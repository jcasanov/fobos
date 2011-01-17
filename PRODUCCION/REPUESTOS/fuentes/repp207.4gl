{*
 * Titulo           : repp207.4gl - Liquidación de pedidos      
 * Elaboracion      : 07-oct-2008
 * Autor            : JCM
 * Formato Ejecucion: fglrun repp207 base modulo compania localidad [numliq]
 *
 *		Si (numliq <> 0) el programa se esta ejcutando en modo de
 *			solo consulta
 *		Si (numliq = 0) el programa se esta ejecutando en forma 
 *			independiente
 *}

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_numliq	LIKE rept028.r28_numliq

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA r_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS

DEFINE vm_max_rows	SMALLINT
--
-- DEFINE RECORD(S) HERE
--
DEFINE rm_r28		RECORD LIKE rept028.*

DEFINE vm_ind_ped	SMALLINT
DEFINE rm_pedido ARRAY[50] OF RECORD
	pedido		LIKE rept016.r16_pedido, 
	moneda		LIKE rept016.r16_moneda, 
	n_moneda	LIKE gent013.g13_nombre, 
	proveedor	LIKE rept016.r16_proveedor, 
	tipo		LIKE rept016.r16_tipo, 
	n_tipo		CHAR(10)
END RECORD

DEFINE vm_ind_rub	SMALLINT
DEFINE rm_rubros ARRAY[100] OF RECORD
	rubro		LIKE rept030.r30_codrubro, 
	fecha		LIKE rept030.r30_fecha,	 
	moneda		LIKE rept030.r30_moneda,
	paridad		LIKE rept030.r30_paridad,
	valor		LIKE rept030.r30_valor,
	valor_ml	LIKE rept030.r30_valor,
	check		CHAR(1)
END RECORD
DEFINE rm_r30 	ARRAY[100] OF RECORD 
	serial		LIKE rept030.r30_serial,
	observacion	LIKE rept030.r30_observacion,
	orden		LIKE rept030.r30_orden
END RECORD



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp207.error')
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
LET vg_proceso = 'repp207'

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
OPEN WINDOW w_207 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE 1,
		  BORDER, MESSAGE LINE LAST - 1) 
OPEN FORM f_207 FROM '../forms/repf207_1'
DISPLAY FORM f_207

LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_r28.* TO NULL
CALL muestra_contadores()

LET vm_max_rows = 1000

IF vm_numliq <> 0 THEN
	CALL execute_query()
END IF

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Rubros'
		HIDE OPTION 'Ver pedidos'
		HIDE OPTION 'Imprimir'
		IF vm_numliq <> 0 THEN          -- Se ejecuta en modo de solo
			HIDE OPTION 'Ingresar'  -- consulta
			HIDE OPTION 'Consultar'
			IF vm_num_rows = 1 THEN
			   
				SHOW OPTION 'Rubros'
				SHOW OPTION 'Ver pedidos'
			END IF
		END IF
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		CALL control_ingreso()
		IF vm_num_rows >= 1 THEN

		   IF fl_control_permiso_opcion('Modificar') THEN			
			SHOW OPTION 'Modificar'
		   END IF 
	  	   
			SHOW OPTION 'Rubros'	

		   IF fl_control_permiso_opcion('Imprimir') THEN
			   SHOW OPTION 'Imprimir'
		   END IF
	
			SHOW OPTION 'Ver pedidos'

		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
	COMMAND KEY('M') 'Modificar' 		'Modificar registro corriente.'
		CALL control_modificacion()
	COMMAND KEY('P') 'Ver pedidos'		'Ver pedidos.'
		CALL ingresa_pedidos('C')
	COMMAND KEY('U') 'Rubros'		'Ingresar rubros.'
		CALL ingresa_rubros()
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro.'
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
		   
		   IF fl_control_permiso_opcion('Modificar') THEN			
			SHOW OPTION 'Modificar'
		   END IF 

	  	   SHOW OPTION 'Rubros'
		   

		   IF fl_control_permiso_opcion('Imprimir') THEN
			   SHOW OPTION 'Imprimir'
		   END IF		
		
			SHOW OPTION 'Ver pedidos'
		
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Imprimir'
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Rubros'
				HIDE OPTION 'Ver pedidos'
			END IF
		ELSE

		   IF fl_control_permiso_opcion('Modificar') THEN			
			SHOW OPTION 'Modificar'
		   END IF 

	  	   SHOW OPTION 'Rubros'		   

		   IF fl_control_permiso_opcion('Imprimir') THEN
			   SHOW OPTION 'Imprimir'
		   END IF


			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Ver pedidos'
		
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
	COMMAND KEY('P') 'Imprimir' 'Imprimir la Liquidación.'
		CALL control_imprimir_liquidacion()
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




FUNCTION control_imprimir_liquidacion()
DEFINE command_run 	VARCHAR(200)

LET command_run = 'fglrun repp408 ' || vg_base || ' ' || vg_modulo || ' ' ||
			vg_codcia || ' ' || vg_codloc || ' ' || 
			rm_r28.r28_numliq
RUN command_run

END FUNCTION



FUNCTION control_ingreso()

DEFINE done 		SMALLINT
DEFINE rowid   		SMALLINT

DEFINE r_r00		RECORD LIKE rept000.*
DEFINE r_g14		RECORD LIKE gent014.*

CLEAR FORM
INITIALIZE rm_r28.* TO NULL

LET rm_r28.r28_fecing      = CURRENT
LET rm_r28.r28_usuario     = vg_usuario
LET rm_r28.r28_compania    = vg_codcia
LET rm_r28.r28_localidad   = vg_codloc
LET rm_r28.r28_estado      = 'A'
LET rm_r28.r28_moneda      = rg_gen.g00_moneda_base

CALL fl_lee_compania_repuestos(vg_codcia) RETURNING r_r00.*
LET rm_r28.r28_bodega      = r_r00.r00_bodega_fact

LET rm_r28.r28_fecha_ing   = CURRENT
LET rm_r28.r28_fob_fabrica = 0.0 
LET rm_r28.r28_faltante    = 0.0 
LET rm_r28.r28_flete       = 0.0 
LET rm_r28.r28_otros       = 0.0 
LET rm_r28.r28_total_fob   = 0.0 
LET rm_r28.r28_tot_cargos  = 0.0 
LET rm_r28.r28_seguro      = 0.0 
LET rm_r28.r28_margen_uti  = 0.0 
LET rm_r28.r28_fact_costo  = 0.0 

CALL muestra_etiquetas()

BEGIN WORK

CALL lee_datos('I')
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	ROLLBACK WORK
	RETURN
END IF

SELECT MAX(r28_numliq) INTO rm_r28.r28_numliq
	FROM rept028
	WHERE r28_compania  = vg_codcia
	  AND r28_localidad = vg_codloc
IF rm_r28.r28_numliq IS NULL THEN
	LET rm_r28.r28_numliq = 1
ELSE
	LET rm_r28.r28_numliq = rm_r28.r28_numliq + 1
END IF  

LET rm_r28.r28_fact_costo = 0
IF rm_r28.r28_fob_fabrica > 0 THEN 
	LET rm_r28.r28_fact_costo = (rm_r28.r28_fob_fabrica + 
				     rm_r28.r28_otros + 
			    	     rm_r28.r28_flete + 
				     rm_r28.r28_tot_cargos)
			            / rm_r28.r28_fob_fabrica     
END IF

LET rm_r28.r28_codprov = rm_pedido[1].proveedor
INSERT INTO rept028 VALUES (rm_r28.*)
DISPLAY BY NAME rm_r28.r28_numliq

LET rowid  = SQLCA.SQLERRD[6] 	-- Rowid de la ultima fila 
                              	-- procesada
LET done = graba_pedidos()
IF NOT done THEN
	ROLLBACK WORK
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	ELSE
		CLEAR FORM
		CALL muestra_contadores()
	END IF
	RETURN
END IF

COMMIT WORK

IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF
LET vm_rows[vm_num_rows] = rowid
LET vm_row_current = vm_num_rows

CALL muestra_contadores()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_modificacion()

DEFINE done 		SMALLINT

IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

IF rm_r28.r28_estado = 'P' THEN
	CALL fgl_winmessage(vg_producto,
			    'Esta liquidación ya fue cerrada y no puede ser' ||	
                            ' modificada',
			    'exclamation')
	RETURN
END IF
IF rm_r28.r28_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto,
			    'Esta liquidación no está activa', 'exclamation')
	RETURN
END IF

CALL lee_muestra_registro(vm_rows[vm_row_current])

BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_upd CURSOR FOR 
	SELECT * FROM rept028 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_upd
FETCH q_upd INTO rm_r28.*
IF status < 0 THEN
	WHENEVER ERROR STOP
	CALL fl_mensaje_bloqueo_otro_usuario()
	ROLLBACK WORK
	RETURN
END IF  
WHENEVER ERROR STOP

LET vm_ind_rub = lee_detalle()
LET vm_ind_ped = lee_pedidos()

CALL lee_datos('M')
IF INT_FLAG THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	CLOSE q_upd
	RETURN
END IF 

LET rm_r28.r28_fact_costo = 0
IF rm_r28.r28_fob_fabrica > 0 THEN 
	LET rm_r28.r28_fact_costo = (rm_r28.r28_fob_fabrica + 
				     rm_r28.r28_otros + 
			    	     rm_r28.r28_flete + 
				     rm_r28.r28_tot_cargos)
			            / rm_r28.r28_fob_fabrica     
END IF

UPDATE rept028 SET * = rm_r28.* WHERE CURRENT OF q_upd

LET done = graba_pedidos()
IF NOT done THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	RETURN
END IF

COMMIT WORK
CLOSE q_upd
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION calcula_paridad(moneda_ori, moneda_dest)

DEFINE moneda_ori	LIKE rept030.r30_moneda
DEFINE moneda_dest	LIKE rept028.r28_moneda
DEFINE paridad		LIKE rept030.r30_paridad   

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
DEFINE r_r30		RECORD LIKE rept030.*

DECLARE q_ing2 CURSOR FOR 
	SELECT * FROM rept030 
		WHERE r30_compania  = vg_codcia
	          AND r30_localidad = vg_codloc
	          AND r30_numliq    = rm_r28.r28_numliq
		ORDER BY r30_fecha, r30_orden

LET i = 1
FOREACH q_ing2 INTO r_r30.*
	LET rm_rubros[i].rubro    = r_r30.r30_codrubro
	LET rm_rubros[i].fecha    = r_r30.r30_fecha   
	LET rm_rubros[i].moneda   = r_r30.r30_moneda
	LET rm_rubros[i].paridad  = r_r30.r30_paridad
	LET rm_rubros[i].valor    = r_r30.r30_valor
	LET rm_rubros[i].valor_ml = 
		fl_retorna_precision_valor(rm_r28.r28_moneda,
     		r_r30.r30_valor * r_r30.r30_paridad)
	LET rm_rubros[i].check    = 'N'
	LET rm_r30[i].serial      = r_r30.r30_serial
	LET rm_r30[i].orden       = r_r30.r30_orden
	LET rm_r30[i].observacion = r_r30.r30_observacion
	
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

DEFINE total		LIKE rept030.r30_valor
DEFINE rubro		LIKE rept030.r30_codrubro

DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_g17		RECORD LIKE gent017.*
DEFINE r_r30		RECORD LIKE rept030.*


IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

OPEN WINDOW w_207_4 AT 9,02 WITH 16 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER) 
OPEN FORM f_207_4 FROM '../forms/repf207_4'
DISPLAY FORM f_207_4

LET total = 0
LET vm_ind_rub = lee_detalle()
LET total = total_cargos(vm_ind_rub)

-- Si el estado de la liquidacion es igual a 'P' o 
-- se esta ejecutando el programa en modo de solo consulta
-- no deben de modificarse los rubros
IF rm_r28.r28_estado = 'P' OR vm_numliq <> 0 THEN
	IF vm_ind_rub = 0 THEN
		CALL fgl_winmessage(vg_producto,
			'No hay rubros ingresados en esta liquidación.',
			'exclamation')
		CLOSE WINDOW w_207_4
		RETURN
	END IF

	CALL set_count(vm_ind_rub)
	DISPLAY ARRAY rm_rubros TO ra_rubros.*
		BEFORE DISPLAY
			CALL dialog.keysetlabel('ACCEPT', '')
		AFTER DISPLAY
			CONTINUE DISPLAY
		BEFORE ROW
			LET i = arr_curr()
			DISPLAY rm_r30[i].observacion TO n_rubro
			DISPLAY total TO total_cargos
		ON KEY(INTERRUPT)
			EXIT DISPLAY
	END DISPLAY
	CLOSE WINDOW w_207_4
	RETURN 
END IF

OPTIONS INSERT KEY F30

LET salir = 0
WHILE NOT salir
LET i = 1
LET j = 1
LET INT_FLAG = 0	
IF vm_ind_rub <= 0 THEN
	INITIALIZE rm_rubros[1].* TO NULL
	LET rm_rubros[1].fecha = CURRENT
	LET vm_ind_rub = 1
END IF
CALL set_count(vm_ind_rub)
INPUT ARRAY rm_rubros WITHOUT DEFAULTS FROM ra_rubros.*
	ON KEY(INTERRUPT)
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			EXIT INPUT 
		END IF
	ON KEY(F2)
		IF INFIELD(r30_codrubro) THEN
			CALL fl_ayuda_rubros() 
				RETURNING r_g17.g17_codrubro, 
					  r_g17.g17_nombre 
			IF r_g17.g17_codrubro IS NOT NULL THEN
				LET rm_rubros[i].rubro = r_g17.g17_codrubro
				DISPLAY rm_rubros[i].rubro 
					TO ra_rubros[j].r30_codrubro
				LET rm_r30[i].observacion = r_g17.g17_nombre
				DISPLAY rm_r30[j].observacion 
					TO n_rubro
			END IF
		END IF
		IF INFIELD(r30_moneda) THEN
			CALL fl_ayuda_monedas() 
				RETURNING r_mon.g13_moneda, r_mon.g13_nombre, 
					  r_mon.g13_decimales 
			IF r_mon.g13_moneda IS NOT NULL THEN
				LET rm_rubros[i].moneda = r_mon.g13_moneda
				DISPLAY r_mon.g13_moneda 
					TO ra_rubros[j].r30_moneda
			END IF	
		END IF
		LET INT_FLAG = 0
	BEFORE INPUT
		CALL dialog.keysetlabel('INSERT', '')  
		IF vm_ind_rub = 0 THEN
			INITIALIZE rm_rubros[1].* TO NULL
			LET rm_rubros[1].fecha = CURRENT
			DISPLAY rm_rubros[1].* TO ra_rubros[1].*
			CONTINUE INPUT
		END IF
		DISPLAY rm_r30[i].observacion TO n_rubro
		DISPLAY total TO total_cargos
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
		DISPLAY rm_r30[i].observacion TO n_rubro
		LET total = total_cargos(arr_count())
		DISPLAY total TO total_cargos
	BEFORE INSERT
		INITIALIZE rm_rubros[i].* TO NULL
		LET rm_rubros[i].fecha     = CURRENT
		DISPLAY rm_rubros[i].* TO ra_rubros[j].*
	BEFORE DELETE
		CALL deleteRow(i, arr_count())
	AFTER  DELETE
		LET vm_ind_rub = arr_count()
		EXIT INPUT
	BEFORE FIELD r30_codrubro
		LET rubro = rm_rubros[i].rubro
	AFTER FIELD r30_codrubro
		IF rm_rubros[i].rubro IS NULL THEN
			INITIALIZE rm_rubros[i].rubro TO NULL
			CLEAR ra_rubros[j].r30_codrubro 
			CONTINUE INPUT          
		ELSE
			CALL fl_lee_rubro_liquidacion(rm_rubros[i].rubro)
				RETURNING r_g17.*
			IF r_g17.g17_codrubro IS NULL THEN
				CALL fgl_winmessage(vg_producto,
 					'Rubro no existe.',
					'exclamation')
				NEXT FIELD r30_codrubro
			END IF
			LET rm_rubros[i].rubro     = r_g17.g17_codrubro
			LET rm_r30[i].orden        = r_g17.g17_orden
			IF rm_r30[i].observacion IS NULL 
			OR rubro <> rm_rubros[i].rubro THEN
				LET rm_r30[i].observacion  = r_g17.g17_nombre
			END IF
			DISPLAY rm_rubros[i].* TO ra_rubros[j].*
			DISPLAY rm_r30[i].observacion TO n_rubro
		END IF
	AFTER FIELD r30_moneda
		IF rm_rubros[i].moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_rubros[i].moneda) 
				RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN	
				CALL FGL_WINMESSAGE(vg_producto, 
                             		            'Moneda no existe',        
                                        	    'exclamation')
				NEXT FIELD r30_moneda
			ELSE
				IF r_mon.g13_estado = 'B' THEN
					CALL FGL_WINMESSAGE(vg_producto, 
                            		 	            'Moneda está ' ||
                               	                            'bloqueada',        
                                       	                    'exclamation')
					NEXT FIELD r30_moneda
				ELSE
					LET rm_rubros[i].paridad = 
						calcula_paridad(
							rm_rubros[i].moneda,
							rm_r28.r28_moneda)
					IF rm_rubros[i].paridad IS NULL THEN
						LET rm_rubros[i].moneda =
							rm_r28.r28_moneda     
					END IF	
					DISPLAY rm_rubros[i].* 
						TO ra_rubros[j].*
				END IF
			END IF 
		ELSE
			CONTINUE INPUT        
		END IF
	AFTER FIELD r30_valor
		IF rm_rubros[i].valor IS NULL THEN
			CONTINUE INPUT
		END IF
		LET rm_rubros[i].valor = fl_retorna_precision_valor(
						rm_rubros[i].moneda,
						rm_rubros[i].valor)
		IF rm_r28.r28_moneda IS NOT NULL THEN
			LET rm_rubros[i].valor_ml = 
				fl_retorna_precision_valor(rm_r28.r28_moneda,
				rm_rubros[i].valor * rm_rubros[i].paridad)
		ELSE
			LET rm_rubros[i].valor_ml =
				rm_rubros[i].valor * rm_rubros[i].paridad
		END IF
		DISPLAY rm_rubros[i].* TO ra_rubros[i].*
		LET total = total_cargos(arr_count()) 
		DISPLAY total TO total_cargos
	BEFORE FIELD check
		CALL mas_datos(i)	
		LET rm_rubros[i].check = 'N'
		DISPLAY rm_rubros[i].check TO ra_rubros[j].check	
		NEXT FIELD NEXT
	AFTER INPUT
		LET vm_ind_rub = arr_count()
		FOR i = 1 TO vm_ind_rub 
			IF rm_rubros[i].rubro IS NULL OR
			   rm_rubros[i].fecha IS NULL OR
			   rm_rubros[i].moneda IS NULL OR
		  	   rm_rubros[i].paridad IS NULL OR
			   rm_rubros[i].valor IS NULL 
			THEN
				CONTINUE INPUT
			END IF
		END FOR 
		LET salir = 1
END INPUT
IF INT_FLAG THEN
	CLOSE WINDOW w_207_4
	RETURN 
END IF

END WHILE

BEGIN WORK
	LET done = graba_rubros()
	IF NOT done THEN
		ROLLBACK WORK
		CLOSE WINDOW w_207_4
		RETURN
	END IF
COMMIT WORK

CLOSE WINDOW w_207_4

RETURN 

END FUNCTION



FUNCTION mas_datos(i)

DEFINE i		SMALLINT

DEFINE r_g13		RECORD LIKE gent013.*

OPTIONS 
	INPUT NO WRAP

OPEN WINDOW w_207_5 AT 10,20 WITH 05 ROWS, 50 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER) 
OPEN FORM f_207_5 FROM '../forms/repf207_5'
DISPLAY FORM f_207_5

CALL fl_lee_moneda(rm_rubros[i].moneda) RETURNING r_g13.*
DISPLAY rm_rubros[i].moneda TO r30_moneda
DISPLAY r_g13.g13_nombre TO n_moneda

LET INT_FLAG = 0
INPUT rm_r30[i].observacion WITHOUT DEFAULTS FROM r30_observacion
IF INT_FLAG THEN
	CLOSE WINDOW w_207_5
	RETURN
END IF

CLOSE WINDOW w_207_5

END FUNCTION



FUNCTION graba_rubros()

DEFINE done		SMALLINT
DEFINE intentar		SMALLINT

DEFINE i		SMALLINT
DEFINE j		SMALLINT
DEFINE flag		CHAR(1)

DEFINE r_r30		RECORD LIKE rept030.*

DECLARE q_rubro CURSOR FOR
	SELECT * FROM rept030
		WHERE r30_compania  = vg_codcia
		  AND r30_localidad = vg_codloc
		  AND r30_numliq    = rm_r28.r28_numliq
		ORDER BY r30_fecha, r30_orden

LET i = 1
FOREACH q_rubro INTO r_r30.*
	INITIALIZE flag TO NULL
	LET j = i
	IF r_r30.r30_serial = rm_r30[i].serial THEN
		LET flag = 'U'
		LET i = i + 1
	ELSE
		LET flag = 'D'
	END IF
	IF flag IS NOT NULL THEN
		LET done = actualiza_detalle_liq(j, flag, r_r30.r30_serial)
		IF NOT done THEN
			RETURN done 
		END IF
		CONTINUE FOREACH
	END IF
END FOREACH 

WHILE (i <= vm_ind_rub)
	INITIALIZE r_r30.* TO NULL
	LET r_r30.r30_compania    = vg_codcia
	LET r_r30.r30_localidad   = vg_codloc
	LET r_r30.r30_numliq      = rm_r28.r28_numliq
	LET r_r30.r30_serial      = 0
	LET r_r30.r30_codrubro    = rm_rubros[i].rubro
	LET r_r30.r30_fecha       = rm_rubros[i].fecha
	LET r_r30.r30_observacion = rm_r30[i].observacion 
	LET r_r30.r30_moneda      = rm_rubros[i].moneda
	LET r_r30.r30_valor       = rm_rubros[i].valor
	LET r_r30.r30_paridad     = rm_rubros[i].paridad
	LET r_r30.r30_orden	  = rm_r30[i].orden

	INSERT INTO rept030 VALUES (r_r30.*)

	LET i = i + 1
END WHILE

LET done = actualiza_cabecera_liq()
IF NOT done THEN
	RETURN done 
END IF

RETURN 1

END FUNCTION



FUNCTION deleteRow(i, num_rows)

DEFINE i		SMALLINT
DEFINE num_rows		SMALLINT

WHILE (i < num_rows)
	LET rm_r30[i].* = rm_r30[i + 1].*
	LET i = i + 1
END WHILE
INITIALIZE rm_r30[i].* TO NULL

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
DEFINE serial		LIKE rept030.r30_serial

DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT

DEFINE r_r30		RECORD LIKE rept030.*

LET intentar = 1
LET done = 0
WHILE (intentar)
	INITIALIZE r_r30.* TO NULL
	WHENEVER ERROR CONTINUE
		DECLARE q_updet CURSOR FOR
			SELECT * FROM rept030
				WHERE r30_compania  = vg_codcia
				  AND r30_localidad = vg_codloc
				  AND r30_numliq    = rm_r28.r28_numliq
				  AND r30_serial    = serial
			FOR UPDATE
	OPEN q_updet
	FETCH q_updet INTO r_r30.*
	IF STATUS < 0 THEN
		WHENEVER ERROR STOP
		LET intentar = mensaje_intentar()
		CLOSE q_updet
		FREE  q_updet
	ELSE
		WHENEVER ERROR STOP
		LET intentar = 0
		LET done = 1
	END IF
END WHILE

IF NOT intentar AND NOT done THEN
	RETURN done
END IF

CASE flag
	WHEN 'U' 
		LET r_r30.r30_codrubro    = rm_rubros[i].rubro
		LET r_r30.r30_moneda      = rm_rubros[i].moneda
		LET r_r30.r30_paridad     = rm_rubros[i].paridad
		LET r_r30.r30_valor       = rm_rubros[i].valor
		LET r_r30.r30_orden	  = rm_r30[i].orden
		LET r_r30.r30_observacion = rm_r30[i].observacion 
		
		UPDATE rept030 SET * = r_r30.* WHERE CURRENT OF q_updet 
	WHEN 'D'
		DELETE FROM rept030 WHERE CURRENT OF q_updet
END CASE

CLOSE q_updet
FREE  q_updet
RETURN done

END FUNCTION



FUNCTION actualiza_cabecera_liq()

DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT

DEFINE r_r28		RECORD LIKE rept028.*

LET intentar = 1
LET done = 0
WHILE (intentar)
	INITIALIZE r_r28.* TO NULL
	WHENEVER ERROR CONTINUE
		DECLARE q_r28 CURSOR FOR
			SELECT * FROM rept028
				WHERE r28_compania  = vg_codcia
				  AND r28_localidad = vg_codloc
				  AND r28_numliq    = rm_r28.r28_numliq
			FOR UPDATE
	OPEN q_r28  
	FETCH q_r28 INTO r_r28.*
	IF STATUS < 0 THEN
		WHENEVER ERROR STOP
		LET intentar = mensaje_intentar()
		CLOSE q_r28
		FREE  q_r28
	ELSE
		WHENEVER ERROR STOP
		LET intentar = 0
		LET done = 1
	END IF
END WHILE

IF NOT intentar AND NOT done THEN
	RETURN done
END IF

SELECT SUM(r30_valor * r30_paridad) INTO r_r28.r28_tot_cargos
	FROM rept030
	WHERE r30_compania  = vg_codcia
	  AND r30_localidad = vg_codloc
	  AND r30_numliq    = r_r28.r28_numliq 
IF r_r28.r28_tot_cargos IS NULL THEN
	LET r_r28.r28_tot_cargos = 0.0
END IF
LET r_r28.r28_tot_cargos = fl_retorna_precision_valor(r_r28.r28_moneda,
						      r_r28.r28_tot_cargos)

LET r_r28.r28_total_fob = r_r28.r28_total_fob + r_r28.r28_tot_cargos
LET r_r28.r28_total_fob = fl_retorna_precision_valor(r_r28.r28_moneda,
 						     r_r28.r28_total_fob)	
LET r_r28.r28_fact_costo = 0 
IF r_r28.r28_fob_fabrica > 0 THEN
	LET r_r28.r28_fact_costo = (r_r28.r28_fob_fabrica + r_r28.r28_otros + 
			            r_r28.r28_flete + r_r28.r28_tot_cargos)
			           / r_r28.r28_fob_fabrica
END IF

UPDATE rept028 SET * = r_r28.* WHERE CURRENT OF q_r28   

CLOSE q_r28
FREE  q_r28  

RETURN done

END FUNCTION



FUNCTION actualiza_estado_pedido(estado_ori, estado_dest, pedido)

DEFINE estado_ori	LIKE rept017.r17_estado
DEFINE estado_dest	LIKE rept017.r17_estado
DEFINE pedido		LIKE rept016.r16_pedido

DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT

DEFINE r_r16		RECORD LIKE rept016.*

LET intentar = 1
LET done = 0
WHILE (intentar)
	INITIALIZE r_r16.* TO NULL
	WHENEVER ERROR CONTINUE
		DECLARE q_cab CURSOR FOR
			SELECT * FROM rept016
				WHERE r16_compania  = vg_codcia
				  AND r16_localidad = vg_codloc
				  AND r16_pedido    = pedido
			FOR UPDATE
	OPEN  q_cab  
	FETCH q_cab INTO r_r16.*
	IF STATUS < 0 THEN
		WHENEVER ERROR STOP
		LET intentar = mensaje_intentar()
		CLOSE q_cab
		FREE  q_cab
	ELSE
		WHENEVER ERROR STOP
		LET intentar = 0
		LET done = 1
	END IF
END WHILE

IF NOT intentar AND NOT done THEN
	RETURN done
END IF

LET r_r16.r16_estado = estado_dest                   

UPDATE rept016 SET * = r_r16.* WHERE CURRENT OF q_cab   

LET done = actualiza_detalles_pedido(estado_ori, estado_dest, pedido)
IF NOT done THEN
	RETURN done
END IF
CLOSE q_cab  
FREE  q_cab

RETURN done

END FUNCTION



FUNCTION actualiza_detalles_pedido(estado_ori, estado_dest, pedido)

DEFINE estado_ori	LIKE rept017.r17_estado
DEFINE estado_dest	LIKE rept017.r17_estado

DEFINE pedido		LIKE rept016.r16_pedido

DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT

DEFINE r_r17		RECORD LIKE rept017.*

LET intentar = 1
LET done = 0
WHILE (intentar)
	INITIALIZE r_r17.* TO NULL
	WHENEVER ERROR CONTINUE
		DECLARE q_r17 CURSOR FOR
			SELECT * FROM rept017
				WHERE r17_compania  = vg_codcia
				  AND r17_localidad = vg_codloc
				  AND r17_pedido    = pedido
				  AND r17_estado    = estado_ori
			FOR UPDATE
	OPEN  q_r17
	FETCH q_r17 INTO r_r17.*
	IF STATUS < 0 THEN
		WHENEVER ERROR STOP
		LET intentar = mensaje_intentar()
		CLOSE q_r17
		FREE  q_r17
	ELSE
		WHENEVER ERROR STOP
		LET intentar = 0
		LET done = 1
	END IF
END WHILE

IF NOT intentar AND NOT done THEN
	RETURN done
END IF

WHILE (STATUS <> NOTFOUND)
	LET r_r17.r17_estado = estado_dest           
	UPDATE rept017 SET * = r_r17.* WHERE CURRENT OF q_r17   

	INITIALIZE r_r17.* TO NULL
	FETCH q_r17 INTO r_r17.*
END WHILE    
CLOSE q_r17
FREE  q_r17

RETURN done

END FUNCTION



FUNCTION lee_datos(flag)

DEFINE flag 		CHAR(1)
DEFINE resp 		CHAR(6)

DEFINE contador 	SMALLINT

DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_g14		RECORD LIKE gent014.*
DEFINE r_r02		RECORD LIKE rept002.*

LET INT_FLAG = 0
INPUT BY NAME rm_r28.r28_estado, rm_r28.r28_origen, 
              rm_r28.r28_forma_pago, rm_r28.r28_descripcion,
              rm_r28.r28_num_pi, rm_r28.r28_guia, rm_r28.r28_pedimento, 
              rm_r28.r28_fecha_lleg, rm_r28.r28_fecha_ing, rm_r28.r28_moneda,
	      rm_r28.r28_fob_fabrica, rm_r28.r28_faltante,
              rm_r28.r28_flete, rm_r28.r28_otros, rm_r28.r28_total_fob, 
              rm_r28.r28_tot_cargos, rm_r28.r28_seguro,
              rm_r28.r28_elaborado, rm_r28.r28_usuario, rm_r28.r28_fecing 
 	WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(r28_origen, 
                		     r28_forma_pago, r28_descripcion, 
                		     r28_num_pi, r28_guia, r28_pedimento, 
			             r28_fecha_lleg, r28_fecha_ing, r28_moneda,
		                     r28_fob_fabrica, r28_faltante, r28_flete,
		                     r28_otros, r28_total_fob, r28_tot_cargos, 
				     r28_seguro, r28_elaborado
                                    ) THEN
			RETURN
		END IF

		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN
		END IF
	ON KEY(F5)
		CALL ingresa_pedidos('I')
		DISPLAY BY NAME rm_r28.r28_total_fob,
 				rm_r28.r28_fob_fabrica,
				rm_r28.r28_faltante,
				rm_r28.r28_flete,
				rm_r28.r28_otros
	ON KEY(F2)
		IF INFIELD(r28_moneda) THEN
			CALL fl_ayuda_monedas() 
				RETURNING r_mon.g13_moneda, r_mon.g13_nombre, 
					  r_mon.g13_decimales 
			IF r_mon.g13_moneda IS NOT NULL THEN
				LET rm_r28.r28_moneda = r_mon.g13_moneda
				DISPLAY r_mon.g13_moneda TO r28_moneda
				DISPLAY r_mon.g13_nombre TO n_moneda
			END IF	
		END IF
		LET INT_FLAG = 0
	AFTER FIELD r28_moneda
		IF rm_r28.r28_moneda IS NULL THEN
			CLEAR n_moneda
		ELSE
			CALL fl_lee_moneda(rm_r28.r28_moneda) RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN	
				CALL FGL_WINMESSAGE(vg_producto, 
                             		            'Moneda no existe',        
                                        	    'exclamation')
				CLEAR n_moneda
				NEXT FIELD r28_moneda
			ELSE
				IF r_mon.g13_estado = 'B' THEN
					CALL FGL_WINMESSAGE(vg_producto, 
                            		 	            'Moneda está ' ||
                               	                            'bloqueada',        
                                       	                    'exclamation')
					CLEAR n_moneda
					NEXT FIELD r28_moneda
				ELSE
					DISPLAY r_mon.g13_nombre TO n_moneda
					IF rm_r28.r28_moneda <> 
						rg_gen.g00_moneda_base 
					AND rm_r28.r28_moneda <> 
						rg_gen.g00_moneda_alt 
					THEN
						CALL fgl_winmessage(
							vg_producto,
							'La moneda debe ser ' ||
							'la moneda base o la' ||
							'moneda alterna.',
							'exclamation')
						CLEAR n_moneda
						NEXT FIELD r28_moneda
					END IF
					CALL muestra_etiquetas()
				END IF
			END IF 
		END IF
	AFTER FIELD r28_faltante     
		LET rm_r28.r28_faltante =
			fl_retorna_precision_valor(rm_r28.r28_moneda,
						   rm_r28.r28_faltante)
		DISPLAY BY NAME rm_r28.r28_faltante
		LET rm_r28.r28_total_fob = rm_r28.r28_fob_fabrica +
					   rm_r28.r28_faltante    +
					   rm_r28.r28_flete       +
					   rm_r28.r28_otros       + 
					   rm_r28.r28_tot_cargos  +
					   rm_r28.r28_seguro 
		DISPLAY BY NAME rm_r28.r28_total_fob
	AFTER FIELD r28_otros       
		LET rm_r28.r28_otros =
			fl_retorna_precision_valor(rm_r28.r28_moneda,
						   rm_r28.r28_otros)
		DISPLAY BY NAME rm_r28.r28_otros 
		LET rm_r28.r28_total_fob = rm_r28.r28_fob_fabrica +
					   rm_r28.r28_faltante    +
					   rm_r28.r28_flete       +
					   rm_r28.r28_otros       + 
					   rm_r28.r28_tot_cargos  +
					   rm_r28.r28_seguro 
		LET rm_r28.r28_fact_costo =  0
		IF rm_r28.r28_fob_fabrica > 0 THEN
			LET rm_r28.r28_fact_costo = (rm_r28.r28_fob_fabrica + 
						     rm_r28.r28_otros + 
			   		             rm_r28.r28_flete + 
        					     rm_r28.r28_tot_cargos)
			    		            / rm_r28.r28_fob_fabrica
		END IF
		DISPLAY BY NAME rm_r28.r28_total_fob, rm_r28.r28_fact_costo
	AFTER FIELD r28_flete       
		LET rm_r28.r28_flete =
			fl_retorna_precision_valor(rm_r28.r28_moneda,
						   rm_r28.r28_flete)
		DISPLAY BY NAME rm_r28.r28_flete 
		LET rm_r28.r28_total_fob = rm_r28.r28_fob_fabrica +
					   rm_r28.r28_faltante    +
					   rm_r28.r28_flete       +
					   rm_r28.r28_otros       + 
					   rm_r28.r28_tot_cargos  +
					   rm_r28.r28_seguro 
		LET rm_r28.r28_fact_costo =  0
		IF rm_r28.r28_fob_fabrica > 0 THEN
			LET rm_r28.r28_fact_costo =  (rm_r28.r28_fob_fabrica + 
						      rm_r28.r28_otros + 
				   		      rm_r28.r28_flete + 
                	                              rm_r28.r28_tot_cargos)
				    		     / rm_r28.r28_fob_fabrica
		END IF
		DISPLAY BY NAME rm_r28.r28_total_fob, rm_r28.r28_fact_costo
	AFTER FIELD r28_seguro      
		LET rm_r28.r28_seguro =
			fl_retorna_precision_valor(rm_r28.r28_moneda,
						   rm_r28.r28_seguro)
		DISPLAY BY NAME rm_r28.r28_seguro 
		LET rm_r28.r28_total_fob = rm_r28.r28_fob_fabrica +
					   rm_r28.r28_faltante    +
					   rm_r28.r28_flete       +
					   rm_r28.r28_otros       + 
					   rm_r28.r28_tot_cargos  +
					   rm_r28.r28_seguro 
		DISPLAY BY NAME rm_r28.r28_total_fob
	AFTER INPUT 
		LET rm_r28.r28_tot_cargos = total_cargos(vm_ind_rub)
		DISPLAY BY NAME rm_r28.r28_tot_cargos
		LET rm_r28.r28_total_fob = rm_r28.r28_fob_fabrica +
					   rm_r28.r28_faltante    +
					   rm_r28.r28_flete       +
					   rm_r28.r28_otros       + 
					   rm_r28.r28_tot_cargos  +
					   rm_r28.r28_seguro 
		LET rm_r28.r28_fact_costo =  0
		IF rm_r28.r28_fob_fabrica > 0 THEN
			LET rm_r28.r28_fact_costo =  (rm_r28.r28_fob_fabrica + 
						      rm_r28.r28_otros + 
				   		      rm_r28.r28_flete + 
                	                              rm_r28.r28_tot_cargos)
				    		     / rm_r28.r28_fob_fabrica
		END IF
		DISPLAY BY NAME rm_r28.r28_total_fob, rm_r28.r28_fact_costo
		IF vm_ind_ped = 0 THEN
			CALL fgl_winquestion(vg_producto,
				'No ha ingresado ningun pedido, y no ' ||
				'podrá grabar. ¿Desea especificar algún ' ||
				'pedido? ', 'No', 'Yes|No', 'question', 1)
				RETURNING resp
			IF resp = 'Yes' THEN
				CONTINUE INPUT
			ELSE
				LET int_flag = 1
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION total_cargos(num_elm)

DEFINE i		SMALLINT
DEFINE num_elm		SMALLINT 
DEFINE total		LIKE rept028.r28_tot_cargos

IF num_elm IS NULL OR num_elm = 0 THEN
	SELECT SUM(r30_valor * r30_paridad) INTO total
		FROM rept030
		WHERE r30_compania  = vg_codcia
		  AND r30_localidad = vg_codloc
		  AND r30_numliq    = rm_r28.r28_numliq 
	IF total IS NULL THEN
		LET total = 0
	END IF
ELSE
	LET total = 0
	FOR i = 1 TO num_elm
		LET total = total + rm_rubros[i].valor_ml
	END FOR
END IF 

IF rm_r28.r28_moneda IS NOT NULL THEN
	LET total = fl_retorna_precision_valor(rm_r28.r28_moneda, total)
END IF

RETURN total

END FUNCTION



FUNCTION control_consulta()

DEFINE expr_sql			VARCHAR(500)
DEFINE query			VARCHAR(600)

DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r28		RECORD LIKE rept028.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_g14		RECORD LIKE gent014.*

CLEAR FORM

LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql 
        ON r28_numliq,      r28_estado, r28_origen, r28_forma_pago, 
	   r28_descripcion, r28_num_pi, r28_guia,   r28_pedimento, 
	   r28_fecha_lleg,  r28_fecha_ing, r28_moneda,       
           r28_fob_fabrica, r28_faltante, r28_flete, r28_otros, 
           r28_total_fob,   r28_tot_cargos, r28_seguro, 
	     r28_elaborado, r28_usuario
	ON KEY(F2)
		IF INFIELD(r28_numliq) THEN
			CALL fl_ayuda_liquidacion_rep(vg_codcia, vg_codloc, 'T')
				RETURNING r_r28.r28_numliq 
			IF r_r28.r28_numliq IS NOT NULL THEN
				LET rm_r28.r28_numliq = r_r28.r28_numliq
				DISPLAY BY NAME rm_r28.r28_numliq
			END IF
		END IF
		IF INFIELD(r28_moneda) THEN
			CALL fl_ayuda_monedas() 
				RETURNING r_mon.g13_moneda, r_mon.g13_nombre, 
					  r_mon.g13_decimales 
			IF r_mon.g13_moneda IS NOT NULL THEN
				LET rm_r28.r28_moneda = r_mon.g13_moneda
				DISPLAY r_mon.g13_moneda TO r28_moneda
				DISPLAY r_mon.g13_nombre TO n_moneda
			END IF	
		END IF
		LET INT_FLAG = 0
	AFTER FIELD r28_moneda
		LET rm_r28.r28_moneda = GET_FLDBUF(r28_moneda)
		IF rm_r28.r28_moneda IS NULL THEN
			CLEAR n_moneda
		ELSE
			CALL fl_lee_moneda(rm_r28.r28_moneda) RETURNING r_mon.*
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

LET query = 'SELECT *, ROWID FROM rept028 ', 
            '	WHERE r28_compania  = ', vg_codcia, 
	    ' 	  AND r28_localidad = ', vg_codloc,
	    ' 	  AND ', expr_sql CLIPPED, 
            ' ORDER BY 1, 2, 3' 

PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_r28.*, vm_rows[vm_num_rows]
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

SELECT * INTO rm_r28.* FROM rept028 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

DISPLAY BY NAME rm_r28.r28_numliq,
		rm_r28.r28_estado,
		rm_r28.r28_descripcion,
		rm_r28.r28_origen,     
		rm_r28.r28_forma_pago,
		rm_r28.r28_num_pi,
		rm_r28.r28_guia,
		rm_r28.r28_pedimento,
		rm_r28.r28_fecha_lleg,
		rm_r28.r28_fecha_ing,
		rm_r28.r28_moneda,
		rm_r28.r28_fob_fabrica,
		rm_r28.r28_faltante,
		rm_r28.r28_flete,
		rm_r28.r28_otros,
		rm_r28.r28_total_fob,
		rm_r28.r28_tot_cargos,
		rm_r28.r28_seguro,     
		rm_r28.r28_fact_costo,
		rm_r28.r28_elaborado,
		rm_r28.r28_usuario,
		rm_r28.r28_fecing
CALL muestra_etiquetas()
CALL muestra_contadores()

END FUNCTION



FUNCTION muestra_contadores()

DISPLAY "" AT 1,1
DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 68 

END FUNCTION



FUNCTION siguiente_registro()

IF vm_num_rows = 0 THEN
	RETURN
END IF

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
	INITIALIZE vm_ind_ped TO NULL
	INITIALIZE vm_ind_rub TO NULL
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION anterior_registro()

IF vm_num_rows = 0 THEN
	RETURN
END IF

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
	INITIALIZE vm_ind_ped TO NULL
	INITIALIZE vm_ind_rub TO NULL
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION muestra_etiquetas()

DEFINE nom_estado	CHAR(9)

DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_r02		RECORD LIKE rept002.*

CASE rm_r28.r28_estado
	WHEN 'A' LET nom_estado = 'ACTIVO'
	WHEN 'B' LET nom_estado = 'ELIMINADA'
	WHEN 'P' LET nom_estado = 'PROCESADA'
END CASE
DISPLAY nom_estado   TO n_estado

CALL fl_lee_moneda(rm_r28.r28_moneda) RETURNING r_g13.*
DISPLAY r_g13.g13_nombre TO n_moneda

END FUNCTION



FUNCTION execute_query()

LET vm_num_rows = 1
LET vm_row_current = 1

SELECT ROWID INTO vm_rows[vm_num_rows]
	FROM rept028
	WHERE r28_compania  = vg_codcia
	  AND r28_localidad = vg_codloc
	  AND r28_numliq    = vm_numliq
IF STATUS = NOTFOUND THEN
	CALL fgl_winmessage(vg_producto, 'Liquidación no existe', 'exclamation')
	EXIT PROGRAM
ELSE
	CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION muestra_detalle_pedido(pedido)

DEFINE pedido		LIKE rept029.r29_pedido
DEFINE comando 		CHAR(255)

LET comando = 'fglrun repp302 ' || vg_base || ' ' || vg_modulo || ' ' ||
                                 vg_codcia || ' ' || vg_codloc || ' ' ||
                                 pedido

RUN comando

END FUNCTION



FUNCTION lee_pedidos()

DEFINE i		SMALLINT
DEFINE r_r29		RECORD LIKE rept029.*

DECLARE q_ped CURSOR FOR 
	SELECT r29_pedido, r16_moneda, g13_nombre, r16_proveedor, r16_tipo 
		FROM rept029, rept016, gent013 
		WHERE r29_compania  = vg_codcia
	          AND r29_localidad = vg_codloc
	          AND r29_numliq    = rm_r28.r28_numliq
		  AND r16_compania  = r29_compania
		  AND r16_localidad = r29_localidad
                  AND r16_pedido    = r29_pedido
		  AND g13_moneda    = r16_moneda
		ORDER BY 1                   

LET i = 1
FOREACH q_ped INTO rm_pedido[i].pedido,	  rm_pedido[i].moneda, 
		   rm_pedido[i].n_moneda, rm_pedido[i].proveedor, 
		   rm_pedido[i].tipo  

	CASE rm_pedido[i].tipo
		WHEN 'S'
			LET rm_pedido[i].n_tipo = 'SUGERIDO'
		WHEN 'E'
			LET rm_pedido[i].n_tipo = 'EMERGENCIA'	
	END CASE

	LET i = i + 1
	IF i > 100 THEN
		EXIT FOREACH
	END IF
END FOREACH

LET i = i - 1 

RETURN i

END FUNCTION



FUNCTION ingresa_pedidos(flag)

DEFINE resp		CHAR(6)

DEFINE i		SMALLINT
DEFINE j		SMALLINT
DEFINE salir		SMALLINT
DEFINE contador		SMALLINT

DEFINE flag 		CHAR(1)

DEFINE done		SMALLINT
DEFINE fob		LIKE rept028.r28_fob_fabrica
DEFINE ped_ant		LIKE rept016.r16_pedido 

DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_r16		RECORD LIKE rept016.*

IF vm_num_rows = 0 AND flag = 'C' THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

OPEN WINDOW w_207_2 AT 9,12 WITH 12 ROWS, 66 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER) 
OPEN FORM f_207_2 FROM '../forms/repf207_2'
DISPLAY FORM f_207_2

IF vm_ind_ped IS NULL OR vm_ind_ped <= 0 THEN 
	LET vm_ind_ped = lee_pedidos()
END IF

-- Si el estado de la liquidacion es igual a 'P' o 
-- se esta ejecutando el programa en modo de solo consulta
-- no deben de modificarse los pedidos
IF rm_r28.r28_estado = 'P' OR vm_numliq <> 0 OR flag = 'C' THEN
	IF vm_ind_ped = 0 THEN
		CALL fgl_winmessage(vg_producto,
			'No hay pedidos asignados a esta liquidación.',
			'exclamation')
		RETURN
	END IF
	CALL set_count(vm_ind_ped)
	DISPLAY ARRAY rm_pedido TO ra_pedido.*
		ON KEY(F5)
			IF rm_pedido[i].pedido IS NOT NULL THEN
				CALL muestra_detalle_pedido(rm_pedido[i].pedido)
			ELSE
				CALL fgl_winmessage(vg_producto,
					'Ingrese un pedido primero.',
					'exclamation')
			END IF
		BEFORE DISPLAY
			CALL dialog.keysetlabel('ACCEPT', '')
		AFTER DISPLAY
			CONTINUE DISPLAY
		BEFORE ROW
			LET i = arr_curr()
		ON KEY(INTERRUPT)
			EXIT DISPLAY
	END DISPLAY
	CLOSE WINDOW w_207_2

	LET vm_ind_ped = 0 --GVA ... PARA QUE VUELVA A MOSTRAR LOS PEDIDOS 
			   --CORRESPONDIENTES A LA LIQUIDACION CONSULTADA

	RETURN 
END IF

OPTIONS INSERT KEY F30

LET salir = 0
WHILE NOT salir

LET i = 1
LET j = 1
LET INT_FLAG = 0
IF vm_ind_ped > 0 THEN
	CALL set_count(vm_ind_ped)
END IF
INPUT ARRAY rm_pedido WITHOUT DEFAULTS FROM ra_pedido.*
	ON KEY(INTERRUPT)
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			EXIT INPUT 
		END IF
	ON KEY(F5)
		IF rm_pedido[i].pedido IS NOT NULL THEN
			CALL muestra_detalle_pedido(rm_pedido[i].pedido)
		ELSE
			CALL fgl_winmessage(vg_producto,
				'Ingrese un pedido primero.',
				'exclamation')
		END IF
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
	BEFORE INPUT
		CALL dialog.keysetlabel('INSERT', '')
		IF vm_ind_ped = 0 THEN
			INITIALIZE rm_pedido[1].* TO NULL
			DISPLAY rm_pedido[1].* TO ra_pedido[1].*
		END IF
	ON KEY(F2)
		IF INFIELD(r16_pedido) THEN
			CALL fl_ayuda_pedidos_rep(vg_codcia, vg_codloc, 'R', 
				'T') RETURNING r_r16.r16_pedido 
--				 	       r_p01.p01_nomprov,
--					       r_r16.r16_estado, 
--					       r_r16.r16_tipo        
			IF r_r16.r16_pedido IS NOT NULL THEN
				LET rm_pedido[i].pedido = r_r16.r16_pedido
				DISPLAY rm_pedido[i].pedido 
					TO ra_pedido[j].r16_pedido
			END IF		
		END IF
		LET INT_FLAG = 0
	BEFORE FIELD r16_pedido
		LET ped_ant = rm_pedido[i].pedido
	AFTER FIELD r16_pedido
		IF rm_pedido[i].pedido IS NULL THEN
			CONTINUE INPUT
		END IF
		CALL fl_lee_pedido_rep(vg_codcia, vg_codloc, 
			rm_pedido[i].pedido) RETURNING r_r16.*
		IF r_r16.r16_pedido IS NULL THEN
			CALL fgl_winmessage(vg_producto,
				'El pedido no existe.',
				'exclamation') 
			NEXT FIELD r16_pedido
		END IF
		IF r_r16.r16_estado <> 'R' AND r_r16.r16_estado <> 'L' THEN
			CALL fgl_winmessage(vg_producto,
				'No puede liquidar este pedido.',
				'exclamation')
			NEXT FIELD r16_pedido
		END IF
		SELECT COUNT(*) INTO contador
			FROM rept017
			WHERE r17_compania  = vg_codcia
		  	  AND r17_localidad = vg_codloc
		  	  AND r17_pedido    = rm_pedido[i].pedido
			  AND r17_estado IN ('R', 'L')
		IF contador = 0 THEN
			CALL fgl_winmessage(vg_producto, 
				'No existen items recibidos ni ' ||
				'liquidados en el pedido',
        			'exclamation')
			NEXT FIELD r16_pedido
		END IF
		LET rm_pedido[i].pedido    = r_r16.r16_pedido
		LET rm_pedido[i].moneda    = r_r16.r16_moneda
		LET rm_pedido[i].tipo      = r_r16.r16_tipo
		LET rm_pedido[i].proveedor = r_r16.r16_proveedor
		CALL etiquetas_pedido(i)
		DISPLAY rm_pedido[i].* TO ra_pedido[j].*
	AFTER INPUT
		LET vm_ind_ped = arr_count()
		LET rm_r28.r28_fob_fabrica = 0
		FOR i = 1 TO vm_ind_ped
			IF rm_r28.r28_numliq IS NULL THEN
				SELECT SUM(r117_fob * r117_cantidad) INTO fob
		 		  FROM rept117
				 WHERE r117_compania  = vg_codcia
				   AND r117_localidad = vg_codloc
				   AND r117_pedido    = rm_pedido[i].pedido
				   AND r117_numliq IS NULL
			ELSE
				SELECT SUM(r117_fob * r117_cantidad) INTO fob
		 		  FROM rept117
				 WHERE r117_compania  = vg_codcia
				   AND r117_localidad = vg_codloc
				   AND r117_pedido    = rm_pedido[i].pedido
				   AND r117_numliq = rm_r28.r28_numliq
			END IF
			IF fob IS NULL THEN
				LET fob = 0
			END IF
			LET rm_r28.r28_fob_fabrica = rm_r28.r28_fob_fabrica + fob
		END FOR
		LET rm_r28.r28_total_fob = rm_r28.r28_fob_fabrica +
					   rm_r28.r28_faltante +
					   rm_r28.r28_flete  +
					   rm_r28.r28_otros
		LET salir = 1
END INPUT
IF INT_FLAG THEN
	LET salir = 1
END IF
END WHILE

CLOSE WINDOW w_207_2

END FUNCTION



FUNCTION graba_pedidos()

DEFINE i 		SMALLINT

DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT

DEFINE r_r29		RECORD LIKE rept029.*

LET intentar = 1
LET done = 0
WHILE (intentar)
	INITIALIZE r_r29.* TO NULL
	WHENEVER ERROR CONTINUE
		DECLARE q_pedxliq CURSOR FOR
			SELECT * FROM rept029
				WHERE r29_compania  = vg_codcia
				  AND r29_localidad = vg_codloc
				  AND r29_numliq    = rm_r28.r28_numliq
			FOR UPDATE
	OPEN  q_pedxliq 
	FETCH q_pedxliq INTO r_r29.*
	IF STATUS < 0 THEN
		WHENEVER ERROR STOP
		LET intentar = mensaje_intentar()
		CLOSE q_pedxliq
		FREE  q_pedxliq
	ELSE
		WHENEVER ERROR STOP
		CLOSE q_pedxliq
		LET intentar = 0
		LET done = 1
	END IF
END WHILE

IF NOT intentar AND NOT done THEN
	RETURN done 
END IF

OPEN  q_pedxliq 
FETCH q_pedxliq INTO r_r29.*
WHILE (STATUS <> NOTFOUND)
	LET done = actualiza_estado_pedido('L', 'R', r_r29.r29_pedido)
	IF NOT done THEN
		RETURN done
	END IF
	DELETE FROM rept029 WHERE CURRENT OF q_pedxliq

	UPDATE rept117 SET r117_numliq = NULL
	 WHERE r117_compania  = vg_codcia
	   AND r117_localidad = vg_codloc
	   AND r117_pedido    = r_r29.r29_pedido
	   AND r117_cod_tran  = 'IX'
	   AND r117_numliq    = rm_r28.r28_numliq

	INITIALIZE r_r29.* TO NULL
	FETCH q_pedxliq INTO r_r29.*
END WHILE
CLOSE q_pedxliq
FREE  q_pedxliq


INITIALIZE r_r29.* TO NULL
LET r_r29.r29_compania  = vg_codcia
LET r_r29.r29_localidad = vg_codloc
LET r_r29.r29_numliq    = rm_r28.r28_numliq
FOR i = 1 TO vm_ind_ped
	LET r_r29.r29_pedido = rm_pedido[i].pedido	
	IF r_r29.r29_pedido IS NULL THEN
		CONTINUE FOR
	END IF	

	INSERT INTO rept029 VALUES(r_r29.*)

	UPDATE rept117 SET r117_numliq = r_r29.r29_numliq
	 WHERE r117_compania  = vg_codcia
	   AND r117_localidad = vg_codloc
	   AND r117_pedido    = r_r29.r29_pedido
	   AND r117_numliq 	  IS NULL

	LET done = actualiza_estado_pedido('R', 'L', r_r29.r29_pedido)
	IF NOT done THEN
		RETURN done
	END IF
END FOR

RETURN done

END FUNCTION



FUNCTION etiquetas_pedido(i)

DEFINE i		SMALLINT

DEFINE r_g13		RECORD LIKE gent013.*
DEFINE tipo		CHAR(10)

CALL fl_lee_moneda(rm_pedido[i].moneda) RETURNING r_g13.*
LET rm_pedido[i].n_moneda = r_g13.g13_nombre

CASE rm_pedido[i].tipo
	WHEN 'S'
		LET rm_pedido[i].n_tipo = 'SUGERIDO'
	WHEN 'E'
		LET rm_pedido[i].n_tipo = 'EMERGENCIA'
	OTHERWISE
		INITIALIZE rm_pedido[i].n_tipo TO NULL
END CASE		 

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
