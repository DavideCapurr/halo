import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

export const HALO_PLUS_PRODUCT_ID = "app.halo.plus.monthly";

type Json = Record<string, unknown>;

export type StoreKitSyncResult = {
  userId: string;
  productId: string;
  originalTransactionId: string;
  transactionId: string | null;
  status: string;
  currentPeriodStart: string | null;
  currentPeriodEnd: string | null;
  environment: string;
};

export function serviceClient() {
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false } },
  );
}

export function jsonResponse(body: unknown, init: ResponseInit = {}) {
  return new Response(JSON.stringify(body), {
    ...init,
    headers: {
      "Content-Type": "application/json",
      ...(init.headers ?? {}),
    },
  });
}

export async function authenticatedUserId(req: Request): Promise<string> {
  const authHeader = req.headers.get("Authorization") ?? "";
  const token = authHeader.replace(/^Bearer\s+/i, "").trim();
  if (!token) throw new Error("missing authorization");

  const { data, error } = await serviceClient().auth.getUser(token);
  if (error || !data.user) throw new Error("invalid authorization");
  return data.user.id;
}

export async function syncStoreKitTransaction(params: {
  signedTransactionInfo: string;
  expectedUserId?: string;
}): Promise<StoreKitSyncResult> {
  const hinted = decodeJWSPayload(params.signedTransactionInfo);
  const transactionId = stringValue(hinted.transactionId);
  if (!transactionId) throw new Error("missing transaction id");

  const verified = await verifiedTransactionPayload(
    transactionId,
    params.signedTransactionInfo,
    stringValue(hinted.environment),
  );

  const productId = stringValue(verified.productId);
  if (productId !== HALO_PLUS_PRODUCT_ID) {
    throw new Error("unsupported product");
  }

  const bundleId = Deno.env.get("APPLE_BUNDLE_ID");
  const payloadBundleId = stringValue(verified.bundleId);
  if (bundleId && payloadBundleId && payloadBundleId !== bundleId) {
    throw new Error("bundle mismatch");
  }

  const userId = stringValue(verified.appAccountToken) ??
    params.expectedUserId;
  if (!userId) throw new Error("missing app account token");
  if (params.expectedUserId && userId !== params.expectedUserId) {
    throw new Error("app account token mismatch");
  }

  const originalTransactionId =
    stringValue(verified.originalTransactionId) ?? transactionId;
  const status = entitlementStatus(verified);
  const environment = normalizeEnvironment(stringValue(verified.environment));
  const currentPeriodStart = dateFromAppleMillis(verified.purchaseDate);
  const currentPeriodEnd = dateFromAppleMillis(verified.expiresDate);

  const supa = serviceClient();
  const { error } = await supa
    .from("plus_entitlements")
    .upsert({
      user_id: userId,
      provider: "storekit",
      product_id: productId,
      original_transaction_id: originalTransactionId,
      transaction_id: transactionId,
      status,
      current_period_start: currentPeriodStart,
      current_period_end: currentPeriodEnd,
      environment,
      raw_payload: verified,
    }, { onConflict: "provider,original_transaction_id" });

  if (error) throw new Error(error.message);

  return {
    userId,
    productId,
    originalTransactionId,
    transactionId,
    status,
    currentPeriodStart,
    currentPeriodEnd,
    environment,
  };
}

async function verifiedTransactionPayload(
  transactionId: string,
  fallbackJWS: string,
  hintedEnvironment?: string,
): Promise<Json> {
  const credentialsAvailable = Boolean(
    Deno.env.get("APPLE_STOREKIT_ISSUER_ID") &&
      Deno.env.get("APPLE_STOREKIT_KEY_ID") &&
      Deno.env.get("APPLE_STOREKIT_PRIVATE_KEY") &&
      Deno.env.get("APPLE_BUNDLE_ID"),
  );

  if (!credentialsAvailable) {
    if (Deno.env.get("HALO_STOREKIT_ALLOW_LOCAL") === "true") {
      return decodeJWSPayload(fallbackJWS);
    }
    throw new Error("apple storekit credentials missing");
  }

  const candidates = apiCandidates(hintedEnvironment);
  let lastError = "";
  for (const baseURL of candidates) {
    const token = await appStoreServerJWT();
    const response = await fetch(
      `${baseURL}/inApps/v1/transactions/${encodeURIComponent(transactionId)}`,
      { headers: { Authorization: `Bearer ${token}` } },
    );

    if (response.ok) {
      const body = await response.json();
      const signedTransactionInfo = body.signedTransactionInfo;
      if (typeof signedTransactionInfo !== "string") {
        throw new Error("apple response missing transaction info");
      }
      return decodeJWSPayload(signedTransactionInfo);
    }

    lastError = `${response.status} ${await response.text()}`;
  }

  throw new Error(`apple verification failed: ${lastError}`);
}

function apiCandidates(environment?: string): string[] {
  const normalized = normalizeEnvironment(environment);
  const production = "https://api.storekit.itunes.apple.com";
  const sandbox = "https://api.storekit-sandbox.itunes.apple.com";
  if (normalized === "sandbox" || normalized === "xcode") {
    return [sandbox, production];
  }
  return [production, sandbox];
}

async function appStoreServerJWT(): Promise<string> {
  const issuerId = Deno.env.get("APPLE_STOREKIT_ISSUER_ID")!;
  const keyId = Deno.env.get("APPLE_STOREKIT_KEY_ID")!;
  const bundleId = Deno.env.get("APPLE_BUNDLE_ID")!;
  const privateKey = Deno.env.get("APPLE_STOREKIT_PRIVATE_KEY")!;

  const now = Math.floor(Date.now() / 1000);
  const header = base64urlJson({ alg: "ES256", kid: keyId, typ: "JWT" });
  const payload = base64urlJson({
    iss: issuerId,
    iat: now,
    exp: now + 15 * 60,
    aud: "appstoreconnect-v1",
    bid: bundleId,
  });
  const signingInput = `${header}.${payload}`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(privateKey),
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    key,
    new TextEncoder().encode(signingInput),
  );
  return `${signingInput}.${base64url(new Uint8Array(signature))}`;
}

function entitlementStatus(payload: Json): string {
  if (payload.revocationDate) return "revoked";
  const end = dateFromAppleMillis(payload.expiresDate);
  if (end && Date.parse(end) <= Date.now()) return "expired";
  return "active";
}

export function decodeJWSPayload(jws: string): Json {
  const parts = jws.split(".");
  if (parts.length < 2) throw new Error("invalid jws");
  const json = new TextDecoder().decode(base64urlDecode(parts[1]));
  return JSON.parse(json);
}

export function stringValue(value: unknown): string | undefined {
  return typeof value === "string" && value.length > 0 ? value : undefined;
}

function dateFromAppleMillis(value: unknown): string | null {
  if (typeof value === "number") return new Date(value).toISOString();
  if (typeof value === "string" && /^\d+$/.test(value)) {
    return new Date(Number(value)).toISOString();
  }
  if (typeof value === "string" && value.length > 0) {
    return new Date(value).toISOString();
  }
  return null;
}

function normalizeEnvironment(value?: string): string {
  switch ((value ?? "").toLowerCase()) {
    case "production":
      return "production";
    case "sandbox":
      return "sandbox";
    case "xcode":
    case "xcode-local":
    case "localtesting":
      return "xcode";
    default:
      return "unknown";
  }
}

function base64urlJson(value: Json): string {
  return base64url(new TextEncoder().encode(JSON.stringify(value)));
}

function base64url(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

function base64urlDecode(value: string): Uint8Array {
  const padded = value.replace(/-/g, "+").replace(/_/g, "/") +
    "=".repeat((4 - value.length % 4) % 4);
  const binary = atob(padded);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i += 1) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes;
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const normalized = pem.replace(/\\n/g, "\n");
  const base64 = normalized
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s+/g, "");
  const bytes = base64urlDecode(base64.replace(/\+/g, "-").replace(/\//g, "_"));
  const copy = new ArrayBuffer(bytes.byteLength);
  new Uint8Array(copy).set(bytes);
  return copy;
}
