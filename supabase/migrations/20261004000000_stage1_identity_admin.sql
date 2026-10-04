-- Etapa 1: identidade, perfis, administração e auditoria
create extension if not exists pgcrypto;

create type public.app_role as enum ('seller','admin');
create type public.account_status as enum ('active','suspended');
create type public.admin_level as enum ('standard','superadmin');

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  email text not null default '',
  role public.app_role not null default 'seller',
  status public.account_status not null default 'active',
  admin_level public.admin_level not null default 'standard',
  accepted_terms_at timestamptz,
  suspended_at timestamptz,
  suspension_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint admin_level_only_admin check (role = 'admin' or admin_level = 'standard')
);

create table if not exists public.admin_invitations (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  invited_by uuid not null references public.profiles(id),
  status text not null default 'pending' check (status in ('pending','accepted','revoked')),
  expires_at timestamptz not null default (now() + interval '72 hours'),
  accepted_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.audit_logs (
  id bigint generated always as identity primary key,
  actor_id uuid references public.profiles(id),
  action text not null,
  target_user_id uuid references public.profiles(id),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists profiles_role_status_idx on public.profiles(role,status);
create index if not exists profiles_email_idx on public.profiles(lower(email));
create index if not exists audit_logs_created_idx on public.audit_logs(created_at desc);

create or replace function public.set_updated_at()
returns trigger language plpgsql security invoker as $$
begin new.updated_at = now(); return new; end $$;

drop trigger if exists profiles_updated_at on public.profiles;
create trigger profiles_updated_at before update on public.profiles
for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles(id,full_name,email,role,status,admin_level,accepted_terms_at)
  values(
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name',''),
    lower(new.email),
    'seller',
    'active',
    'standard',
    case when coalesce((new.raw_user_meta_data->>'accepted_terms')::boolean,false)
      then now() else null end
  )
  on conflict (id) do update set
    email = excluded.email,
    full_name = case when public.profiles.full_name = '' then excluded.full_name else public.profiles.full_name end;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin' and p.status='active');
$$;

create or replace function public.is_superadmin()
returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin' and p.admin_level='superadmin' and p.status='active');
$$;

alter table public.profiles enable row level security;
alter table public.admin_invitations enable row level security;
alter table public.audit_logs enable row level security;

drop policy if exists profiles_select_self_or_admin on public.profiles;
create policy profiles_select_self_or_admin on public.profiles
for select using (id=auth.uid() or public.is_admin());

drop policy if exists profiles_insert_none on public.profiles;
create policy profiles_insert_none on public.profiles for insert with check (false);

drop policy if exists profiles_update_none on public.profiles;
create policy profiles_update_none on public.profiles for update using (false);

drop policy if exists profiles_delete_none on public.profiles;
create policy profiles_delete_none on public.profiles for delete using (false);

create or replace function public.update_my_profile(p_full_name text)
returns public.profiles
language plpgsql security definer set search_path=public
as $$
declare result public.profiles;
begin
  update public.profiles
  set full_name=trim(p_full_name)
  where id=auth.uid() and status='active'
  returning * into result;
  if result.id is null then raise exception 'Conta indisponível'; end if;
  return result;
end $$;
revoke all on function public.update_my_profile(text) from public;
grant execute on function public.update_my_profile(text) to authenticated;

create or replace function public.suspend_seller(p_user_id uuid,p_reason text)
returns void language plpgsql security definer set search_path=public
as $$
begin
  if not public.is_admin() then raise exception 'Acesso negado'; end if;
  if p_reason is null or length(trim(p_reason)) < 3 then raise exception 'Informe o motivo da suspensão'; end if;
  update public.profiles
  set status='suspended', suspended_at=now(), suspension_reason=trim(p_reason)
  where id=p_user_id and role='seller';
  if not found then raise exception 'Vendedor não encontrado'; end if;
  insert into public.audit_logs(actor_id,action,target_user_id,metadata)
  values(auth.uid(),'seller.suspended',p_user_id,jsonb_build_object('reason',trim(p_reason)));
end $$;
revoke all on function public.suspend_seller(uuid,text) from public;
grant execute on function public.suspend_seller(uuid,text) to authenticated;

create or replace function public.reactivate_seller(p_user_id uuid,p_reason text)
returns void language plpgsql security definer set search_path=public
as $$
begin
  if not public.is_admin() then raise exception 'Acesso negado'; end if;
  update public.profiles
  set status='active', suspended_at=null, suspension_reason=null
  where id=p_user_id and role='seller';
  if not found then raise exception 'Vendedor não encontrado'; end if;
  insert into public.audit_logs(actor_id,action,target_user_id,metadata)
  values(auth.uid(),'seller.reactivated',p_user_id,jsonb_build_object('reason',coalesce(trim(p_reason),'')));
end $$;
revoke all on function public.reactivate_seller(uuid,text) from public;
grant execute on function public.reactivate_seller(uuid,text) to authenticated;

create or replace function public.bootstrap_superadmin(p_email text)
returns void language plpgsql security definer set search_path=public
as $$
declare target_id uuid;
begin
  if coalesce(current_setting('request.jwt.claim.role',true),'') <> 'service_role' then
    raise exception 'Procedimento reservado ao proprietário';
  end if;
  select id into target_id from auth.users where lower(email)=lower(trim(p_email)) limit 1;
  if target_id is null then raise exception 'Crie primeiro a conta Auth com esse e-mail'; end if;
  update public.profiles
  set role='admin', admin_level='superadmin', status='active', suspended_at=null, suspension_reason=null
  where id=target_id;
  insert into public.audit_logs(actor_id,action,target_user_id,metadata)
  values(null,'superadmin.bootstrapped',target_id,jsonb_build_object('email',lower(trim(p_email))));
end $$;
revoke all on function public.bootstrap_superadmin(text) from public;
grant execute on function public.bootstrap_superadmin(text) to service_role;

create or replace function public.invite_admin_record(p_email text)
returns uuid language plpgsql security definer set search_path=public
as $$
declare invitation_id uuid;
begin
  if not public.is_superadmin() then raise exception 'Somente o superadministrador pode convidar administradores'; end if;
  insert into public.admin_invitations(email,invited_by)
  values(lower(trim(p_email)),auth.uid())
  returning id into invitation_id;
  insert into public.audit_logs(actor_id,action,metadata)
  values(auth.uid(),'admin.invited',jsonb_build_object('email',lower(trim(p_email)),'invitation_id',invitation_id));
  return invitation_id;
end $$;
revoke all on function public.invite_admin_record(text) from public;
grant execute on function public.invite_admin_record(text) to authenticated;

create or replace function public.revoke_admin(p_user_id uuid,p_reason text)
returns void language plpgsql security definer set search_path=public
as $$
declare target public.profiles;
declare super_count integer;
begin
  if not public.is_superadmin() then raise exception 'Somente o superadministrador pode remover administradores'; end if;
  select * into target from public.profiles where id=p_user_id and role='admin';
  if target.id is null then raise exception 'Administrador não encontrado'; end if;
  if target.id=auth.uid() then raise exception 'Não é permitido remover a própria conta'; end if;
  select count(*) into super_count from public.profiles where role='admin' and admin_level='superadmin' and status='active';
  if target.admin_level='superadmin' and super_count <= 1 then raise exception 'O último superadministrador deve ser preservado'; end if;
  update public.profiles set status='suspended' where id=p_user_id;
  insert into public.audit_logs(actor_id,action,target_user_id,metadata)
  values(auth.uid(),'admin.revoked',p_user_id,jsonb_build_object('reason',coalesce(trim(p_reason),'')));
end $$;
revoke all on function public.revoke_admin(uuid,text) from public;
grant execute on function public.revoke_admin(uuid,text) to authenticated;

drop policy if exists audit_select_admin on public.audit_logs;
create policy audit_select_admin on public.audit_logs for select using (public.is_admin());

drop policy if exists audit_insert_none on public.audit_logs;
create policy audit_insert_none on public.audit_logs for insert with check (false);

drop policy if exists invitations_select_superadmin on public.admin_invitations;
create policy invitations_select_superadmin on public.admin_invitations for select using (public.is_superadmin());

drop policy if exists invitations_insert_none on public.admin_invitations;
create policy invitations_insert_none on public.admin_invitations for insert with check (false);

grant select on public.profiles to authenticated;
grant select on public.audit_logs to authenticated;
grant select on public.admin_invitations to authenticated;
