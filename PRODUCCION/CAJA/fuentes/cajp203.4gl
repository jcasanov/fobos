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
DEFINE rm_j14		RECORD LIKE cajt014.*
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

DEFINE rm_detret	ARRAY[50] OF RECORD
				j14_tipo_ret	LIKE cajt014.j14_tipo_ret,
				j14_porc_ret	LIKE cajt014.j14_porc_ret,
				j14_codigo_sri	LIKE cajt014.j14_codigo_sri,
				c03_concepto_ret LIKE ordt003.c03_concepto_ret,
				j14_base_imp	LIKE cajt014.j14_base_imp,
				j14_valor_ret	LIKE cajt014.j14_valor_ret
			END RECORD
DEFINE fec_ini_por	ARRAY[50] OF LIKE cajt014.j14_fec_ini_porc
DEFINE rm_adi_r		ARRAY[50] OF RECORD
				tipo_fuente	LIKE cajt010.j10_tipo_fuente,
				cod_tr		LIKE cajt010.j10_tipo_destino,
				num_tr		LIKE cajt010.j10_num_destino,
				num_sri		LIKE rept038.r38_num_sri,
				tipo_doc	LIKE rept038.r38_tipo_doc,
				fec_fact	DATE
			END RECORD
DEFINE vm_num_ret	SMALLINT
DEFINE vm_max_ret	SMALLINT
DEFINE tot_base_imp	DECIMAL(12,2)
DEFINE tot_valor_ret	DECIMAL(12,2)
DEFINE rm_detsol	ARRAY[200] OF RECORD
				z20_localidad	LIKE cxct020.z20_localidad,
				z20_tipo_doc	LIKE cxct020.z20_tipo_doc,
				num_doc		LIKE cxct020.z20_num_tran,
				num_sri		LIKE rept038.r38_num_sri,
				z20_fecha_emi	LIKE cxct020.z20_fecha_emi,
				valor_ret	DECIMAL(12,2)
			END RECORD
DEFINE rm_adi		ARRAY[200] OF RECORD
				z20_num_doc	LIKE cxct020.z20_num_tran,
				z20_dividendo	LIKE cxct020.z20_dividendo,
				z25_numero_sol	LIKE cxct025.z25_numero_sol,
				z24_areaneg	LIKE cxct024.z24_areaneg,
				z20_cod_tran	LIKE cxct020.z20_cod_tran,
				num_ret_s	LIKE cajt014.j14_num_ret_sri
			END RECORD
DEFINE vm_num_sol	SMALLINT
DEFINE vm_max_sol	SMALLINT
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT



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
CREATE TEMP TABLE tmp_ret
	(
		cod_pago		CHAR(2),
		num_ret_sri		CHAR(21),
		autorizacion		VARCHAR(15,10),
		fecha_emi		DATE,
		tipo_ret		CHAR(1),
		porc_ret		DECIMAL(5,2),
		codigo_sri		CHAR(6),
		concepto_ret		VARCHAR(200,100),
		base_imp		DECIMAL(12,2),
		valor_ret		DECIMAL(12,2),
		tipo_fuente		CHAR(2),
		cod_tr			CHAR(2),
		num_tr			VARCHAR(21),
		num_fac_sri		CHAR(21),
		tipo_doc		CHAR(2),
		fec_fact		DATE,
		fec_ini_porc		DATE
	)
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
LET vm_max_sol  = 200

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
		  AND j04_fecha_aper  = vg_fecha
		  AND j04_secuencia   = (SELECT MAX(j04_secuencia) 
		  			FROM cajt004
	  				WHERE j04_compania  = vg_codcia
	  				  AND j04_localidad = vg_codloc
	  				  AND j04_codigo_caja 
	  				  	= rm_j02.j02_codigo_caja
	  				  AND j04_fecha_aper  = vg_fecha)
	
	IF STATUS = NOTFOUND THEN 
		CALL fl_mostrar_mensaje('La caja no esta aperturada.', 'stop')
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
		WHENEVER ERROR CONTINUE
		DECLARE qu_lopr CURSOR FOR SELECT * FROM rept023
			WHERE r23_compania  = rm_j10.j10_compania AND 
			      r23_localidad = rm_j10.j10_localidad AND 
			      r23_numprev   = rm_j10.j10_num_fuente
			FOR UPDATE
		OPEN qu_lopr 
		FETCH qu_lopr INTO r_r23.*
		IF status < 0 OR status = NOTFOUND THEN
			ROLLBACK WORK
			CALL fl_mostrar_mensaje('Registro ya no existe o esta bloqueado por otro proceso.','stop')
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
			DELETE FROM tmp_ret
			ROLLBACK WORK
			CONTINUE WHILE
		END IF
	END IF
	
	CALL proceso_master_transacciones_caja()
END WHILE

CLOSE WINDOW w_203
DROP TABLE tmp_ret
EXIT PROGRAM

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
		  AND j04_fecha_aper  = vg_fecha
		  AND j04_secuencia   = (SELECT MAX(j04_secuencia) 
	  			FROM cajt004
  				WHERE j04_compania  = vg_codcia
  				  AND j04_localidad = vg_codloc
  				  AND j04_codigo_caja 
  				  	= r_j90.j90_codigo_caja
  				  AND j04_fecha_aper  = vg_fecha)
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
	WHENEVER ERROR CONTINUE
	DECLARE qu_lopr_a CURSOR FOR SELECT * FROM rept023
		WHERE r23_compania  = rm_j10.j10_compania AND 
		      r23_localidad = rm_j10.j10_localidad AND 
		      r23_numprev   = rm_j10.j10_num_fuente
		FOR UPDATE
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
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_z02		RECORD LIKE cxct002.*
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
	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(j10_tipo_fuente, j10_num_fuente,
							 rm_r38.r38_num_sri)
		THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
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
			CALL fl_mostrar_mensaje('No se pueden cancelar pre-ventas en esta caja.','exclamation')
			NEXT FIELD j10_tipo_fuente
		END IF
		IF rm_j10.j10_tipo_fuente = 'OT' AND rm_j02.j02_ordenes = 'N'
		THEN
			CALL fl_mostrar_mensaje('No se pueden cancelar ordenes de trabajo en esta caja.','exclamation')
			NEXT FIELD j10_tipo_fuente
		END IF
		IF rm_j10.j10_tipo_fuente = 'SC' AND rm_j02.j02_solicitudes = 'N'
		THEN
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
			CALL fl_mostrar_mensaje('Registro de caja no esta activo.','exclamation')
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
				CALL fl_lee_cliente_localidad(vg_codcia,
						vg_codloc, r_j10.j10_codcli)
					RETURNING r_z02.*
{JCM
				IF r_z02.z02_email IS NULL THEN	
					CALL fl_mostrar_mensaje('Cliente no tiene registrado el correo electrónico para esta localidad.','exclamation')
					NEXT FIELD j10_num_fuente
				ELSE
					CALL fl_mostrar_mensaje('Cliente tiene registrado este correo electrónico para esta localidad: ' || r_z02.z02_email CLIPPED || '.', 'info')
				END IF
}
				CALL fl_lee_preventa_rep(vg_codcia, vg_codloc,
					r_j10.j10_num_fuente) RETURNING r_r23.*
				IF r_r23.r23_numprev IS NULL THEN
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
				CALL fl_lee_cliente_general(r_r23.r23_codcli)
					RETURNING r_z01.*
				IF r_z01.z01_paga_impto = 'S' AND
				   r_r23.r23_porc_impto = 0
				THEN
					CALL fl_mostrar_mensaje('No puede factura esta preventa, porque no tiene IVA y el cliente esta configurado para calcular pago de impuestos.', 'exclamation')
					CONTINUE INPUT
				END IF
				IF NOT facturar_sin_stock() THEN
					NEXT FIELD j10_num_fuente
				END IF
			WHEN 'PV'
				CALL fl_lee_preventa_veh(vg_codcia, vg_codloc,
					r_j10.j10_num_fuente) RETURNING r_v26.*
				IF r_v26.v26_numprev IS NULL THEN
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
				CALL fl_lee_cliente_localidad(vg_codcia,
						vg_codloc, r_j10.j10_codcli)
					RETURNING r_z02.*
{JCM
				IF r_z02.z02_email IS NULL THEN	
					CALL fl_mostrar_mensaje('Cliente no tiene registrado el correo electrónico para esta localidad.','exclamation')
					NEXT FIELD j10_num_fuente
				ELSE
					CALL fl_mostrar_mensaje('Cliente tiene registrado este correo electrónico para esta localidad: ' || r_z02.z02_email CLIPPED || '.', 'info')
				END IF
}
				CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc,
					r_j10.j10_num_fuente) RETURNING r_t23.*
				IF r_t23.t23_orden IS NULL THEN
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
				CALL fl_lee_cliente_general(r_t23.t23_cod_cliente)
					RETURNING r_z01.*
				IF r_z01.z01_paga_impto = 'S' AND
				   r_t23.t23_porc_impto = 0
				THEN
					CALL fl_mostrar_mensaje('No puede factura esta orden de trabajo, porque no tiene IVA y el cliente esta configurado para calcular pago de impuestos.', 'exclamation')
					CONTINUE INPUT
				END IF
			WHEN 'SC'
				CALL fl_lee_solicitud_cobro_cxc(
					vg_codcia, vg_codloc, 
					r_j10.j10_num_fuente) 
					RETURNING r_z24.*
				IF r_z24.z24_numero_sol IS NULL THEN
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
		IF NOT tiene_configuracion_contable_impto() THEN
			CONTINUE INPUT
		END IF
		IF rm_j10.j10_tipo_fuente = 'PR' THEN
			{--
			IF NOT valido_preventas_con_ot() THEN
				CONTINUE INPUT
			END IF
			--}
		END IF
END INPUT

END FUNCTION



FUNCTION tiene_configuracion_contable_impto()
DEFINE r_b40		RECORD LIKE ctbt040.*
DEFINE r_b43		RECORD LIKE ctbt043.*
DEFINE r_r23		RECORD LIKE rept023.*
DEFINE r_t01		RECORD LIKE talt001.*
DEFINE r_t04		RECORD LIKE talt004.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE bodega		LIKE rept024.r24_bodega
DEFINE resul		SMALLINT
DEFINE mensaje		VARCHAR(150)

LET resul = 1
IF vg_codloc <> 1 AND vg_codloc <> 3 THEN
	RETURN resul
END IF
CASE rm_j10.j10_tipo_fuente
	WHEN 'PR'
		CALL fl_lee_preventa_rep(vg_codcia, vg_codloc,
						rm_j10.j10_num_fuente)
			RETURNING r_r23.*
		DECLARE q_r24 CURSOR FOR
			SELECT UNIQUE r24_bodega
				FROM rept024
				WHERE r24_compania  = r_r23.r23_compania
				  AND r24_localidad = r_r23.r23_localidad
				  AND r24_numprev   = r_r23.r23_numprev
		FOREACH q_r24 INTO bodega
			INITIALIZE r_b40.* TO NULL
			SELECT * INTO r_b40.*
				FROM ctbt040
				WHERE b40_compania    = r_r23.r23_compania
				  AND b40_localidad   = r_r23.r23_localidad
				  AND b40_modulo      = 'RE'
				  AND b40_bodega      = bodega
				  AND b40_grupo_linea = r_r23.r23_grupo_linea
				  AND b40_porc_impto  = r_r23.r23_porc_impto
			IF r_b40.b40_compania IS NULL THEN
				LET mensaje = 'No existe configuracion ',
						'contable en la bodega ',
						bodega CLIPPED, ' para el ',
						'IMPUESTO ',
						r_r23.r23_porc_impto
						USING "##&.##", '%. LLAME AL ',
						'ADMINISTRADOR.'
				CALL fl_mostrar_mensaje(mensaje, 'stop')
				LET resul = 0
				EXIT FOREACH
			END IF
		END FOREACH
	WHEN 'OT'
		CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc,
						rm_j10.j10_num_fuente)
			RETURNING r_t23.*
		CALL fl_lee_tipo_vehiculo(r_t23.t23_compania, r_t23.t23_modelo)
			RETURNING r_t04.*
		CALL fl_lee_linea_taller(r_t23.t23_compania, r_t04.t04_linea)
			RETURNING r_t01.*
		INITIALIZE r_b43.* TO NULL
		SELECT * INTO r_b43.*
			FROM ctbt043
			WHERE b43_compania    = r_t23.t23_compania
			  AND b43_localidad   = r_t23.t23_localidad
			  AND b43_grupo_linea = r_t01.t01_grupo_linea
			  AND b43_porc_impto  = r_t23.t23_porc_impto
		IF r_b43.b43_compania IS NULL THEN
			LET mensaje = 'No existe configuracion contable para ',
					'el IMPUESTO ', r_t23.t23_porc_impto
					USING "##&.##", '%. LLAME AL ',
					'ADMINISTRADOR.'
			CALL fl_mostrar_mensaje(mensaje, 'stop')
			LET resul = 0
		END IF
END CASE
RETURN resul

END FUNCTION



FUNCTION valido_preventas_con_ot()
DEFINE num_ot		LIKE talt023.t23_orden
DEFINE ctas		INTEGER
DEFINE resul		SMALLINT
DEFINE mensaje		VARCHAR(200)

LET resul = 1
IF prevent_ot_estado('A') IS NOT NULL THEN
	CALL fl_mostrar_mensaje('No puede facturar una Pre-Venta que esta asociada a una Orden de Trabajo que esta ACTIVA.', 'exclamation')
	LET resul = 0
END IF
IF prevent_ot_estado('E') IS NOT NULL AND resul = 1 THEN
	CALL fl_mostrar_mensaje('No puede facturar una Pre-Venta que esta asociada a una Orden de Trabajo que ha sido ELIMINADA.', 'exclamation')
	LET resul = 0
END IF
IF resul = 1 THEN
	SELECT t23_compania, t23_localidad, t23_orden,
		(SELECT COUNT(*)
			FROM rept023
			WHERE r23_compania   = t23_compania
			  AND r23_localidad  = t23_localidad
			  AND r23_numprev   <> rm_j10.j10_num_fuente
			  AND r23_num_ot     = t23_orden
			  AND r23_estado    <> 'F') cuantas
		FROM talt023
		WHERE t23_compania          = vg_codcia
		  AND t23_estado            = 'C'
		  AND DATE(t23_fec_cierre) >= vg_fecha
	UNION
	SELECT t23_compania, t23_localidad, t23_orden,
		(SELECT COUNT(*)
			FROM rept023
			WHERE r23_compania   = t23_compania
			  AND r23_localidad  = t23_localidad
			  AND r23_numprev   <> rm_j10.j10_num_fuente
			  AND r23_num_ot     = t23_orden
			  AND r23_estado    <> 'F') cuantas
		FROM talt023
		WHERE t23_compania          = vg_codcia
		  AND t23_estado            = 'A'
	INTO TEMP t1
	SELECT t23_orden,
		(SELECT COUNT(*)
			FROM rept023
			WHERE r23_compania   = t23_compania
			  AND r23_localidad  = t23_localidad
			  AND r23_numprev   <> rm_j10.j10_num_fuente
			  AND r23_num_ot     = t23_orden
			  AND r23_estado     = 'F') cuantas
		FROM t1
		INTO TEMP t2
	DROP TABLE t1
	DECLARE q_ord_act CURSOR FOR SELECT * FROM t2 WHERE cuantas <> 0
	FOREACH q_ord_act INTO num_ot, ctas
		LET mensaje = 'La Orden de Trabajo ', num_ot USING "<<<<<&",
				' ya tiene una o varias Pre-Ventas facturadas.',
				' Por favor facture primero esta Orden de',
				' Trabajo.'
		CALL fl_mostrar_mensaje(mensaje, 'exclamation')
		LET resul = 0
		EXIT FOREACH
	END FOREACH
	DROP TABLE t2
END IF
RETURN resul

END FUNCTION



FUNCTION prevent_ot_estado(estado)
DEFINE estado		LIKE talt023.t23_estado
DEFINE num_ot		LIKE talt023.t23_orden

LET num_ot = NULL
IF rm_j10.j10_tipo_fuente <> 'PR' THEN
	RETURN num_ot
END IF
SELECT r23_num_ot
	INTO num_ot
	FROM rept023, talt023
	WHERE r23_compania  = vg_codcia
	  AND r23_localidad = vg_codloc
	  AND r23_numprev   = rm_j10.j10_num_fuente
	  AND t23_compania  = r23_compania
	  AND t23_localidad = r23_localidad
	  AND t23_orden     = r23_num_ot
	  AND t23_estado    = estado
RETURN num_ot

END FUNCTION



FUNCTION control_crear_cliente()
DEFINE command_run	VARCHAR(100)
DEFINE run_prog		CHAR(10)

IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia, 'CO', 'cxcp101')
THEN
	RETURN
END IF
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
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
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE cont		INTEGER
DEFINE flag		SMALLINT

-- OJO PUESTO PARA LA NOTA DE VENTA
{--
IF vg_codloc = 3 THEN
	CALL fl_lee_cliente_general(rm_j10.j10_codcli) RETURNING r_z01.*
	IF r_z01.z01_tipo_doc_id <> 'R' THEN
		LET vm_tipo_doc = 'NV'
	END IF
END IF
--}
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
	LET cod_tran = vm_tipo_doc
	IF vm_tipo_doc = 'NV' THEN
		LET cod_tran = 'FA'
	END IF
	SELECT COUNT(*) INTO cont FROM rept038
		WHERE r38_compania    = vg_codcia
		  AND r38_localidad   = vg_codloc
		  AND r38_tipo_doc    = vm_tipo_doc
  		  AND r38_tipo_fuente = rm_j10.j10_tipo_fuente
  		  AND r38_cod_tran    = cod_tran
  		  AND r38_num_sri     = rm_r38.r38_num_sri
	IF cont > 0 THEN
		CALL fl_mostrar_mensaje('La secuencia del SRI ' || rm_r38.r38_num_sri[9,17] || ' ya existe.','exclamation')
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
SELECT COUNT(*) INTO cont
	FROM gent037
	WHERE g37_compania   = vg_codcia
	  AND g37_localidad  = vg_codloc
	  AND g37_tipo_doc   = vm_tipo_doc
	{--
  	  AND g37_fecha_emi <= DATE(TODAY)
  	  AND g37_fecha_exp >= DATE(TODAY)
	--}
	  AND g37_secuencia IN
		(SELECT MAX(g37_secuencia)
			FROM gent037
			WHERE g37_compania  = vg_codcia
			  AND g37_localidad = vg_codloc
			  AND g37_tipo_doc  = vm_tipo_doc)
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
DEFINE fecha_cob	LIKE cxct026.z26_fecha_cobro
DEFINE i, j, salir	SMALLINT
DEFINE resul, k		SMALLINT
DEFINE resp			CHAR(6)
DEFINE cont_cred	LIKE cajt001.j01_cont_cred
DEFINE total		LIKE cajt011.j11_valor
DEFINE vuelto, val, dif	LIKE cajt011.j11_valor
DEFINE valor_ef, val_r	LIKE cajt011.j11_valor
DEFINE val_aux		LIKE cajt011.j11_valor
DEFINE bco_tarj		SMALLINT
DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_g09		RECORD LIKE gent009.*
DEFINE r_g10		RECORD LIKE gent010.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_j01		RECORD LIKE cajt001.*
DEFINE r_j11		RECORD LIKE cajt011.*
DEFINE r_z02		RECORD LIKE cxct002.*
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE tiene_tj		SMALLINT
DEFINE tiene_rt		SMALLINT

OPTIONS
	INSERT KEY F30

LET cont_cred = 'R'
IF rm_j10.j10_tipo_fuente = 'PR' OR rm_j10.j10_tipo_fuente = 'OT' THEN
	LET cont_cred = 'C'
END IF
IF rm_j10.j10_tipo_fuente = 'SC' THEN
	INITIALIZE r_j11.* TO NULL
	DECLARE q_j11_cp CURSOR FOR
		SELECT * FROM cajt011
			WHERE j11_compania    = vg_codcia
			  AND j11_localidad   = vg_codloc
			  AND j11_tipo_fuente = rm_j10.j10_tipo_fuente
			  AND j11_num_fuente  = rm_j10.j10_num_fuente
			ORDER BY j11_secuencia
	LET k = 1
	FOREACH q_j11_cp INTO r_j11.*
		LET rm_j11[k].forma_pago   = r_j11.j11_codigo_pago
		LET rm_j11[k].moneda       = r_j11.j11_moneda
		LET rm_j11[k].cod_bco_tarj = r_j11.j11_cod_bco_tarj
		LET rm_j11[k].num_ch_aut   = r_j11.j11_num_ch_aut
		LET rm_j11[k].num_cta_tarj = r_j11.j11_num_cta_tarj
		LET rm_j11[k].valor        = r_j11.j11_valor 
		LET k                      = k + 1
	END FOREACH
END IF
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
			CALL fl_ayuda_forma_pago(vg_codcia, cont_cred, 'A', 'T')
				RETURNING r_j01.j01_codigo_pago,
					  r_j01.j01_nombre,
					  r_j01.j01_cont_cred
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
							valor_ch, fecha_cob
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
			IF rm_j11[i].forma_pago = 'DP' OR
			   rm_j11[i].forma_pago = 'DB'
			THEN
				CALL fl_ayuda_cuenta_banco(vg_codcia, 'A') 
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
				IF rm_j11[i].forma_pago <> 'CP' --OR
				   --rm_j10.j10_tipo_fuente <> 'SC'
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
		IF fl_determinar_si_es_retencion(vg_codcia,rm_j11[i].forma_pago,
						cont_cred)
		THEN
			CALL detalle_retenciones(i, j, 'I')
			IF rm_j10.j10_tipo_fuente = 'SC' THEN
				EXIT INPUT
			END IF
			LET int_flag = 0
		END IF
	ON KEY(F7)
		IF INFIELD(j11_valor) AND
		   NOT fl_determinar_si_es_retencion(vg_codcia,
						rm_j11[i].forma_pago, cont_cred)
		THEN
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
				LET vuelto = total - rm_j10.j10_valor
				IF vuelto < 0 THEN 
					LET vuelto = 0
				END IF
				DISPLAY BY NAME vuelto
			END IF
		END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel('INSERT', '')
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
		CALL calcula_total(arr_count()) RETURNING total
	BEFORE ROW
		--#IF NOT INFIELD(j11_valor) OR
		   --#fl_determinar_si_es_retencion(vg_codcia,
					--#rm_j11[i].forma_pago, cont_cred)
		--#THEN
			--#CALL dialog.keysetlabel('F7', '')
		--#END IF
		LET i = arr_curr()
		LET j = scr_line()
		--#IF fl_determinar_si_es_retencion(vg_codcia,
					--#rm_j11[i].forma_pago, cont_cred)
		--#THEN
			--#IF rm_j10.j10_tipo_fuente = 'PR' OR
			   --#rm_j10.j10_tipo_fuente = 'OT' THEN
				--#CALL dialog.keysetlabel("F6","Retenciones")
			--#ELSE
				--#IF rm_j10.j10_tipo_fuente = 'SC' THEN
					--#CALL dialog.keysetlabel("F6","Facturas")
				--#ELSE
					--#CALL dialog.keysetlabel("F6","")
				--#END IF
			--#END IF
		--#ELSE
			--#CALL dialog.keysetlabel("F6","")
		--#END IF
	BEFORE DELETE
		LET i = arr_curr()
		IF fl_determinar_si_es_retencion(vg_codcia,rm_j11[i].forma_pago,
						cont_cred)
		THEN
			CALL borrar_retencion(rm_j11[i].num_ch_aut,
						rm_j11[i].forma_pago, 0)
		END IF
	BEFORE FIELD j11_valor
		--#CALL dialog.keysetlabel('F7', 'Diferencia')
		--#IF fl_determinar_si_es_retencion(vg_codcia,
					--#rm_j11[i].forma_pago, cont_cred)
		--#THEN
			--#CALL dialog.keysetlabel('F7', '')
		--#END IF
		IF fl_determinar_si_es_retencion(vg_codcia,rm_j11[i].forma_pago,
						cont_cred)
		THEN
			IF rm_j11[i].valor IS NOT NULL OR
			   rm_j11[i].valor > 0 THEN
				LET val_aux = rm_j11[i].valor
			END IF
		END IF
	AFTER FIELD j11_codigo_pago
		IF rm_j11[i].forma_pago IS NULL THEN
			IF fgl_lastkey() <> fgl_keyval('up') THEN
				NEXT FIELD j11_codigo_pago
			ELSE
				CONTINUE INPUT
			END IF
		END IF 
		CALL fl_lee_tipo_pago_caja(vg_codcia, rm_j11[i].forma_pago,
						cont_cred)
			RETURNING r_j01.*		
		IF r_j01.j01_codigo_pago IS NULL THEN
			CALL fl_mostrar_mensaje('Forma de Pago no existe.','exclamation')
			NEXT FIELD j11_codigo_pago
		END IF
		IF r_j01.j01_estado = 'B' THEN
			CALL fl_mostrar_mensaje('Forma de Pago esta BLOQUEADA.','exclamation')
			NEXT FIELD j11_codigo_pago
		END IF
		LET rm_j11[i].moneda = rm_j10.j10_moneda
		DISPLAY rm_j11[i].moneda TO ra_j11[j].j11_moneda
		--#IF fl_determinar_si_es_retencion(vg_codcia,
					--#rm_j11[i].forma_pago, cont_cred)
		--#THEN
			--#IF rm_j10.j10_tipo_fuente = 'PR' OR
			   --#rm_j10.j10_tipo_fuente = 'OT' THEN
				--#CALL dialog.keysetlabel("F6","Retenciones")
			--#ELSE
				--#IF rm_j10.j10_tipo_fuente = 'SC' THEN
					--#CALL dialog.keysetlabel("F6","Facturas")
				--#ELSE
					--#CALL dialog.keysetlabel("F6","")
				--#END IF
			--#END IF
		--#ELSE
			--#CALL dialog.keysetlabel("F6","")
		--#END IF
		IF FIELD_TOUCHED(j11_codigo_pago) AND
		   fl_determinar_si_es_retencion(vg_codcia,rm_j11[i].forma_pago,
						cont_cred)
		THEN
			IF cont_cred = 'R' THEN
				--CALL fl_mostrar_mensaje('LAS RETENCIONES DE CLIENTES SOLO SE PUEDEN INGRESAR POR DIGITACION DE RETENCIONES.', 'info')
				--NEXT FIELD j11_codigo_pago
			END IF
			CALL detalle_retenciones(i, j, 'I')
			IF rm_j10.j10_tipo_fuente = 'SC' THEN
				EXIT INPUT
			END IF
		END IF
		IF rm_j11[i].forma_pago = vm_efectivo THEN
			NEXT FIELD j11_valor
		END IF
		IF rm_j11[i].forma_pago[1, 1] = 'T' AND
		   rm_j11[i].forma_pago <> 'TJ'
		THEN
			DECLARE q_tj CURSOR FOR
				SELECT g10_tarjeta
					FROM gent010
					WHERE g10_compania  = vg_codcia
					  AND g10_cod_tarj  =
							rm_j11[i].forma_pago
					  AND g10_cont_cred = cont_cred
					ORDER BY g10_tarjeta
			OPEN q_tj
			FETCH q_tj INTO rm_j11[i].cod_bco_tarj
			CLOSE q_tj
			FREE q_tj
			DISPLAY rm_j11[i].cod_bco_tarj TO
				ra_j11[j].j11_cod_bco_tarj
			NEXT FIELD j11_num_ch_aut
		ELSE
			NEXT FIELD j11_cod_bco_tarj
		END IF
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
	AFTER FIELD j11_cod_bco_tarj
		IF rm_j11[i].cod_bco_tarj IS NULL THEN
			CONTINUE INPUT
		END IF
		LET bco_tarj = banco_tarjeta(rm_j11[i].forma_pago)
		IF (bco_tarj IS NULL OR bco_tarj = 3) AND
		  (rm_j11[i].forma_pago <> 'RE' AND
		   rm_j11[i].forma_pago <> 'CT')
		THEN
			INITIALIZE rm_j11[i].cod_bco_tarj TO NULL
			CLEAR ra_j11[j].j11_cod_bco_tarj
		END IF
		IF bco_tarj = 1 AND
		  (rm_j11[i].forma_pago <> 'RE' AND
		   rm_j11[i].forma_pago <> 'CT')
		THEN
			CALL fl_lee_banco_general(rm_j11[i].cod_bco_tarj)
				RETURNING r_g08.* 
			IF r_g08.g08_banco IS NULL THEN
				CALL fl_mostrar_mensaje('Banco no existe.','exclamation')
				NEXT FIELD j11_cod_bco_tarj
			END IF
		END IF
		IF bco_tarj = 2 THEN
			CALL fl_lee_tarjeta_credito(vg_codcia,
							rm_j11[i].cod_bco_tarj,
							rm_j11[i].forma_pago,
							cont_cred)
				RETURNING r_g10.* 
			IF r_g10.g10_estado = 'B' THEN
				CALL fl_mostrar_mensaje('Tarjeta de Crédito esta BLOQUEADA.', 'exclamation')
				NEXT FIELD j11_cod_bco_tarj
			END IF
			IF r_g10.g10_tarjeta IS NULL THEN
				CALL fl_mostrar_mensaje('Tarjeta de Crédito no existe o no esta asociada a esta forma de pago.', 'exclamation')
				NEXT FIELD j11_cod_bco_tarj
			END IF
			IF vg_codloc = 2 OR vg_codloc = 4 THEN
				CONTINUE INPUT
			END IF
			CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc,
							r_g10.g10_codcobr)
				RETURNING r_z02.*
			CALL fl_lee_cuenta(vg_codcia, r_z02.z02_aux_clte_mb)
				RETURNING r_b10.*
			IF r_b10.b10_estado = 'B' THEN
				CALL fl_mostrar_mensaje('La cuenta contable de esta Tarjeta de Credito esta BLOQUEADA.', 'exclamation')
				NEXT FIELD j11_cod_bco_tarj
			END IF
		END IF
	AFTER FIELD j11_num_ch_aut
		LET bco_tarj = banco_tarjeta(rm_j11[i].forma_pago)
		IF bco_tarj IS NULL THEN
			INITIALIZE rm_j11[i].num_ch_aut TO NULL
			CLEAR ra_j11[j].j11_num_ch_aut
		END IF
		IF fl_determinar_si_es_retencion(vg_codcia,rm_j11[i].forma_pago,
						cont_cred)
		THEN
			IF NOT valido_num_ret(rm_j11[i].num_ch_aut) THEN
				NEXT FIELD j11_num_ch_aut
			END IF
		END IF
	AFTER FIELD j11_num_cta_tarj
		LET bco_tarj = banco_tarjeta(rm_j11[i].forma_pago)
		IF bco_tarj IS NULL OR bco_tarj = 3 THEN
			INITIALIZE rm_j11[i].num_cta_tarj TO NULL
			CLEAR ra_j11[j].j11_num_cta_tarj
		END IF
		IF rm_j11[i].forma_pago = 'DP' OR rm_j11[i].forma_pago = 'DB'
		THEN
			IF  rm_j11[i].num_cta_tarj IS NULL THEN
				CALL fl_mostrar_mensaje('Digite cuenta de compañía.','exclamation')
				NEXT FIELD j11_num_cta_tarj
			END IF
			CALL fl_lee_banco_compania(vg_codcia, rm_j11[i].cod_bco_tarj,
				rm_j11[i].num_cta_tarj) RETURNING r_g09.*
			IF r_g09.g09_numero_cta IS NULL THEN
				CALL fl_mostrar_mensaje('No existe cuenta en este banco.','exclamation')
				NEXT FIELD j11_num_cta_tarj
			END IF
		END IF
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
		IF fl_determinar_si_es_retencion(vg_codcia,rm_j11[i].forma_pago,
						cont_cred)
		THEN
			IF val_aux IS NOT NULL OR val_aux > 0 THEN
				LET rm_j11[i].valor = val_aux
				DISPLAY rm_j11[i].valor TO ra_j11[j].j11_valor
			END IF
		END IF
	AFTER DELETE
		LET vm_indice = arr_count()
		CALL calcula_total(vm_indice) RETURNING total
		EXIT INPUT
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
	AFTER INPUT
		LET tiene_tj = 0
		LET tiene_rt = 0
		LET vm_indice = arr_count()
		FOR i = 1 TO vm_indice 
			IF (banco_tarjeta(rm_j11[i].forma_pago) = 1 OR
			    banco_tarjeta(rm_j11[i].forma_pago) = 2) AND
			   (rm_j11[i].forma_pago <> 'RE' AND
			    rm_j11[i].forma_pago <> 'CT')
			THEN
				IF rm_j11[i].cod_bco_tarj IS NULL THEN
					CALL fl_mostrar_mensaje('Debe ingresar el código del banco o de la tarjeta.','exclamation')
					NEXT FIELD j11_cod_bco_tarj
				END IF
				IF rm_j11[i].num_cta_tarj IS NULL THEN
					CALL fl_mostrar_mensaje('Debe ingresar el número de la cuenta o de la tarjeta.','exclamation')
					NEXT FIELD j11_num_cta_tarj
				END IF
			END IF
			IF rm_j11[i].forma_pago = vm_cheque
			OR rm_j11[i].forma_pago[1, 1] = 'T'
			OR fl_determinar_si_es_retencion(vg_codcia,
						rm_j11[i].forma_pago, cont_cred)
			THEN
				IF rm_j11[i].num_ch_aut IS NULL THEN
					CALL fl_mostrar_mensaje('Debe ingresar el número del cheque/retención/aut. tarjeta.','exclamation')
					NEXT FIELD j11_num_ch_aut
				END IF
			END IF
			IF ((rm_j11[i].forma_pago[1, 1]  = 'T') AND
			   ((rm_j11[i].forma_pago       <> 'TJ' AND
			     rm_j10.j10_tipo_fuente     <> 'SC') OR
			    (rm_j10.j10_tipo_fuente      = 'SC')))
			THEN
				CALL fl_lee_tipo_pago_caja(vg_codcia,
						rm_j11[i].forma_pago, cont_cred)
					RETURNING r_j01.*		
				IF r_j01.j01_aux_cont IS NULL THEN
					CALL fl_mostrar_mensaje('Forma de Pago no tiene configurado auxiliar contable.','exclamation')
					NEXT FIELD j11_codigo_pago
				END IF
				IF rm_j11[i].cod_bco_tarj IS NULL THEN
					CALL fl_mostrar_mensaje('Debe ingresar el código del banco o de la tarjeta.','exclamation')
					NEXT FIELD j11_cod_bco_tarj
				END IF
				IF rm_j11[i].num_cta_tarj IS NULL THEN
					CALL fl_mostrar_mensaje('Debe ingresar el número de la cuenta o de la tarjeta.','exclamation')
					NEXT FIELD j11_num_cta_tarj
				END IF
			END IF
			IF rm_j11[i].forma_pago = vm_cheque OR
			   rm_j11[i].forma_pago[1, 1]  = 'T'
			--OR fl_determinar_si_es_retencion(vg_codcia,
			--			rm_j11[i].forma_pago, cont_cred)
			THEN
				IF repetidos_num_ch_aut(i) THEN
					CALL fl_mostrar_mensaje('No puede repetir un mismo número de tarjeta, cheque o autorización.', 'exclamation')
					NEXT FIELD j11_num_ch_aut
				END IF
			END IF
			IF fl_determinar_si_es_retencion(vg_codcia,
						rm_j11[i].forma_pago, cont_cred)
			THEN
				IF registros_retenciones(rm_j11[i].num_ch_aut,
						rm_j11[i].forma_pago, 0) = 0
				THEN
					CALL fl_mostrar_mensaje('Debe digitar el detalle de la retencion.', 'info')
					CALL detalle_retenciones(i, j, 'I')
					CONTINUE INPUT
				END IF
				IF rm_j11[i].valor <> 0 THEN
					SELECT NVL(SUM(valor_ret), 0.00)
						INTO val_r
						FROM tmp_ret
						WHERE cod_pago    =
							rm_j11[i].forma_pago
						  AND num_ret_sri =
							rm_j11[i].num_ch_aut
					IF val_r <> rm_j11[i].valor THEN
						CALL fl_mostrar_mensaje('El valor de esta retencion es diferente al valor digitado en el detalle de retenciones.', 'exclamation')
						CONTINUE INPUT
					END IF
				END IF
				LET tiene_rt = 1
			END IF
			IF rm_j11[i].forma_pago[1, 1]  = 'T' THEN
				LET tiene_tj = 1
			END IF
		END FOR
		LET total = calcula_total(vm_indice)
		IF total <> rm_j10.j10_valor THEN
			IF rm_j10.j10_tipo_fuente = 'SC' THEN
				CALL fl_mostrar_mensaje('El total del detalle de la forma de pago debe ser igual al valor a recaudar.','exclamation')
				CONTINUE INPUT
			END IF
			IF total > rm_j10.j10_valor THEN
				LET valor_ef = valor_efectivo(vm_indice)
				LET vuelto = total - rm_j10.j10_valor
				IF valor_ef >= vuelto THEN 
					DISPLAY BY NAME vuelto
				ELSE
					CALL fl_mostrar_mensaje('El total en efectivo no es suficiente para el vuelto.','exclamation')
					CONTINUE INPUT
				END IF
			ELSE
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
		IF tiene_tj AND tiene_rt THEN
			CALL fl_mostrar_mensaje('Cuando el pago de una factura se hace con tarjeta de credito, no se puede digitar una retencion al cliente.', 'info')
			CONTINUE INPUT
		END IF
		LET salir = 1
END INPUT
IF int_flag THEN
	EXIT WHILE
END IF

END WHILE

END FUNCTION



FUNCTION banco_tarjeta(forma_pago)
DEFINE forma_pago	LIKE cajt011.j11_codigo_pago
DEFINE cont_cred	LIKE cajt001.j01_cont_cred
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
	WHEN 'DB' LET ret_val = 1 
	WHEN 'CD' LET ret_val = 1 
	WHEN 'DA' LET ret_val = 1 
	WHEN 'CT' LET ret_val = 1 
	WHEN 'RE' LET ret_val = 1 
	
	WHEN 'TJ' LET ret_val = 2
	
	OTHERWISE  
		-- Estas formas de pago no necesitan informacion del
		-- banco o tarjeta de crédito:
		-- 'EF', 'OC', 'OT', 'RT'
		INITIALIZE ret_val TO NULL
END CASE 

IF forma_pago[1, 1] = 'T' THEN
	LET ret_val = 2
END IF
LET cont_cred = 'R'
IF rm_j10.j10_tipo_fuente = 'PR' OR rm_j10.j10_tipo_fuente = 'OT' THEN
	LET cont_cred = 'C'
END IF
IF fl_determinar_si_es_retencion(vg_codcia, forma_pago, cont_cred) THEN
	LET ret_val = 3
END IF

RETURN ret_val

END FUNCTION



FUNCTION ayudas_bco_tarj(forma_pago)
DEFINE forma_pago	LIKE cajt011.j11_codigo_pago
DEFINE cod_bco_tarj	LIKE cajt011.j11_cod_bco_tarj
DEFINE cont_cred	LIKE cajt001.j01_cont_cred
DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_g10		RECORD LIKE gent010.*

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
	LET cont_cred = 'C'
	IF rm_j10.j10_tipo_fuente = 'SC' THEN
		LET cont_cred = 'R'
	END IF
	CALL fl_ayuda_tarjeta(vg_codcia, cont_cred, 'A')
		RETURNING r_g10.g10_tarjeta, r_g10.g10_nombre
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
			CALL fl_mostrar_mensaje('No existe paridad de cambio para esta moneda.','stop')
			EXIT PROGRAM
		END IF
		LET total = total + (rm_j11[i].valor * paridad)
	END IF
END FOR 

IF num_args() <> 7 THEN
	DISPLAY total TO total_mf
END IF

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
	CALL fl_lee_factor_moneda(moneda_ori, moneda_dest) RETURNING r_g14.*
	IF r_g14.g14_serial IS NULL THEN
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
DEFINE prog		CHAR(10)

IF rm_j10.j10_num_fuente IS NULL THEN
	CALL fl_mostrar_mensaje('Debe especificar un documento primero.','exclamation')
	RETURN
END IF
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF

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
		LET prog = 'cxcp204 '
		IF rm_j10.j10_tipo_destino = 'PA' OR
		   rm_j10.j10_tipo_destino = 'PR'
		THEN
			LET prog = 'cxcp205 '
		END IF
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
 			      'COBRANZAS', vg_separador, 'fuentes', 
			      vg_separador, run_prog, prog, vg_base, ' ',
			      'CO', vg_codcia, ' ', vg_codloc,
			      ' ', rm_j10.j10_num_fuente 
		IF rm_j10.j10_tipo_destino = 'PA' OR
		   rm_j10.j10_tipo_destino = 'PR'
		THEN
			LET comando = comando CLIPPED, ' ',
					rm_j10.j10_tipo_destino
		END IF
END CASE

RUN comando

END FUNCTION



FUNCTION detalle_retenciones(i, j, tipo_llamada)
DEFINE i, j		SMALLINT
DEFINE tipo_llamada	CHAR(1)
DEFINE l, k, entro	SMALLINT
DEFINE cont_cred	LIKE cajt014.j14_cont_cred

LET cont_cred = 'R'
IF rm_j10.j10_tipo_fuente = 'PR' OR rm_j10.j10_tipo_fuente = 'OT' THEN
	LET cont_cred = 'C'
END IF
IF fl_determinar_si_es_retencion(vg_codcia, rm_j11[i].forma_pago, cont_cred)
THEN
	IF NOT tiene_aux_cont_retencion(rm_j11[i].forma_pago, cont_cred, 1) AND
	   tipo_llamada = 'I'
	THEN
		RETURN
	END IF
	IF rm_j10.j10_tipo_fuente = 'SC' THEN
		CALL control_retenciones_credito(rm_j11[i].forma_pago,
						tipo_llamada)
			RETURNING entro
		IF tipo_llamada = 'I' AND entro THEN
			DECLARE q_ret4 CURSOR FOR
				SELECT num_ret_sri, NVL(SUM(valor_ret), 0.00)
					FROM tmp_ret
					WHERE cod_pago = rm_j11[i].forma_pago
					GROUP BY 1
					ORDER BY 1
			LET l = i
			FOR k = 1 TO vm_indice
				IF fl_determinar_si_es_retencion(vg_codcia,
						rm_j11[k].forma_pago, cont_cred)
				THEN
					LET l = k
					EXIT FOR
				END IF
			END FOR
			OPEN q_ret4
			WHILE TRUE
				IF rm_j11[l].forma_pago IS NOT NULL THEN
					IF NOT fl_determinar_si_es_retencion(
						vg_codcia, rm_j11[l].forma_pago,
						cont_cred)
					THEN
						LET l = l + 1
						CONTINUE WHILE
					END IF
				END IF
				FETCH q_ret4 INTO rm_j11[l].num_ch_aut,
							rm_j11[l].valor
				IF STATUS = NOTFOUND THEN
					EXIT WHILE
				END IF
				LET rm_j11[l].forma_pago   =rm_j11[i].forma_pago
				LET rm_j11[l].moneda       = rm_j10.j10_moneda
				LET rm_j11[l].cod_bco_tarj = NULL
				LET rm_j11[l].num_cta_tarj = NULL
				LET l = l + 1
			END WHILE
			LET l = l - 1
			IF (l >= i AND l < vm_indice) AND
			   (i > 1 OR vm_indice = 1)
			THEN
				LET vm_indice = vm_indice + l - 1
			ELSE
				IF l > vm_indice THEN
					LET vm_indice = l
				END IF
			END IF
		END IF
	END IF
	IF rm_j10.j10_tipo_fuente = 'PR' OR rm_j10.j10_tipo_fuente = 'OT' THEN
		CALL control_retenciones(rm_j11[i].num_ch_aut,
					rm_j11[i].forma_pago, tipo_llamada, 0)
			RETURNING rm_j11[i].num_ch_aut, rm_j11[i].valor, entro
		IF tipo_llamada = 'I' THEN
			DISPLAY rm_j11[i].num_ch_aut TO ra_j11[j].j11_num_ch_aut
			DISPLAY rm_j11[i].valor      TO ra_j11[j].j11_valor
		END IF
	END IF
END IF

END FUNCTION



FUNCTION control_retenciones_credito(codigo_pago, tipo_llamada)
DEFINE codigo_pago	LIKE cajt001.j01_codigo_pago
DEFINE tipo_llamada	CHAR(1)
DEFINE row_ini, col_ini	SMALLINT
DEFINE row_fin, col_fin	SMALLINT
DEFINE i, j, col	SMALLINT
DEFINE cambio, entro	SMALLINT
DEFINE numero_ret	LIKE cajt011.j11_num_ch_aut
DEFINE num_ret		LIKE cajt014.j14_num_ret_sri
DEFINE val_ret		LIKE cajt014.j14_valor_ret
DEFINE tipo_f		LIKE cajt010.j10_tipo_fuente
DEFINE num_f		LIKE cajt010.j10_num_fuente
DEFINE cod_tr		LIKE cajt010.j10_tipo_destino
DEFINE num_tr		LIKE cajt010.j10_num_destino
DEFINE num_s		LIKE rept038.r38_num_sri

LET row_ini = 07
LET row_fin = 14
LET col_ini = 12
LET col_fin = 59
IF vg_gui = 0 THEN
	LET row_ini = 05
	LET row_fin = 15
	LET col_ini = 12
	LET col_fin = 60
END IF
OPEN WINDOW w_cajf203_3 AT row_ini, col_ini WITH row_fin ROWS, col_fin COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
			MESSAGE LINE LAST) 
IF vg_gui = 1 THEN
	OPEN FORM f_cajf203_3 FROM '../forms/cajf203_3'
ELSE
	OPEN FORM f_cajf203_3 FROM '../forms/cajf203_3c'
END IF
DISPLAY FORM f_cajf203_3
--#DISPLAY 'LC'			TO tit_col1
--#DISPLAY 'TP'			TO tit_col2
--#DISPLAY 'Documento'      	TO tit_col3
--#DISPLAY 'Numero SRI'      	TO tit_col4
--#DISPLAY 'Fecha Emi.'	 	TO tit_col5
--#DISPLAY 'Valor Ret.'		TO tit_col6
DISPLAY rm_j10.j10_codcli TO z20_codcli
DISPLAY rm_j10.j10_nomcli TO z01_nomcli
LET cambio = 0
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET col                    = 2
LET vm_columna_1           = col
LET vm_columna_2           = 3
LET rm_orden[vm_columna_1] = 'DESC'
LET rm_orden[vm_columna_2] = 'ASC'
WHILE TRUE
	CALL cargar_detalle_sol(tipo_llamada)
	IF vm_num_sol = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		LET int_flag = 1
		EXIT WHILE
	END IF
	IF vg_gui = 0 THEN
		CALL muestra_contadores_det(1, vm_num_sol)
	END IF
	LET int_flag = 0
	CALL set_count(vm_num_sol)
	DISPLAY ARRAY rm_detsol TO rm_detsol.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
		ON KEY(RETURN)
			LET i = arr_curr()
			LET j = scr_line()
			CALL muestra_contadores_det(i, vm_num_sol)
	       	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_3()
		ON KEY(F5)
			LET i = arr_curr()
			LET j = scr_line()
			CALL ver_documento(i)
			LET int_flag = 0
		ON KEY(F6)
			LET i = arr_curr()
			LET j = scr_line()
			IF rm_adi[i].z20_cod_tran = 'FA' THEN
				IF vg_codloc = 2 OR vg_codloc = 4 THEN
					CALL fl_ver_transaccion_rep(vg_codcia,
							vg_codloc,
							rm_adi[i].z20_cod_tran,
							rm_adi[i].z20_num_doc)
				ELSE
					CALL retorna_num_fue(i) RETURNING num_f
					CALL retorna_ret_fac(i)
						RETURNING tipo_f, cod_tr,
								num_tr, num_s
					LET num_tr = rm_adi[i].z20_num_doc
					IF rm_j10.j10_tipo_destino = 'PR' OR
					   rm_j10.j10_tipo_destino = 'PA'
					THEN
						LET num_tr =rm_detsol[i].num_doc
					END IF
				CALL fl_ver_comprobantes_emitidos_caja(tipo_f,
						num_f, rm_adi[i].z20_cod_tran,
						num_tr, rm_j10.j10_codcli)
				END IF
				LET int_flag = 0
			END IF
		ON KEY(F7)
			LET i = arr_curr()
			LET j = scr_line()
			IF tipo_llamada = 'C' THEN
				IF rm_detsol[i].valor_ret = 0 THEN
					--#CONTINUE DISPLAY
				END IF
			END IF
			IF tipo_llamada = 'I' THEN
				LET numero_ret = NULL
				CALL retorna_num_ret(numero_ret,codigo_pago,i,1)
					RETURNING numero_ret
			ELSE
				LET numero_ret = rm_adi[i].num_ret_s
			END IF
			CALL control_retenciones(numero_ret, codigo_pago,
							tipo_llamada, i)
				RETURNING num_ret, val_ret, entro
			IF tipo_llamada = 'I' THEN
				LET rm_detsol[i].valor_ret = val_ret
				IF rm_detsol[i].valor_ret IS NULL THEN
					LET rm_detsol[i].valor_ret = 0
				END IF
				DISPLAY rm_detsol[i].valor_ret TO
					rm_detsol[j].valor_ret
				CALL calcular_total_sol()
				IF entro THEN
					LET cambio = 1
				END IF
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
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel("INSERT","")
			--#CALL dialog.keysetlabel("DELETE","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
			--#DISPLAY rm_adi[1].z25_numero_sol TO z25_numero_sol
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#LET j = scr_line()
			--#IF rm_adi[i].z20_cod_tran = 'FA' THEN
				--#CALL dialog.keysetlabel("F6","Factura")
			--#ELSE
				--#CALL dialog.keysetlabel("F6","")
			--#END IF
			--#IF tipo_llamada = 'C' THEN
				--#IF rm_detsol[i].valor_ret = 0 THEN
					--#CALL dialog.keysetlabel("F7","")
				--#ELSE
					--#CALL dialog.keysetlabel("F7","Retenciones")
				--#END IF
			--#END IF
			--#CALL muestra_contadores_det(i, vm_num_sol)
			--#CALL calcular_total_sol()
		--#AFTER DISPLAY
			--#IF tipo_llamada = 'C' THEN
				--#CONTINUE DISPLAY
			--#END IF
			--#LET int_flag = 1
			--#EXIT DISPLAY
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
LET int_flag = 0
CLOSE WINDOW w_cajf203_3
RETURN cambio

END FUNCTION



FUNCTION cargar_detalle_sol(tipo_llamada)
DEFINE tipo_llamada	CHAR(1)
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_z24		RECORD LIKE cxct024.*
DEFINE tipo_doc		LIKE rept038.r38_tipo_doc
DEFINE tipo_f		LIKE cajt010.j10_tipo_fuente
DEFINE query		CHAR(4000)
DEFINE campo		VARCHAR(50)
DEFINE campo2		VARCHAR(20)
DEFINE tabla		VARCHAR(10)
DEFINE expr_joi		VARCHAR(200)
DEFINE cuantos		INTEGER

LET tipo_doc = 'FA'
CALL fl_lee_cliente_general(rm_j10.j10_codcli) RETURNING r_z01.*
IF r_z01.z01_tipo_doc_id <> 'R' AND vg_codloc = 3 THEN
	LET tipo_doc = 'NV'
END IF
LET campo     = ' NVL(SUM(valor_ret), 0.00) valor_ret '
LET campo2    = ' num_ret_sri '
LET tabla     = 'tmp_ret'
LET expr_joi  = '   AND cod_tr          = z20_cod_tran ',
		'   AND num_tr          = z20_num_tran '
IF tipo_llamada = 'C' THEN
	LET campo     = ' NVL(SUM(j14_valor_ret), 0.00) valor_ret '
	LET campo2    = ' j14_num_ret_sri '
	LET tabla     = 'cajt014'
	LET expr_joi  = '   AND j14_cod_tran    = z20_cod_tran ',
			'   AND j14_num_tran    = z20_num_tran '
END IF
CALL fl_lee_solicitud_cobro_cxc(vg_codcia, vg_codloc, rm_j10.j10_num_fuente)
	RETURNING r_z24.*
CASE r_z24.z24_areaneg
	WHEN 1 LET tipo_f = 'PR'
	WHEN 2 LET tipo_f = 'OT'
END CASE
LET query = 'SELECT z20_localidad, z20_tipo_doc, TRIM(NVL(z20_num_tran,',
		' z20_num_doc)) num_doc, r38_num_sri, z20_fecha_emi,',
		campo CLIPPED, ', z20_num_tran, z25_dividendo, z25_numero_sol,',
		' z24_areaneg, z20_cod_tran,', campo2 CLIPPED,
		' FROM cxct024, cxct025, cxct020, ', retorna_base_loc() CLIPPED,
			'rept038, OUTER ', tabla,
		' WHERE z24_compania    = ', vg_codcia,
		'   AND z24_localidad   = ', vg_codloc,
		'   AND z24_numero_sol  = ', rm_j10.j10_num_fuente,
		'   AND z25_compania    = z24_compania ',
		'   AND z25_localidad   = z24_localidad ',
		'   AND z25_numero_sol  = z24_numero_sol ',
		'   AND z20_compania    = z25_compania ',
		'   AND z20_localidad   = z25_localidad ',
		'   AND z20_codcli      = z25_codcli ',
		'   AND z20_tipo_doc    = z25_tipo_doc ',
		'   AND z20_num_doc     = z25_num_doc ',
		'   AND z20_dividendo   = z25_dividendo ',
		'   AND r38_compania    = z20_compania ',
		'   AND r38_localidad   = z20_localidad ',
		'   AND r38_tipo_doc    IN ("FA", "NV") ',
		--'   AND r38_tipo_doc    = "', tipo_doc, '"',
		'   AND r38_tipo_fuente = "', tipo_f CLIPPED, '"',
		'   AND r38_cod_tran    = z20_cod_tran ',
		'   AND r38_num_tran    = z20_num_tran ',
		expr_joi CLIPPED,
		' GROUP BY 1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 12 ',
	' UNION ',
	' SELECT z20_localidad, z20_tipo_doc, TRIM(NVL(z20_num_tran,',
		' z20_num_doc) || " ") num_doc, r38_num_sri, z20_fecha_emi,',
		campo CLIPPED, ', z20_num_tran, 0, z24_numero_sol,',
		' z24_areaneg, z20_cod_tran,', campo2 CLIPPED,
		' FROM cxct024, cajt010, cxct023, cxct020, ',
			retorna_base_loc() CLIPPED, 'rept038, OUTER ', tabla,
		' WHERE z24_compania    = ', vg_codcia,
		'   AND z24_localidad   = ', vg_codloc,
		'   AND z24_numero_sol  = ', rm_j10.j10_num_fuente,
		'   AND j10_compania    = z24_compania ',
		'   AND j10_localidad   = z24_localidad ',
		'   AND j10_tipo_fuente = "SC" ',
		'   AND j10_num_fuente  = z24_numero_sol ',
		'   AND z23_compania    = j10_compania ',
		'   AND z23_localidad   = j10_localidad ',
		'   AND z23_codcli      = j10_codcli ',
		'   AND z23_tipo_favor  = j10_tipo_destino ',
		'   AND z23_doc_favor   = j10_num_destino ',
		'   AND z20_compania    = z23_compania ',
		'   AND z20_localidad   = z23_localidad ',
		'   AND z20_codcli      = z23_codcli ',
		'   AND z20_tipo_doc    = z23_tipo_doc ',
		'   AND z20_num_doc     = z23_num_doc ',
		'   AND z20_dividendo   = z23_div_doc ',
		'   AND r38_compania    = z20_compania ',
		'   AND r38_localidad   = z20_localidad ',
		'   AND r38_tipo_doc    IN ("FA", "NV") ',
		--'   AND r38_tipo_doc    = "', tipo_doc, '"',
		'   AND r38_tipo_fuente = "', tipo_f CLIPPED, '"',
		'   AND r38_cod_tran    = z20_cod_tran ',
		'   AND r38_num_tran    = z20_num_tran ',
		expr_joi CLIPPED,
		' GROUP BY 1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 12 ',
                ' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
			', ', vm_columna_2, ' ', rm_orden[vm_columna_2] 
PREPARE cons_fac FROM query
DECLARE q_fact_c CURSOR FOR cons_fac
LET vm_num_sol = 1
FOREACH q_fact_c INTO rm_detsol[vm_num_sol].*, rm_adi[vm_num_sol].*
	LET vm_num_sol = vm_num_sol + 1
	IF vm_num_sol > vm_max_sol THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_sol = vm_num_sol - 1
CALL calcular_total_sol()

END FUNCTION



FUNCTION calcular_total_sol()
DEFINE tot_ret		DECIMAL(14,2)
DEFINE i		SMALLINT

LET tot_ret = 0
FOR i = 1 TO vm_num_sol
	LET tot_ret = tot_ret + rm_detsol[i].valor_ret
END FOR
DISPLAY BY NAME tot_ret

END FUNCTION



FUNCTION control_retenciones(numero_ret, codigo_pago, tipo_llamada, posi)
DEFINE numero_ret	LIKE cajt011.j11_num_ch_aut
DEFINE codigo_pago	LIKE cajt001.j01_codigo_pago
DEFINE tipo_llamada	CHAR(1)
DEFINE posi		SMALLINT
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r23		RECORD LIKE rept023.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE j10_tipo_destino	LIKE cajt010.j10_tipo_destino
DEFINE j10_num_destino	LIKE cajt010.j10_num_destino
DEFINE row_ini, col_ini	SMALLINT
DEFINE row_fin, col_fin	SMALLINT
DEFINE entro		SMALLINT
DEFINE valor_bruto	DECIMAL(14,2)
DEFINE valor_impto	DECIMAL(14,2)
DEFINE subtotal		DECIMAL(14,2)
DEFINE flete		DECIMAL(14,2)
DEFINE valor_fact	DECIMAL(14,2)

LET row_ini = 04
LET row_fin = 20
LET col_ini = 04
LET col_fin = 74
IF vg_gui = 0 THEN
	LET row_ini = 05
	LET row_fin = 18
	LET col_ini = 04
	LET col_fin = 74
END IF
OPEN WINDOW w_cajf203_2 AT row_ini, col_ini WITH row_fin ROWS, col_fin COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
			MESSAGE LINE LAST) 
IF vg_gui = 1 THEN
	OPEN FORM f_cajf203_2 FROM '../forms/cajf203_2'
ELSE
	OPEN FORM f_cajf203_2 FROM '../forms/cajf203_2c'
END IF
DISPLAY FORM f_cajf203_2
LET vm_num_ret = 0
LET vm_max_ret = 50
CALL borrar_retenciones()
--#DISPLAY 'T'		 TO tit_col1
--#DISPLAY '%'		 TO tit_col2
--#DISPLAY 'Cod. SRI' 	 TO tit_col3
--#DISPLAY 'Descripcion' TO tit_col4
--#DISPLAY 'Base Imp.'	 TO tit_col5
--#DISPLAY 'Valor Ret.'	 TO tit_col6
IF rm_j10.j10_tipo_fuente = 'PR' THEN
	CALL fl_lee_preventa_rep(vg_codcia, vg_codloc, rm_j10.j10_num_fuente)
		RETURNING r_r23.*
	LET valor_bruto = r_r23.r23_tot_bruto - r_r23.r23_tot_dscto
	LET valor_impto = r_r23.r23_tot_neto - r_r23.r23_tot_bruto +
				r_r23.r23_tot_dscto - r_r23.r23_flete
	LET subtotal    = valor_bruto + valor_impto
	LET flete       = r_r23.r23_flete
END IF
IF rm_j10.j10_tipo_fuente = 'OT' THEN
	CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc, rm_j10.j10_num_fuente)
		RETURNING r_t23.*
	--LET valor_bruto = r_t23.t23_tot_bruto - r_t23.t23_tot_dscto
	LET valor_bruto = r_t23.t23_tot_bruto - r_t23.t23_vde_mo_tal
	LET valor_impto = r_t23.t23_val_impto
	LET subtotal    = valor_bruto + valor_impto
	LET flete       = NULL
END IF
DISPLAY rm_r38.r38_num_sri TO num_sri
LET valor_fact       = rm_j10.j10_valor
LET j10_tipo_destino = rm_j10.j10_tipo_destino
LET j10_num_destino  = rm_j10.j10_num_destino
IF rm_j10.j10_tipo_fuente = 'SC' THEN
	DISPLAY rm_detsol[posi].num_sri TO num_sri
	LET j10_tipo_destino = rm_adi[posi].z20_cod_tran
	LET j10_num_destino  = rm_adi[posi].z20_num_doc
	IF rm_j10.j10_tipo_destino = 'PR' OR rm_j10.j10_tipo_destino = 'PA' THEN
		LET j10_num_destino = rm_detsol[posi].num_doc
	END IF
	CASE rm_adi[posi].z24_areaneg
		WHEN 1
			CALL fl_lee_cabecera_transaccion_rep(vg_codcia,
						vg_codloc,
						rm_adi[posi].z20_cod_tran,
						j10_num_destino)
				RETURNING r_r19.*
			IF r_r19.r19_compania IS NULL THEN
				CALL lee_cabecera_transaccion_loc(vg_codcia,
						vg_codloc,
						rm_adi[posi].z20_cod_tran,
						j10_num_destino)
					RETURNING r_r19.*
			END IF
			LET valor_bruto = r_r19.r19_tot_bruto -
						r_r19.r19_tot_dscto
			LET valor_impto = r_r19.r19_tot_neto -
						r_r19.r19_tot_bruto +
						r_r19.r19_tot_dscto -
						r_r19.r19_flete
			LET subtotal    = valor_bruto + valor_impto
			LET flete       = r_r19.r19_flete
			LET valor_fact  = subtotal + flete
		WHEN 2
			CALL fl_lee_factura_taller(vg_codcia, vg_codloc,
						j10_num_destino)
				RETURNING r_t23.*
			LET valor_bruto = r_t23.t23_tot_bruto -
							--r_t23.t23_tot_dscto
							r_t23.t23_vde_mo_tal
			LET valor_impto = r_t23.t23_val_impto
			LET subtotal    = valor_bruto + valor_impto
			LET flete       = NULL
			LET valor_fact  = subtotal
	END CASE
END IF
DISPLAY BY NAME rm_j10.j10_tipo_fuente, rm_j10.j10_num_fuente,rm_j10.j10_codcli,
		rm_j10.j10_nomcli, valor_bruto, valor_impto, subtotal, flete,
		valor_fact, j10_tipo_destino, j10_num_destino
CASE tipo_llamada
	WHEN 'I' CALL ingreso_retenciones(numero_ret, codigo_pago, posi)
			RETURNING entro
	WHEN 'C' CALL consulta_retenciones(numero_ret, codigo_pago, posi)
END CASE
LET int_flag = 0
CLOSE WINDOW w_cajf203_2
RETURN rm_j14.j14_num_ret_sri, tot_valor_ret, entro

END FUNCTION



FUNCTION ingreso_retenciones(numero_ret, codigo_pago, posi)
DEFINE numero_ret	LIKE cajt011.j11_num_ch_aut
DEFINE codigo_pago	LIKE cajt001.j01_codigo_pago
DEFINE posi		SMALLINT
DEFINE entro, i		SMALLINT

CALL cargar_retenciones(numero_ret, codigo_pago, posi)
CALL lee_retenciones(numero_ret, codigo_pago, posi)
IF int_flag THEN
	IF registros_retenciones(numero_ret, codigo_pago, posi) = 0 THEN
		INITIALIZE rm_j14.j14_num_ret_sri, tot_valor_ret TO NULL
		LET vm_num_ret = 0
	END IF
	LET entro = 0
ELSE
	CALL borrar_retencion(numero_ret, codigo_pago, posi)
	FOR i = 1 TO vm_num_ret
		INSERT INTO tmp_ret
			VALUES(codigo_pago, rm_j14.j14_num_ret_sri,
				rm_j14.j14_autorizacion, rm_j14.j14_fecha_emi,
				rm_detret[i].*, rm_adi_r[i].*, fec_ini_por[i])
	END FOR
	LET entro = 1
END IF
RETURN entro

END FUNCTION



FUNCTION consulta_retenciones(numero_ret, codigo_pago, posi)
DEFINE numero_ret	LIKE cajt011.j11_num_ch_aut
DEFINE codigo_pago	LIKE cajt001.j01_codigo_pago
DEFINE posi		SMALLINT
DEFINE sec		LIKE cajt014.j14_sec_ret
DEFINE num_sri		LIKE rept038.r38_num_sri
DEFINE cod_tr		LIKE cajt010.j10_tipo_destino
DEFINE num_tr		LIKE cajt010.j10_num_destino
DEFINE query		CHAR(2000)
DEFINE i, j		SMALLINT

LET cod_tr = rm_j10.j10_tipo_destino
LET num_tr = rm_j10.j10_num_destino
IF posi > 0 THEN
	LET cod_tr = rm_adi[posi].z20_cod_tran
	LET num_tr = rm_adi[posi].z20_num_doc
	IF rm_j10.j10_tipo_destino = 'PR' OR rm_j10.j10_tipo_destino = 'PA'
	THEN
		LET num_tr = rm_detsol[posi].num_doc
	END IF
END IF
LET query = 'SELECT j14_num_ret_sri, j14_autorizacion, j14_fecha_emi, ',
			'r38_num_sri, j14_tipo_ret, j14_porc_ret, ',
			'j14_codigo_sri, c03_concepto_ret, ',
			'j14_base_imp, j14_valor_ret, j14_tipo_fue, ',
			'j14_cod_tran, j14_num_tran, r38_num_sri, ',
			'r38_tipo_doc, j14_fec_emi_fact, j14_sec_ret, ',
			'j14_fec_ini_porc ',
		' FROM cajt014, ', retorna_base_loc() CLIPPED, 'rept038, ',
			'ordt003 ',
		' WHERE j14_compania       = ', vg_codcia,
		'   AND j14_localidad      = ', vg_codloc,
		'   AND j14_tipo_fuente    = "', rm_j10.j10_tipo_fuente, '"',
		'   AND j14_num_fuente     = ', rm_j10.j10_num_fuente,
		'   AND j14_num_ret_sri    = "', numero_ret, '"',
		'   AND j14_codigo_pago    = "', codigo_pago, '"',
		'   AND j14_cod_tran       = "', cod_tr, '"',
		'   AND j14_num_tran       = ', num_tr,
		'   AND r38_compania       = j14_compania ',
		'   AND r38_localidad      = j14_localidad ',
		'   AND r38_tipo_doc       = j14_tipo_doc ',
		'   AND r38_tipo_fuente    = j14_tipo_fue ',
		'   AND r38_cod_tran       = j14_cod_tran ',
		'   AND r38_num_tran       = j14_num_tran ',
		'   AND c03_compania       = j14_compania ',
		'   AND c03_tipo_ret       = j14_tipo_ret ',
		'   AND c03_porcentaje     = j14_porc_ret ',
		'   AND c03_codigo_sri     = j14_codigo_sri ',
		'   AND c03_fecha_ini_porc = j14_fec_ini_porc ',
		' ORDER BY j14_sec_ret '
PREPARE cons_ret3 FROM query
DECLARE q_ret3 CURSOR FOR cons_ret3
LET vm_num_ret = 1
FOREACH q_ret3 INTO rm_j14.j14_num_ret_sri, rm_j14.j14_autorizacion,
			rm_j14.j14_fecha_emi, num_sri, rm_detret[vm_num_ret].*,
			rm_adi_r[vm_num_ret].*, sec, fec_ini_por[vm_num_ret]
	LET vm_num_ret = vm_num_ret + 1
	IF vm_num_ret > vm_max_ret THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_ret = vm_num_ret - 1
IF vm_num_ret = 0 THEN
	RETURN
END IF
DISPLAY BY NAME rm_j14.j14_num_ret_sri, rm_j14.j14_autorizacion,
		rm_j14.j14_fecha_emi, num_sri
CALL calcular_tot_retencion(vm_num_ret)
CALL muestra_contadores_det(1, vm_num_ret)
CALL set_count(vm_num_ret)
DISPLAY ARRAY rm_detret TO rm_detret.*
	ON KEY(INTERRUPT)
		EXIT DISPLAY
       	ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(RETURN)
		LET i = arr_curr()
        	LET j = scr_line()
		CALL muestra_contadores_det(i, vm_num_ret)
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
                --#CALL dialog.keysetlabel('ACCEPT', '')
		--#CALL dialog.keysetlabel('RETURN','')
	--#BEFORE ROW
		--#LET i = arr_curr()
		--#LET j = scr_line()
		--#CALL muestra_contadores_det(i, vm_num_ret)
        --#AFTER DISPLAY
                --#CONTINUE DISPLAY
END DISPLAY
CALL muestra_contadores_det(0, vm_num_ret)

END FUNCTION



FUNCTION borrar_retenciones()
DEFINE i		SMALLINT

INITIALIZE rm_j14.* TO NULL
FOR i = 1 TO fgl_scr_size('rm_detret')
	CLEAR rm_detret[i].*
END FOR
FOR i = 1 TO vm_max_ret
	INITIALIZE rm_detret[i].* TO NULL
END FOR
CLEAR j14_num_ret_sri, j14_autorizacion, j14_fecha_emi, num_row, max_row,
	tot_base_imp, tot_valor_ret, j10_codcli, j10_nomcli, valor_bruto,
	valor_impto, subtotal, flete, j10_tipo_fuente, j10_num_fuente,
	j10_tipo_destino, j10_num_destino, num_sri

END FUNCTION



FUNCTION cargar_retenciones(numero_ret, codigo_pago, posi)
DEFINE numero_ret	LIKE cajt011.j11_num_ch_aut
DEFINE codigo_pago	LIKE cajt001.j01_codigo_pago
DEFINE posi		SMALLINT
DEFINE tipo_fue		LIKE ordt002.c02_tipo_fuente
DEFINE tipo_f		LIKE cajt010.j10_tipo_fuente
DEFINE num_f		LIKE cajt010.j10_num_fuente
DEFINE cod_tr		LIKE cajt010.j10_tipo_destino
DEFINE num_tr		LIKE cajt010.j10_num_destino
DEFINE num_s		LIKE rept038.r38_num_sri
DEFINE tip_d		LIKE rept038.r38_tipo_doc
DEFINE query		CHAR(8000)
DEFINE expr_sql		VARCHAR(100)
DEFINE expr_tip		VARCHAR(150)
DEFINE i, lim		INTEGER
DEFINE fec_f		DATE

CALL retorna_num_fue(posi) RETURNING num_f
CALL retorna_ret_fac(posi) RETURNING tipo_f, cod_tr, num_tr, num_s
IF registros_retenciones(numero_ret, codigo_pago, posi) = 0 THEN
	CASE tipo_f
		WHEN "PR" LET tipo_fue = 'B'
		WHEN "OT" LET tipo_fue = 'S'
	END CASE
	LET expr_tip = ', "', vm_tipo_doc, '" tip_doc, "', vg_fecha, '" fec_fact, ',
			'z08_fecha_ini_porc fec_ini_porc '
	IF rm_j10.j10_tipo_fuente = 'SC' THEN
		CALL retorna_tipo_doc(posi, tipo_f) RETURNING tip_d, fec_f
		LET expr_tip = ', "', tip_d, '" tip_doc, "',fec_f,
				'" fec_fact, z08_fecha_ini_porc fec_ini_porc '
	END IF
	LET query = 'SELECT "", "", "", ',
			' CASE WHEN ("', tipo_f, '" = "PR" AND ',
					'c03_tipo_fuente = "B") OR',
				' ("', tipo_f, '" = "OT" AND ',
					'c03_tipo_fuente = "B" AND ',
				'(SELECT t23_val_mo_cti ',
				'FROM talt023 ',
				'WHERE t23_compania  = z08_compania ',
				'  AND t23_localidad = ', rm_j10.j10_localidad,
				'  AND t23_orden     = ', num_f, ') > 0) OR ',
				' ("', tipo_f, '" = "OT" AND ',
					'c03_tipo_fuente = "S" AND ',
				'(SELECT t23_val_mo_tal ',
				'FROM talt023 ',
				'WHERE t23_compania  = z08_compania ',
				'  AND t23_localidad = ', rm_j10.j10_localidad,
				'  AND t23_orden     = ', num_f, ') > 0) OR ',
				' ("', tipo_f, '" = "OT" AND ',
					'c03_tipo_fuente = "T") ',
				'THEN z08_tipo_ret ',
			' END, ',
			' CASE WHEN ("', tipo_f, '" = "PR" AND ',
					'c03_tipo_fuente = "B") OR',
				' ("', tipo_f, '" = "OT" AND ',
					'c03_tipo_fuente = "B" AND ',
				'(SELECT t23_val_mo_cti ',
				'FROM talt023 ',
				'WHERE t23_compania  = z08_compania ',
				'  AND t23_localidad = ', rm_j10.j10_localidad,
				'  AND t23_orden     = ', num_f, ') > 0) OR ',
				' ("', tipo_f, '" = "OT" AND ',
					'c03_tipo_fuente = "S" AND ',
				'(SELECT t23_val_mo_tal ',
				'FROM talt023 ',
				'WHERE t23_compania  = z08_compania ',
				'  AND t23_localidad = ', rm_j10.j10_localidad,
				'  AND t23_orden     = ', num_f, ') > 0) OR ',
				' ("', tipo_f, '" = "OT" AND ',
					'c03_tipo_fuente = "T") ',
				'THEN z08_porcentaje ',
			' END, ',
			' z08_codigo_sri, c03_concepto_ret, ',
			' CASE WHEN "', tipo_f, '" = "PR" AND ',
					'c03_tipo_fuente = "B" THEN',
			' (SELECT r23_tot_bruto - r23_tot_dscto ',
				'FROM ', retorna_base_loc() CLIPPED, 'rept023 ',
				'WHERE r23_compania  = z08_compania ',
				'  AND r23_localidad = ', rm_j10.j10_localidad,
				'  AND r23_numprev   = ', num_f,
				')',
			'      WHEN "', tipo_f, '" = "OT" AND ',
					'c03_tipo_fuente = "B" AND ',
				'(SELECT t23_val_mo_cti ',
				'FROM talt023 ',
				'WHERE t23_compania  = z08_compania ',
				'  AND t23_localidad = ', rm_j10.j10_localidad,
				'  AND t23_orden     = ', num_f, ') > 0 ',
				'THEN',
			' (SELECT t23_val_mo_cti ',
				'FROM talt023 ',
				'WHERE t23_compania  = z08_compania ',
				'  AND t23_localidad = ', rm_j10.j10_localidad,
				'  AND t23_orden     = ', num_f,
				')',
			'      WHEN "', tipo_f, '" = "OT" AND ',
					'c03_tipo_fuente = "S" AND ',
				'(SELECT t23_val_mo_tal ',
				'FROM talt023 ',
				'WHERE t23_compania  = z08_compania ',
				'  AND t23_localidad = ', rm_j10.j10_localidad,
				'  AND t23_orden     = ', num_f, ') > 0 ',
				'THEN',
			' (SELECT t23_val_mo_tal - t23_vde_mo_tal ',
				'FROM talt023 ',
				'WHERE t23_compania  = z08_compania ',
				'  AND t23_localidad = ', rm_j10.j10_localidad,
				'  AND t23_orden     = ', num_f,
				')',
			'      WHEN "', tipo_f, '" = "OT" AND ',
					'c03_tipo_fuente = "T" THEN ',
			' (SELECT t23_tot_bruto - t23_vde_mo_tal ',
				'FROM talt023 ',
				'WHERE t23_compania  = z08_compania ',
				'  AND t23_localidad = ', rm_j10.j10_localidad,
				'  AND t23_orden     = ', num_f,
				')',
			--' ELSE 0 ',
			' END, ',
			' CASE WHEN "', tipo_f, '" = "PR" AND ',
					'c03_tipo_fuente = "B" THEN',
			' (SELECT r23_tot_bruto - r23_tot_dscto ',
				'FROM ', retorna_base_loc() CLIPPED, 'rept023 ',
				'WHERE r23_compania  = z08_compania ',
				'  AND r23_localidad = ', rm_j10.j10_localidad,
				'  AND r23_numprev   = ', num_f,
				')',
			'      WHEN "', tipo_f, '" = "OT" AND ',
					'c03_tipo_fuente = "B" AND ',
				'(SELECT t23_val_mo_cti ',
				'FROM talt023 ',
				'WHERE t23_compania  = z08_compania ',
				'  AND t23_localidad = ', rm_j10.j10_localidad,
				'  AND t23_orden     = ', num_f, ') > 0 ',
				'THEN',
			' (SELECT t23_val_mo_cti ',
				'FROM talt023 ',
				'WHERE t23_compania  = z08_compania ',
				'  AND t23_localidad = ', rm_j10.j10_localidad,
				'  AND t23_orden     = ', num_f,
				')',
			'      WHEN "', tipo_f, '" = "OT" AND ',
					'c03_tipo_fuente = "S" AND ',
				'(SELECT t23_val_mo_tal ',
				'FROM talt023 ',
				'WHERE t23_compania  = z08_compania ',
				'  AND t23_localidad = ', rm_j10.j10_localidad,
				'  AND t23_orden     = ', num_f, ') > 0 ',
				'THEN',
			' (SELECT t23_val_mo_tal - t23_vde_mo_tal ',
				'FROM talt023 ',
				'WHERE t23_compania  = z08_compania ',
				'  AND t23_localidad = ', rm_j10.j10_localidad,
				'  AND t23_orden     = ', num_f,
				')',
			'      WHEN "', tipo_f, '" = "OT" AND ',
					'c03_tipo_fuente = "T" THEN ',
			' (SELECT t23_tot_bruto - t23_vde_mo_tal ',
				'FROM talt023 ',
				'WHERE t23_compania  = z08_compania ',
				'  AND t23_localidad = ', rm_j10.j10_localidad,
				'  AND t23_orden     = ', num_f,
				')',
			--' ELSE 0 ',
			' END * (c02_porcentaje / 100),',
			' "', tipo_f, '" tipo_f, "', cod_tr, '" cod_tr, "',
			num_tr, '" num_tr, "', num_s, '" num_sri ',
			expr_tip CLIPPED,
			' FROM cxct008, ordt003, ordt002, cajt091 ',
			' WHERE z08_compania       = ', vg_codcia,
			'   AND z08_codcli         = ', rm_j10.j10_codcli,
			'   AND z08_defecto        = "S" ',
			'   AND c03_compania       = z08_compania ',
			'   AND c03_tipo_ret       = z08_tipo_ret ',
			'   AND c03_porcentaje     = z08_porcentaje ',
			'   AND c03_codigo_sri     = z08_codigo_sri ',
			'   AND c03_fecha_ini_porc = z08_fecha_ini_porc ',
			'   AND c03_estado         = "A" ',
			'   AND c02_compania       = c03_compania ',
			'   AND c02_tipo_ret       = c03_tipo_ret ',
			'   AND c02_porcentaje     = c03_porcentaje ',
			'   AND c02_estado         = "A" ',
			'   AND j91_compania       = c02_compania ',
			'   AND j91_codigo_pago    = "', codigo_pago, '"',
			'   AND j91_cont_cred      = "C" ',
			'   AND j91_tipo_ret       = c02_tipo_ret ',
			'   AND j91_porcentaje     = c02_porcentaje ',
		' UNION ',
		' SELECT "", "", "", z08_tipo_ret, z08_porcentaje,',
			' c03_codigo_sri, c03_concepto_ret,',
			' CASE WHEN "', tipo_f, '" = "PR" AND ',
					'c03_tipo_fuente = "B" THEN',
			' (SELECT r23_flete ',
				'FROM ', retorna_base_loc() CLIPPED, 'rept023 ',
				'WHERE r23_compania  = z08_compania ',
				'  AND r23_localidad = ', rm_j10.j10_localidad,
				'  AND r23_numprev   = ', num_f,
				')',
			' ELSE 0 ',
			' END, ',
			' CASE WHEN "', tipo_f, '" = "PR" AND ',
					'c03_tipo_fuente = "B" THEN',
			' (SELECT r23_flete ',
				'FROM ', retorna_base_loc() CLIPPED, 'rept023 ',
				'WHERE r23_compania  = z08_compania ',
				'  AND r23_localidad = ', rm_j10.j10_localidad,
				'  AND r23_numprev   = ', num_f,
				')',
			' ELSE 0 ',
			' END * (c02_porcentaje / 100),',
			' "', tipo_f, '" tipo_f, "', cod_tr, '" cod_tr, "',
			num_tr, '" num_tr, "', num_s, '" num_sri ',
			expr_tip CLIPPED,
			' FROM cxct008, ordt003, ordt002, cajt091 ',
			' WHERE z08_compania       = ', vg_codcia,
			'   AND z08_codcli         = ', rm_j10.j10_codcli,
			'   AND z08_flete          = "S" ',
			'   AND c03_compania       = z08_compania ',
			'   AND c03_tipo_ret       = z08_tipo_ret ',
			'   AND c03_porcentaje     = z08_porcentaje ',
			'   AND c03_codigo_sri     = z08_codigo_sri ',
			'   AND c03_fecha_ini_porc = z08_fecha_ini_porc ',
			'   AND c03_estado         = "A" ',
			'   AND c02_compania       = c03_compania ',
			'   AND c02_tipo_ret       = c03_tipo_ret ',
			'   AND c02_porcentaje     = c03_porcentaje ',
			'   AND c02_estado         = "A" ',
			'   AND j91_compania       = c02_compania ',
			'   AND j91_codigo_pago    = "', codigo_pago, '"',
			'   AND j91_cont_cred      = "C" ',
			'   AND j91_tipo_ret       = c02_tipo_ret ',
			'   AND j91_porcentaje     = c02_porcentaje ',
			'   AND EXISTS (SELECT 1 FROM ',
					retorna_base_loc() CLIPPED, 'rept023 ',
				'WHERE r23_compania  = z08_compania ',
				'  AND r23_localidad = ', rm_j10.j10_localidad,
				'  AND r23_numprev   = ', num_f,
				'  AND r23_flete     > 0) ',
		' UNION ',
		' SELECT "", "", "", z08_tipo_ret, z08_porcentaje,',
			' c03_codigo_sri, c03_concepto_ret,',
			' CASE WHEN "', tipo_f, '" = "PR" AND ',
					'c03_tipo_fuente = "B" THEN',
			' (SELECT r23_tot_neto - r23_tot_bruto + ',
					'r23_tot_dscto - r23_flete ',
				'FROM ', retorna_base_loc() CLIPPED, 'rept023 ',
				'WHERE r23_compania  = z08_compania ',
				'  AND r23_localidad = ', rm_j10.j10_localidad,
				'  AND r23_numprev   = ', num_f,
				')',
			'      WHEN "', tipo_f, '" = "OT" THEN',
			' (SELECT t23_val_impto ',
				'FROM talt023 ',
				'WHERE t23_compania  = z08_compania ',
				'  AND t23_localidad = ', rm_j10.j10_localidad,
				'  AND t23_orden     = ', num_f,
				')',
			' ELSE 0 ',
			' END, ',
			' CASE WHEN "', tipo_f, '" = "PR" AND ',
					'c03_tipo_fuente = "B" THEN',
			' (SELECT r23_tot_neto - r23_tot_bruto + ',
					'r23_tot_dscto - r23_flete ',
				'FROM ', retorna_base_loc() CLIPPED, 'rept023 ',
				'WHERE r23_compania  = z08_compania ',
				'  AND r23_localidad = ', rm_j10.j10_localidad,
				'  AND r23_numprev   = ', num_f,
				')',
			'      WHEN "', tipo_f, '" = "OT" THEN',
			' (SELECT t23_val_impto ',
				'FROM talt023 ',
				'WHERE t23_compania  = z08_compania ',
				'  AND t23_localidad = ', rm_j10.j10_localidad,
				'  AND t23_orden     = ', num_f,
				')',
			' ELSE 0 ',
			' END * (c02_porcentaje / 100),',
			' "', tipo_f, '" tipo_f, "', cod_tr, '" cod_tr, "',
			num_tr, '" num_tr, "', num_s, '" num_sri ',
			expr_tip CLIPPED,
			' FROM cxct008, ordt003, ordt002, cajt091 ',
			' WHERE z08_compania       = ', vg_codcia,
			'   AND z08_codcli         = ', rm_j10.j10_codcli,
			'   AND z08_tipo_ret       = "I" ',
			'   AND c03_compania       = z08_compania ',
			'   AND c03_tipo_ret       = z08_tipo_ret ',
			'   AND c03_porcentaje     = z08_porcentaje ',
			'   AND c03_codigo_sri     = z08_codigo_sri ',
			'   AND c03_fecha_ini_porc = z08_fecha_ini_porc ',
			'   AND c03_estado         = "A" ',
			'   AND c02_compania       = c03_compania ',
			'   AND c02_tipo_ret       = c03_tipo_ret ',
			'   AND c02_porcentaje     = c03_porcentaje ',
			'   AND c02_estado         = "A" ',
			'   AND c02_tipo_fuente    = "', tipo_fue, '"',
			'   AND j91_compania       = c02_compania ',
			'   AND j91_codigo_pago    = "', codigo_pago, '"',
			'   AND j91_cont_cred      = "C" ',
			'   AND j91_tipo_ret       = c02_tipo_ret ',
			'   AND j91_porcentaje     = c02_porcentaje '
ELSE
	LET expr_sql = NULL
	IF numero_ret IS NOT NULL THEN
		LET expr_sql = '   AND num_ret_sri = "', numero_ret CLIPPED, '"'
	END IF
	LET query = 'SELECT num_ret_sri, autorizacion, fecha_emi, tipo_ret,',
			' porc_ret, codigo_sri, concepto_ret, base_imp,',
			' valor_ret, tipo_fuente, cod_tr, num_tr, num_fac_sri,',
			' tipo_doc, fec_fact, fec_ini_porc ',
			' FROM tmp_ret ',
			' WHERE cod_pago    = "', codigo_pago, '"',
			'   AND tipo_fuente = "', tipo_f, '"',
			expr_sql CLIPPED
	IF posi > 0 THEN
		LET query = query CLIPPED,
				'   AND cod_tr      = "', cod_tr, '"',
				'   AND num_tr      = "', num_tr, '"'
	END IF
END IF
PREPARE cons_ret FROM query
DECLARE q_cons_ret CURSOR FOR cons_ret
LET vm_num_ret = 1
FOREACH q_cons_ret INTO rm_j14.j14_num_ret_sri, rm_j14.j14_autorizacion,
			rm_j14.j14_fecha_emi, rm_detret[vm_num_ret].*,
			rm_adi_r[vm_num_ret].*, fec_ini_por[vm_num_ret]
	IF rm_detret[vm_num_ret].j14_tipo_ret IS NULL THEN
		CONTINUE FOREACH
	END IF
	IF registros_retenciones(numero_ret, codigo_pago, posi) = 0 THEN
		IF LENGTH(rm_detret[vm_num_ret].j14_codigo_sri) < 2 THEN
			INITIALIZE rm_j14.* TO NULL
			LET rm_detret[vm_num_ret].j14_codigo_sri   = NULL
			LET rm_detret[vm_num_ret].c03_concepto_ret = NULL
		END IF
	END IF
	IF LENGTH(rm_j14.j14_num_ret_sri) < 14 THEN
		LET rm_j14.j14_num_ret_sri = NULL
	END IF
	LET vm_num_ret = vm_num_ret + 1
	IF vm_num_ret > vm_max_ret THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_ret = vm_num_ret - 1
IF vm_num_ret = 0 THEN
	RETURN
END IF
IF rm_j14.j14_num_ret_sri IS NULL THEN
	RETURN
END IF
LET lim = vm_num_ret
IF lim > fgl_scr_size('rm_detret') THEN
	LET lim = fgl_scr_size('rm_detret')
END IF
FOR i = 1 TO lim
	DISPLAY rm_detret[i].* TO rm_detret[i].*
END FOR
CALL calcular_tot_retencion(lim)

END FUNCTION



FUNCTION lee_retenciones(numero_ret, codigo_pago, posi)
DEFINE numero_ret	LIKE cajt011.j11_num_ch_aut
DEFINE codigo_pago	LIKE cajt001.j01_codigo_pago
DEFINE posi		SMALLINT
DEFINE salir		SMALLINT

LET salir = 0
WHILE NOT salir
	CALL lee_cabecera_ret(numero_ret, codigo_pago, posi)
	IF int_flag THEN
		OPTIONS INPUT WRAP
		EXIT WHILE
	END IF
	OPTIONS INPUT WRAP
	CALL lee_detalle_ret(codigo_pago, posi) RETURNING salir
	IF int_flag THEN
		EXIT WHILE
	END IF
END WHILE

END FUNCTION



FUNCTION lee_cabecera_ret(numero_ret, codigo_pago, posi)
DEFINE numero_ret	LIKE cajt011.j11_num_ch_aut
DEFINE codigo_pago	LIKE cajt001.j01_codigo_pago
DEFINE posi, dias_tope	SMALLINT
DEFINE r_j14		RECORD LIKE cajt014.*
DEFINE resp		CHAR(6)
DEFINE fecha		DATE
DEFINE fecha_min	DATE
DEFINE fecha_tope	DATE
DEFINE mensaje		VARCHAR(200)

OPTIONS INPUT NO WRAP
IF rm_j14.j14_fecha_emi IS NULL THEN
	LET rm_j14.j14_fecha_emi = vg_fecha
END IF
LET int_flag = 0
INPUT BY NAME rm_j14.j14_num_ret_sri, rm_j14.j14_autorizacion,
	rm_j14.j14_fecha_emi
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(j14_num_ret_sri, j14_autorizacion,
					j14_fecha_emi)
		THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
       	ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD j14_autorizacion
		IF rm_j14.j14_autorizacion IS NULL THEN
			DECLARE q_aut CURSOR FOR
				SELECT autorizacion
					FROM tmp_ret
			OPEN q_aut
			FETCH q_aut INTO rm_j14.j14_autorizacion
			DISPLAY BY NAME rm_j14.j14_autorizacion
			CLOSE q_aut
			FREE q_aut
		END IF
	BEFORE FIELD j14_fecha_emi
		LET fecha = rm_j14.j14_fecha_emi
		IF rm_j10.j10_tipo_fuente = 'SC' THEN
			CALL retorna_fec_emi() RETURNING fecha
			IF fecha IS NOT NULL THEN
				LET rm_j14.j14_fecha_emi = fecha
				DISPLAY BY NAME rm_j14.j14_fecha_emi
			END IF
			LET fecha = vg_fecha
		END IF
	AFTER FIELD j14_num_ret_sri
		IF NOT valido_num_ret(rm_j14.j14_num_ret_sri) THEN
			NEXT FIELD j14_num_ret_sri
		END IF
		CALL lee_num_retencion(numero_ret, codigo_pago, posi)
			RETURNING r_j14.*
		IF r_j14.j14_num_ret_sri IS NOT NULL THEN
			IF r_j14.j14_num_ret_sri = rm_j14.j14_num_ret_sri AND
			   (r_j14.j14_num_ret_sri <> numero_ret OR
			    numero_ret IS NULL)
			THEN
				CALL fl_mostrar_mensaje('Este numero de retencion ya ha sido ingresado.', 'exclamation')
				NEXT FIELD j14_num_ret_sri
			END IF
		END IF
	AFTER FIELD j14_autorizacion
		IF LENGTH(rm_j14.j14_autorizacion) <> 10 THEN
			CALL fl_mostrar_mensaje('El numero de la autorizacion ingresado es incorrecto.', 'exclamation')
			NEXT FIELD j14_autorizacion
		END IF
		{-- OJO
		IF rm_j14.j14_autorizacion[1, 1] <> '1' THEN
			CALL fl_mostrar_mensaje('Numero de Autorizacion es incorrecto.', 'exclamation')
			NEXT FIELD j14_autorizacion
		END IF
		--}
		IF NOT fl_valida_numeros(rm_j14.j14_autorizacion) THEN
			NEXT FIELD j14_autorizacion
		END IF
	AFTER FIELD j14_fecha_emi
		IF rm_j14.j14_fecha_emi IS NULL THEN
			LET rm_j14.j14_fecha_emi = fecha
			DISPLAY BY NAME rm_j14.j14_fecha_emi
		END IF
		IF rm_j10.j10_tipo_fuente <> 'SC' THEN
			LET rm_j14.j14_fecha_emi = fecha
			DISPLAY BY NAME rm_j14.j14_fecha_emi
			CONTINUE INPUT
		ELSE
			CALL retorna_fec_emi() RETURNING fecha
			IF fecha IS NOT NULL THEN
				LET rm_j14.j14_fecha_emi = fecha
				DISPLAY BY NAME rm_j14.j14_fecha_emi
				CONTINUE INPUT
			END IF
			LET fecha = vg_fecha
		END IF
		IF rm_j14.j14_fecha_emi < vg_fecha AND
		   rm_j10.j10_tipo_fuente <> 'SC'
		THEN
			CALL fl_mostrar_mensaje('La fecha de emision del comprobante no puede ser menor que la fecha de hoy.', 'exclamation')
			NEXT FIELD j14_fecha_emi
		END IF
		LET fecha_min  = DATE(rm_j10.j10_fecha_pro)
		IF vg_codcia = 1 THEN
			LET dias_tope = 60
		ELSE
			LET dias_tope = 45
		END IF
		--LET fecha_tope = fecha_min + (dias_tope + 1) UNITS DAY
		LET fecha_tope = (MDY(MONTH(fecha_min), 01, YEAR(fecha_min))
				+ 1 UNITS MONTH - 1 UNITS DAY)
				+ (dias_tope + 1) UNITS DAY
		IF rm_j10.j10_tipo_fuente = 'SC' THEN
			LET fecha_min  = DATE(rm_detsol[posi].z20_fecha_emi)
			LET fecha_tope = fecha_min + (dias_tope + 1) UNITS DAY
		END IF
		IF rm_j14.j14_fecha_emi < fecha_min THEN
			LET mensaje = 'La fecha de emision del comprobante no',
					' puede ser menor que la fecha de',
					' factura (',
					fecha_min USING "dd-mm-yyyy", ').'
			CALL fl_mostrar_mensaje(mensaje, 'exclamation')
			NEXT FIELD j14_fecha_emi
		END IF
		IF (MDY(MONTH(fecha_min), 01, YEAR(fecha_min)) + 1 UNITS MONTH
			- 1 UNITS DAY) < (vg_fecha - (dias_tope + 1) UNITS DAY)
		THEN
			LET mensaje = 'No se puede cargar retenciones a una ',
					'factura con fecha de mas de ',
					dias_tope USING "<<&", ' dias.'
			CALL fl_mostrar_mensaje(mensaje, 'exclamation')
			NEXT FIELD j14_fecha_emi
		END IF
		IF rm_j14.j14_fecha_emi > fecha_tope THEN
			LET fecha_tope = fecha_tope - (dias_tope + 1) UNITS DAY
			LET mensaje = 'La fecha de emision del comprobante no',
					' puede ser mayor a ',
					dias_tope + 1 USING "<<&",
					' dias que la ',
					'fecha de factura (',
					fecha_tope USING "dd-mm-yyyy", ').'
			CALL fl_mostrar_mensaje(mensaje, 'exclamation')
			NEXT FIELD j14_fecha_emi
		END IF
END INPUT

END FUNCTION



FUNCTION lee_detalle_ret(codigo_pago, posi)
DEFINE codigo_pago	LIKE cajt001.j01_codigo_pago
DEFINE posi		SMALLINT
DEFINE r_z09		RECORD LIKE cxct009.*
DEFINE r_c02		RECORD LIKE ordt002.*
DEFINE r_c03		RECORD LIKE ordt003.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE cont_cred	LIKE cajt014.j14_cont_cred
DEFINE base_imp		LIKE cajt014.j14_base_imp
DEFINE valor_bruto	DECIMAL(14,2)
DEFINE valor_impto	DECIMAL(14,2)
DEFINE subtotal		DECIMAL(14,2)
DEFINE flete		DECIMAL(14,2)
DEFINE valor_fact	DECIMAL(14,2)
DEFINE resp		CHAR(6)
DEFINE i, j, l, k	SMALLINT
DEFINE salir, flag_c	SMALLINT
DEFINE max_row, resul	SMALLINT

IF vm_num_ret > 0 THEN
	CALL calcular_tot_retencion(vm_num_ret)
ELSE
	LET vm_num_ret = 1
END IF
LET cont_cred = 'R'
IF rm_j10.j10_tipo_fuente = 'PR' OR rm_j10.j10_tipo_fuente = 'OT' THEN
	LET cont_cred = 'C'
END IF
LET salir    = 0
LET int_flag = 0
CALL set_count(vm_num_ret)
INPUT ARRAY rm_detret WITHOUT DEFAULTS FROM rm_detret.*
	ON KEY(INTERRUPT)
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
       	ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(j14_porc_ret) THEN
			CALL fl_ayuda_retenciones(vg_codcia, codigo_pago, 'A')
				RETURNING r_c02.c02_tipo_ret,
					  r_c02.c02_porcentaje, r_c02.c02_nombre
			IF r_c02.c02_tipo_ret IS NOT NULL THEN
				LET rm_detret[i].j14_tipo_ret =
							r_c02.c02_tipo_ret
				LET rm_detret[i].j14_porc_ret =
							r_c02.c02_porcentaje
				IF rm_detret[i].j14_codigo_sri IS NULL THEN
					CALL codigo_sri_defecto(vg_codcia,
							rm_j10.j10_codcli,
						rm_detret[i].j14_tipo_ret,
						rm_detret[i].j14_porc_ret)
					RETURNING rm_detret[i].j14_codigo_sri,
							fec_ini_por[i]
				END IF
				CALL fl_lee_codigos_sri(vg_codcia,
						rm_detret[i].j14_tipo_ret,
						rm_detret[i].j14_porc_ret,
						rm_detret[i].j14_codigo_sri,
						fec_ini_por[i])
					RETURNING r_c03.*
				LET rm_detret[i].c03_concepto_ret =
							r_c03.c03_concepto_ret
				DISPLAY rm_detret[i].* TO rm_detret[j].*
			END IF
		END IF
		IF INFIELD(j14_codigo_sri) THEN
			CALL fl_ayuda_codigos_sri(vg_codcia,
					rm_detret[i].j14_tipo_ret,
					rm_detret[i].j14_porc_ret, 'A',
					rm_j10.j10_codcli, 'C')
				RETURNING r_c03.c03_codigo_sri,
					  r_c03.c03_concepto_ret,
					  r_c03.c03_fecha_ini_porc
			IF r_c03.c03_codigo_sri IS NOT NULL THEN
				LET rm_detret[i].j14_codigo_sri =
							r_c03.c03_codigo_sri
				LET rm_detret[i].c03_concepto_ret =
							r_c03.c03_concepto_ret
				LET fec_ini_por[i] = r_c03.c03_fecha_ini_porc
				DISPLAY rm_detret[i].* TO rm_detret[j].*
			END IF
		END IF
		LET int_flag = 0
	ON KEY(F5)
		LET int_flag = 0
		EXIT INPUT
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
		--#CALL dialog.keysetlabel("F5","Cabecera")
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
		LET max_row = arr_count()
		IF i > max_row THEN
			LET max_row = max_row + 1
		END IF
		CALL muestra_contadores_det(i, max_row)
		CALL calcular_tot_retencion(max_row)
	BEFORE FIELD j14_base_imp
		LET base_imp = rm_detret[i].j14_base_imp
	AFTER FIELD j14_porc_ret
		SELECT UNIQUE j91_tipo_ret
			INTO rm_detret[i].j14_tipo_ret
			FROM cajt091
			WHERE j91_compania    = vg_codcia
			  AND j91_codigo_pago = codigo_pago
			  AND j91_cont_cred   = cont_cred
		IF rm_detret[i].j14_porc_ret IS NOT NULL THEN
			CALL fl_lee_tipo_retencion(vg_codcia,
						rm_detret[i].j14_tipo_ret,
						rm_detret[i].j14_porc_ret)
				RETURNING r_c02.*
			IF r_c02.c02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe configurado este porcentaje de retencion.', 'exclamation')
				NEXT FIELD j14_porc_ret
			END IF
			IF r_c02.c02_estado <> 'A' THEN
				CALL fl_mostrar_mensaje('El porcentaje de retencion esta bloqueado.', 'exclamation')
				NEXT FIELD j14_porc_ret
			END IF
			IF rm_detret[i].j14_codigo_sri IS NULL THEN
				CALL codigo_sri_defecto(vg_codcia,
						rm_j10.j10_codcli,
						rm_detret[i].j14_tipo_ret,
						rm_detret[i].j14_porc_ret)
					RETURNING rm_detret[i].j14_codigo_sri,
							fec_ini_por[i]
			END IF
			CALL fl_lee_codigos_sri(vg_codcia,
						rm_detret[i].j14_tipo_ret,
						rm_detret[i].j14_porc_ret,
						rm_detret[i].j14_codigo_sri,
						fec_ini_por[i])
				RETURNING r_c03.*
			LET rm_detret[i].c03_concepto_ret =
							r_c03.c03_concepto_ret
			DISPLAY rm_detret[i].* TO rm_detret[j].*
		ELSE
			LET rm_detret[i].j14_tipo_ret = NULL
		END IF
		DISPLAY rm_detret[i].j14_tipo_ret TO rm_detret[j].j14_tipo_ret
	AFTER FIELD j14_codigo_sri
		IF rm_detret[i].j14_codigo_sri IS NOT NULL THEN
			CALL fl_lee_codigos_sri(vg_codcia,
						rm_detret[i].j14_tipo_ret,
						rm_detret[i].j14_porc_ret,
						rm_detret[i].j14_codigo_sri,
						fec_ini_por[i])
				RETURNING r_c03.*
			IF r_c03.c03_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe configurado este codigo del SRI.', 'exclamation')
				NEXT FIELD j14_codigo_sri
			END IF
			IF r_c03.c03_estado <> 'A' THEN
				CALL fl_mostrar_mensaje('El codigo del SRI esta bloqueado.', 'exclamation')
				NEXT FIELD j14_codigo_sri
			END IF
			LET rm_detret[i].c03_concepto_ret =
							r_c03.c03_concepto_ret
			IF NOT tiene_aux_cont_retencion(codigo_pago,cont_cred,0)
			THEN
				CALL fl_lee_det_retencion_cli(vg_codcia,
						rm_j10.j10_codcli,
						rm_detret[i].j14_tipo_ret,
						rm_detret[i].j14_porc_ret,
						rm_detret[i].j14_codigo_sri,
						fec_ini_por[i], codigo_pago,
						cont_cred)
					RETURNING r_z09.*
				IF r_z09.z09_aux_cont IS NULL THEN
					CALL fl_mostrar_mensaje('No existe auxiliar contable para este codigo de SRI en este tipo de retencion.', 'exclamation')
					NEXT FIELD j14_codigo_sri
				END IF
			END IF
		ELSE
			LET rm_detret[i].c03_concepto_ret = NULL
		END IF
		DISPLAY rm_detret[i].c03_concepto_ret TO
			rm_detret[j].c03_concepto_ret
		LET flag_c = 0
		IF rm_detret[i].j14_base_imp <> base_imp THEN
			LET flag_c = 1
		END IF
		CALL calcular_retencion(i, j, flag_c)
		CALL calcular_tot_retencion(max_row)
	AFTER FIELD j14_base_imp
		LET flag_c = 0
		IF rm_detret[i].j14_base_imp <> base_imp THEN
			LET flag_c = 1
		END IF
		CALL calcular_retencion(i, j, flag_c)
		CALL calcular_tot_retencion(max_row)
	AFTER FIELD j14_valor_ret
		CALL calcular_retencion(i, j, 0)
		CALL calcular_tot_retencion(max_row)
	AFTER DELETE
		LET max_row = max_row - 1
		IF max_row <= 0 THEN
			LET max_row = 1
		END IF
		CALL calcular_tot_retencion(max_row)
	AFTER INPUT
		LET vm_num_ret = arr_count()
		CALL calcular_tot_retencion(vm_num_ret)
		FOR l = 1 TO vm_num_ret - 1
			FOR k = l + 1 TO vm_num_ret
				IF (rm_detret[l].j14_tipo_ret =
				    rm_detret[k].j14_tipo_ret) AND
				   (rm_detret[l].j14_porc_ret =
				    rm_detret[k].j14_porc_ret) AND
				   (rm_detret[l].j14_codigo_sri =
				    rm_detret[k].j14_codigo_sri) AND
				   (fec_ini_por[l] = fec_ini_por[k])
				THEN
					CALL fl_mostrar_mensaje('Existen un mismo tipo de porcentaje y codigo del SRI mas de una vez en el detalle.', 'exclamation')
					CONTINUE INPUT
				END IF
			END FOR
		END FOR
		IF rm_j10.j10_tipo_fuente = 'SC' THEN
			CASE rm_adi[posi].z24_areaneg
				WHEN 1
					CALL fl_lee_cabecera_transaccion_rep(
						vg_codcia, vg_codloc,
						rm_adi[posi].z20_cod_tran,
						rm_adi[posi].z20_num_doc)
						RETURNING r_r19.*
					IF r_r19.r19_compania IS NULL THEN
					CALL lee_cabecera_transaccion_loc(
						vg_codcia, vg_codloc,
						rm_adi[posi].z20_cod_tran,
						rm_adi[posi].z20_num_doc)
						RETURNING r_r19.*
					END IF
					LET valor_bruto = r_r19.r19_tot_bruto -
							r_r19.r19_tot_dscto
					LET valor_impto = r_r19.r19_tot_neto -
							r_r19.r19_tot_bruto +
							r_r19.r19_tot_dscto -
							r_r19.r19_flete
					LET subtotal    = valor_bruto +
								valor_impto
					LET flete       = r_r19.r19_flete
					LET valor_fact  = subtotal + flete
				WHEN 2
					CALL fl_lee_factura_taller(vg_codcia,
						vg_codloc,
						rm_adi[posi].z20_num_doc)
						RETURNING r_t23.*
					LET valor_bruto = r_t23.t23_tot_bruto -
							--r_t23.t23_tot_dscto
							r_t23.t23_vde_mo_tal
					LET valor_impto = r_t23.t23_val_impto
					LET subtotal    = valor_bruto +
								valor_impto
					LET flete       = NULL
					LET valor_fact  = subtotal
			END CASE
			LET valor_fact = valor_fact - valor_impto
			IF tot_base_imp > valor_fact THEN
				CALL fl_mostrar_mensaje('El total de la base imponible no puede ser mayor que el valor de la factura.', 'exclamation')
				CONTINUE INPUT
			END IF
		ELSE
			IF tot_base_imp > rm_j10.j10_valor THEN
				CALL fl_mostrar_mensaje('El total de la base imponible no puede ser mayor que el valor de la factura.', 'exclamation')
				CONTINUE INPUT
			END IF
		END IF
		LET resul = 0
		FOR l = 1 TO vm_num_ret
			IF rm_detret[l].j14_codigo_sri IS NULL THEN
				LET resul = 1
				EXIT FOR
			END IF
		END FOR
		IF resul THEN
			CONTINUE INPUT
		END IF
		FOR l = 1 TO vm_num_ret
			CALL retorna_ret_fac(posi)
				RETURNING rm_adi_r[l].tipo_fuente,
						rm_adi_r[l].cod_tr,
						rm_adi_r[l].num_tr,
						rm_adi_r[l].num_sri
			IF rm_j10.j10_tipo_fuente = 'SC' THEN
				CALL retorna_tipo_doc(posi,
							rm_adi_r[l].tipo_fuente)
					RETURNING rm_adi_r[l].tipo_doc,
						rm_adi_r[l].fec_fact
			ELSE
				LET rm_adi_r[l].tipo_doc = vm_tipo_doc
				LET rm_adi_r[l].fec_fact = vg_fecha
			END IF
		END FOR
		LET salir = 1
END INPUT
RETURN salir

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION valido_num_ret(num_ret_sri)
DEFINE num_ret_sri	LIKE cajt014.j14_num_ret_sri
DEFINE lim		SMALLINT

IF LENGTH(num_ret_sri) < 14 THEN
	CALL fl_mostrar_mensaje('El número del documento ingresado es incorrecto.', 'exclamation')
	RETURN 0
END IF
IF num_ret_sri[4, 4] <> '-' OR num_ret_sri[8, 8] <> '-' THEN
	CALL fl_mostrar_mensaje('Faltan los guiones.', 'exclamation')
	RETURN 0
END IF
IF num_ret_sri[1, 3] = '000' OR num_ret_sri[5, 7] = '000' THEN
	CALL fl_mostrar_mensaje('Los prefijos son incorrectos. No pueden ser 000.', 'exclamation')
	RETURN 0
END IF
IF LENGTH(num_ret_sri[1, 7]) <> 7 THEN
	CALL fl_mostrar_mensaje('Digite correctamente el punto de venta o el punto de emision.', 'exclamation')
	RETURN 0
END IF
{--
LET lim = LENGTH(num_ret_sri)
IF NOT fl_solo_numeros(num_ret_sri[9, lim]) THEN
	CALL fl_mostrar_mensaje('Digite solo numeros para el numero del comprobante.', 'exclamation')
	RETURN 0
END IF
--}
IF NOT fl_valida_numeros(num_ret_sri[1, 3]) THEN
	RETURN 0
END IF
IF NOT fl_valida_numeros(num_ret_sri[5, 7]) THEN
	RETURN 0
END IF
LET lim = LENGTH(num_ret_sri)
IF NOT fl_valida_numeros(num_ret_sri[9, lim]) THEN
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION calcular_retencion(i, j, flag)
DEFINE i, j, flag	SMALLINT

IF rm_detret[i].j14_valor_ret IS NOT NULL AND NOT flag THEN
	RETURN
END IF
IF rm_detret[i].j14_valor_ret > 0 AND NOT flag THEN
	RETURN
END IF
LET rm_detret[i].j14_valor_ret = rm_detret[i].j14_base_imp *
				(rm_detret[i].j14_porc_ret / 100)
DISPLAY rm_detret[i].j14_base_imp  TO rm_detret[i].j14_base_imp
DISPLAY rm_detret[i].j14_valor_ret TO rm_detret[i].j14_valor_ret

END FUNCTION



FUNCTION calcular_tot_retencion(lim)
DEFINE i, lim		SMALLINT

LET tot_base_imp  = 0
LET tot_valor_ret = 0
FOR i = 1 TO lim
	LET tot_base_imp  = tot_base_imp  + rm_detret[i].j14_base_imp
	LET tot_valor_ret = tot_valor_ret + rm_detret[i].j14_valor_ret
END FOR
DISPLAY BY NAME tot_base_imp, tot_valor_ret

END FUNCTION



FUNCTION lee_num_retencion(numero_ret, codigo_pago, posi)
DEFINE numero_ret	LIKE cajt011.j11_num_ch_aut
DEFINE codigo_pago	LIKE cajt001.j01_codigo_pago
DEFINE posi		SMALLINT
DEFINE r_j14		RECORD LIKE cajt014.*

INITIALIZE r_j14.* TO NULL
DECLARE q_j14 CURSOR FOR
	SELECT cajt014.*
		FROM cajt014, cajt010
		WHERE j14_compania     = vg_codcia
		  AND j14_localidad    = vg_codloc
		  AND j14_tipo_fuente IN ("PR", "OT")
		  AND j14_num_ret_sri  = rm_j14.j14_num_ret_sri
		  AND j10_compania     = j14_compania
		  AND j10_localidad    = j14_localidad
		  AND j10_tipo_fuente  = j14_tipo_fuente
		  AND j10_num_fuente   = j14_num_fuente
		  AND j10_codcli       = rm_j10.j10_codcli
OPEN q_j14
FETCH q_j14 INTO r_j14.*
IF STATUS = NOTFOUND THEN
	CALL retorna_num_ret(numero_ret, codigo_pago, posi, 1)
		RETURNING r_j14.j14_num_ret_sri
END IF
CLOSE q_j14
FREE q_j14
RETURN r_j14.*

END FUNCTION



FUNCTION registros_retenciones(numero_ret, codigo_pago, posi)
DEFINE numero_ret	LIKE cajt011.j11_num_ch_aut
DEFINE codigo_pago	LIKE cajt001.j01_codigo_pago
DEFINE posi		SMALLINT
DEFINE tipo_f		LIKE cajt010.j10_tipo_fuente
DEFINE cod_tra		LIKE cajt010.j10_tipo_destino
DEFINE num_tra		LIKE cajt010.j10_num_destino
DEFINE num_s		LIKE rept038.r38_num_sri
DEFINE query		CHAR(500)
DEFINE cuantos		INTEGER

IF numero_ret IS NULL THEN
	RETURN 0
END IF
CALL retorna_ret_fac(posi) RETURNING tipo_f, cod_tra, num_tra, num_s
IF tipo_f = 'SC' THEN
	CALL retorna_num_ret(numero_ret, codigo_pago, posi, 0) RETURNING tipo_f
END IF
LET query = 'SELECT COUNT(*) tot_reg ',
		' FROM tmp_ret ',
		' WHERE cod_pago    = "', codigo_pago, '"',
		'   AND tipo_fuente = "', tipo_f, '"',
		'   AND num_ret_sri = "', numero_ret CLIPPED, '"'
IF posi > 0 THEN
	LET query = query CLIPPED,
			'   AND cod_tr      = "', cod_tra, '"',
			'   AND num_tr      = ', num_tra
END IF
LET query = query CLIPPED, ' INTO TEMP t1'
PREPARE exec_contar FROM query
EXECUTE exec_contar
SELECT tot_reg INTO cuantos FROM t1
DROP TABLE t1
RETURN cuantos

END FUNCTION



FUNCTION tiene_aux_cont_retencion(codigo_pago, cont_cred, flag)
DEFINE codigo_pago	LIKE cajt001.j01_codigo_pago
DEFINE cont_cred	LIKE cajt001.j01_cont_cred
DEFINE flag		SMALLINT
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_b42		RECORD LIKE ctbt042.*
DEFINE r_j01		RECORD LIKE cajt001.*
DEFINE r_j91		RECORD LIKE cajt091.*
DEFINE tipo_ret		LIKE cajt091.j91_tipo_ret
DEFINE porc_ret		LIKE cajt091.j91_porcentaje
DEFINE resul		SMALLINT

INITIALIZE r_b42.* TO NULL
SELECT * INTO r_b42.*
	FROM ctbt042
	WHERE b42_compania    = vg_codcia
	  AND b42_localidad   = vg_codloc
CALL fl_lee_cuenta(r_b42.b42_compania, r_b42.b42_retencion) RETURNING r_b10.*
LET resul = 1
IF vg_codloc = 2 OR vg_codloc = 4 THEN
	RETURN resul
END IF
IF r_b10.b10_compania IS NULL THEN
	SELECT UNIQUE j91_tipo_ret
		INTO tipo_ret
		FROM cajt091
		WHERE j91_compania    = vg_codcia
		  AND j91_codigo_pago = codigo_pago
		  AND j91_cont_cred   = cont_cred
	CALL fl_lee_det_tipo_ret_caja(vg_codcia, codigo_pago, cont_cred,
					tipo_ret, porc_ret)
		RETURNING r_j91.*
	IF r_j91.j91_aux_cont IS NULL THEN
		CALL fl_lee_tipo_pago_caja(vg_codcia, codigo_pago,
						cont_cred)
			RETURNING r_j01.*
		IF r_j01.j01_aux_cont IS NULL THEN
			LET resul = 0
		END IF
	END IF
END IF
IF NOT resul AND flag THEN
	CALL fl_mostrar_mensaje('No existen auxiliares contables para este tipo de forma de pago. LLAME AL ADMINISTRADOR.', 'exclamation')
END IF
RETURN resul

END FUNCTION



FUNCTION codigo_sri_defecto(codcia, codcli, tipo_ret, porc_ret)
DEFINE codcia		LIKE cxct008.z08_compania
DEFINE codcli		LIKE cxct008.z08_codcli
DEFINE tipo_ret		LIKE cxct008.z08_tipo_ret
DEFINE porc_ret		LIKE cxct008.z08_porcentaje
DEFINE cod_sri		LIKE cxct008.z08_codigo_sri
DEFINE fec_ini		LIKE ordt003.c03_fecha_ini_porc
DEFINE query		CHAR(1200)

INITIALIZE cod_sri, fec_ini TO NULL
LET query = 'SELECT c03_codigo_sri, c03_fecha_ini_porc, ',
		' CASE WHEN z08_codcli IS NULL ',
			' THEN "S" ',
			' ELSE "N" ',
		' END defecto ',
		' FROM ordt003, OUTER cxct008 ',
		' WHERE c03_compania       = ', codcia,
		'   AND c03_tipo_ret       = "', tipo_ret, '"',
		'   AND c03_porcentaje     = ', porc_ret,
		'   AND c03_estado         = "A"',
		'   AND z08_compania       = c03_compania ',
		'   AND z08_codcli         = ', codcli,
		'   AND z08_tipo_ret       = c03_tipo_ret ',
		'   AND z08_porcentaje     = c03_porcentaje ',
		'   AND z08_codigo_sri     = c03_codigo_sri ',
		'   AND z08_fecha_ini_porc = c03_fecha_ini_porc ',
		'   AND c03_fecha_fin_porc IS NULL ',
		' INTO TEMP t1 '
PREPARE exec_t1 FROM query
EXECUTE exec_t1
DECLARE q_sri2 CURSOR FOR
	SELECT c03_codigo_sri, c03_fecha_ini_porc
		FROM t1 WHERE defecto = "S"
OPEN q_sri2
FETCH q_sri2 INTO cod_sri, fec_ini
CLOSE q_sri2
FREE q_sri2
DROP TABLE t1
RETURN cod_sri, fec_ini

END FUNCTION



FUNCTION retorna_ret_fac(posi)
DEFINE posi		SMALLINT
DEFINE tipo_f		LIKE cajt010.j10_tipo_fuente
DEFINE cod_tr		LIKE cajt010.j10_tipo_destino
DEFINE num_tr		LIKE cajt010.j10_num_destino
DEFINE num_s		LIKE rept038.r38_num_sri

LET tipo_f = rm_j10.j10_tipo_fuente
LET cod_tr = rm_j10.j10_tipo_destino
LET num_tr = rm_j10.j10_num_destino
LET num_s  = rm_r38.r38_num_sri
IF posi > 0 THEN
	CASE rm_adi[posi].z24_areaneg
		WHEN 1 LET tipo_f = 'PR'
		WHEN 2 LET tipo_f = 'OT'
	END CASE
	LET cod_tr = rm_adi[posi].z20_cod_tran
	LET num_tr = rm_adi[posi].z20_num_doc
	LET num_s  = rm_detsol[posi].num_sri
END IF
RETURN tipo_f, cod_tr, num_tr, num_s

END FUNCTION



FUNCTION retorna_num_fue(posi)
DEFINE posi		SMALLINT
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r23		RECORD LIKE rept023.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE num_f		LIKE cajt010.j10_num_fuente

LET num_f = rm_j10.j10_num_fuente
IF posi > 0 THEN
	CASE rm_adi[posi].z24_areaneg
		WHEN 1
			CALL fl_lee_cabecera_transaccion_rep(vg_codcia,
					vg_codloc, rm_adi[posi].z20_cod_tran,
					rm_adi[posi].z20_num_doc)
				RETURNING r_r19.*
			IF r_r19.r19_compania IS NULL THEN
				CALL lee_cabecera_transaccion_loc(vg_codcia,
						vg_codloc,
						rm_adi[posi].z20_cod_tran,
						rm_adi[posi].z20_num_doc)
					RETURNING r_r19.*
			END IF
			CALL lee_cabecera_preventa_loc(r_r19.r19_compania,
					r_r19.r19_localidad, r_r19.r19_cod_tran,
					r_r19.r19_num_tran)
				RETURNING r_r23.*
			LET num_f = r_r23.r23_numprev
		WHEN 2
			CALL fl_lee_factura_taller(vg_codcia, vg_codloc,
					rm_adi[posi].z20_num_doc)
				RETURNING r_t23.*
			LET num_f = r_t23.t23_orden
	END CASE
END IF
RETURN num_f

END FUNCTION



FUNCTION retorna_num_ret(numero_ret, codigo_pago, posi, flag)
DEFINE numero_ret	LIKE cajt014.j14_num_ret_sri
DEFINE codigo_pago	LIKE cajt001.j01_codigo_pago
DEFINE posi, flag	SMALLINT
DEFINE tipo_f		LIKE cajt010.j10_tipo_fuente
DEFINE cod_tra		LIKE cajt010.j10_tipo_destino
DEFINE num_tra		LIKE cajt010.j10_num_destino
DEFINE num_s		LIKE rept038.r38_num_sri
DEFINE num_ret		LIKE cajt014.j14_num_ret_sri
DEFINE query		CHAR(600)
DEFINE expr_sql		VARCHAR(200)
DEFINE campo		VARCHAR(12)

LET num_ret = NULL
CALL retorna_ret_fac(posi) RETURNING tipo_f, cod_tra, num_tra, num_s
LET expr_sql = NULL
IF numero_ret IS NOT NULL THEN
	LET expr_sql = '   AND num_ret_sri = "', numero_ret CLIPPED, '"'
END IF
LET campo = 'tipo_fuente'
IF flag THEN
	LET campo    = 'num_ret_sri'
	LET expr_sql = '   AND tipo_fuente = "', tipo_f, '"',
			expr_sql CLIPPED
END IF
LET query = 'SELECT UNIQUE ', campo CLIPPED,
		' FROM tmp_ret ',
		' WHERE cod_pago    = "', codigo_pago, '"',
		expr_sql CLIPPED
IF posi > 0 THEN
	LET query = query CLIPPED,
			'   AND cod_tr      = "', cod_tra, '"',
			'   AND num_tr      = ', num_tra
END IF
LET query = query CLIPPED, ' INTO TEMP t1'
PREPARE exec_ret FROM query
EXECUTE exec_ret
SELECT * INTO num_ret FROM t1
DROP TABLE t1
RETURN num_ret CLIPPED

END FUNCTION



FUNCTION borrar_retencion(numero_ret, codigo_pago, posi)
DEFINE numero_ret	LIKE cajt011.j11_num_ch_aut
DEFINE codigo_pago	LIKE cajt001.j01_codigo_pago
DEFINE posi		SMALLINT
DEFINE tipo_f		LIKE cajt010.j10_tipo_fuente
DEFINE cod_tra		LIKE cajt010.j10_tipo_destino
DEFINE num_tra		LIKE cajt010.j10_num_destino
DEFINE num_s		LIKE rept038.r38_num_sri
DEFINE query		CHAR(500)

IF numero_ret IS NULL THEN
	RETURN
END IF
CALL retorna_ret_fac(posi) RETURNING tipo_f, cod_tra, num_tra, num_s
IF tipo_f = 'SC' THEN
	CALL retorna_num_ret(numero_ret, codigo_pago, posi, 0) RETURNING tipo_f
END IF
LET query = 'DELETE FROM tmp_ret ',
		' WHERE cod_pago    = "', codigo_pago, '"',
		'   AND tipo_fuente = "', tipo_f, '"',
		'   AND num_ret_sri = "', numero_ret CLIPPED,'"'
IF posi > 0 THEN
	LET query = query CLIPPED,
			'   AND cod_tr      = "', cod_tra, '"',
			'   AND num_tr      = ', num_tra
END IF
PREPARE exec_del_ret FROM query
EXECUTE exec_del_ret

END FUNCTION



FUNCTION lee_cabecera_transaccion_loc(codcia, codloc, cod_tran, num_tran)
DEFINE codcia		LIKE rept019.r19_compania
DEFINE codloc		LIKE rept019.r19_localidad
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE query		CHAR(400)

INITIALIZE r_r19.* TO NULL
IF NOT (codloc = 2 OR codloc = 4) THEN
	RETURN r_r19.*
END IF
LET query = 'SELECT * FROM ', retorna_base_loc() CLIPPED, 'rept019 ',
		' WHERE r19_compania  = ', codcia,
		'   AND r19_localidad = ', codloc,
		'   AND r19_cod_tran  = "', cod_tran, '"',
		'   AND r19_num_tran  = ', num_tran
PREPARE cons_f_loc FROM query
DECLARE q_cons_f_loc CURSOR FOR cons_f_loc
OPEN q_cons_f_loc
FETCH q_cons_f_loc INTO r_r19.*
CLOSE q_cons_f_loc
FREE q_cons_f_loc
RETURN r_r19.*

END FUNCTION



FUNCTION lee_cabecera_preventa_loc(codcia, codloc, cod_tran, num_tran)
DEFINE codcia		LIKE rept023.r23_compania
DEFINE codloc		LIKE rept023.r23_localidad
DEFINE cod_tran		LIKE rept023.r23_cod_tran
DEFINE num_tran		LIKE rept023.r23_num_tran
DEFINE r_r23		RECORD LIKE rept023.*
DEFINE query		CHAR(400)

INITIALIZE r_r23.* TO NULL
IF NOT (codloc = 2 OR codloc = 4) THEN
	SELECT * INTO r_r23.*
		FROM rept023
		WHERE r23_compania  = codcia
		  AND r23_localidad = codloc
		  AND r23_cod_tran  = cod_tran
		  AND r23_num_tran  = num_tran
	RETURN r_r23.*
END IF
LET query = 'SELECT * FROM ', retorna_base_loc() CLIPPED, 'rept023 ',
		' WHERE r23_compania  = ', codcia,
		'   AND r23_localidad = ', codloc,
		'   AND r23_cod_tran  = "', cod_tran, '"',
		'   AND r23_num_tran  = ', num_tran
PREPARE cons_p_loc FROM query
DECLARE q_cons_p_loc CURSOR FOR cons_p_loc
OPEN q_cons_p_loc
FETCH q_cons_p_loc INTO r_r23.*
CLOSE q_cons_p_loc
FREE q_cons_p_loc
RETURN r_r23.*

END FUNCTION



FUNCTION retorna_base_loc()
DEFINE base_loc		VARCHAR(10)

LET base_loc = NULL
IF NOT (vg_codloc = 2 OR vg_codloc = 4) THEN
	RETURN base_loc CLIPPED
END IF
SELECT g56_base_datos INTO base_loc
	FROM gent056
	WHERE g56_compania  = vg_codcia
	  AND g56_localidad = vg_codloc
IF base_loc IS NOT NULL THEN
	LET base_loc = base_loc CLIPPED, ':'
END IF
RETURN base_loc CLIPPED

END FUNCTION



FUNCTION retorna_tipo_doc(posi, tipo_f)
DEFINE posi		SMALLINT
DEFINE tipo_f		LIKE cajt010.j10_tipo_fuente
DEFINE tip_d		LIKE rept038.r38_tipo_doc
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE fec_f		DATE
DEFINE query		CHAR(1000)

LET query = 'SELECT r38_tipo_doc '
IF (vg_codloc = 2 OR vg_codloc = 4) THEN
	LET query = query CLIPPED,
		' FROM ', retorna_base_loc() CLIPPED, 'rept038'
ELSE
	LET query = query CLIPPED, ' FROM rept038'
END IF
LET query = query CLIPPED,
		' WHERE r38_compania    = ', vg_codcia,
		'   AND r38_localidad   = ', vg_codloc,
		'   AND r38_tipo_fuente = "', tipo_f, '"',
		'   AND r38_cod_tran    = "', rm_adi[posi].z20_cod_tran, '"',
		'   AND r38_num_tran    = ', rm_adi[posi].z20_num_doc
LET tip_d = NULL
PREPARE cons_r38_2 FROM query
DECLARE q_cons_r38_2 CURSOR FOR cons_r38_2
OPEN q_cons_r38_2
FETCH q_cons_r38_2 INTO tip_d
CLOSE q_cons_r38_2
FREE q_cons_r38_2
LET fec_f = vg_fecha
CASE tipo_f
	WHEN 'PR'
		CALL fl_lee_cabecera_transaccion_rep(vg_codcia,	vg_codloc,
						rm_adi[posi].z20_cod_tran,
						rm_adi[posi].z20_num_doc)
			RETURNING r_r19.*
		IF r_r19.r19_compania IS NULL THEN
			CALL lee_cabecera_transaccion_loc(vg_codcia, vg_codloc,
						rm_adi[posi].z20_cod_tran,
						rm_adi[posi].z20_num_doc)
				RETURNING r_r19.*
		END IF
		LET fec_f = DATE(r_r19.r19_fecing)
	WHEN 'OT'
		CALL fl_lee_factura_taller(vg_codcia, vg_codloc,
						rm_adi[posi].z20_num_doc)
			RETURNING r_t23.*
		LET fec_f = DATE(r_t23.t23_fec_factura)
END CASE
RETURN tip_d, fec_f

END FUNCTION



FUNCTION retorna_fec_emi()
DEFINE fecha		DATE

LET fecha = NULL
DECLARE q_fec CURSOR FOR
	SELECT fecha_emi
		FROM tmp_ret
		WHERE num_ret_sri = rm_j14.j14_num_ret_sri
OPEN q_fec
FETCH q_fec INTO fecha
CLOSE q_fec
FREE q_fec
RETURN fecha

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

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF

-- 1: grabar detalles
IF rm_j10.j10_valor > 0 THEN
	CALL graba_detalle()
	CALL actualiza_acumulados_caja('I')
	IF rm_j10.j10_tipo_fuente = 'SC' THEN
		CALL actualiza_cheques_postfechados('C')
	END IF

END IF

-- 2: actualizar el estado de la cabecera a '*' y el codigo de caja

LET done = actualiza_cabecera('*')
IF NOT done THEN
	DELETE FROM tmp_ret
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
		LET run_prog = 'fglrun '
		IF vg_gui = 0 THEN
			LET run_prog = 'fglgo '
		END IF
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
				WHERE g37_compania   = vg_codcia
				  AND g37_localidad  = vg_codloc
				  AND g37_tipo_doc   = vm_tipo_doc
		  		  AND g37_cont_cred  = cont_cred
				{--
			  	  AND g37_fecha_emi <= DATE(TODAY)
			  	  AND g37_fecha_exp >= DATE(TODAY)
				--}
				  AND g37_secuencia IN
					(SELECT MAX(g37_secuencia)
					FROM gent037
					WHERE g37_compania  = vg_codcia
					  AND g37_localidad = vg_codloc
					  AND g37_tipo_doc  = vm_tipo_doc)
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
			VALUES (vg_codcia, vg_codloc, r_g37.g37_tipo_doc,
				rm_j10.j10_tipo_fuente, rm_j10.j10_tipo_destino,
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
	CALL actualiza_detalle_retencion(1)
	DELETE FROM tmp_ret
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
	CALL fl_mostrar_mensaje('Proceso no pudo Terminar Correctamente.','stop')

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
DEFINE fecha_actual DATETIME YEAR TO SECOND

LET intentar = 1
LET done = 0
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

IF NOT intentar AND NOT done THEN
	RETURN done
END IF

LET fecha_actual = fl_current()

UPDATE cajt010 SET j10_estado      = estado,
				   j10_codigo_caja = rm_j04.j04_codigo_caja,
				   j10_fecha_pro   = fecha_actual
 WHERE CURRENT OF q_j10 

CLOSE q_j10

RETURN done

END FUNCTION



FUNCTION elimina_detalle()
DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT

CALL actualiza_detalle_retencion(0)
DELETE FROM tmp_ret
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
DEFINE r_j11		RECORD LIKE cajt011.*
DEFINE total		LIKE cajt011.j11_valor
DEFINE vuelto		LIKE cajt011.j11_valor
DEFINE valor		LIKE cajt011.j11_valor
DEFINE paridad		LIKE cajt011.j11_paridad
DEFINE i, secuencia 	SMALLINT

LET total = calcula_total(vm_indice)
IF total > rm_j10.j10_valor THEN
	LET vuelto = total - rm_j10.j10_valor
END IF
DELETE FROM cajt011
	WHERE j11_compania    = vg_codcia
	  AND j11_localidad   = vg_codloc
	  AND j11_tipo_fuente = rm_j10.j10_tipo_fuente
	  AND j11_num_fuente  = rm_j10.j10_num_fuente
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
	CALL grabar_detalle_retencion(r_j11.j11_secuencia, rm_j11[i].forma_pago,
					rm_j11[i].num_ch_aut)
END FOR 

END FUNCTION



FUNCTION grabar_detalle_retencion(secuencia, codigo_pago, num_ret)
DEFINE secuencia	LIKE cajt011.j11_secuencia
DEFINE codigo_pago	LIKE cajt001.j01_codigo_pago
DEFINE num_ret		LIKE cajt011.j11_num_ch_aut
DEFINE num_s		LIKE rept038.r38_num_sri
DEFINE r_j14		RECORD LIKE cajt014.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE i		SMALLINT
DEFINE fec_f		DATE

IF (registros_retenciones(num_ret, codigo_pago, 0) = 0) AND
   (rm_j10.j10_tipo_fuente <> 'SC')
THEN
	RETURN
END IF
DECLARE q_ret2 CURSOR FOR
	SELECT num_ret_sri, autorizacion, fecha_emi, tipo_ret, porc_ret,
		codigo_sri, concepto_ret, base_imp, valor_ret, num_fac_sri,
		fec_fact, fec_ini_porc
		FROM tmp_ret
		WHERE cod_pago    = codigo_pago
		  AND num_ret_sri = num_ret
LET i = 1
FOREACH q_ret2 INTO r_j14.j14_num_ret_sri, r_j14.j14_autorizacion,
			r_j14.j14_fecha_emi, rm_detret[i].*, num_s, fec_f,
			fec_ini_por[i]
	LET r_j14.j14_compania     = vg_codcia
	LET r_j14.j14_localidad    = vg_codloc
	LET r_j14.j14_tipo_fuente  = rm_j10.j10_tipo_fuente
	LET r_j14.j14_num_fuente   = rm_j10.j10_num_fuente
	LET r_j14.j14_secuencia    = secuencia
	LET r_j14.j14_codigo_pago  = codigo_pago
	LET r_j14.j14_sec_ret      = i
	CALL fl_lee_cliente_general(rm_j10.j10_codcli) RETURNING r_z01.*
	LET r_j14.j14_cedruc       = r_z01.z01_num_doc_id
	LET r_j14.j14_razon_social = rm_j10.j10_nomcli
	LET r_j14.j14_num_fact_sri = num_s
	LET r_j14.j14_fec_emi_fact = fec_f
	LET r_j14.j14_tipo_ret     = rm_detret[i].j14_tipo_ret
	LET r_j14.j14_porc_ret     = rm_detret[i].j14_porc_ret
	LET r_j14.j14_codigo_sri   = rm_detret[i].j14_codigo_sri
	LET r_j14.j14_fec_ini_porc = fec_ini_por[i]
	LET r_j14.j14_base_imp     = rm_detret[i].j14_base_imp
	LET r_j14.j14_valor_ret    = rm_detret[i].j14_valor_ret
	IF rm_j10.j10_tipo_fuente = 'PR' OR rm_j10.j10_tipo_fuente = 'OT' THEN
		LET r_j14.j14_cont_cred = 'C'
	ELSE
		LET r_j14.j14_cont_cred = 'R'
	END IF
	LET r_j14.j14_tipo_comp    = NULL
	LET r_j14.j14_num_comp     = NULL
	LET r_j14.j14_usuario      = vg_usuario
	LET r_j14.j14_fecing       = fl_current()
	INSERT INTO cajt014 VALUES (r_j14.*)
	LET i = i + 1
END FOREACH

END FUNCTION



FUNCTION actualiza_detalle_retencion(flag)
DEFINE flag		SMALLINT
DEFINE r_j14		RECORD LIKE cajt014.*
DEFINE expr_sql		CHAR(1500)
DEFINE expr_con		CHAR(400)
DEFINE query		CHAR(3500)

IF NOT flag THEN
	DELETE FROM cajt014
		WHERE j14_compania    = vg_codcia
		  AND j14_localidad   = vg_codloc
		  AND j14_tipo_fuente = rm_j10.j10_tipo_fuente
		  AND j14_num_fuente  = rm_j10.j10_num_fuente
	RETURN
END IF
INITIALIZE r_j14.* TO NULL
IF rm_j10.j10_tipo_fuente = 'PR' THEN
	SELECT r40_tipo_comp, r40_num_comp
		INTO r_j14.j14_tipo_comp, r_j14.j14_num_comp
		FROM rept040, ctbt012
		WHERE r40_compania  = vg_codcia
		  AND r40_localidad = vg_codloc
		  AND r40_cod_tran  = rm_j10.j10_tipo_destino
		  AND r40_num_tran  = rm_j10.j10_num_destino
		  AND b12_compania  = r40_compania
		  AND b12_tipo_comp = r40_tipo_comp
		  AND b12_num_comp  = r40_num_comp
		  AND b12_subtipo   = 8
END IF
IF rm_j10.j10_tipo_fuente = 'OT' THEN
	SELECT t50_tipo_comp, t50_num_comp
		INTO r_j14.j14_tipo_comp, r_j14.j14_num_comp
		FROM talt050, ctbt012
		WHERE t50_compania  = vg_codcia
		  AND t50_localidad = vg_codloc
		  AND t50_orden     = rm_j10.j10_num_fuente
		  AND t50_factura   = rm_j10.j10_num_destino
		  AND b12_compania  = t50_compania
		  AND b12_tipo_comp = t50_tipo_comp
		  AND b12_num_comp  = t50_num_comp
		  AND b12_subtipo   = 41
END IF
IF rm_j10.j10_tipo_fuente = 'SC' THEN
	SELECT z40_tipo_comp, z40_num_comp
		INTO r_j14.j14_tipo_comp, r_j14.j14_num_comp
		FROM cxct040
		WHERE z40_compania  = vg_codcia
		  AND z40_localidad = vg_codloc
		  AND z40_codcli    = rm_j10.j10_codcli
		  AND z40_tipo_doc  = rm_j10.j10_tipo_destino
		  AND z40_num_doc   = rm_j10.j10_num_destino
END IF
LET expr_sql = 'j14_tipo_doc  = (SELECT UNIQUE tipo_doc FROM tmp_ret ',
				'WHERE num_ret_sri = j14_num_ret_sri ',
				'  AND num_fac_sri = j14_num_fact_sri ',
				'  AND tipo_ret    = j14_tipo_ret ',
				'  AND porc_ret    = j14_porc_ret ',
				'  AND codigo_sri  = j14_codigo_sri ',
				'  AND fec_ini_porc = j14_fec_ini_porc), ',
		'j14_tipo_fue  = (SELECT UNIQUE tipo_fuente FROM tmp_ret ',
				'WHERE num_ret_sri = j14_num_ret_sri ',
				'  AND num_fac_sri = j14_num_fact_sri ',
				'  AND tipo_ret    = j14_tipo_ret ',
				'  AND porc_ret    = j14_porc_ret ',
				'  AND codigo_sri  = j14_codigo_sri ',
				'  AND fec_ini_porc = j14_fec_ini_porc), ',
		'j14_cod_tran  = (SELECT UNIQUE cod_tr FROM tmp_ret ',
				'WHERE num_ret_sri = j14_num_ret_sri ',
				'  AND num_fac_sri = j14_num_fact_sri ',
				'  AND tipo_ret    = j14_tipo_ret ',
				'  AND porc_ret    = j14_porc_ret ',
				'  AND codigo_sri  = j14_codigo_sri ',
				'  AND fec_ini_porc = j14_fec_ini_porc), ',
		'j14_num_tran  = (SELECT UNIQUE num_tr FROM tmp_ret ',
				'WHERE num_ret_sri = j14_num_ret_sri ',
				'  AND num_fac_sri = j14_num_fact_sri ',
				'  AND tipo_ret    = j14_tipo_ret ',
				'  AND porc_ret    = j14_porc_ret ',
				'  AND codigo_sri  = j14_codigo_sri ',
				'  AND fec_ini_porc = j14_fec_ini_porc)'
IF rm_j10.j10_tipo_fuente <> 'SC' THEN
	LET expr_sql = 'j14_tipo_doc  = "', vm_tipo_doc, '", ',
			'j14_tipo_fue  = "', rm_j10.j10_tipo_fuente CLIPPED,
					'", ',
			'j14_cod_tran  = "', rm_j10.j10_tipo_destino CLIPPED,
					'", ',
			'j14_num_tran  = "', rm_j10.j10_num_destino CLIPPED,
					'"'
END IF
LET expr_con = NULL
IF r_j14.j14_tipo_comp IS NOT NULL THEN
	LET expr_con = ',     j14_tipo_comp = "', r_j14.j14_tipo_comp CLIPPED,
			'", ',
			'     j14_num_comp  = "', r_j14.j14_num_comp CLIPPED,
			'" '
END IF
LET query = 'UPDATE cajt014 ',
		' SET ', expr_sql CLIPPED,
			expr_con CLIPPED,
		' WHERE j14_compania    = ', vg_codcia,
		'   AND j14_localidad   = ', vg_codloc,
		'   AND j14_tipo_fuente = "', rm_j10.j10_tipo_fuente, '"',
		'   AND j14_num_fuente  = ', rm_j10.j10_num_fuente
PREPARE exec_j14 FROM query
EXECUTE exec_j14

END FUNCTION



FUNCTION mensaje_intentar()

DEFINE intentar		SMALLINT
DEFINE resp		CHAR(6)

LET intentar = 1
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
				  AND j13_fecha        = vg_fecha
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
			LET r_j13.j13_fecha        = vg_fecha
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
--IF rm_j10.j10_tipo_destino = vm_tipo_doc THEN
IF vm_tipo_doc = 'FA' OR vm_tipo_doc = 'NV' THEN
	SELECT r38_num_sri INTO rm_r38.r38_num_sri
		FROM rept038
		WHERE r38_compania    = vg_codcia
	  	  AND r38_localidad   = vg_codloc
		  AND r38_tipo_doc    = vm_tipo_doc
	  	  AND r38_tipo_fuente = rm_j10.j10_tipo_fuente
	  	  AND r38_cod_tran    = rm_j10.j10_tipo_destino
	  	  AND r38_num_tran    = rm_j10.j10_num_destino 
	DISPLAY BY NAME rm_r38.r38_num_sri
END IF
CALL muestra_registro()
CALL muestra_detalle()

END FUNCTION



FUNCTION muestra_detalle()
DEFINE i, j, num	SMALLINT
DEFINE filas_pant	SMALLINT
DEFINE dummy		LIKE cajt011.j11_valor
DEFINE cont_cred	LIKE cajt001.j01_cont_cred

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

LET num = 1
FOREACH q_detalle INTO rm_j11[num].*
	LET num = num + 1
	IF num > vm_max_rows THEN
		EXIT FOREACH
	END IF
END FOREACH

LET num = num - 1

LET cont_cred = 'R'
IF rm_j10.j10_tipo_fuente = 'PR' OR rm_j10.j10_tipo_fuente = 'OT' THEN
	LET cont_cred = 'C'
END IF
CALL setea_botones()
IF num > 0 THEN
	CALL calcula_total(num) RETURNING dummy
	CALL set_count(num)
ELSE
	CALL fl_mostrar_mensaje('No hay detalle de forma de pago.','exclamation')
	EXIT PROGRAM
END IF
DISPLAY ARRAY rm_j11 TO ra_j11.*
	ON KEY(INTERRUPT)
		EXIT DISPLAY
       	ON KEY(F1,CONTROL-W)
		CALL control_visor_teclas_caracter_2() 
	ON KEY(F5)
		CALL ver_documento_origen()
		LET int_flag = 0
	ON KEY(F6)
		LET i = arr_curr()
		LET j = scr_line()
		IF fl_determinar_si_es_retencion(vg_codcia,rm_j11[i].forma_pago,
							cont_cred)
		THEN
			CALL detalle_retenciones(i, j, 'C')
			LET int_flag = 0
		END IF
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
                --#CALL dialog.keysetlabel('ACCEPT', '')
		--#CALL dialog.keysetlabel('RETURN','')
	--#BEFORE ROW
		--#LET i = arr_curr()
		--#IF fl_determinar_si_es_retencion(vg_codcia,
					--#rm_j11[i].forma_pago, cont_cred)
		--#THEN
			--#IF rm_j10.j10_tipo_fuente = 'PR' OR
			   --#rm_j10.j10_tipo_fuente = 'OT' THEN
				--#CALL dialog.keysetlabel("F6","Retenciones")
			--#ELSE
				--#IF rm_j10.j10_tipo_fuente = 'SC' THEN
					--#CALL dialog.keysetlabel("F6","Det. Ret. Fact.")
				--#ELSE
					--#CALL dialog.keysetlabel("F6","")
				--#END IF
			--#END IF
		--#ELSE
			--#CALL dialog.keysetlabel("F6","")
		--#END IF
        --#AFTER DISPLAY
                --#CONTINUE DISPLAY
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
		IF rm_j11[i].forma_pago = vm_cheque THEN
			IF rm_j11[i].cod_bco_tarj = rm_j11[j].cod_bco_tarj AND
			   rm_j11[i].num_ch_aut = rm_j11[j].num_ch_aut
			THEN
				LET resul = 1
				EXIT FOR
			END IF
		END IF
		IF rm_j11[i].forma_pago[1, 1] = 'T' THEN
			IF rm_j11[i].cod_bco_tarj = rm_j11[j].cod_bco_tarj AND
			   rm_j11[i].num_ch_aut = rm_j11[j].num_ch_aut AND
			   rm_j11[i].num_cta_tarj = rm_j11[j].num_cta_tarj
			THEN
				LET resul = 1
				EXIT FOR
			END IF
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
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
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
	-- OJO NO IMPRIMIR
	RUN comando
	--
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
				-- OJO NO IMPRIMIR
				RUN comando
				--
			END FOREACH
		--END IF 
	END IF 
	IF rm_j10.j10_tipo_fuente = 'OT' THEN
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
 			      'TALLER', vg_separador, 'fuentes', 
			      vg_separador, run_prog, 'talp408 ', vg_base, ' ',
			      'TA', ' ', vg_codcia, ' ', vg_codloc, ' ',
			      r_t23.t23_orden
		-- OJO NO IMPRIMIR
		RUN comando
		--
	END IF 
END IF

END FUNCTION



FUNCTION retorna_arreglo()
--#LET vm_size_arr = fgl_scr_size('r_detalle')
IF vg_gui = 0 THEN
        LET vm_size_arr = 5
END IF
                                                                                
END FUNCTION



FUNCTION ver_documento(i)
DEFINE i		SMALLINT
DEFINE comando		CHAR(400)
DEFINE run_prog		CHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
IF rm_adi[i].z20_dividendo > 0 THEN
	LET comando = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS',
		vg_separador, 'fuentes', vg_separador, run_prog, 'cxcp200 ',
		vg_base, ' "CO" ', vg_codcia, ' ', vg_codloc, ' ',
		rm_j10.j10_codcli, ' "', rm_detsol[i].z20_tipo_doc, '" ',
		rm_adi[i].z20_num_doc, ' ', rm_adi[i].z20_dividendo
ELSE
	LET comando = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS',
		vg_separador, 'fuentes', vg_separador, run_prog, 'cxcp201 ',
		vg_base, ' "CO" ', vg_codcia, ' ', vg_codloc, ' ',
		rm_j10.j10_codcli, ' "', rm_detsol[i].z20_tipo_doc, '" ',
		rm_adi[i].z20_num_doc
END IF
RUN comando

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



FUNCTION facturar_sin_stock()
DEFINE r_reg		RECORD
						bodega		LIKE rept011.r11_bodega,
						item		LIKE rept011.r11_item,
						stock		LIKE rept011.r11_stock_act
					END RECORD
DEFINE r_r00		RECORD LIKE rept000.*
DEFINE resul		SMALLINT
DEFINE query		CHAR(800)
DEFINE mensaje		VARCHAR(200)

LET resul = 1
CALL fl_lee_compania_repuestos(vg_codcia) RETURNING r_r00.*
IF r_r00.r00_fact_sin_stock = 'S' THEN
	RETURN resul
END IF
LET query = 'SELECT r24_bodega, r24_item, NVL(SUM(r11_stock_act), 0) stock ',
				'FROM rept024, OUTER rept011 ',
				'WHERE r24_compania  = ', vg_codcia,
				'  AND r24_localidad = ', vg_codloc,
				'  AND r24_numprev   = ', rm_j10.j10_num_fuente,
				'  AND r11_compania  = r24_compania ',
				'  AND r11_bodega    = r24_bodega ',
				'  AND r11_item      = r24_item ',
				'GROUP BY 1, 2 '
PREPARE val_sin_stock FROM query
DECLARE q_val_sin_stock CURSOR FOR val_sin_stock
FOREACH q_val_sin_stock INTO r_reg.*
	IF r_reg.stock > 0 THEN
		CONTINUE FOREACH
	END IF
	LET mensaje = 'El item ', r_reg.item CLIPPED, ' en la bodega ',
					r_reg.bodega CLIPPED, ' no tiene STOCK, por tal motivo no ',
					'puede facturar esta preventa.'
	CALL fl_mostrar_mensaje(mensaje, 'exclamation')
	LET resul = 0
	EXIT FOREACH
END FOREACH
RETURN resul

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
DISPLAY '<F6>      Retención'                AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F7>      Calcular Diferencia'      AT a,2
DISPLAY  'F7' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION control_visor_teclas_caracter_3() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Ver Documento'            AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Ver Factura'              AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F7>      Retención'                AT a,2
DISPLAY  'F7' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
