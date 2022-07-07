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

drop schema if exists feature8_1 cascade;
drop schema if exists feature8_2 cascade;

create schema feature8_1;
create schema feature8_2;

delete from public.deps_saved_ddl where true;

create table feature8_1._table (
  col_1 text
);
create table feature8_2._table (
  col_1 text
);

create view feature8_1._view as select * from feature8_1._table;
create view feature8_2._view as select * from feature8_2._table;

select public.deps_save_and_drop_dependencies(
  'feature8_1',
  '_table',
  '{
    "dry_run": false,
    "verbose": true,
    "populate_materialized_view": true
  }'
);

select * from public.deps_saved_ddl;

select
  util.__assert(
    (select count(ctid) from public.deps_saved_ddl where ddl_statement ~* 'create view') = 1,
    'There is only 1 create view statement'::text
  );