package Yacd;

use warnings;
use strict;
use 5.010;

=head1 NAME

Yacd - Module used to decode CCSDS TM

=cut

our $VERSION = '1.2';

require Exporter;
use base qw/Exporter/;
our @EXPORT_OK = qw($VERSION);

=head1 SYNOPSIS

This library allows decoding of CCSDS frames and packets as defined in the PSS/ECSS standards.

    use Yacd;
    use Data::Dumper;
    use Convert::Binary::C;

    #User defined callbacks
    sub pkt_tm_decode{
        my ($pkt,$raw,$rec_head)=@_;
        print Dumper($pkt);
    }
    sub tmfe_decode{
        my ($frame,$raw,$rec_head)=@_;
        print Dumper($frame);
    }

    #Load Customization of protocol
    my $c = eval {
    Convert::Binary::C->new(
        IntSize=>4,
        ShortSize=>2,
        Alignment=>1,
        CompoundAlignment=>1,
        ByteOrder=>'BigEndian',
        UnsignedChars=>1,
        UnsignedBitfields=>1,
        #OrderMembers=>1,   # requires Tie::Hash::Indexed to minimize performance decrease (min x3!)
        ) ->parse_file('custo.h')
    };

    if ($@) {
        die "The structure definition was not parsed properly:\n$@";
    }

    #Prepare config to module. Callbacks are called for each frame or packet found
    my $config={
        coderefs_packet=>[ \&main::pkt_tm_decode, ], #callbacks for packets
        coderefs_frame=>[\&main::tmfe_record],       #callbacks for frames
        idle_frames=>1,                              #also pass idle frames to callback
        idle_packets=>1,                             #also pass idle packets to callback
        c=>$c,                                       #protocol definition
        skip=>13000,                                 #skip n frames (until the next packet)
        frame_nr=>20042,                             #decode n frames (until the last packet is finished)
        full_packet=>0,                              #full packet decoding to coderefs
        full_frame=>0,                               #full frame decoding to coderefs
        search_sync=>0,                              #provides sync search when sync missing
    };

    #Launch loop on logfile
    read_frames($ARGV[0],$config);


=head1 AUTHOR

Laurent KISLAIRE, C<< <teebeenator at gmail.com> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Yacd


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Laurent KISLAIRE.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

=head1 AUTHOR

Laurent KISLAIRE, C<< <teebeenator at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<teebeenator at gmail.com>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Yacd


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Laurent KISLAIRE.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Yacd
