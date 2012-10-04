#!/usr/bin/perl
use strict;
use warnings;
use Yacd::File::FrameLog qw/frames_loop/;
use Data::Dumper;
use Convert::Binary::C;

my ($vc, %dist_vc );

sub packet_decode {
    my ( $struct, $raw, $rec_head ) = @_;

#    die Dumper($struct);
    my $pcat=$struct->{pkt}{pkt_hdr}{bn};
    open my $f, ">>", "log_${vc}_$pcat";
    print $f unpack('H*',$raw), "\n";
    return;
}

sub tmfe_decode {
    my ( $struct, $raw, $rec_head ) = @_;

    #die Dumper($struct);

    $vc = $struct->{channel_id}{vcid};
    $dist_vc{$vc}->{n}++;
    return;
}

sub cbc {
    my $c = eval {
        Convert::Binary::C->new(
            IntSize           => 4,
            ShortSize         => 2,
            Alignment         => 1,
            CompoundAlignment => 1,
            ByteOrder         => 'BigEndian',
            UnsignedChars     => 1,
            UnsignedBitfields => 1,
        )->parse_file( $_[0] );
    };

    if ($@) {
        die "The structure definition was not parsed properly:\n$@";
    }

    #Record_hdr_t elements are LittleEndian
    #$c->tag('record_hdr_t', ByteOrder => 'LittleEndian');
    return $c;
}

my $fname = shift        or die "Error\n  class.pl logfile [ cfile ]\n";
my $custo = shift // "custo.h";

my $sz       = -s $fname or die "Can't open $fname";

my $config = {
    c => cbc($custo),
    coderefs_packet => [ \&main::packet_decode, ],
    coderefs_frame  => [ \&main::tmfe_decode ],
    skip            => 200_000,
    frame_nr        => 6_000,
    #    idle_frames     => 1,
    full_packet     => 1,
    #    full_frame      => 1,
};

frames_loop( $config, $fname );

warn Dumper( \%dist_vc ), "\n";

