
-- Fix: avoid PL/pgSQL record-variable shadowing in partner settlement aggregates.
create or replace function public.create_partner_settlement(
  p_beneficiary_id uuid,p_amount_eur numeric,p_settlement_date timestamptz,p_settlement_method text,
  p_reference text,p_proof_path text,p_observation text
)
returns public.partner_settlements language plpgsql security definer set search_path=''
as $function$
declare result public.partner_settlements;remaining numeric:=round(p_amount_eur,2);pending numeric;entry_rec record;available numeric;allocation numeric;
begin
  if not public.is_superadmin() then raise exception 'Somente o superadministrador pode registrar acertos de Sócios'; end if;
  if p_amount_eur is null or p_amount_eur<=0 then raise exception 'O valor do acerto deve ser maior que zero'; end if;
  if p_settlement_method not in('transfer','central_retention') then raise exception 'Forma de acerto inválida'; end if;
  if p_settlement_method='transfer' and nullif(trim(coalesce(p_reference,'')),'') is null and nullif(trim(coalesce(p_proof_path,'')),'') is null then raise exception 'Transferência exige referência ou comprovante'; end if;
  if nullif(trim(coalesce(p_proof_path,'')),'') is not null and not exists(select 1 from storage.objects so where so.bucket_id='partner-settlement-proofs' and so.name=trim(p_proof_path)) then raise exception 'O comprovante informado não foi encontrado no armazenamento privado'; end if;
  perform 1 from public.profiles where id=p_beneficiary_id and role='seller' for update;
  if not found then raise exception 'Sócio não encontrado'; end if;
  pending:=round(
    coalesce((select sum(pe.amount_eur) from public.partner_entries pe where pe.beneficiary_id=p_beneficiary_id),0)
    +coalesce((select sum(pa.amount_eur) from public.partner_adjustments pa where pa.beneficiary_id=p_beneficiary_id),0)
    -coalesce((select sum(ps.amount_eur) from public.partner_settlements ps where ps.beneficiary_id=p_beneficiary_id),0)
  ,2);
  if pending<=0 then raise exception 'Não há saldo positivo pendente para este Sócio'; end if;
  if p_amount_eur>pending then raise exception 'O acerto excede o saldo positivo pendente de %.',pending; end if;
  insert into public.partner_settlements(beneficiary_id,amount_eur,settlement_date,settlement_method,reference,proof_path,observation,created_by)
  values(p_beneficiary_id,round(p_amount_eur,2),coalesce(p_settlement_date,now()),p_settlement_method,nullif(trim(p_reference),''),nullif(trim(p_proof_path),''),nullif(trim(p_observation),''),auth.uid())
  returning * into result;
  for entry_rec in
    select pe.id,greatest(0,round(
      pe.amount_eur
      +coalesce((select sum(pa.amount_eur) from public.partner_adjustments pa where pa.partner_entry_id=pe.id),0)
      -coalesce((select sum(sa.amount_eur) from public.partner_settlement_allocations sa where sa.partner_entry_id=pe.id),0)
    ,2)) as available
    from public.partner_entries pe
    where pe.beneficiary_id=p_beneficiary_id
    order by pe.created_at,pe.id
    for update
  loop
    exit when remaining<=0;
    available:=entry_rec.available;
    if available>0 then
      allocation:=least(remaining,available);
      insert into public.partner_settlement_allocations(settlement_id,partner_entry_id,amount_eur)
      values(result.id,entry_rec.id,allocation);
      remaining:=round(remaining-allocation,2);
    end if;
  end loop;
  if remaining<>0 then raise exception 'Não foi possível alocar integralmente o acerto'; end if;
  insert into public.audit_logs(actor_id,target_user_id,action,metadata)
  values(auth.uid(),p_beneficiary_id,'partner.settlement_created',jsonb_build_object('settlement_id',result.id,'amount_eur',result.amount_eur,'method',result.settlement_method,'reference',result.reference));
  return result;
end $function$;
