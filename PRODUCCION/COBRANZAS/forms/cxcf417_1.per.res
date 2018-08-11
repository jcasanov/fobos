DATABASE FORMONLY
SCREEN
{

          Moneda: [c0] [c001            ]   Rango: [c002      ] - [c003      ]

  C�digo Cliente: [c004  ] [c005                                             ]

 Area de Negocio: [c006  ] [c007                          ]
    Tipo Cliente: [c008  ] [c009                          ]
    Tipo Cartera: [c010  ] [c011                          ]

       Localidad: [c012  ] [c013                          ]

      Zona Venta: [c014  ] [c015                          ]

      Zona Cobro: [c016  ] [c017                          ]

        Cobrador: [c020  ] [c021                          ]

}   
ATTRIBUTES
c0   = FORMONLY.moneda TYPE CHAR NOT NULL, UPSHIFT, AUTONEXT, REQUIRED, REVERSE,
	WIDGET = "FIELD_BMP", CONFIG = "lista.bmp F2", REVERSE;
c001 = FORMONLY.tit_mon, NOENTRY, REVERSE;
c002 = FORMONLY.fecha_ini TYPE DATE NOT NULL, REQUIRED, AUTONEXT, UPSHIFT,
	REVERSE, FORMAT = 'dd-mm-yyyy',
	COMMENTS = 'Fecha Inicial en que se realiz� la cobranza. (dd-mm-yyyy)';
c003 = FORMONLY.fecha_fin TYPE DATE NOT NULL, REQUIRED, AUTONEXT, UPSHIFT,
	REVERSE, FORMAT = 'dd-mm-yyyy',
	COMMENTS = 'Fecha Final en que se realiz� la cobranza. (dd-mm-yyyy)';

c004 = FORMONLY.codcli, UPSHIFT, AUTONEXT,
	WIDGET = 'FIELD_BMP', CONFIG = 'lista.bmp F2';
c005 = FORMONLY.nomcli, UPSHIFT, NOENTRY;

c006 = FORMONLY.area_n TYPE SMALLINT, AUTONEXT, WIDGET = "FIELD_BMP", 
       CONFIG="lista.bmp F2", COLOR = RED BLINK WHERE a = 0;
c007 = FORMONLY.tit_area, NOENTRY;
c008 = FORMONLY.tipcli TYPE SMALLINT, WIDGET = 'FIELD_BMP', 
       CONFIG = 'lista.bmp F2';
c009 = FORMONLY.tit_tipcli, NOENTRY;
c010 = FORMONLY.tipcar TYPE SMALLINT, WIDGET = 'FIELD_BMP', 
       CONFIG = 'lista.bmp F2';
c011 = FORMONLY.tit_tipcar, NOENTRY;

c012 = FORMONLY.localidad, UPSHIFT, AUTONEXT,
	WIDGET = 'FIELD_BMP', CONFIG = 'lista.bmp F2';
c013 = FORMONLY.tit_localidad, UPSHIFT, NOENTRY;

c014 = FORMONLY.zona_venta, UPSHIFT, AUTONEXT,
	WIDGET = 'FIELD_BMP', CONFIG = 'lista.bmp F2';
c015 = FORMONLY.tit_zona_venta, UPSHIFT, NOENTRY;

c016 = FORMONLY.zona_cobro, UPSHIFT, AUTONEXT,
	WIDGET = 'FIELD_BMP', CONFIG = 'lista.bmp F2';
c017 = FORMONLY.tit_zona_cobro, UPSHIFT, NOENTRY;

c020 = FORMONLY.cobrador, UPSHIFT, AUTONEXT,
	WIDGET = 'FIELD_BMP', CONFIG = 'lista.bmp F2';
c021 = FORMONLY.tit_cobrador, UPSHIFT, NOENTRY;
END
INSTRUCTIONS
DELIMITERS '||'
