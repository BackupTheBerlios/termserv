#!/usr/bin/perl
# rom-image-selection.cgi

do '../web-lib.pl';
require './ltsp-lib.pl';

&init_config();

&ReadParse();

&header($text{'select_rom_image'}, "", undef);

print "<hr><br>\n";

print "<form action=\"./rom-image.cgi\" method=\"get\">\n";

print "<table cellpadding=\"5\" border width=100%>\n";
print "<tr $tb> <td colspan=\"2\"><b>" . $text{"select"} . "</b></td></tr>\n";
print "<tr $cb> <td>" . $text{"select_nic"} . "</td><td>";

print "gaga";

print "</td></tr></table>\n";

print "</td> </tr>\n";
print "</table>\n";

print "</form>\n";

print "<br><hr>\n";
&footer("", $text{'index'});

