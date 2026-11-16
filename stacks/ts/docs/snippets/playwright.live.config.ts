import { defineConfig, devices } from "@playwright/test";

// The live pass drives the running app (__P__30) against the API (__P__20); one run at a time (TEST-8).
const BASE_URL = "http://127.0.0.1:__P__30";

// biome-ignore lint/style/noDefaultExport: Playwright loads its config from the default export
export default defineConfig({
    testDir: "tests-live",
    outputDir: "test-results/live",
    fullyParallel: false,
    workers: 1,
    reporter: "list",
    timeout: 120_000,
    expect: { timeout: 30_000 },
    use: { baseURL: BASE_URL, ...devices["Desktop Chrome"] },
});
