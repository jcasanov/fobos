------------------------------------------------------------------------------
-- Titulo           : genp108.4gl - Mantenimiento de Tarjetas de Crédito
-- Elaboracion      : 27-ago-2001
-- Autor            : JCM 
-- Formato Ejecucion: fglrun genp108 base modulo
-- Ultima Correccion: 27-ago-2001
-- Motivo Correccion:  
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_rows		ARRAY[1000] OF INTEGER -- ARREGLO ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS
DEFINE rm_g10		RECORD LIKE gent010.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/genp108.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parametros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'genp108'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_rows = 1000
OPEN WINDOW w_genf108_1 AT 3, 2 WITH 15 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0, BORDER,
			MESSAGE LINE LAST - 1)
OPEN FORM f_genf108_1 FROM '../forms/genf108_1'
DISPLAY FORM f_genf108_1
INITIALIZE rm_g10.* TO NULL
LET vm_num_rows    = 0
LET vm_row_current = 0
CALL muestra_contadores()
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Bloquear/Activar'
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registos'
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
	COMMAND KEY('M') 'Modificar' 		'Modificar registro corriente'
		CALL control_modificacion()
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro'
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
        COMMAND KEY('E') 'Bloquear/Activar' 'Bloquear o activar registro. '
                CALL control_bloqueo_activacion()
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro'
		CALL siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder'  		'Ver anterior registro'
		CALL anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('S') 'Salir' 		'Salir del programa'
		EXIT MENU
END MENU

END FUNCTION
 


FUNCTION control_ingreso()
DEFINE r_g10		RECORD LIKE gent010.*

CLEAR FORM
INITIALIZE rm_g10.* TO NULL
LET rm_g10.g10_compania  = vg_codcia
LET rm_g10.g10_estado    = 'A'
LET rm_g10.g10_cont_cred = 'C'
LET rm_g10.g10_fecing    = fl_current()
LET rm_g10.g10_usuario   = vg_usuario 
DISPLAY BY NAME rm_g10.g10_estado, rm_g10.g10_fecing, rm_g10.g10_usuario
DISPLAY 'ACTIVO' TO tit_estado
CALL lee_datos('I')
IF int_flag THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF
WHILE TRUE
	SQL
		SELECT NVL(MAX(g10_tarjeta), 0) + 1
			INTO $rm_g10.g10_tarjeta
			FROM gent010
			WHERE g10_compania = $vg_codcia
	END SQL
	INITIALIZE r_g10.* TO NULL
	DECLARE q_veri CURSOR FOR
		SELECT * FROM gent010
			WHERE g10_compania = vg_codcia
			  AND g10_tarjeta  = rm_g10.g10_tarjeta
	OPEN q_veri
	FETCH q_veri INTO r_g10.*
	CLOSE q_veri
	FREE q_veri
	IF r_g10.g10_compania IS NULL THEN
		EXIT WHILE
	END IF
END WHILE
LET rm_g10.g10_fecing  = fl_current()
INSERT INTO gent010 VALUES (rm_g10.*)
DISPLAY BY NAME rm_g10.g10_tarjeta
IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF
LET vm_rows[vm_num_rows] = SQLCA.SQLERRD[6]
LET vm_row_current       = vm_num_rows
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL muestra_contadores()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_modificacion()

IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])
IF rm_g10.g10_estado = 'B' THEN
	CALL fl_mostrar_mensaje('No puede modificar una tarjeta Bloqueada.', 'exclamation')
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_upd CURSOR FOR
	SELECT * FROM gent010
		WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_upd
FETCH q_upd INTO rm_g10.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF  
WHENEVER ERROR STOP
CALL lee_datos('M')
IF int_flag THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	RETURN
END IF 
UPDATE gent010
	SET * = rm_g10.*
	WHERE CURRENT OF q_upd
COMMIT WORK
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mensaje_registro_modificado()

END FUNCTION

 

FUNCTION control_consulta()
DEFINE r_j01		RECORD LIKE cajt001.*
DEFINE r_cligen		RECORD LIKE cxct001.*
DEFINE r_tarjeta	RECORD LIKE gent010.*
DEFINE codigo		LIKE gent010.g10_tarjeta
DEFINE nom_tarjeta	LIKE gent010.g10_nombre
DEFINE cod_cobranzas	LIKE cxct001.z01_codcli
DEFINE nom_cliente	LIKE cxct001.z01_nomcli
DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(1200)

CLEAR FORM
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON g10_estado, g10_tarjeta, g10_nombre, g10_codcobr,
	g10_cod_tarj, g10_cont_cred, g10_usuario, g10_fecing
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT CONSTRUCT
	ON KEY(F2)
		IF INFIELD(g10_tarjeta) THEN
			CALL fl_ayuda_tarjeta(vg_codcia, 'T', 'T')
				RETURNING codigo, nom_tarjeta
			IF codigo IS NOT NULL THEN
				LET rm_g10.g10_tarjeta = codigo
				LET rm_g10.g10_nombre  = nom_tarjeta
				DISPLAY BY NAME rm_g10.g10_tarjeta,
						rm_g10.g10_nombre
			END IF
		END IF
		IF INFIELD(g10_codcobr) THEN
			CALL fl_ayuda_cliente_general()
				RETURNING cod_cobranzas, nom_cliente
			IF cod_cobranzas IS NOT NULL THEN
				LET rm_g10.g10_codcobr = cod_cobranzas
				DISPLAY BY NAME rm_g10.g10_codcobr,
						nom_cliente
			END IF
		END IF
		IF INFIELD(g10_cod_tarj) THEN
			CALL fl_ayuda_forma_pago(vg_codcia, 'T', 'A', 'N')
				RETURNING r_j01.j01_codigo_pago,
						r_j01.j01_nombre,
						r_j01.j01_cont_cred
			IF r_j01.j01_codigo_pago IS NOT NULL THEN
				LET rm_g10.g10_cod_tarj  = r_j01.j01_codigo_pago
				LET rm_g10.g10_cont_cred = r_j01.j01_cont_cred
				DISPLAY BY NAME rm_g10.g10_cod_tarj,
						r_j01.j01_nombre,
						rm_g10.g10_cont_cred
			END IF
		END IF
		LET int_flag = 0
	AFTER FIELD g10_tarjeta
		LET rm_g10.g10_tarjeta = GET_FLDBUF(g10_tarjeta)
		IF rm_g10.g10_tarjeta IS NULL THEN
			DISPLAY '' TO g10_nombre
		ELSE
			CALL fl_lee_tarjeta_credito(vg_codcia,
							rm_g10.g10_tarjeta,
							rm_g10.g10_cod_tarj,
							rm_g10.g10_cont_cred)
				RETURNING r_tarjeta.*
			IF r_tarjeta.g10_tarjeta IS NULL THEN
				DISPLAY '' TO g10_nombre
			END IF
			DISPLAY r_tarjeta.g10_nombre TO g10_nombre
		END IF
	AFTER FIELD g10_codcobr
		LET rm_g10.g10_codcobr = GET_FLDBUF(g10_codcobr)
		IF rm_g10.g10_codcobr IS NULL THEN
			CLEAR nom_cliente
		ELSE
			CALL fl_lee_cliente_general(rm_g10.g10_codcobr)
				RETURNING r_cligen.*
			IF r_cligen.z01_codcli IS NULL THEN
				CLEAR nom_cliente
			END IF
			IF r_cligen.z01_estado = 'B' THEN
				CLEAR nom_cliente
				NEXT FIELD g10_codcobr
			END IF
			DISPLAY r_cligen.z01_nomcli TO nom_cliente
		END IF
END CONSTRUCT
IF int_flag THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	CALL muestra_contadores()
	RETURN
END IF
LET query = 'SELECT *, ROWID FROM gent010 ',
		' WHERE g10_compania  = ', vg_codcia,
		'   AND ', expr_sql CLIPPED,
		' ORDER BY g10_tarjeta'
PREPARE cons FROM query
DECLARE q_tarj CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_tarj INTO rm_g10.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
	IF vm_num_rows > vm_max_rows THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
      	LET vm_row_current = 0
	LET vm_num_rows    = 0
  	CALL muestra_contadores()
      	CLEAR FORM
      	RETURN
END IF
LET vm_row_current = 1
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL muestra_contadores()

END FUNCTION



FUNCTION control_bloqueo_activacion()
DEFINE resp		CHAR(6)
DEFINE i		SMALLINT
DEFINE mensaje		VARCHAR(20)
DEFINE estado		CHAR(1)

IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])
LET mensaje = 'Seguro de bloquear'
IF rm_g10.g10_estado <> 'A' THEN
        LET mensaje = 'Seguro de activar'
END IF
CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
IF resp <> 'Yes' THEN
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_del CURSOR FOR
	SELECT * FROM gent010
		WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_del
FETCH q_del INTO rm_g10.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
LET estado = 'B'
IF rm_g10.g10_estado <> 'A' THEN
	LET estado = 'A'
END IF
UPDATE gent010
	SET g10_estado = estado
	WHERE CURRENT OF q_del
COMMIT WORK
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL muestra_contadores()
CALL fl_mensaje_registro_modificado()
                                                                                
END FUNCTION



FUNCTION lee_datos(flag)
DEFINE flag   		CHAR(1)
DEFINE resp   		CHAR(6)
DEFINE cod_cobranzas	LIKE cxct001.z01_codcli
DEFINE nom_cliente	LIKE cxct001.z01_nomcli
DEFINE r_j01		RECORD LIKE cajt001.*
DEFINE r_cligen 	RECORD LIKE cxct001.*
DEFINE r_g10		RECORD LIKE gent010.*

LET int_flag = 0 
INPUT BY NAME rm_g10.g10_nombre, rm_g10.g10_codcobr, rm_g10.g10_cod_tarj,
	rm_g10.g10_cont_cred
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_g10.g10_nombre, rm_g10.g10_codcobr,
				 rm_g10.g10_cod_tarj, rm_g10.g10_cont_cred)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				EXIT INPUT
			END IF
		ELSE
			EXIT INPUT
		END IF
	ON KEY(F2)
		IF INFIELD(g10_codcobr) THEN
			CALL fl_ayuda_cliente_general()
				RETURNING cod_cobranzas, nom_cliente
			IF cod_cobranzas IS NOT NULL THEN
				LET rm_g10.g10_codcobr = cod_cobranzas
				DISPLAY BY NAME rm_g10.g10_codcobr,
						nom_cliente
			END IF
		END IF
		IF INFIELD(g10_cod_tarj) THEN
			CALL fl_ayuda_forma_pago(vg_codcia, 'T', 'A', 'N')
				RETURNING r_j01.j01_codigo_pago,
						r_j01.j01_nombre,
						r_j01.j01_cont_cred
			IF r_j01.j01_codigo_pago IS NOT NULL THEN
				LET rm_g10.g10_cod_tarj  = r_j01.j01_codigo_pago
				LET rm_g10.g10_cont_cred = r_j01.j01_cont_cred
				DISPLAY BY NAME rm_g10.g10_cod_tarj,
						r_j01.j01_nombre,
						rm_g10.g10_cont_cred
			END IF
		END IF
		LET int_flag = 0
	AFTER FIELD g10_codcobr
		IF rm_g10.g10_codcobr IS NULL THEN
			CLEAR nom_cliente
		ELSE
			CALL fl_lee_cliente_general(rm_g10.g10_codcobr)
				RETURNING r_cligen.*
			IF r_cligen.z01_codcli IS NULL THEN
				CALL fl_mostrar_mensaje('No existe un cliente con ese código.', 'exclamation')
				NEXT FIELD g10_codcobr
			END IF
			IF r_cligen.z01_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD g10_codcobr
			END IF
			LET rm_g10.g10_codcobr = r_cligen.z01_codcli
			DISPLAY r_cligen.z01_nomcli TO nom_cliente
		END IF
	AFTER FIELD g10_cod_tarj
		IF rm_g10.g10_cod_tarj IS NOT NULL THEN
			CALL fl_lee_tipo_pago_caja(vg_codcia,
							rm_g10.g10_cod_tarj,
							rm_g10.g10_cont_cred)
				RETURNING r_j01.*
			IF r_j01.j01_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe tipo de forma de pago.', 'exclamation')
				NEXT FIELD g10_cod_tarj
			END IF
			IF r_j01.j01_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD g10_cod_tarj
			END IF
			IF r_j01.j01_retencion = 'S' THEN
				CALL fl_mostrar_mensaje('Este tipo de forma de pago es de Retencion.', 'exclamation')
				NEXT FIELD g10_cod_tarj
			END IF
			LET rm_g10.g10_cont_cred = r_j01.j01_cont_cred
			DISPLAY BY NAME r_j01.j01_nombre, rm_g10.g10_cont_cred
		ELSE
			CLEAR j01_nombre
		END IF
	AFTER INPUT
		CALL fl_lee_tipo_pago_caja(vg_codcia, rm_g10.g10_cod_tarj,
						rm_g10.g10_cont_cred)
			RETURNING r_j01.*
		IF r_j01.j01_compania IS NULL THEN
			CALL fl_mostrar_mensaje('Digite un tipo de forma de pago valido (Contado/Crédito).', 'exclamation')
			CONTINUE INPUT
		END IF
		IF flag = 'M' THEN
			EXIT INPUT
		END IF
		INITIALIZE r_g10.* TO NULL
		DECLARE q_g10 CURSOR FOR
			SELECT * FROM gent010
				WHERE g10_compania  = vg_codcia
				  AND g10_cod_tarj  = rm_g10.g10_cod_tarj
				  AND g10_cont_cred = rm_g10.g10_cont_cred
				  AND g10_codcobr   = rm_g10.g10_codcobr
		OPEN q_g10
		FETCH q_g10 INTO r_g10.*
		CLOSE q_g10
		FREE q_g10
		IF r_g10.g10_compania IS NOT NULL THEN
			CALL fl_mostrar_mensaje('Ya existe ingresada esta tarjeta de crédito.', 'exclamation')
			CONTINUE INPUT
		END IF
END INPUT

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER
DEFINE r_j01		RECORD LIKE cajt001.*
DEFINE r_cligen		RECORD LIKE cxct001.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_g10.* FROM gent010 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
DISPLAY BY NAME rm_g10.g10_estado, rm_g10.g10_tarjeta, rm_g10.g10_nombre,
		rm_g10.g10_codcobr, rm_g10.g10_cod_tarj, rm_g10.g10_cont_cred,
		rm_g10.g10_usuario, rm_g10.g10_fecing
CALL fl_lee_cliente_general(rm_g10.g10_codcobr) RETURNING r_cligen.*
CALL fl_lee_tipo_pago_caja(vg_codcia, rm_g10.g10_cod_tarj, rm_g10.g10_cont_cred)
	RETURNING r_j01.*
DISPLAY r_cligen.z01_nomcli TO nom_cliente
DISPLAY BY NAME r_j01.j01_nombre
CALL muestra_contadores()
IF rm_g10.g10_estado = 'A' THEN
	DISPLAY 'ACTIVO' TO tit_estado
ELSE
	DISPLAY 'BLOQUEADO' TO tit_estado
END IF

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



FUNCTION muestra_contadores() 

DISPLAY '' AT 1, 1
DISPLAY vm_row_current, ' de ', vm_num_rows AT 1, 67

END FUNCTION
