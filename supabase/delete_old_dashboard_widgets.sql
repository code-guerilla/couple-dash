delete from public.dashboard_widget;

delete from public.couple_alert
where title in (
  'Snack shortage detected',
  'Anniversary approaching',
  'Cuddle maintenance overdue',
  'Dishwasher loaded incorrectly',
  'One partner said "nothing"',
  'Dashboard created'
);
