alter function public.list_my_couples() security definer;

grant select, insert, update, delete on public.app_admin to authenticated;
grant select, insert, update, delete on public.couple to authenticated;
grant select, insert, update, delete on public.partner to authenticated;
grant select, insert, update, delete on public.couple_member to authenticated;
grant select, insert, update, delete on public.dashboard_widget to authenticated;
grant select, insert, update, delete on public.couple_alert to authenticated;
grant execute on function public.list_my_couples() to authenticated;
