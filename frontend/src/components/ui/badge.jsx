import * as React from "react";
import { cva } from "class-variance-authority";
import { cn } from "@/lib/utils";

const badgeVariants = cva(
    "inline-flex items-center rounded-full px-3 py-1 text-xs font-medium transition-colors",
    {
        variants: {
            variant: {
                default:
                    "bg-primary-100 text-primary-700 dark:bg-primary-900/30 dark:text-primary-300",
                secondary:
                    "bg-secondary-100 text-secondary-700 dark:bg-secondary-900/30 dark:text-secondary-300",
                success:
                    "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-300",
                warning:
                    "bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300",
                destructive:
                    "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-300",
                outline:
                    "border border-slate-200 text-slate-700 dark:border-slate-700 dark:text-slate-300",
            },
        },
        defaultVariants: {
            variant: "default",
        },
    }
);

function Badge({ className, variant, ...props }) {
    return (
        <div className={cn(badgeVariants({ variant }), className)} {...props} />
    );
}

function NotificationDot({ count, className }) {
    if (!count || count === 0) return null;

    return (
        <span
            className={cn(
                "absolute -top-1 -right-1 flex h-5 w-5 items-center justify-center rounded-full bg-red-500 text-[10px] font-bold text-white animate-pulse",
                className
            )}
        >
            {count > 9 ? "9+" : count}
        </span>
    );
}

export { Badge, badgeVariants, NotificationDot };
