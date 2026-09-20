import { describe, it, expect } from 'vitest';
import { buildCsvContent } from './export_csv';

describe('buildCsvContent()', () => {
  it('retourne une chaîne vide pour une liste vide', () => {
    expect(buildCsvContent([])).toBe('');
  });

  it('génère l\'en-tête depuis les clés de la première ligne', () => {
    const csv = buildCsvContent([{ nom: 'Kaba', pays: 'Tunisie' }]);
    expect(csv.split('\r\n')[0]).toBe('nom,pays');
  });

  it('sépare correctement plusieurs lignes', () => {
    const csv = buildCsvContent([
      { nom: 'Kaba' },
      { nom: 'Camara' },
    ]);
    expect(csv.split('\r\n')).toEqual(['nom', 'Kaba', 'Camara']);
  });

  it('échappe les valeurs contenant une virgule', () => {
    const csv = buildCsvContent([{ ville: 'Paris, France' }]);
    expect(csv).toBe('ville\r\n"Paris, France"');
  });

  it('échappe les valeurs contenant des guillemets (doublés)', () => {
    const csv = buildCsvContent([{ note: 'Dossier "urgent"' }]);
    expect(csv).toBe('note\r\n"Dossier ""urgent"""');
  });

  it('échappe les valeurs contenant un saut de ligne', () => {
    const csv = buildCsvContent([{ note: 'ligne1\nligne2' }]);
    expect(csv).toBe('note\r\n"ligne1\nligne2"');
  });

  it('convertit null/undefined en chaîne vide sans planter', () => {
    const csv = buildCsvContent([{ a: null, b: undefined, c: 0 }]);
    expect(csv.split('\r\n')[1]).toBe(',,0');
  });

  it('ne modifie pas les valeurs simples (pas de guillemets superflus)', () => {
    const csv = buildCsvContent([{ statut: 'Envoyée' }]);
    expect(csv).toBe('statut\r\nEnvoyée');
  });
});
