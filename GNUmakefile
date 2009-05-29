.PHONY: all test clean distclean dist pack assets

all: test

dist:
	rm -rf inc META.y*ml
	perl Makefile.PL
	$(MAKE) -f Makefile dist

install distclean tardist: Makefile
	$(MAKE) -f $< $@

test: Makefile
	TEST_RELEASE=1 $(MAKE) -f $< $@

Makefile: Makefile.PL
	perl $<

clean: distclean

reset: clean
	perl Makefile.PL
	$(MAKE) test

pack:
	tpage --include_path assets_embed --include_path assets/tt Embed.pm > lib/Blog/Bluejay/Assets/Embed.pm

assets:
	./script/assets2source > lib/Blog/Bluejay/Assets/Data/Source.pm
