import { ButtonHTMLAttributes, forwardRef } from "react";
import { cn } from "@/lib/utils";

interface InkButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: "solid" | "ghost" | "outline";
  size?: "sm" | "md";
}

export const InkButton = forwardRef<HTMLButtonElement, InkButtonProps>(
  ({ className, variant = "outline", size = "md", ...props }, ref) => {
    return (
      <button
        ref={ref}
        className={cn(
          "inline-flex items-center justify-center font-medium tracking-wide transition-all duration-200 disabled:opacity-40 disabled:cursor-not-allowed rounded-xl",
          size === "sm" ? "text-[12px] px-3.5 h-8" : "text-[13px] px-5 h-10",
          variant === "solid" &&
            "btn-gradient text-white active:scale-[0.97]",
          variant === "outline" &&
            "border border-[hsl(var(--primary)/0.3)] bg-transparent text-[hsl(var(--primary))] hover:bg-[hsl(var(--primary))] hover:text-white hover:shadow-md active:scale-[0.97] transition-all",
          variant === "ghost" &&
            "bg-transparent text-[hsl(var(--ink-muted))] hover:text-[hsl(var(--primary))] hover:bg-[hsl(var(--primary)/0.08)] rounded-xl",
          className
        )}
        {...props}
      />
    );
  }
);
InkButton.displayName = "InkButton";
