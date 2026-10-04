alter table public.withdrawal_methods alter column tax_id drop not null;
alter table public.withdrawal_methods drop constraint if exists withdrawal_methods_pix_fields;
alter table public.withdrawal_methods add constraint withdrawal_methods_pix_fields check ((method_type='pix' and pix_key_type is not null and pix_key is not null and tax_id is not null and iban is null) or method_type in ('iban','revolut'));
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
