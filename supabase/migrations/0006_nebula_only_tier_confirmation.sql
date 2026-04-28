-- Halo MVP — aggiorna la regola drag-to-tier.
-- Solo l'uscita da Nebula richiede conferma reciproca; gli spostamenti tra
-- cerchi gia mutuali vengono salvati direttamente su follows.tier.

create or replace function public.follows_tier_promotion_guard()
returns trigger language plpgsql as $$
declare
  old_rank int := public.tier_rank(old.tier);
  new_rank int := public.tier_rank(new.tier);
begin
  -- Declassamento o invariato: ok.
  if new_rank <= old_rank then
    return new;
  end if;

  -- Promozioni tra cerchi gia mutuali: ok.
  if old.tier <> 'nebula' then
    return new;
  end if;

  -- Uscita da Nebula: deve coincidere con una proposed_tier approvata dall'altra parte.
  if old.proposed_tier is null or old.proposed_tier <> new.tier then
    raise exception 'Halo: promozione a % richiede prima una proposed_tier congruente', new.tier
      using errcode = 'check_violation';
  end if;

  if old.proposed_by is null then
    raise exception 'Halo: proposed_by mancante per promozione'
      using errcode = 'check_violation';
  end if;

  -- Chi conferma deve essere diverso da chi ha proposto.
  if auth.uid() is not null and auth.uid() = old.proposed_by then
    raise exception 'Halo: la promozione richiede conferma dalla controparte'
      using errcode = 'check_violation';
  end if;

  -- Reset proposta una volta applicata.
  new.proposed_tier := null;
  new.proposed_by   := null;
  return new;
end
$$;
