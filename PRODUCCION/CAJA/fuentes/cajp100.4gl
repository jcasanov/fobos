------------------------------------------------------------------------------
-- Titulo           : cajp100.4gl - Mantenimiento de Parámetros Generales 
-- Elaboracion      : 01-oct-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun cajp100 base módulo compañía
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_caj		RECORD LIKE cajt000.*
DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_r_rows	ARRAY [50] OF INTEGER

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cajp100.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'cajp100'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()
DEFINE confir		CHAR(6)

CALL fl_nivel_isolation()
LET vm_max_rows	= 50
OPEN WINDOW wf AT 3,2 WITH 10 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_caj FROM "../forms/cajf100_1"
DISPLAY FORM f_caj
INITIALIZE rm_caj.* TO NULL
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Bloquear/Activar'
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		IF vm_num_rows = vm_max_rows THEN
			CALL fl_mensaje_arreglo_lleno()
		ELSE
			CALL control_ingreso()
		END IF
		IF vm_num_rows = 1 THEN
		   IF fl_control_permiso_opcion('Bloquear') THEN
		  	  SHOW OPTION 'Bloquear/Activar'
		   END IF
			
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
		   IF fl_control_permiso_opcion('Bloquear') THEN
				SHOW OPTION 'Bloquear/Activar'
		   END IF
			
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Bloquear/Activar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
		   IF fl_control_permiso_opcion('Bloquear') THEN
				SHOW OPTION 'Bloquear/Activar'
		   END IF
			
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
INITIALIZE rm_caj.* TO NULL
LET rm_caj.j00_estado = 'A'
CLEAR tit_est
CLEAR tit_estado_caj
CLEAR tit_compania
CALL muestra_estado()
CALL leer_datos()
IF NOT int_flag THEN
	INSERT INTO cajt000 VALUES (rm_caj.*)
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



FUNCTION control_consulta()
DEFINE cod_aux      	LIKE cajt000.j00_compania
DEFINE nom_aux      	LIKE gent001.g01_razonsocial
DEFINE query		VARCHAR(400)
DEFINE expr_sql		VARCHAR(400)
DEFINE num_reg		INTEGER

LET int_flag = 0
INITIALIZE cod_aux TO NULL
CLEAR FORM
CONSTRUCT BY NAME expr_sql ON j00_compania
	ON KEY(F2)
		IF infield(j00_compania) THEN
                	CALL fl_ayuda_companias_cajagen()
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
	                IF cod_aux IS NOT NULL THEN
                	        DISPLAY cod_aux TO j00_compania
                        	DISPLAY nom_aux TO tit_compania
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
LET query = 'SELECT *, ROWID FROM cajt000 WHERE ' || expr_sql || ' ORDER BY 1'
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_cons INTO rm_caj.*, num_reg
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



FUNCTION leer_datos ()
DEFINE resp		CHAR(6)
DEFINE cod_cia_aux      LIKE gent001.g01_compania
DEFINE r_act_aux	RECORD LIKE cajt000.*

LET int_flag = 0
INITIALIZE r_act_aux.* TO NULL
INITIALIZE cod_cia_aux TO NULL
INPUT BY NAME rm_caj.j00_compania
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF field_touched(rm_caj.j00_compania) THEN
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
		IF infield(j00_compania) THEN
                	CALL fl_ayuda_compania() RETURNING cod_cia_aux
			LET int_flag = 0
	                IF cod_cia_aux IS NOT NULL THEN
        	        	CALL fl_lee_compania(cod_cia_aux)
					RETURNING rg_cia.*
				LET rm_caj.j00_compania = cod_cia_aux
                	        DISPLAY BY NAME rm_caj.j00_compania
                        	DISPLAY rg_cia.g01_razonsocial TO tit_compania
			END IF
        	END IF
	AFTER FIELD j00_compania
                IF rm_caj.j00_compania IS NOT NULL THEN
                        CALL fl_lee_compania(rm_caj.j00_compania)
                                RETURNING rg_cia.*
                        IF rg_cia.g01_compania IS NULL THEN
                                CALL fgl_winmessage(vg_producto,'Compañía no exi
ste','exclamation')
                                NEXT FIELD j00_compania
                        END IF
                        DISPLAY rg_cia.g01_razonsocial TO tit_compania
                        IF rg_cia.g01_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD j00_compania
                        END IF
                        CALL fl_lee_compania_caja(rm_caj.j00_compania)
                                RETURNING r_act_aux.*
                        IF rm_caj.j00_compania = r_act_aux.j00_compania THEN
                        	CALL fgl_winmessage(vg_producto,'Compañía ya ha sido asignada a caja general','exclamation')
                                NEXT FIELD j00_compania
                        END IF
                ELSE
			CLEAR j00_compania
			CLEAR tit_compania
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
DEFINE num_registro		INTEGER

IF vm_num_rows > 0 THEN
	SELECT * INTO rm_caj.* FROM cajt000 WHERE ROWID = num_registro	
	IF STATUS = NOTFOUND THEN 
		CALL fgl_winmessage (vg_producto,'No existe registro con índice: ' || vm_row_current,'exclamation')
		RETURN
	END IF
	DISPLAY BY NAME rm_caj.j00_compania
 	CALL fl_lee_compania(rm_caj.j00_compania) RETURNING rg_cia.*
      	DISPLAY rg_cia.g01_razonsocial TO tit_compania
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
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_ba CURSOR FOR SELECT * FROM cajt000
	WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_ba
FETCH q_ba INTO rm_caj.*
IF STATUS < 0 THEN
	COMMIT WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF	
CAll fl_mensaje_seguro_ejecutar_proceso()
	RETURNING confir
IF confir = 'Yes' THEN
	LET int_flag = 1
	CALL bloquea_activa_registro()
END IF
COMMIT WORK
WHENEVER ERROR STOP

END FUNCTION



FUNCTION bloquea_activa_registro()
DEFINE estado   CHAR(1)
                                                                                
IF rm_caj.j00_estado = 'A' THEN
        DISPLAY 'BLOQUEADO' TO tit_estado_caj
        LET estado = 'B'
ELSE
        DISPLAY 'ACTIVO' TO tit_estado_caj
        LET estado = 'A'
END IF
DISPLAY estado TO tit_est
UPDATE cajt000 SET j00_estado = estado WHERE CURRENT OF q_ba
LET rm_caj.j00_estado = estado
                                                                                
END FUNCTION



FUNCTION muestra_estado()
IF rm_caj.j00_estado = 'A' THEN
        DISPLAY 'ACTIVO' TO tit_estado_caj
ELSE
        DISPLAY 'BLOQUEADO' TO tit_estado_caj
END IF
DISPLAY rm_caj.j00_estado TO tit_est
                                                                                
END FUNCTION



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
	LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc, 'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
