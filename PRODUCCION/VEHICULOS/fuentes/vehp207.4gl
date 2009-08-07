------------------------------------------------------------------------------
-- Titulo           : vehp207.4gl - DEVOLUCION DE FACTURAS
-- Elaboracion      : 17-dic-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun vehp207 base modulo compania localidad
--			Si se reciben 4 parametros se está ejecutando en 
--			modo independiente
--			Si se reciben 6 parametros, se asume que el quinto es
-- 			el codigo de la devolucion (transaccion origen)
--			y el sexto parametro es el numero de la devolucion
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)

DEFINE vm_transaccion   LIKE veht030.v30_cod_tran
DEFINE vm_dev_tran      LIKE veht030.v30_cod_tran

DEFINE vm_factura 	LIKE veht030.v30_cod_tran
DEFINE vm_dev_fact 	LIKE veht030.v30_cod_tran
DEFINE vm_num_tran	LIKE veht030.v30_num_tran

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA r_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS

DEFINE vm_max_rows	SMALLINT
DEFINE vm_max_ventas	SMALLINT
--
-- DEFINE RECORD(S) HERE
--
DEFINE rm_v00			RECORD LIKE veht000.*
DEFINE rm_v30			RECORD LIKE veht030.*

DEFINE vm_indice	SMALLINT
DEFINE rm_dev ARRAY[100] OF RECORD
	check			CHAR(1),
	codigo_veh  		LIKE veht031.v31_codigo_veh, 
	precio			LIKE veht031.v31_precio, 
	descuento		LIKE veht031.v31_descuento, 
	val_descto		LIKE veht031.v31_val_descto, 
	total			LIKE veht031.v31_precio
END RECORD



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 6 THEN  -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'vehp207'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
LET vg_codloc   = arg_val(4)

INITIALIZE vm_dev_tran TO NULL
LET vm_num_tran = 0
IF num_args() = 6 THEN
	LET vm_dev_tran = arg_val(5)
	LET vm_num_tran = arg_val(6)
END IF

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
OPEN WINDOW w_207 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_207 FROM '../forms/vehf207_1'
DISPLAY FORM f_207

LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_v30.* TO NULL
CALL muestra_contadores()

LET vm_max_rows   = 1000
LET vm_max_ventas = 100

CALL fl_lee_compania_vehiculos(vg_codcia) RETURNING rm_v00.*
IF rm_v00.v00_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 
		'No existe registro de configuración para esta compañía.',
		'exclamation')
	EXIT PROGRAM
END IF

-- OjO
LET vm_factura     = 'FA'

SELECT g21_codigo_dev INTO vm_dev_fact FROM gent021 
	WHERE g21_cod_tran = vm_factura
-- LET vm_dev_fact    = 'DF'

LET vm_transaccion = vm_dev_fact
IF num_args() <> 6 THEN
   	LET vm_dev_tran    = vm_factura
END IF
--

CALL setea_botones_f1()

IF num_args() = 6 THEN
	CALL consultar_devoluciones()
END IF

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		CALL control_ingreso()
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro.'
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
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

DEFINE rowid		INTEGER
DEFINE done		SMALLINT
DEFINE i		SMALLINT

CLEAR FORM
INITIALIZE rm_v30.* TO NULL

-- THESE VALUES WON'T CHANGE 
LET rm_v30.v30_compania   = vg_codcia
LET rm_v30.v30_localidad  = vg_codloc
LET rm_v30.v30_cod_tran   = vm_transaccion
LET rm_v30.v30_tipo_dev   = vm_dev_tran      
LET rm_v30.v30_flete      = 0
LET rm_v30.v30_usuario    = vg_usuario
LET rm_v30.v30_fecing     = CURRENT

CALL lee_datos('I')
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET rm_v30.v30_bodega_dest = rm_v30.v30_bodega_ori

CALL ingresa_detalle()
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF


-------------------
-- Para que solo grabe cuando haya algo que grabar
LET done = 0
FOR i = 1 TO vm_indice
	IF rm_dev[i].check = 'S' THEN
		LET done = 1
		EXIT FOR
	END IF
END FOR

IF NOT done THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF
----------------------

BEGIN WORK

LET rm_v30.v30_num_tran = nextValInSequence()
IF rm_v30.v30_num_tran = -1 THEN
	ROLLBACK WORK
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

INSERT INTO veht030 VALUES (rm_v30.*)
DISPLAY BY NAME rm_v30.v30_num_tran

LET rowid = SQLCA.SQLERRD[6] 			-- Rowid de la ultima fila 
                                             	-- procesada
LET done = graba_detalle()
IF NOT done THEN
	ROLLBACK WORK
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET done = actualiza_transaccion()
IF NOT done THEN
	ROLLBACK WORK
   	IF vm_num_rows = 0 THEN
	    	CLEAR FORM
    	ELSE	
	    	CALL lee_muestra_registro(vm_rows[vm_row_current])
    	END IF
	RETURN
END IF

CALL crea_nota_credito()
COMMIT WORK
CALL fl_control_master_contab_vehiculos(vg_codcia, vg_codloc, 
		rm_v30.v30_cod_tran, rm_v30.v30_num_tran)

IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF
LET vm_row_current = vm_num_rows
LET vm_rows[vm_num_rows] = rowid

CALL muestra_contadores()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION lee_datos(flag)

DEFINE flag 		CHAR(1)
DEFINE resp 		CHAR(6)

DEFINE r_v22		RECORD LIKE veht022.*
DEFINE r_v30		RECORD LIKE veht030.*

DEFINE r_vehfac RECORD
        v30_codcli              LIKE veht030.v30_codcli,
        z01_nomcli              LIKE cxct001.z01_nomcli,
        v22_codigo_veh          LIKE veht022.v22_codigo_veh,
        v22_modelo              LIKE veht022.v22_modelo
END RECORD

LET INT_FLAG = 0
INPUT BY NAME rm_v30.v30_cod_tran,   rm_v30.v30_num_tran,  rm_v30.v30_codcli,
	      rm_v30.v30_nomcli,     rm_v30.v30_vendedor,  rm_v30.v30_moneda,
	      rm_v30.v30_bodega_ori, rm_v30.v30_cont_cred, rm_v30.v30_tipo_dev,
	      rm_v30.v30_num_dev,    rm_v30.v30_usuario,   rm_v30.v30_fecing 
	WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(v30_num_dev) THEN
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
		IF INFIELD(v30_num_dev) THEN
			CALL fl_ayuda_serie_veh_facturados(vg_codcia, vg_codloc)
				RETURNING r_vehfac.*
		     	IF r_vehfac.v22_codigo_veh IS NOT NULL THEN
				CALL fl_lee_cod_vehiculo_veh(vg_codcia, 
					vg_codloc, r_vehfac.v22_codigo_veh)
					RETURNING r_v22.*
				IF r_v22.v22_codigo_veh IS NOT NULL THEN
					LET rm_v30.v30_tipo_dev = 
						r_v22.v22_cod_tran
					LET rm_v30.v30_num_dev  = 
						r_v22.v22_num_tran
					LET rm_v30.v30_nomcli   = 
						r_vehfac.z01_nomcli
					DISPLAY BY NAME rm_v30.v30_tipo_dev, 
							rm_v30.v30_num_dev,
							rm_v30.v30_nomcli
				END IF
			END IF
		END IF
		LET INT_FLAG = 0
	BEFORE INPUT
		CALL setea_botones_f1()
	AFTER FIELD v30_num_dev
		IF rm_v30.v30_num_dev IS NULL THEN
			INITIALIZE r_v30.* TO NULL
			CALL muestra_etiquetas(r_v30.*)
			DISPLAY BY NAME r_v30.v30_cont_cred
			CONTINUE INPUT
		END IF
		CALL fl_lee_cabecera_transaccion_veh(vg_codcia, vg_codloc, 
			rm_v30.v30_tipo_dev, rm_v30.v30_num_dev)
			RETURNING r_v30.*
		IF r_v30.v30_cod_tran IS NULL THEN
			CALL fgl_winmessage(vg_producto,
				'No existe factura.',
				'exclamation')
			INITIALIZE r_v30.* TO NULL
			CALL muestra_etiquetas(r_v30.*)
			DISPLAY BY NAME r_v30.v30_cont_cred
			NEXT FIELD v30_num_dev
		END IF
		IF TODAY > date(r_v30.v30_fecing) + rm_v00.v00_dias_dev THEN
			CALL fgl_winmessage(vg_producto,
				'Ha excedido el limite de tiempo permitido ' ||
				'para realizar devoluciones.',
				'exclamation')
			INITIALIZE r_v30.* TO NULL 
			CALL muestra_etiquetas(r_v30.*)
			DISPLAY BY NAME r_v30.v30_cont_cred
			NEXT FIELD v30_num_dev
		END IF
		IF rm_v00.v00_dev_mes = 'S' THEN
			IF month(r_v30.v30_fecing) <> month(TODAY) THEN
				CALL fgl_winmessage(vg_producto,
					'La devolución debe realizarse ' ||
					'en el mismo mes en que se realizó ' ||
					'la venta.',
					'exclamation')
				INITIALIZE r_v30.* TO NULL 
				CALL muestra_etiquetas(r_v30.*)
				DISPLAY BY NAME r_v30.v30_cont_cred
				NEXT FIELD v30_num_dev
			END IF
		END IF
		LET rm_v30.v30_tipo_dev    = vm_dev_tran
		LET rm_v30.v30_cont_cred   = r_v30.v30_cont_cred
		LET rm_v30.v30_descuento   = r_v30.v30_descuento
		LET rm_v30.v30_porc_impto  = r_v30.v30_porc_impto
		LET rm_v30.v30_bodega_ori  = r_v30.v30_bodega_ori
		LET rm_v30.v30_moneda      = r_v30.v30_moneda
		LET rm_v30.v30_paridad     = r_v30.v30_paridad
		LET rm_v30.v30_precision   = r_v30.v30_precision
		LET rm_v30.v30_codcli      = r_v30.v30_codcli
		LET rm_v30.v30_nomcli      = r_v30.v30_nomcli
		LET rm_v30.v30_dircli      = r_v30.v30_dircli    
		LET rm_v30.v30_cedruc      = r_v30.v30_cedruc     
		LET rm_v30.v30_telcli      = r_v30.v30_telcli     
		LET rm_v30.v30_vendedor    = r_v30.v30_vendedor
		LET rm_v30.v30_bodega_ori  = r_v30.v30_bodega_ori
		DISPLAY BY NAME rm_v30.v30_cont_cred
		CALL muestra_etiquetas(rm_v30.*)
		CALL setea_botones_f1()
END INPUT

END FUNCTION



FUNCTION control_consulta()

DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_v01		RECORD LIKE veht001.*
DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)

CLEAR FORM

LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql 
           ON v30_cod_tran,   v30_num_tran,  v30_tipo_dev, v30_num_dev,
              v30_codcli,     v30_nomcli,    v30_vendedor, v30_moneda,   
              v30_bodega_ori, v30_cont_cred, v30_usuario       
	ON KEY(F2)
		IF INFIELD(v30_codcli) THEN
         	  	CALL fl_ayuda_cliente_localidad(vg_codcia, vg_codloc) 
				RETURNING r_z01.z01_codcli, r_z01.z01_nomcli
			IF r_z01.z01_codcli IS NOT NULL THEN
                  		LET rm_v30.v30_codcli = r_z01.z01_codcli
				LET rm_v30.v30_nomcli = r_z01.z01_nomcli
                 		DISPLAY BY NAME rm_v30.v30_codcli, 
						rm_v30.v30_nomcli  
			END IF
            	END IF
            	IF INFIELD(v30_vendedor) THEN
         	  	CALL fl_ayuda_vendedores_veh(vg_codcia) 
				RETURNING r_v01.v01_vendedor, r_v01.v01_nombres
			IF r_v01.v01_vendedor IS NOT NULL THEN
                  		LET rm_v30.v30_vendedor = r_v01.v01_vendedor
                 		DISPLAY BY NAME rm_v30.v30_vendedor  
				DISPLAY r_v01.v01_nombres TO n_vendedor
			END IF
            	END IF
		IF INFIELD(v30_moneda) THEN
			CALL fl_ayuda_monedas() 
				RETURNING r_mon.g13_moneda, r_mon.g13_nombre, 
					  r_mon.g13_decimales 
			IF r_mon.g13_moneda IS NOT NULL THEN
				LET rm_v30.v30_moneda = r_mon.g13_moneda
				DISPLAY BY NAME rm_v30.v30_moneda
				DISPLAY r_mon.g13_nombre TO n_moneda
			END IF	
		END IF
		LET int_flag = 0
END CONSTRUCT

IF INT_FLAG THEN
	CLEAR FORM
	IF vm_row_current > 0 THEN
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET query = 'SELECT *, ROWID FROM veht030 ', 
	    	' WHERE v30_compania  = ', vg_codcia,
		'   AND v30_localidad = ', vg_codloc,
		'   AND v30_cod_tran  = "', vm_transaccion, '"',
                '   AND v30_tipo_dev  = "', vm_dev_tran, '"',
		'   AND ', expr_sql CLIPPED,
		' ORDER BY 1, 2, 3, 4' 

PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_v30.*, vm_rows[vm_num_rows]
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

SELECT * INTO rm_v30.* FROM veht030 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

DISPLAY BY NAME rm_v30.v30_cod_tran,
		rm_v30.v30_num_tran,
		rm_v30.v30_codcli,
		rm_v30.v30_nomcli,
		rm_v30.v30_vendedor,
		rm_v30.v30_moneda,
		rm_v30.v30_bodega_ori,
		rm_v30.v30_cont_cred,
		rm_v30.v30_tipo_dev,
		rm_v30.v30_num_dev,
		rm_v30.v30_usuario,
		rm_v30.v30_fecing 
		
CALL muestra_detalle()
CALL muestra_etiquetas(rm_v30.*)
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



FUNCTION consultar_devoluciones()

LET vm_num_rows    = 1
LET vm_row_current = 1

DECLARE q_dev2 CURSOR FOR
	SELECT *, ROWID FROM veht030
		WHERE v30_compania  = vg_codcia
		  AND v30_localidad = vg_codloc
		  AND v30_cod_tran  = vm_dev_tran
		  AND v30_num_tran  = vm_num_tran
		ORDER BY 1, 2, 3, 4
		  
FOREACH q_dev2 INTO rm_v30.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
	IF vm_num_rows > vm_max_rows THEN
		EXIT FOREACH
	END IF
END FOREACH
FREE q_dev2

LET vm_num_rows = vm_num_rows - 1

IF vm_num_rows = 0 THEN
	CALL fgl_winmessage(vg_producto,
		'No existen devoluciones para esta factura.',
		'info')
	EXIT PROGRAM
END IF

CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION nextValInSequence()

DEFINE resp		CHAR(6)
DEFINE retVal 		SMALLINT

LET retVal = -1
WHILE retVal = -1

LET retVal = fl_actualiza_control_secuencias(vg_codcia, vg_codloc, vg_modulo,
		'AA', vm_transaccion)
IF retVal = 0 THEN
	EXIT PROGRAM
END IF
IF retVal <> -1 THEN
	 EXIT WHILE
END IF

CALL fgl_winquestion(vg_producto, 'La tabla de secuencias de transacciones ' ||
                     'está siendo accesada por otro usuario, espere unos  ' ||
                     'segundos y vuelva a intentar', 'No', 'Yes|No|Cancel',
                     'question', 1) RETURNING resp 
IF resp <> 'Yes' THEN
	EXIT WHILE	
END IF

END WHILE

RETURN retVal

END FUNCTION



FUNCTION crea_nota_credito()
DEFINE linea		LIKE veht020.v20_linea
DEFINE r_lin		RECORD LIKE veht003.*
DEFINE r_glin		RECORD LIKE gent020.*
DEFINE r_nc		RECORD LIKE cxct021.*
DEFINE r		RECORD LIKE gent014.*
DEFINE r_v06		RECORD LIKE veht006.*
DEFINE num_nc		INTEGER
DEFINE num_row		INTEGER
DEFINE valor_credito	DECIMAL(14,2)	
DEFINE valor_aplicado	DECIMAL(14,2)	
DEFINE numprev		LIKE veht026.v26_numprev
DEFINE codigo_plan	LIKE veht006.v06_codigo_plan
DEFINE tot_pa_nc	DECIMAL(14,2)
DEFINE tot_int		DECIMAL(12,2)

SELECT v26_tot_pa_nc, v26_codigo_plan, v26_numprev 
	INTO tot_pa_nc, codigo_plan, numprev FROM veht026
	WHERE v26_compania  = vg_codcia AND
	      v26_localidad = vg_codloc AND
	      v26_cod_tran  = rm_v30.v30_tipo_dev AND
	      v26_num_tran  = rm_v30.v30_num_dev
IF status = NOTFOUND THEN
	CALL fgl_winmessage(vg_producto, 'No existe preventa','stop')
	ROLLBACK WORK
	EXIT PROGRAM
END IF
INITIALIZE r_v06.* TO NULL
IF codigo_plan IS NOT NULL THEN
	CALL fl_lee_plan_financiamiento(vg_codcia, codigo_plan)
		RETURNING r_v06.*
	IF r_v06.v06_compania IS NULL THEN
		CALL fgl_winmessage(vg_producto, 'No existe código plan','stop')
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
END IF
SELECT SUM(v28_val_int) INTO tot_int FROM veht028
	WHERE v28_compania  = vg_codcia AND
	      v28_localidad = vg_codloc AND
	      v28_numprev   = numprev
IF tot_int IS NULL THEN
	LET tot_int = 0
END IF
DECLARE q_dfg CURSOR FOR 
	SELECT v20_linea 
		FROM veht031, veht022, veht020
		WHERE v31_compania   = vg_codcia           
		  AND v31_localidad  = vg_codloc           
		  AND v31_cod_tran   = rm_v30.v30_tipo_dev 
		  AND v31_num_tran   = rm_v30.v30_num_dev   
		  AND v22_compania   = v31_compania
		  AND v22_localidad  = v31_localidad
		  AND v22_codigo_veh = v31_codigo_veh
		  AND v20_compania   = v22_compania
		  AND v20_modelo     = v22_modelo
	  
OPEN  q_dfg
FETCH q_dfg INTO linea
CLOSE q_dfg
FREE  q_dfg
CALL fl_lee_linea_veh(vg_codcia, linea) RETURNING r_lin.*
CALL fl_lee_grupo_linea(vg_codcia, r_lin.v03_grupo_linea)
	RETURNING r_glin.*
CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, 'CO', 'AA', 'NC')
	RETURNING num_nc
IF num_nc <= 0 THEN
	ROLLBACK WORK
	EXIT PROGRAM
END IF
INITIALIZE r_nc.* TO NULL
LET r_nc.z21_compania 	= vg_codcia
LET r_nc.z21_localidad 	= vg_codloc
LET r_nc.z21_codcli     = rm_v30.v30_codcli 
IF tot_pa_nc = 0 THEN
	IF r_v06.v06_codigo_cobr IS NOT NULL THEN
		LET r_nc.z21_codcli = r_v06.v06_codigo_cobr
	END IF
END IF
LET r_nc.z21_tipo_doc 	= 'NC'
LET r_nc.z21_num_doc 	= num_nc 
LET r_nc.z21_areaneg 	= r_glin.g20_areaneg
LET r_nc.z21_linea 	= r_glin.g20_grupo_linea
LET r_nc.z21_referencia = 'DEV. FACTURA: ', rm_v30.v30_tipo_dev, ' ',
			   rm_v30.v30_num_dev USING '<<<<<<<<<<<<<&'
LET r_nc.z21_fecha_emi 	= TODAY
LET r_nc.z21_moneda 	= rm_v30.v30_moneda
LET r_nc.z21_paridad 	= 1
IF r_nc.z21_moneda <> rg_gen.g00_moneda_base THEN
	CALL fl_lee_factor_moneda(r_nc.z21_moneda, rg_gen.g00_moneda_base)
		RETURNING r.*
	IF r.g14_serial IS NULL THEN
		CALL fgl_winmessage(vg_producto, 'No hay factor de conversión','stop')
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
	LET r_nc.z21_paridad 	= r.g14_tasa
END IF	
LET valor_credito       = rm_v30.v30_tot_neto + tot_int
LET r_nc.z21_valor 	= valor_credito
IF tot_pa_nc > 0 AND r_v06.v06_codigo_cobr IS NOT NULL THEN
	LET r_nc.z21_valor = tot_pa_nc
END IF 
LET r_nc.z21_saldo 	= r_nc.z21_valor
LET r_nc.z21_subtipo 	= 1
LET r_nc.z21_origen 	= 'A'
LET r_nc.z21_usuario 	= vg_usuario
LET r_nc.z21_fecing 	= CURRENT
INSERT INTO cxct021 VALUES (r_nc.*)
LET num_row = SQLCA.SQLERRD[6]
CALL fl_aplica_documento_favor(vg_codcia, vg_codloc, r_nc.z21_codcli, 
			    r_nc.z21_tipo_doc, r_nc.z21_num_doc, r_nc.z21_valor,
			    r_nc.z21_moneda, r_glin.g20_areaneg,
			    rm_v30.v30_tipo_dev, rm_v30.v30_num_dev)  
	RETURNING valor_aplicado
IF valor_aplicado < 0 THEN
	ROLLBACK WORK
	EXIT PROGRAM
END IF
UPDATE cxct021 SET z21_saldo = z21_saldo - valor_aplicado
	WHERE ROWID = num_row
CALL fl_genera_saldos_cliente(vg_codcia, vg_codloc, r_nc.z21_codcli)
IF tot_pa_nc > 0 AND r_v06.v06_codigo_cobr IS NOT NULL THEN
	CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, 'CO', 'AA', 'NC')
		RETURNING num_nc
	IF num_nc <= 0 THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
	LET r_nc.z21_num_doc = num_nc
	LET r_nc.z21_codcli  = r_v06.v06_codigo_cobr
	LET r_nc.z21_valor   = valor_credito - tot_pa_nc
	LET r_nc.z21_saldo   = r_nc.z21_valor
	INSERT INTO cxct021 VALUES (r_nc.*)
	LET num_row = SQLCA.SQLERRD[6]
	CALL fl_aplica_documento_favor(vg_codcia, vg_codloc, r_nc.z21_codcli, 
			    r_nc.z21_tipo_doc, r_nc.z21_num_doc, r_nc.z21_valor,
			    r_nc.z21_moneda, r_glin.g20_areaneg,
			    rm_v30.v30_tipo_dev, rm_v30.v30_num_dev)  
		RETURNING valor_aplicado
	IF valor_aplicado < 0 THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
	UPDATE cxct021 SET z21_saldo = z21_saldo - valor_aplicado
		WHERE ROWID = num_row
	CALL fl_genera_saldos_cliente(vg_codcia, vg_codloc, r_nc.z21_codcli)
END IF 

END FUNCTION



FUNCTION setea_botones_f1()

DISPLAY 'Código Veh.'  TO bt_codigo_veh
DISPLAY 'Precio Venta' TO bt_precio_venta
DISPLAY 'Dscto.'       TO bt_dscto 
DISPLAY 'Val. Dscto.'  TO bt_val_dscto
DISPLAY 'Total'        TO bt_total

END FUNCTION



FUNCTION muestra_etiquetas(r_v30)

DEFINE r_v30		RECORD LIKE veht030.*
DEFINE r_v01		RECORD LIKE veht001.*
DEFINE r_v02		RECORD LIKE veht002.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_z01		RECORD LIKE cxct001.*

IF r_v30.v30_num_dev IS NULL THEN
	INITIALIZE rm_v30.v30_codcli,
		   rm_v30.v30_nomcli, 
		   rm_v30.v30_dircli,       
		   rm_v30.v30_telcli,      
		   rm_v30.v30_cedruc,     
		   rm_v30.v30_moneda
		TO NULL
	CLEAR n_moneda, n_vendedor, n_bodega
ELSE
	CALL fl_lee_bodega_veh(vg_codcia, r_v30.v30_bodega_ori) 
		RETURNING r_v02.*
	DISPLAY r_v02.v02_nombre TO n_bodega

	CALL fl_lee_vendedor_veh(vg_codcia, r_v30.v30_vendedor) 
		RETURNING r_v01.*
	DISPLAY r_v01.v01_nombres TO n_vendedor

	CALL fl_lee_moneda(r_v30.v30_moneda) RETURNING r_g13.*
	DISPLAY r_g13.g13_nombre TO n_moneda    
END IF

DISPLAY BY NAME r_v30.v30_moneda,
		r_v30.v30_codcli,
		r_v30.v30_nomcli,
		r_v30.v30_vendedor,
		r_v30.v30_bodega_ori

CALL setea_botones_f1()

END FUNCTION



FUNCTION ingresa_detalle()

DEFINE resp 		CHAR(6)
DEFINE i    		SMALLINT
DEFINE j    		SMALLINT
DEFINE k    		SMALLINT
DEFINE salir		SMALLINT

DEFINE c		CHAR(1)

DEFINE r_v22		RECORD LIKE veht022.*

LET vm_indice = lee_detalle_factura() 
IF INT_FLAG THEN
	RETURN
END IF

IF vm_indice = 0 THEN
	CALL fgl_winmessage(vg_producto,
		'Esta factura ya fue devuelta por completo.',
		'exclamation')
	LET INT_FLAG = 1
	RETURN
END IF

OPTIONS 
	INSERT KEY F30,
	DELETE KEY F31

LET salir = 0
WHILE NOT salir
	LET i = 1
	LET j = 1
	LET INT_FLAG = 0
	CALL set_count(vm_indice)
	INPUT ARRAY rm_dev WITHOUT DEFAULTS FROM ra_dev.*
		ON KEY(INTERRUPT)
			LET INT_FLAG = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET INT_FLAG = 1
				EXIT INPUT
			END IF
		BEFORE INPUT
			CALL dialog.keysetlabel('INSERT', '')
			CALL dialog.keysetlabel('DELETE', '')
			CALL calcula_totales(vm_indice)
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
			CALL fl_lee_cod_vehiculo_veh(vg_codcia, vg_codloc,
				rm_dev[i].codigo_veh) RETURNING r_v22.*
			DISPLAY r_v22.v22_modelo    TO modelo
			DISPLAY r_v22.v22_chasis    TO serie
			DISPLAY r_v22.v22_cod_color TO color
		BEFORE FIELD check
			LET c = rm_dev[i].check
		AFTER FIELD check
			IF c <> rm_dev[i].check THEN
				CALL calcula_totales(vm_indice)
				NEXT FIELD ra_dev[j-1].check
			END IF
		BEFORE DELETE	
			EXIT INPUT
		BEFORE INSERT
			EXIT INPUT	
		AFTER INPUT
			CALL calcula_totales(vm_indice)

-- OjO
-- validacion para evitar problemas en presentaciones
-- sera eliminada en cuanto se manejen las
-- devoluciones parciales
		for i = 1 to vm_indice  
			if rm_dev[i].check = 'N' then
				call fgl_winmessage(vg_producto,
					'Deben devolverse todos los ' ||
					'items.',
					'exclamation') 
				continue input	
			end if
		end for
--
			LET salir = 1
	END INPUT

	IF INT_FLAG THEN
		RETURN
	END IF
END WHILE

END FUNCTION



FUNCTION lee_detalle_factura()

DEFINE i		SMALLINT

DECLARE q_dev CURSOR FOR
	SELECT 'N', v31_codigo_veh, v31_precio, v31_descuento, v31_val_descto,
		(v31_precio - v31_val_descto)  
		FROM veht031, veht022
		WHERE v31_compania   = vg_codcia
		  AND v31_localidad  = vg_codloc
		  AND v31_cod_tran   = rm_v30.v30_tipo_dev
		  AND v31_num_tran   = rm_v30.v30_num_dev
		  AND v22_compania   = v31_compania 
		  AND v22_localidad  = v31_localidad
		  AND v22_codigo_veh = v31_codigo_veh
		  AND v22_estado     = 'F'
		  AND v22_cod_tran   = v31_cod_tran
		  AND v22_num_tran   = v31_num_tran
		  
LET i = 1
FOREACH q_dev INTO rm_dev[i].*
	LET i = i + 1
	IF i > vm_max_ventas THEN
		CALL fl_mensaje_arreglo_incompleto()
		EXIT PROGRAM
	END IF
END FOREACH

LET i = i - 1

RETURN i

END FUNCTION



FUNCTION calcula_totales(num_elm)

DEFINE num_elm		SMALLINT
DEFINE i      	 	SMALLINT

DEFINE r_v22		RECORD LIKE veht022.*

DEFINE bruto		LIKE veht030.v30_tot_bruto
DEFINE total		LIKE veht030.v30_tot_neto
DEFINE descto       	LIKE veht030.v30_tot_dscto
DEFINE precio		LIKE veht030.v30_tot_bruto
DEFINE costo		LIKE veht030.v30_tot_costo
	
DEFINE iva          	LIKE veht030.v30_tot_dscto

LET total     = 0	-- TOTAL NETO  
LET bruto     = 0 	-- TOTAL BRUTO     
LET iva       = 0
LET descto    = 0
LET precio    = 0
LET costo     = 0

FOR i = 1 TO num_elm
	IF rm_dev[i].check = 'S' THEN
		LET bruto  = bruto  + rm_dev[i].total
		LET descto = descto + rm_dev[i].val_descto
		LET precio = precio + rm_dev[i].precio
		CALL fl_lee_cod_vehiculo_veh(vg_codcia, vg_codloc,
			rm_dev[i].codigo_veh) RETURNING r_v22.*
		LET costo = costo + (r_v22.v22_costo_ing +
				     r_v22.v22_cargo_ing + 
				     r_v22.v22_costo_adi)
	END IF
END FOR

LET bruto  = fl_retorna_precision_valor(rm_v30.v30_moneda, bruto)
LET descto = fl_retorna_precision_valor(rm_v30.v30_moneda, descto)
LET precio = fl_retorna_precision_valor(rm_v30.v30_moneda, precio)
LET costo  = fl_retorna_precision_valor(rm_v30.v30_moneda, costo)

LET iva   = bruto * (rm_v30.v30_porc_impto / 100)

LET total = bruto + iva

LET rm_v30.v30_tot_dscto  = descto
LET rm_v30.v30_tot_bruto  = bruto 
LET rm_v30.v30_tot_neto   = total
LET rm_v30.v30_tot_costo  = costo

DISPLAY BY NAME rm_v30.v30_tot_bruto,
                iva,
                rm_v30.v30_tot_neto
                
END FUNCTION



FUNCTION graba_detalle()

DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT
DEFINE i		SMALLINT
DEFINE r_v20		RECORD LIKE veht020.*
DEFINE r_v22		RECORD LIKE veht022.*
DEFINE r_v31		RECORD LIKE veht031.*

LET intentar = 1
LET done = 0
WHILE (intentar)
	WHENEVER ERROR CONTINUE
		DECLARE q_v31 CURSOR FOR
			SELECT * FROM veht031
				WHERE v31_compania  = vg_codcia         
				  AND v31_localidad = vg_codloc          
				  AND v31_cod_tran  = rm_v30.v30_cod_tran
				  AND v31_num_tran  = rm_v30.v30_num_tran
			FOR UPDATE
	WHENEVER ERROR STOP
	IF STATUS < 0 THEN
		LET intentar = mensaje_intentar()
	ELSE
		LET intentar = 0
		LET done = 1
	END IF
END WHILE

IF NOT intentar AND NOT done THEN
	RETURN done
END IF

FOREACH q_v31
	DELETE FROM veht031 WHERE CURRENT OF q_v31
END FOREACH

LET r_v31.v31_compania  = vg_codcia
LET r_v31.v31_localidad = vg_codloc
LET r_v31.v31_cod_tran  = rm_v30.v30_cod_tran
LET r_v31.v31_num_tran  = rm_v30.v30_num_tran

LET r_v31.v31_costant_mb = 0
LET r_v31.v31_costant_ma = 0
LET r_v31.v31_costnue_mb = 0
LET r_v31.v31_costnue_ma = 0
LET r_v31.v31_fob	 = 0

FOR i = 1 TO vm_indice
	IF rm_dev[i].check = 'N' THEN
		CONTINUE FOR
	END IF

	LET r_v31.v31_codigo_veh = rm_dev[i].codigo_veh
	CALL fl_lee_cod_vehiculo_veh(vg_codcia, vg_codloc, rm_dev[i].codigo_veh)
		RETURNING r_v22.*
	CALL fl_lee_modelo_veh(r_v22.v22_compania, r_v22.v22_modelo)
		RETURNING r_v20.*
	LET r_v20.v20_stock = r_v20.v20_stock - 1
	IF r_v20.v20_stock < 0 THEN
		LET r_v20.v20_stock = 0
	END IF
	UPDATE veht020 SET v20_stock = r_v20.v20_stock
		WHERE v20_compania   = r_v20.v20_compania AND 
		      v20_modelo     = r_v20.v20_modelo
	
	LET done = actualiza_existencias(rm_dev[i].codigo_veh)
	IF NOT done THEN
		RETURN done
	END IF

    	LET r_v31.v31_nuevo       = r_v22.v22_nuevo
    	LET r_v31.v31_descuento   = rm_dev[i].descuento
    	LET r_v31.v31_val_descto  = rm_dev[i].val_descto
    	LET r_v31.v31_precio      = rm_dev[i].precio
    	LET r_v31.v31_moneda_cost = r_v22.v22_moneda_ing
   	LET r_v31.v31_costo       = r_v22.v22_costo_ing +
   				    r_v22.v22_cargo_ing +
   				    r_v22.v22_costo_adi
    	
	INSERT INTO veht031 VALUES (r_v31.*)
END FOR 

RETURN done

END FUNCTION



FUNCTION actualiza_existencias(codigo_veh)

DEFINE codigo_veh	LIKE veht022.v22_codigo_veh
DEFINE done 		SMALLINT

LET done = 0

SET LOCK MODE TO WAIT 3
WHENEVER ERROR CONTINUE
	DECLARE q_v22 CURSOR FOR
		SELECT * FROM veht022
			WHERE v22_compania   = vg_codcia
			  AND v22_localidad  = vg_codloc
			  AND v22_codigo_veh = codigo_veh
		FOR UPDATE OF v22_estado, v22_cod_tran, v22_num_tran
WHENEVER ERROR STOP
SET LOCK MODE TO NOT WAIT

IF STATUS < 0 THEN
	RETURN done
END IF

LET done = 1

OPEN  q_v22
FETCH q_v22

	UPDATE veht022 SET v22_estado = 'A',
			   v22_cod_tran = NULL,
			   v22_num_tran = NULL
		WHERE CURRENT OF q_v22
		
CLOSE q_v22
FREE  q_v22
	
RETURN done
	
END FUNCTION



FUNCTION actualiza_transaccion()

DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT

DEFINE i		SMALLINT

LET intentar = 1
LET done = 0
WHILE (intentar)
	WHENEVER ERROR CONTINUE
		DECLARE q_v30 CURSOR FOR
			SELECT * FROM veht030
				WHERE v30_compania  = vg_codcia         
				  AND v30_localidad = vg_codloc          
				  AND v30_cod_tran  = rm_v30.v30_tipo_dev
				  AND v30_num_tran  = rm_v30.v30_num_dev 
			FOR UPDATE
	WHENEVER ERROR STOP
	IF STATUS < 0 THEN
		LET intentar = mensaje_intentar()
	ELSE
		LET intentar = 0
		LET done = 1
	END IF
END WHILE

IF NOT intentar AND NOT done THEN
	RETURN done
END IF

OPEN  q_v30
FETCH q_v30 
    	UPDATE veht030 SET v30_tipo_dev = rm_v30.v30_cod_tran,
			   v30_num_dev  = rm_v30.v30_num_tran
		WHERE CURRENT OF q_v30
CLOSE q_v30
FREE  q_v30

RETURN done

END FUNCTION



FUNCTION mensaje_intentar()

DEFINE intentar		SMALLINT
DEFINE resp		CHAR(6)

LET intentar = 1
CALL fgl_winquestion(vg_producto, 
		     'Registro bloqueado por otro usuario, desea ' ||
                     'intentarlo nuevamente', 'No', 'Yes|No', 'question', 1)
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



FUNCTION muestra_detalle()

DEFINE i			SMALLINT
DEFINE filas_pant		SMALLINT

LET filas_pant = fgl_scr_size('ra_dev')

FOR i = 1 TO filas_pant 
	INITIALIZE rm_dev[i].* TO NULL
	LET rm_dev[i].check = 'N' 
	CLEAR ra_dev[i].*
END FOR

DECLARE q_dev3 CURSOR FOR
	SELECT 'S', v31_codigo_veh, v31_precio, v31_descuento, v31_val_descto,
		(v31_precio - v31_val_descto)  
		FROM veht031
		WHERE v31_compania  = rm_v30.v30_compania  
		  AND v31_localidad = rm_v30.v30_localidad
		  AND v31_cod_tran  = rm_v30.v30_cod_tran 
		  AND v31_num_tran  = rm_v30.v30_num_tran

LET i = 1
FOREACH q_dev3 INTO rm_dev[i].*
	LET i = i + 1
	IF i > vm_max_ventas THEN
		EXIT FOREACH
	END IF
END FOREACH
FREE q_dev3

LET i = i - 1
IF i = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF

LET vm_indice = i
IF i < filas_pant THEN
	LET filas_pant = i
END IF

CALL calcula_totales(vm_indice)

FOR i = 1 TO filas_pant
	DISPLAY rm_dev[i].* TO ra_dev[i].*
END FOR

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
