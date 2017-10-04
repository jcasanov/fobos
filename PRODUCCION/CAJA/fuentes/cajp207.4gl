--------------------------------------------------------------------------------
-- Titulo           : cajp207.4gl - Egreso de caja
-- Elaboracion      : 10-dic-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun cajp207 base modulo compania localidad
--		      [tipo_fuente num_fuente]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_tipo_fuente	LIKE cajt010.j10_tipo_fuente
DEFINE vm_num_fuente	LIKE cajt010.j10_num_fuente

DEFINE vm_egr_caja	CHAR(2)
DEFINE vm_che_cp	CHAR(2)
DEFINE vm_cheque	CHAR(2)
DEFINE vm_efectivo 	CHAR(2)

DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT

DEFINE vm_filas_pant	SMALLINT
DEFINE vm_rowid		INTEGER
DEFINE vm_size_arr	INTEGER

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA r_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS

DEFINE vm_max_rows	SMALLINT
DEFINE vm_eg_mix	SMALLINT
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
DEFINE rm_egresos		ARRAY[32767] OF RECORD
				       tipo_fuente LIKE cajt011.j11_tipo_fuente,
					num_fuente LIKE cajt011.j11_num_fuente,
					num_ch	   LIKE cajt011.j11_num_ch_aut,
					num_cta	  LIKE cajt011.j11_num_cta_tarj,
					cod_bco	  LIKE cajt011.j11_cod_bco_tarj,
					fecha	   DATE,
					valor	   LIKE cajt011.j11_valor,
					check	   CHAR(1)
				END RECORD



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cajp207.err')
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
LET vg_proceso = 'cajp207'

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
DEFINE i		SMALLINT
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
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
OPEN WINDOW w_207 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
        OPEN FORM f_207 FROM '../forms/cajf207_1'
ELSE
        OPEN FORM f_207 FROM '../forms/cajf207_1c'
END IF
DISPLAY FORM f_207

LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_j10.* TO NULL
CALL muestra_contadores()

LET vm_egr_caja = 'EC'
LET vm_che_cp   = 'CP'
LET vm_cheque   = 'CH'
LET vm_efectivo = 'EF'

LET vm_max_egr  = 32767
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
	fecha			DATE,
	valor			DECIMAL(12,2),
	egresa			CHAR(1)
);
CREATE UNIQUE INDEX tmp_pk 
	ON tmp_detalle(tipo_fuente, num_fuente, num_cheque, num_cta, cod_bco);
	
	
	
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Eliminar'
		HIDE OPTION 'Detalle'
                HIDE OPTION 'Imprimir'
		IF num_args() = 6 THEN
			HIDE OPTION 'Consultar'
			HIDE OPTION 'Egreso'
                	SHOW OPTION 'Imprimir'
			CALL execute_query()
			IF vm_filas_pant < vm_ind_egr THEN
				SHOW OPTION 'Detalle'
			END IF
		END IF
	COMMAND KEY('E') 'Egreso' 		'Realizar egreso de caja.'
		HIDE OPTION 'Detalle'
		HIDE OPTION 'Imprimir'
		CALL control_egreso()
		IF vm_num_rows >= 1 THEN
			IF rm_j10.j10_estado <> 'E' THEN
				SHOW OPTION 'Eliminar'
			END IF
			SHOW OPTION 'Imprimir'
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
		HIDE OPTION 'Imprimir'
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
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
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
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
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
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
		END IF
        COMMAND KEY('P') 'Imprimir'		'Imprime el egreso.'
        	CALL imprimir()
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_egreso()

DEFINE rowid		INTEGER
DEFINE intentar		SMALLINT
DEFINE done		SMALLINT

DEFINE r_b00		RECORD LIKE ctbt000.*
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE r_j02		RECORD LIKE cajt002.*

CLEAR FORM
INITIALIZE rm_j10.* TO NULL

LET rm_j10.j10_fecing      = fl_current()
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
	--CALL fgl_winmessage(vg_producto,'No hay una caja asignada al usuario ' || vg_usuario || '.','stop')
	CALL fl_mostrar_mensaje('No hay una caja asignada al usuario ' || vg_usuario || '.','stop')
	EXIT PROGRAM
END IF

LET rm_j10.j10_codigo_caja = r_j02.j02_codigo_caja 

INITIALIZE rm_j04.* TO NULL
BEGIN WORK
	SELECT * INTO rm_j04.* FROM cajt004
		WHERE j04_compania    = vg_codcia
		  AND j04_localidad   = vg_codloc
		  AND j04_codigo_caja = r_j02.j02_codigo_caja
		  AND j04_fecha_aper  = vg_fecha
		  AND j04_secuencia   = (SELECT MAX(j04_secuencia) 
		  				FROM cajt004
	  					WHERE j04_compania  = vg_codcia
	  				  	  AND j04_localidad = vg_codloc
	  					  AND j04_codigo_caja 
	  					  	= r_j02.j02_codigo_caja
	  					  AND j04_fecha_aper  = vg_fecha)

IF rm_j04.j04_codigo_caja IS NULL THEN
	ROLLBACK WORK
	--CALL fgl_winmessage(vg_producto,'La caja no está aperturada.','exclamation')
	CALL fl_mostrar_mensaje('La caja no está aperturada.','exclamation')
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	ELSE
		CLEAR FORM
	END IF
	RETURN
END IF

CALL lee_datos('I')
IF int_flag THEN
	ROLLBACK WORK
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

CALL abre_cursor_caja()

--IF rm_j10.j10_valor = 0 THEN
	CALL ingresa_detalle()
	IF rm_j10.j10_valor = 0 AND vm_ind_egr = 0 THEN
		CALL fl_mostrar_mensaje('No se ha indicado efectivo y no hay cheques.','exclamation')
		LET int_flag = 1
	END IF
--END IF
IF int_flag THEN
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

INITIALIZE r_b12.* TO NULL

CALL fl_lee_compania_contabilidad(vg_codcia) RETURNING r_b00.*
IF vg_codloc <> 2 AND vg_codloc <> 4 THEN
	--IF r_b00.b00_inte_online = 'S' THEN
		CALL contabilizacion_online() RETURNING r_b12.*
		IF int_flag THEN
			IF vm_num_rows = 0 THEN
				CLEAR FORM
			ELSE	
				CALL lee_muestra_registro(vm_rows[vm_row_current])
			END IF
			ROLLBACK WORK
			RETURN 
		END IF
	--END IF
END IF

COMMIT WORK

IF vg_codloc <> 2 AND vg_codloc <> 4 THEN
	IF r_b12.b12_compania IS NOT NULL AND r_b00.b00_mayo_online = 'S' THEN
		CALL fl_mayoriza_comprobante(r_b12.b12_compania,
						r_b12.b12_tipo_comp,
						r_b12.b12_num_comp, 'M')
	END IF
END IF
IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF
LET vm_row_current = vm_num_rows
LET vm_rows[vm_num_rows] = rowid

CALL muestra_contadores()
CALL lee_muestra_registro(vm_rows[vm_row_current])
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
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_mon		RECORD LIKE gent013.*

LET vm_eg_mix = 0
LET int_flag  = 0
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

		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			RETURN
		END IF
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
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
			CALL fl_ayuda_cuenta_banco(vg_codcia, 'A') 
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
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
		CALL retorna_arreglo()
		LET vm_filas_pant = vm_size_arr
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
				--CALL fgl_winmessage(vg_producto,'Banco no existe.','exclamation')
				CALL fl_mostrar_mensaje('Banco no existe.','exclamation')
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
				--CALL fgl_winmessage(vg_producto,'Debe ingresar un banco primero.','exclamation')
				CALL fl_mostrar_mensaje('Debe ingresar un banco primero.','exclamation')
				INITIALIZE rm_j10.j10_numero_cta TO NULL
				DISPLAY BY NAME rm_j10.j10_numero_cta
				NEXT FIELD j10_banco
			END IF
			LET nro_cta = rm_j10.j10_numero_cta
			CALL fl_lee_banco_compania(vg_codcia, rm_j10.j10_banco,
				rm_j10.j10_numero_cta) RETURNING r_g09.*
			IF r_g09.g09_numero_cta IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'No existe cuenta en este banco.','exclamation')
				CALL fl_mostrar_mensaje('No existe cuenta en este banco.','exclamation')
				LET rm_j10.j10_numero_cta = nro_cta
				NEXT FIELD j10_numero_cta
			END IF
			IF r_g09.g09_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD j10_numero_cta
			END IF
			CALL fl_lee_cuenta(r_g09.g09_compania,
						r_g09.g09_aux_cont)
				RETURNING r_b10.*
			IF r_b10.b10_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No se puede escoger una cuenta corriente que no tiene auxiliar contable.', 'exclamation')
				NEXT FIELD j10_numero_cta
			END IF
			IF r_b10.b10_estado <> 'A' THEN
				CALL fl_mostrar_mensaje('El auxiliar contable de esta cuenta bancaria esta con estado bloqueado.', 'exclamation')
				NEXT FIELD j10_numero_cta
			END IF
			CALL fl_lee_moneda(r_g09.g09_moneda) RETURNING r_mon.*
			LET rm_j10.j10_moneda = r_mon.g13_moneda
			DISPLAY BY NAME rm_j10.j10_moneda
			DISPLAY r_mon.g13_nombre TO n_moneda
			
			CALL obtener_saldos()
			IF int_flag THEN
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
			--CALL fgl_winmessage(vg_producto,'Moneda no existe.','exclamation')
			CALL fl_mostrar_mensaje('Moneda no existe.','exclamation')
			CLEAR n_moneda
			NEXT FIELD j10_moneda
		ELSE
			IF r_mon.g13_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				CLEAR n_moneda
				NEXT FIELD j10_moneda
			ELSE
				DISPLAY r_mon.g13_nombre TO n_moneda
				CALL obtener_saldos()
				IF int_flag THEN
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
			--CALL fgl_winmessage(vg_producto,'Debe digitar valores positivos.','exclamation')
			CALL fl_mostrar_mensaje('Debe digitar valores positivos.','exclamation')
			NEXT FIELD j10_valor
		END IF
		IF rm_j10.j10_valor > 0 AND rm_j10.j10_valor > saldo_hoy_ef THEN
			CALL fl_mostrar_mensaje('No puede egresar un valor mayor al que existe en la caja.','exclamation')
			NEXT FIELD j10_valor
		END IF
END INPUT
IF int_flag THEN
	RETURN
END IF

END FUNCTION



FUNCTION obtener_saldos()

IF NOT caja_aperturada(rm_j10.j10_moneda) THEN
	LET int_flag = 1
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

DEFINE expr_sql			CHAR(500)
DEFINE query			CHAR(600)

DEFINE dummy			LIKE gent008.g08_nombre
	
DEFINE r_g13			RECORD LIKE gent013.*
DEFINE r_j10			RECORD LIKE cajt010.*
DEFINE r_g08			RECORD LIKE gent008.*
DEFINE r_g09			RECORD LIKE gent009.*

CLEAR FORM

LET int_flag = 0
CONSTRUCT BY NAME expr_sql 
	ON j10_num_fuente, j10_estado, j10_numero_cta,
	   j10_banco, j10_moneda, j10_referencia, j10_valor, 
	   j10_codigo_caja, j10_usuario
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
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
			CALL fl_ayuda_cuenta_banco(vg_codcia, 'T') 
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
		LET int_flag = 0
	BEFORE CONSTRUCT
		CALL setea_nombre_botones_f1()
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
END CONSTRUCT

IF int_flag THEN
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
	    '	  AND ', expr_sql CLIPPED,
	    '	ORDER BY 1, 2, 3, 4'
	    
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_j10.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
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
DEFINE r_j02		RECORD LIKE cajt002.*
DEFINE tot_egr_ch	DECIMAL(12,2)
DEFINE num_fuente 	LIKE cajt010.j10_num_fuente

LET int_flag = 0
CALL fl_retorna_caja(vg_codcia, vg_codloc, vg_usuario) RETURNING r_j02.*
IF r_j02.j02_codigo_caja IS NULL THEN
	CALL fl_mostrar_mensaje('No hay una caja asignada al usuario ' || vg_usuario || '.','stop')
	EXIT PROGRAM
END IF
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])
IF rm_j10.j10_estado = 'E' THEN
	CALL fl_mostrar_mensaje('Este registro ya ha sido eliminado.','exclamation')
	RETURN
END IF
IF DATE(rm_j10.j10_fecha_pro) <> vg_fecha THEN
	CALL fl_mostrar_mensaje('Solo puede eliminar egresos realizados hoy.','exclamation')
	RETURN
END IF
INITIALIZE rm_j04.* TO NULL
SELECT * INTO rm_j04.* FROM cajt004
	WHERE j04_compania    = vg_codcia
	  AND j04_localidad   = vg_codloc
	  AND j04_codigo_caja = r_j02.j02_codigo_caja
	  AND j04_fecha_aper  = vg_fecha
	  AND j04_secuencia   = (SELECT MAX(j04_secuencia) 
	  				FROM cajt004
  					WHERE j04_compania  = vg_codcia
  				  	  AND j04_localidad = vg_codloc
  					  AND j04_codigo_caja 
  					  	= r_j02.j02_codigo_caja
  					  AND j04_fecha_aper  = vg_fecha)

IF rm_j04.j04_codigo_caja IS NULL THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('La caja no está aperturada.','exclamation')
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	ELSE
		CLEAR FORM
	END IF
	RETURN
END IF
IF NOT caja_aperturada(rm_j10.j10_moneda) THEN
	CALL fl_mostrar_mensaje('No puede eliminar egresos de una caja cerrada.','exclamation')
	RETURN
END IF
CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
IF resp = 'Yes' THEN
	IF vg_codloc <> 2 AND vg_codloc <> 4 THEN
		CALL fl_mayoriza_comprobante(vg_codcia, rm_j10.j10_tip_contable,
						rm_j10.j10_num_contable, 'D')
	END IF
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

	CALL abre_cursor_caja()
	
	CALL actualiza_acumulados_caja('D')
	CALL actualiza_acumulados_tipo_transaccion('D')
	IF vg_codloc <> 2 AND vg_codloc <> 4 THEN
		CALL elimina_comprobante_contable()
	END IF
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
CALL setea_nombre_botones_f1()
CALL muestra_detalle()

END FUNCTION



FUNCTION muestra_contadores()

IF vg_gui = 1 THEN
	DISPLAY "" AT 1,1
	DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 67
END IF

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

--#DISPLAY 'Tp'			TO bt_tipo
--#DISPLAY 'Num.Fue.'		TO bt_num
--#DISPLAY 'Num. Cheque'	TO bt_cheque
--#DISPLAY 'Cta. Cte.'		TO bt_cta_cte
--#DISPLAY 'Bco'		TO bt_banco
--#DISPLAY 'Fecha Pro.'		TO bt_fecha
--#DISPLAY 'Valor'		TO bt_valor
--#DISPLAY 'E'			TO bt_check

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
DEFINE query		CHAR(3000)

DELETE FROM tmp_detalle

LET query = ' SELECT j11_tipo_fuente, j11_num_fuente, j11_num_ch_aut, ',
		'j11_num_cta_tarj, j11_cod_bco_tarj, ',
		'DATE(j10_fecha_pro) j10_fecha_pro, j11_valor, "N" n_eg',
		' FROM cajt010, cajt011 ',
		' WHERE j10_compania    = ', vg_codcia,
		'   AND j10_localidad   = ', vg_codloc,
		'   AND j10_estado      NOT IN ("E") ',
		'   AND j10_codigo_caja = "', rm_j05.j05_codigo_caja, '"',
		'   AND j11_compania    = j10_compania ',
		'   AND j11_localidad   = j10_localidad ',
		'   AND j11_tipo_fuente = j10_tipo_fuente ',
		'   AND j11_num_fuente  = j10_num_fuente ',
		'   AND j11_moneda      = "', rm_j05.j05_moneda, '"',
		'   AND j11_codigo_pago = "', vm_cheque, '"',
		'   AND j11_num_egreso  IS NULL ',
{
		' UNION ',
		' SELECT j11_tipo_fuente, j11_num_fuente, j11_num_ch_aut, ', 
		'j11_num_cta_tarj, j11_cod_bco_tarj, j11_valor, "N" n_eg',
		' FROM cajt010, cajt011, cxct026 ',
		' WHERE j10_compania    = ', vg_codcia,
		'   AND j10_localidad   = ', vg_codloc,
		'   AND j10_estado      NOT IN ("E") ',
		'   AND j10_codigo_caja = ', rm_j05.j05_codigo_caja,
		'   AND j11_compania    = j10_compania ',
		'   AND j11_localidad   = j10_localidad ',
		'   AND j11_tipo_fuente = j10_tipo_fuente ',
		'   AND j11_num_fuente  = j10_num_fuente ',
		'   AND j11_moneda      = "', rm_j05.j05_moneda, '"',
		'   AND j11_codigo_pago = "', vm_che_cp, '"',
		'   AND j11_num_egreso  IS NULL ',
		'   AND z26_compania    = j10_compania ',
		'   AND z26_localidad   = j10_localidad ',
		'   AND z26_codcli      = j10_codcli ',
		'   AND z26_banco       = j11_cod_bco_tarj ',
		'   AND z26_num_cta     = j11_num_cta_tarj ',
		'   AND z26_num_cheque  = j11_num_ch_aut ',
		'   AND z26_fecha_cobro <= TODAY ',
}
	' INTO TEMP t1 '
PREPARE exe_tmp FROM query
EXECUTE exe_tmp

INSERT INTO tmp_detalle SELECT * FROM t1
DROP TABLE t1

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
	--CALL fgl_winmessage(vg_producto,'No se han ingresado cheques a esta caja.','exclamation')
	CALL fl_mostrar_mensaje('No hay cheques pendientes en esta caja.','exclamation')
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
                	LET int_flag = 1
                        RETURN
                END IF
        END FOREACH
        
        LET i = 1
        LET j = 1
        LET int_flag = 0
	IF vm_ind_egr > 0 THEN
		CALL set_count(vm_ind_egr)
	END IF
	INPUT ARRAY rm_egresos WITHOUT DEFAULTS FROM ra_egresos.*
		ON KEY(INTERRUPT)
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				EXIT INPUT
			END IF
	        ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
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
		ON KEY(F22)
			LET col = 8
			EXIT INPUT
		BEFORE INPUT
			--#CALL dialog.keysetlabel('INSERT', '')
			--#CALL dialog.keysetlabel('DELETE', '')
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
			CALL muestra_contadores_det(i, vm_ind_egr)
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
					
				--NEXT FIELD ra_egresos[j].check
				NEXT FIELD check
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
					CALL fl_mostrar_mensaje('No ha digitado ningun valor de egreso.','exclamation')
					CONTINUE INPUT
				END IF	
			END IF	
			IF rm_j10.j10_valor > 0 THEN
				LET m = 0
				FOR k = 1 TO vm_ind_egr 
					IF rm_egresos[k].check = 'S' THEN
						LET m = m + 1	 
					END IF
				END FOR 
				IF m > 0 THEN
					LET vm_eg_mix = 1
				END IF
			END IF
	END INPUT
	IF int_flag THEN
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
CALL muestra_contadores_det(0, vm_ind_egr)

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

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
	  	  AND j11_localidad    = vg_codloc
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

IF STATUS < 0 THEN
	WHENEVER ERROR STOP
	SET LOCK MODE TO NOT WAIT
	CALL fl_mensaje_bloqueo_otro_usuario()
	ROLLBACK WORK
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP

WHILE (STATUS <> NOTFOUND)
	UPDATE cajt011 SET j11_num_egreso = rm_j10.j10_num_fuente
		WHERE CURRENT OF q_det
	
	INITIALIZE num_egreso TO NULL
	FETCH q_det INTO num_egreso
END WHILE  
SET LOCK MODE TO NOT WAIT
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
	
END FUNCTION



FUNCTION actualiza_acumulados_tipo_transaccion(flag)
DEFINE flag 		CHAR(1)
-- I: actualizacion en incremento
-- D: actualizacion en decremento (se multiplica por menos uno [-1])

DEFINE codigo_pago	LIKE cajt013.j13_codigo_pago
DEFINE cod_pago2	LIKE cajt013.j13_codigo_pago
DEFINE salir		SMALLINT
DEFINE valor_aux	LIKE cajt013.j13_valor
DEFINE r_j13		RECORD LIKE cajt013.*

SELECT SUM(valor) INTO valor_aux FROM tmp_detalle WHERE egresa = 'S'
IF valor_aux IS NULL THEN
	LET valor_aux = 0
END IF

LET salir = 0
LET codigo_pago = vm_cheque
LET cod_pago2   = vm_che_cp

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
				  AND j13_fecha        = vg_fecha
		 		  AND j13_moneda       = rm_j10.j10_moneda
				  AND j13_trn_generada = vm_egr_caja
				  AND j13_codigo_pago  IN (codigo_pago)
			FOR UPDATE
	OPEN  q_j13
	FETCH q_j13 INTO r_j13.*
	WHENEVER ERROR STOP
	
	IF STATUS < 0 THEN
		SET LOCK MODE TO NOT WAIT
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No se pueden actualizar los acumulados.','exclamation')
		EXIT PROGRAM
	END IF

	IF (STATUS <> NOTFOUND) THEN
		UPDATE cajt013 SET j13_valor = j13_valor + valor_aux
			WHERE CURRENT OF q_j13
	END IF
	CLOSE q_j13
	FREE  q_j13
	SET LOCK MODE TO NOT WAIT

	IF codigo_pago = vm_cheque THEN
		LET codigo_pago = vm_efectivo
		LET cod_pago2   = vm_efectivo
		LET valor_aux   = rm_j10.j10_valor
	ELSE
		LET salir = 1
	END IF
END WHILE

END FUNCTION



FUNCTION muestra_detalle()

DEFINE i		SMALLINT
DEFINE filas_pant	SMALLINT
DEFINE tot_egr_ch	DECIMAL(12,2)

CALL retorna_arreglo()
LET filas_pant = vm_size_arr
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
CALL muestra_contadores_det(0, vm_ind_egr)

END FUNCTION



FUNCTION lee_detalle()

DELETE FROM tmp_detalle

INSERT INTO tmp_detalle
	SELECT j11_tipo_fuente, j11_num_fuente, j11_num_ch_aut,
		j11_num_cta_tarj, j11_cod_bco_tarj, DATE(j10_fecha_pro),
		j11_valor, 'S'
	 	FROM cajt011, cajt010
	 	WHERE j11_compania     = vg_codcia
	 	  AND j11_localidad    = vg_codloc
	 	  AND j11_num_egreso   = rm_j10.j10_num_fuente
	 	  AND j11_codigo_pago IN (vm_cheque)
		  AND j10_compania     = j11_compania
		  AND j10_localidad    = j11_localidad
		  AND j10_tipo_fuente  = j11_tipo_fuente
		  AND j10_num_fuente   = j11_num_fuente
	       
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
        LET int_flag = 0
	CALL set_count(vm_ind_egr)
	DISPLAY ARRAY rm_egresos TO ra_egresos.*
		ON KEY(INTERRUPT)
			EXIT DISPLAY
        	ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
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
		ON KEY(F22)
			LET col = 8
			EXIT DISPLAY
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
			--#CALL dialog.keysetlabel('ACCEPT', '')
			--#CALL setea_nombre_botones_f1()
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#LET j = scr_line()
			--#CALL muestra_contadores_det(i, vm_ind_egr)
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
	END DISPLAY
	IF int_flag THEN
		LET salir = 1
		LET int_flag = 0
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
CALL muestra_contadores_det(0, vm_ind_egr)

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
	CALL fl_mostrar_mensaje('No existe forma de pago.','exclamation')
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
	CALL fl_mensaje_bloqueo_otro_usuario()
	ROLLBACK WORK
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
IF STATUS <> NOTFOUND THEN
	UPDATE ctbt012 SET b12_estado = 'E' WHERE CURRENT OF q_ctb
END IF
SET LOCK MODE TO NOT WAIT
CLOSE q_ctb
FREE  q_ctb

END FUNCTION



FUNCTION abre_cursor_caja()

INITIALIZE rm_j05.* TO NULL
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
WHENEVER ERROR STOP
IF STATUS = NOTFOUND THEN 
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('La caja no está aperturada.','exclamation')
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	ELSE
		CLEAR FORM
	END IF
	RETURN
END IF
IF STATUS < 0 THEN
	CALL fl_mensaje_bloqueo_otro_usuario()
	ROLLBACK WORK
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	ELSE
		CLEAR FORM
	END IF
	RETURN
END IF

END FUNCTION



FUNCTION contabilizacion_online()
DEFINE r_g09		RECORD LIKE gent009.*
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
DEFINE r_j02		RECORD LIKE cajt002.*

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
SELECT SUM(valor) INTO tot_egr FROM tmp_detalle WHERE egresa = 'S'
IF tot_egr IS NULL THEN
	LET tot_egr = 0
END IF
LET tot_egr = tot_egr + rm_j10.j10_valor
INITIALIZE r_b41.* TO NULL
DECLARE q_aux CURSOR FOR
	SELECT * FROM ctbt041 WHERE b41_compania  = vg_codcia
				AND b41_localidad = vg_codloc
OPEN  q_aux
FETCH q_aux INTO r_b41.*
CLOSE q_aux
FREE  q_aux
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No se han configurado las cuentas de Caja.','exclamation')
	LET int_flag = 1
	CLOSE WINDOW w_207_2
	RETURN r_b12.*
END IF
CALL fl_lee_codigo_caja_caja(vg_codcia, vg_codloc, rm_j10.j10_codigo_caja)
	RETURNING r_j02.*
IF r_j02.j02_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe en cajt002: ' || rm_j10.j10_codigo_caja, 'stop')
	EXIT PROGRAM
END IF
IF r_j02.j02_aux_cont IS NOT NULL THEN
	LET r_b41.b41_caja_mb = r_j02.j02_aux_cont
	LET r_b41.b41_caja_me = r_j02.j02_aux_cont
END IF

IF rm_j10.j10_moneda = rg_gen.g00_moneda_base THEN
	LET cuenta = r_b41.b41_caja_mb     
ELSE
	LET cuenta = r_b41.b41_caja_me
END IF
CALL inserta_tabla_temporal(cuenta, 0, tot_egr, 'V') 
	RETURNING tot_debito, tot_credito
IF rm_j10.j10_banco IS NOT NULL THEN
	CALL fl_lee_banco_compania(vg_codcia, rm_j10.j10_banco, 
		rm_j10.j10_numero_cta) RETURNING r_g09.*
	CALL inserta_tabla_temporal(r_g09.g09_aux_cont, tot_egr, 0, 'F') 
		RETURNING tot_debito, tot_credito
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
				CALL fl_ayuda_cuenta_contable(vg_codcia, -1) 
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
			LET int_flag = 0	
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
			IF tot_debito <> tot_egr THEN
				--CALL fgl_winmessage(vg_producto,'Los valores en el débito y el crédito deben ser iguales al total egresado.','exclamation')
				CALL fl_mostrar_mensaje('Los valores en el débito y el crédito deben ser iguales al total egresado.','exclamation')
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

IF rm_j10.j10_banco IS NULL THEN
	CALL genera_comprobante_contable('EC') RETURNING r_b12.*
	IF r_b12.b12_compania IS NULL THEN
		LET int_flag = 1
		CLOSE WINDOW w_207_2
		RETURN r_b12.*
	END IF
ELSE
	CALL genera_comprobante_contable('DP') RETURNING r_b12.*
	IF r_b12.b12_compania IS NULL THEN
		LET int_flag = 1
		CLOSE WINDOW w_207_2
		RETURN r_b12.*
	END IF
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
	CALL fl_mostrar_mensaje('No existe tipo de comprobante para Egreso de caja: ' || tipo_comp,'exclamation')
	RETURN r_b12.*
END IF
LET glosa = rm_j10.j10_tipo_destino || ' - ' || rm_j10.j10_num_destino 
INITIALIZE r_b12.* TO NULL
LET r_b12.b12_compania    = vg_codcia  
-- OjO confirmar
LET r_b12.b12_tipo_comp   = r_b03.b03_tipo_comp
LET r_b12.b12_num_comp    = fl_numera_comprobante_contable(vg_codcia,
                            	r_b12.b12_tipo_comp, YEAR(vg_fecha), MONTH(vg_fecha))
LET r_b12.b12_estado      = 'A' 
IF rm_j10.j10_valor > 0 THEN
	CASE vg_codloc
		WHEN 1 LET r_b12.b12_subtipo = 71
		WHEN 3 LET r_b12.b12_subtipo = 73
		WHEN 4 LET r_b12.b12_subtipo = 75
	END CASE
ELSE
	CASE vg_codloc
		WHEN 1 LET r_b12.b12_subtipo = 72
		WHEN 3 LET r_b12.b12_subtipo = 74
		WHEN 4 LET r_b12.b12_subtipo = 76
	END CASE
END IF
IF vm_eg_mix THEN
	CASE vg_codloc
		WHEN 1 LET r_b12.b12_subtipo = 77
		WHEN 3 LET r_b12.b12_subtipo = 78
		WHEN 4 LET r_b12.b12_subtipo = 79
	END CASE
END IF
LET r_b12.b12_glosa       = rm_j10.j10_referencia
LET r_b12.b12_origen      = 'A' 
LET r_b12.b12_moneda      = rm_j10.j10_moneda
LET r_b12.b12_paridad     = calcula_paridad(rm_j10.j10_moneda,
					    rg_gen.g00_moneda_base) 
LET r_b12.b12_fec_proceso = vg_fecha
-- OjO EG no esta relacionado al modulo CG
LET r_b12.b12_modulo      = r_b03.b03_modulo
LET r_b12.b12_usuario     = vg_usuario 
LET r_b12.b12_fecing      = fl_current()
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
	    '			  b13_secuencia, b13_cuenta, b13_tipo_doc,',
	    '			  b13_glosa, b13_valor_base, b13_valor_aux, ',
	    '			  b13_num_concil, b13_fec_proceso) ', 
	    '	SELECT ', vg_codcia, ', "', r_b12.b12_tipo_comp , '", "',
	    		r_b12.b12_num_comp CLIPPED, '", te_serial, te_cuenta, ',
	               ' "DEP" ,"', glosa CLIPPED, '", ',
	    		expr_valor CLIPPED, ', 0,', 
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
	    '			  b13_secuencia, b13_cuenta, b13_tipo_doc, ',
	    '			  b13_glosa, b13_valor_base, b13_valor_aux, ',
	    '			  b13_num_concil, b13_fec_proceso) ', 
	    '	SELECT ', vg_codcia, ', "', r_b12.b12_tipo_comp , '", "',
	    		r_b12.b12_num_comp CLIPPED, '", te_serial, te_cuenta, ',
	    		' "DEP", "', glosa CLIPPED, '", ',
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
		CALL fl_mostrar_mensaje('No existe factor de conversión para esta moneda.','exclamation')
		INITIALIZE paridad TO NULL
	ELSE
		LET paridad = r_g14.g14_tasa 
	END IF
END IF
RETURN paridad

END FUNCTION



FUNCTION imprimir()
DEFINE comando 		CHAR(300)
DEFINE run_prog		CHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador,
	      'CAJA', vg_separador, 'fuentes', 
	      vg_separador, run_prog, 'cajp404 ', 
	      vg_base, ' ', 'CG', vg_codcia, ' ', 
	      vg_codloc, ' ', rm_j10.j10_num_fuente 

RUN comando

END FUNCTION



FUNCTION retorna_arreglo()

--#LET vm_size_arr = fgl_scr_size('ra_egresos')
IF vg_gui = 0 THEN
        LET vm_size_arr = 6
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
