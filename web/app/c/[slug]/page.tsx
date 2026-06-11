import { notFound } from "next/navigation";
import { coverURL, getCampaign, getSupporters } from "@/lib/supabase";
import { formatMoney } from "@/lib/format";
import DonateButton from "./DonateButton";

export const dynamic = "force-dynamic";

export default async function CampaignPage({
  params,
  searchParams,
}: {
  params: { slug: string };
  searchParams: { status?: string };
}) {
  const campaign = await getCampaign(params.slug);
  if (!campaign) notFound();

  const supporters = await getSupporters(params.slug).catch(() => []);
  const cover = coverURL(campaign.cover_path);
  const progress =
    campaign.goal_cents > 0
      ? Math.min(campaign.raised_cents / campaign.goal_cents, 1)
      : 0;
  const reached = campaign.raised_cents >= campaign.goal_cents;
  const expired = campaign.expires_at
    ? new Date(campaign.expires_at) <= new Date()
    : false;
  const collecting = campaign.status === "active" && !expired;
  const remaining = Math.max(campaign.goal_cents - campaign.raised_cents, 0);

  return (
    <main className="wrap">
      <p className="eyebrow">Halo / Campagna</p>

      {searchParams.status === "success" && (
        <div className="banner success">
          Grazie! Il tuo contributo è stato ricevuto. Il totale si aggiorna appena
          Stripe conferma.
        </div>
      )}
      {searchParams.status === "cancel" && (
        <div className="banner cancel">Donazione annullata. Puoi riprovare quando vuoi.</div>
      )}

      {cover && <img className="cover" src={cover} alt={campaign.title} />}
      <h1 className="title">{campaign.title}</h1>
      {campaign.description && <p className="description">{campaign.description}</p>}

      <div className="panel">
        <div className="bar">
          <span style={{ width: `${Math.max(progress * 100, 4)}%` }} />
        </div>
        <div className="metrics">
          <div className="metric">
            <div className="value">
              {formatMoney(campaign.raised_cents, campaign.currency)}
            </div>
            <div className="label">raccolti</div>
          </div>
          <div className="metric">
            <div className="value">
              {formatMoney(campaign.goal_cents, campaign.currency)}
            </div>
            <div className="label">obiettivo</div>
          </div>
          <div className="metric">
            <div className="value">{campaign.supporter_count}</div>
            <div className="label">sostenitori</div>
          </div>
        </div>
        <p className={`status-line${reached ? " reached" : ""}`}>
          {reached
            ? "Traguardo raggiunto — e si può ancora dare."
            : collecting
              ? `Mancano ${formatMoney(remaining, campaign.currency)}.`
              : "Campagna chiusa."}
        </p>
      </div>

      {collecting ? (
        <DonateButton campaignId={campaign.id} currency={campaign.currency} />
      ) : (
        <div className="panel">
          <p className="description">Questa campagna non accetta più donazioni.</p>
        </div>
      )}

      {supporters.length > 0 && (
        <div className="panel">
          <p className="eyebrow">Sostenitori</p>
          <div>
            {supporters.map((s, i) => (
              <div className="supporter" key={i}>
                <div>
                  <div className="name">{s.display_name ?? "Sostenitore"}</div>
                  {s.message && <div className="msg">{s.message}</div>}
                </div>
                <div className="amount">{formatMoney(s.amount_cents, campaign.currency)}</div>
              </div>
            ))}
          </div>
        </div>
      )}

      <p className="footer">
        I fondi vanno diretti a chi ha creato la campagna. Halo è solo il megafono.
      </p>
    </main>
  );
}
