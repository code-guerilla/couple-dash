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

  if target_partner.id is null then
    raise exception 'Invalid partner invite';
  end if;

  if target_partner.user_id = auth.uid() then
    accepted_partner_id := target_partner.id;
    accepted_couple_id := target_partner.couple_id;
    return next;
  end if;

  if target_partner.user_id is not null and target_partner.user_id <> auth.uid() then
    raise exception 'Partner invite already accepted';
  end if;

  if target_partner.invite_token_hash is null
    or extensions.crypt(p_invite_token, target_partner.invite_token_hash) <> target_partner.invite_token_hash then
    raise exception 'Invalid partner invite';
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
