--------------------------------------------------------------------------------
-- Titulo           : repp108.4gl - Mantenimiento de Items 
-- Elaboracion      : 15-sep-2001
-- Autor            : GVA
-- Formato Ejecucion: fglrun repp108 base RE 1 
-- Ultima Correccion: 20-Ago-2002 (NPC)
-- Motivo Correccion: Se aumento el campo r10_filtro a la tabla rept010 y se
--                    aumento la consulta de sustituciones
--		      Se creó otro ON KEY para Ubicación, se agregó la forma
--		      repf108_6.per (RCA).
--		      Se aumentaron rm_sublin, rm_marca. rm_grupo, rm_clase para
--		      ACEROS. por NPC
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_rows		ARRAY[10000] OF INTEGER -- ARREGLO ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO LINEA VTA
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS LINEA VTA
DEFINE vm_r_rows   	ARRAY[10000] OF INTEGER -- ARREGLO ROWID DE FILAS LEIDAS
DEFINE rm_mon		RECORD LIKE gent013.*  	-- MONEDA
DEFINE rm_par		RECORD LIKE gent016.*	-- PARTIDA ARANCELARIA 
DEFINE rm_lin		RECORD LIKE rept003.*	-- LINEA DE VENTA
DEFINE rm_sublin	RECORD LIKE rept070.*	-- SUBLINEA DE VENTA
DEFINE rm_grupo		RECORD LIKE rept071.*	-- GRUPO DE VENTA
DEFINE rm_clase		RECORD LIKE rept072.*	-- CLASE DE VENTA
DEFINE rm_marca		RECORD LIKE rept073.*	-- MARCA DE VENTA
DEFINE rm_item		RECORD LIKE rept010.*	-- MAESTRO ITEMS
DEFINE rm_item2		RECORD LIKE rept010.*	-- AUX. MAESTRO ITEMS
DEFINE rm_uni		RECORD LIKE rept005.*	-- UNIDAD DE MEDIDA
DEFINE rm_rot		RECORD LIKE rept004.*	-- INDICE DE ROTACION
DEFINE rm_titem		RECORD LIKE rept006.*	-- TIPO DE ITEM	
DEFINE rm_conf 		RECORD LIKE gent000.*	-- CONFIGURACION DE FACTURACION
DEFINE rm_cmon 		RECORD LIKE gent014.*	-- CONVERSION ENTRE MONEDAS
DEFINE rm_r00 		RECORD LIKE rept000.*	-- CONFIGURACION DE REPUESTOS
DEFINE rm_prov		RECORD LIKE cxpt001.*	-- PROVEEDORES
DEFINE rm_elec          RECORD LIKE rept074.*	-- CODIGOS ELECTRICOS
DEFINE vm_flag_mant	CHAR(1)
DEFINE vm_max_rows	SMALLINT
DEFINE rm_g04		RECORD LIKE gent004.*
DEFINE rm_g05		RECORD LIKE gent005.*
DEFINE rm_r87		RECORD LIKE rept087.*
DEFINE vm_sustituye	LIKE rept014.r14_item_nue
DEFINE vm_sustituido	LIKE rept014.r14_item_ant
DEFINE vm_stock_inicial	LIKE rept011.r11_stock_act
DEFINE modificar_precio	SMALLINT
DEFINE vm_programa	CHAR(1)
DEFINE vm_clonado	CHAR(1)



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp108.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 AND num_args() <> 6 THEN
	-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vm_max_rows = 10000
LET vg_proceso  = 'repp108'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()

CALL fl_nivel_isolation()
OPEN WINDOW w_item AT 3,2 WITH 21 ROWS, 80 COLUMNS 
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2)
OPEN FORM f_item FROM '../forms/repf108_1'
DISPLAY FORM f_item 

CALL fl_lee_usuario(vg_usuario)            RETURNING rm_g05.*
CALL fl_lee_grupo_usuario(rm_g05.g05_grupo) RETURNING rm_g04.*

INITIALIZE vm_sustituye, vm_sustituido TO NULL

LET vm_clonado     = 'N'
LET vm_num_rows    = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
IF arg_val(5) = 'C' THEN
	CALL control_ingreso()
	CLOSE WINDOW w_item
	IF int_flag THEN
		EXIT PROGRAM -3
	ELSE
		EXIT PROGRAM 0
	END IF
END IF
CLEAR tit_estado
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Existencias'
		HIDE OPTION 'Movimientos'
		HIDE OPTION 'Pedidos'
		HIDE OPTION 'Bloquear/Activar'
		HIDE OPTION 'Sustituye a'
		HIDE OPTION 'Sustituido por'
		HIDE OPTION 'Estadisticas'
		HIDE OPTION 'Ubicación'
		HIDE OPTION 'Usr. Cambio Prec'
		HIDE OPTION 'Clonar Item'
		IF num_args() = 5 THEN
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Modificar'
			HIDE OPTION 'Consultar'
			CALL control_consulta()
			SHOW OPTION 'Existencias'
			SHOW OPTION 'Movimientos'
			SHOW OPTION 'Pedidos'
			IF vm_sustituye IS NOT NULL THEN
				SHOW OPTION 'Sustituye a'
			END IF
			IF vm_sustituido IS NOT NULL THEN
				SHOW OPTION 'Sustituido por'
			END IF
			SHOW OPTION 'Estadisticas'
			SHOW OPTION 'Ubicación'
			SHOW OPTION 'Usr. Cambio Prec'
		END IF
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		HIDE OPTION 'Sustituye a'
		HIDE OPTION 'Sustituido por'
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Bloquear/Activar'
			IF tiene_acceso_clonador() THEN
				SHOW OPTION 'Clonar Item'
			END IF
		END IF
		IF vm_num_rows > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF		
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
		HIDE OPTION 'Estadisticas'
		HIDE OPTION 'Existencias'
		HIDE OPTION 'Movimientos'
		HIDE OPTION 'Pedidos'
		HIDE OPTION 'Usr. Cambio Prec'
	COMMAND KEY('M') 'Modificar' 'Modificar registro corriente'
		IF vm_num_rows > 0 THEN
			CALL control_modificacion()
		ELSE
			CALL fl_mensaje_consultar_primero()
		END IF	
		IF vm_num_rows > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF		
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
        COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		HIDE OPTION 'Sustituye a'
		HIDE OPTION 'Sustituido por'
		HIDE OPTION 'Estadisticas'
                CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Existencias'
			SHOW OPTION 'Movimientos'
			SHOW OPTION 'Pedidos'
			SHOW OPTION 'Ubicación'
			SHOW OPTION 'Usr. Cambio Prec'
			IF tiene_acceso_clonador() THEN
				SHOW OPTION 'Clonar Item'
			END IF
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Bloquear/Activar'
				HIDE OPTION 'Existencias'
				HIDE OPTION 'Movimientos'
				HIDE OPTION 'Pedidos'
				HIDE OPTION 'Ubicación'
				HIDE OPTION 'Usr. Cambio Prec'
				HIDE OPTION 'Clonar Item'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Existencias'
			SHOW OPTION 'Movimientos'
			SHOW OPTION 'Pedidos'
			SHOW OPTION 'Ubicación'
			SHOW OPTION 'Usr. Cambio Prec'
			IF tiene_acceso_clonador() THEN
				SHOW OPTION 'Clonar Item'
			END IF
		END IF
		IF rm_item.r10_estado <> 'S' THEN
			SHOW OPTION 'Bloquear/Activar'
		END IF
		IF vm_sustituye IS NOT NULL THEN
			SHOW OPTION 'Sustituye a'
		END IF
		IF vm_sustituido IS NOT NULL THEN
			SHOW OPTION 'Sustituido por'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Estadisticas'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
	COMMAND KEY('K') 'Movimientos'		'Movimientos del item'
		CALL control_movimientos()
	COMMAND KEY('T') 'Estadisticas'		'Estadisticas de ventas'
		CALL estadisticas()
	COMMAND KEY('E') 'Existencias'		'Consulta existencia del item'
		CALL control_existencias()
	COMMAND KEY('P') 'Pedidos'		'Consulta pedidos del item'
		CALL control_pedidos()
	COMMAND KEY('Y') 'Sustituye a'		'A que items sustituye'
		CALL sustituye()
	COMMAND KEY('O') 'Sustituido por'	'Por que item fue sustituido'
		CALL sustituido()
	COMMAND KEY('U') 'Ubicación'		'Cambio de Ubicación el Item'
		CALL control_ubicacion()
	COMMAND KEY('X') 'Usr. Cambio Prec' 'Consulta Usuarios Cambiaron Precio'
		CALL control_cambio_precio()
	COMMAND KEY('Z') 'Clonar Item'		'Clonar este Item'
		CALL control_clonacion_item()
		IF vm_num_rows > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF		
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
        COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro. '
		HIDE OPTION 'Sustituye a'
		HIDE OPTION 'Sustituido por'
		HIDE OPTION 'Estadisticas'
                IF vm_row_current < vm_num_rows THEN
                        LET vm_row_current = vm_row_current + 1
                END IF
                CALL lee_muestra_registro(vm_r_rows[vm_row_current])
                CALL muestra_contadores(vm_row_current, vm_num_rows)
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE 
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_sustituye IS NOT NULL THEN
			SHOW OPTION 'Sustituye a'
		END IF
		IF vm_sustituido IS NOT NULL THEN
			SHOW OPTION 'Sustituido por'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Estadisticas'
		END IF
        COMMAND KEY('R') 'Retroceder'  'Ver anterior registro. '
		HIDE OPTION 'Sustituye a'
		HIDE OPTION 'Sustituido por'
		HIDE OPTION 'Estadisticas'
                IF vm_row_current > 1 THEN
                        LET vm_row_current = vm_row_current - 1
                END IF
                CALL lee_muestra_registro(vm_r_rows[vm_row_current])
                CALL muestra_contadores(vm_row_current, vm_num_rows)
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE 
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_sustituye IS NOT NULL THEN
			SHOW OPTION 'Sustituye a'
		END IF
		IF vm_sustituido IS NOT NULL THEN
			SHOW OPTION 'Sustituido por'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Estadisticas'
		END IF
	COMMAND KEY('B') 'Bloquear/Activar' 'Bloquear o activar registro. '
		CALL control_bloqueo_activacion()
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)
DEFINE codi_aux         LIKE cxpt001.p01_codprov
DEFINE nom_prov         LIKE cxpt001.p01_nomprov
DEFINE r_utl		RECORD LIKE rept077.*
DEFINE capitulo		LIKE gent016.g16_capitulo

CLEAR FORM
INITIALIZE rm_item.*, codi_aux, capitulo TO NULL
LET int_flag = 0
IF num_args() = 4 THEN
    	CONSTRUCT BY NAME expr_sql ON r10_codigo, r10_estado, r10_nombre,
		r10_linea, r10_sub_linea, r10_cod_grupo, r10_cod_clase,
		r10_marca, r10_tipo, r10_peso, r10_uni_med, r10_cantpaq,
		r10_modelo, r10_partida, r10_fob, r10_monfob,
		r10_filtro, r10_precio_mb, r10_sec_item, r10_paga_impto,
		r10_precio_ma, r10_costo_mb, r10_costo_ma, r10_costult_mb,
		r10_costult_ma, r10_costrepo_mb, r10_usu_cosrepo,
		r10_fec_cosrepo, r10_fec_camprec, r10_cantped, r10_cantback,
		r10_precio_ant, r10_rotacion, r10_stock_max, r10_stock_min,
		r10_proveedor, r10_electrico, r10_cod_pedido, r10_cod_comerc,
		r10_cod_util, r10_vol_cuft, r10_dias_mant, r10_dias_inv,
		r10_cantveh,
		r10_serie_lote, r10_comentarios, r10_usuario, r10_fecing,
		r10_feceli
	ON KEY(F2)
		IF INFIELD(r10_codigo) THEN
			IF rm_item.r10_linea IS NOT NULL THEN
			     	CALL fl_ayuda_maestro_items(vg_codcia,
							    rm_item.r10_linea)
			     		RETURNING rm_item2.r10_codigo,
						  rm_item2.r10_nombre
			ELSE 
			     	CALL fl_ayuda_maestro_items(vg_codcia,'TODOS')
			     		RETURNING rm_item2.r10_codigo,
						  rm_item2.r10_nombre
			END IF
		     	IF rm_item2.r10_codigo IS NOT NULL THEN
				LET rm_item.r10_codigo = rm_item2.r10_codigo
					DISPLAY BY NAME rm_item.r10_codigo
					DISPLAY BY NAME rm_item2.r10_nombre
		     	END IF
		END IF
		IF INFIELD(r10_partida) THEN
			CALL fl_ayuda_partidas(capitulo)
				RETURNING rm_par.g16_partida
			IF rm_par.g16_partida IS NOT NULL THEN
				LET rm_item.r10_partida = rm_par.g16_partida
                    		CALL fl_lee_partida(rm_item.r10_partida)
                                	RETURNING rm_par.*
				DISPLAY BY NAME rm_item.r10_partida
				DISPLAY rm_par.g16_desc_par TO nom_par
			END IF
		END IF
		IF INFIELD(r10_rotacion) THEN
		     CALL fl_ayuda_clases(vg_codcia)
		     RETURNING rm_rot.r04_rotacion, rm_rot.r04_nombre
		     IF rm_rot.r04_rotacion IS NOT NULL THEN
			LET rm_item.r10_rotacion = rm_rot.r04_rotacion
			DISPLAY BY NAME rm_item.r10_rotacion
			DISPLAY rm_rot.r04_nombre TO nom_rot
		     END IF
		END IF
		IF INFIELD(r10_tipo) THEN
		     CALL fl_ayuda_tipo_item()
		     RETURNING rm_titem.r06_codigo, rm_titem.r06_nombre
		     IF rm_titem.r06_codigo IS NOT NULL THEN
		        LET rm_item.r10_tipo = rm_titem.r06_codigo
			DISPLAY BY NAME rm_item.r10_tipo
			DISPLAY rm_titem.r06_nombre TO nom_tipo
		     END IF
		END IF
		IF INFIELD(r10_linea) THEN
		     CALL fl_ayuda_lineas_rep(vg_codcia)
		     RETURNING rm_lin.r03_codigo, rm_lin.r03_nombre
		     IF rm_lin.r03_codigo IS NOT NULL THEN
			LET rm_item.r10_linea = rm_lin.r03_codigo
			DISPLAY BY NAME rm_item.r10_linea
			DISPLAY rm_lin.r03_nombre TO nom_lin
		     END IF
		END IF
	{-- Añadido por NPC --}
		IF INFIELD(r10_sub_linea) THEN
		     CALL fl_ayuda_sublinea_rep(vg_codcia,rm_item.r10_linea)
		     	RETURNING rm_sublin.r70_sub_linea,
			 	  rm_sublin.r70_desc_sub
		     IF rm_sublin.r70_sub_linea IS NOT NULL THEN
			LET rm_item.r10_sub_linea = rm_sublin.r70_sub_linea
			DISPLAY BY NAME rm_item.r10_sub_linea
			DISPLAY rm_sublin.r70_desc_sub TO tit_sub_linea
		     END IF
		END IF
		IF INFIELD(r10_cod_grupo) THEN
		     CALL fl_ayuda_grupo_ventas_rep(vg_codcia,rm_item.r10_linea,
							rm_item.r10_sub_linea)
		     	RETURNING rm_grupo.r71_cod_grupo,
				  rm_grupo.r71_desc_grupo
		     IF rm_grupo.r71_cod_grupo IS NOT NULL THEN
			LET rm_item.r10_cod_grupo = rm_grupo.r71_cod_grupo
			DISPLAY BY NAME rm_item.r10_cod_grupo
			DISPLAY rm_grupo.r71_desc_grupo TO tit_grupo
		     END IF
		END IF
		IF INFIELD(r10_cod_clase) THEN
		     CALL fl_ayuda_clase_ventas_rep(vg_codcia,
				rm_item.r10_linea,rm_item.r10_sub_linea,
				rm_item.r10_cod_grupo)
		     	RETURNING rm_clase.r72_cod_clase,
				  rm_clase.r72_desc_clase
		     IF rm_clase.r72_cod_clase IS NOT NULL THEN
			LET rm_item.r10_cod_clase = rm_clase.r72_cod_clase
			DISPLAY BY NAME rm_item.r10_cod_clase
			DISPLAY rm_clase.r72_desc_clase TO tit_clase
		     END IF
		END IF
		IF INFIELD(r10_marca) THEN
		     CALL fl_ayuda_marcas_rep_asignadas(vg_codcia, rm_item.r10_cod_clase)
		     	RETURNING rm_marca.r73_marca
		     IF rm_marca.r73_marca IS NOT NULL THEN
			LET rm_item.r10_marca = rm_marca.r73_marca
                    	CALL fl_lee_marca_rep(vg_codcia, rm_item.r10_marca)
                    		RETURNING rm_marca.*
			DISPLAY BY NAME rm_item.r10_marca
			DISPLAY rm_marca.r73_desc_marca TO tit_marca
		     END IF
		END IF
	{-- --}
		IF INFIELD(r10_uni_med) THEN
		     CALL fl_ayuda_unidad_medida()
		     RETURNING rm_uni.r05_codigo, rm_uni.r05_siglas
		     IF rm_uni.r05_codigo IS NOT NULL THEN
			LET rm_item.r10_uni_med = rm_uni.r05_codigo
			DISPLAY BY NAME rm_item.r10_uni_med
			DISPLAY rm_uni.r05_siglas TO nom_uni
		     END IF
		END IF
		IF INFIELD(r10_monfob) THEN
		      CALL fl_ayuda_monedas()
			RETURNING rm_mon.g13_moneda, rm_mon.g13_nombre,
				rm_mon.g13_decimales
		      IF rm_mon.g13_moneda IS NOT NULL THEN
		            LET rm_item.r10_monfob = rm_mon.g13_moneda
			    DISPLAY BY NAME rm_item.r10_monfob
			    DISPLAY rm_mon.g13_nombre TO nom_mon
		      END IF
		END IF
                IF INFIELD(r10_proveedor) THEN
                        CALL fl_ayuda_proveedores()
                                RETURNING codi_aux, nom_prov
                        LET int_flag = 0
                        IF codi_aux IS NOT NULL THEN
				LET rm_item.r10_proveedor = codi_aux
                                DISPLAY BY NAME rm_item.r10_proveedor, nom_prov
                        END IF
                END IF
		IF INFIELD(r10_electrico) THEN
                	CALL fl_ayuda_electrico_rep(vg_codcia,'T')
                               	RETURNING rm_elec.r74_electrico,
                               	          rm_elec.r74_descripcion
                       	IF rm_elec.r74_electrico IS NOT NULL THEN
                       		LET rm_item.r10_electrico =rm_elec.r74_electrico
                         	DISPLAY BY NAME rm_item.r10_electrico
                         	DISPLAY rm_elec.r74_descripcion TO elec_desc
                       	END IF
                        LET int_flag = 0
		END IF
		IF INFIELD(r10_cod_util) THEN
			CALL fl_ayuda_factor_utilidad_rep(vg_codcia)
		     		RETURNING r_utl.r77_codigo_util
		     	IF r_utl.r77_codigo_util IS NOT NULL THEN
				LET rm_item.r10_cod_util =
							r_utl.r77_codigo_util
				DISPLAY BY NAME rm_item.r10_cod_util
		     	END IF
		END IF
                LET int_flag = 0
		AFTER FIELD r10_linea
			LET rm_item.r10_linea = get_fldbuf(r10_linea)
                	IF rm_item.r10_linea IS NOT NULL THEN
                    		CALL fl_lee_linea_rep(vg_codcia,
						      rm_item.r10_linea)
                                	RETURNING rm_lin.*
                        	IF rm_lin.r03_codigo IS NULL THEN
					CALL fl_mostrar_mensaje('La Línea de venta no existe en la compañía.','exclamation')
                                	NEXT FIELD r10_linea
                        	END IF
				DISPLAY rm_lin.r03_nombre TO nom_lin
			ELSE 
				CLEAR nom_lin
                	END IF
			LET int_flag = 0
		AFTER FIELD r10_sub_linea
			LET rm_item.r10_sub_linea = get_fldbuf(r10_sub_linea)
			IF rm_item.r10_sub_linea IS NOT NULL THEN
				CALL fl_lee_sublinea_rep(vg_codcia,
						rm_item.r10_linea,
						rm_item.r10_sub_linea)
					RETURNING rm_sublin.*
				IF rm_item.r10_linea IS NOT NULL THEN
					IF rm_item.r10_linea <> rm_sublin.r70_linea THEN
						CALL mensaje_error_sublinea()
					END IF
				END IF
				DISPLAY rm_sublin.r70_desc_sub TO tit_sub_linea
			ELSE
				CLEAR tit_sub_linea
			END IF
			LET int_flag = 0
		AFTER FIELD r10_cod_grupo
			LET rm_item.r10_cod_grupo = get_fldbuf(r10_cod_grupo)
			IF rm_item.r10_cod_grupo IS NOT NULL THEN
				CALL fl_lee_grupo_rep(vg_codcia,
						rm_item.r10_linea,
						rm_item.r10_sub_linea,
						rm_item.r10_cod_grupo)
					RETURNING rm_grupo.*
				IF rm_sublin.r70_sub_linea IS NOT NULL THEN
					IF rm_sublin.r70_sub_linea <> rm_grupo.r71_sub_linea THEN
						CALL mensaje_error_grupo()
					END IF
				END IF
				DISPLAY rm_grupo.r71_desc_grupo TO tit_grupo
			ELSE
				CLEAR tit_grupo
			END IF
			LET int_flag = 0
		AFTER FIELD r10_cod_clase
			LET rm_item.r10_cod_clase = get_fldbuf(r10_cod_clase)
			IF rm_item.r10_cod_clase IS NOT NULL THEN
				CALL fl_lee_clase_rep(vg_codcia,
						rm_item.r10_linea,
						rm_item.r10_sub_linea,
						rm_item.r10_cod_grupo,
						rm_item.r10_cod_clase)
					RETURNING rm_clase.*
				IF rm_grupo.r71_cod_grupo IS NOT NULL THEN
					IF rm_grupo.r71_cod_grupo <> rm_clase.r72_cod_grupo THEN
						CALL mensaje_error_clase()
					END IF
				END IF
				DISPLAY rm_clase.r72_desc_clase TO tit_clase
			ELSE
				CLEAR tit_clase
			END IF
			LET int_flag = 0
		AFTER FIELD r10_marca
			LET rm_item.r10_marca = get_fldbuf(r10_marca)
			IF rm_item.r10_marca IS NOT NULL THEN
				CALL fl_lee_marca_rep(vg_codcia,
						rm_item.r10_marca)
					RETURNING rm_marca.*
				IF rm_marca.r73_marca IS NULL THEN
					CALL fl_mostrar_mensaje('La Marca no existe en la compañía.','exclamation')
					NEXT FIELD r10_marca
				END IF
				DISPLAY rm_marca.r73_desc_marca TO tit_marca
			ELSE
				CLEAR tit_marca
			END IF
			LET int_flag = 0
		AFTER FIELD r10_partida
			LET rm_item.r10_partida = get_fldbuf(r10_partida)
			IF rm_item.r10_partida IS NOT NULL THEN
				CALL fl_lee_partida(rm_item.r10_partida)
					RETURNING rm_par.*
				IF rm_par.g16_partida IS NULL THEN
					CALL fl_mostrar_mensaje('La Partida Arancelaria no existe en la compañía.','exclamation')
					NEXT FIELD r10_partida
				END IF
				DISPLAY rm_par.g16_desc_par TO nom_par
			ELSE
				CLEAR nom_par
			END IF
			LET int_flag = 0
	END CONSTRUCT
	IF int_flag THEN
		CLEAR FORM
		IF vm_num_rows >0 THEN
			CALL lee_muestra_registro(vm_r_rows[vm_row_current])
		END IF
		CALL muestra_contadores(vm_row_current, vm_num_rows)
		RETURN
	END IF
ELSE
	LET expr_sql = "r10_codigo = '", arg_val(5) CLIPPED, "'"
END IF
LET query = 'SELECT *, ROWID FROM rept010 ',
		' WHERE r10_compania = ', vg_codcia,
		'   AND ', expr_sql CLIPPED,
		' ORDER BY r10_sec_item'
PREPARE cons FROM query
DECLARE q_item CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_item INTO rm_item.*, vm_r_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	IF num_args() = 5 THEN
		EXIT PROGRAM
	END IF
	LET vm_row_current = 0
	CALL muestra_contadores(vm_row_current, vm_num_rows)
        CLEAR FORM
        RETURN
END IF
LET vm_row_current = 1
CALL lee_muestra_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION control_ingreso()
DEFINE cod_item		INTEGER
DEFINE r_g13		RECORD LIKE gent013.*

CLEAR FORM
INITIALIZE rm_item.*, rm_lin.*, rm_uni.*, rm_titem.*, rm_par.*, rm_rot.* TO NULL
LET vm_flag_mant           = 'I'
LET rm_item.r10_compania   = vg_codcia
LET rm_item.r10_estado     = 'A'
LET rm_item.r10_usuario    = vg_usuario
LET rm_item.r10_fecing     = fl_current()
LET rm_item.r10_paga_impto = 'S'
LET rm_item.r10_cantped    = 0
LET rm_item.r10_cantback   = 0
LET rm_item.r10_costo_mb   = 0
LET rm_item.r10_costo_ma   = 0
LET rm_item.r10_costult_mb = 0
LET rm_item.r10_costult_ma = 0
LET rm_item.r10_precio_ma  = 0
LET rm_item.r10_sec_item   = 0

DISPLAY BY NAME rm_item.r10_usuario, rm_item.r10_fecing, rm_item.r10_estado,
		rm_item.r10_costo_mb, rm_item.r10_costo_ma, 
		rm_item.r10_cantped, rm_item.r10_cantback, 
		rm_item.r10_costult_mb, rm_item.r10_costult_ma, 
		rm_item.r10_paga_impto, rm_item.r10_precio_ma,
		rm_item.r10_sec_item

CALL muestra_estado()
CALL lee_datos()
IF NOT int_flag THEN
	BEGIN WORK
		CALL retorna_sec_cod_item() RETURNING cod_item
		LET rm_item.r10_codigo = cod_item
		LET rm_item.r10_fecing = fl_current()
		IF num_args() <> 4 THEN
			IF arg_val(5) = 'C' THEN
				LET rm_item.r10_costo_mb    = -0.01
				LET rm_item.r10_estado      = 'B'
				LET rm_item.r10_comentarios = arg_val(6)
			END IF
		END IF
		INSERT INTO rept010 VALUES(rm_item.*)
	        IF vm_num_rows = vm_max_rows THEN
        	        LET vm_num_rows = 1
	        ELSE
        	        LET vm_num_rows = vm_num_rows + 1
	        END IF
		LET vm_r_rows[vm_num_rows] = SQLCA.SQLERRD[6] 
		LET vm_row_current = vm_num_rows
		INSERT INTO rept011
		      (r11_compania, r11_bodega, r11_item, r11_ubicacion,
		       r11_stock_ant, r11_stock_act, r11_ing_dia, r11_egr_dia)
		  VALUES(vg_codcia, rm_r00.r00_bodega_fact,rm_item.r10_codigo,
		       'SN',0,0,0,0)
	COMMIT WORK
	CALL fl_mensaje_registro_ingresado()
END IF
IF vm_num_rows > 0 THEN
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION control_modificacion()

LET vm_flag_mant      = 'M'
IF rm_item.r10_estado = 'B' THEN
	IF rm_item.r10_costult_mb <> 0 OR rm_item.r10_precio_mb <> 0 OR
	   rm_item.r10_usuario <> vg_usuario
	THEN
		CALL fl_mensaje_estado_bloqueado()
		RETURN
	END IF
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR 
	SELECT * FROM rept010 WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_item.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
LET rm_item2.r10_precio_mb = rm_item.r10_precio_mb
CALL lee_datos()
IF int_flag THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	RETURN
END IF
CALL cambio_modificacion()
UPDATE rept010 SET * = rm_item.* WHERE CURRENT OF q_up
IF rm_item.r10_fec_camprec IS NOT NULL THEN
	IF DATE(rm_item.r10_fec_camprec) >= vg_fecha THEN
		CALL usuario_camprec()
	END IF
END IF
COMMIT WORK
CLEAR vm_row_current1
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION lee_datos()
DEFINE resp 		VARCHAR(6)
DEFINE linea		LIKE rept010.r10_linea
DEFINE r_r48		RECORD LIKE rept048.*
DEFINE r_utl		RECORD LIKE rept077.*
DEFINE costo_mb		LIKE rept010.r10_costo_mb
DEFINE capitulo		LIKE gent016.g16_capitulo
DEFINE cod_comerc	LIKE rept010.r10_cod_comerc

LET modificar_precio = 0
LET capitulo = NULL
LET int_flag = 0
INPUT BY NAME rm_item.r10_codigo, rm_item.r10_nombre, rm_item.r10_linea,
	rm_item.r10_sub_linea, rm_item.r10_cod_grupo, rm_item.r10_cod_clase,
	rm_item.r10_marca, rm_item.r10_tipo, rm_item.r10_peso,
	rm_item.r10_uni_med, rm_item.r10_cantpaq, rm_item.r10_modelo,
	rm_item.r10_sec_item, rm_item.r10_partida, rm_item.r10_fob,
	rm_item.r10_monfob, rm_item.r10_filtro, rm_item.r10_precio_mb,
	rm_item.r10_paga_impto, rm_item.r10_precio_ma, rm_item.r10_costo_mb,
	rm_item.r10_costo_ma, rm_item.r10_costult_mb, rm_item.r10_costult_ma,
	rm_item.r10_costrepo_mb, rm_item.r10_precio_ant, rm_item.r10_rotacion,
	rm_item.r10_fec_camprec, rm_item.r10_stock_max, rm_item.r10_stock_min,
	rm_item.r10_proveedor, rm_item.r10_electrico, rm_item.r10_cod_pedido,
	rm_item.r10_cod_comerc, rm_item.r10_cod_util, rm_item.r10_vol_cuft,
	rm_item.r10_dias_mant, rm_item.r10_dias_inv, rm_item.r10_cantveh,
	rm_item.r10_serie_lote,	rm_item.r10_comentarios
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_item.r10_codigo, rm_item.r10_nombre,
				 rm_item.r10_linea, rm_item.r10_sub_linea,
				 rm_item.r10_cod_grupo, rm_item.r10_cod_clase,
				 rm_item.r10_marca, rm_item.r10_tipo,
				 rm_item.r10_peso, rm_item.r10_uni_med,
				 rm_item.r10_cantpaq, rm_item.r10_modelo,
				 rm_item.r10_sec_item, rm_item.r10_partida,
				 rm_item.r10_fob, rm_item.r10_monfob,
				 rm_item.r10_filtro, rm_item.r10_precio_mb,
				 rm_item.r10_paga_impto, rm_item.r10_precio_ma,
		      		 rm_item.r10_costo_mb, rm_item.r10_costo_ma,
				 rm_item.r10_costult_mb, rm_item.r10_costult_ma,
				 rm_item.r10_costrepo_mb,rm_item.r10_precio_ant,
				 rm_item.r10_rotacion, rm_item.r10_fec_camprec,
		      		 rm_item.r10_stock_max, rm_item.r10_stock_min,
				 rm_item.r10_proveedor, rm_item.r10_electrico,
		      		 rm_item.r10_cod_pedido, rm_item.r10_cod_comerc,
				 rm_item.r10_cod_util, rm_item.r10_vol_cuft,
				 rm_item.r10_dias_mant, rm_item.r10_dias_inv,
				 rm_item.r10_cantveh, rm_item.r10_serie_lote,
				 rm_item.r10_comentarios)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				IF vm_flag_mant = 'I' THEN
					CLEAR FORM
				END IF
				EXIT INPUT
			END IF
		ELSE
			IF vm_flag_mant = 'I' THEN
				CLEAR FORM
			END IF
			EXIT INPUT
		END IF
	ON KEY(F2)
		IF INFIELD(r10_partida) THEN
			CALL fl_ayuda_partidas(capitulo)
				RETURNING rm_par.g16_partida
			IF rm_par.g16_partida IS NOT NULL THEN
				LET rm_item.r10_partida = rm_par.g16_partida
                    		CALL fl_lee_partida(rm_item.r10_partida)
                                	RETURNING rm_par.*
				DISPLAY BY NAME rm_item.r10_partida
				DISPLAY rm_par.g16_desc_par TO nom_par
			END IF
		END IF
		IF INFIELD(r10_rotacion) THEN
		     CALL fl_ayuda_clases(vg_codcia)
		     RETURNING rm_rot.r04_rotacion, rm_rot.r04_nombre
		     IF rm_rot.r04_rotacion IS NOT NULL THEN
			LET rm_item.r10_rotacion = rm_rot.r04_rotacion
			DISPLAY BY NAME rm_item.r10_rotacion
			DISPLAY rm_rot.r04_nombre TO nom_rot
		     END IF
		END IF
		IF INFIELD(r10_tipo) THEN
		     CALL fl_ayuda_tipo_item()
		     RETURNING rm_titem.r06_codigo, rm_titem.r06_nombre
		     IF rm_titem.r06_codigo IS NOT NULL THEN
		        LET rm_item.r10_tipo = rm_titem.r06_codigo
			DISPLAY BY NAME rm_item.r10_tipo
			DISPLAY rm_titem.r06_nombre TO nom_tipo
		     END IF
		END IF
		IF INFIELD(r10_linea) THEN
		     CALL fl_ayuda_lineas_rep(vg_codcia)
		     	RETURNING rm_lin.r03_codigo, rm_lin.r03_nombre
		     IF rm_lin.r03_codigo IS NOT NULL THEN
			LET rm_item.r10_linea = rm_lin.r03_codigo
			DISPLAY BY NAME rm_item.r10_linea
			DISPLAY rm_lin.r03_nombre TO nom_lin
		     END IF
		END IF
	{-- Añadido por NPC --}
		IF INFIELD(r10_sub_linea) THEN
		     CALL fl_ayuda_sublinea_rep(vg_codcia,rm_item.r10_linea)
		     	RETURNING rm_sublin.r70_sub_linea,
			 	  rm_sublin.r70_desc_sub
		     IF rm_sublin.r70_sub_linea IS NOT NULL THEN
			LET rm_item.r10_sub_linea = rm_sublin.r70_sub_linea
			DISPLAY BY NAME rm_item.r10_sub_linea
			DISPLAY rm_sublin.r70_desc_sub TO tit_sub_linea
		     END IF
		END IF
		IF INFIELD(r10_cod_grupo) THEN
		     CALL fl_ayuda_grupo_ventas_rep(vg_codcia,rm_item.r10_linea,
							rm_item.r10_sub_linea)
		     	RETURNING rm_grupo.r71_cod_grupo,
				  rm_grupo.r71_desc_grupo
		     IF rm_grupo.r71_cod_grupo IS NOT NULL THEN
			LET rm_item.r10_cod_grupo = rm_grupo.r71_cod_grupo
			DISPLAY BY NAME rm_item.r10_cod_grupo
			DISPLAY rm_grupo.r71_desc_grupo TO tit_grupo
		     END IF
		END IF
		IF INFIELD(r10_cod_clase) THEN
		     CALL fl_ayuda_clase_ventas_rep(vg_codcia,
				rm_item.r10_linea,rm_item.r10_sub_linea,
				rm_item.r10_cod_grupo)
		     	RETURNING rm_clase.r72_cod_clase,
				  rm_clase.r72_desc_clase
		     IF rm_clase.r72_cod_clase IS NOT NULL THEN
			LET rm_item.r10_cod_clase = rm_clase.r72_cod_clase
			DISPLAY BY NAME rm_item.r10_cod_clase
			DISPLAY rm_clase.r72_desc_clase TO tit_clase
		     END IF
		END IF
		IF INFIELD(r10_marca) THEN
		     CALL fl_ayuda_marcas_rep_asignadas(vg_codcia, rm_item.r10_cod_clase)
		     	RETURNING rm_marca.r73_marca
		     IF rm_marca.r73_marca IS NOT NULL THEN
			LET rm_item.r10_marca = rm_marca.r73_marca
                    	CALL fl_lee_marca_rep(vg_codcia, rm_item.r10_marca)
                    		RETURNING rm_marca.*
			DISPLAY BY NAME rm_item.r10_marca
			DISPLAY rm_marca.r73_desc_marca TO tit_marca
		     END IF
		END IF
		IF INFIELD(r10_cod_util) THEN
			CALL fl_ayuda_factor_utilidad_rep(vg_codcia)
		     		RETURNING r_utl.r77_codigo_util
		     	IF r_utl.r77_codigo_util IS NOT NULL THEN
				LET rm_item.r10_cod_util =
							r_utl.r77_codigo_util
				DISPLAY BY NAME rm_item.r10_cod_util
		     	END IF
		END IF
	{-- --}
                IF INFIELD(r10_proveedor) THEN
                        CALL fl_ayuda_proveedores()
                                RETURNING rm_prov.p01_codprov, 	
					  rm_prov.p01_nomprov
		     IF rm_prov.p01_codprov IS NOT NULL THEN
			LET rm_item.r10_proveedor = rm_prov.p01_codprov
			DISPLAY BY NAME rm_item.r10_proveedor
			DISPLAY rm_prov.p01_nomprov TO nom_prov
		     END IF
                END IF

                IF INFIELD(r10_electrico) THEN
                	CALL fl_ayuda_electrico_rep(vg_codcia,'T')
                               	RETURNING rm_elec.r74_electrico,
                               	          rm_elec.r74_descripcion
                       	IF rm_elec.r74_electrico IS NOT NULL THEN
                       		LET rm_item.r10_electrico =rm_elec.r74_electrico
                        	DISPLAY BY NAME rm_item.r10_electrico
                         	DISPLAY rm_elec.r74_descripcion TO elec_desc
                       	END IF
                        LET int_flag = 0
                END IF
		IF INFIELD(r10_uni_med) THEN
		     CALL fl_ayuda_unidad_medida()
		     RETURNING rm_uni.r05_codigo, rm_uni.r05_siglas
		     IF rm_uni.r05_codigo IS NOT NULL THEN
			LET rm_item.r10_uni_med = rm_uni.r05_codigo
			DISPLAY BY NAME rm_item.r10_uni_med
			DISPLAY rm_uni.r05_siglas TO nom_uni
		     END IF
		END IF
		IF INFIELD(r10_monfob) THEN
		      CALL fl_ayuda_monedas()
			RETURNING rm_mon.g13_moneda, rm_mon.g13_nombre,
				rm_mon.g13_decimales
		      IF rm_mon.g13_moneda IS NOT NULL THEN
		            LET rm_item.r10_monfob = rm_mon.g13_moneda
			    DISPLAY BY NAME rm_item.r10_monfob
			    DISPLAY rm_mon.g13_nombre TO nom_mon
		      END IF
		END IF
		LET int_flag = 0
	BEFORE  FIELD r10_codigo
		IF vm_flag_mant = 'M' THEN
			NEXT FIELD NEXT
		END IF
	BEFORE FIELD r10_cod_comerc
		IF vm_flag_mant <> 'I' THEN
			LET cod_comerc = rm_item.r10_cod_comerc
		END IF
	AFTER FIELD r10_codigo
		IF rm_item.r10_codigo IS NOT NULL THEN
			CALL fl_lee_item(vg_codcia, rm_item.r10_codigo)
				RETURNING rm_item2.*
			IF rm_item2.r10_codigo IS NOT NULL THEN
				CALL fl_mostrar_mensaje('Ya existe el Item en la Compañía.','exclamation')
				NEXT FIELD r10_codigo
			END IF
		END IF
	AFTER FIELD r10_tipo
                IF rm_item.r10_tipo IS NOT NULL THEN
                    CALL fl_lee_tipo_item(rm_item.r10_tipo)
                                RETURNING rm_titem.*
                        IF rm_titem.r06_codigo IS NULL THEN
				CALL fl_mostrar_mensaje('El Tipo de Item no existe en la compañía.','exclamation')
                                NEXT FIELD r10_tipo
                        END IF
			DISPLAY rm_titem.r06_nombre TO nom_tipo
		ELSE
			CLEAR nom_tipo
                END IF
	AFTER FIELD r10_linea
	        IF rm_item.r10_linea IS NOT NULL THEN
        		CALL fl_lee_linea_rep(vg_codcia, rm_item.r10_linea)
                		RETURNING rm_lin.*
                       	IF rm_lin.r03_codigo IS NULL THEN
				CALL fl_mostrar_mensaje('La Línea de venta no existe en la compañía.','exclamation')
                               	NEXT FIELD r10_linea
               	        END IF
			IF rm_lin.r03_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
                               	NEXT FIELD r10_linea
			END IF
			DISPLAY rm_lin.r03_nombre TO nom_lin
		ELSE 
			CLEAR nom_lin
               	END IF
	{-- Añadido por NPC --}
	AFTER FIELD r10_sub_linea
                IF rm_item.r10_sub_linea IS NOT NULL THEN
                    CALL fl_lee_sublinea_rep(vg_codcia,rm_item.r10_linea,
						rm_item.r10_sub_linea)
                    	RETURNING rm_sublin.*
                    IF rm_sublin.r70_sub_linea IS NULL THEN
			CALL fl_mostrar_mensaje('La Sublínea de venta no existe en la compañía.','exclamation')
                    	NEXT FIELD r10_sub_linea
                    END IF
		    IF rm_item.r10_linea IS NOT NULL THEN
			IF rm_item.r10_linea <> rm_sublin.r70_linea THEN
				CALL mensaje_error_sublinea()
			END IF
		     END IF
		     DISPLAY rm_sublin.r70_desc_sub TO tit_sub_linea
		ELSE 
		     CLEAR tit_sub_linea
                END IF
	AFTER FIELD r10_cod_grupo
                IF rm_item.r10_cod_grupo IS NOT NULL THEN
                    CALL fl_lee_grupo_rep(vg_codcia,rm_item.r10_linea,
				rm_item.r10_sub_linea,rm_item.r10_cod_grupo)
                    	RETURNING rm_grupo.*
                    IF rm_grupo.r71_cod_grupo IS NULL THEN
			CALL fl_mostrar_mensaje('El Grupo no existe en la compañía.','exclamation')
                        NEXT FIELD r10_cod_grupo
                    END IF
		    IF rm_sublin.r70_sub_linea IS NOT NULL THEN
			IF rm_sublin.r70_sub_linea <> rm_grupo.r71_sub_linea
			THEN
				CALL mensaje_error_grupo()
			END IF
		     END IF
		     DISPLAY rm_grupo.r71_desc_grupo TO tit_grupo
		ELSE 
		     CLEAR tit_grupo
                END IF
	AFTER FIELD r10_cod_clase
                IF rm_item.r10_cod_clase IS NOT NULL THEN
                    	CALL fl_lee_clase_rep(vg_codcia,
				rm_item.r10_linea,rm_item.r10_sub_linea,
				rm_item.r10_cod_grupo,rm_item.r10_cod_clase)
                    	RETURNING rm_clase.*
                    IF rm_clase.r72_cod_clase IS NULL THEN
			CALL fl_mostrar_mensaje('La Clase no existe en la compañía.','exclamation')
                        NEXT FIELD r10_cod_clase
                    END IF
		    IF rm_grupo.r71_cod_grupo IS NOT NULL THEN
			IF rm_grupo.r71_cod_grupo <> rm_clase.r72_cod_grupo
			THEN
				CALL mensaje_error_clase()
			END IF
		     END IF
		     DISPLAY rm_clase.r72_desc_clase TO tit_clase
		ELSE 
		     CLEAR tit_clase
                END IF
	AFTER FIELD r10_marca
                IF rm_item.r10_marca IS NOT NULL THEN
                    CALL fl_lee_marca_rep(vg_codcia, rm_item.r10_marca)
                    	RETURNING rm_marca.*
                    IF rm_marca.r73_marca IS NULL THEN
			CALL fl_mostrar_mensaje('La Marca no existe en la compañía.','exclamation')
                        NEXT FIELD r10_marca
                    END IF
		    DISPLAY rm_marca.r73_desc_marca TO tit_marca
		ELSE 
		    CLEAR tit_marca
                END IF
	{-- --}
	AFTER FIELD r10_proveedor
        	IF rm_item.r10_proveedor IS NOT NULL THEN
                	CALL fl_lee_proveedor(rm_item.r10_proveedor)
                    		RETURNING rm_prov.*
                	IF rm_prov.p01_codprov IS NULL THEN
				CALL fl_mostrar_mensaje('No existe proveedor: ' || rm_prov.p01_codprov,'exclamation')
                        	NEXT FIELD r10_proveedor
                    	END IF
			IF rm_prov.p01_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
                        	NEXT FIELD r10_proveedor
			END IF
		    	DISPLAY rm_prov.p01_nomprov TO nom_prov
		ELSE 
			CLEAR nom_prov
		END IF
	BEFORE FIELD r10_electrico
		IF vm_flag_mant = 'I' THEN
			CALL fl_mostrar_mensaje('El código eléctrico dede ingresarlo cuando esté en la opción de modificación.','info')
			LET rm_item.r10_electrico = NULL
			CONTINUE INPUT
		END IF
	AFTER FIELD r10_electrico
		IF vm_flag_mant = 'M' THEN
			IF rm_item.r10_electrico IS NOT NULL THEN
				CALL fl_lee_electrico_rep(vg_codcia,
							rm_item.r10_electrico)
					RETURNING rm_elec.*
				IF rm_elec.r74_compania IS NULL THEN
					CALL fl_mostrar_mensaje('No existe ese código eléctrico para este ítem.','exclamation')
					NEXT FIELD r10_electrico
				END IF
				IF rm_elec.r74_estado = 'E' THEN
					CALL fl_mostrar_mensaje('Este código eléctrico ha sido eliminado.','exclamation')
					NEXT FIELD r10_electrico
				END IF
				DISPLAY rm_elec.r74_descripcion TO elec_desc
			ELSE
				CLEAR elec_desc
			END IF
		ELSE
			CLEAR r10_electrico, elec_desc
		END IF
	AFTER FIELD r10_uni_med
                IF rm_item.r10_uni_med IS NOT NULL THEN
                    CALL fl_lee_unidad_medida(rm_item.r10_uni_med)
                                RETURNING rm_uni.*
                        IF rm_uni.r05_codigo IS NULL THEN
				CALL fl_mostrar_mensaje('La Unidad de Medida no existe en la compañía.','exclamation')
                                NEXT FIELD r10_uni_med
                        END IF
			DISPLAY rm_uni.r05_siglas TO nom_uni
		ELSE
			CLEAR nom_uni
                END IF
	AFTER FIELD r10_partida
                IF rm_item.r10_partida IS NOT NULL THEN
                    CALL fl_lee_partida(rm_item.r10_partida)
                                RETURNING rm_par.*
                        IF rm_par.g16_partida IS NULL THEN
				CALL fl_mostrar_mensaje('La Partida Arancelaria no existe en la compañía.','exclamation')
                                NEXT FIELD r10_partida
                        END IF
			DISPLAY rm_par.g16_desc_par TO nom_par
		ELSE
			CLEAR nom_par
                END IF
	AFTER FIELD r10_rotacion
                IF rm_item.r10_rotacion IS NOT NULL THEN
                    CALL fl_lee_indice_rotacion(vg_codcia, rm_item.r10_rotacion)
                                RETURNING rm_rot.*
                        IF rm_rot.r04_rotacion IS NULL THEN
				CALL fl_mostrar_mensaje('El Indice de Rotación no existe en la compañía.','exclamation')
                                NEXT FIELD r10_rotacion
                        END IF
			DISPLAY rm_rot.r04_nombre TO nom_rot
		ELSE 
			CLEAR nom_rot
                END IF
	AFTER FIELD r10_monfob
                IF rm_item.r10_monfob IS NOT NULL THEN
                    CALL fl_lee_moneda(rm_item.r10_monfob)
                                RETURNING rm_mon.*
                        IF rm_mon.g13_moneda IS NULL THEN
				CALL fl_mostrar_mensaje('La Moneda no existe en la compañía.','exclamation')
                                NEXT FIELD r10_monfob
                        END IF
			DISPLAY rm_mon.g13_nombre TO nom_mon
		ELSE 
			CLEAR nom_mon
                END IF
	AFTER FIELD r10_precio_mb
		IF rm_item.r10_precio_mb IS NOT NULL THEN
			LET rm_item.r10_precio_mb = 
			    fl_retorna_precision_valor(rg_gen.g00_moneda_base, 
						     rm_item.r10_precio_mb)
			IF vm_flag_mant = 'I' THEN
			      LET rm_item.r10_precio_ant = rm_item.r10_precio_mb
			      DISPLAY BY NAME rm_item.r10_precio_ant
			END IF
			IF rm_item2.r10_precio_mb <> rm_item.r10_precio_mb
			AND vm_flag_mant = 'M'
			THEN
				LET modificar_precio = 1
				LET rm_item.r10_precio_ant  =
							rm_item2.r10_precio_mb
				LET rm_item.r10_fec_camprec = fl_current()
				DISPLAY BY NAME rm_item.r10_fec_camprec
				DISPLAY BY NAME rm_item.r10_precio_ant
			END IF
			IF rg_gen.g00_moneda_alt IS NOT NULL OR 
			   rg_gen.g00_moneda_alt <> ' '
			   THEN
				CALL fl_lee_factor_moneda(rg_gen.g00_moneda_base, rg_gen.g00_moneda_alt)
					RETURNING rm_cmon.*
				IF rm_cmon.g14_serial IS NOT NULL THEN
					LET rm_item.r10_precio_ma = 
				   	    rm_item.r10_precio_mb *
					    rm_cmon.g14_tasa
				END IF
			END IF
			INITIALIZE r_r48.* TO NULL
			DECLARE q_comp CURSOR FOR
				SELECT * FROM rept048
					WHERE r48_compania  = vg_codcia
					  AND r48_localidad = vg_codloc
					  AND r48_item_comp = rm_item.r10_codigo
					ORDER BY r48_sec_carga DESC
			OPEN q_comp
			FETCH q_comp INTO r_r48.*
			CLOSE q_comp
			FREE q_comp
			IF r_r48.r48_compania IS NOT NULL THEN
				IF (rm_item.r10_costo_mb + r_r48.r48_costo_mo)
				 >= rm_item.r10_precio_mb
				THEN
					CALL fl_mostrar_mensaje('El Precio digitado esta por debajo, del costo promedio mas la mano de obra de éste ítem.','exclamation')
					NEXT FIELD r10_precio_mb
				END IF
			END IF
			IF rm_item.r10_precio_ma IS NULL THEN
				CALL fl_mostrar_mensaje('Precio digitado es demasiado grande','exclamation')
				NEXT FIELD r10_precio_mb
			END IF
			DISPLAY BY NAME rm_item.r10_precio_ma
		END IF
	BEFORE FIELD r10_costo_mb
		IF vm_flag_mant = 'M' THEN
			LET costo_mb = rm_item.r10_costo_mb
		END IF
	AFTER FIELD r10_costo_mb
		IF vm_flag_mant <> 'I' THEN
			IF tiene_stock(costo_mb) THEN
				LET rm_item.r10_costo_mb = costo_mb
			END IF
		END IF
		DISPLAY BY NAME rm_item.r10_costo_mb
	AFTER FIELD r10_cod_comerc
		IF vm_flag_mant <> 'I' AND cod_comerc IS NOT NULL THEN
			LET rm_item.r10_cod_comerc = cod_comerc
			DISPLAY BY NAME rm_item.r10_cod_comerc
		END IF
	AFTER INPUT 
		CALL fl_lee_compania_repuestos(vg_codcia)
                	RETURNING rm_r00.*
                IF rm_r00.r00_compania IS NULL THEN
			CALL fl_mostrar_mensaje('No existe configuración de repuestos para la compañía.','exclamation')
                        NEXT FIELD r10_codigo
                END IF
                CALL fl_lee_sublinea_rep(vg_codcia,rm_item.r10_linea,
						rm_item.r10_sub_linea)
                	RETURNING rm_sublin.*
		IF rm_sublin.r70_compania IS NULL THEN
			CALL mensaje_error_sublinea()
                       	NEXT FIELD r10_sub_linea
		END IF
                CALL fl_lee_grupo_rep(vg_codcia,rm_item.r10_linea,
				rm_item.r10_sub_linea,rm_item.r10_cod_grupo)
                    	RETURNING rm_grupo.*
		IF rm_grupo.r71_compania IS NULL THEN
			CALL mensaje_error_grupo()
                       	NEXT FIELD r10_cod_grupo
		END IF
                CALL fl_lee_clase_rep(vg_codcia,rm_item.r10_linea,
				rm_item.r10_sub_linea,rm_item.r10_cod_grupo,
				rm_item.r10_cod_clase)
                	RETURNING rm_clase.*
		IF rm_clase.r72_compania IS NULL THEN
			CALL mensaje_error_clase()
                       	NEXT FIELD r10_cod_clase
		END IF
		IF rm_item.r10_cod_util IS NOT NULL THEN
			CALL fl_lee_factor_utilidad_rep(vg_codcia,
							rm_item.r10_cod_util)
				RETURNING r_utl.*
			IF r_utl.r77_codigo_util IS NULL THEN
				CALL fl_mostrar_mensaje('El Factor de Utilidad no existe en esta Compañía.','exclamation')
				NEXT FIELD r10_cod_util
               		END IF
              	END IF
		IF rm_item.r10_stock_max IS NOT NULL THEN
			IF rm_item.r10_stock_max < rm_item.r10_stock_min THEN
				CALL fl_mostrar_mensaje('El Stock Máximo debe ser mayor o igual al Stock Mínimo.','exclamation')
				NEXT FIELD r10_stock_max
			END IF
		END IF
		IF rm_item.r10_cod_util IS NULL THEN
			NEXT FIELD r10_cod_util
		END IF
END INPUT

END FUNCTION



FUNCTION mensaje_error_sublinea()

CALL fl_mostrar_mensaje('La Sublínea no pertenece a la Línea de venta.','exclamation')

END FUNCTION



FUNCTION mensaje_error_grupo()

CALL fl_mostrar_mensaje('El Grupo no pertenece a la Sublínea de venta.','exclamation')

END FUNCTION



FUNCTION mensaje_error_clase()

CALL fl_mostrar_mensaje('La Clase no pertenece al Grupo.','exclamation')

END FUNCTION



FUNCTION control_bloqueo_activacion()
DEFINE resp    	CHAR(6)
DEFINE i	SMALLINT
DEFINE mensaje	VARCHAR(20)
DEFINE estado	LIKE rept010.r10_estado

DEFINE fecha_actual DATETIME YEAR TO SECOND

LET int_flag = 0
IF rm_item.r10_codigo IS NULL OR vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
IF rm_item.r10_estado = 'S' THEN
	CALL fl_mostrar_mensaje('El registro se encuentra sustituido.','exclamation')
	RETURN
END IF 
IF rm_item.r10_costo_mb < 0 THEN
	CALL fl_mostrar_mensaje('Este ítem es para componer.\n No puede DESBLOQUEARLO.','exclamation')
	RETURN
END IF 
CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
IF resp = 'Yes' THEN
	BEGIN WORK
	WHENEVER ERROR CONTINUE
	DECLARE q_del CURSOR FOR SELECT * FROM rept010 
		WHERE ROWID = vm_r_rows[vm_row_current]
		FOR UPDATE
	OPEN q_del
	FETCH q_del INTO rm_item.*
	IF status < 0 THEN
		ROLLBACK WORK
		CALL fl_mensaje_bloqueo_otro_usuario()
		WHENEVER ERROR STOP
		RETURN
	END IF
	WHENEVER ERROR CONTINUE
	LET estado = 'B'
	IF rm_item.r10_estado <> 'A' THEN
		LET estado = 'A'
	END IF
	CASE estado 
		WHEN 'B'
			LET fecha_actual = fl_current()
			UPDATE rept010 SET r10_estado = estado,
					   r10_feceli = fecha_actual
			WHERE CURRENT OF q_del
		WHEN 'A'
			UPDATE rept010 SET r10_estado = estado,
					   r10_feceli = ''
			WHERE CURRENT OF q_del
	END CASE
	IF STATUS < 0 THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No se pudo cambiar el estado del item, esta siendo bloqueado por otro usuario.', 'exclamation')
		WHENEVER ERROR STOP
		RETURN
	END IF
	WHENEVER ERROR STOP
	COMMIT WORK
	LET int_flag = 1
	CALL fl_mensaje_registro_modificado()
	CLEAR FORM	
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER
DEFINE r_prov		RECORD LIKE cxpt001.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_item.* FROM rept010 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
DISPLAY BY NAME rm_item.r10_codigo, rm_item.r10_estado, rm_item.r10_nombre,
		rm_item.r10_linea, rm_item.r10_sub_linea, rm_item.r10_cod_grupo,
		rm_item.r10_cod_clase, rm_item.r10_marca, rm_item.r10_tipo,
		rm_item.r10_peso, rm_item.r10_uni_med, rm_item.r10_cantpaq,
		rm_item.r10_cantveh, rm_item.r10_modelo, rm_item.r10_partida,
		rm_item.r10_fob, rm_item.r10_monfob, rm_item.r10_filtro,
		rm_item.r10_precio_mb, rm_item.r10_paga_impto,
		rm_item.r10_precio_ma, rm_item.r10_costo_mb,
		rm_item.r10_costo_ma, rm_item.r10_costult_mb,
		rm_item.r10_costult_ma, rm_item.r10_costrepo_mb,
		rm_item.r10_usu_cosrepo, rm_item.r10_fec_cosrepo,
		rm_item.r10_cantped, rm_item.r10_cantback,
		rm_item.r10_precio_ant, rm_item.r10_rotacion,
		rm_item.r10_fec_camprec, rm_item.r10_stock_max,
		rm_item.r10_stock_min, rm_item.r10_proveedor,
		rm_item.r10_electrico, rm_item.r10_cod_pedido,
		rm_item.r10_cod_comerc, rm_item.r10_cod_util,
		rm_item.r10_vol_cuft, rm_item.r10_dias_mant,
		rm_item.r10_dias_inv, rm_item.r10_serie_lote,
		rm_item.r10_comentarios, rm_item.r10_usuario,
		rm_item.r10_fecing, rm_item.r10_feceli, rm_item.r10_sec_item
CALL fl_lee_unidad_medida(rm_item.r10_uni_med)
        RETURNING rm_uni.*
	DISPLAY rm_uni.r05_siglas TO nom_uni
CALL fl_lee_partida(rm_item.r10_partida)
        RETURNING rm_par.*
	DISPLAY rm_par.g16_desc_par TO nom_par
CALL fl_lee_indice_rotacion(vg_codcia, rm_item.r10_rotacion)
        RETURNING rm_rot.*
	DISPLAY rm_rot.r04_nombre TO nom_rot
CALL fl_lee_moneda(rm_item.r10_monfob)
        RETURNING rm_mon.*
	DISPLAY rm_mon.g13_nombre TO nom_mon
CALL fl_lee_linea_rep(vg_codcia, rm_item.r10_linea)
        RETURNING rm_lin.*
	DISPLAY rm_lin.r03_nombre TO nom_lin

{-- Añadido por NPC --}
CALL fl_lee_sublinea_rep(vg_codcia,rm_item.r10_linea,rm_item.r10_sub_linea)
	RETURNING rm_sublin.*
	DISPLAY rm_sublin.r70_desc_sub TO tit_sub_linea
CALL fl_lee_grupo_rep(vg_codcia,rm_item.r10_linea,rm_item.r10_sub_linea,
			rm_item.r10_cod_grupo)
	RETURNING rm_grupo.*
	DISPLAY rm_grupo.r71_desc_grupo TO tit_grupo
CALL fl_lee_clase_rep(vg_codcia,rm_item.r10_linea,rm_item.r10_sub_linea,
			rm_item.r10_cod_grupo,rm_item.r10_cod_clase)
	RETURNING rm_clase.*
	DISPLAY rm_clase.r72_desc_clase TO tit_clase
CALL fl_lee_marca_rep(vg_codcia, rm_item.r10_marca)
	RETURNING rm_marca.*
	DISPLAY rm_marca.r73_desc_marca TO tit_marca
{-- --}

CALL fl_lee_tipo_item(rm_item.r10_tipo)
	RETURNING rm_titem.*
	DISPLAY rm_titem.r06_nombre TO nom_tipo
CALL muestra_estado()
CALL fl_lee_electrico_rep(vg_codcia, rm_item.r10_electrico)
	RETURNING rm_elec.*
	DISPLAY rm_elec.r74_descripcion TO elec_desc
CALL fl_lee_proveedor(rm_item.r10_proveedor)
	RETURNING r_prov.*
	DISPLAY r_prov.p01_nomprov TO nom_prov

{-- Añadido por JCM --}
INITIALIZE vm_sustituido, vm_sustituye TO NULL
-- Cursor que obtiene los items sustitutos para este item,   
-- es decir, por quienes fue sustituido
IF rm_item.r10_estado = 'S' THEN
	DECLARE q_sustitutos CURSOR FOR 
		SELECT r14_item_nue FROM rept014
			WHERE r14_compania = vg_codcia
			  AND r14_item_ant = rm_item.r10_codigo
			  
	OPEN  q_sustitutos
	FETCH q_sustitutos INTO vm_sustituido
	CLOSE q_sustitutos
	FREE  q_sustitutos
END IF

-- Cursor que obtiene los items sustituidos por este item,   
-- es decir, a quienes sustituye
DECLARE q_sustituidos CURSOR FOR 
	SELECT r14_item_ant FROM rept014
		WHERE r14_compania = vg_codcia
		  AND r14_item_nue = rm_item.r10_codigo
		  
OPEN  q_sustituidos
FETCH q_sustituidos INTO vm_sustituye
CLOSE q_sustituidos
FREE  q_sustituidos

DISPLAY BY NAME vm_sustituye, vm_sustituido

IF rm_g04.g04_ver_costo = 'N' THEN
	DISPLAY 0 TO r10_costo_mb
	DISPLAY 0 TO r10_costo_ma
END IF
{-- FIN de añadido --}
CALL muestra_usu_camprec()

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current              SMALLINT
DEFINE num_rows                 SMALLINT
                                                                                
DISPLAY rm_item.r10_codigo TO tit_item3
DISPLAY rm_item.r10_codigo TO tit_item2
DISPLAY rm_item.r10_codigo TO tit_item1
{-- Añadido por NPC --}
DISPLAY row_current, num_rows TO vm_row_current4, vm_num_rows4
DISPLAY row_current, num_rows TO vm_row_current3, vm_num_rows3
{-- --}
DISPLAY row_current, num_rows TO vm_row_current2, vm_num_rows2
DISPLAY row_current, num_rows TO vm_row_current1, vm_num_rows1

END FUNCTION



FUNCTION control_existencias()
DEFINE i, j		SMALLINT
DEFINE rb		RECORD LIKE rept002.*
DEFINE r_exist ARRAY[100] OF RECORD
	bodega		LIKE rept011.r11_bodega, 
	n_bodega	LIKE rept002.r02_nombre, 
	stock		LIKE rept011.r11_stock_act,
	ubic		LIKE rept011.r11_ubicacion
END RECORD
DEFINE serie		LIKE rept076.r76_serie
DEFINE fecing		LIKE rept076.r76_fecing
DEFINE r_r76		RECORD LIKE rept076.*
DEFINE total_sto	DECIMAL(8,2)

OPEN WINDOW w_108_2 AT 08, 10 WITH 14 ROWS, 61 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER) 
OPEN FORM f_108_2 FROM '../forms/repf108_2'
DISPLAY FORM f_108_2

DISPLAY 'Bodega' 	TO bt_bodega
DISPLAY 'Stock'  	TO bt_stock
DISPLAY 'Ubicación'	TO bt_ubic

DISPLAY rm_item.r10_codigo TO item
DISPLAY rm_item.r10_nombre TO n_item

DECLARE q_exist CURSOR FOR
	SELECT r02_codigo, r02_nombre, r11_stock_act, r11_ubicacion
		FROM rept002, rept011
		WHERE r02_compania   = vg_codcia
		  AND r02_tipo_ident NOT IN ('C', 'R')
		  AND r11_compania   = r02_compania
                  AND r11_bodega     = r02_codigo
		  AND r11_item       = rm_item.r10_codigo
                ORDER BY 3 DESC, 1
LET i = 1
LET total_sto = 0
FOREACH q_exist INTO r_exist[i].*
	IF r_exist[i].stock IS NULL THEN
		LET r_exist[i].stock = 0
	END IF
	LET total_sto = total_sto + r_exist[i].stock
	LET i = i + 1
	IF i > 100 THEN
		EXIT FOREACH
	END IF
END FOREACH
IF i = 0 THEN
	LET i = 1
	CALL fl_lee_bodega_rep(vg_codcia, rm_r00.r00_bodega_fact)
		RETURNING rb.*
	INITIALIZE r_exist[1].* TO NULL
	LET r_exist[1].bodega   = rm_r00.r00_bodega_fact
	LET r_exist[1].n_bodega	= rb.r02_nombre
	LET r_exist[1].stock    = 0
END IF
LET i = i - 1
IF i = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
        RETURN
END IF

DISPLAY BY NAME total_sto
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY r_exist TO ra_exist.*
	ON KEY(INTERRUPT)
		EXIT DISPLAY
	ON KEY(F5)
		IF r_r76.r76_serie IS NOT NULL THEN
			LET j = arr_curr()
			CALL fl_ayuda_serie_rep(vg_codcia, vg_codloc,
				r_exist[j].bodega, rm_item.r10_codigo, 'T')
				RETURNING serie, fecing
			LET int_flag = 0
		END IF
	BEFORE DISPLAY
		--#CALL dialog.keysetlabel('ACCEPT', '')
	BEFORE ROW
		LET j = arr_curr()
		INITIALIZE r_r76.* TO NULL
		DECLARE q_ser CURSOR FOR
				SELECT UNIQUE * FROM rept076
					WHERE r76_compania  = vg_codcia
					  AND r76_localidad = vg_codloc 
					  AND r76_bodega    = r_exist[j].bodega
					  AND r76_item      = rm_item.r10_codigo
		OPEN q_ser
		FETCH q_ser INTO r_r76.*
		IF r_r76.r76_serie IS NOT NULL THEN
			--#CALL dialog.keysetlabel('F5', 'Series')
		ELSE
			--#CALL dialog.keysetlabel('F5', '')
		END IF
		CLOSE q_ser
		FREE q_ser
	AFTER DISPLAY
		CONTINUE DISPLAY
END DISPLAY

CLOSE WINDOW w_108_2

END FUNCTION



FUNCTION control_ubicacion()

DEFINE i		SMALLINT
DEFINE rb		RECORD LIKE rept002.*
DEFINE r_ubica ARRAY[100] OF RECORD
	bodega		LIKE rept011.r11_bodega, 
	n_bodega	LIKE rept002.r02_nombre, 
	stock		LIKE rept011.r11_stock_act,
	ubic_ant	LIKE rept011.r11_ubicacion,
	ubic_act	LIKE rept011.r11_ubica_ant
END RECORD

OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12

OPEN WINDOW w_108_6 AT 8,25 WITH 13 ROWS, 54 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER) 
OPEN FORM f_108_6 FROM '../forms/repf108_6'
DISPLAY FORM f_108_6

DISPLAY 'Bodega' 	TO bt_bodega
DISPLAY 'Stock'  	TO bt_stock
DISPLAY 'Ubic. Ant.'	TO bt_ubic_ant
DISPLAY 'Ubic. Act.'	TO bt_ubic_act

DISPLAY rm_item.r10_codigo TO item
DISPLAY rm_item.r10_nombre TO n_item

DECLARE q_ubica CURSOR FOR
	SELECT r02_codigo, r02_nombre, r11_stock_act, r11_ubicacion
		FROM rept002, rept011
		WHERE r02_compania = vg_codcia
		  AND r02_compania = r11_compania
		  AND r02_codigo   NOT IN ('QC', 'GC')
		  AND r11_item     = rm_item.r10_codigo
                  AND r11_bodega   = r02_codigo
                ORDER BY 3 DESC, 1
LET i = 1
FOREACH q_ubica INTO r_ubica[i].*
	IF r_ubica[i].stock IS NULL THEN
		LET r_ubica[i].stock = 0
	END IF
	LET i = i + 1
	IF i > 100 THEN
		EXIT FOREACH
	END IF
END FOREACH
IF i = 0 THEN
	LET i = 1
	CALL fl_lee_bodega_rep(vg_codcia, rm_r00.r00_bodega_fact)
		RETURNING rb.*
	INITIALIZE r_ubica[1].* TO NULL
	LET r_ubica[1].bodega   = rm_r00.r00_bodega_fact
	LET r_ubica[1].n_bodega	= rb.r02_nombre
	LET r_ubica[1].stock    = 0
END IF
LET i = i - 1

LET int_flag = 0
CALL set_count(i)
INPUT ARRAY r_ubica WITHOUT DEFAULTS FROM  ra_ubica.*
	ON KEY(INTERRUPT)
		EXIT INPUT
	AFTER INPUT
 
FOR i = 1 TO arr_count()
	IF r_ubica[i].ubic_act IS NULL THEN
		LET r_ubica[i].ubic_act = r_ubica[i].ubic_ant
	END IF
	UPDATE rept011 SET 	r11_ubicacion = r_ubica[i].ubic_act, 
				r11_ubica_ant = r_ubica[i].ubic_ant 
                	  WHERE r11_compania  = vg_codcia
                    	    AND r11_item      = rm_item.r10_codigo
                  	    AND r11_bodega    = r_ubica[i].bodega
 
END FOR 
END INPUT
 
 
CLOSE WINDOW w_108_6

END FUNCTION



FUNCTION control_pedidos()
DEFINE i, j		SMALLINT
DEFINE r_pedido		ARRAY[1000] OF RECORD
				pedido		LIKE rept016.r16_pedido, 
				proveedor	LIKE rept016.r16_proveedor, 
				fecha_lleg	LIKE rept016.r16_fec_llegada, 
				cantidad	LIKE rept017.r17_cantped,
				fob		LIKE rept017.r17_fob
			END RECORD

OPEN WINDOW w_108_3 AT 9,19 WITH 13 ROWS, 60 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER) 
OPEN FORM f_108_3 FROM '../forms/repf108_3'
DISPLAY FORM f_108_3

DISPLAY 'Pedido' TO bt_pedido
DISPLAY 'Proveedor' TO bt_proveedor
DISPLAY 'Fec. Lleg.' TO bt_fecha
DISPLAY 'Cant.' TO bt_cantidad
DISPLAY 'F O B' TO bt_fob

DISPLAY rm_item.r10_codigo TO item
DISPLAY rm_item.r10_nombre TO n_item

SELECT r17_pedido, r16_proveedor, r16_fec_llegada, r17_cantped, r17_fob
	FROM rept016, rept017
	WHERE r17_compania  = vg_codcia
          AND r17_item      = rm_item.r10_codigo
	  AND r16_compania  = r17_compania
          AND r16_localidad = r17_localidad
          AND r16_pedido    = r17_pedido
UNION
	SELECT r17_pedido, r16_proveedor, r16_fec_llegada, 
	       (r17_cantped - r17_cantrec), r17_fob
		FROM rept016, rept017
		WHERE r17_compania  = vg_codcia
	          AND r17_item      = rm_item.r10_codigo
		  AND r17_cantped   > r17_cantrec 
		  AND r16_compania  = r17_compania
                  AND r16_localidad = r17_localidad
                  AND r16_pedido    = r17_pedido
	INTO TEMP tmp_ped

DECLARE q_pedido CURSOR FOR SELECT * FROM tmp_ped ORDER BY r16_fec_llegada DESC
                  
LET i = 1
FOREACH q_pedido INTO r_pedido[i].*
	LET i = i + 1
	IF i > 1000 THEN
		EXIT FOREACH
	END IF
END FOREACH
DROP TABLE tmp_ped
LET i = i - 1
IF i = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	CLOSE WINDOW w_108_3
        RETURN
END IF

LET int_flag = 0
CALL set_count(i)
DISPLAY ARRAY r_pedido TO ra_pedido.*
	ON KEY(INTERRUPT)
		EXIT DISPLAY
	ON KEY(F5)
		LET j = arr_curr()
		CALL ver_pedido(r_pedido[j].pedido)
		LET int_flag = 0
	BEFORE DISPLAY
		--#CALL dialog.keysetlabel('ACCEPT', '')
		--#CALL dialog.keysetlabel('F5', 'Pedido')
	BEFORE ROW
		LET j = arr_curr()
		DISPLAY j TO num_row
		DISPLAY i TO max_row
	AFTER DISPLAY
		CONTINUE DISPLAY
END DISPLAY

CLOSE WINDOW w_108_3

END FUNCTION



FUNCTION leer_nota_ped()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

LET lin_menu = 0
LET row_ini  = 6
LET num_rows = 6
LET num_cols = 22
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_repp AT row_ini, 30 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_repf302_2 FROM '../forms/repf302_2'
ELSE
	OPEN FORM f_repf302_2 FROM '../forms/repf302_2c'
END IF
DISPLAY FORM f_repf302_2
LET vm_programa = 'N'
LET int_flag    = 0
INPUT BY NAME vm_programa
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
END INPUT
CLOSE WINDOW w_repp
RETURN

END FUNCTION



FUNCTION ver_pedido(pedido)
DEFINE pedido		LIKE rept016.r16_pedido
DEFINE comando		CHAR(400)
DEFINE run_prog		CHAR(10)
DEFINE prog		CHAR(10)
DEFINE r_r81		RECORD LIKE rept081.*

LET prog        = ' repp204 '
LET vm_programa = 'S'
CALL fl_lee_nota_pedido_rep(vg_codcia, vg_codloc, pedido) RETURNING r_r81.*
IF r_r81.r81_pedido IS NOT NULL THEN
	IF vg_gui = 1 THEN
		CALL leer_nota_ped()
		IF int_flag THEN
			RETURN
		END IF
		IF vm_programa = 'N' THEN
			LET prog   = ' repp233 '
			LET pedido = r_r81.r81_pedido
		END IF
	END IF
END IF
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS',
		vg_separador, 'fuentes', vg_separador, run_prog, prog, vg_base,
		' ', vg_modulo, ' ', vg_codcia,' ', vg_codloc, ' "', pedido, '"'
RUN comando

END FUNCTION



FUNCTION sustituye()

DEFINE i		SMALLINT
DEFINE max_items	SMALLINT
DEFINE r_items ARRAY[100] OF RECORD 
	item		LIKE rept010.r10_codigo, 
	nombre		LIKE rept010.r10_nombre, 	
	fecha		DATE
END RECORD

LET max_items = 100

OPEN WINDOW w_108_4 AT 9,8 WITH 12 ROWS, 68 COLUMNS 
	ATTRIBUTE(FORM LINE FIRST + 1, BORDER, MESSAGE LINE LAST - 1)
OPEN FORM f_108_4 FROM '../forms/repf108_4'
DISPLAY FORM f_108_4

DISPLAY fl_justifica_titulo('D', 'Sustituto', 10) TO lbl_item
DISPLAY 'Sustituidos' TO bt_item
DISPLAY 'Fecha'       TO bt_fecha

DISPLAY rm_item.r10_codigo TO item1
DISPLAY rm_item.r10_nombre TO n_item1

-- Cursor que obtiene los items sustituidos por este item,
-- es decir, a quienes sustituye
DECLARE q_sustituidos2 CURSOR FOR 
	SELECT r14_item_ant, r10_nombre, DATE(r14_fecing) 
		FROM rept014, rept010
		WHERE r14_compania = vg_codcia
		  AND r14_item_nue = rm_item.r10_codigo
		  AND r10_compania = r14_compania 
		  AND r10_codigo   = r14_item_ant

LET i = 1
FOREACH q_sustituidos2 INTO r_items[i].*
	LET i = i + 1
	IF i > max_items THEN
		EXIT FOREACH
	END IF
END FOREACH

LET i = i - 1
LET int_flag = 0
CALL set_count(i)
DISPLAY ARRAY r_items TO ra_items.*

CLOSE WINDOW w_108_4

END FUNCTION



FUNCTION sustituido()

DEFINE i		SMALLINT
DEFINE max_items	SMALLINT
DEFINE r_items ARRAY[100] OF RECORD
	item		LIKE rept010.r10_codigo, 
	nombre		LIKE rept010.r10_nombre, 	
	fecha		DATE
END RECORD

LET max_items = 100

OPEN WINDOW w_108_4 AT 9,8 WITH 12 ROWS, 68 COLUMNS 
	ATTRIBUTE(FORM LINE FIRST + 1, BORDER, MESSAGE LINE LAST - 1)
OPEN FORM f_108_4 FROM '../forms/repf108_4'
DISPLAY FORM f_108_4

DISPLAY fl_justifica_titulo('D', 'Sustituido', 10) TO lbl_item
DISPLAY 'Sustituto' TO bt_item
DISPLAY 'Fecha'     TO bt_fecha

DISPLAY rm_item.r10_codigo TO item1
DISPLAY rm_item.r10_nombre TO n_item1

-- Cursor que obtiene los items sustitutos para este item,
-- es decir, por quienes fue sustituido
DECLARE q_sustitutos2 CURSOR FOR 
	SELECT r14_item_nue, r10_nombre, DATE(r14_fecing) FROM rept014, rept010
		WHERE r14_compania = vg_codcia
		  AND r14_item_ant = rm_item.r10_codigo
		  AND r10_compania = r14_compania 
		  AND r10_codigo   = r14_item_nue
		  
LET i = 1
FOREACH q_sustitutos2 INTO r_items[i].*
	LET i = i + 1
	IF i > max_items THEN
		EXIT FOREACH
	END IF
END FOREACH

LET i = i - 1

LET int_flag = 0
CALL set_count(i)
DISPLAY ARRAY r_items TO ra_items[i].*

CLOSE WINDOW w_108_4

END FUNCTION



FUNCTION estadisticas()
DEFINE r_par		RECORD
				r12_moneda	LIKE rept012.r12_moneda,
				n_moneda	LIKE gent013.g13_nombre,
				anho		SMALLINT,
				bodega		LIKE rept002.r02_codigo,
				n_bodega	LIKE rept002.r02_nombre
			END RECORD
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_r00		RECORD LIKE rept000.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE anio		SMALLINT
DEFINE titu		VARCHAR(15)

INITIALIZE r_par.* TO NULL
CALL fl_lee_compania_repuestos(vg_codcia) RETURNING r_r00.*
CALL fl_lee_moneda(rg_gen.g00_moneda_base) RETURNING r_g13.*
CALL fl_lee_bodega_rep(vg_codcia, r_r00.r00_bodega_fact) RETURNING r_r02.*
LET r_par.r12_moneda = rg_gen.g00_moneda_base
LET r_par.n_moneda   = r_g13.g13_nombre 
LET r_par.bodega     = r_r00.r00_bodega_fact
LET r_par.n_bodega   = r_r02.r02_nombre
LET r_par.anho       = YEAR(vg_fecha)
OPEN WINDOW w_108_5 AT 05, 08 WITH 19 ROWS, 67 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, BORDER)
OPEN FORM f_108_5 FROM '../forms/repf108_5'
DISPLAY FORM f_108_5
LET anio = r_par.anho - 1
LET titu = 'Año'	, anio
DISPLAY 'Mes' 		TO tit_col1
DISPLAY titu		TO tit_col2
DISPLAY 'Ventas '	TO tit_col3
DISPLAY 'Devolu.'	TO tit_col4
DISPLAY 'Total  '	TO tit_col5
DISPLAY 'Facturas'	TO tit_col6
WHILE TRUE
	LET int_flag = 0
	INPUT BY NAME r_par.*
		WITHOUT DEFAULTS
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT INPUT
		ON KEY(F2)
			IF INFIELD(r12_moneda) THEN
				CALL fl_ayuda_monedas()
					RETURNING r_g13.g13_moneda,
						  r_g13.g13_nombre,
						  r_g13.g13_decimales
				IF r_g13.g13_moneda IS NOT NULL THEN
					LET r_par.r12_moneda = r_g13.g13_moneda
					LET r_par.n_moneda   = r_g13.g13_nombre
					DISPLAY BY NAME r_par.*
				END IF
			END IF
			IF INFIELD(bodega) THEN
				CALL fl_ayuda_bodegas_rep(vg_codcia, vg_codloc,
							'T', 'T', 'T', 'T', '2')
					RETURNING r_r02.r02_codigo,
						  r_r02.r02_nombre
				IF r_r02.r02_codigo IS NOT NULL THEN
					LET r_par.bodega   = r_r02.r02_codigo
					LET r_par.n_bodega = r_r02.r02_nombre
					DISPLAY BY NAME r_par.*
				END IF
			END IF
			LET int_flag = 0
		AFTER FIELD r12_moneda
			IF r_par.r12_moneda IS NOT NULL THEN
				CALL fl_lee_moneda(r_par.r12_moneda)
					RETURNING r_g13.*
				IF r_g13.g13_moneda IS NULL THEN
					CALL fl_mostrar_mensaje('Moneda no existe.','exclamation')
					NEXT FIELD r12_moneda
				END IF
				LET r_par.n_moneda = r_g13.g13_nombre
				DISPLAY BY NAME r_par.n_moneda
			ELSE
				LET r_par.n_moneda = NULL
				CLEAR n_moneda
			END IF
		AFTER FIELD bodega
			IF r_par.bodega IS NOT NULL THEN
				CALL fl_lee_bodega_rep(vg_codcia, r_par.bodega) 
					RETURNING r_r02.*
				IF r_r02.r02_codigo IS NULL THEN
					CALL fl_mostrar_mensaje('Bodega no existe.','exclamation')
					NEXT FIELD bodega
				END IF
				LET r_par.n_bodega = r_r02.r02_nombre
				DISPLAY BY NAME r_par.n_bodega
			ELSE
				LET r_par.n_bodega = NULL
				CLEAR n_bodega
			END IF
		AFTER FIELD anho
			IF r_par.anho <= 1900 THEN
				CALL fl_mostrar_mensaje('El año debe ser mayor a 1900.','exclamation')
				NEXT FIELD anho
			END IF
	END INPUT
	IF int_flag THEN
		EXIT WHILE
	END IF
	LET anio = r_par.anho - 1
	LET titu = 'Año'	, anio
	DISPLAY titu		TO tit_col2
	IF NOT consulta_estadisticas(r_par.*) THEN
		EXIT WHILE
	END IF
END WHILE
LET int_flag = 0
CLOSE WINDOW w_108_5
RETURN

END FUNCTION



FUNCTION consulta_estadisticas(r_par)
DEFINE r_par		RECORD
				r12_moneda	LIKE rept012.r12_moneda,
				n_moneda	LIKE gent013.g13_nombre,
				anho		SMALLINT,
				bodega		LIKE rept002.r02_codigo,
				n_bodega	LIKE rept002.r02_nombre
			END RECORD
DEFINE r_estat		ARRAY[12] OF RECORD
				mes		CHAR(10), 
				unid_vant	LIKE rept012.r12_uni_deman, 
				unid_vend	LIKE rept012.r12_uni_venta, 
				unid_dev	LIKE rept012.r12_uni_deman, 
				unid_vtot	LIKE rept012.r12_uni_deman, 
				unid_dema	LIKE rept012.r12_uni_deman
			END RECORD
DEFINE unid_vend	LIKE rept012.r12_uni_venta
DEFINE unid_dema	LIKE rept012.r12_uni_deman
DEFINE unid_dev		LIKE rept012.r12_uni_deman 
DEFINE unid_vtot	LIKE rept012.r12_uni_deman 
DEFINE tot_vend		LIKE rept012.r12_uni_venta
DEFINE tot_dema		LIKE rept012.r12_uni_deman
DEFINE tot_dev		LIKE rept012.r12_uni_perdi
DEFINE tot_vtot		LIKE rept012.r12_uni_perdi
DEFINE tot_vant		LIKE rept012.r12_uni_perdi
DEFINE query		CHAR(1000)
DEFINE fec_ini, fec_fin DATE
DEFINE i, mes, num_rows	SMALLINT
DEFINE continuar	SMALLINT
DEFINE expr_bod		VARCHAR(100)

LET num_rows = 12
INITIALIZE mes, r_estat[1].* TO NULL
LET tot_vend = 0 
LET tot_dev  = 0 
LET tot_dema = 0 
LET tot_vtot = 0 
FOR i = 1 TO num_rows
	LET r_estat[i].mes 	 = 
		fl_justifica_titulo('I', fl_retorna_nombre_mes(i), 10)
	LET r_estat[i].unid_vant = retorna_valor_anio_ant(r_par.bodega,
							r_par.anho - 1, i)
	LET r_estat[i].unid_vend = 0
	LET r_estat[i].unid_dema = 0
	LET r_estat[i].unid_dev  = 0
	LET r_estat[i].unid_vtot = 0
END FOR
ERROR 'Generando consulta . . . espere por favor' ATTRIBUTE(NORMAL)
LET expr_bod = NULL
IF r_par.bodega IS NOT NULL THEN
	LET expr_bod = '   AND r20_bodega      = "', r_par.bodega, '"'
END IF
LET query = 'SELECT MONTH(r20_fecing), ',
			'NVL(SUM(CASE WHEN r20_cod_tran = "FA" OR ',
						'r20_cod_tran = "NV" ',
					'THEN r20_cant_ven ',
					'ELSE 0.00 ',
				'END), 0), ',
			'NVL(SUM(CASE WHEN r20_cod_tran <> "FA" AND ',
						'r20_cod_tran <> "NV" ',
					'THEN r20_cant_ven * (-1) ',
					'ELSE 0.00 ',
				'END), 0), ',
			'NVL(SUM(CASE WHEN r20_cod_tran = "FA" OR ',
						'r20_cod_tran = "NV" ',
					'THEN r20_cant_ven ',
					'ELSE r20_cant_ven * (-1) ',
				'END), 0), ',
			'NVL(SUM(CASE WHEN r20_cod_tran <> "AF" ',
					'THEN 1 ',
					'ELSE -1 ',
				'END), 0) ',
		'FROM rept020 ',
		'WHERE r20_compania      = ', vg_codcia,
		'  AND r20_localidad     = ', vg_codloc,
		'  AND r20_cod_tran     IN ("FA", "NV", "DF", "AF") ',
		expr_bod CLIPPED,
		'  AND r20_item          = "', rm_item.r10_codigo, '"',
		'  AND YEAR(r20_fecing)  = ', r_par.anho,
		' GROUP BY 1 ',
		' ORDER BY 1 '
PREPARE cit FROM query
DECLARE q_cit CURSOR FOR cit
FOREACH	q_cit INTO mes, unid_vend, unid_dev, unid_vtot, unid_dema
	LET r_estat[mes].unid_vend = unid_vend
	LET r_estat[mes].unid_dev  = unid_dev
	LET r_estat[mes].unid_vtot = unid_vtot
	LET r_estat[mes].unid_dema = unid_dema
END FOREACH	
LET tot_vant = 0
LET tot_vend = 0
LET tot_dev  = 0
LET tot_vtot = 0
LET tot_dema = 0
FOR mes = 1 TO 12
	LET tot_vant = tot_vant + r_estat[mes].unid_vant
	LET tot_vend = tot_vend + r_estat[mes].unid_vend
	LET tot_dev  = tot_dev  + r_estat[mes].unid_dev
	LET tot_vtot = tot_vtot + r_estat[mes].unid_vtot
	LET tot_dema = tot_dema + r_estat[mes].unid_dema
END FOR
ERROR ' ' ATTRIBUTE(NORMAL)
LET continuar = 0
LET int_flag  = 0
CALL set_count(num_rows)
DISPLAY ARRAY r_estat TO r_estat.*
	ON KEY(INTERRUPT)
		EXIT DISPLAY
	ON KEY(F5)
		LET continuar = 1
		EXIT DISPLAY
	ON KEY(F6)
		LET fec_ini = MDY(i, 01, r_par.anho)
	        LET fec_fin = MDY(i, 01, r_par.anho) + 1 UNITS MONTH
				- 1 UNITS DAY
		CALL muestra_movimientos_item(rm_item.r10_codigo, r_par.bodega,
						r_par.r12_moneda, fec_ini,
						fec_fin)
		CONTINUE DISPLAY
	BEFORE DISPLAY
		--#CALL dialog.keysetlabel('F5', 'Cabecera')
		--#CALL dialog.keysetlabel('F6', 'Movimientos')
		--#CALL dialog.keysetlabel("ACCEPT","")
		DISPLAY BY NAME tot_vant, tot_vend, tot_dema, tot_dev, tot_vtot
	BEFORE ROW
		LET i = arr_curr()
	AFTER DISPLAY
		CONTINUE DISPLAY
END DISPLAY
RETURN continuar

END FUNCTION



FUNCTION retorna_valor_anio_ant(bodega, anio, mes)
DEFINE bodega		LIKE rept020.r20_bodega
DEFINE anio, mes	SMALLINT
DEFINE query		CHAR(600)
DEFINE expr_bod		VARCHAR(100)
DEFINE valor		LIKE rept020.r20_cant_ven

LET expr_bod = NULL
IF bodega IS NOT NULL THEN
	LET expr_bod = '   AND r20_bodega      = "', bodega, '"'
END IF
LET query = 'SELECT NVL(SUM(CASE WHEN r20_cod_tran = "FA" OR ',
						'r20_cod_tran = "NV" ',
					'THEN r20_cant_ven ',
					'ELSE r20_cant_ven * (-1) ',
				'END), 0) ',
		'FROM rept020 ',
		'WHERE r20_compania      = ', vg_codcia,
		'  AND r20_localidad     = ', vg_codloc,
		'  AND r20_cod_tran     IN ("FA", "NV", "DF", "AF") ',
		expr_bod CLIPPED,
		'  AND r20_item          = "', rm_item.r10_codigo, '"',
		'  AND EXTEND(r20_fecing, YEAR TO MONTH) = "',
			anio USING "&&&&", '-', mes USING "&&", '"'
PREPARE cons_ant FROM query
DECLARE q_cons_ant CURSOR FOR cons_ant
OPEN q_cons_ant
FETCH q_cons_ant INTO valor
CLOSE q_cons_ant
FREE q_cons_ant
RETURN valor

END FUNCTION



FUNCTION muestra_movimientos_item(item, bodega, moneda, fec_ini, fec_fin)
DEFINE item		LIKE rept010.r10_codigo
DEFINE bodega, bod	LIKE rept002.r02_codigo
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE fec_ini, fec_fin	DATE
DEFINE r_item		RECORD LIKE rept010.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_bod		RECORD LIKE rept002.*
DEFINE r_trn		RECORD LIKE rept019.*
DEFINE num_rows, i	SMALLINT
DEFINE max_rows		SMALLINT
DEFINE tot_uni		DECIMAL(8,2)
DEFINE tot_val		DECIMAL(14,2)
DEFINE comando		VARCHAR(140)
DEFINE columna_act	SMALLINT
DEFINE columna_ant	SMALLINT
DEFINE orden_act	CHAR(4)
DEFINE orden_ant	CHAR(4)
DEFINE orden		VARCHAR(100)
DEFINE query		VARCHAR(300)
DEFINE rt		RECORD LIKE gent021.*
DEFINE r_mov ARRAY[800] OF RECORD
	fecha		DATE,
	tipo		LIKE rept019.r19_cod_tran,
	numero		LIKE rept019.r19_num_tran,
	cliente		VARCHAR(30),
	unidades	DECIMAL(8,2),
	valor		DECIMAL(14,2)
	END RECORD

CREATE TEMP TABLE temp_mov
	(te_fecha	DATETIME YEAR TO SECOND,
	 te_tipo	CHAR(2),
	 te_numero	INTEGER,
	 te_cliente	VARCHAR(30),
	 te_unidades	DECIMAL(8,2),
	 te_valor	DECIMAL(14,2))
LET max_rows = 800
OPEN WINDOW w_mov AT 3,5 WITH FORM "../forms/repf310_2"
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
ERROR "Generando consulta . . . espere por favor." ATTRIBUTE(NORMAL)
CALL fl_lee_item(vg_codcia, item) RETURNING r_item.*
CALL fl_lee_moneda(moneda) RETURNING r_mon.*
CALL fl_lee_bodega_rep(vg_codcia, bodega) RETURNING r_bod.*
DISPLAY 'Fecha'       TO tit_col1
DISPLAY 'Tp'          TO tit_col2
DISPLAY '# Documento' TO tit_col3
DISPLAY 'Cliente'     TO tit_col4
DISPLAY 'Uni.'        TO tit_col5
DISPLAY 'V a l o r'   TO tit_col6
DISPLAY BY NAME item, fec_ini, fec_fin
DISPLAY r_item.r10_nombre TO name_item
DISPLAY r_mon.g13_nombre TO tit_mon
DISPLAY r_bod.r02_nombre TO tit_bod
LET int_flag = 0
INPUT BY NAME fec_ini, fec_fin
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	AFTER FIELD fec_ini
		IF fec_ini IS NULL THEN
			NEXT FIELD fec_ini
		END IF
	AFTER FIELD fec_fin
		IF fec_fin IS NULL THEN
			NEXT FIELD fec_fin
		END IF
	AFTER INPUT
		IF int_flag THEN
			EXIT INPUT
		END IF
		IF fec_ini > fec_fin THEN
			CALL fl_mostrar_mensaje('Fecha final no puede ser menor a la inicial.', 'exclamation')
			NEXT FIELD fec_ini
		END IF
END INPUT
IF int_flag THEN	
	LET int_flag = 0
	CLOSE WINDOW w_mov
	RETURN
END IF
DECLARE q_det CURSOR FOR SELECT r20_fecing, r20_cod_tran, r20_num_tran,
	'', r20_cant_ven, (r20_precio * r20_cant_ven) - r20_val_descto, 
	r20_bodega
	FROM rept020
	WHERE r20_compania = vg_codcia AND r20_localidad = vg_codloc AND 
	      r20_item = item AND
	      r20_fecing BETWEEN EXTEND(fec_ini, YEAR TO SECOND) AND
	      EXTEND(fec_fin, YEAR TO SECOND) + 23 UNITS HOUR + 59 UNITS MINUTE
					      + 59 UNITS SECOND
	ORDER BY r20_fecing
LET num_rows = 1
OPEN q_det 
LET tot_uni = 0
LET tot_val = 0
WHILE TRUE
	FETCH q_det INTO r_mov[num_rows].*, bod
	IF status = NOTFOUND THEN
		EXIT WHILE
	END IF
	CALL fl_lee_cod_transaccion(r_mov[num_rows].tipo) RETURNING rt.*
	IF rt.g21_act_estad <> 'S' THEN
		CONTINUE WHILE
	END IF
	CALL fl_lee_cabecera_transaccion_rep(vg_codcia, vg_codloc, 
		r_mov[num_rows].tipo, r_mov[num_rows].numero)
		RETURNING r_trn.*
	IF bod <> bodega THEN
		CONTINUE WHILE
	END IF
	IF r_trn.r19_moneda <> moneda THEN
		CONTINUE WHILE
	END IF
	IF rt.g21_tipo = 'I' THEN
		LET r_mov[num_rows].unidades = r_mov[num_rows].unidades * -1
		LET r_mov[num_rows].valor    = r_mov[num_rows].valor    * -1
	END IF	
	LET r_mov[num_rows].cliente = r_trn.r19_nomcli
	INSERT INTO temp_mov VALUES (r_mov[num_rows].*)
	LET tot_uni = tot_uni + r_mov[num_rows].unidades
	LET tot_val = tot_val + r_mov[num_rows].valor
	LET num_rows = num_rows + 1
	IF num_rows = max_rows + 1 THEN
		EXIT WHILE
	END IF
END WHILE
CLOSE q_det
LET num_rows = num_rows - 1
IF num_rows = 0 THEN
	DROP TABLE temp_mov
	CALL fl_mensaje_consulta_sin_registros()
	CLOSE WINDOW w_mov
	RETURN
END IF
DISPLAY BY NAME tot_uni, tot_val
LET orden_act = 'DESC'
LET orden_ant = 'ASC'
LET columna_act = 1
LET columna_ant = 4
ERROR ' '
WHILE TRUE
	IF orden_act = 'ASC' THEN
		LET orden_act = 'DESC'
	ELSE
		LET orden_act = 'ASC'
	END IF
	LET orden = columna_act, ' ', orden_act, ', ', columna_ant, ' ',
		    orden_ant 
	LET query = 'SELECT * FROM temp_mov ORDER BY ', orden CLIPPED
	PREPARE mt FROM query
	DECLARE q_mt CURSOR FOR mt
	LET  i = 1
	FOREACH q_mt INTO r_mov[i].*
		LET i = i + 1
	END FOREACH 
	CALL set_count(num_rows)
	LET int_flag = 0
	DISPLAY ARRAY r_mov TO r_mov.*
		BEFORE DISPLAY 
			--#CALL dialog.keysetlabel("ACCEPT","")
		AFTER DISPLAY 
			CONTINUE DISPLAY
		BEFORE ROW
			LET i = arr_curr()
			MESSAGE i, ' de ', num_rows
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F5)
			LET i = arr_curr()
			CALL fl_ver_transaccion_rep(vg_codcia, vg_codloc, 
			       	r_mov[i].tipo, r_mov[i].numero)
		ON KEY(F6)
			LET comando = 'fglrun repp108 ', vg_base, ' RE ', 
			               vg_codcia, ' ',
			               vg_codloc, 
                                       ' "',
			               item CLIPPED || '"'
		        RUN comando
		ON KEY(F15)
			LET columna_ant = columna_act
			LET columna_act = 1 
			LET orden_ant   = orden_act
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET columna_ant = columna_act
			LET columna_act = 2 
			LET orden_ant   = orden_act
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET columna_ant = columna_act
			LET columna_act = 3 
			LET orden_ant   = orden_act
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET columna_ant = columna_act
			LET columna_act = 4 
			LET orden_ant   = orden_act
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F19)
			LET columna_ant = columna_act
			LET columna_act = 5 
			LET orden_ant   = orden_act
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F20)
			LET columna_ant = columna_act
			LET columna_act = 6 
			LET orden_ant   = orden_act
			LET int_flag = 2
			EXIT DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
END WHILE
CLOSE WINDOW w_mov
DROP TABLE temp_mov
LET int_flag = 0

END FUNCTION



FUNCTION cambio_modificacion()

LET rm_item.r10_usu_cosrepo = NULL
LET rm_item.r10_fec_cosrepo = NULL
	LET rm_item.r10_usu_cosrepo = vg_usuario
	LET rm_item.r10_fec_cosrepo = fl_current()
DISPLAY BY NAME rm_item.r10_usu_cosrepo, rm_item.r10_fec_cosrepo

END FUNCTION



FUNCTION usuario_camprec()

IF NOT modificar_precio THEN
	RETURN
END IF
INITIALIZE rm_r87.* TO NULL
LET rm_r87.r87_compania    = vg_codcia
LET rm_r87.r87_localidad   = vg_codloc
LET rm_r87.r87_item        = rm_item.r10_codigo
SELECT NVL(MAX(r87_secuencia), 0) + 1 INTO rm_r87.r87_secuencia
	FROM rept087
	WHERE r87_compania = rm_r87.r87_compania
	  AND r87_item     = rm_r87.r87_item
LET rm_r87.r87_precio_act  = rm_item.r10_precio_mb
LET rm_r87.r87_precio_ant  = rm_item.r10_precio_ant
LET rm_r87.r87_usu_camprec = vg_usuario
LET rm_r87.r87_fec_camprec = rm_item.r10_fec_camprec
INSERT INTO rept087 VALUES (rm_r87.*)
DISPLAY BY NAME rm_r87.r87_usu_camprec

END FUNCTION



FUNCTION muestra_usu_camprec()
DEFINE r_r87		RECORD LIKE rept087.*

IF rm_item.r10_fec_camprec IS NULL THEN
	RETURN
END IF
DECLARE q_usu_c CURSOR FOR
	SELECT * FROM rept087
	WHERE r87_compania = rm_item.r10_compania
	  AND r87_item     = rm_item.r10_codigo
	ORDER BY r87_fec_camprec DESC
OPEN q_usu_c
FETCH q_usu_c INTO r_r87.*
DISPLAY BY NAME r_r87.r87_usu_camprec
CLOSE q_usu_c
FREE q_usu_c

END FUNCTION



FUNCTION control_cambio_precio()
DEFINE r_camprec	ARRAY[1000] OF RECORD
				r87_localidad	LIKE rept087.r87_localidad,
				r87_secuencia	LIKE rept087.r87_secuencia,
				r87_precio_act	LIKE rept087.r87_precio_act,
				r87_precio_ant	LIKE rept087.r87_precio_ant,
				r87_usu_camprec	LIKE rept087.r87_usu_camprec,
				r87_fec_camprec	LIKE rept087.r87_fec_camprec
			END RECORD
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE
DEFINE i, j, l, salir	SMALLINT

OPEN WINDOW w_108_7 AT 05, 06 WITH 18 ROWS, 69 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER) 
OPEN FORM f_108_7 FROM '../forms/repf108_7'
DISPLAY FORM f_108_7
DISPLAY 'LC'			TO tit_col1
DISPLAY 'Sec.'			TO tit_col2
DISPLAY 'Precio Actual'		TO tit_col3
DISPLAY 'Precio Anter.'		TO tit_col4
DISPLAY 'Usuario'		TO tit_col5
DISPLAY 'Fecha Cambio Precio'	TO tit_col6
LET fecha_fin = vg_fecha
LET fecha_ini = fecha_fin - 3 UNITS MONTH
DISPLAY rm_item.r10_codigo TO r87_item
DISPLAY BY NAME fecha_ini, fecha_fin, rm_item.r10_nombre
WHILE TRUE
	CALL lee_fechas_camprec(fecha_ini, fecha_fin)
		RETURNING fecha_ini, fecha_fin
	IF int_flag THEN
		CLOSE WINDOW w_108_7
		LET int_flag = 0
		RETURN
	END IF
	DECLARE q_camprec CURSOR FOR
		SELECT r87_localidad, r87_secuencia, r87_precio_act,
			r87_precio_ant, r87_usu_camprec, r87_fec_camprec
			FROM rept087
			WHERE r87_compania = vg_codcia
			  AND r87_item     = rm_item.r10_codigo
			  AND DATE(r87_fec_camprec)
				BETWEEN fecha_ini AND fecha_fin
	                ORDER BY r87_fec_camprec DESC
	LET i = 1
	FOREACH q_camprec INTO r_camprec[i].*
		LET i = i + 1
		IF i > 1000 THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		CONTINUE WHILE
	END IF
	LET int_flag = 0
	CALL set_count(i)
	DISPLAY ARRAY r_camprec TO r_camprec.*
		ON KEY(INTERRUPT)
			LET salir = 1
			EXIT DISPLAY
		ON KEY(F5)
			LET salir = 0
			EXIT DISPLAY
		BEFORE DISPLAY
			CALL dialog.keysetlabel('ACCEPT', '')
			CALL dialog.keysetlabel("F1","")
			CALL dialog.keysetlabel("CONTROL-W","")
			DISPLAY i TO max_row_prec
		BEFORE ROW
			LET j = arr_curr()	
			LET l = scr_line()
			DISPLAY j TO num_row_prec
		AFTER DISPLAY
			CONTINUE DISPLAY
	END DISPLAY
	IF salir THEN
		EXIT WHILE
	END IF
	FOR i = 1 TO fgl_scr_size('r_camprec')
		CLEAR r_camprec[i].*
	END FOR
	CLEAR num_row_prec, max_row_prec
END WHILE
CLOSE WINDOW w_108_7
LET int_flag = 0
RETURN

END FUNCTION



FUNCTION lee_fechas_camprec(fecha_ini, fecha_fin)
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE
DEFINE fec_ini		DATE
DEFINE fec_fin		DATE

LET int_flag = 0
INPUT BY NAME fecha_ini, fecha_fin
	WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
		LET int_flag = 1
		--#RETURN fecha_ini, fecha_fin
		EXIT INPUT
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD fecha_ini
		LET fec_ini = fecha_ini
	BEFORE FIELD fecha_fin
		LET fec_fin = fecha_fin
	AFTER FIELD fecha_ini
		IF fecha_ini IS NULL THEN
			LET fecha_ini = fec_ini
			DISPLAY BY NAME fecha_ini
		END IF
		IF fecha_ini > vg_fecha THEN
			CALL fl_mostrar_mensaje('La Fecha Inicial no puede ser mayor que la Fecha de Hoy.', 'exclamation')
			NEXT FIELD fecha_ini
		END IF
	AFTER FIELD fecha_fin
		IF fecha_fin IS NULL THEN
			LET fecha_fin = fec_fin
			DISPLAY BY NAME fecha_fin
		END IF
		IF fecha_fin > vg_fecha THEN
			CALL fl_mostrar_mensaje('La Fecha Final no puede ser mayor que la Fecha de Hoy.', 'exclamation')
			NEXT FIELD fecha_fin
		END IF
	AFTER INPUT
		IF fecha_ini > fecha_fin THEN
			CALL fl_mostrar_mensaje('La Fecha Inicial no puede ser mayor que la Fecha Final.', 'exclamation')
			NEXT FIELD fecha_ini
		END IF
END INPUT
RETURN fecha_ini, fecha_fin

END FUNCTION



FUNCTION tiene_stock(costo_act)
DEFINE costo_act	LIKE rept010.r10_costo_mb
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE loc1		LIKE gent002.g02_localidad
DEFINE loc2		LIKE gent002.g02_localidad
DEFINE mensaje		VARCHAR(200)
DEFINE resul		SMALLINT

IF rm_item.r10_costo_mb = costo_act THEN
	RETURN 1
END IF
IF vg_codloc = 1 OR vg_codloc = 2 THEN
	LET loc1 = 1
	LET loc2 = 2
END IF
DECLARE q_stock CURSOR FOR
	SELECT * FROM rept011
		WHERE r11_compania = vg_codcia
		  AND r11_bodega IN
			(SELECT r02_codigo FROM rept002
				WHERE r02_compania  = r11_compania
				  AND r02_codigo   NOT IN ('QC', 'GC')
				  AND r02_estado    = 'A'
				  AND r02_area      = 'R'
				  AND r02_tipo     <> 'S'
				  AND r02_localidad IN (loc1, loc2))
		  AND r11_item     = rm_item.r10_codigo
		ORDER BY r11_bodega
LET resul = 0
FOREACH q_stock INTO r_r11.*
	IF r_r11.r11_stock_act = 0 THEN
		CONTINUE FOREACH
	END IF
	LET resul = 1
	CALL fl_lee_bodega_rep(r_r11.r11_compania, r_r11.r11_bodega)
		RETURNING r_r02.*
	LET mensaje = 'El Item ', r_r11.r11_item CLIPPED, ' tiene ',
			r_r11.r11_stock_act USING "##,##&.##", ' unidades de ',
			'existencia en la Bodega ', r_r02.r02_codigo, ' ',
			r_r02.r02_nombre CLIPPED, '.'
	CALL fl_mostrar_mensaje(mensaje, 'info')
END FOREACH
RETURN resul

END FUNCTION



FUNCTION muestra_estado()

CASE rm_item.r10_estado
	WHEN 'A' 
        	DISPLAY 'ACTIVO' TO tit_estado
	WHEN 'B'
		DISPLAY 'BLOQUEADO' TO tit_estado
	WHEN 'S'
		DISPLAY 'SUSTITUIDO' TO tit_estado
END CASE

END FUNCTION



FUNCTION control_clonacion_item()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE cod_item		INTEGER
DEFINE resp			CHAR(6)
DEFINE r_c04		RECORD LIKE ordt004.*
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_r05		RECORD LIKE rept005.*
DEFINE r_r06		RECORD LIKE rept006.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r72		RECORD LIKE rept072.*
DEFINE r_r73		RECORD LIKE rept073.*
DEFINE r_r77		RECORD LIKE rept077.*
DEFINE costo_mb		LIKE rept010.r10_costo_mb
DEFINE codigo_anterior	LIKE rept010.r10_codigo
-- Variables de la forma
DEFINE act_lista_precios CHAR(1)
DEFINE fecha_actual DATETIME YEAR TO SECOND
DEFINE query		CHAR(1500)

LET int_flag = 0
CALL fl_hacer_pregunta('Esta seguro de Clonar éste Item ?', 'No') RETURNING resp
IF resp <> 'Yes' THEN
	RETURN
END IF
LET lin_menu = 0
LET row_ini  = 4
LET num_rows = 21
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_repf108_9 AT row_ini, 02 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_repf108_9 FROM '../forms/repf108_9'
ELSE
	OPEN FORM f_repf108_9 FROM '../forms/repf108_9c'
END IF
DISPLAY FORM f_repf108_9
CLEAR FORM
IF rm_item.r10_proveedor IS NOT NULL THEN
	INITIALIZE r_c04.* TO NULL
	DECLARE q_cost_prov CURSOR FOR
		SELECT * FROM ordt004
			WHERE c04_compania  = vg_codcia
			  AND c04_localidad = vg_codloc
			  AND c04_codprov   = rm_item.r10_proveedor
			  AND c04_cod_item  = rm_item.r10_codigo
			ORDER BY c04_fecha_vigen DESC
	OPEN q_cost_prov
	FETCH q_cost_prov INTO r_c04.*
	CLOSE q_cost_prov
	FREE q_cost_prov
	LET rm_item.r10_precio_mb = r_c04.c04_pvp_prov_sug
	LET rm_item.r10_costo_mb  = r_c04.c04_costo_prov
END IF
LET rm_item.r10_estado = 'A'
LET act_lista_precios = 'S'
LET codigo_anterior = rm_item.r10_codigo
LET rm_item.r10_codigo = NULL
CALL muestra_estado()
DISPLAY BY NAME rm_item.r10_estado, rm_item.r10_nombre, rm_item.r10_cod_clase,
				rm_item.r10_marca, rm_item.r10_tipo, rm_item.r10_uni_med,
				rm_item.r10_modelo, rm_item.r10_filtro, rm_item.r10_fob,
				rm_item.r10_cod_util, rm_item.r10_proveedor,
				rm_item.r10_precio_mb, rm_item.r10_costo_mb, act_lista_precios,
				rm_item.r10_cod_pedido, rm_item.r10_cod_comerc
DISPLAY rm_clase.r72_desc_clase TO tit_clase
DISPLAY rm_marca.r73_desc_marca TO tit_marca
DISPLAY rm_titem.r06_nombre     TO nom_tipo
DISPLAY rm_uni.r05_siglas       TO nom_uni
DISPLAY rm_prov.p01_nomprov     TO nom_prov
LET int_flag = 0
INPUT BY NAME rm_item.r10_codigo, rm_item.r10_nombre, rm_item.r10_cod_clase,
			  rm_item.r10_marca, rm_item.r10_tipo, rm_item.r10_uni_med,
			  rm_item.r10_modelo, rm_item.r10_filtro, rm_item.r10_fob,
			  rm_item.r10_cod_util, rm_item.r10_proveedor,rm_item.r10_precio_mb,
			  rm_item.r10_costo_mb, act_lista_precios, rm_item.r10_cod_pedido, 
			  rm_item.r10_cod_comerc
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_item.r10_codigo, rm_item.r10_nombre,
							 rm_item.r10_cod_clase, rm_item.r10_marca,
							 rm_item.r10_tipo, rm_item.r10_uni_med,
							 rm_item.r10_modelo, rm_item.r10_filtro,
							 rm_item.r10_fob, rm_item.r10_cod_util,
							 rm_item.r10_proveedor, rm_item.r10_precio_mb,
							 rm_item.r10_costo_mb, act_lista_precios,
							 rm_item.r10_cod_pedido, rm_item.r10_cod_comerc)
		THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
	ON KEY(F2)
		IF INFIELD(r10_cod_clase) THEN
			CALL fl_ayuda_clase_ventas_rep(vg_codcia, rm_item.r10_linea,
											rm_item.r10_sub_linea,
											rm_item.r10_cod_grupo)
				RETURNING r_r72.r72_cod_clase, r_r72.r72_desc_clase
			IF r_r72.r72_cod_clase IS NOT NULL THEN
				LET rm_item.r10_cod_clase = r_r72.r72_cod_clase
				DISPLAY BY NAME rm_item.r10_cod_clase
				DISPLAY r_r72.r72_desc_clase TO tit_clase
			END IF
		END IF
		IF INFIELD(r10_marca) THEN
			CALL fl_ayuda_marcas_rep_asignadas(vg_codcia, rm_item.r10_cod_clase)
				RETURNING r_r73.r73_marca
			IF r_r73.r73_marca IS NOT NULL THEN
				LET rm_item.r10_marca = r_r73.r73_marca
				CALL fl_lee_marca_rep(vg_codcia, rm_item.r10_marca)
					RETURNING r_r73.*
				DISPLAY BY NAME rm_item.r10_marca
				DISPLAY r_r73.r73_desc_marca TO tit_marca
			END IF
		END IF
		IF INFIELD(r10_tipo) THEN
			CALL fl_ayuda_tipo_item()
				RETURNING r_r06.r06_codigo, r_r06.r06_nombre
			IF r_r06.r06_codigo IS NOT NULL THEN
				LET rm_item.r10_tipo = r_r06.r06_codigo
				DISPLAY BY NAME rm_item.r10_tipo
				DISPLAY r_r06.r06_nombre TO nom_tipo
			END IF
		END IF
		IF INFIELD(r10_uni_med) THEN
			CALL fl_ayuda_unidad_medida()
				RETURNING r_r05.r05_codigo, r_r05.r05_siglas
			IF r_r05.r05_codigo IS NOT NULL THEN
				LET rm_item.r10_uni_med = r_r05.r05_codigo
				DISPLAY BY NAME rm_item.r10_uni_med
				DISPLAY r_r05.r05_siglas TO nom_uni
			END IF
		END IF
		IF INFIELD(r10_cod_util) THEN
			CALL fl_ayuda_factor_utilidad_rep(vg_codcia)
				RETURNING r_r77.r77_codigo_util
				IF r_r77.r77_codigo_util IS NOT NULL THEN
					LET rm_item.r10_cod_util = r_r77.r77_codigo_util
					DISPLAY BY NAME rm_item.r10_cod_util
				END IF
		END IF
		IF INFIELD(r10_proveedor) THEN
			CALL fl_ayuda_proveedores()
				RETURNING r_p01.p01_codprov, r_p01.p01_nomprov
			IF r_p01.p01_codprov IS NOT NULL THEN
				LET rm_item.r10_proveedor = r_p01.p01_codprov
				DISPLAY BY NAME rm_item.r10_proveedor
				DISPLAY r_p01.p01_nomprov TO nom_prov
			END IF
		END IF
		LET int_flag = 0
	BEFORE FIELD r10_costo_mb
		LET costo_mb = rm_item.r10_costo_mb
	AFTER FIELD r10_codigo
		IF rm_item.r10_codigo IS NOT NULL THEN
			CALL fl_lee_item(vg_codcia, rm_item.r10_codigo) RETURNING r_r10.*
			IF r_r10.r10_codigo IS NOT NULL THEN
				CALL fl_mostrar_mensaje('Ya existe el Item en la Compañía.','exclamation')
				NEXT FIELD r10_codigo
			END IF
		END IF
	AFTER FIELD r10_cod_clase
		IF rm_item.r10_cod_clase IS NOT NULL THEN
			CALL fl_lee_clase_rep(vg_codcia, rm_item.r10_linea,
								rm_item.r10_sub_linea, rm_item.r10_cod_grupo,
								rm_item.r10_cod_clase)
				RETURNING r_r72.*
			IF r_r72.r72_cod_clase IS NULL THEN
				CALL fl_mostrar_mensaje('La Clase no existe en la compañía.','exclamation')
				NEXT FIELD r10_cod_clase
			END IF
			IF rm_grupo.r71_cod_grupo IS NOT NULL THEN
				IF rm_grupo.r71_cod_grupo <> r_r72.r72_cod_grupo THEN
					CALL mensaje_error_clase()
				END IF
			END IF
			DISPLAY r_r72.r72_desc_clase TO tit_clase
		ELSE
			CLEAR tit_clase
		END IF
	AFTER FIELD r10_marca
		IF rm_item.r10_marca IS NOT NULL THEN
			CALL fl_lee_marca_rep(vg_codcia, rm_item.r10_marca)
				RETURNING r_r73.*
			IF r_r73.r73_marca IS NULL THEN
				CALL fl_mostrar_mensaje('La Marca no existe en la compañía.','exclamation')
				NEXT FIELD r10_marca
			END IF
			DISPLAY r_r73.r73_desc_marca TO tit_marca
		ELSE
			CLEAR tit_marca
		END IF
	AFTER FIELD r10_tipo
		IF rm_item.r10_tipo IS NOT NULL THEN
			CALL fl_lee_tipo_item(rm_item.r10_tipo) RETURNING r_r06.*
			IF r_r06.r06_codigo IS NULL THEN
				CALL fl_mostrar_mensaje('El Tipo de Item no existe en la compañía.','exclamation')
				NEXT FIELD r10_tipo
			END IF
			DISPLAY r_r06.r06_nombre TO nom_tipo
		ELSE
			CLEAR nom_tipo
		END IF
	AFTER FIELD r10_uni_med
		IF rm_item.r10_uni_med IS NOT NULL THEN
			CALL fl_lee_unidad_medida(rm_item.r10_uni_med) RETURNING r_r05.*
			IF r_r05.r05_codigo IS NULL THEN
				CALL fl_mostrar_mensaje('La Unidad de Medida no existe en la compañía.','exclamation')
				NEXT FIELD r10_uni_med
			END IF
			DISPLAY r_r05.r05_siglas TO nom_uni
		ELSE
			CLEAR nom_uni
		END IF
	AFTER FIELD r10_proveedor
		IF rm_item.r10_proveedor IS NOT NULL THEN
			CALL fl_lee_proveedor(rm_item.r10_proveedor) RETURNING r_p01.*
			IF r_p01.p01_codprov IS NULL THEN
				CALL fl_mostrar_mensaje('No existe proveedor: ' || r_p01.p01_codprov,'exclamation')
				NEXT FIELD r10_proveedor
			END IF
			IF r_p01.p01_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD r10_proveedor
			END IF
			DISPLAY r_p01.p01_nomprov TO nom_prov
		ELSE
			CLEAR nom_prov
		END IF
	AFTER FIELD r10_precio_mb
		IF rm_item.r10_precio_mb IS NOT NULL THEN
			LET rm_item.r10_precio_mb =
						fl_retorna_precision_valor(rg_gen.g00_moneda_base,
													rm_item.r10_precio_mb)
		END IF
	AFTER FIELD r10_costo_mb
		IF tiene_stock(costo_mb) THEN
			LET rm_item.r10_costo_mb = costo_mb
		END IF
		DISPLAY BY NAME rm_item.r10_costo_mb
	AFTER INPUT
		IF rm_clase.r72_compania IS NULL THEN
			CALL mensaje_error_clase()
			NEXT FIELD r10_cod_clase
		END IF
		IF rm_item.r10_cod_util IS NOT NULL THEN
			CALL fl_lee_factor_utilidad_rep(vg_codcia, rm_item.r10_cod_util)
				RETURNING r_r77.*
			IF r_r77.r77_codigo_util IS NULL THEN
				CALL fl_mostrar_mensaje('El Factor de Utilidad no existe en esta Compañía.','exclamation')
				NEXT FIELD r10_cod_util
			END IF
		END IF
		IF rm_item.r10_precio_mb <= rm_item.r10_costo_mb THEN
			CALL fl_mostrar_mensaje('El P. V. P debe ser mayor que el costo.', 'exclamation')
			NEXT FIELD r10_precio_mb
		END IF
END INPUT
IF int_flag THEN
	LET int_flag = 0
	CLOSE WINDOW w_repf108_9
	RETURN
END IF
CALL fl_lee_compania_repuestos(vg_codcia) RETURNING rm_r00.*
INITIALIZE rm_lin.*, rm_uni.*, rm_titem.*, rm_par.*, rm_rot.* TO NULL
BEGIN WORK
	IF rm_item.r10_codigo IS NULL THEN
		CALL retorna_sec_cod_item() RETURNING rm_item.r10_codigo
	END IF
	LET rm_item.r10_costult_mb  = 0
	LET rm_item.r10_costult_ma  = 0
	LET rm_item.r10_precio_ant  = 0
	LET rm_item.r10_fec_camprec = NULL
	LET rm_item.r10_usu_cosrepo = NULL
	LET rm_item.r10_fec_cosrepo = NULL
	LET rm_item.r10_fec_camprec = NULL
	LET rm_item.r10_cod_comerc  = NULL
	LET rm_item.r10_usuario     = vg_usuario
	LET rm_item.r10_fecing      = fl_current()
	INSERT INTO rept010 VALUES(rm_item.*)
	IF vm_num_rows = vm_max_rows THEN
		LET vm_num_rows = 1
	ELSE
		LET vm_num_rows = vm_num_rows + 1
	END IF
	LET vm_r_rows[vm_num_rows] = SQLCA.SQLERRD[6] 
	LET vm_row_current         = vm_num_rows
	INSERT INTO rept011
	      (r11_compania, r11_bodega, r11_item, r11_ubicacion,
	       r11_stock_ant, r11_stock_act, r11_ing_dia, r11_egr_dia)
	  VALUES(vg_codcia, rm_r00.r00_bodega_fact, rm_item.r10_codigo, 'SN', 0, 0,
			 0, 0)
	-- Agregamos un registro a la lista de precios del proveedor 
	IF act_lista_precios = 'S' THEN
		LET fecha_actual = fl_current()
		LET query = 'INSERT INTO ordt004 ',
						'(c04_compania, c04_localidad, c04_codprov,',
						' c04_cod_item, c04_fecha_vigen, c04_pvp_prov_sug,',
						' c04_desc_prov, c04_costo_prov, c04_fecha_fin,',
						' c04_usuario, c04_fecing) ',
						'SELECT c04_compania, c04_localidad, c04_codprov, ',
							'"', rm_item.r10_codigo CLIPPED, '", ',
							'"', vg_fecha, '", c04_pvp_prov_sug, ',
							'c04_desc_prov, c04_costo_prov, c04_fecha_fin, ',
							'"', vg_usuario CLIPPED, '", "', fecha_actual, '" ',
			  			' FROM ordt004 ',
						' WHERE c04_compania  = ', vg_codcia,
						'   AND c04_localidad = ', vg_codloc,
						'   AND c04_cod_item  = "', codigo_anterior CLIPPED,
												'" ',
						'   AND (c04_fecha_fin >= "', vg_fecha, '" ',
						'    OR  c04_fecha_fin IS NULL) '
		PREPARE ins_c04 FROM query
		EXECUTE ins_c04
	END IF
COMMIT WORK
LET vm_clonado = 'S'
CALL fl_mostrar_mensaje('Item ha sido clonado exitosamente.', 'info')
CLOSE WINDOW w_repf108_9
LET int_flag = 0
CALL fl_hacer_pregunta('Desea Modificar éste Item ?', 'No') RETURNING resp
IF resp <> 'Yes' THEN
	LET vm_clonado = 'N'
	RETURN
END IF
CALL control_modificacion()
LET vm_clonado = 'N'
RETURN

END FUNCTION



FUNCTION tiene_acceso_clonador()

IF (rm_g05.g05_grupo = 'SI' OR rm_g05.g05_grupo = 'GE') AND
   (rm_g05.g05_tipo = 'AG')
THEN
	RETURN 1
ELSE
	RETURN 0
END IF

END FUNCTION


 
FUNCTION control_movimientos()
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE bodega		LIKE rept002.r02_codigo
DEFINE col_ini		SMALLINT
DEFINE col_fin		SMALLINT
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE
DEFINE fec_ini, fec_fin	DATE
DEFINE comando		CHAR(400)
DEFINE run_prog		CHAR(10)

LET col_ini = 15
LET col_fin = 54
IF vg_gui = 0 THEN
	LET col_ini = 14
	LET col_fin = 54
END IF
OPEN WINDOW w_repf108_8 AT 08, col_ini WITH 12 ROWS, col_fin COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_repf108_8 FROM '../forms/repf108_8'
ELSE
	OPEN FORM f_repf108_8 FROM '../forms/repf108_8c'
END IF
DISPLAY FORM f_repf108_8
CLEAR FORM
DISPLAY BY NAME rm_item.r10_codigo, rm_item.r10_nombre
INITIALIZE r_r02.*, vm_stock_inicial TO NULL
LET bodega    = NULL
LET fecha_fin = vg_fecha
LET fecha_ini = MDY(MONTH(fecha_fin), 01, YEAR(fecha_fin))
WHILE TRUE
	LET int_flag = 0
	INPUT BY NAME bodega, fecha_ini, fecha_fin
		WITHOUT DEFAULTS
	        ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT INPUT
		ON KEY(F2)
			IF INFIELD(bodega) THEN
				CALL fl_ayuda_bodegas_rep(vg_codcia, vg_codloc,
							'T', 'T', 'A', 'T', '2')
					RETURNING r_r02.r02_codigo,
						  r_r02.r02_nombre
				IF r_r02.r02_codigo IS NOT NULL THEN
					LET bodega = r_r02.r02_codigo
					DISPLAY BY NAME bodega, r_r02.r02_nombre
				END IF
			END IF
			LET int_flag = 0
		BEFORE FIELD fecha_ini
			LET fec_ini = fecha_ini
		BEFORE FIELD fecha_fin
			LET fec_fin = fecha_fin
		AFTER FIELD bodega 
			IF bodega IS NOT NULL THEN
				CALL fl_lee_bodega_rep(vg_codcia, bodega)
					RETURNING r_r02.* 
				IF r_r02.r02_codigo IS NULL  THEN
					CALL fl_mostrar_mensaje('La bodega no existe en la Compañía.','exclamation')
					NEXT FIELD bodega
				END IF
				DISPLAY BY NAME r_r02.r02_nombre
				IF r_r02.r02_localidad <> vg_codloc THEN
					CALL fl_mostrar_mensaje('No puede ver movimientos de esta bodega, porque no pertenece a esta localidad.', 'exclamation')
					NEXT FIELD bodega
				END IF
				CALL obtener_stock_inicial_bodega(bodega,
							fecha_ini, fecha_fin)
					RETURNING bodega
				DISPLAY BY NAME bodega
			ELSE
				INITIALIZE r_r02.*, vm_stock_inicial TO NULL
				DISPLAY BY NAME vm_stock_inicial
				CLEAR r02_nombre
			END IF
		AFTER FIELD fecha_ini
			IF fecha_ini IS NOT NULL THEN
				IF fecha_ini > vg_fecha THEN
					CALL fl_mostrar_mensaje('La Fecha Inicial no puede ser mayor que la fecha de hoy.', 'exclamation')
					NEXT FIELD fecha_ini
				END IF
				IF bodega IS NOT NULL THEN
				       CALL obtener_stock_inicial_bodega(bodega,
							fecha_ini, fecha_fin)
						RETURNING bodega
					DISPLAY BY NAME bodega
				ELSE
					INITIALIZE vm_stock_inicial TO NULL
					DISPLAY BY NAME vm_stock_inicial
				END IF
			ELSE
				LET fecha_ini = fec_ini
				DISPLAY BY NAME fecha_ini
			END IF
		AFTER FIELD fecha_fin
			IF fecha_fin IS NOT NULL THEN
				IF fecha_fin > vg_fecha THEN
					CALL fl_mostrar_mensaje('La Fecha Final no puede ser mayor que la fecha de hoy.', 'exclamation')
					NEXT FIELD fecha_fin
				END IF
			ELSE
				LET fecha_fin = fec_fin
				DISPLAY BY NAME fecha_fin
			END IF
		AFTER INPUT
			IF fecha_ini > fecha_fin THEN
				CALL fl_mostrar_mensaje('La Fecha Final no puede ser menor que la Fecha Inicial.', 'exclamation')
				NEXT FIELD fecha_fin
			END IF
	END INPUT
	IF int_flag THEN
		EXIT WHILE
	END IF
	LET run_prog = '; fglrun '
	IF vg_gui = 0 THEN
		LET run_prog = '; fglgo '
	END IF
	IF bodega IS NULL THEN
		LET bodega = 'XX'
	END IF
	LET comando = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS',
			vg_separador, 'fuentes', vg_separador, run_prog,
			'repp307 ', vg_base, ' ', vg_modulo, ' ', vg_codcia,
			' ', vg_codloc, ' "', bodega CLIPPED, '" "',
			rm_item.r10_codigo CLIPPED, '" "', fecha_ini, '" "',
			fecha_fin, '" 0'
	RUN comando
	IF bodega = 'XX' THEN
		LET bodega = NULL
	END IF
END WHILE
LET int_flag = 0
CLOSE WINDOW w_repf108_8
RETURN

END FUNCTION



FUNCTION obtener_stock_inicial_bodega(bod, fecha_ini, fecha_fin)
DEFINE bod		LIKE rept019.r19_bodega_ori
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE
DEFINE fec_ini		LIKE rept020.r20_fecing
DEFINE bodega		LIKE rept019.r19_bodega_ori
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE r_g21		RECORD LIKE gent021.*
DEFINE query         	CHAR(800)

LET fec_ini = EXTEND(fecha_ini, YEAR TO SECOND)
LET query = 'SELECT rept020.*, rept019.*, gent021.* ' ,
		' FROM rept020, rept019, gent021 ',
		' WHERE r20_compania   = ', vg_codcia,
		'   AND r20_localidad = ', vg_codloc, 
		'   AND r20_item       = "', rm_item.r10_codigo, '"',
		'   AND r20_fecing    <= "', fec_ini, '"',
		'   AND r20_compania   = r19_compania ',
		'   AND r20_localidad  = r19_localidad ',
		'   AND r20_cod_tran   = r19_cod_tran ',
		'   AND r20_num_tran   = r19_num_tran ',
		'   AND r20_cod_tran   = g21_cod_tran ',
		' ORDER BY r20_fecing DESC'
PREPARE cons_stock FROM query
DECLARE q_sto CURSOR FOR cons_stock
LET vm_stock_inicial = 0
OPEN q_sto
FETCH q_sto INTO r_r20.*, r_r19.*, r_g21.*
IF STATUS <> NOTFOUND THEN
	LET bodega = bod
	IF r_g21.g21_tipo = 'T' THEN
		IF bod = r_r19.r19_bodega_ori THEN
			LET bodega = r_r19.r19_bodega_ori
		END IF
		IF bod = r_r19.r19_bodega_dest THEN
			LET bodega = r_r19.r19_bodega_dest
		END IF
	ELSE
		IF r_g21.g21_tipo <> 'C' THEN
			LET bodega = r_r20.r20_bodega
		END IF
	END IF
	IF r_g21.g21_tipo <> 'T' THEN
		IF r_g21.g21_tipo = 'E' THEN
			LET r_r20.r20_cant_ven = r_r20.r20_cant_ven * (-1)
		END IF
		LET vm_stock_inicial = r_r20.r20_stock_ant + r_r20.r20_cant_ven
	ELSE
		IF bodega = r_r19.r19_bodega_ori THEN
			LET vm_stock_inicial = r_r20.r20_stock_ant
						- r_r20.r20_cant_ven
		END IF
		IF bodega = r_r19.r19_bodega_dest THEN
			LET vm_stock_inicial = r_r20.r20_stock_bd
						+ r_r20.r20_cant_ven
		END IF
	END IF
END IF
DISPLAY BY NAME vm_stock_inicial
IF bodega <> bod THEN
	CALL fl_mostrar_mensaje('Pero tiene Stock Inicial en la Bodega ' || bodega CLIPPED, 'info')
	LET bod = bodega
END IF
RETURN bod

END FUNCTION



FUNCTION retorna_sec_cod_item()
DEFINE cod_item		INTEGER

INITIALIZE cod_item TO NULL

SELECT MAX(r10_codigo) + 1 nue_ite 
  INTO cod_item
  FROM rept010 
 WHERE r10_compania = rm_item.r10_compania

IF cod_item IS NULL THEN
	LET cod_item = 1
END IF

RETURN cod_item

END FUNCTION
