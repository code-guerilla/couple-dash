alter table public.couple
  alter column wedding_date type timestamptz
  using wedding_date::timestamptz;

alter table public.couple
  add column if not exists chore_turn_partner_id uuid;

alter table public.partner
  add constraint partner_couple_id_id_unique unique (couple_id, id);

alter table public.couple
  add constraint couple_chore_turn_partner_fk
  foreign key (id, chore_turn_partner_id)
  references public.partner (couple_id, id)
  on delete set null (chore_turn_partner_id);

create index if not exists couple_chore_turn_partner_id_idx
  on public.couple (chore_turn_partner_id);

drop function if exists public.list_my_couples();
drop function if exists public.admin_list_tenants();
drop function if exists public.admin_get_tenant(uuid);

create or replace function public.list_my_couples()
returns table (
  couple_id uuid,
  slug text,
  name text,
  subtitle text,
  relationship_start date,
  wedding_date timestamptz,
  chore_turn_partner_id uuid,
  partner_count bigint,
  accepted_partner_count bigint
)
language sql
stable
security invoker
set search_path = ''
as $$
  select
    couple.id,
    couple.slug,
    couple.name,
    couple.subtitle,
    couple.relationship_start,
    couple.wedding_date,
    couple.chore_turn_partner_id,
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

create or replace function public.admin_list_tenants()
returns table (
  couple_id uuid,
  slug text,
  name text,
  subtitle text,
  relationship_start date,
  wedding_date timestamptz,
  chore_turn_partner_id uuid,
  partner_count bigint,
  accepted_partner_count bigint,
  widget_count bigint,
  active_alert_count bigint,
  created_at timestamptz
)
language sql
stable
security invoker
set search_path = ''
as $$
  select
    couple.id,
    couple.slug,
    couple.name,
    couple.subtitle,
    couple.relationship_start,
    couple.wedding_date,
    couple.chore_turn_partner_id,
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

create or replace function public.admin_get_tenant(p_couple_id uuid)
returns table (
  couple_id uuid,
  slug text,
  name text,
  subtitle text,
  relationship_start date,
  wedding_date timestamptz,
  chore_turn_partner_id uuid,
  partners jsonb
)
language sql
stable
security invoker
set search_path = ''
as $$
  select
    couple.id,
    couple.slug,
    couple.name,
    couple.subtitle,
    couple.relationship_start,
    couple.wedding_date,
    couple.chore_turn_partner_id,
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

create or replace function public.enforce_couple_member_settings_update()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if (select private.is_app_admin()) then
    return new;
  end if;

  if not private.is_couple_member(old.id) then
    raise exception 'Not allowed';
  end if;

  if new.id is distinct from old.id
    or new.slug is distinct from old.slug
    or new.name is distinct from old.name
    or new.subtitle is distinct from old.subtitle
    or new.relationship_start is distinct from old.relationship_start
    or new.created_by is distinct from old.created_by
    or new.created_at is distinct from old.created_at then
    raise exception 'Couple members can only update wedding_date and chore_turn_partner_id';
  end if;

  return new;
end;
$$;

drop trigger if exists enforce_couple_member_settings_update on public.couple;
create trigger enforce_couple_member_settings_update
before update on public.couple
for each row
execute function public.enforce_couple_member_settings_update();

create policy "Members update couple settings"
on public.couple for update
to authenticated
using ((select private.is_app_admin()) or private.is_couple_member(id))
with check (
  (select private.is_app_admin())
  or (
    private.is_couple_member(id)
    and (
      chore_turn_partner_id is null
      or exists (
        select 1
        from public.partner partner
        where partner.id = couple.chore_turn_partner_id
          and partner.couple_id = couple.id
      )
    )
  )
);

grant select (id, slug, name, subtitle, relationship_start, wedding_date, chore_turn_partner_id, created_at)
  on public.couple to authenticated;
grant execute on function public.list_my_couples() to authenticated;
grant execute on function public.admin_list_tenants() to authenticated;
grant execute on function public.admin_get_tenant(uuid) to authenticated;

do $$
begin
  if exists (
    select 1
    from pg_publication
    where pubname = 'supabase_realtime'
  ) and not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'couple'
  ) then
    alter publication supabase_realtime add table public.couple;
  end if;
end;
$$;
