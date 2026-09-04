program ProfessionalServer;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  models.dcheader in 'Models\models.dcheader.pas',
  models.dcdetall in 'Models\models.dcdetall.pas',
  attributes in 'attributes.pas',
  models.types in 'Models\models.types.pas',
  models.cjdetall in 'Models\models.cjdetall.pas',
  models.igtfrecords in 'Models\models.igtfrecords.pas',
  models.movprod in 'Models\models.movprod.pas',
  models.hiproduc in 'Models\models.hiproduc.pas',
  models.hiprocli in 'Models\models.hiprocli.pas',
  models.hiresume in 'Models\models.hiresume.pas',
  models.ivproser in 'Models\models.ivproser.pas',
  models.cfprocli in 'Models\models.cfprocli.pas',
  models.cfparame in 'Models\models.cfparame.pas',
  models.ivserial in 'Models\models.ivserial.pas',
  services.connection in 'Services\services.connection.pas',
  services.counters in 'Services\services.counters.pas',
  services.control in 'Services\services.control.pas',
  services.queries in 'Services\services.queries.pas',
  dto.invoice in 'DTOs\dto.invoice.pas',
  services.invoice in 'Services\services.invoice.pas',
  data.mapper in 'Data\data.mapper.pas',
  data.connection in 'Data\data.connection.pas',
  tools.livetest in 'Tools\tools.livetest.pas',
  api.json in 'API\api.json.pas',
  api.fields in 'API\api.fields.pas',
  api.server in 'API\api.server.pas',
  services.documents in 'Services\services.documents.pas',
  api.filters in 'API\api.filters.pas';

// Reads a -name=value command line argument. FindCmdLineSwitch with
// clstValueAppended keeps the '=' in the returned value, so the parsing is
// done here instead.
function ReadArgument(const AName: string): string;
var
  I, PrefixLen: Integer;
  Arg, Prefix: string;
begin
  Result := '';
  Prefix := '-' + AName + '=';
  PrefixLen := Length(Prefix);

  for I := 1 to ParamCount do
  begin
    Arg := ParamStr(I);
    if Length(Arg) < PrefixLen then
      Continue;

    // Accept '/name=value' as well as '-name=value'.
    if (Length(Arg) > 0) and (Arg[1] = '/') then
      Arg := '-' + Copy(Arg, 2, MaxInt);

    if SameText(Copy(Arg, 1, PrefixLen), Prefix) then
      Exit(Copy(Arg, PrefixLen + 1, MaxInt));
  end;
end;

// Runs the diagnostic switches, if any. Returns True when a switch ran and
// the program must exit without starting the web server.
function RunCommandLineTools: Boolean;
var
  Settings: TLiveTestSettings;
begin
  Result := True;

  // -checkdb reads the configuration and the company row without writing
  // anything. Run this before the first live invoice: it tells a connection
  // failure apart from a write failure.
  if FindCmdLineSwitch('checkdb', ['-', '/'], True) then
  begin
    Writeln(RunConnectionCheck);
    Exit;
  end;

  // -livetest issues ONE cash invoice against the configured database.
  //   ProfessionalServer.exe -livetest -customer=V24403273 -product=010001
  if FindCmdLineSwitch('livetest', ['-', '/'], True) then
  begin
    Settings := TLiveTestSettings.Default;
    Settings.CustomerCode := ReadArgument('customer');
    Settings.ProductCode := ReadArgument('product');
    Writeln(RunLiveInvoiceTest(Settings));
    Exit;
  end;

  Result := False;
end;

var
  Port: Integer;

begin
  try
    if RunCommandLineTools then
      Exit;

    if not TryStrToInt(ReadArgument('port'), Port) then
      Port := DEFAULT_PORT;;
    StartServer(Port);
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
