# Security checklist (pilot release)

## What is protected

| Layer | Protection |
|--------|------------|
| **Supabase RLS** | Tenant data: owners see only their business; customers see only their rows; inserts blocked when business is suspended/cancelled/inactive (`business_accepts_customers`). |
| **Profiles** | Users cannot self-promote to `super_admin` (trigger `prevent_profile_sensitive_self_update`). |
| **Businesses** | Owners cannot change billing fields (`prevent_business_billing_tamper`); delete only for `super_admin`. |
| **Super Admin UI** | `SuperAdminGate` checks `profiles.role = super_admin` via Supabase before showing UI. |
| **App Creator** | Password checked only in Edge Function `creator-admin` using `CREATOR_PASSWORD` secret (not in Flutter). |
| **Payments** | `STRIPE_SECRET_KEY` only in `server/.env`; Flutter uses publishable key + backend URL via `--dart-define`. |
| **OTP / SMS** | Twilio credentials only in Supabase Edge Function secrets; no OTP in API response unless `ALLOW_DEV_OTP_RESPONSE=true`. |
| **Release APK** | `--obfuscate` + `--split-debug-info` (see build script below). |
| **Logging** | `AppLog` and Flutter `debugPrint` are no-ops in release (`kDebugMode`). |

## What cannot be fully protected

- **Reverse engineering**: Obfuscation slows copying; a determined attacker can still decompile. Real secrets must never be in the APK.
- **Supabase anon key**: Expected in the client (web landing + app). Security is **RLS + Edge Functions**, not hiding the anon key.
- **Manager / employee PIN**: Client-side gate only (compile-time `--dart-define`). Use strong PINs for pilot; plan Supabase Auth for production staff.
- **Business logic in Dart**: UI flows can be copied; enforce rules in Postgres RLS and Edge Functions.

## Secrets — never commit

| Secret | Where it lives |
|--------|----------------|
| `.env` | Local only (gitignored) |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase Edge secrets / server only |
| `SUPABASE_ACCESS_TOKEN` | Local CLI / CI only |
| `SUPABASE_DB_PASSWORD` | Password manager / Supabase dashboard |
| `TWILIO_*` | Supabase Edge secrets |
| `STRIPE_SECRET_KEY` | `server/.env` only |
| `CREATOR_PASSWORD` | Supabase Edge secret `CREATOR_PASSWORD` |
| `docs/config.js` | Generated locally (`tools/generate_peymii_config.ps1`) — gitignored |
| `build/debug-info/` | Obfuscation symbols — **private**, gitignored |

**Safe in git:** `SUPABASE_ANON_KEY` in examples only; real project anon key should be in `.env` / generated `docs/config.js` (not tracked).

## Before every push

```powershell
.\tools\verify_no_secrets.ps1
```

If `docs/config.js` was committed earlier:

```powershell
git rm --cached docs/config.js
git commit -m "Stop tracking generated landing config"
```

## Build a protected pilot APK

1. Fill `.env` (see `.env.example`) — **do not commit**.
2. Optional pilot staff PINs in `.env`: `MANAGER_PIN`, `EMPLOYEE_PIN`.
3. Run:

```powershell
.\tools\build_test_apk.ps1
```

Output: `release/bizmi-pilot-release.apk` (obfuscated).  
Debug symbols: `build/debug-info/` — store offline for crash reports; never upload to public GitHub.

Fast debug build (no obfuscation):

```powershell
.\tools\build_test_apk.ps1 -Debug
```

## Supabase RLS verification (manual)

In SQL Editor, confirm policies exist (migrations `20250519100200_rls_policies.sql` + later):

- `businesses_update_owner` — `owner_id = auth.uid()`
- `orders_select_owner` — owner or customer’s own order
- `orders_insert_customer` — `business_accepts_customers(business_id)`
- `products_select_public` — active + publicly visible business, or owner
- `profiles` — no self role escalation (trigger)

Suspended store: `business_accepts_customers` returns false for `suspended` / `cancelled` / inactive.

## Edge Function secrets (production)

Set in Supabase Dashboard → Edge Functions → Secrets:

- `CREATOR_PASSWORD` (required for creator-admin)
- `SUPABASE_SERVICE_ROLE_KEY`
- Twilio vars for SMS
- Do **not** set `ALLOW_DEV_OTP_RESPONSE=true` in production
