import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";

const configPath = process.argv[2];
if (!configPath) {
  throw new Error("Usage: create-config.mjs <configuration-path>");
}

const allowed = (process.env.TEXLITE_DOCKER_ENGINES ?? "")
  .split(",")
  .map((engine) => engine.trim())
  .filter((engine) => ["pdflatex", "xelatex", "lualatex"].includes(engine));

if (allowed.length === 0) {
  throw new Error("No supported LaTeX engines were supplied by the container entrypoint.");
}

const defaultEngine = allowed.includes("xelatex")
  ? "xelatex"
  : allowed.includes("pdflatex")
    ? "pdflatex"
    : "lualatex";

const config = {
  siteName: (process.env.TEXLITE_INIT_SITE_NAME ?? "TexLite").trim() || "TexLite",
  adminEmail: (process.env.TEXLITE_INIT_ADMIN_EMAIL ?? "").trim(),
  server: { host: "0.0.0.0", port: 3040 },
  storage: { dataDir: "/data" },
  latex: { defaultEngine, allowedEngines: allowed }
};

await mkdir(path.dirname(configPath), { recursive: true, mode: 0o700 });
await writeFile(configPath, `${JSON.stringify(config, null, 2)}\n`, { encoding: "utf8", mode: 0o600, flag: "wx" });
