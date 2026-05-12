import { ApplicationStatus } from "@/types/application";
import { cn } from "@/lib/utils";

const STATUS_BADGE_CONFIG: Record<ApplicationStatus, { label: string; bgClass: string; textClass: string }> = {
  [ApplicationStatus.DRAFT]: {
    label: "Bản nháp",
    bgClass: "bg-gray-100",
    textClass: "text-gray-600",
  },
  [ApplicationStatus.SUBMITTED]: {
    label: "Đã nộp",
    bgClass: "bg-[#E8EFF9]",
    textClass: "text-[#1B3F8B]",
  },
  [ApplicationStatus.IN_REVIEW]: {
    label: "Đang xử lý",
    bgClass: "bg-[#FEF3C7]",
    textClass: "text-[#92400E]",
  },
  [ApplicationStatus.PENDING_SUPPLEMENT]: {
    label: "Cần bổ sung",
    bgClass: "bg-[#FFF7ED]",
    textClass: "text-[#9A3412]",
  },
  [ApplicationStatus.APPROVED]: {
    label: "Đã duyệt",
    bgClass: "bg-[#F0FDF4]",
    textClass: "text-[#166534]",
  },
  [ApplicationStatus.REJECTED]: {
    label: "Từ chối",
    bgClass: "bg-[#FEF2F2]",
    textClass: "text-[#991B1B]",
  },
  [ApplicationStatus.WITHDRAWN]: {
    label: "Đã rút",
    bgClass: "bg-gray-100",
    textClass: "text-gray-500",
  },
};

interface StatusBadgeProps {
  status: ApplicationStatus;
  className?: string;
}

export function StatusBadge({ status, className }: StatusBadgeProps) {
  const config = STATUS_BADGE_CONFIG[status];

  if (!config) {
    return (
      <span className={cn("inline-flex items-center rounded-full px-2.5 py-1 text-xs font-semibold", className)}>
        {status}
      </span>
    );
  }

  return (
    <span
      className={cn(
        "inline-flex items-center gap-2 rounded-full px-2.5 py-1 text-xs font-semibold",
        config.bgClass,
        config.textClass,
        className
      )}
    >
      <span className={cn("inline-flex h-2.5 w-2.5 rounded-full bg-current", config.textClass)} />
      {config.label}
    </span>
  );
}
