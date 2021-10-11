unit D_LogwProc;

interface

uses
  Windows, Messages, CommCtrl, WinSock, F_IpHlpApi, F_SysUtils, F_ListBoxEx,
  F_FramePaint, F_MyMsgBox, F_Resources, F_Controls, F_MiscUtils;

function LogwDlgProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): BOOL; stdcall;

implementation

//

function LogwDlgProc_WmInitDialog(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  ThreadID: LongWord;
  rect    : TRect;
  himl    : HIMAGELIST;
  dwStyle : DWORD;
  hChild  : THandle;

  function ThreadCallback(LpParameter: Pointer): DWORD; stdcall;
  const
    dwError: Array [Boolean] of DWORD = (ID_ROUTE_ERROR, ID_ROUTE_SUCCES);
    dwImage: Array [Boolean] of DWORD = (3, 2);
  var
    hWnd      : THandle;
    iItem     : Integer;
    iCount    : Integer;
    iCheck    : Integer;
    iCurrent  : Integer;
    pszRoute  : WideString;
    pszAddress: WideString;
    pszNetMask: WideString;
    pszGateway: WideString;
    pszText   : WideString;
    hmMenu    : HMENU;
    dwRet     : DWORD;
    hChild    : THandle;
    himl      : HIMAGELIST;
  begin

    //

    Result := 0;

    // извлекаем дескриптор родительского окна из переданного агрумента.

    hWnd := THandle(LpParameter);

    //

    SetThreadPriority(hThread, THREAD_PRIORITY_BELOW_NORMAL);

    //

    SetEnableWindowW(GetDlgItem(hWnd, ID_CANCEL), FALSE);
    hmMenu := GetSystemMenu(hWnd, FALSE);
    EnableMenuItem(hmMenu, SC_CLOSE, MF_BYCOMMAND or MF_GRAYED);

    //

    hChild := GetDlgItem(GetDlgItem(hWnd, IDC_LOGW_STATUSBAR_INFO),
      IDC_LOGW_SPRITES);
    if (hChild <> 0) then
      SendMessageW(hChild, STM_EX_ANIMATESTART, 0, 0);

    // узнаем IP адрес выбранного шлюза.

    iItem := SendMessageW(GetDlgItem(GetParent(hWnd), IDC_MAIN_IPADDR_ROUTES),
      CB_GETCURSEL, 0, 0);
    pszGateway := ComboBox_GetItemW(GetDlgItem(GetParent(hWnd),
      IDC_MAIN_IPADDR_ROUTES), iItem);

    // устанавливаем диапазон значений шкалы прогресса.

    iCheck := SendMessageW(GetDlgItem(GetParent(hWnd), IDC_MAIN_ROUTE_LIST),
      LB_EX_GETCHECKCOUNT, 0, 0);
    dwRet := SendMessageW(GetDlgItem(GetParent(hWnd), IDC_MAIN_AISTNET_ROUTE),
      BM_GETCHECK, 0, 0);
    if (dwRet = BST_CHECKED) then
      Inc(iCheck , 2);

    hChild := GetDlgItem(GetDlgItem(hWnd, IDC_LOGW_STATUSBAR_INFO),
      IDC_LOGW_PROGRESS);
    if (hChild <> 0) then
      SendMessageW(hChild, PBM_SETRANGE, 0, MakeLParam(0, iCheck));

    // добавляем выбранные маршруты.

    iCount := SendMessageW(GetDlgItem(GetParent(hWnd), IDC_MAIN_ROUTE_LIST),
      LB_GETCOUNT, 0, 0);

    iCurrent := 0;

    for iItem := 0 to iCount -1 do
    begin

      dwRet := SendMessageW(GetDlgItem(GetParent(hWnd), IDC_MAIN_ROUTE_LIST),
        LB_EX_GETITEMSTATE, iItem, 0);
      if (dwRet = BST_CHECKED) then
      begin

        pszText := ListBox_GetItemW(GetDlgItem(GetParent(hWnd),
          IDC_MAIN_ROUTE_LIST), iItem);

        pszRoute := GetRouteNameFromStringW(pszText);
        pszAddress := GetRouteAddressFromStringW(pszText);
        if IsMaskRouteReadStringW(pszText) then
          pszNetMask := GetRouteMaskFromStringW(pszText)
        else
          pszNetMask := '255.255.255.255';

        dwRet := CreateForwardEntry(pszAddress, pszNetMask, pszGateway);

        pszText := FormatW(
          LoadStrW(ID_ROUTE_EVENT),
          [pszRoute, pszAddress, pszNetMask, LoadStrW(dwError[dwRet = ERROR_SUCCESS])]
        );
        SendMessageW(GetDlgItem(hWnd, IDC_LOGW_EVENT_LOG), LB_ADDSTRING, 0,
          Integer(LPWSTR(pszText)));

        SendMessageW(GetDlgItem(hWnd, IDC_LOGW_EVENT_LOG), LB_EX_SETIMAGEINDEX,
          iCurrent, dwImage[dwRet = ERROR_SUCCESS]);

        Inc(iCurrent);

        pszText := FormatW(LoadStrW(ID_ROUTE_PROGRESS), [iCurrent, iCheck]);
        SendMessageW(GetDlgItem(hWnd, IDC_LOGW_STATUSBAR_INFO), SB_SETTEXTW, 1,
          Integer(LPWSTR(pszText)));

        hChild := GetDlgItem(GetDlgItem(hWnd, IDC_LOGW_STATUSBAR_INFO),
          IDC_LOGW_PROGRESS);
        if (hChild <> 0) then
          SendMessageW(hChild, PBM_SETPOS, iCurrent, 0);

        Sleep(150);

      end;

    end;

    // добавляем маршруты для IP-TV.

    dwRet := SendMessageW(GetDlgItem(GetParent(hWnd), IDC_MAIN_AISTNET_ROUTE),
      BM_GETCHECK, 0, 0);
    if (dwRet = BST_CHECKED) then
    begin

      //

      iItem := SendMessageW(GetDlgItem(GetParent(hWnd), IDC_MAIN_IPADDR_NETMASK),
        CB_GETCURSEL, 0, 0);
      pszGateway := ComboBox_GetItemW(GetDlgItem(GetParent(hWnd),
        IDC_MAIN_IPADDR_NETMASK), iItem);

      //

      pszRoute := 'IP-TV';
      pszAddress := '232.0.0.0';
      pszNetMask := '255.255.252.0';

      dwRet := CreateForwardEntry(pszAddress, pszNetMask, pszGateway);

      pszText := FormatW(
        LoadStrW(ID_ROUTE_EVENT),
        [pszRoute, pszAddress, pszNetMask, LoadStrW(dwError[dwRet = ERROR_SUCCESS])]
      );
      SendMessageW(GetDlgItem(hWnd, IDC_LOGW_EVENT_LOG), LB_ADDSTRING, 0,
        Integer(LPWSTR(pszText)));

      SendMessageW(GetDlgItem(hWnd, IDC_LOGW_EVENT_LOG), LB_EX_SETIMAGEINDEX,
        iCurrent, dwImage[dwRet = ERROR_SUCCESS]);

      Inc(iCurrent);

      pszText := FormatW(LoadStrW(ID_ROUTE_PROGRESS), [iCurrent, iCheck]);
      SendMessageW(GetDlgItem(hWnd, IDC_LOGW_STATUSBAR_INFO), SB_SETTEXTW, 1,
        Integer(LPWSTR(pszText)));

      hChild := GetDlgItem(GetDlgItem(hWnd, IDC_LOGW_STATUSBAR_INFO),
        IDC_LOGW_PROGRESS);
      if (hChild <> 0) then
        SendMessageW(hChild, PBM_SETPOS, iCurrent, 0);

      Sleep(150);

      //

      pszRoute := 'SAP';
      pszAddress := '224.2.127.254';
      pszNetMask := '255.255.255.255';

      dwRet := CreateForwardEntry(pszAddress, pszNetMask, pszGateway);

      pszText := FormatW(
        LoadStrW(ID_ROUTE_EVENT),
        [pszRoute, pszAddress, pszNetMask, LoadStrW(dwError[dwRet = ERROR_SUCCESS])]
      );
      SendMessageW(GetDlgItem(hWnd, IDC_LOGW_EVENT_LOG), LB_ADDSTRING, 0,
        Integer(LPWSTR(pszText)));

      SendMessageW(GetDlgItem(hWnd, IDC_LOGW_EVENT_LOG), LB_EX_SETIMAGEINDEX,
        iCurrent, dwImage[dwRet = ERROR_SUCCESS]);

      Inc(iCurrent);

      pszText := FormatW(LoadStrW(ID_ROUTE_PROGRESS), [iCurrent, iCheck]);
      SendMessageW(GetDlgItem(hWnd, IDC_LOGW_STATUSBAR_INFO), SB_SETTEXTW, 1,
        Integer(LPWSTR(pszText)));

      hChild := GetDlgItem(GetDlgItem(hWnd, IDC_LOGW_STATUSBAR_INFO),
        IDC_LOGW_PROGRESS);
      if (hChild <> 0) then
        SendMessageW(hChild, PBM_SETPOS, iCurrent, 0);

      Sleep(150);

    end;

    //

    MessageBeep(MB_OK or MB_ICONINFORMATION);

    //

    SetEnableWindowW(GetDlgItem(hWnd, ID_CANCEL), TRUE);
    EnableMenuItem(hmMenu, SC_CLOSE, MF_BYCOMMAND or MF_ENABLED);
    PostMessageW(GetParent(hWnd), WM_COMMAND, MakeWParam(IDC_MAIN_ROUTE_LIST,
      LBN_SELCHANGE), GetDlgItem(GetParent(hWnd), IDC_MAIN_ROUTE_LIST));

    //

    hChild := GetDlgItem(GetDlgItem(hWnd, IDC_LOGW_STATUSBAR_INFO),
      IDC_LOGW_SPRITES);
    if (hChild <> 0) then
    begin
      SendMessageW(hChild, STM_EX_ANIMATESTOP, 0, 0);
      himl := SendMessageW(hChild, STM_EX_GETIMAGELIST, 0, 0);
      if (himl <> 0) then
        ImageList_Destroy(himl);
      himl := ImageList_LoadImageW(HInstance,
        MAKEINTRESOURCEW(RC_BITMAP_ENABLE_BUTTONS), 16, 0, CLR_DEFAULT,
        IMAGE_BITMAP, LR_LOADTRANSPARENT or LR_CREATEDIBSECTION);
      if (himl <> 0) then
        SendMessageW(hChild, STM_EX_SETIMAGELIST, himl, 0);
      SendMessageW(hChild, STM_EX_SETCURRENTFRAME, 2, 0);
    end;

    //

    pszText := LoadStrW(ID_ROUTE_READY);
    SendMessageW(GetDlgItem(hWnd, IDC_LOGW_STATUSBAR_INFO), SB_SETTEXTW, 1,
      Integer(LPWSTR(pszText)));

  end;

begin

  //

  SetCenterDialogPos(hWnd, GetParent(hWnd), TRUE);

  //

  if ((osvi.dwMajorVersion > 5) or ((osvi.dwMajorVersion = 5) and
    (osvi.dwMinorVersion >= 1))) then
  begin
    dwStyle := GetWindowLongW(GetDlgItem(hWnd, IDC_LOGW_STATUSBAR_INFO),
      GWL_EXSTYLE);
    if ((dwStyle and WS_EX_COMPOSITED) = 0) then
      SetWindowLongW(GetDlgItem(hWnd, IDC_LOGW_STATUSBAR_INFO), GWL_EXSTYLE,
        dwStyle or WS_EX_COMPOSITED);
  end;

  //

  CreateExtendedListboxW(GetDlgItem(hWnd, IDC_LOGW_EVENT_LOG));

  dwStyle := SendMessageW(GetDlgItem(hWnd, IDC_LOGW_EVENT_LOG),
    LB_EX_GETEXTENDEDSTYLE, 0, 0);
  dwStyle := dwStyle or LBS_EX_INFOTIP or LBS_EX_IMAGELIST;
  SendMessageW(GetDlgItem(hWnd, IDC_LOGW_EVENT_LOG), LB_EX_SETEXTENDEDSTYLE, 0,
    dwStyle);

  himl := ImageList_LoadImageW(HInstance, MAKEINTRESOURCEW(RC_BITMAP_ENABLE_BUTTONS),
    16, 0, CLR_DEFAULT, IMAGE_BITMAP, LR_LOADTRANSPARENT or LR_CREATEDIBSECTION);
  if (himl <> 0) then
    SendMessageW(GetDlgItem(hWnd, IDC_LOGW_EVENT_LOG), LB_EX_SETIMAGELIST, himl,
      0);

  //

  dwStyle := WS_CHILD or WS_VISIBLE or WS_CLIPSIBLINGS;
  CreateWindowExW(0, LPWSTR(WideString('STATIC')), nil, dwStyle, 0, 0, 0, 0,
    GetDlgItem(hWnd, IDC_LOGW_STATUSBAR_INFO), IDC_LOGW_SPRITES, HInstance, nil);

  hChild := GetDlgItem(GetDlgItem(hWnd, IDC_LOGW_STATUSBAR_INFO), IDC_LOGW_SPRITES);
  if (hChild <> 0) then
  begin
    CreateAnimationStaticW(hChild);
    himl := ImageList_LoadImageW(HInstance, MAKEINTRESOURCEW(RC_BITMAP_SPRITES),
      16, 0, CLR_DEFAULT, IMAGE_BITMAP, LR_LOADTRANSPARENT or LR_CREATEDIBSECTION);
    if (himl <> 0) then
      SendMessageW(hChild, STM_EX_SETIMAGELIST, himl, 0);
  end;

  //

  dwStyle := WS_CHILD or WS_VISIBLE or WS_CLIPSIBLINGS;
  CreateWindowExW(0, PROGRESS_CLASS, nil, dwStyle, 0, 0, 0, 0,
    GetDlgItem(hWnd, IDC_LOGW_STATUSBAR_INFO), IDC_LOGW_PROGRESS, HInstance, nil);

  //

  GetWindowRect(hWnd, rect);
  mmiX := rect.Right - rect.Left;
  mmiY := rect.Bottom - rect.Top;

  GetClientRect(hWnd, rect);
  SendMessageW(hWnd, WM_SIZE, -1, MakeLParam(rect.Right - rect.Left,
    rect.Bottom - rect.Top));

  //

  SetFocus(GetDlgItem(hWnd, ID_CANCEL));

  //

  hThread := CreateThread(
    nil,
    0,
    @ThreadCallback,        // функция обратного вызова.
    Pointer(THandle(hWnd)), // передаем в аргумент дескриптор окна.
    0,
    ThreadID
  );
  if (hThread <> 0) then
  begin
    CloseHandle(hThread);
    hThread := 0;
  end;

  //

  Result := 0;

end;

//

function LogwDlgProc_WmCommand(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  //

  case HiWord(wParam) of
    BN_CLICKED:
      case LoWord(wParam) of

        //

        ID_CANCEL:
        begin
          SendMessageW(hWnd, WM_CLOSE, 0, 0);
        end;

      end;

  end;

  //

  Result := 0;

end;

//

function LogwDlgProc_WmSize(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  uFlags : DWORD;
  Panels : Array [0..2] of Integer;
  rect   : TRect;
  hChild : THandle;
begin

  //

  if (wParam <> SIZE_MINIMIZED) then
  begin

    uFlags := SWP_NOACTIVATE or SWP_NOZORDER or SWP_NOMOVE;

    SetWindowPos(GetDlgItem(hWnd, IDC_LOGW_STATUSBAR_INFO), HWND_TOP, 0, 0,
      LoWord(lParam), HiWord(lParam), uFlags);

    Panels[0] := 26;
    Panels[1] := LoWord(lParam) - 125;
    Panels[2] := -1;
    SendMessageW(GetDlgItem(hWnd, IDC_LOGW_STATUSBAR_INFO), SB_SETPARTS, 3,
      Integer(@Panels));

    hChild := GetDlgItem(GetDlgItem(hWnd, IDC_LOGW_STATUSBAR_INFO),
      IDC_LOGW_SPRITES);
    if (hChild <> 0) then
    begin
      SendMessageW(GetDlgItem(hWnd, IDC_LOGW_STATUSBAR_INFO), SB_GETRECT, 0,
        Integer(@rect));
      SetWindowPos(
        hChild,
        HWND_TOP,
        rect.Left + 1,
        rect.Top + 1,
        rect.Right - rect.Left - 3,
        rect.Bottom - rect.Top - 2,
        uFlags xor SWP_NOMOVE
      );
    end;

    hChild := GetDlgItem(GetDlgItem(hWnd, IDC_LOGW_STATUSBAR_INFO),
      IDC_LOGW_PROGRESS);
    if (hChild <> 0) then
    begin
      SendMessageW(GetDlgItem(hWnd, IDC_LOGW_STATUSBAR_INFO), SB_GETRECT, 2,
        Integer(@rect));
      SetWindowPos(
        hChild,
        HWND_TOP,
        rect.Left + 3,
        rect.Top + 3,
        rect.Right - rect.Left - 7,
        rect.Bottom - rect.Top - 6,
        uFlags xor SWP_NOMOVE
      );
    end;

    GetWindowRect(GetDlgItem(hWnd, IDC_LOGW_EVENT_LOG), rect);
    SetWindowPos(GetDlgItem(hWnd, IDC_LOGW_EVENT_LOG), HWND_TOP, 0, 0,
      LoWord(lParam) - GetPixelFromDialogUnitX(8), HiWord(lParam) -
      GetPixelFromDialogUnitX(37), uFlags);

    uFlags := SWP_NOACTIVATE or SWP_NOZORDER or SWP_NOSIZE;

    SetWindowPos(GetDlgItem(hWnd, ID_CANCEL), HWND_TOP, LoWord(lParam) -
      GetPixelFromDialogUnitX(42), HiWord(lParam) - GetPixelFromDialogUnitX(28),
      0, 0, uFlags);

    uFlags := RDW_FRAME or RDW_INVALIDATE or RDW_UPDATENOW;

    RedrawWindow(GetDlgItem(hWnd, IDC_LOGW_STATUSBAR_INFO), nil, 0, uFlags);

  end;

  //

  Result := 0;

end;

//

function LogwDlgProc_WmGetMinMaxInfo(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  mmi: PMinMaxInfo;
begin

  //

  mmi := PMinMaxInfo(lParam);
  mmi.ptMinTrackSize.X := mmiX;
  mmi.ptMinTrackSize.Y := mmiY;

  //

  Result := 0;

end;

//

function LogwDlgProc_WmEraseBkgnd(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  rect: TRect;
begin

  //

  GetClientRect(hWnd, rect);
  FillRect(HDC(wParam), rect, HBRUSH(COLOR_BTNFACE + 1));

  //

  Result := 1;

end;

//

function LogwDlgProc_WmClose(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  himl  : HIMAGELIST;
  hChild: THandle;
begin

  //

  hChild := GetDlgItem(GetDlgItem(hWnd, IDC_LOGW_STATUSBAR_INFO), IDC_LOGW_SPRITES);
  if (hChild <> 0) then
  begin
    himl := SendMessageW(hChild, STM_EX_GETIMAGELIST, 0, 0);
    if (himl <> 0) then
      ImageList_Destroy(himl);
    RemoveAnimationStaticW(hChild);
    DestroyWindow(hChild);
  end;

  //

  hChild := GetDlgItem(GetDlgItem(hWnd, IDC_LOGW_STATUSBAR_INFO), IDC_LOGW_PROGRESS);
  if (hChild <> 0) then
    DestroyWindow(hChild);

  //

  himl := SendMessageW(GetDlgItem(hWnd, IDC_LOGW_EVENT_LOG), LB_EX_GETIMAGELIST, 0, 0);
  if (himl <> 0) then
    ImageList_Destroy(himl);

  RemoveExtendedListboxW(GetDlgItem(hWnd, IDC_LOGW_EVENT_LOG));

  //

  EndDialog(hWnd, 0);

  //

  Result := 0;
  
end;

//

function LogwDlgProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): BOOL; stdcall;
begin

  case uMsg of

    //

    WM_INITDIALOG:
    begin
      Result := BOOL(LogwDlgProc_WmInitDialog(hWnd, uMsg, wParam, lParam));
    end;

    //

    WM_COMMAND:
    begin
      Result := BOOL(LogwDlgProc_WmCommand(hWnd, uMsg, wParam, lParam));
    end;

    //

    WM_SIZE:
    begin
      Result := BOOL(LogwDlgProc_WmSize(hWnd, uMsg, wParam, lParam));
    end;

    //

    WM_GETMINMAXINFO:
    begin
      Result := BOOL(LogwDlgProc_WmGetMinMaxInfo(hWnd, uMsg, wParam, lParam));
    end;

    //

    WM_ERASEBKGND:
    begin
      Result := BOOL(LogwDlgProc_WmEraseBkgnd(hWnd, uMsg, wParam, lParam));
    end;

    //

    WM_CLOSE:
    begin
      Result := BOOL(LogwDlgProc_WmClose(hWnd, uMsg, wParam, lParam));
    end;

  else
    Result := FALSE;
  end;

end;

end.