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
          "inline-flex items-center justify-center font-medium tracking-wide transition-all duration-200 disabled:opacity-40 disabled:cursor-not-allowed rounded-lg",
          size === "sm" ? "text-[12px] px-3 h-8" : "text-[13px] px-5 h-10",
          variant === "solid" &&
            "bg-[hsl(var(--ink))] text-[hsl(var(--background))] hover:opacity-80 shadow-sm active:scale-[0.97]",
          variant === "outline" &&
            "border border-[hsl(var(--hairline))] bg-transparent text-[hsl(var(--ink))] hover:bg-[hsl(var(--ink))] hover:text-[hsl(var(--background))] active:scale-[0.97]",
          variant === "ghost" &&
            "bg-transparent text-[hsl(var(--ink-muted))] hover:text-[hsl(var(--ink))] hover:bg-[hsl(var(--muted))] rounded-lg",
          className
        )}
        {...props}
      />
    );
  }
);
InkButton.displayName = "InkButton";
