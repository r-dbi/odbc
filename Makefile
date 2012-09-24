dox:
	rm -rf a.out.dSYM a.out
	find doc -type f -not -name header.html -and -not -name footer.html | xargs rm 
	doxygen

clean:
	rm -rf a.out.dSYM a.out
