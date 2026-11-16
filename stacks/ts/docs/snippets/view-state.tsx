import type { UseQueryResult } from "@tanstack/react-query";
import type { ReactNode } from "react";

interface ViewStateProps {
    readonly title: string;
    readonly queries: readonly UseQueryResult<unknown>[];
    readonly children: ReactNode;
}

/** Loading, error-with-retry, or the content: no view renders blank on a failed read (UI-1). */
export function ViewState({ title, queries, children }: ViewStateProps) {
    const failed = queries.filter((query) => query.isError);
    if (failed.length > 0) {
        return (
            <div role="alert" aria-label={`${title} failed to load`}>
                <p>{failed[0]?.error?.message ?? "Something failed to load."}</p>
                <button type="button" onClick={() => failed.forEach((query) => void query.refetch())}>
                    Retry
                </button>
            </div>
        );
    }
    if (queries.some((query) => query.isPending)) return <p aria-busy="true">Loading {title}…</p>;
    return <>{children}</>;
}
