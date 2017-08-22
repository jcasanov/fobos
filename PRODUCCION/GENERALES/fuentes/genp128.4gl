------------------------------------------------------------------------------
-- Titulo           : genp128.4gl - Mantenimiento de Procesos por Módulo 
-- Elaboracion      : 30-ago-2001
-- Autor            : RCA
-- Formato Ejecucion: fglrun programa base modulo
-- Ultima Correccion: 28-mar-2002 
-- Motivo Correccion: Para escoger el estado de un radio
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_rows		ARRAY[1000] OF INTEGER	-- ARREGLO ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT		-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT		-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows	SMALLINT		-- MAXIMO DE FILAS LEIDAS
DEFINE rm_modu		RECORD LIKE gent054.*
DEFINE r		RECORD LIKE gent050.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/genp128.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 2 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_proceso = 'genp128'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 17
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_generales AT row_ini, 02 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_genf128_1 FROM '../forms/genf128_1'
ELSE
	OPEN FORM f_genf128_1 FROM '../forms/genf128_1c'
END IF
DISPLAY FORM f_genf128_1
INITIALIZE rm_modu.* TO NULL
LET vm_max_rows    = 1000
LET vm_num_rows    = 0
LET vm_row_current = 0
CALL muestra_contadores()
MENU 'PROCESOS'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Bloquear/Activar'
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registos'
		IF vm_num_rows = vm_max_rows THEN
			CALL fl_mensaje_arreglo_lleno()
		ELSE
			CALL control_ingreso()
		END IF
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
	COMMAND KEY('C') 'Consultar' 'Consultar un registro'
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
	COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro'
		CALL mostrar_siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
	COMMAND KEY('R') 'Retroceder'  'Ver anterior registro'
		CALL mostrar_anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('B') 'Bloquear/Activar' 'Bloquear o activar registro'
		CALL control_bloqueo()
	COMMAND KEY('S') 'Salir' 'Salir del programa'
		EXIT MENU
END MENU

END FUNCTION

 

FUNCTION control_consulta()
DEFINE modulo		LIKE gent050.g50_modulo
DEFINE nom_modulo	LIKE gent050.g50_nombre
DEFINE proceso		LIKE gent054.g54_proceso
DEFINE nom_proceso	LIKE gent054.g54_nombre
DEFINE expr_sql		VARCHAR(600)
DEFINE query		VARCHAR(800)

CLEAR FORM
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON g54_modulo, g54_proceso, g54_nombre, g54_tipo,
	g54_estado, g54_usuario
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT CONSTRUCT
	ON KEY(F2)
		IF INFIELD(g54_modulo) THEN
			CALL fl_ayuda_modulos() RETURNING modulo, nom_modulo  
			IF modulo IS NOT NULL THEN
				LET rm_modu.g54_modulo = modulo
				DISPLAY BY NAME rm_modu.g54_modulo  
			       	DISPLAY	BY NAME nom_modulo
			END IF
		END IF
		IF INFIELD(g54_proceso) THEN
			CALL fl_ayuda_procesos(modulo)
				RETURNING modulo, proceso, nom_proceso 
			IF proceso IS NOT NULL THEN
				LET rm_modu.g54_proceso = proceso
				LET rm_modu.g54_nombre  = nom_proceso
				DISPLAY BY NAME rm_modu.g54_proceso
				DISPLAY BY NAME rm_modu.g54_nombre
			END IF
		END IF
		LET int_flag = 0
END CONSTRUCT
IF int_flag THEN
	CLEAR FORM
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	CALL muestra_contadores()
	RETURN
END IF
LET query = 'SELECT *, ROWID FROM gent054 WHERE ', expr_sql CLIPPED
PREPARE cons FROM query
DECLARE q_modu CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_modu INTO rm_modu.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
	IF vm_num_rows > vm_max_rows THEN
		EXIT PROGRAM
	END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	CLEAR FORM
	LET vm_row_current = 0
	CALL muestra_contadores()
	RETURN
END IF
LET vm_row_current = 1
CLOSE q_modu
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL muestra_contadores()

END FUNCTION


  

FUNCTION control_modificacion()
DEFINE flag		CHAR(1)

CALL lee_muestra_registro(vm_rows[vm_row_current])
IF rm_modu.g54_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR
	SELECT * FROM gent054 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_modu.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
CALL ingresa_datos('M')
IF int_flag THEN
	ROLLBACK WORK
	RETURN
END IF
UPDATE gent054 SET * = rm_modu.* WHERE CURRENT OF q_up
COMMIT WORK
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION control_bloqueo()
DEFINE resp    	CHAR(6)
DEFINE i		SMALLINT
DEFINE mensaje	VARCHAR(20)
DEFINE estado 	CHAR(1)

LET int_flag = 0
IF rm_modu.g54_modulo IS NULL OR vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
      	RETURN
END IF
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_blo CURSOR FOR SELECT * FROM gent054 WHERE ROWID = vm_rows[vm_row_current]
      FOR UPDATE
OPEN q_blo
FETCH q_blo INTO rm_modu.*
IF status < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
LET mensaje = 'Seguro de bloquear'
LET estado = 'B'
IF rm_modu.g54_estado <> 'A' THEN
      LET mensaje = 'Seguro de activar'
      LET estado = 'A'
END IF
CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
IF resp <> 'Yes' THEN
	ROLLBACK WORK
	RETURN
END IF
UPDATE gent054 set g54_estado = estado WHERE CURRENT OF q_blo
COMMIT WORK
DISPLAY 'B' TO g54_estado
LET int_flag = 1
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL muestra_contadores()
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION control_ingreso()
DEFINE num_aux		INTEGER
DEFINE query		VARCHAR(400)

OPTIONS INPUT WRAP
CLEAR FORM
INITIALIZE rm_modu.* TO NULL
LET rm_modu.g54_fecing  = fl_current()
LET rm_modu.g54_usuario = vg_usuario 
LET rm_modu.g54_estado  = "A" 
LET rm_modu.g54_tipo    = 'M'
DISPLAY BY NAME rm_modu.g54_fecing, rm_modu.g54_usuario, rm_modu.g54_estado
CALL ingresa_datos('I')
IF NOT int_flag THEN
	BEGIN WORK
		INSERT INTO gent054 VALUES (rm_modu.*)
		LET num_aux = SQLCA.SQLERRD[6] 
		LET query = 'INSERT INTO gent055 ',
				' SELECT g05_usuario, ', vg_codcia, ', "',
					rm_modu.g54_modulo, '", "',
					rm_modu.g54_proceso CLIPPED, '", "',
					vg_usuario CLIPPED, '", "',
					fl_current(), '"',
				' FROM gent005 ',
				' WHERE g05_estado  = "A" ',
				'   AND g05_tipo   <> "AG"'
		PREPARE ins_g55 FROM query
		EXECUTE ins_g55
	COMMIT WORK
	CALL fl_mensaje_registro_ingresado()
	LET vm_num_rows = vm_num_rows + 1
	LET vm_rows[vm_num_rows] = num_aux
	LET vm_row_current = vm_num_rows
END IF
IF vm_num_rows > 0 THEN
	CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF
CALL muestra_contadores()

END FUNCTION




FUNCTION ingresa_datos(flag)
DEFINE resp   		CHAR(6)
DEFINE modulo		LIKE gent050.g50_modulo
DEFINE nom_modulo	LIKE gent050.g50_nombre
DEFINE rp		RECORD LIKE gent054.*
DEFINE flag 		CHAR(1)
DEFINE mod_ori		LIKE gent050.g50_modulo
DEFINE pro_ori		LIKE gent054.g54_proceso

IF flag = 'M' THEN
	LET mod_ori = rm_modu.g54_modulo
	LET pro_ori = rm_modu.g54_proceso
END IF
OPTIONS INPUT WRAP
LET int_flag = 0 
DISPLAY BY NAME rm_modu.g54_fecing

INPUT BY NAME	rm_modu.g54_modulo, 	rm_modu.g54_proceso, 	
		rm_modu.g54_nombre,
		rm_modu.g54_tipo,	rm_modu.g54_estado, 
		rm_modu.g54_usuario, 	rm_modu.g54_fecing
		WITHOUT DEFAULTS                                                           
	ON KEY (INTERRUPT)
		IF FIELD_TOUCHED (rm_modu.g54_modulo, rm_modu.g54_proceso, 	
		rm_modu.g54_nombre,
		rm_modu.g54_tipo, 	rm_modu.g54_estado,
		rm_modu.g54_usuario,	rm_modu.g54_fecing) THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
				RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				RETURN
			END IF
		ELSE
			RETURN
		END IF
	ON KEY (F2)
		IF INFIELD(g54_modulo) THEN
			CALL fl_ayuda_modulos() RETURNING modulo, nom_modulo  
			IF modulo IS NOT NULL THEN
				LET rm_modu.g54_modulo = modulo
				DISPLAY BY NAME rm_modu.g54_modulo  
			       	DISPLAY	BY NAME nom_modulo
			END IF
		END IF
	AFTER FIELD g54_modulo
		IF flag = 'M' THEN
			LET rm_modu.g54_modulo  = mod_ori
			DISPLAY BY NAME rm_modu.*
		END IF
		IF rm_modu.g54_modulo IS NOT NULL THEN
			CLEAR nom_modulo
			CALL fl_lee_modulo(rm_modu.g54_modulo) RETURNING r.*
			IF r.g50_modulo IS NULL THEN
              			CALL fgl_winmessage(vg_producto,'No existe un módulo con ese código','exclamation')
				NEXT FIELD g54_modulo
        		END IF   
			LET rm_modu.g54_modulo 	= r.g50_modulo
			LET nom_modulo     	= r.g50_nombre
        		DISPLAY BY NAME rm_modu.g54_modulo, nom_modulo
		END IF
	AFTER FIELD g54_proceso
		IF flag = 'M' THEN
			LET rm_modu.g54_proceso = pro_ori
			DISPLAY BY NAME rm_modu.*
		END IF
	AFTER INPUT
		CALL fl_lee_proceso(rm_modu.g54_modulo, rm_modu.g54_proceso)
			RETURNING rp.*
		IF status <> NOTFOUND AND flag <> 'M' THEN
              		CALL fgl_winmessage(vg_producto,
				'Proceso ya existe.',
				'exclamation')
			NEXT FIELD g54_modulo
        	END IF   
			
END INPUT
                                                                                
END FUNCTION



FUNCTION mostrar_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1 
END IF	
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL muestra_contadores()

END FUNCTION



FUNCTION mostrar_anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1 
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL muestra_contadores()

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER
DEFINE nom_modulo	LIKE gent050.g50_nombre

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_modu.* FROM gent054 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
DISPLAY BY NAME rm_modu.*
IF rm_modu.g54_modulo IS NOT NULL THEN
       SELECT g50_nombre INTO nom_modulo FROM gent050 
		WHERE g50_modulo = rm_modu.g54_modulo 
       IF STATUS = NOTFOUND THEN
              CALL fgl_winmessage(vg_producto,'No existe un modulo con ese código','info')
              CLEAR desc_modulo
        END IF   
        DISPLAY BY NAME nom_modulo
END IF
END FUNCTION



FUNCTION muestra_contadores() 

DISPLAY '' AT 1,1
DISPLAY vm_row_current, ' de ',vm_num_rows AT 1,67

END FUNCTION



FUNCTION no_validar_parametros()

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




