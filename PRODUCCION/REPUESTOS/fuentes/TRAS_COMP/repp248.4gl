--------------------------------------------------------------------------------
-- Titulo           : repp248.4gl - Composición de ítems
-- Elaboracion      : 17-May-2010
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp248 base módulo compañía localidad
--			[composición]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_rows		ARRAY [20000] OF INTEGER
DEFINE vm_row_current	SMALLINT
DEFINE vm_num_rows	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE rm_orden 	ARRAY[15] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE rm_r46		RECORD LIKE rept046.*
DEFINE rm_detalle	ARRAY [20000] OF RECORD
				r47_bodega_part	LIKE rept047.r47_bodega_part,
				r47_item_part	LIKE rept047.r47_item_part,
				r47_desc_part	LIKE rept047.r47_desc_part,
				r47_cantidad	LIKE rept047.r47_cantidad,
				r47_costo_part	LIKE rept047.r47_costo_part,
				r47_marca_p	LIKE rept047.r47_marca_p
			END RECORD
DEFINE rm_adi		ARRAY [20000] OF RECORD
				r47_division_p	LIKE rept047.r47_division_p,
				r47_sub_linea_p	LIKE rept047.r47_sub_linea_p,
				r47_cod_grupo_p	LIKE rept047.r47_cod_grupo_p,
				r47_cod_clase_p	LIKE rept047.r47_cod_clase_p,
				r47_nom_div_p	LIKE rept047.r47_nom_div_p,
				r47_desc_sub_p	LIKE rept047.r47_desc_sub_p,
				r47_desc_grupo_p LIKE rept047.r47_desc_grupo_p,
				r47_desc_clase_p LIKE rept047.r47_desc_clase_p,
				r47_desc_marca_p LIKE rept047.r47_desc_marca_p,
				descripcion	LIKE rept047.r47_desc_part
			END RECORD
DEFINE rm_g01		RECORD LIKE gent001.*
DEFINE rm_g04		RECORD LIKE gent004.*
DEFINE rm_g05		RECORD LIKE gent005.*
DEFINE rm_r00		RECORD LIKE rept000.*
DEFINE rm_r01		RECORD LIKE rept001.*
DEFINE vm_bod_comp	LIKE rept002.r02_codigo
DEFINE r_loc 	   	ARRAY[50] OF RECORD
				bod_loc		LIKE rept002.r02_codigo,
				nom_bod_loc	LIKE rept002.r02_nombre,
				stock_loc	LIKE rept011.r11_stock_act
			END RECORD
DEFINE r_rem		ARRAY[50] OF RECORD
				bod_rem		LIKE rept002.r02_codigo,
				nom_bod_rem	LIKE rept002.r02_nombre,
				stock_rem	LIKE rept011.r11_stock_act
			END RECORD
DEFINE i_loc, i_rem	SMALLINT
DEFINE vm_est_ant	CHAR(1)
DEFINE vm_item_nue	CHAR(6)



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp248.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 THEN   -- Validar # parÃ¡metros correcto
	CALL fl_mostrar_mensaje('NÃºmero de parametros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'repp248'
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
CALL fl_lee_compania_repuestos(vg_codcia) RETURNING rm_r00.*
IF rm_r00.r00_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No esta creada una compaÃ±Ã­a para el mÃ³dulo de inventarios.','stop')
	RETURN
END IF
IF rm_r00.r00_estado <> 'A' THEN
	CALL fl_mostrar_mensaje('La compania esta con estado BLOQUEADO.','stop')
	RETURN
END IF
IF num_args() = 4 THEN
	CALL fl_chequeo_mes_proceso_rep(vg_codcia) RETURNING int_flag
	IF int_flag THEN
		RETURN
	END IF
END IF
CALL fl_lee_usuario(vg_usuario) RETURNING rm_g05.*
CALL fl_lee_grupo_usuario(rm_g05.g05_grupo) RETURNING rm_g04.*
INITIALIZE rm_r01.* TO NULL
DECLARE qu_vd CURSOR FOR
	SELECT * FROM rept001
		WHERE r01_compania   = vg_codcia
		  AND r01_user_owner = vg_usuario
OPEN qu_vd
FETCH qu_vd INTO rm_r01.*
IF STATUS = NOTFOUND THEN
	--IF rm_g05.g05_tipo = 'UF' THEN
		FREE qu_vd
		CALL fl_mostrar_mensaje('Usted no esta configurado en la tabla de vendedores/bodegueros.','stop')
		RETURN
	--END IF
END IF
FREE qu_vd
LET vm_bod_comp = NULL
SQL
	SELECT r02_codigo
		INTO $vm_bod_comp
		FROM rept002
		WHERE r02_compania   = $vg_codcia
		  AND r02_localidad  = $vg_codloc
		  AND r02_area       = "T"
		  AND r02_tipo_ident = "E"
END SQL
IF vm_bod_comp IS NULL THEN
	CALL fl_mostrar_mensaje('No existe la bodega de composición para esta localidad.', 'stop')
	RETURN
END IF
LET vm_max_det     = 20000
LET vm_row_current = 0
LET vm_num_rows	   = 0
LET vm_max_rows    = 20000
LET lin_menu       = 0
LET row_ini        = 3
LET num_rows       = 22
LET num_cols       = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_repf248_1 AT row_ini, 02 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_repf248_1 FROM "../forms/repf248_1"
ELSE
	OPEN FORM f_repf248_1 FROM "../forms/repf248_1c"
END IF
DISPLAY FORM f_repf248_1
CALL fl_lee_compania(vg_codcia) RETURNING rm_g01.*
CALL muestra_contadores(0, 0)
CALL muestra_contadores_det(0, 0)
CALL borrar_cabecera()
CALL borrar_detalle()
CALL mostrar_cabecera_forma()
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Cerrar'
		HIDE OPTION 'Ver Item'
		HIDE OPTION 'Ver Detalle'
		HIDE OPTION 'Imprimir'
		IF num_args() = 5 THEN
			HIDE OPTION 'Ingresar'                                  
			HIDE OPTION 'Consultar'                                 
			SHOW OPTION 'Ver Item'
			SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Imprimir'                                  
			CALL control_consulta()                                 
			CALL control_ver_detalle()
			EXIT MENU
		END IF                                                          
	COMMAND KEY('I') 'Ingresar' 'Crea Estructura de Composición.'
		HIDE OPTION 'Imprimir'
		CALL control_ingreso()
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
		IF vm_row_current > 0 THEN
			SHOW OPTION 'Modificar'
			IF rm_r46.r46_estado = 'C' THEN
				HIDE OPTION 'Cerrar'
			ELSE
				SHOW OPTION 'Cerrar'
			END IF
			SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Ver Item'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
		END IF
	COMMAND KEY('C') 'Consultar' 'Consultar un registro.'
		HIDE OPTION 'Imprimir'
		CALL control_consulta()
		IF vm_num_rows < 1 THEN
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Modificar'
			IF rm_r46.r46_estado = 'C' THEN
				HIDE OPTION 'Cerrar'
			ELSE
				SHOW OPTION 'Cerrar'
			END IF
			SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Ver Item'
			SHOW OPTION 'Imprimir'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				IF rm_r46.r46_estado = 'C' OR
				   rm_r46.r46_estado IS NULL
				THEN
					HIDE OPTION 'Cerrar'
				ELSE
					SHOW OPTION 'Cerrar'
				END IF
				HIDE OPTION 'Ver Detalle'
				HIDE OPTION 'Ver Item'
				HIDE OPTION 'Imprimir'
			END IF
		ELSE
			SHOW OPTION 'Modificar'
			IF rm_r46.r46_estado = 'C' THEN
				HIDE OPTION 'Cerrar'
			ELSE
				SHOW OPTION 'Cerrar'
			END IF
			SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Ver Item'
			SHOW OPTION 'Imprimir'
			IF vm_num_rows = 1 THEN
				HIDE OPTION 'Avanzar'
				HIDE OPTION 'Retroceder'
			ELSE
				SHOW OPTION 'Avanzar'
			END IF
		END IF
        COMMAND KEY('M') 'Modificar' 'Modifica Estructura de Composición.'
		CALL control_modificacion()
        COMMAND KEY('Y') 'Cerrar' 'Cierra Estructura de Composición.'
		CALL control_cerrar()
		IF rm_r46.r46_estado = 'C' THEN
			HIDE OPTION 'Cerrar'
		ELSE
			SHOW OPTION 'Cerrar'
		END IF
        COMMAND KEY('P') 'Imprimir' 'Imprime estructura de composición.'
		CALL control_imprimir_comp()
	COMMAND KEY('X') 'Ver Item' 'Muestra el ítem compuesto.'
		CALL mostrar_item(rm_r46.r46_item_comp)
	COMMAND KEY('D') 'Ver Detalle' 'Ver detalle del Registro.'
		IF vm_num_rows > 0 THEN
			CALL control_ver_detalle()
		ELSE
			CALL fl_mensaje_consultar_primero()
		END IF
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
		HIDE OPTION 'Imprimir'
		CALL siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF rm_r46.r46_estado = 'C' THEN
			HIDE OPTION 'Cerrar'
		ELSE
			SHOW OPTION 'Cerrar'
		END IF
                IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
                END IF
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
		HIDE OPTION 'Imprimir'
		CALL anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF rm_r46.r46_estado = 'C' THEN
			HIDE OPTION 'Cerrar'
		ELSE
			SHOW OPTION 'Cerrar'
		END IF
                IF vm_num_rows > 0 THEN
                	SHOW OPTION 'Imprimir'
                END IF
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU
CLOSE WINDOW w_repf248_1
EXIT PROGRAM

END FUNCTION



FUNCTION control_ingreso()
DEFINE comentarios	LIKE rept010.r10_comentarios
DEFINE coderr		INTEGER
DEFINE ses_id		INTEGER
DEFINE comando		CHAR(400)
DEFINE prog		VARCHAR(10)

CALL borrar_cabecera()
CALL borrar_detalle()
LET int_flag = 0
CALL fl_hacer_pregunta('Usted va a generar una composición con un ítem NUEVO ?', 'Yes')
	RETURNING vm_item_nue
IF vm_item_nue = 'Yes' THEN
	{--
	SQL
		SELECT r10_codigo
			INTO $rm_r46.r46_item_comp
			FROM rept010
			WHERE r10_compania = $vg_codcia
			  AND r10_estado   = "B"
			  AND r10_costo_mb < 0
			  AND r10_usuario  = $vg_usuario
	END SQL
	--}
	IF rm_r46.r46_item_comp IS NULL THEN
		SQL
			SELECT DBINFO('sessionid') INTO $ses_id FROM dual
		END SQL
		LET comentarios = '$ SID : ', ses_id USING "<<<<<<&"
		LET prog        = 'repp108'
		IF NOT fl_control_acceso_proceso_men(vg_usuario, vg_codcia,
							vg_modulo, prog)
		THEN
			CALL mostrar_salir()
			RETURN
		END IF
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
			'REPUESTOS', vg_separador, 'fuentes', vg_separador,
			'; fglrun ', prog CLIPPED, ' ', vg_base, ' ', vg_modulo,
			' ', vg_codcia, ' ', vg_codloc, ' C "',
			comentarios CLIPPED, '"'
		RUN comando RETURNING coderr
		IF coderr <> 0 THEN
			--CALL mostrar_salir()
			--RETURN
		END IF
	END IF
END IF
LET rm_r46.r46_compania    = vg_codcia
LET rm_r46.r46_localidad   = vg_codloc
IF rm_r46.r46_item_comp IS NULL THEN
	SQL
		SELECT r10_codigo
			INTO $rm_r46.r46_item_comp
			FROM rept010
			WHERE r10_compania    = $vg_codcia
			  AND r10_estado      = "B"
			  AND r10_costo_mb    < 0
			  AND r10_comentarios = $comentarios
			  AND r10_usuario     = $vg_usuario
	END SQL
END IF
IF rm_r46.r46_item_comp IS NULL AND vm_item_nue = 'Yes' THEN
	CALL fl_mostrar_mensaje('Debe ingresar el ítem para pode continuar con el proceso de composición.', 'exclamation')
	CALL mostrar_salir()
	RETURN
END IF
IF NOT genera_datos(1) THEN
	RETURN
END IF
CALL control_imprimir_comp()
CALL fl_mostrar_mensaje('Estructura de Composición Generada OK.', 'info')

END FUNCTION



FUNCTION genera_datos(flag)
DEFINE flag		SMALLINT
DEFINE num_aux		INTEGER

LET vm_est_ant             = rm_r46.r46_estado
CALL datos_item_cab(rm_r46.r46_item_comp)
LET rm_r46.r46_cod_ventas  = rm_r01.r01_codigo
LET rm_r46.r46_tiene_oc    = 'N'
LET rm_r46.r46_usuario     = vg_usuario
LET rm_r46.r46_fecing      = CURRENT
DISPLAY BY NAME rm_r46.r46_tiene_oc, rm_r46.r46_cod_ventas, rm_r01.r01_nombres,
		rm_r46.r46_usuario, rm_r46.r46_fecing
IF NOT leer_datos_comp('I', flag) THEN
	RETURN 0
END IF
BEGIN WORK
	CALL generar_cabecera_composicion() RETURNING num_aux
	IF NOT generar_detalle_composicion('I', flag) THEN
		ROLLBACK WORK
		CALL mostrar_salir()
		RETURN 0
	END IF
COMMIT WORK
CALL mostrar_nuevo_reg(num_aux, 'I')
RETURN 1

END FUNCTION



FUNCTION control_modificacion()
DEFINE resul		SMALLINT

CALL lee_muestra_registro(vm_rows[vm_row_current])
IF rm_r46.r46_estado = 'C' THEN
	CALL fl_mostrar_mensaje('No puede modificar la estructura de un ítem que esta compuesta.', 'exclamation')
	RETURN
END IF
IF vm_item_nue IS NULL THEN
	LET vm_item_nue = 'Yes'
END IF
BEGIN WORK
	WHENEVER ERROR CONTINUE
	DECLARE q_up CURSOR FOR
		SELECT * FROM rept046
			WHERE ROWID = vm_rows[vm_row_current]
		FOR UPDATE
	OPEN q_up
	FETCH q_up INTO rm_r46.*
	IF STATUS < 0 THEN
		WHENEVER ERROR STOP
		ROLLBACK WORK
		CALL fl_mensaje_bloqueo_otro_usuario()
		RETURN
	END IF
	WHENEVER ERROR STOP
	IF NOT leer_datos_comp('M', 1) THEN
		ROLLBACK WORK
		RETURN
	END IF
	LET rm_r46.r46_usu_modifi = vg_usuario
	LET rm_r46.r46_fec_modifi = CURRENT
	WHENEVER ERROR CONTINUE
	UPDATE rept046
		SET * = rm_r46.*
		WHERE r46_compania    = rm_r46.r46_compania
		  AND r46_localidad   = rm_r46.r46_localidad
		  AND r46_composicion = rm_r46.r46_composicion
		  AND r46_item_comp   = rm_r46.r46_item_comp
	IF STATUS <> 0 THEN
		ROLLBACK WORK
		WHENEVER ERROR STOP
		CALL fl_mostrar_mensaje('No se puede actualizar la estructura. Por favor llame al ADMINISTRADOR.', 'stop')
		CALL mostrar_salir()
		RETURN
	END IF
	WHENEVER ERROR STOP
	IF NOT generar_detalle_composicion('M', 1) THEN
		ROLLBACK WORK
		CALL mostrar_salir()
		RETURN
	END IF
COMMIT WORK
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mostrar_mensaje('Estructura de Composición Modificada OK.', 'info')

END FUNCTION



FUNCTION control_cerrar()
DEFINE resul		SMALLINT

CALL lee_muestra_registro(vm_rows[vm_row_current])
IF rm_r46.r46_estado = 'C' THEN
	CALL fl_mostrar_mensaje('No puede cerrar la estructura de un ítem que esta compuesto.', 'exclamation')
	RETURN
END IF
BEGIN WORK
	WHENEVER ERROR CONTINUE
	DECLARE q_up2 CURSOR FOR
		SELECT * FROM rept046
			WHERE ROWID = vm_rows[vm_row_current]
		FOR UPDATE
	OPEN q_up2
	FETCH q_up2 INTO rm_r46.*
	IF STATUS < 0 THEN
		WHENEVER ERROR STOP
		ROLLBACK WORK
		CALL fl_mensaje_bloqueo_otro_usuario()
		RETURN
	END IF
	WHENEVER ERROR CONTINUE
	UPDATE rept046
		SET r46_estado     = 'C',
		    r46_usu_cierre = vg_usuario,
		    r46_fec_cierre = CURRENT
		WHERE CURRENT OF q_up2
	IF STATUS <> 0 THEN
		ROLLBACK WORK
		WHENEVER ERROR STOP
		CALL fl_mostrar_mensaje('No se puede cerrar la composición. Por favor llame al ADMINISTRADOR.', 'stop')
		RETURN
	END IF
	WHENEVER ERROR STOP
COMMIT WORK
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mostrar_mensaje('Estructura de Composición Cerrada OK.', 'info')

END FUNCTION



FUNCTION leer_datos_comp(flag, flag2)
DEFINE flag		CHAR(1)
DEFINE flag2		SMALLINT

CALL leer_datos(flag)
IF int_flag THEN
	CALL mostrar_salir()
	RETURN 0
END IF
IF flag2 = 1 THEN
	CALL leer_detalle(flag)
	IF int_flag THEN
		CALL mostrar_salir()
		RETURN 0
	END IF
END IF
RETURN 1

END FUNCTION



FUNCTION leer_datos(flag)
DEFINE flag		CHAR(1)
DEFINE resp 		CHAR(6)
DEFINE r_r03		RECORD LIKE rept003.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r46		RECORD LIKE rept046.*
DEFINE item		LIKE rept010.r10_codigo
DEFINE composi		LIKE rept046.r46_composicion
DEFINE grupo_linea	LIKE gent020.g20_grupo_linea
DEFINE bodega		LIKE rept002.r02_codigo

LET grupo_linea = NULL
LET bodega      = NULL
LET int_flag    = 0
INPUT BY NAME rm_r46.r46_item_comp, rm_r46.r46_referencia, rm_r46.r46_tiene_oc
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(r46_item_comp, r46_referencia)
		THEN
			EXIT INPUT
		END IF
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
	ON KEY(F2)
		IF flag = 'M' THEN
			CONTINUE INPUT
		END IF
		IF INFIELD(r46_item_comp) THEN
			IF vm_item_nue = 'Yes' THEN
				CALL fl_ayuda_items_compuestos(vg_codcia,
								vg_codloc, 'I')
					RETURNING composi, r_r10.r10_codigo,
						r_r10.r10_nombre
			ELSE
				CALL fl_ayuda_maestro_items_stock(vg_codcia,
							grupo_linea, bodega)
					RETURNING r_r10.r10_codigo,
						r_r10.r10_nombre,
						r_r10.r10_linea,
						r_r10.r10_precio_mb,
						r_r11.r11_bodega,
						r_r11.r11_stock_act
			END IF
			IF r_r10.r10_codigo IS NOT NULL THEN
				CALL datos_item_cab(r_r10.r10_codigo)
			END IF
		END IF
		LET int_flag = 0
	BEFORE FIELD r46_item_comp
		LET item = rm_r46.r46_item_comp
	AFTER FIELD r46_item_comp
		IF flag = 'M' THEN
			LET rm_r46.r46_item_comp = item
			DISPLAY BY NAME rm_r46.r46_item_comp
			CONTINUE INPUT
		END IF
		IF rm_r46.r46_item_comp IS NOT NULL THEN
			CALL fl_lee_item(vg_codcia, rm_r46.r46_item_comp)
				RETURNING r_r10.*
			IF r_r10.r10_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Item no existe.', 'exclamation')
				NEXT FIELD r46_item_comp
			END IF
			CALL fl_lee_composicion_cab(vg_codcia, vg_codloc,
							rm_r46.r46_item_comp)
				RETURNING r_r46.*
			IF r_r46.r46_compania IS NOT NULL THEN
				--
				CALL fl_mostrar_mensaje('No puede generar nuevamente la estructura de este ítem, porque ya esta compuesto o en proceso.', 'exclamation')
				NEXT FIELD r46_item_comp
				--
			END IF
			CALL datos_item_cab(r_r10.r10_codigo)
			CALL fl_lee_linea_rep(vg_codcia, rm_r46.r46_division_c)
				RETURNING r_r03.*
			IF r_r03.r03_estado = 'B' THEN
				CALL fl_mostrar_mensaje('Division tiene estado BLOQUEADO.', 'exclamation')
				NEXT FIELD r46_item_comp
			END IF
			IF vm_est_ant <> 'C' THEN
				IF r_r10.r10_estado <> 'B' AND
				   r_r10.r10_costo_mb >= 0
				THEN
					CALL fl_mostrar_mensaje('El Item no es para COMPONER.', 'exclamation')
					NEXT FIELD r46_item_comp
				END IF
			END IF
		ELSE
			LET rm_r46.r46_desc_comp    = NULL
			LET rm_r46.r46_division_c   = NULL
			LET rm_r46.r46_sub_linea_c  = NULL
			LET rm_r46.r46_cod_grupo_c  = NULL
			LET rm_r46.r46_cod_clase_c  = NULL
			LET rm_r46.r46_marca_c      = NULL
			LET rm_r46.r46_nom_div_c    = NULL
			LET rm_r46.r46_desc_sub_c   = NULL
			LET rm_r46.r46_desc_grupo_c = NULL
			LET rm_r46.r46_desc_clase_c = NULL
			LET rm_r46.r46_desc_marca_c = NULL
			CLEAR r46_desc_comp
		END IF
	AFTER INPUT
		LET rm_r46.r46_referencia = rm_r46.r46_referencia CLIPPED
		IF rm_r46.r46_referencia IS NULL THEN
			CALL fl_mostrar_mensaje('Digite la referencia.', 'exclamation')
			NEXT FIELD r46_referencia
		END IF
END INPUT
IF int_flag THEN
	RETURN
END IF
IF rm_r46.r46_tiene_oc IS NULL THEN
	LET rm_r46.r46_tiene_oc = 'N'
	DISPLAY BY NAME rm_r46.r46_tiene_oc
END IF

END FUNCTION



FUNCTION leer_detalle(flag)
DEFINE flag		CHAR(1)
DEFINE r_r10	 	RECORD LIKE rept010.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE grupo_linea	LIKE gent020.g20_grupo_linea
DEFINE resp 		CHAR(6)
DEFINE mensaje		VARCHAR(150)
DEFINE i, j, k, l	SMALLINT
DEFINE max_row		SMALLINT
DEFINE encontro		SMALLINT

IF flag = 'I' THEN
	IF vm_est_ant = 'C' THEN
		SELECT COUNT(*) INTO vm_num_det
			FROM rept047
			WHERE r47_compania    = rm_r46.r46_compania
			  AND r47_localidad   = rm_r46.r46_localidad
			  AND r47_composicion = rm_r46.r46_composicion
			  AND r47_item_comp   = rm_r46.r46_item_comp
		IF vm_num_det = 0 THEN
			LET vm_num_det = 1
		END IF
	ELSE
		LET vm_num_det = 1
	END IF
END IF
LET grupo_linea = NULL
LET int_flag    = 0
CALL set_count(vm_num_det)
INPUT ARRAY rm_detalle WITHOUT DEFAULTS FROM rm_detalle.*
	ON KEY(INTERRUPT)
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
	ON KEY(F2)
		IF INFIELD(r47_item_part) THEN
			CALL fl_ayuda_maestro_items_stock(vg_codcia,
						grupo_linea, vm_bod_comp)
				RETURNING r_r10.r10_codigo, r_r10.r10_nombre,
					  r_r10.r10_linea, r_r10.r10_precio_mb,
					  r_r11.r11_bodega, r_r11.r11_stock_act
			IF r_r10.r10_codigo IS NOT NULL THEN
				CALL datos_item_det(r_r10.*, i, j)
			END IF
		END IF
		LET int_flag = 0
	ON KEY(F5)
		IF rm_g05.g05_grupo = 'SI' OR rm_g05.g05_grupo = 'GE' THEN
			LET i = arr_curr()
			CALL mostrar_item(rm_r46.r46_item_comp)
			LET int_flag = 0
		END IF
	ON KEY(F6)
		IF rm_g05.g05_grupo = 'SI' OR rm_g05.g05_grupo = 'GE' THEN
			LET i = arr_curr()
			IF rm_detalle[i].r47_item_part IS NOT NULL THEN
				CALL mostrar_item(rm_detalle[i].r47_item_part)
				LET int_flag = 0
			END IF
		END IF
	ON KEY(F7)
		LET i = arr_curr()
		CALL control_stock_items(rm_r46.r46_item_comp, 0)
		LET int_flag = 0
	ON KEY(F8)
		LET i = arr_curr()
		IF rm_detalle[i].r47_item_part IS NOT NULL THEN
			CALL control_stock_items(rm_detalle[i].r47_item_part, i)
			LET int_flag = 0
		END IF
	BEFORE INPUT 
		--#CALL dialog.keysetlabel("F7","Stock Item Comp.")
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
		LET max_row = arr_count()
		IF i > max_row THEN
			LET max_row = max_row + 1
		END IF
		CALL mostrar_etiquetas(i, max_row)
		IF rm_g05.g05_grupo = 'SI' OR rm_g05.g05_grupo = 'GE' THEN
			CALL dialog.keysetlabel("F5", "Item Composición")
			IF rm_detalle[i].r47_item_part IS NOT NULL THEN
				CALL dialog.keysetlabel("F6", "Item Parte")
				CALL dialog.keysetlabel("F8","Stock Item Parte")
			ELSE
				CALL dialog.keysetlabel("F6", "")
				CALL dialog.keysetlabel("F8", "")
			END IF
		ELSE
			CALL dialog.keysetlabel("F5", "")
			CALL dialog.keysetlabel("F6", "")
		END IF
	AFTER FIELD r47_item_part
		IF rm_detalle[i].r47_item_part IS NOT NULL THEN
			CALL fl_lee_item(vg_codcia, rm_detalle[i].r47_item_part)
				RETURNING r_r10.*
			IF r_r10.r10_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Item no existe.','exclamation')
				NEXT FIELD r47_item_part
			END IF
			IF r_r10.r10_costo_mb <= 0.01 AND
			   fl_item_tiene_movimientos(r_r10.r10_compania,
							r_r10.r10_codigo)
			THEN
				CALL fl_mostrar_mensaje('Debe estar configurado correctamente el costo del item destino y NO con costo menor igual a 0.01.', 'exclamation')
				NEXT FIELD r47_item_part
			END IF
			IF r_r10.r10_estado = 'B' THEN
				CALL fl_mostrar_mensaje('Item tiene estado de BLOQUEADO.', 'exclamation')
				NEXT FIELD r47_item_part
			END IF
			IF rm_r46.r46_item_comp = rm_detalle[i].r47_item_part
			THEN
				CALL fl_mostrar_mensaje('El Item para componer debe ser diferente al Item de partes.', 'exclamation')
				NEXT FIELD r47_item_part
			END IF
			CALL datos_item_det(r_r10.*, i, j)
			CALL mostrar_etiquetas(i, max_row)
			{--
			IF retorna_item_stock(rm_detalle[i].r47_bodega_part,
						rm_detalle[i].r47_item_part) < 0
			THEN
				CALL fl_mostrar_mensaje('El Item de partes no tiene stock local en la bodega de ensamblaje.', 'exclamation')
				NEXT FIELD r47_item_part
			END IF
			--}
			IF rm_g05.g05_grupo = 'SI' OR rm_g05.g05_grupo = 'GE'
			THEN
				CALL dialog.keysetlabel("F6", "Item Parte")
				CALL dialog.keysetlabel("F8","Stock Item Parte")
			END IF
			IF rm_detalle[i].r47_cantidad IS NULL THEN
				NEXT FIELD r47_cantidad
			END IF
		END IF
	AFTER FIELD r47_cantidad
		IF rm_detalle[i].r47_bodega_part IS NULL OR
		   rm_detalle[i].r47_item_part IS NULL
		THEN
			CONTINUE INPUT
		END IF
		IF rm_detalle[i].r47_cantidad IS NULL THEN
			NEXT FIELD r47_cantidad
		END IF
		{--
		IF rm_detalle[i].r47_cantidad > retorna_item_stock(
						rm_detalle[i].r47_bodega_part,
						rm_detalle[i].r47_item_part)
 		THEN
			CALL fl_mostrar_mensaje('La cantidad no puede ser mayor al stock local en esta bodega.', 'exclamation')
			NEXT FIELD r47_cantidad
		END IF
		--}
	AFTER DELETE
		INITIALIZE rm_adi[i].* TO NULL
	AFTER INPUT
		LET vm_num_det = arr_count()
		LET l = 0
		FOR k = 1 TO vm_num_det
			IF rm_detalle[k].r47_item_part IS NULL THEN
				LET l = l + 1
			END IF
		END FOR
		IF l = vm_num_det THEN
			CALL fl_mostrar_mensaje('Al menos debe armar la composición con un ítem.', 'exclamation')
			CONTINUE INPUT
		END IF
		FOR k = 1 TO vm_num_det
			IF rm_detalle[k].r47_cantidad IS NULL THEN
				LET mensaje = 'Digite la cantidad para ',
					'componer del ítem ',
					rm_detalle[k].r47_item_part CLIPPED, '.'
				CALL fl_mostrar_mensaje(mensaje, 'exclamation')
				CONTINUE INPUT
			END IF
		END FOR
		LET encontro = 0
		FOR k = 1 TO vm_num_det - 1
			FOR l = k + 1 TO vm_num_det
				IF rm_detalle[l].r47_item_part IS NULL THEN
					CONTINUE FOR
				END IF
				IF (rm_detalle[k].r47_bodega_part =
				    rm_detalle[l].r47_bodega_part) AND
				   (rm_detalle[k].r47_item_part =
				    rm_detalle[l].r47_item_part)
				THEN
					LET i        = k
					LET encontro = 1
					EXIT FOR
				END IF
			END FOR
		END FOR
		IF encontro THEN
			LET mensaje = 'El item: ',
					rm_detalle[i].r47_item_part CLIPPED,
					' en bodega ',
					rm_detalle[i].r47_bodega_part,
					' esta repetido. Por favor borrelo',
					' para continuar.'
			CALL fl_mostrar_mensaje(mensaje, 'exclamation')
			CONTINUE INPUT
		END IF
END INPUT
IF rm_r46.r46_cod_clase_c IS NULL THEN
	CLEAR r46_cod_clase_c, r46_desc_clase_c
END IF
CALL muestra_contadores_det(0, vm_num_det)

END FUNCTION



FUNCTION datos_item_cab(item)
DEFINE item		LIKE rept010.r10_codigo
DEFINE r_r03		RECORD LIKE rept003.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r70		RECORD LIKE rept070.*
DEFINE r_r71		RECORD LIKE rept071.*
DEFINE r_r72		RECORD LIKE rept072.*
DEFINE r_r73		RECORD LIKE rept073.*

LET rm_r46.r46_item_comp    = item
CALL fl_lee_item(vg_codcia, item) RETURNING r_r10.*
LET rm_r46.r46_estado       = 'P'
CALL muestra_estado()
LET rm_r46.r46_desc_comp    = r_r10.r10_nombre
LET rm_r46.r46_division_c   = r_r10.r10_linea
LET rm_r46.r46_sub_linea_c  = r_r10.r10_sub_linea
LET rm_r46.r46_cod_grupo_c  = r_r10.r10_cod_grupo
LET rm_r46.r46_cod_clase_c  = r_r10.r10_cod_clase
LET rm_r46.r46_marca_c      = r_r10.r10_marca
CALL fl_lee_linea_rep(vg_codcia, rm_r46.r46_division_c) RETURNING r_r03.*
CALL fl_lee_sublinea_rep(vg_codcia,rm_r46.r46_division_c,rm_r46.r46_sub_linea_c)
	RETURNING r_r70.*
CALL fl_lee_grupo_rep(vg_codcia, rm_r46.r46_division_c, rm_r46.r46_sub_linea_c,
			rm_r46.r46_cod_grupo_c)
	RETURNING r_r71.*
CALL fl_lee_clase_rep(vg_codcia, rm_r46.r46_division_c, rm_r46.r46_sub_linea_c,
			rm_r46.r46_cod_grupo_c, rm_r46.r46_cod_clase_c)
	RETURNING r_r72.*
CALL fl_lee_marca_rep(vg_codcia, rm_r46.r46_marca_c) RETURNING r_r73.*
LET rm_r46.r46_nom_div_c    = r_r03.r03_nombre
LET rm_r46.r46_desc_sub_c   = r_r70.r70_desc_sub
LET rm_r46.r46_desc_grupo_c = r_r71.r71_desc_grupo
LET rm_r46.r46_desc_clase_c = r_r72.r72_desc_clase
LET rm_r46.r46_desc_marca_c = r_r73.r73_desc_marca
DISPLAY BY NAME rm_r46.r46_item_comp, rm_r46.r46_desc_comp

END FUNCTION



FUNCTION datos_item_det(r_r10, i, j)
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE i, j		SMALLINT
DEFINE r_r03		RECORD LIKE rept003.*
DEFINE r_r70		RECORD LIKE rept070.*
DEFINE r_r71		RECORD LIKE rept071.*
DEFINE r_r72		RECORD LIKE rept072.*
DEFINE r_r73		RECORD LIKE rept073.*

LET rm_detalle[i].r47_bodega_part = vm_bod_comp
LET rm_detalle[i].r47_item_part   = r_r10.r10_codigo
CALL fl_lee_item(vg_codcia, rm_detalle[i].r47_item_part) RETURNING r_r10.*
LET rm_detalle[i].r47_desc_part   = r_r10.r10_nombre
LET rm_detalle[i].r47_costo_part  = r_r10.r10_costo_mb
LET rm_adi[i].r47_division_p      = r_r10.r10_linea
LET rm_adi[i].r47_sub_linea_p     = r_r10.r10_sub_linea
LET rm_adi[i].r47_cod_grupo_p     = r_r10.r10_cod_grupo
LET rm_adi[i].r47_cod_clase_p     = r_r10.r10_cod_clase
LET rm_detalle[i].r47_marca_p     = r_r10.r10_marca
CALL fl_lee_linea_rep(vg_codcia, rm_adi[i].r47_division_p) RETURNING r_r03.*
CALL fl_lee_sublinea_rep(vg_codcia, rm_adi[i].r47_division_p,
				rm_adi[i].r47_sub_linea_p)
	RETURNING r_r70.*
CALL fl_lee_grupo_rep(vg_codcia, rm_adi[i].r47_division_p,
			rm_adi[i].r47_sub_linea_p, rm_adi[i].r47_cod_grupo_p)
	RETURNING r_r71.*
CALL fl_lee_clase_rep(vg_codcia, rm_adi[i].r47_division_p,
			rm_adi[i].r47_sub_linea_p, rm_adi[i].r47_cod_grupo_p,
			rm_adi[i].r47_cod_clase_p)
	RETURNING r_r72.*
CALL fl_lee_marca_rep(vg_codcia, rm_detalle[i].r47_marca_p) RETURNING r_r73.*
LET rm_adi[i].r47_nom_div_p       = r_r03.r03_nombre
LET rm_adi[i].r47_desc_sub_p      = r_r70.r70_desc_sub
LET rm_adi[i].r47_desc_grupo_p    = r_r71.r71_desc_grupo
LET rm_adi[i].r47_desc_clase_p    = r_r72.r72_desc_clase
LET rm_adi[i].descripcion         = r_r10.r10_nombre
LET rm_adi[i].r47_desc_marca_p    = r_r73.r73_desc_marca
DISPLAY rm_detalle[i].* TO rm_detalle[j].*
DISPLAY BY NAME rm_adi[i].r47_nom_div_p, rm_adi[i].r47_desc_sub_p,
		rm_adi[i].r47_desc_grupo_p, rm_adi[i].r47_desc_clase_p,
		rm_adi[i].descripcion

END FUNCTION



FUNCTION control_consulta()
DEFINE flag		CHAR(1)
DEFINE r_r01		RECORD LIKE rept001.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE composi		LIKE rept046.r46_composicion
DEFINE expr_sql		CHAR(1500)
DEFINE query		CHAR(3000)

CALL borrar_cabecera()
CALL borrar_detalle()
IF num_args() = 4 THEN
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON r46_composicion, r46_cod_ventas,
			r46_estado, r46_item_comp, r46_desc_comp,r46_referencia,
			r46_usu_modifi, r46_fec_modifi, r46_usu_cierre,
			r46_fec_cierre, r46_usuario, r46_fecing
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT CONSTRUCT
		ON KEY(F2)
			IF INFIELD(r46_composicion) THEN
				CALL fl_ayuda_items_compuestos(vg_codcia,
								vg_codloc, 'C')
					RETURNING composi, r_r10.r10_codigo,
							r_r10.r10_nombre
				IF r_r10.r10_codigo IS NOT NULL THEN
					LET rm_r46.r46_composicion = composi
					LET rm_r46.r46_item_comp   =
								r_r10.r10_codigo
					LET rm_r46.r46_desc_comp   =
								r_r10.r10_nombre
					DISPLAY BY NAME rm_r46.r46_composicion,
							rm_r46.r46_item_comp,
							rm_r46.r46_desc_comp
				END IF
			END IF
			IF INFIELD(r46_cod_ventas) AND
			  (rm_g05.g05_tipo <> 'UF' OR rm_r01.r01_tipo = 'J' OR
			   rm_r01.r01_tipo = 'G')
			THEN
				CALL fl_ayuda_vendedores(vg_codcia, 'A', 'A')
					RETURNING r_r01.r01_codigo,
						  r_r01.r01_nombres
				IF rm_r01.r01_codigo IS NOT NULL THEN
					LET rm_r46.r46_cod_ventas =
								r_r01.r01_codigo
					DISPLAY BY NAME rm_r46.r46_cod_ventas,
							r_r01.r01_nombres
				END IF
			END IF
			IF INFIELD(r46_item_comp) THEN
				CALL fl_ayuda_items_compuestos(vg_codcia,
								vg_codloc, 'C')
					RETURNING composi, r_r10.r10_codigo,
						r_r10.r10_nombre
				IF r_r10.r10_codigo IS NOT NULL THEN
					LET rm_r46.r46_item_comp   =
								r_r10.r10_codigo
					LET rm_r46.r46_desc_comp   =
								r_r10.r10_nombre
					DISPLAY BY NAME rm_r46.r46_item_comp,
							rm_r46.r46_desc_comp
				END IF
			END IF
			LET int_flag = 0
		AFTER FIELD r46_cod_ventas
			IF rm_r01.r01_tipo <> 'J' AND rm_r01.r01_tipo <> 'G'
			THEN
				LET rm_r46.r46_cod_ventas = rm_r01.r01_codigo
				DISPLAY BY NAME rm_r46.r46_cod_ventas,
						rm_r01.r01_nombres
			END IF
			LET r_r01.r01_codigo = GET_FLDBUF(r46_cod_ventas)
			IF r_r01.r01_codigo IS NOT NULL THEN
				CALL fl_lee_vendedor_rep(vg_codcia,
							r_r01.r01_codigo)
					RETURNING r_r01.*
				LET rm_r46.r46_cod_ventas = r_r01.r01_codigo
				DISPLAY BY NAME rm_r46.r46_cod_ventas,
						rm_r01.r01_nombres
			ELSE
				LET rm_r46.r46_cod_ventas = NULL
				CLEAR r01_nombres
			END IF
		AFTER FIELD r46_item_comp
			LET r_r10.r10_codigo = GET_FLDBUF(r46_item_comp)
			IF r_r10.r10_codigo IS NOT NULL THEN
				CALL fl_lee_item(vg_codcia, r_r10.r10_codigo)
					RETURNING r_r10.*
				IF r_r10.r10_compania IS NULL THEN
					CALL fl_mostrar_mensaje('Item no existe.', 'exclamation')
					NEXT FIELD r46_item_comp
				END IF
			ELSE
				CLEAR r46_item_comp, r46_desc_comp
			END IF
	END CONSTRUCT
	IF int_flag THEN
		CALL mostrar_salir()
		RETURN
	END IF
ELSE
	LET expr_sql = 'r46_composicion = ', arg_val(5)
END IF
LET query = 'SELECT *, ROWID ',
		' FROM rept046 ',
		' WHERE r46_compania  = ', vg_codcia,
		'   AND r46_localidad = ', vg_codloc,
		'   AND ', expr_sql CLIPPED,
		' ORDER BY 3'
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_r46.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
	IF vm_num_rows > vm_max_rows THEN
		EXIT FOREACH
	END IF
END FOREACH 
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	LET vm_num_rows    = 0
	LET vm_row_current = 0
	LET vm_num_det     = 0
	CALL muestra_contadores(0, 0)
	CALL borrar_cabecera()
	CALL borrar_detalle()
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF
LET vm_row_current = 1
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION generar_cabecera_composicion()
DEFINE num_aux		INTEGER

WHILE TRUE
	SELECT NVL(MAX(r46_composicion) + 1, 1)
		INTO rm_r46.r46_composicion
		FROM rept046
		WHERE r46_compania    = rm_r46.r46_compania
		  AND r46_localidad   = rm_r46.r46_localidad
	LET rm_r46.r46_fecing = CURRENT
	WHENEVER ERROR CONTINUE
	INSERT INTO rept046 VALUES (rm_r46.*)
	IF STATUS = 0 THEN
		LET num_aux = SQLCA.SQLERRD[6]
		WHENEVER ERROR STOP
		EXIT WHILE
	END IF
END WHILE
WHENEVER ERROR STOP
RETURN num_aux

END FUNCTION



FUNCTION generar_detalle_composicion(flag, flag2)
DEFINE flag		CHAR(1)
DEFINE flag2		SMALLINT
DEFINE r_r47		RECORD LIKE rept047.*
DEFINE i, resul		SMALLINT

WHENEVER ERROR CONTINUE
DELETE FROM rept047
	WHERE r47_compania    = rm_r46.r46_compania
	  AND r47_localidad   = rm_r46.r46_localidad
	  AND r47_composicion = rm_r46.r46_composicion
	  AND r47_item_comp   = rm_r46.r46_item_comp
IF STATUS <> 0 THEN
	WHENEVER ERROR STOP
	CALL fl_mostrar_mensaje('No se puede eliminar el detalle de la composición. Por favor llame al ADMINISTRADOR.', 'exclamation')
	RETURN 0
END IF
WHENEVER ERROR STOP
LET resul     = 1
FOR i = 1 TO vm_num_det
	INITIALIZE r_r47.* TO NULL
	LET r_r47.r47_compania     = rm_r46.r46_compania
	LET r_r47.r47_localidad    = rm_r46.r46_localidad
	LET r_r47.r47_composicion  = rm_r46.r46_composicion
	LET r_r47.r47_item_comp    = rm_r46.r46_item_comp
	LET r_r47.r47_bodega_part  = rm_detalle[i].r47_bodega_part
	LET r_r47.r47_item_part    = rm_detalle[i].r47_item_part CLIPPED
	LET r_r47.r47_desc_part    = rm_detalle[i].r47_desc_part CLIPPED
	LET r_r47.r47_costo_part   = rm_detalle[i].r47_costo_part
	LET r_r47.r47_cantidad     = rm_detalle[i].r47_cantidad
	LET r_r47.r47_division_p   = rm_adi[i].r47_division_p
	LET r_r47.r47_nom_div_p    = rm_adi[i].r47_nom_div_p
	LET r_r47.r47_sub_linea_p  = rm_adi[i].r47_sub_linea_p
	LET r_r47.r47_desc_sub_p   = rm_adi[i].r47_desc_sub_p
	LET r_r47.r47_cod_grupo_p  = rm_adi[i].r47_cod_grupo_p
	LET r_r47.r47_desc_grupo_p = rm_adi[i].r47_desc_grupo_p
	LET r_r47.r47_cod_clase_p  = rm_adi[i].r47_cod_clase_p
	LET r_r47.r47_desc_clase_p = rm_adi[i].r47_desc_clase_p
	LET r_r47.r47_marca_p      = rm_detalle[i].r47_marca_p
	LET r_r47.r47_desc_marca_p = rm_adi[i].r47_desc_marca_p
	WHENEVER ERROR CONTINUE
	INSERT INTO rept047 VALUES (r_r47.*)
	IF STATUS <> 0 THEN
		WHENEVER ERROR STOP
		CALL fl_mostrar_mensaje('No se puede insertar el detalle de la composicion. Por favor llame al ADMINISTRADOR.', 'exclamation')
		LET resul = 0
		EXIT FOR
	END IF
	WHENEVER ERROR STOP
END FOR
RETURN resul

END FUNCTION



FUNCTION retorna_item_stock(bodega, item)
DEFINE bodega		LIKE rept002.r02_codigo
DEFINE item		LIKE rept010.r10_codigo
DEFINE query		CHAR(800)
DEFINE sto_part		LIKE rept011.r11_stock_act

LET query = 'SELECT NVL(SUM(r11_stock_act), 0) ',
		' FROM rept011, rept002, gent002 ',
		' WHERE r11_compania   = ', vg_codcia,
		'   AND r11_bodega     = "', bodega, '"',
		'   AND r11_item       = "', item CLIPPED,
					'"',
		'   AND r02_compania   = r11_compania ',
		'   AND r02_codigo     = r11_bodega ',
		'   AND g02_compania   = r02_compania ',
		'   AND g02_localidad  = r02_localidad ',
		'   AND g02_ciudad     = ', retorna_ciudad()
PREPARE cons_sto FROM query
DECLARE q_sto CURSOR FOR cons_sto
OPEN q_sto
FETCH q_sto INTO sto_part
CLOSE q_sto
FREE q_sto
RETURN sto_part

END FUNCTION



FUNCTION retorna_ciudad()
DEFINE ciudad		LIKE gent002.g02_ciudad

IF vg_codloc = 1 OR vg_codloc = 6 THEN
	LET ciudad = 1
ELSE
	LET ciudad = 45
END IF
RETURN ciudad

END FUNCTION



FUNCTION mostrar_nuevo_reg(num_aux, flag)
DEFINE num_aux		INTEGER
DEFINE flag		CHAR(1)

IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	IF flag = 'I' THEN
		LET vm_num_rows = vm_num_rows + 1
	END IF
END IF
LET vm_row_current       = vm_num_rows
LET vm_rows[vm_num_rows] = num_aux
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION mostrar_salir()

IF vm_num_rows = 0 THEN
	CALL borrar_cabecera()
	CALL borrar_detalle()
ELSE
	CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION muestra_contadores(num_cur, max_cur)
DEFINE num_cur, max_cur	SMALLINT

DISPLAY BY NAME num_cur, max_cur

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION borrar_cabecera()

INITIALIZE rm_r46.* TO NULL
CLEAR num_cur, max_cur, r46_composicion, r46_cod_ventas, r01_nombres,
	r46_item_comp, r46_desc_comp, r46_referencia, r46_tiene_oc, r46_estado,
	nom_est, r46_usu_cierre, r46_fec_cierre, r46_usu_modifi, r46_fec_modifi,
	r46_usuario, r46_fecing

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i		SMALLINT

FOR i = 1 TO fgl_scr_size('rm_detalle')
	CLEAR rm_detalle[i].*
END FOR
FOR i = 1 TO vm_max_det
	INITIALIZE rm_detalle[i].*, rm_adi[i].* TO NULL
END FOR
CLEAR num_row, max_row, r47_nom_div_p, r47_desc_sub_p, r47_desc_grupo_p,
	r47_desc_clase_p, descripcion

END FUNCTION



FUNCTION mostrar_cabecera_forma()

DISPLAY "Bodega"	TO tit_col1
DISPLAY "Item P."	TO tit_col2
DISPLAY "Descripción"	TO tit_col3
DISPLAY "Cantidad"	TO tit_col4
DISPLAY "Costo"		TO tit_col5
DISPLAY "Marca"		TO tit_col6

END FUNCTION



FUNCTION lee_muestra_registro(row)
DEFINE row		INTEGER
DEFINE r_r01		RECORD LIKE rept001.*
DEFINE r_r02		RECORD LIKE rept002.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF
CALL borrar_cabecera()
SELECT * INTO rm_r46.* FROM rept046 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con indice: ', row USING "<<<<<<&"
END IF
CALL fl_lee_vendedor_rep(vg_codcia, rm_r46.r46_cod_ventas) RETURNING r_r01.*
DISPLAY BY NAME rm_r46.r46_composicion, rm_r46.r46_cod_ventas,r_r01.r01_nombres,
		rm_r46.r46_item_comp,rm_r46.r46_desc_comp,rm_r46.r46_referencia,
		rm_r46.r46_tiene_oc,rm_r46.r46_usu_cierre,rm_r46.r46_fec_cierre,
		rm_r46.r46_usu_modifi, rm_r46.r46_fec_modifi,
		rm_r46.r46_usuario, rm_r46.r46_fecing
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_estado()
CALL muestra_detalle()

END FUNCTION



FUNCTION muestra_detalle()
DEFINE i, lim 		SMALLINT
DEFINE query 		CHAR(1500)
DEFINE sec		SMALLINT

CALL borrar_detalle()
LET query = 'SELECT r47_bodega_part, r47_item_part, r47_desc_part, ',
			'r47_cantidad, r47_costo_part, r47_marca_p, ',
			'r47_division_p, r47_sub_linea_p, r47_cod_grupo_p, ',
			'r47_cod_clase_p, r47_nom_div_p, r47_desc_sub_p, ',
			'r47_desc_grupo_p, r47_desc_clase_p, r47_desc_marca_p,',
			' r47_desc_part ',
		' FROM rept047 ',
            	' WHERE r47_compania    = ', vg_codcia, 
	    	'   AND r47_localidad   = ', vg_codloc,
	    	'   AND r47_composicion = ', rm_r46.r46_composicion,
	    	'   AND r47_item_comp   = "', rm_r46.r46_item_comp CLIPPED, '"',
	    	' ORDER BY r47_item_part'
PREPARE cons2 FROM query
DECLARE q_cons2 CURSOR FOR cons2
LET vm_num_det = 1
FOREACH q_cons2 INTO rm_detalle[vm_num_det].*, rm_adi[vm_num_det].*
	LET vm_num_det = vm_num_det + 1
        IF vm_num_det > vm_max_det THEN
		EXIT FOREACH
	END IF	
END FOREACH 
LET vm_num_det = vm_num_det - 1
IF vm_num_det = 0 THEN 
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_num_det = 0
	CALL borrar_detalle()
	RETURN
END IF
LET lim = vm_num_det
IF vm_num_det > fgl_scr_size('rm_detalle') THEN
	LET lim = fgl_scr_size('rm_detalle')
END IF
FOR i = 1 TO lim
	DISPLAY rm_detalle[i].* TO rm_detalle[i].*
END FOR
CALL muestra_contadores_det(0, vm_num_det)

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



FUNCTION control_ver_detalle()
DEFINE i, j 		SMALLINT

LET int_flag = 0
CALL set_count(vm_num_det)
DISPLAY ARRAY rm_detalle TO rm_detalle.*
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT DISPLAY
	ON KEY(F5)
		IF rm_g05.g05_grupo = 'SI' OR rm_g05.g05_grupo = 'GE' THEN
			LET i = arr_curr()
			CALL mostrar_item(rm_r46.r46_item_comp)
			LET int_flag = 0
		END IF
	ON KEY(F6)
		IF rm_g05.g05_grupo = 'SI' OR rm_g05.g05_grupo = 'GE' THEN
			LET i = arr_curr()
			CALL mostrar_item(rm_detalle[i].r47_item_part)
			LET int_flag = 0
		END IF
        --#BEFORE DISPLAY
                --#CALL dialog.keysetlabel("ACCEPT", "")
	--#BEFORE ROW
		--#LET i = arr_curr()
		--#LET j = scr_line()
		--#CALL mostrar_etiquetas(i, vm_num_det)
		--#IF rm_g05.g05_grupo = 'SI' OR rm_g05.g05_grupo = 'GE' THEN
			--#CALL dialog.keysetlabel("F5", "Item Compuesto")
			--#CALL dialog.keysetlabel("F6", "Item Parte")
		--#ELSE
			--#CALL dialog.keysetlabel("F5", "")
			--#CALL dialog.keysetlabel("F6", "")
		--#END IF
        --#AFTER DISPLAY
                --#CONTINUE DISPLAY
END DISPLAY
CLEAR r47_nom_div_p, r47_desc_sub_p, r47_desc_grupo_p, r47_desc_clase_p,
	descripcion
CALL muestra_contadores_det(0, vm_num_det)

END FUNCTION



FUNCTION mostrar_item(item)
DEFINE item		LIKE rept020.r20_item
DEFINE param		VARCHAR(60)

LET param = ' "', item CLIPPED, '"'
CALL fl_ejecuta_comando('REPUESTOS', vg_modulo, 'repp108 ', param, 1)

END FUNCTION



FUNCTION control_stock_items(codigo, pos)
DEFINE codigo		LIKE rept010.r10_codigo
DEFINE pos		SMALLINT
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE tot_stock_loc	DECIMAL (8,2)
DEFINE tot_stock_rem	DECIMAL (8,2)
DEFINE tot_stock_gen 	DECIMAL (8,2)
DEFINE i, salir, lim	SMALLINT
DEFINE row_ini		SMALLINT
DEFINE query		CHAR(400)

CALL fl_lee_item(vg_codcia, codigo) RETURNING r_r10.*
IF r_r10.r10_compania IS NULL THEN
	RETURN
END IF
LET row_ini = 3
IF vg_gui = 0 THEN
	LET row_ini = 2
END IF
OPEN WINDOW w_repf247_3 AT row_ini, 31 WITH 21 ROWS, 48 COLUMNS
	ATTRIBUTE(BORDER, FORM LINE FIRST, COMMENT LINE LAST)
IF vg_gui = 1 THEN
	OPEN FORM f_repf247_3 FROM '../forms/repf247_3'
ELSE
	OPEN FORM f_repf247_3 FROM '../forms/repf247_3c'
END IF
DISPLAY FORM f_repf247_3
CREATE TEMP TABLE temp_loc(
		bod_loc		CHAR(2), 
		nom_bod_loc	CHAR(30),
		stock_loc	DECIMAL(8,2),
		cant_loc	DECIMAL(8,2)
	)
CREATE TEMP TABLE temp_rem(
		bod_rem		CHAR(2), 
		nom_bod_rem	CHAR(30),
		stock_rem	DECIMAL(8,2)
	)
CALL mostrar_cabecera_bodegas_ln()
DISPLAY BY NAME codigo, r_r10.r10_nombre
DECLARE q_eme CURSOR FOR
	SELECT * FROM rept011
		WHERE r11_compania = vg_codcia
		  AND r11_item     = codigo
		  AND r11_stock_act > 0
		ORDER BY r11_stock_act DESC, r11_bodega
LET i_loc = 0
LET i_rem = 0
LET tot_stock_loc = 0
LET tot_stock_rem = 0
FOREACH q_eme INTO r_r11.*
	CALL fl_lee_bodega_rep(vg_codcia, r_r11.r11_bodega) RETURNING r_r02.*
        IF r_r02.r02_tipo = 'S' THEN
		CONTINUE FOREACH
	END IF
        IF r_r02.r02_localidad = vg_codloc THEN
		LET i_loc                    = i_loc + 1
		LET r_loc[i_loc].bod_loc     = r_r11.r11_bodega
		LET r_loc[i_loc].nom_bod_loc = r_r02.r02_nombre
		LET r_loc[i_loc].stock_loc   = r_r11.r11_stock_act
		LET tot_stock_loc            = tot_stock_loc
						+ r_r11.r11_stock_act
		INSERT INTO temp_loc
			VALUES (r_r11.r11_bodega, r_r02.r02_nombre,
				r_r11.r11_stock_act, NULL)
	ELSE
		LET i_rem = i_rem + 1
		LET r_rem[i_rem].bod_rem     = r_r11.r11_bodega
		LET r_rem[i_rem].nom_bod_rem = r_r02.r02_nombre
		LET r_rem[i_rem].stock_rem   = r_r11.r11_stock_act
		LET tot_stock_rem            = tot_stock_rem
						+ r_r11.r11_stock_act
		INSERT INTO temp_rem VALUES (r_rem[i_rem].*)
	END IF
END FOREACH
IF i_loc = 0 AND i_rem = 0 THEN
	DROP TABLE temp_loc
	DROP TABLE temp_rem
	CALL fl_mensaje_consulta_sin_registros()
	LET int_flag = 0
	CLOSE WINDOW w_repf247_3
	RETURN
END IF
LET tot_stock_gen = tot_stock_loc + tot_stock_rem
LET lim           = fgl_scr_size('r_loc')
FOR i = 1 TO lim
	IF i > i_loc THEN
		EXIT FOR
	END IF
	DISPLAY r_loc[i].*  TO r_loc[i].*
END FOR
FOR i = 1 TO fgl_scr_size('r_rem')      
	IF i > i_rem THEN               
		EXIT FOR                
	END IF                          
	DISPLAY r_rem[i].* TO r_rem[i].*
END FOR                            
DISPLAY BY NAME tot_stock_loc, tot_stock_rem, tot_stock_gen
LET salir = 0
IF i_loc > 0 AND salir = 0 THEN
	CALL control_detalle_bodega_loc(pos) RETURNING salir
ELSE
	IF i_rem > 0 AND salir = 0 THEN
		CALL control_detalle_bodega_rem(pos) RETURNING salir
	END IF
END IF
DROP TABLE temp_loc
DROP TABLE temp_rem
LET int_flag = 0
CLOSE WINDOW w_repf247_3
RETURN

END FUNCTION



FUNCTION control_detalle_bodega_loc(pos)
DEFINE pos		SMALLINT
DEFINE i, j, salir	SMALLINT
DEFINE col 		SMALLINT
DEFINE query		CHAR(400)

FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET col          = 3
LET vm_columna_1 = col
LET vm_columna_2 = 1
LET rm_orden[vm_columna_1] = 'DESC'
LET rm_orden[vm_columna_2] = 'ASC'
WHILE TRUE
	LET query = 'SELECT bod_loc, nom_bod_loc, stock_loc FROM temp_loc ',
			'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				',', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE loc FROM query
	DECLARE q_loc CURSOR FOR loc 
	LET i = 1
	FOREACH q_loc INTO r_loc[i].*
		LET i = i + 1
		IF i > i_loc THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	LET salir = 0
	CALL muestra_contadores_det_tot(1, i_loc, 0, i_rem)
	CALL set_count(i)
	DISPLAY ARRAY r_loc TO r_loc.*
        	ON KEY(INTERRUPT)   
			LET salir = 1
        	        EXIT DISPLAY  
        	ON KEY(RETURN)   
			LET i = arr_curr()
			CALL muestra_contadores_det_tot(i, i_loc, 0, i_rem)
		ON KEY(F5)
			IF i_rem > 0 THEN
				CALL muestra_contadores_det_tot(0, i_loc, 1,
								i_rem)
				CALL control_detalle_bodega_rem(pos)
					RETURNING salir
				IF salir = 1 THEN
					EXIT DISPLAY
				END IF
			END IF
		ON KEY(F15)
			LET col = 1
			EXIT DISPLAY
		ON KEY(F16)
			LET col = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET col = 3
			EXIT DISPLAY
		--#BEFORE DISPLAY 
			--#CALL dialog.keysetlabel('ACCEPT', '')   
			--#IF i_rem > 0 THEN
				--#CALL dialog.keysetlabel("F5","Remotas") 
			--#ELSE
				--#CALL dialog.keysetlabel("F5","") 
			--#END IF
		--#BEFORE ROW 
			--#LET i = arr_curr()	
			--#LET j = scr_line()
			--#CALL muestra_contadores_det_tot(i, i_loc, 0, i_rem)
	        --#AFTER DISPLAY  
	                --#CONTINUE DISPLAY  
	END DISPLAY
	IF salir = 1 THEN
		EXIT WHILE
	END IF
	IF col <> vm_columna_1 THEN
		LET vm_columna_2           = vm_columna_1 
		LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
		LET vm_columna_1           = col 
	END IF
	IF rm_orden[vm_columna_1] = 'ASC' THEN
		LET rm_orden[vm_columna_1] = 'DESC'
	ELSE
		LET rm_orden[vm_columna_1] = 'ASC'
	END IF
END WHILE
RETURN salir

END FUNCTION 



FUNCTION control_detalle_bodega_rem(pos)
DEFINE pos		SMALLINT
DEFINE i, j, salir 	SMALLINT
DEFINE col 		SMALLINT
DEFINE query		CHAR(400)

FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET col          = 3
LET vm_columna_1 = col
LET vm_columna_2 = 1
LET rm_orden[vm_columna_1] = 'DESC'
LET rm_orden[vm_columna_2] = 'ASC'
WHILE TRUE
	LET query = 'SELECT * FROM temp_rem ',
			'ORDER BY ',
				vm_columna_1, ' ', rm_orden[vm_columna_1], ',', 
				vm_columna_2, ' ', rm_orden[vm_columna_2] 
	PREPARE rem FROM query
	DECLARE q_rem CURSOR FOR rem 
	LET i = 1
	FOREACH q_rem INTO r_rem[i].*
		LET i = i + 1
		IF i > i_rem THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	LET salir = 0
	CALL muestra_contadores_det_tot(0, i_loc, 1, i_rem)
	CALL set_count(i)
	DISPLAY ARRAY r_rem TO r_rem.*
        	ON KEY(INTERRUPT)   
			LET salir = 1
	                EXIT DISPLAY  
		ON KEY(RETURN)
			LET i = arr_curr()	
			LET j = scr_line()
			CALL muestra_contadores_det_tot(0, i_loc, i, i_rem)
		ON KEY(F5)
			IF i_loc > 0 THEN
				CALL muestra_contadores_det_tot(1, i_loc, 0,
								i_rem)
				CALL control_detalle_bodega_loc(pos)
					RETURNING salir
				IF salir = 1 THEN
					EXIT DISPLAY
				END IF
			END IF
		ON KEY(F18)
			LET col = 1
			EXIT DISPLAY
		ON KEY(F19)
			LET col = 2
			EXIT DISPLAY
		ON KEY(F20)
			LET col = 3
			EXIT DISPLAY
	        --#BEFORE DISPLAY 
	                --#CALL dialog.keysetlabel('ACCEPT', '')   
			--#CALL dialog.keysetlabel("F1","") 
			--#IF i_loc > 0 THEN
				--#CALL dialog.keysetlabel("F5","Locales") 
			--#ELSE
				--#CALL dialog.keysetlabel("F5","") 
			--#END IF
				--#CALL dialog.keysetlabel("CONTROL-W","") 
		--#BEFORE ROW 
			--#LET i = arr_curr()	
			--#LET j = scr_line()
			--#CALL muestra_contadores_det_tot(0, i_loc, i, i_rem)
	        --#AFTER DISPLAY  
	                --#CONTINUE DISPLAY  
	END DISPLAY 
	IF salir = 1 THEN
		EXIT WHILE
	END IF
	IF col <> vm_columna_1 THEN
		LET vm_columna_2           = vm_columna_1 
		LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
		LET vm_columna_1           = col 
	END IF
	IF rm_orden[vm_columna_1] = 'ASC' THEN
		LET rm_orden[vm_columna_1] = 'DESC'
	ELSE
		LET rm_orden[vm_columna_1] = 'ASC'
	END IF
END WHILE
RETURN salir

END FUNCTION 



FUNCTION muestra_contadores_det_tot(num_row_l, max_row_l, num_row_r, max_row_r)
DEFINE num_row_l, max_row_l	SMALLINT
DEFINE num_row_r, max_row_r	SMALLINT

DISPLAY BY NAME num_row_l, max_row_l, num_row_r, max_row_r

END FUNCTION 



FUNCTION mostrar_cabecera_bodegas_ln()

DISPLAY 'BD'			TO tit_col1
DISPLAY 'Bodegas Locales'	TO tit_col2
DISPLAY 'Stock'			TO tit_col3
DISPLAY 'BD'			TO tit_col4
DISPLAY 'Bodegas Remotas'	TO tit_col5
DISPLAY 'Stock'			TO tit_col6

END FUNCTION 



FUNCTION mostrar_etiquetas(i, num)
DEFINE i, num		SMALLINT

CALL muestra_contadores_det(i, num)
DISPLAY rm_adi[i].r47_desc_clase_p TO r47_desc_clase_p
DISPLAY BY NAME rm_adi[i].descripcion, rm_adi[i].r47_nom_div_p,
		rm_adi[i].r47_desc_sub_p, rm_adi[i].r47_desc_grupo_p,
		rm_adi[i].r47_desc_clase_p, rm_adi[i].descripcion

END FUNCTION 



FUNCTION muestra_estado()

DISPLAY BY NAME rm_r46.r46_estado
CASE rm_r46.r46_estado
	WHEN 'P' DISPLAY "EN PROCESO" TO nom_est
	WHEN 'C' DISPLAY "COMPUESTO"  TO nom_est
END CASE

END FUNCTION 



FUNCTION control_imprimir_comp()
DEFINE r_rep		RECORD
				num_lin		SMALLINT,
				bod_part	LIKE rept047.r47_bodega_part,
				item_part	LIKE rept047.r47_item_part,
				desc_part	LIKE rept047.r47_desc_part,
				cla_part	LIKE rept046.r46_desc_clase_c,
				unid_part	LIKE rept010.r10_uni_med,
				cantidad	LIKE rept047.r47_cantidad,
				marca		LIKE rept047.r47_marca_p
			END RECORD
DEFINE comando		VARCHAR(100)
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r47		RECORD LIKE rept047.*
DEFINE r_r72		RECORD LIKE rept072.*

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
DECLARE q_imp CURSOR FOR
	SELECT * FROM rept047
		WHERE r47_compania    = vg_codcia
		  AND r47_localidad   = vg_codloc
		  AND r47_composicion = rm_r46.r46_composicion
		  AND r47_item_comp   = rm_r46.r46_item_comp
		ORDER BY r47_item_part ASC
START REPORT report_composicion TO PIPE comando
LET r_rep.num_lin = 0
FOREACH q_imp INTO r_r47.*
	LET r_rep.num_lin   = r_rep.num_lin + 1
	LET r_rep.bod_part  = r_r47.r47_bodega_part
	LET r_rep.item_part = r_r47.r47_item_part
	LET r_rep.desc_part = r_r47.r47_desc_part
	CALL fl_lee_item(vg_codcia, r_r47.r47_item_part) RETURNING r_r10.*
	IF rm_r46.r46_cod_clase_c IS NULL THEN
		IF rm_r46.r46_cod_grupo_c IS NOT NULL THEN
			LET r_r10.r10_cod_grupo = rm_r46.r46_cod_grupo_c
		END IF
		CALL fl_lee_clase_rep(vg_codcia, rm_r46.r46_division_c,
				rm_r46.r46_sub_linea_c, r_r10.r10_cod_grupo,
				r_r10.r10_cod_clase)
			RETURNING r_r72.*
		LET r_rep.cla_part = r_r72.r72_desc_clase
	ELSE
		LET r_rep.cla_part = rm_r46.r46_desc_clase_c
	END IF
	LET r_rep.unid_part = UPSHIFT(r_r10.r10_uni_med)
	LET r_rep.cantidad = r_r47.r47_cantidad
	LET r_rep.marca    = r_r47.r47_marca_p
	OUTPUT TO REPORT report_composicion(r_rep.*)
END FOREACH
FINISH REPORT report_composicion

END FUNCTION



REPORT report_composicion(r_rep)
DEFINE r_rep		RECORD
				num_lin		SMALLINT,
				bod_part	LIKE rept047.r47_bodega_part,
				item_part	LIKE rept047.r47_item_part,
				desc_part	LIKE rept047.r47_desc_part,
				cla_part	LIKE rept046.r46_desc_clase_c,
				unid_part	LIKE rept010.r10_uni_med,
				cantidad	LIKE rept047.r47_cantidad,
				marca		LIKE rept047.r47_marca_p
			END RECORD
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE documento	VARCHAR(60)
DEFINE usuario		VARCHAR(10,5)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE nom_est		VARCHAR(20)
DEFINE escape		SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	132
	BOTTOM MARGIN	3
	PAGE LENGTH	44

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresiÂ¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo    = "MODULO: ", r_g50.g50_nombre[1, 19] CLIPPED
	LET documento = "COMPROBANTE DE COMPOSICION No. ",
			rm_r46.r46_composicion USING "<<<<<<&"
	CALL fl_justifica_titulo('D', rm_r46.r46_usuario, 10) RETURNING usuario
	CALL fl_justifica_titulo('C', documento CLIPPED, 80) RETURNING titulo
	LET titulo = modulo, titulo
	CASE rm_r46.r46_estado
		WHEN 'P' LET nom_est = "EN PROCESO"
		WHEN 'C' LET nom_est = " COMPUESTO"
	END CASE
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 001, rm_g01.g01_razonsocial,
	      COLUMN 122, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, titulo CLIPPED,
	      COLUMN 126, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 027, "DIVISION COMP.  : ", rm_r46.r46_division_c CLIPPED,
			" ", rm_r46.r46_nom_div_c CLIPPED
	PRINT COLUMN 027, "LINEA COMP.     : ", rm_r46.r46_sub_linea_c CLIPPED,
			" ", rm_r46.r46_desc_sub_c CLIPPED
	PRINT COLUMN 027, "GRUPO COMP.     : ", rm_r46.r46_cod_grupo_c CLIPPED,
			" ", rm_r46.r46_desc_grupo_c CLIPPED
	PRINT COLUMN 027, "MARCA COMP.     : ", rm_r46.r46_marca_c CLIPPED,
			" ", rm_r46.r46_desc_marca_c CLIPPED,
	      COLUMN 115, "ESTADO: ", nom_est CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", DATE(TODAY) USING 'dd-mm-yyyy',
		1 SPACES, TIME,
	      COLUMN 045, "REFERENCIA : ", rm_r46.r46_referencia CLIPPED,
	      COLUMN 123, usuario CLIPPED
	PRINT COLUMN 001, "------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 001, "L.",
	      COLUMN 006, "BD",
	      COLUMN 010, "ITEM",
	      COLUMN 020, "DESCRIPCION",
	      COLUMN 104, "UNI. MED.",
	      COLUMN 116, "CANTIDAD",
	      COLUMN 128, "MARCA"
	PRINT COLUMN 001, "------------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 2 LINES
	PRINT COLUMN 001, r_rep.num_lin		USING "&&&",
	      COLUMN 006, r_rep.bod_part	CLIPPED,
	      COLUMN 010, r_rep.item_part[1, 9]	CLIPPED,
	      COLUMN 020, r_rep.cla_part	CLIPPED
	PRINT COLUMN 022, r_rep.desc_part	CLIPPED,
	      COLUMN 104, r_rep.unid_part	CLIPPED,
	      COLUMN 114, r_rep.cantidad	USING '---,--&.##',
	      COLUMN 128, r_rep.marca		CLIPPED
	
PAGE TRAILER
	PRINT COLUMN 027, "AUTORIZADO_______________________";
	print ASCII escape;
	print ASCII desact_comp 

END REPORT
