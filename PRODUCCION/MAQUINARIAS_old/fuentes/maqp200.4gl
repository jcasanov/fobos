------------------------------------------------------------------------------
-- Titulo           : maqp200.4gl - Mantenimiento de Maquinaria Por Clientes    
-- Elaboracion      : 18-nov-2004
-- Autor            : JCM
-- Formato Ejecucion: fglrun maqp200 base modulo compania 
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA r_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS

DEFINE vm_max_rows	SMALLINT
--
-- DEFINE RECORD(S) HERE
--
DEFINE rm_m00			RECORD LIKE maqt000.*  --Parametros
DEFINE rm_m11			RECORD LIKE maqt011.*
DEFINE rm_m12			RECORD LIKE maqt012.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/maqp200.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN	-- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'maqp200'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea

CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_rows = 1000
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_m11 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_m11 FROM '../forms/maqf200_1'
DISPLAY FORM f_m11

DISPLAY '' TO n_estado

LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_m11.* TO NULL
INITIALIZE rm_m12.* TO NULL
--CALL muestra_contadores()
--CALL muestra_etiquetas()

CALL fl_lee_parametros_maq(vg_codcia) RETURNING rm_m00.*

LET vm_max_rows = 1000

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
--		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
	COMMAND KEY('M') 'Modificar' 		'Modificar registro corriente.'
--		CALL control_modificacion()
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro.'
--		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Modificar'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
--		CALL siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
--		CALL anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()
DEFINE rowid		INTEGER

CLEAR FORM
INITIALIZE rm_m11.* TO NULL
INITIALIZE rm_m12.* TO NULL

-- INITIALIZING NOT NULL FIELDS. IF IN AN INPUT I CAN'T PUT ANYTHING IN THEM -- 

-- Campos de la tabla maqt011
LET rm_m11.m11_compania       = vg_codcia
LET rm_m11.m11_estado         = 'A'
LET rm_m11.m11_nuevo          = 'S'
LET rm_m11.m11_fecha_ent      = CURRENT
LET rm_m11.m11_fecha_sgte_rev = CURRENT + rm_m00.m00_dias_revi_ini

DISPLAY 'ACTIVO' TO n_estado

-- Campos de la tabla maqt011
LET rm_m12.m12_compania    = vg_codcia
LET rm_m12.m12_fecha       = CURRENT
LET rm_m12.m12_horometro   = 0

------------------------------------------------------------------------------- 

CALL lee_datos('I')
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

SELECT MAX(m11_secuencia) INTO rm_m11.m11_secuencia
	FROM maqt011 
	WHERE m11_compania  = vg_codcia
	  AND m11_modelo    = rm_m11.m11_modelo
IF rm_m11.m11_secuencia IS NULL THEN
	LET rm_m11.m11_secuencia = 1
ELSE
	LET rm_m11.m11_secuencia = rm_m11.m11_secuencia + 1
END IF
INSERT INTO maqt011 VALUES (rm_m11.*)
LET rowid = SQLCA.SQLERRD[6] 	-- Rowid de la ultima fila procesada 

LET rm_m12.m12_compania  = rm_m11.m11_compania
LET rm_m12.m12_modelo    = rm_m11.m11_modelo
LET rm_m12.m12_secuencia = rm_m11.m11_secuencia
WHENEVER ERROR CONTINUE
INSERT INTO maqt012 VALUES (rm_m12.*)
WHENEVER ERROR STOP

IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF
LET vm_row_current = vm_num_rows
LET vm_rows[vm_num_rows] = rowid            	-- Rowid de la ultima fila 
                                             	-- procesada
CALL muestra_contadores()
CALL muestra_etiquetas()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_modificacion()

IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

IF rm_m11.m11_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF

CALL lee_muestra_registro(vm_rows[vm_row_current])

BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_upd CURSOR FOR 
	SELECT * FROM maqt011 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_upd
FETCH q_upd INTO rm_m11.*
WHENEVER ERROR STOP
IF SQLCA.SQLCODE < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	RETURN
END IF  
IF SQLCA.SQLCODE = NOTFOUND THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto, 'No existe rowid en la tabla.', 'stop')
	RETURN
END IF  

CALL lee_datos('M')

IF INT_FLAG THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	RETURN
END IF 

UPDATE maqt011 SET * = rm_m11.* WHERE CURRENT OF q_upd

LET rm_m12.m12_compania  = rm_m11.m11_compania
LET rm_m12.m12_modelo    = rm_m11.m11_modelo
LET rm_m12.m12_secuencia = rm_m11.m11_secuencia
WHENEVER ERROR CONTINUE
INSERT INTO maqt012 VALUES (rm_m12.*)
WHENEVER ERROR STOP

COMMIT WORK
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION lee_datos(flag)

DEFINE flag 		CHAR(1)
DEFINE resp 		CHAR(6)

DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_m01		RECORD LIKE maqt001.*
DEFINE r_m02		RECORD LIKE maqt002.*
DEFINE r_m05		RECORD LIKE maqt005.*
DEFINE r_m10		RECORD LIKE maqt010.*

DEFINE m12_fecha_ori	LIKE maqt012.m12_fecha
DEFINE m12_horom_ori	LIKE maqt012.m12_horometro

INITIALIZE m12_fecha_ori, m12_horom_ori TO NULL
IF flag = 'M' THEN
	LET m12_fecha_ori = rm_m12.m12_fecha
	LET m12_horom_ori = rm_m12.m12_horometro
END IF

LET INT_FLAG = 0
INPUT BY NAME rm_m11.m11_estado,    rm_m11.m11_codcli, 
              rm_m11.m11_modelo,    rm_m11.m11_serie,  rm_m11.m11_comentarios, 
              rm_m11.m11_ano,       rm_m11.m11_motor,  rm_m11.m11_fecha_ent, 
              rm_m12.m12_fecha,     rm_m11.m11_fecha_sgte_rev,
              rm_m12.m12_horometro, rm_m11.m11_garantia_meses, 
              rm_m11.m11_garantia_horas, rm_m11.m11_provincia, 
              rm_m11.m11_canton,    rm_m11.m11_ubicacion WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_m11.m11_estado, rm_m11.m11_codcli, rm_m11.m11_linea,  rm_m11.m11_modelo, rm_m11.m11_serie, rm_m11.m11_comentarios, rm_m11.m11_ano, rm_m11.m11_motor, rm_m11.m11_fecha_ent, rm_m12.m12_fecha, rm_m11.m11_fecha_sgte_rev, rm_m12.m12_horometro, rm_m11.m11_garantia_meses, rm_m11.m11_garantia_horas, rm_m11.m11_provincia, rm_m11.m11_canton, rm_m11.m11_ubicacion) 
		THEN
			RETURN
		END IF

		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
                	RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN
		END IF
	ON KEY(F2)
		IF INFIELD(m11_codcli) THEN
			CALL fl_ayuda_cliente_localidad(vg_codcia, vg_codloc)
				RETURNING rm_z01.z01_codcli, rm_z01.z01_nomcli
			IF rm_z01.z01_codcli IS NOT NULL THEN
				LET rm_m11.m11_codcli = rm_z01.z01_codcli
				DISPLAY BY NAME rm_m11.m11_codcli
				DISPLAY rm_z01.z01_nomcli TO n_cliente
			END IF 
		END IF
		IF INFIELD(m11_modelo) THEN
			CALL fl_ayuda_modelos_lineas_maq(vg_codcia)
				RETURNING r_m10.m10_linea,  r_m05.m05_nombre, 
                                          r_m10.m10_modelo, 
                                          r_m10.m10_descripcion
			IF r_m10.m10_modelo IS NOT NULL THEN
				LET rm_m11.m11_linea  = r_m10.m10_linea
				LET rm_m11.m11_modelo = r_m10.m10_modelo
				DISPLAY BY NAME rm_m11.m11_linea,
                                                rm_m11.m11_modelo
				DISPLAY r_m05.m05_nombre, r_m10.m10_descripcion
                                     TO n_linea, n_modelo
			END IF
		END IF
		IF INFIELD(m11_canton) THEN
			CALL fl_ayuda_cantones_provincias()
				RETURNING r_m01.m01_provincia,  
					  r_m01.m01_nombre, 
                                          r_m02.m02_canton, 
                                          r_m02.m02_nombre
			IF r_m01.m01_provincia IS NOT NULL THEN
				LET rm_m11.m11_provincia = r_m01.m01_provincia
				LET rm_m11.m11_canton    = r_m02.m02_canton
				DISPLAY BY NAME rm_m11.m11_provincia,
                                                rm_m11.m11_canton
				DISPLAY r_m01.m01_nombre, r_m02.m02_nombre
                                     TO n_provincia, n_canton
			END IF
		END IF
		LET INT_FLAG = 0
	AFTER FIELD m11_codcli
		IF rm_m11.m11_codcli IS NOT NULL THEN
			CALL fl_lee_cliente_general(rm_m11.m11_codcli)
				RETURNING r_z01.*
			IF r_z01.z01_codcli IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe el Cliente en la Compañía. ','exclamation') 
				CLEAR n_nomcli
				INITIALIZE rm_m11.m11_codcli TO NULL 
				NEXT FIELD m11_codcli
			END IF
			IF r_z01.z01_estado <> 'A' THEN
				CALL fgl_winmessage(vg_producto,
						    'Cliente está bloqueado',
						    'exclamation')
				NEXT FIELD m11_codcli
			END IF
		END IF
	AFTER  FIELD m11_modelo
		IF rm_m11.m11_modelo IS NULL THEN
			CLEAR n_modelo
		ELSE
			CALL fl_lee_modelo_veh(rm_m11.m11_compania, 
                                             rm_m11.m11_modelo)
							RETURNING r_v20.*
			IF r_v20.v20_modelo IS NULL THEN	
				CLEAR n_modelo
				CALL fgl_winmessage(vg_producto,
					            'Modelo no existe',
						    'exclamation')
				NEXT FIELD m11_modelo
			ELSE
				DISPLAY r_v20.v20_modelo_ext TO n_modelo
			END IF 
		END IF
	AFTER  FIELD m11_cod_color
		IF rm_m11.m11_cod_color IS NULL THEN
			CLEAR n_color
		ELSE
			CALL fl_lee_color_veh(rm_m11.m11_compania, 
                                              rm_m11.m11_cod_color)
							RETURNING r_v05.*
			IF r_v05.v05_cod_color IS NULL THEN	
				CLEAR n_color
				CALL fgl_winmessage(vg_producto,
					            'No existe color',
						    'exclamation')
				NEXT FIELD m11_cod_color
			ELSE
				DISPLAY r_v05.v05_descri_base TO n_color
			END IF 
		END IF
	AFTER  FIELD m11_bodega
		IF rm_m11.m11_bodega IS NULL THEN
			CLEAR n_bodega
		ELSE
			CALL fl_lee_bodega_veh(rm_m11.m11_compania, 
                                               rm_m11.m11_bodega)
							RETURNING r_v02.*
			IF r_v02.v02_bodega IS NULL THEN	
				CLEAR n_bodega
				CALL fgl_winmessage(vg_producto,
					            'Bodega no existe para' ||
                                                    ' esta compañía',
						    'exclamation')
				NEXT FIELD m11_bodega
			ELSE
				IF r_v02.v02_estado = 'B' THEN
					CLEAR n_bodega
					CALL fgl_winmessage(vg_producto,
						           'Bodega está' ||
                                                           ' bloqueada',
						    	   'exclamation')
					NEXT FIELD m11_bodega
				ELSE
					DISPLAY r_v02.v02_nombre TO n_bodega
				END IF
			END IF 
		END IF
	AFTER INPUT 
		IF
			CALL fgl_winmessage(vg_producto,
					    'Para vender este vehículo debe ' ||
                                            'realizar primero una compra local',
					    'info')
		END IF
END INPUT

END FUNCTION


{

FUNCTION control_consulta()

DEFINE expr_sql			VARCHAR(500)
DEFINE query			VARCHAR(600)

DEFINE bodega			LIKE veht002.v02_bodega,
       nom_bodega		LIKE veht002.v02_nombre

DEFINE modelo			LIKE veht020.v20_modelo,
       linea			LIKE veht020.v20_linea,     -- DUMMY VARIABLE
       modelo_ext       	LIKE veht020.v20_modelo_ext

DEFINE color			LIKE veht005.v05_cod_color,
       nom_color 		LIKE veht005.v05_descri_base

DEFINE g13_moneda		LIKE gent013.g13_moneda,
       nombre			LIKE gent013.g13_nombre,
       decimales 		LIKE gent013.g13_decimales

DEFINE tran 			LIKE gent021.g21_cod_tran,
       nom_tran			LIKE gent021.g21_nombre

DEFINE r_mon			RECORD LIKE gent013.*
DEFINE r_v20			RECORD LIKE veht020.*
DEFINE r_v05			RECORD LIKE veht005.*
DEFINE r_v02			RECORD LIKE veht002.*
DEFINE r_g21			RECORD LIKE gent021.*

DEFINE r_serveh RECORD
        codigo_veh	LIKE maqt011.m11_codigo_veh,
        chasis		LIKE maqt011.m11_chasis,
        modelo		LIKE maqt011.m11_modelo,
        cod_color	LIKE maqt011.m11_cod_color,
        bodega		LIKE maqt011.m11_bodega
END RECORD

CLEAR FORM

LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql 
	ON m11_chasis, m11_estado, m11_nuevo, m11_bodega, m11_modelo, 
           m11_codigo_veh, m11_comentarios, m11_motor, m11_ano,
           m11_cod_color, m11_dueno, m11_kilometraje, m11_placa, 
           m11_moneda_prec, m11_precio, m11_moneda_liq, m11_costo_liq, 
           m11_cargo_liq, 
           m11_numero_liq, m11_fec_ing_bod, m11_pedido, m11_moneda_ing,
           m11_costo_ing, m11_cargo_ing, m11_costo_adi, m11_cod_tran, 
           m11_num_tran, m11_usuario 
	ON KEY(F2)
		IF INFIELD(m11_chasis) THEN
			CALL fl_ayuda_serie_veh_todos(vg_codcia, vg_codloc, 
				'00') RETURNING r_serveh.*
			IF r_serveh.codigo_veh IS NOT NULL THEN
				LET rm_m11.m11_chasis     = r_serveh.chasis	
				LET rm_m11.m11_codigo_veh = r_serveh.codigo_veh
				LET rm_m11.m11_modelo     = r_serveh.modelo
				DISPLAY BY NAME rm_m11.m11_chasis,       
						rm_m11.m11_codigo_veh,
						rm_m11.m11_modelo
			END IF
		END IF
		IF INFIELD(m11_bodega) THEN
			CALL fl_ayuda_bodegas_veh(vg_codcia) 
				RETURNING bodega, nom_bodega 
			IF bodega IS NOT NULL THEN
				LET rm_m11.m11_bodega = bodega
				DISPLAY BY NAME rm_m11.m11_bodega
				DISPLAY nom_bodega TO n_bodega
			END IF
		END IF
		IF INFIELD(m11_modelo) THEN
			CALL fl_ayuda_modelos_veh(vg_codcia)
				RETURNING modelo, linea
			IF modelo IS NOT NULL THEN
				SELECT v20_modelo_ext INTO modelo_ext
					FROM veht020
					WHERE v20_compania = vg_codcia
					  AND v20_modelo   = modelo
				LET rm_m11.m11_modelo = modelo
				DISPLAY BY NAME rm_m11.m11_modelo
				DISPLAY modelo_ext TO n_modelo
			END IF
		END IF
		IF INFIELD(m11_cod_color) THEN
			CALL fl_ayuda_colores(vg_codcia) 
				RETURNING color, nom_color
			IF color IS NOT NULL THEN
				LET rm_m11.m11_cod_color = color
				DISPLAY BY NAME rm_m11.m11_cod_color
				DISPLAY nom_color TO n_color
			END IF
		END IF
		IF INFIELD(m11_moneda_liq) THEN
			CALL fl_ayuda_monedas() 
				RETURNING g13_moneda, nombre, decimales 
			IF g13_moneda IS NOT NULL THEN
				LET rm_m11.m11_moneda_liq = g13_moneda
				DISPLAY BY NAME rm_m11.m11_moneda_liq
				DISPLAY nombre TO n_moneda_liq
			END IF	
		END IF
		IF INFIELD(m11_moneda_ing) THEN
			CALL fl_ayuda_monedas() 
				RETURNING g13_moneda, nombre, decimales 
			IF g13_moneda IS NOT NULL THEN
				LET rm_m11.m11_moneda_ing = g13_moneda
				DISPLAY BY NAME rm_m11.m11_moneda_ing
				DISPLAY nombre TO n_moneda_ing
			END IF	
		END IF
		IF INFIELD(m11_moneda_prec) THEN
			CALL fl_ayuda_monedas() 
				RETURNING g13_moneda, nombre, decimales 
			IF g13_moneda IS NOT NULL THEN
				LET rm_m11.m11_moneda_prec = g13_moneda
				DISPLAY BY NAME rm_m11.m11_moneda_prec
				DISPLAY nombre TO n_moneda_prec
			END IF	
		END IF
		IF INFIELD(m11_cod_tran) THEN
			CALL fl_ayuda_tipo_tran('N') RETURNING tran, nom_tran
			IF tran IS NOT NULL THEN
				LET rm_m11.m11_cod_tran = tran
				DISPLAY BY NAME rm_m11.m11_cod_tran
				DISPLAY nom_tran TO n_transaccion
			END IF
		END IF 
		LET INT_FLAG = 0
	AFTER  FIELD m11_modelo
		LET rm_m11.m11_modelo = GET_FLDBUF(m11_modelo)
		IF rm_m11.m11_modelo IS NULL THEN
			CLEAR n_modelo
		ELSE
			CALL fl_lee_modelo_veh(rm_m11.m11_compania, 
                                               rm_m11.m11_modelo)
							RETURNING r_v20.*
			IF r_v20.v20_modelo IS NULL THEN	
				CLEAR n_modelo
			ELSE
				DISPLAY r_v20.v20_modelo_ext TO n_modelo
			END IF 
		END IF
	AFTER  FIELD m11_cod_color
		LET rm_m11.m11_cod_color = GET_FLDBUF(m11_cod_color)
		IF rm_m11.m11_cod_color IS NULL THEN
			CLEAR n_color
		ELSE
			CALL fl_lee_color_veh(rm_m11.m11_compania, 
                                              rm_m11.m11_cod_color)
							RETURNING r_v05.*
			IF r_v05.v05_cod_color IS NULL THEN	
				CLEAR n_bodega
			ELSE
				DISPLAY r_v05.v05_descri_base TO n_color
			END IF 
		END IF
	AFTER  FIELD m11_bodega
		LET rm_m11.m11_bodega = GET_FLDBUF(m11_bodega)
		IF rm_m11.m11_bodega IS NULL THEN
			CLEAR n_bodega
		ELSE
			CALL fl_lee_bodega_veh(vg_codcia, 
                                               rm_m11.m11_bodega)
							RETURNING r_v02.*
			IF r_v02.v02_bodega IS NULL THEN	
				CLEAR n_bodega
			ELSE
				IF r_v02.v02_estado = 'B' THEN
					CLEAR n_bodega
				ELSE
					DISPLAY r_v02.v02_nombre TO n_bodega
				END IF
			END IF 
		END IF
	AFTER  FIELD m11_cod_tran
		LET rm_m11.m11_cod_tran = GET_FLDBUF(m11_cod_tran)
		IF rm_m11.m11_cod_tran IS NULL THEN
			CLEAR n_transaccion
		ELSE
			CALL fl_lee_cod_transaccion(rm_m11.m11_cod_tran)
				RETURNING r_g21.*
			IF r_g21.g21_cod_tran IS NULL THEN	
				CLEAR n_transaccion
			ELSE
				IF r_g21.g21_estado = 'B' THEN
					CLEAR n_transaccion
				ELSE
					DISPLAY r_g21.g21_nombre TO n_transaccion
				END IF
			END IF 
		END IF
	AFTER FIELD m11_moneda_liq
		LET rm_m11.m11_moneda_liq = GET_FLDBUF(m11_moneda_liq)
		IF rm_m11.m11_moneda_liq IS NULL THEN
			CLEAR n_moneda_liq
		ELSE
			CALL fl_lee_moneda(rm_m11.m11_moneda_liq) 
				RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN	
				CLEAR n_moneda_liq
			ELSE
				IF r_mon.g13_estado = 'B' THEN
					CLEAR n_moneda_liq
				ELSE
					DISPLAY r_mon.g13_nombre TO n_moneda_liq
				END IF
			END IF 
		END IF
	AFTER FIELD m11_moneda_ing
		LET rm_m11.m11_moneda_ing = GET_FLDBUF(m11_moneda_ing)
		IF rm_m11.m11_moneda_ing IS NULL THEN
			CLEAR n_moneda_ing
		ELSE
			CALL fl_lee_moneda(rm_m11.m11_moneda_ing) 
				RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN	
				CLEAR n_moneda_ing
			ELSE
				IF r_mon.g13_estado = 'B' THEN
					CLEAR n_moneda_ing
				ELSE
					DISPLAY r_mon.g13_nombre TO n_moneda_ing
				END IF
			END IF 
		END IF
	AFTER FIELD m11_moneda_prec
		LET rm_m11.m11_moneda_prec = GET_FLDBUF(m11_moneda_prec)
		IF rm_m11.m11_moneda_prec IS NULL THEN
			CLEAR n_moneda_prec
		ELSE
			CALL fl_lee_moneda(rm_m11.m11_moneda_prec) 
				RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN	
				CLEAR n_moneda_prec
			ELSE
				IF r_mon.g13_estado = 'B' THEN
					CLEAR n_moneda_prec
				ELSE
					DISPLAY r_mon.g13_nombre TO n_moneda_prec
				END IF
			END IF 
		END IF
END CONSTRUCT

IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET query = 'SELECT *, ROWID FROM maqt011 ',
            '	WHERE m11_compania  = ', vg_codcia, 
	    '     AND m11_localidad = ', vg_codloc,
            '  	  AND ', expr_sql, ' ORDER BY 1, 2, 3' 
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_m11.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > 1000 THEN
		EXIT FOREACH
	END IF	
END FOREACH 
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN 
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_num_rows = 0
	LET vm_row_current = 0
	CALL muestra_contadores()
	CLEAR FORM
	RETURN
END IF

LET vm_row_current = 1
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION lee_muestra_registro(row)
DEFINE row 		INTEGER
DEFINE total		LIKE maqt011.m11_costo_ing

IF vm_num_rows <= 0 THEN
	RETURN
END IF

SELECT * INTO rm_m11.* FROM maqt011 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

DISPLAY BY NAME rm_m11.m11_bodega,
                rm_m11.m11_modelo,
		rm_m11.m11_estado,
		rm_m11.m11_chasis,
		rm_m11.m11_nuevo,
		rm_m11.m11_codigo_veh,
		rm_m11.m11_comentarios,
		rm_m11.m11_motor,
		rm_m11.m11_ano,
		rm_m11.m11_cod_color,
		rm_m11.m11_dueno,
		rm_m11.m11_kilometraje,
		rm_m11.m11_placa,
		rm_m11.m11_moneda_liq,
		rm_m11.m11_costo_liq,
		rm_m11.m11_cargo_liq,
		rm_m11.m11_numero_liq,
		rm_m11.m11_fec_ing_bod,
		rm_m11.m11_pedido,
		rm_m11.m11_moneda_ing,
		rm_m11.m11_costo_ing,
		rm_m11.m11_cargo_ing,
		rm_m11.m11_costo_adi,
		rm_m11.m11_moneda_prec,
		rm_m11.m11_precio,
		rm_m11.m11_cod_tran,
		rm_m11.m11_num_tran,
		rm_m11.m11_usuario,
		rm_m11.m11_fecing

LET total = rm_m11.m11_costo_ing + rm_m11.m11_cargo_ing + rm_m11.m11_costo_adi
DISPLAY total TO costo_tot

CALL muestra_contadores()
CALL muestra_etiquetas()

END FUNCTION



FUNCTION muestra_contadores()

DISPLAY vm_row_current, vm_num_rows TO vm_row_current2, vm_num_rows2 
DISPLAY vm_row_current, vm_num_rows TO vm_row_current1, vm_num_rows1 

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



FUNCTION muestra_etiquetas()

DEFINE nom_estado		CHAR(9)

DEFINE r_v02			RECORD LIKE veht002.*
DEFINE r_v20			RECORD LIKE veht020.*
DEFINE r_v05			RECORD LIKE veht005.*
DEFINE r_g13			RECORD LIKE gent013.*
DEFINE r_g21			RECORD LIKE gent021.*

CALL fl_lee_bodega_veh(vg_codcia, rm_m11.m11_bodega) RETURNING r_v02.*
DISPLAY r_v02.v02_nombre TO n_bodega

CALL fl_lee_modelo_veh(vg_codcia, rm_m11.m11_modelo) RETURNING r_v20.*
DISPLAY r_v20.v20_modelo_ext TO n_modelo

CALL fl_lee_color_veh(vg_codcia, rm_m11.m11_cod_color) RETURNING r_v05.*
DISPLAY r_v05.v05_descri_base TO n_color

CALL fl_lee_moneda(rm_m11.m11_moneda_liq) RETURNING r_g13.*
DISPLAY r_g13.g13_nombre TO n_moneda_liq

CALL fl_lee_moneda(rm_m11.m11_moneda_ing) RETURNING r_g13.*
DISPLAY r_g13.g13_nombre TO n_moneda_ing

CALL fl_lee_moneda(rm_m11.m11_moneda_prec) RETURNING r_g13.*
DISPLAY r_g13.g13_nombre TO n_moneda_prec

CALL fl_lee_cod_transaccion(rm_m11.m11_cod_tran) RETURNING r_g21.*
DISPLAY r_g21.g21_nombre TO n_transaccion

CASE rm_m11.m11_estado
	WHEN 'A' LET nom_estado = 'ACTIVO'
	WHEN 'B' LET nom_estado = 'BLOQUEADO'
	WHEN 'F' LET nom_estado = 'FACTURADO'
	WHEN 'P' LET nom_estado = 'EN PEDIDO'
	WHEN 'R' LET nom_estado = 'RESERVADO'
	WHEN 'M' LET nom_estado = 'MANUAL'
	WHEN 'C' LET nom_estado = 'EN CHEQUEO'
END CASE
DISPLAY nom_estado   TO n_estado

END FUNCTION



FUNCTION execute_query()

LET vm_num_rows = 1
LET vm_row_current = 1

SELECT ROWID INTO vm_rows[vm_num_rows]
	FROM maqt011
	WHERE m11_compania  = vg_codcia
	  AND m11_localidad = vg_codloc
	  AND m11_codigo_veh = vm_cod_veh
IF STATUS = NOTFOUND THEN
	CALL fgl_winmessage(vg_producto, 
		'No existe vehículo.', 
		'exclamation')
	EXIT PROGRAM
ELSE
	CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION ver_reservacion()

DEFINE command_line	CHAR(100)

IF rm_m11.m11_estado <> 'R' THEN
	CALL fgl_winmessage(vg_producto,
		'Este vehículo no ha sido reservado.',
		'exclamation')
	RETURN
END IF

LET command_line = 'fglrun vehp209 ', vg_base,   ' ', vg_modulo,
		                 ' ', vg_codcia, ' ', vg_codloc,
				 ' ', rm_m11.m11_codigo_veh
RUN command_line

END FUNCTION

}


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
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: ' || 
                            vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
