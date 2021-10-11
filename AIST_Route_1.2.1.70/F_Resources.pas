unit F_Resources;

interface

uses
  Windows, Messages, CommCtrl, F_FileInfo, F_Windows;

const

  { id dialog resources }

  RC_DIALOG_MAIN          = 101;
  RC_DIALOG_EDIT_ENTRY    = 102;
  RC_DIALOG_UPDATE_ROUTES = 103;
  RC_DIALOG_EVENT         = 104;
  RC_DIALOG_OFN_TEMPLATE  = 105;
  RC_DIALOG_ABOUT         = 106;

  { id bitmap resources }

  RC_BITMAP_ENABLE_BUTTONS  = 101;
  RC_BITMAP_DISABLE_BUTTONS = 102;
  RC_BITMAP_AUTO_CREATE     = 103;
  RC_BITMAP_STATUS_INFO     = 104;
  RC_BITMAP_SPRITES         = 105;

  { id icon resources }

  RC_ICON_MAIN = 101;

  { id menu resources }

  RC_MENU_LIST = 101;

  { id accelarator resources }

  RC_ACCEL_MAIN = 101;

  { id dialog controls #101 }

  IDC_MAIN_IPADDR_ROUTES   = 10101;
  IDC_MAIN_IPADDR_NETMASK  = 10102;
  IDC_MAIN_UPDATE_ADAPTERS = 10103;
  IDC_MAIN_AISTNET_ROUTE   = 10104;
  IDC_MAIN_AUTO_CREATE     = 10105;
  IDC_MAIN_WINDOW_MODE     = 10106;
  IDC_MAIN_UPDATE_ROUTES   = 10107;
  IDC_MAIN_TOOLBAR_EDIT    = 10108;
  IDC_MAIN_SERVER_LIST     = 10109;
  IDC_MAIN_ROUTE_LIST      = 10110;
  IDC_MAIN_SELECT_ALL      = 10111;
  IDC_MAIN_UNSELECT_ALL    = 10112;
  IDC_MAIN_STATUSBAR_INFO  = 10113;

  IDT_MAIN_CREATE_ROUTE    = 10121;
  IDT_MAIN_EDIT_ROUTE      = 10122;
  IDT_MAIN_DELETE_ROUTE    = 10123;
  IDT_MAIN_CLEAR_LIST      = 10124;
  IDT_MAIN_CLIPBOARD       = 10125;
  IDT_MAIN_FILE_SAVE       = 10126;

  IDM_MAIN_CREATE_ROUTE    = 10131;
  IDM_MAIN_EDIT_ROUTE      = 10132;
  IDM_MAIN_DELETE_ROUTE    = 10133;
  IDM_MAIN_CLEAR_LIST      = 10134;
  IDM_MAIN_ABOUT           = 10135;

  IDH_MAIN_CREATE_ROUTE    = IDM_MAIN_CREATE_ROUTE;
  IDH_MAIN_EDIT_ROUTE      = IDM_MAIN_EDIT_ROUTE;
  IDH_MAIN_DELETE_ROUTE    = IDM_MAIN_DELETE_ROUTE;
  IDH_MAIN_CLEAR_LIST      = IDM_MAIN_CLEAR_LIST;

  { id dialog controls #102 }

  IDC_EDIT_WITHOUT_MASK  = 10201;
  IDC_EDIT_WITH_MASK     = 10202;
  IDC_EDIT_SYSIP_ADDRESS = 10203;
  IDC_EDIT_TEXT_NETMASK  = 10204;
  IDC_EDIT_SYSIP_NETMASK = 10205;
  IDC_EDIT_ROUTE_NAME    = 10206;

  { id dialog controls #103 }

  IDC_DOWN_SPRITES = 10301;
  IDC_DOWN_LOADING = 10302;

  { id dialog controls #104 }

  IDC_LOGW_EVENT_LOG      = 10401;
  IDC_LOGW_STATUSBAR_INFO = 10402;
  IDC_LOGW_SPRITES        = 10403;
  IDC_LOGW_PROGRESS       = 10404;

  { id dialog controls #105 }

  IDC_SAVE_RUN_BAT = 10501;

  { id dialog controls #106 }

  IDC_INFO_LOGO       = 10601;
  IDC_INFO_VERSION    = 10602;
  IDC_INFO_COPYRIGHTS = 10603;
  IDC_INFO_URL        = 10604;
  IDC_INFO_MAIL       = 10605;

  { start id dynamic variables }

  IDM_SERVERS_START = 5000;

  { id stringtable resources }

  ID_APP_VERSION     = 1600;
  ID_SIMPLE_MODE     = 1601;
  ID_EXTENDED_MODE   = 1602;
  ID_INSERT_ROUTE    = 1603;
  ID_EDIT_ROUTE      = 1604;
  ID_DELETE_ROUTE    = 1605;
  ID_CLEAR_LIST      = 1606;
  ID_COPY_CLIPBOARD  = 1607;
  ID_FILE_SAVE       = 1608;
  ID_NOTIFY_CLEAR    = 1609;
  ID_ABOUT_MENU      = 1610;
  ID_ROUTES_COUNT    = 1611;
  ID_SELECTED_ROUTES = 1612;
  ID_REQUIRES_NT     = 1614;
  ID_ADMIN_RIGHTS    = 1615;
  ID_NAME_CUEBANNER  = 1617;

  ID_SERVER_CONNECT = 1632;
  ID_ADD_ROUTES     = 1633;
  ID_SUCCES_LOAD    = 1634;
  ID_ERROR_LOAD     = 1635;

  ID_ROUTE_EVENT    = 1648;
  ID_ROUTE_PROGRESS = 1649;
  ID_ROUTE_READY    = 1650;
  ID_ROUTE_SUCCES   = 1651;
  ID_ROUTE_ERROR    = 1652;

  ID_FILTER_INDEX = 1664;
  ID_ERROR_CODE   = 1665;

  //

  fmtForum   : WideString = 'http://tltorrent.ru/viewtopic.php?t=97776';
  fmtEmail   : WideString = 'mailto:maks1509@inbox.ru';
  fmtFontName: WideString = 'Tahoma';

var

  ExeInfo   : TStringFileInfoW;

  tbBtnsEdit: Array [1..9] of TTBButton = (
    (iBitmap: 0; idCommand: IDT_MAIN_CREATE_ROUTE; fsState: TBSTATE_ENABLED;
      fsStyle: BTNS_BUTTON),
    (iBitmap: 1; idCommand: IDT_MAIN_EDIT_ROUTE; fsState: TBSTATE_ENABLED;
      fsStyle: BTNS_BUTTON),
    (iBitmap: 2; idCommand: IDT_MAIN_DELETE_ROUTE; fsState: TBSTATE_ENABLED;
      fsStyle: BTNS_BUTTON),
    (iBitmap: -1; idCommand: -1; fsState: TBSTATE_ENABLED; fsStyle: BTNS_SEP),
    (iBitmap: 3; idCommand: IDT_MAIN_CLEAR_LIST; fsState: TBSTATE_ENABLED;
      fsStyle: BTNS_BUTTON),
    (iBitmap: -1; idCommand: -1; fsState: TBSTATE_ENABLED; fsStyle: BTNS_SEP),
    (iBitmap: 4; idCommand: IDT_MAIN_CLIPBOARD; fsState: TBSTATE_ENABLED;
      fsStyle: BTNS_BUTTON),
    (iBitmap: -1; idCommand: -1; fsState: TBSTATE_ENABLED; fsStyle: BTNS_SEP),
    (iBitmap: 5; idCommand: IDT_MAIN_FILE_SAVE; fsState: TBSTATE_ENABLED;
      fsStyle: BTNS_BUTTON)
  );

  hThread   : DWORD = 0;

  pszRoutes : Array [0..5] of LPWSTR = (
    '172.16.0.0 mask 255.240.0.0 (ADSL)',
    '10.0.0.0 mask 255.0.0.0 (AIST.NET)',
    '192.168.0.0 mask 255.255.0.0 (VPN)',
    '81.28.160.111 (irc.avtograd.ru)',
    '85.114.164.196 (aist2.mytlt.ru)',
    '81.28.160.241 (radio.avtograd.ru)'
  );

  pszServers: Array [0..2, 0..1] of LPWSTR = (
    ('http://aisty.net.ru/AIST_ROUTE/routes.conf',
      'http://aisty.net.ru'),
    ('http://crysis-wars-tlt.org.ru/files/routes.conf',
      'http://crysis-wars-tlt.org.ru'),
    ('http://webdrive.avtograd.ru/Download/Explorer/updates/routes.conf',
      'http://webdrive.avtograd.ru')
  );

  SetExecute: Boolean = FALSE;
  SetUpdate : Integer = 1;

  mmiX      : Integer = 0;
  mmiY      : Integer = 0;

  osvi      : TOSVersionInfoW;

implementation

end.