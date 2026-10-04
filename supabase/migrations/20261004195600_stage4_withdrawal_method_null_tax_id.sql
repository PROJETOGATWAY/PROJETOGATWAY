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