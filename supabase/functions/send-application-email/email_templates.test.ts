import { assertEquals, assertStringIncludes } from 'https://deno.land/std@0.224.0/assert/mod.ts';
import {
  bytesToBase64, buildEmailHtml, buildEmailText, extractBucketAndPath, replaceVars, replaceVarsHtml,
} from './email_templates.ts';

Deno.test('replaceVars substitutes every placeholder, adding parentheses around a present country', () => {
  const out = replaceVars(
    '{{student_name}} postule a {{program_name}} - {{university_name}}{{country}} le {{submitted_at}}. Docs: {{documents_list}}',
    {
      studentName: 'Amina K.', programName: 'Master IA', univName: 'Sorbonne',
      country: 'France', submittedAt: '01/01/2026', documentsListText: 'CV',
    },
  );
  assertEquals(out, 'Amina K. postule a Master IA - Sorbonne (France) le 01/01/2026. Docs: CV');
});

Deno.test('replaceVars leaves no parentheses when country is empty', () => {
  const out = replaceVars('{{university_name}}{{country}}', {
    studentName: '', programName: '', univName: 'MIT', country: '', submittedAt: '', documentsListText: '',
  });
  assertEquals(out, 'MIT');
});

Deno.test('replaceVarsHtml wraps the documents list in a <ul>', () => {
  const out = replaceVarsHtml('{{documents_list}}', { studentName: '', programName: '', univName: '', country: '', submittedAt: '', documentsListText: '' }, '<li>CV</li>');
  assertEquals(out, '<ul style="margin:8px 0 16px;padding-left:20px;"><li>CV</li></ul>');
});

Deno.test('buildEmailText includes the signed-links section when a signed link is present', () => {
  const text = buildEmailText({
    studentName: 'Jean', programName: 'MBA', univName: 'HEC', country: 'France', submittedAt: '01/01/2026',
    signedLinksText: '  - CV: https://example.com/cv\n', docsListText: '  - CV',
  });
  assertStringIncludes(text, 'LIENS DE TÉLÉCHARGEMENT');
  assertStringIncludes(text, 'https://example.com/cv');
});

Deno.test('buildEmailText mentions attachments when there are no signed links but attachCount > 0', () => {
  const text = buildEmailText({
    studentName: 'Jean', programName: 'MBA', univName: 'HEC', country: '', submittedAt: '', attachCount: 2, docsListText: '  - CV',
  });
  assertStringIncludes(text, 'Documents joints en pièce jointe');
});

Deno.test('buildEmailText mentions neither attachments nor links when there are none', () => {
  const text = buildEmailText({ studentName: 'Jean', programName: 'MBA', univName: 'HEC', country: '', submittedAt: '' });
  assertEquals(text.includes('LIENS DE TÉLÉCHARGEMENT'), false);
  assertEquals(text.includes('Documents joints'), false);
});

Deno.test('buildEmailHtml embeds the student, program and university names', () => {
  const html = buildEmailHtml({ studentName: 'Marie Curie', programName: 'PhD Physique', univName: 'Sorbonne', country: 'France', submittedAt: '01/01/2026' });
  assertStringIncludes(html, 'Marie Curie');
  assertStringIncludes(html, 'PhD Physique');
  assertStringIncludes(html, 'Sorbonne');
});

Deno.test('buildEmailHtml uses the custom template body instead of the default paragraph when provided', () => {
  const html = buildEmailHtml({
    studentName: 'Marie', programName: 'PhD', univName: 'Sorbonne', country: '', submittedAt: '',
    customBody: 'Texte personnalisé du modèle.',
  });
  assertStringIncludes(html, 'Texte personnalisé du modèle.');
});

Deno.test('bytesToBase64 matches the platform base64 encoding for known bytes', () => {
  const bytes = new TextEncoder().encode('Studium');
  assertEquals(bytesToBase64(bytes), btoa('Studium'));
});

Deno.test('extractBucketAndPath splits a public storage URL into bucket and (undecoded) path', () => {
  const url = 'https://xyz.supabase.co/storage/v1/object/public/documents/abc-123/cv/CV.pdf';
  assertEquals(extractBucketAndPath(url), { bucket: 'documents', path: 'abc-123/cv/CV.pdf' });
});

Deno.test('extractBucketAndPath returns null for a URL without the storage marker', () => {
  assertEquals(extractBucketAndPath('https://example.com/file.pdf'), null);
});

Deno.test('extractBucketAndPath returns null when there is no path after the bucket name', () => {
  assertEquals(extractBucketAndPath('https://xyz.supabase.co/storage/v1/object/public/documents'), null);
});
