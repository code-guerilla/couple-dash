grant select (user_id, created_at) on public.app_admin to authenticated;
grant insert, update, delete on public.app_admin to authenticated;

grant select (id, slug, name, subtitle, relationship_start, wedding_date, chore_turn_partner_id, created_at)
  on public.couple to authenticated;
grant insert, update, delete on public.couple to authenticated;

grant select (id, couple_id, slug, name, role, accent, hunger_level, avatar_path, created_at)
  on public.partner to authenticated;
grant insert, update, delete on public.partner to authenticated;

grant select, insert, update, delete on public.couple_member to authenticated;
grant select, insert, update on public.dashboard_widget to authenticated;
grant select, insert, update, delete on public.couple_alert to authenticated;

grant execute on function public.is_app_admin() to authenticated;
grant execute on function public.is_couple_member(uuid) to authenticated;
grant execute on function public.admin_list_tenants() to authenticated;
grant execute on function public.admin_create_tenant(text, text, text, date, date, text, text, text, text) to authenticated;
grant execute on function public.admin_get_tenant(uuid) to authenticated;
grant execute on function public.admin_update_tenant(uuid, text, text, text, date, date, uuid, text, text, uuid, text, text) to authenticated;
grant execute on function public.admin_regenerate_tenant_credentials(uuid) to authenticated;
grant execute on function public.admin_delete_tenant(uuid) to authenticated;
