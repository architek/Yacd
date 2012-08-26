package Yacd::Packet;

use warnings;
use strict;

=head1 NAME

Yacd::Packet - Module to decode a packet..

=cut

# BEGIN block is necessary here so that other modules can use the constants.
use vars qw( @EXPORT_OK %EXPORT_TAGS );
BEGIN {
    use Exporter qw( import );
    @EXPORT_OK   = qw/parse_packet/;
    %EXPORT_TAGS = (
        ERROR_CODES => [ qw(
            YA_PACKET_NONE
            YA_PACKET_HEAD
            YA_PACKET_COMP
            ) ],
    );

    # Add all the constant names and error code names to @EXPORT_OK
    Exporter::export_ok_tags( qw( ERROR_CODES ) );
}

use constant YA_PACKET_NONE => 0;
use constant YA_PACKET_HEAD => 1;
use constant YA_PACKET_COMP => 2;

sub parse_packet {
    my ( $c, $raw, $full_packet, $res, $r_struct ) = @_;
    my $pkt_len;

    if ( length($raw) >= $c->sizeof('pkt_hdr_t') ) {
        my $pkt_hdr = $c->unpack( 'pkt_hdr_t', $raw );
        $pkt_len = $pkt_hdr->{pkt_df_length} + $c->sizeof('pkt_hdr_t') + 1;
        if ( length($raw) >= $pkt_len ) {
            if ( $full_packet ) {
                $c->tag('pkt_df_t.data', Dimension => $pkt_len - $c->offsetof('pkt_t','pkt_df.data') );
                $r_struct->{pkt} = $c->unpack( 'pkt_t', $raw );
            }
            else {
                $r_struct->{pkt_hdr} = $pkt_hdr;
                $r_struct->{pkt_data_field_hdr} = $c->unpack( 'pkt_data_field_hdr_t', substr( $raw, $c->sizeof('pkt_hdr_t') ) );
            }
            $$res = YA_PACKET_COMP;
        }
        else {
            $$res = YA_PACKET_HEAD;
        }
    }
    else {
        $$res = YA_PACKET_NONE;
    }
    return $pkt_len;
}

=head1 SYNOPSIS

This module allows to decode a packet.

=head1 EXPORTS

=head2 parse_packet ( c, raw, fullpacket, result status reference, result struct reference ) 

 Try to decode as much of this packet. 
 This sub returns packet length as detected or 0.
 It also returns a value in res:
 * 0 not even a header was decoded
 * 1 a packet header was decoded and packet length returned
 * 2 a complete packet was decoded 
 In case a complete packet was decoded, the resulting structures are in struct (fullpacket option will decode the full packet and not only the headers)

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

1;    # End of Yacd::Packet
