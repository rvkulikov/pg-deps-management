-- @see https://github.com/rvkulikov/pg-deps-management/issues/10

--- dependency tree
--- table1
---   view1
---     rule1
---     rule2
---     fn1
---       fn2
---         view2
---         pc1
---           tg1
---             trg1

drop schema if exists util cascade;
create schema util;

create function util.__assert(condition boolean, message text) returns void as $$
begin
  if not condition then
    raise exception 'Assertion failed: %', message;
  end if;
end;
$$ language plpgsql;

drop schema if exists feature10 cascade;
create schema feature10;

delete from public.deps_saved_ddl where true;

create table feature10._table1(
  col_1 text
);

create view feature10._view1 as select * from feature10._table1;

create function feature10._fn1() returns setof feature10._view1 language plpgsql as $$ begin
  return query select * from feature10._view1;
end; $$;

create function feature10._fn2() returns setof feature10._view1 language plpgsql as $$ begin
  return query select * from feature10._fn1();
end; $$;

create procedure feature10._pc1() language plpgsql as $$ begin
  perform * from feature10._fn2();
end; $$;

create view feature10._view2 as select * from feature10._fn2();

create function feature10._tg1() returns trigger language plpgsql as $trg$ begin
  call feature10._pc1();
  return new;
end $trg$;

create trigger trg1
  before insert or update on feature10._table1
  for each row execute procedure feature10._tg1();

create rule _rule1 as on insert to feature10._view1
  do instead nothing;

create rule _rule2 as on insert to feature10._view1
  do instead insert into feature10._table1 values (new.col_1);

insert into feature10._view1 values (10);

select public.deps_save_and_drop_dependencies(
  'feature10',
  '_table1',
  '{"dry_run": true, "verbose": true, "populate_materialized_view": true}'::jsonb
);

select * from feature10._table1;

select * from public.deps_saved_ddl;

-- select
--   util.__assert(
--       (select count(ctid) from public.deps_saved_ddl where ddl_statement ~* 'create view') = 1,
--       'There is only 1 create view statement'::text
--     );