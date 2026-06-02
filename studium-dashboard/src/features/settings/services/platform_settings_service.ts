import { supabase } from '../../../shared/services/supabase';

export interface PlatformSettings {
  uploadMaxSizeMb:      number;
  uploadAllowedFormats: string;
  motivationMinWords:   number;
  supportEmail:         string;
  platformName:         string;
  defaultLanguage:      string;
}

const DEFAULTS: PlatformSettings = {
  uploadMaxSizeMb:      10,
  uploadAllowedFormats: 'pdf,doc,docx,jpg,jpeg,png',
  motivationMinWords:   300,
  supportEmail:         'support@studium.app',
  platformName:         'Studium',
  defaultLanguage:      'fr',
};

const KEY_MAP: Record<keyof PlatformSettings, string> = {
  uploadMaxSizeMb:      'upload_max_size_mb',
  uploadAllowedFormats: 'upload_allowed_formats',
  motivationMinWords:   'motivation_min_words',
  supportEmail:         'support_email',
  platformName:         'platform_name',
  defaultLanguage:      'default_language',
};

export async function fetchPlatformSettings(): Promise<PlatformSettings> {
  const { data, error } = await supabase
    .from('platform_settings')
    .select('key, value');

  if (error || !data?.length) return { ...DEFAULTS };

  const map: Record<string, string> = {};
  data.forEach((r: any) => { map[r.key] = r.value; });

  return {
    uploadMaxSizeMb:      Number(map['upload_max_size_mb']      ?? DEFAULTS.uploadMaxSizeMb),
    uploadAllowedFormats: map['upload_allowed_formats']          ?? DEFAULTS.uploadAllowedFormats,
    motivationMinWords:   Number(map['motivation_min_words']     ?? DEFAULTS.motivationMinWords),
    supportEmail:         map['support_email']                   ?? DEFAULTS.supportEmail,
    platformName:         map['platform_name']                   ?? DEFAULTS.platformName,
    defaultLanguage:      map['default_language']                ?? DEFAULTS.defaultLanguage,
  };
}

export async function savePlatformSettings(settings: PlatformSettings): Promise<void> {
  const rows = (Object.keys(KEY_MAP) as (keyof PlatformSettings)[]).map(k => ({
    key:        KEY_MAP[k],
    value:      String(settings[k]),
    updated_at: new Date().toISOString(),
  }));

  const { error } = await supabase
    .from('platform_settings')
    .upsert(rows, { onConflict: 'key' });

  if (error) throw error;
}
