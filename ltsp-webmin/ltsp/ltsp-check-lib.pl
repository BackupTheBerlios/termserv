#!/usr/bin/perl

require "./globals.pl";

sub ltsp_check_tftp() {

  open (LST, "</etc/inetd.conf");
  @lines = (<LST>);
  close (LST);

  foreach (@lines) {
    if (/^tftp/) {
      return 1;
    }
  }

  return 0;

}

return TRUE;
