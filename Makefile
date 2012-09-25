clean:
	rm -rf a.out.dSYM a.out

dox:
	make clean
	find doc -type f -not -name header.html -and -not -name footer.html | xargs rm 
	doxygen
