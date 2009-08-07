--------------------------------------------------------------------------------
-- Titulo           : repp108.4gl - Mantenimiento de Items 
-- Elaboracion      : 15-sep-2001
-- Autor            : GVA
-- Formato Ejecucion: fglrun repp108 base RE 1 
-- Ultima Correccion: 11-ene-2002 (JCM)
-- Motivo Correccion: Se aumento el campo r10_filtro a la tabla rept010 y se
--                    aumento la consulta de sustituciones
--		      Se creó otro ON KEY para Ubicación, se agregó la forma
--		      repf108_6.per (RCA)
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_rows ARRAY[1000] OF INTEGER -- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT      -- FILA CORRIENTE DEL ARREGLO LINEA VTA
DEFINE vm_num_rows	SMALLINT	 -- CANTIDAD DE FILAS LEIDAS LINEA VTA
DEFINE vm_r_rows   ARRAY[1000] OF INTEGER -- ARREGLO DE ROWID DE FILAS LEIDAS 

DEFINE rm_mon		RECORD LIKE gent013.*  	-- MONEDA
DEFINE rm_par		RECORD LIKE gent016.*	-- PARTIDA ARANCELARIA 
DEFINE rm_lin		RECORD LIKE rept003.*	-- LINEA DE VENTA
DEFINE rm_item		RECORD LIKE rept010.*	-- MAESTRO ITEMS
DEFINE rm_item2		RECORD LIKE rept010.*	-- AUX. MAESTRO ITEMS
DEFINE rm_uni		RECORD LIKE rept005.*	-- UNIDAD DE MEDIDA
DEFINE rm_rot		RECORD LIKE rept004.*	-- INDICE DE ROTACION
DEFINE rm_titem		RECORD LIKE rept006.*	-- TIPO DE ITEM	
DEFINE rm_conf 		RECORD LIKE gent000.*	-- CONFIGURACION DE FACTURACION
DEFINE rm_cmon 		RECORD LIKE gent014.*	-- CONVERSION ENTRE MONEDAS
DEFINE rm_r00 		RECORD LIKE rept000.*	-- CONFIGURACION DE REPUESTOS
DEFINE vm_flag_mant	CHAR(1)
DEFINE vm_max_rows	SMALLINT

DEFINE rm_g04		RECORD LIKE gent004.*
DEFINE rm_g05		RECORD LIKE gent005.*

DEFINE vm_sustituye	LIKE rept014.r14_item_nue
DEFINE vm_sustituido	LIKE rept014.r14_item_ant



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp108.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 4 THEN     -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
        'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vm_max_rows = 1000
LET vg_proceso = 'repp108'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()

CALL fl_nivel_isolation()
OPEN WINDOW w_item AT 3,2 WITH 23 ROWS, 80 COLUMNS 
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2)
OPEN FORM f_item FROM '../forms/repf108_1'
DISPLAY FORM f_item 

CALL fl_lee_usuario(vg_usuario)            RETURNING rm_g05.*
CALL fl_lee_grupo_usuario(rm_g05.g05_grupo) RETURNING rm_g04.*

INITIALIZE vm_sustituye, vm_sustituido TO NULL

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
		HIDE OPTION 'Modelos'
		HIDE OPTION 'Pedidos'
		HIDE OPTION 'Bloquear/Activar'
		HIDE OPTION 'Sustituye a'
		HIDE OPTION 'Sustituido por'
		HIDE OPTION 'Estadisticas'
		HIDE OPTION 'Ubicación'
		IF num_args() = 4 THEN
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Modificar'
			HIDE OPTION 'Consultar'
			HIDE OPTION 'Modelos'
			CALL control_consulta()
			SHOW OPTION 'Existencias'
			SHOW OPTION 'Pedidos'
			IF vm_sustituye IS NOT NULL THEN
				SHOW OPTION 'Sustituye a'
			END IF
			IF vm_sustituido IS NOT NULL THEN
				SHOW OPTION 'Sustituido por'
			END IF
			SHOW OPTION 'Estadisticas'
			SHOW OPTION 'Ubicación'
		END IF
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		HIDE OPTION 'Sustituye a'
		HIDE OPTION 'Sustituido por'
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Bloquear/Activar'
			SHOW OPTION 'Modelos'
		END IF
		IF vm_num_rows > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF		
		HIDE OPTION 'Estadisticas'
		HIDE OPTION 'Existencias'
		HIDE OPTION 'Pedidos'
	COMMAND KEY('M') 'Modificar' 'Modificar registro corriente'
		IF vm_num_rows > 0 THEN
			CALL control_modificacion()
		ELSE
			CALL fl_mensaje_consultar_primero()
		END IF	
        COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		HIDE OPTION 'Sustituye a'
		HIDE OPTION 'Sustituido por'
		HIDE OPTION 'Estadisticas'
                CALL control_consulta()
		IF vm_num_rows < 1 THEN
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Modelos'
				HIDE OPTION 'Bloquear/Activar'
				HIDE OPTION 'Existencias'
				HIDE OPTION 'Pedidos'
				HIDE OPTION 'Ubicación'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Modelos'
			SHOW OPTION 'Existencias'
			SHOW OPTION 'Pedidos'
			SHOW OPTION 'Ubicación'
			IF rm_item.r10_estado <> 'S' THEN
				SHOW OPTION 'Bloquear/Activar'
			END IF
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
	COMMAND KEY('L') 'Modelos'		'Modelos en los que este item sirve'
		CALL control_modelos()
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
		IF vm_row_current = vm_num_rows THEN
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

CLEAR FORM
INITIALIZE rm_item.* TO NULL
LET int_flag = 0
IF num_args() = 3 THEN
    	CONSTRUCT BY NAME expr_sql ON r10_codigo, r10_nombre,r10_linea,r10_tipo,
		r10_peso, r10_uni_med, r10_cantpaq, r10_cantveh, r10_modelo, 
		r10_partida, r10_rotacion, r10_fob,r10_monfob, r10_filtro,
		r10_precio_mb, 
		r10_precio_ma, r10_costo_mb, r10_costo_ma, r10_costult_mb,
		r10_costult_ma, r10_cantped, r10_cantback, r10_precio_ant,  
		r10_fec_camprec, r10_comentarios, r10_paga_impto, r10_feceli,
		r10_estado
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
		     	END IF
		END IF
		IF INFIELD(r10_partida) THEN
			CALL fl_ayuda_partidas()
				RETURNING rm_par.g16_partida
			IF rm_par.g16_partida IS NOT NULL THEN
				LET rm_item.r10_partida = rm_par.g16_partida
                    		CALL fl_lee_partida(rm_item.r10_partida)
                                	RETURNING rm_par.*
				DISPLAY BY NAME rm_item.r10_partida
				DISPLAY rm_par.g16_nombre TO nom_par
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
		AFTER FIELD r10_linea
			LET rm_item.r10_linea = get_fldbuf(r10_linea)
                	IF rm_item.r10_linea IS NOT NULL THEN
                    		CALL fl_lee_linea_rep(vg_codcia,
						      rm_item.r10_linea)
                                	RETURNING rm_lin.*
                        	IF rm_lin.r03_codigo IS NULL THEN
                                	CALL fgl_winmessage (vg_producto, 'La Línea de venta no existe en la compañía ','exclamation')
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
	LET expr_sql = "r10_codigo = '", arg_val(4) CLIPPED, "'"
END IF
LET query = 'SELECT *, ROWID FROM rept010 ',
		'WHERE r10_compania = ', vg_codcia, ' AND ', expr_sql CLIPPED
		--' ORDER BY 1, 2'
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
	IF num_args() = 4 THEN
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

CLEAR FORM
INITIALIZE rm_item.* TO NULL
INITIALIZE rm_lin.* TO NULL
INITIALIZE rm_uni.* TO NULL
INITIALIZE rm_titem.* TO NULL
INITIALIZE rm_par.* TO NULL
INITIALIZE rm_rot.* TO NULL
LET vm_flag_mant           = 'I'
LET rm_item.r10_compania   = vg_codcia
LET rm_item.r10_estado     = 'A'
LET rm_item.r10_usuario    = vg_usuario
LET rm_item.r10_fecing     = CURRENT
LET rm_item.r10_paga_impto = 'S'
LET rm_item.r10_cantped    = 0
LET rm_item.r10_cantback   = 0
LET rm_item.r10_costo_mb   = 0
LET rm_item.r10_costo_ma   = 0
LET rm_item.r10_costult_mb = 0
LET rm_item.r10_costult_ma = 0
LET rm_item.r10_precio_ma  = 0
DISPLAY BY NAME rm_item.r10_usuario, rm_item.r10_fecing, rm_item.r10_estado,
		rm_item.r10_costo_mb, rm_item.r10_costo_ma, 
		rm_item.r10_cantped, rm_item.r10_cantback, 
		rm_item.r10_costult_mb, rm_item.r10_costult_ma, 
		rm_item.r10_paga_impto, rm_item.r10_precio_ma
DISPLAY 'ACTIVO' TO tit_estado
CALL lee_datos()
IF NOT int_flag THEN
	BEGIN WORK
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
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR 
	SELECT * FROM rept010 
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_item.*
IF status < 0 THEN
	COMMIT WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
LET rm_item2.r10_precio_mb = rm_item.r10_precio_mb
CALL lee_datos()
IF NOT int_flag THEN
    	UPDATE rept010 SET * = rm_item.*
		WHERE CURRENT OF q_up
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
ELSE 
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION lee_datos()
DEFINE resp 	VARCHAR(6)

LET int_flag = 0
INPUT BY NAME rm_item.r10_codigo,  rm_item.r10_nombre,   rm_item.r10_linea,
	      rm_item.r10_tipo,    rm_item.r10_peso,     rm_item.r10_uni_med,
	      rm_item.r10_cantpaq, rm_item.r10_cantveh,  rm_item.r10_modelo, 
	      rm_item.r10_partida, rm_item.r10_rotacion, rm_item.r10_fob,
	      rm_item.r10_monfob,  rm_item.r10_filtro,   rm_item.r10_precio_mb,
	      rm_item.r10_precio_ma,
	      rm_item.r10_costo_mb,rm_item.r10_costo_ma, rm_item.r10_costult_mb,
	      rm_item.r10_costult_ma, rm_item.r10_precio_ant,
	      rm_item.r10_fec_camprec,rm_item.r10_comentarios,
	      rm_item.r10_comentarios,rm_item.r10_paga_impto, rm_item.r10_feceli
              WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
        	IF field_touched(rm_item.r10_codigo, rm_item.r10_nombre,
		rm_item.r10_tipo, rm_item.r10_peso, rm_item.r10_uni_med,
		rm_item.r10_cantpaq, rm_item.r10_cantveh, rm_item.r10_modelo,
		rm_item.r10_partida, rm_item.r10_linea, rm_item.r10_rotacion,
		rm_item.r10_fob, rm_item.r10_monfob, rm_item.r10_precio_mb,
		rm_item.r10_costo_mb,rm_item.r10_costult_mb,
		rm_item.r10_comentarios, rm_item.r10_filtro)
                THEN
                        LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
                        	RETURNING resp
                        IF resp = 'Yes' THEN
                            LET int_flag = 1
			    IF vm_flag_mant = 'I' THEN
                                	CLEAR FORM
			    END IF
                            RETURN
                        END IF
                ELSE
			IF vm_flag_mant = 'I' THEN
                	        CLEAR FORM
			END IF
                        RETURN
                END IF       	
	ON KEY(F2)
		IF INFIELD(r10_partida) THEN
			CALL fl_ayuda_partidas()
			RETURNING rm_par.g16_partida
			IF rm_par.g16_partida IS NOT NULL THEN
				LET rm_item.r10_partida = rm_par.g16_partida
                    		CALL fl_lee_partida(rm_item.r10_partida)
                                	RETURNING rm_par.*
				DISPLAY BY NAME rm_item.r10_partida
				DISPLAY rm_par.g16_nombre TO nom_par
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
	AFTER FIELD r10_codigo
		IF rm_item.r10_codigo IS NOT NULL THEN
			CALL fl_lee_item(vg_codcia, rm_item.r10_codigo)
				RETURNING rm_item2.*
			IF rm_item2.r10_codigo IS NOT NULL THEN
				CALL fgl_winmessage(vg_producto,'Ya existe el Item en la Compañía ','exclamation')
				NEXT FIELD r10_codigo
			END IF
		END IF
	AFTER FIELD r10_tipo
                IF rm_item.r10_tipo IS NOT NULL THEN
                    CALL fl_lee_tipo_item(rm_item.r10_tipo)
                                RETURNING rm_titem.*
                        IF rm_titem.r06_codigo IS NULL THEN
                                CALL fgl_winmessage (vg_producto, 'El Tipo de Item no existe en la compañía ','exclamation')
                                NEXT FIELD r10_tipo
                        END IF
			DISPLAY rm_titem.r06_nombre TO nom_tipo
		ELSE
			CLEAR nom_tipo
                END IF
	AFTER FIELD r10_uni_med
                IF rm_item.r10_uni_med IS NOT NULL THEN
                    CALL fl_lee_unidad_medida(rm_item.r10_uni_med)
                                RETURNING rm_uni.*
                        IF rm_uni.r05_codigo IS NULL THEN
                                CALL fgl_winmessage (vg_producto, 'La Unidad de Medida no existe en la compañía ','exclamation')
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
                                CALL fgl_winmessage (vg_producto, 'La Partida Arancelaria no existe en la compañía ','exclamation')
                                NEXT FIELD r10_partida
                        END IF
			DISPLAY rm_par.g16_nombre TO nom_par
		ELSE
			CLEAR nom_par
                END IF
	AFTER FIELD r10_linea
                IF rm_item.r10_linea IS NOT NULL THEN
                    CALL fl_lee_linea_rep(vg_codcia, rm_item.r10_linea)
                                RETURNING rm_lin.*
                        IF rm_lin.r03_codigo IS NULL THEN
                                CALL fgl_winmessage (vg_producto, 'La Línea de venta no existe en la compañía ','exclamation')
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
	AFTER FIELD r10_rotacion
                IF rm_item.r10_rotacion IS NOT NULL THEN
                    CALL fl_lee_indice_rotacion(vg_codcia, rm_item.r10_rotacion)
                                RETURNING rm_rot.*
                        IF rm_rot.r04_rotacion IS NULL THEN
                                CALL fgl_winmessage (vg_producto, 'El Indice de Rotación no existe en la compañía ','exclamation')
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
                                CALL fgl_winmessage (vg_producto, 'La Moneda no existe en la compañía ','exclamation')
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
			     LET rm_item.r10_precio_ant = rm_item2.r10_precio_mb
			     LET rm_item.r10_fec_camprec = CURRENT
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
			IF rm_item.r10_precio_ma IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Precio digitado es demasiado grande', 'exclamatoin')
				NEXT FIELD r10_precio_mb
			END IF
			DISPLAY BY NAME rm_item.r10_precio_ma
		END IF
	AFTER INPUT 
		CALL fl_lee_compania_repuestos(vg_codcia)
                	RETURNING rm_r00.*
                IF rm_r00.r00_compania IS NULL THEN
                	CALL fgl_winmessage(vg_producto, 'No existe configuración de repuestos para la compañía ','exclamation')
                        NEXT FIELD r10_codigo
                END IF
END INPUT

END FUNCTION




FUNCTION control_bloqueo_activacion()
DEFINE resp    	CHAR(6)
DEFINE i	SMALLINT
DEFINE mensaje	VARCHAR(20)
DEFINE estado	LIKE rept010.r10_estado

LET int_flag = 0
IF rm_item.r10_codigo IS NULL OR vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
IF rm_item.r10_estado = 'S' THEN
	CALL fgl_winmessage(vg_producto,'El registro se encuentra sustituido ',
			    'exclamation')
	RETURN
END IF 
CALL fl_mensaje_seguro_ejecutar_proceso()
	RETURNING resp
IF resp = 'Yes' THEN
WHENEVER ERROR CONTINUE
	BEGIN WORK
	DECLARE q_del CURSOR FOR SELECT * FROM rept010 
		WHERE ROWID = vm_r_rows[vm_row_current]
		FOR UPDATE
	OPEN q_del
	FETCH q_del INTO rm_item.*
	IF status < 0 THEN
		COMMIT WORK
		CALL fl_mensaje_bloqueo_otro_usuario()
		WHENEVER ERROR STOP
		RETURN
	END IF
	LET estado = 'B'
	IF rm_item.r10_estado <> 'A' THEN
		LET estado = 'A'
	END IF
	CASE estado 
		WHEN 'B'
			UPDATE rept010 SET r10_estado = estado,
					   r10_feceli = CURRENT
			WHERE CURRENT OF q_del
		WHEN 'A'
			UPDATE rept010 SET r10_estado = estado,
					   r10_feceli = ''
			WHERE CURRENT OF q_del
	END CASE
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

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_item.* FROM rept010 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
DISPLAY BY NAME rm_item.r10_codigo,  rm_item.r10_nombre,    rm_item.r10_tipo,
	      	rm_item.r10_peso,    rm_item.r10_uni_med,   rm_item.r10_cantpaq,
	      	rm_item.r10_cantveh, rm_item.r10_modelo,    rm_item.r10_partida,
	     	rm_item.r10_linea,   rm_item.r10_rotacion,  rm_item.r10_fob,
	      	rm_item.r10_monfob,  rm_item.r10_precio_mb, 
		rm_item.r10_costo_mb,    rm_item.r10_costult_mb, 
		rm_item.r10_cantped,     rm_item.r10_cantback, 
		rm_item.r10_comentarios, rm_item.r10_usuario,
	      	rm_item.r10_fecing,      rm_item.r10_precio_ma, 
		rm_item.r10_costo_ma,    rm_item.r10_costult_ma,
		rm_item.r10_feceli,      rm_item.r10_fec_camprec,
		rm_item.r10_paga_impto,  rm_item.r10_estado,
		rm_item.r10_precio_ant,  rm_item.r10_filtro
CALL fl_lee_unidad_medida(rm_item.r10_uni_med)
        RETURNING rm_uni.*
	DISPLAY rm_uni.r05_siglas TO nom_uni
CALL fl_lee_partida(rm_item.r10_partida)
        RETURNING rm_par.*
	DISPLAY rm_par.g16_nombre TO nom_par
CALL fl_lee_indice_rotacion(vg_codcia, rm_item.r10_rotacion)
        RETURNING rm_rot.*
	DISPLAY rm_rot.r04_nombre TO nom_rot
CALL fl_lee_moneda(rm_item.r10_monfob)
        RETURNING rm_mon.*
	DISPLAY rm_mon.g13_nombre TO nom_mon
CALL fl_lee_linea_rep(vg_codcia, rm_item.r10_linea)
        RETURNING rm_lin.*
	DISPLAY rm_lin.r03_nombre TO nom_lin
CALL fl_lee_tipo_item(rm_item.r10_tipo)
	RETURNING rm_titem.*
	DISPLAY rm_titem.r06_nombre TO nom_tipo
CASE rm_item.r10_estado
	WHEN 'A' 
        	DISPLAY 'ACTIVO' TO tit_estado
	WHEN 'B'
		DISPLAY 'BLOQUEADO' TO tit_estado
	WHEN 'S'
		DISPLAY 'SUSTITUIDO' TO tit_estado
END CASE

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

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current              SMALLINT
DEFINE num_rows                 SMALLINT
                                                                                
DISPLAY row_current, num_rows TO vm_row_current2, vm_num_rows2
DISPLAY row_current, num_rows TO vm_row_current1, vm_num_rows1
                                                                                
END FUNCTION



FUNCTION control_existencias()
DEFINE i		SMALLINT
DEFINE rb		RECORD LIKE rept002.*
DEFINE r_exist ARRAY[100] OF RECORD
	bodega		LIKE rept011.r11_bodega, 
	n_bodega	LIKE rept002.r02_nombre, 
	stock		LIKE rept011.r11_stock_act,
	ubic		LIKE rept011.r11_ubicacion
END RECORD

OPEN WINDOW w_108_2 AT 8,31 WITH 13 ROWS, 48 COLUMNS
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
		  AND r11_item     = rm_item.r10_codigo
                  AND r11_bodega   = r02_codigo
                ORDER BY 3 DESC, 1
LET i = 1
FOREACH q_exist INTO r_exist[i].*
	IF r_exist[i].stock IS NULL THEN
		LET r_exist[i].stock = 0
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
	INITIALIZE r_exist[1].* TO NULL
	LET r_exist[1].bodega   = rm_r00.r00_bodega_fact
	LET r_exist[1].n_bodega	= rb.r02_nombre
	LET r_exist[1].stock    = 0
END IF
LET i = i - 1
IF i = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
--	CLOSE WINDOW w_108_2
        RETURN
END IF

LET int_flag = 0
CALL set_count(i)
DISPLAY ARRAY r_exist TO ra_exist.*
	ON KEY(INTERRUPT)
		EXIT DISPLAY
	BEFORE DISPLAY
		CALL dialog.keysetlabel('ACCEPT', '')
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
--IF i = 0 THEN
--	CALL fl_mensaje_consulta_sin_registros()
--	CLOSE WINDOW w_108_6
--      RETURN
--END IF

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



FUNCTION control_modelos()

DEFINE i		SMALLINT		-- Fila actual en el arreglo del programa
DEFINE j		SMALLINT		-- Fila actual en el arreglo de la pantalla
DEFINE num_elm	SMALLINT
DEFINE r_r115	RECORD LIKE rept115.*
DEFINE r_modelo	ARRAY[100] OF RECORD
	modelo		LIKE talt004.t04_modelo,
	linea		LIKE talt004.t04_linea 
END RECORD

OPTIONS INPUT WRAP, ACCEPT KEY F12

OPEN WINDOW w_108_7 AT 8,25 WITH 13 ROWS, 45 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER) 
OPEN FORM f_108_7 FROM '../forms/repf108_7'
DISPLAY FORM f_108_7

DISPLAY 'Modelo' 	TO bt_modelo
DISPLAY 'Línea' 	TO bt_linea

DISPLAY rm_item.r10_codigo TO item
DISPLAY rm_item.r10_nombre TO n_item

DECLARE q_modelo CURSOR FOR
	SELECT r115_modelo, t04_linea 
	  FROM rept115, talt004 
	 WHERE r115_compania = vg_codcia
       AND r115_item     = rm_item.r10_codigo
	   AND t04_compania  = r115_compania
	   AND t04_modelo    = r115_modelo
	 ORDER BY t04_linea, r115_modelo
LET i = 1
FOREACH q_modelo INTO r_modelo[i].*
	LET i = i + 1
	IF i > 100 THEN
		EXIT FOREACH
	END IF
END FOREACH
LET i = i - 1
{
IF i = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	CLOSE WINDOW w_108_7
	RETURN
END IF
}
LET int_flag = 0
CALL set_count(i)
INPUT ARRAY r_modelo WITHOUT DEFAULTS FROM  ra_modelo.*
	ON KEY(INTERRUPT)
		EXIT INPUT
	ON KEY (F2)
		IF INFIELD(modelo) THEN
			CALL fl_ayuda_tipos_vehiculos(vg_codcia)
				RETURNING r_modelo[i].modelo, r_modelo[i].linea
			DISPLAY r_modelo[i].* TO ra_modelo[j].*
		END IF
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
	AFTER INPUT
		LET num_elm = arr_count()
{
		IF num_elm = 0 THEN
			CALL fgl_winmessage(vg_producto, 'Debe ingresar al menos un modelo.',
							   'exclamation')
			CONTINUE INPUT
		END IF
}
		DELETE FROM rept115 WHERE r115_compania = vg_codcia
							  AND r115_item     = rm_item.r10_codigo
		IF num_elm > 0 THEN
			FOR i = 1 TO num_elm
				IF r_modelo[i].modelo IS NULL THEN
					CONTINUE FOR
				END IF
				INITIALIZE r_r115.* TO NULL
				LET r_r115.r115_compania = vg_codcia
				LET r_r115.r115_item     = rm_item.r10_codigo
				LET r_r115.r115_modelo   = r_modelo[i].modelo
				LET r_r115.r115_usuario  = vg_usuario
				LET r_r115.r115_fecing   = CURRENT
				INSERT INTO rept115 VALUES (r_r115.*)
			END FOR 
		END IF
END INPUT
 
CLOSE WINDOW w_108_7

END FUNCTION



FUNCTION control_pedidos()

DEFINE i		SMALLINT

DEFINE r_pedido ARRAY[100] OF RECORD
	pedido		LIKE rept016.r16_pedido, 
	proveedor	LIKE rept016.r16_proveedor, 
	fecha_lleg	LIKE rept016.r16_fec_llegada, 
	cantidad	LIKE rept017.r17_cantped
END RECORD

OPEN WINDOW w_108_3 AT 8,34 WITH 13 ROWS, 45 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER) 
OPEN FORM f_108_3 FROM '../forms/repf108_3'
DISPLAY FORM f_108_3

DISPLAY 'Pedido' TO bt_pedido
DISPLAY 'Proveedor' TO bt_proveedor
DISPLAY 'Fec. Lleg.' TO bt_fecha
DISPLAY 'Cant.' TO bt_cantidad

DISPLAY rm_item.r10_codigo TO item
DISPLAY rm_item.r10_nombre TO n_item

DECLARE q_pedido CURSOR FOR
	SELECT r17_pedido, r16_proveedor, r16_fec_llegada, r17_cantped
		FROM rept016, rept017
		WHERE r17_compania  = vg_codcia
	          AND r17_item      = rm_item.r10_codigo
		  --AND r17_cantped   > r17_cantrec 
		  AND r17_estado    NOT IN ('A', 'P')
		  AND r16_compania  = r17_compania
                  AND r16_localidad = r17_localidad
                  AND r16_pedido    = r17_pedido
{ XXX no creo que esto haya estado bien
	UNION ALL
	SELECT r17_pedido, r16_proveedor, r16_fec_llegada, 
	       (r17_cantped - r17_cantrec)
		FROM rept016, rept017
		WHERE r17_compania  = vg_codcia
	          AND r17_item      = rm_item.r10_codigo
		  AND r17_cantped   > r17_cantrec 
		  AND r17_estado    = 'P'
		  AND r16_compania  = r17_compania
                  AND r16_localidad = r17_localidad
                  AND r16_pedido    = r17_pedido
}                  
LET i = 1
FOREACH q_pedido INTO r_pedido[i].*
	LET i = i + 1
	IF i > 100 THEN
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
	BEFORE DISPLAY
		CALL dialog.keysetlabel('ACCEPT', '')
	AFTER DISPLAY
		CONTINUE DISPLAY
END DISPLAY

CLOSE WINDOW w_108_3

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

DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_r00		RECORD LIKE rept000.*
DEFINE r_r02		RECORD LIKE rept002.*

DEFINE r_par RECORD
	r12_moneda	LIKE rept012.r12_moneda,
	n_moneda	LIKE gent013.g13_nombre,
	anho		SMALLINT,
	bodega		LIKE rept002.r02_codigo,
	n_bodega	LIKE rept002.r02_nombre
END RECORD

INITIALIZE r_par.* TO NULL
CALL fl_lee_compania_repuestos(vg_codcia)                RETURNING r_r00.*
CALL fl_lee_moneda(rg_gen.g00_moneda_base)               RETURNING r_g13.*
CALL fl_lee_bodega_rep(vg_codcia, r_r00.r00_bodega_fact) RETURNING r_r02.*
LET r_par.r12_moneda = rg_gen.g00_moneda_base
LET r_par.n_moneda   = r_g13.g13_nombre 
LET r_par.bodega     = r_r00.r00_bodega_fact
LET r_par.n_bodega   = r_r02.r02_nombre
LET r_par.anho       = YEAR(TODAY)

OPEN WINDOW w_108_5 AT 5,13 WITH 20 ROWS, 57 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER) 
OPEN FORM f_108_5 FROM '../forms/repf108_5'
DISPLAY FORM f_108_5

DISPLAY 'Mes' 		TO bt_mes
DISPLAY 'Ventas '	TO bt_vend
DISPLAY 'Demanda'	TO bt_dema
DISPLAY 'Pérdida'	TO bt_perd
DISPLAY 'Total'		TO bt_total

LET int_flag = 0
INPUT BY NAME r_par.* WITHOUT DEFAULTS
	ON KEY(F2)
		IF infield(r12_moneda) THEN
			CALL fl_ayuda_monedas() RETURNING r_g13.g13_moneda,
							  r_g13.g13_nombre,
							  r_g13.g13_decimales
			IF r_g13.g13_moneda IS NOT NULL THEN
				LET r_par.r12_moneda = r_g13.g13_moneda
				LET r_par.n_moneda   = r_g13.g13_nombre
				DISPLAY BY NAME r_par.*
			END IF
		END IF
		IF infield(bodega) THEN
			CALL fl_ayuda_bodegas_rep(vg_codcia, NULL, 'T') 
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
			CALL fl_lee_moneda(r_par.r12_moneda) RETURNING r_g13.*
			IF r_g13.g13_moneda IS NULL THEN
				CALL fgl_winmessage(vg_producto, 
					'Moneda no existe', 
					'exclamation')
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
				CALL fgl_winmessage(vg_producto, 
					'Bodega no existe', 
					'exclamation')
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
				CALL fgl_winmessage(vg_producto,
					'El año debe ser mayor a 1900.',
					'exclamation')
				NEXT FIELD anho
			END IF
END INPUT
IF int_flag THEN
	CLOSE WINDOW w_108_5
	RETURN
END IF

CALL consulta_estadisticas(r_par.*)

CLOSE WINDOW w_108_5

END FUNCTION



FUNCTION consulta_estadisticas(r_par)
DEFINE i		SMALLINT
DEFINE query		VARCHAR(700)
DEFINE mes		SMALLINT
DEFINE expr_sql		VARCHAR(200)
DEFINE expr_bod		VARCHAR(100)
DEFINE expr_anho 	VARCHAR(50)

DEFINE num_rows		SMALLINT

DEFINE unid_vend	LIKE rept012.r12_uni_venta
DEFINE unid_dema	LIKE rept012.r12_uni_deman
DEFINE unid_perd	LIKE rept012.r12_uni_perdi

DEFINE tot_vend		LIKE rept012.r12_uni_venta
DEFINE tot_dema		LIKE rept012.r12_uni_deman
DEFINE tot_perd		LIKE rept012.r12_uni_perdi
DEFINE total		SMALLINT
DEFINE fec_ini, fec_fin DATE
DEFINE r_par RECORD
	r12_moneda	LIKE rept012.r12_moneda,
	n_moneda	LIKE gent013.g13_nombre,
	anho		SMALLINT,
	bodega		LIKE rept002.r02_codigo,
	n_bodega	LIKE rept002.r02_nombre
END RECORD

DEFINE r_estat ARRAY[12] OF RECORD
	mes		CHAR(10), 
	unid_vend	LIKE rept012.r12_uni_venta, 
	unid_dema	LIKE rept012.r12_uni_deman, 
	unid_perd	LIKE rept012.r12_uni_perdi, 
	subtotal	SMALLINT        
END RECORD

LET num_rows = 12
LET i = 1
INITIALIZE mes, r_estat[i].* TO NULL
LET tot_vend = 0 
LET tot_perd = 0
LET tot_dema = 0 

FOR i = 1 TO num_rows
	LET r_estat[i].mes 	 = 
		fl_justifica_titulo('I', fl_retorna_nombre_mes(i), 10)
	LET r_estat[i].unid_vend = 0
	LET r_estat[i].unid_dema = 0
	LET r_estat[i].unid_perd = 0
	LET r_estat[i].subtotal  = 0
END FOR

ERROR 'Generando consulta . . . espere por favor' ATTRIBUTE(NORMAL)
LET expr_bod = ' 1 = 1 '
IF r_par.bodega IS NOT NULL THEN
	LET expr_bod = "r19_bodega_ori = '", r_par.bodega CLIPPED, "'"
END IF

LET query = 'SELECT MONTH(r19_fecing), SUM(r20_cant_ven - r20_cant_dev), ',
	    '	    COUNT(r20_cant_ped), SUM(r20_cant_ped - r20_cant_ven) ',
	    '	FROM rept019, rept020 ',
	    '	WHERE r19_compania     = ',  vg_codcia CLIPPED, 
		'     AND r19_cod_tran     = "FA" ',
	    '	  AND r19_moneda       = "', r_par.r12_moneda, '"',
	    '  	  AND YEAR(r19_fecing) = ',  r_par.anho CLIPPED,
	    '	  AND ', expr_bod CLIPPED, 
		'     AND r20_compania     = r19_compania ',
		'     AND r20_localidad    = r19_localidad ',
		'     AND r20_cod_tran     = r19_cod_tran ',
		'     AND r20_num_tran     = r19_num_tran ',
	    '	  AND r20_item = "', rm_item.r10_codigo, '"',
	    ' 	GROUP BY 1 ',
	    '	ORDER BY 1 '
	    
PREPARE cit FROM query
DECLARE q_cit CURSOR FOR cit

FOREACH	q_cit INTO mes, unid_vend, unid_dema, unid_perd
	LET r_estat[mes].unid_vend = unid_vend
	LET r_estat[mes].unid_dema = unid_dema
	LET r_estat[mes].unid_perd = unid_perd
	LET r_estat[mes].subtotal  = unid_vend + unid_dema + unid_perd
	LET tot_vend = tot_vend + unid_vend
	LET tot_dema = tot_dema + unid_dema
	LET tot_perd = tot_perd + unid_perd
END FOREACH

ERROR ' ' ATTRIBUTE(NORMAL)

LET int_flag = 0
CALL set_count(num_rows)
DISPLAY ARRAY r_estat TO r_estat.*
	BEFORE ROW
		LET i = arr_curr()
	BEFORE DISPLAY
		CALL dialog.keysetlabel('F8', 'Movimientos')
		CALL dialog.keysetlabel("ACCEPT","")
		LET total = tot_vend + tot_dema + tot_perd
		DISPLAY BY NAME tot_vend, tot_dema, tot_perd, total
	AFTER DISPLAY
		CONTINUE DISPLAY
	ON KEY(INTERRUPT)
		EXIT DISPLAY
	ON KEY(F8)
	LET fec_ini = MDY(i, 01, r_par.anho)
        LET fec_fin = MDY(i, 01, r_par.anho) + 1 UNITS MONTH - 1 UNITS DAY
		CALL muestra_movimientos_item(	rm_item.r10_codigo, 
						r_par.bodega,
						r_par.r12_moneda,
						fec_ini, fec_fin)

		CONTINUE DISPLAY
END DISPLAY

END FUNCTION


FUNCTION muestra_movimientos_item(item, bodega, moneda, fec_ini, fec_fin)
DEFINE item		LIKE rept010.r10_codigo
DEFINE bodega		LIKE rept002.r02_codigo
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE fec_ini, fec_fin	DATE
DEFINE r_item		RECORD LIKE rept010.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_bod		RECORD LIKE rept002.*
DEFINE r_trn		RECORD LIKE rept019.*
DEFINE num_rows, i	SMALLINT
DEFINE max_rows		SMALLINT
DEFINE tot_uni		INTEGER
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
	unidades	INTEGER,
	valor		DECIMAL(14,2)
	END RECORD

CREATE TEMP TABLE temp_mov
	(te_fecha	DATETIME YEAR TO SECOND,
	 te_tipo	CHAR(2),
	 te_numero	INTEGER,
	 te_cliente	VARCHAR(30),
	 te_unidades	INTEGER,
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
DECLARE q_det CURSOR FOR SELECT r20_fecing, r20_cod_tran, r20_num_tran,
	'', r20_cant_ven, (r20_precio * r20_cant_ven) - r20_val_descto
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
	FETCH q_det INTO r_mov[num_rows].*
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
	IF r_trn.r19_bodega_ori <> bodega THEN
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
			CALL dialog.keysetlabel("ACCEPT","")
		AFTER DISPLAY 
			CONTINUE DISPLAY
		BEFORE ROW
			LET i = arr_curr()
			MESSAGE i, ' de ', num_rows
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F5)
			LET i = arr_curr()
			LET comando = 'fglrun repp308 ' || vg_base || ' RE ' || 
			       	vg_codcia || ' ' ||
			       	vg_codloc || ' ' || r_mov[i].tipo || ' ' ||
			       	r_mov[i].numero
			RUN comando
		ON KEY(F6)
			LET comando = 'fglrun repp108 ', vg_base, ' RE ', 
			               vg_codcia, ' "',
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



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 
                            'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 
                            'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || 
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
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| 
                            vg_codloc, 'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_compania <> vg_codcia THEN
	CALL fgl_winmessage(vg_producto, 'Combinación compañía/localidad no ' ||
                            'existe ', 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
