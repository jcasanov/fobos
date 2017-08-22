-------------------------------------------------------------------------------
-- Titulo               : Genp114.4gl -- Mantenimiento de Partidas Arancelarias
-- Elaboración          : 23-ago-2001
-- Autor                : GVA
-- Formato de Ejecución : fglrun genp114 base GE [partida]
-- Ultima Correción     : 10-Mar-2003
-- Motivo Corrección    : Arreglar el campo nombre y aumentar el subtitulo
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_par		RECORD LIKE gent038.*
DEFINE rm_pra		RECORD LIKE gent016.*
DEFINE rm_pra2		RECORD LIKE gent016.*
DEFINE vm_r_rows	ARRAY[1000] OF INTEGER -- ARREGLO DE ROWID DE FILAS
DEFINE vm_row_current   INTEGER        -- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows      INTEGER        -- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      INTEGER        -- MAXIMO DE FILAS LEIDAS
DEFINE vm_demonios      VARCHAR(12)
DEFINE vm_flag_mant     CHAR(1)



MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 2 AND num_args() <> 3 THEN
     CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto','stop')
     EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_proceso = 'genp114'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()
                                                                                
END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_rows = 1000
OPEN WINDOW w_pra AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 1)
OPEN FORM f_pra FROM '../forms/genf114_1'
DISPLAY FORM f_pra
INITIALIZE rm_pra.* TO NULL
INITIALIZE rm_par.* TO NULL
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		IF num_args() <> 2 THEN
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Consultar'
			CALL control_consulta()
			IF vm_num_rows > 1 THEN
				SHOW OPTION 'Avanzar'
			END IF
			IF vm_row_current <= 1 THEN
                        	HIDE OPTION 'Retroceder'
	                END IF
		END IF
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
DEFINE r_g16		RECORD LIKE gent016.*
DEFINE par		RECORD LIKE gent016.*
DEFINE r_g38		RECORD LIKE gent038.*
DEFINE expr_sql		CHAR(1000)
DEFINE query		CHAR(800)
DEFINE partida		LIKE gent016.g16_partida
DEFINE desc_par		LIKE gent016.g16_desc_par
DEFINE capitulo		LIKE gent038.g38_capitulo
DEFINE desc_cap		LIKE gent038.g38_desc_cap
DEFINE partidas		VARCHAR(200)
DEFINE i, j, k, l, ini	INTEGER

CLEAR FORM
INITIALIZE partida, capitulo TO NULL
IF num_args() <> 2 THEN
	SELECT MIN(g16_niv_par) INTO ini FROM gent016
		WHERE g16_niv_par        <> 0
		  AND LENGTH(g16_niv_par) = 1
	LET partida  = arg_val(3)
	LET l        = LENGTH(partida)
	LET j        = l
	LET partidas = '('
	WHILE (j >= ini)
		LET k = l
		LET partidas = partidas, '"', partida[1, l], '"'
		IF (j MOD 2) = 0 THEN
			FOR i = l TO 1 STEP -1
				LET l = l - 1
				IF partida[i, i] = '.' THEN
					LET partidas = partidas, ', '
					LET k = k - l + 1
					EXIT FOR
				END IF
			END FOR
		ELSE
			LET partidas = partidas, ', '
			LET l = l - 1
			LET k = k - l
		END IF
		LET j = j - k
	END WHILE
	LET partidas = partidas, '"', partida[1, ini], '"'
	LET partidas = partidas, ')'
	LET expr_sql = ' g16_partida IN ', partidas
ELSE
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON g16_capitulo, g38_desc_cap,
			   g16_partida,     g16_desc_par,
	 		   g16_porcentaje,  g16_salvagu,
			   g16_niv_par,	    g16_nacional,
			   g16_verifcador,  g16_usuario
		ON KEY(F2)
			IF INFIELD(g16_capitulo) THEN
				CALL fl_ayuda_capitulo()
					RETURNING capitulo, desc_cap
				IF capitulo IS NOT NULL THEN
					LET rm_pra.g16_capitulo = capitulo
					LET rm_par.g38_desc_cap = desc_cap
					DISPLAY BY NAME rm_pra.g16_capitulo,
						rm_par.g38_desc_cap
				END IF
			END IF
			IF INFIELD(g16_partida) THEN
			 	CALL fl_ayuda_partidas(rm_pra.g16_capitulo)	
							 RETURNING partida
				IF partida IS NOT NULL THEN
					CALL fl_lee_partida(partida)
						RETURNING r_g16.*
					LET rm_pra.g16_partida =
							r_g16.g16_partida
					LET rm_pra.g16_desc_par=
							r_g16.g16_desc_par
					DISPLAY BY NAME rm_pra.g16_partida,
							rm_pra.g16_desc_par
				END IF
			END IF
			LET int_flag = 0
		AFTER FIELD g16_capitulo
			LET rm_pra.g16_capitulo = get_fldbuf(g16_capitulo)	
                        IF  rm_pra.g16_capitulo IS NOT NULL THEN
				CALL fl_lee_capitulo(rm_pra.g16_capitulo) 
					      RETURNING r_g38.*
				IF r_g38.g38_capitulo IS NULL THEN
					CALL fl_mostrar_mensaje('Capítulo de Partida Arancelaria no existe.','exclamation')
					NEXT FIELD g16_capitulo
				END IF
                                LET rm_pra.g16_capitulo = r_g38.g38_capitulo
                                LET rm_par.g38_desc_cap = r_g38.g38_desc_cap
                                DISPLAY BY NAME rm_pra.g16_capitulo,
                                                rm_par.g38_desc_cap
--			ELSE
--			CLEAR g38_desc_cap
                        END IF
			LET int_flag = 0
		AFTER FIELD g16_partida
			LET rm_pra.g16_partida = get_fldbuf(g16_partida)	
                        IF  rm_pra.g16_partida IS NOT NULL THEN
                        CALL fl_lee_partida(rm_pra.g16_partida)
                                               RETURNING par.*
				IF par.g16_partida IS NULL THEN
				     CALL fl_mostrar_mensaje('Partida Arancelaria no existe.','exclamation')
				     NEXT FIELD g16_partida
				ELSE
                               	     CALL fl_lee_partida(par.g16_partida) 
							RETURNING r_g16.*
                                     LET rm_pra.g16_partida = r_g16.g16_partida
                                     LET rm_pra.g16_desc_par= r_g16.g16_desc_par
                                     DISPLAY BY NAME rm_pra.g16_partida,
                                                     rm_pra.g16_desc_par
				END IF
			ELSE
				CLEAR g16_desc_par
                        END IF
			LET int_flag = 0
	END CONSTRUCT
	IF int_flag THEN
		CLEAR FORM
		IF vm_num_rows > 0 THEN
			CALL lee_muestra_registro(vm_r_rows[vm_row_current])
		END IF
--		CALL muestra_contadores(vm_row_current, vm_num_rows)
		RETURN
	END IF
END IF
LET query = 'SELECT gent016.*, gent016.ROWID, g38_desc_cap ',
	    ' FROM  gent016, gent038 ',
 	    ' WHERE ', expr_sql CLIPPED,
       	    '  AND g16_capitulo = g38_capitulo',
       	    ' ORDER BY g16_partida, g16_niv_par' CLIPPED
PREPARE cons FROM query
DECLARE q_pra CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_pra INTO rm_pra.*, vm_r_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	IF num_args() <> 2 THEN
		EXIT PROGRAM
	END IF
	LET vm_row_current = 0
	CALL muestra_contadores(vm_row_current, vm_num_rows)
        CLEAR FORM
        RETURN
END IF
LET vm_row_current = 1
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL lee_muestra_registro(vm_r_rows[vm_row_current])

END FUNCTION



FUNCTION control_ingreso()
DEFINE num_aux          INTEGER

OPTIONS INPUT WRAP
CLEAR FORM
INITIALIZE rm_pra.* TO NULL
INITIALIZE rm_par.* TO NULL
LET rm_pra.g16_porcentaje = 0
LET rm_pra.g16_salvagu    = 0
LET rm_pra.g16_fecing     = fl_current()
LET rm_pra.g16_usuario    = vg_usuario
LET rm_par.g38_usuario    = vg_usuario

DISPLAY BY NAME rm_pra.g16_fecing, rm_pra.g16_usuario
LET vm_flag_mant          = 'I'
CALL lee_datos()
IF NOT int_flag THEN
	BEGIN WORK
		INSERT INTO gent016 VALUES (rm_pra.*)
		LET num_aux = SQLCA.SQLERRD[6]
	COMMIT WORK
	IF vm_num_rows = vm_max_rows THEN
                LET vm_num_rows = 1
        ELSE
                LET vm_num_rows = vm_num_rows + 1
        END IF
	LET vm_row_current 		= vm_num_rows
        LET vm_r_rows[vm_row_current]   = num_aux
--	LET vm_r_rows[vm_num_rows] = SQLCA.SQLERRD[6] 
	CALL fl_mensaje_registro_ingresado()
END IF
IF vm_num_rows > 0 THEN
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION control_modificacion()
DEFINE     	flag   CHAR(1)

IF vm_num_rows = 0 THEN
        CALL fl_mensaje_consultar_primero()
        RETURN
END IF
CALL lee_muestra_registro(vm_r_rows[vm_row_current])

LET vm_flag_mant       = 'M'
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR
	SELECT * FROM gent016
	 WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_pra.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
DECLARE q_up2 CURSOR FOR
	SELECT * FROM gent038
         	WHERE g38_capitulo = rm_pra.g16_capitulo
		  AND g38_desc_cap = rm_par.g38_desc_cap
        	FOR UPDATE
	OPEN q_up2
FETCH q_up2 INTO rm_par.*
IF STATUS = NOTFOUND THEN
	CALL fgl_winmessage (vg_producto,'No existe registro con índice:
 ' || vm_row_current,'exclamation')
END IF
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
CALL lee_datos()
IF NOT int_flag THEN
    	UPDATE gent016 SET   g16_capitulo   = rm_pra.g16_capitulo,
				g16_partida    = rm_pra.g16_partida,
				g16_desc_par   = rm_pra.g16_desc_par,
    			   	g16_porcentaje = rm_pra.g16_porcentaje,
    			   	g16_salvagu    = rm_pra.g16_salvagu,
				g16_niv_par    = rm_pra.g16_niv_par,
				g16_nacional   = rm_pra.g16_nacional,
				g16_verifcador = rm_pra.g16_verifcador
		WHERE CURRENT OF q_up
	IF rm_pra.g16_capitulo IS NOT NULL THEN
	UPDATE gent038 SET      g38_capitulo   = rm_par.g38_capitulo,
				g38_desc_cap   = rm_par.g38_desc_cap
		WHERE CURRENT OF q_up2
	ELSE
		INSERT INTO gent016 VALUES (rm_pra.*)
	END IF
	COMMIT WORK
--	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL fl_mensaje_registro_modificado()
ELSE
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION lee_datos()
DEFINE   	 resp    CHAR(6)
DEFINE   	 codigo  LIKE gent016.g16_partida
----
DEFINE r_g16            RECORD LIKE gent016.*
DEFINE par              RECORD LIKE gent016.*
DEFINE r_g38            RECORD LIKE gent038.*
DEFINE partida          LIKE gent016.g16_partida
DEFINE desc_par         LIKE gent016.g16_desc_par
DEFINE capitulo         LIKE gent038.g38_capitulo
DEFINE desc_cap         LIKE gent038.g38_desc_cap
----

OPTIONS INPUT WRAP
DISPLAY BY NAME rm_pra.*, rm_par.g38_desc_cap
LET int_flag = 0
INPUT BY NAME   rm_pra.g16_capitulo,    rm_par.g38_desc_cap,
		rm_pra.g16_partida,  	rm_pra.g16_desc_par,
		rm_pra.g16_porcentaje, 	rm_pra.g16_salvagu,
		rm_pra.g16_niv_par,	rm_pra.g16_nacional,
		rm_pra.g16_verifcador 
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	 IF field_touched(rm_pra.g16_capitulo,   rm_par.g38_desc_cap,
				  rm_pra.g16_partida,    rm_pra.g16_desc_par,
				  rm_pra.g16_porcentaje, rm_pra.g16_salvagu, 
				  rm_pra.g16_niv_par,	 rm_pra.g16_nacional,
				  rm_pra.g16_verifcador)
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
	BEFORE FIELD g16_capitulo
		IF vm_flag_mant = 'M' THEN
			NEXT FIELD NEXT
		END IF 
	BEFORE FIELD g16_partida
		IF vm_flag_mant = 'M' THEN
			NEXT FIELD NEXT
		END IF 
	AFTER FIELD g16_capitulo
		LET rm_pra.g16_capitulo = get_fldbuf(g16_capitulo)	
                   IF  rm_pra.g16_capitulo IS NOT NULL THEN
			CALL fl_lee_capitulo(rm_pra.g16_capitulo) 
					      RETURNING r_g38.*
			IF r_g38.g38_capitulo IS NULL THEN
				CALL fl_mostrar_mensaje('Capítulo de Partida Arancelaria no existe.','exclamation')
				NEXT FIELD g16_capitulo
			END IF
                        LET rm_pra.g16_capitulo = r_g38.g38_capitulo
                        LET rm_par.g38_desc_cap = r_g38.g38_desc_cap
                        DISPLAY BY NAME rm_pra.g16_capitulo, rm_par.g38_desc_cap
  		ELSE
  			CLEAR g38_desc_cap
                END IF
		LET int_flag = 0
--OJO
	AFTER FIELD g16_partida
                IF  rm_pra.g16_partida IS NOT NULL THEN
                    CALL fl_lee_partida(rm_pra.g16_partida)
                                            RETURNING par.*
			IF par.g16_partida IS NOT NULL THEN
			     CALL fl_mostrar_mensaje('Partida Arancelaria ya existe.','exclamation')
			     NEXT FIELD g16_partida
			END IF
                END IF
		LET int_flag = 0
--------
END INPUT

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER
DEFINE desc_cap		LIKE gent038.g38_desc_cap

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_pra.*
	 FROM gent016 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
ELSE
	SELECT * INTO rm_par.*
		 FROM gent038
		WHERE g38_capitulo = rm_pra.g16_capitulo
END IF
DISPLAY BY NAME rm_pra.*
DISPLAY BY NAME rm_par.g38_desc_cap

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current              SMALLINT
DEFINE num_rows                 SMALLINT

DISPLAY "" AT 1,1
DISPLAY row_current, " de ", num_rows AT 1, 69
                                                                                
END FUNCTION
