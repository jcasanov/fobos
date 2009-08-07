------------------------------------------------------------------------------
-- Titulo           : cajp203.4gl - Formas de Pago 
-- Elaboracion      : 30-oct-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun cajp203 base modulo compania localidad 
--		      [tipo_fuente num_fuente]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_tipo_fuente	LIKE cajt010.j10_tipo_fuente
DEFINE vm_num_fuente	LIKE cajt010.j10_num_fuente

DEFINE vm_cheque	CHAR(2)
DEFINE vm_efectivo	CHAR(2)

DEFINE vm_rowid		INTEGER
DEFINE vm_max_rows	SMALLINT
DEFINE vm_indice  	SMALLINT
--
-- DEFINE RECORD(S) HERE
--
DEFINE rm_j02		RECORD LIKE cajt002.*
DEFINE rm_j04		RECORD LIKE cajt004.*
DEFINE rm_j10		RECORD LIKE cajt010.*

DEFINE rm_j11 ARRAY[50] OF RECORD 
	forma_pago		LIKE cajt011.j11_codigo_pago, 
	moneda			LIKE cajt011.j11_moneda, 
	cod_bco_tarj		LIKE cajt011.j11_cod_bco_tarj, 
	num_ch_aut		LIKE cajt011.j11_num_ch_aut, 
	num_cta_tarj		LIKE cajt011.j11_num_cta_tarj,
	valor			LIKE cajt011.j11_valor 
END RECORD



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cajp203.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 6 THEN -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'cajp203'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
LET vg_codloc   = arg_val(4)

LET vm_num_fuente = 0
IF num_args() = 6 THEN
	LET vm_tipo_fuente = arg_val(5)
	LET vm_num_fuente  = arg_val(6)
END IF

CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

DEFINE salir		SMALLINT
DEFINE resp 		CHAR(3)  

CALL fl_nivel_isolation()
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_203 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER, 
		  MESSAGE LINE LAST - 2) 
OPEN FORM f_203 FROM '../forms/cajf203_1'
DISPLAY FORM f_203

LET vm_max_rows = 50

LET vm_cheque   = 'CH'
LET vm_efectivo = 'EF'

IF vm_num_fuente <> 0 THEN
	CALL execute_query()
	EXIT PROGRAM
END IF

CALL fl_retorna_caja(vg_codcia, vg_codloc, vg_usuario) RETURNING rm_j02.*
IF rm_j02.j02_codigo_caja IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'No hay una caja asignada al usuario ' || vg_usuario || '.',
		'stop')
	EXIT PROGRAM
END IF

LET rm_j10.j10_codigo_caja = rm_j02.j02_codigo_caja

LET salir = 0
WHILE NOT salir 
	CLEAR FORM
	LET int_flag = 0
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
		CALL fgl_winmessage(vg_producto,
			'La caja no está aperturada.',
			'exclamation')
		EXIT PROGRAM
	END IF
	
	INITIALIZE rm_j10.*    TO NULL
	INITIALIZE rm_j11[1].* TO NULL
	LET vm_indice = 1
	
	LET rm_j10.j10_codigo_caja = rm_j02.j02_codigo_caja
	
	CALL lee_datos_cabecera()
	IF INT_FLAG THEN
		LET salir = 1  
		CONTINUE WHILE
	END IF
	
	IF rm_j10.j10_valor <= 0 THEN
		CALL fgl_winmessage(vg_producto, 'La factura es a credito, se debe cancelar a traves de una Solicitud de Cobro.', 'exclamation')
		CONTINUE WHILE
	END IF
	CALL ingresa_detalle()
	IF int_flag THEN
		CONTINUE WHILE
	END IF
	
	CALL proceso_master_transacciones_caja()
END WHILE

CLOSE WINDOW w_203

END FUNCTION



FUNCTION lee_datos_cabecera()

DEFINE resp 		CHAR(6)
DEFINE estado 		CHAR(1)

DEFINE tipo_fuente	LIKE cajt010.j10_tipo_fuente

DEFINE r_r23		RECORD LIKE rept023.* 	-- Preventa Repuestos
DEFINE r_v26		RECORD LIKE veht026.* 	-- Preventa Vehiculos
DEFINE r_t23		RECORD LIKE talt023.*	-- Orden de Trabajo
DEFINE r_z24		RECORD LIKE cxct024.*	-- Solicitud Cobro Clientes
DEFINE r_j10		RECORD LIKE cajt010.*

LET rm_j10.j10_tipo_fuente = 'SC'
LET INT_FLAG = 0
INPUT BY NAME rm_j10.j10_tipo_fuente, rm_j10.j10_num_fuente WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(j10_tipo_fuente, j10_num_fuente) THEN
			RETURN
		END IF

		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN
		END IF
	ON KEY(F2)
		IF INFIELD(j10_num_fuente) THEN
			CALL fl_ayuda_numero_fuente_caja(vg_codcia, vg_codloc, 
							 rm_j10.j10_tipo_fuente)
					RETURNING r_j10.j10_num_fuente,
						  r_j10.j10_nomcli,
						  r_j10.j10_valor 
			IF r_j10.j10_num_fuente IS NOT NULL THEN
				LET rm_j10.j10_num_fuente = r_j10.j10_num_fuente
				DISPLAY BY NAME rm_j10.j10_num_fuente
			END IF
		END IF
		LET INT_FLAG = 0
	ON KEY(F5)
		IF INFIELD(j10_tipo_fuente) OR INFIELD(j10_num_fuente) THEN
			LET tipo_fuente = rm_j10.j10_tipo_fuente
			LET rm_j10.j10_tipo_fuente = GET_FLDBUF(j10_tipo_fuente)
			IF tipo_fuente = rm_j10.j10_tipo_fuente THEN
				IF rm_j10.j10_num_fuente IS NOT NULL THEN
					CALL ver_documento_origen()
				END IF
			ELSE
				CALL dialog.keysetlabel('F5', '')
			END IF
		END IF
		LET INT_FLAG = 0
	BEFORE INPUT
		CALL dialog.keysetlabel('F5', '')
	BEFORE FIELD j10_tipo_fuente
		LET tipo_fuente = rm_j10.j10_tipo_fuente
	AFTER FIELD j10_tipo_fuente
		IF (rm_j10.j10_tipo_fuente = 'PV' 
		    OR rm_j10.j10_tipo_fuente = 'PR')
		AND rm_j02.j02_pre_ventas = 'N'
		THEN
			CALL fgl_winmessage(vg_producto,
				'No se pueden cancelar facturas de ventas en ' ||
				'esta caja.',
				'exclamation')
			NEXT FIELD j10_tipo_fuente
		END IF
		IF rm_j10.j10_tipo_fuente = 'OT' AND rm_j02.j02_ordenes = 'N'
		THEN
			CALL fgl_winmessage(vg_producto,
				'No se pueden cancelar facturas de servicios ' ||
				'en esta caja.',
				'exclamation')
			NEXT FIELD j10_tipo_fuente
		END IF
		IF rm_j10.j10_tipo_fuente = 'SC' AND rm_j02.j02_solicitudes = 'N'
		THEN
			CALL fgl_winmessage(vg_producto,
				'No se pueden cancelar solicitudes de ' ||
				'cobro en esta caja.',
				'exclamation')
			NEXT FIELD j10_tipo_fuente
		END IF
		IF rm_j10.j10_tipo_fuente <> tipo_fuente THEN
			CALL dialog.keysetlabel('F5', '')
		END IF
	AFTER FIELD j10_num_fuente
		IF rm_j10.j10_num_fuente IS NULL THEN
			CLEAR FORM
			CALL setea_botones()
			DISPLAY BY NAME rm_j10.j10_tipo_fuente,
					rm_j10.j10_num_fuente
			CALL dialog.keysetlabel('F5', '')
			CONTINUE INPUT
		END IF
		CALL fl_lee_cabecera_caja(vg_codcia, vg_codloc, 
					  rm_j10.j10_tipo_fuente,
					  rm_j10.j10_num_fuente) 
						RETURNING r_j10.* 	 
		IF r_j10.j10_num_fuente IS NULL THEN
			CALL fgl_winmessage(vg_producto,
				'Registro no existe.',
				'exclamation')
			CLEAR FORM
			CALL setea_botones()
			DISPLAY BY NAME rm_j10.j10_tipo_fuente,
					rm_j10.j10_num_fuente
			CALL dialog.keysetlabel('F5', '')
			NEXT FIELD j10_num_fuente
		END IF
		IF r_j10.j10_estado <> 'A' THEN
			CALL fgl_winmessage(vg_producto,
				'Registro de caja no está activo.',
				'exclamation')
			CLEAR FORM
			CALL setea_botones()
			DISPLAY BY NAME rm_j10.j10_tipo_fuente,
					rm_j10.j10_num_fuente
			CALL dialog.keysetlabel('F5', '')
			NEXT FIELD j10_num_fuente
		END IF
		CASE rm_j10.j10_tipo_fuente
			WHEN 'PR'
				CALL fl_lee_preventa_rep(vg_codcia, vg_codloc,
					r_j10.j10_num_fuente) RETURNING r_r23.*
				IF r_r23.r23_numprev IS NULL THEN
					CALL fgl_winmessage(vg_producto,
						'Preventa no existe',
						'exclamation')
					CLEAR FORM
					DISPLAY BY NAME rm_j10.j10_tipo_fuente,
							rm_j10.j10_num_fuente
					CALL dialog.keysetlabel('F5', '')
					NEXT FIELD j10_num_fuente
				END IF
				IF r_r23.r23_estado <> 'F' THEN
					CALL fgl_winmessage(vg_producto,
						'Preventa no ha sido facturada.',
						'exclamation')
					CLEAR FORM
					DISPLAY BY NAME rm_j10.j10_tipo_fuente,
							rm_j10.j10_num_fuente
					CALL dialog.keysetlabel('F5', '')
					NEXT FIELD j10_num_fuente
				END IF
			WHEN 'PV'
				CALL fl_lee_preventa_veh(vg_codcia, vg_codloc,
					r_j10.j10_num_fuente) RETURNING r_v26.*
				IF r_v26.v26_numprev IS NULL THEN
					CALL fgl_winmessage(vg_producto,
						'Preventa no existe',
						'exclamation')
					CLEAR FORM
					DISPLAY BY NAME rm_j10.j10_tipo_fuente,
							rm_j10.j10_num_fuente
					CALL dialog.keysetlabel('F5', '')
					NEXT FIELD j10_num_fuente
				END IF
				IF r_v26.v26_estado <> 'F' THEN
					CALL fgl_winmessage(vg_producto,
						'Preventa no ha sido facturada.',
						'exclamation')
					CLEAR FORM
					DISPLAY BY NAME rm_j10.j10_tipo_fuente,
							rm_j10.j10_num_fuente
					CALL dialog.keysetlabel('F5', '')
					NEXT FIELD j10_num_fuente
				END IF
			WHEN 'OT'
				CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc,
					r_j10.j10_num_fuente) RETURNING r_t23.*
				IF r_t23.t23_orden IS NULL THEN
					CALL fgl_winmessage(vg_producto,
						'Orden de trabajo no existe.',
						'exclamation')
					CLEAR FORM
					DISPLAY BY NAME rm_j10.j10_tipo_fuente,
							rm_j10.j10_num_fuente
					CALL dialog.keysetlabel('F5', '')
					NEXT FIELD j10_num_fuente
				END IF
				IF r_t23.t23_estado <> 'F' THEN
					CALL fgl_winmessage(vg_producto,
						'Orden de trabajo no ha ' ||
						'sido facturada.',
						'exclamation')
					CLEAR FORM
					DISPLAY BY NAME rm_j10.j10_tipo_fuente,
							rm_j10.j10_num_fuente
					CALL dialog.keysetlabel('F5', '')
					NEXT FIELD j10_num_fuente
				END IF
			WHEN 'SC'
				CALL fl_lee_solicitud_cobro_cxc(
					vg_codcia, vg_codloc, 
					r_j10.j10_num_fuente) 
					RETURNING r_z24.*
				IF r_z24.z24_numero_sol IS NULL THEN
					CALL fgl_winmessage(vg_producto,
						'Solicitud de cobro no existe.',
						'exclamation')
					CLEAR FORM
					DISPLAY BY NAME rm_j10.j10_tipo_fuente,
							rm_j10.j10_num_fuente
					CALL dialog.keysetlabel('F5', '')
					NEXT FIELD j10_num_fuente
				END IF
				IF r_z24.z24_estado <> 'A' THEN
					CALL fgl_winmessage(vg_producto,
						'Solicitud de cobro no está ' ||
						'activa.',
						'exclamation')
					CLEAR FORM
					DISPLAY BY NAME rm_j10.j10_tipo_fuente,
							rm_j10.j10_num_fuente
					CALL dialog.keysetlabel('F5', '')
					NEXT FIELD j10_num_fuente
				END IF
		END CASE

		IF r_j10.j10_tipo_fuente = 'PR' OR r_j10.j10_tipo_fuente = 'PV' OR
		   r_j10.j10_tipo_fuente = 'OT'
		THEN
			IF r_j10.j10_tipo_destino IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'No se ha generado factura.',
									'exclamation')
				CLEAR FORM
				DISPLAY BY NAME rm_j10.j10_tipo_fuente,
								rm_j10.j10_num_fuente
				CALL dialog.keysetlabel('F5', '')
				NEXT FIELD j10_num_fuente
			END IF
		END IF

		LET rm_j10.* = r_j10.*
		CALL muestra_registro()
		CALL dialog.keysetlabel('F5', 'Ver Documento')
END INPUT

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
DEFINE i		SMALLINT
DEFINE j		SMALLINT
DEFINE salir		SMALLINT
DEFINE resp		CHAR(6)

DEFINE total		LIKE cajt011.j11_valor
DEFINE vuelto		LIKE cajt011.j11_valor
DEFINE valor_ef		LIKE cajt011.j11_valor

DEFINE bco_tarj		SMALLINT

DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_g09		RECORD LIKE gent009.*
DEFINE r_g10		RECORD LIKE gent010.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_j01		RECORD LIKE cajt001.*

OPTIONS
	INSERT KEY F30


{*
 * En el caso de las SC, la forma de pago ya fue ingresado en cobranzas
 * y solo debe aprobarse en caja
 *}
IF rm_j10.j10_tipo_fuente = 'SC' THEN
	DECLARE q_medio CURSOR FOR 
		SELECT z101_codigo_pago, z101_moneda, z101_cod_bco_tarj, 
			   z101_num_ch_aut,  z101_num_cta_tarj, z101_valor 
 		  FROM cxct101 
		 WHERE z101_compania   = vg_codcia
		   AND z101_localidad  = vg_codloc
		   AND z101_numero_sol = rm_j10.j10_num_fuente

	LET vm_indice = 1
	FOREACH q_medio INTO rm_j11[vm_indice].*
		LET vm_indice = vm_indice + 1
		IF vm_indice > vm_max_rows THEN
			CALL fl_mensaje_arreglo_lleno()
			EXIT FOREACH
		END IF
	END FOREACH
	FREE q_medio
	LET vm_indice = vm_indice - 1
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
				CALL ayudas_bco_tarj(rm_j11[i].forma_pago)
					RETURNING rm_j11[i].cod_bco_tarj
				DISPLAY rm_j11[i].cod_bco_tarj 
					TO ra_j11[j].j11_cod_bco_tarj
			END IF
		END IF
		LET INT_FLAG = 0
	ON KEY(F5)
		CALL ver_documento_origen()
		LET INT_FLAG = 0
	BEFORE INPUT
		CALL dialog.keysetlabel('INSERT', '')
		CALL calcula_total(arr_count()) RETURNING total
	BEFORE ROW
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
			CALL fgl_winmessage(vg_producto,
				'Forma de Pago no existe.',
				'exclamation')
			NEXT FIELD j11_codigo_pago
		END IF
		IF r_j01.j01_estado = 'B' THEN
			CALL fgl_winmessage(vg_producto,
				'Forma de Pago está bloqueada.',
				'exclamation')
			NEXT FIELD j11_codigo_pago
		END IF
	AFTER FIELD j11_moneda
		IF rm_j11[i].moneda IS NULL THEN
			NEXT FIELD j11_moneda
		END IF 

		CALL fl_lee_moneda(rm_j11[i].moneda) RETURNING r_mon.*

		-- Validaciones sobre la moneda
		IF r_mon.g13_moneda IS NULL THEN	
			CALL FGL_WINMESSAGE(vg_producto, 
                      		            'Moneda no existe',        
                                       	    'exclamation')
			NEXT FIELD j11_moneda
		END IF
		IF r_mon.g13_estado = 'B' THEN
			CALL FGL_WINMESSAGE(vg_producto, 
                	 	            'Moneda está bloqueada',        
                                       	    'exclamation')
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
	AFTER FIELD j11_valor
		IF rm_j11[i].valor IS NULL THEN
			NEXT FIELD j11_valor
		END IF
		IF rm_j11[i].valor <= 0 THEN
			CALL fgl_winmessage(vg_producto,
				'El valor debe ser mayor a cero.',
				'exclamation')
			NEXT FIELD j11_valor
		END IF	
		LET vm_indice = arr_count()
		LET total = calcula_total(vm_indice)
		LET valor_ef = valor_efectivo(vm_indice)
		LET vuelto = total - rm_j10.j10_valor
		IF vuelto < 0 THEN 
			LET vuelto = 0
		END IF
		DISPLAY BY NAME vuelto
		IF fgl_lastkey() = fgl_keyval('return') THEN
			NEXT FIELD ra_j11[j-1].j11_codigo_pago
		END IF
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
				CALL fgl_winmessage(vg_producto,
					'Banco no existe.',
					'exclamation')
				NEXT FIELD j11_cod_bco_tarj
			END IF
		END IF
		IF bco_tarj = 2 THEN
			CALL fl_lee_tarjeta_credito(rm_j11[i].cod_bco_tarj)
				RETURNING r_g10.* 
			IF r_g10.g10_tarjeta IS NULL THEN
				CALL fgl_winmessage(vg_producto,
					'Tarjeta no existe.',
					'exclamation')
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
				CALL fgl_winmessage(vg_producto,
					'Digite cuenta de compañía.',
					'exclamation')
				NEXT FIELD j11_num_cta_tarj
			END IF
			CALL fl_lee_banco_compania(vg_codcia, rm_j11[i].cod_bco_tarj,
				rm_j11[i].num_cta_tarj) RETURNING r_g09.*
			IF r_g09.g09_numero_cta IS NULL THEN
				CALL fgl_winmessage(vg_producto,
					'No existe cuenta en este banco.',
					'exclamation')
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
					CALL fgl_winmessage(vg_producto,
						'Debe ingresar el código ' ||
						'del banco o de la tarjeta.',
						'exclamation')
					NEXT FIELD j11_cod_bco_tarj
				END IF
				IF rm_j11[i].num_cta_tarj IS NULL THEN
					CALL fgl_winmessage(vg_producto,
						'Debe ingresar el número ' ||
						'de la cuenta o de la ' ||
						'tarjeta.',
						'exclamation')
					NEXT FIELD j11_num_cta_tarj
				END IF
			END IF
			IF rm_j11[i].forma_pago = vm_cheque
			OR rm_j11[i].forma_pago = 'TJ'
			OR rm_j11[i].forma_pago = 'RT'
			THEN
				IF rm_j11[i].num_ch_aut IS NULL THEN
					CALL fgl_winmessage(vg_producto,
						'Debe ingresar el número ' ||
						'del cheque/retención/aut. ' ||
						'tarjeta.',
						'exclamation')
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
					CALL fgl_winmessage(vg_producto,
						'El total en efectivo ' ||
						'no es suficiente para ' ||
						'el vuelto.',
						'exclamation')
					CONTINUE INPUT
				END IF
			ELSE
				CALL fgl_winmessage(vg_producto,
					'El total en la moneda de la ' ||
					'facturación debe ser igual al ' ||
					'valor a recaudar.',
					'exclamation')
				CONTINUE INPUT
			END IF 
		END IF
		LET salir = 1
END INPUT
IF INT_FLAG THEN
	RETURN
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
			CALL fgl_winmessage(vg_producto,
				'No existe paridad de cambio para esta moneda.',
				'stop')
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
		CALL fgl_winmessage(vg_producto, 
				    'No existe factor de conversión ' ||
				    'para esta moneda',
				    'exclamation')
		INITIALIZE paridad TO NULL
	ELSE
		LET paridad = r_g14.g14_tasa 
	END IF
END IF

RETURN paridad

END FUNCTION



FUNCTION ver_documento_origen()

DEFINE comando		CHAR(250)

IF rm_j10.j10_num_fuente IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'Debe especificar un documento primero.',
		'exclamation')
	RETURN
END IF

CASE rm_j10.j10_tipo_fuente
	WHEN 'PR'	-- fglrun repp209 vg_base RE vg_codcia vg_codloc numprev
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
 			      'REPUESTOS', vg_separador, 'fuentes', 
			      vg_separador, '; fglrun repp209 ', vg_base, ' ',
			      'RE', vg_codcia, ' ', vg_codloc,
			      ' PREV ', rm_j10.j10_num_fuente 
	WHEN 'PV'	-- fglrun vehp201 vg_base VE vg_codcia vg_codloc numprev
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
 			      'VEHICULOS', vg_separador, 'fuentes', 
			      vg_separador, '; fglrun vehp201 ', vg_base, ' ',
			      'VE', vg_codcia, ' ', vg_codloc,
			      ' ', rm_j10.j10_num_fuente 
	WHEN 'OT'	-- fglrun talp204 vg_base TA vg_codcia vg_codloc orden
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
 			      'TALLER', vg_separador, 'fuentes', 
			      vg_separador, '; fglrun talp204 ', vg_base, ' ',
			      'TA', vg_codcia, ' ', vg_codloc,
			      ' ', rm_j10.j10_num_fuente, ' O'
	WHEN 'SC'	-- fglrun cxcp204 vg_base CO vg_codcia vg_codloc num_sol
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
 			      'COBRANZAS', vg_separador, 'fuentes', 
			      vg_separador, '; fglrun cxcp204 ', vg_base, ' ',
			      'CO', vg_codcia, ' ', vg_codloc,
			      ' ', rm_j10.j10_num_fuente 
END CASE

RUN comando

END FUNCTION



FUNCTION proceso_master_transacciones_caja()

DEFINE done 		SMALLINT
DEFINE comando		CHAR(250)

DEFINE r_z24		RECORD LIKE cxct024.*

BEGIN WORK

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

CALL fl_lee_solicitud_cobro_cxc(vg_codcia, vg_codloc, rm_j10.j10_num_fuente) 
	RETURNING r_z24.*
IF r_z24.z24_tipo = 'P' THEN
	LET comando = 'fglrun cajp204 ', vg_base, ' ',
			      vg_codcia, ' ', vg_codloc, ' ', 
			       rm_j10.j10_num_fuente 
ELSE
	LET comando = 'fglrun cajp205 ', vg_base, ' ',
			      vg_codcia, ' ', vg_codloc, ' ', 
			       rm_j10.j10_num_fuente 
END IF

RUN comando

-- 3: si el estado de la cabecera cambio a 'P' todo OK
--CALL verifica_pago_tarjeta_credito()
CALL fl_lee_cabecera_caja(vg_codcia, vg_codloc, rm_j10.j10_tipo_fuente,
						  rm_j10.j10_num_fuente) 
 	RETURNING rm_j10.* 	 

IF rm_j10.j10_estado = 'P' THEN
	CALL actualiza_acumulados_tipo_transaccion('I')
	CALL imprime_comprobante()	
	CALL fgl_winmessage(vg_producto, 'Proceso terminado OK.', 'exclamation')
	RETURN	
END IF

-- 4: si el estado sigue en '*' 

BEGIN WORK

IF rm_j10.j10_estado = '*' THEN
	CALL fgl_winmessage(vg_producto, 
		'Proceso no pudo terminar correctamente',
		'exclamation')

--	4.1:	borrar detalles
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

--	4.2:	regresar el estado a 'A'
	LET done = 0 
	INITIALIZE rm_j10.j10_codigo_caja TO NULL
	WHILE NOT done 
		LET done = actualiza_cabecera('A')
	END WHILE
END IF

COMMIT WORK

END FUNCTION



FUNCTION verifica_pago_tarjeta_credito()
DEFINE r_j11		RECORD LIKE cajt011.*
DEFINE r_g10		RECORD LIKE gent010.*
DEFINE r_doc		RECORD LIKE cxct020.*

SELECT * INTO r_j11.* FROM cajt011
	WHERE j11_compania    = rm_j10.j10_compania    AND  
	      j11_localidad   = rm_j10.j10_localidad   AND  
	      j11_tipo_fuente = rm_j10.j10_tipo_fuente AND  
	      j11_num_fuente  = rm_j10.j10_num_fuente   AND 
	      j11_codigo_pago = 'TJ'
IF status = NOTFOUND THEN
	RETURN
END IF
CALL fl_lee_tarjeta_credito(r_j11.j11_cod_bco_tarj) RETURNING r_g10.*
IF r_g10.g10_codcobr IS NULL THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto, 'Tarjeta de crédito: ' ||
		r_g10.g10_nombre || ' no tiene código cobranzas asignado. '
		|| 'Por favor asígnelo en el módulo de parámetro GENERALES.',
		'stop')
	EXIT PROGRAM
END IF
INITIALIZE r_doc.* TO NULL
LET r_doc.z20_compania	= vg_codcia
LET r_doc.z20_localidad = vg_codloc
LET r_doc.z20_codcli 	= r_g10.g10_codcobr
LET r_doc.z20_tipo_doc 	= rm_j10.j10_tipo_destino
LET r_doc.z20_num_doc 	= rm_j10.j10_num_destino
LET r_doc.z20_dividendo = 01
LET r_doc.z20_areaneg 	= rm_j10.j10_areaneg
LET r_doc.z20_referencia= 'AUI. #: ', r_j11.j11_num_ch_aut
LET r_doc.z20_fecha_emi = TODAY
LET r_doc.z20_fecha_vcto= TODAY + 30
LET r_doc.z20_tasa_int  = 0
LET r_doc.z20_tasa_mora = 0
LET r_doc.z20_moneda 	= r_j11.j11_moneda
LET r_doc.z20_paridad 	= 1 
LET r_doc.z20_paridad   = r_j11.j11_paridad
LET r_doc.z20_valor_cap = r_j11.j11_valor
LET r_doc.z20_valor_int = 0
LET r_doc.z20_saldo_cap = r_j11.j11_valor
LET r_doc.z20_saldo_int = 0
LET r_doc.z20_cartera 	= 1
LET r_doc.z20_linea 	= 'KOMAT'
LET r_doc.z20_origen 	= 'A'
LET r_doc.z20_cod_tran  = rm_j10.j10_tipo_destino
LET r_doc.z20_num_tran  = rm_j10.j10_num_destino
LET r_doc.z20_usuario 	= vg_usuario
LET r_doc.z20_fecing 	= CURRENT
INSERT INTO cxct020 VALUES (r_doc.*)
CALL fl_genera_saldos_cliente(vg_codcia, vg_codloc, r_g10.g10_codcobr)

END FUNCTION



FUNCTION actualiza_cabecera(estado)

DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT

DEFINE estado		CHAR(1)

LET intentar = 1
LET done = 0
WHILE (intentar)
	WHENEVER ERROR CONTINUE
		DECLARE q_j10 CURSOR FOR
			SELECT * FROM cajt010
				WHERE j10_compania    = vg_codcia         
				  AND j10_localidad   = vg_codloc          
				  AND j10_tipo_fuente = rm_j10.j10_tipo_fuente
				  AND j10_num_fuente  = rm_j10.j10_num_fuente
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

OPEN q_j10
FETCH q_j10 

	UPDATE cajt010 SET j10_estado      = estado,
					   j10_fecha_pro   = CURRENT,
					   j10_codigo_caja = rm_j04.j04_codigo_caja
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
		CALL fgl_winmessage(vg_producto,
			'No existe paridad de cambio para esta moneda.',
			'stop')
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
CALL fgl_winquestion(vg_producto, 
		     'Registro bloqueado por otro usuario, desea ' ||
                     'intentarlo nuevamente', 'No', 'Yes|No', 'question', 1)
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
		CALL fgl_winmessage(vg_producto,
			'Registro de caja bloqueado.',
			'exclamation')
		ROLLBACK WORK
		EXIT PROGRAM
	END IF

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

BEGIN WORK

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
		CALL fgl_winmessage(vg_producto,
			'No se pueden actualizar los acumulados.',
			'exclamation')
		ROLLBACK WORK
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

COMMIT WORK

END FUNCTION



FUNCTION actualiza_cheques_postfechados(estado)

DEFINE estado		CHAR(1)

WHENEVER ERROR CONTINUE
SET LOCK MODE TO WAIT 5
DECLARE q_che_post CURSOR FOR
	SELECT z26_estado FROM cxct026
		WHERE EXISTS (SELECT z26_compania, z26_localidad, z26_codcli,
			      z26_banco,    z26_num_cta,   z26_num_cheque
	  			FROM cajt011
	  			WHERE j11_compania    = vg_codcia
	  		  	  AND j11_localidad   = vg_codloc
	  			  AND j11_tipo_fuente = rm_j10.j10_tipo_fuente
	  			  AND j11_num_fuente  = rm_j10.j10_num_fuente
	  			  AND j11_codigo_pago = vm_cheque
	  			  AND j11_protestado  = 'N'
	  			  AND z26_compania    = j11_compania
	  			  AND z26_localidad   = j11_localidad
	  			  AND z26_codcli      = rm_j10.j10_codcli
	  			  AND z26_banco       = j11_cod_bco_tarj
	  			  AND z26_num_cta     = j11_num_cta_tarj
	  			  AND z26_num_cheque  = j11_num_ch_aut
	  			  AND z26_estado     <> estado)
	FOR UPDATE OF z26_estado

SET LOCK MODE TO NOT WAIT
WHENEVER ERROR STOP

IF STATUS < 0 THEN
	CALL fgl_winmessage(vg_producto,
		'No se ha podido actualizar el estado de los cheques ' ||
		'postfechados.',
		'exclamation')
	ROLLBACK WORK
	EXIT PROGRAM
END IF

FOREACH q_che_post
	UPDATE cxct026 SET z26_estado = estado WHERE CURRENT OF q_che_post
END FOREACH

END FUNCTION



FUNCTION setea_botones()

DISPLAY 'FP'			TO 	bt_codigo_pago
DISPLAY 'Mon'			TO 	bt_moneda
DISPLAY 'Bco/Tarj'		TO 	bt_bco_tarj
DISPLAY 'Nro. Che./Aut.'	TO 	bt_che_aut
DISPLAY 'Nro. Cta./Tarj.'	TO 	bt_cta_tarj
DISPLAY 'Valor'			TO 	bt_valor

END FUNCTION



FUNCTION execute_query()

SELECT ROWID INTO vm_rowid
	FROM cajt010
	WHERE j10_compania    = vg_codcia
	  AND j10_localidad   = vg_codloc
	  AND j10_tipo_fuente = vm_tipo_fuente
	  AND j10_num_fuente  = vm_num_fuente

IF STATUS = NOTFOUND THEN
	CALL fgl_winmessage(vg_producto, 
		'No existe forma de pago.', 
		'exclamation')
	EXIT PROGRAM	
ELSE
	CALL lee_muestra_registro(vm_rowid)
END IF

END FUNCTION



FUNCTION lee_muestra_registro(row)
DEFINE row 		INTEGER

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
	      	
CALL muestra_registro()
CALL muestra_detalle()

END FUNCTION



FUNCTION muestra_detalle()

DEFINE i		SMALLINT
DEFINE filas_pant	SMALLINT

DEFINE dummy		LIKE cajt011.j11_valor

LET filas_pant = fgl_scr_size('ra_j11')
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
	CALL fgl_winmessage(vg_producto,
		'No hay detalle de forma de pago.',
		'exclamation')
	EXIT PROGRAM
END IF
DISPLAY ARRAY rm_j11 TO ra_j11.*
	BEFORE DISPLAY
		CALL setea_botones()
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
			CALL fgl_winmessage(vg_producto,
				'No existe paridad de cambio para esta moneda.',
				'stop')
			EXIT PROGRAM
		END IF
		LET valor = valor + (rm_j11[i].valor * paridad)
	END IF
END FOR

RETURN valor

END FUNCTION



FUNCTION imprime_comprobante()

DEFINE comando			VARCHAR(250)

DEFINE r_r23		RECORD LIKE rept023.* 	-- Preventa Repuestos
DEFINE r_v26		RECORD LIKE veht026.* 	-- Preventa Vehiculos
DEFINE r_t23		RECORD LIKE talt023.*	-- Orden de Trabajo
DEFINE r_z24		RECORD LIKE cxct024.*	-- Solicitud Cobro Clientes

INITIALIZE comando TO NULL
CASE rm_j10.j10_tipo_fuente 
	WHEN 'SC'
		CALL fl_lee_solicitud_cobro_cxc(vg_codcia, vg_codloc,
						rm_j10.j10_num_fuente)
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
END CASE

IF comando IS NOT NULL THEN
	RUN comando
END IF

END FUNCTION



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 
                            'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 
                            'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || 
                            vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
	LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc, 
                            'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: ' || 
                            vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
