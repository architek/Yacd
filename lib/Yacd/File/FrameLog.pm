package Yacd::File::FrameLog;

use warnings;
use strict;
use Carp;

=head1 NAME

Yacd::File::FrameLog - Module to decode logfile of CCSDS TM logfile record, Cadu, Frame and included packets

=cut

# BEGIN block is necessary here so that other modules can use the constants.
use vars qw( @EXPORT_OK %EXPORT_TAGS );

BEGIN {
    use Exporter qw( import );
    @EXPORT_OK   = qw/read_record frames_loop/;
    %EXPORT_TAGS = (
        CONSTANTS   => [qw(SYNC)],
        ERROR_CODES => [qw(YA_READ)],

    );

    # Add all the constant names and error code names to @EXPORT_OK
    Exporter::export_ok_tags(qw(CONSTANTS ERROR_CODES));
}

use constant SYNC    => "\x1a\xcf\xfc\x1d";
use constant YA_READ => 0;

use Yacd::Packet qw/parse_packet :ERROR_CODES/;

#Read a record from a file
#Passing the configuration is needed at last for knowing the size of a record
#
sub read_record {    #$record($file_handle, $configuration)
    my ( $fin, $config ) = @_;
    my $c          = $config->{c};
    my $len_record = $c->sizeof('record_t');
    my $raw;

    if ( read( $fin, $raw, $len_record ) != $len_record ) {
        carp "Could not read a full frame record\n";
        return YA_READ;
    }

    if ( $c->def('sync') ) {
        my $sync_offset = $c->offsetof( 'record_t', 'sync' );
        if ( substr $raw, $sync_offset, 4 ne SYNC ) {
            carp "Record does not contain a SYNC, reading next record";
            if ( $config->{search_sync} ) {
            }
            return YA_READ;
        }
    }
    return $raw;
}

sub frames_loop {    #$frame_nr($configuration,$filename)
    my ( $config, $filename ) = @_;

    my $c = $config->{c};
    my $res_pktdec;
    my $struct_pktdec = {};
    my @packet_vcid   = ("") x 128;        # VC 0..127
                                           #Forward idle
    my $frame_nr      = 0;
    my $skip          = $config->{skip};

    my $idle_frames  = $config->{idle_frames};
    my $idle_packets = $config->{idle_packets};

    #Full packets and frame decoding
    my $full_packet = $config->{full_packet};
    my $full_frame  = $config->{full_frame};

    open my $fin, "<", $filename or croak "Can not open $filename";
    binmode $fin;

    seek( $fin, $skip * $c->sizeof('record_t'), 0 ) if $skip;
  FRAME_DECODE:
    while ( !eof $fin ) {
        my $raw;

        #Extract frame from record
        next FRAME_DECODE unless $raw = read_record( $fin, $config );

        #Extract record header, Frame and headers
        my $rec_hdr = substr $raw, 0, $c->offsetof( 'record_t', 'cadu' );
        $raw = substr $raw, $c->offsetof( 'record_t', 'cadu.frame' ), $c->sizeof('frame_t');
        my $frame_hdr = $c->unpack( 'frame_hdr_t', $raw );
        my $frame_df_hdr = $c->unpack( 'frame_df_hdr_t', substr $raw, $c->sizeof('frame_hdr_t') );
        my $fhp = $frame_df_hdr->{fhp};

        #skip and such
        return $frame_nr if defined $config->{frame_nr} and $frame_nr >= $config->{frame_nr} and $fhp != 0b11111111111;
        if ($skip) {
            next FRAME_DECODE if $fhp == 0b11111111111;
            $skip = 0;
        }
        $frame_nr++;
        next FRAME_DECODE if $fhp == 0b11111111110 && !$idle_frames;

        if ($full_frame) {
            $_->( $c->unpack( 'frame_t', $raw ), $raw, $rec_hdr ) for @{ $config->{coderefs_frame} };
        }
        else {
            $_->( $frame_hdr, $raw, $rec_hdr ) for @{ $config->{coderefs_frame} };
        }

        #Extract frame data for non OID
        next FRAME_DECODE if $fhp == 0b11111111110;
        $raw = substr $raw, $c->offsetof( 'frame_t', 'data' ), $c->sizeof('frame_t.data');
        my $vc = $frame_hdr->{channel_id}{vcid};

        #Frame does not finish packet, append and go to next frame
        if ( $fhp == 0b11111111111 ) {
            $packet_vcid[$vc] .= $raw;
            next FRAME_DECODE;
        }

        #There is a packet beginning in this frame, finalize current
        if ( length( $packet_vcid[$vc] ) ) {
            $packet_vcid[$vc] .= substr $raw, 0, $fhp;
            my $pkt_len = parse_packet( $c, $packet_vcid[$vc], $full_packet, \$res_pktdec, $struct_pktdec );
            if ( $res_pktdec == YA_PACKET_COMP ) {
                $_->( $struct_pktdec, substr( $packet_vcid[$vc], 0, $pkt_len ), $rec_hdr ) for @{ $config->{coderefs_packet} };
            }
        }

        #Begin decoding following packets **pointed to by FHP**
        $raw = substr $raw, $fhp;

        do {
            my $pkt_len = parse_packet( $c, $raw, $full_packet, \$res_pktdec, $struct_pktdec );
            if ( $res_pktdec == YA_PACKET_COMP ) {
                $_->( $struct_pktdec, substr( $raw, 0, $pkt_len ), $rec_hdr ) for @{ $config->{coderefs_packet} };
                substr( $raw, 0, $pkt_len, '' );
            }
        } while ( $res_pktdec == YA_PACKET_COMP );

        #Not complete header or packet, push for following frames
        $packet_vcid[$vc] = $raw;
    }

    close $fin;
    return $frame_nr;
}

=head1 SYNOPSIS

This module allows to read a binary file containing blocks of cadu or frames.
Frames are decoded and so are included packets. 

The module expects a filename and a configuration describing:
    - Code references for frames: After each decoded frame, a list of subs can be called
    - Code references for packets: After each decoded packet, a list of subs can be called
    - Description as a C include file of the protocol

=head1 EXPORTS

=head2 frames_loop(config, filename)

 Given a file name of X blocks containing frames, return number of frames read from the file or -1 on incomplete read.
 After each decoded frame and packet,  call a list of plugin passed in $config.

=head1 AUTHOR

Laurent KISLAIRE, C<< <teebeenator at gmail.com> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Yacd::File::FrameLog


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Laurent KISLAIRE.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Yacd::File::FrameLog
