
-------------------------------------------------------------------------------
-- Titulo               : Genp117.4gl -- Mantenimiento de Grupos
--					 de Lineas de Ventas
-- Elaboración          : 27-ago-2001
-- Autor                : GVA
-- Formato de Ejecución : fglrun Genp117.4gl base GE 1
-- Ultima Correción     : 27-ago-2001
-- Motivo Corrección    : 1
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_lvent  	RECORD LIKE gent020.*
DEFINE rm_lvent2  	RECORD LIKE gent020.*
DEFINE rm_aneg 	        RECORD LIKE gent003.*
DEFINE vm_r_rows ARRAY[1000] OF INTEGER -- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS
DEFINE vm_demonios	VARCHAR(12)
DEFINE vm_flag_mant	CHAR(1)

MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN
     CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto','stop')
     EXIT PROGRAM
END IF
LET vg_base	= arg_val(1)
LET vg_modulo	= arg_val(2)
LET vg_codcia	= arg_val(3)
LET vg_proceso	= 'genp117'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_rows = 1000
OPEN WINDOW w_lvent AT 3,2 WITH 14 ROWS, 80 COLUMNS 
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPEN FORM f_lvent FROM '../forms/genf117_1'
DISPLAY FORM f_lvent
INITIALIZE rm_lvent.* TO NULL
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
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_consulta()
DEFINE codigo		LIKE gent020.g20_grupo_linea
DEFINE cod_areaneg 	LIKE gent003.g03_areaneg
DEFINE nom_lvent	LIKE gent020.g20_nombre
DEFINE nombre		LIKE gent003.g03_nombre
DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)

CLEAR FORM
LET int_flag = 0
INITIALIZE codigo TO NULL
CONSTRUCT BY NAME expr_sql ON g20_grupo_linea, g20_nombre, g20_areaneg,
		              g20_usuario, g20_fecing
	ON KEY(F2)
		IF INFIELD(g20_grupo_linea) THEN
		      CALL fl_ayuda_grupo_lineas(vg_codcia)
			   RETURNING codigo, nom_lvent
			IF codigo IS NOT NULL THEN
			    LET rm_lvent.g20_grupo_linea = codigo
			    LET rm_lvent.g20_nombre    = nom_lvent
			    DISPLAY BY NAME rm_lvent.g20_grupo_linea,
			                    rm_lvent.g20_nombre
			END IF
		END IF
  		IF INFIELD(g20_areaneg) THEN
                        CALL fl_ayuda_areaneg(vg_codcia)
			    RETURNING cod_areaneg, nombre
                        IF cod_areaneg IS NOT NULL THEN
                            LET rm_lvent.g20_areaneg = cod_areaneg
                            DISPLAY BY NAME rm_lvent.g20_areaneg
			    DISPLAY nombre TO nom_areaneg
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
LET query = 'SELECT *, ROWID FROM gent020 WHERE g20_compania = ',
		vg_codcia, ' AND ',  expr_sql CLIPPED, ' ORDER BY 3'
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_lvent.*, vm_r_rows[vm_num_rows]
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
INITIALIZE rm_lvent.* TO NULL
LET rm_lvent.g20_fecing = CURRENT
LET rm_lvent.g20_usuario = vg_usuario
LET rm_lvent.g20_compania = vg_codcia
DISPLAY BY NAME rm_lvent.g20_fecing, rm_lvent.g20_usuario
CALL lee_datos()
IF NOT int_flag THEN
	INSERT INTO gent020 VALUES (rm_lvent.*)
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
DEFINE 	nombre		LIKE gent003.g03_nombre

LET vm_flag_mant = 'M'
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_up CURSOR FOR SELECT * FROM gent020 WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_lvent.*
IF status < 0 THEN
	COMMIT WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
LET rm_lvent2.g20_nombre = rm_lvent.g20_nombre
CALL fl_lee_area_negocio(vg_codcia, rm_lvent.g20_areaneg) RETURNING rm_aneg.*
DISPLAY rm_aneg.g03_nombre TO nom_areaneg
CALL lee_datos()
IF NOT int_flag THEN
    	UPDATE gent020 
	      SET g20_nombre  = rm_lvent.g20_nombre, 
		  g20_areaneg = rm_lvent.g20_areaneg	
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
DEFINE 	codigo 	 	LIKE gent020.g20_grupo_linea
DEFINE 	cod_areaneg 	LIKE gent003.g03_areaneg
DEFINE 	nombre 		LIKE gent003.g03_nombre

OPTIONS INPUT WRAP
LET int_flag = 0
INPUT BY NAME rm_lvent.g20_grupo_linea,  rm_lvent.g20_nombre, 
	      rm_lvent.g20_areaneg WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	 IF field_touched(rm_lvent.g20_grupo_linea, 
				  rm_lvent.g20_nombre, rm_lvent.g20_areaneg)
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
				CLEAR FORM
		        RETURN
                END IF
        ON KEY(F2)
                IF INFIELD(g20_areaneg) THEN
                        CALL fl_ayuda_areaneg(vg_codcia)
			     RETURNING cod_areaneg, nombre
                        IF cod_areaneg IS NOT NULL THEN
                            LET rm_lvent.g20_areaneg = cod_areaneg
                            DISPLAY BY NAME rm_lvent.g20_areaneg
                            DISPLAY nombre TO nom_areaneg
                        END IF
                END IF
		LET int_flag = 0
	AFTER FIELD g20_areaneg
		IF rm_lvent.g20_areaneg IS NOT NULL THEN
		     CALL fl_lee_area_negocio(vg_codcia, rm_lvent.g20_areaneg)
		          RETURNING rm_aneg.*
			IF rm_aneg.g03_nombre IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Area de negocio no existe','exclamation')
                                NEXT FIELD g20_areaneg
			END IF
			DISPLAY rm_aneg.g03_nombre TO nom_areaneg
		ELSE
			CLEAR nom_areaneg
		END IF
	BEFORE FIELD g20_grupo_linea
		IF vm_flag_mant = 'M' THEN
			NEXT FIELD NEXT
		END IF
	AFTER INPUT
	    IF vm_flag_mant = 'I' THEN
		CALL fl_lee_grupo_linea(vg_codcia, rm_lvent.g20_grupo_linea)
			RETURNING rm_lvent2.*
		IF rm_lvent2.g20_grupo_linea IS NOT NULL THEN
		   	CALL fgl_winmessage(vg_producto,'Ya existe la linea de venta en la compañía ','exclamation')
		      	NEXT FIELD g20_grupo_linea
		END IF
	    END IF
	    IF vm_flag_mant = 'I' 
	    OR rm_lvent2.g20_nombre <> rm_lvent.g20_nombre
		THEN
		SELECT g20_grupo_linea INTO codigo FROM gent020
		WHERE g20_compania = vg_codcia
		AND   g20_nombre   = rm_lvent.g20_nombre
		IF status <> NOTFOUND THEN
			CALL fgl_winmessage(vg_producto, 'El nombre del Grupo de Línea ya ha sido asignada al registro de código  '||codigo,'exclamation')
			NEXT FIELD g20_nombre
		END IF
            END IF
END INPUT

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER
DEFINE 	descri_areaneg	LIKE gent003.g03_nombre

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_lvent.* FROM gent020 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
CALL fl_lee_area_negocio(vg_codcia, rm_lvent.g20_areaneg) 
	RETURNING rm_aneg.*
DISPLAY BY NAME rm_lvent.g20_grupo_linea, rm_lvent.g20_areaneg,
		rm_lvent.g20_nombre, rm_lvent.g20_usuario, rm_lvent.g20_fecing 
DISPLAY rm_aneg.g03_nombre TO nom_areaneg

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

