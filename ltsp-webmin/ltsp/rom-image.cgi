#!/usr/bin/perl
# rom-image.cgi

do '../web-lib.pl';
require './ltsp-lib.pl';
require "./ltsp-etherboot-lib.pl";

&init_config();

&ReadParse();

$image = $in{"image"};
$format = $in{"output"};

if ($format eq "floppy_loadable_image") {
  if (-e ($config{"path_to_etherboot"} . "/floppyload.bin")) {
    print "Content-type: application/octet-stream\n\n";
    &include($config{"path_to_etherboot"} . "/floppyload.bin");
  } elsif (-e ($config{"path_to_etherboot"} . "/boot1a.bin")) {
    print "Content-type: application/octet-stream\n\n";
    &include($config{"path_to_etherboot"} . "/boot1a.bin");
  } else {
    &header("Error");
    $whatfailed = &text("error_finding_floppy_boot_sector");
    &error(&text("file_not_found"));
    exit;
  }
}

if ($format ne "floppy_loadable_image") { 
  print "Content-type: application/octet-stream\n\n";
}

&include($config{"path_to_rom_images"} . "/$image.lzrom");
