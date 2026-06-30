/**
 * Admin customization for FluentDeck.
 *
 * Post-login deep-link redirect fix
 * --------------------------------
 * Strapi 4.19's login flow does not reliably honor `?redirectTo=` when the
 * target path contains `::` (which is the case for Content Manager URLs such
 * as `/content-manager/collection-types/api::category.category/9`).  After
 * login the user ends up on the admin dashboard instead of the requested
 * page.  The Flutter app uses these deep links for admins, so we need the
 * redirect to work.
 *
 * We fix it entirely on the client:
 *   1. While the admin sits on `/admin/auth/login`, we snapshot the
 *      `redirectTo` query parameter into `sessionStorage`.
 *   2. On every SPA navigation, we check whether the user has a JWT token
 *      (i.e. they just finished logging in) and has landed on the admin
 *      root / "use case" page while a redirect is pending.  If so, we
 *      consume the pending target and navigate there.
 *
 * The extension is a no-op outside the admin (e.g. during SSR / build) and
 * outside the login flow.
 */

const REDIRECT_KEY = "mathe:pendingAdminRedirect";

const safe = (fn) => {
  try {
    return fn();
  } catch (_) {
    return undefined;
  }
};

const installDeepLinkRedirect = () => {
  if (typeof window === "undefined") return;

  const captureRedirectFromLoginUrl = () => {
    const url = new URL(window.location.href);
    if (url.pathname !== "/admin/auth/login") return;
    const redirectTo = url.searchParams.get("redirectTo");
    if (!redirectTo) return;
    safe(() => sessionStorage.setItem(REDIRECT_KEY, redirectTo));
  };

  const isAuthenticated = () => {
    const raw =
      safe(() => localStorage.getItem("jwtToken")) ||
      safe(() => sessionStorage.getItem("jwtToken"));
    if (!raw) return false;
    const trimmed = String(raw).trim();
    return trimmed.length > 2 && trimmed !== '"null"' && trimmed !== "null";
  };

  /// True only when react-router has stopped on a generic admin landing page
  /// (the dashboard or the post-onboarding "use case" page).  We never want
  /// to steal a navigation that is already on the correct deep-link target.
  const isOnAdminLanding = (pathname) =>
    pathname === "/admin" ||
    pathname === "/admin/" ||
    pathname === "/admin/usecase";

  const consumePendingRedirect = () => {
    const pending = safe(() => sessionStorage.getItem(REDIRECT_KEY));
    if (!pending) return;

    const url = new URL(window.location.href);

    if (url.pathname.startsWith("/admin/auth/")) return;

    if (!isAuthenticated()) return;

    if (!isOnAdminLanding(url.pathname)) return;

    const decoded = decodeURIComponent(pending);
    const target = decoded.startsWith("/admin") ? decoded : "/admin" + decoded;

    if (url.pathname + url.search === target) {
      safe(() => sessionStorage.removeItem(REDIRECT_KEY));
      return;
    }

    safe(() => sessionStorage.removeItem(REDIRECT_KEY));
    window.location.replace(target);
  };

  const tick = () => {
    captureRedirectFromLoginUrl();
    consumePendingRedirect();
  };

  const origPush = window.history.pushState;
  const origReplace = window.history.replaceState;
  window.history.pushState = function patchedPushState() {
    const result = origPush.apply(this, arguments);
    Promise.resolve().then(tick);
    return result;
  };
  window.history.replaceState = function patchedReplaceState() {
    const result = origReplace.apply(this, arguments);
    Promise.resolve().then(tick);
    return result;
  };
  window.addEventListener("popstate", () => Promise.resolve().then(tick));

  tick();
  setTimeout(tick, 300);
  setTimeout(tick, 1500);
};

const config = {
  locales: [],
};

const bootstrap = () => {
  installDeepLinkRedirect();
};

export default {
  config,
  bootstrap,
};
