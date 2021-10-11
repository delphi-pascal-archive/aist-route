unit F_FileHttp;

interface

uses
  Windows, WinInet;

function InternetDownloadTextFileW(pszURL: WideString): WideString;

implementation

//

function InternetDownloadTextFileW(pszURL: WideString): WideString;
var
  pszReq  : WideString;
  fSession: HINTERNET;
  fConnect: HINTERNET;
  fRequest: HINTERNET;
  dwBytes : DWORD;
  dwLength: DWORD;
  dwStatus: DWORD;
  pszBuf  : AnsiString;

  function InternetGetHostNameW(pszText: WideString): WideString;
  var
    dwPos : Integer;
    pszRes: WideString;
  begin
    pszRes := pszURL;
    dwPos := Pos('http://', pszRes);
    if (dwPos > 0) then
      Delete(pszRes, dwPos, 7);
    dwPos := Pos('/', pszRes) - 1;
    Result := Copy(pszRes, 1, dwPos);
    dwPos := lstrcmpiW(LPWSTR(Result), '');
    if (dwPos = 0) then
      Result := pszRes;
  end;

  function InternetGetLinkPathW(pszText: WideString): WideString;
  var
    dwPos  : Integer;
    pszHost: WideString;
    pszRes : WideString;
  begin
    pszRes := pszText;
    pszHost := InternetGetHostNameW(pszRes);
    dwPos := Pos(pszHost, pszRes) + lstrlenW(LPWSTR(pszHost));
    Delete(pszRes, 1, dwPos);
    Result := pszRes;
  end;

begin

  Result := '';

  // инициализируем WinInet функции для установки соединения.

  fSession := InternetOpenW(nil, INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  if (fSession <> nil) then
  try

    // устанавливаем таймаут на подключение в 15 секунд.

    dwLength := 15 * 1000;
    InternetSetOptionW(fSession, INTERNET_OPTION_CONNECT_TIMEOUT, @dwLength,
      SizeOf(dwLength));
    InternetSetOptionW(fSession, INTERNET_OPTION_SEND_TIMEOUT, @dwLength,
      SizeOf(dwLength));
    InternetSetOptionW(fSession, INTERNET_OPTION_RECEIVE_TIMEOUT, @dwLength,
      SizeOf(dwLength));
    InternetSetOptionW(fSession, INTERNET_OPTION_DATA_SEND_TIMEOUT, @dwLength,
      SizeOf(dwLength));
    InternetSetOptionW(fSession, INTERNET_OPTION_DATA_RECEIVE_TIMEOUT, @dwLength,
      SizeOf(dwLength));
    InternetSetOptionW(fSession, INTERNET_OPTION_DISCONNECTED_TIMEOUT, @dwLength,
      SizeOf(dwLength));

    // открываем HTTP сессию для доступа к сайту.

    pszReq := InternetGetHostNameW(pszURL);
    fConnect := InternetConnectW(fSession, LPWSTR(pszReq),
      INTERNET_DEFAULT_HTTP_PORT, nil, nil, INTERNET_SERVICE_HTTP, 0, 0);
    if (fConnect <> nil) then
    try

      // подготавливаем новый HTTP запрос. используем комбинацию флагов для
      // прямой загрузки файла с сервера без кэширования.

      pszReq := InternetGetLinkPathW(pszURL);
      fRequest := HttpOpenRequestW(fConnect, nil, LPWSTR(pszReq), nil, nil,
        nil, INTERNET_FLAG_NO_CACHE_WRITE or INTERNET_FLAG_DONT_CACHE or
        INTERNET_FLAG_RELOAD, 0);
      if (fRequest <> nil) then
      try

        // добавляем HTTP заголовки к HTTP запросу.

        pszReq := 'User-Agent: Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 5.0)' + sLineBreak;
        HttpAddRequestHeadersW(fRequest, LPWSTR(pszReq), lstrlenW(LPWSTR(pszReq)),
          HTTP_ADDREQ_FLAG_ADD);
        pszReq := 'Accept: text/html' + sLineBreak;
        HttpAddRequestHeadersW(fRequest, LPWSTR(pszReq), lstrlenW(LPWSTR(pszReq)),
          HTTP_ADDREQ_FLAG_ADD);
        pszReq := 'Accept-Language: ru' + sLineBreak;
        HttpAddRequestHeadersW(fRequest, LPWSTR(pszReq), lstrlenW(LPWSTR(pszReq)),
          HTTP_ADDREQ_FLAG_ADD);
        pszReq := 'Accept-Charset: windows-1251, utf-8' + sLineBreak;
        HttpAddRequestHeadersW(fRequest, LPWSTR(pszReq), lstrlenW(LPWSTR(pszReq)),
          HTTP_ADDREQ_FLAG_ADD);
        pszReq := 'Keep-Alive: 300' + sLineBreak;
        HttpAddRequestHeadersW(fRequest, LPWSTR(pszReq), lstrlenW(LPWSTR(pszReq)),
          HTTP_ADDREQ_FLAG_ADD);
        pszReq := 'Connection: Keep-Alive' + sLineBreak;
        HttpAddRequestHeadersW(fRequest, LPWSTR(pszReq), lstrlenW(LPWSTR(pszReq)),
          HTTP_ADDREQ_FLAG_ADD);
        pszReq := 'Content-Type: text/plain' + sLineBreak;
        HttpAddRequestHeadersW(fRequest, LPWSTR(pszReq), lstrlenW(LPWSTR(pszReq)),
          HTTP_ADDREQ_FLAG_ADD);

        // отправляем подготовленный запрос на HTTP сервер.

        if HttpSendRequestW(fRequest, nil, 0, nil, 0) then
        try

          dwBytes  := 0;
          dwLength := 10;

          // проверим возвращаемый заголовок. если все хорошо, код ошибки
          // будет 200.

          if HttpQueryInfoW(fRequest, HTTP_QUERY_FLAG_NUMBER or HTTP_QUERY_STATUS_CODE,
            @dwStatus, dwLength, dwBytes) then
          try

            case dwStatus of
              HTTP_STATUS_OK:
                begin

                  // здесь мы декодируем строку, полученную от запроса и
                  // преобразуем ее из UTF-8 в формат Unicode.

                  InternetQueryDataAvailable(fRequest, dwLength, 0, 0);
                  SetLength(pszBuf, dwLength + 1);

                  repeat
                    InternetReadFile(fRequest, LPTSTR(pszBuf), dwLength, dwBytes);
                    SetLength(pszBuf, dwBytes);
                    Result := Result + UTF8Decode(pszBuf);
                  until
                    dwBytes = 0;

                end;
            end;

          //

          finally
          end;

        //

        finally
        end;

      //

      finally
        InternetCloseHandle(fRequest);
      end;

    //

    finally
      InternetCloseHandle(fConnect);
    end;

  //

  finally
    InternetCloseHandle(fSession);
  end;

end;

end.