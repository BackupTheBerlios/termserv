#!/usr/bin/perl

$DEBUG = 0;

# Hash "profiles"
# Contains the host configuration entry name as key
# and the configuration values as "conf,value;conf,value"

%profiles = ();

# Reads the configuration file
# puts information into %profiles

sub ltsp_read_config($) { 

  %profiles = ();

  my $config_file = shift(@_);

  print "ltsp_read_config: reading $config_file<br>\n" if $DEBUG;

  &lock_file("$config_file");
  open (LST, "<$config_file");
  @lines = (<LST>);
  close (LST);
  &unlock_file("$config_file");
  &webmin_log("read", "file", $config_file, );

  for ($i = 0; $i<$#lines; $i++) {

    $_ = $lines[$i];

    # If current line is just a comment, leave the rest out

    if (/^\#/) { next; }

    # If the current line is the beginning of a host
    # configuration entry (="hce")

    if (/^\[(.*)?\]/) {
      $cur_hce = "$1";
      print "ltsp_read_config: $1<br>\n" if $DEBUG;

      do {
        $i++;
        $lines[$i] =~ s/ //g;
        chop($lines[$i]);

        # If line is not empty or a comment
        if ((length($lines[$i]) != "0") and (!($lines[$i] =~ /^\#/))) {
          ($key, $value) = split(/=/, $lines[$i]);
          $value =~ s/\"//g;
          $profiles{"$cur_hce"} .= ";$key,$value";
        }
      } until (($lines[$i+1] =~ /^\[(.*)?\]/) or ($#lines == $i));
    }
  }

  # Kill semicolon
  foreach (keys(%profiles)) {
    $profiles{"$_"} = substr($profiles{"$_"}, 1);
  }

}

sub ltsp_write_config($) {

  my $conf_file = shift(@_);
  &lock_file("$conf_file");
  open (LST, ">$conf_file");

  foreach (&ltsp_get_hces()) {
    my $cur_hce = $_;
    if (&ltsp_get_configuration($cur_hce) != 0) {
      %conf = &ltsp_get_configuration($cur_hce);
      print "ltsp_write_config: hce is $cur_hce\n<br>" if $DEBUG;
      print LST "[$cur_hce]\n";
      print "<tt>LST: [$cur_hce]</tt><br>\n" if $DEBUG;
      foreach (keys(%conf)) {
        print LST "$_ = \"" . $conf{"$_"} . "\"\n";
        print "<tt>LST $_ = \"" . $conf{"$_"} . "\"</tt><br>\n" if $DEBUG;
      } 
    }
  }

  close (LST);
  &unlock_file("$conf_file");
  &webmin_log("write", "file", $conf_file, );

}

sub ltsp_get_hces() {

  return sort(keys(%profiles));

}

sub ltsp_get_configuration($) {

  my $prof = shift(@_);
  my %ret_hash = ();

  if ($profiles{"$prof"} eq "") { return 0; }

  foreach (split(/;/, $profiles{"$prof"})) {
    ($key, $value) = split(/,/); 
    $ret_hash{"$key"} = $value;
    print "ltsp_get_configuration: key is $key, value is $value\n<br>" if $DEBUG;
  }

  return %ret_hash;

}

sub ltsp_get_option_groups() {

  print "ltsp_get_option_groups called<br>\n" if $DEBUG;

  my @options = ();

  open (LST, "./options/order");
  foreach (<LST>) {
    chop;
    print "ltsp_get_option_groups: $_<br>\n" if $DEBUG;
    s/=(.*)?$//;
    print "ltsp_get_option_groups: $_<br>\n" if $DEBUG;
    push (@options, $_);
  }
  close (LST);

  return @options;

}

sub ltsp_get_options() {

  print "ltsp_get_options called<br>\n" if $DEBUG;

  my $option = shift(@_);
  my @options = ();

  open (LST, "./options/order");
  foreach (<LST>) {
    chop;
    if (/^$option/) {
      print "ltsp_get_options: option found<br>\n" if $DEBUG;
      s/^(.*)?=//;
      foreach (split(/\,/)) {
        push (@options, $_);
        print "ltsp_get_options: $_<br>\n" if $DEBUG;
      }
    }
  }
  close (LST);

  return @options;

}

sub ltsp_get_option_type($) {

  my $option = shift(@_);
  if (-e "./options/$option/select") {
    return "select";
  } elsif (-e "./options/$option/ip") {
    return "ip";
  }

}

sub ltsp_get_possible_values($) {

  my $option = shift(@_);

  if (&ltsp_get_option_type("$option") ne "select") { return (); }

  open (LST, "<./options/$option/options");
  @values = (<LST>);
  close (LST);

  return @values;

}

sub ltsp_need_value_translation($) {

  my $option = shift(@_);

  if ( -e "./options/$option/translate") {
    return 1;
  }
  return 0;
}

sub ltsp_modify_entry($, %) {

  ($entry, %data) = @_;
  $profiles{"$entry"} = "";
  foreach (keys(%data)) {
    $profiles{"$entry"} .= ";$_," . $data{"$_"};
  }
  print "ltsp_modify_entry: $entry is " . $profiles{"$entry"} . "<br>\n" if $DEBUG;
  $profiles{"$entry"} = substr($profiles{"$entry"}, 1);

}

return TRUE;
