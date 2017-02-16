#include <R.h>
#include <Rinternals.h>
#include <stdlib.h> // for NULL
#include <R_ext/Rdynload.h>

/* FIXME:
   Check these declarations against the C/Fortran source code.
*/

/* .Call calls */
extern SEXP odbc_column_types(SEXP);
extern SEXP odbc_connection_begin(SEXP);
extern SEXP odbc_connection_commit(SEXP);
extern SEXP odbc_connection_info(SEXP);
extern SEXP odbc_connection_quote(SEXP);
extern SEXP odbc_connection_release(SEXP);
extern SEXP odbc_connection_rollback(SEXP);
extern SEXP odbc_connection_sql_columns(SEXP, SEXP, SEXP, SEXP, SEXP);
extern SEXP odbc_connection_sql_tables(SEXP, SEXP, SEXP, SEXP, SEXP);
extern SEXP odbc_connection_valid(SEXP);
extern SEXP odbc_list_data_sources_();
extern SEXP odbc_list_drivers_();
extern SEXP odbc_new_result(SEXP, SEXP);
extern SEXP odbc_odbc_connect(SEXP, SEXP);
extern SEXP odbc_result_active(SEXP);
extern SEXP odbc_result_bind(SEXP, SEXP);
extern SEXP odbc_result_column_info(SEXP);
extern SEXP odbc_result_completed(SEXP);
extern SEXP odbc_result_execute(SEXP);
extern SEXP odbc_result_fetch(SEXP, SEXP);
extern SEXP odbc_result_insert_dataframe(SEXP, SEXP);
extern SEXP odbc_result_release(SEXP);
extern SEXP odbc_result_row_count(SEXP);
extern SEXP odbc_result_rows_affected(SEXP);

static const R_CallMethodDef CallEntries[] = {
    {"odbc_column_types",            (DL_FUNC) &odbc_column_types,            1},
    {"odbc_connection_begin",        (DL_FUNC) &odbc_connection_begin,        1},
    {"odbc_connection_commit",       (DL_FUNC) &odbc_connection_commit,       1},
    {"odbc_connection_info",         (DL_FUNC) &odbc_connection_info,         1},
    {"odbc_connection_quote",        (DL_FUNC) &odbc_connection_quote,        1},
    {"odbc_connection_release",      (DL_FUNC) &odbc_connection_release,      1},
    {"odbc_connection_rollback",     (DL_FUNC) &odbc_connection_rollback,     1},
    {"odbc_connection_sql_columns",  (DL_FUNC) &odbc_connection_sql_columns,  5},
    {"odbc_connection_sql_tables",   (DL_FUNC) &odbc_connection_sql_tables,   5},
    {"odbc_connection_valid",        (DL_FUNC) &odbc_connection_valid,        1},
    {"odbc_list_data_sources_",      (DL_FUNC) &odbc_list_data_sources_,      0},
    {"odbc_list_drivers_",           (DL_FUNC) &odbc_list_drivers_,           0},
    {"odbc_new_result",              (DL_FUNC) &odbc_new_result,              2},
    {"odbc_odbc_connect",            (DL_FUNC) &odbc_odbc_connect,            2},
    {"odbc_result_active",           (DL_FUNC) &odbc_result_active,           1},
    {"odbc_result_bind",             (DL_FUNC) &odbc_result_bind,             2},
    {"odbc_result_column_info",      (DL_FUNC) &odbc_result_column_info,      1},
    {"odbc_result_completed",        (DL_FUNC) &odbc_result_completed,        1},
    {"odbc_result_execute",          (DL_FUNC) &odbc_result_execute,          1},
    {"odbc_result_fetch",            (DL_FUNC) &odbc_result_fetch,            2},
    {"odbc_result_insert_dataframe", (DL_FUNC) &odbc_result_insert_dataframe, 2},
    {"odbc_result_release",          (DL_FUNC) &odbc_result_release,          1},
    {"odbc_result_row_count",        (DL_FUNC) &odbc_result_row_count,        1},
    {"odbc_result_rows_affected",    (DL_FUNC) &odbc_result_rows_affected,    1},
    {NULL, NULL, 0}
};

void R_init_odbc(DllInfo *dll)
{
    R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
}
