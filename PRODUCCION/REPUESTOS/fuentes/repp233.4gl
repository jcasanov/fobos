------------------------------------------------------------------------------
-- Titulo           : repp233.4gl - Mantenimiento de Nota de Pedidos
-- Elaboracion      : 14-Abr-2003
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp233 base módulo compañía localidad [nota_ped]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_nuevoprog	CHAR(400)
DEFINE rm_r16		RECORD LIKE rept016.*
DEFINE rm_r81		RECORD LIKE rept081.*
DEFINE rm_r82		RECORD LIKE rept082.*
DEFINE vm_nivel		LIKE ctbt001.b01_nivel
DEFINE vm_grupo_linea	LIKE gent020.g20_grupo_linea
DEFINE vm_num_rows      SMALLINT
DEFINE vm_row_current   SMALLINT
DEFINE vm_max_rows      SMALLINT
DEFINE vm_max_elm       SMALLINT
DEFINE vm_num_repd      SMALLINT
DEFINE vm_num_repd_aux  SMALLINT
DEFINE vm_scr_lin       SMALLINT
DEFINE vm_size_arr	SMALLINT
DEFINE vm_flag_grabar	SMALLINT 
DEFINE rm_orden 	ARRAY[15] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_r_rows	ARRAY [1000] OF LIKE rept081.r81_pedido
DEFINE rm_detadu 	ARRAY [1300] OF RECORD
				r82_partida	LIKE rept082.r82_partida,
				r82_item	LIKE rept082.r82_item,
			       r82_cod_item_prov LIKE rept082.r82_cod_item_prov,
				r82_descripcion	LIKE rept082.r82_descripcion,
				r82_cod_unid	LIKE rept082.r82_cod_unid,
				r82_cantidad	LIKE rept082.r82_cantidad,
				r82_peso_item	LIKE rept082.r82_peso_item,
				total_peso	DECIMAL(13,4),
				r82_prec_exfab	LIKE rept082.r82_prec_exfab,
-- r82_prec_fob_mi, r82_prec_fob_mb
-- estos campos son llenados segun NPC por la liquidación por lo tanto no 
-- es necesario mostrarlos en este proceso (RCA)
--				r82_prec_fob_mi	LIKE rept082.r82_prec_fob_mi,
--				r82_prec_fob_mb	LIKE rept082.r82_prec_fob_mb,
				total_fob	DECIMAL(13,4)
			END RECORD
DEFINE rm_detadu_aux	ARRAY [1300] OF RECORD
				r82_partida	LIKE rept082.r82_partida,
				r82_item	LIKE rept082.r82_item,
			       r82_cod_item_prov LIKE rept082.r82_cod_item_prov,
				r82_descripcion	LIKE rept082.r82_descripcion,
				r82_cod_unid	LIKE rept082.r82_cod_unid,
				r82_cantidad	LIKE rept082.r82_cantidad,
				r82_peso_item	LIKE rept082.r82_peso_item,
				total_peso	DECIMAL(13,4),
				r82_prec_exfab	LIKE rept082.r82_prec_exfab,
--				r82_prec_fob_mi	LIKE rept082.r82_prec_fob_mi,
--				r82_prec_fob_mb	LIKE rept082.r82_prec_fob_mb,
				total_fob	DECIMAL(13,4)
			END RECORD
DEFINE vm_total_cant	DECIMAL(22,10)
DEFINE vm_total_pesgen	DECIMAL(22,10)
DEFINE vm_total_fobgen	DECIMAL(22,10)
DEFINE vm_moneda_ped	LIKE rept081.r81_moneda_base
DEFINE vm_estado	LIKE rept016.r16_estado
DEFINE moneda9		LIKE gent013.g13_simbolo
DEFINE rm_r83		RECORD LIKE rept083.*
DEFINE rm_r84		RECORD LIKE rept084.*



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp233.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 THEN  -- Validar # parámetros correcto
	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto', 'stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'repp233'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE i		SMALLINT
DEFINE r_r81		RECORD LIKE rept081.*
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
LET vm_max_rows = 1000
LET vm_max_elm  = 1300
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 22
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_mas AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST - 1, MENU LINE lin_menu,
		BORDER, MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
	OPEN FORM f_mas FROM "../forms/repf233_1"
ELSE
	OPEN FORM f_mas FROM "../forms/repf233_1c"
END IF
DISPLAY FORM f_mas
CALL mostrar_botones_detalle()
SELECT MAX(b01_nivel) INTO vm_nivel FROM ctbt001
IF vm_nivel IS NULL THEN
	CALL fl_mostrar_mensaje('No existe ningun nivel de cuenta configurado en la compania.','stop')
	EXIT PROGRAM
END IF
DECLARE qu_gl CURSOR FOR SELECT g20_grupo_linea FROM gent020
	WHERE g20_compania = vg_codcia
OPEN qu_gl 
FETCH qu_gl INTO vm_grupo_linea 
IF STATUS = NOTFOUND THEN                              
	CALL fl_mostrar_mensaje('No hay grupo de División configurado.','stop') 
	EXIT PROGRAM
END IF
CALL iniciar_vars()
FOR i = 1 TO 15
	LET rm_orden[i] = '' 
END FOR
LET vm_num_rows     = 0
LET vm_row_current  = 0
LET vm_num_repd     = 0
LET vm_num_repd_aux = 0
LET vm_scr_lin      = 0
CALL muestra_contadores_det(0)
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Detalle'
		HIDE OPTION 'Eliminar'
		HIDE OPTION 'Imprimir'
		IF num_args() = 5 THEN
			HIDE OPTION 'Nota de Pedido'
			HIDE OPTION 'Consultar'
			LET rm_r81.r81_pedido = arg_val(5)
			CALL fl_lee_nota_pedido_rep(vg_codcia, vg_codloc,
							rm_r81.r81_pedido)
				RETURNING r_r81.*
                	CALL control_consulta()
			IF vm_num_rows = 0 THEN
                                EXIT PROGRAM
                        END IF
                	CALL muestra_detalle_arr()
                        EXIT PROGRAM
		END IF
	COMMAND KEY('N') 'Nota de Pedido' 'Modificar registro corriente. '
                CALL control_nota_pedido()
		IF vm_row_current > 0 THEN
			SHOW OPTION 'Eliminar'
			SHOW OPTION 'Imprimir'
                        SHOW OPTION 'Detalle'
		ELSE
			HIDE OPTION 'Eliminar'
			HIDE OPTION 'Imprimir'
                        HIDE OPTION 'Detalle'
		END IF
                IF vm_row_current = vm_num_rows THEN
                        HIDE OPTION 'Avanzar'
                END IF
                IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
                CALL control_consulta()
                IF vm_num_rows <= 1 THEN
                        SHOW OPTION 'Detalle'
			SHOW OPTION 'Imprimir'
                        HIDE OPTION 'Avanzar'
                        HIDE OPTION 'Retroceder'
                        IF vm_num_rows = 0 THEN
                        	HIDE OPTION 'Detalle'
				HIDE OPTION 'Imprimir'
				HIDE OPTION 'Eliminar'
                        END IF
                ELSE
			SHOW OPTION 'Imprimir'
                        SHOW OPTION 'Avanzar'
                        SHOW OPTION 'Detalle'
                END IF
                IF vm_num_rows >= 1 THEN
			SHOW OPTION 'Eliminar'
		END IF
                IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
	 COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro. '
                CALL muestra_siguiente_registro()
                IF vm_row_current = vm_num_rows THEN
                        HIDE OPTION 'Avanzar'
                        SHOW OPTION 'Retroceder'
                        NEXT OPTION 'Retroceder'
                ELSE
                        SHOW OPTION 'Avanzar'
                        SHOW OPTION 'Retroceder'
                END IF
	COMMAND KEY('R') 'Retroceder'  'Ver anterior registro. '
                CALL muestra_anterior_registro()
                IF vm_row_current = 1 THEN
                        HIDE OPTION 'Retroceder'
                        SHOW OPTION 'Avanzar'
                        NEXT OPTION 'Avanzar'
                ELSE
                        SHOW OPTION 'Avanzar'
                        SHOW OPTION 'Retroceder'
                END IF
	COMMAND KEY('D') 'Detalle' 'Muestra siguiente detalle del registro. '
                CALL muestra_detalle_arr()
	COMMAND KEY('E') 'Eliminar' 'Eliminar nota de pedido. '
		IF vm_num_rows > 0 THEN
			CALL control_eliminacion()
		END IF
	COMMAND KEY('P') 'Imprimir' 'Muestra nota de pedido para imprimir. '
		CALL imprimir()
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_nota_pedido()

MENU 'OPCIONES'
	BEFORE MENU
		IF rm_r81.r81_pedido IS NULL THEN
			HIDE OPTION 'Modificar'
			HIDE OPTION 'Detalle'
			HIDE OPTION 'Imprimir'
		ELSE
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Detalle'
			SHOW OPTION 'Imprimir'
		END IF
	COMMAND KEY('I') 'Ingresar'  'Crea una Nota de Pedido. '
		CALL nota_pedido_sub_menu('I')
		IF rm_r81.r81_pedido IS NULL THEN
			HIDE OPTION 'Modificar'
			HIDE OPTION 'Detalle'
			HIDE OPTION 'Imprimir'
		ELSE
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Detalle'
			SHOW OPTION 'Imprimir'
		END IF
	COMMAND KEY('M') 'Modificar' 'Modifica Nota de Pedido. '
		CALL nota_pedido_sub_menu('M')
	COMMAND KEY('D') 'Detalle' 'Muestra siguiente detalle del registro. '
                CALL muestra_detalle_arr()
	COMMAND KEY('P') 'Imprimir' 'Muestra nota de pedido para imprimir. '
		CALL imprimir()
	COMMAND KEY('S') 'Salir' 'Sale del menú. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION nota_pedido_sub_menu(valida)
DEFINE valida		CHAR(1)
DEFINE resp		CHAR(6)

CASE valida
	WHEN 'I'
		CALL limpiar_pantalla(1)
	WHEN 'M'
		IF vm_estado <> 'A' THEN
			CALL fl_mostrar_mensaje('Pedido no esta ACTIVO.','exclamation')
			RETURN
		END IF
END CASE
BEGIN WORK
MENU 'OPCIONES'
	BEFORE MENU
		CALL leer_cabecera()
		IF int_flag THEN
			CALL salida_por_intflag(int_flag)
			EXIT MENU
		END IF
		CALL leer_detalle()
		IF int_flag THEN
			CALL salida_por_intflag(int_flag)
			EXIT MENU
		END IF
	COMMAND KEY('C') 'Cabecera' 'Lee Cabecera del registro corriente. '
		CALL leer_cabecera()
		IF int_flag THEN
			CALL salida_por_intflag(int_flag)
			EXIT MENU
		END IF
		CALL muestra_contadores(vm_row_current, vm_num_rows)
	COMMAND KEY('D') 'Detalle' 'Lee Detalle del registro corriente. '
		CALL leer_detalle()
		IF int_flag THEN
			CALL salida_por_intflag(int_flag)
			EXIT MENU
		END IF
	COMMAND KEY('G') 'Grabar' 'Graba el registro corriente. '
		IF vm_flag_grabar = 0 THEN
			CALL control_grabar()
			EXIT MENU
		END IF
	COMMAND KEY('S') 'Salir' 'Sale del menú. '
		IF vm_flag_grabar = 0 THEN
			LET int_flag = 0
			CALL fl_hacer_pregunta('Salir al menú principal y perder los cambios realizados ?','No')
				RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				CALL salida_por_intflag(int_flag)
				EXIT MENU
			END IF
		ELSE
			CALL salida_por_intflag(0)
			EXIT MENU
		END IF
END MENU

END FUNCTION



FUNCTION control_grabar()
DEFINE r_r81		RECORD LIKE rept081.*

IF rm_r81.r81_pedido IS NULL THEN
	CALL fl_mostrar_mensaje('No puede grabar el pedido sin especificar la cabecera.','exclamation')
	RETURN
END IF
IF vm_num_repd = 0 THEN
	CALL fl_mostrar_mensaje('No puede grabar el pedido sin especificar el detalle.','exclamation')
	RETURN
END IF
CALL fl_lee_nota_pedido_rep(vg_codcia, vg_codloc, rm_r81.r81_pedido)
	RETURNING r_r81.*
IF r_r81.r81_compania IS NULL THEN
	CALL grabar_pedido()
	LET rm_r81.r81_fecing = CURRENT
	INSERT INTO rept081 VALUES (rm_r81.*)
	CALL grabar_detalle()
	COMMIT WORK
	IF vm_num_rows = vm_max_rows THEN
		LET vm_num_rows = 1
	ELSE
		LET vm_num_rows = vm_num_rows + 1
	END IF
	LET vm_row_current = vm_num_rows
	LET vm_r_rows[vm_row_current] = rm_r81.r81_pedido
	CALL muestra_reg_corriente(vm_r_rows[vm_row_current], 1)
	CALL imprimir()
	CALL fl_mensaje_registro_ingresado()
ELSE
	CALL grabar_pedido()
	UPDATE rept081 SET * = rm_r81.* WHERE CURRENT OF q_r81
	CALL grabar_detalle()
	COMMIT WORK
	CALL muestra_contadores_det(0)
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL fl_mensaje_registro_modificado()
END IF
LET vm_flag_grabar = 1

END FUNCTION



FUNCTION grabar_pedido()
DEFINE r_r16		RECORD LIKE rept016.*

CALL fl_lee_pedido_rep(vg_codcia, vg_codloc, rm_r81.r81_pedido)
	RETURNING r_r16.*
IF r_r16.r16_compania IS NOT NULL THEN
	UPDATE rept016 SET r16_proveedor = rm_r81.r81_cod_prov,
			   r16_moneda    = rm_r81.r81_moneda_base,
			   r16_aux_cont  = rm_r16.r16_aux_cont
		WHERE CURRENT OF q_r16
	RETURN
END IF
INITIALIZE r_r16.* TO NULL
LET r_r16.r16_compania    = rm_r81.r81_compania
LET r_r16.r16_localidad   = rm_r81.r81_localidad
LET r_r16.r16_pedido      = rm_r81.r81_pedido
LET r_r16.r16_estado      = vm_estado
LET r_r16.r16_tipo        = 'E'
LET r_r16.r16_linea       = NULL
LET r_r16.r16_referencia  = 'GEN. POR NOTA PEDIDO'
LET r_r16.r16_proveedor   = rm_r81.r81_cod_prov
LET r_r16.r16_moneda      = rm_r81.r81_moneda_base
LET r_r16.r16_demora      = 0
LET r_r16.r16_seguridad   = 0
LET r_r16.r16_fec_envio   = TODAY
LET r_r16.r16_fec_llegada = TODAY
LET r_r16.r16_maximo      = 0
LET r_r16.r16_minimo      = 0
LET r_r16.r16_periodo_vta = 0
LET r_r16.r16_pto_reorden = 0
LET r_r16.r16_flag_estad  = 'M'
LET r_r16.r16_aux_cont    = rm_r16.r16_aux_cont
LET r_r16.r16_usuario     = rm_r81.r81_usuario
LET r_r16.r16_fecing      = CURRENT
INSERT INTO rept016 VALUES (r_r16.*)

END FUNCTION



FUNCTION grabar_detalle()
DEFINE i		SMALLINT
DEFINE r_g16		RECORD LIKE gent016.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r17		RECORD LIKE rept017.*
DEFINE sec_partida	LIKE rept082.r82_sec_partida

DELETE FROM rept017
	WHERE r17_compania  = rm_r81.r81_compania
	  AND r17_localidad = rm_r81.r81_localidad
	  AND r17_pedido    = rm_r81.r81_pedido
DELETE FROM rept082
	WHERE r82_compania  = rm_r81.r81_compania
	  AND r82_localidad = rm_r81.r81_localidad
	  AND r82_pedido    = rm_r81.r81_pedido
LET rm_r82.r82_compania     = rm_r81.r81_compania
LET rm_r82.r82_localidad    = rm_r81.r81_localidad
LET rm_r82.r82_pedido       = rm_r81.r81_pedido
LET rm_r82.r82_porc_arancel = 0
LET rm_r82.r82_porc_salvagu = 0
CALL generar_sec_part()
FOR i = 1 TO vm_num_repd
	IF rm_detadu[i].r82_item IS NULL THEN
		CONTINUE FOR
	END IF
	CALL fl_lee_item(rm_r82.r82_compania, rm_detadu[i].r82_item)
		RETURNING r_r10.*
	CALL fl_lee_partida(r_r10.r10_partida) RETURNING r_g16.*
	INITIALIZE r_r17.* TO NULL
	LET r_r17.r17_compania    = rm_r82.r82_compania
	LET r_r17.r17_localidad   = rm_r82.r82_localidad
	LET r_r17.r17_pedido      = rm_r82.r82_pedido
	LET r_r17.r17_item        = rm_detadu[i].r82_item
	LET r_r17.r17_orden       = i
	LET r_r17.r17_estado      = vm_estado
	LET r_r17.r17_fob         = rm_detadu[i].r82_prec_exfab
	LET r_r17.r17_cantped     = rm_detadu[i].r82_cantidad
	LET r_r17.r17_cantrec     = 0
	--LET r_r17.r17_exfab_mb    = r_r17.r17_fob / rm_r81.r81_paridad_div
	LET r_r17.r17_exfab_mb    = r_r17.r17_fob * rm_r81.r81_paridad_div
	LET r_r17.r17_desp_mi     = 0
	LET r_r17.r17_desp_mb     = 0
-- Se agrega cero (0) a r_r17.r17_tot_fob_mi y r_r17.r17_tot_fob_mb
-- Si no se cae por que se obvio por cambios en forma, estos campos
-- son llenados segun NPC por la liquidación por lo tanto no es necesario
-- mostrarlos en este proceso (RCA)
	LET r_r17.r17_tot_fob_mi  = 0
	LET r_r17.r17_tot_fob_mb  = 0
--	LET r_r17.r17_tot_fob_mi  = rm_detadu[i].r82_prec_fob_mi
--	LET r_r17.r17_tot_fob_mb  = rm_detadu[i].r82_prec_fob_mb
	LET r_r17.r17_flete       = 0
	LET r_r17.r17_seguro      = 0
	LET r_r17.r17_cif         = 0
	LET r_r17.r17_arancel     = 0
	LET r_r17.r17_salvagu     = 0
	LET r_r17.r17_cargos      = 0
	LET r_r17.r17_costuni_ing = 0
	LET r_r17.r17_ind_bko     = 'S'
	LET r_r17.r17_linea       = r_r10.r10_linea
	LET r_r17.r17_rotacion    = r_r10.r10_rotacion
	LET r_r17.r17_partida     = rm_detadu[i].r82_partida
	LET r_r17.r17_porc_part   = r_g16.g16_porcentaje
	LET r_r17.r17_porc_salva  = 0
	LET r_r17.r17_vol_cuft    = r_r10.r10_vol_cuft
	LET r_r17.r17_peso        = rm_detadu[i].r82_peso_item
	LET r_r17.r17_cantpaq     = r_r10.r10_cantpaq
	INSERT INTO rept017 VALUES(r_r17.*)
	LET sec_partida = 0
	SELECT sec_part INTO sec_partida FROM tmp_part
		WHERE partida = rm_detadu[i].r82_partida
	INSERT INTO rept082
		VALUES (rm_r82.r82_compania, rm_r82.r82_localidad,
			rm_r82.r82_pedido, rm_detadu[i].r82_item, i,
			rm_detadu[i].r82_cod_item_prov, 
			rm_detadu[i].r82_descripcion, rm_detadu[i].r82_cod_unid,
		 	rm_detadu[i].r82_cantidad, rm_detadu[i].r82_prec_exfab,
-- r82_prec_fob_mi, r82_prec_fob_mb
-- estos campos son llenados segun NPC por la liquidación por lo tanto no
-- es necesario mostrarlos en este proceso, se los encera (RCA)
		 	0,
		 	0,
--		 	rm_detadu[i].r82_prec_fob_mi,
--			rm_detadu[i].r82_prec_fob_mb, 
			rm_detadu[i].r82_partida, sec_partida,
			rm_r82.r82_porc_arancel, rm_r82.r82_porc_salvagu,
		 	rm_detadu[i].r82_peso_item)
END FOR
DROP TABLE tmp_part

END FUNCTION



FUNCTION generar_sec_part()
DEFINE i, l		SMALLINT

CREATE TEMP TABLE tmp_part(
		partida		VARCHAR(15,8),
		sec_part	SMALLINT
	)
LET l = 1
FOR i = 1 TO vm_num_repd
	IF rm_detadu[i].r82_item IS NULL THEN
		CONTINUE FOR
	END IF
	SELECT * FROM tmp_part WHERE partida = rm_detadu[i].r82_partida
	IF STATUS = NOTFOUND THEN
		INSERT INTO tmp_part VALUES(rm_detadu[i].r82_partida, l)
		LET l = l + 1
	END IF
END FOR

END FUNCTION



FUNCTION bloquear_nota_pedido(pedido, flag)
DEFINE pedido		LIKE rept081.r81_pedido
DEFINE flag		SMALLINT
DEFINE r_r81		RECORD LIKE rept081.*
 
WHENEVER ERROR CONTINUE
DECLARE q_r81 CURSOR FOR
	SELECT * FROM rept081
		WHERE r81_compania  = vg_codcia
  		  AND r81_localidad = vg_codloc
		  AND r81_pedido    = pedido
	FOR UPDATE
OPEN q_r81
FETCH q_r81 INTO r_r81.*
IF STATUS < 0 THEN
	IF flag THEN
		ROLLBACK WORK
	END IF
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN 1
END IF
WHENEVER ERROR STOP
RETURN 0

END FUNCTION



FUNCTION bloquear_pedido(pedido)
DEFINE pedido		LIKE rept016.r16_pedido
DEFINE r_r16		RECORD LIKE rept016.*
 
WHENEVER ERROR CONTINUE
DECLARE q_r16 CURSOR FOR
	SELECT * FROM rept016
		WHERE r16_compania  = vg_codcia
  		  AND r16_localidad = vg_codloc
		  AND r16_pedido    = pedido
	FOR UPDATE
OPEN q_r16
FETCH q_r16 INTO r_r16.*
IF STATUS < 0 THEN
	--ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN 1
END IF
WHENEVER ERROR STOP
RETURN 0

END FUNCTION



FUNCTION salida_por_intflag(flag)
DEFINE flag		SMALLINT

IF flag THEN
	ROLLBACK WORK
END IF
CALL iniciar_vars()
CLEAR FORM
CALL mostrar_botones_detalle()
IF vm_row_current > 0 THEN
	CALL muestra_reg_corriente(vm_r_rows[vm_row_current], 0)
END IF
CALL muestra_contadores_det(0)
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION control_consulta()
DEFINE query		CHAR(1500)
DEFINE expr_sql		CHAR(1000)
DEFINE num_reg		INTEGER
DEFINE codpe_aux	LIKE rept081.r81_pedido
DEFINE codp_aux		LIKE cxpt002.p02_codprov
DEFINE nomp_aux		LIKE cxpt001.p01_nomprov
DEFINE proveedor	LIKE rept081.r81_nom_prov
DEFINE cod_aux		LIKE ctbt010.b10_cuenta
DEFINE nom_aux		LIKE ctbt010.b10_descripcion
DEFINE mone_aux         LIKE gent013.g13_moneda
DEFINE nomm_aux         LIKE gent013.g13_nombre
DEFINE deci_aux         LIKE gent013.g13_decimales
DEFINE partida		LIKE gent016.g16_partida
DEFINE capitulo		LIKE gent016.g16_capitulo

CALL limpiar_pantalla(0)
INITIALIZE codpe_aux, codp_aux, mone_aux, capitulo TO NULL
LET int_flag = 0
IF num_args() = 4 THEN
	CONSTRUCT BY NAME expr_sql ON r81_pedido, r81_fecha, r81_moneda_base,
		r81_paridad_div, r81_cod_prov, r81_nom_prov, r81_dir_prov,
		r81_ciu_prov, r81_est_prov, r81_pai_prov, r81_tel_prov,
		r81_email_prov, r81_fax_prov, r16_aux_cont, r81_marcas,
		r81_pagador, r81_forma_pago, r81_pais_origen, r81_puerto_ori,
		r81_puerto_dest, r81_tipo_trans, r81_tipo_embal,
		r81_tipo_fact_pre, r81_tipo_seguro, r81_tot_exfab,
		r81_tot_desp_mi, r81_tot_fob_mi, r81_tot_fob_mb, r81_tot_flete,
		r81_tot_car_fle, r81_tot_seguro, r81_tot_seg_neto,
		r81_tot_cargos_mb, r82_partida, r82_item, r82_cod_item_prov,
		r82_descripcion, r82_cod_unid, r82_cantidad, r82_peso_item,
		r82_prec_exfab, r81_usuario
--                r82_prec_fob_mi, r82_prec_fob_mb, r81_usuario
		ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
		ON KEY(F2)
			IF INFIELD(r81_pedido) THEN
				CALL fl_ayuda_nota_pedido(vg_codcia)
--				CALL fl_ayuda_pedidos_rep(vg_codcia, vg_codloc,
--								'T', 'T')
					RETURNING codpe_aux, proveedor
				LET int_flag = 0
				IF codpe_aux IS NOT NULL THEN
					DISPLAY codpe_aux TO r81_pedido
					DISPLAY proveedor TO tit_proveedor
				END IF
			END IF
			IF INFIELD(r81_moneda_base) THEN
                        	CALL fl_ayuda_monedas()
                                	RETURNING mone_aux, nomm_aux, deci_aux
	                        LET int_flag = 0
        	                IF mone_aux IS NOT NULL THEN
                	                DISPLAY mone_aux TO r81_moneda_base
                        	        DISPLAY nomm_aux TO tit_moneda
	                        END IF
	                END IF
			IF INFIELD(r81_cod_prov) THEN
				CALL fl_ayuda_proveedores_localidad(vg_codcia,
								vg_codloc)
					RETURNING codp_aux, nomp_aux
				LET int_flag = 0
				IF codp_aux IS NOT NULL THEN
					CALL cargar_proveedor(codp_aux)
					CALL muestra_datos_prov()
				END IF
			END IF
			IF INFIELD(r16_aux_cont) THEN
                	        CALL fl_ayuda_cuenta_contable(vg_codcia,
								vm_nivel)
                        	        RETURNING cod_aux, nom_aux
	                        LET int_flag = 0
        	                IF cod_aux IS NOT NULL THEN
                	                DISPLAY cod_aux TO r16_aux_cont
	                                DISPLAY nom_aux TO tit_aux_con
        	                END IF
	                END IF
			IF INFIELD(r82_partida) THEN
				CALL fl_ayuda_partidas(capitulo)
					RETURNING partida
	                        LET int_flag = 0
				IF partida IS NOT NULL THEN
					DISPLAY partida TO r82_partida
					LET rm_detadu[1].r82_partida =
							get_fldbuf(r82_partida)
					CALL muestra_partida(1)
				END IF
			END IF
		BEFORE CONSTRUCT
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
	END CONSTRUCT
	IF int_flag THEN
		IF vm_row_current > 0 THEN
			CALL muestra_reg_corriente(vm_r_rows[vm_row_current], 1)
		ELSE
			CALL limpiar_pantalla(1)
		END IF
		RETURN
	END IF
ELSE
	LET expr_sql = 'r81_pedido = "', arg_val(5), '"'
END IF
LET query = 'SELECT UNIQUE r81_pedido FROM rept081, rept082 ',
		'WHERE r81_compania  = ', vg_codcia,
		'  AND r81_localidad = ', vg_codloc,
		'  AND ', expr_sql CLIPPED,
		'  AND r82_compania  = r81_compania ',
		'  AND r82_localidad = r81_localidad ',
		'  AND r82_pedido    = r81_pedido '
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO vm_r_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	LET int_flag = 0
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_row_current = 0
	LET vm_num_repd    = 0
	CALL limpiar_pantalla(1)
ELSE  
	LET vm_row_current = 1
	CALL muestra_reg_corriente(vm_r_rows[vm_row_current], 1)
END IF

END FUNCTION



FUNCTION leer_cabecera()
DEFINE resp		CHAR(6)
DEFINE resul, res	SMALLINT
DEFINE flag_ped, i	SMALLINT
DEFINE r_r81		RECORD LIKE rept081.*
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_p01 		RECORD LIKE cxpt001.*
DEFINE r_p02		RECORD LIKE cxpt002.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE codpe_aux	LIKE rept081.r81_pedido
DEFINE codp_aux		LIKE cxpt002.p02_codprov
DEFINE nomp_aux		LIKE cxpt001.p01_nomprov
DEFINE cod_aux		LIKE ctbt010.b10_cuenta
DEFINE nom_aux		LIKE ctbt010.b10_descripcion
DEFINE mone_aux         LIKE gent013.g13_moneda
DEFINE nomm_aux         LIKE gent013.g13_nombre
DEFINE deci_aux         LIKE gent013.g13_decimales
DEFINE paridad		LIKE rept081.r81_paridad_div
DEFINE moneda		LIKE gent013.g13_moneda

INITIALIZE codpe_aux, codp_aux, mone_aux TO NULL
LET flag_ped = 0
LET int_flag = 0
INPUT BY NAME rm_r81.r81_pedido, rm_r81.r81_fecha, rm_r81.r81_moneda_base,
	rm_r81.r81_paridad_div,	rm_r81.r81_cod_prov, rm_r81.r81_nom_prov,
	rm_r81.r81_dir_prov, rm_r81.r81_ciu_prov, rm_r81.r81_est_prov,
	rm_r81.r81_pai_prov, rm_r81.r81_tel_prov, rm_r81.r81_email_prov,
	rm_r81.r81_fax_prov, rm_r16.r16_aux_cont, rm_r81.r81_marcas,
	rm_r81.r81_pagador, rm_r81.r81_forma_pago, rm_r81.r81_pais_origen,
	rm_r81.r81_puerto_ori, rm_r81.r81_puerto_dest, rm_r81.r81_tipo_trans,
	rm_r81.r81_tipo_embal, rm_r81.r81_tipo_fact_pre, rm_r81.r81_tipo_seguro,
	rm_r81.r81_tot_desp_mi, rm_r81.r81_tot_flete, rm_r81.r81_tot_seguro,
	rm_r81.r81_tot_seg_neto, moneda9
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF field_touched(rm_r81.r81_pedido, rm_r81.r81_fecha,
				 rm_r81.r81_moneda_base, rm_r81.r81_paridad_div,
				 rm_r81.r81_cod_prov, rm_r81.r81_nom_prov,
				 rm_r81.r81_dir_prov, rm_r81.r81_ciu_prov,
				 rm_r81.r81_est_prov, rm_r81.r81_pai_prov,
				 rm_r81.r81_tel_prov, rm_r81.r81_email_prov,
				 rm_r81.r81_fax_prov, rm_r16.r16_aux_cont,
				 rm_r81.r81_marcas, rm_r81.r81_pagador,
				 rm_r81.r81_forma_pago, rm_r81.r81_pais_origen,
				 rm_r81.r81_puerto_ori, rm_r81.r81_puerto_dest,
				 rm_r81.r81_tipo_trans, rm_r81.r81_tipo_embal,
				 rm_r81.r81_tipo_fact_pre,
				 rm_r81.r81_tipo_seguro, rm_r81.r81_tot_desp_mi,
				 rm_r81.r81_tot_flete, rm_r81.r81_tot_seguro,
				 rm_r81.r81_tot_seg_neto, moneda9)
		THEN
               		LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
        	        	RETURNING resp
              		IF resp = 'Yes' THEN
				LET int_flag = 1
				{--
				IF vm_r_rows[vm_row_current] IS NULL THEN
					LET vm_num_rows    = 0
					LET vm_row_current = 0
				END IF
				--}
				RETURN
                	END IF
		ELSE
			RETURN
		END IF
	ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(r81_pedido) THEN
			CALL fl_ayuda_pedidos_rep(vg_codcia, vg_codloc, 'T','T')
				RETURNING codpe_aux
			LET int_flag = 0
			IF codpe_aux IS NOT NULL THEN
				LET rm_r81.r81_pedido = codpe_aux
				DISPLAY BY NAME rm_r81.r81_pedido
			END IF
		END IF
		IF INFIELD(r81_cod_prov) THEN
			CALL fl_ayuda_proveedores_localidad(vg_codcia,vg_codloc)
				RETURNING codp_aux, nomp_aux
			LET int_flag = 0
			IF codp_aux IS NOT NULL THEN
				CALL cargar_proveedor(codp_aux)
				CALL muestra_datos_prov()
			END IF
		END IF
		IF INFIELD(r16_aux_cont) THEN
                        CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
                                RETURNING cod_aux, nom_aux
                        LET int_flag = 0
                        IF cod_aux IS NOT NULL THEN
				LET rm_r16.r16_aux_cont = cod_aux
                                DISPLAY BY NAME rm_r16.r16_aux_cont
                                DISPLAY nom_aux TO tit_aux_con
                        END IF
                END IF
		IF INFIELD(r81_moneda_base) THEN
                        CALL fl_ayuda_monedas()
                                RETURNING mone_aux, nomm_aux, deci_aux
                        LET int_flag = 0
                        IF mone_aux IS NOT NULL THEN
				LET rm_r81.r81_moneda_base = mone_aux
				CALL calcula_paridad(rm_r81.r81_moneda_base,
							vm_moneda_ped)
					RETURNING rm_r81.r81_paridad_div
                                DISPLAY BY NAME rm_r81.r81_moneda_base,
						rm_r81.r81_paridad_div
                                DISPLAY nomm_aux TO tit_moneda
                        END IF
                END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD r81_pedido
		IF flag_ped THEN
			NEXT FIELD NEXT
		END IF
		IF rm_r81.r81_pedido IS NOT NULL THEN
			CALL bloquear_pedido(rm_r81.r81_pedido) RETURNING res
			IF res THEN
				LET int_flag = 1
				RETURN
			END IF
			CALL bloquear_nota_pedido(rm_r81.r81_pedido, 0)
				RETURNING res
			IF res THEN
				LET int_flag = 1
				RETURN
			END IF
			LET resul = 2
		END IF
	BEFORE FIELD r81_moneda_base
		IF rm_r81.r81_moneda_base IS NULL THEN
			LET rm_r81.r81_moneda_base = vm_moneda_ped
		ELSE
			LET moneda = rm_r81.r81_moneda_base
		END IF
	BEFORE FIELD r81_paridad_div       
		IF rm_r81.r81_paridad_div <> 1 THEN
			LET paridad = rm_r81.r81_paridad_div
		END IF
	BEFORE FIELD moneda9
		--LET moneda9 = rm_r81.r81_moneda_base
		CALL fl_lee_moneda(vm_moneda_ped) RETURNING r_g13.*
		LET moneda9 = r_g13.g13_simbolo
	AFTER FIELD moneda9
		DISPLAY BY NAME moneda9
	AFTER FIELD r81_pedido
		IF rm_r81.r81_pedido IS NULL THEN
			CALL fl_mostrar_mensaje('Digite un pedido.','exclamation')
			NEXT FIELD r81_pedido
		END IF
		{--
		IF vm_num_rows = 0 THEN
			LET vm_num_rows = 1
		END IF
		IF vm_row_current = 0 THEN
			LET vm_row_current = 1
		END IF
		--}
		CALL fl_lee_nota_pedido_rep(vg_codcia, vg_codloc,
						rm_r81.r81_pedido)
			RETURNING r_r81.*
		IF r_r81.r81_compania IS NULL THEN
			CALL cargar_datos_nota_pedido() RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD r81_pedido
			END IF
			CALL muestra_contadores_det(0)
			CALL muestra_contadores(vm_row_current, vm_num_rows)
			LET flag_ped = 1
		ELSE
			LET resul = 0
			IF vm_num_rows < 1 THEN
				LET vm_row_current = 1
				LET vm_num_rows    = 1
				LET vm_r_rows[vm_row_current] = r_r81.r81_pedido
			END IF
			CALL muestra_reg_corriente(rm_r81.r81_pedido, 1)
		END IF
		DISPLAY rm_r81.r81_pedido TO tit_pedido
		IF vm_estado <> 'A' THEN
			CALL fl_mostrar_mensaje('Pedido no esta ACTIVO.','exclamation')
			LET int_flag = 1
			RETURN
		END IF
		IF resul <> 2 THEN
			CALL bloquear_pedido(rm_r81.r81_pedido) RETURNING res
			IF res THEN
				LET int_flag = 1
				RETURN
			END IF
			CALL bloquear_nota_pedido(rm_r81.r81_pedido, 0)
				RETURNING res
			IF res THEN
				LET int_flag = 1
				RETURN
			END IF
		END IF
	AFTER FIELD r81_fecha
		IF rm_r81.r81_fecha IS NOT NULL THEN
			DISPLAY rm_r81.r81_fecha TO tit_fecha
		END IF
	AFTER FIELD r81_moneda_base
		IF rm_r81.r81_moneda_base IS NOT NULL THEN
                        CALL fl_lee_moneda(rm_r81.r81_moneda_base)
                                RETURNING r_g13.*
                        IF r_g13.g13_moneda IS NULL  THEN
				CALL fl_mostrar_mensaje('Moneda no existe.','exclamation')
                                NEXT FIELD r81_moneda_base
                        END IF
                        DISPLAY r_g13.g13_nombre TO tit_moneda
			CALL muestra_monedas()
                        IF r_g13.g13_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD r81_moneda_base
                        END IF
                ELSE
			IF resul = 2 THEN
				LET rm_r81.r81_moneda_base = moneda
			END IF
                        DISPLAY BY NAME rm_r81.r81_moneda_base
                        CALL fl_lee_moneda(rm_r81.r81_moneda_base) RETURNING r_g13.*
                        DISPLAY r_g13.g13_nombre TO tit_moneda
			CALL muestra_monedas()
                END IF
	AFTER FIELD r81_paridad_div       
		IF rm_r81.r81_paridad_div IS NULL THEN
			LET rm_r81.r81_paridad_div = paridad
			DISPLAY BY NAME rm_r81.r81_paridad_div
		END IF
		CALL calcula_paridad(rm_r81.r81_moneda_base, vm_moneda_ped)
			RETURNING paridad
		IF paridad IS NULL THEN
			NEXT FIELD r81_moneda_base
		END IF
		IF paridad = 1 THEN
			LET rm_r81.r81_paridad_div = paridad
			DISPLAY BY NAME rm_r81.r81_paridad_div
		ELSE
			IF rm_r81.r81_paridad_div = 1 THEN
				DISPLAY paridad TO r81_paridad_div
			END IF
		END IF
		IF rm_r81.r81_paridad_div <> paridad THEN
			LET rm_r81.r81_paridad_div = paridad
		END IF
	AFTER FIELD r81_cod_prov
		IF rm_r81.r81_cod_prov IS NOT NULL THEN
			CALL fl_lee_proveedor_localidad(vg_codcia, vg_codloc,
							rm_r81.r81_cod_prov)
				RETURNING r_p02.*
			IF r_p02.p02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe ese proveedor.','exclamation')
				NEXT FIELD r81_cod_prov
			END IF
			CALL cargar_proveedor(rm_r81.r81_cod_prov)
			CALL muestra_datos_prov()
			CALL fl_lee_proveedor(rm_r81.r81_cod_prov)
				RETURNING r_p01.*
			IF r_p01.p01_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD r81_cod_prov
			END IF
		ELSE
			CALL borra_datos_prov()
		END IF
	AFTER FIELD r16_aux_cont
		IF rm_r16.r16_aux_cont IS NOT NULL THEN
                        CALL fl_lee_cuenta(vg_codcia, rm_r16.r16_aux_cont)
                                RETURNING r_b10.*
                        IF r_b10.b10_cuenta IS NULL THEN
				CALL fl_mostrar_mensaje('Cuenta no existe.','exclamation')
                                NEXT FIELD r16_aux_cont
                        END IF
                        DISPLAY r_b10.b10_descripcion TO tit_aux_con
                        IF r_b10.b10_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD r16_aux_cont
                        END IF
			IF r_b10.b10_nivel <> vm_nivel THEN
				CALL fl_mostrar_mensaje('Nivel de cuenta debe ser solo 6.','info')
                                NEXT FIELD r16_aux_cont
                        END IF
                ELSE
                        CLEAR tit_aux_con
                END IF
	--AFTER FIELD r81_tot_exfab, r81_tot_desp_mi
	AFTER FIELD r81_tot_desp_mi
		IF rm_r81.r81_tot_exfab IS NULL THEN
			LET rm_r81.r81_tot_exfab = 0
		END IF
		IF rm_r81.r81_tot_desp_mi IS NULL THEN
			LET rm_r81.r81_tot_desp_mi = 0
		END IF
		{--
		LET rm_r81.r81_tot_exfab = 
			fl_retorna_precision_valor(rm_r81.r81_moneda_base,
							rm_r81.r81_tot_exfab)
		LET rm_r81.r81_tot_desp_mi = 
				fl_retorna_precision_valor(vm_moneda_ped,
							rm_r81.r81_tot_desp_mi)
		--}
		DISPLAY BY NAME rm_r81.r81_tot_exfab, rm_r81.r81_tot_desp_mi
		CALL calcular_totales_cab()
	AFTER FIELD r81_tot_flete
		IF rm_r81.r81_tot_flete IS NULL THEN
			LET rm_r81.r81_tot_flete = 0
		END IF
		{--
		LET rm_r81.r81_tot_flete = 
			fl_retorna_precision_valor(rm_r81.r81_moneda_base,
							rm_r81.r81_tot_flete)
		--}
		DISPLAY BY NAME rm_r81.r81_tot_flete
		CALL calcular_totales_cab()
	AFTER FIELD r81_tot_seguro
		IF rm_r81.r81_tot_seguro IS NULL THEN
			LET rm_r81.r81_tot_seguro = 0
		END IF
		{--
		LET rm_r81.r81_tot_seguro = 
			fl_retorna_precision_valor(rm_r81.r81_moneda_base,
							rm_r81.r81_tot_seguro)
		--}
		DISPLAY BY NAME rm_r81.r81_tot_seguro
		CALL calcular_totales_cab()
	AFTER FIELD r81_tot_seg_neto
		IF rm_r81.r81_tot_seg_neto IS NULL THEN
			LET rm_r81.r81_tot_seg_neto = 0
		END IF
		{--
		LET rm_r81.r81_tot_seg_neto =
			fl_retorna_precision_valor(rm_r81.r81_moneda_base,
							rm_r81.r81_tot_seg_neto)
		--}
		DISPLAY BY NAME rm_r81.r81_tot_seg_neto
		CALL calcular_totales_cab()
	AFTER INPUT
		CALL calcular_totales_cab()
		LET vm_flag_grabar = 0
END INPUT

END FUNCTION



FUNCTION cargar_datos_default()

LET vm_estado                = 'A'
LET vm_moneda_ped	     = rg_gen.g00_moneda_base
LET rm_r81.r81_compania      = vg_codcia
LET rm_r81.r81_localidad     = vg_codloc
LET rm_r81.r81_moneda_base   = rg_gen.g00_moneda_base
CALL cargar_moneda()
LET rm_r81.r81_tot_exfab     = 0
LET rm_r81.r81_tot_desp_mi   = 0
LET rm_r81.r81_tot_fob_mi    = 0
LET rm_r81.r81_tot_fob_mb    = 0
LET rm_r81.r81_tot_flete     = 0
LET rm_r81.r81_tot_car_fle   = 0
LET rm_r81.r81_tot_seguro    = 0
LET rm_r81.r81_tot_seg_neto  = 0
LET rm_r81.r81_tot_cargos_mb = 0
LET rm_r81.r81_usuario       = vg_usuario
LET rm_r81.r81_fecing        = CURRENT
CALL muestra_nota_ped()

END FUNCTION



FUNCTION cargar_datos_nota_pedido()
DEFINE r_r16		RECORD LIKE rept016.*
DEFINE r_r17		RECORD LIKE rept017.*
DEFINE i		SMALLINT
DEFINE resp             CHAR(6)

CALL fl_lee_pedido_rep(vg_codcia, vg_codloc, rm_r81.r81_pedido)
	RETURNING r_r16.*
IF r_r16.r16_pedido IS NULL THEN
	CALL fl_hacer_pregunta('Este pedido no existe. Desea crearlo?','Yes')
		RETURNING resp
	IF resp = 'Yes' THEN
		CALL cargar_datos_default()
		RETURN 2
	END IF
	LET int_flag = 0
	RETURN 1
END IF
CALL iniciar_vars()
CALL cargar_datos_default()
LET vm_estado = r_r16.r16_estado
IF vm_estado <> 'A' THEN
	CALL fl_mostrar_mensaje('Pedido no esta ACTIVO.','exclamation')
	RETURN 1
END IF
LET vm_moneda_ped	     = r_r16.r16_moneda
IF vm_moneda_ped <> rg_gen.g00_moneda_base THEN
	LET vm_moneda_ped = rg_gen.g00_moneda_base
END IF
LET rm_r81.r81_compania      = r_r16.r16_compania
LET rm_r81.r81_localidad     = r_r16.r16_localidad
LET rm_r81.r81_pedido        = r_r16.r16_pedido
LET rm_r81.r81_moneda_base   = r_r16.r16_moneda
CALL cargar_moneda()
CALL cargar_proveedor(r_r16.r16_proveedor)
LET rm_r82.r82_compania      = rm_r81.r81_compania
LET rm_r82.r82_localidad     = rm_r81.r81_localidad
LET rm_r82.r82_pedido        = rm_r81.r81_pedido
LET rm_r82.r82_porc_arancel  = 0
LET rm_r82.r82_porc_salvagu  = 0
DECLARE q_r17 CURSOR FOR
	SELECT * FROM rept017
		WHERE r17_compania  = r_r16.r16_compania
		  AND r17_localidad = r_r16.r16_localidad
		  AND r17_pedido    = r_r16.r16_pedido
LET vm_num_repd = 1
FOREACH q_r17 INTO r_r17.*
	CALL carga_datos_item(r_r17.r17_item, vm_num_repd, 0, 0)
	LET rm_detadu[vm_num_repd].r82_cantidad    = r_r17.r17_cantped
	LET rm_detadu[vm_num_repd].r82_peso_item   = r_r17.r17_peso
	LET rm_detadu[vm_num_repd].r82_prec_exfab  = r_r17.r17_fob
--OJO
--	LET rm_detadu[vm_num_repd].r82_prec_fob_mi = r_r17.r17_tot_fob_mi
--	LET rm_detadu[vm_num_repd].r82_prec_fob_mb = r_r17.r17_tot_fob_mb
	CALL calcular_datos_item(vm_num_repd, 0, 0)
	LET rm_detadu_aux[vm_num_repd].* = rm_detadu[vm_num_repd].*
	LET vm_num_repd = vm_num_repd + 1
        IF vm_num_repd > vm_max_elm THEN
		CALL fl_mensaje_arreglo_incompleto()
		EXIT PROGRAM
        END IF
END FOREACH
LET vm_num_repd = vm_num_repd - 1
CALL calcular_datos_item2(vm_num_repd)
CALL muestra_lineas_detalle()
CALL calcular_totales_det()
CALL muestra_nota_ped()
RETURN 0

END FUNCTION



FUNCTION carga_datos_item(item, i, j, flag)
DEFINE item		LIKE rept010.r10_codigo
DEFINE i, j, flag	SMALLINT
DEFINE r_r10		RECORD LIKE rept010.*

CALL fl_lee_item(vg_codcia, item) RETURNING r_r10.*
IF NOT flag THEN
	LET rm_detadu[i].r82_partida = r_r10.r10_partida
END IF
LET rm_detadu[i].r82_item          = r_r10.r10_codigo
LET rm_detadu[i].r82_cod_item_prov = r_r10.r10_cod_comerc
IF r_r10.r10_cod_comerc IS NULL THEN
	LET rm_detadu[i].r82_cod_item_prov = '.'
END IF
LET rm_detadu[i].r82_descripcion = r_r10.r10_modelo
LET rm_detadu[i].r82_cod_unid    = r_r10.r10_uni_med
LET rm_detadu[i].r82_peso_item   = r_r10.r10_peso
LET rm_detadu[i].r82_cantidad    = 0
LET rm_detadu[i].r82_peso_item   = r_r10.r10_peso
LET rm_detadu[i].r82_prec_exfab  = r_r10.r10_fob
--LET rm_detadu[i].r82_prec_fob_mi = 0
--LET rm_detadu[i].r82_prec_fob_mb = 0
CALL calcular_datos_item(i, j, flag)
LET rm_detadu_aux[i].* = rm_detadu[i].*
IF flag THEN
	DISPLAY rm_detadu[i].r82_cod_item_prov TO
		rm_detadu[j].r82_cod_item_prov
	DISPLAY rm_detadu[i].r82_cod_unid      TO
		rm_detadu[j].r82_cod_unid
	DISPLAY rm_detadu[i].r82_peso_item     TO
		rm_detadu[j].r82_peso_item
	DISPLAY rm_detadu[i].r82_descripcion   TO
		rm_detadu[j].r82_descripcion
	DISPLAY rm_detadu[i].r82_cantidad      TO
		rm_detadu[j].r82_cantidad
	DISPLAY rm_detadu[i].r82_peso_item     TO
		rm_detadu[j].r82_peso_item
	DISPLAY rm_detadu[i].r82_prec_exfab    TO
		rm_detadu[j].r82_prec_exfab
--	DISPLAY rm_detadu[i].r82_prec_fob_mi   TO
--		rm_detadu[j].r82_prec_fob_mi
--	DISPLAY rm_detadu[i].r82_prec_fob_mb   TO
--		rm_detadu[j].r82_prec_fob_mb
END IF

END FUNCTION



FUNCTION calcular_datos_item2(num)
DEFINE i, num		SMALLINT

LET rm_r81.r81_tot_exfab  = 0
--LET rm_r81.r81_tot_fob_mi = 0
--LET rm_r81.r81_tot_fob_mb = 0
--OJO
FOR i = 1 TO num
	LET rm_r81.r81_tot_exfab  = rm_r81.r81_tot_exfab +
				     rm_detadu[i].total_fob
	{--
--	LET rm_r81.r81_tot_fob_mi = rm_r81.r81_tot_fob_mi +
-- 				     rm_detadu[i].r82_prec_fob_mi
--	LET rm_r81.r81_tot_fob_mb = rm_r81.r81_tot_fob_mb +
-- 				     rm_detadu[i].r82_prec_fob_mb
	--}
END FOR
CALL calcular_totales_fob()

END FUNCTION



FUNCTION cargar_moneda()
DEFINE r_g13		RECORD LIKE gent013.*

CALL fl_lee_moneda(rm_r81.r81_moneda_base) RETURNING r_g13.*
IF r_g13.g13_moneda IS NULL THEN
	CALL fl_mostrar_mensaje('Moneda no existe.','stop')
	EXIT PROGRAM
END IF
DISPLAY r_g13.g13_nombre TO tit_moneda
CALL muestra_monedas()
CALL calcula_paridad(rm_r81.r81_moneda_base, vm_moneda_ped)
	RETURNING rm_r81.r81_paridad_div
IF rm_r81.r81_paridad_div IS NULL THEN
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION cargar_proveedor(proveedor)
DEFINE proveedor	LIKE cxpt001.p01_codprov
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_g30		RECORD LIKE gent030.*
DEFINE r_g31		RECORD LIKE gent031.*

LET rm_r81.r81_cod_prov = proveedor
CALL fl_lee_proveedor(rm_r81.r81_cod_prov) RETURNING r_p01.*
LET rm_r81.r81_nom_prov = r_p01.p01_nomprov
LET rm_r81.r81_dir_prov = r_p01.p01_direccion1
CALL fl_lee_ciudad(r_p01.p01_ciudad) RETURNING r_g31.*
LET rm_r81.r81_ciu_prov = r_g31.g31_nombre
CALL fl_lee_pais(r_p01.p01_pais) RETURNING r_g30.*
LET rm_r81.r81_pai_prov = r_g30.g30_nombre
IF rm_r81.r81_tel_prov IS NULL THEN
	LET rm_r81.r81_tel_prov = r_p01.p01_telefono1
END IF
IF rm_r81.r81_fax_prov IS NULL THEN
	IF r_p01.p01_fax1 IS NOT NULL THEN
		LET rm_r81.r81_fax_prov = r_p01.p01_fax1
	END IF
END IF
IF rm_r81.r81_pais_origen IS NULL THEN
	LET rm_r81.r81_pais_origen = r_g30.g30_nombre
END IF

END FUNCTION



FUNCTION muestra_datos_prov()

DISPLAY BY NAME rm_r81.r81_cod_prov, rm_r81.r81_nom_prov, rm_r81.r81_dir_prov,
		rm_r81.r81_ciu_prov, rm_r81.r81_pai_prov, rm_r81.r81_tel_prov,
		rm_r81.r81_fax_prov, rm_r81.r81_pais_origen
DISPLAY rm_r81.r81_nom_prov TO tit_proveedor

END FUNCTION



FUNCTION borra_datos_prov()

INITIALIZE rm_r81.r81_cod_prov, rm_r81.r81_nom_prov, rm_r81.r81_dir_prov,
	rm_r81.r81_ciu_prov, rm_r81.r81_pai_prov, rm_r81.r81_tel_prov,
	rm_r81.r81_fax_prov TO NULL
CLEAR tit_proveedor, r81_cod_prov, r81_nom_prov, r81_dir_prov, r81_ciu_prov,
	r81_pai_prov, r81_tel_prov, r81_fax_prov

END FUNCTION



FUNCTION calcula_paridad(moneda_ori, moneda_dest)
DEFINE moneda_ori	LIKE rept081.r81_moneda_base
DEFINE moneda_dest	LIKE rept016.r16_moneda
DEFINE r_g14		RECORD LIKE gent014.*

IF moneda_ori = moneda_dest THEN
	IF moneda_ori = rg_gen.g00_moneda_base THEN
		RETURN 1
	END IF
	LET moneda_dest = rg_gen.g00_moneda_base
END IF
CALL fl_lee_factor_moneda(moneda_ori, moneda_dest) RETURNING r_g14.*
IF r_g14.g14_serial IS NULL THEN
	CALL fl_mostrar_mensaje('No existe factor de conversión para esta moneda.','exclamation')
END IF
RETURN r_g14.g14_tasa 

END FUNCTION



FUNCTION leer_detalle()
DEFINE resp             CHAR(6)
DEFINE i,j,l,k		SMALLINT
DEFINE aux_j, aux_i	SMALLINT
DEFINE r_g16		RECORD LIKE gent016.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r82		RECORD LIKE rept082.*
DEFINE r_r05		RECORD LIKE rept005.*
DEFINE stock		LIKE rept022.r22_cantidad 
DEFINE partida		LIKE gent016.g16_partida
DEFINE partida2		LIKE gent016.g16_partida
DEFINE capitulo		LIKE gent016.g16_capitulo
DEFINE salir		SMALLINT
DEFINE in_array		SMALLINT
DEFINE mensaje		VARCHAR(100)

INITIALIZE r_r82.*, capitulo TO NULL
LET i        = 1
LET in_array = 0
LET salir    = 0
WHILE NOT salir
	CALL set_count(vm_num_repd)
	LET int_flag = 0
	INPUT ARRAY rm_detadu WITHOUT DEFAULTS FROM rm_detadu.*
		ON KEY(INTERRUPT)
			LET int_flag = 0
        	     	CALL fl_mensaje_abandonar_proceso()
	        	       	RETURNING resp
	       		IF resp = 'Yes' THEN
				LET vm_num_repd = vm_num_repd_aux
				FOR l = 1 TO vm_num_repd
					LET rm_detadu[l].* = rm_detadu_aux[l].*
				END FOR
				CALL muestra_lineas_detalle()
				CALL muestra_contadores_det(0)
 	      			LET int_flag = 1
				{--
				IF vm_r_rows[vm_row_current] IS NULL THEN
					LET vm_num_rows    = 0
					LET vm_row_current = 0
				END IF
				--}
				EXIT WHILE
	       	       	END IF	
		ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
		ON KEY(F2)
			IF INFIELD(r82_partida) THEN
				CALL fl_ayuda_partidas(capitulo)
					RETURNING partida
	                        LET int_flag = 0
				IF partida IS NOT NULL THEN
                                CALL fl_lee_partida(partida)
                                        RETURNING r_g16.*
					LET partida2 = partida,'-',r_g16.g16_nacional,'-',r_g16.g16_verifcador
--
					LET rm_detadu[i].r82_partida = partida2
					DISPLAY rm_detadu[i].r82_partida TO
						rm_detadu[j].r82_partida 
					LET rm_detadu[i].r82_partida = partida 
				END IF
			END IF
			IF INFIELD(r82_item) THEN
	               		CALL fl_ayuda_maestro_items_stock(vg_codcia,
						vm_grupo_linea,r_r11.r11_bodega)
                     		RETURNING r_r10.r10_codigo, r_r10.r10_nombre,
					  r_r10.r10_linea, r_r10.r10_precio_mb,
					  r_r11.r11_bodega, stock         
				LET int_flag = 0
				IF r_r10.r10_codigo IS NOT NULL THEN
					LET rm_detadu[i].r82_item =
						r_r10.r10_codigo
					DISPLAY r_r10.r10_codigo TO
						rm_detadu[j].r82_item 
					CALL carga_datos_item(r_r10.r10_codigo,
								i, j, 1)
				END IF
			END IF
			IF INFIELD(r82_cod_unid) THEN
				CALL fl_ayuda_unidad_medida()
					RETURNING r_r05.r05_codigo,
						  r_r05.r05_siglas
				LET int_flag = 0
				IF r_r05.r05_codigo IS NOT NULL THEN
					LET rm_detadu[i].r82_cod_unid =
								r_r05.r05_codigo
					DISPLAY rm_detadu[i].r82_cod_unid TO
						rm_detadu[j].r82_cod_unid
				END IF
			END IF
		ON KEY(F5)
			LET i = arr_curr()
			CALL control_subtitulos(rm_detadu[i].r82_item)
			LET int_flag = 0
		ON KEY(F6)
			LET i = arr_curr()
			CALL ver_item(i)
			LET int_flag = 0
		ON KEY(F7)
			LET i = arr_curr()
			CALL ver_partida(i)
			LET int_flag = 0
		BEFORE INPUT
			CALL retorna_tam_arr()
			LET vm_scr_lin = vm_size_arr
			IF in_array THEN
				--#CALL dialog.setcurrline(j, k)
			END IF
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		BEFORE ROW
	       		LET i = arr_curr()
	       		LET j = scr_line()
	       		LET vm_num_repd = arr_count()
			CALL calcular_totales_det()
			CALL muestra_contadores_det(i)
			CALL muestra_partida(i)
		BEFORE FIELD r82_item
			LET r_r82.r82_item = rm_detadu[i].r82_item
		AFTER FIELD r82_partida
			IF rm_detadu[i].r82_partida IS NOT NULL THEN
				CALL fl_lee_partida(rm_detadu[i].r82_partida)
					RETURNING r_g16.*
				IF r_g16.g16_partida IS NULL THEN
					CALL fl_mostrar_mensaje('Partida no existe.','exclamation')
					NEXT FIELD r82_partida
				END IF
				CALL muestra_partida(i)
			ELSE
				CLEAR tit_partida, g16_desc_par
			END IF
		AFTER FIELD r82_item
			IF rm_detadu[i].r82_item IS NOT NULL THEN
				CALL fl_lee_item(vg_codcia,
						rm_detadu[i].r82_item)
					RETURNING r_r10.*
				IF r_r10.r10_compania IS NULL THEN
					CALL fl_mostrar_mensaje('No existe Item.','exclamation')
					NEXT FIELD r82_item
				END IF
				IF r_r10.r10_estado = 'B' THEN
					CALL fl_mensaje_estado_bloqueado()
					NEXT FIELD r82_item
				END IF
				FOR k = 1 TO arr_count()
					IF  rm_detadu[i].r82_item =
					    rm_detadu[k].r82_item AND 
					    i <> k
					THEN
						LET mensaje = 'El item ya fue ingresado en la posicion ' || k || ', desea ir a esa posición?'
						CALL fl_hacer_pregunta(mensaje, 'Yes')
							RETURNING resp	
						IF resp = 'Yes' THEN
						      INITIALIZE rm_detadu[i].*
								TO NULL
							LET i = arr_count() - 1	
							LET vm_num_repd	= i 
							LET in_array = 1
							EXIT INPUT
						END IF
						CALL fl_mostrar_mensaje('No puede ingresar items repetidos.','exclamation')
						NEXT FIELD r82_item
	               			END IF
				END FOR
				IF r_r10.r10_costo_mb <= 0.01 AND
				   fl_item_tiene_movimientos(r_r10.r10_compania,
							r_r10.r10_codigo)
				THEN
					CALL fl_mostrar_mensaje('Debe estar configurado correctamente el costo del item y NO con costo menor igual a 0.01.', 'exclamation')
					NEXT FIELD r82_item
				END IF
			ELSE
				LET rm_detadu[i].r82_item = r_r82.r82_item
				DISPLAY rm_detadu[i].r82_item TO
					rm_detadu[j].r82_item
			END IF
			IF rm_detadu[i].r82_item <> r_r82.r82_item OR
			   r_r82.r82_item IS NULL
			THEN
				CALL carga_datos_item(rm_detadu[i].r82_item, i,
							j, 1)
			END IF
		AFTER FIELD r82_cod_unid
			IF rm_detadu[i].r82_cod_unid IS NOT NULL THEN
				CALL fl_lee_unidad_medida(
						rm_detadu[i].r82_cod_unid)
                                	RETURNING r_r05.*
				IF r_r05.r05_codigo IS NULL THEN
					CALL fl_mostrar_mensaje('La Unidad de Medida no existe en la compañía.','exclamation')
					NEXT FIELD r82_cod_unid
				END IF
			END IF
		AFTER FIELD r82_cantidad, r82_peso_item, r82_prec_exfab
			CALL calcular_datos_item(i, j, 1)
			CALL calcular_totales_det()
		AFTER DELETE
			LET vm_num_repd = arr_count()
			CALL calcular_totales_det()
		AFTER INPUT
			LET vm_num_repd = arr_count()
			IF vm_num_repd = 0 THEN
				CALL fl_mostrar_mensaje('Escriba algo en el detalle.','exclamation')
				NEXT FIELD r82_item
			END IF
			LET vm_flag_grabar = 0
			CALL calcular_totales_det()
			LET vm_num_repd_aux = vm_num_repd
			FOR l = 1 TO vm_num_repd
				WHENEVER ERROR CONTINUE
				DECLARE q_r10 CURSOR FOR
					SELECT * FROM rept010
						WHERE r10_compania = vg_codcia
						  AND r10_codigo   =
							rm_detadu[l].r82_item
				FOR UPDATE
				OPEN q_r10
				FETCH q_r10 INTO r_r10.*
				IF STATUS < 0 THEN
					CALL fl_mostrar_mensaje('El Item ' || rm_detadu[l].r82_item CLIPPED || ' esta bloqueado por otro usuario.','exclamation')
					WHENEVER ERROR STOP
					CLOSE q_r10
					FREE q_r10
					CONTINUE INPUT
				END IF
				WHENEVER ERROR STOP
				UPDATE rept010 SET r10_peso       =
						rm_detadu[l].r82_peso_item,
					           r10_uni_med    =
						rm_detadu[l].r82_cod_unid,
					   	   r10_partida    =
						rm_detadu[l].r82_partida,
					   	   r10_cod_comerc = 
						rm_detadu[l].r82_cod_item_prov,
			-- SE EXCLUYO EL 12/MAR/2008
			   	   --r10_modelo = rm_detadu[l].r82_descripcion,
						   r10_fob    =
						rm_detadu[l].r82_prec_exfab,
						   r10_usu_cosrepo = vg_usuario,
						   r10_fec_cosrepo = CURRENT
					WHERE CURRENT OF q_r10
				CLOSE q_r10
				FREE q_r10
				LET rm_detadu_aux[l].* = rm_detadu[l].*
			END FOR
			CALL calcular_totales_cab()
			IF NOT valido_item_sin_partida(arr_count()) THEN
				CONTINUE INPUT
			END IF
			LET salir = 1
	END INPUT
END WHILE
LET vm_num_repd = arr_count()
RETURN

END FUNCTION



FUNCTION valido_item_sin_partida(max_row)
DEFINE max_row		INTEGER
DEFINE contar, i	INTEGER
DEFINE mens_ite		VARCHAR(200)
DEFINE mensaje		VARCHAR(300)
DEFINE palabra		CHAR(6)

LET mens_ite = NULL
LET contar   = 0
FOR i = 1 TO max_row
	IF rm_detadu[i].r82_partida = '0000.00.00.00' OR
	   rm_detadu[i].r82_partida = '0'
	THEN
		LET mens_ite = mens_ite, ' ', rm_detadu[i].r82_item CLIPPED
		LET contar   = contar + 1
	END IF
END FOR
IF contar = 0 THEN
	RETURN 1
END IF
LET mensaje = 'Los Items: '
LET palabra = 'tienen'
IF contar = 1 THEN
	LET mensaje = 'El Item: '
	LET palabra = 'tiene'
END IF
LET mensaje = mensaje CLIPPED, mens_ite CLIPPED, ', no ', palabra CLIPPED,
		' ninguna partida asignada.'
CALL fl_mostrar_mensaje(mensaje, 'exclamation')
RETURN 0

END FUNCTION



FUNCTION calcular_totales_fob()

LET rm_r81.r81_tot_fob_mi   = rm_r81.r81_tot_exfab   + rm_r81.r81_tot_desp_mi
{--
LET rm_r81.r81_tot_fob_mi   = fl_retorna_precision_valor(vm_moneda_ped,
							rm_r81.r81_tot_fob_mi)
--}
--LET rm_r81.r81_tot_fob_mb   = rm_r81.r81_tot_fob_mi  / rm_r81.r81_paridad_div
LET rm_r81.r81_tot_fob_mb   = rm_r81.r81_tot_fob_mi  * rm_r81.r81_paridad_div
{--
LET rm_r81.r81_tot_fob_mb   = fl_retorna_precision_valor(rm_r81.r81_moneda_base,
							rm_r81.r81_tot_fob_mb)
--}
DISPLAY BY NAME rm_r81.r81_tot_exfab,rm_r81.r81_tot_fob_mi,rm_r81.r81_tot_fob_mb

END FUNCTION



FUNCTION calcular_totales_cab()

CALL calcular_totales_fob()
--LET rm_r81.r81_tot_car_fle  = rm_r81.r81_tot_fob_mi  + rm_r81.r81_tot_flete
LET rm_r81.r81_tot_car_fle  = rm_r81.r81_tot_fob_mb  + rm_r81.r81_tot_flete
{--
LET rm_r81.r81_tot_car_fle  = fl_retorna_precision_valor(rm_r81.r81_moneda_base,
							rm_r81.r81_tot_car_fle)
--}
LET rm_r81.r81_tot_cargos_mb= rm_r81.r81_tot_car_fle + rm_r81.r81_tot_seguro
{--
LET rm_r81.r81_tot_cargos_mb= fl_retorna_precision_valor(rm_r81.r81_moneda_base,
					     	       rm_r81.r81_tot_cargos_mb)
--}
DISPLAY BY NAME rm_r81.r81_tot_fob_mi, rm_r81.r81_tot_fob_mb,
		rm_r81.r81_tot_car_fle, rm_r81.r81_tot_cargos_mb
CALL mostrar_campo_nuevos_valor()

END FUNCTION



FUNCTION calcular_totales_det()
DEFINE i		SMALLINT

LET vm_total_cant   = 0
LET vm_total_pesgen = 0
LET vm_total_fobgen = 0
FOR i = 1 TO vm_num_repd
	IF rm_detadu[i].r82_cantidad IS NOT NULL THEN
		LET vm_total_cant   = vm_total_cant  + rm_detadu[i].r82_cantidad
	END IF
	IF rm_detadu[i].total_peso IS NOT NULL THEN
		LET vm_total_pesgen = vm_total_pesgen + rm_detadu[i].total_peso
	END IF
	IF rm_detadu[i].total_fob IS NOT NULL THEN
		LET vm_total_fobgen = vm_total_fobgen + rm_detadu[i].total_fob
	END IF
END FOR
DISPLAY BY NAME vm_total_cant, vm_total_pesgen, vm_total_fobgen
CALL calcular_datos_item2(vm_num_repd)

END FUNCTION



FUNCTION muestra_reg_corriente(registro, flag)
DEFINE registro		LIKE rept081.r81_pedido
DEFINE flag		SMALLINT

CALL mostrar_registro(registro)
IF flag THEN
	CALL muestra_contadores_det(0)
	CALL muestra_contadores(vm_row_current, vm_num_rows)
END IF

END FUNCTION



FUNCTION muestra_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
        LET vm_row_current = vm_row_current + 1
END IF
CALL muestra_reg_corriente(vm_r_rows[vm_row_current], 1)

END FUNCTION



FUNCTION muestra_anterior_registro()

IF vm_row_current > 1 THEN
        LET vm_row_current = vm_row_current - 1
END IF
CALL muestra_reg_corriente(vm_r_rows[vm_row_current], 1)

END FUNCTION
                                                                                
                                                                                
                                                                                
FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current      SMALLINT
DEFINE num_rows         SMALLINT

IF vg_gui = 1 THEN
	DISPLAY row_current TO vm_row_current3
	DISPLAY num_rows    TO vm_num_rows3
	DISPLAY row_current TO vm_row_current2
	DISPLAY num_rows    TO vm_num_rows2
	DISPLAY row_current TO vm_row_current1
	DISPLAY num_rows    TO vm_num_rows1
	CLEAR r81_pedido
	DISPLAY ' ' TO r81_pedido
	DISPLAY BY NAME rm_r81.r81_pedido
END IF
                                                                                
END FUNCTION



FUNCTION muestra_contadores_det(cor)
DEFINE cor              SMALLINT

IF vg_gui = 1 THEN
	DISPLAY cor         TO vm_row_current4
	DISPLAY vm_num_repd TO vm_num_rows4
END IF

END FUNCTION



FUNCTION mostrar_registro(num_reg)
DEFINE num_reg		LIKE rept081.r81_pedido
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_r16		RECORD LIKE rept016.*
DEFINE mensaje		VARCHAR(100)

IF vm_num_rows < 1 THEN
	RETURN
END IF
DECLARE q_dt CURSOR FOR
	SELECT * FROM rept081, rept082
		WHERE r81_compania  = vg_codcia
		  AND r81_localidad = vg_codloc
		  AND r81_pedido    = num_reg
		  AND r82_compania  = r81_compania
		  AND r82_localidad = r81_localidad
		  AND r82_pedido    = r81_pedido
OPEN q_dt
FETCH q_dt INTO rm_r81.*
IF STATUS = NOTFOUND THEN
	LET mensaje ='No existe registro con índice: ', vm_row_current
	CALL fl_mostrar_mensaje(mensaje, 'exclamation')
	RETURN
END IF	
CALL muestra_nota_ped()
CALL fl_lee_pedido_rep(vg_codcia, vg_codloc, rm_r81.r81_pedido)
	RETURNING r_r16.*
LET vm_estado           = r_r16.r16_estado
LET rm_r16.r16_aux_cont = r_r16.r16_aux_cont
CALL fl_lee_cuenta(vg_codcia, rm_r16.r16_aux_cont) RETURNING r_b10.*
DISPLAY BY NAME rm_r16.r16_aux_cont
DISPLAY r_b10.b10_descripcion TO tit_aux_con
LET vm_moneda_ped       = r_r16.r16_moneda
IF vm_moneda_ped <> rg_gen.g00_moneda_base THEN
	LET vm_moneda_ped = rg_gen.g00_moneda_base
END IF
CALL fl_lee_moneda(rm_r81.r81_moneda_base) RETURNING r_g13.*
DISPLAY r_g13.g13_nombre TO tit_moneda
CALL muestra_monedas()
CALL muestra_detalle(num_reg)

END FUNCTION



FUNCTION muestra_nota_ped()

DISPLAY BY NAME rm_r81.r81_pedido, rm_r81.r81_fecha, rm_r81.r81_moneda_base,
		rm_r81.r81_paridad_div, rm_r81.r81_cod_prov,rm_r81.r81_nom_prov,
		rm_r81.r81_dir_prov, rm_r81.r81_ciu_prov, rm_r81.r81_est_prov,
		rm_r81.r81_pai_prov, rm_r81.r81_tel_prov, rm_r81.r81_email_prov,
		rm_r81.r81_fax_prov, rm_r81.r81_marcas, rm_r81.r81_pagador,
		rm_r81.r81_forma_pago, rm_r81.r81_pais_origen,
		rm_r81.r81_puerto_ori, rm_r81.r81_puerto_dest,
		rm_r81.r81_tipo_trans, rm_r81.r81_tipo_embal,
		rm_r81.r81_tipo_fact_pre, rm_r81.r81_tipo_seguro,
		rm_r81.r81_tot_exfab, rm_r81.r81_tot_desp_mi,
		rm_r81.r81_tot_fob_mi, rm_r81.r81_tot_fob_mb,
		rm_r81.r81_tot_flete, rm_r81.r81_tot_car_fle,
		rm_r81.r81_tot_seguro, rm_r81.r81_tot_seg_neto,
		rm_r81.r81_tot_cargos_mb, rm_r81.r81_usuario, rm_r81.r81_fecing
DISPLAY rm_r81.r81_pedido   TO tit_pedido
DISPLAY rm_r81.r81_nom_prov TO tit_proveedor
DISPLAY rm_r81.r81_fecha    TO tit_fecha
CALL mostrar_campo_nuevos_valor()

END FUNCTION



FUNCTION muestra_detalle(num_reg)
DEFINE num_reg          LIKE rept081.r81_pedido
DEFINE query            CHAR(1000)
DEFINE i  		SMALLINT
DEFINE r_r82		RECORD LIKE rept082.*
DEFINE orden		INTEGER

CALL retorna_tam_arr()
LET vm_scr_lin = vm_size_arr
LET int_flag = 0
FOR i = 1 TO vm_scr_lin
        INITIALIZE rm_detadu[i].* TO NULL
        CLEAR rm_detadu[i].*
END FOR
LET query = 'SELECT *, rowid FROM rept082 ',
                'WHERE r82_compania  = ', vg_codcia,
		'  AND r82_localidad = ', vg_codloc,
		'  AND r82_pedido    = "', num_reg, '"',
		--'ORDER BY rowid '
		' ORDER BY r82_sec_item '
PREPARE cons1 FROM query
DECLARE q_cons1 CURSOR FOR cons1
LET i = 1
LET vm_num_repd = 0
FOREACH q_cons1 INTO r_r82.*, orden
	LET rm_detadu[i].r82_partida       = r_r82.r82_partida
	LET rm_detadu[i].r82_item	   = r_r82.r82_item
	LET rm_detadu[i].r82_cod_item_prov = r_r82.r82_cod_item_prov
	LET rm_detadu[i].r82_descripcion   = r_r82.r82_descripcion
	LET rm_detadu[i].r82_cod_unid	   = r_r82.r82_cod_unid
	LET rm_detadu[i].r82_cantidad	   = r_r82.r82_cantidad
	LET rm_detadu[i].r82_peso_item	   = r_r82.r82_peso_item
	LET rm_detadu[i].total_peso        = r_r82.r82_cantidad *
						r_r82.r82_peso_item
	LET rm_detadu[i].r82_prec_exfab    = r_r82.r82_prec_exfab
--	LET rm_detadu[i].r82_prec_fob_mi   = r_r82.r82_prec_fob_mi
--	LET rm_detadu[i].r82_prec_fob_mb   = r_r82.r82_prec_fob_mb
	LET rm_detadu[i].total_fob         = r_r82.r82_cantidad *
						r_r82.r82_prec_exfab
	LET rm_detadu_aux[i].* = rm_detadu[i].*
        LET vm_num_repd = vm_num_repd + 1
	LET vm_num_repd_aux = vm_num_repd
        LET i = i + 1
        IF vm_num_repd > vm_max_elm THEN
        	LET vm_num_repd = vm_num_repd - 1
		CALL fl_mensaje_arreglo_incompleto()
		EXIT PROGRAM
        END IF
END FOREACH
IF vm_num_repd > 0 THEN
        LET int_flag = 0
	CALL muestra_contadores_det(0)
	CALL muestra_lineas_detalle()
END IF
CALL calcular_totales_det()
IF int_flag THEN
	INITIALIZE rm_detadu[1].* TO NULL
        RETURN
END IF

END FUNCTION



FUNCTION muestra_lineas_detalle()
DEFINE i		SMALLINT
DEFINE lineas		SMALLINT

CALL retorna_tam_arr()
LET lineas = vm_size_arr
FOR i = 1 TO lineas
	IF i <= vm_num_repd THEN
		DISPLAY rm_detadu[i].* TO rm_detadu[i].*
	ELSE
		CLEAR rm_detadu[i].*
	END IF
END FOR
CALL muestra_partida(1)

END FUNCTION



FUNCTION muestra_detalle_arr()
DEFINE i,j,l,col,resul	SMALLINT
DEFINE query		CHAR(800)
DEFINE r_r81		RECORD LIKE rept081.*
DEFINE r_r82		RECORD LIKE rept082.*

LET col           = 5
LET rm_orden[col] = 'ASC'
LET vm_columna_1  = col
LET vm_columna_2  = 14
WHILE TRUE
	CALL mostrar_botones_detalle()
	LET query = 'SELECT * FROM rept082 ',
	                'WHERE r82_compania  = ', vg_codcia,
			'  AND r82_localidad = ', vg_codloc,
			'  AND r82_pedido    = "', rm_r81.r81_pedido, '"',
			" ORDER BY ", vm_columna_1, ' ', rm_orden[vm_columna_1],
			        ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE det FROM query
	DECLARE q_det CURSOR FOR det
	LET vm_num_repd = 1
        FOREACH q_det INTO r_r82.*
		LET rm_detadu[vm_num_repd].r82_partida = r_r82.r82_partida
		LET rm_detadu[vm_num_repd].r82_item = r_r82.r82_item
		LET rm_detadu[vm_num_repd].r82_cod_item_prov =
							r_r82.r82_cod_item_prov
		LET rm_detadu[vm_num_repd].r82_descripcion =
							r_r82.r82_descripcion
		LET rm_detadu[vm_num_repd].r82_cod_unid	   = r_r82.r82_cod_unid
		LET rm_detadu[vm_num_repd].r82_cantidad	   = r_r82.r82_cantidad
		LET rm_detadu[vm_num_repd].r82_peso_item   = r_r82.r82_peso_item
		LET rm_detadu[vm_num_repd].total_peso = r_r82.r82_cantidad *
							r_r82.r82_peso_item
		LET rm_detadu[vm_num_repd].r82_prec_exfab = r_r82.r82_prec_exfab
-- OJO
--		LET rm_detadu[vm_num_repd].r82_prec_fob_mi =
--							r_r82.r82_prec_fob_mi
--		LET rm_detadu[vm_num_repd].r82_prec_fob_mb =
--							r_r82.r82_prec_fob_mb
		LET rm_detadu[vm_num_repd].total_fob = r_r82.r82_cantidad *
							r_r82.r82_prec_exfab
		LET rm_detadu_aux[vm_num_repd].* = rm_detadu[vm_num_repd].*
                LET vm_num_repd = vm_num_repd + 1
                IF vm_num_repd > vm_max_elm THEN
                        EXIT FOREACH
                END IF
        END FOREACH
        LET vm_num_repd = vm_num_repd - 1
	LET int_flag = 0
	CALL set_count(vm_num_repd)
	CALL retorna_tam_arr()
	LET vm_scr_lin = vm_size_arr
	DISPLAY ARRAY rm_detadu TO rm_detadu.*
		--#BEFORE ROW
			--#LET i = arr_curr()
	        	--#LET j = scr_line()
			--#CALL muestra_contadores_det(i)
			--#CALL muestra_partida(i)
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#IF num_args() = 4 THEN
				--#CALL dialog.keysetlabel("F5","")
			--#ELSE
				--#CALL dialog.keysetlabel("F5","Imprimir")
			--#END IF
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_1() 
		ON KEY(F5)
			IF num_args() = 5 THEN
				CALL imprimir()
				LET int_flag = 0
			END IF
		ON KEY(F6)
			LET i = arr_curr()
			CALL ver_item(i)
			LET int_flag = 0
		ON KEY(F7)
			LET i = arr_curr()
			CALL ver_partida(i)
			LET int_flag = 0
		ON KEY(F15)
			LET col = 4
			EXIT DISPLAY
		ON KEY(F16)
			LET col = 5
			EXIT DISPLAY
		ON KEY(F17)
			LET col = 6
			EXIT DISPLAY
		ON KEY(F18)
			LET col = 7
			EXIT DISPLAY
		ON KEY(F19)
			LET col = 8
			EXIT DISPLAY
		ON KEY(F20)
			LET col = 9
			EXIT DISPLAY
		ON KEY(F21)
			LET col = 10
			EXIT DISPLAY
		ON KEY(F22)
			LET col = 11
			EXIT DISPLAY
		ON KEY(F23)
			LET col = 13
			EXIT DISPLAY
		ON KEY(F24)
			LET col = 14
			EXIT DISPLAY
		ON KEY(F25)
			LET col = 15
			EXIT DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		CALL muestra_contadores_det(0)
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

END FUNCTION



FUNCTION mostrar_botones_detalle()

{
--#DISPLAY 'Item'                  TO tit_col1
--#DISPLAY 'Cod. Item Prov.'       TO tit_col2
--#DISPLAY 'Descripcion Cod. Item' TO tit_col3
--#DISPLAY 'Unidad'                TO tit_col4
--#DISPLAY 'Cantidad'              TO tit_col5
--#DISPLAY 'Peso Uni.'             TO tit_col6
--#DISPLAY 'Total Peso'            TO tit_col7
--#DISPLAY 'EX-FCA DIV.'           TO tit_col8
--#DISPLAY 'FOB DIV.'              TO tit_col9
--#DISPLAY 'FOB BASE'              TO tit_col10
--#DISPLAY 'Total FOB BASE'        TO tit_col11
}

--#DISPLAY 'Partida'               TO tit_col1
--#DISPLAY 'Item'       	   TO tit_col2
--#DISPLAY 'Cod. Item Prov.'       TO tit_col3
--#DISPLAY 'Descripcion Cod. Item' TO tit_col4
--#DISPLAY 'Unidad'                TO tit_col5

--#DISPLAY 'Cantidad'              TO tit_col6
--#DISPLAY 'Peso'             	   TO tit_col7
--#DISPLAY 'Total Peso'            TO tit_col8
--#DISPLAY 'FOB Divisa'            TO tit_col9
--#DISPLAY 'Total FOB'             TO tit_col10

END FUNCTION



FUNCTION control_eliminacion()
DEFINE resp		CHAR(6)
DEFINE resul, i		SMALLINT

IF vm_estado <> 'A' THEN
	CALL fl_mostrar_mensaje('Pedido no esta ACTIVO.','exclamation')
	RETURN
END IF
CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
IF resp = 'Yes' THEN
	BEGIN WORK
		CALL bloquear_nota_pedido(rm_r81.r81_pedido, 1) RETURNING resul
		IF resul THEN
			RETURN
		END IF
		DELETE FROM rept017
			WHERE r17_compania  = vg_codcia  AND 
			      r17_localidad = vg_codloc AND 
			      r17_pedido    = rm_r81.r81_pedido
		DELETE FROM rept018
			WHERE r18_compania  = vg_codcia  AND 
			      r18_localidad = vg_codloc AND 
			      r18_pedido    = rm_r81.r81_pedido
		DELETE FROM rept029
			WHERE r29_compania  = vg_codcia  AND 
			      r29_localidad = vg_codloc AND 
			      r29_pedido    = rm_r81.r81_pedido
		DELETE FROM rept016
			WHERE r16_compania  = vg_codcia  AND 
			      r16_localidad = vg_codloc AND 
			      r16_pedido    = rm_r81.r81_pedido
		DELETE FROM rept082
			WHERE r82_compania  = vg_codcia
			  AND r82_localidad = vg_codloc
			  AND r82_pedido    = rm_r81.r81_pedido
		DELETE FROM rept081 WHERE CURRENT OF q_r81
	COMMIT WORK
	CALL fl_mostrar_mensaje('La nota de pedido ha sido eliminada.','info')
	IF vm_num_rows = 1 THEN
		LET vm_row_current = 0
		LET vm_num_rows    = 0
		CALL limpiar_pantalla(1)
		RETURN
	END IF
	FOR i = vm_row_current TO vm_num_rows - 1
		LET vm_r_rows[i] = vm_r_rows[i + 1]
	END FOR
	LET vm_r_rows[vm_num_rows] = NULL
	LET vm_row_current         = vm_row_current - 1
	LET vm_num_rows            = vm_num_rows    - 1
	CALL muestra_reg_corriente(vm_r_rows[vm_row_current], 1)
END IF
	
END FUNCTION



FUNCTION imprimir()
DEFINE run_prog		CHAR(10)

{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS',
	vg_separador, 'fuentes', vg_separador, run_prog, ' repp433 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ', rm_r81.r81_pedido
RUN vm_nuevoprog

END FUNCTION



FUNCTION ver_item(i)
DEFINE i		SMALLINT
DEFINE run_prog		CHAR(10)

{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS',
	vg_separador, 'fuentes', vg_separador, run_prog, ' repp108 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' "',
	rm_detadu[i].r82_item, '"'
RUN vm_nuevoprog

END FUNCTION



FUNCTION ver_partida(i)
DEFINE i		SMALLINT
DEFINE run_prog		CHAR(10)

{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES',
	vg_separador, 'fuentes', vg_separador, run_prog, ' genp114 ', vg_base,
	' "GE" "', rm_detadu[i].r82_partida, '"'
RUN vm_nuevoprog

END FUNCTION



FUNCTION retorna_tam_arr()

--#LET vm_size_arr = fgl_scr_size('rm_detadu')
IF vg_gui = 0 THEN
	LET vm_size_arr = 4
END IF

END FUNCTION



FUNCTION calcular_datos_item(i, j, flag)
DEFINE i, j, flag	SMALLINT

LET rm_detadu[i].total_peso = rm_detadu[i].r82_cantidad *
			     rm_detadu[i].r82_peso_item
LET rm_detadu[i].total_fob  = rm_detadu[i].r82_cantidad *
			     rm_detadu[i].r82_prec_exfab
IF flag THEN
	DISPLAY rm_detadu[i].total_peso TO rm_detadu[j].total_peso
	DISPLAY rm_detadu[i].total_fob  TO rm_detadu[j].total_fob
END IF

END FUNCTION



FUNCTION muestra_partida(i)
DEFINE i		SMALLINT
DEFINE r_g16		RECORD LIKE gent016.*
DEFINE r_r83		RECORD LIKE rept083.*
DEFINE r_r84		RECORD LIKE rept084.*

CALL fl_lee_partida(rm_detadu[i].r82_partida) RETURNING r_g16.*
DISPLAY rm_detadu[i].r82_partida TO tit_partida
DISPLAY BY NAME r_g16.g16_desc_par
INITIALIZE r_r83.* TO NULL
DECLARE q_rel3 CURSOR FOR
	SELECT * FROM rept083
		WHERE r83_compania = vg_codcia
		  AND r83_item     = rm_detadu[i].r82_item
OPEN q_rel3
FETCH q_rel3 INTO r_r83.*
CALL fl_lee_desc_subtitulo(vg_codcia, r_r83.r83_cod_desc_item) RETURNING r_r84.*
DISPLAY r_r84.r84_descripcion TO sub_titulo

END FUNCTION



FUNCTION muestra_monedas()
DEFINE r_g13		RECORD LIKE gent013.*

{--
DISPLAY rm_r81.r81_moneda_base TO moneda1
DISPLAY rm_r81.r81_moneda_base TO moneda2	-- OJO
--DISPLAY vm_moneda_ped          TO moneda2
DISPLAY rm_r81.r81_moneda_base TO moneda3
DISPLAY vm_moneda_ped          TO moneda4

{--
DISPLAY rm_r81.r81_moneda_base TO moneda5
DISPLAY rm_r81.r81_moneda_base TO moneda6
DISPLAY rm_r81.r81_moneda_base TO moneda7
DISPLAY rm_r81.r81_moneda_base TO moneda8
DISPLAY rm_r81.r81_moneda_base TO moneda9
LET moneda9 = rm_r81.r81_moneda_base
--}

DISPLAY vm_moneda_ped          TO moneda5
DISPLAY vm_moneda_ped          TO moneda6
DISPLAY vm_moneda_ped          TO moneda7
DISPLAY vm_moneda_ped          TO moneda8
DISPLAY vm_moneda_ped          TO moneda9
LET moneda9 = vm_moneda_ped
--}

CALL fl_lee_moneda(rm_r81.r81_moneda_base) RETURNING r_g13.*
DISPLAY r_g13.g13_simbolo TO moneda1
DISPLAY r_g13.g13_simbolo TO moneda2
DISPLAY r_g13.g13_simbolo TO moneda3
DISPLAY r_g13.g13_simbolo TO moneda12
DISPLAY r_g13.g13_simbolo TO moneda13
DISPLAY r_g13.g13_simbolo TO moneda14
DISPLAY r_g13.g13_simbolo TO moneda15
DISPLAY r_g13.g13_simbolo TO moneda16
CALL fl_lee_moneda(vm_moneda_ped) RETURNING r_g13.*
DISPLAY r_g13.g13_simbolo TO moneda10
DISPLAY r_g13.g13_simbolo TO moneda11
DISPLAY r_g13.g13_simbolo TO moneda4
DISPLAY r_g13.g13_simbolo TO moneda5
DISPLAY r_g13.g13_simbolo TO moneda6
DISPLAY r_g13.g13_simbolo TO moneda7
DISPLAY r_g13.g13_simbolo TO moneda8
DISPLAY r_g13.g13_simbolo TO moneda9
LET moneda9 = r_g13.g13_simbolo

END FUNCTION



FUNCTION mostrar_campo_nuevos_valor()

--DISPLAY (rm_r81.r81_tot_exfab / rm_r81.r81_paridad_div)   TO r81_tot_exfab_base
DISPLAY (rm_r81.r81_tot_exfab * rm_r81.r81_paridad_div)   TO r81_tot_exfab_base
--DISPLAY (rm_r81.r81_tot_desp_mi / rm_r81.r81_paridad_div) TO r81_tot_desp_mb
DISPLAY (rm_r81.r81_tot_desp_mi * rm_r81.r81_paridad_div) TO r81_tot_desp_mb
--DISPLAY (rm_r81.r81_tot_flete * rm_r81.r81_paridad_div)   TO r81_tot_flete_mi
DISPLAY (rm_r81.r81_tot_flete / rm_r81.r81_paridad_div)   TO r81_tot_flete_mi
--DISPLAY (rm_r81.r81_tot_car_fle * rm_r81.r81_paridad_div) TO r81_tot_car_fle_mi
DISPLAY (rm_r81.r81_tot_car_fle / rm_r81.r81_paridad_div) TO r81_tot_car_fle_mi
--DISPLAY (rm_r81.r81_tot_seguro * rm_r81.r81_paridad_div)  TO r81_tot_seguro_mi
DISPLAY (rm_r81.r81_tot_seguro / rm_r81.r81_paridad_div)  TO r81_tot_seguro_mi
--DISPLAY (rm_r81.r81_tot_seg_neto * rm_r81.r81_paridad_div)TO r81_tot_seg_neto_mi
DISPLAY (rm_r81.r81_tot_seg_neto / rm_r81.r81_paridad_div)TO r81_tot_seg_neto_mi
--DISPLAY (rm_r81.r81_tot_cargos_mb * rm_r81.r81_paridad_div) TO r81_tot_cargos_mi
DISPLAY (rm_r81.r81_tot_cargos_mb / rm_r81.r81_paridad_div) TO r81_tot_cargos_mi

END FUNCTION



FUNCTION iniciar_vars()
DEFINE i		SMALLINT

INITIALIZE vm_estado, rm_r16.*, rm_r81.*, rm_r82.* TO NULL
FOR i = 1 TO vm_max_elm
	INITIALIZE rm_detadu[i].*, rm_detadu_aux[i].* TO NULL
END FOR

END FUNCTION



FUNCTION limpiar_pantalla(flag)
DEFINE flag		SMALLINT

IF flag THEN
	CALL iniciar_vars()
END IF
CLEAR FORM
CALL mostrar_botones_detalle()
CALL muestra_contadores_det(0)
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION llamar_visor_teclas()
DEFINE a		SMALLINT

IF vg_gui = 0 THEN
	CALL fl_visor_teclas_caracter() RETURNING int_flag 
	LET a = fgl_getkey()
	CLOSE WINDOW w_tf
	LET int_flag = 0
END IF

END FUNCTION



FUNCTION control_visor_teclas_caracter_1() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Imprimir Nota de Pedido'  AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION control_subtitulos(item)
DEFINE item		LIKE rept010.r10_codigo
DEFINE lin_menu		SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

LET lin_menu = 0
LET num_rows = 13
LET num_cols = 62
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET num_rows = 14
	LET num_cols = 63
END IF
OPEN WINDOW w_sub AT 07, 10 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu, BORDER,
		MESSAGE LINE LAST)
IF vg_gui = 1 THEN
	OPEN FORM f_sub FROM "../forms/repf233_2"
ELSE
	OPEN FORM f_sub FROM "../forms/repf233_2c"
END IF
DISPLAY FORM f_sub
INITIALIZE rm_r83.*, rm_r84.* TO NULL
LET rm_r83.r83_item = item
CALL leer_subtitulo()
IF NOT int_flag THEN
	CALL grabar_subtitulo()
END IF
CLOSE WINDOW w_sub

END FUNCTION



FUNCTION leer_subtitulo()
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r83		RECORD LIKE rept083.*
DEFINE r_r84		RECORD LIKE rept084.*

CALL fl_lee_item(vg_codcia, rm_r83.r83_item) RETURNING r_r10.*
DECLARE q_rel CURSOR FOR
	SELECT * FROM rept083
		WHERE r83_compania = vg_codcia
		  AND r83_item     = rm_r83.r83_item
OPEN q_rel
FETCH q_rel INTO rm_r83.*
IF STATUS = NOTFOUND THEN
	CALL retorna_sec() RETURNING rm_r83.r83_cod_desc_item
	LET rm_r84.r84_descripcion = NULL
	LET rm_r84.r84_usuario     = vg_usuario
	LET rm_r84.r84_fecing      = CURRENT
ELSE
	CALL fl_lee_desc_subtitulo(vg_codcia, rm_r83.r83_cod_desc_item)
		RETURNING rm_r84.*
END IF
CLOSE q_rel
FREE q_rel
DISPLAY BY NAME rm_r83.r83_item, r_r10.r10_nombre, rm_r83.r83_cod_desc_item,
		rm_r84.r84_descripcion, rm_r84.r84_usuario, rm_r84.r84_fecing
LET int_flag = 0
INPUT BY NAME rm_r83.r83_cod_desc_item, rm_r84.r84_descripcion
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
	ON KEY(F2)
		IF INFIELD(r83_cod_desc_item) THEN
			CALL fl_ayuda_subtitulos(vg_codcia)
				RETURNING r_r83.r83_cod_desc_item
			LET int_flag = 0
			IF r_r83.r83_cod_desc_item IS NOT NULL THEN
				LET rm_r83.r83_cod_desc_item =
						r_r83.r83_cod_desc_item
				DISPLAY BY NAME rm_r83.r83_cod_desc_item
				CALL fl_lee_desc_subtitulo(vg_codcia,
						r_r83.r83_cod_desc_item)
					RETURNING r_r84.*
				DISPLAY BY NAME r_r84.r84_descripcion
			END IF
		END IF
	AFTER FIELD r83_cod_desc_item
		IF rm_r83.r83_cod_desc_item IS NOT NULL THEN
			CALL fl_lee_desc_subtitulo(vg_codcia,
						rm_r83.r83_cod_desc_item)
				RETURNING r_r84.*
			LET rm_r84.r84_descripcion = r_r84.r84_descripcion
			IF r_r84.r84_compania IS NULL THEN
				CALL retorna_sec()
					RETURNING rm_r83.r83_cod_desc_item
				DISPLAY BY NAME rm_r83.r83_cod_desc_item
				LET rm_r84.r84_descripcion = NULL
			END IF
			DISPLAY BY NAME rm_r84.r84_descripcion
		ELSE
--			CALL retorna_sec() RETURNING rm_r83.r83_cod_desc_item
--			DISPLAY BY NAME rm_r83.r83_cod_desc_item
			LET rm_r84.r84_descripcion = NULL
			CLEAR r84_descripcion
		END IF
	AFTER INPUT
		CALL borrar_subtitulo(rm_r83.r83_item)
		DELETE FROM rept083
			WHERE r83_compania = vg_codcia
			  AND r83_item     = rm_r83.r83_item
		--IF rm_r83.r83_cod_desc_item IS NULL THEN
		IF rm_r84.r84_descripcion IS NULL THEN
			LET int_flag = 1
		END IF
END INPUT

END FUNCTION



FUNCTION retorna_sec()
DEFINE cod_desc_item	LIKE rept084.r84_cod_desc_item

SELECT MAX(r84_cod_desc_item) INTO cod_desc_item
	FROM rept084
	WHERE r84_compania = vg_codcia
IF cod_desc_item IS NULL THEN
	LET cod_desc_item = 1
ELSE
	LET cod_desc_item = cod_desc_item + 1
END IF
RETURN cod_desc_item

END FUNCTION



FUNCTION grabar_subtitulo()
DEFINE r_r83		RECORD LIKE rept083.*
DEFINE r_r84		RECORD LIKE rept084.*
DEFINE act_r84		SMALLINT

DECLARE q_up_r84 CURSOR FOR
	SELECT * FROM rept084
		WHERE r84_compania      = vg_codcia
		  AND r84_cod_desc_item = rm_r83.r83_cod_desc_item
	FOR UPDATE
OPEN q_up_r84
FETCH q_up_r84 INTO r_r84.*
IF STATUS < 0 THEN
	CALL fl_mostrar_mensaje('En este momento no se puede actualizar el subtitulo de este item, esta bloqueado por otro proceso.', 'exclamation')
	CLOSE q_up_r84
	FREE q_up_r84
	RETURN
END IF
LET act_r84 = 1
IF STATUS = NOTFOUND THEN
	LET act_r84 = 0
END IF
DECLARE q_rel2 CURSOR FOR
	SELECT * FROM rept083
		WHERE r83_compania = vg_codcia
		  AND r83_item     = rm_r83.r83_item
	FOR UPDATE
OPEN q_rel2
FETCH q_rel2 INTO r_r83.*
IF STATUS <> NOTFOUND THEN
	DELETE FROM rept083 WHERE CURRENT OF q_rel2
	IF STATUS < 0 THEN
		CALL fl_mostrar_mensaje('No se puede actualizar el subtitulo de este item en la tabla de relacion, ha ocurrido un error de base de datos.', 'exclamation')
		CLOSE q_up_r84
		FREE q_up_r84
		CLOSE q_rel2
		FREE q_rel2
		RETURN
	END IF
END IF
CLOSE q_rel2
FREE q_rel2
LET rm_r83.r83_compania = vg_codcia
INSERT INTO rept083 VALUES(rm_r83.*)
IF act_r84 THEN
	UPDATE rept084 SET r84_descripcion = rm_r84.r84_descripcion
		WHERE CURRENT OF q_up_r84
	IF STATUS < 0 THEN
		CALL fl_mostrar_mensaje('No se puede actualizar el subtitulo de este item, ha ocurrido un error de base de datos.', 'exclamation')
		CLOSE q_up_r84
		FREE q_up_r84
		RETURN
	END IF
ELSE
	LET rm_r84.r84_compania      = vg_codcia
	LET rm_r84.r84_cod_desc_item = rm_r83.r83_cod_desc_item
	LET rm_r84.r84_usuario       = vg_usuario
	LET rm_r84.r84_fecing        = CURRENT
	INSERT INTO rept084 VALUES(rm_r84.*)
END IF
CLOSE q_up_r84
FREE q_up_r84

END FUNCTION



FUNCTION borrar_subtitulo(item)
DEFINE r_r83		RECORD LIKE rept083.*
DEFINE item		LIKE rept083.r83_item

DECLARE q_borra83 CURSOR FOR
	SELECT * FROM rept083
		WHERE r83_compania = vg_codcia
		  AND r83_item     = item
	FOR UPDATE
OPEN q_borra83
FETCH q_borra83 INTO r_r83.*
IF STATUS <> NOTFOUND THEN
	DELETE FROM rept083 WHERE CURRENT OF q_borra83
	IF STATUS < 0 THEN
		CALL fl_mostrar_mensaje('No se puede borrar el subtitulo de este item, ha ocurrido un error de base de datos.', 'exclamation')
		CLOSE q_borra83
		FREE q_borra83
		RETURN
	END IF
END IF
CLOSE q_borra83
FREE q_borra83

END FUNCTION
