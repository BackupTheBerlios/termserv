#!/usr/bin/perl

$DEBUG = 1;
$EXPERIMENTAL = 1;

# LTSP versions. We use a hash for comparison, because unfortunately
# the pre versions often differ very much from the final ones and
# they are named in a way that makes direct comparison impossible.
%versions = (
  "1.0"      => 1000,
  "1.03"     => 1030,
  "1.92"     => 1920,
  "2.0"      => 2000,
  "2.01"     => 2010,
  "2.02"     => 2020,
  "2.03"     => 2030,
  "2.04"     => 2040,
  "2.05"     => 2050,
  "2.06"     => 2060,
  "2.07"     => 2070,
  "2.08"     => 2080,
  "2.09pre1" => 2081,
  "2.09pre2" => 2082,
  "2.09"     => 2090
);

return TRUE;
