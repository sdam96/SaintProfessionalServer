unit attributes;

interface

type
  PrimaryKeyAttribute = class(TCustomAttribute)
  end;

  NotNullAttribute = class(TCustomAttribute)
  end;

  IndexedAttribute = class(TCustomAttribute)
  end;

  FixedLengthAttribute = class(TCustomAttribute)
  end;

  SizeAttribute = class(TCustomAttribute)
  private
    FValue: Integer;
  public
    constructor Create(AValue: Integer);
    property Value: Integer read FValue;
  end;

  DecimalAttribute = class(TCustomAttribute)
  private
    FPrecision: Integer;
    FScale: Integer;
  public
    constructor Create(APrecision, AScale: Integer);
    property Precision: Integer read FPrecision;
    property Scale: Integer read FScale;
  end;

  DefaultValueAttribute = class(TCustomAttribute)
  private
    FValue: string;
  public
    constructor Create(const AValue: string);
    property Value: string read FValue;
  end;

implementation

{ SizeAttribute }

constructor SizeAttribute.Create(AValue: Integer);
begin
  inherited Create;
  FValue := AValue;
end;

{ DecimalAttribute }

constructor DecimalAttribute.Create(APrecision, AScale: Integer);
begin
  inherited Create;
  FPrecision := APrecision;
  FScale := AScale;
end;

{ DefaultValueAttribute }

constructor DefaultValueAttribute.Create(const AValue: string);
begin
  inherited Create;
  FValue := AValue;
end;

end.
