-------------------------------------------------------------------------------
-- Titulo               : genp118.4gl -- Mantenimiento de Transacciones de
--		                                 Modulos de Facturación
-- Elaboración          : 29-ago-2001
-- Autor                : GVA
-- Formato de Ejecución : fglrun  genp118.4gl base GE 
-- Ultima Correción     : 3-sep-2001
-- Motivo Corrección    : 2
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_tran   RECORD LIKE gent021.*
DEFINE rm_tran2  RECORD LIKE gent021.*
DEFINE vm_r_rows ARRAY[1000] OF INTEGER -- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current   SMALLINT        -- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows      SMALLINT        -- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS
DEFINE vm_flag_mant     CHAR(1)
DEFINE vm_tipo          LIKE gent021.g21_tipo

MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/genp118.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 2 THEN
     CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto','stop')
     EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_proceso = 'genp118'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()
                                                                                
END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_rows = 1000
OPEN WINDOW w_tran AT 3,2 WITH 16 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPEN FORM f_tran FROM '../forms/genf118_1'
DISPLAY FORM f_tran
INITIALIZE rm_tran.* TO NULL
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
	COMMAND KEY('E') 'Bloquear/Activar' 'Bloquear o activar registro. '
		CALL control_bloqueo_activacion()
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_consulta()
DEFINE codigo		LIKE gent021.g21_cod_tran
DEFINE nombre		LIKE gent021.g21_nombre
DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)

CLEAR FORM
LET int_flag = 0
INITIALIZE codigo TO NULL
CONSTRUCT BY NAME expr_sql ON 	g21_cod_tran, g21_nombre, g21_estado, g21_tipo,
			      	g21_calc_costo,g21_act_estad, g21_codigo_dev, 
				g21_usuario, g21_fecing
	ON KEY(F2)
		IF INFIELD(g21_cod_tran) THEN
		     CALL fl_ayuda_tipo_tran('N')
		     RETURNING rm_tran.g21_cod_tran, rm_tran.g21_nombre
		     IF rm_tran.g21_cod_tran IS NOT NULL THEN
			DISPLAY BY NAME rm_tran.g21_cod_tran, rm_tran.g21_nombre
		     END IF
		END IF
                IF INFIELD(g21_codigo_dev) THEN
                     CALL fl_ayuda_tipo_tran('N')
                     RETURNING codigo, nombre
                     IF rm_tran.g21_cod_tran IS NOT NULL THEN
			LET rm_tran.g21_codigo_dev = codigo
                        DISPLAY BY NAME rm_tran.g21_codigo_dev
			DISPLAY  nombre TO nom_dev
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
LET query = 'SELECT *, ROWID FROM gent021 WHERE ', expr_sql CLIPPED,
		' ORDER BY 1, 2'
PREPARE cons FROM query
DECLARE q_tran CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_tran INTO rm_tran.*, vm_r_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > 1000 THEN
                EXIT FOREACH
        END IF
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

OPTIONS INPUT WRAP
CLEAR FORM
INITIALIZE rm_tran.* TO NULL
LET vm_flag_mant           = 'I'
LET rm_tran.g21_fecing     = CURRENT
LET rm_tran.g21_usuario    = vg_usuario
LET rm_tran.g21_estado     = 'A'
LET rm_tran.g21_tipo       = 'E'
LET rm_tran.g21_calc_costo = 'N'
LET rm_tran.g21_act_estad  = 'N'
DISPLAY BY NAME rm_tran.g21_fecing, rm_tran.g21_usuario, rm_tran.g21_estado
DISPLAY 'ACTIVO' TO tit_estado
CALL lee_datos()
IF NOT int_flag THEN
	INSERT INTO gent021 VALUES (rm_tran.*)
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

LET vm_flag_mant      = 'M'
LET vm_tipo           = rm_tran.g21_tipo
IF rm_tran.g21_estado <> 'A' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR SELECT * FROM gent021 WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_tran.*
IF status < 0 THEN
	WHENEVER ERROR STOP
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	RETURN
END IF
WHENEVER ERROR STOP
CALL lee_datos()
IF NOT int_flag THEN
    	UPDATE gent021 SET * = rm_tran.*
		WHERE CURRENT OF q_up
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
ELSE
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF
CLOSE q_up

END FUNCTION



FUNCTION control_bloqueo_activacion()
DEFINE resp    	CHAR(6)
DEFINE i	SMALLINT
DEFINE estado	LIKE gent021.g21_estado

LET int_flag = 0
IF rm_tran.g21_cod_tran IS NULL OR vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL fl_mensaje_seguro_ejecutar_proceso()
	RETURNING resp
IF resp = 'Yes' THEN
	BEGIN WORK
	WHENEVER ERROR CONTINUE
	DECLARE q_del CURSOR FOR SELECT * FROM gent021 
		WHERE ROWID = vm_r_rows[vm_row_current]
		FOR UPDATE
	OPEN q_del
	FETCH q_del INTO rm_tran.*
	IF status < 0 THEN
		WHENEVER ERROR STOP
		ROLLBACK WORK
		CALL fl_mensaje_bloqueo_otro_usuario()
		RETURN
	END IF
	WHENEVER ERROR STOP
	LET estado = 'B'
	IF rm_tran.g21_estado <> 'A' THEN
		LET estado = 'A'
	END IF
	UPDATE gent021 SET g21_estado = estado WHERE CURRENT OF q_del
	COMMIT WORK
	LET int_flag = 1
	CALL fl_mensaje_registro_modificado()
	CLEAR FORM	
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION lee_datos()
DEFINE           resp      CHAR(6)
DEFINE           codigo    LIKE gent021.g21_cod_tran
DEFINE           nombre    LIKE gent021.g21_nombre
                                                                                
OPTIONS INPUT WRAP
LET int_flag = 0 
INPUT BY NAME 	rm_tran.g21_cod_tran, rm_tran.g21_nombre, rm_tran.g21_estado,
 	      	rm_tran.g21_tipo, rm_tran.g21_calc_costo, rm_tran.g21_act_estad,
		rm_tran.g21_codigo_dev
              WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
        	 IF field_touched(rm_tran.g21_nombre, rm_tran.g21_calc_costo,
				  rm_tran.g21_codigo_dev)
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
                IF INFIELD(g21_codigo_dev) THEN
			LET vm_tipo = rm_tran.g21_tipo
		   IF vm_tipo <> 'C' THEN
                      CALL fl_ayuda_tipo_tran(vm_tipo)
                      RETURNING codigo, nombre
                      IF rm_tran.g21_cod_tran IS NOT NULL THEN
			   LET rm_tran.g21_codigo_dev = codigo 
                           DISPLAY BY NAME rm_tran.g21_codigo_dev
                           DISPLAY nombre TO  nom_dev
                      END IF
                   END IF
                END IF
                LET int_flag = 0
	BEFORE  FIELD g21_cod_tran
		IF vm_flag_mant = 'M' THEN
			NEXT FIELD NEXT
		END IF
	AFTER FIELD g21_tipo
		CASE rm_tran.g21_tipo
			WHEN 'E'
				LET rm_tran.g21_calc_costo = 'N'
				DISPLAY BY NAME rm_tran.g21_calc_costo 
			WHEN 'C'
				LET rm_tran.g21_calc_costo = 'S'
				DISPLAY BY NAME rm_tran.g21_calc_costo 
		END CASE
	AFTER FIELD g21_calc_costo
		CASE rm_tran.g21_tipo
			WHEN 'E'
				LET rm_tran.g21_calc_costo = 'N'
				DISPLAY BY NAME rm_tran.g21_calc_costo 
			WHEN 'C'
				LET rm_tran.g21_calc_costo = 'S'
				DISPLAY BY NAME rm_tran.g21_calc_costo 
		END CASE	
  AFTER FIELD g21_codigo_dev
                IF rm_tran.g21_codigo_dev IS NOT NULL THEN
			IF rm_tran.g21_tipo <> 'C' THEN
				SELECT g21_cod_tran FROM gent021
				WHERE  g21_cod_tran = rm_tran.g21_codigo_dev
				AND    g21_tipo    <> rm_tran.g21_tipo
				IF status = NOTFOUND THEN
					CALL fgl_winmessage(vg_producto,'No existe código de devolución', 'exclamation') 
				END IF 
			ELSE
				CLEAR g21_codigo_dev, nom_dev
				LET rm_tran.g21_codigo_dev = ''
			END IF 
		END IF 
	AFTER INPUT
               IF vm_flag_mant = 'I' THEN
                        CALL fl_lee_cod_transaccion(rm_tran.g21_cod_tran)
                                RETURNING rm_tran2.*
                        IF rm_tran2.g21_cod_tran IS NOT NULL THEN
                                CALL fgl_winmessage (vg_producto, 'La transacció
n ya existe en la base de datos','exclamation')
                                NEXT FIELD g21_cod_tran
                        END IF
               END IF
                IF rm_tran.g21_codigo_dev IS NOT NULL THEN
			IF rm_tran.g21_tipo = 'C' THEN
				CLEAR g21_codigo_dev, nom_dev
				LET rm_tran.g21_codigo_dev = ''
			END IF 
		END IF 
		IF rm_tran.g21_codigo_dev IS NOT NULL 
		OR rm_tran.g21_codigo_dev <> ''
		 THEN	
		   IF rm_tran.g21_codigo_dev = rm_tran.g21_cod_tran THEN
			CALL fgl_winmessage(vg_producto, 'El código de la devolución no puede ser el mismo que el código de la transacción', 'exclamation')
			NEXT FIELD g21_codigo_dev
		   END IF
		   IF rm_tran.g21_tipo <> vm_tipo THEN
		         IF rm_tran.g21_tipo <> 'C' THEN
		         	CALL fgl_winmessage(vg_producto, 'El código de devolución no es válido porque cambio el tipo de la transacción', 'exclamation')
		        	NEXT FIELD g21_tipo
		          END IF
		   END IF
		END IF
		IF rm_tran.g21_act_estad = 'S' AND rm_tran.g21_tipo <> 'I' AND 
				rm_tran.g21_tipo <> 'E'	THEN
			CALL fgl_winmessage(vg_producto, 'Tipo de Transacción no válido para actualizar estadísticas', 'exclamation')
			NEXT FIELD g21_tipo
		END IF
END INPUT
                                                                                
END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_tran.* FROM gent021 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
DISPLAY BY NAME rm_tran.*
IF rm_tran.g21_estado = 'A' THEN
        DISPLAY 'ACTIVO' TO tit_estado
ELSE
        DISPLAY 'BLOQUEADO' TO tit_estado
END IF
CALL fl_lee_cod_transaccion(rm_tran.g21_codigo_dev)
RETURNING rm_tran2.*
DISPLAY rm_tran2.g21_nombre TO nom_dev

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

