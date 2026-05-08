create table if not exists public.couple_chore_task (
  id uuid primary key default extensions.gen_random_uuid(),
  couple_id uuid not null references public.couple(id) on delete cascade,
  title text not null check (length(trim(title)) > 0),
  icon text not null default 'i-lucide-circle-help',
  assigned_partner_id uuid,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint couple_chore_task_assigned_partner_fk
    foreign key (couple_id, assigned_partner_id)
    references public.partner (couple_id, id)
    on delete set null (assigned_partner_id)
);

create index if not exists couple_chore_task_couple_sort_idx
  on public.couple_chore_task (couple_id, sort_order);
create index if not exists couple_chore_task_assigned_partner_idx
  on public.couple_chore_task (assigned_partner_id)
  where assigned_partner_id is not null;

with partner_order as (
  select
    partner.id,
    partner.couple_id,
    row_number() over (partition by partner.couple_id order by partner.created_at) as partner_order
  from public.partner partner
),
default_tasks(title, icon, sort_order, preferred_side) as (
  values
    ('Wer macht den Kaffee?', 'i-lucide-coffee', 1, 1),
    ('Wer geht mit dem Hund Lotte?', 'i-lucide-dog', 2, 1),
    ('Wer ist mit Kochen dran?', 'i-lucide-cooking-pot', 3, 2),
    ('Wer macht das Bad sauber?', 'i-lucide-bath', 4, 1),
    ('Wer bringt den Müll raus?', 'i-lucide-trash-2', 5, 2)
)
insert into public.couple_chore_task (couple_id, title, icon, sort_order, assigned_partner_id)
select
  couple.id,
  default_tasks.title,
  default_tasks.icon,
  default_tasks.sort_order,
  case
    when default_tasks.preferred_side = 1 then coalesce(couple.chore_turn_partner_id, partner_one.id, partner_two.id)
    else coalesce(partner_two.id, partner_one.id, couple.chore_turn_partner_id)
  end
from public.couple couple
cross join default_tasks
left join partner_order partner_one
  on partner_one.couple_id = couple.id
  and partner_one.partner_order = 1
left join partner_order partner_two
  on partner_two.couple_id = couple.id
  and partner_two.partner_order = 2
where not exists (
  select 1
  from public.couple_chore_task existing_task
  where existing_task.couple_id = couple.id
);

create or replace function public.update_couple_chore_task(
  p_task_id uuid,
  p_title text,
  p_assigned_partner_id uuid
) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_task public.couple_chore_task%rowtype;
  next_title text := trim(coalesce(p_title, ''));
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  select *
    into target_task
  from public.couple_chore_task task
  where task.id = p_task_id;

  if target_task.id is null or not public.is_couple_member(target_task.couple_id) then
    raise exception 'Not allowed';
  end if;

  if next_title = '' then
    raise exception 'Task title is required';
  end if;

  if p_assigned_partner_id is not null
    and not exists (
      select 1
      from public.partner partner
      where partner.id = p_assigned_partner_id
        and partner.couple_id = target_task.couple_id
    ) then
    raise exception 'Selected partner does not belong to this couple';
  end if;

  update public.couple_chore_task
    set title = next_title,
        assigned_partner_id = p_assigned_partner_id,
        updated_at = now()
  where id = target_task.id;
end;
$$;

alter table public.couple_chore_task enable row level security;

create policy "Chore tasks visible to members and admins"
on public.couple_chore_task for select
to authenticated
using ((select private.is_app_admin()) or private.is_couple_member(couple_id));

create policy "Members and admins update chore tasks"
on public.couple_chore_task for update
to authenticated
using ((select private.is_app_admin()) or private.is_couple_member(couple_id))
with check (
  ((select private.is_app_admin()) or private.is_couple_member(couple_id))
  and (
    assigned_partner_id is null
    or exists (
      select 1
      from public.partner partner
      where partner.id = couple_chore_task.assigned_partner_id
        and partner.couple_id = couple_chore_task.couple_id
    )
  )
);

create policy "App admins insert chore tasks"
on public.couple_chore_task for insert
to authenticated
with check ((select private.is_app_admin()));

create policy "App admins delete chore tasks"
on public.couple_chore_task for delete
to authenticated
using ((select private.is_app_admin()));

grant select, insert, update, delete on public.couple_chore_task to authenticated;
grant execute on function public.update_couple_chore_task(uuid, text, uuid) to authenticated;

do $$
begin
  if exists (
    select 1
    from pg_publication
    where pubname = 'supabase_realtime'
  ) and not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'couple_chore_task'
  ) then
    alter publication supabase_realtime add table public.couple_chore_task;
  end if;
end $$;

notify pgrst, 'reload schema';
