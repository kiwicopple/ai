/* 
  --------------------------------------------
  PROFILES
  --------------------------------------------

  Logic:
  - Users should be able to see their own profile
  - Users should be able to see the profiles of all members of all the organizations they belong to

  Interface:
  - public.profiles: view -> List of all the profiles the user has access to
*/


/* 
  --------------------------------------------
  View
  --------------------------------------------
*/

create or replace view "public"."profiles" 
with (security_invoker = true)
as
select
  "auth"."users"."id" as "id",
  "auth"."users"."email" as "email",
  "profiles"."username",
  "profiles"."first_name",
  "profiles"."last_name",
  coalesce("full_name", "first_name" || ' ' || "last_name") as "full_name"
from 
  "auth"."users"
  left join "private"."profiles" on "auth"."users"."id" = "private"."profiles"."id"
where 
  "auth"."users"."id" in (select * from public.colleagues())
;

-- Grant access to the underlying tables for the view to work
grant select on "auth"."users" to "authenticated";
grant select on "private"."profiles" to "authenticated";

drop policy if exists "SELECT: authenticated" on auth.users;
create policy         "SELECT: authenticated" on auth.users
  for select 
  to authenticated
  using ( id in (select * from public.colleagues()) );

drop policy if exists "SELECT: authenticated" on private.profiles;
create policy         "SELECT: authenticated" on private.profiles
  for select
  to authenticated
  using ( id in (select * from public.colleagues()) );

