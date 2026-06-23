import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

/**
 * Source of Truth extension for Pi.
 *
 * Registers the source-of-truth skills directory so Pi discovers the skill.
 * The skill activates automatically from its description when a task touches a
 * docs/ spec catalog, so no session bootstrap injection is needed.
 */

const extensionDir = dirname(fileURLToPath(import.meta.url));
const packageRoot = resolve(extensionDir, "../..");
const skillsDir = resolve(packageRoot, "skills");

export default function sourceOfTruthPiExtension(pi: ExtensionAPI) {
	pi.on("resources_discover", async () => ({
		skillPaths: [skillsDir],
	}));
}
