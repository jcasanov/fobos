--------------------------------------------------------------------------------
-- Titulo           : talp300.4gl - Consulta de detalle de ordenes de trabajo
-- Elaboracion      : 07-dic-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun talp300 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_nuevoprog     CHAR(400)
DEFINE rm_ord		RECORD LIKE talt023.*
DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE vm_scr_lin       SMALLINT
DEFINE vm_total         DECIMAL(12,2)
DEFINE rm_orden 	ARRAY[20] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE rm_det		ARRAY [20000] OF RECORD
				tit_fecha	DATE,
				tit_tipo	LIKE talt023.t23_tipo_ot,
				t23_orden	LIKE talt023.t23_orden,
				t23_nom_cliente	LIKE talt023.t23_nom_cliente,
				tit_modelo_det	LIKE talt023.t23_modelo,
				t23_tot_neto	LIKE talt023.t23_tot_neto,
				estado		LIKE talt023.t23_estado
			END RECORD
DEFINE vm_orden		ARRAY [20000] OF RECORD
				t23_num_factura	LIKE talt023.t23_num_factura,
				t28_ot_nue	LIKE talt028.t28_ot_nue,
				t28_num_dev	LIKE talt028.t28_num_dev,
				t23_descripcion	LIKE talt023.t23_descripcion
			END RECORD

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp300.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN   -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'talp300'
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
LET vm_max_det = 20000
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 22
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_mas AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
	OPEN FORM f_tal FROM "../forms/talf300_1"
ELSE
	OPEN FORM f_tal FROM "../forms/talf300_1c"
END IF
DISPLAY FORM f_tal
LET vm_scr_lin = 0
CALL muestra_contadores_det(0, 0)
CALL borrar_cabecera()
CALL borrar_detalle()
CALL mostrar_cabecera_forma()
CALL control_consulta()

END FUNCTION



FUNCTION control_consulta()
DEFINE i, j, l, col	SMALLINT
DEFINE factor		SMALLINT
DEFINE col_aux		SMALLINT
DEFINE query		CHAR(3000)
DEFINE expr_sql         CHAR(800)
DEFINE feccie		DATE
DEFINE fecfac		DATE
DEFINE fecdev		DATE
DEFINE feceli		DATE
DEFINE fecing		DATE
DEFINE cuantos		INTEGER
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE num_comp		LIKE ctbt012.b12_num_comp
DEFINE estado		LIKE talt023.t23_estado

LET rm_ord.t23_estado = 'A'
LET rm_ord.t23_moneda = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_ord.t23_moneda) RETURNING r_mon.*
IF r_mon.g13_moneda IS NULL THEN
	CALL fl_mostrar_mensaje('Moneda no existe moneda base.','stop')
        EXIT PROGRAM
END IF
CALL muestra_estado()
DISPLAY r_mon.g13_nombre TO tit_moneda
WHILE TRUE
	LET vm_num_det = 0
	CALL borrar_detalle()
	CALL muestra_contadores_det(0, vm_num_det)
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL armar_expresion_sql() RETURNING expr_sql
	FOR i = 1 TO 20
		LET rm_orden[i] = '' 
	END FOR
	LET rm_orden[1]  = 'ASC'
	LET vm_columna_1 = 1
	LET vm_columna_2 = 2
	LET col          = 1
	LET col_aux      = 5
	WHILE TRUE
		IF rm_ord.t23_estado <> 'D' AND rm_ord.t23_estado <> 'T' THEN
			LET query = query_ot_general() CLIPPED, ' ',
					expr_sql CLIPPED
		END IF
		IF rm_ord.t23_estado = 'D' THEN
			LET query = query_ot_devuelta() CLIPPED, ' ',
					expr_sql CLIPPED
		END IF
		IF rm_ord.t23_estado = 'T' THEN
			LET query = query_ot_general() CLIPPED, ' ',
					expr_sql CLIPPED,
					' UNION ',
					query_ot_devuelta() CLIPPED, ' ',
						expr_sql CLIPPED
		END IF
		LET query = query CLIPPED,
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
		PREPARE deto FROM query
		DECLARE q_deto CURSOR FOR deto
		LET vm_num_det = 1
		FOREACH q_deto INTO rm_det[vm_num_det].tit_tipo,
				rm_det[vm_num_det].t23_orden,
				rm_det[vm_num_det].t23_nom_cliente,
				rm_det[vm_num_det].tit_modelo_det,
                        	rm_det[vm_num_det].t23_tot_neto,
                        	rm_det[vm_num_det].estado, feccie, fecfac,
				fecdev, feceli, fecing, vm_orden[vm_num_det].*
			IF rm_ord.t23_estado = 'A' OR rm_ord.t23_estado = 'T'
			THEN
				LET rm_det[vm_num_det].tit_fecha = fecing
				LET col_aux = 11
			END IF
			IF rm_ord.t23_estado = 'E' THEN
				LET rm_det[vm_num_det].tit_fecha = feceli
				LET col_aux = 10
			END IF
			IF rm_ord.t23_estado = 'C' THEN
				LET rm_det[vm_num_det].tit_fecha = feccie
				LET col_aux = 7
			END IF
			IF rm_ord.t23_estado = 'F' THEN
				LET rm_det[vm_num_det].tit_fecha = fecfac
				LET col_aux = 8
			END IF
			IF rm_ord.t23_estado = 'D' THEN
				LET rm_det[vm_num_det].tit_fecha = fecdev
				LET col_aux = 10
			END IF
			LET vm_num_det = vm_num_det + 1
			IF vm_num_det > vm_max_det THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET vm_num_det = vm_num_det - 1
		IF vm_num_det = 0 THEN
			CALL fl_mensaje_consulta_sin_registros()
			EXIT WHILE
		END IF
		CALL sacar_total()
		CALL set_count(vm_num_det)
		LET int_flag = 0
		DISPLAY ARRAY rm_det TO rm_det.*
			ON KEY(INTERRUPT)
				LET int_flag = 1
				EXIT DISPLAY
			ON KEY(F5)
				LET i = arr_curr()
				IF rm_det[i].estado <> 'F' AND
				   rm_det[i].estado <> 'D'
				THEN
					--#CONTINUE DISPLAY
				END IF
				CALL fl_mostrar_contable_tal(vg_codcia,
							vg_codloc,
							rm_det[i].t23_orden)
					RETURNING tipo_comp, num_comp
				IF tipo_comp IS NOT NULL AND cuantos = 1 THEN
					CALL fl_ver_contabilizacion(tipo_comp, 
							     num_comp)
				END IF
				LET int_flag = 0
			ON KEY(F6)
				LET i = arr_curr()
				IF rm_det[i].estado <> 'F' AND
				   rm_det[i].estado <> 'D'
				THEN
					--#CONTINUE DISPLAY
				END IF
				CALL fl_ver_factura_dev_tal(
						vm_orden[i].t23_num_factura,
						rm_det[i].estado)
				LET int_flag = 0
			ON KEY(F7)
				LET i = arr_curr()
				CALL fl_ver_orden_trabajo(rm_det[i].t23_orden,
							'O')
				LET int_flag = 0
			ON KEY(F8)
				LET i = arr_curr()
				LET factor = 1
				IF rm_det[i].estado <> 'F' AND
				   rm_det[i].estado <> 'D'
				THEN
					LET factor = -1
				END IF
				CALL fl_muestra_mano_obra_orden_trabajo(
							vg_codcia, vg_codloc,
							rm_det[i].t23_orden,
							factor)
				LET int_flag = 0
			ON KEY(F9)
				LET i = arr_curr()
				CALL fl_muestra_det_ord_compra_orden_trabajo(
							vg_codcia, vg_codloc,
							rm_det[i].t23_orden,
							rm_det[i].estado)
				LET int_flag = 0
			ON KEY(F10)
				LET i = arr_curr()
				CALL fl_control_prof_trans(vg_codcia, vg_codloc,
							rm_det[i].t23_orden)
				LET int_flag = 0
			ON KEY(F11)
				LET i = arr_curr()
				LET estado = rm_det[i].estado
				IF rm_det[i].estado = 'N' THEN
					LET estado = "D"
				END IF
				CALL fl_muestra_repuestos_orden_trabajo(
							vg_codcia, vg_codloc,
							rm_det[i].t23_orden,
							estado)
				LET int_flag = 0
			ON KEY(F15)
				LET col = col_aux
				EXIT DISPLAY
			ON KEY(F16)
				LET col = 1
				EXIT DISPLAY
			ON KEY(F17)
				LET col = 2
				EXIT DISPLAY
			ON KEY(F18)
				LET col = 3
				EXIT DISPLAY
			ON KEY(F19)
				LET col = 4
				EXIT DISPLAY
			ON KEY(F20)
				LET col = 5
				EXIT DISPLAY
			ON KEY(F21)
				LET col = 6
				EXIT DISPLAY
			--#BEFORE DISPLAY
				--#CALL dialog.keysetlabel('ACCEPT','')
				--#CALL dialog.keysetlabel('CONTROL-B','')
				--#CALL dialog.keysetlabel("F1","")
				--#CALL dialog.keysetlabel("CONTROL-W","")
			--#BEFORE ROW
				--#LET l = scr_line()
				--#LET j = arr_curr()
				--#CALL muestra_contadores_det(j, vm_num_det)
				--#SELECT COUNT(*) INTO cuantos FROM talt050 
				--#	WHERE t50_compania  = vg_codcia	
				--#	  AND t50_localidad = vg_codloc
				--#	  AND t50_orden     =rm_det[j].t23_orden
				--#IF cuantos > 0 THEN
					--#CALL dialog.keysetlabel('F5', 
					--#	'Contabilización')
					--#CALL dialog.keysetlabel('F6',
					--#	'Comprobante')
				--#ELSE
					--#CALL dialog.keysetlabel('F5', '')
					--#CALL dialog.keysetlabel('F6', '')
				--#END IF
				--#DISPLAY BY NAME vm_orden[j].t23_descripcion
			--#AFTER DISPLAY 
				--#CONTINUE DISPLAY
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
END WHILE

END FUNCTION



FUNCTION query_ot_general()
DEFINE query		CHAR(1500)

LET query = 'SELECT t23_tipo_ot, t23_orden, t23_nom_cliente, t23_modelo, ',
			't23_tot_neto, t23_estado, DATE(t23_fec_cierre), ',
			'DATE(t23_fec_factura), DATE(t23_fecfin), ',
			'DATE(t23_fec_elimin), DATE(t23_fecing), ',
			't23_num_factura, 0, 0, t23_descripcion ',
			'FROM talt023 ',
			'WHERE t23_compania    = ', vg_codcia,
			'  AND t23_localidad   = ', vg_codloc
RETURN query CLIPPED

END FUNCTION



FUNCTION query_ot_devuelta()
DEFINE query		CHAR(1500)

LET query = 'SELECT t23_tipo_ot, t23_orden, t23_nom_cliente, t23_modelo, ',
			't23_tot_neto, t23_estado, t23_fecini, ',
			'DATE(t23_fec_cierre), DATE(t23_fec_factura), ',
			'DATE(t28_fec_anula), DATE(t23_fecing), ',
			't23_num_factura, t28_ot_nue, t28_num_dev, ',
			't23_descripcion ',
			'FROM talt023, talt028 ',
			'WHERE t23_compania    = ', vg_codcia,
			'  AND t23_localidad   = ', vg_codloc,
			'  AND t23_compania    = t28_compania ',
			'  AND t23_localidad   = t28_localidad ',
			'  AND t23_num_factura = t28_factura '
RETURN query CLIPPED

END FUNCTION



FUNCTION lee_parametros()
DEFINE difmes		SMALLINT
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_cli		RECORD LIKE cxct001.*
DEFINE r_mod		RECORD LIKE talt004.*
DEFINE r_tip		RECORD LIKE talt005.*
DEFINE mone_aux         LIKE gent013.g13_moneda
DEFINE nomm_aux         LIKE gent013.g13_nombre
DEFINE deci_aux         LIKE gent013.g13_decimales
DEFINE codcli		LIKE talt023.t23_cod_cliente
DEFINE nomcli		LIKE talt023.t23_nom_cliente
DEFINE codt_aux		LIKE talt005.t05_tipord
DEFINE nomt_aux		LIKE talt005.t05_nombre
DEFINE codm_aux		LIKE talt004.t04_modelo
DEFINE noml_aux		LIKE talt004.t04_linea
DEFINE codb_aux		LIKE veht002.v02_bodega
DEFINE nomb_aux		LIKE veht002.v02_nombre
DEFINE estado		LIKE talt023.t23_estado

INITIALIZE mone_aux, codcli, codt_aux, codm_aux TO NULL
LET int_flag = 0
INPUT BY NAME rm_ord.t23_estado, rm_ord.t23_moneda, rm_ord.t23_fecini,
	rm_ord.t23_fecfin, rm_ord.t23_cod_cliente, rm_ord.t23_modelo,
	rm_ord.t23_tipo_ot
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(t23_moneda) THEN
               		CALL fl_ayuda_monedas()
                       		RETURNING mone_aux, nomm_aux, deci_aux
       		      	LET int_flag = 0
                      	IF mone_aux IS NOT NULL THEN
                              	LET rm_ord.t23_moneda = mone_aux
                               	DISPLAY BY NAME rm_ord.t23_moneda
                               	DISPLAY nomm_aux TO tit_moneda
                       	END IF
                END IF
		IF INFIELD(t23_cod_cliente) THEN
                     	CALL fl_ayuda_cliente_general()
				RETURNING codcli, nomcli
                       	IF codcli IS NOT NULL THEN
                             	LET rm_ord.t23_cod_cliente = codcli
                               	DISPLAY BY NAME rm_ord.t23_cod_cliente
                               	DISPLAY nomcli TO tit_nombre_cli
                        END IF
                END IF
		IF INFIELD(t23_modelo) THEN
			CALL fl_ayuda_tipos_vehiculos(vg_codcia)
				RETURNING codm_aux, noml_aux
			LET int_flag = 0
			IF codm_aux IS NOT NULL THEN
                             	LET rm_ord.t23_modelo = codm_aux
				DISPLAY BY NAME rm_ord.t23_modelo
				CALL fl_lee_tipo_vehiculo(vg_codcia, codm_aux)
					RETURNING r_mod.*
				DISPLAY r_mod.t04_modelo TO tit_modelo_cab
			END IF
		END IF
		IF INFIELD(t23_tipo_ot) THEN
                	CALL fl_ayuda_tipo_orden_trabajo(vg_codcia)
				RETURNING codt_aux, nomt_aux
                       	IF codt_aux IS NOT NULL THEN
                            	LET rm_ord.t23_tipo_ot =codt_aux
                              	DISPLAY BY NAME rm_ord.t23_tipo_ot
                               	DISPLAY nomt_aux TO tit_tipo_ot
                       	END IF
                END IF
	BEFORE INPUT
		LET estado = rm_ord.t23_estado
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD t23_fecfin
		IF rm_ord.t23_fecini IS NOT NULL AND rm_ord.t23_fecfin IS NULL
		THEN
			LET rm_ord.t23_fecfin = TODAY
			DISPLAY BY NAME rm_ord.t23_fecfin
		END IF
	AFTER FIELD t23_estado
		IF rm_ord.t23_estado IS NULL THEN
			LET rm_ord.t23_estado = estado
		END IF
		CALL muestra_estado()
	AFTER FIELD t23_moneda
               	IF rm_ord.t23_moneda IS NOT NULL THEN
                       	CALL fl_lee_moneda(rm_ord.t23_moneda)
                               	RETURNING r_mon.*
                       	IF r_mon.g13_moneda IS NULL THEN
                               	--CALL fgl_winmessage(vg_producto,'Moneda no existe.','exclamation')
				CALL fl_mostrar_mensaje('Moneda no existe.','exclamation')
                               	NEXT FIELD t23_moneda
                       	END IF
               	ELSE
                       	LET rm_ord.t23_moneda = rg_gen.g00_moneda_base
                       	CALL fl_lee_moneda(rm_ord.t23_moneda)
				RETURNING r_mon.*
                       	DISPLAY BY NAME rm_ord.t23_moneda
               	END IF
               	DISPLAY r_mon.g13_nombre TO tit_moneda
	AFTER FIELD t23_cod_cliente
               	IF rm_ord.t23_cod_cliente IS NOT NULL THEN
                       	CALL fl_lee_cliente_general(rm_ord.t23_cod_cliente)
                     		RETURNING r_cli.*
                        IF r_cli.z01_codcli IS NULL THEN
                               	--CALL fgl_winmessage(vg_producto,'Cliente no existe.','exclamation')
				CALL fl_mostrar_mensaje('Cliente no existe.','exclamation')
                               	NEXT FIELD t23_cod_cliente
                        END IF
			DISPLAY r_cli.z01_nomcli TO tit_nombre_cli
		ELSE
			CLEAR tit_nombre_cli
                END IF
	AFTER FIELD t23_modelo
               	IF rm_ord.t23_modelo IS NOT NULL THEN
                       	CALL fl_lee_tipo_vehiculo(vg_codcia, rm_ord.t23_modelo)
                            	RETURNING r_mod.*
                        IF r_mod.t04_modelo IS NULL THEN
                               	--CALL fgl_winmessage(vg_producto,'Modelo no existe.','exclamation')
				CALL fl_mostrar_mensaje('Modelo no existe.','exclamation')
                               	NEXT FIELD t23_modelo
                       	END IF
			DISPLAY r_mod.t04_modelo TO tit_modelo_cab
		ELSE
			CLEAR tit_modelo_cab
                END IF
	AFTER FIELD t23_tipo_ot
               	IF rm_ord.t23_tipo_ot IS NOT NULL THEN
                       	CALL fl_lee_tipo_orden_taller(vg_codcia,
							rm_ord.t23_tipo_ot)
                               	RETURNING r_tip.*
                        IF r_tip.t05_compania IS NULL THEN
                               	--CALL fgl_winmessage(vg_producto,'Tipo de orden no existe.','exclamation')
				CALL fl_mostrar_mensaje('Tipo de orden no existe.','exclamation')
                               	NEXT FIELD t23_tipo_ot
                        END IF
			DISPLAY r_tip.t05_nombre TO tit_tipo_ot
		ELSE
			CLEAR tit_tipo_ot
                END IF
	AFTER INPUT
		IF rm_ord.t23_estado = 'F' THEN
			IF rm_ord.t23_fecini IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Debe ingresar fecha inicial para ordenes facturadas.','exclamation')
				CALL fl_mostrar_mensaje('Debe ingresar fecha inicial para ordenes facturadas.','exclamation')
				NEXT FIELD t23_fecini
			END IF
			IF rm_ord.t23_fecfin IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Debe ingresar fecha final para ordenes facturadas.','exclamation')
				CALL fl_mostrar_mensaje('Debe ingresar fecha final para ordenes facturadas.','exclamation')
				NEXT FIELD t23_fecfin
			END IF
			IF rm_ord.t23_fecfin > TODAY THEN
				--CALL fgl_winmessage(vg_producto,'Debe ingresar fecha final menor a la de hoy.','exclamation')
				CALL fl_mostrar_mensaje('Debe ingresar fecha final menor a la de hoy.','exclamation')
				NEXT FIELD t23_fecfin
			END IF
			IF rm_ord.t23_fecini > rm_ord.t23_fecfin THEN
				--CALL fgl_winmessage(vg_producto,'Fecha inicial debe ser menor a fecha final.','exclamation')
				CALL fl_mostrar_mensaje('Fecha inicial debe ser menor a fecha final.','exclamation')
				NEXT FIELD t23_fecini
			END IF
		END IF
		IF rm_ord.t23_fecini IS NULL THEN
			LET rm_ord.t23_fecfin = NULL
			DISPLAY BY NAME rm_ord.t23_fecfin
		END IF
		IF rm_ord.t23_fecfin IS NULL THEN
			LET rm_ord.t23_fecini = NULL
			DISPLAY BY NAME rm_ord.t23_fecini
		END IF
END INPUT

END FUNCTION



FUNCTION armar_expresion_sql()
DEFINE expr_sql         CHAR(800)

LET expr_sql = NULL
IF rm_ord.t23_estado <> 'T' THEN
	LET expr_sql = ' AND t23_estado = "', rm_ord.t23_estado, '"'
END IF
LET expr_sql = expr_sql CLIPPED,
		'  AND t23_moneda = "', rm_ord.t23_moneda, '"'
IF rm_ord.t23_estado = 'A' THEN
	IF rm_ord.t23_fecini IS NOT NULL THEN
		LET expr_sql = expr_sql CLIPPED, '  AND t23_fecini BETWEEN "',
			rm_ord.t23_fecini, '" AND "',
			rm_ord.t23_fecfin, '"'
	END IF
END IF
IF rm_ord.t23_estado = 'E' THEN
	IF rm_ord.t23_fecini IS NOT NULL THEN
		LET expr_sql = expr_sql CLIPPED,
			'   AND DATE(t23_fec_elimin) ',
					'BETWEEN "', rm_ord.t23_fecini,
					  '" AND "', rm_ord.t23_fecfin, '"'
	END IF
END IF
IF rm_ord.t23_estado = 'C' THEN
	IF rm_ord.t23_fecini IS NOT NULL THEN
		LET expr_sql = expr_sql CLIPPED, '  AND DATE(t23_fec_cierre) ',
			'BETWEEN "', rm_ord.t23_fecini, '" AND "',
			rm_ord.t23_fecfin, '"'
	END IF
END IF
IF rm_ord.t23_estado = 'F' THEN
	LET expr_sql = expr_sql CLIPPED, ' AND DATE(t23_fec_factura) BETWEEN "',
		rm_ord.t23_fecini, '" AND "', rm_ord.t23_fecfin, '"'
END IF
IF rm_ord.t23_estado = 'D' THEN
	IF rm_ord.t23_fecini IS NOT NULL THEN
		LET expr_sql = expr_sql CLIPPED, '  AND DATE(t28_fec_anula) ',
			'BETWEEN "', rm_ord.t23_fecini, '" AND "',
			rm_ord.t23_fecfin, '"'
	END IF
END IF
IF rm_ord.t23_cod_cliente IS NOT NULL THEN
	LET expr_sql = expr_sql CLIPPED, '  AND t23_cod_cliente = "',
			rm_ord.t23_cod_cliente, '"'
END IF
IF rm_ord.t23_modelo IS NOT NULL THEN
	LET expr_sql = expr_sql CLIPPED, '  AND t23_modelo = "',
			rm_ord.t23_modelo, '"'
END IF
IF rm_ord.t23_tipo_ot IS NOT NULL THEN
	LET expr_sql = expr_sql CLIPPED, '  AND t23_tipo_ot = "',
			rm_ord.t23_tipo_ot, '"'
END IF
RETURN expr_sql

END FUNCTION



FUNCTION sacar_total()
DEFINE i		SMALLINT

LET vm_total = 0
FOR i = 1 TO vm_num_det
	LET vm_total = vm_total + rm_det[i].t23_tot_neto
END FOR
DISPLAY vm_total TO tit_total

END FUNCTION



FUNCTION borrar_cabecera()

CLEAR t23_estado, tit_estado, t23_moneda, tit_moneda, t23_fecini, t23_fecfin,
	t23_cod_cliente, tit_nombre_cli, t23_modelo, tit_modelo_cab,
	t23_tipo_ot, tit_tipo_ot, t23_descripcion
INITIALIZE rm_ord.* TO NULL

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i  		SMALLINT

CALL muestra_contadores_det(0, 0)
--#LET vm_scr_lin = fgl_scr_size('rm_det')
IF vg_gui = 0 THEN
	LET vm_scr_lin = 10
END IF
FOR i = 1 TO vm_scr_lin
        INITIALIZE rm_det[i].*, vm_orden[i].* TO NULL
        CLEAR rm_det[i].*
END FOR
CLEAR tit_total, t23_descripcion

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION


 
FUNCTION muestra_estado()

DISPLAY BY NAME rm_ord.t23_estado
IF rm_ord.t23_estado = 'A' THEN
	DISPLAY 'ACTIVAS' TO tit_estado
END IF
IF rm_ord.t23_estado = 'C' THEN
	DISPLAY 'CERRADAS' TO tit_estado
END IF
IF rm_ord.t23_estado = 'F' THEN
	DISPLAY 'FACTURADAS' TO tit_estado
END IF
IF rm_ord.t23_estado = 'E' THEN
	DISPLAY 'ELIMINADAS' TO tit_estado
END IF
IF rm_ord.t23_estado = 'D' THEN
	DISPLAY 'DEVUELTAS' TO tit_estado
END IF
IF rm_ord.t23_estado = 'T' THEN
	DISPLAY 'T O D A S' TO tit_estado
END IF

END FUNCTION



FUNCTION mostrar_cabecera_forma()

--#DISPLAY 'Fecha'      TO tit_col1
--#DISPLAY 'T'          TO tit_col2
--#DISPLAY 'Orden'      TO tit_col3
--#DISPLAY 'Cliente'    TO tit_col4
--#DISPLAY 'Modelo'     TO tit_col5
--#DISPLAY 'Valor Neto' TO tit_col6
--#DISPLAY 'E'          TO tit_col7

END FUNCTION



FUNCTION llamar_visor_teclas()
DEFINE a		CHAR(1)

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
DISPLAY '<F5>      Ver Orden'                AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Orden Creada'             AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F7>      Devolución'               AT a,2
DISPLAY  'F7' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
