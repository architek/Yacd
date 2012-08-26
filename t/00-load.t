#!perl -T

use Test::More tests => 3;

BEGIN {
    use_ok('Yacd')              || print "Bail out!  ";
    use_ok('Yacd::Packet')      || print "Bail out!  ";
    use_ok('Yacd::File::Frame') || print "Bail out!  ";
}

diag("Testing Yacd loading $Yacd::VERSION, Perl $], $^X");
