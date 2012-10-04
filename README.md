[![Build Status](https://secure.travis-ci.org/architek/Yacd.png?branch=master)](http://travis-ci.org/architek/Yacd)

This library allows decoding of CCSDS frames and packets as defined in the PSS/ECSS standards.
As the underlying library (Convert::Binary::C) is written in C, performance is greatly improved compared to Ccsds framework.

On an Intel(R) Core(TM) i3 CPU M 350  @ 2.27GHz, decoding was observed at a speed of 60MB/s.

Easy Install (in Windows, simply do not put sudo)
	cpan Module::Install   <------ used by Makefile.PL
	perl Makefile.PL
	sudo make              <------ the sudo here is required as this will install all dependencies
	sudo make install

Example of use:

    use Yacd::File::FrameLog qw/frames_loop/;
    use Data::Dumper;
    use Convert::Binary::C;

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
        IntSize=>4, ShortSize=>2,
        Alignment=>1, CompoundAlignment=>1,
        ByteOrder=>'BigEndian',
        UnsignedChars=>1, UnsignedBitfields=>1,
        #OrderMembers=>1,   # requires Tie::Hash::Indexed (huge performance loss)
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
    };

    #Launch loop on logfile
    read_frames($ARGV[0],$config);

