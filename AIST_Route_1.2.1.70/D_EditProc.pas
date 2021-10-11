unit D_EditProc;

interface

uses
  Windows, Messages, CommCtrl, F_Windows, F_SysUtils, F_ListBoxEx, F_MyMsgBox,
  F_Resources, F_Controls, F_MiscUtils;

function EditDlgProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): BOOL; stdcall;

implementation

//

function EditDlgProc_WmInitDialog(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  nItem  : Integer;
  nText  : WideString;
  bResult: Boolean;
  pszText: WideString;
begin

  //

  SetCenterDialogPos(hWnd, GetParent(hWnd), TRUE);

  //

  SendMessageW(GetDlgItem(hWnd, IDC_EDIT_ROUTE_NAME), EM_LIMITTEXT, 255, 0);

  //

  nItem := SendMessageW(GetDlgItem(GetParent(hWnd), IDC_MAIN_ROUTE_LIST),
    LB_GETCURSEL, 0, 0);
  nText := ListBox_GetItemW(GetDlgItem(GetParent(hWnd), IDC_MAIN_ROUTE_LIST),
    nItem);
  bResult := IsMaskRouteReadStringW(nText);
  SetEnableWindowW(GetDlgItem(hWnd, IDC_EDIT_TEXT_NETMASK), bResult);
  SetEnableWindowW(GetDlgItem(hWnd, IDC_EDIT_SYSIP_NETMASK), bResult);

  if bResult then
  begin
    SendMessageW(GetDlgItem(hWnd, IDC_EDIT_WITH_MASK), BM_SETCHECK, BST_CHECKED,
      0);
    pszText := GetRouteMaskFromStringW(nText);
    SysIPAddress32_SetTextW(GetDlgItem(hWnd, IDC_EDIT_SYSIP_NETMASK), pszText);
  end
  else
    SendMessageW(GetDlgItem(hWnd, IDC_EDIT_WITHOUT_MASK), BM_SETCHECK,
      BST_CHECKED, 0);

  pszText := GetRouteAddressFromStringW(nText);
  SysIPAddress32_SetTextW(GetDlgItem(hWnd, IDC_EDIT_SYSIP_ADDRESS), pszText);
  pszText := GetRouteNameFromStringW(nText);
  SendMessageW(GetDlgItem(hWnd, IDC_EDIT_ROUTE_NAME), WM_SETTEXT, 0,
    Integer(LPWSTR(pszText)));

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

function EditDlgProc_WmCommand(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
const
  bCheck: Array [Boolean] of DWORD = (LST_UNCHECKED, LST_CHECKED);
var
  dwRet  : DWORD;
  pszText: WideString;
  nItem  : Integer;
  bResult: Boolean;
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

          // получаем индекс удаляемой строки.
          nItem := SendMessageW(GetDlgItem(GetParent(hWnd), IDC_MAIN_ROUTE_LIST),
            LB_GETCURSEL, 0, 0);
          // получаем данные об отмеченности пункта.
          dwRet := SendMessageW(GetDlgItem(GetParent(hWnd), IDC_MAIN_ROUTE_LIST),
            LB_EX_GETITEMSTATE, nItem, 0);
          bResult := dwRet = LST_CHECKED;
          // удаляем нужную строку по индексу.
          SendMessageW(GetDlgItem(GetParent(hWnd), IDC_MAIN_ROUTE_LIST), LB_DELETESTRING,
            nItem, 0);

          SendMessageW(GetDlgItem(GetParent(hWnd), IDC_MAIN_ROUTE_LIST),
            LB_INSERTSTRING, nItem, Integer(LPWSTR(pszText)));

          // выделим строку в списке перед установкой флажка. требуется для
          // перерисовки элемента, которое не возникает после LB_SETCURSEL.

          SendMessageW(GetDlgItem(GetParent(hWnd), IDC_MAIN_ROUTE_LIST),
            LB_SETCURSEL, nItem, 0);

          SendMessageW(GetDlgItem(GetParent(hWnd), IDC_MAIN_ROUTE_LIST),
            LB_EX_SETITEMSTATE, nItem, bCheck[bResult]);

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

function EditDlgProc_WmClose(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  //

  EndDialog(hWnd, 0);

  //

  Result := 0;
  
end;

//

function EditDlgProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): BOOL; stdcall;
begin

  case uMsg of

    //

    WM_INITDIALOG:
    begin
      Result := BOOL(EditDlgProc_WmInitDialog(hWnd, uMsg, wParam, lParam));
    end;

    //

    WM_COMMAND:
    begin
      Result := BOOL(EditDlgProc_WmCommand(hWnd, uMsg, wParam, lParam));
    end;

    //

    WM_CLOSE:
    begin
      Result := BOOL(EditDlgProc_WmClose(hWnd, uMsg, wParam, lParam));
    end;

  else
    Result := FALSE;
  end;

end;

end.