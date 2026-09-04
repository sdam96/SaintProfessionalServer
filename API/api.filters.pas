unit api.filters;

interface

uses
  System.SysUtils, System.Generics.Collections, Horse;

type
  EInvalidFilterError = class(Exception);

  // Parses query-string filters into a parameterised WHERE clause.
  //
  // Any column the model exposes can be filtered by naming it directly:
  //   ?CODIGO=V24403273
  //   ?NOMBRE[like]=acosta
  //   ?FECEMIS[gte]=82427&FECEMIS[lte]=82440
  //   ?TIPTRAN[in]=FAC,DEVxFAC
  //
  // Column names come from the client and reach the SQL text, so each one is
  // resolved against the columns the class actually declares and the DECLARED
  // spelling is what gets emitted. Values never touch the SQL: they are bound
  // as parameters. Anything unmatched aborts the request.
  //
  // Supported operators: eq (default), ne, gt, gte, lt, lte, like, in.
  TFilterParser = class
  private
    class function IsReservedParam(const AName: string): Boolean;
    class procedure SplitParam(const AParam: string;
      out AColumn, AOperator: string);
    class function LikePattern(const AText: string): string;
  public
    // Returns '1 = 1' and no parameters when nothing was filtered, so the
    // result is always a usable WHERE body.
    class procedure Parse(AClass: TClass; AQuery: THorseCoreParam;
      out AWhere: string; out AParams: TArray<Variant>);
  end;

implementation

uses
  data.mapper;

// Query keys the API reserves for itself; everything else is a column.
class function TFilterParser.IsReservedParam(const AName: string): Boolean;
begin
  Result := SameText(AName, 'fields') or
            SameText(AName, 'limit') or
            SameText(AName, 'offset') or
            SameText(AName, 'sort');
end;

// 'NOMBRE[like]' -> column 'NOMBRE', operator 'like'.
// 'NOMBRE'       -> column 'NOMBRE', operator 'eq'.
class procedure TFilterParser.SplitParam(const AParam: string;
  out AColumn, AOperator: string);
var
  OpenPos, ClosePos: Integer;
begin
  AColumn := AParam;
  AOperator := 'eq';

  OpenPos := Pos('[', AParam);
  if OpenPos = 0 then
    Exit;

  ClosePos := Pos(']', AParam);
  if ClosePos < OpenPos then
    raise EInvalidFilterError.CreateFmt(
      'El filtro "%s" no tiene un operador válido.', [AParam]);

  AColumn := Copy(AParam, 1, OpenPos - 1);
  AOperator := LowerCase(Copy(AParam, OpenPos + 1, ClosePos - OpenPos - 1));
end;

// Escapes the LIKE wildcards so a filter such as '100%' matches literally.
class function TFilterParser.LikePattern(const AText: string): string;
var
  Escaped: string;
begin
  Escaped := StringReplace(AText, '\', '\\', [rfReplaceAll]);
  Escaped := StringReplace(Escaped, '%', '\%', [rfReplaceAll]);
  Escaped := StringReplace(Escaped, '_', '\_', [rfReplaceAll]);
  Result := '%' + Escaped + '%';
end;

class procedure TFilterParser.Parse(AClass: TClass; AQuery: THorseCoreParam;
  out AWhere: string; out AParams: TArray<Variant>);
var
  Key, ParamName, Column, Operator, Value: string;
  Resolved: string;
  Values: TArray<string>;
  Placeholders: string;
  Count, I: Integer;

  procedure AddParam(const AValue: Variant);
  begin
    SetLength(AParams, Count + 1);
    AParams[Count] := AValue;
    Inc(Count);
  end;

begin
  AWhere := '';
  AParams := nil;
  Count := 0;

  for Key in AQuery.Dictionary.Keys do
  begin
    ParamName := Key;
    if IsReservedParam(ParamName) then
      Continue;

    SplitParam(ParamName, Column, Operator);

    Resolved := TEntityMapper.ResolveColumn(AClass, Column);
    if Resolved = '' then
      raise EInvalidFilterError.CreateFmt(
        'El campo "%s" no existe.', [Column]);

    Value := AQuery.Field(Key).AsString;

    if AWhere <> '' then
      AWhere := AWhere + ' AND ';

    if Operator = 'eq' then
    begin
      AWhere := AWhere + Format('`%s` = :p%d', [Resolved, Count]);
      AddParam(Value);
    end
    else if Operator = 'ne' then
    begin
      AWhere := AWhere + Format('`%s` <> :p%d', [Resolved, Count]);
      AddParam(Value);
    end
    else if Operator = 'gt' then
    begin
      AWhere := AWhere + Format('`%s` > :p%d', [Resolved, Count]);
      AddParam(Value);
    end
    else if Operator = 'gte' then
    begin
      AWhere := AWhere + Format('`%s` >= :p%d', [Resolved, Count]);
      AddParam(Value);
    end
    else if Operator = 'lt' then
    begin
      AWhere := AWhere + Format('`%s` < :p%d', [Resolved, Count]);
      AddParam(Value);
    end
    else if Operator = 'lte' then
    begin
      AWhere := AWhere + Format('`%s` <= :p%d', [Resolved, Count]);
      AddParam(Value);
    end
    else if Operator = 'like' then
    begin
      AWhere := AWhere + Format('`%s` LIKE :p%d', [Resolved, Count]);
      AddParam(LikePattern(Value));
    end
    else if Operator = 'in' then
    begin
      Values := Value.Split([',']);
      if Length(Values) = 0 then
        raise EInvalidFilterError.CreateFmt(
          'El filtro "%s[in]" no tiene valores.', [Column]);

      Placeholders := '';
      for I := 0 to High(Values) do
      begin
        if I > 0 then
          Placeholders := Placeholders + ', ';
        Placeholders := Placeholders + Format(':p%d', [Count]);
        AddParam(Trim(Values[I]));
      end;
      AWhere := AWhere + Format('`%s` IN (%s)', [Resolved, Placeholders]);
    end
    else
      raise EInvalidFilterError.CreateFmt(
        'El operador "%s" no está soportado.', [Operator]);
  end;

  if AWhere = '' then
    AWhere := '1 = 1';
end;

end.
