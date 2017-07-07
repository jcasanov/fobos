------------------------------------------------------------------------------
-- Titulo           : cajp206.4gl - Otros ingresos
-- Elaboracion      : 07-nov-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun cajp206 base modulo compania localidad
--		      [tipo_fuente num_fuente]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_tipo_fuente	LIKE cajt010.j10_tipo_fuente
DEFINE vm_num_fuente	LIKE cajt010.j10_num_fuente

DEFINE vm_cheque	CHAR(2)
DEFINE vm_efectivo	CHAR(2)
DEFINE vm_deposito	CHAR(2)
DEFINE vm_otros_ingresos LIKE cajt010.j10_tipo_fuente

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

DEFINE rm_j11 ARRAY[50] OF RECORD 
	forma_pago		LIKE cajt011.j11_codigo_pago, 
	moneda			LIKE cajt011.j11_moneda, 
	cod_bco_tarj		LIKE cajt011.j11_cod_bco_tarj, 
	num_ch_aut		LIKE cajt011.j11_num_ch_aut, 
	num_cta_tarj		LIKE cajt011.j11_num_cta_tarj,
	valor			LIKE cajt011.j11_valor 
END RECORD

DEFINE vm_paridad ARRAY[50] OF	LIKE cajt011.j11_paridad



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
--CALL startlog('../logs/errores')
CALL startlog('../logs/cajp206.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 6 THEN -- Validar # parámetros correcto
	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto.','stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'cajp206'
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
DEFINE r_b00		RECORD LIKE ctbt000.*
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE r_g13		RECORD LIKE gent013.*

CALL fl_nivel_isolation()
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 21
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_206 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
        OPEN FORM f_206 FROM '../forms/cajf206_1'
ELSE
        OPEN FORM f_206 FROM '../forms/cajf206_1c'
END IF
DISPLAY FORM f_206

LET vm_max_rows = 50

LET vm_otros_ingresos = 'OI'
LET vm_cheque   = 'CH'
LET vm_efectivo = 'EF'
LET vm_deposito = 'DP'

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
		CALL fl_mostrar_mensaje('La caja no está aperturada.','exclamation')
		EXIT PROGRAM
	END IF
	
	INITIALIZE rm_j10.*    TO NULL
	INITIALIZE rm_j11[1].* TO NULL
	LET vm_indice = 1

	LET rm_j10.j10_compania    = vg_codcia
	LET rm_j10.j10_localidad   = vg_codloc
	LET rm_j10.j10_estado      = 'A'
	LET rm_j10.j10_usuario     = vg_usuario
	LET rm_j10.j10_fecing      = CURRENT
	LET rm_j10.j10_tipo_fuente = vm_otros_ingresos
	LET rm_j10.j10_moneda      = rg_gen.g00_moneda_base
	LET rm_j10.j10_codigo_caja = rm_j02.j02_codigo_caja
	CALL fl_lee_moneda(rm_j10.j10_moneda) RETURNING r_g13.*
	DISPLAY r_g13.g13_nombre TO n_moneda
	LET rm_j10.j10_fecha_pro   = CURRENT

	CALL lee_datos_cabecera()
	IF INT_FLAG THEN
		LET salir = 1  
		CONTINUE WHILE
	END IF
	
	IF rm_j10.j10_valor > 0 THEN
		CALL ingresa_detalle()
		IF INT_FLAG THEN
			CONTINUE WHILE
		END IF
	END IF

	BEGIN WORK
	
	CALL proceso_master_transacciones_caja()
	
	INITIALIZE r_b12.* TO NULL

	CALL fl_lee_compania_contabilidad(vg_codcia) RETURNING r_b00.*
	--IF r_b00.b00_inte_online = 'S' THEN
		CALL contabilizacion_online() RETURNING r_b12.*
		IF int_flag THEN
			CLEAR FORM
			ROLLBACK WORK
			CONTINUE WHILE
		END IF
	--END IF

	COMMIT WORK


	IF r_b12.b12_compania IS NOT NULL AND r_b00.b00_mayo_online = 'S' THEN
		CALL fl_mayoriza_comprobante(r_b12.b12_compania, 
			r_b12.b12_tipo_comp, r_b12.b12_num_comp, 'M')
	END IF
	CALL imprime_comprobante()

	CALL fl_mensaje_registro_ingresado()

END WHILE

CLOSE WINDOW w_206

END FUNCTION



FUNCTION lee_datos_cabecera()

DEFINE resp 		CHAR(6)
DEFINE estado 		CHAR(1)

DEFINE nomcli		LIKE cxct001.z01_nomcli

DEFINE r_g03		RECORD LIKE gent003.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_g13		RECORD LIKE gent013.*

LET INT_FLAG = 0
INPUT BY NAME rm_j10.j10_tipo_fuente, rm_j10.j10_num_fuente, 
	      rm_j10.j10_fecha_pro,  rm_j10.j10_areaneg, rm_j10.j10_referencia, 
              rm_j10.j10_codcli,     rm_j10.j10_nomcli,  rm_j10.j10_moneda,   
              rm_j10.j10_valor,      rm_j10.j10_usuario
	WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(j10_areaneg, j10_codcli, 
	      			     j10_nomcli,    j10_moneda,  j10_valor
	      			    ) THEN
			LET INT_FLAG = 1
			EXIT INPUT
		END IF

		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			EXIT INPUT
		END IF
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(j10_areaneg) THEN
			CALL fl_ayuda_areaneg(vg_codcia) 
				RETURNING r_g03.g03_areaneg,
					  r_g03.g03_nombre
			IF r_g03.g03_areaneg IS NOT NULL THEN
				LET rm_j10.j10_areaneg = r_g03.g03_areaneg
				DISPLAY BY NAME rm_j10.j10_areaneg
				DISPLAY r_g03.g03_nombre TO n_areaneg
			END IF
		END IF
		IF INFIELD(j10_codcli) THEN
         	  	CALL fl_ayuda_cliente_general() 
				RETURNING r_z01.z01_codcli, r_z01.z01_nomcli
			IF r_z01.z01_codcli IS NOT NULL THEN	
                  		LET rm_j10.j10_codcli = r_z01.z01_codcli
                  		LET rm_j10.j10_nomcli = r_z01.z01_nomcli
                 		DISPLAY BY NAME rm_j10.j10_codcli,
                 				rm_j10.j10_nomcli
			END IF
		END IF
		IF INFIELD(j10_moneda) THEN
			CALL fl_ayuda_monedas() RETURNING r_g13.g13_moneda,
							  r_g13.g13_nombre,
							  r_g13.g13_decimales
			IF r_g13.g13_moneda IS NOT NULL THEN
				LET rm_j10.j10_moneda = r_g13.g13_moneda
				DISPLAY BY NAME rm_j10.j10_moneda
				DISPLAY r_g13.g13_nombre TO n_moneda
			END IF
		END IF
		LET INT_FLAG = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD j10_areaneg
		IF rm_j10.j10_areaneg IS NULL THEN
			CLEAR n_areaneg
			CONTINUE INPUT
		END IF
		CALL fl_lee_area_negocio(vg_codcia, rm_j10.j10_areaneg)
			RETURNING r_g03.*
		IF r_g03.g03_areaneg IS NULL THEN
			--CALL fgl_winmessage(vg_producto,'Area de negocio no existe.','exclamation')
			CALL fl_mostrar_mensaje('Area de negocio no existe.','exclamation')
			CLEAR n_areaneg
			NEXT FIELD j10_areaneg
		END IF
		DISPLAY r_g03.g03_nombre TO n_areaneg
	AFTER FIELD j10_codcli
		IF rm_j10.j10_codcli IS NULL THEN
			CONTINUE INPUT
		ELSE
			CALL fl_lee_cliente_general(rm_j10.j10_codcli) 
				RETURNING r_z01.*
			IF r_z01.z01_codcli IS NULL THEN
              			--CALL fgl_winmessage(vg_producto,'No existe un cliente con ese código.','exclamation')
				CALL fl_mostrar_mensaje('No existe un cliente con ese código.','exclamation')
				INITIALIZE rm_j10.j10_nomcli TO NULL
				DISPLAY BY NAME rm_j10.j10_nomcli
				NEXT FIELD j10_codcli     
        		END IF   
			IF r_z01.z01_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				INITIALIZE rm_j10.j10_nomcli TO NULL
				DISPLAY BY NAME rm_j10.j10_nomcli
				NEXT FIELD j10_codcli      
			END IF
			LET rm_j10.j10_codcli = r_z01.z01_codcli
			LET rm_j10.j10_nomcli = r_z01.z01_nomcli
        		DISPLAY BY NAME rm_j10.j10_codcli,
					rm_j10.j10_nomcli
		END IF
	BEFORE FIELD j10_nomcli
		LET nomcli = rm_j10.j10_nomcli
	AFTER FIELD j10_nomcli
		IF rm_j10.j10_nomcli IS NULL THEN
			CONTINUE INPUT
		END IF
		IF nomcli <> rm_j10.j10_nomcli THEN
			INITIALIZE rm_j10.j10_codcli TO NULL
			DISPLAY BY NAME rm_j10.j10_codcli
		END IF
	AFTER FIELD j10_moneda
		IF rm_j10.j10_moneda IS NULL THEN
			CLEAR n_moneda
		ELSE
			CALL fl_lee_moneda(rm_j10.j10_moneda) RETURNING r_g13.*
			IF r_g13.g13_moneda IS NULL THEN	
				--CALL FGL_WINMESSAGE(vg_producto,'Moneda no existe.','exclamation')
				CALL fl_mostrar_mensaje('Moneda no existe.','exclamation')
				CLEAR n_moneda
				NEXT FIELD j10_moneda
			ELSE
				IF r_g13.g13_estado = 'B' THEN
					CALL fl_mensaje_estado_bloqueado()
					CLEAR n_moneda
					NEXT FIELD j10_moneda
				ELSE
					DISPLAY r_g13.g13_nombre TO n_moneda
				END IF
			END IF 
		END IF
	AFTER INPUT
		IF int_flag THEN
			EXIT INPUT
		END IF
	      	IF rm_j10.j10_referencia IS NULL THEN
			CALL fl_mostrar_mensaje('Digite referencia.','exclamation')
			NEXT FIELD j10_referencia
		END IF
END INPUT

END FUNCTION



FUNCTION ingresa_detalle()

DEFINE i		SMALLINT
DEFINE j		SMALLINT
DEFINE salir		SMALLINT
DEFINE resp		CHAR(6)

DEFINE total		LIKE cajt011.j11_valor
DEFINE vuelto		LIKE cajt011.j11_valor
DEFINE valor_ef		LIKE cajt011.j11_valor
DEFINE cont_cred	LIKE cajt001.j01_cont_cred

DEFINE bco_tarj		SMALLINT

DEFINE r_g08		RECORD LIKE gent008.*
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
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(j11_codigo_pago) THEN
			CALL fl_ayuda_forma_pago(vg_codcia, 'T', 'A', 'N') 
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
			CALL ayudas_bco_tarj(rm_j11[i].forma_pago)
				RETURNING rm_j11[i].cod_bco_tarj
			DISPLAY rm_j11[i].cod_bco_tarj 
				TO ra_j11[j].j11_cod_bco_tarj
		END IF
		LET INT_FLAG = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel('INSERT', '')
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
		CALL fl_lee_tipo_pago_caja(vg_codcia, rm_j11[i].forma_pago,
						r_j01.j01_cont_cred)
			RETURNING r_j01.*		
		IF r_j01.j01_codigo_pago IS NULL THEN
			--CALL fgl_winmessage(vg_producto,'Forma de Pago no existe.','exclamation')
			CALL fl_mostrar_mensaje('Forma de Pago no existe.','exclamation')
			NEXT FIELD j11_codigo_pago
		END IF
		IF r_j01.j01_estado = 'B' THEN
			CALL fl_mensaje_estado_bloqueado()
			NEXT FIELD j11_codigo_pago
		END IF
		IF  r_j01.j01_codigo_pago <> vm_efectivo
		AND r_j01.j01_codigo_pago <> vm_cheque
		AND r_j01.j01_codigo_pago <> vm_deposito
		THEN
			--CALL fgl_winmessage(vg_producto,'La forma de pago debe ser en efectivo, cheque o depósito.','exclamation')
			CALL fl_mostrar_mensaje('La forma de pago debe ser en efectivo, cheque o depósito.','exclamation')
			NEXT FIELD j11_codigo_pago
		END IF
	AFTER FIELD j11_moneda
		IF rm_j11[i].moneda IS NULL THEN
			NEXT FIELD j11_moneda
		END IF 

		CALL fl_lee_moneda(rm_j11[i].moneda) RETURNING r_mon.*

		-- Validaciones sobre la moneda
		IF r_mon.g13_moneda IS NULL THEN	
			--CALL FGL_WINMESSAGE(vg_producto,'Moneda no existe','exclamation')
			CALL fl_mostrar_mensaje('Moneda no existe.','exclamation')
			NEXT FIELD j11_moneda
		END IF
		IF r_mon.g13_estado = 'B' THEN
			CALL fl_mensaje_estado_bloqueado()
			NEXT FIELD j11_moneda
		END IF

		LET vm_paridad[i] = calcula_paridad(rm_j11[i].moneda,
						    rm_j10.j10_moneda)
		IF vm_paridad[i] IS NULL THEN
			LET rm_j11[i].moneda = rm_j10.j10_moneda
			DISPLAY rm_j11[i].moneda TO ra_j11[j].j11_moneda
			LET vm_paridad[i] = 1
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
			--CALL fgl_winmessage(vg_producto,'El valor debe ser mayor a cero.','exclamation')
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
		DISPLAY BY NAME vuelto
		IF fgl_lastkey() = fgl_keyval('return') THEN
			--NEXT FIELD ra_j11[j-1].j11_codigo_pago
			NEXT FIELD j11_codigo_pago
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
				--CALL fgl_winmessage(vg_producto,'Banco no existe.','exclamation')
				CALL fl_mostrar_mensaje('Banco no existe.','exclamation')
				NEXT FIELD j11_cod_bco_tarj
			END IF
		END IF
		IF bco_tarj = 2 THEN
			LET cont_cred = 'C'
			IF rm_j10.j10_tipo_fuente = 'SC' THEN
				LET cont_cred = 'R'
			END IF
			CALL fl_lee_tarjeta_credito(vg_codcia,
							rm_j11[i].cod_bco_tarj,
							rm_j11[i].forma_pago,
							cont_cred)
				RETURNING r_g10.* 
			IF r_g10.g10_tarjeta IS NULL THEN
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

DEFINE forma_pago	LIKE cajt011.j11_codigo_pago
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
	CALL fl_ayuda_tarjeta(vg_codcia, 'T', 'A')
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

DEFINE total		LIKE cajt011.j11_valor

LET total = 0
FOR i = 1 TO num_elm
	IF rm_j11[i].valor IS NOT NULL THEN
		LET total = total + (rm_j11[i].valor * vm_paridad[i])
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
		INITIALIZE paridad TO NULL
	ELSE
		LET paridad = r_g14.g14_tasa 
	END IF
END IF

RETURN paridad

END FUNCTION



FUNCTION proceso_master_transacciones_caja()

DEFINE done 		SMALLINT
DEFINE comando		CHAR(250)

DEFINE r_z24		RECORD LIKE cxct024.*

LET rm_j10.j10_codigo_caja = rm_j04.j04_codigo_caja

LET rm_j10.j10_num_fuente = nextValInSequence(vg_modulo, 
				rm_j10.j10_tipo_fuente)
IF rm_j10.j10_num_fuente  = -1 THEN
	ROLLBACK WORK
	RETURN
END IF

LET rm_j10.j10_estado = 'P'

LET rm_j10.j10_tipo_destino = rm_j10.j10_tipo_fuente
LET rm_j10.j10_num_destino  = rm_j10.j10_num_fuente

INSERT INTO cajt010 VALUES(rm_j10.*)
DISPLAY BY NAME rm_j10.j10_num_fuente

-- 1: Actualiza cajt010 con el codigo de caja actual y grabar detalles
LET done = actualiza_cabecera()
IF NOT done THEN
	ROLLBACK WORK
	RETURN 
END IF 

IF rm_j10.j10_valor > 0 THEN
	CALL graba_detalle()
	CALL actualiza_acumulados_caja('I')
	CALL actualiza_acumulados_tipo_transaccion('I')
END IF

END FUNCTION



FUNCTION actualiza_cabecera()

DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT

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

	UPDATE cajt010 SET j10_codigo_caja = rm_j02.j02_codigo_caja
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

LET total = calcula_total(vm_indice)
IF total > rm_j10.j10_valor THEN
	LET vuelto = total - rm_j10.j10_valor
END IF

INITIALIZE r_j11.* TO NULL

LET r_j11.j11_compania    = vg_codcia
LET r_j11.j11_localidad   = vg_codloc
LET r_j11.j11_tipo_fuente = rm_j10.j10_tipo_fuente
LET r_j11.j11_num_fuente  = rm_j10.j10_num_fuente

LET r_j11.j11_protestado  = 'N'

LET secuencia = 1
FOR i = 1 TO vm_indice 

	IF vuelto > 0 AND rm_j11[i].forma_pago = vm_efectivo THEN
		LET valor = rm_j11[i].valor * vm_paridad[i]
		IF valor > vuelto THEN
			LET rm_j11[i].valor = 
				rm_j11[i].valor - (vuelto / vm_paridad[i])
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
	LET r_j11.j11_paridad     = vm_paridad[i]
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



FUNCTION nextValInSequence(modulo, tipo_tran)

DEFINE modulo		LIKE gent050.g50_modulo
DEFINE tipo_tran 	LIKE rept019.r19_cod_tran

DEFINE resp		CHAR(6)
DEFINE retVal 		SMALLINT

LET retVal = -1
WHILE retVal = -1

LET retVal = fl_actualiza_control_secuencias(vg_codcia, vg_codloc, modulo,
		'AA', tipo_tran)
IF retVal = 0 THEN
	EXIT PROGRAM
END IF
IF retVal <> -1 THEN
	 EXIT WHILE
END IF

--CALL fgl_winquestion(vg_producto,'La tabla de secuencias de transacciones está siendo accesada por otro usuario, espere unos segundos y vuelva a intentar','No','Yes|No|Cancel','question',1)
CALL fl_hacer_pregunta('La tabla de secuencias de transacciones está siendo accesada por otro usuario, espere unos segundos y vuelva a intentar','No')
	RETURNING resp 
IF resp <> 'Yes' THEN
	EXIT WHILE	
END IF

END WHILE

RETURN retVal

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
		ROLLBACK WORK
		CALL fl_mensaje_bloqueo_otro_usuario()
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



FUNCTION setea_botones()

--#DISPLAY 'FP'			TO 	bt_codigo_pago
--#DISPLAY 'Mon'			TO 	bt_moneda
--#DISPLAY 'Bco/Tarj'		TO 	bt_bco_tarj
--#DISPLAY 'Nro. Che./Aut.'	TO 	bt_che_aut
--#DISPLAY 'Nro. Cta./Tarj.'	TO 	bt_cta_tarj
--#DISPLAY 'Valor'			TO 	bt_valor

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
		rm_j10.j10_valor,
		rm_j10.j10_fecha_pro,
		rm_j10.j10_usuario
		
CALL muestra_registro()      	
CALL muestra_detalle()

END FUNCTION



FUNCTION muestra_registro()

DEFINE r_g03		RECORD LIKE gent003.*
DEFINE r_g13		RECORD LIKE gent013.*

DISPLAY BY NAME rm_j10.j10_areaneg,
		rm_j10.j10_codcli,
		rm_j10.j10_nomcli,
		rm_j10.j10_moneda,
		rm_j10.j10_valor,
		rm_j10.j10_fecha_pro,
		rm_j10.j10_usuario
CASE rm_j10.j10_estado 
	WHEN 'A'
		DISPLAY 'ACTIVO' TO estado
	WHEN 'P'
		DISPLAY 'PROCESADO' TO estado
	WHEN 'E'
		DISPLAY 'ELIMINADO' TO estado
END CASE

CALL fl_lee_area_negocio(vg_codcia, rm_j10.j10_areaneg) RETURNING r_g03.*
DISPLAY r_g03.g03_nombre TO n_areaneg

CALL fl_lee_moneda(rm_j10.j10_moneda) RETURNING r_g13.*
DISPLAY r_g13.g13_nombre TO n_moneda

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
	LET vm_paridad[i] = calcula_paridad(rm_j11[i].moneda,
					    rm_j10.j10_moneda)
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
		CALL control_visor_teclas_caracter_1() 
	ON KEY(F5)
		CALL imprime_comprobante()
	--#BEFORE DISPLAY
		--#CALL setea_botones()
		--#CALL dialog.keysetlabel('F5', 'Imprimir')
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
END DISPLAY

END FUNCTION



FUNCTION valor_efectivo(num_elm)

DEFINE num_elm		SMALLINT
DEFINE i		SMALLINT

DEFINE valor		LIKE cajt011.j11_valor

LET valor = 0
FOR i = 1 TO num_elm
	IF rm_j11[i].forma_pago = vm_efectivo THEN
		LET valor = valor + (rm_j11[i].valor * vm_paridad[i])
	END IF
END FOR

RETURN valor

END FUNCTION



FUNCTION contabilizacion_online()

DEFINE r_b41		RECORD LIKE ctbt041.*
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_ctas	ARRAY[25] OF RECORD 
	cuenta		LIKE ctbt013.b13_cuenta,
	n_cuenta	LIKE ctbt010.b10_descripcion,
	valor_db	LIKE ctbt013.b13_valor_base,
	valor_cr	LIKE ctbt013.b13_valor_base
END RECORD

DEFINE i, j, col	SMALLINT
DEFINE max_rows		SMALLINT
DEFINE salir		SMALLINT
DEFINE tot_egr		LIKE cajt010.j10_valor
DEFINE last_lvl_cta	LIKE ctbt001.b01_nivel
DEFINE cuenta      	LIKE ctbt010.b10_cuenta
DEFINE debito		LIKE ctbt013.b13_valor_base
DEFINE credito		LIKE ctbt013.b13_valor_base

DEFINE tot_debito	LIKE ctbt013.b13_valor_base
DEFINE tot_credito	LIKE ctbt013.b13_valor_base

DEFINE resp 		VARCHAR(6)
DEFINE query		CHAR(250)
DEFINE orden 		ARRAY[10] OF CHAR(4)
DEFINE columna_1	SMALLINT
DEFINE columna_2	SMALLINT

FOR i = 1 TO 10
	LET orden[i] = '' 
END FOR
LET columna_1 = 1
LET columna_2 = 2
LET col       = 2

CREATE TEMP TABLE tmp_cuenta(
	te_cuenta	CHAR(12),
	te_descripcion  CHAR(30),
	te_valor_db	DECIMAL(14,2),
	te_valor_cr	DECIMAL(14,2),
	te_serial	SERIAL,
	te_flag		CHAR(1) 
	-- 'F' -> Fijo, no puede ser elminado
	-- 'V' -> Variable, se puede eliminar
);

LET max_rows = 25

INITIALIZE r_b12.* TO NULL

OPEN WINDOW w_207_2 AT 5,3 WITH 14 ROWS, 77 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER, MESSAGE LINE LAST)
IF vg_gui = 1 THEN
        OPEN FORM f_207_2 FROM '../forms/cajf207_2'
ELSE
        OPEN FORM f_207_2 FROM '../forms/cajf207_2c'
END IF
DISPLAY FORM f_207_2

--#DISPLAY 'Cuenta' 		TO bt_cuenta
--#DISPLAY 'Descripción'	TO bt_descripcion
--#DISPLAY 'Débito'		TO bt_valor_db
--#DISPLAY 'Crédito'		TO bt_valor_cr

DECLARE q_aux CURSOR FOR
	SELECT * FROM ctbt041 WHERE b41_compania  = vg_codcia
				AND b41_localidad = vg_codloc

OPEN  q_aux
FETCH q_aux INTO r_b41.*
CLOSE q_aux
FREE  q_aux
IF STATUS = NOTFOUND THEN
	--CALL fgl_winmessage(vg_producto,'No se han configurado las cuentas de Caja.','exclamation')
	CALL fl_mostrar_mensaje('No se han configurado las cuentas de Caja.','exclamation')
	LET int_flag = 1
	CLOSE WINDOW w_207_2
	RETURN r_b12.*
END IF

IF rm_j10.j10_moneda = rg_gen.g00_moneda_base THEN
	LET cuenta = r_b41.b41_caja_mb     
ELSE
	LET cuenta = r_b41.b41_caja_me
END IF

CALL inserta_tabla_temporal(cuenta, rm_j10.j10_valor, 0, 'V') 
	RETURNING tot_debito, tot_credito

SELECT MAX(b01_nivel) INTO last_lvl_cta FROM ctbt001
IF last_lvl_cta IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'No se ha configurado el plan de cuentas, no puede haber contabilización en línea.','exclamation')
	CALL fl_mostrar_mensaje('No se ha configurado el plan de cuentas, no puede haber contabilización en línea.','exclamation')
	LET int_flag = 1
	CLOSE WINDOW w_207_2
	RETURN r_b12.*
END IF

OPTIONS 
	INSERT KEY F10,
	DELETE KEY F11

LET salir    = 0
WHILE NOT salir
	LET query = 'SELECT te_cuenta, te_descripcion, te_valor_db, ',
		     	'   te_valor_cr ',
		    '	FROM tmp_cuenta ',
		    '	ORDER BY ', columna_1, ' ', orden[columna_1],
			      ', ', columna_2, ' ', orden[columna_2]
	PREPARE ctas FROM query
	DECLARE q_ctas CURSOR FOR ctas 

	LET i = 1
	FOREACH q_ctas INTO r_ctas[i].*    
		LET i = i + 1
		IF i > max_rows THEN
			EXIT FOREACH
		END IF
	END FOREACH

	LET int_flag = 0
	CALL set_count(i)
	INPUT ARRAY r_ctas WITHOUT DEFAULTS FROM r_ctas.*
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
			IF INFIELD(b13_cuenta) AND modificable(r_ctas[i].cuenta)
			THEN
				CALL fl_ayuda_cuenta_contable(vg_codcia, 
					last_lvl_cta) 
					RETURNING r_b10.b10_cuenta, 
        					  r_b10.b10_descripcion 
				IF r_b10.b10_cuenta IS NOT NULL THEN
					LET r_ctas[i].cuenta = r_b10.b10_cuenta
					LET r_ctas[i].n_cuenta = 
						r_b10.b10_descripcion
					DISPLAY r_ctas[i].cuenta
						TO r_ctas[j].b13_cuenta
					DISPLAY r_ctas[i].n_cuenta
						TO r_ctas[j].n_cuenta
				END IF	
			END IF
			LET INT_FLAG = 0	
		ON KEY(F15)
			LET col = 1	
			EXIT INPUT
		ON KEY(F16)
			LET col = 2	
			EXIT INPUT
		ON KEY(F17)
			LET col = 3	
			EXIT INPUT
		ON KEY(F18)
			LET col = 4	
			EXIT INPUT
		BEFORE INPUT
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
			DISPLAY BY NAME tot_debito, tot_credito
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
		BEFORE DELETE
			IF NOT modificable(r_ctas[i].cuenta) THEN
				EXIT INPUT    
			END IF
			DELETE FROM tmp_cuenta 
				WHERE te_cuenta = r_ctas[i].cuenta
			LET tot_debito  = tot_debito  - r_ctas[i].valor_db
			LET tot_credito = tot_credito - r_ctas[i].valor_cr
			DISPLAY BY NAME tot_debito, tot_credito
		BEFORE FIELD b13_cuenta
			LET cuenta = r_ctas[i].cuenta
		AFTER FIELD b13_cuenta
			IF r_ctas[i].cuenta IS NULL AND modificable(cuenta)
			THEN
-- :)
				IF cuenta IS NOT NULL THEN
					DELETE FROM tmp_cuenta
						WHERE te_cuenta = cuenta
				END IF
-- :)
				CONTINUE INPUT
			END IF
			IF (r_ctas[i].cuenta IS NULL 
			 OR cuenta <> r_ctas[i].cuenta) 
			AND NOT modificable(cuenta) 
			THEN
				--CALL fgl_winmessage(vg_producto,'No puede modificar esta cuenta.','exclamation')
				CALL fl_mostrar_mensaje('No puede modificar esta cuenta.','exclamation')
				LET r_ctas[i].cuenta = cuenta
				DISPLAY r_ctas[i].cuenta TO r_ctas[j].b13_cuenta
				CONTINUE INPUT
			END IF
			IF (cuenta IS NULL OR cuenta <> r_ctas[i].cuenta) 
			AND NOT modificable(r_ctas[i].cuenta) 
			THEN
				--CALL fgl_winmessage(vg_producto,'No puede volver a ingresar esta cuenta.','exclamation')
				CALL fl_mostrar_mensaje('No puede volver a ingresar esta cuenta.','exclamation')
				LET r_ctas[i].cuenta = ' '
				NEXT FIELD b13_cuenta
			END IF
			CALL fl_lee_cuenta(vg_codcia, r_ctas[i].cuenta) 
				RETURNING r_b10.*
			IF r_b10.b10_cuenta IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'No existe cuenta contable.','exclamation')
				CALL fl_mostrar_mensaje('No existe cuenta contable.','exclamation')
				NEXT FIELD b13_cuenta
			END IF
			IF r_b10.b10_permite_mov = 'N' THEN
				CALL fl_mostrar_mensaje('Cuenta no permite movimiento.', 'exclamation')
				NEXT FIELD b13_cuenta
			END IF
-- :)
			IF cuenta IS NOT NULL THEN
				DELETE FROM tmp_cuenta
					WHERE te_cuenta = cuenta
			END IF
-- :)
			CALL inserta_tabla_temporal(r_ctas[i].cuenta,
				r_ctas[i].valor_db, r_ctas[i].valor_cr, 'V')
				RETURNING tot_debito, tot_credito
			DISPLAY BY NAME tot_debito, tot_credito
			LET r_ctas[i].n_cuenta = r_b10.b10_descripcion
			DISPLAY r_ctas[i].n_cuenta TO r_ctas[j].n_cuenta
		BEFORE FIELD valor_db 
			IF NOT modificable(r_ctas[i].cuenta) THEN
				NEXT FIELD b13_cuenta  
			END IF
			LET debito = r_ctas[i].valor_db
		AFTER FIELD valor_db
			IF r_ctas[i].valor_db IS NULL THEN
				LET r_ctas[i].valor_db = 0
				DISPLAY r_ctas[i].valor_db
					TO r_ctas[j].valor_db
			END IF
			IF r_ctas[i].valor_db > 0 THEN
				LET r_ctas[i].valor_cr = 0
				DISPLAY r_ctas[i].valor_cr
					TO r_ctas[j].valor_cr
			END IF
			IF debito <> r_ctas[i].valor_db OR debito IS NULL 
			THEN
				CALL inserta_tabla_temporal(r_ctas[i].cuenta,
					r_ctas[i].valor_db, r_ctas[i].valor_cr,
					'V') RETURNING tot_debito, tot_credito
				DISPLAY BY NAME tot_debito, tot_credito
			{
				IF cuenta_distribucion(vg_codcia, 
						       r_ctas[i].cuenta) 
				AND rm_cuenta[i].valor_debito > 0
				THEN
					CALL muestra_distribucion(vg_codcia,
						rm_cuenta[i].cuenta,
						rm_cuenta[i].valor_debito)
					LET int_flag = 0
				END IF
			}
			END IF
		BEFORE FIELD valor_cr 
			IF NOT modificable(r_ctas[i].cuenta) THEN
				NEXT FIELD b13_cuenta
			END IF
			LET credito = r_ctas[i].valor_cr
		AFTER FIELD valor_cr
			IF r_ctas[i].valor_cr IS NULL THEN
				LET r_ctas[i].valor_cr = 0
				DISPLAY r_ctas[i].valor_cr TO r_ctas[j].valor_cr
			END IF
			IF r_ctas[i].valor_cr > 0 THEN
				LET r_ctas[i].valor_db = 0
				DISPLAY r_ctas[i].valor_db TO r_ctas[j].valor_db
			END IF
			IF credito <> r_ctas[i].valor_cr OR credito IS NULL 
			THEN
				CALL inserta_tabla_temporal(r_ctas[i].cuenta,
					r_ctas[i].valor_db, r_ctas[i].valor_cr,
					'V') RETURNING tot_debito, tot_credito
				DISPLAY BY NAME tot_debito, tot_credito
			{
				IF cuenta_distribucion(vg_codcia, 
						       rm_cuenta[i].cuenta) 
				AND rm_cuenta[i].valor_credito > 0
				THEN
					CALL muestra_distribucion(vg_codcia,
						rm_cuenta[i].cuenta,
						rm_cuenta[i].valor_credito)
					LET int_flag = 0
				END IF
			}
			END IF
		AFTER INPUT
			IF tot_debito <> tot_credito THEN
				--CALL fgl_winmessage(vg_producto,'Los valores en el débito y el crédito deben ser iguales.','exclamation')
				CALL fl_mostrar_mensaje('Los valores en el débito y el crédito deben ser iguales.','exclamation')
				CONTINUE INPUT
			END IF
			IF tot_debito <> rm_j10.j10_valor THEN
				--CALL fgl_winmessage(vg_producto,'Los valores en el débito y el crédito deben ser iguales al total ingresado.','exclamation')
				CALL fl_mostrar_mensaje('Los valores en el débito y el crédito deben ser iguales al total ingresado.','exclamation')
				CONTINUE INPUT
			END IF
			LET salir = 1
	END INPUT
	IF int_flag THEN
		CLOSE WINDOW w_207_2
		RETURN r_b12.*
	END IF

	IF col IS NOT NULL AND NOT salir THEN
        	IF col <> columna_1 THEN
        	        LET columna_2        = columna_1
        	        LET orden[columna_2] = orden[columna_1]
        	        LET columna_1        = col
        	END IF
        	IF orden[columna_1] = 'ASC' THEN
        	        LET orden[columna_1] = 'DESC'
        	ELSE
        	        LET orden[columna_1] = 'ASC'
        	END IF
		INITIALIZE col TO NULL
	END IF
END WHILE	

CALL genera_comprobante_contable('DC') RETURNING r_b12.*
IF r_b12.b12_compania IS NULL THEN
	LET int_flag = 1
	CLOSE WINDOW w_207_2
	RETURN r_b12.*
END IF

DROP TABLE tmp_cuenta
CLOSE WINDOW w_207_2

RETURN r_b12.*

END FUNCTION



FUNCTION modificable(cuenta)

DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE return_value	SMALLINT
DEFINE flag		CHAR(1)

INITIALIZE flag TO NULL

SELECT te_flag INTO flag FROM tmp_cuenta WHERE te_cuenta = cuenta

LET return_value = 1
IF flag = 'F' THEN
	LET return_value = 0
END IF

RETURN return_value

END FUNCTION



FUNCTION inserta_tabla_temporal(cuenta, valor_db, valor_cr, flag)

DEFINE cuenta		LIKE ctbt013.b13_cuenta
DEFINE valor_db		LIKE ctbt013.b13_valor_base
DEFINE valor_cr		LIKE ctbt013.b13_valor_base
DEFINE flag		CHAR(1)

DEFINE query		CHAR(255)

DEFINE tot_debito	LIKE ctbt013.b13_valor_base
DEFINE tot_credito	LIKE ctbt013.b13_valor_base

CASE flag
	WHEN 'F'
		SELECT * FROM tmp_cuenta WHERE te_cuenta = cuenta
		IF STATUS = NOTFOUND THEN
			LET query = 'INSERT INTO tmp_cuenta ',
					'SELECT "', cuenta CLIPPED, 
					        '", b10_descripcion, ',
					        valor_db, ', ', valor_cr, 
					 ', 0, "', flag, '"',
				        '  FROM ctbt010 ',
					'  WHERE b10_compania = ',  vg_codcia,
					'    AND b10_cuenta   = "', 
							cuenta CLIPPED, '"' 
			PREPARE stmnt1 FROM query
			EXECUTE stmnt1
		END IF
	WHEN 'V'
		SELECT * FROM tmp_cuenta WHERE te_cuenta = cuenta
		IF STATUS = NOTFOUND THEN
			IF valor_db IS NULL THEN
				LET valor_db = 0
			END IF
			IF valor_cr IS NULL THEN
				LET valor_cr = 0
			END IF
			LET query = 'INSERT INTO tmp_cuenta ',
					'SELECT "', cuenta CLIPPED, 
					        '", b10_descripcion, ',
					        valor_db, ', ', valor_cr, 
					 ', 0, "', flag, '"',
				        '  FROM ctbt010 ',
					'  WHERE b10_compania = ',  vg_codcia,
					'    AND b10_cuenta   = "', 
							cuenta CLIPPED, '"' 
			PREPARE stmnt2 FROM query
			EXECUTE stmnt2
		ELSE
			UPDATE tmp_cuenta SET te_valor_db = valor_db,
					      te_valor_cr = valor_cr
				WHERE te_cuenta = cuenta
		END IF
END CASE

SELECT SUM(te_valor_db), SUM(te_valor_cr) 
	INTO tot_debito, tot_credito 
	FROM tmp_cuenta

RETURN tot_debito, tot_credito

END FUNCTION



FUNCTION genera_comprobante_contable(tipo_comp)

DEFINE r_b00		RECORD LIKE ctbt000.*
DEFINE r_b03		RECORD LIKE ctbt003.*
DEFINE r_b12		RECORD LIKE ctbt012.*

DEFINE tipo_comp	LIKE ctbt003.b03_tipo_comp

DEFINE glosa 		LIKE ctbt013.b13_glosa
DEFINE query		CHAR(500)
DEFINE expr_valor	CHAR(100)

CALL fl_lee_compania_contabilidad(vg_codcia) RETURNING r_b00.*

CALL fl_lee_tipo_comprobante_contable(vg_codcia, tipo_comp) RETURNING r_b03.*
IF r_b03.b03_compania IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'No existe tipo de comprobante para Egreso de caja: ' || tipo_comp,'exclamation')
	CALL fl_mostrar_mensaje('No existe tipo de comprobante para Egreso de caja: ' || tipo_comp,'exclamation')
	RETURN r_b12.*
END IF

LET glosa = rm_j10.j10_tipo_destino || ' - ' || rm_j10.j10_num_destino 

INITIALIZE r_b12.* TO NULL
LET r_b12.b12_compania    = vg_codcia  
-- OjO confirmar
LET r_b12.b12_tipo_comp   = r_b03.b03_tipo_comp
LET r_b12.b12_num_comp    = fl_numera_comprobante_contable(vg_codcia,
                            	r_b12.b12_tipo_comp, YEAR(TODAY), MONTH(TODAY))
LET r_b12.b12_estado      = 'A' 
LET r_b12.b12_glosa       = 'COMPROBANTE: ' || glosa CLIPPED || '. ' ||
			    rm_j10.j10_referencia CLIPPED 
LET r_b12.b12_origen      = 'A' 
LET r_b12.b12_moneda      = rm_j10.j10_moneda
LET r_b12.b12_paridad     = calcula_paridad(rm_j10.j10_moneda,
					    rg_gen.g00_moneda_base) 
LET r_b12.b12_fec_proceso = TODAY
LET r_b12.b12_modulo      = 'CG'                
LET r_b12.b12_usuario     = vg_usuario 
LET r_b12.b12_fecing      = CURRENT

INSERT INTO ctbt012 VALUES(r_b12.*)

--
IF r_b12.b12_moneda = r_b00.b00_moneda_base THEN
	LET expr_valor = ' (te_valor_cr * (-1)), 0 '
ELSE
	LET expr_valor = ' (te_valor_cr * (-1) * ', r_b12.b12_paridad, 
			 '), (te_valor_cr * (-1))'
END IF
--

LET query = 'INSERT INTO ctbt013 (b13_compania, b13_tipo_comp, b13_num_comp, ',
	    '			  b13_secuencia, b13_cuenta, ',
	    '			  b13_glosa, b13_valor_base, b13_valor_aux, ',
	    '			  b13_num_concil, b13_fec_proceso) ', 
	    '	SELECT ', vg_codcia, ', "', r_b12.b12_tipo_comp , '", "',
	    		r_b12.b12_num_comp CLIPPED, '", te_serial, te_cuenta, ',
	               '"', glosa CLIPPED, '", ',
	    		expr_valor CLIPPED, ',0, ', 
	    ' 		DATE("', r_b12.b12_fec_proceso, '")',
	    '		FROM tmp_cuenta ', 
	    '		WHERE te_valor_cr > 0 '
PREPARE stmnt3 FROM query
EXECUTE stmnt3

--
IF r_b12.b12_moneda = r_b00.b00_moneda_base THEN
	LET expr_valor = ' te_valor_db, 0 '
ELSE
	LET expr_valor = ' (te_valor_db * ', r_b12.b12_paridad, 
			 '), te_valor_db'
END IF
--
LET query = 'INSERT INTO ctbt013 (b13_compania, b13_tipo_comp, b13_num_comp, ',
	    '			  b13_secuencia, b13_cuenta, ',
	    '			  b13_glosa, b13_valor_base, b13_valor_aux, ',
	    '			  b13_num_concil, b13_fec_proceso) ', 
	    '	SELECT ', vg_codcia, ', "', r_b12.b12_tipo_comp , '", "',
	    		r_b12.b12_num_comp CLIPPED, '", te_serial, te_cuenta, ',
	    		'"', glosa CLIPPED, '", ',
	    		expr_valor CLIPPED, ', 0, ', 
	    ' 		DATE("', r_b12.b12_fec_proceso, '")',
	    '		FROM tmp_cuenta ', 
	    '		WHERE te_valor_db > 0 '
PREPARE stmnt4 FROM query
EXECUTE stmnt4

UPDATE cajt010 SET j10_tip_contable = r_b12.b12_tipo_comp,
		   j10_num_contable = r_b12.b12_num_comp
	WHERE j10_compania    = rm_j10.j10_compania
	  AND j10_localidad   = rm_j10.j10_localidad
	  AND j10_tipo_fuente = rm_j10.j10_tipo_fuente
	  AND j10_num_fuente  = rm_j10.j10_num_fuente

RETURN r_b12.*

END FUNCTION



FUNCTION imprime_comprobante()
DEFINE comando 		CHAR(300)
DEFINE run_prog		CHAR(10)

{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
LET comando = 'cd ..', vg_separador, '..', vg_separador,
	      'CAJA', vg_separador, 'fuentes', 
	      vg_separador, run_prog, 'cajp403 ', 
	      vg_base, ' ', 'CG', vg_codcia, ' ', 
	      vg_codloc, ' ', rm_j10.j10_num_fuente 

RUN comando

END FUNCTION



FUNCTION retorna_arreglo()
--#LET vm_size_arr = fgl_scr_size('ra_j11')
IF vg_gui = 0 THEN
        LET vm_size_arr = 5
END IF
                                                                                
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
DISPLAY '<F5>      Imprime Documento'        AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
