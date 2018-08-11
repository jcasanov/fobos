------------------------------------------------------------------------------
-- Titulo           : repp309.4gl - Consulta transacciones de repuestos      
-- Elaboracion      : 21-feb-2002
-- Autor            : JCM
-- Formato Ejecucion: fglrun repp309 base módulo compañía localidad
--			             [fec_ini] [fec_fin] [tipo] [cliente] 
--				     [moneda] [vendedor] [tipo_vta]
--			Si tipo = 'C' entonces es un cliente
--			Caso contrario es un tipo de cliente
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE vm_size_arr      SMALLINT
DEFINE vm_tipo		CHAR(1)
DEFINE vm_cliente	LIKE rept019.r19_codcli
DEFINE vm_moneda	LIKE rept019.r19_moneda
DEFINE vm_vendedor	LIKE rept019.r19_vendedor
DEFINE vm_expr		VARCHAR(230)
DEFINE vm_expr_ven	VARCHAR(30)
DEFINE vm_expr_vta_inv	VARCHAR(100)
DEFINE vm_total		DECIMAL(14,2)
DEFINE rm_par 		RECORD 
				r19_moneda	LIKE rept019.r19_moneda,
				tit_moneda	LIKE gent013.g13_nombre,
				cod_tran	LIKE rept019.r19_cod_tran,
				n_cod_tran	LIKE gent021.g21_nombre,
				fecha_ini	DATE,
				fecha_fin	DATE
			END RECORD
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE rm_det 		ARRAY [20000] OF RECORD
				fecha_tran	DATE,
				cod_tran  	LIKE rept019.r19_cod_tran,
				num_tran        LIKE rept019.r19_num_tran,
				referencia     	LIKE rept019.r19_referencia,
				r19_moneda	LIKE rept019.r19_moneda,
				r19_tot_neto	LIKE rept019.r19_tot_neto
			END RECORD
DEFINE rm_g01		RECORD LIKE gent001.*



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp309.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 11 THEN   -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'repp309'
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
OPEN WINDOW w_repp309 AT row_ini, 02 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_repf309_1 FROM "../forms/repf309_1"
ELSE
	OPEN FORM f_repf309_1 FROM "../forms/repf309_1c"
END IF
DISPLAY FORM f_repf309_1
CALL fl_lee_compania(vg_codcia) RETURNING rm_g01.*
LET vm_size_arr = 0
CALL muestra_contadores_det(0)
CALL borrar_cabecera()
CALL borrar_detalle()
CALL mostrar_cabecera_forma()
CALL control_consulta()

END FUNCTION



FUNCTION control_consulta()
DEFINE r_g13		RECORD LIKE gent013.*

INITIALIZE rm_par.* TO NULL
LET rm_par.fecha_ini  = vg_fecha
LET rm_par.fecha_fin  = vg_fecha
LET rm_par.r19_moneda = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_par.r19_moneda) RETURNING r_g13.*
IF r_g13.g13_moneda IS NULL THEN
	CALL fl_mostrar_mensaje('No existe moneda base.', 'stop')
        EXIT PROGRAM
END IF
LET rm_par.tit_moneda = r_g13.g13_nombre
DISPLAY r_g13.g13_nombre TO tit_moneda
WHILE TRUE
	LET vm_num_det = 0
	CALL borrar_detalle()
	CALL muestra_contadores_det(0)
	IF num_args() = 4 THEN
		CALL lee_parametros()
		IF int_flag THEN
			EXIT WHILE
		END IF
	END IF
	CALL control_detalle()
	IF num_args() <> 4 THEN
		EXIT WHILE
	END IF
END WHILE
LET int_flag = 0
CLOSE WINDOW w_repp309
EXIT PROGRAM

END FUNCTION



FUNCTION control_detalle()
DEFINE i, j, col	SMALLINT
DEFINE cuantos	 	SMALLINT
DEFINE query		CHAR(2100)
DEFINE expr_cod_tran    VARCHAR(100)
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE num_comp		LIKE ctbt012.b12_num_comp
DEFINE transaccion	VARCHAR(20)
DEFINE tabla2		VARCHAR(50)
DEFINE expr_tipcli	VARCHAR(200)
DEFINE expr_ord		VARCHAR(10)
DEFINE param		VARCHAR(60)

IF num_args() = 4 THEN
	LET vm_expr     = '1=1'
	LET tabla2      = ' '
	LET expr_tipcli = ' '
ELSE
	LET rm_par.fecha_ini = arg_val(5)
	LET rm_par.fecha_fin = arg_val(6)
	LET vm_tipo          = arg_val(7)
	LET vm_cliente       = arg_val(8)
	LET vm_moneda        = arg_val(9)
	LET vm_vendedor      = arg_val(10)
	LET vm_expr_ven      = NULL
	LET rm_par.r19_moneda = vm_moneda
	LET vm_expr_vta_inv = NULL
	IF arg_val(11) <> 'T' THEN
		LET vm_expr_vta_inv = '   AND r19_cont_cred   = "',
					arg_val(11), '"'
	END IF
	IF vm_vendedor > 0 THEN
		LET vm_expr_ven  = ' AND r19_vendedor = ', vm_vendedor
	END IF
	IF vm_tipo = 'C' THEN
		LET vm_expr     = 'r19_cod_tran IN ("FA","NV","DF","AF") ', 
				vm_expr_vta_inv CLIPPED,
				  ' AND r19_codcli =',vm_cliente,
				  ' AND r19_moneda = "',
						rm_par.r19_moneda, '"',
				  vm_expr_ven
		LET tabla2      = ' '
		LET expr_tipcli = ' '
	ELSE
		LET vm_expr     = 'r19_cod_tran IN ("FA","NV","DF","AF") ', 
				vm_expr_vta_inv CLIPPED,
				  ' AND r19_moneda = "',
						rm_par.r19_moneda, '"',
				  vm_expr_ven
		LET tabla2 	= ' , cxct001 '
		LET expr_tipcli = ' AND z01_codcli = r19_codcli ',
				  ' AND z01_tipo_clte = ', vm_cliente
	END IF
	DISPLAY BY NAME rm_par.*
END IF
LET expr_cod_tran = ' ' 
IF rm_par.cod_tran IS NOT NULL THEN
	LET expr_cod_tran = ' AND r19_cod_tran = "',rm_par.cod_tran,'"'
END IF
LET expr_cod_tran = expr_cod_tran,
			' AND r19_moneda   = "', rm_par.r19_moneda, '"'
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET col           = 3
LET vm_columna_1  = col
LET vm_columna_2  = 1
LET rm_orden[col] = 'DESC'
WHILE TRUE
	LET expr_ord = NULL
	IF vm_columna_1 = 1 THEN
		LET expr_ord = ', 7 ASC'
	END IF
	LET query = 'SELECT DATE(r19_fecing), r19_cod_tran,',
			' r19_num_tran, CASE WHEN r19_nomcli = " " ',
			'THEN r19_referencia ELSE r19_nomcli END CASE,',
			'r19_moneda, (r19_tot_bruto - r19_tot_dscto), ',
			'rept019.ROWID ',
		    '	 FROM rept019 ', tabla2 CLIPPED,
		    '	WHERE r19_compania    = ', vg_codcia,
		    '	  AND r19_localidad   = ', vg_codloc,
		    '     AND ', vm_expr, ' ',
		    expr_cod_tran CLIPPED,
		    '	  AND DATE(r19_fecing) BETWEEN ',
		  '"', rm_par.fecha_ini, '" AND ',
		  '"', rm_par.fecha_fin, '"', 
		    expr_tipcli CLIPPED,
		' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
			expr_ord CLIPPED,
			', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE deto FROM query
	DECLARE q_deto CURSOR FOR deto
	LET vm_num_det = 1
	FOREACH q_deto INTO rm_det[vm_num_det].*
		IF rm_det[vm_num_det].cod_tran = 'DF' OR
		   rm_det[vm_num_det].cod_tran = 'DC' OR
		   rm_det[vm_num_det].cod_tran = 'AF' THEN
			LET rm_det[vm_num_det].r19_tot_neto =
				rm_det[vm_num_det].r19_tot_neto * (-1) 
		END IF
		LET vm_num_det = vm_num_det + 1
		IF vm_num_det > vm_max_det THEN
			IF num_args() <> 4 THEN
				CALL fl_mensaje_arreglo_incompleto()
				EXIT PROGRAM
			END IF
			EXIT FOREACH
		END IF
	END FOREACH
	LET vm_num_det = vm_num_det - 1
	IF vm_num_det = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		EXIT WHILE
	END IF
	IF vg_gui = 0 THEN
		CALL muestra_etiquetas_det(1)
	END IF
	CALL sacar_total()
	CALL set_count(vm_num_det)
	DISPLAY ARRAY rm_det TO rm_det.*
		ON KEY(INTERRUPT)
			EXIT DISPLAY
       		ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_1() 
		ON KEY(RETURN)
			LET i = arr_curr()
			LET j = scr_line()
			CALL muestra_etiquetas_det(i)
		ON KEY(F5)
			LET i = arr_curr()
			LET j = scr_line()
			CALL mostrar_comp_contable(rm_det[i].cod_tran,
				 		   rm_det[i].num_tran)
				   RETURNING tipo_comp, num_comp
			IF tipo_comp IS NOT NULL AND cuantos = 1 THEN
				CALL contabilizacion(tipo_comp, num_comp)
			END IF
			LET int_flag = 0
		ON KEY(F6)
			LET i = arr_curr()
			LET j = scr_line()
			CALL fl_ver_transaccion_rep(vg_codcia, vg_codloc,
					rm_det[i].cod_tran, rm_det[i].num_tran)
			IF rm_det[i].cod_tran = 'IA' THEN
				LET param = vg_codloc, ' "', rm_det[i].cod_tran,
						'" ', rm_det[i].num_tran
				CALL ejecuta_comando('REPUESTOS', vg_modulo,
							'repp308 ', param)
			END IF
			LET int_flag = 0
		ON KEY(F7)
			LET i = arr_curr()
			LET j = scr_line()
			CALL imprime_transaccion(rm_det[i].cod_tran,
						rm_det[i].num_tran)
			LET int_flag = 0
		ON KEY(F8)
			CALL imprimir_listado()
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
			--#CALL dialog.keysetlabel("RETURN","")
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#LET j = scr_line()
			--#CALL muestra_etiquetas_det(i)
			--#SELECT COUNT(*) INTO cuantos FROM rept040 
			--#	WHERE r40_compania  = vg_codcia	
			--#	  AND r40_localidad = vg_codloc
			--#	  AND r40_cod_tran  = rm_det[i].cod_tran
			--#	  AND r40_num_tran  = rm_det[i].num_tran
			--#IF cuantos > 0 THEN
				--#CALL dialog.keysetlabel('F5', 
				--#	'Contabilización')
			--#ELSE
				--#CALL dialog.keysetlabel('F5', '')
			--#END IF
			--#CALL retorna_transaccion(rm_det[i].cod_tran)
				--#RETURNING transaccion
			--#CALL dialog.keysetlabel('F7', transaccion)
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

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_g21		RECORD LIKE gent021.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE mone_aux         LIKE gent013.g13_moneda
DEFINE nomm_aux         LIKE gent013.g13_nombre
DEFINE deci_aux         LIKE gent013.g13_decimales
DEFINE fec_ini		DATE
DEFINE fec_fin		DATE

LET int_flag = 0
INPUT BY NAME rm_par.* WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(r19_moneda) THEN
               		CALL fl_ayuda_monedas()
                       		RETURNING mone_aux, nomm_aux, deci_aux
                      	IF mone_aux IS NOT NULL THEN
                              	LET rm_par.r19_moneda = mone_aux
                               	DISPLAY BY NAME rm_par.r19_moneda
                               	DISPLAY nomm_aux TO tit_moneda
                       	END IF
                END IF
		IF INFIELD(cod_tran) THEN
			CALL fl_ayuda_tipo_tran('N')
				RETURNING r_g21.g21_cod_tran, 
					  r_g21.g21_nombre
			IF r_g21.g21_cod_tran IS NOT NULL THEN
				LET rm_par.cod_tran = r_g21.g21_cod_tran
				LET rm_par.n_cod_tran = r_g21.g21_nombre
				DISPLAY BY NAME rm_par.*
			END IF 
		END IF
		LET int_flag = 0 
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD fecha_ini
		LET fec_ini = rm_par.fecha_ini
	BEFORE FIELD fecha_fin
		LET fec_fin = rm_par.fecha_fin
	AFTER FIELD r19_moneda
               	IF rm_par.r19_moneda IS NOT NULL THEN
                       	CALL fl_lee_moneda(rm_par.r19_moneda)
                               	RETURNING r_g13.*
                       	IF r_g13.g13_moneda IS NULL THEN
				CALL fl_mostrar_mensaje('Moneda no existe.','exclamation')
                               	NEXT FIELD r19_moneda
                       	END IF
                       	IF rm_par.r19_moneda <> rg_gen.g00_moneda_base
                       	AND rm_par.r19_moneda <> rg_gen.g00_moneda_alt THEN
				CALL fl_mostrar_mensaje('La moneda solo puede ser moneda base o alterna.','exclamation')
                               	NEXT FIELD r19_moneda
			END IF
               	ELSE
                       	LET rm_par.r19_moneda = rg_gen.g00_moneda_base
                       	CALL fl_lee_moneda(rm_par.r19_moneda)
				RETURNING r_g13.*
                       	DISPLAY BY NAME rm_par.r19_moneda
               	END IF
               	DISPLAY r_g13.g13_nombre TO tit_moneda
	AFTER FIELD cod_tran
		IF rm_par.cod_tran IS NULL THEN
			LET rm_par.n_cod_tran = NULL
			DISPLAY BY NAME rm_par.cod_tran, rm_par.n_cod_tran
			CONTINUE INPUT
		END IF

		CALL fl_lee_cod_transaccion(rm_par.cod_tran)
                        	RETURNING r_g21.*
		IF r_g21.g21_cod_tran IS NULL THEN
			CALL fl_mostrar_mensaje('Código de transacción no existe.','exclamation')
			NEXT FIELD cod_tran
		END IF
		LET rm_par.n_cod_tran = r_g21.g21_nombre
		DISPLAY BY NAME rm_par.n_cod_tran
	AFTER FIELD fecha_ini 
		IF rm_par.fecha_ini IS NOT NULL THEN
			IF rm_par.fecha_ini > vg_fecha THEN
				CALL fl_mostrar_mensaje('La fecha de inicio no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD fecha_ini
			END IF
		ELSE
			LET rm_par.fecha_ini = fec_ini     
			DISPLAY BY NAME rm_par.fecha_ini
		END IF
	AFTER FIELD fecha_fin 
		IF rm_par.fecha_fin IS NOT NULL THEN
			IF rm_par.fecha_fin > vg_fecha THEN
				CALL fl_mostrar_mensaje('La fecha de término no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD fecha_fin
			END IF
		ELSE
			LET rm_par.fecha_fin = fec_fin
			DISPLAY BY NAME rm_par.fecha_fin
		END IF
	AFTER INPUT
		IF rm_par.fecha_ini > rm_par.fecha_fin THEN
			CALL fl_mostrar_mensaje('Fecha inicial debe ser menor a fecha final.','exclamation')
			NEXT FIELD fecha_ini
		END IF
END INPUT

END FUNCTION



FUNCTION borrar_cabecera()

INITIALIZE rm_par.* TO NULL
DISPLAY BY NAME rm_par.*

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i  		SMALLINT

CALL muestra_contadores_det(0)
--#LET vm_size_arr = fgl_scr_size('rm_det')
IF vg_gui = 0 THEN
	LET vm_size_arr = 12
END IF
FOR i = 1 TO vm_size_arr
        INITIALIZE rm_det[i].* TO NULL
        CLEAR rm_det[i].*
END FOR
CLEAR vm_total, g21_nombre

END FUNCTION



FUNCTION muestra_contadores_det(num_row)
DEFINE num_row		SMALLINT

DISPLAY BY NAME num_row, vm_num_det

END FUNCTION


 
FUNCTION mostrar_cabecera_forma()

--#DISPLAY 'Fecha'   TO tit_col1
--#DISPLAY 'TP'	     TO tit_col2
--#DISPLAY 'Número'  TO tit_col3
--#DISPLAY 'Cliente' TO tit_col4
--#DISPLAY 'Mo'      TO tit_col5
--#DISPLAY 'Valor'   TO tit_col6

END FUNCTION



FUNCTION contabilizacion(tipo_comp, num_comp)
DEFINE tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE num_comp		LIKE ctbt012.b12_num_comp
DEFINE param		VARCHAR(60)

LET param = ' "', tipo_comp, '" ', num_comp CLIPPED
CALL ejecuta_comando('CONTABILIDAD', 'CB', 'ctbp201 ', param)

END FUNCTION



FUNCTION mostrar_comp_contable(cod_tran, num_tran)
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE i       	 	SMALLINT
DEFINE max_rows		SMALLINT
DEFINE r_det ARRAY[50] OF RECORD
	tipo_comp		LIKE rept040.r40_tipo_comp,
	num_comp		LIKE rept040.r40_num_comp,
	fecha			LIKE ctbt012.b12_fec_proceso,
	subtipo			LIKE ctbt004.b04_nombre
END RECORD

LET max_rows = 50
DECLARE q_cursor1 CURSOR FOR
	SELECT r40_tipo_comp, r40_num_comp, b12_fec_proceso, b04_nombre
		FROM rept040, ctbt012, OUTER ctbt004
		WHERE r40_compania  = vg_codcia
		  AND r40_localidad = vg_codloc
		  AND r40_cod_tran  = cod_tran
		  AND r40_num_tran  = num_tran
		  AND b12_compania  = r40_compania
		  AND b12_tipo_comp = r40_tipo_comp
		  AND b12_num_comp  = r40_num_comp
		  AND b04_compania  = b12_compania
		  AND b04_subtipo   = b12_subtipo 
LET i = 1
FOREACH q_cursor1 INTO r_det[i].*
	LET i = i + 1
	IF i > max_rows THEN
		EXIT FOREACH
	END IF
END FOREACH

LET i = i - 1
IF i = 1 THEN
	RETURN r_det[1].tipo_comp, r_det[1].num_comp
END IF

OPEN WINDOW w_309_2 AT 10, 11 WITH 09 ROWS, 60 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST - 2)
IF vg_gui = 1 THEN
	OPEN FORM f_309_2 FROM '../forms/repf309_2'
ELSE
	OPEN FORM f_309_2 FROM '../forms/repf309_2c'
END IF
DISPLAY FORM f_309_2

--#DISPLAY 'Comprobante' TO bt_tipo_comp
--#DISPLAY 'Fecha'       TO bt_fecha    
--#DISPLAY 'Subtipo'     TO bt_subtipo  

IF i = 0 THEN
	INITIALIZE r_det[1].* TO NULL
	CALL fl_mensaje_consulta_sin_registros()
	CLOSE WINDOW w_309_2
	RETURN r_det[1].tipo_comp, r_det[1].num_comp
END IF

CALL set_count(i)
DISPLAY ARRAY r_det TO r_det.*
	ON KEY(INTERRUPT)
		EXIT DISPLAY
       	ON KEY(F1,CONTROL-W)
		CALL control_visor_teclas_caracter_2() 
	ON KEY(F5)
		LET i = arr_curr()
		CALL contabilizacion(r_det[i].tipo_comp, r_det[i].num_comp)	
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel('ACCEPT', '')
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
		--#CALL dialog.keysetlabel("RETURN","")
	--#BEFORE ROW
		--#LET i = arr_curr()
	--#AFTER DISPLAY
		--#CONTINUE DISPLAY
END DISPLAY

LET i = arr_curr()
CLOSE WINDOW w_309_2
RETURN r_det[i].tipo_comp, r_det[i].num_comp

END FUNCTION



FUNCTION imprime_transaccion(cod_tran, num_tran)
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE r_r19            RECORD LIKE rept019.*   -- Transacción Repuestos
DEFINE impresion	CHAR(1)

INITIALIZE impresion TO NULL
IF cod_tran = 'FA' OR cod_tran = 'DF' OR cod_tran = 'AF' THEN
	LET impresion = 'F'
	CALL fl_lee_cabecera_transaccion_rep(vg_codcia, vg_codloc, cod_tran,
						num_tran)
		RETURNING r_r19.*
	IF r_r19.r19_tipo_dev IS NOT NULL THEN
		CALL control_sel_impresion(cod_tran, num_tran)
			RETURNING impresion
		IF int_flag THEN
			RETURN
		END IF
	END IF
	CASE impresion
		WHEN 'F'
			CALL imprimir_comprobante(cod_tran, num_tran, 1)
		WHEN 'D'
			CALL imprimir_comprobante(r_r19.r19_cod_tran,
						r_r19.r19_num_tran, 2)
		WHEN 'T'
			CALL imprimir_comprobante(cod_tran, num_tran, 1)
			CALL imprimir_comprobante(r_r19.r19_cod_tran,
						r_r19.r19_num_tran, 2)
	END CASE
END IF
IF cod_tran = 'A-' OR cod_tran = 'A+' THEN
	CALL imprimir_comprobante(cod_tran, num_tran, 3)
END IF
CASE cod_tran
	WHEN 'CL'
		CALL imprimir_comprobante(cod_tran, num_tran, 4)
	WHEN 'DC'
		CALL imprimir_comprobante(cod_tran, num_tran, 5)
	WHEN 'RQ'
		CALL imprimir_comprobante(cod_tran, num_tran, 6)
	WHEN 'DR'
		CALL imprimir_comprobante(cod_tran, num_tran, 7)
	WHEN 'TR'
		CALL imprimir_comprobante(cod_tran, num_tran, 8)
	WHEN 'IM'
		CALL imprimir_comprobante(cod_tran, num_tran, 9)
	WHEN 'AC'
		CALL imprimir_comprobante(cod_tran, num_tran, 10)
END CASE

END FUNCTION



FUNCTION control_sel_impresion(cod_tran, num_tran)
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE impresion	CHAR(1)
DEFINE row_max		SMALLINT
DEFINE col_max		SMALLINT

LET row_max = 11
LET col_max = 42
IF vg_gui = 0 THEN
	LET row_max = 10
	LET col_max = 43
END IF
OPEN WINDOW w_309_3 AT 08, 20 WITH row_max ROWS, col_max COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST - 2)
IF vg_gui = 1 THEN
	OPEN FORM f_309_3 FROM '../forms/repf309_3'
ELSE
	OPEN FORM f_309_3 FROM '../forms/repf309_3c'
END IF
DISPLAY FORM f_309_3
LET impresion = 'F'
DISPLAY BY NAME cod_tran, num_tran, impresion
IF vg_gui = 0 THEN
	CALL muestra_impresion(impresion)
END IF
LET int_flag = 0
INPUT BY NAME impresion WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD impresion
		IF vg_gui = 0 THEN
			IF impresion IS NOT NULL THEN
				CALL muestra_impresion(impresion)
			ELSE
				CLEAR tit_impresion
			END IF
		END IF
END INPUT
CLOSE WINDOW w_309_3
RETURN impresion

END FUNCTION



FUNCTION imprimir_comprobante(cod_tran, num_tran, reporte)
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE reporte, salir	SMALLINT
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE query		VARCHAR(250)
DEFINE expr_tran	VARCHAR(70)
DEFINE prog		VARCHAR(10)
DEFINE param		VARCHAR(60)

LET salir = 0
LET param = vg_codloc, ' "', cod_tran, '" ', num_tran CLIPPED
CASE reporte
	WHEN 1
		LET prog = 'repp410 '
	WHEN 2
		LET expr_tran = '  AND r19_cod_tran  = "', cod_tran, '"',
				'  AND r19_num_tran  = ',  num_tran
		IF cod_tran = 'FA' THEN
			LET expr_tran = '  AND r19_tipo_dev  = "', cod_tran,'"',
					'  AND r19_num_dev   = ',  num_tran
		END IF
		LET query = 'SELECT * FROM rept019 ',
				'WHERE r19_compania  = ', vg_codcia,
				'  AND r19_localidad = ', vg_codloc,
				expr_tran CLIPPED
		PREPARE devanu FROM query
		DECLARE q_r19 CURSOR FOR devanu
		LET prog = 'repp401 '
		FOREACH q_r19 INTO r_r19.*
			IF r_r19.r19_tipo_dev IS NULL THEN
				CONTINUE FOREACH
			END IF
			LET param = vg_codloc, ' "', r_r19.r19_cod_tran, '" ',
					r_r19.r19_num_tran CLIPPED
			CALL ejecuta_comando('REPUESTOS',vg_modulo, prog, param)
		END FOREACH
		LET salir = 1
	WHEN 3
		LET prog = 'repp411 '
	WHEN 4
		LET prog = 'repp413 '
	WHEN 5
		LET prog = 'repp416 '
	WHEN 6
		LET prog = 'repp414 '
	WHEN 7
		LET prog = 'repp417 '
	WHEN 8
		LET prog = 'repp415 '
	WHEN 9
		CALL fl_lee_cabecera_transaccion_rep(vg_codcia, vg_codloc,
							cod_tran, num_tran)
			RETURNING r_r19.*
		IF r_r19.r19_numliq IS NULL THEN
			CALL fl_mostrar_mensaje('No existe el número de la liquidación.','exclamation')
		ELSE
			LET prog  = 'repp408 '
			LET param = vg_codloc, ' ', r_r19.r19_numliq CLIPPED
		END IF
		LET salir = 1
	WHEN 10
		LET prog = 'repp412 '
END CASE
IF NOT salir THEN
	CALL ejecuta_comando('REPUESTOS', vg_modulo, prog, param)
END IF

END FUNCTION



FUNCTION imprimir_listado()
DEFINE comando		VARCHAR(100)
DEFINE i		SMALLINT

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
START REPORT report_list_trans TO PIPE comando
FOR i = 1 TO vm_num_det
	OUTPUT TO REPORT report_list_trans(i)
END FOR
FINISH REPORT report_list_trans
RETURN

END FUNCTION



REPORT report_list_trans(i)
DEFINE i		SMALLINT
DEFINE r_g21		RECORD LIKE gent021.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE usuario		VARCHAR(19,15)
DEFINE modulo		VARCHAR(40)
DEFINE factura		VARCHAR(15)
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
	CALL fl_lee_cod_transaccion(rm_par.cod_tran) RETURNING r_g21.*
	print ASCII escape;
	print ASCII desact_comp;
	print ASCII escape;
	print ASCII act_10cpi;
	PRINT COLUMN 005, rm_g01.g01_razonsocial,
  	      COLUMN 074, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 029, "DETALLE DE TRANSACCIONES",
	      COLUMN 074, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 022, "** MONEDA        : ", rm_par.r19_moneda,
						" ", rm_par.tit_moneda
	IF rm_par.cod_tran IS NOT NULL THEN
		PRINT COLUMN 022, "** TIPO TRANSAC. : ", rm_par.cod_tran, " ",
							r_g21.g21_nombre
	ELSE
		PRINT 1 SPACES
	END IF
	PRINT COLUMN 022, "** FECHA INICIAL : ", rm_par.fecha_ini
							USING "dd-mm-yyyy"
	PRINT COLUMN 022, "** FECHA FINAL   : ", rm_par.fecha_fin
							USING "dd-mm-yyyy"
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", vg_fecha USING "dd-mm-yyyy",
 		1 SPACES, TIME,
	      COLUMN 062, usuario
	PRINT "--------------------------------------------------------------------------------"
	PRINT COLUMN 001, "FECHA",
	      COLUMN 012, "TP",
	      COLUMN 015, "N U M E R O",
	      COLUMN 031, "C L I E N T E",
	      COLUMN 065, "Mo",
	      COLUMN 068, "        VALOR"
	PRINT "--------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 3 LINES
	LET factura = rm_det[i].num_tran
	CALL fl_justifica_titulo('I', factura, 15) RETURNING factura
	PRINT COLUMN 001, rm_det[i].fecha_tran		USING "dd-mm-yyyy",
	      COLUMN 012, rm_det[i].cod_tran,
	      COLUMN 015, factura,
	      COLUMN 031, rm_det[i].referencia[1, 33],
	      COLUMN 065, rm_det[i].r19_moneda,
	      COLUMN 068, rm_det[i].r19_tot_neto	USING "--,---,--&.##"
	
ON LAST ROW
	NEED 2 LINES
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 070, "-------------"
	PRINT COLUMN 057, "TOTAL ==>  ", vm_total USING "--,---,--&.##";
	print ASCII escape;
	print ASCII des_neg;
	print ASCII escape;
	print ASCII act_comp

END REPORT



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



FUNCTION muestra_impresion(impresion)
DEFINE impresion	CHAR(1)

CASE impresion
	WHEN 'F'
		DISPLAY 'FACTURA'              TO tit_impresion
	WHEN 'D'
		DISPLAY 'DEVOLUCION/ANULACION' TO tit_impresion
	WHEN 'T'
		DISPLAY 'T O D A S'            TO tit_impresion
	OTHERWISE
		CLEAR impresion, tit_impresion
END CASE

END FUNCTION



FUNCTION retorna_transaccion(cod_tran)
DEFINE cod_tran		LIKE rept019.r19_cod_tran

IF cod_tran = 'FA' OR cod_tran = 'DF' OR cod_tran = 'AF' THEN
	RETURN 'Impr. Fact/Dev/Anul'
END IF
IF cod_tran = 'A-' OR cod_tran = 'A+' THEN
	RETURN 'Impr. Ajustes Exis.'
END IF
CASE cod_tran
	WHEN 'CL'
		RETURN 'Impr. Compra Loc.'
	WHEN 'DC'
		RETURN 'Impr. Dev/Comp/Loc'
	WHEN 'RQ'
		RETURN 'Imprimir Requisición'
	WHEN 'DR'
		RETURN 'Imprimir Dev. Req.'
	WHEN 'TR'
		RETURN 'Impr. Transferencia'
	WHEN 'IM'
		RETURN 'Impr. Importación'
	WHEN 'AC'
		RETURN 'Impr. Ajuste Costo'
	WHEN 'IA'
		RETURN ''
END CASE

END FUNCTION



FUNCTION sacar_total()
DEFINE i		SMALLINT

LET vm_total = 0
FOR i = 1 TO vm_num_det
	LET vm_total = vm_total + rm_det[i].r19_tot_neto
END FOR
DISPLAY BY NAME vm_total

END FUNCTION



FUNCTION muestra_etiquetas_det(i)
DEFINE i		SMALLINT
DEFINE r_g21		RECORD LIKE gent021.*

CALL muestra_contadores_det(i)
CALL fl_lee_cod_transaccion(rm_det[i].cod_tran) RETURNING r_g21.*
DISPLAY BY NAME r_g21.g21_nombre
IF r_g21.g21_cod_tran = "FA" OR r_g21.g21_cod_tran = "DF" OR
   r_g21.g21_cod_tran = "AF"
THEN
	--#DISPLAY 'Cliente'    TO tit_col4
ELSE
	IF r_g21.g21_cod_tran = "CL" OR r_g21.g21_cod_tran = "DC" THEN
		--#DISPLAY 'Proveedor'  TO tit_col4
	ELSE
		--#DISPLAY 'Referencia' TO tit_col4
	END IF
END IF

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
DISPLAY '<F5>      Comprobante Contable'     AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Ver Transacción'          AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F7>      Imprimir Transacción'     AT a,2
DISPLAY  'F7' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F8>      Imprimir Listado'         AT a,2
DISPLAY  'F8' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION control_visor_teclas_caracter_2() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Ver Comprobante'          AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
