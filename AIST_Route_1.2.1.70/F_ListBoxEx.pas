unit F_ListBoxEx;

{******************************************************************************}
{                                                                              }
{ Проект             : Extended Listbox                                        }
{ Последнее изменение: 13.07.2010                                              }
{ Авторские права    : © Мельников Максим Викторович, 2010                     }
{ Электронная почта  : maks1509@inbox.ru                                       }
{                                                                              }
{******************************************************************************}
{                                                                              }
{ Эта программа является свободным программным обеспечением. Вы можете         }
{ распространять и/или модифицировать её согласно условиям Стандартной         }
{ Общественной Лицензии GNU, опубликованной Фондом Свободного Программного     }
{ Обеспечения, версии 3 или, по Вашему желанию, любой более поздней версии.    }
{                                                                              }
{ Эта программа распространяется в надежде, что она будет полезной, но БЕЗ     }
{ ВСЯКИХ ГАРАНТИЙ, в том числе подразумеваемых гарантий ТОВАРНОГО СОСТОЯНИЯ    }
{ ПРИ ПРОДАЖЕ и ГОДНОСТИ ДЛЯ ОПРЕДЕЛЁННОГО ПРИМЕНЕНИЯ. Смотрите Стандартную    }
{ Общественную Лицензию GNU для получения дополнительной информации.           }
{                                                                              }
{ Вы должны были получить копию Стандартной Общественной Лицензии GNU          }
{ вместе с программой. В случае её отсутствия, посмотрите                      }
{ http://www.gnu.org/copyleft/gpl.html                                         }
{                                                                              }
{******************************************************************************}

interface

uses
  Windows, Messages, CommCtrl, F_Windows, F_UxThemes, F_SysUtils;

procedure CreateExtendedListboxW(hWnd: HWND);
procedure RemoveExtendedListboxW(hWnd: HWND);

const

  { extended listbox messages }

  LB_EX_GETITEMSTATE     = WM_USER + 101;
  LB_EX_SETITEMSTATE     = WM_USER + 102;

  LB_EX_GETCHECKCOUNT    = WM_USER + 103;

  LB_EX_GETEXTENDEDSTYLE = WM_USER + 104;
  LB_EX_SETEXTENDEDSTYLE = WM_USER + 105;

  LB_EX_BEGINLABELEDIT   = WM_USER + 106;
  LB_EX_ENDLABELEDIT     = WM_USER + 107;

  LB_EX_GETIMAGELIST     = WM_USER + 108;
  LB_EX_SETIMAGELIST     = WM_USER + 109;

  LB_EX_GETIMAGEINDEX    = WM_USER + 110;
  LB_EX_SETIMAGEINDEX    = WM_USER + 111;

  { extended listbox styles }

  LBS_EX_UNDERLINEHOT = $00000010;
  LBS_EX_INFOTIP      = $00000100;
  LBS_EX_CHECKBOXES   = $00001000;
  LBS_EX_IMAGELIST    = $00010000;

  { extended listbox states }

  LST_UNCHECKED = 0;
  LST_CHECKED   = 1;

implementation

type
  MAX_ITEMS = 0..32767;
  TItemData = packed record
    check: Integer;
    index: Integer;
  end;
  TCtrlWndProc = function(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
  TEditWndProc = function(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
  P_CTRL_PRO = ^T_CTRL_PRO;
  T_CTRL_PRO = packed record
    CtrlProc  : TCtrlWndProc;
    OldiHeight: Integer;
    NewiHeight: Integer;
    rcClient  : TRect;
    bEnabled  : Boolean;
    hFont     : HFONT;
    //
    hToolTip  : HWND;
    ti        : TToolInfoW;
    pszToolTip: Array [0..MAX_PATH-1] of WideChar;
    //
    hTimer    : DWORD;
    //
    bToolTip  : Boolean;
    dwOldItem : Integer;
    dwSelItem : Integer;
    //
    dwExStyle : DWORD;
    //
    hTheme    : HTHEME;
    IsManifest: Boolean;
    //
    hdcMem    : HDC;
    hbmMem    : HBITMAP;
    hbmOld    : HBITMAP;
    //
    EditProc  : TEditWndProc;
    hEdit     : HWND;
    dwEditItem: Integer;
    //
    himl      : HIMAGELIST;
    imgSize   : Integer;
    //
    ItemData  : Array [MAX_ITEMS] of TItemData;
  end;

const
  ThemeClassName: LPWSTR = 'Button';

var
  pcp: P_CTRL_PRO;

//

function EditWndProc_WmKillFocus(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  dwLen  : DWORD;
  pszText: WideString;
  dwRet  : DWORD;
begin

  dwRet := DWORD(LB_ERR);

  dwLen := SendMessageW(hWnd, WM_GETTEXTLENGTH, 0, 0);
  if (dwLen > 0) then
  begin

    SetLength(pszText, dwLen + 1);
    SendMessageW(hWnd, WM_GETTEXT, dwLen + 1, Integer(LPWSTR(pszText)));

  end
  else
    pszText := '';

  if ((pcp.dwExStyle and LBS_EX_CHECKBOXES) <> 0) then
    dwRet := SendMessageW(GetParent(hWnd), LB_EX_GETITEMSTATE, pcp.dwEditItem, 0);

  SendMessageW(GetParent(hWnd), LB_DELETESTRING, pcp.dwEditItem, 0);

  SendMessageW(GetParent(hWnd), LB_INSERTSTRING, pcp.dwEditItem,
    Integer(LPWSTR(pszText)));

  if ((pcp.dwExStyle and LBS_EX_CHECKBOXES) <> 0) then
    SendMessageW(GetParent(hWnd), LB_EX_SETITEMSTATE, pcp.dwEditItem, dwRet);

  SendMessageW(GetParent(hWnd), LB_SETCURSEL, pcp.dwEditItem, 0);

  SetWindowLongW(hWnd, GWL_WNDPROC, Longint(@pcp.EditProc));
  RedrawWindow(GetParent(hWnd), nil, 0, RDW_FRAME or RDW_INVALIDATE or
    RDW_UPDATENOW);

  DestroyWindow(hWnd);
  pcp.hEdit := 0;

  Result := 0;

end;

//

function EditWndProc_WmKeyUp(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  case LoWord(wParam) of

    VK_ESCAPE:
    begin

      SetWindowLongW(hWnd, GWL_WNDPROC, Longint(@pcp.EditProc));
      DestroyWindow(hWnd);
      pcp.hEdit := 0;

    end;

    VK_RETURN:
    begin

      SendMessageW(hWnd, WM_KILLFOCUS, 0, 0);

    end;

  end;

  Result := 0;

end;

//

function EditWndProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
begin

  pcp := P_CTRL_PRO(GetWindowLongW(GetParent(hWnd), GWL_USERDATA));

  if (pcp = nil) then
  begin
    Result := DefWindowProcW(hWnd, uMsg, wParam, lParam);
    Exit;
  end;

  case uMsg of

    //

    WM_KILLFOCUS:
    begin
      Result := EditWndProc_WmKillFocus(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_KEYUP:
    begin
      Result := EditWndProc_WmKeyUp(pcp, hWnd, uMsg, wParam, lParam);
    end;

  else
    Result := CallWindowProcW(@pcp.EditProc, hWnd, uMsg, wParam, lParam);
  end;

end;

//

function CtrlWndItem_WmPaint(pcp: P_CTRL_PRO; hWnd: hWnd; hdcIn: HDC; iRect: TRect; iItem: Integer): LRESULT;
const
  oldStyle: Array [Boolean] of DWORD = (
    DFCS_BUTTONCHECK or DFCS_FLAT,
    DFCS_BUTTONCHECK or DFCS_CHECKED or DFCS_FLAT
  );
  yesCheck: Array [Boolean] of DWORD = (CBS_CHECKEDNORMAL, CBS_CHECKEDHOT);
  notCheck: Array [Boolean] of DWORD = (CBS_UNCHECKEDNORMAL, CBS_UNCHECKEDHOT);
var
  rcItem : TRect;
  hbrNew : HBRUSH;
  pszText: WideString;
  dwRet  : DWORD;
  dwLen  : DWORD;
  hfnt   : HFONT;
  lf     : TLogFontW;
begin

  CopyRect(rcItem, iRect);

  dwLen := SendMessageW(hWnd, LB_GETTEXTLEN, iItem, 0);
  if (dwLen > 0) then
  begin

    SetLength(pszText, dwLen);
    SendMessageW(hWnd, LB_GETTEXT, iItem, Integer(LPWSTR(pszText)));

  end
  else
    pszText := '';

  dwLen := lstrlenW(LPWSTR(pszText));

  if pcp.bEnabled then
  begin

    if (SendMessageW(hWnd, LB_GETSEL, iItem, 0) > 0) then
    begin

      FillRect(hdcIn, rcItem, GetSysColorBrush(COLOR_HIGHLIGHT));
      SetBkMode(hdcIn, TRANSPARENT);
      SetBkColor(hdcIn, GetSysColor(COLOR_HIGHLIGHT));
      SetTextColor(hdcIn, GetSysColor(COLOR_HIGHLIGHTTEXT));

    end
    else
    begin

      FillRect(hdcIn, rcItem, GetSysColorBrush(COLOR_WINDOW));
      SetBkMode(hdcIn, TRANSPARENT);
      SetBkColor(hdcIn, GetSysColor(COLOR_WINDOW));
      SetTextColor(hdcIn, GetSysColor(COLOR_WINDOWTEXT));

      if (((iItem mod 2) <> 0) and (dwLen > 0)) then
      begin

        hbrNew := CreateSolidBrush(RGB(240, 240, 240));
        FillRect(hdcIn, rcItem, hbrNew);
        SetBkMode(hdcIn, TRANSPARENT);
        SetBkColor(hdcIn, RGB(240, 240, 240));
        DeleteObject(hbrNew);

      end;

    end;

  end
  else
  begin

    FillRect(hdcIn, rcItem, GetSysColorBrush(COLOR_WINDOW));
    SetBkMode(hdcIn, TRANSPARENT);
    SetBkColor(hdcIn, TRANSPARENT);
    SetTextColor(hdcIn, GetSysColor(COLOR_GRAYTEXT));

  end;

  if ((dwLen > 0) and ((pcp.dwExStyle and LBS_EX_CHECKBOXES) <> 0)) then
  begin

    dwRet := SendMessageW(hWnd, LB_EX_GETITEMSTATE, iItem, 0);

    SetRect(
      rcItem,
      iRect.Left + 3,
      iRect.Top + 2,
      iRect.Left + GetSystemMetrics(SM_CYMENUCHECK) + 3,
      iRect.Bottom - 2
    );

    if ((InitThemeLibrary and IsUseThemes) and pcp.IsManifest) then
    begin

      if (pcp.hTheme <> 0) then
      begin

        if (dwRet = LST_CHECKED) then
          DrawThemeBackground(pcp.hTheme, hdcIn, BP_CHECKBOX,
            yesCheck[iItem = pcp.dwSelItem], rcItem, nil)
        else
          DrawThemeBackground(pcp.hTheme, hdcIn, BP_CHECKBOX,
            notCheck[iItem = pcp.dwSelItem], rcItem, nil);

      end
      else
        DrawFrameControl(hdcIn, rcItem, DFC_BUTTON, oldStyle[dwRet = LST_CHECKED]);

    end
    else
      DrawFrameControl(hdcIn, rcItem, DFC_BUTTON, oldStyle[dwRet = LST_CHECKED]);

  end;

  SetRect(
    rcItem,
    iRect.Left + 5,
    iRect.Top,
    iRect.Right - 5,
    iRect.Bottom
  );

  if ((pcp.dwExStyle and LBS_EX_CHECKBOXES) <> 0) then
    Inc(rcItem.Left, GetSystemMetrics(SM_CYMENUCHECK) + 3);

  if ((pcp.dwExStyle and LBS_EX_UNDERLINEHOT) <> 0) then
  begin

    if (iItem = pcp.dwSelItem) then
    begin

      ZeroMemory(@lf, SizeOf(TLogFontW));
      if (pcp.hFont <> 0) then
      begin
        dwRet := GetObjectW(pcp.hFont, SizeOf(TLogFontW), @lf);
        if (dwRet <> 0) then
        begin
          lf.lfUnderline := 1;
          hfnt := CreateFontIndirectW(lf);
        end
        else
          hfnt := pcp.hFont;
      end
      else
        hfnt := pcp.hFont;

    end
    else
      hfnt := pcp.hFont;

  end
  else
    hfnt := pcp.hFont;

  if ((dwLen > 0) and ((pcp.dwExStyle and LBS_EX_IMAGELIST) <> 0) and
    (pcp.himl <> 0)) then
  begin

    ImageList_DrawEx(
      pcp.himl,
      pcp.ItemData[iItem].index,
      hdcIn,
      rcItem.Left,
      rcItem.Top + 1,
      pcp.imgSize,
      pcp.imgSize,
      CLR_DEFAULT,
      CLR_DEFAULT,
      ILD_NORMAL or ILD_TRANSPARENT
    );

    Inc(rcItem.Left, pcp.imgSize + 5);

  end;

  SelectObject(hdcIn, hfnt);

  DrawTextW(
    hdcIn,
    LPWSTR(pszText),
    -1,
    rcItem,
    DT_SINGLELINE or DT_LEFT or DT_VCENTER or DT_END_ELLIPSIS or DT_NOPREFIX
  );

  if ((pcp.dwExStyle and LBS_EX_UNDERLINEHOT) <> 0) then
  begin

    if ((hfnt <> 0) and (iItem = pcp.dwSelItem)) then
      DeleteObject(hfnt);

  end;

  Result := 0;

end;

//

function CtrlWndItem_HitTest(pcp: P_CTRL_PRO; hWnd: THandle; iRect: TRect; bCheck, bHiml: Boolean; pszText: WideString): Boolean;
var
  hdcIn  : HDC;
  dwFlags: DWORD;
  dwLen  : Integer;
  rcItem : TRect;
begin

  CopyRect(rcItem, iRect);

  hdcIn := GetDC(0);

  SelectObject(hdcIn, pcp.hFont);

  dwLen := rcItem.Right - rcItem.Left - 10;

  if bCheck then
    Dec(dwLen, GetSystemMetrics(SM_CYMENUCHECK) + 2);

  if bHiml then
    Dec(dwLen, pcp.imgSize + 5);

  dwFlags := DT_CALCRECT or DT_WORDBREAK or DT_NOPREFIX or DT_SINGLELINE or
    DT_LEFT or DT_VCENTER;
  DrawTextW(hdcIn, LPWSTR(pszText), -1, rcItem, dwFlags);

  ReleaseDC(0, hdcIn);

  Result := dwLen < (rcItem.Right - rcItem.Left);

end;

//

function CtrlWndItem_TextHitTest(hWnd: THandle; iRect: TRect; bCheck, bHiml: Boolean): Boolean;
var
  pt    : TPoint;
  rcItem: TRect;
begin

  GetCursorPos(pt);
  ScreenToClient(hWnd, pt);

  SetRect(rcItem, iRect.Left + 3, iRect.Top, iRect.Right - 3, iRect.Bottom );

  if bCheck then
    Inc(rcItem.Left, GetSystemMetrics(SM_CYMENUCHECK) + 2);

  if bHiml then
    Inc(rcItem.Left, pcp.imgSize + 5);

  Result := PtinRect(rcItem, pt);

end;


//

function CtrlWndProc_WmDestroy(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  RemoveExtendedListboxW(hWnd);

  Result := 0;

end;

//

function CtrlWndProc_WmSetFont(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  pcp.hFont := HFONT(wParam);

  Result := CallWindowProcW(@pcp.CtrlProc, hWnd, uMsg, wParam, lParam);

  RedrawWindow(hWnd, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_UPDATENOW);

end;

//

function CtrlWndProc_WmEnable(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  pcp.bEnabled := BOOL(wParam);
  RedrawWindow(hWnd, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_UPDATENOW);

  Result := 0;

end;

//

function CtrlWndProc_WmPaint(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  hdcIn : HDC;
  ps    : TPaintStruct;
  rcItem: TRect;
  iCount: Integer;
  iStart: Integer;
begin

  if (wParam = 0) then
    hdcIn := BeginPaint(hWnd, ps)
  else
    hdcIn := wParam;

  try

    if pcp.bEnabled then
      FillRect(pcp.hdcMem, pcp.rcClient, GetStockObject(WHITE_BRUSH))
    else
      FillRect(hdcIn, pcp.rcClient, GetSysColorBrush(COLOR_WINDOW));

    iCount := SendMessageW(hWnd, LB_GETCOUNT, 0, 0);

    if (iCount > 0) then
    begin

      SetRect(
        rcItem,
        pcp.rcClient.Left,
        pcp.rcClient.Top,
        pcp.rcClient.Right,
        pcp.NewiHeight
      );

      iStart := SendMessageW(hWnd, LB_GETTOPINDEX, 0, 0);

      while (rcItem.Bottom < (pcp.rcClient.Bottom + pcp.NewiHeight)) do
      begin

        CtrlWndItem_WmPaint(pcp, hWnd, pcp.hdcMem, rcItem, iStart);
        OffsetRect(rcItem, 0, pcp.NewiHeight);
        Inc(iStart);

      end;

    end;

    BitBlt(
      hdcIn,
      0,
      0,
      pcp.rcClient.Right - pcp.rcClient.Left,
      pcp.rcClient.Bottom - pcp.rcClient.Top,
      pcp.hdcMem,
      0,
      0,
      SRCCOPY
    );

  finally

    if (wParam = 0) then
      EndPaint(hWnd, ps);

  end;

  Result := 0;

end;

//

function CtrlWndProc_WmEraseBkgnd(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  if (pcp.hEdit = 0) then
  begin

    SendMessageW(hWnd, WM_SETREDRAW, Integer(FALSE), 0);
    RedrawWindow(hWnd, nil, 0, RDW_INVALIDATE or RDW_UPDATENOW or RDW_NOERASE);
    SendMessageW(hWnd, WM_SETREDRAW, Integer(TRUE), 0);

  end;

  Result := 1;

end;

//

function CtrlWndProc_WmThemeChanged(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  pcp.IsManifest := IsManifestAvailableW(AnsiStringToWide(ParamStr(0), CP_ACP));

  if (pcp.hTheme <> 0) then
  begin

    CloseThemeData(pcp.hTheme);
    pcp.hTheme := 0;

  end;

  if (InitThemeLibrary and IsUseThemes) then
    pcp.hTheme := OpenThemeData(hWnd, ThemeClassName);

  SetWindowPos(hWnd, 0, 0, 0, 0, 0, SWP_FRAMECHANGED or SWP_NOMOVE or
    SWP_NOSIZE or SWP_NOZORDER);
  RedrawWindow(hWnd, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_ERASE);

  Result := CallWindowProcW(@pcp.CtrlProc, hWnd, uMsg, wParam, lParam);

end;

//

function CtrlWndProc_WmlButtonUp(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  Result := CallWindowProcW(@pcp.CtrlProc, hWnd, uMsg, wParam, lParam);

  RedrawWindow(hWnd, nil, 0, RDW_INVALIDATE or RDW_UPDATENOW or RDW_NOERASE);

end;

//

function CtrlWndProc_WmScroll(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  if (pcp.hEdit <> 0) then
    SendMessageW(pcp.hEdit, WM_KILLFOCUS, 0, 0);
  SendMessageW(hWnd, WM_SETREDRAW, Integer(FALSE), 0);

  Result := CallWindowProcW(@pcp.CtrlProc, hWnd, uMsg, wParam, lParam);

  SendMessageW(hWnd, WM_SETREDRAW, Integer(TRUE), 0);
  RedrawWindow(hWnd, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_UPDATENOW);

end;

//

function CtrlWndProc_WmKeyDown(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  if (pcp.hEdit = 0) then
  begin

    SendMessageW(hWnd, WM_SETREDRAW, Integer(FALSE), 0);

    Result := CallWindowProcW(@pcp.CtrlProc, hWnd, uMsg, wParam, lParam);

    RedrawWindow(hWnd, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_UPDATENOW);
    SendMessageW(hWnd, WM_SETREDRAW, Integer(TRUE), 0);

  end
  else

    Result := 0;

end;

//

function CtrlWndProc_WmMouseLeave(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  if (IsWindowVisible(pcp.hToolTip) and ((pcp.dwExStyle and LBS_EX_INFOTIP) <> 0)) then
  begin

    pcp.bToolTip := FALSE;
    SendMessageW(pcp.hToolTip, TTM_TRACKACTIVATE, Integer(FALSE), 0);
    pcp.dwOldItem := LB_ERR;

  end;

  pcp.dwSelItem := LB_ERR;
  RedrawWindow(hWnd, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_ERASE);

  Result := 0;

end;

//

function CtrlWndProc_WmMouseMove(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  pt     : TPoint;
  iCount : Integer;
  pszText: WideString;
  rcItem : TRect;
  tme    : Windows.TTrackMouseEvent;
begin

  if (pcp.hEdit = 0) then
  begin

    SendMessageW(hWnd, WM_SETREDRAW, Integer(FALSE), 0);

    Result := CallWindowProcW(@pcp.CtrlProc, hWnd, uMsg, wParam, lParam);

    pcp.dwSelItem := SendMessageW(hWnd, LB_ITEMFROMPOINT, 0,
      MakeLParam(LoWord(lParam), HiWord(lParam)));
    RedrawWindow(hWnd, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_UPDATENOW);
    SendMessageW(hWnd, WM_SETREDRAW, Integer(TRUE), 0);

  end
  else

    Result := 0;

  with tme do
  begin

    cbSize      := SizeOf(Windows.TTrackMouseEvent);
    dwFlags     := TME_LEAVE;
    hwndTrack   := hWnd;
    dwHoverTime := HOVER_DEFAULT;

  end;

  if ((pcp.hToolTip <> 0) and ((pcp.dwExStyle and LBS_EX_INFOTIP) <> 0)) then
  begin

    iCount := SendMessageW(hWnd, LB_GETCOUNT, 0, 0);
    if (iCount > 0) then
    begin

      if (pcp.dwSelItem = LB_ERR) then
      begin

        pcp.bToolTip := FALSE;
        SendMessageW(pcp.hToolTip, TTM_TRACKACTIVATE, Integer(FALSE),
          Integer(@pcp.ti));
        Exit;

      end;

      if (pcp.dwSelItem = pcp.dwOldItem) then
        Exit;

      iCount := SendMessageW(hWnd, LB_GETTEXTLEN, pcp.dwSelItem, 0);
      if (iCount > 0) then
      begin

        SetLength(pszText, iCount + 1);
        SendMessageW(hWnd, LB_GETTEXT, pcp.dwSelItem, Integer(LPWSTR(pszText)));
        ZeroMemory(@pcp.pszToolTip, SizeOf(pcp.pszToolTip));
        lstrcpynW(pcp.pszToolTip, LPWSTR(pszText), lstrlenW(LPWSTR(pszText)) + 1);

      end;

      if pcp.bToolTip then
      begin

        SendMessageW(pcp.hToolTip, TTM_TRACKACTIVATE, Integer(FALSE),
          Integer(@pcp.ti));
        pcp.dwOldItem := LB_ERR;
        pcp.bToolTip := FALSE;

      end
      else
      begin

        SendMessageW(hWnd, LB_GETITEMRECT, pcp.dwSelItem, Integer(@rcItem));

        if not CtrlWndItem_TextHitTest(
          hWnd,
          rcItem,
          (pcp.dwExStyle and LBS_EX_CHECKBOXES) <> 0,
          (pcp.dwExStyle and LBS_EX_IMAGELIST) <> 0
        ) then
          Exit;

        if not CtrlWndItem_HitTest(
          pcp,
          hWnd,
          rcItem,
          (pcp.dwExStyle and LBS_EX_CHECKBOXES) <> 0,
          (pcp.dwExStyle and LBS_EX_IMAGELIST) <> 0,
          pszText
        ) then
        begin

          pcp.dwOldItem := LB_ERR;
          Exit;

        end;

        if ((not pcp.bToolTip) and (wParam <> MK_LBUTTON)) then
        begin

          pt.X := rcItem.Left;
          pt.Y := rcItem.Top;

          if ((pcp.dwExStyle and LBS_EX_CHECKBOXES) <> 0) then
            Inc(pt.X, GetSystemMetrics(SM_CYMENUCHECK) + 5);

          if ((pcp.dwExStyle and LBS_EX_IMAGELIST) <> 0) then
            Inc(pt.X, pcp.imgSize + 5);

          ClientToScreen(hWnd, pt);
          SendMessageW(pcp.hToolTip, TTM_TRACKPOSITION, 0, MakeLParam(pt.X, pt.Y));
          SendMessageW(pcp.hToolTip, TTM_TRACKACTIVATE, Integer(TRUE),
            Integer(@pcp.ti));
          pcp.dwOldItem := pcp.dwSelItem;
          pcp.bToolTip := TRUE;

        end;

      end;

    end;

  end;

end;

//

function CtrlWndProc_WmNotify(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  pnmh: PNMHdr;
  ptit: PToolTipTextW;
begin

  pnmh := PNMHdr(lParam);
  case pnmh.code of

    TTN_NEEDTEXTW:
    begin

      ptit := PToolTipTextW(lParam);
      ptit.lpszText := pcp.pszToolTip;

    end;

  end;

  Result := 0;

end;

//

function CtrlWndProc_WmlButtonDblClk(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  iItem  : Integer;
  iCount : Integer;
  pt     : TPoint;
  rcItem : TRect;
begin

  iCount := SendMessageW(hWnd, LB_GETCOUNT, 0, 0);
  if (iCount > 0) then
  begin

    iItem := SendMessageW(hWnd, LB_ITEMFROMPOINT, 0, MakeLParam(LoWord(lParam),
      HiWord(lParam)));

    if (iItem <> LB_ERR) then
    begin

      if ((pcp.dwExStyle and LBS_EX_CHECKBOXES) <> 0) then
      begin

        SendMessageW(hWnd, LB_GETITEMRECT, iItem, Integer(@rcItem));

        GetCursorPos(pt);
        ScreenToClient(hWnd, pt);

        Inc(rcItem.Left, 2);
        rcItem.Right := rcItem.Left + GetSystemMetrics(SM_CYMENUCHECK) + 3;

        if not PtInRect(rcItem, pt) then
          SendMessageW(GetParent(hWnd), WM_COMMAND, MakeWParam(GetDlgCtrlID(hWnd),
            LBN_DBLCLK), hWnd);

      end
      else

        SendMessageW(GetParent(hWnd), WM_COMMAND, MakeWParam(GetDlgCtrlID(hWnd),
          LBN_DBLCLK), hWnd);

    end;

  end;

  Result := 0;

end;

//

function CtrlWndProc_WmlButtonDown(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  iItem : Integer;
  iCount: Integer;
  pt    : TPoint;
  rcItem: TRect;
  dwRet : DWORD;
begin

  iCount := SendMessageW(hWnd, LB_GETCOUNT, 0, 0);
  if (iCount > 0) then
  begin

    iItem := SendMessageW(hWnd, LB_ITEMFROMPOINT, 0, MakeLParam(LoWord(lParam),
      HiWord(lParam)));

    if (iItem <> LB_ERR) then
    begin

      GetCursorPos(pt);

      if ((pcp.hToolTip <> 0) and ((pcp.dwExStyle and LBS_EX_INFOTIP) <> 0) and
        IsWindowVisible(pcp.hToolTip)) then
      begin

        pcp.bToolTip := FALSE;
        ShowWindow(pcp.hToolTip, SW_HIDE);
        if IsWindowVisible(pcp.hToolTip) then
          SendMessageW(pcp.hToolTip, TTM_TRACKACTIVATE, Integer(FALSE), 0);

      end;

      SendMessageW(hWnd, WM_SETREDRAW, Integer(FALSE), 0);
      SendMessageW(hWnd, LB_SETCURSEL, iItem, 0);

      ScreenToClient(hWnd, pt);
      SendMessageW(hWnd, LB_GETITEMRECT, iItem, Integer(@rcItem));

      Inc(rcItem.Left, 2);
      rcItem.Right := rcItem.Left + 14;
      if PtInRect(rcItem, pt) then
      begin

        dwRet := SendMessageW(hWnd, LB_EX_GETITEMSTATE, iItem, 0);
        if (dwRet = LST_CHECKED) then
          SendMessageW(hWnd, LB_EX_SETITEMSTATE, iItem, LST_UNCHECKED)
        else
          SendMessageW(hWnd, LB_EX_SETITEMSTATE, iItem, LST_CHECKED);

      end;

      SetFocus(hWnd);

      Result := CallWindowProcW(@pcp.CtrlProc, hWnd, uMsg, wParam, lParam);

      RedrawWindow(hWnd, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_UPDATENOW);
      SendMessageW(hWnd, WM_SETREDRAW, Integer(TRUE), 0);

      end

    else

      Result := 0;

  end

  else

    Result := 0;

end;

//

function CtrlWndProc_WmrButtonDown(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  iCount: Integer;
  iItem : Integer;
begin

  if (pcp.hEdit <> 0) then
    SendMessageW(pcp.hEdit, WM_KILLFOCUS, 0, 0);

  iCount := SendMessageW(hWnd, LB_GETCOUNT, 0, 0);
  if (iCount > 0) then
  begin

    iItem := SendMessageW(hWnd, LB_ITEMFROMPOINT, 0, MakeLParam(LoWord(lParam),
      HiWord(lParam)));

    if (iItem <> LB_ERR) then
    begin

      if ((pcp.hToolTip <> 0) and ((pcp.dwExStyle and LBS_EX_INFOTIP) <> 0) and
        IsWindowVisible(pcp.hToolTip)) then
      begin

          pcp.bToolTip := FALSE;
          ShowWindow(pcp.hToolTip, SW_HIDE);
          if IsWindowVisible(pcp.hToolTip) then
            SendMessageW(pcp.hToolTip, TTM_TRACKACTIVATE, Integer(FALSE), 0);

      end;

      SendMessageW(hWnd, LB_SETCURSEL, iItem, 0);
      RedrawWindow(hWnd, nil, 0, RDW_INVALIDATE or RDW_UPDATENOW or RDW_NOERASE);
      SetFocus(hWnd);

      SendMessageW(GetParent(hWnd), WM_COMMAND, MakeWParam(GetDlgCtrlID(hWnd),
        LBN_SELCHANGE), hWnd);

    end;

  end;

  Result := 0;

end;

//

function CtrlWndProc_WmrButtonUp(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  iItem : Integer;
  pt    : TPoint;
  rcItem: TRect;
begin

  iItem := SendMessageW(hWnd, LB_GETCURSEL, 0, 0);
  SendMessageW(hWnd, LB_GETITEMRECT, iItem, Integer(@rcItem));

  GetCursorPos(pt);
  ScreenToClient(hWnd, pt);

  Inc(rcItem.Left, 2);
  rcItem.Right := rcItem.Left + 14;

  if not PtInRect(rcItem, pt) then
  begin

    ClientToScreen(hWnd, pt);
    SendMessageW(GetParent(hWnd), WM_CONTEXTMENU, hWnd, MakeLParam(pt.X, pt.Y));

  end;

  Result := 0;

end;

//

function CtrlWndProc_WmSize(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  hdcIn: HDC;
begin

  GetClientRect(hWnd, pcp.rcClient);

  if (pcp.hdcMem <> 0) then
  begin
    SelectObject(pcp.hdcMem, pcp.hbmOld);
    DeleteObject(pcp.hbmMem);
    DeleteDC(pcp.hdcMem);
  end;

  hdcIn := GetDC(hWnd);
  pcp.hdcMem := CreateCompatibleDC(hdcIn);
  pcp.hbmMem := CreateCompatibleBitmap(
    hdcIn,
    pcp.rcClient.Right - pcp.rcClient.Left,
    pcp.rcClient.Bottom - pcp.rcClient.Top
  );
  pcp.hbmOld := SelectObject(pcp.hdcMem, pcp.hbmMem);
  ReleaseDC(hWnd, hdcIn);

  SendMessageW(hWnd, WM_SETREDRAW, Integer(FALSE), 0);

  Result := CallWindowProcW(@pcp.CtrlProc, hWnd, uMsg, wParam, lParam);

  SendMessageW(hWnd, WM_SETREDRAW, Integer(TRUE), 0);
  RedrawWindow(hWnd, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_UPDATENOW);

end;

//

function CtrlWndProc_WmTimer(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  pt    : TPoint;
  rcItem: TRect;
begin

  if ((pcp.hToolTip <> 0) and ((pcp.dwExStyle and LBS_EX_INFOTIP) <> 0) and
    IsWindowVisible(pcp.hToolTip)) then
  begin

    GetCursorPos(pt);
    GetWindowRect(hWnd, rcItem);

    if ((pcp.dwExStyle and LBS_EX_CHECKBOXES) <> 0) then
      Inc(rcItem.Left, GetSystemMetrics(SM_CYMENUCHECK) + 5);

    if ((pcp.dwExStyle and LBS_EX_IMAGELIST) <> 0) then
      Inc(rcItem.Left, pcp.imgSize + 5);

    if not PtInRect(rcItem, pt) then
    begin

      pcp.bToolTip := FALSE;
      SendMessageW(pcp.hToolTip, TTM_TRACKACTIVATE, Integer(FALSE), 0);
      pcp.dwOldItem := LB_ERR;

    end;

  end;

  Result := 0;

end;

//

function CtrlWndProc_WmKillFocus(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  pcp.dwSelItem := LB_ERR;
  SendMessageW(hWnd, WM_SETREDRAW, Integer(FALSE), 0);

  Result := CallWindowProcW(@pcp.CtrlProc, hWnd, uMsg, wParam, lParam);

  SendMessageW(hWnd, WM_SETREDRAW, Integer(TRUE), 0);
  RedrawWindow(hWnd, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_UPDATENOW);

end;

//

function CtrlWndProc_LbExGetItemState(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  if ((wParam <> LB_ERR) and ((pcp.dwExStyle and LBS_EX_CHECKBOXES) <> 0)) then

    Result := pcp.ItemData[wParam].check

  else

    Result := LB_ERR;

end;

//

function CtrlWndProc_LbExSetItemState(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  rcItem: TRect;
begin

  if ((wParam <> LB_ERR) and ((pcp.dwExStyle and LBS_EX_CHECKBOXES) <> 0)) then
  begin

    pcp.ItemData[wParam].check := lParam;
    SendMessageW(hWnd, LB_GETITEMRECT, wParam, Integer(@rcItem));
    Inc(rcItem.Left, 2);
    rcItem.Right := rcItem.Left + 14;
    RedrawWindow(hWnd, @rcItem, 0, RDW_INVALIDATE or RDW_UPDATENOW or RDW_ERASE);

  end;

  Result := 0;

end;

//

function CtrlWndProc_LbExGetCheckCount(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  iCount: Integer;
  iItem : Integer;
  dwRet : Integer;
begin

  Result := 0;

  iCount := SendMessageW(hWnd, LB_GETCOUNT, 0, 0);
  if (iCount > 0) then
  begin

    for iItem := 0 to iCount -1 do
    begin

      dwRet := SendMessageW(hWnd, LB_EX_GETITEMSTATE, iItem, 0);
      if (dwRet = LST_CHECKED) then
        Inc(Result);

    end;

  end;

end;

//

function CtrlWndProc_LbExGetExtendedStyle(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  Result := LRESULT(pcp.dwExStyle);

end;

//

function CtrlWndProc_LbExSetExtendedStyle(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  pcp.dwExStyle := lParam;
  RedrawWindow(hWnd, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_ERASE);

  Result := 0;

end;

//

function CtrlWndProc_LbExBeginLabelEdit(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
const
  pszClassName: LPWSTR = 'EDIT';
var
  rcItem : TRect;
  dwLen  : DWORD;
  pszText: WideString;
begin

  pcp.dwEditItem := SendMessageW(hWnd, LB_GETCURSEL, 0, 0);

  if (pcp.dwEditItem <> LB_ERR) then
  begin

    SendMessageW(hWnd, LB_GETITEMRECT, pcp.dwEditItem, Integer(@rcItem));

    if ((pcp.dwExStyle and LBS_EX_CHECKBOXES) <> 0) then
      Inc(rcItem.Left, GetSystemMetrics(SM_CYMENUCHECK) + 5);

    if ((pcp.dwExStyle and LBS_EX_IMAGELIST) <> 0) then
      Inc(rcItem.Left, pcp.imgSize + 5);

    pcp.hEdit := CreateWindowExW(
      WS_EX_CLIENTEDGE,
      pszClassName,
      nil,
      ES_LEFT or ES_AUTOHSCROLL or WS_CHILD or WS_VISIBLE or WS_TABSTOP,
      rcItem.Left,
      rcItem.Top,
      rcItem.Right - rcItem.Left,
      rcItem.Bottom - rcItem.Top,
      hWnd,
      DWORD(-1),
      HInstance,
      nil
    );

    if (pcp.hEdit <> 0) then
    begin

      SetWindowPos(
        pcp.hEdit,
        HWND_TOP,
        0,
        0,
        0,
        0,
        SWP_NOACTIVATE or SWP_NOSIZE or SWP_NOMOVE or SWP_NOZORDER
      );

      dwLen := SendMessageW(hWnd, LB_GETTEXTLEN, pcp.dwEditItem, 0);
      if (dwLen > 0) then
      begin

        SetLength(pszText, dwLen);
        SendMessageW(hWnd, LB_GETTEXT, pcp.dwEditItem, Integer(LPWSTR(pszText)));

      end
      else
        pszText := '';

      SendMessageW(pcp.hEdit, WM_SETTEXT, 0, Integer(LPWSTR(pszText)));

      if (dwLen > 0) then
      begin

        SendMessageW(pcp.hEdit, EM_SETSEL, 0, dwLen);
        SendMessageW(pcp.hEdit, EM_SCROLLCARET, 0, 0);

      end;

      if (pcp.hFont <> 0) then
        SendMessageW(pcp.hEdit, WM_SETFONT, Integer(pcp.hFont), Integer(TRUE));

      SetActiveWindow(pcp.hEdit);
      SetFocus(pcp.hEdit);

      pcp.EditProc := TEditWndProc(Pointer(GetWindowLongW(pcp.hEdit,
        GWL_WNDPROC)));
      SetWindowLongW(pcp.hEdit, GWL_WNDPROC, Longint(@EditWndProc));

    end;

  end;

  Result := 0;

end;

//

function CtrlWndProc_LbExEndLabelEdit(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  if (pcp.hEdit <> 0) then
    SendMessageW(pcp.hEdit, WM_KILLFOCUS, 0, 0);

  Result := 0;

end;

//

function CtrlWndProc_LbExGetImageList(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  Result := LRESULT(pcp.himl);

end;

//

function CtrlWndProc_LbExSetImageList(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  pcp.himl := HIMAGELIST(wParam);
  if (pcp.himl <> 0) then
    ImageList_GetIconSize(pcp.himl, pcp.imgSize, pcp.imgSize);

  Result := 0;

end;

//

function CtrlWndProc_LbExGetImageIndex(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  if ((wParam <> LB_ERR) and ((pcp.dwExStyle and LBS_EX_IMAGELIST) <> 0) and
    (pcp.himl <> 0)) then

      Result := pcp.ItemData[wParam].index + 1

  else

    Result := LB_ERR;

end;

//

function CtrlWndProc_LbExSetImageIndex(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  rcItem: TRect;
begin

  if ((wParam <> LB_ERR) and ((pcp.dwExStyle and LBS_EX_IMAGELIST) <> 0) and
    (pcp.himl <> 0) and (lParam > 0)) then
  begin
    pcp.ItemData[wParam].index := lParam - 1;
    SendMessageW(hWnd, LB_GETITEMRECT, wParam, Integer(@rcItem));
    RedrawWindow(hWnd, @rcItem, 0, RDW_INVALIDATE or RDW_UPDATENOW or RDW_ERASE);
  end;

  Result := 0;

end;

//

function CtrlWndProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
begin

  pcp := P_CTRL_PRO(GetWindowLongW(hWnd, GWL_USERDATA));

  if (pcp = nil) then
  begin
    Result := DefWindowProcW(hWnd, uMsg, wParam, lParam);
    Exit;
  end;

  case uMsg of

    //

    WM_DESTROY:
    begin
      Result := CtrlWndProc_WmDestroy(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_SETFONT:
    begin
      Result := CtrlWndProc_WmSetFont(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_ENABLE:
    begin
      Result := CtrlWndProc_WmEnable(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_PRINTCLIENT,
    WM_PAINT,
    WM_UPDATEUISTATE:
    begin
      Result := CtrlWndProc_WmPaint(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_ERASEBKGND:
    begin
      Result := CtrlWndProc_WmEraseBkgnd(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_THEMECHANGED,
    WM_SYSCOLORCHANGE:
    begin
      Result := CtrlWndProc_WmThemeChanged(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_SIZE:
    begin
      Result := CtrlWndProc_WmSize(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_LBUTTONUP:
    begin
      Result := CtrlWndProc_WmlButtonUp(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_MOUSEWHEEL,
    WM_VSCROLL,
    WM_HSCROLL:
    begin
      Result := CtrlWndProc_WmScroll(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_KEYDOWN:
    begin
      Result := CtrlWndProc_WmKeyDown(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_MOUSELEAVE:
    begin
      Result := CtrlWndProc_WmMouseLeave(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_MOUSEMOVE:
    begin
      Result := CtrlWndProc_WmMouseMove(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_NOTIFY:
    begin
      Result := CtrlWndProc_WmNotify(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_LBUTTONDBLCLK:
    begin
      Result := CtrlWndProc_WmlButtonDblClk(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_LBUTTONDOWN:
    begin
      Result := CtrlWndProc_WmlButtonDown(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_RBUTTONDOWN:
    begin
      Result := CtrlWndProc_WmrButtonDown(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_RBUTTONUP:
    begin
      Result := CtrlWndProc_WmrButtonUp(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_TIMER:
    begin
      Result := CtrlWndProc_WmTimer(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_KILLFOCUS:
    begin
      Result := CtrlWndProc_WmKillFocus(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    LB_EX_GETITEMSTATE:
    begin
      Result := CtrlWndProc_LbExGetItemState(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    LB_EX_SETITEMSTATE:
    begin
      Result := CtrlWndProc_LbExSetItemState(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    LB_EX_GETCHECKCOUNT:
    begin
      Result := CtrlWndProc_LbExGetCheckCount(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    LB_EX_GETEXTENDEDSTYLE:
    begin
      Result := CtrlWndProc_LbExGetExtendedStyle(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    LB_EX_SETEXTENDEDSTYLE:
    begin
      Result := CtrlWndProc_LbExSetExtendedStyle(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    LB_EX_BEGINLABELEDIT:
    begin
      Result := CtrlWndProc_LbExBeginLabelEdit(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    LB_EX_ENDLABELEDIT:
    begin
      Result := CtrlWndProc_LbExEndLabelEdit(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    LB_EX_GETIMAGELIST:
    begin
      Result := CtrlWndProc_LbExGetImageList(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    LB_EX_SETIMAGELIST:
    begin
      Result := CtrlWndProc_LbExSetImageList(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    LB_EX_GETIMAGEINDEX:
    begin
      Result := CtrlWndProc_LbExGetImageIndex(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    LB_EX_SETIMAGEINDEX:
    begin
      Result := CtrlWndProc_LbExSetImageIndex(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

  else
    Result := CallWindowProcW(@pcp.CtrlProc, hWnd, uMsg, wParam, lParam);
  end;

end;

//

procedure CreateExtendedListboxW(hWnd: HWND);
var
  iccex: TInitCommonControlsEx;
begin

  iccex.dwSize := SizeOf(TInitCommonControlsEx);
  iccex.dwICC  := ICC_BAR_CLASSES;
  InitCommonControlsEx(iccex);

  RemoveExtendedListboxW(hWnd);

  pcp := P_CTRL_PRO(HeapAlloc(GetProcessHeap, HEAP_ZERO_MEMORY, SizeOf(T_CTRL_PRO)));
  ZeroMemory(pcp, SizeOf(T_CTRL_PRO));

  pcp.CtrlProc := TCtrlWndProc(Pointer(GetWindowLongW(hWnd, GWL_WNDPROC)));
  pcp.OldiHeight := SendMessageW(hWnd, LB_GETITEMHEIGHT, 0, 0);
  pcp.NewiHeight := 18;
  SendMessageW(hWnd, LB_SETITEMHEIGHT, 0, pcp.NewiHeight);

  pcp.bEnabled := IsWindowEnabled(hWnd);
  pcp.hFont := SendMessageW(hWnd, WM_GETFONT, 0, 0);

  pcp.hToolTip := CreateWindowExW(WS_EX_TOOLWINDOW or WS_EX_TOPMOST,
    TOOLTIPS_CLASS, nil, CW_USEDEFAULT, Integer(CW_USEDEFAULT),
    Integer(CW_USEDEFAULT), Integer(CW_USEDEFAULT), Integer(CW_USEDEFAULT),
    GetParent(hWnd), 0, HInstance, nil);
  if (pcp.hToolTip <> 0) then
  begin

    pcp.ti.cbSize   := SizeOf(TToolInfoW);
    pcp.ti.uFlags   := TTF_IDISHWND or TTF_TRACK or TTF_ABSOLUTE or TTF_TRANSPARENT;
    pcp.ti.hwnd     := hWnd;
    pcp.ti.uId      := hWnd;
    pcp.ti.Rect     := pcp.rcClient;
    pcp.ti.lpszText := LPSTR_TEXTCALLBACKW;
    SendMessageW(pcp.hToolTip, TTM_ADDTOOLW, 0, Integer(@pcp.ti));
    SetWindowPos(pcp.hToolTip, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or
      SWP_NOSIZE or SWP_NOACTIVATE);

    pcp.hTimer := SetTimer(hWnd, 0, 250, nil);

  end;

  pcp.bToolTip  := FALSE;
  pcp.dwOldItem := LB_ERR;

  pcp.dwSelItem := LB_ERR;
  pcp.dwExStyle := $00000000;

  pcp.IsManifest := IsManifestAvailableW(AnsiStringToWide(ParamStr(0), CP_ACP));
  if (InitThemeLibrary and IsUseThemes) then
    pcp.hTheme := OpenThemeData(hWnd, ThemeClassName)
  else
    pcp.hTheme := 0;

  pcp.EditProc := nil;
  pcp.hEdit := 0;
  pcp.dwEditItem := LB_ERR;

  pcp.himl := 0;
  pcp.imgSize := 0;

  FillChar(pcp.ItemData, SizeOf(pcp.ItemData), -1);

  SetWindowLongW(hWnd, GWL_USERDATA, Longint(pcp));
  SetWindowLongW(hWnd, GWL_WNDPROC, Longint(@CtrlWndProc));

  SendMessageW(hWnd, WM_SIZE, 0, 0);

end;

//

procedure RemoveExtendedListboxW(hWnd: HWND);
begin

  pcp := P_CTRL_PRO(GetWindowLongW(hWnd, GWL_USERDATA));
  if (pcp <> nil) then
  begin

    SendMessageW(hWnd, LB_SETITEMHEIGHT, 0, pcp.OldiHeight);

    if (InitThemeLibrary and IsUseThemes) then
    begin

      if (pcp.hTheme <> 0) then
      begin

        CloseThemeData(pcp.hTheme);
        pcp.hTheme := 0;

      end;

    end;

    pcp.ti.hwnd := hWnd;
    pcp.ti.uId  := hWnd;
    if (pcp.hToolTip <> 0) then
    begin

      SendMessageW(pcp.hToolTip, TTM_DELTOOLW, 0, Integer(@pcp.ti));
      DestroyWindow(pcp.hToolTip);

    end;

    if (pcp.hTimer <> 0) then
      KillTimer(hWnd, pcp.hTimer);

    if (pcp.hdcMem <> 0) then
    begin

      SelectObject(pcp.hdcMem, pcp.hbmOld);
      DeleteObject(pcp.hbmMem);
      DeleteDC(pcp.hdcMem);

    end;

    SetWindowLongW(hWnd, GWL_WNDPROC, Longint(@pcp.CtrlProc));
    RedrawWindow(hWnd, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_ERASE);

    SetWindowLongW(hWnd, GWL_USERDATA, 0);
    HeapFree(GetProcessHeap, 0, pcp);

  end;

end;

end.