# PEYMI / Bakery App — רשימת התקנה ידנית (SETUP TODO)

מסמך זה מפרט **מה כבר קיים בקוד** ומה **אתה חייב לעשות בעצמך** כדי שה-SaaS עם Supabase יעבוד.

---

## סטטוס כללי (חשוב)

| נושא | מצב |
|------|-----|
| קוד Flutter (מסכים, לוגיקה, חיבור ל-Supabase) | ✅ קיים ב-repo |
| קבצי SQL migrations | ✅ קיימים ב-`supabase/migrations/` |
| Edge Functions (קוד) | ✅ קיימים ב-`supabase/functions/` |
| פרויקט Supabase אמיתי מחובר | ❌ **לא** — אין לנו גישה לחשבון שלך |
| DB בפרודקשן רץ אצלך | ❌ עד שתיצור פרויקט ותריץ migrations |
| SMS אמיתי (Twilio) | ❌ אופציונלי — אפשר dev בינתיים |
| תשלומים / מנוי אוטומטי (Stripe → subscription) | ❌ עדיין לא מחובר |

**בלי Supabase מוגדר:** האפליקציה הרגילה (קטלוג, מנהל מקומי, עובד, דילים וכו') ממשיכה לעבוד כמו קודם.  
**ריבוע "יצירת חנות" בהגדרות מופיע רק אחרי** שמגדירים `SUPABASE_URL` + `SUPABASE_ANON_KEY`.

---

## מה אתה צריך להכין (מפתחות)

### חובה

| ערך | איפה משתמשים | האם לשלוח לצ'אט/AI |
|-----|----------------|---------------------|
| `SUPABASE_URL` | אפליקציית Flutter (`--dart-define`) | מותר (לא סודי) |
| `SUPABASE_ANON_KEY` | אפליקציית Flutter (`--dart-define`) | מותר (ציבורי עם RLS) |
| `SUPABASE_SERVICE_ROLE_KEY` | **רק** Supabase Edge Functions / שרת | **לא** — לעולם לא באפליקציה ולא בצ'אט |

איפה למצוא ב-Supabase Dashboard → **Project Settings → API**:
- Project URL → `SUPABASE_URL`
- `anon` `public` → `SUPABASE_ANON_KEY`
- `service_role` `secret` → `SUPABASE_SERVICE_ROLE_KEY`

### אופציונלי (SMS אמיתי)

| ערך | איפה |
|-----|------|
| `TWILIO_ACCOUNT_SID` | Supabase → Edge Functions → Secrets |
| `TWILIO_AUTH_TOKEN` | Supabase → Edge Functions → Secrets |
| `TWILIO_FROM_NUMBER` | Supabase → Edge Functions → Secrets |

### פיתוח בלבד (בלי Twilio)

| ערך | איפה |
|-----|------|
| `ALLOW_DEV_OTP_RESPONSE=true` | Supabase Edge Functions → Secrets |

כשזה דלוק, פונקציית `send-phone-otp` מחזירה את הקוד ב-JSON (למפתחים בלבד). **אל תדליק בפרודקשן.**

### לא נדרש כרגע

- מפתחות Stripe ל-SaaS (מנוי אוטומטי עדיין לא ממומש)
- מפתחות אחרים מהאפליקציה הישנה (Stripe מקומי ב-`server/` נפרד)

---

## שלב 1 — חשבון ופרויקט Supabase (ידני)

- [ ] הירשם / התחבר ל-[https://supabase.com](https://supabase.com)
- [ ] **New project** → בחר שם, סיסמת DB, אזור (קרוב אליך)
- [ ] המתן עד שהפרויקט במצב Ready
- [ ] העתק: **Project URL**, **anon key**, **service_role key** (שמור במקום בטוח)

---

## שלב 2 — מסד נתונים (migrations)

### אופציה א' — SQL Editor (הכי פשוט)

- [ ] Dashboard → **SQL Editor** → New query
- [ ] הרץ **לפי הסדר** את הקבצים:
  1. `supabase/migrations/20250519100000_initial_saas_schema.sql`
  2. `supabase/migrations/20250519100100_security_functions.sql`
  3. `supabase/migrations/20250519100200_rls_policies.sql`
  4. `supabase/migrations/20250519100300_storage.sql`
- [ ] ודא שאין שגיאות אדומות

### אופציה ב' — Supabase CLI

- [ ] התקן [Supabase CLI](https://supabase.com/docs/guides/cli)
- [ ] `cd bakery_shop_app`
- [ ] `supabase login`
- [ ] `supabase link --project-ref YOUR_PROJECT_REF`  
  (ה-ref מופיע ב-URL: `https://supabase.com/dashboard/project/XXXXX`)
- [ ] `supabase db push`

---

## שלב 3 — Edge Functions

- [ ] התקן Supabase CLI (אם עדיין לא)
- [ ] מתוך שורש הפרויקט:

```powershell
cd c:\Users\Nirhdhd\bakery_shop_app
supabase functions deploy create-business
supabase functions deploy send-phone-otp
supabase functions deploy verify-phone-otp
supabase functions deploy super-admin-business
```

- [ ] Dashboard → **Edge Functions** → **Secrets** — הוסף:

```
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_ANON_KEY=eyJ...anon...
SUPABASE_SERVICE_ROLE_KEY=eyJ...service_role...
ALLOW_DEV_OTP_RESPONSE=true
```

(בפרודקשן: Twilio במקום `ALLOW_DEV_OTP_RESPONSE`, או בנוסף.)

> הערה: לפעמים Supabase מזריק אוטומטית `SUPABASE_URL` ו-`SERVICE_ROLE` — בדוק בדשבורד מה כבר קיים.

---

## שלב 4 — Auth באפליקציה

- [ ] Dashboard → **Authentication** → **Providers** → **Email** — ודא שמופעל
- [ ] (אופציונלי) כבה "Confirm email" לבדיקות מהירות:  
  Authentication → Providers → Email → **Confirm email** = off

---

## שלב 5 — הרצת האפליקציה עם Supabase

הסקריפט `tools\refresh_app.ps1` **לא** מעביר מפתחות Supabase כברירת מחדל.  
צריך להריץ עם `--dart-define` (או לעדכן את הסקריפט).

### הרצה על הטלפון (דוגמה)

```powershell
cd c:\Users\Nirhdhd\bakery_shop_app
flutter run -d RZCYA1S0LGL `
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi...
```

### ריענון כפוי אחרי שינוי קוד

```powershell
.\tools\refresh_app.ps1 -Force
```

(אחרי שעדכנת את `refresh_app.ps1` עם dart-define — ראה שלב 5א למטה)

### שלב 5א — עדכון refresh_app.ps1 (מומלץ)

- [ ] פתח `tools\refresh_app.ps1` והוסף בשורת `flutter run` / `flutter build apk` את אותם `--dart-define` עם הערכים שלך  
  **או** שמור ערכים בקובץ מקומי שלא עולה ל-Git (ראה `.env.example`)

---

## שלב 6 — בדיקות (אחרי שהכל למעלה הושלם)

### 6.1 הרשמת משתמש

- [ ] פתח אפליקציה → **הגדרות** → **יצירת חנות** (אמור להופיע רק עם Supabase מוגדר)
- [ ] התחבר / הירשם (מסך Sign up / Sign in)
- [ ] ב-Supabase: **Table Editor** → `profiles` — שורה חדשה עם ה-`id` שלך, `role` = `customer`

### 6.2 אימות טלפון

- [ ] אחרי התחברות → מסך: *"To create a store, please verify your phone number."*
- [ ] הזן טלפון → Send code
- [ ] **אם `ALLOW_DEV_OTP_RESPONSE=true`:** ב-Logs של Edge Function או בתשובת הרשת יופיע `dev_code` (בפיתוח)
- [ ] הזן קוד → Verify
- [ ] ב-`profiles`: `phone_verified` = `true`, `phone_verified_at` מלא

### 6.3 פתיחת חנות

- [ ] מסך Create Store: **Store Name** + **Store Link** (slug, למשל `david-fashion`)
- [ ] Create Store
- [ ] הודעה: *"Your store is ready."*
- [ ] ב-`businesses`: שורה עם `owner_id` שלך, `subscription_status` = `trial`, `is_active` = true
- [ ] ב-`profiles`: `role` אמור להתעדכן ל-`business_owner`

### 6.4 לינק ציבורי לחנות

- [ ] בדשבורד הבעלים: **Copy Link** / **Open Store**
- [ ] הנתיב באפליקציה: `/{slug}` למשל `/david-fashion`
- [ ] מכשיר אחר / משתמש לא מחובר: אותו נתיב אמור להציג את דף החנות הציבורי
- [ ] אם העסק מושבת — *"This business is currently unavailable."*
- [ ] אם slug לא קיים — *"Store not found."*

> ב-Web/deep link מלא עדיין מוגבל; בנייד הניווט דרך `onGenerateRoute` עובד.

### 6.5 Super Admin

- [ ] אחרי הרשמה עם המייל שלך, הרץ ב-SQL Editor:

```sql
update public.profiles
set role = 'super_admin'
where email = 'YOUR_EMAIL@example.com';
```

- [ ] סגור ופתח את האפליקציה (עם Supabase מוגדר)
- [ ] ניווט ל-`/super-admin` (במכשיר: דרך adb או הוספת כפתור זמני בקוד)  
  ```powershell
  adb shell am start -a android.intent.action.VIEW -d "peymi://super-admin" 
  ```
  *(אם אין deep link — השתמש ב-Flutter: שנה זמנית `home` או הוסף כפתור בהגדרות)*

- [ ] אמור לראות רשימת כל העסקים, חיפוש, Activate / Suspend

**דרך פשוטה לבדיקה:** הוסף בקוד זמנית ניווט ל-`SuperAdminScreen` מכפתור בהגדרות (רק לך).

### 6.6 השבתת עסק

- [ ] ב-Super Admin: **Suspend** על עסק
- [ ] ודא: `subscription_status` = `suspended` או `is_active` = false
- [ ] פתח את הלינק הציבורי — *"This business is currently unavailable."*
- [ ] נסה ליצור הזמנה — אמור להיחסם (RLS)
- [ ] בעל העסק: דשבורד נעול עם הודעת השעיה (חלק billing עדיין UI בסיסי)

---

## מה עובד היום ב-UI (כנה)

| תכונה | מצב |
|--------|-----|
| הרשמה / התחברות אימייל | ✅ |
| אימות טלפון (OTP) | ✅ עם `ALLOW_DEV_OTP_RESPONSE` או Twilio |
| יצירת חנות (Edge Function + RLS) | ✅ |
| דף חנות ציבורי `/{slug}` | ✅ (באפליקציה) |
| הזמנה בסיסית מדף ציבורי | ✅ |
| הודעה לעסק (customer_messages) | ✅ |
| דשבורד בעלים (צפייה, קישור, השעיה) | ✅ חלקי |
| הוספת/עריכת מוצרים בדשבורד | ⚠️ בעיקר דרך Supabase Table Editor / UI עדיין לא מלא |
| תורים (appointments) ב-UI | ⚠️ DB + RLS קיימים, UI ציבורי מינימלי |
| מנוי / תשלום אוטומטי | ❌ |
| Super Admin ניווט נוח מהאפליקציה | ⚠️ מסך קיים, צריך ניווט ל-`/super-admin` |

---

## מה **לא** לשלוח לי (AI) / ל-GitHub

- [ ] לעולם אל תעלה `.env` עם מפתחות אמיתיים
- [ ] אל תשים `SUPABASE_SERVICE_ROLE_KEY` באפליקציית Flutter
- [ ] אל תדליק `ALLOW_DEV_OTP_RESPONSE=true` בפרודקשן

---

## קבצי עזר בפרויקט

| קובץ | תוכן |
|------|--------|
| `docs/SUPABASE_SETUP.md` | סיכום טכני באנגלית |
| `.env.example` | תבנית משתני סביבה |
| `supabase/migrations/` | סכמת DB + RLS |
| `supabase/functions/` | לוגיקת שרת רגישה |

---

## סיום

כשכל הסעיפים למעלה מסומנים — הבסיס SaaS אצלך **חי**.  
אם משהו נכשל, בדוק בסדר:

1. האם `dart-define` באמת הועברו בהרצה  
2. האם כל 4 קבצי ה-migration רצו בלי שגיאה  
3. האם כל 4 ה-Edge Functions נפרסו + Secrets  
4. Logs: Supabase → Edge Functions → Logs  

---

*עודכן לפי מצב הקוד ב-repo — Supabase לא מחובר אוטומטית לחשבון שלך.*
