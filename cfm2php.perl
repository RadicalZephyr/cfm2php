#!/usr/bin/perl

# cfm2php - a cfml to php converter

# Copyright (C) 2011 Geoff Shannon

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the:
# Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor,
# Boston, MA 02110-1301, USA.

# You can contact me with bugfixes, feature suggestions, praise
# etc. at: earthlingzephyr@gmail.com

# A short script that will convert some core coldfusion statements
# into php equivalents.  Note: this does not do actual syntax parsing,
# and thus the code that it produces WILL BE MALFORMED

# However, it will get you about 60% of the way there, and it will
# save a hell of a lot of typing.



use Getopt::Long;

my ($inplace, $debug, $outprefix);

GetOptions("debug" => \$debug,
           "inplace" => \$inplace,
           "out-prefix=s" => \$outprefix);

my $holdterminator = $/;
undef $/;

foreach (@ARGV) {
    if (/.*\.cfm/i) {
        open $infile, '<:crlf', $_;

        # open the re-suffixed outfile
        s/(.*)\.cfm/$1.php/i;
        open $outfile, '>', $outprefix . $_;

        $_ = <$infile>;
        
        s/#application\.dsn#//gi;

        s#<cfif (.*?)>#if ($1) {#gi;
        s#<cfelseif (.*?)>#} elseif ($1) {#gi;
        s#<cfelse>#} else {#gi;
        s#</cfif>#}#gi;

        s#<cfloop (.*?)>([\d\D]*?)</cfloop>#for ($1) {$2}#gi;

        s#<cfoutput query="([a-zA-Z0-9_]*)"> ?([\d\D]*) ?</cfoutput>#\$length = mysql_num_rows(\$$1);\n\nfor (\$i = 0; \$i < \$length; \$i++) {$2}#gi;

        s#<cfquery name="(?<qname>.*?)".*?(?:maxrows=(?<limit>\d+))?.*?>\s*(?<query>[\d\D]*?)\s*</cfquery>#\$query = "$+{query} LIMIT $+{limit}";\n\n\$$+{qname} = mysql_query(\$query);\n#gi;

        s#<cfset ([a-zA-Z0-9_]*) ?= ?(.*)>#\$$1 = $2;#gi;
        s#parameterexists(\(.*?\))#isset$1#gi;
        s/#dateformat\(([a-zA-Z0-9_]*), ?(".*")\)#/date($1, $2)/gi;
        s/#dollarformat\(([a-zA-Z0-9_]*)\)#/number_format($1, 2)/gi;

        s#URL\.([a-zA-Z0-9_]*)#\$_GET['$1']#g;
        s#Form\.([a-zA-Z0-9_]*)#\$_POST['$1']#g;

        s#\bOR\b#||#g;
        s#\bAND\b#&&#g;
        s#\bGTE\b#>=#g;
        s#\bGT\b#>#g;
        s#\bLTE\b#>=#g;
        s#\bLT\b#>#g;
        s#\bIS NOT\b#!=#g;
        s#\bIS\b#==#g;

        s/#([a-zA-Z0-9_]*)\.([a-zA-Z0-9_]*)#/mysql_result(\$$1, 0, "$2")/g;
        s/#([a-zA-Z0-9_]*)#/\$$1/gi;

        s/\.cfm/.php/gi;

        s|Author: Christine Kelley|Author: Geoff Shannon|;
        s|Date: 12/01|Date: 10/11|;
        s|Version: 1.0|Version: 2.0|;
        s|© 2001 Christine M Kelley|© 2011 Geoff Shannon|;

        $_ = '<?php require("/home/geoff/phplay/htdocs/admin/verify.php"); ?>' . "\n" . $_;
        
        print $outfile $_;
    }
}

$/ = $holdterminator;
