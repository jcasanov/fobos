--------------------------------------------------------------------------------
-- Titulo           : talp217.4gl - Registro Técnico de Equipos
-- Elaboracion      : 24-oct-2013
-- Autor            : NPC
-- Formato Ejecucion: fglrun talp217 base modulo compania localidad [num_reg]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_rows		ARRAY[10000] OF INTEGER
DEFINE vm_row_current	SMALLINT
DEFINE vm_num_rows	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_num_det	SMALLINT
DEFINE vm_max_det	SMALLINT
DEFINE vm_size_arr	SMALLINT
DEFINE vm_lin_pag	SMALLINT
DEFINE rm_regtec	ARRAY[600] OF RECORD
				t35_item	LIKE talt035.t35_item,
				r10_marca	LIKE rept010.r10_marca,
				t35_serie	LIKE talt035.t35_serie,
				t35_desc_prueb	LIKE talt035.t35_desc_prueb,
				t35_tecnico	LIKE talt035.t35_tecnico,
				t35_observacion	LIKE talt035.t35_observacion
			END RECORD
DEFINE rm_t34		RECORD LIKE talt034.*
DEFINE rm_t35		RECORD LIKE talt035.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp217.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 THEN	-- Validar # parametros correcto
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'talp217'
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
IF num_args() = 4 THEN
	CALL fl_chequeo_mes_proceso_tal(vg_codcia) RETURNING int_flag 
	IF int_flag THEN
		RETURN
	END IF
END IF
LET vm_max_rows = 10000
LET vm_max_det  = 600
LET lin_menu    = 0
LET row_ini     = 3
LET num_rows    = 22
LET num_cols    = 80
IF vg_gui = 0 THEN        
	LET lin_menu = 1
	LET row_ini  = 2
	LET num_rows = 22
	LET num_cols = 78
END IF                  
OPEN WINDOW w_talp217_1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,   
		  BORDER, MESSAGE LINE LAST - 1)                                
IF vg_gui = 1 THEN
	OPEN FORM f_talf217_1 FROM '../forms/talf217_1'
ELSE
	OPEN FORM f_talf217_1 FROM '../forms/talf217_1c'
END IF
DISPLAY FORM f_talf217_1
CALL control_mostrar_botones()
LET vm_num_rows    = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU	
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Cerrar'
		HIDE OPTION 'Eliminar'
		HIDE OPTION 'Ver Detalle'
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
                HIDE OPTION 'Imprimir'
		IF num_args() = 5 THEN
			HIDE OPTION 'Consultar'
			HIDE OPTION 'Ingresar'
                	HIDE OPTION 'Imprimir'
			HIDE OPTION 'Ver Detalle'
			CALL control_consulta()
			CALL control_ver_detalle()
			EXIT MENU
		END IF
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		HIDE OPTION 'Imprimir'
		CALL control_ingreso()
                IF vm_num_rows <= 1 THEN
                        HIDE OPTION 'Avanzar'
                        HIDE OPTION 'Retroceder'
			IF vm_num_rows = 1 THEN
				IF rm_t34.t34_estado = 'A' OR
				   rm_t34.t34_estado = 'P'
				THEN
					SHOW OPTION 'Modificar'
					SHOW OPTION 'Eliminar'
					SHOW OPTION 'Cerrar'
				ELSE
					HIDE OPTION 'Modificar'
					IF rm_t34.t34_estado = 'C' AND
					   rm_t34.t34_fecha = TODAY
					THEN
						SHOW OPTION 'Eliminar'
					ELSE
						HIDE OPTION 'Eliminar'
					END IF
					HIDE OPTION 'Cerrar'
				END IF
				IF vm_num_det > 0 THEN
					SHOW OPTION 'Ver Detalle'
				ELSE
					HIDE OPTION 'Ver Detalle'
				END IF
			END IF 
                ELSE
			IF rm_t34.t34_estado = 'A' OR
			   rm_t34.t34_estado = 'P'
			THEN
				SHOW OPTION 'Modificar'
				SHOW OPTION 'Eliminar'
				SHOW OPTION 'Cerrar'
			ELSE
				HIDE OPTION 'Modificar'
				IF rm_t34.t34_estado = 'C' AND
				   rm_t34.t34_fecha = TODAY
				THEN
					SHOW OPTION 'Eliminar'
				ELSE
					HIDE OPTION 'Eliminar'
				END IF
				HIDE OPTION 'Cerrar'
			END IF
			IF vm_num_det > 0 THEN
				SHOW OPTION 'Ver Detalle'
			ELSE
				HIDE OPTION 'Ver Detalle'
			END IF
			SHOW OPTION 'Retroceder'
                END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
		END IF
		IF rm_t34.t34_estado = 'E' THEN
			HIDE OPTION 'Imprimir'
		END IF
        COMMAND KEY('M') 'Modificar'	'Modifica un Control Ruta Activo.'
		CALL control_modificacion()
        COMMAND KEY('C') 'Consultar'    'Consultar un registro.'
		HIDE OPTION 'Imprimir'
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
                        HIDE OPTION 'Avanzar'
                        HIDE OPTION 'Retroceder'
			IF vm_num_rows = 1 THEN
				IF rm_t34.t34_estado = 'A' OR
				   rm_t34.t34_estado = 'P'
				THEN
					SHOW OPTION 'Cerrar'
					SHOW OPTION 'Eliminar'
					SHOW OPTION 'Modificar'
				ELSE
					HIDE OPTION 'Cerrar'
					IF rm_t34.t34_estado = 'C' AND
					   rm_t34.t34_fecha = TODAY
					THEN
						SHOW OPTION 'Eliminar'
					ELSE
						HIDE OPTION 'Eliminar'
					END IF
					HIDE OPTION 'Modificar'
				END IF
				IF vm_num_det > 0 THEN
					SHOW OPTION 'Ver Detalle'
				ELSE
					HIDE OPTION 'Ver Detalle'
				END IF
			END IF 
                ELSE
			IF rm_t34.t34_estado = 'A' OR
			   rm_t34.t34_estado = 'P'
			THEN
				SHOW OPTION 'Modificar'
				SHOW OPTION 'Eliminar'
				SHOW OPTION 'Cerrar'
			ELSE
				HIDE OPTION 'Modificar'
				IF rm_t34.t34_estado = 'C' AND
				   rm_t34.t34_fecha = TODAY
				THEN
					SHOW OPTION 'Eliminar'
				ELSE
					HIDE OPTION 'Eliminar'
				END IF
				HIDE OPTION 'Cerrar'
			END IF
			IF vm_num_det > 0 THEN
				SHOW OPTION 'Ver Detalle'
			ELSE
				HIDE OPTION 'Ver Detalle'
			END IF
                        SHOW OPTION 'Avanzar'
                END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
		END IF
		IF rm_t34.t34_estado = 'E' THEN
			HIDE OPTION 'Imprimir'
		END IF
        COMMAND KEY('P') 'Cerrar'	'Cierra un Control Ruta Activo.'
		CALL control_cierre()
		IF rm_t34.t34_estado = 'A' OR rm_t34.t34_estado = 'P' THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Eliminar'
			SHOW OPTION 'Cerrar'
		ELSE
			HIDE OPTION 'Modificar'
			IF rm_t34.t34_estado = 'C' AND
			   rm_t34.t34_fecha = TODAY
			THEN
				SHOW OPTION 'Eliminar'
			ELSE
				HIDE OPTION 'Eliminar'
			END IF
			HIDE OPTION 'Cerrar'
		END IF
        COMMAND KEY('E') 'Eliminar'	'Elimina un Control Ruta Activo.'
		CALL control_eliminacion()
		IF rm_t34.t34_estado = 'A' OR rm_t34.t34_estado = 'P' THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Eliminar'
			SHOW OPTION 'Cerrar'
		ELSE
			HIDE OPTION 'Modificar'
			IF rm_t34.t34_estado = 'C' AND
			   rm_t34.t34_fecha = TODAY
			THEN
				SHOW OPTION 'Eliminar'
			ELSE
				HIDE OPTION 'Eliminar'
			END IF
			HIDE OPTION 'Cerrar'
		END IF
		IF rm_t34.t34_estado = 'E' THEN
			HIDE OPTION 'Imprimir'
		ELSE
			SHOW OPTION 'Imprimir'
		END IF
	COMMAND KEY('V') 'Ver Detalle'	'Ver Detalle de la Transacción.'
		IF vm_num_rows > 0 THEN
			CALL control_ver_detalle()
		ELSE 
			CALL fl_mensaje_consultar_primero()
		END IF 
        COMMAND KEY('W') 'Imprimir'	'Imprime Devolución/Anulación.'
		CALL control_imprimir()
	COMMAND KEY('A') 'Avanzar' 	'Ver siguiente registro.'
		CALL siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			IF rm_t34.t34_estado = 'A' OR
			   rm_t34.t34_estado = 'P'
			THEN
				SHOW OPTION 'Modificar'
				SHOW OPTION 'Eliminar'
				SHOW OPTION 'Cerrar'
			ELSE
				HIDE OPTION 'Modificar'
				IF rm_t34.t34_estado = 'C' AND
				   rm_t34.t34_fecha = TODAY
				THEN
					SHOW OPTION 'Eliminar'
				ELSE
					HIDE OPTION 'Eliminar'
				END IF
				HIDE OPTION 'Cerrar'
			END IF
			IF vm_num_det > 0 THEN
				SHOW OPTION 'Ver Detalle'
			ELSE
				HIDE OPTION 'Ver Detalle'
			END IF
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			IF rm_t34.t34_estado = 'A' OR
			   rm_t34.t34_estado = 'P'
			THEN
				SHOW OPTION 'Modificar'
				SHOW OPTION 'Eliminar'
				SHOW OPTION 'Cerrar'
			ELSE
				HIDE OPTION 'Modificar'
				IF rm_t34.t34_estado = 'C' AND
				   rm_t34.t34_fecha = TODAY
				THEN
					SHOW OPTION 'Eliminar'
				ELSE
					HIDE OPTION 'Eliminar'
				END IF
				HIDE OPTION 'Cerrar'
			END IF
			IF vm_num_det > 0 THEN
				SHOW OPTION 'Ver Detalle'
			ELSE
				HIDE OPTION 'Ver Detalle'
			END IF
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
		END IF
		IF rm_t34.t34_estado = 'E' THEN
			HIDE OPTION 'Imprimir'
		ELSE
			SHOW OPTION 'Imprimir'
		END IF
	COMMAND KEY('R') 'Retroceder' 	'Ver anterior registro.'
		CALL anterior_registro()
		IF vm_row_current = 1 THEN
			IF rm_t34.t34_estado = 'A' OR
			   rm_t34.t34_estado = 'P'
			THEN
				SHOW OPTION 'Modificar'
				SHOW OPTION 'Eliminar'
				SHOW OPTION 'Cerrar'
			ELSE
				HIDE OPTION 'Modificar'
				IF rm_t34.t34_estado = 'C' AND
				   rm_t34.t34_fecha = TODAY
				THEN
					SHOW OPTION 'Eliminar'
				ELSE
					HIDE OPTION 'Eliminar'
				END IF
				HIDE OPTION 'Cerrar'
			END IF
			IF vm_num_det > 0 THEN
				SHOW OPTION 'Ver Detalle'
			ELSE
				HIDE OPTION 'Ver Detalle'
			END IF
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			IF rm_t34.t34_estado = 'A' OR
			   rm_t34.t34_estado = 'P'
			THEN
				SHOW OPTION 'Modificar'
				SHOW OPTION 'Eliminar'
				SHOW OPTION 'Cerrar'
			ELSE
				HIDE OPTION 'Modificar'
				IF rm_t34.t34_estado = 'C' AND
				   rm_t34.t34_fecha = TODAY
				THEN
					SHOW OPTION 'Eliminar'
				ELSE
					HIDE OPTION 'Eliminar'
				END IF
				HIDE OPTION 'Cerrar'
			END IF
			IF vm_num_det > 0 THEN
				SHOW OPTION 'Ver Detalle'
			ELSE
				HIDE OPTION 'Ver Detalle'
			END IF
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
		END IF
		IF rm_t34.t34_estado = 'E' THEN
			HIDE OPTION 'Imprimir'
		ELSE
			SHOW OPTION 'Imprimir'
		END IF
	COMMAND KEY('S') 'Salir'    	'Salir del programa.'
		EXIT MENU
END MENU
CLOSE WINDOW w_talp217_1
EXIT PROGRAM

END FUNCTION



FUNCTION control_mostrar_botones()

--#DISPLAY "Cód."		TO tit_col1
--#DISPLAY "Marca"		TO tit_col2
--#DISPLAY "Serie"		TO tit_col3
--#DISPLAY "Prueba"		TO tit_col4
--#DISPLAY "Téc."		TO tit_col5
--#DISPLAY "Observación"	TO tit_col6

END FUNCTION



FUNCTION muestra_contadores(num_reg, max_reg)
DEFINE num_reg, max_reg	SMALLINT

DISPLAY BY NAME num_reg, max_reg

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i		SMALLINT

LET vm_num_det  = 0
LET vm_size_arr = fgl_scr_size('rm_regtec')
FOR i = 1 TO vm_size_arr
	CLEAR rm_regtec[i].*
END FOR
FOR i = 1 TO vm_max_det
	INITIALIZE rm_regtec[i].* TO NULL
END FOR

END FUNCTION



FUNCTION control_ingreso()
DEFINE num_aux		INTEGER
DEFINE mensaje		VARCHAR(100)

CLEAR FORM
CALL control_mostrar_botones()
INITIALIZE rm_t34.*, rm_t35.* TO NULL
CALL borrar_detalle()
LET rm_t34.t34_compania  = vg_codcia
LET rm_t34.t34_localidad = vg_codloc
LET rm_t34.t34_estado    = "A"
LET rm_t34.t34_fecha     = TODAY
LET rm_t34.t34_usuario   = vg_usuario
LET rm_t34.t34_fecing    = CURRENT
DISPLAY BY NAME rm_t34.t34_fecha, rm_t34.t34_usuario, rm_t34.t34_fecing
CALL muestra_estado()
CALL lee_cabecera('I')
IF int_flag THEN
	CALL muestra_salir()
	RETURN
END IF
CALL lee_detalle('I')
IF int_flag THEN
	CALL muestra_salir()
	RETURN
END IF
BEGIN WORK
WHILE TRUE
	SELECT NVL(MAX(t34_num_reg) + 1, 1)
		INTO rm_t34.t34_num_reg
		FROM talt034
		WHERE t34_compania  = rm_t34.t34_compania
		  AND t34_localidad = rm_t34.t34_localidad
	LET rm_t34.t34_fecing = CURRENT
	WHENEVER ERROR CONTINUE
	INSERT INTO talt034 VALUES (rm_t34.*)
	IF STATUS = 0 THEN
		LET num_aux = SQLCA.SQLERRD[6]
		WHENEVER ERROR STOP
		EXIT WHILE
	END IF
END WHILE
CALL grabar_detalle()
COMMIT WORK
IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows  = 1
ELSE
	LET vm_num_rows  = vm_num_rows + 1
END IF
LET vm_row_current       = vm_num_rows
LET vm_rows[vm_num_rows] = num_aux
CALL lee_muestra_registro(vm_rows[vm_row_current])
LET mensaje = 'Se generó Registro Técnico No. ',
		rm_t34.t34_num_reg USING "<<<<<<<&", '.'
CALL fl_mostrar_mensaje(mensaje, 'info')

END FUNCTION



FUNCTION control_modificacion()

CALL lee_muestra_registro(vm_rows[vm_row_current])
IF rm_t34.t34_estado <> 'A' THEN
	CALL fl_mostrar_mensaje('Solo se pueden modificar un registro técnico que esten con estado ACTIVO.', 'exclamation')
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_modif CURSOR FOR
	SELECT * FROM talt034
		WHERE t34_compania  = rm_t34.t34_compania
		  AND t34_localidad = rm_t34.t34_localidad
		  AND t34_num_ot    = rm_t34.t34_num_ot
		  AND t34_num_reg   = rm_t34.t34_num_reg
		FOR UPDATE
OPEN q_modif
FETCH q_modif INTO rm_t34.*
IF STATUS <> 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
IF STATUS = NOTFOUND THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No existe el registro de este registro técnico. Por favor LLAME AL ADMINISTRADOR.', 'stop')
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
CALL lee_cabecera('M')
IF int_flag THEN
	ROLLBACK WORK
	CALL muestra_salir()
	WHENEVER ERROR STOP
	RETURN
END IF
CALL lee_detalle('M')
IF int_flag THEN
	ROLLBACK WORK
	CALL muestra_salir()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR CONTINUE
UPDATE talt034
	SET * = rm_t34.*
	WHERE CURRENT OF q_modif
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No se pudo MODIFICAR la cabecera del registro técnico. Por favor LLAME AL ADMINISTRADOR.', 'stop')
	WHENEVER ERROR STOP
	RETURN
END IF
DELETE FROM talt035
	WHERE t35_compania  = rm_t34.t34_compania
	  AND t35_localidad = rm_t34.t34_localidad
	  AND t35_num_ot    = rm_t34.t34_num_ot
	  AND t35_num_reg   = rm_t34.t34_num_reg
WHENEVER ERROR CONTINUE
CALL grabar_detalle()
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No se pudo MODIFICAR el detalle del registro técnico. Por favor LLAME AL ADMINISTRADOR.', 'stop')
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
COMMIT WORK
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mostrar_mensaje('El Registro Técnico ha sido modificado OK.', 'info')

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		CHAR(1800)
DEFINE query		CHAR(3500)
DEFINE r_t23		RECORD LIKE talt023.*

CLEAR FORM
INITIALIZE rm_t34.*, r_t23.* TO NULL
CALL control_mostrar_botones()
IF num_args() = 4 THEN
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON t34_num_reg, t34_fecha, t34_estado,
		t34_num_fact, t34_referencia, t34_usuario, t34_fecing
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT CONSTRUCT
	ON KEY(F2)
		IF INFIELD(t34_num_fact) THEN
			CALL fl_ayuda_facturas_tal(vg_codcia, vg_codloc, 'T')
				RETURNING r_t23.t23_num_factura,
					r_t23.t23_nom_cliente
			IF r_t23.t23_num_factura IS NOT NULL THEN
				DISPLAY r_t23.t23_num_factura TO t34_num_fact
			END IF
		END IF
		LET int_flag = 0
	AFTER FIELD t34_num_fact
		LET rm_t34.t34_num_fact = GET_FLDBUF(t34_num_fact)
		IF rm_t34.t34_num_fact IS NOT NULL THEN
			CALL fl_lee_factura_taller(vg_codcia, vg_codloc,
						rm_t34.t34_num_fact)
				RETURNING r_t23.*
			IF r_t23.t23_compania IS NULL THEN
				CALL fl_mostrar_mensaje('La factura no existe.','exclamation')
				NEXT FIELD t34_num_fact
			END IF
			LET rm_t34.t34_num_fact = r_t23.t23_num_factura
			DISPLAY BY NAME	rm_t34.t34_num_fact
		ELSE
			INITIALIZE r_t23.* TO NULL
		END IF
	END CONSTRUCT
	IF int_flag THEN
		CALL muestra_salir()
		RETURN
	END IF
ELSE
	LET expr_sql = ' t34_num_reg = ', arg_val(5)
END IF
LET query = 'SELECT *, ROWID FROM talt034 ',
		' WHERE t34_compania  = ', vg_codcia,
		'   AND t34_localidad = ', vg_codloc,
		'   AND ', expr_sql CLIPPED,
		' ORDER BY 4 ' 
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_t34.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
		EXIT FOREACH
	END IF	
END FOREACH 
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN 
	CALL fl_mensaje_consulta_sin_registros()
	IF num_args() = 5 THEN
		CLOSE WINDOW w_talp217_1
		EXIT PROGRAM
	END IF
	LET vm_num_rows    = 0
	LET vm_row_current = 0
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CLEAR FORM
	CALL control_mostrar_botones()
	RETURN
END IF
LET vm_row_current = 1
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION control_cierre()
DEFINE resp		CHAR(6)
DEFINE i, encontro	SMALLINT
DEFINE mens		VARCHAR(250)

CALL lee_muestra_registro(vm_rows[vm_row_current])
IF rm_t34.t34_estado <> 'A' THEN
	CALL fl_mostrar_mensaje('Solo se puede cerrar un registro técnico que esten con estado ACTIVO.', 'exclamation')
	RETURN
END IF
{--
LET encontro = 0
FOR i = 1 TO vm_num_det
	IF rm_regtec[i].r10_marca IS NULL OR
	   rm_regtec[i].t35_serie IS NULL
	THEN
		LET mens = "La guía de remisión No. ",
				rm_regtec[i].t35_item USING "<<<<<<&",
				" no tiene configurado la hora de llegada o",
				" de salida. Por tal motivo, no se puede",
				" CERRAR este registro técnico. Modifíquelo",
				" para digitar las horas de llegada o de",
				" salida."
		CALL fl_mostrar_mensaje(mens, 'exclamation')
		LET encontro = 1
		EXIT FOR
	END IF
END FOR
IF encontro THEN
	RETURN
END IF
--}
CALL fl_hacer_pregunta('Esta seguro de CERRAR este Registro Técnico ?', 'No')
	RETURNING resp
IF resp <> 'Yes' THEN
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_cier CURSOR FOR
	SELECT * FROM talt034
		WHERE t34_compania  = rm_t34.t34_compania
		  AND t34_localidad = rm_t34.t34_localidad
		  AND t34_num_ot    = rm_t34.t34_num_ot
		  AND t34_num_reg   = rm_t34.t34_num_reg
		FOR UPDATE
OPEN q_cier
FETCH q_cier INTO rm_t34.*
IF STATUS <> 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
IF STATUS = NOTFOUND THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No existe el registro de este registro técnico. Por favor LLAME AL ADMINISTRADOR.', 'stop')
	WHENEVER ERROR STOP
	RETURN
END IF
UPDATE talt034
	SET t34_estado     = 'C',
	    t34_usu_cierre = vg_usuario,
	    t34_fec_cierre = CURRENT
	WHERE CURRENT OF q_cier
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No se pudo CERRAR el registro técnico. Por favor LLAME AL ADMINISTRADOR.', 'stop')
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
COMMIT WORK
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mostrar_mensaje('El Registro Técnico ha sido Cerrado OK.', 'info')

END FUNCTION



FUNCTION control_eliminacion()
DEFINE resp		CHAR(6)

CALL lee_muestra_registro(vm_rows[vm_row_current])
IF rm_t34.t34_estado <> 'A' THEN
	IF rm_t34.t34_fecha > TODAY THEN
		CALL fl_mostrar_mensaje('Solo se pueden eliminar un registro técnico que esten con estado ACTIVO.', 'exclamation')
		RETURN
	ELSE
		IF rm_t34.t34_estado = 'C' THEN
			CALL fl_mostrar_mensaje('El registro técnico esta CERRADO y es de hoy, se puede ELIMINAR.', 'info')
		END IF
	END IF
END IF
CALL fl_hacer_pregunta('Esta seguro de ELIMINAR este Registro Técnico ?', 'No')
	RETURNING resp
IF resp <> 'Yes' THEN
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_elim CURSOR FOR
	SELECT * FROM talt034
		WHERE t34_compania  = rm_t34.t34_compania
		  AND t34_localidad = rm_t34.t34_localidad
		  AND t34_num_ot    = rm_t34.t34_num_ot
		  AND t34_num_reg   = rm_t34.t34_num_reg
		FOR UPDATE
OPEN q_elim
FETCH q_elim INTO rm_t34.*
IF STATUS <> 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
IF STATUS = NOTFOUND THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No existe el registro de este registro técnico. Por favor LLAME AL ADMINISTRADOR.', 'stop')
	WHENEVER ERROR STOP
	RETURN
END IF
UPDATE talt034
	SET t34_estado   = 'E',
	    t34_usu_elim = vg_usuario,
	    t34_fec_elim = CURRENT
	WHERE CURRENT OF q_elim
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No se pudo ELIMINAR el registro técnico. Por favor LLAME AL ADMINISTRADOR.', 'stop')
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
COMMIT WORK
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mostrar_mensaje('El Registro Técnico ha sido Eliminado OK.', 'info')

END FUNCTION



FUNCTION control_ver_detalle()
DEFINE i, j		SMALLINT

CALL set_count(vm_num_det)
DISPLAY ARRAY rm_regtec TO rm_regtec.*
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT DISPLAY
	ON KEY(F5)
		CALL fl_ver_factura_dev_tal(rm_t34.t34_num_fact, "F")
		LET int_flag = 0
	ON KEY(F6)
		CALL control_imprimir()
		LET int_flag = 0
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel('ACCEPT', '')
	--#BEFORE ROW
		--#LET i = arr_curr()
		--#LET j = scr_line()
		--#CALL muestra_etiquetas_det(i, vm_num_det)
	--#AFTER DISPLAY
		--#CONTINUE DISPLAY
END DISPLAY
CALL muestra_etiquetas_det(0, vm_num_det)

END FUNCTION



FUNCTION control_imprimir()
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE codcli		LIKE rept019.r19_codcli
DEFINE nomcli		LIKE rept019.r19_nomcli
DEFINE query		CHAR(1000)
DEFINE comando		VARCHAR(100)
DEFINE resp		CHAR(6)
DEFINE i		SMALLINT

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
LET vm_lin_pag = 66
START REPORT reporte_reg_tec TO PIPE comando
--FOR i = 1 TO vm_num_det
	OUTPUT TO REPORT reporte_reg_tec(i)
--END FOR
FINISH REPORT reporte_reg_tec

END FUNCTION



REPORT reporte_reg_tec(i)
DEFINE i		SMALLINT
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE r_g54		RECORD LIKE gent054.*
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(32)
DEFINE usuario		VARCHAR(10)
DEFINE escape		SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_12cpi	SMALLINT
DEFINE act_dob1		SMALLINT
DEFINE act_dob2		SMALLINT
DEFINE des_dob		SMALLINT
DEFINE act_comp		SMALLINT
DEFINE act_neg, des_neg	SMALLINT
DEFINE desact_comp	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	80
	BOTTOM MARGIN	4
	PAGE LENGTH	vm_lin_pag

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_dob1	= 87		# Activar Doble Ancho (inicio)
	LET act_dob2	= 49		# Activar Doble Ancho (final)
	LET des_dob	= 48		# Desactivar Doble Ancho
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_neg	= 71		# Activar negrita.
	LET des_neg	= 72		# Desactivar negrita.
	CALL fl_lee_proceso(vg_modulo, vg_proceso) RETURNING r_g54.*
	LET titulo = "CUSTODIA DE EQUIPOS (INGRESO)"
	CALL fl_justifica_titulo('C', titulo, 40) RETURNING titulo
	SKIP 3 LINES
	print ASCII escape;
	print ASCII act_10cpi;
	--print ASCII escape;
	--print ASCII act_comp;
	PRINT COLUMN 010, ASCII escape, ASCII act_dob1, ASCII act_dob2,
		ASCII escape, ASCII act_neg,
	      COLUMN 015, titulo CLIPPED,
		ASCII escape, ASCII act_dob1, ASCII des_dob,
		ASCII escape, ASCII des_neg,
		ASCII escape, ASCII act_10cpi--, ASCII escape, ASCII act_comp
	SKIP 2 LINES
	CALL fl_justifica_titulo('I', rm_t34.t34_usuario, 10)
		RETURNING usuario
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo = 'MODULO: ', r_g50.g50_nombre[1, 19] CLIPPED
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 072, "PAG. ", PAGENO USING "&&&"
	SKIP 4 LINES

ON EVERY ROW
	PRINT COLUMN 002, 'Yo ________________________________________________'
	SKIP 1 LINES
	PRINT COLUMN 002, 'portador de la C.I.___________________ propietario',
			' y/o representante'
	SKIP 1 LINES
	PRINT COLUMN 002, 'del propietario del equipo, autorizo a',
		ASCII escape, ASCII act_neg,
		' ACERO COMERCIAL ECUATORIANO S.A.,', ASCII escape,ASCII des_neg
	SKIP 1 LINES
	PRINT COLUMN 002, 'a vender, rematar, negociar o donar, el equipo ',
				'que esta bajo custodia'
	SKIP 1 LINES
	PRINT COLUMN 002, ' en los talleres de', ASCII escape, ASCII act_neg,
		' ACERO COMERCIAL ECUATORIANO S.A.',ASCII escape,ASCII des_neg,
		', por trabajos'
	SKIP 1 LINES
	PRINT COLUMN 002, 'de reparacion, garantia o mantenimiento, si el',
		' equipo no es'
	SKIP 1 LINES
	PRINT COLUMN 002, ' retirado dentro de los primeros 30 DIAS a partir '
	SKIP 1 LINES
	PRINT COLUMN 002, 'de la fecha de terminación del trabajo. '
	SKIP 1 LINES

PAGE TRAILER
	SKIP 3 LINES
	PRINT COLUMN 003, "...............................",
	      COLUMN 048, "................................"
	PRINT COLUMN 003, " PROPIETARIO Y/O REPRESENTANTE ",
	      COLUMN 048, "ACERO COMERCIAL ECUATORIANO S.A.";
	print ASCII escape;
	print ASCII act_10cpi;
	--print ASCII escape;
	--print ASCII desact_comp;

END REPORT



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



FUNCTION muestra_estado()
DEFINE tit_estado	VARCHAR(15)

LET tit_estado = NULL
CASE rm_t34.t34_estado
	WHEN 'A' LET tit_estado = 'ACTIVO'
	WHEN 'C' LET tit_estado = 'CERRADO'
	WHEN 'E' LET tit_estado = 'ELIMINADO'
END CASE
DISPLAY BY NAME rm_t34.t34_estado, tit_estado

END FUNCTION



FUNCTION lee_cabecera(flag)
DEFINE flag		CHAR(1)
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE r_t34		RECORD LIKE talt034.*
DEFINE resp		CHAR(6)

CALL fl_lee_factura_taller(vg_codcia, vg_codloc, rm_t34.t34_num_fact)
	RETURNING r_t23.*
DISPLAY BY NAME r_t23.t23_cod_cliente, r_t23.t23_nom_cliente,
		r_t23.t23_fec_factura
LET int_flag = 0
INPUT BY NAME rm_t34.t34_num_fact, rm_t34.t34_referencia
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF FIELD_TOUCHED(rm_t34.t34_num_fact, rm_t34.t34_referencia)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				EXIT INPUT
			END IF
		ELSE
			LET int_flag = 1
			EXIT INPUT
		END IF
	ON KEY(F2)
		IF INFIELD(t34_num_fact) THEN
			CALL fl_ayuda_facturas_tal(vg_codcia, vg_codloc, 'F')
				RETURNING r_t23.t23_num_factura,
					r_t23.t23_nom_cliente
			IF r_t23.t23_num_factura IS NOT NULL THEN
				CALL fl_lee_factura_taller(vg_codcia, vg_codloc,
							r_t23.t23_num_factura)
					RETURNING r_t23.*
				LET rm_t34.t34_num_fact = r_t23.t23_num_factura
				DISPLAY BY NAME rm_t34.t34_num_fact,
						r_t23.t23_cod_cliente,
						r_t23.t23_nom_cliente,
						r_t23.t23_fec_factura
			END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		INITIALIZE r_t34.* TO NULL
		IF flag = 'M' THEN
			LET r_t34.* = rm_t34.*
		END IF
	AFTER FIELD t34_num_fact
		IF flag = 'M' THEN
			LET rm_t34.t34_num_fact = r_t34.t34_num_fact
			DISPLAY BY NAME rm_t34.t34_num_fact
			CONTINUE INPUT
		END IF
		IF rm_t34.t34_num_fact IS NOT NULL THEN
			CALL fl_lee_factura_taller(vg_codcia, vg_codloc,
						rm_t34.t34_num_fact)
				RETURNING r_t23.*
			IF r_t23.t23_compania IS NULL THEN
				CALL fl_mostrar_mensaje('La factura no existe.','exclamation')
				NEXT FIELD t34_num_fact
			END IF
			IF r_t23.t23_estado = "D" THEN
				CALL fl_mostrar_mensaje('Esta factura esta con estado DEVUELTA.', 'exclamation')
				NEXT FIELD t34_num_fact
			END IF
			LET rm_t34.t34_num_ot   = r_t23.t23_orden
			LET rm_t34.t34_num_fact = r_t23.t23_num_factura
		ELSE
			INITIALIZE r_t23.* TO NULL
		END IF
		DISPLAY BY NAME rm_t34.t34_num_fact, r_t23.t23_cod_cliente,
				r_t23.t23_nom_cliente, r_t23.t23_fec_factura
END INPUT

END FUNCTION



FUNCTION muestra_salir()

IF vm_num_rows = 0 THEN
	CLEAR FORM
	CALL control_mostrar_botones()
	RETURN
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION lee_detalle(flag)
DEFINE flag		CHAR(1)
DEFINE r_t03		RECORD LIKE talt003.*
DEFINE i, j		SMALLINT
DEFINE resp		CHAR(6)

OPTIONS 
	INSERT KEY F30,
	DELETE KEY F31
CALL control_mostrar_botones()
IF flag = 'I' THEN
	CALL cargar_detalle(0)
END IF
LET int_flag = 0
CALL set_count(vm_num_det) 
INPUT ARRAY rm_regtec WITHOUT DEFAULTS FROM rm_regtec.*
	ON KEY(INTERRUPT)
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp      
		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
	ON KEY(F2)
		IF INFIELD(t35_tecnico) THEN
			CALL fl_ayuda_mecanicos(vg_codcia, 'M')
				RETURNING r_t03.t03_mecanico,
					  r_t03.t03_nombres
			IF r_t03.t03_mecanico IS NOT NULL THEN
				LET rm_regtec[i].t35_tecnico =
						r_t03.t03_mecanico
				DISPLAY rm_regtec[i].t35_tecnico TO
					rm_regtec[j].t35_tecnico
			END IF
		END IF
		LET int_flag = 0
	ON KEY(F5)
		CALL fl_ver_factura_dev_tal(rm_t34.t34_num_fact, "F")
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel('INSERT','')
		--#CALL dialog.keysetlabel('DELETE','')
	BEFORE INSERT
		--#CANCEL INSERT
	BEFORE DELETE
		--#CANCEL DELETE
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
		CALL muestra_etiquetas_det(i, vm_num_det)
	AFTER FIELD t35_tecnico
		IF rm_regtec[i].t35_tecnico IS NOT NULL THEN
			CALL fl_lee_mecanico(vg_codcia,rm_regtec[i].t35_tecnico)
				RETURNING r_t03.*
			IF r_t03.t03_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Técnico no existe.','exclamation')
				NEXT FIELD t35_tecnico
			END IF
		END IF
	AFTER INPUT
		FOR i = 1 TO vm_num_det
			IF (rm_regtec[i].r10_marca IS NULL  OR
			    rm_regtec[i].t35_serie IS NULL  OR
			    rm_regtec[i].t35_tecnico IS NULL)
			THEN
				CONTINUE INPUT
			END IF
		END FOR
		LET vm_num_det = arr_count()
END INPUT 
IF flag = 'I' THEN
	DROP TABLE tmp_detalle
END IF

END FUNCTION



FUNCTION grabar_detalle()
DEFINE i		SMALLINT
DEFINE r_r10		RECORD LIKE rept010.*

FOR i = 1 TO vm_num_det
	INITIALIZE rm_t35.* TO NULL
	LET rm_t35.t35_compania    = rm_t34.t34_compania
	LET rm_t35.t35_localidad   = rm_t34.t34_localidad
	LET rm_t35.t35_num_ot      = rm_t34.t34_num_ot
	LET rm_t35.t35_num_reg     = rm_t34.t34_num_reg
	LET rm_t35.t35_secuencia   = i
	LET rm_t35.t35_item        = rm_regtec[i].t35_item
	CALL fl_lee_item(rm_t35.t35_compania, rm_t35.t35_item) RETURNING r_r10.*
	LET rm_t35.t35_descripcion = r_r10.r10_nombre
	LET rm_t35.t35_marca       = r_r10.r10_marca
	LET rm_t35.t35_serie       = rm_regtec[i].t35_serie
	LET rm_t35.t35_desc_prueb  = rm_regtec[i].t35_desc_prueb
	LET rm_t35.t35_tecnico     = rm_regtec[i].t35_tecnico
	LET rm_t35.t35_observacion = rm_regtec[i].t35_observacion
	INSERT INTO talt035 VALUES (rm_t35.*)
END FOR

END FUNCTION



FUNCTION lee_muestra_registro(row)
DEFINE row		INTEGER
DEFINE r_t23		RECORD LIKE talt023.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_t34.* FROM talt034 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', row
END IF
CALL control_mostrar_botones()
DISPLAY BY NAME rm_t34.t34_estado, rm_t34.t34_num_reg, rm_t34.t34_fecha,
		rm_t34.t34_num_fact, rm_t34.t34_referencia,
		rm_t34.t34_usuario, rm_t34.t34_fecing
CALL fl_lee_factura_taller(vg_codcia, vg_codloc, rm_t34.t34_num_fact)
	RETURNING r_t23.*
DISPLAY BY NAME r_t23.t23_cod_cliente, r_t23.t23_nom_cliente,
		r_t23.t23_fec_factura
CALL muestra_estado()
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_detalle()

END FUNCTION



FUNCTION muestra_detalle()
DEFINE i		SMALLINT

CALL cargar_detalle(1)
IF vm_num_det < vm_size_arr THEN 
	LET vm_size_arr = vm_num_det
END IF 
FOR i = 1 TO vm_size_arr 
	DISPLAY rm_regtec[i].* TO rm_regtec[i].*
END FOR 
SELECT COUNT(*) INTO vm_num_det FROM tmp_detalle
DROP TABLE tmp_detalle
CALL muestra_etiquetas_det(0, vm_num_det)

END FUNCTION



FUNCTION cargar_detalle(flag)
DEFINE flag		SMALLINT

CALL borrar_detalle()
CALL generar_temp_det(flag)
CALL cargar_det_temp()
IF vm_num_det = 0 AND flag <> 'I' THEN
	DROP TABLE tmp_detalle
	RETURN
END IF

END FUNCTION



FUNCTION generar_temp_det(flag)
DEFINE flag		SMALLINT
DEFINE query		CHAR(2000)
DEFINE cuantos		INTEGER

IF flag = 1 THEN
	LET query = "SELECT t35_item, t35_marca, t35_serie, t35_desc_prueb,",
			" t35_tecnico, t35_observacion ",
			" FROM talt035",
			" WHERE t35_compania  = ", rm_t34.t34_compania,
			"   AND t35_localidad = ", rm_t34.t34_localidad,
			"   AND t35_num_ot    = ", rm_t34.t34_num_ot,
			"   AND t35_num_reg   = ", rm_t34.t34_num_reg,
			" INTO TEMP t1"
	PREPARE exec_t1 FROM query
	EXECUTE exec_t1
	SELECT COUNT(*) INTO cuantos FROM t1
	IF cuantos > 0 THEN
		SELECT * FROM t1 INTO TEMP tmp_detalle
		DROP TABLE t1
		RETURN
	END IF
	DROP TABLE t1
END IF
LET query = "SELECT r20_item, r10_marca, '' serie, '' des_pru, '' tecni,",
			" '' observ",
		" FROM rept019, rept020, rept010 ",
		" WHERE  r19_compania    = ", rm_t34.t34_compania,
		"   AND  r19_localidad   = ", rm_t34.t34_localidad,
		"   AND  r19_cod_tran    = 'FA' ",
		"   AND (r19_tipo_dev    = 'TR' ",
		"    OR  r19_tipo_dev    IS NULL) ",
		"   AND  r19_ord_trabajo = ", rm_t34.t34_num_ot,
		"   AND  r20_compania    = r19_compania ",
		"   AND  r20_localidad   = r19_localidad ",
		"   AND  r20_cod_tran    = r19_cod_tran ",
		"   AND  r20_num_tran    = r19_num_tran ",
		"   AND  r10_compania    = r20_compania ",
		"   AND  r10_codigo      = r20_item ",
		" INTO TEMP tmp_detalle"
PREPARE exec_tmp FROM query
EXECUTE exec_tmp

END FUNCTION



FUNCTION cargar_det_temp()

DECLARE q_regtec CURSOR FOR
	SELECT * FROM tmp_detalle
LET vm_num_det = 1
FOREACH q_regtec INTO rm_regtec[vm_num_det].*
	LET vm_num_det = vm_num_det + 1
        IF vm_num_det > vm_max_det THEN
		EXIT FOREACH
	END IF	
END FOREACH 
LET vm_num_det = vm_num_det - 1

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION muestra_etiquetas_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r72		RECORD LIKE rept072.*
DEFINE r_t03		RECORD LIKE talt003.*

CALL muestra_contadores_det(num_row, max_row)
IF num_row = 0 THEN
	CLEAR r72_desc_clase, r10_nombre, t03_nombres
	RETURN
END IF
CALL fl_lee_item(vg_codcia, rm_regtec[num_row].t35_item) RETURNING r_r10.*
CALL fl_lee_clase_rep(vg_codcia, r_r10.r10_linea, r_r10.r10_sub_linea,
			r_r10.r10_cod_grupo, r_r10.r10_cod_clase)
	RETURNING r_r72.*
CALL fl_lee_mecanico(vg_codcia,rm_regtec[num_row].t35_tecnico) RETURNING r_t03.*
DISPLAY BY NAME r_r72.r72_desc_clase, r_r10.r10_nombre, r_t03.t03_nombres

END FUNCTION
