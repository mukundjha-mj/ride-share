import * as React from "react";
import { cn } from "@/lib/utils";

const Input = React.forwardRef(({ className, type, label, error, ...props }, ref) => {
    return (
        <div className="space-y-2">
            {label && (
                <label className="text-sm font-medium text-slate-700 dark:text-slate-300">
                    {label}
                </label>
            )}
            <input
                type={type}
                className={cn(
                    "flex h-11 w-full rounded-xl border border-slate-200 bg-white/50 backdrop-blur-sm px-4 py-2 text-sm transition-all duration-200",
                    "placeholder:text-slate-400",
                    "focus:outline-none focus:ring-2 focus:ring-primary-500/50 focus:border-primary-500",
                    "disabled:cursor-not-allowed disabled:opacity-50",
                    "dark:border-slate-700 dark:bg-slate-800/50 dark:text-slate-50 dark:placeholder:text-slate-500",
                    error && "border-red-500 focus:ring-red-500/50 focus:border-red-500",
                    className
                )}
                ref={ref}
                {...props}
            />
            {error && (
                <p className="text-xs text-red-500 mt-1">{error}</p>
            )}
        </div>
    );
});
Input.displayName = "Input";

export { Input };
