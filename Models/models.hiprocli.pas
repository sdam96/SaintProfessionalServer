unit models.hiprocli;

interface

uses
  attributes, models.types;

type
  // Monthly history per customer/supplier. TIPREG = 1 sales, 0 purchases.
  // CONTADO and COBPAG accumulate the total net of tax. IMPUESTO does not
  // accumulate consistently between cash and credit: still undetermined.
  // Logical key: ANIOH + MESH + TIPREG + CODIGO.
  TPartyHistory = class
  public
    [PrimaryKey][NotNull] ANIOH: Integer;
    [PrimaryKey][NotNull] MESH: Integer;
    [PrimaryKey][NotNull] TIPREG: TFlag;
    [PrimaryKey][NotNull][Size(25)] CODIGO: string;

    [Decimal(17, 2)] CONTADO: TAmount;
    [Decimal(17, 2)] CREDITO: TAmount;
    [Decimal(17, 2)] IMPUESTO: TAmount;
    [Decimal(17, 2)] COBPAG: TAmount;
    [Decimal(17, 2)] DESCUENTOS: TAmount;
    [Decimal(17, 2)] DEVOLUCIONES: TAmount;
    [Decimal(17, 2)] COSTOSMERCANCIA: TAmount;      // may end up NEGATIVE
    [Decimal(17, 2)] COSTOSMERCANCIADEV: TAmount;
  end;

implementation

end.
