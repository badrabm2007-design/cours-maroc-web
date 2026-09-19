import type { Context, Config } from "@netlify/functions";

export default async (req: Request, context: Context) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, HEAD, OPTIONS",
        "Access-Control-Allow-Headers": "*",
      },
    });
  }

  const url = new URL(req.url);
  const id = url.searchParams.get("id");
  if (!id) {
    return new Response("Missing id parameter", {
      status: 400,
      headers: { "Access-Control-Allow-Origin": "*" },
    });
  }

  const driveUrl = `https://drive.usercontent.google.com/download?id=${id}&export=download&confirm=t`;

  try {
    const upstreamRes = await fetch(driveUrl, {
      headers: {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
      },
    });

    if (!upstreamRes.ok) {
      return new Response(`Error fetching file: ${upstreamRes.statusText}`, {
        status: upstreamRes.status,
        headers: { "Access-Control-Allow-Origin": "*" },
      });
    }

    const headers = new Headers();
    headers.set("Content-Type", "application/pdf");
    headers.set("Access-Control-Allow-Origin", "*");
    headers.set("Access-Control-Allow-Methods", "GET, HEAD, OPTIONS");
    headers.set("Cache-Control", "public, max-age=86400");

    return new Response(upstreamRes.body, {
      status: 200,
      headers,
    });
  } catch (e: any) {
    return new Response(`Error fetching PDF: ${e?.message || e}`, {
      status: 500,
      headers: { "Access-Control-Allow-Origin": "*" },
    });
  }
};

export const config: Config = {
  path: "/api/pdf",
};
