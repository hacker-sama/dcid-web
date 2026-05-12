import { ApplicationTimeline, TimelineItem } from "./ApplicationTimeline";
import { ApplicationStatus } from "@/types/application";

export default {
  title: "Shared/ApplicationTimeline",
};

const items: TimelineItem[] = [
  {
    id: "3",
    fromStatus: ApplicationStatus.SUBMITTED,
    toStatus: ApplicationStatus.IN_REVIEW,
    changedBy: "Nguyễn Văn A",
    note: "Hồ sơ đang được kiểm tra.",
    changedAt: "2026-05-09T11:35:00.000Z",
  },
  {
    id: "2",
    fromStatus: null,
    toStatus: ApplicationStatus.SUBMITTED,
    changedBy: null,
    note: null,
    changedAt: "2026-05-09T10:10:00.000Z",
  },
];

export const Default = () => <ApplicationTimeline items={items} />;
