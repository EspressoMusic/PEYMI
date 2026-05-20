# העלאת APK לבדיקה (GitHub Releases)

## 1. בניית APK

```powershell
cd c:\Users\Nirhdhd\bakery_shop_app
.\tools\build_test_apk.ps1
```

**נתיב הקובץ:**

```
c:\Users\Nirhdhd\bakery_shop_app\build\app\outputs\flutter-apk\app-debug.apk
```

(או `bizmi-test.apk` אחרי שהסקריפט מעתיק אותו ל-`release/`.)

---

## 2. העלאה ל-GitHub Releases

1. פתחו: https://github.com/EspressoMusic/PEYMI/releases  
2. **Draft a new release** (או **Create a new release**)  
3. **Choose a tag:** `v0.1.0-test` → **Create new tag**  
4. **Release title:** `Bizmi Android test v0.1.0`  
5. **Description:** `Internal test APK — not for Play Store`  
6. גררו את הקובץ: `app-debug.apk` (או `bizmi-test.apk`)  
   - מומלץ לשנות שם לקובץ: **`bizmi-test.apk`** (בלי רווחים)  
7. **Publish release**

---

## 3. קישור ההורדה

אחרי Publish, לחצו ימני על הקובץ → **Copy link address**.

פורמט לדוגמה:

```
https://github.com/EspressoMusic/PEYMI/releases/download/v0.1.0-test/bizmi-test.apk
```

---

## 4. עדכון `docs/config.js` (ב-GitHub)

1. https://github.com/EspressoMusic/PEYMI → **docs** → **config.js** → **Edit**  
2. עדכנו:

```js
apkDownloadUrl: "https://github.com/EspressoMusic/PEYMI/releases/download/v0.1.0-test/bizmi-test.apk",
```

3. **Commit changes**  
4. המתינו 1–2 דקות → בדקו: https://espressomusic.github.io/PEYMI/shiki  

צפוי: כפתור **Download Android Test APK** (נפרד מ-**Open in app**).

---

## 5. בדיקה בטלפון

1. הורידו APK מהדף  
2. אפשרו "מקורות לא ידועים" להתקנה  
3. התקינו → פתחו שוב את הקישור → **Open in app**
