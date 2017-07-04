--------------------------------------------------------------------------------
-- Titulo           : repp324.4gl - Consulta ventas de items compuestos
-- Elaboracion      : 08-Oct-2010
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp324 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE rm_orden 	ARRAY[15] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE rm_par 		RECORD 
				fecha_ini	DATE,
				fecha_fin	DATE,
				tipo_est	CHAR
			END RECORD
DEFINE rm_detalle	ARRAY [30000] OF RECORD
				fecha		DATE,
				item		LIKE rept010.r10_codigo,
				composicion	LIKE rept048.r48_composicion,
				carga		LIKE rept048.r48_sec_carga,
				referencia	LIKE rept048.r48_referencia,
				unidades	LIKE rept048.r48_carg_stock,
				costo		LIKE rept048.r48_costo_comp,
				estado		LIKE rept048.r48_estado
			END RECORD
DEFINE rm_adi		ARRAY [30000] OF RECORD
				desc_clase	LIKE rept072.r72_desc_clase,
				desc_item	LIKE rept010.r10_nombre,
				desc_marca	LIKE rept073.r73_desc_marca
			END RECORD
DEFINE rm_g05		RECORD LIKE gent005.*



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp324.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN   -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'repp324'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
LET vm_max_det = 30000
LET lin_menu   = 0
LET row_ini    = 3
LET num_rows   = 22
LET num_cols   = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_repp324 AT row_ini, 02 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_repf324_1 FROM "../forms/repf324_1"
ELSE
	OPEN FORM f_repf324_1 FROM "../forms/repf324_1c"
END IF
DISPLAY FORM f_repf324_1
CALL muestra_contadores_det(0, 0)
CALL borrar_cabecera()
CALL borrar_detalle()
CALL mostrar_cabecera_forma()
CALL control_consulta()
CLOSE WINDOW w_repp324
RETURN

END FUNCTION



FUNCTION control_consulta()

CALL fl_lee_usuario(vg_usuario) RETURNING rm_g05.*
INITIALIZE rm_par.* TO NULL
LET rm_par.fecha_fin = TODAY
LET rm_par.fecha_ini = MDY(MONTH(rm_par.fecha_fin), 01, YEAR(rm_par.fecha_fin))
LET rm_par.tipo_est  = 'C'
LET vm_num_det       = 0
WHILE TRUE
	CALL borrar_detalle()
	CALL muestra_contadores_det(0, 0)
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL mostrar_consulta()
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE fec_ini		DATE
DEFINE fec_fin		DATE

LET int_flag = 0
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	BEFORE FIELD fecha_ini
		LET fec_ini = rm_par.fecha_ini
	BEFORE FIELD fecha_fin
		LET fec_fin = rm_par.fecha_fin
	AFTER FIELD fecha_ini 
		IF rm_par.fecha_ini IS NULL THEN
			LET rm_par.fecha_ini = fec_ini     
			DISPLAY BY NAME rm_par.fecha_ini
		END IF
		IF rm_par.fecha_ini > TODAY THEN
			CALL fl_mostrar_mensaje('La fecha de inicio no puede ser mayor a la de hoy.','exclamation')
			NEXT FIELD fecha_ini
		END IF
	AFTER FIELD fecha_fin 
		IF rm_par.fecha_fin IS NULL THEN
			LET rm_par.fecha_fin = fec_fin
			DISPLAY BY NAME rm_par.fecha_fin
		END IF
		IF rm_par.fecha_fin > TODAY THEN
			CALL fl_mostrar_mensaje('La fecha de término no puede ser mayor a la de hoy.','exclamation')
			NEXT FIELD fecha_fin
		END IF
	AFTER INPUT
		IF rm_par.fecha_ini > rm_par.fecha_fin THEN
			CALL fl_mostrar_mensaje('Fecha inicial debe ser menor a fecha final.','exclamation')
			NEXT FIELD fecha_ini
		END IF
END INPUT
IF int_flag THEN
	RETURN
END IF
IF rm_par.tipo_est IS NULL THEN
	LET rm_par.tipo_est = 'C'
	DISPLAY BY NAME rm_par.tipo_est
END IF

END FUNCTION



FUNCTION mostrar_consulta()
DEFINE i, j, col, salir	SMALLINT
DEFINE query		CHAR(800)

IF NOT preparar_tabla_temp_consulta() THEN
	RETURN
END IF
LET vm_columna_1           = 1
LET vm_columna_2           = 2
LET rm_orden[vm_columna_1] = 'DESC'
LET rm_orden[vm_columna_2] = 'ASC'
INITIALIZE col TO NULL
LET salir = 0
WHILE NOT salir
	LET query = "SELECT * FROM tmp_car ",
                   	" ORDER BY ", vm_columna_1, " ", rm_orden[vm_columna_1],
				", ", vm_columna_2, " ", rm_orden[vm_columna_2]
	PREPARE cargas FROM query
	DECLARE q_cargas CURSOR FOR cargas
	LET i = 1
	FOREACH q_cargas INTO rm_detalle[i].*, rm_adi[i].*
		LET i = i + 1
		IF i > vm_max_det THEN
			EXIT FOREACH
		END IF
	END FOREACH
	CALL mostrar_totales()
	LET int_flag = 0
	CALL set_count(vm_num_det)
	DISPLAY ARRAY rm_detalle TO rm_detalle.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			LET salir    = 1
			EXIT DISPLAY
		ON KEY(F5)
			IF rm_g05.g05_grupo = 'SI' OR rm_g05.g05_grupo = 'GE'
			THEN
				LET i = arr_curr()
				CALL mostrar_item(rm_detalle[i].item)
				LET int_flag = 0
			END IF
		ON KEY(F6)
			LET i = arr_curr()
			IF rm_detalle[i].carga IS NULL THEN
				CONTINUE DISPLAY
			END IF
			CALL detalle_venta(i)
			LET int_flag = 0
		ON KEY(F7)
			LET i = arr_curr()
			CALL ver_composicion(i)
			LET int_flag = 0
		ON KEY(F8)
			LET i = arr_curr()
			IF rm_detalle[i].carga IS NULL THEN
				CONTINUE DISPLAY
			END IF
			CALL ver_carga(i)
			LET int_flag = 0
		ON KEY(F9)
			CALL imprimir_listado()
			LET int_flag = 0
		ON KEY(F10)
			CALL generar_archivo()
			LET int_flag = 0
		ON KEY(F15)
			LET col = 1
			EXIT DISPLAY
		ON KEY(F16)
			LET col = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET col = 3
			EXIT DISPLAY
		ON KEY(F18)
			LET col = 4
			EXIT DISPLAY
		ON KEY(F19)
			LET col = 5
			EXIT DISPLAY
		ON KEY(F20)
			LET col = 6
			EXIT DISPLAY
		ON KEY(F21)
			LET col = 7
			EXIT DISPLAY
		ON KEY(F22)
			LET col = 8
			EXIT DISPLAY
		BEFORE DISPLAY
			CALL dialog.keysetlabel("ACCEPT","")
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
			IF rm_g05.g05_grupo = 'SI' OR rm_g05.g05_grupo = 'GE'
			THEN
				CALL dialog.keysetlabel("F5", "Item")
			ELSE
				CALL dialog.keysetlabel("F5", "")
			END IF
			IF rm_detalle[i].carga IS NULL THEN
				CALL dialog.keysetlabel("F6", "")
				CALL dialog.keysetlabel("F8", "")
			ELSE
				CALL dialog.keysetlabel("F6", "Detalle Venta")
				CALL dialog.keysetlabel("F8", "Carga")
			END IF
			CALL muestra_etiquetas(i)
		AFTER DISPLAY
			CONTINUE DISPLAY
	END DISPLAY
	IF int_flag = 1 OR salir THEN
		EXIT WHILE
	END IF
	IF col IS NOT NULL AND NOT salir THEN
		IF col <> vm_columna_1 THEN
			LET vm_columna_2           = vm_columna_1
			LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
			LET vm_columna_1           = col
		END IF
		IF rm_orden[vm_columna_1] = 'ASC' THEN
			LET rm_orden[vm_columna_1] = 'DESC'
		ELSE
			LET rm_orden[vm_columna_1] = 'ASC'
		END IF
		INITIALIZE col TO NULL
	END IF
END WHILE
DROP TABLE tmp_car

END FUNCTION



FUNCTION preparar_tabla_temp_consulta()
DEFINE fec_ini, fec_fin	LIKE rept019.r19_fecing
DEFINE query		CHAR(6000)

LET fec_ini  = EXTEND(rm_par.fecha_ini, YEAR TO SECOND)
LET fec_fin  = EXTEND(rm_par.fecha_fin, YEAR TO SECOND)
		+ 23 UNITS HOUR + 59 UNITS MINUTE + 59 UNITS SECOND  
IF rm_par.tipo_est <> 'T' AND rm_par.tipo_est <> 'X' THEN
	LET query = 'SELECT DATE(r48_fecing) fecha, r48_item_comp item,',
			' r48_composicion composicion, r48_sec_carga carga,',
			' r48_referencia referencia, r48_carg_stock unidades,',
			' r48_costo_comp costo, r48_estado estado,',
			' r46_desc_clase_c desc_clase,r46_desc_comp desc_item,',
			' r46_marca_c desc_marca',
		' FROM rept048, rept046 ',
		' WHERE r48_compania    = ', vg_codcia,
		'   AND r48_localidad   = ', vg_codloc,
		'   AND r48_fecing      BETWEEN "', fec_ini,
					 '" AND "', fec_fin, '"',
		'   AND r48_estado      = "', rm_par.tipo_est, '"',
		'   AND r46_compania    = r48_compania ',
		'   AND r46_localidad   = r48_localidad ',
		'   AND r46_composicion = r48_composicion ',
		'   AND r46_item_comp   = r48_item_comp '
ELSE
	IF rm_par.tipo_est <> 'X' THEN
		LET query = 'SELECT DATE(r46_fecing) fecha,r46_item_comp item,',
			' r46_composicion composicion, r48_sec_carga carga,',
			' r46_referencia referencia, r48_carg_stock unidades,',
			' r48_costo_comp costo, NVL(r48_estado, r46_estado)',
			' estado, r46_desc_clase_c desc_clase,',
			' r46_desc_comp desc_item, r46_marca_c desc_marca',
		' FROM rept046, OUTER rept048 ',
		' WHERE r46_compania    = ', vg_codcia,
		'   AND r46_localidad   = ', vg_codloc,
		'   AND r46_fecing      BETWEEN "', fec_ini,
					 '" AND "', fec_fin, '"',
		'   AND r48_compania    = r46_compania ',
		'   AND r48_localidad   = r46_localidad ',
		'   AND r48_composicion = r46_composicion ',
		'   AND r48_item_comp   = r46_item_comp '
	ELSE
		LET query = 'SELECT DATE(r46_fecing) fecha,r46_item_comp item,',
			' r46_composicion composicion, "" carga,',
			' r46_referencia referencia, "" unidades,',
			' "" costo, r46_estado estado, r46_desc_clase_c',
			' desc_clase, r46_desc_comp desc_item, r46_marca_c',
			' desc_marca',
		' FROM rept046 ',
		' WHERE r46_compania    = ', vg_codcia,
		'   AND r46_localidad   = ', vg_codloc,
		'   AND r46_fecing      BETWEEN "', fec_ini,
					 '" AND "', fec_fin, '"'
	END IF
END IF
LET query = query CLIPPED, ' INTO TEMP tmp_car '
PREPARE exec_tmp FROM query
EXECUTE exec_tmp
SELECT COUNT(*) INTO vm_num_det FROM tmp_car
IF vm_num_det = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	DROP TABLE tmp_car
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION borrar_cabecera()

INITIALIZE rm_par.* TO NULL
DISPLAY BY NAME rm_par.*

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i  		SMALLINT

CALL muestra_contadores_det(0, 0)
FOR i = 1 TO fgl_scr_size('rm_detalle')
        INITIALIZE rm_detalle[i].*, rm_adi[i].* TO NULL
        CLEAR rm_detalle[i].*
END FOR
CLEAR total_unid, total_costo, desc_clase, desc_item, desc_marca,num_row,max_row

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION


 
FUNCTION mostrar_cabecera_forma()

--#DISPLAY "Fecha"		TO tit_col1
--#DISPLAY "Items"		TO tit_col2
--#DISPLAY "Comp."		TO tit_col3
--#DISPLAY "Carga"		TO tit_col4
--#DISPLAY "Referencia"		TO tit_col5
--#DISPLAY "Tot. Unid."		TO tit_col6
--#DISPLAY "Tot. Costo"		TO tit_col7
--#DISPLAY "E"			TO tit_col8

END FUNCTION



FUNCTION mostrar_totales()
DEFINE total_unid	DECIMAL(12,2)
DEFINE total_costo	DECIMAL(12,2)
DEFINE i		SMALLINT

LET total_unid  = 0
LET total_costo = 0
FOR i = 1 TO vm_num_det
	IF rm_detalle[i].unidades IS NULL THEN
		CONTINUE FOR
	END IF
	LET total_unid  = total_unid  + rm_detalle[i].unidades
	LET total_costo = total_costo + rm_detalle[i].costo
END FOR
DISPLAY BY NAME total_unid, total_costo

END FUNCTION



FUNCTION muestra_etiquetas(i)
DEFINE i		SMALLINT

CALL muestra_contadores_det(i, vm_num_det)
DISPLAY BY NAME rm_adi[i].*

END FUNCTION



FUNCTION mostrar_item(item)
DEFINE item		LIKE rept020.r20_item
DEFINE param		VARCHAR(60)

LET param = ' "', item CLIPPED, '"'
CALL fl_ejecuta_comando('REPUESTOS', vg_modulo, 'repp108 ', param, 1)

END FUNCTION



FUNCTION detalle_venta(pos)
DEFINE pos		SMALLINT
DEFINE param		VARCHAR(60)

LET param = ' "', rm_par.fecha_ini, '" "', rm_par.fecha_fin, '" V "',
		rm_detalle[pos].item CLIPPED, '"'
CALL fl_ejecuta_comando('REPUESTOS', vg_modulo, 'repp323 ', param, 1)

END FUNCTION



FUNCTION ver_composicion(i)
DEFINE i		SMALLINT
DEFINE param		VARCHAR(60)

LET param = ' ', rm_detalle[i].composicion
CALL fl_ejecuta_comando('REPUESTOS', vg_modulo, 'repp248 ', param, 1)

END FUNCTION



FUNCTION ver_carga(i)
DEFINE i		SMALLINT
DEFINE param		VARCHAR(60)

LET param = ' ', rm_detalle[i].composicion, ' "', rm_detalle[i].item CLIPPED,
		'" ', rm_detalle[i].carga
CALL fl_ejecuta_comando('REPUESTOS', vg_modulo, 'repp249 ', param, 1)

END FUNCTION



FUNCTION imprimir_listado()
DEFINE i		INTEGER
DEFINE comando		VARCHAR(100)

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
START REPORT listado_item_compuesto TO PIPE comando
	FOR i = 1 TO vm_num_det
		OUTPUT TO REPORT listado_item_compuesto(rm_detalle[i].*,
								rm_adi[i].*)
	END FOR
FINISH REPORT listado_item_compuesto

END FUNCTION



REPORT listado_item_compuesto(r_rep)
DEFINE r_rep 		RECORD
				fecha		DATE,
				item		LIKE rept010.r10_codigo,
				composicion	LIKE rept048.r48_composicion,
				carga		LIKE rept048.r48_sec_carga,
				referencia	LIKE rept048.r48_referencia,
				unidades	LIKE rept048.r48_carg_stock,
				costo		LIKE rept048.r48_costo_comp,
				estado		LIKE rept048.r48_estado,
				desc_clase	LIKE rept072.r72_desc_clase,
				desc_item	LIKE rept010.r10_nombre,
				desc_marca	LIKE rept073.r73_desc_marca
			END RECORD
DEFINE r_cia		RECORD LIKE gent001.*
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE long		SMALLINT
DEFINE escape		SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_12cpi	SMALLINT

OUTPUT
	TOP MARGIN	0
	LEFT MARGIN	0
	RIGHT MARGIN	132 
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi�n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	LET modulo      = "MODULO: INVENTARIO"
	LET long        = LENGTH(modulo)
	LET usuario     = 'USUARIO: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('C', 'LISTADO ITEMS COMPUESTO', 80)
		RETURNING titulo
	CALL fl_lee_compania(vg_codcia) RETURNING r_cia.*
	print ASCII escape;
	print ASCII act_comp;
	print ASCII escape;
	print ASCII act_10cpi
	PRINT COLUMN 001, r_cia.g01_razonsocial,
  	      COLUMN 122, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 026, titulo CLIPPED,
	      COLUMN 126, UPSHIFT(vg_proceso)
	SKIP 1 LINES
	PRINT COLUMN 049, "** FECHA INICIAL : ",
		rm_par.fecha_ini USING "dd-mm-yyyy"
	PRINT COLUMN 049, "** FECHA FINAL   : ", 
		 rm_par.fecha_fin USING "dd-mm-yyyy"
	PRINT COLUMN 049, "** ESTADO        : ", rm_par.tipo_est CLIPPED,
		retorna_estado(rm_par.tipo_est) CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
		1 SPACES, TIME,
	      COLUMN 114, usuario
	PRINT COLUMN 001, "------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 001, "FECHA",
	      COLUMN 012, "ITEM",
	      COLUMN 044, "D E S C R I P C I O N",
	      COLUMN 089, "TOTAL UNI.",
	      COLUMN 101, "   TOTAL COSTO",
	      COLUMN 119, "E S T A D O"
	PRINT COLUMN 001, "------------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 4 LINES
	PRINT COLUMN 001, r_rep.fecha			USING "dd-mm-yyyy",
	      COLUMN 012, r_rep.item[1, 6]		CLIPPED,
	      COLUMN 019, r_rep.desc_clase[1, 41]	CLIPPED,
	      COLUMN 061, r_rep.desc_item		CLIPPED,
	      COLUMN 127, r_rep.desc_marca[1, 6]	CLIPPED
	PRINT COLUMN 019, r_rep.composicion		USING "<<<<00&",
	      COLUMN 028, r_rep.carga			USING "<<<<00&",
	      COLUMN 037, r_rep.referencia[1, 50]	CLIPPED,
	      COLUMN 089, r_rep.unidades		USING "---,--&.##",
	      COLUMN 101, r_rep.costo			USING "---,---,--&.##",
	      COLUMN 117, retorna_estado(r_rep.estado)	CLIPPED
	
ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 089, "----------",
	      COLUMN 101, "--------------"
	PRINT COLUMN 076, "TOTALES ==>  ",
	      COLUMN 089, SUM(r_rep.unidades)		USING "---,--&.##",
	      COLUMN 101, SUM(r_rep.costo)		USING "---,---,--&.##"
	print ASCII escape;
	print ASCII desact_comp

END REPORT



FUNCTION retorna_estado(estado)
DEFINE estado		LIKE rept048.r48_estado
DEFINE desc_est		VARCHAR(20)

CASE estado
	WHEN 'P' LET desc_est = "EN PROCESO"
	WHEN 'C' LET desc_est = "CARGADO EN STOCK"
	WHEN 'E' LET desc_est = "ELIMINADO"
	WHEN 'T' LET desc_est = "T O D O S"
END CASE
RETURN desc_est

END FUNCTION 



FUNCTION generar_archivo()
DEFINE mensaje		VARCHAR(100)

ERROR 'Generando Archivo repp324.unl ... por favor espere'
UNLOAD TO "../../../tmp/repp324.unl"
	SELECT fecha, item, desc_clase, desc_item, desc_marca, composicion,
		carga, referencia, unidades, costo, estado
		FROM tmp_car
		ORDER BY 1 ASC, 2 ASC
RUN "mv ../../../tmp/repp324.unl $HOME/tmp/"
LET mensaje = FGL_GETENV("HOME"), '/tmp/repp324.unl'
CALL fl_mostrar_mensaje('Archivo Generado en: ' || mensaje, 'info')
ERROR ' '

END FUNCTION
