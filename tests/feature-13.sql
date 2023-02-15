-- @see https://github.com/rvkulikov/pg-deps-management/issues/5
-- I have tried to drop a view so that I can modify it, while retaining all the existing dependencies,
-- however it seems that when I provide a view name to this function, it does not capture any dependencies
-- for the view.

drop schema if exists util cascade;
create schema util;

create or replace function util.__assert(condition boolean, message text) returns void as $$
begin
  if not condition then
    raise exception 'Asserting failed: %', message;
  end if;
end;
$$ language plpgsql;

drop schema if exists feature13 cascade;
create schema feature13;

create role "PUBLIC";

delete from public.deps_saved_ddl where true;

create table feature13.table (col_1 text, col_2 text);
create view feature13.view as select * from feature13.table;

grant select on feature13.view to public;
grant insert on feature13.view to "PUBLIC";
grant select (col_1) on feature13.view to "PUBLIC";
grant update (col_2) on feature13.view to "PUBLIC";
grant update (col_2) on feature13.view to public;

select public.deps_save_and_drop_dependencies(
  'feature13',
  'table',
  '{
    "dry_run": false,
    "verbose": true,
    "populate_materialized_view": true
  }'
);

select * from public.deps_saved_ddl;

select
  util.__assert(
      (select count(true) from public.deps_saved_ddl where trim(' ' from ddl_statement) = 'GRANT SELECT ON feature13.view TO public') = 1,
      'Default PUBLIC role table grants ok'::text
    );

select
  util.__assert(
      (select count(true) from public.deps_saved_ddl where trim(' ' from ddl_statement) = 'GRANT INSERT ON feature13.view TO "PUBLIC"') = 1,
      'Custom "PUBLIC" role table grants ok'::text
    );

select
  util.__assert(
      (select count(true) from public.deps_saved_ddl where trim(' ' from ddl_statement) = 'GRANT UPDATE (col_2) ON feature13.view TO public') = 1,
      'Default PUBLIC role column grants ok'::text
    );

select
  util.__assert(
      (select count(true) from public.deps_saved_ddl where trim(' ' from ddl_statement) = 'GRANT UPDATE (col_2) ON feature13.view TO "PUBLIC"') = 1,
      'Custom "PUBLIC" role column grants ok'::text
    );