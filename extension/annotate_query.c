#include "postgres.h"
#include "fmgr.h"
#include "utils/builtins.h"
#include "parser/parser.h"
#include "nodes/print.h"

PG_MODULE_MAGIC;


PG_FUNCTION_INFO_V1(annotate_query);

Datum
annotate_query(PG_FUNCTION_ARGS)
{
	text	*sql_t = PG_GETARG_TEXT_P(0);
	text	*out_t;
	char	*sql, *out;
	List	*tree;

	sql = text_to_cstring(sql_t);
	tree = raw_parser(sql);

	out = nodeToString(tree);

	out_t = cstring_to_text(out);
	PG_RETURN_TEXT_P(out_t);
}