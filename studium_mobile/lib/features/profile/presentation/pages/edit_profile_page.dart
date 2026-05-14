import 'dart:io';

import 'package:country_picker/country_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/student_profile.dart';
import '../providers/profile_providers.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
const _kBlue   = Color(0xFF4880FF);
const _kNavy   = Color(0xFF0D1F42);
const _kDark   = Color(0xFF1A1D2E);
const _kGrey   = Color(0xFF9CA3AF);
const _kBorder = Color(0xFFE5E7EB);
const _kFill   = Color(0xFFFAFAFC);

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _dio     = Dio();
  final _picker  = ImagePicker();

  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _motivationCtrl;
  late final TextEditingController _academicGoalsCtrl;
  late final TextEditingController _careerGoalsCtrl;

  DateTime? _birthDate;
  String?   _nationality;
  String?   _nationalityCode;
  String?   _countryResidence;
  String?   _countryResidenceCode;
  String?   _phone;
  String    _phoneCountryCode = 'TN';
  int       _wordCount        = 0;

  String?   _photoUrl;
  File?     _photoFile;
  bool      _photoLoading = false;

  bool _initialized = false;
  bool _loading     = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _addressCtrl.dispose();
    _motivationCtrl.dispose();
    _academicGoalsCtrl.dispose();
    _careerGoalsCtrl.dispose();
    _dio.close();
    super.dispose();
  }

  void _initControllers(StudentProfile? profile) {
    if (_initialized) return;
    _firstNameCtrl     = TextEditingController(text: profile?.firstName ?? '');
    _lastNameCtrl      = TextEditingController(text: profile?.lastName ?? '');
    _addressCtrl       = TextEditingController(text: profile?.address ?? '');
    _motivationCtrl    = TextEditingController(text: profile?.motivationLetter ?? '');
    _academicGoalsCtrl = TextEditingController(text: profile?.academicGoals ?? '');
    _careerGoalsCtrl   = TextEditingController(text: profile?.careerGoals ?? '');
    _birthDate         = profile?.birthDate;
    _nationality       = profile?.nationality;
    _countryResidence  = profile?.countryResidence;
    _phone             = profile?.phone;
    _photoUrl          = profile?.photoUrl;
    _wordCount         = _countWords(profile?.motivationLetter ?? '');

    _motivationCtrl.addListener(
        () => setState(() => _wordCount = _countWords(_motivationCtrl.text)));
    _initialized = true;
  }

  int _countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  // ─── Photo ────────────────────────────────────────────────────────────────

  Future<void> _pickPhoto() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: _kBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Choisir une photo',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _kDark,
                  ),
                ),
                const SizedBox(height: 8),
                _SheetTile(
                  icon: Icons.camera_alt_outlined,
                  label: 'Prendre une photo',
                  color: _kBlue,
                  onTap: () {
                    Navigator.pop(context);
                    _capturePhoto(ImageSource.camera);
                  },
                ),
                _SheetTile(
                  icon: Icons.photo_library_outlined,
                  label: 'Choisir depuis la galerie',
                  color: _kBlue,
                  onTap: () {
                    Navigator.pop(context);
                    _capturePhoto(ImageSource.gallery);
                  },
                ),
                if (_photoUrl != null || _photoFile != null)
                  _SheetTile(
                    icon: Icons.delete_outline,
                    label: 'Supprimer la photo',
                    color: const Color(0xFFEF4444),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _photoFile = null;
                        _photoUrl  = null;
                      });
                    },
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _capturePhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _photoFile = File(picked.path));
      }
    } catch (_) {}
  }

  Future<String?> _uploadPhoto(String userId) async {
    if (_photoFile == null) return _photoUrl;
    setState(() => _photoLoading = true);
    try {
      final ext      = _photoFile!.path.split('.').last.toLowerCase();
      final path     = 'avatars/$userId.$ext';
      final bytes    = await _photoFile!.readAsBytes();
      final supabase = Supabase.instance.client;

      await supabase.storage.from('documents').uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/$ext',
          upsert: true,
        ),
      );

      return supabase.storage.from('documents').getPublicUrl(path);
    } catch (e) {
      debugPrint('Upload photo error: $e');
      return _photoUrl;
    } finally {
      setState(() => _photoLoading = false);
    }
  }

  // ─── Date / pays ──────────────────────────────────────────────────────────

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Non définie';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _pickNationality() {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      countryListTheme: CountryListThemeData(
        borderRadius: BorderRadius.circular(16),
        inputDecoration: InputDecoration(
          hintText: 'Rechercher un pays...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _kBorder),
          ),
        ),
      ),
      onSelect: (country) => setState(() {
        _nationality     = country.name;
        _nationalityCode = country.countryCode;
      }),
    );
  }

  void _pickCountryResidence() {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      countryListTheme: CountryListThemeData(
        borderRadius: BorderRadius.circular(16),
        inputDecoration: InputDecoration(
          hintText: 'Rechercher un pays...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _kBorder),
          ),
        ),
      ),
      onSelect: (country) => setState(() {
        _countryResidence     = country.name;
        _countryResidenceCode = country.countryCode;
      }),
    );
  }

  // ─── Adresse Nominatim ────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _searchAddress(String pattern) async {
    if (pattern.length < 3) return [];
    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': pattern,
          'format': 'json',
          'limit': 6,
          'addressdetails': 1,
        },
        options: Options(headers: {
          'Accept-Language': 'fr',
          'User-Agent': 'StudiumApp/1.0',
        }),
      );
      if (response.statusCode != 200) return [];
      return (response.data as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  IconData _placeIcon(String type) {
    switch (type) {
      case 'city':
      case 'town':
      case 'village':
        return Icons.location_city_outlined;
      case 'administrative':
      case 'state':
        return Icons.map_outlined;
      case 'country':
        return Icons.public_outlined;
      default:
        return Icons.location_on_outlined;
    }
  }

  // ─── Word counter ─────────────────────────────────────────────────────────

  Color _wordCountColor() {
    if (_wordCount == 0) return _kGrey;
    if (_wordCount < 300) return const Color(0xFFEF4444);
    if (_wordCount <= 600) return const Color(0xFF10B981);
    return const Color(0xFFF59E0B);
  }

  String _wordCountLabel() {
    if (_wordCount == 0) return '0 / 300–600 mots';
    if (_wordCount < 300) return '$_wordCount mots — minimum 300';
    if (_wordCount <= 600) return '$_wordCount mots ✓';
    return '$_wordCount mots — maximum 600 dépassé';
  }

  // ─── Save ─────────────────────────────────────────────────────────────────

  Future<void> _save(StudentProfile? current) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final userId      = current?.id ?? '';
    final uploadedUrl = await _uploadPhoto(userId);

    final updated = StudentProfile(
      id: userId,
      email: current?.email,
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      phone: (_phone?.isEmpty ?? true) ? null : _phone,
      nationality: _nationality,
      birthDate: _birthDate,
      countryResidence: _countryResidence,
      address: _addressCtrl.text.trim().isEmpty
          ? null : _addressCtrl.text.trim(),
      photoUrl: uploadedUrl,
      motivationLetter: _motivationCtrl.text.trim().isEmpty
          ? null : _motivationCtrl.text.trim(),
      academicGoals: _academicGoalsCtrl.text.trim().isEmpty
          ? null : _academicGoalsCtrl.text.trim(),
      careerGoals: _careerGoalsCtrl.text.trim().isEmpty
          ? null : _careerGoalsCtrl.text.trim(),
      completenessScore: current?.completenessScore ?? 0,
    );

    await ref.read(profileNotifierProvider.notifier).upsert(updated);
    setState(() => _loading = false);
    if (mounted) Navigator.pop(context);
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileNotifierProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('Erreur : $e'))),
      data: (profile) {
        _initControllers(profile);
        return Scaffold(
          backgroundColor: const Color(0xFFF4F6FB),
          appBar: _buildAppBar(profile),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, MediaQuery.of(context).padding.bottom + 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ─── Hero photo card ──────────────────────────────
                  _buildPhotoHero(profile)
                      .animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),

                  const SizedBox(height: 28),

                  // ─── Identité ─────────────────────────────────────
                  _SectionHeader('Identité', icon: Icons.person_outline_rounded)
                      .animate().fadeIn(delay: 80.ms),
                  const SizedBox(height: 12),
                  _FormCard(children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StyledField(
                            controller: _firstNameCtrl,
                            label: 'Prénom',
                            required: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StyledField(
                            controller: _lastNameCtrl,
                            label: 'Nom',
                            required: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _DatePickerField(
                      label: 'Date de naissance',
                      value: _formatDate(_birthDate),
                      hasValue: _birthDate != null,
                      onTap: _pickBirthDate,
                      onClear: () => setState(() => _birthDate = null),
                    ),
                    const SizedBox(height: 12),
                    _CountryPickerField(
                      label: 'Nationalité',
                      value: _nationality,
                      countryCode: _nationalityCode,
                      icon: Icons.flag_outlined,
                      onTap: _pickNationality,
                      onClear: () => setState(() {
                        _nationality     = null;
                        _nationalityCode = null;
                      }),
                    ),
                  ]).animate().fadeIn(delay: 120.ms).slideY(begin: 0.04),

                  const SizedBox(height: 24),

                  // ─── Contact ──────────────────────────────────────
                  _SectionHeader('Contact', icon: Icons.contacts_outlined)
                      .animate().fadeIn(delay: 180.ms),
                  const SizedBox(height: 12),
                  _FormCard(children: [
                    IntlPhoneField(
                      initialValue: _phone,
                      initialCountryCode: _phoneCountryCode,
                      decoration: _fieldDecoration('Téléphone'),
                      onChanged: (phone) {
                        _phone            = phone.completeNumber;
                        _phoneCountryCode = phone.countryISOCode;
                      },
                      onCountryChanged: (country) {
                        _phoneCountryCode = country.code;
                      },
                    ),
                    const SizedBox(height: 12),
                    _CountryPickerField(
                      label: 'Pays de résidence',
                      value: _countryResidence,
                      countryCode: _countryResidenceCode,
                      icon: Icons.public_outlined,
                      onTap: _pickCountryResidence,
                      onClear: () => setState(() {
                        _countryResidence     = null;
                        _countryResidenceCode = null;
                      }),
                    ),
                    const SizedBox(height: 12),

                    // Adresse — Nominatim typeahead
                    TypeAheadField<Map<String, dynamic>>(
                      controller: _addressCtrl,
                      builder: (context, controller, focusNode) {
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: _fieldDecoration(
                            'Ville / Adresse',
                            hint: 'Tapez une ville, rue...',
                            prefix: const Icon(
                              Icons.location_on_outlined,
                              size: 18, color: _kGrey,
                            ),
                          ),
                        );
                      },
                      suggestionsCallback: _searchAddress,
                      itemBuilder: (context, place) {
                        final name = place['display_name'] as String? ?? '';
                        final type = place['type']         as String? ?? '';
                        final parts = name.split(',');
                        return ListTile(
                          leading: Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: _kBlue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(_placeIcon(type),
                                size: 16, color: _kBlue),
                          ),
                          title: Text(
                            parts.take(2).join(',').trim(),
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            parts.skip(2).join(',').trim(),
                            style: const TextStyle(
                                fontSize: 11, color: _kGrey),
                            overflow: TextOverflow.ellipsis,
                          ),
                          dense: true,
                        );
                      },
                      onSelected: (place) {
                        final name = place['display_name'] as String? ?? '';
                        _addressCtrl.text = name
                            .split(',')
                            .take(3)
                            .join(',')
                            .trim();
                      },
                      decorationBuilder: (context, child) => Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: child,
                        ),
                      ),
                      loadingBuilder: (context) => const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(
                          child: SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      emptyBuilder: (context) => const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Aucun résultat — essayez un autre terme',
                          style: TextStyle(color: _kGrey, fontSize: 13),
                        ),
                      ),
                    ),
                  ]).animate().fadeIn(delay: 200.ms).slideY(begin: 0.04),

                  const SizedBox(height: 24),

                  // ─── Motivation & Objectifs ───────────────────────
                  _SectionHeader('Motivation & Objectifs',
                      icon: Icons.auto_stories_outlined)
                      .animate().fadeIn(delay: 260.ms),
                  const SizedBox(height: 12),
                  _FormCard(children: [
                    // Info banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _kBlue.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _kBlue.withValues(alpha: 0.15),
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline,
                              size: 16, color: _kBlue),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Rédigez une lettre personnalisée entre 300 et 600 mots. '
                              'Expliquez votre parcours, vos motivations et votre projet académique.',
                              style: TextStyle(
                                fontSize: 12,
                                color: _kBlue,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _motivationCtrl,
                      maxLines: 10,
                      decoration: _fieldDecoration(
                        'Lettre de motivation',
                        hint: 'Parlez de votre parcours, vos motivations...',
                        multiline: true,
                        hasError: true,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        if (_wordCount < 300) {
                          return 'Minimum 300 mots ($_wordCount actuellement)';
                        }
                        if (_wordCount > 600) {
                          return 'Maximum 600 mots ($_wordCount actuellement)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    // Word count bar
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (_wordCount / 600).clamp(0.0, 1.0),
                              minHeight: 4,
                              backgroundColor: _kBorder,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  _wordCountColor()),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _wordCountLabel(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _wordCountColor(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _StyledField(
                      controller: _academicGoalsCtrl,
                      label: 'Objectifs académiques',
                      maxLines: 3,
                      hint: 'Décrivez vos ambitions académiques...',
                    ),
                    const SizedBox(height: 12),
                    _StyledField(
                      controller: _careerGoalsCtrl,
                      label: 'Objectifs professionnels',
                      maxLines: 3,
                      hint: 'Décrivez votre projet professionnel...',
                    ),
                  ]).animate().fadeIn(delay: 300.ms).slideY(begin: 0.04),

                  const SizedBox(height: 32),

                  // ─── Gradient save button ─────────────────────────
                  _GradientButton(
                    loading: _loading,
                    onTap: () => _save(profile),
                  ).animate().fadeIn(delay: 360.ms).slideY(begin: 0.1),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(StudentProfile? profile) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_kNavy, Color(0xFF1E5298)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Modifier le profil',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
      actions: [
        _loading
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              )
            : TextButton(
                onPressed: () => _save(profile),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Enregistrer',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
      ],
    );
  }

  // ─── Photo hero card ──────────────────────────────────────────────────────

  Widget _buildPhotoHero(StudentProfile? profile) {
    final displayName =
        '${profile?.firstName ?? ''} ${profile?.lastName ?? ''}'.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kNavy, Color(0xFF1565C0), Color(0xFF1E5298)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _kNavy.withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          GestureDetector(
            onTap: _pickPhoto,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 88, height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _photoLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : _photoFile != null
                            ? Image.file(_photoFile!, fit: BoxFit.cover)
                            : _photoUrl != null
                                ? Image.network(
                                    _photoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _AvatarPlaceholder(),
                                  )
                                : _AvatarPlaceholder(),
                  ),
                ),
                Positioned(
                  bottom: 2, right: 2,
                  child: Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      color: _kBlue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Name
          Text(
            displayName.isEmpty ? 'Mon profil' : displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (profile?.email != null) ...[
            const SizedBox(height: 4),
            Text(
              profile!.email!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 14),
          // Change photo pill
          GestureDetector(
            onTap: _pickPhoto,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.30),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt_outlined,
                      color: Colors.white, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Modifier la photo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── InputDecoration helper ───────────────────────────────────────────────────

InputDecoration _fieldDecoration(
  String label, {
  String?  hint,
  Widget?  prefix,
  bool     multiline = false,
  bool     hasError  = false,
}) {
  final base = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: _kBorder),
  );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFD1D5DB)),
    prefixIcon: prefix,
    alignLabelWithHint: multiline,
    floatingLabelBehavior: FloatingLabelBehavior.auto,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: base,
    enabledBorder: base,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _kBlue, width: 1.5),
    ),
    errorBorder: hasError
        ? OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEF4444)),
          )
        : null,
    filled: true,
    fillColor: _kFill,
  );
}

// ─── Avatar placeholder ───────────────────────────────────────────────────────

class _AvatarPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A3C6E),
      child: const Icon(Icons.person, color: Colors.white, size: 48),
    );
  }
}

// ─── Bottom sheet tile ────────────────────────────────────────────────────────

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final VoidCallback onTap;

  const _SheetTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: color == const Color(0xFFEF4444) ? color : _kDark,
        ),
      ),
      onTap: onTap,
    );
  }
}

// ─── Gradient save button ─────────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _GradientButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kBlue, Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _kBlue.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: loading ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Enregistrer les modifications',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String   text;
  final IconData? icon;
  const _SectionHeader(this.text, {this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4, height: 20,
          decoration: BoxDecoration(
            color: _kBlue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        if (icon != null) ...[
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: _kBlue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: _kBlue),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _kDark,
          ),
        ),
      ],
    );
  }
}

// ─── Form card ────────────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  final List<Widget> children;
  const _FormCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

// ─── Styled text field ────────────────────────────────────────────────────────

class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool required;
  final int maxLines;

  const _StyledField({
    required this.controller,
    required this.label,
    this.hint,
    this.required = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: _fieldDecoration(
        label,
        hint: hint,
        multiline: maxLines > 1,
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null
          : null,
    );
  }
}

// ─── Country picker field ─────────────────────────────────────────────────────

class _CountryPickerField extends StatelessWidget {
  final String   label;
  final String?  value;
  final String?  countryCode;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _CountryPickerField({
    required this.label,
    required this.value,
    required this.countryCode,
    required this.icon,
    required this.onTap,
    required this.onClear,
  });

  String _flag(String code) => code
      .toUpperCase()
      .split('')
      .map((c) => String.fromCharCode(c.codeUnitAt(0) + 127397))
      .join();

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _kFill,
          border: Border.all(color: _kBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            hasValue && countryCode != null
                ? Text(_flag(countryCode!),
                    style: const TextStyle(fontSize: 20))
                : Icon(icon, size: 18, color: _kGrey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(fontSize: 11, color: _kGrey)),
                  const SizedBox(height: 2),
                  Text(
                    hasValue ? value! : 'Sélectionner un pays',
                    style: TextStyle(
                      fontSize: 14,
                      color: hasValue ? _kDark : const Color(0xFFD1D5DB),
                      fontWeight:
                          hasValue ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (hasValue)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.clear, size: 16, color: _kGrey),
              )
            else
              const Icon(Icons.chevron_right, size: 18, color: _kGrey),
          ],
        ),
      ),
    );
  }
}

// ─── Date picker field ────────────────────────────────────────────────────────

class _DatePickerField extends StatelessWidget {
  final String label;
  final String value;
  final bool   hasValue;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.hasValue,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _kFill,
          border: Border.all(color: _kBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.cake_outlined, size: 18, color: _kGrey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(fontSize: 11, color: _kGrey)),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: hasValue ? _kDark : const Color(0xFFD1D5DB),
                      fontWeight:
                          hasValue ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (hasValue)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.clear, size: 16, color: _kGrey),
              ),
          ],
        ),
      ),
    );
  }
}
