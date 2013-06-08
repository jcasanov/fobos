--------------------------------------------------------------------------------
-- Titulo           : rolp222.4gl - Mantenimiento utilidades               
-- Elaboracion      : 04-oct-2003
-- Autor            : JCM
-- Formato Ejecucion: fglrun rolp222 base modulo compania [anio cod_trab] [flag]
-- Ultima Correccion:
-- Motivo Correccion:
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_proceso 	LIKE rolt003.n03_proceso
DEFINE rm_loc		RECORD LIKE gent002.*
DEFINE rm_n00		RECORD LIKE rolt000.*  
DEFINE rm_n01		RECORD LIKE rolt001.*  
DEFINE rm_n03		RECORD LIKE rolt003.*  
DEFINE rm_n05		RECORD LIKE rolt005.*  
DEFINE rm_n90		RECORD LIKE rolt090.*
DEFINE rm_par		RECORD 
				n41_ano        	LIKE rolt041.n41_ano, 
				n41_estado	LIKE rolt041.n41_estado,
				n_estado	VARCHAR(20),
				n41_porc_trabaj	LIKE rolt041.n41_porc_trabaj,
				n41_val_trabaj	DECIMAL(22,10),
				n41_porc_cargas	LIKE rolt041.n41_porc_cargas,
				n41_val_cargas	DECIMAL(22,10),
				valor_repart	DECIMAL(22,10),
				n41_util_bonif	LIKE rolt041.n41_util_bonif
			END RECORD
DEFINE vm_r_rows 	ARRAY[200] OF INTEGER
DEFINE rm_scr		ARRAY[1000] OF RECORD
				n_trab		LIKE rolt030.n30_nombres,
				n42_val_trabaj	DECIMAL(22,10),
				n42_num_cargas 	LIKE rolt042.n42_num_cargas,
				n42_val_cargas 	DECIMAL(22,10),
				n42_descuentos	LIKE rolt042.n42_descuentos,
				subtotal	DECIMAL(22,10)
			END RECORD
DEFINE vm_cod_trab	ARRAY[1000] OF RECORD
				n42_cod_trab	LIKE rolt042.n42_cod_trab,
				n42_cod_depto	LIKE rolt042.n42_cod_depto,
				n42_tipo_pago	LIKE rolt042.n42_tipo_pago,
				n42_bco_empresa	LIKE rolt042.n42_bco_empresa,
				n42_cta_empresa	LIKE rolt042.n42_cta_empresa,
				n42_cta_trabaj	LIKE rolt042.n42_cta_trabaj,
				n42_dias_trab	LIKE rolt042.n42_dias_trab
			END RECORD
DEFINE vm_numdesc	INTEGER
DEFINE vm_maxdesc	INTEGER
DEFINE rm_desc		ARRAY[100] OF RECORD 
				n49_cod_rubro	LIKE rolt049.n49_cod_rubro,
				n_rubro		LIKE rolt006.n06_nombre,
				n49_num_prest	LIKE rolt049.n49_num_prest,
				n49_valor	LIKE rolt049.n49_valor
			END RECORD
DEFINE vm_num_rows	INTEGER
DEFINE vm_row_current	INTEGER
DEFINE vm_max_rows	INTEGER
DEFINE vm_num_nov 	INTEGER
DEFINE vm_filas_pant 	INTEGER
DEFINE vm_numelm 	INTEGER
DEFINE vm_maxelm 	INTEGER



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp222.err')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
-- Validar # parámetros correcto
IF num_args() <> 3 AND num_args() <> 6 THEN   
	CALL fl_mostrar_mensaje( 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp222'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE mensaje		CHAR(80)
DEFINE salir 		INTEGER
DEFINE opcion 		INTEGER
DEFINE resp 		VARCHAR(6)
DEFINE tot_porc		DECIMAL(5,2)
DEFINE r_n41		RECORD LIKE rolt041.*

CALL fl_nivel_isolation()
CREATE TEMP TABLE tmp_descuentos (
	n49_cod_trab		INTEGER,
	n49_cod_rubro		INTEGER,
	n_rubro			VARCHAR(30, 15),
	n49_num_prest		INTEGER,
	n49_valor		DECIMAL(12, 2)
)
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rm_loc.*
IF rm_loc.g02_compania IS NULL THEN
	DROP TABLE tmp_descuentos
	CALL fl_mostrar_mensaje('No existe localidad.','stop')
	EXIT PROGRAM
END IF
-- AQUI SE DEFINEN VALORES DE VARIABLES GLOBALES
LET vm_max_rows = 200
LET vm_maxelm   = 1000
LET vm_maxdesc  = 100
LET vm_proceso  = 'UT'
CALL fl_lee_compania_roles(vg_codcia) RETURNING rm_n01.*
IF rm_n01.n01_compania IS NULL THEN
	DROP TABLE tmp_descuentos
	CALL fl_mostrar_mensaje(
		'No existe configuración para esta compañía.',
		'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_conf_adic_rol(vg_codcia) RETURNING rm_n90.*
IF rm_n90.n90_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configuracion adicional de nomina en la tabla rolt090.', 'stop')
	EXIT PROGRAM
END IF
IF num_args() = 6 THEN
	IF arg_val(6) <> 'G' AND arg_val(6) <> 'C' AND arg_val(6) <> 'X' THEN
		CALL fl_mostrar_mensaje('Parametros incorrecto.', 'stop')
		EXIT PROGRAM
	END IF
	INITIALIZE rm_par.* TO NULL
	LET rm_par.n41_ano      = arg_val(4)	
	DECLARE q_est CURSOR FOR
		SELECT * FROM rolt041
			WHERE n41_compania = vg_codcia          
			  AND n41_ano      = rm_par.n41_ano         
      	OPEN  q_est
	FETCH q_est INTO r_n41.*
	CLOSE q_est
	FREE  q_est
	IF r_n41.n41_estado IS NULL THEN
		CALL fl_mostrar_mensaje('Liquidación no existe.', 'stop')
		EXIT PROGRAM
	END IF
	LET rm_par.n41_ano         = r_n41.n41_ano
	LET rm_par.n41_estado      = r_n41.n41_estado
	LET rm_par.n41_porc_trabaj = r_n41.n41_porc_trabaj
	LET rm_par.n41_val_trabaj  = r_n41.n41_val_trabaj
	LET rm_par.n41_porc_cargas = r_n41.n41_porc_cargas
	LET rm_par.n41_val_cargas  = r_n41.n41_val_cargas
	LET rm_par.valor_repart    = rm_par.n41_val_trabaj +
					rm_par.n41_val_cargas
	LET rm_par.n41_util_bonif  = r_n41.n41_util_bonif
	LET tot_porc               = rm_par.n41_porc_trabaj +
					rm_par.n41_porc_cargas
	CASE rm_par.n41_estado  
		WHEN 'A' 
			LET rm_par.n_estado = 'ACTIVO'
		WHEN 'P' 
			LET rm_par.n_estado = 'PROCESADO'
	END CASE
	IF arg_val(6) = 'G' THEN
		CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
		IF resp <> 'Yes' THEN
			EXIT PROGRAM
		END IF
		BEGIN WORK
			CALL regenerar_novedades_empleado(arg_val(5), 1, 1)
		COMMIT WORK
		CALL fl_mostrar_mensaje('Registro de Utilidades del Empleado Regenerado OK.', 'info')
		EXIT PROGRAM
	END IF
END IF
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_222 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST) 
OPEN FORM f_222 FROM '../forms/rolf222_1'
DISPLAY FORM f_222
SELECT * FROM rolt005 
	WHERE n05_compania = vg_codcia AND n05_proceso  = vm_proceso
IF status = NOTFOUND THEN
	LET mensaje = 'No existe en rolt005 proceso: ', vm_proceso
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	RETURN
END IF
CALL fl_retorna_proceso_roles_activo(vg_codcia) RETURNING rm_n05.*
MENU 'OPCIONES'
	BEFORE MENU
		CALL mostrar_botones()
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Cerrar'
		HIDE OPTION 'Imprimir'
		HIDE OPTION 'Recibo de Pago'
		HIDE OPTION 'Detalle'
		HIDE OPTION 'Mantenimiento'
                HIDE OPTION 'Generar'
		HIDE OPTION 'Informe Min.'
		HIDE OPTION 'Archivo Banco'
		LET opcion = utilidades_entregadas()
                IF rm_n05.n05_proceso IS NULL THEN
                	SHOW OPTION 'Generar'
		END IF
                IF rm_n05.n05_proceso = vm_proceso THEN
			IF opcion <> 0 THEN
                        	SHOW OPTION 'Generar'
			END IF
                END IF
                HIDE OPTION 'Cerrar'
		IF num_args() = 6 AND arg_val(6) = 'C' THEN
			HIDE OPTION 'Generar'
			HIDE OPTION 'Mantenimiento'
			HIDE OPTION 'Consultar'
			CALL carga_trabajadores(1)
			IF vm_numelm = 0 THEN
				CALL fl_mostrar_mensaje('No existe distribucion de utilidades.', 'stop')
				EXIT PROGRAM
			END IF
			LET vm_num_rows = 1
			LET vm_row_current = 1
			CALL muestra_contadores(vm_row_current, vm_num_rows)
			DISPLAY BY NAME rm_par.*, tot_porc
			CALL control_detalle()
			EXIT PROGRAM
		END IF
      	COMMAND KEY('G') 'Generar' 'Calcula las utilidades de los trabajadores.'
		CALL control_generar()
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Mantenimiento'
			SHOW OPTION 'Cerrar'
			SHOW OPTION 'Imprimir'
			SHOW OPTION 'Recibo de Pago'
			SHOW OPTION 'Informe Min.'
			IF vm_filas_pant < vm_numelm THEN
				SHOW OPTION 'Detalle'
			ELSE
				HIDE OPTION 'Detalle'
			END IF
		END IF
      	COMMAND KEY('M') 'Mantenimiento' 'Da mantenimiento a las utilidades de los trabajadores.'
		CALL control_modificacion()
      	COMMAND KEY('U') 'Cerrar' 'Cierra el proceso activo. '
		CALL control_cerrar()
		IF rm_par.n41_estado = 'P' THEN
			HIDE OPTION 'Generar'
			HIDE OPTION 'Cerrar'
			HIDE OPTION 'Mantenimiento'
		END IF
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		CALL control_consulta(0)
		IF vm_num_rows <= 1 THEN
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Cerrar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
		IF rm_par.n41_estado = 'A' THEN
			SHOW OPTION 'Generar'
			SHOW OPTION 'Mantenimiento'
			SHOW OPTION 'Cerrar'
		ELSE
			HIDE OPTION 'Generar'
			HIDE OPTION 'Mantenimiento'
			HIDE OPTION 'Cerrar'
		END IF
		IF rm_par.n41_estado IS NULL THEN
			SHOW OPTION 'Generar'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
			SHOW OPTION 'Recibo de Pago'
			SHOW OPTION 'Informe Min.'
			SHOW OPTION 'Detalle'
			SHOW OPTION 'Archivo Banco'
		END IF
	COMMAND KEY('D') 'Detalle' 'Consulta el detalle del registro actual. '
		CALL control_detalle()
	COMMAND KEY('B') 'Archivo Banco' 'Genera archivo para depositar Banco.'
		CALL generar_archivo()
	COMMAND KEY('I') 'Imprimir' 'Imprime un registro. '
		CALL control_imprimir()
	COMMAND KEY('P') 'Recibo de Pago' 'Imprime los recibos de pago. '
		CALL control_imprimir_recibo(NULL)
	COMMAND KEY('F') 'Informe Min.' 'Imprime un informe para el Ministerio de Trabajo.'
		CALL control_imprimir_informe()
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
		IF rm_par.n41_estado = 'A' THEN
			SHOW OPTION 'Generar'
			SHOW OPTION 'Mantenimiento'
			SHOW OPTION 'Cerrar'
		ELSE
			HIDE OPTION 'Generar'
			HIDE OPTION 'Mantenimiento'
			HIDE OPTION 'Cerrar'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Detalle'
			SHOW OPTION 'Archivo Banco'
		END IF
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
		IF rm_par.n41_estado = 'A' THEN
			SHOW OPTION 'Generar'
			SHOW OPTION 'Mantenimiento'
			SHOW OPTION 'Cerrar'
		ELSE
			HIDE OPTION 'Generar'
			HIDE OPTION 'Mantenimiento'
			HIDE OPTION 'Cerrar'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Detalle'
			SHOW OPTION 'Archivo Banco'
		END IF
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION mostrar_botones()

DISPLAY 'Nombre Trabajador' 	TO bt_nom_trab
DISPLAY 'Por Dias Trab.'	TO bt_val_trabaj
DISPLAY 'CT'			TO bt_num_cargas
DISPLAY 'Por Cargas' 		TO bt_val_cargas
DISPLAY 'Descuentos' 		TO bt_descuentos
DISPLAY 'Subtotal' 		TO bt_subtotal

END FUNCTION



FUNCTION control_consulta(flag)
DEFINE query		VARCHAR(400)
DEFINE expr_sql		VARCHAR(400)
DEFINE num_reg		INTEGER
DEFINE r_n41		RECORD LIKE rolt041.*
DEFINE flag		CHAR(1)

IF flag = 0 THEN
	INITIALIZE rm_par.* TO NULL
	LET int_flag = 0
	CLEAR FORM
	CALL mostrar_botones()
	CONSTRUCT BY NAME expr_sql ON n41_ano, n41_estado, n41_util_bonif 
	IF int_flag THEN
		IF vm_row_current > 0 THEN
			CALL mostrar_registro(vm_r_rows[vm_row_current])
		ELSE
			CLEAR FORM
			INITIALIZE rm_par.* TO NULL
			CALL mostrar_botones()
		END IF
		RETURN
	END IF
ELSE
	LET expr_sql = 'n41_ano = ', rm_par.n41_ano
END IF
LET query = 'SELECT *, rowid FROM rolt041 ',
		' WHERE n41_compania = ', vg_codcia,
		'   AND n41_proceso  = "', vm_proceso, '"',
		'   AND ', expr_sql CLIPPED,
		' ORDER BY 1, 5 DESC'
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1 
FOREACH q_cons INTO r_n41.*, vm_r_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	LET int_flag = 0
	INITIALIZE rm_par.* TO NULL
	CALL fl_mensaje_consulta_sin_registros()
	CLEAR FORM
	CALL mostrar_botones()
	LET vm_row_current = 0
ELSE  
	LET vm_row_current = 1
	CALL mostrar_registro(vm_r_rows[vm_row_current])
	CALL muestra_contadores(vm_row_current, vm_num_rows)
END IF

END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE num_registro	INTEGER
DEFINE tot_porc		DECIMAL(5,2)

DEFINE r_n41		RECORD LIKE rolt041.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF
INITIALIZE rm_par.* TO NULL
SELECT n41_ano, n41_estado, ' ', n41_porc_trabaj, n41_val_trabaj,
       n41_porc_cargas, n41_val_cargas, 0, n41_util_bonif 
	INTO rm_par.*
	FROM rolt041 
	WHERE ROWID = num_registro       
IF STATUS = NOTFOUND THEN
	CALL fgl_winmessage (vg_producto,'No existe registro con índice: ' || vm_row_current,'exclamation')
	RETURN
END IF
LET rm_par.valor_repart = rm_par.n41_val_trabaj + rm_par.n41_val_cargas
LET tot_porc = rm_par.n41_porc_trabaj + rm_par.n41_porc_cargas
CASE rm_par.n41_estado  
	WHEN 'A' 
		LET rm_par.n_estado = 'ACTIVO'
	WHEN 'P' 
		LET rm_par.n_estado = 'PROCESADO'
END CASE
DISPLAY BY NAME	rm_par.*, tot_porc
CALL muestra_detalle()

END FUNCTION



FUNCTION muestra_detalle()
DEFINE tot_val_trabaj		LIKE rolt041.n41_val_trabaj
DEFINE tot_val_cargas		LIKE rolt041.n41_val_cargas
DEFINE tot_dsctos		LIKE rolt042.n42_descuentos
DEFINE tot_valor		LIKE rolt041.n41_val_trabaj
DEFINE i			SMALLINT

CALL carga_trabajadores(0)
LET int_flag = 0
CALL set_count(vm_numelm)
DISPLAY ARRAY rm_scr TO ra_scr.*
	BEFORE DISPLAY
                LET vm_filas_pant = fgl_scr_size('ra_scr')
		CALL calcula_totales() RETURNING tot_val_trabaj, 
 						 tot_val_cargas,
						 tot_dsctos,
						 tot_valor
		DISPLAY BY NAME tot_val_trabaj, tot_val_cargas, tot_dsctos,
				tot_valor
		EXIT DISPLAY
	BEFORE ROW
		LET i = arr_curr()
		CALL muestra_etiquetas(i, vm_numelm)
END DISPLAY
CALL muestra_contadores_det(0, vm_numelm)
CALL mostrar_salir_det()
	
END FUNCTION



FUNCTION control_detalle()
DEFINE tot_val_trabaj		LIKE rolt041.n41_val_trabaj
DEFINE tot_val_cargas		LIKE rolt041.n41_val_cargas
DEFINE tot_dsctos		LIKE rolt042.n42_descuentos
DEFINE tot_valor 		LIKE rolt041.n41_val_trabaj
DEFINE cod_trab			LIKE rolt042.n42_cod_trab
DEFINE i			INTEGER

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
LET int_flag = 0
CALL set_count(vm_numelm)
DISPLAY ARRAY rm_scr TO ra_scr.*
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT DISPLAY
	ON KEY(F5)
		CALL mostrar_descuentos(arr_curr())
		LET int_flag = 0
	ON KEY(F6)
		LET i = arr_curr()
		LET cod_trab = vm_cod_trab[i].n42_cod_trab
		CALL control_imprimir_recibo(cod_trab)
		LET int_flag = 0
	BEFORE DISPLAY
		--#CALL dialog.keysetlabel('ACCEPT', '')   
                --#CALL dialog.keysetlabel('F5','Descuentos')
                --#CALL dialog.keysetlabel('F6','Recibo de Pago')
		CALL calcula_totales() RETURNING tot_val_trabaj, 
                                                 tot_val_cargas,
						 tot_dsctos,
                                                 tot_valor
		DISPLAY BY NAME tot_val_trabaj, tot_val_cargas, tot_dsctos,
				tot_valor
	BEFORE ROW
		LET i = arr_curr()
		CALL muestra_etiquetas(i, vm_numelm)
	AFTER DISPLAY
		CONTINUE DISPLAY
END DISPLAY
CALL muestra_contadores_det(0, vm_numelm)
CALL mostrar_salir_det()
LET int_flag = 0

END FUNCTION



FUNCTION control_modificacion()
DEFINE r_n41		RECORD LIKE rolt041.*
DEFINE tot_val_trabaj	LIKE rolt041.n41_val_trabaj
DEFINE tot_val_cargas	LIKE rolt041.n41_val_cargas
DEFINE tot_dsctos	LIKE rolt042.n42_descuentos
DEFINE tot_valor 	LIKE rolt041.n41_val_trabaj
DEFINE cod_trab		LIKE rolt042.n42_cod_trab
DEFINE salir, i, j	SMALLINT
DEFINE resp		CHAR(6)
DEFINE query		CHAR(1200)

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
IF rm_par.n41_estado = 'P' THEN
	CALL fl_mostrar_mensaje('Estas utilidades ya han sido procesadas.','exclamation')
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR
	SELECT * FROM rolt041
		WHERE n41_compania = vg_codcia
		  AND n41_proceso  = vm_proceso
		  AND n41_ano      = rm_par.n41_ano
	FOR UPDATE
OPEN q_up
FETCH q_up INTO r_n41.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
OPTIONS 
	INSERT KEY F30,
	DELETE KEY F31
LET int_flag = 0
LET salir    = 0
WHILE NOT salir
	CALL set_count(vm_numelm)
	INPUT ARRAY rm_scr WITHOUT DEFAULTS FROM ra_scr.*
		ON KEY(INTERRUPT)
        		LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				EXIT INPUT
			END IF
		ON KEY(F5)
			LET i = arr_curr()
			CALL fl_modifica_forma_pago(vg_codcia, 
					    vm_cod_trab[i].n42_cod_trab,
					    vm_cod_trab[i].n42_tipo_pago,
					    vm_cod_trab[i].n42_bco_empresa,
					    vm_cod_trab[i].n42_cta_empresa,
					    vm_cod_trab[i].n42_cta_trabaj)
				RETURNING vm_cod_trab[i].n42_tipo_pago,
					    vm_cod_trab[i].n42_bco_empresa,
					    vm_cod_trab[i].n42_cta_empresa,
					    vm_cod_trab[i].n42_cta_trabaj
			LET int_flag = 0
		ON KEY(F6)
			LET i = arr_curr()
                	LET j = scr_line()
			CALL lee_muestra_descuentos(i)
			LET int_flag = 0
			DISPLAY rm_scr[i].* TO ra_scr[j].*
			CALL calcula_totales() RETURNING tot_val_trabaj, 
        	                                         tot_val_cargas,
							 tot_dsctos,
                        	                         tot_valor
			DISPLAY BY NAME tot_val_trabaj, tot_val_cargas,
					tot_dsctos, tot_valor
		ON KEY(F7)
			CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
			IF resp <> 'Yes' THEN
				CONTINUE INPUT	
			END IF
			CALL regenerar_novedades_empleado(
						vm_cod_trab[i].n42_cod_trab,
						1, arr_count())
			LET int_flag = 0
			DELETE FROM tmp_descuentos 
				WHERE n49_cod_trab = vm_cod_trab[i].n42_cod_trab
			INSERT INTO tmp_descuentos
				SELECT n49_cod_trab, n49_cod_rubro, n06_nombre,
					n49_num_prest, n49_valor
				FROM rolt049, rolt006
			       	WHERE n49_compania  = vg_codcia
				  AND n49_proceso   = vm_proceso
				  AND n49_cod_trab  =
						vm_cod_trab[i].n42_cod_trab
				  AND n49_fecha_ini = r_n41.n41_fecha_ini
				  AND n49_fecha_fin = r_n41.n41_fecha_fin
				  AND n06_cod_rubro = n49_cod_rubro
			SELECT n42_val_trabaj, n42_num_cargas, n42_val_cargas,
				n42_descuentos, n42_val_trabaj + n42_val_cargas
				- n42_descuentos
				INTO rm_scr[i].n42_val_trabaj,
					rm_scr[i].n42_num_cargas,
					rm_scr[i].n42_val_cargas,
					rm_scr[i].n42_descuentos,
					rm_scr[i].subtotal
				FROM rolt042
				 WHERE n42_compania  = vg_codcia
				   AND n42_proceso   = vm_proceso
				   AND n42_cod_trab  =
						vm_cod_trab[i].n42_cod_trab
				   AND n42_fecha_ini = r_n41.n41_fecha_ini
				   AND n42_fecha_fin = r_n41.n41_fecha_fin
			DISPLAY rm_scr[i].* TO ra_scr[j].*
			CALL calcula_totales() RETURNING tot_val_trabaj, 
        	                                         tot_val_cargas,
							 tot_dsctos,
                        	                         tot_valor
			DISPLAY BY NAME tot_val_trabaj, tot_val_cargas,
					tot_dsctos, tot_valor
			CALL fl_mostrar_mensaje('Registro de Utilidades del Empleado Regenerado OK.', 'info')
		BEFORE INPUT
	        	--#CALL dialog.keysetlabel('INSERT','')
        		--#CALL dialog.keysetlabel('DELETE','')
                	--#CALL dialog.keysetlabel('F5','Forma de Pago')
                	--#CALL dialog.keysetlabel('F6','Descuentos')
                	--#CALL dialog.keysetlabel('F7','Regenerar Util.')
			CALL calcula_totales() RETURNING tot_val_trabaj, 
        	                                         tot_val_cargas,
							 tot_dsctos,
                        	                         tot_valor
			DISPLAY BY NAME tot_val_trabaj, tot_val_cargas,
					tot_dsctos, tot_valor
		BEFORE INSERT
			LET salir = 0
			EXIT INPUT
		BEFORE ROW
			LET i = arr_curr()
                	LET j = scr_line()
			CALL muestra_etiquetas(i, vm_numelm)
		AFTER FIELD n42_val_trabaj, n42_val_cargas
			LET rm_scr[i].subtotal =
				rm_scr[i].n42_val_trabaj +
				rm_scr[i].n42_val_cargas -
				rm_scr[i].n42_descuentos
			DISPLAY rm_scr[i].* TO ra_scr[j].*
			CALL calcula_totales() RETURNING tot_val_trabaj, 
        	                                         tot_val_cargas,
							 tot_dsctos,
                        	                         tot_valor
			DISPLAY BY NAME tot_val_trabaj, tot_val_cargas,
					tot_dsctos, tot_valor
		AFTER INPUT
			LET salir = 1
	END INPUT
	IF int_flag = 1 THEN
		LET salir = 1
	END IF
END WHILE
IF int_flag THEN
	ROLLBACK WORK
	CLEAR FORM
	CALL mostrar_botones()
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
	RETURN
END IF
CLEAR nom_trab, n42_dias_trab
FOR i = 1 TO vm_numelm 
	SELECT NVL(SUM(n49_valor), 0)
		INTO rm_scr[i].n42_descuentos 
		FROM tmp_descuentos
		WHERE n49_cod_trab = vm_cod_trab[i].n42_cod_trab
	UPDATE rolt042 SET
		n42_val_trabaj  = rm_scr[i].n42_val_trabaj,
		n42_num_cargas  = rm_scr[i].n42_num_cargas,
		n42_val_cargas  = rm_scr[i].n42_val_cargas,
		n42_descuentos  = rm_scr[i].n42_descuentos,
		n42_dias_trab   = vm_cod_trab[i].n42_dias_trab,
		n42_tipo_pago   = vm_cod_trab[i].n42_tipo_pago,
		n42_bco_empresa = vm_cod_trab[i].n42_bco_empresa,
		n42_cta_empresa = vm_cod_trab[i].n42_cta_empresa,
		n42_cta_trabaj  = vm_cod_trab[i].n42_cta_trabaj
	WHERE n42_compania = vg_codcia
          AND n42_cod_trab = vm_cod_trab[i].n42_cod_trab
	  AND n42_ano      = rm_par.n41_ano
	DELETE FROM rolt049
		WHERE n49_compania  = vg_codcia
		  AND n49_proceso   = vm_proceso
		  AND n49_cod_trab  = vm_cod_trab[i].n42_cod_trab 
		  AND n49_fecha_ini = r_n41.n41_fecha_ini
		  AND n49_fecha_fin = r_n41.n41_fecha_fin
	LET query = 'INSERT INTO rolt049  ', 
	            '	SELECT ', vg_codcia, ', "', vm_proceso, '", ',
		      	          vm_cod_trab[i].n42_cod_trab, ', MDY(',
		                  MONTH(r_n41.n41_fecha_ini), ', ', 
		                  DAY(r_n41.n41_fecha_ini), ', ', 
		                  YEAR(r_n41.n41_fecha_ini), '), MDY(', 
		                  MONTH(r_n41.n41_fecha_fin), ', ', 
		                  DAY(r_n41.n41_fecha_fin), ', ', 
		                  YEAR(r_n41.n41_fecha_fin), '), ', 
				  ' n49_cod_rubro, n49_num_prest, n06_orden, ',
				  ' n06_det_tot, n06_imprime_0, n49_valor ',
		    '	FROM tmp_descuentos, rolt006 ',
		    '  	WHERE n49_cod_trab  = ', vm_cod_trab[i].n42_cod_trab, 
		    '     AND n06_cod_rubro = n49_cod_rubro '
	PREPARE stmnt2 FROM query
	EXECUTE stmnt2
END FOR
COMMIT WORK
CALL fl_mensaje_registro_modificado()
IF vm_row_current > 0 THEN
	CALL mostrar_registro(vm_r_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION carga_trabajadores(flag)
DEFINE cod_trab 	LIKE rolt042.n42_cod_trab
DEFINE flag		SMALLINT
DEFINE query		CHAR(900)
DEFINE expr_sql		VARCHAR(100)

DELETE FROM tmp_descuentos
INSERT INTO tmp_descuentos
	SELECT n49_cod_trab, n49_cod_rubro, n06_nombre, n49_num_prest, 
               n49_valor
	FROM rolt049, rolt006
       	WHERE n49_compania        = vg_codcia
	  AND n49_proceso         = vm_proceso
	  AND YEAR(n49_fecha_fin) = rm_par.n41_ano
	  AND n06_cod_rubro       = n49_cod_rubro
LET expr_sql = NULL
IF flag THEN
	LET expr_sql = '   AND n30_tipo_trab = "N" '
END IF
LET query = 'SELECT n42_cod_trab, n42_cod_depto, n42_tipo_pago, ',
			'n42_bco_empresa, n42_cta_empresa, n42_cta_trabaj, ',
			'n42_dias_trab, n30_nombres, n42_val_trabaj, ',
			'n42_num_cargas, n42_val_cargas, n42_descuentos, 0.00 ',
		' FROM rolt030, rolt042 ',
		' WHERE n42_compania  = ', vg_codcia,
		'   AND n42_ano       = ', rm_par.n41_ano,
		'   AND n30_compania  = n42_compania ',
		'   AND n30_cod_trab  = n42_cod_trab ',
            	' ORDER BY n30_nombres '
PREPARE cons_trab FROM query
DECLARE q_trab CURSOR FOR cons_trab
IF num_args() = 5 AND arg_val(5) <> 'X' THEN
	LET cod_trab = arg_val(5)
ELSE
	INITIALIZE cod_trab TO NULL
END IF
LET vm_numelm = 1
FOREACH q_trab INTO vm_cod_trab[vm_numelm].*, rm_scr[vm_numelm].*
	IF cod_trab IS NOT NULL AND
	   vm_cod_trab[vm_numelm].n42_cod_trab <> cod_trab
	THEN
		CONTINUE FOREACH
	END IF
	LET rm_scr[vm_numelm].subtotal = (rm_scr[vm_numelm].n42_val_trabaj +
                                          rm_scr[vm_numelm].n42_val_cargas) -
                                          rm_scr[vm_numelm].n42_descuentos 
        LET vm_numelm = vm_numelm + 1
        IF vm_numelm > vm_maxelm THEN
                CALL fl_mensaje_arreglo_incompleto()
                EXIT PROGRAM
        END IF
END FOREACH
LET vm_numelm = vm_numelm - 1

END FUNCTION



FUNCTION calcula_totales()
DEFINE i                INTEGER
DEFINE val_trabaj       DECIMAL(22,10)
DEFINE val_cargas       DECIMAL(22,10)
DEFINE descuentos       LIKE rolt042.n42_descuentos
DEFINE valor_neto       DECIMAL(22,10)
DEFINE tot_val_trabaj   DECIMAL(22,10)
DEFINE tot_val_cargas   DECIMAL(22,10)
DEFINE tot_dsctos       LIKE rolt042.n42_descuentos
DEFINE tot_valor_neto   DECIMAL(22,10)

LET tot_val_trabaj  = 0
LET tot_val_cargas  = 0
LET tot_dsctos      = 0
LET tot_valor_neto  = 0
FOR i = 1 TO vm_numelm
	LET val_trabaj = rm_scr[i].n42_val_trabaj
	IF val_trabaj IS NULL THEN
		LET val_trabaj = 0
	END IF
        LET tot_val_trabaj = tot_val_trabaj + val_trabaj
	LET val_cargas = rm_scr[i].n42_val_cargas
	IF val_cargas IS NULL THEN
		LET val_cargas = 0
	END IF
        LET tot_val_cargas = tot_val_cargas + val_cargas
	LET descuentos = rm_scr[i].n42_descuentos
	IF descuentos IS NULL THEN
		LET descuentos = 0
	END IF
        LET tot_dsctos = tot_dsctos + descuentos

	LET valor_neto = val_trabaj + val_cargas - descuentos
	IF valor_neto IS NULL THEN
		LET valor_neto = 0
	END IF
        LET tot_valor_neto = tot_valor_neto + valor_neto
END FOR
RETURN tot_val_trabaj, tot_val_cargas, tot_dsctos, tot_valor_neto

END FUNCTION



FUNCTION muestra_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION muestra_anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current	SMALLINT
DEFINE num_rows		SMALLINT
                                                                                
DISPLAY "" AT 1,1
DISPLAY row_current, " de ", num_rows AT 1, 69
                                                                                
END FUNCTION



FUNCTION control_cerrar()
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n41		RECORD LIKE rolt041.*
DEFINE fecha_ini	LIKE rolt042.n42_fecha_ini
DEFINE fecha_fin	LIKE rolt042.n42_fecha_fin
DEFINE resp		VARCHAR(6)
DEFINE neg, i		INTEGER

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
IF rm_par.n41_estado = 'P' THEN
	CALL fl_mostrar_mensaje('Ya se ha pagado las utilidades a los trabajadores.', 'stop')
	RETURN
END IF
CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
IF resp = 'No' THEN
        LET int_flag = 0
        RETURN
END IF
SELECT COUNT(n42_cod_trab) INTO neg
	FROM rolt042
       	WHERE n42_compania    = vg_codcia
	  AND n42_ano         = rm_par.n41_ano
	  AND (n42_val_trabaj < 0
	   OR  n42_val_cargas < 0
	   OR  n42_descuentos < 0
	   OR (n42_val_trabaj + n42_val_cargas - n42_descuentos) < 0)
IF neg > 0 THEN
	CALL fl_mostrar_mensaje('Existen empleados con valor a recibir negativo, por favor corrija y vuelva a intentar.', 'info')
	RETURN
END IF
CALL fl_lee_proceso_roles(vm_proceso) RETURNING r_n03.*
BEGIN WORK
WHENEVER ERROR CONTINUE
	DECLARE q_cerr CURSOR FOR
		SELECT * FROM rolt041
		        WHERE n41_compania = vg_codcia
			  AND n41_ano      = rm_par.n41_ano
	        FOR UPDATE
	OPEN q_cerr
	FETCH q_cerr INTO r_n41.*
	IF STATUS < 0 THEN
	        ROLLBACK WORK
	        WHENEVER ERROR STOP
	        CALL fl_mensaje_bloqueo_otro_usuario()
	        RETURN
	END IF
	WHENEVER ERROR STOP
	-- Se actualiza n41_fecing con la fecha en que se cerro el registro
	-- para determinar en que quincena se pago
	UPDATE rolt041
		SET n41_estado = 'P',
		    n41_fecing = CURRENT
		WHERE CURRENT OF q_cerr
	LET fecha_ini = MDY(r_n03.n03_mes_ini, r_n03.n03_dia_ini,rm_par.n41_ano)
	LET fecha_fin = MDY(r_n03.n03_mes_fin, r_n03.n03_dia_fin,rm_par.n41_ano)
	FOR i = 1 TO vm_numelm
		IF rm_scr[i].n42_descuentos = 0 THEN
			CONTINUE FOR
		END IF
		CALL actualizacion_anticipos(i, fecha_ini, fecha_fin)
	END FOR
	LET i = 0
	UPDATE rolt005
		SET n05_activo     = 'N',
		    n05_fec_ultcie = n05_fec_cierre,
		    n05_fec_cierre = CURRENT
		WHERE n05_compania = vg_codcia
		  AND n05_proceso  = vm_proceso
COMMIT WORK
CALL mostrar_registro(vm_r_rows[vm_row_current])	
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL fl_mostrar_mensaje('Proceso Terminado OK.', 'info')

END FUNCTION



FUNCTION actualizacion_anticipos(i, fecha_ini, fecha_fin)
DEFINE i		SMALLINT
DEFINE fecha_ini	LIKE rolt042.n42_fecha_ini
DEFINE fecha_fin	LIKE rolt042.n42_fecha_fin
DEFINE num_prest	LIKE rolt046.n46_num_prest
DEFINE r_n45		RECORD LIKE rolt045.*
DEFINE r_n49		RECORD LIKE rolt049.*
DEFINE query		CHAR(600)

LET query = 'SELECT * FROM rolt049 ',
		' WHERE n49_compania  = ', vg_codcia,
		'   AND n49_proceso   = "', vm_proceso, '"',
		'   AND n49_cod_trab  = ', vm_cod_trab[i].n42_cod_trab,
		'   AND n49_fecha_ini = "', fecha_ini, '"',
		'   AND n49_fecha_fin = "', fecha_fin, '"',
		'   AND n49_num_prest IS NOT NULL '
PREPARE cons_prest FROM query
DECLARE q_prest CURSOR FOR cons_prest
FOREACH q_prest INTO r_n49.*
	LET num_prest = NULL
	DECLARE q_prest2 CURSOR FOR
		SELECT n46_num_prest
			FROM rolt045, rolt046
        		WHERE n45_compania    = vg_codcia
			  AND n45_cod_trab    = vm_cod_trab[i].n42_cod_trab
			  AND n45_estado     IN ('A', 'R')
			  AND n46_compania    = n45_compania
			  AND n46_num_prest   = n45_num_prest
			  AND n46_cod_liqrol  = vm_proceso
			  AND n46_fecha_ini   = fecha_ini
			  AND n46_fecha_fin   = fecha_fin 
	OPEN q_prest2
	FETCH q_prest2 INTO num_prest
	CLOSE q_prest2
	FREE q_prest2
	IF num_prest IS NULL THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No existe préstamo para el trabajador ' || rm_scr[i].n_trab CLIPPED || '.', 'stop')
		EXIT PROGRAM
	END IF
	CALL fl_lee_cab_prestamo_roles(vg_codcia, num_prest) RETURNING r_n45.*
	IF (r_n45.n45_descontado + r_n49.n49_valor) >=
	   (r_n45.n45_val_prest + r_n45.n45_valor_int + r_n45.n45_sal_prest_ant)
	THEN
		LET r_n45.n45_estado = 'P' 
	END IF
	UPDATE rolt058
		SET n58_div_act    = n58_div_act + 1,
		    n58_saldo_dist = n58_saldo_dist - r_n49.n49_valor
		WHERE n58_compania  = vg_codcia
		  AND n58_num_prest = r_n45.n45_num_prest
		  AND n58_proceso   = vm_proceso
	UPDATE rolt046
		SET n46_saldo = n46_valor - r_n49.n49_valor
        	WHERE n46_compania   = vg_codcia
		  AND n46_num_prest  = r_n49.n49_num_prest
		  AND n46_cod_liqrol = vm_proceso
		  AND n46_fecha_ini  = fecha_ini 
		  AND n46_fecha_fin  = fecha_fin
		  AND n46_saldo      = r_n49.n49_valor
	UPDATE rolt046
		SET n46_saldo = n46_valor - (r_n49.n49_valor + n46_saldo)
        	WHERE n46_compania   = vg_codcia
		  AND n46_num_prest  = r_n49.n49_num_prest
		  AND n46_cod_liqrol = vm_proceso
		  AND n46_fecha_ini  = fecha_ini 
		  AND n46_fecha_fin  = fecha_fin
		  AND n46_saldo      > 0
		  AND n46_saldo      < r_n49.n49_valor
	UPDATE rolt045
		SET n45_descontado = n45_descontado + r_n49.n49_valor,
		    n45_estado     = r_n45.n45_estado
       		WHERE n45_compania   = vg_codcia
		  AND n45_num_prest  = r_n49.n49_num_prest
		  AND n45_cod_rubro  = r_n49.n49_cod_rubro
		  AND n45_cod_trab   = vm_cod_trab[i].n42_cod_trab
	     	  AND n45_estado    IN ('A', 'R')
		  AND n45_val_prest + n45_valor_int +
			n45_sal_prest_ant - n45_descontado > 0
END FOREACH

END FUNCTION



FUNCTION control_generar()
DEFINE resp		VARCHAR(6)
DEFINE mensaje		VARCHAR(250)
DEFINE tot_porc		DECIMAL(5,2)
DEFINE fecha_ini	LIKE rolt042.n42_fecha_ini
DEFINE fecha_fin	LIKE rolt042.n42_fecha_fin

CALL fl_lee_parametro_general_roles() RETURNING rm_n00.*
IF rm_n00.n00_serial IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configuración general para este módulo.', 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_proceso_roles(vm_proceso) RETURNING rm_n03.*
IF rm_n03.n03_proceso IS NULL THEN
	CALL fl_mostrar_mensaje('No se ha configurado proceso de utilidades.', 'stop')
	EXIT PROGRAM
END IF
IF rm_n03.n03_mes_ini IS NULL OR rm_n03.n03_dia_ini IS NULL OR
   rm_n03.n03_mes_fin IS NULL OR rm_n03.n03_dia_fin IS NULL
THEN
	CALL fl_mostrar_mensaje('No se ha configurado un periodo de calculo de las UTILIDADES.', 'stop')
	EXIT PROGRAM
END IF
INITIALIZE rm_par.* TO NULL
IF rm_n01.n01_estado <> 'A' THEN
	CALL fl_mostrar_mensaje('Compañía no esta activa.', 'stop')
	EXIT PROGRAM
END IF
LET rm_par.n41_ano         = rm_n01.n01_ano_proceso - 1
LET rm_par.n41_estado      = 'A'
LET rm_par.n_estado        = 'ACTIVO'
LET rm_par.n41_porc_trabaj = rm_n00.n00_uti_trabaj
LET rm_par.n41_porc_cargas = rm_n00.n00_uti_cargas
LET rm_par.n41_util_bonif  = 'U'
LET tot_porc               = rm_par.n41_porc_trabaj + rm_par.n41_porc_cargas
DISPLAY BY NAME rm_par.*, tot_porc
IF utilidades_entregadas() = 2 THEN
	CALL fl_hacer_pregunta('Ya se han distribuido las utilidades, si continua perdera lo grabado anteriormente. Desea continuar?', 'No')
		RETURNING resp
	IF resp <> 'Yes' THEN
		RETURN
	END IF
END IF
IF utilidades_entregadas() = 0 THEN
	CALL fl_mostrar_mensaje('Ya existe una liquidación cerrada, consúltela.', 'exclamation')
	RETURN
END IF
LET fecha_ini = MDY(rm_n03.n03_mes_ini, rm_n03.n03_dia_ini, rm_par.n41_ano)
LET fecha_fin = MDY(rm_n03.n03_mes_fin, rm_n03.n03_dia_fin, rm_par.n41_ano)
BEGIN WORK
WHENEVER ERROR CONTINUE
	DELETE FROM rolt049
		WHERE n49_compania  = vg_codcia
		  AND n49_proceso   = vm_proceso
		  AND n49_fecha_ini = fecha_ini
		  AND n49_fecha_fin = fecha_fin
	IF STATUS < 0 THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No se pudo borrar detalle de descuentos de utilidades (rolt049). Intente mas tarde.', 'stop')
		EXIT PROGRAM
	END IF
	DELETE FROM rolt042
		WHERE n42_compania = vg_codcia
		  AND n42_ano      = rm_par.n41_ano
	IF STATUS < 0 THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No se pudo borrar detalle de distribucion de utilidades (rolt042). Intente mas tarde.', 'stop')
		EXIT PROGRAM
	END IF
	DELETE FROM rolt041
		WHERE n41_compania = vg_codcia
		  AND n41_ano      = rm_par.n41_ano
	IF STATUS < 0 THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No se pudo borrar cabecera de distribucion de utilidades (rolt041). Intente mas tarde.', 'stop')
		EXIT PROGRAM
	END IF
	WHENEVER ERROR STOP
	CALL ingresar_valores()
	IF int_flag THEN
		ROLLBACK WORK
		IF vm_row_current > 0 THEN
			CALL mostrar_registro(vm_r_rows[vm_row_current])
		ELSE
			CLEAR FORM
			INITIALIZE rm_par.* TO NULL
			CALL mostrar_botones()
		END IF
		RETURN
	END IF
	CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
	IF resp <> 'Yes' THEN
		ROLLBACK WORK
		EXIT PROGRAM	
	END IF
	INSERT INTO rolt041
		VALUES (vg_codcia, vm_proceso, fecha_ini, fecha_fin,
			rm_par.n41_ano, rm_par.n41_estado,rm_par.n41_util_bonif,
			rm_par.n41_porc_trabaj, rm_par.n41_porc_cargas,
			rm_par.n41_val_trabaj, rm_par.n41_val_cargas,
			rm_n00.n00_moneda_pago, 1, vg_usuario, CURRENT) 
	LET vm_num_nov = 0
	MESSAGE 'Se están distribuyendo las utilidades entre los trabajadores. Por favor, espere...' 
	CALL genera_novedades()
	MESSAGE '' 
COMMIT WORK
CALL control_consulta(1)
LET mensaje = 'Las utilidades se distribuyeron entre ', vm_num_nov USING '<<<&',
              ' trabajadores. '
CALL fl_mostrar_mensaje(mensaje, 'info')

END FUNCTION



FUNCTION genera_novedades()
DEFINE r_trab		RECORD 
				cod_trab	LIKE rolt042.n42_cod_trab,
				nombres		LIKE rolt030.n30_nombres,
				estado		LIKE rolt030.n30_estado,
				fecha_ing	LIKE rolt030.n30_fecha_ing,
				fecha_reing	LIKE rolt030.n30_fecha_reing,
				fecha_sal	LIKE rolt030.n30_fecha_sal,
				cod_depto	LIKE rolt030.n30_cod_depto,
				tipo_pago	LIKE rolt042.n42_tipo_pago,
				bco_empresa	LIKE rolt042.n42_bco_empresa,
				cta_empresa	LIKE rolt042.n42_cta_empresa,
				cta_trabaj	LIKE rolt042.n42_cta_trabaj,
				dias_trab	INTEGER,
				num_cargas	INTEGER,
				descuentos	DECIMAL(22,10)
			END RECORD
DEFINE r_n42		RECORD LIKE rolt042.*
DEFINE fecha		LIKE rolt042.n42_fecha_ing
DEFINE fecha_ing	LIKE rolt042.n42_fecha_ing
DEFINE fecha_sal	LIKE rolt042.n42_fecha_sal
DEFINE fecha_ini	LIKE rolt042.n42_fecha_ini
DEFINE fecha_fin	LIKE rolt042.n42_fecha_fin
DEFINE tot_val_trabaj  	DECIMAL(22,10)
DEFINE tot_val_cargas  	DECIMAL(22,10)
DEFINE tot_dsctos  	DECIMAL(22,10)
DEFINE tot_valor	DECIMAL(22,10)
DEFINE tot_dias		INTEGER
DEFINE tot_dias_cargas	INTEGER
DEFINE tot_cargas, i	SMALLINT
DEFINE n_dias, ult_dia	SMALLINT
DEFINE factor_dias	DECIMAL(28, 20)
DEFINE factor_cargas	DECIMAL(28, 20)
DEFINE fec		DATE
DEFINE query		CHAR(3000)

CREATE TEMP TABLE te_trab (
	cod_trab		INTEGER,
	nombres			VARCHAR(45,25),
	estado			CHAR(1),
	fecha_ing		DATE,
	fecha_reing		DATE,
	fecha_sal		DATE,
	cod_depto		SMALLINT,
	tipo_pago		CHAR(1),
	bco_empresa		INTEGER,
	cta_empresa		CHAR(15),
	cta_trabaj		CHAR(15),
	dias_trab		INTEGER,
	num_cargas		INTEGER,
	descuentos		DECIMAL(22,10)
)

CREATE TEMP TABLE tmp_desctos
	(
		compania	INTEGER,
		proceso		CHAR(2),
		cod_trab	INTEGER,
		fecha_ini	DATE,
		fecha_fin	DATE,
		cod_rubd	SMALLINT,
		num_pre		INTEGER,
		n06_orden	SMALLINT,
		n06_det_tot	CHAR(2),
		n06_imprime_0	CHAR(1),
		saldo		DECIMAL(22,10)
	)

{--
LET query = 'INSERT INTO te_trab ',
		'SELECT n30_cod_trab, n30_nombres, n30_estado, n30_fecha_ing, ',
			'n30_fecha_reing, n30_fecha_sal, n30_cod_depto, ',
			'CASE WHEN n30_estado = "I" ',
				'THEN "C" ',
				'ELSE n30_tipo_pago ',
			'END, n30_bco_empresa, n30_cta_empresa, ',
			'CASE WHEN n30_estado = "I" ',
				'THEN "" ',
				'ELSE n30_cta_trabaj ',
			'END, 0, 0, 0 ',
			' FROM rolt030 ',
			' WHERE n30_compania    = ', vg_codcia,
			'   AND n30_fecha_ing  <= "',
				DATE(MDY(rm_n03.n03_mes_fin, rm_n03.n03_dia_fin,
					 rm_par.n41_ano)), '"',
			'   AND n30_fecha_sal  IS NULL ',
			'   AND n30_tipo_contr  = "F" ',
			'   AND n30_estado     <> "J" ',
			'   AND n30_tipo_trab   = "N" ',
			'   AND n30_fec_jub    IS NULL '
PREPARE exec_tmp1 FROM query
EXECUTE exec_tmp1
INSERT INTO te_trab
	SELECT n30_cod_trab, n30_nombres, n30_estado, n30_fecha_ing,
		n30_fecha_reing, n30_fecha_sal, n30_cod_depto, n30_tipo_pago,
		n30_bco_empresa, n30_cta_empresa, n30_cta_trabaj, 0, 0, 0  
		FROM rolt030 
		WHERE n30_compania    = vg_codcia
		  AND n30_fecha_sal  >= MDY(rm_n03.n03_mes_ini,
					rm_n03.n03_dia_ini, rm_par.n41_ano)
		  AND n30_tipo_contr  = 'F'
		  AND n30_estado      = 'J'
		  AND n30_tipo_trab   = 'N'
		  AND n30_fec_jub    IS NOT NULL
LET query = 'INSERT INTO te_trab ',
		'SELECT n30_cod_trab, n30_nombres, n30_estado, n30_fecha_ing, ',
			'n30_fecha_reing, n30_fecha_sal, n30_cod_depto, ',
			'CASE WHEN n30_estado = "I" ',
				'THEN "C" ',
				'ELSE n30_tipo_pago ',
			'END, n30_bco_empresa, n30_cta_empresa, ',
			'CASE WHEN n30_estado = "I" ',
				'THEN "" ',
				'ELSE n30_cta_trabaj ',
			'END, 0, 0, 0 ',
			' FROM rolt030 ',
			' WHERE n30_compania    = ', vg_codcia,
			'   AND n30_fecha_ing  <= "',
				DATE(MDY(rm_n03.n03_mes_fin, rm_n03.n03_dia_fin,
					 rm_par.n41_ano)), '"',
			'   AND n30_fecha_sal  <= "',
				DATE(MDY(rm_n03.n03_mes_fin, rm_n03.n03_dia_fin,
					 rm_par.n41_ano + 1)), '"',
			'   AND n30_tipo_contr  = "F" ',
			'   AND n30_estado     <> "J" ',
			'   AND n30_tipo_trab   = "N" ',
			'   AND n30_fec_jub    IS NULL '
PREPARE exec_tmp2 FROM query
EXECUTE exec_tmp2
DELETE FROM te_trab
	WHERE fecha_reing > MDY(rm_n03.n03_mes_fin, rm_n03.n03_dia_fin,
				rm_par.n41_ano)
DELETE FROM te_trab 
	WHERE te_trab.fecha_sal < MDY(rm_n03.n03_mes_ini, rm_n03.n03_dia_ini,
					rm_par.n41_ano)
	AND (fecha_reing IS NULL OR 
	     fecha_reing > MDY(rm_n03.n03_mes_fin, rm_n03.n03_dia_fin,
				rm_par.n41_ano))
DELETE FROM te_trab 
	WHERE te_trab.fecha_sal         < MDY(rm_n03.n03_mes_ini,
						rm_n03.n03_dia_ini,
						rm_par.n41_ano)
	  AND YEAR(te_trab.fecha_reing) = YEAR(te_trab.fecha_sal)
--}
LET fecha_ini       = MDY(rm_n03.n03_mes_ini, rm_n03.n03_dia_ini,rm_par.n41_ano)
LET fecha_fin       = MDY(rm_n03.n03_mes_fin, rm_n03.n03_dia_fin,rm_par.n41_ano)
CALL cargar_tabla_temp(0, 0)
DECLARE q_te_trab CURSOR FOR SELECT * FROM te_trab ORDER BY nombres 
LET tot_dias        = 0
LET tot_cargas      = 0
LET tot_dias_cargas = 0
FOREACH q_te_trab INTO r_trab.*
	--CALL retorna_num_cargas(r_trab.cod_trab, fecha_fin) RETURNING r_trab.num_cargas
	LET fecha_ing = r_trab.fecha_ing
	IF r_trab.fecha_reing IS NOT NULL THEN
		LET fecha_ing = r_trab.fecha_reing
	END IF
	IF fecha_ing < fecha_ini THEN
		LET fecha_ing = fecha_ini 
	END IF
	LET fecha_sal = fecha_fin 
	IF r_trab.fecha_sal IS NOT NULL THEN
		IF r_trab.fecha_sal <= fecha_sal AND
		   r_trab.fecha_sal > fecha_ing
		THEN
			LET fecha_sal = r_trab.fecha_sal 
		END IF
	END IF
	--LET r_trab.dias_trab = fecha_sal - fecha_ing + 1
	{--
	LET r_trab.dias_trab = retorna_num_meses(fecha_ing, fecha_sal)
				* rm_n00.n00_dias_mes
	LET n_dias           = rm_n00.n00_dias_mes
	IF ((DAY(r_trab.fecha_ing) > 1 AND
	     YEAR(r_trab.fecha_ing) = rm_par.n41_ano) OR
	    (DAY(r_trab.fecha_reing) > 1 AND
	     YEAR(r_trab.fecha_reing) = rm_par.n41_ano)) AND
	   r_trab.estado <> 'J'
	THEN
		LET fec = r_trab.fecha_ing
		IF r_trab.fecha_reing IS NOT NULL THEN
			LET fec = r_trab.fecha_reing
		END IF
		LET ult_dia = DAY(MDY(MONTH(fec), 01, YEAR(fec))
				+ 1 UNITS MONTH - 1 UNITS DAY)
		IF ult_dia > rm_n00.n00_dias_mes THEN
			LET ult_dia = rm_n00.n00_dias_mes
		END IF
		LET n_dias = ult_dia - DAY(fec) + 1
	END IF
	IF YEAR(r_trab.fecha_sal) = rm_par.n41_ano AND r_trab.estado = 'I' THEN
		LET n_dias = DAY(r_trab.fecha_sal)
		IF (n_dias > rm_n00.n00_dias_mes) OR
		   (MONTH(r_trab.fecha_sal) = 2 AND DAY(r_trab.fecha_sal) >= 28)
		THEN
			LET n_dias = rm_n00.n00_dias_mes
		END IF
	END IF
	LET r_trab.dias_trab = r_trab.dias_trab + n_dias
	IF r_trab.dias_trab > rm_n90.n90_dias_ano_ut THEN
		LET r_trab.dias_trab = rm_n90.n90_dias_ano_ut
	END IF
	--}
	if r_trab.cod_trab = 455 then
		let r_trab.dias_trab = 24
	end if
	CALL insertar_descuentos(r_trab.cod_trab, fecha_ini, fecha_fin)
	SELECT NVL(SUM(saldo), 0)
		INTO r_trab.descuentos
		FROM tmp_desctos
		WHERE cod_trab = r_trab.cod_trab
	UPDATE te_trab
		SET num_cargas = r_trab.num_cargas,
		    dias_trab  = r_trab.dias_trab,
		    descuentos = r_trab.descuentos 
		WHERE cod_trab = r_trab.cod_trab
	LET tot_dias        = tot_dias   + r_trab.dias_trab
	LET tot_dias_cargas = tot_dias_cargas + 
				      (r_trab.dias_trab * r_trab.num_cargas)
	LET tot_cargas      = tot_cargas + r_trab.num_cargas
END FOREACH
LET factor_dias    = rm_par.n41_val_trabaj / tot_dias
LET factor_cargas  = rm_par.n41_val_cargas / tot_dias_cargas
LET tot_val_trabaj = 0
LET tot_val_cargas = 0
LET vm_numelm      = 1
LET vm_num_nov     = 0
FOREACH q_te_trab INTO r_trab.*
	LET rm_scr[vm_numelm].n_trab         = r_trab.nombres 
	LET rm_scr[vm_numelm].n42_val_trabaj = r_trab.dias_trab * factor_dias 
	LET rm_scr[vm_numelm].n42_num_cargas = r_trab.num_cargas
	LET rm_scr[vm_numelm].n42_val_cargas = r_trab.dias_trab * 
                                               r_trab.num_cargas * 
                                               factor_cargas
	IF r_trab.descuentos IS NULL THEN
		LET r_trab.descuentos = 0
	END IF
	LET rm_scr[vm_numelm].n42_descuentos = r_trab.descuentos 
	LET rm_scr[vm_numelm].subtotal = (rm_scr[vm_numelm].n42_val_trabaj +
   			 	 	  rm_scr[vm_numelm].n42_val_cargas) -  
   			 	 	  rm_scr[vm_numelm].n42_descuentos   
	LET vm_cod_trab[vm_numelm].n42_cod_trab    = r_trab.cod_trab	
	LET vm_cod_trab[vm_numelm].n42_cod_depto   = r_trab.cod_depto
	LET vm_cod_trab[vm_numelm].n42_tipo_pago   = r_trab.tipo_pago
	LET vm_cod_trab[vm_numelm].n42_bco_empresa = r_trab.bco_empresa
	LET vm_cod_trab[vm_numelm].n42_cta_empresa = r_trab.cta_empresa
	LET vm_cod_trab[vm_numelm].n42_cta_trabaj  = r_trab.cta_trabaj	 
	LET vm_cod_trab[vm_numelm].n42_dias_trab   = r_trab.dias_trab	 
	INITIALIZE r_n42.* TO NULL
	LET r_n42.n42_compania    = vg_codcia
	LET r_n42.n42_proceso     = vm_proceso
	LET r_n42.n42_cod_trab    = r_trab.cod_trab
	LET r_n42.n42_fecha_ini   = fecha_ini
	LET r_n42.n42_fecha_fin   = fecha_fin
	LET r_n42.n42_ano         = rm_par.n41_ano
	LET r_n42.n42_cod_depto   = r_trab.cod_depto
	LET r_n42.n42_fecha_ing   = r_trab.fecha_ing
	IF r_trab.fecha_reing IS NOT NULL THEN
		LET r_n42.n42_fecha_ing   = r_trab.fecha_reing
	END IF
	LET r_n42.n42_fecha_sal   = r_trab.fecha_sal
	LET r_n42.n42_dias_trab   = vm_cod_trab[vm_numelm].n42_dias_trab
	LET r_n42.n42_num_cargas  = rm_scr[vm_numelm].n42_num_cargas
	LET r_n42.n42_val_trabaj  = rm_scr[vm_numelm].n42_val_trabaj
	LET r_n42.n42_val_cargas  = rm_scr[vm_numelm].n42_val_cargas
	LET r_n42.n42_descuentos  = rm_scr[vm_numelm].n42_descuentos 
	LET r_n42.n42_tipo_pago   = r_trab.tipo_pago
	LET r_n42.n42_bco_empresa = r_trab.bco_empresa
	LET r_n42.n42_cta_empresa = r_trab.cta_empresa
	LET r_n42.n42_cta_trabaj  = r_trab.cta_trabaj
	INSERT INTO rolt042 VALUES(r_n42.*)
	INSERT INTO rolt049
		SELECT * FROM tmp_desctos
			WHERE cod_trab = r_trab.cod_trab
	LET tot_val_trabaj = tot_val_trabaj + r_n42.n42_val_trabaj
	LET tot_val_cargas = tot_val_cargas + r_n42.n42_val_cargas
	LET vm_numelm      = vm_numelm  + 1
	LET vm_num_nov     = vm_num_nov + 1
	IF vm_numelm > vm_maxelm THEN
		ROLLBACK WORK
                CALL fl_mensaje_arreglo_incompleto()
                EXIT PROGRAM
	END IF
END FOREACH
LET vm_numelm = vm_numelm - 1
--CALL distribuir_picos(1, vm_numelm)
DROP TABLE te_trab
DROP TABLE tmp_desctos
SELECT * INTO rm_n05.*
	FROM rolt005
	WHERE n05_compania = vg_codcia
	  AND n05_proceso  = vm_proceso
IF STATUS = NOTFOUND THEN
        INITIALIZE rm_n05.* TO NULL
        LET rm_n05.n05_compania   = vg_codcia
        LET rm_n05.n05_proceso    = vm_proceso
        LET rm_n05.n05_activo     = 'S'
        LET rm_n05.n05_fecini_act = fecha_ini
        LET rm_n05.n05_fecfin_act = fecha_fin
        LET rm_n05.n05_fec_ultcie = CURRENT
        LET rm_n05.n05_fec_cierre = CURRENT
        LET rm_n05.n05_usuario    = vg_usuario
        LET rm_n05.n05_fecing     = CURRENT
        INSERT INTO rolt005 VALUES (rm_n05.*)
ELSE
        LET rm_n05.n05_activo = 'S'
        UPDATE rolt005
		SET n05_activo = 'S',
		    n05_fecini_act = fecha_ini,
		    n05_fecfin_act = fecha_fin
	        WHERE n05_compania = vg_codcia
	          AND n05_proceso  = vm_proceso
END IF
IF vm_num_rows >= 0 THEN
	LET vm_num_rows = vm_num_rows + 1
ELSE
	LET vm_num_rows = 1
END IF
IF vm_num_rows IS NULL THEN
	LET vm_num_rows = 1
END IF
LET vm_row_current = vm_num_rows
LET int_flag = 0
CALL set_count(vm_numelm)
DISPLAY ARRAY rm_scr TO ra_scr.*
	ON KEY(F5)
		CALL mostrar_descuentos(arr_curr())
		LET int_flag = 0
	BEFORE DISPLAY
                --#CALL dialog.keysetlabel('F5','Descuentos')
                LET vm_filas_pant = fgl_scr_size('ra_scr')
		CALL calcula_totales() RETURNING tot_val_trabaj, 
 						 tot_val_cargas,
						 tot_dsctos,
						 tot_valor
		DISPLAY BY NAME tot_val_trabaj, tot_val_cargas, tot_dsctos,
				tot_valor
		EXIT DISPLAY
	BEFORE ROW
		LET i = arr_curr()
		CALL muestra_etiquetas(i, vm_numelm)
END DISPLAY
CALL muestra_contadores_det(0, vm_numelm)
CALL mostrar_salir_det()
	
END FUNCTION



FUNCTION regenerar_novedades_empleado(cod_trab, ini, lim)
DEFINE cod_trab		LIKE rolt042.n42_cod_trab
DEFINE ini, lim		SMALLINT
DEFINE r_trab		RECORD 
				cod_trab	LIKE rolt042.n42_cod_trab,
				nombres		LIKE rolt030.n30_nombres,
				estado		LIKE rolt030.n30_estado,
				fecha_ing	LIKE rolt030.n30_fecha_ing,
				fecha_reing	LIKE rolt030.n30_fecha_reing,
				fecha_sal	LIKE rolt030.n30_fecha_sal,
				cod_depto	LIKE rolt030.n30_cod_depto,
				tipo_pago	LIKE rolt042.n42_tipo_pago,
				bco_empresa	LIKE rolt042.n42_bco_empresa,
				cta_empresa	LIKE rolt042.n42_cta_empresa,
				cta_trabaj	LIKE rolt042.n42_cta_trabaj,
				dias_trab	INTEGER,
				num_cargas	INTEGER,
				descuentos	DECIMAL(22,10)
			END RECORD
DEFINE r_trab_aux	RECORD 
				cod_trab	LIKE rolt042.n42_cod_trab,
				nombres		LIKE rolt030.n30_nombres,
				estado		LIKE rolt030.n30_estado,
				fecha_ing	LIKE rolt030.n30_fecha_ing,
				fecha_reing	LIKE rolt030.n30_fecha_reing,
				fecha_sal	LIKE rolt030.n30_fecha_sal,
				cod_depto	LIKE rolt030.n30_cod_depto,
				tipo_pago	LIKE rolt042.n42_tipo_pago,
				bco_empresa	LIKE rolt042.n42_bco_empresa,
				cta_empresa	LIKE rolt042.n42_cta_empresa,
				cta_trabaj	LIKE rolt042.n42_cta_trabaj,
				dias_trab	INTEGER,
				num_cargas	INTEGER,
				descuentos	DECIMAL(22,10)
			END RECORD
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n42		RECORD LIKE rolt042.*
DEFINE fecha		LIKE rolt042.n42_fecha_ing
DEFINE fecha_ing	LIKE rolt042.n42_fecha_ing
DEFINE fecha_sal	LIKE rolt042.n42_fecha_sal
DEFINE fecha_ini	LIKE rolt042.n42_fecha_ini
DEFINE fecha_fin	LIKE rolt042.n42_fecha_fin
DEFINE tot_dias		INTEGER
DEFINE tot_dias_cargas	INTEGER
DEFINE tot_cargas	SMALLINT
DEFINE n_dias, ult_dia	SMALLINT
DEFINE factor_dias	DECIMAL(28, 20)
DEFINE factor_cargas	DECIMAL(28, 20)
DEFINE fec		DATE
DEFINE query		CHAR(3000)

IF rm_par.n41_estado = 'P' THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No se puede modificar. La liquidación ya fue procesada.', 'stop')
	EXIT PROGRAM
END IF
INITIALIZE r_n42.* TO NULL
SELECT * INTO r_n42.*
	FROM rolt042
	WHERE n42_compania = vg_codcia
	  AND n42_proceso  = vm_proceso
	  AND n42_cod_trab = cod_trab
	  AND n42_ano      = rm_par.n41_ano
WHENEVER ERROR CONTINUE
DELETE FROM rolt049
	WHERE n49_compania  = vg_codcia
	  AND n49_proceso   = vm_proceso
	  AND n49_cod_trab  = cod_trab
	  AND n49_fecha_ini = r_n42.n42_fecha_ini
	  AND n49_fecha_fin = r_n42.n42_fecha_fin
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No se pudo borrar detalle de liquidacion de decimos (rolt049). Intente mas tarde.', 'stop')
	EXIT PROGRAM
END IF
DELETE FROM rolt042
	WHERE n42_compania  = vg_codcia
	  AND n42_proceso   = vm_proceso
	  AND n42_cod_trab  = cod_trab
	  AND n42_fecha_ini = r_n42.n42_fecha_ini
	  AND n42_fecha_fin = r_n42.n42_fecha_fin
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No se pudo borrar cabecera de liquidacion de decimos (rolt042). Intente mas tarde.', 'stop')
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
CALL fl_lee_trabajador_roles(vg_codcia, cod_trab) RETURNING r_n30.*
IF r_n30.n30_cod_trab IS NULL THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No existe codigo de trabajador.', 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_proceso_roles(vm_proceso) RETURNING rm_n03.*
CREATE TEMP TABLE te_trab (
	cod_trab		INTEGER,
	nombres			VARCHAR(45,25),
	estado			CHAR(1),
	fecha_ing		DATE,
	fecha_reing		DATE,
	fecha_sal		DATE,
	cod_depto		SMALLINT,
	tipo_pago		CHAR(1),
	bco_empresa		INTEGER,
	cta_empresa		CHAR(15),
	cta_trabaj		CHAR(15),
	dias_trab		INTEGER,
	num_cargas		INTEGER,
	descuentos		DECIMAL(22,10)
)
CREATE TEMP TABLE tmp_desctos
	(
		compania	INTEGER,
		proceso		CHAR(2),
		cod_trab	INTEGER,
		fecha_ini	DATE,
		fecha_fin	DATE,
		cod_rubd	SMALLINT,
		num_pre		INTEGER,
		n06_orden	SMALLINT,
		n06_det_tot	CHAR(2),
		n06_imprime_0	CHAR(1),
		saldo		DECIMAL(22,10)
	)
{--
LET query = 'INSERT INTO te_trab ',
		'SELECT n30_cod_trab, n30_nombres, n30_estado, n30_fecha_ing, ',
			'n30_fecha_reing, n30_fecha_sal, n30_cod_depto, ',
			'CASE WHEN n30_estado = "I" ',
				'THEN "C" ',
				'ELSE n30_tipo_pago ',
			'END, n30_bco_empresa, n30_cta_empresa, ',
			'CASE WHEN n30_estado = "I" ',
				'THEN "" ',
				'ELSE n30_cta_trabaj ',
			'END, 0, 0, 0 ',
			' FROM rolt030 ',
			' WHERE n30_compania    = ', vg_codcia,
			'   AND n30_fecha_ing  <= "',
				DATE(MDY(rm_n03.n03_mes_fin, rm_n03.n03_dia_fin,
					 rm_par.n41_ano)), '"',
			'   AND n30_fecha_sal  IS NULL ',
			'   AND n30_tipo_contr  = "F" ',
			'   AND n30_estado     <> "J" ',
			'   AND n30_tipo_trab   = "N" ',
			'   AND n30_fec_jub    IS NULL '
PREPARE exec_tmp3 FROM query
EXECUTE exec_tmp3
INSERT INTO te_trab
	SELECT n30_cod_trab, n30_nombres, n30_estado, n30_fecha_ing,
		n30_fecha_reing, n30_fecha_sal, n30_cod_depto, n30_tipo_pago,
		n30_bco_empresa, n30_cta_empresa, n30_cta_trabaj, 0, 0, 0  
		FROM rolt030 
		WHERE n30_compania    = vg_codcia
		  AND n30_fecha_sal  >= MDY(rm_n03.n03_mes_ini,
					rm_n03.n03_dia_ini, rm_par.n41_ano)
		  AND n30_tipo_contr  = 'F'
		  AND n30_estado      = 'J'
		  AND n30_tipo_trab   = 'N'
		  AND n30_fec_jub    IS NOT NULL
LET query = 'INSERT INTO te_trab ',
		'SELECT n30_cod_trab, n30_nombres, n30_estado, n30_fecha_ing, ',
			'n30_fecha_reing, n30_fecha_sal, n30_cod_depto, ',
			'CASE WHEN n30_estado = "I" ',
				'THEN "C" ',
				'ELSE n30_tipo_pago ',
			'END, n30_bco_empresa, n30_cta_empresa, ',
			'CASE WHEN n30_estado = "I" ',
				'THEN "" ',
				'ELSE n30_cta_trabaj ',
			'END, 0, 0, 0 ',
			' FROM rolt030 ',
			' WHERE n30_compania    = ', vg_codcia,
			'   AND n30_fecha_ing  <= "',
				DATE(MDY(rm_n03.n03_mes_fin, rm_n03.n03_dia_fin,
					 rm_par.n41_ano)), '"',
			'   AND n30_fecha_sal  <= "',
				DATE(MDY(rm_n03.n03_mes_fin, rm_n03.n03_dia_fin,
					 rm_par.n41_ano + 1)), '"',
			'   AND n30_tipo_contr  = "F" ',
			'   AND n30_estado     <> "J" ',
			'   AND n30_tipo_trab   = "N" ',
			'   AND n30_fec_jub    IS NULL '
PREPARE exec_tmp4 FROM query
EXECUTE exec_tmp4
DELETE FROM te_trab
	WHERE fecha_reing > MDY(rm_n03.n03_mes_fin, rm_n03.n03_dia_fin,
				rm_par.n41_ano)
DELETE FROM te_trab 
	WHERE te_trab.fecha_sal < MDY(rm_n03.n03_mes_ini, rm_n03.n03_dia_ini,
				rm_par.n41_ano)
	AND (fecha_reing IS NULL OR 
	     fecha_reing > MDY(rm_n03.n03_mes_fin, rm_n03.n03_dia_fin,
				rm_par.n41_ano))
--}
LET fecha_ini       = r_n42.n42_fecha_ini
LET fecha_fin       = r_n42.n42_fecha_fin
CALL cargar_tabla_temp(1, cod_trab)
DECLARE q_te_trab2 CURSOR FOR SELECT * FROM te_trab ORDER BY nombres 
LET tot_dias        = 0
LET tot_cargas      = 0
LET tot_dias_cargas = 0
FOREACH q_te_trab2 INTO r_trab.*
	--CALL retorna_num_cargas(r_trab.cod_trab, r_n42.n42_fecha_fin)
	--	RETURNING r_trab.num_cargas
	LET fecha_ing = r_trab.fecha_ing
	IF r_trab.fecha_reing IS NOT NULL THEN
		LET fecha_ing = r_trab.fecha_reing
	END IF
	IF fecha_ing < fecha_ini THEN
		LET fecha_ing = fecha_ini 
	END IF
	LET fecha_sal = fecha_fin 
	IF r_trab.fecha_sal IS NOT NULL THEN
		IF r_trab.fecha_sal <= fecha_sal AND
		   r_trab.fecha_sal > fecha_ing
		THEN
			LET fecha_sal = r_trab.fecha_sal 
		END IF
	END IF
	--LET r_trab.dias_trab = fecha_sal - fecha_ing + 1
	{--
	LET r_trab.dias_trab = retorna_num_meses(fecha_ing, fecha_sal)
				* rm_n00.n00_dias_mes
	LET n_dias           = rm_n00.n00_dias_mes
	IF ((DAY(r_trab.fecha_ing) > 1 AND
	     YEAR(r_trab.fecha_ing) = rm_par.n41_ano) OR
	    (DAY(r_trab.fecha_reing) > 1 AND
	     YEAR(r_trab.fecha_reing) = rm_par.n41_ano)) AND
	   r_trab.estado <> 'J'
	THEN
		LET fec = r_trab.fecha_ing
		IF r_trab.fecha_reing IS NOT NULL THEN
			LET fec = r_trab.fecha_reing
		END IF
		LET ult_dia = DAY(MDY(MONTH(fec), 01, YEAR(fec))
				+ 1 UNITS MONTH - 1 UNITS DAY)
		IF ult_dia > rm_n00.n00_dias_mes THEN
			LET ult_dia = rm_n00.n00_dias_mes
		END IF
		LET n_dias = ult_dia - DAY(fec) + 1
	END IF
	IF YEAR(r_trab.fecha_sal) = rm_par.n41_ano AND r_trab.estado = 'I' THEN
		LET n_dias = DAY(r_trab.fecha_sal)
		IF (n_dias > rm_n00.n00_dias_mes) OR
		   (MONTH(r_trab.fecha_sal) = 2 AND DAY(r_trab.fecha_sal) >= 28)
		THEN
			LET n_dias = rm_n00.n00_dias_mes
		END IF
	END IF
	LET r_trab.dias_trab = r_trab.dias_trab + n_dias
	IF r_trab.dias_trab > rm_n90.n90_dias_ano_ut THEN
		LET r_trab.dias_trab = rm_n90.n90_dias_ano_ut
	END IF
	--}
	LET tot_dias         = tot_dias + r_trab.dias_trab 
	LET tot_dias_cargas  = tot_dias_cargas + (r_trab.dias_trab
							* r_trab.num_cargas)
	LET tot_cargas       = tot_cargas + r_trab.num_cargas
	IF num_args() = 6 THEN
		IF r_trab.cod_trab = cod_trab THEN
			LET r_trab_aux.* = r_trab.*
		END IF
	END IF
END FOREACH
IF num_args() = 6 THEN
	LET r_trab.* = r_trab_aux.*
END IF
LET factor_dias   = rm_par.n41_val_trabaj / tot_dias
LET factor_cargas = rm_par.n41_val_cargas / tot_dias_cargas
CALL insertar_descuentos(r_n30.n30_cod_trab, fecha_ini, fecha_fin)
SELECT NVL(SUM(saldo), 0)
	INTO r_trab.descuentos
	FROM tmp_desctos
	WHERE cod_trab = r_n30.n30_cod_trab
CALL retorna_num_cargas(r_n30.n30_cod_trab, r_n42.n42_fecha_fin)
	RETURNING r_trab.num_cargas
INITIALIZE r_n42.* TO NULL
LET r_n42.n42_compania    = vg_codcia
LET r_n42.n42_proceso     = vm_proceso
LET r_n42.n42_cod_trab    = r_n30.n30_cod_trab
LET r_n42.n42_fecha_ini   = fecha_ini
LET r_n42.n42_fecha_fin   = fecha_fin
LET r_n42.n42_ano         = rm_par.n41_ano
LET r_n42.n42_cod_depto   = r_n30.n30_cod_depto
LET r_n42.n42_fecha_ing   = r_trab.fecha_ing
IF r_n30.n30_fecha_reing IS NOT NULL THEN
	LET r_n42.n42_fecha_ing = r_n30.n30_fecha_reing
END IF
LET r_n42.n42_fecha_sal   = r_trab.fecha_sal
LET r_n42.n42_dias_trab   = r_trab.dias_trab
LET r_n42.n42_num_cargas  = r_trab.num_cargas
LET r_n42.n42_val_trabaj  = r_trab.dias_trab * factor_dias 
LET r_n42.n42_val_cargas  = r_trab.dias_trab * r_trab.num_cargas * factor_cargas
LET r_n42.n42_descuentos  = r_trab.descuentos
LET r_n42.n42_tipo_pago   = r_n30.n30_tipo_pago
LET r_n42.n42_bco_empresa = r_n30.n30_bco_empresa
LET r_n42.n42_cta_empresa = r_n30.n30_cta_empresa
LET r_n42.n42_cta_trabaj  = r_n30.n30_cta_trabaj
INSERT INTO rolt042 VALUES(r_n42.*)
INSERT INTO rolt049 SELECT * FROM tmp_desctos WHERE cod_trab = cod_trab
DROP TABLE te_trab
DROP TABLE tmp_desctos
--CALL distribuir_picos(ini, lim)

END FUNCTION



FUNCTION cargar_tabla_temp(flag, cod_trab)
DEFINE flag		SMALLINT
DEFINE cod_trab		LIKE rolt042.n42_cod_trab
DEFINE query		CHAR(10000)
DEFINE expr_f_i_c	CHAR(600)
DEFINE expr_carg	CHAR(700)
DEFINE expr_trab	VARCHAR(100)
DEFINE expr_f_i		VARCHAR(250)
DEFINE expr_f_f		VARCHAR(250)
DEFINE subquery		VARCHAR(150)

LET expr_trab = NULL
IF flag THEN
	LET expr_trab = '   AND n30_cod_trab = ', cod_trab
END IF
LET expr_carg = 'NVL((CASE WHEN (n30_est_civil = "C" OR n30_est_civil = "U") ',
			'THEN (SELECT COUNT(n31_secuencia) ',
			'FROM rolt031 ',
			'WHERE n31_compania           = n30_compania ',
			'  AND n31_cod_trab           = n30_cod_trab ',
			'  AND n31_tipo_carga        <> "H" ',
			'  AND YEAR(n31_fecha_nacim) <= ', rm_par.n41_ano, ') ',
			'ELSE 0 ',
		'END + ',
		'(SELECT COUNT(n31_secuencia) ',
			'FROM rolt031 ',
			'WHERE n31_compania     = n30_compania ',
			'  AND n31_cod_trab     = n30_cod_trab ',
			'  AND n31_tipo_carga   = "H" ',
			'  AND n31_fecha_nacim >= DATE(MDY(',rm_n03.n03_mes_fin,
						', ', rm_n03.n03_dia_fin,
						', ', rm_par.n41_ano, ') ',
					'- 19 UNITS YEAR + 1 UNITS DAY) ',
			'  AND n31_fecha_nacim <= DATE(MDY(',rm_n03.n03_mes_fin,
						', ', rm_n03.n03_dia_fin,
						', ', rm_par.n41_ano, ')))), ',
		'0) AS carga, '
LET expr_f_i   = 'CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) < ',
				'MDY(n03_mes_ini, n03_dia_ini, ',
					rm_par.n41_ano, ') ',
			'THEN MDY(n03_mes_ini, n03_dia_ini, ', rm_par.n41_ano,
				') ',
			'ELSE NVL(n30_fecha_reing, n30_fecha_ing) ',
		'END '
LET expr_f_f   = 'CASE WHEN n30_fecha_sal > MDY(n03_mes_fin, n03_dia_fin, ',
							rm_par.n41_ano, ') ',
			'THEN MDY(n03_mes_fin, n03_dia_fin, ', rm_par.n41_ano,
				') ',
			'ELSE n30_fecha_sal ',
		'END '
LET subquery   = '(SELECT n00_dias_mes ',
			'FROM rolt000 ',
			'WHERE n00_serial = n30_compania) '
LET expr_f_i_c = 'CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) < ',
				'MDY(n03_mes_ini, n03_dia_ini, ',
					rm_par.n41_ano, ') ',
			'THEN MDY(n03_mes_ini, n03_dia_ini, ', rm_par.n41_ano,
				') ',
			'ELSE MDY(MONTH(NVL(n30_fecha_reing, n30_fecha_ing)), ',
				'CASE WHEN DAY(NVL(n30_fecha_reing, ',
						'n30_fecha_ing)) = 31 ',
					'THEN ', subquery CLIPPED, ' ',
					'ELSE DAY(NVL(n30_fecha_reing, ',
							'n30_fecha_ing)) ',
				'END, ', rm_par.n41_ano, ') ',
	    	'END '
LET query = 'SELECT n30_cod_trab, n30_nombres, n30_estado, n30_fecha_ing, ',
			'n30_fecha_reing, n30_fecha_sal, n30_cod_depto, ',
			'n30_tipo_pago, n30_bco_empresa, n30_cta_empresa, ',
			'n30_cta_trabaj, ',
			'((n03_mes_fin - MONTH(', expr_f_i CLIPPED, ')) * ',
				subquery CLIPPED, ') + ',
			'(', subquery CLIPPED, ' - ',
			'DAY(', expr_f_i_c CLIPPED, ') + 1) AS dias, ',
			expr_carg CLIPPED, ' 0 dcto ',
		'FROM rolt030, rolt003 ',
		'WHERE n30_compania             = ', vg_codcia,
			expr_trab CLIPPED,
		'  AND n30_estado               = "A" ',
		'  AND ((YEAR(n30_fecha_ing)   <= ', rm_par.n41_ano,
		'  AND   n30_fecha_sal         IS NULL) ',
		'   OR  (YEAR(n30_fecha_reing) <= ', rm_par.n41_ano,
		'  AND   n30_fecha_sal         IS NOT NULL)) ',
		'  AND n30_tipo_contr           = "F" ',
		'  AND n30_tipo_trab            = "N" ',
		'  AND n30_fec_jub             IS NULL ',
		'  AND n03_proceso              = "', vm_proceso, '"',
	' UNION ',
	'SELECT n30_cod_trab, n30_nombres, n30_estado, n30_fecha_ing, ',
			'n30_fecha_reing, n30_fecha_sal, n30_cod_depto, ',
			'n30_tipo_pago, n30_bco_empresa, n30_cta_empresa, ',
			'n30_cta_trabaj, ',
			'CASE WHEN (MONTH(', expr_f_f CLIPPED, ') - 1) >= ',
					'MONTH(', expr_f_i CLIPPED, ') ',
				'THEN (((MONTH(', expr_f_f CLIPPED, ') - 1) - ',
					'MONTH(', expr_f_i CLIPPED, ')) * ',
					subquery CLIPPED, ') + ',
					'(', subquery CLIPPED, ' - ',
					'DAY(', expr_f_i_c CLIPPED, ') + 1) ',
				'ELSE 0 ',
			'END + ',
			'CASE WHEN DAY(', expr_f_f CLIPPED, ') = 31 ',
				'THEN ', subquery CLIPPED, ' ',
				'ELSE DAY(', expr_f_f CLIPPED, ') - ',
					'CASE WHEN MONTH(', expr_f_i CLIPPED,
									') = ',
						'MONTH(', expr_f_f CLIPPED,') ',
						'THEN DAY(', expr_f_i_c CLIPPED,
							 ') - 1 ',
						'ELSE 0 ',
					'END ',
			'END + ',
			'CASE WHEN (MONTH(', expr_f_f CLIPPED, ') = 02 AND ',
				'EXTEND(', expr_f_f CLIPPED,
					', MONTH TO DAY) = ',
				'EXTEND(MDY(MONTH(', expr_f_f CLIPPED,'), 01, ',
						'YEAR(', expr_f_f CLIPPED,')) ',
					'+ 1 UNITS MONTH - 1 UNITS DAY, ',
					'MONTH TO DAY)) ',
				'THEN CASE WHEN MOD(', rm_par.n41_ano,
						', 4) = 0 ',
						'THEN 1 ',
						'ELSE 2 ',
					'END ',
				'ELSE 0 ',
			'END AS dias, ',
			expr_carg CLIPPED, ' 0 dcto ',
		'FROM rolt030, rolt003 ',
		'WHERE n30_compania         = ', vg_codcia,
			expr_trab CLIPPED,
		'  AND n30_estado           = "I" ',
		'  AND YEAR(n30_fecha_sal) >= ', rm_par.n41_ano,
		'  AND YEAR(n30_fecha_sal) <= YEAR(TODAY) ',
		'  AND n30_tipo_contr       = "F" ',
		'  AND n30_tipo_trab        = "N" ',
	 	'  AND n30_fec_jub         IS NULL ',
		'  AND n03_proceso          = "', vm_proceso, '"',
		' INTO TEMP t1 '
PREPARE exec_temp FROM query
EXECUTE exec_temp
INSERT INTO te_trab SELECT * FROM t1
DROP TABLE t1

END FUNCTION



FUNCTION retorna_num_meses(fecha1, fecha2)
DEFINE fecha1, fecha2	DATE
DEFINE num_mes		SMALLINT

LET num_mes = MONTH(fecha1) + 1
IF num_mes > MONTH(fecha2) THEN
	LET num_mes = 0
ELSE
	LET num_mes = MONTH(fecha2) - num_mes + 1
END IF
RETURN num_mes

END FUNCTION



FUNCTION retorna_num_cargas(cod_trab, fecha_fin)
DEFINE cod_trab		LIKE rolt042.n42_cod_trab
DEFINE fecha_fin	LIKE rolt042.n42_fecha_fin
DEFINE num_cargas	SMALLINT

SELECT n31_tipo_carga, COUNT(n31_secuencia) tot_carg
	FROM rolt031, rolt030
	WHERE n31_compania     = vg_codcia 
	  AND n31_cod_trab     = cod_trab 
	  AND n31_tipo_carga  <> 'H'
	  AND n31_fecha_nacim <= fecha_fin
	  AND n30_compania     = n31_compania
	  AND n30_cod_trab     = n31_cod_trab
	  AND (n30_est_civil   = 'C'
	   OR  n30_est_civil   = 'U')
	GROUP BY 1
	UNION ALL
	SELECT n31_tipo_carga, COUNT(n31_secuencia) tot_carg
		FROM rolt031
		WHERE n31_compania     = vg_codcia 
		  AND n31_cod_trab     = cod_trab 
		  AND n31_tipo_carga   = 'H'
		  AND n31_fecha_nacim >= fecha_fin - 19 UNITS YEAR + 1 UNITS DAY
		  AND n31_fecha_nacim <= fecha_fin
		GROUP BY 1
	INTO TEMP t1
SELECT NVL(SUM(tot_carg), 0) INTO num_cargas FROM t1
DROP TABLE t1
RETURN num_cargas

END FUNCTION



FUNCTION insertar_descuentos(cod_trab, fecha_ini, fecha_fin)
DEFINE cod_trab		LIKE rolt042.n42_cod_trab
DEFINE fecha_ini	LIKE rolt042.n42_fecha_ini
DEFINE fecha_fin	LIKE rolt042.n42_fecha_fin
DEFINE query 		CHAR(3000)

LET query = 'SELECT ', vg_codcia, ' AS compania, "', vm_proceso,
			'" AS proceso, ', cod_trab, ' AS cod_trab,',
			' MDY(', MONTH(fecha_ini), ', ', DAY(fecha_ini), ', ',
			YEAR(fecha_ini), ') AS fecha_ini, MDY(',
			MONTH(fecha_fin), ', ', DAY(fecha_fin), ', ',
			YEAR(fecha_fin), ') AS fecha_fin, n45_cod_rubro',
			' AS cod_rubd, n45_num_prest AS num_pre, n06_orden, ',
			'n06_det_tot, n06_imprime_0, SUM(n46_saldo) AS saldo ',
		' FROM rolt045, rolt046, rolt006 ',
		' WHERE n45_compania   = ', vg_codcia,
		'   AND n45_cod_trab   = ', cod_trab,
		'   AND n45_estado     IN ("A", "R", "P")',
		'   AND n46_compania   = n45_compania',
		'   AND n46_num_prest  = n45_num_prest',
		'   AND n46_cod_liqrol = "', vm_proceso, '"',	
		'   AND n46_fecha_ini  = MDY(', MONTH(fecha_ini),
		                         ', ', DAY(fecha_ini),
		                         ', ', YEAR(fecha_ini), ')',
		'   AND n46_fecha_fin  = MDY(', MONTH(fecha_fin),
		                         ', ', DAY(fecha_fin),
		                         ', ', YEAR(fecha_fin), ')',
		'   AND n06_cod_rubro  = n45_cod_rubro',
		' GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10',
		' HAVING SUM(n46_saldo) > 0',
		' UNION ',
		' SELECT ', vg_codcia, ' AS compania, "', vm_proceso,
			'" AS proceso, ', cod_trab, ' AS cod_trab,',
			' MDY(', MONTH(fecha_ini), ', ', DAY(fecha_ini), ', ',
			YEAR(fecha_ini), ') AS fecha_ini, MDY(',
			MONTH(fecha_fin), ', ', DAY(fecha_fin), ', ',
			YEAR(fecha_fin), ') AS fecha_fin, n10_cod_rubro',
			' AS cod_rubd, 0 AS num_pre, n06_orden, ',
			'n06_det_tot, n06_imprime_0, SUM(n10_valor) AS saldo ',
		' FROM rolt010, rolt006 ',
		' WHERE n10_compania   = ', vg_codcia,
		'   AND n10_cod_liqrol = "', vm_proceso, '"',
		'   AND n10_cod_trab   = ', cod_trab, 
		'   AND n06_cod_rubro  = n10_cod_rubro',
		' GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ',
		' INTO TEMP t1 '
PREPARE stmnt FROM query
EXECUTE stmnt
INSERT INTO tmp_desctos SELECT * FROM t1
UPDATE tmp_desctos
	SET num_pre = NULL
	WHERE cod_trab = cod_trab
	  AND num_pre  = 0
DROP TABLE t1

END FUNCTION



FUNCTION distribuir_picos(ini, lim)
DEFINE ini, lim		SMALLINT
DEFINE r_scr		ARRAY[1000] OF RECORD
				c_trab		LIKE rolt030.n30_cod_trab,
				n_trab		LIKE rolt030.n30_nombres,
				n42_val_trabaj	DECIMAL(22,10),
				n42_num_cargas 	DECIMAL(22,10),
				n42_val_cargas 	DECIMAL(22,10),
				n42_descuentos	DECIMAL(22,10),
				subtotal	DECIMAL(22,10)
			END RECORD
DEFINE dif_val_trabaj  	DECIMAL(22,10)
DEFINE dif_val_cargas  	DECIMAL(22,10)
DEFINE i, tot_reg	SMALLINT

CALL retorna_diferencias_n42() RETURNING dif_val_trabaj, dif_val_cargas
SELECT COUNT(*) INTO tot_reg
	FROM rolt042, rolt030, rolt090
	WHERE n42_compania    = vg_codcia
	  AND n42_proceso     = vm_proceso
	  AND n42_ano         = rm_par.n41_ano
	  AND n30_compania    = n42_compania
	  AND n30_cod_trab    = n42_cod_trab
	  AND n90_compania    = n42_compania
	  AND n90_dias_ano_ut > n42_dias_trab
DECLARE q_dife CURSOR FOR
	SELECT n42_cod_trab, n30_nombres, n42_val_trabaj, n42_num_cargas,
		n42_val_cargas, n42_descuentos, n42_val_trabaj + n42_val_cargas
		- n42_descuentos
		FROM rolt042, rolt030, rolt090
		WHERE n42_compania    = vg_codcia
		  AND n42_proceso     = vm_proceso
		  AND n42_ano         = rm_par.n41_ano
		  AND n30_compania    = n42_compania
		  AND n30_cod_trab    = n42_cod_trab
		  AND n90_compania    = n42_compania
		  AND n90_dias_ano_ut > n42_dias_trab
		ORDER BY n30_nombres ASC
LET i = 1
FOREACH q_dife INTO r_scr[i].*
	LET r_scr[i].n42_val_trabaj = r_scr[i].n42_val_trabaj +
				       (dif_val_trabaj / tot_reg)
	IF NOT (dif_val_cargas < 0 AND r_scr[i].n42_val_cargas = 0) THEN
		LET r_scr[i].n42_val_cargas = r_scr[i].n42_val_cargas +
					       (dif_val_cargas / tot_reg)
	END IF
	CALL buscar_act_trab_pico(r_scr[i].*, ini, lim)
	LET i = i + 1
	IF i > vm_maxelm THEN
		ROLLBACK WORK
                CALL fl_mensaje_arreglo_incompleto()
                EXIT PROGRAM
	END IF
END FOREACH
LET i = i - 1
CALL retorna_diferencias_n42() RETURNING dif_val_trabaj, dif_val_cargas
IF dif_val_trabaj <> 0 OR dif_val_cargas <> 0 THEN
	LET r_scr[i].n42_val_trabaj = r_scr[i].n42_val_trabaj +
				       (dif_val_trabaj / tot_reg)
	IF NOT (dif_val_cargas < 0 AND r_scr[i].n42_val_cargas = 0) THEN
		LET r_scr[i].n42_val_cargas = r_scr[i].n42_val_cargas +
					       (dif_val_cargas / tot_reg)
	END IF
	CALL buscar_act_trab_pico(r_scr[i].*, ini, lim)
END IF

END FUNCTION



FUNCTION retorna_diferencias_n42()
DEFINE tot_val_trabaj  	DECIMAL(22,10)
DEFINE tot_val_cargas  	DECIMAL(22,10)
DEFINE dif_val_trabaj  	DECIMAL(22,10)
DEFINE dif_val_cargas  	DECIMAL(22,10)

SELECT NVL(SUM(n42_val_trabaj), 0), NVL(SUM(n42_val_cargas), 0)
	INTO tot_val_trabaj, tot_val_cargas
	FROM rolt042
	WHERE n42_compania = vg_codcia
	  AND n42_proceso  = vm_proceso
	  AND n42_ano      = rm_par.n41_ano
LET dif_val_trabaj = rm_par.n41_val_trabaj - tot_val_trabaj
LET dif_val_cargas = rm_par.n41_val_cargas - tot_val_cargas
RETURN dif_val_trabaj, dif_val_cargas

END FUNCTION



FUNCTION buscar_act_trab_pico(r_scr, ini, lim)
DEFINE r_scr		RECORD
				c_trab		LIKE rolt030.n30_cod_trab,
				n_trab		LIKE rolt030.n30_nombres,
				n42_val_trabaj	DECIMAL(22,10),
				n42_num_cargas 	DECIMAL(22,10),
				n42_val_cargas 	DECIMAL(22,10),
				n42_descuentos	DECIMAL(22,10),
				subtotal	DECIMAL(22,10)
			END RECORD
DEFINE ini, lim, l	SMALLINT

FOR l = ini TO lim
	IF vm_cod_trab[l].n42_cod_trab = r_scr.c_trab OR arg_val(6) = 'G'
	THEN
		LET rm_scr[l].n42_val_trabaj = r_scr.n42_val_trabaj
		LET rm_scr[l].n42_val_cargas = r_scr.n42_val_cargas
		UPDATE rolt042
			SET n42_val_trabaj = rm_scr[l].n42_val_trabaj,
			    n42_val_cargas = rm_scr[l].n42_val_cargas
			WHERE n42_compania = vg_codcia
			  AND n42_cod_trab = vm_cod_trab[l].n42_cod_trab
			  AND n42_ano      = rm_par.n41_ano
		EXIT FOR
	END IF
END FOR

END FUNCTION



FUNCTION ingresar_valores()
DEFINE porc		LIKE rolt041.n41_porc_trabaj
DEFINE resp 		VARCHAR(6)

LET porc     = rm_par.n41_porc_trabaj + rm_par.n41_porc_cargas
LET int_flag = 0
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
                LET int_flag = 0
                CALL fl_mensaje_abandonar_proceso() RETURNING resp
                IF resp = 'Yes' THEN
                        LET int_flag = 1
                        EXIT INPUT
                END IF
	AFTER FIELD n41_val_trabaj
		IF rm_par.n41_val_trabaj IS NULL THEN
			NEXT FIELD n41_val_trabaj
		END IF
		LET rm_par.valor_repart = rm_par.n41_val_trabaj +
						rm_par.n41_val_cargas
		DISPLAY BY NAME rm_par.*
	AFTER FIELD n41_val_cargas
		IF rm_par.n41_val_cargas IS NULL THEN
			NEXT FIELD n41_val_cargas
		END IF
		LET rm_par.valor_repart = rm_par.n41_val_trabaj +
						rm_par.n41_val_cargas
		DISPLAY BY NAME rm_par.*
		{--
		LET rm_par.n41_val_trabaj = (rm_par.valor_repart *
					     rm_par.n41_porc_trabaj) / porc
		LET rm_par.n41_val_cargas = rm_par.valor_repart -
					     rm_par.n41_val_trabaj
		--}
	AFTER INPUT
		IF rm_par.n41_val_cargas > rm_par.n41_val_trabaj THEN
			CALL fl_mostrar_mensaje('El valor de las cargas no puede ser mayor que el valor de trabajadores.', 'exclamation')
			CONTINUE INPUT
		END IF
END INPUT
	
END FUNCTION



FUNCTION utilidades_entregadas()
DEFINE r_n41 		RECORD LIKE rolt041.*
DEFINE query		VARCHAR(1000)

INITIALIZE r_n41.* TO NULL
LET query = 'SELECT * FROM rolt041 ', 
	    ' WHERE n41_compania = ', vg_codcia,  
            '   AND n41_ano      = ', rm_n01.n01_ano_proceso - 1
PREPARE cons_util FROM query
EXECUTE cons_util INTO r_n41.*
IF r_n41.n41_compania IS NULL THEN
	RETURN 1
END IF
CASE r_n41.n41_estado
	WHEN 'A'
		RETURN 2
	WHEN 'P'
		RETURN 0
END CASE

END FUNCTION



FUNCTION muestra_etiquetas(posi, lim)
DEFINE posi, lim	SMALLINT

DISPLAY rm_scr[posi].n_trab TO nom_trab
DISPLAY BY NAME vm_cod_trab[posi].n42_dias_trab
CALL muestra_contadores_det(posi, lim)

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION mostrar_salir_det()
DEFINE i, lim		SMALLINT

FOR i = 1 TO vm_filas_pant
	CLEAR ra_scr[i].*
END FOR
LET lim = vm_numelm
IF lim > vm_filas_pant THEN
	LET lim = vm_filas_pant
END IF
FOR i = 1 TO lim
	DISPLAY rm_scr[i].* TO ra_scr[i].*
END FOR
CLEAR nom_trab, n42_dias_trab

END FUNCTION



FUNCTION lee_muestra_descuentos(currelm)
DEFINE currelm		SMALLINT
DEFINE resp		VARCHAR(6)
DEFINE i, j, salir	SMALLINT
DEFINE rubro		LIKE rolt049.n49_cod_rubro
DEFINE valor		LIKE rolt049.n49_valor
DEFINE tot_valor	LIKE rolt042.n42_descuentos
DEFINE r_n06		RECORD LIKE rolt006.*

OPEN WINDOW w_rolf222_2 AT 4,6 WITH 20 ROWS, 70 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rolf222_2 FROM '../forms/rolf222_2'
ELSE
	OPEN FORM f_rolf222_2 FROM '../forms/rolf222_2c'
END IF
DISPLAY FORM f_rolf222_2
CALL carga_descuentos(currelm)
OPTIONS
        INSERT KEY F10,
        DELETE KEY F11
LET salir = 0
WHILE (salir = 0)
	CALL set_count(vm_numdesc)
	INPUT ARRAY rm_desc WITHOUT DEFAULTS FROM ra_desc.*
	        ON KEY(INTERRUPT)
	                LET int_flag = 0
        	        CALL fl_mensaje_abandonar_proceso() RETURNING resp
	                IF resp = 'Yes' THEN
	                        LET int_flag = 1
				LET salir = 1
	                        EXIT INPUT
	                END IF
		ON KEY(F2)
			IF INFIELD(n49_cod_rubro) AND 
	                   rm_desc[i].n49_num_prest IS NULL 
	 		THEN
				CALL fl_ayuda_rubros_generales_roles('DE', 'T',
							'T', 'S', 'T', 'T')
					RETURNING r_n06.n06_cod_rubro, 
						  r_n06.n06_nombre 
				IF r_n06.n06_cod_rubro IS NOT NULL THEN
					LET rm_desc[i].n49_cod_rubro =
							r_n06.n06_cod_rubro
					LET rm_desc[i].n_rubro =
							r_n06.n06_nombre
					DISPLAY rm_desc[i].* TO ra_desc[j].*
				END IF
			END IF
		ON KEY(F5)
			LET i = arr_curr()
			IF rm_desc[i].n49_num_prest IS NULL THEN
				CONTINUE INPUT
			END IF
			CALL ver_anticipo(i)
			LET int_flag = 0
	        BEFORE INPUT
			CALL calcula_total_descuento(arr_count())
				RETURNING tot_valor   
			DISPLAY BY NAME tot_valor
	        BEFORE ROW
	                LET i = arr_curr()
	                LET j = scr_line()
			--#IF rm_desc[i].n49_num_prest IS NULL THEN
				--#CALL dialog.keysetlabel("F5","")
			--#ELSE
				--#CALL dialog.keysetlabel("F5","Anticipo")
			--#END IF
		BEFORE DELETE
			IF rm_desc[i].n49_num_prest IS NOT NULL THEN
				CALL fl_mostrar_mensaje('No puede eliminar este registro.', 'info')
				EXIT INPUT
			END IF
			CALL calcula_total_descuento(arr_count())
				RETURNING tot_valor
			DISPLAY BY NAME tot_valor
			DISPLAY rm_scr[currelm].n42_val_trabaj +
				rm_scr[currelm].n42_val_cargas -
				tot_valor
				TO subtotal
		BEFORE FIELD n49_cod_rubro
			LET rubro = rm_desc[i].n49_cod_rubro
		AFTER FIELD n49_cod_rubro
			IF (rm_desc[i].n49_cod_rubro <> rubro OR 
			    rm_desc[i].n49_cod_rubro IS NULL) AND 
			   rm_desc[i].n49_num_prest IS NOT NULL 
			THEN
				CALL fl_mostrar_mensaje('No puede modificar este registro.', 'info')
				LET rm_desc[i].n49_cod_rubro = rubro	
				DISPLAY rm_desc[i].* TO ra_desc[j].*
			END IF
			IF rm_desc[i].n49_cod_rubro IS NOT NULL THEN
				CALL fl_lee_rubro_roles(rm_desc[i].n49_cod_rubro)
					RETURNING r_n06.*
				LET rm_desc[i].n_rubro = r_n06.n06_nombre
				DISPLAY rm_desc[i].* TO ra_desc[j].*
			END IF
		BEFORE FIELD n49_valor
			LET valor = rm_desc[i].n49_valor
		AFTER FIELD n49_valor
			IF (rm_desc[i].n49_valor <> valor OR 
			    rm_desc[i].n49_valor IS NULL) AND 
			   rm_desc[i].n49_num_prest IS NOT NULL 
			THEN
				CALL fl_mostrar_mensaje('No puede modificar este registro.', 'info')
				LET rm_desc[i].n49_valor = valor	
				DISPLAY rm_desc[i].* TO ra_desc[j].*
			END IF
			IF rm_desc[i].n49_cod_rubro IS NOT NULL THEN
				IF rm_desc[i].n49_valor < 0 THEN
					NEXT FIELD n49_valor
				END IF
				DISPLAY rm_desc[i].* TO ra_desc[j].*
				CALL calcula_total_descuento(arr_count()) 
					RETURNING tot_valor
				DISPLAY BY NAME tot_valor
				DISPLAY rm_scr[currelm].n42_val_trabaj +
					rm_scr[currelm].n42_val_cargas -
					tot_valor
					TO subtotal
			END IF
		AFTER INPUT
			LET vm_numdesc = arr_count()
			CALL calcula_total_descuento(vm_numdesc)
				RETURNING tot_valor
			DISPLAY BY NAME tot_valor
			DISPLAY rm_scr[currelm].n42_val_trabaj +
				rm_scr[currelm].n42_val_cargas -
				tot_valor
				TO subtotal
			IF tot_valor > rm_scr[currelm].n42_val_trabaj +
				rm_scr[currelm].n42_val_cargas
			THEN
				CALL fl_mostrar_mensaje('El total de descuentos debe ser menor al valor del decimo.', 'info')
				CONTINUE INPUT
			END IF
			LET salir = 1 
	END INPUT
END WHILE
DELETE FROM tmp_descuentos
	WHERE n49_cod_trab = vm_cod_trab[currelm].n42_cod_trab
LET rm_scr[currelm].n42_descuentos = 0 
FOR i = 1 TO vm_numdesc
	INSERT INTO tmp_descuentos VALUES (vm_cod_trab[currelm].n42_cod_trab,
		rm_desc[i].*)
	LET rm_scr[currelm].n42_descuentos = 
		rm_scr[currelm].n42_descuentos + rm_desc[i].n49_valor  
END FOR 
LET rm_scr[currelm].subtotal = rm_scr[currelm].n42_val_trabaj
				+ rm_scr[currelm].n42_val_cargas
				- rm_scr[currelm].n42_descuentos 
LET int_flag = 0
CLOSE WINDOW w_rolf222_2
RETURN

END FUNCTION



FUNCTION calcula_total_descuento(numelm)
DEFINE numelm, i	SMALLINT
DEFINE valor            LIKE rolt049.n49_valor     
DEFINE tot_valor        LIKE rolt049.n49_valor     

LET valor     = 0
LET tot_valor = 0
FOR i = 1 TO numelm
	LET valor = rm_desc[i].n49_valor
	IF valor IS NULL THEN
		LET valor = 0
	END IF
        LET tot_valor = tot_valor + valor
END FOR
RETURN tot_valor

END FUNCTION



FUNCTION mostrar_descuentos(i)
DEFINE i, j		SMALLINT

OPEN WINDOW w_rolf222_2 AT 4,6 WITH 19 ROWS, 70 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rolf222_2 FROM '../forms/rolf222_2'
ELSE
	OPEN FORM f_rolf222_2 FROM '../forms/rolf222_2c'
END IF
DISPLAY FORM f_rolf222_2
CALL carga_descuentos(i)
CALL set_count(vm_numdesc)
DISPLAY ARRAY rm_desc TO ra_desc.*
	ON KEY(F5)
		LET j = arr_curr()
		IF rm_desc[j].n49_num_prest IS NULL THEN
			CONTINUE DISPLAY
		END IF
		CALL ver_anticipo(j)
		LET int_flag = 0
	--#BEFORE ROW 
		--#LET j = arr_curr()	
		--#IF rm_desc[j].n49_num_prest IS NULL THEN
			--#CALL dialog.keysetlabel("F5","")
		--#ELSE
			--#CALL dialog.keysetlabel("F5","Anticipo")
		--#END IF
END DISPLAY
LET int_flag = 0
CLOSE WINDOW w_rolf222_2
RETURN

END FUNCTION



FUNCTION carga_descuentos(curr_elm)
DEFINE curr_elm		SMALLINT
DEFINE i		SMALLINT
DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_g34		RECORD LIKE gent034.*

-- Muestro los otros datos primero
CALL fl_lee_departamento(vg_codcia, vm_cod_trab[curr_elm].n42_cod_depto) 
	RETURNING r_g34.*
CALL fl_lee_banco_general(vm_cod_trab[curr_elm].n42_bco_empresa) 
	RETURNING r_g08.*
DISPLAY 'Cod.'     TO bt_cod_rubro
DISPLAY 'Rubro'    TO bt_nom_rubro
DISPLAY 'Anticipo' TO bt_num_prest
DISPLAY 'Valor'    TO bt_valor
DISPLAY BY NAME vm_cod_trab[curr_elm].n42_cod_trab,
		rm_scr[curr_elm].n_trab,
		vm_cod_trab[curr_elm].n42_cod_depto,
		vm_cod_trab[curr_elm].n42_tipo_pago,
		vm_cod_trab[curr_elm].n42_bco_empresa,
		vm_cod_trab[curr_elm].n42_cta_empresa,
		vm_cod_trab[curr_elm].n42_cta_trabaj,
		rm_scr[curr_elm].n42_val_trabaj,
		rm_scr[curr_elm].n42_val_cargas,
		rm_scr[curr_elm].subtotal
DISPLAY rm_scr[curr_elm].n42_descuentos TO tot_valor
CASE vm_cod_trab[curr_elm].n42_tipo_pago
	WHEN 'E'
		DISPLAY 'EFECTIVO' TO n_tipo_pago 
	WHEN 'C'
		DISPLAY 'CHEQUE' TO n_tipo_pago 
	WHEN 'T'
		DISPLAY 'TRANSFERENCIA' TO n_tipo_pago 
END CASE
DISPLAY r_g34.g34_nombre      TO n_depto
DISPLAY r_g08.g08_nombre      TO n_banco
DECLARE q_desc CURSOR FOR 
	SELECT n49_cod_rubro, n_rubro, n49_num_prest, n49_valor
		FROM tmp_descuentos
		WHERE n49_cod_trab = vm_cod_trab[curr_elm].n42_cod_trab
LET vm_numdesc = 1
FOREACH q_desc INTO rm_desc[vm_numdesc].*
        LET vm_numdesc = vm_numdesc + 1
        IF vm_numdesc > vm_maxdesc THEN
                CALL fl_mensaje_arreglo_incompleto()
                EXIT PROGRAM
        END IF
END FOREACH
LET vm_numdesc = vm_numdesc - 1
FOR i = (vm_numdesc + 1) TO vm_maxdesc
	INITIALIZE rm_desc[i].* TO NULL
END FOR

END FUNCTION


 
FUNCTION ver_anticipo(i)
DEFINE i		SMALLINT
DEFINE param		VARCHAR(60)

LET param = ' ', rm_desc[i].n49_num_prest
CALL ejecuta_comando('NOMINA', vg_modulo, 'rolp214 ', param)

END FUNCTION



FUNCTION control_imprimir()
DEFINE param		VARCHAR(60)

LET param = ' ', rm_par.n41_ano             
CALL ejecuta_comando('NOMINA', vg_modulo, 'rolp424 ', param)
                     
END FUNCTION



FUNCTION control_imprimir_recibo(cod_trab)
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE param		VARCHAR(60)

CALL fl_lee_trabajador_roles(vg_codcia, cod_trab) RETURNING r_n30.*
LET param = ' ', rm_par.n41_ano, ' N '
IF r_n30.n30_cod_trab IS NOT NULL THEN
	LET param = param CLIPPED, ' ', r_n30.n30_cod_depto, ' ',
			r_n30.n30_cod_trab	
END IF
CALL ejecuta_comando('NOMINA', vg_modulo, 'rolp420 ', param)
                     
END FUNCTION



FUNCTION control_imprimir_informe()
DEFINE param		VARCHAR(60)

LET param = ' ', rm_par.n41_ano             
CALL ejecuta_comando('NOMINA', vg_modulo, 'rolp421 ', param)
                     
END FUNCTION



FUNCTION ejecuta_comando(modulo, mod, prog, param)
DEFINE modulo		VARCHAR(15)
DEFINE mod		LIKE gent050.g50_modulo
DEFINE prog		VARCHAR(10)
DEFINE param		VARCHAR(60)
DEFINE comando          VARCHAR(250)
DEFINE run_prog		VARCHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, modulo, vg_separador,
		'fuentes', vg_separador, run_prog, prog, vg_base, ' ', mod, ' ',
		vg_codcia, ' ', param
RUN comando

END FUNCTION



FUNCTION generar_archivo()
DEFINE query 		CHAR(6000)
DEFINE archivo		VARCHAR(100)
DEFINE mensaje		VARCHAR(200)
DEFINE nom_mes		VARCHAR(10)
DEFINE r_g31		RECORD LIKE gent031.*
DEFINE r_n41		RECORD LIKE rolt041.*

CREATE TEMP TABLE tmp_rol_ban
	(
		tipo_pago		CHAR(2),
		cuenta_empresa		CHAR(10),
		secuencia		SERIAL,
		comp_pago		CHAR(5),
		cod_trab		CHAR(6),
		moneda			CHAR(3),
		valor			VARCHAR(13),
		forma_pago		CHAR(3),
		codi_banco		CHAR(4),
		tipo_cuenta		CHAR(3),
		cuenta_empleado		CHAR(11),
		tipo_doc_id		CHAR(1),
		--num_doc_id		DECIMAL(13,0),
		num_doc_id		VARCHAR(13),
		empleado		VARCHAR(40),
		direccion		VARCHAR(40),
		ciudad			VARCHAR(20),
		telefono		VARCHAR(10),
		local_cobro		VARCHAR(10),
		referencia		VARCHAR(30),
		referencia_adic		VARCHAR(30)
	)

LET query = 'SELECT "PA" AS tip_pag, g09_numero_cta AS cuenta_empr,',
			' 0 AS secu, "" AS comp_p,n42_cod_trab AS cod_emp, ',
			'g13_simbolo AS mone, ',
			'TRUNC((n42_val_trabaj + n42_val_cargas - ',
				'n42_descuentos) * 100, 0) AS',
			' neto_rec, "CTA" AS for_pag, "0040" AS cod_ban,',
			' CASE WHEN n30_tipo_cta_tra = "A"',
				' THEN "AHO"',
				' ELSE "CTE"',
			' END AS tipo_c, n42_cta_trabaj AS cuenta_empl,',
			' n30_tipo_doc_id AS tipo_id,',
			' CASE WHEN n42_cod_trab = 24 AND ', vg_codloc, ' = 1 ',
				' THEN "0920503067"',
				' ELSE n30_num_doc_id',
			' END AS cedula,',
			' CASE WHEN n42_cod_trab = 24 AND ', vg_codloc, ' = 1 ',
				' THEN "CHILA RUA EMILIANO FRANCISCO"',
				' ELSE n30_nombres',
			' END AS empleados, n30_domicilio AS direc,',
			' g31_nombre AS ciudad_emp, n30_telef_domic AS fono,',
			' "" AS loc_cob, n03_nombre AS refer1,',
			' CASE',
				' WHEN MONTH(n41_fecing) = 01 THEN "ENERO"',
				' WHEN MONTH(n41_fecing) = 02 THEN "FEBRERO"',
				' WHEN MONTH(n41_fecing) = 03 THEN "MARZO"',
				' WHEN MONTH(n41_fecing) = 04 THEN "ABRIL"',
				' WHEN MONTH(n41_fecing) = 05 THEN "MAYO"',
				' WHEN MONTH(n41_fecing) = 06 THEN "JUNIO"',
				' WHEN MONTH(n41_fecing) = 07 THEN "JULIO"',
				' WHEN MONTH(n41_fecing) = 08 THEN "AGOSTO"',
				' WHEN MONTH(n41_fecing) = 09 THEN "SEPTIEMBRE"',
				' WHEN MONTH(n41_fecing) = 10 THEN "OCTUBRE"',
				' WHEN MONTH(n41_fecing) = 11 THEN "NOVIEMBRE"',
				' WHEN MONTH(n41_fecing) = 12 THEN "DICIEMBRE"',
			' END || "-" || LPAD(n41_ano, 4, 0) AS refer2',
		' FROM rolt041, rolt042, rolt030, gent009, gent013, gent031,',
			' rolt003 ',
		' WHERE n41_compania    = ', vg_codcia,
		'   AND n41_proceso     = "', vm_proceso, '"',
		'   AND n41_ano         = ', rm_par.n41_ano,
		'   AND n41_estado     <> "E"',
		'   AND n42_compania    = n41_compania ',
		'   AND n42_proceso     = n41_proceso ',
		'   AND n42_fecha_ini   = n41_fecha_ini ',
		'   AND n42_fecha_fin   = n41_fecha_fin ',
		'   AND n42_tipo_pago   = "T"',
		'   AND (n42_val_trabaj + n42_val_cargas - n42_descuentos) > 0',
  		'   AND n30_compania    = n42_compania ',
		'   AND n30_cod_trab    = n42_cod_trab ',
		'   AND g09_compania    = n42_compania ',
		'   AND g09_banco       = n42_bco_empresa ',
		'   AND n03_proceso     = n42_proceso ',
		'   AND g13_moneda      = n41_moneda ',
		'   AND g31_ciudad      = n30_ciudad_nac ',
		' ORDER BY 14 ',
		' INTO TEMP t1 '
PREPARE exec_dat FROM query
EXECUTE exec_dat
LET query = 'INSERT INTO tmp_rol_ban ',
		'(tipo_pago, cuenta_empresa, secuencia, comp_pago, cod_trab,',
		' moneda, valor, forma_pago, codi_banco, tipo_cuenta,',
		' cuenta_empleado, tipo_doc_id, num_doc_id, empleado,',
		' direccion, ciudad, telefono, local_cobro, referencia,',
		' referencia_adic) ',
		' SELECT * FROM t1 '
PREPARE exec_tmp FROM query
EXECUTE exec_tmp
DROP TABLE t1
LET query = 'SELECT tipo_pago, cuenta_empresa, secuencia, comp_pago, cod_trab,',
		' "USD" moneda, LPAD(valor, 13, 0) valor, forma_pago,',
		' codi_banco, tipo_cuenta,',
		' LPAD(cuenta_empleado, 11, 0) cta_emp, tipo_doc_id,',
		' LPAD(num_doc_id, 13, 0) num_doc_id,',
		' REPLACE(empleado, "ñ", "N") empleado,',
		' "" direccion, "" ciudad, "" telefono, "" local_cobro,',
		' "ROL DE PAGO" referencia, referencia_adic',
		' FROM tmp_rol_ban ',
		' INTO TEMP t1 '
PREPARE exec_t1 FROM query
EXECUTE exec_t1
DROP TABLE tmp_rol_ban
UNLOAD TO "../../../tmp/rol_pag.txt" DELIMITER "	"
	SELECT * FROM t1
		ORDER BY secuencia
INITIALIZE r_n41.* TO NULL
SELECT * INTO r_n41.*
	FROM rolt041
	WHERE n41_compania  = vg_codcia
	  AND n41_proceso   = vm_proceso
	  AND n41_ano       = rm_par.n41_ano
	  AND n41_estado   <> "E"
LET nom_mes = UPSHIFT(fl_justifica_titulo('I',
			fl_retorna_nombre_mes(MONTH(r_n41.n41_fecing)), 11))
LET archivo = "ACRE_", rm_loc.g02_nombre[1, 3] CLIPPED, "_",
		vm_proceso, nom_mes[1, 3] CLIPPED,
		YEAR(r_n41.n41_fecing) USING "####", "_"
CALL fl_lee_ciudad(rm_loc.g02_ciudad) RETURNING r_g31.*
LET archivo = archivo CLIPPED, r_g31.g31_siglas CLIPPED, ".txt"
LET mensaje = 'Archivo ', archivo CLIPPED, ' Generado ', FGL_GETENV("HOME"),
		'/tmp/  OK'
LET archivo = "mv ../../../tmp/rol_pag.txt $HOME/tmp/", archivo CLIPPED
RUN archivo
DROP TABLE t1
CALL fl_mostrar_mensaje(mensaje, 'info')

END FUNCTION 
