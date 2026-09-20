import { assertEquals } from 'https://deno.land/std@0.224.0/assert/mod.ts';
import { classifyDocuments, docStoragePath, isPackStale, wrapText } from './pack_utils.ts';

Deno.test('docStoragePath extracts and decodes the path from a public-style storage URL', () => {
  const url = 'https://xyz.supabase.co/storage/v1/object/public/documents/abc-123/cv/Mon%20CV.pdf';
  assertEquals(docStoragePath(url), 'abc-123/cv/Mon CV.pdf');
});

Deno.test('docStoragePath returns null when the marker is absent', () => {
  assertEquals(docStoragePath('https://example.com/not-a-storage-url'), null);
});

Deno.test('wrapText keeps the full text intact across the wrapped lines', () => {
  const text = 'un texte assez long pour etre coupe en plusieurs lignes de test';
  const lines = wrapText(text, 20);
  assertEquals(lines.join(' '), text);
});

Deno.test('wrapText never exceeds maxCharsPerLine for lines with more than one word', () => {
  const lines = wrapText('un texte assez long pour etre coupe en plusieurs lignes de test', 20);
  for (const line of lines) {
    if (line.includes(' ')) assertEquals(line.length <= 20, true);
  }
});

Deno.test('wrapText keeps a single very long word on its own line even past the limit', () => {
  const lines = wrapText('motmotmotmotmotmotmotmotmotmotmotmotmot', 10);
  assertEquals(lines, ['motmotmotmotmotmotmotmotmotmotmotmotmot']);
});

Deno.test('classifyDocuments treats pdf and image mime types as mergeable, the rest as unmerged', () => {
  const docs = [
    { id: '1', mime_type: 'application/pdf' },
    { id: '2', mime_type: 'image/png' },
    { id: '3', mime_type: 'image/jpeg' },
    { id: '4', mime_type: 'application/msword' },
    { id: '5', mime_type: null },
  ];
  const { mergeable, unmerged } = classifyDocuments(docs);
  assertEquals(mergeable.map((d) => d.id), ['1', '2', '3']);
  assertEquals(unmerged.map((d) => d.id), ['4', '5']);
});

Deno.test('isPackStale is true when a tracked timestamp is after the pack generation date', () => {
  assertEquals(
    isPackStale(['2026-09-02T00:00:00.000Z'], '2026-09-01T00:00:00.000Z'),
    true,
  );
});

Deno.test('isPackStale is false when all tracked timestamps predate the pack, ignoring null/undefined', () => {
  assertEquals(
    isPackStale(['2026-09-01T00:00:00.000Z', null, undefined], '2026-09-05T00:00:00.000Z'),
    false,
  );
});

Deno.test('isPackStale is false when there are no tracked timestamps at all', () => {
  assertEquals(isPackStale([null, undefined], '2026-09-05T00:00:00.000Z'), false);
});
