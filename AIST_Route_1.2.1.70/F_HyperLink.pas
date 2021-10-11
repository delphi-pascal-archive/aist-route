unit F_HyperLink;

{******************************************************************************}
{                                                                              }
{ Проект             : HyperLink Control                                       }
{ Последнее изменение: 07.07.2010                                              }
{ Авторские права    : © Мельников Максим Викторович, 2009-2010                }
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
  Windows, Messages, CommCtrl, F_Windows;

const
  //
  STM_EX_SETHOVERCLR  = WM_USER + 101; // установить цвет для наведенного состояния.
  STM_EX_SETNORMALCLR = WM_USER + 102; // установить цвет для обычного состояния.
  STM_EX_SETPRESSCLR  = WM_USER + 103; // установить цвет для нажатого состояния.
  STM_EX_SETBCKGNDCLR = WM_USER + 104; // установить цвет для фона текста.
  STM_EX_SETTIPTEXT   = WM_USER + 105; // установить текст всплывающей подсказки.
  //
  STM_EX_GETHOVERCLR  = WM_USER + 111; // получить цвет для наведенного состояния.
  STM_EX_GETNORMALCLR = WM_USER + 112; // получить цвет для обычного состояния.
  STM_EX_GETPRESSCLR  = WM_USER + 113; // получить цвет для нажатого состояния.
  STM_EX_GETBCKGNDCLR = WM_USER + 114; // получить цвет для фона текста.
  STM_EX_GETTIPTEXT   = WM_USER + 115; // получить текст всплывающей подсказки.

// создание элемента управления HyperLink.

procedure CreateHyperlinkStaticW(hWnd: HWND);

// удаление элемента управления HyperLink.

procedure RemoveHyperlinkStaticW(hWnd: HWND);

implementation

type
  TCtrlWndProc = function(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
  P_CTRL_PRO = ^T_CTRL_PRO;
  T_CTRL_PRO = packed record
    CtrlProc  : TCtrlWndProc;
    hCursor   : HCURSOR;
    hFont     : HFONT;
    rcClient  : TRect;
    //
    clrHover  : TColorRef;
    clrNormal : TColorRef;
    clrPress  : TColorRef;
    clrBckgnd : TColorRef; // CLR_NONE.
    pszText   : Array [0..MAX_PATH-1] of WideChar;
    //
    bHover    : Boolean;
    bPress    : Boolean;
    bEnabled  : Boolean;
    //
    hToolTip  : HWND;
    ti        : TToolInfoW;
    pszToolTip: Array [0..MAX_PATH-1] of WideChar;
    //
    dtStyle   : DWORD;
    //
    hdcMem    : HDC;
    hbmMem    : HBITMAP;
    hbmOld    : HBITMAP;
  end;

var
  pcp: P_CTRL_PRO;

//

function CtrlWndProc_StmExSetHoverClr(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  pcp.clrHover := TColorRef(wParam);
  RedrawWindow(hWnd, nil, 0, RDW_INVALIDATE or RDW_UPDATENOW or RDW_NOERASE);

  Result := 0;

end;

//

function CtrlWndProc_StmExGetHoverClr(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  Result := LRESULT(pcp.clrHover);

end;

//

function CtrlWndProc_StmExSetNormalClr(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  pcp.clrNormal := TColorRef(wParam);
  RedrawWindow(hWnd, nil, 0, RDW_INVALIDATE or RDW_UPDATENOW or RDW_NOERASE);

  Result := 0;

end;

//

function CtrlWndProc_StmExGetNormalClr(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  Result := LRESULT(pcp.clrNormal);

end;

//

function CtrlWndProc_StmExSetPressClr(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  pcp.clrPress := TColorRef(wParam);
  RedrawWindow(hWnd, nil, 0, RDW_INVALIDATE or RDW_UPDATENOW or RDW_NOERASE);

  Result := 0;

end;

//

function CtrlWndProc_StmExGetPressClr(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  Result := LRESULT(pcp.clrPress);

end;

//

function CtrlWndProc_StmExSetBckgdClr(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  pcp.clrBckgnd := TColorRef(wParam);
  RedrawWindow(hWnd, nil, 0, RDW_INVALIDATE or RDW_UPDATENOW or RDW_NOERASE);

  Result := 0;

end;

//

function CtrlWndProc_StmExGetBckgdClr(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  Result := LRESULT(pcp.clrBckgnd);

end;

//

function CtrlWndProc_StmExSetTipText(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  lstrcpynW(pcp.pszToolTip, LPWSTR(lParam), lParam);

  Result := 0;

end;

//

function CtrlWndProc_StmExGetTipText(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  lstrcpynW(LPWSTR(lParam), pcp.pszToolTip, lstrlenW(pcp.pszToolTip) + 1);

  Result := 0;

end;

//

function CtrlWndProc_WmSetFont(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  pcp.hFont := HFONT(wParam);

  Result := CallWindowProcW(@pcp.CtrlProc, hWnd, uMsg, wParam, lParam);

  RedrawWindow(hWnd, nil, 0, RDW_INVALIDATE or RDW_UPDATENOW or RDW_NOERASE);

end;

//

function CtrlWndProc_WmSetText(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  ZeroMemory(@pcp.pszText, SizeOf(pcp.pszText));
  lstrcpynW(pcp.pszText, LPWSTR(lParam), lParam);
  RedrawWindow(hWnd, nil, 0, RDW_INVALIDATE or RDW_UPDATENOW or RDW_NOERASE);

  Result := DefWindowProcW(hWnd, uMsg, wParam, lParam);

end;

//

function CtrlWndProc_WmEnable(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  pcp.bEnabled := BOOL(wParam);
  RedrawWindow(hWnd, nil, 0, RDW_INVALIDATE or RDW_UPDATENOW or RDW_NOERASE);

  Result := 0;

end;

//

function CtrlWndProc_WmMouseLeave(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  if (pcp.hToolTip <> 0) then
    SendMessageW(pcp.hToolTip, TTM_TRACKACTIVATE, Integer(FALSE), 0);

  pcp.bHover := FALSE;
  pcp.bPress := FALSE;

  RedrawWindow(hWnd, nil, 0, RDW_INVALIDATE or RDW_UPDATENOW or RDW_NOERASE);

  Result := 0;

end;

//

function CtrlWndProc_WmMouseMove(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  tme: Windows.TTrackMouseEvent;
  pt : TPoint;
begin

  GetCursorPos(pt);
  ScreenToClient(hWnd, pt);

  with tme do
  begin

    cbSize      := SizeOf(Windows.TTrackMouseEvent);
    dwFlags     := TME_LEAVE;
    hwndTrack   := hWnd;
    dwHoverTime := HOVER_DEFAULT;

  end;

  pcp.bHover := Windows.TrackMouseEvent(tme) and PtInRect(pcp.rcClient, pt);
  pcp.bPress := (GetCapture = hWnd) and PtInRect(pcp.rcClient, pt);
  RedrawWindow(hWnd, nil, 0, RDW_INVALIDATE or RDW_UPDATENOW or RDW_NOERASE);

  Result := 0;

end;

//

function CtrlWndProc_WmCaptureChanged(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  pcp.bPress := FALSE;

  Result := 0;

end;

//

function CtrlWndProc_WmNcHitTest(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  Result := HTCLIENT;

end;

//

function CtrlWndProc_WmlButtonDown(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  if (pcp.hToolTip <> 0) then
    SendMessageW(pcp.hToolTip, TTM_TRACKACTIVATE, Integer(FALSE), 0);
  pcp.bPress := TRUE;
  SetFocus(hWnd);
  SetCapture(hWnd);
  RedrawWindow(hWnd, nil, 0, RDW_INVALIDATE or RDW_UPDATENOW or RDW_NOERASE);

  Result := 0;

end;

//

function CtrlWndProc_WmlButtonUp(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  pt: TPoint;
begin

  GetCursorPos(pt);
  ScreenToClient(hWnd, pt);
  if (PtInRect(pcp.rcClient, pt) and (GetCapture = hWnd)) then
    SendMessageW(GetParent(hWnd), WM_COMMAND, MakeLong(GetDlgCtrlID(hWnd), STN_CLICKED), 0);

  ReleaseCapture;

  RedrawWindow(hWnd, nil, 0, RDW_INVALIDATE or RDW_UPDATENOW or RDW_NOERASE);

  Result := 0;

end;

//

function CtrlWndProc_WmSetCursor(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  if (pcp.hToolTip <> 0) then
    SendMessageW(pcp.hToolTip, TTM_TRACKACTIVATE, Integer(TRUE), Integer(@pcp.ti));

  if (pcp.hCursor <> 0) then
    SetCursor(pcp.hCursor);

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

  RedrawWindow(hWnd, nil, 0, RDW_INVALIDATE or RDW_UPDATENOW or RDW_NOERASE);

  Result := CallWindowProcW(@pcp.CtrlProc, hWnd, uMsg, wParam, lParam);

end;

//

function CtrlWndProc_WmPaint(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
var
  hdcIn : HDC;
  ps    : TPaintStruct;
  hbrNew: HBRUSH;
begin

  if (wParam = 0) then
    hdcIn := BeginPaint(hWnd, ps)
  else
    hdcIn := wParam;

  if (pcp.clrBckgnd = CLR_DEFAULT) then
    FillRect(pcp.hdcMem, pcp.rcClient, HBRUSH(COLOR_BTNFACE + 1))
  else
  begin

    hbrNew := CreateSolidBrush(pcp.clrBckgnd);
    FillRect(pcp.hdcMem, pcp.rcClient, hbrNew);
    DeleteObject(hbrNew);

  end;

  if pcp.bEnabled then
  begin

    if (pcp.bHover and pcp.bPress) then
      SetTextColor(pcp.hdcMem, pcp.clrPress)
    else
    if (pcp.bHover and not pcp.bPress) then
      SetTextColor(pcp.hdcMem, pcp.clrHover)
    else
      SetTextColor(pcp.hdcMem, pcp.clrNormal);

  end
  else
    SetTextColor(pcp.hdcMem, GetSysColor(COLOR_GRAYTEXT));

  SetBkMode(pcp.hdcMem, TRANSPARENT);
  SetBkColor(pcp.hdcMem, TRANSPARENT);

  SelectObject(pcp.hdcMem, pcp.hFont);

  DrawTextW(pcp.hdcMem, pcp.pszText, -1, pcp.rcClient, pcp.dtStyle);

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

  if (wParam = 0) then
    EndPaint(hWnd, ps);

  Result := 0;

end;

//

function CtrlWndProc_WmEraseBkgnd(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  if (pcp.clrBckgnd <> CLR_DEFAULT) then
  begin

    FillRect(HDC(wParam), pcp.rcClient, HBRUSH(COLOR_BTNFACE + 1));

    Result := 1;

  end
  else
    Result := DefWindowProcW(hWnd, uMsg, wParam, lParam);

end;

//

function CtrlWndProc_WmSysColorChange(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  RedrawWindow(hWnd, nil, 0, RDW_INVALIDATE or RDW_UPDATENOW or RDW_NOERASE);

  Result := 0;

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

    STM_EX_SETHOVERCLR:
    begin
      Result := CtrlWndProc_StmExSetHoverClr(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_GETHOVERCLR:
    begin
      Result := CtrlWndProc_StmExGetHoverClr(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_SETNORMALCLR:
    begin
      Result := CtrlWndProc_StmExSetNormalClr(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_GETNORMALCLR:
    begin
      Result := CtrlWndProc_StmExGetNormalClr(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_SETPRESSCLR:
    begin
      Result := CtrlWndProc_StmExSetPressClr(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_GETPRESSCLR:
    begin
      Result := CtrlWndProc_StmExGetPressClr(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_SETBCKGNDCLR:
    begin
      Result := CtrlWndProc_StmExSetBckgdClr(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_GETBCKGNDCLR:
    begin
      Result := CtrlWndProc_StmExGetBckgdClr(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_SETTIPTEXT:
    begin
      Result := CtrlWndProc_StmExSetTipText(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_GETTIPTEXT:
    begin
      Result := CtrlWndProc_StmExGetTipText(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_DESTROY:
    begin
      RemoveHyperlinkStaticW(hWnd);
    end;

    //

    WM_SETFONT:
    begin
      Result := CtrlWndProc_WmSetFont(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_SETTEXT:
    begin
      Result := CtrlWndProc_WmSetText(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_ENABLE:
    begin
      Result := CtrlWndProc_WmEnable(pcp, hWnd, uMsg, wParam, lParam);
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

    WM_CAPTURECHANGED:
    begin
      Result := CtrlWndProc_WmCaptureChanged(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_NCHITTEST:
    begin
      Result := CtrlWndProc_WmNcHitTest(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_LBUTTONDOWN:
    begin
      Result := CtrlWndProc_WmlButtonDown(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_LBUTTONUP:
    begin
      Result := CtrlWndProc_WmlButtonUp(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_SETCURSOR:
    begin
      Result := CtrlWndProc_WmSetCursor(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_SIZE:
    begin
      Result := CtrlWndProc_WmSize(pcp, hWnd, uMsg, wParam, lParam);
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

    WM_SYSCOLORCHANGE:
    begin
      Result := CtrlWndProc_WmSysColorChange(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_NOTIFY:
    begin
      Result := CtrlWndProc_WmNotify(pcp, hWnd, uMsg, wParam, lParam);
    end;

  else
    Result := CallWindowProcW(@pcp.CtrlProc, hWnd, uMsg, wParam, lParam);
  end;

end;

//

procedure CreateHyperlinkStaticW(hWnd: HWND);
var
  iccex  : TInitCommonControlsEx;
  dtStyle: DWORD;
  dwLen  : Integer;
begin

  iccex.dwSize := SizeOf(TInitCommonControlsEx);
  iccex.dwICC  := ICC_BAR_CLASSES;
  InitCommonControlsEx(iccex);

  RemoveHyperlinkStaticW(hWnd);

  pcp := P_CTRL_PRO(HeapAlloc(GetProcessHeap, HEAP_ZERO_MEMORY, SizeOf(T_CTRL_PRO)));

  ZeroMemory(pcp, SizeOf(pcp));
  pcp.CtrlProc   := TCtrlWndProc(Pointer(GetWindowLongW(hWnd, GWL_WNDPROC)));
  pcp.hCursor    := LoadImageW(0, MAKEINTRESOURCEW(IDC_HAND), IMAGE_CURSOR, 0, 0,
    LR_SHARED or LR_DEFAULTSIZE);

  pcp.hFont      := SendMessageW(hWnd, WM_GETFONT, 0, 0);

  GetClientRect(hWnd, pcp.rcClient);

  pcp.clrHover   := RGB(255, 0, 0);
  pcp.clrNormal  := RGB(0, 0, 255);
  pcp.clrPress   := RGB(0, 0, 128);
  pcp.clrBckgnd  := CLR_DEFAULT;

  dwLen := SendMessageW(hWnd, WM_GETTEXTLENGTH, 0, 0);
  if (dwLen > 0) then
  begin

    ZeroMemory(@pcp.pszText, SizeOf(pcp.pszText));
    SendMessageW(hWnd, WM_GETTEXT, SizeOf(pcp.pszText), Integer(@pcp.pszText));

  end;

  pcp.bHover   := FALSE;
  pcp.bPress   := FALSE;
  pcp.bEnabled := IsWindowEnabled(hWnd);

  pcp.hToolTip   := CreateWindowExW(WS_EX_TOPMOST, TOOLTIPS_CLASS, nil,
    WS_POPUP or TTS_NOPREFIX or TTS_ALWAYSTIP, Integer(CW_USEDEFAULT),
    Integer(CW_USEDEFAULT), Integer(CW_USEDEFAULT), Integer(CW_USEDEFAULT),
    GetParent(hWnd), 0, HInstance, nil);
  if (pcp.hToolTip <> 0) then
  begin

    pcp.ti.cbSize   := SizeOf(TToolInfoW);
    pcp.ti.uFlags   := TTF_SUBCLASS or TTF_IDISHWND;
    pcp.ti.hwnd     := hWnd;
    pcp.ti.uId      := hWnd;
    pcp.ti.lpszText := LPSTR_TEXTCALLBACKW;
    SetRectEmpty(pcp.ti.Rect);
    ZeroMemory(@pcp.pszToolTip, SizeOf(pcp.pszToolTip));
    SendMessageW(pcp.hToolTip, TTM_ADDTOOLW, 0, Integer(@pcp.ti));

  end;

  dtStyle := GetWindowLongW(hWnd, GWL_STYLE);

  case (dtStyle and SS_TYPEMASK) of
    SS_LEFT          : pcp.dtStyle := DT_LEFT or DT_EXPANDTABS {or DT_WORDBREAK};
    SS_CENTER        : pcp.dtStyle := DT_CENTER or DT_EXPANDTABS {or DT_WORDBREAK};
    SS_RIGHT         : pcp.dtStyle := DT_RIGHT or DT_EXPANDTABS {or DT_WORDBREAK};
    SS_SIMPLE        : pcp.dtStyle := DT_LEFT or DT_SINGLELINE;
    SS_LEFTNOWORDWRAP: pcp.dtStyle := DT_LEFT or DT_EXPANDTABS;
  end;
  if ((dtStyle and SS_CENTERIMAGE) = 0) then
    pcp.dtStyle := pcp.dtStyle or DT_VCENTER;
  if ((dtStyle and SS_NOTIFY) = 0) then
    SetWindowLongW(hWnd, GWL_STYLE, dtStyle or SS_NOTIFY);

  SetWindowLongW(hWnd, GWL_USERDATA, Longint(pcp));

  SetWindowLongW(hWnd, GWL_WNDPROC, Longint(@CtrlWndProc));

  SendMessageW(hWnd, WM_SIZE, 0, 0);

end;

//

procedure RemoveHyperlinkStaticW(hWnd: HWND);
begin

  pcp := P_CTRL_PRO(GetWindowLongW(hWnd, GWL_USERDATA));
  if (pcp <> nil) then
  begin

    if (pcp.hCursor <> 0) then
      DestroyCursor(pcp.hCursor);

    pcp.ti.hwnd := hWnd;
    pcp.ti.uId  := hWnd;
    if (pcp.hToolTip <> 0) then
    begin

      SendMessageW(pcp.hToolTip, TTM_DELTOOLW, 0, Integer(@pcp.ti));
      DestroyWindow(pcp.hToolTip);

    end;

    if (pcp.hdcMem <> 0) then
    begin

      SelectObject(pcp.hdcMem, pcp.hbmOld);
      DeleteObject(pcp.hbmMem);
      DeleteDC(pcp.hdcMem);

    end;

    SetWindowLongW(hWnd, GWL_WNDPROC, Longint(@pcp.CtrlProc));
    RedrawWindow(hWnd, @pcp.rcClient, 0, RDW_INVALIDATE or RDW_ERASE);

    SetWindowLongW(hWnd, GWL_USERDATA, 0);
    HeapFree(GetProcessHeap, 0, pcp);

  end;

end;

end.