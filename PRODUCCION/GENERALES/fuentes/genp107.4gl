{*
 * Titulo           : genp107.4gl - Mantenimiento de Cuentas Corrientes de la
 *                                  Compania     
 * Elaboracion      : 02-mar-2009
 * Autor            : JCM
 * Formato Ejecucion: fglrun genp107 base modulo codcia
 *}
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_nivel_cta	LIKE ctbt001.b01_nivel

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA r_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS

DEFINE rm_cta		RECORD LIKE gent009.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/genp107.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'genp107'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_rows = 1000
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_cta AT 3,2 WITH 21 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_cta FROM '../forms/genf107_1'
DISPLAY FORM f_cta

LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_cta.* TO NULL
CALL muestra_contadores()

SELECT MAX(b01_nivel) INTO vm_nivel_cta FROM ctbt001
IF vm_nivel_cta IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'No se ha configurado el plan de cuentas.',
		'stop')
	EXIT PROGRAM
END IF

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Chequera'
		HIDE OPTION 'Bloquear/Activar'
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		IF vm_num_rows = vm_max_rows THEN
			CALL fl_mensaje_arreglo_lleno()
		ELSE
			CALL control_ingreso()
		END IF
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Bloquear/Activar'
			SHOW OPTION 'Chequera'
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
	COMMAND KEY('M') 'Modificar' 		'Modificar registro corriente.'
		CALL control_modificacion()
	COMMAND KEY ('H') 'Chequera'		'Datos de la chequera de la cuenta.'
		CALL control_chequera()
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro.'
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Chequera'
			SHOW OPTION 'Bloquear/Activar'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Bloquear/Activar'
				HIDE OPTION 'Chequera'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Chequera'
			SHOW OPTION 'Bloquear/Activar'
		END IF
		IF vm_row_current <= 1 THEN
			HIDE OPTION 'Retroceder'
		END IF
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
		CALL siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
		CALL anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('B') 'Bloquear/Activar'     'Bloquea o activa registro.'
		CALL control_bloquea_activa()
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()

CLEAR FORM
INITIALIZE rm_cta.* TO NULL

LET rm_cta.g09_compania = vg_codcia
LET rm_cta.g09_fecing   = CURRENT
LET rm_cta.g09_usuario  = vg_usuario
LET rm_cta.g09_moneda   = rg_gen.g00_moneda_base
LET rm_cta.g09_estado   = 'A'

CALL lee_datos('I')
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF
INSERT INTO gent009 VALUES (rm_cta.*)

LET vm_num_rows = vm_num_rows + 1
LET vm_row_current = vm_num_rows
LET vm_rows[vm_num_rows] = SQLCA.SQLERRD[6] 	-- Rowid de la ultima fila 
                                             	-- procesada
CALL muestra_contadores()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_modificacion()

IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

CALL lee_muestra_registro(vm_rows[vm_row_current])

IF rm_cta.g09_estado = 'B' THEN   
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF

WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_upd CURSOR FOR 
	SELECT * FROM gent009 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_upd
FETCH q_upd INTO rm_cta.*
WHENEVER ERROR STOP
IF STATUS < 0 THEN
	CALL fl_mensaje_bloqueo_otro_usuario()
	ROLLBACK WORK
	RETURN
END IF  

CALL lee_datos('M')

IF INT_FLAG THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	CLOSE q_upd
	FREE  q_upd
	RETURN
END IF 

UPDATE gent009 SET * = rm_cta.* WHERE CURRENT OF q_upd
COMMIT WORK
CLOSE q_upd
FREE  q_upd
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION lee_datos(flag)

DEFINE flag 		CHAR(1)
DEFINE resp 		CHAR(6)

DEFINE moneda 		LIKE gent013.g13_moneda
DEFINE nom_moneda	LIKE gent013.g13_nombre
DEFINE decimales	LIKE gent013.g13_decimales

DEFINE banco 		LIKE gent008.g08_banco
DEFINE nom_banco	LIKE gent008.g08_nombre

DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE nom_cuenta 	LIKE ctbt010.b10_descripcion

DEFINE r_ban		RECORD LIKE gent008.*
DEFINE r_cta 		RECORD LIKE gent009.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_b10            RECORD LIKE ctbt010.*

IF flag = 'I' THEN
	LET rm_cta.g09_tipo_cta = 'A'
	LET rm_cta.g09_pago_roles = 'N'
END IF

CALL muestra_etiquetas()

LET INT_FLAG = 0
INPUT BY NAME rm_cta.g09_banco, rm_cta.g09_numero_cta, rm_cta.g09_tipo_cta,
              rm_cta.g09_moneda, rm_cta.g09_pago_roles, rm_cta.g09_atencion_rol,
              rm_cta.g09_aux_cont, rm_cta.g09_usuario,
			  rm_cta.g09_fecing, rm_cta.g09_estado WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_cta.g09_banco, rm_cta.g09_numero_cta,
                                     rm_cta.g09_tipo_cta, rm_cta.g09_moneda,
				     rm_cta.g09_pago_roles, 
                                     rm_cta.g09_atencion_rol,
				     rm_cta.g09_aux_cont 
                                    ) THEN
			RETURN
		END IF

		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
			RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN
		END IF
	ON KEY (F2)
		IF INFIELD(g09_banco) THEN
			CALL fl_ayuda_bancos() RETURNING banco, nom_banco
			IF banco IS NOT NULL THEN
				LET rm_cta.g09_banco = banco
				DISPLAY BY NAME rm_cta.g09_banco
				DISPLAY nom_banco TO n_banco
			END IF
		END IF
		IF INFIELD(g09_moneda) THEN
			CALL fl_ayuda_monedas() 
				RETURNING moneda, nom_moneda, decimales 
			IF moneda IS NOT NULL THEN
				LET rm_cta.g09_moneda = moneda
				DISPLAY moneda TO g09_moneda
				DISPLAY nom_moneda TO n_moneda
			END IF	
		END IF
		IF INFIELD(g09_aux_cont) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel_cta) 
				RETURNING cuenta, nom_cuenta 
			IF cuenta IS NOT NULL THEN
				LET rm_cta.g09_aux_cont = cuenta
				DISPLAY cuenta TO g09_aux_cont
				DISPLAY nom_cuenta TO n_cuenta
			END IF	
		END IF
		LET INT_FLAG = 0
	BEFORE FIELD g09_banco
		IF flag = 'M' THEN
			NEXT FIELD g09_tipo_cta
		END IF
	AFTER FIELD g09_banco
		IF rm_cta.g09_banco IS NULL THEN
			CLEAR n_banco
		ELSE
			CALL fl_lee_banco_general(rm_cta.g09_banco) 
				RETURNING r_ban.*
			IF r_ban.g08_banco IS NULL THEN	
				CLEAR n_banco
				CALL fgl_winmessage(vg_producto,
					            'Banco no existe',
						    'exclamation')
				NEXT FIELD g09_banco
			ELSE
				DISPLAY r_ban.g08_nombre TO n_banco
			END IF 
		END IF
		IF rm_cta.g09_banco IS NOT NULL THEN
			IF rm_cta.g09_numero_cta IS NOT NULL THEN
				CALL fl_lee_banco_compania(vg_codcia,
                                                   	  rm_cta.g09_banco,
                                                          rm_cta.g09_numero_cta)
					RETURNING r_cta.*
				IF  r_cta.g09_numero_cta IS NOT NULL THEN
					CALL fgl_winmessage(vg_producto,
					                    'Cuenta ya existe',
						            'exclamation')
					NEXT FIELD g09_banco
				END IF 
			END IF
		END IF
	BEFORE FIELD g09_numero_cta
		IF flag = 'M' THEN
			NEXT FIELD g09_tipo_cta
		END IF
	AFTER FIELD g09_numero_cta
		IF rm_cta.g09_numero_cta IS NOT NULL THEN
			IF rm_cta.g09_banco IS NOT NULL THEN
				CALL fl_lee_banco_compania(vg_codcia,
                                                   	  rm_cta.g09_banco,
                                                          rm_cta.g09_numero_cta)
					RETURNING r_cta.*
				IF  r_cta.g09_numero_cta IS NOT NULL THEN
					CALL fgl_winmessage(vg_producto,
					                    'Cuenta ya existe',
						            'exclamation')
					NEXT FIELD g09_numero_cta
				END IF 
			END IF
		END IF
	AFTER FIELD g09_moneda
		IF rm_cta.g09_moneda IS NULL THEN
			CLEAR n_moneda
		ELSE
			CALL fl_lee_moneda(rm_cta.g09_moneda) RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN	
				CALL FGL_WINMESSAGE(vg_producto, 
                             		            'Moneda no existe',        
                                        	    'exclamation')
				CLEAR n_moneda
				NEXT FIELD g09_moneda
			ELSE
				IF r_mon.g13_estado = 'B' THEN
					CALL FGL_WINMESSAGE(vg_producto, 
                            		 	            'Moneda está ' ||
                               	                            'bloqueada',        
                                       	                    'exclamation')
					CLEAR n_moneda
					NEXT FIELD g09_moneda
				ELSE
					DISPLAY r_mon.g13_nombre TO n_moneda
				END IF
			END IF 
		END IF
	AFTER FIELD g09_aux_cont
		IF rm_cta.g09_aux_cont IS NOT NULL THEN
			CALL fl_lee_cuenta(vg_codcia, rm_cta.g09_aux_cont)
				RETURNING r_b10.*
			IF r_b10.b10_cuenta IS NOT NULL THEN
				IF r_b10.b10_estado = 'B' THEN
					CALL FGL_WINMESSAGE(vg_producto, 
                            		 	            'Cuenta está ' ||
                               	                            'bloqueada',        
                                       	                    'exclamation')
					CLEAR n_cuenta
					NEXT FIELD g09_aux_cont
				END IF
				IF r_b10.b10_nivel <> vm_nivel_cta THEN
					CALL FGL_WINMESSAGE(vg_producto, 
                            		 	            'Cuenta debe ' ||
                               	                            'ser de nivel ' ||
                               	                            vm_nivel_cta || '.',
                                       	                    'exclamation')
					CLEAR n_cuenta
					NEXT FIELD g09_aux_cont
				END IF
				DISPLAY r_b10.b10_descripcion TO n_cuenta
			ELSE
					CALL FGL_WINMESSAGE(vg_producto, 
                            		 	            'Cuenta no ' ||
                               	                            'existe',        
                                       	                    'exclamation')
					CLEAR n_cuenta
					NEXT FIELD g09_aux_cont
			END IF
		ELSE
			DISPLAY '' TO n_cuenta
		END IF
	AFTER INPUT
		IF rm_cta.g09_pago_roles = 'S' AND 
                   rm_cta.g09_atencion_rol IS NULL THEN
			CALL FGL_WINMESSAGE(vg_producto, 
                        	            'Debe indicar a quien va ' ||
                                            'dirigida la carta para el banco',
                                            'exclamation')
			NEXT FIELD g09_atencion_rol
		END IF
		-- VALIDA QUE LOS REGISTROS NO HAYAN SIDO BLOQUEADOS	
			CALL fl_lee_moneda(rm_cta.g09_moneda) RETURNING r_mon.*
			IF r_mon.g13_estado = 'B' THEN
				CALL FGL_WINMESSAGE(vg_producto, 
                                    	            'Moneda fue ' ||
                               	                    'bloqueada',        
                                                    'exclamation')
				CLEAR n_moneda
				NEXT FIELD g09_moneda
			END IF
			CALL fl_lee_cuenta(vg_codcia, rm_cta.g09_aux_cont)
				RETURNING r_b10.*
			IF r_b10.b10_cuenta IS NOT NULL THEN
				IF r_b10.b10_estado = 'B' THEN
					CALL FGL_WINMESSAGE(vg_producto, 
                            		 	            'Cuenta fue ' ||
                               	                            'bloqueada',        
                                       	                    'exclamation')
					CLEAR n_cuenta
					NEXT FIELD g09_aux_cont
				END IF
			END IF
END INPUT

END FUNCTION



FUNCTION control_chequera()

DEFINE r_g08			RECORD LIKE gent008.*
DEFINE r_g100			RECORD LIKE gent100.*

DEFINE resp				CHAR(6)

OPTIONS INPUT WRAP, ACCEPT KEY F12
OPEN WINDOW w_cheq AT 3,2 WITH 17 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_cheq FROM '../forms/genf107_2'
DISPLAY FORM f_cheq

INITIALIZE r_g100.* TO NULL

BEGIN WORK

WHENEVER ERROR CONTINUE
DECLARE q_cheq CURSOR FOR
	SELECT * INTO r_g100.* 
	  FROM gent100
	 WHERE g100_compania   = vg_codcia
	   AND g100_banco      = rm_cta.g09_banco
	   AND g100_numero_cta = rm_cta.g09_numero_cta
	FOR UPDATE

OPEN  q_cheq
FETCH q_cheq INTO r_g100.*
IF STATUS < 0 THEN
	WHENEVER ERROR STOP
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto, 'La chequera esta siendo bloqueada por otro usuario.', 'exclamation')
	CLOSE WINDOW w_cheq
	RETURN
END IF
WHENEVER ERROR STOP

IF r_g100.g100_compania IS NULL THEN
	LET r_g100.g100_banco      = rm_cta.g09_banco
	LET r_g100.g100_numero_cta = rm_cta.g09_numero_cta

	LET r_g100.g100_cheq_ini     = 0
	LET r_g100.g100_cheq_fin     = 0
	LET r_g100.g100_cheq_act     = 0 
	LET r_g100.g100_posy_benef   = 0
	LET r_g100.g100_posix_benef  = 0
	LET r_g100.g100_posfx_benef  = 0
	LET r_g100.g100_posy_valn    = 0
	LET r_g100.g100_posix_valn   = 0
	LET r_g100.g100_posfx_valn   = 0
	LET r_g100.g100_posy_vallt1  = 0 
	LET r_g100.g100_posix_vallt1 = 0 
	LET r_g100.g100_posfx_vallt1 = 0
	LET r_g100.g100_posy_vallt2  = 0
	LET r_g100.g100_posix_vallt2 = 0
	LET r_g100.g100_posfx_vallt2 = 0
	LET r_g100.g100_posy_ciud    = 0
	LET r_g100.g100_posix_ciud   = 0
	LET r_g100.g100_posfx_ciud   = 0
	LET r_g100.g100_posy_fech    = 0
	LET r_g100.g100_posix_fech   = 0
	LET r_g100.g100_posfx_fech   = 0
END IF

CALL fl_lee_banco_general(rm_cta.g09_banco) RETURNING r_g08.*
DISPLAY r_g08.g08_nombre TO n_banco

INPUT BY NAME r_g100.g100_banco, r_g100.g100_numero_cta,  r_g100.g100_cheq_ini,
			  r_g100.g100_cheq_fin, 	r_g100.g100_cheq_act, 
			  r_g100.g100_posy_benef,
			  r_g100.g100_posix_benef,	r_g100.g100_posfx_benef, 
			  r_g100.g100_posy_valn,
			  r_g100.g100_posix_valn, 	r_g100.g100_posfx_valn,  
			  r_g100.g100_posy_vallt1,
			  r_g100.g100_posix_vallt1,	r_g100.g100_posfx_vallt1,
			  r_g100.g100_posy_vallt2,
			  r_g100.g100_posix_vallt2,	r_g100.g100_posfx_vallt2,
			  r_g100.g100_posy_ciud,
			  r_g100.g100_posix_ciud,  	r_g100.g100_posfx_ciud,  
			  r_g100.g100_posy_fech,
			  r_g100.g100_posix_fech,  	r_g100.g100_posfx_fech
		WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			EXIT INPUT
		END IF
END INPUT
IF INT_FLAG THEN
	LET INT_FLAG = 0
	ROLLBACK WORK
	CLOSE WINDOW w_cheq
	RETURN
END IF

IF r_g100.g100_compania IS NULL THEN
	LET r_g100.g100_compania = vg_codcia
	INSERT INTO gent100 VALUES (r_g100.*)
ELSE
	UPDATE gent100 SET * = r_g100.* WHERE CURRENT OF q_cheq
END IF

COMMIT WORK

CALL fgl_winmessage(vg_producto, 'Chequera actualizada OK', 'information')	
CLOSE WINDOW w_cheq

END FUNCTION



FUNCTION control_consulta()

DEFINE expr_sql			VARCHAR(500)
DEFINE query			VARCHAR(600)

DEFINE tipo_cta			LIKE gent009.g09_tipo_cta
DEFINE nro_cta			LIKE gent009.g09_numero_cta

DEFINE banco			LIKE gent008.g08_banco
DEFINE nom_banco		LIKE gent008.g08_nombre

DEFINE cuenta			LIKE ctbt010.b10_cuenta
DEFINE nom_cuenta 		LIKE ctbt010.b10_descripcion

DEFINE moneda			LIKE gent013.g13_moneda
DEFINE nom_moneda		LIKE gent013.g13_nombre
DEFINE decimales 		LIKE gent013.g13_decimales   

DEFINE r_ban			RECORD LIKE gent008.*
DEFINE r_cta			RECORD LIKE gent009.*
DEFINE r_mon			RECORD LIKE gent013.*
DEFINE r_b10			RECORD LIKE ctbt010.*

CLEAR FORM

LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql 
        ON g09_banco, g09_numero_cta, g09_estado,
           g09_tipo_cta, g09_moneda, g09_pago_roles, 
           g09_atencion_rol, g09_aux_cont, 
           g09_usuario
	ON KEY(F2)
		IF INFIELD(g09_banco) THEN
			CALL fl_ayuda_bancos() RETURNING banco, nom_banco
			IF banco IS NOT NULL THEN
				LET rm_cta.g09_banco = banco
				DISPLAY BY NAME rm_cta.g09_banco
				DISPLAY nom_banco TO n_banco
			END IF
		END IF
		IF INFIELD(g09_moneda) THEN
			CALL fl_ayuda_monedas() 
				RETURNING moneda, nom_moneda, decimales 
			IF moneda IS NOT NULL THEN
				LET rm_cta.g09_moneda = moneda
				DISPLAY moneda TO g09_moneda
				DISPLAY nom_moneda TO n_moneda
			END IF	
		END IF
		IF INFIELD(g09_numero_cta) THEN
			CALL fl_ayuda_cuenta_banco(vg_codcia) 
				RETURNING banco, nom_banco, tipo_cta, nro_cta 
			IF nro_cta IS NOT NULL THEN
				LET rm_cta.g09_banco = banco
				DISPLAY banco TO g09_banco
				LET rm_cta.g09_numero_cta = nro_cta
				DISPLAY nro_cta TO g09_numero_cta
				DISPLAY nom_banco TO n_banco
				DISPLAY tipo_cta TO g09_tipo_cta
			END IF	
		END IF
		IF INFIELD(g09_aux_cont) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel_cta) 
				RETURNING cuenta, nom_cuenta 
			IF cuenta IS NOT NULL THEN
				LET rm_cta.g09_aux_cont = cuenta
				DISPLAY cuenta TO g09_aux_cont
				DISPLAY nom_cuenta TO n_cuenta
			END IF	
		END IF
		LET INT_FLAG = 0
	AFTER FIELD g09_banco
		LET rm_cta.g09_banco = GET_FLDBUF(g09_banco)
		IF rm_cta.g09_banco IS NULL THEN
			CLEAR n_banco
		ELSE
			CALL fl_lee_banco_general(rm_cta.g09_banco) 
				RETURNING r_ban.*
			IF r_ban.g08_banco IS NULL THEN	
				CLEAR n_banco
			ELSE
				DISPLAY r_ban.g08_nombre TO n_banco
			END IF 
		END IF
	AFTER FIELD g09_moneda
		LET rm_cta.g09_moneda = GET_FLDBUF(g09_moneda)
		IF rm_cta.g09_moneda IS NULL THEN
			CLEAR n_moneda
		ELSE
			CALL fl_lee_moneda(rm_cta.g09_moneda) RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN	
				CLEAR n_moneda
			ELSE
				DISPLAY r_mon.g13_nombre TO n_moneda
			END IF
		END IF 
	AFTER FIELD g09_numero_cta
		LET rm_cta.g09_numero_cta = GET_FLDBUF(g09_numero_cta)
		IF rm_cta.g09_numero_cta IS NULL THEN
			CLEAR n_banco
			INITIALIZE rm_cta.g09_banco TO NULL
			DISPLAY BY NAME rm_cta.g09_banco
		ELSE
			IF rm_cta.g09_banco IS NULL THEN
				CALL fgl_winmessage(vg_producto,
					'Debe ingresar un banco primero',
					'exclamation')
				INITIALIZE rm_cta.g09_numero_cta TO NULL
				DISPLAY BY NAME rm_cta.g09_numero_cta
				NEXT FIELD g09_banco
			END IF
			CALL fl_lee_banco_compania(vg_codcia, rm_cta.g09_banco,
				rm_cta.g09_numero_cta) RETURNING r_cta.*
			IF r_cta.g09_numero_cta IS NULL THEN
				CLEAR n_banco
				INITIALIZE rm_cta.g09_banco TO NULL
				DISPLAY BY NAME rm_cta.g09_banco
			ELSE
				CALL fl_lee_banco_general(r_cta.g09_banco) 
					RETURNING r_ban.*
				IF r_ban.g08_banco IS NULL THEN	
					CLEAR n_banco
					INITIALIZE rm_cta.g09_banco TO NULL
					DISPLAY BY NAME rm_cta.g09_banco
				ELSE
					DISPLAY r_ban.g08_nombre TO n_banco
					DISPLAY r_ban.g08_banco  TO g09_banco
				END IF 
			END IF
		END IF
	AFTER FIELD g09_aux_cont
		LET rm_cta.g09_aux_cont = GET_FLDBUF(g09_aux_cont)
		IF rm_cta.g09_aux_cont IS NOT NULL THEN
			CALL fl_lee_cuenta(vg_codcia, rm_cta.g09_aux_cont)
				RETURNING r_b10.*
                	IF r_b10.b10_cuenta IS NULL THEN
				DISPLAY '' TO n_cuenta
			ELSE
				DISPLAY r_b10.b10_descripcion TO n_cuenta
			END IF
		ELSE
			DISPLAY '' TO n_cuenta
		END IF
END CONSTRUCT

IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET query = 'SELECT *, ROWID FROM gent009 WHERE ', expr_sql, 
            ' AND g09_compania = ', vg_codcia, ' ORDER BY 1' 
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_cta.*, vm_rows[vm_num_rows]
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



FUNCTION lee_muestra_registro(row)
DEFINE row 		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF

SELECT * INTO rm_cta.* FROM gent009 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

DISPLAY BY NAME rm_cta.g09_banco, rm_cta.g09_numero_cta, rm_cta.g09_estado,
                rm_cta.g09_tipo_cta, rm_cta.g09_moneda, rm_cta.g09_pago_roles,
                rm_cta.g09_atencion_rol, rm_cta.g09_aux_cont, 
				rm_cta.g09_usuario, rm_cta.g09_fecing  

CALL muestra_etiquetas()
CALL muestra_contadores()

END FUNCTION



FUNCTION control_bloquea_activa()

DEFINE resp    	CHAR(6)
DEFINE i	SMALLINT
DEFINE mensaje	VARCHAR(20)
DEFINE estado	CHAR(1)

LET int_flag = 0
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

CALL lee_muestra_registro(vm_rows[vm_row_current])
LET resp = 'Yes'
	LET mensaje = 'Seguro de bloquear'
	IF rm_cta.g09_estado <> 'A' THEN
		LET mensaje = 'Seguro de activar'
	END IF
	CALL fl_mensaje_seguro_ejecutar_proceso()
 		RETURNING resp

IF resp = 'Yes' THEN
	WHENEVER ERROR CONTINUE
	BEGIN WORK
	DECLARE q_del CURSOR FOR SELECT * FROM gent009 
		WHERE ROWID = vm_rows[vm_row_current]
		FOR UPDATE
	OPEN q_del
	FETCH q_del INTO rm_cta.*
	IF status < 0 THEN
		CALL fl_mensaje_bloqueo_otro_usuario()
		WHENEVER ERROR STOP
		ROLLBACK WORK
		RETURN
	END IF

	LET estado = 'B'
	IF rm_cta.g09_estado <> 'A' THEN
		LET estado = 'A'
	END IF

	UPDATE gent009 SET g09_estado = estado WHERE CURRENT OF q_del
	COMMIT WORK
	CLOSE q_del
	WHENEVER ERROR STOP
	LET int_flag = 0 
	
	CALL fl_mensaje_registro_modificado()
	CLEAR FORM
	CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION muestra_etiquetas()

DEFINE r_banco 		RECORD LIKE gent008.*
DEFINE r_moneda		RECORD LIKE gent013.*
DEFINE r_b10		RECORD LIKE ctbt010.*

CALL fl_lee_banco_general(rm_cta.g09_banco) RETURNING r_banco.*
CALL fl_lee_moneda(rm_cta.g09_moneda) RETURNING r_moneda.*
CALL fl_lee_cuenta(vg_codcia, rm_cta.g09_aux_cont) RETURNING r_b10.*

DISPLAY r_banco.g08_nombre TO n_banco 
DISPLAY r_moneda.g13_nombre TO n_moneda 
DISPLAY r_b10.b10_descripcion TO n_cuenta

IF rm_cta.g09_estado = 'A' THEN
	DISPLAY 'ACTIVO' TO n_estado
ELSE
	DISPLAY 'BLOQUEADO' TO n_estado
END IF

END FUNCTION



FUNCTION muestra_contadores()

DISPLAY "" AT 1,1
DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 70 

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
