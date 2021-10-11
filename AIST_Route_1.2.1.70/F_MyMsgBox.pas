unit F_MyMsgBox;

{******************************************************************************}
{                                                                              }
{ Проект             : Message Box Icon Caption                                }
{ Последнее изменение: 10.07.2010                                              }
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
  Windows, Messages;

function MyMessageBoxW(hWnd: HWND; pszText, pszCaption: LPWSTR; dwFlags: DWORD): Integer;

implementation

var
  hook: HHOOK = 0;

//

function THookProcW(nCode: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
var
  himi: HICON;
  hWnd: THandle;
begin

  case nCode of

    //

    HCBT_ACTIVATE:
    begin

      hWnd := GetParent(THandle(wParam));

      himi := GetClassLongW(hWnd, GCL_HICON);
      if (himi = 0) then
        himi := SendMessageW(hWnd, WM_GETICON, ICON_SMALL, 0);
      if (himi <> 0) then
        SendMessageW(wParam, WM_SETICON, ICON_SMALL, himi);

      Result := 0;

      if (hook <> 0) then
      begin
        UnhookWindowsHookEx(hook);
        hook := 0;
      end;

    end;
    
  else
    Result := CallNextHookEx(hook, nCode, wParam, lParam);
  end;

end;

//

function MyMessageBoxW(hWnd: HWND; pszText, pszCaption: LPWSTR; dwFlags: DWORD): Integer;
var
  dwRet: Integer;
begin

  if (hook = 0) then
    hook := SetWindowsHookExW(WH_CBT, @THookProcW, HInstance, 0);

  dwRet := MessageBoxW(hWnd, pszText, pszCaption, dwFlags);

  if (hook <> 0) then
  begin
    UnhookWindowsHookEx(hook);
    hook := 0;
  end;

  Result := dwRet;

end;

end.