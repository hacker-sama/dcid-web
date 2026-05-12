import assert from "assert";
import { renderToStaticMarkup } from "react-dom/server";
import { ApplicationTimeline, TimelineItem } from "./ApplicationTimeline";
import { ApplicationStatus } from "@/types/application";

const items: TimelineItem[] = [
  {
    id: "1",
    fromStatus: null,
    toStatus: ApplicationStatus.SUBMITTED,
    changedBy: "Hệ thống",
    note: "",
    changedAt: "2026-05-09T09:00:00.000Z",
  },
];

const markup = renderToStaticMarkup(<ApplicationTimeline items={items} />);
assert.ok(markup.includes("Đã nộp"), "ApplicationTimeline should render new status label");
assert.ok(markup.includes("Hệ thống"), "ApplicationTimeline should render system actor text");
