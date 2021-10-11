unit D_MainProc;

interface

uses
  Windows, Messages, CommCtrl, ShellApi, F_CommDlg, F_UxThemes, F_SysUtils,
  F_IpHlpApi, F_Windows, F_ButtHiml, F_ListBoxEx, F_HyperLink, F_MyMsgBox,
  F_Resources, F_Controls, F_MiscUtils, D_InfoProc, D_EditProc, D_DownProc,
  D_InstProc, D_LogwProc, D_HookProc;

function MainDlgProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): BOOL; stdcall;

implementation

//

function MainDlgProc_WmInitDialog(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  himl   : HIMAGELIST;
  himi   : HICON;
  hfnt   : HFONT;
  hmMenu : HMENU;
  pszText: WideString;
  nItem  : Integer;
  iCount : Integer;
  rect   : TRect;
  Panels : Array [0..1] of Integer;
  bi     : BUTTON_IMAGELIST;
  bResult: Boolean;
  dwStyle: DWORD;
begin

  //

  himi := LoadImageW(HInstance, MAKEINTRESOURCEW(RC_ICON_MAIN), IMAGE_ICON, 16,
    16, 0);
  if (himi <> 0) then
    SendMessageW(hWnd, WM_SETICON, ICON_SMALL, himi);

  //

  pszText := FormatW(LoadStrW(ID_APP_VERSION), [ExeInfo.pszProductName,
    ExeInfo.pszFileVersion]);
  SendMessageW(hWnd, WM_SETTEXT, 0, Integer(LPWSTR(pszText)));

  //

  hfnt := CreateFontW(GetWindowFontSizeW(hWnd, 8), 0, 0, 0, 400, 5, 0, 0,
    RUSSIAN_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, PROOF_QUALITY,
    DEFAULT_PITCH, LPWSTR(fmtFontName));
  if (hfnt <> 0) then
    SendMessageW(GetDlgItem(hWnd, IDC_MAIN_WINDOW_MODE), WM_SETFONT, hfnt, 0);

  //

  CreateExtendedListboxW(GetDlgItem(hWnd, IDC_MAIN_ROUTE_LIST));

  dwStyle := SendMessageW(GetDlgItem(hWnd, IDC_MAIN_ROUTE_LIST),
    LB_EX_GETEXTENDEDSTYLE, 0, 0);
  dwStyle := dwStyle or LBS_EX_CHECKBOXES or LBS_EX_INFOTIP;
  SendMessageW(GetDlgItem(hWnd, IDC_MAIN_ROUTE_LIST), LB_EX_SETEXTENDEDSTYLE, 0,
    dwStyle);

  //

  for iCount := Low(pszRoutes) to High(pszRoutes) do
  begin
    nItem := SendMessageW(GetDlgItem(hWnd, IDC_MAIN_ROUTE_LIST), LB_ADDSTRING,
      0, Integer(pszRoutes[iCount]));
    SendMessageW(GetDlgItem(hWnd, IDC_MAIN_ROUTE_LIST), LB_EX_SETITEMSTATE,
      nItem, LST_CHECKED);
  end;

  // создаем панель инструментов.

  SendMessageW(GetDlgItem(hWnd, IDC_MAIN_TOOLBAR_EDIT), TB_BUTTONSTRUCTSIZE,
    SizeOf(TTBButton), 0);
  SendMessageW(GetDlgItem(hWnd, IDC_MAIN_TOOLBAR_EDIT), TB_BUTTONCOUNT, 0, 0);
  SendMessageW(GetDlgItem(hWnd, IDC_MAIN_TOOLBAR_EDIT), TB_ADDBUTTONS,
    Length(tbBtnsEdit), Integer(@tbBtnsEdit));
  SendMessageW(GetDlgItem(hWnd, IDC_MAIN_TOOLBAR_EDIT), TB_AUTOSIZE, 0, 0);

  //

  himl := ImageList_LoadImageW(HInstance, MAKEINTRESOURCEW(RC_BITMAP_ENABLE_BUTTONS),
    16, 0, CLR_DEFAULT, IMAGE_BITMAP, LR_DEFAULTCOLOR or LR_CREATEDIBSECTION);
  if (himl <> 0) then
    SendMessageW(GetDlgItem(hWnd, IDC_MAIN_TOOLBAR_EDIT), TB_SETIMAGELIST, 0,
      himl);
  himl := ImageList_LoadImageW(HInstance, MAKEINTRESOURCEW(RC_BITMAP_DISABLE_BUTTONS),
    16, 0, CLR_DEFAULT, IMAGE_BITMAP, LR_DEFAULTCOLOR or LR_CREATEDIBSECTION);
  if (himl <> 0) then
    SendMessageW(GetDlgItem(hWnd, IDC_MAIN_TOOLBAR_EDIT), TB_SETDISABLEDIMAGELIST,
      0, himl);

  // создаем окно строки состояния.

  GetClientRect(hWnd, rect);
  Panels[0] := (rect.Right - rect.Left) div 2;
  Panels[1] := -1;
  SendMessageW(GetDlgItem(hWnd, IDC_MAIN_STATUSBAR_INFO), SB_SETPARTS, 2,
    Integer(@Panels));

  // добавляем значки в строку состояния.

  himl := ImageList_LoadImageW(HInstance, MAKEINTRESOURCEW(RC_BITMAP_STATUS_INFO),
    16, 0, CLR_DEFAULT, IMAGE_BITMAP, LR_DEFAULTCOLOR or LR_CREATEDIBSECTION);
  if (himl <> 0) then
  begin
    himi := ImageList_GetIcon(himl, 0, ILD_NORMAL or ILD_TRANSPARENT);
    if (himi <> 0) then
      SendMessageW(GetDlgItem(hWnd, IDC_MAIN_STATUSBAR_INFO), SB_SETICON, 0, himi);
    himi := ImageList_GetIcon(himl, 1, ILD_NORMAL or ILD_TRANSPARENT);
    if (himi <> 0) then
      SendMessageW(GetDlgItem(hWnd, IDC_MAIN_STATUSBAR_INFO), SB_SETICON, 1, himi);
    ImageList_Destroy(himl);
  end;

  // отмечаем чекбокс добавления маршрута для IP-TV.

  SendMessageW(GetDlgItem(hWnd, IDC_MAIN_AISTNET_ROUTE), BM_SETCHECK, BST_CHECKED, 0);

  // добавляем дополнительный пункт в системное меню диалога.

  hmMenu := GetSystemMenu(hWnd, FALSE);
  AppendMenuW(hmMenu, MF_SEPARATOR, 0, nil);
  pszText := LoadStrW(ID_ABOUT_MENU);
  AppendMenuW(hmMenu, MF_BYPOSITION, IDM_MAIN_ABOUT, LPWSTR(pszText));

  //

  CreateHyperlinkStaticW(GetDlgItem(hWnd, IDC_MAIN_UPDATE_ADAPTERS));

  //

  hfnt := CreateFontW(GetWindowFontSizeW(hWnd, 8), 0, 0, 0, 800, 0, 1, 0,
    RUSSIAN_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, PROOF_QUALITY,
    DEFAULT_PITCH, LPWSTR(fmtFontName));
  if (hfnt <> 0) then
    SendMessageW(GetDlgItem(hWnd, IDC_MAIN_AUTO_CREATE), WM_SETFONT, hfnt, 0);

  //

  ZeroMemory(@bi, SizeOf(BUTTON_IMAGELIST));
  with bi do
  begin
    himl        := ImageList_LoadImageW(HInstance,
      MAKEINTRESOURCEW(RC_BITMAP_AUTO_CREATE), 16, 1, RGB(192, 192, 192),
      IMAGE_BITMAP, LR_CREATEDIBSECTION);
    margin.Left := 10;
    uAlign      := BUTTON_IMAGELIST_ALIGN_LEFT;
    bResult := BOOL(SendMessageW(GetDlgItem(hWnd, IDC_MAIN_AUTO_CREATE),
      BCM_SETIMAGELIST, 0, Integer(@bi)));
    if not bResult then
      ImageList_Destroy(himl);
  end;

  // подготавливаем кнопку изменения режима и уменьшаем окно.

  PostMessageW(hWnd, WM_COMMAND, MakeWParam(IDC_MAIN_WINDOW_MODE, BN_CLICKED), 0);

  // извлекаем сведения из сетевых интерфейсов.

  PostMessageW(hWnd, WM_COMMAND, MakeWParam(IDC_MAIN_UPDATE_ADAPTERS, BN_CLICKED),
    0);

  //

  ShowWindow(hWnd, SW_SHOW);

  //

  SetFocus(GetDlgItem(hWnd, IDC_MAIN_WINDOW_MODE));

  //

  Result := 0;

end;

//

function MainDlgProc_WmCommand(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
const
  fmtDefExt  : WideString = 'bat';
  fmtFileName: WideString = 'MyRoutes.bat';
var
  dwRet  : DWORD;
  dwLen  : ULONG;
  PipAdap: PIP_ADAPTER_INFO;
  PIpAddr: PIP_ADDR_STRING;
  nItem  : Integer;
  pszText: WideString;
  ofn    : TOpenFilenameW;
  iCount : Integer;
  iCheck : Integer;
  bResult: Boolean;
  hf     : HFILE;
  pszAnsi: LPTSTR;
  hPopup : HMENU;
  lpmii  : TMenuItemInfoW;
  rect   : TRect;
  params : TTPMParams;
begin

  // идентификаторы пунктов меню списка серверов.

  iCount := Length(pszServers);
  if (LoWord(wParam) - IDM_SERVERS_START in [0..iCount]) then
    SetUpdate := LoWord(wParam) - IDM_SERVERS_START;

  //

  case HiWord(wParam) of

    // идентификатор акселераторов совпадает с сообщением LBN_SELCHANGE.

    LBN_SELCHANGE:
      case LoWord(wParam) of

        //

        IDC_MAIN_ROUTE_LIST:
        begin

          // получаем количество выделенных чекбоксов и число маршрутов в списке.

          iCheck := SendMessageW(GetDlgItem(hWnd, IDC_MAIN_ROUTE_LIST),
            LB_EX_GETCHECKCOUNT, 0, 0);
          iCount := SendMessageW(GetDlgItem(hWnd, IDC_MAIN_ROUTE_LIST),
            LB_GETCOUNT, 0, 0);

          pszText := FormatW(LoadStrW(ID_ROUTES_COUNT), [iCount]);
          SendMessageW(GetDlgItem(hWnd, IDC_MAIN_STATUSBAR_INFO), SB_SETTEXTW,
            0, Integer(LPWSTR(pszText)));
          pszText := FormatW(LoadStrW(ID_SELECTED_ROUTES), [iCheck]);
          SendMessageW(GetDlgItem(hWnd, IDC_MAIN_STATUSBAR_INFO), SB_SETTEXTW,
            1, Integer(LPWSTR(pszText)));

          // проверяем выделен ли какой-нибудь пункт в списке маршрутов.

          dwRet := SendMessageW(GetDlgItem(hWnd, IDC_MAIN_ROUTE_LIST),
            LB_GETCURSEL, 0, 0);
          bResult := Integer(dwRet) <> LB_ERR;
          SendMessageW(GetDlgItem(hWnd, IDC_MAIN_TOOLBAR_EDIT), TB_ENABLEBUTTON,
            IDT_MAIN_EDIT_ROUTE, Integer(bResult));
          SendMessageW(GetDlgItem(hWnd, IDC_MAIN_TOOLBAR_EDIT), TB_ENABLEBUTTON,
            IDT_MAIN_DELETE_ROUTE, Integer(bResult));

          bResult := iCount > 0;
          SendMessageW(GetDlgItem(hWnd, IDC_MAIN_TOOLBAR_EDIT), TB_ENABLEBUTTON,
            IDT_MAIN_CLEAR_LIST, Integer(bResult));
          SetEnableWindowW(GetDlgItem(hWnd, IDC_MAIN_SELECT_ALL), bResult);
          SetEnableWindowW(GetDlgItem(hWnd, IDC_MAIN_UNSELECT_ALL), bResult);

          // изменяем состояние кнопок взависимости от ситуации.

          dwRet := SendMessageW(GetDlgItem(hWnd, IDC_MAIN_IPADDR_ROUTES),
            CB_GETCOUNT, 0, 0);

          bResult := dwRet > 0;
          SetEnableWindowW(GetDlgItem(hWnd, IDC_MAIN_IPADDR_ROUTES), bResult);
          SetEnableWindowW(GetDlgItem(hWnd, IDC_MAIN_IPADDR_NETMASK), bResult);
          SetEnableWindowW(GetDlgItem(hWnd, IDC_MAIN_UPDATE_ROUTES), bResult);
          SetEnableWindowW(GetDlgItem(hWnd, IDC_MAIN_SERVER_LIST), bResult);

          bResult := bResult and (iCheck > 0);
          SetEnableWindowW(GetDlgItem(hWnd, IDC_MAIN_AISTNET_ROUTE), bResult);
          SetEnableWindowW(GetDlgItem(hWnd, IDC_MAIN_AUTO_CREATE), bResult);

          bResult := bResult and (iCount > 0);
          SendMessageW(GetDlgItem(hWnd, IDC_MAIN_TOOLBAR_EDIT), TB_ENABLEBUTTON,
            IDT_MAIN_CLIPBOARD, Integer(bResult));
          SendMessageW(GetDlgItem(hWnd, IDC_MAIN_TOOLBAR_EDIT), TB_ENABLEBUTTON,
            IDT_MAIN_FILE_SAVE, Integer(bResult));

        end;

        //

        IDH_MAIN_CREATE_ROUTE:
        begin

          PostMessageW(hWnd, WM_COMMAND, MakeWParam(IDM_MAIN_CREATE_ROUTE,
            BN_CLICKED), 0);

        end;

      //

        IDH_MAIN_EDIT_ROUTE:
        begin

          PostMessageW(hWnd, WM_COMMAND, MakeWParam(IDM_MAIN_EDIT_ROUTE,
            BN_CLICKED), 0);

        end;

        //

        IDH_MAIN_DELETE_ROUTE:
        begin

          PostMessageW(hWnd, WM_COMMAND, MakeWParam(IDM_MAIN_DELETE_ROUTE,
            BN_CLICKED), 0);

        end;

        //

        IDH_MAIN_CLEAR_LIST:
        begin

          PostMessageW(hWnd, WM_COMMAND, MakeWParam(IDM_MAIN_CLEAR_LIST,
            BN_CLICKED), 0);

        end;

      end;

    //

    LBN_DBLCLK:
      case LoWord(wParam) of

        //

        IDC_MAIN_ROUTE_LIST:
        begin

          PostMessageW(hWnd, WM_COMMAND, MakeWParam(IDM_MAIN_EDIT_ROUTE,
            BN_CLICKED), 0);

        end;

      end;

    //

    BN_CLICKED:
      case LoWord(wParam) of

        //

        IDC_MAIN_UPDATE_ADAPTERS:
        begin

          PipAdap := nil;
          dwLen   := 0;
          dwRet   := GetAdaptersInfo(PipAdap, @dwLen);

          SendMessageW(GetDlgItem(hWnd, IDC_MAIN_IPADDR_ROUTES),
            CB_RESETCONTENT, 0, 0);
          SendMessageW(GetDlgItem(hWnd, IDC_MAIN_IPADDR_NETMASK),
            CB_RESETCONTENT, 0, 0);

          if (dwRet = ERROR_BUFFER_OVERFLOW) then
          begin
            PipAdap := PIP_ADAPTER_INFO(HeapAlloc(GetProcessHeap,
              HEAP_ZERO_MEMORY, dwLen));
            try
              dwRet := GetAdaptersInfo(PipAdap, @dwLen);
              if (dwRet = ERROR_SUCCESS) then
              begin
                repeat

                  PIpAddr := @PipAdap.GatewayList;
                  while (PIpAddr <> nil) do
                  begin
                    pszText := AnsiStringToWide(PIpAddr.IpAddress.acString, CP_ACP);
                    if IsValidIPAddressW(pszText) then
                      SendMessageW(GetDlgItem(hWnd, IDC_MAIN_IPADDR_ROUTES),
                        CB_ADDSTRING, 0, Integer(LPWSTR(pszText)));
                    PIpAddr := PIpAddr.Next;
                  end;

                  PIpAddr := @PipAdap.IpAddressList;
                  while (PIpAddr <> nil) do
                  begin
                    pszText := AnsiStringToWide(PIpAddr.IpAddress.acString, CP_ACP);
                    SendMessageW(GetDlgItem(hWnd, IDC_MAIN_IPADDR_NETMASK),
                      CB_ADDSTRING, 0, Integer(LPWSTR(pszText)));
                    PIpAddr := PIpAddr.Next;
                  end;

                  PipAdap := PipAdap.Next;

                until
                  PipAdap = nil;
              end;
            finally
              HeapFree(GetProcessHeap, 0, PipAdap);
            end;
          end;

          SendMessageW(GetDlgItem(hWnd, IDC_MAIN_IPADDR_ROUTES), CB_SETCURSEL,
            0, 0);
          SendMessageW(GetDlgItem(hWnd, IDC_MAIN_IPADDR_NETMASK), CB_SETCURSEL,
            0, 0);

          PostMessageW(hWnd, WM_COMMAND, MakeWParam(IDC_MAIN_ROUTE_LIST,
            LBN_SELCHANGE), GetDlgItem(hWnd, IDC_MAIN_ROUTE_LIST));

        end;

        //

        IDC_MAIN_WINDOW_MODE:
        begin

          // iDiff := nItem; iWidth := iCount; iHeight := iCheck.

          dwRet := SendMessageW(GetDlgItem(hWnd, IDC_MAIN_WINDOW_MODE),
            BM_GETCHECK, 0, 0);

          //
          GetWindowRect(hWnd, rect);
          iCount := rect.Bottom - rect.Top;
          GetClientRect(hWnd, rect);
          nItem := iCount - (rect.Bottom - rect.Top);
          //

          GetWindowRect(hWnd, rect);
          iCount := rect.Right - rect.Left;

          if (dwRet = BST_CHECKED) then
          begin

            pszText := LoadStrW(ID_SIMPLE_MODE);

            GetWindowRect(GetDlgItem(hWnd, IDC_MAIN_STATUSBAR_INFO), rect);
            MapWindowPoints(0, hWnd, rect, 2);

            iCheck := rect.Bottom + nItem;

            {
            GetSystemMetrics(SM_CYCAPTION) + GetSystemMetrics(SM_CXFRAME) * 2 - 1
            }

          end
          else
          begin

            pszText := LoadStrW(ID_EXTENDED_MODE);

            GetWindowRect(GetDlgItem(hWnd, IDC_MAIN_WINDOW_MODE), rect);
            MapWindowPoints(0, hWnd, rect, 2);

            iCheck := rect.Bottom + nItem + ((rect.Bottom - rect.Top) div 2);

            {
            GetSystemMetrics(SM_CYCAPTION) + GetSystemMetrics(SM_CXFRAME) * 2 + 5
            }

          end;

          SendMessageW(GetDlgItem(hWnd, IDC_MAIN_WINDOW_MODE), WM_SETTEXT, 0,
            Integer(LPWSTR(pszText)));

          dwRet := SWP_FRAMECHANGED or SWP_NOMOVE or SWP_NOZORDER or SWP_NOACTIVATE;
          SetWindowPos(hWnd, 0, 0, 0, iCount, iCheck, dwRet);

        end;

        //

        IDC_MAIN_AUTO_CREATE:
        begin

          DialogBoxParamW(HInstance, MAKEINTRESOURCEW(RC_DIALOG_EVENT), hWnd,
            @LogwDlgProc, 0);

        end;

        //

        IDC_MAIN_UPDATE_ROUTES:
          begin

            DialogBoxParamW(HInstance, MAKEINTRESOURCEW(RC_DIALOG_UPDATE_ROUTES),
              hWnd, @DownDlgProc, 0);

          end;

        //

        IDT_MAIN_CREATE_ROUTE,
        IDM_MAIN_CREATE_ROUTE:
        begin

          DialogBoxParamW(HInstance, MAKEINTRESOURCEW(RC_DIALOG_EDIT_ENTRY),
            hWnd, @InstDlgProc, 0);

        end;

        //

        IDT_MAIN_EDIT_ROUTE,
        IDM_MAIN_EDIT_ROUTE:
        begin

          nItem := SendMessageW(GetDlgItem(hWnd, IDC_MAIN_ROUTE_LIST),
            LB_GETCURSEL, 0, 0);
          if (nItem <> LB_ERR) then
            DialogBoxParamW(HInstance, MAKEINTRESOURCEW(RC_DIALOG_EDIT_ENTRY),
              hWnd, @EditDlgProc, 0);

        end;

        //

        IDT_MAIN_DELETE_ROUTE,
        IDM_MAIN_DELETE_ROUTE:
        begin

          nItem := SendMessageW(GetDlgItem(hWnd, IDC_MAIN_ROUTE_LIST),
            LB_GETCURSEL, 0, 0);
          if (nItem <> LB_ERR) then
          begin
            SendMessageW(GetDlgItem(hWnd, IDC_MAIN_ROUTE_LIST), LB_DELETESTRING,
              nItem, 0);
            SendMessageW(GetDlgItem(hWnd, IDC_MAIN_ROUTE_LIST), LB_SETCURSEL,
              nItem, 0);
            PostMessageW(hWnd, WM_COMMAND, MakeWParam(IDC_MAIN_ROUTE_LIST,
              LBN_SELCHANGE), GetDlgItem(hWnd, IDC_MAIN_ROUTE_LIST));
          end;

        end;

        //

        IDT_MAIN_CLEAR_LIST,
        IDM_MAIN_CLEAR_LIST:
        begin

          dwRet := SendMessageW(GetDlgItem(hWnd, IDC_MAIN_ROUTE_LIST),
            LB_GETCOUNT, 0, 0);
          if (dwRet > 0) then
          begin
            pszText := LoadStrW(ID_NOTIFY_CLEAR);
            dwRet := MyMessageBoxW(
              hWnd,
              MAKEINTRESOURCEW(pszText),
              MAKEINTRESOURCEW(ExeInfo.pszProductName),
              MB_YESNO or MB_ICONQUESTION
            );
            if (dwRet = ID_YES) then
            begin
              SendMessageW(GetDlgItem(hWnd, IDC_MAIN_ROUTE_LIST),
                LB_RESETCONTENT, 0, 0);
              PostMessageW(hWnd, WM_COMMAND, MakeWParam(IDC_MAIN_ROUTE_LIST,
                LBN_SELCHANGE), GetDlgItem(hWnd, IDC_MAIN_ROUTE_LIST));
            end;
          end;

        end;

        //

        IDT_MAIN_CLIPBOARD:
        begin

          pszText := GetBatFileContentFromList(hWnd);
          SetTextToClipboard(hWnd, LPWSTR(pszText), TRUE);
          MessageBeep(MB_OK or MB_ICONINFORMATION);

        end;

        //

        IDT_MAIN_FILE_SAVE:
        begin

          dwRet := OFN_OVERWRITEPROMPT or OFN_DONTADDTORECENT or
            OFN_ENABLESIZING or OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST or
            OFN_LONGNAMES or OFN_EXPLORER or OFN_HIDEREADONLY or
            OFN_ENABLEHOOK or OFN_ENABLETEMPLATE;

          ZeroMemory(@ofn, SizeOf(TOpenFilenameW));

          if (osvi.dwPlatformId = VER_PLATFORM_WIN32_NT) then
            ofn.lStructSize := SizeOf(TOpenFilenameW)
          else
            ofn.lStructSize := OPENFILENAME_SIZE_VERSION_400W;
          ofn.hWndOwner       := hWnd;
          ofn.hInstance       := HInstance;
          ofn.lpstrFilter     := MAKEINTRESOURCEW(
            CharReplaceW(LoadStrW(ID_FILTER_INDEX), '|', #0)
            );
          ofn.lpstrFile       := VirtualAlloc(
            nil, MAX_PATH, MEM_COMMIT, PAGE_READWRITE
            );
          ofn.lpstrDefExt     := LPWSTR(fmtDefExt);
          ofn.lpstrInitialDir := MAKEINTRESOURCEW(
            ExtractFilePathW(AnsiStringToWide(ParamStr(0), CP_ACP))
            );
          ofn.nMaxFile        := MAX_PATH;
          ofn.lpTemplateName  := MAKEINTRESOURCEW(RC_DIALOG_OFN_TEMPLATE);
          ofn.lpfnHook        := HookDlgProc;
          ofn.FlagsEx         := OFN_EX_NOPLACESBAR;
          ofn.Flags           := dwRet;
          lstrcpyW(ofn.lpstrFile, LPWSTR(fmtFileName));

          SetExecute := FALSE;

          if GetSaveFileNameW(ofn) then
          begin

            // проверяем расширение у сохраняемого файла. если выбран первый
            // элемент в списке расширений, выполняем проверку на наличие
            // расширения файла в его имени.

            bResult := FALSE;
            hf := CreateFileW(ofn.lpstrFile, GENERIC_WRITE, FILE_SHARE_WRITE,
              nil, CREATE_ALWAYS, 0, 0);
            dwRet := GetLastError;
            if (hf <> INVALID_HANDLE_VALUE) then
            try
              pszAnsi := LPTSTR(WideStringToAnsi(GetBatFileContentFromList(hWnd),
                CP_ACP));
              bResult := WriteFile(hf, pszAnsi[0], lstrlen(pszAnsi), dwLen, nil);
              dwRet := GetLastError;
            finally
              CloseHandle(hf);
            end;

            if not bResult then
            begin
              pszText := SysErrorMessageW(dwRet);
              pszText := FormatW(
                LoadStrW(ID_ERROR_CODE),
                [ofn.lpstrFile, dwRet, pszText]
              );
              MyMessageBoxW(
                hWnd,
                MAKEINTRESOURCEW(pszText),
                MAKEINTRESOURCEW(ExeInfo.pszProductName),
                MB_OK or MB_ICONSTOP
              );
            end;

            if (bResult and SetExecute) then
              ShellExecuteAndWaitW(ofn.lpstrFile, SW_SHOWNORMAL);

          end;

          VirtualFree(ofn.lpstrFile, 0, MEM_RELEASE);

        end;

        //

        IDC_MAIN_SERVER_LIST:
          begin

            hPopup := CreatePopupMenu;
            if (hPopup <> 0) then
            begin

              for iCount := 1 to Length(pszServers) do
              begin

                pszText := pszServers[iCount - 1, 1];

                ZeroMemory(@lpmii, SizeOf(TMenuItemInfoW));
                lpmii.cbSize     := SizeOf(TMenuItemInfoW);
                lpmii.fState     := MFS_ENABLED;
                lpmii.fMask      := MIIM_STRING or MIIM_STATE or MIIM_ID;
                lpmii.dwTypeData := LPWSTR(pszText);
                lpmii.wID        := IDM_SERVERS_START + iCount;
                InsertMenuItemW(hPopup, iCount, TRUE, lpmii);

              end;

              CheckMenuRadioItem(
                hPopup,
                IDM_SERVERS_START + 1,
                IDM_SERVERS_START + Length(pszServers),
                IDM_SERVERS_START + SetUpdate,
                MF_BYCOMMAND
              );

              GetWindowRect(GetDlgItem(hWnd, IDC_MAIN_SERVER_LIST), rect);

              params.cbSize := SizeOf(TTPMParams);
              params.rcExclude := rect;

              dwRet := TPM_HORPOSANIMATION or TPM_LEFTBUTTON or TPM_VERTICAL or
                TPM_RIGHTALIGN or TPM_TOPALIGN;
              TrackPopupMenuEx(hPopup, dwRet, rect.Right, rect.Bottom,
                hWnd, @params);

              DestroyMenu(hPopup);

            end;

          end;

        //

        IDC_MAIN_SELECT_ALL:
        begin

          iCount := SendMessageW(GetDlgItem(hWnd, IDC_MAIN_ROUTE_LIST),
            LB_GETCOUNT, 0, 0);
          if (iCount > 0) then
          begin
            for nItem := 0 to iCount -1 do
              SendMessageW(GetDlgItem(hWnd, IDC_MAIN_ROUTE_LIST),
                LB_EX_SETITEMSTATE, nItem, LST_CHECKED);
          end;

          PostMessageW(hWnd, WM_COMMAND, MakeWParam(IDC_MAIN_ROUTE_LIST,
            LBN_SELCHANGE), GetDlgItem(hWnd, IDC_MAIN_ROUTE_LIST));

        end;

        //

        IDC_MAIN_UNSELECT_ALL:
        begin

          iCount := SendMessageW(GetDlgItem(hWnd, IDC_MAIN_ROUTE_LIST),
            LB_GETCOUNT, 0, 0);
          if (iCount > 0) then
          begin
            for nItem := 0 to iCount -1 do
              SendMessageW(GetDlgItem(hWnd, IDC_MAIN_ROUTE_LIST),
                LB_EX_SETITEMSTATE, nItem, LST_UNCHECKED);
          end;

          PostMessageW(hWnd, WM_COMMAND, MakeWParam(IDC_MAIN_ROUTE_LIST,
            LBN_SELCHANGE), GetDlgItem(hWnd, IDC_MAIN_ROUTE_LIST));

        end;

      end;
  end;

  //

  Result := 0;

end;

//

function MainDlgProc_WmContextMenu(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
const
  IsEnable: Array [Boolean] of Integer = (MF_GRAYED or MF_DISABLED, MF_ENABLED);
var
  hmMenu : HMENU;
  subMenu: HMENU;
  iItem  : Integer;
  bEnable: Boolean;
begin

  //

  if (THandle(wParam) = GetDlgItem(hWnd, IDC_MAIN_ROUTE_LIST)) then
  begin

    hmMenu := F_Windows.LoadMenuW(HInstance, MAKEINTRESOURCEW(RC_MENU_LIST));
    if (hmMenu <> 0) then
    begin

      subMenu := GetSubMenu(hmMenu, 0);
      if (subMenu <> 0) then
      begin

        iItem := SendMessageW(wParam, LB_GETCURSEL, 0, 0);
        bEnable := iItem > -1;
        EnableMenuItem(subMenu, IDM_MAIN_EDIT_ROUTE, MF_BYCOMMAND or
          IsEnable[bEnable]);
        EnableMenuItem(subMenu, IDM_MAIN_DELETE_ROUTE, MF_BYCOMMAND or
          IsEnable[bEnable]);
        iItem := SendMessageW(wParam, LB_GETCOUNT, 0, 0);
        bEnable := iItem <> 0;
        EnableMenuItem(subMenu, IDM_MAIN_CLEAR_LIST, MF_BYCOMMAND or
          IsEnable[bEnable]);

      TrackPopupMenu(subMenu, TPM_HORIZONTAL, LoWord(lParam), HiWord(lParam), 0,
        hWnd, nil);

      end;

      DestroyMenu(hmMenu);

    end;

  end;

  //

  Result := 0;

end;

//

function MainDlgProc_WmThemeChanged(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  // так как существует ошибка при отлове сообщения WM_THEMECHANGED при
  // применении современной темы оформления после классической, как
  // вариант - используем WM_SYSCOLORCHANGE сообщение. это требуется для
  // выравнивания диалогового окна по нижней границе строки состояния.
  // http://connect.microsoft.com/VisualStudio/feedback/ViewFeedback.aspx?FeedbackID=123811#details

  PostMessageW(hWnd, WM_COMMAND, MakeWParam(IDC_MAIN_WINDOW_MODE, BN_CLICKED), 0);

  //

  Result := 0;

end;

//

function MainDlgProc_WmSysCommand(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  //

  case LoWord(wParam) of

    //

    IDM_MAIN_ABOUT:
    begin
      Result := DialogBoxParamW(HInstance, MAKEINTRESOURCEW(RC_DIALOG_ABOUT),
        hWnd, @InfoDlgProc, 0);
    end;
    
  else
    Result := 0;
  end;

end;

//

function MainDlgProc_WmNotify(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  pnmh : PNMHdr;
  pttip: PToolTipTextW;
begin

  //

  pnmh := PNMHdr(lParam);
  case pnmh.code of

    //

    TTN_NEEDTEXTW:
      begin

        pttip := PToolTipTextW(lParam);
        case pttip.hdr.idFrom of
          IDT_MAIN_CREATE_ROUTE:
            pttip.lpszText := MAKEINTRESOURCEW(ID_INSERT_ROUTE);
          IDT_MAIN_EDIT_ROUTE:
            pttip.lpszText := MAKEINTRESOURCEW(ID_EDIT_ROUTE);
          IDT_MAIN_DELETE_ROUTE:
            pttip.lpszText := MAKEINTRESOURCEW(ID_DELETE_ROUTE);
          IDT_MAIN_CLEAR_LIST:
            pttip.lpszText := MAKEINTRESOURCEW(ID_CLEAR_LIST);
          IDT_MAIN_CLIPBOARD:
            pttip.lpszText := MAKEINTRESOURCEW(ID_COPY_CLIPBOARD);
          IDT_MAIN_FILE_SAVE:
            pttip.lpszText := MAKEINTRESOURCEW(ID_FILE_SAVE);
        end;

      end;
  end;

  //

  Result := 0;

end;

//

function MainDlgProc_WmClose(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  himi: HICON;
  himl: HIMAGELIST;
  hfnt: HFONT;
  bi  : BUTTON_IMAGELIST;
begin

  //

  himi := SendMessageW(hWnd, WM_GETICON, ICON_SMALL, 0);
  if (himi <> 0) then
    DestroyIcon(himi);

  //

  hfnt := SendMessageW(GetDlgItem(hWnd, IDC_MAIN_AUTO_CREATE), WM_GETFONT, 0, 0);
  if (hfnt <> 0) then
    DeleteObject(hfnt);
  hfnt := SendMessageW(GetDlgItem(hWnd, IDC_MAIN_WINDOW_MODE), WM_GETFONT, 0, 0);
  if (hfnt <> 0) then
    DeleteObject(hfnt);

  //

  himl := SendMessageW(GetDlgItem(hWnd, IDC_MAIN_TOOLBAR_EDIT), TB_GETIMAGELIST,
    0, 0);
  if (himl <> 0) then
    ImageList_Destroy(himl);
  himl := SendMessageW(GetDlgItem(hWnd, IDC_MAIN_TOOLBAR_EDIT),
    TB_GETDISABLEDIMAGELIST, 0, 0);
  if (himl <> 0) then
    ImageList_Destroy(himl);

  //

  himi := SendMessageW(GetDlgItem(hWnd, IDC_MAIN_STATUSBAR_INFO), SB_GETICON, 0,
    0);
  if (himi <> 0) then
    DestroyIcon(himi);
  himi := SendMessageW(GetDlgItem(hWnd, IDC_MAIN_STATUSBAR_INFO), SB_GETICON, 1,
    0);
  if (himi <> 0) then
    DestroyIcon(himi);

  //

  RemoveExtendedListboxW(GetDlgItem(hWnd, IDC_MAIN_ROUTE_LIST));

  //

  RemoveHyperlinkStaticW(GetDlgItem(hWnd, IDC_MAIN_UPDATE_ADAPTERS));

  //

  SendMessageW(GetDlgItem(hWnd, IDC_MAIN_AUTO_CREATE), BCM_GETIMAGELIST, 0,
    Integer(@bi));
  if (bi.himl <> 0) then
    ImageList_Destroy(bi.himl);

  //

  PostQuitMessage(0);

  //

  Result := 0;

end;

//

function MainDlgProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): BOOL; stdcall;
begin

  case uMsg of

    //

    WM_INITDIALOG:
    begin
      Result := BOOL(MainDlgProc_WmInitDialog(hWnd, uMsg, wParam, lParam));
    end;

    //

    WM_COMMAND:
    begin
      Result := BOOL(MainDlgProc_WmCommand(hWnd, uMsg, wParam, lParam));
    end;

    //
    
    WM_CONTEXTMENU:
    begin
      Result := BOOL(MainDlgProc_WmContextMenu(hWnd, uMsg, wParam, lParam));
    end;

    //

    WM_THEMECHANGED,
    WM_SYSCOLORCHANGE:
    begin
      Result := BOOL(MainDlgProc_WmThemeChanged(hWnd, uMsg, wParam, lParam));
    end;

    //

    WM_SYSCOMMAND:
    begin
      Result := BOOL(MainDlgProc_WmSysCommand(hWnd, uMsg, wParam, lParam));
    end;

    //

    WM_NOTIFY:
    begin
      Result := BOOL(MainDlgProc_WmNotify(hWnd, uMsg, wParam, lParam));
    end;

    //

    WM_CLOSE:
    begin
      Result := BOOL(MainDlgProc_WmClose(hWnd, uMsg, wParam, lParam));
    end;

  else
    Result := FALSE;
  end;

end;

end.