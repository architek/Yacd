This library allows decoding of CCSDS frames and packets as defined in the PSS/ECSS standards.

    use Yacd;
    use Data::Dumper;

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
    }

    #Launch loop on logfile
    read_frames($ARGV[0],$config);

