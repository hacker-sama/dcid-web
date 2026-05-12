import { StatusBadge } from "./StatusBadge";
import { ApplicationStatus } from "@/types/application";

export default {
  title: "Shared/StatusBadge",
};

export const Draft = () => <StatusBadge status={ApplicationStatus.DRAFT} />;
export const Submitted = () => <StatusBadge status={ApplicationStatus.SUBMITTED} />;
export const Approved = () => <StatusBadge status={ApplicationStatus.APPROVED} />;
