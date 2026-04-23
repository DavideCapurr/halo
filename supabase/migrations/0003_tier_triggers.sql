-- Halo MVP — trigger su follows
-- 1. Soft cap sui tier Inner (5) e Close (15): logga un NOTICE ma non blocca.
--    La UX scoraggia il superamento; nessun hard limit per riflettere Dunbar in modo flessibile.
-- 2. Gestione proposed_tier: la promozione di tier richiede conferma reciproca.
--    Chi viene "tirato dentro" deve accettare.

-- ---------- soft cap su Inner/Close ----------
create or replace function public.follows_soft_cap_warn()
returns trigger language plpgsql as $$
declare
  c_inner int;
  c_close int;
begin
  if new.tier = 'inner' then
    select count(*) into c_inner
    from public.follows
    where follower_id = new.follower_id and tier = 'inner'
      and (tg_op = 'INSERT' or followee_id <> new.followee_id);
    if c_inner >= 5 then
      raise notice 'Halo soft cap: % utenti già in Inner per %', c_inner, new.follower_id;
    end if;
  elsif new.tier = 'close' then
    select count(*) into c_close
    from public.follows
    where follower_id = new.follower_id and tier = 'close'
      and (tg_op = 'INSERT' or followee_id <> new.followee_id);
    if c_close >= 15 then
      raise notice 'Halo soft cap: % utenti già in Close per %', c_close, new.follower_id;
    end if;
  end if;
  return new;
end
$$;

drop trigger if exists trg_follows_soft_cap on public.follows;
create trigger trg_follows_soft_cap
before insert or update of tier on public.follows
for each row execute function public.follows_soft_cap_warn();

-- ---------- drag-to-tier: conferma reciproca ----------
-- Regole:
--   * Il follower può liberamente DECLASSARE (es. inner -> nebula) senza conferma.
--   * La PROMOZIONE (verso un tier più alto) richiede proposed_tier + proposed_by,
--     e la riga deve essere confermata da controparte prima di aggiornare `tier`.
--
-- Enforcement: se qualcuno tenta di aumentare `tier` direttamente senza passare
-- da proposed_tier, il trigger lo impedisce. Le app client devono:
--   1. Chi propone -> UPDATE proposed_tier = X, proposed_by = auth.uid()
--   2. Controparte -> UPDATE tier = proposed_tier, proposed_tier = NULL, proposed_by = NULL
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

  -- Promozione: deve coincidere con una proposed_tier approvata dall'altra parte.
  -- La controparte (cioè il soggetto "avvicinato") è il followee (se il follower propone)
  -- o viceversa; accettiamo entrambi i versi.
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

drop trigger if exists trg_follows_tier_promotion on public.follows;
create trigger trg_follows_tier_promotion
before update of tier on public.follows
for each row execute function public.follows_tier_promotion_guard();
