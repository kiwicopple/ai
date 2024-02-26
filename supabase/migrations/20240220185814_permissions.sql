/* 
  --------------------------------------------
  PERMISSIONS
  --------------------------------------------

  A set of idempotent functions and views to manage permissions and access control lists.

  - is_member_of(): boolean     -> Check if a user is a member of an organization
  - belongs_to(): setof text    -> Get all the organizations a user belongs to
  - colleagues(): setof uuid    -> A list of all the users in the same organizations as the user
  - permissions: view           -> View of all permissions (useful as an ACL)
*/



/* 
  --------------------------------------------
  is_member_of()
  --------------------------------------------
*/

create or replace function "private"."is_member_of" (
  "organization_id" text,
  "requested_user_id" uuid
)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from "private"."members"
    where "organization_id" = "organization_id"
    and "user_id" = "requested_user_id"
  );
$$;
grant execute on function "private"."is_member_of"(text, uuid) to "authenticated";


create or replace function "public"."is_member_of" (
  "organization_id" text
)
returns boolean
security definer
language sql
stable
as $$
  select * 
  from private.is_member_of(organization_id, auth.uid());
$$;


/* 
  --------------------------------------------
  belongs_to()
  --------------------------------------------
*/

create or replace function "private"."belongs_to" (
  "requested_user_id" uuid
)
returns setof text
language sql
stable
as $$
  select distinct "organization_id" 
  from "private"."members"
  where "user_id" = "requested_user_id";
$$;
grant execute on function "private"."belongs_to"(uuid) to "authenticated";


create or replace function "public"."belongs_to" ()
returns setof text
security definer
language sql
stable
as $$
  select * 
  from private.belongs_to(auth.uid());
$$;


/* 
  --------------------------------------------
  colleagues()
  --------------------------------------------
*/


create or replace function "private"."colleagues" (
  "requested_user_id" uuid
)
returns setof uuid
language sql
stable
as $$
  select distinct "user_id"
  from "private"."members"
  where "organization_id" in (
    select * from private.belongs_to("requested_user_id") -- we include the calling user because it's simpler to exclude them in requesting functions than to include them
  ); 
$$;
grant execute on function "private"."colleagues"(uuid) to "authenticated";


create or replace function "public"."colleagues" ()
returns setof uuid
security definer
language sql
stable
as $$
  select * 
  from private.colleagues(auth.uid());
$$;


/* 
  --------------------------------------------
  View: permissions
  --------------------------------------------
*/

create or replace view "private"."permissions"
as
select
  "members"."id" as "permission_id",
  "members"."user_id",
  "members"."role",
  "members"."organization_id",
  "organizations"."name"
from "private"."members"
left join "private"."organizations" on "members"."organization_id" = "organizations"."id"
;

create or replace view "public"."permissions"
as
select *
from "private"."permissions"
where "organization_id" in (select * from belongs_to());
grant select on "public"."permissions" to "authenticated";
