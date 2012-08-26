typedef struct
{
  struct pad1
  {
    int version:3;
    int type:1;
    int sechdr:1;
    int pid:7;
    int pcat:4;
    int segf:2;
    int seqn:14;
  };
  unsigned short pkt_df_length;
} pkt_hdr_t;

typedef struct
{
  struct pad2
  {
    int spare_1:1;
    int pus_version:3;
    int spare_2:4;
  };
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
  char data[1];
//      unsigned short crc;
} pkt_df_t;

typedef struct
{
  pkt_hdr_t pkt_hdr;
  pkt_df_t pkt_df;
} pkt_t;
