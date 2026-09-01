unit models.cfprocli;

interface

uses
  attributes, models.types;

type
  // Suppliers and customers share this table.
  // TIPREG = 1 -> customer/sales ; TIPREG = 0 -> supplier/purchases.
  // EVERY API query must filter TIPREG = 1.
  TParty = class
  public
    [PrimaryKey][NotNull] TIPREG: TFlag;
    [PrimaryKey][NotNull][Size(25)] CODIGO: string;

    [Indexed][Size(100)] NOMBRE: string;
    [Size(40)] REPRESEN: string;
    [Size(120)] DIRECC1: string;
    [Size(120)] DIRECC2: string;
    [Size(40)] NUMTEL: string;
    [Indexed][Size(25)] RIF: string;
    [Size(25)] NIT: string;

    PRECIO: TFlag;                      // applicable price list (1..3)
    FECHA1: TClarionDate;               // last movement
    FECHA2: TClarionDate;               // last payment
    [Size(10)] FECHA1S: string;
    [Size(10)] FECHA2S: string;

    [Decimal(17, 2)] MONTODEB: TAmount;
    [Decimal(17, 2)] MONTOCRE: TAmount;
    [Decimal(17, 2)] LIMITECRE: TAmount;
    [Indexed][Size(15)] CODVEN: string;
    DIASBLOQUEO: Integer;
    [Size(19)] TIPOCLI: string;         // free text; EMPTY in this install
    DIASCRE: Integer;
    [Decimal(7, 2)] PORRET: TRate;
    [Size(19)] TIPOPRO: string;
    [Decimal(17, 2)] ANTICIPOS: TAmount;
    [Size(15)] CODZON: string;
    [Size(40)] NUMFAX: string;
    [Size(60)] DIRCORREO: string;
    [Size(15)] CLASE: string;
    PERCREDITO: TFlag;
    [Size(20)] CUENTACON: string;
    [Size(20)] CUENTATER: string;
    CALCIMPUESTO: TFlag;
    [Size(120)] DIRECCALTERNA1: string;
    [Size(120)] DIRECCALTERNA2: string;
    [Decimal(5, 2)] PORRETIMP: TRate;
    CONESPECIAL: TFlag;                 // special taxpayer (withholds VAT)
    TIPOPROVEEDOR: TFlag;
    [Decimal(7, 2)] PORMAXDESPAR: TRate;
    [Decimal(7, 2)] PORMAXDESGLO: TRate;

    // ---- Clinic/gym block: irrelevant to sales, written as zeros ----
    SERFUMA: TFlag;
    SERALERGIAS: TFlag;
    SERDIABETES: TFlag;
    SERSIDA: TFlag;
    SERTENSIONBAJA: TFlag;
    SERTENSIONALTA: TFlag;
    SERASMA: TFlag;
    SERPROBLEMASRENALES: TFlag;
    SERINFARTO: TFlag;
    SEREPILEPSIA: TFlag;
    SERCANCER: TFlag;
    [Size(1)] SEROTROS1: string;
    [Size(1)] SEROTROS2: string;

    FECHANAC: TClarionDate;
    [Size(10)] SEXO: string;
    [Size(100)] FOTO: string;
    [Size(10)] PREFIJO_MOVIL: string;
    [Size(20)] NUMERO_MOVIL: string;
    MARKAR: TFlag;
    [Size(40)] NUMTELCONTACTO: string;
    [Size(40)] NOMBREGERENTE: string;
    [Size(40)] NUMTELGERENTE: string;
    FECNACCONTACTO: TClarionDate;
    FECNACGERENTE: TClarionDate;
    [Size(40)] TIPOCOMERCIO: string;
    [Size(60)] MENSAFACTURAR: string;
    [Size(40)] NOMBREEGEO1: string;
    [Size(40)] NOMBREEGEO2: string;
    [Size(40)] NOMBREEGEO3: string;
    [Size(40)] NOMBRE1: string;
    [Size(40)] NOMBRE2: string;
    [Size(40)] APELLIDO1: string;
    [Size(40)] APELLIDO2: string;
    [Size(10)] CODIGOPOSTAL: string;
    [Size(40)] NOMBREBAREMO: string;
    APLICADSTOFAC: TFlag;
    TIPOAFILIADO: TFlag;
    [Size(20)] CODIGOPAGADOR: string;
    SITAFILIADO: TFlag;
    INTEGRADO: TFlag;
    [Decimal(17, 2)] VALORIMPUESTOCR: TAmount;
    [Size(40)] NOMBREIMPUESTOCR: string;
    [Size(10)] CODIGOIMPUESTOCR: string;
  end;

implementation

end.
