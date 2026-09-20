// Fonctions pures extraites de index.ts pour être testables sans démarrer
// Deno.serve (import direct, aucun effet de bord réseau).

const DOCS_BUCKET = 'documents';

// Le bucket "documents" est prive : file_url garde le format d'URL publique
// historique (utile pour en extraire le chemin), mais fetch(url) echoue
// desormais. Cette fonction tourne en service role, donc .download(path)
// contourne RLS directement, sans avoir besoin de signer une URL.
export function docStoragePath(fileUrl: string): string | null {
  const marker = `/object/public/${DOCS_BUCKET}/`;
  const idx = fileUrl.indexOf(marker);
  if (idx === -1) return null;
  return decodeURIComponent(fileUrl.slice(idx + marker.length));
}

export function wrapText(text: string, maxCharsPerLine: number): string[] {
  const words = text.split(/\s+/);
  const lines: string[] = [];
  let current = '';
  for (const word of words) {
    if ((current + ' ' + word).trim().length > maxCharsPerLine) {
      if (current) lines.push(current.trim());
      current = word;
    } else {
      current = (current + ' ' + word).trim();
    }
  }
  if (current) lines.push(current);
  return lines;
}

// Un document est fusionnable dans le pack (page copiée/incrustée) s'il est
// PDF ou image ; sinon (doc/docx...) il reste "transmis séparément".
export function classifyDocuments<T extends { mime_type?: string | null }>(
  docs: T[],
): { mergeable: T[]; unmerged: T[] } {
  const isPdf   = (mime?: string | null) => (mime ?? '').includes('pdf');
  const isImage = (mime?: string | null) => (mime ?? '').startsWith('image/');
  return {
    mergeable: docs.filter((d) => isPdf(d.mime_type) || isImage(d.mime_type)),
    unmerged:  docs.filter((d) => !isPdf(d.mime_type) && !isImage(d.mime_type)),
  };
}

// Un pack existant est perime si le profil ou un document approuve a change
// depuis sa generation (sinon un pack genere tot resterait fige, ex. lettre
// de motivation ajoutee apres coup et jamais reprise dans le pack deja envoye).
export function isPackStale(
  dataChangeTimestamps: (string | null | undefined)[],
  generatedAt: string,
): boolean {
  const latest = dataChangeTimestamps
    .filter((d): d is string => Boolean(d))
    .map((d) => new Date(d).getTime())
    .reduce((max, t) => Math.max(max, t), 0);
  return latest > new Date(generatedAt).getTime();
}
