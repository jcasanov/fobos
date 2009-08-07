------------------------------------------------------------------------------
-- Titulo           : vehp303.4gl - Consulta de vehículos vendidos
-- Elaboracion      : 29-nov-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun vehp303 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE vm_nuevoprog     VARCHAR(400)
DEFINE rm_veh		RECORD LIKE veht030.*
DEFINE rm_veh2		RECORD LIKE veht031.*
DEFINE rm_mod		RECORD LIKE veht022.*
DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE vm_scr_lin       SMALLINT
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_ter	DATE
DEFINE vm_total         DECIMAL(12,2)
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE rm_det		ARRAY [1000] OF RECORD
				v30_bodega_ori	LIKE veht030.v30_bodega_ori,
				tit_fecha_vta	DATE,
				tit_siglas	LIKE veht001.v01_iniciales,
				v30_nomcli	LIKE veht030.v30_nomcli,
				tit_modelo_det	LIKE veht022.v22_modelo,
				tit_valor_vta	DECIMAL(12,2)
			END RECORD
DEFINE rm_tran		ARRAY [1000] OF RECORD
				v30_cod_tran	LIKE veht030.v30_cod_tran,
				v30_num_tran	LIKE veht030.v30_num_tran
			END RECORD

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'vehp303'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_det = 1000
OPEN WINDOW w_mas AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_veh FROM "../forms/vehf303_1"
DISPLAY FORM f_veh
LET vm_scr_lin = 0
CALL muestra_contadores_det(0)
CALL borrar_cabecera()
CALL mostrar_cabecera_forma()
WHILE TRUE
	MENU 'OPCIONES'
		BEFORE MENU
			CALL borrar_detalle()
			CALL mostrar_cabecera_forma()
			CALL control_consulta()
			IF int_flag THEN
        	        	EXIT MENU
			END IF
		COMMAND KEY ('C') 'Consultar'
			CALL borrar_cabecera()
			CALL borrar_detalle()
			CALL mostrar_cabecera_forma()
			CALL control_consulta()
			IF int_flag THEN
        	        	EXIT MENU
			END IF
		COMMAND KEY('S') 'Salir'
        	        EXIT MENU
	END MENU
END WHILE

END FUNCTION



FUNCTION mostrar_cabecera_forma()

DISPLAY 'CB'          TO tit_col1
DISPLAY 'Fec. Vta.'   TO tit_col2
DISPLAY 'Sig.'        TO tit_col3
DISPLAY 'Cliente'     TO tit_col4
DISPLAY 'Modelo'      TO tit_col5
DISPLAY 'Valor Venta' TO tit_col6

END FUNCTION



FUNCTION control_consulta()
DEFINE i,j,l,col	SMALLINT
DEFINE expr_gen		VARCHAR(1500)
DEFINE query		VARCHAR(600)
DEFINE expr_sql         VARCHAR(400)
DEFINE expr_sql2        VARCHAR(100)
DEFINE r_veh		RECORD LIKE veht030.*
DEFINE r_mod		RECORD LIKE veht020.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_ven		RECORD LIKE veht001.*
DEFINE r_bod		RECORD LIKE veht002.*
DEFINE mone_aux		LIKE gent013.g13_moneda
DEFINE nomm_aux		LIKE gent013.g13_nombre
DEFINE deci_aux		LIKE gent013.g13_decimales
DEFINE codv_aux		LIKE veht001.v01_vendedor
DEFINE nomv_aux		LIKE veht001.v01_nombres
DEFINE codm_aux		LIKE veht020.v20_modelo
DEFINE noml_aux		LIKE veht020.v20_linea
DEFINE codb_aux		LIKE veht002.v02_bodega
DEFINE nomb_aux		LIKE veht002.v02_nombre
DEFINE fecha_ter	DATE

OPTIONS INPUT NO WRAP
INITIALIZE mone_aux, codv_aux, codm_aux TO NULL
FOR i = 1 TO vm_max_det
	INITIALIZE rm_det[i].*, rm_tran[i].* TO NULL
END FOR
LET vm_fecha_ter      = TODAY
LET rm_veh.v30_moneda = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_veh.v30_moneda) RETURNING r_mon.* 
IF r_mon.g13_moneda IS NULL THEN
	CALL fgl_winmessage(vg_producto,'Moneda no existe moneda base.','stop')
	EXIT PROGRAM
END IF
DISPLAY r_mon.g13_nombre TO tit_mon_bas
LET vm_num_det = 0
LET int_flag   = 0
INPUT BY NAME rm_veh.v30_moneda, vm_fecha_ini, vm_fecha_ter,
	rm_veh.v30_vendedor, rm_mod.v22_modelo, rm_mod.v22_bodega
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		EXIT PROGRAM
	ON KEY(F2)
		IF infield(v30_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING mone_aux, nomm_aux, deci_aux
			LET int_flag = 0
			IF mone_aux IS NOT NULL THEN
				LET rm_veh.v30_moneda = mone_aux
				DISPLAY BY NAME rm_veh.v30_moneda 
				DISPLAY nomm_aux TO tit_mon_bas
			END IF 
		END IF
		IF infield(v30_vendedor) THEN
			CALL fl_ayuda_vendedores_veh(vg_codcia)
				RETURNING codv_aux, nomv_aux
			LET int_flag = 0
			IF codv_aux IS NOT NULL THEN
				LET rm_veh.v30_vendedor = codv_aux
				DISPLAY BY NAME rm_veh.v30_vendedor
				DISPLAY nomv_aux TO tit_vendedor
			END IF
		END IF
		IF infield(v22_modelo) THEN
			CALL fl_ayuda_modelos_veh(vg_codcia)
				RETURNING codm_aux, noml_aux
			LET int_flag = 0
			IF codm_aux IS NOT NULL THEN
				LET rm_mod.v22_modelo = codm_aux
				DISPLAY BY NAME rm_mod.v22_modelo
				CALL fl_lee_modelo_veh(vg_codcia,
						rm_mod.v22_modelo)
					RETURNING r_mod.*
				DISPLAY r_mod.v20_modelo_ext TO tit_modelo
			END IF
		END IF
		IF infield(v22_bodega) THEN
			CALL fl_ayuda_bodegas_veh(vg_codcia)
				RETURNING codb_aux, nomb_aux
			LET int_flag = 0
			IF codb_aux IS NOT NULL THEN
				LET rm_mod.v22_bodega = codb_aux
				DISPLAY BY NAME rm_mod.v22_bodega
				DISPLAY nomb_aux TO tit_bodega
			END IF
		END IF
	BEFORE FIELD vm_fecha_ter
		LET fecha_ter = vm_fecha_ter
	AFTER FIELD v30_moneda 
		IF rm_veh.v30_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_veh.v30_moneda)
				RETURNING r_mon.* 
			IF r_mon.g13_moneda IS NULL  THEN
				CALL fgl_winmessage(vg_producto,'Moneda no existe.','exclamation')
				NEXT FIELD v30_moneda
			END IF
		ELSE
			LET rm_veh.v30_moneda = rg_gen.g00_moneda_base
			CALL fl_lee_moneda(rm_veh.v30_moneda) RETURNING r_mon.* 
			DISPLAY BY NAME rm_veh.v30_moneda
		END IF
		DISPLAY r_mon.g13_nombre TO tit_mon_bas
	AFTER FIELD vm_fecha_ini 
		IF vm_fecha_ini IS NOT NULL THEN
			IF vm_fecha_ini > TODAY THEN
				CALL fgl_winmessage(vg_producto,'La fecha de inicio no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD vm_fecha_ini
			END IF
		END IF
	AFTER FIELD vm_fecha_ter 
		IF vm_fecha_ter IS NOT NULL THEN
			IF vm_fecha_ter > TODAY THEN
				CALL fgl_winmessage(vg_producto,'La fecha de término no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD vm_fecha_ter
			END IF
		ELSE
			LET vm_fecha_ter = fecha_ter
			DISPLAY BY NAME vm_fecha_ter
		END IF
	AFTER FIELD v30_vendedor 
		IF rm_veh.v30_vendedor IS NOT NULL THEN
			CALL fl_lee_vendedor_veh(vg_codcia, rm_veh.v30_vendedor)
				RETURNING r_ven.* 
			IF r_ven.v01_compania IS NULL  THEN
				CALL fgl_winmessage(vg_producto,'Vendedor no existe.','exclamation')
				NEXT FIELD v30_vendedor
			END IF
			DISPLAY r_ven.v01_nombres TO tit_vendedor
		ELSE
			CLEAR tit_vendedor
		END IF
	AFTER FIELD v22_bodega 
		IF rm_mod.v22_bodega IS NOT NULL THEN
			CALL fl_lee_bodega_veh(vg_codcia, rm_mod.v22_bodega)
				RETURNING r_bod.* 
			IF r_bod.v02_compania IS NULL  THEN
				CALL fgl_winmessage(vg_producto,'Bodega no existe.','exclamation')
				NEXT FIELD v22_bodega
			END IF
			DISPLAY r_bod.v02_nombre TO tit_bodega
		ELSE
			CLEAR tit_bodega
		END IF
	AFTER INPUT
		IF vm_fecha_ter < vm_fecha_ini THEN
			CALL fgl_winmessage(vg_producto,'La fecha de término debe ser mayor a la fecha de inicio.','exclamation')
			NEXT FIELD vm_fecha_ter
		END IF
		IF rm_veh.v30_vendedor IS NOT NULL THEN
			LET expr_sql = 'AND v30_vendedor = ',rm_veh.v30_vendedor
		END IF
		IF rm_mod.v22_modelo IS NOT NULL THEN
			IF expr_sql IS NULL THEN
				LET expr_sql = 'AND v22_modelo = "',
						rm_mod.v22_modelo, '"'
			ELSE
				LET expr_sql = expr_sql, ' AND v22_modelo = "',
						rm_mod.v22_modelo, '"'
			END IF
		END IF
		IF rm_mod.v22_bodega IS NOT NULL THEN
			IF expr_sql IS NULL THEN
				LET expr_sql = 'AND v22_bodega = "',
						rm_mod.v22_bodega, '"'
			ELSE
				LET expr_sql = expr_sql, ' AND v22_bodega = "',
						rm_mod.v22_bodega, '"'
			END IF
		END IF
END INPUT
CONSTRUCT BY NAME expr_sql2 ON v30_nomcli
	ON KEY(INTERRUPT)
		RETURN
END CONSTRUCT
LET expr_gen = 'SELECT v30_bodega_ori, DATE(v30_fecing) fecha, v01_iniciales, ',
	'v30_nomcli, v22_modelo, ',
	'(v31_precio - v31_val_descto) * (1 + v30_porc_impto / 100) valor, ',
	'v30_cod_tran, v30_num_tran, v30_tipo_dev, v30_num_dev ',
	'FROM veht030, veht031, veht022, veht001 ',
		'WHERE v30_compania     = ',vg_codcia,
		'  AND v30_localidad    = ',vg_codloc,
		'  AND v30_cod_tran     = "FA" ',
		'  AND v30_moneda       = "',rm_veh.v30_moneda, '"',
		'  AND DATE(v30_fecing) ',
		'  BETWEEN "', vm_fecha_ini, '" AND "', vm_fecha_ter, '"',
		' ',expr_sql CLIPPED,
		'  AND ',expr_sql2 CLIPPED,
		'  AND v30_compania     = v31_compania ',
		'  AND v30_localidad    = v31_localidad ',
		'  AND v30_cod_tran     = v31_cod_tran ',
		'  AND v30_num_tran     = v31_num_tran ',
		'  AND v30_compania     = v22_compania ', 
		'  AND v30_localidad    = v22_localidad ',
		'  AND v30_cod_tran     = v22_cod_tran ',
		'  AND v30_num_tran     = v22_num_tran ',
		'  AND v30_compania     = v01_compania ',
		'  AND v30_vendedor     = v01_vendedor ',
	'INTO TEMP tmp_detalle_veh'
PREPARE q_gen FROM expr_gen
EXECUTE q_gen
SELECT COUNT(*) INTO vm_num_det FROM tmp_detalle_veh
IF vm_num_det = 0 THEN
	DROP TABLE tmp_detalle_veh
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET rm_orden[1]  = 'ASC'
LET vm_columna_1 = 2
LET vm_columna_2 = 3
LET col          = 2
WHILE TRUE
	LET query = 'SELECT * FROM tmp_detalle_veh ',
			" ORDER BY ", vm_columna_1, ' ', rm_orden[vm_columna_1],
			        ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE deto FROM query
	DECLARE q_deto CURSOR FOR deto
	LET i = 1
	FOREACH q_deto INTO rm_det[i].*,rm_veh.v30_cod_tran,rm_veh.v30_num_tran,
				rm_veh.v30_tipo_dev,rm_veh.v30_num_dev
		LET rm_tran[i].v30_cod_tran = rm_veh.v30_cod_tran
		LET rm_tran[i].v30_num_tran = rm_veh.v30_num_tran
		IF rm_veh.v30_num_dev IS NOT NULL THEN
			CALL fl_lee_cabecera_transaccion_veh(vg_codcia,
					vg_codloc, rm_veh.v30_cod_tran,
					rm_veh.v30_num_tran)
				RETURNING r_veh.*
			IF r_veh.v30_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe la transacción procesada.','stop')
				EXIT PROGRAM
			END IF
			IF DATE(r_veh.v30_fecing) >= vm_fecha_ini
			AND DATE(r_veh.v30_fecing) <= vm_fecha_ter THEN
				LET rm_det[i].tit_valor_vta = 0
			END IF
		END IF
		LET i = i + 1
		IF i > vm_max_det THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	CALL sacar_total()
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rm_det TO rm_det.*
		BEFORE DISPLAY
			CALL dialog.keysetlabel('ACCEPT','')
		BEFORE ROW
			LET j = arr_curr()
			LET l = scr_line()
			CALL muestra_contadores_det(j)
		AFTER DISPLAY 
			CONTINUE DISPLAY
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
		ON KEY(F5)
			CALL ver_factura(j)
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
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
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
END WHILE
DROP TABLE tmp_detalle_veh

END FUNCTION



FUNCTION sacar_total()
DEFINE i		SMALLINT

LET vm_total = 0
FOR i = 1 TO vm_num_det
	LET vm_total = vm_total + rm_det[i].tit_valor_vta
END FOR
DISPLAY vm_total TO tit_total

END FUNCTION



FUNCTION borrar_cabecera()

CLEAR v30_moneda, tit_mon_bas, vm_fecha_ini, vm_fecha_ter, v30_vendedor,
	tit_vendedor, v22_modelo, tit_modelo, v22_bodega, tit_bodega
INITIALIZE rm_veh.*, rm_veh2.*, rm_mod.*, vm_fecha_ini, vm_fecha_ter TO NULL

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i  		SMALLINT

CALL muestra_contadores_det(0)
LET vm_scr_lin = fgl_scr_size('rm_det')
FOR i = 1 TO vm_scr_lin
        INITIALIZE rm_det[i].*, rm_tran[i].* TO NULL
        CLEAR rm_det[i].*
END FOR
CLEAR tit_total

END FUNCTION



FUNCTION muestra_contadores_det(cor)
DEFINE cor	           SMALLINT

DISPLAY "" AT 21, 4
DISPLAY cor, " de ", vm_num_det AT 21, 8

END FUNCTION



FUNCTION ver_factura(i)
DEFINE i		SMALLINT

LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS',
	vg_separador, 'fuentes', vg_separador, '; fglrun vehp304 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ',
	rm_tran[i].v30_cod_tran, ' ', rm_tran[i].v30_num_tran
RUN vm_nuevoprog

END FUNCTION



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEn
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
