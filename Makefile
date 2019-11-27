all:
	@echo "make: Entering directory '/Users/jhester/p/odbc/src'"
	@Rscript -e 'pkgload::load_all(quiet = FALSE)'
	@echo "make: Leaving directory '/Users/jhester/p/odbc/src'"

test:
	@echo "make: Entering directory '/Users/jhester/p/odbc/tests/testthat'"
	@Rscript -e 'devtools::test()'
	@echo "make: Leaving directory '/Users/jhester/p/odbc/tests/testthat'"

clean:
	@Rscript -e 'devtools::clean_dll()'
