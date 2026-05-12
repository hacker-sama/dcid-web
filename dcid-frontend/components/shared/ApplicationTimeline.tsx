import { formatDate, cn } from "@/lib/utils";
import { STATUS_CONFIG } from "@/constants/application-status";
import { EmptyState } from "./EmptyState";
import { ApplicationStatus } from "@/types/application";

export interface TimelineItem {
  id: string;
  fromStatus: ApplicationStatus | null;
  toStatus: ApplicationStatus;
  changedBy: string | null;
  note: string | null;
  changedAt: string;
}

interface StatusHistoryItem {
  id: string;
  status: ApplicationStatus;
  changedByName: string;
  note?: string;
  timestamp: string;
}

interface ApplicationTimelineProps {
  items?: TimelineItem[];
  history?: StatusHistoryItem[];
}

export function ApplicationTimeline({ items, history }: ApplicationTimelineProps) {
  const normalizedItems: TimelineItem[] = items
    ? items
    : history
    ? history.map((entry) => ({
        id: entry.id,
        fromStatus: null,
        toStatus: entry.status,
        changedBy: entry.changedByName,
        note: entry.note ?? null,
        changedAt: entry.timestamp,
      }))
    : [];

  if (!normalizedItems || normalizedItems.length === 0) {
    return <EmptyState message="Chưa có lịch sử xử lý" />;
  }

  const sortedItems = [...normalizedItems].sort(
    (a, b) => new Date(b.changedAt).getTime() - new Date(a.changedAt).getTime()
  );

  return (
    <div className="space-y-6">
      {sortedItems.map((item, index) => {
        const isLast = index === sortedItems.length - 1;
        const config = STATUS_CONFIG[item.toStatus];
        const dotTextClass =
          config?.colorClass.split(" ").find((cls: string) => cls.startsWith("bg-")) ?? "bg-gray-500";

        return (
          <div key={item.id} className="relative pl-8">
            {!isLast && (
              <span className="absolute left-2 top-3 h-[calc(100%-1.25rem)] w-px bg-border"></span>
            )}
            <div className="absolute left-0 top-3">
              <span className={cn("inline-flex h-3 w-3 rounded-full bg-current", dotTextClass)} />
            </div>

            <div className="rounded-2xl border border-border bg-background p-4 shadow-sm">
              <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
                <p className="font-semibold text-foreground">{config?.label ?? item.toStatus}</p>
                <time className="text-sm text-muted-foreground">
                  {formatDate(item.changedAt, "HH:mm, dd/MM/yyyy")}
                </time>
              </div>

              <p className="text-sm text-muted-foreground mt-1">
                bởi <span className="font-medium text-foreground">{item.changedBy ?? "Hệ thống"}</span>
              </p>

              {item.note ? (
                <div className="mt-3 rounded-2xl bg-slate-50 p-3 text-sm text-slate-700 shadow-sm">
                  {item.note}
                </div>
              ) : null}
            </div>
          </div>
        );
      })}
    </div>
  );
}
