#!/usr/bin/perl
use strict;
use warnings;
use Yacd::File::Frame;
use Data::Dumper;
use Convert::Binary::C;

my $filename = $ARGV[0];
my $custo = $ARGV[1] // "custo.h";
my ( $nf, $np ) = ( 0, 0 );
my ( $vc, %dist_vc, $slice);
my $PERCENTAGE = 1;

my $config = {
    coderefs_packet => [ \&main::tm_packet_decode, ],
    coderefs_frame  => [ \&main::tmfe_decode ],
    c               => prep_struct(),
};

sub tm_packet_decode {
    my ( $pkt_hdr, $pkt_data_field_hdr, $raw, $rec_head ) = @_;
    $np++;
}

sub tmfe_decode {
    my ( $frame_hdr, $raw, $rec_head ) = @_;
    $nf++;

    $vc = $frame_hdr->{channel_id}{vcid};
    $dist_vc{$vc}->{n}++;
    if ( $PERCENTAGE and $nf % int( $slice * $PERCENTAGE / 100 ) == 0 ) {
        print "Progress : " . int( 100 * $nf / $slice ) . "%";
    }
}

my $sz = -s $filename;
$slice = $sz / $config->{c}->sizeof('record_t');
print "Detected $sz bytes, $slice blocks\n";

print "Start";
read_frames( $filename, $config );
print Dumper( \%dist_vc );
print "$np non_idle packets\n";
print "End";

sub prep_struct {
    my $c = eval {
        Convert::Binary::C->new(
            IntSize           => 4,
            ShortSize         => 2,
            Alignment         => 1,
            CompoundAlignment => 1,
            ByteOrder         => 'BigEndian',
            UnsignedChars     => 1,
            UnsignedBitfields => 1,
        )->parse_file($custo);
    };
    if ($@) {
        die "The structure definition was not parsed properly:\n$@";
    }
    #Record_hdr_t elements are LittleEndian
    $c->tag('record_hdr_t', ByteOrder => 'LittleEndian');
    return $c;
}
