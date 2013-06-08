-------------------------------------------------------------------------------
-- Titulo               : Genp124.4gl -- Mantenimiento de Departamentos
-- Elaboración          : 23-ago-2001
-- Autor                : GVA
-- Formato de Ejecución : fglrun Genp125.4gl base GE 1
-- Ultima Correción     : 27-ago-2001
-- Motivo Corrección    : 2
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_g34 		RECORD LIKE gent034.*
DEFINE rm_g33 		RECORD LIKE gent033.*
DEFINE vm_r_rows 	ARRAY[1000] OF INTEGER -- ARREGLO DE ROWID DE FILAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS
DEFINE vm_demonios	VARCHAR(12)
DEFINE flag_man         CHAR(1)
DEFINE vm_nivel		LIKE ctbt001.b01_nivel



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
LET vg_base	= arg_val(1)
LET vg_modulo	= arg_val(2)
LET vg_codcia	= arg_val(3)
LET vg_proceso	= 'genp124'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_rows = 1000
OPEN WINDOW w_dep AT 3,2 WITH 16 ROWS, 80 COLUMNS 
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPEN FORM f_dep FROM '../forms/genf124_1'
DISPLAY FORM f_dep
INITIALIZE rm_g34.* TO NULL
SELECT MAX(b01_nivel) INTO vm_nivel FROM ctbt001
IF vm_nivel IS NULL THEN
	CALL fl_mostrar_mensaje('No existe ningun nivel de cuenta configurado en la compania.','stop')
	EXIT PROGRAM
END IF
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
DEFINE codigo		LIKE gent034.g34_cod_depto
DEFINE nom_dep		LIKE gent034.g34_nombre
DEFINE nombre		LIKE gent033.g33_nombre
DEFINE cod_aux		LIKE ctbt010.b10_cuenta
DEFINE nom_aux		LIKE ctbt010.b10_descripcion
DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)

CLEAR FORM
LET int_flag = 0
INITIALIZE codigo, cod_aux TO NULL
CONSTRUCT BY NAME expr_sql ON g34_cod_depto, g34_cod_ccosto, g34_nombre,
		              g34_aux_deprec, g34_usuario
	ON KEY(F2)
		IF INFIELD(g34_cod_depto) THEN
			CALL fl_ayuda_departamentos(vg_codcia)
			     RETURNING codigo, nom_dep
			IF codigo IS NOT NULL THEN
			    LET rm_g34.g34_cod_depto = codigo
			    LET rm_g34.g34_nombre    = nom_dep
			    DISPLAY BY NAME rm_g34.g34_cod_depto,
			                    rm_g34.g34_nombre
			END IF
		END IF
  		IF INFIELD(g34_cod_ccosto) THEN
                        CALL fl_ayuda_ccostos(vg_codcia)
				RETURNING codigo, nombre
                        IF codigo IS NOT NULL THEN
                            LET rm_g34.g34_cod_ccosto = codigo
                            DISPLAY BY NAME rm_g34.g34_cod_ccosto
			    DISPLAY nombre TO nom_ccosto
                        END IF
                END IF
		IF INFIELD(g34_aux_deprec) THEN
                        CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
                                RETURNING cod_aux, nom_aux
                        LET int_flag = 0
                        IF cod_aux IS NOT NULL THEN
                                DISPLAY cod_aux TO g34_aux_deprec
                                DISPLAY nom_aux TO tit_aux_deprec
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
FOREACH q_cons INTO rm_g34.*, vm_r_rows[vm_num_rows]
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
INITIALIZE rm_g34.* TO NULL
LET rm_g34.g34_fecing = CURRENT
LET rm_g34.g34_usuario = vg_usuario
LET rm_g34.g34_compania = vg_codcia
DISPLAY BY NAME rm_g34.g34_fecing, rm_g34.g34_usuario
SELECT MAX(g34_cod_depto) + 1 INTO rm_g34.g34_cod_depto FROM gent034
        WHERE g34_compania = vg_codcia
        IF rm_g34.g34_cod_depto IS NULL THEN
                LET rm_g34.g34_cod_depto = 1
        END IF
CALL lee_datos()
IF NOT int_flag THEN
	BEGIN WORK
	WHENEVER ERROR CONTINUE
	INSERT INTO gent034 VALUES (rm_g34.*)
	WHENEVER ERROR STOP
	IF status < 0 THEN
	    SELECT MAX(g34_cod_depto) + 1 INTO rm_g34.g34_cod_depto FROM gent034
                   WHERE g34_compania = vg_codcia
            IF rm_g34.g34_cod_depto IS NULL THEN
                 LET rm_g34.g34_cod_depto = 1
            END IF
	    INSERT INTO gent034 VALUES (rm_g34.*)
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
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR SELECT * FROM gent034 WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_g34.*
IF status < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
CALL fl_lee_centro_costo(vg_codcia, rm_g34.g34_cod_ccosto) RETURNING rm_g33.*
DISPLAY rm_g33.g33_nombre TO nom_ccosto
CALL lee_datos()
IF NOT int_flag THEN
    	UPDATE gent034
	 SET g34_nombre = rm_g34.g34_nombre,
	     g34_cod_ccosto = rm_g34.g34_cod_ccosto,
	     g34_aux_deprec = rm_g34.g34_aux_deprec
		WHERE CURRENT OF q_up
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
ELSE
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF
CLOSE q_up

END FUNCTION



FUNCTION lee_datos()
DEFINE serial 	 	LIKE gent034.g34_cod_depto
DEFINE codigo 	 	LIKE gent033.g33_cod_ccosto
DEFINE nombre		LIKE gent033.g33_nombre
DEFINE cod_aux		LIKE ctbt010.b10_cuenta
DEFINE nom_aux		LIKE ctbt010.b10_descripcion
DEFINE resp  	  	CHAR(6)
DEFINE resul		SMALLINT

OPTIONS INPUT WRAP
LET int_flag = 0
INPUT BY NAME rm_g34.g34_nombre, rm_g34.g34_cod_ccosto, rm_g34.g34_aux_deprec
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	 IF field_touched(rm_g34.g34_cod_ccosto, rm_g34.g34_nombre,
				  rm_g34.g34_aux_deprec)
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
                            LET rm_g34.g34_cod_ccosto = codigo
                            DISPLAY BY NAME rm_g34.g34_cod_ccosto
                            DISPLAY nombre TO nom_ccosto
                        END IF
                END IF
		IF INFIELD(g34_aux_deprec) THEN
                        CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
                                RETURNING cod_aux, nom_aux
                        LET int_flag = 0
                        IF cod_aux IS NOT NULL THEN
				LET rm_g34.g34_aux_deprec = cod_aux
                                DISPLAY cod_aux TO g34_aux_deprec
                                DISPLAY nom_aux TO tit_aux_deprec
                        END IF
                END IF
		LET int_flag = 0
	AFTER FIELD g34_cod_ccosto
		IF rm_g34.g34_cod_ccosto IS NOT NULL THEN
		     CALL fl_lee_centro_costo(vg_codcia, rm_g34.g34_cod_ccosto)
		          RETURNING rm_g33.*
			IF rm_g33.g33_nombre IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Centro de costo  no existe','exclamation')
                                NEXT FIELD g34_cod_ccosto
			END IF
			DISPLAY rm_g33.g33_nombre TO nom_ccosto
		ELSE
			CLEAR nom_ccosto
		END IF
	AFTER FIELD g34_aux_deprec
                IF rm_g34.g34_aux_deprec IS NOT NULL THEN
			CALL validar_cuenta(rm_g34.g34_aux_deprec, 1)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD g34_aux_deprec
			END IF
		ELSE
			CLEAR tit_aux_deprec
                END IF
	AFTER INPUT
		INITIALIZE serial TO NULL
		SELECT g34_cod_depto INTO serial FROM gent034
      		      WHERE g34_nombre = rm_g34.g34_nombre 
		      AND g34_compania = vg_codcia	
		IF status <> NOTFOUND THEN
		   IF flag_man = 'I' OR
		      (flag_man = 'M' AND rm_g34.g34_cod_depto <> serial)
		   THEN
		   	CALL fgl_winmessage(vg_producto,'Ya existe el departamento en el registro de código  '|| serial,'exclamation')
		      	NEXT FIELD g34_nombre
		   END IF
		END IF
END INPUT

END FUNCTION



FUNCTION validar_cuenta(aux_cont, flag)
DEFINE aux_cont		LIKE ctbt010.b10_cuenta
DEFINE flag		SMALLINT
DEFINE r_b10            RECORD LIKE ctbt010.*

CALL fl_lee_cuenta(vg_codcia, aux_cont) RETURNING r_b10.*
IF r_b10.b10_cuenta IS NULL  THEN
	CALL fgl_winmessage(vg_producto,'Cuenta no existe para esta compañía.','exclamation')
	RETURN 1
END IF
CASE flag
	WHEN 1
		DISPLAY r_b10.b10_descripcion TO tit_aux_deprec
END CASE
IF r_b10.b10_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN 1
END IF
IF r_b10.b10_nivel <> vm_nivel THEN
	CALL fgl_winmessage(vg_producto,'Nivel de cuenta debe ser solo del ultimo.','exclamation')
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER
DEFINE descri_ccosto	LIKE gent033.g33_nombre
DEFINE r_b10            RECORD LIKE ctbt010.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_g34.* FROM gent034 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
CALL fl_lee_centro_costo(vg_codcia, rm_g34.g34_cod_ccosto) RETURNING rm_g33.*
DISPLAY BY NAME rm_g34.g34_cod_depto, rm_g34.g34_cod_ccosto, rm_g34.g34_nombre, 
		rm_g34.g34_aux_deprec, rm_g34.g34_usuario, rm_g34.g34_fecing 
DISPLAY rm_g33.g33_nombre TO nom_ccosto
CALL fl_lee_cuenta(vg_codcia, rm_g34.g34_aux_deprec) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_aux_deprec

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current              SMALLINT
DEFINE num_rows                 SMALLINT
                                                                                
DISPLAY "" AT 1,1
DISPLAY row_current, " de ", num_rows AT 1, 69
                                                                                
END FUNCTION
