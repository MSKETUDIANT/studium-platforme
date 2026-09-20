/**
 * Supabase (PostgREST) plafonne chaque réponse à 1000 lignes par défaut
 * (db-max-rows), même sans .range() explicite : une liste qui dépasse ce
 * seuil serait tronquée silencieusement. Ce helper boucle par pages de 1000
 * jusqu'à épuisement pour charger l'intégralité des lignes.
 */
export async function fetchAllRows<T>(
  buildQuery: (from: number, to: number) => PromiseLike<{ data: T[] | null; error: unknown }>,
  pageSize = 1000,
): Promise<T[]> {
  const all: T[] = [];
  let from = 0;
  while (true) {
    const { data, error } = await buildQuery(from, from + pageSize - 1);
    if (error) throw error;
    all.push(...(data ?? []));
    if (!data || data.length < pageSize) break;
    from += pageSize;
  }
  return all;
}
