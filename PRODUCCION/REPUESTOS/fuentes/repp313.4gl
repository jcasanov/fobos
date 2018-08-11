------------------------------------------------------------------------------
-- Titulo           : repp313.4gl - Consulta Ordenes de Despacho
-- Elaboracion      : 23-Ago-2002
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp313 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_r34		RECORD LIKE rept034.*
DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE vm_size_arr      SMALLINT
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE r_desp		ARRAY[3000] OF RECORD
				r34_bodega	LIKE rept034.r34_bodega,
				r34_num_ord_des LIKE rept034.r34_num_ord_des,
				r34_cod_tran	LIKE rept034.r34_cod_tran,
				r34_num_tran	LIKE rept034.r34_num_tran,
				r34_fec_entrega	LIKE rept034.r34_fec_entrega,
				r34_entregar_a	LIKE rept034.r34_entregar_a
			END RECORD
DEFINE vm_imprimir	CHAR(1)
DEFINE vm_incluir	CHAR(1)
DEFINE tot_cant_fact	INTEGER
DEFINE rm_g05		RECORD LIKE gent005.*



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp313.err')
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
LET vg_proceso = 'repp313'
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
CALL fl_lee_usuario(vg_usuario) RETURNING rm_g05.*
LET vm_max_det = 3000
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
OPEN WINDOW w_mas AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
			MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rep FROM "../forms/repf313_1"
ELSE
	OPEN FORM f_rep FROM "../forms/repf313_1c"
END IF
DISPLAY FORM f_rep
LET vm_size_arr = 0
CALL muestra_contadores_det(0)
CALL borrar_cabecera()
CALL borrar_detalle()
CALL mostrar_cabecera_forma()
CALL control_consulta()
LET int_flag = 0
CLOSE WINDOW w_mas
EXIT PROGRAM

END FUNCTION



FUNCTION control_consulta()
DEFINE r_ord_des	RECORD
				r34_bodega	LIKE rept034.r34_bodega,
				r34_num_ord_des LIKE rept034.r34_num_ord_des,
				r34_cod_tran	LIKE rept034.r34_cod_tran,
				r34_num_tran	LIKE rept034.r34_num_tran,
				r34_fec_entrega	LIKE rept034.r34_fec_entrega,
				r34_entregar_a	LIKE rept034.r34_entregar_a
			END RECORD
DEFINE i, j, col, resul	SMALLINT
DEFINE query		CHAR(1000)
DEFINE expr_est         VARCHAR(100)
DEFINE expr_bod         VARCHAR(100)
DEFINE expr_ran         VARCHAR(100)
DEFINE run_prog		CHAR(10)
DEFINE tit_estado	CHAR(15)
DEFINE r_r34		RECORD LIKE rept034.*
DEFINE ord_des		LIKE rept034.r34_num_ord_des
DEFINE cant_tot_fac	LIKE rept020.r20_cant_ven
DEFINE cant_tot_dev	LIKE rept020.r20_cant_ven

LET rm_r34.r34_estado = 'P'
DISPLAY BY NAME rm_r34.r34_estado
IF vg_gui = 0 THEN
	CALL muestra_estado(rm_r34.r34_estado, 1) RETURNING tit_estado
END IF
LET vm_imprimir = 'O'
LET vm_incluir  = 'N'
WHILE TRUE
	LET vm_num_det = 0
	CALL borrar_detalle()
	CALL muestra_contadores_det(0)
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	LET expr_est = NULL
	LET expr_bod = NULL
	LET expr_ran = NULL
	LET resul    = 0
	IF rm_r34.r34_estado = 'P' THEN
		LET expr_est = '  AND r34_estado IN ("A", "P") '
		CALL obtener_ord_des_pend_real(rm_r34.r34_bodega)
			RETURNING resul
	ELSE
		LET expr_est    = '  AND r34_estado = "', rm_r34.r34_estado, '"'
		LET vm_imprimir = 'O'
	END IF
	IF rm_r34.r34_bodega IS NOT NULL THEN
		LET expr_bod = '  AND r34_bodega = "', rm_r34.r34_bodega, '"'
	END IF
	IF vm_fecha_ini IS NOT NULL THEN
		LET expr_ran = '  AND r34_fec_entrega BETWEEN "', vm_fecha_ini,
				'" AND "', vm_fecha_fin, '"'
	END IF
	FOR i = 1 TO 10
		LET rm_orden[i] = '' 
	END FOR
	LET col           = 2
	LET rm_orden[col] = 'DESC'
	LET vm_columna_1  = col
	LET vm_columna_2  = 5
	LET rm_orden[5]   = 'DESC'
	WHILE TRUE
		LET query = 'SELECT r34_bodega, r34_num_ord_des, r34_cod_tran,',
				' r34_num_tran, r34_fec_entrega,',
				' r34_entregar_a ',
			' FROM rept034 ',
			' WHERE r34_compania    = ', vg_codcia,
			'   AND r34_localidad   = ', vg_codloc,
			expr_est CLIPPED, 
			expr_bod CLIPPED, 
			expr_ran CLIPPED, 
			" ORDER BY ", vm_columna_1, ' ', rm_orden[vm_columna_1],
			       	', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
		PREPARE deto FROM query
		DECLARE q_deto CURSOR FOR deto
		LET vm_num_det = 1
		FOREACH q_deto INTO r_ord_des.*
			SELECT NVL(SUM(r20_cant_ven), 0)
				INTO cant_tot_fac
				FROM rept019, rept020
				WHERE r19_compania  = vg_codcia
				  AND r19_localidad = vg_codloc
				  AND r19_cod_tran  = r_ord_des.r34_cod_tran
				  AND r19_num_tran  = r_ord_des.r34_num_tran
				  AND r20_compania  = r19_compania
				  AND r20_localidad = r19_localidad
				  AND r20_cod_tran  = r19_cod_tran
				  AND r20_num_tran  = r19_num_tran
			SELECT NVL(SUM(r20_cant_ven), 0)
				INTO cant_tot_dev
				FROM rept019, rept020
				WHERE r19_compania  = vg_codcia
				  AND r19_localidad = vg_codloc
				  AND r19_cod_tran  = 'DF'
				  AND r19_tipo_dev  = r_ord_des.r34_cod_tran
				  AND r19_num_dev   = r_ord_des.r34_num_tran
				  AND r20_compania  = r19_compania
				  AND r20_localidad = r19_localidad
				  AND r20_cod_tran  = r19_cod_tran
				  AND r20_num_tran  = r19_num_tran
			IF cant_tot_dev = cant_tot_fac THEN
				CONTINUE FOREACH
			END IF
			IF resul THEN
				CALL fl_lee_orden_despacho(vg_codcia, vg_codloc,
						rm_r34.r34_bodega,
						r_ord_des.r34_num_ord_des)
					RETURNING r_r34.*
				LET ord_des = NULL
				SELECT UNIQUE r35_num_ord_des INTO ord_des
					FROM t4
					WHERE r20_cod_tran = r_r34.r34_cod_tran
					  AND r20_num_tran = r_r34.r34_num_tran
					  AND r35_num_ord_des =
							r_r34.r34_num_ord_des
				IF ord_des IS NULL THEN
					CONTINUE FOREACH
				END IF
			END IF
			LET r_desp[vm_num_det].* = r_ord_des.*
			LET vm_num_det = vm_num_det + 1
			IF vm_num_det > vm_max_det THEN
				EXIT FOREACH
			END IF
		END FOREACH
		FREE q_deto
		LET vm_num_det = vm_num_det - 1
		IF vm_num_det = 0 THEN
			CALL fl_mensaje_consulta_sin_registros()
			EXIT WHILE
		END IF
		IF vg_gui = 0 THEN
			CALL muestra_datos_det(1)
		END IF
		LET int_flag = 0
		CALL set_count(vm_num_det)
		DISPLAY ARRAY r_desp TO r_desp.*
			ON KEY(INTERRUPT)
				LET int_flag = 1
				EXIT DISPLAY
			ON KEY(RETURN)
				LET i = arr_curr()
				CALL muestra_datos_det(i)
        		ON KEY(F1,CONTROL-W)
				CALL control_visor_teclas_caracter_1() 
			ON KEY(F5)
				LET i = arr_curr()
				LET j = scr_line()
				CALL fl_ver_transaccion_rep(vg_codcia,vg_codloc,
							r_desp[i].r34_cod_tran,
							r_desp[i].r34_num_tran)
			ON KEY(F6)
				LET i = arr_curr()
				LET j = scr_line()
				CALL llamar_orden_despacho(i, 1)
				LET int_flag = 0
			ON KEY(F7)
				IF rm_r34.r34_estado <> 'D' THEN
					LET i = arr_curr()
					LET j = scr_line()
					CALL llamar_orden_despacho(i, 2)
					LET int_flag = 0
				END IF
			ON KEY(F8)
				LET i = arr_curr()
				LET j = scr_line()
				CALL llamar_nota_entrega(i)
				LET int_flag = 0
			ON KEY(F9)
				IF (NOT tiene_codigo_caja()  OR
				    rm_g05.g05_tipo <> 'UF') AND
				   (rm_g05.g05_grupo = 'GE'  OR
				    rm_g05.g05_grupo = 'SI'  OR
				    rm_g05.g05_grupo = 'OD')
				THEN
					LET i = arr_curr()
					LET j = scr_line()
					CALL imprimir_orden(i)
					LET int_flag = 0
				END IF
			ON KEY(F10)
				CALL control_imprimir()
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
			--#BEFORE DISPLAY
				--#CALL dialog.keysetlabel('ACCEPT','')
				--#CALL dialog.keysetlabel("F1","")
				--#CALL dialog.keysetlabel("CONTROL-W","")
				--#CALL dialog.keysetlabel("F5","Factura")
				--#CALL dialog.keysetlabel("F6","Orden Despacho")
				--#CALL dialog.keysetlabel("F8","Nota Entrega")
				--#CALL dialog.keysetlabel("F10","Imprimir Listado")
				--#IF rm_r34.r34_estado <> 'D' THEN
					--#CALL dialog.keysetlabel("F7","Ord. Desp. Pend.")
				--#ELSE
					--#CALL dialog.keysetlabel("F7","")
				--#END IF
				--#IF (NOT tiene_codigo_caja()  OR
				    --#rm_g05.g05_tipo <> 'UF') AND
				   --#(rm_g05.g05_grupo = 'GE'  OR
				    --#rm_g05.g05_grupo = 'SI'  OR
				    --#rm_g05.g05_grupo = 'OD')
				--#THEN
					--#CALL dialog.keysetlabel("F9","Imprimir Orden")
				--#ELSE
					--#CALL dialog.keysetlabel("F9","")
				--#END IF
			--#BEFORE ROW
				--#LET i = arr_curr()
				--#LET j = scr_line()
				--#CALL muestra_datos_det(i)
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
	IF resul THEN
		DROP TABLE t4
	END IF
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE
DEFINE tit_estado	CHAR(15)

LET int_flag = 0
INPUT BY NAME rm_r34.r34_estado, rm_r34.r34_bodega, vm_fecha_ini, vm_fecha_fin
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(r34_bodega) THEN
			CALL fl_ayuda_bodegas_rep(vg_codcia,  vg_codloc, 'T', '2', 'A', 'S', 'V')
				RETURNING r_r02.r02_codigo,
					  r_r02.r02_nombre 
			LET int_flag = 0
			IF r_r02.r02_codigo IS NOT NULL THEN
				LET rm_r34.r34_bodega = r_r02.r02_codigo
				DISPLAY r_r02.r02_codigo TO r34_bodega
				DISPLAY r_r02.r02_nombre TO tit_bodega
			END IF
		END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD vm_fecha_ini
		LET fecha_ini = vm_fecha_ini
	BEFORE FIELD vm_fecha_fin
		LET fecha_fin = vm_fecha_fin
	AFTER FIELD r34_estado
		IF rm_r34.r34_estado IS NOT NULL THEN
			DISPLAY BY NAME rm_r34.r34_estado
			IF vg_gui = 0 THEN
				CALL muestra_estado(rm_r34.r34_estado, 1)
					RETURNING tit_estado
			END IF
		ELSE
			IF vg_gui = 0 THEN
				CLEAR tit_estado
			END IF
		END IF
		IF rm_r34.r34_estado = 'D' THEN
			IF vm_fecha_ini IS NULL THEN
				LET vm_fecha_ini = vg_fecha
				DISPLAY BY NAME vm_fecha_ini
			END IF
			IF vm_fecha_fin IS NULL THEN
				LET vm_fecha_fin = vg_fecha
				DISPLAY BY NAME vm_fecha_fin
			END IF
		END IF
	AFTER FIELD r34_bodega
		IF rm_r34.r34_bodega IS NOT NULL THEN
			CALL fl_lee_bodega_rep(vg_codcia, rm_r34.r34_bodega)
				RETURNING r_r02.*
			IF r_r02.r02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe esa Bodega.','exclamation')
				NEXT FIELD r34_bodega
			END IF
       	                IF r_r02.r02_estado = 'B' THEN
               	                CALL fl_mensaje_estado_bloqueado()
                       	        NEXT FIELD r34_bodega
                        END IF
			DISPLAY r_r02.r02_nombre TO tit_bodega
		ELSE
			CLEAR tit_bodega
		END IF
	AFTER FIELD vm_fecha_ini 
		IF vm_fecha_ini IS NOT NULL THEN
			IF vm_fecha_ini > vg_fecha THEN
				CALL fl_mostrar_mensaje('La Fecha Inicial no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD vm_fecha_ini
			END IF
			IF vm_fecha_fin IS NULL THEN
				LET vm_fecha_fin = vg_fecha
			END IF
			DISPLAY BY NAME vm_fecha_fin
		ELSE
			IF rm_r34.r34_estado = 'D' THEN
				LET vm_fecha_ini = fecha_ini
			END IF
			DISPLAY BY NAME vm_fecha_ini
		END IF
	AFTER FIELD vm_fecha_fin 
		IF vm_fecha_fin IS NOT NULL THEN
			IF vm_fecha_fin > vg_fecha THEN
				CALL fl_mostrar_mensaje('La Fecha Final no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD vm_fecha_fin
			END IF
		ELSE
			IF rm_r34.r34_estado = 'D' THEN
				LET vm_fecha_fin = fecha_fin
			END IF
			DISPLAY BY NAME vm_fecha_fin
		END IF
	AFTER INPUT
		IF rm_r34.r34_bodega IS NULL THEN
			NEXT FIELD r34_bodega
		END IF
		IF vm_fecha_ini > vm_fecha_fin THEN
			CALL fl_mostrar_mensaje('Fecha Inicial debe ser menor a Fecha Final.','exclamation')
			NEXT FIELD vm_fecha_ini
		END IF
		IF rm_r34.r34_estado = 'D' THEN
			IF vm_fecha_ini IS NULL THEN
				CALL fl_mostrar_mensaje('Debe ingresar Fecha Inicial.','exclamation')
				NEXT FIELD vm_fecha_ini
			END IF
			IF vm_fecha_fin IS NULL THEN
				CALL fl_mostrar_mensaje('Debe ingresar Fecha Final.','exclamation')
				NEXT FIELD vm_fecha_fin
			END IF
		END IF
		IF vm_fecha_ini IS NULL THEN
			IF vm_fecha_fin IS NOT NULL THEN
				CALL fl_mostrar_mensaje('Debe ingresar también la Fecha Inicial.','exclamation')
				NEXT FIELD vm_fecha_ini
			END IF
		END IF
		IF vm_fecha_fin IS NULL THEN
			IF vm_fecha_ini IS NOT NULL THEN
				CALL fl_mostrar_mensaje('Debe ingresar también la Fecha Final.','exclamation')
				NEXT FIELD vm_fecha_fin
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION borrar_cabecera()

CLEAR r34_estado, vm_fecha_ini, vm_fecha_fin, r34_bodega, tit_bodega
INITIALIZE rm_r34.*, vm_fecha_ini, vm_fecha_fin TO NULL

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i  		SMALLINT

CALL muestra_contadores_det(0)
--#LET vm_size_arr = fgl_scr_size('r_desp')
IF vg_gui = 0 THEN
	LET vm_size_arr = 10
END IF
FOR i = 1 TO vm_size_arr
        INITIALIZE r_desp[i].* TO NULL
        CLEAR r_desp[i].*
END FOR
CLEAR r34_entregar_en

END FUNCTION



FUNCTION muestra_contadores_det(cor)
DEFINE cor                 SMALLINT

DISPLAY cor        TO num_row
DISPLAY vm_num_det TO max_row

END FUNCTION



FUNCTION mostrar_cabecera_forma()

--#DISPLAY 'BD'       TO tit_col1
--#DISPLAY 'Orden'    TO tit_col2
--#DISPLAY 'TP'       TO tit_col3
--#DISPLAY 'Factura'  TO tit_col4
--#DISPLAY 'Fecha'    TO tit_col5
--#DISPLAY 'Entregar' TO tit_col6

END FUNCTION


 
FUNCTION llamar_orden_despacho(i, flag)
DEFINE i, flag		SMALLINT
DEFINE comando		CHAR(400)
DEFINE run_prog		CHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS',
	vg_separador, 'fuentes', vg_separador, run_prog, 'repp231 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' "',
	r_desp[i].r34_cod_tran, '" ', r_desp[i].r34_num_tran
IF flag = 2 THEN
	LET comando = comando CLIPPED, ' "C" "P"'
END IF
RUN comando

END FUNCTION


 
FUNCTION llamar_nota_entrega(i)
DEFINE i		SMALLINT
DEFINE comando		CHAR(400)
DEFINE run_prog		CHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS',
	vg_separador, 'fuentes', vg_separador, run_prog, 'repp314 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ',
	r_desp[i].r34_bodega, ' ', r_desp[i].r34_num_ord_des, ' "D"'
RUN comando

END FUNCTION



FUNCTION imprimir_orden(i)
DEFINE i		SMALLINT
DEFINE comando		CHAR(400)
DEFINE run_prog		CHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS',
	vg_separador, 'fuentes', vg_separador, run_prog, 'repp431 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ',
	r_desp[i].r34_bodega, ' ', r_desp[i].r34_num_ord_des
RUN comando

END FUNCTION



FUNCTION muestra_estado(estado, flag)
DEFINE estado		CHAR(1)
DEFINE flag		SMALLINT
DEFINE tit_estado	CHAR(15)

CASE estado
	WHEN 'P'
		LET tit_estado = 'PENDIENTES'
	WHEN 'D'
		LET tit_estado = 'DESPACHADAS'
	OTHERWISE
		IF flag = 1 THEN
			CLEAR r34_estado, tit_estado
		END IF
END CASE
IF flag = 1 THEN
	DISPLAY BY NAME tit_estado
END IF
RETURN tit_estado

END FUNCTION



FUNCTION obtener_ord_des_pend_real(bodega_des)
DEFINE bodega_des	LIKE rept034.r34_bodega
DEFINE fec_i, fec_f	LIKE rept020.r20_fecing
DEFINE query		CHAR(600)
DEFINE fec_ini, fec_fin	DATE
DEFINE cuantos		INTEGER
DEFINE expr_bod		VARCHAR(100)
DEFINE expr_fec		VARCHAR(100)

LET expr_bod = '   AND r20_bodega     = ', bodega_des
IF bodega_des IS NULL THEN
	LET query = 'SELECT r02_codigo FROM rept002 ',
			' WHERE r02_compania  = ', vg_codcia,
			'   AND r02_localidad = ', vg_codloc,
			'   AND r02_factura   = "S" ',
			' INTO TEMP t_bd1 '
	PREPARE cons_bod FROM query
	EXECUTE cons_bod
	LET expr_bod = '   AND r20_bodega    IN (SELECT r02_codigo FROM t_bd1)'
END IF
LET fec_ini = vm_fecha_ini
LET fec_fin = vm_fecha_fin
IF vm_fecha_ini IS NULL THEN
	LET fec_ini = MDY(01, 01, 2003)
	LET fec_fin = vg_fecha
END IF
LET fec_i = EXTEND(fec_ini, YEAR TO SECOND)
LET fec_f = EXTEND(fec_fin, YEAR TO SECOND) + 23 UNITS HOUR + 59 UNITS MINUTE
		+ 59 UNITS SECOND
LET query = 'SELECT r20_cod_tran, r20_num_tran, DATE(r20_fecing) fecha, ',
			'r20_bodega, r20_item, r20_cant_ven ',
		' FROM rept020 ',
		' WHERE r20_compania   = ', vg_codcia,
		'   AND r20_localidad  = ', vg_codloc,
		'   AND r20_cod_tran   = "FA"',
		expr_bod CLIPPED,
		'   AND r20_fecing    BETWEEN "', fec_i, '" AND "', fec_f, '"',
		' INTO TEMP t_r20'
PREPARE cons_r20 FROM query
EXECUTE cons_r20
IF bodega_des IS NULL THEN
	DROP TABLE t_bd1
END IF
SELECT r19_cod_tran, r19_num_tran, r19_tipo_dev, r19_num_dev
	FROM rept019
	WHERE r19_compania  = vg_codcia
	  AND r19_localidad = vg_codloc
	  AND r19_cod_tran  = "FA"
	  AND (r19_tipo_dev = "DF" OR r19_tipo_dev IS NULL)
	INTO TEMP t_r19
SELECT t_r20.* FROM t_r20, t_r19
	WHERE r19_cod_tran = r20_cod_tran
	  AND r19_num_tran = r20_num_tran
	INTO TEMP t1
DROP TABLE t_r19
DROP TABLE t_r20
LET expr_fec = NULL
IF vm_fecha_ini IS NOT NULL THEN
	LET expr_fec = '   AND r34_fec_entrega BETWEEN "', vm_fecha_ini,
						'" AND "', vm_fecha_fin, '"'
END IF
LET query = 'SELECT r34_compania, r34_localidad, r34_bodega, r34_num_ord_des,',
			' r34_cod_tran,	r34_num_tran ',
		' FROM rept034 ',
		' WHERE r34_compania   = ', vg_codcia,
		'   AND r34_localidad  = ', vg_codloc,
		'   AND r34_estado    IN ("A", "P") ',
		expr_fec CLIPPED,
		' INTO TEMP t_r34'
PREPARE cons_t_r34 FROM query
EXECUTE cons_t_r34
SELECT r20_cod_tran, r20_num_tran, fecha, r20_bodega, r20_item, r34_num_ord_des
	FROM t1, t_r34
	WHERE r34_compania  = vg_codcia
	  AND r34_localidad = vg_codloc
	  AND r34_bodega    = r20_bodega
	  AND r34_cod_tran  = r20_cod_tran
	  AND r34_num_tran  = r20_num_tran
	INTO TEMP t2
DROP TABLE t1
DROP TABLE t_r34
SELECT COUNT(*) INTO cuantos FROM t2
IF cuantos = 0 THEN
	DROP TABLE t2
	RETURN 0
END IF
SELECT UNIQUE r35_num_ord_des, r20_bodega bodega, r20_item item,
	SUM(r35_cant_des - r35_cant_ent) cantidad
	FROM t2, rept035
	WHERE r35_compania    = vg_codcia
	  AND r35_localidad   = vg_codloc
	  AND r35_bodega      = r20_bodega
	  AND r35_num_ord_des = r34_num_ord_des
	  AND r35_item        = r20_item
	GROUP BY 1, 2, 3
	HAVING SUM(r35_cant_des - r35_cant_ent) > 0
	INTO TEMP t3
SELECT UNIQUE r20_cod_tran, r20_num_tran, fecha, r35_num_ord_des, r20_bodega,
	r20_item, cantidad cant_fin
	FROM t2, t3
	WHERE r20_bodega      = bodega
	  AND r20_item        = item
	  AND r35_num_ord_des = r34_num_ord_des
	INTO TEMP t4
DROP TABLE t2
DROP TABLE t3
SELECT COUNT(*) INTO cuantos FROM t4
IF cuantos = 0 THEN
	DROP TABLE t4
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION control_imprimir()
DEFINE resul		SMALLINT

IF rm_r34.r34_estado = 'P' THEN
	CALL leer_parametros_imp()
	IF int_flag THEN
		RETURN
	END IF
END IF
CASE vm_imprimir
	WHEN 'O'
		CALL imprimir_listado_orden()
	WHEN 'I'
		CALL ejecutar_impresion_items()
	WHEN 'T'
		CALL imprimir_listado_orden()
		CALL ejecutar_impresion_items()
END CASE
IF vm_incluir = 'S' THEN
	DROP TABLE t4
	CALL obtener_ord_des_pend_real(rm_r34.r34_bodega) RETURNING resul
END IF
RETURN

END FUNCTION



FUNCTION leer_parametros_imp()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE col_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

LET lin_menu = 0
LET row_ini  = 6
LET col_ini  = 20
LET num_rows = 10
LET num_cols = 47
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 9
	LET col_ini  = 17
	LET num_rows = 6
	LET num_cols = 48
END IF
OPEN WINDOW w_repf313_2 AT row_ini, col_ini WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_repf313_2 FROM "../forms/repf313_2"
ELSE
	OPEN FORM f_repf313_2 FROM "../forms/repf313_2c"
END IF
DISPLAY FORM f_repf313_2
IF vg_gui = 0 THEN
	CALL muestra_imprimir(vm_imprimir)
END IF
LET int_flag = 0
INPUT BY NAME vm_imprimir, vm_incluir
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
CLOSE WINDOW w_repf313_2
RETURN

END FUNCTION



FUNCTION imprimir_listado_orden()
DEFINE comando		CHAR(100)
DEFINE i		SMALLINT

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
START REPORT report_pendientes_orden TO PIPE comando
FOR i = 1 TO vm_num_det
	OUTPUT TO REPORT report_pendientes_orden(i)
END FOR
FINISH REPORT report_pendientes_orden

END FUNCTION



FUNCTION ejecutar_impresion_items()
DEFINE resul		SMALLINT
DEFINE bodega_d		LIKE rept034.r34_bodega

IF vm_incluir = 'S' THEN
	DROP TABLE t4
	LET bodega_d = NULL
	CALL obtener_ord_des_pend_real(bodega_d) RETURNING resul
END IF
CALL genera_archivo_item()
CALL imprimir_listado_items()

END FUNCTION



FUNCTION imprimir_listado_items()
DEFINE comando		CHAR(100)
DEFINE r_report		RECORD
				cod_tran	LIKE rept020.r20_cod_tran,
				num_tran	LIKE rept020.r20_num_tran,
				fecha_tran	DATE,
				num_ord_des	LIKE rept034.r34_num_ord_des,
				bodega		LIKE rept020.r20_bodega,
				item		LIKE rept020.r20_item,
				canti		DECIMAL(10,2)
			END RECORD

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
DECLARE q_t4 CURSOR FOR
	SELECT * FROM t4 ORDER BY r20_bodega, r20_num_tran DESC
START REPORT report_pendientes_items TO PIPE comando
LET tot_cant_fact = 0
FOREACH q_t4 INTO r_report.*
	OUTPUT TO REPORT report_pendientes_items(r_report.*)
END FOREACH
FINISH REPORT report_pendientes_items

END FUNCTION



REPORT report_pendientes_orden(i)
DEFINE i		SMALLINT
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE modulo		VARCHAR(40)
DEFINE factura		VARCHAR(15)
DEFINE cant_fact	INTEGER
DEFINE usuario		VARCHAR(10,5)
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
	CALL fl_lee_compania(vg_codcia) RETURNING r_g01.*
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo      = "MODULO: ", r_g50.g50_nombre[1, 19] CLIPPED
	CALL fl_justifica_titulo('D', vg_usuario, 10) RETURNING usuario
	CALL fl_lee_bodega_rep(vg_codcia, rm_r34.r34_bodega) RETURNING r_r02.*
	print ASCII escape;
	print ASCII desact_comp;
	print ASCII escape;
	print ASCII act_10cpi;
	PRINT COLUMN 005, r_g01.g01_razonsocial,
  	      COLUMN 074, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 029, "DETALLE DE ORDENES DESPACHO",
	      COLUMN 074, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 022, "** ESTADO        : ", rm_r34.r34_estado, " ",
		muestra_estado(rm_r34.r34_estado, 2)
	PRINT COLUMN 022, "** BODEGA        : ", rm_r34.r34_bodega, " ",
						 r_r02.r02_nombre
	IF vm_fecha_ini IS NOT NULL THEN
		PRINT COLUMN 022, "** FECHA INICIAL : ", vm_fecha_ini
							USING "dd-mm-yyyy"
	ELSE
		PRINT COLUMN 001, 1 SPACES
	END IF
	IF vm_fecha_fin IS NOT NULL THEN
		PRINT COLUMN 022, "** FECHA FINAL   : ", vm_fecha_fin
							USING "dd-mm-yyyy"
	ELSE
		PRINT COLUMN 001, 1 SPACES
	END IF
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", vg_fecha USING "dd-mm-yyyy",
 		1 SPACES, TIME,
	      COLUMN 071, usuario
	PRINT "--------------------------------------------------------------------------------"
	PRINT COLUMN 001, "BD",
	      COLUMN 004, "ORDEN",
	      COLUMN 011, "F A C T U R A S",
	      COLUMN 030, "FECHA",
	      COLUMN 041, "ENTREGAR"
	PRINT "--------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 3 LINES
	LET factura = r_desp[i].r34_num_tran
	CALL fl_justifica_titulo('I', factura, 15) RETURNING factura
	PRINT COLUMN 001, r_desp[i].r34_bodega,
	      COLUMN 004, r_desp[i].r34_num_ord_des	USING "<<<<<&",
	      COLUMN 011, r_desp[i].r34_cod_tran, '-',
	      COLUMN 014, factura,
	      COLUMN 030, r_desp[i].r34_fec_entrega	USING "dd-mm-yyyy",
	      COLUMN 041, r_desp[i].r34_entregar_a
	
ON LAST ROW
	SKIP 1 LINES
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 005, "TOTAL ORDENES DESPACHO  ==> ",
		vm_num_det USING "<<<<<<&";
	print ASCII escape;
	print ASCII des_neg;
	print ASCII escape;
	print ASCII act_comp

END REPORT



REPORT report_pendientes_items(r_report)
DEFINE r_report		RECORD
				cod_tran	LIKE rept020.r20_cod_tran,
				num_tran	LIKE rept020.r20_num_tran,
				fecha_tran	DATE,
				num_ord_des	LIKE rept034.r34_num_ord_des,
				bodega		LIKE rept020.r20_bodega,
				item		LIKE rept020.r20_item,
				canti		DECIMAL(10,2)
			END RECORD
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE modulo		VARCHAR(40)
DEFINE factura		VARCHAR(15)
DEFINE cant_fact	INTEGER
DEFINE usuario		VARCHAR(19, 15)
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
	CALL fl_lee_compania(vg_codcia) RETURNING r_g01.*
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo  = "MODULO: ", r_g50.g50_nombre[1, 19] CLIPPED
	LET usuario = "USUARIO: ", vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	print ASCII escape;
	print ASCII act_10cpi;
	print ASCII escape;
	print ASCII act_comp;
	PRINT COLUMN 005, r_g01.g01_razonsocial,
  	      COLUMN 122, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 029, "DETALLE DE ITEMS PENDIENTES",
	      COLUMN 126, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 022, "** ESTADO        : ", rm_r34.r34_estado, " ",
		muestra_estado(rm_r34.r34_estado, 2)
	IF vm_fecha_ini IS NOT NULL THEN
		PRINT COLUMN 022, "** FECHA INICIAL : ", vm_fecha_ini
							USING "dd-mm-yyyy"
	ELSE
		PRINT COLUMN 001, 1 SPACES
	END IF
	IF vm_fecha_fin IS NOT NULL THEN
		PRINT COLUMN 022, "** FECHA FINAL   : ", vm_fecha_fin
							USING "dd-mm-yyyy"
	ELSE
		PRINT COLUMN 001, 1 SPACES
	END IF
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", vg_fecha USING "dd-mm-yyyy",
 		1 SPACES, TIME,
	      COLUMN 114, usuario
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 004, "F A C T U R A S",
	      COLUMN 050, "C L I E N T E S",
	      COLUMN 094, "FECHA",
	      COLUMN 106, "ORD. D.",
	      COLUMN 115, "ITEMS",
	      COLUMN 124, " CANTIDAD"
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 004, r_report.cod_tran, '-',
	      COLUMN 007, factura,
	      COLUMN 024, r_r19.r19_nomcli[1, 68]	CLIPPED,
	      COLUMN 094, r_report.fecha_tran		USING "dd-mm-yyyy",
	      COLUMN 106, r_report.num_ord_des		USING "<<<<<<&",
	      COLUMN 115, r_report.item[1, 7]		CLIPPED,
	      COLUMN 124, r_report.canti		USING "--,--&.##"

BEFORE GROUP OF r_report.bodega
	LET cant_fact = 0
	CALL fl_lee_bodega_rep(vg_codcia, r_report.bodega) RETURNING r_r02.*
	NEED 8 LINES
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 003, r_report.bodega,
	      COLUMN 006, r_r02.r02_nombre;
	print ASCII escape;
	print ASCII des_neg
	SKIP 1 LINES

ON EVERY ROW
	NEED 6 LINES
	LET factura = r_report.num_tran
	CALL fl_justifica_titulo('I', factura, 15) RETURNING factura
	CALL fl_lee_cabecera_transaccion_rep(vg_codcia, vg_codloc,
						r_report.cod_tran,
						r_report.num_tran)
		RETURNING r_r19.*
	PRINT COLUMN 004, r_report.cod_tran, '-',
	      COLUMN 007, factura,
	      COLUMN 024, r_r19.r19_nomcli[1, 68]	CLIPPED,
	      COLUMN 094, r_report.fecha_tran		USING "dd-mm-yyyy",
	      COLUMN 106, r_report.num_ord_des		USING "<<<<<<&",
	      COLUMN 115, r_report.item[1, 7]		CLIPPED,
	      COLUMN 124, r_report.canti		USING "--,--&.##"
	
AFTER GROUP OF r_report.bodega
	NEED 5 LINES
	SKIP 1 LINES
	SELECT UNIQUE r20_num_tran FROM t4
		WHERE r20_bodega = r_report.bodega INTO TEMP caca
	SELECT COUNT(*) INTO cant_fact FROM caca
	DROP TABLE caca
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 005, "TOTAL FACTURA BODEGA ", r_report.bodega, " ==> ",
	      cant_fact USING "<<<<<<&";
	print ASCII escape;
	print ASCII des_neg
	LET tot_cant_fact = tot_cant_fact + cant_fact
	SKIP 1 LINES

ON LAST ROW
	NEED 2 LINES
	SKIP 1 LINES
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 005, "TOTAL FACTURAS          ==> ",
		tot_cant_fact USING "<<<<<<&";
	print ASCII escape;
	print ASCII des_neg;
	print ASCII escape;
	print ASCII desact_comp

END REPORT



FUNCTION muestra_imprimir(imprimir)
DEFINE imprimir		CHAR(1)
DEFINE tit_imprimir	CHAR(25)

CASE imprimir
	WHEN 'O'
		LET tit_imprimir = 'POR ORDEN DE DESPACHO'
	WHEN 'I'
		LET tit_imprimir = 'POR ITEM'
	WHEN 'T'
		LET tit_imprimir = 'T O D O S'
	OTHERWISE
		CLEAR vm_imprimir, tit_imprimir
END CASE
DISPLAY BY NAME tit_imprimir

END FUNCTION



FUNCTION muestra_datos_det(i)
DEFINE i		SMALLINT
DEFINE r_r34		RECORD LIKE rept034.*

CALL muestra_contadores_det(i)
CALL fl_lee_orden_despacho(vg_codcia, vg_codloc, r_desp[i].r34_bodega,
				r_desp[i].r34_num_ord_des)
	RETURNING r_r34.*
DISPLAY BY NAME r_r34.r34_entregar_en

END FUNCTION



FUNCTION tiene_codigo_caja()
DEFINE r_j02		RECORD LIKE cajt002.*

INITIALIZE r_j02.* TO NULL
DECLARE q_j02 CURSOR FOR
	SELECT * FROM cajt002
		WHERE j02_compania  = vg_codcia
		  AND j02_localidad = vg_codloc
		  AND j02_usua_caja = rm_g05.g05_usuario
OPEN q_j02
FETCH q_j02 INTO r_j02.*
CLOSE q_j02
FREE q_j02
IF r_j02.j02_compania IS NULL THEN
	RETURN 0
ELSE
	RETURN 1
END IF

END FUNCTION



FUNCTION genera_archivo_item()
DEFINE resp		CHAR(6)
DEFINE mensaje		VARCHAR(100)

LET int_flag = 0
CALL fl_hacer_pregunta('Desea generar también un archivo? ', 'Yes')
	RETURNING resp
IF resp <> "Yes" THEN
	LET int_flag = 0
	RETURN
END IF
ERROR 'Generando Archivo repp313.unl ... por favor espere'
SELECT r20_bodega, r35_num_ord_des, r20_cod_tran, r20_num_tran, fecha, 
	r20_item, r72_desc_clase clase, r10_nombre descrip, r10_marca,
	cant_fin
	FROM t4, rept010, rept072
	WHERE r10_compania  = 1
	  AND r10_codigo    = r20_item
	  AND r72_compania  = r10_compania
	  AND r72_linea     = r10_linea
	  AND r72_sub_linea = r10_sub_linea
	  AND r72_cod_grupo = r10_cod_grupo
	  AND r72_cod_clase = r10_cod_clase
	INTO TEMP tmp_arc1
SELECT tmp_arc1.*, r34_entregar_en entregar_en
	FROM tmp_arc1, rept034
	WHERE r34_compania    = 1
	  AND r34_localidad   = vg_codloc
	  AND r34_bodega      = r20_bodega
	  AND r34_num_ord_des = r35_num_ord_des
	INTO TEMP tmp_arc2
DROP TABLE tmp_arc1
SELECT tmp_arc2.*, r01_nombres vendedor
	FROM tmp_arc2, rept019, rept001
	WHERE r19_compania  = 1
	  AND r19_localidad = vg_codloc
	  AND r19_cod_tran  = r20_cod_tran
	  AND r19_num_tran  = r20_num_tran
	  AND r01_compania  = r19_compania
	  AND r01_codigo    = r19_vendedor
	INTO TEMP tmp_arc3
DROP TABLE tmp_arc2
UNLOAD TO "../../../tmp/repp313.unl"
	SELECT * FROM tmp_arc3
		ORDER BY 5, 6
DROP TABLE tmp_arc3
RUN "mv ../../../tmp/repp313.unl $HOME/tmp/"
LET mensaje = FGL_GETENV("HOME"), '/tmp/repp313.unl'
CALL fl_mostrar_mensaje('Archivo Generado en: ' || mensaje, 'info')
ERROR ' '

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
DISPLAY '<F6>      Orden Despacho Bodega'    AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F7>      Orden Despacho Pend.'     AT a,2
DISPLAY  'F7' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F8>      Nota Entrega Bodega'      AT a,2
DISPLAY  'F8' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F9>      Imprimir Orden'           AT a,2
DISPLAY  'F9' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F10>     Imprimir Listado'         AT a,2
DISPLAY  'F10' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
