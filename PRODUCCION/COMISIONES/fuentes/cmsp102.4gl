{*
 * Titulo               : cmsp102.4gl -- Mantenimiento de comisionistas
 * Elaboración          : 09-jun-2009
 * Autor                : JCM
 * Formato de Ejecución : fglrun cmsp102 base modulo compania
 *}
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_comi 	RECORD LIKE cmst002.*
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
CALL startlog('../logs/cmsp102.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN
     CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto','stop')
     EXIT PROGRAM
END IF
LET vg_base	= arg_val(1)
LET vg_modulo	= arg_val(2)
LET vg_codcia	= arg_val(3)
LET vg_proceso	= 'cmsp102'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_rows = 1000
OPEN WINDOW w_comi AT 3,2 WITH 15 ROWS, 80 COLUMNS 
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPEN FORM f_comi FROM '../forms/cmsf102_1'
DISPLAY FORM f_comi
INITIALIZE rm_comi.* TO NULL
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
DEFINE codigo		LIKE cmst002.c02_codigo
DEFINE nombre		LIKE cmst002.c02_nombres
DEFINE r_r01		RECORD LIKE rept001.*
DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)

CLEAR FORM
LET int_flag = 0
INITIALIZE codigo TO NULL
CONSTRUCT BY NAME expr_sql ON c02_codigo, c02_nombres,c02_iniciales, c02_estado,
 			      c02_vendrep,  c02_usuario, c02_fecing
	ON KEY(F2)
		IF INFIELD(c02_codigo) THEN
			CALL fl_ayuda_comisionistas(vg_codcia)
			RETURNING codigo, nombre
			IF codigo IS NOT NULL THEN
			    LET rm_comi.c02_codigo = codigo
			    LET rm_comi.c02_nombres  = nombre
			    DISPLAY BY NAME rm_comi.c02_codigo,
			                    rm_comi.c02_nombres
			END IF
		END IF
		IF INFIELD(c02_vendrep) THEN
			CALL fl_ayuda_vendedores(vg_codcia)
			 RETURNING r_r01.r01_codigo, r_r01.r01_nombres
			IF r_r01.r01_codigo IS NOT NULL THEN
			    LET rm_comi.c02_vendrep = r_r01.r01_codigo
			    DISPLAY BY NAME rm_comi.c02_vendrep
				DISPLAY r_r01.r01_nombres TO nomvendrep	
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
LET query = 'SELECT *, ROWID FROM cmst002 WHERE c02_compania = ',
	     vg_codcia, ' AND ', expr_sql CLIPPED, ' ORDER BY 3'
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_comi.*, vm_r_rows[vm_num_rows]
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

LET vm_flag_mant = 'I'
CLEAR FORM
INITIALIZE rm_comi.* TO NULL
LET rm_comi.c02_fecing     = CURRENT
LET rm_comi.c02_usuario    = vg_usuario
LET rm_comi.c02_compania   = vg_codcia
LET rm_comi.c02_estado     = 'A'
DISPLAY BY NAME rm_comi.c02_estado, rm_comi.c02_fecing, rm_comi.c02_usuario
DISPLAY 'ACTIVO' TO tit_estado
SELECT MAX(c02_codigo) + 1 INTO rm_comi.c02_codigo FROM cmst002
        WHERE c02_compania = vg_codcia
        IF rm_comi.c02_codigo IS NULL THEN
                LET rm_comi.c02_codigo = 1
        END IF
CALL lee_datos()
IF NOT int_flag THEN
	BEGIN WORK
	INSERT INTO cmst002 VALUES (rm_comi.*)
	COMMIT WORK
        IF vm_num_rows = vm_max_rows THEN
                LET vm_num_rows = 1
        ELSE
                LET vm_num_rows = vm_num_rows + 1
        END IF
	LET vm_r_rows[vm_num_rows] = SQLCA.SQLERRD[6] 
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
IF rm_comi.c02_estado <> 'A' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_up CURSOR FOR SELECT * FROM cmst002 WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_comi.*
IF status < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
CALL lee_datos()
IF NOT int_flag THEN
    	UPDATE cmst002
	 SET	c02_nombres    = rm_comi.c02_nombres,
	     	c02_iniciales  = rm_comi.c02_iniciales,
		c02_vendrep     = rm_comi.c02_vendrep
		WHERE CURRENT OF q_up
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
ELSE
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF

END FUNCTION


FUNCTION control_bloqueo_activacion()
DEFINE resp    	CHAR(6)
DEFINE i	SMALLINT
DEFINE mensaje	VARCHAR(20)
DEFINE estado	CHAR(1)

LET int_flag = 0
IF rm_comi.c02_codigo IS NULL OR vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
LET mensaje = 'Seguro de bloquear'
IF rm_comi.c02_estado <> 'A' THEN
	LET mensaje = 'Seguro de activar'
END IF
CALL fl_mensaje_seguro_ejecutar_proceso()
	RETURNING resp
IF resp = 'Yes' THEN
WHENEVER ERROR CONTINUE
	BEGIN WORK
	DECLARE q_del CURSOR FOR SELECT * FROM cmst002 
		WHERE ROWID = vm_r_rows[vm_row_current]
		FOR UPDATE
	OPEN q_del
	FETCH q_del INTO rm_comi.*
	IF status < 0 THEN
		COMMIT WORK
		CALL fl_mensaje_bloqueo_otro_usuario()
		WHENEVER ERROR STOP
		RETURN
	END IF
	LET estado = 'B'
	IF rm_comi.c02_estado <> 'A' THEN
		LET estado = 'A'
	END IF
	UPDATE cmst002 SET c02_estado = estado WHERE CURRENT OF q_del
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
DEFINE 	serial 	 	LIKE cmst002.c02_codigo
DEFINE 	iniciales	LIKE cmst002.c02_iniciales
DEFINE 	r_r01		RECORD LIKE rept001.*

OPTIONS INPUT WRAP
LET int_flag = 0
INPUT BY NAME rm_comi.c02_nombres, rm_comi.c02_iniciales, rm_comi.c02_vendrep
	      WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	 IF field_touched( rm_comi.c02_nombres, rm_comi.c02_iniciales,
				   rm_comi.c02_vendrep)
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
		IF INFIELD(c02_vendrep) THEN
			CALL fl_ayuda_vendedores(vg_codcia)
			  RETURNING r_r01.r01_codigo, r_r01.r01_nombres
			IF r_r01.r01_codigo IS NOT NULL THEN
			    LET rm_comi.c02_vendrep = r_r01.r01_codigo
			    DISPLAY BY NAME rm_comi.c02_vendrep
			    DISPLAY r_r01.r01_nombres TO nomvendrep
			ELSE
				CLEAR nomvendrep
			END IF
		END IF
		LET int_flag = 0
	AFTER FIELD c02_vendrep	
	    IF rm_comi.c02_vendrep IS NOT NULL THEN
			CALL fl_lee_vendedor_rep(vg_codcia, rm_comi.c02_vendrep)
				RETURNING r_r01.*
			IF r_r01.r01_codigo  IS NULL THEN
	            CALL fgl_winmessage(vg_producto, 'No existe código de vendedor', 					 'exclamation')
		    	NEXT FIELD c02_vendrep 
			END IF
		ELSE 
			CLEAR nomvendrep
		END IF	
	AFTER INPUT
		INITIALIZE serial TO NULL
		SELECT c02_codigo, c02_iniciales INTO serial, iniciales
		 FROM cmst002
      		 WHERE c02_compania  = vg_codcia 
		 AND   c02_iniciales = rm_comi.c02_iniciales	
		IF status <> NOTFOUND THEN
		   IF vm_flag_mant = 'I' OR
		      (vm_flag_mant = 'M' AND rm_comi.c02_codigo <> serial)
		   THEN
		   	CALL fgl_winmessage(vg_producto,'Las iniciales ya fueron asignadas al comisionista de código  '|| serial,'exclamation')
		      	NEXT FIELD c02_iniciales
		   END IF
		END IF
END INPUT

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER
DEFINE r_r01		RECORD LIKE rept001.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_comi.* FROM cmst002 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
DISPLAY BY NAME rm_comi.c02_codigo, rm_comi.c02_nombres, rm_comi.c02_iniciales, 
		rm_comi.c02_estado, rm_comi.c02_vendrep,
		rm_comi.c02_usuario, rm_comi.c02_fecing
IF rm_comi.c02_estado = 'A' THEN
	DISPLAY 'ACTIVO' TO tit_estado
ELSE
	DISPLAY 'BLOQUEADO' TO tit_estado
END IF
CALL fl_lee_vendedor_rep(vg_codcia, rm_comi.c02_vendrep) RETURNING r_r01.*
DISPLAY r_r01.r01_nombres TO nomvendrep

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current              SMALLINT
DEFINE num_rows                 SMALLINT
                                                                                
DISPLAY "" AT 1,1
DISPLAY row_current, " de ", num_rows AT 1, 69
                                                                                
END FUNCTION



FUNCTION validar_parametros()
                                                                                
CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
        CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'sto
p')
        EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
        CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 'st
op')
        EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
     CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || vg_codcia, 			 'stop')
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
      CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| vg_codloc, 			  'stop')
      EXIT PROGRAM
END IF
                                                                                
END FUNCTION

