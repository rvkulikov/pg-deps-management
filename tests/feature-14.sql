-- @see https://github.com/rvkulikov/pg-deps-management/issues/14
-- Grantee of a access right is not recorded

drop schema if exists util cascade;
create schema util;

create or replace function util.__assert(condition boolean, message text) returns void as $$
begin
  if not condition then
    raise exception 'Asserting failed: %', message;
  end if;
end;
$$ language plpgsql;

do $$ begin
  create role "feature14_grantor1";
exception
  when duplicate_object
    then raise notice 'not creating role "feature14_grantor1"';
end $$;
do $$ begin
  create role "feature14_grantor2";
exception
  when duplicate_object
    then raise notice 'not creating role "feature14_grantor2"';
end $$;

drop schema if exists feature14 cascade;
create schema feature14;

delete from public.deps_saved_ddl where true;

create table feature14.table (col_1 text, col_2 text);
create view feature14.view as select * from feature14.table;

select current_user, session_user;
grant usage on schema feature14 to feature14_grantor1;
grant usage on schema feature14 to feature14_grantor2;
grant select, insert, update, delete on feature14.view to feature14_grantor1 with grant option;

set session authorization feature14_grantor1;
select current_user, session_user;

grant select on feature14.view to "feature14_grantor2";

set session authorization default;

select public.deps_save_and_drop_dependencies(
  'feature14',
  'table',
  '{
    "dry_run": false,
    "verbose": true,
    "populate_materialized_view": true
  }'
);

select ddl_order, ddl_operation, ddl_authorization, ddl_grantor, ddl_grantee, ddl_statement from public.deps_saved_ddl;

select public.deps_restore_dependencies(
  'feature14',
  'table',
  '{
    "dry_run": false,
    "verbose": true
  }'
)