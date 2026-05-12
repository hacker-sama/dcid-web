import NextAuth from "next-auth";
import KeycloakProvider from "next-auth/providers/keycloak";
import { UserRole } from "@/types/user";

const keycloakClientId = process.env.KEYCLOAK_CLIENT_ID;
const keycloakIssuer = process.env.KEYCLOAK_ISSUER;
const keycloakClientSecret =
  process.env.KEYCLOAK_CLIENT_SECRET &&
  process.env.KEYCLOAK_CLIENT_SECRET !== "change-me"
    ? process.env.KEYCLOAK_CLIENT_SECRET
    : undefined;

export const { handlers, auth, signIn, signOut } = NextAuth({
  providers: [
    KeycloakProvider({
      clientId: keycloakClientId,
      clientSecret: keycloakClientSecret,
      issuer: keycloakIssuer,
      authorization: { params: { scope: "openid profile email" } },
    }),
  ],
  callbacks: {
    async jwt({ token, account }) {
      if (account) {
        token.accessToken = account.access_token;
        // Parse role from Keycloak token
        if (account.access_token) {
          try {
            const payload = JSON.parse(Buffer.from(account.access_token.split(".")[1], "base64").toString());
            const roles = payload.realm_access?.roles || [];
            
            // Map roles
            if (roles.includes("ADMIN")) token.role = UserRole.ADMIN;
            else if (roles.includes("SUPERVISOR")) token.role = UserRole.SUPERVISOR;
            else if (roles.includes("OFFICER")) token.role = UserRole.OFFICER;
            else token.role = UserRole.CITIZEN;
            
          } catch (error) {
            console.error("Failed to parse role from token", error);
            token.role = UserRole.CITIZEN;
          }
        }
      }
      return token;
    },
    async session({ session, token }) {
      session.accessToken = token.accessToken as string;
      if (session.user) {
        session.user.role = token.role as UserRole;
      }
      return session;
    },
  },
  session: { strategy: "jwt" },
});
