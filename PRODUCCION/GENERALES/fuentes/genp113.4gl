                                                                                
-------------------------------------------------------------------------------
-- Titulo               : genp113.4gl -- Mantenimiento de Control de Secuencia
-- Elaboración          : 29-ago-2001
-- Autor                : GVA
-- Formato de Ejecución : fglrun  genp113.4gl base GE 1
-- Ultima Correción     : 3-sep-2001
-- Motivo Corrección    : 2
--------------------------------------------------------------------------------
                                                                                


GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_csec  	 RECORD LIKE gent015.*
DEFINE rm_mod 	  	 RECORD LIKE gent050.*
DEFINE rm_loc   	 RECORD LIKE gent002.*
DEFINE vm_r_rows ARRAY[1000] OF INTEGER -- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current   SMALLINT        -- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows      SMALLINT        -- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- CANTIDAD DE FILAS LEIDAS
DEFINE vm_demonios      VARCHAR(12)
DEFINE vm_flag_mant     CHAR(1)


MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN
     CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto','stop')
     EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'genp113'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()
                                                                                
END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_rows = 1000
OPEN WINDOW w_csec AT 3,2 WITH 17 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPEN FORM f_csec FROM '../forms/genf113_1'
DISPLAY FORM f_csec
INITIALIZE rm_csec.* TO NULL
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
        COMMAND KEY('M') 'Modificar' 'Modificar registro corriente. '
                IF vm_num_rows > 0 THEN
                        CALL control_modificacion()
                ELSE
			CALL fl_mensaje_consultar_primero()
		END IF
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Modificar'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
	COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro'
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
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_consulta()
DEFINE codigo		LIKE gent015.g15_modulo
DEFINE nombre		LIKE gent015.g15_nombre
DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)

CLEAR FORM

LET int_flag = 0
INITIALIZE codigo TO NULL
CONSTRUCT BY NAME expr_sql ON g15_localidad, g15_modulo, g15_bodega, g15_tipo, 
                              g15_nombre, g15_numero, g15_usuario, g15_fecing
	ON KEY(F2)
		IF INFIELD(g15_localidad) THEN
		     CALL fl_ayuda_localidad(vg_codcia)
			     RETURNING rm_loc.g02_localidad, rm_loc.g02_nombre
			IF rm_loc.g02_localidad IS NOT NULL THEN
			    LET rm_csec.g15_localidad = rm_loc.g02_localidad
			    DISPLAY BY NAME rm_csec.g15_localidad
			    DISPLAY rm_loc.g02_nombre TO nom_loc
			END IF
		END IF
  		IF INFIELD(g15_modulo) THEN
                        CALL fl_ayuda_modulos()
				RETURNING rm_mod.g50_modulo, rm_mod.g50_nombre
                        IF rm_mod.g50_modulo IS NOT NULL THEN
                            LET rm_csec.g15_modulo = rm_mod.g50_modulo
                            DISPLAY BY NAME rm_csec.g15_modulo
			    DISPLAY rm_mod.g50_nombre TO nom_mod
                        END IF
                END IF
		LET int_flag = 0
END CONSTRUCT
IF int_flag THEN
	CLEAR FORM
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	END IF
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	RETURN
END IF
LET query = 'SELECT *, ROWID FROM gent015 WHERE g15_compania = ',
	     vg_codcia, ' AND ', expr_sql CLIPPED
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_csec.*, vm_r_rows[vm_num_rows]
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
DEFINE descri_cia	LIKE gent001.g01_razonsocial

LET vm_flag_mant = 'I'
CLEAR FORM
INITIALIZE rm_csec.* TO NULL
LET rm_csec.g15_fecing = fl_current()
LET rm_csec.g15_usuario = vg_usuario
LET rm_csec.g15_compania = vg_codcia
DISPLAY BY NAME rm_csec.g15_fecing, rm_csec.g15_usuario
CALL lee_datos()
IF NOT int_flag THEN
	INSERT INTO gent015 VALUES (rm_csec.*)
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
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_up CURSOR FOR SELECT * FROM gent015 WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_csec.*
IF status < 0 THEN
	COMMIT WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
CALL lee_datos()
IF NOT int_flag THEN
    	UPDATE gent015
	 SET 	g15_tipo = rm_csec.g15_tipo, 
		g15_nombre = rm_csec.g15_nombre,
	     	g15_numero = rm_csec.g15_numero
		WHERE CURRENT OF q_up
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
ELSE
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF

CLOSE q_up
END FUNCTION



FUNCTION lee_datos()
DEFINE  resp    	CHAR(6)

OPTIONS INPUT WRAP
LET int_flag = 0
INPUT BY NAME rm_csec.g15_localidad, rm_csec.g15_modulo, rm_csec.g15_bodega,
              rm_csec.g15_tipo, rm_csec.g15_nombre, rm_csec.g15_numero
              WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	 IF field_touched(rm_csec.g15_localidad, rm_csec.g15_modulo,
				  rm_csec.g15_bodega, rm_csec.g15_tipo,
				  rm_csec.g15_nombre, rm_csec.g15_numero)
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
		IF INFIELD(g15_localidad) THEN
		     CALL fl_ayuda_localidad(vg_codcia)
			     RETURNING rm_loc.g02_localidad, rm_loc.g02_nombre
			IF rm_loc.g02_localidad IS NOT NULL THEN
			    LET rm_csec.g15_localidad = rm_loc.g02_localidad
			    DISPLAY BY NAME rm_csec.g15_localidad
			    DISPLAY rm_loc.g02_nombre TO nom_loc
			END IF
		END IF
  		IF INFIELD(g15_modulo) THEN
                        CALL fl_ayuda_modulos()
				RETURNING rm_mod.g50_modulo, rm_mod.g50_nombre
                        IF rm_mod.g50_modulo IS NOT NULL THEN
                            LET rm_csec.g15_modulo = rm_mod.g50_modulo
                            DISPLAY BY NAME rm_csec.g15_modulo
			    DISPLAY rm_mod.g50_nombre TO nom_mod
                        END IF
                END IF
		LET int_flag = 0
	BEFORE FIELD g15_localidad
		IF vm_flag_mant = 'M' THEN
			NEXT FIELD NEXT
		END IF 
	BEFORE FIELD g15_modulo
		IF vm_flag_mant = 'M' THEN
			NEXT FIELD NEXT
		END IF
	BEFORE FIELD g15_bodega
		IF vm_flag_mant = 'M' THEN
			NEXT FIELD NEXT
		END IF
	AFTER FIELD g15_localidad
		IF rm_csec.g15_localidad IS NOT NULL THEN
		     CALL fl_lee_localidad(vg_codcia, rm_csec.g15_localidad)
		          RETURNING rm_loc.*
			IF rm_loc.g02_nombre IS NULL THEN
				CALL fgl_winmessage(vg_producto,'La localidad no existe','exclamation')
				CLEAR nom_loc
                                NEXT FIELD g15_localidad
			END IF
			DISPLAY rm_loc.g02_nombre TO nom_loc
		ELSE
			CLEAR nom_loc
		END IF
	AFTER FIELD g15_modulo
		IF rm_csec.g15_modulo IS NOT NULL THEN
		     CALL fl_lee_modulo(rm_csec.g15_modulo)
		          RETURNING rm_mod.*
			IF rm_mod.g50_nombre IS NULL THEN
				CALL fgl_winmessage(vg_producto,'El módulo no existe','exclamation')
                                NEXT FIELD g15_modulo
			END IF
			CLEAR nom_mod
			DISPLAY rm_mod.g50_nombre TO nom_mod
		ELSE
			CLEAR nom_mod
		END IF
	AFTER INPUT
		IF vm_flag_mant = 'I' THEN
			SELECT g15_localidad  FROM gent015
		         WHERE g15_compania  = vg_codcia	
		          AND  g15_localidad = rm_csec.g15_localidad	
		          AND  g15_modulo    = rm_csec.g15_modulo	
		          AND  g15_bodega    = rm_csec.g15_bodega	
		          AND  g15_tipo      = rm_csec.g15_tipo	
		        IF status <> NOTFOUND THEN
		   	    CALL fgl_winmessage(vg_producto,'Ya existe la secuencia ','exclamation')
		      	    NEXT FIELD g15_localidad
		        END IF
		END IF
END INPUT

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_csec.* FROM gent015 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
DISPLAY BY NAME rm_csec.g15_localidad, rm_csec.g15_modulo, rm_csec.g15_bodega,
                rm_csec.g15_tipo, rm_csec.g15_nombre, rm_csec.g15_numero,
                rm_csec.g15_usuario, rm_csec.g15_fecing
CALL fl_lee_localidad(vg_codcia, rm_csec.g15_localidad) RETURNING rm_loc.*
CALL fl_lee_modulo(rm_csec.g15_modulo) RETURNING rm_mod.*
DISPLAY rm_loc.g02_nombre TO nom_loc
DISPLAY rm_mod.g50_nombre TO nom_mod

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current              SMALLINT
DEFINE num_rows                 SMALLINT
                                                                                
DISPLAY "" AT 1,1
DISPLAY row_current, " de ", num_rows AT 1, 69
                                                                                
END FUNCTION



FUNCTION no_validar_parametros()
                                                                                
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

