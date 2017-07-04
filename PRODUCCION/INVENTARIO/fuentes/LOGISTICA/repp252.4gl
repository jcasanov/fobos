--------------------------------------------------------------------------------
-- Titulo           : repp252.4gl - Mantenimiento Control de Ruta
-- Elaboracion      : 07-jun-2013
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp252 base modulo compania localidad [num_hoja]
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
DEFINE rm_hoja		ARRAY[600] OF RECORD
				r114_guia_remision LIKE rept114.r114_guia_remision,
				r114_hora_lleg	DATETIME HOUR TO MINUTE,
				r114_hora_sali	DATETIME HOUR TO MINUTE,
				r112_descripcion LIKE rept112.r112_descripcion,
				r114_recibido_por LIKE rept114.r114_recibido_por
			END RECORD
DEFINE rm_codhoj	ARRAY[600] OF RECORD
				r95_num_sri	LIKE rept095.r95_num_sri,
				r108_descripcion LIKE rept108.r108_descripcion,
				r109_descripcion LIKE rept109.r109_descripcion,
				r114_cod_zona	LIKE rept114.r114_cod_zona,
				r114_cod_subzona LIKE rept114.r114_cod_subzona,
				r114_cod_obser	LIKE rept114.r114_cod_obser
			END RECORD
DEFINE rm_r113		RECORD LIKE rept113.*
DEFINE rm_r114		RECORD LIKE rept114.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp252.err')
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
LET vg_proceso = 'repp252'
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
	CALL fl_chequeo_mes_proceso_rep(vg_codcia) RETURNING int_flag 
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
OPEN WINDOW w_repp252_1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,   
		  BORDER, MESSAGE LINE LAST - 1)                                
IF vg_gui = 1 THEN
	OPEN FORM f_repf252_1 FROM '../forms/repf252_1'
ELSE
	OPEN FORM f_repf252_1 FROM '../forms/repf252_1c'
END IF
DISPLAY FORM f_repf252_1
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
				IF rm_r113.r113_estado = 'A' OR
				   rm_r113.r113_estado = 'P'
				THEN
					SHOW OPTION 'Modificar'
					SHOW OPTION 'Eliminar'
					SHOW OPTION 'Cerrar'
				ELSE
					HIDE OPTION 'Modificar'
					IF rm_r113.r113_estado = 'C' AND
					   rm_r113.r113_fecha = TODAY
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
			IF rm_r113.r113_estado = 'A' OR
			   rm_r113.r113_estado = 'P'
			THEN
				SHOW OPTION 'Modificar'
				SHOW OPTION 'Eliminar'
				SHOW OPTION 'Cerrar'
			ELSE
				HIDE OPTION 'Modificar'
				IF rm_r113.r113_estado = 'C' AND
				   rm_r113.r113_fecha = TODAY
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
		IF rm_r113.r113_estado = 'E' THEN
			HIDE OPTION 'Imprimir'
		ELSE
			SHOW OPTION 'Imprimir'
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
				IF rm_r113.r113_estado = 'A' OR
				   rm_r113.r113_estado = 'P'
				THEN
					SHOW OPTION 'Cerrar'
					SHOW OPTION 'Eliminar'
					SHOW OPTION 'Modificar'
				ELSE
					HIDE OPTION 'Cerrar'
					IF rm_r113.r113_estado = 'C' AND
					   rm_r113.r113_fecha = TODAY
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
			IF rm_r113.r113_estado = 'A' OR
			   rm_r113.r113_estado = 'P'
			THEN
				SHOW OPTION 'Modificar'
				SHOW OPTION 'Eliminar'
				SHOW OPTION 'Cerrar'
			ELSE
				HIDE OPTION 'Modificar'
				IF rm_r113.r113_estado = 'C' AND
				   rm_r113.r113_fecha = TODAY
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
		IF rm_r113.r113_estado = 'E' THEN
			HIDE OPTION 'Imprimir'
		ELSE
			SHOW OPTION 'Imprimir'
		END IF
        COMMAND KEY('P') 'Cerrar'	'Cierra un Control Ruta Activo.'
		CALL control_cierre()
		IF rm_r113.r113_estado = 'A' OR rm_r113.r113_estado = 'P' THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Eliminar'
			SHOW OPTION 'Cerrar'
		ELSE
			HIDE OPTION 'Modificar'
			IF rm_r113.r113_estado = 'C' AND
			   rm_r113.r113_fecha = TODAY
			THEN
				SHOW OPTION 'Eliminar'
			ELSE
				HIDE OPTION 'Eliminar'
			END IF
			HIDE OPTION 'Cerrar'
		END IF
        COMMAND KEY('E') 'Eliminar'	'Elimina un Control Ruta Activo.'
		CALL control_eliminacion()
		IF rm_r113.r113_estado = 'A' OR rm_r113.r113_estado = 'P' THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Eliminar'
			SHOW OPTION 'Cerrar'
		ELSE
			HIDE OPTION 'Modificar'
			IF rm_r113.r113_estado = 'C' AND
			   rm_r113.r113_fecha = TODAY
			THEN
				SHOW OPTION 'Eliminar'
			ELSE
				HIDE OPTION 'Eliminar'
			END IF
			HIDE OPTION 'Cerrar'
		END IF
		IF rm_r113.r113_estado = 'E' THEN
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
			IF rm_r113.r113_estado = 'A' OR
			   rm_r113.r113_estado = 'P'
			THEN
				SHOW OPTION 'Modificar'
				SHOW OPTION 'Eliminar'
				SHOW OPTION 'Cerrar'
			ELSE
				HIDE OPTION 'Modificar'
				IF rm_r113.r113_estado = 'C' AND
				   rm_r113.r113_fecha = TODAY
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
			IF rm_r113.r113_estado = 'A' OR
			   rm_r113.r113_estado = 'P'
			THEN
				SHOW OPTION 'Modificar'
				SHOW OPTION 'Eliminar'
				SHOW OPTION 'Cerrar'
			ELSE
				HIDE OPTION 'Modificar'
				IF rm_r113.r113_estado = 'C' AND
				   rm_r113.r113_fecha = TODAY
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
		IF rm_r113.r113_estado = 'E' THEN
			HIDE OPTION 'Imprimir'
		ELSE
			SHOW OPTION 'Imprimir'
		END IF
	COMMAND KEY('R') 'Retroceder' 	'Ver anterior registro.'
		CALL anterior_registro()
		IF vm_row_current = 1 THEN
			IF rm_r113.r113_estado = 'A' OR
			   rm_r113.r113_estado = 'P'
			THEN
				SHOW OPTION 'Modificar'
				SHOW OPTION 'Eliminar'
				SHOW OPTION 'Cerrar'
			ELSE
				HIDE OPTION 'Modificar'
				IF rm_r113.r113_estado = 'C' AND
				   rm_r113.r113_fecha = TODAY
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
			IF rm_r113.r113_estado = 'A' OR
			   rm_r113.r113_estado = 'P'
			THEN
				SHOW OPTION 'Modificar'
				SHOW OPTION 'Eliminar'
				SHOW OPTION 'Cerrar'
			ELSE
				HIDE OPTION 'Modificar'
				IF rm_r113.r113_estado = 'C' AND
				   rm_r113.r113_fecha = TODAY
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
		IF rm_r113.r113_estado = 'E' THEN
			HIDE OPTION 'Imprimir'
		ELSE
			SHOW OPTION 'Imprimir'
		END IF
	COMMAND KEY('S') 'Salir'    	'Salir del programa.'
		EXIT MENU
END MENU
CLOSE WINDOW w_repp252_1
EXIT PROGRAM

END FUNCTION



FUNCTION control_mostrar_botones()

--#DISPLAY "Guia"		TO tit_col1
--#IF rm_r113.r113_areaneg = 2 THEN
	--#DISPLAY "Cliente"	TO tit_col1
--#END IF
--#DISPLAY "H.Ll."		TO tit_col2
--#DISPLAY "H.Sl."		TO tit_col3
--#DISPLAY "Observación"	TO tit_col4
--#DISPLAY "Recibido Por"	TO tit_col5

END FUNCTION



FUNCTION muestra_contadores(num_reg, max_reg)
DEFINE num_reg, max_reg	SMALLINT

DISPLAY BY NAME num_reg, max_reg

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i		SMALLINT

LET vm_num_det  = 0
LET vm_size_arr = fgl_scr_size('rm_hoja')
FOR i = 1 TO vm_size_arr
	CLEAR rm_hoja[i].*
END FOR
FOR i = 1 TO vm_max_det
	INITIALIZE rm_hoja[i].*, rm_codhoj[i].* TO NULL
END FOR

END FUNCTION



FUNCTION control_ingreso()
DEFINE num_aux		INTEGER
DEFINE mensaje		VARCHAR(100)

CLEAR FORM
CALL control_mostrar_botones()
INITIALIZE rm_r113.*, rm_r114.* TO NULL
CALL borrar_detalle()
LET rm_r113.r113_compania  = vg_codcia
LET rm_r113.r113_localidad = vg_codloc
LET rm_r113.r113_estado    = "A"
LET rm_r113.r113_fecha     = TODAY
LET rm_r113.r113_usuario   = vg_usuario
LET rm_r113.r113_fecing    = CURRENT
DISPLAY BY NAME rm_r113.r113_fecha, rm_r113.r113_usuario, rm_r113.r113_fecing
CALL muestra_estado()
CALL lee_cabecera('I')
IF int_flag THEN
	CALL muestra_salir()
	RETURN
END IF
CALL lee_detalle()
IF int_flag THEN
	CALL muestra_salir()
	RETURN
END IF
BEGIN WORK
WHILE TRUE
	SELECT NVL(MAX(r113_num_hojrut) + 1, 1)
		INTO rm_r113.r113_num_hojrut
		FROM rept113
		WHERE r113_compania  = rm_r113.r113_compania
		  AND r113_localidad = rm_r113.r113_localidad
	LET rm_r113.r113_fecing = CURRENT
	WHENEVER ERROR CONTINUE
	INSERT INTO rept113 VALUES (rm_r113.*)
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
LET mensaje = 'Se generó Control de Ruta No. ',
		rm_r113.r113_num_hojrut USING "<<<<<<<&", '.'
CALL fl_mostrar_mensaje(mensaje, 'info')

END FUNCTION



FUNCTION control_modificacion()

CALL lee_muestra_registro(vm_rows[vm_row_current])
IF rm_r113.r113_estado <> 'A' AND rm_r113.r113_estado <> 'P' THEN
	CALL fl_mostrar_mensaje('Solo se pueden modificar un control de ruta que esten con estado ACTIVO o EN PROCESO.', 'exclamation')
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_modif CURSOR FOR
	SELECT * FROM rept113
		WHERE r113_compania   = rm_r113.r113_compania
		  AND r113_localidad  = rm_r113.r113_localidad
		  AND r113_num_hojrut = rm_r113.r113_num_hojrut
		FOR UPDATE
OPEN q_modif
FETCH q_modif INTO rm_r113.*
IF STATUS <> 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
IF STATUS = NOTFOUND THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No existe el registro de este control de ruta. Por favor LLAME AL ADMINISTRADOR.', 'stop')
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
CALL lee_detalle()
IF int_flag THEN
	ROLLBACK WORK
	CALL muestra_salir()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR CONTINUE
UPDATE rept113
	SET * = rm_r113.*
	WHERE CURRENT OF q_modif
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No se pudo MODIFICAR la cabecera del control de ruta. Por favor LLAME AL ADMINISTRADOR.', 'stop')
	WHENEVER ERROR STOP
	RETURN
END IF
DELETE FROM rept114
	WHERE r114_compania   = rm_r113.r113_compania
	  AND r114_localidad  = rm_r113.r113_localidad
	  AND r114_num_hojrut = rm_r113.r113_num_hojrut
WHENEVER ERROR CONTINUE
CALL grabar_detalle()
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No se pudo MODIFICAR el detalle del control de ruta. Por favor LLAME AL ADMINISTRADOR.', 'stop')
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
COMMIT WORK
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mostrar_mensaje('El Control de Ruta ha sido modificada OK.', 'info')

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		CHAR(1800)
DEFINE query		CHAR(3500)
DEFINE num_hojrut	LIKE rept113.r113_num_hojrut
DEFINE r_g03		RECORD LIKE gent003.*
DEFINE r_r110		RECORD LIKE rept110.*
DEFINE r_r111		RECORD LIKE rept111.*
DEFINE r_r115		RECORD LIKE rept115.*

CLEAR FORM
INITIALIZE rm_r113.*, r_g03.*, r_r110.*, r_r111.*, r_r115.* TO NULL
CALL control_mostrar_botones()
IF num_args() = 4 THEN
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON r113_num_hojrut, r113_fecha, r113_estado,
		r113_cod_trans, r113_cod_chofer, r113_cod_ayud,r113_observacion,
		r113_areaneg, r113_km_ini, r113_km_fin, r113_usuario,
		r113_fecing, r113_usu_cierre, r113_fec_cierre, r113_usu_elim,
		r113_fec_elim
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT CONSTRUCT
	ON KEY(F2)
		IF INFIELD(r113_num_hojrut) THEN
			CALL fl_ayuda_hoja_ruta(vg_codcia, vg_codloc, "T")
				RETURNING num_hojrut
			IF num_hojrut IS NOT NULL THEN
				DISPLAY num_hojrut TO r113_num_hojrut
			END IF
		END IF
		IF INFIELD(r113_cod_trans) THEN
			CALL fl_ayuda_transporte(vg_codcia, vg_codloc, "T")
				RETURNING r_r110.r110_cod_trans,
					  r_r110.r110_descripcion
		      	IF r_r110.r110_cod_trans IS NOT NULL THEN
				CALL fl_lee_transporte(vg_codcia, vg_codloc,
						r_r110.r110_cod_trans)
					RETURNING r_r110.*
				DISPLAY r_r110.r110_cod_trans TO r113_cod_trans
				DISPLAY BY NAME r_r110.r110_descripcion,
						r_r110.r110_placa
		      	END IF
		END IF
		IF INFIELD(r113_cod_chofer) AND
		   r_r110.r110_cod_trans IS NOT NULL
		THEN
			CALL fl_ayuda_chofer(vg_codcia, vg_codloc,
						r_r110.r110_cod_trans, "T")
				RETURNING r_r111.r111_cod_chofer,
					  r_r111.r111_nombre
		      	IF r_r111.r111_cod_chofer IS NOT NULL THEN
				DISPLAY r_r111.r111_cod_chofer TO
					r113_cod_chofer
				DISPLAY BY NAME r_r111.r111_nombre
		      	END IF
		END IF
		IF INFIELD(r113_cod_ayud) AND
		   r_r110.r110_cod_trans IS NOT NULL
		THEN
			CALL fl_ayuda_ayudante(vg_codcia, vg_codloc,
						r_r110.r110_cod_trans, "T")
				RETURNING r_r115.r115_cod_ayud,
					  r_r115.r115_nombre
		      	IF r_r115.r115_cod_ayud IS NOT NULL THEN
				DISPLAY r_r115.r115_cod_ayud TO
					r113_cod_ayud
				DISPLAY BY NAME r_r115.r115_nombre
		      	END IF
		END IF
		IF INFIELD(r113_areaneg) THEN
			CALL fl_ayuda_areaneg(vg_codcia)
				RETURNING r_g03.g03_areaneg, r_g03.g03_nombre
			IF r_g03.g03_areaneg IS NOT NULL THEN
				DISPLAY r_g03.g03_areaneg TO r_r113.r113_areaneg
				DISPLAY BY NAME r_g03.g03_nombre
			END IF
		END IF
		LET int_flag = 0
	AFTER FIELD r113_cod_trans
		LET rm_r113.r113_cod_trans = GET_FLDBUF(r113_cod_trans)
		IF rm_r113.r113_cod_trans IS NOT NULL THEN
			CALL fl_lee_transporte(vg_codcia, vg_codloc,
						rm_r113.r113_cod_trans)
				RETURNING r_r110.*
			IF r_r110.r110_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Este transporte no existe en la compañía.', 'exclamation')
				NEXT FIELD r113_cod_trans
			END IF
			LET rm_r113.r113_cod_trans = r_r110.r110_cod_trans
		ELSE
			INITIALIZE r_r110.*, r_r111.*, r_r115.*,
					rm_r113.r113_cod_chofer,
					rm_r113.r113_cod_ayud
				TO NULL
		END IF
		DISPLAY BY NAME r_r110.r110_descripcion, r_r110.r110_placa,
				rm_r113.r113_cod_chofer, r_r111.r111_nombre,
				rm_r113.r113_cod_ayud, r_r115.r115_nombre
	AFTER FIELD r113_cod_chofer
		LET rm_r113.r113_cod_trans = GET_FLDBUF(r113_cod_trans)
		IF rm_r113.r113_cod_trans IS NULL THEN
			INITIALIZE r_r111.*, rm_r113.r113_cod_chofer TO NULL
			DISPLAY BY NAME rm_r113.r113_cod_chofer,
					r_r111.r111_nombre
			CONTINUE CONSTRUCT
		END IF
		LET rm_r113.r113_cod_chofer = GET_FLDBUF(r113_cod_chofer)
		IF rm_r113.r113_cod_chofer IS NOT NULL THEN
			CALL fl_lee_chofer(vg_codcia, vg_codloc,
						rm_r113.r113_cod_trans,
						rm_r113.r113_cod_chofer)
				RETURNING r_r111.*
			IF r_r111.r111_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Este chofer no existe en la compañía o no esta asociado a éste transporte.', 'exclamation')
				NEXT FIELD r113_cod_chofer
			END IF
			LET rm_r113.r113_cod_chofer = r_r111.r111_cod_chofer
		ELSE
			INITIALIZE r_r111.* TO NULL
		END IF
		DISPLAY BY NAME r_r111.r111_nombre
	AFTER FIELD r113_cod_ayud
		LET rm_r113.r113_cod_trans = GET_FLDBUF(r113_cod_trans)
		IF rm_r113.r113_cod_trans IS NULL THEN
			INITIALIZE r_r115.*, rm_r113.r113_cod_ayud TO NULL
			DISPLAY BY NAME rm_r113.r113_cod_ayud,r_r115.r115_nombre
			CONTINUE CONSTRUCT
		END IF
		LET rm_r113.r113_cod_ayud = GET_FLDBUF(r113_cod_ayud)
		IF rm_r113.r113_cod_ayud IS NOT NULL THEN
			CALL fl_lee_ayudante(vg_codcia, vg_codloc,
						rm_r113.r113_cod_trans,
						rm_r113.r113_cod_ayud)
				RETURNING r_r115.*
			IF r_r115.r115_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Este ayudante no existe en la compañía o no esta asociado a éste transporte.', 'exclamation')
				NEXT FIELD r113_cod_ayud
			END IF
			LET rm_r113.r113_cod_ayud = r_r115.r115_cod_ayud
		ELSE
			INITIALIZE r_r115.* TO NULL
		END IF
		DISPLAY BY NAME r_r115.r115_nombre
	AFTER FIELD r113_areaneg
		LET rm_r113.r113_areaneg = GET_FLDBUF(r113_areaneg)
		IF rm_r113.r113_areaneg IS NOT NULL THEN
			CALL fl_lee_area_negocio(vg_codcia,rm_r113.r113_areaneg)
				RETURNING r_g03.*
			IF r_g03.g03_areaneg IS NULL THEN
				CALL fl_mostrar_mensaje('Area de Negocio no existe en la compañía.', 'exclamation')
				NEXT FIELD r113_areaneg
			END IF
			LET rm_r113.r113_areaneg = r_g03.g03_areaneg
		ELSE
			INITIALIZE r_g03.* TO NULL
		END IF
		DISPLAY BY NAME r_g03.g03_nombre
	END CONSTRUCT
	IF int_flag THEN
		CALL muestra_salir()
		RETURN
	END IF
ELSE
	LET expr_sql = ' r113_num_hojrut = ', arg_val(5)
END IF
LET query = 'SELECT *, ROWID FROM rept113 ',
		' WHERE r113_compania  = ', vg_codcia,
		'   AND r113_localidad = ', vg_codloc,
		'   AND ', expr_sql CLIPPED,
		' ORDER BY 3 ' 
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_r113.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
		EXIT FOREACH
	END IF	
END FOREACH 
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN 
	CALL fl_mensaje_consulta_sin_registros()
	IF num_args() = 5 THEN
		CLOSE WINDOW w_repp252_1
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
IF rm_r113.r113_estado <> 'A' AND rm_r113.r113_estado <> 'P' THEN
	CALL fl_mostrar_mensaje('Solo se puede cerrar un control de ruta que esten con estado ACTIVO o EN PROCESO.', 'exclamation')
	RETURN
END IF
LET encontro = 0
FOR i = 1 TO vm_num_det
	IF rm_hoja[i].r114_hora_lleg IS NULL OR
	   rm_hoja[i].r114_hora_sali IS NULL
	THEN
		LET mens = "La guía de remisión No. ",
				rm_hoja[i].r114_guia_remision USING "<<<<<<&",
				" no tiene configurado la hora de llegada o",
				" de salida. Por tal motivo, no se puede",
				" CERRAR este control de ruta. Modifíquelo",
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
CALL fl_hacer_pregunta('Esta seguro de CERRAR este Control de Ruta ?', 'No')
	RETURNING resp
IF resp <> 'Yes' THEN
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_cier CURSOR FOR
	SELECT * FROM rept113
		WHERE r113_compania   = rm_r113.r113_compania
		  AND r113_localidad  = rm_r113.r113_localidad
		  AND r113_num_hojrut = rm_r113.r113_num_hojrut
		FOR UPDATE
OPEN q_cier
FETCH q_cier INTO rm_r113.*
IF STATUS <> 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
IF STATUS = NOTFOUND THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No existe el registro de este control de ruta. Por favor LLAME AL ADMINISTRADOR.', 'stop')
	WHENEVER ERROR STOP
	RETURN
END IF
UPDATE rept113
	SET r113_estado     = 'C',
	    r113_usu_cierre = vg_usuario,
	    r113_fec_cierre = CURRENT
	WHERE CURRENT OF q_cier
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No se pudo CERRAR el control de ruta. Por favor LLAME AL ADMINISTRADOR.', 'stop')
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
COMMIT WORK
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mostrar_mensaje('El Control de Ruta ha sido Cerrada OK.', 'info')

END FUNCTION



FUNCTION control_eliminacion()
DEFINE resp		CHAR(6)

CALL lee_muestra_registro(vm_rows[vm_row_current])
IF rm_r113.r113_estado <> 'A' AND rm_r113.r113_estado <> 'P' THEN
	IF rm_r113.r113_fecha > TODAY THEN
		CALL fl_mostrar_mensaje('Solo se pueden eliminar un control de ruta que esten con estado ACTIVO o EN PROCESO.', 'exclamation')
		RETURN
	ELSE
		IF rm_r113.r113_estado = 'C' THEN
			CALL fl_mostrar_mensaje('El control de ruta esta CERRADO y es de hoy, se puede ELIMINAR.', 'info')
		END IF
	END IF
END IF
CALL fl_hacer_pregunta('Esta seguro de ELIMINAR este Control de Ruta ?', 'No')
	RETURNING resp
IF resp <> 'Yes' THEN
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_elim CURSOR FOR
	SELECT * FROM rept113
		WHERE r113_compania   = rm_r113.r113_compania
		  AND r113_localidad  = rm_r113.r113_localidad
		  AND r113_num_hojrut = rm_r113.r113_num_hojrut
		FOR UPDATE
OPEN q_elim
FETCH q_elim INTO rm_r113.*
IF STATUS <> 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
IF STATUS = NOTFOUND THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No existe el registro de este control de ruta. Por favor LLAME AL ADMINISTRADOR.', 'stop')
	WHENEVER ERROR STOP
	RETURN
END IF
UPDATE rept113
	SET r113_estado   = 'E',
	    r113_usu_elim = vg_usuario,
	    r113_fec_elim = CURRENT
	WHERE CURRENT OF q_elim
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No se pudo ELIMINAR el control de ruta. Por favor LLAME AL ADMINISTRADOR.', 'stop')
	WHENEVER ERROR STOP
	RETURN
END IF
UPDATE rept114
	SET r114_estado = 'N'
	WHERE r114_compania   = rm_r113.r113_compania
	  AND r114_localidad  = rm_r113.r113_localidad
	  AND r114_num_hojrut = rm_r113.r113_num_hojrut
WHENEVER ERROR STOP
COMMIT WORK
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mostrar_mensaje('El Control de Ruta ha sido Eliminada OK.', 'info')

END FUNCTION



FUNCTION control_ver_detalle()
DEFINE i, j		SMALLINT

CALL set_count(vm_num_det)
DISPLAY ARRAY rm_hoja TO rm_hoja.*
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT DISPLAY
	ON KEY(F5)
		CALL ver_guia(rm_hoja[i].r114_guia_remision)
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

CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
IF rm_r113.r113_estado = 'A' THEN
	CALL fl_hacer_pregunta('Este Control de Ruta esta ACTIVO, desea imprimirlo para cambiar su estado a EN PROCESO ?', 'No')
		RETURNING resp
	IF resp <> 'Yes' THEN
		RETURN
	END IF
	BEGIN WORK
	WHENEVER ERROR CONTINUE
	DECLARE q_est CURSOR FOR
		SELECT * FROM rept113
			WHERE r113_compania   = rm_r113.r113_compania
			  AND r113_localidad  = rm_r113.r113_localidad
			  AND r113_num_hojrut = rm_r113.r113_num_hojrut
			FOR UPDATE
	OPEN q_est
	FETCH q_est INTO rm_r113.*
	IF STATUS <> 0 THEN
		ROLLBACK WORK
		CALL fl_mensaje_bloqueo_otro_usuario()
		WHENEVER ERROR STOP
		RETURN
	END IF
	IF STATUS = NOTFOUND THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No existe el registro de este control de ruta. Por favor LLAME AL ADMINISTRADOR.', 'stop')
		WHENEVER ERROR STOP
		RETURN
	END IF
	UPDATE rept113
		SET r113_estado = 'P'
		WHERE CURRENT OF q_est
	IF STATUS < 0 THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No se pudo cambiar el estado del control de ruta. Por favor LLAME AL ADMINISTRADOR.', 'stop')
		WHENEVER ERROR STOP
		RETURN
	END IF
	WHENEVER ERROR STOP
	COMMIT WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	CALL fl_mostrar_mensaje('El Control de Ruta se cambió a estado EN PROCESO OK.','info')
END IF
LET vm_lin_pag = 66
START REPORT reporte_hoja_ruta TO PIPE comando
FOR i = 1 TO vm_num_det
	IF rm_r113.r113_areaneg <> 1 THEN
		CALL fl_lee_cliente_general(rm_hoja[i].r114_guia_remision)
			RETURNING r_z01.*
		OUTPUT TO REPORT reporte_hoja_ruta(i,
				rm_hoja[i].r114_guia_remision, r_z01.z01_nomcli)
		CONTINUE FOR
	END IF
	LET query = "SELECT r19_codcli, ",
				"CASE WHEN r19_cod_tran = 'TR' ",
					"THEN r19_referencia ",
					"ELSE r19_nomcli ",
				"END ",
			"FROM rept097, rept019 ",
			"WHERE r97_compania      = ", rm_r113.r113_compania,
			"  AND r97_localidad     = ", rm_r113.r113_localidad,
			"  AND r97_guia_remision = ",
						rm_hoja[i].r114_guia_remision,
			"  AND r19_compania      = r97_compania ",
			"  AND r19_localidad     = r97_localidad ",
			"  AND r19_cod_tran      = r97_cod_tran ",
			"  AND r19_num_tran      = r97_num_tran ",
			"GROUP BY 1, 2 ",
			"ORDER BY 2 "
	PREPARE cons_cli FROM query
	DECLARE q_cli CURSOR FOR cons_cli
	FOREACH q_cli INTO codcli, nomcli
		OUTPUT TO REPORT reporte_hoja_ruta(i, codcli, nomcli)
	END FOREACH
END FOR
FINISH REPORT reporte_hoja_ruta

END FUNCTION



REPORT reporte_hoja_ruta(i, codcli, nomcli)
DEFINE i		SMALLINT
DEFINE codcli		LIKE rept019.r19_codcli
DEFINE nomcli		LIKE rept019.r19_nomcli
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE r_g54		RECORD LIKE gent054.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r110		RECORD LIKE rept110.*
DEFINE r_r111		RECORD LIKE rept111.*
DEFINE r_r115		RECORD LIKE rept115.*
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(32)
DEFINE usuario		VARCHAR(10)
DEFINE lin_doc		VARCHAR(20)
DEFINE num_sri		INTEGER
DEFINE query		CHAR(2000)
DEFINE expr_cli		VARCHAR(100)
DEFINE col		SMALLINT
DEFINE escape		SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_12cpi	SMALLINT
DEFINE act_dob1		SMALLINT
DEFINE act_dob2		SMALLINT
DEFINE des_dob		SMALLINT
DEFINE act_comp		SMALLINT
DEFINE desact_comp	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	132
	BOTTOM MARGIN	4
	PAGE LENGTH	vm_lin_pag

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	LET act_dob1	= 87		# Activar Doble Ancho (inicio)
	LET act_dob2	= 49		# Activar Doble Ancho (final)
	LET des_dob	= 48		# Desactivar Doble Ancho
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	CALL fl_lee_proceso(vg_modulo, vg_proceso) RETURNING r_g54.*
	CALL fl_lee_transporte(rm_r113.r113_compania, rm_r113.r113_localidad,
				rm_r113.r113_cod_trans)
		RETURNING r_r110.*
	CALL fl_lee_chofer(rm_r113.r113_compania, rm_r113.r113_localidad,
				rm_r113.r113_cod_trans, rm_r113.r113_cod_chofer)
		RETURNING r_r111.*
	CALL fl_lee_ayudante(rm_r113.r113_compania, rm_r113.r113_localidad,
				rm_r113.r113_cod_trans, rm_r113.r113_cod_ayud)
		RETURNING r_r115.*
	LET titulo = r_g54.g54_nombre CLIPPED, " No. ",
			rm_r113.r113_num_hojrut USING "<<<<&&&"
	CALL fl_justifica_titulo('C', titulo, 40) RETURNING titulo
	print ASCII escape;
	print ASCII act_10cpi;
	print ASCII escape;
	print ASCII act_comp;
	PRINT COLUMN 018, ASCII escape, ASCII act_dob1, ASCII act_dob2,
	      COLUMN 022, titulo CLIPPED,
		ASCII escape, ASCII act_dob1, ASCII des_dob,
		ASCII escape, ASCII act_10cpi, ASCII escape, ASCII act_comp
	SKIP 1 LINES
	CALL fl_justifica_titulo('I', rm_r113.r113_usuario, 10)
		RETURNING usuario
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo = 'MODULO: ', r_g50.g50_nombre[1, 19] CLIPPED
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 125, "PAG. ", PAGENO USING "&&&"
	SKIP 1 LINES
	PRINT COLUMN 001, "CHOFER     : ", rm_r113.r113_cod_chofer USING "&&&",
		" ", r_r111.r111_nombre CLIPPED,
	      COLUMN 067, "KM INICIAL      : ",
		rm_r113.r113_km_ini USING "<<<<<&"
	PRINT COLUMN 001, "AYUDANTE   : ", rm_r113.r113_cod_ayud USING "&&&",
		" ", r_r115.r115_nombre CLIPPED,
	      COLUMN 067, "KM FINAL        : ",
		rm_r113.r113_km_fin USING "<<<<<&"
	PRINT COLUMN 001, "TRANSPORTE : ", rm_r113.r113_cod_trans USING "&&&",
		" ", r_r110.r110_descripcion CLIPPED,
	      COLUMN 067, "FECHA HOJA RUTA : ",
		rm_r113.r113_fecha USING "dd-mm-yyyy"
	PRINT COLUMN 001, "PLACA      : ", r_r110.r110_placa
	PRINT COLUMN 001, "USUARIO    : ", usuario,
	      COLUMN 067, "FECHA IMPRESION : ", DATE(TODAY) USING "dd-mm-yyyy",
		1 SPACES, TIME
	PRINT COLUMN 001, "------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 001, "RUTA",
	      COLUMN 017, "CLIENTE",
	      COLUMN 043, "GUIA REMISION",
	      COLUMN 062, "DOCUMENTO",
	      COLUMN 074, "H.LLEG.",
	      COLUMN 082, "H.SALI.";
	IF rm_r113.r113_estado = "C" THEN
		PRINT COLUMN 090, "RECIBIDO POR",
		      COLUMN 111, " ",
		      COLUMN 113, "OBSERVACIONES"
	ELSE
		PRINT COLUMN 090, "RECIBIDO POR",
		      COLUMN 107, "FIRMA",
		      COLUMN 118, "OBSERVACIONES"
	END IF
	PRINT COLUMN 001, "------------------------------------------------------------------------------------------------------------------------------------"

BEFORE GROUP OF nomcli
	NEED 4 LINES
	SKIP 1 LINES
	PRINT COLUMN 001, rm_codhoj[i].r108_descripcion[1, 15] CLIPPED,
	      COLUMN 017, nomcli[1, 25] CLIPPED,
	      COLUMN 043, rm_codhoj[i].r95_num_sri CLIPPED;
	IF rm_r113.r113_estado = "C" THEN
		PRINT COLUMN 074, rm_hoja[i].r114_hora_lleg,
		      COLUMN 082, rm_hoja[i].r114_hora_sali,
		      COLUMN 090, rm_hoja[i].r114_recibido_por[1, 21] CLIPPED,
		      COLUMN 111, " ",
		      COLUMN 112, rm_hoja[i].r112_descripcion[1, 21] CLIPPED
	ELSE
		PRINT COLUMN 074, "_______",
		      COLUMN 082, "_______",
		      COLUMN 090, "________________",
		      COLUMN 107, "__________",
		      COLUMN 118, "_______________"
	END IF

ON EVERY ROW
	NEED 2 LINES
	LET expr_cli = ")"
	IF codcli IS NOT NULL THEN
		LET expr_cli = "   AND r19_codcli    = ", codcli, ")"
	END IF
	LET query = "SELECT r97_cod_tran, r97_num_tran,",
			" CAST(r38_num_sri[9, 21] AS INTEGER)",
			" FROM rept097, OUTER rept038",
			" WHERE r97_compania      = ", rm_r113.r113_compania,
			"   AND r97_localidad     = ", rm_r113.r113_localidad,
			"   AND r97_guia_remision = ",
					rm_hoja[i].r114_guia_remision,
			"   AND EXISTS",
				" (SELECT 1 FROM rept019",
					" WHERE r19_compania  = r97_compania",
					"   AND r19_localidad = r97_localidad",
					"   AND r19_cod_tran  = r97_cod_tran",
					"   AND r19_num_tran  = r97_num_tran",
					expr_cli CLIPPED,
			"  AND r38_compania      = r97_compania",
			"  AND r38_localidad     = r97_localidad",
			"  AND r38_tipo_fuente   = 'PR'",
			"  AND r38_cod_tran      = r97_cod_tran",
			"  AND r38_num_tran      = r97_num_tran",
			" ORDER BY 1, 2 "
	PREPARE cons_fac FROM query
	DECLARE q_r97 CURSOR FOR cons_fac
	LET col     = 43
	LET lin_doc = NULL
	FOREACH q_r97 INTO r_r19.r19_cod_tran, r_r19.r19_num_tran, num_sri
		LET lin_doc = r_r19.r19_cod_tran, "-",
				r_r19.r19_num_tran USING "<<<<<<&"
		IF num_sri IS NOT NULL THEN
			LET lin_doc = lin_doc CLIPPED, "(",
					num_sri USING "<<<<<<&", ")"
		END IF
		PRINT COLUMN col, lin_doc CLIPPED;
		LET col = col + LENGTH(lin_doc) + 2
		IF col > 120 THEN
			PRINT ' '
			LET col = 43
		END IF
	END FOREACH
	PRINT ' '
	SKIP 1 LINES

PAGE TRAILER
	SKIP 3 LINES
	PRINT COLUMN 003, "..............................",
	      COLUMN 100, ".............................."
	PRINT COLUMN 003, "       Firma Responsable      ",
	      COLUMN 100, "     Firma de Autorizacion    ";
	print ASCII escape;
	print ASCII act_10cpi;
	print ASCII escape;
	print ASCII desact_comp;

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
CASE rm_r113.r113_estado
	WHEN 'A' LET tit_estado = 'ACTIVO'
	WHEN 'P' LET tit_estado = 'EN PROCESO'
	WHEN 'C' LET tit_estado = 'CERRADO'
	WHEN 'E' LET tit_estado = 'ELIMINADO'
END CASE
DISPLAY BY NAME rm_r113.r113_estado, tit_estado

END FUNCTION



FUNCTION lee_cabecera(flag)
DEFINE flag		CHAR(1)
DEFINE r_g03		RECORD LIKE gent003.*
DEFINE r_r110		RECORD LIKE rept110.*
DEFINE r_r111		RECORD LIKE rept111.*
DEFINE r_r113		RECORD LIKE rept113.*
DEFINE r_r115		RECORD LIKE rept115.*
DEFINE resp		CHAR(6)

CALL fl_lee_transporte(rm_r113.r113_compania, rm_r113.r113_localidad,
			rm_r113.r113_cod_trans)
	RETURNING r_r110.*
CALL fl_lee_chofer(rm_r113.r113_compania, rm_r113.r113_localidad,
			rm_r113.r113_cod_trans, rm_r113.r113_cod_chofer)
	RETURNING r_r111.*
CALL fl_lee_ayudante(rm_r113.r113_compania, rm_r113.r113_localidad,
			rm_r113.r113_cod_trans, rm_r113.r113_cod_ayud)
	RETURNING r_r115.*
DISPLAY BY NAME r_r110.r110_descripcion, r_r110.r110_placa, r_r111.r111_nombre,
		r_r115.r115_nombre
LET int_flag = 0
INPUT BY NAME rm_r113.r113_cod_trans, rm_r113.r113_cod_chofer,
		rm_r113.r113_cod_ayud, rm_r113.r113_observacion,
		rm_r113.r113_areaneg, rm_r113.r113_km_ini, rm_r113.r113_km_fin
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF FIELD_TOUCHED(rm_r113.r113_cod_trans,rm_r113.r113_cod_chofer,
				 rm_r113.r113_cod_ayud,rm_r113.r113_observacion,
				 rm_r113.r113_areaneg, rm_r113.r113_km_ini,
				 rm_r113.r113_km_fin)
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
		IF rm_r113.r113_estado = 'P' AND flag = 'M' THEN
			CONTINUE INPUT
		END IF
		IF INFIELD(r113_cod_trans) THEN
			CALL fl_ayuda_transporte(vg_codcia, vg_codloc, "A")
				RETURNING r_r110.r110_cod_trans,
					  r_r110.r110_descripcion
		      	IF r_r110.r110_cod_trans IS NOT NULL THEN
				CALL fl_lee_transporte(vg_codcia, vg_codloc,
						r_r110.r110_cod_trans)
					RETURNING r_r110.*
				LET rm_r113.r113_cod_trans =
							r_r110.r110_cod_trans
				DISPLAY BY NAME rm_r113.r113_cod_trans,
						r_r110.r110_descripcion,
						r_r110.r110_placa
		      	END IF
		END IF
		IF INFIELD(r113_cod_chofer) AND
		   rm_r113.r113_cod_trans IS NOT NULL
		THEN
			CALL fl_ayuda_chofer(vg_codcia, vg_codloc,
						rm_r113.r113_cod_trans, "A")
				RETURNING r_r111.r111_cod_chofer,
					  r_r111.r111_nombre
		      	IF r_r111.r111_cod_chofer IS NOT NULL THEN
				LET rm_r113.r113_cod_chofer =
							r_r111.r111_cod_chofer
				DISPLAY BY NAME rm_r113.r113_cod_chofer,
						r_r111.r111_nombre
		      	END IF
		END IF
		IF INFIELD(r113_cod_ayud) AND
		   rm_r113.r113_cod_trans IS NOT NULL
		THEN
			CALL fl_ayuda_ayudante(vg_codcia, vg_codloc,
						rm_r113.r113_cod_trans, "A")
				RETURNING r_r115.r115_cod_ayud,
					  r_r115.r115_nombre
		      	IF r_r115.r115_cod_ayud IS NOT NULL THEN
				LET rm_r113.r113_cod_ayud = r_r115.r115_cod_ayud
				DISPLAY BY NAME rm_r113.r113_cod_ayud,
						r_r115.r115_nombre
		      	END IF
		END IF
		IF INFIELD(r113_areaneg) THEN
			CALL fl_ayuda_areaneg(vg_codcia)
				RETURNING r_g03.g03_areaneg, r_g03.g03_nombre
			IF r_g03.g03_areaneg IS NOT NULL THEN
				LET rm_r113.r113_areaneg = r_g03.g03_areaneg
				DISPLAY BY NAME rm_r113.r113_areaneg,
						r_g03.g03_nombre
			END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		INITIALIZE r_r113.* TO NULL
		IF rm_r113.r113_estado = 'P' AND flag = 'M' THEN
			LET r_r113.* = rm_r113.*
		END IF
	AFTER FIELD r113_cod_trans
		IF rm_r113.r113_estado = 'P' AND flag = 'M' THEN
			LET rm_r113.r113_cod_trans = r_r113.r113_cod_trans
			DISPLAY BY NAME rm_r113.r113_cod_trans
			CONTINUE INPUT
		END IF
		IF rm_r113.r113_cod_trans IS NOT NULL THEN
			CALL fl_lee_transporte(vg_codcia, vg_codloc,
						rm_r113.r113_cod_trans)
				RETURNING r_r110.*
			IF r_r110.r110_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Este transporte no existe en la compañía.', 'exclamation')
				NEXT FIELD r113_cod_trans
			END IF
			IF r_r110.r110_estado = "B" THEN
				CALL fl_mostrar_mensaje('Este transporte esta con estado BLOQUEADO.', 'exclamation')
				NEXT FIELD r113_cod_trans
			END IF
		ELSE
			INITIALIZE r_r110.*, r_r111.*, r_r115.*,
					rm_r113.r113_cod_chofer,
					rm_r113.r113_cod_ayud
				TO NULL
		END IF
		DISPLAY BY NAME r_r110.r110_descripcion, r_r110.r110_placa,
				rm_r113.r113_cod_chofer, r_r111.r111_nombre,
				rm_r113.r113_cod_ayud, r_r115.r115_nombre
	AFTER FIELD r113_cod_chofer
		IF rm_r113.r113_estado = 'P' AND flag = 'M' THEN
			LET rm_r113.r113_cod_chofer = r_r113.r113_cod_chofer
			DISPLAY BY NAME rm_r113.r113_cod_chofer
			CONTINUE INPUT
		END IF
		IF rm_r113.r113_cod_trans IS NULL THEN
			INITIALIZE r_r111.*, rm_r113.r113_cod_chofer TO NULL
			DISPLAY BY NAME rm_r113.r113_cod_chofer,
					r_r111.r111_nombre
			CONTINUE INPUT
		END IF
		IF rm_r113.r113_cod_chofer IS NOT NULL THEN
			CALL fl_lee_chofer(vg_codcia, vg_codloc,
						rm_r113.r113_cod_trans,
						rm_r113.r113_cod_chofer)
				RETURNING r_r111.*
			IF r_r111.r111_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Este chofer no existe en la compañía o no esta asociado a éste transporte.', 'exclamation')
				NEXT FIELD r113_cod_chofer
			END IF
			IF r_r111.r111_estado = "B" THEN
				CALL fl_mostrar_mensaje('Este chofer esta con estado BLOQUEADO.', 'exclamation')
				NEXT FIELD r113_cod_chofer
			END IF
		ELSE
			INITIALIZE r_r111.* TO NULL
		END IF
		DISPLAY BY NAME r_r111.r111_nombre
	AFTER FIELD r113_cod_ayud
		IF rm_r113.r113_estado = 'P' AND flag = 'M' THEN
			LET rm_r113.r113_cod_ayud = r_r113.r113_cod_ayud
			DISPLAY BY NAME rm_r113.r113_cod_ayud
			CONTINUE INPUT
		END IF
		IF rm_r113.r113_cod_trans IS NULL THEN
			INITIALIZE r_r115.*, rm_r113.r113_cod_ayud TO NULL
			DISPLAY BY NAME rm_r113.r113_cod_ayud,r_r115.r115_nombre
			CONTINUE INPUT
		END IF
		IF rm_r113.r113_cod_ayud IS NOT NULL THEN
			CALL fl_lee_ayudante(vg_codcia, vg_codloc,
						rm_r113.r113_cod_trans,
						rm_r113.r113_cod_ayud)
				RETURNING r_r115.*
			IF r_r115.r115_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Este ayudante no existe en la compañía o no esta asociado a éste transporte.', 'exclamation')
				NEXT FIELD r113_cod_ayud
			END IF
			IF r_r115.r115_estado = "B" THEN
				CALL fl_mostrar_mensaje('Este ayudante esta con estado BLOQUEADO.', 'exclamation')
				NEXT FIELD r113_cod_ayud
			END IF
		ELSE
			INITIALIZE r_r115.* TO NULL
		END IF
		DISPLAY BY NAME r_r115.r115_nombre
	AFTER FIELD r113_observacion
		IF rm_r113.r113_estado = 'P' AND flag = 'M' THEN
			LET rm_r113.r113_observacion = r_r113.r113_observacion
			DISPLAY BY NAME rm_r113.r113_observacion
			CONTINUE INPUT
		END IF
	AFTER FIELD r113_areaneg
		IF rm_r113.r113_estado = 'P' AND flag = 'M' THEN
			LET rm_r113.r113_areaneg = r_r113.r113_areaneg
			DISPLAY BY NAME rm_r113.r113_areaneg
			CONTINUE INPUT
		END IF
		IF rm_r113.r113_areaneg IS NOT NULL THEN
			CALL fl_lee_area_negocio(vg_codcia,rm_r113.r113_areaneg)
				RETURNING r_g03.*
			IF r_g03.g03_areaneg IS NULL THEN
				CALL fl_mostrar_mensaje('Area de Negocio no existe en la compañía.', 'exclamation')
				NEXT FIELD r113_areaneg
			END IF
			LET rm_r113.r113_areaneg = r_g03.g03_areaneg
		ELSE
			INITIALIZE r_g03.* TO NULL
		END IF
		DISPLAY BY NAME r_g03.g03_nombre
	AFTER FIELD r113_km_ini
		IF rm_r113.r113_estado = 'P' AND flag = 'M' THEN
			LET rm_r113.r113_km_ini = r_r113.r113_km_ini
			DISPLAY BY NAME rm_r113.r113_km_ini
			CONTINUE INPUT
		END IF
	AFTER FIELD r113_km_fin
		IF rm_r113.r113_km_fin IS NOT NULL THEN
			IF NOT fl_solo_numeros(rm_r113.r113_km_fin) THEN
				CALL fl_mostrar_mensaje('Digite solo números en el kilometraje final.', 'exclamation')
				NEXT FIELD r113_km_fin
			END IF
		END IF
	AFTER INPUT
		CALL fl_lee_chofer(vg_codcia, vg_codloc, rm_r113.r113_cod_trans,
					rm_r113.r113_cod_chofer)
			RETURNING r_r111.*
		IF r_r111.r111_compania IS NULL THEN
			CALL fl_mostrar_mensaje('Este chofer no existe en la compañía o no esta asociado a éste transporte.', 'exclamation')
			NEXT FIELD r113_cod_chofer
		END IF
		IF rm_r113.r113_km_ini IS NOT NULL AND
		   rm_r113.r113_km_fin IS NOT NULL
		THEN
			IF rm_r113.r113_km_ini >= rm_r113.r113_km_fin THEN
				CALL fl_mostrar_mensaje('El Km inicial debe ser menor que el Km final.', 'exclamation')
				NEXT FIELD r113_km_ini
			END IF
		END IF
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



FUNCTION lee_detalle()
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_z02		RECORD LIKE cxct002.*
DEFINE r_r95		RECORD LIKE rept095.*
DEFINE r_r112		RECORD LIKE rept112.*
DEFINE n_guia		LIKE rept095.r95_guia_remision
DEFINE n_hojrut		LIKE rept113.r113_num_hojrut
DEFINE n_hojrut_o	LIKE rept113.r113_num_hojrut
DEFINE i, j, max_row	SMALLINT
DEFINE num_row, ctos	SMALLINT
DEFINE hora_lleg	DATETIME HOUR TO MINUTE
DEFINE hora_sali	DATETIME HOUR TO MINUTE
DEFINE resp		CHAR(6)
DEFINE mens		VARCHAR(100)

LET n_hojrut = 0
IF rm_r113.r113_num_hojrut IS NOT NULL THEN
	LET n_hojrut = rm_r113.r113_num_hojrut
END IF
CALL control_mostrar_botones()
LET int_flag = 0
CALL set_count(vm_num_det) 
INPUT ARRAY rm_hoja WITHOUT DEFAULTS FROM rm_hoja.*
	ON KEY(INTERRUPT)
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp      
		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
	ON KEY(F2)
		IF rm_r113.r113_areaneg = 1 THEN
			IF INFIELD(r114_guia_remision) AND
			   rm_r113.r113_estado <> "P"
			THEN
				CALL fl_ayuda_guias_remision(vg_codcia,
							vg_codloc, "R")
					RETURNING n_guia
				IF n_guia IS NOT NULL THEN
					CALL fl_lee_guias_remision(vg_codcia,
							vg_codloc, n_guia)
						RETURNING r_r95.*
					LET rm_hoja[i].r114_guia_remision =
									n_guia
					DISPLAY rm_hoja[i].* TO rm_hoja[j].*
				END IF
			END IF
		END IF
		IF rm_r113.r113_areaneg = 2 THEN
			IF INFIELD(r114_guia_remision) AND
			   rm_r113.r113_estado <> "P"
			THEN
				CALL fl_ayuda_cliente_localidad(vg_codcia,
								vg_codloc)
					RETURNING r_z01.z01_codcli,
						  r_z01.z01_nomcli
				IF r_z01.z01_codcli IS NOT NULL THEN
					LET rm_hoja[i].r114_guia_remision =
								r_z01.z01_codcli
					DISPLAY rm_hoja[i].* TO rm_hoja[j].*
				END IF
			END IF
		END IF
		IF INFIELD(r112_descripcion) THEN
			CALL fl_ayuda_obsers(vg_codcia, vg_codloc, "T", "A")
				RETURNING r_r112.r112_cod_obser,
					  r_r112.r112_descripcion
			IF r_r112.r112_cod_obser IS NOT NULL THEN
				LET rm_codhoj[i].r114_cod_obser =
							r_r112.r112_cod_obser
				LET rm_hoja[i].r112_descripcion =
							r_r112.r112_descripcion
				DISPLAY rm_hoja[i].r112_descripcion TO
					rm_hoja[j].r112_descripcion
			END IF
		END IF
		LET int_flag = 0
	ON KEY(F5)
		CALL ver_guia(rm_hoja[i].r114_guia_remision)
		LET int_flag = 0
	BEFORE INPUT
		IF rm_r113.r113_estado = "P" THEN
			CALL dialog.keysetlabel('INSERT','')
			CALL dialog.keysetlabel('DELETE','')
		END IF
	BEFORE INSERT
		IF rm_r113.r113_estado = "P" THEN
			CANCEL INSERT
		END IF
	BEFORE DELETE
		IF rm_r113.r113_estado = "P" THEN
			CANCEL DELETE
		END IF
	BEFORE ROW
		LET i       = arr_curr()
		LET j       = scr_line()
		LET num_row = arr_count()
		IF i > num_row THEN
			LET num_row = num_row + 1
		END IF
		CALL muestra_etiquetas_det(i, num_row)
	BEFORE FIELD r114_guia_remision
		IF rm_r113.r113_estado = "P" THEN
			LET n_guia = rm_hoja[i].r114_guia_remision
		END IF
	BEFORE FIELD r114_hora_lleg
		LET hora_lleg = rm_hoja[i].r114_hora_lleg
	BEFORE FIELD r114_hora_sali
		LET hora_sali = rm_hoja[i].r114_hora_sali
	AFTER FIELD r114_guia_remision
		IF rm_r113.r113_estado = "P" THEN
			LET rm_hoja[i].r114_guia_remision = n_guia
			DISPLAY rm_hoja[i].r114_guia_remision TO
				rm_hoja[j].r114_guia_remision
			CONTINUE INPUT
		END IF
		IF rm_r113.r113_areaneg <> 1 THEN
			IF rm_hoja[i].r114_guia_remision IS NOT NULL THEN
				CALL fl_lee_cliente_general(
						rm_hoja[i].r114_guia_remision)
					RETURNING r_z01.*
				IF r_z01.z01_codcli IS NULL THEN
					CALL fl_mostrar_mensaje('Cliente no existe.', 'exclamation')
					NEXT FIELD r114_guia_remision
				END IF
				LET rm_hoja[i].r114_guia_remision =
								r_z01.z01_codcli
				DISPLAY rm_hoja[i].r114_guia_remision TO
					rm_hoja[j].r114_guia_remision
				CALL fl_lee_cliente_localidad(vg_codcia,
						vg_codloc, r_z01.z01_codcli)
					RETURNING r_z02.*
				IF r_z02.z02_compania IS NULL THEN
					CALL fl_mostrar_mensaje('Cliente no está activado para esta Localidad.', 'exclamation')
					NEXT FIELD r114_guia_remision
				END IF
			END IF
			CONTINUE INPUT
		END IF
		IF rm_hoja[i].r114_guia_remision IS NOT NULL THEN
			CALL fl_lee_guias_remision(vg_codcia, vg_codloc,
						rm_hoja[i].r114_guia_remision)
				RETURNING r_r95.*
			IF r_r95.r95_guia_remision IS NULL THEN
				CALL fl_mostrar_mensaje("No existe este número de guía de remisión.", 'exclamation')
				NEXT FIELD r114_guia_remision
			END IF
			IF r_r95.r95_estado <> "C" THEN
				CALL fl_mostrar_mensaje("La guía de remisión no esta CERRADA.", 'exclamation')
				NEXT FIELD r114_guia_remision
			END IF
			LET n_hojrut_o = NULL
			SELECT UNIQUE r114_num_hojrut
				INTO n_hojrut_o
				FROM rept113, rept114
				WHERE r113_compania       = vg_codcia
				  AND r113_localidad      = vg_codloc
				  AND r113_num_hojrut    <> n_hojrut
				  AND r113_estado        <> "E"
				  AND r114_compania       = r113_compania
				  AND r114_localidad      = r113_localidad
				  AND r114_num_hojrut     = r113_num_hojrut
				  AND r114_guia_remision  =
						rm_hoja[i].r114_guia_remision
				  AND r114_estado         = "E"
			IF n_hojrut_o IS NOT NULL THEN
				LET mens = "La guía de remisión esta asignada ",
					"al control de ruta No. ",
					n_hojrut_o USING "<<<<<<&", "."
				CALL fl_mostrar_mensaje(mens, 'exclamation')
				NEXT FIELD r114_guia_remision
			END IF
		ELSE
			INITIALIZE rm_hoja[i].r114_guia_remision TO NULL
		END IF
		DISPLAY rm_hoja[i].* TO rm_hoja[j].*
		CALL muestra_etiquetas_det(i, num_row)
	AFTER FIELD r114_hora_lleg
		IF rm_hoja[i].r114_hora_lleg IS NULL THEN
			LET rm_hoja[i].r114_hora_lleg = hora_lleg
			DISPLAY rm_hoja[i].r114_hora_lleg TO
				rm_hoja[j].r114_hora_lleg
			IF rm_r113.r113_estado = "P" THEN
				CALL fl_mostrar_mensaje('Debe digitar la hora de llegada, para poder continuar.', 'exclamation')
				NEXT FIELD r114_hora_lleg
			END IF
		END IF
		IF rm_hoja[i].r114_hora_lleg >= rm_hoja[i].r114_hora_sali THEN
			CALL fl_mostrar_mensaje('La hora de llegada debe ser menor que la hora de salida.', 'exclamation')
			NEXT FIELD r114_hora_lleg
		END IF
	AFTER FIELD r114_hora_sali
		IF rm_hoja[i].r114_hora_sali IS NULL THEN
			LET rm_hoja[i].r114_hora_sali = hora_sali
			DISPLAY rm_hoja[i].r114_hora_sali TO
				rm_hoja[j].r114_hora_sali
			IF rm_r113.r113_estado = "P" THEN
				CALL fl_mostrar_mensaje('Debe digitar la hora de salida, para poder continuar.', 'exclamation')
				NEXT FIELD r114_hora_sali
			END IF
		END IF
		IF rm_hoja[i].r114_hora_sali <= rm_hoja[i].r114_hora_lleg THEN
			CALL fl_mostrar_mensaje('La hora de salida debe ser mayor que la hora de llegada.', 'exclamation')
			NEXT FIELD r114_hora_sali
		END IF
	AFTER FIELD r112_descripcion
		IF rm_hoja[i].r112_descripcion IS NULL THEN
			CONTINUE INPUT
		END IF
		SELECT COUNT(*) INTO ctos
			FROM rept112
			WHERE r112_compania    = vg_codcia
			  AND r112_localidad   = vg_codloc
			  AND r112_descripcion = rm_hoja[i].r112_descripcion
		IF ctos = 0 THEN
			CALL fl_mostrar_mensaje('Tipo de observación no existe.', 'exclamation')
			NEXT FIELD r112_descripcion
		END IF
	AFTER FIELD r114_recibido_por
		IF rm_hoja[i].r114_recibido_por IS NULL AND
		   rm_r113.r113_estado = "P"
		THEN
			CALL fl_mostrar_mensaje('Debe digitar el campo Recibido Por, para poder continuar.', 'exclamation')
			NEXT FIELD r114_recibido_por
		END IF
	AFTER INSERT
		IF rm_r113.r113_estado <> "P" THEN
			LET num_row = arr_count()
		END IF
	AFTER DELETE
		IF rm_r113.r113_estado <> "P" THEN
			LET num_row = arr_count()
		END IF
	AFTER INPUT
		FOR i = 1 TO num_row
			IF (rm_hoja[i].r114_hora_lleg IS NULL  OR
			    rm_hoja[i].r114_hora_sali IS NULL  OR
			    rm_hoja[i].r114_recibido_por IS NULL) AND
			   rm_r113.r113_estado = "P"
			THEN
				CONTINUE INPUT
			END IF
		END FOR
		IF rm_hoja[num_row].r114_guia_remision IS NULL AND
		   rm_r113.r113_areaneg = 1
		THEN
			CALL fl_mostrar_mensaje("Digite una guía de remisión en este registro.", "exclamation")
			NEXT FIELD r114_guia_remision
		END IF
		FOR i = 1 TO num_row - 1
			FOR j = i + 1 TO num_row
				IF rm_hoja[i].r114_guia_remision =
				   rm_hoja[j].r114_guia_remision
				THEN
					LET mens = "El No. Guía de Remisión ",
						rm_hoja[i].r114_guia_remision USING "<<<<<<&",
						" esta repetido. "
					CALL fl_mostrar_mensaje(mens,
								"exclamation")
					CONTINUE INPUT
				END IF
			END FOR
		END FOR
		LET vm_num_det = arr_count()
END INPUT 

END FUNCTION



FUNCTION grabar_detalle()
DEFINE i		SMALLINT

FOR i = 1 TO vm_num_det
	INITIALIZE rm_r114.* TO NULL
	LET rm_r114.r114_compania      = rm_r113.r113_compania
	LET rm_r114.r114_localidad     = rm_r113.r113_localidad
	LET rm_r114.r114_num_hojrut    = rm_r113.r113_num_hojrut
	LET rm_r114.r114_secuencia     = i
	IF rm_r113.r113_areaneg = 1 THEN
		LET rm_r114.r114_guia_remision = rm_hoja[i].r114_guia_remision
	ELSE
		LET rm_r114.r114_codcli        = rm_hoja[i].r114_guia_remision
	END IF
	INITIALIZE rm_codhoj[i].* TO NULL
	SELECT r95_num_sri,
		(SELECT r108_descripcion
			FROM rept108
			WHERE r108_compania  = r95_compania
			  AND r108_localidad = r95_localidad
			  AND r108_cod_zona  = r95_cod_zona),
		(SELECT r109_descripcion
			FROM rept109
			WHERE r109_compania    = r95_compania
			  AND r109_localidad   = r95_localidad
			  AND r109_cod_zona    = r95_cod_zona
			  AND r109_cod_subzona = r95_cod_subzona),
		r95_cod_zona, r95_cod_subzona
		INTO rm_codhoj[i].*
		FROM rept095
		WHERE r95_compania      = rm_r113.r113_compania
		  AND r95_localidad     = rm_r113.r113_localidad
		  AND r95_guia_remision = rm_hoja[i].r114_guia_remision
	LET rm_r114.r114_cod_zona      = rm_codhoj[i].r114_cod_zona
	LET rm_r114.r114_cod_subzona   = rm_codhoj[i].r114_cod_subzona
	LET rm_r114.r114_hora_lleg     = rm_hoja[i].r114_hora_lleg
	LET rm_r114.r114_hora_sali     = rm_hoja[i].r114_hora_sali
	LET rm_r114.r114_recibido_por  = rm_hoja[i].r114_recibido_por
	LET rm_r114.r114_estado = "E"
	IF rm_hoja[i].r112_descripcion IS NOT NULL THEN
		SELECT r112_cod_obser
			INTO rm_codhoj[i].r114_cod_obser
			FROM rept112
			WHERE r112_compania    = rm_r113.r113_compania
			  AND r112_localidad   = rm_r113.r113_localidad
			  AND r112_descripcion = rm_hoja[i].r112_descripcion
		LET rm_r114.r114_cod_obser = rm_codhoj[i].r114_cod_obser
		LET rm_r114.r114_estado    = "N"
	END IF
	INSERT INTO rept114 VALUES (rm_r114.*)
END FOR

END FUNCTION



FUNCTION lee_muestra_registro(row)
DEFINE row		INTEGER
DEFINE r_g03		RECORD LIKE gent003.*
DEFINE r_r110		RECORD LIKE rept110.*
DEFINE r_r111		RECORD LIKE rept111.*
DEFINE r_r115		RECORD LIKE rept115.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_r113.* FROM rept113 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', row
END IF
CALL control_mostrar_botones()
DISPLAY BY NAME rm_r113.r113_num_hojrut, rm_r113.r113_estado,
		rm_r113.r113_observacion, rm_r113.r113_fecha,
		rm_r113.r113_km_ini, rm_r113.r113_km_fin,
		rm_r113.r113_cod_trans, rm_r113.r113_cod_chofer,
		rm_r113.r113_cod_ayud, rm_r113.r113_areaneg,
		rm_r113.r113_usu_cierre, rm_r113.r113_fec_cierre,
		rm_r113.r113_usu_elim, rm_r113.r113_fec_elim,
		rm_r113.r113_usuario, rm_r113.r113_fecing
CALL fl_lee_transporte(rm_r113.r113_compania, rm_r113.r113_localidad,
			rm_r113.r113_cod_trans)
	RETURNING r_r110.*
CALL fl_lee_chofer(rm_r113.r113_compania, rm_r113.r113_localidad,
			rm_r113.r113_cod_trans, rm_r113.r113_cod_chofer)
	RETURNING r_r111.*
CALL fl_lee_ayudante(rm_r113.r113_compania, rm_r113.r113_localidad,
			rm_r113.r113_cod_trans, rm_r113.r113_cod_ayud)
	RETURNING r_r115.*
CALL fl_lee_area_negocio(vg_codcia, rm_r113.r113_areaneg) RETURNING r_g03.*
DISPLAY BY NAME r_r110.r110_descripcion, r_r110.r110_placa, r_r111.r111_nombre,
		r_r115.r115_nombre, r_g03.g03_nombre
CALL muestra_estado()
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_detalle()

END FUNCTION



FUNCTION muestra_detalle()
DEFINE i		SMALLINT

CALL borrar_detalle()
CALL generar_temp_det()
CALL cargar_det_temp()
IF vm_num_det = 0 THEN 
	DROP TABLE tmp_detalle
	RETURN
END IF
IF vm_num_det < vm_size_arr THEN 
	LET vm_size_arr = vm_num_det
END IF 
FOR i = 1 TO vm_size_arr 
	DISPLAY rm_hoja[i].* TO rm_hoja[i].*
END FOR 
SELECT COUNT(*) INTO vm_num_det FROM tmp_detalle
DROP TABLE tmp_detalle
CALL muestra_etiquetas_det(0, vm_num_det)

END FUNCTION



FUNCTION generar_temp_det()
DEFINE query		CHAR(2000)
DEFINE expr_est		VARCHAR(100)

LET expr_est = NULL
IF rm_r113.r113_estado <> "A" AND rm_r113.r113_estado <> "P" THEN
	LET expr_est = "   AND r114_estado       = 'E'"
END IF
LET query = "SELECT r114_guia_remision, r114_hora_lleg, r114_hora_sali,",
		" (SELECT r112_descripcion",
		" FROM rept112",
		" WHERE r112_compania  = r114_compania",
		"   AND r112_localidad = r114_localidad",
		"   AND r112_cod_obser = r114_cod_obser) r112_descripcion,",
		" r114_recibido_por, r95_num_sri,",
		" (SELECT r108_descripcion",
		" FROM rept108",
		" WHERE r108_compania  = r114_compania",
		"   AND r108_localidad = r114_localidad",
		"   AND r108_cod_zona  = r114_cod_zona) r108_descripcion,",
		" (SELECT r109_descripcion",
		" FROM rept109",
		" WHERE r109_compania    = r114_compania",
		"   AND r109_localidad   = r114_localidad",
		"   AND r109_cod_zona    = r114_cod_zona",
		"   AND r109_cod_subzona = r114_cod_subzona) r109_descripcion,",
		" r114_cod_zona, r114_cod_subzona, r114_cod_obser, r114_codcli",
		" FROM rept114, OUTER rept095",
		" WHERE r114_compania     = ", rm_r113.r113_compania,
		"   AND r114_localidad    = ", rm_r113.r113_localidad,
		"   AND r114_num_hojrut   = ", rm_r113.r113_num_hojrut,
		expr_est CLIPPED,
		"   AND r95_compania      = r114_compania",
		"   AND r95_localidad     = r114_localidad",
		"   AND r95_guia_remision = r114_guia_remision",
		" INTO TEMP tmp_detalle"
PREPARE exec_tmp FROM query
EXECUTE exec_tmp

END FUNCTION



FUNCTION cargar_det_temp()
DEFINE codcli		LIKE rept114.r114_codcli

DECLARE q_hoja CURSOR FOR
	SELECT * FROM tmp_detalle
LET vm_num_det = 1
FOREACH q_hoja INTO rm_hoja[vm_num_det].*, rm_codhoj[vm_num_det].*, codcli
	IF rm_r113.r113_areaneg <> 1 THEN
		LET rm_hoja[vm_num_det].r114_guia_remision = codcli
	END IF
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
DEFINE num_sri		LIKE rept095.r95_num_sri
DEFINE desc_zon		LIKE rept108.r108_descripcion
DEFINE desc_sub		LIKE rept109.r109_descripcion

CALL muestra_contadores_det(num_row, max_row)
IF num_row = 0 THEN
	LET num_row = 1
END IF
INITIALIZE num_sri, desc_zon, desc_sub TO NULL
SELECT r95_num_sri,
	(SELECT r108_descripcion
		FROM rept108
		WHERE r108_compania  = r95_compania
		  AND r108_localidad = r95_localidad
		  AND r108_cod_zona  = r95_cod_zona),
	(SELECT r109_descripcion
		FROM rept109
		WHERE r109_compania    = r95_compania
		  AND r109_localidad   = r95_localidad
		  AND r109_cod_zona    = r95_cod_zona
		  AND r109_cod_subzona = r95_cod_subzona)
	INTO num_sri, desc_zon, desc_sub
	FROM rept095
	WHERE r95_compania      = rm_r113.r113_compania
	  AND r95_localidad     = rm_r113.r113_localidad
	  AND r95_guia_remision = rm_hoja[num_row].r114_guia_remision
DISPLAY num_sri  TO r95_num_sri
DISPLAY desc_zon TO r108_descripcion
DISPLAY desc_sub TO r109_descripcion

END FUNCTION



FUNCTION ver_guia(n_guia)
DEFINE n_guia		LIKE rept114.r114_guia_remision
DEFINE run_prog		CHAR(10)
DEFINE comando		VARCHAR(200)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando  = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS',
		vg_separador, 'fuentes', vg_separador, run_prog CLIPPED,
		' repp241 ', vg_base, ' ', vg_modulo, ' ', vg_codcia, ' ',
		vg_codloc, ' ', n_guia
RUN comando

END FUNCTION
