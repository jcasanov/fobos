------------------------------------------------------------------------------
-- Titulo           : talp212.4gl - Gastos de viaje asignadas a una O.T.    
-- Elaboracion      : 12-abr-2002
-- Autor            : JCM
-- Formato Ejecucion: fglrun talp212 base modulo compania localidad [orden]
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

DEFINE vm_orden    	LIKE talt030.t30_num_ot   
--
-- DEFINE RECORD(S) HERE
--
DEFINE rm_t23			RECORD LIKE talt023.*
DEFINE rm_t30			RECORD LIKE talt030.*

DEFINE vm_max_gastos 	SMALLINT
DEFINE vm_ind_gastos	SMALLINT
DEFINE rm_gastos ARRAY[250] OF RECORD
	descripcion		LIKE talt031.t31_descripcion,
	moneda			LIKE talt031.t31_moneda,
	valor			LIKE talt031.t31_valor,
	valor_mb		LIKE talt031.t31_valor
END RECORD

DEFINE vm_max_mec	SMALLINT
DEFINE vm_ind_mec	SMALLINT
DEFINE rm_mecanico ARRAY[15] OF RECORD
	cod_mecanico		LIKE talt003.t03_mecanico,
	nom_mecanico		LIKE talt003.t03_nombres,
	principal		CHAR(1)
END RECORD



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp212.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 THEN -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
INITIALIZE vm_orden TO NULL
IF num_args() = 5 THEN
	LET vm_orden = arg_val(5)
END IF
LET vg_proceso = 'talp212'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc

CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

DEFINE query		VARCHAR(600)

CALL fl_nivel_isolation()
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_212 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_212 FROM '../forms/talf212_1'
DISPLAY FORM f_212

LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores()

CALL setea_nombre_botones_f1()

LET vm_max_rows   = 1000
LET vm_max_gastos = 250
LET vm_max_mec    = 15

IF vm_orden IS NOT NULL THEN
	LET query = 'SELECT *, ROWID FROM talt030 ',
		    '	WHERE t30_compania  = ', vg_codcia,
	    		' AND t30_localidad = ', vg_codloc,
	    	        ' AND t30_num_ot    = ', vm_orden, 
			' AND t30_estado    = "A" ',
	            '	ORDER BY 1, 2, 3 '
	CALL execute_query(query)
	IF vm_num_rows = 0 THEN
		EXIT PROGRAM
	END IF
END IF

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Eliminar'
		HIDE OPTION 'Detalle'
		HIDE OPTION 'Imprimir'
		IF vm_orden IS NOT NULL THEN -- Se ejecuta en modo de solo
			HIDE OPTION 'Ingresar'   -- consulta
			HIDE OPTION 'Modificar'
			HIDE OPTION 'Eliminar'
			HIDE OPTION 'Consultar'
			IF vm_ind_gastos > fgl_scr_size('ra_gastos') THEN
				SHOW OPTION 'Detalle'
			END IF
			IF vm_num_rows > 1 THEN
				SHOW OPTION 'Avanzar'
			END IF
		END IF
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Eliminar'
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
		IF vm_num_rows > 0 THEN
		   IF fl_control_permiso_opcion('Imprimir') THEN
			   SHOW OPTION 'Imprimir'
		   END IF
		
		ELSE
			HIDE OPTION 'Imprimir'
		END IF
		IF vm_ind_gastos > fgl_scr_size('ra_gastos') THEN
			SHOW OPTION 'Detalle'
		END IF
		CALL setea_nombre_botones_f1()
	COMMAND KEY('M') 'Modificar' 		'Modificar registro corriente.'
		CALL control_modificacion()
		CALL setea_nombre_botones_f1()
	COMMAND KEY('E') 'Eliminar'		'Elimina registro corriente.'
		CALL control_eliminacion()
		CALL setea_nombre_botones_f1()
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro.'
		HIDE OPTION 'Detalle'
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
		   IF fl_control_permiso_opcion('Modificar') THEN			
			SHOW OPTION 'Modificar'
		   END IF 

		   IF fl_control_permiso_opcion('Eliminar') THEN
			SHOW OPTION 'Eliminar'
		   END IF
			
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Eliminar'
			END IF
		ELSE
		   IF fl_control_permiso_opcion('Modificar') THEN			
			SHOW OPTION 'Modificar'
		   END IF 

		   IF fl_control_permiso_opcion('Eliminar') THEN
			SHOW OPTION 'Eliminar'
		   END IF
			SHOW OPTION 'Avanzar'
		
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
		IF vm_num_rows > 0 THEN

		   IF fl_control_permiso_opcion('Imprimir') THEN
			   SHOW OPTION 'Imprimir'
		   END IF
			
		ELSE
			HIDE OPTION 'Imprimir'
		END IF
		IF vm_ind_gastos > fgl_scr_size('ra_gastos') THEN
			SHOW OPTION 'Detalle'
		END IF
		CALL setea_nombre_botones_f1()
	COMMAND KEY('V') 'Ver Mecánicos'	'Ver grupo de trabajo.'
		CALL control_grupo_trabajo('C')
	COMMAND KEY('D') 'Detalle'		'Ver detalle del comprobante.'
		CALL control_detalle()
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
		HIDE OPTION 'Detalle'
		CALL siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_ind_gastos > fgl_scr_size('ra_gastos') THEN
			SHOW OPTION 'Detalle'
		END IF
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
		HIDE OPTION 'Detalle'
		CALL anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_ind_gastos > fgl_scr_size('ra_gastos') THEN
			SHOW OPTION 'Detalle'
		END IF
	COMMAND KEY('P') 'Imprimir'
		CALL control_imprimir()                  
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()

DEFINE rowid		INTEGER
DEFINE done 		SMALLINT
DEFINE j		SMALLINT

CLEAR FORM
INITIALIZE rm_t30.* TO NULL
CALL setea_nombre_botones_f1()

LET rm_t30.t30_compania  = vg_codcia
LET rm_t30.t30_localidad = vg_codloc
LET rm_t30.t30_estado    = 'A'
LET rm_t30.t30_usuario   = vg_usuario
LET rm_t30.t30_fecing    = CURRENT
CALL muestra_etiquetas()

INITIALIZE vm_ind_mec TO NULL

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

CALL atrapa_orden(vg_codcia, vg_codloc, rm_t23.t23_orden)
IF rm_t23.t23_compania IS NULL THEN
	ROLLBACK WORK
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

CALL ingresa_detalle('I')
IF INT_FLAG THEN
	ROLLBACK WORK
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

SELECT MAX(t30_num_gasto) INTO rm_t30.t30_num_gasto
	FROM talt030
	WHERE t30_compania  = vg_codcia
	  AND t30_localidad = vg_codloc
IF rm_t30.t30_num_gasto IS NULL THEN
	LET rm_t30.t30_num_gasto = 1
ELSE
	LET rm_t30.t30_num_gasto = rm_t30.t30_num_gasto + 1
END IF

INSERT INTO talt030 VALUES (rm_t30.*)

LET rowid = SQLCA.SQLERRD[6] 		-- Rowid de la ultima fila
	                        	-- procesada
LET done = grabar_detalle()
IF NOT done THEN
	ROLLBACK WORK
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET done = grabar_grupo_trabajo()
IF NOT done THEN
	ROLLBACK WORK
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

COMMIT WORK

CALL fl_recalcula_valores_ot(vg_codcia, vg_codloc, rm_t23.t23_orden)

IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF
LET vm_row_current = vm_num_rows
LET vm_rows[vm_num_rows] = rowid

CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL muestra_contadores()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_modificacion()

DEFINE done 		SMALLINT
DEFINE orden_ant	LIKE talt030.t30_num_ot

IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

IF rm_t30.t30_estado = 'E' THEN
	CALL fgl_winmessage(vg_producto,
		'El registro fue eliminado y no se puede modificar.',
		'exclamation')
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	RETURN
END IF

IF rm_t23.t23_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto,
		'La orden de trabajo no está activa.',
		'exclamation')
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	RETURN
END IF

CALL lee_muestra_registro(vm_rows[vm_row_current])

INITIALIZE vm_ind_mec TO NULL

WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_upd CURSOR FOR 
	SELECT * FROM talt030 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_upd
FETCH q_upd INTO rm_t30.*
WHENEVER ERROR STOP
IF STATUS < 0 THEN
	CALL fl_mensaje_bloqueo_otro_usuario()
	ROLLBACK WORK
	RETURN
END IF  

LET orden_ant = rm_t30.t30_num_ot
CALL cargar_grupo_trabajo()

CALL lee_datos('M')
IF INT_FLAG THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	RETURN
END IF 

CALL atrapa_orden(vg_codcia, vg_codloc, rm_t23.t23_orden)
IF rm_t23.t23_compania IS NULL THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	RETURN
END IF

CALL ingresa_detalle('M')
IF INT_FLAG THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	CLOSE q_upd
	RETURN
END IF 

UPDATE talt030 SET * = rm_t30.* WHERE CURRENT OF q_upd

LET done = grabar_detalle()
IF INT_FLAG THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	CLOSE q_upd
	RETURN
END IF

LET done = grabar_grupo_trabajo()
IF NOT done THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	CLOSE q_upd
	RETURN
END IF

COMMIT WORK

CALL fl_recalcula_valores_ot(vg_codcia, vg_codloc, rm_t30.t30_num_ot)
IF orden_ant <> rm_t30.t30_num_ot THEN
	CALL fl_recalcula_valores_ot(vg_codcia, vg_codloc, orden_ant)
END IF

CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION lee_datos(flag)

DEFINE flag 		CHAR(1)
DEFINE resp 		CHAR(6)

DEFINE r_t23		RECORD LIKE talt023.*
DEFINE r_g13		RECORD LIKE gent013.*

LET INT_FLAG = 0
INPUT BY NAME rm_t30.t30_num_gasto,     rm_t30.t30_estado,  rm_t30.t30_num_ot,
	      rm_t30.t30_origen,        rm_t30.t30_destino, 
              rm_t30.t30_fec_ini_viaje, rm_t30.t30_fec_fin_viaje,    
              rm_t30.t30_recargo,       rm_t30.t30_desc_viaje,
              rm_t30.t30_usuario,       rm_t30.t30_fecing WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(t30_num_ot, t30_origen, t30_destino,
				     t30_fec_ini_viaje, t30_fec_fin_viaje,
				     t30_recargo, t30_desc_viaje
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
		IF INFIELD(t30_num_ot) THEN
			CALL fl_ayuda_orden_trabajo(vg_codcia, vg_codloc, 'A') 
				RETURNING r_t23.t23_orden,
					  r_t23.t23_nom_cliente
			IF r_t23.t23_orden IS NOT NULL THEN
				LET rm_t30.t30_num_ot = r_t23.t23_orden
				DISPLAY BY NAME rm_t30.t30_num_ot
			END IF
		END IF
		LET INT_FLAG = 0
	ON KEY(F5)
		CALL control_grupo_trabajo('M')
		LET int_flag = 0
	AFTER FIELD t30_num_ot     
		IF rm_t30.t30_num_ot IS NULL THEN
			INITIALIZE r_t23.* TO NULL
			CALL etiquetas_orden_trabajo(r_t23.*)
			CONTINUE INPUT
		END IF

		CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc, 
			rm_t30.t30_num_ot) RETURNING r_t23.*
		IF r_t23.t23_orden IS NULL THEN
			CALL fgl_winmessage(vg_producto,
				'Orden de trabajo no existe.',
				'exclamation')
			INITIALIZE r_t23.* TO NULL
			CALL etiquetas_orden_trabajo(r_t23.*)
			NEXT FIELD t30_num_ot
		END IF

		IF r_t23.t23_estado <> 'A' THEN
			CALL fgl_winmessage(vg_producto,
				'Orden de trabajo no está activa.',
				'exclamation')
			INITIALIZE r_t23.* TO NULL
			CALL etiquetas_orden_trabajo(r_t23.*)
			NEXT FIELD r19_ord_trabajo
		END IF
		CALL etiquetas_orden_trabajo(r_t23.*)

	AFTER INPUT
		IF vm_ind_mec IS NULL OR vm_ind_mec = 0 THEN
			CALL fgl_winmessage(vg_producto,
				'Debe ingresar que mecánicos viajaron.',
				'exclamation')
			CONTINUE INPUT
		END IF
		CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc, 
			rm_t30.t30_num_ot) RETURNING rm_t23.*
		CALL etiquetas_orden_trabajo(rm_t23.*)
END INPUT

END FUNCTION



FUNCTION control_consulta()

DEFINE expr_sql			VARCHAR(500)
DEFINE query			VARCHAR(600)

DEFINE r_t23		RECORD LIKE talt023.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_z01		RECORD LIKE cxct001.*

CLEAR FORM

LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql 
	ON t30_num_gasto,     t30_estado,      t30_num_ot,        t23_estado,  
	   t23_cod_cliente,   t23_nom_cliente, t23_modelo ,       t23_chasis, 
	   t30_origen,        t30_destino,     t30_fec_ini_viaje, 
           t30_fec_fin_viaje, t30_moneda,      t30_recargo,       
           t30_desc_viaje,    t30_usuario
	ON KEY(F2)
-- Falta ayuda de gastos (hay que hacer)
		IF INFIELD(t30_num_ot) THEN
			CALL fl_ayuda_orden_trabajo(vg_codcia, vg_codloc, 'A') 
				RETURNING r_t23.t23_orden,
					  r_t23.t23_nom_cliente
			IF r_t23.t23_orden IS NOT NULL THEN
				LET rm_t30.t30_num_ot = r_t23.t23_orden
				DISPLAY BY NAME rm_t30.t30_num_ot
			END IF
		END IF
		IF INFIELD(t23_cod_cliente) THEN
			CALL fl_ayuda_cliente_general() 
				RETURNING r_z01.z01_codcli, 
					  r_z01.z01_nomcli
			IF r_z01.z01_codcli IS NOT NULL THEN
				LET rm_t23.t23_cod_cliente = r_z01.z01_codcli
				LET rm_t23.t23_nom_cliente = r_z01.z01_nomcli
				DISPLAY BY NAME rm_t23.t23_cod_cliente,  
  				                rm_t23.t23_nom_cliente
			END IF
		END IF
		IF INFIELD(t30_moneda) THEN
			CALL fl_ayuda_monedas() RETURNING r_g13.g13_moneda,
							  r_g13.g13_nombre,
							  r_g13.g13_decimales
			IF r_g13.g13_moneda IS NOT NULL THEN
				LET rm_t30.t30_moneda = r_g13.g13_moneda
				DISPLAY BY NAME rm_t30.t30_moneda
				DISPLAY r_g13.g13_nombre TO n_moneda
			END IF
		END IF
		LET INT_FLAG = 0
END CONSTRUCT

IF INT_FLAG THEN
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	ELSE
		CLEAR FORM
	END IF
	RETURN
END IF

LET query = 'SELECT *, ROWID FROM talt030 WHERE t30_compania  = ', vg_codcia,
	    				  ' AND t30_localidad = ', vg_codloc,
	    				  ' AND ', expr_sql,
	    '	ORDER BY 1, 2, 3 '

CALL execute_query(query)

END FUNCTION



FUNCTION lee_muestra_registro(row)
DEFINE row 		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF

SELECT * INTO rm_t30.* FROM talt030 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

DISPLAY BY NAME rm_t30.t30_num_gasto, 
		rm_t30.t30_estado, 
		rm_t30.t30_num_ot,
	      	rm_t30.t30_origen,  
	      	rm_t30.t30_destino,  
	      	rm_t30.t30_fec_ini_viaje,
              	rm_t30.t30_fec_fin_viaje,
              	rm_t30.t30_moneda,  
              	rm_t30.t30_recargo,
 	      	rm_t30.t30_desc_viaje, 
              	rm_t30.t30_usuario, 
              	rm_t30.t30_fecing

CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc, rm_t30.t30_num_ot) 
	RETURNING rm_t23.*

INITIALIZE vm_ind_mec TO NULL
CALL etiquetas_orden_trabajo(rm_t23.*)
CALL setea_nombre_botones_f1()
CALL muestra_etiquetas()
CALL muestra_contadores()
CALL muestra_detalle()

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



FUNCTION ingresa_detalle(flag)

DEFINE flag		CHAR(1)
DEFINE resp		CHAR(6)
DEFINE i		SMALLINT
DEFINE j		SMALLINT
DEFINE paridad		LIKE gent014.g14_tasa

DEFINE r_g13		RECORD LIKE gent013.*

IF flag = 'M' THEN
	LET i = vm_ind_gastos
ELSE
        LET i = 1
	INITIALIZE rm_gastos[1].* TO NULL
	LET rm_gastos[1].moneda = rg_gen.g00_moneda_base
END IF

LET j = 1
LET INT_FLAG = 0
CALL set_count(i)
INPUT ARRAY rm_gastos WITHOUT DEFAULTS FROM ra_gastos.*
	ON KEY(INTERRUPT)
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			EXIT INPUT
		END IF
	ON KEY(F2)	
		IF INFIELD(t31_moneda) THEN
			CALL fl_ayuda_monedas() RETURNING r_g13.g13_moneda,
							  r_g13.g13_nombre,
							  r_g13.g13_decimales
			IF r_g13.g13_moneda IS NOT NULL THEN
				LET rm_gastos[i].moneda = r_g13.g13_moneda
				DISPLAY rm_gastos[i].* TO ra_gastos[j].* 
			END IF
		END IF
		LET INT_FLAG = 0	
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
		LET rm_gastos[i].moneda = rg_gen.g00_moneda_base
		DISPLAY rm_gastos[i].moneda TO ra_gastos[j].t31_moneda
		CALL calcula_totales(arr_count())
	AFTER FIELD t31_moneda
		IF rm_gastos[i].moneda IS NULL THEN
			INITIALIZE rm_gastos[i].valor_mb TO NULL
			CLEAR ra_gastos[j].valor_mb
			NEXT FIELD t31_moneda
		END IF
		CALL fl_lee_moneda(rm_gastos[i].moneda) RETURNING r_g13.*
		IF r_g13.g13_moneda IS NULL THEN
			CALL fgl_winmessage(vg_producto, 'Moneda no existe.',
				'exclamation')	
			INITIALIZE rm_gastos[i].valor_mb TO NULL
			CLEAR ra_gastos[j].valor_mb
			NEXT FIELD t31_moneda
		END IF
		IF r_g13.g13_estado = 'B' THEN
			CALL fgl_winmessage(vg_producto, 
				'Moneda está bloqueada.',
				'exclamation')	
			INITIALIZE rm_gastos[i].valor_mb TO NULL
			CLEAR ra_gastos[j].valor_mb
			NEXT FIELD t31_moneda
		END IF
	AFTER FIELD t31_valor
		IF rm_gastos[i].valor IS NULL THEN
			INITIALIZE rm_gastos[i].valor_mb TO NULL
			CLEAR ra_gastos[j].valor_mb
			CONTINUE INPUT
		END IF
		LET paridad = 
			calcula_paridad(rm_gastos[i].moneda, rm_t30.t30_moneda)
		LET rm_gastos[i].valor_mb = rm_gastos[i].valor * paridad
		DISPLAY rm_gastos[i].* TO ra_gastos[j].*
		CALL calcula_totales(arr_count())
	AFTER INPUT
		LET vm_ind_gastos = arr_count()
		IF vm_ind_gastos = 0 THEN
			CALL fgl_winquestion(vg_producto,
				'El comprobante no tiene detalles, ' ||
				'y no podrá ser grabado. ¿Desea ' ||
				'ingresar detalles?',
				'No', 'Yes|No', 'question', 1)
				RETURNING resp
			IF resp = 'Yes' THEN
				CONTINUE INPUT  
			ELSE
				LET int_flag = 1
			END IF
		END IF
END INPUT
IF INT_FLAG THEN
	RETURN
END IF

END FUNCTION



FUNCTION calcula_totales(num_elm)

DEFINE i		SMALLINT
DEFINE num_elm		SMALLINT	

LET rm_t30.t30_tot_gasto = 0

FOR i = 1 TO num_elm       
	LET rm_t30.t30_tot_gasto = rm_t30.t30_tot_gasto + rm_gastos[i].valor_mb
END FOR

DISPLAY BY NAME rm_t30.t30_tot_gasto
	
END FUNCTION



FUNCTION lee_detalle()

DEFINE r_t31		RECORD LIKE talt031.*
DEFINE query		VARCHAR(255)
DEFINE i		SMALLINT
DEFINE paridad		LIKE gent014.g14_tasa

LET query = 'SELECT * FROM talt031 ',
	    '	WHERE t31_compania  = ', vg_codcia,
	    '     AND t31_localidad = ', vg_codloc,
	    '     AND t31_num_gasto = ', rm_t30.t30_num_gasto,
	    '	ORDER BY 1, 2, 3, 4'

PREPARE stmnt1 FROM query
DECLARE q_det1 CURSOR FOR stmnt1

LET i = 1
FOREACH q_det1 INTO r_t31.*
	LET rm_gastos[i].descripcion = r_t31.t31_descripcion
	LET rm_gastos[i].moneda      = r_t31.t31_moneda
	LET rm_gastos[i].valor       = r_t31.t31_valor
	LET paridad = calcula_paridad(rm_gastos[i].moneda, rm_t30.t30_moneda)
	LET rm_gastos[i].valor_mb    = rm_gastos[i].valor * paridad
	LET i = i + 1
	IF i > vm_max_gastos THEN
		EXIT FOREACH
	END IF
END FOREACH		
LET i = i - 1
	  
RETURN i
	
END FUNCTION



FUNCTION muestra_detalle()

DEFINE i		SMALLINT
DEFINE filas_pant	SMALLINT

LET filas_pant = fgl_scr_size('ra_gastos')
FOR i = 1 TO filas_pant
	CLEAR ra_gastos[i].*
END FOR

LET vm_ind_gastos = lee_detalle()
IF vm_ind_gastos = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF

IF vm_ind_gastos < filas_pant THEN
	LET filas_pant = vm_ind_gastos
END IF

FOR i = 1 TO filas_pant
	DISPLAY rm_gastos[i].* TO ra_gastos[i].*
END FOR
CALL calcula_totales(vm_ind_gastos)

END FUNCTION



FUNCTION grabar_detalle()

DEFINE i		SMALLINT
DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT

DEFINE r_t31		RECORD LIKE talt031.*

LET intentar = 1
LET done = 0
WHILE (intentar)
	INITIALIZE r_t31.* TO NULL
	WHENEVER ERROR CONTINUE
		DECLARE q_t31 CURSOR FOR
			SELECT * FROM talt031
				WHERE t31_compania  = vg_codcia         
				  AND t31_localidad = vg_codloc
				  AND t31_num_gasto = rm_t30.t30_num_gasto
			FOR UPDATE
	OPEN  q_t31
	FETCH q_t31 INTO r_t31.*
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

WHILE (STATUS <> NOTFOUND)
	DELETE FROM talt031 WHERE CURRENT OF q_t31

	INITIALIZE r_t31.* TO NULL
	FETCH q_t31 INTO r_t31.*
END WHILE
CLOSE q_t31
FREE  q_t31

FOR i = 1 TO vm_ind_gastos
	INITIALIZE r_t31.* TO NULL

	LET r_t31.t31_compania    = vg_codcia
	LET r_t31.t31_localidad   = vg_codloc
	LET r_t31.t31_num_gasto   = rm_t30.t30_num_gasto
	LET r_t31.t31_secuencia   = i
	LET r_t31.t31_descripcion = rm_gastos[i].descripcion
	LET r_t31.t31_moneda      = rm_gastos[i].moneda
	LET r_t31.t31_valor       = rm_gastos[i].valor

	INSERT INTO talt031 VALUES(r_t31.*)
END FOR

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



FUNCTION control_detalle()

DEFINE i		SMALLINT
DEFINE j		SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT
DEFINE query		CHAR(255)

DEFINE paridad		LIKE gent014.g14_tasa

DEFINE orden ARRAY[10] OF CHAR(4)
DEFINE columna_1	SMALLINT
DEFINE columna_2	SMALLINT

LET columna_1 = 1
LET columna_2 = 2
LET orden[columna_1]  = 'DESC'
LET orden[columna_2]  = 'ASC'
INITIALIZE col TO NULL

LET salir = 0
WHILE NOT salir
        LET query = 'SELECT t31_descripcion, t31_moneda, t31_valor ',
		    '	FROM talt031 ',
		    '  	WHERE t31_compania  = ', vg_codcia,
			' AND t31_localidad = ', vg_codloc,
			' AND t31_num_gasto = ', rm_t30.t30_num_gasto,
                    'ORDER BY ', columna_1, ' ', orden[columna_1],
                           ', ', columna_2, ' ', orden[columna_2]
        PREPARE deto2 FROM query
        DECLARE q_deto2 CURSOR FOR deto2 
        LET i = 1
        FOREACH q_deto2 INTO rm_gastos[i].descripcion, rm_gastos[i].moneda,
			     rm_gastos[i].valor
		LET paridad = 
			calcula_paridad(rm_gastos[i].moneda, rm_t30.t30_moneda)
		LET rm_gastos[i].valor_mb = rm_gastos[i].valor * paridad
                LET i = i + 1
                IF i > vm_max_gastos THEN
                        EXIT FOREACH
                END IF
        END FOREACH
        LET vm_ind_gastos = i - 1
        
        LET i = 1
        LET j = 1
        LET INT_FLAG = 0
	CALL set_count(vm_ind_gastos)
	DISPLAY ARRAY rm_gastos TO ra_gastos.*
		ON KEY(INTERRUPT)
			LET salir = 1
			EXIT DISPLAY
		ON KEY(F15)
			LET col = 1
			EXIT DISPLAY
		ON KEY(F16)
			LET col = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET col = 3
			EXIT DISPLAY
		AFTER DISPLAY
			LET salir = 1
	END DISPLAY

	IF col IS NOT NULL AND NOT salir THEN
        	IF col <> columna_1 THEN
        	        LET columna_2        = columna_1
        	        LET orden[columna_2] = orden[columna_1]
        	        LET columna_1        = col
        	END IF
        	IF orden[columna_1] = 'ASC' THEN
        	        LET orden[columna_1] = 'DESC'
        	ELSE
        	        LET orden[columna_1] = 'ASC'
        	END IF
		INITIALIZE col TO NULL
	END IF
END WHILE

END FUNCTION



FUNCTION execute_query(query)

DEFINE query		VARCHAR(600)

PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_t30.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
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



FUNCTION control_eliminacion()

DEFINE done		SMALLINT

IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

IF rm_t30.t30_estado = 'E' THEN
	CALL fgl_winmessage(vg_producto, 
		'El registro ya está eliminado.',
		'exclamation')  
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	RETURN
END IF

IF rm_t23.t23_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto,
		'La orden de trabajo no está activa.',
		'exclamation')
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	RETURN
END IF

CALL lee_muestra_registro(vm_rows[vm_row_current])

WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_del CURSOR FOR 
	SELECT * FROM talt030 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN  q_del
FETCH q_del INTO rm_t30.*
WHENEVER ERROR STOP
IF STATUS < 0 THEN
	CALL fl_mensaje_bloqueo_otro_usuario()
	ROLLBACK WORK
	RETURN
END IF  
UPDATE talt030 SET t30_estado = 'E' WHERE CURRENT OF q_del

COMMIT WORK

CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION control_imprimir()

DEFINE comando		VARCHAR(300)

LET comando = 'cd ..', vg_separador, '..', vg_separador,
      	      'TALLER', vg_separador, 'fuentes', 
              vg_separador, '; fglrun talp406 ', vg_base, ' ',
      	      'TA', vg_codcia, ' ', vg_codloc, ' ', 
	      rm_t30.t30_num_gasto
RUN comando

END FUNCTION



FUNCTION muestra_etiquetas()

DEFINE nom_est_gasto	CHAR(10)
DEFINE nom_est_ot	CHAR(10)

CASE rm_t30.t30_estado 
	WHEN 'A'
		LET nom_est_gasto = 'ACTIVO'
	WHEN 'E'
		LET nom_est_gasto = 'ELIMINADO'
END CASE

CASE rm_t23.t23_estado
	WHEN 'A'
		LET nom_est_ot = 'ACTIVO'
	WHEN 'C'
		LET nom_est_ot = 'CERRADA'
	WHEN 'F'
		LET nom_est_ot = 'FACTURADA'
	WHEN 'E'
		LET nom_est_ot = 'ELIMINADA'
	WHEN 'D'
		LET nom_est_ot = 'DEVUELTA'
END CASE

DISPLAY nom_est_gasto		TO n_est_gasto
DISPLAY nom_est_ot 		TO n_est_orden

END FUNCTION



FUNCTION setea_nombre_botones_f1()

DISPLAY 'Descripción Gasto'	TO 	bt_descripcion
DISPLAY 'Mo'			TO 	bt_moneda
DISPLAY 'Valor' 		TO 	bt_valor
DISPLAY 'Valor Moneda OT'	TO 	bt_valor_mb

END FUNCTION



FUNCTION muestra_contadores()

DISPLAY "" AT 1,1
DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 68 

END FUNCTION



FUNCTION etiquetas_orden_trabajo(r_t23)

DEFINE r_t23			RECORD LIKE talt023.*
DEFINE r_g13			RECORD LIKE gent013.*

LET rm_t30.t30_moneda = r_t23.t23_moneda
CALL fl_lee_moneda(rm_t30.t30_moneda) RETURNING r_g13.*

DISPLAY r_g13.g13_nombre TO n_moneda

DISPLAY BY NAME rm_t30.t30_moneda,
		r_t23.t23_estado,
		r_t23.t23_cod_cliente,
		r_t23.t23_nom_cliente,
		r_t23.t23_modelo,
		r_t23.t23_chasis

END FUNCTION



FUNCTION calcula_paridad(moneda_ori, moneda_dest)

DEFINE moneda_ori	LIKE gent013.g13_moneda
DEFINE moneda_dest	LIKE gent013.g13_moneda
DEFINE paridad		LIKE gent014.g14_tasa

DEFINE r_g14		RECORD LIKE gent014.*

IF moneda_ori = moneda_dest THEN
	LET paridad = 1 
ELSE
	CALL fl_lee_factor_moneda(moneda_ori, moneda_dest) 
		RETURNING r_g14.*
	IF r_g14.g14_serial IS NULL THEN
		CALL fgl_winmessage(vg_producto, 
				    'No existe factor de conversión ' ||
				    'para esta moneda.',
				    'exclamation')
		INITIALIZE paridad TO NULL
	ELSE
		LET paridad = r_g14.g14_tasa 
	END IF
END IF

RETURN paridad

END FUNCTION



-- flag in ('M', 'C') 
-- M: mantenimiento (input   array)
-- C: consulta      (display array)
FUNCTION control_grupo_trabajo(flag)

DEFINE r_t03		RECORD LIKE talt003.*

DEFINE resp		CHAR(6)
DEFINE flag		CHAR(1)
DEFINE i		SMALLINT
DEFINE j		SMALLINT
DEFINE k		SMALLINT
DEFINE ind_ant		SMALLINT
DEFINE r_mec_aux ARRAY[15] OF RECORD
	cod_mecanico		LIKE talt003.t03_mecanico,
	nom_mecanico		LIKE talt003.t03_nombres,
	principal		CHAR(1)
END RECORD

OPEN WINDOW w_212_2 AT 7,12 WITH 10 ROWS, 57 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, BORDER, MESSAGE LINE LAST)
OPEN FORM f_212_2 FROM '../forms/talf212_2'
DISPLAY FORM f_212_2

DISPLAY 'Código'		TO bt_cod_mecanico
DISPLAY 'Nombre'		TO bt_nom_mecanico

CALL cargar_grupo_trabajo()

IF flag = 'C' THEN
	IF vm_ind_mec = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		CLOSE WINDOW w_212_2
		RETURN
	END IF

	message ''
	LET int_flag = 0
	CALL set_count(vm_ind_mec)
	DISPLAY ARRAY rm_mecanico TO ra_mecanico.*
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		BEFORE DISPLAY
			CALL dialog.keysetlabel('', 'ACCEPT')
		AFTER DISPLAY
			CONTINUE DISPLAY
	END DISPLAY
	
	CLOSE WINDOW w_212_2
	RETURN
END IF

LET ind_ant = vm_ind_mec
FOR i = 1 TO vm_ind_mec 
	LET r_mec_aux[i].* = rm_mecanico[i].*
END FOR

LET int_flag = 0
IF vm_ind_mec > 0 THEN
	CALL set_count(vm_ind_mec)
ELSE
	LET i = 1
	INITIALIZE rm_mecanico[i].* TO NULL
	CALL set_count(i)
END IF
INPUT ARRAY rm_mecanico WITHOUT DEFAULTS FROM ra_mecanico.*
	ON KEY(INTERRUPT)
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
	ON KEY(F2)
		IF INFIELD(cod_mecanico) THEN
			CALL fl_ayuda_mecanicos(vg_codcia, 'T') 
				RETURNING r_t03.t03_mecanico,
					  r_t03.t03_nombres
			IF r_t03.t03_mecanico IS NOT NULL THEN
				LET rm_mecanico[i].cod_mecanico = 
					r_t03.t03_mecanico
				DISPLAY rm_mecanico[i].cod_mecanico TO
						ra_mecanico[j].cod_mecanico
			END IF
		END IF
		LET int_flag = 0
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
	AFTER FIELD cod_mecanico
		IF rm_mecanico[i].cod_mecanico IS NULL THEN
			CLEAR ra_mecanico[j].nom_mecanico, 
			      ra_mecanico[j].check
			CONTINUE INPUT            
  		END IF

		CALL fl_lee_mecanico(vg_codcia, rm_mecanico[i].cod_mecanico) 
			RETURNING r_t03.*
		IF r_t03.t03_mecanico IS NULL  THEN
       			CALL fgl_winmessage(vg_producto,
				'No existe mecánico.',
				'exclamation')
			NEXT FIELD cod_mecanico
		END IF
		FOR k = 1 TO arr_count()
			IF k <> i THEN
				IF rm_mecanico[i].cod_mecanico = 
				   rm_mecanico[k].cod_mecanico
				THEN
       					CALL fgl_winmessage(vg_producto,
						'Mecánico ya fue ingresado.',
						'exclamation')
					NEXT FIELD ra_mecanicos[j].cod_mecanico
				END IF
			END IF 
		END FOR
		LET rm_mecanico[i].nom_mecanico = r_t03.t03_nombres
		DISPLAY rm_mecanico[i].* TO ra_mecanico[j].*
	AFTER INPUT
		LET vm_ind_mec = arr_count()
		LET j = 0
		FOR i = 1 TO vm_ind_mec
			IF rm_mecanico[i].principal = 'S' THEN
				LET j = j + 1
			END IF
		END FOR
		CASE j
			WHEN 0       
				CALL fgl_winmessage(vg_producto,
					'Debe escoger un cabeza de grupo.',
					'exclamation')
				CONTINUE INPUT
			WHEN 1
				EXIT CASE
			OTHERWISE
				CALL fgl_winmessage(vg_producto,
					'No puede escoger mas de un cabeza ' ||
					'de grupo.',
					'exclamation')
				CONTINUE INPUT
		END CASE
END INPUT
IF int_flag THEN
	LET vm_ind_mec = ind_ant
	FOR i = 1 TO ind_ant 
		LET rm_mecanico[i].* = r_mec_aux[i].* 
	END FOR
END IF

CLOSE WINDOW w_212_2

END FUNCTION



FUNCTION cargar_grupo_trabajo()

DEFINE i	SMALLINT

IF vm_ind_mec IS NOT NULL THEN
	RETURN
END IF

DECLARE q_mec CURSOR FOR
	SELECT t32_mecanico, t03_nombres, t32_principal 
		FROM talt032, talt003
		WHERE t32_compania  = vg_codcia
		  AND t32_localidad = vg_codloc
		  AND t32_num_gasto = rm_t30.t30_num_gasto
		  AND t03_compania  = t32_compania
		  AND t03_mecanico  = t32_mecanico

LET i = 1
FOREACH q_mec INTO rm_mecanico[i].*
	LET i = i + 1
	IF i > vm_max_mec THEN
		EXIT FOREACH
	END IF
END FOREACH

LET i = i - 1
LET vm_ind_mec = i

END FUNCTION



FUNCTION grabar_grupo_trabajo()

DEFINE i   		SMALLINT
DEFINE done		SMALLINT
DEFINE r_t32		RECORD LIKE talt032.*

LET done = 0	-- done = false

IF vm_ind_mec IS NULL THEN
	RETURN done
END IF

SET LOCK MODE TO WAIT 5
WHENEVER ERROR CONTINUE

INITIALIZE r_t32.* TO NULL
DECLARE q_t32 CURSOR FOR
	SELECT * FROM talt032 WHERE t32_compania  = vg_codcia
				AND t32_localidad = vg_codloc
				AND t32_num_gasto = rm_t30.t30_num_gasto
	FOR UPDATE

OPEN  q_t32
FETCH q_t32 INTO r_t32.*
IF STATUS < 0 THEN
	WHENEVER ERROR STOP
	SET LOCK MODE TO NOT WAIT
	CALL fl_mensaje_bloqueo_otro_usuario()
	RETURN done
END IF
WHENEVER ERROR STOP

LET done = 1	-- done = true

WHILE (STATUS <> NOTFOUND)
	DELETE FROM talt032 WHERE CURRENT OF q_t32

	INITIALIZE r_t32.* TO NULL
	FETCH q_t32 INTO r_t32.*
END WHILE
SET LOCK MODE TO NOT WAIT
CLOSE q_t32
FREE  q_t32

FOR i = 1 TO vm_ind_mec
	INITIALIZE r_t32.* TO NULL

	LET r_t32.t32_compania  = vg_codcia
	LET r_t32.t32_localidad = vg_codloc
	LET r_t32.t32_num_gasto = rm_t30.t30_num_gasto
	LET r_t32.t32_mecanico  = rm_mecanico[i].cod_mecanico 
	IF rm_mecanico[i].principal IS NULL THEN
		LET r_t32.t32_principal = 'N'
	ELSE
		LET r_t32.t32_principal = rm_mecanico[i].principal
	END IF

	INSERT INTO talt032 VALUES (r_t32.*)
END FOR 

RETURN done

END FUNCTION



FUNCTION atrapa_orden(cod_cia, cod_loc, orden)

DEFINE cod_cia		SMALLINT
DEFINE cod_loc		SMALLINT
DEFINE orden  		SMALLINT

SET LOCK MODE TO WAIT 5
WHENEVER ERROR CONTINUE
	DECLARE q_t23 CURSOR FOR
		SELECT * FROM talt023 WHERE t23_compania  = cod_cia
					AND t23_localidad = cod_loc
					AND t23_orden     = orden
		FOR UPDATE
	OPEN  q_t23
	FETCH q_t23 INTO rm_t23.*
WHENEVER ERROR STOP
IF STATUS < 0 THEN
	SET LOCK MODE TO NOT WAIT
	CALL fl_mensaje_bloqueo_otro_usuario()
	INITIALIZE rm_t23.* TO NULL
	RETURN
END IF
SET LOCK MODE TO NOT WAIT

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
