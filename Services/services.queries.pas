unit services.queries;

interface

uses
  System.SysUtils, System.Generics.Collections,
  models.types, models.cfprocli, models.ivproser,
  services.connection, data.mapper;

const
  DEFAULT_PAGE_SIZE = 50;
  MAX_PAGE_SIZE = 500;

type
  EQueryError = class(Exception);

  // Read-only access to the master tables the API exposes.
  //
  // AWhere is built by the API layer from validated column names; values
  // arrive as bound parameters. Customer queries pin TIPREG = 1 on top of
  // whatever was filtered: cfprocli holds suppliers in the same table and
  // codes are not unique across both.
  TQueryService = class
  private
    FSession: ISaintSession;
    class function NormalisePageSize(AValue: Integer): Integer; static;
    class function CustomersOnly(const AWhere: string): string; static;
  public
    constructor Create(const ASession: ISaintSession);

    // Returns nil when the code does not exist. The caller owns the result.
    function GetCustomer(const ACode: string;
      const AColumns: TArray<string> = nil): TParty;
    function GetProduct(const ACode: string;
      const AColumns: TArray<string> = nil): TProduct;

    // The caller owns the returned lists.
    function FindCustomers(const AWhere: string;
      const AParams: array of Variant;
      APageSize: Integer = DEFAULT_PAGE_SIZE;
      AOffset: Integer = 0;
      const AColumns: TArray<string> = nil): TObjectList<TParty>;
    function FindProducts(const AWhere: string;
      const AParams: array of Variant;
      APageSize: Integer = DEFAULT_PAGE_SIZE;
      AOffset: Integer = 0;
      const AColumns: TArray<string> = nil): TObjectList<TProduct>;

    function CountCustomers(const AWhere: string;
      const AParams: array of Variant): Integer;
    function CountProducts(const AWhere: string;
      const AParams: array of Variant): Integer;
  end;

implementation

constructor TQueryService.Create(const ASession: ISaintSession);
begin
  inherited Create;
  FSession := ASession;
end;

class function TQueryService.NormalisePageSize(AValue: Integer): Integer;
begin
  if AValue <= 0 then
    Result := DEFAULT_PAGE_SIZE
  else if AValue > MAX_PAGE_SIZE then
    Result := MAX_PAGE_SIZE
  else
    Result := AValue;
end;

class function TQueryService.CustomersOnly(const AWhere: string): string;
begin
  if (Trim(AWhere) = '') or (Trim(AWhere) = '1 = 1') then
    Result := 'TIPREG = 1'
  else
    Result := 'TIPREG = 1 AND (' + AWhere + ')';
end;

function TQueryService.GetCustomer(const ACode: string;
  const AColumns: TArray<string>): TParty;
begin
  Result := TParty.Create;
  try
    if not TEntityMapper.SelectOne(FSession, Result, 'cfprocli',
         'TIPREG = 1 AND CODIGO = :p0', [ACode], AColumns) then
      FreeAndNil(Result);
  except
    Result.Free;
    raise;
  end;
end;

function TQueryService.GetProduct(const ACode: string;
  const AColumns: TArray<string>): TProduct;
begin
  Result := TProduct.Create;
  try
    if not TEntityMapper.SelectOne(FSession, Result, 'ivproser',
         'CODPRO = :p0', [ACode], AColumns) then
      FreeAndNil(Result);
  except
    Result.Free;
    raise;
  end;
end;

function TQueryService.FindCustomers(const AWhere: string;
  const AParams: array of Variant;
  APageSize, AOffset: Integer;
  const AColumns: TArray<string>): TObjectList<TParty>;
var
  Where: string;
begin
  APageSize := NormalisePageSize(APageSize);
  if AOffset < 0 then
    AOffset := 0;

  // LIMIT and OFFSET are inlined because MySQL does not accept placeholders
  // there through this driver. Both are integers under our control.
  Where := CustomersOnly(AWhere) +
    Format(' ORDER BY NOMBRE LIMIT %d OFFSET %d', [APageSize, AOffset]);

  Result := TEntityMapper.SelectMany<TParty>(
    FSession, 'cfprocli', Where, AParams, AColumns);
end;

function TQueryService.FindProducts(const AWhere: string;
  const AParams: array of Variant;
  APageSize, AOffset: Integer;
  const AColumns: TArray<string>): TObjectList<TProduct>;
var
  Where: string;
begin
  APageSize := NormalisePageSize(APageSize);
  if AOffset < 0 then
    AOffset := 0;

  Where := AWhere +
    Format(' ORDER BY DESCRIP1 LIMIT %d OFFSET %d', [APageSize, AOffset]);

  Result := TEntityMapper.SelectMany<TProduct>(
    FSession, 'ivproser', Where, AParams, AColumns);
end;

function TQueryService.CountCustomers(const AWhere: string;
  const AParams: array of Variant): Integer;
begin
  Result := FSession.ScalarInt(
    'SELECT COUNT(*) FROM cfprocli WHERE ' + CustomersOnly(AWhere), AParams);
end;

function TQueryService.CountProducts(const AWhere: string;
  const AParams: array of Variant): Integer;
begin
  Result := FSession.ScalarInt(
    'SELECT COUNT(*) FROM ivproser WHERE ' + AWhere, AParams);
end;

end.
