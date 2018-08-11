------------------------------------------------------------------------------
-- Titulo           : repp429.4gl - Listado detalle Items
-- Elaboracion      : 08-ago-2002
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp429 base módulo compañía moneda bodega
--					query [margen_ini margen_fin linea
--					filtro col1 col2 ordA ordD]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE rm_g04		RECORD LIKE gent004.*
DEFINE rm_g05		RECORD LIKE gent005.*
DEFINE vm_moneda_des	LIKE gent013.g13_nombre
DEFINE vm_max_rows	SMALLINT
DEFINE rm_par 		RECORD
				moneda		LIKE gent013.g13_moneda,
				bodega		LIKE rept002.r02_codigo,
				query		CHAR(700),
				margen_ini	DECIMAL(9,0),
				margen_fin	DECIMAL(9,0),
				linea		LIKE rept003.r03_codigo,
				filtro		LIKE rept010.r10_filtro
			END RECORD
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 6 AND num_args() <> 8 AND num_args() <> 9
  AND num_args() <> 10 AND num_args() <> 14 THEN
	-- Validar # parámetros correcto
	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto.', 'stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base			= arg_val(1)
LET vg_modulo  	 		= arg_val(2)
LET vg_codcia   		= arg_val(3)
LET rm_par.moneda		= arg_val(4)
LET rm_par.bodega		= arg_val(5)
LET rm_par.query		= arg_val(6)
LET rm_par.margen_ini		= arg_val(7)
LET rm_par.margen_fin		= arg_val(8)
LET rm_par.linea		= arg_val(9)
LET rm_par.filtro		= arg_val(10)
LET vm_columna_1 		= arg_val(11)
LET vm_columna_2 		= arg_val(12)
LET rm_orden[vm_columna_1] 	= arg_val(13)
LET rm_orden[vm_columna_2] 	= arg_val(14)
LET vg_proceso = 'repp429'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)

CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CREATE TEMP TABLE temp_item
	(codigo		CHAR(15),
	 nombre		CHAR(40),
	 costo		DECIMAL (14,2),
	 precio		DECIMAL (14,2),
	 margen		DECIMAL (14,2),
	 stock		INTEGER)

CALL fl_nivel_isolation()
LET vm_max_rows = 2000
CALL fl_lee_usuario(vg_usuario)             RETURNING rm_g05.*
CALL fl_lee_grupo_usuario(rm_g05.g05_grupo) RETURNING rm_g04.*
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE i,col		SMALLINT
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE rs		RECORD LIKE rept011.*
DEFINE r_rep		RECORD
				codigo	LIKE rept010.r10_codigo,
				nombre	LIKE rept010.r10_nombre,
				costo	DECIMAL (14,2),
				precio	DECIMAL (14,2),
				margen	DECIMAL (12,0),
				stock	LIKE rept011.r11_stock_act
			END RECORD
DEFINE comando		VARCHAR(100)
DEFINE query		CHAR(300)

CALL fl_lee_moneda(rm_par.moneda) RETURNING r_mon.*
IF r_mon.g13_moneda IS NULL THEN
       	--CALL fgl_winmessage(vg_producto,'No existe moneda base.','stop')
	CALL fl_mostrar_mensaje('No existe moneda base.','stop')
        EXIT PROGRAM
END IF
LET vm_moneda_des = r_mon.g13_nombre
WHILE TRUE
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL fl_lee_compania(vg_codcia) RETURNING rm_cia.*
	PREPARE cit FROM rm_par.query
	DECLARE q_cit CURSOR FOR cit
	LET i = 0
	FOREACH q_cit INTO r_rep.*
		LET r_rep.margen = 0
		IF r_rep.costo > 0 THEN
			LET r_rep.margen = (r_rep.precio - r_rep.costo)
						/ r_rep.costo * 100
		END IF
		CALL fl_lee_stock_rep(vg_codcia, rm_par.bodega, r_rep.codigo)
			RETURNING rs.*
		IF rs.r11_stock_act IS NULL THEN
			LET rs.r11_stock_act = 0
		END IF
		IF rm_par.margen_ini IS NOT NULL AND arg_val(7) <> 'XX' THEN
			IF rs.r11_stock_act = 0 THEN
				CONTINUE FOREACH
			END IF
			IF r_rep.margen < rm_par.margen_ini OR r_rep.margen
		  	  > rm_par.margen_fin THEN
				CONTINUE FOREACH
			END IF
		END IF
		IF rm_g04.g04_ver_costo = 'N' THEN
			LET r_rep.costo  = NULL
			LET r_rep.margen = NULL
		END IF
		LET i = i + 1
		IF i > vm_max_rows THEN
			EXIT FOREACH
		END IF
		INSERT INTO temp_item VALUES (r_rep.codigo, r_rep.nombre,
					r_rep.costo, r_rep.precio,
					r_rep.margen, rs.r11_stock_act)
	END FOREACH
	LET query = 'SELECT * FROM temp_item ',
		' ORDER BY ',
		vm_columna_1, ' ', rm_orden[vm_columna_1], ',', 
		vm_columna_2, ' ', rm_orden[vm_columna_2] 
	START REPORT rep_items TO PIPE comando
	PREPARE crep FROM query
	DECLARE q_crep CURSOR FOR crep 
	FOREACH q_crep INTO r_rep.*
		OUTPUT TO REPORT rep_items (r_rep.*)
	END FOREACH
	DELETE FROM temp_item
	FINISH REPORT rep_items
END WHILE

END FUNCTION



REPORT rep_items(r_rep)
DEFINE r_rep		RECORD
				codigo	LIKE rept010.r10_codigo,
				nombre	LIKE rept010.r10_nombre,
				costo	DECIMAL (14,2),
				precio	DECIMAL (14,2),
				margen	DECIMAL (14,2),
				stock	LIKE rept011.r11_stock_act
			END RECORD
DEFINE stock		LIKE rept011.r11_stock_act
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r03		RECORD LIKE rept003.*
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i,long		SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	1
	RIGHT MARGIN	90
	BOTTOM MARGIN	4
	PAGE LENGTH	66
FORMAT

PAGE HEADER
	--#print 'E'; --#print '&l26A';	-- Indica que voy a trabajar con hojas A4
	--#print '&k4S'	                -- Letra (12 cpi)
	LET modulo  = "Módulo: Inventario"
	LET long    = LENGTH(modulo)
	LET usuario = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('I', 'LISTADO DETALLE DE ITEMS', 80)
		RETURNING titulo
	CALL fl_lee_bodega_rep(vg_codcia, rm_par.bodega)
		RETURNING r_r02.*
	{FOR i = 1 TO long
		LET titulo[i,i] = modulo[i,i]
	END FOR}
--	LET titulo = modulo, titulo 
	PRINT COLUMN 1, rm_cia.g01_razonsocial,
  	      COLUMN 70, "Página: ", PAGENO USING "&&&"
	PRINT COLUMN 1, modulo CLIPPED,
	      COLUMN 32, titulo CLIPPED,
	      COLUMN 74, UPSHIFT(vg_proceso) 
	PRINT COLUMN 20, "** Moneda         : ", rm_par.moneda, " ",
						vm_moneda_des
	PRINT COLUMN 20, "** Bodega         : ", rm_par.bodega, " ",
						r_r02.r02_nombre
	--#IF rm_par.linea <> 'XX' THEN
		CALL fl_lee_linea_rep(vg_codcia, rm_par.linea)
			RETURNING r_r03.*
		PRINT COLUMN 20, "** Línea          : ", rm_par.linea, " ",
						r_r03.r03_nombre
	--#END IF
	--#IF rm_par.margen_ini IS NOT NULL AND arg_val(7) <> 'XX' THEN
		PRINT COLUMN 20, "** Margen Inicial : ", rm_par.margen_ini
							USING "----&"
		PRINT COLUMN 20, "** Margen Final   : ", rm_par.margen_fin
							USING "----&"
	--#END IF
	--#IF rm_par.filtro <> 'XX' THEN
		PRINT COLUMN 20, "** Filtro         : ", rm_par.filtro
	--#END IF
	PRINT COLUMN 01, "Fecha  : ", vg_fecha USING "dd-mm-yyyy", 1 SPACES, TIME,
	      COLUMN 62, usuario
	SKIP 1 LINES
	--#print '&k4S'	                -- Letra condensada (12 cpi)
	PRINT COLUMN 1,   "Item",
	      COLUMN 17,  "Descripción",
	      COLUMN 40,  "Costo  Unit.",
	      COLUMN 54,  "Precio Unit.",
	      COLUMN 68,  "Marg(%)",
	      COLUMN 76,  "Stock"
	PRINT "--------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 2 LINES
	PRINT COLUMN 1,   r_rep.codigo,
	      COLUMN 17,  r_rep.nombre[1,20],
	      COLUMN 38,  r_rep.costo  USING "---,---,--&.##",
	      COLUMN 52,  r_rep.precio USING "---,---,--&.##",
	      COLUMN 70,  r_rep.margen USING "----&",
	      COLUMN 77,  r_rep.stock  USING "###&"
	
--#ON LAST ROW
	--NEED 2 LINES
	--PRINT COLUMN 48, "TOTALES ==>  "

END REPORT
