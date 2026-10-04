-- Etapa 3: registro de recebimento real com autoria e auditoria server-side
create or replace function public.admin_create_central_receipt(
  p_reference text,
  p_received_at timestamptz,
  p_amount_eur numeric,
  p_method text,
  p_observation text default null
)
returns public.central_receipts
language plpgsql security definer set search_path=''
as $$
declare result public.central_receipts;
begin
 if not public.is_admin() then raise exception 'Acesso negado'; end if;
 if nullif(trim(p_reference),'') is null then raise exception 'A referência do recebimento é obrigatória'; end if;
 if p_amount_eur is null or p_amount_eur<=0 then raise exception 'O valor do recebimento deve ser maior que zero'; end if;
 if p_method not in ('mbway','iban') then raise exception 'Método de recebimento inválido'; end if;
 insert into public.central_receipts(receipt_reference,received_at,amount_eur,payment_method,observation,created_by)
 values(trim(p_reference),coalesce(p_received_at,now()),round(p_amount_eur,2),p_method,nullif(trim(p_observation),''),auth.uid())
 returning * into result;
 insert into public.audit_logs(actor_id,action,metadata)
 values(auth.uid(),'central_receipt.created',jsonb_build_object('receipt_id',result.id,'reference',result.receipt_reference,'amount_eur',result.amount_eur,'payment_method',result.payment_method,'received_at',result.received_at));
 return result;
exception when unique_violation then
 raise exception 'A referência do recebimento já existe';
end;
$$;
revoke all on function public.admin_create_central_receipt(text,timestamptz,numeric,text,text) from anon;
grant execute on function public.admin_create_central_receipt(text,timestamptz,numeric,text,text) to authenticated;
