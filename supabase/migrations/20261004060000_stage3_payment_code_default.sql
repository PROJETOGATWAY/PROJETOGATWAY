-- Etapa 3: identificador único gerado no servidor
alter table public.payment_records
  alter column payment_code set default ('PAY-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,12)));
