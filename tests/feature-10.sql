-- @see https://github.com/rvkulikov/pg-deps-management/issues/10

--- dependency tree
--- table1
---   view1
---     view3
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
create view feature10._view3 as select * from feature10._view1;

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

-- select
--   obj_schema,
--   obj_name,
--   obj_type
-- from (
--   with recursive
--     deps as (
--       select
--         n.nspname  ref_schema,
--         c.relname  ref_name,
--         rc.relkind dep_type,
--         rn.nspname dep_schema,
--         rc.relname dep_name
--       from pg_depend dep
--         join pg_class c on dep.refobjid = c.oid
--         join pg_namespace n on c.relnamespace = n.oid
--         join pg_rewrite r on dep.objid = r.oid
--         join pg_class rc on r.ev_class = rc.oid
--         join pg_namespace rn on rc.relnamespace = rn.oid
--    ),
--    recursive_deps(obj_schema, obj_name, obj_type, depth) as (
--    select
--      'feature10'::name,
--      '_table1'::name,
--      null::char,
--      0
--    union
--    select
--      dep_schema::name,
--      dep_name::name,
--      dep_type::char,
--      recursive_deps.depth + 1
--    from deps
--           join recursive_deps
--                on deps.ref_schema = recursive_deps.obj_schema and
--                   deps.ref_name = recursive_deps.obj_name
--    where
--        deps.ref_schema != deps.dep_schema or
--        deps.ref_name != deps.dep_name
--   )
--  select
--    obj_schema,
--    obj_name,
--    obj_type,
--    depth
--  from
--    recursive_deps
--  where
--      depth > 0
-- ) t
-- group by
--   obj_schema,
--   obj_name,
--   obj_type
-- order by
--   max(depth) desc;

create function feature10._fn3(routine_namespace name, routine_name name) returns table (plan jsonb) language plpgsql as $$ begin
  return execute 'explain (format json) select true';
end; $$;

explain do $$ begin
  execute 'explain (format json) select true';
end $$;