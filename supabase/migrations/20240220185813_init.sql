create schema if not exists "private";
grant usage on schema "private" to "authenticated"; -- Don't expose to PostgREST, but we still need to grant access to the schema

create table "private"."profiles" (
  "id" uuid primary key references "auth"."users"("id"),
  "username" text, -- Public username
  "first_name" text, 
  "last_name" text,
  "full_name" text, -- null means not specified by user

  unique ("username"),
  constraint "username_length" check (length("username") <= 40)
);
alter table "private"."profiles" enable row level security;

-- An organization of users
create table "private"."organizations" (
  "id" text primary key default 'org_' || utils.ksuid(),
  "name" text not null,
  "updated_at" timestamptz default timezone('utc'::text, now()) not null,
  "created_by" uuid not null references "auth"."users"("id"),

  -- Constraints
  constraint "id_prefix" check ("id" like 'org_%'), -- Enforce ID format
  constraint "id_length" check (length("id") <= 80)
);
-- Enable RLS
alter table "private"."organizations" enable row level security;

create table "private"."members" (
  "id" uuid primary key default gen_random_uuid(),
  "organization_id" text not null references "private"."organizations"("id"),
  "user_id" uuid not null references "auth"."users"("id"),
  "role" text not null default 'member' check ("role" in ('owner', 'admin', 'developer', 'billing'))
);
-- Enable RLS
alter table "private"."members" enable row level security;


create table "private"."keys" (
  "id" text primary key default 'sk_' || utils.ksuid(),
  "updated_at" timestamptz default timezone('utc'::text, now()) not null,
  "organization_id" text not null references "private"."organizations"("id"),
  "owner_id" uuid references "auth"."users"("id"),
  "active" boolean default true not null,

  -- Constraints
  constraint "id_prefix" check ("id" like 'sk_%'), -- Enforce ID format
  constraint "key_length" check (length("id") <= 80)
);
-- Enable RLS
alter table "private"."keys" enable row level security;

create table "private"."requests" (
  "id" uuid primary key default gen_random_uuid(),
  "updated_at" timestamptz default timezone('utc'::text, now()) not null,
  "organization_id" text not null references "private"."organizations"("id"),
  "key_id" text not null references "private"."keys"("id"),
  "model" text,
  "input" jsonb,
  "response" jsonb,
  "feedback" jsonb
);
-- Enable RLS
alter table "private"."requests" enable row level security;

