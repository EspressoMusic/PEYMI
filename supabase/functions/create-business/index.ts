import { corsHeaders } from "../_shared/cors.ts";
import { getServiceClient, getUserClient } from "../_shared/supabase.ts";

type CreateBusinessBody = {
  business_name: string;
  slug: string;
  manager_pin: string;
  description?: string;
  logo_url?: string;
  phone?: string;
  business_type?: string;
  address?: string;
  contact_email?: string;
  opening_hours?: Record<string, unknown>;
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return json({ error: "Unauthorized" }, 401);
    }

    const userClient = getUserClient(authHeader);
    const { data: userData, error: userError } = await userClient.auth.getUser();
    if (userError || !userData.user) {
      return json({ error: "Unauthorized" }, 401);
    }

    const body = (await req.json()) as CreateBusinessBody;
    if (!body.business_name?.trim() || !body.slug?.trim()) {
      return json({ error: "business_name and slug are required" }, 400);
    }
    if (!body.manager_pin?.trim() || body.manager_pin.trim().length < 4) {
      return json({ error: "manager_pin must be at least 4 characters" }, 400);
    }

    const service = getServiceClient();
    const userId = userData.user.id;

    const { data: profile, error: profileError } = await service
      .from("profiles")
      .select("phone_verified, role")
      .eq("id", userId)
      .single();

    if (profileError || !profile) {
      return json({ error: "Profile not found" }, 403);
    }

    if (!profile.phone_verified) {
      return json({ error: "Phone verification required before creating a store" }, 403);
    }

    const { data: normalizedSlug, error: slugError } = await service.rpc("normalize_slug", {
      input: body.slug,
    });
    if (slugError || !normalizedSlug) {
      return json({ error: "Invalid store link" }, 400);
    }

    const { data: available } = await service.rpc("is_slug_available", {
      p_slug: normalizedSlug,
    });
    if (!available) {
      return json({
        error: "This store link is already taken. Please choose another one.",
      }, 409);
    }

    const { data: pinHash, error: pinHashError } = await service.rpc("hash_manager_pin", {
      p_pin: body.manager_pin.trim(),
    });
    if (pinHashError || !pinHash) {
      return json({ error: "Could not secure manager password" }, 500);
    }

    const { data: business, error: insertError } = await service
      .from("businesses")
      .insert({
        owner_id: userId,
        business_name: body.business_name.trim(),
        slug: normalizedSlug,
        manager_pin_hash: pinHash,
        description: body.description?.trim() || null,
        logo_url: body.logo_url || null,
        phone: body.phone?.trim() || null,
        business_type: body.business_type?.trim() || null,
        address: body.address?.trim() || null,
        contact_email: body.contact_email?.trim() || userData.user.email?.trim() || null,
        opening_hours: body.opening_hours ?? null,
        subscription_status: "trial",
        is_active: true,
      })
      .select()
      .single();

    if (insertError) {
      if (insertError.code === "23505") {
        return json({
          error: "This store link is already taken. Please choose another one.",
        }, 409);
      }
      return json({ error: insertError.message }, 400);
    }

    const publicBase = (Deno.env.get("PUBLIC_STORE_BASE_URL") ?? "https://bizmi.app").replace(/\/+$/, "");
    return json(
      {
        business,
        public_path: `/${normalizedSlug}`,
        public_url: `${publicBase}/${normalizedSlug}`,
      },
      201,
    );
  } catch (e) {
    return json({ error: (e as Error).message ?? "Server error" }, 500);
  }
});

function json(payload: unknown, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
