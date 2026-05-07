import { redirect } from "next/navigation";
import { auth } from "@/lib/auth";
import { UserRole } from "@/types/user";
import { ROUTES } from "@/constants/routes";

export default async function HomePage() {
  const session = await auth();

  if (!session) {
    redirect(ROUTES.LOGIN);
  }

  if (session.user?.role === UserRole.CITIZEN) {
    redirect(ROUTES.CITIZEN.DASHBOARD);
  } else {
    redirect(ROUTES.OFFICER.DASHBOARD);
  }
}
