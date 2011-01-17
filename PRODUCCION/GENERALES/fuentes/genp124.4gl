
-------------------------------------------------------------------------------
-- Titulo               : Genp124.4gl -- Mantenimiento de Departamentos
-- Elaboración          : 23-ago-2001
-- Autor                : GVA
-- Formato de Ejecución : fglrun Genp125.4gl base GE 1
-- Ultima Correción     : 27-ago-2001
-- Motivo Corrección    : 2
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_dep 	RECORD LIKE gent034.*
DEFINE rm_cost 	RECORD LIKE gent033.*
DEFINE vm_r_rows ARRAY[1000] OF INTEGER -- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS
DEFINE vm_demonios	VARCHAR(12)
DEFINE flag_man         CHAR(1)

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
LET vg_proceso	= 'genp124'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_rows = 1000
OPEN WINDOW w_dep AT 3,2 WITH 14 ROWS, 80 COLUMNS 
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPEN FORM f_dep FROM '../forms/genf124_1'
DISPLAY FORM f_dep
INITIALIZE rm_dep.* TO NULL
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
		   IF fl_control_permiso_opcion('Modificar') THEN			
			SHOW OPTION 'Modificar'
		   END IF 
			
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
		   IF fl_control_permiso_opcion('Modificar') THEN			
			SHOW OPTION 'Modificar'
		   END IF 
			
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
		   IF fl_control_permiso_opcion('Modificar') THEN			
			SHOW OPTION 'Modificar'
		   END IF 
		
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
DEFINE codigo		LIKE gent034.g34_cod_depto
DEFINE nom_dep		LIKE gent034.g34_nombre
DEFINE nombre		LIKE gent033.g33_nombre
DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)

CLEAR FORM
LET int_flag = 0
INITIALIZE codigo TO NULL
CONSTRUCT BY NAME expr_sql ON g34_cod_depto, g34_cod_ccosto, g34_nombre,
		              g34_usuario,g34_fecing
	ON KEY(F2)
		IF INFIELD(g34_cod_depto) THEN
			CALL fl_ayuda_departamentos(vg_codcia)
			     RETURNING codigo, nom_dep
			IF codigo IS NOT NULL THEN
			    LET rm_dep.g34_cod_depto = codigo
			    LET rm_dep.g34_nombre    = nom_dep
			    DISPLAY BY NAME rm_dep.g34_cod_depto,
			                    rm_dep.g34_nombre
			END IF
		END IF
  		IF INFIELD(g34_cod_ccosto) THEN
                        CALL fl_ayuda_ccostos(vg_codcia)
				RETURNING codigo, nombre
                        IF codigo IS NOT NULL THEN
                            LET rm_dep.g34_cod_ccosto = codigo
                            DISPLAY BY NAME rm_dep.g34_cod_ccosto
			    DISPLAY nombre TO nom_ccosto
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
LET query = 'SELECT *, ROWID FROM gent034 WHERE g34_compania = ',
	     vg_codcia, ' AND ', expr_sql CLIPPED, ' ORDER BY 4'
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_dep.*, vm_r_rows[vm_num_rows]
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

LET flag_man = 'I'
CLEAR FORM
INITIALIZE rm_dep.* TO NULL
LET rm_dep.g34_fecing = CURRENT
LET rm_dep.g34_usuario = vg_usuario
LET rm_dep.g34_compania = vg_codcia
DISPLAY BY NAME rm_dep.g34_fecing, rm_dep.g34_usuario
SELECT MAX(g34_cod_depto) + 1 INTO rm_dep.g34_cod_depto FROM gent034
        WHERE g34_compania = vg_codcia
        IF rm_dep.g34_cod_depto IS NULL THEN
                LET rm_dep.g34_cod_depto = 1
        END IF
CALL lee_datos()
IF NOT int_flag THEN
	WHENEVER ERROR CONTINUE
	BEGIN WORK
	INSERT INTO gent034 VALUES (rm_dep.*)
	WHENEVER ERROR STOP
	IF status < 0 THEN
	    SELECT MAX(g34_cod_depto) + 1 INTO rm_dep.g34_cod_depto FROM gent034
                   WHERE g34_compania = vg_codcia
            IF rm_dep.g34_cod_depto IS NULL THEN
                 LET rm_dep.g34_cod_depto = 1
            END IF
	    INSERT INTO gent034 VALUES (rm_dep.*)
	END IF 
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
DEFINE 	nombre		LIKE gent033.g33_nombre

LET flag_man = 'M'
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_up CURSOR FOR SELECT * FROM gent034 WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_dep.*
IF status < 0 THEN
	COMMIT WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
CALL fl_lee_centro_costo(vg_codcia, rm_dep.g34_cod_ccosto) RETURNING rm_cost.*
DISPLAY rm_cost.g33_nombre TO nom_ccosto
CALL lee_datos()
IF NOT int_flag THEN
    	UPDATE gent034
	 SET g34_nombre = rm_dep.g34_nombre,
	     g34_cod_ccosto = rm_dep.g34_cod_ccosto

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
DEFINE 	serial 	 	LIKE gent034.g34_cod_depto
DEFINE 	codigo 	 	LIKE gent033.g33_cod_ccosto
DEFINE 	nombre		LIKE gent033.g33_nombre

OPTIONS INPUT WRAP
LET int_flag = 0
INPUT BY NAME rm_dep.g34_nombre, rm_dep.g34_cod_ccosto WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	 IF field_touched(rm_dep.g34_cod_ccosto, rm_dep.g34_nombre)
                 THEN
                        LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
                        	RETURNING resp
                        IF resp = 'Yes' THEN
                           LET int_flag = 1
                           IF flag_man = 'I' THEN
				 CLEAR FORM
			   END IF
                           RETURN
                        END IF
                ELSE
                        IF flag_man = 'I' THEN
				CLEAR FORM
			END IF
		        RETURN
                END IF
        ON KEY(F2)
                IF INFIELD(g34_cod_ccosto) THEN
                        CALL fl_ayuda_ccostos(vg_codcia)
				RETURNING codigo, nombre
                        IF codigo IS NOT NULL THEN
                            LET rm_dep.g34_cod_ccosto = codigo
                            DISPLAY BY NAME rm_dep.g34_cod_ccosto
                            DISPLAY nombre TO nom_ccosto
                        END IF
                END IF
		LET int_flag = 0
	AFTER FIELD g34_cod_ccosto
		IF rm_dep.g34_cod_ccosto IS NOT NULL THEN
		     CALL fl_lee_centro_costo(vg_codcia, rm_dep.g34_cod_ccosto)
		          RETURNING rm_cost.*
			IF rm_cost.g33_nombre IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Centro de costo  no existe','exclamation')
                                NEXT FIELD g34_cod_ccosto
			END IF
			DISPLAY rm_cost.g33_nombre TO nom_ccosto
		ELSE
			CLEAR nom_ccosto
		END IF
	AFTER INPUT
		INITIALIZE serial TO NULL
		SELECT g34_cod_depto INTO serial FROM gent034
      		      WHERE g34_nombre = rm_dep.g34_nombre 
		      AND g34_compania = vg_codcia	
		IF status <> NOTFOUND THEN
		   IF flag_man = 'I' OR
		      (flag_man = 'M' AND rm_dep.g34_cod_depto <> serial)
		   THEN
		   	CALL fgl_winmessage(vg_producto,'Ya existe el departamento en el registro de código  '|| serial,'exclamation')
		      	NEXT FIELD g34_nombre
		   END IF
		END IF
END INPUT

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER
DEFINE 	descri_ccosto	LIKE gent033.g33_nombre

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_dep.* FROM gent034 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
CALL fl_lee_centro_costo(vg_codcia, rm_dep.g34_cod_ccosto) RETURNING rm_cost.*
DISPLAY BY NAME rm_dep.g34_cod_depto, rm_dep.g34_cod_ccosto, rm_dep.g34_nombre, 
		rm_dep.g34_usuario, rm_dep.g34_fecing 
DISPLAY rm_cost.g33_nombre TO nom_ccosto

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

