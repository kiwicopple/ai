/* 
  --------------------------------------------
  ORGANIZATIONS
  --------------------------------------------

  Logic:
  - Users should be able to see all the organizations they belong to
  - Users should be able to see all members of all the organizations they belong to

  Interface:
  - public.organizations: view -> List of all the organizations the user belongs to
  - public.create_organization(): organization -> Creates an organization and inserts the user as the owner in the "members" table
*/


/* 
  --------------------------------------------
  View
  --------------------------------------------
*/

create or replace view "public"."organizations" 
with (security_invoker = true)
as
select
  "id",
  "name",
  "updated_at"
from "private"."organizations"
where "id" in (select * from public.belongs_to());
;

grant select on "private"."organizations" to "authenticated";

drop policy if exists "SELECT: individual" on private.organizations;
create policy         "SELECT: individual" on private.organizations
  for select
  to authenticated
  using ( public.is_member_of(id) );

/* 
  --------------------------------------------
  create_organization()
  --------------------------------------------
*/

-- Private interface
create or replace function "private"."create_organization" (
  "name" text,
  "owner_id" uuid default auth.uid()
) 
returns "private"."organizations" 
security definer
language plpgsql
as $$
declare
  "new_organization" "private"."organizations"%rowtype;
begin
  insert into "private"."organizations" ("name", "created_by") values ("name", "owner_id") returning * into "new_organization";
  insert into "private"."members" ("organization_id", "user_id", "role") values ("new_organization"."id", "owner_id", 'owner');
  return "new_organization";
end $$;


-- Public interface
create or replace function "public"."create_organization" (
  "name" text
) 
returns "private"."organizations"
security invoker
language plpgsql
as $$
declare
  "new_organization" "private"."organizations"%rowtype;
begin
  select * into "new_organization" from "private"."create_organization"("name", auth.uid());
  return "new_organization";
end $$;




