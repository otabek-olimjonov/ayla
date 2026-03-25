// =============================================================================
// Ayla – AI Chat Edge Function (Gemini)
// =============================================================================
// Endpoint: POST /functions/v1/ai-chat
// Auth:     Required (JWT in Authorization header)
// Body:     { message: string, history: {role, content}[], context: AylaContext }
// Response: { reply: string }
//
// Deploy:   supabase functions deploy ai-chat
// Env vars (set in Supabase Dashboard → Settings → Edge Functions):
//   GEMINI_API_KEY  — your Google AI Studio API key
//   GEMINI_MODEL    — model name (default: gemini-2.0-flash)
// =============================================================================

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
interface ChatMessage {
  role: "user" | "assistant";
  content: string;
}

interface AylaContext {
  mode: "cycle" | "pregnancy";
  language: string;       // 'uz' | 'uz_CY' | 'ru' | 'en'
  cycleLength?: number;
  phase?: string;         // 'menstrual' | 'follicular' | 'ovulation' | 'luteal'
  cycleDay?: number;
  pregnancyWeek?: number;
}

interface RequestBody {
  message: string;
  history: ChatMessage[]; // last N messages for context window
  context: AylaContext;
}

// Gemini REST API types
interface GeminiPart {
  text: string;
}

interface GeminiContent {
  role: "user" | "model";
  parts: GeminiPart[];
}

interface GeminiRequest {
  system_instruction: { parts: GeminiPart[] };
  contents: GeminiContent[];
  generationConfig: {
    maxOutputTokens: number;
    temperature: number;
  };
}

// ---------------------------------------------------------------------------
// System prompt builder
// ---------------------------------------------------------------------------
function buildSystemPrompt(ctx: AylaContext): string {
  const languageNames: Record<string, string> = {
    uz: "Uzbek (Latin script)",
    uz_CY: "Uzbek (Cyrillic script)",
    ru: "Russian",
    en: "English",
  };
  const lang = languageNames[ctx.language] ?? "Uzbek (Latin script)";

  const lines: string[] = [
    `You are Ayla, a friendly and empathetic women's health assistant.`,
    `You help women understand their menstrual cycle, pregnancy, symptoms, and general reproductive health.`,
    ``,
    `IMPORTANT RULES:`,
    `- ALWAYS respond in ${lang}.`,
    `- NEVER provide definitive medical diagnoses.`,
    `- ALWAYS include a brief disclaimer at the end of any health-related advice.`,
    `- Keep responses concise (1–3 paragraphs max).`,
    `- Be warm, supportive, and non-judgmental.`,
    `- If asked about something outside women's health or cycle tracking, politely redirect.`,
    ``,
    `USER CONTEXT:`,
    `- App mode: ${ctx.mode}`,
  ];

  if (ctx.mode === "cycle") {
    if (ctx.phase)       lines.push(`- Current cycle phase: ${ctx.phase}`);
    if (ctx.cycleDay)    lines.push(`- Current cycle day: ${ctx.cycleDay}`);
    if (ctx.cycleLength) lines.push(`- Typical cycle length: ${ctx.cycleLength} days`);
  } else if (ctx.mode === "pregnancy" && ctx.pregnancyWeek) {
    const trimester =
      ctx.pregnancyWeek < 13 ? "first" : ctx.pregnancyWeek < 27 ? "second" : "third";
    lines.push(`- Pregnancy week: ${ctx.pregnancyWeek} (${trimester} trimester)`);
  }

  lines.push(
    ``,
    `DISCLAIMER TEMPLATE (adapt to the response language):`,
    `"⚠️ This is general health information, not medical advice. Please consult your doctor for personal medical concerns."`,
  );

  return lines.join("\n");
}

// ---------------------------------------------------------------------------
// Convert stored chat history → Gemini contents array.
// Gemini uses role "model" (not "assistant") and requires alternating turns.
// Consecutive same-role messages are merged into one content entry.
// ---------------------------------------------------------------------------
function toGeminiContents(history: ChatMessage[]): GeminiContent[] {
  const contents: GeminiContent[] = [];
  for (const msg of history) {
    const role: "user" | "model" = msg.role === "user" ? "user" : "model";
    const last = contents[contents.length - 1];
    if (last && last.role === role) {
      last.parts.push({ text: msg.content });
    } else {
      contents.push({ role, parts: [{ text: msg.content }] });
    }
  }
  return contents;
}

// ---------------------------------------------------------------------------
// Main handler
// ---------------------------------------------------------------------------
serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers":
          "authorization, x-client-info, apikey, content-type",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
      },
    });
  }

  if (req.method !== "POST") return jsonError("Method not allowed", 405);

  // ---------------------------------------------------------------------------
  // Authenticate via Supabase JWT
  // ---------------------------------------------------------------------------
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return jsonError("Missing authorization header", 401);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data: { user }, error: authError } = await supabase.auth.getUser();
  if (authError || !user) return jsonError("Unauthorized", 401);

  // ---------------------------------------------------------------------------
  // Parse body
  // ---------------------------------------------------------------------------
  let body: RequestBody;
  try {
    body = await req.json();
  } catch {
    return jsonError("Invalid JSON body", 400);
  }

  const { message, history = [], context } = body;
  if (!message?.trim()) return jsonError("message is required", 400);
  if (!context)         return jsonError("context is required", 400);

  // ---------------------------------------------------------------------------
  // Build Gemini request
  // ---------------------------------------------------------------------------
  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey) return jsonError("AI service not configured", 503);

  const model    = Deno.env.get("GEMINI_MODEL") ?? "gemini-2.0-flash";
  const endpoint =
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;

  // Keep last 20 messages; append current user message as the final turn
  const contents = toGeminiContents(history.slice(-20));
  const lastTurn = contents[contents.length - 1];
  if (lastTurn?.role === "user") {
    lastTurn.parts.push({ text: message.trim() });
  } else {
    contents.push({ role: "user", parts: [{ text: message.trim() }] });
  }

  const geminiRequest: GeminiRequest = {
    system_instruction: { parts: [{ text: buildSystemPrompt(context) }] },
    contents,
    generationConfig: {
      maxOutputTokens: 512,
      temperature: 0.7,
    },
  };

  // ---------------------------------------------------------------------------
  // Call Gemini API
  // ---------------------------------------------------------------------------
  let aiReply: string;
  try {
    const response = await fetch(`${endpoint}?key=${apiKey}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(geminiRequest),
    });

    if (!response.ok) {
      const errText = await response.text();
      console.error("Gemini API error:", response.status, errText);
      return jsonError("AI service error", 502);
    }

    const data = await response.json();

    // Extract text: candidates[0].content.parts[].text
    aiReply = (data?.candidates?.[0]?.content?.parts as GeminiPart[] ?? [])
      .map((p) => p.text)
      .join("")
      .trim();

    if (!aiReply) return jsonError("Empty response from AI service", 502);
  } catch (err) {
    console.error("Gemini fetch error:", err);
    return jsonError("AI service unreachable", 503);
  }

  // ---------------------------------------------------------------------------
  // Persist both messages (fire-and-forget)
  // ---------------------------------------------------------------------------
  const adminClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  adminClient.from("ai_chat_messages").insert([
    { user_id: user.id, role: "user",      content: message.trim() },
    { user_id: user.id, role: "assistant", content: aiReply },
  ]).then(({ error }) => {
    if (error) console.error("Failed to persist chat messages:", error.message);
  });

  // ---------------------------------------------------------------------------
  // Return reply
  // ---------------------------------------------------------------------------
  return new Response(JSON.stringify({ reply: aiReply }), {
    status: 200,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
  });
});

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------
function jsonError(message: string, status: number): Response {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
  });
}
