import type { ApiClient } from "@__PROJECT__/api-client";

/** The slice of the API port the find screen calls (TS-8). */
export type FindClient = Pick<ApiClient, "searchItems">;

let current: FindClient | null = null;

/** Called once by main.tsx (live) or main-demo.tsx (fakes) before rendering. */
export const provideFindClient = (client: FindClient): void => {
    current = client;
};

export const findClient = (): FindClient => {
    if (current === null) throw new Error("Find client missing: call provideFindClient() in the entry before rendering");
    return current;
};
