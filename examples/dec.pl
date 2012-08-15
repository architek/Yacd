#!/usr/bin/perl
use strict;
use warnings;
use Yacd::File::Frame qw/frames_loop/;
use Data::Dumper;
use Convert::Binary::C;
use POSIX qw(strftime);

my $PERCENTAGE = 1;
my ( $nf, $np, $slice );
my ( $vc, %dist_vc );

sub tl { warn strftime( "%H:%M:%S ", localtime ), ":", @_, "\n"; return;}

sub packet_decode {
    my ( $struct, $raw, $rec_head ) = @_;

    #die Dumper($struct);
    #warn "Len:", length($raw) ,"\n";
    $np++;
    return;
}

sub tmfe_decode {
    my ( $struct, $raw, $rec_head ) = @_;

    #die Dumper($struct);
    $nf++;

    #$vc = $struct->{frame_hdr}{channel_id}{vcid};  #Full frame passed
    $vc = $struct->{channel_id}{vcid};
    $dist_vc{$vc}->{n}++;
    if ( $PERCENTAGE and $nf % int( $slice * $PERCENTAGE / 100 ) == 0 ) {
        tl "Progress : " . int( 100 * $nf / $slice ) . "%";
    }
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

my $fname = shift        or die "Error\n  dec.pl logfile [ cfile ]\n";
my $custo = shift // "custo.h";

my $sz       = -s $fname or die "Can't open $fname";

my $config = {
    c => cbc($custo),
    coderefs_packet => [ \&main::packet_decode, ],
    coderefs_frame  => [ \&main::tmfe_decode ],
    #    idle_frames     => 1,
    #    full_packet     => 1,
    #    full_frame      => 1,
};

$slice = $sz / $config->{c}->sizeof('record_t');

tl "Start - Detected $sz bytes, $slice blocks\n";
frames_loop( $config, $fname );
tl "End - $np non idle packets";

warn Dumper( \%dist_vc ), "\n";

