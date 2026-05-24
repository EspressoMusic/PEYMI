import { corsHeaders } from "../_shared/cors.ts";
import { getServiceClient, getUserClient } from "../_shared/supabase.ts";

type AdminUpdateBody = {
  business_id: string;
  is_active?: boolean;
  subscription_status?: "trial" | "active" | "past_due" | "suspended" | "cancelled";
  past_due_grace_until?: string | null;
  store_mode?: "products" | "appointments";
};

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

    const service = getServiceClient();
    const { data: profile } = await service
      .from("profiles")
      .select("role")
      .eq("id", userData.user.id)
      .single();

    if (profile?.role !== "super_admin") {
      return json({ error: "Forbidden" }, 403);
    }

    const body = (await req.json()) as AdminUpdateBody;
    if (!body.business_id) return json({ error: "business_id required" }, 400);

    const patch: Record<string, unknown> = { updated_at: new Date().toISOString() };
    if (typeof body.is_active === "boolean") patch.is_active = body.is_active;
    if (body.subscription_status) patch.subscription_status = body.subscription_status;
    if (body.past_due_grace_until !== undefined) {
      patch.past_due_grace_until = body.past_due_grace_until;
    }
    if (body.store_mode === "products" || body.store_mode === "appointments") {
      patch.store_mode = body.store_mode;
    }

    const { data, error } = await service
      .from("businesses")
      .update(patch)
      .eq("id", body.business_id)
      .select()
      .single();

    if (error) return json({ error: error.message }, 400);
    return json({ business: data }, 200);
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
