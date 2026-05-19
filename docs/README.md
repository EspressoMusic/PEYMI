# דף נחיתה Peymii (קישור חכם ללקוחות)

קישור לדוגמה: `https://bizmi.app/shiki` או `https://espressomusic.github.io/PEYMI/shiki`

- **מצב בדיקות (ברירת מחדל):** מנסה לפתוח באפליקציה; אם לא מותקנת — דף עם כפתור **APK לבדיקה** (בלי Play/App Store).
- **אפליקציה מותקנת** → נפתחת ישירות בחנות.
- **לאחר פרסום בחנויות:** הגדירו `testingMode: false` ב-`config.js` + `PLAY_STORE_URL` / `APP_STORE_URL`.

## פריסה ב-GitHub Pages

1. העתיקו `config.example.js` → `config.js` ומלאו:
   - `supabaseUrl`, `supabaseAnonKey`
   - `apkDownloadUrl` (קישור APK לבדיקה) או `APK_TEST_URL` ב-`.env`
   - `playStoreUrl`, `appStoreUrl` (רק אחרי פרסום + `testingMode: false`)
2. ב-GitHub: **Settings → Pages → Build from branch `main` → Folder `/docs`**
3. אם הכתובת היא `github.io/PEYMI/` (לא דומיין משלך), הגדירו ב-`config.js`:
   ```js
   basePath: "/PEYMI",
   publicBaseUrl: "https://espressomusic.github.io/PEYMI",
   ```
4. דומיין מותאם (`bizmi.app`): השאירו `basePath: ""` וחברו DNS ל-GitHub Pages.

## יצירת config אוטומטית

```powershell
.\tools\generate_peymii_config.ps1
```
