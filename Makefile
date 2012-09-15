dox:
	find doc -type f -not -name header.html -and -not -name footer.html | xargs rm 
	doxygen
