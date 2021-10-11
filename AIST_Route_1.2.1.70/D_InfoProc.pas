unit D_InfoProc;

interface

uses
  Windows, Messages, CommCtrl, ShellApi, F_SysUtils, F_HyperLink, F_Resources;

function InfoDlgProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): BOOL; stdcall;

implementation

//

function InfoDlgProc_WmInitDialog(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  himi   : HICON;
  hfnt   : HFONT;
  pszText: WideString;
begin

  //

  himi := SendMessageW(GetParent(hWnd), WM_GETICON, ICON_SMALL, 0);
  if (himi <> 0) then
    SendMessageW(hWnd, WM_SETICON, ICON_SMALL, himi);

  hfnt := CreateFontW(GetWindowFontSizeW(hWnd, 8), 0, 0, 0, 800, 0, 0, 0,
    RUSSIAN_CHARSET, OUT_TT_PRECIS, CLIP_DEFAULT_PRECIS, PROOF_QUALITY,
    VARIABLE_PITCH or FF_DONTCARE, LPWSTR(fmtFontName));
  if (hfnt <> 0) then
    SendMessageW(GetDlgItem(hWnd, IDC_INFO_VERSION), WM_SETFONT, hfnt, 0);

  //

  SetCenterDialogPos(hWnd, GetParent(hWnd), TRUE);

  //

  himi := LoadImageW(HInstance, MAKEINTRESOURCEW(RC_ICON_MAIN), IMAGE_ICON, 32,
    32, 0);
  if (himi <> 0) then
    SendMessageW(GetDlgItem(hWnd, IDC_INFO_LOGO), STM_SETIMAGE, IMAGE_ICON, himi);

  //

  pszText := FormatW(LoadStrW(ID_APP_VERSION), [ExeInfo.pszProductName,
    ExeInfo.pszFileVersion]);
  SendMessageW(GetDlgItem(hWnd, IDC_INFO_VERSION), WM_SETTEXT, 0,
    Integer(LPWSTR(pszText)));
  pszText := ExeInfo.pszLegalCopyright;
  SendMessageW(GetDlgItem(hWnd, IDC_INFO_COPYRIGHTS), WM_SETTEXT, 0,
    Integer(LPWSTR(pszText)));

  //

  CreateHyperlinkStaticW(GetDlgItem(hWnd, IDC_INFO_URL));
  SendMessageW(GetDlgItem(hWnd, IDC_INFO_URL), STM_EX_SETTIPTEXT, 0,
    Integer(LPWSTR(fmtForum)));

  CreateHyperlinkStaticW(GetDlgItem(hWnd, IDC_INFO_MAIL));
  SendMessageW(GetDlgItem(hWnd, IDC_INFO_MAIL), STM_EX_SETTIPTEXT, 0,
    Integer(LPWSTR(fmtEmail)));

  //

  Result := 0;
  
end;

//

function InfoDlgProc_WmCommand(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  //

  case HiWord(wParam) of
    BN_CLICKED:
      case LoWord(wParam) of

        //

        IDC_INFO_URL:
        begin
          ShellExecuteW(hWnd, 'open', LPWSTR(fmtForum), nil, nil, SW_SHOWNORMAL);
        end;

        //

        IDC_INFO_MAIL:
        begin
          ShellExecuteW(hWnd, 'open', LPWSTR(fmtEmail), nil, nil, SW_SHOWNORMAL);
        end;

        //

        ID_OK,
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

function InfoDlgProc_WmClose(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  himi: HICON;
  hfnt: HFONT;
begin

  //

  himi := SendMessageW(GetDlgItem(hWnd, IDC_INFO_LOGO), STM_GETIMAGE, IMAGE_ICON,
    0);
  if (himi <> 0) then
    DestroyIcon(himi);

  //

  hfnt := SendMessageW(GetDlgItem(hWnd, IDC_INFO_VERSION), WM_GETFONT, 0, 0);
  if (hfnt <> 0) then
    DeleteObject(hfnt);

  //

  RemoveHyperlinkStaticW(GetDlgItem(hWnd, IDC_INFO_URL));
  RemoveHyperlinkStaticW(GetDlgItem(hWnd, IDC_INFO_MAIL));

  //

  EndDialog(hWnd, 0);

  //

  Result := 0;

end;

//

function InfoDlgProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): BOOL; stdcall;
begin

  case uMsg of

    //

    WM_INITDIALOG:
    begin
      Result := BOOL(InfoDlgProc_WmInitDialog(hWnd, uMsg, wParam, lParam));
    end;

    //

    WM_COMMAND:
    begin
      Result := BOOL(InfoDlgProc_WmCommand(hWnd, uMsg, wParam, lParam));
    end;

    //

    WM_CLOSE:
    begin
      Result := BOOL(InfoDlgProc_WmClose(hWnd, uMsg, wParam, lParam));
    end;

  else
    Result := FALSE;
  end;

end;

end.