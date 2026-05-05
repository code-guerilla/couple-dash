create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

create table if not exists public.app_admin (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.couple (
  id uuid primary key default extensions.gen_random_uuid(),
  slug text unique not null,
  name text not null,
  subtitle text not null default '',
  relationship_start date not null,
  wedding_date date not null,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create table if not exists public.partner (
  id uuid primary key default extensions.gen_random_uuid(),
  couple_id uuid not null references public.couple(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  slug text not null,
  name text not null,
  role text not null default '',
  accent text not null default 'primary',
  hunger_level text not null default 'full',
  avatar_path text,
  invite_token_hash text,
  created_at timestamptz not null default now(),
  unique (couple_id, slug),
  constraint partner_couple_user_unique unique (couple_id, user_id)
);

create table if not exists public.couple_member (
  couple_id uuid not null references public.couple(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  partner_id uuid references public.partner(id) on delete cascade,
  role text not null check (role in ('partner', 'admin')),
  primary key (couple_id, user_id)
);

create table if not exists public.dashboard_widget (
  id uuid primary key default extensions.gen_random_uuid(),
  couple_id uuid not null references public.couple(id) on delete cascade,
  label text not null,
  value text not null,
  unit text,
  detail text not null default '',
  visual text not null default 'stat' check (visual in ('stat', 'progress', 'radial', 'donut', 'bar', 'line', 'memory', 'timeline')),
  sort_order integer not null default 0,
  min_value numeric,
  max_value numeric,
  numeric_value numeric,
  tone text not null default 'info' check (tone in ('info', 'success', 'warning', 'error')),
  visible boolean not null default true,
  timeline_entries jsonb not null default '[]'::jsonb,
  chart_data jsonb not null default '[]'::jsonb,
  chart_options jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.couple_alert (
  id uuid primary key default extensions.gen_random_uuid(),
  couple_id uuid not null references public.couple(id) on delete cascade,
  title text not null,
  detail text not null default '',
  severity text not null default 'info' check (severity in ('info', 'success', 'warning', 'error')),
  source text not null default 'system' check (source in ('system', 'partner')),
  active boolean not null default true,
  triggered_by_partner_id uuid references public.partner(id) on delete set null,
  triggered_by text,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (date_trunc('day', now()) + interval '1 day')
);

alter table public.couple add column if not exists created_by uuid references auth.users(id);
alter table public.couple drop column if exists anniversary_date;
alter table public.partner add column if not exists user_id uuid references auth.users(id) on delete set null;
alter table public.partner add column if not exists hunger_level text not null default 'full';
alter table public.partner alter column hunger_level set default 'full';
update public.partner set hunger_level = 'full' where hunger_level is null;
alter table public.partner alter column hunger_level set not null;
alter table public.partner add column if not exists avatar_path text;
alter table public.partner add column if not exists invite_token_hash text;
alter table public.dashboard_widget add column if not exists visible boolean not null default true;
alter table public.dashboard_widget add column if not exists timeline_entries jsonb not null default '[]'::jsonb;
alter table public.dashboard_widget add column if not exists chart_data jsonb not null default '[]'::jsonb;
alter table public.dashboard_widget add column if not exists chart_options jsonb not null default '{}'::jsonb;
alter table public.couple_alert add column if not exists triggered_by_partner_id uuid references public.partner(id) on delete set null;
alter table public.couple_alert add column if not exists expires_at timestamptz not null default (date_trunc('day', now()) + interval '1 day');
alter table public.dashboard_widget drop constraint if exists dashboard_widget_visual_check;
alter table public.dashboard_widget drop constraint if exists dashboard_widget_scope_person_check;
drop policy if exists "Members update shared widgets" on public.dashboard_widget;
drop policy if exists "Members update own person widgets" on public.dashboard_widget;
drop policy if exists "Members manage shared dashboard widgets" on public.dashboard_widget;
drop trigger if exists validate_dashboard_widget_person_trigger on public.dashboard_widget;
drop function if exists public.validate_dashboard_widget_person();
drop function if exists public.is_current_partner_for_widget(uuid, uuid);
drop index if exists dashboard_widget_person_id_idx;

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'dashboard_widget'
      and column_name = 'scope'
  ) then
    execute 'update public.dashboard_widget set scope = ''shared'', person_id = null where scope is distinct from ''shared'' or person_id is not null';
  end if;
end $$;

with resolved_alert_partner as (
  select
    alert.id as alert_id,
    partner.id as partner_id,
    partner.name as partner_name
  from public.couple_alert alert
  join lateral (
    select candidate.id, candidate.name
    from public.partner candidate
    where candidate.couple_id = alert.couple_id
    order by
      case
        when alert.triggered_by is not null
          and lower(trim(candidate.name)) = lower(trim(alert.triggered_by)) then 0
        else 1
      end,
      candidate.created_at
    limit 1
  ) partner on true
  where alert.source = 'partner'
    and alert.triggered_by_partner_id is null
)
update public.couple_alert alert
set triggered_by_partner_id = resolved_alert_partner.partner_id,
    triggered_by = coalesce(nullif(alert.triggered_by, ''), resolved_alert_partner.partner_name)
from resolved_alert_partner
where alert.id = resolved_alert_partner.alert_id;

alter table public.dashboard_widget drop column if exists person_id;
alter table public.dashboard_widget drop column if exists scope;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'partner_accent_check'
      and conrelid = 'public.partner'::regclass
  ) then
    alter table public.partner
      add constraint partner_accent_check
      check (accent in ('primary', 'secondary', 'accent', 'info', 'success', 'warning', 'error'));
  end if;
end $$;

alter table public.partner drop constraint if exists partner_hunger_level_check;
alter table public.partner
  add constraint partner_hunger_level_check
  check (hunger_level in ('full', 'snack', 'getting-hungry', 'need-food', 'starving', 'critical'));

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'partner_couple_user_unique'
      and conrelid = 'public.partner'::regclass
  ) then
    alter table public.partner
      add constraint partner_couple_user_unique
      unique (couple_id, user_id);
  end if;
end $$;

alter table public.dashboard_widget
  add constraint dashboard_widget_visual_check
  check (visual in ('stat', 'progress', 'radial', 'donut', 'bar', 'line', 'memory', 'timeline'));

create index if not exists couple_slug_idx on public.couple (slug);
create index if not exists partner_couple_id_idx on public.partner (couple_id);
create index if not exists partner_user_id_idx on public.partner (user_id);
create index if not exists partner_avatar_path_idx on public.partner (avatar_path) where avatar_path is not null;
create index if not exists couple_member_user_id_idx on public.couple_member (user_id);
create index if not exists couple_member_couple_id_idx on public.couple_member (couple_id);
create index if not exists dashboard_widget_couple_sort_idx on public.dashboard_widget (couple_id, sort_order);
create index if not exists couple_alert_couple_active_created_idx
  on public.couple_alert (couple_id, active, created_at desc);
create index if not exists couple_alert_triggered_by_partner_id_idx
  on public.couple_alert (triggered_by_partner_id);

create or replace function public.is_app_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as '
  select auth.uid() is not null
    and exists (
      select 1
      from public.app_admin admin
      where admin.user_id = auth.uid()
    );
';

create or replace function public.is_couple_member(p_couple_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as '
  select public.is_app_admin()
    or (
      auth.uid() is not null
      and exists (
        select 1
        from public.couple_member member
        where member.couple_id = p_couple_id
          and member.user_id = auth.uid()
      )
    );
';

create or replace function public.accept_partner_invite(
  p_slug text,
  p_partner_slug text,
  p_invite_token text
) returns table (accepted_partner_id uuid, accepted_couple_id uuid)
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_partner public.partner%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  select partner.*
    into target_partner
  from public.partner partner
  join public.couple couple on couple.id = partner.couple_id
  where couple.slug = p_slug
    and partner.slug = p_partner_slug;

  if target_partner.id is null
    or target_partner.invite_token_hash is null
    or extensions.crypt(p_invite_token, target_partner.invite_token_hash) <> target_partner.invite_token_hash then
    raise exception 'Invalid partner invite';
  end if;

  if target_partner.user_id is not null and target_partner.user_id <> auth.uid() then
    raise exception 'Partner invite already accepted';
  end if;

  update public.partner
    set user_id = auth.uid(),
        invite_token_hash = null
  where id = target_partner.id;

  insert into public.couple_member (couple_id, user_id, partner_id, role)
  values (target_partner.couple_id, auth.uid(), target_partner.id, 'partner')
  on conflict (couple_id, user_id) do update
    set partner_id = excluded.partner_id,
        role = 'partner';

  accepted_partner_id := target_partner.id;
  accepted_couple_id := target_partner.couple_id;
  return next;
end;
$$;

drop function if exists public.list_my_couples();
drop function if exists public.admin_list_tenants();
drop function if exists public.admin_create_tenant(text, text, text, date, date, date, text, text, text, text);
drop function if exists public.admin_update_tenant(uuid, text, text, text, date, date, date, uuid, text, text, uuid, text, text);
drop function if exists public.admin_get_tenant(uuid);
drop function if exists public.update_partner_avatar(uuid, text);
drop function if exists public.update_partner_hunger_level(uuid, text);

create or replace function public.list_my_couples()
returns table (
  couple_id uuid,
  slug text,
  name text,
  subtitle text,
  relationship_start date,
  wedding_date date,
  partner_count bigint,
  accepted_partner_count bigint
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    couple.id,
    couple.slug,
    couple.name,
    couple.subtitle,
    couple.relationship_start,
    couple.wedding_date,
    count(distinct partner.id) as partner_count,
    count(distinct partner.id) filter (where partner.user_id is not null) as accepted_partner_count
  from public.couple_member member
  join public.couple couple on couple.id = member.couple_id
  left join public.partner partner on partner.couple_id = couple.id
  where auth.uid() is not null
    and member.user_id = auth.uid()
  group by couple.id
  order by couple.created_at desc;
$$;

create or replace function public.get_couple_invite_status(p_couple_id uuid)
returns table (
  partner_count bigint,
  accepted_partner_count bigint,
  pending_partner_id uuid,
  pending_partner_name text
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    count(partner.id) as partner_count,
    count(partner.id) filter (where partner.user_id is not null) as accepted_partner_count,
    (array_agg(partner.id order by partner.created_at) filter (where partner.user_id is null))[1] as pending_partner_id,
    (array_agg(partner.name order by partner.created_at) filter (where partner.user_id is null))[1] as pending_partner_name
  from public.partner partner
  where partner.couple_id = p_couple_id
    and public.is_couple_member(p_couple_id);
$$;

create or replace function public.create_pending_partner_invite(p_couple_id uuid)
returns table (
  couple_slug text,
  partner_slug text,
  partner_name text,
  invite_token text
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_partner public.partner%rowtype;
  target_couple_slug text;
  next_invite_token text := encode(extensions.gen_random_bytes(18), 'hex');
begin
  if not public.is_couple_member(p_couple_id) then
    raise exception 'Not allowed';
  end if;

  select partner.*
    into target_partner
  from public.partner partner
  where partner.couple_id = p_couple_id
    and partner.user_id is null
  order by partner.created_at
  limit 1;

  if target_partner.id is null then
    raise exception 'No pending partner invite';
  end if;

  select couple.slug
    into target_couple_slug
  from public.couple couple
  where couple.id = p_couple_id;

  update public.partner
    set invite_token_hash = extensions.crypt(next_invite_token, extensions.gen_salt('bf'))
  where id = target_partner.id;

  couple_slug := target_couple_slug;
  partner_slug := target_partner.slug;
  partner_name := target_partner.name;
  invite_token := next_invite_token;
  return next;
end;
$$;

create or replace function public.admin_list_tenants()
returns table (
  couple_id uuid,
  slug text,
  name text,
  subtitle text,
  relationship_start date,
  wedding_date date,
  partner_count bigint,
  accepted_partner_count bigint,
  widget_count bigint,
  active_alert_count bigint,
  created_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    couple.id,
    couple.slug,
    couple.name,
    couple.subtitle,
    couple.relationship_start,
    couple.wedding_date,
    count(distinct partner.id) as partner_count,
    count(distinct partner.id) filter (where partner.user_id is not null) as accepted_partner_count,
    count(distinct widget.id) as widget_count,
    count(distinct alert.id) filter (where alert.active = true) as active_alert_count,
    couple.created_at
  from public.couple couple
  left join public.partner partner on partner.couple_id = couple.id
  left join public.dashboard_widget widget on widget.couple_id = couple.id
  left join public.couple_alert alert on alert.couple_id = couple.id
  where public.is_app_admin()
  group by couple.id
  order by couple.created_at desc;
$$;

create or replace function public.admin_create_tenant(
  p_slug text,
  p_name text,
  p_subtitle text,
  p_relationship_start date,
  p_wedding_date date,
  p_partner_a_name text,
  p_partner_a_slug text,
  p_partner_b_name text,
  p_partner_b_slug text
) returns table (
  couple_id uuid,
  slug text,
  partner_a_slug text,
  partner_a_invite_token text,
  partner_b_slug text,
  partner_b_invite_token text
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  new_couple_id uuid;
  normalized_slug text := lower(regexp_replace(trim(p_slug), '[^a-zA-Z0-9]+', '-', 'g'));
  normalized_partner_a_slug text := lower(regexp_replace(trim(p_partner_a_slug), '[^a-zA-Z0-9]+', '-', 'g'));
  normalized_partner_b_slug text := lower(regexp_replace(trim(p_partner_b_slug), '[^a-zA-Z0-9]+', '-', 'g'));
  next_partner_a_token text := encode(extensions.gen_random_bytes(18), 'hex');
  next_partner_b_token text := encode(extensions.gen_random_bytes(18), 'hex');
  partner_a_id uuid;
  partner_b_id uuid;
begin
  if not public.is_app_admin() then
    raise exception 'Not allowed';
  end if;

  normalized_slug := trim(both '-' from normalized_slug);
  normalized_partner_a_slug := trim(both '-' from normalized_partner_a_slug);
  normalized_partner_b_slug := trim(both '-' from normalized_partner_b_slug);

  if normalized_slug = '' then
    raise exception 'Tenant slug is required';
  end if;

  if normalized_partner_a_slug = '' or normalized_partner_b_slug = '' then
    raise exception 'Partner slugs are required';
  end if;

  if normalized_partner_a_slug = normalized_partner_b_slug then
    raise exception 'Partner slugs must be different';
  end if;

  insert into public.couple (
    slug,
    name,
    subtitle,
    relationship_start,
    wedding_date,
    created_by
  ) values (
    normalized_slug,
    trim(p_name),
    coalesce(trim(p_subtitle), ''),
    p_relationship_start,
    p_wedding_date,
    auth.uid()
  )
  returning id into new_couple_id;

  insert into public.partner (couple_id, slug, name, role, accent, invite_token_hash)
  values (
    new_couple_id,
    normalized_partner_a_slug,
    trim(p_partner_a_name),
    'Partner',
    'primary',
    extensions.crypt(next_partner_a_token, extensions.gen_salt('bf'))
  )
  returning id into partner_a_id;

  insert into public.partner (couple_id, slug, name, role, accent, invite_token_hash)
  values (
    new_couple_id,
    normalized_partner_b_slug,
    trim(p_partner_b_name),
    'Partner',
    'secondary',
    extensions.crypt(next_partner_b_token, extensions.gen_salt('bf'))
  )
  returning id into partner_b_id;

  insert into public.dashboard_widget (
    couple_id,
    label,
    value,
    detail,
    visual,
    sort_order,
    max_value,
    numeric_value,
    tone,
    timeline_entries,
    chart_data,
    chart_options
  ) values
    (
      new_couple_id,
      'Our Timeline',
      '2 milestones',
      'The relationship milestones that make the dashboard personal.',
      'timeline',
      1,
      null,
      null,
      'success',
      jsonb_build_array(
        jsonb_build_object('id', 'first-met', 'date', p_relationship_start, 'title', 'First Met', 'description', 'The first chapter of the story.', 'icon', 'i-lucide-sparkles'),
        jsonb_build_object('id', 'wedding', 'date', p_wedding_date, 'title', 'The Wedding', 'description', 'The big day on the shared calendar.', 'icon', 'i-lucide-church')
      ),
      '[]'::jsonb,
      '{}'::jsonb
    ),
    (new_couple_id, 'Woraus die Beziehung besteht', '100%', 'Liebe, Kaffee und Essensdiskussionen in einem wissenschaftlich fragwürdigen Mix.', 'donut', 2, null, null, 'success', '[]'::jsonb, jsonb_build_array(jsonb_build_object('label', 'Liebe', 'value', 40), jsonb_build_object('label', 'Kaffee', 'value', 20), jsonb_build_object('label', 'Diskussionen über Essen', 'value', 25), jsonb_build_object('label', 'Gemeinsame Serien', 'value', 15)), jsonb_build_object('centralLabel', 'Beziehungs-Mix', 'centralSubLabel', 'wissenschaftlich fragwürdig')),
    (new_couple_id, 'Gewonnene Diskussionen', '75%', 'Beide tun so, als hätten sie gewonnen.', 'donut', 3, null, null, 'warning', '[]'::jsonb, jsonb_build_array(jsonb_build_object('label', 'Partner A', 'value', 12), jsonb_build_object('label', 'Partner B', 'value', 13), jsonb_build_object('label', 'Beide gewonnen', 'value', 75)), jsonb_build_object('centralLabel', '75%', 'centralSubLabel', 'diplomatischer Sieg')),
    (new_couple_id, 'Top Beziehungsthemen', '87', 'Ranking der wichtigsten Haushaltskonferenzen.', 'bar', 4, null, null, 'info', '[]'::jsonb, jsonb_build_array(jsonb_build_object('label', 'Was essen wir?', 'value', 87), jsonb_build_object('label', 'Wo sind die Schlüssel?', 'value', 42), jsonb_build_object('label', 'Noch eine Folge?', 'value', 64)), '{}'::jsonb),
    (new_couple_id, 'Romantik im Zeitverlauf', '100', 'Fake Trend, echte Gefühle.', 'line', 5, null, null, 'success', '[]'::jsonb, jsonb_build_array(jsonb_build_object('label', 'Kennenlernen', 'value', 80), jsonb_build_object('label', 'Erster Urlaub', 'value', 95), jsonb_build_object('label', 'Umzug', 'value', 62), jsonb_build_object('label', 'Hochzeit', 'value', 100)), '{}'::jsonb);

  insert into public.couple_alert (couple_id, title, detail, severity, source)
  values (
    new_couple_id,
    'Dashboard created',
    'Invite both partners, then open the display with either linked partner account.',
    'success',
    'system'
  );

  couple_id := new_couple_id;
  slug := normalized_slug;
  partner_a_slug := normalized_partner_a_slug;
  partner_a_invite_token := next_partner_a_token;
  partner_b_slug := normalized_partner_b_slug;
  partner_b_invite_token := next_partner_b_token;
  return next;
end;
$$;

create or replace function public.update_partner_avatar(
  p_partner_id uuid,
  p_avatar_path text
) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_partner public.partner%rowtype;
  expected_prefix text;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  select partner.*
    into target_partner
  from public.partner partner
  join public.couple_member member
    on member.couple_id = partner.couple_id
   and member.partner_id = partner.id
   and member.user_id = auth.uid()
  where partner.id = p_partner_id;

  if target_partner.id is null then
    raise exception 'Not allowed';
  end if;

  expected_prefix := target_partner.couple_id::text || '/' || target_partner.id::text || '/';

  if p_avatar_path is not null and p_avatar_path not like expected_prefix || '%' then
    raise exception 'Invalid avatar path';
  end if;

  update public.partner
    set avatar_path = p_avatar_path
  where id = target_partner.id;
end;
$$;

create or replace function public.update_partner_hunger_level(
  p_partner_id uuid,
  p_hunger_level text
) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_partner public.partner%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  if p_hunger_level not in ('full', 'snack', 'getting-hungry', 'need-food', 'starving', 'critical') then
    raise exception 'Invalid hunger level';
  end if;

  select partner.*
    into target_partner
  from public.partner partner
  where partner.id = p_partner_id
    and public.is_couple_member(partner.couple_id);

  if target_partner.id is null then
    raise exception 'Not allowed';
  end if;

  update public.partner
    set hunger_level = p_hunger_level
  where id = target_partner.id;
end;
$$;

create or replace function public.admin_get_tenant(p_couple_id uuid)
returns table (
  couple_id uuid,
  slug text,
  name text,
  subtitle text,
  relationship_start date,
  wedding_date date,
  partners jsonb
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    couple.id,
    couple.slug,
    couple.name,
    couple.subtitle,
    couple.relationship_start,
    couple.wedding_date,
    coalesce(
      jsonb_agg(
        jsonb_build_object(
          'id', partner.id,
          'slug', partner.slug,
          'name', partner.name,
          'role', partner.role,
          'accent', partner.accent,
          'hunger_level', partner.hunger_level,
          'avatar_path', partner.avatar_path,
          'accepted', partner.user_id is not null
        )
        order by partner.created_at
      ) filter (where partner.id is not null),
      '[]'::jsonb
    ) as partners
  from public.couple couple
  left join public.partner partner on partner.couple_id = couple.id
  where public.is_app_admin()
    and couple.id = p_couple_id
  group by couple.id;
$$;

create or replace function public.admin_update_tenant(
  p_couple_id uuid,
  p_slug text,
  p_name text,
  p_subtitle text,
  p_relationship_start date,
  p_wedding_date date,
  p_partner_a_id uuid,
  p_partner_a_name text,
  p_partner_a_slug text,
  p_partner_b_id uuid,
  p_partner_b_name text,
  p_partner_b_slug text
) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  normalized_slug text := lower(regexp_replace(trim(p_slug), '[^a-zA-Z0-9]+', '-', 'g'));
  normalized_partner_a_slug text := lower(regexp_replace(trim(p_partner_a_slug), '[^a-zA-Z0-9]+', '-', 'g'));
  normalized_partner_b_slug text := lower(regexp_replace(trim(p_partner_b_slug), '[^a-zA-Z0-9]+', '-', 'g'));
begin
  if not public.is_app_admin() then
    raise exception 'Not allowed';
  end if;

  normalized_slug := trim(both '-' from normalized_slug);
  normalized_partner_a_slug := trim(both '-' from normalized_partner_a_slug);
  normalized_partner_b_slug := trim(both '-' from normalized_partner_b_slug);

  if normalized_slug = '' then
    raise exception 'Tenant slug is required';
  end if;

  if normalized_partner_a_slug = '' or normalized_partner_b_slug = '' then
    raise exception 'Partner slugs are required';
  end if;

  if normalized_partner_a_slug = normalized_partner_b_slug then
    raise exception 'Partner slugs must be different';
  end if;

  update public.couple
    set slug = normalized_slug,
        name = trim(p_name),
        subtitle = coalesce(trim(p_subtitle), ''),
        relationship_start = p_relationship_start,
        wedding_date = p_wedding_date
  where id = p_couple_id;

  if not found then
    raise exception 'Tenant not found';
  end if;

  update public.partner
    set name = trim(p_partner_a_name),
        slug = normalized_partner_a_slug
  where id = p_partner_a_id
    and couple_id = p_couple_id;

  update public.partner
    set name = trim(p_partner_b_name),
        slug = normalized_partner_b_slug
  where id = p_partner_b_id
    and couple_id = p_couple_id;
end;
$$;

create or replace function public.admin_regenerate_tenant_credentials(p_couple_id uuid)
returns table (
  couple_id uuid,
  slug text,
  partner_a_slug text,
  partner_a_invite_token text,
  partner_b_slug text,
  partner_b_invite_token text
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_couple public.couple%rowtype;
  first_partner public.partner%rowtype;
  second_partner public.partner%rowtype;
  next_partner_a_token text := encode(extensions.gen_random_bytes(18), 'hex');
  next_partner_b_token text := encode(extensions.gen_random_bytes(18), 'hex');
begin
  if not public.is_app_admin() then
    raise exception 'Not allowed';
  end if;

  select *
    into target_couple
  from public.couple couple
  where couple.id = p_couple_id;

  if target_couple.id is null then
    raise exception 'Tenant not found';
  end if;

  select *
    into first_partner
  from public.partner partner
  where partner.couple_id = p_couple_id
  order by partner.created_at
  limit 1;

  select *
    into second_partner
  from public.partner partner
  where partner.couple_id = p_couple_id
    and partner.id <> first_partner.id
  order by partner.created_at
  limit 1;

  if first_partner.id is null or second_partner.id is null then
    raise exception 'Tenant needs two partners before credentials can be generated';
  end if;

  update public.partner
    set invite_token_hash = extensions.crypt(next_partner_a_token, extensions.gen_salt('bf'))
  where id = first_partner.id;

  update public.partner
    set invite_token_hash = extensions.crypt(next_partner_b_token, extensions.gen_salt('bf'))
  where id = second_partner.id;

  couple_id := target_couple.id;
  slug := target_couple.slug;
  partner_a_slug := first_partner.slug;
  partner_a_invite_token := next_partner_a_token;
  partner_b_slug := second_partner.slug;
  partner_b_invite_token := next_partner_b_token;
  return next;
end;
$$;

create or replace function public.admin_delete_tenant(p_couple_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_app_admin() then
    raise exception 'Not allowed';
  end if;

  delete from public.couple
  where id = p_couple_id;

  if not found then
    raise exception 'Tenant not found';
  end if;
end;
$$;

drop function if exists public.update_dashboard_widget(uuid, text, text, text, text, text, text, numeric, jsonb);
drop function if exists public.update_dashboard_widget(uuid, text, text, text, text, text, text, numeric, jsonb, jsonb, jsonb);
drop function if exists public.add_dashboard_widget(uuid, text, text, text, text, text, uuid, text, integer, numeric, numeric, numeric, text);
drop function if exists public.add_dashboard_widget(uuid, text, text, text, text, text, uuid, text, integer, numeric, numeric, numeric, text, jsonb, jsonb, jsonb);
drop function if exists public.add_dashboard_widget(uuid, text, text, text, text, integer, numeric, numeric, numeric, text, jsonb, jsonb, jsonb);
drop function if exists public.delete_dashboard_widget(uuid);

create or replace function public.update_dashboard_widget(
  p_widget_id uuid,
  p_label text default null,
  p_value text default null,
  p_unit text default null,
  p_detail text default null,
  p_visual text default null,
  p_tone text default null,
  p_numeric_value numeric default null,
  p_timeline_entries jsonb default null,
  p_chart_data jsonb default null,
  p_chart_options jsonb default null
) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_widget public.dashboard_widget%rowtype;
begin
  select *
    into target_widget
  from public.dashboard_widget widget
  where widget.id = p_widget_id;

  if target_widget.id is null then
    raise exception 'Widget not found';
  end if;

  if not public.is_app_admin() and not public.is_couple_member(target_widget.couple_id) then
    raise exception 'Not allowed';
  end if;

  update public.dashboard_widget
    set label = coalesce(p_label, label),
        value = coalesce(p_value, value),
        unit = p_unit,
        detail = coalesce(p_detail, detail),
        visual = coalesce(p_visual, visual),
        tone = coalesce(p_tone, tone),
        numeric_value = p_numeric_value,
        timeline_entries = coalesce(p_timeline_entries, timeline_entries),
        chart_data = coalesce(p_chart_data, chart_data),
        chart_options = coalesce(p_chart_options, chart_options),
        updated_at = now()
  where id = p_widget_id;
end;
$$;

create or replace function public.add_dashboard_widget(
  p_couple_id uuid,
  p_label text,
  p_value text default '',
  p_unit text default null,
  p_detail text default '',
  p_visual text default 'stat',
  p_sort_order integer default 0,
  p_min_value numeric default null,
  p_max_value numeric default null,
  p_numeric_value numeric default null,
  p_tone text default 'info',
  p_timeline_entries jsonb default null,
  p_chart_data jsonb default null,
  p_chart_options jsonb default null
) returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  new_id uuid;
begin
  if not public.is_app_admin() and not public.is_couple_member(p_couple_id) then
    raise exception 'Not allowed';
  end if;

  insert into public.dashboard_widget (
    couple_id,
    label,
    value,
    unit,
    detail,
    visual,
    sort_order,
    min_value,
    max_value,
    numeric_value,
    tone,
    timeline_entries,
    chart_data,
    chart_options
  ) values (
    p_couple_id,
    p_label,
    p_value,
    p_unit,
    coalesce(p_detail, ''),
    coalesce(p_visual, 'stat'),
    coalesce(p_sort_order, 0),
    p_min_value,
    p_max_value,
    p_numeric_value,
    coalesce(p_tone, 'info'),
    coalesce(p_timeline_entries, '[]'::jsonb),
    coalesce(p_chart_data, '[]'::jsonb),
    coalesce(p_chart_options, '{}'::jsonb)
  )
  returning id into new_id;

  return new_id;
end;
$$;

create or replace function public.delete_dashboard_widget(p_widget_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_widget public.dashboard_widget%rowtype;
begin
  select *
    into target_widget
  from public.dashboard_widget widget
  where widget.id = p_widget_id;

  if target_widget.id is null then
    raise exception 'Widget not found';
  end if;

  if not public.is_app_admin() and not public.is_couple_member(target_widget.couple_id) then
    raise exception 'Not allowed';
  end if;

  delete from public.dashboard_widget
  where id = p_widget_id;
end;
$$;

create or replace function public.set_widget_visible(p_widget_id uuid, p_visible boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_widget public.dashboard_widget%rowtype;
begin
  select *
    into target_widget
  from public.dashboard_widget widget
  where widget.id = p_widget_id;

  if target_widget.id is null then
    raise exception 'Widget not found';
  end if;

  if not public.is_app_admin() and not public.is_couple_member(target_widget.couple_id) then
    raise exception 'Not allowed';
  end if;

  update public.dashboard_widget
    set visible = p_visible,
        updated_at = now()
  where id = p_widget_id;
end;
$$;

create or replace function public.set_alert_active(p_alert_id uuid, p_active boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_alert public.couple_alert%rowtype;
  current_partner_id uuid;
begin
  select *
    into target_alert
  from public.couple_alert alert
  where alert.id = p_alert_id;

  if target_alert.id is null then
    raise exception 'Alert not found';
  end if;

  if public.is_app_admin() then
    update public.couple_alert
      set active = p_active
    where id = p_alert_id;
    return;
  end if;

  select member.partner_id
    into current_partner_id
  from public.couple_member member
  where member.couple_id = target_alert.couple_id
    and member.user_id = auth.uid();

  if target_alert.source <> 'partner'
    or target_alert.triggered_by_partner_id is distinct from current_partner_id then
    raise exception 'Not allowed';
  end if;

  update public.couple_alert
    set active = p_active
  where id = p_alert_id;
end;
$$;

drop function if exists public.trigger_couple_alert(uuid, text, text, text, text, text);
drop function if exists public.trigger_couple_alert(uuid, text, text, text, text, text, timestamptz);
drop function if exists public.trigger_couple_alert(uuid, text, text, text, text, text, timestamptz, uuid);

create or replace function public.trigger_couple_alert(
  p_couple_id uuid,
  p_title text,
  p_detail text,
  p_severity text,
  p_source text default 'partner',
  p_triggered_by text default null,
  p_expires_at timestamptz default null,
  p_triggered_by_partner_id uuid default null
) returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  new_id uuid;
  next_source text := coalesce(p_source, 'partner');
  current_partner_id uuid;
  current_partner_name text;
begin
  if public.is_app_admin() and next_source = 'system' then
    next_source := coalesce(p_source, 'system');
  elsif next_source = 'partner' then
    select member.partner_id, partner.name
      into current_partner_id, current_partner_name
    from public.couple_member member
    left join public.partner partner on partner.id = member.partner_id
    where member.couple_id = p_couple_id
      and member.user_id = auth.uid();

    if current_partner_id is null
      or (p_triggered_by_partner_id is not null and p_triggered_by_partner_id <> current_partner_id) then
      raise exception 'Not allowed';
    end if;

    next_source := 'partner';
  else
    raise exception 'Not allowed';
  end if;

  if next_source not in ('system', 'partner') then
    raise exception 'Invalid alert source';
  end if;

  insert into public.couple_alert (
    couple_id,
    title,
    detail,
    severity,
    source,
    triggered_by_partner_id,
    triggered_by,
    expires_at
  )
  values (
    p_couple_id,
    p_title,
    coalesce(p_detail, ''),
    coalesce(p_severity, 'info'),
    next_source,
    case when next_source = 'partner' then current_partner_id else null end,
    case when next_source = 'partner' then coalesce(p_triggered_by, current_partner_name) else null end,
    coalesce(p_expires_at, date_trunc('day', now()) + interval '1 day')
  )
  returning id into new_id;

  return new_id;
end;
$$;

alter table public.app_admin enable row level security;
alter table public.couple enable row level security;
alter table public.partner enable row level security;
alter table public.couple_member enable row level security;
alter table public.dashboard_widget enable row level security;
alter table public.couple_alert enable row level security;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'partner-avatars',
  'partner-avatars',
  false,
  2097152,
  array['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = false,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "App admins view app admins" on public.app_admin;
drop policy if exists "App admin view app_admin" on public.app_admin;
drop policy if exists "App admins manage app admins" on public.app_admin;
drop policy if exists "App admin manage app_admin" on public.app_admin;
drop policy if exists "Couple visible to member and admin" on public.couple;
drop policy if exists "App admin manage couple" on public.couple;
drop policy if exists "Partner visible to member and admin" on public.partner;
drop policy if exists "App admin manage partner" on public.partner;
drop policy if exists "Members view couple memberships" on public.couple_member;
drop policy if exists "Couple member visible to member" on public.couple_member;
drop policy if exists "App admins manage couple memberships" on public.couple_member;
drop policy if exists "App admin manage couple_member" on public.couple_member;
drop policy if exists "Widgets are visible to members" on public.dashboard_widget;
drop policy if exists "Members update shared widgets" on public.dashboard_widget;
drop policy if exists "Members update own person widgets" on public.dashboard_widget;
drop policy if exists "Members manage shared dashboard widgets" on public.dashboard_widget;
drop policy if exists "App admins manage widgets" on public.dashboard_widget;
drop policy if exists "Alerts are visible to members" on public.couple_alert;
drop policy if exists "Members create partner alerts" on public.couple_alert;
drop policy if exists "App admins manage alerts" on public.couple_alert;
drop policy if exists "Members read partner avatars" on storage.objects;
drop policy if exists "Partners upload own avatars" on storage.objects;
drop policy if exists "Partners update own avatars" on storage.objects;
drop policy if exists "Partners delete own avatars" on storage.objects;

create policy "App admin view app_admin"
on public.app_admin for select
to authenticated
using (public.is_app_admin());

create policy "App admin manage app_admin"
on public.app_admin for all
to authenticated
using (public.is_app_admin())
with check (public.is_app_admin());

create policy "Couple visible to member and admin"
on public.couple for select
to authenticated
using (public.is_couple_member(id));

create policy "App admin manage couple"
on public.couple for all
to authenticated
using (public.is_app_admin())
with check (public.is_app_admin());

create policy "Partner visible to member and admin"
on public.partner for select
to authenticated
using (public.is_couple_member(couple_id));

create policy "App admin manage partner"
on public.partner for all
to authenticated
using (public.is_app_admin())
with check (public.is_app_admin());

create policy "Couple member visible to member"
on public.couple_member for select
to authenticated
using (public.is_couple_member(couple_id));

create policy "App admin manage couple_member"
on public.couple_member for all
to authenticated
using (public.is_app_admin())
with check (public.is_app_admin());

create policy "Widgets are visible to members"
on public.dashboard_widget for select
to authenticated
using (public.is_couple_member(couple_id));

create policy "Members manage shared dashboard widgets"
on public.dashboard_widget for all
to authenticated
using (public.is_couple_member(couple_id))
with check (public.is_couple_member(couple_id));

create policy "App admins manage widgets"
on public.dashboard_widget for all
to authenticated
using (public.is_app_admin())
with check (public.is_app_admin());

create policy "Alerts are visible to members"
on public.couple_alert for select
to authenticated
using (public.is_couple_member(couple_id));

create policy "Members create partner alerts"
on public.couple_alert for insert
to authenticated
with check (
  source = 'partner'
  and public.is_couple_member(couple_id)
  and triggered_by_partner_id in (
    select member.partner_id
    from public.couple_member member
    where member.couple_id = couple_alert.couple_id
      and member.user_id = auth.uid()
  )
);

create policy "App admins manage alerts"
on public.couple_alert for all
to authenticated
using (public.is_app_admin())
with check (public.is_app_admin());

create policy "Members read partner avatars"
on storage.objects for select
to authenticated
using (
  bucket_id = 'partner-avatars'
  and exists (
    select 1
    from public.couple_member member
    where member.couple_id::text = (storage.foldername(name))[1]
      and member.user_id = auth.uid()
  )
);

create policy "Partners upload own avatars"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'partner-avatars'
  and exists (
    select 1
    from public.couple_member member
    where member.couple_id::text = (storage.foldername(name))[1]
      and member.partner_id::text = (storage.foldername(name))[2]
      and member.user_id = auth.uid()
  )
);

create policy "Partners update own avatars"
on storage.objects for update
to authenticated
using (
  bucket_id = 'partner-avatars'
  and exists (
    select 1
    from public.couple_member member
    where member.couple_id::text = (storage.foldername(name))[1]
      and member.partner_id::text = (storage.foldername(name))[2]
      and member.user_id = auth.uid()
  )
)
with check (
  bucket_id = 'partner-avatars'
  and exists (
    select 1
    from public.couple_member member
    where member.couple_id::text = (storage.foldername(name))[1]
      and member.partner_id::text = (storage.foldername(name))[2]
      and member.user_id = auth.uid()
  )
);

create policy "Partners delete own avatars"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'partner-avatars'
  and exists (
    select 1
    from public.couple_member member
    where member.couple_id::text = (storage.foldername(name))[1]
      and member.partner_id::text = (storage.foldername(name))[2]
      and member.user_id = auth.uid()
  )
);

revoke all on all tables in schema public from anon, authenticated;
revoke all on all functions in schema public from anon, authenticated;
grant usage on schema public to authenticated;

grant select (user_id, created_at) on public.app_admin to authenticated;
grant insert, update, delete on public.app_admin to authenticated;
grant select (id, slug, name, subtitle, relationship_start, wedding_date, created_at)
  on public.couple to authenticated;
grant insert, update, delete on public.couple to authenticated;
grant select (id, couple_id, slug, name, role, accent, hunger_level, avatar_path, created_at)
  on public.partner to authenticated;
grant insert, update, delete on public.partner to authenticated;
grant select, insert, update, delete on public.couple_member to authenticated;
grant select, insert, update, delete on public.dashboard_widget to authenticated;
grant select, insert, update, delete on public.couple_alert to authenticated;

grant execute on function public.is_app_admin() to authenticated;
grant execute on function public.is_couple_member(uuid) to authenticated;
grant execute on function public.accept_partner_invite(text, text, text) to authenticated;
grant execute on function public.list_my_couples() to authenticated;
grant execute on function public.get_couple_invite_status(uuid) to authenticated;
grant execute on function public.create_pending_partner_invite(uuid) to authenticated;
grant execute on function public.update_partner_avatar(uuid, text) to authenticated;
grant execute on function public.update_partner_hunger_level(uuid, text) to authenticated;
grant execute on function public.admin_list_tenants() to authenticated;
grant execute on function public.admin_create_tenant(text, text, text, date, date, text, text, text, text) to authenticated;
grant execute on function public.admin_get_tenant(uuid) to authenticated;
grant execute on function public.admin_update_tenant(uuid, text, text, text, date, date, uuid, text, text, uuid, text, text) to authenticated;
grant execute on function public.admin_regenerate_tenant_credentials(uuid) to authenticated;
grant execute on function public.admin_delete_tenant(uuid) to authenticated;
grant execute on function public.update_dashboard_widget(uuid, text, text, text, text, text, text, numeric, jsonb, jsonb, jsonb) to authenticated;
grant execute on function public.add_dashboard_widget(uuid, text, text, text, text, text, integer, numeric, numeric, numeric, text, jsonb, jsonb, jsonb) to authenticated;
grant execute on function public.delete_dashboard_widget(uuid) to authenticated;
grant execute on function public.set_widget_visible(uuid, boolean) to authenticated;
grant execute on function public.set_alert_active(uuid, boolean) to authenticated;
grant execute on function public.trigger_couple_alert(uuid, text, text, text, text, text, timestamptz, uuid) to authenticated;

do $$
begin
  if exists (
    select 1
    from pg_publication
    where pubname = 'supabase_realtime'
  ) then
    if not exists (
      select 1
      from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'partner'
    ) then
      alter publication supabase_realtime add table public.partner;
    end if;

    if not exists (
      select 1
      from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'dashboard_widget'
    ) then
      alter publication supabase_realtime add table public.dashboard_widget;
    end if;

    if not exists (
      select 1
      from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'couple_alert'
    ) then
      alter publication supabase_realtime add table public.couple_alert;
    end if;
  end if;
end $$;

notify pgrst, 'reload schema';
