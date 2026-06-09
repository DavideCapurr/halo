import { serve } from "https://deno.land/std@0.210.0/http/server.ts";
import {
  authenticatedUserId,
  jsonResponse,
  syncStoreKitTransaction,
} from "../_shared/storekit.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ ok: false, error: "method not allowed" }, {
      status: 405,
      headers: corsHeaders,
    });
  }

  try {
    const userId = await authenticatedUserId(req);
    const body = await req.json();
    const signedTransactionInfo =
      body.signedTransactionInfo ?? body.transactionJWS ?? body.jwsRepresentation;

    if (typeof signedTransactionInfo !== "string") {
      return jsonResponse({ ok: false, error: "missing transaction" }, {
        status: 400,
        headers: corsHeaders,
      });
    }

    const entitlement = await syncStoreKitTransaction({
      signedTransactionInfo,
      expectedUserId: userId,
    });

    return jsonResponse({ ok: true, entitlement }, { headers: corsHeaders });
  } catch (error) {
    return jsonResponse({
      ok: false,
      error: error instanceof Error ? error.message : "storekit sync failed",
    }, {
      status: 400,
      headers: corsHeaders,
    });
  }
});
