//Sample Ccsds customization for a fictitious mission
//The mandatory typedef MUST be there
//Content of typedef can be changed but mandatory members MUST be there

// this typedef is mandatory and needs to include at least the member pkt_df_length
typedef struct {
      int version:3;
      int type:1;
      int sechdr:1;
      int spare:2;
      int vcm:1;
      int rsvd:1;
      int xr:3;
      int bb:6;
      int seqn:14;
      unsigned short pkt_df_length;
} pkt_hdr_t;

// this typedef is not mandatory if your packets do not have a secondary header
typedef struct {
      int sc_coarse;
      char sc_fine[3];
      int tcv:12;
      int msi:12;
      unsigned short cs;
} pkt_data_field_hdr_t;

// this typedef is mandatory and needs to include at least the member data
typedef struct {
      pkt_hdr_t pkt_hdr;
      pkt_data_field_hdr_t pkt_data_field_hdr;
      char data[];
      unsigned short crc;
} pkt_t;

// this typedef is mandatory and needs to include at least the member vcid
typedef struct {
     int version:2;
     int scid:8;
     int vcid:6;
} channel_id_t;

// this typedef is mandatory and needs to include at least the member channel_d
typedef struct {
      channel_id_t channel_id;
      char vcfc[3];
      struct {
          int rp:1;
          int rsvd:7;
      } signalling_field;
      unsigned short fhec;
} frame_hdr_t;

// this typedef is mandatory and needs to include at least the member fhp
typedef struct {
      int spare:5;
      int fhp:11;
} frame_data_field_hdr_t;

// this typedef is mandatory and needs to include at least the member data
typedef struct {
	frame_hdr_t frame_hdr;
	frame_data_field_hdr_t frame_data_field_hdr;
	char data[1215];
} frame_t;

// this typedef is mandatory and needs to include at least the member frame
// if the sync is present in your log then it will be checked against 0x1ACFFC1D
typedef struct {
	int sync;
	frame_t frame;
	char rs[160];
} cadu_t;

// this typedef is not mandatory if your records ARE cadus
typedef struct {
	double bench_time;
	double sim_time;
	unsigned long channel;
	unsigned long rsvd;
	unsigned long rsvd2;
	unsigned long rsvd3;
} record_hdr_t;

// this typedef is mandatory and needs to include at least the member cadu
typedef struct {
	record_hdr_t record_hdr;
	cadu_t cadu;
} record_t;

