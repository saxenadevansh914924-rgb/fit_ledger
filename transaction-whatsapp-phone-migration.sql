-- Run in Supabase Dashboard > SQL Editor.
-- Stores the WhatsApp recipient on each money transaction so repayment can
-- reuse the original number without asking for it again.
alter table public.transactions
  add column if not exists whatsapp_phone text;
alter table public.transactions
  add column if not exists receipt_note text,
  add column if not exists settlement_receipt_note text;
alter table public.transactions
  add column if not exists repaid_amount numeric(12,2) not null default 0,
  add column if not exists last_repayment_amount numeric(12,2),
  add column if not exists last_repaid_on date;
alter table public.transactions
  add column if not exists repayment_history jsonb not null default '[]'::jsonb;

-- Older loans that were already marked fully returned are fully repaid.
update public.transactions
set repaid_amount = amount,
    last_repayment_amount = coalesce(last_repayment_amount, amount),
    last_repaid_on = coalesce(last_repaid_on, settled_on),
    repayment_history = case
      when jsonb_array_length(repayment_history) = 0 and settled_on is not null
        then jsonb_build_array(jsonb_build_object('amount', amount, 'paid_on', settled_on))
      else repayment_history
    end
where is_settled = true and repaid_amount = 0;

-- Bring forward numbers saved by the earlier contact-directory version, if
-- that optional table exists in this project.
do $$
begin
  if to_regclass('public.person_contacts') is not null then
    execute $migration$
      update public.transactions t
      set whatsapp_phone = c.phone
      from public.person_contacts c
      where t.user_id = c.user_id
        and lower(trim(t.person)) = c.person_key
        and t.whatsapp_phone is null
    $migration$;
  end if;
end
$$;
