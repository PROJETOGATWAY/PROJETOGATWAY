-- Etapa 4: métodos de saque, reservas e processamento administrativo
create table if not exists public.withdrawal_methods (
  id uuid primary key default gen_random_uuid(), seller_id uuid not null references public.profiles(id) on delete restrict,
  method_type text not null check (method_type in ('pix','iban','revolut')), holder_name text not null, tax_id text not null,
  pix_key_type text, pix_key text, iban text, country text, bic_swift text, revtag text,
  ownership_declared boolean not null default false, ownership_declared_at timestamptz,
  is_default boolean not null default false, is_active boolean not null default true,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  constraint withdrawal_methods_pix_fields check ((method_type='pix' and pix_key_type is not null and pix_key is not null and iban is null) or method_type in ('iban','revolut')),
  constraint withdrawal_methods_iban_fields check ((method_type='iban' and iban is not null and country is not null) or method_type <> 'iban'),
  constraint withdrawal_methods_revolut_fields check ((method_type='revolut' and iban is not null) or method_type <> 'revolut'),
  constraint withdrawal_methods_ownership_check check (ownership_declared=true and ownership_declared_at is not null)
);
create unique index if not exists withdrawal_methods_one_default on public.withdrawal_methods(seller_id) where is_default and is_active;
create index if not exists withdrawal_methods_seller_idx on public.withdrawal_methods(seller_id,is_active,created_at desc);
alter table public.withdrawals
  add column if not exists withdrawal_method_id uuid references public.withdrawal_methods(id) on delete restrict,
  add column if not exists method_type_snapshot text, add column if not exists destination_holder_name_snapshot text,
  add column if not exists destination_tax_id_snapshot text, add column if not exists destination_pix_key_type_snapshot text,
  add column if not exists destination_pix_key_snapshot text, add column if not exists destination_iban_snapshot text,
  add column if not exists destination_country_snapshot text, add column if not exists destination_bic_swift_snapshot text,
  add column if not exists destination_revtag_snapshot text, add column if not exists destination_masked_snapshot text,
  add column if not exists net_amount_eur numeric, add column if not exists payment_reference text,
  add column if not exists payment_proof_path text, add column if not exists paid_amount_brl numeric,
  add column if not exists paid_at timestamptz, add column if not exists decision_reason text,
  add column if not exists decided_by uuid references public.profiles(id), add column if not exists rules_updated_at_snapshot timestamptz;
alter table public.withdrawals drop constraint if exists withdrawals_status_check;
alter table public.withdrawals add constraint withdrawals_status_check check (status in ('requested','under_review','approved_for_payment','processing','paid','rejected','cancelled'));
alter table public.withdrawals add constraint withdrawals_net_amount_check check (net_amount_eur is null or net_amount_eur>0);
alter table public.withdrawals add constraint withdrawals_paid_brl_check check (paid_amount_brl is null or paid_amount_brl>0);
alter table public.payment_financial_ledger drop constraint if exists payment_financial_ledger_entry_type_check;
alter table public.payment_financial_ledger add constraint payment_financial_ledger_entry_type_check check (entry_type in ('sale_credit','reversal_debit','withdrawal_debit','withdrawal_release'));
create index if not exists withdrawals_seller_status_idx on public.withdrawals(seller_id,status,created_at desc);
create index if not exists withdrawals_method_idx on public.withdrawals(withdrawal_method_id);
alter table public.withdrawal_methods enable row level security;
alter table public.withdrawals enable row level security;
drop policy if exists "withdrawal methods seller own select" on public.withdrawal_methods;
create policy "withdrawal methods seller own select" on public.withdrawal_methods for select to authenticated using (seller_id=auth.uid() or public.is_admin());
drop policy if exists "withdrawals seller own select" on public.withdrawals;
create policy "withdrawals seller own select" on public.withdrawals for select to authenticated using (seller_id=auth.uid() or public.is_admin());
revoke insert,update,delete on public.withdrawal_methods from authenticated;
revoke insert,update,delete on public.withdrawals from authenticated;
grant select on public.withdrawal_methods, public.withdrawals to authenticated;

create or replace function public.withdrawal_mask_destination(p_method_type text,p_pix_key_type text,p_pix_key text,p_iban text,p_country text,p_bic_swift text,p_revtag text)
returns text language plpgsql immutable set search_path=''
as $$
begin
 if p_method_type='pix' then
   if p_pix_key_type='email' then return regexp_replace(coalesce(p_pix_key,''),'(^.).*(@.*$)','\1***\2');
   elsif p_pix_key_type='phone' then return case when length(regexp_replace(coalesce(p_pix_key,''),'[^0-9]','','g'))>=4 then '***'||right(regexp_replace(p_pix_key,'[^0-9]','','g'),4) else '***' end;
   elsif p_pix_key_type in ('cpf','cnpj') then return '***'||right(regexp_replace(coalesce(p_pix_key,''),'[^0-9]','','g'),4); end if;
   return '***'||right(coalesce(p_pix_key,''),4);
 elsif p_method_type='revolut' then return coalesce(nullif(p_revtag,''),'IBAN ••••'||right(regexp_replace(coalesce(p_iban,''),'[^A-Z0-9]','','gi'),4));
 else return coalesce(nullif(p_country,''),'')||' ••••'||right(regexp_replace(coalesce(p_iban,''),'[^A-Z0-9]','','gi'),4);
 end if;
end;
$$;

create or replace function public.validate_withdrawal_method_input(p_method_type text,p_holder_name text,p_tax_id text,p_pix_key_type text,p_pix_key text,p_iban text,p_country text,p_bic_swift text,p_revtag text)
returns void language plpgsql set search_path=''
as $$
declare tax_digits text; iban_clean text; pix_digits text;
begin
 if p_method_type not in ('pix','iban','revolut') then raise exception 'Tipo de método inválido'; end if;
 if length(trim(coalesce(p_holder_name,'')))<2 then raise exception 'O nome do titular é obrigatório'; end if;
 if p_method_type='pix' then
   tax_digits:=regexp_replace(coalesce(p_tax_id,''),'[^0-9]','','g');
   if length(tax_digits) not in (11,14) then raise exception 'CPF ou CNPJ inválido'; end if;
   if p_pix_key_type not in ('cpf','cnpj','email','phone','random') then raise exception 'Tipo de chave Pix inválido'; end if;
   if nullif(trim(coalesce(p_pix_key,'')),'') is null then raise exception 'A chave Pix é obrigatória'; end if;
   if p_pix_key_type='email' and position('@' in trim(p_pix_key))=0 then raise exception 'E-mail da chave Pix inválido'; end if;
   if p_pix_key_type='phone' then pix_digits:=regexp_replace(p_pix_key,'[^0-9]','','g'); if length(pix_digits)<10 or length(pix_digits)>15 then raise exception 'Telefone da chave Pix inválido'; end if; end if;
   if p_pix_key_type='cpf' and length(regexp_replace(p_pix_key,'[^0-9]','','g'))<>11 then raise exception 'Chave Pix CPF inválida'; end if;
   if p_pix_key_type='cnpj' and length(regexp_replace(p_pix_key,'[^0-9]','','g'))<>14 then raise exception 'Chave Pix CNPJ inválida'; end if;
 elsif p_method_type='iban' then
   iban_clean:=upper(regexp_replace(coalesce(p_iban,''),'\s','','g'));
   if length(iban_clean)<15 or length(iban_clean)>34 or iban_clean !~ '^[A-Z]{2}[0-9A-Z]+$' then raise exception 'IBAN inválido'; end if;
   if length(trim(coalesce(p_country,'')))<>2 then raise exception 'País deve usar código ISO de 2 letras'; end if;
   if nullif(trim(coalesce(p_bic_swift,'')),'') is not null and upper(trim(p_bic_swift)) !~ '^[A-Z0-9]{8}([A-Z0-9]{3})?$' then raise exception 'BIC/SWIFT inválido'; end if;
 else
   iban_clean:=upper(regexp_replace(coalesce(p_iban,''),'\s','','g'));
   if length(iban_clean)<15 or length(iban_clean)>34 or iban_clean !~ '^[A-Z]{2}[0-9A-Z]+$' then raise exception 'IBAN em EUR inválido'; end if;
   if nullif(trim(coalesce(p_revtag,'')),'') is not null and trim(p_revtag) !~ '^@?[A-Za-z0-9._-]{3,32}$' then raise exception 'Revtag inválida'; end if;
 end if;
end;
$$;

create or replace function public.create_withdrawal_method(p_method_type text,p_holder_name text,p_tax_id text,p_pix_key_type text default null,p_pix_key text default null,p_iban text default null,p_country text default null,p_bic_swift text default null,p_revtag text default null,p_ownership_declared boolean default false)
returns public.withdrawal_methods language plpgsql security definer set search_path=''
as $$
declare result public.withdrawal_methods; existing_default boolean;
begin
 if not exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='seller' and p.status='active') then raise exception 'Conta de vendedor indisponível'; end if;
 if not coalesce(p_ownership_declared,false) then raise exception 'Declare que o método pertence ao titular informado'; end if;
 perform public.validate_withdrawal_method_input(p_method_type,p_holder_name,p_tax_id,p_pix_key_type,p_pix_key,p_iban,p_country,p_bic_swift,p_revtag);
 select exists(select 1 from public.withdrawal_methods where seller_id=auth.uid() and is_active and is_default) into existing_default;
 insert into public.withdrawal_methods(seller_id,method_type,holder_name,tax_id,pix_key_type,pix_key,iban,country,bic_swift,revtag,ownership_declared,ownership_declared_at,is_default,is_active)
 values(auth.uid(),p_method_type,trim(p_holder_name),nullif(regexp_replace(coalesce(p_tax_id,''),'[^0-9]','','g'),''),nullif(trim(p_pix_key_type),''),nullif(trim(p_pix_key),''),upper(regexp_replace(nullif(trim(p_iban),''),'\s','','g')),upper(trim(nullif(p_country,''))),upper(trim(nullif(p_bic_swift,''))),nullif(trim(p_revtag),''),true,now(),not existing_default,true)
 returning * into result;
 insert into public.audit_logs(actor_id,action,target_user_id,metadata) values(auth.uid(),'withdrawal_method.created',auth.uid(),jsonb_build_object('method_id',result.id,'method_type',result.method_type,'is_default',result.is_default));
 return result;
end;
$$;

create or replace function public.set_default_withdrawal_method(p_method_id uuid)
returns public.withdrawal_methods language plpgsql security definer set search_path=''
as $$
declare result public.withdrawal_methods;
begin
 update public.withdrawal_methods set is_default=false,updated_at=now() where seller_id=auth.uid() and is_default;
 update public.withdrawal_methods set is_default=true,updated_at=now() where id=p_method_id and seller_id=auth.uid() and is_active returning * into result;
 if result.id is null then raise exception 'Método de saque não encontrado ou inativo'; end if;
 insert into public.audit_logs(actor_id,action,target_user_id,metadata) values(auth.uid(),'withdrawal_method.default_changed',auth.uid(),jsonb_build_object('method_id',result.id));
 return result;
end;
$$;

create or replace function public.deactivate_withdrawal_method(p_method_id uuid)
returns public.withdrawal_methods language plpgsql security definer set search_path=''
as $$
declare result public.withdrawal_methods;
begin
 update public.withdrawal_methods set is_active=false,is_default=false,updated_at=now() where id=p_method_id and seller_id=auth.uid() and is_active returning * into result;
 if result.id is null then raise exception 'Método de saque não encontrado ou já inativo'; end if;
 insert into public.audit_logs(actor_id,action,target_user_id,metadata) values(auth.uid(),'withdrawal_method.deactivated',auth.uid(),jsonb_build_object('method_id',result.id));
 return result;
end;
$$;

create or replace function public.request_withdrawal(p_amount_eur numeric,p_withdrawal_method_id uuid,p_rules_updated_at timestamptz)
returns public.withdrawals language plpgsql security definer set search_path=''
as $$
declare current_settings public.platform_settings; method public.withdrawal_methods; balance numeric; result public.withdrawals;
begin
 if not exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='seller' and p.status='active') then raise exception 'Conta de vendedor indisponível'; end if;
 select * into method from public.withdrawal_methods where id=p_withdrawal_method_id and seller_id=auth.uid() and is_active;
 if method.id is null then raise exception 'Método de saque inválido ou inativo'; end if;
 select * into current_settings from public.platform_settings where id=1 for update;
 if current_settings.initialized_at is null then raise exception 'Os saques ainda não estão disponíveis'; end if;
 if current_settings.withdrawals_paused then raise exception 'Novos saques estão pausados'; end if;
 if p_rules_updated_at is null or current_settings.updated_at<>p_rules_updated_at then raise exception 'As regras de saque foram atualizadas. Revise o resumo e confirme novamente'; end if;
 if p_amount_eur is null or round(p_amount_eur,2)<=0 then raise exception 'O valor do saque deve ser maior que zero'; end if;
 if round(p_amount_eur,2)<current_settings.minimum_withdrawal_eur then raise exception 'O valor está abaixo do mínimo de saque'; end if;
 if round(p_amount_eur,2)-current_settings.withdrawal_fixed_fee_eur<=0 then raise exception 'O valor líquido do saque deve ser maior que zero'; end if;
 perform 1 from public.profiles where id=auth.uid() for update;
 select coalesce(sum(l.amount_eur),0) into balance from public.payment_financial_ledger l where l.seller_id=auth.uid();
 if balance<0 then raise exception 'Saldo disponível negativo. Novos saques estão bloqueados'; end if;
 if round(p_amount_eur,2)>balance then raise exception 'Saldo disponível insuficiente'; end if;
 insert into public.withdrawals(seller_id,amount_eur,fixed_fee_snapshot_eur,status,withdrawal_method_id,method_type_snapshot,destination_holder_name_snapshot,destination_tax_id_snapshot,destination_pix_key_type_snapshot,destination_pix_key_snapshot,destination_iban_snapshot,destination_country_snapshot,destination_bic_swift_snapshot,destination_revtag_snapshot,destination_masked_snapshot,net_amount_eur,rules_updated_at_snapshot)
 values(auth.uid(),round(p_amount_eur,2),current_settings.withdrawal_fixed_fee_eur,'requested',method.id,method.method_type,method.holder_name,method.tax_id,method.pix_key_type,method.pix_key,method.iban,method.country,method.bic_swift,method.revtag,public.withdrawal_mask_destination(method.method_type,method.pix_key_type,method.pix_key,method.iban,method.country,method.bic_swift,method.revtag),round(p_amount_eur,2)-current_settings.withdrawal_fixed_fee_eur,current_settings.updated_at)
 returning * into result;
 insert into public.payment_financial_ledger(seller_id,withdrawal_id,entry_type,amount_eur,reason,created_by) values(auth.uid(),result.id,'withdrawal_debit',-result.amount_eur,'Reserva de saque',auth.uid());
 insert into public.audit_logs(actor_id,target_user_id,action,metadata) values(auth.uid(),auth.uid(),'withdrawal.requested',jsonb_build_object('withdrawal_id',result.id,'amount_eur',result.amount_eur,'fixed_fee_eur',result.fixed_fee_snapshot_eur,'net_amount_eur',result.net_amount_eur,'method_type',result.method_type_snapshot,'destination',result.destination_masked_snapshot));
 return result;
end;
$$;

create or replace function public.cancel_own_withdrawal(p_withdrawal_id uuid)
returns public.withdrawals language plpgsql security definer set search_path=''
as $$
declare result public.withdrawals;
begin
 perform 1 from public.profiles where id=auth.uid() for update;
 select * into result from public.withdrawals where id=p_withdrawal_id and seller_id=auth.uid() for update;
 if result.id is null then raise exception 'Saque não encontrado'; end if;
 if result.status<>'requested' then raise exception 'O saque só pode ser cancelado enquanto estiver Solicitado'; end if;
 update public.withdrawals set status='cancelled',decision_reason='Cancelado pelo vendedor',decided_by=auth.uid(),updated_at=now() where id=result.id returning * into result;
 insert into public.payment_financial_ledger(seller_id,withdrawal_id,entry_type,amount_eur,reason,created_by) values(result.seller_id,result.id,'withdrawal_release',result.amount_eur,'Liberação de reserva por cancelamento',auth.uid());
 insert into public.audit_logs(actor_id,target_user_id,action,metadata) values(auth.uid(),auth.uid(),'withdrawal.cancelled_by_seller',jsonb_build_object('withdrawal_id',result.id,'amount_eur',result.amount_eur));
 return result;
end;
$$;

create or replace function public.admin_set_withdrawal_status(p_withdrawal_id uuid,p_status text,p_reason text default null)
returns public.withdrawals language plpgsql security definer set search_path=''
as $$
declare result public.withdrawals; old_status text; target_seller uuid;
begin
 if not public.is_admin() then raise exception 'Acesso negado'; end if;
 select seller_id into target_seller from public.withdrawals where id=p_withdrawal_id;
 if target_seller is null then raise exception 'Saque não encontrado'; end if;
 perform 1 from public.profiles where id=target_seller for update;
 select * into result from public.withdrawals where id=p_withdrawal_id for update;
 old_status:=result.status;
 if p_status='under_review' and result.status<>'requested' then raise exception 'Transição inválida'; end if;
 if p_status='approved_for_payment' and result.status not in ('requested','under_review') then raise exception 'Transição inválida'; end if;
 if p_status='processing' and result.status<>'approved_for_payment' then raise exception 'O saque precisa estar aprovado para pagamento'; end if;
 if p_status in ('rejected','cancelled') then
   if result.status in ('paid','processing','rejected','cancelled') then raise exception 'Este saque não pode ser rejeitado ou cancelado'; end if;
   if nullif(trim(coalesce(p_reason,'')),'') is null then raise exception 'O motivo é obrigatório'; end if;
 else
   if p_status not in ('under_review','approved_for_payment','processing') then raise exception 'Estado administrativo inválido'; end if;
 end if;
 update public.withdrawals set status=p_status,decision_reason=case when p_status in ('rejected','cancelled') then trim(p_reason) else decision_reason end,decided_by=auth.uid(),updated_at=now() where id=result.id returning * into result;
 if p_status in ('rejected','cancelled') then
   insert into public.payment_financial_ledger(seller_id,withdrawal_id,entry_type,amount_eur,reason,created_by) values(result.seller_id,result.id,'withdrawal_release',result.amount_eur,case when p_status='rejected' then 'Liberação de reserva por rejeição' else 'Liberação de reserva por cancelamento administrativo' end,auth.uid());
 end if;
 insert into public.audit_logs(actor_id,target_user_id,action,metadata) values(auth.uid(),result.seller_id,'withdrawal.status_changed',jsonb_build_object('withdrawal_id',result.id,'from_status',old_status,'to_status',p_status,'reason',p_reason));
 return result;
end;
$$;

create or replace function public.admin_mark_withdrawal_paid(p_withdrawal_id uuid,p_payment_reference text,p_payment_proof_path text,p_paid_amount_brl numeric default null)
returns public.withdrawals language plpgsql security definer set search_path=''
as $$
declare result public.withdrawals; target_seller uuid;
begin
 if not public.is_admin() then raise exception 'Acesso negado'; end if;
 if nullif(trim(p_payment_reference),'') is null then raise exception 'A referência do pagamento é obrigatória'; end if;
 if nullif(trim(p_payment_proof_path),'') is null then raise exception 'O comprovante do pagamento é obrigatório'; end if;
 select seller_id into target_seller from public.withdrawals where id=p_withdrawal_id;
 if target_seller is null then raise exception 'Saque não encontrado'; end if;
 perform 1 from public.profiles where id=target_seller for update;
 select * into result from public.withdrawals where id=p_withdrawal_id for update;
 if result.status<>'processing' then raise exception 'O saque precisa estar Em processamento para ser marcado como Pago'; end if;
 if result.method_type_snapshot='pix' then
   if p_paid_amount_brl is null or p_paid_amount_brl<=0 then raise exception 'Informe o valor efetivamente transferido em BRL para Pix'; end if;
 else
   if p_paid_amount_brl is not null then raise exception 'Valor em BRL só é permitido para Pix'; end if;
 end if;
 update public.withdrawals set status='paid',payment_reference=trim(p_payment_reference),payment_proof_path=trim(p_payment_proof_path),paid_amount_brl=case when result.method_type_snapshot='pix' then round(p_paid_amount_brl,2) else null end,paid_at=now(),confirmed_at=now(),decided_by=auth.uid(),updated_at=now() where id=result.id returning * into result;
 insert into public.audit_logs(actor_id,target_user_id,action,metadata) values(auth.uid(),result.seller_id,'withdrawal.paid',jsonb_build_object('withdrawal_id',result.id,'amount_eur',result.amount_eur,'net_amount_eur',result.net_amount_eur,'payment_reference',result.payment_reference,'paid_amount_brl',result.paid_amount_brl));
 return result;
end;
$$;

revoke all on function public.create_withdrawal_method(text,text,text,text,text,text,text,text,text,boolean) from anon; grant execute on function public.create_withdrawal_method(text,text,text,text,text,text,text,text,text,boolean) to authenticated;
revoke all on function public.set_default_withdrawal_method(uuid) from anon; grant execute on function public.set_default_withdrawal_method(uuid) to authenticated;
revoke all on function public.deactivate_withdrawal_method(uuid) from anon; grant execute on function public.deactivate_withdrawal_method(uuid) to authenticated;
revoke all on function public.request_withdrawal(numeric,uuid,timestamptz) from anon; grant execute on function public.request_withdrawal(numeric,uuid,timestamptz) to authenticated;
revoke all on function public.cancel_own_withdrawal(uuid) from anon; grant execute on function public.cancel_own_withdrawal(uuid) to authenticated;
revoke all on function public.admin_set_withdrawal_status(uuid,text,text) from anon; grant execute on function public.admin_set_withdrawal_status(uuid,text,text) to authenticated;
revoke all on function public.admin_mark_withdrawal_paid(uuid,text,text,numeric) from anon; grant execute on function public.admin_mark_withdrawal_paid(uuid,text,text,numeric) to authenticated;
