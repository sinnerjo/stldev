-- MatchTap live sharing
-- Run this once in the Supabase SQL editor for the same project FlappyBall uses.
-- It is safe to run again; it only creates what is missing and replaces the functions.
--
-- How it's locked down: the three tables have row level security turned on with
-- no policies, so the publishable key can't read or list them directly. The app
-- only talks to the database through the mt_* functions below, and every one of
-- them needs a game code, so you can only see a game if you know its code.

create table if not exists public.mt_games (
  code        text primary key check (code ~ '^[A-Z0-9]{6}$'),
  meta        jsonb not null default '{}'::jsonb check (pg_column_size(meta) < 20000),
  meta_rev    bigint not null default 1,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default clock_timestamp()
);

create table if not exists public.mt_events (
  game_code   text not null references public.mt_games(code) on delete cascade,
  id          text not null check (length(id) between 1 and 40),
  device_id   text not null default '' check (length(device_id) <= 40),
  data        jsonb not null check (pg_column_size(data) < 4000),
  deleted     boolean not null default false,
  updated_at  timestamptz not null default clock_timestamp(),
  primary key (game_code, id)
);
create index if not exists mt_events_pull_idx on public.mt_events (game_code, updated_at);

create table if not exists public.mt_claims (
  game_code   text not null references public.mt_games(code) on delete cascade,
  device_id   text not null check (length(device_id) between 1 and 40),
  name        text not null default '' check (length(name) <= 40),
  claims      jsonb not null default '{}'::jsonb check (pg_column_size(claims) < 8000),
  updated_at  timestamptz not null default clock_timestamp(),
  primary key (game_code, device_id)
);

alter table public.mt_games  enable row level security;
alter table public.mt_events enable row level security;
alter table public.mt_claims enable row level security;
revoke all on public.mt_games, public.mt_events, public.mt_claims from anon, authenticated;

-- Create a new shared game. Returns false if the code is already taken.
create or replace function public.mt_create_game(p_code text, p_meta jsonb)
returns boolean language plpgsql security definer set search_path = public as $$
begin
  insert into mt_games (code, meta) values (upper(p_code), coalesce(p_meta, '{}'::jsonb));
  return true;
exception when unique_violation then
  return false;
end $$;

-- Replace the game setup (roster, clock, half, names). Returns the new revision number.
create or replace function public.mt_set_meta(p_code text, p_meta jsonb)
returns bigint language sql security definer set search_path = public as $$
  update mt_games
     set meta = coalesce(p_meta, meta), meta_rev = meta_rev + 1, updated_at = clock_timestamp()
   where code = upper(p_code)
  returning meta_rev;
$$;

-- Add or update a batch of events. A deleted event stays deleted.
create or replace function public.mt_push_events(p_code text, p_rows jsonb)
returns integer language plpgsql security definer set search_path = public as $$
declare
  n integer;
begin
  if jsonb_typeof(p_rows) <> 'array' or jsonb_array_length(p_rows) > 500 then
    raise exception 'bad rows';
  end if;
  if not exists (select 1 from mt_games where code = upper(p_code)) then
    raise exception 'no such game';
  end if;
  insert into mt_events (game_code, id, device_id, data, deleted)
  select upper(p_code),
         r->>'id',
         left(coalesce(r->>'device_id', ''), 40),
         r->'data',
         coalesce((r->>'deleted')::boolean, false)
    from jsonb_array_elements(p_rows) r
  on conflict (game_code, id) do update
     set data = excluded.data,
         deleted = mt_events.deleted or excluded.deleted,
         updated_at = clock_timestamp();
  get diagnostics n = row_count;
  return n;
end $$;

-- Save what one phone is tracking. Also works as a heartbeat so others can see who is live.
create or replace function public.mt_set_claim(p_code text, p_device text, p_name text, p_claims jsonb)
returns void language sql security definer set search_path = public as $$
  insert into mt_claims (game_code, device_id, name, claims)
  select g.code, p_device, left(coalesce(p_name, ''), 40), coalesce(p_claims, '{}'::jsonb)
    from mt_games g where g.code = upper(p_code)
  on conflict (game_code, device_id) do update
     set name = excluded.name, claims = excluded.claims, updated_at = clock_timestamp();
$$;

-- Remove one phone from a game.
create or replace function public.mt_leave(p_code text, p_device text)
returns void language sql security definer set search_path = public as $$
  delete from mt_claims where game_code = upper(p_code) and device_id = p_device;
$$;

-- Everything a phone needs in one call: setup, events changed since p_since, and who is tracking what.
-- Returns null if there is no game with that code.
create or replace function public.mt_pull(p_code text, p_since timestamptz default null)
returns jsonb language sql security definer set search_path = public as $$
  select jsonb_build_object(
    'now', clock_timestamp(),
    'meta', g.meta,
    'meta_rev', g.meta_rev,
    'events', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', e.id, 'device_id', e.device_id, 'data', e.data,
               'deleted', e.deleted, 'updated_at', e.updated_at) order by e.updated_at)
        from mt_events e
       where e.game_code = g.code and (p_since is null or e.updated_at > p_since)
    ), '[]'::jsonb),
    'claims', coalesce((
      select jsonb_agg(jsonb_build_object(
               'device_id', c.device_id, 'name', c.name,
               'claims', c.claims, 'updated_at', c.updated_at))
        from mt_claims c
       where c.game_code = g.code
    ), '[]'::jsonb)
  )
  from mt_games g
  where g.code = upper(p_code);
$$;

grant execute on function public.mt_create_game(text, jsonb) to anon, authenticated;
grant execute on function public.mt_set_meta(text, jsonb) to anon, authenticated;
grant execute on function public.mt_push_events(text, jsonb) to anon, authenticated;
grant execute on function public.mt_set_claim(text, text, text, jsonb) to anon, authenticated;
grant execute on function public.mt_leave(text, text) to anon, authenticated;
grant execute on function public.mt_pull(text, timestamptz) to anon, authenticated;

-- Optional housekeeping: run this now and then to clear out old shared games.
-- Each phone keeps its own copy in Past games, so this only removes the shared copy.
-- delete from public.mt_games where created_at < now() - interval '30 days';
