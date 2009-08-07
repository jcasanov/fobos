------------------------------------------------------------------------------
-- Titulo           : vehp212.4gl - Liquidación de pedidos      
-- Elaboracion      : 05-oct-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun vehp212 base modulo compania localidad [numliq]
--		Si (numliq <> 0) el programa se esta ejcutando en modo de
--			solo consulta
--		Si (numliq = 0) el programa se esta ejecutando en forma 
--			independiente
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)

DEFINE vm_numliq	LIKE veht036.v36_numliq

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA r_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS

DEFINE vm_max_rows	SMALLINT
--
-- DEFINE RECORD(S) HERE
--
DEFINE rm_v36		RECORD LIKE veht036.*
DEFINE vm_max_rubros	SMALLINT
DEFINE rm_rubros ARRAY[100] OF RECORD
	rubro		LIKE veht037.v37_codrubro, 
	fecha		LIKE veht037.v37_fecha,	 
	indicador	LIKE veht037.v37_indicador, 
	base		LIKE veht037.v37_base,
	moneda		LIKE veht037.v37_moneda, 
	paridad		LIKE veht037.v37_paridad, 
	valor		LIKE veht037.v37_valor,
	valor_ml	LIKE veht037.v37_valor,
	check		CHAR(1)
END RECORD
DEFINE rm_v37 	ARRAY[100] OF RECORD 
	serial		LIKE veht037.v37_serial,
	orden		LIKE veht037.v37_orden,
	observacion	LIKE veht037.v37_observacion
END RECORD



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 THEN	-- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'vehp212'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
LET vg_codloc   = arg_val(4)		

LET vm_numliq = 0 			-- igual a cero si se ejecuta en forma 
IF num_args() = 5 THEN   		-- independiente
	LET vm_numliq   = arg_val(5) 	-- <> de cero si se ejecuta en modo de 
END IF					-- solo consulta

CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_212 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST - 1) 
OPEN FORM f_212 FROM '../forms/vehf212_1'
DISPLAY FORM f_212

LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_v36.* TO NULL
CALL muestra_contadores()

LET vm_max_rows   = 1000
LET vm_max_rubros = 100

IF vm_numliq <> 0 THEN
	CALL execute_query()
END IF

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Eliminar'
		HIDE OPTION 'Unidades'
		HIDE OPTION 'Rubros'
		HIDE OPTION 'Fletes'
		IF vm_numliq <> 0 THEN          -- Se ejecuta en modo de solo
			HIDE OPTION 'Ingresar'  -- consulta
			HIDE OPTION 'Consultar'
			IF vm_num_rows = 1 THEN
				SHOW OPTION 'Rubros'
				SHOW OPTION 'Fletes'
				SHOW OPTION 'Unidades'
			END IF
		END IF
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Rubros'
			SHOW OPTION 'Fletes'
			SHOW OPTION 'Eliminar'
			SHOW OPTION 'Unidades'
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
	COMMAND KEY('M') 'Modificar' 		'Modificar registro corriente.'
		CALL control_modificacion()
	COMMAND KEY('E') 'Eliminar'		'Elimina registro corriente'
		CALL control_eliminacion()
	COMMAND KEY('U') 'Unidades' 		'Ver unidades liquidadas.'
		CALL mostrar_unidades()
	COMMAND KEY('B') 'Rubros'		'Ingresar rubros.'
		CALL ingresa_rubros()
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	COMMAND KEY('F') 'Fletes'		'Ingresar valores fletes'
		CALL ingresa_fletes()
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro.'
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Unidades'
			SHOW OPTION 'Rubros'
			SHOW OPTION 'Fletes'
			SHOW OPTION 'Eliminar'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Rubros'
				HIDE OPTION 'Fletes'
				HIDE OPTION 'Unidades'
				HIDE OPTION 'Eliminar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Unidades'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Eliminar'
			SHOW OPTION 'Rubros'
			SHOW OPTION 'Fletes'
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

DEFINE done 		SMALLINT

DEFINE r_v00		RECORD LIKE veht000.*
DEFINE r_g14		RECORD LIKE gent014.*

CLEAR FORM
INITIALIZE rm_v36.* TO NULL

LET rm_v36.v36_fecing      = CURRENT
LET rm_v36.v36_usuario     = vg_usuario
LET rm_v36.v36_compania    = vg_codcia
LET rm_v36.v36_localidad   = vg_codloc
LET rm_v36.v36_estado      = 'A'
LET rm_v36.v36_moneda      = rg_gen.g00_moneda_base

CALL fl_lee_compania_vehiculos(vg_codcia) RETURNING r_v00.*

LET rm_v36.v36_paridad_mb  = calcula_paridad(rm_v36.v36_moneda, 
					     rg_gen.g00_moneda_base)

LET rm_v36.v36_fecha_ing   = CURRENT
LET rm_v36.v36_fob_fabrica = 0.0 
LET rm_v36.v36_inland      = 0.0 
LET rm_v36.v36_flete       = 0.0 
LET rm_v36.v36_otros       = 0.0 
LET rm_v36.v36_total_fob   = 0.0 
LET rm_v36.v36_seguro      = 0.0 
LET rm_v36.v36_tot_cargos  = 0.0 
LET rm_v36.v36_margen_uti  = 0.0 
LET rm_v36.v36_fact_costo  = 0.0 
LET rm_v36.v36_paridad_ma  = 0.0 

CALL muestra_etiquetas()
CALL lee_datos('I')
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

BEGIN WORK

SELECT MAX(v36_numliq) INTO rm_v36.v36_numliq
	FROM veht036
	WHERE v36_compania  = vg_codcia
	  AND v36_localidad = vg_codloc
IF rm_v36.v36_numliq IS NULL THEN
	LET rm_v36.v36_numliq = 1
ELSE
	LET rm_v36.v36_numliq = rm_v36.v36_numliq + 1
END IF  

INSERT INTO veht036 VALUES (rm_v36.*)
DISPLAY BY NAME rm_v36.v36_numliq

IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF
LET vm_row_current = vm_num_rows
LET vm_rows[vm_num_rows] = SQLCA.SQLERRD[6] 	-- Rowid de la ultima fila 
                                             	-- procesada
LET done = actualiza_estado_pedido('L')
IF NOT done THEN
	ROLLBACK WORK
	CLEAR FORM                                         
	RETURN
END IF

LET done = actualiza_detalles_pedido('R', 'L', rm_v36.v36_numliq)
IF NOT done THEN
	ROLLBACK WORK
	CLEAR FORM                                         
	RETURN
END IF
COMMIT WORK

CALL muestra_contadores()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_modificacion()

IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

IF rm_v36.v36_estado = 'P' THEN
	CALL fgl_winmessage(vg_producto,
			    'Esta liquidacion ya fue cerrada y no puede ser' ||	
                            ' modificada',
			    'exclamation')
	RETURN
END IF

CALL lee_muestra_registro(vm_rows[vm_row_current])

WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_upd CURSOR FOR 
	SELECT * FROM veht036 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_upd
FETCH q_upd INTO rm_v36.*
WHENEVER ERROR STOP
IF STATUS < 0 THEN
	CALL fl_mensaje_bloqueo_otro_usuario()
	ROLLBACK WORK
	RETURN
END IF  

CALL lee_datos('M')

IF INT_FLAG THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	CLOSE q_upd
	RETURN
END IF 

UPDATE veht036 SET * = rm_v36.* WHERE CURRENT OF q_upd
COMMIT WORK
CLOSE q_upd
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION calcula_paridad(moneda_ori, moneda_dest)

DEFINE moneda_ori	LIKE veht036.v36_moneda
DEFINE moneda_dest	LIKE veht036.v36_moneda
DEFINE paridad		LIKE veht036.v36_paridad_mb

DEFINE r_g14		RECORD LIKE gent014.*

IF moneda_ori = moneda_dest THEN
	LET paridad = 1 
ELSE
	CALL fl_lee_factor_moneda(moneda_ori, moneda_dest) 
		RETURNING r_g14.*
	IF r_g14.g14_serial IS NULL THEN
		CALL fgl_winmessage(vg_producto, 
				    'No existe factor de conversión ' ||
				    'para esta moneda',
				    'exclamation')
		INITIALIZE paridad TO NULL
	ELSE
		LET paridad = r_g14.g14_tasa 
	END IF
END IF

RETURN paridad

END FUNCTION



FUNCTION lee_detalle()

DEFINE i		SMALLINT
DEFINE r_v37		RECORD LIKE veht037.*

DECLARE q_ing2 CURSOR FOR 
	SELECT * FROM veht037 
		WHERE v37_compania  = vg_codcia
	          AND v37_localidad = vg_codloc
	          AND v37_numliq    = rm_v36.v36_numliq
		ORDER BY v37_fecha, v37_orden

LET i = 1
FOREACH q_ing2 INTO r_v37.*
	LET rm_rubros[i].rubro     = r_v37.v37_codrubro
	LET rm_rubros[i].fecha     = r_v37.v37_fecha   
	LET rm_rubros[i].indicador = r_v37.v37_indicador
	LET rm_rubros[i].base      = r_v37.v37_base
	LET rm_rubros[i].moneda    = r_v37.v37_moneda
	LET rm_rubros[i].paridad   = r_v37.v37_paridad
	LET rm_rubros[i].valor     = r_v37.v37_valor
	IF rm_v36.v36_moneda IS NOT NULL THEN
		LET rm_rubros[i].valor_ml  = 
			fl_retorna_precision_valor(rm_v36.v36_moneda,
			r_v37.v37_valor * r_v37.v37_paridad)
	ELSE
		LET rm_rubros[i].valor_ml = r_v37.v37_valor * r_v37.v37_paridad
	END IF
	LET rm_v37[i].serial       = r_v37.v37_serial
	LET rm_v37[i].orden        = r_v37.v37_orden
	LET rm_v37[i].observacion  = r_v37.v37_observacion
	
	LET rm_rubros[i].check = 'N'

	LET i = i + 1
	IF i > 100 THEN
		EXIT FOREACH
	END IF
END FOREACH

LET i = i - 1 

RETURN i

END FUNCTION



FUNCTION ingresa_rubros()

DEFINE i 		SMALLINT
DEFINE j 		SMALLINT
DEFINE k 		SMALLINT
DEFINE salir		SMALLINT
DEFINE done 		SMALLINT
DEFINE resp		CHAR(6)
DEFINE mensaje		CHAR(40)
DEFINE flag		CHAR(1)

DEFINE total		LIKE veht037.v37_valor
DEFINE rubro		LIKE veht037.v37_codrubro

DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_g17		RECORD LIKE gent017.*
DEFINE r_v37		RECORD LIKE veht037.*

OPEN WINDOW w_212_2 AT 08,2 WITH 15 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER) 
OPEN FORM f_212_2 FROM '../forms/vehf212_2'
DISPLAY FORM f_212_2

LET i = lee_detalle()

LET total = 0
FOR j = 1 TO i
	LET total = total + rm_rubros[j].valor_ml
END FOR

-- Si el estado de la liquidacion es igual a 'P' o 
-- se esta ejecutando el programa en modo de solo consulta
-- no deben de modificarse los rubros
IF rm_v36.v36_estado = 'P' OR vm_numliq <> 0 THEN
	CALL set_count(i)
	DISPLAY ARRAY rm_rubros TO ra_rubros.*
		BEFORE DISPLAY
			CALL dialog.keysetlabel('ACCEPT', '')
		AFTER DISPLAY
			CONTINUE DISPLAY
		BEFORE ROW
			LET i = arr_curr()
			DISPLAY rm_v37[i].observacion TO n_rubro	
			DISPLAY total TO total_cargos
		ON KEY(INTERRUPT)
			EXIT DISPLAY
	END DISPLAY
	CLOSE WINDOW w_212_2
	RETURN 
END IF

LET salir = 0
WHILE NOT salir
LET j = 1
LET INT_FLAG = 0	
CALL set_count(i)
INPUT ARRAY rm_rubros WITHOUT DEFAULTS FROM ra_rubros.*
	ON KEY(INTERRUPT)
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
               		RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			EXIT INPUT 
		END IF
	ON KEY(F2)
		IF INFIELD(v37_codrubro) THEN
			CALL fl_ayuda_rubros() 
				RETURNING r_g17.g17_codrubro, 
					  r_g17.g17_nombre 
			IF r_g17.g17_codrubro IS NOT NULL THEN
				LET rm_rubros[i].rubro = r_g17.g17_codrubro
				DISPLAY r_g17.g17_codrubro 
					TO ra_rubros[j].v37_codrubro
				DISPLAY r_g17.g17_nombre TO n_rubro
			END IF
		END IF
		IF INFIELD(v37_moneda) THEN
			CALL fl_ayuda_monedas() 
				RETURNING r_mon.g13_moneda, r_mon.g13_nombre, 
					  r_mon.g13_decimales 
			IF r_mon.g13_moneda IS NOT NULL THEN
				LET rm_rubros[i].moneda = r_mon.g13_moneda
				DISPLAY r_mon.g13_moneda 
					TO ra_rubros[j].v37_moneda
			END IF	
		END IF
		LET INT_FLAG = 0
	BEFORE INPUT
		CALL dialog.keysetlabel('Insert', '')
		DISPLAY total TO total_cargos
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
		DISPLAY rm_v37[i].observacion TO n_rubro	
		LET total = 0
		FOR k = 1 TO arr_count()
			LET total = total + rm_rubros[k].valor_ml 
		END FOR
		DISPLAY total TO total_cargos
	BEFORE INSERT
		INITIALIZE rm_rubros[i].* TO NULL
		INITIALIZE rm_v37[i].* TO NULL
		LET rm_rubros[i].fecha = CURRENT
		LET rm_rubros[i].check = 'N'
		DISPLAY rm_rubros[i].* TO ra_rubros[j].*
	BEFORE DELETE
		CALL deleteRow(i, arr_count())
	AFTER  DELETE
		LET i = arr_count()
		EXIT INPUT
	BEFORE FIELD v37_codrubro
		LET rubro = rm_rubros[i].rubro
	AFTER FIELD v37_codrubro
		IF rm_rubros[i].rubro IS NULL THEN
			INITIALIZE rm_rubros[i].rubro, 
				   rm_rubros[i].indicador,
				   rm_rubros[i].base TO NULL
			CLEAR ra_rubros[j].v37_codrubro, 
		      	      ra_rubros[j].v37_indicador,
		      	      ra_rubros[j].v37_base 
			CONTINUE INPUT          
		ELSE
			CALL fl_lee_rubro_liquidacion(rm_rubros[i].rubro)
				RETURNING r_g17.*
			IF r_g17.g17_codrubro IS NULL THEN
				INITIALIZE rm_rubros[i].rubro, 
				   	   rm_rubros[i].indicador,
				   	   rm_rubros[i].base TO NULL
				CLEAR ra_rubros[j].v37_codrubro, 
		      	      	      ra_rubros[j].v37_indicador,
		      	      	      ra_rubros[j].v37_base 
				NEXT FIELD v37_codrubro
			END IF
			LET rm_rubros[i].rubro     = r_g17.g17_codrubro
			LET rm_rubros[i].indicador = r_g17.g17_indicador
			LET rm_rubros[i].base      = r_g17.g17_base
			LET rm_v37[i].orden        = r_g17.g17_orden
			IF rm_v37[i].observacion IS NULL 
			OR rubro <> rm_rubros[i].rubro THEN
				LET rm_v37[i].observacion  = r_g17.g17_nombre
			END IF
			DISPLAY rm_rubros[i].* TO ra_rubros[j].*
			DISPLAY rm_v37[i].observacion TO n_rubro
		END IF
	AFTER FIELD v37_moneda
		IF rm_rubros[i].moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_rubros[i].moneda) 
				RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN	
				CALL FGL_WINMESSAGE(vg_producto, 
                             		            'Moneda no existe',        
                                        	    'exclamation')
				NEXT FIELD v37_moneda
			ELSE
				IF r_mon.g13_estado = 'B' THEN
					CALL FGL_WINMESSAGE(vg_producto, 
                            		 	            'Moneda está ' ||
                               	                            'bloqueada',        
                                       	                    'exclamation')
					NEXT FIELD v37_moneda
				ELSE
					LET rm_rubros[i].paridad = 
						calcula_paridad(
							rm_rubros[i].moneda,
							rm_v36.v36_moneda)
					IF rm_rubros[i].paridad IS NULL THEN
						LET rm_rubros[i].moneda =
							rg_gen.g00_moneda_base
					END IF	
					IF rm_v36.v36_moneda IS NOT NULL THEN
						LET rm_rubros[i].valor_ml  = 
						fl_retorna_precision_valor(
							rm_v36.v36_moneda,
							rm_rubros[i].valor * 
							rm_rubros[i].paridad
						)
					ELSE
						LET rm_rubros[i].valor_ml = 
							rm_rubros[i].valor * 
							rm_rubros[i].paridad
					END IF
					DISPLAY rm_rubros[i].* 
						TO ra_rubros[j].*
				END IF
			END IF 
		ELSE
			NEXT FIELD v37_moneda
		END IF
	AFTER FIELD v37_valor
		IF rm_rubros[i].valor IS NULL THEN
			CONTINUE INPUT
		END IF
		LET rm_rubros[i].valor = fl_retorna_precision_valor(
						rm_rubros[i].moneda,
						rm_rubros[i].valor)
		IF rm_v36.v36_moneda IS NOT NULL THEN
			LET rm_rubros[i].valor_ml  = 
				fl_retorna_precision_valor(rm_v36.v36_moneda,
				rm_rubros[i].valor * rm_rubros[i].paridad)
		ELSE
			LET rm_rubros[i].valor_ml = 
				rm_rubros[i].valor * rm_rubros[i].paridad
		END IF						
		DISPLAY rm_rubros[i].* TO ra_rubros[i].*
		LET total = 0
		FOR k = 1 TO arr_count()
			LET total = total + rm_rubros[k].valor_ml
		END FOR
		DISPLAY total TO total_cargos
	BEFORE FIELD check
		CALL mas_datos(i)	
		LET rm_rubros[i].check = 'N'
		DISPLAY rm_rubros[i].check TO ra_rubros[j].check	
		NEXT FIELD NEXT
	AFTER INPUT
		LET k = arr_count()
		LET salir = 1
END INPUT
IF INT_FLAG THEN
	CLOSE WINDOW w_212_2
	RETURN 
END IF

END WHILE

BEGIN WORK

DECLARE q_rubro CURSOR FOR
	SELECT * FROM veht037
		WHERE v37_compania  = vg_codcia
		  AND v37_localidad = vg_codloc
		  AND v37_numliq    = rm_v36.v36_numliq
		ORDER BY v37_fecha, v37_orden

LET i = 1
FOREACH q_rubro INTO r_v37.*
	INITIALIZE flag TO NULL
	LET j = i
	IF r_v37.v37_serial = rm_v37[i].serial THEN
		LET flag = 'U'
		LET i = i + 1
	ELSE
		LET flag = 'D'
	END IF
	IF flag IS NOT NULL THEN
		LET done = actualiza_detalle_liq(j, flag, r_v37.v37_serial)
		IF NOT done THEN
			ROLLBACK WORK
			CLOSE WINDOW w_212_2
			RETURN
		END IF
		CONTINUE FOREACH
	END IF
END FOREACH 

WHILE (i <= k)
	LET r_v37.v37_compania    = vg_codcia
	LET r_v37.v37_localidad   = vg_codloc
	LET r_v37.v37_numliq      = rm_v36.v36_numliq
	LET r_v37.v37_serial      = 0
	LET r_v37.v37_codrubro    = rm_rubros[i].rubro
	LET r_v37.v37_indicador   = rm_rubros[i].indicador
	LET r_v37.v37_base        = rm_rubros[i].base
	LET r_v37.v37_moneda      = rm_rubros[i].moneda
	LET r_v37.v37_paridad     = rm_rubros[i].paridad
	LET r_v37.v37_valor       = rm_rubros[i].valor
	LET r_v37.v37_orden	  = rm_v37[i].orden
	LET r_v37.v37_observacion = rm_v37[i].observacion 
	LET r_v37.v37_fecha       = rm_rubros[i].fecha

	INSERT INTO veht037 VALUES (r_v37.*)

	LET i = i + 1
END WHILE

LET done = actualiza_cabecera_liq()
IF NOT done THEN
	ROLLBACK WORK
	CLOSE WINDOW w_212_2
	RETURN
END IF

COMMIT WORK

CLOSE WINDOW w_212_2

RETURN 

END FUNCTION



FUNCTION deleteRow(i, num_rows)

DEFINE i		SMALLINT
DEFINE num_rows		SMALLINT

WHILE (i < num_rows)
	LET rm_v37[i].* = rm_v37[i + 1].*
	LET i = i + 1
END WHILE
INITIALIZE rm_v37[i].* TO NULL

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



FUNCTION actualiza_detalle_liq(i, flag, serial)

DEFINE flag		CHAR(1)
DEFINE i 		SMALLINT
DEFINE serial		LIKE veht037.v37_serial

DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT

DEFINE r_v37		RECORD LIKE veht037.*

INITIALIZE r_v37.* TO NULL
LET intentar = 1
LET done = 0
WHILE (intentar)
	INITIALIZE r_v37.* TO NULL
	WHENEVER ERROR CONTINUE
		DECLARE q_updet CURSOR FOR
			SELECT * FROM veht037
				WHERE v37_compania  = vg_codcia
				  AND v37_localidad = vg_codloc
				  AND v37_numliq    = rm_v36.v36_numliq
				  AND v37_serial    = serial
			FOR UPDATE
	OPEN q_updet
	FETCH q_updet INTO r_v37.*
	WHENEVER ERROR STOP
	IF STATUS < 0 THEN
		LET intentar = mensaje_intentar()
		CLOSE q_updet
		FREE  q_updet
	ELSE
		LET intentar = 0
		LET done = 1
	END IF
END WHILE

IF NOT intentar AND NOT done THEN
	RETURN done
END IF

CASE flag
	WHEN 'U' 
		LET r_v37.v37_codrubro    = rm_rubros[i].rubro
		LET r_v37.v37_indicador   = rm_rubros[i].indicador
		LET r_v37.v37_base        = rm_rubros[i].base
		LET r_v37.v37_moneda      = rm_rubros[i].moneda
		LET r_v37.v37_paridad     = rm_rubros[i].paridad
		LET r_v37.v37_valor       = rm_rubros[i].valor
		LET r_v37.v37_orden	  = rm_v37[i].orden
		LET r_v37.v37_observacion = rm_v37[i].observacion 
		
		UPDATE veht037 SET * = r_v37.* WHERE CURRENT OF q_updet 
	WHEN 'D'
		DELETE FROM veht037 WHERE CURRENT OF q_updet
END CASE
CLOSE q_updet
FREE  q_updet
RETURN done

END FUNCTION



FUNCTION actualiza_cabecera_liq()

DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT

DEFINE r_v34		RECORD LIKE veht034.*
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
	OPEN q_v36  
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

	SELECT SUM(v37_valor * v37_paridad) INTO r_v36.v36_tot_cargos
		FROM veht037
		WHERE v37_compania  = vg_codcia
		  AND v37_localidad = vg_codloc
		  AND v37_numliq    = r_v36.v36_numliq 
	IF r_v36.v36_tot_cargos IS NULL THEN
		LET r_v36.v36_tot_cargos = 0.0
	END IF
	LET r_v36.v36_tot_cargos = fl_retorna_precision_valor(
					r_v36.v36_moneda,
					r_v36.v36_tot_cargos)
	SELECT SUM(v35_flete) INTO r_v36.v36_flete
		FROM veht035
		WHERE v35_compania   = vg_codcia
		  AND v35_localidad  = vg_codloc
		  AND v35_pedido     = rm_v36.v36_pedido
		  AND v35_numero_liq = rm_v36.v36_numliq
	IF r_v36.v36_flete IS NULL THEN
		LET r_v36.v36_flete = 0.0
	END IF
	LET r_v36.v36_flete = fl_retorna_precision_valor(r_v36.v36_moneda,
							 r_v36.v36_flete)	
	SELECT (v36_fob_fabrica + v36_inland + v36_otros) 
		INTO r_v36.v36_total_fob
		FROM veht036
		WHERE v36_compania  = vg_codcia
		  AND v36_localidad = vg_codloc
		  AND v36_numliq    = r_v36.v36_numliq 
	LET r_v36.v36_total_fob = r_v36.v36_total_fob + r_v36.v36_flete
	LET r_v36.v36_total_fob = fl_retorna_precision_valor(r_v36.v36_moneda,
							r_v36.v36_total_fob)	
	UPDATE veht036 SET * = r_v36.* WHERE CURRENT OF q_v36   
CLOSE q_v36  
FREE  q_v36  
RETURN done

END FUNCTION



FUNCTION actualiza_estado_pedido(estado)

DEFINE estado 		LIKE veht034.v34_estado

DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT

DEFINE r_v34		RECORD LIKE veht034.*

LET intentar = 1
LET done = 0
WHILE (intentar)
	INITIALIZE r_v34.* TO NULL
	WHENEVER ERROR CONTINUE
		DECLARE q_cab CURSOR FOR
			SELECT * FROM veht034
				WHERE v34_compania   = vg_codcia
				  AND v34_localidad = vg_codloc
				  AND v34_pedido    = rm_v36.v36_pedido
			FOR UPDATE
	OPEN q_cab  
	FETCH q_cab INTO r_v34.*
	WHENEVER ERROR STOP
	IF STATUS < 0 THEN
		LET intentar = mensaje_intentar()
		CLOSE q_cab
		FREE  q_cab
	ELSE
		LET intentar = 0
		LET done = 1
	END IF
END WHILE

IF NOT intentar AND NOT done THEN
	RETURN done
END IF

	LET r_v34.v34_estado = estado                   

	UPDATE veht034 SET * = r_v34.* WHERE CURRENT OF q_cab   
CLOSE q_cab  
FREE  q_cab
RETURN done

END FUNCTION



FUNCTION actualiza_detalles_pedido(estado_ori, estado_dest, numliq)

DEFINE estado_ori	LIKE veht035.v35_estado
DEFINE estado_dest	LIKE veht035.v35_estado
DEFINE numliq		LIKE veht035.v35_numero_liq

DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT

DEFINE r_v35		RECORD LIKE veht035.*

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
				  AND v35_estado    = estado_ori
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
	LET r_v35.v35_estado = estado_dest           
	LET r_v35.v35_numero_liq = numliq
	UPDATE veht035 SET * = r_v35.* WHERE CURRENT OF q_v35   

	INITIALIZE r_v35.* TO NULL
	FETCH q_v35 INTO r_v35.*
END WHILE    
CLOSE q_v35
FREE  q_v35
RETURN done

END FUNCTION



FUNCTION actualiza_flete(r_v35, flete)

DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT

DEFINE flete		LIKE veht035.v35_flete

DEFINE r_upd		RECORD LIKE veht035.*
DEFINE r_v35		RECORD LIKE veht035.*

LET intentar = 1
LET done = 0
WHILE (intentar)
	INITIALIZE r_upd.* TO NULL
	WHENEVER ERROR CONTINUE
		DECLARE q_upd_flete CURSOR FOR
			SELECT * FROM veht035
				WHERE v35_compania  = r_v35.v35_compania
				  AND v35_localidad = r_v35.v35_localidad
				  AND v35_pedido    = r_v35.v35_pedido 
				  AND v35_secuencia = r_v35.v35_secuencia
			FOR UPDATE
	OPEN  q_upd_flete
	FETCH q_upd_flete INTO r_upd.*
	WHENEVER ERROR STOP
	IF STATUS < 0 THEN
		LET intentar = mensaje_intentar()
		CLOSE q_upd_flete
		FREE  q_upd_flete
	ELSE
		LET intentar = 0
		LET done = 1
	END IF
END WHILE

IF NOT intentar AND NOT done THEN
	RETURN done
END IF

WHILE (STATUS <> NOTFOUND)
	LET r_upd.v35_flete = flete    

	UPDATE veht035 SET * = r_upd.* WHERE CURRENT OF q_upd_flete   
	
	INITIALIZE r_upd.* TO NULL
	FETCH q_upd_flete INTO r_upd.*
END WHILE    
CLOSE q_upd_flete
FREE  q_upd_flete
RETURN done

END FUNCTION



FUNCTION mas_datos(i)

DEFINE i		SMALLINT

DEFINE r_g13		RECORD LIKE gent013.*

OPTIONS 
	INPUT NO WRAP

OPEN WINDOW w_212_3 AT 10,20 WITH 05 ROWS, 50 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER) 
OPEN FORM f_212_3 FROM '../forms/vehf212_3'
DISPLAY FORM f_212_3

CALL fl_lee_moneda(rm_rubros[i].moneda) RETURNING r_g13.*
DISPLAY rm_rubros[i].moneda TO v37_moneda
DISPLAY r_g13.g13_nombre TO n_moneda

LET INT_FLAG = 0
INPUT rm_v37[i].observacion WITHOUT DEFAULTS FROM v37_observacion
IF INT_FLAG THEN
	CLOSE WINDOW w_212_3
	RETURN
END IF

CLOSE WINDOW w_212_3

END FUNCTION



FUNCTION lee_datos(flag)

DEFINE flag 		CHAR(1)
DEFINE resp 		CHAR(6)

DEFINE contador 	SMALLINT

DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_g14		RECORD LIKE gent014.*
DEFINE r_v34		RECORD LIKE veht034.*
DEFINE r_v02		RECORD LIKE veht002.*

LET INT_FLAG = 0
INPUT BY NAME rm_v36.v36_pedido, rm_v36.v36_estado, rm_v36.v36_origen, 
              rm_v36.v36_forma_pago, rm_v36.v36_descripcion, rm_v36.v36_bodega, 
              rm_v36.v36_num_pi, rm_v36.v36_guia, rm_v36.v36_pedimento, 
              rm_v36.v36_fecha_lleg, rm_v36.v36_fecha_ing, rm_v36.v36_moneda,
	      rm_v36.v36_paridad_mb, rm_v36.v36_fob_fabrica, rm_v36.v36_inland,
              rm_v36.v36_flete, rm_v36.v36_otros, rm_v36.v36_total_fob, 
              rm_v36.v36_seguro, rm_v36.v36_tot_cargos, rm_v36.v36_margen_uti, 
              rm_v36.v36_elaborado, rm_v36.v36_usuario, rm_v36.v36_fecing 
 	WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(v36_pedido, v36_origen, 
                		     v36_forma_pago, v36_descripcion, 
                		     v36_num_pi, v36_guia, v36_pedimento, 
			             v36_fecha_lleg, v36_fecha_ing, v36_moneda,
		                     v36_paridad_mb,  
		                     v36_fob_fabrica, v36_inland, v36_flete,
		                     v36_otros, v36_total_fob, v36_seguro,
				     v36_tot_cargos, 
				     v36_margen_uti, v36_elaborado
                                    ) THEN
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
		IF INFIELD(v36_bodega) THEN
			CALL fl_ayuda_bodegas_veh(vg_codcia) 
				RETURNING r_v02.v02_bodega, r_v02.v02_nombre 
			IF r_v02.v02_bodega IS NOT NULL THEN
				LET rm_v36.v36_bodega = r_v02.v02_bodega
				DISPLAY BY NAME rm_v36.v36_bodega
				DISPLAY r_v02.v02_nombre TO n_bodega
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
	BEFORE FIELD v36_pedido
		IF flag = 'M' THEN 
			NEXT FIELD v36_origen
		END IF
	AFTER FIELD v36_pedido
		IF rm_v36.v36_pedido IS NULL THEN
			INITIALIZE rm_v36.v36_fecha_lleg TO NULL
			LET rm_v36.v36_fob_fabrica = 0.0
			DISPLAY BY NAME rm_v36.v36_fob_fabrica,
				        rm_v36.v36_total_fob,
					rm_v36.v36_fecha_lleg
			CONTINUE INPUT
		END IF
		IF rm_v36.v36_pedido IS NOT NULL THEN
			CALL fl_lee_pedido_veh(vg_codcia, 
					       vg_codloc, 
      					       rm_v36.v36_pedido)
							RETURNING r_v34.*
			IF r_v34.v34_pedido IS NULL THEN
				CALL fgl_winmessage(vg_producto, 
						    'Pedido no existe',
        					    'exclamation')
				INITIALIZE rm_v36.v36_fecha_lleg TO NULL
				LET rm_v36.v36_fob_fabrica = 0.0
				DISPLAY BY NAME rm_v36.v36_fob_fabrica,
					        rm_v36.v36_total_fob,
						rm_v36.v36_fecha_lleg
				NEXT FIELD v36_pedido
			ELSE
				IF r_v34.v34_estado = 'L' OR 
				   r_v34.v34_estado = 'P' 
				THEN
					CALL fgl_winmessage(vg_producto,
       							    'No se puede ' ||
							    'liquidar este '||
     							    'pedido',
							    'exclamation')
					INITIALIZE rm_v36.v36_fecha_lleg TO NULL
					LET rm_v36.v36_fob_fabrica = 0.0
					DISPLAY BY NAME rm_v36.v36_fob_fabrica,
					                rm_v36.v36_total_fob,
							rm_v36.v36_fecha_lleg
					NEXT FIELD v36_pedido	
				END IF
				SELECT COUNT(*) INTO contador
					FROM veht035
					WHERE v35_compania  = vg_codcia
				  	  AND v35_localidad = vg_codloc
				  	  AND v35_pedido    = rm_v36.v36_pedido
					  AND v35_estado IN ('R', 'L')
				IF contador = 0 THEN
					CALL fgl_winmessage(vg_producto, 
							    'No existen ' ||
							    'vehículos ' ||
							    'recibidos ' ||
							    'ni liquidados ' ||
							    'en el pedido',
        						    'exclamation')
					INITIALIZE rm_v36.v36_fecha_lleg TO NULL
					LET rm_v36.v36_fob_fabrica = 0.0
					DISPLAY BY NAME rm_v36.v36_fob_fabrica,
					                rm_v36.v36_total_fob,
							rm_v36.v36_fecha_lleg
					NEXT FIELD v36_pedido
				ELSE
					SELECT SUM(v35_precio_unit)
						INTO rm_v36.v36_fob_fabrica
						FROM veht035
						WHERE v35_compania = vg_codcia
						  AND v35_localidad = vg_codloc
						  AND v35_pedido = 
							rm_v36.v36_pedido
						  AND v35_estado IN ('R', 'L') 
					LET rm_v36.v36_fob_fabrica =
						calcula_paridad(
							r_v34.v34_moneda,
							rm_v36.v36_moneda) *
					                rm_v36.v36_fob_fabrica
					IF rm_v36.v36_fob_fabrica IS NULL THEN
						LET rm_v36.v36_fob_fabrica = 0.0
					END IF
					LET rm_v36.v36_total_fob = 
						rm_v36.v36_fob_fabrica +
					   	rm_v36.v36_inland +
					   	rm_v36.v36_flete  +
					   	rm_v36.v36_otros
					DISPLAY BY NAME rm_v36.v36_total_fob
					DISPLAY BY NAME rm_v36.v36_fob_fabrica
					LET rm_v36.v36_fecha_lleg  = 
						r_v34.v34_fec_llegada
					DISPLAY BY NAME rm_v36.v36_fecha_lleg
				END IF	
			END IF
		END IF
	AFTER FIELD v36_bodega
		IF rm_v36.v36_bodega IS NOT NULL THEN
			CALL fl_lee_bodega_veh(vg_codcia, rm_v36.v36_bodega)
				RETURNING r_v02.*
			IF r_v02.v02_bodega IS NOT NULL THEN
				IF r_v02.v02_estado <> 'B' THEN
					DISPLAY r_v02.v02_nombre TO n_bodega
				ELSE
					CALL fgl_winmessage(vg_producto,
						            'Bodega está ' ||
                                                            'bloqueada',
							    'exclamation')
					CLEAR n_bodega 
					NEXT FIELD v36_bodega
				END IF
			ELSE
				CALL fgl_winmessage(vg_producto,
					            'Bodega no existe',
						    'exclamation')
				CLEAR n_bodega
				NEXT FIELD v36_bodega
			END IF
		ELSE
			CLEAR n_bodega
		END IF		 
	AFTER FIELD v36_moneda
		IF rm_v36.v36_moneda IS NULL THEN
			CLEAR n_moneda
		ELSE
			CALL fl_lee_moneda(rm_v36.v36_moneda) RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN	
				CALL FGL_WINMESSAGE(vg_producto, 
                             		            'Moneda no existe',        
                                        	    'exclamation')
				CLEAR n_moneda
				NEXT FIELD v36_moneda
			ELSE
				IF r_mon.g13_estado = 'B' THEN
					CALL FGL_WINMESSAGE(vg_producto, 
                            		 	            'Moneda está ' ||
                               	                            'bloqueada',        
                                       	                    'exclamation')
					CLEAR n_moneda
					NEXT FIELD v36_moneda
				ELSE
					DISPLAY r_mon.g13_nombre TO n_moneda
					
					LET rm_v36.v36_paridad_mb =
						calcula_paridad(
							rm_v36.v36_moneda,
							rg_gen.g00_moneda_base)
					IF rm_v36.v36_paridad_mb IS NULL THEN
						LET rm_v36.v36_moneda =
							rg_gen.g00_moneda_base
						DISPLAY BY NAME 
							rm_v36.v36_moneda
						LET rm_v36.v36_paridad_mb =
							calcula_paridad(
						   	      rm_v36.v36_moneda,							      rg_gen.g00_moneda_base)
					END IF
					DISPLAY BY NAME rm_v36.v36_paridad_mb
					CALL muestra_etiquetas()
				END IF
			END IF 
		END IF
	AFTER FIELD v36_inland     
		LET rm_v36.v36_inland =
			fl_retorna_precision_valor(rm_v36.v36_moneda,
						   rm_v36.v36_inland)
		DISPLAY BY NAME rm_v36.v36_inland
		LET rm_v36.v36_total_fob = rm_v36.v36_fob_fabrica +
					   rm_v36.v36_inland +
					   rm_v36.v36_flete  +
					   rm_v36.v36_otros
		DISPLAY BY NAME rm_v36.v36_total_fob
	AFTER FIELD v36_otros       
		LET rm_v36.v36_otros =
			fl_retorna_precision_valor(rm_v36.v36_moneda,
						   rm_v36.v36_otros)
		DISPLAY BY NAME rm_v36.v36_otros 
		LET rm_v36.v36_total_fob = rm_v36.v36_fob_fabrica +
					   rm_v36.v36_inland +
					   rm_v36.v36_flete  +
					   rm_v36.v36_otros
		DISPLAY BY NAME rm_v36.v36_total_fob
	AFTER INPUT 
		SELECT SUM(v37_valor * v37_paridad) INTO rm_v36.v36_tot_cargos
			FROM veht037
			WHERE v37_compania  = vg_codcia
			  AND v37_localidad = vg_codloc
			  AND v37_numliq    = rm_v36.v36_numliq 
		IF rm_v36.v36_tot_cargos IS NULL THEN
			LET rm_v36.v36_tot_cargos = 0.0
		END IF
		LET rm_v36.v36_tot_cargos =
			fl_retorna_precision_valor(rm_v36.v36_moneda,
						   rm_v36.v36_tot_cargos)
		DISPLAY BY NAME rm_v36.v36_tot_cargos
END INPUT

END FUNCTION



FUNCTION control_consulta()

DEFINE expr_sql			VARCHAR(500)
DEFINE query			VARCHAR(600)

DEFINE r_v02		RECORD LIKE veht002.*
DEFINE r_v34		RECORD LIKE veht034.*
DEFINE r_v36		RECORD LIKE veht036.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_g14		RECORD LIKE gent014.*

CLEAR FORM

LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql 
        ON v36_numliq,      v36_pedido, v36_estado, v36_origen, v36_forma_pago, 
	   v36_descripcion, v36_bodega, v36_num_pi, v36_guia,   v36_pedimento, 
	   v36_fecha_lleg,  v36_fecha_ing, v36_moneda, v36_paridad_mb,  
           v36_fob_fabrica, v36_inland, v36_flete, v36_otros, 
           v36_total_fob,   v36_seguro, v36_tot_cargos, 
	   v36_margen_uti,  v36_elaborado, v36_usuario
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
		IF INFIELD(v36_bodega) THEN
			CALL fl_ayuda_bodegas_veh(vg_codcia) 
				RETURNING r_v02.v02_bodega, r_v02.v02_nombre 
			IF r_v02.v02_bodega IS NOT NULL THEN
				LET rm_v36.v36_bodega = r_v02.v02_bodega
				DISPLAY BY NAME rm_v36.v36_bodega
				DISPLAY r_v02.v02_nombre TO n_bodega
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
	AFTER FIELD v36_bodega
		LET rm_v36.v36_bodega = GET_FLDBUF(v36_bodega)
		IF rm_v36.v36_bodega IS NOT NULL THEN
			CALL fl_lee_bodega_veh(vg_codcia, rm_v36.v36_bodega)
				RETURNING r_v02.*
			IF r_v02.v02_bodega IS NOT NULL THEN
				IF r_v02.v02_estado <> 'B' THEN
					DISPLAY r_v02.v02_nombre TO n_bodega
				ELSE
					CLEAR n_bodega 
				END IF
			ELSE
				CLEAR n_bodega
			END IF
		ELSE
			CLEAR n_bodega
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
	    ' 	  AND ', expr_sql, 
            ' ORDER BY 3' 

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
		rm_v36.v36_descripcion,
		rm_v36.v36_bodega,
		rm_v36.v36_origen,     
		rm_v36.v36_forma_pago,
		rm_v36.v36_num_pi,
		rm_v36.v36_guia,
		rm_v36.v36_pedimento,
		rm_v36.v36_fecha_lleg,
		rm_v36.v36_fecha_ing,
		rm_v36.v36_moneda,
		rm_v36.v36_fob_fabrica,
		rm_v36.v36_inland,
		rm_v36.v36_flete,
		rm_v36.v36_otros,
		rm_v36.v36_total_fob,
		rm_v36.v36_seguro,
		rm_v36.v36_tot_cargos,
		rm_v36.v36_margen_uti,
		rm_v36.v36_elaborado,
		rm_v36.v36_paridad_mb,
		rm_v36.v36_usuario,
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
DEFINE r_v02			RECORD LIKE veht002.*

CASE rm_v36.v36_estado
	WHEN 'A' LET nom_estado = 'ACTIVO'
	WHEN 'P' LET nom_estado = 'PROCESADO'
	WHEN 'E' LET nom_estado = 'ELIMINADO'
END CASE
DISPLAY nom_estado   TO n_estado

CALL fl_lee_moneda(rm_v36.v36_moneda) RETURNING r_g13.*
DISPLAY r_g13.g13_nombre TO n_moneda

CALL fl_lee_bodega_veh(vg_codcia, rm_v36.v36_bodega) RETURNING r_v02.*
DISPLAY r_v02.v02_nombre TO n_bodega
	
END FUNCTION



FUNCTION control_eliminacion()

DEFINE resp 		CHAR(6)
DEFINE r_v35		RECORD LIKE veht035.*

DEFINE done		SMALLINT

IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

IF rm_v36.v36_estado = 'P' THEN
	CALL fgl_winmessage(vg_producto,
			    'Esta liquidacion ya fue cerrada y no puede ser' ||	
                            ' eliminada',
			    'exclamation')
	RETURN
END IF

IF rm_v36.v36_estado = 'E' THEN
	CALL fgl_winmessage(vg_producto,
			    'Esta liquidacion ya fue eliminada.',	
			    'exclamation')
	RETURN
END IF

BEGIN WORK

CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
IF resp = 'Yes' THEN
	CALL lee_muestra_registro(vm_rows[vm_row_current])

	WHENEVER ERROR CONTINUE
	DECLARE q_del_v36 CURSOR FOR 
		SELECT * FROM veht036 WHERE ROWID = vm_rows[vm_row_current]
		FOR UPDATE
	OPEN  q_del_v36
	FETCH q_del_v36 INTO rm_v36.*
	WHENEVER ERROR STOP
	IF STATUS < 0 THEN
		CALL fl_mensaje_bloqueo_otro_usuario()
		ROLLBACK WORK
		RETURN
	END IF  

	DECLARE q_del_v35 CURSOR FOR
        	SELECT * FROM veht035, veht022
                WHERE v35_compania   = vg_codcia 
                  AND v35_localidad  = vg_codloc
                  AND v35_pedido     = rm_v36.v36_pedido
                  AND v35_estado IN ('L', 'P')
		  AND v35_numero_liq = rm_v36.v36_numliq
                  AND v35_codigo_veh = v22_codigo_veh

	FOREACH q_del_v35 INTO r_v35.* 
		LET done = actualiza_flete(r_v35.*, 0)
	END FOREACH
	LET done = actualiza_detalles_pedido('L', 'R', NULL)
	LET done = actualiza_estado_pedido('R')

	UPDATE veht036 SET v36_estado = 'E' WHERE CURRENT OF q_del_v36

	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	ELSE
		CLEAR FORM
	END IF
	CALL fgl_winmessage(vg_producto,
			    'Registro eliminado Ok.',
			    'exclamation')
END IF

COMMIT WORK
FREE q_del_v35
FREE q_del_v36

END FUNCTION



FUNCTION execute_query()

LET vm_num_rows = 1
LET vm_row_current = 1

SELECT ROWID INTO vm_rows[vm_num_rows]
	FROM veht036
	WHERE v36_compania  = vg_codcia
	  AND v36_localidad = vg_codloc
	  AND v36_numliq    = vm_numliq
IF STATUS = NOTFOUND THEN
	CALL fgl_winmessage(vg_producto, 'Liquidación no existe', 'exclamation')
	EXIT PROGRAM
ELSE
	CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION ingresa_fletes()

DEFINE i 		SMALLINT
DEFINE j 		SMALLINT
DEFINE salir		SMALLINT
DEFINE done 		SMALLINT
DEFINE resp		CHAR(6)
DEFINE mensaje		CHAR(40)

DEFINE total		LIKE veht035.v35_flete       

DEFINE r_fletes ARRAY[100] OF RECORD
	modelo		LIKE veht035.v35_modelo,
	chasis		LIKE veht022.v22_chasis,
	precio_unit	LIKE veht035.v35_precio_unit,
	flete		LIKE veht035.v35_flete
END RECORD
DEFINE sec_flete ARRAY[100] OF SMALLINT

DEFINE r_v35		RECORD LIKE veht035.*

OPEN WINDOW w_212_4 AT 07,2 WITH 17 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER) 
OPEN FORM f_212_4 FROM '../forms/vehf212_4'
DISPLAY FORM f_212_4

DECLARE q_flete CURSOR FOR
        SELECT v35_secuencia, v35_modelo, v22_chasis, v35_precio_unit, v35_flete
                FROM veht035, veht022
                WHERE v35_compania   = vg_codcia 
                  AND v35_localidad  = vg_codloc
                  AND v35_pedido     = rm_v36.v36_pedido
                  AND v35_estado IN ('L', 'P')
		  AND v35_numero_liq = rm_v36.v36_numliq
                  AND v35_codigo_veh = v22_codigo_veh

LET total = 0
LET i = 1
FOREACH q_flete INTO sec_flete[i], r_fletes[i].*
	LET total = total + r_fletes[i].flete
	LET i = i + 1
	IF i > 100 THEN
		EXIT FOREACH
	END IF
END FOREACH
LET i = i - 1

IF i = 0 THEN
	CLOSE WINDOW w_212_4
	RETURN
END IF

-- Si el estado de la liquidacion es igual a 'P' o 
-- se esta ejecutando el programa en modo de solo consulta
-- no deben de modificarse los rubros
IF rm_v36.v36_estado = 'P' OR vm_numliq <> 0 THEN
	CALL set_count(i)
	DISPLAY ARRAY r_fletes TO ra_fletes.*
		BEFORE DISPLAY
			CALL dialog.keysetlabel('ACCEPT', '')
		AFTER DISPLAY
			CONTINUE DISPLAY
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		BEFORE ROW  
			DISPLAY total TO total_flete
	END DISPLAY
	CLOSE WINDOW w_212_4
	RETURN 
END IF

LET salir = 0
WHILE NOT salir
LET j = 1
LET INT_FLAG = 0	
CALL set_count(i)
INPUT ARRAY r_fletes WITHOUT DEFAULTS FROM ra_fletes.*
	ON KEY(INTERRUPT)
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
               		RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			EXIT INPUT 
		END IF
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
	BEFORE INPUT
		CALL dialog.keysetlabel('INSERT', '')
		CALL dialog.keysetlabel('DELETE', '')
		DISPLAY total TO total_flete
	BEFORE INSERT
		IF i = arr_count() THEN
			LET i = arr_count() - 1
		ELSE
			LET i = arr_count()
		END IF
		EXIT INPUT
	BEFORE DELETE
		LET i = arr_count()
		EXIT INPUT
	AFTER FIELD v35_flete
		IF r_fletes[i].flete IS NOT NULL THEN
			LET r_fletes[i].flete =
				fl_retorna_precision_valor(rm_v36.v36_moneda,
							   r_fletes[i].flete)
			LET total = 0
			FOR i = 1 TO arr_count()
				LET total = total + r_fletes[i].flete
			END FOR
			DISPLAY total TO total_flete
		END IF
	AFTER INPUT
		LET i = arr_count()
		LET salir = 1
END INPUT
IF INT_FLAG THEN
	CLOSE WINDOW w_212_4
	RETURN 
END IF

END WHILE

BEGIN WORK

LET r_v35.v35_compania  = vg_codcia
LET r_v35.v35_localidad = vg_codloc
LET r_v35.v35_pedido    = rm_v36.v36_pedido
 
LET j = i
FOR i = 1 TO j
	LET r_v35.v35_secuencia = sec_flete[i]
	LET done = actualiza_flete(r_v35.*, r_fletes[i].flete)
	IF NOT done THEN
		ROLLBACK WORK 
		CLOSE WINDOW w_212_4
		RETURN
	END IF
END FOR 

LET done = 0
LET done = actualiza_cabecera_liq()
IF NOT done THEN
	ROLLBACK WORK
	CLOSE WINDOW w_212_4
	RETURN
END IF

COMMIT WORK

LET rm_v36.v36_flete = total

CLOSE WINDOW w_212_4

RETURN 

END FUNCTION



FUNCTION mostrar_unidades()

DEFINE i 		SMALLINT
DEFINE j 		SMALLINT
DEFINE salir		SMALLINT
DEFINE done 		SMALLINT
DEFINE resp		CHAR(6)
DEFINE mensaje		CHAR(40)

DEFINE r_v05		RECORD LIKE veht005.*

DEFINE r_unid ARRAY[100] OF RECORD
	modelo		LIKE veht035.v35_modelo,
	chasis		LIKE veht022.v22_chasis,
	color		LIKE veht035.v35_cod_color,
	precio_unit	LIKE veht035.v35_precio_unit 
END RECORD

DEFINE r_v35		RECORD LIKE veht035.*

OPEN WINDOW w_212_5 AT 06,2 WITH 17 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER) 
OPEN FORM f_212_5 FROM '../forms/vehf212_5'
DISPLAY FORM f_212_5

DECLARE q_unid CURSOR FOR
        SELECT v35_modelo, v22_chasis, v35_cod_color, v35_precio_unit
                FROM veht035, veht022
                WHERE v35_compania   = vg_codcia 
                  AND v35_localidad  = vg_codloc
                  AND v35_pedido     = rm_v36.v36_pedido
                  AND v35_estado IN ('L', 'P')
		  AND v35_numero_liq = rm_v36.v36_numliq
                  AND v35_codigo_veh = v22_codigo_veh

LET i = 1
FOREACH q_unid INTO r_unid[i].*
	LET i = i + 1
	IF i > 100 THEN
		EXIT FOREACH
	END IF
END FOREACH
LET i = i - 1

IF i = 0 THEN
	CLOSE WINDOW w_212_5
	RETURN
END IF

CALL set_count(i)
DISPLAY ARRAY r_unid TO ra_unid.*
	BEFORE DISPLAY
		CALL dialog.keysetlabel('ACCEPT', '')
	AFTER DISPLAY
		CONTINUE DISPLAY
	ON KEY(INTERRUPT)
		EXIT DISPLAY
	BEFORE ROW
		LET i = arr_curr()
		CALL fl_lee_color_veh(vg_codcia, r_unid[i].color) 
			RETURNING r_v05.*
		DISPLAY r_v05.v05_descri_base TO n_color
END DISPLAY

CLOSE WINDOW w_212_5
RETURN 

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
