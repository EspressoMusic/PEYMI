# דף נחיתה Peymii (קישור חכם ללקוחות)

קישור לדוגמה: `https://bizmi.app/shiki` או `https://espressomusic.github.io/PEYMI/shiki`

- **Android** → Google Play  
- **iPhone/iPad** → App Store  
- **אפליקציה מותקנת** → נפתחת ישירות בחנות  

## פריסה ב-GitHub Pages

1. העתיקו `config.example.js` → `config.js` ומלאו:
   - `supabaseUrl`, `supabaseAnonKey`
   - `playStoreUrl`, `appStoreUrl` (כשהאפליקציה בחנויות)
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
