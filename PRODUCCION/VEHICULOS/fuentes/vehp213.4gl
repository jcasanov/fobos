------------------------------------------------------------------------------
-- Titulo           : vehp213.4gl - Cierre de Pedidos           
-- Elaboracion      : 09-oct-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun vehp213 base modulo compania localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE vm_tipo_tran	LIKE veht030.v30_cod_tran

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA r_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS

DEFINE vm_max_rows	SMALLINT
--
-- DEFINE RECORD(S) HERE
--
DEFINE rm_t00		RECORD LIKE talt000.*
DEFINE rm_v00		RECORD LIKE veht000.*
DEFINE rm_v30		RECORD LIKE veht030.*
DEFINE rm_v36		RECORD LIKE veht036.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'vehp213'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
LET vg_codloc   = arg_val(4)
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
CALL fl_chequeo_mes_proceso_veh(vg_codcia) RETURNING int_flag 
IF int_flag THEN
	RETURN
END IF
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_213 AT 3,2 WITH 15 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_213 FROM '../forms/vehf213_1'
DISPLAY FORM f_213

LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores()

LET vm_tipo_tran = 'IM'
LET vm_max_rows  = 1000

CALL fl_lee_compania_vehiculos(vg_codcia) RETURNING rm_v00.*
IF rm_v00.v00_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'No existe registro de configuracion para está compañía.',
		'stop')
	EXIT PROGRAM
END IF

IF rm_v00.v00_genera_op = 'S' THEN
	CALL fl_lee_configuracion_taller(vg_codcia) RETURNING rm_t00.*
	IF rm_t00.t00_compania IS NULL THEN
		CALL fgl_winmessage(vg_producto,
			'No existe registro de configuracion para está ' ||
			'compañía.',
			'stop')
		EXIT PROGRAM
	END IF
END IF

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Ver Liquidación'
		HIDE OPTION 'Cerrar' 
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		IF vm_num_rows = vm_max_rows THEN
			CALL fl_mensaje_arreglo_lleno()
		ELSE
			CALL control_ingreso()
		END IF
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Ver Liquidación'
			SHOW OPTION 'Cerrar' 
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
	COMMAND KEY('L') 'Ver Liquidación'      'Ver la liquidación.'
		CALL control_liquidacion()
	COMMAND KEY('E') 'Cerrar'		'Cierra la liquidación'
		CALL control_cerrar()
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro.'
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Ver Liquidación'
			SHOW OPTION 'Cerrar' 
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Ver Liquidación'
				HIDE OPTION 'Cerrar' 
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Ver Liquidación'
			SHOW OPTION 'Cerrar' 
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
		CALL siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
		CALL anterior_registro()
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

DEFINE r_v36		RECORD LIKE veht036.*

CLEAR FORM
INITIALIZE rm_v36.* TO NULL

OPTIONS 
	INPUT NO WRAP

LET INT_FLAG = 0
INPUT BY NAME rm_v36.v36_numliq WITHOUT DEFAULTS
	ON KEY(F2)
		IF INFIELD(v36_numliq) THEN
			CALL fl_ayuda_liquidacion_vehiculos(vg_codcia, 		
							    vg_codloc)	
				RETURNING r_v36.v36_pedido, r_v36.v36_numliq,
					  r_v36.v36_estado 
			IF r_v36.v36_numliq IS NOT NULL THEN
				LET rm_v36.v36_numliq = r_v36.v36_numliq
				LET rm_v36.v36_pedido = r_v36.v36_pedido
				DISPLAY BY NAME rm_v36.v36_numliq,
						rm_v36.v36_pedido
			END IF
		END IF
	LET INT_FLAG = 0
END INPUT

OPTIONS 
	INPUT WRAP

IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET vm_num_rows = vm_num_rows + 1
SELECT ROWID INTO vm_rows[vm_num_rows]
	FROM veht036
	WHERE v36_compania  = vg_codcia
	  AND v36_localidad = vg_codloc
	  AND v36_numliq    = rm_v36.v36_numliq
IF STATUS = NOTFOUND THEN
	CALL fgl_winmessage(vg_producto,
			    'Número de liquidación no existe',
			    'exclamation')
	LET vm_num_rows = vm_num_rows - 1
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
ELSE
	LET vm_row_current = vm_num_rows
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	

END IF

END FUNCTION



FUNCTION control_consulta()

DEFINE expr_sql			VARCHAR(500)
DEFINE query			VARCHAR(600)

DEFINE r_v34		RECORD LIKE veht034.*
DEFINE r_v36		RECORD LIKE veht036.*
DEFINE r_mon		RECORD LIKE gent013.*

CLEAR FORM

LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql 
	ON v36_numliq, v36_pedido, v36_fecing, v36_estado,
	   v36_moneda, v36_fob_fabrica, v36_total_fob, v36_tot_cargos,
	   v36_margen_uti, v36_fecha_lleg, v36_fecha_ing
	oN KEY(F2)
		IF INFIELD(v36_numliq) THEN
			CALL fl_ayuda_liquidacion_vehiculos(vg_codcia, 		
							    vg_codloc)	
				RETURNING r_v36.v36_pedido, r_v36.v36_numliq,
					  r_v36.v36_estado 
			IF r_v36.v36_numliq IS NOT NULL THEN
				LET rm_v36.v36_numliq = r_v36.v36_numliq
				LET rm_v36.v36_pedido = r_v36.v36_pedido
				DISPLAY BY NAME rm_v36.v36_numliq,
						rm_v36.v36_pedido
			END IF
		END IF
		IF INFIELD(v36_pedido) THEN
			CALL fl_ayuda_pedidos_vehiculos(vg_codcia, vg_codloc,
							'L')
				RETURNING r_v34.v34_pedido, r_v34.v34_estado,
					  r_v34.v34_fec_envio, 
					  r_v34.v34_fec_llegada
			IF r_v34.v34_pedido IS NOT NULL THEN
				LET rm_v36.v36_pedido      = r_v34.v34_pedido
				DISPLAY BY NAME rm_v36.v36_pedido
			END IF		
		END IF
		IF INFIELD(v36_moneda) THEN
			CALL fl_ayuda_monedas() 
				RETURNING r_mon.g13_moneda, r_mon.g13_nombre, 
					  r_mon.g13_decimales 
			IF r_mon.g13_moneda IS NOT NULL THEN
				LET rm_v36.v36_moneda = r_mon.g13_moneda
				DISPLAY r_mon.g13_moneda TO v36_moneda
				DISPLAY r_mon.g13_nombre TO n_moneda
			END IF	
		END IF
		LET INT_FLAG = 0
	AFTER FIELD v36_moneda
		LET rm_v36.v36_moneda = GET_FLDBUF(v36_moneda)
		IF rm_v36.v36_moneda IS NULL THEN
			CLEAR n_moneda
		ELSE
			CALL fl_lee_moneda(rm_v36.v36_moneda) RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN	
				CLEAR n_moneda
			ELSE
				IF r_mon.g13_estado = 'B' THEN
					CLEAR n_moneda
				ELSE
					DISPLAY r_mon.g13_nombre TO n_moneda
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

LET query = 'SELECT *, ROWID FROM veht036 ',
            '	WHERE v36_compania  = ', vg_codcia, 
	    ' 	  AND v36_localidad = ', vg_codloc,
	    ' 	  AND ', expr_sql CLIPPED,
	    '	ORDER BY 4 DESC'

PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_v36.*, vm_rows[vm_num_rows]
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

IF vm_num_rows <= 0 THEN
	RETURN
END IF

SELECT * INTO rm_v36.* FROM veht036 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

DISPLAY BY NAME rm_v36.v36_numliq,
                rm_v36.v36_pedido,
		rm_v36.v36_estado,
		rm_v36.v36_fecha_lleg,
		rm_v36.v36_fecha_ing,
		rm_v36.v36_moneda,
		rm_v36.v36_fob_fabrica,
		rm_v36.v36_total_fob,
		rm_v36.v36_tot_cargos,
		rm_v36.v36_margen_uti,
		rm_v36.v36_fecing

CALL muestra_etiquetas()
CALL muestra_contadores()

END FUNCTION



FUNCTION muestra_contadores()

--DISPLAY '   ' TO n_estado
--CLEAR n_estado

DISPLAY "" AT 1,1
DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 68 

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
DEFINE r_g13			RECORD LIKE gent013.*

CASE rm_v36.v36_estado
	WHEN 'A' LET nom_estado = 'ACTIVO'
	WHEN 'P' LET nom_estado = 'PROCESADO'
END CASE
DISPLAY nom_estado   TO n_estado

CALL fl_lee_moneda(rm_v36.v36_moneda) RETURNING r_g13.*
DISPLAY r_g13.g13_nombre TO n_moneda
	
END FUNCTION



FUNCTION actualiza_vehiculo(r_v35, inland, seguro, cargos, otros)

DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT

DEFINE inland		LIKE veht036.v36_inland
DEFINE seguro 		LIKE veht036.v36_seguro
DEFINE otros  		LIKE veht036.v36_otros 
DEFINE cargos		LIKE veht037.v37_valor

DEFINE r_v35		RECORD LIKE veht035.*
DEFINE r_v22		RECORD LIKE veht022.*

LET intentar = 1
LET done = 0
WHILE (intentar)
	INITIALIZE r_v22.* TO NULL
	WHENEVER ERROR CONTINUE
		DECLARE q_v22 CURSOR FOR 
			SELECT * FROM veht022
				WHERE v22_compania   = vg_codcia
				  AND v22_localidad  = vg_codloc
				  AND v22_codigo_veh = r_v35.v35_codigo_veh
		FOR UPDATE
	OPEN q_v22  
	FETCH q_v22 INTO r_v22.*
	WHENEVER ERROR STOP
	IF STATUS < 0 THEN
		LET intentar = mensaje_intentar()
		CLOSE q_v22
		FREE  q_v22
	ELSE
		LET intentar = 0
		LET done = 1
	END IF
END WHILE

IF NOT intentar AND NOT done THEN
	RETURN done
END IF

	LET r_v22.v22_bodega      = rm_v36.v36_bodega 
	LET r_v22.v22_numero_liq  = rm_v36.v36_numliq
	LET r_v22.v22_moneda_liq  = rm_v36.v36_moneda
	LET r_v22.v22_costo_liq   = r_v35.v35_precio_unit
	LET r_v22.v22_cargo_liq   = cargos + inland + seguro + otros + 
				    r_v35.v35_flete
	LET r_v22.v22_numero_liq  = rm_v36.v36_numliq
	LET r_v22.v22_fec_ing_bod = rm_v36.v36_fecha_ing
	LET r_v22.v22_moneda_ing  = r_v22.v22_moneda_liq
	LET r_v22.v22_costo_ing   = r_v22.v22_costo_liq
	LET r_v22.v22_cargo_ing   = r_v22.v22_cargo_liq

   -- Calculamos el precio de venta de este vehículo
	LET r_v22.v22_precio      = r_v22.v22_costo_liq + r_v22.v22_cargo_liq
	LET r_v22.v22_precio      = 
		r_v22.v22_precio * (1 + (rm_v36.v36_margen_uti / 100))
	
	LET r_v22.v22_estado      = 'A'
	IF rm_v00.v00_genera_op = 'S' THEN
		LET r_v22.v22_estado      = 'C'
	END IF

	UPDATE veht022 SET * = r_v22.* WHERE CURRENT OF q_v22   
CLOSE q_v22
FREE  q_v22
RETURN done

END FUNCTION 



FUNCTION mensaje_intentar()

DEFINE intentar		SMALLINT
DEFINE resp		CHAR(6)

LET intentar = 1
CALL fgl_winquestion(vg_producto, 
		     'Registro bloqueado por ' ||
	      	     'otro usuario, desea ' ||
                     'intentarlo nuevamente', 'No',
		     'Yes|No', 'question', 1)
				RETURNING resp
IF resp = 'No' THEN
	CALL fl_mensaje_abandonar_proceso()
		 RETURNING resp
	IF resp = 'Yes' THEN
		LET intentar = 0
	END IF	
END IF

RETURN intentar

END FUNCTION



FUNCTION control_liquidacion()

DEFINE command_line	CHAR(100)

IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

LET command_line = 'fglrun vehp212 ', vg_base,   ' ', vg_modulo,
		                 ' ', vg_codcia, ' ', vg_codloc,
				 ' ', rm_v36.v36_numliq
RUN command_line

END FUNCTION



FUNCTION control_cerrar()

DEFINE done		SMALLINT

DEFINE r_v34		RECORD LIKE veht034.*

IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

IF rm_v36.v36_estado = 'P' THEN
	CALL fgl_winmessage(vg_producto,
			    'La liquidación ya fue cerrada.',
			    'exclamation')
	RETURN
END IF

LET r_v34.v34_compania  = rm_v36.v36_compania
LET r_v34.v34_localidad = rm_v36.v36_localidad
LET r_v34.v34_pedido    = rm_v36.v36_pedido   

SELECT COUNT(*) INTO r_v34.v34_unid_liq 
	FROM veht035
	WHERE v35_compania  = vg_codcia
	  AND v35_localidad = vg_codloc
	  AND v35_pedido    = r_v34.v34_pedido
	  AND v35_estado    = 'L'
BEGIN WORK

LET done = actualiza_cabecera_liq()
IF NOT done THEN
	ROLLBACK WORK
	RETURN
END IF

LET done = actualiza_cabecera_pedido(r_v34.*)
IF NOT done THEN
	ROLLBACK WORK
	RETURN
END IF

LET done = actualiza_modelo()
IF NOT done THEN
	ROLLBACK WORK
	RETURN
END IF

LET done = actualiza_detalle_pedido(r_v34.v34_unid_liq)
IF NOT done THEN
	ROLLBACK WORK
	RETURN
END IF

LET done = genera_transaccion()
IF NOT done THEN
	ROLLBACK WORK
	RETURN
END IF

COMMIT WORK
CALL fl_control_master_contab_vehiculos(vg_codcia, vg_codloc, 
		rm_v30.v30_cod_tran, rm_v30.v30_num_tran)

CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION actualiza_cabecera_liq()

DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT

DEFINE r_v36		RECORD LIKE veht036.*

LET intentar = 1
LET done = 0
WHILE (intentar)
	INITIALIZE r_v36.* TO NULL
	WHENEVER ERROR CONTINUE
		DECLARE q_v36 CURSOR FOR
			SELECT * FROM veht036
				WHERE v36_compania  = vg_codcia
				  AND v36_localidad = vg_codloc
				  AND v36_numliq    = rm_v36.v36_numliq
			FOR UPDATE
	OPEN  q_v36  
	FETCH q_v36 INTO r_v36.*
	WHENEVER ERROR STOP
	IF STATUS < 0 THEN
		LET intentar = mensaje_intentar()
		CLOSE q_v36
		FREE  q_v36
	ELSE
		LET intentar = 0
		LET done = 1
	END IF
END WHILE

IF NOT intentar AND NOT done THEN
	RETURN done
END IF
	LET r_v36.v36_fecha_ing = TODAY
	LET r_v36.v36_estado    = 'P'
	UPDATE veht036 SET * = r_v36.* WHERE CURRENT OF q_v36   
CLOSE q_v36  
FREE  q_v36
RETURN done

END FUNCTION



FUNCTION actualiza_cabecera_pedido(r_v34)

DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT

DEFINE r_v34		RECORD LIKE veht034.*
DEFINE r_upd		RECORD LIKE veht034.*

LET intentar = 1
LET done = 0
WHILE (intentar)
	INITIALIZE r_upd.* TO NULL
	WHENEVER ERROR CONTINUE
		DECLARE q_v34 CURSOR FOR
			SELECT * FROM veht034
				WHERE v34_compania  = r_v34.v34_compania
				  AND v34_localidad = r_v34.v34_localidad
				  AND v34_pedido    = r_v34.v34_pedido
			FOR UPDATE
	OPEN q_v34  
	FETCH q_v34 INTO r_upd.*
	WHENEVER ERROR STOP
	IF STATUS < 0 THEN
		LET intentar = mensaje_intentar()
		CLOSE q_v34
		FREE  q_v34
	ELSE
		LET intentar = 0
		LET done = 1
	END IF
END WHILE

IF NOT intentar AND NOT done THEN
	RETURN done
END IF

	LET r_upd.v34_unid_liq = r_v34.v34_unid_liq
	IF r_upd.v34_unid_ped = r_upd.v34_unid_liq THEN
		LET r_upd.v34_estado   = 'P'
	ELSE
		LET r_upd.v34_estado   = 'R'
	END IF

	UPDATE veht034 SET * = r_upd.* WHERE CURRENT OF q_v34
CLOSE q_v34  
FREE  q_v34
RETURN done

END FUNCTION



FUNCTION actualiza_detalle_pedido(unid_liq)

DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT

DEFINE inland		LIKE veht036.v36_inland
DEFINE seguro 		LIKE veht036.v36_seguro
DEFINE otros  		LIKE veht036.v36_otros 
DEFINE cargos		LIKE veht037.v37_valor
DEFINE pu    		LIKE veht037.v37_valor   -- PRECIO (FOB, CIF) POR UNIDAD
DEFINE base  		LIKE veht037.v37_valor   -- PRECIO (FOB, CIF) POR TODAS
						 -- LAS UNIDADES  
DEFINE unid_liq		SMALLINT

DEFINE r_v35		RECORD LIKE veht035.*
DEFINE r_v37		RECORD LIKE veht037.*

DECLARE q_v37 CURSOR FOR
	SELECT * FROM veht037 
		WHERE v37_compania  = rm_v36.v36_compania
		  AND v37_localidad = rm_v36.v36_localidad
		  AND v37_numliq    = rm_v36.v36_numliq

LET intentar = 1
LET done = 0
WHILE (intentar)
	INITIALIZE r_v35.* TO NULL
	WHENEVER ERROR CONTINUE
		DECLARE q_v35 CURSOR FOR
			SELECT * FROM veht035
				WHERE v35_compania  = vg_codcia
				  AND v35_localidad = vg_codloc
				  AND v35_pedido    = rm_v36.v36_pedido
				  AND v35_estado    = 'L'
			FOR UPDATE
	OPEN  q_v35
	FETCH q_v35 INTO r_v35.*
	WHENEVER ERROR STOP
	IF STATUS < 0 THEN
		LET intentar = mensaje_intentar()
		CLOSE q_v35
		FREE  q_v35
	ELSE
		LET intentar = 0
		LET done = 1
	END IF
END WHILE

IF NOT intentar AND NOT done THEN
	RETURN done
END IF

WHILE (STATUS <> NOTFOUND)
	LET inland = (rm_v36.v36_inland / rm_v36.v36_fob_fabrica) * 
		     r_v35.v35_precio_unit
	LET seguro = (rm_v36.v36_seguro / rm_v36.v36_fob_fabrica) * 
		     r_v35.v35_precio_unit
	LET otros  = (rm_v36.v36_otros / rm_v36.v36_fob_fabrica) * 
		     r_v35.v35_precio_unit
	LET cargos = 0
	FOREACH q_v37 INTO r_v37.*
		IF r_v37.v37_indicador = 'U' THEN
			LET cargos = cargos + 
				     ((r_v37.v37_valor * r_v37.v37_paridad)
				      / unid_liq) 
		END IF
--	El valor de la base se almacena en una variable dependiendo del 
--	indicador para hacer una unica operacion de prorrateo.
		IF r_v37.v37_indicador = 'P' THEN
			CASE r_v37.v37_base
				WHEN 'CIF'
					LET pu = inland + 
					         r_v35.v35_precio_unit +
					         r_v35.v35_flete +
				     	         seguro +
						 otros
					LET base = rm_v36.v36_total_fob +
						   rm_v36.v36_seguro 
				WHEN 'FOB'
					LET pu   = r_v35.v35_precio_unit
					LET base = rm_v36.v36_fob_fabrica 
			END CASE
			LET cargos = cargos + 
				     (((r_v37.v37_valor * r_v37.v37_paridad)
				      / base) * pu)		
		END IF
	END FOREACH 
	LET r_v35.v35_bodega_liq = rm_v36.v36_bodega
	LET r_v35.v35_costo_liq  = r_v35.v35_precio_unit + inland + seguro +
				   otros + cargos 

	UPDATE veht035 SET * = r_v35.* WHERE CURRENT OF q_v35   

	LET done = actualiza_vehiculo(r_v35.*, inland, seguro, cargos, otros)
	IF NOT done THEN
		EXIT WHILE  
	END IF

	INITIALIZE r_v35.* TO NULL
	FETCH q_v35 INTO r_v35.*
END WHILE    
CLOSE q_v35
FREE  q_v35
FREE  q_v37
RETURN done

END FUNCTION



FUNCTION actualiza_modelo()

DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT

DEFINE r_v20		RECORD LIKE veht020.*
DEFINE modelo		LIKE veht035.v35_modelo

DECLARE q_mod CURSOR FOR
	SELECT v35_modelo 
		FROM veht035
		WHERE v35_compania  = vg_codcia
	  	  AND v35_localidad = vg_codloc
	  	  AND v35_pedido    = rm_v36.v36_pedido
	  	  AND v35_estado    = 'L'
	
INITIALIZE modelo TO NULL
FOREACH q_mod INTO modelo
	LET intentar = 1
	LET done = 0
	WHILE (intentar)
		INITIALIZE r_v20.* TO NULL
		WHENEVER ERROR CONTINUE
			DECLARE q_v20 CURSOR FOR 
				SELECT * FROM veht020
					WHERE v20_compania  = vg_codcia
					  AND v20_modelo    = modelo
				FOR UPDATE
		OPEN  q_v20
		FETCH q_v20 INTO r_v20.*
		WHENEVER ERROR STOP
		IF STATUS < 0 THEN
			LET intentar = mensaje_intentar()
			CLOSE q_v20
			FREE  q_v20
		ELSE
			LET intentar = 0
			LET done = 1
		END IF
	END WHILE
	IF NOT intentar AND NOT done THEN
		RETURN done
	END IF
	
	UPDATE veht020 SET v20_pedidos = v20_pedidos - 1,
			   v20_stock   = v20_stock   + 1
		WHERE CURRENT OF q_v20
	CLOSE q_v20
	FREE  q_v20
END FOREACH	

RETURN done
	  
END FUNCTION



FUNCTION genera_transaccion()

DEFINE intentar		SMALLINT
DEFINE done, i 		SMALLINT

DEFINE r_v35		RECORD LIKE veht035.*
DEFINE r_v34		RECORD LIKE veht034.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_g14		RECORD LIKE gent014.*
DEFINE r_prov		RECORD LIKE cxpt001.*
DEFINE r_ctrn		RECORD LIKE veht030.*
DEFINE r_v31		RECORD LIKE veht031.*
DEFINE r_v22		RECORD LIKE veht022.*

CALL fl_lee_pedido_veh(vg_codcia, vg_codloc, rm_v36.v36_pedido) 
	RETURNING r_v34.*
CALL fl_lee_proveedor(r_v34.v34_proveedor) RETURNING r_prov.*
INITIALIZE r_ctrn.* TO NULL
LET r_ctrn.v30_num_tran = fl_actualiza_control_secuencias(vg_codcia, 
						          vg_codloc, 
     							  vg_modulo, 
							  'AA', 
							  vm_tipo_tran)
IF r_ctrn.v30_num_tran <= 0 THEN
	ROLLBACK WORK
	EXIT PROGRAM
END IF
LET r_ctrn.v30_compania 	= vg_codcia
LET r_ctrn.v30_localidad 	= vg_codcia
LET r_ctrn.v30_cod_tran 	= vm_tipo_tran
LET r_ctrn.v30_cont_cred 	= 'C'
LET r_ctrn.v30_referencia 	= 'LIQUIDACION: ', 
				  rm_v36.v36_numliq USING '#####'
LET r_ctrn.v30_nomcli 		= r_prov.p01_nomprov
LET r_ctrn.v30_dircli 		= r_prov.p01_direccion1
LET r_ctrn.v30_cedruc 		= r_prov.p01_num_doc
SELECT MIN(v01_vendedor) INTO r_ctrn.v30_vendedor
	FROM veht001 WHERE v01_compania = vg_codcia
LET r_ctrn.v30_descuento 	= 0
LET r_ctrn.v30_porc_impto 	= 0
LET r_ctrn.v30_bodega_ori 	= rm_v36.v36_bodega
LET r_ctrn.v30_bodega_dest 	= rm_v36.v36_bodega
LET r_ctrn.v30_fact_costo 	= rm_v36.v36_fact_costo
LET r_ctrn.v30_fact_venta 	= rm_v36.v36_margen_uti
LET r_ctrn.v30_moneda 		= rm_v36.v36_moneda
IF rg_gen.g00_moneda_base = rm_v36.v36_moneda THEN
	LET r_ctrn.v30_paridad = 1
ELSE
	CALL fl_lee_factor_moneda(rm_v36.v36_moneda, rg_gen.g00_moneda_base) 
		RETURNING r_g14.*
	IF r_g14.g14_serial IS NULL THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto, 
			'No hay paridad de conversión de: ' || 
			rm_v36.v36_moneda || ' a ' || rg_gen.g00_moneda_base, 
			'stop')
		EXIT PROGRAM
	END IF
	LET r_ctrn.v30_paridad = r_g14.g14_tasa
END IF	
CALL fl_lee_moneda(rm_v36.v36_moneda) RETURNING r_g13.*	   	 
LET r_ctrn.v30_precision 	= r_g13.g13_decimales
LET r_ctrn.v30_tot_costo 	= rm_v36.v36_total_fob + rm_v36.v36_seguro +
				  rm_v36.v36_tot_cargos
LET r_ctrn.v30_tot_bruto 	= rm_v36.v36_total_fob + rm_v36.v36_seguro +
				  rm_v36.v36_tot_cargos
LET r_ctrn.v30_tot_dscto 	= rm_v36.v36_total_fob + rm_v36.v36_seguro +
				  rm_v36.v36_tot_cargos
LET r_ctrn.v30_tot_neto  	= rm_v36.v36_total_fob + rm_v36.v36_seguro +
				  rm_v36.v36_tot_cargos
LET r_ctrn.v30_flete 		= rm_v36.v36_flete
LET r_ctrn.v30_numliq 		= rm_v36.v36_numliq
LET r_ctrn.v30_usuario 	        = vg_usuario
LET r_ctrn.v30_fecing 		= CURRENT
INSERT INTO veht030 VALUES (r_ctrn.*)
LET rm_v30.* = r_ctrn.*
LET intentar = 1
LET done     = 0

WHILE (intentar)
	INITIALIZE r_v35.* TO NULL
	WHENEVER ERROR CONTINUE
	DECLARE q_dped CURSOR FOR 
		SELECT * FROM veht035
			WHERE v35_compania  = vg_codcia
			  AND v35_localidad = vg_codloc
			  AND v35_pedido    = rm_v36.v36_pedido
			  AND v35_estado    = 'L'
		FOR UPDATE
	OPEN  q_dped
	FETCH q_dped INTO r_v35.*
	WHENEVER ERROR STOP
	IF status < 0 THEN
		LET intentar = mensaje_intentar()
		CLOSE q_dped
		FREE  q_dped
	ELSE
		LET intentar = 0
		LET done     = 1
	END IF
END WHILE

IF NOT done AND NOT intentar THEN
	RETURN done
END IF

WHILE (status <> NOTFOUND)
	INITIALIZE r_v31.* TO NULL
	LET r_v31.v31_compania      = vg_codcia       
	LET r_v31.v31_localidad     = vg_codloc
	LET r_v31.v31_cod_tran      = r_ctrn.v30_cod_tran
	LET r_v31.v31_num_tran      = r_ctrn.v30_num_tran 
	LET r_v31.v31_codigo_veh    = r_v35.v35_codigo_veh 
	CALL fl_lee_cod_vehiculo_veh(vg_codcia, vg_codloc,
					r_v35.v35_codigo_veh)
					RETURNING r_v22.*
	LET r_v31.v31_nuevo         = r_v22.v22_nuevo   
	LET r_v31.v31_descuento     = 0
	LET r_v31.v31_val_descto    = 0  
	LET r_v31.v31_precio        = r_v22.v22_precio 
	LET r_v31.v31_moneda_cost   = r_v22.v22_moneda_ing 
	LET r_v31.v31_costo         = r_v22.v22_costo_ing
	LET r_v31.v31_fob           = r_v22.v22_costo_liq
	LET r_v31.v31_costant_mb    = r_v22.v22_costo_ing 
	LET r_v31.v31_costant_ma    = r_v22.v22_costo_ing 
	LET r_v31.v31_costnue_mb    = r_v22.v22_costo_ing 
	LET r_v31.v31_costnue_ma    = r_v22.v22_costo_ing 

	INSERT INTO veht031 VALUES (r_v31.*)

	IF rm_v00.v00_genera_op = 'S' THEN
		CALL genera_orden_chequeo(r_v22.v22_codigo_veh, 
					  r_ctrn.v30_num_tran)
		CALL ingresa_vehiculo_taller(r_v22.*)
	END IF

	UPDATE veht035 SET v35_estado = 'P' WHERE CURRENT OF q_dped
	
	INITIALIZE r_v35.* TO NULL
	FETCH q_dped INTO r_v35.*
END WHILE  			   			   	
CLOSE q_dped
FREE  q_dped

RETURN done

END FUNCTION



FUNCTION genera_orden_chequeo(codigo_veh, importacion)

DEFINE importacion 	DECIMAL(15,0)
DEFINE codigo_veh	LIKE veht022.v22_codigo_veh
DEFINE r_v38		RECORD LIKE veht038.*

INITIALIZE r_v38.* TO NULL

LET r_v38.v38_compania     = vg_codcia 
LET r_v38.v38_localidad    = vg_codloc

SELECT MAX(v38_orden_cheq) INTO r_v38.v38_orden_cheq
	FROM veht038
	WHERE v38_compania  = vg_codcia
	  AND v38_localidad = vg_codloc
IF r_v38.v38_orden_cheq IS NULL THEN
	LET r_v38.v38_orden_cheq = 1
ELSE
	LET r_v38.v38_orden_cheq = r_v38.v38_orden_cheq + 1
END IF

LET r_v38.v38_estado       = 'A'
LET r_v38.v38_codigo_veh   = codigo_veh 
LET r_v38.v38_referencia   = 'IMPORTACION # ' || importacion
LET r_v38.v38_usuario      = vg_usuario   
LET r_v38.v38_fecing       = CURRENT

INSERT INTO veht038 VALUES(r_v38.*)

END FUNCTION



FUNCTION ingresa_vehiculo_taller(r_v22)

DEFINE r_t10		RECORD LIKE talt010.*
DEFINE r_v22		RECORD LIKE veht022.*

INITIALIZE r_t10.* TO NULL
LET r_t10.t10_compania      = vg_codcia 
LET r_t10.t10_codcli        = rm_t00.t00_codcli_int
LET r_t10.t10_modelo        = r_v22.v22_modelo 
LET r_t10.t10_chasis        = r_v22.v22_chasis
LET r_t10.t10_estado        = 'A'
LET r_t10.t10_color         = r_v22.v22_cod_color
LET r_t10.t10_motor         = r_v22.v22_motor 
IF r_t10.t10_placa IS NOT NULL THEN
	LET r_t10.t10_placa         = r_v22.v22_placa
ELSE
	LET r_t10.t10_placa         = '.'
END IF
LET r_t10.t10_ano           = r_v22.v22_ano
LET r_t10.t10_usuario       = vg_usuario
LET r_t10.t10_fecing        = CURRENT

INSERT INTO talt010 VALUES (r_t10.*)

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
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: ' || 
                            vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
