import { redirect } from "next/navigation";
import { ROUTES } from "@/constants/routes";

export default function CitizenIndex() {
  redirect(ROUTES.CITIZEN.DASHBOARD);
}
