--------------------------------------------------------------------------------
-- Titulo           : repp246.4gl - Mantenimiento de Items - Pedidos
-- Elaboracion      : 11-Dic-2008
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp246 base modulo compania localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
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



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp246.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN     -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vm_max_rows = 10000
LET vg_proceso  = 'repp246'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()

CALL fl_nivel_isolation()
OPEN WINDOW w_item AT 3,2 WITH 22 ROWS, 80 COLUMNS 
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
			MESSAGE LINE LAST - 1)
OPEN FORM f_item FROM '../forms/repf246_1'
DISPLAY FORM f_item 

CALL fl_lee_usuario(vg_usuario)             RETURNING rm_g05.*
CALL fl_lee_grupo_usuario(rm_g05.g05_grupo) RETURNING rm_g04.*

LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
CLEAR tit_estado
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Existencias'
		HIDE OPTION 'Movimientos'
		HIDE OPTION 'Pedidos'
		IF num_args() = 5 THEN
			HIDE OPTION 'Modificar'
			HIDE OPTION 'Consultar'
			CALL control_consulta()
			SHOW OPTION 'Existencias'
			SHOW OPTION 'Movimientos'
			SHOW OPTION 'Pedidos'
		END IF
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
                CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Existencias'
			SHOW OPTION 'Movimientos'
			SHOW OPTION 'Pedidos'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Existencias'
				HIDE OPTION 'Movimientos'
				HIDE OPTION 'Pedidos'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Existencias'
			SHOW OPTION 'Movimientos'
			SHOW OPTION 'Pedidos'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
	COMMAND KEY('K') 'Movimientos'		'Movimientos del item'
		CALL control_movimientos()
	COMMAND KEY('E') 'Existencias'		'Consulta existencia del item'
		CALL control_existencias()
	COMMAND KEY('P') 'Pedidos'		'Consulta pedidos del item'
		CALL control_pedidos()
        COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro. '
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
        COMMAND KEY('R') 'Retroceder'  'Ver anterior registro. '
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
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)
DEFINE capitulo		LIKE gent016.g16_capitulo

CLEAR FORM
INITIALIZE rm_item.*, capitulo TO NULL
LET int_flag = 0
IF num_args() = 4 THEN
    	CONSTRUCT BY NAME expr_sql ON r10_codigo, r10_estado, r10_nombre,
		r10_linea, r10_sub_linea, r10_cod_grupo, r10_cod_clase,
		r10_marca, r10_cod_pedido, r10_uni_med, r10_cod_comerc,
		r10_peso, r10_partida, r10_fob, r10_monfob, r10_usu_cosrepo,
		r10_fec_cosrepo
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
		IF INFIELD(r10_linea) THEN
		     CALL fl_ayuda_lineas_rep(vg_codcia)
		     RETURNING rm_lin.r03_codigo, rm_lin.r03_nombre
		     IF rm_lin.r03_codigo IS NOT NULL THEN
			LET rm_item.r10_linea = rm_lin.r03_codigo
			DISPLAY BY NAME rm_item.r10_linea
			DISPLAY rm_lin.r03_nombre TO nom_lin
		     END IF
		END IF
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
		     CALL fl_ayuda_marcas_rep_asignadas(vg_codcia,
							rm_item.r10_cod_clase)
		     	RETURNING rm_marca.r73_marca
		     IF rm_marca.r73_marca IS NOT NULL THEN
			LET rm_item.r10_marca = rm_marca.r73_marca
                    	CALL fl_lee_marca_rep(vg_codcia, rm_item.r10_marca)
                    		RETURNING rm_marca.*
			DISPLAY BY NAME rm_item.r10_marca
			DISPLAY rm_marca.r73_desc_marca TO tit_marca
		     END IF
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
		AFTER FIELD r10_linea
			LET rm_item.r10_linea = GET_FLDBUF(r10_linea)
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
		AFTER FIELD r10_linea
			LET rm_item.r10_linea     = GET_FLDBUF(r10_linea)
			IF rm_item.r10_linea IS NULL THEN
				CLEAR nom_lin
                	END IF
		AFTER FIELD r10_sub_linea
			LET rm_item.r10_sub_linea = GET_FLDBUF(r10_sub_linea)
			IF rm_item.r10_sub_linea IS NULL THEN
				CLEAR tit_sub_linea
                	END IF
		AFTER FIELD r10_cod_grupo
			LET rm_item.r10_cod_grupo = GET_FLDBUF(r10_cod_grupo)
			IF rm_item.r10_cod_grupo IS NULL THEN
				CLEAR tit_grupo
                	END IF
		AFTER FIELD r10_cod_clase
			LET rm_item.r10_cod_clase = GET_FLDBUF(r10_cod_clase)
			IF rm_item.r10_cod_clase IS NULL THEN
				CLEAR tit_clase
                	END IF
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



FUNCTION control_modificacion()

IF rm_item.r10_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
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
CALL lee_datos()
IF int_flag THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	RETURN
END IF
CALL cambio_modificacion()
UPDATE rept010 SET * = rm_item.* WHERE CURRENT OF q_up
COMMIT WORK
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION lee_datos()
DEFINE resp 		VARCHAR(6)
DEFINE capitulo		LIKE gent016.g16_capitulo
DEFINE cod_comerc	LIKE rept010.r10_cod_comerc

LET capitulo = NULL
LET int_flag = 0
INPUT BY NAME rm_item.r10_cod_pedido, rm_item.r10_uni_med,
	rm_item.r10_cod_comerc, rm_item.r10_peso, rm_item.r10_partida,
	rm_item.r10_fob, rm_item.r10_monfob
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_item.r10_cod_pedido, rm_item.r10_uni_med,
				 rm_item.r10_cod_comerc, rm_item.r10_peso,
				 rm_item.r10_partida, rm_item.r10_fob,
				 rm_item.r10_monfob)
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
END INPUT

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
		rm_item.r10_cod_clase, rm_item.r10_marca,
		rm_item.r10_cod_pedido, rm_item.r10_uni_med,
		rm_item.r10_cod_comerc, rm_item.r10_peso, rm_item.r10_partida,
		rm_item.r10_fob, rm_item.r10_monfob, rm_item.r10_usu_cosrepo,
		rm_item.r10_fec_cosrepo
CALL fl_lee_unidad_medida(rm_item.r10_uni_med) RETURNING rm_uni.*
DISPLAY rm_uni.r05_siglas TO nom_uni
CALL fl_lee_partida(rm_item.r10_partida) RETURNING rm_par.*
DISPLAY rm_par.g16_desc_par TO nom_par
CALL fl_lee_moneda(rm_item.r10_monfob) RETURNING rm_mon.*
DISPLAY rm_mon.g13_nombre TO nom_mon
CALL fl_lee_linea_rep(vg_codcia, rm_item.r10_linea) RETURNING rm_lin.*
DISPLAY rm_lin.r03_nombre TO nom_lin
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
CALL muestra_estado()

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current	SMALLINT
DEFINE num_rows		SMALLINT

DISPLAY row_current, num_rows TO vm_row_current, vm_num_rows

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
DEFINE fecing		LIKE rept076.r76_fecing
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
		WHERE r02_compania = vg_codcia
		  AND r02_compania = r11_compania
		  AND r02_codigo   NOT IN ('QC', 'GC')
		  AND r11_item     = rm_item.r10_codigo
                  AND r11_bodega   = r02_codigo
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
	CALL fl_lee_bodega_rep(vg_codcia, rm_r00.r00_bodega_fact) RETURNING rb.*
	INITIALIZE r_exist[1].* TO NULL
	LET r_exist[1].bodega   = rm_r00.r00_bodega_fact
	LET r_exist[1].n_bodega	= rb.r02_nombre
	LET r_exist[1].stock    = 0
END IF
LET i = i - 1
IF i = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	CLOSE WINDOW w_108_2
        RETURN
END IF

DISPLAY BY NAME total_sto
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY r_exist TO ra_exist.*
	ON KEY(INTERRUPT)
		EXIT DISPLAY
	BEFORE DISPLAY
		--#CALL dialog.keysetlabel('ACCEPT', '')
	BEFORE ROW
		LET j = arr_curr()
	AFTER DISPLAY
		CONTINUE DISPLAY
END DISPLAY

CLOSE WINDOW w_108_2

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

DECLARE q_pedido CURSOR FOR
	SELECT r17_pedido, r16_proveedor, r16_fec_llegada, r17_cantped, r17_fob
		FROM rept016, rept017
		WHERE r17_compania  = vg_codcia
	          AND r17_item      = rm_item.r10_codigo
		  --AND r17_cantped   > r17_cantrec 
		  --AND r17_estado    NOT IN ('A', 'P')
		  AND r16_compania  = r17_compania
                  AND r16_localidad = r17_localidad
                  AND r16_pedido    = r17_pedido
	--UNION ALL
	UNION
	SELECT r17_pedido, r16_proveedor, r16_fec_llegada, 
	       (r17_cantped - r17_cantrec), r17_fob
		FROM rept016, rept017
		WHERE r17_compania  = vg_codcia
	          AND r17_item      = rm_item.r10_codigo
		  AND r17_cantped   > r17_cantrec 
		  --AND r17_estado    = 'P'
		  AND r16_compania  = r17_compania
                  AND r16_localidad = r17_localidad
                  AND r16_pedido    = r17_pedido
	ORDER BY r16_fec_llegada DESC
                  
LET i = 1
FOREACH q_pedido INTO r_pedido[i].*
	LET i = i + 1
	IF i > 1000 THEN
		EXIT FOREACH
	END IF
END FOREACH
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



FUNCTION cambio_modificacion()

LET rm_item.r10_usu_cosrepo = NULL
LET rm_item.r10_fec_cosrepo = NULL
--IF rm_item.r10_costrepo_mb IS NOT NULL THEN
	LET rm_item.r10_usu_cosrepo = vg_usuario
	LET rm_item.r10_fec_cosrepo = fl_current()
--END IF
DISPLAY BY NAME rm_item.r10_usu_cosrepo, rm_item.r10_fec_cosrepo

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
OPEN WINDOW w_repf246_8 AT 08, col_ini WITH 12 ROWS, col_fin COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_repf246_8 FROM '../forms/repf108_8'
ELSE
	OPEN FORM f_repf246_8 FROM '../forms/repf108_8c'
END IF
DISPLAY FORM f_repf246_8
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
CLOSE WINDOW w_repf246_8
RETURN

END FUNCTION



FUNCTION obtener_stock_inicial_bodega(bod, fecha_ini, fecha_fin)
DEFINE bod		LIKE rept019.r19_bodega_ori
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE
DEFINE fec_ini		LIKE rept020.r20_fecing
DEFINE bodega		LIKE rept019.r19_bodega_ori
DEFINE codloc		LIKE rept019.r19_localidad
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE r_g21		RECORD LIKE gent021.*
DEFINE query         	CHAR(800)

LET fec_ini = EXTEND(fecha_ini, YEAR TO SECOND)
LET codloc  = 0
IF vg_codloc = 3 THEN
	--LET codloc = 5
	LET codloc = 3
END IF
LET query = 'SELECT rept020.*, rept019.*, gent021.* ' ,
		' FROM rept020, rept019, gent021 ',
		' WHERE r20_compania   = ', vg_codcia,
		'   AND r20_localidad IN (', vg_codloc, ', ', codloc, ')',
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
