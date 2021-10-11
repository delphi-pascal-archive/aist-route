unit F_FramePaint;

{******************************************************************************}
{                                                                              }
{ Проект             : Frame Animation Control                                 }
{ Последнее изменение: 01.07.2010                                              }
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
  Windows, Messages, CommCtrl, F_Windows;

procedure CreateAnimationStaticW(hWnd: HWND);
procedure RemoveAnimationStaticW(hWnd: HWND);

const

  { extended static messages }

  STM_EX_SETIMAGELIST    = WM_USER + 101; { wParam = ImageList; lParam = 0 }
  STM_EX_GETIMAGELIST    = WM_USER + 102; { lResult = ImageList }

  STM_EX_SETELAPSEDTIME  = WM_USER + 103; { wParam = Elapse; lParam = 0 }
  STM_EX_GETELAPSEDTIME  = WM_USER + 104; { lResult = Elapse }

  STM_EX_ANIMATESTART    = WM_USER + 105; { wParam = Elapse; lParam = 0 }
  STM_EX_ANIMATESTOP     = WM_USER + 106; { wParam = 0; lParam = 0 }

  STM_EX_SETCURRENTFRAME = WM_USER + 107; { wParam = Frame; lParam = 0 }
  STM_EX_GETCURRENTFRAME = WM_USER + 108; { lResult = Frame }

implementation

const
  IDC_ANIMATETIMER = 101;

type
  TCtrlWndProc = function(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
  P_CTRL_PRO = ^T_CTRL_PRO;
  T_CTRL_PRO = packed record
    CtrlProc  : TCtrlWndProc;
    rcClient  : TRect;
    //
    hdcMem    : HDC;
    hbmMem    : HBITMAP;
    hbmOld    : HBITMAP;
    //
    himl      : HIMAGELIST;
    //
    imgSize   : Integer;
    imgCount  : Integer;
    imgCurrent: Integer;
    //
    dwElapse  : Integer;
  end;

var
  pcp: P_CTRL_PRO;

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

  Result := CallWindowProcW(@pcp.CtrlProc, hWnd, uMsg, wParam, lParam);

  RedrawWindow(hWnd, nil, 0, RDW_INVALIDATE or RDW_UPDATENOW or RDW_NOERASE);

end;

//

function CtrlWndProc_WmPaint(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;

var
  hdcIn: HDC;
  ps   : TPaintStruct;
begin

  if (wParam = 0) then
    hdcIn := BeginPaint(hWnd, ps)
  else
    hdcIn := wParam;

  CallWindowProcW(@pcp.CtrlProc, hWnd, WM_PRINTCLIENT, pcp.hdcMem, PRF_CLIENT);

  if (pcp.himl <> 0) then
    ImageList_DrawEx(
      pcp.himl,
      pcp.imgCurrent - 1,
      pcp.hdcMem,
      pcp.rcClient.Left + ((pcp.rcClient.Right - pcp.rcClient.Left) div 2) - (pcp.imgSize div 2),
      pcp.rcClient.Top + ((pcp.rcClient.Bottom - pcp.rcClient.Top) div 2) - (pcp.imgSize div 2),
      pcp.imgSize,
      pcp.imgSize,
      CLR_DEFAULT,
      CLR_DEFAULT,
      ILD_NORMAL or ILD_TRANSPARENT
    );

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

function CtrlWndProc_WmTimer(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  Inc(pcp.imgCurrent);
  if (pcp.imgCurrent > pcp.imgCount) then
    pcp.imgCurrent := 1;

  RedrawWindow(hWnd, nil, 0, RDW_INVALIDATE or RDW_UPDATENOW or RDW_NOERASE);

  Result := 0;

end;

//

function CtrlWndProc_WmEraseBkgnd(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  Result := 1;

end;

//

function CtrlWndProc_StmExSetImageList(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  pcp.himl := HIMAGELIST(wParam);

  if (pcp.himl <> 0) then
  begin

    ImageList_GetIconSize(pcp.himl, pcp.imgSize, pcp.imgSize);
    pcp.imgCount := ImageList_GetImageCount(pcp.himl);
    pcp.imgCurrent := 1;

  end;

  Result := 0;

end;

//

function CtrlWndProc_StmExGetImageList(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  Result := LRESULT(pcp.himl);

end;

//

function CtrlWndProc_StmExSetElapsedTime(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  pcp.dwElapse := wParam;

  Result := 0;

end;

//

function CtrlWndProc_StmExGetElapsedTime(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  Result := LRESULT(pcp.dwElapse);

end;

//

function CtrlWndProc_StmExAnimateStart(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  SetTimer(hWnd, IDC_ANIMATETIMER, pcp.dwElapse, nil);

  Result := 0;

end;

//

function CtrlWndProc_StmExAnimateStop(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  KillTimer(hWnd, IDC_ANIMATETIMER);

  Result := 0;

end;

//

function CtrlWndProc_StmExSetCurrentFrame(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  if (wParam > 0) then
  begin

    pcp.imgCurrent := wParam;
    RedrawWindow(hWnd, nil, 0, RDW_INVALIDATE or RDW_UPDATENOW or RDW_NOERASE);

  end;

  Result := 0;

end;

//

function CtrlWndProc_StmExGetCurrentFrame(pcp: P_CTRL_PRO; hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin

  Result := LRESULT(pcp.imgCurrent);

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
      RemoveAnimationStaticW(hWnd);
    end;

    //

    WM_SIZE:
    begin
      Result := CtrlWndProc_WmSize(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_PRINTCLIENT,
    WM_PAINT,
    WM_UPDATEUISTATE: // перерисовка окна без вызова WM_PAINT.
    begin
      Result := CtrlWndProc_WmPaint(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_TIMER:
    begin
      Result := CtrlWndProc_WmTimer(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    WM_ERASEBKGND:
    begin
      Result := CtrlWndProc_WmEraseBkgnd(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_SETIMAGELIST:
    begin
      Result := CtrlWndProc_StmExSetImageList(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_GETIMAGELIST:
    begin
      Result := CtrlWndProc_StmExGetImageList(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_SETELAPSEDTIME:
    begin
      Result := CtrlWndProc_StmExSetElapsedTime(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_GETELAPSEDTIME:
    begin
      Result := CtrlWndProc_StmExGetElapsedTime(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_ANIMATESTART:
    begin
      Result := CtrlWndProc_StmExAnimateStart(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_ANIMATESTOP:
    begin
      Result := CtrlWndProc_StmExAnimateStop(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_SETCURRENTFRAME:
    begin
      Result := CtrlWndProc_StmExSetCurrentFrame(pcp, hWnd, uMsg, wParam, lParam);
    end;

    //

    STM_EX_GETCURRENTFRAME:
    begin
      Result := CtrlWndProc_StmExGetCurrentFrame(pcp, hWnd, uMsg, wParam, lParam);
    end;

  else
    Result := CallWindowProcW(@pcp.CtrlProc, hWnd, uMsg, wParam, lParam);
  end;

end;

//

procedure CreateAnimationStaticW(hWnd: HWND);
begin

  RemoveAnimationStaticW(hWnd);

  pcp := P_CTRL_PRO(HeapAlloc(GetProcessHeap, HEAP_ZERO_MEMORY, SizeOf(T_CTRL_PRO)));
  ZeroMemory(pcp, SizeOf(T_CTRL_PRO));

  pcp.CtrlProc   := TCtrlWndProc(Pointer(GetWindowLongW(hWnd, GWL_WNDPROC)));
  pcp.himl       := 0;
  pcp.imgSize    := 0;
  pcp.imgCount   := 0;
  pcp.imgCurrent := 1;
  pcp.dwElapse   := 50;

  SetWindowLongW(hWnd, GWL_USERDATA, Longint(pcp));

  SetWindowLongW(hWnd, GWL_WNDPROC, Longint(@CtrlWndProc));

  SendMessageW(hWnd, WM_SIZE, 0, 0);

end;

//

procedure RemoveAnimationStaticW(hWnd: HWND);
begin

  pcp := P_CTRL_PRO(GetWindowLongW(hWnd, GWL_USERDATA));
  if (pcp <> nil) then
  begin

    if (pcp.hdcMem <> 0) then
    begin
      SelectObject(pcp.hdcMem, pcp.hbmOld);
      DeleteObject(pcp.hbmMem);
      DeleteDC(pcp.hdcMem);
    end;

    KillTimer(hWnd, IDC_ANIMATETIMER);

    SetWindowLongW(hWnd, GWL_WNDPROC, Longint(@pcp.CtrlProc));
    RedrawWindow(hWnd, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_ERASE);

    SetWindowLongW(hWnd, GWL_USERDATA, 0);
    HeapFree(GetProcessHeap, 0, pcp);

  end;

end;

end.