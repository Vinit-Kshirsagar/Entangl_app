// Supabase Edge Function: send-push
// Called by DB trigger notify_send_push() via pg_net.
//
// Phase 5: deletes device_tokens when FCM returns UNREGISTERED / invalid.
// Also attaches structured `data` for Flutter NotificationRouter.
//
// Secrets (Dashboard → Edge Functions → Secrets):
//   FIREBASE_PROJECT_ID
//   FIREBASE_SERVICE_ACCOUNT_JSON
//   PUSH_WEBHOOK_SECRET
//   SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY (auto)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-push-secret, x-webhook-secret",
};

type NotifRecord = {
  id?: string;
  user_id: string;
  actor_id: string;
  type: string;
  post_id?: string | null;
  comment_id?: string | null;
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }

  try {
    const secret = Deno.env.get("PUSH_WEBHOOK_SECRET") ?? "";
    const hdr =
      req.headers.get("x-push-secret") ??
      req.headers.get("x-webhook-secret") ??
      "";
    const auth = req.headers.get("Authorization") ?? "";
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    const authorized =
      (secret && hdr === secret) ||
      (serviceKey && auth === `Bearer ${serviceKey}`);

    if (!authorized) {
      return json({ error: "unauthorized" }, 401);
    }

    const body = await req.json();
    const record = (body.record ?? body) as NotifRecord;
    if (!record?.user_id || !record?.type) {
      return json({ error: "missing record.user_id or type" }, 400);
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: tokens, error: tokErr } = await supabase
      .from("device_tokens")
      .select("id, token, platform")
      .eq("user_id", record.user_id);

    if (tokErr) {
      console.error("device_tokens", tokErr);
      return json({ error: tokErr.message }, 500);
    }

    // Backup column
    const { data: profile } = await supabase
      .from("profiles")
      .select("fcm_token, username, full_name")
      .eq("id", record.user_id)
      .maybeSingle();

    const tokenSet = new Set<string>();
    for (const row of tokens ?? []) {
      if (row.token) tokenSet.add(row.token as string);
    }
    if (profile?.fcm_token) tokenSet.add(profile.fcm_token as string);

    if (tokenSet.size === 0) {
      return json({ sent: 0, reason: "no_tokens" });
    }

    const { data: actor } = await supabase
      .from("profiles")
      .select("username, full_name")
      .eq("id", record.actor_id)
      .maybeSingle();

    const actorName =
      (actor?.full_name as string) ||
      (actor?.username as string) ||
      "Someone";

    const { title, body: notifBody } = buildCopy(record.type, actorName);

    const accessToken = await getGoogleAccessToken();
    const projectId = Deno.env.get("FIREBASE_PROJECT_ID")!;
    const dataPayload: Record<string, string> = {
      type: record.type,
      actor_id: record.actor_id ?? "",
      notification_id: record.id ?? "",
    };
    if (record.post_id) dataPayload.post_id = record.post_id;
    if (record.comment_id) dataPayload.comment_id = record.comment_id;

    let sent = 0;
    const removed: string[] = [];
    const errors: string[] = [];

    for (const token of tokenSet) {
      const res = await fetch(
        `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token,
              notification: { title, body: notifBody },
              data: dataPayload,
              android: {
                priority: "HIGH",
                notification: { channel_id: "entangl_push" },
              },
            },
          }),
        },
      );

      if (res.ok) {
        sent++;
        continue;
      }

      const errText = await res.text();
      errors.push(errText.slice(0, 300));

      // Stale / invalid registration → remove so we stop retrying forever.
      if (shouldDropToken(errText)) {
        await supabase.from("device_tokens").delete().eq("token", token);
        if (profile?.fcm_token === token) {
          await supabase
            .from("profiles")
            .update({ fcm_token: null })
            .eq("id", record.user_id);
        }
        removed.push(token.slice(0, 12));
      }
    }

    return json({
      sent,
      removed: removed.length,
      removed_prefixes: removed,
      errors: errors.length ? errors.slice(0, 3) : undefined,
    });
  } catch (e) {
    console.error(e);
    return json({ error: String(e) }, 500);
  }
});

function shouldDropToken(fcmErrorBody: string): boolean {
  const t = fcmErrorBody.toUpperCase();
  return (
    t.includes("UNREGISTERED") ||
    t.includes("NOT_FOUND") ||
    t.includes("INVALID_ARGUMENT") ||
    t.includes("REGISTRATION-TOKEN-NOT-REGISTERED") ||
    t.includes("INVALID_REGISTRATION")
  );
}

function buildCopy(type: string, actorName: string): {
  title: string;
  body: string;
} {
  switch (type) {
    case "follow":
      return { title: "New follower", body: `${actorName} started following you` };
    case "like":
      return { title: "New like", body: `${actorName} liked your post` };
    case "dislike":
      return { title: "New reaction", body: `${actorName} disliked your post` };
    case "comment":
      return { title: "New comment", body: `${actorName} commented on your post` };
    case "reply":
      return { title: "New reply", body: `${actorName} replied to your comment` };
    case "new_post":
      return {
        title: "New post",
        body: `${actorName} just posted something new`,
      };
    default:
      return { title: "Entangl", body: `${actorName} interacted with you` };
  }
}

async function getGoogleAccessToken(): Promise<string> {
  const raw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
  if (!raw) throw new Error("FIREBASE_SERVICE_ACCOUNT_JSON missing");
  const sa = JSON.parse(raw);
  const now = Math.floor(Date.now() / 1000);
  const header = b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claim = b64url(
    JSON.stringify({
      iss: sa.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    }),
  );
  const unsigned = `${header}.${claim}`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(sa.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsigned),
  );
  const jwt = `${unsigned}.${b64url(sig)}`;

  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  if (!tokenRes.ok) {
    throw new Error(`google token: ${await tokenRes.text()}`);
  }
  const tok = await tokenRes.json();
  return tok.access_token as string;
}

function b64url(input: string | ArrayBuffer): string {
  let bytes: Uint8Array;
  if (typeof input === "string") {
    bytes = new TextEncoder().encode(input);
  } else {
    bytes = new Uint8Array(input);
  }
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const b64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s+/g, "");
  const raw = atob(b64);
  const buf = new Uint8Array(raw.length);
  for (let i = 0; i < raw.length; i++) buf[i] = raw.charCodeAt(i);
  return buf.buffer;
}

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}
