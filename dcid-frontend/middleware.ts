import { NextResponse } from "next/server";
import { auth } from "@/lib/auth";
import { UserRole } from "@/types/user";

export default auth((req) => {
  const { nextUrl } = req;
  const isLoggedIn = !!req.auth;
  const role = req.auth?.user?.role as UserRole;

  const isAuthRoute = nextUrl.pathname.startsWith("/login");
  const isCitizenRoute = nextUrl.pathname.startsWith("/citizen");
  const isOfficerRoute = nextUrl.pathname.startsWith("/officer");

  if (isAuthRoute) {
    if (isLoggedIn) {
      if (role === UserRole.CITIZEN) {
        return NextResponse.redirect(new URL("/citizen/dashboard", nextUrl));
      }
      return NextResponse.redirect(new URL("/officer/dashboard", nextUrl));
    }
    return null;
  }

  if (!isLoggedIn) {
    if (isCitizenRoute || isOfficerRoute) {
      let callbackUrl = nextUrl.pathname;
      if (nextUrl.search) {
        callbackUrl += nextUrl.search;
      }
      const encodedCallbackUrl = encodeURIComponent(callbackUrl);
      return NextResponse.redirect(new URL(`/login?callbackUrl=${encodedCallbackUrl}`, nextUrl));
    }
    return null;
  }

  if (isCitizenRoute && role !== UserRole.CITIZEN) {
    return NextResponse.redirect(new URL("/officer/dashboard", nextUrl));
  }

  if (isOfficerRoute && ![UserRole.OFFICER, UserRole.SUPERVISOR, UserRole.ADMIN].includes(role)) {
    return NextResponse.redirect(new URL("/citizen/dashboard", nextUrl));
  }

  return null;
});

export const config = {
  matcher: ["/((?!api|_next/static|_next/image|favicon.ico).*)"],
};
