#!/usr/bin/perl

$DEBUG = 1;

# This file contains some routines that can be used in
# a general fashion.

# compare_hashes is a function which requests an old
# hash and a new one. it return four arrays: the new,
# the modified, the deleted and the non-modified keys.

sub compare_hashes {

  $oldref = @_[0]; %old = %$oldref;
  $newref = @_[1]; %new = %$newref;

  local @added, @deleted, @modified, @notmodified;

  foreach (keys(%old)) {
    if (!(exists $new{"$_"} )) {
      push (@deleted, "$_");
      print "compare_hashes: old key exists, new key does not -> $_ deleted<br>\n" if $DEBUG;
    }
  }

  foreach (keys(%new)) {
    if (!(exists $old{"$_"} )) {
      push (@added, "$_");
      print "compare_hashes: new key exists, old key does not -> $_ added<br>\n" if $DEBUG;
    }
  }

  # item modified
  foreach (keys(%new)) {
    if ((exists $old{"$_"} ) && (exists $new{"$_"} ) && ($new{"$_"} ne $old{"$_"})) {
      push (@modified, "$_");
      print "compare_hashes: same keys, different -> $_ is modified<br>\n" if $DEBUG;
    }
  }

  # item not modified
  foreach (keys(%new)) {
    if ((exists $old{"$_"} ) && (exists $new{"$_"} ) && ($new{"$_"} eq $old{"$_"})) {
      push (@notmodified, "$_");
    }
  }

  return (\@added, \@deleted, \@modified, \@notmodified);

}

if (1 eq 2) {

  print "Can't buy me lo-hove, lo-hove ...\n";
  %a = ();
  %b = ();

  $a{A} = 1;
  $a{B} = 2;
  $a{C} = 3;
  $a{D} = 4;
  $a{E} = 5;

  $b{F} = 1;
  $b{B} = 4;
  $b{C} = 8;
  $b{D} = 2;
  $b{E} = 5;

  (*added, *deleted, *modified, *notmodified) = compare_hashes(\%a, \%b);

  foreach (@added) { print "added:\t\t $_\n"; }
  foreach (@deleted) { print "deleted:\t $_\n"; }
  foreach (@modified) { print "modified:\t $_\n"; }
  foreach (@notmodified) { print "notmodified:\t $_\n"; }
  
}

return TRUE;
