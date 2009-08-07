------------------------------------------------------------------------------
-- Titulo           : vehp103.4gl - Mantenimiento de Lineas
-- Elaboracion      : 10-sep-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun vehp103 base modulo compania
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA r_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS

--
-- DEFINE RECORD(S) HERE
--
DEFINE rm_v03			RECORD LIKE veht003.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)

LET vg_proceso = 'vehp103'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_rows = 1000
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_v03 AT 3,2 WITH 14 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_v03 FROM '../forms/vehf103_1'
DISPLAY FORM f_v03

LET vm_num_rows = 0
LET vm_row_current = 0

INITIALIZE rm_v03.* TO NULL
CALL muestra_contadores()

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Bloquear/Activar'
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
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
	COMMAND KEY('M') 'Modificar' 		'Modificar registro corriente.'
		CALL control_modificacion()
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro.'
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
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
		CALL siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
		CALL anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('B') 'Bloquear/Activar'     'Bloquea o activa registro.'
		CALL control_bloquea_activa()
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()

DEFINE done 		SMALLINT             
DEFINE rowid		SMALLINT             

CLEAR FORM
INITIALIZE rm_v03.* TO NULL

LET rm_v03.v03_fecing   = CURRENT
LET rm_v03.v03_usuario  = vg_usuario
LET rm_v03.v03_compania = vg_codcia
LET rm_v03.v03_estado = 'A'
DISPLAY 'ACTIVO' TO n_estado

CALL lee_datos('I')
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL muestra_contadores()
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

BEGIN WORK

INSERT INTO veht003 VALUES (rm_v03.*)

LET rowid = SQLCA.SQLERRD[6]	 	-- Rowid de la ultima fila 
                                  	-- procesada
--LET done = actualiza_linea_taller()
LET done = 1
IF NOT done THEN
	ROLLBACK WORK
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL muestra_contadores()
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

COMMIT WORK

IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF 
LET vm_rows[vm_num_rows] = rowid
LET vm_row_current = vm_num_rows

CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_modificacion()

DEFINE done 		SMALLINT

IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

IF rm_v03.v03_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF

CALL lee_muestra_registro(vm_rows[vm_row_current])

WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_upd CURSOR FOR 
	SELECT * FROM veht003 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_upd
FETCH q_upd INTO rm_v03.*
WHENEVER ERROR STOP
IF STATUS < 0 THEN
	CALL fl_mensaje_bloqueo_otro_usuario()
	ROLLBACK WORK
	RETURN
END IF  

CALL lee_datos('M')

IF INT_FLAG THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	CLOSE q_upd
	RETURN
END IF 

UPDATE veht003 SET * = rm_v03.* WHERE CURRENT OF q_upd

LET done = actualiza_linea_taller()
IF NOT done THEN
	ROLLBACK WORK
	RETURN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
END IF

COMMIT WORK
CLOSE q_upd
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION actualiza_linea_taller()

DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT
DEFINE resp		CHAR(6)

DEFINE r_t01		RECORD LIKE talt001.*

CALL fl_lee_linea_taller(vg_codcia, rm_v03.v03_linea) RETURNING r_t01.*
IF r_t01.t01_compania IS NULL THEN
	LET r_t01.t01_compania     = rm_v03.v03_compania
	LET r_t01.t01_linea        = rm_v03.v03_linea
	LET r_t01.t01_nombre       = rm_v03.v03_nombre
	LET r_t01.t01_cod_mod_veh  = 'S'              
	LET r_t01.t01_dcto_mo_cont = 0.0
	LET r_t01.t01_dcto_rp_cont = 0.0  
	LET r_t01.t01_dcto_mo_cred = 0.0 
	LET r_t01.t01_dcto_rp_cred = 0.0
	LET r_t01.t01_usuario      = rm_v03.v03_usuario
	LET r_t01.t01_fecing       = rm_v03.v03_fecing
	INSERT INTO talt001 VALUES (r_t01.*)
	LET done = 1
ELSE
	LET intentar = 1
	LET done = 0
	WHILE (intentar)
		INITIALIZE r_t01.* TO NULL
		WHENEVER ERROR CONTINUE
			DECLARE q_t01 CURSOR FOR
				SELECT * FROM talt001
					WHERE t01_compania  = vg_codcia
					  AND t01_linea     = rm_v03.v03_linea
				FOR UPDATE
		OPEN  q_t01
		FETCH q_t01 INTO r_t01.*
		WHENEVER ERROR STOP
		IF STATUS < 0 THEN
			LET intentar = mensaje_intentar()
			CLOSE q_t01
			FREE  q_t01
		ELSE
			LET intentar = 0
			LET done = 1
		END IF
	END WHILE

	IF NOT intentar AND NOT done THEN
		RETURN done
	END IF

	LET r_t01.t01_nombre       = rm_v03.v03_nombre
	LET r_t01.t01_cod_mod_veh  = 'N'              
	
	UPDATE talt001 SET * = r_t01.* WHERE CURRENT OF q_t01 
	CLOSE q_t01
	FREE  q_t01
END IF

RETURN done

END FUNCTION



FUNCTION mensaje_intentar()

DEFINE intentar		SMALLINT
DEFINE resp		CHAR(6)

LET intentar = 1
CALL fgl_winquestion(vg_producto, 
		     'Registro bloqueado por ' ||
	      	     'otro usuario, desea ' ||
                     'intentarlo nuevamente', 'No',
		     'Yes|No', 'question', 1)
				RETURNING resp
IF resp = 'No' THEN
	CALL fl_mensaje_abandonar_proceso()
		 RETURNING resp
	IF resp = 'Yes' THEN
		LET intentar = 0
	END IF	
END IF

RETURN intentar

END FUNCTION



FUNCTION lee_datos(flag)
DEFINE flag 		CHAR(1)
DEFINE resp 		CHAR(6)

DEFINE grupo 		LIKE gent020.g20_grupo_linea
DEFINE nom_grp		LIKE gent020.g20_nombre

DEFINE r_v03 		RECORD LIKE veht003.*
DEFINE r_g20		RECORD LIKE gent020.*

LET INT_FLAG = 0
INPUT BY NAME rm_v03.v03_linea, rm_v03.v03_nombre, rm_v03.v03_estado, 
              rm_v03.v03_grupo_linea, rm_v03.v03_usuario,
              rm_v03.v03_fecing WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_v03.v03_linea, 
                                     rm_v03.v03_nombre,
                                     rm_v03.v03_grupo_linea
                                    ) THEN
			RETURN
		END IF

		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
                	RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN
		END IF
	ON KEY(F2)
		IF INFIELD(v03_grupo_linea) THEN
			CALL fl_ayuda_grupo_lineas(vg_codcia)
				RETURNING grupo, nom_grp
			IF grupo IS NOT NULL THEN
				LET rm_v03.v03_grupo_linea = grupo
				DISPLAY BY NAME rm_v03.v03_grupo_linea
				DISPLAY nom_grp TO n_grupo
			END IF
		END IF
		LET INT_FLAG = 0
	BEFORE FIELD v03_linea
		IF flag = 'M' THEN
			NEXT FIELD v03_nombre
		END IF
	AFTER  FIELD v03_linea
		IF rm_v03.v03_linea IS NULL THEN
			DISPLAY '' TO v03_nombre
		ELSE
			CALL fl_lee_linea_veh(vg_codcia, rm_v03.v03_linea)
				RETURNING r_v03.*
			IF r_v03.v03_linea IS NOT NULL THEN	
				CALL fgl_winmessage(vg_producto,
                                                    'Línea ya existe',
                                                    'exclamation')
				NEXT FIELD v03_linea
			END IF
		END IF
	AFTER  FIELD v03_grupo_linea
		IF rm_v03.v03_grupo_linea IS NULL THEN
			CLEAR n_grupo        
		ELSE
			CALL fl_lee_grupo_linea(vg_codcia, 
                                                rm_v03.v03_grupo_linea)
							RETURNING r_g20.*
			IF r_g20.g20_grupo_linea IS NULL THEN	
				CALL fgl_winmessage(vg_producto,
                                                    'Grupo de línea no existe',
                                                    'exclamation')
				NEXT FIELD v03_grupo_linea
			ELSE
				LET rm_v03.v03_grupo_linea = r_g20.g20_grupo_linea
				DISPLAY BY NAME rm_v03.v03_grupo_linea
				DISPLAY r_g20.g20_nombre TO n_grupo
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION control_consulta()

DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)

DEFINE linea		LIKE veht003.v03_linea
DEFINE nom_linea	LIKE veht003.v03_nombre

DEFINE grupo		LIKE gent020.g20_grupo_linea
DEFINE nom_grp		LIKE gent020.g20_nombre

DEFINE r_v03		RECORD LIKE veht003.*
DEFINE r_g20		RECORD LIKE gent020.*

CLEAR FORM

INITIALIZE rm_v03.* TO NULL

LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql 
	ON v03_linea, v03_estado, v03_nombre, v03_grupo_linea,  
	   v03_usuario
	ON KEY(F2)
		IF INFIELD(v03_linea) THEN
			CALL fl_ayuda_lineas_veh(vg_codcia)
				RETURNING linea, nom_linea
			IF linea IS NOT NULL THEN
				LET rm_v03.v03_linea = linea
				DISPLAY BY NAME rm_v03.v03_linea
				DISPLAY nom_linea TO v03_nombre
			END IF
		END IF
		IF INFIELD(v03_grupo_linea) THEN
			CALL fl_ayuda_grupo_lineas(vg_codcia)
				RETURNING grupo, nom_grp
			IF grupo IS NOT NULL THEN
				LET rm_v03.v03_grupo_linea = grupo
				DISPLAY BY NAME rm_v03.v03_grupo_linea
				DISPLAY nom_grp TO n_grupo
			END IF
		END IF
		LET INT_FLAG = 0
	AFTER  FIELD v03_linea
		LET rm_v03.v03_linea = GET_FLDBUF(v03_linea)
		IF rm_v03.v03_linea IS NULL THEN
			DISPLAY '' TO v03_nombre
		ELSE
			CALL fl_lee_linea_veh(vg_codcia, rm_v03.v03_linea)
				RETURNING r_v03.*
			IF r_v03.v03_linea IS NOT NULL THEN
				LET rm_v03.v03_linea = r_v03.v03_linea
				DISPLAY BY NAME rm_v03.v03_linea
				DISPLAY r_v03.v03_nombre TO v03_nombre
			ELSE
				DISPLAY '' TO v03_nombre
			END IF
		END IF
	AFTER  FIELD v03_grupo_linea
		LET rm_v03.v03_grupo_linea = GET_FLDBUF(v03_grupo_linea)
		IF rm_v03.v03_grupo_linea IS NULL THEN
			CLEAR n_grupo
		ELSE
			CALL fl_lee_grupo_linea(vg_codcia, 
                                                rm_v03.v03_grupo_linea)
							RETURNING r_g20.*
			IF r_g20.g20_grupo_linea IS NULL THEN
				CLEAR n_grupo
			ELSE
				LET rm_v03.v03_grupo_linea = r_g20.g20_grupo_linea
				DISPLAY BY NAME rm_v03.v03_grupo_linea
				DISPLAY r_g20.g20_nombre TO n_grupo
			END IF
		END IF
END CONSTRUCT

IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET query = 'SELECT *, ROWID FROM veht003 WHERE ', expr_sql, 
            ' AND v03_compania = ', vg_codcia, ' ORDER BY 3' 
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_v03.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > 1000 THEN
		EXIT FOREACH
	END IF	
END FOREACH 
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN 
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_num_rows = 0
	LET vm_row_current = 0
	CALL muestra_contadores()
	CLEAR FORM
	RETURN
END IF

LET vm_row_current = 1
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION siguiente_registro()

IF vm_num_rows = 0 THEN
	RETURN
END IF

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION anterior_registro()

IF vm_num_rows = 0 THEN
	RETURN
END IF

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION lee_muestra_registro(row)
DEFINE row 		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF

SELECT * INTO rm_v03.* FROM veht003 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

DISPLAY BY NAME rm_v03.v03_linea,   
                rm_v03.v03_nombre,
                rm_v03.v03_estado,
		rm_v03.v03_grupo_linea,
		rm_v03.v03_usuario,
		rm_v03.v03_fecing

CALL muestra_etiquetas()
CALL muestra_contadores()

END FUNCTION



FUNCTION control_bloquea_activa()

DEFINE resp    	CHAR(6)
DEFINE mensaje	VARCHAR(20)
DEFINE estado	CHAR(1)

LET int_flag = 0
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

CALL lee_muestra_registro(vm_rows[vm_row_current])
LET resp = 'Yes'
	LET mensaje = 'Seguro de bloquear'
	IF rm_v03.v03_estado <> 'A' THEN
		LET mensaje = 'Seguro de activar'
	END IF
	CALL fl_mensaje_seguro_ejecutar_proceso()
        	RETURNING resp

IF resp = 'Yes' THEN
	WHENEVER ERROR CONTINUE
	BEGIN WORK
	DECLARE q_del CURSOR FOR SELECT * FROM veht003 
		WHERE ROWID = vm_rows[vm_row_current]
		FOR UPDATE
	OPEN q_del
	FETCH q_del INTO rm_v03.*
	IF status < 0 THEN
		CALL fl_mensaje_bloqueo_otro_usuario()
		WHENEVER ERROR STOP
		ROLLBACK WORK
		RETURN
	END IF

	LET estado = 'B'
	IF rm_v03.v03_estado = 'B' THEN
		LET estado = 'A'
	END IF

	UPDATE veht003 SET v03_estado = estado WHERE CURRENT OF q_del
	COMMIT WORK
	CLOSE q_del
	WHENEVER ERROR STOP
	LET int_flag = 0 
	
	CALL fl_mensaje_registro_modificado()

	CLEAR FORM
	CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION muestra_contadores()

DISPLAY "" AT 1,1
DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 70 

END FUNCTION



FUNCTION muestra_etiquetas()

DEFINE nom_estado		CHAR(15)
DEFINE nom_grupo		LIKE gent020.g20_nombre

DEFINE r_g20			RECORD LIKE gent020.*

IF rm_v03.v03_estado = 'A' THEN
	LET nom_estado = 'ACTIVO'
ELSE
	LET nom_estado = 'BLOQUEADO'
END IF

CALL fl_lee_grupo_linea(vg_codcia, rm_v03.v03_grupo_linea) RETURNING r_g20.*
LET nom_grupo = r_g20.g20_nombre

DISPLAY nom_estado TO n_estado
DISPLAY nom_grupo  TO n_grupo

END FUNCTION



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 
                            'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 
                            'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || 
                            vg_codcia, 'stop')
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
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: ' || 
                            vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
