#!/usr/bin/perl
# check_configuration.cgi

do '../web-lib.pl';
require './ltsp-lib.pl';
require './ltsp-check-lib.pl';

&init_config();

&ReadParse();

&header($text{'configuration_check'}, "", undef);

print "<hr><br>\n";

#&ltsp_read_config($config{"ltsconf_path"} . "/lts.conf");

# The outer table
print "<table cellpadding=\"5\" border width=100%>\n";
print "<tr $tb> <td colspan=\"2\"><b>" . $text{'checks'} . "</b></td></tr>\n";
print "<tr $cb> <td>" . $text{"tftp_daemon_running"} . "</td><td>";

if (&ltsp_check_tftp()) {
  print "<font color=\"#00ff00\">" . $text{"Y"} . "</font>";
} else {
  print "<font color=\"#ff0000\">" . $text{"N"} . "</font>";
}


print "</td></tr></table>\n";

print "</td> </tr>\n";
print "</table>\n";

print "<br><hr>\n";
&footer("", $text{'index'});

