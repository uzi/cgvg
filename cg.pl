# cg - Code Grep - grep recursively through files and disiplay matches
# Copyright 1999 by Joshua Uziel <juziel@home.com> - version 1.5.1
#
# usage: cg [-i] [pattern] [files]
#
# Recursive Grep script that does a bit of extra work in adding a count
# field and storing the data in a file, as well as displaying data in a
# colorful and human-readable fashion.  Run with a perl regular expression
# to search for it (with '-i' option for case-insensitive).  You can supply
# a quoted file pattern to search for ('*.c'), run just "cg" alone to
# recall the last search (since it's save to the $LOGFILE), and running
# with a list of files is allowable (though not recurive and pattern-matched
# like the quoted variation).
#
# Examples: "cg printf", "cg printf '*.c'", "cg -i printf '*.c'",
#		"cg -i printf *.c", "cg", etc.
#
# The point of this script was to provide source code searching
# functionality similar to that AT&T's cscope(1).  This is a pure
# hack and lacks any sophistication, but has the advantage that it
# can be used for more than just the C programming language, besides
# adding the functionality that is generally missing from a developer's
# toolbox.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

use POSIX;
use File::Find;
require "find.pl";


# Search for wanted entries for perl internal find subroutine.
sub wanted {

	# Skip things that aren't normal files (like directories).
	if ((($dev,$ino,$mode,$nlink,$uid,$gid) = lstat($_)) && -f _) {

		# Kill the leading ./ and push it on the @LIST
		$name =~ s/^\.\///;

		# Push onto the list if we have a match
		push @LIST, $name if ($name =~ /$SEARCH/o);
	}
}

# Default search list:
# 	Make* *.c *.h *.s *.cc *.pl *.pm *.java *.*sh *.idl
$SEARCH = '(^Make.*$|^.*\.([chs]|cc|p[lm]|java|.*sh|idl)$)';

# Where to store the data
$LOGFILE = "$ENV{'HOME'}/.cglast";

# Path to the rc file
$RCFILE = "$ENV{'HOME'}/.cgvgrc";

# List of files and strings to exclude from our search.
$EXCLUDE = "SCCS|RCS|tags|\.make\.state";

# Set if you want colors (and your term supports it).  This is required
# for the $BOLD* options.
$COLORS = 1;

# Have everything printed in bold... 1 (yes) or 0 (no) only.  This option
# is overrided by $BOLD_ALTERNATE and only available with $COLORS
$BOLD = 0;

# Make every other line bold.
$BOLD_ALTERNATE = 1;

# Defined colors
%colors = ( 'black'	=> "30",
	    'red'	=> "31",
	    'green'	=> "32",
	    'yellow'	=> "33",
	    'blue'	=> "34",
	    'magenta'	=> "35",
	    'cyan'	=> "36",
	    'white'	=> "37");

# Default color for column #
$c[1] = $colors{'cyan'};
$c[2] = $colors{'blue'};
$c[3] = $colors{'red'};
$c[4] = $colors{'green'};

# Check if stdout goes to a tty... can't do colors if we pipe to another
# program like "more" or "less" or to a file.
$COLORS = POSIX::isatty(fileno STDOUT) if ($COLORS);

# If the rc file exists, parse it and override the defaults.
if (-f $RCFILE) {
	open (IN, "<$RCFILE");
	
	while (<IN>) {
		chomp;
		
		# Strip leading spaces and skip blank and comment lines.
		s/\s*//g;
		next if (/^#/);
		next if (/^$/);
		
		($key, $value) = split /=/;

		# Match only the specific value.
		if ($key =~ /^COLORS$/) {
			$COLORS=$value;
		} elsif ($key =~ /^BOLD$/) {
			$BOLD=$value;
		} elsif ($key =~ /^BOLD_ALTERNATE$/) {
			$BOLD_ALTERNATE=$value;
		} elsif ($key =~ /^EDITOR$/) {
			$EDITOR=$value;
		} elsif ($key =~ /^SEARCH$/) {
			print "$value\n";
			$SEARCH=$value;

		# Change colors from the defaults.
		} elsif ($key =~ /^COLOR[1-4]$/) {

			# See that a legal color has been given
			if ($value =~ 
			/^(black|red|green|yellow|blue|magenta|cyan|white)$/) {
				$coltmp = $key;
				$coltmp =~ s/COLOR//;
				$c[$coltmp] = $colors{$value};
			} else {
				die "error: Unknown color '$value' in $RCFILE",
					"at line $..\n";
			}
		} else {
			die "error: Unknown option '$key' in $RCFILE at line",
				"$..\n";
		}
	}

	close (IN);
}

# Generate the log ...
if ($#ARGV+1) {
	$count = 0;
	open (OUT, ">$LOGFILE");

	# Give a point of reference if we change directories.
	print OUT "PWD=$ENV{PWD}\n";

	# Set the @ARGLIST and the file $SEARCH (if any) while counting
	# non-dash arguments.  More than one means we have a $SEARCH, else
	# we use the default list of files to search through.
	$nondash = 0;
	foreach (@ARGV) {
		if (/^-/) {
			push @ARGLIST, $_;
		} else {
			if ($nondash) {
				push @FILELIST, $_;
			} else {
				$pattern = $_
			}
			$nondash++;
		}
	}
	$nondash--;

	# If we have a file list of size 1, use it as a search pattern
	# for files automatically.
	if ($nondash == 1) {
		
		# Unless that one thing is a file, in which case we just
		# search it.
		if (-T $FILELIST[0]) {
			die "error: File $FILELIST[0] not readable.\n"
				unless (-r $FILELIST[0]);
			$nondash++;	# Psych out the $nondash check later.
		} else {
			$SEARCH = $FILELIST[0];
			$SEARCH =~ s/\./\\\./g;		# . --> \.
			$SEARCH =~ s/\*/\.\*/g;		# * --> .*
		}
	}

	# Check our arguments
	$insensitive = 0;
	foreach (@ARGLIST) {
		if (/^\-i$/) {
			$insensitive = 1;
		} else {
			die "error: Unknown argument.\n";
		}
	}

	# Adding "(?i)" to the head makes it case-insensitive
	# (aka. data-driven case insensitivity)
	if ($insensitive) {
		$pattern = "(?i)" . $pattern;
	}

	# Use the given list of files if more than 2 given by the shell,
	# else to a recursive find, matching on the default or given pattern.
	if ($nondash >= 2) {
		@LIST = @FILELIST;
	} else {
		# Initialize @LIST so it's now global and do the find...
		@LIST;
		&find('.');
	}

	# Remove files found in our $EXCLUDE list
	@LIST = grep !/$EXCLUDE/, @LIST;

	# Special case of no matching files, we die with an error.
	die "error: No matching files found.\n" if ($#LIST < 0);

	# Search through the list of files and generate the $LOGFILE
	foreach $file (@LIST) {
		# Only open text files (-T) that we can read (-r).
		open(IN, "<$file") if ((-T $file) && (-r $file));

		while (<IN>) {
			# Search for the pattern (o == only compile once)
			if (/$pattern/o) {
				# $. is the line number and $_ is the entry
				print OUT "$count:$file:$.:$_";
				$count++;
			}
		}
		close (IN);
	}
	close (OUT);
}

# Either way, we print the log... this part works to reformat things
# differently from how it's stored to make it easier on the human eyes.

# Attempt to get the number of columns from an "stty -a"
if ($COL = `stty -a | grep column 2> /dev/null`) {

	# Strip out the value with the string "column"
	@TMP = split ';', $COL;
	foreach $tmp (@TMP) {
		$COL = $tmp if ($tmp =~ /column/);
	}
	# Grab the digit characters surrounded by non-digit characters.
	$COL =~ s/\D*(\d+)\D*/$1/;

	# Something's weird if 0, and we want more than 40.
	die "Error: Zero value found for number of columns.\n" if ($COL == 0);
	die "Error: Too few columns to work with.\n" if ($COL < 40);

	# Adjust things to be a little smaller than the width.
	$COL -= 2;
} else {
	# Default assumption is 80 columns, so do 2 less than it.
	$COL = 78;
}

# Exit there's no logfile.
die "Error: $LOGFILE does not exist.\n" unless (-f "$LOGFILE");

open (IN, "<$LOGFILE");
<IN>;	# Waste the first line, used for PWD.

# $m* are used as "max" variables... maximum length at this point.
$mnum = $mline = $mfile = $i = 0;

while ($in = <IN>) {
	chomp $in;

	# Split and strip the first few colons, leave the rest.
	($rec[$i]->{num}, $rec[$i]->{file}, $rec[$i]->{line}, $rec[$i]->{str}) 
		= split /:/, $in, 4;

	# Remove all leading whitespace.
	$rec[$i]->{str} =~ s/^\s*//;

	# Swap tabs for 8 spaces
	$rec[$i]->{str} =~ s/\t/        /g;
	
	# If we have a longer length for this field, save it. 
	$tmp = length $rec[$i]->{file};
	$mfile = $tmp if ($mfile < $tmp);
	$tmp = length $rec[$i]->{line};
	$mline = $tmp if ($mline < $tmp);

	$i++;
}

# Better than doing this every time like $mfile and $line ...
$mnum = length ($i-1);

# Skip inward the 3 lengths and the spaces separating them.
$skip = $mnum + $mfile + $mline + 3;

# Special case I call "wrapmode" when we're to skip so much that we
# can't even fit 20 characters (and in some cases negative characters).
# Go to next line and automatically skip a tab's worth.
if (($skip + 20) >= $COL) {
	$wrapmode = 1;
	$skip = 8;
}

# Length for the string is the whole line minus length of others.
# Hopefully $COL is adjusted terminal's width.
$mstr = $COL - $skip;

$entries = $i;

for ($i=0; $i < $entries; $i++) {

	# Bold every other entry
	$BOLD = ($i % 2) if ($BOLD_ALTERNATE);
	
	# Print the properly justified first 3 fields.
	print "\e[$BOLD;${c[1]}m" if ($COLORS);
	printf "%${mnum}s ", $rec[$i]->{num};  
	print "\e[0m" if ($COLORS);

	print "\e[$BOLD;${c[2]}m" if ($COLORS);
	printf "%-${mfile}s ", $rec[$i]->{file}; 
	print "\e[0m" if ($COLORS);
	
	print "\e[$BOLD;${c[3]}m" if ($COLORS);
	printf "%${mline}s ", $rec[$i]->{line};
	print "\e[0m" if ($COLORS);

	# Newline only for "wrapmode".
	print "\n" if ($wrapmode);

	# Trickery for the string.  Do this as many times as we've got
	# str's length divided by it's maximum possible length.
	for ($j=0; $j < ((length $rec[$i]->{str}) / $mstr); $j++) {

		# Only skip after first line.
		print " " x $skip if ($j || $wrapmode);

		# Print only $mstr character substring.
		print "\e[$BOLD;${c[4]}m" if ($COLORS);
		print substr $rec[$i]->{str}, ($j*$mstr), $mstr;
		print "\e[0m" if ($COLORS);
		print "\n";
	}
}

close (IN);
