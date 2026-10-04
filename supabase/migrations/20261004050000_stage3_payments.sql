-- Etapa 3: pagamentos, comprovantes privados, conciliação, aprovação atômica e razão financeira

alter table public.payment_records
  add column if not exists payment_code text,
  add column if not exists currency text not null default 'EUR',
  add column if not exists payment_method text,
  add column if not exists order_id text,
  add column if not exists notes text,
  add column if not exists mbway_phone_snapshot text,
  add column if not exists central_iban_snapshot text,
  add column if not exists proof_path text,
  add column if not exists proof_mime_type text,
  add column if not exists proof_size_bytes bigint,
  add column if not exists admin_notes text,
  add column if not exists decision_reason text,
  add column if not exists decided_by uuid references public.profiles(id),
  add column if not exists receipt_id uuid,
  add column if not exists idempotency_key text,
  add column if not exists risk_reason text;

update public.payment_records
set payment_code=coalesce(payment_code,'PAY-'||upper(substr(replace(id::text,'-',''),1,12))),
    currency=coalesce(currency,'EUR')
where payment_code is null;

alter table public.payment_records alter column payment_code set not null;
alter table public.payment_records add constraint payment_records_currency_chk check(currency='EUR');
alter table public.payment_records add constraint payment_records_method_chk check(payment_method in ('mbway','iban'));
alter table public.payment_records add constraint payment_records_proof_mime_chk check(proof_mime_type is null or proof_mime_type in ('image/jpeg','image/png','image/webp','application/pdf'));
alter table public.payment_records add constraint payment_records_proof_size_chk check(proof_size_bytes is null or (proof_size_bytes > 0 and proof_size_bytes <= 10485760));

drop index if exists payment_records_payment_code_key;
create unique index if not exists payment_records_payment_code_key on public.payment_records(payment_code);
create unique index if not exists payment_records_idempotency_key_key on public.payment_records(seller_id,idempotency_key) where idempotency_key is not null;

alter table public.payment_records drop constraint if exists payment_records_status_check;
alter table public.payment_records add constraint payment_records_status_check check(status in ('pending','under_review','approved','rejected','estornado'));

create table if not exists public.central_receipts (
  id uuid primary key default gen_random_uuid(),
  receipt_reference text not null,
  received_at timestamptz not null default now(),
  amount_eur numeric(12,2) not null check(amount_eur>0),
  payment_method text not null check(payment_method in ('mbway','iban')),
  observation text,
  seller_id uuid references public.profiles(id) on delete set null,
  payment_id uuid references public.payment_records(id) on delete set null,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now()
);
create unique index if not exists central_receipts_reference_key on public.central_receipts(receipt_reference);
create unique index if not exists central_receipts_payment_key on public.central_receipts(payment_id) where payment_id is not null;
create index if not exists central_receipts_unmatched_idx on public.central_receipts(payment_id,received_at desc);

create table if not exists public.payment_financial_ledger (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references public.profiles(id) on delete restrict,
  payment_id uuid references public.payment_records(id) on delete restrict,
  withdrawal_id uuid references public.withdrawals(id) on delete restrict,
  entry_type text not null check(entry_type in ('sale_credit','reversal_debit','withdrawal_debit')),
  amount_eur numeric(12,2) not null check(amount_eur<>0),
  reason text not null,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now()
);
create unique index if not exists payment_ledger_sale_credit_key on public.payment_financial_ledger(payment_id) where entry_type='sale_credit';
create unique index if not exists payment_ledger_reversal_key on public.payment_financial_ledger(payment_id) where entry_type='reversal_debit';
create unique index if not exists payment_ledger_withdrawal_key on public.payment_financial_ledger(withdrawal_id) where entry_type='withdrawal_debit';
create index if not exists payment_ledger_seller_created_idx on public.payment_financial_ledger(seller_id,created_at desc);

create table if not exists public.payment_admin_notes (
  id uuid primary key default gen_random_uuid(),
  payment_id uuid not null references public.payment_records(id) on delete cascade,
  admin_id uuid not null references public.profiles(id),
  note text not null,
  created_at timestamptz not null default now()
);
create index if not exists payment_admin_notes_payment_idx on public.payment_admin_notes(payment_id,created_at desc);

alter table public.central_receipts enable row level security;
alter table public.payment_financial_ledger enable row level security;
alter table public.payment_admin_notes enable row level security;

drop policy if exists central_receipts_admin_select on public.central_receipts;
create policy central_receipts_admin_select on public.central_receipts for select to authenticated using(public.is_admin());
drop policy if exists central_receipts_admin_insert on public.central_receipts;
create policy central_receipts_admin_insert on public.central_receipts for insert to authenticated with check(public.is_admin());
drop policy if exists central_receipts_no_update on public.central_receipts;
create policy central_receipts_no_update on public.central_receipts for update to authenticated using(false) with check(false);
drop policy if exists central_receipts_no_delete on public.central_receipts;
create policy central_receipts_no_delete on public.central_receipts for delete to authenticated using(false);

drop policy if exists payment_ledger_own_select on public.payment_financial_ledger;
create policy payment_ledger_own_select on public.payment_financial_ledger for select to authenticated using(seller_id=auth.uid() or public.is_admin());
drop policy if exists payment_ledger_no_write on public.payment_financial_ledger;
create policy payment_ledger_no_write on public.payment_financial_ledger for all to authenticated using(false) with check(false);

drop policy if exists payment_admin_notes_admin_select on public.payment_admin_notes;
create policy payment_admin_notes_admin_select on public.payment_admin_notes for select to authenticated using(public.is_admin());
drop policy if exists payment_admin_notes_admin_insert on public.payment_admin_notes;
create policy payment_admin_notes_admin_insert on public.payment_admin_notes for insert to authenticated with check(public.is_admin());
drop policy if exists payment_admin_notes_no_update on public.payment_admin_notes;
create policy payment_admin_notes_no_update on public.payment_admin_notes for update to authenticated using(false) with check(false);
drop policy if exists payment_admin_notes_no_delete on public.payment_admin_notes;
create policy payment_admin_notes_no_delete on public.payment_admin_notes for delete to authenticated using(false);

-- Comprovantes: bucket privado, 10 MB e quatro MIME types.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('payment-proofs','payment-proofs',false,10485760,array['image/jpeg','image/png','image/webp','application/pdf'])
on conflict(id) do update set public=false,file_size_limit=10485760,allowed_mime_types=excluded.allowed_mime_types;

drop policy if exists payment_proofs_upload_own on storage.objects;
create policy payment_proofs_upload_own on storage.objects for insert to authenticated
with check(bucket_id='payment-proofs' and (storage.foldername(name))[1]=(select auth.uid()::text));

drop policy if exists payment_proofs_read_seller_or_admin on storage.objects;
create policy payment_proofs_read_seller_or_admin on storage.objects for select to authenticated
using(bucket_id='payment-proofs' and ((storage.foldername(name))[1]=(select auth.uid()::text) or public.is_admin()));

drop policy if exists payment_proofs_no_update on storage.objects;
create policy payment_proofs_no_update on storage.objects for update to authenticated using(false) with check(false);

drop policy if exists payment_proofs_delete_own_pending on storage.objects;
create policy payment_proofs_delete_own_pending on storage.objects for delete to authenticated
using(bucket_id='payment-proofs' and (storage.foldername(name))[1]=(select auth.uid()::text));

create or replace function public.create_payment_submission(
  p_gross_amount_eur numeric,
  p_payment_method text,
  p_reference text,
  p_order_id text,
  p_notes text,
  p_idempotency_key text
)
returns public.payment_records
language plpgsql security definer set search_path=''
as $$
declare
  s public.platform_settings;
  result public.payment_records;
  fee numeric;
begin
  if not exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='seller' and p.status='active') then raise exception 'Conta de vendedor indisponível'; end if;
  if p_gross_amount_eur is null or p_gross_amount_eur<=0 then raise exception 'O valor recebido deve ser maior que zero'; end if;
  if p_payment_method not in ('mbway','iban') then raise exception 'Método de pagamento inválido'; end if;
  if nullif(trim(p_idempotency_key),'') is null then raise exception 'Identificador de envio ausente'; end if;
  select * into s from public.platform_settings where id=1;
  if s.initialized_at is null then raise exception 'As configurações de recebimento ainda não foram salvas'; end if;
  select * into result from public.payment_records where seller_id=auth.uid() and idempotency_key=p_idempotency_key limit 1;
  if result.id is not null then return result; end if;
  fee:=round(p_gross_amount_eur*s.platform_fee_percent/100,2);
  insert into public.payment_records(
    seller_id,gross_amount_eur,fee_percent_snapshot,fee_amount_eur,net_amount_eur,status,reference,
    currency,payment_method,order_id,notes,mbway_phone_snapshot,central_iban_snapshot,idempotency_key
  ) values(
    auth.uid(),round(p_gross_amount_eur,2),s.platform_fee_percent,fee,round(p_gross_amount_eur-fee,2),'pending',
    nullif(trim(p_reference),''),'EUR',p_payment_method,nullif(trim(p_order_id),''),nullif(trim(p_notes),''),
    s.mbway_phone,s.central_iban,p_idempotency_key
  ) returning * into result;
  insert into public.audit_logs(actor_id,action,metadata)
  values(auth.uid(),'payment.submitted',jsonb_build_object('payment_id',result.id,'payment_code',result.payment_code,'gross_amount_eur',result.gross_amount_eur));
  return result;
exception when unique_violation then
  select * into result from public.payment_records where seller_id=auth.uid() and idempotency_key=p_idempotency_key limit 1;
  if result.id is not null then return result; end if;
  raise;
end;
$$;
revoke all on function public.create_payment_submission(numeric,text,text,text,text,text) from public;
grant execute on function public.create_payment_submission(numeric,text,text,text,text,text) to authenticated;

create or replace function public.finalize_payment_submission(
  p_payment_id uuid,
  p_proof_path text,
  p_proof_mime_type text,
  p_proof_size_bytes bigint
)
returns public.payment_records
language plpgsql security definer set search_path=''
as $$
declare result public.payment_records;
begin
  if p_proof_mime_type not in ('image/jpeg','image/png','image/webp','application/pdf') then raise exception 'Formato de comprovante não permitido'; end if;
  if p_proof_size_bytes is null or p_proof_size_bytes<=0 or p_proof_size_bytes>10485760 then raise exception 'O comprovante deve ter até 10 MB'; end if;
  if p_proof_path is null or (storage.foldername(p_proof_path))[1]<>(select auth.uid()::text) then raise exception 'Comprovante inválido'; end if;
  update public.payment_records
  set proof_path=p_proof_path,proof_mime_type=p_proof_mime_type,proof_size_bytes=p_proof_size_bytes
  where id=p_payment_id and seller_id=auth.uid() and status='pending' and proof_path is null
  returning * into result;
  if result.id is null then
    select * into result from public.payment_records where id=p_payment_id and seller_id=auth.uid();
    if result.id is null then raise exception 'Lançamento não encontrado'; end if;
    if result.proof_path is null then raise exception 'Não foi possível finalizar o envio'; end if;
  end if;
  return result;
end;
$$;
revoke all on function public.finalize_payment_submission(uuid,text,text,bigint) from public;
grant execute on function public.finalize_payment_submission(uuid,text,text,bigint) to authenticated;

create or replace function public.cleanup_failed_payment_submission(p_payment_id uuid)
returns boolean language plpgsql security definer set search_path=''
as $$
declare removed boolean;
begin
  delete from public.payment_records where id=p_payment_id and seller_id=auth.uid() and status='pending' and proof_path is null returning true into removed;
  return coalesce(removed,false);
end;
$$;
revoke all on function public.cleanup_failed_payment_submission(uuid) from public;
grant execute on function public.cleanup_failed_payment_submission(uuid) to authenticated;

create or replace function public.admin_add_payment_note(p_payment_id uuid,p_note text)
returns public.payment_admin_notes language plpgsql security definer set search_path=''
as $$
declare result public.payment_admin_notes;
begin
  if not public.is_admin() then raise exception 'Acesso negado'; end if;
  if nullif(trim(p_note),'') is null then raise exception 'A anotação não pode estar vazia'; end if;
  insert into public.payment_admin_notes(payment_id,admin_id,note) values(p_payment_id,auth.uid(),trim(p_note)) returning * into result;
  insert into public.audit_logs(actor_id,action,metadata) values(auth.uid(),'payment.note_added',jsonb_build_object('payment_id',p_payment_id));
  return result;
end;
$$;
revoke all on function public.admin_add_payment_note(uuid,text) from public;
grant execute on function public.admin_add_payment_note(uuid,text) to authenticated;

create or replace function public.admin_reject_payment(p_payment_id uuid,p_reason text)
returns public.payment_records language plpgsql security definer set search_path=''
as $$
declare result public.payment_records;
begin
  if not public.is_admin() then raise exception 'Acesso negado'; end if;
  if nullif(trim(p_reason),'') is null then raise exception 'O motivo da rejeição é obrigatório'; end if;
  update public.payment_records set status='rejected',decision_reason=trim(p_reason),decided_by=auth.uid(),updated_at=now()
  where id=p_payment_id and status in ('pending','under_review') returning * into result;
  if result.id is null then raise exception 'O lançamento já foi decidido ou não existe'; end if;
  insert into public.audit_logs(actor_id,action,metadata) values(auth.uid(),'payment.rejected',jsonb_build_object('payment_id',result.id,'reason',result.decision_reason));
  return result;
end;
$$;
revoke all on function public.admin_reject_payment(uuid,text) from public;
grant execute on function public.admin_reject_payment(uuid,text) to authenticated;

create or replace function public.admin_escalate_payment(p_payment_id uuid,p_reason text)
returns public.payment_records language plpgsql security definer set search_path=''
as $$
declare result public.payment_records;
begin
  if not public.is_admin() then raise exception 'Acesso negado'; end if;
  if nullif(trim(p_reason),'') is null then raise exception 'O motivo da análise adicional é obrigatório'; end if;
  update public.payment_records set status='under_review',risk_reason=trim(p_reason),updated_at=now()
  where id=p_payment_id and status='pending' returning * into result;
  if result.id is null then raise exception 'O lançamento não está aguardando análise'; end if;
  insert into public.audit_logs(actor_id,action,metadata) values(auth.uid(),'payment.escalated',jsonb_build_object('payment_id',result.id,'reason',result.risk_reason));
  return result;
end;
$$;
revoke all on function public.admin_escalate_payment(uuid,text) from public;
grant execute on function public.admin_escalate_payment(uuid,text) to authenticated;

create or replace function public.admin_approve_payment(
  p_payment_id uuid,
  p_receipt_id uuid default null,
  p_new_receipt_reference text default null,
  p_new_receipt_at timestamptz default null,
  p_new_receipt_amount_eur numeric default null,
  p_new_receipt_method text default null,
  p_new_receipt_observation text default null
)
returns public.payment_records language plpgsql security definer set search_path=''
as $$
declare
  payment_row public.payment_records;
  receipt_row public.central_receipts;
  result public.payment_records;
begin
  if not public.is_admin() then raise exception 'Acesso negado'; end if;
  select * into payment_row from public.payment_records where id=p_payment_id for update;
  if payment_row.id is null then raise exception 'Lançamento não encontrado'; end if;
  if payment_row.status not in ('pending','under_review') then raise exception 'O lançamento já foi decidido'; end if;

  if p_receipt_id is not null then
    select * into receipt_row from public.central_receipts where id=p_receipt_id for update;
    if receipt_row.id is null then raise exception 'Recebimento não encontrado'; end if;
  else
    if nullif(trim(p_new_receipt_reference),'') is null or p_new_receipt_amount_eur is null or p_new_receipt_method is null then
      raise exception 'Selecione um recebimento existente ou informe os dados do recebimento real';
    end if;
    if p_new_receipt_amount_eur<>payment_row.gross_amount_eur then raise exception 'O valor do recebimento real deve ser exatamente igual ao valor da venda'; end if;
    if p_new_receipt_method<>payment_row.payment_method then raise exception 'O método do recebimento real deve ser igual ao método da venda'; end if;
    insert into public.central_receipts(receipt_reference,received_at,amount_eur,payment_method,observation,seller_id,payment_id,created_by)
    values(trim(p_new_receipt_reference),coalesce(p_new_receipt_at,now()),p_new_receipt_amount_eur,p_new_receipt_method,p_new_receipt_observation,payment_row.seller_id,payment_row.id,auth.uid())
    returning * into receipt_row;
  end if;

  if receipt_row.payment_id is not null and receipt_row.payment_id<>payment_row.id then raise exception 'Este recebimento já está vinculado a outra venda'; end if;
  if receipt_row.amount_eur<>payment_row.gross_amount_eur or receipt_row.payment_method<>payment_row.payment_method then raise exception 'Recebimento incompatível com a venda'; end if;
  if receipt_row.payment_id is null then update public.central_receipts set payment_id=payment_row.id,seller_id=payment_row.seller_id where id=receipt_row.id; end if;

  update public.payment_records
  set status='approved',approved_at=now(),receipt_id=receipt_row.id,decided_by=auth.uid(),updated_at=now()
  where id=payment_row.id returning * into result;

  insert into public.payment_financial_ledger(seller_id,payment_id,entry_type,amount_eur,reason,created_by)
  values(payment_row.seller_id,payment_row.id,'sale_credit',payment_row.net_amount_eur,'Venda aprovada após conferência do recebimento real',auth.uid());

  insert into public.audit_logs(actor_id,action,metadata)
  values(auth.uid(),'payment.approved',jsonb_build_object('payment_id',payment_row.id,'receipt_id',receipt_row.id,'gross_amount_eur',payment_row.gross_amount_eur,'fee_percent',payment_row.fee_percent_snapshot,'net_amount_eur',payment_row.net_amount_eur));
  return result;
exception when unique_violation then
  raise exception 'Esta venda ou recebimento já foi processado por outro administrador';
end;
$$;
revoke all on function public.admin_approve_payment(uuid,uuid,text,timestamptz,numeric,text,text) from public;
grant execute on function public.admin_approve_payment(uuid,uuid,text,timestamptz,numeric,text,text) to authenticated;

create or replace function public.admin_reverse_payment(p_payment_id uuid,p_reason text)
returns public.payment_records language plpgsql security definer set search_path=''
as $$
declare payment_row public.payment_records;result public.payment_records;
begin
  if not public.is_admin() then raise exception 'Acesso negado'; end if;
  if nullif(trim(p_reason),'') is null then raise exception 'O motivo do estorno é obrigatório'; end if;
  select * into payment_row from public.payment_records where id=p_payment_id for update;
  if payment_row.id is null or payment_row.status<>'approved' then raise exception 'Somente vendas aprovadas podem ser estornadas'; end if;
  if exists(select 1 from public.payment_financial_ledger where payment_id=p_payment_id and entry_type='reversal_debit') then raise exception 'Esta venda já foi estornada'; end if;
  update public.payment_records set status='estornado',decision_reason=trim(p_reason),decided_by=auth.uid(),updated_at=now() where id=p_payment_id returning * into result;
  insert into public.payment_financial_ledger(seller_id,payment_id,entry_type,amount_eur,reason,created_by)
  values(payment_row.seller_id,payment_row.id,'reversal_debit',-payment_row.net_amount_eur,trim(p_reason),auth.uid());
  insert into public.audit_logs(actor_id,action,metadata) values(auth.uid(),'payment.reversed',jsonb_build_object('payment_id',payment_row.id,'reason',trim(p_reason),'net_amount_eur',payment_row.net_amount_eur));
  return result;
end;
$$;
revoke all on function public.admin_reverse_payment(uuid,text) from public;
grant execute on function public.admin_reverse_payment(uuid,text) to authenticated;

create or replace function public.get_seller_dashboard(p_start timestamptz default null,p_end timestamptz default null)
returns table(available_balance_eur numeric,pending_balance_eur numeric,approved_volume_eur numeric,at_risk_eur numeric,reserved_withdrawals_eur numeric)
language sql security invoker set search_path=''
as $$
select
 coalesce((select sum(l.amount_eur) from public.payment_financial_ledger l where l.seller_id=auth.uid()),0)
 - coalesce((select sum(w.amount_eur+w.fixed_fee_snapshot_eur) from public.withdrawals w where w.seller_id=auth.uid() and w.status in ('requested','approved')),0),
 coalesce((select sum(p.gross_amount_eur) from public.payment_records p where p.seller_id=auth.uid() and p.status='pending'),0),
 coalesce((select sum(p.gross_amount_eur) from public.payment_records p where p.seller_id=auth.uid() and p.status='approved' and (p_start is null or p.created_at>=p_start) and (p_end is null or p.created_at<p_end)),0)
 - coalesce((select sum(p.gross_amount_eur) from public.payment_records p where p.seller_id=auth.uid() and p.status='estornado' and (p_start is null or p.created_at>=p_start) and (p_end is null or p.created_at<p_end)),0),
 coalesce((select sum(p.gross_amount_eur) from public.payment_records p where p.seller_id=auth.uid() and p.status='under_review'),0),
 coalesce((select sum(w.amount_eur+w.fixed_fee_snapshot_eur) from public.withdrawals w where w.seller_id=auth.uid() and w.status in ('requested','approved')),0);
$$;
revoke all on function public.get_seller_dashboard(timestamptz,timestamptz) from public;
grant execute on function public.get_seller_dashboard(timestamptz,timestamptz) to authenticated;

do $$ begin
 if exists(select 1 from pg_publication where pubname='supabase_realtime') then
  if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='central_receipts') then execute 'alter publication supabase_realtime add table public.central_receipts'; end if;
  if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='payment_financial_ledger') then execute 'alter publication supabase_realtime add table public.payment_financial_ledger'; end if;
 end if;
end $$;

