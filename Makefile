.PHONY: all clean publish

OUTPUTS = build/zamboni-vita/zamboni-vita.pdf build/zamboni-resume/zamboni-resume.pdf

all:
	tectonic -X build

open:
	for i in $(OUTPUTS); do echo $$i...; open $$i &; done

view: all open

watch:
	tectonic -X watch -x 'build --open'

clean:
	rm -f $(OUTPUTS)

######################################################################
# Web publishing

WEBDEST = $(HOME)/Personal/websites/zzamboni.org
# Where to put the files for web page
VITADEST = $(WEBDEST)/static/files/vita
# File in which to update the date
VITAPAGE = $(WEBDEST)/content/vita.md

publish:
	cp build/zamboni-vita/zamboni-vita.pdf build/zamboni-resume/zamboni-resume.pdf $(VITADEST)
	sed -i'' 's/Last updated .*/Last updated on **'"$$(date +'%B %e, %Y')"'**/' $(VITAPAGE)
	sed -i'' 's/^date: .*/date: '"$$(date -Iseconds)"'/' $(VITAPAGE)
	cd $(WEBDEST); git add $(VITADEST) $(VITAPAGE); git commit -a -m 'Updated CV'; git push
