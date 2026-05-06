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
security invoker
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
    timeline_entries
  ) values (
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
    )
  );

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

grant execute on function public.admin_create_tenant(text, text, text, date, date, text, text, text, text) to authenticated;
