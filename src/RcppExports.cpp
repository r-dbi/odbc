// Generated by using Rcpp::compileAttributes() -> do not edit by hand
// Generator token: 10BE3573-1514-4C36-9D1C-5A225CD40393

#include "odbc_types.h"
#include <Rcpp.h>

using namespace Rcpp;

#ifdef RCPP_USE_GLOBAL_ROSTREAM
Rcpp::Rostream<true>&  Rcpp::Rcout = Rcpp::Rcpp_cout_get();
Rcpp::Rostream<false>& Rcpp::Rcerr = Rcpp::Rcpp_cerr_get();
#endif

// list_drivers_
Rcpp::DataFrame list_drivers_();
RcppExport SEXP _odbc_list_drivers_() {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    rcpp_result_gen = Rcpp::wrap(list_drivers_());
    return rcpp_result_gen;
END_RCPP
}
// list_data_sources_
Rcpp::DataFrame list_data_sources_();
RcppExport SEXP _odbc_list_data_sources_() {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    rcpp_result_gen = Rcpp::wrap(list_data_sources_());
    return rcpp_result_gen;
END_RCPP
}
// odbc_connect
connection_ptr odbc_connect(std::string const& connection_string, std::string const& timezone, std::string const& timezone_out, std::string const& encoding, int bigint, long timeout, Rcpp::Nullable<Rcpp::List> const& r_attributes_);
RcppExport SEXP _odbc_odbc_connect(SEXP connection_stringSEXP, SEXP timezoneSEXP, SEXP timezone_outSEXP, SEXP encodingSEXP, SEXP bigintSEXP, SEXP timeoutSEXP, SEXP r_attributes_SEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< std::string const& >::type connection_string(connection_stringSEXP);
    Rcpp::traits::input_parameter< std::string const& >::type timezone(timezoneSEXP);
    Rcpp::traits::input_parameter< std::string const& >::type timezone_out(timezone_outSEXP);
    Rcpp::traits::input_parameter< std::string const& >::type encoding(encodingSEXP);
    Rcpp::traits::input_parameter< int >::type bigint(bigintSEXP);
    Rcpp::traits::input_parameter< long >::type timeout(timeoutSEXP);
    Rcpp::traits::input_parameter< Rcpp::Nullable<Rcpp::List> const& >::type r_attributes_(r_attributes_SEXP);
    rcpp_result_gen = Rcpp::wrap(odbc_connect(connection_string, timezone, timezone_out, encoding, bigint, timeout, r_attributes_));
    return rcpp_result_gen;
END_RCPP
}
// connection_info
Rcpp::List connection_info(connection_ptr const& p);
RcppExport SEXP _odbc_connection_info(SEXP pSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< connection_ptr const& >::type p(pSEXP);
    rcpp_result_gen = Rcpp::wrap(connection_info(p));
    return rcpp_result_gen;
END_RCPP
}
// connection_quote
std::string connection_quote(connection_ptr const& p);
RcppExport SEXP _odbc_connection_quote(SEXP pSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< connection_ptr const& >::type p(pSEXP);
    rcpp_result_gen = Rcpp::wrap(connection_quote(p));
    return rcpp_result_gen;
END_RCPP
}
// connection_release
void connection_release(connection_ptr p);
RcppExport SEXP _odbc_connection_release(SEXP pSEXP) {
BEGIN_RCPP
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< connection_ptr >::type p(pSEXP);
    connection_release(p);
    return R_NilValue;
END_RCPP
}
// connection_begin
void connection_begin(connection_ptr const& p);
RcppExport SEXP _odbc_connection_begin(SEXP pSEXP) {
BEGIN_RCPP
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< connection_ptr const& >::type p(pSEXP);
    connection_begin(p);
    return R_NilValue;
END_RCPP
}
// connection_commit
void connection_commit(connection_ptr const& p);
RcppExport SEXP _odbc_connection_commit(SEXP pSEXP) {
BEGIN_RCPP
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< connection_ptr const& >::type p(pSEXP);
    connection_commit(p);
    return R_NilValue;
END_RCPP
}
// connection_rollback
void connection_rollback(connection_ptr const& p);
RcppExport SEXP _odbc_connection_rollback(SEXP pSEXP) {
BEGIN_RCPP
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< connection_ptr const& >::type p(pSEXP);
    connection_rollback(p);
    return R_NilValue;
END_RCPP
}
// connection_valid
bool connection_valid(connection_ptr const& p);
RcppExport SEXP _odbc_connection_valid(SEXP pSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< connection_ptr const& >::type p(pSEXP);
    rcpp_result_gen = Rcpp::wrap(connection_valid(p));
    return rcpp_result_gen;
END_RCPP
}
// connection_sql_tables
Rcpp::DataFrame connection_sql_tables(connection_ptr const& p, SEXP catalog_name, SEXP schema_name, SEXP table_name, SEXP table_type);
RcppExport SEXP _odbc_connection_sql_tables(SEXP pSEXP, SEXP catalog_nameSEXP, SEXP schema_nameSEXP, SEXP table_nameSEXP, SEXP table_typeSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< connection_ptr const& >::type p(pSEXP);
    Rcpp::traits::input_parameter< SEXP >::type catalog_name(catalog_nameSEXP);
    Rcpp::traits::input_parameter< SEXP >::type schema_name(schema_nameSEXP);
    Rcpp::traits::input_parameter< SEXP >::type table_name(table_nameSEXP);
    Rcpp::traits::input_parameter< SEXP >::type table_type(table_typeSEXP);
    rcpp_result_gen = Rcpp::wrap(connection_sql_tables(p, catalog_name, schema_name, table_name, table_type));
    return rcpp_result_gen;
END_RCPP
}
// connection_sql_catalogs
Rcpp::StringVector connection_sql_catalogs(connection_ptr const& p);
RcppExport SEXP _odbc_connection_sql_catalogs(SEXP pSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< connection_ptr const& >::type p(pSEXP);
    rcpp_result_gen = Rcpp::wrap(connection_sql_catalogs(p));
    return rcpp_result_gen;
END_RCPP
}
// connection_sql_schemas
Rcpp::StringVector connection_sql_schemas(connection_ptr const& p);
RcppExport SEXP _odbc_connection_sql_schemas(SEXP pSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< connection_ptr const& >::type p(pSEXP);
    rcpp_result_gen = Rcpp::wrap(connection_sql_schemas(p));
    return rcpp_result_gen;
END_RCPP
}
// connection_sql_table_types
Rcpp::StringVector connection_sql_table_types(connection_ptr const& p);
RcppExport SEXP _odbc_connection_sql_table_types(SEXP pSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< connection_ptr const& >::type p(pSEXP);
    rcpp_result_gen = Rcpp::wrap(connection_sql_table_types(p));
    return rcpp_result_gen;
END_RCPP
}
// connection_sql_columns
Rcpp::DataFrame connection_sql_columns(connection_ptr const& p, SEXP column_name, SEXP catalog_name, SEXP schema_name, SEXP table_name);
RcppExport SEXP _odbc_connection_sql_columns(SEXP pSEXP, SEXP column_nameSEXP, SEXP catalog_nameSEXP, SEXP schema_nameSEXP, SEXP table_nameSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< connection_ptr const& >::type p(pSEXP);
    Rcpp::traits::input_parameter< SEXP >::type column_name(column_nameSEXP);
    Rcpp::traits::input_parameter< SEXP >::type catalog_name(catalog_nameSEXP);
    Rcpp::traits::input_parameter< SEXP >::type schema_name(schema_nameSEXP);
    Rcpp::traits::input_parameter< SEXP >::type table_name(table_nameSEXP);
    rcpp_result_gen = Rcpp::wrap(connection_sql_columns(p, column_name, catalog_name, schema_name, table_name));
    return rcpp_result_gen;
END_RCPP
}
// transactionLevels
Rcpp::IntegerVector transactionLevels();
RcppExport SEXP _odbc_transactionLevels() {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    rcpp_result_gen = Rcpp::wrap(transactionLevels());
    return rcpp_result_gen;
END_RCPP
}
// set_transaction_isolation
void set_transaction_isolation(connection_ptr const& p, size_t level);
RcppExport SEXP _odbc_set_transaction_isolation(SEXP pSEXP, SEXP levelSEXP) {
BEGIN_RCPP
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< connection_ptr const& >::type p(pSEXP);
    Rcpp::traits::input_parameter< size_t >::type level(levelSEXP);
    set_transaction_isolation(p, level);
    return R_NilValue;
END_RCPP
}
// bigint_mappings
Rcpp::IntegerVector bigint_mappings();
RcppExport SEXP _odbc_bigint_mappings() {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    rcpp_result_gen = Rcpp::wrap(bigint_mappings());
    return rcpp_result_gen;
END_RCPP
}
// result_release
void result_release(result_ptr r);
RcppExport SEXP _odbc_result_release(SEXP rSEXP) {
BEGIN_RCPP
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< result_ptr >::type r(rSEXP);
    result_release(r);
    return R_NilValue;
END_RCPP
}
// result_active
bool result_active(result_ptr const& r);
RcppExport SEXP _odbc_result_active(SEXP rSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< result_ptr const& >::type r(rSEXP);
    rcpp_result_gen = Rcpp::wrap(result_active(r));
    return rcpp_result_gen;
END_RCPP
}
// result_completed
bool result_completed(result_ptr const& r);
RcppExport SEXP _odbc_result_completed(SEXP rSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< result_ptr const& >::type r(rSEXP);
    rcpp_result_gen = Rcpp::wrap(result_completed(r));
    return rcpp_result_gen;
END_RCPP
}
// new_result
result_ptr new_result(connection_ptr const& p, std::string const& sql, const bool immediate, long query_timeout);
RcppExport SEXP _odbc_new_result(SEXP pSEXP, SEXP sqlSEXP, SEXP immediateSEXP, SEXP query_timeoutSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< connection_ptr const& >::type p(pSEXP);
    Rcpp::traits::input_parameter< std::string const& >::type sql(sqlSEXP);
    Rcpp::traits::input_parameter< const bool >::type immediate(immediateSEXP);
    Rcpp::traits::input_parameter< long >::type query_timeout(query_timeoutSEXP);
    rcpp_result_gen = Rcpp::wrap(new_result(p, sql, immediate, query_timeout));
    return rcpp_result_gen;
END_RCPP
}
// result_fetch
List result_fetch(result_ptr const& r, const int n_max);
RcppExport SEXP _odbc_result_fetch(SEXP rSEXP, SEXP n_maxSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< result_ptr const& >::type r(rSEXP);
    Rcpp::traits::input_parameter< const int >::type n_max(n_maxSEXP);
    rcpp_result_gen = Rcpp::wrap(result_fetch(r, n_max));
    return rcpp_result_gen;
END_RCPP
}
// result_column_info
Rcpp::DataFrame result_column_info(result_ptr const& r);
RcppExport SEXP _odbc_result_column_info(SEXP rSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< result_ptr const& >::type r(rSEXP);
    rcpp_result_gen = Rcpp::wrap(result_column_info(r));
    return rcpp_result_gen;
END_RCPP
}
// result_bind
void result_bind(result_ptr const& r, List const& params, size_t batch_rows);
RcppExport SEXP _odbc_result_bind(SEXP rSEXP, SEXP paramsSEXP, SEXP batch_rowsSEXP) {
BEGIN_RCPP
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< result_ptr const& >::type r(rSEXP);
    Rcpp::traits::input_parameter< List const& >::type params(paramsSEXP);
    Rcpp::traits::input_parameter< size_t >::type batch_rows(batch_rowsSEXP);
    result_bind(r, params, batch_rows);
    return R_NilValue;
END_RCPP
}
// result_execute
void result_execute(result_ptr const& r);
RcppExport SEXP _odbc_result_execute(SEXP rSEXP) {
BEGIN_RCPP
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< result_ptr const& >::type r(rSEXP);
    result_execute(r);
    return R_NilValue;
END_RCPP
}
// result_insert_dataframe
void result_insert_dataframe(result_ptr const& r, DataFrame const& df, size_t batch_rows);
RcppExport SEXP _odbc_result_insert_dataframe(SEXP rSEXP, SEXP dfSEXP, SEXP batch_rowsSEXP) {
BEGIN_RCPP
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< result_ptr const& >::type r(rSEXP);
    Rcpp::traits::input_parameter< DataFrame const& >::type df(dfSEXP);
    Rcpp::traits::input_parameter< size_t >::type batch_rows(batch_rowsSEXP);
    result_insert_dataframe(r, df, batch_rows);
    return R_NilValue;
END_RCPP
}
// result_describe_parameters
void result_describe_parameters(result_ptr const& r, DataFrame const& df);
RcppExport SEXP _odbc_result_describe_parameters(SEXP rSEXP, SEXP dfSEXP) {
BEGIN_RCPP
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< result_ptr const& >::type r(rSEXP);
    Rcpp::traits::input_parameter< DataFrame const& >::type df(dfSEXP);
    result_describe_parameters(r, df);
    return R_NilValue;
END_RCPP
}
// result_rows_affected
int result_rows_affected(result_ptr const& r);
RcppExport SEXP _odbc_result_rows_affected(SEXP rSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< result_ptr const& >::type r(rSEXP);
    rcpp_result_gen = Rcpp::wrap(result_rows_affected(r));
    return rcpp_result_gen;
END_RCPP
}
// result_row_count
int result_row_count(result_ptr const& r);
RcppExport SEXP _odbc_result_row_count(SEXP rSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< result_ptr const& >::type r(rSEXP);
    rcpp_result_gen = Rcpp::wrap(result_row_count(r));
    return rcpp_result_gen;
END_RCPP
}
// column_types
void column_types(DataFrame const& df);
RcppExport SEXP _odbc_column_types(SEXP dfSEXP) {
BEGIN_RCPP
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< DataFrame const& >::type df(dfSEXP);
    column_types(df);
    return R_NilValue;
END_RCPP
}

static const R_CallMethodDef CallEntries[] = {
    {"_odbc_list_drivers_", (DL_FUNC) &_odbc_list_drivers_, 0},
    {"_odbc_list_data_sources_", (DL_FUNC) &_odbc_list_data_sources_, 0},
    {"_odbc_odbc_connect", (DL_FUNC) &_odbc_odbc_connect, 7},
    {"_odbc_connection_info", (DL_FUNC) &_odbc_connection_info, 1},
    {"_odbc_connection_quote", (DL_FUNC) &_odbc_connection_quote, 1},
    {"_odbc_connection_release", (DL_FUNC) &_odbc_connection_release, 1},
    {"_odbc_connection_begin", (DL_FUNC) &_odbc_connection_begin, 1},
    {"_odbc_connection_commit", (DL_FUNC) &_odbc_connection_commit, 1},
    {"_odbc_connection_rollback", (DL_FUNC) &_odbc_connection_rollback, 1},
    {"_odbc_connection_valid", (DL_FUNC) &_odbc_connection_valid, 1},
    {"_odbc_connection_sql_tables", (DL_FUNC) &_odbc_connection_sql_tables, 5},
    {"_odbc_connection_sql_catalogs", (DL_FUNC) &_odbc_connection_sql_catalogs, 1},
    {"_odbc_connection_sql_schemas", (DL_FUNC) &_odbc_connection_sql_schemas, 1},
    {"_odbc_connection_sql_table_types", (DL_FUNC) &_odbc_connection_sql_table_types, 1},
    {"_odbc_connection_sql_columns", (DL_FUNC) &_odbc_connection_sql_columns, 5},
    {"_odbc_transactionLevels", (DL_FUNC) &_odbc_transactionLevels, 0},
    {"_odbc_set_transaction_isolation", (DL_FUNC) &_odbc_set_transaction_isolation, 2},
    {"_odbc_bigint_mappings", (DL_FUNC) &_odbc_bigint_mappings, 0},
    {"_odbc_result_release", (DL_FUNC) &_odbc_result_release, 1},
    {"_odbc_result_active", (DL_FUNC) &_odbc_result_active, 1},
    {"_odbc_result_completed", (DL_FUNC) &_odbc_result_completed, 1},
    {"_odbc_new_result", (DL_FUNC) &_odbc_new_result, 4},
    {"_odbc_result_fetch", (DL_FUNC) &_odbc_result_fetch, 2},
    {"_odbc_result_column_info", (DL_FUNC) &_odbc_result_column_info, 1},
    {"_odbc_result_bind", (DL_FUNC) &_odbc_result_bind, 3},
    {"_odbc_result_execute", (DL_FUNC) &_odbc_result_execute, 1},
    {"_odbc_result_insert_dataframe", (DL_FUNC) &_odbc_result_insert_dataframe, 3},
    {"_odbc_result_describe_parameters", (DL_FUNC) &_odbc_result_describe_parameters, 2},
    {"_odbc_result_rows_affected", (DL_FUNC) &_odbc_result_rows_affected, 1},
    {"_odbc_result_row_count", (DL_FUNC) &_odbc_result_row_count, 1},
    {"_odbc_column_types", (DL_FUNC) &_odbc_column_types, 1},
    {NULL, NULL, 0}
};

RcppExport void R_init_odbc(DllInfo *dll) {
    R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
}
