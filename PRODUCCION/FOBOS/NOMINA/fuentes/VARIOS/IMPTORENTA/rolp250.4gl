--------------------------------------------------------------------------------
-- Titulo           : rolp250.4gl - Impuesto a la renta 
-- Elaboracion      : 24-nov-2003
-- Autor            : JCM
-- Formato Ejecucion: fglrun rolp250 BD MODULO COMPANIA 
-- Ultima Correccion:
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_proceso	LIKE rolt003.n03_proceso
DEFINE rm_n03		RECORD LIKE rolt003.*
DEFINE vm_rows		ARRAY[100]	OF LIKE rolt084.n84_ano_proceso 

DEFINE rm_cia		RECORD LIKE rolt001.*
DEFINE rm_par	RECORD 
	n84_ano_proceso		LIKE rolt084.n84_ano_proceso,
	n84_estado	LIKE rolt084.n84_estado,
	n_estado	VARCHAR(13)
END RECORD
DEFINE vm_cod_trab ARRAY[500]   OF RECORD
	cod_trab 		LIKE rolt030.n30_cod_trab,
	estado			LIKE rolt084.n84_estado,
	moneda			LIKE rolt030.n30_mon_sueldo,
	fracc_ini		LIKE rolt084.n84_fracc_ini,
	ing_roles		LIKE rolt032.n32_tot_ing,
        dec_tercero		LIKE rolt036.n36_valor_neto,
        dec_cuarto		LIKE rolt036.n36_valor_neto,
        util			LIKE rolt041.n41_val_trabaj,
	vacaciones		LIKE rolt084.n84_vacaciones,
        varios			LIKE rolt044.n44_valor,
	iess			LIKE rolt084.n84_aporte_iess,
        bonificacion		LIKE rolt084.n84_bonificacion,
	otros_ing		LIKE rolt084.n84_otros_ing,
	imp_base		LIKE rolt084.n84_imp_basico,
	porc_exced		LIKE rolt084.n84_porc_exced
END RECORD
DEFINE rm_scr	ARRAY[500]	OF RECORD
	n30_nombres		LIKE rolt030.n30_nombres,
	ganado			LIKE rolt084.n84_otros_ing,
	n84_imp_real		LIKE rolt084.n84_imp_real,
	n84_imp_ret		LIKE rolt084.n84_imp_ret,
	retencion		LIKE rolt084.n84_imp_real
END RECORD
DEFINE vm_numelm		SMALLINT
DEFINE vm_maxelm		SMALLINT



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp250.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN     -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base      = arg_val(1)
LET vg_modulo    = arg_val(2)
LET vg_codcia    = arg_val(3)
LET vg_proceso = 'rolp250'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE salir		SMALLINT

CALL fl_nivel_isolation()
LET vm_proceso = 'IR'
CALL fl_lee_proceso_roles(vm_proceso) RETURNING rm_n03.*
IF rm_n03.n03_proceso IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configurado el proceso IMPUESTO A LA RENTA en la tabla rolt003.', 'stop')
	EXIT PROGRAM
END IF

OPEN WINDOW wf AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0, BORDER,
		MESSAGE LINE LAST)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_rol FROM "../forms/rolf250_1"
DISPLAY FORM f_rol

LET vm_max_rows    = 100
LET vm_maxelm      = 500
LET vm_row_current = 0
LET vm_num_rows    = 0

CALL mostrar_botones()
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_contadores_det(0, 0)

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Cerrar'
		HIDE OPTION 'Detalle'
	COMMAND KEY('G') 'Generar' 		'Genera los registros de IR.'
		IF vm_num_rows = vm_max_rows THEN
			CALL fl_mensaje_arreglo_lleno()
		ELSE
			CALL control_generar()
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Cerrar'
		END IF
		SHOW OPTION 'Detalle'
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
		IF rm_par.n84_estado = 'A' THEN
			SHOW OPTION 'Cerrar'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Detalle'
		END IF
	COMMAND KEY('C') 'Cerrar'		'Cierra IR para este a¤o.'
		CALL control_cerrar()
		HIDE OPTION 'Cerrar'
	COMMAND KEY('D') 'Detalle' 'Consulta el detalle del registro actual. '
		IF rm_par.n84_estado = 'A' THEN
			CALL muestra_trabajadores('E')
		ELSE
			CALL muestra_trabajadores('C')
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
		IF rm_par.n84_estado = 'A' THEN
			SHOW OPTION 'Cerrar'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Detalle'
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
		IF rm_par.n84_estado = 'A' THEN
			SHOW OPTION 'Cerrar'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Detalle'
		END IF
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

CLOSE WINDOW wf

END FUNCTION



FUNCTION control_generar()
DEFINE cuantos		SMALLINT
DEFINE resp		CHAR(6)
DEFINE r_n84		RECORD LIKE rolt084.*


CALL fl_lee_compania_roles(vg_codcia) RETURNING rm_cia.*
IF rm_cia.n01_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe compañía.','stop')
	EXIT PROGRAM
END IF

INITIALIZE rm_par.* TO NULL

LET rm_par.n84_ano_proceso    = rm_cia.n01_ano_proceso - 1 
LET rm_par.n84_estado = 'A'
LET rm_par.n_estado   = 'Activo'
DISPLAY BY NAME rm_par.*

SELECT COUNT(*) INTO cuantos
	FROM rolt015
	WHERE n15_compania = vg_codcia
	  AND n15_ano      = rm_par.n84_ano_proceso
IF cuantos = 0 THEN
	CALL fl_mostrar_mensaje('No existe configuracion de impuesto a la renta para este a¤o.', 'stop')
	RETURN
END IF

SELECT COUNT(*) FROM rolt084
	WHERE n84_compania = vg_codcia
	  AND n84_ano_proceso      = rm_par.n84_ano_proceso
	  AND n84_estado   = 'A'
IF cuantos > 0 THEN
	CALL fl_hacer_pregunta('Ya se ha generado impuesto a la renta para este a¤o, desea continuar y deshacer lo grabado anteriormente?.', 'No')
	RETURNING resp
	IF resp = 'No' THEN
		RETURN
	END IF
END IF

CALL carga_trabajadores()
IF int_flag = 1 THEN
	RETURN 
END IF

CALL muestra_trabajadores('E')
IF int_flag = 1 THEN
	RETURN 
END IF

BEGIN WORK
	CALL graba_registros()
COMMIT WORK
CALL fl_mostrar_mensaje('Proceso terminado OK', 'info')

RETURN 

END FUNCTION



FUNCTION mostrar_botones()
	
DISPLAY 'Nombre Trabajador'	TO bt_nomtrab
DISPLAY 'Ganado'		TO bt_ganado
DISPLAY 'Imp. Real'		TO bt_imp_real
DISPLAY 'Imp. Ret.'		TO bt_imp_ret
DISPLAY 'Diferencia'		TO bt_reten

END FUNCTION



FUNCTION carga_trabajadores()
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE tot_ing		LIKE rolt084.n84_ing_roles

SELECT * FROM rolt030
	WHERE n30_compania  = vg_codcia
	  AND n30_cod_trab IN (SELECT UNIQUE n32_cod_trab
				FROM rolt032
				WHERE n32_compania     = n30_compania
				  AND n32_ano_proceso  = rm_par.n84_ano_proceso
				  AND n32_estado      <> 'E')
	  AND n30_estado   <> 'J'
	INTO TEMP tmp_trab

CALL retorna_valores_trab()

DECLARE q_trab CURSOR FOR SELECT * FROM tmp_trab ORDER BY n30_nombres

LET vm_numelm = 1
FOREACH q_trab INTO r_n30.*
	LET vm_cod_trab[vm_numelm].cod_trab  = r_n30.n30_cod_trab
	LET rm_scr[vm_numelm].n30_nombres    = r_n30.n30_nombres
	LET vm_cod_trab[vm_numelm].moneda    = r_n30.n30_mon_sueldo
	LET vm_cod_trab[vm_numelm].estado    = 'A' 
	SELECT tot_gan, val_dt, val_dc, bonif, val_ut, val_vac, val_uv,
		val_ap + ap_vac, otros
		INTO vm_cod_trab[vm_numelm].ing_roles,
		vm_cod_trab[vm_numelm].dec_tercero,
		vm_cod_trab[vm_numelm].dec_cuarto,
		vm_cod_trab[vm_numelm].bonificacion,vm_cod_trab[vm_numelm].util,
		vm_cod_trab[vm_numelm].vacaciones,vm_cod_trab[vm_numelm].varios,
		vm_cod_trab[vm_numelm].iess, vm_cod_trab[vm_numelm].otros_ing
		FROM tmp_val
		WHERE cod = r_n30.n30_cod_trab
	SELECT * FROM rolt032
		WHERE n32_compania     = vg_codcia 
		  AND n32_cod_trab     = r_n30.n30_cod_trab
		  AND n32_estado      <> 'E'
		  AND n32_ano_proceso  = rm_par.n84_ano_proceso
		INTO TEMP tt
	SELECT NVL(SUM(n33_valor), 0) 
		INTO rm_scr[vm_numelm].n84_imp_ret
		FROM tt, rolt033, rolt006
		WHERE n33_compania   = n32_compania
		  AND n33_cod_liqrol = n32_cod_liqrol
		  AND n33_fecha_ini  = n32_fecha_ini 
		  AND n33_fecha_fin  = n32_fecha_fin 
		  AND n33_cod_trab   = n32_cod_trab
		  AND n06_cod_rubro  = n33_cod_rubro
		  AND n06_flag_ident = vm_proceso
	DROP TABLE tt		

	CALL retorna_tot_ing(vm_numelm) RETURNING tot_ing

	SELECT n15_base_imp_ini, n15_fracc_base, n15_porc_ir 
		INTO vm_cod_trab[vm_numelm].fracc_ini,
		     vm_cod_trab[vm_numelm].imp_base,
		     vm_cod_trab[vm_numelm].porc_exced
		FROM rolt015
		WHERE n15_compania = vg_codcia
		  AND n15_ano      = rm_par.n84_ano_proceso
		  AND tot_ing      BETWEEN n15_base_imp_ini AND n15_base_imp_fin

	IF vm_cod_trab[vm_numelm].fracc_ini IS NULL THEN
		CALL fl_mostrar_mensaje('No existe configuracion de impuesto a la renta.', 'stop')
		EXIT PROGRAM
	END IF

	LET rm_scr[vm_numelm].ganado = tot_ing

	LET rm_scr[vm_numelm].n84_imp_real = 
		vm_cod_trab[vm_numelm].imp_base +
		((tot_ing - vm_cod_trab[vm_numelm].fracc_ini) * 
			vm_cod_trab[vm_numelm].porc_exced / 100) 

	LET rm_scr[vm_numelm].retencion =
		rm_scr[vm_numelm].n84_imp_real - rm_scr[vm_numelm].n84_imp_ret

	LET vm_numelm = vm_numelm + 1
	IF vm_numelm > vm_maxelm THEN
		CALL fl_mensaje_arreglo_incompleto()
		EXIT PROGRAM
	END IF		
END FOREACH
DROP TABLE tmp_trab
LET vm_numelm = vm_numelm - 1

IF vm_numelm = 0 THEN
	CALL fl_mostrar_mensaje('No existen trabajadores activos.', 'stop')
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION retorna_valores_trab()
DEFINE fecha_ini	LIKE rolt032.n32_fecha_ini
DEFINE fecha_fin	LIKE rolt032.n32_fecha_fin

LET fecha_ini = MDY(rm_n03.n03_mes_ini, rm_n03.n03_dia_ini, rm_par.n84_ano_proceso)
LET fecha_fin = MDY(rm_n03.n03_mes_fin, rm_n03.n03_dia_fin, rm_par.n84_ano_proceso)
SELECT n33_cod_trab, SUM(n33_valor) val_otr
	FROM rolt033
	WHERE n33_compania    = vg_codcia
	  AND n33_cod_liqrol IN ("Q1", "Q2")
	  AND n33_fecha_ini  >= fecha_ini
	  AND n33_fecha_fin  <= fecha_fin
	  AND n33_cod_rubro  IN
		(SELECT n06_cod_rubro FROM rolt006
		WHERE n06_flag_ident NOT IN("DI", "SI")
		  AND n06_cod_rubro  <> 17)
	  AND n33_valor       > 0
	  AND n33_det_tot     = "DI"
	  AND n33_cant_valor  = "V"
	  AND NOT EXISTS
		(SELECT 1 FROM rolt008, rolt006
		 WHERE n08_rubro_base = n33_cod_rubro
		   AND n06_cod_rubro  = n08_cod_rubro
		   AND n06_flag_ident = "AP")
	GROUP BY 1
	INTO TEMP tmp_n33
SELECT LPAD(n30_cod_trab, 3, 0) cod, TRIM(n30_nombres) empleado,
	NVL(SUM(n32_tot_gan), 0) tot_gan,
	NVL(SUM(n32_tot_gan * n13_porc_trab / 100), 0) val_ap,
	NVL(SUM(n32_tot_gan - (n32_tot_gan * n13_porc_trab / 100)), 0) val_nom,
	NVL((SELECT val_otr
		FROM tmp_n33
		WHERE n33_cod_trab = n32_cod_trab), 0.00) otros,
	NVL((SELECT n39_valor_vaca + n39_valor_adic
		FROM rolt039
		WHERE n39_compania      = n30_compania
		  AND n39_proceso      IN ("VA", "VP")
		  AND n39_cod_trab      = n30_cod_trab
		  AND n39_estado        = "P"
		  AND DATE(n39_fecing) BETWEEN fecha_ini
					   AND fecha_fin), 0.00) val_vac,
	NVL((SELECT n39_descto_iess
		FROM rolt039
		WHERE n39_compania      = n30_compania
		  AND n39_proceso      IN ("VA", "VP")
		  AND n39_cod_trab      = n30_cod_trab
		  AND n39_estado        = "P"
		  AND DATE(n39_fecing) BETWEEN fecha_ini
					   AND fecha_fin), 0.00) ap_vac,
	NVL((SELECT (n39_valor_vaca + n39_valor_adic) - n39_descto_iess
		FROM rolt039
		WHERE n39_compania      = n30_compania
		  AND n39_proceso      IN ("VA", "VP")
		  AND n39_cod_trab      = n30_cod_trab
		  AND n39_estado        = "P"
		  AND DATE(n39_fecing) BETWEEN fecha_ini
					   AND fecha_fin), 0.00) net_vac,
	NVL((SELECT n36_valor_bruto
		FROM rolt036
		WHERE n36_compania    = n30_compania
		  AND n36_proceso     = "DT"
		  AND n36_ano_proceso = rm_par.n84_ano_proceso
		  AND n36_cod_trab    = n30_cod_trab
		  AND n36_estado      = "P"), 0) val_dt,
	NVL((SELECT n36_valor_bruto
		FROM rolt036
		WHERE n36_compania    = n30_compania
		  AND n36_proceso     = "DC"
		  AND n36_ano_proceso = rm_par.n84_ano_proceso
		  AND n36_cod_trab    = n30_cod_trab
		  AND n36_estado      = "P"), 0) val_dc,
	NVL((SELECT n42_val_trabaj + n42_val_cargas
		 FROM rolt041, rolt042
		 WHERE n41_compania      = n30_compania
		   AND n41_ano           = YEAR(fecha_fin) - 1
		   AND n41_estado        = "P"
		   AND n42_compania      = n41_compania
		   AND n42_ano           = n41_ano
		   AND n42_cod_trab      = n30_cod_trab), 0.00) val_ut,
	NVL((SELECT SUM(n44_valor)
			FROM rolt043, rolt044
			WHERE n43_compania = n30_compania
			  AND n43_estado   = 'P'
			  AND n44_compania = n43_compania
			  AND n44_num_rol  = n43_num_rol
			  AND n44_cod_trab = n30_cod_trab), 0) val_uv,
	NVL((SELECT n10_valor * NVL((MONTH(n10_fecha_fin) -
			MONTH(n10_fecha_ini)) + 1, 12)
		FROM rolt010
		WHERE n10_compania    = n30_compania
		  AND n10_cod_liqrol  = 'ME'
		  AND n10_cod_trab    = n30_cod_trab), 0) bonif
	FROM tmp_trab, rolt032, rolt013
	WHERE n32_compania     = n30_compania
	  AND n32_cod_liqrol  IN ("Q1", "Q2")
	  AND n32_cod_trab     = n30_cod_trab
	  AND n32_ano_proceso  = rm_par.n84_ano_proceso
	  AND n30_compania     = n32_compania
	  AND n30_cod_trab     = n32_cod_trab
	  AND n13_cod_seguro   = n30_cod_seguro
	GROUP BY 1, 2, 6, 7, 8, 9, 10, 11, 12, 13, 14
	INTO TEMP tmp_val
DROP TABLE tmp_n33

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
				    'para esta moneda',
				    'exclamation')
		INITIALIZE paridad TO NULL
	ELSE
		LET paridad = r_g14.g14_tasa 
	END IF
END IF

RETURN paridad

END FUNCTION



FUNCTION retorna_tot_ing(i)
DEFINE i		SMALLINT
DEFINE tot_ing		LIKE rolt084.n84_otros_ing

LET tot_ing = vm_cod_trab[i].ing_roles + vm_cod_trab[i].dec_tercero +
		vm_cod_trab[i].dec_cuarto + vm_cod_trab[i].bonificacion +
		vm_cod_trab[i].util + vm_cod_trab[i].vacaciones +
		vm_cod_trab[i].varios + vm_cod_trab[i].otros_ing -
		vm_cod_trab[i].iess
RETURN tot_ing

END FUNCTION



FUNCTION siguiente_registro()

IF vm_num_rows = 0 THEN
	RETURN
END IF

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
--CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION anterior_registro()

IF vm_num_rows = 0 THEN
	RETURN
END IF

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
--CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION muestra_trabajadores(flag_consul)
DEFINE flag_consul	CHAR(1)
DEFINE i, j		SMALLINT

CALL set_count(vm_numelm)
DISPLAY ARRAY rm_scr TO ra_scr.*
       	ON KEY(INTERRUPT)   
		LET int_flag = 1
       	        EXIT DISPLAY  
	ON KEY (F5)
		IF vm_cod_trab[i].estado = 'B' THEN
			CALL fl_mostrar_mensaje('A este empleado no se le calcula IR.', 'stop')
			CONTINUE DISPLAY
		END IF
		CALL ingresa_otros(i, flag_consul)
		DISPLAY rm_scr[i].* TO ra_scr[j].*
		CALL mostrar_totales()
		LET int_flag = 0
	ON KEY (F6)
		CALL control_bloqueo_activacion(i)
		CALL mostrar_totales()
		DISPLAY  0, 0, 0 TO ra_scr[j].imp_real,
				    ra_scr[j].imp_ret,
				    ra_scr[j].reten
		LET int_flag = 0
	BEFORE DISPLAY
		CALL dialog.keysetlabel('F5', 'Desgloce Ing.')
		CALL mostrar_totales()
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
		CALL muestra_contadores_det(i, vm_numelm)
		IF flag_consul = 'E' THEN
			IF vm_cod_trab[i].estado = 'A' THEN
				CALL dialog.keysetlabel('F6', 'Bloquear')
			ELSE
				CALL dialog.keysetlabel('F6', 'Activar')
			END IF
		ELSE
			CALL dialog.keysetlabel('F6', '')
		END IF
END DISPLAY
CALL muestra_contadores_det(0, vm_numelm)

END FUNCTION



FUNCTION ingresa_otros(curr, flag)
DEFINE curr		SMALLINT
DEFINE flag		CHAR(1)
DEFINE n84_bonificacion	LIKE rolt084.n84_bonificacion
DEFINE n84_otros_ing	LIKE rolt084.n84_otros_ing
DEFINE tot_ing		LIKE rolt084.n84_otros_ing
DEFINE tecla		INTEGER

OPEN WINDOW wf2 AT 05,10 WITH 18 ROWS, 65 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE LAST ,BORDER,
     		MESSAGE LINE LAST)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_rol_2 FROM "../forms/rolf250_2"
DISPLAY FORM f_rol_2
LET n84_bonificacion = vm_cod_trab[curr].bonificacion
LET n84_otros_ing    = vm_cod_trab[curr].otros_ing
CALL retorna_tot_ing(curr) RETURNING tot_ing
DISPLAY BY NAME rm_par.n84_ano_proceso, rm_par.n84_estado, rm_par.n_estado,
		vm_cod_trab[curr].cod_trab, rm_scr[curr].n30_nombres,
		vm_cod_trab[curr].ing_roles, vm_cod_trab[curr].varios,
		vm_cod_trab[curr].dec_tercero, vm_cod_trab[curr].dec_cuarto,
		vm_cod_trab[curr].util, vm_cod_trab[curr].vacaciones,
		vm_cod_trab[curr].iess, tot_ing, n84_bonificacion, n84_otros_ing
IF rm_par.n84_estado = 'P' AND flag = 'C' THEN
	MESSAGE "Presione una tecla para continuar "
	LET tecla    = fgl_getkey()
	LET int_flag = 0
	CLOSE WINDOW wf2
	RETURN
END IF
LET int_flag = 0
INPUT BY NAME n84_bonificacion, n84_otros_ing
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	AFTER FIELD n84_bonificacion, n84_otros_ing
		IF n84_otros_ing < 0 OR n84_bonificacion < 0 THEN
			CALL fl_mostrar_mensaje('El campo no puede ser negativo.', 'stop')
			CONTINUE INPUT
		END IF
		LET vm_cod_trab[curr].otros_ing    = n84_otros_ing
		LET vm_cod_trab[curr].bonificacion = n84_bonificacion
		CALL retorna_tot_ing(curr) RETURNING tot_ing
		DISPLAY BY NAME tot_ing
		SELECT n15_base_imp_ini, n15_fracc_base, n15_porc_ir 
			INTO vm_cod_trab[curr].fracc_ini,
			     vm_cod_trab[curr].imp_base,
			     vm_cod_trab[curr].porc_exced
			FROM rolt015
			WHERE n15_compania = vg_codcia
			  AND n15_ano      = rm_par.n84_ano_proceso
			  AND tot_ing      BETWEEN n15_base_imp_ini
					       AND n15_base_imp_fin 
		IF vm_cod_trab[curr].fracc_ini IS NULL THEN
			CALL fl_mostrar_mensaje('No existe configuracion de impuesto a la renta.', 'stop')
			EXIT PROGRAM
		END IF
		LET rm_scr[curr].ganado = tot_ing
		LET rm_scr[curr].n84_imp_real = 
			vm_cod_trab[curr].imp_base +
			((tot_ing - vm_cod_trab[curr].fracc_ini) * 
			vm_cod_trab[curr].porc_exced / 100) 
		LET rm_scr[curr].retencion =
			rm_scr[curr].n84_imp_real - rm_scr[curr].n84_imp_ret
END INPUT

CLOSE WINDOW wf2

END FUNCTION



FUNCTION control_consulta()
DEFINE query		VARCHAR(400)
DEFINE expr_sql		VARCHAR(400)
DEFINE num_reg		INTEGER

INITIALIZE rm_par.* TO NULL
LET int_flag = 0
CLEAR FORM
CALL mostrar_botones()
CONSTRUCT BY NAME expr_sql ON n84_ano_proceso, n84_estado 
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

LET query = 'SELECT n84_ano_proceso FROM rolt084 ' ||
	    '	WHERE n84_compania = ' || vg_codcia ||
            '     AND ' || expr_sql || 
            ' GROUP BY n84_ano_proceso ORDER BY n84_ano_proceso DESC'

PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1 
FOREACH q_cons INTO vm_rows[vm_num_rows]
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
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE num_registro	INTEGER

DEFINE r_n84		RECORD LIKE rolt084.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF

LET rm_par.n84_ano_proceso = vm_rows[vm_row_current]

DECLARE q_tc CURSOR FOR 
	SELECT rolt084.*, n30_nombres
		FROM rolt084, rolt030
		WHERE n84_compania    = vg_codcia
		  AND n84_ano_proceso = rm_par.n84_ano_proceso 
		  AND n30_compania    = n84_compania
		  AND n30_cod_trab    = n84_cod_trab
		ORDER BY n30_nombres

LET rm_par.n84_estado = 'P'
LET vm_numelm = 1
FOREACH q_tc INTO r_n84.*, rm_scr[vm_numelm].n30_nombres
	LET vm_cod_trab[vm_numelm].cod_trab    = r_n84.n84_cod_trab
	LET vm_cod_trab[vm_numelm].estado      = r_n84.n84_estado
	LET vm_cod_trab[vm_numelm].moneda      = r_n84.n84_moneda
	LET vm_cod_trab[vm_numelm].fracc_ini   = r_n84.n84_fracc_ini
	LET vm_cod_trab[vm_numelm].ing_roles   = r_n84.n84_ing_roles
	LET vm_cod_trab[vm_numelm].dec_tercero = r_n84.n84_dec_tercero
	LET vm_cod_trab[vm_numelm].dec_cuarto  = r_n84.n84_dec_cuarto
	LET vm_cod_trab[vm_numelm].vacaciones  = r_n84.n84_vacaciones
	LET vm_cod_trab[vm_numelm].varios      = r_n84.n84_roles_varios
	LET vm_cod_trab[vm_numelm].bonificacion= r_n84.n84_bonificacion
	LET vm_cod_trab[vm_numelm].util        = r_n84.n84_utilidades
	LET vm_cod_trab[vm_numelm].iess        = r_n84.n84_aporte_iess
	LET vm_cod_trab[vm_numelm].otros_ing   = r_n84.n84_otros_ing
	LET vm_cod_trab[vm_numelm].imp_base    = r_n84.n84_imp_basico
	LET vm_cod_trab[vm_numelm].porc_exced  = r_n84.n84_porc_exced

	CALL retorna_tot_ing(vm_numelm) RETURNING rm_scr[vm_numelm].ganado

	LET rm_scr[vm_numelm].n84_imp_real     = r_n84.n84_imp_real
	LET rm_scr[vm_numelm].n84_imp_ret      = r_n84.n84_imp_ret
	LET rm_scr[vm_numelm].retencion        = r_n84.n84_imp_real - 
                                                 r_n84.n84_imp_ret

	IF vm_cod_trab[vm_numelm].estado = 'B' THEN
		LET rm_scr[vm_numelm].n84_imp_real = 0
		LET rm_scr[vm_numelm].n84_imp_ret  = 0
		LET rm_scr[vm_numelm].retencion    = 0
	END IF

	IF r_n84.n84_estado = 'A' THEN
		LET rm_par.n84_estado = 'A'
	END IF

	LET vm_numelm = vm_numelm + 1
	IF vm_numelm = vm_maxelm THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_numelm = vm_numelm - 1

IF rm_par.n84_estado = 'A' THEN
	LET rm_par.n_estado = 'ACTIVO'
ELSE
	LET rm_par.n_estado = 'PROCESADO'
END IF
DISPLAY BY NAME rm_par.*

IF vm_numelm = 0 THEN
	CALL fl_mostrar_mensaje('No existe registro con para el a¤o: ' || rm_par.n84_ano_proceso,'exclamation')
	RETURN
END IF
	
CALL muestra_trabajadores('C')

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current	SMALLINT
DEFINE num_rows		SMALLINT
                                                                                
DISPLAY "" AT 1,1
DISPLAY row_current, " de ", num_rows AT 1, 69
                                                                                
END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION mostrar_totales()
DEFINE i		SMALLINT
DEFINE tot_ganado	LIKE rolt084.n84_otros_ing
DEFINE tot_imp_real	LIKE rolt084.n84_otros_ing
DEFINE tot_imp_ret 	LIKE rolt084.n84_otros_ing
DEFINE tot_reten	LIKE rolt084.n84_otros_ing

LET tot_ganado   = 0
LET tot_imp_real = 0
LET tot_imp_ret  = 0
LET tot_reten    = 0
FOR i = 1 TO vm_numelm
	LET tot_ganado   = tot_ganado + rm_scr[i].ganado 
	LET tot_imp_real = tot_imp_real + rm_scr[i].n84_imp_real 
	LET tot_imp_ret  = tot_imp_ret + rm_scr[i].n84_imp_ret 
	LET tot_reten    = tot_reten + rm_scr[i].retencion 
END FOR

DISPLAY BY NAME tot_ganado, tot_imp_real, tot_imp_ret, tot_reten

END FUNCTION



FUNCTION graba_registros()
DEFINE i	SMALLINT
DEFINE r_n84	RECORD LIKE rolt084.*

DELETE FROM rolt084 WHERE n84_compania = vg_codcia AND n84_ano_proceso = rm_par.n84_ano_proceso

FOR i = 1 TO vm_numelm
	INITIALIZE r_n84.* TO NULL
	LET r_n84.n84_compania     = vg_codcia
	LET r_n84.n84_proceso      = vm_proceso
	LET r_n84.n84_cod_trab     = vm_cod_trab[i].cod_trab
	LET r_n84.n84_ano_proceso  = rm_par.n84_ano_proceso	
	LET r_n84.n84_estado       = vm_cod_trab[i].estado
	LET r_n84.n84_moneda       = vm_cod_trab[i].moneda
	LET r_n84.n84_paridad      = calcula_paridad(vm_cod_trab[i].moneda, 
						 rg_gen.g00_moneda_base)
	LET r_n84.n84_fracc_ini    = vm_cod_trab[i].fracc_ini
	LET r_n84.n84_ing_roles    = vm_cod_trab[i].ing_roles
	LET r_n84.n84_dec_cuarto   = vm_cod_trab[i].dec_cuarto
	LET r_n84.n84_dec_tercero  = vm_cod_trab[i].dec_tercero
	LET r_n84.n84_roles_varios = vm_cod_trab[i].varios
	LET r_n84.n84_bonificacion = vm_cod_trab[i].bonificacion
	LET r_n84.n84_utilidades   = vm_cod_trab[i].util
	LET r_n84.n84_vacaciones   = vm_cod_trab[i].vacaciones
	LET r_n84.n84_aporte_iess  = vm_cod_trab[i].iess
	LET r_n84.n84_otros_ing    = vm_cod_trab[i].otros_ing
	LET r_n84.n84_imp_basico   = vm_cod_trab[i].imp_base
	LET r_n84.n84_porc_exced   = vm_cod_trab[i].porc_exced
	LET r_n84.n84_imp_real     = rm_scr[i].n84_imp_real
	LET r_n84.n84_imp_ret      = rm_scr[i].n84_imp_ret 
	LET r_n84.n84_usuario      = vg_usuario
	LET r_n84.n84_fecing       = CURRENT
	CALL retorna_tot_ing(i) RETURNING r_n84.n84_total_gan
	INSERT INTO rolt084 VALUES (r_n84.*)
END FOR

END FUNCTION



FUNCTION control_bloqueo_activacion(fila)
DEFINE fila	SMALLINT
DEFINE resp    	CHAR(6)
DEFINE estado	CHAR(1)

LET int_flag = 0
IF vm_numelm <= 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

CALL fl_mensaje_seguro_ejecutar_proceso()
	RETURNING resp
IF resp = 'Yes' THEN


	LET estado = 'B'
	IF vm_cod_trab[fila].estado <> 'A' THEN
		LET estado = 'A'
	END IF
	LET vm_cod_trab[fila].estado = estado

	CALL fl_mensaje_registro_modificado()
END IF

END FUNCTION



FUNCTION control_cerrar()

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
BEGIN WORK
	UPDATE rolt084
		SET n84_estado     = 'P',
		    n84_usu_modifi = vg_usuario,
		    n84_fec_modifi = CURRENT
		WHERE n84_compania    = vg_codcia
		  AND n84_ano_proceso = rm_par.n84_ano_proceso
		  AND n84_estado      = 'A'
COMMIT WORK

END FUNCTION
