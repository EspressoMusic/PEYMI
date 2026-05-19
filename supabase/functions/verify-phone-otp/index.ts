import { corsHeaders } from "../_shared/cors.ts";
import { normalizePhone } from "../_shared/phone.ts";
import { getServiceClient, getUserClient } from "../_shared/supabase.ts";

const MAX_VERIFY_ATTEMPTS = 5;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) return json({ error: "Unauthorized" }, 401);

    const userClient = getUserClient(authHeader);
    const { data: userData, error: userError } = await userClient.auth.getUser();
    if (userError || !userData.user) return json({ error: "Unauthorized" }, 401);

    const { phone, code } = (await req.json()) as { phone?: string; code?: string };
    if (!phone?.trim() || !code?.trim()) {
      return json({ error: "phone and code are required" }, 400);
    }

    const normalized = normalizePhone(phone);
    if (!normalized) return json({ error: "Invalid phone number" }, 400);

    const service = getServiceClient();
    const userId = userData.user.id;

    const { data: attempt, error: fetchError } = await service
      .from("phone_verification_attempts")
      .select("*")
      .eq("user_id", userId)
      .eq("phone", normalized)
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    if (fetchError || !attempt) {
      return json({ error: "Invalid or expired code" }, 400);
    }

    if (new Date(attempt.expires_at) < new Date()) {
      return json({ error: "Code expired. Request a new one." }, 400);
    }

    if (attempt.attempt_count >= MAX_VERIFY_ATTEMPTS) {
      return json({ error: "Too many attempts. Request a new code." }, 429);
    }

    const codeHash = await hashCode(code.trim());
    const valid = codeHash === attempt.code_hash;

    await service
      .from("phone_verification_attempts")
      .update({ attempt_count: attempt.attempt_count + 1 })
      .eq("id", attempt.id);

    if (!valid) {
      return json({ error: "Invalid code" }, 400);
    }

    const now = new Date().toISOString();
    const { error: profileError } = await service
      .from("profiles")
      .update({
        phone: attempt.phone,
        phone_verified: true,
        phone_verified_at: now,
        updated_at: now,
      })
      .eq("id", userId);

    if (profileError) {
      return json({ error: profileError.message }, 500);
    }

    return json({ ok: true, phone_verified: true }, 200);
  } catch (e) {
    return json({ error: (e as Error).message ?? "Server error" }, 500);
  }
});

async function hashCode(code: string): Promise<string> {
  const data = new TextEncoder().encode(code);
  const digest = await crypto.subtle.digest("SHA-256", data);
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

function json(payload: unknown, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
