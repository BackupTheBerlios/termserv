#!/usr/bin/perl

do "../web-lib.pl";
require "./globals.pl";

sub ltsp_etherboot_image_list() {

  opendir (DIR, $config{"path_to_rom_images"});
  @imgs = readdir (DIR);
  closedir (DIR);

  foreach (@imgs) {
    if (/^\w/) {
      s/\.lzrom//;
      push (@res, $_);
    }
  }

  return @res;

}

return TRUE;

