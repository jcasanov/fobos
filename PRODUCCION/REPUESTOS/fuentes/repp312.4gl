------------------------------------------------------------------------------
-- Titulo           : repp312.4gl - Consulta de ventas a clientes
-- Elaboracion      : 29-abr-2002
-- Autor            : GVA
-- Formato Ejecucion: fglrun repp312 base módulo compañía localidad
-- Ultima Correccion:
-- Motivo Correccion:
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_moneda	LIKE gent013.g13_moneda
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE vm_bodega	LIKE rept011.r11_bodega

DEFINE vm_tipcli	CHAR(1)

DEFINE rm_g13		RECORD LIKE gent013.*


DEFINE r_detalle	ARRAY[1000] OF RECORD
	r19_codcli	LIKE rept019.r19_codcli,
	r19_nomcli	LIKE rept019.r19_nomcli,
	r19_tot_neto	LIKE rept019.r19_tot_neto
	END RECORD



MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN

CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()

IF num_args() <> 4 THEN   -- Validar # parámetros correcto
        CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 'st
op')
        EXIT PROGRAM
END IF

LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)

LET vg_proceso = 'repp312'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
--CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)


CALL fl_nivel_isolation()
OPEN WINDOW w_312 AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0, BORDER,
              MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
        ACCEPT KEY      F12
OPEN FORM f_repf312 FROM "../forms/repf312_1"
DISPLAY FORM f_repf312

INITIALIZE vm_fecha_ini, vm_fecha_fin, vm_bodega, vm_moneda TO NULL

LET vm_fecha_fin = TODAY
LET vm_moneda	 = rg_gen.g00_moneda_base
LET vm_tipcli    = 'C'

CALL fl_lee_moneda(vm_moneda) 	RETURNING rm_g13.* 
DISPLAY rm_g13.g13_nombre TO nom_moneda

DISPLAY 'Codigo'        TO tit_col1
DISPLAY 'Nombre' 	TO tit_col2
DISPLAY 'Total'		TO tit_col3

WHILE TRUE
	CALL funcion_master()
END WHILE

END MAIN




FUNCTION funcion_master()

DEFINE r_r02 		RECORD LIKE rept002.*		--BODEGAS

INITIALIZE r_r02.* TO NULL

LET int_flag = 0

INPUT BY NAME vm_fecha_ini, vm_fecha_fin, vm_moneda, vm_bodega, vm_tipcli
	      WITHOUT DEFAULTS

	ON KEY(INTERRUPT)
		IF NOT field_touched(vm_bodega, vm_fecha_ini, vm_fecha_fin, 
				     vm_moneda, vm_tipcli)
		   THEN
			EXIT PROGRAM
		ELSE
			RETURN
		END IF

	ON KEY(F2)

		IF INFIELD(vm_bodega) THEN
			CALL fl_ayuda_bodegas_rep(vg_codcia, NULL, 'T')
				RETURNING r_r02.r02_codigo, r_r02.r02_nombre
			IF r_r02.r02_codigo IS NOT NULL THEN
				LET vm_bodega = r_r02.r02_codigo
				DISPLAY BY NAME vm_bodega
				DISPLAY r_r02.r02_nombre TO nom_bodega
			END IF
		END IF

		IF INFIELD(vm_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING rm_g13.g13_moneda, rm_g13.g13_nombre,
					  rm_g13.g13_decimales
			IF rm_g13.g13_moneda IS NOT NULL THEN
				LET vm_moneda = rm_g13.g13_moneda
				DISPLAY BY NAME vm_moneda
				DISPLAY rm_g13.g13_nombre TO nom_moneda
			END IF
		END IF

		LET int_flag = 0

	AFTER FIELD vm_bodega
		IF vm_bodega IS NOT NULL THEN
			CALL fl_lee_bodega_rep(vg_codcia, vm_bodega)	
				RETURNING r_r02.*
			IF r_r02.r02_codigo IS NULL THEN
				CLEAR nom_bodega
				CALL fgl_winmessage(vg_producto, 'No existe la Bodega en la Compa¤¡a.', 'exclamation')
				NEXT FIELD vm_bodega
			ELSE 
				DISPLAY r_r02.r02_nombre TO nom_bodega
			END IF
		ELSE
			CLEAR nom_bodega
		END IF

	AFTER FIELD vm_moneda
		IF vm_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(vm_moneda)
				RETURNING rm_g13.*
			IF rm_g13.g13_moneda IS NULL THEN
				CLEAR nom_moneda 
				CALL fgl_winmessage(vg_producto, 'No existe la Moneda en la Compañia.','exclamation')
				NEXT FIELD vm_moneda
			ELSE
				DISPLAY rm_g13.g13_nombre TO nom_moneda
			END IF
		ELSE
			LET vm_moneda	 = rg_gen.g00_moneda_base
			CALL fl_lee_moneda(vm_moneda)
				RETURNING rm_g13.*
			DISPLAY BY NAME vm_moneda
			DISPLAY rm_g13.g13_nombre TO nom_moneda
		END IF
		
	AFTER INPUT 
		IF vm_fecha_ini IS NULL THEN
			NEXT FIELD vm_fecha_ini
		END IF
		IF vm_fecha_fin IS NULL THEN
			NEXT FIELD vm_fecha_fin
		END IF
		IF vm_fecha_ini > vm_fecha_fin THEN
			CALL fgl_winmessage(vg_producto,'La fecha inicial debe ser menor que la fecha final.','exclamation')
			NEXT FIELD vm_fecha_ini
		END IF

		CALL control_display_array()

END INPUT

END FUNCTION




FUNCTION control_display_array()
DEFINE expr_sql 	VARCHAR(1000)
DEFINE expr_bod 	VARCHAR(50)

DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE codcli		LIKE rept019.r19_codcli
DEFINE nomcli		LIKE rept019.r19_nomcli
DEFINE tot_neto		LIKE rept019.r19_tot_neto

DEFINE total_neto	LIKE rept019.r19_tot_neto

DEFINE i,j 		SMALLINT

DEFINE r_orden		ARRAY[3] OF CHAR(4)
DEFINE columna		SMALLINT

DISPLAY 'Código'        TO tit_col1
DISPLAY 'Total'		TO tit_col3
IF vm_tipcli = 'C' THEN
	DISPLAY 'Nombre' 	TO tit_col2
ELSE
	DISPLAY 'Tipo Cliente' 	TO tit_col2
END IF

LET expr_bod = ' '
IF vm_bodega IS NOT NULL THEN
	LET expr_bod = ' AND r19_bodega_ori = "',vm_bodega,'"'
END IF

LET expr_sql = 'SELECT r19_cod_tran, r19_codcli, r19_nomcli,',
			' SUM(r19_tot_neto) total',
			' FROM rept019 ',
			'WHERE r19_compania   =',vg_codcia,
			'  AND r19_localidad  =',vg_codloc,
			'  AND r19_cod_tran   IN ("FA","DF","AF")',
			'  AND r19_codcli     IS NOT NULL',
			'  AND DATE(r19_fecing) BETWEEN  "',vm_fecha_ini,'"',
			'  AND "',vm_fecha_fin,'"',
			expr_bod,
			' GROUP BY r19_cod_tran, r19_codcli, r19_nomcli',
			' INTO TEMP tmp_clientes'

PREPARE consulta FROM expr_sql
EXECUTE consulta

UPDATE tmp_clientes SET total = total * (-1) 
	WHERE r19_cod_tran IN ('DF','AF') 

LET columna = 3

LET r_orden[1] = 'DESC'
LET r_orden[2] = 'DESC'
LET r_orden[3] = 'DESC'


WHILE TRUE
	IF vm_tipcli = 'C' THEN
		LET expr_sql = prepare_query_clientes()
	ELSE
		LET expr_sql = prepare_query_tipo_clientes()
	END IF
	
	LET expr_sql = expr_sql CLIPPED || 
		       ' ORDER BY ',columna, ' ',r_orden[columna]

	PREPARE consulta_2 FROM expr_sql
	DECLARE q_consulta_2 CURSOR FOR consulta_2
	
	LET total_neto = 0
	LET i = 1
	FOREACH q_consulta_2 INTO r_detalle[i].*
		LET total_neto = total_neto + r_detalle[i].r19_tot_neto
		LET i = i + 1
		IF i > 999 THEN
			EXIT FOREACH
		END IF
	END FOREACH

	LET i = i - 1
	IF i = 0 THEN
		DROP TABLE tmp_clientes
		CALL fl_mensaje_consulta_sin_registros()
		RETURN
	END IF

	CALL set_count(i)
	DISPLAY ARRAY r_detalle TO r_detalle.*

		BEFORE DISPLAY 
			CALL dialog.keysetlabel('ACCEPT','')
			IF vm_tipcli = 'C' THEN
				CALL dialog.keysetlabel('F6', 'Estado Cuenta')
			ELSE
				CALL dialog.keysetlabel('F6', '')
			END IF
			CALL dialog.keysetlabel('F7','Imprimir')
			DISPLAY BY NAME total_neto

		BEFORE ROW
			LET j = arr_curr()
			DISPLAY '' AT 07,1
			DISPLAY j, ' de ', i AT 07,60  
	
		ON KEY(INTERRUPT)
			DISPLAY '' AT 07,1
			LET int_flag = 0
			DROP TABLE tmp_clientes
			RETURN

		ON KEY(F5)
			CALL control_ver_detalle_ventas(r_detalle[j].r19_codcli)
			LET int_flag = 0
		ON KEY(F6)
			CALL control_ver_estado_cuentas(r_detalle[j].r19_codcli)
			LET int_flag = 0
		ON KEY(F7) 
			CALL imprimir(i)
			LET int_flag = 0
		ON KEY(F15)
			LET columna = 1
			EXIT DISPLAY
		ON KEY(F16)
			LET columna = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET columna = 3
			EXIT DISPLAY

		AFTER DISPLAY
			CONTINUE DISPLAY
		
	END DISPLAY

	IF r_orden[columna] = 'ASC' THEN
		LET r_orden[columna] = 'DESC'
	ELSE
		LET r_orden[columna] = 'ASC'
	END IF 

END WHILE

END FUNCTION



FUNCTION control_ver_detalle_ventas(cliente)
DEFINE cliente		LIKE rept019.r19_codcli
DEFINE command_run 	VARCHAR(200)

LET command_run = 'fglrun repp309 ',vg_base,' ',vg_modulo,' ',
		  vg_codcia, ' ', vg_codloc,' ',vm_fecha_ini,' ',
		  vm_fecha_fin,' ', vm_tipcli, ' ', cliente,' ',vm_moneda
RUN command_run

END FUNCTION



FUNCTION control_ver_estado_cuentas(cliente)
DEFINE cliente		LIKE rept019.r19_codcli
DEFINE command_run 	VARCHAR(200)

LET command_run = 'cd ..',vg_separador,'..',vg_separador,'COBRANZAS',
		   vg_separador,'fuentes',vg_separador,';',
		  'fglrun cxcp305 ',vg_base, ' ','CO', ' ',
		  vg_codcia, ' ', vg_codloc, ' ',cliente, ' ',vm_moneda
RUN command_run

END FUNCTION



FUNCTION prepare_query_clientes()

DEFINE query		VARCHAR(1000)

LET query = 'SELECT r19_codcli, r19_nomcli, SUM(total) ', 
	    ' FROM tmp_clientes ',
	    ' GROUP BY r19_codcli, r19_nomcli ',
	    ' HAVING SUM(total) > 0 '

RETURN query CLIPPED

END FUNCTION



FUNCTION prepare_query_tipo_clientes()

DEFINE query		VARCHAR(1000)

LET query = 'SELECT z01_tipo_clte, g12_nombre, SUM(total) ', 
	    ' FROM tmp_clientes, cxct001, gent012 ',
	    ' WHERE z01_codcli   = r19_codcli ',
	    '   AND g12_tiporeg = "CL" ',
	    '   AND g12_subtipo  = z01_tipo_clte ',
	    ' GROUP BY z01_tipo_clte, g12_nombre ',
	    ' HAVING SUM(total) > 0 '

RETURN query CLIPPED

END FUNCTION


FUNCTION imprimir(maxelm)
DEFINE i		SMALLINT          
DEFINE maxelm		SMALLINT          
DEFINE comando		VARCHAR(100)

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN          
END IF

START REPORT rep_ventas_clientes TO PIPE comando 
	FOR i = 1 TO (maxelm - 1)
		OUTPUT TO REPORT rep_ventas_clientes(i)
	END FOR
FINISH REPORT rep_ventas_clientes

END FUNCTION



REPORT rep_ventas_clientes(numelm)
DEFINE numelm		SMALLINT
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i,long		SMALLINT
DEFINE fecha		DATE
DEFINE r_r02		RECORD LIKE rept002.*

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	2
	RIGHT MARGIN	90
	BOTTOM MARGIN	4
	PAGE LENGTH	66
FORMAT
PAGE HEADER
	print 'E'; print '&l26A';	-- Indica que voy a trabajar con hojas A4
	print '&k4S'	                -- Letra (12 cpi)
	LET modulo  = "Módulo: Repuestos"
	LET long    = LENGTH(modulo)
	LET usuario = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('I', 'CONSULTA DE VENTA A CLIENTES', 80)
		RETURNING titulo

	PRINT COLUMN 1, rg_cia.g01_razonsocial,
  	      COLUMN 120, "Página: ", PAGENO USING "&&&"
	PRINT COLUMN 1, modulo CLIPPED,
	      COLUMN 52, titulo CLIPPED,
	      COLUMN 124, "REPP312" 
	PRINT COLUMN 48, "** Moneda        : ", vm_moneda,
						" ", rm_g13.g13_nombre
	IF vm_bodega IS NULL THEN
		CALL fl_lee_bodega_rep(vg_codcia, vm_bodega) RETURNING r_r02.*
		PRINT COLUMN 48, "** Bodega        : ", vm_bodega, 
							" ", r_r02.r02_nombre
	ELSE
		PRINT COLUMN 48, "** Bodega        : T O D A S " 
	END IF

	PRINT COLUMN 48, "** Fecha Inicial : ", vm_fecha_ini USING "dd-mm-yyyy"
	PRINT COLUMN 48, "** Fecha Final   : ", vm_fecha_fin USING "dd-mm-yyyy"
	PRINT COLUMN 01, "Fecha  : ", TODAY USING "dd-mm-yyyy", 1 SPACES, TIME,
	      COLUMN 112, usuario
	SKIP 1 LINES
--	print '&k2S'	                -- Letra condensada (16 cpi)
	PRINT COLUMN 4,  "Cod. Cliente ",
	      COLUMN 12, "Nom. Cliente",
	      COLUMN 64, "Valor Neto"
	PRINT "------------------------------------------------------------------------------------------------------------------------"
ON EVERY ROW
	NEED 2 LINES
	PRINT COLUMN 4,   r_detalle[numelm].r19_codcli USING "####&",
	      COLUMN 12,  r_detalle[numelm].r19_nomcli CLIPPED,
	      COLUMN 64,  r_detalle[numelm].r19_tot_neto USING "---,---,--&.&&" 

END REPORT



FUNCTION validar_parametros()
                                                                                
CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
        CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'sto
p')
        EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
        CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 'st
op')
        EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
     CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || vg_codcia, 			 'stop')
     EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
        LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
        CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc,
			    'stop')
        EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
      CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| vg_codloc, 			  'stop')
      EXIT PROGRAM
END IF
                                                                                
END FUNCTION

