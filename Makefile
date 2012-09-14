dox:
	find doc -type f -not -name header.html | xargs rm 
	doxygen
