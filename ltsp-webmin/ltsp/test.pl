#!/usr/bin/perl

%fuck = ();

$fuck{"a"} = 2;
$fuck{"b"} = 3;

print "Hossa!" if (%fuck eq ("1",2,"2",3));

%fuck = ();

print "Hossa nochmal!" if (%fuck eq ());
