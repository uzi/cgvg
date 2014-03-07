# Makefile for cgvg

# Make sure this points to a Perl 5 interpreter
PERL=/usr/bin/perl

# Path where to install to.
PREFIX=/usr

all: cg vg

cg: cg.pl
	echo "#!${PERL}" | cat - cg.pl > cg
	chmod 755 cg

vg: vg.pl
	echo "#!${PERL}" | cat - vg.pl > vg
	chmod 755 vg

install:
	install -m 755 cg   ${PREFIX}/bin
	install -m 755 vg   ${PREFIX}/bin
	install -m 644 cg.1 ${PREFIX}/man/man1
	install -m 644 vg.1 ${PREFIX}/man/man1

uninstall:
	rm -f ${PREFIX}/bin/cg ${PREFIX}/bin/vg \
		${PREFIX}/man/man1/cg.1 ${PREFIX}/man/man1/vg.1 

clean:
	rm -f cg vg
