--------------------------------------------------------------------------------
-- Titulo           : cajp203.4gl - Formas de Pago 
-- Elaboracion      : 30-oct-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun cajp203 base modulo compania localidad 
--		      [tipo_fuente] [num_fuente]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_tipo_fuente	LIKE cajt010.j10_tipo_fuente
DEFINE vm_num_fuente	LIKE cajt010.j10_num_fuente

DEFINE vm_cheque	CHAR(2)
DEFINE vm_efectivo	CHAR(2)

DEFINE vm_rowid		INTEGER
DEFINE vm_max_rows	SMALLINT
DEFINE vm_indice  	SMALLINT
DEFINE vm_size_arr	INTEGER
--
-- DEFINE RECORD(S) HERE
--
DEFINE rm_j02		RECORD LIKE cajt002.*
DEFINE rm_j04		RECORD LIKE cajt004.*
DEFINE rm_j10		RECORD LIKE cajt010.*
DEFINE rm_r38		RECORD LIKE rept038.*

DEFINE rm_j11		ARRAY[1000] OF RECORD 
				forma_pago	LIKE cajt011.j11_codigo_pago, 
				moneda		LIKE cajt011.j11_moneda, 
				cod_bco_tarj	LIKE cajt011.j11_cod_bco_tarj, 
				num_ch_aut	LIKE cajt011.j11_num_ch_aut, 
				num_cta_tarj	LIKE cajt011.j11_num_cta_tarj,
				valor		LIKE cajt011.j11_valor 
			END RECORD
DEFINE vm_tipo_doc	LIKE rept038.r38_cod_tran



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cajp203.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 6 AND num_args() <> 7 THEN
	-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'cajp203'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea

LET vm_num_fuente = 0
IF num_args() <> 4 THEN
	LET vm_tipo_fuente = arg_val(5)
	LET vm_num_fuente  = arg_val(6)
END IF

--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE salir		SMALLINT
DEFINE resp 		CHAR(3)  
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE r_r23 		RECORD LIKE rept023.*

CALL fl_nivel_isolation()
IF num_args() = 7 THEN
	CALL ejecutar_forma_de_pago_automatica()
	EXIT PROGRAM
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
OPEN WINDOW w_203 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST,MENU LINE lin_menu,
		BORDER, MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
        OPEN FORM f_203 FROM '../forms/cajf203_1'
ELSE
        OPEN FORM f_203 FROM '../forms/cajf203_1c'
END IF
DISPLAY FORM f_203

LET vm_max_rows = 1000

LET vm_cheque   = 'CH'
LET vm_efectivo = 'EF'

IF vm_num_fuente <> 0 THEN
	CALL execute_query()
	EXIT PROGRAM
END IF

CALL fl_retorna_caja(vg_codcia, vg_codloc, vg_usuario) RETURNING rm_j02.*
IF rm_j02.j02_codigo_caja IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'No hay una caja asignada al usuario ' || vg_usuario || '.','stop')
	CALL fl_mostrar_mensaje('No hay una caja asignada al usuario ' || vg_usuario || '.','stop')
	EXIT PROGRAM
END IF

LET rm_j10.j10_codigo_caja = rm_j02.j02_codigo_caja

LET salir = 0
WHILE NOT salir 
	LET vm_tipo_doc = 'FA'
	CLEAR FORM
	CALL setea_botones()

	INITIALIZE rm_j04.* TO NULL
	
	SELECT * INTO rm_j04.* FROM cajt004
		WHERE j04_compania    = vg_codcia
		  AND j04_localidad   = vg_codloc
		  AND j04_codigo_caja = rm_j02.j02_codigo_caja
		  AND j04_fecha_aper  = TODAY
		  AND j04_secuencia   = (SELECT MAX(j04_secuencia) 
		  			FROM cajt004
	  				WHERE j04_compania  = vg_codcia
	  				  AND j04_localidad = vg_codloc
	  				  AND j04_codigo_caja 
	  				  	= rm_j02.j02_codigo_caja
	  				  AND j04_fecha_aper  = TODAY)
	
	IF STATUS = NOTFOUND THEN 
		--CALL fgl_winmessage(vg_producto,'La caja no está aperturada.','exclamation')
		CALL fl_mostrar_mensaje('La caja no está aperturada.', 'stop')
		EXIT PROGRAM
	END IF
	
	INITIALIZE rm_j10.*    TO NULL
	INITIALIZE rm_r38.*    TO NULL
	INITIALIZE rm_j11[1].* TO NULL
	LET vm_indice = 1
	
	LET rm_j10.j10_codigo_caja = rm_j02.j02_codigo_caja
	
	CALL lee_datos_cabecera()
	IF INT_FLAG THEN
		LET salir = 1  
		CONTINUE WHILE
	END IF
	BEGIN WORK
	IF rm_j10.j10_tipo_fuente = 'PR' THEN
		DECLARE qu_lopr CURSOR FOR SELECT * FROM rept023
			WHERE r23_compania  = rm_j10.j10_compania AND 
			      r23_localidad = rm_j10.j10_localidad AND 
			      r23_numprev   = rm_j10.j10_num_fuente
			FOR UPDATE
		WHENEVER ERROR CONTINUE
		OPEN qu_lopr 
		FETCH qu_lopr INTO r_r23.*
		IF status < 0 OR status = NOTFOUND THEN
			ROLLBACK WORK
			CALL fl_mostrar_mensaje('Registro ya no existe o está bloqueado por otro proceso.','STOP')
			EXIT WHILE
		END IF 
		WHENEVER ERROR STOP
		CALL fl_lee_cabecera_caja(rm_j10.j10_compania, 
					  rm_j10.j10_localidad, 
					  rm_j10.j10_tipo_fuente,
					  rm_j10.j10_num_fuente) 
						RETURNING rm_j10.* 	 
	END IF
	WHENEVER ERROR STOP
	CALL muestra_registro()
	IF rm_j10.j10_valor > 0 THEN
		CALL ingresa_detalle()
		IF INT_FLAG THEN
			ROLLBACK WORK
			CONTINUE WHILE
		END IF
	END IF
	
	CALL proceso_master_transacciones_caja()
END WHILE

CLOSE WINDOW w_203

END FUNCTION



FUNCTION ejecutar_forma_de_pago_automatica()
DEFINE resul, salir	SMALLINT
DEFINE resp 		CHAR(3)  
DEFINE r_j10_aux	RECORD LIKE cajt010.*
DEFINE r_j10 		RECORD LIKE cajt010.*
DEFINE r_j90 		RECORD LIKE cajt090.*
DEFINE r_r23 		RECORD LIKE rept023.*
DEFINE r_r19 		RECORD LIKE rept019.*
DEFINE r_r88 		RECORD LIKE rept088.*
DEFINE r_t60 		RECORD LIKE talt060.*
DEFINE usuario		LIKE rept019.r19_usuario

LET vm_tipo_doc = 'FA'
LET vm_max_rows = 1000
LET vm_cheque   = 'CH'
LET vm_efectivo = 'EF'
INITIALIZE rm_j10.*, rm_r38.*, rm_j11[1].*, r_j10.*, r_r88.*, r_t60.* TO NULL
CALL fl_lee_cabecera_caja(vg_codcia, vg_codloc, vm_tipo_fuente, vm_num_fuente)
	RETURNING rm_j10.*
IF rm_j10.j10_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe Forma de Pago para Caja.', 'stop')
	EXIT PROGRAM
END IF
CASE vm_tipo_fuente
	WHEN 'PR'
		DECLARE q_r88 CURSOR FOR
			SELECT * FROM rept088
				WHERE r88_compania    = vg_codcia
				  AND r88_localidad   = vg_codloc
				  AND r88_numprev_nue = rm_j10.j10_num_fuente
		OPEN q_r88
		FETCH q_r88 INTO r_r88.*
		CLOSE q_r88
		FREE q_r88
		CALL fl_lee_cabecera_caja(vg_codcia, vg_codloc, vm_tipo_fuente,
						r_r88.r88_numprev_nue)
			RETURNING r_j10.*
	WHEN 'OT'
		DECLARE q_t60 CURSOR FOR
			SELECT * FROM talt060
				WHERE t60_compania  = vg_codcia
				  AND t60_localidad = vg_codloc
				  AND t60_ot_nue    = rm_j10.j10_num_fuente
		OPEN q_t60
		FETCH q_t60 INTO r_t60.*
		CLOSE q_t60
		FREE q_t60
		CALL fl_lee_cabecera_caja(vg_codcia, vg_codloc, vm_tipo_fuente,
						r_t60.t60_ot_nue)
			RETURNING r_j10.*
END CASE
IF r_j10.j10_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe Forma de Pago para Caja de Pre-Venta anterior.', 'stop')
	EXIT PROGRAM
END IF
CASE vm_tipo_fuente
	WHEN 'PR'
		CALL fl_lee_cabecera_transaccion_rep(r_r88.r88_compania,
				r_r88.r88_localidad, r_r88.r88_cod_fact,
				r_r88.r88_num_fact)
			RETURNING r_r19.*
		CALL fl_retorna_caja(vg_codcia, vg_codloc, r_r19.r19_usuario)
			RETURNING rm_j02.*
		LET usuario = r_r19.r19_usuario
	WHEN 'OT'
		CALL fl_lee_cabecera_caja(vg_codcia, vg_codloc, vm_tipo_fuente,
						r_t60.t60_ot_ant)
			RETURNING r_j10_aux.*
		CALL fl_retorna_caja(vg_codcia, vg_codloc,r_j10_aux.j10_usuario)
			RETURNING rm_j02.*
		LET usuario = r_j10_aux.j10_usuario
END CASE
IF rm_j02.j02_codigo_caja IS NULL THEN
	CALL fl_mostrar_mensaje('No hay una caja asignada al usuario ' || usuario || '.','stop')
	EXIT PROGRAM
END IF
INITIALIZE rm_j04.* TO NULL
DECLARE q_j90 CURSOR FOR
	SELECT * FROM cajt090 WHERE j90_localidad = rm_j02.j02_localidad
LET salir = 0
FOREACH q_j90 INTO r_j90.*
	SELECT * INTO rm_j04.* FROM cajt004
		WHERE j04_compania    = vg_codcia
		  AND j04_localidad   = vg_codloc
		  AND j04_codigo_caja = r_j90.j90_codigo_caja
		  AND j04_fecha_aper  = TODAY
		  AND j04_secuencia   = (SELECT MAX(j04_secuencia) 
	  			FROM cajt004
  				WHERE j04_compania  = vg_codcia
  				  AND j04_localidad = vg_codloc
  				  AND j04_codigo_caja 
  				  	= r_j90.j90_codigo_caja
  				  AND j04_fecha_aper  = TODAY)
	IF STATUS <> NOTFOUND THEN 
		LET salir = 1
		EXIT FOREACH
	END IF
END FOREACH
IF NOT salir THEN 
	CALL fl_mostrar_mensaje('La caja del usuario ' || usuario CLIPPED || ' no está aperturada.', 'stop')
	EXIT PROGRAM
END IF
LET rm_j10.j10_codigo_caja = r_j90.j90_codigo_caja
LET vg_usuario             = r_j90.j90_usua_caja
CALL fl_retorna_caja(vg_codcia, vg_codloc, vg_usuario) RETURNING rm_j02.*
LET vm_indice = 1
IF rm_j10.j10_tipo_fuente = 'PR' OR
   rm_j10.j10_tipo_fuente = 'PV' OR
   rm_j10.j10_tipo_fuente = 'OT' THEN
	IF rm_r38.r38_num_sri IS NULL THEN
		CALL validar_num_sri(1) RETURNING resul
		IF resul <= 0 THEN
			EXIT PROGRAM
		END IF
	END IF
END IF
BEGIN WORK
IF rm_j10.j10_tipo_fuente = 'PR' THEN
	DECLARE qu_lopr_a CURSOR FOR SELECT * FROM rept023
		WHERE r23_compania  = rm_j10.j10_compania AND 
		      r23_localidad = rm_j10.j10_localidad AND 
		      r23_numprev   = rm_j10.j10_num_fuente
		FOR UPDATE
	WHENEVER ERROR CONTINUE
	OPEN qu_lopr_a 
	FETCH qu_lopr_a INTO r_r23.*
	IF status < 0 OR status = NOTFOUND THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('Registro ya no existe o está bloqueado por otro proceso.','STOP')
		EXIT PROGRAM
	END IF 
	WHENEVER ERROR STOP
	CALL fl_lee_cabecera_caja(rm_j10.j10_compania, rm_j10.j10_localidad, 
				  rm_j10.j10_tipo_fuente, rm_j10.j10_num_fuente)
		RETURNING rm_j10.* 	 
END IF
WHENEVER ERROR STOP
CALL proceso_master_transacciones_caja()

END FUNCTION



FUNCTION lee_datos_cabecera()
DEFINE tipo_fuente	LIKE cajt010.j10_tipo_fuente
DEFINE r_j10		RECORD LIKE cajt010.*
DEFINE r_r23		RECORD LIKE rept023.* 	-- Preventa Repuestos
DEFINE r_v26		RECORD LIKE veht026.* 	-- Preventa Vehiculos
DEFINE r_t23		RECORD LIKE talt023.*	-- Orden de Trabajo
DEFINE r_z24		RECORD LIKE cxct024.*	-- Solicitud Cobro Clientes
DEFINE aux_sri		LIKE rept038.r38_num_sri
DEFINE resp 		CHAR(6)
DEFINE estado 		CHAR(1)
DEFINE resul		SMALLINT

--LET rm_j10.j10_tipo_fuente = 'OT'
LET rm_j10.j10_tipo_fuente = 'PR'
IF vg_gui = 0 THEN
	CALL muestra_tipo_fuente(rm_j10.j10_tipo_fuente)
END IF
LET int_flag = 0
INPUT BY NAME rm_j10.j10_tipo_fuente, rm_j10.j10_num_fuente, rm_r38.r38_num_sri
	WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(j10_tipo_fuente, j10_num_fuente,
					rm_r38.r38_num_sri)
		THEN
			LET int_flag = 1
			--#RETURN
			EXIT INPUT
		END IF

		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			--#RETURN
			EXIT INPUT
		END IF
       	ON KEY(F1,CONTROL-W)
		CALL control_visor_teclas_caracter_1() 
	ON KEY(F2)
		IF INFIELD(j10_num_fuente) THEN
			CALL fl_ayuda_numero_fuente_caja(vg_codcia, vg_codloc, 
							 rm_j10.j10_tipo_fuente)
					RETURNING r_j10.j10_num_fuente,
						  r_j10.j10_nomcli,
						  r_j10.j10_valor 
			IF r_j10.j10_num_fuente IS NOT NULL THEN
				CALL fl_lee_cabecera_caja(vg_codcia, vg_codloc, 
					  rm_j10.j10_tipo_fuente,
					  r_j10.j10_num_fuente) 
					RETURNING r_j10.* 	 
				LET rm_j10.* = r_j10.*
				DISPLAY BY NAME rm_j10.j10_num_fuente
				IF r_j10.j10_tipo_fuente = 'PR' THEN
					CALL averiguar_refacturacion()
						RETURNING resul
					IF resul THEN
						NEXT FIELD j10_num_fuente
					END IF
				END IF
			END IF
		END IF
		LET int_flag = 0
	ON KEY(F5)
		IF INFIELD(j10_tipo_fuente) OR INFIELD(j10_num_fuente) THEN
			LET tipo_fuente = rm_j10.j10_tipo_fuente
			LET rm_j10.j10_tipo_fuente = GET_FLDBUF(j10_tipo_fuente)
			IF tipo_fuente = rm_j10.j10_tipo_fuente THEN
				IF rm_j10.j10_num_fuente IS NOT NULL THEN
					CALL ver_documento_origen()
				END IF
			ELSE
				--#CALL dialog.keysetlabel('F5', '')
			END IF
			IF vg_gui = 0 THEN
				CALL muestra_tipo_fuente(rm_j10.j10_tipo_fuente)
			END IF
		END IF
		LET int_flag = 0
	ON KEY(F6)
		CALL control_crear_cliente()
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel('F5', '')
		--#CALL dialog.keysetlabel('F6', 'Cliente Contado')
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD j10_tipo_fuente
		LET tipo_fuente = rm_j10.j10_tipo_fuente
	BEFORE FIELD r38_num_sri
		IF rm_j10.j10_tipo_fuente = 'PR' OR
		   rm_j10.j10_tipo_fuente = 'PV' OR
		   rm_j10.j10_tipo_fuente = 'OT' THEN
			LET aux_sri = rm_r38.r38_num_sri
			CALL validar_num_sri(0) RETURNING resul
			CASE resul
				WHEN -1
					--ROLLBACK WORK
					EXIT PROGRAM
				WHEN 0
					NEXT FIELD r38_num_sri
			END CASE
		ELSE
			LET rm_r38.r38_num_sri = NULL
			DISPLAY BY NAME rm_r38.r38_num_sri
		END IF
	AFTER FIELD j10_tipo_fuente
		IF (rm_j10.j10_tipo_fuente = 'PV' 
		    OR rm_j10.j10_tipo_fuente = 'PR')
		AND rm_j02.j02_pre_ventas = 'N'
		THEN
			--CALL fgl_winmessage(vg_producto,'No se pueden cancelar pre-ventas en esta caja.','exclamation')
			CALL fl_mostrar_mensaje('No se pueden cancelar pre-ventas en esta caja.','exclamation')
			NEXT FIELD j10_tipo_fuente
		END IF
		IF rm_j10.j10_tipo_fuente = 'OT' AND rm_j02.j02_ordenes = 'N'
		THEN
			--CALL fgl_winmessage(vg_producto,'No se pueden cancelar ordenes de trabajo en esta caja.','exclamation')
			CALL fl_mostrar_mensaje('No se pueden cancelar ordenes de trabajo en esta caja.','exclamation')
			NEXT FIELD j10_tipo_fuente
		END IF
		IF rm_j10.j10_tipo_fuente = 'SC' AND rm_j02.j02_solicitudes = 'N'
		THEN
			--CALL fgl_winmessage(vg_producto,'No se pueden cancelar solicitudes de cobro en esta caja.','exclamation')
			CALL fl_mostrar_mensaje('No se pueden cancelar solicitudes de cobro en esta caja.','exclamation')
			NEXT FIELD j10_tipo_fuente
		END IF
		IF rm_j10.j10_tipo_fuente <> tipo_fuente THEN
			--#CALL dialog.keysetlabel('F5', '')
		END IF
		IF vg_gui = 0 THEN
			CALL muestra_tipo_fuente(rm_j10.j10_tipo_fuente)
		END IF
	AFTER FIELD j10_num_fuente
		IF rm_j10.j10_num_fuente IS NULL THEN
			CLEAR FORM
			CALL setea_botones()
			DISPLAY BY NAME rm_j10.j10_tipo_fuente,
					rm_j10.j10_num_fuente
			IF vg_gui = 0 THEN
				CALL muestra_tipo_fuente(rm_j10.j10_tipo_fuente)
			END IF
			--#CALL dialog.keysetlabel('F5', '')
			CONTINUE INPUT
		END IF
		CALL fl_lee_cabecera_caja(vg_codcia, vg_codloc, 
					  rm_j10.j10_tipo_fuente,
					  rm_j10.j10_num_fuente) 
						RETURNING r_j10.* 	 
		IF r_j10.j10_num_fuente IS NULL THEN
			--CALL fgl_winmessage(vg_producto,'Registro no existe.','exclamation')
			CALL fl_mostrar_mensaje('Registro no existe.','exclamation')
			CLEAR FORM
			CALL setea_botones()
			DISPLAY BY NAME rm_j10.j10_tipo_fuente,
					rm_j10.j10_num_fuente
			IF vg_gui = 0 THEN
				CALL muestra_tipo_fuente(rm_j10.j10_tipo_fuente)
			END IF
			--#CALL dialog.keysetlabel('F5', '')
			NEXT FIELD j10_num_fuente
		END IF
		IF r_j10.j10_estado <> 'A' THEN
			--CALL fgl_winmessage(vg_producto,'Registro de caja no está activo.','exclamation')
			CALL fl_mostrar_mensaje('Registro de caja no está activo.','exclamation')
			CLEAR FORM
			CALL setea_botones()
			DISPLAY BY NAME rm_j10.j10_tipo_fuente,
					rm_j10.j10_num_fuente
			--#CALL dialog.keysetlabel('F5', '')
			IF vg_gui = 0 THEN
				CALL muestra_tipo_fuente(rm_j10.j10_tipo_fuente)
			END IF
			NEXT FIELD j10_num_fuente
		END IF
		CASE rm_j10.j10_tipo_fuente
			WHEN 'PR'
				CALL fl_lee_preventa_rep(vg_codcia, vg_codloc,
					r_j10.j10_num_fuente) RETURNING r_r23.*
				IF r_r23.r23_numprev IS NULL THEN
					--CALL fgl_winmessage(vg_producto,'Preventa no existe.','exclamation')
					CALL fl_mostrar_mensaje('Preventa no existe.','exclamation')
					CLEAR FORM
					CALL setea_botones()
					DISPLAY BY NAME rm_j10.j10_tipo_fuente,
							rm_j10.j10_num_fuente
					IF vg_gui = 0 THEN
						CALL muestra_tipo_fuente(rm_j10.j10_tipo_fuente)
					END IF
					--#CALL dialog.keysetlabel('F5', '')
					NEXT FIELD j10_num_fuente
				END IF
				CALL averiguar_refacturacion() RETURNING resul
				IF resul THEN
					NEXT FIELD j10_num_fuente
				END IF
				IF r_r23.r23_estado <> 'P' THEN
					--CALL fgl_winmessage(vg_producto,'Preventa no ha sido aprobada.','exclamation')
					CALL fl_mostrar_mensaje('Preventa no ha sido aprobada.','exclamation')
					CLEAR FORM
					CALL setea_botones()
					DISPLAY BY NAME rm_j10.j10_tipo_fuente,
							rm_j10.j10_num_fuente
					IF vg_gui = 0 THEN
						CALL muestra_tipo_fuente(rm_j10.j10_tipo_fuente)
					END IF
					--#CALL dialog.keysetlabel('F5', '')
					NEXT FIELD j10_num_fuente
				END IF
			WHEN 'PV'
				CALL fl_lee_preventa_veh(vg_codcia, vg_codloc,
					r_j10.j10_num_fuente) RETURNING r_v26.*
				IF r_v26.v26_numprev IS NULL THEN
					--CALL fgl_winmessage(vg_producto,'Preventa no existe.','exclamation')
					CALL fl_mostrar_mensaje('Preventa no existe.','exclamation')
					CLEAR FORM
					CALL setea_botones()
					DISPLAY BY NAME rm_j10.j10_tipo_fuente,
							rm_j10.j10_num_fuente
					IF vg_gui = 0 THEN
						CALL muestra_tipo_fuente(rm_j10.j10_tipo_fuente)
					END IF
					--#CALL dialog.keysetlabel('F5', '')
					NEXT FIELD j10_num_fuente
				END IF
				IF r_v26.v26_estado <> 'P' THEN
					--CALL fgl_winmessage(vg_producto,'Preventa no ha sido aprobada.','exclamation')
					CALL fl_mostrar_mensaje('Preventa no ha sido aprobada.','exclamation')
					CLEAR FORM
					CALL setea_botones()
					DISPLAY BY NAME rm_j10.j10_tipo_fuente,
							rm_j10.j10_num_fuente
					IF vg_gui = 0 THEN
						CALL muestra_tipo_fuente(rm_j10.j10_tipo_fuente)
					END IF
					--#CALL dialog.keysetlabel('F5', '')
					NEXT FIELD j10_num_fuente
				END IF
			WHEN 'OT'
				CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc,
					r_j10.j10_num_fuente) RETURNING r_t23.*
				IF r_t23.t23_orden IS NULL THEN
					--CALL fgl_winmessage(vg_producto,'Orden de trabajo no existe.','exclamation')
					CALL fl_mostrar_mensaje('Orden de trabajo no existe.','exclamation')
					CLEAR FORM
					CALL setea_botones()
					DISPLAY BY NAME rm_j10.j10_tipo_fuente,
							rm_j10.j10_num_fuente
					IF vg_gui = 0 THEN
						CALL muestra_tipo_fuente(rm_j10.j10_tipo_fuente)
					END IF
					--#CALL dialog.keysetlabel('F5', '')
					NEXT FIELD j10_num_fuente
				END IF
				IF r_t23.t23_estado <> 'C' THEN
					--CALL fgl_winmessage(vg_producto,'Orden de trabajo no ha sido cerrada.','exclamation')
					CALL fl_mostrar_mensaje('Orden de trabajo no ha sido cerrada.','exclamation')
					CLEAR FORM
					CALL setea_botones()
					DISPLAY BY NAME rm_j10.j10_tipo_fuente,
							rm_j10.j10_num_fuente
					IF vg_gui = 0 THEN
						CALL muestra_tipo_fuente(rm_j10.j10_tipo_fuente)
					END IF
					--#CALL dialog.keysetlabel('F5', '')
					NEXT FIELD j10_num_fuente
				END IF
			WHEN 'SC'
				CALL fl_lee_solicitud_cobro_cxc(
					vg_codcia, vg_codloc, 
					r_j10.j10_num_fuente) 
					RETURNING r_z24.*
				IF r_z24.z24_numero_sol IS NULL THEN
					--CALL fgl_winmessage(vg_producto,'Solicitud de cobro no existe.','exclamation')
					CALL fl_mostrar_mensaje('Solicitud de cobro no existe.','exclamation')
					CLEAR FORM
					CALL setea_botones()
					DISPLAY BY NAME rm_j10.j10_tipo_fuente,
							rm_j10.j10_num_fuente
					IF vg_gui = 0 THEN
						CALL muestra_tipo_fuente(rm_j10.j10_tipo_fuente)
					END IF
					--#CALL dialog.keysetlabel('F5', '')
					NEXT FIELD j10_num_fuente
				END IF
				IF r_z24.z24_estado <> 'A' THEN
					--CALL fgl_winmessage(vg_producto,'Solicitud de cobro no está activa.','exclamation')
					CALL fl_mostrar_mensaje('Solicitud de cobro no está activa.','exclamation')
					CLEAR FORM
					CALL setea_botones()
					DISPLAY BY NAME rm_j10.j10_tipo_fuente,
							rm_j10.j10_num_fuente
					IF vg_gui = 0 THEN
						CALL muestra_tipo_fuente(rm_j10.j10_tipo_fuente)
					END IF
					--#CALL dialog.keysetlabel('F5', '')
					NEXT FIELD j10_num_fuente
				END IF
		END CASE

		LET rm_j10.* = r_j10.*
		CALL muestra_registro()
		--#CALL dialog.keysetlabel('F5', 'Ver Documento')
		IF rm_r38.r38_num_sri IS NULL THEN
			NEXT FIELD r38_num_sri
		END IF
	AFTER FIELD r38_num_sri
		IF rm_j10.j10_tipo_fuente = 'PR' OR
		   rm_j10.j10_tipo_fuente = 'PV' OR
		   rm_j10.j10_tipo_fuente = 'OT' THEN
			IF rm_r38.r38_num_sri IS NOT NULL THEN
				CALL validar_num_sri(1) RETURNING resul
				CASE resul
					WHEN -1
						--ROLLBACK WORK
						EXIT PROGRAM
					WHEN 0
						NEXT FIELD r38_num_sri
				END CASE
			ELSE
				LET rm_r38.r38_num_sri = aux_sri
				DISPLAY BY NAME rm_r38.r38_num_sri
			END IF
		ELSE
			LET rm_r38.r38_num_sri = NULL
			DISPLAY BY NAME rm_r38.r38_num_sri
		END IF
	AFTER INPUT
		IF rm_j10.j10_tipo_fuente = 'PR' OR
		   rm_j10.j10_tipo_fuente = 'PV' OR
		   rm_j10.j10_tipo_fuente = 'OT' THEN
			IF rm_r38.r38_num_sri IS NOT NULL THEN
				CALL validar_num_sri(1) RETURNING resul
				CASE resul
					WHEN -1
						--ROLLBACK WORK
						EXIT PROGRAM
					WHEN 0
						NEXT FIELD r38_num_sri
				END CASE
			ELSE
				LET rm_r38.r38_num_sri = aux_sri
				DISPLAY BY NAME rm_r38.r38_num_sri
			END IF
		ELSE
			LET rm_r38.r38_num_sri = NULL
			DISPLAY BY NAME rm_r38.r38_num_sri
		END IF
END INPUT

END FUNCTION



FUNCTION control_crear_cliente()
DEFINE command_run	VARCHAR(100)
DEFINE run_prog		CHAR(10)

IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CO', 'cxcp101')
THEN
	RETURN
END IF
{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
LET command_run = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS',
		vg_separador, 'fuentes', vg_separador, run_prog, 'cxcp101 ',
		vg_base, ' CO ', vg_codcia, ' ', vg_codloc
RUN command_run

END FUNCTION



FUNCTION averiguar_refacturacion()
DEFINE r_r88		RECORD LIKE rept088.*

INITIALIZE r_r88.* TO NULL
DECLARE q_r88_ad CURSOR FOR
	SELECT * INTO r_r88.* FROM rept088
		WHERE r88_compania    = vg_codcia
		  AND r88_localidad   = vg_codloc
		  AND r88_numprev_nue =	rm_j10.j10_num_fuente
OPEN q_r88_ad
FETCH q_r88_ad INTO r_r88.*
IF r_r88.r88_compania IS NOT NULL THEN
	CLOSE q_r88_ad
	FREE q_r88_ad
	CALL fl_mostrar_mensaje('No puede Facturar esta Preventa. Hagalo por Refacturación.', 'exclamation')
	RETURN 1
END IF
CLOSE q_r88_ad
FREE q_r88_ad
RETURN 0

END FUNCTION



FUNCTION validar_num_sri(validar)
DEFINE validar		SMALLINT
DEFINE r_g37		RECORD LIKE gent037.*
DEFINE r_z01 		RECORD LIKE cxct001.*
DEFINE cont_cred	LIKE gent037.g37_cont_cred
DEFINE cont		INTEGER
DEFINE flag		SMALLINT

-- OJO PUESTO PARA LA NOTA DE VENTA
--IF vg_codloc = 3 THEN
	CALL fl_lee_cliente_general(rm_j10.j10_codcli) RETURNING r_z01.*
	IF r_z01.z01_tipo_doc_id <> 'R' THEN
		LET vm_tipo_doc = 'NV'
	END IF
--END IF
--
CALL retorna_cont_cred() RETURNING cont_cred
CALL fl_validacion_num_sri(vg_codcia, vg_codloc, vm_tipo_doc, cont_cred,
				rm_r38.r38_num_sri)
	RETURNING r_g37.*, rm_r38.r38_num_sri, flag
CASE flag
	WHEN -1
		RETURN -1
	WHEN 0
		RETURN  0
END CASE
IF num_args() <> 7 THEN
	DISPLAY BY NAME rm_r38.r38_num_sri
END IF
IF validar = 1 THEN
	SELECT COUNT(*) INTO cont FROM rept038
		WHERE r38_compania    = vg_codcia
		  AND r38_localidad   = vg_codloc
  		  AND r38_cod_tran    = rm_j10.j10_tipo_destino
  		  AND r38_tipo_fuente = rm_j10.j10_tipo_fuente
  		  AND r38_num_sri     = rm_r38.r38_num_sri
	IF cont > 0 THEN
		CALL fl_mostrar_mensaje('La secuencia del SRI ' || rm_r38.r38_num_sri[9,15] || ' ya existe.','exclamation')
		RETURN 0
	END IF
END IF
RETURN 1

END FUNCTION



FUNCTION retorna_cont_cred()
DEFINE r_r23		RECORD LIKE rept023.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE cont_cred	LIKE gent037.g37_cont_cred
DEFINE cont		INTEGER

LET cont_cred = 'N'
SELECT COUNT(*) INTO cont FROM gent037
	WHERE g37_compania  =  vg_codcia
	  AND g37_localidad =  vg_codloc
	  AND g37_tipo_doc  =  vm_tipo_doc
  	  AND g37_fecha_emi <= DATE(TODAY)
  	  AND g37_fecha_exp >= DATE(TODAY)
IF cont > 1 THEN
	IF rm_j10.j10_tipo_fuente = 'PR' THEN
		CALL fl_lee_preventa_rep(vg_codcia, vg_codloc,
						rm_j10.j10_num_fuente)
			RETURNING r_r23.*
		LET cont_cred = r_r23.r23_cont_cred
	END IF
	IF rm_j10.j10_tipo_fuente = 'OT' THEN
		CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc,
						rm_j10.j10_num_fuente)
			RETURNING r_t23.*
		LET cont_cred = r_t23.t23_cont_cred
	END IF
END IF
RETURN cont_cred

END FUNCTION



FUNCTION muestra_registro()
DEFINE r_g03		RECORD LIKE gent003.*
DEFINE r_g13		RECORD LIKE gent013.*

DISPLAY BY NAME rm_j10.j10_areaneg,
		rm_j10.j10_codcli,
		rm_j10.j10_nomcli,
		rm_j10.j10_moneda,
		rm_j10.j10_tipo_destino,
		rm_j10.j10_num_destino,
		rm_j10.j10_valor,
		rm_j10.j10_fecha_pro,
		rm_j10.j10_usuario

CALL fl_lee_area_negocio(vg_codcia, rm_j10.j10_areaneg) RETURNING r_g03.*
DISPLAY r_g03.g03_nombre TO n_areaneg

CALL fl_lee_moneda(rm_j10.j10_moneda) RETURNING r_g13.*
DISPLAY r_g13.g13_nombre TO n_moneda

END FUNCTION



FUNCTION ingresa_detalle()

DEFINE banco		LIKE gent009.g09_banco
DEFINE nom_bco		VARCHAR(20)
DEFINE tipo_cta		LIKE gent009.g09_tipo_cta
DEFINE numero_cta 	LIKE gent009.g09_numero_cta
DEFINE numero_ch	LIKE cajt011.j11_num_ch_aut
DEFINE valor_ch		LIKE cajt011.j11_valor 
DEFINE i		SMALLINT
DEFINE j		SMALLINT
DEFINE salir		SMALLINT
DEFINE resul		SMALLINT
DEFINE resp		CHAR(6)

DEFINE total		LIKE cajt011.j11_valor
DEFINE vuelto, val, dif	LIKE cajt011.j11_valor
DEFINE valor_ef		LIKE cajt011.j11_valor

DEFINE bco_tarj		SMALLINT

DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_g09		RECORD LIKE gent009.*
DEFINE r_g10		RECORD LIKE gent010.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_j01		RECORD LIKE cajt001.*

OPTIONS
	INSERT KEY F30

LET salir = 0
WHILE NOT salir

LET i = 1
LET j = 1
LET INT_FLAG = 0
CALL set_count(vm_indice)
INPUT ARRAY rm_j11 WITHOUT DEFAULTS FROM ra_j11.*
	ON KEY(INTERRUPT)
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			EXIT INPUT
		END IF
       	ON KEY(F1,CONTROL-W)
		CALL control_visor_teclas_caracter_2() 
	ON KEY(F2)
		IF INFIELD(j11_codigo_pago) THEN
			CALL fl_ayuda_forma_pago(vg_codcia) 
				RETURNING r_j01.j01_codigo_pago,
					  r_j01.j01_nombre
			IF r_j01.j01_codigo_pago IS NOT NULL THEN
				LET rm_j11[i].forma_pago = r_j01.j01_codigo_pago
				DISPLAY rm_j11[i].forma_pago 
					TO ra_j11[j].j11_codigo_pago
			END IF
		END IF
		IF INFIELD(j11_moneda) THEN
			CALL fl_ayuda_monedas() 
				RETURNING r_mon.g13_moneda, r_mon.g13_nombre, 
					  r_mon.g13_decimales 
			IF r_mon.g13_moneda IS NOT NULL THEN
				LET rm_j11[i].moneda = r_mon.g13_moneda
				DISPLAY rm_j11[i].moneda TO ra_j11[j].j11_moneda
			END IF	
		END IF
		IF INFIELD(j11_cod_bco_tarj) THEN
			IF rm_j11[i].forma_pago = 'CP' AND
			   rm_j10.j10_tipo_fuente = 'SC'
			THEN
				CALL fl_ayuda_cheques_postfechados(vg_codcia,
						vg_codloc, rm_j10.j10_codcli) 
					RETURNING banco, numero_ch, numero_cta,
							valor_ch
				IF numero_cta IS NOT NULL THEN
					LET rm_j11[i].cod_bco_tarj = banco
					LET rm_j11[i].num_ch_aut   = numero_ch
					LET rm_j11[i].num_cta_tarj = numero_cta
					LET rm_j11[i].valor        = valor_ch
					DISPLAY rm_j11[i].cod_bco_tarj TO
						ra_j11[j].j11_cod_bco_tarj
					DISPLAY rm_j11[i].num_ch_aut TO
						ra_j11[i].j11_num_ch_aut
					DISPLAY rm_j11[i].num_cta_tarj TO
						ra_j11[j].j11_num_cta_tarj
					DISPLAY rm_j11[i].valor TO
						ra_j11[j].j11_valor
				END IF	
			END IF
			IF rm_j11[i].forma_pago = 'DP' THEN
				CALL fl_ayuda_cuenta_banco(vg_codcia) 
					RETURNING banco, nom_bco, 
				                  tipo_cta, 
				                  numero_cta 
				IF numero_cta IS NOT NULL THEN
					LET rm_j11[i].cod_bco_tarj = banco
					LET rm_j11[i].num_cta_tarj = numero_cta
					DISPLAY rm_j11[i].cod_bco_tarj 
						TO ra_j11[j].j11_cod_bco_tarj
					DISPLAY rm_j11[i].num_cta_tarj 
						TO ra_j11[j].j11_num_cta_tarj
				END IF	
			ELSE
				IF rm_j11[i].forma_pago <> 'CP' OR
				   rm_j10.j10_tipo_fuente <> 'SC'
				THEN
				  CALL ayudas_bco_tarj(rm_j11[i].forma_pago)
					RETURNING rm_j11[i].cod_bco_tarj
				  DISPLAY rm_j11[i].cod_bco_tarj TO
					ra_j11[j].j11_cod_bco_tarj
				END IF
			END IF
			{-- OJO QUITAR CUANDO ESTE ARREGLADO FORMAS PAGO EN CAJA
			IF rm_j11[i].forma_pago = 'CP' THEN
				LET rm_j11[i].forma_pago = vm_cheque
				DISPLAY rm_j11[i].forma_pago TO
					ra_j11[j].j11_codigo_pago
			END IF
			--}
		END IF
		LET INT_FLAG = 0
	ON KEY(F5)
		CALL ver_documento_origen()
		LET INT_FLAG = 0
	ON KEY(F6)
		LET i = arr_curr()
		LET j = scr_line()
		IF rm_j11[i].forma_pago = 'RT' THEN
			IF rm_j10.j10_tipo_fuente = 'PR' OR
			   rm_j10.j10_tipo_fuente = 'OT' THEN
				CALL calcular_retencion(i, j)
			END IF
		END IF
	ON KEY(F7)
		IF infield(j11_valor) THEN
			LET vm_indice = arr_count()
			LET total = calcula_total(vm_indice)
			IF total IS NULL THEN
				LET total = 0
			END IF
			LET val = rm_j11[i].valor
			IF val IS NULL THEN
				LET val = 0
			END IF
			LET val = rm_j10.j10_valor - (total - val)
			IF val > 0 THEN
				LET rm_j11[i].valor = val
				DISPLAY rm_j11[i].valor TO ra_j11[j].j11_valor
				LET vm_indice = arr_count()
				LET total = calcula_total(vm_indice)
			END IF
		END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel('INSERT', '')
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
		CALL calcula_total(arr_count()) RETURNING total
	BEFORE ROW
		--#IF NOT infield(j11_valor) THEN
			--#CALL dialog.keysetlabel('F7', '')
		--#END IF
		LET i = arr_curr()
		LET j = scr_line()
	AFTER ROW
		LET vm_indice = arr_count()
		LET total = calcula_total(vm_indice)
		LET valor_ef = valor_efectivo(vm_indice)
		LET vuelto = total - rm_j10.j10_valor
		IF vuelto < 0 THEN 
			LET vuelto = 0
		END IF
		DISPLAY BY NAME vuelto
		{-- OJO QUITAR CUANDO ESTE ARREGLADO FORMAS DE PAGO EN CAJA
		IF rm_j11[i].forma_pago = 'CP' THEN
			LET rm_j11[i].forma_pago = vm_cheque
			DISPLAY rm_j11[i].forma_pago TO
				ra_j11[j].j11_codigo_pago
		END IF
		--}
	AFTER FIELD j11_codigo_pago
		IF rm_j11[i].forma_pago IS NULL THEN
			IF fgl_lastkey() <> fgl_keyval('up') THEN
				NEXT FIELD j11_codigo_pago
			ELSE
				CONTINUE INPUT
			END IF
		END IF 
		CALL fl_lee_tipo_pago_caja(vg_codcia, rm_j11[i].forma_pago)
			RETURNING r_j01.*		
		IF r_j01.j01_codigo_pago IS NULL THEN
			CALL fl_mostrar_mensaje('Forma de Pago no existe.','exclamation')
			NEXT FIELD j11_codigo_pago
		END IF
		IF r_j01.j01_estado = 'B' THEN
			CALL fl_mostrar_mensaje('Forma de Pago está bloqueada.','exclamation')
			NEXT FIELD j11_codigo_pago
		END IF
		LET rm_j11[i].moneda = rm_j10.j10_moneda
		DISPLAY rm_j11[i].moneda TO ra_j11[j].j11_moneda
		NEXT FIELD j11_cod_bco_tarj
	AFTER FIELD j11_moneda
		IF rm_j11[i].moneda IS NULL THEN
			NEXT FIELD j11_moneda
		END IF 

		CALL fl_lee_moneda(rm_j11[i].moneda) RETURNING r_mon.*

		-- Validaciones sobre la moneda
		IF r_mon.g13_moneda IS NULL THEN	
			CALL fl_mostrar_mensaje('Moneda no existe.','exclamation')
			NEXT FIELD j11_moneda
		END IF
		IF r_mon.g13_estado = 'B' THEN
			CALL fl_mensaje_estado_bloqueado()
			NEXT FIELD j11_moneda
		END IF

		IF calcula_paridad(rm_j11[i].moneda, rm_j10.j10_moneda) IS NULL
		THEN
			LET rm_j11[i].moneda = rm_j10.j10_moneda
			DISPLAY rm_j11[i].moneda TO ra_j11[j].j11_moneda
		END IF
		CALL calcula_total(arr_count()) RETURNING total
		IF rm_j11[i].valor IS NOT NULL THEN
			LET valor_ef = valor_efectivo(vm_indice)
			LET vuelto = total - rm_j10.j10_valor
			IF vuelto < 0 THEN 
				LET vuelto = 0
			END IF
			DISPLAY BY NAME vuelto
		END IF
	BEFORE FIELD j11_valor
		--#CALL dialog.keysetlabel('F7', 'Diferencia')
	AFTER FIELD j11_valor
		IF rm_j11[i].valor IS NULL THEN
			NEXT FIELD j11_valor
		END IF
		IF rm_j11[i].valor <= 0 THEN
			CALL fl_mostrar_mensaje('El valor debe ser mayor a cero.','exclamation')
			NEXT FIELD j11_valor
		END IF	
		LET vm_indice = arr_count()
		LET total = calcula_total(vm_indice)
		LET valor_ef = valor_efectivo(vm_indice)
		LET vuelto = total - rm_j10.j10_valor
		IF vuelto < 0 THEN 
			LET vuelto = 0
		END IF
		--#CALL dialog.keysetlabel('F7', '')
		DISPLAY BY NAME vuelto
		IF fgl_lastkey() = fgl_keyval('return') THEN
			--NEXT FIELD ra_j11[j-1].j11_codigo_pago
			NEXT FIELD j11_codigo_pago
		END IF
		{-- OJO QUITAR CUANDO ESTE ARREGLADO FORMAS DE PAGO EN CAJA
		IF rm_j11[i].forma_pago = 'CP' THEN
			LET rm_j11[i].forma_pago = vm_cheque
			DISPLAY rm_j11[i].forma_pago TO
				ra_j11[j].j11_codigo_pago
		END IF
		--}
	AFTER FIELD j11_cod_bco_tarj
		IF rm_j11[i].cod_bco_tarj IS NULL THEN
			CONTINUE INPUT
		END IF
		LET bco_tarj = banco_tarjeta(rm_j11[i].forma_pago)
		IF bco_tarj IS NULL OR bco_tarj = 3 THEN
			INITIALIZE rm_j11[i].cod_bco_tarj TO NULL
			CLEAR ra_j11[j].j11_cod_bco_tarj
		END IF
		IF bco_tarj = 1 THEN
			CALL fl_lee_banco_general(rm_j11[i].cod_bco_tarj)
				RETURNING r_g08.* 
			IF r_g08.g08_banco IS NULL THEN
				CALL fl_mostrar_mensaje('Banco no existe.','exclamation')
				NEXT FIELD j11_cod_bco_tarj
			END IF
		END IF
		IF bco_tarj = 2 THEN
			CALL fl_lee_tarjeta_credito(rm_j11[i].cod_bco_tarj)
				RETURNING r_g10.* 
			IF r_g10.g10_tarjeta IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Tarjeta no existe.','exclamation')
				CALL fl_mostrar_mensaje('Tarjeta no existe.','exclamation')
				NEXT FIELD j11_cod_bco_tarj
			END IF
		END IF
	AFTER FIELD j11_num_ch_aut
		LET bco_tarj = banco_tarjeta(rm_j11[i].forma_pago)
		IF bco_tarj IS NULL  THEN
			INITIALIZE rm_j11[i].num_ch_aut TO NULL
			CLEAR ra_j11[j].j11_num_ch_aut
		END IF
	AFTER FIELD j11_num_cta_tarj
		LET bco_tarj = banco_tarjeta(rm_j11[i].forma_pago)
		IF bco_tarj IS NULL OR bco_tarj = 3 THEN
			INITIALIZE rm_j11[i].num_cta_tarj TO NULL
			CLEAR ra_j11[j].j11_num_cta_tarj
		END IF
		IF rm_j11[i].forma_pago = 'DP' THEN
			IF  rm_j11[i].num_cta_tarj IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Digite cuenta de compañía.','exclamation')
				CALL fl_mostrar_mensaje('Digite cuenta de compañía.','exclamation')
				NEXT FIELD j11_num_cta_tarj
			END IF
			CALL fl_lee_banco_compania(vg_codcia, rm_j11[i].cod_bco_tarj,
				rm_j11[i].num_cta_tarj) RETURNING r_g09.*
			IF r_g09.g09_numero_cta IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'No existe cuenta en este banco.','exclamation')
				CALL fl_mostrar_mensaje('No existe cuenta en este banco.','exclamation')
				NEXT FIELD j11_num_cta_tarj
			END IF
		END IF
	AFTER DELETE
		LET vm_indice = arr_count()
		CALL calcula_total(vm_indice) RETURNING total
		EXIT INPUT
	AFTER INPUT
		LET vm_indice = arr_count()
		FOR i = 1 TO vm_indice 
			IF banco_tarjeta(rm_j11[i].forma_pago) = 1
			OR banco_tarjeta(rm_j11[i].forma_pago) = 2 
			THEN
				IF rm_j11[i].cod_bco_tarj IS NULL THEN
					--CALL fgl_winmessage(vg_producto,'Debe ingresar el código del banco o de la tarjeta.','exclamation')
					CALL fl_mostrar_mensaje('Debe ingresar el código del banco o de la tarjeta.','exclamation')
					NEXT FIELD j11_cod_bco_tarj
				END IF
				IF rm_j11[i].num_cta_tarj IS NULL THEN
					--CALL fgl_winmessage(vg_producto,'Debe ingresar el número de la cuenta o de la tarjeta.','exclamation')
					CALL fl_mostrar_mensaje('Debe ingresar el número de la cuenta o de la tarjeta.','exclamation')
					NEXT FIELD j11_num_cta_tarj
				END IF
			END IF
			IF rm_j11[i].forma_pago = vm_cheque
			OR rm_j11[i].forma_pago = 'TJ'
			OR rm_j11[i].forma_pago = 'RT'
			THEN
				IF rm_j11[i].num_ch_aut IS NULL THEN
					--CALL fgl_winmessage(vg_producto,'Debe ingresar el número del cheque/retención/aut. tarjeta.','exclamation')
					CALL fl_mostrar_mensaje('Debe ingresar el número del cheque/retención/aut. tarjeta.','exclamation')
					NEXT FIELD j11_num_ch_aut
				END IF
			END IF
			IF rm_j11[i].forma_pago = vm_cheque
			OR rm_j11[i].forma_pago = 'RT'
			THEN
				IF repetidos_num_ch_aut(i) THEN
					CALL fl_mostrar_mensaje('No puede repetir un mismo número de cheque o autorización.', 'exclamation')
					NEXT FIELD j11_num_ch_aut
				END IF
			END IF
		END FOR
		LET total = calcula_total(vm_indice)
		IF total <> rm_j10.j10_valor THEN
			IF total > rm_j10.j10_valor THEN
				LET valor_ef = valor_efectivo(vm_indice)
				LET vuelto = total - rm_j10.j10_valor
				IF valor_ef >= vuelto THEN 
					DISPLAY BY NAME vuelto
				ELSE
					--CALL fgl_winmessage(vg_producto,'El total en efectivo no es suficiente para el vuelto.','exclamation')
					CALL fl_mostrar_mensaje('El total en efectivo no es suficiente para el vuelto.','exclamation')
					CONTINUE INPUT
				END IF
			ELSE
				--CALL fgl_winmessage(vg_producto,'El total en la moneda de la facturación debe ser igual al valor a recaudar.','exclamation')
				CALL fl_mostrar_mensaje('El total en la moneda de la facturación debe ser igual al valor a recaudar.','exclamation')
				CONTINUE INPUT
			END IF 
		END IF
		IF rm_j10.j10_tipo_fuente = 'PR' OR
		   rm_j10.j10_tipo_fuente = 'PV' OR
		   rm_j10.j10_tipo_fuente = 'OT' THEN
			IF rm_r38.r38_num_sri IS NOT NULL THEN
				CALL validar_num_sri(1) RETURNING resul
				IF resul <> 1 THEN
					ROLLBACK WORK
					EXIT PROGRAM
				END IF
			END IF
		END IF
		LET salir = 1
END INPUT
IF INT_FLAG THEN
	--#RETURN
	EXIT WHILE
END IF

END WHILE

END FUNCTION



FUNCTION banco_tarjeta(forma_pago)

DEFINE forma_pago	LIKE cajt011.j11_codigo_pago
DEFINE ret_val		SMALLINT

-- En el CASE se le asignara:

-- 1 (UNO) a la variable ret_val si el codigo está relacionado a un
-- banco 
-- 2 (DOS) a la variable ret_val si el codigo está relacionado a una
-- tarjeta de crédito 
-- 3 (TRES) a la variable ret_val si el codigo requiere que se ingrese 
-- un numero pero no un banco ni tarjeta

CASE forma_pago
	WHEN vm_cheque LET ret_val = 1 
	WHEN 'CP' LET ret_val = 1 
	WHEN 'DP' LET ret_val = 1 
	WHEN 'CD' LET ret_val = 1 
	WHEN 'DA' LET ret_val = 1 
	
	WHEN 'TJ' LET ret_val = 2

	WHEN 'RT' LET ret_val = 3
	
	OTHERWISE  
		-- Estas formas de pago no necesitan informacion del
		-- banco o tarjeta de crédito:
		-- 'EF', 'OC', 'OT', 'RT'
		INITIALIZE ret_val TO NULL
END CASE 

RETURN ret_val

END FUNCTION



FUNCTION ayudas_bco_tarj(forma_pago)

DEFINE forma_pago		LIKE cajt011.j11_codigo_pago
DEFINE cod_bco_tarj		LIKE cajt011.j11_cod_bco_tarj

DEFINE r_g08			RECORD LIKE gent008.*
DEFINE r_g10			RECORD LIKE gent010.*

LET cod_bco_tarj = banco_tarjeta(forma_pago)

IF cod_bco_tarj = 1 THEN
	CALL fl_ayuda_bancos() RETURNING r_g08.g08_banco, r_g08.g08_nombre
	IF r_g08.g08_banco IS NOT NULL THEN
		LET cod_bco_tarj = r_g08.g08_banco
	ELSE
		INITIALIZE cod_bco_tarj TO NULL
	END IF
	RETURN cod_bco_tarj
END IF
IF cod_bco_tarj = 2 THEN
	CALL fl_ayuda_tarjeta() RETURNING r_g10.g10_tarjeta, r_g10.g10_nombre
	IF r_g10.g10_tarjeta IS NOT NULL THEN
		LET cod_bco_tarj = r_g10.g10_tarjeta
	ELSE
		INITIALIZE cod_bco_tarj TO NULL
	END IF
	RETURN cod_bco_tarj
END IF

IF cod_bco_tarj = 3 THEN
	INITIALIZE cod_bco_tarj TO NULL
	RETURN cod_bco_tarj
END IF

RETURN cod_bco_tarj

END FUNCTION



FUNCTION calcula_total(num_elm)

DEFINE i		SMALLINT
DEFINE num_elm		SMALLINT
DEFINE paridad		LIKE cajt011.j11_paridad

DEFINE total		LIKE cajt011.j11_valor

LET total = 0
FOR i = 1 TO num_elm
	IF rm_j11[i].valor IS NOT NULL THEN
		LET paridad = calcula_paridad(rm_j11[i].moneda,
					      rm_j10.j10_moneda)
		IF paridad IS NULL THEN
			--CALL fgl_winmessage(vg_producto,'No existe paridad de cambio para esta moneda.','stop')
			CALL fl_mostrar_mensaje('No existe paridad de cambio para esta moneda.','stop')
			EXIT PROGRAM
		END IF
		LET total = total + (rm_j11[i].valor * paridad)
	END IF
END FOR 

DISPLAY total TO total_mf

RETURN total

END FUNCTION



FUNCTION calcula_paridad(moneda_ori, moneda_dest)

DEFINE moneda_ori	LIKE gent013.g13_moneda
DEFINE moneda_dest	LIKE gent013.g13_moneda
DEFINE paridad		LIKE gent014.g14_tasa       

DEFINE r_g14		RECORD LIKE gent014.*

IF moneda_ori = moneda_dest THEN
	LET paridad = 1 
ELSE
	CALL fl_lee_factor_moneda(moneda_ori, moneda_dest) 
		RETURNING r_g14.*
	IF r_g14.g14_serial IS NULL THEN
		--CALL fgl_winmessage(vg_producto,'No existe factor de conversión para esta moneda.','exclamation')
		CALL fl_mostrar_mensaje('No existe factor de conversión para esta moneda.','exclamation')
		INITIALIZE paridad TO NULL
	ELSE
		LET paridad = r_g14.g14_tasa 
	END IF
END IF

RETURN paridad

END FUNCTION



FUNCTION ver_documento_origen()
DEFINE comando		CHAR(250)
DEFINE run_prog		CHAR(10)

IF rm_j10.j10_num_fuente IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'Debe especificar un documento primero.','exclamation')
	CALL fl_mostrar_mensaje('Debe especificar un documento primero.','exclamation')
	RETURN
END IF
{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}

CASE rm_j10.j10_tipo_fuente
	WHEN 'PR'	-- fglrun repp209 vg_base RE vg_codcia vg_codloc numprev
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
 			      'REPUESTOS', vg_separador, 'fuentes', 
			      vg_separador, run_prog, 'repp209 ', vg_base, ' ',
			      'RE', vg_codcia, ' ', vg_codloc,
			      ' ', rm_j10.j10_num_fuente 
	WHEN 'PV'	-- fglrun vehp201 vg_base VE vg_codcia vg_codloc numprev
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
 			      'VEHICULOS', vg_separador, 'fuentes', 
			      vg_separador, run_prog, 'vehp201 ', vg_base, ' ',
			      'VE', vg_codcia, ' ', vg_codloc,
			      ' ', rm_j10.j10_num_fuente 
	WHEN 'OT'	-- fglrun talp204 vg_base TA vg_codcia vg_codloc orden
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
 			      'TALLER', vg_separador, 'fuentes', 
			      vg_separador, run_prog, 'talp204 ', vg_base, ' ',
			      'TA', vg_codcia, ' ', vg_codloc,
			      ' ', rm_j10.j10_num_fuente, ' O'
	WHEN 'SC'	-- fglrun cxcp204 vg_base CO vg_codcia vg_codloc num_sol
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
 			      'COBRANZAS', vg_separador, 'fuentes', 
			      vg_separador, run_prog, 'cxcp204 ', vg_base, ' ',
			      'CO', vg_codcia, ' ', vg_codloc,
			      ' ', rm_j10.j10_num_fuente 
END CASE

RUN comando

END FUNCTION



FUNCTION calcular_retencion(i, j)
DEFINE i, j		SMALLINT
DEFINE r_r23		RECORD LIKE rept023.*
DEFINE r_t23		RECORD LIKE talt023.*

IF rm_j10.j10_tipo_fuente = 'PR' THEN
	CALL fl_lee_preventa_rep(vg_codcia, vg_codloc, rm_j10.j10_num_fuente)
		RETURNING r_r23.*
	LET rm_j11[i].valor = (r_r23.r23_tot_bruto - r_r23.r23_tot_dscto) * 0.01
END IF
IF rm_j10.j10_tipo_fuente = 'OT' THEN
	CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc, rm_j10.j10_num_fuente)
		RETURNING r_t23.*
	LET rm_j11[i].valor = (r_t23.t23_tot_bruto - r_t23.t23_tot_dscto) * 0.01
END IF
DISPLAY rm_j11[i].valor TO ra_j11[j].j11_valor

END FUNCTION



FUNCTION proceso_master_transacciones_caja()
DEFINE done 		SMALLINT
DEFINE comando		CHAR(250)
DEFINE run_prog		CHAR(10)
DEFINE r_z24		RECORD LIKE cxct024.*
DEFINE r_g37		RECORD LIKE gent037.*
DEFINE cont_cred	LIKE gent037.g37_cont_cred
DEFINE sec_sri		LIKE gent037.g37_sec_num_sri
DEFINE cuantos		SMALLINT
DEFINE modulo		CHAR(2)

{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF

-- 1: grabar detalles
IF rm_j10.j10_valor > 0 THEN
	CALL graba_detalle()
	CALL actualiza_acumulados_caja('I')
	IF rm_j10.j10_tipo_fuente = 'SC' THEN
		CALL actualiza_cheques_postfechados('B')
	END IF

END IF

-- 2: actualizar el estado de la cabecera a '*' y el codigo de caja

LET done = actualiza_cabecera('*')
IF NOT done THEN
	ROLLBACK WORK
	RETURN 
END IF 

COMMIT WORK

-- NOTA: esto se hace despues del COMMIT

-- 3: llamar al programa de YURI 

CASE rm_j10.j10_tipo_fuente
	WHEN 'PR' 	-- fglrun repp211 vg_base vg_codcia num_prev
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
	      		      'REPUESTOS', vg_separador, 'fuentes', 
			      vg_separador, run_prog, 'repp211 ', vg_base, ' ',
			      vg_codcia, ' ', vg_codloc, ' ', 
			       rm_j10.j10_num_fuente 

	WHEN 'PV' 	-- fglrun vehp203 vg_base vg_codcia num_prev
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
	      		      'VEHICULOS', vg_separador, 'fuentes', 
			      vg_separador, run_prog, 'vehp203 ', vg_base, ' ',
			      vg_codcia, ' ', vg_codloc, ' ', 
			       rm_j10.j10_num_fuente 

	WHEN 'OT' 	-- fglrun talp210 vg_base vg_codcia orden   
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
	      		      'TALLER', vg_separador, 'fuentes', 
			      vg_separador, run_prog, 'talp210 ', vg_base, ' ',
			      vg_codcia, ' ', vg_codloc, ' ', 
			       rm_j10.j10_num_fuente 
	WHEN 'SC' 	-- fglrun cajp20x vg_base vg_codcia num_sol 
		CALL fl_lee_solicitud_cobro_cxc(vg_codcia, vg_codloc,
			rm_j10.j10_num_fuente) RETURNING r_z24.*
		{- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE -}
		LET run_prog = 'fglrun '
		IF vg_gui = 0 THEN
			LET run_prog = 'fglgo '
		END IF
		{--- ---}
		IF r_z24.z24_tipo = 'P' THEN
			LET comando = run_prog, 'cajp204 ', vg_base, ' ',
			      vg_codcia, ' ', vg_codloc, ' ', 
			       rm_j10.j10_num_fuente 
		ELSE
			LET comando = run_prog, 'cajp205 ', vg_base, ' ',
			      vg_codcia, ' ', vg_codloc, ' ', 
			       rm_j10.j10_num_fuente 
		END IF
END CASE

RUN comando

-- 4: volver a leer el registro

CALL fl_lee_cabecera_caja(vg_codcia, vg_codloc, rm_j10.j10_tipo_fuente,
	rm_j10.j10_num_fuente) RETURNING rm_j10.*
	
-- 5: si el estado de la cabecera caMbio a 'P' todo OK

IF rm_j10.j10_estado = 'P' THEN
	BEGIN WORK
	CALL actualiza_acumulados_tipo_transaccion('I')
	IF rm_j10.j10_tipo_fuente = 'PR' OR rm_j10.j10_tipo_fuente = 'PV' OR
	   rm_j10.j10_tipo_fuente = 'OT' THEN
		CALL retorna_cont_cred() RETURNING cont_cred
		WHENEVER ERROR CONTINUE
		DECLARE q_sri CURSOR FOR
			SELECT * FROM gent037
				WHERE g37_compania  =  vg_codcia
				  AND g37_localidad =  vg_codloc
				  AND g37_tipo_doc  =  vm_tipo_doc
		  		  AND g37_cont_cred =  cont_cred
			  	  AND g37_fecha_emi <= DATE(TODAY)
			  	  AND g37_fecha_exp >= DATE(TODAY)
			FOR UPDATE
		OPEN q_sri
		FETCH q_sri INTO r_g37.*
		IF STATUS < 0 THEN
			ROLLBACK WORK
			CALL fl_mostrar_mensaje('Lo siento ahora no puede modificar este No. del SRI, porque ésta secuencia se encuentra bloqueada por otro usuario.','stop')
			WHENEVER ERROR STOP
			EXIT PROGRAM
		END IF
		WHENEVER ERROR STOP
		LET cuantos = 8 + r_g37.g37_num_dig_sri
		LET sec_sri = rm_r38.r38_num_sri[9, cuantos] USING "########"
		UPDATE gent037 SET g37_sec_num_sri = sec_sri
			WHERE g37_compania    = r_g37.g37_compania
			  AND g37_localidad   = r_g37.g37_localidad
			  AND g37_tipo_doc    = r_g37.g37_tipo_doc
			  AND g37_secuencia   = r_g37.g37_secuencia
			  AND g37_sec_num_sri <= sec_sri
		INSERT INTO rept038
			VALUES (vg_codcia, vg_codloc, rm_j10.j10_tipo_fuente,  
			        rm_j10.j10_tipo_destino,
				rm_j10.j10_num_destino, rm_r38.r38_num_sri)
	END IF
	IF num_args() = 7 THEN
		CASE rm_j10.j10_tipo_fuente
			WHEN 'PR'
				UPDATE rept088
					SET r88_cod_fact_nue =
							rm_j10.j10_tipo_destino,
					   r88_num_fact_nue =
							rm_j10.j10_num_destino
					WHERE r88_compania    = vg_codcia
					  AND r88_localidad   = vg_codloc
					  AND r88_numprev_nue =
							rm_j10.j10_num_fuente
				IF STATUS < 0 THEN
					ROLLBACK WORK
					CALL fl_mostrar_mensaje('Ha ocurrido un error al Actualizar la Factura Nueva en la tabla rept088.', 'stop')
					EXIT PROGRAM
				END IF
			WHEN 'OT'
				UPDATE talt060
					SET t60_fac_nue = rm_j10.j10_num_destino
					WHERE t60_compania  = vg_codcia
					  AND t60_localidad = vg_codloc
					  AND t60_ot_nue    =
							rm_j10.j10_num_fuente
				IF STATUS < 0 THEN
					ROLLBACK WORK
					CALL fl_mostrar_mensaje('Ha ocurrido un error al Actualizar la Factura Nueva en la tabla talt060.', 'stop')
					EXIT PROGRAM
				END IF
		END CASE
	END IF
	COMMIT WORK
	CALL imprime_comprobante()
	IF num_args() = 7 THEN
		--CALL fl_mostrar_mensaje('Forma de Pago en Caja Generada Ok.', 'info')
	ELSE
		CALL fl_mostrar_mensaje('Proceso Terminado OK.','info')
	END IF
	RETURN 
END IF

-- 6: si el estado sigue en '*' 

BEGIN WORK

IF rm_j10.j10_estado = '*' THEN
	--CALL fgl_winmessage(vg_producto,'Proceso no pudo terminar correctamente.','exclamation')
	CALL fl_mostrar_mensaje('Proceso no pudo terminar correctamente.','exclamation')

--	6.1:	borrar detalles
	IF rm_j10.j10_valor > 0 THEN
		IF rm_j10.j10_tipo_fuente = 'SC' THEN
			CALL actualiza_cheques_postfechados('A')
		END IF
		CALL actualiza_acumulados_caja('D')

		LET done = 0
		WHILE NOT done
			LET done = elimina_detalle()
		END WHILE
	END IF

--	6.2:	regresar el estado a 'A'
	LET done = 0 
	INITIALIZE rm_j10.j10_codigo_caja TO NULL
	WHILE NOT done 
		LET done = actualiza_cabecera('A')
	END WHILE
END IF

COMMIT WORK

END FUNCTION



FUNCTION actualiza_cabecera(estado)

DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT

DEFINE estado		CHAR(1)

LET intentar = 1
LET done = 0
WHENEVER ERROR CONTINUE
WHILE (intentar)
		DECLARE q_j10 CURSOR FOR
			SELECT * FROM cajt010
				WHERE j10_compania    = vg_codcia         
				  AND j10_localidad   = vg_codloc          
				  AND j10_tipo_fuente = rm_j10.j10_tipo_fuente
				  AND j10_num_fuente  = rm_j10.j10_num_fuente
			FOR UPDATE
	OPEN q_j10
	FETCH q_j10 
	IF STATUS < 0 THEN
		LET intentar = mensaje_intentar()
	ELSE
		LET intentar = 0
		LET done = 1
	END IF
END WHILE
WHENEVER ERROR STOP

IF NOT intentar AND NOT done THEN
	RETURN done
END IF


	UPDATE cajt010 SET j10_estado      = estado,
			   j10_codigo_caja = rm_j04.j04_codigo_caja,
			   j10_fecha_pro   = CURRENT
		WHERE CURRENT OF q_j10 

CLOSE q_j10

RETURN done

END FUNCTION



FUNCTION elimina_detalle()

DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT

LET intentar = 1
LET done = 0
WHILE (intentar)
	WHENEVER ERROR CONTINUE
		DECLARE q_j11 CURSOR FOR
			SELECT * FROM cajt011
				WHERE j11_compania    = vg_codcia         
				  AND j11_localidad   = vg_codloc          
				  AND j11_tipo_fuente = rm_j10.j10_tipo_fuente
				  AND j11_num_fuente  = rm_j10.j10_num_fuente
			FOR UPDATE
	WHENEVER ERROR STOP
	IF STATUS < 0 THEN
		LET intentar = mensaje_intentar()
	ELSE
		LET intentar = 0
		LET done = 1
	END IF
END WHILE

IF NOT intentar AND NOT done THEN
	RETURN done
END IF

FOREACH q_j11
	DELETE FROM cajt011 WHERE CURRENT OF q_j11         
END FOREACH

RETURN done

END FUNCTION



FUNCTION graba_detalle()

DEFINE i		SMALLINT              
DEFINE secuencia 	SMALLINT

DEFINE r_j11		RECORD LIKE cajt011.*

DEFINE total		LIKE cajt011.j11_valor
DEFINE vuelto		LIKE cajt011.j11_valor
DEFINE valor		LIKE cajt011.j11_valor
DEFINE paridad		LIKE cajt011.j11_paridad

LET total = calcula_total(vm_indice)
IF total > rm_j10.j10_valor THEN
	LET vuelto = total - rm_j10.j10_valor
END IF

LET secuencia = 1
FOR i = 1 TO vm_indice 

	INITIALIZE r_j11.* TO NULL

	LET r_j11.j11_compania    = vg_codcia
	LET r_j11.j11_localidad   = vg_codloc
	LET r_j11.j11_tipo_fuente = rm_j10.j10_tipo_fuente
	LET r_j11.j11_num_fuente  = rm_j10.j10_num_fuente

	LET r_j11.j11_protestado  = 'N'

	LET paridad = calcula_paridad(rm_j11[i].moneda, rm_j10.j10_moneda)
	IF paridad IS NULL THEN
		--CALL fgl_winmessage(vg_producto,'No existe paridad de cambio para esta moneda.','stop')
		CALL fl_mostrar_mensaje('No existe paridad de cambio para esta moneda.','stop')
		EXIT PROGRAM
	END IF
	IF vuelto > 0 AND rm_j11[i].forma_pago = vm_efectivo THEN
		LET valor = rm_j11[i].valor * paridad
		IF valor > vuelto THEN
			LET rm_j11[i].valor = 
				rm_j11[i].valor - (vuelto / paridad)
			LET vuelto = 0
		ELSE
			LET rm_j11[i].valor = 0
			LET vuelto = vuelto - valor
		END IF
	END IF
	
	IF rm_j11[i].valor = 0 THEN
		CONTINUE FOR
	END IF

	LET r_j11.j11_secuencia   = secuencia
	LET secuencia = secuencia + 1
	LET r_j11.j11_codigo_pago = rm_j11[i].forma_pago
	LET r_j11.j11_moneda      = rm_j11[i].moneda
	LET r_j11.j11_paridad     = paridad
	LET r_j11.j11_valor       = rm_j11[i].valor
	IF banco_tarjeta(rm_j11[i].forma_pago) IS NOT NULL THEN
		LET r_j11.j11_cod_bco_tarj = rm_j11[i].cod_bco_tarj
		LET r_j11.j11_num_ch_aut   = rm_j11[i].num_ch_aut
		LET r_j11.j11_num_cta_tarj = rm_j11[i].num_cta_tarj
	END IF
	
	INSERT INTO cajt011 VALUES (r_j11.*)
END FOR 

END FUNCTION



FUNCTION mensaje_intentar()

DEFINE intentar		SMALLINT
DEFINE resp		CHAR(6)

LET intentar = 1
--CALL fgl_winquestion(vg_producto,'Registro bloqueado por otro usuario, desea intentarlo nuevamente','No','Yes|No','question',1)
CALL fl_hacer_pregunta('Registro bloqueado por otro usuario, desea intentarlo nuevamente','No')
	RETURNING resp
IF resp = 'No' THEN
	CALL fl_mensaje_abandonar_proceso()
		 RETURNING resp
	IF resp = 'Yes' THEN
		LET intentar = 0
	END IF	
END IF

RETURN intentar

END FUNCTION



FUNCTION caja_aperturada(moneda)

DEFINE moneda		LIKE gent013.g13_moneda
DEFINE caja		SMALLINT

LET caja = 0

SELECT COUNT(*) INTO caja FROM cajt005
      	WHERE j05_compania     = rm_j04.j04_compania
          AND j05_localidad    = rm_j04.j04_localidad
          AND j05_codigo_caja  = rm_j04.j04_codigo_caja
          AND j05_fecha_aper   = rm_j04.j04_fecha_aper
          AND j05_secuencia    = rm_j04.j04_secuencia
          AND j05_moneda       = moneda

RETURN caja

END FUNCTION



FUNCTION aperturar_caja(moneda) 

DEFINE caja		SMALLINT
DEFINE moneda		LIKE gent013.g13_moneda

DEFINE r_j05		RECORD LIKE cajt005.*

INITIALIZE r_j05.* TO NULL
        
LET r_j05.j05_compania    = vg_codcia
LET r_j05.j05_localidad   = vg_codloc
LET r_j05.j05_codigo_caja = rm_j04.j04_codigo_caja
LET r_j05.j05_fecha_aper  = rm_j04.j04_fecha_aper
LET r_j05.j05_secuencia   = rm_j04.j04_secuencia
LET r_j05.j05_moneda      = moneda
LET r_j05.j05_ef_apertura = 0
LET r_j05.j05_ch_apertura = 0
LET r_j05.j05_ef_ing_dia  = 0
LET r_j05.j05_ch_ing_dia  = 0
LET r_j05.j05_ef_egr_dia  = 0
LET r_j05.j05_ch_egr_dia  = 0

INSERT INTO cajt005 VALUES (r_j05.*)		
	
RETURN r_j05.*

END FUNCTION



FUNCTION actualiza_acumulados_caja(flag)

DEFINE flag 		CHAR(1)
-- I: actualizacion en incremento
-- D: actualizacion en decremento (se multiplica por menos uno [-1])

DEFINE codigo_pago	LIKE cajt011.j11_codigo_pago
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE valor		LIKE cajt011.j11_valor

DEFINE tot_ing_ch	LIKE cajt005.j05_ch_ing_dia
DEFINE tot_ing_ef	LIKE cajt005.j05_ef_ing_dia
DEFINE r_j05		RECORD LIKE cajt005.*

DECLARE q_cajas_j11 CURSOR FOR
	SELECT j11_codigo_pago, j11_moneda, SUM(j11_valor)
		FROM cajt011
		WHERE j11_compania    = vg_codcia
		  AND j11_localidad   = vg_codloc
		  AND j11_tipo_fuente = rm_j10.j10_tipo_fuente
		  AND j11_num_fuente  = rm_j10.j10_num_fuente
		  AND j11_codigo_pago IN (vm_efectivo, vm_cheque)
	GROUP BY j11_codigo_pago, j11_moneda

FOREACH q_cajas_j11 INTO codigo_pago, moneda, valor
	IF flag = 'D' THEN
		LET valor = valor * (-1)
	END IF

	IF NOT caja_aperturada(moneda) THEN
		CALL aperturar_caja(moneda) RETURNING r_j05.* 
		IF r_j05.j05_moneda IS NULL THEN
			ROLLBACK WORK
			EXIT PROGRAM
		END IF
	END IF


	WHENEVER ERROR CONTINUE
	SET LOCK MODE TO WAIT 3

	DECLARE q_caja_j05 CURSOR FOR
		SELECT j05_ef_ing_dia, j05_ch_ing_dia
			FROM cajt005 
			WHERE j05_compania    = rm_j04.j04_compania
			  AND j05_localidad   = rm_j04.j04_localidad
			  AND j05_codigo_caja = rm_j04.j04_codigo_caja
			  AND j05_fecha_aper  = rm_j04.j04_fecha_aper
			  AND j05_secuencia   = rm_j04.j04_secuencia
			  AND j05_moneda      = moneda
		FOR UPDATE OF j05_ef_ing_dia, j05_ch_ing_dia
	
	SET LOCK MODE TO NOT WAIT
	WHENEVER ERROR STOP

	IF STATUS < 0 THEN
		--CALL fgl_winmessage(vg_producto,'Registro de caja bloqueado.','exclamation')
		CALL fl_mostrar_mensaje('Registro de caja bloqueado.','exclamation')
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
	SET LOCK MODE TO WAIT
	OPEN  q_caja_j05
	FETCH q_caja_j05 INTO tot_ing_ef, tot_ing_ch

		IF codigo_pago = vm_efectivo THEN
			LET tot_ing_ef = tot_ing_ef + valor
		ELSE
			LET tot_ing_ch = tot_ing_ch + valor
		END IF

		UPDATE cajt005 SET j05_ef_ing_dia = tot_ing_ef,
		    		   j05_ch_ing_dia = tot_ing_ch
			WHERE CURRENT OF q_caja_j05
	
	CLOSE q_caja_j05
	FREE  q_caja_j05
END FOREACH
FREE q_cajas_j11

END FUNCTION



FUNCTION actualiza_acumulados_tipo_transaccion(flag)

DEFINE flag 		CHAR(1)
-- I: actualizacion en incremento
-- D: actualizacion en decremento (se multiplica por menos uno [-1])

DEFINE codigo_pago	LIKE cajt011.j11_codigo_pago
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE valor		LIKE cajt013.j13_valor

DEFINE r_j13		RECORD LIKE cajt013.*


DECLARE q_cajas_j13 CURSOR FOR
	SELECT j11_codigo_pago, j11_moneda, SUM(j11_valor)
		FROM cajt011
		WHERE j11_compania    = vg_codcia
		  AND j11_localidad   = vg_codloc
		  AND j11_tipo_fuente = rm_j10.j10_tipo_fuente
		  AND j11_num_fuente  = rm_j10.j10_num_fuente
	GROUP BY j11_codigo_pago, j11_moneda

FOREACH q_cajas_j13 INTO codigo_pago, moneda, valor
	IF flag = 'D' THEN
		LET valor = valor * (-1)
	END IF

	SET LOCK MODE TO WAIT 3
	WHENEVER ERROR CONTINUE
		DECLARE q_j13 CURSOR FOR 
			SELECT * FROM cajt013
				WHERE j13_compania     = vg_codcia
				  AND j13_localidad    = vg_codloc
				  AND j13_codigo_caja  = rm_j02.j02_codigo_caja
				  AND j13_fecha        = TODAY
				  AND j13_moneda       = moneda
				  AND j13_trn_generada = rm_j10.j10_tipo_destino
				  AND j13_codigo_pago  = codigo_pago
			FOR UPDATE
	WHENEVER ERROR STOP
	SET LOCK MODE TO NOT WAIT
	
	IF STATUS < 0 THEN
		ROLLBACK WORK
		--CALL fgl_winmessage(vg_producto,'No se pueden actualizar los acumulados.','exclamation')
		CALL fl_mostrar_mensaje('No se pueden actualizar los acumulados.','exclamation')
		EXIT PROGRAM
	END IF

	INITIALIZE r_j13.* TO NULL
	OPEN  q_j13
	FETCH q_j13 INTO r_j13.*
		IF STATUS = NOTFOUND THEN
			-- El registro no existe, hay que grabarlo
			LET r_j13.j13_compania     = vg_codcia
			LET r_j13.j13_localidad    = vg_codloc
			LET r_j13.j13_codigo_caja  = rm_j02.j02_codigo_caja
			LET r_j13.j13_fecha        = TODAY
			LET r_j13.j13_moneda       = moneda
			LET r_j13.j13_trn_generada = rm_j10.j10_tipo_destino
			LET r_j13.j13_codigo_pago  = codigo_pago
			LET r_j13.j13_valor        = valor
		
			INSERT INTO cajt013 VALUES(r_j13.*)
		ELSE
			UPDATE cajt013 SET j13_valor = j13_valor + valor
				WHERE CURRENT OF q_j13
		END IF
	CLOSE q_j13
	FREE  q_j13
END FOREACH


END FUNCTION



FUNCTION actualiza_cheques_postfechados(estado)
DEFINE estado		CHAR(1)

WHENEVER ERROR CONTINUE
SET LOCK MODE TO WAIT 5
DECLARE q_che_post CURSOR FOR
	SELECT z26_estado FROM cxct026
		WHERE EXISTS (SELECT z26_compania, z26_localidad, z26_codcli,
				z26_banco, z26_num_cta, z26_num_cheque
	  			FROM cajt011
	  			WHERE j11_compania     = vg_codcia
	  		  	  AND j11_localidad    = vg_codloc
	  			  AND j11_tipo_fuente  = rm_j10.j10_tipo_fuente
	  			  AND j11_num_fuente   = rm_j10.j10_num_fuente
	  			  AND j11_codigo_pago  = 'CP'
	  			  AND j11_protestado   = 'N'
	  			  AND z26_compania     = j11_compania
	  			  AND z26_localidad    = j11_localidad
	  			  AND z26_codcli       = rm_j10.j10_codcli
	  			  AND z26_banco        = j11_cod_bco_tarj
	  			  AND z26_num_cta      = j11_num_cta_tarj
	  			  AND z26_num_cheque   = j11_num_ch_aut
	  			  AND z26_estado      <> estado)
	FOR UPDATE OF z26_estado

SET LOCK MODE TO NOT WAIT

IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No se ha podido actualizar el estado de los cheques postfechados.','exclamation')
	EXIT PROGRAM
END IF

WHENEVER ERROR STOP

FOREACH q_che_post
	UPDATE cxct026 SET z26_estado = estado WHERE CURRENT OF q_che_post
END FOREACH
 

END FUNCTION



FUNCTION setea_botones()

--#DISPLAY 'FP'			TO 	bt_codigo_pago
--#DISPLAY 'Mon'		TO 	bt_moneda
--#DISPLAY 'Bco/Tarj'		TO 	bt_bco_tarj
--#DISPLAY 'Nro. Che./Aut.'	TO 	bt_che_aut
--#DISPLAY 'Nro. Cta./Tarj.'	TO 	bt_cta_tarj
--#DISPLAY 'Valor'		TO 	bt_valor

END FUNCTION



FUNCTION execute_query()

SELECT ROWID INTO vm_rowid
	FROM cajt010
	WHERE j10_compania    = vg_codcia
	  AND j10_localidad   = vg_codloc
	  AND j10_tipo_fuente = vm_tipo_fuente
	  AND j10_num_fuente  = vm_num_fuente

IF STATUS = NOTFOUND THEN
	--CALL fgl_winmessage(vg_producto,'No existe forma de pago.','exclamation')
	CALL fl_mostrar_mensaje('No existe forma de pago.','exclamation')
	EXIT PROGRAM	
ELSE
	IF num_args() <> 7 THEN
		CALL lee_muestra_registro(vm_rowid)
	END IF
END IF

END FUNCTION



FUNCTION lee_muestra_registro(row)
DEFINE row 		INTEGER
DEFINE modulo		CHAR(2)

SELECT * INTO rm_j10.* FROM cajt010 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

DISPLAY BY NAME rm_j10.j10_tipo_fuente, 
		rm_j10.j10_num_fuente,
		rm_j10.j10_areaneg,
		rm_j10.j10_codcli,
		rm_j10.j10_nomcli,
		rm_j10.j10_moneda,
		rm_j10.j10_tipo_destino,
		rm_j10.j10_num_destino,
		rm_j10.j10_valor,
		rm_j10.j10_fecha_pro,
		rm_j10.j10_usuario
	      	
IF vg_gui = 0 THEN
	CALL muestra_tipo_fuente(rm_j10.j10_tipo_fuente)
END IF
IF rm_j10.j10_tipo_destino = vm_tipo_doc THEN
	SELECT r38_num_sri INTO rm_r38.r38_num_sri
		FROM rept038
		WHERE r38_compania    = vg_codcia
	  	  AND r38_localidad   = vg_codloc
	  	  AND r38_tipo_fuente = rm_j10.j10_tipo_fuente
	  	  AND r38_cod_tran    = rm_j10.j10_tipo_destino
	  	  AND r38_num_tran    = rm_j10.j10_num_destino 
	DISPLAY BY NAME rm_r38.r38_num_sri
END IF
CALL muestra_registro()
CALL muestra_detalle()

END FUNCTION



FUNCTION muestra_detalle()

DEFINE i		SMALLINT
DEFINE filas_pant	SMALLINT

DEFINE dummy		LIKE cajt011.j11_valor

CALL retorna_arreglo()

LET filas_pant = vm_size_arr
FOR i = 1 TO filas_pant
	CLEAR ra_j11[i].*
END FOR

DECLARE q_detalle CURSOR FOR
	SELECT j11_codigo_pago,  j11_moneda, j11_cod_bco_tarj, j11_num_ch_aut, 
	       j11_num_cta_tarj, j11_valor 
		FROM cajt011
		WHERE j11_compania    = vg_codcia
		  AND j11_localidad   = vg_codloc
		  AND j11_tipo_fuente = rm_j10.j10_tipo_fuente
		  AND j11_num_fuente  = rm_j10.j10_num_fuente

LET i = 1
FOREACH q_detalle INTO rm_j11[i].*
	LET i = i + 1
	IF i > vm_max_rows THEN
		EXIT FOREACH
	END IF
END FOREACH

LET i = i - 1

IF i > 0 THEN
	CALL calcula_total(i) RETURNING dummy
	CALL set_count(i)
ELSE
	--CALL fgl_winmessage(vg_producto,'No hay detalle de forma de pago.','exclamation')
	CALL fl_mostrar_mensaje('No hay detalle de forma de pago.','exclamation')
	EXIT PROGRAM
END IF
DISPLAY ARRAY rm_j11 TO ra_j11.*
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	--#BEFORE DISPLAY
		--#CALL setea_botones()
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
END DISPLAY

END FUNCTION



FUNCTION valor_efectivo(num_elm)

DEFINE num_elm		SMALLINT
DEFINE i		SMALLINT
DEFINE paridad		LIKE cajt011.j11_paridad

DEFINE valor		LIKE cajt011.j11_valor

LET valor = 0
FOR i = 1 TO num_elm
	IF rm_j11[i].forma_pago = vm_efectivo THEN
		LET paridad = calcula_paridad(rm_j11[i].moneda,
					      rm_j10.j10_moneda)
		IF paridad IS NULL THEN
			--CALL fgl_winmessage(vg_producto,'No existe paridad de cambio para esta moneda.','stop')
			CALL fl_mostrar_mensaje('No existe paridad de cambio para esta moneda.','stop')
			EXIT PROGRAM
		END IF
		LET valor = valor + (rm_j11[i].valor * paridad)
	END IF
END FOR

RETURN valor

END FUNCTION



FUNCTION repetidos_num_ch_aut(i)
DEFINE i, j, resul	INTEGER

LET resul = 0
FOR i = 1 TO vm_indice - 1
	FOR j = i + 1 TO vm_indice
		IF rm_j11[i].cod_bco_tarj = rm_j11[j].cod_bco_tarj AND
		   rm_j11[i].num_ch_aut = rm_j11[j].num_ch_aut THEN
			LET resul = 1
			EXIT FOR
		END IF
	END FOR
	IF resul THEN
		EXIT FOR
	END IF
END FOR
RETURN resul

END FUNCTION



FUNCTION imprime_comprobante()
DEFINE comando		VARCHAR(250)
DEFINE r_r23		RECORD LIKE rept023.* 	-- Preventa Repuestos
DEFINE r_r34		RECORD LIKE rept034.* 	-- Orden de Despacho
DEFINE r_v26		RECORD LIKE veht026.* 	-- Preventa Vehiculos
DEFINE r_t23		RECORD LIKE talt023.*	-- Orden de Trabajo
DEFINE r_z24		RECORD LIKE cxct024.*	-- Solicitud Cobro Clientes
DEFINE run_prog		CHAR(10)

INITIALIZE comando TO NULL
{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
CASE rm_j10.j10_tipo_fuente 
	WHEN 'PR'
		CALL fl_lee_preventa_rep(vg_codcia, vg_codloc,
			rm_j10.j10_num_fuente) RETURNING r_r23.*

		LET comando = 'cd ..', vg_separador, '..', vg_separador,
			      'REPUESTOS', vg_separador, 'fuentes', 
			      vg_separador, run_prog, 'repp410 ', vg_base, ' ',
			      'RE', vg_codcia, ' ', vg_codloc, ' "',
			      r_r23.r23_cod_tran, '" ', r_r23.r23_num_tran 
	WHEN 'OT'
		CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc,
			rm_j10.j10_num_fuente) RETURNING r_t23.*

		LET comando = 'cd ..', vg_separador, '..', vg_separador,
 			      'TALLER', vg_separador, 'fuentes', 
			      vg_separador, run_prog, 'talp403 ', vg_base, ' ',
			      'TA', ' ', vg_codcia, ' ', vg_codloc, ' ',
			      r_t23.t23_num_factura
	WHEN 'SC'
		CALL fl_lee_solicitud_cobro_cxc(vg_codcia, vg_codloc,
						rm_j10.j10_num_fuente)
						RETURNING r_z24.*
		IF r_z24.z24_tipo = 'A' THEN
			LET comando = 'cd ..', vg_separador, '..', vg_separador,
 				      'CAJA', vg_separador, 'fuentes', 
				      vg_separador, run_prog, 'cajp401 ', 
				      vg_base, ' ', 'CG', vg_codcia, ' ', 
				      vg_codloc, ' ', r_z24.z24_numero_sol 
		ELSE
			LET comando = 'cd ..', vg_separador, '..', vg_separador,
 				      'CAJA', vg_separador, 'fuentes', 
				      vg_separador, run_prog, 'cajp400 ', 
				      vg_base, ' ', 'CG', vg_codcia, ' ', 
				      vg_codloc, ' ', r_z24.z24_numero_sol 
		END IF
END CASE

IF comando IS NOT NULL THEN
	RUN comando
	IF rm_j10.j10_tipo_fuente = 'PR' THEN
		--IF r_r23.r23_num_ot IS NULL THEN
			LET comando = NULL
			DECLARE q_r34 CURSOR FOR
				SELECT * FROM rept034
					WHERE r34_compania  = vg_codcia
					  AND r34_localidad = vg_codloc
					  AND r34_cod_tran  = r_r23.r23_cod_tran
					  AND r34_num_tran  = r_r23.r23_num_tran
			OPEN q_r34
			FOREACH q_r34 INTO r_r34.*
				LET comando = 'cd ..', vg_separador, '..',
						vg_separador,
				      'REPUESTOS', vg_separador, 'fuentes', 
				      vg_separador, run_prog, 'repp431 ',
				      vg_base, ' RE ', vg_codcia, ' ',
				      vg_codloc, ' "', r_r34.r34_bodega, '" ',
				      r_r34.r34_num_ord_des 
				RUN comando
			END FOREACH
		--END IF 
	END IF 
	IF rm_j10.j10_tipo_fuente = 'OT' THEN
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
 			      'TALLER', vg_separador, 'fuentes', 
			      vg_separador, run_prog, 'talp408 ', vg_base, ' ',
			      'TA', ' ', vg_codcia, ' ', vg_codloc, ' ',
			      r_t23.t23_orden
		RUN comando
	END IF 
END IF

END FUNCTION



FUNCTION retorna_arreglo()
--#LET vm_size_arr = fgl_scr_size('r_detalle')
IF vg_gui = 0 THEN
        LET vm_size_arr = 5
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
DISPLAY '<F5>      Ver Documento'            AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION control_visor_teclas_caracter_2() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Ver Documento'            AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Calcular Retención'       AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F7>      Calcular Diferencia'      AT a,2
DISPLAY  'F7' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION muestra_tipo_fuente(tipo)
DEFINE tipo		LIKE cajt010.j10_tipo_fuente

IF tipo = 'OT' THEN
	DISPLAY 'ORDEN DE TRABAJO' TO tit_tipo_fuente
END IF
IF tipo = 'PR' THEN
	DISPLAY 'PREVENTA DE INVENTARIOS' TO tit_tipo_fuente
END IF
{--
IF tipo = 'PV' THEN
	DISPLAY 'PREVENTA DE VEHICULOS' TO tit_tipo_fuente
END IF
--}
IF tipo = 'SC' THEN
	DISPLAY 'SOLICITUD COBRO CLIENTES' TO tit_tipo_fuente
END IF
IF tipo = 'OI' THEN
	DISPLAY 'OTROS INGRESOS' TO tit_tipo_fuente
END IF
IF tipo = 'EC' THEN
	DISPLAY 'EGRESOS DE CAJA' TO tit_tipo_fuente
END IF

END FUNCTION
