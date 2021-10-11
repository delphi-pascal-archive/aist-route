unit D_HookProc;

interface

uses
  Windows, Messages, F_CommDlg, F_SysUtils, F_Resources;

function HookDlgProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): UINT; stdcall;

implementation

//

function HookDlgProc_WmInitDialog(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;

  procedure SetDlgCtrlFontW(hChild, hParent: THandle);
  var
    hfnt: HFONT;
  begin
    hfnt := SendMessageW(hParent, WM_GETFONT, 0, 0);
    if (hfnt <> 0) then
      SendMessageW(hChild, WM_SETFONT, Integer(hfnt), Integer(TRUE));
  end;

  function EnumChildProcFont(hWnd: THandle; lParam: Integer): BOOL; stdcall;
  begin
    Result := TRUE;
    SetDlgCtrlFontW(hWnd, GetParent(GetParent(hWnd)));
  end;

var
  himi : HICON;

begin

  // отображаем значок в заголовке окна.

  himi := SendMessageW(GetParent(GetParent(hWnd)), WM_GETICON, ICON_SMALL, 0);
  if (himi <> 0) then
    SendMessageW(GetParent(hWnd), WM_SETICON, ICON_SMALL, himi);

  // перечисляем все диалоговые окна родительского окна и устанавливаем в них
  // наш шрифт. также установим шрифт и в наш диалоговый шаблон.

  EnumChildWindows(GetParent(hWnd), @EnumChildProcFont, 0);
  SetDlgCtrlFontW(GetDlgItem(hWnd, IDC_SAVE_RUN_BAT), GetParent(GetParent(hWnd)));

  //

  Result := 0;

end;

//

function HookDlgProc_WmCommand(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  dwRet: DWORD;
begin

  //

  case HiWord(wParam) of
    BN_CLICKED:
      case LoWord(wParam) of

        //

        IDC_SAVE_RUN_BAT:
        begin
          dwRet := SendMessageW(GetDlgItem(hWnd, IDC_SAVE_RUN_BAT), BM_GETCHECK,
            0, 0);
          SetExecute := dwRet = BST_CHECKED;
        end;

      end;

  end;

  //

  Result := 0;

end;

//

function HookDlgProc_WmNotify(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  pnmh: PNMHdr;
begin

  //

  pnmh := PNMHdr(lParam);
  case pnmh.code of
    CDN_INITDONE:

    begin

      // GetParent(hWnd) или GetWindowLongW(hWnd, GWL_HWNDPARENT).

      SetCenterDialogPos(GetParent(hWnd), 0, FALSE);

    end;

  end;

  //

  Result := 0;

end;

//

function HookDlgProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): UINT; stdcall;
begin

  case uMsg of

    //

    WM_INITDIALOG:
    begin
      Result := HookDlgProc_WmInitDialog(hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_COMMAND:
    begin
      Result := HookDlgProc_WmCommand(hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_NOTIFY:
    begin
      Result := HookDlgProc_WmNotify(hWnd, uMsg, wParam, lParam);
    end;

  else
    Result := 0;
  end;

end;

end.