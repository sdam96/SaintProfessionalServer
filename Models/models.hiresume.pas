unit models.hiresume;

interface

uses
  attributes, models.types;

type
  // Monthly summary; hiprocli aggregated without the party code.
  // Logical key: ANIOH + MESH + TIPREG.
  TSummaryHistory = class
  public
    [PrimaryKey][NotNull] ANIOH: Integer;
    [PrimaryKey][NotNull] MESH: Integer;
    [PrimaryKey][NotNull] TIPREG: TFlag;

    [Decimal(17, 2)] CONTADO: TAmount;
    [Decimal(17, 2)] CREDITO: TAmount;
    [Decimal(17, 2)] IMPUESTO: TAmount;
    [Decimal(17, 2)] COBPAG: TAmount;
    [Decimal(17, 2)] DESCUENTOS: TAmount;
    [Decimal(17, 2)] DEVOLUCIONES: TAmount;
    [Decimal(17, 2)] COSTOSMERCANCIA: TAmount;
    [Decimal(17, 2)] COSTOSMERCANCIADEV: TAmount;
  end;

implementation

end.
