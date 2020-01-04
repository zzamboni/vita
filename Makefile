.PHONY: all clean publish

all:
	latexmk
view:
	latexmk -pvc zamboni-vita
clean:
	latexmk -c -bibtex

######################################################################
# Web publishing

WEBDEST = $(HOME)/Personal/websites/zzamboni.org
# Where to put the files for web page
VITADEST = $(WEBDEST)/static/files/vita
# File in which to update the date
VITAPAGE = $(WEBDEST)/content/vita.md

publish:
	cp zamboni-vita.pdf zamboni-vita.html zamboni-vita.txt $(VITADEST)
	sed -i '' 's/Last updated .*/Last updated on **'"$$(date +'%B %e, %Y')"'**/' $(VITAPAGE)
	cd $(WEBDEST); git add $(VITADEST) $(VITAPAGE); git commit -a -m 'Updated CV'; git push
