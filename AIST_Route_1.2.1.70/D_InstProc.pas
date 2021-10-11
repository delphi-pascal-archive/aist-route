unit D_InstProc;

interface

uses
  Windows, Messages, CommCtrl, F_Windows, F_SysUtils, F_ListBoxEx, F_MyMsgBox,
  F_Resources, F_Controls, F_MiscUtils;

function InstDlgProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): BOOL; stdcall;

implementation

//

function InstDlgProc_WmInitDialog(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  dwRet  : DWORD;
  bResult: Boolean;
  pszText: WideString;
begin

  //

  SetCenterDialogPos(hWnd, GetParent(hWnd), TRUE);

  //

  SendMessageW(GetDlgItem(hWnd, IDC_EDIT_ROUTE_NAME), EM_LIMITTEXT, 255, 0);

  //

  SendMessageW(GetDlgItem(hWnd, IDC_EDIT_WITHOUT_MASK), BM_SETCHECK, BST_CHECKED,
    0);
  dwRet := SendMessageW(GetDlgItem(hWnd, IDC_EDIT_WITHOUT_MASK), BM_GETCHECK, 0,
    0);
  bResult := dwRet <> BST_CHECKED;
  SetEnableWindowW(GetDlgItem(hWnd, IDC_EDIT_TEXT_NETMASK), bResult);
  SetEnableWindowW(GetDlgItem(hWnd, IDC_EDIT_SYSIP_NETMASK), bResult);

  //

  OnWmCommand_AddEdtDlgEnChange(hWnd);

  //

  SendMessageW(GetDlgItem(hWnd, IDC_EDIT_SYSIP_ADDRESS), IPM_SETFOCUS, 0, 0);

  //

  if (osvi.dwMajorVersion >= 5) then
  begin
    pszText := LoadStrW(ID_NAME_CUEBANNER);
    SendMessageW(GetDlgItem(hWnd, IDC_EDIT_ROUTE_NAME), EM_SETCUEBANNER, 0,
      Integer(LPWSTR(pszText)));
  end;

  //

  Result := 0;

end;

//

function InstDlgProc_WmCommand(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  dwRet  : DWORD;
  bResult: Boolean;
  pszText: WideString;
  nItem  : Integer;
begin

  //

  case HiWord(wParam) of

    //

    BN_CLICKED:
      case LoWord(wParam) of

        //

        IDC_EDIT_WITHOUT_MASK:
        begin

          dwRet := SendMessageW(GetDlgItem(hWnd, IDC_EDIT_WITHOUT_MASK),
            BM_GETCHECK, 0, 0);
          bResult := dwRet <> BST_CHECKED;
          SetEnableWindowW(GetDlgItem(hWnd, IDC_EDIT_TEXT_NETMASK), bResult);
          SetEnableWindowW(GetDlgItem(hWnd, IDC_EDIT_SYSIP_NETMASK), bResult);
          OnWmCommand_AddEdtDlgEnChange(hWnd);

        end;

        //

        IDC_EDIT_WITH_MASK:
        begin

          dwRet := SendMessageW(GetDlgItem(hWnd, IDC_EDIT_WITH_MASK), BM_GETCHECK,
            0, 0);
          bResult := dwRet = BST_CHECKED;
          SetEnableWindowW(GetDlgItem(hWnd, IDC_EDIT_TEXT_NETMASK), bResult);
          SetEnableWindowW(GetDlgItem(hWnd, IDC_EDIT_SYSIP_NETMASK), bResult);
          OnWmCommand_AddEdtDlgEnChange(hWnd);

        end;

        //

        ID_OK:
        begin

          dwRet := SendMessageW(GetDlgItem(hWnd, IDC_EDIT_WITHOUT_MASK),
            BM_GETCHECK, 0, 0);
          if (dwRet = BST_CHECKED) then
            pszText := FormatW(
              '%s (%s)',
              [SysIPAddress32_GetTextW(GetDlgItem(hWnd, IDC_EDIT_SYSIP_ADDRESS)),
              Edit_GetTextW(GetDlgItem(hWnd, IDC_EDIT_ROUTE_NAME))]
            )
          else
            pszText := FormatW(
              '%s mask %s (%s)',
              [SysIPAddress32_GetTextW(GetDlgItem(hWnd, IDC_EDIT_SYSIP_ADDRESS)),
              SysIPAddress32_GetTextW(GetDlgItem(hWnd, IDC_EDIT_SYSIP_NETMASK)),
              Edit_GetTextW(GetDlgItem(hWnd, IDC_EDIT_ROUTE_NAME))]
            );

          nItem := SendMessageW(GetDlgItem(GetParent(hWnd), IDC_MAIN_ROUTE_LIST),
            LB_ADDSTRING, 0, Integer(LPWSTR(pszText)));
          SendMessageW(GetDlgItem(GetParent(hWnd), IDC_MAIN_ROUTE_LIST),
            LB_EX_SETITEMSTATE, nItem, LST_CHECKED);

          PostMessageW(GetParent(hWnd), WM_COMMAND, MakeWParam(IDC_MAIN_ROUTE_LIST,
            LBN_SELCHANGE), GetDlgItem(GetParent(hWnd), IDC_MAIN_ROUTE_LIST));
            
          SendMessageW(hWnd, WM_CLOSE, 0, 0);

        end;

        //

        ID_CANCEL:
        begin

          SendMessageW(hWnd, WM_CLOSE, 0, 0);

        end;

      end;

    //

    EN_CHANGE:
    begin

      OnWmCommand_AddEdtDlgEnChange(hWnd);

    end;

  end;

  //

  Result := 0;

end;

//

function InstDlgProc_WmClose(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  //

  EndDialog(hWnd, 0);

  //

  Result := 0;
  
end;

//

function InstDlgProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): BOOL; stdcall;
begin

  case uMsg of

    //

    WM_INITDIALOG:
    begin
      Result := BOOL(InstDlgProc_WmInitDialog(hWnd, uMsg, wParam, lParam));
    end;

    //

    WM_COMMAND:
    begin
      Result := BOOL(InstDlgProc_WmCommand(hWnd, uMsg, wParam, lParam));
    end;

    //

    WM_CLOSE:
    begin
      Result := BOOL(InstDlgProc_WmClose(hWnd, uMsg, wParam, lParam));
    end;

  else
    Result := FALSE;
  end;

end;

end.