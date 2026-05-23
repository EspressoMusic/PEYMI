# Customer payment integration (future)

Stage 1 (pilot) uses `business_payment_settings` for manual / external instructions only.
Peymiz does **not** process or hold customer funds in the pilot.

## TODO — provider integrations

- [ ] **Stripe Connect** — international marketplace payments; connected accounts per business; no platform-held customer cards in Flutter.
- [ ] **Grow / Meshulam** — Israeli payments (credit card, Bit, PayBox, etc.).
- [ ] **Webhooks** — payment status callbacks (`payment_intent.succeeded`, provider-specific events) to update `orders` / `appointments` payment state.
- [ ] **Platform commission** — configurable take rate; payout splits via Connect / provider APIs.

## TODO — schema / app

- [ ] `payment_mode = future_provider` + provider credentials stored server-side only (Edge Functions / Vault).
- [ ] Customer payment status on orders/appointments (`unpaid`, `pending`, `paid`, `failed`).
- [ ] Never store PAN/CVV in Supabase or Flutter; PCI scope stays with providers.

## Related

- Migration: `supabase/migrations/20260520150000_business_payment_settings.sql`
- Owner UI: `lib/saas/widgets/owner_payment_settings_panel.dart`
- Customer UI: `lib/saas/widgets/customer_payment_instructions.dart`

**Not** Peymiz subscription billing (`businesses.subscription_status`, owner dashboard past-due card).
