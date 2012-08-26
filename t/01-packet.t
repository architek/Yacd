use warnings;
use strict;
use Test::More;
use Data::Dumper;
use Yacd qw/$VERSION/;
use Yacd::Packet qw/parse_packet :ERROR_CODES/;
use Convert::Binary::C;

#This test generates a raw packet using Ccsds framework with customization Custo.pm
#It then decodes the raw packet using Yacd framework with customization custo.h (the same customization but following yacd syntax)
#A comparison is done on the result to verify it is equivalent

BEGIN {
    eval {
        use FindBin qw/$Bin/;
        require "$Bin/Custo.pm";
        require Ccsds::TM::SourcePacket;
    };
    if ($@) {
        plan skip_all => 'Test not done: Ccsds or Data::ParseBinary not present';
    }
    else {
        plan tests => 2;
    }
}

#Change these to test several values
my $u_seq  = 12311 % 16384;
my $u_len  = 18;
my $u_segf = 3;
my $u_pid  = 4;
my $u_pcat = 6;
my $u_pec  = 6375;
my ( $f1, $f2, $f3 ) = ( 18, 189, 123 );
my ( $c1, $c2, $c3, $c4 ) = ( 1, 2, 83, 93 );
my $apattern = [ ('a' .. 'z') x 1000 ] ;       #up to 26_000
#####################################

diag "seq=$u_seq, len=$u_len, segf=$u_segf, pid=$u_pid, pcat=$u_pcat, pec=$u_pec, Fine=[$f1,$f2,$f3], Coarse=[$c1,$c2,$c3,$c4]";

my $spattern = join( '', @$apattern );
my $def_pkt = {
    'Packet Header' => {
        'Length'                  => 6,
        'Packet Sequence Control' => {
            'Source Seq Count'   => $u_seq,
            'Packet Length'      => $u_len,
            'Segmentation Flags' => $u_segf,
        },
        'Packet Id' => {
            'vApid'          => $u_pid << 4 + $u_pcat,
            'DFH Flag'       => 1,
            'Type'           => 0,
            'Version Number' => 0,
            'Apid'           => {
                'PID'  => $u_pid,
                'Pcat' => $u_pcat,
            }
        }
    },
    'Packet Data Field' => {
        'Packet Error Control'    => $u_pec,
        'TMSourceSecondaryHeader' => {
            'Length'   => 12,
            'Sat_Time' => {
                'CUC Fine'   => [ $f1, $f2, $f3 ],
                'CUC Coarse' => [ $c1, $c2, $c3, $c4 ],
                'OBT' => '21341.0732037425'
            },
            'Time Quality'      => 0,
            'Destination Id'    => 0,
            'Service Subtype'   => 3,
            'Service Type'      => 5,
            'SecHeadFirstField' => {
                'Spare1'             => 0,
                'Spare2'             => 0,
                'PUS Version Number' => 1
            }
        },
        'Source Data' => substr( $spattern, 0, $u_len - 13 ),
    },
    'Has Crc' => 1
};

my $def_pkt_cbc = {
    'pkt' => {
        'pkt_hdr' => {
            'version'       => 0,
            'pkt_df_length' => $u_len,
            'seqn'          => $u_seq,
            'segf'          => $u_segf,
            'pid'           => $u_pid,
            'pcat'          => $u_pcat,
            'type'          => 0,
            'sechdr'        => 1
        },
        'pkt_df' => {
            'data'               => [ 
                    map( ord, @$apattern[ 0 .. $u_len - 13 -1 ] ), 
                    $u_pec >> 8, 
                    $u_pec & 0xFF 
                                    ],
            'pkt_data_field_hdr' => {
                'time_status' => 0,
                'dest'        => 0,
                'ssvc'        => 3,
                'sc_coarse'   => $c4 + 256 * ( $c3 + 256 * ( $c2 + 256 * $c1 ) ),
                'spare_2'     => 0,
                'pus_version' => 1,
                'svc'         => 5,
                'spare_1'     => 0,
                'sc_fine'     => [ $f1, $f2, $f3, ]
            }
        }
    }
};

my $raw = $Ccsds::TM::SourcePacket::TMSourcePacket->build($def_pkt);

my $c = eval {
    Convert::Binary::C->new(
        ByteOrder         => 'BigEndian',
        IntSize           => 4,
        ShortSize         => 2,
        Alignment         => 1,
        CompoundAlignment => 1,
        UnsignedChars     => 1,
        UnsignedBitfields => 1,
    )->parse_file("$Bin/custo.h");
};

if ($@) {
    die "The structure definition was not parsed properly:\n$@";
}

my ( $res, %res_struct );
my $cbc_pkt = parse_packet( $c, $raw, 1, \$res, \%res_struct );
ok( $res == YA_PACKET_COMP, "Decoding of packet generated by Ccsds returned $res" );
is_deeply( \%res_struct, $def_pkt_cbc , "Deep verification of result");

done_testing($2);
diag("Testing Yacd Decoding $Yacd::VERSION, Perl $], $^X");
