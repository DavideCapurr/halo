"use client";

import { useState } from "react";
import { ANON_KEY, FUNCTIONS_URL } from "@/lib/supabase";
import { formatMoney } from "@/lib/format";

const PRESETS = [1, 2, 5, 10, 20];

export default function DonateButton({
  campaignId,
  currency,
}: {
  campaignId: string;
  currency: string;
}) {
  const [amount, setAmount] = useState(5);
  const [message, setMessage] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function donate() {
    setLoading(true);
    setError(null);
    try {
      const base = window.location.origin + window.location.pathname;
      const res = await fetch(`${FUNCTIONS_URL}/campaign-create-payment`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          apikey: ANON_KEY,
          Authorization: `Bearer ${ANON_KEY}`,
        },
        body: JSON.stringify({
          campaignId,
          amountCents: Math.round(amount * 100),
          message: message.trim() || undefined,
          mode: "checkout",
          successUrl: `${base}?status=success`,
          cancelUrl: `${base}?status=cancel`,
        }),
      });
      const data = await res.json();
      if (!res.ok || !data.url) {
        throw new Error(data.error ?? "Donazione non riuscita.");
      }
      window.location.href = data.url as string;
    } catch (e) {
      setError(e instanceof Error ? e.message : "Donazione non riuscita.");
      setLoading(false);
    }
  }

  return (
    <div className="panel">
      <p className="eyebrow">Dona</p>
      <div className="presets" style={{ marginTop: 12 }}>
        {PRESETS.map((value) => (
          <button
            key={value}
            className={`chip${amount === value ? " active" : ""}`}
            onClick={() => setAmount(value)}
            type="button"
          >
            {formatMoney(value * 100, currency)}
          </button>
        ))}
      </div>
      <div className="row">
        <input
          className="input"
          type="number"
          min={1}
          value={amount}
          onChange={(e) => setAmount(Math.max(1, Number(e.target.value) || 1))}
          aria-label="importo personalizzato"
        />
      </div>
      <div className="row">
        <input
          className="input"
          type="text"
          placeholder="un messaggio (opzionale)"
          maxLength={280}
          value={message}
          onChange={(e) => setMessage(e.target.value)}
        />
      </div>
      <button className="donate" onClick={donate} disabled={loading} type="button">
        {loading ? "Attendi…" : `Dona ${formatMoney(Math.round(amount * 100), currency)}`}
      </button>
      {error && <p className="error">{error}</p>}
      <p className="fineprint">
        Pagamento sicuro via Stripe (Apple Pay, Google Pay, carta). I fondi vanno
        diretti a chi ha creato la campagna; Halo trattiene solo una piccola
        commissione.
      </p>
    </div>
  );
}
