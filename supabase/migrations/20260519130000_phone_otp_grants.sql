-- Edge Functions use service_role to store OTP rows.
grant select, insert, update, delete on table public.phone_verification_attempts to service_role;
