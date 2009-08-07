------------------------------------------------------------------------------
-- Titulo           : repp426.4gl - Nota de pedido
-- Elaboracion      : 08-MAR-2002
-- Autor            : GVA
-- Formato Ejecucion: fglrun repp426 base módulo compañía localidad [pedido]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_rep		RECORD LIKE rept016.*
DEFINE rm_cia		RECORD LIKE gent001.*

DEFINE partida_aux	LIKE gent016.g16_partida

DEFINE subtotal_cant	LIKE rept017.r17_cantped
DEFINE subtotal_peso	DECIMAL(9,3)
DEFINE subtotal_fob	DECIMAL(14,2)

DEFINE total_cant	LIKE rept017.r17_cantped
DEFINE total_peso	DECIMAL(9,3)
DEFINE total_fob	DECIMAL(14,2)

DEFINE vm_num_partida	SMALLINT	

DEFINE nom_diteca 	LIKE gent001.g01_razonsocial
DEFINE nom_diteca_2 	LIKE gent001.g01_razonsocial
DEFINE nom_diteca_3 	LIKE gent001.g01_razonsocial
DEFINE tel_diteca 	LIKE gent002.g02_telefono1
DEFINE fax_diteca 	LIKE gent002.g02_fax1
DEFINE contact_1 	VARCHAR(25)
DEFINE contact_2 	VARCHAR(25)

DEFINE nom_proveedor 	LIKE cxpt001.p01_nomprov
DEFINE tel_proveedor 	LIKE cxpt001.p01_telefono1
DEFINE fax_proveedor 	LIKE cxpt001.p01_fax1

DEFINE embarque_1	VARCHAR(20)
DEFINE embarque_2	VARCHAR(20)
DEFINE pago		VARCHAR(20)

DEFINE declaracion_consular 	VARCHAR(1000)
DEFINE flete			DECIMAL(12,2)
DEFINE seguro			DECIMAL(12,2)


MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 THEN   -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'repp426'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
OPEN WINDOW w_mas AT 3,2 WITH 23 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_rep FROM "../forms/repf426_1"
DISPLAY FORM f_rep
CALL borrar_cabecera()
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE i,col		SMALLINT
DEFINE query		VARCHAR(1000)
DEFINE comando		VARCHAR(100)

DEFINE toFile		SMALLINT
DEFINE resp		CHAR(6)

DEFINE r_report 	RECORD
	partida 	LIKE gent016.g16_partida,
	nom_partida 	LIKE gent016.g16_nombre,
	cant		LIKE rept017.r17_cantped,
	item		LIKE rept017.r17_item,
	nombre		LIKE rept010.r10_nombre,
	peso		DECIMAL(9,3),
	fob		DECIMAL(14,2),
	tot_fob		DECIMAL(14,2)
	END RECORD

INITIALIZE contact_1, contact_2, nom_proveedor, tel_proveedor, fax_proveedor,
		nom_diteca_2, nom_diteca_3, tel_diteca, fax_diteca,
		flete, seguro TO NULL

LET nom_diteca   = rg_cia.g01_razonsocial
LET nom_diteca_2 = rg_loc.g02_nombre
LET nom_diteca_3 = rg_loc.g02_nombre
LET tel_diteca   = rg_loc.g02_telefono1
LET fax_diteca   = rg_loc.g02_fax1

LET declaracion_consular = 'Estas mercaderías viajan por cuenta y riesgo del comprador, cesando la responsabilidad del vendedor al obtener el conocimiento de embarque firmado sin anotaciones. El vendedor no asume ninguna responsabilidad sobre las declaraciones consulares. El vendedor no es responsable por atrasos, falta o deterioros ocasionados por guerra, incendio, inundaciones, huelga o cualquier otro incidente de fuerza mayor.- Esta orden esta sujeta a la confirmación del vendedor después de confirmada no se puede hacer ningun cambio sin conocimiento de ambas partes.'

WHILE TRUE
	INITIALIZE partida_aux TO NULL
	LET subtotal_cant = 0
	LET subtotal_peso = 0
	LET subtotal_fob  = 0

	LET total_cant = 0
	LET total_peso = 0
	LET total_fob  = 0

	LET vm_num_partida = 1

	IF num_args() = 4 THEN
		CALL lee_parametros()
		IF int_flag THEN
			EXIT WHILE
		END IF
	ELSE
		LET rm_rep.r16_pedido = arg_val(5)
	END IF
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		IF num_args() = 3 THEN
			CONTINUE WHILE
		ELSE
			EXIT WHILE
		END IF
	END IF

	LET query = 'SELECT r10_partida, g16_nombre, r17_cantped, r17_item, ',
			' r10_nombre, r17_cantped * r10_peso, r17_fob, ',
			' r17_cantped * r17_fob ',
			'FROM rept017, rept010, gent016 ',
			'WHERE r17_compania  = ', vg_codcia,
			'  AND r17_localidad = ', vg_codloc,
			'  AND r17_pedido    = "', rm_rep.r16_pedido, '"',
			'  AND r17_compania  = r10_compania ',
			'  AND r17_item      = r10_codigo ',
			'  AND r10_partida   = g16_partida ',
			'ORDER BY r10_partida'

	PREPARE deto FROM query
	DECLARE q_deto CURSOR FOR deto
	OPEN q_deto
	FETCH q_deto
	IF STATUS = NOTFOUND THEN
		CLOSE q_deto
		CALL fl_mensaje_consulta_sin_registros()
		IF num_args() = 4 THEN
			EXIT WHILE
		END IF
		CONTINUE WHILE
	END IF
	CLOSE q_deto

	LET toFile = 0
	FOR i=1 TO LENGTH(comando)
		IF comando[i, i+4] = 'cat >' THEN
			LET toFile = 1
			EXIT FOR
		END IF 
	END FOR

	IF toFile = 1 THEN
		CALL fgl_winquestion(vg_producto,
		       '¿Desea preparar el archivo para exportar a Excel?',
		       'Yes','Yes|No','question',1)
		RETURNING resp
		IF resp = 'Yes' THEN
			START REPORT export_nota_pedido TO PIPE comando
			FOREACH q_deto INTO r_report.*
				OUTPUT TO REPORT export_nota_pedido(r_report.*)
			END FOREACH
			FINISH REPORT export_nota_pedido
		
			LET comando = comando[7, 100]

			RUN 'unix2dos ' || comando

			IF num_args() = 5 THEN
				EXIT WHILE
			END IF
			CONTINUE WHILE
		END IF
	END IF

	START REPORT report_nota_pedido TO PIPE comando
	FOREACH q_deto INTO r_report.*
		OUTPUT TO REPORT report_nota_pedido(r_report.*)
	END FOREACH
	FINISH REPORT report_nota_pedido
	IF num_args() = 5 THEN
		EXIT WHILE
	END IF
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_rep		RECORD LIKE rept016.*
DEFINE codpe_aux	LIKE rept016.r16_pedido
DEFINE r_prov		RECORD LIKE cxpt001.*
DEFINE r_prov_loc	RECORD LIKE cxpt002.*

OPTIONS INPUT NO WRAP
INITIALIZE r_rep.*, codpe_aux TO NULL
LET int_flag = 0
INPUT BY NAME rm_rep.r16_pedido, nom_diteca, tel_diteca, fax_diteca, contact_1,
		nom_proveedor, tel_proveedor, fax_proveedor, contact_2,
		flete, seguro,
		embarque_1, nom_diteca_2, pago, embarque_2, nom_diteca_3,
		declaracion_consular
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
	ON KEY(F2)
		IF infield(r16_pedido) THEN
			CALL fl_ayuda_pedidos_rep(vg_codcia, vg_codloc, 'T','T')
				RETURNING codpe_aux
			OPTIONS INPUT NO WRAP
			LET int_flag = 0
			IF codpe_aux IS NOT NULL THEN
				LET rm_rep.r16_pedido = codpe_aux
				DISPLAY BY NAME rm_rep.r16_pedido
			END IF
		END IF
	AFTER FIELD r16_pedido
		IF rm_rep.r16_pedido IS NOT NULL THEN
			CALL fl_lee_pedido_rep(vg_codcia,vg_codloc,
						rm_rep.r16_pedido)
				RETURNING r_rep.*
			IF r_rep.r16_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Pedido no existe.','exclamation')
				NEXT FIELD r16_pedido
			END IF
			DISPLAY BY NAME r_rep.r16_pedido
			CALL fl_lee_proveedor(r_rep.r16_proveedor)
				RETURNING r_prov.*
			LET nom_proveedor = r_prov.p01_nomprov
			LET tel_proveedor = r_prov.p01_telefono1
			LET fax_proveedor = r_prov.p01_fax1
			CALL fl_lee_proveedor_localidad(vg_codcia, 
						vg_codloc,r_rep.r16_proveedor)
				RETURNING r_prov_loc.*
			LET contact_2 = r_prov_loc.p02_contacto
			DISPLAY BY NAME nom_proveedor, tel_proveedor, 
					fax_proveedor, contact_2
		END IF
	AFTER INPUT 
		IF nom_diteca IS NULL THEN
			NEXT FIELD nom_diteca
		END IF 
		IF tel_diteca IS NULL THEN
			NEXT FIELD tel_diteca
		END IF 
		IF fax_diteca IS NULL THEN
			NEXT FIELD fax_diteca
		END IF 
		IF contact_1 IS NULL THEN
			NEXT FIELD contact_1
		END IF 
		IF nom_proveedor IS NULL THEN
			NEXT FIELD nom_proveedor
		END IF 
		IF tel_proveedor IS NULL THEN
			NEXT FIELD tel_proveedor
		END IF
		IF fax_proveedor IS NULL THEN
			NEXT FIELD fax_proveedor
		END IF
		IF contact_2 IS NULL THEN
			NEXT FIELD contact_2
		END IF 
		IF embarque_1 IS NULL THEN
			NEXT FIELD embarque_1
		END IF
		IF nom_diteca_2 IS NULL THEN
			NEXT FIELD nom_diteca_2
		END IF
		IF embarque_2 IS NULL THEN
			NEXT FIELD embarque_2
		END IF
		IF nom_diteca_3 IS NULL THEN
			NEXT FIELD nom_diteca_3
		END IF
		IF declaracion_consular IS NULL THEN
			NEXT FIELD declaracion_consular
		END IF
		IF flete IS NULL THEN
			NEXT FIELD flete
		END IF
		IF seguro IS NULL THEN
			NEXT FIELD seguro
		END IF
END INPUT

END FUNCTION



REPORT report_nota_pedido(partida, nom_partida, cant, item, nombre,
		 	  peso, fob, tot_fob)
DEFINE partida		LIKE gent016.g16_partida
DEFINE nom_partida	LIKE gent016.g16_nombre
DEFINE cant		LIKE rept017.r17_cantped
DEFINE item		LIKE rept010.r10_codigo
DEFINE nombre		LIKE rept010.r10_nombre
DEFINE peso		DECIMAL(7,3)
DEFINE fob		DECIMAL(11,2)
DEFINE tot_fob		DECIMAL(12,2)

DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i,long		SMALLINT
DEFINE r_pro		RECORD LIKE cxpt001.*
DEFINE tipo_des		VARCHAR(10)
DEFINE estado		VARCHAR(10)
DEFINE proveedor	VARCHAR(50)
DEFINE r_rep		RECORD LIKE rept016.*
DEFINE mes 		CHAR(12)

OUTPUT
	TOP MARGIN	0
	LEFT MARGIN	10
	RIGHT MARGIN	120
	BOTTOM MARGIN	4
	PAGE LENGTH	66
FORMAT
PAGE HEADER
	print 'E'; print '&l26A';  -- Indica que voy a trabajar con hojas A4
	print '&k4S'	                -- Letra condensada (12 cpi)

	CALL fl_justifica_titulo('C', 'NOTA DE PEDIDO', 80)
		RETURNING titulo
	PRINT COLUMN 1, titulo CLIPPED

	print '&k2S'	                -- Letra condensada (16 cpi)

	LET mes = fl_retorna_nombre_mes(MONTH(TODAY))
	PRINT COLUMN 1, 'No Pedido: ', rm_rep.r16_pedido, 
		COLUMN 50,fl_justifica_titulo('I',mes,10),
			1 SPACES, TODAY USING "dd-mm-yyyy", 1 SPACES, TIME,
		COLUMN 98, 'Página: ', PAGENO USING '&&&' 

	SKIP 1 LINES

	PRINT COLUMN 1, 'De: ', nom_diteca
	PRINT COLUMN 1, 'Teléfono: ', tel_diteca,
	      COLUMN 50, 'Fax: ', fax_diteca,
	      COLUMN 75, 'Contact: ', contact_1 
	PRINT COLUMN 1, 'Para: ', nom_proveedor
	PRINT COLUMN 1, 'Teléfono: ', tel_proveedor, 
	      COLUMN 50, 'Fax: ', fax_proveedor,
	      COLUMN 75, 'Contact: ', contact_2 
	PRINT COLUMN 1, 'Embarque: ', embarque_1
	PRINT COLUMN 1, 'Documento a la orden de: ', nom_diteca_2
	PRINT COLUMN 1, 'Pago: ', pago
	PRINT COLUMN 1, 'Embarque: ', embarque_2
	PRINT COLUMN 1, 'Marcas y números: ', nom_diteca_3
	PRINT COLUMN 1, 'Declaración consular: '
	NEED 10 LINES
	PRINT COLUMN 1, declaracion_consular[1,107]
	PRINT COLUMN 1, declaracion_consular[108,215]
	PRINT COLUMN 1, declaracion_consular[216,323]
	PRINT COLUMN 1, declaracion_consular[324,431]
	PRINT COLUMN 1, declaracion_consular[432,539]
	PRINT COLUMN 1, declaracion_consular[540,647]
	PRINT COLUMN 1, declaracion_consular[648,755]

	PRINT "============================================================================================================"
	PRINT COLUMN 4,  "Cant.",
	      COLUMN 13, "Item",
	      COLUMN 26, "Descripciòn Item",
	      COLUMN 52, "Peso Kg.",
	      COLUMN 70, "Precio Unit.",
	      COLUMN 98, "FOB Total"
	PRINT "============================================================================================================"

ON EVERY ROW

	NEED 5 LINES
	IF partida_aux IS NULL THEN
		LET partida_aux = partida

		PRINT COLUMN 1, vm_num_partida USING '&&',". ARANCELARIA",
			COLUMN 39, partida,
			COLUMN 56, nom_partida
	ELSE
		IF partida_aux <> partida THEN
			NEED 2 LINES

			LET partida_aux = partida
			PRINT COLUMN 1,  '------',
		   	      COLUMN 48, '-----------',
		              COLUMN 93, '----------------'
			PRINT COLUMN 1,  subtotal_cant,
			      COLUMN 26, 'PESO APROXIMADO ',
		   	      COLUMN 47, subtotal_peso USING '###,##&.###',
			      COLUMN 65, 'PRECIO FOB, US $ ',
		              COLUMN 93, subtotal_fob USING '#,###,###,##&.##'
			
			LET subtotal_cant = 0
			LET subtotal_peso = 0
			LET subtotal_fob  = 0
			
			SKIP 1 LINES

			LET vm_num_partida = vm_num_partida + 1

			NEED 3 LINES
			PRINT COLUMN 1, vm_num_partida USING '&&',
					". ARANCELARIA",
				COLUMN 39, partida,
				COLUMN 56, nom_partida
		END IF

	END IF 

	PRINT COLUMN 1,  cant, --fl_justifica_titulo('C', cant, 4), 
	      COLUMN 8,  fl_justifica_titulo('D',item,15),
	      COLUMN 26, nombre[1,20],
	      COLUMN 48, peso               USING '##,##&.###',
	      COLUMN 65, fob    	    USING "###,###,##&.##",
	      COLUMN 93, tot_fob            USING "#,###,###,##&.##"

	LET subtotal_cant = subtotal_cant + cant
	LET subtotal_peso = subtotal_peso + peso
	LET subtotal_fob  = subtotal_fob  + tot_fob
	
	LET total_cant = total_cant + cant 
	LET total_peso = total_peso + peso 
	LET total_fob  = total_fob  + tot_fob 

ON LAST ROW

	NEED 2 LINES
	PRINT COLUMN 1,  '------',
	      COLUMN 48, '-----------',
	      COLUMN 93, '----------------'
	PRINT COLUMN 1,  subtotal_cant,
	      COLUMN 26, 'PESO APROXIMADO ',
	      COLUMN 47, subtotal_peso USING '###,##&.###',
	      COLUMN 65, 'PRECIO FOB, US $ ',
	      COLUMN 93, subtotal_fob USING '#,###,###,##&.##'
	print '&k4S'	                -- Letra condensada (12 cpi)
	SKIP 1 LINES

	NEED 10 LINES
	PRINT COLUMN 17, 'TOTAL KG. ',
		COLUMN 47, fl_justifica_titulo('D',total_peso,16)
				USING '###,##&.###'
	PRINT COLUMN 17, 'TOTAL UNIDADES ',
		COLUMN 42, fl_justifica_titulo('D',total_cant,16) 

	SKIP 1 LINES

	PRINT COLUMN 17, 'VALOR FOB ',
		COLUMN 42, fl_justifica_titulo('D',total_fob,16) 
				USING '#,###,###,##&.##'
	PRINT COLUMN 17, 'FLETE ',
		COLUMN 42, fl_justifica_titulo('D',flete,16) 
	PRINT COLUMN 42, '----------------'
	PRINT COLUMN 17, 'VALOR C&F ',
		COLUMN 42, fl_justifica_titulo('D',total_fob + flete,16) 
				USING '#,###,###,##&.##'
	PRINT COLUMN 17, 'SEGURO ', 
		COLUMN 42, fl_justifica_titulo('D',seguro,16) 
				USING '#,###,###,##&.##'
	PRINT COLUMN 42, '----------------'
	PRINT COLUMN 17, 'TOTAL VALOR C.I.F.',
		COLUMN 42, total_fob + flete + seguro
				USING '#,###,###,##&.##'

END REPORT



REPORT export_nota_pedido(partida, nom_partida, cant, item, nombre,
		 	  peso, fob, tot_fob)
DEFINE partida		LIKE gent016.g16_partida
DEFINE nom_partida	LIKE gent016.g16_nombre
DEFINE cant		LIKE rept017.r17_cantped
DEFINE item		LIKE rept010.r10_codigo
DEFINE nombre		LIKE rept010.r10_nombre
DEFINE peso		DECIMAL(7,3)
DEFINE fob		DECIMAL(11,2)
DEFINE tot_fob		DECIMAL(12,2)

DEFINE i,long		SMALLINT
DEFINE r_pro		RECORD LIKE cxpt001.*
DEFINE tipo_des		VARCHAR(10)
DEFINE estado		VARCHAR(10)
DEFINE proveedor	VARCHAR(50)
DEFINE r_rep		RECORD LIKE rept016.*
DEFINE mes 		CHAR(12)

OUTPUT
	TOP MARGIN	0
	LEFT MARGIN	10
	RIGHT MARGIN	120
	BOTTOM MARGIN	4
	PAGE LENGTH	66
FORMAT

ON EVERY ROW
	IF partida_aux IS NULL THEN
		LET partida_aux = partida

		PRINT COLUMN 1, vm_num_partida USING '&&', '. ARANCELARIA |',
			        partida, '|', nom_partida
	ELSE

		IF partida_aux <> partida THEN
			SKIP 1 LINES
			LET partida_aux = partida
			LET vm_num_partida = vm_num_partida + 1

			PRINT COLUMN 1, vm_num_partida USING '&&', 
                                        '. ARANCELARIA |',
				        partida, '|', nom_partida
		END IF
	END IF 

	PRINT COLUMN 1,  cant, 
	      '|',       fl_justifica_titulo('D',item,15),
	      '|',       nombre[1,20],
	      '|',       peso               USING '##,##&.###',
	      '|',       fob    	    USING "###,###,##&.##",
	      '|',       tot_fob            USING "#,###,###,##&.##"

END REPORT



FUNCTION borrar_cabecera()

CLEAR r16_pedido
INITIALIZE rm_rep.* TO NULL

END FUNCTION



FUNCTION retorna_estado(estado)
DEFINE estado		LIKE rept016.r16_estado
                                                                                
IF estado = 'A' THEN
        RETURN 'ACTIVO'
END IF
IF estado = 'C' THEN
        RETURN 'CONFIRMADO'
END IF
IF estado = 'R' THEN
        RETURN 'RECIBIDO'
END IF
IF estado = 'L' THEN
        RETURN 'LIQUIDADO'
END IF
IF estado = 'P' THEN
        RETURN 'PROCESADO'
END IF

END FUNCTION



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
	LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc, 'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
