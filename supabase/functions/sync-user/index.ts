// supabase/functions/sync-user/index.ts
// Edge Function — Synchronise un utilisateur Firebase Auth vers Supabase
// Appelée à chaque connexion pour créer/mettre à jour le profil

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, apikey, x-client-info",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: CORS_HEADERS });
  }

  try {
    const {
      firebase_uid,
      display_name,
      email,
      phone,
      photo_url,
      auth_providers,
    } = await req.json();

    if (!firebase_uid) {
      return new Response(
        JSON.stringify({ error: "firebase_uid manquant" }),
        { status: 400, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
      );
    }

    // Utiliser le service role pour bypass RLS
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

    // Vérifier si l'utilisateur existe déjà
    const { data: existing } = await supabase
      .from("users")
      .select("id")
      .eq("id", firebase_uid)
      .maybeSingle();

    if (existing) {
      // Mettre à jour les infos auth
      const { data, error } = await supabase
        .from("users")
        .update({
          display_name: display_name || undefined,
          email: email || undefined,
          phone: phone || undefined,
          photo_url: photo_url || undefined,
          auth_providers: auth_providers || undefined,
          updated_at: new Date().toISOString(),
        })
        .eq("id", firebase_uid)
        .select()
        .single();

      if (error) throw error;

      return new Response(JSON.stringify(data), {
        headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
      });
    } else {
      // Créer un nouveau profil
      const username = generateUsername(display_name || "user");

      const { data, error } = await supabase
        .from("users")
        .insert({
          id: firebase_uid,
          display_name: display_name || "Utilisateur",
          username,
          email,
          phone,
          photo_url,
          auth_providers: auth_providers || [],
          onboarding_completed: false,
        })
        .select()
        .single();

      if (error) throw error;

      // Créer les settings par défaut
      await supabase.from("user_settings").insert({
        user_id: firebase_uid,
      });

      console.log(`[sync-user] Nouveau user créé: ${firebase_uid} (@${username})`);

      return new Response(JSON.stringify(data), {
        status: 201,
        headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
      });
    }
  } catch (error) {
    console.error("[sync-user] Error:", error);
    return new Response(
      JSON.stringify({ error: error.message || "Erreur sync user" }),
      {
        status: 500,
        headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
      }
    );
  }
});

function generateUsername(displayName: string): string {
  const base = displayName
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "") // Retirer accents
    .replace(/[^a-z0-9]/g, "_")
    .replace(/_+/g, "_")
    .replace(/^_|_$/g, "")
    .substring(0, 15);

  const suffix = Math.floor(Math.random() * 9999)
    .toString()
    .padStart(4, "0");

  return `${base}_${suffix}`;
}
