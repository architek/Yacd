package Yacd::File::Frame;

use warnings;
use strict;

=head1 NAME

Yacd::File::Frame - Module to decode logfile of CCSDS TM Frame and included packets

=cut

use Data::Dumper;

sub read_record {
    my ( $fin, $config ) = @_;
    my $c          = $config->{c};
    my $len_record = $c->sizeof('record_t');
    my $raw;

    if ( read( $fin, $raw, $len_record ) != $len_record ) {
        warn "Incomplete record";
        return undef;
    }

    #If sync, check
    if ( $c->def('sync') ) {
        my $sync_offset = $c->offsetof( 'record_t', 'sync' );
        if ( substr( $raw, $sync_offset, 4 ) ne "\x1a\xcf\xfc\x1d" ) {
            warn "Record does not contain a SYNC, reading next record";
            return undef;
        }
    }
    return $raw;
}

sub read_frames {
    my ( $filename, $config ) = @_;

    my $skip;
    my $frame_nr    = 0;
    my @packet_vcid = ("") x 128;    # VC 0..127
    my $c            = $config->{c};
    my $idle_frames  = $config->{idle_frames};
    my $idle_packets = $config->{idle_packets};

    #Show warnings if user defined a warning subref
    $config->{output}->{W} = 1;

    #Remove buffering - This slows down a lot the process but helps to correlate errors to normal output
    $| = 1 if $config->{output}->{debug};

    open my $fin, "<", $filename or die "can not open $filename";
    binmode $fin;

    if ( exists $config->{skip} ) {
        $skip = $config->{skip};
        seek( $fin, $skip * $config->{record_len}, 0 );
    }

  FRAME_DECODE:
    while ( !eof $fin ) {

        my $raw;

        #Extract frame from record
        next FRAME_DECODE unless defined( $raw = read_record( $fin, $config ) );
        #Extract record header to pass to upper layer
        my $rec_head = substr $raw, 0, $c->sizeof('record_hdr_t');
        
        #Extract frame
        $raw = substr $raw, $c->offsetof( 'record_t', 'cadu.frame' ), $c->sizeof('frame_t');

        #Parse frame headers (parsing the complete frame might be time consuming and useless for OID frames)
        my $frame_hdr = $c->unpack( 'frame_hdr_t', $raw );
        my $frame_data_field_hdr = $c->unpack( 'frame_data_field_hdr_t', substr($raw, $c->sizeof('frame_hdr_t')));
        my $fhp = $frame_data_field_hdr->{fhp};

        #if we reached the number of frames and we end up on a packet boundary, stop
        return $frame_nr if defined $config->{frame_nr} and $frame_nr >= $config->{frame_nr} and $fhp != 0b11111111111;

        #if we were requested to skip frames, skip until next packet boundary (or OID frame)
        if ( defined $skip ) {
            next FRAME_DECODE if $fhp == 0b11111111111;
            $skip = undef;
        }

        #Process frames
        $frame_nr++;

        #Skip OID frames
        next FRAME_DECODE if $fhp == 0b11111111110 and !$idle_frames;

        #Execute coderefs
        $_->( $c->unpack('frame_t', $raw), $raw, $rec_head ) for @{ $config->{coderefs_frame} };
        next FRAME_DECODE if $fhp == 0b11111111110;

        #Extract frame data
        $raw = substr $raw, $c->offsetof('frame_t','data'), $c->sizeof('frame_t.data');

        #Start Packet assembly on frame data
        my $vc = $frame_hdr->{channel_id}{vcid};

        #Frame does not finish packet, append and go to next frame
        if ( $fhp == 0b11111111111 ) {
            $packet_vcid[$vc] .= $raw;
            next FRAME_DECODE;
        }

        #There is a packet beginning in this frame, finalize current
        if ( length( $packet_vcid[$vc] ) ) {
            $packet_vcid[$vc] .= substr $raw, 0, $fhp;
            if ( length( $packet_vcid[$vc] ) >= $c->sizeof('pkt_hdr_t') ) {
                my $pkt_hdr = $c->unpack( 'pkt_hdr_t', $packet_vcid[$vc] );
                my $pkt_len = $pkt_hdr->{pkt_df_length};

                if ( length( $packet_vcid[$vc] ) >= $pkt_len ) {
                    $_->( $c->unpack('pkt_t',$raw), $raw, $rec_head ) for @{ $config->{coderefs_packet} };
                }
            }
        }

        #Begin decoding following packets
        $raw = substr $raw, $fhp;
        $packet_vcid[$vc] = "";

        my $cont;
        do {
            $cont = 0;

            #Do we have a full packet header
            if ( length($raw) >= $c->sizeof('pkt_hdr_t') ) {
                my $pkt_hdr = $c->unpack( 'pkt_hdr_t', $raw );
                my $pkt_len = $pkt_hdr->{pkt_df_length};

                if ( length( $raw ) >= $pkt_len ) {
                    $_->( $c->unpack('pkt_t',$raw), $raw, $rec_head ) for @{ $config->{coderefs_packet} };
                    substr( $raw, 0, $pkt_len ) = '';
                    $cont = 1;
                }
            }

            #Not complete header or packet, push for following frames
        } while ($cont);
        $packet_vcid[$vc] = $raw;
    }

    close $fin;
    return $frame_nr;
}

require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(read_frames);

=head1 SYNOPSIS

This module allows to read a binary file containing blocks. Each block contains one TM Frame.
Frames are decoded and so are included packets. First Header Pointer is used to find packets, detect incoherency and resynchronise if needed.

The module expects a filename and a configuration describing:
    - Code references for frames: After each decoded frame, a list of subs can be called
    - Code references for packets: After each decoded packet, a list of subs can be called
    - Description as a C include file of the protocol

=head1 EXPORTS

=head2 read_frames()

 Given a file name of X blocks containing frames, return number of frames read from the file or -1 on incomplete read.
 After each decoded frame,  call a list of plugin passed in $config.
 After each decoded packet, call a list of plugin passed in $config.

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

1;    # End of Yacd::File::Frame