import { corsHeaders } from "../_shared/cors.ts";
import { getServiceClient } from "../_shared/supabase.ts";

type InquiryBody = {
  business_id?: string;
  business_slug?: string;
  message?: string;
  customer_name?: string;
  customer_phone?: string;
  customer_email?: string;
  channel?: string;
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = (await req.json()) as InquiryBody;
    const message = body.message?.trim();
    if (!message) {
      return json({ error: "message is required" }, 400);
    }

    const service = getServiceClient();
    let businessQuery = service
      .from("businesses")
      .select("id, business_name, slug, contact_email, owner_id, is_active")
      .limit(1);

    if (body.business_id?.trim()) {
      businessQuery = businessQuery.eq("id", body.business_id.trim());
    } else if (body.business_slug?.trim()) {
      businessQuery = businessQuery.eq("slug", body.business_slug.trim().toLowerCase());
    } else {
      return json({ error: "business_id or business_slug required" }, 400);
    }

    const { data: business, error: businessError } = await businessQuery.single();
    if (businessError || !business) {
      return json({ error: "Store not found" }, 404);
    }
    if (!business.is_active) {
      return json({ error: "Store is not accepting messages" }, 403);
    }

    const { data: inserted, error: insertError } = await service
      .from("customer_messages")
      .insert({
        business_id: business.id,
        message,
        customer_name: body.customer_name?.trim() || null,
        customer_phone: body.customer_phone?.trim() || null,
        customer_email: body.customer_email?.trim() || null,
      })
      .select("id")
      .single();

    if (insertError) {
      return json({ error: insertError.message }, 400);
    }

    let to = business.contact_email?.trim() || "";
    if (!to) {
      const { data: ownerProfile } = await service
        .from("profiles")
        .select("email")
        .eq("id", business.owner_id)
        .maybeSingle();
      to = (ownerProfile?.email as string | undefined)?.trim() || "";
    }

    if (!to) {
      return json(
        {
          ok: true,
          message_id: inserted?.id,
          email_sent: false,
          recipient: null,
          warning: "Store has no inquiry email configured",
        },
        200,
      );
    }

    const resendKey = Deno.env.get("RESEND_API_KEY")?.trim();
    const fromEmail = Deno.env.get("INQUIRY_FROM_EMAIL")?.trim() || "onboarding@resend.dev";

    if (!resendKey) {
      return json(
        {
          ok: true,
          message_id: inserted?.id,
          email_sent: false,
          recipient: to,
          warning: "Email delivery is not configured (RESEND_API_KEY missing)",
        },
        200,
      );
    }

    const customerLines = [
      body.customer_name?.trim() ? `Name: ${body.customer_name.trim()}` : null,
      body.customer_email?.trim() ? `Email: ${body.customer_email.trim()}` : null,
      body.customer_phone?.trim() ? `Phone: ${body.customer_phone.trim()}` : null,
    ].filter(Boolean);

    const subject = `New inquiry — ${business.business_name}`;
    const text = [
      `Store: ${business.business_name} (${business.slug})`,
      `Channel: ${body.channel?.trim() || "app"}`,
      "",
      ...customerLines,
      "",
      message,
    ].join("\n");

    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${resendKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: fromEmail,
        to: [to],
        subject,
        text,
      }),
    });

    if (!res.ok) {
      const errText = await res.text();
      return json(
        {
          ok: true,
          message_id: inserted?.id,
          email_sent: false,
          recipient: to,
          warning: `Email provider error: ${errText}`,
        },
        200,
      );
    }

    return json(
      {
        ok: true,
        message_id: inserted?.id,
        email_sent: true,
        recipient: to,
      },
      200,
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
