# GitHub Pages — דף קישור חכם (זמני)

מטרה: לקוח פותח  
`https://espressomusic.github.io/PEYMI/shiki`

| מצב | התנהגות |
|-----|---------|
| אפליקציה מותקנת | ניסיון לפתוח את החנות באפליקציה |
| לא מותקנת | דף בדיקות + שם חנות (מ-Supabase) + כפתור APK או "Download link is not available yet." |

---

## 1. ודאו שהתיקייה `docs/` ב-Git

הקבצים כבר ב-repo: `index.html`, `landing.js`, `styles.css`, `config.example.js`, `404.html`, `.nojekyll`.

אחרי שינוי מקומי:

```powershell
git pull
```

---

## 2. GitHub → Settings → Pages

| שדה | ערך |
|-----|-----|
| **Source** | Deploy from a branch |
| **Branch** | `main` |
| **Folder** | **`/docs`** |
| **Save** | שמרו |

המתינו 1–3 דקות. כתובת האתר:

`https://espressomusic.github.io/PEYMI/`

(שם המשתמש ב-GitHub לרוב באותיות קטנות; שם ה-repo הוא `PEYMI`.)

---

## 3. צרו `docs/config.js` (לא נכנס ל-Git)

### אופציה א — בעורך ב-GitHub (מומלץ לפריסה)

1. פתחו: https://github.com/EspressoMusic/PEYMI  
2. תיקייה **`docs`** → **Add file** → **Create new file**  
3. שם הקובץ: `config.js`  
4. העתיקו את התוכן מ-`config.example.js` (בלוק GitHub Pages)  
5. מלאו את הערכים למטה → **Commit**

### אופציה ב — מקומית

```powershell
copy docs\config.example.js docs\config.js
# ערכו docs\config.js
```

העלו רק את `config.js` דרך GitHub UI (הקובץ ב-`.gitignore` — לא דוחפים ב-git).

---

## 4. ערכים ב-`config.js`

### `supabaseUrl`

1. https://supabase.com/dashboard → הפרויקט  
2. **Settings → API → Project URL**  
3. דוגמה: `https://qruzhluqmmzlcxksftuh.supabase.co`

### `supabaseAnonKey`

1. אותו מסך: **Project API keys → `anon` `public`**  
2. מחרוזת שמתחילה ב-`eyJ...`  
3. זה מפתח **ציבורי** (מותר בדפדפן).

### `apkDownloadUrl` (אופציונלי)

קישור ישיר ל-APK, למשל מ-GitHub Releases:

```text
https://github.com/EspressoMusic/PEYMI/releases/download/v0.1.0/app-debug.apk
```

אם ריק — יוצג: **"Download link is not available yet."**

### GitHub Pages (חובה עכשיו)

```js
publicBaseUrl: "https://espressomusic.github.io/PEYMI",
basePath: "/PEYMI",
testingMode: true,
```

### אסור ב-`config.js`

| אסור | למה |
|------|-----|
| `SUPABASE_SERVICE_ROLE_KEY` | מפתח שרת — דליפה |
| `TWILIO_AUTH_TOKEN` | סוד SMS |
| `STRIPE_SECRET_KEY` | סוד תשלומים |

---

## 5. אפליקציית Flutter — קישורים זמניים

בקובץ **`.env`** (מקומי, לא ב-Git):

```env
PUBLIC_STORE_BASE_URL=https://espressomusic.github.io/PEYMI
PEYMI_PAGES_BASE_PATH=/PEYMI
```

בנו מחדש:

```powershell
.\tools\refresh_app.ps1 -Force
```

שיתוף / העתקת קישור באפליקציה יפיקו:  
`https://espressomusic.github.io/PEYMI/{slug}`

### מעבר ל-`bizmi.app` אחר כך

רק שנהו ב-`.env`:

```env
PUBLIC_STORE_BASE_URL=https://bizmi.app
PEYMI_PAGES_BASE_PATH=
```

וב-`docs/config.js`:

```js
publicBaseUrl: "https://bizmi.app",
basePath: "",
```

---

## 6. בדיקה

פתחו בטלפון:

**https://espressomusic.github.io/PEYMI/shiki**

| בדיקה | צפוי |
|--------|------|
| שם חנות | "shilo" (או שם העסק ב-Supabase) |
| באנר | Bizmi is currently in testing. |
| APK מוגדר | כפתור הורדה |
| APK לא מוגדר | Download link is not available yet. |
| אפליקציה מותקנת | נפתחת באפליקציה |

---

## Checklist

| Task | Status | Notes |
|------|--------|-------|
| `docs/` ב-repo על `main` | ☐ | `git pull` |
| Pages: Branch `main`, Folder `/docs` | ☐ | Settings → Pages |
| קובץ `docs/config.js` ב-GitHub | ☐ | לא ב-git מקומי |
| `supabaseUrl` + `supabaseAnonKey` | ☐ | רק anon |
| `publicBaseUrl` + `basePath` ל-GitHub | ☐ | `/PEYMI` |
| `testingMode: true` | ☐ | בלי Play/App Store |
| `apkDownloadUrl` (אם יש APK) | ☐ | אופציונלי |
| `.env` → `PUBLIC_STORE_BASE_URL` | ☐ | באפליקציה |
| בדיקת `/PEYMI/shiki` | ☐ | בדפדפן + בטלפון |

---

## פתרון תקלות

- **404 על `/PEYMI/shiki`** — ודאו `404.html` ב-`docs/` ו-`basePath: "/PEYMI"`.  
- **שם חנות לא נטען** — בדקו `config.js` ו-anon key.  
- **עיצוב שבור** — ודאו שקיים `docs/.nojekyll`.  
- **אפליקציה לא נפתחת** — deep link `bizmi://` דורש התקנת APK; קישור GitHub פותח דפדפן (תקין).
