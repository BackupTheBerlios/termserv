#!/usr/bin/perl
# edit_host.cgi

do '../web-lib.pl';
require './ltsp-lib.pl';
&init_config();

&ReadParse();

&ltsp_header($text{'edit_host'}, "", undef);

print "<hr><br>\n";

&ltsp_read_config($config{"ltsconf_path"} . "/lts.conf");

# The outer table
print "<table cellpadding=\"5\" border width=100%>\n";
print "<tr $tb> <td><b>" . $text{'settings_for'} . " " . $text{'host'} . " " . $in{"name"} . "</b></td></tr>\n";
print "<tr $cb> <td>";


#
# Delete button
# 

if (($in{"name"} ne "Default") && ($in{"action"} ne "add")) { 
  print "<form action=\"index.cgi\" method=\"post\">\n";
  print "<input type=\"hidden\" name=\"action\" value=\"delete\">\n";
  print "<input type=\"hidden\" name=\"name\" value=\"" . $in{"name"} . "\">\n";
  print "<input type=\"submit\" value=\"" . $text{'delete_host'} . "\">\n</form>\n"; 
}

print "<form action=\"index.cgi\" method=\"post\">\n";

#
# Submit button
# 
print "<input type=\"submit\" value=\"" . $text{'save_settings'} . "\"><p>\n";

# A table that helps the two buttons to be displayed without borders around them

print "<table><tr><td>\n";

%conf = &ltsp_get_configuration($in{'name'});

print "<input type=\"hidden\" name=\"name\" value=\"" . $in{"name"} . "\">\n";

if ($in{"action"} eq "add") {

  print "<table width=\"100%\">\n";
  print "<input type=\"hidden\" name=\"action\" value=\"add\">\n";
  print "<tr><td><font color=\"#ff0000\">" . $text{"name_of_new_host"} . "</font></td><td>&nbsp;</td>\n";
  print "<td><input type=\"text\" name=\"newhost\"></td></tr>\n";
  print "</table>\n";

} else {

  print "<input type=\"hidden\" name=\"action\" value=\"modify\">\n";

}

foreach (&ltsp_get_option_groups()) {

  print "<table cellpadding=\"5\" border=\"0\">\n";
  print "<tr $tb> <td colspan=\"3\"><b>" . $text{"$_"} . "</b></td></tr>\n";

  foreach (&ltsp_get_options($_)) {

    $cur_option = $_;

    if ($conf{"$_"} eq "") { $def = 1; } else { $def = 0 }

    if (&ltsp_get_option_type($cur_option) eq "select") {

      print "<tr><td>" . $text{"$_"} . "</td>\n";
      if ($in{"name"} ne "Default") {
        print "<td><input type=\"radio\" name=\"def_$cur_option\" value=\"Default\""; print " checked" if ($def);
        print ">" . $text{"default"} . "</td>\n";
        print "<td><input type=\"radio\" name=\"def_$cur_option\" value=\"NoDefault\""; print " checked" if (! $def);
      } else {
        print "<td><input type=\"checkbox\" name=\"def_$cur_option\" value=\"NoDefault\""; print " checked" if (! $def);
      }
      print "><select name=\"$cur_option\" size=\"1\">\n";
      $has_selected = 0;
      foreach (&ltsp_get_possible_values($cur_option)) { 
        $pos_val = $_;
        chomp($pos_val);
        if ($conf{"$cur_option"} eq "$pos_val") {
          print "<option value=\"$pos_val\" selected>";
          $has_selected = 1;
        } else {
          print "<option value=\"$pos_val\">";
        }

        if (&ltsp_need_value_translation($cur_option)) {
          print $text{"$pos_val"} . "\n";
        } else {
          print "$pos_val\n";
        }
      }
      if ((!$def) and (!$has_selected)) {
        print "<option value=\"" . $conf{"$cur_option"} . "\" selected>" . $conf{"$cur_option"};
      }
      print "</select></td></tr>\n";
    } else {
      print "<tr><td>" . $text{"$_"} . "</td>\n";
      if ($in{"name"} ne "Default") {
        print "<td><input type=\"radio\" name=\"def_$cur_option\" value=\"Default\""; print " checked" if ($def);
        print ">" . $text{"default"} . "</td>\n";
        print "<td><input type=\"radio\" name=\"def_$cur_option\" value=\"NoDefault\""; print " checked" if (! $def);
      } else {
        print "<td><input type=\"checkbox\" name=\"def_$cur_option\" value=\"NoDefault\""; print " checked" if (! $def);
      }
      print ">\n";

      print "<input type=\"text\" name=\"$_\" value=\"" . $conf{"$_"} . "\">\n";
      print "</td></tr>\n";
    }

  }

  print "</table><br>\n";

}

#
# Submit button
# 

print "</tr><tr $cb><td><input type=\"submit\" value=\"" . $text{'save_settings'} . "\">\n</td></tr></form>\n";

#
# Delete button
# 

if (($in{"name"} ne "Default") && ($in{"action"} ne "add")) { 
  print "<form action=\"index.cgi\" method=\"post\">\n";
  print "<input type=\"hidden\" name=\"action\" value=\"delete\">\n";
  print "<input type=\"hidden\" name=\"name\" value=\"" . $in{"name"} . "\">\n";
  print "<tr $cb><td><input type=\"submit\" value=\"" . $text{'delete_host'} . "\">\n</td></tr></form>\n"; 
}

print "</td></tr></table>\n";

print "</td> </tr>\n";
print "</table>\n";

print "<br><hr>\n";
&footer("", $text{'index'});

