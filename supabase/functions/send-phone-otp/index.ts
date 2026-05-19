import { corsHeaders } from "../_shared/cors.ts";
import { normalizePhone } from "../_shared/phone.ts";
import { getServiceClient, getUserClient } from "../_shared/supabase.ts";

const OTP_TTL_MINUTES = 10;
const MAX_SENDS_PER_HOUR = 5;

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

    const { phone } = (await req.json()) as { phone?: string };
    const normalized = normalizePhone(phone);
    if (!normalized) return json({ error: "Invalid phone number" }, 400);

    const service = getServiceClient();
    const userId = userData.user.id;

    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000).toISOString();
    const { count } = await service
      .from("phone_verification_attempts")
      .select("id", { count: "exact", head: true })
      .eq("user_id", userId)
      .gte("created_at", oneHourAgo);

    if ((count ?? 0) >= MAX_SENDS_PER_HOUR) {
      return json({ error: "Too many verification attempts. Try again later." }, 429);
    }

    const code = String(Math.floor(100000 + Math.random() * 900000));
    const codeHash = await hashCode(code);
    const expiresAt = new Date(Date.now() + OTP_TTL_MINUTES * 60 * 1000).toISOString();

    const { error: insertError } = await service.from("phone_verification_attempts").insert({
      user_id: userId,
      phone: normalized,
      code_hash: codeHash,
      expires_at: expiresAt,
      attempt_count: 0,
    });
    if (insertError) {
      console.error("OTP insert failed", insertError);
      return json({ error: "Could not store verification code" }, 500);
    }

    // Prefer Supabase Auth phone OTP when configured; otherwise plug Twilio here.
    const twilioSid = Deno.env.get("TWILIO_ACCOUNT_SID");
    const twilioToken = Deno.env.get("TWILIO_AUTH_TOKEN");
    const twilioFrom = Deno.env.get("TWILIO_FROM_NUMBER");

    if (twilioSid && twilioToken && twilioFrom) {
      const basic = btoa(`${twilioSid}:${twilioToken}`);
      const res = await fetch(
        `https://api.twilio.com/2010-04-01/Accounts/${twilioSid}/Messages.json`,
        {
          method: "POST",
          headers: {
            Authorization: `Basic ${basic}`,
            "Content-Type": "application/x-www-form-urlencoded",
          },
          body: new URLSearchParams({
            To: normalized,
            From: twilioFrom,
            Body: `Your verification code is ${code}`,
          }),
        },
      );
      if (!res.ok) {
        const errText = await res.text();
        console.error("Twilio error", errText);
        return json({ error: "Failed to send SMS" }, 502);
      }
    } else if (Deno.env.get("ALLOW_DEV_OTP_RESPONSE") === "true") {
      // Development only — never enable in production.
      return json({ ok: true, dev_code: code }, 200);
    } else {
      console.log(`OTP for ${normalized}: ${code} (configure Twilio or ALLOW_DEV_OTP_RESPONSE)`);
      return json(
        {
          ok: true,
          dev_code: code,
          message: "SMS not configured — use dev_code (development only)",
        },
        200,
      );
    }

    return json({ ok: true }, 200);
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
