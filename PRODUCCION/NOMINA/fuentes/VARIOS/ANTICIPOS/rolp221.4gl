------------------------------------------------------------------------------
-- Titulo           : rolp221.4gl - Mantenimiento novedades decimo cuarto  
-- Elaboracion      : 01-sep-2003
-- Autor            : JCM
-- Formato Ejecucion: fglrun rolp221 base modulo compania [fecha_ini] 
--				[fecha_fin] [cod_trab] [opcion {G | C | F}]
-- 			G: Genera o regenera el decimo cuarto para un trab.
-- 			C: Consulta el decimo cuarto generado para un trab.
-- 			F: Cerrar el decimo cuarto generado por finiquito.
-- Ultima Correccion:
-- Motivo Correccion:
-- Observaciones    : Este programa fue creado en base al programa rolp207,
--		      no se han cambiado los nombres de las variables. De modo,
--		      que no siempre los nombres de las variables coincidiran
--		      con su nombre y/o funcion real en la tabla.
--		      rm_scr[].n36_ganado_per  --> valor del decimo
--		      rm_scr[].n36_valor_bruto --> valor de los anticipos
--		      rm_scr[].n36_descuentos  --> valor de otros descuentos
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_num_rows	INTEGER
DEFINE vm_row_current	INTEGER
DEFINE vm_max_rows	INTEGER
DEFINE vm_r_rows 	ARRAY [200] OF RECORD
	n36_fecha_ini		LIKE rolt036.n36_fecha_ini,
	n36_fecha_fin		LIKE rolt036.n36_fecha_fin
END RECORD

DEFINE rm_n00		RECORD LIKE rolt000.*  
DEFINE rm_loc		RECORD LIKE gent002.*
DEFINE rm_n05		RECORD LIKE rolt005.*  
DEFINE rm_par RECORD 
	n36_ano_proceso		LIKE rolt036.n36_ano_proceso, 
	n36_estado		LIKE rolt036.n36_estado,
	n_estado		VARCHAR(20),
	n36_fecha_ini		LIKE rolt036.n36_fecha_ini,
	n36_fecha_fin		LIKE rolt036.n36_fecha_fin
END RECORD

DEFINE vm_proceso       LIKE rolt036.n36_proceso
DEFINE vm_opcion	CHAR(1)

DEFINE vm_filas_pant 	INTEGER
DEFINE vm_numelm 	INTEGER
DEFINE vm_maxelm 	INTEGER
DEFINE rm_scr ARRAY[1000] OF RECORD
	n_trab			LIKE rolt030.n30_nombres,
	n36_ganado_per		LIKE rolt036.n36_ganado_per,
	n36_valor_bruto		LIKE rolt036.n36_valor_bruto,
	n36_descuentos		LIKE rolt036.n36_descuentos,
	n36_valor_neto		LIKE rolt036.n36_valor_neto
END RECORD
DEFINE vm_cod_trab ARRAY[1000] OF RECORD
	n36_cod_trab		LIKE rolt036.n36_cod_trab,
	n30_mon_sueldo		LIKE rolt030.n30_mon_sueldo,
	n36_cod_depto		LIKE rolt036.n36_cod_depto,
	n36_tipo_pago		LIKE rolt036.n36_tipo_pago,
	n36_bco_empresa		LIKE rolt036.n36_bco_empresa,
	n36_cta_empresa		LIKE rolt036.n36_cta_empresa,
	n36_cta_trabaj		LIKE rolt036.n36_cta_trabaj
END RECORD

DEFINE vm_numdesc		INTEGER
DEFINE vm_maxdesc		INTEGER
DEFINE rm_desc ARRAY[100] OF RECORD 
	n37_cod_rubro		LIKE rolt037.n37_cod_rubro,
	n_rubro			LIKE rolt006.n06_nombre,
	n37_num_prest		LIKE rolt037.n37_num_prest,
	n37_valor		LIKE rolt037.n37_valor
END RECORD


MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp221.err')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 7 THEN   -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)

LET vg_proceso  = 'rolp221'
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

DEFINE salir 		INTEGER
DEFINE resp 		VARCHAR(6)

CALL fl_nivel_isolation()
CREATE TEMP TABLE tmp_descuentos (
	n37_cod_trab		INTEGER,
	n37_cod_rubro		INTEGER,
	n_rubro			VARCHAR(30, 15),
	n37_num_prest		INTEGER,
	n37_valor		DECIMAL(12, 2)
);

CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rm_loc.*
IF rm_loc.g02_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe localidad.','stop')
	EXIT PROGRAM
END IF
-- AQUI SE DEFINEN VALORES DE VARIABLES GLOBALES
LET vm_max_rows = 1000
LET vm_maxelm   = 1000
LET vm_maxdesc  = 100
LET vm_proceso  = 'DC'

INITIALIZE vm_opcion TO NULL
IF num_args() = 7 THEN
	IF arg_val(7) <> 'G' AND arg_val(7) <> 'C' AND arg_val(7) <> 'F' AND
	   arg_val(7) <> 'X'
	THEN
		CALL fl_mostrar_mensaje('Parametros incorrecto.', 'stop')
		EXIT PROGRAM
	END IF
	INITIALIZE rm_par.* TO NULL
	LET rm_par.n36_fecha_ini = arg_val(4)	
	LET rm_par.n36_fecha_fin = arg_val(5)
	IF arg_val(7) = 'X' THEN
		LET vm_proceso           = arg_val(4)
		LET rm_par.n36_fecha_ini = arg_val(5)	
		LET rm_par.n36_fecha_fin = arg_val(6)
	END IF
	LET rm_par.n36_ano_proceso = YEAR(rm_par.n36_fecha_fin)	

	DECLARE q_est CURSOR FOR
		SELECT n36_estado FROM rolt036
			WHERE n36_compania  = vg_codcia          
			  AND n36_proceso   = vm_proceso         
			  AND n36_fecha_ini = rm_par.n36_fecha_ini
			  AND n36_fecha_fin = rm_par.n36_fecha_fin
      	OPEN  q_est
	FETCH q_est INTO rm_par.n36_estado
	CLOSE q_est
	FREE  q_est

	IF rm_par.n36_estado IS NULL THEN
		CALL fl_mostrar_mensaje('Liquidación no existe.', 'stop')
		EXIT PROGRAM
	END IF

	CASE rm_par.n36_estado  
		WHEN 'A' 
			LET rm_par.n_estado = 'ACTIVO'
		WHEN 'P' 
			LET rm_par.n_estado = 'PROCESADO'
		WHEN 'F' 
			LET rm_par.n_estado = 'FINIQUITO'
	END CASE

	CASE arg_val(7) 
		WHEN 'G'
			CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
			IF resp <> 'Yes' THEN
				EXIT PROGRAM
			END IF

			BEGIN WORK
			CALL regenerar_novedades_empleado(arg_val(6))
			COMMIT WORK
			CALL fl_mostrar_mensaje('Proceso terminado OK', 'info')
			EXIT PROGRAM
		WHEN 'C'
			LET vm_opcion = 'C'
		WHEN 'F'
			LET vm_num_rows = 1
			LET vm_row_current = 1
			LET vm_r_rows[vm_row_current].n36_fecha_ini = 
				rm_par.n36_fecha_ini
			LET vm_r_rows[vm_row_current].n36_fecha_fin = 
				rm_par.n36_fecha_fin
			CALL control_cerrar()
			EXIT PROGRAM
	END CASE
	IF arg_val(7) = 'X' THEN
		LET vm_opcion = 'C'
	END IF
END IF

OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_221 AT 3, 2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST) 
OPEN FORM f_221 FROM '../forms/rolf221_1'
DISPLAY FORM f_221

CALL fl_lee_parametro_general_roles()  RETURNING rm_n00.*
IF rm_n00.n00_serial IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'No existe configuración general para este módulo.',
		'stop')
	EXIT PROGRAM
END IF

MENU 'OPCIONES'
	BEFORE MENU
		CALL mostrar_botones()
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Cerrar'
		HIDE OPTION 'Imprimir'
		HIDE OPTION 'Archivo Banco'
		HIDE OPTION 'Recibo de Pago'
		HIDE OPTION 'Informe Min.'
		HIDE OPTION 'Detalle'
		IF vm_opcion = 'C' THEN
			HIDE OPTION 'Consultar'
			CALL carga_trabajadores()
			IF vm_numelm = 0 THEN
				CALL fl_mostrar_mensaje('Liquidación no existe.', 'stop')
				EXIT PROGRAM
			END IF
			LET vm_num_rows = 1
			LET vm_row_current = 1
			CALL muestra_contadores(vm_row_current, vm_num_rows)
			DISPLAY BY NAME rm_par.*
			CALL set_count(vm_numelm)
			CALL control_detalle()
			EXIT PROGRAM
		END IF
       	COMMAND KEY('M') 'Modificar' 'Modificar registro corriente. '
		CALL control_modificacion()
      	COMMAND KEY('U') 'Cerrar' 'Cierra el rol activo. '
		CALL control_cerrar()
		IF rm_n05.n05_proceso IS NULL THEN
			HIDE OPTION 'Modificar'
			HIDE OPTION 'Cerrar'
		END IF
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Cerrar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Cerrar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
		IF rm_par.n36_estado = 'A' THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Cerrar'
		ELSE
			HIDE OPTION 'Modificar'
			HIDE OPTION 'Cerrar'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
			SHOW OPTION 'Archivo Banco'
			SHOW OPTION 'Recibo de Pago'
			SHOW OPTION 'Informe Min.'
			SHOW OPTION 'Detalle'
		END IF
	COMMAND KEY('D') 'Detalle' 'Consulta el detalle del registro actual. '
		CALL control_detalle()
	COMMAND KEY('I') 'Imprimir' 'Imprime un registro. '
		CALL control_imprimir()
	COMMAND KEY('X') 'Archivo Banco' 'Genera archivo para credito bancario.'
		CALL generar_archivo()
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
		IF rm_par.n36_estado = 'A' THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Cerrar'
		ELSE
			HIDE OPTION 'Modificar'
			HIDE OPTION 'Cerrar'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Detalle'
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
		IF rm_par.n36_estado = 'A' THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Cerrar'
		ELSE
			HIDE OPTION 'Modificar'
			HIDE OPTION 'Cerrar'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Detalle'
		END IF
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION mostrar_botones()

DISPLAY 'Nombre Trabajador' 	TO bt_nom_trab
DISPLAY 'Valor Decimo' 		TO bt_valor
DISPLAY 'Anticipos' 		TO bt_anticipo
DISPLAY 'Descuentos' 		TO bt_desctos
DISPLAY 'Total Neto' 		TO bt_neto

END FUNCTION



FUNCTION control_consulta()
DEFINE query		VARCHAR(400)
DEFINE expr_sql		VARCHAR(400)
DEFINE num_reg		INTEGER
DEFINE foo_anho		INTEGER
DEFINE r_n36		RECORD LIKE rolt036.*

INITIALIZE rm_par.* TO NULL
LET int_flag = 0
CLEAR FORM
CALL mostrar_botones()
CONSTRUCT BY NAME expr_sql ON n36_ano_proceso, n36_estado 
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

LET query = 'SELECT n36_ano_proceso, n36_fecha_ini, n36_fecha_fin ' || 
	    '	FROM rolt036 ' ||
	    '	WHERE n36_compania = ' || vg_codcia ||
	    '     AND n36_proceso  = "' || vm_proceso || '"' ||
            '     AND ' || expr_sql || 
            ' GROUP BY 1, 2, 3 ORDER BY 1 DESC'

PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1 
FOREACH q_cons INTO foo_anho, vm_r_rows[vm_num_rows].*
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
--		LET vm_num_rows = vm_num_rows - 1
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
--	CALL muestra_detalle()
	CALL muestra_contadores(vm_row_current, vm_num_rows)
END IF

END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE num_registro	INTEGER
DEFINE query		VARCHAR(500)

DEFINE r_n36		RECORD LIKE rolt036.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF

INITIALIZE rm_par.* TO NULL
LET query = 'SELECT n36_ano_proceso, n36_estado, " ", n36_fecha_ini, ',
            '	    n36_fecha_fin ',
	    ' FROM rolt036 ', 
	    ' WHERE n36_compania  = ',  vg_codcia,
	    '   AND n36_proceso   = "', vm_proceso, '"',
	    '   AND n36_fecha_ini = "',
			vm_r_rows[num_registro].n36_fecha_ini,	'" ',
	    '   AND n36_fecha_fin = "',
		 	vm_r_rows[num_registro].n36_fecha_fin,	'" '
IF num_args() = 7 AND arg_val(7) = 'F' THEN
	LET query = query, ' AND n36_estado = "F"'
END IF 
LET query = query, ' GROUP BY 1, 2, 3, 4, 5 '

PREPARE cons_cab FROM query
DECLARE q_cons_cab CURSOR FOR cons_cab

OPEN q_cons_cab 
FETCH q_cons_cab INTO rm_par.*

IF STATUS = NOTFOUND THEN
	CALL fgl_winmessage (vg_producto,'No existe registro con índice: ' || vm_row_current,'exclamation')
	RETURN
END IF

CASE rm_par.n36_estado  
	WHEN 'A' 
		LET rm_par.n_estado = 'ACTIVO'
	WHEN 'P' 
		LET rm_par.n_estado = 'PROCESADO'
	WHEN 'F' 
		LET rm_par.n_estado = 'FINIQUITO'
END CASE

DISPLAY BY NAME	rm_par.*

INITIALIZE rm_n05.* TO NULL
SELECT * INTO rm_n05.* FROM rolt005 
	WHERE n05_compania   = vg_codcia 
          AND n05_proceso    = vm_proceso
	  AND n05_activo     = 'S'
          AND n05_fecini_act = rm_par.n36_fecha_ini
	  AND n05_fecfin_act = rm_par.n36_fecha_fin

CALL muestra_detalle()

END FUNCTION



FUNCTION muestra_detalle()
DEFINE tot_valor	LIKE rolt036.n36_ganado_per
DEFINE tot_anticipo	LIKE rolt036.n36_valor_bruto
DEFINE tot_desctos	LIKE rolt036.n36_descuentos
DEFINE tot_neto 	LIKE rolt036.n36_valor_neto
DEFINE num_row, i	SMALLINT

CALL carga_trabajadores()
CALL set_count(vm_numelm)
DISPLAY ARRAY rm_scr TO ra_scr.*
	ON KEY(F5)
		LET i = arr_curr()
		CALL fl_valor_ganado_liquidacion(vg_codcia, vm_proceso,
						vm_cod_trab[i].n36_cod_trab,
						rm_par.n36_fecha_ini,
						rm_par.n36_fecha_fin)
		LET int_flag = 0
	BEFORE DISPLAY
                --#CALL dialog.keysetlabel('F5','Detalle Tot. Gan.')
                LET vm_filas_pant = fgl_scr_size('ra_scr')
		CALL calcula_totales() RETURNING tot_valor,   tot_anticipo,
					         tot_desctos, tot_neto
		DISPLAY BY NAME tot_valor, tot_anticipo, tot_desctos, tot_neto
		EXIT DISPLAY
	BEFORE ROW
		LET num_row = arr_curr()
		CALL muestra_contadores_det(num_row, vm_numelm)
END DISPLAY
CALL muestra_contadores_det(0, vm_numelm)
	
END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row		SMALLINT
DEFINE max_row		SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION control_detalle()
DEFINE tot_valor		LIKE rolt036.n36_ganado_per
DEFINE tot_anticipo		LIKE rolt036.n36_valor_bruto
DEFINE tot_desctos		LIKE rolt036.n36_descuentos
DEFINE tot_neto 		LIKE rolt036.n36_valor_neto
DEFINE cod_trab			LIKE rolt036.n36_cod_trab
DEFINE i			INTEGER
DEFINE num_row			SMALLINT

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
DISPLAY ARRAY rm_scr TO ra_scr.*
	ON KEY(INTERRUPT)
		EXIT DISPLAY
	ON KEY(F5)
		CALL mostrar_descuentos(arr_curr())
		LET int_flag = 0
	ON KEY(F6)
		LET i = arr_curr()
		LET cod_trab = vm_cod_trab[i].n36_cod_trab
		CALL control_imprimir_recibo(cod_trab)
		LET int_flag = 0
	ON KEY(F7)
		LET i = arr_curr()
		CALL fl_valor_ganado_liquidacion(vg_codcia, vm_proceso,
						vm_cod_trab[i].n36_cod_trab,
						rm_par.n36_fecha_ini,
						rm_par.n36_fecha_fin)
		LET int_flag = 0
	BEFORE DISPLAY
		--#CALL dialog.keysetlabel('ACCEPT', '')   
                --#CALL dialog.keysetlabel('F5','Descuentos')
                --#CALL dialog.keysetlabel('F6','Recibo de Pago')
                --#CALL dialog.keysetlabel('F7','Detalle Tot. Gan.')
		CALL calcula_totales() RETURNING tot_valor,   tot_anticipo,
					         tot_desctos, tot_neto
		DISPLAY BY NAME tot_valor, tot_anticipo, tot_desctos, tot_neto
	BEFORE ROW
		LET num_row = arr_curr()
		CALL muestra_contadores_det(num_row, vm_numelm)
	AFTER DISPLAY
		CONTINUE DISPLAY
END DISPLAY
CALL muestra_contadores_det(0, vm_numelm)

END FUNCTION



FUNCTION carga_trabajadores()
DEFINE cod_trab 		LIKE rolt036.n36_cod_trab
DEFINE anticipo 		LIKE rolt036.n36_descuentos

DELETE FROM tmp_descuentos

INSERT INTO tmp_descuentos
	SELECT n37_cod_trab, n37_cod_rubro, n06_nombre, n37_num_prest, 
               n37_valor
	FROM rolt037, rolt006
       	WHERE n37_compania  = vg_codcia
	  AND n37_proceso   = vm_proceso
	  AND n37_fecha_ini = rm_par.n36_fecha_ini
	  AND n37_fecha_fin = rm_par.n36_fecha_fin
	  AND n06_cod_rubro = n37_cod_rubro

DECLARE q_trab CURSOR FOR 
	SELECT n36_cod_trab, n30_mon_sueldo, n36_cod_depto, n36_tipo_pago,  
               n36_bco_empresa, n36_cta_empresa, n36_cta_trabaj, n30_nombres, 
               n36_valor_bruto, n36_valor_bruto, n36_descuentos, n36_valor_neto 
        	FROM rolt030, rolt036   
           	WHERE n36_compania  = vg_codcia
		  AND n36_proceso   = vm_proceso
		  AND n36_fecha_ini = rm_par.n36_fecha_ini
		  AND n36_fecha_fin = rm_par.n36_fecha_fin
		  AND n30_compania  = n36_compania
		  AND n30_cod_trab  = n36_cod_trab
		  AND n30_tipo_trab = 'N'
            	ORDER BY n30_nombres 
                                                                                
IF vm_opcion = 'C' AND arg_val(7) <> 'X' THEN
	LET cod_trab = arg_val(6)
ELSE
	INITIALIZE cod_trab TO NULL
END IF

LET vm_numelm = 1
FOREACH q_trab INTO vm_cod_trab[vm_numelm].*, rm_scr[vm_numelm].*
	IF cod_trab IS NOT NULL AND vm_cod_trab[vm_numelm].n36_cod_trab <> cod_trab THEN
		CONTINUE FOREACH
	END IF
	SELECT NVL(SUM(n37_valor), 0) INTO rm_scr[vm_numelm].n36_valor_bruto
		FROM tmp_descuentos, rolt006
		WHERE n37_cod_trab   = vm_cod_trab[vm_numelm].n36_cod_trab 
		  AND n37_cod_rubro  = n06_cod_rubro
		  AND (n37_num_prest IS NOT NULL OR
		       n06_flag_ident = 'AN')
	LET rm_scr[vm_numelm].n36_descuentos = 
			rm_scr[vm_numelm].n36_descuentos -  
			rm_scr[vm_numelm].n36_valor_bruto
        LET vm_numelm = vm_numelm + 1
        IF vm_numelm > vm_maxelm THEN
                CALL fl_mensaje_arreglo_incompleto()
                EXIT PROGRAM
        END IF
END FOREACH
FREE q_trab

LET vm_numelm = vm_numelm - 1

END FUNCTION



FUNCTION calcula_totales()
DEFINE i                INTEGER
DEFINE valor_per        LIKE rolt036.n36_ganado_per
DEFINE tot_valor_per    LIKE rolt036.n36_ganado_per
DEFINE valor_dec        LIKE rolt036.n36_valor_bruto
DEFINE tot_valor_dec    LIKE rolt036.n36_valor_bruto
DEFINE valor_dscto      LIKE rolt036.n36_descuentos
DEFINE tot_valor_dscto  LIKE rolt036.n36_descuentos
DEFINE valor_neto       LIKE rolt036.n36_valor_neto
DEFINE tot_valor_neto   LIKE rolt036.n36_valor_neto
                                                                                
LET tot_valor_per   = 0
LET tot_valor_dec   = 0
LET tot_valor_dscto = 0
LET tot_valor_neto  = 0

FOR i = 1 TO vm_numelm
	LET valor_per = rm_scr[i].n36_ganado_per
	IF valor_per IS NULL THEN
		LET valor_per = 0
	END IF
        LET tot_valor_per = tot_valor_per + valor_per

	LET valor_dec = rm_scr[i].n36_valor_bruto
	IF valor_dec IS NULL THEN
		LET valor_dec = 0
	END IF
        LET tot_valor_dec = tot_valor_dec + valor_dec

	LET valor_dscto = rm_scr[i].n36_descuentos
	IF valor_dscto IS NULL THEN
		LET valor_dscto = 0
	END IF
        LET tot_valor_dscto = tot_valor_dscto + valor_dscto

	LET valor_neto = rm_scr[i].n36_valor_neto
	IF valor_neto IS NULL THEN
		LET valor_neto = 0
	END IF
        LET tot_valor_neto = tot_valor_neto + valor_neto
END FOR
                                                                               
RETURN tot_valor_per, tot_valor_dec, tot_valor_dscto, tot_valor_neto
                                                                                
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
DISPLAY row_current, " de ", num_rows AT 1, 67
                                                                                
END FUNCTION



FUNCTION control_modificacion()
DEFINE r_n36		RECORD LIKE rolt036.*

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
--CALL mostrar_registro(vm_row_current)

IF rm_par.n36_estado = 'P' THEN
	CALL fl_mostrar_mensaje('Este rol ya ha sido procesado.', 'stop')
	RETURN
END IF

BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR SELECT * FROM rolt036
	WHERE n36_compania  = vg_codcia
	  AND n36_proceso   = vm_proceso
	  AND n36_fecha_ini = vm_r_rows[vm_row_current].n36_fecha_ini
	  AND n36_fecha_fin = vm_r_rows[vm_row_current].n36_fecha_fin
	FOR UPDATE
OPEN q_up
FETCH q_up INTO r_n36.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	WHENEVER ERROR STOP
	CALL fl_mensaje_bloqueo_otro_usuario()
	RETURN
END IF
WHENEVER ERROR STOP

--CALL muestra_detalle()

CALL leer_valores()
IF int_flag THEN
	ROLLBACK WORK
	CLEAR FORM
	CALL mostrar_botones()
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_row_current)
	END IF
	RETURN
END IF

CALL graba_detalle()

CLOSE q_up

COMMIT WORK

CALL muestra_detalle()
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION control_imprimir()
DEFINE comando 		VARCHAR(255)

	LET comando = 'fglrun rolp417 ', vg_base, ' ', vg_modulo,
                      ' ', vg_codcia, ' ', rm_par.n36_fecha_ini, ' ',
		      rm_par.n36_fecha_fin
	RUN comando
                     
END FUNCTION



FUNCTION control_imprimir_informe()
DEFINE comando 		VARCHAR(255)

	LET comando = 'fglrun rolp418 ', vg_base, ' ', vg_modulo,
                      ' ', vg_codcia, ' ', rm_par.n36_fecha_ini, ' ',
		      rm_par.n36_fecha_fin
	RUN comando
                     
END FUNCTION



FUNCTION control_imprimir_recibo(cod_trab)
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE comando 		VARCHAR(255)

	CALL fl_lee_trabajador_roles(vg_codcia, cod_trab) RETURNING r_n30.*

	LET comando = 'fglrun rolp410 ', vg_base, ' ', vg_modulo,
                      ' ', vg_codcia, ' ', rm_par.n36_ano_proceso, ' ',
		      vm_proceso, ' ', 'N'

	IF r_n30.n30_cod_trab IS NOT NULL THEN
		LET comando = comando, ' ', r_n30.n30_cod_depto, ' ',
			      r_n30.n30_cod_trab	
	END IF

	RUN comando
                     
END FUNCTION



FUNCTION leer_valores()

DEFINE r_n03		RECORD LIKE rolt003.*

DEFINE opcion		CHAR(1)
DEFINE i                INTEGER
DEFINE j                INTEGER
DEFINE salir            INTEGER
DEFINE resp             VARCHAR(6)

DEFINE valor		LIKE rolt036.n36_ganado_per

DEFINE tot_valor	LIKE rolt036.n36_ganado_per
DEFINE tot_anticipo	LIKE rolt036.n36_valor_bruto
DEFINE tot_desctos	LIKE rolt036.n36_descuentos
DEFINE tot_neto 	LIKE rolt036.n36_valor_neto
                                                                                
LET int_flag = 0

CALL fl_lee_proceso_roles(vm_proceso) RETURNING r_n03.*

CALL carga_trabajadores()
                                                                                
OPTIONS
        INSERT KEY F30,
        DELETE KEY F31
                                                                                
LET salir = 0
WHILE (salir = 0)
CALL set_count(vm_numelm)
DISPLAY ARRAY rm_scr TO ra_scr.*
        ON KEY(INTERRUPT)
                LET int_flag = 0
                CALL fl_mensaje_abandonar_proceso() RETURNING resp
                IF resp = 'Yes' THEN
                        LET int_flag = 1
                        EXIT DISPLAY
                END IF
	ON KEY (F5)
		CALL lee_muestra_descuentos(i)
		LET int_flag = 0
		DISPLAY rm_scr[i].* TO ra_scr[j].*
		CALL calcula_totales() RETURNING tot_valor,   tot_anticipo,
					         tot_desctos, tot_neto
		DISPLAY BY NAME tot_valor, tot_anticipo, tot_desctos, tot_neto
	ON KEY (F6)
		CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
		IF resp <> 'Yes' THEN
			CONTINUE DISPLAY	
		END IF

		CALL regenerar_novedades_empleado(vm_cod_trab[i].n36_cod_trab)
		LET int_flag = 0
		DELETE FROM tmp_descuentos 
			WHERE n37_cod_trab = vm_cod_trab[i].n36_cod_trab

		INSERT INTO tmp_descuentos
			SELECT n37_cod_trab,  n37_cod_rubro, n06_nombre, 
                               n37_num_prest, n37_valor
			FROM rolt037, rolt006
		       	WHERE n37_compania  = vg_codcia
			  AND n37_proceso   = vm_proceso
			  AND n37_fecha_ini = rm_par.n36_fecha_ini
			  AND n37_fecha_fin = rm_par.n36_fecha_fin
			  AND n37_cod_trab  = vm_cod_trab[i].n36_cod_trab
			  AND n06_cod_rubro = n37_cod_rubro

		SELECT n36_ganado_per, n36_valor_bruto, n36_descuentos,
		       n36_valor_neto
		  INTO rm_scr[i].n36_ganado_per, rm_scr[i].n36_valor_bruto,
                       rm_scr[i].n36_descuentos, rm_scr[i].n36_valor_neto
		 FROM rolt036
		 WHERE n36_compania  = vg_codcia
		   AND n36_proceso   = vm_proceso
		   AND n36_fecha_ini = rm_par.n36_fecha_ini
		   AND n36_fecha_fin = rm_par.n36_fecha_fin
		   AND n36_cod_trab  = vm_cod_trab[i].n36_cod_trab

		SELECT NVL(SUM(n37_valor), 0) 
			INTO rm_scr[vm_numelm].n36_valor_bruto
			FROM tmp_descuentos
			WHERE n37_cod_trab = vm_cod_trab[vm_numelm].n36_cod_trab
			  AND n37_num_prest IS NOT NULL
		LET rm_scr[vm_numelm].n36_descuentos = 
			rm_scr[vm_numelm].n36_descuentos -  
			rm_scr[vm_numelm].n36_valor_bruto

		DISPLAY rm_scr[i].* TO ra_scr[j].*
		CALL calcula_totales() RETURNING tot_valor,   tot_anticipo,
					         tot_desctos, tot_neto
		DISPLAY BY NAME tot_valor, tot_anticipo, tot_desctos, tot_neto

		CALL fl_mostrar_mensaje('Proceso terminado OK.', 'info')
	ON KEY (F7)
--		CALL forma_pago(i)
		CALL fl_modifica_forma_pago(vg_codcia, 
					    vm_cod_trab[i].n36_cod_trab, 
					    vm_cod_trab[i].n36_tipo_pago,
					    vm_cod_trab[i].n36_bco_empresa,
					    vm_cod_trab[i].n36_cta_empresa,
					    vm_cod_trab[i].n36_cta_trabaj 
		) RETURNING vm_cod_trab[i].n36_tipo_pago,
			    vm_cod_trab[i].n36_bco_empresa,
			    vm_cod_trab[i].n36_cta_empresa,
			    vm_cod_trab[i].n36_cta_trabaj 

		LET int_flag = 0
        BEFORE DISPLAY
                --#CALL dialog.keysetlabel('F5','Descuentos')
                --#CALL dialog.keysetlabel('F6','Regenerar Decimo')
                --#CALL dialog.keysetlabel('F7','Tipo de Pago')
                LET vm_filas_pant = fgl_scr_size('ra_scr')
		CALL calcula_totales() RETURNING tot_valor,   tot_anticipo,
					         tot_desctos, tot_neto
		DISPLAY BY NAME tot_valor, tot_anticipo, tot_desctos, tot_neto
        BEFORE ROW
                LET i = arr_curr()
                LET j = scr_line()
		CALL muestra_contadores_det(i, vm_numelm)
        AFTER DISPLAY
		CALL calcula_totales() RETURNING tot_valor,   tot_anticipo,
					         tot_desctos, tot_neto
		DISPLAY BY NAME tot_valor, tot_anticipo, tot_desctos, tot_neto
                LET salir = 1
END DISPLAY
IF int_flag = 1 THEN
        LET salir = 1
END IF
                                                                                
END WHILE
CALL muestra_contadores_det(0, vm_numelm)

END FUNCTION



FUNCTION graba_detalle()
DEFINE i 		INTEGER
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n36		RECORD LIKE rolt036.*

DEFINE query		VARCHAR(500)

FOR i = 1 TO vm_numelm
	SELECT NVL(SUM(n37_valor), 0) INTO rm_scr[i].n36_descuentos 
		FROM tmp_descuentos
		WHERE n37_cod_trab = vm_cod_trab[i].n36_cod_trab

	UPDATE rolt036 SET
		n36_descuentos   = rm_scr[i].n36_descuentos,
		n36_valor_neto   = rm_scr[i].n36_valor_neto,
		n36_tipo_pago    = vm_cod_trab[i].n36_tipo_pago,
		n36_bco_empresa  = vm_cod_trab[i].n36_bco_empresa,
		n36_cta_empresa  = vm_cod_trab[i].n36_cta_empresa,
		n36_cta_trabaj   = vm_cod_trab[i].n36_cta_trabaj
	WHERE n36_compania  = vg_codcia
	  AND n36_proceso   = vm_proceso
	  AND n36_fecha_ini = rm_par.n36_fecha_ini
	  AND n36_fecha_fin = rm_par.n36_fecha_fin
	  AND n36_cod_trab  = vm_cod_trab[i].n36_cod_trab 

	DELETE FROM rolt037 WHERE n37_compania  = vg_codcia
			      AND n37_proceso   = vm_proceso
	  		      AND n37_fecha_ini = rm_par.n36_fecha_ini
		      	      AND n37_fecha_fin = rm_par.n36_fecha_fin
		      	      AND n37_cod_trab  = vm_cod_trab[i].n36_cod_trab 

	LET query = 'INSERT INTO rolt037  ', 
	            '	SELECT ', vg_codcia, ', "', vm_proceso, '", MDY(',
		                  MONTH(rm_par.n36_fecha_ini), ', ', 
		                  DAY(rm_par.n36_fecha_ini), ', ', 
		                  YEAR(rm_par.n36_fecha_ini), '), MDY(', 
		                  MONTH(rm_par.n36_fecha_fin), ', ', 
		                  DAY(rm_par.n36_fecha_fin), ', ', 
		                  YEAR(rm_par.n36_fecha_fin), '), ', 
		      	          vm_cod_trab[i].n36_cod_trab, ', ', 
				  ' n37_cod_rubro, n37_num_prest, n06_orden, ',
				  ' n06_det_tot, n06_imprime_0, n37_valor ',
		    '	FROM tmp_descuentos, rolt006 ',
		    '  	WHERE n37_cod_trab = ', vm_cod_trab[i].n36_cod_trab, 
		    '     AND n06_cod_rubro = n37_cod_rubro '

	PREPARE stmnt FROM query
	EXECUTE stmnt
END FOR

END FUNCTION



FUNCTION lee_muestra_descuentos(currelm)
DEFINE currelm		INTEGER
DEFINE resp		VARCHAR(6)
DEFINE i		SMALLINT
DEFINE j		SMALLINT
DEFINE salir		INTEGER
DEFINE rubro		LIKE rolt037.n37_cod_rubro
DEFINE valor		LIKE rolt037.n37_valor

DEFINE tot_valor	LIKE rolt036.n36_descuentos

DEFINE r_n06		RECORD LIKE rolt006.*

OPEN WINDOW w_221_2 AT 4,6 WITH 20 ROWS, 70 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_221_2 FROM '../forms/rolf221_2'
ELSE
	OPEN FORM f_221_2 FROM '../forms/rolf221_2'
END IF
DISPLAY FORM f_221_2

CALL carga_descuentos(currelm)

LET salir = 0

OPTIONS
        INSERT KEY F10,
        DELETE KEY F11

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
		IF INFIELD(n37_cod_rubro) AND 
                   rm_desc[i].n37_num_prest IS NULL 
 		THEN
			CALL fl_ayuda_rubros_generales_roles('DE', 'T',
						'T', 'S', 'T', 'T')
				RETURNING r_n06.n06_cod_rubro, 
					  r_n06.n06_nombre 
			IF r_n06.n06_cod_rubro IS NOT NULL THEN
				LET rm_desc[i].n37_cod_rubro =
						r_n06.n06_cod_rubro
				LET rm_desc[i].n_rubro =
						r_n06.n06_nombre
				DISPLAY rm_desc[i].* TO ra_desc[j].*
			END IF
		END IF
	ON KEY(F5)
		LET i = arr_curr()
		IF rm_desc[i].n37_num_prest IS NULL THEN
			CONTINUE INPUT
		END IF
		CALL ver_anticipo(i)
		LET int_flag = 0
	ON KEY(F6)
		LET i = arr_curr()
		CALL fl_valor_ganado_liquidacion(vg_codcia, vm_proceso,
						vm_cod_trab[i].n36_cod_trab,
						rm_par.n36_fecha_ini,
						rm_par.n36_fecha_fin)
		LET int_flag = 0
        BEFORE INPUT
                --#CALL dialog.keysetlabel('F6','Detalle Tot. Gan.')
		CALL calcula_total_descuento(arr_count()) RETURNING tot_valor   
		DISPLAY BY NAME tot_valor
        BEFORE ROW
                LET i = arr_curr()
                LET j = scr_line()
		--#IF rm_desc[i].n37_num_prest IS NULL THEN
			--#CALL dialog.keysetlabel("F5","")
		--#ELSE
			--#CALL dialog.keysetlabel("F5","Anticipo")
		--#END IF
	BEFORE DELETE
		IF rm_desc[i].n37_num_prest IS NOT NULL THEN
			CALL fl_mostrar_mensaje('No puede eliminar este registro.', 'info')
			EXIT INPUT
		END IF
		CALL calcula_total_descuento(arr_count()) RETURNING tot_valor
		DISPLAY BY NAME tot_valor
		DISPLAY rm_scr[currelm].n36_ganado_per - tot_valor
			TO n36_valor_neto
	BEFORE FIELD n37_cod_rubro
		LET rubro = rm_desc[i].n37_cod_rubro
	AFTER FIELD n37_cod_rubro
		IF (rm_desc[i].n37_cod_rubro <> rubro OR 
		    rm_desc[i].n37_cod_rubro IS NULL) AND 
		   rm_desc[i].n37_num_prest IS NOT NULL 
		THEN
			CALL fl_mostrar_mensaje('No puede modificar este registro.', 'info')
			LET rm_desc[i].n37_cod_rubro = rubro	
			DISPLAY rm_desc[i].* TO ra_desc[j].*
		END IF
		IF rm_desc[i].n37_cod_rubro IS NOT NULL THEN
			CALL fl_lee_rubro_roles(rm_desc[i].n37_cod_rubro)
				RETURNING r_n06.*
			LET rm_desc[i].n_rubro = r_n06.n06_nombre
			DISPLAY rm_desc[i].* TO ra_desc[j].*
		END IF
	BEFORE FIELD n37_valor
		LET valor = rm_desc[i].n37_valor
	AFTER FIELD n37_valor
		IF (rm_desc[i].n37_valor <> valor OR 
		    rm_desc[i].n37_valor IS NULL) AND 
		   rm_desc[i].n37_num_prest IS NOT NULL 
		THEN
			CALL fl_mostrar_mensaje('No puede modificar este registro.', 'info')
			LET rm_desc[i].n37_valor = valor	
			DISPLAY rm_desc[i].* TO ra_desc[j].*
		END IF
		IF rm_desc[i].n37_cod_rubro IS NOT NULL THEN
			IF rm_desc[i].n37_valor < 0 THEN
				NEXT FIELD n37_valor
			END IF
			DISPLAY rm_desc[i].* TO ra_desc[j].*
			CALL calcula_total_descuento(arr_count()) 
				RETURNING tot_valor
			DISPLAY BY NAME tot_valor
			DISPLAY rm_scr[currelm].n36_ganado_per - tot_valor
				TO n36_valor_neto
		END IF
	AFTER INPUT
		LET vm_numdesc = arr_count()
		CALL calcula_total_descuento(vm_numdesc) RETURNING tot_valor
		DISPLAY BY NAME tot_valor
		DISPLAY rm_scr[currelm].n36_ganado_per - tot_valor
			TO n36_valor_neto
		IF tot_valor > rm_scr[currelm].n36_ganado_per THEN
			CALL fl_mostrar_mensaje('El total de descuentos debe ser menor al valor del decimo.', 'info')
			CONTINUE INPUT
		END IF
		LET salir = 1 
END INPUT
END WHILE
--IF int_flag = 1 THEN
--	LET int_flag = 0
--	CLOSE WINDOW w_207_2
--	RETURN
--END IF

DELETE FROM tmp_descuentos 
	WHERE n37_cod_trab = vm_cod_trab[currelm].n36_cod_trab

LET rm_scr[currelm].n36_valor_bruto = 0 
LET rm_scr[currelm].n36_descuentos = 0 
FOR i = 1 TO vm_numdesc
	INSERT INTO tmp_descuentos VALUES (vm_cod_trab[currelm].n36_cod_trab,
		rm_desc[i].*)
	IF rm_desc[i].n37_num_prest IS NULL THEN
		LET rm_scr[currelm].n36_descuentos = 
			rm_scr[currelm].n36_descuentos + rm_desc[i].n37_valor
	ELSE
		LET rm_scr[currelm].n36_valor_bruto = 
			rm_scr[currelm].n36_valor_bruto + rm_desc[i].n37_valor
	END IF  
END FOR 

LET rm_scr[currelm].n36_valor_neto = rm_scr[currelm].n36_ganado_per -
	(rm_scr[currelm].n36_valor_bruto + rm_scr[currelm].n36_descuentos) 

CLOSE WINDOW w_221_2

END FUNCTION



FUNCTION carga_descuentos(curr_elm)
DEFINE curr_elm			INTEGER	
DEFINE i			INTEGER

DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_g34		RECORD LIKE gent034.*

-- Muestro los otros datos primero
CALL fl_lee_departamento(vg_codcia, vm_cod_trab[curr_elm].n36_cod_depto) 
	RETURNING r_g34.*
CALL fl_lee_banco_general(vm_cod_trab[curr_elm].n36_bco_empresa) 
	RETURNING r_g08.*

DISPLAY 'Cod.'     TO bt_cod_rubro
DISPLAY 'Rubro'    TO bt_nom_rubro
DISPLAY 'Anticipo' TO bt_num_prest
DISPLAY 'Valor'    TO bt_valor

DISPLAY BY NAME vm_cod_trab[curr_elm].n36_cod_trab,
		rm_scr[curr_elm].n_trab,
		vm_cod_trab[curr_elm].n36_cod_depto,
		vm_cod_trab[curr_elm].n36_tipo_pago,
		vm_cod_trab[curr_elm].n36_bco_empresa,
		vm_cod_trab[curr_elm].n36_cta_empresa,
		vm_cod_trab[curr_elm].n36_cta_trabaj,
		rm_scr[curr_elm].n36_ganado_per,
		rm_scr[curr_elm].n36_valor_neto

DISPLAY rm_scr[curr_elm].n36_valor_bruto + rm_scr[curr_elm].n36_descuentos 
	TO tot_valor

CASE vm_cod_trab[curr_elm].n36_tipo_pago
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
	SELECT n37_cod_rubro, n_rubro, n37_num_prest, n37_valor
		FROM tmp_descuentos
		WHERE n37_cod_trab = vm_cod_trab[curr_elm].n36_cod_trab
                                                                                
LET vm_numdesc = 1
FOREACH q_desc INTO rm_desc[vm_numdesc].*
        LET vm_numdesc = vm_numdesc + 1
        IF vm_numdesc > vm_maxdesc THEN
                CALL fl_mensaje_arreglo_incompleto()
                EXIT PROGRAM
        END IF
END FOREACH
FREE q_desc

LET vm_numdesc = vm_numdesc - 1

FOR i = (vm_numdesc + 1) TO vm_maxdesc
	INITIALIZE rm_desc[i].* TO NULL
END FOR

END FUNCTION



FUNCTION control_cerrar()
DEFINE r_n36		RECORD LIKE rolt036.*
DEFINE r_n37		RECORD LIKE rolt037.*
DEFINE r_n45		RECORD LIKE rolt045.*
DEFINE resp		VARCHAR(6)
DEFINE neg		INTEGER
DEFINE estado		CHAR(1)
DEFINE query		VARCHAR(500)

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
IF num_args() <> 7 THEN
	CALL mostrar_registro(vm_row_current)
END IF

IF rm_par.n36_estado = 'P' THEN
	CALL fl_mostrar_mensaje('Este rol ya ha sido procesado.', 'stop')
	RETURN
END IF

IF num_args() <> 7 THEN
	CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
	IF resp = 'No' THEN
	        LET int_flag = 0
	        RETURN
	END IF
END IF

SELECT COUNT(n36_cod_trab) INTO neg
	FROM rolt036
       	WHERE n36_compania   = vg_codcia
	  AND n36_proceso    = vm_proceso
	  AND n36_fecha_ini  = vm_r_rows[vm_row_current].n36_fecha_ini
	  AND n36_fecha_fin  = vm_r_rows[vm_row_current].n36_fecha_fin
	  AND n36_valor_neto < 0
	
IF neg > 0 THEN
	CALL fl_mostrar_mensaje('Existen empleados con valor a recibir negativo, por favor corrija y vuelva a intentar.', 'info')
	RETURN
END IF

BEGIN WORK

LET query = 'SELECT * FROM rolt036 ',
        	' WHERE n36_compania  =  ', vg_codcia,
		'   AND n36_proceso   = "', vm_proceso, '"',
		'   AND n36_fecha_ini = DATE(', 
			vm_r_rows[vm_row_current].n36_fecha_ini, ')',
	  	'   AND n36_fecha_fin = DATE(', 
			vm_r_rows[vm_row_current].n36_fecha_fin,')'
IF num_args() = 7 THEN
	LET query = query, '   AND n36_cod_trab  = ', arg_val(6)
END IF
LET query = query, ' FOR UPDATE '

WHENEVER ERROR CONTINUE
PREPARE cerr_cons FROM query
DECLARE q_cerr CURSOR FOR cerr_cons 
OPEN q_cerr
FETCH q_cerr INTO r_n36.*
IF STATUS < 0 THEN
        ROLLBACK WORK
        WHENEVER ERROR STOP
        CALL fl_mensaje_bloqueo_otro_usuario()
        RETURN
END IF
WHENEVER ERROR STOP

LET estado = 'P'
IF num_args() = 7 THEN
	LET estado = 'F'
END IF
-- Se actualiza n36_fecing con la fecha en que se cerro el registro
-- para determinar en que quincena se pago
UPDATE rolt036 SET n36_estado = estado,
                   n36_fecing = CURRENT
        WHERE n36_compania = vg_codcia
	  AND n36_proceso  = vm_proceso
	  AND n36_fecha_ini = vm_r_rows[vm_row_current].n36_fecha_ini
	  AND n36_fecha_fin = vm_r_rows[vm_row_current].n36_fecha_fin
          AND n36_estado    = 'A'

UPDATE rolt005 SET n05_activo = 'N'
	WHERE n05_compania = vg_codcia
	  AND n05_proceso  = vm_proceso 
	  AND n05_activo   = 'S'

DECLARE q_prest CURSOR FOR
	SELECT * FROM rolt037
        	WHERE n37_compania  = vg_codcia
		  AND n37_proceso   = vm_proceso
		  AND n37_fecha_ini = vm_r_rows[vm_row_current].n36_fecha_ini
		  AND n37_fecha_fin = vm_r_rows[vm_row_current].n36_fecha_fin

FOREACH q_prest INTO r_n37.*
	IF num_args() = 7 THEN
		IF arg_val(6) <> r_n37.n37_cod_trab THEN
			CONTINUE FOREACH
		END IF
	END IF
	IF r_n37.n37_num_prest IS NOT NULL THEN
		CALL fl_lee_cab_prestamo_roles(vg_codcia, r_n37.n37_num_prest)
			RETURNING r_n45.*
		IF r_n45.n45_compania IS NULL THEN
			ROLLBACK WORK
			CALL fl_mostrar_mensaje('No existe préstamo: ' || 
						 r_n37.n37_num_prest, 'stop')
			EXIT PROGRAM
		END IF
	END IF
	IF (r_n45.n45_descontado + r_n37.n37_valor) >=
	   (r_n45.n45_val_prest + r_n45.n45_valor_int + r_n45.n45_sal_prest_ant)
	THEN
		LET r_n45.n45_estado = 'P' 
	END IF
	UPDATE rolt058
		SET n58_div_act    = n58_div_act + 1,
		    n58_saldo_dist = n58_saldo_dist - r_n37.n37_valor
		WHERE n58_compania  = r_n37.n37_compania
		  AND n58_num_prest = r_n37.n37_num_prest
		  AND n58_proceso   = r_n37.n37_proceso

	UPDATE rolt046 SET n46_saldo = n46_valor - r_n37.n37_valor
        	WHERE n46_compania   = vg_codcia
		  AND n46_num_prest  = r_n37.n37_num_prest
		  AND n46_cod_liqrol = vm_proceso
		  AND n46_fecha_ini  = vm_r_rows[vm_row_current].n36_fecha_ini
		  AND n46_fecha_fin  = vm_r_rows[vm_row_current].n36_fecha_fin
		  AND n46_saldo      = r_n37.n37_valor

	UPDATE rolt046
		SET n46_saldo = n46_valor - (r_n37.n37_valor + n46_saldo)
        	WHERE n46_compania   = vg_codcia
		  AND n46_num_prest  = r_n37.n37_num_prest
		  AND n46_cod_liqrol = vm_proceso
		  AND n46_fecha_ini  = vm_r_rows[vm_row_current].n36_fecha_ini
		  AND n46_fecha_fin  = vm_r_rows[vm_row_current].n36_fecha_fin
		  AND n46_saldo      > 0
		  AND n46_saldo      < r_n37.n37_valor

	UPDATE rolt045 SET n45_descontado = n45_descontado + r_n37.n37_valor,
			   n45_estado     = r_n45.n45_estado
        	WHERE n45_compania  = vg_codcia
		  AND n45_num_prest = r_n37.n37_num_prest
		  AND n45_cod_rubro = r_n37.n37_cod_rubro
		  AND n45_cod_trab  = r_n37.n37_cod_trab
		  AND n45_estado    IN ('A', 'R')
		  AND n45_val_prest + n45_valor_int +
			n45_sal_prest_ant - n45_descontado > 0
END FOREACH

COMMIT WORK

INITIALIZE rm_n05.* TO NULL 
SELECT * INTO rm_n05.* FROM rolt005
	WHERE n05_compania = vg_codcia
	  AND n05_activo   = 'S' 

IF num_args() <> 7 THEN
	CALL mostrar_registro(vm_row_current)	
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL fl_mensaje_registro_modificado()
END IF

END FUNCTION



FUNCTION mostrar_descuentos(i)
DEFINE i		INTEGER
DEFINE j		SMALLINT

OPEN WINDOW w_221_2 AT 4,6 WITH 19 ROWS, 70 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_221_2 FROM '../forms/rolf221_2'
ELSE
	OPEN FORM f_221_2 FROM '../forms/rolf221_2'
END IF
DISPLAY FORM f_221_2

CALL carga_descuentos(i)

CALL set_count(vm_numdesc)
DISPLAY ARRAY rm_desc TO ra_desc.*
	ON KEY(F5)
		LET j = arr_curr()
		IF rm_desc[j].n37_num_prest IS NULL THEN
			CONTINUE DISPLAY
		END IF
		CALL ver_anticipo(j)
		LET int_flag = 0
	--#BEFORE ROW 
		--#LET j = arr_curr()	
		--#IF rm_desc[j].n37_num_prest IS NULL THEN
			--#CALL dialog.keysetlabel("F5","")
		--#ELSE
			--#CALL dialog.keysetlabel("F5","Anticipo")
		--#END IF
END DISPLAY

CLOSE WINDOW w_221_2

END FUNCTION



FUNCTION calcula_total_descuento(numelm)
DEFINE numelm           INTEGER
DEFINE i                INTEGER
DEFINE valor            LIKE rolt037.n37_valor     
DEFINE tot_valor        LIKE rolt037.n37_valor     
DEFINE n36_valor_neto   LIKE rolt036.n36_valor_neto     
                                                                                
LET valor = 0
LET tot_valor = 0

FOR i = 1 TO numelm
	LET valor = rm_desc[i].n37_valor
	IF valor IS NULL THEN
		LET valor = 0
	END IF
        LET tot_valor = tot_valor + valor
END FOR
                                                                               
RETURN tot_valor

END FUNCTION



FUNCTION regenerar_novedades_empleado(cod_trab)
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n36		RECORD LIKE rolt036.*
DEFINE r_n37		RECORD LIKE rolt037.*

DEFINE op		LIKE rolt004.n04_operacion
DEFINE rubro		LIKE rolt033.n33_cod_rubro
DEFINE valor 		LIKE rolt036.n36_ganado_real
DEFINE dsctos 		LIKE rolt036.n36_descuentos
DEFINE cod_trab		LIKE rolt036.n36_cod_trab

DEFINE query		CHAR(3000)

DEFINE fecha_ini	LIKE rolt036.n36_fecha_ini
DEFINE fecha_fin	LIKE rolt036.n36_fecha_fin
DEFINE total_ganado	LIKE rolt036.n36_ganado_real
DEFINE anhos_trab	SMALLINT
DEFINE meses_trab	SMALLINT
DEFINE dias_trab	SMALLINT

IF rm_par.n36_estado = 'P' THEN
	CALL fl_mostrar_mensaje('No se puede modificar. La liquidación ya fue procesada.', 'stop')
	EXIT PROGRAM
END IF

WHENEVER ERROR CONTINUE
DELETE FROM rolt037 WHERE n37_compania  = vg_codcia
		      AND n37_proceso   = vm_proceso
		      AND n37_fecha_ini = rm_par.n36_fecha_ini
		      AND n37_fecha_fin = rm_par.n36_fecha_fin
		      AND n37_cod_trab  = cod_trab
IF status < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No se pudo borrar detalle de '
				|| 'liquidacion de decimos (rolt037). '
				|| 'Intente mas tarde.', 'stop')
	EXIT PROGRAM
END IF

DELETE FROM rolt036 WHERE n36_compania  = vg_codcia
		      AND n36_proceso   = vm_proceso
		      AND n36_fecha_ini = rm_par.n36_fecha_ini
		      AND n36_fecha_fin = rm_par.n36_fecha_fin
		      AND n36_cod_trab  = cod_trab
IF status < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No se pudo borrar cabecera de '
				|| 'liquidacion de decimos (rolt036). '
				|| 'Intente mas tarde.', 'stop')
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP

CALL fl_lee_trabajador_roles(vg_codcia, cod_trab) RETURNING r_n30.*
IF r_n30.n30_cod_trab IS NULL THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No existe codigo de trabajador.', 'stop')
	EXIT PROGRAM
END IF

LET query = 'SELECT ', vg_codcia, ' AS compania, "', vm_proceso,
		'" AS proceso, MDY(', MONTH(rm_par.n36_fecha_ini), ', ',
		DAY(rm_par.n36_fecha_ini), ', ', YEAR(rm_par.n36_fecha_ini),
		') AS fecha_ini,', ' MDY(', MONTH(rm_par.n36_fecha_fin), ', ',
		DAY(rm_par.n36_fecha_fin), ', ', YEAR(rm_par.n36_fecha_fin),
		') AS fecha_fin,', r_n30.n30_cod_trab, ' AS cod_trab, ',
		'n45_cod_rubro AS cod_rubd, n45_num_prest AS num_pre, ',
		'n06_orden, n06_det_tot,n06_imprime_0,SUM(n46_saldo) AS saldo ',
		' FROM rolt045, rolt046, rolt006 ',
		' WHERE n45_compania   = ', vg_codcia,
		'   AND n45_cod_trab   = ', r_n30.n30_cod_trab, 
		'   AND n45_estado     IN ("A", "R", "P") ',
		'   AND n46_compania   = n45_compania ',
		'   AND n46_num_prest  = n45_num_prest ',
		'   AND n46_cod_liqrol = "', vm_proceso, '"',	
		'   AND n46_fecha_ini  = MDY(', MONTH(rm_par.n36_fecha_ini),
		                         ', ', DAY(rm_par.n36_fecha_ini),
		                         ', ', YEAR(rm_par.n36_fecha_ini), ') ',
		'   AND n46_fecha_fin  = MDY(', MONTH(rm_par.n36_fecha_fin),
		                         ', ', DAY(rm_par.n36_fecha_fin),
		                         ', ', YEAR(rm_par.n36_fecha_fin), ') ',
		'   AND n06_cod_rubro  = n45_cod_rubro ',
		' GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ',
		' HAVING SUM(n46_saldo) > 0 ',
		' UNION ',
		' SELECT ', vg_codcia, ' AS compania, "', vm_proceso,
			'" AS proceso, MDY(', MONTH(rm_par.n36_fecha_ini), ', ',
			DAY(rm_par.n36_fecha_ini), ', ',
			YEAR(rm_par.n36_fecha_ini), ') AS fecha_ini,',
			' MDY(', MONTH(rm_par.n36_fecha_fin), ', ',
			DAY(rm_par.n36_fecha_fin), ', ',
			YEAR(rm_par.n36_fecha_fin), ') AS fecha_fin,',
			r_n30.n30_cod_trab, ' AS cod_trab, n10_cod_rubro',
			' AS cod_rubd, 0 AS num_pre, n06_orden, ',
			'n06_det_tot, n06_imprime_0, SUM(n10_valor) AS saldo ',
		' FROM rolt010, rolt006 ',
		' WHERE n10_compania   = ', vg_codcia,
		'   AND n10_cod_liqrol = "', vm_proceso, '"',
		'   AND n10_cod_trab   = ', r_n30.n30_cod_trab, 
		'   AND n06_cod_rubro  = n10_cod_rubro ',
		' GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ',
		' INTO TEMP tmp_desctos  '	

PREPARE stmnt1 FROM query
EXECUTE stmnt1
	
CALL fl_lee_proceso_roles(vm_proceso) RETURNING r_n03.*

-- SE CALCULA EL TOTAL DE DIAS QUE HA TRABAJADO EN EL PERIODO
LET total_ganado = r_n03.n03_valor
IF r_n30.n30_fecha_reing IS NOT NULL THEN
	LET fecha_ini = r_n30.n30_fecha_reing
ELSE
	LET fecha_ini = r_n30.n30_fecha_ing
END IF
IF r_n30.n30_fecha_sal IS NOT NULL THEN
	LET fecha_fin = r_n30.n30_fecha_sal
	IF fecha_fin <= r_n30.n30_fecha_reing THEN
		LET fecha_fin = rm_par.n36_fecha_fin
	END IF
ELSE
	LET fecha_fin = rm_par.n36_fecha_fin
END IF
IF fecha_ini < rm_par.n36_fecha_ini THEN
	LET fecha_ini = rm_par.n36_fecha_ini
END IF
	
INITIALIZE r_n36.*, r_n37.* TO NULL

LET r_n36.n36_compania  = vg_codcia
LET r_n36.n36_proceso   = vm_proceso
LET r_n36.n36_fecha_ini = rm_par.n36_fecha_ini
LET r_n36.n36_fecha_fin = rm_par.n36_fecha_fin
LET r_n36.n36_cod_trab  = r_n30.n30_cod_trab
LET r_n36.n36_estado    = 'A'
LET r_n36.n36_cod_depto = r_n30.n30_cod_depto
LET r_n36.n36_ano_proceso = YEAR(rm_par.n36_fecha_fin) 
LET r_n36.n36_mes_proceso = MONTH(rm_par.n36_fecha_fin) 
LET r_n36.n36_fecha_ing   = r_n30.n30_fecha_ing
LET r_n36.n36_ganado_real = 
		fl_retorna_precision_valor(r_n30.n30_mon_sueldo, total_ganado)
LET r_n36.n36_ganado_per  = 
		fl_retorna_precision_valor(r_n30.n30_mon_sueldo, total_ganado)

IF fecha_ini >= rm_par.n36_fecha_ini THEN
	CALL retorna_tiempo_entre_fechas(fecha_ini, fecha_fin, 'S')
		RETURNING anhos_trab, meses_trab, dias_trab
	IF anhos_trab IS NULL THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
	IF anhos_trab > 1 THEN
		CALL fl_mostrar_mensaje('Rango de fechas incorrecta.', 'stop')
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
	IF anhos_trab = 1 THEN
		LET r_n36.n36_valor_bruto = 
			fl_retorna_precision_valor(r_n30.n30_mon_sueldo,
				total_ganado)    
	ELSE
		LET r_n36.n36_valor_bruto = 
			fl_retorna_precision_valor(r_n30.n30_mon_sueldo,
				((total_ganado / 12  * meses_trab) +
				 (total_ganado / 360 * dias_trab)))
	END IF
ELSE
	LET r_n36.n36_valor_bruto = 
		fl_retorna_precision_valor(r_n30.n30_mon_sueldo, total_ganado)    
END IF

SELECT NVL(SUM(saldo), 0) INTO dsctos FROM tmp_desctos
LET r_n36.n36_descuentos  = 
		fl_retorna_precision_valor(r_n30.n30_mon_sueldo, dsctos)
LET r_n36.n36_valor_neto  = r_n36.n36_valor_bruto - r_n36.n36_descuentos 
LET r_n36.n36_moneda      = r_n30.n30_mon_sueldo
LET r_n36.n36_paridad     = 1
LET r_n36.n36_tipo_pago   = r_n30.n30_tipo_pago
LET r_n36.n36_bco_empresa = r_n30.n30_bco_empresa
LET r_n36.n36_cta_empresa = r_n30.n30_cta_empresa
LET r_n36.n36_cta_trabaj  = r_n30.n30_cta_trabaj
LET r_n36.n36_usuario     = vg_usuario
LET r_n36.n36_fecing      = CURRENT

INSERT INTO rolt036 VALUES (r_n36.*)

UPDATE tmp_desctos SET num_pre = NULL WHERE num_pre = 0

INSERT INTO rolt037 SELECT * FROM tmp_desctos

DROP TABLE tmp_desctos

END FUNCTION



FUNCTION retorna_tiempo_entre_fechas(fecha_ini, fecha_fin, anho_comercial)
DEFINE fecha_ini		DATE
DEFINE fecha_fin		DATE
DEFINE anho_comercial		CHAR(1)

DEFINE anhos			SMALLINT
DEFINE meses			SMALLINT
DEFINE dias 			SMALLINT
DEFINE dias_mes			SMALLINT
DEFINE fecha			DATE

IF anho_comercial <> 'S' AND anho_comercial <> 'N' THEN
	CALL fl_mostrar_mensaje('Debe especificar si desea usar el mes comercial o no.', 'stop')
	RETURN NULL, NULL, NULL
END IF

IF fecha_ini > fecha_fin THEN
	CALL fl_mostrar_mensaje('Rango de fechas incorrecto.', 'stop')
	RETURN NULL, NULL, NULL
END IF

LET anhos = 0
LET meses = 0
LET dias  = 0

IF fecha_ini = fecha_fin THEN
	RETURN anhos, meses, dias
END IF

LET anhos = year(fecha_fin)  - year(fecha_ini) 
LET meses = month(fecha_fin) - month(fecha_ini)
IF meses < 0 THEN
	LET anhos = anhos - 1
	LET meses = meses + 12
END IF

LET dias_mes = 30 

IF anho_comercial = 'N' THEN
	LET fecha = MDY(month(fecha_ini) + 1, 1, year(fecha_ini))		
	LET fecha = fecha - 1
	LET dias_mes = DAY(fecha)
END IF
IF DAY(fecha_ini) > dias_mes THEN
	LET dias = 0
ELSE
	LET dias = dias_mes - DAY(fecha_ini)
END IF

IF anho_comercial = 'N' THEN
	LET fecha = MDY(month(fecha_fin) + 1, 1, year(fecha_fin))		
	LET fecha = fecha - 1
	LET dias_mes = DAY(fecha)
END IF
IF DAY(fecha_fin) < dias_mes THEN
	LET dias = dias + DAY(fecha_fin)
END IF
LET dias = dias + 1

IF dias >= dias_mes THEN
	LET dias = dias - dias_mes
	LET meses = meses + 1
	IF meses > 12 THEN
		LET meses = meses - 1
		LET anhos = anhos + 1
	END IF
END IF

RETURN anhos, meses, dias

END FUNCTION


 
FUNCTION ver_anticipo(i)
DEFINE i		SMALLINT
DEFINE param		VARCHAR(60)

LET param = ' ', rm_desc[i].n37_num_prest
CALL ejecuta_comando('NOMINA', vg_modulo, 'rolp214 ', param)

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

CREATE TEMP TABLE tmp_rol_ban
	(
		tipo_pago		CHAR(2),
		cuenta_empresa		CHAR(11),
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
		num_doc_id		VARCHAR(13),
		--num_doc_id		DECIMAL(13,0),
		empleado		VARCHAR(40),
		direccion		VARCHAR(40),
		ciudad			VARCHAR(20),
		telefono		VARCHAR(10),
		local_cobro		VARCHAR(10),
		referencia		VARCHAR(30),
		referencia_adic		VARCHAR(30)
	)

LET query = 'SELECT "PA" AS tip_pag, g09_numero_cta AS cuenta_empr,',
			' 0 AS secu, "" AS comp_p, n36_cod_trab AS cod_emp,',
			' g13_simbolo AS mone,TRUNC(n36_valor_neto * 100,0) AS',
			' neto_rec, "CTA" AS for_pag, "0036" AS cod_ban,',
			' CASE WHEN n30_tipo_cta_tra = "A"',
				' THEN "AHO"',
				' ELSE "CTE"',
			' END AS tipo_c, n36_cta_trabaj AS cuenta_empl,',
			' n30_tipo_doc_id AS tipo_id,',
			' CASE WHEN n36_cod_trab = 24 AND ', vg_codloc, ' = 1 ',
				' THEN "0920503067"',
				' ELSE n30_num_doc_id',
			' END AS cedula,',
			' CASE WHEN n36_cod_trab = 24 AND ', vg_codloc, ' = 1 ',
				' THEN "CHILA RUA EMILIANO FRANCISCO"',
				' ELSE n30_nombres',
			' END AS empleados, n30_domicilio AS direc,',
			' g31_nombre AS ciudad_emp, n30_telef_domic AS fono,',
			' "" AS loc_cob, n03_nombre AS refer1,',
			' CASE',
				' WHEN n36_mes_proceso = 01 THEN "ENERO"',
				' WHEN n36_mes_proceso = 02 THEN "FEBRERO"',
				' WHEN n36_mes_proceso = 03 THEN "MARZO"',
				' WHEN n36_mes_proceso = 04 THEN "ABRIL"',
				' WHEN n36_mes_proceso = 05 THEN "MAYO"',
				' WHEN n36_mes_proceso = 06 THEN "JUNIO"',
				' WHEN n36_mes_proceso = 07 THEN "JULIO"',
				' WHEN n36_mes_proceso = 08 THEN "AGOSTO"',
				' WHEN n36_mes_proceso = 09 THEN "SEPTIEMBRE"',
				' WHEN n36_mes_proceso = 10 THEN "OCTUBRE"',
				' WHEN n36_mes_proceso = 11 THEN "NOVIEMBRE"',
				' WHEN n36_mes_proceso = 12 THEN "DICIEMBRE"',
			' END || "-" || LPAD(n36_ano_proceso, 4, 0) AS refer2',
		' FROM rolt036, rolt030, gent009, gent013, gent031,',
			' rolt003 ',
		' WHERE n36_compania    = ', vg_codcia,
		'   AND n36_proceso     = "', vm_proceso, '"',
		'   AND n36_fecha_ini   = "', rm_par.n36_fecha_ini, '"',
		'   AND n36_fecha_fin   = "', rm_par.n36_fecha_fin, '"',
		'   AND n36_estado     <> "E"',
		'   AND n36_valor_neto  > 0 ',
  		'   AND n30_compania    = n36_compania ',
		'   AND n30_cod_trab    = n36_cod_trab ',
		'   AND g09_compania    = n36_compania ',
		'   AND g09_banco       = n36_bco_empresa ',
		'   AND g09_numero_cta  = n36_cta_empresa ',
		'   AND n03_proceso     = n36_proceso ',
		'   AND g13_moneda      = n36_moneda ',
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
		--' REPLACE(direccion, "ñ", "N") direccion,',
		--' ciudad, telefono, local_cobro, referencia, referencia_adic',
		' "" direccion, "" ciudad, "" telefono, "" local_cobro,',
		' "DECIMO CUARTO" referencia, referencia_adic',
		' FROM tmp_rol_ban ',
		' INTO TEMP t1 '
PREPARE exec_t1 FROM query
EXECUTE exec_t1
DROP TABLE tmp_rol_ban
UNLOAD TO "../../../tmp/rol_pag.txt" DELIMITER "	"
	SELECT * FROM t1
		ORDER BY secuencia
LET nom_mes = UPSHIFT(fl_justifica_titulo('I',
			fl_retorna_nombre_mes(MONTH(rm_par.n36_fecha_fin)), 11))
LET archivo = "ACRE_", rm_loc.g02_nombre[1, 3] CLIPPED, "_", vm_proceso,
		nom_mes[1, 3] CLIPPED, YEAR(rm_par.n36_fecha_fin) USING "####",
		"_"
CALL fl_lee_ciudad(rm_loc.g02_ciudad) RETURNING r_g31.*
LET archivo = archivo CLIPPED, r_g31.g31_siglas CLIPPED, ".txt"
LET mensaje = 'Archivo ', archivo CLIPPED, ' Generado ', FGL_GETENV("HOME"),
		'/tmp/  OK'
LET archivo = "mv ../../../tmp/rol_pag.txt $HOME/tmp/", archivo CLIPPED
RUN archivo
DROP TABLE t1
CALL fl_mostrar_mensaje(mensaje, 'info')

END FUNCTION 



{
FUNCTION forma_pago(curr_elm)
DEFINE curr_elm		SMALLINT
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n36		RECORD LIKE rolt036.*
DEFINE r_b10		RECORD LIKE ctbt010.*

DEFINE resp		CHAR(6)
DEFINE resul		SMALLINT
DEFINE r_bco		RECORD LIKE gent009.*
DEFINE r_bco_gen	RECORD LIKE gent008.*
DEFINE codp_aux         LIKE gent030.g30_pais
DEFINE nomp_aux         LIKE gent030.g30_nombre
DEFINE codc_aux         LIKE gent031.g31_ciudad
DEFINE nomc_aux         LIKE gent031.g31_nombre
DEFINE codb_aux         LIKE gent008.g08_banco
DEFINE nomb_aux         LIKE gent008.g08_nombre
DEFINE tipo_aux         LIKE gent009.g09_tipo_cta
DEFINE num_aux          LIKE gent009.g09_numero_cta

CALL fl_lee_trabajador_roles(vg_codcia, vm_cod_trab[curr_elm].n36_cod_trab)
	RETURNING r_n30.*

LET r_n36.n36_tipo_pago   = vm_cod_trab[curr_elm].n36_tipo_pago
LET r_n36.n36_bco_empresa = vm_cod_trab[curr_elm].n36_bco_empresa
LET r_n36.n36_cta_empresa = vm_cod_trab[curr_elm].n36_cta_empresa
LET r_n36.n36_cta_trabaj  = vm_cod_trab[curr_elm].n36_cta_trabaj 
	
OPEN WINDOW w_221_3 AT 4,6 WITH 12 ROWS, 70 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER) 
OPEN FORM f_221_3 FROM '../forms/rolf221_3'
DISPLAY FORM f_221_3

CALL fl_lee_banco_general(r_n36.n36_bco_empresa) RETURNING r_bco_gen.*
DISPLAY r_bco_gen.g08_nombre TO tit_banco

INPUT BY NAME r_n30.n30_cod_trab, r_n30.n30_nombres, r_n36.n36_tipo_pago, 
	      r_n36.n36_bco_empresa, r_n36.n36_cta_empresa, 
	      r_n36.n36_cta_trabaj WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF field_touched(r_n36.n36_tipo_pago,
			r_n36.n36_bco_empresa, r_n36.n36_cta_empresa,
			r_n36.n36_cta_trabaj)
        	THEN
               		LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
                		RETURNING resp
              		IF resp = 'Yes' THEN
				LET int_flag = 1
				EXIT INPUT
                	END IF
		ELSE
			EXIT INPUT
		END IF
	ON KEY (F2)
		IF infield(n36_bco_empresa) THEN
                        CALL fl_ayuda_cuenta_banco(vg_codcia, 'A')
                                RETURNING codb_aux, nomb_aux, tipo_aux, num_aux
                        LET int_flag = 0
                        IF codb_aux IS NOT NULL THEN
				LET r_n36.n36_bco_empresa = codb_aux
				LET r_n36.n36_cta_empresa = num_aux
                                DISPLAY BY NAME r_n36.n36_bco_empresa
                                DISPLAY nomb_aux TO tit_banco
				DISPLAY BY NAME r_n36.n36_cta_empresa
                        END IF
                END IF
	AFTER FIELD n36_bco_empresa
                IF r_n36.n36_bco_empresa IS NOT NULL THEN
                        CALL fl_lee_banco_general(r_n36.n36_bco_empresa)
                                RETURNING r_bco_gen.*
			IF r_bco_gen.g08_banco IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Banco no existe','exclamation')
				NEXT FIELD n36_bco_empresa
			END IF
			DISPLAY r_bco_gen.g08_nombre TO tit_banco
		ELSE
			CLEAR n36_bco_empresa, tit_banco, n36_cta_empresa
                END IF
	AFTER FIELD n36_cta_empresa
                IF r_n36.n36_cta_empresa IS NOT NULL THEN
                        CALL fl_lee_banco_compania(vg_codcia,
					r_n36.n36_bco_empresa,
					r_n36.n36_cta_empresa)
                                RETURNING r_bco.*
			IF r_bco.g09_banco IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Banco o Cuenta Corriente no existe en la compañía','exclamation')
				NEXT FIELD n36_bco_empresa
			END IF
			LET r_n36.n36_cta_empresa = r_bco.g09_numero_cta
			DISPLAY BY NAME r_n36.n36_cta_empresa
                        CALL fl_lee_banco_general(r_n36.n36_bco_empresa)
                                RETURNING r_bco_gen.*
			DISPLAY r_bco_gen.g08_nombre TO tit_banco
			IF r_bco.g09_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD n36_bco_empresa
			END IF
			CALL fl_lee_cuenta(r_g09.g09_compania,
						r_g09.g09_aux_cont)
				RETURNING r_b10.*
			IF r_b10.b10_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No se puede escoger una cuenta corriente que no tiene auxiliar contable.', 'exclamation')
				NEXT FIELD n36_bco_empresa
			END IF
			IF r_b10.b10_estado <> 'A' THEN
				CALL fl_mostrar_mensaje('El auxiliar contable de esta cuenta bancaria esta con estado bloqueado.', 'exclamation')
				NEXT FIELD n36_bco_empresa
			END IF
		ELSE
			CLEAR n36_cta_empresa
		END IF
	AFTER INPUT
		IF r_n36.n36_tipo_pago = 'E' THEN
			IF r_n36.n36_bco_empresa IS NOT NULL
			OR r_n36.n36_cta_empresa IS NOT NULL THEN
				CALL fgl_winmessage(vg_producto,'Empleado con tipo de pago efectivo. Borre el Banco y la cuenta corriente.','exclamation')
				NEXT FIELD n36_bco_empresa
			END IF
			IF r_n36.n36_cta_trabaj IS NOT NULL THEN	
				CALL fgl_winmessage(vg_producto,'Empleado con tipo de pago efectivo. Borre la cuenta del trabajador.','exclamation')
				NEXT FIELD n36_cta_trabaj
			END IF
		END IF
		IF r_n36.n36_tipo_pago = 'C' THEN
			IF r_n36.n36_bco_empresa IS NULL
			OR r_n36.n36_cta_empresa IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Empleado con tipo de pago cheque. Ingrese el Banco y la cuenta corriente.','exclamation')
				NEXT FIELD n36_bco_empresa
			END IF
			IF r_n36.n36_cta_trabaj IS NOT NULL THEN	
				CALL fgl_winmessage(vg_producto,'Empleado con tipo de pago cheque. Borre la cuenta del trabajador.','exclamation')
				NEXT FIELD n36_cta_trabaj
			END IF
		END IF
		IF r_n36.n36_tipo_pago = 'T' THEN
			IF r_n36.n36_bco_empresa IS NULL
			OR r_n36.n36_cta_empresa IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Empleado con tipo de pago transferencia. Ingrese el Banco y la cuenta corriente.','exclamation')
				NEXT FIELD n36_bco_empresa
			END IF
			IF r_n36.n36_cta_trabaj IS NULL THEN	
				CALL fgl_winmessage(vg_producto,'Empleado con tipo de pago transferencia. Ingrese la cuenta del trabajador.','exclamation')
				NEXT FIELD n36_cta_trabaj
			END IF
		END IF
END INPUT
IF int_flag THEN
	LET int_flag = 0
	CLOSE WINDOW w_221_3
	RETURN
END IF

LET vm_cod_trab[curr_elm].n36_tipo_pago   = r_n36.n36_tipo_pago
LET vm_cod_trab[curr_elm].n36_bco_empresa = r_n36.n36_bco_empresa
LET vm_cod_trab[curr_elm].n36_cta_empresa = r_n36.n36_cta_empresa
LET vm_cod_trab[curr_elm].n36_cta_trabaj  = r_n36.n36_cta_trabaj

CLOSE WINDOW w_221_3

END FUNCTION
}
