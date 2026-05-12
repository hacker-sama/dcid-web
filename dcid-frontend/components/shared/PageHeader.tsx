import Link from "next/link";
import { ChevronRight } from "lucide-react";

export interface BreadcrumbItem {
  label: string;
  href?: string;
}

interface PageHeaderProps {
  title: string;
  breadcrumb?: BreadcrumbItem[];
  breadcrumbs?: BreadcrumbItem[];
  actions?: React.ReactNode;
  children?: React.ReactNode;
}

export function PageHeader({ title, breadcrumb, breadcrumbs, actions, children }: PageHeaderProps) {
  const actionContent = actions ?? children;
  const breadcrumbItems = breadcrumb ?? breadcrumbs;

  return (
    <div className="mb-8 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
      <div>
        {breadcrumbItems && breadcrumbItems.length > 0 && (
          <nav className="mb-2 flex flex-wrap items-center gap-2 text-sm text-muted-foreground">
            {breadcrumbItems.map((item, index) => {
              const isLast = index === breadcrumbItems.length - 1;
              return (
                <span key={item.label + index} className="flex items-center gap-2">
                  {item.href && !isLast ? (
                    <Link href={item.href} className="text-primary hover:text-foreground transition-colors">
                      {item.label}
                    </Link>
                  ) : (
                    <span className={isLast ? "font-semibold text-foreground" : "text-muted-foreground"}>
                      {item.label}
                    </span>
                  )}
                  {!isLast && <ChevronRight className="h-4 w-4 text-muted-foreground" />}
                </span>
              );
            })}
          </nav>
        )}
        <h1 className="text-3xl font-bold tracking-tight text-foreground">{title}</h1>
      </div>
      {actions ? <div className="flex items-center gap-2">{actions}</div> : null}
    </div>
  );
}
