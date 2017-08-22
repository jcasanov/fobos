
-------------------------------------------------------------------------------
-- Titulo               : genp119.4gl -- Mantenimiento de Subtipos de
--					 Transacciones
-- Elaboración          : 30-ago-2001
-- Autor                : GVA
-- Formato de Ejecución : fglrun genp119 base GE 
-- Ultima Correción     : 3-sep-2001
-- Motivo Corrección    : 2
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_stran  RECORD LIKE gent022.*
DEFINE rm_tran   RECORD LIKE gent021.*
DEFINE vm_r_rows ARRAY[1000] OF INTEGER -- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current   SMALLINT        -- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows      SMALLINT        -- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS
DEFINE vm_demonios      VARCHAR(12)

MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 2 THEN
     CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto','stop')
     EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_proceso = 'genp119'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()
                                                                                
END MAIN



FUNCTION funcion_master()   
                                                                             
CALL fl_nivel_isolation()
LET vm_max_rows = 1000
OPEN WINDOW w_stran AT 3,2 WITH 14 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPEN FORM f_stran FROM '../forms/genf119_1'
DISPLAY FORM f_stran
INITIALIZE rm_stran.* TO NULL
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
	COMMAND KEY('S') 'Salir' 'Salir del programa.  '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)

CLEAR FORM
INITIALIZE rm_stran.*, rm_tran.* TO NULL
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON g22_cod_subtipo, g22_cod_tran, g22_nombre,
			      g22_estado, g22_usuario, g22_fecing
 	ON KEY(F2)
                IF INFIELD(g22_cod_subtipo) THEN
                       CALL fl_ayuda_subtipo_tran(NULL)
		       RETURNING rm_stran.g22_cod_tran,
				 rm_stran.g22_cod_subtipo, rm_stran.g22_nombre
                        IF rm_stran.g22_cod_subtipo IS NOT NULL THEN
                              DISPLAY BY NAME rm_stran.g22_cod_tran,
				    rm_stran.g22_cod_subtipo,rm_stran.g22_nombre
                        END IF
                END IF
		IF INFIELD(g22_cod_tran) THEN
			CALL fl_ayuda_tipo_tran('N')
			RETURNING rm_stran.g22_cod_tran, rm_tran.g21_nombre
			IF rm_stran.g22_cod_tran IS NOT NULL THEN
			    DISPLAY BY NAME rm_stran.g22_cod_tran
			    DISPLAY rm_tran.g21_nombre TO nom_tran
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
LET query = 'SELECT *, ROWID FROM gent022 WHERE ', expr_sql CLIPPED, 
		' ORDER BY 2, 3'
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_stran.*, vm_r_rows[vm_num_rows]
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

OPTIONS INPUT WRAP
CLEAR FORM
INITIALIZE rm_stran.* TO NULL
LET rm_stran.g22_fecing      = fl_current()
LET rm_stran.g22_usuario     = vg_usuario
LET rm_stran.g22_cod_subtipo = 0 
LET rm_stran.g22_estado      = 'A'
DISPLAY BY NAME rm_stran.g22_fecing, rm_stran.g22_usuario, rm_stran.g22_estado
DISPLAY 'ACTIVO' TO tit_estado
CALL lee_datos('I')
IF NOT int_flag THEN
	INSERT INTO gent022 VALUES  (rm_stran.*)
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
DEFINE    flag		   CHAR(1)

IF rm_stran.g22_estado <> 'A' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_up CURSOR FOR SELECT * FROM gent022 WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE 
OPEN q_up
FETCH q_up INTO rm_stran.*
IF status < 0 THEN
	COMMIT WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
CALL fl_lee_cod_transaccion(rm_stran.g22_cod_tran)RETURNING rm_tran.*
DISPLAY rm_tran.g21_nombre TO nom_tran
CALL lee_datos('M')
IF NOT int_flag THEN
    	UPDATE gent022 SET (g22_cod_tran, g22_nombre) = 
			   (rm_stran.g22_cod_tran, rm_stran.g22_nombre)
		WHERE CURRENT OF q_up
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
ELSE
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF
CLOSE q_up

END FUNCTION


FUNCTION control_bloqueo_activacion()
DEFINE resp    	CHAR(6)
DEFINE i	SMALLINT
DEFINE mensaje	VARCHAR(20)
DEFINE estado	LIKE gent022.g22_estado

LET int_flag = 0
IF rm_stran.g22_cod_subtipo IS NULL OR vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
LET mensaje = 'Seguro de bloquear'
IF rm_stran.g22_estado <> 'A' THEN
	LET mensaje = 'Seguro de activar'
END IF
CALL fl_mensaje_seguro_ejecutar_proceso()
	RETURNING resp
IF resp = 'Yes' THEN
WHENEVER ERROR CONTINUE
	BEGIN WORK
	DECLARE q_del CURSOR FOR SELECT * FROM gent022 
		WHERE ROWID = vm_r_rows[vm_row_current]
		FOR UPDATE
	OPEN q_del
	FETCH q_del INTO rm_stran.*
	IF status < 0 THEN
		COMMIT WORK
		CALL fl_mensaje_bloqueo_otro_usuario()
		WHENEVER ERROR STOP
		RETURN
	END IF
	LET estado = 'B'
	IF rm_stran.g22_estado <> 'A' THEN
		LET estado = 'A'
	END IF
	UPDATE gent022 SET g22_estado = estado WHERE CURRENT OF q_del
	COMMIT WORK
	LET int_flag = 1
	CALL fl_mensaje_registro_modificado()
	CLEAR FORM	
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION lee_datos(flag)
DEFINE  resp    	CHAR(6)
DEFINE 	flag 	 	CHAR(1)
DEFINE 	serial	 	LIKE gent022.g22_cod_subtipo
DEFINE 	nombre	        LIKE gent022.g22_nombre

OPTIONS INPUT WRAP
LET int_flag = 0
INPUT BY NAME rm_stran.g22_nombre, rm_stran.g22_cod_tran
	      WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	 IF field_touched(rm_stran.g22_cod_tran, rm_stran.g22_nombre)
                 THEN
                        LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
                        	RETURNING resp
                        IF resp = 'Yes' THEN
                                LET int_flag = 1
 				IF flag = 'I' THEN
                                         CLEAR FORM
                                END IF
				RETURN
                        END IF
                ELSE
				IF flag = 'I' THEN
                                         CLEAR FORM
                                END IF
				RETURN
                END IF
	ON KEY(F2)
                IF INFIELD(g22_cod_tran) THEN
                     CALL fl_ayuda_tipo_tran('N')
		     RETURNING rm_stran.g22_cod_tran, rm_tran.g21_nombre
                     IF rm_stran.g22_cod_tran IS NOT NULL THEN
                            DISPLAY BY NAME rm_stran.g22_cod_tran
			    DISPLAY rm_tran.g21_nombre TO nom_tran
                     END IF
                END IF
		LET int_flag = 0
	AFTER FIELD g22_cod_tran
         	IF rm_stran.g22_cod_tran IS NOT NULL THEN
		     CALL fl_lee_cod_transaccion(rm_stran.g22_cod_tran)
			RETURNING rm_tran.*
                     IF rm_tran.g21_cod_tran IS NULL THEN
                        CALL fgl_winmessage(vg_producto,'Transacción no existe',                                            'exclamation')
			   CLEAR nom_tran
                    	   NEXT FIELD g22_cod_tran
		     ELSE 
			IF rm_tran.g21_estado = 'B' THEN
                        	CALL fgl_winmessage(vg_producto,'Transacción esta bloqueda', 'exclamation')
			   CLEAR nom_tran
		           NEXT FIELD g22_cod_tran
                        END IF
                     END IF
    			DISPLAY BY NAME rm_stran.g22_cod_tran
                        DISPLAY rm_tran.g21_nombre TO nom_tran
		ELSE
			CLEAR nom_tran
	  	END IF
	AFTER INPUT
     		INITIALIZE serial  TO NULL
                SELECT g22_cod_subtipo, g22_nombre
                      INTO   serial, nombre
	              FROM   gent022
                      WHERE  g22_cod_subtipo = rm_stran.g22_cod_subtipo
                      AND    g22_cod_tran    = rm_stran.g22_cod_tran
                IF status <> NOTFOUND THEN
                      IF rm_stran.g22_cod_subtipo <> serial THEN
                           IF nombre = rm_stran.g22_nombre THEN
                              CALL fgl_winmessage(vg_producto,'Ya existe el subtipo de transacción en el registro de código  '|| serial, 'exclamation')
                              NEXT FIELD g22_nombre
                           END IF
                      END IF
                END IF
END INPUT

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_stran.* FROM gent022 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
DISPLAY BY NAME rm_stran.*
CALL fl_lee_cod_transaccion(rm_stran.g22_cod_tran)RETURNING  rm_tran.*
DISPLAY rm_tran.g21_nombre TO nom_tran
IF rm_stran.g22_estado = 'A' THEN
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
     CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || vg_codcia,
                         'stop')
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
      CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| vg_codloc,
                          'stop')
      EXIT PROGRAM
END IF
                                                                                
END FUNCTION

