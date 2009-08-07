------------------------------------------------------------------------------
-- Titulo           : cajp207.4gl - Egreso de caja
-- Elaboracion      : 10-dic-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun cajp207 base modulo compania localidad
--		      [tipo_fuente num_fuente]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_programa	VARCHAR(12)

DEFINE vm_tipo_fuente	LIKE cajt010.j10_tipo_fuente
DEFINE vm_num_fuente	LIKE cajt010.j10_num_fuente

DEFINE vm_egr_caja	CHAR(2)
DEFINE vm_cheque	CHAR(2)
DEFINE vm_efectivo 	CHAR(2)

DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT

DEFINE vm_filas_pant	SMALLINT
DEFINE vm_rowid		INTEGER

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA r_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS

DEFINE vm_max_rows	SMALLINT
--
-- DEFINE RECORD(S) HERE
--
DEFINE rm_j04			RECORD LIKE cajt004.*
DEFINE rm_j05			RECORD LIKE cajt005.*
DEFINE rm_j10			RECORD LIKE cajt010.*

DEFINE saldo_ant_ef		LIKE cajt005.j05_ef_apertura
DEFINE saldo_ant_ch		LIKE cajt005.j05_ch_apertura

DEFINE saldo_hoy_ef		LIKE cajt005.j05_ef_apertura
DEFINE saldo_hoy_ch		LIKE cajt005.j05_ch_apertura

DEFINE vm_ind_egr		SMALLINT
DEFINE vm_max_egr		SMALLINT
DEFINE rm_egresos ARRAY[1000] OF RECORD
	tipo_fuente		LIKE cajt011.j11_tipo_fuente,
	num_fuente		LIKE cajt011.j11_num_fuente,
	num_ch			LIKE cajt011.j11_num_ch_aut,
	num_cta			LIKE cajt011.j11_num_cta_tarj,
	cod_bco			LIKE cajt011.j11_cod_bco_tarj,
	valor			LIKE cajt011.j11_valor,
	check			CHAR(1)
END RECORD



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
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

CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
LET vg_codloc   = arg_val(4)

LET vm_num_fuente = 0
IF num_args() = 6 THEN
	LET vm_tipo_fuente = arg_val(5)
	LET vm_num_fuente  = arg_val(6)
END IF

LET vm_programa = 'cajp207'
CALL fgl_settitle(vm_programa || ' - ' || vg_producto)
CALL fl_activar_base_datos(vg_base)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vm_programa)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

DEFINE i		SMALLINT

CALL fl_nivel_isolation()
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_207 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_207 FROM '../forms/cajf207_1'
DISPLAY FORM f_207

LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_j10.* TO NULL
CALL muestra_contadores()

LET vm_egr_caja = 'EC'
LET vm_cheque   = 'CH'
LET vm_efectivo = 'EF'

LET vm_max_egr  = 1000
LET vm_max_rows = 1000

CALL setea_nombre_botones_f1()

FOR i = 1 TO 10
       	LET rm_orden[i] = 'ASC'
END FOR

CREATE TEMP TABLE tmp_detalle(
	tipo_fuente		CHAR(2),
	num_fuente		INTEGER,
	num_cheque		VARCHAR(15),
	num_cta    		VARCHAR(25),
	cod_bco			SMALLINT,
	valor			DECIMAL(12,2),
	egresa			CHAR(1)
);
CREATE UNIQUE INDEX tmp_pk 
	ON tmp_detalle(tipo_fuente, num_fuente, num_cheque, num_cta, cod_bco);
	
IF vm_num_fuente <> 0 THEN
	CALL execute_query()
	CALL control_detalle()
	EXIT PROGRAM
END IF
	
	
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Eliminar'
		HIDE OPTION 'Detalle'
	COMMAND KEY('E') 'Egreso' 		'Realizar egreso de caja.'
		HIDE OPTION 'Detalle'
		CALL control_egreso()
		IF vm_num_rows = 1 THEN
			IF rm_j10.j10_estado <> 'E' THEN
				SHOW OPTION 'Eliminar'
			END IF
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
		IF vm_filas_pant < vm_ind_egr THEN
			SHOW OPTION 'Detalle'
		END IF
		CALL setea_nombre_botones_f1()
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro.'
		HIDE OPTION 'Detalle'
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			IF rm_j10.j10_estado <> 'E' THEN
				SHOW OPTION 'Eliminar'
			END IF
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Eliminar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			IF rm_j10.j10_estado <> 'E' THEN
				SHOW OPTION 'Eliminar'
			END IF
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
		IF vm_filas_pant < vm_ind_egr THEN
			SHOW OPTION 'Detalle'
		END IF
		CALL setea_nombre_botones_f1()
	COMMAND KEY('D') 'Detalle'		'Ver detalle egreso.'
		CALL control_detalle()
	COMMAND KEY('L') 'Eliminar'     	'Elimina un egreso.'
		CALL control_elimina()
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
		HIDE OPTION 'Detalle'
		HIDE OPTION 'Eliminar'
		CALL siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF rm_j10.j10_estado <> 'E' THEN
			SHOW OPTION 'Eliminar'
		END IF
		IF vm_filas_pant < vm_ind_egr THEN
			SHOW OPTION 'Detalle'
		END IF
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
		HIDE OPTION 'Detalle'
		HIDE OPTION 'Eliminar'
		CALL anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF rm_j10.j10_estado <> 'E' THEN
			SHOW OPTION 'Eliminar'
		END IF
		IF vm_filas_pant < vm_ind_egr THEN
			SHOW OPTION 'Detalle'
		END IF
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_egreso()

DEFINE rowid		SMALLINT
DEFINE intentar		SMALLINT
DEFINE done		SMALLINT

DEFINE r_j02		RECORD LIKE cajt002.*

CLEAR FORM
INITIALIZE rm_j10.* TO NULL

LET rm_j10.j10_fecing      = CURRENT
LET rm_j10.j10_fecha_pro   = rm_j10.j10_fecing
LET rm_j10.j10_usuario     = vg_usuario
LET rm_j10.j10_compania    = vg_codcia
LET rm_j10.j10_localidad   = vg_codloc
LET rm_j10.j10_tipo_fuente = vm_egr_caja
LET rm_j10.j10_estado      = 'A'
LET rm_j10.j10_valor       = 0
LET rm_j10.j10_moneda      = rg_gen.g00_moneda_base

CALL fl_retorna_caja(vg_codcia, vg_codloc, vg_usuario) RETURNING r_j02.*
IF r_j02.j02_codigo_caja IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'No hay una caja asignada al usuario ' || vg_usuario || '.',
		'stop')
	EXIT PROGRAM
END IF

LET rm_j10.j10_codigo_caja = r_j02.j02_codigo_caja 

BEGIN WORK
DECLARE q_caja CURSOR FOR
	SELECT * FROM cajt004
		WHERE j04_compania    = vg_codcia
		  AND j04_localidad   = vg_codloc
		  AND j04_codigo_caja = r_j02.j02_codigo_caja
		  AND j04_fecha_aper  = TODAY
		  AND j04_secuencia   = (SELECT MAX(j04_secuencia) 
		  				FROM cajt004
	  					WHERE j04_compania  = vg_codcia
	  				  	  AND j04_localidad = vg_codloc
	  					  AND j04_codigo_caja 
	  					  	= r_j02.j02_codigo_caja
	  					  AND j04_fecha_aper  = TODAY)

OPEN  q_caja
FETCH q_caja INTO rm_j04.*
IF STATUS = NOTFOUND THEN 
	CALL fgl_winmessage(vg_producto,
		'La caja no está aperturada.',
		'exclamation')
	ROLLBACK WORK
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	ELSE
		CLEAR FORM
	END IF
	RETURN
END IF

CALL lee_datos('I')
IF INT_FLAG THEN
	ROLLBACK WORK
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

SET LOCK MODE TO WAIT 5
WHENEVER ERROR CONTINUE
DECLARE q_j05 CURSOR FOR
	SELECT * FROM cajt005
		WHERE j05_compania    = rm_j04.j04_compania
		  AND j05_localidad   = rm_j04.j04_localidad
		  AND j05_codigo_caja = rm_j04.j04_codigo_caja
		  AND j05_fecha_aper  = rm_j04.j04_fecha_aper
		  AND j05_secuencia   = rm_j04.j04_secuencia
		  AND j05_moneda      = rm_j10.j10_moneda
	FOR UPDATE
OPEN  q_j05
FETCH q_j05 INTO rm_j05.*
IF STATUS = NOTFOUND THEN 
	WHENEVER ERROR STOP
	SET LOCK MODE TO NOT WAIT
	CALL fgl_winmessage(vg_producto,
		'La caja no está aperturada.',
		'exclamation')
	ROLLBACK WORK
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	ELSE
		CLEAR FORM
	END IF
	RETURN
END IF
WHENEVER ERROR STOP
SET LOCK MODE TO NOT WAIT

CALL ingresa_detalle()
IF INT_FLAG THEN
	ROLLBACK WORK
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET rm_j10.j10_estado = 'P'

SELECT MAX(j10_num_fuente) INTO rm_j10.j10_num_fuente
	FROM cajt010
	WHERE j10_compania    = vg_codcia
	  AND j10_localidad   = vg_codloc
	  AND j10_tipo_fuente = vm_egr_caja
IF rm_j10.j10_num_fuente IS NULL THEN
	LET rm_j10.j10_num_fuente = 1
ELSE
	LET rm_j10.j10_num_fuente = rm_j10.j10_num_fuente + 1
END IF

LET rm_j10.j10_nomcli    = 'Egreso de caja # ' || rm_j10.j10_num_fuente

LET rm_j10.j10_tipo_destino = rm_j10.j10_tipo_fuente
LET rm_j10.j10_num_destino  = rm_j10.j10_num_fuente

INSERT INTO cajt010 VALUES (rm_j10.*)
DISPLAY BY NAME rm_j10.j10_num_fuente

LET rowid = SQLCA.SQLERRD[6] 		-- Rowid de la ultima fila 
                                        -- procesada
CALL actualiza_detalle()

CALL actualiza_acumulados_caja('I')
CALL actualiza_acumulados_tipo_transaccion('I')

COMMIT WORK

IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF
LET vm_row_current = vm_num_rows
LET vm_rows[vm_num_rows] = rowid

CALL muestra_contadores()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION lee_datos(flag)

DEFINE flag 		CHAR(1)
DEFINE resp 		CHAR(6)

DEFINE nro_cta		LIKE gent009.g09_numero_cta
DEFINE dummy		LIKE gent008.g08_nombre
DEFINE moneda		LIKE gent013.g13_moneda

DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_g09		RECORD LIKE gent009.*
DEFINE r_mon		RECORD LIKE gent013.*

LET INT_FLAG = 0
INPUT BY NAME rm_j10.j10_tipo_fuente, rm_j10.j10_num_fuente, rm_j10.j10_fecing,
	      rm_j10.j10_numero_cta,  rm_j10.j10_banco, rm_j10.j10_moneda,
	      rm_j10.j10_referencia,  saldo_ant_ef, saldo_ant_ch, saldo_hoy_ef, 
	      saldo_hoy_ch, rm_j10.j10_valor, rm_j10.j10_usuario, 
	      rm_j10.j10_codigo_caja, rm_j10.j10_estado
	      WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(j10_numero_cta, j10_banco, j10_referencia, 
			             j10_valor
                                    ) THEN
			RETURN
		END IF

		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN
		END IF
	ON KEY(F2)
		IF INFIELD(j10_banco) THEN
			CALL fl_ayuda_bancos() RETURNING r_g08.g08_banco,
							 r_g08.g08_nombre
			IF r_g08.g08_banco IS NOT NULL THEN
				LET rm_j10.j10_banco = r_g08.g08_banco
				DISPLAY BY NAME rm_j10.j10_banco
				DISPLAY r_g08.g08_banco TO n_banco
			END IF
		END IF
		IF INFIELD(j10_numero_cta) THEN
			CALL fl_ayuda_cuenta_banco(vg_codcia) 
				RETURNING r_g09.g09_banco, dummy, 
				          r_g09.g09_tipo_cta, 
				          r_g09.g09_numero_cta 
			IF r_g09.g09_numero_cta IS NOT NULL THEN
				LET rm_j10.j10_banco = r_g09.g09_banco
				LET rm_j10.j10_numero_cta = 
					r_g09.g09_numero_cta
				DISPLAY BY NAME rm_j10.j10_banco, 
					        rm_j10.j10_numero_cta
				DISPLAY dummy TO n_banco
			END IF	
		END IF
		IF INFIELD(j10_moneda) THEN
			CALL fl_ayuda_monedas() RETURNING r_mon.g13_moneda,
							  r_mon.g13_nombre,
							  r_mon.g13_decimales
			IF r_mon.g13_moneda IS NOT NULL THEN
				LET rm_j10.j10_moneda = r_mon.g13_moneda
				DISPLAY BY NAME rm_j10.j10_moneda
				DISPLAY r_mon.g13_nombre TO n_moneda
			END IF
		END IF
		LET INT_FLAG = 0
	BEFORE INPUT
		LET vm_filas_pant = fgl_scr_size('ra_egresos')
		CALL setea_nombre_botones_f1()
		CALL muestra_etiquetas()
	AFTER FIELD j10_banco
		IF rm_j10.j10_banco IS NULL THEN
			INITIALIZE rm_j10.j10_numero_cta TO NULL
			DISPLAY BY NAME rm_j10.j10_numero_cta
			CLEAR n_banco
		ELSE
			CALL fl_lee_banco_general(rm_j10.j10_banco) 
				RETURNING r_g08.*
			IF r_g08.g08_banco IS NULL THEN	
				CLEAR n_banco
				INITIALIZE rm_j10.j10_numero_cta TO NULL
				DISPLAY BY NAME rm_j10.j10_numero_cta
				CALL fgl_winmessage(vg_producto,
					            'Banco no existe.',
						    'exclamation')
				NEXT FIELD j10_banco
			ELSE
				DISPLAY r_g08.g08_nombre TO n_banco
			END IF 
		END IF
	AFTER FIELD j10_numero_cta
		IF rm_j10.j10_numero_cta IS NULL THEN
			INITIALIZE rm_j10.j10_banco TO NULL
			DISPLAY BY NAME rm_j10.j10_banco
			CONTINUE INPUT
		ELSE
			IF rm_j10.j10_banco IS NULL THEN
				CALL fgl_winmessage(vg_producto,
					'Debe ingresar un banco primero.',
					'exclamation')
				INITIALIZE rm_j10.j10_numero_cta TO NULL
				DISPLAY BY NAME rm_j10.j10_numero_cta
				NEXT FIELD j10_banco
			END IF
			LET nro_cta = rm_j10.j10_numero_cta
			CALL fl_lee_banco_compania(vg_codcia, rm_j10.j10_banco,
				rm_j10.j10_numero_cta) RETURNING r_g09.*
			IF r_g09.g09_numero_cta IS NULL THEN
				CALL fgl_winmessage(vg_producto,
					'No existe cuenta en este banco.',
					'exclamation')
				LET rm_j10.j10_numero_cta = nro_cta
				NEXT FIELD j10_numero_cta
			END IF
			IF r_g09.g09_estado = 'B' THEN
				CALL fgl_winmessage(vg_producto,
					'La cuenta está bloqueada.',
					'exclamation')
				NEXT FIELD j10_numero_cta
			END IF
			CALL fl_lee_moneda(r_g09.g09_moneda) RETURNING r_mon.*
			LET rm_j10.j10_moneda = r_mon.g13_moneda
			DISPLAY BY NAME rm_j10.j10_moneda
			DISPLAY r_mon.g13_nombre TO n_moneda
			
			CALL obtener_saldos()
			IF INT_FLAG THEN
				RETURN
			END IF
				   
			DISPLAY BY NAME saldo_ant_ef, saldo_ant_ch, 
					saldo_hoy_ef, saldo_hoy_ch
		END IF
	BEFORE FIELD j10_moneda
		LET moneda = rm_j10.j10_moneda
	AFTER FIELD j10_moneda
		IF rm_j10.j10_moneda IS NULL THEN
			CLEAR n_moneda
			CONTINUE INPUT
		END IF
		CALL fl_lee_moneda(rm_j10.j10_moneda) RETURNING r_mon.*
		IF r_mon.g13_moneda IS NULL THEN	
			CALL fgl_winmessage(vg_producto, 
                        	'Moneda no existe.',
                        	'exclamation')
			CLEAR n_moneda
			NEXT FIELD j10_moneda
		ELSE
			IF r_mon.g13_estado = 'B' THEN
				CALL fgl_winmessage(vg_producto, 
                         		'Moneda está bloqueada.',
                                       	'exclamation')
				CLEAR n_moneda
				NEXT FIELD j10_moneda
			ELSE
				DISPLAY r_mon.g13_nombre TO n_moneda
				CALL obtener_saldos()
				IF INT_FLAG THEN
					RETURN
				END IF
				   
				DISPLAY BY NAME saldo_ant_ef, saldo_ant_ch, 
						saldo_hoy_ef, saldo_hoy_ch
			END IF
		END IF 
		IF rm_j10.j10_moneda <> moneda THEN
			INITIALIZE rm_j10.j10_numero_cta TO NULL
			INITIALIZE rm_j10.j10_banco      TO NULL
			DISPLAY BY NAME rm_j10.j10_numero_cta,
					rm_j10.j10_banco
			CLEAR n_banco
		END IF
	AFTER FIELD j10_valor
		IF rm_j10.j10_valor IS NULL THEN
			LET rm_j10.j10_valor = 0
			DISPLAY BY NAME rm_j10.j10_valor
			CONTINUE INPUT
		END IF
		IF rm_j10.j10_valor < 0 THEN
			CALL fgl_winmessage(vg_producto,
				'Debe digitar valores positivos.',
				'exclamation')
			NEXT FIELD j10_valor
		END IF
		IF rm_j10.j10_valor > saldo_hoy_ef THEN
			CALL fgl_winmessage(vg_producto,
				'No puede egresar una valor mayor al que ' ||
				'existe en la caja.',
				'exclamation')
			NEXT FIELD j10_valor
		END IF
END INPUT
IF INT_FLAG THEN
	RETURN
END IF

END FUNCTION



FUNCTION obtener_saldos()

IF NOT caja_aperturada(rm_j10.j10_moneda) THEN
	LET INT_FLAG = 1
	RETURN
END IF
			
SELECT j05_ef_apertura, j05_ch_apertura,
	(j05_ef_apertura + j05_ef_ing_dia - j05_ef_egr_dia),
	(j05_ch_apertura + j05_ch_ing_dia - j05_ch_egr_dia)
	INTO saldo_ant_ef, saldo_ant_ch, saldo_hoy_ef, saldo_hoy_ch
	FROM cajt005
	WHERE j05_compania    = rm_j04.j04_compania
	  AND j05_localidad   = rm_j04.j04_localidad
	  AND j05_codigo_caja = rm_j04.j04_codigo_caja
	  AND j05_fecha_aper  = rm_j04.j04_fecha_aper
	  AND j05_secuencia   = rm_j04.j04_secuencia
	  AND j05_moneda      = rm_j10.j10_moneda

END FUNCTION



FUNCTION control_consulta()

DEFINE expr_sql			VARCHAR(500)
DEFINE query			VARCHAR(600)

DEFINE dummy			LIKE gent008.g08_nombre
	
DEFINE r_g13			RECORD LIKE gent013.*
DEFINE r_j10			RECORD LIKE cajt010.*
DEFINE r_g08			RECORD LIKE gent008.*
DEFINE r_g09			RECORD LIKE gent009.*

CLEAR FORM

LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql 
	ON j10_num_fuente, j10_estado, j10_numero_cta,
	   j10_banco, j10_moneda, j10_referencia, j10_valor, 
	   j10_codigo_caja, j10_usuario
	ON KEY(F2)
		IF INFIELD(j10_num_fuente) THEN
			CALL fl_ayuda_numero_fuente_caja(vg_codcia, vg_codloc,
				vm_egr_caja) RETURNING r_j10.j10_num_fuente,
					  	       r_j10.j10_nomcli,
					  	       r_j10.j10_valor
			IF r_j10.j10_num_fuente IS NOT NULL THEN
				LET rm_j10.j10_num_fuente 
					= r_j10.j10_num_fuente
				DISPLAY BY NAME rm_j10.j10_num_fuente
			END IF
		END IF
		IF INFIELD(j10_banco) THEN
			CALL fl_ayuda_bancos() RETURNING r_g08.g08_banco,
							 r_g08.g08_nombre
			IF r_g08.g08_banco IS NOT NULL THEN
				LET rm_j10.j10_banco = r_g08.g08_banco
				DISPLAY BY NAME rm_j10.j10_banco
				DISPLAY r_g08.g08_banco TO n_banco
			END IF
		END IF
		IF INFIELD(j10_numero_cta) THEN
			CALL fl_ayuda_cuenta_banco(vg_codcia) 
				RETURNING r_g09.g09_banco, dummy, 
				          r_g09.g09_tipo_cta, 
				          r_g09.g09_numero_cta 
			IF r_g09.g09_numero_cta IS NOT NULL THEN
				LET rm_j10.j10_banco = r_g09.g09_banco
				LET rm_j10.j10_numero_cta = 
					r_g09.g09_numero_cta
				DISPLAY BY NAME rm_j10.j10_banco, 
					        rm_j10.j10_numero_cta
				DISPLAY dummy TO n_banco
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
	BEFORE CONSTRUCT
		CALL setea_nombre_botones_f1()
END CONSTRUCT

IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET query = 'SELECT *, ROWID FROM cajt010 ',
	    '	WHERE j10_compania    = ',  vg_codcia, 
	    '	  AND j10_localidad   = ',  vg_codloc,
	    '	  AND j10_tipo_fuente = "', vm_egr_caja, '"',
	    '	  AND ', expr_sql,
	    '	ORDER BY 1, 2, 3, 4'
	    
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_j10.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > 1000 THEN
		EXIT FOREACH
	END IF	
END FOREACH 
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN 
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_num_rows = 0
	LET vm_row_current = 0
	CALL muestra_contadores()
	CLEAR FORM
	RETURN
END IF

LET vm_row_current = 1
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION control_elimina()

DEFINE resp    		CHAR(6)
DEFINE estado		CHAR(1)

DEFINE tot_egr_ch	DECIMAL(12,2)

DEFINE num_fuente 	LIKE cajt010.j10_num_fuente

LET int_flag = 0
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

CALL lee_muestra_registro(vm_rows[vm_row_current])

IF rm_j10.j10_estado = 'E' THEN
	CALL fgl_winmessage(vg_producto,
		'Este registro ya ha sido eliminado.',
		'exclamation')
	RETURN
END IF

IF DATE(rm_j10.j10_fecha_pro) <> TODAY THEN
	CALL fgl_winmessage(vg_producto, 
		'Solo puede eliminar egresos realizados hoy.',
		'exclamation')
	RETURN
END IF

IF NOT caja_aperturada(rm_j10.j10_moneda) THEN
	CALL fgl_winmessage(vg_producto, 
		'No puede eliminar egresos de una caja cerrada.',
		'exclamation')
	RETURN
END IF
		
CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
IF resp = 'Yes' THEN
	SET LOCK MODE TO WAIT 10
	WHENEVER ERROR CONTINUE
	BEGIN WORK
	DECLARE q_del CURSOR FOR SELECT * FROM cajt010 
		WHERE ROWID = vm_rows[vm_row_current]
		FOR UPDATE
	OPEN q_del
	FETCH q_del INTO rm_j10.*
	IF status < 0 THEN
		WHENEVER ERROR STOP
		SET LOCK MODE TO NOT WAIT 
		CALL fl_mensaje_bloqueo_otro_usuario()
		ROLLBACK WORK
		RETURN
	END IF
	WHENEVER ERROR STOP
	SET LOCK MODE TO NOT WAIT 

	LET estado = 'E'
	
	CALL actualiza_acumulados_caja('D')
	CALL actualiza_acumulados_tipo_transaccion('D')
	CALL elimina_comprobante_contable()

	UPDATE cajt010 SET j10_estado = estado WHERE CURRENT OF q_del
	
	LET num_fuente = rm_j10.j10_num_fuente
	INITIALIZE rm_j10.j10_num_fuente TO NULL
	CALL actualiza_detalle()
	LET rm_j10.j10_num_fuente = num_fuente 
	
	COMMIT WORK
	CLOSE q_del
	LET int_flag = 0 
	
	CALL fl_mensaje_registro_modificado()

	CLEAR FORM
	CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION lee_muestra_registro(row)
DEFINE row 		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF

CLEAR FORM

SELECT * INTO rm_j10.* FROM cajt010 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

DISPLAY BY NAME rm_j10.j10_tipo_fuente, 
		rm_j10.j10_num_fuente, 
		rm_j10.j10_fecing,
		rm_j10.j10_estado,
	      	rm_j10.j10_numero_cta, 
	      	rm_j10.j10_banco, 
	      	rm_j10.j10_moneda,
	      	rm_j10.j10_codigo_caja, 
	      	rm_j10.j10_referencia,
	      	rm_j10.j10_valor, 
	      	rm_j10.j10_usuario 
	      	
CALL muestra_etiquetas()
CALL muestra_contadores()
CALL muestra_detalle()

END FUNCTION



FUNCTION muestra_contadores()

DISPLAY "" AT 1,1
DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 68 

END FUNCTION



FUNCTION siguiente_registro()

IF vm_num_rows = 0 THEN
	RETURN
END IF

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION anterior_registro()

IF vm_num_rows = 0 THEN
	RETURN
END IF

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION muestra_etiquetas()

DEFINE nom_estado		CHAR(9)

DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_j02		RECORD LIKE cajt002.*

CASE rm_j10.j10_estado 
	WHEN 'A' 
		LET nom_estado = 'ACTIVO'
	WHEN 'P'
		LET nom_estado = 'PROCESADO'
	WHEN 'E'
		LET nom_estado = 'ELIMINADO'
END CASE

CALL fl_lee_codigo_caja_caja(vg_codcia, vg_codloc, rm_j10.j10_codigo_caja)
	RETURNING r_j02.*
CALL fl_lee_moneda(rm_j10.j10_moneda) 		RETURNING r_g13.*
CALL fl_lee_banco_general(rm_j10.j10_banco)	RETURNING r_g08.*
	
DISPLAY r_j02.j02_nombre_caja	TO 	n_caja
DISPLAY r_g13.g13_nombre	TO	n_moneda
DISPLAY r_g08.g08_nombre	TO	n_banco
DISPLAY nom_estado		TO 	n_estado

END FUNCTION



FUNCTION setea_nombre_botones_f1()

DISPLAY 'Tp'		TO		bt_tipo
DISPLAY 'Num.'		TO		bt_num
DISPLAY 'Num. Cheque'	TO		bt_cheque
DISPLAY 'Cta. Cte.'	TO		bt_cta_cte
DISPLAY 'Ban.'		TO 		bt_banco
DISPLAY 'Valor'		TO 		bt_valor
DISPLAY 'E'		TO		bt_check

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



FUNCTION lee_cajt011()

DELETE FROM tmp_detalle

INSERT INTO tmp_detalle
	SELECT j11_tipo_fuente,  j11_num_fuente,   j11_num_ch_aut, 
	       j11_num_cta_tarj, j11_cod_bco_tarj, j11_valor, 'N'
	FROM cajt010, cajt011
	WHERE j10_compania    = vg_codcia
	  AND j10_localidad   = vg_codloc
	  AND j10_codigo_caja = rm_j05.j05_codigo_caja
	  AND j11_compania    = j10_compania
	  AND j11_localidad   = j10_localidad
	  AND j11_tipo_fuente = j10_tipo_fuente
	  AND j11_num_fuente  = j10_num_fuente
	  AND j11_moneda      = rm_j05.j05_moneda
	  AND j11_codigo_pago = vm_cheque
	  AND j11_num_egreso IS NULL

SELECT COUNT(*) INTO vm_ind_egr FROM tmp_detalle

END FUNCTION



FUNCTION ingresa_detalle()

DEFINE resp		CHAR(6)
DEFINE i		SMALLINT
DEFINE j		SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT
DEFINE query		CHAR(255)

DEFINE k, m 		SMALLINT -- GVA

DEFINE c		CHAR(1)

DEFINE tot_egreso_ch	DECIMAL(12,2)

CALL lee_cajt011()
IF vm_ind_egr = 0 THEN
	CALL fgl_winmessage(vg_producto,
		'No se han ingresado cheques a esta caja.',
		'exclamation')
	RETURN
END IF

LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET rm_orden[vm_columna_1]  = 'ASC'
LET rm_orden[vm_columna_2]  = 'ASC'
INITIALIZE col TO NULL

LET tot_egreso_ch  = 0 

DISPLAY BY NAME tot_egreso_ch

OPTIONS 
	INSERT KEY F40,
	DELETE KEY F41

LET salir = 0
WHILE NOT salir
        LET query = 'SELECT * FROM tmp_detalle ',
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
        PREPARE deto FROM query
        DECLARE q_deto CURSOR FOR deto 
        LET i = 1
        FOREACH q_deto INTO rm_egresos[i].*
                LET i = i + 1
                IF i > vm_max_egr THEN
                	CALL fl_mensaje_arreglo_incompleto()
                	LET INT_FLAG = 1
                        RETURN
                END IF
        END FOREACH
        
        LET i = 1
        LET j = 1
        LET INT_FLAG = 0
	IF vm_ind_egr > 0 THEN
		CALL set_count(vm_ind_egr)
	END IF
	INPUT ARRAY rm_egresos WITHOUT DEFAULTS FROM ra_egresos.*
		ON KEY(INTERRUPT)
			LET INT_FLAG = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET INT_FLAG = 1
				EXIT INPUT
			END IF
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
		ON KEY(F19)
			LET col = 5
			EXIT INPUT
		ON KEY(F20)
			LET col = 6
			EXIT INPUT
		ON KEY(F21)
			LET col = 7
			EXIT INPUT
		BEFORE INPUT
			CALL dialog.keysetlabel('INSERT', '')
			CALL dialog.keysetlabel('DELETE', '')
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
		BEFORE FIELD check
			LET c = rm_egresos[i].check
		AFTER FIELD check
			IF c <> rm_egresos[i].check THEN
				IF rm_egresos[i].check = 'S' THEN
					LET tot_egreso_ch =
						tot_egreso_ch + 
						rm_egresos[i].valor
				END IF
				IF rm_egresos[i].check = 'N' THEN
					LET tot_egreso_ch =
						tot_egreso_ch -
						rm_egresos[i].valor
				END IF
				DISPLAY BY NAME tot_egreso_ch
			
				CALL actualiza_check(i)
					
				NEXT FIELD ra_egresos[j].check
			END IF
		AFTER INPUT
			IF rm_j10.j10_valor > 0 THEN
				LET salir = 1
			ELSE
				LET m = 0
				FOR k = 1 TO vm_ind_egr 
					IF rm_egresos[k].check = 'S' THEN
						LET m = 1	 
						EXIT FOR
					END IF
				END FOR 
				IF m= 1 THEN
					LET salir = 1
				ELSE 
					CALL fgl_winmessage(vg_producto,'No ha digistado ningun valor de egreso.','exclamation')
					CONTINUE INPUT
				END IF	
			END IF	
	END INPUT
	IF INT_FLAG THEN
		RETURN
	END IF

	IF col IS NOT NULL AND NOT salir THEN
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
		INITIALIZE col TO NULL
	END IF
END WHILE	

END FUNCTION



FUNCTION actualiza_check(i)

DEFINE i		SMALLINT

UPDATE tmp_detalle SET egresa = rm_egresos[i].check
	WHERE tipo_fuente = rm_egresos[i].tipo_fuente
	  AND num_fuente  = rm_egresos[i].num_fuente
	  AND num_cheque  = rm_egresos[i].num_ch
	  AND num_cta     = rm_egresos[i].num_cta
	  AND cod_bco     = rm_egresos[i].cod_bco

END FUNCTION



FUNCTION actualiza_detalle()

DEFINE num_egreso	LIKE cajt011.j11_num_egreso

INITIALIZE num_egreso TO NULL
SET LOCK MODE TO WAIT 3
WHENEVER ERROR CONTINUE
DECLARE q_det CURSOR FOR
	SELECT j11_num_egreso FROM cajt011
		WHERE j11_compania     = vg_codcia
	  	  AND j11_localidad    = vg_codcia
	  	  AND EXISTS (SELECT j11_tipo_fuente, j11_num_fuente, 
	  			   j11_num_ch_aut,  j11_num_cta_tarj, 
	  			   j11_cod_bco_tarj
		  	     	FROM tmp_detalle
			     	WHERE egresa           = 'S'
			      	  AND j11_compania     = vg_codcia
			       	  AND j11_localidad    = vg_codloc
			    	  AND j11_tipo_fuente  = tipo_fuente
			     	  AND j11_num_fuente   = num_fuente
			     	  AND j11_num_ch_aut   = num_cheque
			     	  AND j11_num_cta_tarj = num_cta
			     	  AND j11_cod_bco_tarj = cod_bco)
	FOR UPDATE OF j11_num_egreso
OPEN  q_det
FETCH q_det INTO num_egreso
WHENEVER ERROR STOP
SET LOCK MODE TO NOT WAIT

IF STATUS < 0 THEN
	CALL fl_mensaje_bloqueo_otro_usuario()
	ROLLBACK WORK
	EXIT PROGRAM
END IF

WHILE (STATUS <> NOTFOUND)
	UPDATE cajt011 SET j11_num_egreso = rm_j10.j10_num_fuente
		WHERE CURRENT OF q_det
	
	INITIALIZE num_egreso TO NULL
	FETCH q_det INTO num_egreso
END WHILE  
CLOSE q_det
FREE  q_det

END FUNCTION



FUNCTION actualiza_acumulados_caja(flag)

DEFINE flag 		CHAR(1)
-- I: actualizacion en incremento
-- D: actualizacion en decremento (se multiplica por menos uno [-1])

DEFINE tot_egr_ch	LIKE cajt005.j05_ch_egr_dia
DEFINE tot_egr_ef	LIKE cajt005.j05_ef_egr_dia

SELECT SUM(valor) INTO tot_egr_ch FROM tmp_detalle WHERE egresa = 'S'
IF tot_egr_ch IS NULL THEN 
	LET tot_egr_ch = 0
END IF

LET tot_egr_ef = rm_j10.j10_valor

IF flag = 'D' THEN
	LET tot_egr_ch = tot_egr_ch * (-1)
	LET tot_egr_ef = tot_egr_ef * (-1)
END IF

UPDATE cajt005 SET j05_ef_egr_dia = j05_ef_egr_dia + tot_egr_ef,
    		   j05_ch_egr_dia = j05_ch_egr_dia + tot_egr_ch
	WHERE CURRENT OF q_j05
	
CLOSE q_j05
FREE  q_j05

END FUNCTION



FUNCTION actualiza_acumulados_tipo_transaccion(flag)

DEFINE flag 		CHAR(1)
-- I: actualizacion en incremento
-- D: actualizacion en decremento (se multiplica por menos uno [-1])

DEFINE codigo_pago	LIKE cajt013.j13_codigo_pago
DEFINE salir		SMALLINT
DEFINE valor_aux	LIKE cajt013.j13_valor
DEFINE r_j13		RECORD LIKE cajt013.*

SELECT SUM(valor) INTO valor_aux FROM tmp_detalle WHERE egresa = 'S'
IF valor_aux IS NULL THEN
	LET valor_aux = 0
END IF

LET salir = 0
LET codigo_pago = vm_cheque

WHILE NOT salir
	IF flag = 'D' THEN
		LET valor_aux = valor_aux * (-1)
	END IF

	INITIALIZE r_j13.* TO NULL
	SET LOCK MODE TO WAIT 3
	WHENEVER ERROR CONTINUE
		DECLARE q_j13 CURSOR FOR 
			SELECT * FROM cajt013
				WHERE j13_compania     = vg_codcia
				  AND j13_localidad    = vg_codloc
				  AND j13_codigo_caja  = rm_j10.j10_codigo_caja
				  AND j13_fecha        = TODAY
		 		  AND j13_moneda       = rm_j10.j10_moneda
				  AND j13_trn_generada = vm_egr_caja
				  AND j13_codigo_pago  = codigo_pago
			FOR UPDATE
	OPEN  q_j13
	FETCH q_j13 INTO r_j13.*
	WHENEVER ERROR STOP
	SET LOCK MODE TO NOT WAIT
	
	IF STATUS < 0 THEN
		CALL fgl_winmessage(vg_producto,
			'No se pueden actualizar los acumulados.',
			'exclamation')
		ROLLBACK WORK
		EXIT PROGRAM
	END IF

	IF NOT (STATUS = NOTFOUND) THEN
		UPDATE cajt013 SET j13_valor = j13_valor + valor_aux
			WHERE CURRENT OF q_j13
	END IF
	CLOSE q_j13
	FREE  q_j13
	
	IF codigo_pago = vm_cheque THEN
		LET codigo_pago = vm_efectivo
		LET valor_aux = rm_j10.j10_valor
	ELSE
		LET salir = 1
	END IF
END WHILE

END FUNCTION



FUNCTION muestra_detalle()

DEFINE i		SMALLINT
DEFINE filas_pant	SMALLINT
DEFINE tot_egr_ch	DECIMAL(12,2)

LET filas_pant = fgl_scr_size('ra_cuenta')
LET vm_filas_pant = filas_pant
FOR i = 1 TO filas_pant
	CLEAR ra_egresos[i].*
END FOR

CALL lee_detalle()
IF vm_ind_egr = 0 THEN
	RETURN
END IF

IF vm_ind_egr < filas_pant THEN
	LET filas_pant = vm_ind_egr
END IF

DECLARE q_tmp1 CURSOR FOR SELECT * FROM tmp_detalle ORDER BY 1 , 2
		
LET i = 1
FOREACH q_tmp1 INTO rm_egresos[i].*
	DISPLAY rm_egresos[i].* TO ra_egresos[i].*
	LET i = i + 1
	IF i > filas_pant THEN
		EXIT FOREACH
	END IF
END FOREACH

SELECT SUM(valor) INTO tot_egr_ch FROM tmp_detalle WHERE egresa = 'S'

DISPLAY tot_egr_ch TO tot_egreso_ch

END FUNCTION



FUNCTION lee_detalle()

DELETE FROM tmp_detalle

INSERT INTO tmp_detalle
	SELECT j11_tipo_fuente, j11_num_fuente, j11_num_ch_aut, 
	       j11_num_cta_tarj, j11_cod_bco_tarj, j11_valor, 'S'
	 	FROM cajt011 
	 	WHERE j11_compania    = vg_codcia
	 	  AND j11_localidad   = vg_codloc
	 	  AND j11_codigo_pago = vm_cheque
	 	  AND j11_num_egreso  = rm_j10.j10_num_fuente
	       
SELECT COUNT(*) INTO vm_ind_egr FROM tmp_detalle

END FUNCTION



FUNCTION control_detalle()

DEFINE i		SMALLINT
DEFINE j		SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT
DEFINE query		CHAR(255)

LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET rm_orden[vm_columna_1]  = 'ASC'
LET rm_orden[vm_columna_2]  = 'ASC'
INITIALIZE col TO NULL

LET salir = 0
WHILE NOT salir
        LET query = 'SELECT * FROM tmp_detalle ',
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
        PREPARE deto2 FROM query
        DECLARE q_deto2 CURSOR FOR deto2 
        LET i = 1
        FOREACH q_deto2 INTO rm_egresos[i].*
                LET i = i + 1
                IF i > vm_max_egr THEN
                        EXIT FOREACH
                END IF
        END FOREACH
        LET vm_ind_egr = i - 1
        
        LET i = 1
        LET j = 1
        LET INT_FLAG = 0
	CALL set_count(vm_ind_egr)
	DISPLAY ARRAY rm_egresos TO ra_egresos.*
		ON KEY(INTERRUPT)
			EXIT DISPLAY
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
		BEFORE DISPLAY
			CALL dialog.keysetlabel('ACCEPT', '')
		AFTER DISPLAY
			CONTINUE DISPLAY
	END DISPLAY
	IF INT_FLAG THEN
		LET salir = 1
		LET INT_FLAG = 0
		CONTINUE WHILE
	END IF

	IF col IS NOT NULL AND NOT salir THEN
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
		INITIALIZE col TO NULL
	END IF
END WHILE	

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



FUNCTION execute_query()

LET vm_num_rows    = 1
LET vm_row_current = 1

SELECT ROWID INTO vm_rows[vm_num_rows]
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
	CALL lee_muestra_registro(vm_rows[vm_num_rows])
END IF

END FUNCTION



FUNCTION elimina_comprobante_contable()

DEFINE r_b12		RECORD LIKE ctbt012.*

INITIALIZE r_b12.* TO NULL
SET LOCK MODE TO WAIT 10
WHENEVER ERROR CONTINUE
DECLARE q_ctb CURSOR FOR
	SELECT * FROM ctbt012
		WHERE b12_compania  = rm_j10.j10_compania
		  AND b12_tipo_comp = rm_j10.j10_tip_contable
		  AND b12_num_comp  = rm_j10.j10_num_contable
FOR UPDATE
OPEN  q_ctb
FETCH q_ctb INTO r_b12.*
IF STATUS < 0 THEN
	WHENEVER ERROR STOP
	SET LOCK MODE TO NOT WAIT
	CALL fgl_winmessage(vg_producto, 
		'No se pudo eliminar el comprobante contable, porque está ' ||
		'bloqueado por otro usuario.',
		'exclamation')
	ROLLBACK WORK
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
SET LOCK MODE TO NOT WAIT

UPDATE ctbt012 SET b12_estado = 'E' WHERE CURRENT OF q_ctb
CLOSE q_ctb
FREE  q_ctb

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
