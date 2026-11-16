import { defineConfig, devices } from "@playwright/test";

// Fake-adapter E2E on this agent's own port: fleet spawn sets FLEET_PORT (__P__91–__P__99), so parallel workers
// never collide (TEST-6).
const PORT = Number(process.env.FLEET_PORT ?? "__P__91");
const BASE_URL = `http://127.0.0.1:${PORT}`;

// biome-ignore lint/style/noDefaultExport: Playwright loads its config from the default export
export default defineConfig({
    testDir: "tests",
    outputDir: "test-results",
    fullyParallel: true,
    reporter: "list",
    use: { baseURL: BASE_URL, ...devices["Desktop Chrome"], timezoneId: "UTC" },
    webServer: {
        command: `pnpm exec vite --port ${PORT} --strictPort`,
        url: BASE_URL,
        reuseExistingServer: false,
        env: { VITE_ADAPTER: "demo" },
    },
});
