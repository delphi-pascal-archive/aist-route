unit F_MiscUtils;

interface

uses
  Windows, Messages, CommCtrl, WinSock, F_Windows, F_IpHlpApi, F_SysUtils,
  F_Controls, F_ListBoxEx, F_Resources;

function GetListStringFromSourceW(pszText: WideString): WideString;

function IsNormParseStringW(pszText: WideString): Boolean;
function IsCheckRouteReadStringW(pszText: WideString): Boolean;
function IsMaskRouteReadStringW(pszText: WideString): Boolean;

function GetRouteNameFromStringW(pszText: WideString): WideString;
function GetRouteAddressFromStringW(pszText: WideString): WideString;
function GetRouteMaskFromStringW(pszText: WideString): WideString;

function IsValidIPAddressW(pszText: WideString): Boolean;

function GetBatFileContentFromList(hWnd: HWND): WideString;

procedure OnWmCommand_AddEdtDlgEnChange(hWnd: HWND);

function CreateForwardEntry(pszDest, pszMask, pszHop: WideString): DWORD;

implementation

//

function GetListStringFromSourceW(pszText: WideString): WideString;
var
  ps: Integer;
  s1: WideString;
  s2: WideString;
  ls: Integer;
begin

  Result := '';

  if (Pos('0/', pszText) = 1) or (Pos('1/', pszText) = 1) then
  begin

    Delete(pszText, 1, 2);
    ps := Pos('/', pszText);
    if (ps > 0) then
    begin

      ls := Length(pszText);
      s1 := Copy(pszText, ps + 1, ls - ps);
      s2 := Copy(pszText, 1, ls - Length(s1) - 1);

      Result := FormatW('%s (%s)', [s2, TrimW(s1)]);

    end;

  end;

end;

//

function IsNormParseStringW(pszText: WideString): Boolean;
begin

  Result := (Pos('0/', pszText) = 1) or (Pos('1/', pszText) = 1);

end;

//

function IsCheckRouteReadStringW(pszText: WideString): Boolean;
begin

  Result := Pos('1/', pszText) = 1;

end;

//

function IsMaskRouteReadStringW(pszText: WideString): Boolean;
begin

  Result := Pos('mask', pszText) > 0;

end;

//

function GetRouteNameFromStringW(pszText: WideString): WideString;
var 
  p: Integer;
begin 

  p := Pos('(', pszText);
  if (p > 0) then
    Result := Copy(pszText, p + 1, Length(pszText) - p - 1)
  else 
    Result := '';

end; 
  
//

function GetRouteAddressFromStringW(pszText: WideString): WideString;
var 
  p: Integer;
begin 

  p := Pos('mask', pszText);
  if (p = 0) then
    p := Pos('(', pszText);

  Result := Copy(pszText, 1, p - 2);

end; 

//

function GetRouteMaskFromStringW(pszText: WideString): WideString;
var 
  p1: Integer;
  p2: Integer;
begin 

  p1 := Pos('mask', pszText);
  if (p1 > 0) then
    p1 := p1 + 4;
  p2 := Pos('(', pszText);

  Result := Copy(pszText, p1 + 1, p2 - p1 - 2);

end;

//

function IsValidIPAddressW(pszText: WideString): Boolean;
var
  i  : Integer;
  dot: Integer;
  len: Integer;
begin

  Result := FALSE;

  len := Length(pszText);
  if (len = 0) or (pszText = '0.0.0.0') then
    Exit;

  dot := 0;
  for i := 1 to len do
  begin
    if (pszText[i] = '.') then
      dot := dot + 1;
    if not (AnsiChar(pszText[i]) in ['0'..'9', '.']) then
      dot := 255;
  end;

  Result := dot = 3;

end;

//

function GetBatFileContentFromList(hWnd: HWND): WideString;
const
  fmtGateway : WideString = 'Gateway';
  fmtLocalIp : WideString = 'LocalIp';
  fmtCreate  : WideString = 'rem This file created by AIST ROUTE %s';
  fmtAddress : WideString = 'set %s=%s';
  fmtMaskY   : WideString = 'route -p add %s mask %s %%%s%%' + sLineBreak + 'rem %s';
  fmtMaskN   : WideString = 'route -p add %s %%%s%%' + sLineBreak + 'rem %s';
  fmtIPTV    : WideString = 'route -p add 232.0.0.0 mask 255.255.252.0 %%%s%%' + sLineBreak + 'rem IPTV';
  fmtSAP     : WideString = 'route -p add 224.2.127.254 mask 255.255.255.255 %%%s%%' + sLineBreak + 'rem SAP';
  fmtPrint   : WideString = 'route print';
var
  iItem  : Integer;
  dwRet  : DWORD;
  pszText: WideString;
  iCount : Integer;
begin

  // добавляем версию программы.

  Result := FormatW(fmtCreate, [ExeInfo.pszFileVersion]) + sLineBreak;

  // добавляем адрес шлюза.

  iItem := SendMessageW(GetDlgItem(hWnd, IDC_MAIN_IPADDR_ROUTES), CB_GETCURSEL,
    0, 0);
  pszText := ComboBox_GetItemW(GetDlgItem(hWnd, IDC_MAIN_IPADDR_ROUTES), iItem);
  Result := Result + FormatW(fmtAddress, [fmtGateway, pszText]) + sLineBreak;

  // добавляем текст с выбранными маршрутами.

  iCount := SendMessageW(GetDlgItem(hWnd, IDC_MAIN_ROUTE_LIST), LB_GETCOUNT, 0,
    0);
  if (iCount > 0) then
  begin
    for iItem := 0 to iCount -1 do
    begin
      dwRet := SendMessageW(GetDlgItem(hWnd, IDC_MAIN_ROUTE_LIST),
        LB_EX_GETITEMSTATE, iItem, 0);
      if (dwRet = LST_CHECKED) then
      begin
        pszText := ListBox_GetItemW(GetDlgItem(hWnd, IDC_MAIN_ROUTE_LIST), iItem);
        if IsMaskRouteReadStringW(pszText) then
          Result := Result + FormatW(
            fmtMaskY,
            [GetRouteAddressFromStringW(pszText),
            GetRouteMaskFromStringW(pszText),
            fmtGateway,
            GetRouteNameFromStringW(pszText)]
          ) + sLineBreak
        else
          Result := Result + FormatW(
            fmtMaskN,
            [GetRouteAddressFromStringW(pszText),
            fmtGateway,
            GetRouteNameFromStringW(pszText)]
          ) + sLineBreak;
      end;
    end;
  end;

  // добавляем маршруты для IP-TV.

  dwRet := SendMessageW(GetDlgItem(hWnd, IDC_MAIN_AISTNET_ROUTE), BM_GETCHECK,
    0, 0);
  if (dwRet = BST_CHECKED) then
  begin
    iItem := SendMessageW(GetDlgItem(hWnd, IDC_MAIN_IPADDR_NETMASK), CB_GETCURSEL,
      0, 0);
    pszText := ComboBox_GetItemW(GetDlgItem(hWnd, IDC_MAIN_IPADDR_NETMASK), iItem);
    Result := Result + FormatW(fmtAddress, [fmtLocalIp, pszText]) + sLineBreak;
    Result := Result + FormatW(fmtIPTV, [fmtLocalIp]) + sLineBreak;
    Result := Result + FormatW(fmtSAP, [fmtLocalIp]) + sLineBreak;
  end;

  //

  Result := Result + fmtPrint + sLineBreak;

end;

//

procedure OnWmCommand_AddEdtDlgEnChange(hWnd: HWND);
var
  uState1: Boolean;
  uState2: Boolean;
  s1     : WideString;
  s2     : WideString;
  s3     : WideString;
  dwRet  : DWORD;
begin

  // первоначально проверяем текст в элементах управления для обоих случаев,
  // хотя также для первого флага управления необходимо все проверить.

  uState1 := SysIPAddress32_IsBlankW(GetDlgItem(hWnd, IDC_EDIT_SYSIP_ADDRESS));

  s1 := SysIPAddress32_GetTextW(GetDlgItem(hWnd, IDC_EDIT_SYSIP_ADDRESS));
  s3 := Edit_GetTextW(GetDlgItem(hWnd, IDC_EDIT_ROUTE_NAME));

  dwRet := SendMessageW(GetDlgItem(hWnd, IDC_EDIT_WITHOUT_MASK), BM_GETCHECK, 0,
    0);
  if (dwRet = BST_CHECKED) then

    SetEnableWindowW(
      GetDlgItem(hWnd, ID_OK),
      (not uState1) and IsValidIPAddressW(s1) and (lstrlenW(LPWSTR(TrimW(s3))) <> 0)
    )

  else
  begin

    // если выбран второй флаг в диалоге, тут уже проверяем текст заодно и у
    // оставшихся элементов управления.

    uState2 := SysIPAddress32_IsBlankW(GetDlgItem(hWnd, IDC_EDIT_SYSIP_NETMASK));
    s2 := SysIPAddress32_GetTextW(GetDlgItem(hWnd, IDC_EDIT_SYSIP_NETMASK));

    SetEnableWindowW(
      GetDlgItem(hWnd, ID_OK),
      (not uState1) and (not uState2) and IsValidIPAddressW(s1) and
        IsValidIPAddressW(s2) and (lstrlenW(LPWSTR(TrimW(s3))) <> 0)
    );

  end;

end;

//

function CreateForwardEntry(pszDest, pszMask, pszHop: WideString): DWORD;
const
  fmtLine: WideString = 'route ADD %s MASK %s %s -P';
  fmtSkey: WideString = '%s,%s,%s,1';
  fmtHkey: WideString = 'SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\PersistentRoutes';
var
  pszText : WideString;
  si      : TStartupInfoW;
  pi      : TProcessInformation;
  dwError : DWORD;
  //
  pRoute  : MIB_IPFORWARDROW;
  dwIndex : DWORD;
  dwMetric: DWORD;
  //
  regKey  : HKEY;
  cbData  : DWORD;
  Dispos  : DWORD;
  //
  dwDest  : IPAddr;
  dwMask  : IPAddr;
  dwHop   : IPAddr;
begin

  Result := ERROR_INVALID_FUNCTION;

  // в системах Windows Vista и Windows 7 теперь необходимо добавлять двоичные
  // данные в ключ (не сохраняется постоянный маршрут):
  // HKLM\SYSTEM\CurrentControlSet\Control\Nsi\{GUID}\16\<binary value>
  // http://support.microsoft.com/kb/2011762
  // временное решение - запускаем системное приложение route.exe и проверяем
  // код выхода процесса.

  if (osvi.dwMajorVersion >= 6) then
  begin

    pszText := FormatW(fmtLine, [pszDest, pszMask, pszHop]);

    ZeroMemory(@si, SizeOf(TStartupInfoW));
    with si do
    begin
      cb          := SizeOf(TStartupInfoW);
      dwFlags     := STARTF_USESHOWWINDOW;
      wShowWindow := SW_HIDE;
    end;

    if CreateProcessW(nil, LPWSTR(pszText), nil, nil, FALSE, 0, nil, nil, si, pi) then
    begin

      WaitforSingleObject(pi.hProcess, INFINITE);
      GetExitCodeProcess(pi.hProcess, Result);
      CloseHandle(pi.hProcess);
      CloseHandle(pi.hThread);

    end;

  end
  else
  begin

    dwDest := inet_addr(LPTSTR(WideStringToAnsi(pszDest, CP_ACP)));
    dwMask := inet_addr(LPTSTR(WideStringToAnsi(pszMask, CP_ACP)));
    dwHop  := inet_addr(LPTSTR(WideStringToAnsi(pszHop, CP_ACP)));

    dwIndex := DWORD(-1);

    try

      dwError := GetBestInterface(dwDest, dwIndex);
      if (dwError = ERROR_SUCCESS) then
        begin

        if (dwIndex <> DWORD(-1)) then
        try

          dwError := GetBestRoute(dwDest, 0, pRoute);
          if (dwError = NO_ERROR) then
          try

            dwMetric := pRoute.dwForwardMetric1;

            ZeroMemory(@pRoute, SizeOf(MIB_IPFORWARDROW));

            with pRoute do
            begin
              dwForwardDest      := dwDest;
              dwForwardMask      := dwMask;
              dwForwardPolicy    := 0;
              dwForwardNextHop   := dwHop;
              dwForwardIfIndex   := dwIndex;
              dwForwardType      := MIB_IPROUTE_TYPE_DIRECT;
              dwForwardProto     := PROTO_IP_NETMGMT;
              dwForwardAge       := 0;
              dwForwardNextHopAS := 0;
              dwForwardMetric1   := dwMetric;
              dwForwardMetric2   := DWORD(-1);
              dwForwardMetric3   := DWORD(-1);
              dwForwardMetric4   := DWORD(-1);
              dwForwardMetric5   := DWORD(-1);
            end;

            dwError := CreateIpForwardEntry(@pRoute);
            if (dwError = NO_ERROR) then
            try

              cbData := {(lstrlenW(LPWSTR(pszText)) + 1) * SizeOf(WideChar)}2;

              pszText := FormatW(fmtSkey, [pszDest, pszMask, pszHop]);

              dwError := RegCreateKeyExW(HKEY_LOCAL_MACHINE, LPWSTR(fmtHkey), 0,
                nil, REG_OPTION_NON_VOLATILE, KEY_WRITE, nil, regKey, @Dispos);

              if (dwError = ERROR_SUCCESS) then
              try

                dwError := RegSetValueExW(regKey, LPWSTR(pszText), 0, REG_SZ,
                  LPWSTR(WideString('')), cbData);

                Result := dwError;

              finally
                RegCloseKey(regKey);
              end;

            finally
            end;

          except
          end;

        except
        end;

      end;

    except
    end;

  end;

end;

end.