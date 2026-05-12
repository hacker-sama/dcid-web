import React from "react";
import { Inbox, type LucideIcon } from "lucide-react";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

interface EmptyStateAction {
  label: string;
  onClick: () => void;
}

interface EmptyStateProps {
  message?: string;
  title?: string;
  description?: string;
  action?: EmptyStateAction | React.ReactNode;
  icon?: LucideIcon;
  className?: string;
}

export function EmptyState({
  message,
  title,
  description,
  action,
  icon: Icon = Inbox,
  className,
}: EmptyStateProps) {
  const displayMessage = message ?? title ?? "";

  return (
    <div className={cn("flex min-h-[196px] flex-col items-center justify-center gap-4 rounded-3xl border border-dashed border-border bg-background p-8 text-center", className)}>
      <div className="flex h-16 w-16 items-center justify-center rounded-full bg-primary/10 text-primary">
        <Icon className="h-8 w-8" />
      </div>
      <div>
        <p className="text-lg font-semibold text-foreground">{displayMessage}</p>
        {description ? (
          <p className="mt-2 text-sm text-muted-foreground">{description}</p>
        ) : null}
      </div>
      {action ? (
        !React.isValidElement(action) &&
        action !== null &&
        typeof action === "object" &&
        "label" in action &&
        "onClick" in action ? (
          <Button size="sm" onClick={(action as EmptyStateAction).onClick} type="button">
            {(action as EmptyStateAction).label}
          </Button>
        ) : (
          action
        )
      ) : null}
    </div>
  );
}
