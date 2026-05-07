export enum UserRole {
  CITIZEN = "CITIZEN",
  OFFICER = "OFFICER",
  SUPERVISOR = "SUPERVISOR",
  ADMIN = "ADMIN",
}

export interface UserProfileDTO {
  id: string;
  keycloakId: string;
  username: string;
  email: string;
  fullName: string;
  phoneNumber?: string;
  nationalId?: string;
  dateOfBirth?: string;
  address?: string;
  role: UserRole;
  enabled: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface UpdateProfileRequest {
  fullName: string;
  phoneNumber?: string;
  address?: string;
}

declare module "next-auth" {
  interface Session {
    accessToken?: string;
    user: {
      id?: string;
      name?: string | null;
      email?: string | null;
      image?: string | null;
      role?: UserRole;
    };
  }

  interface JWT {
    accessToken?: string;
    role?: UserRole;
  }
}
