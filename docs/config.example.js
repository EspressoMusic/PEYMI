// העתיקו ל-config.js לפני פריסה (או הריצו tools/generate_peymii_config.ps1)
//
// GitHub Pages (זמני): https://espressomusic.github.io/PEYMI/shiki
// דומיין עתידי:      https://bizmi.app/shiki  → רק שנהו publicBaseUrl + basePath: ""

window.PEYMI_CONFIG = {
  appName: "Bizmi",

  // --- GitHub Pages (בחרו את הבלוק הזה עכשיו) ---
  publicBaseUrl: "https://espressomusic.github.io/PEYMI",
  basePath: "/PEYMI",

  // --- דומיין אמיתי (אחרי חיבור bizmi.app) ---
  // publicBaseUrl: "https://bizmi.app",
  // basePath: "",

  // Supabase — רק anon (מפתח ציבורי). לעולם לא service_role כאן.
  supabaseUrl: "https://YOUR_PROJECT.supabase.co",
  supabaseAnonKey: "YOUR_SUPABASE_ANON_KEY",

  testingMode: true,
  apkDownloadUrl: "",

  playStoreUrl: "",
  appStoreUrl: "",
  androidPackage: "com.example.bakery_shop_app",
  deepLinkScheme: "bizmi",
  tryOpenAppFirst: true,
  redirectDelayMs: 1600,
};
