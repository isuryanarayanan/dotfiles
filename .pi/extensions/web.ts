import { Type } from "@earendil-works/pi-ai";
import { defineTool, type ExtensionAPI } from "@earendil-works/pi-coding-agent";

const USER_AGENT =
  "Mozilla/5.0 (compatible; pi-web-tools/1.0; +https://pi.dev) AppleWebKit/537.36 Chrome/120 Safari/537.36";

function decodeHtml(input: string): string {
  return input
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#39;|&apos;/g, "'")
    .replace(/&#x([0-9a-f]+);/gi, (_match, hex) => String.fromCodePoint(Number.parseInt(hex, 16)))
    .replace(/&#(\d+);/g, (_match, num) => String.fromCodePoint(Number.parseInt(num, 10)));
}

function stripHtml(input: string): string {
  return decodeHtml(
    input
      .replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi, " ")
      .replace(/<style\b[^>]*>[\s\S]*?<\/style>/gi, " ")
      .replace(/<noscript\b[^>]*>[\s\S]*?<\/noscript>/gi, " ")
      .replace(/<br\s*\/?>/gi, "\n")
      .replace(/<\/p\s*>/gi, "\n\n")
      .replace(/<\/h[1-6]\s*>/gi, "\n\n")
      .replace(/<[^>]+>/g, " ")
  )
    .replace(/[ \t]+/g, " ")
    .replace(/\n[ \t]+/g, "\n")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

function duckDuckGoRedirectToUrl(rawUrl: string): string {
  try {
    const parsed = new URL(decodeHtml(rawUrl), "https://duckduckgo.com");
    const uddg = parsed.searchParams.get("uddg");
    return uddg ? decodeURIComponent(uddg) : parsed.toString();
  } catch {
    return decodeHtml(rawUrl);
  }
}

function truncate(text: string, maxChars: number): string {
  if (text.length <= maxChars) return text;
  return `${text.slice(0, maxChars)}\n\n[truncated to ${maxChars} characters]`;
}

export default function(pi: ExtensionAPI) {
  pi.registerTool(defineTool({
    name: "web_search",
    label: "Web Search",
    description:
      "Search the web for current information. Returns titles, URLs, and snippets. Use before web_fetch when you need to discover relevant pages.",
    parameters: Type.Object({
      query: Type.String({ description: "Search query" }),
      max_results: Type.Optional(
        Type.Number({ description: "Maximum number of results to return, default 5, maximum 10", minimum: 1, maximum: 10 })
      ),
    }),
    async execute(_toolCallId, params, signal) {
      const maxResults = Math.min(Math.max(Math.floor(params.max_results ?? 5), 1), 10);
      const url = `https://html.duckduckgo.com/html/?q=${encodeURIComponent(params.query)}`;
      const response = await fetch(url, {
        signal,
        headers: { "User-Agent": USER_AGENT, Accept: "text/html" },
      });

      if (!response.ok) {
        throw new Error(`Search failed: HTTP ${response.status} ${response.statusText}`);
      }

      const html = await response.text();
      const results: Array<{ title: string; url: string; snippet: string }> = [];
      const resultRegex = /<div class="result[\s\S]*?<a rel="nofollow" class="result__a" href="([^"]+)"[^>]*>([\s\S]*?)<\/a>[\s\S]*?<a class="result__snippet"[\s\S]*?>([\s\S]*?)<\/a>/gi;

      for (const match of html.matchAll(resultRegex)) {
        results.push({
          title: stripHtml(match[2]),
          url: duckDuckGoRedirectToUrl(match[1]),
          snippet: stripHtml(match[3]),
        });
        if (results.length >= maxResults) break;
      }

      const text = results.length
        ? results.map((result, index) => `${index + 1}. ${result.title}\n${result.url}\n${result.snippet}`).join("\n\n")
        : `No results found for: ${params.query}`;

      return {
        content: [{ type: "text", text }],
        details: { query: params.query, resultCount: results.length, source: "duckduckgo-html" },
      };
    },
  }));

  pi.registerTool(defineTool({
    name: "web_fetch",
    label: "Web Fetch",
    description:
      "Fetch a URL and return readable text content. Use this to inspect pages found by web_search or URLs provided by the user.",
    parameters: Type.Object({
      url: Type.String({ description: "HTTP or HTTPS URL to fetch" }),
      max_chars: Type.Optional(
        Type.Number({ description: "Maximum characters to return, default 20000, maximum 100000", minimum: 1000, maximum: 100000 })
      ),
    }),
    async execute(_toolCallId, params, signal) {
      const url = new URL(params.url);
      if (url.protocol !== "http:" && url.protocol !== "https:") {
        throw new Error("web_fetch only supports http:// and https:// URLs");
      }

      const maxChars = Math.min(Math.max(Math.floor(params.max_chars ?? 20000), 1000), 100000);
      const response = await fetch(url, {
        signal,
        headers: { "User-Agent": USER_AGENT, Accept: "text/html,text/plain,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" },
      });

      if (!response.ok) {
        throw new Error(`Fetch failed: HTTP ${response.status} ${response.statusText}`);
      }

      const contentType = response.headers.get("content-type") ?? "";
      const raw = await response.text();
      const text = contentType.includes("text/html") || /<html[\s>]/i.test(raw) ? stripHtml(raw) : raw.trim();

      return {
        content: [{ type: "text", text: truncate(text, maxChars) }],
        details: { url: url.toString(), contentType, characters: text.length },
      };
    },
  }));
}
