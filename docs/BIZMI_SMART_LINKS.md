# Bizmi smart links (`https://bizmi.app/{slug}`)

## עברית (סיכום)

כשאתם שולחים ללקוח קישור כמו `https://bizmi.app/shiki`:

1. **האפליקציה מותקנת** — הקישור נפתח באפליקציה על מסך החנות.
2. **אין אפליקציה** — דף הנחיתה ב-`bizmi.app` מזהה **Android** או **iPhone/iPad** ומפנה אוטומטית ל-**Google Play** או **App Store** (אחרי ניסיון קצר לפתוח את האפליקציה).
3. **מחשב** — מוצגות שתי כפתורי הורדה (Play + App Store).

**פריסה (חובה פעם אחת):**

```powershell
# ב-.env: SUPABASE_URL, SUPABASE_ANON_KEY, PLAY_STORE_URL, APP_STORE_URL (כשיש)
.\tools\generate_bizmi_config.ps1
.\tools\deploy_bizmi_landing.ps1   # או העלאה ידנית של hosting/bizmi/public ל-Vercel/Netlify
```

DNS: `bizmi.app` → אותו אחסון סטטי. בלי `config.js` בפרודקשן הזיהוי לא יעבוד.

קישור ישיר לחנות בלי ניסיון פתיחת אפליקציה: `https://bizmi.app/shiki?download=1`

---

## Behavior

| Context | Result |
|--------|--------|
| App installed | `https://bizmi.app/shiki` opens the app on the public store screen for slug `shiki` |
| App not installed | Landing page detects **Android** vs **iPhone/iPad** and redirects to Google Play or App Store (after a short attempt to open the app) |
| In-app navigation | Still uses internal route `/shiki` via `Navigator.pushNamed` |
| Share / copy | Always full URL `https://bizmi.app/shiki` |

## Flutter

- Base URL: `--dart-define=PUBLIC_STORE_BASE_URL=https://bizmi.app` (optional; default is `https://bizmi.app`)
- Add to `.env`: `PUBLIC_STORE_BASE_URL=https://bizmi.app` (picked up by `tools/refresh_app.ps1`)
- Deep links: `app_links` in `lib/core/store_deep_links.dart`

## Deploy web + verification files

1. Run `.\tools\generate_bizmi_config.ps1` (from `.env`) or copy `config.example.js` → `config.js` with Supabase + **real** store URLs.
2. Deploy `hosting/bizmi` to `bizmi.app` (`.\tools\deploy_bizmi_landing.ps1` or Vercel/Netlify — `vercel.json` included).
3. Update **Android** `/.well-known/assetlinks.json`:
   - `package_name` must match `applicationId` in `android/app/build.gradle.kts`
   - Add SHA-256 of your **release** signing cert (`keytool` / Play App Signing)
4. Update **iOS** `/.well-known/apple-app-site-association`:
   - Replace `TEAMID` with your Apple Team ID + bundle id (`com.example.bakeryShopApp` today)
5. Enable **Associated Domains** in Apple Developer for the app ID.

## Test Android App Link

```powershell
adb shell am start -a android.intent.action.VIEW -d "https://bizmi.app/your-slug" com.example.bakery_shop_app
```

## Test custom scheme

```powershell
adb shell am start -a android.intent.action.VIEW -d "bizmi://your-slug" com.example.bakery_shop_app
```

## Supabase Edge Function

`create-business` returns `public_url` and `public_path`. Optional secret: `PUBLIC_STORE_BASE_URL=https://bizmi.app`.

## Production checklist

- [ ] Point DNS `bizmi.app` → static host
- [ ] Replace example bundle IDs / team ID in verification files
- [ ] Publish app with matching package name and entitlements
- [ ] Rebuild app after changing `PUBLIC_STORE_BASE_URL`
