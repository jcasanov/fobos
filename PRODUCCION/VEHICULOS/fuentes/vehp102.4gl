------------------------------------------------------------------------------
-- Titulo           : vehp102.4gl - Mantenimiento Bodegas
-- Elaboracion      : 10-sep-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun vehp102 base modulo compania
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
DEFINE rm_v02			RECORD LIKE veht002.*



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
LET vg_proceso = 'vehp102'

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
OPEN WINDOW w_v02 AT 3,2 WITH 18 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_v02 FROM '../forms/vehf102_1'
DISPLAY FORM f_v02

LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_v02.* TO NULL
CALL muestra_contadores()

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Bloquear/Activar'
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Bloquear/Activar'
		END IF
		IF vm_num_rows > 1 THEN
			SHOW OPTION 'Retroceder'
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

CLEAR FORM
INITIALIZE rm_v02.* TO NULL

LET rm_v02.v02_compania = vg_codcia
LET rm_v02.v02_usuario  = vg_usuario
LET rm_v02.v02_fecing   = CURRENT
LET rm_v02.v02_estado   = 'A'
DISPLAY 'ACTIVO' TO n_estado
LET rm_v02.v02_tipo     = 'F'
LET rm_v02.v02_factura  = 'N'

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

INSERT INTO veht002 VALUES (rm_v02.*)

LET vm_num_rows    = vm_num_rows + 1
LET vm_row_current = vm_num_rows
LET vm_rows[vm_num_rows] = SQLCA.SQLERRD[6] 	-- Rowid de la ultima fila 
                                             	-- procesada
CALL muestra_contadores()
CALL muestra_etiquetas()

CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_modificacion()

IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

IF rm_v02.v02_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF

CALL lee_muestra_registro(vm_rows[vm_row_current])

WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_upd CURSOR FOR 
	SELECT * FROM veht002 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_upd
FETCH q_upd INTO rm_v02.*
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

UPDATE veht002 SET * = rm_v02.* WHERE CURRENT OF q_upd
COMMIT WORK
CLOSE q_upd
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION lee_datos(flag)

DEFINE flag 		CHAR(1)
DEFINE resp 		CHAR(6)

DEFINE r_v02		RECORD LIKE veht002.*

DEFINE bodega		LIKE veht002.v02_bodega
DEFINE nom_bodega	LIKE veht002.v02_nombre
DEFINE est_bodega	LIKE veht002.v02_estado

DEFINE localidad	LIKE gent002.g02_localidad
DEFINE nom_localidad	LIKE gent002.g02_nombre
DEFINE est_localidad	LIKE gent002.g02_estado

DEFINE r_loc		RECORD LIKE gent002.*

INITIALIZE bodega TO NULL
INITIALIZE r_loc.* TO NULL
LET INT_FLAG = 0
INPUT BY NAME rm_v02.v02_bodega, rm_v02.v02_nombre, rm_v02.v02_factura, 
              rm_v02.v02_tipo, rm_v02.v02_localidad, rm_v02.v02_estado,
              rm_v02.v02_usuario, rm_v02.v02_fecing
        WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(v02_bodega, v02_nombre, v02_factura, 
                                     v02_tipo, v02_localidad
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
		IF INFIELD(v02_localidad) THEN
			CALL fl_ayuda_localidad(vg_codcia) 
				RETURNING localidad, nom_localidad 
			IF localidad IS NOT NULL THEN
				LET rm_v02.v02_localidad = localidad
				DISPLAY localidad TO v02_localidad
				DISPLAY nom_localidad TO n_localidad
			END IF
		END IF
		LET INT_FLAG = 0
	BEFORE FIELD v02_bodega
		IF flag = 'M' THEN
			NEXT FIELD v02_nombre
		END IF
	AFTER  FIELD v02_bodega
		IF rm_v02.v02_bodega IS NULL THEN
			DISPLAY '' TO v02_nombre
		ELSE
			CALL fl_lee_bodega_veh(vg_codcia, rm_v02.v02_bodega)
				RETURNING r_v02.*
			IF r_v02.v02_compania IS NOT NULL THEN	
				CALL fgl_winmessage(vg_producto,
                                                    'Bodega ya existe.',
                                                    'exclamation')
				NEXT FIELD v02_bodega
			END IF
		END IF
	AFTER  FIELD v02_localidad
		IF rm_v02.v02_localidad IS NULL THEN
			DISPLAY '' TO n_localidad
		ELSE
			CALL fl_lee_localidad(vg_codcia, rm_v02.v02_localidad)
				RETURNING r_loc.*
			IF r_loc.g02_localidad IS NULL THEN	
				DISPLAY '' TO n_localidad
				NEXT FIELD v02_localidad
			ELSE
				IF r_loc.g02_estado = 'B' THEN
					DISPLAY '' TO n_localidad
					CALL fgl_winmessage(vg_producto,
						           'Localidad está' ||
                                                           ' bloqueada',
						    	   'exclamation')
					NEXT FIELD v02_localidad
				ELSE
					DISPLAY r_loc.g02_nombre TO n_localidad
				END IF
			END IF 
		END IF
END INPUT

END FUNCTION



FUNCTION control_consulta()

DEFINE expr_sql			VARCHAR(500)
DEFINE query			VARCHAR(600)

DEFINE bodega		LIKE veht002.v02_bodega
DEFINE nom_bodega	LIKE veht002.v02_nombre
DEFINE est_bodega	LIKE veht002.v02_estado

DEFINE localidad	LIKE gent002.g02_localidad
DEFINE nom_localidad	LIKE gent002.g02_nombre
DEFINE est_localidad	LIKE gent002.g02_estado

DEFINE r_loc		RECORD LIKE gent002.*
DEFINE r_v02		RECORD LIKE veht002.*

CLEAR FORM

LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql 
	ON v02_bodega, v02_estado, v02_nombre, v02_factura, v02_tipo,  
	   v02_localidad, v02_usuario
	ON KEY(F2)
		IF INFIELD(v02_bodega) THEN
			CALL fl_ayuda_bodegas_veh(vg_codcia) 
				RETURNING bodega, nom_bodega 
			IF bodega IS NOT NULL THEN
				LET rm_v02.v02_bodega = bodega
				DISPLAY bodega TO v02_bodega
				DISPLAY nom_bodega TO v02_nombre
			END IF
		END IF
		IF INFIELD(v02_localidad) THEN
			CALL fl_ayuda_localidad(vg_codcia) 
				RETURNING localidad, nom_localidad 
			IF localidad IS NOT NULL THEN
				LET rm_v02.v02_localidad = localidad
				DISPLAY localidad TO v02_localidad
				DISPLAY nom_localidad TO n_localidad
			END IF
		END IF
		LET INT_FLAG = 0
	AFTER  FIELD v02_bodega
		LET rm_v02.v02_bodega = GET_FLDBUF(v02_bodega)
		IF rm_v02.v02_bodega IS NULL THEN
			DISPLAY '' TO v02_nombre
		ELSE
			CALL fl_lee_bodega_veh(vg_codcia, rm_v02.v02_bodega)
				RETURNING r_v02.*
			IF r_v02.v02_bodega IS NULL THEN	
				DISPLAY '' TO v02_nombre
			ELSE
				DISPLAY r_v02.v02_nombre TO v02_nombre
			END IF
		END IF
	AFTER  FIELD v02_localidad
		LET rm_v02.v02_localidad = GET_FLDBUF(v02_localidad)
		IF rm_v02.v02_localidad IS NULL THEN
			DISPLAY '' TO n_localidad
		ELSE
			CALL fl_lee_localidad(vg_codcia, rm_v02.v02_localidad)
				RETURNING r_loc.*
			IF r_loc.g02_localidad IS NULL THEN	
				DISPLAY '' TO n_localidad
			ELSE
				DISPLAY r_loc.g02_nombre TO n_localidad
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

LET query = 'SELECT *, ROWID FROM veht002 WHERE ', expr_sql, 
            ' AND v02_compania = ', vg_codcia, ' ORDER BY 3' 
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_v02.*, vm_rows[vm_num_rows]
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

SELECT * INTO rm_v02.* FROM veht002 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

DISPLAY BY NAME rm_v02.v02_bodega,
		rm_v02.v02_nombre,
		rm_v02.v02_estado,
		rm_v02.v02_tipo,
		rm_v02.v02_factura,
		rm_v02.v02_localidad,
		rm_v02.v02_usuario,
		rm_v02.v02_fecing
CALL muestra_contadores()
CALL muestra_etiquetas()

END FUNCTION



FUNCTION control_bloquea_activa()

DEFINE resp    	CHAR(6)
DEFINE i	SMALLINT
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
	IF rm_v02.v02_estado <> 'A' THEN
		LET mensaje = 'Seguro de activar'
	END IF
	CALL fl_mensaje_seguro_ejecutar_proceso()
        	RETURNING resp

IF resp = 'Yes' THEN
	WHENEVER ERROR CONTINUE
	BEGIN WORK
	DECLARE q_del CURSOR FOR SELECT * FROM veht002 
		WHERE ROWID = vm_rows[vm_row_current]
		FOR UPDATE
	OPEN q_del
	FETCH q_del INTO rm_v02.*
	IF status < 0 THEN
		CALL fl_mensaje_bloqueo_otro_usuario()
		WHENEVER ERROR STOP
		ROLLBACK WORK
		RETURN
	END IF

	LET estado = 'B'
	IF rm_v02.v02_estado <> 'A' THEN
		LET estado = 'A'
	END IF

	UPDATE veht002 SET v02_estado = estado WHERE CURRENT OF q_del
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

DEFINE nom_estado		CHAR(6)
DEFINE nom_localidad		LIKE gent002.g02_nombre

DEFINE r_g02			RECORD LIKE gent002.*

CALL fl_lee_localidad(vg_codcia, rm_v02.v02_localidad) RETURNING r_g02.*
LET nom_localidad = r_g02.g02_nombre

IF rm_v02.v02_estado = 'A' THEN
	LET nom_estado = 'ACTIVO'
ELSE
	LET nom_estado = 'BLOQUEADO'
END IF

DISPLAY nom_localidad TO n_localidad
DISPLAY nom_estado    TO n_estado

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
