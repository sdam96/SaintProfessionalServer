unit models.dcheader;

interface

uses
  attributes, models.types;

type
  // dcheader has no PRIMARY KEY. Keycpd01 UNIQUE (CONTROL) is the de facto
  // clustered index. Keycpd03 is UNIQUE (TIPREG, CODIGO, TIPTRAN, NUMREF,
  // NUMDOC, CONTROL) and does NOT guarantee NUMREF uniqueness.
  // TIPREG discriminates sales (1) from purchases (0) in the same table.
  TDCHeader = class
  public
    [PrimaryKey][NotNull][Size(19)] CONTROL: string;
    [Indexed] TIPREG: TFlag;
    [Indexed][Size(25)] CODIGO: string;
    [Indexed][Size(10)] TIPTRAN: string;
    [Size(30)] NUMREF: string;
    [Size(30)] NUMDOC: string;
    [Size(60)] DESCRIP1: string;
    [Size(60)] DESCRIP2: string;

    [Indexed] FECEMIS: TClarionDate;
    [Size(10)] FECEMISS: string;
    DIASVEN: Integer;
    FECVENC: TClarionDate;
    [Size(10)] FECVENCS: string;

    [Decimal(17, 2)] MONTOBRU: TAmount;
    [Decimal(17, 2)] MONTODES: TAmount;
    [Decimal(7, 2)]  PORDES: TRate;
    [Decimal(17, 2)] MONTOSUB: TAmount;
    [Decimal(17, 2)] MONTOIMP: TAmount;
    [Decimal(7, 2)]  PORIMP: TRate;
    [Decimal(17, 2)] MONTOPAG: TAmount;
    [Decimal(17, 2)] MONTOTOT: TAmount;
    [Decimal(17, 2)] MONTOSAL: TAmount;
    [Decimal(17, 2)] MONTOEFE: TAmount;
    [Decimal(17, 2)] MONTOCHE: TAmount;
    [Decimal(17, 2)] MONTOTAR: TAmount;

    [Size(20)] NUMCHE: string;
    [Size(20)] NUMTAR: string;
    [Size(100)] NOMBRE: string;
    [Indexed] MARCA: TFlag;
    CONTADOR: Integer;
    TOTCONTADOR: Integer;
    [Indexed][Size(19)] CONTROLDOC: string;
    [Decimal(17, 2)] MONTOPAGF: TAmount;
    [Size(25)] RIF: string;
    [Size(25)] NIT: string;
    [Decimal(17, 2)] MONTOCOS: TAmount;
    [Indexed] TIPODOC: TFlag;
    [Size(15)] CODTAR: string;
    [Decimal(17, 2)] CAMBIO: TAmount;
    [Size(20)] ODC: string;
    [Indexed][Size(15)] CODVEN: string;
    [Size(10)] NUMPRE: string;
    [Size(19)] TIPOCLI: string;
    [Size(19)] TIPOPRO: string;
    COMISV: TFlag;
    COMISC: TFlag;

    [Decimal(17, 2)] MONTORET: TAmount;
    [Decimal(7, 2)]  PORRET: TRate;
    [Decimal(17, 2)] MONTOPA: TAmount;
    [Decimal(17, 2)] COMISVEN: TAmount;
    [Decimal(17, 2)] COMISCOB: TAmount;

    [Size(120)] DIRECCION: string;
    [Size(3)] CODALREC: string;
    [Size(3)] CODALENT: string;
    [Size(15)] CODBANCO: string;
    [Indexed][Size(19)] CONTROLCH: string;
    ACTBANCO: TFlag;
    [Decimal(17, 2)] MONTODESCUENTO: TAmount;
    [Indexed] MARCARE: TFlag;
    HORA: TClarionTime;
    [Decimal(17, 2)] MONTOMANEJO: TAmount;
    [Decimal(17, 2)] MONTOINTERES: TAmount;
    GIROS: TFlag;
    [Decimal(17, 2)] MONTOGIROS: TAmount;

    [Size(19)] CONTROLDEV: string;
    [Size(20)] NUMREFDEV: string;
    [Size(15)] CODDEV: string;
    DEVUELTA: TFlag;
    [Size(10)] CODUSER: string;
    [Size(19)] CONTROLGIR: string;

    [Decimal(17, 2)] TOTALEXENTAS: TAmount;
    [Decimal(17, 2)] BASEIMPONIBLE: TAmount;
    [Size(15)] CODRET: string;
    OTRAPLAZA: TFlag;
    [Decimal(17, 2)] BASEIMPONIBLEIVA: TAmount;
    [Decimal(7, 2)]  FACTORCAMBIO: TRate;
    [Size(15)] SIGNOMONEDA: string;
    [Decimal(5, 2)]  PORRETIMP: TRate;
    [Decimal(17, 2)] MONTORETIMP: TAmount;
    [Size(20)] NROCONTROLDOC: string;
    [Size(10)] NROCOMRET: string;

    [Decimal(17, 2)] MONTOINSTRU1: TAmount;
    [Size(20)] NUMINSTRU1: string;
    [Size(15)] CODBANINSTRU1: string;
    [Size(15)] CODTARINSTRU1: string;
    [Decimal(17, 2)] MONTOINSTRU2: TAmount;
    [Size(20)] NUMINSTRU2: string;
    [Size(15)] CODBANINSTRU2: string;
    [Size(15)] CODTARINSTRU2: string;
    FUNCION1: TFlag;
    FUNCION2: TFlag;

    [Decimal(17, 2)] MONTOIMP2: TAmount;
    [Decimal(7, 2)]  PORIMP2: TRate;
    [Decimal(17, 2)] MONTOIMP3: TAmount;
    [Decimal(7, 2)]  PORIMP3: TRate;

    [Size(15)] CODCOB: string;
    [Indexed][Size(10)] NROCONTRATO: string;
    [Indexed][Size(60)] CENTROCOSTO: string;

    [Size(50)] NOMPACIENTE: string;
    [Size(20)] CEDPACIENTE: string;
    [Size(50)] DIRPACIENTE: string;
    AFECTALIBRO: TFlag;
    COMORETIMP: TFlag;
    [Size(20)] CEDTIT: string;
    [Size(50)] NOMTIT: string;
    [Decimal(17, 2)] MONTOAPAGARPAC: TAmount;
    [Size(10)] IDCAJERO: string;
    [Size(30)] NOMMED: string;
    [Size(10)] NROCLAVE: string;
    FECHAENTREGA: TClarionDate;

    [Decimal(17, 2)] TEMP_BASE_IMP: TAmount;
    [Decimal(7, 2)]  TEMP_PORIMP: TRate;

    [Size(19)] MODELOIMP: string;
    [Size(19)] SERIALIMP: string;
    COM_FISCAL: Integer;
    COM_FISCAL_Z: Integer;
    [Size(30)] NROCONTROLCOMPRA: string;
    [Decimal(17, 2)] MONTOFLETE: TAmount;
    [Indexed][Size(30)] OPERACIONES: string;
    FECULTIMOPAGO: TClarionDate;
    FUNCIONTAR: TFlag;
    FUNCIONINSTRU1: TFlag;
    FUNCIONINSTRU2: TFlag;
    [Indexed][Size(29)] IDTABLAADICIONAL: string;

    [Decimal(15, 0)] KILOMETROS: Int64;
    DIASPROXREVIS: Integer;
    FECPROXREVIS: TClarionDate;

    DIASFIN1: TFlag;
    [Decimal(5, 2)] PORFIN1: TRate;
    DIASFIN2: TFlag;
    [Decimal(5, 2)] PORFIN2: TRate;
    DIASFIN3: TFlag;
    [Decimal(5, 2)] PORFIN3: TRate;
    [Decimal(17, 2)] MONTONCTRANSITO: TAmount;

    [Size(40)] DIRECCION2: string;
    [Size(40)] TELEFCLIEV: string;
    [Size(15)] CODRESPCOMP: string;
    [Size(40)] NOMRESPCOMP: string;
    [Size(25)] DESDEMODULO: string;
    [Size(10)] TIPOFACTURA: string;
    FECDOCORIG: TClarionDate;
    FECVENCDOCORIG: TClarionDate;
    [Size(20)] NROSINIESTRO: string;
    TIPOREGIMEN: TFlag;
    CODCLI: Integer;

    [Size(20)] NROAUTORIZA: string;
    FECHAAUTORIZA: TClarionDate;
    [Size(20)] NROPTOEMISION: string;
    [Size(20)] NROFACTURARD: string;
    [Decimal(17, 2)] MONTORECARGO: TAmount;
    [Size(40)] NUMEROSRI: string;
    FECHASRI: TClarionDate;
    FECHAVENCESRI: TClarionDate;
    [Size(20)] NROSERIE: string;
    [Size(20)] CORTEX: string;
    [Decimal(7, 2)] PORFLETE: TRate;
    FECHAEMISIONCOMPRA: TClarionDate;

    [Decimal(7, 2)]  PORIMPR: TRate;
    [Decimal(17, 2)] MONTOIMPR: TAmount;
    [Decimal(7, 2)]  PORIMPL: TRate;
    [Decimal(17, 2)] MONTOIMPL: TAmount;
    [Decimal(17, 2)] BASEIMPONIBLER: TAmount;
    [Decimal(17, 2)] BASEIMPONIBLEL: TAmount;

    [Decimal(17, 2)] BASEPARARET_ISLR: TAmount;
    [Decimal(17, 2)] SUSTRAENDOPARARET_ISLR: TAmount;
    [Size(15)] CODRET_OTR1: string;
    [Decimal(17, 2)] BASEPARARET_OTR1: TAmount;
    [Decimal(17, 2)] MONTORET_OTR1: TAmount;
    [Decimal(17, 2)] PORCENTAJERET_OTR1: TAmount;
    [Decimal(17, 2)] SUSTRAENDOPARARET_OTR1: TAmount;
    [Decimal(17, 2)] TOTALMONTORET_OTR1: TAmount;
    [Size(15)] CODRET_OTR2: string;
    [Decimal(17, 2)] BASEPARARET_OTR2: TAmount;
    [Decimal(17, 2)] MONTORET_OTR2: TAmount;
    [Decimal(17, 2)] PORCENTAJERET_OTR2: TAmount;
    [Decimal(17, 2)] SUSTRAENDOPARARET_OTR2: TAmount;
    [Decimal(17, 2)] TOTALMONTORET_OTR2: TAmount;

    [Size(15)] IdGrupoComandas: string;

    [Decimal(17, 2)] MONTOIMP4: TAmount;
    [Decimal(7, 2)]  PORIMP4: TRate;
    [Decimal(17, 2)] BASEIMPONIBLE4: TAmount;
    [Decimal(17, 2)] MONTOIMP5: TAmount;
    [Decimal(7, 2)]  PORIMP5: TRate;
    [Decimal(17, 2)] BASEIMPONIBLE5: TAmount;
    [Decimal(17, 2)] MONTOIMP6: TAmount;
    [Decimal(7, 2)]  PORIMP6: TRate;
    [Decimal(17, 2)] BASEIMPONIBLE6: TAmount;
    [Decimal(17, 2)] MONTOIMP7: TAmount;
    [Decimal(7, 2)]  PORIMP7: TRate;
    [Decimal(17, 2)] BASEIMPONIBLE7: TAmount;
    [Decimal(17, 2)] MONTOIMP8: TAmount;
    [Decimal(7, 2)]  PORIMP8: TRate;
    [Decimal(17, 2)] BASEIMPONIBLE8: TAmount;
    [Decimal(17, 2)] MONTOIMP9: TAmount;
    [Decimal(7, 2)]  PORIMP9: TRate;
    [Decimal(17, 2)] BASEIMPONIBLE9: TAmount;
  end;

implementation

end.
