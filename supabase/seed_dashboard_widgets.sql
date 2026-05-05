insert into public.dashboard_widget (
  couple_id,
  label,
  value,
  detail,
  visual,
  sort_order,
  tone,
  timeline_entries,
  chart_data,
  chart_options
)
select
  couple.id,
  seed.label,
  seed.value,
  seed.detail,
  seed.visual,
  seed.sort_order,
  seed.tone,
  '[]'::jsonb,
  seed.chart_data,
  seed.chart_options
from public.couple couple
cross join (
  values
    (
      'Woraus die Beziehung besteht',
      '100%',
      'Liebe, Kaffee und Essensdiskussionen in einem wissenschaftlich fragwürdigen Mix.',
      'donut',
      10,
      'success',
      jsonb_build_array(
        jsonb_build_object('label', 'Liebe', 'value', 40),
        jsonb_build_object('label', 'Kaffee', 'value', 20),
        jsonb_build_object('label', 'Diskussionen über Essen', 'value', 25),
        jsonb_build_object('label', 'Gemeinsame Serien', 'value', 15)
      ),
      jsonb_build_object('centralLabel', 'Beziehungs-Mix', 'centralSubLabel', 'wissenschaftlich fragwürdig')
    ),
    (
      'Gewonnene Diskussionen',
      '75%',
      'Beide tun so, als hätten sie gewonnen.',
      'donut',
      11,
      'warning',
      jsonb_build_array(
        jsonb_build_object('label', 'Partner A', 'value', 12),
        jsonb_build_object('label', 'Partner B', 'value', 13),
        jsonb_build_object('label', 'Beide gewonnen', 'value', 75)
      ),
      jsonb_build_object('centralLabel', '75%', 'centralSubLabel', 'diplomatischer Sieg')
    ),
    (
      'Top Beziehungsthemen',
      '87',
      'Ranking der wichtigsten Haushaltskonferenzen.',
      'bar',
      12,
      'info',
      jsonb_build_array(
        jsonb_build_object('label', 'Was essen wir?', 'value', 87),
        jsonb_build_object('label', 'Wo sind die Schlüssel?', 'value', 42),
        jsonb_build_object('label', 'Noch eine Folge?', 'value', 64)
      ),
      '{}'::jsonb
    ),
    (
      'Romantik im Zeitverlauf',
      '100',
      'Fake Trend, echte Gefühle.',
      'line',
      13,
      'success',
      jsonb_build_array(
        jsonb_build_object('label', 'Kennenlernen', 'value', 80),
        jsonb_build_object('label', 'Erster Urlaub', 'value', 95),
        jsonb_build_object('label', 'Umzug', 'value', 62),
        jsonb_build_object('label', 'Hochzeit', 'value', 100)
      ),
      '{}'::jsonb
    )
) as seed(label, value, detail, visual, sort_order, tone, chart_data, chart_options)
where not exists (
  select 1
  from public.dashboard_widget widget
  where widget.couple_id = couple.id
    and widget.label = seed.label
);
