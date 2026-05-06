alter function public.admin_list_tenants() security definer;
alter function public.admin_create_tenant(text, text, text, date, date, text, text, text, text) security definer;
alter function public.admin_get_tenant(uuid) security definer;
alter function public.admin_update_tenant(uuid, text, text, text, date, date, uuid, text, text, uuid, text, text) security definer;
alter function public.admin_regenerate_tenant_credentials(uuid) security definer;
alter function public.admin_delete_tenant(uuid) security definer;

grant execute on function public.admin_list_tenants() to authenticated;
grant execute on function public.admin_create_tenant(text, text, text, date, date, text, text, text, text) to authenticated;
grant execute on function public.admin_get_tenant(uuid) to authenticated;
grant execute on function public.admin_update_tenant(uuid, text, text, text, date, date, uuid, text, text, uuid, text, text) to authenticated;
grant execute on function public.admin_regenerate_tenant_credentials(uuid) to authenticated;
grant execute on function public.admin_delete_tenant(uuid) to authenticated;
