# Supabase setup (PEYMI SaaS)

## 1. Create project

1. Create a project at [supabase.com](https://supabase.com).
2. Copy **Project URL** and **anon public key**.
3. Copy **service role key** — server/Edge Functions only. Never put it in the Flutter app.

## 2. Apply database migrations

Using [Supabase CLI](https://supabase.com/docs/guides/cli):

```bash
cd bakery_shop_app
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
```

Or run SQL files in order from `supabase/migrations/` in the SQL Editor.

## 3. Deploy Edge Functions

```bash
supabase functions deploy create-business
supabase functions deploy send-phone-otp
supabase functions deploy verify-phone-otp
supabase functions deploy super-admin-business
```

Set secrets in Supabase Dashboard → Edge Functions → Secrets:

- `SUPABASE_SERVICE_ROLE_KEY`
- `TWILIO_ACCOUNT_SID` / `TWILIO_AUTH_TOKEN` / `TWILIO_FROM_NUMBER` (production SMS)
- `ALLOW_DEV_OTP_RESPONSE=true` only for local dev (returns OTP in API response)

## 4. Storage

Migrations create buckets `business-logos` and `product-images`.

## 5. Super Admin

Promote a user after first sign-up:

```sql
update public.profiles
set role = 'super_admin'
where email = 'your-admin@email.com';
```

Open `/super-admin` in the app (requires Supabase dart-defines).

## 6. Run Flutter with Supabase

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

## 7. Security checklist

- Repository private; never commit `.env`.
- RLS enabled on all tenant tables.
- Sensitive actions use Edge Functions + service role where needed.
- `create-business` enforces `phone_verified` server-side.
- Customers blocked when business is suspended/cancelled/inactive (RLS + `business_accepts_customers`).
