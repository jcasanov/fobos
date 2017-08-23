-------------------------------------------------------------------------------
-- Titulo               : repp101.4gl -- Mantenimiento de Vendedores
-- Elaboración          : 3-sep-2001
-- Autor                : GVA
-- Formato de Ejecución : fglrun repp101.4gl base RE 1
-- Ultima Correción     : 4-sep-2001
-- Motivo Corrección    : 2
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_vend 	RECORD LIKE rept001.*
DEFINE rm_rol 	RECORD LIKE rolt030.*
DEFINE vm_r_rows ARRAY[1000] OF INTEGER -- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS
DEFINE vm_flag_mant         CHAR(1)



MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp101.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN
	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto.','stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
     	EXIT PROGRAM
END IF
LET vg_base	= arg_val(1)
LET vg_modulo	= arg_val(2)
LET vg_codcia	= arg_val(3)
LET vg_proceso	= 'repp101'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_rows = 1000
OPEN WINDOW w_vend AT 3,2 WITH 18 ROWS, 80 COLUMNS 
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPEN FORM f_vend FROM '../forms/repf101_1'
DISPLAY FORM f_vend
INITIALIZE rm_vend.* TO NULL
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
		CALL control_ingreso()
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
	COMMAND KEY('M') 'Modificar' 'Modificar registro corriente'
		IF vm_num_rows > 0 THEN
			CALL control_modificacion()
		ELSE
			CALL fl_mensaje_consultar_primero()
		END IF	
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
                IF vm_row_current < vm_num_rows THEN
                        LET vm_row_current = vm_row_current + 1
                END IF
                CALL lee_muestra_registro(vm_r_rows[vm_row_current])
                CALL muestra_contadores(vm_row_current, vm_num_rows)
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
        COMMAND KEY('R') 'Retroceder'  'Ver anterior registro. '
                IF vm_row_current > 1 THEN
                        LET vm_row_current = vm_row_current - 1
                END IF
                CALL lee_muestra_registro(vm_r_rows[vm_row_current])
                CALL muestra_contadores(vm_row_current, vm_num_rows)
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('E') 'Bloquear/Activar' 'Bloquear o activar registro. '
		CALL control_bloqueo_activacion()
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_consulta()
DEFINE codrol		LIKE rept001.r01_codrol
DEFINE codigo		LIKE rept001.r01_codigo
DEFINE nombre		LIKE rept001.r01_nombres
DEFINE nomrol		LIKE rolt030.n30_nombres
DEFINE r_g05		RECORD LIKE gent005.*
DEFINE expr_sql		VARCHAR(1200)
DEFINE query		VARCHAR(800)

CLEAR FORM
INITIALIZE codigo TO NULL
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON r01_codigo, r01_nombres, r01_iniciales,
	r01_estado, r01_codrol, r01_mod_descto, r01_tipo, r01_user_owner,
	r01_usuario, r01_fecing
	ON KEY(F2)
		IF INFIELD(r01_codigo) THEN
			CALL fl_ayuda_vendedores(vg_codcia, 'T', 'T')
			RETURNING codigo, nombre
			IF codigo IS NOT NULL THEN
			    LET rm_vend.r01_codigo = codigo
			    LET rm_vend.r01_nombres  = nombre
			    DISPLAY BY NAME rm_vend.r01_codigo,
			                    rm_vend.r01_nombres
			END IF
		END IF
		IF INFIELD(r01_codrol) THEN
			CALL fl_ayuda_codigo_empleado(vg_codcia)
			 RETURNING codrol, nomrol
			IF codrol IS NOT NULL THEN
			    LET rm_vend.r01_codrol = codrol
			    DISPLAY BY NAME rm_vend.r01_codrol
			END IF
		END IF
		IF INFIELD(r01_user_owner) THEN
			CALL fl_ayuda_usuarios("T") RETURNING r_g05.g05_usuario,
							   r_g05.g05_nombres
			IF r_g05.g05_usuario IS NOT NULL THEN
				LET rm_vend.r01_user_owner = r_g05.g05_usuario
				DISPLAY BY NAME rm_vend.r01_user_owner
			END IF
		END IF
		LET int_flag = 0
END CONSTRUCT
IF int_flag THEN
	CLEAR FORM
	IF vm_num_rows >0 THEN
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	END IF
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	RETURN
END IF
LET query = 'SELECT *, ROWID FROM rept001 WHERE r01_compania = ',
	     vg_codcia, ' AND ', expr_sql CLIPPED, ' ORDER BY 3'
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_vend.*, vm_r_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_row_current = 0
	CALL muestra_contadores(vm_row_current, vm_num_rows)
        CLEAR FORM
        RETURN
END IF
LET vm_row_current = 1
CALL lee_muestra_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION control_ingreso()
DEFINE aux_row		INTEGER	

LET vm_flag_mant = 'I'
CLEAR FORM
INITIALIZE rm_vend.* TO NULL
LET rm_vend.r01_fecing     = fl_current()
LET rm_vend.r01_usuario    = vg_usuario
LET rm_vend.r01_compania   = vg_codcia
LET rm_vend.r01_estado     = 'A'
LET rm_vend.r01_tipo       = 'I'
LET rm_vend.r01_mod_descto = 'N'
DISPLAY BY NAME rm_vend.r01_mod_descto, rm_vend.r01_estado, rm_vend.r01_fecing,
		rm_vend.r01_usuario
DISPLAY 'ACTIVO' TO tit_estado
SELECT MAX(r01_codigo) + 1 INTO rm_vend.r01_codigo FROM rept001
        WHERE r01_compania = vg_codcia
        IF rm_vend.r01_codigo IS NULL THEN
                LET rm_vend.r01_codigo = 1
        END IF
CALL lee_datos()
IF NOT int_flag THEN
	BEGIN WORK
	WHENEVER ERROR CONTINUE
	INSERT INTO rept001 VALUES (rm_vend.*)
	WHENEVER ERROR STOP
	IF STATUS < 0 THEN
	    SELECT MAX(r01_codigo) + 1 INTO rm_vend.r01_codigo FROM rept001
                   WHERE r01_compania = vg_codcia
            IF rm_vend.r01_codigo IS NULL THEN
                 LET rm_vend.r01_codigo = 1
            END IF
	    INSERT INTO rept001 VALUES (rm_vend.*)
	END IF 
	LET aux_row = SQLCA.SQLERRD[6] 
	COMMIT WORK
        IF vm_num_rows = vm_max_rows THEN
                LET vm_num_rows = 1
        ELSE
                LET vm_num_rows = vm_num_rows + 1
        END IF
	LET vm_r_rows[vm_num_rows] = aux_row
	LET vm_row_current = vm_num_rows
	CALL fl_mensaje_registro_ingresado()
END IF
IF vm_num_rows > 0 THEN
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION


                                                                                
FUNCTION control_modificacion()

LET vm_flag_mant = 'M'
IF rm_vend.r01_estado <> 'A' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR
	SELECT * FROM rept001
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_vend.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
CALL lee_datos()
IF NOT int_flag THEN
    	UPDATE rept001 SET r01_nombres    = rm_vend.r01_nombres,
		       	   r01_iniciales  = rm_vend.r01_iniciales,
			   r01_tipo       = rm_vend.r01_tipo, 
			   r01_mod_descto = rm_vend.r01_mod_descto, 
			   r01_user_owner = rm_vend.r01_user_owner, 
			   r01_codrol     = rm_vend.r01_codrol
		WHERE CURRENT OF q_up
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
ELSE
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION control_bloqueo_activacion()
DEFINE resp    	CHAR(6)
DEFINE i	SMALLINT
DEFINE mensaje	VARCHAR(20)
DEFINE estado	CHAR(1)

LET int_flag = 0
IF rm_vend.r01_codigo IS NULL OR vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
LET mensaje = 'Seguro de bloquear'
IF rm_vend.r01_estado <> 'A' THEN
	LET mensaje = 'Seguro de activar'
END IF
CALL fl_mensaje_seguro_ejecutar_proceso()
	RETURNING resp
IF resp = 'Yes' THEN
	BEGIN WORK
	WHENEVER ERROR CONTINUE
	DECLARE q_del CURSOR FOR SELECT * FROM rept001 
		WHERE ROWID = vm_r_rows[vm_row_current]
		FOR UPDATE
	OPEN q_del
	FETCH q_del INTO rm_vend.*
	IF STATUS < 0 THEN
		ROLLBACK WORK
		CALL fl_mensaje_bloqueo_otro_usuario()
		WHENEVER ERROR STOP
		RETURN
	END IF
	WHENEVER ERROR STOP
	LET estado = 'B'
	IF rm_vend.r01_estado <> 'A' THEN
		LET estado = 'A'
	END IF
	UPDATE rept001 SET r01_estado = estado WHERE CURRENT OF q_del
	COMMIT WORK
	LET int_flag = 1
	CALL fl_mensaje_registro_modificado()
	CLEAR FORM	
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION lee_datos()
DEFINE  resp    	CHAR(6)
DEFINE 	serial 	 	LIKE rept001.r01_codigo
DEFINE nomrol		LIKE rolt030.n30_nombres
DEFINE	iniciales	LIKE rept001.r01_iniciales
DEFINE 	codrol    	LIKE rept001.r01_codrol
DEFINE r_g05		RECORD LIKE gent005.*
DEFINE mensaje		VARCHAR(100)

OPTIONS INPUT WRAP
LET int_flag = 0
INPUT BY NAME rm_vend.r01_nombres, rm_vend.r01_iniciales, rm_vend.r01_codrol,
	      rm_vend.r01_mod_descto, rm_vend.r01_tipo, rm_vend.r01_user_owner
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	 IF field_touched(rm_vend.r01_nombres, rm_vend.r01_iniciales,
				  rm_vend.r01_codrol, rm_vend.r01_mod_descto,
				  rm_vend.r01_tipo, rm_vend.r01_user_owner)
                 THEN
                        LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
                        	RETURNING resp
                        IF resp = 'Yes' THEN
                           LET int_flag = 1
                           IF vm_flag_mant = 'I' THEN
				 CLEAR FORM
			   END IF
                           RETURN
                        END IF
                ELSE
                        IF vm_flag_mant = 'I' THEN
				CLEAR FORM
			END IF
		        RETURN
                END IF
	ON KEY(F2)
		IF INFIELD(r01_codrol) THEN
			CALL fl_ayuda_codigo_empleado(vg_codcia)
			  RETURNING codrol, nomrol
			IF codrol IS NOT NULL THEN
			    LET rm_vend.r01_codrol = codrol
			    DISPLAY BY NAME rm_vend.r01_codrol
			END IF
		END IF
		IF INFIELD(r01_user_owner) THEN
			CALL fl_ayuda_usuarios("A") RETURNING r_g05.g05_usuario,
							   r_g05.g05_nombres
			IF r_g05.g05_usuario IS NOT NULL THEN
				LET rm_vend.r01_user_owner = r_g05.g05_usuario
				DISPLAY BY NAME rm_vend.r01_user_owner
			END IF
		END IF
		LET int_flag = 0
	AFTER FIELD r01_user_owner
		IF rm_vend.r01_user_owner IS NOT NULL THEN
			CALL fl_lee_usuario(rm_vend.r01_user_owner)
				RETURNING r_g05.*
			IF r_g05.g05_usuario IS NULL THEN
				CALL fl_mostrar_mensaje('No existe este usuario.','exclamation')
				NEXT FIELD r01_user_owner
			END IF
		END IF
	AFTER INPUT
	    IF rm_vend.r01_codrol IS NOT NULL THEN
		CALL fl_lee_trabajador_roles(vg_codcia, rm_vend.r01_codrol)
			RETURNING rm_rol.*
		IF rm_rol.n30_nombres  IS NULL THEN
			CALL fl_mostrar_mensaje('No existe código de rol.','exclamation')
		     	NEXT FIELD r01_codrol 
		END IF
		IF rm_rol.n30_estado <> 'A' THEN
			CALL fl_mostrar_mensaje('Código de Rol no esta con estado ACTIVO.', 'exclamation')
			NEXT FIELD r01_codrol
		END IF
            ELSE
	        LET int_flag = 0
            END IF
		INITIALIZE serial TO NULL
		SELECT r01_codigo, r01_iniciales INTO serial, iniciales
		 FROM rept001
      		 WHERE r01_compania  = vg_codcia 
		 AND   r01_iniciales = rm_vend.r01_iniciales	
		IF status <> NOTFOUND THEN
		   IF vm_flag_mant = 'I' OR
		      (vm_flag_mant = 'M' AND rm_vend.r01_codigo <> serial)
		   THEN
				LET mensaje = 'Las iniciales ya fueron asignadas ' ||
						'al vendedor de código  '|| serial
				CALL fl_mostrar_mensaje(mensaje,'exclamation')
		      	NEXT FIELD r01_iniciales
		   END IF
		END IF
END INPUT

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_vend.* FROM rept001 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
DISPLAY BY NAME rm_vend.r01_codigo, rm_vend.r01_nombres, rm_vend.r01_iniciales, 
		rm_vend.r01_estado, rm_vend.r01_tipo, rm_vend.r01_codrol,
		rm_vend.r01_usuario, rm_vend.r01_fecing, rm_vend.r01_mod_descto,		rm_vend.r01_user_owner
IF rm_vend.r01_estado = 'A' THEN
	DISPLAY 'ACTIVO' TO tit_estado
ELSE
	DISPLAY 'BLOQUEADO' TO tit_estado
END IF

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current              SMALLINT
DEFINE num_rows                 SMALLINT
                                                                                
DISPLAY "" AT 1,1
DISPLAY row_current, " de ", num_rows AT 1, 69
                                                                                
END FUNCTION
