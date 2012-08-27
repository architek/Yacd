typedef struct
{
  int version:3;
  int type:1;
  int sechdr:1;
  int pid:7;
  int pcat:4;
  int segf:2;
  int seqn:14;
  unsigned short pkt_df_length;
} pkt_hdr_t;

typedef struct
{
  int spare_1:1;
  int pus_version:3;
  int spare_2:4;
  char svc;
  char ssvc;
  char dest;
  int sc_coarse;
  char sc_fine[3];
  char time_status;
} pkt_data_field_hdr_t;

typedef struct
{
  pkt_data_field_hdr_t pkt_data_field_hdr;
  char data[];
//      unsigned short crc;
} pkt_df_t;

typedef struct
{
  pkt_hdr_t pkt_hdr;
  pkt_df_t pkt_df;
} pkt_t;

typedef struct
{
  int version:2;
  int scid:10;
  int vcid:3;
  int opcf:1;
} channel_id_t;

typedef struct
{
  channel_id_t channel_id;
  char mcfc;
  char vcfc;
} frame_hdr_t;

typedef struct
{
  int sh:1;
  int sf:1;
  int po:1;
  int sl:2;
  int fhp:11;
} frame_df_hdr_t;

typedef struct
{
  frame_hdr_t frame_hdr;
  frame_df_hdr_t frame_df_hdr;
  char data[1105];
  int clcw;
} frame_t;

typedef struct
{
  int sync;
  frame_t frame;
  char rs[160];
} cadu_t;

typedef struct
{
  cadu_t cadu;
} record_t;
