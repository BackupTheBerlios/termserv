#!/usr/bin/perl

$DEBUG = 0;
$EXPERIMENTAL = 0;

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
  "2.09pre3" => 2083,
  "2.09pre4" => 2084,
  "2.09"     => 2090,
  "3.0.0"    => 3000,
  "3.0.1"    => 3001,
  "3.0.2"    => 3002,
  "3.0.3"    => 3003,
  "3.0.4"    => 3004,
  "3.0.5"    => 3005,
  "3.0.6"    => 3006,
  "3.0.7"    => 3007,
  "3.0.8"    => 3008,
  "3.0.9"    => 3009
);

return TRUE;
