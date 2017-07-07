--------------------------------------------------------------------------------
-- Titulo           : rolp208.4gl - Mantenimiento Liquidacion Jubilados
-- Elaboracion      : 01-sep-2003
-- Autor            : YEC
-- Formato Ejecucion: fglrun rolp208 base modulo compania 
-- Ultima Correccion:
-- Motivo Correccion:
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_num_rows	INTEGER
DEFINE vm_row_current	INTEGER
DEFINE vm_max_rows	INTEGER
DEFINE vm_r_rows 	ARRAY [200] OF RECORD
				n48_mes_proceso	LIKE rolt048.n48_mes_proceso,
				n48_ano_proceso	LIKE rolt048.n48_ano_proceso
			END RECORD
DEFINE rm_n00		RECORD LIKE rolt000.*  
DEFINE rm_n01		RECORD LIKE rolt001.*  
DEFINE rm_n48		RECORD LIKE rolt048.*  
DEFINE rm_par		RECORD 
				n48_estado	LIKE rolt048.n48_estado,
				n48_mes_proceso	LIKE rolt048.n48_mes_proceso,
				n48_ano_proceso	LIKE rolt048.n48_ano_proceso
			END RECORD
DEFINE rm_pat		ARRAY[300] OF RECORD
				n48_cod_trab	LIKE rolt048.n48_cod_trab,
				n30_num_doc_id	LIKE rolt030.n30_num_doc_id,
				n30_nombres	LIKE rolt030.n30_nombres,
				n30_fec_jub	LIKE rolt030.n30_fec_jub,
				n48_val_jub_pat	LIKE rolt048.n48_val_jub_pat
			END RECORD
DEFINE rm_adi		ARRAY[300] OF RECORD
				n48_tipo_comp	LIKE rolt048.n48_tipo_comp,
				n48_num_comp	LIKE rolt048.n48_num_comp
			END RECORD
DEFINE rm_b00		RECORD LIKE ctbt000.*
DEFINE vm_proceso       LIKE rolt036.n36_proceso
DEFINE vm_nivel		LIKE ctbt001.b01_nivel
DEFINE vm_filas_pant 	INTEGER
DEFINE vm_numelm 	INTEGER
DEFINE vm_maxelm 	INTEGER



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp208.err')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN   -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso  = 'rolp208'
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
DEFINE i		SMALLINT
DEFINE salir 		INTEGER
DEFINE resp 		VARCHAR(6)

-- AQUI SE DEFINEN VALORES DE VARIABLES GLOBALES
LET vm_proceso  = 'JU'
LET vm_max_rows = 200
LET vm_maxelm   = 300
CALL fl_nivel_isolation()
OPEN WINDOW w_rolp208 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
			MESSAGE LINE LAST - 1) 
OPEN FORM f_rolf208_1 FROM '../forms/rolf208_1'
DISPLAY FORM f_rolf208_1
CALL fl_lee_compania_contabilidad(vg_codcia) RETURNING rm_b00.*
IF rm_b00.b00_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe ninguna compañía configurada en CONTABILIDAD.', 'stop')
	EXIT PROGRAM
END IF
SELECT MAX(b01_nivel) INTO vm_nivel FROM ctbt001
IF vm_nivel IS NULL THEN
	CALL fl_mostrar_mensaje('No existe ningun nivel de cuenta configurado en la compañía.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_parametro_general_roles() RETURNING rm_n00.*
IF rm_n00.n00_serial IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configuración general para este módulo.', 'stop')
	EXIT PROGRAM
END IF
LET vm_num_rows = 0
MENU 'OPCIONES'
	BEFORE MENU
		CALL mostrar_botones()
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Cerrar'
		HIDE OPTION 'Reabrir'
		HIDE OPTION 'Imprimir'
		HIDE OPTION 'Recibos de Pago'
		HIDE OPTION 'Detalle/Pago'
		CALL control_consulta('A')
		IF vm_num_rows > 0 THEN
			IF rm_par.n48_estado = 'A' THEN
				SHOW OPTION 'Cerrar'
				HIDE OPTION 'Reabrir'
			ELSE
				HIDE OPTION 'Cerrar'
				SHOW OPTION 'Reabrir'
			END IF
			SHOW OPTION 'Imprimir'
			SHOW OPTION 'Recibos de Pago'
			IF vm_filas_pant < vm_numelm THEN
				SHOW OPTION 'Detalle/Pago'
			ELSE
				HIDE OPTION 'Detalle/Pago'
			END IF
		END IF
       	COMMAND KEY('G') 'Generar' 'Generar liquidación mensual jubilados.'
		CALL control_generar() RETURNING i
		IF i > 0 THEN
			IF rm_par.n48_estado = 'A' THEN
				SHOW OPTION 'Cerrar'
				HIDE OPTION 'Reabrir'
			ELSE
				HIDE OPTION 'Cerrar'
				SHOW OPTION 'Reabrir'
			END IF
		END IF
		IF vm_num_rows > 0 THEN
			IF rm_par.n48_estado = 'A' THEN
				SHOW OPTION 'Cerrar'
				HIDE OPTION 'Reabrir'
			ELSE
				HIDE OPTION 'Cerrar'
				SHOW OPTION 'Reabrir'
			END IF
			SHOW OPTION 'Imprimir'
			SHOW OPTION 'Recibos de Pago'
			IF vm_filas_pant < vm_numelm THEN
				SHOW OPTION 'Detalle/Pago'
			ELSE
				HIDE OPTION 'Detalle/Pago'
			END IF
		END IF
       	COMMAND KEY('U') 'Cerrar' 'Cierra el rol activo. '
		CALL control_cerrar_reabrir('P')
		IF rm_par.n48_estado = 'A' THEN
			SHOW OPTION 'Cerrar'
			HIDE OPTION 'Reabrir'
		ELSE
			HIDE OPTION 'Cerrar'
			SHOW OPTION 'Reabrir'
		END IF
       	COMMAND KEY('O') 'Reabrir' 'Reabre el rol procesado. '
		CALL control_cerrar_reabrir('A')
		IF rm_par.n48_estado = 'A' THEN
			SHOW OPTION 'Cerrar'
			HIDE OPTION 'Reabrir'
		ELSE
			HIDE OPTION 'Cerrar'
			SHOW OPTION 'Reabrir'
		END IF
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		CALL control_consulta('')
		IF vm_num_rows <= 1 THEN
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Cerrar'
				HIDE OPTION 'Reabrir'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			IF rm_par.n48_estado = 'A' THEN
				SHOW OPTION 'Cerrar'
				HIDE OPTION 'Reabrir'
			ELSE
				HIDE OPTION 'Cerrar'
				SHOW OPTION 'Reabrir'
			END IF
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
		IF rm_par.n48_estado = 'A' THEN
			SHOW OPTION 'Cerrar'
			HIDE OPTION 'Reabrir'
		ELSE
			HIDE OPTION 'Cerrar'
			SHOW OPTION 'Reabrir'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
			SHOW OPTION 'Recibos de Pago'
			IF vm_filas_pant < vm_numelm THEN
				SHOW OPTION 'Detalle/Pago'
			ELSE
				HIDE OPTION 'Detalle/Pago'
			END IF
		END IF
	COMMAND KEY('D') 'Detalle/Pago' 
		CALL control_detalle()
	COMMAND KEY('I') 'Imprimir'
		CALL control_imprimir()
	COMMAND KEY('P') 'Recibos de Pago'
		CALL control_recibos()
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
		IF rm_par.n48_estado = 'A' THEN
			SHOW OPTION 'Cerrar'
			HIDE OPTION 'Reabrir'
		ELSE
			HIDE OPTION 'Cerrar'
			SHOW OPTION 'Reabrir'
		END IF
		IF vm_num_rows > 0 THEN
			IF vm_filas_pant < vm_numelm THEN
				SHOW OPTION 'Detalle/Pago'
			ELSE
				HIDE OPTION 'Detalle/Pago'
			END IF
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
		IF rm_par.n48_estado = 'A' THEN
			SHOW OPTION 'Cerrar'
			HIDE OPTION 'Reabrir'
		ELSE
			HIDE OPTION 'Cerrar'
			SHOW OPTION 'Reabrir'
		END IF
		IF vm_num_rows > 0 THEN
			IF vm_filas_pant < vm_numelm THEN
				SHOW OPTION 'Detalle/Pago'
			ELSE
				HIDE OPTION 'Detalle/Pago'
			END IF
		END IF
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_generar()
DEFINE resp		CHAR(10)
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n48, r_n48_2	RECORD LIKE rolt048.*
DEFINE r_n01		RECORD LIKE rolt001.*
DEFINE r_g14		RECORD LIKE gent014.*
DEFINE dias_ini, i	SMALLINT
DEFINE fecha		DATE
DEFINE mensaje		VARCHAR(100)

DECLARE q_pt CURSOR FOR 
	SELECT * FROM rolt030
		WHERE n30_estado      = 'J'
		  AND n30_val_jub_pat > 0
		ORDER BY n30_nombres
OPEN q_pt
FETCH q_pt INTO r_n30.*
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No hay trabajadores jubilados.', 'exclamation')
	RETURN 0
END IF
CALL fl_lee_compania_roles(vg_codcia) RETURNING r_n01.*
INITIALIZE r_n48.* TO NULL
DECLARE q_ultjub CURSOR FOR
	SELECT * FROM rolt048 
		WHERE n48_compania   = vg_codcia
		  AND n48_estado    <> 'E' 
		  AND n48_tipo_comp IS NULL
		ORDER BY n48_fecing DESC
OPEN q_ultjub
FETCH q_ultjub INTO r_n48.* 
IF r_n48.n48_estado = 'P' THEN
	IF r_n48.n48_ano_proceso = r_n01.n01_ano_proceso AND 
	   r_n48.n48_mes_proceso = r_n01.n01_mes_proceso
	THEN
		CALL fl_mostrar_mensaje('La jubilación del presente mes ya fue procesada.', 'exclamation')
		RETURN 0
	END IF
END IF
CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
IF resp <> 'Yes' THEN
	RETURN 0
END IF
BEGIN WORK
DELETE FROM rolt048
	WHERE n48_compania  = vg_codcia
	  AND n48_estado    = 'A'
	  AND n48_tipo_comp IS NULL
LET i = 0
LET fecha = MDY(r_n01.n01_mes_proceso, 01, r_n01.n01_ano_proceso)
CALL retorna_fin_mes(fecha) RETURNING fecha
FOREACH q_pt INTO r_n30.*
	CALL lee_reg_jub2(r_n48.n48_ano_proceso, r_n48.n48_mes_proceso,
				r_n30.n30_cod_trab)
		RETURNING r_n48_2.*
	IF r_n48_2.n48_compania IS NOT NULL THEN
		CONTINUE FOREACH
	END IF
	LET i = i + 1
	INITIALIZE r_n48.* TO NULL
	LET r_n48.n48_compania 		= vg_codcia
	LET r_n48.n48_ano_proceso 	= r_n01.n01_ano_proceso
	LET r_n48.n48_mes_proceso 	= r_n01.n01_mes_proceso
	LET r_n48.n48_cod_trab 		= r_n30.n30_cod_trab
	LET r_n48.n48_estado 		= 'A'
	LET r_n48.n48_moneda 		= r_n30.n30_mon_sueldo
	LET r_n48.n48_val_jub_pat 	= r_n30.n30_val_jub_pat
	IF EXTEND(r_n30.n30_fecha_ing, YEAR TO MONTH) =
	   EXTEND(fecha, YEAR TO MONTH)
	THEN
		LET dias_ini = (fecha - r_n30.n30_fecha_ing) + 1
		IF dias_ini > rm_n00.n00_dias_mes THEN
			LET dias_ini = rm_n00.n00_dias_mes
		END IF
		IF dias_ini = 0 THEN
			LET dias_ini = 1
		END IF
		LET r_n48.n48_val_jub_pat = (r_n30.n30_val_jub_pat /
						rm_n00.n00_dias_mes) * dias_ini
	END IF
	IF EXTEND(r_n30.n30_fecha_reing, YEAR TO MONTH) =
	   EXTEND(fecha, YEAR TO MONTH)
	THEN
		LET dias_ini = (fecha - r_n30.n30_fecha_reing) + 1
		IF dias_ini > rm_n00.n00_dias_mes THEN
			LET dias_ini = rm_n00.n00_dias_mes
		END IF
		IF dias_ini = 0 THEN
			LET dias_ini = 1
		END IF
		LET r_n48.n48_val_jub_pat = (r_n30.n30_val_jub_pat /
						rm_n00.n00_dias_mes) * dias_ini
	END IF
	LET r_n48.n48_paridad 		= 1
	IF r_n48.n48_moneda <> rg_gen.g00_moneda_base THEN
		CALL fl_lee_factor_moneda(r_n48.n48_moneda, rg_gen.g00_moneda_base)
				RETURNING r_g14.*
		IF r_g14.g14_serial IS NULL THEN
			CALL fl_mostrar_mensaje('No hay paridad cambiaria para la moneda: ' || r_n48.n48_moneda,'exclamation')
			RETURN
		END IF
		LET r_n48.n48_paridad = r_g14.g14_tasa
	END IF
	LET r_n48.n48_tipo_pago 	= r_n30.n30_tipo_pago
	IF r_n30.n30_tipo_pago <> 'E' THEN
		LET r_n48.n48_bco_empresa 	= r_n30.n30_bco_empresa
		LET r_n48.n48_cta_empresa 	= r_n30.n30_cta_empresa
		IF r_n30.n30_tipo_pago = 'T' THEN
			LET r_n48.n48_cta_trabaj = r_n30.n30_cta_trabaj
		END IF
		IF r_n48.n48_bco_empresa IS NULL THEN
			SELECT g09_banco, g09_numero_cta
				INTO r_n48.n48_bco_empresa,
					r_n48.n48_cta_empresa
				FROM rolt054, gent009
				WHERE n54_compania = vg_codcia
				  AND g09_compania = n54_compania
				  AND g09_aux_cont = n54_aux_cont
		END IF
	END IF
	LET r_n48.n48_usuario 		= vg_usuario
	LET r_n48.n48_fecing 		= CURRENT
	INSERT INTO rolt048 VALUES (r_n48.*)
END FOREACH
COMMIT WORK
LET mensaje = 'Liquidaciones generadas: ', i USING '##&'
CALL fl_mostrar_mensaje(mensaje, 'info')
IF i > 0 THEN
	CALL control_consulta('A')
END IF
RETURN i

END FUNCTION



FUNCTION mostrar_botones()

DISPLAY 'Código'		TO tit_col1
DISPLAY 'Cédula'		TO tit_col2
DISPLAY 'Nombre Jubilado' 	TO tit_col3
DISPLAY 'Fec. Jub.' 		TO tit_col4
DISPLAY 'Valor' 		TO tit_col5

END FUNCTION



FUNCTION control_consulta(estado)
DEFINE estado		CHAR(1)
DEFINE query		VARCHAR(400)
DEFINE expr_sql		VARCHAR(400)
DEFINE num_reg		INTEGER
DEFINE foo_anho		INTEGER
DEFINE r_n36		RECORD LIKE rolt036.*

INITIALIZE rm_par.* TO NULL
LET int_flag = 0
CLEAR FORM
CALL mostrar_botones()
IF estado IS NULL THEN
	CONSTRUCT BY NAME expr_sql ON n48_estado, n48_mes_proceso, 
				      n48_ano_proceso 
	IF int_flag THEN
		IF vm_row_current > 0 THEN
			CALL mostrar_registro(vm_row_current)
		ELSE
			CLEAR FORM
			INITIALIZE rm_par.* TO NULL
			CALL mostrar_botones()
		END IF
		RETURN
	END IF
ELSE
	LET expr_sql = ' n48_estado = "', estado, '" '
END IF
LET query = 'SELECT n48_mes_proceso, n48_ano_proceso ' || 
	    '	FROM rolt048 WHERE ' || expr_sql || 
            ' GROUP BY 1, 2 ORDER BY 2 DESC, 1 DESC'
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1 
FOREACH q_cons INTO vm_r_rows[vm_num_rows].*
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
	CALL mostrar_registro(vm_row_current)
	CALL muestra_detalle()
	CALL muestra_contadores(vm_row_current, vm_num_rows)
END IF

END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE num_registro	INTEGER
DEFINE n_mes		CHAR(12)

DEFINE r_n36		RECORD LIKE rolt036.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF

INITIALIZE rm_par.* TO NULL
SELECT UNIQUE n48_estado, n48_mes_proceso, n48_ano_proceso 
	INTO rm_par.* FROM rolt048 
	WHERE n48_compania    = vg_codcia
	  AND n48_ano_proceso = vm_r_rows[num_registro].n48_ano_proceso	
	  AND n48_mes_proceso = vm_r_rows[num_registro].n48_mes_proceso	
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro con índice: ' || vm_row_current,'exclamation')
	RETURN
END IF
	
CASE rm_par.n48_estado  
	WHEN 'A' 
		DISPLAY 'ACTIVO' TO tit_estado
	WHEN 'P' 
	 	DISPLAY 'PROCESADO' TO tit_estado
END CASE
DISPLAY BY NAME	rm_par.*
LET n_mes = fl_justifica_titulo('I', 
		fl_retorna_nombre_mes(rm_par.n48_mes_proceso), 12)
DISPLAY BY NAME n_mes
CALL muestra_detalle()

END FUNCTION



FUNCTION muestra_detalle()
DEFINE tot_valor	LIKE rolt036.n36_ganado_per
DEFINE tot_decimo	LIKE rolt036.n36_valor_bruto
DEFINE tot_desctos	LIKE rolt036.n36_descuentos
DEFINE tot_neto 	LIKE rolt036.n36_valor_neto
DEFINE num_row		SMALLINT

CALL carga_trabajadores()
LET int_flag = 0
CALL set_count(vm_numelm)
DISPLAY ARRAY rm_pat TO rm_pat.*
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT DISPLAY
	ON KEY(F5)
		LET num_row = arr_curr()
		CALL control_contabilizacion(num_row)
		LET int_flag = 0
	ON KEY(F6)
		LET num_row = arr_curr()
		CALL control_forma_pago(num_row)
		LET int_flag = 0
	BEFORE DISPLAY
		CALL dialog.keysetlabel('ACCEPT', '')   
		CALL dialog.keysetlabel("F5","Contabilización") 
		CALL dialog.keysetlabel("F6","Forma de Pago") 
                LET vm_filas_pant = fgl_scr_size('rm_pat')
		CALL calcula_totales() RETURNING tot_valor
		DISPLAY BY NAME tot_valor
		LET int_flag = 0
		EXIT DISPLAY
	BEFORE ROW
		LET num_row = arr_curr()
		CALL mostrar_contadores_det(num_row, vm_numelm)
		DISPLAY BY NAME rm_adi[num_row].*
	AFTER DISPLAY
		CONTINUE DISPLAY
END DISPLAY
CALL mostrar_contadores_det(0, vm_numelm)
CALL mostrar_salir_det()
	
END FUNCTION



FUNCTION control_detalle()
DEFINE tot_valor	LIKE rolt036.n36_ganado_per
DEFINE tot_decimo	LIKE rolt036.n36_valor_bruto
DEFINE tot_desctos	LIKE rolt036.n36_descuentos
DEFINE tot_neto 	LIKE rolt036.n36_valor_neto
DEFINE num_row, j	SMALLINT

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

LET int_flag = 0
CALL set_count(vm_numelm)
DISPLAY ARRAY rm_pat TO rm_pat.*
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT DISPLAY
	ON KEY(F5)
		LET num_row = arr_curr()
		CALL control_contabilizacion(num_row)
		LET int_flag = 0
	ON KEY(F6)
		LET num_row = arr_curr()
		CALL control_forma_pago(num_row)
		LET int_flag = 0
	BEFORE DISPLAY
		CALL dialog.keysetlabel('ACCEPT', '')   
		CALL dialog.keysetlabel("F5","Contabilización") 
		CALL dialog.keysetlabel("F6","Forma de Pago") 
		CALL calcula_totales() RETURNING tot_valor
		DISPLAY BY NAME tot_valor
	BEFORE ROW
		LET num_row = arr_curr()
		LET j = scr_line()
		CALL mostrar_contadores_det(num_row, vm_numelm)
		DISPLAY BY NAME rm_adi[num_row].*
	AFTER DISPLAY
		CONTINUE DISPLAY
END DISPLAY
CALL mostrar_contadores_det(0, vm_numelm)
CALL mostrar_salir_det()

END FUNCTION



FUNCTION carga_trabajadores()

DECLARE q_trab CURSOR FOR 
	SELECT n48_cod_trab, n30_num_doc_id, n30_nombres, n30_fec_jub,
		n48_val_jub_pat, n48_tipo_comp, n48_num_comp
        	FROM rolt048, rolt030   
           	WHERE n48_compania    = vg_codcia
		  AND n48_ano_proceso = rm_par.n48_ano_proceso
		  AND n48_mes_proceso = rm_par.n48_mes_proceso
		  AND n48_compania    = n30_compania
		  AND n48_cod_trab    = n30_cod_trab
            	ORDER BY n30_nombres 
LET vm_numelm = 1
FOREACH q_trab INTO rm_pat[vm_numelm].*, rm_adi[vm_numelm].*
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
DEFINE tot_valor   	DECIMAL(14,2)
                                                                                
LET tot_valor = 0

FOR i = 1 TO vm_numelm
	LET tot_valor = tot_valor + rm_pat[i].n48_val_jub_pat
END FOR
RETURN tot_valor
                                                                                
END FUNCTION



FUNCTION muestra_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL mostrar_registro(vm_row_current)
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION muestra_anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL mostrar_registro(vm_row_current)
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current	SMALLINT
DEFINE num_rows		SMALLINT
                                                                                
DISPLAY "" AT 1,1
DISPLAY row_current, " de ", num_rows AT 1, 69
                                                                                
END FUNCTION



FUNCTION mostrar_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION mostrar_salir_det()
DEFINE i, lim		SMALLINT

FOR i = 1 TO vm_filas_pant
	CLEAR rm_pat[i].*
END FOR
LET lim = vm_numelm
IF lim > vm_filas_pant THEN
	LET lim = vm_filas_pant
END IF
FOR i = 1 TO lim
	DISPLAY rm_pat[i].* TO rm_pat[i].*
END FOR
CLEAR n48_tipo_comp, n48_num_comp

END FUNCTION



FUNCTION control_imprimir()
DEFINE comando 		VARCHAR(255)

LET comando = 'fglrun rolp419 ', vg_base, ' ', vg_modulo,
              ' ', vg_codcia, ' ', rm_par.n48_ano_proceso, ' ',
		rm_par.n48_mes_proceso
RUN comando
                     
END FUNCTION



FUNCTION control_recibos()
DEFINE comando 		VARCHAR(255)

LET comando = 'fglrun rolp404 ', vg_base, ' ', vg_modulo,
              ' ', vg_codcia, ' ', rm_par.n48_ano_proceso, ' ',
		rm_par.n48_mes_proceso
RUN comando
                     
END FUNCTION



FUNCTION control_cerrar_reabrir(estado)
DEFINE estado		LIKE rolt048.n48_estado
DEFINE r_n36		RECORD LIKE rolt036.*
DEFINE resp		VARCHAR(6)
DEFINE mensaje		VARCHAR(100)
DEFINE fecha, fecha2	DATE

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL mostrar_registro(vm_row_current)
IF estado = 'A' THEN
	SQL
		SELECT NVL(MAX(MDY(n48_mes_proceso, 01, n48_ano_proceso)),TODAY)
			INTO $fecha
			FROM rolt048 
        		WHERE n48_compania = $vg_codcia
	END SQL
	LET fecha2 = MDY(vm_r_rows[vm_row_current].n48_mes_proceso, 01,
			vm_r_rows[vm_row_current].n48_ano_proceso)
	IF fecha2 < fecha THEN
		CALL fl_mostrar_mensaje('Este rol ya ha sido procesado y no puede ser reabierto.', 'exclamation')
		RETURN
	END IF
END IF
CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
IF resp = 'No' THEN
        LET int_flag = 0
        RETURN
END IF
BEGIN WORK
WHENEVER ERROR STOP
UPDATE rolt048
	SET n48_estado = estado
        WHERE n48_compania    = vg_codcia
	  AND n48_mes_proceso = vm_r_rows[vm_row_current].n48_mes_proceso
	  AND n48_ano_proceso = vm_r_rows[vm_row_current].n48_ano_proceso
COMMIT WORK
CALL mostrar_registro(vm_row_current)	
CALL muestra_contadores(vm_row_current, vm_num_rows)
LET mensaje = 'El rol ha sido '
CASE estado
	WHEN 'A' LET mensaje = mensaje CLIPPED, ' ACTIVADO.'
	WHEN 'P' LET mensaje = mensaje CLIPPED, ' CERRADO.'
END CASE
CALL fl_mostrar_mensaje(mensaje, 'info')

END FUNCTION



FUNCTION retorna_fin_mes(fecha)
DEFINE fecha		DATE
DEFINE mes, anio	SMALLINT

LET mes  = MONTH(fecha) + 1
LET anio = YEAR(fecha)
IF mes > 12 THEN
	LET mes  = 1
	LET anio = anio + 1
END IF
LET fecha = MDY(mes, 01, anio) - 1 UNITS DAY
RETURN fecha

END FUNCTION



FUNCTION control_forma_pago(num_registro)
DEFINE num_registro	INTEGER
DEFINE lin_men		SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE resul	 	SMALLINT
DEFINE escape	 	INTEGER
DEFINE resp		CHAR(6)
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_g09		RECORD LIKE gent009.*
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n48		RECORD LIKE rolt048.*
DEFINE r_n56		RECORD LIKE rolt056.*
DEFINE r_n59		RECORD LIKE rolt059.*
DEFINE tipo_pago	LIKE rolt048.n48_tipo_pago

LET lin_men  = 0
LET num_rows = 10
LET num_cols = 71
IF vg_gui = 0 THEN
	LET lin_men  = 1
	LET num_rows = 11
	LET num_cols = 72
END IF
OPEN WINDOW w_rolf208_2 AT 10, 05 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_men, BORDER,
		  MESSAGE LINE LAST)
IF vg_gui = 1 THEN
	OPEN FORM f_rolf208_2 FROM '../forms/rolf208_2'
ELSE
	OPEN FORM f_rolf208_2 FROM '../forms/rolf208_2c'
END IF
DISPLAY FORM f_rolf208_2
CALL fl_lee_banco_general(rm_n48.n48_bco_empresa) RETURNING r_g08.*
DISPLAY BY NAME r_g08.g08_nombre
CALL lee_reg_jub(num_registro) RETURNING rm_n48.*
IF rm_par.n48_estado = 'P' OR rm_n48.n48_tipo_comp IS NOT NULL THEN
	WHILE TRUE
		DISPLAY BY NAME rm_n48.n48_tipo_pago, rm_n48.n48_bco_empresa,
				rm_n48.n48_cta_empresa, rm_n48.n48_cta_trabaj
		MESSAGE 'Presione ESC para SALIR ...'
		LET escape = fgl_getkey()
		IF escape <> 0 AND escape <> 27 THEN
			CONTINUE WHILE
		END IF
		EXIT WHILE
	END WHILE
	CLOSE WINDOW w_rolf208_2
	RETURN
END IF
CALL fl_lee_trabajador_roles(vg_codcia, rm_n48.n48_cod_trab) RETURNING r_n30.*
IF (r_n30.n30_tipo_pago  <> 'E' AND r_n30.n30_bco_empresa  IS NOT NULL) AND
   (rm_n48.n48_tipo_pago <> 'E' AND rm_n48.n48_bco_empresa IS NULL)
THEN
	LET rm_n48.n48_tipo_pago   = r_n30.n30_tipo_pago
	LET rm_n48.n48_bco_empresa = r_n30.n30_bco_empresa
	LET rm_n48.n48_cta_empresa = r_n30.n30_cta_empresa
	IF rm_n48.n48_tipo_pago = 'T' THEN
		LET rm_n48.n48_cta_trabaj  = r_n30.n30_cta_trabaj
	END IF
	CALL fl_lee_banco_general(rm_n48.n48_bco_empresa) RETURNING r_g08.*
	DISPLAY BY NAME r_g08.g08_nombre
END IF
LET r_n48.* = rm_n48.*
LET int_flag = 0
INPUT BY NAME rm_n48.n48_tipo_pago, rm_n48.n48_bco_empresa,
	rm_n48.n48_cta_empresa, rm_n48.n48_cta_trabaj
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_n48.n48_tipo_pago, rm_n48.n48_bco_empresa,
				 rm_n48.n48_cta_empresa, rm_n48.n48_cta_trabaj)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET rm_n48.n48_tipo_pago  = r_n48.n48_tipo_pago
				LET rm_n48.n48_bco_empresa=r_n48.n48_bco_empresa
				LET rm_n48.n48_cta_empresa=r_n48.n48_cta_empresa
				LET rm_n48.n48_cta_trabaj =r_n48.n48_cta_trabaj
				LET int_flag = 1
				EXIT INPUT
			END IF
		ELSE
			EXIT INPUT
		END IF
	ON KEY(F2)
		IF INFIELD(n48_bco_empresa) THEN
                        CALL fl_ayuda_cuenta_banco(vg_codcia, 'A')
                                RETURNING r_g08.g08_banco, r_g08.g08_nombre,
					r_g09.g09_tipo_cta, r_g09.g09_numero_cta
                        IF r_g08.g08_banco IS NOT NULL THEN
				LET rm_n48.n48_bco_empresa = r_g08.g08_banco
				LET rm_n48.n48_cta_empresa =r_g09.g09_numero_cta
                                DISPLAY BY NAME rm_n48.n48_bco_empresa,
						r_g08.g08_nombre,
						rm_n48.n48_cta_empresa
                        END IF
                END IF
		IF INFIELD(n48_cta_trabaj) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_n48.n48_cta_trabaj = r_b10.b10_cuenta
				DISPLAY BY NAME rm_n48.n48_cta_trabaj
			END IF
		END IF
		LET int_flag = 0
	AFTER FIELD n48_tipo_pago
		IF rm_n48.n48_tipo_pago <> 'T' THEN
			LET rm_n48.n48_cta_trabaj = NULL
			DISPLAY BY NAME rm_n48.n48_cta_trabaj
			CONTINUE INPUT
		END IF
	AFTER FIELD n48_bco_empresa
                IF rm_n48.n48_bco_empresa IS NOT NULL THEN
                        CALL fl_lee_banco_general(rm_n48.n48_bco_empresa)
                                RETURNING r_g08.*
			IF r_g08.g08_banco IS NULL THEN
				CALL fl_mostrar_mensaje('Banco no existe.','exclamation')
				NEXT FIELD n48_bco_empresa
			END IF
			DISPLAY BY NAME r_g08.g08_nombre
		ELSE
			CLEAR n48_bco_empresa, g08_nombre, n48_cta_empresa
                END IF
	AFTER FIELD n48_cta_empresa
                IF rm_n48.n48_cta_empresa IS NOT NULL THEN
                        CALL fl_lee_banco_compania(vg_codcia,
							rm_n48.n48_bco_empresa,
							rm_n48.n48_cta_empresa)
                                RETURNING r_g09.*
			IF r_g09.g09_banco IS NULL THEN
				CALL fl_mostrar_mensaje('Banco o Cuenta Corriente no existe en la compañía.','exclamation')
				NEXT FIELD n48_bco_empresa
			END IF
			LET rm_n48.n48_cta_empresa = r_g09.g09_numero_cta
			DISPLAY BY NAME rm_n48.n48_cta_empresa
                        CALL fl_lee_banco_general(rm_n48.n48_bco_empresa)
                                RETURNING r_g08.*
			DISPLAY BY NAME r_g08.g08_nombre
			IF r_g09.g09_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD n48_bco_empresa
			END IF
			CALL fl_lee_cuenta(r_g09.g09_compania,
						r_g09.g09_aux_cont)
				RETURNING r_b10.*
			IF r_b10.b10_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No se puede escoger una cuenta corriente que no tiene auxiliar contable.', 'exclamation')
				NEXT FIELD n48_bco_empresa
			END IF
			IF r_b10.b10_estado <> 'A' THEN
				CALL fl_mostrar_mensaje('El auxiliar contable de esta cuenta bancaria esta con estado bloqueado.', 'exclamation')
				NEXT FIELD n48_bco_empresa
			END IF
		ELSE
			CLEAR n48_cta_empresa
		END IF
	AFTER FIELD n48_cta_trabaj
		IF rm_n48.n48_tipo_pago <> 'T' THEN
			LET rm_n48.n48_cta_trabaj = NULL
			DISPLAY BY NAME rm_n48.n48_cta_trabaj
			CONTINUE INPUT
		END IF
		IF rm_n48.n48_cta_trabaj IS NOT NULL THEN
			IF NOT validar_cuenta(rm_n48.n48_cta_trabaj) THEN
				NEXT FIELD n48_cta_trabaj
			END IF
		ELSE
			CLEAR n48_cta_trabaj
		END IF
	AFTER INPUT
		IF rm_n48.n48_tipo_pago <> 'E' THEN
			IF rm_n48.n48_bco_empresa IS NULL OR
			   rm_n48.n48_cta_empresa IS NULL
			THEN
				CALL fl_mostrar_mensaje('Empleado con tipo de pago Cheque o Transferencia, debe ingresar el Banco y la Cuenta Corriente.', 'exclamation')
				NEXT FIELD n48_bco_empresa
			END IF
		ELSE
			IF rm_n48.n48_bco_empresa IS NULL OR
			   rm_n48.n48_cta_empresa IS NULL
			THEN
				INITIALIZE rm_n48.n48_bco_empresa,
					rm_n48.n48_cta_empresa TO NULL
				CLEAR n48_bco_empresa, n48_cta_empresa,
					g08_nombre
			END IF
		END IF
		IF rm_n48.n48_cta_trabaj IS NULL THEN
			IF rm_n48.n48_tipo_pago = 'T' THEN
				CALL fl_mostrar_mensaje('Empleado con tipo de Pago Transferencia, debe ingresar el Número de Cuenta Contable.', 'exclamation')
				NEXT FIELD n48_cta_trabaj
			END IF
		END IF
		IF rm_n48.n48_tipo_pago = 'T' THEN
			IF rm_n48.n48_cta_trabaj IS NOT NULL THEN
				IF NOT validar_cuenta(rm_n48.n48_cta_trabaj)
				THEN
					NEXT FIELD n48_cta_trabaj
				END IF
			END IF
		END IF
END INPUT
IF NOT int_flag THEN
	UPDATE rolt048
		SET n48_tipo_pago   = rm_n48.n48_tipo_pago,
		    n48_bco_empresa = rm_n48.n48_bco_empresa,
		    n48_cta_empresa = rm_n48.n48_cta_empresa,
		    n48_cta_trabaj  = rm_n48.n48_cta_trabaj
	WHERE n48_compania    = vg_codcia
	  AND n48_ano_proceso = rm_n48.n48_ano_proceso
	  AND n48_mes_proceso = rm_n48.n48_mes_proceso
	  AND n48_cod_trab    = rm_n48.n48_cod_trab
END IF
CLOSE WINDOW w_rolf208_2

END FUNCTION



FUNCTION validar_cuenta(aux_cont)
DEFINE aux_cont		LIKE ctbt010.b10_cuenta
DEFINE r_cta            RECORD LIKE ctbt010.*

CALL fl_lee_cuenta(vg_codcia, aux_cont) RETURNING r_cta.*
IF r_cta.b10_cuenta IS NULL THEN
	CALL fl_mostrar_mensaje('Cuenta no existe para esta compañía.','exclamation')
	RETURN 0
END IF
IF r_cta.b10_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN 0
END IF
IF r_cta.b10_permite_mov = 'N' THEN
	CALL fl_mostrar_mensaje('Cuenta no permite movimiento.', 'exclamation')
	RETURN 0
END IF
RETURN 1

END FUNCTION




FUNCTION control_contabilizacion(num_registro)
DEFINE num_registro	INTEGER
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE r_n59		RECORD LIKE rolt059.*
DEFINE tipo_pago	LIKE rolt048.n48_tipo_pago
DEFINE resp		CHAR(6)

CALL lee_reg_jub(num_registro) RETURNING rm_n48.*
IF rm_n48.n48_tipo_comp IS NOT NULL THEN
	CALL ver_contabilizacion(rm_n48.n48_tipo_comp, rm_n48.n48_num_comp)
	RETURN
END IF
IF rm_par.n48_estado = 'P' AND rm_n48.n48_tipo_comp IS NULL THEN
	CALL fl_mostrar_mensaje('Ya no se puede contabilizar este registro.', 'exclamation')
	RETURN
END IF
CALL control_forma_pago(num_registro)
IF int_flag THEN
	RETURN
END IF
BEGIN WORK
	WHENEVER ERROR CONTINUE
	DECLARE q_cont CURSOR FOR
		SELECT * FROM rolt048
			WHERE n48_compania    = vg_codcia
			  AND n48_ano_proceso =
				vm_r_rows[vm_row_current].n48_ano_proceso	
			  AND n48_mes_proceso =
				vm_r_rows[vm_row_current].n48_mes_proceso	
			  AND n48_cod_trab    =
				rm_pat[num_registro].n48_cod_trab
		FOR UPDATE
	OPEN q_cont
	FETCH q_cont INTO rm_n48.*
	IF STATUS = NOTFOUND THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('Este registro no existe. Ha ocurrido un error interno de la base de datos.', 'exclamation')
		WHENEVER ERROR STOP
		RETURN
	END IF
	IF STATUS < 0 THEN
		ROLLBACK WORK
		CALL fl_mensaje_bloqueo_otro_usuario()
		WHENEVER ERROR STOP
		RETURN
	END IF
	UPDATE rolt048
		SET n48_tipo_pago   = rm_n48.n48_tipo_pago,
		    n48_bco_empresa = rm_n48.n48_bco_empresa,
		    n48_cta_empresa = rm_n48.n48_cta_empresa,
		    n48_cta_trabaj  = rm_n48.n48_cta_trabaj
		WHERE CURRENT OF q_cont
	IF STATUS < 0 THEN
		ROLLBACK WORK
		WHENEVER ERROR STOP
		CALL fl_mostrar_mensaje('Ha ocurrido un error interno de la base de datos al intentar actualizar el registro. Consulte con el Administrador.', 'exclamation')
		RETURN
	END IF
	WHENEVER ERROR STOP
	CALL generar_contabilizacion() RETURNING r_b12.*
	IF r_b12.b12_compania IS NULL THEN
		WHENEVER ERROR STOP
		ROLLBACK WORK
		RETURN
	END IF
COMMIT WORK
IF r_b12.b12_compania IS NOT NULL AND rm_b00.b00_mayo_online = 'S' THEN
	CALL fl_mayoriza_comprobante(r_b12.b12_compania, r_b12.b12_tipo_comp,
					r_b12.b12_num_comp, 'M')
END IF
CALL fl_hacer_pregunta('Desea ver contabilización generada ?', 'Yes')
	RETURNING resp
IF resp = 'Yes' THEN
	CALL ver_contabilizacion(r_b12.b12_tipo_comp, r_b12.b12_num_comp)
END IF
CALL lee_reg_jub(num_registro) RETURNING rm_n48.*
CALL fl_mostrar_mensaje('Contabilización del Anticipo Generada Ok.', 'info')

END FUNCTION



FUNCTION generar_contabilizacion()
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_g14		RECORD LIKE gent014.*
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n48		RECORD LIKE rolt048.*
DEFINE r_n56		RECORD LIKE rolt056.*
DEFINE r_n59		RECORD LIKE rolt059.*
DEFINE glosa		LIKE ctbt012.b12_glosa
DEFINE num_che		LIKE ctbt012.b12_num_cheque
DEFINE sec		LIKE ctbt013.b13_secuencia
DEFINE valor_cuad	DECIMAL(14,2)

INITIALIZE r_b12.*, r_n56.*, r_n59.* TO NULL
CALL fl_lee_trabajador_roles(vg_codcia, rm_n48.n48_cod_trab) RETURNING r_n30.*
SELECT * INTO r_n56.*
	FROM rolt056
	WHERE n56_compania  = vg_codcia
	  AND n56_proceso   = vm_proceso
	  AND n56_cod_depto = r_n30.n30_cod_depto
	  AND n56_cod_trab  = rm_n48.n48_cod_trab
	  AND n56_estado    = "A"
IF r_n56.n56_compania IS NULL THEN
	CALL fl_lee_proceso_roles(vm_proceso) RETURNING r_n03.*
	CALL fl_mostrar_mensaje('No existen auxiliares contable para este trabajador en el proceso de ' || r_n03.n03_nombre CLIPPED || '.', 'stop')
	RETURN r_b12.*
END IF
IF NOT validacion_contable(TODAY) THEN
	RETURN r_b12.*
END IF
LET r_b12.b12_compania 	  = vg_codcia
LET r_b12.b12_tipo_comp   = "DC"
IF rm_n48.n48_tipo_pago = 'C' THEN
	LET r_b12.b12_tipo_comp = "EG"
END IF
LET r_b12.b12_num_comp    = fl_numera_comprobante_contable(vg_codcia,
				r_b12.b12_tipo_comp, YEAR(TODAY), MONTH(TODAY)) 
IF r_b12.b12_num_comp <= 0 THEN
	INITIALIZE r_b12.* TO NULL
	RETURN r_b12.*
END IF
LET r_b12.b12_estado 	  = 'A'
LET r_b12.b12_glosa       = r_n30.n30_nombres[1, 25] CLIPPED,
				', PAGO DE JUBILACION ',
				DATE(rm_n48.n48_fecing) USING "dd-mm-yyyy"
IF rm_n48.n48_tipo_pago = 'C' THEN
	LET r_b12.b12_benef_che = r_n30.n30_nombres CLIPPED
	CALL lee_cheque(r_b12.*) RETURNING num_che, glosa
	IF int_flag THEN
		CALL fl_mostrar_mensaje('Debe generar el cheque, de lo contrario no se podra liquidar este anticipo.', 'stop')
		INITIALIZE r_b12.* TO NULL
		RETURN r_b12.*
	END IF
	LET r_b12.b12_num_cheque = num_che
	LET r_b12.b12_glosa      = glosa CLIPPED
END IF
LET r_b12.b12_glosa  = r_b12.b12_glosa CLIPPED, ' JUB. ',
			rm_n48.n48_ano_proceso USING "&&&&", '-',
			rm_n48.n48_mes_proceso USING "&&"
LET r_b12.b12_origen = 'A'
CALL fl_lee_moneda(r_n30.n30_mon_sueldo) RETURNING r_g13.*
IF r_g13.g13_moneda  = rg_gen.g00_moneda_base THEN
	LET r_g14.g14_tasa = 1
ELSE
	CALL fl_lee_factor_moneda(r_g13.g13_moneda, rg_gen.g00_moneda_base)
		RETURNING r_g14.*
	IF r_g14.g14_serial IS NULL THEN
		CALL fl_mostrar_mensaje('La paridad para esta moneda no existe.', 'stop')
		INITIALIZE r_b12.* TO NULL
		RETURN r_b12.*
	END IF
END IF
LET r_b12.b12_moneda      = r_g13.g13_moneda
LET r_b12.b12_paridad     = r_g14.g14_tasa
LET r_b12.b12_fec_proceso = TODAY
LET r_b12.b12_modulo      = vg_modulo
LET r_b12.b12_usuario     = vg_usuario
LET r_b12.b12_fecing      = CURRENT
INSERT INTO ctbt012 VALUES (r_b12.*) 
LET sec = 1
IF rm_n48.n48_tipo_pago = 'T' OR rm_n48.n48_tipo_pago = 'R' THEN
	CALL generar_detalle_contable(r_b12.*, rm_n48.n48_cta_trabaj,
				rm_n48.n48_val_jub_pat, 'D', sec, 0, 'S')
ELSE
	CALL generar_detalle_contable(r_b12.*, r_n56.n56_aux_val_vac,
				rm_n48.n48_val_jub_pat, 'D', sec, 0, 'S')
END IF
LET sec = sec + 1
CALL generar_detalle_contable(r_b12.*, r_n56.n56_aux_banco,
				rm_n48.n48_val_jub_pat, 'H', sec, 1, 'S')
SELECT NVL(SUM(b13_valor_base), 0)
	INTO valor_cuad
	FROM ctbt013
	WHERE b13_compania  = vg_codcia
	  AND b13_tipo_comp = r_b12.b12_tipo_comp
	  AND b13_num_comp  = r_b12.b12_num_comp
IF valor_cuad <> 0 THEN
	CALL fl_mostrar_mensaje('Se ha generado un error en la contabilizacion. POR FAVOR LLAME AL ADMINISTRADOR.', 'stop')
	INITIALIZE r_b12.* TO NULL
	RETURN r_b12.*
END IF
UPDATE rolt048
	SET n48_tipo_comp = r_b12.b12_tipo_comp,
	    n48_num_comp  = r_b12.b12_num_comp
	WHERE n48_compania    = vg_codcia
	  AND n48_ano_proceso = rm_n48.n48_ano_proceso
	  AND n48_mes_proceso = rm_n48.n48_mes_proceso
	  AND n48_cod_trab    = rm_n48.n48_cod_trab
RETURN r_b12.*

END FUNCTION



FUNCTION validacion_contable(fecha)
DEFINE fecha		DATE
DEFINE resp 		VARCHAR(6)

IF YEAR(fecha) < YEAR(rm_b00.b00_fecha_cm) OR
  (YEAR(fecha) = YEAR(rm_b00.b00_fecha_cm) AND
   MONTH(fecha) <= MONTH(rm_b00.b00_fecha_cm))
THEN
	CALL fl_mostrar_mensaje('El Mes en Contabilidad esta cerrado. Reapertúrelo para que se pueda generar la contabilización del Anticipo.', 'stop')
	RETURN 0
END IF
IF fecha_bloqueada(vg_codcia, MONTH(fecha), YEAR(fecha)) THEN
	CALL fl_mostrar_mensaje('No puede generar contabilización del Anticipo de un mes bloqueado en CONTABILIDAD.', 'stop')
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION fecha_bloqueada(codcia, mes, ano)
DEFINE codcia 		LIKE ctbt006.b06_compania
DEFINE mes, ano		SMALLINT
DEFINE r_b06		RECORD LIKE ctbt006.*

INITIALIZE r_b06.* TO NULL 
SELECT * INTO r_b06.*
	FROM ctbt006
	WHERE b06_compania = codcia
	  AND b06_ano      = ano
	  AND b06_mes      = mes
IF r_b06.b06_mes IS NOT NULL THEN
	CALL fl_mostrar_mensaje('Mes contable esta bloqueado.','stop')
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION lee_cheque(r_b12)
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE glosa		LIKE ctbt012.b12_glosa

OPEN WINDOW w_rolf208_3 AT 09, 12 WITH FORM "../forms/rolf208_3" 
	ATTRIBUTE(BORDER, COMMENT LINE LAST, FORM LINE FIRST)
LET int_flag = 0
INPUT BY NAME r_b12.b12_num_cheque, r_b12.b12_glosa
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD b12_glosa
		LET glosa = r_b12.b12_glosa
	AFTER FIELD b12_glosa
		IF r_b12.b12_glosa IS NULL THEN
			LET r_b12.b12_glosa = glosa
			DISPLAY BY NAME r_b12.b12_glosa
		END IF
	AFTER FIELD b12_num_cheque
		IF r_b12.b12_num_cheque IS NULL THEN
			NEXT FIELD b12_num_cheque
		END IF
	AFTER INPUT
		IF r_b12.b12_num_cheque IS NULL THEN
			NEXT FIELD b12_num_cheque
		END IF
END INPUT
CLOSE WINDOW w_rolf208_3
RETURN r_b12.b12_num_cheque, r_b12.b12_glosa

END FUNCTION



FUNCTION generar_detalle_contable(r_b12, cuenta, valor, tipo, sec, flag_bco,
					flag)
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE valor		LIKE ctbt013.b13_valor_base
DEFINE tipo		CHAR(1)
DEFINE sec		LIKE ctbt013.b13_secuencia
DEFINE flag_bco		SMALLINT
DEFINE flag		CHAR(1)
DEFINE r_g09		RECORD LIKE gent009.*
DEFINE r_b13		RECORD LIKE ctbt013.*

INITIALIZE r_b13.* TO NULL
LET r_b13.b13_compania    = r_b12.b12_compania
LET r_b13.b13_tipo_comp   = r_b12.b12_tipo_comp
LET r_b13.b13_num_comp    = r_b12.b12_num_comp
LET r_b13.b13_secuencia   = sec
IF flag_bco THEN
	IF rm_n48.n48_tipo_pago <> 'E' THEN
		CALL fl_lee_banco_compania(vg_codcia, rm_n48.n48_bco_empresa,
						rm_n48.n48_cta_empresa)
			RETURNING r_g09.*
		IF flag = 'S' THEN
			LET cuenta = r_g09.g09_aux_cont
		END IF
	END IF
	CASE rm_n48.n48_tipo_pago
		WHEN 'C' IF flag = 'S' THEN
				LET r_b13.b13_tipo_doc = 'CHE'
			 END IF
		WHEN 'T' --LET r_b13.b13_tipo_doc = 'DEP'
	END CASE
END IF
LET r_b13.b13_cuenta      = cuenta
LET r_b13.b13_glosa       = 'LIQ.PAG.JUB. ',
				rm_n48.n48_cod_trab USING "<<<&&", ' AN-',
				rm_n48.n48_val_jub_pat USING "<<<&&",
				' ', DATE(rm_n48.n48_fecing) USING "dd-mm-yyyy"
LET r_b13.b13_valor_base  = 0
LET r_b13.b13_valor_aux   = 0
CASE tipo
	WHEN 'D'
		LET r_b13.b13_valor_base = valor
	WHEN 'H'
		LET r_b13.b13_valor_base = valor * (-1)
END CASE
LET r_b13.b13_fec_proceso = r_b12.b12_fec_proceso
INSERT INTO ctbt013 VALUES (r_b13.*)

END FUNCTION



FUNCTION lee_reg_jub(num_registro)
DEFINE num_registro	INTEGER

INITIALIZE rm_n48.* TO NULL
SELECT * INTO rm_n48.*
	FROM rolt048 
	WHERE n48_compania    = vg_codcia
	  AND n48_ano_proceso = vm_r_rows[vm_row_current].n48_ano_proceso	
	  AND n48_mes_proceso = vm_r_rows[vm_row_current].n48_mes_proceso	
	  AND n48_cod_trab    = rm_pat[num_registro].n48_cod_trab
RETURN rm_n48.*

END FUNCTION



FUNCTION lee_reg_jub2(anio, mes, cod_trab)
DEFINE anio		LIKE rolt048.n48_ano_proceso
DEFINE mes		LIKE rolt048.n48_mes_proceso
DEFINE cod_trab		LIKE rolt048.n48_cod_trab
DEFINE r_n48		RECORD LIKE rolt048.*

INITIALIZE r_n48.* TO NULL
SELECT * INTO r_n48.*
	FROM rolt048 
	WHERE n48_compania    = vg_codcia
	  AND n48_ano_proceso = anio
	  AND n48_mes_proceso = mes
	  AND n48_cod_trab    = cod_trab
RETURN r_n48.*

END FUNCTION



FUNCTION ver_contabilizacion(tipo_comp, num_comp)
DEFINE tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE num_comp		LIKE ctbt012.b12_num_comp
DEFINE param		VARCHAR(60)

LET param = ' "', tipo_comp, '" "', num_comp, '"'
CALL fl_ejecuta_comando('CONTABILIDAD', 'CB', 'ctbp201 ', param, 0)

END FUNCTION
