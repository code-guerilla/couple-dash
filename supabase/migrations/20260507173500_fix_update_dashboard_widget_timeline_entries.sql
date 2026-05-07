create or replace function public.update_dashboard_widget(
  p_widget_id uuid,
  p_label text default null,
  p_value text default null,
  p_unit text default null,
  p_detail text default null,
  p_visual text default null,
  p_tone text default null,
  p_numeric_value numeric default null,
  p_timeline_entries jsonb default null
) returns void
language plpgsql
security invoker
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
        updated_at = now()
  where id = p_widget_id;
end;
$$;
