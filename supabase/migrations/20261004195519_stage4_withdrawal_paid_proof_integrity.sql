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
 if p_payment_proof_path not like result.seller_id::text || '/' || result.id::text || '/%' then raise exception 'Comprovante inválido para este saque'; end if;
 if not exists(select 1 from storage.objects where bucket_id='withdrawal-proofs' and name=p_payment_proof_path) then raise exception 'O comprovante não foi encontrado no armazenamento privado'; end if;
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