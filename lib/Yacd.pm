package Yacd;

use warnings;
use strict;

=head1 NAME

Ccsds - Module used to decode CCSDS TM

=cut

our $VERSION = '1.0';

require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw($VERSION);

=head1 SYNOPSIS

This library allows decoding of CCSDS frames and packets as defined in the PSS/ECSS standards.

    use Yacd;
    use Data::Dumper;
    
    my $c = eval {
    #Load Customization of protocol
    Convert::Binary::C->new(
        IntSize=>4,
        ShortSize=>2,
        Alignment=>1,
        CompoundAlignment=>1,
        ByteOrder=>'BigEndian',
        UnsignedChars=>1, 
        UnsignedBitfields=>1,
#        OrderMembers=>1,   # requires Tie::Hash::Indexed to minimize performance decrease (min x3!)
        ) ->parse_file('custo.h')
    };
    if ($@) {
        die "The structure definition was not parsed properly:\n$@";
    } 
    #Prepare config to module. Callbacks are called for each frame or packet found
    my $config={
            coderefs_packet=>[ \&main::pkt_tm_decode, ],
            coderefs_frame=>[\&main::tmfe_record],
            idle_frames=>1,  #also pass idle frames to callback
            idle_packets=>1, #also pass idle packets to callback
            c=>$c,
    }

    #Launch loop. The callbacks will be triggered
    read_frames($ARGV[0],$config);   

    sub pkt_tm_decode{
        my ($pkt,$raw,$rec_head)=@_;
        print Dumper($pkt);
    }
    sub tmfe_decode{
        my ($frame,$raw,$rec_head)=@_;
        print Dumper($frame);
    }
}

=head1 AUTHOR

Laurent KISLAIRE, C<< <teebeenator at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<teebeenator at gmail.com>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ccsds


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Laurent KISLAIRE.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

}

=head1 AUTHOR

Laurent KISLAIRE, C<< <teebeenator at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<teebeenator at gmail.com>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ccsds


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Laurent KISLAIRE.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Ccsds
