unit models.cjdetall;

interface

uses
  attributes, models.types;

type
  // Cash register line. One row is inserted per cash collection.
  // NUMREF carries the document number with an 'R' suffix.
  TCashDetail = class
  public
    [PrimaryKey][NotNull][Size(19)] CONTROL: string;
    [Indexed][Size(10)] CODCAJA: string;        // 'DEMO' in the dump
    [Indexed][Size(30)] NUMREF: string;         // '000011R'
    [Indexed] FECEMIS: TClarionDate;
    [Size(10)] FECEMISS: string;                // Saint leaves this empty here
    [Decimal(17, 2)] MONTOCOBRADO: TAmount;
    TIPOCOBRO: TFlag;                           // 0 = cash

    [Size(20)] NUMCHETAR: string;
    [Size(15)] CODBANCO: string;
    [Size(15)] CODTAR: string;
    [Size(15)] CODBANCODEP: string;
    [Size(20)] REFERENDEP: string;
    MARCADEP: TFlag;
    DEPOSITADO: TFlag;
    OTRAPLAZA: TFlag;

    HORA: TClarionTime;
    [Indexed][Size(10)] TIPTRAN: string;        // 'FAC', 'DEVxFAC'
    [Size(30)] NUMDOC: string;                  // '000011', no suffix
    [Indexed][Size(25)] CODIGO: string;         // customer
    [Size(60)] DESCRIP1: string;                // 'Factura 000011'
    ESTADOCAJA: TFlag;
  end;

implementation

end.
