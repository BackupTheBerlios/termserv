#!/usr/bin/perl
# index.cgi

do '../web-lib.pl';
require './ltsp-lib.pl';

&init_config();

&ReadParse();

&ltsp_header($text{"index_title"}, "", undef, "config");

print "<hr><br>\n";

#
# This is where actions after POST are executed and 
# warnings are outputted
#

if ($in{"action"} eq "delete") {

  &ltsp_read_config($config{"ltsconf_path"} . "/lts.conf");

  print "<font color=\"#ff0000\">Host " . $in{"name"} . " deleted</font>\n";

  &ltsp_modify_entry($in{"name"}, "d", %ent);
  &ltsp_write_config($config{"ltsconf_path"} . "/lts.conf");

} elsif ($in{"action"} eq "add") {

  &ltsp_read_config($config{"ltsconf_path"} . "/lts.conf");

  print "<font color=\"#ff0000\">Host \"" . $in{"newhost"} . "\" added</font>\n";

  %modent = ();
  foreach (&ltsp_get_options()) {
    if ($in{"def_$_"} eq "NoDefault") {
      $modent{"$_"} = $in{"$_"};
    }
  }

  &ltsp_modify_entry($in{"newhost"}, "a", %modent);
  &ltsp_write_config($config{"ltsconf_path"} . "/lts.conf");

} elsif ($in{"action"} eq "modify") {

  &ltsp_read_config($config{"ltsconf_path"} . "/lts.conf");

  print "<font color=\"#ff0000\">Host \"" . $in{"name"} . "\" modified</font>\n";

  %modent = ();
  foreach (&ltsp_get_options()) {
    if ($in{"def_$_"} eq "NoDefault") {
      $modent{"$_"} = $in{"$_"};
    }
  }

  &ltsp_modify_entry($in{"name"}, "m", %modent);
  &ltsp_write_config($config{"ltsconf_path"} . "/lts.conf");
  
}

&ltsp_read_config($config{"ltsconf_path"} . "/lts.conf");

foreach (sort(&ltsp_get_hces())) {
  if ($_ eq "Default") {
    push (@icons, "images/group.gif");
  } else {
    push (@icons, "images/host.gif");
  }
  push (@configs, "$_");
  push (@links, "./edit_host.cgi?name=" . &urlize($_));
}

print "<table border width=100%>\n";
print "<tr $tb> <td><b>" . $text{'hosts'} . "</b></td></tr>\n";
print "<tr $cb> <td>";

&icons_table(\@links, \@configs, \@icons, 5);

print "</td> </tr>\n";
print "</table>\n";

print "<br><a href=\"./edit_host.cgi?action=add\">" . $text{"add_host"} . "</a>\n";

if ($EXPERIMENTAL) { print "<br><a href=\"./check_configuration.cgi\">" . $text{"configuration_check"} . "</a>\n"; }

if ($EXPERIMENTAL) { print "<br><a href=\"./rom-image-selection.cgi\">" . $text{"select_rom_image"} . "</a>\n"; }

print "<br><hr>\n";
&footer("/", $text{'index'});

