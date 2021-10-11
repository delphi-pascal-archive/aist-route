unit F_WinMain;

interface

uses
  Windows, CommCtrl, F_CommCtrl, F_Windows, F_SetupApi, F_SysUtils, F_FileInfo,
  F_MyMsgBox, F_Resources, D_MainProc;

function WinMain(HInstance: HINST; hPrevInstance: HINST; lpCmdLine: LPTSTR; nCmdShow: Integer): Integer; stdcall;

implementation

//

function WinMain(HInstance: HINST; hPrevInstance: HINST; lpCmdLine: LPTSTR; nCmdShow: Integer): Integer; stdcall;
var
  pszText: WideString;
  iccex  : TInitCommonControlsEx;
  uMsg   : TMsg;
  hDlg   : HWND;
  hTable : HACCEL;
begin

  //

  Result := 0;

  // извлекаем информацию из ресурса версии и заполняем ей подготовленную
  // структуру, которую вдальнейшем будем использовать для чтения и записи
  // настроек программы, а также вывода текста в заголовке сообщений.

  pszText := AnsiStringToWide(ParamStr(0), CP_ACP);
  ZeroMemory(@exeInfo, SizeOf(TStringFileInfoW));
  GetFileInfoW(pszText, ExeInfo);

  // проверяем версию операционной системы. в нашем случае это требуется для
  // применения расширенных оконных стилей при создании окон. минимальная версия
  // операционной системы для корректной работы программы - Windows 2000.

  ZeroMemory(@osvi, SizeOf(TOSVersionInfoW));
  osvi.dwOSVersionInfoSize := SizeOf(TOSVersionInfoW);
  if (F_Windows.GetVersionExW(osvi) and (osvi.dwPlatformId = VER_PLATFORM_WIN32_NT) and
    (osvi.dwMajorVersion >= 5)) then
  begin

    if IsUserAdmin then
    begin

      // инициализируем библиотеку стандартных элементов управления.

      iccex.dwSize := SizeOf(TInitCommonControlsEx);
      iccex.dwICC  := ICC_BAR_CLASSES or ICC_INTERNET_CLASSES or
        ICC_PROGRESS_CLASS or ICC_STANDARD_CLASSES or ICC_WIN95_CLASSES;
      InitCommonControlsEx(iccex);

      //

      hDlg := CreateDialogParamW(HInstance, MAKEINTRESOURCEW(RC_DIALOG_MAIN), 0,
        @MainDlgProc, 0);

      if (hDlg <> 0) then
      begin

        //

        hTable := LoadAcceleratorsW(HInstance, MAKEINTRESOURCEW(RC_ACCEL_MAIN));

        // запускаем цикл обработки сообщений.

        while GetMessageW(uMsg, 0, 0, 0) do
        begin

          if (TranslateAcceleratorW(hDlg, hTable, uMsg) = 0) and
            (not IsDialogMessageW(hDlg, uMsg)) then

          begin
            TranslateMessage(uMsg);
            DispatchMessageW(uMsg);
          end;

        end;

        // уничтожаем таблицу акселераторов.

        if (hTable <> 0) then
          DestroyAcceleratorTable(hTable);

        // уничтожаем диалоговое окно.

        DestroyWindow(hDlg);

      end;

      // возвращаем значение кода выхода из программы в систему.

      Result := uMsg.wParam;

    end
    else
    begin

      pszText := LoadStrW(ID_ADMIN_RIGHTS);
      MessageBoxW(
        GetActiveWindow,
        MAKEINTRESOURCEW(pszText),
        MAKEINTRESOURCEW(ExeInfo.pszProductName),
        MB_OK or MB_ICONEXCLAMATION
      );

    end;


  end
  else
  begin

    pszText := LoadStrW(ID_REQUIRES_NT);
    MessageBoxW(
      GetActiveWindow,
      MAKEINTRESOURCEW(pszText),
      MAKEINTRESOURCEW(ExeInfo.pszProductName),
      MB_OK or MB_ICONEXCLAMATION
    );

  end;

end;

end.