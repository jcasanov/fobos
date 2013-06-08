------------------------------------------------------------------------------
-- Titulo           : rolp242.4gl - Retiro de trabajadores del fondo de cesantia
-- Elaboracion      : 20-nov-2003
-- Autor            : JCM
-- Formato Ejecucion: fglrun rolp242 base modulo compania
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA r_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS


DEFINE rm_par	RECORD 
	n82_cod_trab		LIKE rolt082.n82_cod_trab,
	nomtrab			LIKE rolt030.n30_nombres,	
	n82_banco		LIKE rolt082.n82_banco,
	nombanco		LIKE gent008.g08_nombre,	
	n82_numero_cta 		LIKE rolt082.n82_numero_cta,
	n82_num_cheque		LIKE rolt082.n82_num_cheque,
	n82_fecha		LIKE rolt082.n82_fecha,
	n82_moneda		LIKE rolt082.n82_moneda,
	nommoneda		LIKE gent013.g13_nombre,
	n82_valor		LIKE rolt082.n82_valor, 
	val_poliza		LIKE rolt082.n82_valor, 
	val_rol  		LIKE rolt082.n82_valor, 
	saldo    		LIKE rolt082.n82_valor 
END RECORD
DEFINE rm_n82		RECORD LIKE rolt082.*

DEFINE rm_scr ARRAY[1000]	OF	RECORD 
	n82_cod_trab		LIKE rolt082.n82_cod_trab,
	nomtrab			LIKE rolt030.n30_nombres,	
	n82_fecha		LIKE rolt082.n82_fecha,
	n82_valor		LIKE rolt082.n82_valor 
END RECORD
DEFINE vm_numelm	INTEGER
DEFINE vm_maxelm	INTEGER



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'rolp242'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()
DEFINE tot_retirado		DECIMAL(12,2)

CALL fl_nivel_isolation()
LET vm_max_rows = 1000
LET vm_maxelm = 1000
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12

OPEN WINDOW w_ret AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_ret FROM '../forms/rolf242_1'
DISPLAY FORM f_ret

DISPLAY 'Cod.' 		TO bt_cod_trab
DISPLAY 'Nombre'	TO bt_nomtrab
DISPLAY 'Fecha' 	TO bt_fecha
DISPLAY 'Retirado'	TO bt_retirado

DECLARE q_cur CURSOR FOR 
	SELECT n82_cod_trab, n30_nombres, n82_fecha, n82_valor
	  FROM rolt082, rolt030
	 WHERE n82_compania = vg_codcia
	   AND n30_compania = n82_compania
	   AND n30_cod_trab = n82_cod_trab
         ORDER BY n82_fecha DESC

LET tot_retirado = 0
LET vm_numelm = 1
FOREACH q_cur INTO rm_scr[vm_numelm].*
	LET tot_retirado = tot_retirado + rm_scr[vm_numelm].n82_valor
	LET vm_numelm = vm_numelm + 1
	IF vm_numelm > vm_maxelm THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_numelm = vm_numelm - 1

IF vm_numelm > 0 THEN
	DISPLAY BY NAME tot_retirado
	CALL set_count(vm_numelm)
	DISPLAY ARRAY rm_scr TO ra_scr.*
END IF

CLOSE WINDOW w_ret

OPEN WINDOW w_retiro AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_retiro FROM '../forms/rolf242_2'
DISPLAY FORM f_retiro

LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores()

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Eliminar'
		HIDE OPTION 'Recibo De Pago'
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		IF vm_num_rows = vm_max_rows THEN
			CALL fl_mensaje_arreglo_lleno()
		ELSE
			CALL control_ingreso()
		END IF
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Eliminar'
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Recibo De Pago'
		END IF	
	COMMAND KEY('P') 'Recibo De Pago'	'Imprime el recibo de pago.'
		CALL imprime_recibo()
	COMMAND KEY('E') 'Eliminar' 		'Eliminar registro corriente.'
		CALL control_eliminacion()
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro.'
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Eliminar'
			SHOW OPTION 'Recibo De Pago'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Eliminar'
				HIDE OPTION 'Recibo De Pago'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Eliminar'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Recibo De Pago'
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
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()
DEFINE r_n30			RECORD LIKE rolt030.*
DEFINE r_n80			RECORD LIKE rolt080.*
DEFINE r_n81			RECORD LIKE rolt081.*
DEFINE paridad			LIKE rolt082.n82_paridad

CALL fl_lee_poliza_cesantia_activa(vg_codcia) RETURNING r_n81.*
IF r_n81.n81_compania IS NOT NULL THEN
	CALL fl_mostrar_mensaje('No puede retirar porque existe una poliza activa.', 'stop')	
	RETURN
END IF

CLEAR FORM
INITIALIZE rm_par.* TO NULL

LET rm_par.n82_valor = 0
LET rm_par.val_poliza = 0
LET rm_par.val_rol = 0
LET rm_par.saldo = 0

CALL lee_datos()
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

CALL fl_lee_trabajador_roles(vg_codcia, rm_par.n82_cod_trab) RETURNING r_n30.*

LET paridad = calcula_paridad(rm_par.n82_moneda, r_n30.n30_mon_sueldo)

BEGIN WORK
INSERT INTO rolt082 
	VALUES (vg_codcia,             rm_par.n82_cod_trab,   0,
                rm_par.n82_banco,      rm_par.n82_numero_cta, 
	        rm_par.n82_num_cheque, rm_par.n82_fecha,       
                rm_par.n82_moneda,     paridad, 
		rm_par.n82_valor)
LET vm_num_rows = vm_num_rows + 1
LET vm_row_current = vm_num_rows
LET vm_rows[vm_num_rows] = SQLCA.SQLERRD[6]
CALL lee_muestra_registro(vm_rows[vm_row_current])
DECLARE q_jj CURSOR FOR 
	SELECT * FROM rolt080 WHERE n80_compania = vg_codcia
				AND n80_cod_trab = rm_par.n82_cod_trab
			ORDER BY n80_ano DESC, n80_mes DESC
OPEN  q_jj
FETCH q_jj INTO r_n80.*
	UPDATE rolt080 SET n80_val_retiro = n80_val_retiro - rm_par.n82_valor
		WHERE n80_compania = vg_codcia
		  AND n80_ano      = r_n80.n80_ano
		  AND n80_mes      = r_n80.n80_mes
		  AND n80_cod_trab = r_n80.n80_cod_trab

COMMIT WORK

CALL muestra_contadores()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_eliminacion()
DEFINE r_n80		RECORD LIKE rolt080.*
DEFINE r_n81		RECORD LIKE rolt081.*
DEFINE r_n82		RECORD LIKE rolt082.*
DEFINE resp		CHAR(7)

IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

CALL fl_lee_poliza_cesantia_activa(vg_codcia) RETURNING r_n81.*
IF r_n81.n81_compania IS NOT NULL THEN
	CALL fl_mostrar_mensaje('No puede eliminar el registro porque existe una póliza activa.', 'stop')	
	RETURN
END IF
CALL fl_hacer_pregunta('Seguro de ejecutar proceso','No')
	RETURNING resp
IF resp <> 'Yes' THEN
	RETURN
END IF

CALL lee_muestra_registro(vm_rows[vm_row_current])

WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_upd CURSOR FOR 
	SELECT * FROM rolt082 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_upd
FETCH q_upd INTO r_n82.*
IF STATUS < 0 THEN
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	ROLLBACK WORK
	RETURN
END IF  
WHENEVER ERROR STOP

DECLARE q_up CURSOR FOR 
	SELECT * FROM rolt080 WHERE n80_compania = vg_codcia
				AND n80_cod_trab = r_n82.n82_cod_trab
			ORDER BY n80_ano DESC, n80_mes DESC
OPEN  q_up
FETCH q_up INTO r_n80.*
	UPDATE rolt080 SET n80_val_retiro = n80_val_retiro + r_n82.n82_valor
		WHERE n80_compania = vg_codcia
		  AND n80_ano      = r_n80.n80_ano
		  AND n80_mes      = r_n80.n80_mes
		  AND n80_cod_trab = r_n80.n80_cod_trab
CLOSE q_up
FREE  q_up

DELETE FROM rolt082 WHERE CURRENT OF q_upd

COMMIT WORK
CLOSE q_upd
FREE  q_upd
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION lee_datos()
DEFINE resp 		CHAR(6)
DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_g09		RECORD LIKE gent009.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_b10		RECORD LIKE ctbt010.*

LET INT_FLAG = 0
LET rm_par.n82_fecha = TODAY
OPTIONS INPUT NO WRAP
INPUT BY NAME rm_par.n82_cod_trab WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		RETURN
	ON KEY(F2)
   		CALL fl_ayuda_codigo_empleado(vg_codcia)
                    	RETURNING r_n30.n30_cod_trab, r_n30.n30_nombres
        	IF r_n30.n30_cod_trab IS NOT NULL THEN
                	LET rm_par.n82_cod_trab = r_n30.n30_cod_trab
                	LET rm_par.nomtrab = r_n30.n30_nombres
                	DISPLAY BY NAME rm_par.n82_cod_trab, rm_par.nomtrab
		END IF
	AFTER FIELD n82_cod_trab
		IF rm_par.n82_cod_trab IS NOT NULL THEN
			CALL fl_lee_trabajador_roles(vg_codcia,
						rm_par.n82_cod_trab)
                        	RETURNING r_n30.*
			IF r_n30.n30_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe el código de este empleado en la Compañía.','exclamation')
				NEXT FIELD n82_cod_trab
			END IF
			{
			IF r_n30.n30_estado = 'I' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD n82_cod_trab
			END IF
			}
			LET rm_par.nomtrab = r_n30.n30_nombres
			CALL mostrar_valores(rm_par.n82_cod_trab)
			DISPLAY BY NAME rm_par.*
			IF rm_par.saldo <= 0 THEN
				CALL fgl_winmessage(vg_producto,'Empleado no tiene saldo.','exclamation')
				NEXT FIELD n82_cod_trab
			END IF
		ELSE
			CLEAR nomtrab
		END IF
END INPUT
LET INT_FLAG = 0
OPTIONS INPUT WRAP
INPUT BY NAME rm_par.n82_banco, rm_par.n82_numero_cta, rm_par.n82_num_cheque, 
	      rm_par.n82_moneda, rm_par.n82_valor WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_par.*) THEN
			RETURN
		END IF

		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN
		END IF
	ON KEY(F2)
		IF INFIELD(n82_numero_cta) THEN
			CALL fl_ayuda_cuenta_banco(vg_codcia, 'A')
				RETURNING r_g08.g08_banco, r_g08.g08_nombre,
					  r_g09.g09_tipo_cta, 
					  r_g09.g09_numero_cta
			IF r_g08.g08_banco IS NOT NULL THEN
				LET rm_par.n82_banco = r_g08.g08_banco
				LET rm_par.nombanco  = r_g08.g08_nombre
				LET rm_par.n82_numero_cta = r_g09.g09_numero_cta
				DISPLAY BY NAME rm_par.n82_banco,
						rm_par.nombanco,
						rm_par.n82_numero_cta
			END IF
		END IF
		IF INFIELD(n82_banco) THEN
			CALL fl_ayuda_bancos()
				RETURNING r_g08.g08_banco, r_g08.g08_nombre
			IF r_g08.g08_banco IS NOT NULL THEN
				LET rm_par.n82_banco = r_g08.g08_banco
				LET rm_par.nombanco  = r_g08.g08_nombre
				DISPLAY BY NAME rm_par.n82_banco,
						rm_par.nombanco
			END IF
		END IF
		LET int_flag = 0
	AFTER FIELD n82_banco
		IF rm_par.n82_banco IS NULL THEN
			CONTINUE INPUT
		END IF
		CALL fl_lee_banco_general(rm_par.n82_banco) RETURNING r_g08.*
		IF r_g08.g08_banco IS NOT NULL THEN
			LET rm_par.n82_banco = r_g08.g08_banco
			LET rm_par.nombanco  = r_g08.g08_nombre
			DISPLAY BY NAME rm_par.n82_banco, rm_par.nombanco
		END IF
	AFTER FIELD n82_numero_cta
		IF rm_par.n82_numero_cta IS NOT NULL THEN
			CALL fl_lee_banco_compania(vg_codcia, rm_par.n82_banco,
							rm_par.n82_numero_cta)
				RETURNING r_g09.*
			IF r_g09.g09_numero_cta IS NULL THEN
				CALL fl_mostrar_mensaje('No existe cuenta en este banco.','exclamation')
				NEXT FIELD n82_numero_cta
			END IF
			IF r_g09.g09_estado = 'B' THEN
				CALL fl_mostrar_mensaje('La cuenta esta bloqueada.','exclamation')
				NEXT FIELD n82_numero_cta
			END IF
			CALL fl_lee_cuenta(r_g09.g09_compania,
						r_g09.g09_aux_cont)
				RETURNING r_b10.*
			IF r_b10.b10_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No se puede escoger una cuenta corriente que no tiene auxiliar contable.', 'exclamation')
				NEXT FIELD n82_numero_cta
			END IF
			IF r_b10.b10_estado <> 'A' THEN
				CALL fl_mostrar_mensaje('El auxiliar contable de esta cuenta bancaria esta con estado bloqueado.', 'exclamation')
				NEXT FIELD n82_numero_cta
			END IF
		END IF
	AFTER FIELD n82_valor
		IF rm_par.n82_valor IS NULL THEN
			LET rm_par.n82_valor = 0
			DISPLAY BY NAME rm_par.n82_valor
		END IF
		IF rm_par.n82_valor < 0 THEN
			NEXT FIELD n82_valor
		END IF
		LET rm_par.saldo = rm_par.val_poliza + rm_par.val_rol
		LET rm_par.saldo = rm_par.saldo - rm_par.n82_valor
		DISPLAY BY NAME rm_par.saldo
		IF rm_par.saldo < 0 THEN
			CALL fl_mostrar_mensaje('No se puede retirar nás de lo que tiene el empleado.', 'exclamation')
			NEXT FIELD n82_valor
		END IF
	AFTER INPUT
		IF rm_par.n82_valor = 0 THEN
			CALL fl_mostrar_mensaje('Digite valor a retirar.', 'exclamation')
			NEXT FIELD n82_valor
		END IF
		IF rm_par.n82_numero_cta IS NOT NULL THEN
			CALL fl_lee_banco_compania(vg_codcia, rm_par.n82_banco,
				rm_par.n82_numero_cta) RETURNING r_g09.*
			IF r_g09.g09_numero_cta IS NULL THEN
				CALL fl_mostrar_mensaje('No existe la cuenta.', 'stop')
				NEXT FIELD n82_numero_cta
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION control_consulta()
DEFINE resp 		CHAR(6)
DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)
DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_g09		RECORD LIKE gent009.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_n30		RECORD LIKE rolt030.*

CLEAR FORM
LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql ON n82_cod_trab, n82_banco, n82_numero_cta,
			      n82_num_cheque, n82_fecha, n82_moneda, n82_valor
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(n82_cod_trab,   n82_banco, n82_numero_cta,
				     n82_num_cheque, n82_fecha, n82_moneda, 
                                     n82_valor) 
		THEN
			RETURN
		END IF

		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN
		END IF
	ON KEY(F2)
		IF INFIELD(n82_cod_trab) THEN
                        CALL fl_ayuda_codigo_empleado(vg_codcia)
                                RETURNING r_n30.n30_cod_trab, r_n30.n30_nombres
                        IF r_n30.n30_cod_trab IS NOT NULL THEN
                                LET rm_par.n82_cod_trab = r_n30.n30_cod_trab
                                LET rm_par.nomtrab = r_n30.n30_nombres
                                DISPLAY BY NAME rm_par.n82_cod_trab,
						rm_par.nomtrab
                        END IF
                END IF
		IF INFIELD(n82_numero_cta) THEN
			CALL fl_ayuda_cuenta_banco(vg_codcia, 'T')
				RETURNING r_g08.g08_banco, r_g08.g08_nombre,
					  r_g09.g09_tipo_cta, 
					  r_g09.g09_numero_cta
			IF r_g08.g08_banco IS NOT NULL THEN
				LET rm_par.n82_banco = r_g08.g08_banco
				LET rm_par.nombanco  = r_g08.g08_nombre
				LET rm_par.n82_numero_cta = r_g09.g09_numero_cta
				DISPLAY BY NAME rm_par.n82_banco,
						rm_par.nombanco,
						rm_par.n82_numero_cta
			END IF
		END IF
		IF INFIELD(n82_banco) THEN
			CALL fl_ayuda_bancos()
				RETURNING r_g08.g08_banco, r_g08.g08_nombre
			IF r_g08.g08_banco IS NOT NULL THEN
				LET rm_par.n82_banco = r_g08.g08_banco
				LET rm_par.nombanco  = r_g08.g08_nombre
				DISPLAY BY NAME rm_par.n82_banco,
						rm_par.nombanco
			END IF
		END IF
		IF INFIELD(n82_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING r_g13.g13_moneda, r_g13.g13_nombre,
					  r_g13.g13_decimales
			IF r_g13.g13_moneda IS NOT NULL THEN
				LET rm_par.n82_moneda = r_g13.g13_moneda
				LET rm_par.nommoneda  = r_g13.g13_nombre
				DISPLAY BY NAME rm_par.n82_moneda,
					 	rm_par.nommoneda
			END IF
		END IF
		LET int_flag = 0
END CONSTRUCT

IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET query = 'SELECT *, ROWID FROM rolt082 WHERE n82_compania = ', vg_codcia, 
		' AND ', expr_sql, ' ORDER BY 1, 2, 3' 
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_n82.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > 1000 THEN
		EXIT FOREACH
	END IF	
END FOREACH 
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN 
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_row_current = 0
	LET vm_num_rows = 0
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
DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_n30		RECORD LIKE rolt030.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF

SELECT * INTO rm_n82.* FROM rolt082 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

LET rm_par.n82_cod_trab   = rm_n82.n82_cod_trab
LET rm_par.n82_banco      = rm_n82.n82_banco
LET rm_par.n82_numero_cta = rm_n82.n82_numero_cta
LET rm_par.n82_num_cheque = rm_n82.n82_num_cheque
LET rm_par.n82_fecha      = rm_n82.n82_fecha
LET rm_par.n82_moneda     = rm_n82.n82_moneda
LET rm_par.n82_valor      = rm_n82.n82_valor

CALL fl_lee_banco_general(rm_par.n82_banco) RETURNING r_g08.*
LET rm_par.nombanco = r_g08.g08_nombre

CALL fl_lee_moneda(rm_par.n82_moneda) RETURNING r_g13.*
LET rm_par.nommoneda = r_g13.g13_nombre
CALL fl_lee_trabajador_roles(vg_codcia, rm_par.n82_cod_trab)
           RETURNING r_n30.*
LET rm_par.nomtrab = r_n30.n30_nombres

DISPLAY BY NAME rm_par.*

CALL muestra_contadores()

END FUNCTION



FUNCTION muestra_contadores()

DISPLAY "" AT 1,1
DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 70 

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



FUNCTION mostrar_valores(cod_trab)
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_n80		RECORD LIKE rolt080.*
DEFINE r_n81		RECORD LIKE rolt081.*
DEFINE r_n83		RECORD LIKE rolt083.*

DEFINE query		VARCHAR(500)

DEFINE val_poliza	LIKE rolt080.n80_val_retiro
DEFINE val_acum  	LIKE rolt080.n80_val_retiro

INITIALIZE r_n80.*, r_n81.*, r_n83.* TO NULL
DECLARE q_pol CURSOR FOR 
	SELECT * FROM rolt081
		WHERE n81_compania = vg_codcia
		ORDER BY n81_fec_vcto DESC

OPEN  q_pol
FETCH q_pol INTO r_n81.*
	IF STATUS = NOTFOUND THEN
		LET val_poliza = 0
	ELSE
		SELECT * INTO r_n83.* FROM rolt083
			WHERE n83_compania   = vg_codcia
	 		  AND n83_num_poliza = r_n81.n81_num_poliza
	 		  AND n83_cod_trab   = cod_trab

		IF r_n83.n83_compania IS NULL THEN
			LET val_poliza = 0
		ELSE
			LET val_poliza = r_n83.n83_cap_trab  + 
                                         r_n83.n83_cap_patr  +
		                         r_n83.n83_cap_int   + 
                                         r_n83.n83_cap_dscto + 
                                         r_n83.n83_val_int   + 
                                         r_n83.n83_val_dscto
		END IF
	END IF
CLOSE q_pol
FREE  q_pol

DECLARE q_val CURSOR FOR 
	SELECT * FROM rolt080 
		WHERE n80_compania = vg_codcia
		  AND n80_cod_trab = cod_trab
		ORDER BY n80_ano DESC, n80_mes DESC
OPEN  q_val
FETCH q_val INTO r_n80.*
	IF STATUS = NOTFOUND THEN
		LET val_acum = 0
	ELSE
		LET val_acum = 0
		IF r_n81.n81_compania IS NOT NULL THEN
			IF r_n80.n80_ano <= YEAR(r_n81.n81_fecha_fin) AND
			   r_n80.n80_mes = MONTH(r_n81.n81_fecha_fin)
			THEN
				LET val_acum = 0
			ELSE
				LET val_acum = r_n80.n80_sac_trab  +
					       r_n80.n80_sac_patr  +
					       r_n80.n80_sac_int   +
					       r_n80.n80_sac_dscto +
					       r_n80.n80_val_retiro
				CALL fl_lee_moneda(r_n80.n80_moneda)
					RETURNING r_g13.*
				LET rm_par.n82_moneda = r_g13.g13_moneda
				LET rm_par.nommoneda  = r_g13.g13_nombre
			END IF
		END IF
	END IF
CLOSE q_val
FREE  q_val

LET rm_par.val_poliza = val_poliza
LET rm_par.val_rol    = val_acum - val_poliza
LET rm_par.saldo      = val_acum

END FUNCTION



FUNCTION imprime_recibo()
DEFINE comando		VARCHAR(1000)

LET comando = ' fglrun rolp443 ', vg_base, ' ', vg_modulo, ' ', vg_codcia,
	      rm_n82.n82_cod_trab, ' ', rm_n82.n82_secuencia

RUN comando

END FUNCTION
