use inc::Module::Install;

name 'Yacd';
all_from 'lib/Yacd.pm';
author q{Laurent KISLAIRE <teebeenator@gmail.com>};
license 'perl';

build_requires 'Test::More';
requires 'Convert::Binary::C' => '0';
#test_requires 'CcsdsTools' => '0';
#test_requires 'Ccsds' => '0';

test =>
  { TESTS => q[t/00-load.t t/01-packet.t t/02-framelog.t t/pod.t ] };

auto_install;

WriteAll;
