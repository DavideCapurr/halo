-- Halo MVP — indici per mutualità
-- L'orbital field separa i follow mutuali (bolle) dai follow asimmetrici (asteroidi).
-- La query di mutualità (per il viewer V e una lista di candidati U) ha forma:
--
--   select followee_id from follows where follower_id = V and followee_id = any(U)
--   intersect
--   select follower_id from follows where followee_id = V and follower_id = any(U)
--
-- L'indice esistente `follows_followee_idx` copre il secondo verso.
-- L'indice esistente `follows_follower_tier_idx` ha (follower_id, tier): ottimo per
-- "le mie follow ordinate per tier", ma non per il filtro su followee_id.
-- Aggiungiamo un indice composito (follower_id, followee_id) — già implicito nella
-- PK, ma i lookup `eq + in` su `followee_id` a volte non lo sfruttano: l'indice esplicito
-- (follower_id, followee_id) coincide con la PK e quindi è già coperto.
-- Aggiungiamo invece un indice sul *secondo verso* utile per il bulk mutual check
-- bidirezionale: (followee_id, follower_id).

create index if not exists follows_followee_follower_idx
  on public.follows (followee_id, follower_id);
