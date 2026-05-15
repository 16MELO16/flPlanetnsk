-- 007_add_customer_email.sql

alter table orders add column if not exists customer_email text default '';

alter table orders drop constraint if exists customer_email_format;

alter table orders add constraint customer_email_format
  check (
    customer_email = '' or
    (customer_email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' and char_length(customer_email) <= 200)
  );
