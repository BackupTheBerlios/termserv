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

    # If current line is just a comment or empty, leave the rest out

    if (/^\#/) { next; }
#    if (length($_) != "0") { next; }

    # If the current line is the beginning of a host
    # configuration entry (="hce")

    if (/^\[(.*)?\]/) {
      $cur_hce = "$1";

      do {
        $i++;
        $lines[$i] =~ s/ //g;
        chop($lines[$i]);

        # If line is not empty or a comment
        if ((length($lines[$i]) != "0") and (!($lines[$i] =~ /^\#/))) {
          ($key, $value) = split(/=/, $lines[$i]);
          # RESPECT NOQUOTE!
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

  print "_ltsp_modify_entry_on_write called<br>\n" if $DEBUG;
  # This function reads a list, which contains the entry in the
  # config file, and a hash, which contains the configuration
  # information of the entry; it returns the modified list

  *lines = shift(@_);

  %cur_conf = ();
  
  for ($i = 0; $i<=$#lines; $i++) {

    $_ = $lines[$i];
    chomp;
    if (/^\#/) { next; }
    if (length($_) == "0") { next; }
    if (/^\[(.*)?\]/) { 
      $host = $1;
      next; 
    }

    ($key, $value) = split(/=/);
    chomp($key); $key =~ s/( *)?//g;
    chomp($value); $value =~ s/( *)?//g;
    $value =~ s/\"//g;
    $cur_conf{"$key"} .= $value;
  }

  %conf = &ltsp_get_configuration($host);

  (*added, *deleted, *modified, *nonmodifed) = &compare_hashes(\%cur_conf, \%conf);

  for ($i = 0; $i<=$#lines; $i++) {
    $_ = $lines[$i];
    chomp;
    if (/^\#/) { next; }
    if (length($_) == "0") { next; }
    if (/^\[(.*)?\]/) { next; }

    ($key, $value) = split(/=/);
    chomp($key); $key =~ s/( *)?//g;
    chomp($value); $value =~ s/( *)?//g;
    $value =~ s/\"//g;

    # And once again Larry gets on my ****. He is too stupid to invent
    # the "a in b" operator which returns true when string a is in array b
    # even the squichie eaters languages from Wirth have this simple operation!
 
    foreach (@deleted) {
      if ($_ eq $key) {
        splice(@lines, $i, 1);
      }
    }    

    foreach (@modified) {
      if ($_ eq $key) {
        print "modified: $_<br>\n" if $DEBUG;
        if ($lines[$i] =~ /( *)?(\w*)?(.*)?=(.*)?\"(.*)?\"(.*)?/) {
          $rep = $conf{"$_"};
          if (&ltsp_value_needs_quotes("$_")) {
            $lines[$i] =~ s/=(.*)?\"(.*)?\"(.*)?/=$1\"$rep\"$3/;
          } else {
            $lines[$i] =~ s/=(.*)?\"(.*)?\"(.*)?/=$1$rep$3/;
          }
        } elsif ($lines[$i] =~ /( *)?(\w*)?(.*)?=((\t| )*)?([^ ]*)?( *)?/) {
          $rep = $conf{"$_"};
          if (&ltsp_value_needs_quotes("$_")) {
            $lines[$i] =~ s/=((\t| )*)?([^ ]*)?( *)?/=$1\"$rep\"$3/;
          } else {
            $lines[$i] =~ s/=((\t| )*)?([^ ]*)?( *)?/=$1$rep$3/;
          }
        }
      }
    }

  }

  foreach (@added) {
    if (&ltsp_value_needs_quotes("$_")) {
      push (@lines, "$_ = \"" . $conf{"$_"} . "\"\n");
    } else {
      push (@lines, "$_ = " . $conf{"$_"} . "\n");
    }
  }

  print "_ltsp_modify_entry_on_write says bye-bye<br>\n" if $DEBUG;

}

sub ltsp_write_config($) {

  print "ltsp_write_config: procedure called\n<br>" if $DEBUG;

  my $config_file = shift(@_);

  &lock_file("$config_file");
  open (LST, "<$config_file");
  my @lines = (<LST>);
  close (LST);
  &unlock_file("$config_file");
  &webmin_log("read", "file", $config_file, );

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
      print "ltsp_write_config: delete lines $begin_delete to $end_delete\n<br>" if $DEBUG;
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
      print "ltsp_write_config: modifying lines $begin_modify to $end_modify\n<br>" if $DEBUG;
      # TMTOWTDI - har har - lick my shiny metal a**, Larry!
      for ($i = $begin_modify; $i < $end_modify; $i++) { 
        print "<tt><font color=\"#1fff1f\">" . $lines[$i] . "</font></tt>\n<br>" if $DEBUG;
        push (@mod_lines, $lines[$i]); 
      }
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
        push (@lines, "[$cur_hce]\n");
        foreach (keys(%conf)) { 
          if (&ltsp_value_needs_quotes("$_")) {
            push (@lines, "$_ = \"" . $conf{"$_"} . "\"\n"); 
          } else {
            push (@lines, "$_ = " . $conf{"$_"} . "\n"); 
          }
        } 
      }
    }
  }

  &lock_file("$config_file");
  open (LST, ">$config_file");

  # Insert file writing operation code here
 
  foreach (@lines) { 
    print LST "$_"; 
    print "<tt><font color=\"#0000ff\">$_</font></tt><br>\n" if $DEBUG;
  }

  close (LST);
  &unlock_file("$config_file");
  &webmin_log("write", "file", $config_file, );

  # Set back "helper" variables
  @added_hosts = ();
  @modified_hosts = ();
  @deleted_hosts = ();

  print "ltsp_write_config: procedure finished\n<br>" if $DEBUG;

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

  my $option = shift(@_);
  my @options = ();

  open (LST, "./options/order");
  foreach (<LST>) {
    chop;
    if (/^$option/) {
      s/^(.*)?=//;
      foreach (split(/\,/)) {
        push (@options, $_);
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
  } else {
    return 0;
  }
}

sub ltsp_modify_entry($, %) {

  ($entry, %data) = @_;

  # Test whether the entry is empty
  # empty means that the entry does not yet exist,
  # so it's been created

  if ($profiles{"$entry"} eq "") {
    $newhost = 1;
    push (@added_hosts, $entry);
    print "ltsp_modify_entry: $entry is a new entry<br>\n" if $DEBUG;
  }

  $profiles{"$entry"} = "";
  foreach (keys(%data)) {
    $profiles{"$entry"} .= ";$_," . $data{"$_"};
  }
  print "ltsp_modify_entry: $entry is " . $profiles{"$entry"} . "<br>\n" if $DEBUG;
  $profiles{"$entry"} = substr($profiles{"$entry"}, 1);

  if (!($newhost eq 1) && !($profiles{"$entry"} eq "")) {
    push (@modified_hosts, $entry);
    print "ltsp_modify_entry: $entry is a modified entry<br>\n" if $DEBUG;
  }

  # Test whether the entry is empty at the end
  # empty means that the entry does not have any configuration
  # so the user wanted to delete that entry

  if ($profiles{"$entry"} eq "") {
    push (@deleted_hosts, $entry);
    print "ltsp_modify_entry: $entry is a deleted entry<br>\n" if $DEBUG;
  }

}

return TRUE;
