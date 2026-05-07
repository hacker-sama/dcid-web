import { StatusHistoryItem } from "@/types/application";
import { STATUS_CONFIG } from "@/constants/application-status";
import { formatDate, cn } from "@/lib/utils";

interface ApplicationTimelineProps {
  history: StatusHistoryItem[];
}

export function ApplicationTimeline({ history }: ApplicationTimelineProps) {
  if (!history || history.length === 0) return null;

  // Sort history ascending by timestamp
  const sortedHistory = [...history].sort((a, b) => 
    new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime()
  );

  return (
    <div className="space-y-4">
      {sortedHistory.map((item, index) => {
        const isLast = index === sortedHistory.length - 1;
        const config = STATUS_CONFIG[item.status];
        // simple mapping for dot color based on background color class
        const dotColor = config?.colorClass.split(' ')[0].replace('bg-', 'bg-').replace('text-', 'bg-') || 'bg-gray-400';

        return (
          <div key={item.id} className="relative pl-6 pb-4">
            {!isLast && (
              <div className="absolute left-[11px] top-3 bottom-0 w-0.5 bg-border" />
            )}
            <div 
              className={cn(
                "absolute left-0 top-1.5 h-6 w-6 rounded-full border-4 border-background",
                config?.colorClass.split(' ')[0] || "bg-gray-400"
              )} 
            />
            <div>
              <div className="flex items-center justify-between">
                <p className="font-semibold text-foreground">
                  {config?.label || item.status}
                </p>
                <time className="text-sm text-muted-foreground">
                  {formatDate(item.timestamp)}
                </time>
              </div>
              <p className="text-sm text-muted-foreground mt-1">
                Bởi: <span className="font-medium text-foreground">{item.changedByName}</span>
              </p>
              {item.note && (
                <div className="mt-2 p-3 bg-muted rounded-md text-sm border">
                  {item.note}
                </div>
              )}
            </div>
          </div>
        );
      })}
    </div>
  );
}
