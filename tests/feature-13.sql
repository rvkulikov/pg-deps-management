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

delete from public.deps_saved_ddl where true;

create table feature13.table (col_1 text);
create view feature13.view as select * from feature13.table;

grant update on feature13.view to public;
grant delete on feature13.view to public;

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

select public.deps_restore_dependencies(
  'feature13',
  'table',
  '{
   "dry_run": false,
   "verbose": false
  }'
);