DO $SEED$
DECLARE 
   user_luke_skywalker      auth.users%ROWTYPE;
   user_leia_organa         auth.users%ROWTYPE;
   user_darth_vader         auth.users%ROWTYPE;
   org_tatooine             private.organizations%ROWTYPE;
   org_alderine             private.organizations%ROWTYPE;
   org_death_star           private.organizations%ROWTYPE;
   key_tatooine_01          private.keys%ROWTYPE;
   key_tatooine_02          private.keys%ROWTYPE;
   key_alderine_01          private.keys%ROWTYPE;
BEGIN  

-- USERS
insert into "auth"."users" ("id", "email") values ('78258479-f7af-4741-ae82-1d42556221eb', 'luke@example.com') returning * into user_luke_skywalker;
insert into "auth"."users" ("id", "email") values ('78258479-f7af-4741-ae82-1d42556221ec', 'leia@example.com') returning * into user_leia_organa;
insert into "auth"."users" ("id", "email") values ('78258479-f7af-4741-ae82-1d42556221ed', 'darth@example.com') returning * into user_darth_vader;

-- PROFILES
insert into "private"."profiles" ("id", "first_name", "last_name") values (user_luke_skywalker.id, 'Luke', 'Skywalker');
insert into "private"."profiles" ("id", "first_name", "last_name") values (user_darth_vader.id, 'Darth', 'Vader');

-- ORGANIZATIONS
select * from "private"."create_organization" ('Tatooine', user_luke_skywalker.id) into org_tatooine;
select * from "private"."create_organization" ('Alterine', user_leia_organa.id) into org_alderine;
select * from "private"."create_organization" ('Death Star', user_darth_vader.id) into org_death_star;

-- TEAMS
insert into "private"."members" ("organization_id", "user_id", "role") values (org_tatooine.id, user_leia_organa.id, 'admin');

-- KEYS
insert into "private"."keys" ("organization_id") values (org_tatooine.id) returning * into key_tatooine_01;
insert into "private"."keys" ("organization_id") values (org_tatooine.id) returning * into key_tatooine_02;
insert into "private"."keys" ("organization_id") values (org_alderine.id) returning * into key_alderine_01;


END $SEED$