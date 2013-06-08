--------------------------------------------------------------------------------
-- Titulo           : repp307.4gl - Consulta de Egresos/Ingresos Items (Kardex)
-- Elaboracion      : 13-dic-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp307 base módulo compañía localidad
--			[bodega] [item] [fecha1] [fecha2]
-- Ultima Correccion:
-- Motivo Correccion:
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_g05		RECORD LIKE gent005.*
DEFINE rm_r02		RECORD LIKE rept002.*
DEFINE rm_r10		RECORD LIKE rept010.*
DEFINE rm_r20		RECORD LIKE rept020.*
DEFINE vm_bodega	LIKE rept019.r19_bodega_ori
DEFINE vm_stock_inicial	LIKE rept011.r11_stock_act
DEFINE vm_tot_ing	LIKE rept011.r11_stock_act
DEFINE vm_tot_egr	LIKE rept011.r11_stock_act
DEFINE vm_tot_ing2	LIKE rept011.r11_stock_act
DEFINE vm_tot_egr2	LIKE rept011.r11_stock_act
DEFINE vm_saldo_fin	LIKE rept011.r11_stock_act
DEFINE r_detalle	ARRAY[4000] OF RECORD
				r20_cod_tran	LIKE rept019.r19_cod_tran,
				r20_num_tran	LIKE rept019.r19_num_tran,
				fecha		DATE,
				cliente		LIKE cxct001.z01_nomcli,
				cant_ing	LIKE rept011.r11_stock_act,
				cant_egr	LIKE rept011.r11_stock_act,
				saldo		LIKE rept011.r11_stock_act
			END RECORD
DEFINE vm_r_rows	ARRAY[100] OF INTEGER
DEFINE vm_num_rows      SMALLINT
DEFINE vm_row_current   SMALLINT
DEFINE vm_max_rows      SMALLINT
DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE vm_fecha_desde	DATE
DEFINE vm_fecha_hasta	DATE
DEFINE vm_size_arr	INTEGER
DEFINE vm_solo_fact	CHAR(1)
DEFINE vm_solo_costo	CHAR(1)
DEFINE vm_imprimir	CHAR(1)
DEFINE flag_ver_item	SMALLINT



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp307.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 8 AND num_args() <> 9 THEN
	-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de pparametros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'repp307'
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
LET vm_max_rows = 100
LET vm_max_det  = 4000
LET lin_menu    = 0
LET row_ini     = 3
LET num_rows    = 22
LET num_cols    = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_repp307_1 AT row_ini, 02 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_repf307_1 FROM "../forms/repf307_1"
ELSE
	OPEN FORM f_repf307_1 FROM "../forms/repf307_1c"
END IF
DISPLAY FORM f_repf307_1
INITIALIZE rm_r20.*, vm_bodega, vm_fecha_desde, vm_fecha_hasta, vm_stock_inicial
	TO NULL
--#LET vm_size_arr = fgl_scr_size('r_detalle')
IF vg_gui = 0 THEN
	LET vm_size_arr = 11
END IF
CALL fl_retorna_usuario()
CALL fl_lee_usuario(vg_usuario) RETURNING rm_g05.*
LET vm_num_rows    = 0
LET vm_row_current = 0
LET vm_num_det     = 0
LET vm_fecha_desde = TODAY
LET vm_fecha_hasta = TODAY
LET vm_solo_fact   = 'N'
LET vm_solo_costo  = 'N'
CALL setear_botones_det()
CALL muestra_contadores(vm_row_current, vm_num_rows)
LET flag_ver_item  = 1
IF num_args() <> 4 THEN
	CALL llamada_con_parametros()
	IF vm_bodega <> 'XX' THEN
		LET int_flag = 0
		CLOSE WINDOW w_repp307_1
		EXIT PROGRAM
	END IF
END IF
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Detalle'
		HIDE OPTION 'Imprimir Listado'
		IF num_args() = 4 THEN
			CALL muestra_consulta_movimientos_items()
		END IF
		IF vm_num_rows = 0 THEN
			EXIT MENU
		END IF
		SHOW OPTION 'Avanzar'
		IF vm_num_rows = 1 THEN
			HIDE OPTION 'Avanzar'
		END IF
		SHOW OPTION 'Detalle'
		SHOW OPTION 'Imprimir Listado'
		IF num_args() <> 4 THEN
			HIDE OPTION 'Consultar'
		END IF
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		CALL muestra_consulta_movimientos_items()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Detalle'
			SHOW OPTION 'Imprimir Listado'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Detalle'
				HIDE OPTION 'Imprimir Listado'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Detalle'
			SHOW OPTION 'Imprimir Listado'
		END IF
		IF vm_row_current <= 1 THEN
			HIDE OPTION 'Retroceder'
		END IF
	COMMAND KEY('D') 'Detalle' 'Muestra siguiente detalle del registro. '
		CALL muestra_detalle()
	COMMAND KEY('I') 'Imprimir Listado' 'Muestra Listado a Imprimir.'
		CALL control_imprimir()
	COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro. '
		CALL muestra_siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder'  'Ver anterior registro. '
		CALL muestra_anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU
LET int_flag = 0
CLOSE WINDOW w_repp307_1
EXIT PROGRAM

END FUNCTION



FUNCTION llamada_con_parametros()

LET vm_num_rows     = 1
LET vm_bodega       = arg_val(5)
LET rm_r20.r20_item = arg_val(6)
LET vm_fecha_desde  = arg_val(7)	
LET vm_fecha_hasta  = arg_val(8)	
IF num_args() > 8 THEN
	LET flag_ver_item = arg_val(9)
END IF
LET vm_solo_costo = "N"
IF vm_bodega = 'XX' THEN
	LET vm_bodega     = NULL
	LET vm_solo_fact  = "N"
	CALL cargar_bodegas()
	LET vm_bodega    = 'XX'
ELSE
	CALL fl_lee_item(vg_codcia, rm_r20.r20_item) RETURNING rm_r10.* 
	CALL fl_lee_bodega_rep(vg_codcia, vm_bodega) RETURNING rm_r02.* 
	DISPLAY BY NAME rm_r20.r20_item, vm_bodega, vm_fecha_desde,
			vm_fecha_hasta
	DISPLAY rm_r10.r10_nombre  TO nom_item
	DISPLAY rm_r02.r02_nombre  TO nom_bodega
	DISPLAY rm_r02.r02_factura TO vm_solo_fact
	CALL muestra_contadores(1, vm_num_rows)
	CALL control_detalle()
END IF

END FUNCTION



FUNCTION muestra_consulta_movimientos_items()
DEFINE entro	 	SMALLINT

LET entro = 0
WHILE TRUE
	CALL borrar_pantalla()
	IF NOT entro THEN
		LET vm_stock_inicial = 0
	END IF
	CALL setear_botones_det()
	CALL muestra_contadores_det(0, 0)
	DISPLAY BY NAME vm_stock_inicial
	IF NOT entro THEN
		--INITIALIZE rm_r10.*, rm_r20.r20_item TO NULL
	END IF
	LET entro = 0
	CALL control_lee_cabecera()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL setear_botones_det()
	IF vm_num_rows = 0 THEN
		LET entro = 1
		CONTINUE WHILE
	END IF
	IF vm_num_rows = 1 THEN
		CALL control_detalle()
		IF vm_num_det = 0 THEN
			LET entro = 1
		END IF
	END IF
	EXIT WHILE
END WHILE
IF vm_num_rows > 0 THEN
	CALL mostrar_registro(vm_r_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION control_lee_cabecera()
DEFINE grupo_linea	LIKE rept021.r21_grupo_linea
DEFINE bodega		LIKE rept011.r11_bodega
DEFINE stock		LIKE rept011.r11_stock_act
DEFINE item		LIKE rept010.r10_codigo
DEFINE bodeg		LIKE rept002.r02_codigo
DEFINE solo, expr_loc	CHAR(1)
DEFINE fec_ini, fec_fin	DATE
DEFINE f_ini, f_fin	DATE
DEFINE flag_fact	CHAR(1)

LET vm_solo_costo = 'N'
LET grupo_linea   = NULL
IF vm_stock_inicial = 0 AND vm_num_rows = 0 AND vm_num_det = 0 THEN
	LET vm_bodega = NULL
END IF
CALL fl_lee_bodega_rep(vg_codcia, vm_bodega) RETURNING rm_r02.* 
DISPLAY BY NAME rm_r20.r20_item, vm_bodega, vm_fecha_desde, vm_fecha_hasta
DISPLAY rm_r10.r10_nombre TO nom_item
DISPLAY rm_r02.r02_nombre TO nom_bodega
LET item     = rm_r20.r20_item
LET bodeg    = vm_bodega
LET f_ini    = vm_fecha_desde
LET f_fin    = vm_fecha_hasta
LET solo     = vm_solo_fact
LET int_flag = 0
INPUT BY NAME rm_r20.r20_item, vm_bodega, vm_solo_fact, vm_fecha_desde,
	vm_fecha_hasta
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag        = 1
		LET rm_r20.r20_item = item
		LET vm_bodega       = bodeg
		LET vm_fecha_desde  = f_ini
		LET vm_fecha_hasta  = f_fin
		LET vm_solo_fact    = solo
		EXIT INPUT
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(r20_item) THEN
			CALL fl_ayuda_maestro_items_stock(vg_codcia,
							grupo_linea, vm_bodega)
				RETURNING rm_r10.r10_codigo, rm_r10.r10_nombre,
					  rm_r10.r10_linea,rm_r10.r10_precio_mb,
					  bodega, stock
			IF rm_r10.r10_codigo IS NOT NULL THEN
				LET rm_r20.r20_item = rm_r10.r10_codigo
				DISPLAY BY NAME rm_r20.r20_item 
				DISPLAY rm_r10.r10_nombre TO nom_item
			END IF 
		END IF
		IF INFIELD(vm_bodega) THEN
			LET flag_fact = vm_solo_fact
			IF flag_fact = 'N' THEN
				LET flag_fact = 'T'
			END IF
			IF vg_codloc = 1 OR vg_codloc = 2 OR vg_codloc = 6 THEN
				LET expr_loc = 'G'
			END IF
			IF vg_codloc = 3 OR vg_codloc = 4 OR vg_codloc = 5 OR
			   vg_codloc = 7
			THEN
				LET expr_loc = 'Q'
			END IF
			IF vg_codloc = 3 OR vg_codloc = 5 THEN
				LET expr_loc = 'U'
			END IF
			CALL fl_ayuda_bodegas_rep(vg_codcia, expr_loc, 'T',
						'T', 'A', flag_fact, '2')
				RETURNING rm_r02.r02_codigo, rm_r02.r02_nombre
			IF rm_r02.r02_codigo IS NOT NULL THEN
				LET vm_bodega = rm_r02.r02_codigo
				DISPLAY BY NAME vm_bodega
				DISPLAY rm_r02.r02_nombre TO nom_bodega
			END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD vm_fecha_desde 
		LET fec_ini = vm_fecha_desde
	BEFORE FIELD vm_fecha_hasta 
		LET fec_fin = vm_fecha_hasta
	AFTER FIELD r20_item 
		IF rm_r20.r20_item IS NOT NULL THEN
			CALL fl_lee_item(vg_codcia, rm_r20.r20_item)
				RETURNING rm_r10.* 
			IF rm_r10.r10_codigo IS NULL  THEN
				CALL fl_mostrar_mensaje('El item no existe en la Compañía.','exclamation')
				NEXT FIELD r20_item
			END IF
			DISPLAY rm_r10.r10_nombre TO nom_item
		ELSE
			CLEAR nom_item
		END IF
	AFTER FIELD vm_bodega 
		IF vm_bodega IS NOT NULL THEN
			CALL fl_lee_bodega_rep(vg_codcia, vm_bodega)
				RETURNING rm_r02.* 
			IF rm_r02.r02_codigo IS NULL  THEN
				CALL fl_mostrar_mensaje('La bodega no existe en la Compañía.','exclamation')
				NEXT FIELD vm_bodega
			END IF
			DISPLAY rm_r02.r02_nombre TO nom_bodega
		ELSE
			INITIALIZE rm_r02.* TO NULL
			CLEAR nom_bodega
		END IF
	AFTER FIELD vm_fecha_desde 
		IF vm_fecha_desde IS NOT NULL THEN
			IF vm_fecha_desde > TODAY THEN
				CALL fl_mostrar_mensaje('La Fecha Desde, no puede ser mayor a la fecha de hoy.', 'exclamation')
				NEXT FIELD vm_fecha_desde
			END IF
			IF vm_fecha_desde < '01-01-1900' THEN
				CALL fl_mostrar_mensaje('Debe ingresa fechas mayores a las del año 1899.', 'exclamation')	
				NEXT FIELD vm_fecha_desde
			END IF
		ELSE
			LET vm_fecha_desde = fec_ini
			DISPLAY BY NAME vm_fecha_desde
		END IF
	AFTER FIELD vm_fecha_hasta 
		IF vm_fecha_hasta IS NOT NULL THEN
			IF vm_fecha_hasta > TODAY THEN
				CALL fl_mostrar_mensaje('La Fecha Hasta, no puede ser mayor a la fecha de hoy.','exclamation')
				NEXT FIELD vm_fecha_hasta
			END IF
			IF vm_fecha_hasta < '01-01-1990' THEN
				CALL fl_mostrar_mensaje('Debe ingresa fechas mayores a las del año 1989.','exclamation')	
				NEXT FIELD vm_fecha_hasta
			END IF
		ELSE
			LET vm_fecha_hasta = fec_fin
			DISPLAY BY NAME vm_fecha_hasta
		END IF
	AFTER INPUT
		IF vm_fecha_desde > vm_fecha_hasta THEN
			CALL fl_mostrar_mensaje('La Fecha Hasta debe ser mayor a la Fecha Desde.','exclamation')
			NEXT FIELD vm_fecha_hasta
		END IF
END INPUT
IF int_flag THEN
	RETURN
END IF
IF NOT (rm_g05.g05_grupo = 'SI' OR rm_g05.g05_grupo = 'GE') THEN
	LET vm_solo_costo = 'N'
END IF
CALL cargar_bodegas()

END FUNCTION



FUNCTION cargar_bodegas()
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE codloc		LIKE rept002.r02_localidad
DEFINE fec_i, fec_f	LIKE rept020.r20_fecing
DEFINE query		CHAR(800)
DEFINE cuantos		INTEGER
DEFINE num_row_id	INTEGER
DEFINE expr_bod		VARCHAR(100)
DEFINE expr_fact	VARCHAR(100)

LET expr_bod = NULL
IF vm_bodega IS NOT NULL THEN
	LET expr_bod = '   AND r02_codigo    = "', vm_bodega, '"'
END IF
LET expr_fact = NULL
IF vm_solo_fact = "S" THEN
	LET expr_fact = '   AND r02_factura   = "S"'
END IF
LET codloc = 0
IF vg_codloc = 3 THEN
	--LET codloc = 5
	LET codloc = 3
END IF
LET query = 'SELECT rept002.*, ROWID FROM rept002 ',
		' WHERE r02_compania  = ', vg_codcia,
		expr_bod CLIPPED,
		'   AND r02_localidad IN (', vg_codloc, ', ', codloc, ')',
		--'   AND r02_estado    = "A"',
		expr_fact CLIPPED,
		' ORDER BY r02_codigo ASC '
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO r_r02.*, num_row_id
	LET fec_i = EXTEND(vm_fecha_desde, YEAR TO SECOND)
	LET fec_f = EXTEND(vm_fecha_hasta, YEAR TO SECOND) + 23 UNITS HOUR +
			59 UNITS MINUTE + 59 UNITS SECOND  
	SELECT COUNT(*) INTO cuantos
		FROM rept020
		WHERE r20_compania  = vg_codcia
		  AND r20_localidad = vg_codloc
		  AND r20_bodega    = r_r02.r02_codigo
		  AND r20_item      = rm_r20.r20_item
		  AND r20_fecing    BETWEEN fec_i AND fec_f
	IF cuantos = 0 THEN
		LET codloc = vg_codloc
		IF vg_codloc = 5 THEN
			--LET codloc = 3
		END IF
		SELECT COUNT(*) INTO cuantos
			FROM rept020, rept019
			WHERE r20_compania    = vg_codcia
			  AND r20_localidad   = codloc
			  AND r20_cod_tran    = 'TR'
			  AND r20_item        = rm_r20.r20_item
			  AND r20_fecing      BETWEEN fec_i AND fec_f
			  AND r19_compania    = r20_compania
			  AND r19_localidad   = r20_localidad
			  AND r19_cod_tran    = r20_cod_tran
			  AND r19_num_tran    = r20_num_tran
			  AND (r19_bodega_ori = r_r02.r02_codigo
			   OR r19_bodega_dest = r_r02.r02_codigo)
		IF cuantos = 0 THEN
			CALL obtener_stock_inicial_bodega_fecha(r_r02.r02_codigo)
			IF vm_stock_inicial = 0 THEN
				CONTINUE FOREACH
			END IF
		END IF
	END IF
	LET vm_r_rows[vm_num_rows] = num_row_id
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 AND vm_solo_costo = 'N' THEN
	CALL obtener_stock_inicial_bodega()
	CALL muestra_contadores(0, vm_num_rows)
	RETURN
END IF
LET vm_row_current = 1
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_contadores_det(0, vm_num_det)
CALL mostrar_registro(vm_r_rows[vm_row_current])

END FUNCTION



FUNCTION control_detalle()

CALL control_consulta_detalle(1)
IF vm_num_det = 0 AND vm_solo_costo = 'N' THEN
	CALL obtener_stock_inicial_bodega()
	RETURN
END IF
CALL muestra_detalle()

END FUNCTION



FUNCTION obtener_stock_inicial_bodega()
DEFINE fec_ini		LIKE rept020.r20_fecing
DEFINE bodega		LIKE rept019.r19_bodega_ori
DEFINE codloc		LIKE rept019.r19_localidad
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE r_g21		RECORD LIKE gent021.*
DEFINE query         	CHAR(800)

IF vm_num_rows <= 1 THEN
	CALL fl_mensaje_consulta_sin_registros()
END IF
LET fec_ini = EXTEND(vm_fecha_desde, YEAR TO SECOND)
LET codloc = 0
IF vg_codloc = 3 THEN
	--LET codloc = 5
	LET codloc = 3
END IF
IF vm_num_rows <= 1 THEN
	LET query = 'SELECT rept020.*, rept019.*, gent021.* ' ,
		' FROM rept020, rept019, gent021 ',
		' WHERE r20_compania   = ', vg_codcia,
		'   AND r20_localidad IN (', vg_codloc, ', ', codloc, ')',
		'   AND r20_item       = "', rm_r20.r20_item CLIPPED, '"',
		'   AND r20_fecing    <= "', fec_ini, '"',
		'   AND r20_compania   = r19_compania ',
		'   AND r20_localidad  = r19_localidad ',
		'   AND r20_cod_tran   = r19_cod_tran ',
		'   AND r20_num_tran   = r19_num_tran ',
		'   AND r20_cod_tran   = g21_cod_tran ',
		' ORDER BY r20_fecing DESC'
	PREPARE cons_stock FROM query
	DECLARE q_sto CURSOR FOR cons_stock
	LET vm_stock_inicial = 0
	OPEN q_sto
	FETCH q_sto INTO r_r20.*, r_r19.*, r_g21.*
	IF STATUS <> NOTFOUND THEN
		LET bodega = vm_bodega
		IF r_g21.g21_tipo = 'T' THEN
			IF vm_bodega = r_r19.r19_bodega_ori THEN
				LET bodega = r_r19.r19_bodega_ori
			END IF
			IF vm_bodega = r_r19.r19_bodega_dest THEN
				LET bodega = r_r19.r19_bodega_dest
			END IF
		ELSE
			IF r_g21.g21_tipo <> 'C' THEN
				LET bodega = r_r20.r20_bodega
			END IF
		END IF
		IF r_g21.g21_tipo <> 'T' THEN
			IF r_g21.g21_tipo = 'E' THEN
				LET r_r20.r20_cant_ven =
					r_r20.r20_cant_ven * (-1)
			END IF
			LET vm_stock_inicial = r_r20.r20_stock_ant +
						r_r20.r20_cant_ven
		ELSE
			IF bodega = r_r19.r19_bodega_ori THEN
				LET vm_stock_inicial = r_r20.r20_stock_ant
							- r_r20.r20_cant_ven
			END IF
			IF bodega = r_r19.r19_bodega_dest THEN
				LET vm_stock_inicial = r_r20.r20_stock_bd
							+ r_r20.r20_cant_ven
			END IF
		END IF
	END IF
ELSE
	CALL obtener_stock_inicial_bodega_fecha(vm_bodega)
	DISPLAY BY NAME vm_stock_inicial
END IF
IF vm_num_rows > 1 THEN
	RETURN
END IF
IF (bodega <> vm_bodega) OR (vm_bodega IS NULL) THEN
	IF vm_bodega IS NOT NULL THEN
		--CALL fl_mostrar_mensaje('Pero tiene Stock Inicial en la Bodega ' || bodega CLIPPED, 'info')
	END IF
	CALL obtener_stock_inicial_bodega_fecha(vm_bodega)
	LET vm_bodega = bodega
END IF
DISPLAY BY NAME vm_stock_inicial, vm_bodega

END FUNCTION



FUNCTION obtener_stock_inicial_bodega_fecha(bodega)
DEFINE bodega		LIKE rept019.r19_bodega_ori
DEFINE codloc		LIKE rept019.r19_localidad
DEFINE fec_ini		LIKE rept019.r19_fecing
DEFINE query         	CHAR(5000)

LET fec_ini = EXTEND(vm_fecha_desde, YEAR TO SECOND)
LET codloc = 0
IF vg_codloc = 3 THEN
	--LET codloc = 5
	LET codloc = 3
END IF
LET query = 'SELECT (NVL(CASE WHEN g21_tipo = "E" ',
				'THEN a.r20_cant_ven * (-1) ',
				'ELSE a.r20_cant_ven ',
			'END, 0) + a.r20_stock_ant) saldo, ',
			'MAX(a.r20_fecing) fecha ',
			'FROM rept020 a, gent021 ',
			'WHERE a.r20_compania   = ', vg_codcia,
			'  AND a.r20_localidad IN (', vg_codloc,', ',codloc,')',
			'  AND a.r20_cod_tran  NOT IN ("TR", "AC") ',
			'  AND a.r20_bodega     = "', bodega, '"',
			'  AND a.r20_item       = "',
						rm_r20.r20_item CLIPPED, '"',
			'  AND a.r20_fecing    <= "', fec_ini, '"',
			'  AND a.r20_fecing     = ',
				'(SELECT MAX(b.r20_fecing) ',
				'FROM rept020 b ',
				'WHERE b.r20_compania  = a.r20_compania ',
				'  AND b.r20_localidad = a.r20_localidad ',
				'  AND b.r20_bodega    = a.r20_bodega ',
				'  AND b.r20_item      = a.r20_item) ',
			'  AND g21_cod_tran     = a.r20_cod_tran ',
			'GROUP BY 1 ',
		'UNION ',
		'SELECT (NVL(CASE WHEN a.r19_bodega_ori = "', bodega, '"',
					'THEN b.r20_cant_ven * (-1) ',
					'ELSE b.r20_cant_ven ',
				'END, 0) + b.r20_stock_bd) saldo, ',
				'MAX(b.r20_fecing) fecha ',
			'FROM rept019 a, rept020 b ',
			'WHERE a.r19_compania      = ', vg_codcia,
			'  AND a.r19_localidad    IN (', vg_codloc, ', ',
							codloc, ')',
			'  AND a.r19_cod_tran      = "TR" ',
			'  AND (a.r19_bodega_ori   = "', bodega, '"',
			'   OR  a.r19_bodega_dest  = "', bodega, '")',
			'  AND b.r20_compania      = a.r19_compania ',
			'  AND b.r20_localidad     = a.r19_localidad ',
			'  AND b.r20_cod_tran      = a.r19_cod_tran ',
			'  AND b.r20_num_tran      = a.r19_num_tran ',
			'  AND b.r20_item          = "',
						rm_r20.r20_item CLIPPED, '"',
			'  AND b.r20_fecing       <= "', fec_ini, '"',
			'  AND b.r20_fecing        = ',
				'(SELECT MAX(d.r20_fecing)',
				'FROM rept019 c, rept020 d ',
				'WHERE c.r19_compania  = a.r19_compania ',
				'  AND c.r19_localidad = a.r19_localidad ',
				'  AND c.r19_cod_tran  = a.r19_cod_tran ',
				'  AND c.r19_num_tran  = a.r19_num_tran ',
				'  AND d.r20_compania  = c.r19_compania ',
				'  AND d.r20_localidad = c.r19_localidad ',
				'  AND d.r20_cod_tran  = c.r19_cod_tran ',
				'  AND d.r20_num_tran  = c.r19_num_tran ',
				'  AND d.r20_item      = b.r20_item) ',
		'GROUP BY 1 ',
		'INTO TEMP t1 '
PREPARE exec_tmp_si FROM query
EXECUTE exec_tmp_si
LET fec_ini = NULL
DECLARE q_saldo CURSOR FOR
	SELECT a.saldo, MAX(a.fecha) fecha
		FROM t1 a
		WHERE a.fecha = (SELECT MAX(b.fecha) FROM t1 b)
		GROUP BY 1
OPEN q_saldo
FETCH q_saldo INTO vm_stock_inicial, fec_ini
CLOSE q_saldo
FREE q_saldo
DROP TABLE t1
IF fec_ini IS NULL THEN
	LET vm_stock_inicial = 0
END IF

END FUNCTION



FUNCTION muestra_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_contadores_det(0, vm_num_det)
IF vm_num_det = 0 AND vm_solo_costo = 'N' THEN
	CALL obtener_stock_inicial_bodega()
END IF
IF vm_solo_costo = 'S' THEN
	CLEAR vm_stock_inicial, vm_tot_ing, vm_tot_egr
END IF

END FUNCTION



FUNCTION muestra_anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_contadores_det(0, vm_num_det)
IF vm_num_det = 0 AND vm_solo_costo = 'N' THEN
	CALL obtener_stock_inicial_bodega()
END IF
IF vm_solo_costo = 'S' THEN
	CLEAR vm_stock_inicial, vm_tot_ing, vm_tot_egr
END IF

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current	SMALLINT
DEFINE num_rows		SMALLINT

IF vg_gui = 1 THEN
	DISPLAY "" AT 1, 1
	DISPLAY row_current, " de ", num_rows AT 1, 66
END IF

END FUNCTION



FUNCTION mostrar_registro(num_reg)
DEFINE num_reg		INTEGER
DEFINE mensaje		VARCHAR(100)

IF vm_num_rows <= 0 THEN
	RETURN
END IF
DECLARE q_dt CURSOR FOR SELECT * FROM rept002 WHERE ROWID = num_reg
OPEN q_dt
FETCH q_dt INTO rm_r02.*
IF STATUS = NOTFOUND THEN
	LET mensaje = 'No existe registro con ROWID: ', vm_row_current
	CALL fl_mostrar_mensaje(mensaje, 'exclamation')
	CLOSE q_dt
	FREE q_dt
	RETURN
END IF	
CLOSE q_dt
FREE q_dt
LET vm_bodega = rm_r02.r02_codigo
DISPLAY BY NAME rm_r20.r20_item, vm_bodega, vm_fecha_desde, vm_fecha_hasta,
		vm_solo_fact
DISPLAY rm_r02.r02_nombre TO nom_bodega
CALL control_consulta_detalle(1)
CALL muestra_lineas_detalle()

END FUNCTION



FUNCTION control_consulta_detalle(mostrar_stock)
DEFINE mostrar_stock	SMALLINT
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_g21		RECORD LIKE gent021.*
DEFINE bodega		LIKE rept019.r19_bodega_ori
DEFINE codloc		LIKE rept019.r19_localidad
DEFINE fec_ini		LIKE rept020.r20_fecing
DEFINE fec_fin		LIKE rept020.r20_fecing
DEFINE query         	CHAR(1400)
DEFINE saldo		DECIMAL (8,2)
DEFINE i		SMALLINT

LET fec_ini = EXTEND(vm_fecha_desde, YEAR TO SECOND)
LET fec_fin = EXTEND(vm_fecha_hasta, YEAR TO SECOND) + 23 UNITS HOUR +
	      59 UNITS MINUTE + 59 UNITS SECOND  
LET codloc = 0
IF vg_codloc = 3 THEN
	--LET codloc = 5
END IF
LET query = 'SELECT rept020.*, rept019.*, gent021.*, rept020.ROWID ' ,
		' FROM rept020, rept019, gent021 ',
		' WHERE r20_compania  = ', vg_codcia,
		'   AND r20_localidad IN (', vg_codloc, ', ', codloc, ')',
		'   AND r20_item      = "', rm_r20.r20_item, '"',
		'   AND r20_fecing    BETWEEN "', fec_ini, '"',
					' AND "', fec_fin, '"',
		'   AND r20_compania  = r19_compania ',
		'   AND r20_localidad = r19_localidad ',
		'   AND r20_cod_tran  = r19_cod_tran ',
		'   AND r20_num_tran  = r19_num_tran ',
		'   AND r20_cod_tran  = g21_cod_tran ',
		' ORDER BY r20_fecing, rept020.ROWID '
PREPARE consulta FROM query
DECLARE q_consulta CURSOR FOR consulta
LET i          = 1
LET vm_tot_ing = 0
LET vm_tot_egr = 0
LET saldo      = 0
FOREACH q_consulta INTO r_r20.*, r_r19.*, r_g21.*
	LET bodega = "**"
	IF r_g21.g21_tipo = 'T' THEN
		IF vm_bodega = r_r19.r19_bodega_ori THEN
			LET bodega = r_r19.r19_bodega_ori
		END IF
		IF vm_bodega = r_r19.r19_bodega_dest THEN
			LET bodega = r_r19.r19_bodega_dest
		END IF
	ELSE
		IF r_g21.g21_tipo <> 'C' THEN
			LET bodega = r_r20.r20_bodega
		END IF
	END IF
	IF vm_bodega <> bodega THEN
		CONTINUE FOREACH
	END IF
	IF i = 1 THEN
		IF r_g21.g21_tipo <> 'T' THEN
			LET vm_stock_inicial = r_r20.r20_stock_ant
		ELSE
			IF bodega = r_r19.r19_bodega_ori THEN
				LET vm_stock_inicial = r_r20.r20_stock_ant
			END IF
			IF bodega = r_r19.r19_bodega_dest THEN
				LET vm_stock_inicial = r_r20.r20_stock_bd
			END IF
		END IF
		LET saldo = vm_stock_inicial
		IF mostrar_stock THEN
			DISPLAY BY NAME vm_stock_inicial
		END IF
	END IF
	LET r_detalle[i].r20_cod_tran = r_r20.r20_cod_tran
	LET r_detalle[i].r20_num_tran = r_r20.r20_num_tran
	LET r_detalle[i].fecha        = DATE(r_r20.r20_fecing)
	LET r_detalle[i].cliente      = r_r19.r19_nomcli
	IF r_r19.r19_nomcli IS NULL OR r_r19.r19_nomcli = ' ' THEN
		LET r_detalle[i].cliente = r_r19.r19_referencia
	END IF
	CASE
		WHEN(r_g21.g21_tipo = 'I')
			IF vm_solo_costo = 'N' THEN
				LET r_detalle[i].cant_egr = 0
				LET r_detalle[i].cant_ing = r_r20.r20_cant_ven
				LET r_detalle[i].saldo    = r_r20.r20_cant_ven
								+ saldo
				LET vm_tot_ing            = vm_tot_ing
							+ r_r20.r20_cant_ven
			ELSE
				LET r_detalle[i].cant_egr = r_r20.r20_costo
				LET r_detalle[i].cant_ing = r_r20.r20_costnue_mb
				LET r_detalle[i].saldo    = r_r20.r20_costant_mb
			END IF
		WHEN(r_g21.g21_tipo = 'E')
			IF vm_solo_costo = 'N' THEN
				LET r_detalle[i].cant_egr = r_r20.r20_cant_ven
				LET r_detalle[i].cant_ing = 0
				LET r_detalle[i].saldo    = saldo
							- r_r20.r20_cant_ven
				LET vm_tot_egr            = vm_tot_egr
							+ r_r20.r20_cant_ven
			ELSE
				LET r_detalle[i].cant_egr = r_r20.r20_costo
				LET r_detalle[i].cant_ing = r_r20.r20_costnue_mb
				LET r_detalle[i].saldo    = r_r20.r20_costant_mb
			END IF
		WHEN(r_g21.g21_tipo = 'C')
			IF vm_solo_costo = 'N' THEN
				LET r_detalle[i].cant_egr = 0
				LET r_detalle[i].cant_ing = 0
				LET r_detalle[i].saldo    = saldo
			ELSE
				LET r_detalle[i].cant_egr = r_r20.r20_costo
				LET r_detalle[i].cant_ing = r_r20.r20_costnue_mb
				LET r_detalle[i].saldo    = r_r20.r20_costant_mb
			END IF
		WHEN(r_g21.g21_tipo = 'T')
			IF vm_solo_costo = 'S' THEN
				LET r_detalle[i].cant_egr = r_r20.r20_costo
				LET r_detalle[i].cant_ing = r_r20.r20_costnue_mb
				LET r_detalle[i].saldo    = r_r20.r20_costant_mb
				EXIT CASE
			END IF
			IF vm_bodega = r_r19.r19_bodega_ori THEN
				LET r_detalle[i].cant_egr = r_r20.r20_cant_ven
				LET r_detalle[i].cant_ing = 0
				LET r_detalle[i].saldo    = saldo - 
							    r_r20.r20_cant_ven 
				LET vm_tot_egr            = vm_tot_egr + 
							    r_r20.r20_cant_ven
			END IF
			IF vm_bodega = r_r19.r19_bodega_dest THEN
				LET r_detalle[i].cant_egr = 0
				LET r_detalle[i].cant_ing = r_r20.r20_cant_ven
				LET r_detalle[i].saldo    = r_r20.r20_cant_ven +
							    saldo
				LET vm_tot_ing            = vm_tot_ing + 
							    r_r20.r20_cant_ven
			END IF
	END CASE
	IF vm_solo_costo = 'N' THEN
		LET saldo = r_detalle[i].saldo
	END IF
	LET i = i + 1
	IF i > vm_max_det THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_det = i - 1

END FUNCTION



FUNCTION muestra_lineas_detalle()
DEFINE i		SMALLINT

CALL muestra_contadores_det(0, vm_num_det)
FOR i = 1 TO vm_size_arr 
	IF i <= vm_num_det THEN
		DISPLAY r_detalle[i].* TO r_detalle[i].*
	ELSE
		CLEAR r_detalle[i].*
	END IF
END FOR
IF vm_solo_costo = 'S' THEN
	CLEAR vm_tot_ing, vm_tot_egr
ELSE
	DISPLAY BY NAME vm_tot_ing, vm_tot_egr
END IF

END FUNCTION



FUNCTION muestra_detalle()
DEFINE i, j		SMALLINT
DEFINE ver_costo	SMALLINT
DEFINE param		VARCHAR(60)

IF vm_solo_costo = 'N' THEN
	DISPLAY BY NAME vm_tot_ing, vm_tot_egr, vm_stock_inicial
ELSE
	CLEAR vm_tot_ing, vm_tot_egr
END IF
IF vg_gui = 0 THEN
	CALL muestra_etiquetas_det(1, vm_num_det)
END IF
LET ver_costo = 0
WHILE TRUE
	IF ver_costo THEN
		CALL control_consulta_detalle(1)
		IF vm_num_det = 0 AND vm_solo_costo = 'N' THEN
			CALL obtener_stock_inicial_bodega()
			EXIT WHILE
		END IF
		IF vm_solo_costo = 'S' THEN
			CLEAR vm_stock_inicial, vm_tot_ing, vm_tot_egr
		ELSE
			DISPLAY BY NAME vm_stock_inicial, vm_tot_ing, vm_tot_egr
		END IF
	END IF
	CALL set_count(vm_num_det)
	DISPLAY ARRAY r_detalle TO r_detalle.*
		ON KEY(INTERRUPT)
			LET ver_costo = 0
			EXIT DISPLAY
		ON KEY(RETURN)
			LET i = arr_curr()
			CALL muestra_etiquetas_det(i, vm_num_det)
	       	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_1() 
		ON KEY(F5)
			LET i = arr_curr()
			LET j = scr_line()
			CALL fl_ver_transaccion_rep(vg_codcia, vg_codloc,
						r_detalle[i].r20_cod_tran,
						r_detalle[i].r20_num_tran)
			IF r_detalle[i].r20_cod_tran = 'IA' THEN
				LET param = vg_codloc, ' "',
						r_detalle[i].r20_cod_tran, '" ',
						r_detalle[i].r20_num_tran
				CALL ejecuta_comando('REPUESTOS', vg_modulo,
							'repp308 ', param)
			END IF
			LET int_flag = 0
		ON KEY(F6)
			CALL control_imprimir()
			LET int_flag = 0
		ON KEY(F7)
			IF rm_g05.g05_grupo = 'SI' AND flag_ver_item THEN
				LET i = arr_curr()
				CALL mostrar_item(i)
				LET int_flag = 0
			END IF
		ON KEY(F8)
			IF (rm_g05.g05_grupo = 'SI' OR rm_g05.g05_grupo = 'GE')
			THEN
				LET ver_costo = 1
				IF vm_solo_costo = 'N' THEN
					LET vm_solo_costo = 'S'
					LET int_flag = 0
					EXIT DISPLAY
				ELSE
					LET vm_solo_costo = 'N'
					LET int_flag = 0
					EXIT DISPLAY
				END IF
			END IF
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel('RETURN', '')
			--#CALL dialog.keysetlabel('ACCEPT','')
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
			--#IF (rm_g05.g05_grupo = 'SI' OR
				--#rm_g05.g05_grupo = 'GE')
			--#THEN
				--#IF vm_solo_costo = 'N' THEN
					--#CALL dialog.keysetlabel("F8","Ver Costo")
				--#ELSE
					--#CALL dialog.keysetlabel("F8","Ver Stock")
				--#END IF
			--#ELSE
				--#CALL dialog.keysetlabel("F8","")
			--#END IF
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#LET j = scr_line()
			--#CALL muestra_etiquetas_det(i, vm_num_det)
			--#IF rm_g05.g05_grupo = 'SI' AND flag_ver_item THEN
				--#CALL dialog.keysetlabel("F7","Ver Item")
			--#ELSE
				--#CALL dialog.keysetlabel("F7","")
			--#END IF
		--#AFTER DISPLAY 
			--#CONTINUE DISPLAY
	END DISPLAY
	IF ver_costo THEN
		CALL setear_botones_det()
		IF vm_solo_costo = 'S' THEN
			CLEAR vm_stock_inicial, vm_tot_ing, vm_tot_egr
		ELSE
			DISPLAY BY NAME vm_stock_inicial, vm_tot_ing, vm_tot_egr
		END IF
		CONTINUE WHILE
	END IF
	EXIT WHILE
END WHILE
CLEAR g21_nombre
CALL muestra_contadores_det(0, vm_num_det)
IF int_flag THEN
	IF vm_num_det > vm_size_arr THEN
		CALL muestra_lineas_detalle()
	END IF
END IF

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION muestra_etiquetas_det(i, num)
DEFINE i, num		SMALLINT
DEFINE r_g21		RECORD LIKE gent021.*

CALL muestra_contadores_det(i, num)
CALL fl_lee_cod_transaccion(r_detalle[i].r20_cod_tran) RETURNING r_g21.*
DISPLAY BY NAME r_g21.g21_nombre

END FUNCTION



FUNCTION setear_botones_det()

--#DISPLAY 'TP'       		TO tit_col1
--#DISPLAY 'Numero'		TO tit_col2
--#DISPLAY 'Fecha'       	TO tit_col3
--#DISPLAY 'Referencia' 	TO tit_col4
--#IF vm_solo_costo = 'N' THEN
	--#DISPLAY 'Ing.'	TO tit_col5
	--#DISPLAY 'Egr.'	TO tit_col6
	--#DISPLAY 'Saldo'	TO tit_col7
--#ELSE
	--#DISPLAY 'Costo'	TO tit_col5
	--#DISPLAY 'Cos. Nue.'	TO tit_col6
	--#DISPLAY 'Cos. Ant.'	TO tit_col7
--#END IF

END FUNCTION



FUNCTION control_imprimir()
DEFINE resul		SMALLINT

IF vm_num_rows = 1 THEN
	CALL imprimir_listado_una_bodega()
	RETURN
END IF
LET vm_imprimir = 'B'
CALL leer_parametros_imp()
IF int_flag THEN
	RETURN
END IF
CASE vm_imprimir
	WHEN 'B'
		CALL imprimir_listado_una_bodega()
	WHEN 'C'
		CALL imprimir_listado_por_bodega()
	WHEN 'T'
		CALL imprimir_listado_una_bodega()
		CALL imprimir_listado_por_bodega()
END CASE
LET int_flag = 0
CLOSE WINDOW w_repf307_2
RETURN

END FUNCTION



FUNCTION leer_parametros_imp()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE col_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

LET lin_menu = 0
LET row_ini  = 8
LET col_ini  = 18
LET num_rows = 8
LET num_cols = 50
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 9
	LET col_ini  = 15
	LET num_rows = 4
	LET num_cols = 52
END IF
OPEN WINDOW w_repf307_2 AT row_ini, col_ini WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_repf307_2 FROM "../forms/repf307_2"
ELSE
	OPEN FORM f_repf307_2 FROM "../forms/repf307_2c"
END IF
DISPLAY FORM f_repf307_2
IF vg_gui = 0 THEN
	CALL muestra_imprimir(vm_imprimir)
END IF
LET int_flag = 0
INPUT BY NAME vm_imprimir
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD vm_imprimir
		IF vm_imprimir IS NOT NULL THEN
			DISPLAY BY NAME vm_imprimir
			IF vg_gui = 0 THEN
				CALL muestra_imprimir(vm_imprimir)
			END IF
		ELSE
			IF vg_gui = 0 THEN
				CLEAR tit_imprimir
			END IF
		END IF
END INPUT
IF int_flag THEN
	CLOSE WINDOW w_repf307_2
	RETURN
END IF

END FUNCTION



FUNCTION imprimir_listado_una_bodega()
DEFINE comando		VARCHAR(100)
DEFINE i		SMALLINT

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
START REPORT reporte_kardex_una_bodega TO PIPE comando
FOR i = 1 TO vm_num_det
	OUTPUT TO REPORT reporte_kardex_una_bodega(i)
END FOR
FINISH REPORT reporte_kardex_una_bodega

END FUNCTION



FUNCTION imprimir_listado_por_bodega()
DEFINE comando		VARCHAR(100)
DEFINE i, j		SMALLINT
DEFINE r_r02		RECORD LIKE rept002.*

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
START REPORT reporte_kardex_por_bodega TO PIPE comando
LET vm_saldo_fin = 0
LET vm_tot_ing2  = 0
LET vm_tot_egr2  = 0
FOR i = 1 TO vm_num_rows
	SELECT * INTO r_r02.* FROM rept002 WHERE ROWID = vm_r_rows[i]
	LET vm_bodega = r_r02.r02_codigo
	CALL control_consulta_detalle(0)
	FOR j = 1 TO vm_num_det
		OUTPUT TO REPORT reporte_kardex_por_bodega(r_r02.*, j)
	END FOR
	LET vm_tot_ing2 = vm_tot_ing
	LET vm_tot_egr2 = vm_tot_egr
END FOR
FINISH REPORT reporte_kardex_por_bodega
SELECT r02_codigo INTO vm_bodega FROM rept002
	WHERE ROWID = vm_r_rows[vm_row_current]
CALL control_consulta_detalle(0)

END FUNCTION



REPORT reporte_kardex_una_bodega(i)
DEFINE i		SMALLINT
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE usuario		VARCHAR(19,15)
DEFINE modulo		VARCHAR(40)
DEFINE factura		VARCHAR(15)
DEFINE fecha_ini	DATE
DEFINE escape		SMALLINT
DEFINE act_comp		SMALLINT
DEFINE desact_comp	SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_neg, des_neg	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	80
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresión
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_neg	= 71		# Activar negrita.
	LET des_neg	= 72		# Desactivar negrita.
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo      = "MODULO: ", r_g50.g50_nombre[1, 19] CLIPPED
	LET usuario     = "USUARIO: ", vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_lee_compania(vg_codcia) RETURNING r_g01.*
	print ASCII escape;
	print ASCII desact_comp;
	print ASCII escape;
	print ASCII act_10cpi;
	PRINT COLUMN 005, r_g01.g01_razonsocial,
  	      COLUMN 074, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 029, "LISTADO INGRESOS/EGRESOS ITEMS",
	      COLUMN 074, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 010, "** ITEM          : ", rm_r20.r20_item[1, 6] CLIPPED,
					" ", rm_r10.r10_nombre[1, 46] CLIPPED
	PRINT COLUMN 010, "** BODEGA        : ", vm_bodega CLIPPED, " ",
						rm_r02.r02_nombre CLIPPED
	PRINT COLUMN 010, "** FECHA INICIAL : ", vm_fecha_desde
							USING "dd-mm-yyyy"
	PRINT COLUMN 010, "** FECHA FINAL   : ", vm_fecha_hasta
							USING "dd-mm-yyyy"
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
 		1 SPACES, TIME,
	      COLUMN 062, usuario
	PRINT "--------------------------------------------------------------------------------"
	PRINT COLUMN 001, "TP",
	      COLUMN 005, "NUMERO",
	      COLUMN 013, "FECHA TRAN",
	      COLUMN 027, "R E F E R E N C I A",
	      COLUMN 051, "  INGRESO",
	      COLUMN 061, "   EGRESO",
	      COLUMN 071, "     SALDO"
	PRINT "--------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 3 LINES
	IF i - 1 = 0 THEN
		LET fecha_ini = vm_fecha_desde - 1 UNITS DAY
		print ASCII escape;
		print ASCII act_neg;
		PRINT COLUMN 043, "STOCK INICIAL AL ",
			fecha_ini USING "dd-mm-yyyy", " : ",
			vm_stock_inicial USING "---,--&.##";
		print ASCII escape;
		print ASCII des_neg
		SKIP 1 LINES
	END IF
	LET factura = r_detalle[i].r20_num_tran
	CALL fl_justifica_titulo('I', factura, 8) RETURNING factura
	PRINT COLUMN 001, r_detalle[i].r20_cod_tran,
	      COLUMN 004, factura,
	      COLUMN 013, r_detalle[i].fecha		USING "dd-mm-yyyy",
	      COLUMN 024, r_detalle[i].cliente[1, 26] CLIPPED,
	      COLUMN 051, r_detalle[i].cant_ing		USING "##,##&.##",
	      COLUMN 061, r_detalle[i].cant_egr		USING "##,##&.##";
	IF i = vm_num_det THEN
		print ASCII escape;
		print ASCII act_neg;
		PRINT COLUMN 073, r_detalle[i].saldo	USING "---,--&.##";
		print ASCII escape;
		print ASCII des_neg
	ELSE
		PRINT COLUMN 071, r_detalle[i].saldo	USING "---,--&.##"
	END IF
	
ON LAST ROW
	NEED 2 LINES
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 053, "---------",
	      COLUMN 063, "---------"
	PRINT COLUMN 038, "TOTALES ==>  ", vm_tot_ing USING "##,##&.##",
	      COLUMN 061, vm_tot_egr USING "##,##&.##";
	print ASCII escape;
	print ASCII des_neg;
	print ASCII escape;
	print ASCII act_comp

END REPORT



REPORT reporte_kardex_por_bodega(r_r02, i)
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE i		SMALLINT
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE usuario		VARCHAR(19,15)
DEFINE modulo		VARCHAR(40)
DEFINE factura		VARCHAR(15)
DEFINE fecha_ini	DATE
DEFINE escape		SMALLINT
DEFINE act_comp		SMALLINT
DEFINE desact_comp	SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_neg, des_neg	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	80
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresión
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_neg	= 71		# Activar negrita.
	LET des_neg	= 72		# Desactivar negrita.
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo      = "MODULO: ", r_g50.g50_nombre[1, 19] CLIPPED
	LET usuario     = "USUARIO: ", vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_lee_compania(vg_codcia) RETURNING r_g01.*
	print ASCII escape;
	print ASCII desact_comp;
	print ASCII escape;
	print ASCII act_10cpi;
	PRINT COLUMN 005, r_g01.g01_razonsocial,
  	      COLUMN 074, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 029, "LISTADO ING./EGR. ITEMS POR BODEGA",
	      COLUMN 074, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 010, "** ITEM          : ", rm_r20.r20_item[1, 6] CLIPPED,
					" ", rm_r10.r10_nombre[1, 46] CLIPPED
	PRINT COLUMN 010, "** FECHA INICIAL : ", vm_fecha_desde
							USING "dd-mm-yyyy"
	PRINT COLUMN 010, "** FECHA FINAL   : ", vm_fecha_hasta
							USING "dd-mm-yyyy"
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
 		1 SPACES, TIME,
	      COLUMN 062, usuario
	PRINT "--------------------------------------------------------------------------------"
	PRINT COLUMN 003, "TP",
	      COLUMN 007, "NUMERO",
	      COLUMN 015, "FECHA TRAN",
	      COLUMN 028, "R E F E R E N C I A",
	      COLUMN 051, "  INGRESO",
	      COLUMN 061, "   EGRESO",
	      COLUMN 071, "     SALDO"
	PRINT "--------------------------------------------------------------------------------"

BEFORE GROUP OF r_r02.r02_codigo
	NEED 7 LINES
	LET fecha_ini = vm_fecha_desde - 1 UNITS DAY
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 003, r_r02.r02_codigo,
	      COLUMN 006, r_r02.r02_nombre CLIPPED,
	      COLUMN 043, "STOCK INICIAL AL ",
		fecha_ini USING "dd-mm-yyyy", " : ",
		vm_stock_inicial USING "---,--&.##";
	print ASCII escape;
	print ASCII des_neg
	SKIP 1 LINES

ON EVERY ROW
	NEED 5 LINES
	LET factura = r_detalle[i].r20_num_tran
	CALL fl_justifica_titulo('I', factura, 8) RETURNING factura
	PRINT COLUMN 003, r_detalle[i].r20_cod_tran,
	      COLUMN 006, factura,
	      COLUMN 015, r_detalle[i].fecha		USING "dd-mm-yyyy",
	      COLUMN 026, r_detalle[i].cliente[1, 24] CLIPPED,
	      COLUMN 051, r_detalle[i].cant_ing		USING "##,##&.##",
	      COLUMN 061, r_detalle[i].cant_egr		USING "##,##&.##";
	IF i = vm_num_det THEN
		print ASCII escape;
		print ASCII act_neg;
		PRINT COLUMN 073, r_detalle[i].saldo	USING "---,--&.##";
		print ASCII escape;
		print ASCII des_neg
		LET vm_saldo_fin = vm_saldo_fin + r_detalle[i].saldo
	ELSE
		PRINT COLUMN 071, r_detalle[i].saldo	USING "---,--&.##"
	END IF
	
AFTER GROUP OF r_r02.r02_codigo
	NEED 4 LINES
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 053, "---------",
	      COLUMN 063, "---------"
	PRINT COLUMN 038, "TOTALES ==>  ", vm_tot_ing2 USING "##,##&.##",
	      COLUMN 061, vm_tot_egr2 USING "##,##&.##";
	print ASCII escape;
	print ASCII des_neg
	SKIP 1 LINES

ON LAST ROW
	NEED 1 LINES
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 045, "SALDO TOTAL AL ",
		vm_fecha_hasta USING "dd-mm-yyyy", " : ",
		vm_saldo_fin USING "---,--&.##";
	print ASCII escape;
	print ASCII des_neg;
	print ASCII escape;
	print ASCII act_comp

END REPORT



FUNCTION borrar_pantalla()
DEFINE i		SMALLINT

FOR i = 1 TO vm_max_det
	INITIALIZE r_detalle[i].* TO NULL
END FOR
CLEAR FORM 

END FUNCTION



FUNCTION muestra_imprimir(imprimir)
DEFINE imprimir		CHAR(1)
DEFINE tit_imprimir	VARCHAR(40)

CASE imprimir
	WHEN 'B'
		LET tit_imprimir = 'SOLO LISTADO DE ESTA BODEGA'
	WHEN 'C'
		LET tit_imprimir = 'TODAS LAS BODEGAS DE ESTA CONSULTA'
	WHEN 'T'
		LET tit_imprimir = 'T O D O S'
	OTHERWISE
		CLEAR vm_imprimir, tit_imprimir
END CASE
DISPLAY BY NAME tit_imprimir

END FUNCTION



FUNCTION mostrar_item(i)
DEFINE i		SMALLINT
DEFINE comando		VARCHAR(250)
DEFINE run_prog		CHAR(10)

LET run_prog = 'fglrun '
IF vg_gui = 0 THEN
	LET run_prog = 'fglgo '
END IF
LET comando = run_prog, 'repp108 ', vg_base, ' RE ', vg_codcia, ' ', vg_codloc,
		' "', rm_r20.r20_item CLIPPED, '"'
RUN comando

END FUNCTION



FUNCTION ejecuta_comando(modulo, mod, prog, param)
DEFINE modulo		VARCHAR(15)
DEFINE mod		LIKE gent050.g50_modulo
DEFINE prog		VARCHAR(10)
DEFINE param		VARCHAR(60)
DEFINE comando          VARCHAR(250)
DEFINE run_prog		VARCHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, modulo,
		vg_separador, 'fuentes', vg_separador, run_prog, prog,
		vg_base, ' ', mod, ' ', vg_codcia, ' ', param
RUN comando

END FUNCTION



FUNCTION llamar_visor_teclas()
DEFINE a		SMALLINT

IF vg_gui = 0 THEN
	CALL fl_visor_teclas_caracter() RETURNING int_flag 
	LET a = fgl_getkey()
	CLOSE WINDOW w_tf
	LET int_flag = 0
END IF

END FUNCTION



FUNCTION control_visor_teclas_caracter_1() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Ver Transacción'          AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Imprimir Listado'         AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
