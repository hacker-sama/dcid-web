import { ApplicationStatus } from "@/types/application";

export const STATUS_CONFIG: Record<ApplicationStatus, { label: string; colorClass: string }> = {
  [ApplicationStatus.DRAFT]: {
    label: "Nháp",
    colorClass: "bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-300",
  },
  [ApplicationStatus.SUBMITTED]: {
    label: "Đã nộp",
    colorClass: "bg-[#E8EFF9] text-[#1B3F8B] dark:bg-blue-900/30 dark:text-blue-400",
  },
  [ApplicationStatus.IN_REVIEW]: {
    label: "Đang xử lý",
    colorClass: "bg-[#FEF3C7] text-[#92400E] dark:bg-amber-900/30 dark:text-amber-400",
  },
  [ApplicationStatus.PENDING_SUPPLEMENT]: {
    label: "Yêu cầu bổ sung",
    colorClass: "bg-[#FFF7ED] text-[#9A3412] dark:bg-orange-900/30 dark:text-orange-400",
  },
  [ApplicationStatus.APPROVED]: {
    label: "Đã duyệt",
    colorClass: "bg-[#F0FDF4] text-[#166534] dark:bg-green-900/30 dark:text-green-400",
  },
  [ApplicationStatus.REJECTED]: {
    label: "Từ chối",
    colorClass: "bg-[#FEF2F2] text-[#991B1B] dark:bg-red-900/30 dark:text-red-400",
  },
  [ApplicationStatus.WITHDRAWN]: {
    label: "Đã rút",
    colorClass: "bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-300",
  },
};
