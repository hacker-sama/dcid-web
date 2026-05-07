import NextAuth from "next-auth";
import KeycloakProvider from "next-auth/providers/keycloak";
import { UserRole } from "@/types/user";

export const { handlers, auth, signIn, signOut } = NextAuth({
  providers: [
    KeycloakProvider({
      clientId: process.env.KEYCLOAK_CLIENT_ID,
      clientSecret: process.env.KEYCLOAK_CLIENT_SECRET,
      issuer: process.env.KEYCLOAK_ISSUER,
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
