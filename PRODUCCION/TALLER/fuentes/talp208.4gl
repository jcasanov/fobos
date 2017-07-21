--------------------------------------------------------------------------------
-- Titulo           : talp208.4gl - Aprobación crédito de ordenes de trabajo 
-- Elaboracion      : 22-oct-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun talp208 base módulo compañía localidad
--			[ord_trabajo] [A]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_nuevoprog     CHAR(400)
DEFINE rm_t25		RECORD LIKE talt025.*
DEFINE rm_t26		RECORD LIKE talt026.*
DEFINE rm_t27		RECORD LIKE talt027.*
DEFINE rm_t23		RECORD LIKE talt023.*
DEFINE rm_t04		RECORD LIKE talt004.*
DEFINE rm_t60		RECORD LIKE talt060.*
DEFINE rm_z61		RECORD LIKE cxct061.*
DEFINE vm_max_elm       SMALLINT
DEFINE vm_scr_lin       SMALLINT
DEFINE vm_ind_docs      SMALLINT
DEFINE vm_entro_inp    	SMALLINT
DEFINE vm_fec_vcto	DATE
DEFINE vm_total_cap     DECIMAL(11,2)
DEFINE vm_total_int     DECIMAL(11,2)
DEFINE vm_total_gen     DECIMAL(11,2)
DEFINE vm_plazo_dia	LIKE talt025.t25_plazo
DEFINE vm_areaneg	LIKE gent020.g20_areaneg
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE entro_cre	SMALLINT
DEFINE rm_deto		ARRAY [100] OF RECORD
				t23_orden	LIKE talt023.t23_orden,
				t23_nom_cliente	LIKE talt023.t23_nom_cliente,
				t23_tot_neto	LIKE talt023.t23_tot_neto,
				t25_valor_cred	LIKE talt025.t25_valor_cred,
				t25_valor_ant	LIKE talt025.t25_valor_ant
			END RECORD
DEFINE rm_ta 		ARRAY [100] OF RECORD
				t26_dividendo	LIKE talt026.t26_dividendo,
				t26_fec_vcto	LIKE talt026.t26_fec_vcto,
				t26_valor_cap	LIKE talt026.t26_valor_cap,
				t26_valor_int	LIKE talt026.t26_valor_int,
				tit_valor_tot	DECIMAL(11,2)
			END RECORD
DEFINE rm_docs 		ARRAY[100] OF RECORD
        			t27_tipo        LIKE talt027.t27_tipo,
        			t27_numero	LIKE talt027.t27_numero,
        			z21_moneda	LIKE cxct021.z21_moneda,
        			z21_fecha_emi	LIKE cxct021.z21_fecha_emi,
        			t27_valor       LIKE talt027.t27_valor,
        			tit_valor_usar	LIKE talt027.t27_valor
			END RECORD
DEFINE rm_ta_aux	ARRAY [100] OF RECORD
				t26_dividendo	LIKE talt026.t26_dividendo,
				t26_fec_vcto	LIKE talt026.t26_fec_vcto,
				t26_valor_cap	LIKE talt026.t26_valor_cap,
				t26_valor_int	LIKE talt026.t26_valor_int,
				tit_valor_tot	DECIMAL(11,2)
			END RECORD
DEFINE rm_docs_aux	ARRAY[100] OF RECORD
        			t27_tipo        LIKE talt027.t27_tipo,
        			t27_numero	LIKE talt027.t27_numero,
        			z21_moneda	LIKE cxct021.z21_moneda,
        			z21_fecha_emi	LIKE cxct021.z21_fecha_emi,
        			t27_valor       LIKE talt027.t27_valor,
        			tit_valor_usar	LIKE talt027.t27_valor
			END RECORD

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp208.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 6 THEN  -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'talp208'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE i,j,l,col	SMALLINT
DEFINE query		CHAR(500)
DEFINE tipo		LIKE talt023.t23_tipo_ot
DEFINE r_tp		RECORD LIKE talt005.*
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
IF num_args() = 4 OR num_args() = 6 THEN
	CALL fl_chequeo_mes_proceso_tal(vg_codcia) RETURNING int_flag
	IF int_flag THEN
		RETURN
	END IF
END IF
CREATE TEMP TABLE tempo_doc 
	(locali		SMALLINT,
	 codcli		INTEGER,
	 nomcli		CHAR(100),
	 localidad	VARCHAR(20,10),
	 por_vencer	DECIMAL(12,2),
	 vencido	DECIMAL(12,2))
LET vm_max_elm = 100
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
IF num_args() = 6 THEN
	CALL ejecutar_aprobacion_credito_automatica()
	EXIT PROGRAM
END IF
OPEN WINDOW w_mas AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
	OPEN FORM f_mas FROM "../forms/talf208_1"
ELSE
	OPEN FORM f_mas FROM "../forms/talf208_1c"
END IF
DISPLAY FORM f_mas
FOR i = 1 TO vm_max_elm
	INITIALIZE rm_ta[i].*, rm_ta_aux[i].*, rm_docs[i].*, rm_docs_aux[i].*
		TO NULL
END FOR
INITIALIZE rm_t25.*, rm_t26.*, rm_t27.*, rm_t23.* TO NULL
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET rm_orden[1] = 'ASC'
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET col          = 1
WHILE TRUE
     --#DISPLAY 'Orden'      TO tit_col1
     --#DISPLAY 'Cliente'    TO tit_col2
     --#DISPLAY 'Total Neto' TO tit_col3
     --#DISPLAY 'Crédito'    TO tit_col4
     --#DISPLAY 'Dcto. a Favor'  TO tit_col5
	LET query = 'SELECT t23_orden, t23_nom_cliente, t23_tot_neto, ',
			' t25_valor_cred, t25_valor_ant, t23_tipo_ot ',
			' FROM talt023, OUTER talt025 ',
			' WHERE t23_compania  = ', vg_codcia, ' AND ',
			      ' t23_localidad = ', vg_codloc, ' AND ',
			      ' t23_estado = "C" AND ',
			      ' t23_compania  = t25_compania AND ',
			      ' t23_localidad = t25_localidad AND ',
			      ' t23_orden     = t25_orden',
			" ORDER BY ", vm_columna_1, ' ', rm_orden[vm_columna_1],
			        ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE deto FROM query
	DECLARE q_deto CURSOR FOR deto
	LET i = 1
	FOREACH q_deto INTO rm_deto[i].*, tipo
		IF rm_deto[i].t25_valor_cred IS NULL THEN
			LET rm_deto[i].t25_valor_cred = 0
			LET rm_deto[i].t25_valor_ant  = 0
		END IF
		CALL fl_lee_tipo_orden_taller(vg_codcia,tipo) RETURNING r_tp.*
		IF r_tp.t05_factura = 'N' THEN
			CONTINUE FOREACH
		END IF
		IF rm_deto[i].t23_tot_neto = 0 THEN
			CONTINUE FOREACH
		END IF
		LET i = i + 1
		IF i > vm_max_elm THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		EXIT PROGRAM
	END IF
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rm_deto TO rm_deto.*
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#LET l = scr_line()
			--#CALL muestra_contadores(j,i)
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel('ACCEPT','')
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#AFTER DISPLAY 
			--#CONTINUE DISPLAY
		ON KEY(INTERRUPT)
			EXIT DISPLAY
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_2() 
		ON KEY(F5)
			LET j = arr_curr()
			LET l = scr_line()
			LET rm_t23.t23_orden = rm_deto[j].t23_orden
			CALL sub_menu(j)
			LET int_flag = 0
			IF entro_cre = 1 THEN
				--#CONTINUE DISPLAY
			ELSE
				EXIT DISPLAY
			END IF
		ON KEY(F6)
			LET j = arr_curr()
			LET l = scr_line()
			LET rm_t23.t23_orden = rm_deto[j].t23_orden
			CALL ver_orden()
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



FUNCTION ejecutar_aprobacion_credito_automatica()
DEFINE r_t25		RECORD LIKE talt025.*

INITIALIZE rm_t25.*, rm_t26.*, rm_t27.*, rm_t23.*, rm_t60.* TO NULL
LET r_t25.t25_orden = arg_val(5)
DECLARE q_t60 CURSOR FOR
	SELECT * FROM talt060
		WHERE t60_compania  = vg_codcia
		  AND t60_localidad = vg_codloc
		  AND t60_ot_nue    = r_t25.t25_orden
OPEN q_t60
FETCH q_t60 INTO rm_t60.*
CLOSE q_t60
FREE q_t60
CALL fl_lee_cabecera_credito_taller(vg_codcia, vg_codloc, rm_t60.t60_ot_nue)
	RETURNING r_t25.*
IF r_t25.t25_compania IS NOT NULL THEN
	RETURN
END IF
CALL sub_menu(0)

END FUNCTION



FUNCTION sub_menu(j)
DEFINE j		SMALLINT
DEFINE resp		CHAR(6)
DEFINE flag,i		SMALLINT
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE flag_error 	SMALLINT

LET entro_cre = 0
CALL fl_lee_configuracion_credito_cxc(vg_codcia, vg_codloc) RETURNING rm_z61.*
LET vm_entro_inp   = 0
INITIALIZE rm_t04.*, rm_t25.t25_orden, rm_t27.t27_orden TO NULL
IF num_args() <> 4 THEN
	LET rm_t25.t25_orden = arg_val(5)
	LET rm_t23.t23_orden = rm_t25.t25_orden
END IF
LET vm_scr_lin           = 0
LET vm_ind_docs          = 0
LET vm_plazo_dia         = rm_z61.z61_dia_entre_pago
LET vm_fec_vcto          = NULL
LET rm_t25.t25_compania  = vg_codcia
LET rm_t25.t25_localidad = vg_codloc
LET rm_t26.t26_compania  = vg_codcia
LET rm_t26.t26_localidad = vg_codloc
LET rm_t27.t27_compania  = vg_codcia
LET rm_t27.t27_localidad = vg_codloc
CALL encerar_totales()
CALL bloqueo_orden() RETURNING flag
IF flag THEN
	IF num_args() = 4 THEN
		CLOSE FORM f_tal
		CLOSE WINDOW wf
	END IF
	ROLLBACK WORK
	RETURN
END IF
IF num_args() <> 4 THEN
	CALL fl_lee_tipo_vehiculo(vg_codcia, rm_t23.t23_modelo)
		RETURNING rm_t04.*
	CALL cargar_cabecera_default()
END IF
CALL control_saldos_vencidos(vg_codcia, rm_t23.t23_cod_cliente, 0)
	RETURNING flag_error
IF flag_error AND j > 0 THEN
	ROLLBACK WORK
	RETURN
END IF
IF vg_codloc > 2 AND j > 0 THEN
	IF NOT tiene_cupo_credito(j) THEN
		LET entro_cre = 1
		ROLLBACK WORK
		RETURN
	END IF
END IF
IF num_args() = 6 THEN
	CALL generacion_credito()
	ROLLBACK WORK
	RETURN
END IF
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
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
	OPEN FORM f_tal FROM "../forms/talf208_2"
ELSE
	OPEN FORM f_tal FROM "../forms/talf208_2c"
END IF
DISPLAY FORM f_tal
CALL mostrar_botones_detalle_cre()
CALL mostrar_registro(rm_t23.t23_orden)
IF rm_t25.t25_orden IS NULL THEN
	CALL cargar_cabecera_default()
ELSE
	CALL cargar_fecha_plazo()
	CALL sacar_total()
	IF num_args() = 4 THEN
		FOR i = 1 TO fgl_scr_size('rm_ta')
			IF i <= rm_t25.t25_dividendos THEN
				DISPLAY rm_ta[i].tit_valor_tot TO
					rm_ta[i].tit_valor_tot
			ELSE
				CLEAR rm_ta[i].tit_valor_tot
			END IF
		END FOR
		DISPLAY BY NAME vm_fec_vcto, vm_plazo_dia
	END IF
END IF
LET vm_plazo_dia          = rm_z61.z61_dia_entre_pago
LET rm_t25.t25_dividendos = rm_z61.z61_num_pagos
LET rm_t25.t25_interes    = rm_z61.z61_intereses
LET vm_fec_vcto           = TODAY + vm_plazo_dia UNITS DAY
CALL calcula_plazo()
DISPLAY BY NAME vm_fec_vcto, vm_plazo_dia, rm_t25.t25_dividendos,
		rm_t25.t25_interes, rm_t25.t25_plazo
MENU 'OPCIONES'
	BEFORE MENU
		SHOW OPTION 'Crédito'
		SHOW OPTION 'Dcto. a Favor'
		SHOW OPTION 'Grabar'
		SHOW OPTION 'Orden de Trabajo'
		IF rm_t25.t25_dividendos > vm_scr_lin THEN
                        SHOW OPTION 'Detalle'
                ELSE
                        HIDE OPTION 'Detalle'
                END IF
       	COMMAND KEY('C') 'Crédito' 'Créditos a un registro corriente. '
		CALL control_creditos()
		IF rm_t25.t25_dividendos > vm_scr_lin THEN
               	        SHOW OPTION 'Detalle'
		ELSE
        		HIDE OPTION 'Detalle'
	        END IF
       	COMMAND KEY('F') 'Dcto. a Favor' 'Documentos a favor del cliente. '
		CALL control_anticipos()
       	COMMAND KEY('G') 'Grabar' 'Graba el cédito del cliente. '
		IF rm_t25.t25_plazo IS NULL THEN
			CALL fl_mostrar_mensaje('Digite forma de pago.', 'stop')
		ELSE
			CALL control_grabar()
			EXIT MENU
		END IF
       	COMMAND KEY('V') 'Orden de Trabajo' 'Ver orden actual. '
		CALL ver_orden()
	COMMAND KEY('D') 'Detalle' 'Muestra siguiente detalles del registro. '
                CALL muestra_detalle_arr()
	COMMAND KEY('S') 'Salir' 'Salir al menú principal. '
		ROLLBACK WORK
		EXIT MENU
END MENU
CLOSE FORM f_tal
CLOSE WINDOW wf

END FUNCTION



FUNCTION generacion_credito()

CALL control_creditos()
CALL control_grabar()

END FUNCTION



FUNCTION bloqueo_orden()

BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_upord CURSOR FOR SELECT * FROM talt023
	WHERE t23_compania  = vg_codcia AND 
	      t23_localidad = vg_codloc AND 
	      t23_orden     = rm_t23.t23_orden
	FOR UPDATE
OPEN q_upord
FETCH q_upord INTO rm_t23.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN 1
END IF
WHENEVER ERROR STOP
IF rm_t23.t23_cod_cliente IS NULL THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Orden de Trabajo no tiene el código del cliente.','exclamation')
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION control_creditos()
DEFINE saldo_vencido, i	SMALLINT
DEFINE num_dias		SMALLINT
DEFINE r_t23		RECORD LIKE talt023.*

CALL validar_saldo_vencido_cliente() RETURNING saldo_vencido
IF NOT saldo_vencido THEN
	CALL encerar_totales()
	IF num_args() = 4 THEN
		CALL leer_cabecera()
	ELSE
		CALL fl_lee_orden_trabajo(rm_t60.t60_compania,
						rm_t60.t60_localidad,
						rm_t60.t60_ot_ant)
			RETURNING r_t23.*
		LET num_dias          = 7
		IF r_t23.t23_cont_cred = 'C' THEN
			LET num_dias  = 1
		END IF
		LET vm_fec_vcto           = TODAY + num_dias UNITS DAY
		LET vm_plazo_dia          = 1
		LET rm_t25.t25_dividendos = rm_z61.z61_num_pagos
		IF r_t23.t23_cont_cred = 'R' THEN
			SELECT NVL(MAX(z20_dividendo), 1)
				INTO rm_t25.t25_dividendos
				FROM cxct020
				WHERE z20_compania  = r_t23.t23_compania
				  AND z20_localidad = r_t23.t23_localidad
				  AND z20_codcli    = r_t23.t23_cod_cliente
				  AND z20_areaneg   = 2
				  AND z20_cod_tran  = 'FA'
				  AND z20_num_tran  = r_t23.t23_num_factura
		END IF
		LET rm_t25.t25_interes    = rm_z61.z61_intereses
		CALL calcula_plazo()
		LET rm_t25.t25_valor_cred = rm_t23.t23_tot_neto
						- rm_t25.t25_valor_ant
	END IF
	IF rm_t25.t25_valor_cred > 0 AND rm_t25.t25_interes = 0
	   AND NOT int_flag AND num_args() = 4
	THEN
		CALL leer_detalle()
	END IF
	IF num_args() <> 4 THEN
		CALL muestra_detalle_default()
		LET vm_entro_inp = 0
		FOR i = 1 TO rm_t25.t25_dividendos
			LET rm_ta_aux[i].* = rm_ta[i].* 
		END FOR
	END IF
END IF
 
END FUNCTION



FUNCTION validar_saldo_vencido_cliente()
DEFINE r_cxc		RECORD LIKE cxct000.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE saldo_venc       LIKE cxct030.z30_saldo_venc
DEFINE moneda		LIKE gent013.g13_moneda

CALL fl_retorna_saldo_vencido(vg_codcia,rm_t23.t23_cod_cliente)
	RETURNING moneda, saldo_venc
IF saldo_venc > 0 THEN
	CALL fl_lee_moneda(moneda) RETURNING r_mon.*
	IF num_args() = 4 THEN
		CALL fl_mostrar_mensaje('El cliente tiene un saldo vencido de ' || saldo_venc || ' en la moneda ' || r_mon.g13_nombre || '.','exclamation')
	END IF
	CALL fl_lee_compania_cobranzas(vg_codcia) RETURNING r_cxc.*
	IF r_cxc.z00_compania IS NULL THEN
		CALL fl_mostrar_mensaje('No existe un registro de configuración para la compañía en cobranzas.','stop')
		EXIT PROGRAM
	END IF
END IF
RETURN 0

END FUNCTION



FUNCTION control_grabar()
DEFINE indice           SMALLINT
DEFINE r_tal		RECORD LIKE talt025.*
DEFINE valor		LIKE cajt010.j10_valor

WHENEVER ERROR STOP
INITIALIZE r_tal.* TO NULL
LET rm_t25.t25_orden     = rm_t23.t23_orden
LET rm_t26.t26_orden     = rm_t23.t23_orden
LET rm_t27.t27_orden     = rm_t23.t23_orden
LET rm_t25.t25_compania  = vg_codcia
LET rm_t25.t25_localidad = vg_codloc
LET rm_t26.t26_compania  = vg_codcia
LET rm_t26.t26_localidad = vg_codloc
LET rm_t27.t27_compania  = vg_codcia
LET rm_t27.t27_localidad = vg_codloc
IF rm_t25.t25_valor_cred > 0 THEN
	LET rm_t23.t23_cont_cred = 'R'
ELSE
	LET rm_t23.t23_cont_cred = 'C'
END IF
CALL sacar_areaneg()
LET valor = rm_t23.t23_tot_neto - rm_t25.t25_valor_ant - rm_t25.t25_valor_cred
CALL fl_lee_cabecera_credito_taller(vg_codcia,vg_codloc,rm_t23.t23_orden)
	RETURNING r_tal.*
IF r_tal.t25_compania IS NULL THEN
	INSERT INTO talt025 VALUES (rm_t25.*)
ELSE
	UPDATE talt025 SET t25_valor_ant  = rm_t25.t25_valor_ant,
			   t25_valor_cred = rm_t25.t25_valor_cred,
			   t25_interes    = rm_t25.t25_interes,
			   t25_dividendos = rm_t25.t25_dividendos,
			   t25_plazo      = rm_t25.t25_plazo
		WHERE t25_compania  = vg_codcia
		  AND t25_localidad = vg_codloc
		  AND t25_orden     = rm_t23.t23_orden
END IF
IF vm_ind_docs > 0 THEN
	DELETE FROM talt027 WHERE t27_compania = vg_codcia
			AND t27_localidad      = vg_codloc
			AND t27_orden          = rm_t27.t27_orden
END IF
DELETE FROM talt026 WHERE t26_compania = vg_codcia
		AND t26_localidad      = vg_codloc
		AND t26_orden          = rm_t26.t26_orden
DELETE FROM cajt010 WHERE j10_compania = vg_codcia
		AND j10_localidad      = vg_codloc
		AND j10_tipo_fuente    = 'OT'
		AND j10_num_fuente     = rm_t23.t23_orden
FOR indice = 1 TO rm_t25.t25_dividendos
	INSERT INTO talt026 VALUES (rm_t26.t26_compania,
		rm_t26.t26_localidad, rm_t26.t26_orden,
		rm_ta[indice].t26_dividendo, rm_ta[indice].t26_valor_cap,
		rm_ta[indice].t26_valor_int, rm_ta[indice].t26_fec_vcto)
END FOR
FOR indice = 1 TO vm_ind_docs
	IF rm_docs[indice].tit_valor_usar > 0 THEN
		INSERT INTO talt027 VALUES (rm_t27.t27_compania,
			rm_t27.t27_localidad, rm_t27.t27_orden,
			rm_docs[indice].t27_tipo, rm_docs[indice].t27_numero,
   		     	rm_docs[indice].tit_valor_usar)
	END IF
END FOR
INSERT INTO cajt010 VALUES(vg_codcia,vg_codloc,'OT',rm_t23.t23_orden,vm_areaneg,
	'A',rm_t23.t23_cod_cliente,rm_t23.t23_nom_cliente,rm_t23.t23_moneda,
	valor,CURRENT,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,vg_usuario,
	CURRENT)
LET int_flag = 0
UPDATE talt023 SET t23_cont_cred = rm_t23.t23_cont_cred
	WHERE CURRENT OF q_upord
COMMIT WORK
IF num_args() = 4 THEN
	CALL fl_mensaje_registro_ingresado()
END IF
WHENEVER ERROR STOP

END FUNCTION



FUNCTION control_anticipos()
DEFINE r_cxc		RECORD LIKE cxct021.*
DEFINE r_ant		RECORD LIKE talt027.*
DEFINE valor_ant_ori	LIKE talt025.t25_valor_ant
DEFINE l		SMALLINT

WHENEVER ERROR STOP
OPEN WINDOW w_ant AT 06, 14 WITH 12 ROWS, 64 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_talf208_3 FROM '../forms/talf208_3'
ELSE
	OPEN FORM f_talf208_3 FROM '../forms/talf208_3c'
END IF
DISPLAY FORM f_talf208_3
CALL mostrar_botones_detalle_ant()
IF rm_t27.t27_orden IS NULL THEN
	LET rm_t27.t27_orden = rm_t23.t23_orden
	CALL sacar_areaneg()
	DECLARE q_ant2 CURSOR FOR SELECT * FROM talt027
		WHERE t27_compania = vg_codcia
		AND t27_localidad  = vg_codloc
		AND t27_orden      = rm_t23.t23_orden
	DECLARE q_ant1 CURSOR FOR SELECT * FROM cxct021
        	        WHERE z21_compania  = vg_codcia
                	  AND z21_localidad = vg_codloc
	                  AND z21_codcli    = rm_t23.t23_cod_cliente
        	          AND z21_areaneg   = vm_areaneg
                	  AND z21_moneda    = rm_t23.t23_moneda
	                  AND z21_saldo     > 0
                ORDER BY z21_fecha_emi
	LET vm_ind_docs = 1
	FOREACH q_ant1 INTO r_cxc.*
		LET rm_docs[vm_ind_docs].t27_tipo       = r_cxc.z21_tipo_doc
		LET rm_docs[vm_ind_docs].t27_numero     = r_cxc.z21_num_doc
		LET rm_docs[vm_ind_docs].z21_moneda     = r_cxc.z21_moneda
		LET rm_docs[vm_ind_docs].z21_fecha_emi  = r_cxc.z21_fecha_emi
		LET rm_docs[vm_ind_docs].t27_valor      = r_cxc.z21_saldo
		LET rm_docs[vm_ind_docs].tit_valor_usar = 0
		LET vm_ind_docs = vm_ind_docs + 1
	        IF vm_ind_docs > vm_max_elm THEN
			CALL fl_mensaje_arreglo_incompleto()
			EXIT PROGRAM
       	        	--EXIT FOREACH
	        END IF
	END FOREACH
	LET vm_ind_docs = vm_ind_docs - 1
	FOREACH q_ant2 INTO r_ant.*
	        FOR l = 1 TO vm_ind_docs
        	        IF rm_docs[l].t27_tipo = r_ant.t27_tipo
 	                AND rm_docs[l].t27_numero = r_ant.t27_numero THEN
	                        LET rm_docs[l].tit_valor_usar = r_ant.t27_valor
        	                EXIT FOR
	                END IF
        	END FOR
	END FOREACH
END IF
CLOSE q_ant1
CLOSE q_ant2
IF vm_ind_docs = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	CLOSE WINDOW w_ant
	RETURN
END IF
FOR l = 1 TO vm_ind_docs
	LET rm_docs_aux[l].* = rm_docs[l].*
END FOR
DISPLAY rm_t23.t23_tot_neto TO tit_neto
LET int_flag = 0
LET valor_ant_ori = rm_t25.t25_valor_ant
CALL leer_anticipos()
CLOSE WINDOW w_ant
IF int_flag THEN
	RETURN
END IF
IF rm_t25.t25_valor_ant <> valor_ant_ori THEN
	IF rm_t25.t25_valor_cred > 0 THEN
		LET rm_t25.t25_valor_cred = rm_t23.t23_tot_neto
						- rm_t25.t25_valor_ant
		CALL muestra_detalle_default()
	END IF
END IF
DISPLAY BY NAME rm_t25.t25_valor_ant, rm_t25.t25_valor_cred
CALL sin_credito()

END FUNCTION



FUNCTION leer_anticipos()
DEFINE resul		SMALLINT
DEFINE resp             CHAR(6)
DEFINE i,j,k		SMALLINT
DEFINE valor		LIKE talt027.t27_valor

OPTIONS INPUT WRAP,
	INSERT KEY F13,
	DELETE KEY F14
LET i = 1
LET resul = 0
LET int_flag = 0
WHILE TRUE
	CALL set_count(vm_ind_docs)
	INPUT ARRAY rm_docs WITHOUT DEFAULTS FROM rm_docs.*
		ON KEY(INTERRUPT)
       			LET int_flag = 0
	               	CALL fl_mensaje_abandonar_proceso()
       		               	RETURNING resp
       			IF resp = 'Yes' THEN
               			LET int_flag = 1
				FOR k = 1 TO vm_ind_docs
					LET rm_docs[k].* = rm_docs_aux[k].*
				END FOR
	        		RETURN
        	       	END IF	
        	ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
		BEFORE INPUT
			--#CALL dialog.keysetlabel("DELETE","")
			--#CALL dialog.keysetlabel("INSERT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		BEFORE ROW
        		LET i = arr_curr()
	       		LET j = scr_line()
			CALL sacar_total_ant() RETURNING resul
		BEFORE INSERT
			EXIT INPUT
		BEFORE FIELD tit_valor_usar
	                LET valor = rm_docs[i].tit_valor_usar
		AFTER FIELD tit_valor_usar
			IF rm_docs[i].tit_valor_usar IS NOT NULL THEN
				IF rm_docs[i].tit_valor_usar
				> rm_docs[i].t27_valor THEN
					--CALL fgl_winmessage(vg_producto,'El valor debe ser menor o igual al saldo','exclamation')
					CALL fl_mostrar_mensaje('El valor debe ser menor o igual al saldo.','exclamation')
					NEXT FIELD tit_valor_usar
				END IF
				CALL fl_retorna_precision_valor(
						rm_t23.t23_moneda,
						rm_docs[i].tit_valor_usar)
	                               	RETURNING rm_docs[i].tit_valor_usar
        	               	DISPLAY rm_docs[i].tit_valor_usar
					TO rm_docs[j].tit_valor_usar
				CALL sacar_total_ant() RETURNING resul
			ELSE
				LET rm_docs[i].tit_valor_usar = valor
				DISPLAY rm_docs[i].tit_valor_usar
					TO rm_docs[j].tit_valor_usar
			END IF
		AFTER INPUT
			CALL sacar_total_ant() RETURNING resul
			IF resul = 1 THEN
				--CALL fgl_winmessage(vg_producto,'El total de anticipos no puede ser mayor que el neto de la orden','exclamation')
				CALL fl_mostrar_mensaje('El total de anticipos no puede ser mayor que el neto de la orden.','exclamation')
				NEXT FIELD tit_valor_usar
			END IF
			EXIT WHILE
	END INPUT
END WHILE

END FUNCTION



FUNCTION leer_cabecera()
DEFINE resp		CHAR(6)
DEFINE orden		LIKE talt023.t23_orden
DEFINE nomcli		LIKE talt023.t23_nom_cliente
DEFINE r_tal		RECORD LIKE talt025.*
DEFINE plazo_dia	LIKE talt025.t25_plazo
DEFINE fec_vcto		DATE
DEFINE i		SMALLINT
DEFINE r_z00		RECORD LIKE cxct000.*
DEFINE r_z02		RECORD LIKE cxct002.*

INITIALIZE orden, plazo_dia, fec_vcto, r_tal.* TO NULL
CALL encerar_totales()
LET int_flag = 0
INPUT BY NAME vm_fec_vcto, vm_plazo_dia, rm_t25.t25_dividendos,
	rm_t25.t25_interes
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF field_touched(vm_fec_vcto, vm_plazo_dia,
			rm_t25.t25_dividendos, rm_t25.t25_interes)
		THEN
               		LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
        	        	RETURNING resp
              		IF resp = 'Yes' THEN
				LET vm_entro_inp = 0
				CALL sacar_total()
				LET vm_fec_vcto           = fec_vcto
				LET vm_plazo_dia          = plazo_dia
				LET rm_t25.t25_dividendos = r_tal.t25_dividendos
				LET rm_t25.t25_interes    = r_tal.t25_interes 
				LET rm_t25.t25_plazo      = r_tal.t25_plazo 
				IF fec_vcto IS NOT NULL THEN
					LET rm_t25.t25_valor_cred =
							r_tal.t25_valor_cred
				ELSE
					LET rm_t25.t25_valor_cred = 0
				END IF
				LET rm_t25.t25_valor_ant  = r_tal.t25_valor_ant 
				DISPLAY BY NAME rm_t23.t23_orden, vm_plazo_dia,
						vm_fec_vcto,
						rm_t25.t25_dividendos,
						rm_t25.t25_interes,
						rm_t25.t25_plazo,
						rm_t25.t25_valor_cred,
						rm_t25.t25_valor_ant
				LET int_flag = 1
				RETURN
                	END IF
		ELSE
			RETURN
		END IF
       	ON KEY(F1,CONTROL-W)
		CALL control_visor_teclas_caracter_1() 
	ON KEY(F6)
		CALL ver_orden()
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
		LET vm_entro_inp = 1
		DISPLAY BY NAME rm_t23.t23_orden
		CALL muestra_cabecera()
		IF rm_t25.t25_valor_cred = 0 THEN
			LET rm_t25.t25_valor_cred = rm_t23.t23_tot_neto
							- rm_t25.t25_valor_ant
			DISPLAY BY NAME rm_t25.t25_valor_cred
		END IF
		LET fec_vcto             = vm_fec_vcto
		LET plazo_dia	         = vm_plazo_dia
		LET r_tal.t25_dividendos = rm_t25.t25_dividendos
		LET r_tal.t25_interes    = rm_t25.t25_interes 
		LET r_tal.t25_plazo      = rm_t25.t25_plazo 
		LET r_tal.t25_valor_cred = rm_t25.t25_valor_cred
		LET r_tal.t25_valor_ant  = rm_t25.t25_valor_ant 
	AFTER FIELD vm_fec_vcto
		IF vm_fec_vcto IS NOT NULL THEN
			IF vm_fec_vcto < TODAY + 1 THEN
				--CALL fgl_winmessage(vg_producto,'Esta fecha no es válida. Mínimo un día más que la fecha de hoy','exclamation')
				CALL fl_mostrar_mensaje('Esta fecha no es válida. Mínimo un día más que la fecha de hoy.','exclamation')
				NEXT FIELD vm_fec_vcto
			END IF
		ELSE
			LET vm_fec_vcto = fec_vcto
			DISPLAY BY NAME vm_fec_vcto
		END IF
	AFTER FIELD vm_plazo_dia
		IF vm_plazo_dia IS NULL THEN
			LET vm_plazo_dia = plazo_dia
			DISPLAY BY NAME vm_plazo_dia
		END IF
	AFTER FIELD t25_dividendos
		IF rm_t25.t25_dividendos IS NULL THEN
			LET rm_t25.t25_dividendos = r_tal.t25_dividendos
			DISPLAY BY NAME rm_t25.t25_dividendos
		END IF
	AFTER FIELD t25_interes
		IF rm_t25.t25_interes IS NULL THEN
			LET rm_t25.t25_interes = r_tal.t25_interes
			DISPLAY BY NAME rm_t25.t25_interes
		END IF
	AFTER INPUT 
		IF rm_t25.t25_dividendos = 0 THEN
			LET rm_t25.t25_valor_cred = 0
			CALL sin_credito()
			CALL encerar_totales()
			CALL mostrar_total()
			RETURN
		END IF
		IF vm_fec_vcto IS NULL THEN
			CALL fl_mostrar_mensaje('Digíte la fecha de vencimiento del primer pago.','exclamation')
			NEXT FIELD vm_fec_vcto
		END IF
		IF vm_plazo_dia > 0 THEN
			CALL calcula_plazo()
			DISPLAY BY NAME rm_t25.t25_plazo
		ELSE
			CALL fl_mostrar_mensaje('Especifique días dividendos para los pagos.','exclamation')
			NEXT FIELD vm_plazo_dia
		END IF
		IF (fec_vcto <> vm_fec_vcto OR plazo_dia <> vm_plazo_dia
		OR r_tal.t25_dividendos <> rm_t25.t25_dividendos
		OR r_tal.t25_interes <> rm_t25.t25_interes)
		OR rm_ta[1].t26_dividendo IS NULL THEN
			CALL muestra_detalle_default()
		END IF
		LET vm_entro_inp = 0
		FOR i = 1 TO rm_t25.t25_dividendos
			LET rm_ta_aux[i].* = rm_ta[i].* 
		END FOR
		CALL fl_lee_compania_cobranzas(vg_codcia) RETURNING r_z00.* 
		IF r_z00.z00_bloq_vencido = 'S' THEN
			--IF vg_codloc = 3 OR vg_codloc = 4 OR vg_codloc = 5 THEN
				CALL fl_lee_cliente_localidad(vg_codcia,
							vg_codloc,
							rm_t23.t23_cod_cliente)
					RETURNING r_z02.*
				IF vm_plazo_dia > r_z02.z02_credit_dias THEN
					CALL fl_mostrar_mensaje('El plazo de crédito no puede ser mayor al límite de días crédito del cliente.', 'exclamation')
					NEXT FIELD vm_plazo_dia
				END IF
			--END IF
		END IF
		IF rm_t25.t25_dividendos > rm_z61.z61_max_pagos THEN
			CALL fl_mostrar_mensaje('El número de pagos no puede ser mayor al maximo de pagos.', 'exclamation')
			NEXT FIELD t25_dividendos
		END IF
		IF vm_plazo_dia > rm_z61.z61_max_entre_pago THEN
			CALL fl_mostrar_mensaje('Los días entre pagos no puede ser mayor al maximo de días para los pagos.', 'exclamation')
			NEXT FIELD vm_plazo_dia
		END IF
		IF rm_t25.t25_interes > rm_z61.z61_intereses THEN
			CALL fl_mostrar_mensaje('El porcentaje de interés no puede ser mayor al maximo porcentaje de interés.', 'exclamation')
			NEXT FIELD t25_interes
		END IF
END INPUT

END FUNCTION



FUNCTION cargar_cabecera_default()
DEFINE r_loc		RECORD LIKE cxct002.*
DEFINE r_are		RECORD LIKE cxct003.*
DEFINE num_reg		INTEGER

LET rm_t25.t25_valor_ant  = 0
LET rm_t25.t25_interes    = 0
LET rm_t25.t25_dividendos = 0
LET rm_t25.t25_plazo 	  = 0
CALL fl_lee_cliente_localidad(vg_codcia,vg_codloc,rm_t23.t23_cod_cliente)
	RETURNING r_loc.*
LET num_reg = 0
SELECT COUNT(*) INTO num_reg FROM talt026
	WHERE t26_compania = vg_codcia
	AND t26_localidad  = vg_codloc
	AND t26_orden      = rm_t23.t23_orden
IF num_reg <> 0 THEN
	CALL cargar_fecha_plazo()
ELSE
	IF r_loc.z02_credit_dias > 0 THEN
		LET rm_t25.t25_plazo = r_loc.z02_credit_dias  
	ELSE
		CALL sacar_areaneg()
		CALL fl_lee_cliente_areaneg(vg_codcia,vg_codloc,
				vm_areaneg,rm_t23.t23_cod_cliente)
			RETURNING r_are.*
		LET rm_t25.t25_plazo = r_are.z03_credit_dias
	END IF
	LET vm_plazo_dia = 0
	LET vm_fec_vcto  = NULL
END IF
IF num_reg = 0 THEN
	LET rm_t25.t25_valor_cred = 0
END IF
CALL muestra_cabecera()

END FUNCTION



FUNCTION cargar_fecha_plazo()
DEFINE r_tal2		RECORD LIKE talt026.*
DEFINE i		SMALLINT

DECLARE q_ant3 CURSOR FOR SELECT * FROM talt026
	WHERE t26_compania = vg_codcia
	AND t26_localidad  = vg_codloc
	AND t26_orden      = rm_t23.t23_orden
LET i = 1
LET vm_fec_vcto = NULL 
FOREACH q_ant3 INTO r_tal2.*
	IF i = 1 THEN
		LET vm_fec_vcto  = r_tal2.t26_fec_vcto
		LET vm_plazo_dia = rm_t25.t25_dividendos
	ELSE
		LET vm_plazo_dia = r_tal2.t26_fec_vcto - vm_fec_vcto
		EXIT FOREACH
	END IF
	LET i = i + 1
END FOREACH

END FUNCTION



FUNCTION muestra_cabecera()

CALL fl_lee_tipo_vehiculo(vg_codcia,rm_t23.t23_modelo) RETURNING rm_t04.*
CALL fl_retorna_precision_valor(rm_t23.t23_moneda,rm_t25.t25_valor_ant)
	RETURNING rm_t25.t25_valor_ant
CALL fl_retorna_precision_valor(rm_t23.t23_moneda,rm_t25.t25_valor_cred)
	RETURNING rm_t25.t25_valor_cred
IF num_args() <> 4 THEN
	RETURN
END IF
DISPLAY rm_t23.t23_estado TO tit_est
DISPLAY 'CERRADA' TO tit_estado
DISPLAY rm_t23.t23_modelo TO tit_modelo
DISPLAY rm_t04.t04_linea TO tit_linea
DISPLAY rm_t23.t23_nom_cliente TO tit_cliente
DISPLAY rm_t23.t23_tot_neto TO tit_neto_cre
DISPLAY BY NAME vm_fec_vcto, vm_plazo_dia, rm_t25.t25_plazo,
		rm_t25.t25_valor_cred, rm_t25.t25_valor_ant, rm_t25.t25_interes,
		rm_t25.t25_dividendos 

END FUNCTION



FUNCTION calcula_plazo()

LET rm_t25.t25_plazo = (vm_fec_vcto - TODAY) + ((rm_t25.t25_dividendos - 1) *
			vm_plazo_dia)

END FUNCTION



FUNCTION sacar_areaneg()
DEFINE r_lin		RECORD LIKE talt001.*
DEFINE r_grp		RECORD LIKE gent020.*

CALL fl_lee_linea_taller(vg_codcia,rm_t04.t04_linea)
	RETURNING r_lin.*
CALL fl_lee_grupo_linea(vg_codcia,r_lin.t01_grupo_linea)
	RETURNING r_grp.*
IF r_grp.g20_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No hay línea de venta en Taller.','stop')
	EXIT PROGRAM
END IF
LET vm_areaneg = r_grp.g20_areaneg

END FUNCTION



FUNCTION muestra_detalle_default()
DEFINE i, ind		SMALLINT
DEFINE fecha		DATE
DEFINE query		CHAR(300)

LET rm_ta[1].t26_fec_vcto = vm_fec_vcto 
FOR i = 1 TO rm_t25.t25_dividendos
	LET rm_ta[i].t26_dividendo = i
	IF num_args() <> 6 THEN
		IF i < rm_t25.t25_dividendos THEN
			LET rm_ta[i + 1].t26_fec_vcto = rm_ta[i].t26_fec_vcto
							+ vm_plazo_dia
		END IF
	ELSE
		LET query = 'SELECT t26_fec_vcto ',
				' FROM talt026 ',
				' WHERE t26_compania  = ', rm_t60.t60_compania,
				'   AND t26_localidad = ', rm_t60.t60_localidad,
				'   AND t26_orden     = ', rm_t60.t60_ot_ant,
				'   AND t26_dividendo = ', i
		PREPARE cons_t26_ant FROM query
		DECLARE q_t26_ant CURSOR FOR cons_t26_ant
		OPEN q_t26_ant
		FETCH q_t26_ant INTO fecha
		IF STATUS = NOTFOUND THEN
			LET rm_ta[i].t26_fec_vcto = vm_fec_vcto
		ELSE
			IF fecha > TODAY THEN
				LET rm_ta[i].t26_fec_vcto = fecha
			ELSE
				LET rm_ta[i].t26_fec_vcto = TODAY + 1 UNITS DAY
			END IF
		END IF
		CLOSE q_t26_ant
		FREE q_t26_ant
	END IF
	LET rm_ta[i].t26_valor_cap = rm_t25.t25_valor_cred/rm_t25.t25_dividendos
	IF rm_t25.t25_interes > 0 THEN
		CALL calculo_valor_interes(i)
	ELSE
		LET rm_ta[i].t26_valor_int = rm_t25.t25_interes 
	END IF
	CALL fl_retorna_precision_valor(rm_t23.t23_moneda,
					rm_ta[i].t26_valor_cap)
        	RETURNING rm_ta[i].t26_valor_cap
	CALL fl_retorna_precision_valor(rm_t23.t23_moneda,
					rm_ta[i].t26_valor_int)
        	RETURNING rm_ta[i].t26_valor_int
END FOR
CALL sacar_total()
LET ind = rm_t25.t25_dividendos
LET rm_ta[ind].t26_valor_cap =  rm_ta[ind].t26_valor_cap + rm_t25.t25_valor_cred
				- vm_total_cap 
CALL sacar_total()
IF num_args() <> 4 THEN
	RETURN
END IF
CALL muestra_lineas_detalle()
CALL mostrar_total()

END FUNCTION



FUNCTION calculo_valor_interes(lim)
DEFINE lim,i		SMALLINT
DEFINE valor_cap_acum	LIKE talt026.t26_valor_cap

LET valor_cap_acum = 0
FOR i = 1 TO lim - 1
	LET valor_cap_acum = valor_cap_acum + rm_ta[i].t26_valor_cap
END FOR
LET rm_ta[lim].t26_valor_int = (rm_t25.t25_valor_cred - valor_cap_acum)
				* (rm_t25.t25_interes / 100)
				* (vm_plazo_dia / 360)

END FUNCTION



FUNCTION leer_detalle()
DEFINE resul		SMALLINT
DEFINE resp             CHAR(6)
DEFINE i,j,k		SMALLINT
DEFINE fec_vcto		LIKE talt026.t26_fec_vcto
DEFINE valor_cap	LIKE talt026.t26_valor_cap

OPTIONS INPUT WRAP,
	INSERT KEY F13,
	DELETE KEY F14
LET i = 1
LET resul = 0
CALL encerar_totales()
LET int_flag = 0
WHILE TRUE
	CALL set_count(rm_t25.t25_dividendos)
	INPUT ARRAY rm_ta WITHOUT DEFAULTS FROM rm_ta.*
		ON KEY(INTERRUPT)
       			LET int_flag = 0
	               	CALL fl_mensaje_abandonar_proceso()
       		               	RETURNING resp
       			IF resp = 'Yes' THEN
				FOR k = 1 TO rm_t25.t25_dividendos
					LET rm_ta[k].*  = rm_ta_aux[k].*
				END FOR
				CALL muestra_lineas_detalle()
               			LET int_flag = 1
	        		RETURN 
        	       	END IF	
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_1() 
		ON KEY(F6)
			CALL ver_orden()
		BEFORE INPUT
			--#CALL dialog.keysetlabel("DELETE","")
			--#CALL dialog.keysetlabel("INSERT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
			LET vm_scr_lin = fgl_scr_size('rm_ta')
		BEFORE ROW
        		LET i = arr_curr()
       			LET j = scr_line()
			CALL sacar_total()
		BEFORE INSERT
			EXIT INPUT
		BEFORE FIELD t26_fec_vcto
                	LET fec_vcto = rm_ta[i].t26_fec_vcto
		BEFORE FIELD t26_valor_cap
        	        LET valor_cap = rm_ta[i].t26_valor_cap
		AFTER FIELD t26_fec_vcto
			IF rm_ta[i].t26_fec_vcto IS NOT NULL THEN
				IF rm_ta[i].t26_fec_vcto < TODAY + 1 THEN
					--CALL fgl_winmessage(vg_producto,'Esta fecha no es válida. Mínimo un día más que la fecha de hoy','exclamation')
					CALL fl_mostrar_mensaje('Esta fecha no es válida. Mínimo un día más que la fecha de hoy.','exclamation')
					NEXT FIELD t26_fec_vcto
				END IF
			ELSE
				LET rm_ta[i].t26_fec_vcto = fec_vcto
				DISPLAY rm_ta[i].t26_fec_vcto
					TO rm_ta[j].t26_fec_vcto
	        	END IF
		AFTER FIELD t26_valor_cap
			IF rm_ta[i].t26_valor_cap IS NOT NULL THEN
				CALL fl_retorna_precision_valor(
							rm_t23.t23_moneda,
							rm_ta[i].t26_valor_cap)
	                               	RETURNING rm_ta[i].t26_valor_cap
        	               	DISPLAY rm_ta[i].t26_valor_cap
					TO rm_ta[j].t26_valor_cap
				CALL sacar_total()
			ELSE
				LET rm_ta[i].t26_valor_cap = valor_cap
				DISPLAY rm_ta[i].t26_valor_cap
					TO rm_ta[j].t26_valor_cap
			END IF
			DISPLAY rm_ta[i].tit_valor_tot
				TO rm_ta[j].tit_valor_tot
		AFTER INPUT
			CALL sacar_total()
			CALL validar_campos() RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD t26_fec_vcto
			END IF
			IF resul = 2 THEN
				NEXT FIELD t26_valor_cap
			END IF
			EXIT WHILE
	END INPUT
END WHILE
RETURN

END FUNCTION



FUNCTION validar_campos()
DEFINE i,j		SMALLINT

IF vm_total_cap <> rm_t25.t25_valor_cred THEN
	--CALL fgl_winmessage(vg_producto,'Existen valores de capital no válidos, corrijalos','exclamation')
	CALL fl_mostrar_mensaje('Existen valores de capital no válidos, corrijalos.','exclamation')
	RETURN 2
END IF
LET j = rm_t25.t25_dividendos - 1
FOR i = 1 TO j
	IF rm_ta[i].t26_fec_vcto >= rm_ta[i + 1].t26_fec_vcto THEN
		--CALL fgl_winmessage(vg_producto,'Existen fechas de dividendos no válidas, corrijalas','exclamation')
		CALL fl_mostrar_mensaje('Existen fechas de dividendos no válidas, corrijalas.','exclamation')
		RETURN 1
	END IF
END FOR
LET rm_t25.t25_plazo = rm_ta[j + 1].t26_fec_vcto - TODAY
LET vm_fec_vcto      = rm_ta[1].t26_fec_vcto
DISPLAY BY NAME vm_fec_vcto, rm_t25.t25_plazo
RETURN 0

END FUNCTION



FUNCTION sin_credito()
DEFINE l		SMALLINT

IF rm_t25.t25_valor_cred = 0 THEN
	FOR l = 1 TO vm_scr_lin
		INITIALIZE rm_ta[l].* TO NULL
		CLEAR rm_ta[l].*
	END FOR
	LET rm_t25.t25_dividendos = 0
	LET rm_t25.t25_plazo      = 0
	LET rm_t25.t25_interes    = 0
	LET vm_plazo_dia          = 0
	LET vm_fec_vcto           = NULL
	DISPLAY BY NAME rm_t25.t25_dividendos, vm_fec_vcto, rm_t25.t25_plazo,
			rm_t25.t25_interes, vm_plazo_dia, rm_t25.t25_valor_cred
END IF

END FUNCTION



FUNCTION sacar_total_ant()
DEFINE i		SMALLINT

LET rm_t25.t25_valor_ant = 0
FOR i = 1 TO vm_ind_docs
	LET rm_t25.t25_valor_ant = rm_t25.t25_valor_ant
					+ rm_docs[i].tit_valor_usar
END FOR
DISPLAY rm_t25.t25_valor_ant TO t25_valor_ant
IF rm_t25.t25_valor_ant > rm_t23.t23_tot_neto THEN
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION sacar_total()
DEFINE i		SMALLINT

CALL encerar_totales()
FOR i = 1 TO rm_t25.t25_dividendos
	CALL sumar_totales(i)
END FOR
IF num_args() = 4 THEN
	CALL mostrar_total()
END IF

END FUNCTION



FUNCTION encerar_totales()

LET vm_total_cap = 0
LET vm_total_int = 0
LET vm_total_gen = 0

END FUNCTION



FUNCTION sumar_totales(i)
DEFINE i		SMALLINT

LET rm_ta[i].tit_valor_tot = rm_ta[i].t26_valor_cap + rm_ta[i].t26_valor_int
CALL fl_retorna_precision_valor(rm_t23.t23_moneda,rm_ta[i].tit_valor_tot)
	RETURNING rm_ta[i].tit_valor_tot
LET vm_total_cap = vm_total_cap + rm_ta[i].t26_valor_cap
LET vm_total_int = vm_total_int + rm_ta[i].t26_valor_int
LET vm_total_gen = vm_total_gen + rm_ta[i].tit_valor_tot

END FUNCTION



FUNCTION ver_orden()
DEFINE run_prog		CHAR(10)

IF rm_t23.t23_orden IS NULL THEN
        CALL fl_mensaje_consultar_primero()
        RETURN
END IF
{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'TALLER',
	vg_separador, 'fuentes', vg_separador, run_prog, 'talp204 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ', rm_t23.t23_orden,
	' ', 'O'
RUN vm_nuevoprog

END FUNCTION



FUNCTION mostrar_registro(num_orden)
DEFINE num_orden	LIKE talt023.t23_orden

LET rm_t25.t25_interes    = 0
LET rm_t25.t25_dividendos = 1
CALL fl_lee_cabecera_credito_taller(vg_codcia, vg_codloc, num_orden)
	RETURNING rm_t25.*
IF num_args() = 4 THEN
	DISPLAY num_orden TO t23_orden
END IF
CALL muestra_cabecera()
CALL muestra_detalle(num_orden)

END FUNCTION



FUNCTION muestra_detalle(num_reg)
DEFINE num_reg          LIKE talt023.t23_orden
DEFINE query            CHAR(400)
DEFINE i  		SMALLINT

LET vm_scr_lin = fgl_scr_size('rm_ta')
LET int_flag = 0
FOR i = 1 TO vm_scr_lin
        INITIALIZE rm_ta[i].* TO NULL
	IF num_args() = 4 THEN
	        CLEAR rm_ta[i].*
	END IF
END FOR
LET i = 1
LET query = 'SELECT t26_dividendo,t26_fec_vcto,t26_valor_cap,t26_valor_int ',
		'FROM talt026 ',
                'WHERE t26_compania = ', vg_codcia,
		' AND t26_localidad = ', vg_codloc,
		' AND t26_orden = ', num_reg,
		' ORDER BY 1' 
PREPARE cons1 FROM query
DECLARE q_cons1 CURSOR FOR cons1
LET rm_t25.t25_dividendos = 0
FOREACH q_cons1 INTO rm_ta[i].*
        LET rm_t25.t25_dividendos = rm_t25.t25_dividendos + 1
        LET i = i + 1
        IF rm_t25.t25_dividendos > vm_max_elm THEN
        	LET rm_t25.t25_dividendos = rm_t25.t25_dividendos - 1
		CALL fl_mensaje_arreglo_incompleto()
		EXIT PROGRAM
                --EXIT FOREACH
        END IF
END FOREACH
IF rm_t25.t25_dividendos > 0 AND num_args() = 4 THEN
        LET int_flag = 0
	CALL muestra_lineas_detalle()
END IF
CALL sacar_total()
IF int_flag THEN
        RETURN
END IF
CALL set_count(rm_t25.t25_dividendos)

END FUNCTION



FUNCTION muestra_lineas_detalle()
DEFINE i		SMALLINT
DEFINE lineas		SMALLINT

LET lineas = fgl_scr_size('rm_ta')
FOR i = 1 TO lineas
	IF i <= rm_t25.t25_dividendos THEN
		DISPLAY rm_ta[i].* TO rm_ta[i].*
	ELSE
		CLEAR rm_ta[i].*
	END IF
END FOR

END FUNCTION



FUNCTION muestra_detalle_arr()
DEFINE i,j		SMALLINT

LET vm_scr_lin = fgl_scr_size('rm_ta')
CALL set_count(rm_t25.t25_dividendos)
DISPLAY ARRAY rm_ta TO rm_ta.*
	ON KEY(INTERRUPT)
		EXIT DISPLAY
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	--#BEFORE ROW
		--#LET i = arr_curr()
        	--#LET j = scr_line()
		--#DISPLAY rm_ta[i].tit_valor_tot TO rm_ta[j].tit_valor_tot
	--#BEFORE DISPLAY
		--#LET vm_scr_lin = fgl_scr_size('rm_ta')
		--#CALL dialog.keysetlabel("ACCEPT","")
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	--#AFTER DISPLAY
		--#CONTINUE DISPLAY
END DISPLAY

END FUNCTION



FUNCTION mostrar_total()

DISPLAY vm_total_cap TO tit_total_cap
DISPLAY vm_total_int TO tit_total_int
DISPLAY vm_total_gen TO tit_total_gen

END FUNCTION



FUNCTION muestra_contadores(cor,num)
DEFINE cor,num	         SMALLINT
                                                                                
IF vg_gui = 1 THEN
	DISPLAY "" AT 19,1
	DISPLAY cor, " de ", num AT 19, 4
END IF
                                                                                
END FUNCTION



FUNCTION mostrar_botones_detalle_cre()

--#DISPLAY 'No.'           TO tit_col1
--#DISPLAY 'Fec. Vcto.'    TO tit_col2
--#DISPLAY 'Valor Capital' TO tit_col3
--#DISPLAY 'Valor Interés' TO tit_col4
--#DISPLAY 'Valor Total'   TO tit_col5

END FUNCTION
                                                                                
                                                                                
                                                                                
FUNCTION mostrar_botones_detalle_ant()

--#DISPLAY 'Tipo Documento'   TO tit_col6
--#DISPLAY 'Mon'              TO tit_col7
--#DISPLAY 'Fecha Emi.'       TO tit_col8
--#DISPLAY 'Saldo Documento'  TO tit_col9
--#DISPLAY 'Valor a Utilizar' TO tit_col10

END FUNCTION



FUNCTION control_saldos_vencidos(codcia, codcli, flag_mens)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codcli		LIKE cxct001.z01_codcli
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE valor		DECIMAL(14,2)
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_z00		RECORD LIKE cxct000.*
DEFINE r_z02		RECORD LIKE cxct002.*
DEFINE mensaje		VARCHAR(180)
DEFINE flag_error 	SMALLINT
DEFINE flag_mens 	SMALLINT
DEFINE icono		CHAR(20)
DEFINE mens		CHAR(20)

LET icono = 'exclamation'
LET mens  = 'Lo siento, esta'
IF flag_mens THEN
	LET icono = 'info'
	LET mens  = 'Esta'
END IF
CALL fl_retorna_saldo_vencido(codcia, codcli) RETURNING moneda, valor
LET flag_error = 0
IF valor > 0 THEN
	CALL fl_lee_moneda(moneda) RETURNING r_g13.*
	LET mensaje = 'El cliente tiene un saldo vencido de ', valor, ' en ',
			'la moneda ', r_g13.g13_nombre CLIPPED, '.'
	IF num_args() = 4 THEN
		CALL fl_mostrar_mensaje(mensaje, icono)
	END IF
	CALL fl_lee_compania_cobranzas(codcia) RETURNING r_z00.* 
	IF r_z00.z00_bloq_vencido = 'S' THEN
		CALL fl_mostrar_mensaje(mens CLIPPED || ' activo el bloqueo de proformar y facturar a clientes con saldos vencidos. El cliente debera cancelar sus deudas.', icono)
		LET flag_error = 1
		--IF vg_codloc = 3 OR vg_codloc = 4 OR vg_codloc = 5 THEN
			CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc,
							codcli)
				RETURNING r_z02.*
			IF r_z02.z02_credit_dias > 0 THEN
				LET flag_error = 0
			END IF
		--END IF
	END IF
END IF
RETURN flag_error

END FUNCTION



FUNCTION tiene_cupo_credito(i)
DEFINE i		SMALLINT
DEFINE r_cli		RECORD
				codcli		LIKE cxct001.z01_codcli,
				nomcli		LIKE cxct001.z01_nomcli,
				locali		LIKE gent002.g02_localidad,
				tot_pven 	DECIMAL(12,2),
				tot_venc 	DECIMAL(12,2),
				tot_saldo 	DECIMAL(12,2)
			END RECORD
DEFINE r_z02		RECORD LIKE cxct002.*
DEFINE mensaje		CHAR(500)
DEFINE resul		SMALLINT
DEFINE cred_aprob	DECIMAL(12,2)
DEFINE valor_cred	DECIMAL(12,2)
DEFINE query		CHAR(800)

CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc, rm_t23.t23_cod_cliente)
	RETURNING r_z02.*
IF r_z02.z02_credit_dias < 1 THEN
	CALL fl_mostrar_mensaje('NO SE PUEDE PROCESAR ESTE CREDITO PORQUE EL CLIENTE NO TIENE DIAS DE CREDITO.', 'exclamation')
	RETURN 0
END IF
IF NOT genera_tabla_trabajo_detalle() THEN
	DELETE FROM tempo_doc
	DROP TABLE tmp_mov
	RETURN 1
END IF
IF NOT genera_tabla_trabajo_resumen() THEN
	DELETE FROM tempo_doc
	DROP TABLE tmp_mov
	RETURN 1
END IF
CALL muestra_resumen_clientes() RETURNING resul, r_cli.*
DELETE FROM tempo_doc
DROP TABLE tmp_mov
IF resul THEN
	RETURN 1
END IF
CALL fl_lee_cliente_localidad(vg_codcia, r_cli.locali, r_cli.codcli)
	RETURNING r_z02.*
LET query = 'SELECT NVL(SUM(r25_valor_cred), 0) val_c ',
		'FROM rept023, rept025 ',
		'WHERE r23_compania   = ', vg_codcia,
		'  AND r23_localidad  = ', vg_codloc,
		'  AND r23_codcli     = ', r_cli.codcli,
		'  AND r23_estado     = "P" ',
		'  AND r23_cod_tran  IS NULL ',
		'  AND r25_compania   = r23_compania ',
		'  AND r25_localidad  = r23_localidad ',
		'  AND r25_numprev    = r23_numprev ',
		'  AND r25_cod_tran  IS NULL ',
		'UNION ',
		'SELECT NVL(SUM(t25_valor_cred), 0) val_c ',
		'FROM talt023, talt025 ',
		'WHERE t23_compania     = ', vg_codcia,
		'  AND t23_localidad    = ', vg_codloc,
		'  AND t23_orden       <> ', rm_deto[i].t23_orden,
		'  AND t23_cod_cliente  = ', r_cli.codcli,
		'  AND t23_estado      IN ("A", "C") ',
		'  AND t25_compania     = t23_compania ',
		'  AND t25_localidad    = t23_localidad ',
		'  AND t25_orden        = t23_orden ',
		'INTO TEMP t1 '
PREPARE exec_t1 FROM query
EXECUTE exec_t1
LET cred_aprob = 0
SELECT NVL(SUM(val_c), 0)
	INTO cred_aprob
	FROM t1
DROP TABLE t1
LET valor_cred = (r_z02.z02_cupcred_aprob - r_cli.tot_saldo) -
			(cred_aprob + rm_deto[i].t23_tot_neto)
IF (cred_aprob + rm_deto[i].t23_tot_neto) >
   (r_z02.z02_cupcred_aprob - r_cli.tot_saldo)
THEN
	LET mensaje = 'El cliente tiene SALDO DEUDOR de:           ',
		r_cli.tot_saldo USING "#,###,##&.&&",
		'\n\nEl CREDITO que se solicita es de:               ',
		rm_deto[i].t23_tot_neto USING "#,###,##&.&&"
	IF cred_aprob > 0 THEN
		LET mensaje = mensaje CLIPPED,
			'\n\nTiene créditos ya aprobados de:                ',
			cred_aprob USING "#,###,##&.&&"
	END IF
	LET mensaje = mensaje CLIPPED,
		'\n\nEl monto total de su DEUDA sería de:        ',
		(r_cli.tot_saldo + rm_deto[i].t23_tot_neto + cred_aprob)
		USING "#,###,##&.&&",
		'\n\nEl cliente tiene un CUPO DE CREDITO de: ',
		r_z02.z02_cupcred_aprob USING "#,###,##&.&&",
		'\n\ny el crédito solicitado excede el CUPO en:  ',
		valor_cred USING "#,###,##&.&&"
	CALL fl_mostrar_mensaje(mensaje, 'exclamation')
	CALL fl_mostrar_mensaje('NO SE PUEDE PROCESAR ESTE CREDITO.', 'exclamation')
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION genera_tabla_trabajo_detalle()
DEFINE fecha		LIKE cxct022.z22_fecing
DEFINE query		CHAR(4500)
DEFINE subquery1	CHAR(1500)
DEFINE subquery2	CHAR(500)
DEFINE num_doc		INTEGER

ERROR "Procesando documentos con saldos . . . espere por favor." ATTRIBUTE(NORMAL)
LET query = 'SELECT cxct020.* ',
		' FROM cxct020 ',
		' WHERE z20_compania   = ', vg_codcia,
		'   AND z20_codcli     = ', rm_t23.t23_cod_cliente,
		'   AND z20_fecha_emi <= TODAY ',
		' INTO TEMP tmp_z20 '
PREPARE cons_z20 FROM query
EXECUTE cons_z20
LET fecha = EXTEND(TODAY, YEAR TO SECOND) + 23 UNITS HOUR +
		59 UNITS MINUTE + 59 UNITS SECOND
LET subquery1 = '(SELECT z23_valor_cap + z23_valor_int + z23_saldo_cap + ',
			'z23_saldo_int ',
		' FROM cxct023, cxct022 ',
		' WHERE z23_compania  = z20_compania ',
		'   AND z23_localidad = z20_localidad ',
		'   AND z23_codcli    = z20_codcli ',
		'   AND z23_tipo_doc  = z20_tipo_doc ',
		'   AND z23_num_doc   = z20_num_doc ',
		'   AND z23_div_doc   = z20_dividendo ',
		'   AND z22_compania  = z23_compania ',
		'   AND z22_localidad = z23_localidad ',
		'   AND z22_codcli    = z23_codcli ',
		'   AND z22_tipo_trn  = z23_tipo_trn ',
		'   AND z22_num_trn   = z23_num_trn ',
		'   AND z22_fecing    = (SELECT MAX(z22_fecing) ',
					' FROM cxct023, cxct022 ',
					' WHERE z23_compania  = z20_compania ',
					'   AND z23_localidad = z20_localidad ',
					'   AND z23_codcli    = z20_codcli ',
					'   AND z23_tipo_doc  = z20_tipo_doc ',
					'   AND z23_num_doc   = z20_num_doc ',
					'   AND z23_div_doc   = z20_dividendo ',
					'   AND z22_compania  = z23_compania ',
					'   AND z22_localidad = z23_localidad ',
					'   AND z22_codcli    = z23_codcli ',
					'   AND z22_tipo_trn  = z23_tipo_trn ',
					'   AND z22_num_trn   = z23_num_trn ',
					'   AND z22_fecing   <= "', fecha, '"))'
LET subquery2 = ' (SELECT NVL(SUM(z23_valor_cap + z23_valor_int), 0) ',
		' FROM cxct023 ',
		' WHERE z23_compania  = z20_compania ',
		'   AND z23_localidad = z20_localidad ',
		'   AND z23_codcli    = z20_codcli ',
		'   AND z23_tipo_doc  = z20_tipo_doc ',
		'   AND z23_num_doc   = z20_num_doc ',
		'   AND z23_div_doc   = z20_dividendo) '
LET query = ' SELECT g02_nombre, z20_localidad, z20_codcli, z20_tipo_doc, ',
			'z20_num_doc, z20_dividendo, z01_nomcli, ',
			'z20_fecha_emi, z20_fecha_vcto, ',
			'(z20_valor_cap + z20_valor_int) valor_doc, ',
			' NVL(', subquery1 CLIPPED, ', ',
			' CASE WHEN z20_fecha_emi <= TODAY ',
				' THEN z20_saldo_cap + z20_saldo_int - ',
					subquery2 CLIPPED,
				' ELSE z20_valor_cap + z20_valor_int',
			' END) valor_mov, z20_areaneg area_n, ',
			'z20_cod_tran cod_tran, z20_num_tran num_tran ',
		' FROM tmp_z20, gent002, cxct001 ',
		' WHERE g02_compania   = z20_compania ',
		'   AND g02_localidad  = z20_localidad ',
		'   AND z01_codcli     = z20_codcli ',
		' INTO TEMP tmp_mov '
PREPARE stmnt1 FROM query
EXECUTE stmnt1
DROP TABLE tmp_z20
DELETE FROM tmp_mov WHERE valor_mov = 0
SELECT COUNT(*) INTO num_doc FROM tmp_mov 
ERROR ' '
IF num_doc = 0 THEN
	RETURN 0
END IF
CALL obtener_documentos_a_favor()
RETURN 1

END FUNCTION



FUNCTION obtener_documentos_a_favor()
DEFINE fecha		LIKE cxct022.z22_fecing
DEFINE query		CHAR(6000)
DEFINE subquery1	CHAR(1000)
DEFINE subquery2	CHAR(400)
DEFINE num_fav		INTEGER

ERROR "Procesando documentos a favor con saldos . . . espere por favor." ATTRIBUTE(NORMAL)
LET query = 'SELECT cxct021.* ',
		' FROM cxct021 ',
		' WHERE z21_compania   = ', vg_codcia,
		'   AND z21_codcli     = ', rm_t23.t23_cod_cliente,
		'   AND z21_fecha_emi <= TODAY ',
		' INTO TEMP tmp_z21 '
PREPARE cons_z21 FROM query
EXECUTE cons_z21
LET fecha = EXTEND(TODAY, YEAR TO SECOND) + 23 UNITS HOUR + 59 UNITS MINUTE
		+ 59 UNITS SECOND
LET subquery1 = '(SELECT SUM(z23_valor_cap + z23_valor_int) ',
		' FROM cxct023, cxct022 ',
		' WHERE z23_compania   = z21_compania ',
		'   AND z23_localidad  = z21_localidad ',
		'   AND z23_codcli     = z21_codcli ',
		'   AND z23_tipo_favor = z21_tipo_doc ',
		'   AND z23_doc_favor  = z21_num_doc ',
		'   AND z22_compania   = z23_compania ',
		'   AND z22_localidad  = z23_localidad ',
		'   AND z22_codcli     = z23_codcli ',
		'   AND z22_tipo_trn   = z23_tipo_trn ',
		'   AND z22_num_trn    = z23_num_trn ',
		'   AND z22_fecing     BETWEEN EXTEND(z21_fecha_emi, ',
						'YEAR TO SECOND)',
					 ' AND "', fecha, '")'
LET subquery2 = '(SELECT NVL(SUM(z23_valor_cap + z23_valor_int), 0) ',
		' FROM cxct023 ',
		' WHERE z23_compania   = z21_compania ',
		'   AND z23_localidad  = z21_localidad ',
		'   AND z23_codcli     = z21_codcli ',
		'   AND z23_tipo_favor = z21_tipo_doc ',
		'   AND z23_doc_favor  = z21_num_doc) '
LET query = 'SELECT z21_localidad, z21_tipo_doc, z21_num_doc, z21_codcli, ',
		' z01_nomcli, z21_fecha_emi, ',
		' NVL(CASE WHEN z21_fecha_emi > TODAY ',
			' THEN z21_valor + ', subquery1 CLIPPED,
			' ELSE ', subquery2 CLIPPED, ' + z21_saldo - ',
				  subquery1 CLIPPED,
		' END, ',
		' CASE WHEN z21_fecha_emi <= TODAY ',
			' THEN z21_saldo - ', subquery2 CLIPPED,
			' ELSE z21_valor',
		' END) * (-1) saldo_mov ',
		' FROM tmp_z21, cxct001 ',
		' WHERE z01_codcli     = z21_codcli ',
		' INTO TEMP tmp_fav '
PREPARE stmnt2 FROM query
EXECUTE stmnt2
DROP TABLE tmp_z21
DELETE FROM tmp_fav WHERE saldo_mov = 0
SELECT COUNT(*) INTO num_fav FROM tmp_fav
ERROR ' '
IF num_fav = 0 THEN
	--DROP TABLE tmp_fav
	--RETURN
END IF
SELECT z21_localidad, z21_codcli, z01_nomcli, NVL(SUM(saldo_mov), 0) saldo_fav
	FROM tmp_fav
	GROUP BY 1, 2, 3
	INTO TEMP tmp_sal_fav
DROP TABLE tmp_fav

END FUNCTION



FUNCTION genera_tabla_trabajo_resumen()
DEFINE query		CHAR(1200)
DEFINE subquery		CHAR(800)
DEFINE num_cli		INTEGER
DEFINE flag		SMALLINT

LET flag = 1
ERROR "Generando resumen . . . espere por favor." ATTRIBUTE(NORMAL)
LET query = 'SELECT z20_localidad loc1, z20_codcli cli1, valor_mov sald1 ',
		' FROM tmp_mov ',
		' WHERE z20_fecha_vcto >= TODAY ',
		'   AND valor_mov       > 0 ',
		' INTO TEMP t1 '
PREPARE cons_t1_a FROM query
EXECUTE	cons_t1_a
LET query = 'SELECT z20_localidad loc2, z20_codcli cli2, valor_mov sald2 ',
		' FROM tmp_mov ',
		' WHERE z20_fecha_vcto < TODAY ',
		'   AND valor_mov      > 0 ',
		' INTO TEMP t2 '
PREPARE cons_t2_a FROM query
EXECUTE	cons_t2_a
LET subquery = '(SELECT NVL(SUM(sald1), 0) ',
			' FROM t1 ',
			' WHERE cli1 = z20_codcli ',
			'   AND loc1 = z20_localidad), ',
			'(SELECT NVL(SUM(sald2), 0) ',
			' FROM t2 ',
			' WHERE cli2 = z20_codcli ',
			'   AND loc2 = z20_localidad) '
LET query = 'INSERT INTO tempo_doc ',
		' SELECT z20_localidad, z20_codcli, z01_nomcli, g02_nombre, ',
			subquery CLIPPED,
			' FROM tmp_mov ',
			' GROUP BY 1, 2, 3, 4'
PREPARE cons_mov FROM query
EXECUTE cons_mov
DELETE FROM tempo_doc WHERE por_vencer = 0 AND vencido = 0
SELECT COUNT(*) INTO num_cli FROM tempo_doc
ERROR " "
IF num_cli = 0 THEN
	LET flag = 0
END IF
DROP TABLE t1
DROP TABLE t2
RETURN flag

END FUNCTION



FUNCTION muestra_resumen_clientes()
DEFINE r_cli		RECORD
				codcli		LIKE cxct001.z01_codcli,
				nomcli		LIKE cxct001.z01_nomcli,
				locali		LIKE gent002.g02_localidad,
				tot_pven 	DECIMAL(12,2),
				tot_venc 	DECIMAL(12,2),
				tot_saldo 	DECIMAL(12,2)
			END RECORD
DEFINE query		CHAR(200)

SELECT codcli, nomcli, locali,
	NVL(SUM(por_vencer + vencido), 0) saldo_deu,
	NVL(SUM(por_vencer + vencido), 0) saldo_fav
	FROM tempo_doc
	GROUP BY 1, 2, 3
	INTO TEMP tmp_sal_deu
UPDATE tmp_sal_deu SET saldo_fav = 0
INSERT INTO tmp_sal_deu
	SELECT z21_codcli, z01_nomcli, z21_localidad, 0.00,
		NVL(SUM(saldo_fav), 0) saldo_fav
		FROM tmp_sal_fav
		GROUP BY 1, 2, 3, 4
SELECT codcli, nomcli, locali, NVL(SUM(saldo_deu), 0) saldo_deu,
	NVL(SUM(saldo_fav), 0) saldo_fav
	FROM tmp_sal_deu
	GROUP BY 1, 2, 3
	INTO TEMP tmp_cli_car
DROP TABLE tmp_sal_deu
DROP TABLE tmp_sal_fav
LET query = "SELECT codcli, nomcli, locali, saldo_deu, ",
			"NVL(saldo_fav, 0), saldo_deu + ",
			"NVL(saldo_fav, 0) ",
		" FROM tmp_cli_car "
PREPARE cons2 FROM query
DECLARE q_cons2 CURSOR FOR cons2
OPEN q_cons2
FETCH q_cons2 INTO r_cli.*
CLOSE q_cons2
FREE q_cons2
DROP TABLE tmp_cli_car
IF r_cli.tot_saldo <= 0 THEN
	RETURN 1, r_cli.*
END IF
RETURN 0, r_cli.*

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
DISPLAY '<F6>      Orden de Trabajo'         AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION control_visor_teclas_caracter_2() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Formas de Pago'           AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Orden de Trabajo'         AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
