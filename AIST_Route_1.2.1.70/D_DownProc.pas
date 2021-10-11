unit D_DownProc;

interface

uses
  Windows, Messages, CommCtrl, F_Windows, F_FileHttp, F_SysUtils, F_ListBoxEx,
  F_FramePaint, F_MyMsgBox, F_Resources, F_Controls, F_MiscUtils;

function DownDlgProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): BOOL; stdcall;

implementation

//

function DownDlgProc_WmInitDialog(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  himl    : HIMAGELIST;
  ThreadID: LongWord;

  procedure AddStringToCheckListBox(hWnd: THandle; pszMsg: WideString);
  const
    bCheck: Array [Boolean] of DWORD = (LST_UNCHECKED, LST_CHECKED);
  var
    bResult: Boolean;
    nItem  : Integer;
    pszText: WideString;
  begin

    bResult := IsCheckRouteReadStringW(pszMsg);
    pszText := GetListStringFromSourceW(pszMsg);

    nItem := SendMessageW(GetDlgItem(GetParent(hWnd), IDC_MAIN_ROUTE_LIST),
      LB_ADDSTRING, 0, Integer(LPWSTR(pszText)));
    SendMessageW(GetDlgItem(GetParent(hWnd), IDC_MAIN_ROUTE_LIST),
      LB_EX_SETITEMSTATE, nItem, bCheck[bResult]);

    PostMessageW(GetParent(hWnd), WM_COMMAND, MakeWParam(IDC_MAIN_ROUTE_LIST,
      LBN_SELCHANGE), GetDlgItem(GetParent(hWnd), IDC_MAIN_ROUTE_LIST));

  end;

  function ThreadCallback(LpParameter: Pointer): DWORD; stdcall;
  var
    hWnd   : THandle;
    pszText: WideString;
    pszFile: WideString;
    bResult : Boolean;
    i      : Integer;
  begin

    //

    Result := 0;

    // извлекаем дескриптор родительского окна из переданного агрумента.

    hWnd := THandle(LpParameter);

    //

    SetThreadPriority(hThread, THREAD_PRIORITY_BELOW_NORMAL);

    //

    pszText := LoadStrW(ID_SERVER_CONNECT);
    SendMessageW(GetDlgItem(hWnd, IDC_DOWN_LOADING), WM_SETTEXT, 0,
      Integer(LPWSTR(pszText)));

    pszFile := InternetDownloadTextFileW(pszServers[SetUpdate - 1, 0]);
    bResult := lstrlenW(LPWSTR(TrimW(pszFile))) > 0;

    Sleep(100);

    if bResult then
    begin

      pszText := LoadStrW(ID_ADD_ROUTES);
      SendMessageW(GetDlgItem(hWnd, IDC_DOWN_LOADING), WM_SETTEXT, 0,
        Integer(LPWSTR(pszText)));
      SendMessageW(GetDlgItem(GetParent(hWnd), IDC_MAIN_ROUTE_LIST),
        LB_RESETCONTENT, 0, 0);

      SendMessageW(GetDlgItem(GetParent(hWnd), IDC_MAIN_ROUTE_LIST), WM_SETREDRAW,
        Integer(FALSE), 0);

      pszFile := #10 + pszFile + #10;
      while (lstrlenW(LPWSTR(pszFile)) > 0) do
        begin
          i := Pos(#10, pszFile);
          if (i > 1) then
            begin

              pszText := Copy(pszFile, 1, i - 1);
              bResult := lstrlenW(LPWSTR(TrimW(pszText))) <> 0;
              if (IsNormParseStringW(pszText) and bResult) then
                AddStringToCheckListBox(hWnd, pszText);

              Sleep(5);

            end;
          Delete(pszFile, 1, i);
        end;

      SendMessageW(GetDlgItem(GetParent(hWnd), IDC_MAIN_ROUTE_LIST), WM_SETREDRAW,
        Integer(TRUE), 0);

    end;

    SetForegroundWindow(GetParent(hWnd));
    SetFocus(GetParent(hWnd));

    SendMessageW(hWnd, WM_DESTROY, 0, 0);

    if bResult then
    begin

      pszText := LoadStrW(ID_SUCCES_LOAD);
      MyMessageBoxW(
        GetParent(hWnd),
        MAKEINTRESOURCEW(pszText),
        MAKEINTRESOURCEW(ExeInfo.pszProductName),
        MB_OK or MB_ICONINFORMATION
      );

    end
    else
    begin

      pszText := LoadStrW(ID_ERROR_LOAD);
      MyMessageBoxW(
        GetParent(hWnd),
        MAKEINTRESOURCEW(pszText),
        MAKEINTRESOURCEW(ExeInfo.pszProductName),
        MB_OK or MB_ICONSTOP
      );

    end;

  end;

begin

  //

  SetCenterDialogPos(hWnd, GetParent(hWnd), TRUE);

  //

  CreateAnimationStaticW(GetDlgItem(hWnd, IDC_DOWN_SPRITES));
  himl := ImageList_LoadImageW(HInstance, MAKEINTRESOURCEW(RC_BITMAP_SPRITES),
    16, 0, CLR_DEFAULT, IMAGE_BITMAP, LR_LOADTRANSPARENT or LR_CREATEDIBSECTION);
  if (himl <> 0) then
  begin
    SendMessageW(GetDlgItem(hWnd, IDC_DOWN_SPRITES), STM_EX_SETIMAGELIST, himl,
      0);
    SendMessageW(GetDlgItem(hWnd, IDC_DOWN_SPRITES), STM_EX_ANIMATESTART, 0, 0);
  end;

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

function DownDlgProc_WmDestroy(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  himl: HIMAGELIST;
begin

  //

  himl := SendMessageW(GetDlgItem(hWnd, IDC_DOWN_SPRITES), STM_EX_GETIMAGELIST,
    0, 0);
  if (himl <> 0) then
    ImageList_Destroy(himl);
  RemoveAnimationStaticW(GetDlgItem(hWnd, IDC_DOWN_SPRITES));

  //

  EndDialog(hWnd, 0);

  //

  Result := 0;
  
end;

//

function DownDlgProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): BOOL; stdcall;
begin

  case uMsg of

    //

    WM_INITDIALOG:
    begin
      Result := BOOL(DownDlgProc_WmInitDialog(hWnd, uMsg, wParam, lParam));
    end;

    //

    WM_DESTROY:
    begin
      Result := BOOL(DownDlgProc_WmDestroy(hWnd, uMsg, wParam, lParam));
    end;

  else
    Result := FALSE;
  end;

end;

end.