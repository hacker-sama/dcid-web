import React from "react";
import { cn } from "@/lib/utils";
import { Check } from "lucide-react";

interface WizardStep {
  id: string;
  title: string;
}

interface WizardLayoutProps {
  steps: WizardStep[];
  currentStep: number;
  children: React.ReactNode;
  title: string;
}

export function WizardLayout({ steps, currentStep, children, title }: WizardLayoutProps) {
  return (
    <div className="flex flex-col md:flex-row gap-8">
      {/* Sidebar / Stepper */}
      <div className="w-full md:w-64 shrink-0">
        <h2 className="text-xl font-bold mb-6">{title}</h2>
        <div className="relative border-l-2 border-muted ml-3 space-y-8">
          {steps.map((step, index) => {
            const isCompleted = index < currentStep;
            const isCurrent = index === currentStep;

            return (
              <div key={step.id} className="relative pl-6">
                <div 
                  className={cn(
                    "absolute -left-[11px] flex h-5 w-5 items-center justify-center rounded-full border-2 bg-background",
                    isCompleted ? "border-primary bg-primary text-primary-foreground" : 
                    isCurrent ? "border-primary text-primary" : "border-muted-foreground text-muted-foreground"
                  )}
                >
                  {isCompleted ? <Check className="h-3 w-3" /> : <span className="text-[10px] font-bold">{index + 1}</span>}
                </div>
                <div className={cn(
                  "text-sm font-medium",
                  isCurrent ? "text-primary" : isCompleted ? "text-foreground" : "text-muted-foreground"
                )}>
                  {step.title}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Content Area */}
      <div className="flex-1 min-w-0">
        <div className="bg-card border rounded-lg shadow-sm">
          {children}
        </div>
      </div>
    </div>
  );
}
