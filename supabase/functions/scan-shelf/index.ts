// supabase/functions/scan-shelf/index.ts
// Edge Function — Analyse d'une photo d'étagère via Claude Vision API
// Pipeline : Photo base64 → Claude Vision → JSON structuré des livres détectés

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY");

const SHELF_ANALYSIS_PROMPT = `Tu es un expert en identification de livres. Analyse cette photo d'étagère.

INSTRUCTIONS PRÉCISES :

1. Identifie CHAQUE livre visible sur la photo, même partiellement.
   Parcours de GAUCHE À DROITE, étagère par étagère de HAUT EN BAS.

2. Pour chaque livre, extrais :
   - titre : le titre exact lu sur la tranche (ou ta meilleure estimation)
   - auteur : l'auteur si lisible sur la tranche
   - editeur : l'éditeur ou la collection si reconnaissable
     (Folio, Poche, Gallimard, Penguin, Points, Le Livre de Poche, J'ai Lu, etc.)
   - confiance : un score de 0 à 100 indiquant ta certitude
   - statut : "COMPLET" si tu es sûr, "PARTIEL" si partiellement lisible,
     "ILLISIBLE" si tu ne peux rien lire
   - apparence : couleur de la tranche, taille estimée (poche/moyen/grand),
     épaisseur approximative
   - candidats : si confiance < 80%, propose 2-3 titres alternatifs possibles

3. INDICES CONTEXTUELS à utiliser :
   - Les logos d'éditeurs sont très distinctifs (Gallimard = fond crème,
     Folio = bande colorée en bas, Penguin = orange...)
   - Les livres d'une même collection ont le même design
   - La taille et l'épaisseur donnent des indices sur le livre
   - Les livres voisins peuvent donner un contexte (même auteur, même thème)

4. Retourne UNIQUEMENT un objet JSON valide, sans commentaire ni markdown.
   Pas de \`\`\`json, juste le JSON brut.

STRUCTURE JSON ATTENDUE :
{
  "etageres": [
    {
      "numero": 1,
      "livres": [
        {
          "position": 1,
          "titre_detecte": "L'Étranger",
          "auteur_detecte": "Albert Camus",
          "editeur_detecte": "Folio",
          "confiance": 95,
          "statut": "COMPLET",
          "apparence": "tranche blanc cassé avec bande verte, format poche, fin",
          "candidats_alternatifs": []
        }
      ]
    }
  ],
  "stats": {
    "total_livres": 0,
    "identifies_confiance_haute": 0,
    "partiels": 0,
    "illisibles": 0
  }
}`;

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, apikey, x-client-info",
};

serve(async (req: Request) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: CORS_HEADERS });
  }

  try {
    if (!ANTHROPIC_API_KEY) {
      throw new Error("ANTHROPIC_API_KEY non configurée dans les secrets Supabase");
    }

    const body = await req.json();
    const { image, media_type } = body;

    if (!image) {
      return new Response(
        JSON.stringify({ error: "Image manquante (champ 'image' en base64)" }),
        { status: 400, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
      );
    }

    console.log(`[scan-shelf] Analyse en cours, image: ${(image.length / 1024).toFixed(0)} Ko base64`);

    // Appel Claude Vision API
    const response = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-sonnet-4-20250514",
        max_tokens: 4096,
        messages: [
          {
            role: "user",
            content: [
              {
                type: "image",
                source: {
                  type: "base64",
                  media_type: media_type || "image/jpeg",
                  data: image,
                },
              },
              {
                type: "text",
                text: SHELF_ANALYSIS_PROMPT,
              },
            ],
          },
        ],
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`[scan-shelf] Claude API error: ${response.status}`, errorText);
      throw new Error(`Claude API error: ${response.status}`);
    }

    const result = await response.json();
    const textContent = result.content?.[0]?.text;

    if (!textContent) {
      throw new Error("Réponse Claude vide");
    }

    // Nettoyer et parser le JSON (au cas où Claude ajoute des backticks)
    const cleanedJson = textContent
      .replace(/```json\n?/g, "")
      .replace(/```\n?/g, "")
      .trim();

    const scanResult = JSON.parse(cleanedJson);

    console.log(`[scan-shelf] ${scanResult.stats?.total_livres ?? 0} livres détectés`);

    return new Response(JSON.stringify(scanResult), {
      headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("[scan-shelf] Error:", error);
    return new Response(
      JSON.stringify({ error: error.message || "Erreur lors du scan" }),
      {
        status: 500,
        headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
      }
    );
  }
});
