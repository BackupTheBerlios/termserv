#!/usr/bin/perl

require "./helper.pl";

require "./globals.pl";

# Hash "profiles"
# Contains the host configuration entry name as key
# and the configuration values as "conf,value;conf,value"

%profiles = ();

# Lists "added_hosts", "modified_hosts" and "deleted_hosts
# contain new, modified or deleted hosts; these lists
# are needed for simpler non-rewriting configuration file
# operations

@added_hosts = ();
@modified_hosts = ();
@deleted_hosts = ();

$version = "unknown";

# This has to be used instead of header() by all cgis!
sub ltsp_header {
  &header(@_);
# This code reads /etc/ltsp.conf if there and ignores the
# ltsconf_path setting. It works, but we need to handle this better,
# so it is commented out.
#
#  # TODO: make location of ltsp.conf configurable?
#  if (-e "/etc/ltsp.conf") {
#    open (LST, "</etc/ltsp.conf");
#    my @lines = (<LST>);
#    close (LST);
#    foreach $_ (@lines) {
#      # If current line is just a comment or empty, leave the rest out
#      if (/^\#/) { next; }
#      if(/^\s*LTSP_DIR\s*=\s*(.+)\s*/) {
## hack!
#        $config{"ltsconf_path"} = "$1/i386/etc";
#        last;
#      }
#    }
#  }
  $version = ltsp_read_version($config{"ltsconf_path"} . "/version");
  error($text{"unknown_version"} . " $version.") unless ($versions{$version});
  if($DEBUG) {
    &ltsp_check_options();
  }
}

sub ltsp_read_version($) { 

  my $version_file = shift(@_);
  my $vers = "unknown";
  open (LST, "<$version_file");
  my @lines = (<LST>);
  close (LST);
  # for ($i = 0; $i<$#lines; $i++) does not work, it does not get all lines.
  # Why? But foreach is more elegant anyway.
  foreach $_ (@lines) {
    # If current line is just a comment or empty, leave the rest out
    if (/^\#/) { next; }
    if(/^\s*VERSION\s*=\s*(.+)\s*/) {
      $vers = "$1";
      last;
    }
  }
  print "version: $vers<br>\n" if $DEBUG;
  return $vers;
}

# Reads the configuration file
# puts information into %profiles

sub ltsp_read_config($) { 

  %profiles = ();

  my $config_file = shift(@_);
  error("config file $config_file not found") unless ( -e $config_file);

  &lock_file("$config_file");
  open (LST, "<$config_file");
  @lines = (<LST>);
  close (LST);
  &unlock_file("$config_file");
  &webmin_log("read", "file", $config_file, );

  for ($i = 0; $i<$#lines; $i++) {

    $_ = $lines[$i];

    # If current line is just a comment or empty, leave the rest out

    if (/^\#/) { next; }

    # If the current line is the beginning of a host
    # configuration entry (="hce")

    if (/^\[(.*)?\]/) {
      $cur_hce = "$1";

      do {
        $i++;
        # $lines[$i] =~ s/ //g;
        chomp($lines[$i]);

        # If line is not empty or a comment
        if ((length($lines[$i]) != "0") and (!($lines[$i] =~ /^\#/))) {
          ($key, $value) = split(/=/, $lines[$i]);

          $key =~ s/(\s*)?//g;
          $value =~ s/^(\s*)?//;
          $value =~ s/(\s*)$//;
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

sub _ltsp_modify_entry_on_write(@) {

  # This function reads a list, which contains the entry in the
  # config file, and a hash, which contains the configuration
  # information of the entry; it returns the modified list

  *lines = shift(@_);

  %cur_conf = ();
  
  for ($i = 0; $i<=$#lines; $i++) {

    $_ = $lines[$i];

    if (/^\#/) { next; }
    if (length($_) == "0") { next; }
    if (/^\s*?\[(.*)?\]/) { $host = $1; next; }

    ($key, $value) = split(/=/);
    $key =~ s/(\s*)?//g;
    $value =~ s/^(\s|\t)*(\"{0,1})(.*?)\"{0,1}\s*$/$3/;
    $cur_conf{"$key"} .= $value;
  }

  %conf = &ltsp_get_configuration($host);

  (*added, *deleted, *modified, *nonmodifed) = &compare_hashes(\%cur_conf, \%conf);

  for ($i = 0; $i<=$#lines; $i++) {
    $_ = $lines[$i];
    if (/^\#/) { next; }
    if (length($_) == "0") { next; }
    if (/\s+?\[(.*)?\]/) { next; }

    ($key, $value) = split(/=/);
    $key =~ s/(\s*)?//g;
    $value =~ s/^(\s|\t)*(\"{0,1})(.*?)\"{0,1}\s*$/$3/;

    # And once again Larry gets on my ****. He is too stupid to invent
    # the "a in b" operator which returns true when string a is in array b
    # even the squichie eaters languages from Wirth have this simple operation!
# It's not an operator, but it works like this:
# if grep /^$a$/, @b
# returns true if and only if $a is in @b.
# So this should work:
#   if grep /^$key$/, @deleted {
#      if (&_ltsp_option_exists($key)) {
#        splice(@lines, $i, 1);
#      }
#    }
# etc.
  
    foreach (@deleted) {
      if ($_ eq $key) {
        print "delete?: $_<br>\n" if $DEBUG;
        if (&_ltsp_option_exists($_)) {
          splice(@lines, $i, 1);
        } else {
          print "i don't know this $_, so I refuse to delete the bastard!<br>\n" if $DEBUG;
        }
      }
    }    

    foreach (@modified) {
      if ($_ eq $key) {
        print "modified: $_<br>\n" if $DEBUG;
        if ($lines[$i] =~ /(\s*)?(\w*)?(.*)?=(.*)?\"(.*)?\"(.*)?/) {
          $rep = $conf{"$_"};
          if (&ltsp_value_needs_quotes("$_")) {
            $lines[$i] =~ s/=(.*)?\"(.*)?\"(.*)?/=$1\"$rep\"$3/;
          } else {
            $lines[$i] =~ s/=(.*)?\"(.*)?\"(.*)?/=$1$rep$3/;
          }
        } elsif ($lines[$i] =~ /(\s*)?(\w*)?(.*)?=(\s*)?([^ ]*)?( *)?/) {
          $rep = $conf{"$_"};
          if (&ltsp_value_needs_quotes("$_")) {
            $lines[$i] =~ s/=(\s*)?([^ ]*)?( *)?/=$1\"$rep\"$3/;
          } else {
            $lines[$i] =~ s/=(\s*)?([^ ]*)?( *)?/=$1$rep$3/;
          }
        }
      }
    }

  }

  foreach (@added) {
    if (&ltsp_value_needs_quotes("$_")) {
      push (@lines, "$_ = \"" . $conf{"$_"} . "\"");
    } else {
      push (@lines, "$_ = " . $conf{"$_"});
    }
  }

  print "_ltsp_modify_entry_on_write says bye-bye<br>\n" if $DEBUG;

}

sub ltsp_write_config($) {

  my $config_file = shift(@_);

  &lock_file("$config_file");
  open (LST, "<$config_file");
  my @lines = (<LST>);
  close (LST);
  &unlock_file("$config_file");
  &webmin_log("read", "file", $config_file, );

  for ($i = 0; $i <= $#lines; $i++) { $lines[$i] =~ s/\n$//; } 

  # Do we have any hosts deleted?
  if ($#deleted_hosts != -1) {
    foreach (@deleted_hosts) {
      $i = 0;

      # Find out where to begin deletion
      BEGINDELETE: for ($i = 0; $i < $#lines; $i++) {
        if ($lines[$i] =~ /^\[$_\]/) {
          $begin_delete = $i;
          last BEGINDELETE;
        }
      }
      # Find out where to stop deletion
      ENDDELETE: while ($i <= $#lines) {
        $i++;
        if ($lines[$i] =~ /^\[(.*)?\]/) {
          $end_delete = $i-1;
          last ENDDELETE;
        }
      }
      # In case of EOF
      if ($end_delete != $i) { $end_delete = $i; }
      splice (@lines, $begin_delete, $end_delete-$begin_delete);
    }
  }

  #
  # Do we have modified hosts?
  #

  if ($#modified_hosts ne -1) {

    foreach (@modified_hosts) {
      $i = 0;

      # Find out where to begin modification
      BEGINMODIFY: for ($i = 0; $i < $#lines; $i++) {
        if ($lines[$i] =~ /^\[$_\]/) {
          $begin_modify = $i;
          last BEGINMODIFY;
        }
      }
      # Find out where to stop deletion
      ENDMODIFY: while ($i <= $#lines) {
        $i++;
        if ($lines[$i] =~ /^\[(.*)?\]/) {
          $end_modify = $i-1;
          last ENDMODIFY;
        }
      }
      # In case of EOF
      if ($end_modify != $i) { $end_modify = $i; }
      # TMTOWTDI - har har - lick my shiny metal a**, Larry!
      for ($i = $begin_modify; $i < $end_modify; $i++) { 
        push (@mod_lines, $lines[$i]); 
      }

      # Okay, I give no business about empty lines and comments at the end of an entry
      #for ($i = $end_modify; $i > $begin_modify; $i--) {
      #  print "line is: <font color=#00ff00>" . $mod_lines[$i] . "</font><br>" if $DEBUG;
      #  if (($mod_lines[$i] =~ /^\s*?$/) || ($mod_lines[$i] =~ /^\s*?\#/)) {
      #    print "and it contains nonsense<br>" if $DEBUG;
      #    splice(@mod_lines, $i, 1);
      #  }
      #}

      # That's the only interesting subroutine here, believe me

      &_ltsp_modify_entry_on_write(\@mod_lines);
      splice(@lines, $begin_modify, $end_modify-$begin_modify, @mod_lines);
    }

  }

  #
  # Do we have any new hosts?
  #

  if ($#added_hosts ne -1) {
    foreach (@added_hosts) {
      my $cur_hce = $_;
      if (&ltsp_get_configuration($cur_hce) != 0) {
        %conf = &ltsp_get_configuration($cur_hce);
        push (@lines, "[$cur_hce]");
        foreach (keys(%conf)) { 
          if (&ltsp_value_needs_quotes("$_")) {
            push (@lines, "$_ = \"" . $conf{"$_"}. "\""); 
          } else {
            push (@lines, "$_ = " . $conf{"$_"}); 
          }
        } 
      }
    }
  }

  &lock_file("$config_file");
  open (LST, ">$config_file");

  # Insert file writing operation code here
 
  foreach (@lines) { 
    print LST "$_\n"; 
    print "<tt><font color=\"#0000ff\">$_</font></tt><br>\n" if $DEBUG;
  }

  close (LST);
  &unlock_file("$config_file");
  &webmin_log("write", "file", $config_file, );

  # Set back "helper" variables
  @added_hosts = ();
  @modified_hosts = ();
  @deleted_hosts = ();

}

sub ltsp_get_hces() {

  return keys(%profiles);

}

sub ltsp_get_configuration($) {

  my $prof = shift(@_);
  my %ret_hash = ();

  if ($profiles{"$prof"} eq "") { return 0; }

  foreach (split(/;/, $profiles{"$prof"})) {
    ($key, $value) = split(/,/); 
    $ret_hash{"$key"} = $value;
  }

  return %ret_hash;

}

sub ltsp_get_option_groups() {

  my @options = ();

  open (LST, "./options/order");
  foreach (<LST>) {
    chomp;
    s/=(.*)?$//;
    push (@options, $_);
  }
  close (LST);

  return @options;

}

sub ltsp_get_options() {

  my $option_group = shift(@_);
  my @options = ();
  my @order_options = ();
  my @existing_options = ();

  open (LST, "./options/order");
  foreach (<LST>) {
    chop;
    if (/^$option_group/) {
      s/^(.*)?=//;
      foreach (split(/\,/)) {
	push (@options, $_) if ltsp_is_option_supported($_);
      }
    }
  }
  close (LST);

  return @options;

}

sub ltsp_check_options() {

  my $option;
  my @order_options = ();
  my @existing_options = ();

  open (LST, "./options/order");
  foreach (<LST>) {
    chop;
    s/^(.*)?=//;
    foreach (split(/\,/)) {
      error("unknown option $_ in options/order!") unless _ltsp_option_exists($_);
      push (@order_options, $_);
    }
  }
  close (LST);

  opendir (LST, "./options");
  @existing_options = grep !/^\.\.?$/, readdir LST;
  foreach $option (@existing_options) {
    if (-d "./options/$option") {
      error("Option $option exists but is not in options/order!") unless grep /$option/, @order_options;
    }
  }
}

sub ltsp_get_option_type($) {

  my $option = shift(@_);
  if (-e "./options/$option/select") {
    return "select";
  } elsif (-e "./options/$option/ip") {
    return "ip";
  } elsif (-e "./options/$option/text") {
    return "text";
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

sub ltsp_is_option_supported($) {

  my $option = shift(@_);
  
  if (-e "./options/$option/required_version") {
    open (LST, "<./options/$option/required_version");
    my $req_version = (<LST>);
    chop($req_version);
    close (LST);
    error("unknown version $req_version for option $option") unless $versions{$req_version};
    my $min_version = $versions{$req_version};
    return 0 unless ($min_version le $versions{"$version"});
  }
  if (-e "./options/$option/deprecated_by_version") {
    open (LST, "<./options/$option/deprecated_by_version");
    my $dep_version = (<LST>);
    chop($dep_version);
    close (LST);
    error("unknown version $dep_version for option $option") unless $versions{$dep_version};
    my $max_version = $versions{$dep_version};
    return 0 unless ($versions{"$version"} lt $max_version);
  }
  return 1;
}

sub ltsp_need_value_translation($) {

  my $option = shift(@_);

  if ( -e "./options/$option/translate") {
    return 1;
  }
  return 0;
}

sub ltsp_value_needs_quotes($) {

  my $option = shift(@_);

  if ( -e "./options/$option/quoted") {
    return 1;
  }
  return 0;
}

sub ltsp_modify_entry($, %) {

  ($entry, %data) = @_;

  # Test whether the entry is empty
  # empty means that the entry does not yet exist,
  # so it's been created

  if ($profiles{"$entry"} eq "") {
    $newhost = 1;
    push (@added_hosts, $entry);
  }

  $profiles{"$entry"} = "";
  foreach (keys(%data)) {
    $profiles{"$entry"} .= ";$_," . $data{"$_"};
  }
  $profiles{"$entry"} = substr($profiles{"$entry"}, 1);

  if (!($newhost eq 1) && !($profiles{"$entry"} eq "")) {
    push (@modified_hosts, $entry);
  }

  # Test whether the entry is empty at the end
  # empty means that the entry does not have any configuration
  # so the user wanted to delete that entry

  if ($profiles{"$entry"} eq "") {
    push (@deleted_hosts, $entry);
  }

}

sub _ltsp_option_exists($) {

  my $option = shift(@_);

  print "_ltsp_option_exists called, argument is $_<br>\n" if $DEBUG;

  if (-d "./options/$option/") {
    print "_ltsp_option_exists called, argument is $_ and exists<br>\n" if $DEBUG;
    return 1;
  }
  print "_ltsp_option_exists called, argument is $_ and doesn't exist<br>\n" if $DEBUG;
  return 0;

}

return TRUE;