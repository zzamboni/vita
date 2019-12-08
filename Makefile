.PHONY: all clean publish

all:
	latexmk
clean:
	latexmk -c -bibtex

######################################################################
# Web publishing

# Where to put the files for web page
VITAWEBDEST = $(HOME)/Personal/websites/zzamboni.org/static/files/vita

publish:
	cp zamboni-vita.pdf $(VITAWEBDEST)
