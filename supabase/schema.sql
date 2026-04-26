create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

do $$
begin
  if to_regclass('public.app_admins') is not null and to_regclass('public.app_admin') is null then
    alter table public.app_admins rename to app_admin;
  end if;

  if to_regclass('public.couples') is not null and to_regclass('public.couple') is null then
    alter table public.couples rename to couple;
  end if;

  if to_regclass('public.partners') is not null and to_regclass('public.partner') is null then
    alter table public.partners rename to partner;
  end if;

  if to_regclass('public.couple_members') is not null and to_regclass('public.couple_member') is null then
    alter table public.couple_members rename to couple_member;
  end if;

  if to_regclass('public.display_devices') is not null and to_regclass('public.display_device') is null then
    alter table public.display_devices rename to display_device;
  end if;

  if to_regclass('public.dashboard_widgets') is not null and to_regclass('public.dashboard_widget') is null then
    alter table public.dashboard_widgets rename to dashboard_widget;
  end if;

  if to_regclass('public.couple_alerts') is not null and to_regclass('public.couple_alert') is null then
    alter table public.couple_alerts rename to couple_alert;
  end if;
end $$;

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
  anniversary_date date not null,
  theme text not null default 'night',
  display_token_hash text not null,
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

create table if not exists public.display_device (
  id uuid primary key default extensions.gen_random_uuid(),
  couple_id uuid not null references public.couple(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  label text not null default 'Kitchen display',
  revoked_at timestamptz,
  created_at timestamptz not null default now(),
  unique (couple_id, user_id)
);

create table if not exists public.dashboard_widget (
  id uuid primary key default extensions.gen_random_uuid(),
  couple_id uuid not null references public.couple(id) on delete cascade,
  label text not null,
  value text not null,
  unit text,
  detail text not null default '',
  scope text not null check (scope in ('shared', 'person')),
  person_id uuid references public.partner(id) on delete cascade,
  visual text not null default 'stat' check (visual in ('stat', 'progress', 'radial', 'doughnut', 'bar', 'line', 'memory')),
  sort_order integer not null default 0,
  min_value numeric,
  max_value numeric,
  numeric_value numeric,
  tone text not null default 'info' check (tone in ('info', 'success', 'warning', 'error')),
  visible boolean not null default true,
  updated_at timestamptz not null default now(),
  constraint dashboard_widget_scope_person_check check (
    (scope = 'shared' and person_id is null)
    or
    (scope = 'person' and person_id is not null)
  )
);

create table if not exists public.couple_alert (
  id uuid primary key default extensions.gen_random_uuid(),
  couple_id uuid not null references public.couple(id) on delete cascade,
  title text not null,
  detail text not null default '',
  severity text not null default 'info' check (severity in ('info', 'success', 'warning', 'error')),
  source text not null default 'system' check (source in ('system', 'partner')),
  active boolean not null default true,
  triggered_by text,
  created_at timestamptz not null default now()
);

alter table public.couple add column if not exists theme text not null default 'night';
alter table public.couple add column if not exists display_token_hash text;
alter table public.couple add column if not exists created_by uuid references auth.users(id);
update public.couple
  set display_token_hash = extensions.crypt(extensions.gen_random_uuid()::text, extensions.gen_salt('bf'))
where display_token_hash is null;
alter table public.couple alter column display_token_hash set not null;
alter table public.partner add column if not exists user_id uuid references auth.users(id) on delete set null;
alter table public.partner add column if not exists invite_token_hash text;
alter table public.partner drop column if exists edit_token;
alter table public.dashboard_widget add column if not exists visible boolean not null default true;
update public.dashboard_widget set visual = 'stat' where visual = 'status';
update public.dashboard_widget set visual = 'progress' where visual = 'latency';
update public.dashboard_widget set visual = 'bar' where visual = 'allocation';

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

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'dashboard_widget_visual_check'
      and conrelid = 'public.dashboard_widget'::regclass
  ) then
    alter table public.dashboard_widget
      add constraint dashboard_widget_visual_check
      check (visual in ('stat', 'progress', 'radial', 'doughnut', 'bar', 'line', 'memory'));
  end if;
end $$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'dashboard_widget_scope_person_check'
      and conrelid = 'public.dashboard_widget'::regclass
  ) then
    alter table public.dashboard_widget
      add constraint dashboard_widget_scope_person_check
      check (
        (scope = 'shared' and person_id is null)
        or
        (scope = 'person' and person_id is not null)
      );
  end if;
end $$;

create index if not exists couple_slug_idx on public.couple (slug);
create index if not exists partner_couple_id_idx on public.partner (couple_id);
create index if not exists partner_user_id_idx on public.partner (user_id);
create index if not exists couple_member_user_id_idx on public.couple_member (user_id);
create index if not exists couple_member_couple_id_idx on public.couple_member (couple_id);
create index if not exists display_device_user_id_idx on public.display_device (user_id);
create index if not exists display_device_couple_id_idx on public.display_device (couple_id);
create index if not exists dashboard_widget_couple_sort_idx on public.dashboard_widget (couple_id, sort_order);
create index if not exists dashboard_widget_person_id_idx on public.dashboard_widget (person_id);
create index if not exists couple_alert_couple_active_created_idx
  on public.couple_alert (couple_id, active, created_at desc);

create or replace function public.is_app_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() is not null
    and exists (
      select 1
      from public.app_admin admin
      where admin.user_id = auth.uid()
    );
$$;

create or replace function public.is_couple_member(p_couple_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
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
$$;

create or replace function public.is_display_device_for_couple(p_couple_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() is not null
    and exists (
      select 1
      from public.display_device device
      where device.couple_id = p_couple_id
        and device.user_id = auth.uid()
        and device.revoked_at is null
    );
$$;

create or replace function public.is_current_partner_for_widget(p_couple_id uuid, p_person_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() is not null
    and exists (
      select 1
      from public.couple_member member
      where member.couple_id = p_couple_id
        and member.user_id = auth.uid()
        and member.partner_id = p_person_id
    );
$$;

create or replace function public.validate_dashboard_widget_person()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  partner_couple_id uuid;
begin
  if new.scope = 'shared' and new.person_id is not null then
    raise exception 'Shared widgets cannot have person_id';
  end if;

  if new.scope = 'person' and new.person_id is null then
    raise exception 'Person widgets require person_id';
  end if;

  if new.person_id is not null then
    select partner.couple_id
      into partner_couple_id
    from public.partner partner
    where partner.id = new.person_id;

    if partner_couple_id is null or partner_couple_id <> new.couple_id then
      raise exception 'Widget person_id must reference a partner from the same couple';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists validate_dashboard_widget_person_trigger on public.dashboard_widget;
create trigger validate_dashboard_widget_person_trigger
before insert or update of couple_id, scope, person_id
on public.dashboard_widget
for each row
execute function public.validate_dashboard_widget_person();

create or replace function public.claim_display_device(p_slug text, p_display_token text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_couple public.couple%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  select *
    into target_couple
  from public.couple couple
  where couple.slug = p_slug;

  if target_couple.id is null
    or target_couple.display_token_hash is null
    or extensions.crypt(p_display_token, target_couple.display_token_hash) <> target_couple.display_token_hash then
    raise exception 'Invalid display token';
  end if;

  insert into public.display_device (couple_id, user_id, revoked_at)
  values (target_couple.id, auth.uid(), null)
  on conflict (couple_id, user_id) do update
    set revoked_at = null;

  return target_couple.id;
end;
$$;

create or replace function public.accept_partner_invite(
  p_slug text,
  p_partner_slug text,
  p_invite_token text
) returns table (partner_id uuid, couple_id uuid)
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

  partner_id := target_partner.id;
  couple_id := target_partner.couple_id;
  return next;
end;
$$;

create or replace function public.update_dashboard_widget(
  p_widget_id uuid,
  p_label text,
  p_value text,
  p_unit text,
  p_detail text,
  p_visual text,
  p_tone text,
  p_numeric_value numeric
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

  if not public.is_app_admin() then
    if target_widget.scope = 'shared' then
      if not public.is_couple_member(target_widget.couple_id) then
        raise exception 'Not allowed';
      end if;
    elsif not public.is_current_partner_for_widget(target_widget.couple_id, target_widget.person_id) then
      raise exception 'Not allowed';
    end if;
  end if;

  update public.dashboard_widget
    set label = coalesce(p_label, label),
        value = coalesce(p_value, value),
        unit = p_unit,
        detail = coalesce(p_detail, detail),
        visual = coalesce(p_visual, visual),
        tone = coalesce(p_tone, tone),
        numeric_value = p_numeric_value,
        updated_at = now()
  where id = p_widget_id;
end;
$$;

create or replace function public.add_dashboard_widget(
  p_couple_id uuid,
  p_label text,
  p_value text,
  p_unit text,
  p_detail text,
  p_scope text,
  p_person_id uuid,
  p_visual text,
  p_sort_order integer,
  p_min_value numeric,
  p_max_value numeric,
  p_numeric_value numeric,
  p_tone text
) returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  new_id uuid;
begin
  if not public.is_app_admin() then
    if p_scope = 'shared' then
      if p_person_id is not null or not public.is_couple_member(p_couple_id) then
        raise exception 'Not allowed';
      end if;
    elsif p_scope = 'person' then
      if p_person_id is null or not public.is_current_partner_for_widget(p_couple_id, p_person_id) then
        raise exception 'Not allowed';
      end if;
    else
      raise exception 'Invalid scope';
    end if;
  end if;

  insert into public.dashboard_widget (
    couple_id,
    label,
    value,
    unit,
    detail,
    scope,
    person_id,
    visual,
    sort_order,
    min_value,
    max_value,
    numeric_value,
    tone
  ) values (
    p_couple_id,
    p_label,
    p_value,
    p_unit,
    coalesce(p_detail, ''),
    p_scope,
    p_person_id,
    coalesce(p_visual, 'stat'),
    coalesce(p_sort_order, 0),
    p_min_value,
    p_max_value,
    p_numeric_value,
    coalesce(p_tone, 'info')
  )
  returning id into new_id;

  return new_id;
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

  if not public.is_app_admin() then
    if target_widget.scope = 'shared' then
      if not public.is_couple_member(target_widget.couple_id) then
        raise exception 'Not allowed';
      end if;
    elsif not public.is_current_partner_for_widget(target_widget.couple_id, target_widget.person_id) then
      raise exception 'Not allowed';
    end if;
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
begin
  select *
    into target_alert
  from public.couple_alert alert
  where alert.id = p_alert_id;

  if target_alert.id is null then
    raise exception 'Alert not found';
  end if;

  if not public.is_app_admin() and not public.is_couple_member(target_alert.couple_id) then
    raise exception 'Not allowed';
  end if;

  update public.couple_alert
    set active = p_active
  where id = p_alert_id;
end;
$$;

create or replace function public.trigger_couple_alert(
  p_couple_id uuid,
  p_title text,
  p_detail text,
  p_severity text,
  p_source text default 'partner',
  p_triggered_by text default null
) returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  new_id uuid;
  next_source text := coalesce(p_source, 'partner');
begin
  if public.is_app_admin() then
    next_source := coalesce(p_source, 'system');
  elsif public.is_couple_member(p_couple_id) and next_source = 'partner' then
    next_source := 'partner';
  else
    raise exception 'Not allowed';
  end if;

  insert into public.couple_alert (couple_id, title, detail, severity, source, triggered_by)
  values (
    p_couple_id,
    p_title,
    coalesce(p_detail, ''),
    coalesce(p_severity, 'info'),
    next_source,
    p_triggered_by
  )
  returning id into new_id;

  return new_id;
end;
$$;

alter table public.app_admin enable row level security;
alter table public.couple enable row level security;
alter table public.partner enable row level security;
alter table public.couple_member enable row level security;
alter table public.display_device enable row level security;
alter table public.dashboard_widget enable row level security;
alter table public.couple_alert enable row level security;

do $$
begin
  if to_regclass('public.couple') is not null then
    execute 'drop policy if exists "Public read couple" on public.couple';
    execute 'drop policy if exists "Public read couples" on public.couple';
    execute 'drop policy if exists "Couple visible to member admin and display" on public.couple';
    execute 'drop policy if exists "Couples are visible to members admins and displays" on public.couple';
    execute 'drop policy if exists "couple are visible to members admins and displays" on public.couple';
    execute 'drop policy if exists "App admin manage couple" on public.couple';
    execute 'drop policy if exists "App admins manage couple" on public.couple';
    execute 'drop policy if exists "App admins manage couples" on public.couple';
  end if;

  if to_regclass('public.partner') is not null then
    execute 'drop policy if exists "Public read partner without token" on public.partner';
    execute 'drop policy if exists "Public read partners without token" on public.partner';
    execute 'drop policy if exists "Partner visible to member admin and display" on public.partner';
    execute 'drop policy if exists "Partners are visible to members admins and displays" on public.partner';
    execute 'drop policy if exists "partner are visible to members admins and displays" on public.partner';
    execute 'drop policy if exists "App admin manage partner" on public.partner';
    execute 'drop policy if exists "App admins manage partner" on public.partner';
    execute 'drop policy if exists "App admins manage partners" on public.partner';
  end if;

  if to_regclass('public.dashboard_widget') is not null then
    execute 'drop policy if exists "Public read widgets" on public.dashboard_widget';
    execute 'drop policy if exists "Widgets are visible to members and displays" on public.dashboard_widget';
    execute 'drop policy if exists "Members insert shared widgets" on public.dashboard_widget';
    execute 'drop policy if exists "Members insert own person widgets" on public.dashboard_widget';
    execute 'drop policy if exists "Members update shared widgets" on public.dashboard_widget';
    execute 'drop policy if exists "Members update own person widgets" on public.dashboard_widget';
    execute 'drop policy if exists "App admins manage widgets" on public.dashboard_widget';
  end if;

  if to_regclass('public.couple_alert') is not null then
    execute 'drop policy if exists "Public read alerts" on public.couple_alert';
    execute 'drop policy if exists "Alerts are visible to members and displays" on public.couple_alert';
    execute 'drop policy if exists "Members create partner alerts" on public.couple_alert';
    execute 'drop policy if exists "App admins manage alerts" on public.couple_alert';
  end if;
end $$;

drop policy if exists "App admins view app admins" on public.app_admin;
drop policy if exists "App admin view app_admin" on public.app_admin;
drop policy if exists "App admins manage app admins" on public.app_admin;
drop policy if exists "App admin manage app_admin" on public.app_admin;
drop policy if exists "Members view couple memberships" on public.couple_member;
drop policy if exists "Couple member visible to member" on public.couple_member;
drop policy if exists "App admins manage couple memberships" on public.couple_member;
drop policy if exists "App admin manage couple_member" on public.couple_member;
drop policy if exists "Members and displays view display devices" on public.display_device;
drop policy if exists "Display device visible to member and device" on public.display_device;
drop policy if exists "App admins manage display devices" on public.display_device;
drop policy if exists "App admin manage display_device" on public.display_device;

create policy "App admin view app_admin"
on public.app_admin for select
to authenticated
using (public.is_app_admin());

create policy "App admin manage app_admin"
on public.app_admin for all
to authenticated
using (public.is_app_admin())
with check (public.is_app_admin());

create policy "Couple visible to member admin and display"
on public.couple for select
to authenticated
using (public.is_couple_member(id) or public.is_display_device_for_couple(id));

create policy "App admin manage couple"
on public.couple for all
to authenticated
using (public.is_app_admin())
with check (public.is_app_admin());

create policy "Partner visible to member admin and display"
on public.partner for select
to authenticated
using (public.is_couple_member(couple_id) or public.is_display_device_for_couple(couple_id));

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

create policy "Display device visible to member and device"
on public.display_device for select
to authenticated
using (public.is_couple_member(couple_id) or (user_id = auth.uid() and revoked_at is null));

create policy "App admin manage display_device"
on public.display_device for all
to authenticated
using (public.is_app_admin())
with check (public.is_app_admin());

create policy "Widgets are visible to members and displays"
on public.dashboard_widget for select
to authenticated
using (
  public.is_couple_member(couple_id)
  or (visible = true and public.is_display_device_for_couple(couple_id))
);

create policy "Members insert shared widgets"
on public.dashboard_widget for insert
to authenticated
with check (
  scope = 'shared'
  and person_id is null
  and public.is_couple_member(couple_id)
);

create policy "Members insert own person widgets"
on public.dashboard_widget for insert
to authenticated
with check (
  scope = 'person'
  and person_id is not null
  and public.is_current_partner_for_widget(couple_id, person_id)
);

create policy "Members update shared widgets"
on public.dashboard_widget for update
to authenticated
using (
  scope = 'shared'
  and person_id is null
  and public.is_couple_member(couple_id)
)
with check (
  scope = 'shared'
  and person_id is null
  and public.is_couple_member(couple_id)
);

create policy "Members update own person widgets"
on public.dashboard_widget for update
to authenticated
using (
  scope = 'person'
  and person_id is not null
  and public.is_current_partner_for_widget(couple_id, person_id)
)
with check (
  scope = 'person'
  and person_id is not null
  and public.is_current_partner_for_widget(couple_id, person_id)
);

create policy "App admins manage widgets"
on public.dashboard_widget for all
to authenticated
using (public.is_app_admin())
with check (public.is_app_admin());

create policy "Alerts are visible to members and displays"
on public.couple_alert for select
to authenticated
using (
  public.is_couple_member(couple_id)
  or (active = true and public.is_display_device_for_couple(couple_id))
);

create policy "Members create partner alerts"
on public.couple_alert for insert
to authenticated
with check (
  source = 'partner'
  and public.is_couple_member(couple_id)
);

create policy "App admins manage alerts"
on public.couple_alert for all
to authenticated
using (public.is_app_admin())
with check (public.is_app_admin());

revoke all on all tables in schema public from anon, authenticated;
revoke all on all functions in schema public from anon, authenticated;
grant usage on schema public to authenticated;

grant select (user_id, created_at) on public.app_admin to authenticated;
grant insert, update, delete on public.app_admin to authenticated;
grant select (id, slug, name, subtitle, relationship_start, wedding_date, anniversary_date, theme, created_at)
  on public.couple to authenticated;
grant insert, update, delete on public.couple to authenticated;
grant select (id, couple_id, slug, name, role, accent, created_at)
  on public.partner to authenticated;
grant insert, update, delete on public.partner to authenticated;
grant select, insert, update, delete on public.couple_member to authenticated;
grant select, insert, update, delete on public.display_device to authenticated;
grant select, insert, update, delete on public.dashboard_widget to authenticated;
grant select, insert, update, delete on public.couple_alert to authenticated;

grant execute on function public.is_app_admin() to authenticated;
grant execute on function public.is_couple_member(uuid) to authenticated;
grant execute on function public.is_display_device_for_couple(uuid) to authenticated;
grant execute on function public.claim_display_device(text, text) to authenticated;
grant execute on function public.accept_partner_invite(text, text, text) to authenticated;
grant execute on function public.update_dashboard_widget(uuid, text, text, text, text, text, text, numeric) to authenticated;
grant execute on function public.add_dashboard_widget(uuid, text, text, text, text, text, uuid, text, integer, numeric, numeric, numeric, text) to authenticated;
grant execute on function public.set_widget_visible(uuid, boolean) to authenticated;
grant execute on function public.set_alert_active(uuid, boolean) to authenticated;
grant execute on function public.trigger_couple_alert(uuid, text, text, text, text, text) to authenticated;

drop function if exists public.partner_can_edit(text, uuid, uuid);
drop function if exists public.update_dashboard_widget_with_token(text, uuid, text, text, text, text, text, text, numeric);
drop function if exists public.add_dashboard_widget_with_token(text, uuid, text, text, text, text, text, uuid, text, integer, numeric, numeric, numeric, text);
drop function if exists public.trigger_couple_alert_with_token(text, uuid, text, text, text, text);

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

