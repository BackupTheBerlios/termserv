#!/usr/bin/perl
# rom-image-selection.cgi

do '../web-lib.pl';
require './ltsp-lib.pl';
require "./ltsp-etherboot-lib.pl";

&init_config();

&ReadParse();

&ltsp_header($text{'select_rom_image'}, "", undef);

print "<hr><br>\n";

print "<form action=\"./rom-image.cgi\" method=\"get\">\n";

print "<table cellpadding=\"5\" border width=100%>\n";

print "<tr $tb> <td><b>" . $text{"select"} . "</b></td></tr>\n";

print "<tr $cb><td><table border=\"0\">\n";

print "<tr $cb> <td>" . $text{"select_nic"} . "</td><td><select name=\"image\">\n";

foreach (&ltsp_etherboot_image_list()) {
  print "<option>$_\n";
}

print "</select>\n";

print "</td></tr><tr $cb><td>" . $text{"rom_output_format"} . "</td>";

print "<td><select name=\"output\">\n";
print "<option value=\"binary_image\">" . $text{"binary_image"};
print "<option value=\"floppy_loadable_image\">" . $text{"floppy_loadable_image"};
print "</select>\n";

print "</td></tr>\n";
print "<tr $cb><td><input type=\"submit\" value=\"" . $text{"get_rom_image"} . "\"></td><td></td></tr>\n";
print "</table>\n";

print "</td></tr>\n";
print "</table>\n";

print "</form>\n";

print "<br><hr>\n";
&footer("", $text{'index'});

