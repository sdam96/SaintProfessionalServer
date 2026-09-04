unit services.documents;

interface

uses
  System.SysUtils, System.Generics.Collections,
  models.types, models.dcheader, models.dcdetall,
  services.connection, data.mapper;

const
  DEFAULT_DOCUMENT_PAGE_SIZE = 50;
  MAX_DOCUMENT_PAGE_SIZE = 500;

type
  EDocumentError = class(Exception);

  // Read-only access to sales documents.
  //
  // dcheader holds every kind of document in one table, discriminated by
  // TIPTRAN: FAC, PAGxFAC, DEVxFAC, N/CxFAC, GIRO, N/CxGIRO, PRE. It also
  // holds purchases, discriminated by TIPREG, which is why every query here
  // pins TIPREG = 1 regardless of what the caller filtered.
  //
  // AWhere is built by the API layer from validated column names; values
  // arrive as bound parameters.
  TDocumentService = class
  private
    FSession: ISaintSession;
    class function NormalisePageSize(AValue: Integer): Integer; static;
    class function SalesOnly(const AWhere: string): string; static;
  public
    constructor Create(const ASession: ISaintSession);

    // Returns nil when CONTROL does not exist. The caller owns the result.
    function GetByControl(const AControl: string;
      const AColumns: TArray<string> = nil): TDCHeader;

    // Lines of a document, ordered by FECHORA, which is the physical order
    // Saint writes them in. The caller owns the returned list.
    function GetLines(const AControl: string;
      const AColumns: TArray<string> = nil): TObjectList<TDCDetail>;

    function FindDocuments(const AWhere: string;
      const AParams: array of Variant;
      APageSize: Integer = DEFAULT_DOCUMENT_PAGE_SIZE;
      AOffset: Integer = 0;
      const AColumns: TArray<string> = nil): TObjectList<TDCHeader>;

    function CountDocuments(const AWhere: string;
      const AParams: array of Variant): Integer;
  end;

implementation

constructor TDocumentService.Create(const ASession: ISaintSession);
begin
  inherited Create;
  FSession := ASession;
end;

class function TDocumentService.NormalisePageSize(AValue: Integer): Integer;
begin
  if AValue <= 0 then
    Result := DEFAULT_DOCUMENT_PAGE_SIZE
  else if AValue > MAX_DOCUMENT_PAGE_SIZE then
    Result := MAX_DOCUMENT_PAGE_SIZE
  else
    Result := AValue;
end;

// TIPREG = 1 is not negotiable: without it a purchase could be returned as
// a sale, since NUMREF is not unique across both.
class function TDocumentService.SalesOnly(const AWhere: string): string;
begin
  if (Trim(AWhere) = '') or (Trim(AWhere) = '1 = 1') then
    Result := 'TIPREG = 1'
  else
    Result := 'TIPREG = 1 AND (' + AWhere + ')';
end;

function TDocumentService.GetByControl(const AControl: string;
  const AColumns: TArray<string>): TDCHeader;
begin
  Result := TDCHeader.Create;
  try
    if not TEntityMapper.SelectOne(FSession, Result, 'dcheader',
         'CONTROL = :p0', [AControl], AColumns) then
      FreeAndNil(Result);
  except
    Result.Free;
    raise;
  end;
end;

function TDocumentService.GetLines(const AControl: string;
  const AColumns: TArray<string>): TObjectList<TDCDetail>;
begin
  // KeyDet01 is (CONTROL, FECHORA), so this ordering follows the clustered
  // index and matches the order Saint wrote the lines in.
  Result := TEntityMapper.SelectMany<TDCDetail>(FSession, 'dcdetall',
    'CONTROL = :p0 ORDER BY FECHORA', [AControl], AColumns);
end;

function TDocumentService.FindDocuments(const AWhere: string;
  const AParams: array of Variant;
  APageSize, AOffset: Integer;
  const AColumns: TArray<string>): TObjectList<TDCHeader>;
var
  Where: string;
begin
  APageSize := NormalisePageSize(APageSize);
  if AOffset < 0 then
    AOffset := 0;

  // FECEMIS can be edited by a Saint user who holds cfusuari.MODIFFEC, so
  // this is the fiscal order, not the creation order. Ordering by
  // SUBSTRING(CONTROL,1,12) would give the real chronological sequence but
  // could not use an index.
  // LIMIT and OFFSET are inlined because MySQL does not accept placeholders
  // there through this driver. Both are integers under our control.
  Where := SalesOnly(AWhere) +
    Format(' ORDER BY FECEMIS DESC, HORA DESC LIMIT %d OFFSET %d',
      [APageSize, AOffset]);

  Result := TEntityMapper.SelectMany<TDCHeader>(
    FSession, 'dcheader', Where, AParams, AColumns);
end;

function TDocumentService.CountDocuments(const AWhere: string;
  const AParams: array of Variant): Integer;
begin
  Result := FSession.ScalarInt(
    'SELECT COUNT(*) FROM dcheader WHERE ' + SalesOnly(AWhere), AParams);
end;

end.
