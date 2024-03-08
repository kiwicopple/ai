/* 
  --------------------------------------------
  KEYS
  --------------------------------------------

  Logic:
  - Users should be able to see keys in any of the organizations they belong to

  Interface:
  - public.keys: view -> List of all the profiles the user has access to
  - public.validate_key(): function -> Validates a single key, determining if it is active and belongs to the organization
*/


/* 
  --------------------------------------------
  View
  --------------------------------------------
*/

create view "public"."keys" 
with ( security_invoker = true )
as
select
  "id",
  "updated_at",
  "organization_id",
  "active"
from "private"."keys"
where "organization_id" in (select * from public.belongs_to());

-- Grant access to the underlying tables for the view to work
grant select on "private"."keys" to "authenticated";

drop policy if exists "SELECT: authenticated" on "private"."keys";
create policy         "SELECT: authenticated" on "private"."keys"
  for select 
  to authenticated
  using ( organization_id in (select * from public.belongs_to()) );


/* 
  --------------------------------------------
  validate_key()
  --------------------------------------------
*/

create or replace function "public"."validate_key" (
  "key_id" text
)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from "private"."keys"
    where "id" = "key_id"
    and "organization_id" in (select * from private.belongs_to("user_id"))
    and "active" = true
  );
$$;


