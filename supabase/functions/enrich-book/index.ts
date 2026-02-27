// supabase/functions/enrich-book/index.ts
// Edge Function — Enrichissement d'un livre via Google Books + Open Library
// Pipeline : titre + auteur → recherche cascade → métadonnées complètes

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, apikey, x-client-info",
};

interface EnrichmentResult {
  isbn_13?: string;
  isbn_10?: string;
  title: string;
  author?: string;
  publisher?: string;
  collection?: string;
  publication_date?: string;
  language?: string;
  page_count?: number;
  description?: string;
  genres?: string[];
  cover_url?: string;
  goodreads_rating?: number;
  confidence: number;
  sources: string[];
}

// ── Google Books API ──

async function searchGoogleBooks(
  title: string,
  author?: string | null,
  publisher?: string | null
): Promise<EnrichmentResult | null> {
  try {
    // Construire la query
    let query = `intitle:${title}`;
    if (author) query += `+inauthor:${author}`;

    const url = `https://www.googleapis.com/books/v1/volumes?q=${encodeURIComponent(query)}&langRestrict=fr&maxResults=5`;

    const response = await fetch(url);
    if (!response.ok) return null;

    const data = await response.json();
    if (!data.items || data.items.length === 0) return null;

    // Trouver le meilleur match
    const bestMatch = findBestMatch(data.items, title, author, publisher);
    if (!bestMatch) return null;

    const info = bestMatch.volumeInfo;
    const identifiers = info.industryIdentifiers || [];

    return {
      isbn_13: identifiers.find((id: any) => id.type === "ISBN_13")?.identifier,
      isbn_10: identifiers.find((id: any) => id.type === "ISBN_10")?.identifier,
      title: info.title || title,
      author: info.authors?.[0] || author || undefined,
      publisher: info.publisher,
      publication_date: info.publishedDate,
      language: info.language,
      page_count: info.pageCount,
      description: info.description?.substring(0, 500),
      genres: info.categories,
      cover_url: info.imageLinks?.thumbnail?.replace("http://", "https://"),
      confidence: calculateMatchScore(info, title, author, publisher),
      sources: ["google_books"],
    };
  } catch (error) {
    console.error("[enrich-book] Google Books error:", error);
    return null;
  }
}

// ── Open Library API ──

async function searchOpenLibrary(
  title: string,
  author?: string | null
): Promise<Partial<EnrichmentResult> | null> {
  try {
    let url = `https://openlibrary.org/search.json?title=${encodeURIComponent(title)}`;
    if (author) url += `&author=${encodeURIComponent(author)}`;
    url += "&limit=3";

    const response = await fetch(url);
    if (!response.ok) return null;

    const data = await response.json();
    if (!data.docs || data.docs.length === 0) return null;

    const doc = data.docs[0];

    return {
      isbn_13: doc.isbn?.find((isbn: string) => isbn.length === 13),
      isbn_10: doc.isbn?.find((isbn: string) => isbn.length === 10),
      title: doc.title,
      author: doc.author_name?.[0],
      publisher: doc.publisher?.[0],
      page_count: doc.number_of_pages_median,
      genres: doc.subject?.slice(0, 5),
      cover_url: doc.cover_i
        ? `https://covers.openlibrary.org/b/id/${doc.cover_i}-M.jpg`
        : undefined,
      sources: ["open_library"],
    };
  } catch (error) {
    console.error("[enrich-book] Open Library error:", error);
    return null;
  }
}

// ── Matching d'édition ──

function findBestMatch(
  items: any[],
  title: string,
  author?: string | null,
  publisher?: string | null
): any | null {
  let bestScore = 0;
  let bestItem = null;

  for (const item of items) {
    const info = item.volumeInfo;
    const score = calculateMatchScore(info, title, author, publisher);
    if (score > bestScore) {
      bestScore = score;
      bestItem = item;
    }
  }

  return bestScore >= 30 ? bestItem : null;
}

function calculateMatchScore(
  info: any,
  title: string,
  author?: string | null,
  publisher?: string | null
): number {
  let score = 0;
  const infoTitle = (info.title || "").toLowerCase();
  const searchTitle = title.toLowerCase();

  // Titre match
  if (infoTitle === searchTitle) {
    score += 40;
  } else if (infoTitle.includes(searchTitle) || searchTitle.includes(infoTitle)) {
    score += 25;
  }

  // Auteur match
  if (author && info.authors) {
    const infoAuthors = info.authors.join(" ").toLowerCase();
    if (infoAuthors.includes(author.toLowerCase())) {
      score += 30;
    }
  }

  // Éditeur match
  if (publisher && info.publisher) {
    const infoPublisher = info.publisher.toLowerCase();
    const searchPublisher = publisher.toLowerCase();
    // Mapper les collections aux éditeurs (Folio → Gallimard, Poche → LGF, etc.)
    const publisherAliases: Record<string, string[]> = {
      gallimard: ["folio", "gallimard", "nrf"],
      lgf: ["le livre de poche", "lgf", "poche"],
      pocket: ["pocket"],
      points: ["points", "seuil"],
      "j'ai lu": ["j'ai lu", "jai lu", "flammarion"],
    };

    for (const [key, aliases] of Object.entries(publisherAliases)) {
      const matchesSearch = aliases.some((a) => searchPublisher.includes(a));
      const matchesInfo = aliases.some((a) => infoPublisher.includes(a)) || infoPublisher.includes(key);
      if (matchesSearch && matchesInfo) {
        score += 20;
        break;
      }
    }
  }

  // Langue française bonus
  if (info.language === "fr") {
    score += 10;
  }

  return score;
}

// ── Fusion des résultats ──

function mergeResults(
  google: EnrichmentResult | null,
  openLib: Partial<EnrichmentResult> | null,
  originalTitle: string,
  originalAuthor?: string | null
): EnrichmentResult {
  const base: EnrichmentResult = {
    title: originalTitle,
    author: originalAuthor || undefined,
    confidence: 0,
    sources: [],
  };

  if (google) {
    Object.assign(base, google);
  }

  if (openLib) {
    // Compléter les champs manquants avec Open Library
    if (!base.isbn_13 && openLib.isbn_13) base.isbn_13 = openLib.isbn_13;
    if (!base.page_count && openLib.page_count) base.page_count = openLib.page_count;
    if (!base.cover_url && openLib.cover_url) base.cover_url = openLib.cover_url;
    if (!base.genres && openLib.genres) base.genres = openLib.genres;
    if (openLib.sources) base.sources.push(...openLib.sources);
  }

  return base;
}

// ── Handler principal ──

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: CORS_HEADERS });
  }

  try {
    const { title, author, publisher } = await req.json();

    if (!title) {
      return new Response(
        JSON.stringify({ error: "Titre manquant" }),
        { status: 400, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
      );
    }

    console.log(`[enrich-book] Recherche: "${title}" par ${author || "?"}`);

    // Recherche en parallèle sur Google Books et Open Library
    const [googleResult, openLibResult] = await Promise.all([
      searchGoogleBooks(title, author, publisher),
      searchOpenLibrary(title, author),
    ]);

    // Fusionner les résultats
    const enriched = mergeResults(googleResult, openLibResult, title, author);

    console.log(
      `[enrich-book] Résultat: ISBN=${enriched.isbn_13 || "?"}, ` +
      `confidence=${enriched.confidence}, sources=${enriched.sources.join("+")}`
    );

    return new Response(JSON.stringify(enriched), {
      headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("[enrich-book] Error:", error);
    return new Response(
      JSON.stringify({ error: error.message || "Erreur lors de l'enrichissement" }),
      {
        status: 500,
        headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
      }
    );
  }
});
