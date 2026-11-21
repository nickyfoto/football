// Builds dist/ for the Cloudflare deploy (football.macworks.dev).
// Copies every *.html page and adds the Cloudflare Web Analytics beacon to
// each game page. index.html only redirects, so it is left without one.
// The source files are not changed, so the GitHub Pages copy is not tracked.
import { mkdirSync, readdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";

// Site token from Cloudflare dashboard > Web Analytics > football.macworks.dev.
// It is public: it ends up in every page's source.
const BEACON_TOKEN = "484bf3fc8c4249c4a1b60a03e1dc7921";

const beacon = `<!-- Cloudflare Web Analytics --><script type="module" src="https://static.cloudflareinsights.com/beacon.min.js" data-cf-beacon='{"token": "${BEACON_TOKEN}"}'></script><!-- End Cloudflare Web Analytics -->`;

rmSync("dist", { recursive: true, force: true });
mkdirSync("dist");

for (const file of readdirSync(".").filter((name) => name.endsWith(".html"))) {
	let html = readFileSync(file, "utf8");
	if (BEACON_TOKEN && file !== "index.html") {
		const at = html.lastIndexOf("</body>");
		if (at === -1) throw new Error(`${file} has no </body> tag`);
		html = `${html.slice(0, at)}${beacon}\n${html.slice(at)}`;
	}
	writeFileSync(`dist/${file}`, html);
}
