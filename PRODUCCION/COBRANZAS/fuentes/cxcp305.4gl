--------------------------------------------------------------------------------
-- Titulo           : cxcp305.4gl - Consulta Estado Cuenta Clientes
-- Elaboracion      : 17-oct-2001
-- Autor            : YEC
-- Formato Ejecucion: fglrun cxcp305 base módulo compañía localidad
--		      [cliente] [moneda] [[flag_saldo] [tipo_saldo] [valor]
--					  [dias_min] [dias_max]]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_max_doc       SMALLINT
DEFINE vm_tot_doc	DECIMAL(14,2)
DEFINE vm_num_doc	SMALLINT
DEFINE rm_cligen	RECORD LIKE cxct001.*
DEFINE rm_clicia	RECORD LIKE cxct002.*
DEFINE rm_mon		RECORD LIKE gent013.*
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE rm_par  		RECORD
				localidad	LIKE gent002.g02_localidad,
				codcli		LIKE cxct001.z01_codcli,
				nomcli		LIKE cxct001.z01_nomcli,
				moneda		LIKE gent013.g13_moneda,
				tit_mon		LIKE gent013.g13_nombre,
			        flag_saldo	CHAR(1),
				tipo_saldo	CHAR(1),
				valor		DECIMAL(12,2),
				dias_min	SMALLINT,
				dias_max	SMALLINT
			END RECORD
DEFINE rm_rows		ARRAY[4000] OF LIKE cxct001.z01_codcli
DEFINE rm_dcli 		ARRAY[10000] OF RECORD
				tit_loc		LIKE gent002.g02_localidad,
				tit_area	CHAR(15),
				z20_tipo_doc	LIKE cxct020.z20_tipo_doc,
				num_doc		CHAR(18),
				z20_fecha_vcto	LIKE cxct020.z20_fecha_vcto,
				tit_estado	CHAR(15),
				dias		SMALLINT,
				saldo		DECIMAL(14,2)
			END RECORD
DEFINE rm_rowid 	ARRAY[10000] OF INTEGER
DEFINE vm_muestra_df	SMALLINT



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxcp305.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 6 AND num_args() <> 9 AND num_args() <> 11
THEN
	-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
IF arg_val(4) <> '0' THEN
	LET vg_codloc  = arg_val(4)
END IF
LET vg_proceso = 'cxcp305'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()
DEFINE r		RECORD LIKE gent013.*
DEFINE ru		RECORD LIKE gent005.*
DEFINE localidad	LIKE gent002.g02_localidad
DEFINE comando		VARCHAR(100)
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE run_prog		CHAR(10)
DEFINE auxiliar 	SMALLINT

LET vm_max_rows	= 4000
LET vm_max_doc  = 10000
CREATE TEMP TABLE temp_doc
	(tit_loc		SMALLINT,
	 tit_area		CHAR(15),
	 z20_tipo_doc		CHAR(2),
	 num_doc		CHAR(18),
	 z20_fecha_vcto		DATE,
	 tit_estado		CHAR(10),
	 dias			SMALLINT,
	 saldo			DECIMAL(14,2),
	 val_ori		DECIMAL(14,2),
         z20_areaneg		SMALLINT,
	 z20_num_doc		CHAR(15),
	 z20_dividendo		SMALLINT,
	 z20_codcli		INTEGER,
	 z20_cod_tran		CHAR(2),
	 z20_num_tran		DECIMAL(15,0))
INITIALIZE rm_par.* TO NULL
LET rm_par.flag_saldo = 'S'
LET rm_par.tipo_saldo = 'T'
LET rm_par.valor      = 0.01
LET rm_par.moneda     = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_par.moneda) RETURNING rm_mon.*
LET rm_par.tit_mon = rm_mon.g13_nombre
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
OPEN WINDOW wf AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_cli FROM "../forms/cxcf305_2"
ELSE
	OPEN FORM f_cli FROM "../forms/cxcf305_2c"
END IF
DISPLAY FORM f_cli
LET vm_num_rows    = 0
LET vm_row_current = 0
LET vm_muestra_df  = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_titulos_columnas()
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Detalle'
		HIDE OPTION 'Movimientos'
		HIDE OPTION 'Doc. a Favor'
		HIDE OPTION 'Datos'
		HIDE OPTION 'Ch. Protestados'
		HIDE OPTION 'Ch. Postfechados'
		HIDE OPTION 'Imprimir'
		CALL fl_lee_usuario(vg_usuario) RETURNING ru.*
		IF ru.g05_tipo <> 'AG' THEN	
			HIDE OPTION 'Recalcular Saldos'
		END IF
		IF num_args() <> 4 THEN
			HIDE OPTION 'Consultar'
			IF arg_val(4) <> '0' THEN
				LET rm_par.localidad = vg_codloc
			END IF
			LET rm_par.codcli = arg_val(5)
			LET rm_par.moneda = arg_val(6)
			IF num_args() <> 6 THEN
				LET rm_par.flag_saldo = arg_val(7)
				LET rm_par.tipo_saldo = arg_val(8)
				LET rm_par.valor      = arg_val(9)
				LET rm_par.dias_min   = NULL
				LET rm_par.dias_max   = NULL
				IF num_args() <> 9 THEN
					LET rm_par.dias_min = arg_val(10)
					LET rm_par.dias_max = arg_val(11)
				END IF
				IF rm_par.tipo_saldo = 'V' THEN
					IF rm_par.dias_min > 0 THEN
						LET rm_par.dias_min =
							rm_par.dias_min * (-1)
					END IF
					IF rm_par.dias_max > 0 THEN
						LET rm_par.dias_max =
							rm_par.dias_max * (-1)
					END IF
					LET auxiliar        = rm_par.dias_min
					LET rm_par.dias_min = rm_par.dias_max
					LET rm_par.dias_max = auxiliar
				END IF
			END IF
			LET vm_row_current          = 1
			LET rm_rows[vm_row_current] = rm_par.codcli
			CALL control_consulta()
                        SHOW OPTION 'Movimientos'
			SHOW OPTION 'Doc. a Favor'
			SHOW OPTION 'Datos'
			SHOW OPTION 'Ch. Protestados'
			SHOW OPTION 'Ch. Postfechados'
			SHOW OPTION 'Imprimir'
			IF vm_num_doc > 0 THEN
                      		SHOW OPTION 'Detalle'
                	END IF
		END IF
	COMMAND KEY('C') 'Consultar'
	#COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		IF num_args() <> 4 THEN
			CONTINUE MENU
		END IF
		CALL control_consulta()
		CALL muestra_titulos_columnas()
		IF vm_num_rows <= 1 THEN
                	SHOW OPTION 'Movimientos'
			SHOW OPTION 'Doc. a Favor'
			SHOW OPTION 'Ch. Protestados'
			SHOW OPTION 'Ch. Postfechados'
			SHOW OPTION 'Datos'
			SHOW OPTION 'Imprimir'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
                		HIDE OPTION 'Movimientos'
				HIDE OPTION 'Doc. a Favor'
				HIDE OPTION 'Ch. Protestados'
				HIDE OPTION 'Ch. Postfechados'
				HIDE OPTION 'Datos'
				HIDE OPTION 'Imprimir'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
                	SHOW OPTION 'Movimientos'
			SHOW OPTION 'Doc. a Favor'
			SHOW OPTION 'Ch. Protestados'
			SHOW OPTION 'Ch. Postfechados'
			SHOW OPTION 'Datos'
			SHOW OPTION 'Imprimir'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
		IF vm_num_doc > 0 THEN
                	SHOW OPTION 'Detalle'
                ELSE
                	HIDE OPTION 'Detalle'
                END IF
		IF vm_muestra_df THEN
			IF vm_num_rows > 0 THEN
				CALL mostrar_documentos_favor(vg_codcia,
				rm_par.localidad, rm_rows[vm_row_current],
				rm_par.moneda)
			END IF
		END IF
	#COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro. '
	COMMAND KEY('A') 'Avanzar'
		CALL muestra_siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_num_doc > 0 THEN
                        SHOW OPTION 'Detalle'
                ELSE
                        HIDE OPTION 'Detalle'
                END IF
	#COMMAND KEY('R') 'Retroceder'  'Ver anterior registro. '
	COMMAND KEY('R') 'Retroceder'
		CALL muestra_anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_num_doc > 0 THEN
                        SHOW OPTION 'Detalle'
                ELSE
                        HIDE OPTION 'Detalle'
                END IF
	COMMAND KEY('D') 'Detalle' 'Ir al detalle de documentos.'
		IF vm_num_doc > 0 THEN
			CALL ubicarse_en_detalle()
		END IF
	COMMAND KEY('M') 'Movimientos' 'Ver detalle de pagos.'
		IF vm_num_rows > 0 THEN
			CALL mostrar_movimientos_cliente(vg_codcia,
				rm_par.localidad, rm_rows[vm_row_current],
				rm_par.moneda)
		END IF
	COMMAND KEY('F') 'Doc. a Favor'
		IF vm_num_rows > 0 THEN
			CALL mostrar_documentos_favor(vg_codcia,
				rm_par.localidad, rm_rows[vm_row_current],
				rm_par.moneda)
		END IF
	COMMAND KEY('T') 'Datos'
		LET localidad = rm_par.localidad
		IF rm_par.localidad IS NULL THEN
			LET localidad = 0
		END IF
		IF vm_row_current > 0 THEN
			LET run_prog = 'fglrun '
			IF vg_gui = 0 THEN
				LET run_prog = 'fglgo '
			END IF
			LET comando = run_prog, 'cxcp101 ', vg_base, ' ',
				vg_modulo, ' ', vg_codcia, ' ', localidad, ' ',
				rm_rows[vm_row_current]
			RUN comando 
		END IF
	COMMAND KEY('P') 'Ch. Protestados'
		IF vm_row_current > 0 THEN
			CALL mostrar_cheque_protestados(vg_codcia,
				rm_par.localidad, rm_rows[vm_row_current],
				rm_par.moneda)
		END IF
	COMMAND KEY('X') 'Ch. Postfechados'
		IF vm_row_current > 0 THEN
			CALL mostrar_cheque_postfechados(vg_codcia,
				rm_par.localidad, rm_rows[vm_row_current],
				rm_par.moneda)
		END IF
	COMMAND KEY('Z') 'Recalcular Saldos' 
		IF vm_row_current > 0 THEN
			CALL proceso_recalcula_saldos(rm_par.localidad,
							rm_rows[vm_row_current])
		END IF
	#COMMAND KEY('S') 'Salir' 'Salir del programa. '
	COMMAND KEY('I') 'Imprimir'
		CALL imprimir(rm_par.localidad, rm_rows[vm_row_current],
				rm_par.moneda)
	COMMAND KEY('S') 'Salir'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_consulta()
DEFINE query		CHAR(1700)
DEFINE expr_valor	VARCHAR(250)
DEFINE expr_loc		VARCHAR(50)
DEFINE orden		VARCHAR(20)
DEFINE mon_aux		LIKE gent013.g13_moneda
DEFINE tit_mon		LIKE gent013.g13_nombre
DEFINE codcli		LIKE cxct001.z01_codcli
DEFINE nomcli		LIKE cxct001.z01_nomcli
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE i		SMALLINT
DEFINE ini_col	 	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

LET int_flag = 0
IF num_args() = 4 THEN
	LET ini_col  = 5
	LET num_rows = 13
	LET num_cols = 73
	IF vg_gui = 0 THEN
		LET ini_col  = 4
		LET num_rows = 13
		LET num_cols = 74
	END IF
	OPEN WINDOW w_par AT 9, ini_col WITH num_rows ROWS, num_cols COLUMNS
		ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER)
	IF vg_gui = 1 THEN
		OPEN FORM f_305_1 FROM "../forms/cxcf305_1"
	ELSE
		OPEN FORM f_305_1 FROM "../forms/cxcf305_1c"
	END IF
	DISPLAY FORM f_305_1
	IF vg_gui = 0 THEN
		CALL muestra_flagsaldo(rm_par.flag_saldo)
		CALL muestra_tiposaldo(rm_par.tipo_saldo)
	END IF
	IF rm_par.localidad IS NOT NULL THEN
		CALL fl_lee_localidad(vg_codcia, rm_par.localidad)
			RETURNING r_g02.*
		DISPLAY r_g02.g02_nombre TO tit_localidad
	ELSE
		CLEAR tit_localidad
	END IF
	LET int_flag = 0
	INPUT BY NAME rm_par.* WITHOUT DEFAULTS
        	ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
		ON KEY(F2)
			IF INFIELD(localidad) THEN
				CALL fl_ayuda_localidad(vg_codcia)
					RETURNING r_g02.g02_localidad,
						  r_g02.g02_nombre
				IF r_g02.g02_localidad IS NOT NULL THEN
					LET rm_par.localidad =
							r_g02.g02_localidad
					DISPLAY BY NAME rm_par.localidad
					DISPLAY r_g02.g02_nombre TO
						tit_localidad
				END IF
			END IF
			IF INFIELD(codcli) THEN
				IF rm_par.localidad IS NULL THEN
					CALL fl_ayuda_cliente_general()
						RETURNING codcli, nomcli
				ELSE
					CALL fl_ayuda_cliente_localidad(
							vg_codcia,
							rm_par.localidad)
						RETURNING codcli, nomcli
				END IF
				IF codcli IS NOT NULL THEN
					LET rm_par.codcli = codcli
					LET rm_par.nomcli = nomcli
					DISPLAY BY NAME rm_par.codcli,
							rm_par.nomcli
				END IF
			END IF
			IF INFIELD(moneda) THEN
                        	CALL fl_ayuda_monedas()
					RETURNING mon_aux, tit_mon, i
                        	IF mon_aux IS NOT NULL THEN
					LET rm_par.tit_mon = tit_mon
                                	DISPLAY BY NAME rm_par.tit_mon
                        	END IF
                	END IF
                	LET int_flag = 0
		BEFORE INPUT
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		AFTER FIELD localidad
			IF rm_par.localidad IS NOT NULL THEN
				CALL fl_lee_localidad(vg_codcia,
							rm_par.localidad)
					RETURNING r_g02.*
				IF r_g02.g02_compania IS NULL THEN
					CALL fl_mostrar_mensaje('Localidad no existe.','exclamation')
					NEXT FIELD localidad
				END IF
				IF r_g02.g02_estado = 'B' THEN
					CALL fl_mensaje_estado_bloqueado()
					NEXT FIELD localidad
				END IF
				DISPLAY r_g02.g02_nombre TO tit_localidad
			ELSE
				CLEAR tit_localidad
			END IF
		AFTER FIELD codcli
			IF rm_par.codcli IS NOT NULL THEN
				CALL fl_lee_cliente_general(rm_par.codcli)
					RETURNING rm_cligen.*
				IF rm_cligen.z01_codcli IS NULL THEN
					--CALL fgl_winmessage(vg_producto, 'Cliente no existe.', 'exclamation')
					CALL fl_mostrar_mensaje('Cliente no existe.', 'exclamation')
					NEXT FIELD codcli
				END IF
				{--
				IF rm_cligen.z01_estado = 'B' THEN
					CALL fl_mensaje_estado_bloqueado()
					NEXT FIELD codcli
				END IF
				--}
				LET rm_par.nomcli = rm_cligen.z01_nomcli
				DISPLAY BY NAME rm_par.nomcli
				IF rm_par.localidad IS NULL THEN
					CONTINUE INPUT
				END IF
				CALL fl_lee_cliente_localidad(vg_codcia,
							rm_par.localidad,
							rm_cligen.z01_codcli)
					RETURNING rm_clicia.*
				IF rm_clicia.z02_compania IS NULL THEN
					--CALL fgl_winmessage(vg_producto,'Cliente no está activado para la compañía.', 'exclamation')
					CALL fl_mostrar_mensaje('Cliente no está activado para la compañía.', 'exclamation')
					NEXT FIELD codcli
				END IF
			ELSE
				LET rm_par.nomcli = NULL
				DISPLAY BY NAME rm_par.nomcli
			END IF
		AFTER FIELD moneda
			IF rm_par.moneda IS NOT NULL THEN
				CALL fl_lee_moneda(rm_par.moneda)
					RETURNING rm_mon.*
				IF rm_mon.g13_moneda IS NULL THEN
					--CALL fgl_winmessage(vg_producto,'Moneda no existe', 'exclamation')
					CALL fl_mostrar_mensaje('Moneda no existe', 'exclamation')
					NEXT FIELD moneda
				END IF
				IF rm_mon.g13_estado = 'B' THEN
					CALL fl_mensaje_estado_bloqueado()
					NEXT FIELD moneda
				END IF
				LET rm_par.tit_mon = rm_mon.g13_nombre
				DISPLAY BY NAME rm_par.tit_mon
			ELSE
				LET rm_par.tit_mon = NULL
				DISPLAY BY NAME rm_par.tit_mon
			END IF
		AFTER FIELD valor
			IF rm_par.valor < 0 OR rm_par.valor IS NULL THEN
				LET rm_par.valor = 0.01
				DISPLAY BY NAME rm_par.valor
			END IF
		AFTER FIELD flag_saldo
			IF vg_gui = 0 THEN
				IF rm_par.flag_saldo IS NOT NULL THEN
				       CALL muestra_flagsaldo(rm_par.flag_saldo)
				ELSE
					CLEAR tit_flag_saldo
				END IF
			END IF
		AFTER FIELD tipo_saldo
			IF vg_gui = 0 THEN
				IF rm_par.tipo_saldo IS NOT NULL THEN
				       CALL muestra_tiposaldo(rm_par.tipo_saldo)
				ELSE
					CLEAR tit_tipo_saldo
				END IF
			END IF
		AFTER INPUT
			IF rm_par.tipo_saldo = 'P' OR rm_par.tipo_saldo = 'V'
			THEN
				IF rm_par.dias_min IS NOT NULL THEN
					IF rm_par.dias_max IS NOT NULL THEN
						IF rm_par.dias_min > rm_par.dias_max
						THEN
							CALL fl_mostrar_mensaje('El No. de días mínimo no puede ser mayor que los días máximo.', 'exclamation')
							NEXT FIELD dias_min
						END IF
					ELSE
						LET rm_par.dias_min = NULL
					END IF
				ELSE
					LET rm_par.dias_max = NULL
				END IF
			ELSE
				LET rm_par.dias_min = NULL
				LET rm_par.dias_max = NULL
			END IF
	END INPUT
	CLOSE WINDOW w_par
	IF int_flag THEN
		LET int_flag = 0
		IF vm_row_current > 0 THEN
			CALL mostrar_registro(rm_rows[vm_row_current])
		ELSE
			CLEAR FORM
		END IF
		RETURN
	END IF
END IF
ERROR 'Generando consulta . . . espere por favor.' ATTRIBUTE(NORMAL)
LET expr_loc = ' '
IF rm_par.localidad IS NOT NULL THEN
	LET expr_loc = '   AND z30_localidad = ' || rm_par.localidad
END IF
LET query = 'SELECT z30_codcli, ' ||
		'SUM(z30_saldo_favor), ' ||
       		'SUM(z30_saldo_xvenc), ' ||
       		'SUM(z30_saldo_venc),  ' ||
       		'SUM(z30_saldo_xvenc + z30_saldo_venc) ' ||
  		'FROM cxct030 ' ||
		'WHERE z30_compania  = ' || vg_codcia ||
		expr_loc CLIPPED ||
		' AND  z30_moneda    = "' || rm_par.moneda || '"' 
IF rm_par.codcli IS NOT NULL THEN
	LET query = query CLIPPED || 
			' AND z30_codcli = ' || rm_par.codcli
END IF
--IF rm_par.codcli IS NULL THEN
	CASE rm_par.tipo_saldo 
		WHEN 'A'
			LET expr_valor = 'SUM(z30_saldo_favor) >= ' || rm_par.valor
			LET orden      = '2 DESC'
		WHEN 'P'
			LET expr_valor = 'SUM(z30_saldo_xvenc) >= ' || rm_par.valor
			LET orden      = '3 DESC'
		WHEN 'V'
			LET expr_valor = 'SUM(z30_saldo_venc)  >= ' || rm_par.valor
			LET orden      = '4 DESC'
		WHEN 'T'
			LET expr_valor = 'SUM(z30_saldo_favor) + ',
					'SUM(z30_saldo_xvenc) + ',
				 	'SUM(z30_saldo_venc) >= ', rm_par.valor
			LET orden      = '5 DESC'
	END CASE
	LET query = query CLIPPED || 
			' GROUP BY 1 ' ||
			' HAVING ' || expr_valor CLIPPED ||
			' ORDER BY ' || orden
{-- OJO COMENTADO POR NPC 12/11/2004
ELSE
	LET query = query CLIPPED || 
			' AND z30_codcli = ' || rm_par.codcli ||
			' GROUP BY 1 '
END IF
--}
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	LET int_flag = 0
	CALL fl_mensaje_consulta_sin_registros()
	MESSAGE '' 
	ERROR ' ' ATTRIBUTE(NORMAL)
	CLEAR FORM
	LET vm_row_current = 0
	LET vm_num_doc     = 0
	IF num_args() <> 4 THEN
		EXIT PROGRAM
	END IF
ELSE  
	LET vm_row_current = 1
	CALL mostrar_registro(rm_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION ubicarse_en_detalle()
DEFINE i		SMALLINT
DEFINE query		CHAR(300)
DEFINE r_an		RECORD LIKE gent003.*
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE areaneg		LIKE cxct020.z20_areaneg
DEFINE num_doc		LIKE cxct020.z20_num_doc
DEFINE dividendo	LIKE cxct020.z20_dividendo
DEFINE cod_tran		LIKE cxct020.z20_cod_tran 
DEFINE num_tran		LIKE cxct020.z20_num_tran 
DEFINE codcli		LIKE cxct020.z20_codcli 
DEFINE num_sri		LIKE rept038.r38_num_sri
DEFINE val_original	DECIMAL(14,2)
DEFINE comando		VARCHAR(150)
DEFINE run_prog		CHAR(10)
DEFINE mens		VARCHAR(50)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
WHILE TRUE
	CALL set_count(vm_num_doc)
	DISPLAY ARRAY rm_dcli TO rm_dcli.*
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#SELECT z20_areaneg, z20_num_doc, z20_dividendo,
			       --#z20_cod_tran, z20_num_tran,z20_codcli, val_ori
				--#INTO areaneg, num_doc, dividendo, cod_tran, 
				     --#num_tran, codcli, val_original
				--#FROM temp_doc 
				--#WHERE ROWID = rm_rowid[i]
			--#CALL obtener_num_sri(cod_tran, num_tran,
						--#rm_dcli[i].tit_loc, areaneg)
				--#RETURNING num_sri
			--#MESSAGE i, ' de ', vm_num_doc, 
				--#'    Valor Original: ', 
			        --#val_original USING '#,###,###,##&.##',
				--#'    No. SRI ', num_sri
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
		ON KEY(INTERRUPT)
			EXIT DISPLAY
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_1() 
		ON KEY(RETURN)
			LET i = arr_curr()
			SELECT z20_areaneg, z20_num_doc, z20_dividendo,
				z20_cod_tran, z20_num_tran,z20_codcli, val_ori
				INTO areaneg, num_doc, dividendo, cod_tran,
					num_tran, codcli, val_original
				FROM temp_doc 
				WHERE ROWID = rm_rowid[i]
			CALL obtener_num_sri(cod_tran, num_tran,
						rm_dcli[i].tit_loc, areaneg)
				RETURNING num_sri
			MESSAGE i, ' de ', vm_num_doc, '    Valor Original: ',
				val_original USING '#,###,###,##&.##',
				'    No. SRI ', num_sri
		ON KEY(F5)
			LET i = arr_curr()
			SELECT tit_loc, z20_areaneg, z20_num_doc,
				z20_dividendo,
		       		z20_cod_tran, z20_num_tran, z20_codcli,
				val_ori
				INTO codloc, areaneg, num_doc,dividendo,
					cod_tran, num_tran, codcli,
					val_original
				FROM temp_doc 
				WHERE ROWID = rm_rowid[i]
			IF cod_tran IS NOT NULL THEN
				CALL fl_lee_area_negocio(vg_codcia, areaneg)
					RETURNING r_an.*
				IF r_an.g03_modulo = 'RE' THEN
					CALL fl_ver_transaccion_rep(vg_codcia,
								    codloc,
								    cod_tran,
								    num_tran)
				END IF
				IF r_an.g03_modulo = 'TA' THEN
  	      			  LET comando = 'cd ' || '..' || vg_separador ||
					      '..' || vg_separador ||
					      'TALLER' || 
					      vg_separador || 'fuentes' ||
					      vg_separador || run_prog ||
					      'talp204 ' || vg_base || 
					      ' TA ' || 
					      vg_codcia || ' ' || 
					      codloc || ' ' ||
				       	      num_tran || ' F'
					RUN comando
				END IF
				IF r_an.g03_modulo = 'VE' THEN
					CALL fl_ver_transaccion_veh(vg_codcia,
								    codloc,
								    cod_tran,
								    num_tran)
				END IF
			END IF	
		ON KEY(F6)
			LET i = arr_curr()
			SELECT tit_loc, z20_codcli, z20_num_doc, z20_dividendo
				INTO codloc, codcli, num_doc, dividendo
				FROM temp_doc 
				WHERE ROWID = rm_rowid[i]
			CALL muestra_movimientos_documento_cxc(vg_codcia, 
				codloc, areaneg, codcli,
				rm_dcli[i].z20_tipo_doc, num_doc, dividendo)
		ON KEY(F7)
			LET i = arr_curr()
			LET run_prog = 'fglrun '
			IF vg_gui = 0 THEN
				LET run_prog = 'fglgo '
			END IF
			SELECT tit_loc INTO codloc FROM temp_doc
				WHERE ROWID = rm_rowid[i]
			LET comando = run_prog, 'cxcp200 ' || vg_base || ' ' ||
			      vg_modulo || ' ' ||
			      vg_codcia || ' ' || 
			      codloc    || ' ' ||
			      codcli    || ' ' ||
			      rm_dcli[i].z20_tipo_doc || ' ' ||
			      num_doc   || ' ' ||
			      dividendo
			RUN comando
		ON KEY(F8)
			CALL imprimir(rm_par.localidad, rm_rows[vm_row_current],
					rm_par.moneda)
		ON KEY(F15)
			LET i = 1
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET i = 2
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET i = 3
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET i = 4
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F19)
			LET i = 5
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F20)
			LET i = 6
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F21)
			LET i = 7
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F22)
			LET i = 8
			LET int_flag = 2
			EXIT DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF i <> vm_columna_1 THEN
		LET vm_columna_2           = vm_columna_1 
		LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
		LET vm_columna_1           = i 
	END IF
	IF rm_orden[vm_columna_1] = 'ASC' THEN
		LET rm_orden[vm_columna_1] = 'DESC'
	ELSE
		LET rm_orden[vm_columna_1] = 'ASC'
	END IF
	LET query = 'SELECT tit_loc, tit_area, z20_tipo_doc, num_doc, ',
			'z20_fecha_vcto, tit_estado, dias, saldo, ROWID ',
			'FROM temp_doc ',
			'ORDER BY ',
			vm_columna_1, ' ', rm_orden[vm_columna_1], ',', 
			vm_columna_2, ' ', rm_orden[vm_columna_2] 
	PREPARE dcol FROM query
	DECLARE q_dcol CURSOR FOR dcol
	LET i = 1
	FOREACH q_dcol INTO rm_dcli[i].*, rm_rowid[i]
		LET i = i + 1
	END FOREACH
END WHILE
LET mens = vm_num_doc CLIPPED || ' documento(s)'
MESSAGE mens 
                                                                                
END FUNCTION



FUNCTION muestra_titulos_columnas()

--#DISPLAY 'LC'            TO tit_col1
--#DISPLAY 'Area Neg.'     TO tit_col2
--#DISPLAY 'TP'            TO tit_col3
--#DISPLAY 'No. Documento' TO tit_col4
--#DISPLAY 'Fecha Vcto.'   TO tit_col5
--#DISPLAY 'Estado'        TO tit_col6
--#DISPLAY 'Días'          TO tit_col7
--#DISPLAY 'S a l d o'     TO tit_col8

END FUNCTION



FUNCTION muestra_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL mostrar_registro(rm_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION muestra_anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL mostrar_registro(rm_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current	SMALLINT
DEFINE num_rows		SMALLINT
                                                                                
IF vg_gui = 1 THEN
	DISPLAY "" AT 1,1
	DISPLAY row_current, " de ", num_rows AT 1, 68
END IF
                                                                                
END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE num_registro	LIKE talt022.t22_numpre
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_tal_aux	RECORD LIKE talt020.*
DEFINE tot_favor 	DECIMAL(14,2)
DEFINE tot_xven  	DECIMAL(14,2)
DEFINE tot_vcdo  	DECIMAL(14,2)
DEFINE tot_saldo 	DECIMAL(14,2)
DEFINE tot_postfec 	DECIMAL(14,2)
DEFINE query		CHAR(1200)
DEFINE expr_loc		VARCHAR(50)

ERROR 'Cargando documentos del cliente . . . espere por favor.' ATTRIBUTE(NORMAL)
IF vm_num_rows > 0 THEN
	SELECT * INTO rm_cligen.* FROM cxct001 
                WHERE z01_codcli = num_registro
	IF STATUS = NOTFOUND THEN
		--CALL fgl_winmessage (vg_producto,'No existe cliente: ' || num_registro,'exclamation')
		CALL fl_mostrar_mensaje('No existe cliente: ' || num_registro, 'exclamation')
		RETURN
	END IF
	DISPLAY BY NAME	rm_cligen.z01_codcli, rm_cligen.z01_nomcli, 
			rm_par.tit_mon, rm_cligen.z01_direccion1, 
			rm_cligen.z01_telefono1, rm_cligen.z01_telefono2, 
			rm_cligen.z01_fax1, rm_par.localidad
	IF rm_cligen.z01_estado = 'A' THEN
		DISPLAY 'ACTIVO' TO tit_estcli
	END IF
	IF rm_cligen.z01_estado = 'B' THEN
		DISPLAY 'BLOQUEADO' TO tit_estcli
	END IF
	IF rm_par.localidad IS NOT NULL THEN
		CALL fl_lee_localidad(vg_codcia, rm_par.localidad)
			RETURNING r_g02.*
		DISPLAY r_g02.g02_nombre TO tit_localidad
	ELSE
		CLEAR tit_localidad
	END IF
	LET tot_favor = 0
	LET expr_loc  = ' '
	IF rm_par.localidad IS NOT NULL THEN
		LET expr_loc = '   AND z30_localidad = ', rm_par.localidad
	END IF
	LET query = 'SELECT SUM(z30_saldo_favor), SUM(z30_saldo_xvenc), ',
			' SUM(z30_saldo_venc) ',
			' FROM cxct030 ',
			' WHERE z30_compania  = ', vg_codcia,
			expr_loc CLIPPED,
			'   AND z30_codcli    = ', rm_cligen.z01_codcli,
			'   AND z30_moneda    = "', rm_par.moneda, '"'
	PREPARE suma FROM query
	DECLARE q_suma CURSOR FOR suma
	OPEN q_suma
	FETCH q_suma INTO tot_favor, tot_xven, tot_vcdo
	IF STATUS = NOTFOUND THEN
		LET tot_favor = 0	
		LET tot_xven  = 0	
		LET tot_vcdo  = 0	
		LET tot_saldo = 0	
	END IF
	CLOSE q_suma
	FREE q_suma
	LET tot_saldo = (tot_xven + tot_vcdo) - tot_favor
	LET expr_loc = ' '
	IF rm_par.localidad IS NOT NULL THEN
		LET expr_loc = '   AND z26_localidad = ', rm_par.localidad
	END IF
	LET query = 'SELECT SUM(z26_valor) FROM cxct026 ',
			' WHERE z26_compania  = ', vg_codcia,
			expr_loc CLIPPED,
			'   AND z26_codcli    = ', rm_cligen.z01_codcli,
			'   AND z26_estado    = "A"'
	PREPARE suma2 FROM query
	DECLARE q_suma2 CURSOR FOR suma2
	OPEN q_suma2
	FETCH q_suma2 INTO tot_postfec
	IF STATUS = NOTFOUND THEN
		LET tot_postfec = 0
	END IF
	CLOSE q_suma2
	FREE q_suma2
	DISPLAY BY NAME tot_favor, tot_xven, tot_vcdo, tot_saldo, tot_postfec
	IF tot_favor > 0 THEN
		IF tot_xven + tot_vcdo = 0 THEN
			LET vm_muestra_df = 1
		ELSE
			LET vm_muestra_df = 0
		END IF
	END IF
	CALL carga_muestra_detalle(num_registro)
END IF
ERROR ' ' ATTRIBUTE(NORMAL)

END FUNCTION



FUNCTION carga_muestra_detalle(codcli)
DEFINE codcli           LIKE cxct001.z01_codcli
DEFINE r_doc		RECORD LIKE cxct020.*
DEFINE tit_area		CHAR(15)
DEFINE tit_estado	CHAR(10)
DEFINE i, dias          SMALLINT
DEFINE valor_aux, aux	DECIMAL(13,2)
DEFINE numdoc   	CHAR(18)
DEFINE mens		VARCHAR(50)
DEFINE query		CHAR(1200)
DEFINE expr_loc		VARCHAR(50)

DELETE FROM temp_doc 
FOR i = 1 TO fgl_scr_size('rm_dcli')
        INITIALIZE rm_dcli[i].* TO NULL
        CLEAR rm_dcli[i].*
END FOR
LET valor_aux = 0
IF rm_par.flag_saldo = 'S' THEN
	LET valor_aux = 0.01
END IF
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET rm_orden[4]  = 'ASC'
LET vm_columna_1 = 4
LET vm_columna_2 = 1
LET expr_loc     = ' '
IF rm_par.localidad IS NOT NULL THEN
	LET expr_loc = '   AND z20_localidad = ', rm_par.localidad
END IF
LET query = 'SELECT cxct020.*, g03_abreviacion ',
		' FROM cxct020, gent003 ',
        	' WHERE z20_compania  = ', vg_codcia,
		expr_loc CLIPPED,
	  	'   AND z20_codcli    = ', codcli,
	  	'   AND z20_saldo_cap + z20_saldo_int >= ', valor_aux,
	  	'   AND z20_compania  = g03_compania ',
	  	'   AND z20_areaneg   = g03_areaneg ',
		' ORDER BY z20_fecha_vcto'
PREPARE cxc20 FROM query
DECLARE q_doc CURSOR FOR cxc20
LET int_flag   = 0
LET vm_num_doc = 1
FOREACH q_doc INTO r_doc.*, tit_area
	LET numdoc     = r_doc.z20_num_doc CLIPPED, '-', 
			 r_doc.z20_dividendo USING '&&'
	LET valor_aux  = r_doc.z20_saldo_cap + r_doc.z20_saldo_int
	LET dias       = NULL
	LET tit_estado = 'Cancelado'
	IF valor_aux <> 0 THEN
		LET dias = r_doc.z20_fecha_vcto - TODAY
		IF dias < 0 THEN
			LET tit_estado = 'Vencido'
		ELSE
			LET tit_estado = 'Por Vencer'
		END IF
	END IF
	IF num_args() <> 6 THEN
		CASE rm_par.tipo_saldo
			WHEN 'A'
				IF tit_estado <> 'Cancelado' THEN
					CONTINUE FOREACH
				END IF
			WHEN 'P'
				IF tit_estado <> 'Por Vencer' THEN
					CONTINUE FOREACH
				END IF
			WHEN 'V'
				IF tit_estado <> 'Vencido' THEN
					CONTINUE FOREACH
				END IF
		END CASE
		IF rm_par.dias_min IS NOT NULL THEN
			IF rm_par.tipo_saldo <> 'A' AND rm_par.tipo_saldo <> 'T'
			THEN
				IF NOT (dias >= rm_par.dias_min AND
					dias <= rm_par.dias_max)
				THEN
					CONTINUE FOREACH
				END IF
			END IF
		END IF
	END IF
	LET aux = r_doc.z20_valor_cap + r_doc.z20_valor_int
	INSERT INTO temp_doc VALUES (r_doc.z20_localidad, tit_area,
		r_doc.z20_tipo_doc, numdoc, r_doc.z20_fecha_vcto, tit_estado,
		dias, valor_aux, aux, r_doc.z20_areaneg, r_doc.z20_num_doc,
		r_doc.z20_dividendo, r_doc.z20_codcli, r_doc.z20_cod_tran,
		r_doc.z20_num_tran)
	LET rm_rowid[vm_num_doc]                = SQLCA.SQLERRD[6]
	LET rm_dcli[vm_num_doc].tit_loc		= r_doc.z20_localidad
	LET rm_dcli[vm_num_doc].tit_area	= tit_area
	LET rm_dcli[vm_num_doc].z20_tipo_doc	= r_doc.z20_tipo_doc
	LET rm_dcli[vm_num_doc].num_doc		= numdoc
	LET rm_dcli[vm_num_doc].z20_fecha_vcto	= r_doc.z20_fecha_vcto
	LET rm_dcli[vm_num_doc].tit_estado	= tit_estado
	LET rm_dcli[vm_num_doc].dias		= dias
	LET rm_dcli[vm_num_doc].saldo		= valor_aux
	LET vm_num_doc                          = vm_num_doc + 1
        IF vm_num_doc > vm_max_doc THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_doc = vm_num_doc - 1
IF vm_num_doc > 0 THEN
        FOR i = 1 TO fgl_scr_size('rm_dcli')
                DISPLAY rm_dcli[i].* TO rm_dcli[i].*
        END FOR
END IF
LET mens = vm_num_doc CLIPPED || ' documento(s)'
MESSAGE mens

END FUNCTION



FUNCTION muestra_movimientos_documento_cxc(codcia, codloc, areaneg, codcli,
						tipo_doc, num_doc, dividendo)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE areaneg		LIKE gent003.g03_areaneg
DEFINE codcli		LIKE cxct001.z01_codcli
DEFINE tipo_doc		LIKE cxct020.z20_tipo_doc
DEFINE num_doc		LIKE cxct020.z20_num_doc
DEFINE dividendo	LIKE cxct020.z20_dividendo
DEFINE r_cli		RECORD LIKE cxct001.*
DEFINE max_rows, i	SMALLINT
DEFINE r_orden 		ARRAY[10] OF CHAR(4)
DEFINE columna_1	SMALLINT
DEFINE columna_2	SMALLINT
DEFINE num_rows		SMALLINT
DEFINE tot_pago		DECIMAL(14,2)
DEFINE query		CHAR(1200)
DEFINE comando		VARCHAR(200)
DEFINE r_loc		ARRAY[100] OF RECORD
				loc		LIKE gent002.g02_localidad,
				tipo		LIKE cxct023.z23_tipo_favor
			END RECORD
DEFINE r_pdoc		ARRAY[100] OF RECORD
				z23_tipo_trn	LIKE cxct023.z23_tipo_trn,
				z23_num_trn	LIKE cxct023.z23_num_trn,
				z22_fecha_emi	LIKE cxct022.z22_fecha_emi,
				z22_referencia	LIKE cxct022.z22_referencia,
				val_pago	DECIMAL(14,2)
			END RECORD
DEFINE num_rows2 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE run_prog, prog	VARCHAR(10)
DEFINE expr_loc		VARCHAR(50)

LET max_rows  = 100
LET num_rows2 = 15
LET num_cols  = 76
IF vg_gui = 0 THEN
	LET num_rows2 = 14
	LET num_cols  = 77
END IF
OPEN WINDOW w_mdoc AT 8, 3 WITH num_rows2 ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_305_3 FROM "../forms/cxcf305_3"
ELSE
	OPEN FORM f_305_3 FROM "../forms/cxcf305_3c"
END IF
DISPLAY FORM f_305_3
--#DISPLAY 'Tp'                  TO tit_col1 
--#DISPLAY 'Número'              TO tit_col2 
--#DISPLAY 'Fec.Pago'            TO tit_col3
--#DISPLAY 'R e f e r e n c i a' TO tit_col4 
--#DISPLAY 'V a l o r'           TO tit_col5
CALL fl_lee_cliente_general(codcli) RETURNING r_cli.*
IF r_cli.z01_codcli IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'No existe cliente: ' || codcli,'exclamation')
	CALL fl_mostrar_mensaje('No existe cliente: ' || codcli, 'exclamation')
	CLOSE WINDOW w_mdoc
	RETURN
END IF
DISPLAY BY NAME r_cli.z01_nomcli
DISPLAY tipo_doc, num_doc, dividendo TO z23_tipo_doc, z23_num_doc, z23_div_doc
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET r_orden[3]  = 'ASC'
LET columna_1 = 3
LET columna_2 = 1
LET expr_loc = ' '
IF codloc IS NOT NULL THEN
	LET expr_loc = '   AND z23_localidad = ', codloc
END IF
WHILE TRUE
	LET query = 'SELECT z23_tipo_trn, z23_num_trn, z22_fecha_emi, ',
			'   z22_referencia, z23_valor_cap + z23_valor_int, ',
			'   z23_localidad, z23_tipo_favor ',
	        	' FROM cxct023, cxct022 ',
			' WHERE z23_compania  = ? ', 
			expr_loc CLIPPED,
		        '   AND z23_codcli    = ? AND ',
		      	      ' z23_tipo_doc  = ? AND ',
		              ' z23_num_doc   = ? AND ',
		      	      ' z23_div_doc   = ? AND ',
		      	      ' z23_compania  = z22_compania  AND ',
		      	      ' z23_localidad = z22_localidad AND ',
		      	      ' z23_codcli    = z22_codcli    AND ',
		      	      ' z23_tipo_trn  = z22_tipo_trn  AND ',
		      	      ' z23_num_trn   = z22_num_trn ',
			' ORDER BY ', columna_1, ' ',
			      r_orden[columna_1], ', ',
			      columna_2, ' ', r_orden[columna_2]
	PREPARE dpgc FROM query
	DECLARE q_dpgc CURSOR FOR dpgc
	LET i = 1
	LET tot_pago = 0
	OPEN q_dpgc USING codcia, codcli, tipo_doc, num_doc, dividendo
	WHILE TRUE
		FETCH q_dpgc INTO r_pdoc[i].*, r_loc[i].*
		IF status = NOTFOUND THEN
			EXIT WHILE
		END IF
		LET tot_pago = tot_pago + r_pdoc[i].val_pago 
		LET i = i + 1
		IF i > max_rows THEN
			EXIT WHILE
		END IF
	END WHILE
	CLOSE q_dpgc
	FREE q_dpgc
	LET num_rows = i - 1
	IF num_rows = 0 THEN
		--CALL fgl_winmessage(vg_producto,'Documento no tiene movimientos', 'exclamation')
		CALL fl_mostrar_mensaje('Documento no tiene movimientos.','exclamation')
		CLOSE WINDOW w_mdoc
		RETURN
	END IF
	LET int_flag = 0
	CALL set_count(num_rows)
	DISPLAY BY NAME tot_pago
	DISPLAY ARRAY r_pdoc TO r_pdoc.*
		ON KEY(INTERRUPT)
			EXIT DISPLAY
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_2() 
		ON KEY(F5)
			LET i = arr_curr()
			CALL fl_muestra_forma_pago_caja(codcia, r_loc[i].loc,
							areaneg, codcli,
							r_pdoc[i].z23_tipo_trn,
							r_pdoc[i].z23_num_trn) 
		ON KEY(F6)
			LET i = arr_curr()
			LET run_prog = 'fglrun '
			IF vg_gui = 0 THEN
				LET run_prog = 'fglgo '
			END IF
			LET prog = 'cxcp202 '
			IF r_loc[i].tipo IS NOT NULL THEN
				LET prog = 'cxcp203 '
			END IF
			LET comando = run_prog || prog CLIPPED || ' ' ||
				vg_base || ' ' || vg_modulo || ' ' ||
			      codcia || ' ' || 
			      r_loc[i].loc || ' ' ||
			      codcli   || ' ' ||
			      r_pdoc[i].z23_tipo_trn || ' ' ||
			      r_pdoc[i].z23_num_trn
			RUN comando
		ON KEY(F15)
			LET i = 1
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET i = 2
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET i = 3
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET i = 4
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F19)
			LET i = 5
			LET int_flag = 2
			EXIT DISPLAY
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#MESSAGE i, ' de ', num_rows
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF i <> columna_1 THEN
		LET columna_2           = columna_1 
		LET r_orden[columna_2] = r_orden[columna_1]
		LET columna_1 = i 
	END IF
	IF r_orden[columna_1] = 'ASC' THEN
		LET r_orden[columna_1] = 'DESC'
	ELSE
		LET r_orden[columna_1] = 'ASC'
	END IF
END WHILE
CLOSE WINDOW w_mdoc

END FUNCTION



FUNCTION muestra_movimientos_de_doc_favor(codcia, codloc, codcli, tipo_doc, 
					   num_doc)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE codcli		LIKE cxct001.z01_codcli
DEFINE tipo_doc		LIKE cxct021.z21_tipo_doc
DEFINE num_doc		LIKE cxct021.z21_num_doc
DEFINE r_cli		RECORD LIKE cxct001.*
DEFINE max_rows, i	SMALLINT
DEFINE r_orden ARRAY[10] OF CHAR(4)
DEFINE columna_1	SMALLINT
DEFINE columna_2	SMALLINT
DEFINE num_rows		SMALLINT
DEFINE tot_pago		DECIMAL(14,2)
DEFINE query		CHAR(1200)
DEFINE comando		VARCHAR(200)
DEFINE r_loc		ARRAY[100] OF RECORD
				loc		LIKE gent002.g02_localidad,
				tipo		LIKE cxct023.z23_tipo_favor
			END RECORD
DEFINE r_pdoc		ARRAY[100] OF RECORD
				z23_tipo_trn	LIKE cxct023.z23_tipo_trn,
				z23_num_trn	LIKE cxct023.z23_num_trn,
				z22_fecha_emi	LIKE cxct022.z22_fecha_emi,
				z22_referencia	LIKE cxct022.z22_referencia,
				val_pago	DECIMAL(14,2)
			END RECORD
DEFINE num_rows2 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE run_prog, prog	VARCHAR(10)
DEFINE expr_loc		VARCHAR(50)

LET max_rows  = 100
LET num_rows2 = 16
LET num_cols  = 76
IF vg_gui = 0 THEN
	LET num_rows2 = 15
	LET num_cols  = 76
END IF
OPEN WINDOW w_ftrn AT 8, 3 WITH num_rows2 ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_305_5 FROM "../forms/cxcf305_5"
ELSE
	OPEN FORM f_305_5 FROM "../forms/cxcf305_5c"
END IF
DISPLAY FORM f_305_5
--#DISPLAY 'Tp'                  TO tit_col1 
--#DISPLAY 'Número'              TO tit_col2 
--#DISPLAY 'Fecha'               TO tit_col3
--#DISPLAY 'R e f e r e n c i a' TO tit_col4 
--#DISPLAY 'V a l o r'           TO tit_col5
CALL fl_lee_cliente_general(codcli) RETURNING r_cli.*
IF r_cli.z01_codcli IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'No existe cliente: ' || codcli,'exclamation')
	CALL fl_mostrar_mensaje('No existe cliente: ' || codcli,'exclamation')
	CLOSE WINDOW w_ftrn
	RETURN
END IF
DISPLAY BY NAME r_cli.z01_nomcli
DISPLAY tipo_doc, num_doc TO z23_tipo_favor, z23_doc_favor
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET r_orden[3]  = 'ASC'
LET columna_1 = 3
LET columna_2 = 1
LET expr_loc = ' '
IF codloc IS NOT NULL THEN
	LET expr_loc = '   AND z23_localidad = ', codloc
END IF
WHILE TRUE
	LET query = 'SELECT z23_tipo_trn, z23_num_trn, z22_fecha_emi, ',
			'   z22_referencia, z23_valor_cap + z23_valor_int, ',
			'   z23_localidad, z23_tipo_favor ',
	        	' FROM cxct023, cxct022 ',
			' WHERE z23_compania  = ? ',
			expr_loc CLIPPED,
	      	       '    AND z23_codcli    = ? AND ',
		      	      ' z23_tipo_favor= ? AND ',
		              ' z23_doc_favor = ? AND ',
		      	      ' z23_compania  = z22_compania  AND ',
		      	      ' z23_localidad = z22_localidad AND ',
		      	      ' z23_codcli    = z22_codcli    AND ',
		      	      ' z23_tipo_trn  = z22_tipo_trn  AND ',
		      	      ' z23_num_trn   = z22_num_trn ',
			' ORDER BY ', columna_1, ' ',
			      r_orden[columna_1], ', ',
			      columna_2, ' ', r_orden[columna_2]
	PREPARE dtf FROM query
	DECLARE q_dtf CURSOR FOR dtf
	LET i = 1
	LET tot_pago = 0
	OPEN q_dtf USING codcia, codcli, tipo_doc, num_doc
	WHILE TRUE
		FETCH q_dtf INTO r_pdoc[i].*, r_loc[i].*
		IF status = NOTFOUND THEN
			EXIT WHILE
		END IF
		LET tot_pago = tot_pago + r_pdoc[i].val_pago 
		LET i = i + 1
		IF i > max_rows THEN
			EXIT WHILE
		END IF
	END WHILE
	CLOSE q_dtf
	FREE q_dtf
	LET num_rows = i - 1
	IF num_rows = 0 THEN
		--CALL fgl_winmessage(vg_producto,'Documento no tiene movimientos', 'exclamation')
		CALL fl_mostrar_mensaje('Documento no tiene movimientos.','exclamation')
		CLOSE WINDOW w_ftrn
		RETURN
	END IF
	LET int_flag = 0
	CALL set_count(num_rows)
	DISPLAY BY NAME tot_pago
	DISPLAY ARRAY r_pdoc TO r_pdoc.*
		ON KEY(INTERRUPT)
			EXIT DISPLAY
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_3() 
		ON KEY(F5)
			LET i = arr_curr()
			LET run_prog = 'fglrun '
			IF vg_gui = 0 THEN
				LET run_prog = 'fglgo '
			END IF
			LET prog = 'cxcp202 '
			IF r_loc[i].tipo IS NOT NULL THEN
				LET prog = 'cxcp203 '
			END IF
			LET comando = run_prog || prog CLIPPED || ' ' ||
				vg_base || ' ' || vg_modulo || ' ' ||
			      codcia || ' ' || 
			      r_loc[i].loc || ' ' ||
			      codcli || ' ' ||
			      r_pdoc[i].z23_tipo_trn || ' ' ||
			      r_pdoc[i].z23_num_trn
			RUN comando
		ON KEY(F15)
			LET i = 1
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET i = 2
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET i = 3
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET i = 4
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F19)
			LET i = 5
			LET int_flag = 2
			EXIT DISPLAY
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#MESSAGE i, ' de ', num_rows
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF i <> columna_1 THEN
		LET columna_2           = columna_1 
		LET r_orden[columna_2] = r_orden[columna_1]
		LET columna_1 = i 
	END IF
	IF r_orden[columna_1] = 'ASC' THEN
		LET r_orden[columna_1] = 'DESC'
	ELSE
		LET r_orden[columna_1] = 'ASC'
	END IF
END WHILE
CLOSE WINDOW w_ftrn

END FUNCTION



FUNCTION mostrar_movimientos_cliente(codcia, codloc, codcli, moneda)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE codcli		LIKE cxct001.z01_codcli
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE areaneg		LIKE gent003.g03_areaneg
DEFINE r_cli		RECORD LIKE cxct001.*
DEFINE max_rows, i	SMALLINT
DEFINE r_orden		ARRAY[10] OF CHAR(4)
DEFINE columna_1	SMALLINT
DEFINE columna_2	SMALLINT
DEFINE num_rows		SMALLINT
DEFINE tot_pago		DECIMAL(14,2)
DEFINE query		CHAR(1200)
DEFINE dividendo	SMALLINT
DEFINE comando		VARCHAR(200)
DEFINE r_arn		ARRAY[800] OF LIKE gent003.g03_areaneg
DEFINE r_loc		ARRAY[800] OF RECORD
				loc		LIKE gent002.g02_localidad,
				tipo		LIKE cxct023.z23_tipo_favor
			END RECORD
DEFINE r_movc		ARRAY[800] OF RECORD
				z23_tipo_trn	LIKE cxct023.z23_tipo_trn,
				z23_num_trn	LIKE cxct023.z23_num_trn,
				z23_tipo_doc	LIKE cxct023.z23_tipo_doc,
				num_doc		CHAR(18),
				z22_fecha_elim	LIKE cxct022.z22_fecha_elim,
				z22_fecha_emi	LIKE cxct022.z22_fecha_emi,
				z22_moneda	LIKE cxct022.z22_moneda,
				val_pago	DECIMAL(14,2)
			END RECORD
DEFINE num_rows2 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE run_prog, prog	VARCHAR(10)
DEFINE expr_loc		VARCHAR(50)

LET max_rows  = 800
LET num_rows2 = 16
LET num_cols  = 78
IF vg_gui = 0 THEN
	LET num_rows2 = 14
	LET num_cols  = 76
END IF
OPEN WINDOW w_dmcli AT 8, 3 WITH num_rows2 ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_305_4 FROM "../forms/cxcf305_4"
ELSE
	OPEN FORM f_305_4 FROM "../forms/cxcf305_4c"
END IF
DISPLAY FORM f_305_4
--#DISPLAY 'Tp'                  TO tit_col1 
--#DISPLAY 'Número'              TO tit_col2 
--#DISPLAY 'Tp'                  TO tit_col3 
--#DISPLAY 'Documento'           TO tit_col4
--#DISPLAY 'Fec. Elim'           TO tit_col5 
--#DISPLAY 'Fec. Pago'           TO tit_col6 
--#DISPLAY 'Mo'                  TO tit_col7 
--#DISPLAY 'V a l o r'           TO tit_col8
CALL fl_lee_cliente_general(codcli) RETURNING r_cli.*
IF r_cli.z01_codcli IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'No existe cliente: ' || codcli,'exclamation')
	CALL fl_mostrar_mensaje('No existe cliente: ' || codcli,'exclamation')
	CLOSE WINDOW w_dmcli
	RETURN
END IF
DISPLAY BY NAME r_cli.z01_nomcli
FOR i = 1 TO 10
	LET r_orden[i] = '' 
END FOR
LET r_orden[6]  = 'ASC'
LET columna_1 = 6
LET columna_2 = 1
LET expr_loc = ' '
IF codloc IS NOT NULL THEN
	LET expr_loc = '   AND z23_localidad = ', codloc
END IF
WHILE TRUE
	LET query = 'SELECT z23_tipo_trn, z23_num_trn, z23_tipo_doc, ',
			' z23_num_doc, z22_fecha_elim, z22_fecha_emi, ',
			' z22_moneda, z23_valor_cap + z23_valor_int, ',
			' z23_div_doc, z22_areaneg, z23_localidad, ',
			' z23_tipo_favor ',
	        	' FROM cxct023, cxct022 ',
			' WHERE z23_compania  = ? ',
			expr_loc CLIPPED,
		      	'   AND z23_codcli    = ? AND ',
		      	      ' z23_compania  = z22_compania  AND ',
		      	      ' z23_localidad = z22_localidad AND ',
		      	      ' z23_codcli    = z22_codcli    AND ',
		      	      ' z23_tipo_trn  = z22_tipo_trn  AND ',
		      	      ' z23_num_trn   = z22_num_trn   AND ',
		      	      ' z22_moneda    = ? ',
			' ORDER BY ', columna_1, ' ',
			      r_orden[columna_1], ', ',
			      columna_2, ' ', r_orden[columna_2]
	PREPARE dmcli FROM query
	DECLARE q_dmcli CURSOR FOR dmcli
	LET i = 1
	LET tot_pago = 0
	OPEN q_dmcli USING codcia, codcli, moneda
	WHILE TRUE
		FETCH q_dmcli INTO r_movc[i].*, dividendo, r_arn[i], r_loc[i].*
		IF status = NOTFOUND THEN
			EXIT WHILE
		END IF
		LET r_movc[i].num_doc = r_movc[i].num_doc CLIPPED, 
				        '-', dividendo USING '&&'
		LET tot_pago = tot_pago + r_movc[i].val_pago 
		LET i = i + 1
		IF i > max_rows THEN
			EXIT WHILE
		END IF
	END WHILE
	CLOSE q_dmcli
	FREE q_dmcli
	LET num_rows = i - 1
	IF num_rows = 0 THEN
		--CALL fgl_winmessage(vg_producto,'Cliente no tiene movimientos', 'exclamation')
		CALL fl_mostrar_mensaje('Cliente no tiene movimientos.','exclamation')
		CLOSE WINDOW w_dmcli
		RETURN
	END IF
	LET int_flag = 0
	CALL set_count(num_rows)
	DISPLAY BY NAME tot_pago
	DISPLAY ARRAY r_movc TO r_movc.*
		ON KEY(INTERRUPT)
			EXIT DISPLAY
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_2() 
		ON KEY(F5)
			LET i = arr_curr()
			CALL fl_muestra_forma_pago_caja(codcia, r_loc[i].loc,
							r_arn[i], codcli,
							r_movc[i].z23_tipo_trn,
							r_movc[i].z23_num_trn) 
		ON KEY(F6)
			LET i = arr_curr()
			LET run_prog = 'fglrun '
			IF vg_gui = 0 THEN
				LET run_prog = 'fglgo '
			END IF
			LET prog = 'cxcp202 '
			IF r_loc[i].tipo IS NOT NULL THEN
				LET prog = 'cxcp203 '
			END IF
			LET comando = run_prog || prog CLIPPED || ' ' ||
				vg_base || ' ' || vg_modulo || ' ' ||
			      codcia || ' ' || 
			      r_loc[i].loc || ' ' ||
			      codcli || ' ' ||
			      r_movc[i].z23_tipo_trn || ' ' ||
			      r_movc[i].z23_num_trn
			RUN comando
		ON KEY(F15)
			LET i = 1
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET i = 2
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET i = 3
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET i = 4
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F19)
			LET i = 5
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F20)
			LET i = 6
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F21)
			LET i = 7
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F22)
			LET i = 8
			LET int_flag = 2
			EXIT DISPLAY
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#MESSAGE i, ' de ', num_rows
			--#IF r_movc[i].z23_tipo_trn <> 'PG' THEN
				--#CALL dialog.keysetlabel("F5","")
			--#ELSE
				--#CALL dialog.keysetlabel("F5","Pago Caja")
			--#END IF
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF i <> columna_1 THEN
		LET columna_2           = columna_1 
		LET r_orden[columna_2] = r_orden[columna_1]
		LET columna_1 = i 
	END IF
	IF r_orden[columna_1] = 'ASC' THEN
		LET r_orden[columna_1] = 'DESC'
	ELSE
		LET r_orden[columna_1] = 'ASC'
	END IF
END WHILE
CLOSE WINDOW w_dmcli

END FUNCTION



FUNCTION mostrar_documentos_favor(codcia, codloc, codcli, moneda)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE codcli		LIKE cxct001.z01_codcli
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE areaneg		LIKE gent003.g03_areaneg
DEFINE r_cli		RECORD LIKE cxct001.*
DEFINE max_rows, i	SMALLINT
DEFINE r_orden 		ARRAY[10] OF CHAR(4)
DEFINE columna_1	SMALLINT
DEFINE columna_2	SMALLINT
DEFINE num_rows		SMALLINT
DEFINE tot_valor	DECIMAL(14,2)
DEFINE tot_saldo	DECIMAL(14,2)
DEFINE query		CHAR(1200)
DEFINE dividendo	SMALLINT
DEFINE comando		VARCHAR(250)
DEFINE r_arn		ARRAY[500] OF LIKE gent003.g03_areaneg
DEFINE r_loc		ARRAY[500] OF LIKE gent002.g02_localidad
DEFINE r_dda		ARRAY[500] OF RECORD
				z21_localidad	LIKE cxct021.z21_localidad,
				z21_tipo_doc	LIKE cxct021.z21_tipo_doc,
				z21_num_doc	LIKE cxct021.z21_num_doc,
				z21_fecha_emi	LIKE cxct021.z21_fecha_emi,
				z21_valor	LIKE cxct021.z21_valor,
				z21_saldo	LIKE cxct021.z21_saldo
			END RECORD
DEFINE num_rows2 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE run_prog		CHAR(10)
DEFINE expr_loc		VARCHAR(50)

LET max_rows  = 500
LET num_rows2 = 15
LET num_cols  = 65
IF vg_gui = 0 THEN
	LET num_rows2 = 14
	LET num_cols  = 66
END IF
OPEN WINDOW w_dda AT 6, 08 WITH num_rows2 ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_305_7 FROM "../forms/cxcf305_7"
ELSE
	OPEN FORM f_305_7 FROM "../forms/cxcf305_7c"
END IF
DISPLAY FORM f_305_7
--#DISPLAY 'LC'                  TO tit_col1 
--#DISPLAY 'Tipo'                TO tit_col2 
--#DISPLAY 'Número'              TO tit_col3 
--#DISPLAY 'Fec. Pago'           TO tit_col4 
--#DISPLAY 'V a l o r'           TO tit_col5
--#DISPLAY 'S a l d o'           TO tit_col6
CALL fl_lee_cliente_general(codcli) RETURNING r_cli.*
IF r_cli.z01_codcli IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'No existe cliente: ' || codcli,'exclamation')
	CALL fl_mostrar_mensaje('No existe cliente: ' || codcli,'exclamation')
	CLOSE WINDOW w_dda
	RETURN
END IF
DISPLAY BY NAME r_cli.z01_nomcli
FOR i = 1 TO 10
	LET r_orden[i] = '' 
END FOR
LET r_orden[4] = 'ASC'
LET columna_1  = 4
LET columna_2  = 3
LET expr_loc   = ' '
IF codloc IS NOT NULL THEN
	LET expr_loc = '   AND z21_localidad = ', codloc
END IF
WHILE TRUE
	LET query = 'SELECT z21_localidad, z21_tipo_doc, z21_num_doc, ',
			' z21_fecha_emi, z21_valor, z21_saldo, z21_areaneg, ',
			' z21_localidad ',
	        	' FROM cxct021 ',
			' WHERE z21_compania  = ? ',
			expr_loc CLIPPED,
		      	'   AND z21_codcli    = ? AND ',
		      	      ' z21_moneda    = ? ',
			' ORDER BY ', columna_1, ' ',
			      r_orden[columna_1], ', ',
			      columna_2, ' ', r_orden[columna_2]
	PREPARE dda FROM query
	DECLARE q_dda CURSOR FOR dda
	LET i = 1
	LET tot_valor = 0
	LET tot_saldo = 0
	OPEN q_dda USING codcia, codcli, moneda
	WHILE TRUE
		FETCH q_dda INTO r_dda[i].*, r_arn[i], r_loc[i]
		IF status = NOTFOUND THEN
			EXIT WHILE
		END IF
		CALL fl_lee_moneda(moneda) RETURNING rm_mon.*
		DISPLAY rm_mon.g13_nombre TO tit_mon
		LET tot_valor = tot_valor + r_dda[i].z21_valor 
		LET tot_saldo = tot_saldo + r_dda[i].z21_saldo 
		LET i = i + 1
		IF i > max_rows THEN
			EXIT WHILE
		END IF
	END WHILE
	CLOSE q_dda
	FREE q_dda
	LET num_rows = i - 1
	IF num_rows = 0 THEN
		--CALL fgl_winmessage(vg_producto,'Cliente no tiene documentos a favor', 'exclamation')
		CALL fl_mostrar_mensaje('Cliente no tiene documentos a favor.','exclamation')
		CLOSE WINDOW w_dda
		RETURN
	END IF
	LET int_flag = 0
	CALL set_count(num_rows)
	DISPLAY BY NAME tot_valor, tot_saldo
	DISPLAY ARRAY r_dda TO r_dda.*
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#MESSAGE i, ' de ', num_rows
			--#IF r_dda[i].z21_tipo_doc <> 'PA' THEN
				--#CALL dialog.keysetlabel("F5","")
			--#ELSE
				--#CALL dialog.keysetlabel("F5","Pago Caja")
			--#END IF
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
		ON KEY(INTERRUPT)
			EXIT DISPLAY
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_4() 
		ON KEY(F5)
			LET i = arr_curr()
			CALL fl_muestra_forma_pago_caja(codcia, r_loc[i],
							r_arn[i], codcli,
							r_dda[i].z21_tipo_doc,
							r_dda[i].z21_num_doc) 
		ON KEY(F6)
			LET i = arr_curr()
			LET run_prog = 'fglrun '
			IF vg_gui = 0 THEN
				LET run_prog = 'fglgo '
			END IF
			LET comando = run_prog || 'cxcp201 ' ||
				vg_base || ' ' || vg_modulo || ' ' ||
			      codcia || ' ' || 
			      r_loc[i] || ' ' ||
			      codcli || ' ' ||
			      r_dda[i].z21_tipo_doc || ' ' ||
			      r_dda[i].z21_num_doc
			RUN comando
		ON KEY(F7)
			LET i = arr_curr()
			CALL muestra_movimientos_de_doc_favor(codcia,
				r_loc[i], codcli, r_dda[i].z21_tipo_doc,
				r_dda[i].z21_num_doc) 
		ON KEY(F15)
			LET i = 1
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET i = 2
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET i = 3
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET i = 4
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F19)
			LET i = 5
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F20)
			LET i = 6
			LET int_flag = 2
			EXIT DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF i <> columna_1 THEN
		LET columna_2           = columna_1 
		LET r_orden[columna_2] = r_orden[columna_1]
		LET columna_1 = i 
	END IF
	IF r_orden[columna_1] = 'ASC' THEN
		LET r_orden[columna_1] = 'DESC'
	ELSE
		LET r_orden[columna_1] = 'ASC'
	END IF
END WHILE
CLOSE WINDOW w_dda

END FUNCTION



FUNCTION mostrar_cheque_protestados(codcia, codloc, codcli, moneda)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE codcli		LIKE cxct001.z01_codcli
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE v_num_chpr	SMALLINT
DEFINE v_max_chpr	SMALLINT
DEFINE total		DECIMAL(12,2)
DEFINE i,j,col		SMALLINT
DEFINE query		CHAR(1200)
DEFINE expr_sql         CHAR(600)
DEFINE v_nuevoprog	CHAR(400)
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_cli		RECORD LIKE cxct001.*
DEFINE r_loc		ARRAY [100] OF LIKE gent002.g02_localidad
DEFINE r_chpr		ARRAY [100] OF RECORD
				j12_fecing	DATE,
				g08_nombre	LIKE gent008.g08_nombre,
				j12_num_cheque	LIKE cajt012.j12_num_cheque,
				j12_valor	LIKE cajt012.j12_valor
			END RECORD
DEFINE r_ch_pr		ARRAY [100] OF RECORD
				j12_banco	LIKE cajt012.j12_banco,
				j12_num_cta	LIKE cajt012.j12_num_cta,
				j12_num_cheque	LIKE cajt012.j12_num_cheque,
				j12_secuencia	LIKE cajt012.j12_secuencia
			END RECORD
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE run_prog		CHAR(10)
DEFINE expr_loc		VARCHAR(50)

LET v_max_chpr = 100
LET num_rows = 17
LET num_cols = 63
IF vg_gui = 0 THEN
	LET num_rows = 18
	LET num_cols = 64
END IF
OPEN WINDOW w_chpr AT 06, 15 WITH num_rows ROWS, num_cols COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST,
                   MENU LINE 0, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_305_8 FROM '../forms/cxcf305_8'
ELSE
	OPEN FORM f_305_8 FROM '../forms/cxcf305_8c'
END IF
DISPLAY FORM f_305_8
CALL mostrar_botones_chques()
CALL fl_lee_cliente_general(codcli) RETURNING r_cli.*
CALL fl_lee_moneda(moneda) RETURNING r_mon.*
DISPLAY codcli TO j12_codcli
DISPLAY r_cli.z01_nomcli TO tit_nombre_cli
DISPLAY moneda TO j12_moneda
DISPLAY r_mon.g13_nombre TO tit_moneda
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET rm_orden[1]  = 'ASC'
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET col          = 1
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET expr_loc = ' '
IF codloc IS NOT NULL THEN
	LET expr_loc = '   AND j12_localidad = ', codloc
END IF
WHILE TRUE
	LET query = 'SELECT DATE(j12_fecing), g08_nombre, j12_num_cheque, ',
			'j12_valor, j12_banco, j12_num_cta, j12_num_cheque, ',
			'j12_secuencia, j12_localidad ',
			'FROM cajt012, cxct001, gent008 ',
			'WHERE j12_compania  = ', codcia,
			expr_loc CLIPPED,
			'  AND j12_codcli    = ', codcli,
			'  AND j12_moneda    = "', moneda, '"',
			'  AND j12_codcli    = z01_codcli ',
			'  AND j12_banco     = g08_banco ',
			" ORDER BY ", vm_columna_1, ' ', rm_orden[vm_columna_1],
			       	', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE deto FROM query
	DECLARE q_deto CURSOR FOR deto
	LET v_num_chpr = 1
	LET total = 0
	FOREACH q_deto INTO r_chpr[v_num_chpr].*, r_ch_pr[v_num_chpr].*,
				r_loc[v_num_chpr]
		LET total = total + r_chpr[v_num_chpr].j12_valor
		LET v_num_chpr = v_num_chpr + 1
		IF v_num_chpr > v_max_chpr THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET v_num_chpr = v_num_chpr - 1
	IF v_num_chpr = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		EXIT WHILE
	END IF
	CALL set_count(v_num_chpr)
	LET int_flag = 0
	DISPLAY ARRAY r_chpr TO r_chpr.*
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel('ACCEPT','')
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#LET j = scr_line()
			--#CALL muestra_contadores_det(i, v_num_chpr)
			--#DISPLAY total TO tit_total
		--#AFTER DISPLAY 
			--#CONTINUE DISPLAY
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_5() 
		ON KEY(F5)
			LET i = arr_curr()
			LET j = scr_line()
			LET v_nuevoprog = 'cd ..', vg_separador, '..',
				vg_separador, 'COBRANZAS',
				vg_separador, 'fuentes',
				vg_separador, run_prog, 'cxcp207 ',
				vg_base, ' ', vg_modulo,
					' ', codcia, ' ',
				r_loc[i], ' ', r_ch_pr[i].j12_banco,
				' ', '"', r_ch_pr[i].j12_num_cta,'"',
				' ', '"', r_ch_pr[i].j12_num_cheque,
				'"',' ',r_ch_pr[i].j12_secuencia
			RUN v_nuevoprog
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
CLOSE WINDOW w_chpr

END FUNCTION



FUNCTION mostrar_cheque_postfechados(codcia, codloc, codcli, moneda)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE codcli		LIKE cxct001.z01_codcli
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE v_num_chpf	SMALLINT
DEFINE v_max_chpf	SMALLINT
DEFINE total		DECIMAL(12,2)
DEFINE i,j,col		SMALLINT
DEFINE query		CHAR(1000)
DEFINE expr_sql         CHAR(600)
DEFINE v_nuevoprog	CHAR(400)
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_cli		RECORD LIKE cxct001.*
DEFINE r_loc		ARRAY [100] OF LIKE gent002.g02_localidad
DEFINE r_chpf		ARRAY [100] OF RECORD
				z26_fecha_cobro	LIKE cxct026.z26_fecha_cobro,
				g08_nombre	LIKE gent008.g08_nombre,
				z26_num_cheque	LIKE cxct026.z26_num_cheque,
				z26_valor	LIKE cxct026.z26_valor
			END RECORD
DEFINE r_ch_pf		ARRAY [100] OF RECORD
				z26_codcli	LIKE cxct026.z26_codcli,
				z26_banco	LIKE cxct026.z26_banco,
				z26_num_cta	LIKE cxct026.z26_num_cta,
				z26_num_cheque	LIKE cxct026.z26_num_cheque
			END RECORD
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE run_prog		CHAR(10)
DEFINE expr_loc		VARCHAR(50)

LET v_max_chpf = 100
LET num_rows = 17
LET num_cols = 63
IF vg_gui = 0 THEN
	LET num_rows = 18
	LET num_cols = 64
END IF
OPEN WINDOW w_chpf AT 06, 15 WITH num_rows ROWS, num_cols COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST,
                   MENU LINE 0, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_305_9 FROM '../forms/cxcf305_9'
ELSE
	OPEN FORM f_305_9 FROM '../forms/cxcf305_9c'
END IF
DISPLAY FORM f_305_9
CALL mostrar_botones_chques()
CALL fl_lee_cliente_general(codcli) RETURNING r_cli.*
CALL fl_lee_moneda(moneda) RETURNING r_mon.*
DISPLAY codcli TO z26_codcli
DISPLAY r_cli.z01_nomcli TO tit_nombre_cli
DISPLAY moneda TO z20_moneda
DISPLAY r_mon.g13_nombre TO tit_moneda
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET rm_orden[1]  = 'ASC'
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET col          = 1
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET expr_loc = ' '
IF codloc IS NOT NULL THEN
	LET expr_loc = '   AND z26_localidad = ', codloc
END IF
WHILE TRUE
	LET query = 'SELECT z26_fecha_cobro, g08_nombre, z26_num_cheque, ',
			'z26_valor, z26_codcli, z26_banco, z26_num_cta, ',
			'z26_num_cheque, z26_localidad ',
			'FROM cxct026, cxct001, gent008 ',
			'WHERE z26_compania  = ', codcia,
			expr_loc CLIPPED,
			'  AND z26_codcli    = ', codcli,
			'  AND z26_estado    = "A" ',
			'  AND z26_codcli    = z01_codcli ',
			'  AND z26_banco     = g08_banco ',
			" ORDER BY ", vm_columna_1, ' ', rm_orden[vm_columna_1],
			       	', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE deto2 FROM query
	DECLARE q_deto2 CURSOR FOR deto2
	LET v_num_chpf = 1
	LET total = 0
	FOREACH q_deto2 INTO r_chpf[v_num_chpf].*, r_ch_pf[v_num_chpf].*,
				r_loc[v_num_chpf]
		LET total = total + r_chpf[v_num_chpf].z26_valor
		LET v_num_chpf = v_num_chpf + 1
		IF v_num_chpf > v_max_chpf THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET v_num_chpf = v_num_chpf - 1
	IF v_num_chpf = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		EXIT WHILE
	END IF
	CALL set_count(v_num_chpf)
	LET int_flag = 0
	DISPLAY ARRAY r_chpf TO r_chpf.*
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel('ACCEPT','')
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#LET j = scr_line()
			--#CALL muestra_contadores_det(i, v_num_chpf)
			--#DISPLAY total TO tit_total
		--#AFTER DISPLAY 
			--#CONTINUE DISPLAY
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_5() 
		ON KEY(F5)
			LET i = arr_curr()
			LET j = scr_line()
			LET v_nuevoprog = 'cd ..', vg_separador, '..',
				vg_separador, 'COBRANZAS',
				vg_separador, 'fuentes',
				vg_separador, run_prog, 'cxcp206 ',
				vg_base, ' ', vg_modulo,
					' ', codcia, ' ',
				r_loc[i], ' ', r_ch_pf[i].z26_codcli,
				' ', r_ch_pf[i].z26_banco, ' ', '"',
				r_ch_pf[i].z26_num_cta,'"', ' ',
				'"', r_ch_pf[i].z26_num_cheque, '"'
			RUN v_nuevoprog
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
CLOSE WINDOW w_chpf

END FUNCTION



FUNCTION muestra_contadores_det(cor, maximo)
DEFINE cor, maximo	SMALLINT

IF vg_gui = 1 THEN
	DISPLAY "" AT 17, 2
	DISPLAY cor, " de ", maximo AT 17, 6
END IF

END FUNCTION


 
FUNCTION mostrar_botones_chques()

--#DISPLAY 'Fecha'        TO tit_col1
--#DISPLAY 'Banco'        TO tit_col2
--#DISPLAY 'No. Cheque'   TO tit_col3
--#DISPLAY 'Valor Cheque' TO tit_col4

END FUNCTION



FUNCTION proceso_recalcula_saldos(codloc, codcli)
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE codcli		LIKE cxct002.z02_codcli

IF vm_num_rows <= 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
IF codloc IS NOT NULL THEN
	CALL fl_genera_saldos_cliente(vg_codcia, codloc, rm_cligen.z01_codcli) 
ELSE
	DECLARE q_z02 CURSOR FOR
		SELECT z02_localidad FROM cxct002
			WHERE z02_compania = vg_codcia
			  AND z02_codcli   = codcli
	FOREACH q_z02 INTO codloc
		CALL fl_genera_saldos_cliente(vg_codcia, codloc, codcli) 
	END FOREACH
END IF
CALL mostrar_registro(rm_rows[vm_row_current])

END FUNCTION



FUNCTION imprimir(codloc, codcli, moneda)
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE codcli		LIKE cxct001.z01_codcli
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE comando		CHAR(400)
DEFINE run_prog		VARCHAR(10)

IF codloc IS NULL THEN
	LET codloc = 0
END IF
LET run_prog = 'fglrun '
IF vg_gui = 0 THEN
	LET run_prog = 'fglgo '
END IF
LET comando = run_prog, 'cxcp409 ', vg_base, ' ', vg_modulo, ' ', vg_codcia,
		' ', codloc, ' ', codcli, ' "', moneda, '" "',rm_par.tipo_saldo,
		'" "', rm_par.flag_saldo, '" ', rm_par.dias_min, ' ',
		rm_par.dias_max
RUN comando

END FUNCTION



FUNCTION obtener_num_sri(cod_tran, num_tran, tit_loc, areaneg)
DEFINE cod_tran		LIKE cxct021.z21_cod_tran
DEFINE num_tran		LIKE cxct021.z21_num_tran
DEFINE tit_loc		LIKE gent002.g02_localidad
DEFINE areaneg		LIKE cxct020.z20_areaneg
DEFINE r_r38		RECORD LIKE rept038.*
DEFINE tipo_fuente	LIKE rept038.r38_tipo_fuente
DEFINE query		CHAR(600)
DEFINE base_suc		VARCHAR(10)

INITIALIZE r_r38.* TO NULL
IF cod_tran IS NULL THEN
	RETURN r_r38.r38_num_sri
END IF
LET tipo_fuente = NULL
LET base_suc    = NULL
IF areaneg = 1 THEN
	LET tipo_fuente = 'PR'
END IF
IF areaneg = 2 THEN
	LET tipo_fuente = 'OT'
END IF
IF tit_loc = 2 THEN
	LET base_suc = 'acero_gc:'
END IF
IF tit_loc = 4 THEN
	LET base_suc = 'acero_qs:'
END IF
LET query = 'SELECT * FROM ', base_suc CLIPPED, 'rept038',
		' WHERE r38_compania    = ', vg_codcia,
		'   AND r38_localidad   = ', tit_loc,
		'   AND r38_tipo_doc   IN ("FA", "NV") ',
		'   AND r38_tipo_fuente = "', tipo_fuente, '"',
		'   AND r38_cod_tran    = "', cod_tran, '"',
		'   AND r38_num_tran    = ', num_tran
PREPARE cons_r38 FROM query
DECLARE q_r38 CURSOR FOR cons_r38
OPEN q_r38
FETCH q_r38 INTO r_r38.*
CLOSE q_r38
FREE q_r38
RETURN r_r38.r38_num_sri

END FUNCTION



FUNCTION muestra_flagsaldo(flagsaldo)
DEFINE flagsaldo	CHAR(1)

CASE flagsaldo
	WHEN 'S'
		DISPLAY 'CON SALDO' TO tit_flag_saldo
	WHEN 'T'
		DISPLAY 'T O D O S' TO tit_flag_saldo
	OTHERWISE
		CLEAR flag_saldo, tit_flag_saldo
END CASE

END FUNCTION



FUNCTION muestra_tiposaldo(tiposaldo)
DEFINE tiposaldo	CHAR(1)

CASE tiposaldo
	WHEN 'A'
		DISPLAY 'A FAVOR' TO tit_tipo_saldo
	WHEN 'P'
		DISPLAY 'POR VENCER' TO tit_tipo_saldo
	WHEN 'V'
		DISPLAY 'VENCIDOS' TO tit_tipo_saldo
	WHEN 'T'
		DISPLAY 'T O D O S' TO tit_tipo_saldo
	OTHERWISE
		CLEAR tipo_saldo, tit_tipo_saldo
END CASE

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
DISPLAY '<F5>      Ver Factura'              AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Movimientos'              AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F7>      Documento'                AT a,2
DISPLAY  'F7' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F8>      Imprimir Est. Cta.'       AT a,2
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
DISPLAY '<F5>      Pago Caja'                AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Documento'                AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION control_visor_teclas_caracter_3() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Documento'                AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION control_visor_teclas_caracter_4() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Pago Caja'                AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Documento'                AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F7>      Movimientos'              AT a,2
DISPLAY  'F7' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION control_visor_teclas_caracter_5() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Cheque'                   AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
