import { corsHeaders } from "../_shared/cors.ts";
import { getServiceClient } from "../_shared/supabase.ts";

type CreatorAdminBody = {
  password?: string;
  action?: "list" | "update";
  business_id?: string;
  is_active?: boolean;
  subscription_status?: "trial" | "active" | "past_due" | "suspended" | "cancelled";
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = (await req.json()) as CreatorAdminBody;
    const expected = Deno.env.get("CREATOR_PASSWORD");
    if (!expected) {
      return json({ error: "CREATOR_PASSWORD not configured on server" }, 503);
    }
    if (!body.password || body.password !== expected) {
      return json({ error: "Forbidden" }, 403);
    }

    const service = getServiceClient();
    const action = body.action ?? "list";

    if (action === "list") {
      const rows = await service
        .from("businesses")
        .select("*, profiles!businesses_owner_id_fkey(email)")
        .order("created_at", { ascending: false });

      const businesses = [];
      for (const raw of rows.data ?? []) {
        const map = raw as Record<string, unknown>;
        const owner = map.profiles as Record<string, unknown> | null;
        const { profiles: _p, ...business } = map;
        const businessId = map.id as string;
        const [products, orders, appointments] = await Promise.all([
          service.from("products").select("id", { count: "exact", head: true }).eq("business_id", businessId),
          service.from("orders").select("id", { count: "exact", head: true }).eq("business_id", businessId),
          service.from("appointments").select("id", { count: "exact", head: true }).eq("business_id", businessId),
        ]);
        businesses.push({
          business,
          owner_email: owner?.email ?? null,
          product_count: products.count ?? 0,
          order_count: orders.count ?? 0,
          appointment_count: appointments.count ?? 0,
        });
      }
      return json({ businesses }, 200);
    }

    if (action === "update") {
      if (!body.business_id) return json({ error: "business_id required" }, 400);
      const patch: Record<string, unknown> = { updated_at: new Date().toISOString() };
      if (typeof body.is_active === "boolean") patch.is_active = body.is_active;
      if (body.subscription_status) patch.subscription_status = body.subscription_status;

      const { data, error } = await service
        .from("businesses")
        .update(patch)
        .eq("id", body.business_id)
        .select()
        .single();

      if (error) return json({ error: error.message }, 400);
      return json({ business: data }, 200);
    }

    return json({ error: "Unknown action" }, 400);
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
