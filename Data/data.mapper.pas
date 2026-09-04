unit data.mapper;

interface

uses
  System.SysUtils, System.Rtti, System.TypInfo, System.Classes,
  System.Generics.Collections,
  Data.DB, FireDAC.Comp.Client, FireDAC.Stan.Param, services.connection;

type
  EMapperError = class(Exception);

  // Maps model classes to Saint tables through RTTI. Every public field of a
  // model class is a column and its name matches the column name exactly.
  //
  // Two consequences of the schema drive this design:
  //   - No column has a DEFAULT and almost none are NOT NULL, so every INSERT
  //     must list every column of the entity.
  //   - Delphi zero-initialises class fields, so an unassigned string field
  //     writes '' and an unassigned numeric writes 0. That is exactly what
  //     Saint stores; nothing is ever written as NULL.
  //
  // A partial entity (TParameters) maps only the columns it declares, so its
  // SELECT reads only those and its UPDATE must be written by hand.
  TEntityMapper = class
  private
    class var FCtx: TRttiContext;
    class procedure BindField(AParam: TFDParam; ARttiField: TRttiField;
      AEntity: TObject);
    class procedure ReadField(ARttiField: TRttiField; AEntity: TObject;
      AField: TField);
  public
    // All column names the class exposes, in declaration order.
    class function ColumnNames(AClass: TClass): TArray<string>;
    // True when AName matches one of the class columns, case-insensitively.
    // This is what makes a client-supplied projection safe to inline.
    class function HasColumn(AClass: TClass; const AName: string): Boolean;
    // Returns the column as declared, or '' when it does not exist.
    class function ResolveColumn(AClass: TClass; const AName: string): string;

    class function ColumnList(AClass: TClass): string;
    // Backtick-quoted list restricted to AColumns. An empty array yields
    // every column. Each entry MUST have been resolved through
    // ResolveColumn first; this method does not validate.
    class function ProjectionList(AClass: TClass;
      const AColumns: TArray<string>): string;

    class function BuildInsert(const ATable: string; AClass: TClass): string;
    class function BuildSelect(const ATable: string; AClass: TClass;
      const AWhere: string;
      const AColumns: TArray<string> = nil): string;

    class procedure Insert(const ASession: ISaintSession; AEntity: TObject;
      const ATable: string);
    // Returns False when the query finds no row; AEntity is left untouched.
    // Fields outside AColumns keep their zero value.
    class function SelectOne(const ASession: ISaintSession; AEntity: TObject;
      const ATable, AWhere: string; const AParams: array of Variant;
      const AColumns: TArray<string> = nil): Boolean;
    // AWhere may carry ORDER BY and LIMIT. The caller owns the returned list.
    class function SelectMany<T: class, constructor>(
      const ASession: ISaintSession; const ATable, AWhere: string;
      const AParams: array of Variant;
      const AColumns: TArray<string> = nil): TObjectList<T>;
    class procedure LoadFromDataSet(AEntity: TObject; ADataSet: TDataSet);
  end;

implementation

class function TEntityMapper.ColumnNames(AClass: TClass): TArray<string>;
var
  Typ: TRttiType;
  Fld: TRttiField;
  Count: Integer;
begin
  Typ := FCtx.GetType(AClass);
  SetLength(Result, Length(Typ.GetFields));
  Count := 0;
  for Fld in Typ.GetFields do
    if Fld.Visibility = mvPublic then
    begin
      Result[Count] := Fld.Name;
      Inc(Count);
    end;
  SetLength(Result, Count);

  if Count = 0 then
    raise EMapperError.CreateFmt(
      'La clase %s no expone columnas.', [AClass.ClassName]);
end;

class function TEntityMapper.ResolveColumn(AClass: TClass;
  const AName: string): string;
var
  Column: string;
begin
  Result := '';
  for Column in ColumnNames(AClass) do
    if SameText(Column, AName) then
      Exit(Column);
end;

class function TEntityMapper.HasColumn(AClass: TClass;
  const AName: string): Boolean;
begin
  Result := ResolveColumn(AClass, AName) <> '';
end;

class function TEntityMapper.ColumnList(AClass: TClass): string;
begin
  Result := ProjectionList(AClass, nil);
end;

class function TEntityMapper.ProjectionList(AClass: TClass;
  const AColumns: TArray<string>): string;
var
  Cols: TArray<string>;
  I: Integer;
begin
  if Length(AColumns) = 0 then
    Cols := ColumnNames(AClass)
  else
    Cols := AColumns;

  Result := '`' + Cols[0] + '`';
  for I := 1 to High(Cols) do
    Result := Result + ', `' + Cols[I] + '`';
end;

class function TEntityMapper.BuildInsert(const ATable: string;
  AClass: TClass): string;
var
  Cols: TArray<string>;
  Values: string;
  I: Integer;
begin
  Cols := ColumnNames(AClass);
  Values := ':' + Cols[0];
  for I := 1 to High(Cols) do
    Values := Values + ', :' + Cols[I];
  Result := Format('INSERT INTO %s (%s) VALUES (%s)',
    [ATable, ColumnList(AClass), Values]);
end;

class function TEntityMapper.BuildSelect(const ATable: string;
  AClass: TClass; const AWhere: string;
  const AColumns: TArray<string>): string;
begin
  Result := Format('SELECT %s FROM %s WHERE %s',
    [ProjectionList(AClass, AColumns), ATable, AWhere]);
end;

class procedure TEntityMapper.BindField(AParam: TFDParam;
  ARttiField: TRttiField; AEntity: TObject);
var
  Value: TValue;
begin
  Value := ARttiField.GetValue(AEntity);
  case ARttiField.FieldType.TypeKind of
    tkUString, tkString, tkLString, tkWString:
      AParam.AsString := Value.AsString;
    tkInteger:
      AParam.AsInteger := Value.AsOrdinal;
    tkInt64:
      AParam.AsLargeInt := Value.AsInt64;
    tkFloat:
      if ARttiField.FieldType.Handle = TypeInfo(Currency) then
        AParam.AsCurrency := Value.AsCurrency
      else
        AParam.AsFloat := Value.AsExtended;
  else
    raise EMapperError.CreateFmt(
      'Tipo no soportado en la columna %s.', [ARttiField.Name]);
  end;
end;

class procedure TEntityMapper.ReadField(ARttiField: TRttiField;
  AEntity: TObject; AField: TField);
begin
  case ARttiField.FieldType.TypeKind of
    tkUString, tkString, tkLString, tkWString:
      ARttiField.SetValue(AEntity, TValue.From<string>(AField.AsString));
    tkInteger:
      ARttiField.SetValue(AEntity,
        TValue.FromOrdinal(ARttiField.FieldType.Handle, AField.AsInteger));
    tkInt64:
      ARttiField.SetValue(AEntity, TValue.From<Int64>(AField.AsLargeInt));
    tkFloat:
      if ARttiField.FieldType.Handle = TypeInfo(Currency) then
        ARttiField.SetValue(AEntity, TValue.From<Currency>(AField.AsCurrency))
      else
        ARttiField.SetValue(AEntity, TValue.From<Double>(AField.AsFloat));
  else
    raise EMapperError.CreateFmt(
      'Tipo no soportado en la columna %s.', [ARttiField.Name]);
  end;
end;

class procedure TEntityMapper.Insert(const ASession: ISaintSession;
  AEntity: TObject; const ATable: string);
var
  Query: TFDQuery;
  Typ: TRttiType;
  Fld: TRttiField;
begin
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := ASession.Connection;
    Query.SQL.Text := BuildInsert(ATable, AEntity.ClassType);

    Typ := FCtx.GetType(AEntity.ClassType);
    for Fld in Typ.GetFields do
      if Fld.Visibility = mvPublic then
        BindField(Query.ParamByName(Fld.Name), Fld, AEntity);

    Query.ExecSQL;
  finally
    Query.Free;
  end;
end;

class function TEntityMapper.SelectOne(const ASession: ISaintSession;
  AEntity: TObject; const ATable, AWhere: string;
  const AParams: array of Variant;
  const AColumns: TArray<string>): Boolean;
var
  Query: TFDQuery;
begin
  Query := ASession.OpenQuery(
    BuildSelect(ATable, AEntity.ClassType, AWhere, AColumns), AParams);
  try
    Result := not Query.IsEmpty;
    if Result then
      LoadFromDataSet(AEntity, Query);
  finally
    Query.Free;
  end;
end;

class function TEntityMapper.SelectMany<T>(const ASession: ISaintSession;
  const ATable, AWhere: string; const AParams: array of Variant;
  const AColumns: TArray<string>): TObjectList<T>;
var
  Query: TFDQuery;
  Entity: T;
begin
  Result := TObjectList<T>.Create(True);
  try
    Query := ASession.OpenQuery(
      BuildSelect(ATable, T, AWhere, AColumns), AParams);
    try
      while not Query.Eof do
      begin
        Entity := T.Create;
        Result.Add(Entity);
        LoadFromDataSet(Entity, Query);
        Query.Next;
      end;
    finally
      Query.Free;
    end;
  except
    Result.Free;
    raise;
  end;
end;

// Only the fields present in the result set are read, so a projected query
// leaves the remaining fields at their zero value.
class procedure TEntityMapper.LoadFromDataSet(AEntity: TObject;
  ADataSet: TDataSet);
var
  Typ: TRttiType;
  Fld: TRttiField;
  DataField: TField;
begin
  Typ := FCtx.GetType(AEntity.ClassType);
  for Fld in Typ.GetFields do
    if Fld.Visibility = mvPublic then
    begin
      DataField := ADataSet.FindField(Fld.Name);
      if (DataField <> nil) and not DataField.IsNull then
        ReadField(Fld, AEntity, DataField);
    end;
end;

end.
