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

drop schema if exists feature19 cascade;
create schema feature19;

delete from public.deps_saved_ddl where true;

create table feature19.table (col_1 text);
create view feature19.view as select * from feature19.table;

drop role if exists feature19_user;
create role feature19_user;
grant usage on schema feature19 to feature19_user;
grant select on feature19.table to feature19_user;
grant select on feature19.view to feature19_user;

select public.deps_save_and_drop_dependencies(
  'feature19',
  'table',
  '{
    "dry_run": false,
    "verbose": true
  }'::jsonb
);

select * from public.deps_saved_ddl;

select
  util.__assert(
     (select count(true) from public.deps_saved_ddl where ddl_statement ~* 'grant select on feature19.view to feature19_user') = 1,
     'There is self-referencing grants'::text
  );
