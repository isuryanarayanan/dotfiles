/**
 * save-pasted-image
 *
 * Grab an image from the system clipboard, prompt for a filename, save it
 * into the terminal's current directory, and insert an `@<path>` reference
 * into the editor so the agent picks it up via the normal file pipeline.
 *
 * Trigger via:
 *   /img            -> prompt for filename
 *   /img foo.png    -> save as foo.png (no prompt)
 *
 * macOS only for now (uses osascript to read the clipboard).
 */

import { promises as fs } from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

function timestamp(): string {
	const d = new Date();
	const p = (n: number, w = 2) => String(n).padStart(w, "0");
	return (
		`${d.getFullYear()}${p(d.getMonth() + 1)}${p(d.getDate())}` +
		`-${p(d.getHours())}${p(d.getMinutes())}${p(d.getSeconds())}`
	);
}

async function uniquePath(target: string): Promise<string> {
	try {
		await fs.access(target);
	} catch {
		return target;
	}
	const dir = path.dirname(target);
	const ext = path.extname(target);
	const base = path.basename(target, ext);
	for (let i = 1; i < 1000; i++) {
		const candidate = path.join(dir, `${base}-${i}${ext}`);
		try {
			await fs.access(candidate);
		} catch {
			return candidate;
		}
	}
	return path.join(dir, `${base}-${Date.now()}${ext}`);
}

/**
 * Try to write the macOS clipboard image to `dest` as PNG.
 * Returns true on success, false if the clipboard does not contain an image.
 */
async function grabMacClipboardImage(
	pi: ExtensionAPI,
	dest: string,
): Promise<{ ok: true } | { ok: false; reason: string }> {
	// Try PNG first, then TIFF (macOS screenshots are often TIFF on the pasteboard).
	const script = `
on run argv
  set destPath to item 1 of argv
  set theData to missing value
  try
    set theData to (the clipboard as «class PNGf»)
  end try
  if theData is missing value then
    try
      set theData to (the clipboard as «class TIFF»)
    end try
  end if
  if theData is missing value then
    return "NOIMAGE"
  end if
  try
    set f to open for access (POSIX file destPath) with write permission
    set eof f to 0
    write theData to f
    close access f
    return "OK"
  on error errMsg
    try
      close access (POSIX file destPath)
    end try
    return "ERR:" & errMsg
  end try
end run
`;

	const result = await pi.exec("osascript", ["-e", script, dest], { timeout: 5000 });
	const out = (result.stdout ?? "").trim();
	if (result.code !== 0) {
		return { ok: false, reason: `osascript exited ${result.code}: ${result.stderr?.trim() || out}` };
	}
	if (out === "OK") return { ok: true };
	if (out === "NOIMAGE") return { ok: false, reason: "Clipboard does not contain an image" };
	return { ok: false, reason: out || "Unknown osascript error" };
}

async function handlePasteImage(args: string, ctx: ExtensionContext, pi: ExtensionAPI): Promise<void> {
	if (process.platform !== "darwin") {
		ctx.ui.notify("save-pasted-image: only macOS is supported right now", "error");
		return;
	}

	// 1. Dump clipboard image to a temp file.
	const tmpFile = path.join(os.tmpdir(), `pi-clip-${process.pid}-${Date.now()}.png`);
	const grab = await grabMacClipboardImage(pi, tmpFile);
	if (!grab.ok) {
		ctx.ui.notify(`No image pasted: ${grab.reason}`, "warning");
		return;
	}

	// 2. Decide on filename.
	const argName = args.trim();
	let chosen: string | undefined;

	if (argName) {
		chosen = argName;
	} else if (ctx.hasUI) {
		const defaultName = `pasted-${timestamp()}.png`;
		const answer = await ctx.ui.input(
			`Save clipboard image as (in ${ctx.cwd}) — Esc to cancel`,
			defaultName,
		);
		if (answer === undefined) {
			await fs.unlink(tmpFile).catch(() => {});
			ctx.ui.notify("Image paste cancelled", "info");
			return;
		}
		chosen = answer.trim() || defaultName;
	} else {
		chosen = `pasted-${timestamp()}.png`;
	}

	// Ensure .png extension if user gave none
	if (!path.extname(chosen)) chosen += ".png";

	// 3. Resolve, ensure dir, move into place.
	const targetRaw = path.isAbsolute(chosen) ? chosen : path.join(ctx.cwd, chosen);
	try {
		await fs.mkdir(path.dirname(targetRaw), { recursive: true });
		const finalPath = await uniquePath(targetRaw);
		await fs.rename(tmpFile, finalPath).catch(async (err) => {
			// rename across devices fails -> copy + unlink
			if ((err as NodeJS.ErrnoException).code === "EXDEV") {
				await fs.copyFile(tmpFile, finalPath);
				await fs.unlink(tmpFile).catch(() => {});
			} else {
				throw err;
			}
		});

		ctx.ui.notify(`Saved clipboard image -> ${finalPath}`, "info");

		// 4. Drop an @<path> reference into the editor.
		if (ctx.hasUI) {
			const current = ctx.ui.getEditorText?.() ?? "";
			const ref = `@${finalPath}`;
			const next = current.length === 0 ? ref : `${current.replace(/\s*$/, "")} ${ref}`;
			ctx.ui.setEditorText(next);
		}
	} catch (err) {
		await fs.unlink(tmpFile).catch(() => {});
		ctx.ui.notify(
			`Failed to save image: ${err instanceof Error ? err.message : String(err)}`,
			"error",
		);
	}
}

export default function (pi: ExtensionAPI) {
	pi.registerCommand("img", {
		description: "Save clipboard image to cwd and reference it in the prompt",
		handler: async (args, ctx) => {
			await handlePasteImage(args, ctx, pi);
		},
	});

}
