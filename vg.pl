# vg - Vi Grepped - edit a file at a line specified in a cg search.
# Copyright 1999 by Joshua Uziel <juziel@home.com> - version 1.5.2
#
# Usage: vg number
#
# Helper script to go with cg for opening a editor conveniently
# with the correct file and line as shown in cg's log.  Run this
# with a single numerical argument (ie. "vg 3") to edit the desired
# log entry.
#
# This script seems to work fine with a number of editors, including
# vi, vim, emacs, pico, joe, etc.  (Despite it's name.)
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

# File where the log is.
$LOGFILE = "$ENV{'HOME'}/.cglast";

# Path to the rc file
$RCFILE = "$ENV{'HOME'}/.cgvgrc";

# Default editor to use.
$EDITOR = "vi";

# Use the $EDITOR environment variable if it exists.
$EDITOR = $ENV{'EDITOR'} if ($ENV{'EDITOR'});

# If the rc file exists, parse it and override the defaults.
if (-f $RCFILE) {
        open (IN, "<$RCFILE");

        while (<IN>) {
                chomp;
		
		# Strip spaces and skip blank and comment lines.
		s/^\s*//;
		next if (/^#/);
		next if (/^$/);

                ($key, $value) = split /=/;

                if ($key =~ /^EDITOR$/) {
                        $EDITOR=$value;
                } elsif ($key =~ /^BOLD$/) {
                        next;
                } elsif ($key =~ /^BOLD_ALTERNATE$/) {
                        next;
                } elsif ($key =~ /^SEARCH$/) {
                        next;
                } elsif ($key =~ /^COLOR[S1-4]$/) {
                        next;
                } else {
                        die "error: Unknown option '$key' in $RCFILE at line",
				"$..\n";
                }
        }

        close (IN);
}

# We can't edit if the editor doesn't exist.
`which $EDITOR`;
$no_editor = $?;
die "Error: Editor $EDITOR isn't in your path.\n" if ($no_editor);

# We need one argument only, and it has to be a number.
die "Error: Single argument needed.\n" unless ($#ARGV == 0);

# Set it to $num and test that it is a number.
$num = $ARGV[0];

die "Error: Non-numerical argument.\n" 
	unless (($num =~ /\d+/) && ($num !~ /\D+/));

die "Error: $LOGFILE doesn't exist.\n" unless (-f $LOGFILE);

open (IN, "<$LOGFILE");

# Check if our current path is the path when the log was taken.  If so,
# then nullify $path, else set it to $path/ so we can use anywhere.
$PWD="$ENV{PWD}\n";
$path=(split(/=/, <IN>))[1];
if ($PWD eq $path) {
	$path="";
} else {
	chomp($path);
	$path="$path/";
}

# Find the line we want and open up vi to that line.
foreach $line (<IN>) {
	($this, $file, $line) = (split(/:/, $line))[0,1,2];

	# Change this to execute the editor.
	exec "$EDITOR +$line $path$file" if ($num == $this);
}

# If we're here, there was a problem.
die "Error: Numerical argument invalid.\n";
