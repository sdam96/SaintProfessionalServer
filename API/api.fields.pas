unit api.fields;

interface

uses
  System.SysUtils, System.Classes;

type
  EInvalidFieldsError = class(Exception);

  TFieldSelection = class
  public
    class function Parse(AClass: TClass; const AValue: string): TArray<string>;
  end;

implementation

uses
  data.mapper;

{ TFieldException }

class function TFieldSelection.Parse(AClass: TClass;
  const AValue: string): TArray<string>;
var
  Parts: TArray<string>;
  Part, Resolved: string;
  Count: Integer;
  I, J: Integer;
  Duplicated: Boolean;
begin
  Result := nil;
  if Trim(AValue) = '' then Exit;

  Parts := AValue.Split([',']);
  SetLength(Result, Length(Parts));
  Count := 0;

  for I := 0 to High(Parts) do
  begin
    Part := Trim(Parts[I]);
    if Part = '' then Continue;

    Resolved := TEntityMapper.ResolveColumn(AClass, Part);
    if Resolved = '' then
      raise EInvalidFieldsError.CreateFmt('Campo "%s" no existe', [Part]);

    Duplicated := False;
    for J := 0 to Count - 1 do
      if SameText(Result[J], Resolved) then
      begin
        Duplicated := True;
        Break;
      end;

    if not Duplicated then
    begin
      Result[Count] := Resolved;
      Inc(Count);
    end;
  end;

  SetLength(Result, Count);
  if Count = 0 then
    raise EInvalidFieldsError.Create(
      'Parametro "fields" no tiene campos validos');
end;

end.
