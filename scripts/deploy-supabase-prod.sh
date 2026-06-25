#!/usr/bin/env bash
#
# Halo — deploy Supabase prod (migrations + edge functions + secrets).
#
# Esegue l'item Fase 0 di TODO.md "Supabase prod deployato" in un comando.
# Richiede la Supabase CLI loggata (`supabase login`) e il ref del progetto
# prod. NON committare i secret: passali via file env locale (vedi sotto).
#
# Uso:
#   PROJECT_REF=xxxxxxxxxxxx ./scripts/deploy-supabase-prod.sh
#   # opzionale: SECRETS_FILE=supabase/.env.prod (default) per i secret funzioni
#
# Step idempotenti: link → db push → functions deploy → secrets set.
set -euo pipefail

cd "$(dirname "$0")/.."

PROJECT_REF="${PROJECT_REF:-}"
SECRETS_FILE="${SECRETS_FILE:-supabase/.env.prod}"

if ! command -v supabase >/dev/null 2>&1; then
  echo "✗ Supabase CLI non trovata. Installa: https://supabase.com/docs/guides/cli" >&2
  exit 1
fi

if [[ -z "$PROJECT_REF" ]]; then
  echo "✗ Imposta PROJECT_REF (ref del progetto prod, es. gxzdasexwlfmxhimaxnd)." >&2
  exit 1
fi

# Funzioni edge senza verifica JWT (webhook / endpoint pubblici). Devono
# combaciare con i blocchi verify_jwt=false in supabase/config.toml.
PUBLIC_FUNCTIONS=(purge-expired waitlist-signup apple-storekit-webhook stripe-webhook)
# Funzioni edge che richiedono un JWT valido del chiamante.
AUTH_FUNCTIONS=(apple-storekit-sync stripe-create-checkout-session stripe-customer-portal)

echo "→ Link al progetto prod ($PROJECT_REF)…"
supabase link --project-ref "$PROJECT_REF"

echo "→ Push delle migrations…"
supabase db push

echo "→ Deploy edge functions (no-verify-jwt)…"
for fn in "${PUBLIC_FUNCTIONS[@]}"; do
  echo "  • $fn"
  supabase functions deploy "$fn" --no-verify-jwt --project-ref "$PROJECT_REF"
done

echo "→ Deploy edge functions (jwt richiesto)…"
for fn in "${AUTH_FUNCTIONS[@]}"; do
  echo "  • $fn"
  supabase functions deploy "$fn" --project-ref "$PROJECT_REF"
done

if [[ -f "$SECRETS_FILE" ]]; then
  echo "→ Set secrets da $SECRETS_FILE…"
  supabase secrets set --env-file "$SECRETS_FILE" --project-ref "$PROJECT_REF"
else
  cat >&2 <<EOF
⚠ $SECRETS_FILE assente: secret funzioni NON impostati.
  Crea il file (gitignored) a partire da supabase/.env.prod.example e ri-esegui,
  oppure: supabase secrets set --project-ref $PROJECT_REF KEY=VALUE …
EOF
fi

echo "✓ Deploy prod completato."
