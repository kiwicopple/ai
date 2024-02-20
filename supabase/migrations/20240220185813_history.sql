
create table history (
  id uuid primary key default gen_random_uuid(),
  inserted_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  tenant_id uuid not null,
  model text,
  input jsonb,
  response jsonb,
  feedback
);