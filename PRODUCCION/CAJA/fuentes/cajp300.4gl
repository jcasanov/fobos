------------------------------------------------------------------------------
-- Titulo           : cajp300.4gl - Consulta transacciones procesadas por caja
-- Elaboracion      : 20-dic-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun cajp300 base módulo compañía localidad
-- Ultima Correccion: 28-05-2002
-- Motivo Correccion: (RCA) Linea 133 se le corrigió del SELECT
--		      el parámetro 'E' de Eliminado
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_nuevoprog     VARCHAR(400)
DEFINE rm_caj		RECORD LIKE cajt010.*
DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE vm_scr_lin       SMALLINT
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE rm_det		ARRAY [1000] OF RECORD
				j10_fecha_pro	DATE,
				j10_nomcli	LIKE cajt010.j10_nomcli,
				j10_tipo_destino LIKE cajt010.j10_tipo_destino,
				j10_num_destino	LIKE cajt010.j10_num_destino,
				j11_codigo_pago	LIKE cajt011.j11_codigo_pago,
				j11_moneda	LIKE cajt011.j11_moneda,
				j11_valor	LIKE cajt011.j11_valor
			END RECORD
DEFINE rm_cajs		ARRAY[1000] OF RECORD
				j10_compania	LIKE cajt010.j10_compania,
				j10_localidad	LIKE cajt010.j10_localidad,
				j10_tipo_fuente	LIKE cajt010.j10_tipo_fuente,
				j10_num_fuente	LIKE cajt010.j10_num_fuente,
				j10_codcli	LIKE cajt010.j10_codcli
			END RECORD

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cajp300.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN   -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'cajp300'
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
OPEN FORM f_caj FROM "../forms/cajf300_1"
DISPLAY FORM f_caj
LET vm_scr_lin = 0
CALL muestra_contadores_det(0)
CALL borrar_cabecera()
CALL borrar_detalle()
CALL mostrar_cabecera_forma()
CALL control_consulta()

END FUNCTION



FUNCTION control_consulta()
DEFINE i,j,col		SMALLINT
DEFINE query		VARCHAR(1000)
DEFINE expr_sql         VARCHAR(400)
DEFINE expr_sql2        VARCHAR(100)

DEFINE cuantos		SMALLINT

DEFINE tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE num_comp		LIKE ctbt012.b12_num_comp

LET vm_fecha_ini = TODAY
LET vm_fecha_fin = TODAY
WHILE TRUE
	LET vm_num_det = 0
	CALL borrar_detalle()
	CALL muestra_contadores_det(0)
	CALL lee_parametros() RETURNING expr_sql
	IF int_flag = 2 THEN
		CONTINUE WHILE
	END IF
	IF int_flag THEN
		EXIT WHILE
	END IF
	IF rm_caj.j10_codigo_caja IS NOT NULL THEN
		LET expr_sql2 ='  AND j10_codigo_caja = ',rm_caj.j10_codigo_caja
	ELSE
		INITIALIZE expr_sql2 TO NULL
	END IF
	FOR i = 1 TO 10
		LET rm_orden[i] = '' 
	END FOR
	LET rm_orden[1]  = 'ASC'
	LET vm_columna_1 = 1
	LET vm_columna_2 = 2
	LET col          = 1
	WHILE TRUE
		LET query = 'SELECT DATE(j10_fecha_pro), j10_nomcli, ',
			'j10_tipo_destino, j10_num_destino, j11_codigo_pago, ',
			'j11_moneda, j11_valor, j10_compania, j10_localidad, ',
			'j10_tipo_fuente, j10_num_fuente, j10_codcli ',
			'FROM cajt010, OUTER cajt011 ',
			'WHERE j10_compania    = ', vg_codcia,
			'  AND j10_localidad   = ', vg_codloc,
			'  AND j10_estado IN ("P") ',
			'  AND ', expr_sql CLIPPED, 
			expr_sql2 CLIPPED, 
			'  AND DATE(j10_fecha_pro) BETWEEN "', vm_fecha_ini,
			'" AND "', vm_fecha_fin, '"',
			'  AND j10_compania    = j11_compania ',
			'  AND j10_localidad   = j11_localidad ',
			'  AND j10_tipo_fuente = j11_tipo_fuente ',
			'  AND j10_num_fuente  = j11_num_fuente ',
			" ORDER BY ", vm_columna_1, ' ', rm_orden[vm_columna_1],
			       	', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
		PREPARE deto FROM query
		DECLARE q_deto CURSOR FOR deto
		LET vm_num_det = 1
		FOREACH q_deto INTO rm_det[vm_num_det].*, rm_cajs[vm_num_det].*
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
				IF rm_det[i].j10_tipo_destino = 'EC' THEN
					CALL dialog.keysetlabel("F5", "")
				ELSE
					CALL dialog.keysetlabel("F5", 
						"Forma de Pago")
				END IF
				IF rm_det[i].j10_tipo_destino = 'FA' OR 
				   rm_det[i].j10_tipo_destino = 'PG' OR
				   rm_det[i].j10_tipo_destino = 'PA' OR
				   rm_det[i].j10_tipo_destino = 'EC' THEN
					CALL dialog.keysetlabel("F6",
						"Comprobante")
				ELSE
					CALL dialog.keysetlabel("F6","")
				END IF
				CALL contar_comprobantes(
						rm_cajs[i].j10_tipo_fuente,
						rm_cajs[i].j10_num_fuente, 
						rm_det[i].j10_tipo_destino,
						rm_det[i].j10_num_destino
					) RETURNING cuantos
							
				IF cuantos > 0 THEN
					CALL dialog.keysetlabel('F8', 
						'Contabilización')
				ELSE
					CALL dialog.keysetlabel('F8', '')
				END IF
			AFTER DISPLAY 
				CONTINUE DISPLAY
			ON KEY(INTERRUPT)
				LET int_flag = 1
				EXIT DISPLAY
			ON KEY(F5)
				CALL ver_forma_pago(i)
				LET int_flag = 0
			ON KEY(F6)
				CALL fl_ver_comprobantes_emitidos_caja(
					rm_cajs[i].j10_tipo_fuente, 
					rm_cajs[i].j10_num_fuente, 
				        rm_det[i].j10_tipo_destino, 
				        rm_det[i].j10_num_destino, 
				        rm_cajs[i].j10_codcli)
				LET int_flag = 0
			ON KEY(F7)
				CALL imprime_comprobante(
					rm_cajs[i].j10_tipo_fuente, 
					rm_cajs[i].j10_num_fuente) 
				LET int_flag = 0
			ON KEY(F8)
				CALL mostrar_comp_contable(
						rm_cajs[i].j10_tipo_fuente, 
						rm_cajs[i].j10_num_fuente, 
				        	rm_det[i].j10_tipo_destino, 
				        	rm_det[i].j10_num_destino 
					) RETURNING tipo_comp, num_comp
				IF tipo_comp IS NOT NULL AND cuantos = 1 THEN
					CALL contabilizacion(tipo_comp, 
							     num_comp)
				END IF
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
DEFINE r_caj		RECORD LIKE cajt002.*
DEFINE cod_aux		LIKE cajt002.j02_codigo_caja
DEFINE nom_aux		LIKE cajt002.j02_nombre_caja
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE
DEFINE expr_sql		VARCHAR(400)

OPTIONS INPUT NO WRAP
INITIALIZE cod_aux, expr_sql TO NULL
LET int_flag = 0
INPUT BY NAME rm_caj.j10_codigo_caja, vm_fecha_ini, vm_fecha_fin
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN NULL
	ON KEY(F2)
		IF infield(j10_codigo_caja) THEN
			CALL fl_ayuda_cajas(vg_codcia, vg_codloc)
				RETURNING cod_aux, nom_aux
			OPTIONS INPUT NO WRAP
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				LET rm_caj.j10_codigo_caja = cod_aux
				DISPLAY BY NAME rm_caj.j10_codigo_caja 
				DISPLAY nom_aux TO j02_nombre_caja
			END IF 
		END IF
	BEFORE FIELD vm_fecha_ini
		LET fecha_ini = vm_fecha_ini
	BEFORE FIELD vm_fecha_fin
		LET fecha_fin = vm_fecha_fin
	AFTER FIELD j10_codigo_caja
		IF rm_caj.j10_codigo_caja IS NOT NULL THEN
			CALL fl_lee_codigo_caja_caja(vg_codcia, vg_codloc,
							rm_caj.j10_codigo_caja)
                        	RETURNING r_caj.*
			IF r_caj.j02_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Código de Caja no existe.','exclamation')
				NEXT FIELD j10_codigo_caja
			END IF
			DISPLAY BY NAME r_caj.j02_nombre_caja
		ELSE
			CLEAR j02_nombre_caja
		END IF
	AFTER FIELD vm_fecha_ini 
		IF vm_fecha_ini IS NOT NULL THEN
			IF vm_fecha_ini > TODAY THEN
				CALL fgl_winmessage(vg_producto,'La fecha de inicio no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD vm_fecha_ini
			END IF
		ELSE
			LET vm_fecha_ini = fecha_ini
			DISPLAY BY NAME vm_fecha_ini
		END IF
	AFTER FIELD vm_fecha_fin 
		IF vm_fecha_fin IS NOT NULL THEN
			IF vm_fecha_fin > TODAY THEN
				CALL fgl_winmessage(vg_producto,'La fecha de término no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD vm_fecha_fin
			END IF
		ELSE
			LET vm_fecha_fin = fecha_fin
			DISPLAY BY NAME vm_fecha_fin
		END IF
	AFTER INPUT
		IF vm_fecha_ini > vm_fecha_fin THEN
			CALL fgl_winmessage(vg_producto,'Fecha inicial debe ser menor a fecha final.','exclamation')
			NEXT FIELD vm_fecha_ini
		END IF
END INPUT
OPTIONS INPUT WRAP
CONSTRUCT BY NAME expr_sql ON j10_nomcli, j10_tipo_destino, j11_codigo_pago,
	j11_moneda, j11_valor
	ON KEY(INTERRUPT)
		LET int_flag = 2
		RETURN NULL
END CONSTRUCT
RETURN expr_sql

END FUNCTION



FUNCTION borrar_cabecera()

CLEAR vm_fecha_ini, vm_fecha_fin, j10_codigo_caja, j02_nombre_caja
INITIALIZE rm_caj.*, vm_fecha_ini, vm_fecha_fin TO NULL

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i  		SMALLINT

CALL muestra_contadores_det(0)
LET vm_scr_lin = fgl_scr_size('rm_det')
FOR i = 1 TO vm_scr_lin
        INITIALIZE rm_det[i].*, rm_cajs[i].* TO NULL
        CLEAR rm_det[i].*
END FOR

END FUNCTION



FUNCTION muestra_contadores_det(cor)
DEFINE cor	           SMALLINT

DISPLAY "" AT 21, 2
DISPLAY cor, " de ", vm_num_det AT 21, 6

END FUNCTION


 
FUNCTION mostrar_cabecera_forma()

DISPLAY 'Fecha'              TO tit_col1
DISPLAY 'Cliente/Referencia' TO tit_col2
DISPLAY 'DO'                 TO tit_col3
DISPLAY 'Número'             TO tit_col4
DISPLAY 'TP'                 TO tit_col5
DISPLAY 'Mo'                 TO tit_col6
DISPLAY 'Valor'              TO tit_col7

END FUNCTION



FUNCTION ver_forma_pago(i)
DEFINE i		SMALLINT
DEFINE prog		CHAR(10)

IF rm_det[i].j10_tipo_destino <> 'OI' THEN
	LET prog = 'cajp203'
ELSE
	LET prog = 'cajp206'
END IF
LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'CAJA',
	vg_separador, 'fuentes', vg_separador, '; fglrun ', prog, ' ', vg_base,
	' ', vg_modulo, ' ', rm_cajs[i].j10_compania, ' ',
	rm_cajs[i].j10_localidad, ' ', '"', rm_cajs[i].j10_tipo_fuente, '"',
	' ', rm_cajs[i].j10_num_fuente
RUN vm_nuevoprog

END FUNCTION



FUNCTION imprime_comprobante(tipo_fuente, num_fuente)

DEFINE comando                  VARCHAR(250)

DEFINE tipo_fuente		LIKE cajt010.j10_tipo_fuente
DEFINE num_fuente		LIKE cajt010.j10_num_fuente

DEFINE r_r23            RECORD LIKE rept023.*   -- Preventa Repuestos
DEFINE r_v26            RECORD LIKE veht026.*   -- Preventa Vehiculos
DEFINE r_t23            RECORD LIKE talt023.*   -- Orden de Trabajo
DEFINE r_z24            RECORD LIKE cxct024.*   -- Solicitud Cobro Clientes

INITIALIZE comando TO NULL
CASE tipo_fuente
        WHEN 'PV'
                CALL fgl_winmessage(vg_producto,                
			'Opcion no habilitada.',
			'exclamation')

        WHEN 'PR'
                CALL fl_lee_preventa_rep(vg_codcia, vg_codloc,
                        num_fuente) RETURNING r_r23.*

                LET comando = 'cd ..', vg_separador, '..', vg_separador,
                              'REPUESTOS', vg_separador, 'fuentes',
                              vg_separador, '; fglrun repp410_', vg_codloc USING '&', ' ',
							  vg_base, ' ',
                              'RE', vg_codcia, ' ', vg_codloc,
                              ' ', r_r23.r23_num_tran
	display comando								  
        WHEN 'OT'
                CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc,
                        num_fuente) RETURNING r_t23.*

                LET comando = 'cd ..', vg_separador, '..', vg_separador,
                              'TALLER', vg_separador, 'fuentes',
                              vg_separador, '; fglrun talp403 ', vg_base, ' ',
                              'TA', vg_codcia, ' ', vg_codloc,
                              ' ', r_t23.t23_num_factura
        WHEN 'SC'
                CALL fl_lee_solicitud_cobro_cxc(vg_codcia, vg_codloc,
                                                num_fuente)
                                                RETURNING r_z24.*
                IF r_z24.z24_tipo = 'A' THEN
                        LET comando = 'cd ..', vg_separador, '..', vg_separador,
                                      'CAJA', vg_separador, 'fuentes',
                                      vg_separador, '; fglrun cajp401 ',
                                      vg_base, ' ', 'CG', vg_codcia, ' ',
                                      vg_codloc, ' ', r_z24.z24_numero_sol
                ELSE
                        LET comando = 'cd ..', vg_separador, '..', vg_separador,
                                      'CAJA', vg_separador, 'fuentes',
                                      vg_separador, '; fglrun cajp400_', vg_codloc USING '&', ' ',
                                      vg_base, ' ', 'CG', vg_codcia, ' ',
                                      vg_codloc, ' ', r_z24.z24_numero_sol
                END IF
        WHEN 'OI'
        	LET comando = 'cd ..', vg_separador, '..', vg_separador,
                              'CAJA', vg_separador, 'fuentes',
                              vg_separador, '; fglrun cajp403 ',
                              vg_base, ' ', 'CG', vg_codcia, ' ',
                              vg_codloc, ' ', num_fuente             
        WHEN 'EC'
        	LET comando = 'cd ..', vg_separador, '..', vg_separador,
                              'CAJA', vg_separador, 'fuentes',
                              vg_separador, '; fglrun cajp404 ',
                              vg_base, ' ', 'CG', vg_codcia, ' ',
                              vg_codloc, ' ', num_fuente             
END CASE

IF comando IS NOT NULL THEN
        RUN comando
END IF

END FUNCTION



FUNCTION contabilizacion(tipo_comp, num_comp)

DEFINE comando 		VARCHAR(255)

DEFINE tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE num_comp		LIKE ctbt012.b12_num_comp

LET comando = 'cd ..', vg_separador, '..', vg_separador,
	      'CONTABILIDAD', vg_separador, 'fuentes', 
	      vg_separador, '; fglrun ctbp201 ', vg_base, ' ',
	      'CB ', vg_codcia, ' ', vg_codloc, ' ' , tipo_comp, ' ', num_comp

RUN comando

END FUNCTION



FUNCTION contar_comprobantes(tipo_fuente, num_fuente, tipo_destino, num_destino)

DEFINE tipo_fuente	LIKE cajt010.j10_tipo_fuente
DEFINE num_fuente	LIKE cajt010.j10_num_fuente
DEFINE tipo_destino	LIKE cajt010.j10_tipo_destino
DEFINE num_destino	LIKE cajt010.j10_num_destino
DEFINE cuantos		SMALLINT

DEFINE r_j10		RECORD LIKE cajt010.*

LET cuantos = 0
CASE tipo_fuente
	WHEN 'PV'
		SELECT COUNT(*) INTO cuantos FROM veht050 
			WHERE v50_compania  = vg_codcia
			  AND v50_localidad = vg_codloc
			  AND v50_cod_tran  = tipo_destino
			  AND v50_num_tran  = num_destino
	WHEN 'PR'
		SELECT COUNT(*) INTO cuantos FROM rept040 
			WHERE r40_compania  = vg_codcia
			  AND r40_localidad = vg_codloc
			  AND r40_cod_tran  = tipo_destino
			  AND r40_num_tran  = num_destino
	WHEN 'SC'
		CALL fl_lee_cabecera_caja(vg_codcia, vg_codloc, tipo_fuente, 
					  num_fuente) RETURNING r_j10.*
		SELECT COUNT(*) INTO cuantos FROM cxct040 
			WHERE z40_compania  = vg_codcia
			  AND z40_localidad = vg_codloc
			  AND z40_codcli    = r_j10.j10_codcli 
			  AND z40_tipo_doc  = tipo_destino
			  AND z40_num_doc   = num_destino
	WHEN 'OT'
		SELECT COUNT(*) INTO cuantos FROM talt050
			WHERE t50_compania  = vg_codcia
			  AND t50_localidad = vg_codloc
			  AND t50_orden     = num_fuente
			  AND t50_factura   = num_destino
	WHEN 'EC'
		SELECT COUNT(*) INTO cuantos FROM cajt010
			WHERE j10_compania  = vg_codcia
			  AND j10_localidad = vg_codloc
			  AND j10_tipo_destino = tipo_destino
			  AND j10_num_destino  = num_destino 
	WHEN 'OI'
		SELECT COUNT(*) INTO cuantos FROM cajt010
			WHERE j10_compania  = vg_codcia
			  AND j10_localidad = vg_codloc
			  AND j10_tipo_destino = tipo_destino
			  AND j10_num_destino  = num_destino 
END CASE 

RETURN cuantos

END FUNCTION



FUNCTION mostrar_comp_contable(tipo_fuente, num_fuente, tipo_destino, 
			       num_destino)

DEFINE tipo_fuente	LIKE cajt010.j10_tipo_fuente
DEFINE num_fuente	LIKE cajt010.j10_num_fuente
DEFINE tipo_destino	LIKE cajt010.j10_tipo_destino
DEFINE num_destino	LIKE cajt010.j10_num_destino
DEFINE r_j10		RECORD LIKE cajt010.*

DEFINE query 		VARCHAR(500)

DEFINE i       	 	SMALLINT

DEFINE max_rows		SMALLINT
DEFINE r_det ARRAY[50] OF RECORD
	tipo_comp		LIKE ctbt012.b12_tipo_comp,
	num_comp		LIKE ctbt012.b12_num_comp,
	fecha			LIKE ctbt012.b12_fec_proceso,
	subtipo			LIKE ctbt004.b04_nombre
END RECORD

LET max_rows = 50

INITIALIZE query TO NULL
CASE tipo_fuente
	WHEN 'PR'
		LET query = 'SELECT r40_tipo_comp, r40_num_comp, ',
				'   b12_fec_proceso, b04_nombre ',
			    '	FROM rept040, ctbt012, OUTER ctbt004 ',
			    '	WHERE r40_compania  = ', vg_codcia,
			    '     AND r40_localidad = ', vg_codloc, 
			    '     AND r40_cod_tran  = "', tipo_destino, '"',
			    '     AND r40_num_tran  = "', num_destino, '"',
		  	    '     AND b12_compania  = r40_compania ',
		            '     AND b12_tipo_comp = r40_tipo_comp ',
		            '     AND b12_num_comp  = r40_num_comp ',
		            '     AND b04_compania  = b12_compania ',
		            '     AND b04_subtipo   = b12_subtipo '
	WHEN 'PV'
		LET query = 'SELECT v50_tipo_comp, v50_num_comp, ',
				'   b12_fec_proceso, b04_nombre ',
			    '	FROM veht050, ctbt012, OUTER ctbt004 ',
			    '	WHERE v50_compania  = ', vg_codcia,
			    '     AND v50_localidad = ', vg_codloc, 
			    '     AND v50_cod_tran  = "', tipo_destino, '"',
			    '     AND v50_num_tran  = "', num_destino, '"',
		  	    '     AND b12_compania  = v50_compania ',
		            '     AND b12_tipo_comp = v50_tipo_comp ',
		            '     AND b12_num_comp  = v50_num_comp ',
		            '     AND b04_compania  = b12_compania ',
		            '     AND b04_subtipo   = b12_subtipo '
	WHEN 'OT'
		LET query = 'SELECT t50_tipo_comp, t50_num_comp, ',
				'   b12_fec_proceso, b04_nombre ',
			    '	FROM talt050, ctbt012, OUTER ctbt004 ',
			    '	WHERE t50_compania  = ', vg_codcia,
			    '     AND t50_localidad = ', vg_codloc, 
			    '     AND t50_orden     = "', num_fuente, '"',
			    '     AND t50_factura   = "', num_destino, '"',
		  	    '     AND b12_compania  = t50_compania ',
		            '     AND b12_tipo_comp = t50_tipo_comp ',
		            '     AND b12_num_comp  = t50_num_comp ',
		            '     AND b04_compania  = b12_compania ',
		            '     AND b04_subtipo   = b12_subtipo '
	WHEN 'SC'
		CALL fl_lee_cabecera_caja(vg_codcia, vg_codloc, tipo_fuente, 
					  num_fuente) RETURNING r_j10.*
		LET query = 'SELECT z40_tipo_comp, z40_num_comp, ',
				'   b12_fec_proceso, b04_nombre ',
			    '	FROM cxct040, ctbt012, OUTER ctbt004 ',
			    '	WHERE z40_compania  = ', vg_codcia,
			    '	  AND z40_localidad = ', vg_codloc,
			    '     AND z40_codcli    = ', r_j10.j10_codcli,
			    '     AND z40_tipo_doc  = "', tipo_destino, '"',
			    '     AND z40_num_doc   = "', num_destino,  '"',
		  	    '     AND b12_compania  = z40_compania ',
		            '     AND b12_tipo_comp = z40_tipo_comp ',
		            '     AND b12_num_comp  = z40_num_comp ',
		            '     AND b04_compania  = b12_compania ',
		            '     AND b04_subtipo   = b12_subtipo '
	WHEN 'EC'
		LET query = 'SELECT j10_tip_contable, j10_num_contable, ',
				'   b12_fec_proceso, b04_nombre ',
			    '	FROM cajt010, ctbt012, OUTER ctbt004 ',
			    ' 	WHERE j10_compania  = ', vg_codcia,
			    '	  AND j10_localidad = ', vg_codloc,
			    '	  AND j10_tipo_destino = "', tipo_destino, '"',
			    '     AND j10_num_destino  = "', num_destino,  '"',
		  	    '     AND b12_compania  = j10_compania ',
		            '     AND b12_tipo_comp = j10_tip_contable ',
		            '     AND b12_num_comp  = j10_num_contable ',
		            '     AND b04_compania  = b12_compania ',
		            '     AND b04_subtipo   = b12_subtipo '
	WHEN 'OI'
		LET query = 'SELECT j10_tip_contable, j10_num_contable, ',
				'   b12_fec_proceso, b04_nombre ',
			    '	FROM cajt010, ctbt012, OUTER ctbt004 ',
			    ' 	WHERE j10_compania  = ', vg_codcia,
			    '	  AND j10_localidad = ', vg_codloc,
			    '	  AND j10_tipo_destino = "', tipo_destino, '"',
			    '     AND j10_num_destino  = "', num_destino,  '"',
		  	    '     AND b12_compania  = j10_compania ',
		            '     AND b12_tipo_comp = j10_tip_contable ',
		            '     AND b12_num_comp  = j10_num_contable ',
		            '     AND b04_compania  = b12_compania ',
		            '     AND b04_subtipo   = b12_subtipo '
END CASE

PREPARE stmnt1 FROM query
DECLARE q_cursor1 CURSOR FOR stmnt1 

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

OPEN WINDOW w_300_2 AT 10,10 WITH 09 ROWS, 60 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST - 2)
OPEN FORM f_300_2 FROM '../forms/cajf300_2'
DISPLAY FORM f_300_2

DISPLAY 'Comprobante' TO bt_tipo_comp
DISPLAY 'Fecha'       TO bt_fecha    
DISPLAY 'Subtipo'     TO bt_subtipo  

IF i = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	CLOSE WINDOW w_300_2
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

CLOSE WINDOW w_300_2
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
	WHEN 'PV'
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
 			      'VEHICULOS', vg_separador, 'fuentes', 
			      vg_separador, '; fglrun vehp304 ', vg_base, ' ',
			      'VE', vg_codcia, ' ', vg_codloc,
			      ' ', tipo_destino, ' ', num_destino
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
	WHEN 'EC'
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
 			      'CAJA', vg_separador, 'fuentes', 
			      vg_separador, '; fglrun cajp207 ', vg_base, ' ',
			      'CG ', vg_codcia, ' ', vg_codloc, ' ',  
			      tipo_fuente, num_fuente
END CASE
IF comando IS NOT NULL THEN
	RUN comando
END IF

END FUNCTION
