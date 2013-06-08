--------------------------------------------------------------------------------
-- Titulo           : repp204.4gl - Mantenimiento de Pedidos
-- Elaboracion      : 07-nov-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp204 base módulo compañía localidad [pedido]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_nuevoprog	CHAR(400)
DEFINE rm_r16		RECORD LIKE rept016.*
DEFINE rm_r17		RECORD LIKE rept017.*
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
DEFINE vm_grabado	SMALLINT 
DEFINE vm_flag_grabar	SMALLINT 
DEFINE vm_flag_mant     CHAR(1)
DEFINE vm_total_gen     DECIMAL(13,4)
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_estado	LIKE rept016.r16_estado
DEFINE vm_r_rows	ARRAY [1000] OF LIKE rept016.r16_pedido
DEFINE rm_repd 		ARRAY [1300] OF RECORD
				r17_item	LIKE rept017.r17_item,
				tit_descripcion	LIKE rept010.r10_nombre,
				r17_cantped	LIKE rept017.r17_cantped,
				r17_fob		LIKE rept017.r17_fob,
				tit_subtotal	DECIMAL(12,4)
			END RECORD
DEFINE rm_repd_aux	ARRAY [1300] OF RECORD
				r17_item	LIKE rept017.r17_item,
				tit_descripcion	LIKE rept010.r10_nombre,
				r17_cantped	LIKE rept017.r17_cantped,
				r17_fob		LIKE rept017.r17_fob,
				tit_subtotal	DECIMAL(12,4)
			END RECORD



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
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
LET vg_proceso = 'repp204'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE i		SMALLINT
DEFINE r_r16		RECORD LIKE rept016.*
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
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
	OPEN FORM f_mas FROM "../forms/repf204_1"
ELSE
	OPEN FORM f_mas FROM "../forms/repf204_1c"
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
FOR i = 1 TO vm_max_elm
	INITIALIZE rm_repd[i].*, rm_repd_aux[i].* TO NULL
END FOR
INITIALIZE rm_r16.*, rm_r17.* TO NULL
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET vm_num_rows     = 0
LET vm_row_current  = 0
LET vm_num_repd     = 0
LET vm_num_repd_aux = 0
LET vm_scr_lin      = 0
LET vm_flag_grabar  = 0
LET vm_flag_mant    = 'N'
LET vm_estado       = 'A'
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_contadores_det(0)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Detalle'
		HIDE OPTION 'Eliminar'
		HIDE OPTION 'Imprimir'
		IF num_args() = 5 THEN
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Consultar'
			LET rm_r16.r16_pedido = arg_val(5)
			CALL fl_lee_pedido_rep(vg_codcia, vg_codloc,
						rm_r16.r16_pedido)
				RETURNING r_r16.*
			--LET vm_estado = r_r16.r16_estado
                	CALL control_consulta()
			IF vm_num_rows > 0 THEN
                		CALL muestra_detalle_arr()
                        END IF
                        EXIT PROGRAM
		END IF
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
                CALL control_ingreso()
                IF vm_num_rows >= 1 THEN
                        SHOW OPTION 'Modificar'
                        SHOW OPTION 'Detalle'
			SHOW OPTION 'Eliminar'
                END IF
                IF vm_row_current > 1 THEN
                        SHOW OPTION 'Retroceder'
                END IF
                IF vm_row_current = vm_num_rows THEN
                        HIDE OPTION 'Avanzar'
                END IF
	COMMAND KEY('M') 'Modificar' 'Modificar registro corriente. '
                CALL control_modificacion()
		{--
		IF vm_num_repd > vm_scr_lin THEN
                        SHOW OPTION 'Detalle'
                ELSE
                        HIDE OPTION 'Detalle'
                END IF
		--}
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
                CALL control_consulta()
                IF vm_num_rows <= 1 THEN
                        SHOW OPTION 'Modificar'
                        SHOW OPTION 'Detalle'
			SHOW OPTION 'Imprimir'
                        HIDE OPTION 'Avanzar'
                        HIDE OPTION 'Retroceder'
                        IF vm_num_rows = 0 THEN
                                HIDE OPTION 'Modificar'
                        	HIDE OPTION 'Detalle'
				HIDE OPTION 'Imprimir'
				HIDE OPTION 'Eliminar'
                        END IF
                ELSE
			SHOW OPTION 'Imprimir'
                        SHOW OPTION 'Avanzar'
                        SHOW OPTION 'Modificar'
                        SHOW OPTION 'Detalle'
                END IF
                IF vm_num_rows >= 1 THEN
			SHOW OPTION 'Eliminar'
		END IF
                IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
		{--
		IF vm_num_repd > vm_scr_lin THEN
                        SHOW OPTION 'Detalle'
                ELSE
                        HIDE OPTION 'Detalle'
                END IF
		--}
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
		{--
		IF vm_num_repd > vm_scr_lin THEN
                        SHOW OPTION 'Detalle'
                ELSE
                        HIDE OPTION 'Detalle'
                END IF
		--}
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
		{--
		IF vm_num_repd > vm_scr_lin THEN
                        SHOW OPTION 'Detalle'
                ELSE
                        HIDE OPTION 'Detalle'
                END IF
		--}
	COMMAND KEY('D') 'Detalle' 'Muestra siguiente detalles del registro. '
                CALL muestra_detalle_arr()
	COMMAND KEY('P') 'Imprimir' 'Muestra el pedido para imprimir. '
		CALL imprimir()
	COMMAND KEY('E') 'Eliminar' 'Eliminar pedidos no actualizados.'
		IF vm_num_rows > 0 THEN
			CALL control_eliminacion()
		END IF
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION sub_menu()
DEFINE resp		CHAR(6)

MENU 'OPCIONES'
	BEFORE MENU
		IF vm_flag_mant = 'I' THEN
			CALL leer_cabecera()
			IF int_flag THEN
				CLEAR FORM
				CALL mostrar_botones_detalle()
				IF vm_row_current > 0 THEN
		               		CALL mostrar_registro(
						vm_r_rows[vm_row_current])
       				END IF
				EXIT MENU
			END IF
			IF vm_flag_grabar = 0 THEN
				HIDE OPTION 'Detalle'
			ELSE
				SHOW OPTION 'Detalle'
			END IF
		END IF
		IF vm_flag_mant = 'M' THEN
			CALL leer_detalle()
			IF int_flag THEN
				ROLLBACK WORK
				CLEAR FORM
				CALL mostrar_botones_detalle()
				IF vm_row_current > 0 THEN
		               		CALL mostrar_registro(
						vm_r_rows[vm_row_current])
       				END IF
				EXIT MENU
			END IF
		END IF
	COMMAND KEY('C') 'Cabecera' 'Lee Cabecera del registro corriente. '
		CALL leer_cabecera()
		IF int_flag THEN
			IF vm_flag_mant = 'M' THEN
				ROLLBACK WORK
			END IF
			CLEAR FORM
			CALL mostrar_botones_detalle()
			IF vm_row_current > 0 THEN
		        	CALL mostrar_registro(vm_r_rows[vm_row_current])
       			END IF
			EXIT MENU
		END IF
	COMMAND KEY('D') 'Detalle' 'Lee Detalle del registro corriente. '
		CALL leer_detalle()
		IF int_flag THEN
			IF vm_flag_mant = 'M' THEN
				ROLLBACK WORK
			END IF
			CLEAR FORM
			CALL mostrar_botones_detalle()
			IF vm_row_current > 0 THEN
		        	CALL mostrar_registro(vm_r_rows[vm_row_current])
       			END IF
			EXIT MENU
		END IF
	COMMAND KEY('G') 'Grabar' 'Graba el registro corriente. '
		CALL control_grabar()
		IF vm_grabado THEN
			EXIT MENU
		END IF
	COMMAND KEY('S') 'Salir' 'Sale del menú. '
		IF vm_flag_grabar = 1 THEN
			LET int_flag = 0
			--CALL fgl_winquestion(vg_producto,'Salir al menú principal y perder los cambios realizados ?','No','Yes|No|Cancel','question',1)
			CALL fl_hacer_pregunta('Salir al menú principal y perder los cambios realizados ?','No')
				RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				IF vm_flag_mant = 'M' THEN
					ROLLBACK WORK
        			END IF
				CLEAR FORM
				CALL mostrar_botones_detalle()
				IF vm_row_current > 0 THEN
		                	CALL mostrar_registro(
						vm_r_rows[vm_row_current])
        			END IF
				EXIT MENU
			END IF
		ELSE
			CLEAR FORM
			CALL mostrar_botones_detalle()
			IF vm_row_current > 0 THEN
		               	CALL mostrar_registro(vm_r_rows[vm_row_current])
       			END IF
			EXIT MENU
		END IF
END MENU

END FUNCTION



FUNCTION control_grabar()

LET vm_grabado = 0
IF rm_r16.r16_pedido IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'No puede grabar el pedido sin especificar la cabecera.','exclamation')
	CALL fl_mostrar_mensaje('No puede grabar el pedido sin especificar la cabecera.','exclamation')
	RETURN
END IF
IF vm_num_repd = 0 THEN
	--CALL fgl_winmessage(vg_producto,'No puede grabar el pedido sin especificar el detalle.','exclamation')
	CALL fl_mostrar_mensaje('No puede grabar el pedido sin especificar el detalle.','exclamation')
	RETURN
END IF
IF rm_r16.r16_linea = 'TODAS' THEN
	LET rm_r16.r16_linea = NULL
END IF
IF vm_flag_mant = 'I' AND vm_flag_grabar THEN
	LET vm_grabado = 1
	BEGIN WORK
		LET rm_r16.r16_fecing = CURRENT
		INSERT INTO rept016 VALUES (rm_r16.*)
		CALL grabar_detalle()
	COMMIT WORK
	IF vm_num_rows = vm_max_rows THEN
		LET vm_num_rows = 1
	ELSE
		LET vm_num_rows = vm_num_rows + 1
	END IF
	LET vm_row_current = vm_num_rows
	LET vm_r_rows[vm_row_current] = rm_r16.r16_pedido
	CALL mostrar_registro(vm_r_rows[vm_num_rows])	
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL muestra_contadores_det(0)
	CALL fl_mensaje_registro_ingresado()
END IF
IF vm_flag_mant = 'M' AND vm_flag_grabar THEN
	LET vm_grabado = 1
	UPDATE rept016 SET r16_tipo         = rm_r16.r16_tipo,
			   r16_linea        = rm_r16.r16_linea,
			   r16_referencia   = rm_r16.r16_referencia,
			   r16_proveedor    = rm_r16.r16_proveedor,
			   r16_moneda       = rm_r16.r16_moneda,
			   r16_demora       = rm_r16.r16_demora,
			   r16_seguridad    = rm_r16.r16_seguridad,
			   r16_fec_envio    = rm_r16.r16_fec_envio,
			   r16_fec_llegada  = rm_r16.r16_fec_llegada,
			   r16_aux_cont     = rm_r16.r16_aux_cont
		WHERE CURRENT OF q_up
	CALL grabar_detalle()
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
END IF
LET vm_flag_grabar = 0
WHENEVER ERROR STOP

END FUNCTION



FUNCTION grabar_detalle()
DEFINE i		SMALLINT
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_g16		RECORD LIKE gent016.*

DELETE FROM rept017 WHERE r17_compania  = vg_codcia
		      AND r17_localidad = vg_codloc
		      AND r17_pedido    = rm_r16.r16_pedido
		      AND r17_estado    = "A"
		      --AND r17_cantrec   < r17_cantped
FOR i = 1 TO vm_num_repd
	IF rm_repd[i].r17_item IS NULL THEN
		CONTINUE FOR
	END IF
	CALL fl_lee_item(vg_codcia, rm_repd[i].r17_item) RETURNING r_r10.*
	CALL fl_lee_partida(r_r10.r10_partida) RETURNING r_g16.*
	LET rm_r17.r17_linea    = r_r10.r10_linea
	LET rm_r17.r17_rotacion = r_r10.r10_rotacion
	LET rm_r17.r17_partida  = r_r10.r10_partida
	LET rm_r17.r17_peso     = r_r10.r10_peso
	LET rm_r17.r17_cantpaq  = r_r10.r10_cantpaq
	LET rm_r17.r17_porc_part= r_g16.g16_porcentaje
	LET rm_r17.r17_vol_cuft = r_r10.r10_vol_cuft
	INSERT INTO rept017 VALUES (rm_r17.r17_compania, rm_r17.r17_localidad,
				rm_r16.r16_pedido, rm_repd[i].r17_item, i,
				rm_r17.r17_estado, rm_repd[i].r17_fob,
				rm_repd[i].r17_cantped, rm_r17.r17_cantrec,
 				rm_r17.r17_exfab_mb, rm_r17.r17_desp_mi,
				rm_r17.r17_desp_mb, rm_r17.r17_tot_fob_mi,
				rm_r17.r17_tot_fob_mb, rm_r17.r17_flete,
 				rm_r17.r17_seguro, rm_r17.r17_cif,
 				rm_r17.r17_arancel, rm_r17.r17_salvagu,
				rm_r17.r17_cargos, rm_r17.r17_costuni_ing,
				rm_r17.r17_ind_bko, rm_r17.r17_linea,
				rm_r17.r17_rotacion, rm_r17.r17_partida,
				rm_r17.r17_porc_part, rm_r17.r17_porc_salva,
				rm_r17.r17_vol_cuft, rm_r17.r17_peso,
				rm_r17.r17_cantpaq)
END FOR

END FUNCTION



FUNCTION datos_cabecera_default()
DEFINE r_g13		RECORD LIKE gent013.*

LET rm_r16.r16_compania    = vg_codcia
LET rm_r16.r16_localidad   = vg_codloc
LET rm_r16.r16_estado      = 'A'
LET rm_r16.r16_tipo        = 'E'
LET rm_r16.r16_fec_envio   = CURRENT
LET rm_r16.r16_moneda      = rg_gen.g00_moneda_base
LET rm_r16.r16_maximo      = 0
LET rm_r16.r16_minimo      = 0
LET rm_r16.r16_periodo_vta = 0
LET rm_r16.r16_pto_reorden = 0
LET rm_r16.r16_flag_estad  = 'M'
LET rm_r16.r16_usuario     = vg_usuario
LET rm_r16.r16_fecing      = CURRENT
CALL fl_lee_moneda(rm_r16.r16_moneda) RETURNING r_g13.*
IF r_g13.g13_moneda IS NULL THEN
        --CALL fgl_winmessage(vg_producto,'No existe ninguna moneda base','stop')
	CALL fl_mostrar_mensaje('No existe ninguna moneda base.','stop')
        EXIT PROGRAM
END IF
DISPLAY BY NAME rm_r16.r16_tipo, rm_r16.r16_fec_envio, rm_r16.r16_moneda
DISPLAY r_g13.g13_nombre TO tit_mon_bas
IF vg_gui = 0 THEN
	CALL muestra_tipo(rm_r16.r16_tipo)
END IF
CALL muestra_estado()

END FUNCTION



FUNCTION datos_detalle_default()

LET rm_r17.r17_compania    = vg_codcia
LET rm_r17.r17_localidad   = vg_codloc
LET rm_r17.r17_estado      = 'A'
LET rm_r17.r17_cantrec     = 0
LET rm_r17.r17_exfab_mb    = 0
LET rm_r17.r17_desp_mi     = 0
LET rm_r17.r17_desp_mb     = 0
LET rm_r17.r17_tot_fob_mi  = 0
LET rm_r17.r17_tot_fob_mb  = 0
LET rm_r17.r17_flete       = 0
LET rm_r17.r17_seguro      = 0
LET rm_r17.r17_cif         = 0
LET rm_r17.r17_arancel     = 0
LET rm_r17.r17_salvagu     = 0
LET rm_r17.r17_cargos      = 0
LET rm_r17.r17_costuni_ing = 0
LET rm_r17.r17_ind_bko     = 'S'
LET rm_r17.r17_porc_part   = 0
LET rm_r17.r17_porc_salva  = 0
LET rm_r17.r17_vol_cuft    = NULL

END FUNCTION



FUNCTION control_ingreso()
DEFINE i		SMALLINT

CLEAR FORM
CALL fl_retorna_usuario()
CALL mostrar_botones_detalle()
INITIALIZE rm_r16.*, rm_r17.* TO NULL
FOR i = 1 TO vm_max_elm
	INITIALIZE rm_repd[i].*, rm_repd_aux[i].* TO NULL
END FOR
CALL retorna_tam_arr()
FOR i = 1 TO vm_size_arr
	CLEAR rm_repd[i].*
END FOR
CALL datos_cabecera_default()
CALL datos_detalle_default()
LET vm_total_gen = 0
LET vm_flag_mant = 'I'
LET vm_num_repd  = 0
LET vm_num_repd_aux = 0
CALL sub_menu()

END FUNCTION



FUNCTION control_modificacion()
	
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
IF rm_r16.r16_estado <> vm_estado THEN
	CALL fl_mostrar_mensaje('No puede dar mantenimiento a un pedido que no este activo.','exclamation')
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR SELECT * FROM rept016
	WHERE r16_compania  = vg_codcia
	  AND r16_localidad = vg_codloc
	  AND r16_pedido    = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_r16.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
CALL datos_detalle_default()
LET vm_flag_mant = 'M'
CALL sub_menu()
 
END FUNCTION



FUNCTION control_consulta()
DEFINE query		CHAR(1200)
DEFINE expr_sql		CHAR(800)
DEFINE num_reg		INTEGER
DEFINE codpe_aux	LIKE rept016.r16_pedido
DEFINE codl_aux		LIKE rept003.r03_codigo
DEFINE noml_aux		LIKE rept003.r03_nombre
DEFINE codp_aux		LIKE cxpt002.p02_codprov
DEFINE nomp_aux		LIKE cxpt001.p01_nomprov
DEFINE mone_aux         LIKE gent013.g13_moneda
DEFINE nomm_aux         LIKE gent013.g13_nombre
DEFINE deci_aux         LIKE gent013.g13_decimales
DEFINE cod_aux		LIKE ctbt010.b10_cuenta
DEFINE nom_aux		LIKE ctbt010.b10_descripcion
DEFINE r_p02		RECORD LIKE cxpt002.*

CLEAR FORM
CALL mostrar_botones_detalle()
INITIALIZE codpe_aux, codl_aux, codp_aux, mone_aux, cod_aux TO NULL
LET int_flag = 0
IF num_args() = 4 THEN
	CONSTRUCT BY NAME expr_sql ON r16_pedido, r16_tipo, r16_estado,
		r16_linea, r16_moneda, r16_proveedor, r16_fec_envio,
		r16_referencia, r16_aux_cont
		ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
		ON KEY(F2)
			IF INFIELD(r16_pedido) THEN
				CALL fl_ayuda_pedidos_rep(vg_codcia,vg_codloc,
							'T','T')
					RETURNING codpe_aux
				LET int_flag = 0
				IF codpe_aux IS NOT NULL THEN
					DISPLAY codpe_aux TO r16_pedido
				END IF
			END IF
			IF INFIELD(r16_linea) THEN
				CALL fl_ayuda_lineas_rep(vg_codcia)
					RETURNING codl_aux, noml_aux
				LET int_flag = 0
				IF codl_aux IS NOT NULL THEN
					DISPLAY codl_aux TO r16_linea
				END IF
			END IF
			IF INFIELD(r16_proveedor) THEN
				CALL fl_ayuda_proveedores_localidad(vg_codcia,
								vg_codloc)
					RETURNING codp_aux, nomp_aux
				LET int_flag = 0
				IF codp_aux IS NOT NULL THEN
					CALL fl_lee_proveedor_localidad(
							vg_codcia,vg_codloc,
							codp_aux)
						RETURNING r_p02.*
					DISPLAY codp_aux TO r16_proveedor
					DISPLAY nomp_aux TO tit_proveedor
					DISPLAY r_p02.p02_dias_demora
						TO r16_demora
					DISPLAY r_p02.p02_dias_seguri
						TO r16_seguridad
				END IF
			END IF
			IF INFIELD(r16_moneda) THEN
                        	CALL fl_ayuda_monedas()
                                	RETURNING mone_aux, nomm_aux, deci_aux
	                        LET int_flag = 0
        	                IF mone_aux IS NOT NULL THEN
                	                DISPLAY mone_aux TO r16_moneda
                        	        DISPLAY nomm_aux TO tit_mon_bas
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
		AFTER FIELD r16_tipo
			LET rm_r16.r16_tipo = get_fldbuf(r16_tipo)
			IF vg_gui = 0 THEN
				IF rm_r16.r16_tipo IS NOT NULL THEN
					CALL muestra_tipo(rm_r16.r16_tipo)
				ELSE
					CLEAR tit_tipo
				END IF
			END IF
		AFTER FIELD r16_estado
			LET rm_r16.r16_estado = get_fldbuf(r16_estado)
			IF rm_r16.r16_estado IS NOT NULL THEN
				CALL muestra_estado()
			ELSE
				CLEAR r16_estado, tit_estado_rep
			END IF
		BEFORE CONSTRUCT
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
	END CONSTRUCT
	IF int_flag THEN
		IF vm_row_current > 0 THEN
			CALL mostrar_registro(vm_r_rows[vm_row_current])
		ELSE
			CLEAR FORM
			CALL mostrar_botones_detalle()
		END IF
		RETURN
	END IF
ELSE
	LET expr_sql = 'r16_pedido = "', arg_val(5), '"'
END IF
LET query = 'SELECT UNIQUE r16_pedido FROM rept016, rept017 ' ||
		'WHERE r16_compania  = ' || vg_codcia ||
		'  AND r16_localidad = ' || vg_codloc ||
		'  AND ' || expr_sql CLIPPED ||
		'  AND r17_compania  = r16_compania ' ||
		'  AND r17_localidad = r16_localidad ' ||
		'  AND r17_pedido    = r16_pedido '
		--'  AND r17_estado    = "' || vm_estado || '"' ||
		--'  AND r17_cantrec   < r17_cantped'
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
	CLEAR FORM
	LET vm_row_current = 0
	LET vm_num_repd    = 0
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL muestra_contadores_det(0)
	CALL mostrar_botones_detalle()
ELSE  
	LET vm_row_current = 1
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL muestra_contadores_det(0)
	CALL mostrar_registro(vm_r_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION leer_cabecera()
DEFINE resp		CHAR(6)
DEFINE i		SMALLINT
DEFINE r_r16		RECORD LIKE rept016.*
DEFINE r_r03 		RECORD LIKE rept003.*
DEFINE r_p01 		RECORD LIKE cxpt001.*
DEFINE r_p02		RECORD LIKE cxpt002.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE codp_aux		LIKE cxpt002.p02_codprov
DEFINE nomp_aux		LIKE cxpt001.p01_nomprov
DEFINE codl_aux		LIKE rept003.r03_codigo
DEFINE noml_aux		LIKE rept003.r03_nombre
DEFINE mone_aux         LIKE gent013.g13_moneda
DEFINE nomm_aux         LIKE gent013.g13_nombre
DEFINE deci_aux         LIKE gent013.g13_decimales
DEFINE cod_aux		LIKE ctbt010.b10_cuenta
DEFINE nom_aux		LIKE ctbt010.b10_descripcion
DEFINE lineaant		LIKE rept016.r16_linea
DEFINE fec_envio	LIKE rept016.r16_fec_envio
DEFINE monedaant	LIKE rept016.r16_moneda

INITIALIZE codp_aux, codl_aux, mone_aux, cod_aux TO NULL
LET int_flag = 0
INPUT BY NAME rm_r16.r16_pedido, rm_r16.r16_tipo, rm_r16.r16_linea,
	rm_r16.r16_moneda, rm_r16.r16_proveedor, rm_r16.r16_fec_envio,
	rm_r16.r16_referencia, rm_r16.r16_aux_cont
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF field_touched(rm_r16.r16_pedido, rm_r16.r16_tipo,
			rm_r16.r16_linea, rm_r16.r16_moneda,
			rm_r16.r16_proveedor, rm_r16.r16_fec_envio,
			rm_r16.r16_referencia, rm_r16.r16_aux_cont)
		THEN
               		LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
        	        	RETURNING resp
              		IF resp = 'Yes' THEN
				IF rm_r16.r16_linea = 'TODAS' THEN
					LET rm_r16.r16_linea = NULL
				END IF
				LET vm_flag_grabar = 0
				LET int_flag = 1
				RETURN
                	END IF
		ELSE
			RETURN
		END IF
	ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(r16_linea) THEN
			CALL fl_ayuda_lineas_rep(vg_codcia)
				RETURNING codl_aux, noml_aux
			LET int_flag = 0
			IF codl_aux IS NOT NULL THEN
				LET rm_r16.r16_linea = codl_aux
				DISPLAY BY NAME rm_r16.r16_linea
			END IF
		END IF
		IF INFIELD(r16_proveedor) THEN
			CALL fl_ayuda_proveedores_localidad(vg_codcia,vg_codloc)
				RETURNING codp_aux, nomp_aux
			LET int_flag = 0
			IF codp_aux IS NOT NULL THEN
				CALL fl_lee_proveedor_localidad(vg_codcia,
							vg_codloc,codp_aux)
					RETURNING r_p02.*
				LET rm_r16.r16_proveedor = codp_aux
				LET rm_r16.r16_demora = r_p02.p02_dias_demora
				LET rm_r16.r16_seguridad =
						r_p02.p02_dias_seguri
				DISPLAY BY NAME rm_r16.r16_proveedor,
					rm_r16.r16_demora, rm_r16.r16_seguridad
				DISPLAY nomp_aux TO tit_proveedor
			END IF
		END IF
		IF INFIELD(r16_moneda) THEN
                        CALL fl_ayuda_monedas()
                                RETURNING mone_aux, nomm_aux, deci_aux
                        LET int_flag = 0
                        IF mone_aux IS NOT NULL THEN
				LET rm_r16.r16_moneda = mone_aux
                                DISPLAY BY NAME rm_r16.r16_moneda
                                DISPLAY nomm_aux TO tit_mon_bas
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
	BEFORE INPUT
		IF rm_r16.r16_linea = 'TODAS' THEN
			LET rm_r16.r16_linea = NULL
		END IF
		LET lineaant  = rm_r16.r16_linea
		LET monedaant = rm_r16.r16_moneda
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD r16_pedido
		IF vm_flag_mant = 'M' THEN
			NEXT FIELD NEXT
		END IF
	BEFORE FIELD r16_linea
		IF rm_r16.r16_linea = 'TODAS' THEN
			LET rm_r16.r16_linea = NULL
		END IF
	BEFORE FIELD r16_fec_envio
		LET fec_envio = rm_r16.r16_fec_envio
	AFTER FIELD r16_pedido
		IF rm_r16.r16_pedido IS NOT NULL THEN
			CALL fl_lee_pedido_rep(vg_codcia,vg_codloc,
						rm_r16.r16_pedido)
				RETURNING r_r16.*
			IF r_r16.r16_compania IS NOT NULL THEN
				--CALL fgl_winmessage(vg_producto,'Este pedido ya fue realizado','exclamation')
				CALL fl_mostrar_mensaje('Este pedido ya fue realizado.','exclamation')
				NEXT FIELD r16_pedido
			END IF
		END IF
	AFTER FIELD r16_linea
		IF rm_r16.r16_linea IS NOT NULL THEN
			CALL fl_lee_linea_rep(vg_codcia,rm_r16.r16_linea)
				RETURNING r_r03.*
			IF r_r03.r03_compania IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'No existe esa División.','exclamation')
				CALL fl_mostrar_mensaje('No existe esa División.','exclamation')
				NEXT FIELD r16_linea
			END IF
			IF lineaant <> rm_r16.r16_linea AND vm_num_repd > 0 THEN
				--CALL fgl_winmessage(vg_producto,'División no puede ser cambiada.','exclamation')
				CALL fl_mostrar_mensaje('División no puede ser cambiada.','exclamation')
				LET rm_r16.r16_linea = lineaant
				DISPLAY BY NAME rm_r16.r16_linea
				NEXT FIELD r16_linea
			END IF
                        IF r_r03.r03_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD r16_linea
                        END IF
		END IF
	AFTER FIELD r16_proveedor
		IF rm_r16.r16_proveedor IS NOT NULL THEN
			CALL fl_lee_proveedor_localidad(vg_codcia,
						vg_codloc,rm_r16.r16_proveedor)
				RETURNING r_p02.*
			IF r_p02.p02_compania IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'No existe ese proveedor','exclamation')
				CALL fl_mostrar_mensaje('No existe ese proveedor.','exclamation')
				NEXT FIELD r16_proveedor
			END IF
			CALL fl_lee_proveedor(rm_r16.r16_proveedor)
				RETURNING r_p01.*
			DISPLAY r_p01.p01_nomprov TO tit_proveedor
			IF r_p01.p01_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD r16_proveedor
			END IF
			LET rm_r16.r16_demora    = r_p02.p02_dias_demora
			LET rm_r16.r16_seguridad = r_p02.p02_dias_seguri
			DISPLAY BY NAME rm_r16.r16_demora, rm_r16.r16_seguridad
		ELSE
			CLEAR r16_demora, r16_seguridad, tit_proveedor
		END IF
	AFTER FIELD r16_fec_envio
		IF rm_r16.r16_fec_envio IS NOT NULL THEN
			IF rm_r16.r16_fec_envio > TODAY THEN
				--CALL fgl_winmessage(vg_producto,'La fecha de envío no puede ser mayor a la fecha de hoy','exclamation')
				CALL fl_mostrar_mensaje('La fecha de envío no puede ser mayor a la fecha de hoy.','exclamation')
				NEXT FIELD r16_fec_envio
			END IF
		ELSE
			LET rm_r16.r16_fec_envio = fec_envio
			DISPLAY BY NAME rm_r16.r16_fec_envio
		END IF
	AFTER FIELD r16_moneda
		IF rm_r16.r16_moneda IS NOT NULL THEN
                        CALL fl_lee_moneda(rm_r16.r16_moneda)
                                RETURNING r_g13.*
                        IF r_g13.g13_moneda IS NULL  THEN
                        	--CALL fgl_winmessage(vg_producto,'Moneda no existe','exclamation')
				CALL fl_mostrar_mensaje('Moneda no existe.','exclamation')
                                NEXT FIELD r16_moneda
                        END IF
                        DISPLAY r_g13.g13_nombre TO tit_mon_bas
			IF monedaant <> rm_r16.r16_moneda
			AND vm_num_repd > 0 THEN
				--CALL fgl_winmessage(vg_producto,'Moneda no puede ser cambiada.','exclamation')
				CALL fl_mostrar_mensaje('Moneda no puede ser cambiada.','exclamation')
				LET rm_r16.r16_moneda = monedaant
				DISPLAY BY NAME rm_r16.r16_moneda
                        	CALL fl_lee_moneda(rm_r16.r16_moneda)
					RETURNING r_g13.*
                        	DISPLAY r_g13.g13_nombre TO tit_mon_bas
				NEXT FIELD r16_moneda
			END IF
                        IF r_g13.g13_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD r16_moneda
                        END IF
                ELSE
                        LET rm_r16.r16_moneda = rg_gen.g00_moneda_base
                        DISPLAY BY NAME rm_r16.r16_moneda
                        CALL fl_lee_moneda(rm_r16.r16_moneda) RETURNING r_g13.*
                        DISPLAY r_g13.g13_nombre TO tit_mon_bas
                END IF
	AFTER FIELD r16_aux_cont
		IF rm_r16.r16_aux_cont IS NOT NULL THEN
                        CALL fl_lee_cuenta(vg_codcia,rm_r16.r16_aux_cont)
                                RETURNING r_b10.*
                        IF r_b10.b10_cuenta IS NULL THEN
                        	--CALL fgl_winmessage(vg_producto,'Cuenta no existe','exclamation')
				CALL fl_mostrar_mensaje('Cuenta no existe.','exclamation')
                                NEXT FIELD r16_aux_cont
                        END IF
                        DISPLAY r_b10.b10_descripcion TO tit_aux_con
                        IF r_b10.b10_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD r16_aux_cont
                        END IF
			IF r_b10.b10_nivel <> vm_nivel THEN
                        	--CALL fgl_winmessage(vg_producto,'Nivel de cuenta debe ser solo 6','info')
				CALL fl_mostrar_mensaje('Nivel de cuenta debe ser solo 6.','info')
                                NEXT FIELD r16_aux_cont
                        END IF
                ELSE
                        CLEAR tit_aux_con
                END IF
	AFTER FIELD r16_tipo
		IF vg_gui = 0 THEN
			IF rm_r16.r16_tipo IS NOT NULL THEN
				CALL muestra_tipo(rm_r16.r16_tipo)
			ELSE
				CLEAR tit_tipo
			END IF
		END IF
	AFTER INPUT
		IF rm_r16.r16_tipo = 'S' THEN
			IF rm_r16.r16_linea IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Pedido es sugerido, escoja una División.','exclamation')
				CALL fl_mostrar_mensaje('Pedido es sugerido, escoja una División.','exclamation')
				LET rm_r16.r16_linea = lineaant
				DISPLAY BY NAME rm_r16.r16_linea
				NEXT FIELD r16_linea
			END IF
		END IF
		IF rm_r16.r16_linea IS NULL THEN
			LET rm_r16.r16_linea = 'TODAS'
		END IF
		LET vm_flag_grabar = 1
END INPUT

END FUNCTION



FUNCTION leer_detalle()
DEFINE resul		SMALLINT
DEFINE resp             CHAR(6)
DEFINE i,j,l,k		SMALLINT
DEFINE aux_j, aux_i	SMALLINT
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r17		RECORD LIKE rept017.*
DEFINE stock		LIKE rept022.r22_cantidad 
DEFINE salir		SMALLINT
DEFINE in_array		SMALLINT
DEFINE mensaje		VARCHAR(100)

INITIALIZE r_r17.* TO NULL
LET i = 1
LET resul    = 0
LET salir    = 0
LET in_array = 0

WHILE NOT salir
CALL set_count(vm_num_repd)
LET int_flag = 0
INPUT ARRAY rm_repd WITHOUT DEFAULTS FROM rm_repd.*
	ON KEY(INTERRUPT)
       		LET int_flag = 0
               	CALL fl_mensaje_abandonar_proceso()
	               	RETURNING resp
       		IF resp = 'Yes' THEN
			LET vm_num_repd = vm_num_repd_aux
			FOR l = 1 TO vm_num_repd
				LET rm_repd[l].* = rm_repd_aux[l].*
			END FOR
			CALL muestra_lineas_detalle()
			CALL muestra_contadores_det(0)
			LET vm_flag_grabar = 0
       			LET int_flag = 1
			EXIT WHILE
       	       	END IF	
	ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(r17_item) THEN
               		CALL fl_ayuda_maestro_items_stock(vg_codcia,
						vm_grupo_linea,r_r11.r11_bodega)
                     		RETURNING r_r10.r10_codigo, r_r10.r10_nombre,
					  r_r10.r10_linea, r_r10.r10_precio_mb,
					  r_r11.r11_bodega, stock         
			LET int_flag = 0
			IF r_r10.r10_codigo IS NOT NULL THEN
				LET rm_repd[i].r17_item       = r_r10.r10_codigo
				LET rm_repd[i].tit_descripcion= r_r10.r10_nombre
				LET rm_repd[i].r17_fob        = r_r10.r10_fob
				DISPLAY r_r10.r10_codigo TO rm_repd[j].r17_item 
				DISPLAY r_r10.r10_nombre TO
					rm_repd[j].tit_descripcion 
				DISPLAY rm_repd[i].r17_fob TO rm_repd[j].r17_fob
			END IF
		END IF
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
		CALL sacar_total()
		DISPLAY rm_repd[i].tit_descripcion TO tit_descri
		CALL muestra_clase(i)
		CALL muestra_contadores_det(i)
	BEFORE FIELD r17_item
		LET r_r17.r17_item = rm_repd[i].r17_item
	BEFORE FIELD r17_cantped
		LET r_r17.r17_cantped = rm_repd[i].r17_cantped
	BEFORE FIELD r17_fob
		LET r_r17.r17_fob = rm_repd[i].r17_fob
	AFTER FIELD r17_item
		IF rm_repd[i].r17_item IS NOT NULL THEN
			CALL fl_lee_item(vg_codcia,rm_repd[i].r17_item)
				RETURNING r_r10.*
			IF r_r10.r10_compania IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'No existe Item.','exclamation')
				CALL fl_mostrar_mensaje('No existe Item.','exclamation')
				NEXT FIELD r17_item
			END IF
			IF rm_repd[i].r17_item = r_r17.r17_item THEN
				LET r_r10.r10_fob = rm_repd[i].r17_fob
			END IF
			LET rm_repd[i].tit_descripcion = r_r10.r10_nombre
			LET rm_repd[i].r17_fob         = r_r10.r10_fob
			DISPLAY r_r10.r10_nombre TO rm_repd[j].tit_descripcion
			DISPLAY rm_repd[i].tit_descripcion TO tit_descri
			CALL muestra_clase(i)
			DISPLAY rm_repd[i].r17_fob TO rm_repd[j].r17_fob
			IF rm_r16.r16_linea <> 'TODAS' THEN
				IF r_r10.r10_linea <> rm_r16.r16_linea THEN
					--CALL fgl_winmessage(vg_producto,'División del Item es diferente de la División de cabecera.','exclamation')
					CALL fl_mostrar_mensaje('División del Item es diferente de la División de cabecera.','exclamation')
					NEXT FIELD r17_item
				END IF 
			END IF 
----
{--
 -- VALIDACION DE LA MONEDA DEL FOB CON LA DE MONEDA DE CABECERA
			IF r_r10.r10_monfob <> rm_r16.r16_moneda THEN
				--CALL fgl_winmessage(vg_producto,'Moneda del Item es diferente de la moneda de cabecera.','exclamation')
				CALL fl_mostrar_mensaje('Moneda del Item es diferente de la moneda de cabecera.','exclamation')
				NEXT FIELD r17_item
			END IF
--}
----
{ 
SE COMENTA UNICAMENTE POR EL CASO DE DITECA, EXISTEN 609.000 ITEMS SIN FOB
SIN EMBARGO ANALIZANDO SI NO TIENE FOB SE DEBE PODER DIGITAR, SI LO PERMITE.
			IF r_r10.r10_fob = 0 THEN
				--CALL fgl_winmessage(vg_producto,'Item no tiene FOB.','exclamation')
				CALL fl_mostrar_mensaje('Item no tiene FOB.','exclamation')
				NEXT FIELD r17_item
			END IF
}
			IF r_r10.r10_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD r17_item
			END IF
		------ PARA LA VALIDACION DE ITEMS REPETIDOS ------
			FOR k = 1 TO arr_count()
				IF  rm_repd[i].r17_item =
				    rm_repd[k].r17_item AND 
				    i <> k
				    THEN
					LET mensaje = 'El item ya fue ingresado en la posicion ' || k || ', desea ir a esa posición?'
					--CALL fgl_winquestion(vg_producto,mensaje,'Yes', 'Yes|No', 'question', 1)
					CALL fl_hacer_pregunta(mensaje, 'Yes')
						RETURNING resp	
					IF resp = 'Yes' THEN
						INITIALIZE rm_repd[i].*
							TO NULL
						LET i = arr_count() - 1	
						LET vm_num_repd	= i 
						LET in_array = 1
						EXIT INPUT
					END IF
					--CALL fgl_winmessage(vg_producto,'No puede ingresar items repetidos.','exclamation')
					CALL fl_mostrar_mensaje('No puede ingresar items repetidos.','exclamation')
					NEXT FIELD r17_item
               			END IF
			END FOR
			IF r_r10.r10_costo_mb <= 0.01 AND
			   fl_item_tiene_movimientos(r_r10.r10_compania,
							r_r10.r10_codigo)
			THEN
				CALL fl_mostrar_mensaje('Debe estar configurado correctamente el costo del item y NO con costo menor igual a 0.01.', 'exclamation')
				NEXT FIELD r17_item
			END IF
		ELSE
			LET rm_repd[i].r17_item = r_r17.r17_item
			DISPLAY rm_repd[i].r17_item TO rm_repd[j].r17_item
		END IF
	AFTER FIELD r17_cantped
		IF rm_repd[i].r17_cantped IS NOT NULL THEN
			IF rm_repd[i].r17_fob IS NOT NULL THEN
				LET vm_num_repd = arr_count()
				CALL calcular_subtotal(i,j)
				CALL sacar_total()
			END IF
		ELSE
			LET rm_repd[i].r17_cantped = r_r17.r17_cantped
			DISPLAY rm_repd[i].r17_cantped TO rm_repd[j].r17_cantped
		END IF
	AFTER FIELD r17_fob
		IF rm_repd[i].r17_fob IS NOT NULL THEN
			IF rm_repd[i].r17_cantped IS NOT NULL THEN
				LET vm_num_repd = arr_count()
				CALL calcular_subtotal(i,j)
				CALL sacar_total()
			END IF
		ELSE
			LET rm_repd[i].r17_fob = r_r17.r17_fob
			DISPLAY rm_repd[i].r17_fob TO rm_repd[j].r17_fob
		END IF
	AFTER DELETE
		LET vm_num_repd = arr_count()
		CALL sacar_total()
	AFTER INPUT
		IF rm_r16.r16_linea = 'TODAS' THEN
			LET rm_r16.r16_linea = NULL
		END IF
		LET vm_num_repd = arr_count()
		IF vm_num_repd = 0 THEN
			--CALL fgl_winmessage(vg_producto,'Escriba algo en el detalle.','exclamation')
			CALL fl_mostrar_mensaje('Escriba algo en el detalle.','exclamation')
			NEXT FIELD r17_item
		END IF
		LET vm_flag_grabar = 1
		CALL sacar_total()
		LET vm_num_repd_aux = vm_num_repd
		FOR l = 1 TO vm_num_repd
			LET rm_repd_aux[l].* = rm_repd[l].*
		END FOR
		LET salir = 1
END INPUT
END WHILE
LET vm_num_repd = arr_count()
RETURN

END FUNCTION



FUNCTION calcular_subtotal(i,j)
DEFINE i,j		SMALLINT

LET rm_repd[i].tit_subtotal = rm_repd[i].r17_cantped * rm_repd[i].r17_fob
CALL fl_retorna_precision_valor(rm_r16.r16_moneda,rm_repd[i].tit_subtotal)
	RETURNING rm_repd[i].tit_subtotal
DISPLAY rm_repd[i].tit_subtotal TO rm_repd[j].tit_subtotal

END FUNCTION



FUNCTION sacar_total()
DEFINE i		SMALLINT
DEFINE tot_cant		DECIMAL(8,2)

LET tot_cant     = 0
LET vm_total_gen = 0
FOR i = 1 TO vm_num_repd
	LET tot_cant     = tot_cant     + rm_repd[i].r17_cantped
	LET vm_total_gen = vm_total_gen + rm_repd[i].tit_subtotal
END FOR
DISPLAY vm_total_gen TO tit_total
DISPLAY BY NAME tot_cant

END FUNCTION



FUNCTION muestra_siguiente_registro()
                                                                                
IF vm_row_current < vm_num_rows THEN
        LET vm_row_current = vm_row_current + 1
END IF
CLEAR tit_clase, tit_descri
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_contadores_det(0)
                                                                                
END FUNCTION



FUNCTION muestra_anterior_registro()
                                                                                
IF vm_row_current > 1 THEN
        LET vm_row_current = vm_row_current - 1
END IF
CLEAR tit_clase, tit_descri
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_contadores_det(0)
                                                                                
END FUNCTION
                                                                                
                                                                                
                                                                                
FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current      SMALLINT
DEFINE num_rows         SMALLINT

IF vg_gui = 1 THEN
	DISPLAY "" AT 1, 1
	DISPLAY row_current, " de ", num_rows AT 1, 68
END IF
                                                                                
END FUNCTION



FUNCTION muestra_contadores_det(cor)
DEFINE cor              SMALLINT

IF vg_gui = 1 THEN
	DISPLAY "" AT 9, 2
	DISPLAY cor, " de ", vm_num_repd AT 9, 64
END IF

END FUNCTION



FUNCTION mostrar_registro(num_reg)
DEFINE num_reg		LIKE rept016.r16_pedido
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE mensaje		VARCHAR(100)

IF vm_num_rows > 0 THEN
        DECLARE q_dt CURSOR FOR SELECT * FROM rept016, rept017
                WHERE r16_compania = vg_codcia
                 AND r16_localidad = vg_codloc
                 AND r16_pedido    = num_reg
		 AND r17_compania  = r16_compania
		 AND r17_localidad = r16_localidad
		 AND r17_pedido    = r16_pedido
		 --AND r17_estado    = vm_estado
		 --AND r17_cantrec   < r17_cantped
        OPEN q_dt
        FETCH q_dt INTO rm_r16.*
        IF STATUS = NOTFOUND THEN
		LET mensaje ='No existe registro con índice: ' || vm_row_current
		CALL fl_mostrar_mensaje(mensaje,'exclamation')
                RETURN
        END IF	
	DISPLAY BY NAME rm_r16.r16_pedido, rm_r16.r16_tipo, rm_r16.r16_linea,
			rm_r16.r16_proveedor, rm_r16.r16_fec_envio,
			rm_r16.r16_demora, rm_r16.r16_seguridad,
			rm_r16.r16_fec_llegada, rm_r16.r16_referencia,
			rm_r16.r16_moneda, rm_r16.r16_aux_cont
	CALL fl_lee_proveedor(rm_r16.r16_proveedor) RETURNING r_p01.*
	DISPLAY r_p01.p01_nomprov TO tit_proveedor
        CALL fl_lee_moneda(rm_r16.r16_moneda) RETURNING r_g13.*
        DISPLAY r_g13.g13_nombre TO tit_mon_bas
        CALL fl_lee_cuenta(vg_codcia,rm_r16.r16_aux_cont) RETURNING r_b10.*
        DISPLAY r_b10.b10_descripcion TO tit_aux_con
	IF vg_gui = 0 THEN
		CALL muestra_tipo(rm_r16.r16_tipo)
	END IF
	CALL muestra_estado()
	CALL muestra_detalle(num_reg)
ELSE
	RETURN
END IF

END FUNCTION



FUNCTION muestra_detalle(num_reg)
DEFINE num_reg          LIKE rept016.r16_pedido
DEFINE query            CHAR(800)
DEFINE i  		SMALLINT
DEFINE orden		SMALLINT
DEFINE cant		LIKE rept017.r17_cantped
DEFINE estado		LIKE rept017.r17_estado

CALL retorna_tam_arr()
LET vm_scr_lin = vm_size_arr
LET int_flag = 0
FOR i = 1 TO vm_scr_lin
        INITIALIZE rm_repd[i].* TO NULL
        CLEAR rm_repd[i].*
END FOR
LET query = 'SELECT r17_item, r10_nombre, r17_cantrec, r17_fob, ' ||
		' r17_cantped * r17_fob, r17_orden, r17_cantped, r17_estado ' ||
		'FROM rept017, rept010 ' ||
                'WHERE r17_compania = ' || vg_codcia ||
		' AND r17_localidad = ' || vg_codloc ||
		' AND r17_pedido    = ' || '"' || num_reg || '"' ||
		--' AND r17_estado    = "' || vm_estado || '"' ||
		--' AND r17_cantrec   < r17_cantped ' ||
		' AND r17_compania  = r10_compania ' ||
		' AND r17_item      = r10_codigo ' ||
		'ORDER BY r17_orden '
PREPARE cons1 FROM query
DECLARE q_cons1 CURSOR FOR cons1
LET i = 1
LET vm_num_repd = 0
FOREACH q_cons1 INTO rm_repd[i].*, orden, cant, estado
	CALL calcula_cantidad(cant, estado, i)
	LET rm_repd_aux[i].* = rm_repd[i].*
        LET vm_num_repd = vm_num_repd + 1
	LET vm_num_repd_aux = vm_num_repd
        LET i = i + 1
        IF vm_num_repd > vm_max_elm THEN
        	LET vm_num_repd = vm_num_repd - 1
		CALL fl_mensaje_arreglo_incompleto()
		EXIT PROGRAM
                --EXIT FOREACH
        END IF
END FOREACH
IF vm_num_repd > 0 THEN
        LET int_flag = 0
	CALL muestra_contadores_det(0)
	CALL muestra_lineas_detalle()
END IF
CALL sacar_total()
IF int_flag THEN
	INITIALIZE rm_repd[1].* TO NULL
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
		DISPLAY rm_repd[i].* TO rm_repd[i].*
		DISPLAY rm_repd[i].tit_descripcion TO tit_descri
		CALL muestra_clase(i)
	ELSE
		CLEAR rm_repd[i].*, tit_clase, tit_descri
	END IF
END FOR

END FUNCTION



FUNCTION muestra_detalle_arr()
DEFINE i,j,l,col	SMALLINT
DEFINE query		CHAR(800)
DEFINE r_r16		RECORD LIKE rept016.*
DEFINE orden		LIKE rept017.r17_orden
DEFINE cant		LIKE rept017.r17_cantped
DEFINE estado		LIKE rept017.r17_estado

LET rm_orden[1]  = 'ASC'
LET vm_columna_1 = 6
LET vm_columna_2 = 2
LET col          = 1
WHILE TRUE
	CALL mostrar_botones_detalle()
	{--
	BEGIN WORK
	WHENEVER ERROR CONTINUE
	DECLARE q_up2 CURSOR FOR SELECT * FROM rept016
		WHERE r16_compania  = vg_codcia
		  AND r16_localidad = vg_codloc
		  AND r16_pedido    = vm_r_rows[vm_row_current]
		FOR UPDATE
	OPEN q_up2
	FETCH q_up2 INTO r_r16.*
	IF STATUS < 0 THEN
		ROLLBACK WORK
		CALL fl_mensaje_bloqueo_otro_usuario()
		WHENEVER ERROR STOP
		RETURN
	END IF
	WHENEVER ERROR STOP
	--}
	LET query = 'SELECT r17_item, r10_nombre, r17_cantrec, r17_fob, ',
			' r17_cantped * r17_fob, r17_orden, r17_cantped, ',
			' r17_estado ',
			'FROM rept017, rept010 ',
	                'WHERE r17_compania = ', vg_codcia,
			' AND r17_localidad = ', vg_codloc,
			' AND r17_pedido    = "', rm_r16.r16_pedido, '"',
			--' AND r17_estado    = "', vm_estado, '"',
			--' AND r17_cantrec   < r17_cantped ',
			' AND r17_compania  = r10_compania ', 
			' AND r17_item      = r10_codigo ',  
			" ORDER BY ", vm_columna_1, ' ', rm_orden[vm_columna_1],
			        ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE det FROM query
	DECLARE q_det CURSOR FOR det
	LET vm_num_repd = 1
        FOREACH q_det INTO rm_repd[vm_num_repd].*, orden, cant, estado
		CALL calcula_cantidad(cant, estado, vm_num_repd)
                LET vm_num_repd = vm_num_repd + 1
                IF vm_num_repd > vm_max_elm THEN
                        EXIT FOREACH
                END IF
        END FOREACH
        LET vm_num_repd = vm_num_repd - 1
	CALL retorna_tam_arr()
	LET vm_scr_lin = vm_size_arr
	CALL sacar_total()
	CALL set_count(vm_num_repd)
	LET int_flag = 0
	DISPLAY ARRAY rm_repd TO rm_repd.*
		ON KEY(RETURN)
			LET i = arr_curr()
	        	LET j = scr_line()
			DISPLAY rm_repd[i].tit_descripcion TO tit_descri
			CALL muestra_clase(i)
		--#BEFORE ROW
			--#LET i = arr_curr()
	        	--#LET j = scr_line()
			--#CALL muestra_contadores_det(i)
			--#DISPLAY rm_repd[i].tit_subtotal
				--#TO rm_repd[j].tit_subtotal
			--#DISPLAY rm_repd[i].tit_descripcion TO tit_descri
			--#CALL muestra_clase(i)
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
		ON KEY(F15)
			LET col = 1
			EXIT DISPLAY
		ON KEY(F16)
			LET col = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET col = 3
			EXIT DISPLAY
		ON KEY(F18)
			LET col = 4
			EXIT DISPLAY
		ON KEY(F19)
			LET col = 5
			EXIT DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		CALL muestra_contadores_det(0)
		--ROLLBACK WORK
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
	--COMMIT WORK
END WHILE

END FUNCTION



FUNCTION calcula_cantidad(cant, estado, i)
DEFINE cant		DECIMAL(8,2)
DEFINE estado		LIKE rept017.r17_estado
DEFINE i		SMALLINT

CASE estado
	WHEN vm_estado
		LET rm_repd[i].r17_cantped = cant - rm_repd[i].r17_cantped
	WHEN 'C'
		LET rm_repd[i].r17_cantped = cant
END CASE

END FUNCTION



FUNCTION muestra_tipo(tipo)
DEFINE tipo		LIKE rept016.r16_tipo

CASE tipo
	WHEN 'S'
		DISPLAY 'SUGERIDO' TO tit_tipo
	WHEN 'E'
		DISPLAY 'EMERGENCIA' TO tit_tipo
	OTHERWISE
		CLEAR r16_tipo, tit_tipo
END CASE

END FUNCTION



FUNCTION muestra_estado()
DEFINE estado		LIKE rept016.r16_estado

LET estado = rm_r16.r16_estado
CASE estado
	WHEN vm_estado
	        DISPLAY 'ACTIVO' TO tit_estado_rep
	WHEN 'C'
       		DISPLAY 'CONFIRMADO' TO tit_estado_rep
	WHEN 'R'
        	DISPLAY 'RECIBIDO' TO tit_estado_rep
	WHEN 'L'
        	DISPLAY 'LIQUIDADO' TO tit_estado_rep
	WHEN 'P'
        	DISPLAY 'PROCESADO' TO tit_estado_rep
	OTHERWISE
		CLEAR r16_estado, tit_estado_rep
END CASE
DISPLAY BY NAME rm_r16.r16_estado

END FUNCTION



FUNCTION muestra_clase(i)
DEFINE i		SMALLINT
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r72		RECORD LIKE rept072.*

CALL fl_lee_item(vg_codcia, rm_repd[i].r17_item) RETURNING r_r10.*
CALL fl_lee_clase_rep(vg_codcia, r_r10.r10_linea, r_r10.r10_sub_linea,
			r_r10.r10_cod_grupo, r_r10.r10_cod_clase)
	RETURNING r_r72.*
DISPLAY r_r72.r72_desc_clase TO tit_clase

END FUNCTION



FUNCTION mostrar_botones_detalle()

--#DISPLAY 'Item'        TO tit_col1
--#DISPLAY 'Descripción' TO tit_col2
--#DISPLAY 'Cant.'       TO tit_col3
--#DISPLAY 'FOB'         TO tit_col4
--#DISPLAY 'Subtotal'    TO tit_col5

END FUNCTION



FUNCTION control_eliminacion()
DEFINE resp		CHAR(6)

IF rm_r16.r16_estado <> 'A' THEN
	--CALL fgl_winmessage(vg_producto,'El estado del pedido debe ser activo.','exclamation')
	CALL fl_mostrar_mensaje('El estado del pedido debe ser activo.','exclamation')
	RETURN
END IF
CALL fl_mensaje_seguro_ejecutar_proceso()
	RETURNING resp
IF resp = 'Yes' THEN
	BEGIN WORK
	DELETE FROM rept017
		WHERE r17_compania  = rm_r16.r16_compania  AND 
		      r17_localidad = rm_r16.r16_localidad AND 
		      r17_pedido    = rm_r16.r16_pedido
	DELETE FROM rept018
		WHERE r18_compania  = rm_r16.r16_compania  AND 
		      r18_localidad = rm_r16.r16_localidad AND 
		      r18_pedido    = rm_r16.r16_pedido
	DELETE FROM rept029
		WHERE r29_compania  = rm_r16.r16_compania  AND 
		      r29_localidad = rm_r16.r16_localidad AND 
		      r29_pedido    = rm_r16.r16_pedido
	DELETE FROM rept016
		WHERE r16_compania  = rm_r16.r16_compania  AND 
		      r16_localidad = rm_r16.r16_localidad AND 
		      r16_pedido    = rm_r16.r16_pedido
	COMMIT WORK
	--CALL fgl_winmessage(vg_producto,'El pedido ha sido eliminado.','info')
	CALL fl_mostrar_mensaje('El pedido ha sido eliminado.','info')
	EXIT PROGRAM
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
	vg_separador, 'fuentes', vg_separador, run_prog, ' repp406 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ',rm_r16.r16_pedido
RUN vm_nuevoprog

END FUNCTION



FUNCTION retorna_tam_arr()

--#LET vm_size_arr = fgl_scr_size('rm_repd')
IF vg_gui = 0 THEN
	LET vm_size_arr = 6
END IF

END FUNCTION



FUNCTION llamar_visor_teclas()
DEFINE a		CHAR(1)

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
DISPLAY '<F5>      Imprimir Listado de Pedidos' AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
