// העתיקו ל-config.js לפני פריסה (או הריצו tools/generate_peymii_config.ps1)
window.PEYMI_CONFIG = {
  appName: "Bizmi",
  publicBaseUrl: "https://bizmi.app",
  basePath: "",

  supabaseUrl: "https://YOUR_PROJECT.supabase.co",
  supabaseAnonKey: "YOUR_SUPABASE_ANON_KEY",

  // מצב בדיקות (ברירת מחדל) — בלי Play / App Store
  testingMode: true,
  apkDownloadUrl: "", // לדוגמה: קישור GitHub Releases ל-APK

  // כשהאפליקציה תפורסם בחנויות: testingMode: false + מלאו את הקישורים
  playStoreUrl: "",
  appStoreUrl: "",
  androidPackage: "com.example.bakery_shop_app",
  deepLinkScheme: "bizmi",
  tryOpenAppFirst: true,
  redirectDelayMs: 1600,
};
