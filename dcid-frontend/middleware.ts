import { NextResponse } from "next/server";
import { auth } from "@/lib/auth";
import { UserRole } from "@/types/user";

export default auth((req) => {
  const { nextUrl } = req;
  const isLoggedIn = !!req.auth;
  const role = req.auth?.user?.role as UserRole;

  // (auth) route group exposes /login in the URL
  const isAuthRoute =
    nextUrl.pathname === "/login" || nextUrl.pathname.startsWith("/login/");
  const isCitizenRoute = nextUrl.pathname.startsWith("/citizen");
  const isOfficerRoute = nextUrl.pathname.startsWith("/officer");

  // Already logged in → redirect away from login page to correct portal
  if (isAuthRoute) {
    if (isLoggedIn) {
      if (role === UserRole.CITIZEN) {
        return NextResponse.redirect(new URL("/citizen/dashboard", nextUrl));
      }
      if ([UserRole.OFFICER, UserRole.SUPERVISOR, UserRole.ADMIN].includes(role)) {
        return NextResponse.redirect(new URL("/officer/dashboard", nextUrl));
      }
    }
    return null;
  }

  // Unauthenticated → redirect to login with callbackUrl
  if (!isLoggedIn) {
    if (isCitizenRoute || isOfficerRoute) {
      let callbackUrl = nextUrl.pathname;
      if (nextUrl.search) {
        callbackUrl += nextUrl.search;
      }
      const encodedCallbackUrl = encodeURIComponent(callbackUrl);
      return NextResponse.redirect(
        new URL(`/login?callbackUrl=${encodedCallbackUrl}`, nextUrl)
      );
    }
    return null;
  }

  // Authenticated — wrong role checks
  // Citizen route: only CITIZEN role allowed
  if (isCitizenRoute && role !== UserRole.CITIZEN) {
    if ([UserRole.OFFICER, UserRole.SUPERVISOR, UserRole.ADMIN].includes(role)) {
      return NextResponse.redirect(new URL("/officer/dashboard", nextUrl));
    }
    // Unknown role
    return NextResponse.redirect(new URL("/403", nextUrl));
  }

  // Officer route: only OFFICER, SUPERVISOR, ADMIN allowed
  if (
    isOfficerRoute &&
    ![UserRole.OFFICER, UserRole.SUPERVISOR, UserRole.ADMIN].includes(role)
  ) {
    if (role === UserRole.CITIZEN) {
      return NextResponse.redirect(new URL("/citizen/dashboard", nextUrl));
    }
    // Unknown role
    return NextResponse.redirect(new URL("/403", nextUrl));
  }

  return null;
});

export const config = {
  matcher: ["/((?!api|_next/static|_next/image|favicon.ico).*)"],
};
