# First time?

* Wanna move column in a table 'cause it hurts your inner perfectionist?
* You new CTO/DBA decided that your current table layout must be optimized by 4 bytes per row or business will fail?
* Your code standards changed and all inner joins must be rewritten with where again?
* Uhm, why not to add some other columns for our primary table?
* Simple grep in your migration directory for view definition give you 20 results?
* You look at your migration and see copy-pasted 1000 sloc of other migrations. And the same for rollback?!

![first time](.resources/first-time.jpg)

## What is this

Complex enhancement/refactoring of https://gist.github.com/mateuszwenus/11187288  
See related topics https://wiki.postgresql.org/wiki/Todo#Views_and_Rules

Recursively backup all dependent views, then modify base tables, then recreate all backuped views

## Supported features

| Feature                        | View | Materialized View | Comment                                |
|--------------------------------|------|-------------------|----------------------------------------|
| Create view                    | Yes  | Yes               | With reloptions, tablespace, (no) data |
| Create index                   | N/A  | Yes               |                                        |
| Alter owner to                 | Yes  | Yes               |                                        |
| Create rule                    | Yes  | Yes               |                                        |
| Comment on view                | Yes  | Yes               |                                        |
| Comment on view column         | Yes  | Yes               |                                        |
| Grant privilege on view        | Yes  | Yes               | With grant options                     |
| Grant privilege on view column | Yes  | Yes               | With grant options                     |
| Create policy                  | N/A  | N/A               |                                        |


## Usage

```postgresql
select public.deps_save_and_drop_dependencies(
  'public',
  'my_table',
  '{
    "dry_run": true,
    "verbose": false,
    "populate_materialized_view": false
  }'
);

-- alter my_table...

select public.deps_restore_dependencies(
  'public',
  'my_table',
  '{
    "dry_run": true,
    "verbose": false
  }'
);
```

## Options

* deps_save_and_drop_dependencies
  * `dry_run` Run without actually dropping dependencies
  * `verbose` Show debug log
  * `populate_materialized_view` Enable or disable materialized view refresh-on-create via `WITH [NO] DATA` flag
    
* deps_restore_dependencies
  * `dry_run` Run without actually executing ddl statements
  * `verbose` Show debug log
