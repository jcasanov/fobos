------------------------------------------------------------------------------
-- Titulo           : maqp200.4gl - Mantenimiento de Maquinaria Por Clientes    
-- Elaboracion      : 18-nov-2004
-- Autor            : JCM
-- Formato Ejecucion: fglrun maqp200 base modulo compania 
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA r_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS

DEFINE vm_max_rows	SMALLINT
--
-- DEFINE RECORD(S) HERE
--
DEFINE rm_m00			RECORD LIKE maqt000.*  --Parametros
DEFINE rm_m11			RECORD LIKE maqt011.*
DEFINE rm_m12			RECORD LIKE maqt012.*
DEFINE m11_provincia		SMALLINT

DEFINE r_detalle ARRAY[500] OF RECORD 
	m13_fecha		LIKE maqt013.m13_fecha,
	m13_comentario		LIKE maqt013.m13_comentario
END RECORD
DEFINE vm_num_det		SMALLINT
DEFINE vm_max_det		SMALLINT



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/maqp200.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN	-- Validar # par�metros correcto
	CALL fgl_winmessage(vg_producto, 'N�mero de par�metros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'maqp200'

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
LET vm_max_det  = 500 
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_m11 AT 3,2 WITH 20 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_m11 FROM '../forms/maqf200_1'
DISPLAY FORM f_m11

DISPLAY '' TO n_estado

LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_m11.* TO NULL
INITIALIZE rm_m12.* TO NULL
CALL muestra_contadores()
CALL muestra_etiquetas()

CALL fl_lee_parametros_maq(vg_codcia) RETURNING rm_m00.*

LET vm_max_rows = 1000

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Ubicacion'
		HIDE OPTION 'Bit�cora'
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Ubicacion'
			SHOW OPTION 'Bit�cora'
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
			SHOW OPTION 'Ubicacion'
			SHOW OPTION 'Bit�cora'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Ubicacion'
				HIDE OPTION 'Bit�cora'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Ubicacion'
			SHOW OPTION 'Bit�cora'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
	COMMAND KEY('U') 'Ubicacion'		'Muestra datos sobre la ubicacion de la maquina'
		CALL mostrar_ubicacion()
		LET int_flag = 0
	COMMAND KEY('L') 'Bit�cora'		'Muestra la bit�cora de una maquina'
		CALL mostrar_bitacora()
		LET int_flag = 0
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
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()
DEFINE rowid		INTEGER
DEFINE r_t10		RECORD LIKE talt010.*

CLEAR FORM
INITIALIZE rm_m11.* TO NULL
INITIALIZE rm_m12.* TO NULL

-- INITIALIZING NOT NULL FIELDS. IF IN AN INPUT I CAN'T PUT ANYTHING IN THEM -- 

-- Campos de la tabla maqt011
LET rm_m11.m11_compania       = vg_codcia
LET rm_m11.m11_estado         = 'A'
LET rm_m11.m11_nuevo          = 'S'

DISPLAY 'ACTIVO' TO n_estado

-- Campos de la tabla maqt011
LET rm_m12.m12_compania    = vg_codcia
LET rm_m12.m12_fecha       = CURRENT
LET rm_m12.m12_horometro   = 0

------------------------------------------------------------------------------- 

CALL lee_datos('I')
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

SELECT MAX(m11_secuencia) INTO rm_m11.m11_secuencia
	FROM maqt011 
	WHERE m11_compania  = vg_codcia
	  AND m11_modelo    = rm_m11.m11_modelo
IF rm_m11.m11_secuencia IS NULL THEN
	LET rm_m11.m11_secuencia = 1
ELSE
	LET rm_m11.m11_secuencia = rm_m11.m11_secuencia + 1
END IF
INSERT INTO maqt011 VALUES (rm_m11.*)
LET rowid = SQLCA.SQLERRD[6] 	-- Rowid de la ultima fila procesada 

LET rm_m12.m12_compania  = rm_m11.m11_compania
LET rm_m12.m12_modelo    = rm_m11.m11_modelo
LET rm_m12.m12_secuencia = rm_m11.m11_secuencia

INSERT INTO maqt012 VALUES (rm_m12.*)

LET r_t10.t10_compania = rm_m11.m11_compania
LET r_t10.t10_codcli   = rm_m11.m11_codcli  
LET r_t10.t10_modelo   = rm_m11.m11_modelo  
LET r_t10.t10_chasis   = rm_m11.m11_serie   
LET r_t10.t10_estado   = rm_m11.m11_estado   
LET r_t10.t10_color    = 'AMARILLO'          
LET r_t10.t10_motor    = rm_m11.m11_motor    
LET r_t10.t10_placa    = 0                   
LET r_t10.t10_usuario  = vg_usuario      
LET r_t10.t10_fecing   = CURRENT             

WHENEVER ERROR CONTINUE
INSERT INTO talt010 VALUES (r_t10.*)
WHENEVER ERROR STOP

IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF
LET vm_row_current = vm_num_rows
LET vm_rows[vm_num_rows] = rowid            	-- Rowid de la ultima fila 
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

IF rm_m11.m11_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF

CALL lee_muestra_registro(vm_rows[vm_row_current])

BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_upd CURSOR FOR 
	SELECT * FROM maqt011 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_upd
FETCH q_upd INTO rm_m11.*
WHENEVER ERROR STOP
IF SQLCA.SQLCODE < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	RETURN
END IF  
IF SQLCA.SQLCODE = NOTFOUND THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto, 'No existe rowid en la tabla.', 'stop')
	RETURN
END IF  

CALL lee_datos('M')

IF INT_FLAG THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	RETURN
END IF 

UPDATE maqt011 SET * = rm_m11.* WHERE CURRENT OF q_upd

LET rm_m12.m12_compania  = rm_m11.m11_compania
LET rm_m12.m12_modelo    = rm_m11.m11_modelo
LET rm_m12.m12_secuencia = rm_m11.m11_secuencia

DELETE FROM maqt012 WHERE m12_compania  = rm_m11.m11_compania
                      AND m12_modelo    = rm_m11.m11_modelo  
                      AND m12_secuencia = rm_m11.m11_secuencia  
                      AND m12_fecha     = rm_m12.m12_fecha  
INSERT INTO maqt012 VALUES (rm_m12.*)

COMMIT WORK
CALL fl_mensaje_registro_modificado()


END FUNCTION



FUNCTION lee_datos(flag)

DEFINE flag 		CHAR(1)
DEFINE resp 		CHAR(6)

DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_m01		RECORD LIKE maqt001.*
DEFINE r_m02		RECORD LIKE maqt002.*
DEFINE r_m05		RECORD LIKE maqt005.*
DEFINE r_m10		RECORD LIKE maqt010.*

DEFINE r_m12		RECORD LIKE maqt012.*

DEFINE query 		VARCHAR(1000)


LET query = 'SELECT * FROM maqt012 WHERE m12_compania  = ? ',
                                  '  AND m12_modelo    = ? ',
                                  '  AND m12_secuencia = ? ',
            ' ORDER BY m12_fecha DESC '

PREPARE qcons FROM query
DECLARE q_ult_rev CURSOR FOR qcons 

LET INT_FLAG = 0
INPUT BY NAME rm_m11.m11_estado,    rm_m11.m11_codcli, 
              rm_m11.m11_modelo,    rm_m11.m11_serie,  rm_m11.m11_comentarios, 
              rm_m11.m11_ano,       rm_m11.m11_motor,  rm_m11.m11_fecha_ent, 
              rm_m11.m11_fecha_sgte_rev, rm_m12.m12_fecha,     
              rm_m12.m12_horometro, 
              rm_m11.m11_canton,    rm_m11.m11_garantia_meses,
              rm_m11.m11_garantia_horas WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_m11.m11_estado, rm_m11.m11_codcli, rm_m11.m11_modelo, rm_m11.m11_serie, rm_m11.m11_comentarios, rm_m11.m11_ano, rm_m11.m11_motor, rm_m11.m11_fecha_ent, rm_m12.m12_fecha, rm_m11.m11_fecha_sgte_rev, rm_m12.m12_horometro, rm_m11.m11_garantia_meses, rm_m11.m11_garantia_horas, rm_m11.m11_canton) 
		THEN
			RETURN
		END IF

		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
                	RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN
		END IF
	ON KEY(F5)
		CALL ingresa_datos_ubicacion()
		LET int_flag = 0
	ON KEY(F6)
		CALL ingresar_log()
		LET int_flag = 0
	BEFORE INPUT
		CALL dialog.keysetlabel('F5', 'Ubicacion')
		CALL dialog.keysetlabel('F6', 'Bit�cora')
	ON KEY(F2)
		IF INFIELD(m11_codcli) THEN
			CALL fl_ayuda_cliente_localidad(vg_codcia, vg_codloc)
				RETURNING r_z01.z01_codcli, r_z01.z01_nomcli
			IF r_z01.z01_codcli IS NOT NULL THEN
				LET rm_m11.m11_codcli = r_z01.z01_codcli
				DISPLAY BY NAME rm_m11.m11_codcli
				DISPLAY r_z01.z01_nomcli TO n_cliente
			END IF 
		END IF
		IF INFIELD(m11_modelo) THEN
			CALL fl_ayuda_modelos_lineas_maq(vg_codcia)
				RETURNING r_m10.m10_linea,  r_m05.m05_nombre, 
                                          r_m10.m10_modelo, 
                                          r_m10.m10_descripcion
			IF r_m10.m10_modelo IS NOT NULL THEN
				LET rm_m11.m11_modelo = r_m10.m10_modelo
				DISPLAY BY NAME rm_m11.m11_modelo
				DISPLAY r_m10.m10_descripcion
                                     TO n_modelo
			END IF
		END IF
		IF INFIELD(m11_canton) THEN
			INITIALIZE m11_provincia TO NULL
			CALL fl_ayuda_cantones(m11_provincia)
				RETURNING r_m02.m02_provincia,
                                          r_m01.m01_nombre,
  					  r_m02.m02_canton, 
                                          r_m02.m02_nombre
			IF r_m02.m02_provincia IS NOT NULL THEN
				LET m11_provincia = r_m02.m02_provincia
				LET rm_m11.m11_canton    = r_m02.m02_canton
				DISPLAY BY NAME m11_provincia,
                                                rm_m11.m11_canton
				DISPLAY r_m01.m01_nombre, r_m02.m02_nombre
                                     TO n_provincia, n_canton
			END IF
		END IF
		LET INT_FLAG = 0
	AFTER FIELD m11_codcli
		IF rm_m11.m11_codcli IS NOT NULL THEN
			CALL fl_lee_cliente_general(rm_m11.m11_codcli)
				RETURNING r_z01.*
			IF r_z01.z01_codcli IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe el Cliente en la Compa��a. ','exclamation') 
				CLEAR n_cliente
				NEXT FIELD m11_codcli
			END IF
			IF r_z01.z01_estado <> 'A' THEN
				CALL fgl_winmessage(vg_producto,
						    'Cliente est� bloqueado',
						    'exclamation')
				CLEAR n_cliente
				NEXT FIELD m11_codcli
			END IF
			DISPLAY r_z01.z01_nomcli TO n_cliente
		END IF
	AFTER  FIELD m11_modelo
		IF rm_m11.m11_modelo IS NULL THEN
			CLEAR n_modelo
		ELSE
			CALL fl_lee_modelo_maq(rm_m11.m11_compania, 
                                               rm_m11.m11_modelo)
					RETURNING r_m10.*
			IF r_m10.m10_modelo IS NULL THEN	
				CLEAR n_modelo
				CALL fgl_winmessage(vg_producto,
					            'Modelo no existe',
						    'exclamation')
				NEXT FIELD m11_modelo
			ELSE
				DISPLAY r_m10.m10_descripcion TO n_modelo
			END IF 
		END IF
	AFTER FIELD m11_canton
		IF rm_m11.m11_canton IS NULL THEN
			CLEAR n_canton
		ELSE
			CALL fl_lee_canton(rm_m11.m11_canton)
				RETURNING r_m02.*
			IF r_m02.m02_provincia IS NULL THEN	
				CLEAR n_canton
				CALL fgl_winmessage(vg_producto, 'Cant�n no existe',
						    'exclamation')
				NEXT FIELD m11_canton
			ELSE
				DISPLAY r_m02.m02_nombre TO n_canton
			END IF 
		END IF
	AFTER FIELD m12_fecha 
		IF rm_m12.m12_fecha <= rm_m11.m11_fecha_ent THEN
			CALL fgl_winmessage(vg_producto, 'La fecha de �ltima revisi�n debe ser mayor a la fecha de entrega.', 'exclamation')
			NEXT FIELD m12_fecha
		END IF
		OPEN  q_ult_rev USING vg_codcia, rm_m11.m11_modelo, rm_m11.m11_secuencia
		FETCH q_ult_rev INTO r_m12.*
		CLOSE q_ult_rev
		IF rm_m12.m12_fecha < r_m12.m12_fecha THEN
			CALL fgl_winmessage(vg_producto, 'La fecha no puede ser menor a la de la �ltima revisi�n.', 'exclamation')
			NEXT FIELD m12_fecha
		END IF
	AFTER FIELD m12_horometro 
		IF rm_m12.m12_horometro < 0 THEN
			CALL fgl_winmessage(vg_producto, 'El valor en el hor�metro no puede ser negativo.', 'information')
			NEXT FIELD m12_horometro
		END IF
	AFTER INPUT
		LET rm_m11.m11_estado = 'A'
		CALL calcula_sgte_revision()
END INPUT

END FUNCTION



FUNCTION control_consulta()

DEFINE expr_sql			VARCHAR(500)
DEFINE query			VARCHAR(600)

DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_m01		RECORD LIKE maqt001.*
DEFINE r_m02		RECORD LIKE maqt002.*
DEFINE r_m05		RECORD LIKE maqt005.*
DEFINE r_m10		RECORD LIKE maqt010.*

CLEAR FORM

INITIALIZE m11_provincia TO NULL

LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql 
	ON m11_estado, m11_codcli, m11_modelo, m11_serie, m11_comentarios, 
           m11_ano, m11_motor, m11_fecha_ent, m11_fecha_sgte_rev,
	   m11_canton
	ON KEY(F2)
		IF INFIELD(m11_codcli) THEN
			CALL fl_ayuda_cliente_localidad(vg_codcia, vg_codloc)
				RETURNING r_z01.z01_codcli, r_z01.z01_nomcli
			IF r_z01.z01_codcli IS NOT NULL THEN
				LET rm_m11.m11_codcli = r_z01.z01_codcli
				DISPLAY BY NAME rm_m11.m11_codcli
				DISPLAY r_z01.z01_nomcli TO n_cliente
			END IF 
		END IF
		IF INFIELD(m11_modelo) THEN
			CALL fl_ayuda_modelos_lineas_maq(vg_codcia)
				RETURNING r_m10.m10_linea,  r_m05.m05_nombre, 
                                          r_m10.m10_modelo, 
                                          r_m10.m10_descripcion
			IF r_m10.m10_modelo IS NOT NULL THEN
				LET rm_m11.m11_modelo = r_m10.m10_modelo
				DISPLAY BY NAME rm_m11.m11_modelo
				DISPLAY r_m10.m10_descripcion
                                     TO n_modelo
			END IF
		END IF
		IF INFIELD(m11_provincia) THEN
			CALL fl_ayuda_provincias()
				RETURNING r_m01.m01_provincia, 
                                          r_m01.m01_nombre
			IF r_m01.m01_provincia IS NOT NULL THEN
				LET m11_provincia = r_m01.m01_provincia
				DISPLAY BY NAME m11_provincia 
				DISPLAY r_m01.m01_nombre TO n_provincia
			END IF
		END IF
		IF INFIELD(m11_canton) THEN
			CALL fl_ayuda_cantones(m11_provincia)
				RETURNING r_m02.m02_provincia,
                                          r_m01.m01_nombre,
  					  r_m02.m02_canton, 
                                          r_m02.m02_nombre
			IF r_m02.m02_provincia IS NOT NULL THEN
				LET m11_provincia = r_m02.m02_provincia
				LET rm_m11.m11_canton    = r_m02.m02_canton
				DISPLAY BY NAME m11_provincia,
                                                rm_m11.m11_canton
				DISPLAY r_m01.m01_nombre, r_m02.m02_nombre
                                     TO n_provincia, n_canton
			END IF
		END IF
		LET INT_FLAG = 0
END CONSTRUCT

IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET query = 'SELECT *, ROWID FROM maqt011 ',
            '	WHERE m11_compania  = ', vg_codcia, 
            '  	  AND ', expr_sql, 
            ' ORDER BY m11_compania, m11_codcli, m11_modelo' 
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_m11.*, vm_rows[vm_num_rows]
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



FUNCTION lee_muestra_registro(row)
DEFINE row 		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF

SELECT * INTO rm_m11.* FROM maqt011 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

INITIALIZE rm_m12.* TO NULL
DECLARE q_q12 CURSOR FOR
	SELECT * FROM maqt012 WHERE m12_compania  = rm_m11.m11_compania
				AND m12_modelo    = rm_m11.m11_modelo
				AND m12_secuencia = rm_m11.m11_secuencia
		ORDER BY m12_fecha DESC

OPEN  q_q12
FETCH q_q12 INTO rm_m12.*
CLOSE q_q12
FREE  q_q12

DISPLAY BY NAME rm_m11.m11_estado,
                rm_m11.m11_codcli,
                rm_m11.m11_modelo,
		rm_m11.m11_serie,
		rm_m11.m11_comentarios,
		rm_m11.m11_motor,
		rm_m11.m11_ano,
		rm_m11.m11_fecha_ent,
		rm_m11.m11_fecha_sgte_rev,
		rm_m12.m12_fecha,
		rm_m12.m12_horometro,
		m11_provincia,
		rm_m11.m11_canton,
		rm_m11.m11_garantia_meses,
		rm_m11.m11_garantia_horas

CALL muestra_contadores()
CALL muestra_etiquetas()

END FUNCTION



FUNCTION muestra_contadores()

DISPLAY "" AT 1,1
DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 67 

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



FUNCTION muestra_etiquetas()

DEFINE n_estado		CHAR(11)

DEFINE r_z01			RECORD LIKE cxct001.*
DEFINE r_m10			RECORD LIKE maqt010.*
DEFINE r_m01			RECORD LIKE maqt001.*
DEFINE r_m02			RECORD LIKE maqt002.*

CALL fl_lee_cliente_general(rm_m11.m11_codcli) RETURNING r_z01.*
CALL fl_lee_canton(rm_m11.m11_canton) RETURNING r_m02.*
LET m11_provincia = r_m02.m02_provincia
CALL fl_lee_provincia(m11_provincia)  RETURNING r_m01.*

CASE rm_m11.m11_estado
	WHEN 'A' LET n_estado = 'ACTIVO'
	WHEN 'B' LET n_estado = 'BLOQUEADO'
	WHEN 'C' LET n_estado = 'EN CHEQUEO'
END CASE
DISPLAY r_z01.z01_nomcli, m11_provincia, r_m01.m01_nombre, 
        r_m02.m02_nombre, n_estado 
     TO n_cliente, m11_provincia, n_provincia, n_canton, n_estado

END FUNCTION



FUNCTION ingresa_datos_ubicacion()

DEFINE telf			VARCHAR(30)
DEFINE r_z01			RECORD LIKE cxct001.*

DEFINE 
	ubic_ant		LIKE maqt011.m11_ubicacion,
	telf_ant		LIKE maqt011.m11_telf_ubic

IF rm_m11.m11_codcli IS NULL THEN
	CALL fgl_winmessage(VG_PRODUCTO, 'Debe ingresar el cliente primero.', 'info')
	RETURN
END IF

OPEN WINDOW w_pch1 AT 7,10 WITH FORM "../forms/maqf200_2"
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER, MENU LINE 0)

CALL fl_lee_cliente_general(rm_m11.m11_codcli) RETURNING r_z01.*

LET telf = r_z01.z01_telefono1 CLIPPED 
IF r_z01.z01_telefono2 IS NOT NULL THEN
	LET telf = telf CLIPPED, ' - ', r_z01.z01_telefono2 CLIPPED
END IF

DISPLAY r_z01.z01_codcli, r_z01.z01_nomcli, r_z01.z01_direccion1, 
        telf, rm_m11.m11_ubicacion, rm_m11.m11_telf_ubic
     TO m11_codcli, n_cliente, direccion, telefonos, m11_ubicacion, 
        m11_telf_ubic 

OPTIONS 
	INPUT WRAP,
	ACCEPT KEY F12

LET ubic_ant = rm_m11.m11_ubicacion
LET telf_ant = rm_m11.m11_telf_ubic

LET int_flag = 0
INPUT BY NAME rm_m11.m11_ubicacion, rm_m11.m11_telf_ubic WITHOUT DEFAULTS
IF int_flag THEN
	LET rm_m11.m11_ubicacion = ubic_ant
	LET rm_m11.m11_telf_ubic = telf_ant
END IF 

LET int_flag = 0
CLOSE WINDOW w_pch1

END FUNCTION



FUNCTION mostrar_ubicacion()

DEFINE telf			VARCHAR(30)
DEFINE r_z01			RECORD LIKE cxct001.*

OPEN WINDOW w_pch AT 7,10 WITH FORM "../forms/maqf200_2"
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER, MENU LINE 0)

CALL fl_lee_cliente_general(rm_m11.m11_codcli) RETURNING r_z01.*

LET telf = r_z01.z01_telefono1 CLIPPED 
IF r_z01.z01_telefono2 IS NOT NULL THEN
	LET telf = telf CLIPPED, ' - ', r_z01.z01_telefono2 CLIPPED
END IF

LET int_flag = 0
WHILE TRUE
	DISPLAY r_z01.z01_codcli, r_z01.z01_nomcli, r_z01.z01_direccion1, 
                telf, rm_m11.m11_ubicacion, rm_m11.m11_telf_ubic
	     TO m11_codcli, n_cliente, direccion, telefonos, m11_ubicacion, 
                m11_telf_ubic 

	IF int_flag THEN
		EXIT WHILE
	END IF
END WHILE

LET int_flag = 0
CLOSE WINDOW w_pch

END FUNCTION



FUNCTION ingresar_log()

DEFINE i, j 		SMALLINT

CALL cargar_datos_log()

OPEN WINDOW w_log AT 7,4 WITH FORM "../forms/maqf200_3"
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER, MENU LINE 0)

DISPLAY 'Fecha'      TO tit_col1
DISPLAY 'Comentario' TO tit_col2

	CALL set_count(vm_num_det)
	INPUT ARRAY r_detalle WITHOUT DEFAULTS FROM r_detalle.*
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
			IF r_detalle[i].m13_fecha IS NULL THEN
				LET r_detalle[i].m13_fecha = TODAY
			END IF
			DISPLAY r_detalle[i].* TO r_detalle[j].*
			DISPLAY r_detalle[i].m13_comentario TO tit_coment	
		BEFORE INSERT
			LET i = arr_curr()
			LET j = scr_line()
			IF r_detalle[i].m13_fecha IS NULL THEN
				LET r_detalle[i].m13_fecha = TODAY
			END IF
			DISPLAY r_detalle[i].* TO r_detalle[j].*
		AFTER INPUT
			LET vm_num_det = arr_curr()
	END INPUT

	IF int_flag THEN
		LET int_flag = 0
		CLOSE WINDOW w_log
		RETURN
	END IF
	
	DELETE FROM maqt013 WHERE m13_compania  = rm_m11.m11_compania
	                      AND m13_modelo    = rm_m11.m11_modelo
	                      AND m13_secuencia = rm_m11.m11_secuencia

	FOR i = 1 TO vm_num_det
		INSERT INTO maqt013 VALUES (rm_m11.m11_compania,
					    rm_m11.m11_modelo,
					    rm_m11.m11_secuencia,
					    r_detalle[i].m13_fecha,
					    i,
					    r_detalle[i].m13_comentario)	
	END FOR

LET int_flag = 0
CLOSE WINDOW w_log

END FUNCTION



FUNCTION mostrar_bitacora()

DEFINE i 		SMALLINT

CALL cargar_datos_log()

OPEN WINDOW w_log1 AT 7,4 WITH FORM "../forms/maqf200_3"
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER, MENU LINE 0)

DISPLAY 'Fecha'      TO tit_col1
DISPLAY 'Comentario' TO tit_col2

	CALL set_count(vm_num_det)
	DISPLAY ARRAY r_detalle TO r_detalle.*
		BEFORE ROW
			LET i = arr_curr()
			DISPLAY r_detalle[i].m13_comentario TO tit_coment	
	END DISPLAY

LET int_flag = 0
CLOSE WINDOW w_log1

END FUNCTION



FUNCTION cargar_datos_log()

DEFINE r_m13		RECORD LIKE maqt013.*
	
DECLARE q_log CURSOR FOR 
	SELECT * FROM maqt013 WHERE m13_compania  = rm_m11.m11_compania
				AND m13_modelo    = rm_m11.m11_modelo
 				AND m13_secuencia = rm_m11.m11_secuencia 
		ORDER BY 1, 2, 3, 4, 5

LET vm_num_det = 1
FOREACH q_log INTO r_m13.*
	LET r_detalle[vm_num_det].m13_fecha      = r_m13.m13_fecha	
	LET r_detalle[vm_num_det].m13_comentario = r_m13.m13_comentario	

	LET vm_num_det = vm_num_det + 1 
	IF vm_num_det > vm_max_det THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_det = vm_num_det - 1

END FUNCTION



FUNCTION calcula_sgte_revision()

DEFINE r_m12		RECORD LIKE maqt012.*
DEFINE p_vez		CHAR(1)
DEFINE fecha_ant	DATE
DEFINE dias		INTEGER
DEFINE veces		SMALLINT

DECLARE q_aprox CURSOR FOR
	SELECT * FROM maqt012
	 WHERE m12_compania  = rm_m11.m11_compania
	   AND m12_modelo    = rm_m11.m11_modelo 
	   AND m12_secuencia = rm_m11.m11_secuencia

INITIALIZE fecha_ant TO NULL

LET dias = 0
LET veces = 0
LET p_vez = 'S'
FOREACH q_aprox INTO r_m12.*
	IF p_vez = 'S' THEN
		LET fecha_ant = r_m12.m12_fecha 
		LET p_vez = 'N'
		CONTINUE FOREACH
	END IF
	LET veces = veces + 1
	LET dias = dias + (r_m12.m12_fecha - fecha_ant)
	LET fecha_ant = r_m12.m12_fecha
END FOREACH

IF fecha_ant IS NOT NULL THEN
	LET veces = veces + 1
	LET dias = dias + (rm_m12.m12_fecha - fecha_ant)
	LET fecha_ant = rm_m12.m12_fecha
END IF

IF dias = 0 THEN
	LET dias = 30
ELSE
	LET dias = dias / veces
END IF

LET rm_m11.m11_fecha_sgte_rev = rm_m12.m12_fecha + dias

END FUNCTION



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe m�dulo: ' || vg_modulo, 
                            'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compa��a: '|| vg_codcia, 
                            'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compa��a no est� activa: ' || 
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
	CALL fgl_winmessage(vg_producto, 'Localidad no est� activa: ' || 
                            vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
