------------------------------------------------------------------------------
-- Titulo           : repp309.4gl - Consulta transacciones de repuestos      
-- Elaboracion      : 21-feb-2002
-- Autor            : JCM
-- Formato Ejecucion: fglrun repp309 base módulo compañía localidad
--			             [fec_ini] [fec_fin] [tipo] [cliente] 
--				     [moneda]
--			Si tipo = 'C' entonces es un cliente
--			Caso contrario es un tipo de cliente
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE vm_scr_lin       SMALLINT

DEFINE vm_tipo		CHAR(1)
DEFINE vm_cliente	LIKE rept019.r19_codcli
DEFINE vm_moneda	LIKE rept019.r19_moneda
DEFINE vm_expr		VARCHAR(100)

DEFINE rm_par RECORD 
	cod_tran	LIKE rept019.r19_cod_tran,
	n_cod_tran	LIKE gent021.g21_nombre,
	fecha_ini	DATE,
	fecha_fin	DATE
END RECORD

DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT

DEFINE rm_det ARRAY [1000] OF RECORD
	fecha_tran	DATE,
	cod_tran  	LIKE rept019.r19_cod_tran,
	num_tran        LIKE rept019.r19_num_tran,
	referencia     	LIKE rept019.r19_referencia,
	r19_moneda	LIKE rept019.r19_moneda,
	r19_tot_neto	LIKE rept019.r19_tot_neto
END RECORD

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 9 THEN   -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)

LET vg_proceso = 'repp309'

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
OPEN FORM f_rep FROM "../forms/repf309_1"
DISPLAY FORM f_rep
LET vm_scr_lin = 0

CALL muestra_contadores_det(0)
CALL borrar_cabecera()
CALL borrar_detalle()
CALL mostrar_cabecera_forma()
CALL control_consulta()

END FUNCTION



FUNCTION control_consulta()
DEFINE i,j,col		SMALLINT
DEFINE cuantos	 	SMALLINT
DEFINE query		VARCHAR(1000)
DEFINE expr_cod_tran    VARCHAR(40)
DEFINE r_r19		RECORD LIKE rept019.*

DEFINE tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE num_comp		LIKE ctbt012.b12_num_comp

DEFINE tipo_fuente	LIKE cajt010.j10_tipo_fuente
DEFINE num_fuente	LIKE cajt010.j10_num_fuente

DEFINE tabla2		VARCHAR(50)
DEFINE expr_tipcli	VARCHAR(200)

INITIALIZE rm_par.* TO NULL
LET rm_par.fecha_ini = TODAY
LET rm_par.fecha_fin = TODAY
WHILE TRUE
	LET vm_num_det = 0
	CALL borrar_detalle()
	CALL muestra_contadores_det(0)
	IF num_args() = 4 THEN
		LET vm_expr = '1=1'
		LET tabla2 = ' '
		LET expr_tipcli = ' '
		CALL lee_parametros()
		IF int_flag THEN
			EXIT WHILE
		END IF
	ELSE
		LET rm_par.fecha_ini = arg_val(5)
		LET rm_par.fecha_fin = arg_val(6)
		LET vm_tipo      = arg_val(7)
		LET vm_cliente   = arg_val(8)
		LET vm_moneda    = arg_val(9)
	
		IF vm_tipo = 'C' THEN
			LET vm_expr     = 'r19_cod_tran IN ("FA","DF","AF") ', 
					  ' AND r19_codcli =',vm_cliente,
					  ' AND r19_moneda = "',vm_moneda,'"'
			LET tabla2      = ' '
			LET expr_tipcli = ' '
		ELSE
			LET vm_expr     = 'r19_cod_tran IN ("FA","DF","AF") ', 
					  ' AND r19_moneda = "',vm_moneda,'"'
			LET tabla2 = ' ,cxct001 '
			LET expr_tipcli = ' AND z01_codcli = r19_codcli ',
					  ' AND z01_tipo_clte = ', vm_cliente
		END IF
		DISPLAY BY NAME rm_par.*
	END IF
	
	LET expr_cod_tran = ' ' 
	IF rm_par.cod_tran IS NOT NULL THEN
		LET expr_cod_tran = ' AND r19_cod_tran = "', rm_par.cod_tran, 
				    '"'	
	END IF

	FOR i = 1 TO 10
		LET rm_orden[i] = '' 
	END FOR
	LET rm_orden[1]  = 'ASC'
	LET vm_columna_1 = 1
	LET vm_columna_2 = 2
	LET col          = 1
	WHILE TRUE
		LET query = 'SELECT DATE(r19_fecing), r19_cod_tran, ',
			    '       r19_num_tran, r19_nomcli, r19_moneda, ',
			    '       r19_tot_neto ',
			    '	 FROM rept019 ', tabla2 CLIPPED,
			    '	WHERE r19_compania    = ', vg_codcia,
			    '	  AND r19_localidad   = ', vg_codloc,
			    '     AND ',vm_expr, ' ',
			    expr_cod_tran CLIPPED,
			    '	  AND DATE(r19_fecing) BETWEEN ',
				  '"', rm_par.fecha_ini, '" AND ',
				  '"', rm_par.fecha_fin, '"', 
			    expr_tipcli CLIPPED,
			    ' 	ORDER BY ', vm_columna_1, ' ', 
					rm_orden[vm_columna_1], ', ', 
					vm_columna_2, ' ',
                                        rm_orden[vm_columna_2]

		PREPARE deto FROM query
		DECLARE q_deto CURSOR FOR deto
		LET vm_num_det = 1
		FOREACH q_deto INTO rm_det[vm_num_det].*
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
		CALL set_count(vm_num_det)
		LET int_flag = 0
		DISPLAY ARRAY rm_det TO rm_det.*
			BEFORE DISPLAY
				CALL dialog.keysetlabel('ACCEPT','')
			BEFORE ROW
				LET i = arr_curr()
				LET j = scr_line()
				CALL muestra_contadores_det(i)

				SELECT COUNT(*) INTO cuantos FROM rept040 
					WHERE r40_compania  = vg_codcia	
					  AND r40_localidad = vg_codloc
					  AND r40_cod_tran  = rm_det[i].cod_tran
					  AND r40_num_tran  = rm_det[i].num_tran
	
				IF cuantos > 0 THEN
					CALL dialog.keysetlabel('F5', 'Contabilización')
				ELSE
					CALL dialog.keysetlabel('F5', '')
				END IF

				IF rm_det[i].cod_tran = 'DF' THEN
					CALL dialog.keysetlabel('F7', 'Nota de Credito')
				ELSE
					CALL dialog.keysetlabel('F7', '')
				END IF
			AFTER DISPLAY 
				CONTINUE DISPLAY
			ON KEY(INTERRUPT)
				LET int_flag = 1
				EXIT DISPLAY
			ON KEY(F5)
				CALL mostrar_comp_contable(rm_det[i].cod_tran,
					 		   rm_det[i].num_tran)
							   RETURNING tipo_comp,
								     num_comp
				IF tipo_comp IS NOT NULL AND cuantos = 1 THEN
					CALL contabilizacion(tipo_comp, 
							     num_comp)
				END IF
				LET int_flag = 0
			ON KEY(F6)
				CALL fl_ver_transaccion_rep(
					vg_codcia, 
					vg_codloc,
					rm_det[i].cod_tran,
					rm_det[i].num_tran
				)
				LET int_flag = 0
			ON KEY(F7)
				CALL imprimir_nota_credito(vg_codcia, vg_codloc,
										   rm_det[i].cod_tran,
										   rm_det[i].num_tran
				)
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
	IF num_args() <> 4 THEN
		EXIT PROGRAM
	END IF
END WHILE

END FUNCTION



FUNCTION imprimir_nota_credito(codcia, codloc, codtran, numtran)

DEFINE codcia	LIKE rept019.r19_compania
DEFINE codloc	LIKE rept019.r19_localidad
DEFINE codtran  LIKE rept019.r19_cod_tran
DEFINE numtran	LIKE rept019.r19_num_tran

DEFINE comando 		VARCHAR(255)

IF codtran <> 'DF' THEN
	RETURN
END IF

LET comando = 'cd ..', vg_separador, '..', vg_separador,
	      'COBRANZAS', vg_separador, 'fuentes', 
	      vg_separador, '; fglrun cxcp403 ', vg_base, ' ',
	      'CO', codcia, ' ', codloc, ' ', numtran

RUN comando

END FUNCTION



FUNCTION lee_parametros()

DEFINE r_g21		RECORD LIKE gent021.*

LET int_flag = 0
INPUT BY NAME rm_par.* WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN 
	ON KEY(F2)
		IF infield(cod_tran) THEN
			CALL fl_ayuda_tipo_tran('N')
				RETURNING r_g21.g21_cod_tran, 
					  r_g21.g21_nombre
			IF r_g21.g21_cod_tran IS NOT NULL THEN
				LET rm_par.cod_tran = r_g21.g21_cod_tran
				LET rm_par.n_cod_tran = r_g21.g21_nombre
				DISPLAY BY NAME rm_par.*
			END IF 
		END IF
	AFTER FIELD cod_tran
		IF rm_par.cod_tran IS NULL THEN
			LET rm_par.n_cod_tran = NULL
			DISPLAY BY NAME rm_par.cod_tran, rm_par.n_cod_tran
			CONTINUE INPUT
		END IF

		CALL fl_lee_cod_transaccion(rm_par.cod_tran)
                        	RETURNING r_g21.*
		IF r_g21.g21_cod_tran IS NULL THEN
			CALL fgl_winmessage(vg_producto,
				'Código de transacción no existe.',
				'exclamation')
			NEXT FIELD cod_tran
		END IF
		LET rm_par.n_cod_tran = r_g21.g21_nombre
		DISPLAY BY NAME rm_par.n_cod_tran
	AFTER FIELD fecha_ini 
		IF rm_par.fecha_ini IS NOT NULL THEN
			IF rm_par.fecha_ini > TODAY THEN
				CALL fgl_winmessage(vg_producto,
					'La fecha de inicio no puede ser ' || 
					'mayor a la de hoy.',
					'exclamation')
				NEXT FIELD fecha_ini
			END IF
		ELSE
			LET rm_par.fecha_ini = NULL     
			DISPLAY BY NAME rm_par.fecha_ini
		END IF
	AFTER FIELD fecha_fin 
		IF rm_par.fecha_fin IS NOT NULL THEN
			IF rm_par.fecha_fin > TODAY THEN
				CALL fgl_winmessage(vg_producto,
					'La fecha de término no puede ser ' ||
					'mayor a la de hoy.',
					'exclamation')
				NEXT FIELD fecha_fin
			END IF
		ELSE
			LET rm_par.fecha_fin = NULL
			DISPLAY BY NAME rm_par.fecha_fin
		END IF
	AFTER INPUT
		IF rm_par.fecha_ini > rm_par.fecha_fin THEN
			CALL fgl_winmessage(vg_producto,
				'Fecha inicial debe ser menor a fecha final.',
				'exclamation')
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
LET vm_scr_lin = fgl_scr_size('rm_det')
FOR i = 1 TO vm_scr_lin
        INITIALIZE rm_det[i].* TO NULL
        CLEAR rm_det[i].*
END FOR

END FUNCTION



FUNCTION muestra_contadores_det(cor)
DEFINE cor	           SMALLINT

DISPLAY "" AT 21, 2
DISPLAY cor, " de ", vm_num_det AT 21, 6

END FUNCTION


 
FUNCTION mostrar_cabecera_forma()

DISPLAY 'Fecha'   TO tit_col1
DISPLAY 'TR' 	  TO tit_col2
DISPLAY 'Número'  TO tit_col3
DISPLAY 'Cliente' TO tit_col4
DISPLAY 'Mo'      TO tit_col5
DISPLAY 'Valor'   TO tit_col6

END FUNCTION



FUNCTION contabilizacion(tipo_comp, num_comp)

DEFINE comando 		VARCHAR(255)

DEFINE tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE num_comp		LIKE ctbt012.b12_num_comp

LET comando = 'cd ..', vg_separador, '..', vg_separador,
	      'CONTABILIDAD', vg_separador, 'fuentes', 
	      vg_separador, '; fglrun ctbp201 ', vg_base, ' ',
	      'CB ', vg_codcia, ' ', vg_codloc, ' ', tipo_comp, ' ', num_comp

RUN comando

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

OPEN WINDOW w_309_2 AT 10,10 WITH 09 ROWS, 60 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST - 2)
OPEN FORM f_309_2 FROM '../forms/repf309_2'
DISPLAY FORM f_309_2

DISPLAY 'Comprobante' TO bt_tipo_comp
DISPLAY 'Fecha'       TO bt_fecha    
DISPLAY 'Subtipo'     TO bt_subtipo  

IF i = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	CLOSE WINDOW w_309_2
	INITIALIZE r_det[1].* TO NULL
	RETURN r_det[1].tipo_comp, r_det[1].num_comp
END IF

CALL set_count(i)
DISPLAY ARRAY r_det TO r_det.*
	BEFORE DISPLAY
		CALL dialog.keysetlabel('ACCEPT', '')
	BEFORE ROW
		LET i = arr_curr()
	ON KEY(INTERRUPT)
		EXIT DISPLAY
	ON KEY(F5)
		CALL contabilizacion(r_det[i].tipo_comp, r_det[i].num_comp)	
	AFTER DISPLAY
		CONTINUE DISPLAY
END DISPLAY

CLOSE WINDOW w_309_2
RETURN r_det[1].tipo_comp, r_det[1].num_comp

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



FUNCTION fl_ver_comprobantes_emitidos_caja(tipo_fuente, num_fuente, tipo_destino, num_destino, codcli)
DEFINE tipo_fuente	LIKE cajt010.j10_tipo_fuente
DEFINE num_fuente	LIKE cajt010.j10_num_fuente
DEFINE tipo_destino	LIKE cajt010.j10_tipo_destino
DEFINE num_destino	LIKE cajt010.j10_num_destino
DEFINE codcli		LIKE cajt010.j10_codcli	
DEFINE rs		RECORD LIKE cxct024.*	
DEFINE comando		VARCHAR(250)

LET comando = NULL
CASE tipo_fuente
	WHEN 'PR'
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
 			      'REPUESTOS', vg_separador, 'fuentes', 
			      vg_separador, '; fglrun repp308 ', vg_base, ' ',
			      'RE', vg_codcia, ' ', vg_codloc,
			      ' ', tipo_destino, ' ', num_destino
	WHEN 'OT'
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
 			      'TALLER', vg_separador, 'fuentes', 
			      vg_separador, '; fglrun talp204 ', vg_base, ' ',
			      'TA ', vg_codcia, ' ', vg_codloc, ' ', 
			      num_destino, ' F '
	WHEN 'SC'
		CALL fl_lee_solicitud_cobro_cxc(vg_codcia, vg_codloc, num_fuente)
			RETURNING rs.*
		CASE rs.z24_tipo 
			WHEN 'P'
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
 			      'COBRANZAS', vg_separador, 'fuentes', 
			      vg_separador, '; fglrun cxcp202 ', vg_base, ' ',
			      'CO ', vg_codcia, ' ', vg_codloc, ' ', 
			      codcli, ' ', tipo_destino, ' ', num_destino
			WHEN 'A'
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
 			      'COBRANZAS', vg_separador, 'fuentes', 
			      vg_separador, '; fglrun cxcp201 ', vg_base, ' ',
			      'CO ', vg_codcia, ' ', vg_codloc, ' ', 
			      codcli, ' ', tipo_destino, ' ', num_destino
		END CASE
END CASE
IF comando IS NOT NULL THEN
	RUN comando
END IF

END FUNCTION
