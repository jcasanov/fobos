--------------------------------------------------------------------------------
-- Titulo           : repp249.4gl - Carga por composición de ítems
-- Elaboracion      : 01-Jul-2010
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp249 base módulo compañía localidad
--			[composición] [item] [carga]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_rows2		ARRAY [20000] OF INTEGER
DEFINE vm_row_current2	SMALLINT
DEFINE vm_num_rows2	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE rm_orden 	ARRAY[15] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE rm_r46		RECORD LIKE rept046.*
DEFINE rm_r48		RECORD LIKE rept048.*
DEFINE rm_carga		ARRAY [20000] OF RECORD
				r20_bodega	LIKE rept020.r20_bodega,
				r20_item	LIKE rept020.r20_item,
				r47_desc_part	LIKE rept047.r47_desc_part,
				r20_cant_ven	LIKE rept020.r20_cant_ven,
				r20_costnue_mb	LIKE rept020.r20_costnue_mb,
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
DEFINE vm_bod_aj	LIKE rept002.r02_codigo
DEFINE vm_uni_aux	LIKE rept048.r48_carg_stock
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
DEFINE rm_det_oc	ARRAY[50] OF RECORD
				r49_numero_oc	LIKE rept049.r49_numero_oc,
				c10_referencia	LIKE ordt010.c10_referencia,
				r49_cant_unid	LIKE rept049.r49_cant_unid,
				r49_costo_oc	LIKE rept049.r49_costo_oc,
				c10_estado	LIKE ordt010.c10_estado
			END RECORD
DEFINE vm_num_oc	SMALLINT
DEFINE vm_max_oc	SMALLINT
DEFINE vm_est_ant	CHAR(1)



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp249.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 7 THEN   -- Validar # parÃ¡metros correcto
	CALL fl_mostrar_mensaje('NÃºmero de parametros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'repp249'
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
LET vm_max_det      = 20000
LET vm_row_current2 = 0
LET vm_num_rows2    = 0
LET vm_max_rows     = 20000
LET lin_menu        = 0
LET row_ini         = 3
LET num_rows        = 22
LET num_cols        = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_repf249_1 AT row_ini, 02 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_repf249_1 FROM "../forms/repf249_1"
ELSE
	OPEN FORM f_repf249_1 FROM "../forms/repf249_1c"
END IF
DISPLAY FORM f_repf249_1
LET vm_uni_aux = NULL
CALL fl_lee_compania(vg_codcia) RETURNING rm_g01.*
CALL muestra_contadores(0, 0)
CALL muestra_contadores_det(0, 0)
CALL borrar_cabecera2()
CALL borrar_detalle2()
CALL mostrar_cabecera_forma()
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Eliminar'
		HIDE OPTION 'Cargar'
		HIDE OPTION 'Ordenes Compra'
		HIDE OPTION 'Detalle Trans.'
		HIDE OPTION 'Ver Item'
		HIDE OPTION 'Ver Detalle'
		HIDE OPTION 'Imprimir'
		IF num_args() = 7 THEN                                          
			HIDE OPTION 'Ingresar'                                  
			HIDE OPTION 'Consultar'                                 
			SHOW OPTION 'Ordenes Compra'
			SHOW OPTION 'Detalle Trans.'
			SHOW OPTION 'Ver Item'
			SHOW OPTION 'Imprimir'                                  
			SHOW OPTION 'Ver Detalle'
			CALL control_consulta()                                 
			CALL control_ver_detalle2()
			EXIT MENU
		END IF                                                          
	COMMAND KEY('I') 'Ingresar' 'Crea Estructura de Composición.'
		HIDE OPTION 'Imprimir'
		CALL control_ingreso()
		IF vm_row_current2 > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current2 = vm_num_rows2 THEN
			HIDE OPTION 'Avanzar'
		END IF
		IF vm_row_current2 > 0 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Eliminar'
			IF rm_r46.r46_tiene_oc = 'S' THEN
				SHOW OPTION 'Ordenes Compra'
			ELSE
				HIDE OPTION 'Ordenes Compra'
			END IF
			IF rm_r48.r48_estado = 'C' THEN
				HIDE OPTION 'Cargar'
			ELSE
				SHOW OPTION 'Cargar'
			END IF
			SHOW OPTION 'Detalle Trans.'
			SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Ver Item'
		END IF
		IF vm_num_rows2 > 0 THEN
			SHOW OPTION 'Imprimir'
		END IF
	COMMAND KEY('C') 'Consultar' 'Consultar un registro.'
		HIDE OPTION 'Imprimir'
		CALL control_consulta()
		IF vm_num_rows2 < 1 THEN
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Eliminar'
			SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Ver Item'
			SHOW OPTION 'Detalle Trans.'
			IF rm_r46.r46_tiene_oc = 'S' THEN
				SHOW OPTION 'Ordenes Compra'
			ELSE
				HIDE OPTION 'Ordenes Compra'
			END IF
			IF rm_r48.r48_estado = 'C' THEN
				HIDE OPTION 'Cargar'
			ELSE
				SHOW OPTION 'Cargar'
			END IF
			SHOW OPTION 'Imprimir'
			IF vm_num_rows2 = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Eliminar'
				HIDE OPTION 'Detalle Trans.'
				IF rm_r46.r46_tiene_oc = 'S' THEN
					SHOW OPTION 'Ordenes Compra'
				ELSE
					HIDE OPTION 'Ordenes Compra'
				END IF
				IF rm_r48.r48_estado = 'C' OR
				   rm_r48.r48_estado IS NULL
				THEN
					HIDE OPTION 'Cargar'
				ELSE
					SHOW OPTION 'Cargar'
				END IF
				HIDE OPTION 'Ver Detalle'
				HIDE OPTION 'Ver Item'
				HIDE OPTION 'Imprimir'
			END IF
		ELSE
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Eliminar'
			SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Ver Item'
			SHOW OPTION 'Detalle Trans.'
			IF rm_r46.r46_tiene_oc = 'S' THEN
				SHOW OPTION 'Ordenes Compra'
			ELSE
				HIDE OPTION 'Ordenes Compra'
			END IF
			IF rm_r48.r48_estado = 'C' THEN
				HIDE OPTION 'Cargar'
			ELSE
				SHOW OPTION 'Cargar'
			END IF
			SHOW OPTION 'Imprimir'
			IF vm_num_rows2 = 1 THEN
				HIDE OPTION 'Avanzar'
				HIDE OPTION 'Retroceder'
			ELSE
				SHOW OPTION 'Avanzar'
			END IF
		END IF
        COMMAND KEY('M') 'Modificar' 'Modifica registro en proceso.'
		CALL control_modificacion()
        COMMAND KEY('E') 'Eliminar' 'Elimina registro para la carga.'
		CALL control_eliminacion()
        COMMAND KEY('T') 'Cargar' 'Genera Carga del Item.'
		CALL cargar_stock_item_compuesto()
		IF rm_r48.r48_estado = 'C' THEN
			HIDE OPTION 'Cargar'
		ELSE
			SHOW OPTION 'Cargar'
		END IF
        COMMAND KEY('O') 'Ordenes Compra' 'Ordenes Compra para Carga del Item.'
		IF rm_r46.r46_tiene_oc = 'S' THEN
			CALL control_ordenes_compra('M', vm_num_det)
		END IF
        COMMAND KEY('T') 'Detalle Trans.' 'Detalle transacciones generadas.'
		CALL control_detalle_trans()
        COMMAND KEY('P') 'Imprimir' 'Imprime comprobante de carga de stock.'
		CALL control_imprimir_carga()
	COMMAND KEY('X') 'Ver Item' 'Muestra el ítem compuesto.'
		CALL mostrar_item(rm_r48.r48_item_comp)
	COMMAND KEY('D') 'Ver Detalle' 'Ver detalle del Registro.'
		IF vm_num_rows2 > 0 THEN
			CALL control_ver_detalle2()
		ELSE
			CALL fl_mensaje_consultar_primero()
		END IF
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
		HIDE OPTION 'Imprimir'
		CALL siguiente_registro2()
		IF vm_row_current2 = vm_num_rows2 THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
                IF vm_num_rows2 > 0 THEN
			SHOW OPTION 'Imprimir'
                END IF
		IF rm_r46.r46_tiene_oc = 'S' THEN
			SHOW OPTION 'Ordenes Compra'
		ELSE
			HIDE OPTION 'Ordenes Compra'
		END IF
		IF rm_r48.r48_estado = 'C' THEN
			HIDE OPTION 'Cargar'
		ELSE
			SHOW OPTION 'Cargar'
		END IF
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
		HIDE OPTION 'Imprimir'
		CALL anterior_registro2()
		IF vm_row_current2 = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
                IF vm_num_rows2 > 0 THEN
                	SHOW OPTION 'Imprimir'
                END IF
		IF rm_r46.r46_tiene_oc = 'S' THEN
			SHOW OPTION 'Ordenes Compra'
		ELSE
			HIDE OPTION 'Ordenes Compra'
		END IF
		IF rm_r48.r48_estado = 'C' THEN
			HIDE OPTION 'Cargar'
		ELSE
			SHOW OPTION 'Cargar'
		END IF
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU
CLOSE WINDOW w_repf249_1
EXIT PROGRAM

END FUNCTION



FUNCTION control_ingreso()
DEFINE comentarios	LIKE rept010.r10_comentarios
DEFINE coderr		INTEGER
DEFINE ses_id		INTEGER
DEFINE comando		CHAR(400)
DEFINE prog		VARCHAR(10)

CALL borrar_cabecera2()
CALL borrar_detalle2()
INITIALIZE rm_r48.* TO NULL
LET rm_r48.r48_compania    = vg_codcia
LET rm_r48.r48_localidad   = vg_codloc
LET rm_r48.r48_estado      = 'P'
LET rm_r48.r48_carg_stock  = 1
LET rm_r48.r48_costo_inv   = 0.00
LET rm_r48.r48_costo_oc    = 0.00
LET rm_r48.r48_costo_mo    = 0.00
LET rm_r48.r48_costo_comp  = 0.00
LET rm_r48.r48_usuario     = vg_usuario
LET rm_r48.r48_fecing      = CURRENT
DISPLAY BY NAME rm_r48.r48_composicion, rm_r48.r48_usuario, rm_r48.r48_fecing
CALL muestra_estado2()
IF NOT genera_datos() THEN
	CALL mostrar_salir()
	RETURN
END IF
--CALL control_imprimir_carga()
CALL fl_mostrar_mensaje('Estructura de Carga Generada OK.', 'info')

END FUNCTION



FUNCTION genera_datos()
DEFINE num_aux		INTEGER

LET vm_est_ant = rm_r48.r48_estado
IF NOT leer_datos_comp('I', 1) THEN
	RETURN 0
END IF
BEGIN WORK
	WHILE TRUE
		CALL retorna_secuencia_carga() RETURNING rm_r48.r48_sec_carga
		LET rm_r48.r48_fecing = CURRENT
		WHENEVER ERROR CONTINUE
		INSERT INTO rept048 VALUES (rm_r48.*)
		IF STATUS = 0 THEN
			LET num_aux = SQLCA.SQLERRD[6]
			WHENEVER ERROR STOP
			EXIT WHILE
		END IF
	END WHILE
	WHENEVER ERROR STOP
	IF NOT control_transferencia('D', 'I', 0) THEN
		ROLLBACK WORK
		RETURN 0
	END IF
	WHENEVER ERROR STOP
COMMIT WORK
CALL mostrar_nuevo_reg(num_aux, 'I')
RETURN 1

END FUNCTION



FUNCTION control_modificacion()
DEFINE bod_aux		LIKE rept002.r02_codigo

CALL lee_muestra_registro2(vm_rows2[vm_row_current2])
IF rm_r48.r48_estado <> 'P' THEN
	CALL fl_mostrar_mensaje('Solo se puede modificar una carga que esta en proceso.', 'exclamation')
	RETURN
END IF
BEGIN WORK
	WHENEVER ERROR CONTINUE
	DECLARE q_up CURSOR FOR
		SELECT * FROM rept048
			WHERE ROWID = vm_rows2[vm_row_current2]
		FOR UPDATE
	OPEN q_up
	FETCH q_up INTO rm_r48.*
	IF STATUS < 0 THEN
		WHENEVER ERROR STOP
		ROLLBACK WORK
		CALL fl_mensaje_bloqueo_otro_usuario()
		RETURN
	END IF
	WHENEVER ERROR STOP
	LET bod_aux    = rm_r48.r48_bodega_comp
	LET vm_uni_aux = rm_r48.r48_carg_stock
	IF NOT leer_datos_comp('M', 2) THEN
		ROLLBACK WORK
		RETURN
	END IF
	{--
	IF NOT cambiar_bodega_comp() THEN
		ROLLBACK WORK
		RETURN
	END IF
	--}
	WHENEVER ERROR CONTINUE
	UPDATE rept048
		SET * = rm_r48.*
		WHERE r48_compania    = rm_r48.r48_compania
		  AND r48_localidad   = rm_r48.r48_localidad
		  AND r48_composicion = rm_r48.r48_composicion
		  AND r48_item_comp   = rm_r48.r48_item_comp
		  AND r48_sec_carga   = rm_r48.r48_sec_carga
	IF STATUS <> 0 THEN
		ROLLBACK WORK
		WHENEVER ERROR STOP
		CALL fl_mostrar_mensaje('No se puede modificar el registro para la carga. Por favor llame al ADMINISTRADOR.', 'stop')
		CALL mostrar_salir()
		RETURN
	END IF
	WHENEVER ERROR STOP
	IF bod_aux <> rm_r48.r48_bodega_comp OR
	   vm_uni_aux <> rm_r48.r48_carg_stock
	THEN
		IF NOT control_transferencia('C', 'M', 1) THEN
			ROLLBACK WORK
			CALL mostrar_salir()
			RETURN 0
		END IF
		IF NOT control_transferencia('D', 'M', 2) THEN
			ROLLBACK WORK
			CALL mostrar_salir()
			RETURN 0
		END IF
		WHENEVER ERROR STOP
	END IF
COMMIT WORK
CALL lee_muestra_registro2(vm_rows2[vm_row_current2])
CALL fl_mostrar_mensaje('Estructura de Carga Modificada OK.', 'info')
LET vm_uni_aux = NULL

END FUNCTION



FUNCTION control_eliminacion()
DEFINE resp		CHAR(6)

CALL lee_muestra_registro2(vm_rows2[vm_row_current2])
IF rm_r48.r48_estado <> 'P' THEN
	CALL fl_mostrar_mensaje('Solo se puede eliminar una carga que esta en proceso.', 'exclamation')
	RETURN
END IF
LET int_flag = 0
CALL fl_hacer_pregunta('Desea ELIMINAR esta carga ?', 'No') RETURNING resp
IF resp <> 'Yes' THEN
	CALL mostrar_salir()
	RETURN
END IF
BEGIN WORK
	WHENEVER ERROR CONTINUE
	DECLARE q_elim CURSOR FOR
		SELECT * FROM rept048
			WHERE ROWID = vm_rows2[vm_row_current2]
		FOR UPDATE
	OPEN q_elim
	FETCH q_elim INTO rm_r48.*
	IF STATUS < 0 THEN
		WHENEVER ERROR STOP
		ROLLBACK WORK
		CALL fl_mensaje_bloqueo_otro_usuario()
		RETURN
	END IF
	WHENEVER ERROR STOP
	WHENEVER ERROR CONTINUE
	UPDATE rept048
		SET r48_estado     = 'E',
		    r48_usu_elimin = vg_usuario,
		    r48_fec_elimin = CURRENT
		WHERE r48_compania    = rm_r48.r48_compania
		  AND r48_localidad   = rm_r48.r48_localidad
		  AND r48_composicion = rm_r48.r48_composicion
		  AND r48_item_comp   = rm_r48.r48_item_comp
		  AND r48_sec_carga   = rm_r48.r48_sec_carga
	IF STATUS <> 0 THEN
		ROLLBACK WORK
		WHENEVER ERROR STOP
		CALL fl_mostrar_mensaje('No se puede eliminar el registro para la carga. Por favor llame al ADMINISTRADOR.', 'stop')
		CALL mostrar_salir()
		RETURN
	END IF
	WHENEVER ERROR STOP
	IF NOT control_transferencia('C', 'E', 0) THEN
		ROLLBACK WORK
		CALL mostrar_salir()
		RETURN
	END IF
	WHENEVER ERROR STOP
COMMIT WORK
CALL lee_muestra_registro2(vm_rows2[vm_row_current2])
CALL fl_mostrar_mensaje('Estructura de Carga Eliminada OK.', 'info')

END FUNCTION



FUNCTION control_transferencia(valida_sto, tipo_mant, flag)
DEFINE valida_sto	CHAR(1)
DEFINE tipo_mant	CHAR(1)
DEFINE flag		SMALLINT

IF NOT valida_stock(rm_r48.r48_bodega_comp, valida_sto) THEN
	RETURN 0
END IF
IF NOT procesar_trans('TR', tipo_mant, flag) THEN
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION cargar_stock_item_compuesto()
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r40		RECORD LIKE rept040.*
DEFINE r_r53		RECORD LIKE rept053.*
DEFINE bodega		LIKE rept002.r02_codigo
DEFINE valor_fob	LIKE rept010.r10_fob
DEFINE resp		CHAR(6)
DEFINE mensaje		CHAR(400)
DEFINE i, cargo, resul	SMALLINT
DEFINE insertar		SMALLINT
DEFINE query		CHAR(600)
DEFINE campos		VARCHAR(150)

IF vm_num_oc = 0 THEN
	CALL cargar_ordenes_compras() RETURNING resul
END IF
CALL verificacion_oc()
IF rm_r46.r46_tiene_oc = 'S' AND vm_num_oc = 0 THEN
	CALL fl_mostrar_mensaje('No puede cargar al INVENTARIO esta composición, porque no tiene valores por ordenes de compra.', 'exclamation')
	RETURN
END IF
IF NOT valida_stock(rm_r48.r48_bodega_comp, 'C') THEN
	CALL mostrar_salir()
	RETURN
END IF
LET valor_fob = 0
FOR i = 1 TO vm_num_det
	CALL fl_lee_item(vg_codcia, rm_carga[i].r20_item) RETURNING r_r10.*
	LET valor_fob = valor_fob + (r_r10.r10_fob * rm_carga[i].r20_cant_ven)
END FOR
LET valor_fob = valor_fob / rm_r48.r48_carg_stock
LET cargo     = 0
IF rm_r46.r46_tiene_oc = 'S' AND vm_num_oc = 0 THEN
	LET int_flag = 0
	CALL fl_hacer_pregunta('Desea cargar valores por Ordenes de Compra ?', 'Yes')
		RETURNING resp
	IF resp = 'Yes' THEN
		CALL control_ordenes_compra('P', vm_num_det)
	END IF
END IF
LET int_flag = 0
CALL fl_hacer_pregunta('Desea procesar esta carga al STOCK del INVENTARIO ?', 'Yes')
	RETURNING resp
IF resp <> 'Yes' THEN
	RETURN
END IF
OPEN WINDOW w_repf249_5 AT 07, 17 WITH 06 ROWS, 47 COLUMNS
	ATTRIBUTE(BORDER, FORM LINE FIRST, COMMENT LINE LAST)
IF vg_gui = 1 THEN
	OPEN FORM f_repf249_5 FROM '../forms/repf249_3'
ELSE
	OPEN FORM f_repf249_5 FROM '../forms/repf249_3c'
END IF
DISPLAY FORM f_repf249_5
INITIALIZE vm_bod_aj TO NULL
DECLARE q_bod_c CURSOR FOR
	SELECT r02_codigo, r02_nombre
		FROM rept002
		WHERE r02_compania   = vg_codcia
		  AND r02_localidad  = vg_codloc
		  AND r02_estado     = 'A'
		  AND r02_area       = 'R'
		  AND r02_tipo_ident = 'X'
OPEN q_bod_c
FETCH q_bod_c INTO vm_bod_aj, r_r02.r02_nombre
CLOSE q_bod_c
FREE q_bod_c
DISPLAY BY NAME vm_bod_aj, r_r02.r02_nombre
LET int_flag = 0
INPUT BY NAME vm_bod_aj
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
	ON KEY(F2)
		IF INFIELD(vm_bod_aj) THEN
			CALL fl_ayuda_bodegas_rep(vg_codcia, vg_codloc, 'A',
							'F', 'R', 'T', 'X')
				RETURNING r_r02.r02_codigo, r_r02.r02_nombre
			IF r_r02.r02_codigo IS NOT NULL THEN
				LET vm_bod_aj = r_r02.r02_codigo
				DISPLAY BY NAME vm_bod_aj, r_r02.r02_nombre
			END IF
		END IF
		LET int_flag = 0
	BEFORE FIELD vm_bod_aj
		LET bodega = vm_bod_aj
	AFTER FIELD vm_bod_aj
		IF vm_bod_aj IS NOT NULL THEN
			CALL fl_lee_bodega_rep(vg_codcia, vm_bod_aj)
				RETURNING r_r02.*
			IF r_r02.r02_codigo IS NULL THEN
				CALL fl_mostrar_mensaje('Bodega no existe.', 'exclamation')
				NEXT FIELD vm_bod_aj
			END IF
			IF r_r02.r02_localidad <> vg_codloc THEN
				CALL fl_mostrar_mensaje('Bodega debe ser de esta localidad.','exclamation')
				NEXT FIELD vm_bod_aj
			END IF
			IF r_r02.r02_estado = 'B' THEN
				CALL fl_mostrar_mensaje('Bodega esta bloqueada.','exclamation')
				NEXT FIELD vm_bod_aj
			END IF
			IF r_r02.r02_tipo <> 'F' THEN
				CALL fl_mostrar_mensaje('La Bodega debe ser Física.','exclamation')
				NEXT FIELD vm_bod_aj
			END IF
			IF r_r02.r02_area <> 'R' THEN
				CALL fl_mostrar_mensaje('La Bodega debe ser de INVENTAIRO.','exclamation')
				NEXT FIELD vm_bod_aj
			END IF
			IF r_r02.r02_tipo_ident <> 'X' THEN
			{--
			IF r_r02.r02_tipo_ident <> 'V' AND
			   r_r02.r02_tipo_ident <> 'I' AND
			   r_r02.r02_tipo_ident <> 'S'
			THEN
			--}
				CALL fl_mostrar_mensaje('La Bodega debe ser de tipo Composición.','exclamation')
				NEXT FIELD vm_bod_aj
			END IF
			DISPLAY BY NAME r_r02.r02_nombre
		ELSE
			CLEAR r02_nombre
		END IF
END INPUT
IF int_flag THEN
	LET int_flag = 0
	CLOSE WINDOW w_repf249_5
	CALL mostrar_salir()
	RETURN
END IF
LET int_flag = 0
CLOSE WINDOW w_repf249_5
IF resp = 'Yes' THEN
	BEGIN WORK
		WHENEVER ERROR CONTINUE
		LET campos = ', r10_comentarios = "S/N" '
		LET query  = 'UPDATE rept010',
				' SET r10_costo_mb    = ',
						rm_r48.r48_costo_comp,
				   ', r10_fob         = ', valor_fob,
					campos CLIPPED,
				' WHERE r10_compania = ',
					rm_r48.r48_compania,
				'   AND r10_codigo   = "',
					rm_r48.r48_item_comp CLIPPED,'"'
		PREPARE act_r10 FROM query
		EXECUTE act_r10
		IF STATUS <> 0 THEN
			WHENEVER ERROR STOP
			ROLLBACK WORK
			CALL fl_mostrar_mensaje('No se puede actualizar datos del maestro de ítem. Por favor llame al ADMINISTRADOR.', 'exclamation')
			RETURN
		END IF
		WHENEVER ERROR STOP
		CALL proceso_carga() RETURNING cargo, resul
		IF NOT cargo THEN
			CALL mostrar_salir()
			RETURN
		END IF
	COMMIT WORK
END IF
IF NOT cargo THEN
	CALL mostrar_salir()
	RETURN
END IF
DECLARE q_cont_ajuste CURSOR WITH HOLD FOR
	SELECT * FROM rept053
		WHERE r53_compania    = vg_codcia
		  AND r53_localidad   = vg_codloc
		  AND r53_composicion = rm_r48.r48_composicion
		  AND r53_item_comp   = rm_r48.r48_item_comp
		  AND r53_sec_carga   = rm_r48.r48_sec_carga
		  AND r53_cod_tran    = 'AC'
		ORDER BY r53_num_tran
FOREACH q_cont_ajuste INTO r_r53.*
	IF r_r53.r53_cod_tran = 'AC' THEN
		LET r_r53.r53_cod_tran = 'CI'
	END IF
	CALL fl_control_master_contab_repuestos(r_r53.r53_compania,
						r_r53.r53_localidad,
						r_r53.r53_cod_tran,
						r_r53.r53_num_tran)
END FOREACH
IF resul = 1 THEN
	DECLARE q_cont_ajuste2 CURSOR WITH HOLD FOR
		SELECT * FROM rept053
			WHERE r53_compania    = vg_codcia
			  AND r53_localidad   = vg_codloc
			  AND r53_composicion = rm_r48.r48_composicion
			  AND r53_item_comp   = rm_r48.r48_item_comp
			  AND r53_sec_carga   = rm_r48.r48_sec_carga
			  AND r53_cod_tran    = 'A+'
			ORDER BY r53_num_tran
	FOREACH q_cont_ajuste2 INTO r_r53.*
		INITIALIZE r_r40.* TO NULL
		SELECT * INTO r_r40.*
			FROM rept040
			WHERE r40_compania  = r_r53.r53_compania
			  AND r40_localidad = r_r53.r53_localidad
			  AND r40_cod_tran  = r_r53.r53_cod_tran
			  AND r40_num_tran  = r_r53.r53_num_tran
		CALL fl_mayoriza_comprobante(r_r40.r40_compania,
						r_r40.r40_tipo_comp,
						r_r40.r40_num_comp, 'M')
	END FOREACH
END IF
CALL lee_muestra_registro2(vm_rows2[vm_row_current2])
LET mensaje = 'Carga de Item ', rm_r48.r48_item_comp CLIPPED,
		' Procesada OK.'
CALL fl_mostrar_mensaje(mensaje CLIPPED, 'info')
CALL control_imprimir_carga()
CALL control_detalle_trans()

END FUNCTION



FUNCTION proceso_carga()
DEFINE resul, i		SMALLINT
DEFINE mensaje		VARCHAR(200)

LET resul = 0
FOR i = 1 TO vm_num_det
	WHENEVER ERROR CONTINUE
	UPDATE rept047
		SET r47_costo_part = rm_carga[i].r20_costnue_mb
		WHERE r47_compania    = rm_r48.r48_compania
		  AND r47_localidad   = rm_r48.r48_localidad
		  AND r47_composicion = rm_r48.r48_composicion
		  AND r47_item_comp   = rm_r48.r48_item_comp
		  AND r47_bodega_part = rm_carga[i].r20_bodega
		  AND r47_item_part   = rm_carga[i].r20_item
	IF STATUS <> 0 THEN
		ROLLBACK WORK
		WHENEVER ERROR STOP
		LET mensaje = 'No se puede actualizar el costo del ítem: ',
				rm_carga[vm_num_det].r20_item CLIPPED,
				' en la composición. Por favor llame al ',
				'ADMINISTRADOR.'
		CALL fl_mostrar_mensaje(mensaje, 'stop')
		EXIT FOR
	END IF
	WHENEVER ERROR STOP
	LET resul = 1
END FOR
IF resul = 0 THEN
	RETURN 0, 0
END IF
IF NOT procesar_trans('A-', 'C', 0) THEN
	RETURN 0, 0
END IF
IF NOT procesar_trans('A+', 'C', 0) THEN
	RETURN 0, 0
END IF
CALL procesar_diario_tr() RETURNING resul
IF resul = 0 THEN
	RETURN 0, 0
END IF
IF NOT procesar_trans('AC', 'C', 0) THEN
	RETURN 0, 0
END IF
LET rm_r48.r48_estado     = 'C'
LET rm_r48.r48_usu_cierre = vg_usuario
LET rm_r48.r48_fec_cierre = CURRENT
UPDATE rept048
	SET r48_estado     = rm_r48.r48_estado,
	    r48_usu_cierre = rm_r48.r48_usu_cierre,
	    r48_fec_cierre = rm_r48.r48_fec_cierre
	WHERE r48_compania    = rm_r48.r48_compania
	  AND r48_localidad   = rm_r48.r48_localidad
	  AND r48_composicion = rm_r48.r48_composicion
	  AND r48_item_comp   = rm_r48.r48_item_comp
	  AND r48_sec_carga   = rm_r48.r48_sec_carga
IF STATUS <> 0 THEN
	ROLLBACK WORK
	WHENEVER ERROR STOP
	CALL fl_mostrar_mensaje('No se puede actualizar el estado de la carga del stock para el ítem compuesto. Por favor llame al ADMINISTRADOR.', 'stop')
	RETURN 0, 0
END IF
WHENEVER ERROR STOP
RETURN 1, resul

END FUNCTION



FUNCTION retorna_secuencia_carga()
DEFINE sec_carga	LIKE rept048.r48_sec_carga

SELECT NVL(MAX(r48_sec_carga) + 1, 1)
	INTO sec_carga
	FROM rept048
	WHERE r48_compania    = rm_r48.r48_compania
	  AND r48_localidad   = rm_r48.r48_localidad
	  AND r48_composicion = rm_r48.r48_composicion
RETURN sec_carga

END FUNCTION



FUNCTION leer_datos_comp(flag, flag2)
DEFINE flag		CHAR(1)
DEFINE flag2		SMALLINT

CALL leer_datos2(flag)
IF int_flag THEN
	CALL mostrar_salir()
	RETURN 0
END IF
--IF flag2 = 1 THEN
	CALL muestra_detalle2()
	CALL leer_detalle2()
	IF int_flag THEN
		CALL mostrar_salir()
		RETURN 0
	END IF
--END IF
RETURN 1

END FUNCTION



FUNCTION leer_datos2(flag)
DEFINE flag		CHAR(1)
DEFINE resp 		CHAR(6)
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r46		RECORD LIKE rept046.*
DEFINE bodega		LIKE rept002.r02_codigo
DEFINE composi		LIKE rept046.r46_composicion
DEFINE car_sto		LIKE rept048.r48_carg_stock
DEFINE val_mo		LIKE rept048.r48_costo_mo

LET int_flag = 0
INPUT BY NAME rm_r48.r48_composicion, rm_r48.r48_bodega_comp,
	rm_r48.r48_referencia, rm_r48.r48_costo_mo, rm_r48.r48_carg_stock
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(r48_composicion, r48_bodega_comp,
					r48_referencia, r48_costo_mo,
					r48_carg_stock)
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
		IF INFIELD(r48_composicion) THEN
			IF flag = 'M' THEN
				CONTINUE INPUT
			END IF
			CALL fl_ayuda_items_compuestos(vg_codcia, vg_codloc,'C')
				RETURNING composi, r_r10.r10_codigo,
						r_r10.r10_nombre
			IF r_r10.r10_codigo IS NOT NULL THEN
				LET rm_r48.r48_composicion = composi
				LET rm_r48.r48_item_comp   = r_r10.r10_codigo
				DISPLAY BY NAME rm_r48.r48_composicion,
						rm_r48.r48_item_comp
				DISPLAY r_r10.r10_nombre TO r46_desc_comp
			END IF
		END IF
		IF INFIELD(r48_bodega_comp) THEN
			CALL fl_ayuda_bodegas_rep(vg_codcia, vg_codloc, 'A',
							'F', 'R', 'T', 'S')
				RETURNING r_r02.r02_codigo, r_r02.r02_nombre
			IF r_r02.r02_codigo IS NOT NULL THEN
				LET rm_r48.r48_bodega_comp = r_r02.r02_codigo
				DISPLAY BY NAME rm_r48.r48_bodega_comp,
						r_r02.r02_nombre
			END IF
		END IF
		LET int_flag = 0
	ON KEY(F5)
		IF rm_r46.r46_tiene_oc = 'S' THEN
			CALL control_ordenes_compra('P', vm_num_det)
			LET int_flag = 0
		END IF
	BEFORE INPUT 
		IF rm_r46.r46_tiene_oc = 'S' THEN
                	CALL dialog.keysetlabel("F5", "Ordenes Compra")
		ELSE
                	CALL dialog.keysetlabel("F5", "")
		END IF
	BEFORE FIELD r48_composicion
		LET composi = rm_r48.r48_composicion
	BEFORE FIELD r48_bodega_comp
		LET bodega = rm_r48.r48_bodega_comp
	BEFORE FIELD r48_carg_stock
		LET car_sto = rm_r48.r48_carg_stock
	BEFORE FIELD r48_costo_mo
		LET val_mo = rm_r48.r48_costo_mo
	AFTER FIELD r48_composicion
		IF flag = 'M' THEN
			LET rm_r48.r48_composicion = composi
			DISPLAY BY NAME rm_r48.r48_composicion
			CONTINUE INPUT
		END IF
		IF rm_r48.r48_composicion IS NOT NULL THEN
			CALL fl_lee_composicion_cab3(vg_codcia, vg_codloc,
						rm_r48.r48_composicion)
				RETURNING r_r46.*
			IF r_r46.r46_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Numero de composición no existe.', 'exclamation')
				NEXT FIELD r48_composicion
			END IF
			IF r_r46.r46_estado <> 'C' THEN
				CALL fl_mostrar_mensaje('Esta composición no esta cerrada.', 'exclamation')
				NEXT FIELD r48_composicion
			END IF
			LET rm_r48.r48_item_comp = r_r46.r46_item_comp
			DISPLAY BY NAME rm_r48.r48_item_comp,
					r_r46.r46_desc_comp
		ELSE
			LET rm_r48.r48_item_comp = NULL
			CLEAR r48_item_comp, r46_desc_comp
		END IF
	AFTER FIELD r48_bodega_comp
		IF rm_r48.r48_bodega_comp IS NOT NULL THEN
			CALL fl_lee_bodega_rep(vg_codcia,rm_r48.r48_bodega_comp)
				RETURNING r_r02.*
			IF r_r02.r02_codigo IS NULL THEN
				CALL fl_mostrar_mensaje('Bodega no existe.', 'exclamation')
				NEXT FIELD r48_bodega_comp
			END IF
			IF r_r02.r02_localidad <> vg_codloc THEN
				CALL fl_mostrar_mensaje('Bodega debe ser de esta localidad.','exclamation')
				NEXT FIELD r48_bodega_comp
			END IF
			IF r_r02.r02_estado = 'B' THEN
				CALL fl_mostrar_mensaje('Bodega esta bloqueada.','exclamation')
				NEXT FIELD r48_bodega_comp
			END IF
			IF r_r02.r02_tipo <> 'F' THEN
				CALL fl_mostrar_mensaje('La Bodega debe ser Física.','exclamation')
				NEXT FIELD r48_bodega_comp
			END IF
			IF r_r02.r02_area <> 'R' THEN
				CALL fl_mostrar_mensaje('La Bodega debe ser de INVENTAIRO.','exclamation')
				NEXT FIELD r48_bodega_comp
			END IF
			IF r_r02.r02_tipo_ident <> 'S' THEN
				CALL fl_mostrar_mensaje('La Bodega debe ser de tipo SubFactory.','exclamation')
				NEXT FIELD r48_bodega_comp
			END IF
			DISPLAY BY NAME r_r02.r02_nombre
		ELSE
			CLEAR r02_nombre
		END IF
	AFTER FIELD r48_carg_stock
		IF rm_r48.r48_carg_stock IS NULL THEN
			LET rm_r48.r48_carg_stock = car_sto
			DISPLAY BY NAME rm_r48.r48_carg_stock
		END IF
	AFTER FIELD r48_costo_mo
		IF rm_r48.r48_costo_mo IS NULL THEN
			LET rm_r48.r48_costo_mo = val_mo
			DISPLAY BY NAME rm_r48.r48_costo_mo
		END IF
	AFTER INPUT
		LET rm_r48.r48_referencia = rm_r48.r48_referencia CLIPPED
		IF rm_r48.r48_referencia IS NULL THEN
			CALL fl_mostrar_mensaje('Digite la referencia.', 'exclamation')
			NEXT FIELD r48_referencia
		END IF
		IF flag = 'I' THEN
			IF existe_otra_carga_en_proceso() THEN
				CONTINUE INPUT
			END IF
		END IF
END INPUT
IF int_flag THEN
	RETURN
END IF
CALL fl_lee_composicion_cab2(vg_codcia, vg_codloc, rm_r48.r48_composicion,
				rm_r48.r48_item_comp)
	RETURNING rm_r46.*

END FUNCTION



FUNCTION existe_otra_carga_en_proceso()
DEFINE r_r48		RECORD LIKE rept048.*

INITIALIZE r_r48.* TO NULL
DECLARE q_carg_act CURSOR FOR
	SELECT * FROM rept048
		WHERE r48_compania     = rm_r48.r48_compania
		  AND r48_localidad    = rm_r48.r48_localidad
		  AND r48_composicion  = rm_r48.r48_composicion
		  AND r48_item_comp    = rm_r48.r48_item_comp
		  AND r48_estado       = 'P'
OPEN q_carg_act
FETCH q_carg_act INTO r_r48.*
CLOSE q_carg_act
FREE q_carg_act
IF r_r48.r48_compania IS NOT NULL THEN
	CALL fl_mostrar_mensaje('Existe una carga EN PROCESO para esta composición.', 'exclamation')
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION leer_detalle2()
DEFINE bodega		LIKE rept048.r48_bodega_comp
DEFINE resp 		CHAR(6)
DEFINE i, j		SMALLINT

LET int_flag = 0
CALL set_count(vm_num_det)
INPUT ARRAY rm_carga WITHOUT DEFAULTS FROM rm_carga.*
	ON KEY(INTERRUPT)
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
	ON KEY(F5)
		IF rm_g05.g05_grupo = 'SI' OR rm_g05.g05_grupo = 'GE' THEN
			LET i = arr_curr()
			CALL mostrar_item(rm_r48.r48_item_comp)
			LET int_flag = 0
		END IF
	ON KEY(F6)
		IF rm_g05.g05_grupo = 'SI' OR rm_g05.g05_grupo = 'GE' THEN
			LET i = arr_curr()
			IF rm_carga[i].r20_item IS NOT NULL THEN
				CALL mostrar_item(rm_carga[i].r20_item)
				LET int_flag = 0
			END IF
		END IF
	ON KEY(F7)
		LET i = arr_curr()
		CALL control_stock_items(rm_r48.r48_item_comp, 0)
		LET int_flag = 0
	ON KEY(F8)
		LET i = arr_curr()
		IF rm_carga[i].r20_item IS NOT NULL THEN
			CALL control_stock_items(rm_carga[i].r20_item, i)
			LET int_flag = 0
		END IF
	BEFORE INPUT 
		--#CALL dialog.keysetlabel("INSERT", "")
		--#CALL dialog.keysetlabel("DELETE", "")
		--#CALL dialog.keysetlabel("F7", "Stock Item Comp.")
	BEFORE INSERT
		--#CANCEL INSERT
	BEFORE DELETE
		--#CANCEL DELETE
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
		CALL mostrar_etiquetas(i, vm_num_det)
		--CALL datos_item_det(r_r10, i, j)
		IF rm_g05.g05_grupo = 'SI' OR rm_g05.g05_grupo = 'GE' THEN
			CALL dialog.keysetlabel("F5", "Item Composición")
			IF rm_carga[i].r20_item IS NOT NULL THEN
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
		CALL mostrar_total(vm_num_det)
	BEFORE FIELD r20_bodega
		LET bodega = rm_carga[i].r20_bodega
	AFTER FIELD r20_bodega
		LET rm_carga[i].r20_bodega = bodega
		DISPLAY rm_carga[i].r20_bodega TO rm_carga[j].r20_bodega
	AFTER INPUT
		LET vm_num_det = arr_count()
END INPUT
CALL muestra_contadores_det(0, vm_num_det)

END FUNCTION



FUNCTION datos_item_det(r_r10, i, j)
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE i, j		SMALLINT
DEFINE r_r03		RECORD LIKE rept003.*
DEFINE r_r70		RECORD LIKE rept070.*
DEFINE r_r71		RECORD LIKE rept071.*
DEFINE r_r72		RECORD LIKE rept072.*
DEFINE r_r73		RECORD LIKE rept073.*

LET rm_adi[i].r47_division_p      = r_r10.r10_linea
LET rm_adi[i].r47_sub_linea_p     = r_r10.r10_sub_linea
LET rm_adi[i].r47_cod_grupo_p     = r_r10.r10_cod_grupo
LET rm_adi[i].r47_cod_clase_p     = r_r10.r10_cod_clase
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
CALL fl_lee_marca_rep(vg_codcia, rm_carga[i].r47_marca_p) RETURNING r_r73.*
LET rm_adi[i].r47_nom_div_p       = r_r03.r03_nombre
LET rm_adi[i].r47_desc_sub_p      = r_r70.r70_desc_sub
LET rm_adi[i].r47_desc_grupo_p    = r_r71.r71_desc_grupo
LET rm_adi[i].r47_desc_clase_p    = r_r72.r72_desc_clase
LET rm_adi[i].descripcion         = r_r10.r10_nombre
LET rm_adi[i].r47_desc_marca_p    = r_r73.r73_desc_marca
DISPLAY BY NAME rm_adi[i].r47_nom_div_p, rm_adi[i].r47_desc_sub_p,
		rm_adi[i].r47_desc_grupo_p, rm_adi[i].r47_desc_clase_p,
		rm_adi[i].descripcion

END FUNCTION



FUNCTION mostrar_total(max_row)
DEFINE max_row		SMALLINT
DEFINE i		SMALLINT

LET rm_r48.r48_costo_inv  = 0.00
FOR i = 1 TO max_row
	IF rm_carga[i].r20_costnue_mb IS NULL OR
	   rm_carga[i].r20_cant_ven IS NULL
	THEN
		CONTINUE FOR
	END IF
	LET rm_r48.r48_costo_inv = rm_r48.r48_costo_inv +
		(rm_carga[i].r20_costnue_mb * rm_carga[i].r20_cant_ven)
END FOR
LET rm_r48.r48_costo_comp = rm_r48.r48_costo_inv + rm_r48.r48_costo_oc
DISPLAY BY NAME rm_r48.r48_costo_inv, rm_r48.r48_costo_oc, rm_r48.r48_costo_comp

END FUNCTION



FUNCTION control_consulta()
DEFINE flag		CHAR(1)
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE composi		LIKE rept046.r46_composicion
DEFINE expr_sql		CHAR(1500)
DEFINE query		CHAR(3000)

CALL borrar_cabecera2()
CALL borrar_detalle2()
IF num_args() = 4 THEN
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON r48_estado, r48_composicion,r48_sec_carga,
		r48_item_comp, r48_referencia, r48_usu_cierre, r48_fec_cierre,
		r48_usuario, r48_fecing
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT CONSTRUCT
		ON KEY(F2)
			IF INFIELD(r48_item_comp) THEN
				CALL fl_ayuda_items_compuestos(vg_codcia,
								vg_codloc,'C')
					RETURNING composi, r_r10.r10_codigo,
							r_r10.r10_nombre
				IF r_r10.r10_codigo IS NOT NULL THEN
					LET rm_r48.r48_item_comp =
								r_r10.r10_codigo
					DISPLAY BY NAME rm_r48.r48_item_comp
					DISPLAY r_r10.r10_nombre TO
						r46_desc_comp
				END IF
			END IF
			LET int_flag = 0
		AFTER FIELD r48_item_comp
			LET r_r10.r10_codigo = GET_FLDBUF(r48_item_comp)
			IF r_r10.r10_codigo IS NOT NULL THEN
				CALL fl_lee_item(vg_codcia, r_r10.r10_codigo)
					RETURNING r_r10.*
				IF r_r10.r10_compania IS NULL THEN
					CALL fl_mostrar_mensaje('Item no existe.', 'exclamation')
					NEXT FIELD r48_item_comp
				END IF
			ELSE
				CLEAR r48_item_comp, r46_desc_comp
			END IF
	END CONSTRUCT
	IF int_flag THEN
		CALL mostrar_salir()
		RETURN
	END IF
ELSE
	LET expr_sql = 'r48_composicion = ', arg_val(5),
			'  AND r48_item_comp = "', arg_val(6) CLIPPED, '"',
			'  AND r48_sec_carga = ', arg_val(7)
END IF
IF NOT consulta_carga_stock(expr_sql) THEN
	RETURN
END IF

END FUNCTION



{--
FUNCTION cambiar_bodega_comp()
DEFINE query		CHAR(6000)
DEFINE num_aux		INTEGER

LET query = 'INSERT INTO rept046 ',
		'(r46_compania, r46_localidad, r46_composicion,',
		' r46_item_comp, r46_estado, r46_cod_ventas,',
		' r46_desc_comp, r48_costo_inv, r48_costo_oc, r48_costo_mo,',
		' r48_costo_comp, r46_division_c, r46_nom_div_c,',
		' r46_sub_linea_c, r46_desc_sub_c, r46_cod_grupo_c,',
		' r46_desc_grupo_c, r46_cod_clase_c, r46_desc_clase_c,',
		' r46_marca_c, r46_desc_marca_c, r46_referencia,',
		' r48_carg_stock, r46_usu_modifi, r46_fec_modifi,',
		' r46_usu_cierre, r46_fec_cierre, r46_usuario, r46_fecing) ',
		'SELECT r46_compania, r46_localidad,r46_composicion,',
			' r46_item_comp,',
			' r46_estado, r46_cod_ventas, r46_desc_comp,',
			' r48_costo_inv, r48_costo_oc, r48_costo_mo,',
			' r48_costo_comp, r46_division_c, r46_nom_div_c,',
			' r46_sub_linea_c, r46_desc_sub_c, r46_cod_grupo_c,',
			' r46_desc_grupo_c, r46_cod_clase_c, r46_desc_clase_c,',
			' r46_marca_c, r46_desc_marca_c, r46_referencia,',
			' r48_carg_stock, r46_usu_modifi, r46_fec_modifi,',
			' r46_usu_cierre, r46_fec_cierre, r46_usuario,',
			' r46_fecing ',
			'FROM rept046 ',
			' WHERE r46_compania    = ', rm_r48.r48_compania,
			'   AND r46_localidad   = ', rm_r48.r48_localidad,
			'   AND r46_composicion = ', rm_r48.r48_composicion,
			'   AND r46_item_comp   = "', rm_r48.r48_item_comp, '"'
WHENEVER ERROR CONTINUE
PREPARE ins_r46 FROM query
EXECUTE ins_r46
IF STATUS <> 0 THEN
	WHENEVER ERROR STOP
	CALL fl_mostrar_mensaje('No se puede actualizar la bodega en la cabecera de la composición. Por favor llame al ADMINISTRADOR.', 'exclamation')
	RETURN 0, 0
END IF
LET num_aux = SQLCA.SQLERRD[6]
LET query = 'INSERT INTO rept047 ',
		'(r47_compania, r47_localidad, r47_composicion,',
		' r47_item_comp, r47_bodega_part,',
		' r47_item_part, r47_desc_part, r47_costo_part, r47_cantidad,',
		' r47_division_p, r47_nom_div_p, r47_sub_linea_p,',
		' r47_desc_sub_p, r47_cod_grupo_p, r47_desc_grupo_p,',
		' r47_cod_clase_p, r47_desc_clase_p, r47_marca_p,',
		' r47_desc_marca_p) ',
		'SELECT r47_compania, r47_localidad, r47_composicion,',
			' r47_item_comp,',
			' r47_bodega_part, r47_item_part, r47_desc_part,',
			' r47_costo_part, r47_cantidad, r47_division_p,',
			' r47_nom_div_p, r47_sub_linea_p, r47_desc_sub_p,',
			' r47_cod_grupo_p, r47_desc_grupo_p, r47_cod_clase_p,',
			' r47_desc_clase_p, r47_marca_p, r47_desc_marca_p ',
			'FROM rept047 ',
			' WHERE r47_compania    = ', rm_r48.r48_compania,
			'   AND r47_localidad   = ', rm_r48.r48_localidad,
			'   AND r47_composicion = ', rm_r48.r48_composicion,
			'   AND r47_item_comp   = "', rm_r48.r48_item_comp, '"'
WHENEVER ERROR CONTINUE
PREPARE ins_r47 FROM query
EXECUTE ins_r47
IF STATUS <> 0 THEN
	WHENEVER ERROR STOP
	CALL fl_mostrar_mensaje('No se puede actualizar la bodega en el detalle de la composición. Por favor llame al ADMINISTRADOR.', 'exclamation')
	RETURN 0, 0
END IF
LET query = 'INSERT INTO rept053 ',
		'(r53_compania, r53_localidad, r53_composicion,',
		' r53_item_comp, r53_sec_carga, r53_cod_tran, r53_num_tran,',
		' r53_usuario, r53_fecing) ',
		'SELECT r53_compania, r53_localidad, r53_composicion,',
			' r53_item_comp, r53_sec_carga, r53_cod_tran,',
			' r53_num_tran, r53_usuario, r53_fecing ',
			'FROM rept053 ',
			' WHERE r53_compania    = ', rm_r48.r48_compania,
			'   AND r53_localidad   = ', rm_r48.r48_localidad,
			'   AND r53_composicion = ', rm_r48.r48_composicion,
			'   AND r53_item_comp   = "', rm_r48.r48_item_comp, '"'
WHENEVER ERROR CONTINUE
PREPARE ins_r53 FROM query
EXECUTE ins_r53
IF STATUS <> 0 THEN
	WHENEVER ERROR STOP
	CALL fl_mostrar_mensaje('No se puede actualizar la bodega en la tabla relacional de la composición. Por favor llame al ADMINISTRADOR.', 'exclamation')
	RETURN 0, 0
END IF
LET query = 'INSERT INTO rept049 ',
		'(r49_compania, r49_localidad, r49_composicion,',
		' r49_item_comp, r49_sec_carga, r49_numero_oc, r49_costo_oc,',
		' r49_cant_unid, r49_usuario, r49_fecing) ',
		'SELECT r49_compania, r49_localidad, r49_composicion,',
			' r49_item_comp, r49_sec_carga, r49_numero_oc,',
			' r49_costo_oc, r49_cant_unid, r49_usuario, r49_fecing',
			' FROM rept049 ',
			' WHERE r49_compania    = ', rm_r48.r48_compania,
			'   AND r49_localidad   = ', rm_r48.r48_localidad,
			'   AND r49_composicion = ', rm_r48.r48_composicion,
			'   AND r49_item_comp   = "', rm_r48.r48_item_comp, '"'
			'   AND r49_sec_carga   = ', rm_r48.r48_sec_carga
WHENEVER ERROR CONTINUE
PREPARE ins_r49 FROM query
EXECUTE ins_r49
IF STATUS <> 0 THEN
	WHENEVER ERROR STOP
	CALL fl_mostrar_mensaje('No se puede actualizar la bodega en la tabla de ordenes de compra de la composición. Por favor llame al ADMINISTRADOR.', 'exclamation')
	RETURN 0, 0
END IF
WHENEVER ERROR CONTINUE
DELETE FROM rept049
	WHERE r49_compania    = rm_r48.r48_compania
	  AND r49_localidad   = rm_r48.r48_localidad
	  AND r49_composicion = rm_r48.r48_composicion
	  AND r49_item_comp   = rm_r48.r48_item_comp
	  AND r49_sec_carga   = rm_r48.r48_sec_carga
IF STATUS <> 0 THEN
	WHENEVER ERROR STOP
	CALL fl_mostrar_mensaje('No se puede eliminar el registro anterior de ordenes de compra de la composición. Por favor llame al ADMINISTRADOR.', 'exclamation')
	RETURN 0, 0
END IF
WHENEVER ERROR CONTINUE
DELETE FROM rept053
	WHERE r53_compania    = rm_r48.r48_compania
	  AND r53_localidad   = rm_r48.r48_localidad
	  AND r53_composicion = rm_r48.r48_composicion
	  AND r53_item_comp   = rm_r48.r48_item_comp
IF STATUS <> 0 THEN
	WHENEVER ERROR STOP
	CALL fl_mostrar_mensaje('No se puede eliminar el registro anterior de tabla relacional de la composición. Por favor llame al ADMINISTRADOR.', 'exclamation')
	RETURN 0, 0
END IF
WHENEVER ERROR CONTINUE
DELETE FROM rept047
	WHERE r47_compania    = rm_r48.r48_compania
	  AND r47_localidad   = rm_r48.r48_localidad
	  AND r47_composicion = rm_r48.r48_composicion
	  AND r47_item_comp   = rm_r48.r48_item_comp
IF STATUS <> 0 THEN
	WHENEVER ERROR STOP
	CALL fl_mostrar_mensaje('No se puede eliminar el registro anterior del detalle de la composición. Por favor llame al ADMINISTRADOR.', 'exclamation')
	RETURN 0, 0
END IF
WHENEVER ERROR CONTINUE
DELETE FROM rept046
	WHERE r46_compania    = rm_r48.r48_compania
	  AND r46_localidad   = rm_r48.r48_localidad
	  AND r46_composicion = rm_r48.r48_composicion
	  AND r46_item_comp   = rm_r48.r48_item_comp
IF STATUS <> 0 THEN
	WHENEVER ERROR STOP
	CALL fl_mostrar_mensaje('No se puede eliminar el registro anterior de la cabecera de la composición. Por favor llame al ADMINISTRADOR.', 'exclamation')
	RETURN 0, 0
END IF
WHENEVER ERROR STOP
RETURN 1, num_aux

END FUNCTION
--}



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

IF vm_num_rows2 = vm_max_rows THEN
	LET vm_num_rows2 = 1
ELSE
	IF flag = 'I' THEN
		LET vm_num_rows2 = vm_num_rows2 + 1
	END IF
END IF
LET vm_row_current2       = vm_num_rows2
LET vm_rows2[vm_num_rows2] = num_aux
CALL lee_muestra_registro2(vm_rows2[vm_row_current2])

END FUNCTION



FUNCTION mostrar_salir()

IF vm_num_rows2 = 0 THEN
	CALL borrar_cabecera2()
	CALL borrar_detalle2()
ELSE
	CALL lee_muestra_registro2(vm_rows2[vm_row_current2])
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



FUNCTION borrar_cabecera2()

INITIALIZE rm_r48.* TO NULL
CLEAR num_cur, max_cur, r48_composicion, r48_bodega_comp, r02_nombre,
	r48_item_comp, r46_desc_comp, r48_referencia, r48_carg_stock,
	r48_costo_mo, r48_estado, nom_est, r48_usu_cierre, r48_fec_cierre,
	r48_usuario, r48_fecing

END FUNCTION



FUNCTION borrar_detalle2()
DEFINE i		SMALLINT

FOR i = 1 TO fgl_scr_size('rm_carga')
	CLEAR rm_carga[i].*
END FOR
FOR i = 1 TO vm_max_det
	INITIALIZE rm_carga[i].*, rm_adi[i].* TO NULL
END FOR
CLEAR num_row, max_row, r47_nom_div_p, r47_desc_sub_p, r47_desc_grupo_p,
	r47_desc_clase_p, descripcion, r48_costo_inv, r48_costo_oc,
	r48_costo_comp

END FUNCTION



FUNCTION mostrar_cabecera_forma()

DISPLAY "Bodega"	TO tit_col1
DISPLAY "Item P."	TO tit_col2
DISPLAY "Descripción"	TO tit_col3
DISPLAY "Cantidad"	TO tit_col4
DISPLAY "Costo"		TO tit_col5
DISPLAY "Marca"		TO tit_col6

END FUNCTION



FUNCTION valida_stock(bodega, flag)
DEFINE bodega		LIKE rept002.r02_codigo
DEFINE flag		CHAR(1)
DEFINE mensaje		CHAR(400)
DEFINE i, resul		SMALLINT

LET resul = 1
FOR i = 1 TO vm_num_det
	IF flag = 'D' THEN
		LET bodega = rm_carga[i].r20_bodega
	END IF
	IF retorna_item_stock(bodega, rm_carga[i].r20_item) <= 0 THEN
		LET mensaje = 'El stock actual en la bodega: ',
				bodega, ' es ',
				retorna_item_stock(bodega,
				rm_carga[i].r20_item) USING "---,--&.##",
				' del ítem ', rm_carga[i].r20_item CLIPPED,
				'.\n',
				'\n No se puede generar composición.'
		CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
		LET resul = 0
		EXIT FOR
	END IF
	IF rm_carga[i].r20_cant_ven > retorna_item_stock(bodega,
							rm_carga[i].r20_item)
	THEN
		LET mensaje = 'La cantidad del ítem:       ',
				rm_carga[i].r20_item CLIPPED, ' es  ',
				rm_carga[i].r20_cant_ven USING "##,##&.##",
				{--
				'\nPOR ',
				rm_r48.r48_carg_stock USING "##,##&.##",
				' UNIDADES.\n\n',
				--}
				'\n\nEl stock actual en la bodega: ',
				bodega, ' es ',
				retorna_item_stock(bodega,
				rm_carga[i].r20_item) USING "---,--&.##",
				'.\n',
				'\n No se puede obtener stock de las partes.'
		CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
		LET resul = 0
		EXIT FOR
	END IF
END FOR
RETURN resul

END FUNCTION



FUNCTION procesar_trans(cod_tran, flag, tipo_llamada)
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE flag		CHAR(1)
DEFINE tipo_llamada	SMALLINT

IF cod_tran = 'TR' THEN
	IF NOT genera_transferencia(flag, tipo_llamada) THEN
		ROLLBACK WORK
		RETURN 0
	END IF
	RETURN 1
END IF
IF NOT transaccion_aj(cod_tran) THEN
	ROLLBACK WORK
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION genera_transferencia(flag, tipo_llamada)
DEFINE flag		CHAR(1)
DEFINE tipo_llamada	SMALLINT
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE r_r46		RECORD LIKE rept046.*
DEFINE r_r47		RECORD LIKE rept047.*
DEFINE stock_act	LIKE rept011.r11_stock_act
DEFINE mensaje		VARCHAR(200)
DEFINE i, resul		SMALLINT

INITIALIZE r_r19.* TO NULL
CALL fl_lee_composicion_cab3(vg_codcia, vg_codloc, rm_r48.r48_composicion)
	RETURNING r_r46.*
LET r_r19.r19_compania		= vg_codcia
LET r_r19.r19_localidad   	= vg_codloc
LET r_r19.r19_cod_tran    	= 'TR'
CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, vg_modulo, 'AA',
					r_r19.r19_cod_tran)
	RETURNING r_r19.r19_num_tran
IF r_r19.r19_num_tran = 0 THEN
	CALL fl_mostrar_mensaje('No existe control de secuencia para esta transacción, no se puede asignar un número de transacción a la operación.','stop')
	RETURN 0
END IF
IF r_r19.r19_num_tran = -1 THEN
	SET LOCK MODE TO WAIT
	WHILE r_r19.r19_num_tran = -1
		CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, 
							vg_modulo, 'AA',
							r_r19.r19_cod_tran)
			RETURNING r_r19.r19_num_tran
	END WHILE
	SET LOCK MODE TO NOT WAIT
END IF
LET r_r19.r19_cont_cred		= 'C'
CASE flag
	WHEN 'I' LET r_r19.r19_referencia = 'TR. GEN. COMP.# '
	WHEN 'E' LET r_r19.r19_referencia = 'TR. ELI. COMP.# '
	WHEN 'M'
		IF tipo_llamada = 1 THEN
			LET r_r19.r19_referencia = 'TR. M.ELI. COMP.# '
		END IF
		IF tipo_llamada = 2 THEN
			LET r_r19.r19_referencia = 'TR. M.GEN. COMP.# '
		END IF
END CASE
LET r_r19.r19_referencia	= r_r19.r19_referencia CLIPPED, ' ',
					rm_r48.r48_composicion USING "<<<<<&",
					' BD ', rm_r48.r48_bodega_comp CLIPPED,
					' ', rm_r48.r48_item_comp CLIPPED
LET r_r19.r19_nomcli		= ' '
LET r_r19.r19_dircli     	= ' '
LET r_r19.r19_cedruc     	= ' '
LET r_r19.r19_vendedor   	= r_r46.r46_cod_ventas
LET r_r19.r19_descuento  	= 0.0
LET r_r19.r19_porc_impto 	= 0.0
CASE flag
	WHEN 'I'
		LET r_r19.r19_bodega_ori  = vm_bod_comp
		LET r_r19.r19_bodega_dest = rm_r48.r48_bodega_comp
	WHEN 'E'
		LET r_r19.r19_bodega_ori  = rm_r48.r48_bodega_comp
		LET r_r19.r19_bodega_dest = vm_bod_comp
	WHEN 'M'
		IF tipo_llamada = 1 THEN
			LET r_r19.r19_bodega_ori  = rm_r48.r48_bodega_comp
			LET r_r19.r19_bodega_dest = vm_bod_comp
		END IF
		IF tipo_llamada = 2 THEN
			LET r_r19.r19_bodega_ori  = vm_bod_comp
			LET r_r19.r19_bodega_dest = rm_r48.r48_bodega_comp
		END IF
END CASE
LET r_r19.r19_moneda     	= rg_gen.g00_moneda_base
LET r_r19.r19_precision  	= rg_gen.g00_decimal_mb
LET r_r19.r19_paridad    	= 1
LET r_r19.r19_tot_costo  	= 0
LET r_r19.r19_tot_bruto  	= 0.0
LET r_r19.r19_tot_dscto  	= 0.0
LET r_r19.r19_tot_neto		= r_r19.r19_tot_costo
LET r_r19.r19_flete      	= 0.0
LET r_r19.r19_usuario      	= vg_usuario
LET r_r19.r19_fecing      	= CURRENT
INSERT INTO rept019 VALUES (r_r19.*)
INITIALIZE r_r20.* TO NULL
LET r_r20.r20_compania		= vg_codcia
LET r_r20.r20_localidad  	= vg_codloc
LET r_r20.r20_cod_tran   	= r_r19.r19_cod_tran
LET r_r20.r20_num_tran   	= r_r19.r19_num_tran
LET r_r20.r20_cant_ent   	= 0 
LET r_r20.r20_cant_dev   	= 0
LET r_r20.r20_descuento  	= 0.0
LET r_r20.r20_val_descto 	= 0.0
LET r_r20.r20_val_impto  	= 0.0
LET r_r20.r20_ubicacion  	= 'SN'
DECLARE q_trans_d CURSOR FOR
	SELECT * FROM rept047
		WHERE r47_compania    = rm_r48.r48_compania
		  AND r47_localidad   = rm_r48.r48_localidad
		  AND r47_composicion = rm_r48.r48_composicion
		  AND r47_item_comp   = rm_r48.r48_item_comp
		  AND r47_bodega_part = vm_bod_comp
		ORDER BY r47_item_part ASC
LET resul = 1
LET i     = 1
FOREACH q_trans_d INTO r_r47.*
	IF vm_uni_aux IS NULL THEN
		LET r_r47.r47_cantidad = r_r47.r47_cantidad
						* rm_r48.r48_carg_stock
	ELSE
		IF tipo_llamada = 1 THEN
			LET r_r47.r47_cantidad = r_r47.r47_cantidad
							* vm_uni_aux
		END IF
		IF tipo_llamada = 2 THEN
			LET r_r47.r47_cantidad = r_r47.r47_cantidad
							* rm_r48.r48_carg_stock
		END IF
	END IF
	CALL fl_lee_item(vg_codcia, r_r47.r47_item_part) RETURNING r_r10.*
	LET r_r19.r19_tot_costo  = r_r19.r19_tot_costo + 
				  (r_r47.r47_cantidad * r_r10.r10_costo_mb)
	LET r_r20.r20_cant_ped   = r_r47.r47_cantidad
	LET r_r20.r20_cant_ven   = r_r47.r47_cantidad
	LET r_r20.r20_bodega     = r_r19.r19_bodega_ori
	LET r_r20.r20_item       = r_r47.r47_item_part 
	LET r_r20.r20_costo      = r_r10.r10_costo_mb 
	LET r_r20.r20_orden      = i
	LET r_r20.r20_fob        = r_r10.r10_fob 
	LET r_r20.r20_linea      = r_r10.r10_linea 
	LET r_r20.r20_rotacion   = r_r10.r10_rotacion 
	LET r_r20.r20_precio     = r_r10.r10_precio_mb
	LET r_r20.r20_costant_mb = r_r10.r10_costo_mb
	LET r_r20.r20_costnue_mb = r_r10.r10_costo_mb
	LET r_r20.r20_costant_ma = r_r10.r10_costo_ma
	LET r_r20.r20_costnue_ma = r_r10.r10_costo_ma
	CALL fl_lee_stock_rep(vg_codcia, r_r19.r19_bodega_ori,
				r_r47.r47_item_part)
		RETURNING r_r11.*
	IF r_r11.r11_compania IS NOT NULL THEN
		CALL fl_lee_bodega_rep(r_r11.r11_compania, r_r11.r11_bodega)
			RETURNING r_r02.*
		IF r_r02.r02_tipo <> 'S' THEN
			LET stock_act = r_r11.r11_stock_act - r_r47.r47_cantidad
			IF stock_act < 0 THEN
				LET mensaje = 'ERROR: El item ',
						r_r11.r11_item CLIPPED,
						' tiene stock insuficiente, ',
						'para generar esta ',
						'transferencia. Llame al',
						'ADMINISTRADOR.'
				CALL fl_mostrar_mensaje(mensaje, 'stop')
				LET resul = 0
				EXIT FOREACH
			END IF
		END IF
	END IF
	IF r_r11.r11_stock_act IS NULL THEN
		LET r_r11.r11_stock_act = 0
	END IF
	LET r_r20.r20_stock_ant  = r_r11.r11_stock_act 
	CALL fl_lee_stock_rep(vg_codcia, r_r19.r19_bodega_dest,
				r_r47.r47_item_part)
		RETURNING r_r11.*
	IF r_r11.r11_stock_act IS NULL THEN
		LET r_r11.r11_stock_act = 0
	END IF
	LET r_r20.r20_stock_bd   = r_r11.r11_stock_act 
	LET r_r20.r20_fecing	 = CURRENT
	INSERT INTO rept020 VALUES(r_r20.*)
	UPDATE rept011
		SET r11_stock_act = r11_stock_act - r_r47.r47_cantidad,
		    r11_egr_dia   = r11_egr_dia   + r_r47.r47_cantidad
		WHERE r11_compania = vg_codcia
		  AND r11_bodega   = r_r19.r19_bodega_ori
		  AND r11_item     = r_r47.r47_item_part 
	CALL fl_lee_stock_rep(vg_codcia, r_r19.r19_bodega_dest,
				r_r47.r47_item_part)
		RETURNING r_r11.*
	IF r_r11.r11_stock_act IS NULL THEN
		INSERT INTO rept011
			(r11_compania, r11_bodega, r11_item, r11_ubicacion,
			 r11_stock_ant, r11_stock_act, r11_ing_dia, r11_egr_dia)
			VALUES(vg_codcia, r_r19.r19_bodega_dest,
				r_r47.r47_item_part, 'SN', 0,
				r_r47.r47_cantidad, r_r47.r47_cantidad, 0)
	ELSE
		UPDATE rept011
			SET r11_stock_act = r11_stock_act + r_r47.r47_cantidad,
	      		    r11_ing_dia   = r11_ing_dia   + r_r47.r47_cantidad
			WHERE r11_compania  = vg_codcia
			  AND r11_bodega    = r_r19.r19_bodega_dest
			  AND r11_item      = r_r47.r47_item_part 
	END IF
END FOREACH
IF resul THEN
	UPDATE rept019
		SET r19_tot_costo = r_r19.r19_tot_costo,
		    r19_tot_bruto = r_r19.r19_tot_bruto,
		    r19_tot_neto  = r_r19.r19_tot_bruto
		WHERE r19_compania  = vg_codcia
		  AND r19_localidad = vg_codloc
		  AND r19_cod_tran  = r_r19.r19_cod_tran
		  AND r19_num_tran  = r_r19.r19_num_tran
	INSERT INTO rept053
		VALUES (rm_r48.r48_compania, rm_r48.r48_localidad,
			rm_r48.r48_composicion, rm_r48.r48_item_comp,
			rm_r48.r48_sec_carga, r_r19.r19_cod_tran,
			r_r19.r19_num_tran, vg_usuario, CURRENT)
ELSE
	DELETE FROM rept019
		WHERE r19_compania  = vg_codcia
		  AND r19_localidad = vg_codloc
		  AND r19_cod_tran  = r_r19.r19_cod_tran
		  AND r19_num_tran  = r_r19.r19_num_tran
	UPDATE gent015
		SET g15_numero = r_r19.r19_num_tran - 1
		WHERE g15_compania  = vg_codcia
		  AND g15_localidad = vg_codloc
		  AND g15_modulo    = vg_modulo
		  AND g15_bodega    = "AA"
		  AND g15_tipo      = r_r19.r19_cod_tran
END IF
CALL imprimir_transferencia(r_r19.r19_cod_tran, r_r19.r19_num_tran)
LET mensaje = 'Se genero transferencia # ', r_r19.r19_num_tran USING "<<<<<<<&",
		'. De la bodega ', r_r19.r19_bodega_ori, ' a la bodega ',
		r_r19.r19_bodega_dest, '.'
CALL fl_mostrar_mensaje(mensaje, 'info')
RETURN resul

END FUNCTION



FUNCTION procesar_diario_tr()
DEFINE r_reg		RECORD
				codcia		LIKE rept019.r19_compania,
				codloc		LIKE rept019.r19_localidad,
				cod_tran	LIKE rept019.r19_cod_tran,
				num_tran	LIKE rept019.r19_num_tran,
				porc_impto	LIKE rept019.r19_porc_impto,
				grupo_linea	LIKE gent020.g20_grupo_linea,
				tot_costo	LIKE rept019.r19_tot_costo
			END RECORD
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE r_b13		RECORD LIKE ctbt013.*
DEFINE r_b40		RECORD LIKE ctbt040.*
DEFINE r_r03		RECORD LIKE rept003.*
DEFINE query		CHAR(1500)
DEFINE cuantos		INTEGER
DEFINE resul		SMALLINT

LET resul = 0
LET query = 'SELECT r19_compania, r19_localidad, r19_cod_tran, r19_num_tran, ',
			'r19_porc_impto, r20_linea, ',
			'NVL(SUM(r20_cant_ven * r20_costo), 0) ',
		'FROM rept053, rept019, rept020 ',
		'WHERE r53_compania    = ', vg_codcia,
		'  AND r53_localidad   = ', vg_codloc,
		'  AND r53_composicion = ', rm_r48.r48_composicion,
		'  AND r53_item_comp   = "', rm_r48.r48_item_comp CLIPPED, '"',
		'  AND r53_cod_tran    = "A+" ',
		'  AND r19_compania    = r53_compania ',
		'  AND r19_localidad   = r53_localidad ',
		'  AND r19_cod_tran    = r53_cod_tran ',
		'  AND r19_num_tran    = r53_num_tran ',
		'  AND r20_compania    = r19_compania ',
		'  AND r20_localidad   = r19_localidad ',
		'  AND r20_cod_tran    = r19_cod_tran ',
		'  AND r20_num_tran    = r19_num_tran ',
		' GROUP BY 1, 2, 3, 4, 5, 6'
PREPARE cons_diario FROM query
DECLARE q_diario CURSOR FOR cons_diario
FOREACH q_diario INTO r_reg.*
	INITIALIZE r_b12.*, r_b13.* TO NULL
	LET r_b12.b12_compania    = vg_codcia
	LET r_b12.b12_tipo_comp   = 'DR'
	LET r_b12.b12_num_comp    = fl_numera_comprobante_contable(vg_codcia,
						r_b12.b12_tipo_comp,
						YEAR(TODAY), MONTH(TODAY))
	LET r_b12.b12_subtipo     = 17
	LET r_b12.b12_estado      = 'A'
	LET r_b12.b12_glosa       = '(COMPOSICION # ',
				rm_r48.r48_composicion USING "<<<<<<<<<&", ' ',
				'BODEGA: ', rm_r48.r48_bodega_comp, ' ITEM: ',
				rm_r48.r48_item_comp CLIPPED, ')'
	LET r_b12.b12_origen      = 'A'
	LET r_b12.b12_moneda      = rg_gen.g00_moneda_base
	LET r_b12.b12_paridad     = 1
	LET r_b12.b12_fec_proceso = TODAY
	LET r_b12.b12_modulo      = vg_modulo
	LET r_b12.b12_usuario     = vg_usuario
	LET r_b12.b12_fecing      = CURRENT
	WHENEVER ERROR CONTINUE
	INSERT INTO ctbt012 VALUES(r_b12.*)
	IF STATUS <> 0 THEN
		CALL fl_mostrar_mensaje('No se ha podido insertar la cabecera del diario contable de esta composición. Por favor llame al ADMINISTRADOR.', 'stop')
		WHENEVER ERROR STOP
		LET resul = 0
		EXIT FOREACH
	END IF
	WHENEVER ERROR STOP
	CALL fl_lee_linea_rep(r_b12.b12_compania, r_reg.grupo_linea)
		RETURNING r_r03.*
	CALL fl_lee_auxiliares_ventas(vg_codcia, vg_codloc, vg_modulo,
					vm_bod_comp, r_r03.r03_grupo_linea,
					r_reg.porc_impto)
		RETURNING r_b40.*
	LET r_b13.b13_compania    = r_b12.b12_compania
	LET r_b13.b13_tipo_comp   = r_b12.b12_tipo_comp
	LET r_b13.b13_num_comp    = r_b12.b12_num_comp
	LET r_b13.b13_secuencia   = 1
	LET r_b13.b13_glosa       = ' (COMPOSICION # ',
					rm_r48.r48_composicion
					USING "<<<<<<<<<&", ' ',
					'BODEGA: ',
					rm_r48.r48_bodega_comp,
					' ITEM: ',
						rm_r48.r48_item_comp CLIPPED,')'
	LET r_b13.b13_cuenta      = r_b40.b40_ajustes
	LET r_b13.b13_valor_base  = r_reg.tot_costo
	LET r_b13.b13_valor_aux   = 0.00
	LET r_b13.b13_fec_proceso = r_b12.b12_fec_proceso
	WHENEVER ERROR CONTINUE
	INSERT INTO ctbt013 VALUES(r_b13.*)
	IF STATUS <> 0 THEN
		CALL fl_mostrar_mensaje('No se ha podido insertar el detalle del diario contable de esta composición. Por favor llame al ADMINISTRADOR.', 'stop')
		WHENEVER ERROR STOP
		LET resul = 0
		EXIT FOREACH
	END IF
	WHENEVER ERROR STOP
	LET r_b13.b13_secuencia   = 2
	LET r_b13.b13_cuenta      = r_b40.b40_inventario
	LET r_b13.b13_valor_base  = r_reg.tot_costo * (-1)
	WHENEVER ERROR CONTINUE
	INSERT INTO ctbt013 VALUES(r_b13.*)
	IF STATUS <> 0 THEN
		CALL fl_mostrar_mensaje('No se ha podido insertar el detalle del diario contable de esta composición. Por favor llame al ADMINISTRADOR.', 'stop')
		WHENEVER ERROR STOP
		LET resul = 0
		EXIT FOREACH
	END IF
	WHENEVER ERROR STOP
	INSERT INTO rept040
		VALUES (rm_r48.r48_compania, rm_r48.r48_localidad,
			r_reg.cod_tran, r_reg.num_tran, r_b12.b12_tipo_comp,
			r_b12.b12_num_comp)
	LET resul = 1
END FOREACH
RETURN resul

END FUNCTION



FUNCTION transaccion_aj(cod_tran)
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE r_dato		RECORD
				division	LIKE rept020.r20_linea,
				bodega		LIKE rept019.r19_bodega_ori
			END RECORD
DEFINE query		CHAR(800)
DEFINE resul		SMALLINT

CASE cod_tran
	WHEN 'A-'
		LET query = 'SELECT UNIQUE r47_division_p, r47_bodega_part',
				' FROM rept047 ',
				' WHERE r47_compania    = ',
						rm_r48.r48_compania,
				'   AND r47_localidad   = ',
						rm_r48.r48_localidad,
				'   AND r47_composicion = ',
						rm_r48.r48_composicion,
				'   AND r47_item_comp   = "',
						rm_r48.r48_item_comp, '"',
				' ORDER BY 2, 1 '
	WHEN 'A+'
		LET query = 'SELECT UNIQUE r46_division_c, "',
					vm_bod_aj, '"',
				' FROM rept046 ',
				' WHERE r46_compania    = ',
						rm_r48.r48_compania,
				'   AND r46_localidad   = ',
						rm_r48.r48_localidad,
				'   AND r46_composicion = ',
						rm_r48.r48_composicion,
				'   AND r46_item_comp   = "',
						rm_r48.r48_item_comp, '"',
				' ORDER BY 2, 1 '
	WHEN 'AC'
		LET query = 'SELECT UNIQUE r46_division_c',
				' FROM rept046 ',
				' WHERE r46_compania    = ',
						rm_r48.r48_compania,
				'   AND r46_localidad   = ',
						rm_r48.r48_localidad,
				'   AND r46_composicion = ',
						rm_r48.r48_composicion,
				'   AND r46_item_comp   = "',
						rm_r48.r48_item_comp, '"',
				' ORDER BY 1 '
END CASE
PREPARE cons_aj FROM query
DECLARE qu_ajuste CURSOR FOR cons_aj
LET resul = 1
FOREACH qu_ajuste INTO r_dato.*
	IF NOT generar_ajuste(r_dato.*, cod_tran) THEN
		LET resul = 0
		EXIT FOREACH
	END IF
END FOREACH
RETURN resul

END FUNCTION



FUNCTION generar_ajuste(r_dato, cod_tran)
DEFINE r_dato		RECORD
				division	LIKE rept020.r20_linea,
				bodega		LIKE rept019.r19_bodega_ori
			END RECORD
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r10_o, r_r10_t	RECORD LIKE rept010.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE i		LIKE rept020.r20_orden
DEFINE item, item_t	LIKE rept011.r11_item
DEFINE usuario		LIKE gent005.g05_usuario
DEFINE cantidad		DECIMAL(13,4)
DEFINE feceli		LIKE rept010.r10_feceli
DEFINE costo_ing	DECIMAL(12,2)
DEFINE costo_nue	DECIMAL(12,2)
DEFINE mensaje 		VARCHAR(200)
DEFINE query		CHAR(1000)
DEFINE resul		SMALLINT
DEFINE varusu		VARCHAR(100)
DEFINE resp		CHAR(6)

INITIALIZE r_r19.*, r_r20.* TO NULL
CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, 'RE', 'AA', cod_tran)
	RETURNING num_tran
CASE num_tran
	WHEN 0
		CALL fl_mostrar_mensaje('No existe control de secuencia para el ' || cod_tran || ', no se puede asignar un numero de transaccion.', 'stop')
		ROLLBACK WORK
		EXIT PROGRAM
	WHEN -1
		SET LOCK MODE TO WAIT
		WHILE num_tran = -1
			IF num_tran <> -1 THEN
				EXIT WHILE
			END IF
			CALL fl_actualiza_control_secuencias(vg_codcia,
						vg_codloc, 'RE', 'AA', cod_tran)
				RETURNING num_tran
		END WHILE
		SET LOCK MODE TO NOT WAIT
END CASE
LET r_r19.r19_compania    = vg_codcia
LET r_r19.r19_localidad   = vg_codloc
LET r_r19.r19_cod_tran    = cod_tran
LET r_r19.r19_num_tran    = num_tran
LET r_r19.r19_cont_cred   = 'C'
LET r_r19.r19_referencia  = 'COMP.# ', rm_r48.r48_composicion USING "<<<<<&",
				' BD ', rm_r48.r48_bodega_comp CLIPPED, ' ',
				rm_r48.r48_item_comp CLIPPED
IF cod_tran <> 'A-' THEN
	CALL retorna_referencia(cod_tran, r_r19.r19_referencia)
		RETURNING r_r19.r19_referencia
END IF
LET r_r19.r19_referencia = r_r19.r19_referencia CLIPPED, '. ',
				rm_r48.r48_referencia CLIPPED
LET r_r19.r19_nomcli      = ' '
LET r_r19.r19_dircli      = ' '
LET r_r19.r19_telcli      = ' '
LET r_r19.r19_cedruc      = ' '
LET r_r19.r19_vendedor    = rm_r01.r01_codigo
LET r_r19.r19_descuento   = 0
LET r_r19.r19_porc_impto  = 0
IF cod_tran = 'AC' THEN
	LET r_r19.r19_bodega_ori  = rm_r00.r00_bodega_fact
	LET r_r19.r19_bodega_dest = rm_r00.r00_bodega_fact
ELSE
	LET r_r19.r19_bodega_ori  = r_dato.bodega
	LET r_r19.r19_bodega_dest = r_dato.bodega
	IF cod_tran = 'A-' THEN
		LET r_r19.r19_bodega_ori  = rm_r48.r48_bodega_comp
		LET r_r19.r19_bodega_dest = rm_r48.r48_bodega_comp
	END IF
END IF
LET r_r19.r19_moneda 	  = rg_gen.g00_moneda_base
LET r_r19.r19_paridad     = rg_gen.g00_decimal_mb
LET r_r19.r19_precision   = rg_gen.g00_decimal_mb
LET r_r19.r19_tot_costo   = 0
LET r_r19.r19_tot_bruto   = 0
LET r_r19.r19_tot_dscto   = 0
LET r_r19.r19_tot_neto 	  = 0
LET r_r19.r19_flete 	  = 0
LET r_r19.r19_usuario 	  = vg_usuario
LET r_r19.r19_fecing 	  = CURRENT
INSERT INTO rept019 VALUES (r_r19.*)
CASE cod_tran
	WHEN 'A-'
		LET query = 'SELECT r47_item_part, r47_cantidad * ',
					rm_r48.r48_carg_stock,', r46_item_comp',
				' FROM rept047, rept046 ',
				' WHERE r47_compania    = ',
						rm_r48.r48_compania,
				'   AND r47_localidad   = ',
						rm_r48.r48_localidad,
				'   AND r47_composicion = ',
						rm_r48.r48_composicion,
				'   AND r47_item_comp   = "',
						rm_r48.r48_item_comp, '"',
				'   AND r47_bodega_part = "',
						r_dato.bodega,'"',
				'   AND r47_division_p  = "',
						r_dato.division, '"',
				'   AND r46_compania    = r47_compania ',
				'   AND r46_localidad   = r47_localidad ',
				'   AND r46_composicion = r47_composicion ',
				'   AND r46_item_comp   = r47_item_comp ',
				' ORDER BY 1, 2 '
	WHEN 'A+'
		LET query = 'SELECT r46_item_comp, ', rm_r48.r48_carg_stock,
				' FROM rept046 ',
				' WHERE r46_compania    = ',
						rm_r48.r48_compania,
				'   AND r46_localidad   = ',
						rm_r48.r48_localidad,
				'   AND r46_composicion = ',
						rm_r48.r48_composicion,
				'   AND r46_item_comp   = "',
						rm_r48.r48_item_comp, '"',
				'   AND r46_division_c  = "',
						r_dato.division, '"',
				' ORDER BY 1, 2 '
	WHEN 'AC'
		LET query = 'SELECT r46_item_comp, ', rm_r48.r48_costo_comp,
				' FROM rept046 ',
				' WHERE r46_compania    = ',
						rm_r48.r48_compania,
				'   AND r46_localidad   = ',
						rm_r48.r48_localidad,
				'   AND r46_composicion = ',
						rm_r48.r48_composicion,
				'   AND r46_item_comp   = "',
						rm_r48.r48_item_comp, '"',
				'   AND r46_division_c  = "',
						r_dato.division, '"',
				' ORDER BY 1, 2 '
END CASE
PREPARE cons_det2 FROM query
DECLARE q_det2 CURSOR FOR cons_det2
LET resul = 1
LET i     = 1
FOREACH q_det2 INTO item, cantidad, item_t
	IF cod_tran = 'A-' THEN
		LET r_dato.bodega = rm_r48.r48_bodega_comp
		--LET r_dato.bodega = vm_bod_comp
		--LET cantidad      = cantidad * rm_r48.r48_carg_stock
	END IF
	IF cod_tran = 'AC' THEN
		LET costo_ing           = cantidad
		LET cantidad            = rm_r48.r48_carg_stock
		LET r_r11.r11_stock_ant = cantidad
	ELSE
		CALL fl_lee_stock_rep(vg_codcia, r_dato.bodega, item)
			RETURNING r_r11.*
		IF r_r11.r11_compania IS NULL THEN
			LET r_r11.r11_stock_act = 0
		END IF
	END IF
	IF cod_tran <> 'A+' THEN
		CALL fl_lee_item(vg_codcia, rm_r48.r48_item_comp)
			RETURNING r_r10_o.*
		IF cod_tran = 'A-' THEN
			CALL fl_lee_item(vg_codcia, item_t) RETURNING r_r10_t.*
		ELSE
			CALL fl_lee_item(vg_codcia, item) RETURNING r_r10_t.*
		END IF
		IF r_r10_o.r10_uni_med <> r_r10_t.r10_uni_med THEN
			IF r_r10_o.r10_cantpaq < r_r10_t.r10_cantpaq THEN
				IF cod_tran = 'AC' THEN
					LET costo_ing = costo_ing *
							r_r10_t.r10_cantpaq
				END IF
				LET cantidad = cantidad * r_r10_t.r10_cantpaq
			ELSE
				IF cod_tran = 'AC' THEN
					LET costo_ing = costo_ing /
							r_r10_t.r10_cantpaq
				END IF
				LET cantidad = cantidad / r_r10_t.r10_cantpaq
			END IF
		END IF
	END IF
    	LET r_r20.r20_compania 	 = r_r19.r19_compania
    	LET r_r20.r20_localidad	 = r_r19.r19_localidad
    	LET r_r20.r20_cod_tran 	 = r_r19.r19_cod_tran
    	LET r_r20.r20_num_tran 	 = r_r19.r19_num_tran
	IF cod_tran = 'AC' THEN
		--LET r_r20.r20_bodega = rm_r48.r48_bodega_comp
		LET r_r20.r20_bodega = vm_bod_aj
	ELSE
	    	LET r_r20.r20_bodega = r_dato.bodega
	END IF
    	LET r_r20.r20_item 	 = item
    	LET r_r20.r20_orden 	 = i
    	LET r_r20.r20_cant_ped 	 = cantidad
    	LET r_r20.r20_cant_ven   = cantidad
	LET r_r20.r20_cant_dev 	 = 0
	LET r_r20.r20_cant_ent   = 0
	LET r_r20.r20_descuento  = 0
	LET r_r20.r20_val_descto = 0
	IF cod_tran = 'AC' THEN
		CALL fl_lee_item(vg_codcia, rm_r48.r48_item_comp)
			RETURNING r_r10_o.*
		CALL fl_lee_item(vg_codcia, item) RETURNING r_r10_t.*
		IF r_r10_o.r10_uni_med <> r_r10_t.r10_uni_med THEN
			CALL fl_obtiene_costo_item(vg_codcia, r_r19.r19_moneda,
						item, cantidad, costo_ing)
				RETURNING costo_nue
		ELSE
			CALL fl_obtiene_costo_item_tras(vg_codcia,
						r_r19.r19_moneda, item,
						cantidad, costo_ing)
				RETURNING costo_nue
		END IF
	END IF
	CALL fl_lee_item(r_r19.r19_compania, item) RETURNING r_r10.*
    	LET r_r20.r20_costo 	 = r_r10.r10_costo_mb / r_r20.r20_cant_ven
    	LET r_r20.r20_costant_mb = r_r10.r10_costo_mb / r_r20.r20_cant_ven
    	LET r_r20.r20_costant_ma = r_r10.r10_costo_ma / r_r20.r20_cant_ven
    	LET r_r20.r20_costnue_mb = r_r10.r10_costo_mb / r_r20.r20_cant_ven
    	LET r_r20.r20_costnue_ma = r_r10.r10_costo_ma / r_r20.r20_cant_ven
	LET feceli               = NULL
	IF r_r10.r10_estado = 'A' THEN
		LET feceli = CURRENT
	END IF
	IF cod_tran = 'AC' THEN
		LET r_r10.r10_costo_mb    = costo_nue / r_r20.r20_cant_ven
		LET r_r10.r10_costult_mb  = costo_ing / r_r20.r20_cant_ven
		LET r_r20.r20_costnue_mb  = costo_ing / r_r20.r20_cant_ven
    		LET r_r20.r20_costo 	  = costo_nue / r_r20.r20_cant_ven
		WHENEVER ERROR CONTINUE
		WHILE TRUE
			UPDATE rept010
				SET r10_estado      = 'B',
				    r10_costo_mb    = r_r10.r10_costo_mb,
				    r10_costult_mb  = r_r10.r10_costult_mb,
				    r10_usu_cosrepo = vg_usuario,
				    r10_fec_cosrepo = CURRENT,
				    r10_feceli      = feceli
				WHERE r10_compania = vg_codcia
				  AND r10_codigo   = item
			IF STATUS = 0 THEN
				EXIT WHILE
			END IF
			DECLARE q_blo CURSOR FOR
				SELECT UNIQUE s.username
					FROM sysmaster:syslocks l,
						sysmaster:syssessions s
					WHERE type    = "U"
					  AND sid     <> DBINFO('sessionid')
					  AND owner   = sid
					  AND tabname = 'rept010'
					  AND rowidlk = (SELECT ROWID
							FROM rept010
							WHERE r10_compania =
								vg_codcia
							  AND r10_codigo   =
								item)
			LET varusu = NULL
			FOREACH q_blo INTO usuario
				IF varusu IS NULL THEN
					LET varusu = UPSHIFT(usuario) CLIPPED
				ELSE
					LET varusu = varusu CLIPPED, ' ',
							UPSHIFT(usuario) CLIPPED
				END IF
			END FOREACH
			LET mensaje = 'El Item ', r_r20.r20_item CLIPPED,
					' esta siendo bloqueado por el ',
					'usuario ', varusu CLIPPED,
					'. Desea intentar nuevamente con el ',
					'ajuste (A+) de la composición ?'
			CALL fl_hacer_pregunta(mensaje, 'Yes') RETURNING resp
			IF resp = 'Yes' THEN
				CONTINUE WHILE
			END IF
			ROLLBACK WORK
			WHENEVER ERROR STOP
			LET mensaje = 'No se ha podido actualizar el costo del',
					' Item ', r_r20.r20_item CLIPPED,
					'. Esta bloqueado por el usuario ',
					UPSHIFT(usuario) CLIPPED,
					'. LLAME AL ADMINISTRADOR.'
			CALL fl_mostrar_mensaje(mensaje, 'stop')
			EXIT PROGRAM
		END WHILE
		WHENEVER ERROR STOP
	END IF
	IF r_r19.r19_moneda <> rg_gen.g00_moneda_base THEN
		LET r_r10.r10_precio_mb = r_r10.r10_precio_ma
		LET r_r10.r10_costo_mb  = r_r10.r10_costo_ma
	END IF	
    	LET r_r20.r20_precio 	 = r_r10.r10_precio_mb
    	LET r_r20.r20_val_impto  = 0
    	LET r_r20.r20_fob 	 = r_r10.r10_fob
    	LET r_r20.r20_linea 	 = r_r10.r10_linea
    	LET r_r20.r20_rotacion 	 = r_r10.r10_rotacion
    	LET r_r20.r20_ubicacion  = '.'
	IF cod_tran <> 'AC' THEN
    		LET r_r20.r20_stock_ant = r_r11.r11_stock_act
	ELSE
    		LET r_r20.r20_stock_ant = cantidad
	END IF
	IF r_r20.r20_stock_ant IS NULL THEN
		LET r_r20.r20_stock_ant = 0
	END IF
	IF cod_tran <> 'AC' THEN
		CALL fl_lee_stock_rep(vg_codcia, r_dato.bodega, item)
			RETURNING r_r11.*
		IF r_r11.r11_compania IS NULL THEN
    			LET r_r11.r11_stock_act = 0
			IF cod_tran = 'A+' THEN
				INSERT INTO rept011
					(r11_compania, r11_bodega, r11_item,
					 r11_ubicacion, r11_stock_ant,
					 r11_stock_act, r11_ing_dia,r11_egr_dia)
					VALUES (vg_codcia,r_r19.r19_bodega_dest,
						item, 'SN', 0, cantidad,
						cantidad, 0)
			ELSE
				INSERT INTO rept011
					(r11_compania, r11_bodega, r11_item,
					 r11_ubicacion, r11_stock_ant,
					 r11_stock_act, r11_ing_dia,r11_egr_dia)
					VALUES (vg_codcia,r_r19.r19_bodega_dest,
						item, 'SN', 0, cantidad, 0,
						cantidad)
			END IF
		ELSE
			IF cod_tran = 'A+' THEN
				SET LOCK MODE TO WAIT
				WHENEVER ERROR CONTINUE
				UPDATE rept011
					SET r11_stock_act = r11_stock_act +
								cantidad,
					    r11_ing_dia   = r11_ing_dia   +
								cantidad
					WHERE r11_compania = vg_codcia
					  AND r11_bodega   = r_dato.bodega
					  AND r11_item     = item
				IF STATUS <> 0 THEN
					WHENEVER ERROR STOP
					SET LOCK MODE TO NOT WAIT
					LET resul = 0
					CALL fl_mostrar_mensaje('Ha ocurrido un error al actualizar (incrementar) el stock en el ' || cod_tran || '. Por favor llame al ADMINISTRADOR.', 'exclamation')
					EXIT FOREACH
				END IF
				WHENEVER ERROR STOP
				SET LOCK MODE TO NOT WAIT
			ELSE
				CALL fl_lee_stock_rep(vg_codcia, r_dato.bodega,
							item)
					RETURNING r_r11.*
				IF r_r11.r11_compania IS NULL THEN
					LET r_r11.r11_stock_act = 0
				END IF
				LET mensaje = 'ITEM: ', item
				IF r_r11.r11_stock_act <= 0 THEN
					LET resul   = 0
					LET mensaje = mensaje CLIPPED,
					' no tiene stock y se nesecita: ',
					cantidad USING '####&.##',
					'. No puede ajustar para esta ',
					'Composición.'
					CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
					EXIT FOREACH
				END IF
				IF r_r11.r11_stock_act < cantidad THEN
					LET resul   = 0
					LET mensaje = mensaje CLIPPED,
					' solo tiene stock: ',
					r_r11.r11_stock_act USING '####&.##', 
					' y se nesecita: ',
					cantidad USING '####&.##',
					'. No puede ajustar para este ',
					' Composición.'
					CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
					EXIT FOREACH
				END IF
				SET LOCK MODE TO WAIT
				WHENEVER ERROR CONTINUE
				UPDATE rept011
					SET r11_stock_act = r11_stock_act -
								cantidad,
					    r11_egr_dia   = r11_egr_dia   +
								cantidad
					WHERE r11_compania = vg_codcia
					  AND r11_bodega   = r_dato.bodega
					  AND r11_item     = item
				IF STATUS <> 0 THEN
					WHENEVER ERROR STOP
					SET LOCK MODE TO NOT WAIT
					LET resul = 0
					CALL fl_mostrar_mensaje('Ha ocurrido un error al actualizar (disminuir) el stock en el ' || cod_tran || '. Por favor llame al ADMINISTRADOR.', 'exclamation')
					EXIT FOREACH
				END IF
				WHENEVER ERROR STOP
				SET LOCK MODE TO NOT WAIT
			END IF
		END IF
	END IF
	LET r_r20.r20_stock_bd   = 0
	LET r_r20.r20_fecing     = CURRENT
	INSERT INTO rept020 VALUES (r_r20.*)
	IF r_r20.r20_cod_tran <> 'AC' THEN
		LET r_r19.r19_tot_costo = r_r19.r19_tot_costo +
					(cantidad * r_r20.r20_costo)
	ELSE
		LET r_r19.r19_tot_costo = r_r19.r19_tot_costo +
					(cantidad * r_r20.r20_costnue_mb)
	END IF
END FOREACH
IF NOT resul THEN
	RETURN resul
END IF
IF i = 0 OR i IS NULL THEN
	DELETE FROM rept019
		WHERE r19_compania  = r_r19.r19_compania
		  AND r19_localidad = r_r19.r19_localidad
		  AND r19_cod_tran  = r_r19.r19_cod_tran
		  AND r19_num_tran  = r_r19.r19_num_tran
ELSE
	UPDATE rept019
		SET r19_tot_costo = r_r19.r19_tot_costo,
		    r19_tot_bruto = r_r19.r19_tot_costo,
		    r19_tot_neto  = r_r19.r19_tot_costo
		WHERE r19_compania  = r_r19.r19_compania
		  AND r19_localidad = r_r19.r19_localidad
		  AND r19_cod_tran  = r_r19.r19_cod_tran
		  AND r19_num_tran  = r_r19.r19_num_tran 
	INSERT INTO rept053
		VALUES (rm_r48.r48_compania, rm_r48.r48_localidad,
			rm_r48.r48_composicion, rm_r48.r48_item_comp,
			rm_r48.r48_sec_carga, r_r19.r19_cod_tran,
			r_r19.r19_num_tran, rm_r48.r48_usuario, CURRENT)
END IF
RETURN resul

END FUNCTION



FUNCTION retorna_referencia(cod_tran, referencia)
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE referencia	LIKE rept019.r19_referencia
DEFINE r_r53		RECORD LIKE rept053.*
DEFINE ulti		SMALLINT

CASE cod_tran
	WHEN 'A+' LET cod_tran = 'A-'
	WHEN 'AC' LET cod_tran = 'A+'
END CASE
LET referencia = referencia CLIPPED, '. ', cod_tran, ':'
DECLARE q_r53 CURSOR FOR
	SELECT * FROM rept053
		WHERE r53_compania    = vg_codcia
		  AND r53_localidad   = vg_codloc
		  AND r53_composicion = rm_r48.r48_composicion
		  AND r53_sec_carga   = rm_r48.r48_sec_carga
		  AND r53_item_comp   = rm_r48.r48_item_comp
		  AND r53_cod_tran    = cod_tran
		ORDER BY r53_num_tran
FOREACH q_r53 INTO r_r53.*
	LET referencia = referencia CLIPPED, ' ',
			r_r53.r53_num_tran USING "<<<<<&", ', '
END FOREACH
LET referencia = referencia CLIPPED
LET ulti       = LENGTH(referencia)
IF referencia[ulti, ulti] = ',' THEN
	LET referencia = referencia[1, ulti - 1] CLIPPED
END IF
RETURN referencia CLIPPED

END FUNCTION



FUNCTION control_ordenes_compra(flag, max_row)
DEFINE flag		CHAR(1)
DEFINE max_row		SMALLINT
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r46		RECORD LIKE rept046.*
DEFINE i		SMALLINT

LET vm_max_oc = 50
FOR i = 1 TO vm_max_oc
	INITIALIZE rm_det_oc[i].* TO NULL
END FOR
IF NOT cargar_ordenes_compras() THEN
	IF rm_r48.r48_estado = 'C' THEN
		RETURN
	END IF
END IF
OPEN WINDOW w_repf249_4 AT 05, 04 WITH 14 ROWS, 73 COLUMNS
	ATTRIBUTE(BORDER, FORM LINE FIRST, COMMENT LINE LAST)
IF vg_gui = 1 THEN
	OPEN FORM f_repf249_4 FROM '../forms/repf249_2'
ELSE
	OPEN FORM f_repf249_4 FROM '../forms/repf249_2c'
END IF
DISPLAY FORM f_repf249_4
--#DISPLAY "Num. OC"	TO tit_col1
--#DISPLAY "Referencia"	TO tit_col2
--#DISPLAY "Unidades"	TO tit_col3
--#DISPLAY "Costo OC"	TO tit_col4
--#DISPLAY "E"		TO tit_col5
CALL fl_lee_composicion_cab2(vg_codcia, vg_codloc, rm_r48.r48_composicion,
				rm_r48.r48_item_comp)
	RETURNING r_r46.*
DISPLAY BY NAME rm_r48.r48_sec_carga, rm_r48.r48_item_comp, r_r46.r46_desc_comp
CALL muestra_estado2()
IF rm_r48.r48_estado = 'P' THEN
	CALL ingresa_ordenes_compras()
ELSE
	CALL consulta_ordenes_compras()
END IF
IF int_flag THEN
	LET int_flag = 0
	CLOSE WINDOW w_repf249_4
	RETURN
END IF
IF rm_r48.r48_estado = 'P' THEN
	IF flag = 'M' THEN
		BEGIN WORK
	END IF
		IF NOT graba_ordenes_compras() THEN
			IF flag = 'M' THEN
				ROLLBACK WORK
			END IF
			RETURN
		END IF
	IF flag = 'M' THEN
		COMMIT WORK
		CALL fl_mostrar_mensaje('Ordenes de Compra Grabadas Ok.','info')
	END IF
END IF
LET int_flag = 0
CLOSE WINDOW w_repf249_4
CALL mostrar_total(max_row)
RETURN

END FUNCTION



FUNCTION cargar_ordenes_compras()
DEFINE query		CHAR(2000)
DEFINE expr_est		VARCHAR(100)

LET expr_est = NULL
IF rm_r48.r48_estado = 'P' THEN
	LET expr_est = '   AND c10_estado      = "C" '
END IF
LET query = 'SELECT r49_numero_oc, c10_referencia, r49_cant_unid, ',
			'r49_costo_oc, c10_estado ',
		' FROM rept049, ordt010 ',
		' WHERE r49_compania    = ', vg_codcia,
		'   AND r49_localidad   = ', vg_codloc,
		'   AND r49_composicion = ', rm_r48.r48_composicion,
		'   AND r49_item_comp   = "', rm_r48.r48_item_comp, '"',
		'   AND r49_sec_carga   = ', rm_r48.r48_sec_carga,
		'   AND c10_compania    = r49_compania ',
		'   AND c10_localidad   = r49_localidad ',
		'   AND c10_numero_oc   = r49_numero_oc ',
		expr_est CLIPPED,
		' ORDER BY r49_numero_oc ASC '
PREPARE cons_oc FROM query
DECLARE q_r49 CURSOR FOR cons_oc
LET vm_num_oc = 1
FOREACH q_r49 INTO rm_det_oc[vm_num_oc].*
	LET vm_num_oc = vm_num_oc + 1
	IF vm_num_oc > vm_max_oc THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_oc = vm_num_oc - 1
IF vm_num_oc = 0 THEN
	IF rm_r48.r48_estado = 'C' THEN
		CALL fl_mensaje_consulta_sin_registros()
	END IF
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION ingresa_ordenes_compras()
DEFINE resp		CHAR(6)
DEFINE mensaje		VARCHAR(150)
DEFINE i, j, k, l	SMALLINT
DEFINE max_row		SMALLINT
DEFINE encontro		SMALLINT
DEFINE r_c01		RECORD LIKE ordt001.*
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_r49		RECORD LIKE rept049.*
DEFINE cant_u		LIKE rept049.r49_cant_unid

IF vm_num_oc = 0 THEN
	IF vm_est_ant = 'C' THEN
		SELECT COUNT(*) INTO vm_num_oc
			FROM rept049
			WHERE r49_compania    = rm_r48.r48_compania
			  AND r49_localidad   = rm_r48.r48_localidad
			  AND r49_composicion = rm_r48.r48_composicion
			  AND r49_item_comp   = rm_r48.r48_item_comp
			  AND r49_sec_carga   = rm_r48.r48_sec_carga
		IF vm_num_oc = 0 THEN
			LET vm_num_oc = 1
		END IF
	ELSE
		LET vm_num_oc = 1
	END IF
END IF
LET int_flag = 0
CALL set_count(vm_num_oc)
INPUT ARRAY rm_det_oc WITHOUT DEFAULTS FROM rm_det_oc.*
	ON KEY(INTERRUPT)
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
	ON KEY(F2)
		IF INFIELD(r49_numero_oc) THEN
			CALL fl_ayuda_ordenes_compra(vg_codcia, vg_codloc, 0, 0,
							'C', 'CI', 'T')
				RETURNING r_c10.c10_numero_oc
			IF r_c10.c10_numero_oc IS NOT NULL THEN
				CALL datos_oc(r_c10.c10_numero_oc, i, j)
				CALL mostrar_total_oc(max_row)
			END IF
		END IF
		LET int_flag = 0
	ON KEY(F5)
		LET i = arr_curr()
		IF rm_det_oc[i].r49_numero_oc IS NOT NULL THEN
			CALL ver_orden_compra(i)
			LET int_flag = 0
		END IF
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
		LET max_row = arr_count()
		IF i > max_row THEN
			LET max_row = max_row + 1
		END IF
		CALL muestra_contadores_det(i, max_row)
		CALL mostrar_total_oc(max_row)
		IF rm_det_oc[i].r49_numero_oc IS NOT NULL THEN
                	CALL dialog.keysetlabel("F5", "Orden Compra")
		ELSE
                	CALL dialog.keysetlabel("F5", "")
		END IF
	BEFORE FIELD r49_cant_unid
		LET cant_u = rm_det_oc[i].r49_cant_unid
	AFTER FIELD r49_numero_oc
		IF rm_det_oc[i].r49_numero_oc IS NOT NULL THEN
			CALL fl_lee_orden_compra(vg_codcia, vg_codloc,
					rm_det_oc[i].r49_numero_oc)
				RETURNING r_c10.*
			IF r_c10.c10_numero_oc IS NULL THEN
				CALL fl_mostrar_mensaje('Orden de compra no existe.', 'exclamation')
				NEXT FIELD r49_numero_oc
			END IF
			IF r_c10.c10_estado <> 'C' THEN
				CALL fl_mostrar_mensaje('Orden de compra no esta CERRADA.', 'exclamation')
				NEXT FIELD r49_numero_oc
			END IF
			CALL fl_lee_tipo_orden_compra(r_c10.c10_tipo_orden)
				RETURNING r_c01.*
			IF r_c01.c01_modulo <> 'CI' OR r_c01.c01_modulo IS NULL
			THEN
				CALL fl_mostrar_mensaje('Orden de compra debe ser para composición de ítems.', 'exclamation')
				NEXT FIELD r49_numero_oc
			END IF
			INITIALIZE r_r49.* TO NULL
			DECLARE q_r49_2 CURSOR FOR
				SELECT * FROM rept049
					WHERE r49_compania  = vg_codcia
					  AND r49_localidad = vg_codloc
					  AND r49_numero_oc =r_c10.c10_numero_oc
			FOREACH q_r49_2 INTO r_r49.*
				IF r_r49.r49_composicion =rm_r48.r48_composicion
				   AND r_r49.r49_item_comp =rm_r48.r48_item_comp
				   AND r_r49.r49_sec_carga =rm_r48.r48_sec_carga
				THEN
					CONTINUE FOREACH
				END IF
				IF r_r49.r49_numero_oc IS NOT NULL THEN
					CALL fl_mostrar_mensaje('Orden de compra ya ha sido asociada a otra carga de ítems.', 'exclamation')
					NEXT FIELD r49_numero_oc
				END IF
			END FOREACH
			CALL datos_oc(r_c10.c10_numero_oc, i, j)
			CALL mostrar_total_oc(max_row)
		ELSE
			INITIALIZE rm_det_oc[i].* TO NULL
			DISPLAY rm_det_oc[i].* TO rm_det_oc[j].*
		END IF
		CALL mostrar_total_oc(max_row)
	AFTER FIELD r49_cant_unid
		IF rm_det_oc[i].r49_cant_unid IS NULL THEN
			LET rm_det_oc[i].r49_cant_unid = cant_u
			DISPLAY rm_det_oc[i].r49_cant_unid TO
				rm_det_oc[j].r49_cant_unid
		END IF
		CALL mostrar_total_oc(max_row)
	AFTER INPUT
		LET vm_num_oc = arr_count()
		{--
		LET l = 0
		FOR k = 1 TO vm_num_oc
			IF rm_det_oc[k].r49_numero_oc IS NULL THEN
				LET l = l + 1
			END IF
		END FOR
		IF l = vm_num_oc THEN
			CALL fl_mostrar_mensaje('Al menos debe digitar una orden de compra.', 'exclamation')
			CONTINUE INPUT
		END IF
		--}
		IF vm_num_oc = 0 THEN
			EXIT INPUT
		END IF
		LET encontro = 0
		FOR k = 1 TO vm_num_oc - 1
			FOR l = k + 1 TO vm_num_oc
				IF (rm_det_oc[l].r49_numero_oc =
				    rm_det_oc[k].r49_numero_oc)
				THEN
					LET i        = k
					LET encontro = 1
					EXIT FOR
				END IF
			END FOR
		END FOR
		IF encontro THEN
			LET mensaje = 'La Orden de Compra: ',
				rm_det_oc[i].r49_numero_oc USING "<<<<<<&",
					' esta repetida. Por favor borrela',
					' para continuar.'
			CALL fl_mostrar_mensaje(mensaje, 'exclamation')
			CONTINUE INPUT
		END IF
		CALL mostrar_total_oc(max_row)
END INPUT
IF vm_num_oc = 0 THEN
	LET int_flag = 0
END IF

END FUNCTION



FUNCTION mostrar_total_oc(max_row)
DEFINE max_row		SMALLINT
DEFINE i		SMALLINT

LET rm_r48.r48_costo_oc = 0.00
FOR i = 1 TO max_row
	IF rm_det_oc[i].r49_numero_oc IS NULL THEN
		CONTINUE FOR
	END IF
	LET rm_r48.r48_costo_oc = rm_r48.r48_costo_oc +
					(rm_det_oc[i].r49_costo_oc /
					 rm_det_oc[i].r49_cant_unid)
END FOR
DISPLAY BY NAME rm_r48.r48_costo_oc

END FUNCTION



FUNCTION consulta_ordenes_compras()
DEFINE i, j 		SMALLINT

LET int_flag = 0
CALL set_count(vm_num_oc)
DISPLAY ARRAY rm_det_oc TO rm_det_oc.*
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT DISPLAY
	ON KEY(F5)
		LET i = arr_curr()
		CALL ver_orden_compra(i)
		LET int_flag = 0
        --#BEFORE DISPLAY
                --#CALL dialog.keysetlabel("ACCEPT", "")
	--#BEFORE ROW
		--#LET i = arr_curr()
		--#LET j = scr_line()
		--#CALL muestra_contadores_det(i, vm_num_oc)
		--#CALL mostrar_total_oc(vm_num_oc)
        --#AFTER DISPLAY
                --#CONTINUE DISPLAY
END DISPLAY
CALL muestra_contadores_det(0, vm_num_oc)

END FUNCTION



FUNCTION graba_ordenes_compras()
DEFINE resul, i		SMALLINT

WHENEVER ERROR CONTINUE
DELETE FROM rept049
	WHERE r49_compania    = vg_codcia
	  AND r49_localidad   = vg_codloc
	  AND r49_composicion = rm_r48.r48_composicion
	  AND r49_item_comp   = rm_r48.r48_item_comp
	  AND r49_sec_carga   = rm_r48.r48_sec_carga
IF STATUS <> 0 THEN
	WHENEVER ERROR STOP
	CALL fl_mostrar_mensaje('Ha ocurrido un error al intentar borrar la lista de ordenes de compra de esta composición. Por favor llame al ADMINISTRADOR.', 'stop')
	RETURN 0
END IF
LET resul = 1
FOR i = 1 TO vm_num_oc
	IF rm_det_oc[i].r49_numero_oc IS NULL THEN
		CONTINUE FOR
	END IF
	IF rm_det_oc[i].c10_estado <> 'C' THEN
		CONTINUE FOR
	END IF
	WHENEVER ERROR CONTINUE
	INSERT INTO rept049
		VALUES (vg_codcia, vg_codloc, rm_r48.r48_composicion,
			rm_r48.r48_item_comp, rm_r48.r48_sec_carga,
			rm_det_oc[i].r49_numero_oc, rm_det_oc[i].r49_costo_oc,
			rm_det_oc[i].r49_cant_unid, vg_usuario, CURRENT)
	IF STATUS <> 0 THEN
		WHENEVER ERROR STOP
		CALL fl_mostrar_mensaje('Ha ocurrido un error al intentar insertar la lista de ordenes de compra de esta composición. Por favor llame al ADMINISTRADOR.', 'stop')
		LET resul = 0
		EXIT FOR
	END IF
END FOR
CALL mostrar_total_oc(vm_num_oc)
SELECT * FROM rept048
	WHERE r48_compania    = vg_codcia
	  AND r48_localidad   = vg_codloc
	  AND r48_composicion = rm_r48.r48_composicion
	  AND r48_item_comp   = rm_r48.r48_item_comp
	  AND r48_sec_carga   = rm_r48.r48_sec_carga
IF STATUS <> NOTFOUND THEN
	IF rm_r48.r48_costo_oc IS NULL THEN
		LET rm_r48.r48_costo_oc = 0
	END IF
	LET rm_r48.r48_costo_comp = rm_r48.r48_costo_inv + rm_r48.r48_costo_oc
	WHENEVER ERROR CONTINUE
	UPDATE rept048
		SET r48_costo_oc   = rm_r48.r48_costo_oc,
		    r48_costo_comp = rm_r48.r48_costo_comp
		WHERE r48_compania    = vg_codcia
		  AND r48_localidad   = vg_codloc
		  AND r48_composicion = rm_r48.r48_composicion
		  AND r48_item_comp   = rm_r48.r48_item_comp
		  AND r48_sec_carga   = rm_r48.r48_sec_carga
	IF STATUS <> 0 THEN
		WHENEVER ERROR STOP
		CALL fl_mostrar_mensaje('No se puede actualizar el costo de ordenes de compra en la composición. Por favor llame al ADMINISTRADOR.', 'stop')
		LET resul = 0
	END IF
END IF
WHENEVER ERROR STOP
RETURN resul

END FUNCTION



FUNCTION datos_oc(numero_oc, i, j)
DEFINE numero_oc	LIKE ordt010.c10_numero_oc
DEFINE i, j		SMALLINT
DEFINE r_c10		RECORD LIKE ordt010.*

LET rm_det_oc[i].r49_numero_oc = numero_oc
CALL fl_lee_orden_compra(vg_codcia, vg_codloc, rm_det_oc[i].r49_numero_oc)
	RETURNING r_c10.*
LET rm_det_oc[i].c10_referencia = r_c10.c10_referencia
LET rm_det_oc[i].r49_costo_oc   = (r_c10.c10_tot_compra - r_c10.c10_tot_impto
					- r_c10.c10_dif_cuadre
					+ r_c10.c10_tot_dscto)
LET rm_det_oc[i].r49_costo_oc   = rm_det_oc[i].r49_costo_oc +
					(rm_det_oc[i].r49_costo_oc *
					 r_c10.c10_recargo / 100)
LET rm_det_oc[i].c10_estado     = r_c10.c10_estado
IF rm_det_oc[i].r49_cant_unid IS NULL THEN
	LET rm_det_oc[i].r49_cant_unid = 1
END IF
DISPLAY rm_det_oc[i].* TO rm_det_oc[j].*

END FUNCTION



FUNCTION verificacion_oc()
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE i, j		SMALLINT

FOR i = 1 TO vm_num_oc
	CALL fl_lee_orden_compra(vg_codcia,vg_codloc,rm_det_oc[i].r49_numero_oc)
		RETURNING r_c10.*
	IF r_c10.c10_estado <> 'C' THEN
		FOR j = i TO vm_num_oc - 1
			LET rm_det_oc[j].* = rm_det_oc[i + 1].*
		END FOR
		INITIALIZE rm_det_oc[vm_num_oc].* TO NULL
		LET vm_num_oc = vm_num_oc - 1
	END IF
END FOR

END FUNCTION



FUNCTION mostrar_item(item)
DEFINE item		LIKE rept020.r20_item
DEFINE param		VARCHAR(60)

LET param = ' "', item CLIPPED, '"'
CALL fl_ejecuta_comando('REPUESTOS', vg_modulo, 'repp108 ', param, 1)

END FUNCTION



FUNCTION ver_orden_compra(i)
DEFINE i		SMALLINT
DEFINE param		VARCHAR(60)

LET param = ' ', rm_det_oc[i].r49_numero_oc
CALL fl_ejecuta_comando('COMPRAS', 'OC', 'ordp200 ', param, 1)

END FUNCTION



FUNCTION imprimir_transferencia(cod_tran, num_tran)
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE param		VARCHAR(60)

LET param = ' "', cod_tran, '" ', num_tran
CALL fl_ejecuta_comando('REPUESTOS', vg_modulo, 'repp415 ', param, 1)

END FUNCTION



FUNCTION consulta_carga_stock(expr_sql)
DEFINE expr_sql		CHAR(1500)
DEFINE query		CHAR(3000)

LET query = 'SELECT *, ROWID ',
		' FROM rept048 ',
		' WHERE r48_compania  = ', vg_codcia,
		'   AND r48_localidad = ', vg_codloc,
		'   AND ', expr_sql CLIPPED,
		' ORDER BY r48_composicion ASC, r48_sec_carga ASC '
PREPARE cons_r48 FROM query
DECLARE q_r48 CURSOR FOR cons_r48
LET vm_num_rows2 = 1
FOREACH q_r48 INTO rm_r48.*, vm_rows2[vm_num_rows2]
	LET vm_num_rows2 = vm_num_rows2 + 1
	IF vm_num_rows2 > vm_max_rows THEN
		EXIT FOREACH
	END IF
END FOREACH 
LET vm_num_rows2 = vm_num_rows2 - 1
IF vm_num_rows2 = 0 THEN
	LET vm_num_rows2    = 0
	LET vm_row_current2 = 0
	LET vm_num_det      = 0
	CALL muestra_contadores(0, 0)
	CALL borrar_cabecera2()
	CALL borrar_detalle2()
	CALL fl_mensaje_consulta_sin_registros()
	RETURN 0
END IF
LET vm_row_current2 = 1
CALL lee_muestra_registro2(vm_rows2[vm_row_current2])
RETURN 1

END FUNCTION



FUNCTION lee_muestra_registro2(row)
DEFINE row		INTEGER
DEFINE r_r02		RECORD LIKE rept002.*

IF vm_num_rows2 <= 0 THEN
	RETURN
END IF
CALL borrar_cabecera2()
SELECT * INTO rm_r48.* FROM rept048 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con indice: ', row USING "<<<<<<&"
END IF
CALL fl_lee_bodega_rep(vg_codcia, rm_r48.r48_bodega_comp) RETURNING r_r02.*
CALL fl_lee_composicion_cab2(vg_codcia, vg_codloc, rm_r48.r48_composicion,
				rm_r48.r48_item_comp)
	RETURNING rm_r46.*
DISPLAY BY NAME rm_r48.r48_composicion, rm_r48.r48_sec_carga,
		rm_r48.r48_bodega_comp, r_r02.r02_nombre, rm_r48.r48_item_comp,
		rm_r46.r46_desc_comp, rm_r48.r48_referencia,
		rm_r48.r48_carg_stock, rm_r48.r48_costo_mo,
		rm_r48.r48_usu_cierre, rm_r48.r48_fec_cierre,
		rm_r48.r48_usuario, rm_r48.r48_fecing
CALL muestra_contadores(vm_row_current2, vm_num_rows2)
CALL muestra_estado2()
CALL muestra_detalle2()

END FUNCTION



FUNCTION muestra_detalle2()
DEFINE query 		CHAR(2000)
DEFINE expr_est		VARCHAR(150)
DEFINE expr		VARCHAR(15)
DEFINE cam_c		SMALLINT
DEFINE r_r10		RECORD LIKE rept010.*

CALL borrar_detalle2()
IF rm_r48.r48_sec_carga IS NOT NULL AND rm_r48.r48_estado = 'C' THEN
	LET cam_c = 0
	LET query = 'SELECT r20_bodega, r20_item, r47_desc_part, r20_cant_ven,',
			' r20_costnue_mb, r47_marca_p, r47_division_p, ',
			'r47_sub_linea_p, r47_cod_grupo_p, r47_cod_clase_p, ',
			'r47_nom_div_p, r47_desc_sub_p, r47_desc_grupo_p, ',
			'r47_desc_clase_p, r47_desc_marca_p, r47_desc_part ',
		' FROM rept047, rept048, rept053, rept020 ',
            	' WHERE r47_compania    = ', vg_codcia, 
	    	'   AND r47_localidad   = ', vg_codloc,
	    	'   AND r47_composicion = ', rm_r48.r48_composicion,
	    	'   AND r47_item_comp   = "', rm_r48.r48_item_comp CLIPPED, '"',
		'   AND r48_compania    = r47_compania ',
		'   AND r48_localidad   = r47_localidad ',
		'   AND r48_composicion = r47_composicion ',
		'   AND r48_item_comp   = r47_item_comp ',
		'   AND r48_sec_carga   = ', rm_r48.r48_sec_carga,
		'   AND r53_compania    = r48_compania ',
		'   AND r53_localidad   = r48_localidad ',
		'   AND r53_composicion = r48_composicion ',
		'   AND r53_item_comp   = r48_item_comp ',
		'   AND r53_sec_carga   = r48_sec_carga ',
		'   AND r53_cod_tran    = "TR" ',
		'   AND r20_compania    = r53_compania ',
		'   AND r20_localidad   = r53_localidad ',
		'   AND r20_cod_tran    = r53_cod_tran ',
		'   AND r20_num_tran    = r53_num_tran ',
		'   AND r20_bodega      = r47_bodega_part ',
		'   AND r20_item        = r47_item_part ',
	    	' ORDER BY 2'
ELSE
	LET cam_c    = 1
	LET expr_est = '   AND r48_estado      = "', rm_r48.r48_estado, '"'
	LET expr     = ' OUTER'
	IF rm_r48.r48_estado IS NULL THEN
		LET expr_est = '   AND r48_estado      = "P"'
		LET expr     = NULL
	END IF
	LET expr_est = '   AND r48_estado      = "', rm_r48.r48_estado, '"'
	LET query = 'SELECT r47_bodega_part, r47_item_part, r47_desc_part,',
			' (r47_cantidad * ', rm_r48.r48_carg_stock,
			'), r47_costo_part,',
			' r47_marca_p, r47_division_p, r47_sub_linea_p,',
			' r47_cod_grupo_p, r47_cod_clase_p, r47_nom_div_p,',
			' r47_desc_sub_p, r47_desc_grupo_p, r47_desc_clase_p,',
			' r47_desc_marca_p, r47_desc_part ',
		' FROM rept047, ', expr CLIPPED, ' rept048 ',
            	' WHERE r47_compania    = ', vg_codcia, 
	    	'   AND r47_localidad   = ', vg_codloc,
	    	'   AND r47_composicion = ', rm_r48.r48_composicion,
	    	'   AND r47_item_comp   = "', rm_r48.r48_item_comp CLIPPED, '"',
		'   AND r48_compania    = r47_compania ',
		'   AND r48_localidad   = r47_localidad ',
		'   AND r48_composicion = r47_composicion ',
		'   AND r48_item_comp   = r47_item_comp ',
		expr_est CLIPPED,
	    	' ORDER BY 2'
END IF
PREPARE cons3 FROM query
DECLARE q_cons3 CURSOR FOR cons3
LET vm_num_det = 1
FOREACH q_cons3 INTO rm_carga[vm_num_det].*, rm_adi[vm_num_det].*
	IF cam_c THEN
		CALL fl_lee_item(vg_codcia, rm_carga[vm_num_det].r20_item)
			RETURNING r_r10.*
		LET rm_carga[vm_num_det].r20_costnue_mb = r_r10.r10_costo_mb
	END IF
	LET vm_num_det = vm_num_det + 1
        IF vm_num_det > vm_max_det THEN
		EXIT FOREACH
	END IF	
END FOREACH 
LET vm_num_det = vm_num_det - 1
IF vm_num_det = 0 THEN 
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_num_det = 0
	CALL borrar_detalle2()
	RETURN
END IF
CALL muestra_lineas_carga()

END FUNCTION



FUNCTION muestra_lineas_carga()
DEFINE i, lim 		SMALLINT

FOR i = 1 TO fgl_scr_size('rm_carga')
	CLEAR rm_carga[i].*
END FOR
LET lim = vm_num_det
IF vm_num_det > fgl_scr_size('rm_carga') THEN
	LET lim = fgl_scr_size('rm_carga')
END IF
FOR i = 1 TO lim
	DISPLAY rm_carga[i].* TO rm_carga[i].*
END FOR
CALL muestra_contadores_det(0, vm_num_det)
CALL mostrar_total(vm_num_det)

END FUNCTION



FUNCTION siguiente_registro2()

IF vm_num_rows2 = 0 THEN
	RETURN
END IF
IF vm_row_current2 < vm_num_rows2 THEN
	LET vm_row_current2 = vm_row_current2 + 1
END IF
CALL lee_muestra_registro2(vm_rows2[vm_row_current2])

END FUNCTION



FUNCTION anterior_registro2()

IF vm_num_rows2 = 0 THEN
	RETURN
END IF
IF vm_row_current2 > 1 THEN
	LET vm_row_current2 = vm_row_current2 - 1
END IF
CALL lee_muestra_registro2(vm_rows2[vm_row_current2])

END FUNCTION



FUNCTION control_ver_detalle2()
DEFINE i, j 		SMALLINT

LET int_flag = 0
CALL set_count(vm_num_det)
DISPLAY ARRAY rm_carga TO rm_carga.*
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT DISPLAY
	ON KEY(F5)
		IF rm_g05.g05_grupo = 'SI' OR rm_g05.g05_grupo = 'GE' THEN
			LET i = arr_curr()
			CALL mostrar_item(rm_r48.r48_item_comp)
			LET int_flag = 0
		END IF
	ON KEY(F6)
		IF rm_g05.g05_grupo = 'SI' OR rm_g05.g05_grupo = 'GE' THEN
			LET i = arr_curr()
			CALL mostrar_item(rm_carga[i].r20_item)
			LET int_flag = 0
		END IF
	ON KEY(F7)
		IF rm_r46.r46_tiene_oc = 'S' THEN
			CALL control_ordenes_compra('M', vm_num_det)
			LET int_flag = 0
		END IF
	ON KEY(F8)
		CALL control_detalle_trans()
		LET int_flag = 0
	ON KEY(F9)
		LET i = arr_curr()
		CALL control_stock_items(rm_r48.r48_item_comp, 0)
		LET int_flag = 0
	ON KEY(F10)
		LET i = arr_curr()
		CALL control_stock_items(rm_carga[i].r20_item, i)
		LET int_flag = 0
        --#BEFORE DISPLAY
                --#CALL dialog.keysetlabel("ACCEPT", "")
		--#IF rm_r46.r46_tiene_oc = 'S' THEN
                	--#CALL dialog.keysetlabel("F7", "Ordenes Compra")
		--#ELSE
                	--#CALL dialog.keysetlabel("F7", "")
		--#END IF
                --#CALL dialog.keysetlabel("F8", "Detalle Trans.")
		--#CALL dialog.keysetlabel("F9", "Stock Item Comp.")
	--#BEFORE ROW
		--#LET i = arr_curr()
		--#LET j = scr_line()
		--#CALL mostrar_etiquetas(i, vm_num_det)
		--#IF rm_g05.g05_grupo = 'SI' OR rm_g05.g05_grupo = 'GE' THEN
			--#CALL dialog.keysetlabel("F5", "Item Compuesto")
			--#CALL dialog.keysetlabel("F6", "Item Parte")
			--#CALL dialog.keysetlabel("F10","Stock Item Parte")
		--#ELSE
			--#CALL dialog.keysetlabel("F5", "")
			--#CALL dialog.keysetlabel("F6", "")
			--#CALL dialog.keysetlabel("F10", "")
		--#END IF
        --#AFTER DISPLAY
                --#CONTINUE DISPLAY
END DISPLAY
CALL muestra_lineas_carga()

END FUNCTION



FUNCTION control_detalle_trans()
DEFINE r_det		ARRAY[500] OF RECORD
				cod_tran	LIKE rept019.r19_cod_tran,
				num_tran	LIKE rept019.r19_num_tran,
				bodega		LIKE rept019.r19_bodega_ori,
				referencia	LIKE rept019.r19_referencia,
				tipo_comp	LIKE rept040.r40_tipo_comp,
				num_comp	LIKE rept040.r40_num_comp
			END RECORD
DEFINE num_r		INTEGER
DEFINE num_row, i	SMALLINT
DEFINE max_row		SMALLINT
DEFINE query		CHAR(1500)

LET query = 'SELECT rept019.ROWID, r19_cod_tran, r19_num_tran, ',
			'CASE WHEN r19_cod_tran = "AC" ',
				'THEN "" ',
				'ELSE r19_bodega_ori ',
			'END, r19_referencia, r40_tipo_comp, r40_num_comp ',
		' FROM rept053, rept019, OUTER rept040 ',
		' WHERE r53_compania    = ', vg_codcia,
		'   AND r53_localidad   = ', vg_codloc,
		'   AND r53_composicion = ', rm_r48.r48_composicion,
		'   AND r53_item_comp   = "', rm_r48.r48_item_comp CLIPPED, '"',
		'   AND r53_sec_carga   = ', rm_r48.r48_sec_carga,
		'   AND r19_compania    = r53_compania ',
		'   AND r19_localidad   = r53_localidad ',
		'   AND r19_cod_tran    = r53_cod_tran ',
		'   AND r19_num_tran    = r53_num_tran ',
		'   AND r40_compania    = r19_compania ',
		'   AND r40_localidad   = r19_localidad ',
		'   AND r40_cod_tran    = r19_cod_tran ',
		'   AND r40_num_tran    = r19_num_tran ',
		' ORDER BY 1, 2, 3 '
PREPARE cons_dett FROM query
DECLARE q_cursor1 CURSOR FOR cons_dett
LET max_row = 500
LET num_row = 1
FOREACH q_cursor1 INTO num_r, r_det[num_row].*
	LET num_row = num_row + 1
	IF num_row > max_row THEN
		EXIT FOREACH
	END IF
END FOREACH
LET num_row = num_row - 1
IF num_row = 0 THEN
	CALL fl_mostrar_mensaje('No se ha generado ninguna transaccion.', 'exclamation')
	RETURN
END IF
OPEN WINDOW w_repf249_3 AT 07, 05 WITH 14 ROWS, 71 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
		MESSAGE LINE LAST)
IF vg_gui = 1 THEN
	OPEN FORM f_repf249_3 FROM '../forms/repf247_2'
ELSE
	OPEN FORM f_repf249_3 FROM '../forms/repf247_2c'
END IF
DISPLAY FORM f_repf249_3
--#DISPLAY 'Transaccion' TO tit_col1
--#DISPLAY 'BD'          TO tit_col2
--#DISPLAY 'Referencia'  TO tit_col3
--#DISPLAY 'Comprobante' TO tit_col4
LET int_flag = 0
CALL set_count(num_row)
DISPLAY ARRAY r_det TO r_det.*
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT DISPLAY
	ON KEY(F5)
		LET i = arr_curr()
		IF r_det[i].tipo_comp IS NOT NULL THEN
			CALL ver_contabilizacion(r_det[i].tipo_comp,
							r_det[i].num_comp)	
			LET int_flag = 0
		END IF
	ON KEY(F6)
		LET i = arr_curr()
		CALL fl_ver_transaccion_rep(vg_codcia, vg_codloc,
					r_det[i].cod_tran, r_det[i].num_tran)
		LET int_flag = 0
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel('ACCEPT', '')
	--#BEFORE ROW
		--#LET i = arr_curr()
		--#DISPLAY i       TO num_row
		--#DISPLAY num_row TO max_row
		--#IF r_det[i].tipo_comp IS NOT NULL THEN
			--#CALL dialog.keysetlabel('F5', 'Contabilizacion')
		--#ELSE
			--#CALL dialog.keysetlabel('F5', '')
		--#END IF
	--#AFTER DISPLAY
		--#CONTINUE DISPLAY
END DISPLAY
LET int_flag = 0
CLOSE WINDOW w_repf249_3
RETURN

END FUNCTION



FUNCTION ver_contabilizacion(tipo_comp, num_comp)
DEFINE tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE num_comp		LIKE ctbt012.b12_num_comp
DEFINE param		VARCHAR(60)

LET param = ' "', tipo_comp, '" ', num_comp CLIPPED
CALL fl_ejecuta_comando('CONTABILIDAD', 'CB', 'ctbp201 ', param, 0)

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
DISPLAY BY NAME rm_adi[i].descripcion
DISPLAY BY NAME rm_adi[i].r47_nom_div_p, rm_adi[i].r47_desc_sub_p,
		rm_adi[i].r47_desc_grupo_p, rm_adi[i].r47_desc_clase_p,
		rm_adi[i].descripcion

END FUNCTION 



FUNCTION muestra_estado2()

DISPLAY BY NAME rm_r48.r48_estado
CASE rm_r48.r48_estado
	WHEN 'P' DISPLAY "EN PROCESO"       TO nom_est
	WHEN 'C' DISPLAY "CARGADO EN STOCK" TO nom_est
	WHEN 'E' DISPLAY "ELIMINADO"        TO nom_est
END CASE

END FUNCTION 



FUNCTION control_imprimir_carga()
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
DEFINE query		CHAR(2000)

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
IF rm_r48.r48_estado = 'C' THEN
	LET query = 'SELECT 0, r20_bodega, r20_item, r47_desc_part,',
			' r47_desc_clase_p, ',
			'r10_uni_med, r20_cant_ven, r47_marca_p ',
		' FROM rept047, rept048, rept053, rept020, rept010 ',
            	' WHERE r47_compania    = ', vg_codcia, 
	    	'   AND r47_localidad   = ', vg_codloc,
	    	'   AND r47_composicion = ', rm_r48.r48_composicion,
	    	'   AND r47_item_comp   = "', rm_r48.r48_item_comp CLIPPED, '"',
		'   AND r48_compania    = r47_compania ',
		'   AND r48_localidad   = r47_localidad ',
		'   AND r48_composicion = r47_composicion ',
		'   AND r48_item_comp   = r47_item_comp ',
		'   AND r48_sec_carga   = ', rm_r48.r48_sec_carga,
		'   AND r53_compania    = r48_compania ',
		'   AND r53_localidad   = r48_localidad ',
		'   AND r53_composicion = r48_composicion ',
		'   AND r53_item_comp   = r48_item_comp ',
		'   AND r53_sec_carga   = r48_sec_carga ',
		'   AND r20_compania    = r53_compania ',
		'   AND r20_localidad   = r53_localidad ',
		'   AND r20_cod_tran    = r53_cod_tran ',
		'   AND r20_num_tran    = r53_num_tran ',
		'   AND r20_bodega      = r47_bodega_part ',
		'   AND r20_item        = r47_item_part ',
		'   AND r10_compania    = r20_compania ',
		'   AND r10_codigo      = r20_item ',
	    	' ORDER BY 3'
ELSE
	LET query = 'SELECT 0, r47_bodega_part, r47_item_part, r47_desc_part,',
			' r47_desc_clase_p, ',
			'r10_uni_med, r47_cantidad, r47_marca_p ',
		' FROM rept047, rept010, rept048 ',
            	' WHERE r47_compania    = ', vg_codcia, 
	    	'   AND r47_localidad   = ', vg_codloc,
	    	'   AND r47_composicion = ', rm_r48.r48_composicion,
	    	'   AND r47_item_comp   = "', rm_r48.r48_item_comp CLIPPED, '"',
		'   AND r10_compania    = r47_compania ',
		'   AND r10_codigo      = r47_item_part ',
		'   AND r48_compania    = r47_compania ',
		'   AND r48_localidad   = r47_localidad ',
		'   AND r48_composicion = r47_composicion ',
		'   AND r48_item_comp   = r47_item_comp ',
		'   AND r48_sec_carga   = ', rm_r48.r48_sec_carga,
	    	' ORDER BY 3'
END IF
PREPARE imp_car FROM query
DECLARE q_imp_car CURSOR FOR imp_car
START REPORT report_carga TO PIPE comando
LET r_rep.num_lin = 0
FOREACH q_imp_car INTO r_rep.*
	LET r_rep.num_lin  = r_rep.num_lin + 1
	OUTPUT TO REPORT report_carga(r_rep.*)
END FOREACH
FINISH REPORT report_carga

END FUNCTION



REPORT report_carga(r_rep)
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
DEFINE r_r46		RECORD LIKE rept046.*
DEFINE documento	VARCHAR(60)
DEFINE usuario		VARCHAR(10,5)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE nom_est		VARCHAR(25)
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
	LET documento = "COMPROBANTE DE CARGA STOCK No. ",
			rm_r48.r48_sec_carga USING "<<<<<<&"
	CALL fl_justifica_titulo('D', rm_r48.r48_usuario, 10) RETURNING usuario
	CALL fl_justifica_titulo('C', documento CLIPPED, 80) RETURNING titulo
	LET titulo = modulo, titulo
	LET nom_est = "ESTADO:"
	CASE rm_r48.r48_estado
		WHEN 'P' LET nom_est = nom_est CLIPPED, " EN PROCESO"
		WHEN 'C' LET nom_est = nom_est CLIPPED, " CARGADO EN STOCK"
	END CASE
	CALL fl_justifica_titulo('D', nom_est, 24) RETURNING nom_est
	CALL fl_lee_composicion_cab2(vg_codcia,vg_codloc,rm_r48.r48_composicion,
					rm_r48.r48_item_comp)
		RETURNING r_r46.*
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 001, rm_g01.g01_razonsocial,
	      COLUMN 122, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, titulo CLIPPED,
	      COLUMN 126, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 027, "DIVISION COMP.  : ", r_r46.r46_division_c CLIPPED,
			" ", r_r46.r46_nom_div_c CLIPPED,
	      COLUMN 098, "COMPOSICION No. ",
			r_r46.r46_composicion USING "<<<<<<&"
	PRINT COLUMN 027, "LINEA COMP.     : ", r_r46.r46_sub_linea_c CLIPPED,
			" ", r_r46.r46_desc_sub_c CLIPPED
	PRINT COLUMN 027, "GRUPO COMP.     : ", r_r46.r46_cod_grupo_c CLIPPED,
			" ", r_r46.r46_desc_grupo_c CLIPPED
	PRINT COLUMN 027, "MARCA COMP.     : ", r_r46.r46_marca_c CLIPPED,
			" ", r_r46.r46_desc_marca_c CLIPPED,
	      COLUMN 109, nom_est CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", DATE(TODAY) USING 'dd-mm-yyyy',
		1 SPACES, TIME,
	      COLUMN 045, "REFERENCIA : ", rm_r48.r48_referencia CLIPPED,
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
