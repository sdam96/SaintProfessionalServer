unit models.cfparame;

interface

uses
  attributes, models.types;

type
  // DELIBERATELY PARTIAL MAPPING. cfparame holds around 300 configuration
  // columns that belong to Saint. Never INSERT or UPDATE the whole entity:
  // the ORM would overwrite settings we do not know about. Read only, and
  // update named columns one at a time.
  TParameters = class
  public
    [PrimaryKey][NotNull] CONTROL: TFlag;          // always 1

    [Size(100)] NOMBRE: string;
    [Size(25)] NUMFISCAL: string;
    [Decimal(7, 2)] IMPPOR: TRate;                 // general VAT, 16.00

    // ---- Counters. The only real contention point with Saint. ----
    NROINIFAC: Integer;                            // next invoice number
    NROINIPRE: Integer;                            // next quote number
    NROINIDEV: Integer;
    CONTADORCONTROL: Integer;                      // CONTROL/FECHORA sequence

    [Decimal(17, 4)] TASACAMBIO1: TAmount;         // 850.0000
    [Size(15)] NOMBREMONEDA: string;               // 'USD'
    [Size(15)] MONEDA: string;                     // 'BolIvares'
    FECCIERRE: TClarionDate;
  end;

implementation

end.
