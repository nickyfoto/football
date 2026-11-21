import { defineConfig } from "cf/config";

// Serves the game pages from football.macworks.dev as an assets-only Worker.
// `npm run deploy` copies the *.html pages into dist/ and runs `cf deploy dist`.
export default defineConfig({
	worker: {
		name: "football",
		compatibilityDate: "2026-11-20",
		domains: ["football.macworks.dev"],
		workersDev: false,
	},
});
