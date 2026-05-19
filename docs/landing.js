(function () {
  const cfg = window.PEYMI_CONFIG || window.BIZMI_CONFIG || {};
  const appName = cfg.appName || "Bizmi";
  const basePath = (cfg.basePath || "").replace(/\/+$/, "");
  const baseUrl = (cfg.publicBaseUrl || "https://bizmi.app").replace(/\/+$/, "");
  const testingMode = cfg.testingMode !== false;
  const apkUrl = (cfg.apkDownloadUrl || cfg.testApkUrl || "").trim();

  const playUrl = (cfg.playStoreUrl || "").trim();
  const appStoreUrl = (cfg.appStoreUrl || "").trim();
  const androidPackage = cfg.androidPackage || "com.example.bakery_shop_app";
  const deepLinkScheme = cfg.deepLinkScheme || "bizmi";
  const redirectDelayMs = cfg.redirectDelayMs ?? 1600;
  const tryOpenAppFirst = cfg.tryOpenAppFirst !== false;

  const reserved = new Set([
    "super-admin",
    "settings",
    "orders",
    "deals",
    "catalog",
    "www",
    ".well-known",
    "peymii",
    "docs",
  ]);

  const copy = {
    he: {
      brandTagline: "חנות ותורים באפליקציה",
      loading: "טוען חנות…",
      testingBanner: "Bizmi נמצאת כרגע בבדיקות.",
      testingLead: "כדי לצפות בחנות זו, הורידו את גרסת הבדיקה לאנדרואיד.",
      apkButton: "הורדת APK לבדיקה (Android)",
      apkUnavailable: "קישור ההורדה עדיין לא זמין.",
      openingApp: "מנסים לפתוח באפליקציה…",
      openInApp: "פתיחה באפליקציה",
      configError: "חסר config.js — העתיקו מ-config.example.js",
      loadError: "לא ניתן לטעון את החנות.",
      notFound: "החנות לא נמצאה",
      notFoundHint: "ייתכן שהקישור שגוי או שהחנות עדיין לא פעילה.",
      storeLabel: "חנות ב-Bizmi",
      downloadLead: "הורידו את האפליקציה כדי לצפות בחנות.",
      deviceAndroid: "זיהינו Android",
      deviceIos: "זיהינו iPhone / iPad",
      deviceDesktop: "בחרו חנות להורדה:",
      downloadAndroid: "Google Play",
      downloadIos: "App Store",
      redirecting: "מעבירים לחנות…",
    },
    en: {
      brandTagline: "Store & appointments in the app",
      loading: "Loading store…",
      testingBanner: "Bizmi is currently in testing.",
      testingLead: "To view this store, download the Android test version.",
      apkButton: "Download Android Test APK",
      apkUnavailable: "Download link is not available yet.",
      openingApp: "Trying to open the app…",
      openInApp: "Open in app",
      configError: "Missing config.js — copy from config.example.js",
      loadError: "Could not load this store.",
      notFound: "Store not found",
      notFoundHint: "This link may be wrong or the store is not public yet.",
      storeLabel: "Store on Bizmi",
      downloadLead: "Download the app to view this store.",
      deviceAndroid: "Android detected",
      deviceIos: "iPhone / iPad detected",
      deviceDesktop: "Choose a store:",
      downloadAndroid: "Google Play",
      downloadIos: "App Store",
      redirecting: "Redirecting to download…",
    },
  };

  function lang() {
    const l = (navigator.language || "en").toLowerCase();
    return l.startsWith("he") ? "he" : "en";
  }

  function t(key) {
    return copy[lang()][key];
  }

  function restoreGithubPagesPath() {
    const saved = sessionStorage.getItem("peymii_path");
    if (!saved) return;
    sessionStorage.removeItem("peymii_path");
    if (location.pathname !== saved) {
      history.replaceState(null, "", saved + location.search);
    }
  }

  function slugFromPath() {
    restoreGithubPagesPath();
    let path = location.pathname;
    if (basePath && path.startsWith(basePath)) {
      path = path.slice(basePath.length) || "/";
    }
    const parts = path.replace(/^\/+|\/+$/g, "").split("/");
    const slug = (parts[0] || "").toLowerCase().replace(/[^a-z0-9-]/g, "");
    if (!slug || reserved.has(slug)) return null;
    return slug;
  }

  function detectPlatform() {
    const ua = navigator.userAgent || navigator.vendor || "";
    if (/android/i.test(ua)) return "android";
    const isIos =
      /iPad|iPhone|iPod/i.test(ua) ||
      (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1);
    if (isIos && !window.MSStream) return "ios";
    return "other";
  }

  function setError(msg) {
    const el = document.getElementById("error");
    el.hidden = false;
    el.textContent = msg;
    hideLoader();
  }

  function hideLoader() {
    const loader = document.getElementById("loader");
    if (loader) loader.classList.add("done");
  }

  function tryOpenAppOnly(slug, platform) {
    if (!tryOpenAppFirst || !slug) return;

    const status = document.getElementById("open-app-status");
    if (status) {
      status.hidden = false;
      status.textContent = t("openingApp");
    }

    let left = false;
    const onVis = () => {
      if (document.hidden) left = true;
    };
    document.addEventListener("visibilitychange", onVis);

    if (platform === "android") {
      window.location.href =
        "intent://" +
        slug +
        "#Intent;scheme=" +
        deepLinkScheme +
        ";package=" +
        androidPackage +
        ";end";
    } else if (platform === "ios") {
      window.location.href = deepLinkScheme + "://" + slug;
    } else {
      window.location.href = baseUrl + "/" + slug;
    }

    setTimeout(() => {
      document.removeEventListener("visibilitychange", onVis);
      if (status && !left) status.hidden = true;
    }, 1500);
  }

  function setupTestingUi(slug, platform) {
    document.getElementById("actions-testing").hidden = false;
    document.getElementById("actions-store").hidden = true;

    const banner = document.getElementById("testing-banner");
    banner.hidden = false;
    banner.textContent = t("testingBanner");

    const msg = document.getElementById("store-message");
    if (slug) {
      msg.textContent = t("testingLead");
    } else {
      document.getElementById("store-name").textContent = appName;
      msg.textContent = t("testingLead");
      hideLoader();
    }

    const apkBtn = document.getElementById("apk-download");
    const apkMissing = document.getElementById("apk-unavailable");

    if (apkUrl && apkUrl !== "#") {
      apkBtn.href = apkUrl;
      apkBtn.textContent = t("apkButton");
      apkBtn.hidden = false;
      apkBtn.target = "_blank";
      apkBtn.rel = "noopener";
      apkBtn.removeAttribute("aria-disabled");
      apkMissing.hidden = true;
    } else {
      apkBtn.hidden = true;
      apkMissing.hidden = false;
      apkMissing.textContent = t("apkUnavailable");
    }

    const openApp = document.getElementById("open-app");
    openApp.textContent = t("openInApp");
    openApp.href = slug ? baseUrl + "/" + slug : baseUrl;

    if (slug && (platform === "android" || platform === "ios")) {
      tryOpenAppOnly(slug, platform);
    }
  }

  function storeUrlFor(platform) {
    if (platform === "android" && playUrl) return playUrl;
    if (platform === "ios" && appStoreUrl && appStoreUrl !== "#") return appStoreUrl;
    return null;
  }

  function tryOpenAppThenStore(slug, platform) {
    const store = storeUrlFor(platform);
    if (!store) {
      tryOpenAppOnly(slug, platform);
      return;
    }

    let left = false;
    const onVis = () => {
      if (document.hidden) left = true;
    };
    document.addEventListener("visibilitychange", onVis);

    if (platform === "android") {
      const fallback = encodeURIComponent(store);
      window.location.href =
        "intent://" +
        slug +
        "#Intent;scheme=" +
        deepLinkScheme +
        ";package=" +
        androidPackage +
        ";S.browser_fallback_url=" +
        fallback +
        ";end";
    } else if (platform === "ios") {
      window.location.href = deepLinkScheme + "://" + slug;
      setTimeout(() => {
        if (!left && !document.hidden) window.location.replace(store);
      }, 900);
    }

    setTimeout(() => {
      document.removeEventListener("visibilitychange", onVis);
      if (!left && !document.hidden && store) {
        window.location.replace(store);
      }
    }, redirectDelayMs);
  }

  function setupStoreUi(platform, slug) {
    document.getElementById("actions-testing").hidden = true;
    document.getElementById("actions-store").hidden = false;

    const hint = document.getElementById("device-hint");
    const primary = document.getElementById("download-primary");
    const secondary = document.getElementById("download-secondary");
    const openApp = document.getElementById("open-app-store");
    const status = document.getElementById("redirect-status");
    const redirectText = document.getElementById("redirect-text");

    openApp.textContent = t("openInApp");
    openApp.href = slug ? baseUrl + "/" + slug : baseUrl;

    if (platform === "android" && playUrl) {
      hint.textContent = t("deviceAndroid");
      primary.href = playUrl;
      primary.textContent = t("downloadAndroid");
      primary.hidden = false;
      secondary.hidden = true;
      status.hidden = false;
      redirectText.textContent = t("redirecting");
    } else if (platform === "ios" && appStoreUrl) {
      hint.textContent = t("deviceIos");
      primary.href = appStoreUrl;
      primary.textContent = t("downloadIos");
      primary.hidden = false;
      secondary.hidden = true;
      status.hidden = false;
      redirectText.textContent = t("redirecting");
    } else {
      hint.textContent = t("deviceDesktop");
      primary.hidden = !playUrl;
      if (playUrl) {
        primary.href = playUrl;
        primary.textContent = t("downloadAndroid");
      }
      secondary.hidden = !appStoreUrl;
      if (appStoreUrl) {
        secondary.href = appStoreUrl;
        secondary.textContent = t("downloadIos");
      }
      status.hidden = true;
    }

    if (slug && (platform === "android" || platform === "ios")) {
      tryOpenAppThenStore(slug, platform);
    }
  }

  async function loadStore(slug) {
    const url = cfg.supabaseUrl;
    const key = cfg.supabaseAnonKey;
    if (!url || !key || key === "your_anon_key") {
      document.getElementById("store-name").textContent = t("storeLabel");
      setError(t("configError"));
      return;
    }

    const api =
      url.replace(/\/+$/, "") +
      "/rest/v1/businesses?select=business_name,description,slug&slug=eq." +
      encodeURIComponent(slug);

    try {
      const res = await fetch(api, {
        headers: { apikey: key, Authorization: "Bearer " + key },
      });
      if (!res.ok) {
        setError(t("loadError"));
        return;
      }
      const rows = await res.json();
      const store = rows[0];
      if (!store) {
        document.getElementById("store-name").textContent = t("notFound");
        setError(t("notFoundHint"));
        return;
      }
      document.getElementById("store-name").textContent = store.business_name;
      document.getElementById("store-slug").hidden = false;
      document.getElementById("store-slug").textContent = baseUrl + "/" + slug;
      if (!testingMode) {
        document.getElementById("store-message").textContent = store.description
          ? store.description + " — " + t("downloadLead")
          : t("downloadLead");
      }
      document.title = store.business_name + " — " + appName;
      hideLoader();
    } catch (_) {
      setError(t("loadError"));
    }
  }

  const slug = slugFromPath();
  const platform = detectPlatform();

  document.documentElement.lang = lang() === "he" ? "he" : "en";
  document.documentElement.dir = lang() === "he" ? "rtl" : "ltr";

  const badge = document.getElementById("brand-badge");
  if (badge) badge.textContent = appName;
  const tagline = document.getElementById("brand-tagline");
  if (tagline) tagline.textContent = t("brandTagline");
  const foot = document.getElementById("footnote-domain");
  if (foot) {
    try {
      foot.textContent = new URL(baseUrl).host;
    } catch (_) {
      foot.textContent = baseUrl;
    }
  }

  if (testingMode) {
    setupTestingUi(slug, platform);
    if (slug) loadStore(slug);
    else hideLoader();
  } else {
    setupStoreUi(platform, slug);
    if (slug) loadStore(slug);
    else {
      document.getElementById("store-name").textContent = appName;
      document.getElementById("store-message").textContent = t("downloadLead");
      hideLoader();
    }
  }
})();
