unit api.json;

interface

uses
  System.SysUtils, System.JSON, System.Rtti, System.TypInfo,
  System.Generics.Collections, models.types, models.cfprocli,
  models.ivproser, dto.invoice;

type
  EInvoiceRequestError = class(Exception);

  TJsonMapper = class
  private
    class var FCtx: TRttiContext;
    class function Includes(const AColumns: TArray<string>;
      const AName: string): Boolean;
    class function FieldToJson(ARttiField: TRttiField; AEntity: TObject):
      TJSONValue;
  public
    class function EntityToJson(AEntity: TObject;
      const AColumns: TArray<string> = nil): TJSONObject;

    class function EntityListToJson<T: class>(AList: TObjectList<T>;
      ATotal, AOffset: Integer; const AColumns: TArray<string> = nil):
        TJSONObject;

    class function InvoiceResultToJson(const AResult: TInvoiceResult):
      TJSONObject;

    class function ErrorToJson(const AMessage: string): TJSONObject;
    class function JsonToInvoiceRequest(ABody: TJSONObject): TInvoiceRequest;
  end;

implementation

function ReadString(AObject: TJSONObject; const AKey: string;
  const ADefault: string = ''): string;
var
  Value: TJSONValue;
begin
  Value := AObject.FindValue(AKey);
  if (Value = nil) or (Value is TJSONNull) then Result := ADefault
  else Result := Value.Value;
end;

function ReadNumber(AObject: TJSONObject; const AKey: string;
  ADefault: Double = 0): Double;
var
  Value: TJSONValue;
begin
  Value := AObject.FindValue(AKey);
  if (Value = nil) or (Value is TJSONNull) then Result := ADefault
  else if not TryStrToFloat(Value.Value, Result, TFormatSettings.Invariant) then
    raise EInvoiceRequestError.CreateFmt(
      'Campo "%s" no es un numero valido', [AKey]);
end;

function ReadBool(AObject: TJSONObject; const AKey: string;
  ADefault: Boolean = False): Boolean;
var
  Value: TJSONValue;
begin
  Value := AObject.FindValue(AKey);
  if (Value = nil) or (Value is TJSONNull) then Result := ADefault
  else Result := Value is TJSONTrue;
end;

{ TJsonMapper }

class function TJsonMapper.EntityListToJson<T>(AList: TObjectList<T>; ATotal,
  AOffset: Integer; const AColumns: TArray<string>): TJSONObject;
var
  Items: TJSONArray;
  Item: T;
begin
  Items := TJSONArray.Create;

  for Item in AList do Items.AddElement(EntityToJson(Item, AColumns));

  Result := TJSONObject.Create;
  Result.AddPair('total', TJSONNumber.Create(ATotal));
  Result.AddPair('count', TJSONNumber.Create(AList.Count));
  Result.AddPair('offset', TJSONNumber.Create(AOffset));
  Result.AddPair('data', Items);
end;

class function TJsonMapper.EntityToJson(AEntity: TObject;
  const AColumns: TArray<string>): TJSONObject;
var
  Typ: TRttiType;
  Fld: TRttiField;
begin
  Result := TJSONObject.Create;

  Typ := FCtx.GetType(AEntity.ClassType);
  for Fld in Typ.GetFields do
    if (Fld.Visibility = mvPublic) and Includes(AColumns, Fld.Name) then
      Result.AddPair(Fld.Name, FieldToJson(Fld, AEntity));
end;

class function TJsonMapper.ErrorToJson(const AMessage: string): TJSONObject;
begin
  Result := TJSONObject.Create;;
  Result.AddPair('error', AMessage);
end;

class function TJsonMapper.FieldToJson(ARttiField: TRttiField;
  AEntity: TObject): TJSONValue;
var
  Value: TValue;
begin
  Value := ARttiField.GetValue(AEntity);

  case ARttiField.FieldType.TypeKind of
    tkUString, tkString, tkLString, tkWString:
      Result:=TJSONString.Create(Value.AsString);

    tkInteger:
      Result := TJSONNumber.Create(Value.AsOrdinal);

    tkInt64:
      Result := TJSONNumber.Create(Value.AsInt64);

    tkFloat:
      if ARttiField.FieldType.Handle = TypeInfo(Currency) then
        Result :=TJSONNumber.Create(Value.AsCurrency)
      else
        Result := TJSONNumber.Create(Value.AsExtended);
  else
    Result := TJSONNull.Create;
  end;
end;

class function TJsonMapper.Includes(const AColumns: TArray<string>;
  const AName: string): Boolean;
var
  Column: string;
begin
  if Length(AColumns) = 0 then Exit(True);

  for Column in AColumns do
    if SameText(Column, AName) then
      Exit(True);
  Result := False;
end;

class function TJsonMapper.InvoiceResultToJson(
  const AResult: TInvoiceResult): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('numero', AResult.InvoiceNumber);
  Result.AddPair('controlFactura', AResult.InvoiceControl);
  Result.AddPair('controlPago', AResult.PaymentControl);
  Result.AddPair('controlCaja', AResult.CashControl);
  Result.AddPair('fecha', ClarionToStr(AResult.IssueDate));
  Result.AddPair('fechaClarion', TJSONNumber.Create(AResult.IssueDate));
  Result.AddPair('base', TJSONNumber.Create(AResult.GrossAmount));
  Result.AddPair('impuesto', TJSONNumber.Create(AResult.TaxAmount));
  Result.AddPair('igtf', TJSONNumber.Create(AResult.IGTFAmount));
  Result.AddPair('total', TJSONNumber.Create(AResult.TotalAmount));
end;

class function TJsonMapper.JsonToInvoiceRequest(
  ABody: TJSONObject): TInvoiceRequest;
var
  LinesValue: TJSONValue;
  LinesArray: TJSONArray;
  LineValue: TJSONValue;
  LineObject: TJSONObject;
  Line: TInvoiceLineRequest;
  I: Integer;
begin
  if ABody = nil then
    raise EInvoiceRequestError.Create('Cuerpo de la solicitud vacio');

  Result := TInvoiceRequest.Create;
  try
    Result.CustomerCode := ReadString(ABody, 'cliente');
    if Trim(Result.CustomerCode) = '' then
      raise EInvoiceRequestError.Create('Falta campo "cliente"');

    Result.SalespersonCode := ReadString(ABody, 'vendedor','01');
    Result.UserCode := ReadString(ABody, 'usuario', 'DEMO');
    Result.CashRegisterCode := ReadString(ABody, 'caja', 'DEMO');
    Result.PaidInForeignCurrency := ReadBool(ABody, 'pagoEnDivisa');

    if SameText(ReadString(ABody, 'condicion', 'contado'), 'creadito') then
      Result.PaymentTerms := ptCredit
    else Result.PaymentTerms := ptCash;

    Result.CreditDays := Trunc(ReadNumber(ABody, 'diasCredito', 0));

    LinesValue := ABody.FindValue('renglones');
    if not (LinesValue is TJSONArray) then
      raise EInvoiceRequestError.Create(
      'Renglones vacios');

    LinesArray := TJSONArray(LinesValue);
    if LinesArray.Count = 0 then
      raise EInvoiceRequestError.Create('factura vacia');

    for I := 0 to LinesArray.Count - 1 do
    begin
      LineValue := LinesArray.Items[I];
      if not (LineValue is TJSONObject) then
        raise EInvoiceRequestError.CreateFmt(
        'Renglon %d no es un objeto valido', [I + 1]);

      LineObject := TJSONObject(LineValue);
      Line := Result.AddLine;
      Line.ProductCode := ReadString(LineObject, 'producto');
      Line.Quantity := ReadNumber(LineObject, 'cantidad', 0);
      Line.UnitPrice := ReadNumber(LineObject,  'precio', 0);
      Line.DiscountRate := ReadNumber(LineObject, 'descuento', 0);
      Line.ServerCode := ReadString(LineObject, 'servidor');
      Line.WarehouseCode := ReadString(LineObject, 'deposito', '01');
    end;

  except
    Result.Free;
    raise;
  end;

end;

end.
