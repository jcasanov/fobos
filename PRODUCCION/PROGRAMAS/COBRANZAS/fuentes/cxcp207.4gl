------------------------------------------------------------------------------
-- Titulo           : cxcp207.4gl - Ingreso de cheques protestados
-- Elaboracion      : 13-dic-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxcp207 base m�dulo compa��a localidad
--			[banco] [numero_cuenta] [numero_cheque] [secuencia]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE vm_nuevoprog	CHAR(400)
DEFINE rm_caj		RECORD LIKE cajt012.*
DEFINE rm_caj2		RECORD LIKE cajt010.*
DEFINE rm_cxc		RECORD LIKE cxct020.*
DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_max_det	SMALLINT
DEFINE vm_num_det	SMALLINT
DEFINE vm_scr_lin	SMALLINT
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE vm_nota_deb	CHAR(2)
DEFINE vm_r_rows	ARRAY [1000] OF INTEGER
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE rm_det		ARRAY [1000] OF RECORD
				j10_tipo_destino LIKE cajt010.j10_tipo_destino,
				j10_fecha_pro	DATE,
				g08_nombre	LIKE gent008.g08_nombre,
				j11_num_cta_tarj LIKE cajt011.j11_num_cta_tarj,
				j11_num_ch_aut	LIKE cajt011.j11_num_ch_aut,
				j11_protestado	LIKE cajt011.j11_protestado
			END RECORD
DEFINE rm_cajs		ARRAY [1000] OF RECORD
				j10_compania	LIKE cajt010.j10_compania,
				j10_localidad	LIKE cajt010.j10_localidad,
				j10_tipo_fuente	LIKE cajt010.j10_tipo_fuente,
				j10_num_fuente	LIKE cajt010.j10_num_fuente,
				j11_compania	LIKE cajt011.j11_compania,
				j11_localidad	LIKE cajt011.j11_localidad,
				j11_tipo_fuente	LIKE cajt011.j11_tipo_fuente,
				j11_num_fuente	LIKE cajt011.j11_num_fuente,
				j11_secuencia	LIKE cajt011.j11_secuencia,
				j11_cod_bco_tarj LIKE cajt011.j11_cod_bco_tarj
			END RECORD

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 8 THEN  -- Validar # par�metros correcto
	--CALL fgl_winmessage(vg_producto,'N�mero de par�metros incorrecto.', 'stop')
	CALL fl_mostrar_mensaje('N�mero de par�metros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'cxcp207'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

LET vm_nota_deb = 'ND'
IF num_args() = 8 THEN
	CALL control_cheque()
	RETURN
END IF
CALL fl_nivel_isolation()
LET vm_max_rows	= 1000
LET vm_max_det	= 1000
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
	OPEN FORM f_cxc FROM "../forms/cxcf207_1"
ELSE
	OPEN FORM f_cxc FROM "../forms/cxcf207_1c"
END IF
DISPLAY FORM f_cxc
LET vm_num_rows    = 0
LET vm_row_current = 0
LET vm_num_det     = 0
CALL muestra_contadores_det(0)
CALL borrar_cabecera()
CALL mostrar_botones_detalle()
WHILE TRUE
	CALL borrar_detalle()
	CALL control_cheques_protestados()
	IF int_flag THEN
		EXIT WHILE
	END IF
END WHILE

END FUNCTION



FUNCTION control_cheques_protestados()
DEFINE r_cli		RECORD LIKE cxct002.*
DEFINE r_cli_gen	RECORD LIKE cxct001.*
DEFINE cod_aux		LIKE cxct002.z02_codcli
DEFINE nom_aux		LIKE cxct001.z01_nomcli
DEFINE fecha_fin	DATE

INITIALIZE r_cli.*, r_cli_gen.*, cod_aux TO NULL
LET vm_fecha_fin = TODAY
LET int_flag = 0
INPUT BY NAME rm_caj2.j10_codcli, vm_fecha_ini, vm_fecha_fin
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(j10_codcli) THEN
			CALL fl_ayuda_cliente_localidad(vg_codcia,vg_codloc)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				LET rm_caj2.j10_codcli = cod_aux
				DISPLAY BY NAME rm_caj2.j10_codcli 
				DISPLAY nom_aux TO j10_nomcli
			END IF 
		END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD vm_fecha_fin
		LET fecha_fin = vm_fecha_fin
	AFTER FIELD j10_codcli
		IF rm_caj2.j10_codcli IS NOT NULL THEN
			CALL fl_lee_cliente_general(rm_caj2.j10_codcli)
		 		RETURNING r_cli_gen.*
			IF r_cli_gen.z01_codcli IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Cliente no existe.','exclamation')
				CALL fl_mostrar_mensaje('Cliente no existe.','exclamation')
				NEXT FIELD j10_codcli
			END IF
			DISPLAY r_cli_gen.z01_nomcli TO j10_nomcli
			IF r_cli_gen.z01_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD j10_codcli
                        END IF		 
			CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc,
							rm_caj2.j10_codcli)
		 		RETURNING r_cli.*
			IF r_cli.z02_compania IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Cliente no est� activado para la compa��a.','exclamation')
				CALL fl_mostrar_mensaje('Cliente no est� activado para la compa��a.','exclamation')
				NEXT FIELD j10_codcli
			END IF
		ELSE
			CLEAR j10_nomcli
		END IF
	AFTER FIELD vm_fecha_ini 
		IF vm_fecha_ini IS NOT NULL THEN
			IF vm_fecha_ini > TODAY THEN
				--CALL fgl_winmessage(vg_producto,'La fecha de inicio no puede ser mayor a la de hoy.','exclamation')
				CALL fl_mostrar_mensaje('La fecha de inicio no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD vm_fecha_ini
			END IF
		END IF
	AFTER FIELD vm_fecha_fin 
		IF vm_fecha_fin IS NOT NULL THEN
			IF vm_fecha_fin > TODAY THEN
				--CALL fgl_winmessage(vg_producto,'La fecha de t�rmino no puede ser mayor a la de hoy.','exclamation')
				CALL fl_mostrar_mensaje('La fecha de t�rmino no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD vm_fecha_fin
			END IF
		ELSE
			LET vm_fecha_fin = fecha_fin
			DISPLAY BY NAME vm_fecha_fin
		END IF
	AFTER INPUT
		IF vm_fecha_fin < vm_fecha_ini THEN
			--CALL fgl_winmessage(vg_producto,'La fecha de t�rmino debe ser mayor a la fecha de inicio.','exclamation')
			CALL fl_mostrar_mensaje('La fecha de t�rmino debe ser mayor a la fecha de inicio.','exclamation')
			NEXT FIELD vm_fecha_fin
		END IF
END INPUT
CALL muestra_detalle_cheques()

END FUNCTION



FUNCTION muestra_detalle_cheques()
DEFINE i,j,col		SMALLINT
DEFINE query		CHAR(1000)
DEFINE expr_sql		VARCHAR(100)

INITIALIZE expr_sql TO NULL
IF rm_caj2.j10_codcli IS NOT NULL THEN
	LET expr_sql = '  AND j10_codcli      = ', rm_caj2.j10_codcli
END IF
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET rm_orden[1]  = 'ASC'
LET vm_columna_1 = 2
LET vm_columna_2 = 3
LET col          = 2
WHILE TRUE
	LET query = 'SELECT j10_tipo_destino, DATE(j10_fecha_pro), ',
			'g08_nombre, j11_num_cta_tarj, j11_num_ch_aut, ',
			'j11_protestado, j10_compania, j10_localidad, ',
			'j10_tipo_fuente, j10_num_fuente, j11_compania, ',
			'j11_localidad, j11_tipo_fuente, j11_num_fuente, ',
			'j11_secuencia, j11_cod_bco_tarj ',
			'FROM cajt010, cajt011, gent008 ',
			'WHERE j10_compania     = ', vg_codcia,
			'  AND j10_localidad    = ', vg_codloc,
			expr_sql CLIPPED,
			'  AND j10_areaneg IS NOT NULL ',
			'  AND DATE(j10_fecha_pro) ',
			'  BETWEEN "', vm_fecha_ini,
			'" AND "', vm_fecha_fin, '"',
			'  AND j11_compania     = j10_compania ',
			'  AND j11_localidad    = j10_localidad ',
			'  AND j11_tipo_fuente  = j10_tipo_fuente ',
			'  AND j11_num_fuente   = j10_num_fuente ',
			'  AND j11_codigo_pago  = "CH" ',
			'  AND j11_protestado   = "N" ',
			'  AND j11_cod_bco_tarj = g08_banco ',
			'  AND j11_num_egreso IS NOT NULL ',
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
		RETURN
	END IF
	CALL set_count(vm_num_det)
	LET int_flag = 0
	DISPLAY ARRAY rm_det TO rm_det.*
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel('ACCEPT','')
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#LET j = scr_line()
			--#CALL muestra_contadores_det(i)
		--#AFTER DISPLAY 
			--#CONTINUE DISPLAY
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_1() 
		ON KEY(F5)
			LET i = arr_curr()
			LET j = scr_line()
			CALL control_protesto(i)
			DISPLAY rm_det[i].j11_protestado
				TO rm_det[j].j11_protestado
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
		LET int_flag = 0
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



FUNCTION control_protesto(i)
DEFINE i		SMALLINT
DEFINE r_caj2		RECORD LIKE cajt011.*
DEFINE r_mon_par	RECORD LIKE gent014.*
DEFINE fecha_aux	DATE
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

INITIALIZE rm_caj.*, rm_cxc.* TO NULL
IF rm_det[i].j11_protestado = 'S' THEN
	--CALL fgl_winmessage(vg_producto,'Cheque ya fue ingresado como protestado.','exclamation')
	CALL fl_mostrar_mensaje('Cheque ya fue ingresado como protestado.','exclamation')
	RETURN
END IF
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 19
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_for AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST) 
IF vg_gui = 1 THEN
	OPEN FORM f_cxc3 FROM "../forms/cxcf207_2"
ELSE
	OPEN FORM f_cxc3 FROM "../forms/cxcf207_2c"
END IF
DISPLAY FORM f_cxc3
CALL fl_retorna_usuario()
CLEAR FORM
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up2 CURSOR FOR SELECT * FROM cajt011
	WHERE j11_compania    = rm_cajs[i].j11_compania 
	  AND j11_localidad   = rm_cajs[i].j11_localidad
	  AND j11_tipo_fuente = rm_cajs[i].j11_tipo_fuente
	  AND j11_num_fuente  = rm_cajs[i].j11_num_fuente
	  AND j11_secuencia   = rm_cajs[i].j11_secuencia
	FOR UPDATE
OPEN q_up2
FETCH q_up2 INTO r_caj2.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	CLOSE WINDOW w_for
	RETURN
END IF
WHENEVER ERROR STOP
CALL cargar_datos_cheque(i)
CALL leer_datos(i)
IF NOT int_flag THEN
	LET rm_caj.j12_fecing = CURRENT
	CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, vg_modulo,
						'AA', vm_nota_deb)
		RETURNING rm_caj.j12_nd_interna
	IF rm_caj.j12_nd_interna <= '0' THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
	DISPLAY BY NAME rm_caj.j12_nd_interna
	SELECT MAX(j12_secuencia) INTO rm_caj.j12_secuencia FROM cajt012
		WHERE j12_compania  = vg_codcia
		  AND j12_localidad = vg_codloc
	IF rm_caj.j12_secuencia > 0 THEN
		LET rm_caj.j12_secuencia = rm_caj.j12_secuencia + 1
	ELSE
		LET rm_caj.j12_secuencia = 1
	END IF
	INSERT INTO cajt012 VALUES (rm_caj.*)
	IF rm_caj.j12_moneda = rg_gen.g00_moneda_base THEN
		LET r_mon_par.g14_tasa = 1
	ELSE
		CALL fl_lee_factor_moneda(rm_caj.j12_moneda,
					rg_gen.g00_moneda_base)
			RETURNING r_mon_par.*
		IF r_mon_par.g14_serial IS NULL THEN
			--CALL fgl_winmessage(vg_producto,'La paridad para est� moneda no existe.','stop')
			CALL fl_mostrar_mensaje('La paridad para est� moneda no existe.','stop')
			ROLLBACK WORK
			EXIT PROGRAM
		END IF
	END IF
	LET rm_cxc.z20_paridad = r_mon_par.g14_tasa
	--LET fecha_aux = TODAY + 30
	LET fecha_aux = TODAY
	--LET rm_cxc.z20_val_impto = (rm_caj.j12_valor * rg_gen.g00_porc_impto)
				   --/ (100 + rg_gen.g00_porc_impto)
	LET rm_cxc.z20_val_impto = 0
	CALL fl_retorna_precision_valor(rm_caj.j12_moneda, rm_cxc.z20_val_impto)
		RETURNING rm_cxc.z20_val_impto
	INSERT INTO cxct020 VALUES (rm_caj.j12_compania, rm_caj.j12_localidad,
			rm_caj.j12_codcli, vm_nota_deb, rm_caj.j12_nd_interna,1,
			rm_caj.j12_areaneg, rm_caj.j12_referencia,
			TODAY, fecha_aux, 0, 0, rm_caj.j12_moneda,
			rm_cxc.z20_paridad, rm_cxc.z20_val_impto, 
			rm_caj.j12_valor, 0,
			rm_caj.j12_valor, 0, rm_cxc.z20_cartera,
			rm_cxc.z20_linea, NULL, 'A', NULL, NULL, NULL, 
			rm_caj.j12_usuario, rm_caj.j12_fecing)
	LET rm_det[i].j11_protestado = 'S'
	UPDATE cajt011 SET j11_protestado = rm_det[i].j11_protestado
		WHERE CURRENT OF q_up2
	CALL fl_genera_saldos_cliente(vg_codcia, vg_codloc, rm_caj.j12_codcli)
	COMMIT WORK
	DISPLAY BY NAME rm_caj.j12_fecing
	CALL fl_mensaje_registro_ingresado()
ELSE
	ROLLBACK WORK
END IF
WHENEVER ERROR STOP
CLOSE WINDOW w_for
--#IF int_flag THEN
	--#RETURN
--#END IF

END FUNCTION



FUNCTION cargar_datos_cheque(i)
DEFINE i		SMALLINT
DEFINE r_caj		RECORD LIKE cajt010.*

INITIALIZE rm_caj.j12_codcli TO NULL
CALL fl_lee_cabecera_caja(rm_cajs[i].j10_compania, rm_cajs[i].j10_localidad,
			rm_cajs[i].j10_tipo_fuente, rm_cajs[i].j10_num_fuente)
	RETURNING r_caj.*
LET rm_caj.j12_compania     = vg_codcia
LET rm_caj.j12_localidad    = vg_codloc
LET rm_caj.j12_banco        = rm_cajs[i].j11_cod_bco_tarj
LET rm_caj.j12_num_cta      = rm_det[i].j11_num_cta_tarj
LET rm_caj.j12_num_cheque   = rm_det[i].j11_num_ch_aut
LET rm_caj.j12_secuencia    = 0
LET rm_caj.j12_codcli       = r_caj.j10_codcli
LET rm_caj.j12_areaneg      = r_caj.j10_areaneg
LET rm_caj.j12_tipo_fuente  = rm_cajs[i].j11_tipo_fuente
LET rm_caj.j12_num_fuente   = rm_cajs[i].j11_num_fuente
LET rm_caj.j12_sec_cheque   = rm_cajs[i].j11_secuencia
LET rm_caj.j12_fec_caja     = rm_det[i].j10_fecha_pro
LET rm_caj.j12_moneda       = r_caj.j10_moneda
LET rm_caj.j12_valor        = 0
LET rm_caj.j12_usuario      = vg_usuario
LET rm_caj.j12_fecing       = CURRENT
CALL mostrar_registro(i)

END FUNCTION



FUNCTION leer_datos(i)
DEFINE i		SMALLINT
DEFINE resp		CHAR(6)
DEFINE r_cli		RECORD LIKE cxct002.*
DEFINE r_cli_gen	RECORD LIKE cxct001.*
DEFINE r_car		RECORD LIKE gent012.*
DEFINE r_lin		RECORD LIKE gent020.*
DEFINE r_caj		RECORD LIKE cajt010.*
DEFINE r_caj2		RECORD LIKE cajt011.*
DEFINE cod_aux		LIKE cxct002.z02_codcli
DEFINE nom_aux		LIKE cxct001.z01_nomcli
DEFINE codc_aux		LIKE gent012.g12_subtipo
DEFINE nomc_aux		LIKE gent012.g12_nombre
DEFINE codl_aux		LIKE gent020.g20_grupo_linea
DEFINE noml_aux		LIKE gent020.g20_nombre
DEFINE codcli		LIKE cajt012.j12_codcli
DEFINE valor		LIKE cajt012.j12_valor

INITIALIZE r_cli.*, r_cli_gen.*, r_car.*, r_lin.*, cod_aux, codc_aux, codl_aux
	TO NULL
LET int_flag = 0
INPUT BY NAME rm_caj.j12_codcli, rm_caj.j12_referencia, rm_caj.j12_valor,
	rm_caj.j12_nd_banco, rm_caj.j12_nd_fec_bco, rm_cxc.z20_cartera,
	rm_cxc.z20_linea
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
	        IF field_touched(rm_caj.j12_codcli, rm_caj.j12_referencia,
			rm_caj.j12_valor, rm_caj.j12_nd_banco,
			rm_caj.j12_nd_fec_bco, rm_cxc.z20_cartera,
			rm_cxc.z20_linea)
	        THEN
		       	LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
               			RETURNING resp
		        IF resp = 'Yes' THEN
				LET int_flag = 1
        	               	CLEAR FORM
                		--#RETURN
				EXIT INPUT
	        	END IF
		ELSE
			--#RETURN
			EXIT INPUT
		END IF
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(j12_codcli) THEN
			CALL fl_ayuda_cliente_localidad(vg_codcia,vg_codloc)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				LET rm_caj.j12_codcli = cod_aux
				DISPLAY BY NAME rm_caj.j12_codcli 
				DISPLAY nom_aux TO tit_nombre_cli
			END IF 
		END IF
		IF INFIELD(z20_cartera) THEN
			CALL fl_ayuda_subtipo_cartera()
				RETURNING codc_aux, nomc_aux
			LET int_flag = 0
			IF codc_aux IS NOT NULL THEN
				LET rm_cxc.z20_cartera = codc_aux
				DISPLAY BY NAME rm_cxc.z20_cartera 
				DISPLAY nomc_aux TO tit_cartera
			END IF 
		END IF
		IF INFIELD(z20_linea) THEN
			CALL fl_ayuda_grupo_lineas(vg_codcia)
				RETURNING codl_aux, noml_aux
			LET int_flag = 0
			IF codl_aux IS NOT NULL THEN
				LET rm_cxc.z20_linea = codl_aux
				DISPLAY BY NAME rm_cxc.z20_linea 
				DISPLAY noml_aux TO tit_linea
			END IF
		END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD j12_codcli
		LET codcli = rm_caj.j12_codcli
	BEFORE FIELD j12_valor
		LET valor  = rm_caj.j12_valor
	AFTER FIELD j12_codcli
		IF rm_caj.j12_codcli IS NOT NULL THEN
			CALL fl_lee_cliente_general(rm_caj.j12_codcli)
		 		RETURNING r_cli_gen.*
			IF r_cli_gen.z01_codcli IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Cliente no existe.','exclamation')
				CALL fl_mostrar_mensaje('Cliente no existe.','exclamation')
				NEXT FIELD j12_codcli
			END IF
			DISPLAY r_cli_gen.z01_nomcli TO tit_nombre_cli
			IF r_cli_gen.z01_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD j12_codcli
                        END IF		 
			CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc,
							rm_caj.j12_codcli)
		 		RETURNING r_cli.*
			IF r_cli.z02_compania IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Cliente no est� activado para la compa��a.','exclamation')
				CALL fl_mostrar_mensaje('Cliente no est� activado para la compa��a.','exclamation')
				NEXT FIELD j12_codcli
			END IF
		ELSE
			LET rm_caj.j12_codcli = codcli
			DISPLAY BY NAME rm_caj.j12_codcli
			CALL fl_lee_cliente_general(rm_caj.j12_codcli)
		 		RETURNING r_cli_gen.*
			DISPLAY r_cli_gen.z01_nomcli TO tit_nombre_cli
		END IF
	AFTER FIELD j12_valor
		IF rm_caj.j12_valor IS NULL THEN
			LET rm_caj.j12_valor = valor
			DISPLAY BY NAME rm_caj.j12_valor
		END IF
	AFTER FIELD j12_nd_fec_bco
		IF rm_caj.j12_nd_fec_bco IS NOT NULL THEN
			IF rm_caj.j12_nd_fec_bco > TODAY THEN
				--CALL fgl_winmessage(vg_producto,'La fecha de la Nota de D�bito no puede ser mayor a la fecha de hoy.','exclamation')
				CALL fl_mostrar_mensaje('La fecha de la Nota de D�bito no puede ser mayor a la fecha de hoy.','exclamation')
				NEXT FIELD j12_nd_fec_bco
			END IF
		END IF
	AFTER FIELD z20_cartera 
		IF rm_cxc.z20_cartera IS NOT NULL THEN
			CALL fl_lee_subtipo_entidad('CR',rm_cxc.z20_cartera)
				RETURNING r_car.*
			IF r_car.g12_tiporeg IS NULL  THEN
				--CALL fgl_winmessage(vg_producto,'Cartera no existe.','exclamation')
				CALL fl_mostrar_mensaje('Cartera no existe.','exclamation')
				NEXT FIELD z20_cartera
			END IF
			DISPLAY r_car.g12_nombre TO tit_cartera
		ELSE
			CLEAR tit_cartera
		END IF
	AFTER FIELD z20_linea 
		IF rm_cxc.z20_linea IS NOT NULL THEN
			CALL fl_lee_grupo_linea(vg_codcia,rm_cxc.z20_linea)
				RETURNING r_lin.*
			IF r_lin.g20_grupo_linea IS NULL  THEN
				--CALL fgl_winmessage(vg_producto,'L�nea de venta no existe.','exclamation')
				CALL fl_mostrar_mensaje('L�nea de venta no existe.','exclamation')
				NEXT FIELD z20_linea
			END IF
			DISPLAY r_lin.g20_nombre TO tit_linea
		ELSE
			CLEAR tit_linea
		END IF
	AFTER INPUT
		IF rm_caj.j12_codcli IS NULL THEN
			--CALL fgl_winmessage(vg_producto,'Debe ingresar el cliente para grabar el cheque.','exclamation')
			CALL fl_mostrar_mensaje('Debe ingresar el cliente para grabar el cheque.','exclamation')
			NEXT FIELD j12_codcli
		END IF
		CALL fl_lee_cabecera_caja(rm_cajs[i].j10_compania,
					rm_cajs[i].j10_localidad,
					rm_cajs[i].j10_tipo_fuente,
					rm_cajs[i].j10_num_fuente)
			RETURNING r_caj.*
		IF rm_caj.j12_codcli <> r_caj.j10_codcli THEN
			LET rm_caj.j12_codcli = r_caj.j10_codcli
			DISPLAY BY NAME rm_caj.j12_codcli
			CALL fl_lee_cliente_general(rm_caj.j12_codcli)
		 		RETURNING r_cli_gen.*
			DISPLAY r_cli_gen.z01_nomcli TO tit_nombre_cli
		END IF
		IF rm_caj.j12_valor = 0 THEN
			--CALL fgl_winmessage(vg_producto,'El valor del cheque debe ser mayor a cero.','exclamation')
			CALL fl_mostrar_mensaje('El valor del cheque debe ser mayor a cero.','exclamation')
			NEXT FIELD j12_valor
		END IF
		IF rm_cxc.z20_linea IS NOT NULL THEN
			CALL fl_lee_grupo_linea(vg_codcia, rm_cxc.z20_linea)
				RETURNING r_lin.*
			IF rm_caj.j12_areaneg <> r_lin.g20_areaneg THEN
				--CALL fgl_winmessage(vg_producto,'La l�nea no pertenece al �rea de negocio especificada.','exclamation')
				CALL fl_mostrar_mensaje('La l�nea no pertenece al �rea de negocio especificada.','exclamation')
				NEXT FIELD z20_linea
			END IF
		END IF
		CALL fl_lee_detalle_pago_caja(rm_cajs[i].j11_compania,
				rm_cajs[i].j11_localidad,
				rm_cajs[i].j11_tipo_fuente,
				rm_cajs[i].j11_num_fuente,
				rm_cajs[i].j11_secuencia)
			RETURNING r_caj2.*
		IF r_caj2.j11_valor IS NOT NULL THEN
			IF rm_caj.j12_valor < r_caj2.j11_valor THEN
				--CALL fgl_winmessage(vg_producto,'El valor debe ser mayor al valor del cheque.','exclamation')
				CALL fl_mostrar_mensaje('El valor debe ser mayor al valor del cheque.','exclamation')
				NEXT FIELD j12_valor
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION muestra_contadores_det(cor)
DEFINE cor	           SMALLINT

IF vg_gui = 1 THEN
	DISPLAY "" AT 21, 2
	DISPLAY cor, " de ", vm_num_det AT 21, 6
END IF

END FUNCTION


 
FUNCTION control_cheque()
DEFINE r_caj		RECORD LIKE cajt012.*
DEFINE r_cxc		RECORD LIKE cxct020.*
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 19
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW wf2 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_cxc2 FROM "../forms/cxcf207_2"
ELSE
	OPEN FORM f_cxc2 FROM "../forms/cxcf207_2c"
END IF
DISPLAY FORM f_cxc2
LET r_caj.j12_banco       = arg_val(5)
LET r_caj.j12_num_cta     = arg_val(6)
LET r_caj.j12_num_cheque  = arg_val(7)
LET r_caj.j12_secuencia   = arg_val(8)
CALL fl_lee_cheque_protestado_cxc(vg_codcia, vg_codloc, r_caj.j12_banco,
			r_caj.j12_num_cta, r_caj.j12_num_cheque,
			r_caj.j12_secuencia)
	RETURNING rm_caj.*
CALL fl_lee_documento_deudor_cxc(rm_caj.j12_compania, rm_caj.j12_localidad,
				rm_caj.j12_codcli, vm_nota_deb,
				rm_caj.j12_nd_interna, 1)
	RETURNING rm_cxc.*
CALL mostrar_registro(0)
MENU 'OPCIONES'
	COMMAND KEY('D') 'Documento'
		CALL ver_documento_deudor()
	COMMAND KEY('S') 'Salir'
		EXIT MENU
END MENU
CLOSE WINDOW wf2
IF int_flag THEN
	RETURN
END IF

END FUNCTION



FUNCTION mostrar_registro(i)
DEFINE i		SMALLINT
DEFINE r_caj		RECORD LIKE cajt010.*
DEFINE r_caj2		RECORD LIKE cajt011.*
DEFINE r_cli_gen	RECORD LIKE cxct001.*
DEFINE r_bco_gen	RECORD LIKE gent008.*
DEFINE r_are		RECORD LIKE gent003.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_car		RECORD LIKE gent012.*
DEFINE r_lin		RECORD LIKE gent020.*

DISPLAY BY NAME rm_caj.j12_banco, rm_caj.j12_num_cta, rm_caj.j12_num_cheque,
		rm_caj.j12_codcli, rm_caj.j12_areaneg, rm_caj.j12_fec_caja,
		rm_caj.j12_moneda, rm_caj.j12_usuario, rm_caj.j12_fecing,
		rm_caj.j12_referencia, rm_caj.j12_valor, rm_caj.j12_nd_banco,
		rm_caj.j12_nd_fec_bco, rm_caj.j12_nd_interna,
		rm_cxc.z20_cartera, rm_cxc.z20_linea
CALL fl_lee_cliente_general(rm_caj.j12_codcli) RETURNING r_cli_gen.*
DISPLAY r_cli_gen.z01_nomcli TO tit_nombre_cli
CALL fl_lee_area_negocio(vg_codcia,rm_caj.j12_areaneg) RETURNING r_are.*
DISPLAY r_are.g03_nombre TO tit_area
CALL fl_lee_banco_general(rm_caj.j12_banco) RETURNING r_bco_gen.*
DISPLAY r_bco_gen.g08_nombre TO tit_banco
CALL fl_lee_moneda(rm_caj.j12_moneda) RETURNING r_mon.* 
DISPLAY r_mon.g13_nombre TO tit_moneda
CALL fl_lee_subtipo_entidad('CR',rm_cxc.z20_cartera) RETURNING r_car.*
DISPLAY r_car.g12_nombre TO tit_cartera
CALL fl_lee_grupo_linea(vg_codcia,rm_cxc.z20_linea)
	RETURNING r_lin.*
DISPLAY r_lin.g20_nombre TO tit_linea
IF num_args() = 4 THEN
	CALL fl_lee_detalle_pago_caja(rm_cajs[i].j11_compania,
			rm_cajs[i].j11_localidad, rm_cajs[i].j11_tipo_fuente,
			rm_cajs[i].j11_num_fuente, rm_cajs[i].j11_secuencia)
		RETURNING r_caj2.*
ELSE
	CALL fl_lee_detalle_pago_caja(rm_caj.j12_compania, rm_caj.j12_localidad,
			rm_caj.j12_tipo_fuente, rm_caj.j12_num_fuente,
			rm_caj.j12_sec_cheque)
		RETURNING r_caj2.*
END IF
DISPLAY r_caj2.j11_valor TO tit_valor_che

END FUNCTION



FUNCTION ver_documento_deudor()
DEFINE run_prog		CHAR(10)

{-- ESTO PARA LLAMAR AL PROGRAMA SEG�N SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS',
	vg_separador, 'fuentes', vg_separador, run_prog, 'cxcp200 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ', rm_caj.j12_codcli,
	' ', vm_nota_deb, ' ', rm_caj.j12_nd_interna, ' ', 1
RUN vm_nuevoprog

END FUNCTION



FUNCTION mostrar_botones_detalle()

--#DISPLAY 'TD'          TO tit_col1
--#DISPLAY 'Fec. Emi.'   TO tit_col2
--#DISPLAY 'Banco'       TO tit_col3
--#DISPLAY 'No. Cuenta'  TO tit_col4
--#DISPLAY 'No. Cheque'  TO tit_col5
--#DISPLAY 'P'           TO tit_col6

END FUNCTION



FUNCTION borrar_cabecera()

CLEAR j10_nomcli, vm_fecha_ini, vm_fecha_fin
INITIALIZE rm_caj.*, rm_caj2.*, rm_cxc.*, vm_fecha_ini, vm_fecha_fin TO NULL

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i  		SMALLINT

CALL muestra_contadores_det(0)
LET vm_scr_lin = fgl_scr_size('rm_det')
FOR i = 1 TO vm_scr_lin
        CLEAR rm_det[i].*
END FOR
FOR i = 1 TO vm_max_det
        INITIALIZE rm_det[i].*, rm_cajs[i].* TO NULL
END FOR

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
DISPLAY '<F5>      Protesto'                 AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
