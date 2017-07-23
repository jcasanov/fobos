------------------------------------------------------------------------------
-- Titulo           : actp100.4gl - Configuración parametros por Compañía 
-- Elaboracion      : 01-oct-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun actp100 base módulo compañía
-- Ultima Correccion: 02-jun-2003
-- Motivo Correccion: (RCA) Revision y Cooreccion Aceros
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_programa	VARCHAR(12)
DEFINE rm_a00		RECORD LIKE actt000.*
DEFINE vm_num_rows	INTEGER
DEFINE vm_row_current	INTEGER
DEFINE vm_max_rows	INTEGER
DEFINE tit_mes		VARCHAR(11)
DEFINE vm_r_rows	ARRAY [50] OF INTEGER



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	--CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'actp100'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_rows	= 1000
OPEN WINDOW wf AT 3,2 WITH 17 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_act FROM "../forms/actf100_1"
DISPLAY FORM f_act
INITIALIZE rm_a00.* TO NULL
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Bloquear/Activar'
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		IF vm_num_rows = vm_max_rows THEN
			CALL fl_mensaje_arreglo_lleno()
		ELSE
			CALL control_ingreso()
		END IF
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Bloquear/Activar'
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
       	COMMAND KEY('M') 'Modificar' 'Modificar registro corriente. '
		CALL control_modificacion()		
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Bloquear/Activar'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Bloquear/Activar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Bloquear/Activar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
	COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro. '
		CALL muestra_siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder'  'Ver anterior registro. '
		CALL muestra_anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
 	COMMAND KEY('B') 'Bloquear/Activar' 'Bloquear o activar registro. '
                CALL bloquear_activar()
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()

CALL fl_retorna_usuario()
INITIALIZE rm_a00.* TO NULL
LET rm_a00.a00_calc_reexp = 'S'
LET rm_a00.a00_estado     = 'A'
LET rm_a00.a00_anopro     = YEAR(TODAY)
LET rm_a00.a00_mespro     = MONTH(TODAY)
CLEAR tit_est, tit_estado_act, tit_compania, tit_aux_rex
CALL muestra_estado()
CALL fl_retorna_nombre_mes(rm_a00.a00_mespro) RETURNING tit_mes
DISPLAY BY NAME rm_a00.a00_anopro, rm_a00.a00_mespro, tit_mes
CALL leer_datos('I')
IF NOT int_flag THEN
	INSERT INTO actt000 VALUES (rm_a00.*)
	LET vm_num_rows = vm_num_rows + 1
	LET vm_row_current = vm_num_rows
	LET vm_r_rows[vm_row_current] = SQLCA.SQLERRD[6] 
	CALL mostrar_registro(vm_r_rows[vm_num_rows])	
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL fl_mensaje_registro_ingresado()
ELSE
	CLEAR FORM
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
END IF

END FUNCTION



FUNCTION control_modificacion()
	
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
IF rm_a00.a00_estado = 'B' THEN
        CALL fl_mensaje_estado_bloqueado()
        RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR
	SELECT * FROM actt000
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_a00.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
CALL leer_datos('M')
IF NOT int_flag THEN
	UPDATE actt000 SET a00_aux_reexp  = rm_a00.a00_aux_reexp,
			   a00_ind_reexp  = rm_a00.a00_ind_reexp,
			   a00_calc_reexp = rm_a00.a00_calc_reexp
			WHERE CURRENT OF q_up
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
ELSE
	ROLLBACK WORK
	CLEAR FORM
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
END IF
 
END FUNCTION



FUNCTION control_consulta()
DEFINE codc_aux      	LIKE actt000.a00_compania
DEFINE nomc_aux      	LIKE gent001.g01_razonsocial
DEFINE cod_aux		LIKE ctbt010.b10_cuenta
DEFINE nom_aux		LIKE ctbt010.b10_descripcion
DEFINE r_a00		RECORD LIKE actt000.*
DEFINE query		VARCHAR(400)
DEFINE expr_sql		VARCHAR(400)
DEFINE num_reg		INTEGER

LET int_flag = 0
INITIALIZE codc_aux, cod_aux TO NULL
CLEAR FORM
CONSTRUCT BY NAME expr_sql ON a00_compania, a00_aux_reexp, a00_ind_reexp,
	a00_anopro, a00_mespro, a00_calc_reexp
	ON KEY(F2)
		IF infield(a00_compania) THEN
                	CALL fl_ayuda_companias_activos()
				RETURNING codc_aux, nomc_aux
			LET int_flag = 0
	                IF codc_aux IS NOT NULL THEN
                	        DISPLAY codc_aux TO a00_compania
                        	DISPLAY nomc_aux TO tit_compania
			END IF
        	END IF
		IF infield(a00_aux_reexp) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, -1)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				DISPLAY cod_aux TO a00_aux_reexp 
				DISPLAY nom_aux TO tit_aux_rex
			END IF 
		END IF
		IF INFIELD(a00_mespro) THEN
			CALL fl_ayuda_mostrar_meses()
				RETURNING r_a00.a00_mespro, tit_mes
			IF r_a00.a00_mespro IS NOT NULL THEN
				DISPLAY BY NAME r_a00.a00_mespro, tit_mes
			END IF
                END IF
END CONSTRUCT
IF int_flag THEN
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	ELSE
		CLEAR FORM
	END IF
	RETURN
END IF
LET query = 'SELECT *, ROWID FROM actt000 ',
		' WHERE ', expr_sql CLIPPED, ' ORDER BY 1'
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_cons INTO rm_a00.*, num_reg
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
		LET vm_num_rows = vm_num_rows - 1
                EXIT FOREACH
        END IF
	LET vm_r_rows[vm_num_rows] = num_reg
END FOREACH
IF vm_num_rows = 0 THEN
	LET int_flag = 0
	CALL fl_mensaje_consulta_sin_registros()
	CLEAR FORM
	LET vm_row_current = 0
ELSE  
	LET vm_row_current = 1
	CALL mostrar_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION leer_datos (flag_mant)
DEFINE flag_mant	CHAR(1)
DEFINE resp		CHAR(6)
DEFINE cod_cia_aux      LIKE gent001.g01_compania
DEFINE cod_aux		LIKE ctbt010.b10_cuenta
DEFINE nom_aux		LIKE ctbt010.b10_descripcion
DEFINE r_act_aux	RECORD LIKE actt000.*
DEFINE r_ctb_aux	RECORD LIKE ctbt010.*

LET int_flag = 0
INITIALIZE r_act_aux.* TO NULL
INITIALIZE r_act_aux.* TO NULL
INITIALIZE cod_cia_aux TO NULL
INITIALIZE cod_aux TO NULL
INPUT BY NAME rm_a00.a00_compania, rm_a00.a00_aux_reexp, rm_a00.a00_ind_reexp,
	rm_a00.a00_calc_reexp
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF field_touched(rm_a00.a00_compania, rm_a00.a00_aux_reexp,
			rm_a00.a00_ind_reexp, rm_a00.a00_calc_reexp)
        	THEN
	               	LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
                		RETURNING resp
        	      	IF resp = 'Yes' THEN
				LET int_flag = 1
                       		CLEAR FORM
	                       	RETURN
        	        END IF
		ELSE
			RETURN
		END IF
	ON KEY(F2)
		IF infield(a00_compania) THEN
                	CALL fl_ayuda_compania() RETURNING cod_cia_aux
			LET int_flag = 0
	                IF cod_cia_aux IS NOT NULL THEN
        	        	CALL fl_lee_compania(cod_cia_aux)
					RETURNING rg_cia.*
				LET rm_a00.a00_compania = cod_cia_aux
                	        DISPLAY BY NAME rm_a00.a00_compania
                        	DISPLAY rg_cia.g01_razonsocial TO tit_compania
			END IF
        	END IF
		IF infield(a00_aux_reexp) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, -1)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				LET rm_a00.a00_aux_reexp = cod_aux
				DISPLAY BY NAME rm_a00.a00_aux_reexp 
				DISPLAY nom_aux TO tit_aux_rex
			END IF 
		END IF
	BEFORE FIELD a00_compania
		IF flag_mant = 'M' THEN
			NEXT FIELD NEXT
		END IF
	BEFORE FIELD a00_aux_reexp
		IF rm_a00.a00_compania IS NULL THEN
			CALL fgl_winmessage(vg_producto,'Ingrese la compañía primero','info')
			NEXT FIELD a00_compania
		END IF
	AFTER FIELD a00_compania
                IF rm_a00.a00_compania IS NOT NULL THEN
                        CALL fl_lee_compania(rm_a00.a00_compania)
                                RETURNING rg_cia.*
                        IF rg_cia.g01_compania IS NULL THEN
                                CALL fgl_winmessage(vg_producto,'Compañía no exi
ste','exclamation')
                                NEXT FIELD a00_compania
                        END IF
                        DISPLAY rg_cia.g01_razonsocial TO tit_compania
                        IF rg_cia.g01_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD a00_compania
                        END IF
                        CALL fl_lee_compania_activos(rm_a00.a00_compania)
                                RETURNING r_act_aux.*
                        IF rm_a00.a00_compania = r_act_aux.a00_compania THEN
                        	CALL fgl_winmessage(vg_producto,'Compañía ya ha sido asignada a activos','exclamation')
                                NEXT FIELD a00_compania
                        END IF
                ELSE
			CLEAR tit_compania
		END IF
	AFTER FIELD a00_aux_reexp
		IF rm_a00.a00_aux_reexp IS NOT NULL THEN
			CALL fl_lee_cuenta(rm_a00.a00_compania,
						rm_a00.a00_aux_reexp)
                        	RETURNING r_ctb_aux.*
			IF r_ctb_aux.b10_cuenta IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Auxiliar de reexpresión no existe para esta compañía','exclamation')
				NEXT FIELD a00_aux_reexp
			END IF
			DISPLAY r_ctb_aux.b10_descripcion TO tit_aux_rex
			IF r_ctb_aux.b10_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD a00_aux_reexp
			END IF
			IF r_ctb_aux.b10_permite_mov = 'N' THEN
				CALL fl_mostrar_mensaje('Auxiliar de reexpresión no permite movimiento.', 'exclamation')
				NEXT FIELD a00_aux_reexp
			END IF
		ELSE
			CLEAR tit_aux_rex
		END IF
END INPUT

END FUNCTION



FUNCTION muestra_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION muestra_anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current	SMALLINT
DEFINE num_rows		SMALLINT
                                                                                
DISPLAY "" AT 1,1
DISPLAY row_current, " de ", num_rows AT 1, 69
                                                                                
END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE r_ctb_aux		RECORD LIKE ctbt010.*
DEFINE num_registro		INTEGER

IF vm_num_rows > 0 THEN
	SELECT * INTO rm_a00.* FROM actt000 WHERE ROWID=num_registro	
	IF STATUS = NOTFOUND THEN
		CALL fgl_winmessage (vg_producto,'No existe registro con índice: ' || vm_row_current,'exclamation')
		RETURN
	END IF
	DISPLAY BY NAME rm_a00.a00_compania,
			rm_a00.a00_aux_reexp,
			rm_a00.a00_ind_reexp,
			rm_a00.a00_calc_reexp,
			rm_a00.a00_anopro,
			rm_a00.a00_mespro
	CALL fl_lee_compania(rm_a00.a00_compania) RETURNING rg_cia.*
        DISPLAY rg_cia.g01_razonsocial TO tit_compania
	CALL fl_lee_cuenta(rm_a00.a00_compania,rm_a00.a00_aux_reexp)
       		RETURNING r_ctb_aux.*
	DISPLAY r_ctb_aux.b10_descripcion TO tit_aux_rex
	CALL fl_retorna_nombre_mes(rm_a00.a00_mespro) RETURNING tit_mes
	DISPLAY BY NAME tit_mes
	CALL muestra_estado()
ELSE
	RETURN
END IF

END FUNCTION



FUNCTION bloquear_activar()
DEFINE confir	CHAR(6)

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
LET int_flag = 0
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_ba CURSOR FOR
	SELECT * FROM actt000
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_ba
FETCH q_ba INTO rm_a00.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF	
WHENEVER ERROR STOP
CAll fl_mensaje_seguro_ejecutar_proceso() RETURNING confir
IF confir <> 'Yes' THEN
	ROLLBACK WORK
	RETURN
END IF
LET int_flag = 1
CALL bloquea_activa_registro()
COMMIT WORK

END FUNCTION



FUNCTION bloquea_activa_registro()
DEFINE estado		LIKE actt000.a00_estado
                                                                                
IF rm_a00.a00_estado = 'A' THEN
        DISPLAY 'BLOQUEADO' TO tit_estado_act
        LET estado = 'B'
ELSE
        DISPLAY 'ACTIVO' TO tit_estado_act
        LET estado = 'A'
END IF
DISPLAY estado TO tit_est
UPDATE actt000 SET a00_estado = estado WHERE CURRENT OF q_ba
LET rm_a00.a00_estado = estado
                                                                                
END FUNCTION



FUNCTION muestra_estado()

IF rm_a00.a00_estado = 'A' THEN
        DISPLAY 'ACTIVO' TO tit_estado_act
ELSE
        DISPLAY 'BLOQUEADO' TO tit_estado_act
END IF
DISPLAY rm_a00.a00_estado TO tit_est
                                                                                
END FUNCTION
