/* 
  --------------------------------------------
  KEYS
  --------------------------------------------

  Logic:
  - Users should be able to see keys in any of the organizations they belong to

  Interface:
  - public.keys: view -> List of all the profiles the user has access to
*/


/* 
  --------------------------------------------
  View
  --------------------------------------------
*/

create view "public"."requests" 
with ( security_invoker = true )
as
select
  "id",
  "updated_at",
  "organization_id",
  "key_id",
  "model",
  "input",
  "response",
  "feedback"
from "private"."requests"
where "organization_id" in (select * from public.belongs_to());

-- Grant access to the underlying tables for the view to work
grant select on "private"."requests" to "authenticated";

drop policy if exists "SELECT: authenticated" on "private"."requests";
create policy         "SELECT: authenticated" on "private"."requests"
  for select 
  to authenticated
  using ( organization_id in (select * from public.belongs_to()) );
