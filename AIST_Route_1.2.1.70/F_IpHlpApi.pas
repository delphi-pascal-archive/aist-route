unit F_IpHlpApi;

interface

uses
  Windows;

const

  PROTO_IP_NETMGMT = 3;

  MIB_IPROUTE_TYPE_DIRECT = 3;

  MAX_ADAPTER_DESCRIPTION_LENGTH = 128;
  MAX_ADAPTER_NAME_LENGTH        = 256;
  MAX_ADAPTER_ADDRESS_LENGTH     = 8;

type

  IPAddr = Cardinal;

  time_t = int64;

  PMIB_IPFORWARDROW = ^MIB_IPFORWARDROW;
  MIB_IPFORWARDROW = packed record
    dwForwardDest     : DWORD; { IP addr of destination }
    dwForwardMask     : DWORD; { subnetwork mask of destination }
    dwForwardPolicy   : DWORD; { conditions for multi-path route }
    dwForwardNextHop  : DWORD; { IP address of next hop }
    dwForwardIfIndex  : DWORD; { index of interface }
    dwForwardType     : DWORD; { route type }
    dwForwardProto    : DWORD; { protocol that generated route }
    dwForwardAge      : DWORD; { age of route }
    dwForwardNextHopAS: DWORD; { autonomous system number of next hop }
    dwForwardMetric1  : DWORD; { protocol-specific metric }
    dwForwardMetric2  : DWORD; { protocol-specific metric }
    dwForwardMetric3  : DWORD; { protocol-specific metric }
    dwForwardMetric4  : DWORD; { protocol-specific metric }
    dwForwardMetric5  : DWORD; { protocol-specific metric }
  end;

  PIP_ADDRESS_STRING = ^IP_ADDRESS_STRING;
  IP_ADDRESS_STRING = packed record
    acString: Array [1..16] of AnsiChar;
  end;

  PIP_MASK_STRING = ^PIP_MASK_STRING;
  IP_MASK_STRING = IP_ADDRESS_STRING;
  PIP_ADDR_STRING = ^IP_ADDR_STRING;
  IP_ADDR_STRING = packed record
    Next     : PIP_ADDR_STRING;
    IpAddress: IP_ADDRESS_STRING;
    IpMask   : IP_MASK_STRING;
    Context  : DWORD;
  end;

  PIP_ADAPTER_INFO = ^IP_ADAPTER_INFO;
  IP_ADAPTER_INFO = packed record
    Next               : PIP_ADAPTER_INFO;
    ComboIndex         : DWORD;
    AdapterName        : Array [1..MAX_ADAPTER_NAME_LENGTH + 4] of AnsiChar;
    Description        : Array [1..MAX_ADAPTER_DESCRIPTION_LENGTH + 4] of AnsiChar;
    AddressLength      : UINT;
    Address            : Array [1..MAX_ADAPTER_ADDRESS_LENGTH] of Byte;
    Index              : DWORD;
    dwType             : UINT;
    DhcpEnabled        : UINT;
    CurrentIpAddress   : PIP_ADDR_STRING;
    IpAddressList      : IP_ADDR_STRING;
    GatewayList        : IP_ADDR_STRING;
    DhcpServer         : IP_ADDR_STRING;
    HaveWins           : Boolean;
    PrimaryWinsServer  : IP_ADDR_STRING;
    SecondaryWinsServer: IP_ADDR_STRING;
    LeaseObtained      : time_t;
    LeaseExpires       : time_t;
  end;

function GetAdaptersInfo(pAdapterInfo: PIP_ADAPTER_INFO; pOutBufLen: PULONG): DWORD; stdcall;
function GetBestInterface(dwDestAddr: IPAddr; var pdwBestIfIndex: DWORD): DWORD; stdcall;
function CreateIpForwardEntry(pRoute: PMIB_IPFORWARDROW): DWORD; stdcall;
function GetBestRoute(dwDestAddr, dwSourceAddr: DWORD; var pBestRoute: MIB_IPFORWARDROW): DWORD; stdcall;

implementation

const
  iphlpapi = 'iphlpapi.dll';

function GetAdaptersInfo;      external iphlpapi name 'GetAdaptersInfo';
function GetBestInterface;     external iphlpapi name 'GetBestInterface';
function CreateIpForwardEntry; external iphlpapi name 'CreateIpForwardEntry';
function GetBestRoute;         external iphlpapi name 'GetBestRoute';

end.