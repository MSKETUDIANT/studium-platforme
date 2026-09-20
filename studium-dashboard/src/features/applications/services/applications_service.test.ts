import { describe, it, expect } from 'vitest';
import { docTypeLabel, mapRow, buildDocFileName } from './applications_service';

describe('docTypeLabel()', () => {
  it('traduit les types de document connus', () => {
    expect(docTypeLabel('cv')).toBe('Curriculum Vitae');
    expect(docTypeLabel('transcript')).toBe('Relevé de notes');
    expect(docTypeLabel('recommendation')).toBe('Lettre de recommandation');
    expect(docTypeLabel('passport')).toBe("Passeport / Pièce d'identité");
    expect(docTypeLabel('motivation_letter')).toBe('Lettre de motivation');
    expect(docTypeLabel('diploma')).toBe('Diplôme');
    expect(docTypeLabel('language_cert')).toBe('Attestation de langue');
    expect(docTypeLabel('financial_proof')).toBe('Justificatif de financement');
    expect(docTypeLabel('other')).toBe('Document complémentaire');
  });

  it('retourne le type brut tel quel si inconnu (pas de crash)', () => {
    expect(docTypeLabel('type_inexistant')).toBe('type_inexistant');
  });
});

describe('mapRow()', () => {
  const baseRow = {
    id: 'app-1',
    status: 'verified',
    submitted_at: '2026-01-15T00:00:00.000Z',
    notes: 'Une note',
    motivation_letter: 'Ma lettre',
    student_profiles: { id: 'stu-1', first_name: 'Amina', last_name: 'K.', nationality: 'Sénégal', completeness_score: 87 },
    programs: {
      id: 'prog-1', program_name: 'Master IA', university_name: 'Sorbonne', country: 'France', level: 'master',
      deadline: '2026-06-01', requirements: ['CV', 'Relevé'],
      contact_email: 'fallback@sorbonne.fr', cc_emails: 'cc-fallback@sorbonne.fr',
      program_contacts: [{ email: 'admissions@sorbonne.fr', cc_emails: ['a@x.fr', 'b@x.fr'] }],
    },
  };

  it('traduit le statut brut vers le libellé UI et propage les champs de base', () => {
    const app = mapRow(baseRow);
    expect(app.rawStatus).toBe('verified');
    expect(app.status).toBe('Vérifiée');
    expect(app.student).toBe('Amina K.');
    expect(app.score).toBe(87);
    expect(app.university).toBe('Sorbonne');
    expect(app.deadline).toBe('2026-06-01');
  });

  it('priorise le contact dédié du programme (program_contacts) sur le contact_email générique', () => {
    const app = mapRow(baseRow);
    expect(app.contactEmail).toBe('admissions@sorbonne.fr');
    expect(app.ccEmails).toBe('a@x.fr, b@x.fr');
  });

  it('retombe sur programs.contact_email/cc_emails quand aucun program_contacts n\'est renseigné', () => {
    const row = { ...baseRow, programs: { ...baseRow.programs, program_contacts: [] } };
    const app = mapRow(row);
    expect(app.contactEmail).toBe('fallback@sorbonne.fr');
    expect(app.ccEmails).toBe('cc-fallback@sorbonne.fr');
  });

  it('retombe sur le fallback même si program_contacts existe mais avec une liste cc_emails vide', () => {
    const row = {
      ...baseRow,
      programs: { ...baseRow.programs, program_contacts: [{ email: 'admissions@sorbonne.fr', cc_emails: [] }] },
    };
    const app = mapRow(row);
    expect(app.ccEmails).toBe('cc-fallback@sorbonne.fr');
  });

  it('ne plante pas et retombe sur des valeurs par défaut sûres quand student_profiles/programs sont absents', () => {
    const app = mapRow({ id: 'app-2', status: 'draft' });
    expect(app.student).toBe('Inconnu');
    expect(app.studentId).toBe('');
    expect(app.programId).toBe('');
    expect(app.score).toBe(0);
    expect(app.programRequirements).toEqual([]);
    expect(app.contactEmail).toBeUndefined();
  });

  it('retombe sur le statut "submitted"/"En attente" quand le statut brut est absent', () => {
    const app = mapRow({ id: 'app-3' });
    expect(app.rawStatus).toBe('submitted');
    expect(app.status).toBe('En attente');
  });

  it('force programRequirements à un tableau vide si programs.requirements n\'est pas un tableau', () => {
    const row = { ...baseRow, programs: { ...baseRow.programs, requirements: null } };
    expect(mapRow(row).programRequirements).toEqual([]);
  });
});

describe('buildDocFileName()', () => {
  it('construit NOM_Prenom_Type_Date avec l\'extension du fichier original', () => {
    const name = buildDocFileName('Amina Ba Diallo', 'transcript', 'mon_releve.PDF');
    expect(name).toMatch(/^DIALLO_Amina_Releve_\d{4}-\d{2}-\d{2}\.pdf$/);
  });

  it('déduit une extension pdf par défaut quand le fichier original est absent', () => {
    const name = buildDocFileName('Jean Dupont', 'cv', null);
    expect(name).toMatch(/^DUPONT_Jean_CV_\d{4}-\d{2}-\d{2}\.pdf$/);
  });

  it('nettoie les caractères non alphabétiques du nom et prénom', () => {
    const name = buildDocFileName("Jean-Paul O'Neil", 'other', 'doc.jpg');
    expect(name).toMatch(/^ONEIL_JeanPaul_Autre_\d{4}-\d{2}-\d{2}\.jpg$/);
  });

  it('dérive un slug depuis le type quand il est inconnu de la table de labels', () => {
    const name = buildDocFileName('Marie Curie', 'un_type_exotique', 'x.png');
    expect(name).toMatch(/^CURIE_Marie_UNTYPEEXOTIQUE_\d{4}-\d{2}-\d{2}\.png$/);
  });
});
