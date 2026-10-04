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
