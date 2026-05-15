import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type ForumReplyRecord = {
  id: string;
  id_pregunta: string;
  id_autor: string;
  contenido?: string | null;
};

type WebhookPayload = {
  type?: string;
  table?: string;
  record?: ForumReplyRecord;
};

type PushTokenRow = {
  token: string;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const payload = (await req.json()) as WebhookPayload;
    const reply = payload.record;

    if (!reply?.id || !reply.id_pregunta || !reply.id_autor) {
      return json({ skipped: true, reason: "Payload incompleto" }, 400);
    }

    const supabase = createClient(
      requiredEnv("SUPABASE_URL"),
      requiredEnv("SUPABASE_SERVICE_ROLE_KEY"),
      {
        auth: {
          persistSession: false,
          autoRefreshToken: false,
        },
      },
    );

    const { data: question, error: questionError } = await supabase
      .from("preguntas_foro")
      .select("id, id_autor, titulo")
      .eq("id", reply.id_pregunta)
      .maybeSingle();

    if (questionError) throw questionError;
    if (!question) {
      return json({ skipped: true, reason: "Pregunta no encontrada" }, 404);
    }
    if (question.id_autor === reply.id_autor) {
      return json({ skipped: true, reason: "Respuesta propia" });
    }

    const title = "Nueva respuesta en tu pregunta";
    const body = buildBody(question.titulo, reply.contenido);

    await supabase.from("notificaciones").insert({
      id_usuario: question.id_autor,
      titulo: title,
      cuerpo: body,
      tipo: "foro",
      id_referencia: question.id,
      leida: false,
    });

    const { data: preferences } = await supabase
      .from("preferencias_notificacion")
      .select("push_habilitado")
      .eq("id_usuario", question.id_autor)
      .maybeSingle();

    if (preferences?.push_habilitado === false) {
      return json({ sent: 0, skipped: true, reason: "Push deshabilitado" });
    }

    const { data: tokens, error: tokensError } = await supabase
      .from("tokens_push")
      .select("token")
      .eq("id_usuario", question.id_autor)
      .eq("activo", true);

    if (tokensError) throw tokensError;

    const activeTokens = ((tokens ?? []) as PushTokenRow[])
      .map((row) => row.token)
      .filter((token) => token.trim().length > 0);

    if (activeTokens.length === 0) {
      return json({ sent: 0, skipped: true, reason: "Sin tokens activos" });
    }

    const accessToken = await getFirebaseAccessToken();
    const results = await Promise.allSettled(
      activeTokens.map((token) =>
        sendFcmMessage({
          accessToken,
          token,
          title,
          body,
          data: {
            type: "foro",
            threadId: question.id,
            replyId: reply.id,
          },
        })
      ),
    );

    return json({
      sent: results.filter((result) => result.status === "fulfilled").length,
      failed: results.filter((result) => result.status === "rejected").length,
    });
  } catch (error) {
    console.error(error);
    return json(
      { error: error instanceof Error ? error.message : "Error desconocido" },
      500,
    );
  }
});

function buildBody(title: string, content?: string | null) {
  const normalizedTitle = title.trim();
  const normalizedContent = (content ?? "").trim();
  if (normalizedContent.length === 0) return normalizedTitle;

  const shortContent =
    normalizedContent.length > 90
      ? `${normalizedContent.substring(0, 87)}...`
      : normalizedContent;

  return `${normalizedTitle}: ${shortContent}`;
}

async function sendFcmMessage(params: {
  accessToken: string;
  token: string;
  title: string;
  body: string;
  data: Record<string, string>;
}) {
  const projectId = requiredEnv("FIREBASE_PROJECT_ID");
  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${params.accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token: params.token,
          notification: {
            title: params.title,
            body: params.body,
          },
          data: params.data,
          android: {
            priority: "HIGH",
            notification: {
              channel_id: "forum_notifications",
            },
          },
        },
      }),
    },
  );

  if (!response.ok) {
    throw new Error(`FCM ${response.status}: ${await response.text()}`);
  }
}

async function getFirebaseAccessToken() {
  const clientEmail = requiredEnv("FIREBASE_CLIENT_EMAIL");
  const privateKey = requiredEnv("FIREBASE_PRIVATE_KEY").replaceAll("\\n", "\n");
  const now = Math.floor(Date.now() / 1000);
  const jwtHeader = base64UrlEncode(
    JSON.stringify({ alg: "RS256", typ: "JWT" }),
  );
  const jwtClaim = base64UrlEncode(
    JSON.stringify({
      iss: clientEmail,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    }),
  );

  const unsignedJwt = `${jwtHeader}.${jwtClaim}`;
  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(privateKey),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(unsignedJwt),
  );

  const jwt = `${unsignedJwt}.${base64UrlEncode(signature)}`;
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  if (!response.ok) {
    throw new Error(`OAuth ${response.status}: ${await response.text()}`);
  }

  const data = await response.json();
  return data.access_token as string;
}

function pemToArrayBuffer(pem: string) {
  const base64 = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes.buffer;
}

function base64UrlEncode(value: string | ArrayBuffer) {
  const bytes =
    typeof value === "string"
      ? new TextEncoder().encode(value)
      : new Uint8Array(value);
  let binary = "";
  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }
  return btoa(binary)
    .replaceAll("+", "-")
    .replaceAll("/", "_")
    .replaceAll("=", "");
}

function requiredEnv(name: string) {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`Falta el secreto ${name}`);
  return value;
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}
