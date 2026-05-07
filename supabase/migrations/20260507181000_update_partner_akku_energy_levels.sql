alter table public.partner
  drop constraint if exists partner_hunger_level_check;

alter table public.partner
  alter column hunger_level set default 'Alles normal';

update public.partner
set hunger_level = case hunger_level
  when 'Absolut vollgefressen' then 'Absolut vollgefressen'
  when 'Kleiner Snack wär nice' then 'Kleiner Snack wär nice'
  when 'Alles normal' then 'Alles normal'
  when 'Hungrig' then 'Hungrig'
  when 'Richtig hungrig' then 'Richtig hungrig'
  when 'Am Verhungern' then 'Am Verhungern'
  when 'Voll motiviert - Lass uns Ausgehen' then 'Alles normal'
  when 'Kuschelbedürftig' then 'Kleiner Snack wär nice'
  when 'Hangry' then 'Richtig hungrig'
  when 'Im Tunnel' then 'Hungrig'
  when 'Pause benötigt - Sofazeit' then 'Kleiner Snack wär nice'
  when 'Absolut ausgelaugt - alles absagen' then 'Am Verhungern'
  when 'Kleiner Spaziergang wär super' then 'Kleiner Snack wär nice'
  when 'Voll geladen und motiviert - Lass uns was starten' then 'Alles normal'
  else 'Alles normal'
end;

alter table public.partner
  add constraint partner_hunger_level_check
  check (
    hunger_level in (
      'Absolut vollgefressen',
      'Kleiner Snack wär nice',
      'Alles normal',
      'Hungrig',
      'Richtig hungrig',
      'Am Verhungern'
    )
  );

alter table public.partner
  add column if not exists battery_level text not null default 'Voll geladen und motiviert - Lass uns was starten';

alter table public.partner
  drop constraint if exists partner_battery_level_check;

update public.partner
set battery_level = case battery_level
  when 'Voll motiviert - Lass uns Ausgehen' then 'Voll geladen und motiviert - Lass uns was starten'
  when 'Kuschelbedürftig' then 'Kleiner Spaziergang wär super'
  when 'Hangry' then 'Absolut ausgelaugt - alles absagen'
  when 'Im Tunnel' then 'Pause benötigt - Sofazeit'
  when 'Absolut ausgelaugt - alles absagen' then 'Absolut ausgelaugt - alles absagen'
  when 'Pause benötigt - Sofazeit' then 'Pause benötigt - Sofazeit'
  when 'Kleiner Spaziergang wär super' then 'Kleiner Spaziergang wär super'
  when 'Voll geladen und motiviert - Lass uns was starten' then 'Voll geladen und motiviert - Lass uns was starten'
  else 'Voll geladen und motiviert - Lass uns was starten'
end;

alter table public.partner
  add constraint partner_battery_level_check
  check (
    battery_level in (
      'Absolut ausgelaugt - alles absagen',
      'Pause benötigt - Sofazeit',
      'Kleiner Spaziergang wär super',
      'Voll geladen und motiviert - Lass uns was starten'
    )
  );

grant select (id, couple_id, slug, name, role, accent, hunger_level, battery_level, avatar_path, created_at)
  on public.partner to authenticated;

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
    'Absolut vollgefressen',
    'Kleiner Snack wär nice',
    'Alles normal',
    'Hungrig',
    'Richtig hungrig',
    'Am Verhungern'
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

create or replace function public.update_partner_battery_level(
  p_partner_id uuid,
  p_battery_level text
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

  if p_battery_level not in (
    'Absolut ausgelaugt - alles absagen',
    'Pause benötigt - Sofazeit',
    'Kleiner Spaziergang wär super',
    'Voll geladen und motiviert - Lass uns was starten'
  ) then
    raise exception 'Invalid battery level';
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
    set battery_level = p_battery_level
  where id = target_partner.id;
end;
$$;

grant execute on function public.update_partner_battery_level(uuid, text) to authenticated;
