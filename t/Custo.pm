package Ccsds::Custo;
use Data::ParseBinary;

our $has_crc=Value('Has Crc',
    sub {
      ( $_->ctx->{'Packet Header'}->{'Packet Id'}->{'vApid'} != 2047 &&
        $_->ctx->{'Packet Header'}->{'Packet Id'}->{'vApid'} != 29
      ) ? 1 : 0 ;
    }
);

1;
