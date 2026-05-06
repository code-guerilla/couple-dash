alter table public.partner
  drop constraint if exists partner_hunger_level_check;

alter table public.partner
  alter column hunger_level set default 'Voll motiviert - Lass uns Ausgehen';

update public.partner
set hunger_level = case hunger_level
  when 'full' then 'Voll motiviert - Lass uns Ausgehen'
  when 'snack' then 'Kuschelbedürftig'
  when 'getting-hungry' then 'Hangry'
  when 'need-food' then 'Hangry'
  when 'starving' then 'Im Tunnel'
  when 'critical' then 'Pause benötigt - Sofazeit'
  else 'Voll motiviert - Lass uns Ausgehen'
end;

alter table public.partner
  add constraint partner_hunger_level_check
  check (
    hunger_level in (
      'Voll motiviert - Lass uns Ausgehen',
      'Kuschelbedürftig',
      'Hangry',
      'Im Tunnel',
      'Pause benötigt - Sofazeit'
    )
  );

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

  if p_hunger_level not in (
    'Voll motiviert - Lass uns Ausgehen',
    'Kuschelbedürftig',
    'Hangry',
    'Im Tunnel',
    'Pause benötigt - Sofazeit'
  ) then
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

create or replace function public.update_couple_settings(
  p_couple_id uuid,
  p_relationship_start date,
  p_wedding_date date,
  p_chore_turn_partner_id uuid default null
) returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if not public.is_app_admin() and not public.is_couple_member(p_couple_id) then
    raise exception 'Not allowed';
  end if;

  if p_chore_turn_partner_id is not null
    and not exists (
      select 1
      from public.partner partner
      where partner.id = p_chore_turn_partner_id
        and partner.couple_id = p_couple_id
    ) then
    raise exception 'Selected partner does not belong to this couple';
  end if;

  update public.couple
    set relationship_start = p_relationship_start,
        wedding_date = p_wedding_date,
        chore_turn_partner_id = p_chore_turn_partner_id
  where id = p_couple_id;

  if not found then
    raise exception 'Couple not found';
  end if;
end;
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
    or new.created_by is distinct from old.created_by
    or new.created_at is distinct from old.created_at then
    raise exception 'Couple members can only update relationship_start, wedding_date and chore_turn_partner_id';
  end if;

  return new;
end;
$$;

grant execute on function public.update_partner_hunger_level(uuid, text) to authenticated;
grant execute on function public.update_couple_settings(uuid, date, date, uuid) to authenticated;

notify pgrst, 'reload schema';
