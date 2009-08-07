------------------------------------------------------------------------------
-- Titulo           : talp300.4gl - Consulta de detalle de ordenes de trabajo
-- Elaboracion      : 07-dic-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun talp300 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_nuevoprog     VARCHAR(400)
DEFINE rm_ord		RECORD LIKE talt023.*
DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE vm_scr_lin       SMALLINT
DEFINE vm_total         DECIMAL(12,2)
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE rm_det		ARRAY [1000] OF RECORD
				tit_fecha	DATE,
				tit_tipo	LIKE talt023.t23_tipo_ot,
				t23_nom_cliente	LIKE talt023.t23_nom_cliente,
				tit_modelo_det	LIKE talt023.t23_modelo,
				t23_tot_neto	LIKE talt023.t23_tot_neto
			END RECORD
DEFINE vm_orden		ARRAY [1000] OF RECORD
				t23_orden	LIKE talt023.t23_orden,
				t28_ot_nue	LIKE talt028.t28_ot_nue,
				t28_num_dev	LIKE talt028.t28_num_dev
			END RECORD

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp300.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN   -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'talp300'
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
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_tal FROM "../forms/talf300_1"
DISPLAY FORM f_tal
LET vm_scr_lin = 0
CALL muestra_contadores_det(0)
CALL borrar_cabecera()
CALL borrar_detalle()
CALL mostrar_cabecera_forma()
CALL control_consulta()

END FUNCTION



FUNCTION control_consulta()
DEFINE i,j,l,col	SMALLINT
DEFINE col_aux		SMALLINT
DEFINE query		VARCHAR(1000)
DEFINE expr_sql         VARCHAR(600)
DEFINE fecini		DATE
DEFINE feccie		DATE
DEFINE fecfac		DATE
DEFINE fecdev		DATE
DEFINE r_mon		RECORD LIKE gent013.*

LET rm_ord.t23_estado = 'A'
LET rm_ord.t23_moneda = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_ord.t23_moneda) RETURNING r_mon.*
IF r_mon.g13_moneda IS NULL THEN
       	CALL fgl_winmessage(vg_producto,'Moneda no existe moneda base.','stop')
        EXIT PROGRAM
END IF
CALL muestra_estado()
DISPLAY r_mon.g13_nombre TO tit_moneda
WHILE TRUE
	LET vm_num_det = 0
	CALL borrar_detalle()
	CALL muestra_contadores_det(0)
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL armar_expresion_sql() RETURNING expr_sql
	FOR i = 1 TO 10
		LET rm_orden[i] = '' 
	END FOR
	LET rm_orden[1]  = 'ASC'
	LET vm_columna_1 = 1
	LET vm_columna_2 = 2
	LET col          = 1
	LET col_aux      = 5
	WHILE TRUE
		IF rm_ord.t23_estado <> 'D' THEN
			LET query = 'SELECT t23_tipo_ot, t23_nom_cliente, ',
				't23_modelo, t23_tot_neto, t23_fecini, ',
				'DATE(t23_fec_cierre), DATE(t23_fec_factura), ',
				'DATE(t23_fecfin), t23_orden, 0, 0 ',
				'FROM talt023 ',
				'WHERE t23_compania    = ', vg_codcia,
				'  AND t23_localidad   = ', vg_codloc,
				expr_sql CLIPPED, 
				" ORDER BY ", vm_columna_1, ' ',
					rm_orden[vm_columna_1],
			        	', ', vm_columna_2, ' ',
					rm_orden[vm_columna_2]
		ELSE
			LET query = 'SELECT t23_tipo_ot, t23_nom_cliente, ',
				't23_modelo, t23_tot_neto, t23_fecini, ',
				'DATE(t23_fec_cierre), DATE(t23_fec_factura), ',
				'DATE(t28_fec_anula), t23_orden, t28_ot_nue, ',
				't28_num_dev ',
				'FROM talt023, talt028 ',
				'WHERE t23_compania    = ', vg_codcia,
				'  AND t23_localidad   = ', vg_codloc,
				'  AND t23_compania    = t28_compania ',
				'  AND t23_localidad   = t28_localidad ',
				'  AND t23_num_factura = t28_factura ',
				expr_sql CLIPPED, 
				" ORDER BY ", vm_columna_1, ' ',
					rm_orden[vm_columna_1],
			        	', ', vm_columna_2, ' ',
					rm_orden[vm_columna_2]
		END IF
		PREPARE deto FROM query
		DECLARE q_deto CURSOR FOR deto
		LET vm_num_det = 1
		FOREACH q_deto INTO rm_det[vm_num_det].tit_tipo,
				rm_det[vm_num_det].t23_nom_cliente,
				rm_det[vm_num_det].tit_modelo_det,
                        	rm_det[vm_num_det].t23_tot_neto,
				fecini, feccie, fecfac, fecdev,
				vm_orden[vm_num_det].*
			IF rm_ord.t23_estado = 'A'
			OR rm_ord.t23_estado = 'E' THEN
				LET rm_det[vm_num_det].tit_fecha = fecini
				LET col_aux = 5
			END IF
			IF rm_ord.t23_estado = 'C' THEN
				LET rm_det[vm_num_det].tit_fecha = feccie
				LET col_aux = 6
			END IF
			IF rm_ord.t23_estado = 'F' THEN
				LET rm_det[vm_num_det].tit_fecha = fecfac
				LET col_aux = 7
			END IF
			IF rm_ord.t23_estado = 'D' THEN
				LET rm_det[vm_num_det].tit_fecha = fecdev
				LET col_aux = 8
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
			BEFORE DISPLAY
				CALL dialog.keysetlabel('ACCEPT','')
				CALL dialog.keysetlabel('CONTROL-B','')
			BEFORE ROW
				LET j = arr_curr()
				LET l = scr_line()
				CALL muestra_contadores_det(j)
				IF rm_ord.t23_estado <> 'D' THEN
					CALL dialog.keysetlabel('F6','')
					CALL dialog.keysetlabel('F7','')
				ELSE
					CALL dialog.keysetlabel('F6','Orden Creada')
					CALL dialog.keysetlabel('F7','Devolución')
				END IF
			AFTER DISPLAY 
				CONTINUE DISPLAY
			ON KEY(INTERRUPT)
				LET int_flag = 1
				EXIT DISPLAY
			ON KEY(F5)
				CALL ver_orden(j)
				LET int_flag = 0
			ON KEY(F6)
				IF rm_ord.t23_estado = 'D' THEN
					CALL ver_orden_nueva(j)
					LET int_flag = 0
				END IF
			ON KEY(F7)
				IF rm_ord.t23_estado = 'D' THEN
					CALL ver_devolucion(j)
					LET int_flag = 0
				END IF
			ON KEY(CONTROL-B)
				CALL fl_recalcula_valores_ot(vg_codcia, vg_codloc, vm_orden[j].t23_orden)
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
                               	CALL fgl_winmessage(vg_producto,'Moneda no existe.','exclamation')
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
                               	CALL fgl_winmessage(vg_producto,'Cliente no existe.','exclamation')
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
                               	CALL fgl_winmessage(vg_producto,'Modelo no existe.','exclamation')
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
                               	CALL fgl_winmessage(vg_producto,'Tipo de orden no existe.','exclamation')
                               	NEXT FIELD t23_tipo_ot
                        END IF
			DISPLAY r_tip.t05_nombre TO tit_tipo_ot
		ELSE
			CLEAR tit_tipo_ot
                END IF
	AFTER INPUT
		IF rm_ord.t23_estado = 'F' THEN
			IF rm_ord.t23_fecini IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Debe ingresar fecha inicial para ordenes facturadas.','exclamation')
				NEXT FIELD t23_fecini
			END IF
			IF rm_ord.t23_fecfin IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Debe ingresar fecha final para ordenes facturadas.','exclamation')
				NEXT FIELD t23_fecfin
			END IF
			IF rm_ord.t23_fecfin > TODAY THEN
				CALL fgl_winmessage(vg_producto,'Debe ingresar fecha final menor a la de hoy.','exclamation')
				NEXT FIELD t23_fecfin
			END IF
			IF rm_ord.t23_fecini > rm_ord.t23_fecfin THEN
				CALL fgl_winmessage(vg_producto,'Fecha inicial debe ser menor a fecha final.','exclamation')
				NEXT FIELD t23_fecini
			END IF
			LET difmes = month(rm_ord.t23_fecfin)
					- month(rm_ord.t23_fecini)
			IF difmes > 6 THEN
				CALL fgl_winmessage(vg_producto,'El rango de fechas debe ser hasta de 6 meses.','exclamation')
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
DEFINE expr_sql         VARCHAR(600)

LET expr_sql = 'AND t23_estado = "', rm_ord.t23_estado, '"',
		'  AND t23_moneda = "', rm_ord.t23_moneda, '"'
IF rm_ord.t23_estado = 'A' OR rm_ord.t23_estado = 'E' THEN
	IF rm_ord.t23_fecini IS NOT NULL THEN
		LET expr_sql = expr_sql, '  AND t23_fecini BETWEEN "',
			rm_ord.t23_fecini, '" AND "',
			rm_ord.t23_fecfin, '"'
	END IF
END IF
IF rm_ord.t23_estado = 'C' THEN
	IF rm_ord.t23_fecini IS NOT NULL THEN
		LET expr_sql = expr_sql, '  AND DATE(t23_fec_cierre) ',
			'BETWEEN "', rm_ord.t23_fecini, '" AND "',
			rm_ord.t23_fecfin, '"'
	END IF
END IF
IF rm_ord.t23_estado = 'F' THEN
	LET expr_sql = expr_sql, ' AND DATE(t23_fec_factura) BETWEEN "',
		rm_ord.t23_fecini, '" AND "', rm_ord.t23_fecfin, '"'
END IF
IF rm_ord.t23_estado = 'D' THEN
	IF rm_ord.t23_fecini IS NOT NULL THEN
		LET expr_sql = expr_sql, '  AND DATE(t28_fec_anula) ',
			'BETWEEN "', rm_ord.t23_fecini, '" AND "',
			rm_ord.t23_fecfin, '"'
	END IF
END IF
IF rm_ord.t23_cod_cliente IS NOT NULL THEN
	LET expr_sql = expr_sql, '  AND t23_cod_cliente = "',
			rm_ord.t23_cod_cliente, '"'
END IF
IF rm_ord.t23_modelo IS NOT NULL THEN
	LET expr_sql = expr_sql, '  AND t23_modelo = "',
			rm_ord.t23_modelo, '"'
END IF
IF rm_ord.t23_tipo_ot IS NOT NULL THEN
	LET expr_sql = expr_sql, '  AND t23_tipo_ot = "',
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
	t23_tipo_ot, tit_tipo_ot 
INITIALIZE rm_ord.* TO NULL

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i  		SMALLINT

CALL muestra_contadores_det(0)
LET vm_scr_lin = fgl_scr_size('rm_det')
FOR i = 1 TO vm_scr_lin
        INITIALIZE rm_det[i].*, vm_orden[i].* TO NULL
        CLEAR rm_det[i].*
END FOR
CLEAR tit_total

END FUNCTION



FUNCTION muestra_contadores_det(cor)
DEFINE cor	           SMALLINT

DISPLAY "" AT 6, 62
DISPLAY cor, " de ", vm_num_det AT 6, 66

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

END FUNCTION



FUNCTION mostrar_cabecera_forma()

DISPLAY 'Fecha'      TO tit_col1
DISPLAY 'T'          TO tit_col2
DISPLAY 'Cliente'    TO tit_col3
DISPLAY 'Modelo'     TO tit_col4
DISPLAY 'Valor Neto' TO tit_col5

END FUNCTION



FUNCTION ver_orden(i)
DEFINE i		SMALLINT

LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'TALLER',
	vg_separador, 'fuentes', vg_separador, '; fglrun talp204 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ',
	vm_orden[i].t23_orden, ' ', 'O'
RUN vm_nuevoprog

END FUNCTION



FUNCTION ver_orden_nueva(i)
DEFINE i		SMALLINT

LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'TALLER',
	vg_separador, 'fuentes', vg_separador, '; fglrun talp204 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ',
	vm_orden[i].t28_ot_nue, ' ', 'O'
RUN vm_nuevoprog

END FUNCTION



FUNCTION ver_devolucion(i)
DEFINE i		SMALLINT

LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'TALLER',
	vg_separador, 'fuentes', vg_separador, '; fglrun talp211 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ',
	vm_orden[i].t28_num_dev
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
