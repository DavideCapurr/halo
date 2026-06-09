import { serve } from "https://deno.land/std@0.210.0/http/server.ts";
import {
  decodeJWSPayload,
  jsonResponse,
  stringValue,
  syncStoreKitTransaction,
} from "../_shared/storekit.ts";

serve(async (req) => {
  if (req.method !== "POST") {
    return jsonResponse({ ok: false, error: "method not allowed" }, { status: 405 });
  }

  try {
    const body = await req.json();
    const signedPayload = body.signedPayload;
    if (typeof signedPayload !== "string") {
      return jsonResponse({ ok: false, error: "missing signedPayload" }, { status: 400 });
    }

    const notification = decodeJWSPayload(signedPayload);
    const data = notification.data as Record<string, unknown> | undefined;
    const signedTransactionInfo = stringValue(data?.signedTransactionInfo);

    if (!signedTransactionInfo) {
      return jsonResponse({
        ok: true,
        ignored: true,
        reason: "notification has no transaction payload",
      });
    }

    const transactionPayload = decodeJWSPayload(signedTransactionInfo);
    if (!stringValue(transactionPayload.appAccountToken)) {
      return jsonResponse({
        ok: true,
        ignored: true,
        reason: "transaction has no app account token",
      });
    }

    const entitlement = await syncStoreKitTransaction({ signedTransactionInfo });
    return jsonResponse({
      ok: true,
      notificationType: notification.notificationType ?? null,
      subtype: notification.subtype ?? null,
      entitlement,
    });
  } catch (error) {
    return jsonResponse({
      ok: false,
      error: error instanceof Error ? error.message : "storekit webhook failed",
    }, { status: 400 });
  }
});
