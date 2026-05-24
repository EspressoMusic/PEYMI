import { corsHeaders } from "../_shared/cors.ts";
import { getServiceClient } from "../_shared/supabase.ts";

type DealPushBody = {
  business_slug?: string;
  title_he?: string;
  title_en?: string;
  body_he?: string;
  body_en?: string;
};

const CHUNK = 500;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = (await req.json()) as DealPushBody;
    const slug = body.business_slug?.trim().toLowerCase();
  if (!slug) {
      return json({ error: "business_slug is required" }, 400);
    }

    const titleHe = body.title_he?.trim() || "מבצע חדש!";
    const titleEn = body.title_en?.trim() || "New deal!";
    const bodyHe = body.body_he?.trim() || titleHe;
    const bodyEn = body.body_en?.trim() || titleEn;

    const service = getServiceClient();
    const { data: business, error: businessError } = await service
      .from("businesses")
      .select("id, business_name, slug, is_active")
      .eq("slug", slug)
      .maybeSingle();

    if (businessError) {
      return json({ error: businessError.message }, 400);
    }
    if (!business) {
      return json({ error: "Store not found" }, 404);
    }

    const { data: rows, error: tokenError } = await service
      .from("store_push_tokens")
      .select("fcm_token, locale")
      .eq("business_slug", slug);

    if (tokenError) {
      return json({ error: tokenError.message }, 400);
    }

    const tokens = (rows ?? [])
      .map((r) => (r.fcm_token as string | undefined)?.trim())
      .filter((t): t is string => !!t && t.length > 20);

    if (tokens.length === 0) {
      return json({ ok: true, sent: 0, warning: "No registered devices for this store" }, 200);
    }

    const fcmKey = Deno.env.get("FCM_SERVER_KEY")?.trim();
    if (!fcmKey) {
      return json(
        {
          ok: true,
          sent: 0,
          registered: tokens.length,
          warning: "FCM_SERVER_KEY is not configured on the server",
        },
        200,
      );
    }

    const localeByToken = new Map<string, string>();
    for (const row of rows ?? []) {
      const token = (row.fcm_token as string | undefined)?.trim();
      if (token) localeByToken.set(token, (row.locale as string | undefined) ?? "he");
    }

    let sent = 0;
    for (let i = 0; i < tokens.length; i += CHUNK) {
      const chunk = tokens.slice(i, i + CHUNK);
      const heTokens = chunk.filter((t) => (localeByToken.get(t) ?? "he").startsWith("he"));
      const enTokens = chunk.filter((t) => !(localeByToken.get(t) ?? "he").startsWith("he"));

      if (heTokens.length) {
        sent += await sendFcmBatch(fcmKey, heTokens, titleHe, bodyHe, slug);
      }
      if (enTokens.length) {
        sent += await sendFcmBatch(fcmKey, enTokens, titleEn, bodyEn, slug);
      }
    }

    return json({ ok: true, sent, registered: tokens.length }, 200);
  } catch (e) {
    return json({ error: (e as Error).message ?? "Server error" }, 500);
  }
});

async function sendFcmBatch(
  serverKey: string,
  tokens: string[],
  title: string,
  body: string,
  slug: string,
): Promise<number> {
  if (!tokens.length) return 0;

  const res = await fetch("https://fcm.googleapis.com/fcm/send", {
    method: "POST",
    headers: {
      Authorization: `key=${serverKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      registration_ids: tokens,
      priority: "high",
      notification: {
        title,
        body,
        sound: "default",
      },
      data: {
        type: "deal",
        slug,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
    }),
  });

  if (!res.ok) {
    console.error("FCM error", await res.text());
    return 0;
  }

  const payload = await res.json();
  const success = typeof payload?.success === "number" ? payload.success : tokens.length;
  return success;
}

function json(payload: unknown, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
