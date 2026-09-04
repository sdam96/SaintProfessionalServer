unit data.connection;

interface

uses
  System.SysUtils, System.IniFiles,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error,
  FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.UI.Intf, FireDAC.Phys, FireDAC.Phys.Intf,
  FireDAC.Phys.MySQL, FireDAC.Phys.MySQLDef,
  FireDAC.DApt, FireDAC.Comp.Client,
  models.types;

const
  // The server runs from the legacy application's root folder and reads its
  // configuration from the same file Saint uses.
  LEGACY_INI_FILE = 'Professional.ini';

type
  // Settings read from section [Sistemas] of Professional.ini.
  // Only the keys the API needs are read; the file holds several hundred
  // more that belong to Saint.
  TSaintSettings = record
    Host: string;
    Port: Integer;
    Database: string;
    UserName: string;
    Password: string;
    Station: string;      // Estacion -> CONTROL/FECHORA suffix
    UsesCashRegister: Boolean;
    UsesIGTF: Boolean;
    IGTFRate: TRate;
    VendorLib: string;    // not in Professional.ini; optional override
    class function LoadFromIni(const AFileName: string): TSaintSettings; static;
    // Professional.ini next to the executable.
    class function Load: TSaintSettings; static;
  end;

  // Builds the FireDAC connection against Saint's MySQL database.
  // The caller owns the returned connection.
  //
  // Saint reaches the same database through the ODBC driver named in the ini
  // file, in autocommit. That value is irrelevant here because FireDAC
  // connects natively, but it is why this connection must never hold locks
  // longer than necessary.
  TSaintConnectionFactory = class
  public
    class function Build(const ASettings: TSaintSettings): TFDConnection;
  end;

implementation

class function TSaintSettings.LoadFromIni(
  const AFileName: string): TSaintSettings;
var
  Ini: TIniFile;
begin
  if not FileExists(AFileName) then
    raise Exception.CreateFmt(
      'No se encontró %s. El servidor debe ejecutarse desde la carpeta ' +
      'raíz de Saint Professional.', [AFileName]);

  Ini := TIniFile.Create(AFileName);
  try
    Result.Host := Ini.ReadString('Sistemas', 'server', '127.0.0.1');
    Result.Port := Ini.ReadInteger('Sistemas', 'port', 3306);
    Result.Database := Ini.ReadString('Sistemas', 'database', '');
    Result.UserName := Ini.ReadString('Sistemas', 'user', '');
    Result.Password := Ini.ReadString('Sistemas', 'password', '');
    Result.Station := Ini.ReadString('Sistemas', 'Estacion', '01');

    // 'usacaja' appears twice in the observed file (1 first, then 0).
    // TIniFile returns the last occurrence, matching how Saint reads it.
    Result.UsesCashRegister := Ini.ReadInteger('Sistemas', 'usacaja', 0) <> 0;

    Result.UsesIGTF := Ini.ReadInteger('Sistemas', 'IGTF', 0) <> 0;
    Result.IGTFRate := Ini.ReadFloat('Sistemas', 'porcentajeIGTF', 0);
    Result.VendorLib := Ini.ReadString('Sistemas', 'VendorLib', '');

    if Result.Database = '' then
      raise Exception.CreateFmt(
        'La clave "database" está vacía en %s.', [AFileName]);
    if Length(Result.Station) <> 2 then
      raise Exception.CreateFmt(
        'La clave "Estacion" debe tener 2 caracteres en %s.', [AFileName]);
  finally
    Ini.Free;
  end;
end;

class function TSaintSettings.Load: TSaintSettings;
begin
  Result := LoadFromIni(ExtractFilePath(ParamStr(0)) + LEGACY_INI_FILE);
end;

class function TSaintConnectionFactory.Build(
  const ASettings: TSaintSettings): TFDConnection;
begin
  Result := TFDConnection.Create(nil);
  try
    Result.DriverName := 'MySQL';
    Result.Params.Values['Server'] := ASettings.Host;
    Result.Params.Values['Port'] := IntToStr(ASettings.Port);
    Result.Params.Values['Database'] := ASettings.Database;
    Result.Params.Values['User_Name'] := ASettings.UserName;
    Result.Params.Values['Password'] := ASettings.Password;

    // Connection-level charset. TSaintSession still issues an explicit
    // SET NAMES ... COLLATE utf8mb4_unicode_ci, because the collation is what
    // matters here and this parameter does not set it.
    Result.Params.Values['CharacterSet'] := 'utf8mb4';

    if ASettings.VendorLib <> '' then
      Result.Params.Values['VendorLib'] := ASettings.VendorLib;

    Result.LoginPrompt := False;
    Result.TxOptions.AutoCommit := False;
    // ReadCommitted is deliberate: under RepeatableRead the counter
    // reservation could read a stale cfparame row if Saint updated it.
    Result.TxOptions.Isolation := xiReadCommitted;
  except
    Result.Free;
    raise;
  end;
end;

end.
