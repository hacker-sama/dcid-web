import { Badge } from "@/components/ui/badge";
import { ApplicationStatus } from "@/types/application";
import { STATUS_CONFIG } from "@/constants/application-status";
import { cn } from "@/lib/utils";

interface StatusBadgeProps {
  status: ApplicationStatus;
  className?: string;
}

export function StatusBadge({ status, className }: StatusBadgeProps) {
  const config = STATUS_CONFIG[status];
  
  if (!config) {
    return <Badge variant="outline" className={className}>{status}</Badge>;
  }

  return (
    <Badge 
      variant="outline" 
      className={cn("font-medium border-0", config.colorClass, className)}
    >
      {config.label}
    </Badge>
  );
}
