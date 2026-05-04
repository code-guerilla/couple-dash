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
  anniversary_date date not null,
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

create table if not exists public.dashboard_widget (
  id uuid primary key default extensions.gen_random_uuid(),
  couple_id uuid not null references public.couple(id) on delete cascade,
  label text not null,
  value text not null,
  unit text,
  detail text not null default '',
  scope text not null check (scope in ('shared', 'person')),
  person_id uuid references public.partner(id) on delete cascade,
  visual text not null default 'stat' check (visual in ('stat', 'progress', 'radial', 'doughnut', 'bar', 'line', 'memory', 'timeline')),
  sort_order integer not null default 0,
  min_value numeric,
  max_value numeric,
  numeric_value numeric,
  tone text not null default 'info' check (tone in ('info', 'success', 'warning', 'error')),
  visible boolean not null default true,
  timeline_entries jsonb not null default '[]'::jsonb,
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

alter table public.couple add column if not exists created_by uuid references auth.users(id);
alter table public.partner add column if not exists user_id uuid references auth.users(id) on delete set null;
alter table public.partner add column if not exists invite_token_hash text;
alter table public.dashboard_widget add column if not exists visible boolean not null default true;
alter table public.dashboard_widget add column if not exists timeline_entries jsonb not null default '[]'::jsonb;
alter table public.dashboard_widget drop constraint if exists dashboard_widget_visual_check;

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

alter table public.dashboard_widget
  add constraint dashboard_widget_visual_check
  check (visual in ('stat', 'progress', 'radial', 'doughnut', 'bar', 'line', 'memory', 'timeline'));

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

create or replace function public.is_current_partner_for_widget(p_couple_id uuid, p_person_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as '
  select auth.uid() is not null
    and exists (
      select 1
      from public.couple_member member
      where member.couple_id = p_couple_id
        and member.user_id = auth.uid()
        and member.partner_id = p_person_id
    );
';

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

create or replace function public.list_my_couples()
returns table (
  couple_id uuid,
  slug text,
  name text,
  subtitle text,
  relationship_start date,
  wedding_date date,
  anniversary_date date,
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
    couple.anniversary_date,
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
  anniversary_date date,
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
    couple.anniversary_date,
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
  p_anniversary_date date,
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
    anniversary_date,
    created_by
  ) values (
    normalized_slug,
    trim(p_name),
    coalesce(trim(p_subtitle), ''),
    p_relationship_start,
    p_wedding_date,
    p_anniversary_date,
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
    scope,
    person_id,
    visual,
    sort_order,
    max_value,
    numeric_value,
    tone,
    timeline_entries
  ) values
    (
      new_couple_id,
      'Our Timeline',
      '6 milestones',
      'The relationship milestones that make the dashboard personal.',
      'shared',
      null,
      'timeline',
      1,
      null,
      null,
      'success',
      jsonb_build_array(
        jsonb_build_object('id', 'first-met', 'date', p_relationship_start, 'title', 'First Met', 'description', 'The first chapter of the story.', 'icon', 'i-lucide-sparkles'),
        jsonb_build_object('id', 'official-couple', 'date', p_anniversary_date, 'title', 'Officially a Couple', 'description', 'The anniversary date that anchors the dashboard.', 'icon', 'i-lucide-badge-check'),
        jsonb_build_object('id', 'moved-together', 'date', p_anniversary_date, 'title', 'Moved Together', 'description', 'One place, two routines, shared keys.', 'icon', 'i-lucide-home'),
        jsonb_build_object('id', 'fur-baby', 'date', p_anniversary_date, 'title', 'Fur-Baby Date', 'description', 'The day the household got cuter.', 'icon', 'i-lucide-paw-print'),
        jsonb_build_object('id', 'engagement', 'date', p_anniversary_date, 'title', 'The Engagement', 'description', 'A yes worth keeping visible.', 'icon', 'i-lucide-gem'),
        jsonb_build_object('id', 'wedding', 'date', p_wedding_date, 'title', 'The Wedding', 'description', 'The big day on the shared calendar.', 'icon', 'i-lucide-church')
      )
    ),
    (new_couple_id, 'Days Together', '0', 'Update this together from the partner console.', 'shared', null, 'stat', 2, null, null, 'info', '[]'::jsonb),
    (new_couple_id, 'Wedding Countdown', 'Set', 'Keep the next milestone visible on the dashboard.', 'shared', null, 'stat', 3, null, null, 'success', '[]'::jsonb),
    (new_couple_id, trim(p_partner_a_name) || ' Check-in', 'Ready', 'Personal metric for ' || trim(p_partner_a_name) || '.', 'person', partner_a_id, 'stat', 4, null, null, 'info', '[]'::jsonb),
    (new_couple_id, trim(p_partner_b_name) || ' Check-in', 'Ready', 'Personal metric for ' || trim(p_partner_b_name) || '.', 'person', partner_b_id, 'stat', 5, null, null, 'info', '[]'::jsonb);

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

create or replace function public.admin_get_tenant(p_couple_id uuid)
returns table (
  couple_id uuid,
  slug text,
  name text,
  subtitle text,
  relationship_start date,
  wedding_date date,
  anniversary_date date,
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
    couple.anniversary_date,
    coalesce(
      jsonb_agg(
        jsonb_build_object(
          'id', partner.id,
          'slug', partner.slug,
          'name', partner.name,
          'role', partner.role,
          'accent', partner.accent,
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
  p_anniversary_date date,
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
        wedding_date = p_wedding_date,
        anniversary_date = p_anniversary_date
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

create or replace function public.update_dashboard_widget(
  p_widget_id uuid,
  p_label text,
  p_value text,
  p_unit text,
  p_detail text,
  p_visual text,
  p_tone text,
  p_numeric_value numeric,
  p_timeline_entries jsonb default null
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
        timeline_entries = coalesce(p_timeline_entries, timeline_entries),
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
alter table public.dashboard_widget enable row level security;
alter table public.couple_alert enable row level security;

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
drop policy if exists "App admins manage widgets" on public.dashboard_widget;
drop policy if exists "Alerts are visible to members" on public.couple_alert;
drop policy if exists "Members create partner alerts" on public.couple_alert;
drop policy if exists "App admins manage alerts" on public.couple_alert;

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
grant select (id, slug, name, subtitle, relationship_start, wedding_date, anniversary_date, created_at)
  on public.couple to authenticated;
grant insert, update, delete on public.couple to authenticated;
grant select (id, couple_id, slug, name, role, accent, created_at)
  on public.partner to authenticated;
grant insert, update, delete on public.partner to authenticated;
grant select, insert, update, delete on public.couple_member to authenticated;
grant select, update, delete on public.dashboard_widget to authenticated;
grant select, insert, update, delete on public.couple_alert to authenticated;

grant execute on function public.is_app_admin() to authenticated;
grant execute on function public.is_couple_member(uuid) to authenticated;
grant execute on function public.accept_partner_invite(text, text, text) to authenticated;
grant execute on function public.list_my_couples() to authenticated;
grant execute on function public.get_couple_invite_status(uuid) to authenticated;
grant execute on function public.create_pending_partner_invite(uuid) to authenticated;
grant execute on function public.admin_list_tenants() to authenticated;
grant execute on function public.admin_create_tenant(text, text, text, date, date, date, text, text, text, text) to authenticated;
grant execute on function public.admin_get_tenant(uuid) to authenticated;
grant execute on function public.admin_update_tenant(uuid, text, text, text, date, date, date, uuid, text, text, uuid, text, text) to authenticated;
grant execute on function public.admin_regenerate_tenant_credentials(uuid) to authenticated;
grant execute on function public.admin_delete_tenant(uuid) to authenticated;
grant execute on function public.update_dashboard_widget(uuid, text, text, text, text, text, text, numeric, jsonb) to authenticated;
grant execute on function public.set_widget_visible(uuid, boolean) to authenticated;
grant execute on function public.set_alert_active(uuid, boolean) to authenticated;
grant execute on function public.trigger_couple_alert(uuid, text, text, text, text, text) to authenticated;

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

notify pgrst, 'reload schema';
