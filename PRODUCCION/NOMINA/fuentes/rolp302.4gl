--------------------------------------------------------------------------------
-- Titulo           : rolp302.4gl - Consulta de Genérica de Empleados
-- Elaboracion      : 05-Sep-2003
-- Autor            : NPC
-- Formato Ejecucion: fglrun rolp302 base modulo compañía
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_det	SMALLINT
DEFINE vm_num_det	SMALLINT
DEFINE i_cor		SMALLINT
DEFINE vm_max_elmt      SMALLINT
DEFINE vm_num_elmt      SMALLINT
DEFINE vm_r_rows	ARRAY[500] OF INTEGER
DEFINE rm_detalle	ARRAY[500] OF RECORD
				n30_cod_trab	LIKE rolt030.n30_cod_trab,
				n30_nombres	LIKE rolt030.n30_nombres,
				g35_nombre	LIKE gent035.g35_nombre,
				n30_sueldo_mes	LIKE rolt030.n30_sueldo_mes,
				n30_estado	LIKE rolt030.n30_estado
			END RECORD
DEFINE rm_det_tot	ARRAY[500] OF RECORD
				n32_cod_liqrol	LIKE rolt032.n32_cod_liqrol,
				n32_fecha_ini	LIKE rolt032.n32_fecha_ini,
				n32_fecha_fin	LIKE rolt032.n32_fecha_fin,
				n32_tot_gan	LIKE rolt032.n32_tot_gan,
				total_ing	DECIMAL(14,2),
				total_egr	DECIMAL(14,2),
				total_net	DECIMAL(14,2)
			END RECORD
DEFINE rm_det_tot2	ARRAY[500] OF RECORD
				n32_ano_proceso	LIKE rolt032.n32_ano_proceso,
				nom_mes		VARCHAR(10),
				n32_sueldo	LIKE rolt032.n32_sueldo,
				n32_tot_gan	LIKE rolt032.n32_tot_gan,
				total_ing	DECIMAL(14,2),
				total_egr	DECIMAL(14,2),
				total_net	DECIMAL(14,2)
			END RECORD
DEFINE rm_dettot	ARRAY[20] OF RECORD
				tot_cod		CHAR(2),
				tot_des		LIKE rolt003.n03_nombre,
				tot_val		DECIMAL(12,2)
			END RECORD
DEFINE vm_num_tot	SMALLINT
DEFINE vm_max_tot	SMALLINT
DEFINE rm_detfon	ARRAY[50] OF RECORD
				fon_fecha	DATETIME YEAR TO MONTH,
				fon_gana	LIKE rolt038.n38_ganado_per,
				fon_neto	LIKE rolt038.n38_valor_fondo
			END RECORD
DEFINE vm_num_fon	SMALLINT
DEFINE vm_max_fon	SMALLINT
DEFINE rm_detdec	ARRAY[100] OF RECORD
				dec_anio	LIKE rolt036.n36_ano_proceso,
				dec_cod		LIKE rolt036.n36_proceso,
				dec_des		LIKE rolt003.n03_nombre_abr,
				dec_gana	LIKE rolt036.n36_ganado_real,
				dec_brut	LIKE rolt036.n36_valor_bruto,
				dec_desc	LIKE rolt036.n36_descuentos,
				dec_neto	LIKE rolt036.n36_valor_neto
			END RECORD
DEFINE vm_num_dec	SMALLINT
DEFINE vm_max_dec	SMALLINT
DEFINE rm_detvac	ARRAY[50] OF RECORD
				vac_anio	LIKE rolt039.n39_ano_proceso,
				vac_dvac	LIKE rolt039.n39_dias_vac,
				vac_dadi	LIKE rolt039.n39_dias_adi,
				vac_dtot	SMALLINT,
				vac_dgoz	LIKE rolt039.n39_dias_goza,
				vac_dpen	SMALLINT,
				vac_gana	LIKE rolt039.n39_tot_ganado,
				vac_brut	LIKE rolt039.n39_valor_vaca,
				vac_desc	LIKE rolt039.n39_descto_iess,
				vac_neto	LIKE rolt039.n39_neto
			END RECORD
DEFINE vm_num_vac	SMALLINT
DEFINE vm_max_vac	SMALLINT
DEFINE rm_totales	RECORD
				total01		DECIMAL(12,2),
				total02		DECIMAL(12,2),
				total03		DECIMAL(12,2),
				total04		DECIMAL(12,2),
				total05		DECIMAL(12,2),
				total06		DECIMAL(12,2),
				total07		DECIMAL(12,2),
				total08		DECIMAL(12,2),
				total09		DECIMAL(12,2),
				total10		DECIMAL(12,2),
				total11		DECIMAL(12,2)
			END RECORD
DEFINE rm_toting	ARRAY[100] OF RECORD
				codrub_h	LIKE rolt033.n33_cod_rubro,
				nomrub_h	LIKE rolt006.n06_nombre_abr,
				valaux_h	LIKE rolt033.n33_horas_porc,
				valrub_h	DECIMAL(14,2)
			END RECORD
DEFINE rm_totdes	ARRAY[100] OF RECORD
				codrub_d	LIKE rolt033.n33_cod_rubro,
				nomrub_d	LIKE rolt006.n06_nombre_abr,
				valrub_d	DECIMAL(14,2)
			END RECORD
DEFINE rm_totrub	ARRAY[500] OF RECORD
				n32_cod_liqrol	LIKE rolt032.n32_cod_liqrol,
				n33_fecha_ini	LIKE rolt033.n33_fecha_ini,
				n33_fecha_fin	LIKE rolt033.n33_fecha_fin,
				n33_horas_porc	LIKE rolt033.n33_horas_porc,
				n33_valor	LIKE rolt033.n33_valor
			END RECORD
DEFINE rm_totrub2	ARRAY[500] OF RECORD
				cod_depto	LIKE rolt032.n32_cod_depto,
				n32_cod_trab	LIKE rolt032.n32_cod_trab,
				n30_nombres	LIKE rolt030.n30_nombres,
				n33_horas_porc	LIKE rolt033.n33_horas_porc,
				n33_valor	LIKE rolt033.n33_valor
			END RECORD
DEFINE rm_n00		RECORD LIKE rolt000.*
DEFINE rm_n30		RECORD LIKE rolt030.*
DEFINE rm_n32		RECORD LIKE rolt032.*
DEFINE rm_n45		RECORD LIKE rolt045.*
DEFINE rm_n46		RECORD LIKE rolt046.*
DEFINE rm_n90		RECORD LIKE rolt090.*
DEFINE vm_codliq_ini	LIKE rolt032.n32_cod_liqrol
DEFINE vm_codliq_fin	LIKE rolt032.n32_cod_liqrol
DEFINE vm_anio_ini	SMALLINT
DEFINE vm_anio_fin	SMALLINT
DEFINE vm_mes_ini	SMALLINT
DEFINE vm_mes_fin	SMALLINT
DEFINE tit_mes_ini	VARCHAR(10)
DEFINE tit_mes_fin	VARCHAR(10)
DEFINE vm_agrupado	CHAR(1)
DEFINE vm_consulta	CHAR(1)
DEFINE total_sueldo	DECIMAL(14,2)
DEFINE total_tot_gan	DECIMAL(14,2)
DEFINE total_ing_gen	DECIMAL(14,2)
DEFINE total_egr_gen	DECIMAL(14,2)
DEFINE total_net_gen	DECIMAL(14,2)
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_tipo_otro	CHAR(1)
DEFINE ver_tot_gan	CHAR(1)



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp302.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 8 THEN	-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp302'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 22
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_rolf302_1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rolf302_1 FROM '../forms/rolf302_1'
ELSE
	OPEN FORM f_rolf302_1 FROM '../forms/rolf302_1c'
END IF
DISPLAY FORM f_rolf302_1
LET vm_max_det  = 500
LET vm_max_elmt = 500
INITIALIZE rm_n30.* TO NULL
CALL fl_lee_parametro_general_roles() RETURNING rm_n00.*
IF rm_n00.n00_serial IS NULL THEN
        CALL fl_mostrar_mensaje('No existe configuración general para este módulo.', 'stop')
	LET int_flag = 0
	CLOSE WINDOW w_rolf302_1
	EXIT PROGRAM
END IF
CALL fl_lee_conf_adic_rol(vg_codcia) RETURNING rm_n90.*
IF rm_n90.n90_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configuracion adicional de nomina en la tabla rolt090.', 'stop')
	LET int_flag = 0
	CLOSE WINDOW w_rolf302_1
	EXIT PROGRAM
END IF
LET rm_n30.n30_estado     = 'A'
LET rm_n30.n30_mon_sueldo = rm_n00.n00_moneda_pago
LET vm_tipo_otro          = 'T'
LET ver_tot_gan           = 'N'
IF num_args() <> 3 THEN
	CALL llamada_otro_programa()
	LET int_flag = 0
	CLOSE WINDOW w_rolf302_1
	EXIT PROGRAM
END IF
CREATE TEMP TABLE temp_detalle(
		cod_depto		SMALLINT,
		n30_cod_trab		INTEGER,
		n30_nombres		VARCHAR(45,25),
		g35_nombre		VARCHAR(30,15),
		n30_sueldo_mes		DECIMAL(14,2),
		n30_estado		CHAR(1)
	)
WHILE TRUE
	CLEAR FORM
	CALL mostrar_botones_detalle1()
	CALL datos_defaults()
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL control_consulta()
END WHILE
DROP TABLE temp_detalle
LET int_flag = 0
CLOSE WINDOW w_rolf302_1
EXIT PROGRAM

END FUNCTION



FUNCTION llamada_otro_programa()
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE fec_ini, fec_fin	DATE

LET fec_ini     = arg_val(4)
LET fec_fin     = arg_val(5)
LET vm_anio_ini = YEAR(fec_ini)
LET vm_mes_ini  = MONTH(fec_ini)
LET vm_anio_fin = YEAR(fec_fin)
LET vm_mes_fin  = MONTH(fec_fin)
CASE arg_val(6)
	WHEN 'T' LET rm_detalle[1].n30_cod_trab = arg_val(7)
		 CALL fl_lee_trabajador_roles(vg_codcia,
						rm_detalle[1].n30_cod_trab)
			RETURNING r_n30.*
		 LET rm_detalle[1].n30_nombres  = r_n30.n30_nombres
	WHEN 'D' LET rm_n32.n32_cod_depto       = arg_val(7)
		 LET rm_detalle[1].n30_cod_trab = NULL
		 LET rm_detalle[1].n30_nombres  = '** TODOS LOS EMPLEADOS **'
	WHEN 'X' LET rm_detalle[1].n30_cod_trab = NULL
		 LET rm_detalle[1].n30_nombres  = '** TODOS LOS EMPLEADOS **'
		 LET rm_n32.n32_cod_depto       = NULL
END CASE
CASE arg_val(8)
	WHEN 'TM' CALL control_totales_liq02(1)
	WHEN 'TR' CALL muestra_totales_rub(1, 1, fec_ini, fec_fin)
	WHEN 'RM' CALL muestra_totales_rub(1, 2, fec_ini, fec_fin)
	WHEN 'TT' CALL control_totales_liq02(1)
END CASE

END FUNCTION



FUNCTION datos_defaults()
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_g34		RECORD LIKE gent034.*

LET vm_num_rows    = 0
LET vm_row_current = 0
LET vm_num_det     = 0
CALL fl_lee_moneda(rm_n30.n30_mon_sueldo) RETURNING r_g13.*
IF r_g13.g13_moneda IS NULL THEN
        CALL fgl_winmessage(vg_producto,'No existe ninguna moneda base.','stop')
        EXIT PROGRAM
END IF
DISPLAY BY NAME r_g13.g13_nombre
CALL fl_lee_departamento(vg_codcia, rm_n30.n30_cod_depto) RETURNING r_g34.*
DISPLAY BY NAME r_g34.g34_nombre

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_g34		RECORD LIKE gent034.*

LET int_flag = 0
INPUT BY NAME rm_n30.n30_cod_depto, rm_n30.n30_estado, rm_n30.n30_mon_sueldo,
	ver_tot_gan
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	ON KEY(F2)
		IF INFIELD(n30_cod_depto) THEN
                        CALL fl_ayuda_departamentos(vg_codcia)
                                RETURNING r_g34.g34_cod_depto, r_g34.g34_nombre
                        IF r_g34.g34_cod_depto IS NOT NULL THEN
				LET rm_n30.n30_cod_depto = r_g34.g34_cod_depto
                                DISPLAY BY NAME rm_n30.n30_cod_depto,
						r_g34.g34_nombre
                        END IF
                END IF
		IF INFIELD(n30_mon_sueldo) THEN
                	CALL fl_ayuda_monedas()
				RETURNING r_g13.g13_moneda, r_g13.g13_nombre,
					  r_g13.g13_decimales
                	IF r_g13.g13_moneda IS NOT NULL THEN
				LET rm_n30.n30_mon_sueldo = r_g13.g13_moneda
                        	DISPLAY BY NAME rm_n30.n30_mon_sueldo,
						r_g13.g13_nombre
                	END IF
		END IF
               	LET int_flag = 0
	AFTER FIELD n30_cod_depto
                IF rm_n30.n30_cod_depto IS NOT NULL THEN
                        CALL fl_lee_departamento(vg_codcia,rm_n30.n30_cod_depto)
                                RETURNING r_g34.*
                        IF r_g34.g34_compania IS NULL  THEN
                                CALL fgl_winmessage(vg_producto, 'Departamento no existe.','exclamation')
                                NEXT FIELD n30_cod_depto
                        END IF
                        DISPLAY BY NAME r_g34.g34_nombre
		ELSE
			CLEAR g34_nombre
                END IF
	AFTER FIELD n30_mon_sueldo
                IF rm_n30.n30_mon_sueldo IS NOT NULL THEN
                        CALL fl_lee_moneda(rm_n30.n30_mon_sueldo)
				RETURNING r_g13.*
                        IF r_g13.g13_moneda IS NULL  THEN
                                CALL fl_mostrar_mensaje('Moneda no existe.','exclamation')
                                NEXT FIELD n30_mon_sueldo
                        END IF
                        DISPLAY BY NAME r_g13.g13_nombre
                        IF r_g13.g13_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD n30_mon_sueldo
                        END IF
                ELSE
			LET rm_n30.n30_mon_sueldo = rm_n00.n00_moneda_pago
                        DISPLAY BY NAME rm_n30.n30_mon_sueldo
                        CALL fl_lee_moneda(rm_n30.n30_mon_sueldo)
				RETURNING r_g13.*
                        DISPLAY BY NAME r_g13.g13_nombre
                END IF
END INPUT

END FUNCTION



FUNCTION control_consulta()
DEFINE col, i	 	SMALLINT

IF preparar_query1() THEN
	RETURN
END IF
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET col           = 2
LET vm_columna_1  = col
LET vm_columna_2  = 4
LET rm_orden[col] = 'ASC'
WHILE TRUE
	CALL cargar_det_tmp()
	CALL mostrar_detalle()
	IF int_flag THEN
		EXIT WHILE
	END IF
END WHILE
DELETE FROM temp_detalle
RETURN

END FUNCTION



FUNCTION mostrar_detalle()
DEFINE i, j, col	SMALLINT
DEFINE resp		CHAR(6)

CALL mostrar_totales_sueldo()
LET int_flag = 0
CALL set_count(vm_num_det)
DISPLAY ARRAY rm_detalle TO rm_detalle.*
       	ON KEY(INTERRUPT)   
		LET int_flag = 1
       	        EXIT DISPLAY  
	ON KEY(F5)
		LET i = arr_curr()	
		CALL mostrar_empleado(rm_detalle[i].n30_cod_trab)
		LET int_flag = 0
	ON KEY(F6)
		LET i = arr_curr()	
		LET int_flag = 0
		CALL fl_hacer_pregunta("Desea ver TOTAL GANADO del empleado por Quincenas ?", "Yes")
			RETURNING resp
		IF resp = "Yes" THEN
			CALL control_totales_liq01(i)
		ELSE
			CALL control_totales_liq02(i)
		END IF
		LET int_flag = 0
	ON KEY(F7)
		LET i = arr_curr()	
		CALL control_anticipos(i)
		LET int_flag = 0
	ON KEY(F8)
		LET i = arr_curr()	
		CALL control_liquidaciones()
		LET int_flag = 0
	ON KEY(F9)
		LET i = arr_curr()	
		CALL control_otros_valores(i)
		LET int_flag = 0
	ON KEY(F10)
		CALL control_totales_rub(i)
		LET int_flag = 0
	ON KEY(F11)
		CALL control_imprimir_empleados()
		LET int_flag = 0
	ON KEY(F15)
		LET col = 1
		EXIT DISPLAY
	ON KEY(F16)
		LET col = 2
		EXIT DISPLAY
	ON KEY(F17)
		LET col = 3
		EXIT DISPLAY
	ON KEY(F18)
		LET col = 4
		EXIT DISPLAY
	ON KEY(F19)
		LET col = 5
		EXIT DISPLAY
	--#BEFORE DISPLAY 
		--#CALL dialog.keysetlabel('ACCEPT', '')   
		--#CALL dialog.keysetlabel('RETURN', '')   
		--#CALL dialog.keysetlabel("F1","") 
		--#CALL dialog.keysetlabel("CONTROL-W","") 
	--#BEFORE ROW 
		--#LET i = arr_curr()	
		--#LET j = scr_line()
		--#CALL muestra_contadores_detalle(i, vm_num_det)
        --#AFTER DISPLAY  
                --#CONTINUE DISPLAY  
END DISPLAY
IF int_flag = 1 THEN
	RETURN
END IF
IF col <> vm_columna_1 THEN
	LET vm_columna_2           = vm_columna_1 
	LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
	LET vm_columna_1           = col 
END IF
IF rm_orden[vm_columna_1] = 'ASC' THEN
	LET rm_orden[vm_columna_1] = 'DESC'
ELSE
	LET rm_orden[vm_columna_1] = 'ASC'
END IF

END FUNCTION



FUNCTION control_totales_liq01(i)
DEFINE i		SMALLINT
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE fec_min		LIKE rolt032.n32_fecha_ini
DEFINE fec_max		LIKE rolt032.n32_fecha_fin

LET lin_menu = 0
LET row_ini  = 4
LET num_rows = 20
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_rolf302_2 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rolf302_2 FROM '../forms/rolf302_2'
ELSE
	OPEN FORM f_rolf302_2 FROM '../forms/rolf302_2c'
END IF
DISPLAY FORM f_rolf302_2
CALL mostrar_botones_detalle2()
CALL datos_defaults2(i, 1)
CALL retorna_fec_min_trab(i) RETURNING fec_min
CALL retorna_fec_max_trab(i) RETURNING fec_max
WHILE TRUE
	CALL borrar_detalle(1)
	DISPLAY rm_detalle[i].n30_sueldo_mes TO n32_sueldo
	CALL lee_parametros2(fec_min, fec_max)
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL control_consulta2(i)
	IF int_flag THEN
		EXIT WHILE
	END IF
END WHILE
LET int_flag = 0
CLOSE WINDOW w_rolf302_2
RETURN

END FUNCTION



FUNCTION control_totales_liq02(i)
DEFINE i		SMALLINT
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE fec_min		LIKE rolt032.n32_fecha_ini
DEFINE fec_max		LIKE rolt032.n32_fecha_fin

LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 22
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_rolf302_10 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rolf302_10 FROM '../forms/rolf302_10'
ELSE
	OPEN FORM f_rolf302_10 FROM '../forms/rolf302_10c'
END IF
DISPLAY FORM f_rolf302_10
CALL mostrar_botones_detalle4()
CALL datos_defaults2(i, 2)
CALL retorna_fec_min_trab(i) RETURNING fec_min
CALL retorna_fec_max_trab(i) RETURNING fec_max
WHILE TRUE
	CALL borrar_detalle(2)
	IF num_args() = 3 THEN
		CALL lee_parametros2(fec_min, fec_max)
		IF int_flag THEN
			EXIT WHILE
		END IF
	END IF
	CALL control_consulta3(i)
	IF int_flag THEN
		EXIT WHILE
	END IF
END WHILE
LET int_flag = 0
CLOSE WINDOW w_rolf302_10
RETURN

END FUNCTION



FUNCTION control_anticipos(i)
DEFINE i		SMALLINT
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE param		VARCHAR(60)
DEFINE r_n30		RECORD LIKE rolt030.*

LET lin_menu = 0
LET row_ini  = 08
LET num_rows = 09
LET num_cols = 70
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 65
END IF
OPEN WINDOW w_rol3 AT row_ini, 06 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rolf302_3 FROM '../forms/rolf302_3'
ELSE
	OPEN FORM f_rolf302_3 FROM '../forms/rolf302_3c'
END IF
DISPLAY FORM f_rolf302_3
INITIALIZE rm_n45.*, rm_n46.* TO NULL
LET rm_n45.n45_cod_trab  = rm_detalle[i].n30_cod_trab
CALL fl_lee_trabajador_roles(vg_codcia, rm_n45.n45_cod_trab) RETURNING r_n30.*
DISPLAY BY NAME	rm_n45.n45_cod_trab, r_n30.n30_nombres
LET rm_n45.n45_estado    = 'V'
CALL muestra_estado_par()
--LET rm_n46.n46_fecha_ini = MDY(01, 01, YEAR(TODAY))
SELECT NVL(MIN(DATE(n45_fecing)), TODAY)
	INTO rm_n46.n46_fecha_ini
	FROM rolt045
	WHERE n45_compania  = vg_codcia
	  AND n45_cod_trab  = rm_n45.n45_cod_trab
	  AND n45_estado   IN ("A", "R")
LET rm_n46.n46_fecha_fin = TODAY
WHILE TRUE
	CALL leer_parametros_ant()
	IF int_flag THEN
		EXIT WHILE
	END IF
	LET param = ' "', rm_n45.n45_estado, '" "', rm_n46.n46_fecha_ini, '" ',
			'"', rm_n46.n46_fecha_fin, '" ', rm_n45.n45_cod_trab
	CALL ejecuta_comando('NOMINA', vg_modulo, 'rolp304 ', param)
END WHILE
CLOSE WINDOW w_rol3

END FUNCTION



FUNCTION control_liquidaciones()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE param		VARCHAR(60)

LET lin_menu = 0
LET row_ini  = 06
LET num_rows = 16
LET num_cols = 54
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 55
END IF
OPEN WINDOW w_rol4 AT row_ini, 14 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rolf302_4 FROM '../forms/rolf302_4'
ELSE
	OPEN FORM f_rolf302_4 FROM '../forms/rolf302_4c'
END IF
DISPLAY FORM f_rolf302_4
IF cargar_datos_liq() THEN
	RETURN
END IF
WHILE TRUE
	CALL mostrar_datos_liq()
	CALL leer_parametros_liq()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL ver_liquidacion(0, 'T')
END WHILE
CLOSE WINDOW w_rol4

END FUNCTION



FUNCTION control_totales_rub(i)
DEFINE i		SMALLINT
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE fec_min		LIKE rolt032.n32_fecha_ini
DEFINE fec_max		LIKE rolt032.n32_fecha_fin

LET lin_menu = 0
LET row_ini  = 6
LET num_rows = 13
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 6
	LET num_rows = 14
	LET num_cols = 78
END IF
OPEN WINDOW w_rolf302_9 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rolf302_9 FROM '../forms/rolf302_9'
ELSE
	OPEN FORM f_rolf302_9 FROM '../forms/rolf302_9c'
END IF
DISPLAY FORM f_rolf302_9
CALL datos_defaults2(i, 0)
CALL retorna_fec_min_trab(i) RETURNING fec_min
CALL retorna_fec_max_trab(i) RETURNING fec_max
WHILE TRUE
	CALL lee_parametros2(fec_min, fec_max)
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL armar_fechas()
	CALL muestra_totales_rub(i, 0,rm_n32.n32_fecha_ini,rm_n32.n32_fecha_fin)
	LET int_flag = 0
END WHILE
CLOSE WINDOW w_rolf302_9
RETURN

END FUNCTION
 


FUNCTION control_imprimir_empleados()
DEFINE param		VARCHAR(60)

LET param = ' "0" "N" "S" "', rm_n30.n30_estado, '" ', rm_n30.n30_cod_depto
CALL ejecuta_comando('NOMINA', vg_modulo, 'rolp423 ', param)

END FUNCTION



FUNCTION leer_parametros_ant()
DEFINE fec_ini		LIKE rolt046.n46_fecha_ini
DEFINE fec_fin		LIKE rolt046.n46_fecha_fin
DEFINE estado		LIKE rolt045.n45_estado

LET int_flag = 0
INPUT BY NAME rm_n45.n45_estado, rm_n46.n46_fecha_ini, rm_n46.n46_fecha_fin
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD n45_estado
		LET estado = rm_n45.n45_estado
	BEFORE FIELD n46_fecha_ini
		LET fec_ini = rm_n46.n46_fecha_ini
	BEFORE FIELD n46_fecha_fin
		LET fec_fin = rm_n46.n46_fecha_fin
	AFTER FIELD n45_estado
		IF rm_n45.n45_estado IS NULL THEN
			LET rm_n45.n45_estado = estado
		END IF
		CALL muestra_estado_par()
	AFTER FIELD n46_fecha_ini
		IF rm_n46.n46_fecha_ini IS NULL THEN
			LET rm_n46.n46_fecha_ini = fec_ini
			DISPLAY BY NAME rm_n46.n46_fecha_ini
		END IF
		IF rm_n46.n46_fecha_ini > TODAY THEN
			CALL fl_mostrar_mensaje('La fecha inicial debe ser menor o igual a la fecha de hoy.', 'exclamation')
			NEXT FIELD n46_fecha_ini
		END IF
	AFTER FIELD n46_fecha_fin
		IF rm_n46.n46_fecha_fin IS NULL THEN
			LET rm_n46.n46_fecha_fin = fec_fin
			DISPLAY BY NAME rm_n46.n46_fecha_fin
		END IF
		IF rm_n46.n46_fecha_fin > TODAY THEN
			CALL fl_mostrar_mensaje('La fecha final debe ser menor o igual a la fecha de hoy.', 'exclamation')
			NEXT FIELD n46_fecha_fin
		END IF
	AFTER INPUT
		IF rm_n46.n46_fecha_fin < rm_n46.n46_fecha_ini THEN
			CALL fl_mostrar_mensaje('La fecha final debe ser menor que la fecha inicial.', 'exclamation')
			NEXT FIELD n46_fecha_fin
		END IF
END INPUT

END FUNCTION



FUNCTION cargar_datos_liq()
DEFINE r_n01		RECORD LIKE rolt001.*
DEFINE r_n05		RECORD LIKE rolt005.*
DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE mensaje		VARCHAR(200)
DEFINE tit_mes		VARCHAR(11)

INITIALIZE rm_n32.* TO NULL
CALL fl_lee_parametro_general_roles()  RETURNING rm_n00.*
IF rm_n00.n00_serial IS NULL THEN
        CALL fl_mostrar_mensaje('No existe configuración general para este módulo.', 'stop')
	RETURN 1
END IF
CALL fl_lee_compania_roles(vg_codcia) RETURNING r_n01.*
IF r_n01.n01_compania IS NULL THEN
        CALL fl_mostrar_mensaje('No existe configuración para esta compañía.', 'stop')
	RETURN 1
END IF
IF r_n01.n01_estado <> 'A' THEN
        CALL fl_mostrar_mensaje('Compañía no está activa.', 'stop')
	RETURN 1
END IF
LET rm_n32.n32_ano_proceso = r_n01.n01_ano_proceso
LET rm_n32.n32_mes_proceso = r_n01.n01_mes_proceso
INITIALIZE r_n05.* TO NULL
DECLARE q_n05 CURSOR FOR
	SELECT * FROM rolt005
		WHERE n05_compania = vg_codcia
		  AND n05_proceso[1] IN ('M', 'Q', 'S')
		ORDER BY n05_fec_cierre DESC
OPEN q_n05
FETCH q_n05 INTO r_n05.*
INITIALIZE r_n32.* TO NULL
DECLARE q_ultliq CURSOR FOR
	SELECT * FROM rolt032
		WHERE n32_compania   = r_n05.n05_compania
		  AND n32_cod_liqrol = r_n05.n05_proceso
		  AND n32_estado     <> 'E'
		ORDER BY n32_fecha_ini DESC
OPEN q_ultliq
FETCH q_ultliq INTO r_n32.*
LET rm_n32.n32_cod_liqrol  = r_n32.n32_cod_liqrol
LET rm_n32.n32_fecha_ini   = r_n32.n32_fecha_ini
LET rm_n32.n32_fecha_fin   = r_n32.n32_fecha_fin
LET rm_n32.n32_ano_proceso = r_n32.n32_ano_proceso
LET rm_n32.n32_mes_proceso = r_n32.n32_mes_proceso
LET vm_agrupado            = 'S'
LET vm_consulta            = 'D'
CALL retorna_mes(rm_n32.n32_mes_proceso) RETURNING tit_mes
DISPLAY BY NAME tit_mes
RETURN 0

END FUNCTION



FUNCTION mostrar_datos_liq()
DEFINE r_n03		RECORD LIKE rolt003.*

DISPLAY BY NAME rm_n32.n32_cod_liqrol, rm_n32.n32_fecha_ini,
		rm_n32.n32_fecha_fin, rm_n32.n32_ano_proceso,
		rm_n32.n32_mes_proceso, vm_agrupado, vm_consulta
CALL fl_lee_proceso_roles(rm_n32.n32_cod_liqrol) RETURNING r_n03.*
DISPLAY BY NAME r_n03.n03_nombre

END FUNCTION



FUNCTION leer_parametros_liq()
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE anio		LIKE rolt032.n32_ano_proceso
DEFINE mes		LIKE rolt032.n32_mes_proceso
DEFINE mes_aux		LIKE rolt032.n32_mes_proceso
DEFINE tit_mes		VARCHAR(11)

LET int_flag = 0
INPUT BY NAME rm_n32.n32_cod_liqrol, rm_n32.n32_ano_proceso,
	rm_n32.n32_mes_proceso, vm_agrupado, vm_consulta
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	ON KEY(F2)
		IF INFIELD(n32_cod_liqrol) THEN
			CALL fl_ayuda_procesos_roles()
				RETURNING r_n03.n03_proceso,
					  r_n03.n03_nombre
			IF r_n03.n03_proceso IS NOT NULL THEN
				LET rm_n32.n32_cod_liqrol = r_n03.n03_proceso
				DISPLAY BY NAME rm_n32.n32_cod_liqrol,
						r_n03.n03_nombre  
			END IF
		END IF
		IF INFIELD(n32_mes_proceso) THEN
			CALL fl_ayuda_mostrar_meses() RETURNING mes_aux, tit_mes
			IF mes_aux IS NOT NULL THEN
				LET rm_n32.n32_mes_proceso = mes_aux
				DISPLAY BY NAME rm_n32.n32_mes_proceso, tit_mes
			END IF
                END IF
		LET int_flag = 0
	BEFORE FIELD n32_ano_proceso
		LET anio = rm_n32.n32_ano_proceso
	BEFORE FIELD n32_mes_proceso
		LET mes = rm_n32.n32_mes_proceso
	AFTER FIELD n32_cod_liqrol
		IF rm_n32.n32_cod_liqrol IS NOT NULL THEN
   			CALL fl_lee_proceso_roles(rm_n32.n32_cod_liqrol)
                        	RETURNING r_n03.*
			IF r_n03.n03_proceso IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe el código de liquidación en la Compañía.','exclamation')
				NEXT FIELD n32_cod_liqrol
			END IF
			DISPLAY BY NAME r_n03.n03_nombre
			CALL mostrar_fechas()
		ELSE
			CLEAR n03_nombre
		END IF
	AFTER FIELD n32_ano_proceso
		IF rm_n32.n32_ano_proceso IS NOT NULL THEN
			IF rm_n32.n32_ano_proceso > YEAR(TODAY) THEN
				CALL fl_mostrar_mensaje('El año no puede ser mayor al año vigente.', 'exclamation')
				NEXT FIELD n32_ano_proceso
			END IF
		ELSE
			LET rm_n32.n32_ano_proceso = anio
			DISPLAY BY NAME rm_n32.n32_ano_proceso
		END IF
		CALL mostrar_fechas()
	AFTER FIELD n32_mes_proceso
		IF rm_n32.n32_mes_proceso IS NULL THEN
			LET rm_n32.n32_mes_proceso = mes
			DISPLAY BY NAME rm_n32.n32_mes_proceso
		END IF
		CALL retorna_mes(rm_n32.n32_mes_proceso) RETURNING tit_mes
		DISPLAY BY NAME tit_mes
		CALL mostrar_fechas()
	AFTER INPUT
		IF rm_n30.n30_cod_depto IS NOT NULL THEN
			LET vm_consulta = 'D'
			DISPLAY BY NAME vm_consulta
		END IF
END INPUT
IF int_flag THEN
	RETURN
END IF
IF rm_n30.n30_cod_depto IS NOT NULL THEN
	LET vm_consulta = 'D'
END IF

END FUNCTION



FUNCTION datos_defaults2(i, flag)
DEFINE i, flag		SMALLINT
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE fec_max		LIKE rolt032.n32_fecha_fin

INITIALIZE rm_n32.*, vm_codliq_ini, vm_codliq_fin TO NULL
LET vm_num_elmt = 0
CALL retorna_fec_max_trab(i) RETURNING fec_max
IF num_args() = 3 THEN
	LET vm_anio_fin = YEAR(fec_max)
	LET vm_mes_fin  = MONTH(fec_max)
	LET vm_anio_ini = vm_anio_fin
	LET vm_mes_ini  = vm_mes_fin
	IF flag = 2 THEN
		SELECT YEAR(MIN(n32_fecha_ini)),
			MONTH(MIN(n32_fecha_ini))
			INTO vm_anio_ini, vm_mes_ini
			FROM rolt032
			WHERE n32_compania    = vg_codcia
			  AND n32_cod_liqrol IN ("Q1", "Q2")
			  AND n32_estado     <> 'E'
			  AND n32_fecha_ini  >= MDY(01, 01, YEAR(TODAY))
			  AND n32_cod_trab    = rm_detalle[i].n30_cod_trab
		IF vm_anio_ini IS NULL THEN
			LET vm_anio_ini = YEAR(fec_max)
			LET vm_mes_ini  = MONTH(fec_max - 1 UNITS YEAR
						+ 1 UNITS DAY)
		END IF
	END IF
ELSE
	IF arg_val(6) = 'D' THEN
		LET rm_n32.n32_cod_depto = arg_val(7)
	END IF
END IF
CALL retorna_mes(vm_mes_ini) RETURNING tit_mes_ini
CALL retorna_mes(vm_mes_fin) RETURNING tit_mes_fin
CALL fl_lee_trabajador_roles(vg_codcia, rm_detalle[i].n30_cod_trab)
	RETURNING r_n30.*
LET rm_n32.n32_cod_trab  = r_n30.n30_cod_trab
IF num_args() = 3 OR arg_val(6) = 'T' THEN
	LET rm_n32.n32_cod_depto = r_n30.n30_cod_depto
END IF
CALL fl_lee_departamento(vg_codcia, rm_n32.n32_cod_depto) RETURNING r_g34.*
DISPLAY BY NAME rm_n32.n32_cod_trab, r_n30.n30_nombres, rm_n32.n32_cod_depto,
		r_g34.g34_nombre, vm_anio_ini, vm_anio_fin, vm_mes_ini,
		vm_mes_fin, tit_mes_ini, tit_mes_fin
IF flag <> 2 THEN
	DISPLAY BY NAME vm_codliq_ini, vm_codliq_fin
END IF
IF flag <> 0 THEN
	CALL muestra_estado(i)
END IF

END FUNCTION



FUNCTION lee_parametros2(fec_min, fec_max)
DEFINE fec_min		LIKE rolt032.n32_fecha_ini
DEFINE fec_max		LIKE rolt032.n32_fecha_fin
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE anio_ini		LIKE rolt032.n32_ano_proceso
DEFINE anio_fin		LIKE rolt032.n32_ano_proceso
DEFINE mes_ini		LIKE rolt032.n32_mes_proceso
DEFINE mes_fin		LIKE rolt032.n32_mes_proceso
DEFINE mes_aux		LIKE rolt032.n32_mes_proceso
DEFINE tit_mes		VARCHAR(11)

LET int_flag = 0
INPUT BY NAME rm_n32.n32_cod_trab, rm_n32.n32_cod_depto, vm_anio_ini,
	vm_mes_ini, vm_codliq_ini, vm_anio_fin, vm_mes_fin, vm_codliq_fin
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	ON KEY(F2)
		IF INFIELD(n32_cod_depto) THEN
			CALL fl_ayuda_departamentos(vg_codcia)
				RETURNING r_g34.g34_cod_depto, r_g34.g34_nombre
			IF r_g34.g34_cod_depto IS NOT NULL THEN
				LET rm_n32.n32_cod_depto = r_g34.g34_cod_depto
				DISPLAY BY NAME rm_n32.n32_cod_depto,
						r_g34.g34_nombre
			END IF
		END IF
		IF INFIELD(n32_cod_trab) THEN
			CALL fl_ayuda_codigo_empleado(vg_codcia)
				RETURNING r_n30.n30_cod_trab, r_n30.n30_nombres
			IF r_n30.n30_cod_trab IS NOT NULL THEN
				LET rm_n32.n32_cod_trab = r_n30.n30_cod_trab
				DISPLAY BY NAME rm_n32.n32_cod_trab,
						r_n30.n30_nombres
			END IF
		END IF
		IF INFIELD(vm_mes_ini) THEN
			CALL fl_ayuda_mostrar_meses() RETURNING mes_aux, tit_mes
			IF mes_aux IS NOT NULL THEN
				LET vm_mes_ini  = mes_aux
				LET tit_mes_ini = tit_mes
				DISPLAY BY NAME vm_mes_ini, tit_mes_ini
			END IF
                END IF
		IF INFIELD(vm_mes_fin) THEN
			CALL fl_ayuda_mostrar_meses() RETURNING mes_aux, tit_mes
			IF mes_aux IS NOT NULL THEN
				LET vm_mes_fin  = mes_aux
				LET tit_mes_fin = tit_mes
				DISPLAY BY NAME vm_mes_fin, tit_mes_fin
			END IF
                END IF
		IF INFIELD(vm_codliq_ini) THEN
			CALL fl_ayuda_procesos_roles()
				RETURNING r_n03.n03_proceso,
					  r_n03.n03_nombre
			IF r_n03.n03_proceso IS NOT NULL THEN
				LET vm_codliq_ini = r_n03.n03_proceso
				DISPLAY BY NAME vm_codliq_ini
			END IF
		END IF
		IF INFIELD(vm_codliq_fin) THEN
			CALL fl_ayuda_procesos_roles()
				RETURNING r_n03.n03_proceso,
					  r_n03.n03_nombre
			IF r_n03.n03_proceso IS NOT NULL THEN
				LET vm_codliq_fin = r_n03.n03_proceso
				DISPLAY BY NAME vm_codliq_fin
			END IF
		END IF
               	LET int_flag = 0
	BEFORE FIELD vm_anio_ini
		LET anio_ini = vm_anio_ini
	BEFORE FIELD vm_anio_fin
		LET anio_fin = vm_anio_fin
	BEFORE FIELD vm_mes_ini
		LET mes_ini = vm_mes_ini
	BEFORE FIELD vm_mes_fin
		LET mes_fin = vm_mes_fin
	AFTER FIELD n32_cod_depto
		IF rm_n32.n32_cod_depto IS NOT NULL THEN
			CALL fl_lee_departamento(vg_codcia,rm_n32.n32_cod_depto)
				RETURNING r_g34.*
			IF r_g34.g34_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Departamento no existe.','exclamation')
				NEXT FIELD n32_cod_depto
			END IF
			DISPLAY BY NAME r_g34.g34_nombre
		ELSE
			CLEAR g34_nombre
		END IF
	AFTER FIELD n32_cod_trab
		IF rm_n32.n32_cod_trab IS NOT NULL THEN
			CALL fl_lee_trabajador_roles(vg_codcia,
							rm_n32.n32_cod_trab)
				RETURNING r_n30.*
			IF r_n30.n30_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe el código de este empleado en la Compañía.','exclamation')
				NEXT FIELD n32_cod_trab
			END IF
			DISPLAY BY NAME r_n30.n30_nombres
		ELSE
			CLEAR n30_nombres
		END IF
	AFTER FIELD vm_anio_ini
		IF vm_anio_ini IS NOT NULL THEN
			IF vm_anio_ini > YEAR(TODAY) THEN
				CALL fl_mostrar_mensaje('El año inicial no puede ser mayor al año vigente.', 'exclamation')
				NEXT FIELD vm_anio_ini
			END IF
		ELSE
			LET vm_anio_ini = anio_ini
			DISPLAY BY NAME vm_anio_ini
		END IF
		IF vm_anio_ini < YEAR(fec_min) THEN
			LET vm_anio_ini = YEAR(fec_min)
			DISPLAY BY NAME vm_anio_ini
		END IF
	AFTER FIELD vm_anio_fin
		IF vm_anio_fin IS NOT NULL THEN
			IF vm_anio_fin > YEAR(TODAY) THEN
				CALL fl_mostrar_mensaje('El año final no puede ser mayor al año vigente.', 'exclamation')
				NEXT FIELD vm_anio_fin
			END IF
		ELSE
			LET vm_anio_fin = anio_fin
			DISPLAY BY NAME vm_anio_fin
		END IF
		IF vm_anio_fin > YEAR(fec_max) THEN
			LET vm_anio_fin = YEAR(fec_max)
			DISPLAY BY NAME vm_anio_fin
		END IF
	AFTER FIELD vm_mes_ini
		IF vm_mes_ini IS NULL THEN
			LET vm_mes_ini = mes_ini
		END IF
		IF MDY(vm_mes_ini, DAY(fec_min), vm_anio_ini) < fec_min THEN
			LET vm_mes_ini = MONTH(fec_min)
		END IF
		DISPLAY BY NAME vm_mes_ini
		CALL retorna_mes(vm_mes_ini) RETURNING tit_mes_ini
		DISPLAY BY NAME tit_mes_ini
	AFTER FIELD vm_mes_fin
		IF vm_mes_fin IS NULL THEN
			LET vm_mes_fin = mes_fin
		END IF
		IF MDY(vm_mes_fin, DAY(fec_max), vm_anio_fin) > fec_max THEN
			LET vm_mes_fin = MONTH(fec_max)
		END IF
		DISPLAY BY NAME vm_mes_fin
		CALL retorna_mes(vm_mes_fin) RETURNING tit_mes_fin
		DISPLAY BY NAME tit_mes_fin
	AFTER FIELD vm_codliq_ini
		IF vm_codliq_ini IS NOT NULL THEN
   			CALL fl_lee_proceso_roles(vm_codliq_ini)
				RETURNING r_n03.*
			IF r_n03.n03_proceso IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe el código de liquidación en la Compañía.','exclamation')
				NEXT FIELD vm_codliq_ini
			END IF
			IF MDY(vm_mes_ini, DAY(fec_min), vm_anio_ini) = fec_min
			THEN
				IF DAY(fec_min) < 16 THEN
					LET vm_codliq_ini = "Q1"
				ELSE
					LET vm_codliq_ini = "Q2"
				END IF
				DISPLAY BY NAME vm_codliq_ini
			END IF
		END IF
	AFTER FIELD vm_codliq_fin
		IF vm_codliq_fin IS NOT NULL THEN
   			CALL fl_lee_proceso_roles(vm_codliq_fin)
				RETURNING r_n03.*
			IF r_n03.n03_proceso IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe el código de liquidación en la Compañía.','exclamation')
				NEXT FIELD vm_codliq_fin
			END IF
			IF MDY(vm_mes_fin, DAY(fec_max), vm_anio_fin) = fec_max
			THEN
				IF DAY(fec_max) < 16 THEN
					LET vm_codliq_fin = "Q1"
				ELSE
					LET vm_codliq_fin = "Q2"
				END IF
				DISPLAY BY NAME vm_codliq_fin
			END IF
		END IF
	AFTER INPUT
		IF vm_anio_ini > vm_anio_fin THEN
			CALL fl_mostrar_mensaje('El año inicial debe ser menor o igual al año final.', 'exclamation')
			NEXT FIELD vm_anio_ini
		END IF
		IF vm_anio_ini = vm_anio_fin THEN
			IF vm_mes_ini > vm_mes_fin THEN
				CALL fl_mostrar_mensaje('Dentro del mismo año, el mes inicial debe ser menor o igual al mes final.', 'exclamation')
				NEXT FIELD vm_mes_ini
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION control_consulta2(pos)
DEFINE pos	 	SMALLINT
DEFINE i, j, col	SMALLINT
DEFINE r_n32		RECORD LIKE rolt032.*

IF preparar_query2() THEN
	RETURN
END IF
CALL mostrar_totales()
LET int_flag = 0
CALL set_count(vm_num_elmt)
DISPLAY ARRAY rm_det_tot TO rm_det_tot.*
       	ON KEY(INTERRUPT)   
		LET int_flag = 1
		EXIT DISPLAY  
	ON KEY(F5)
		LET int_flag = 0
		EXIT DISPLAY  
	ON KEY(F6)
		IF rm_n32.n32_cod_trab IS NOT NULL THEN
			IF rm_n32.n32_cod_trab = rm_detalle[pos].n30_cod_trab
			THEN
				CALL mostrar_empleado(
						rm_detalle[pos].n30_cod_trab)
				LET int_flag = 0
			END IF
		END IF
	ON KEY(F7)
		LET i = arr_curr()	
		CALL ver_liquidacion(i, 'L')
		LET int_flag = 0
	ON KEY(F8)
		LET i = arr_curr()	
		CALL ver_liquidacion(i, 'I')
		LET int_flag = 0
	ON KEY(F9)
		IF rm_n32.n32_cod_trab IS NOT NULL THEN
			IF rm_n32.n32_cod_trab = rm_detalle[pos].n30_cod_trab
			THEN
				CALL control_otros_valores(pos)
				LET int_flag = 0
			END IF
		END IF
	ON KEY(F10)
		CALL muestra_totales_rub(pos, 1, rm_n32.n32_fecha_ini,
					rm_n32.n32_fecha_fin)
		LET int_flag = 0
	ON KEY(F11)
		CALL control_imprimir_tot_gan_quin()
		LET int_flag = 0
	--#BEFORE DISPLAY 
		--#CALL dialog.keysetlabel('ACCEPT', '')   
		--#CALL dialog.keysetlabel("F1","") 
		--#CALL dialog.keysetlabel("CONTROL-W","") 
		--#IF rm_n32.n32_cod_trab IS NOT NULL AND
		   --#(rm_n32.n32_cod_trab = rm_detalle[pos].n30_cod_trab)
		--#THEN
			--#CALL dialog.keysetlabel("F6","Datos Empleado") 
			--#CALL dialog.keysetlabel("F9","Otros Valores") 
		--#ELSE
			--#CALL dialog.keysetlabel("F6","") 
			--#CALL dialog.keysetlabel("F9","") 
		--#END IF
		--#CALL dialog.keysetlabel("F11","Imprimir Listado") 
	--#BEFORE ROW 
		--#LET i = arr_curr()	
		--#LET j = scr_line()
		--#CALL muestra_contadores_det_tot(i, vm_num_elmt)
		--#CALL fl_lee_liquidacion_roles(vg_codcia,
						--#rm_det_tot[i].n32_cod_liqrol,
						--#rm_det_tot[i].n32_fecha_ini,
						--#rm_det_tot[i].n32_fecha_fin,
						--#rm_detalle[pos].n30_cod_trab)
			--#RETURNING r_n32.*
		--#DISPLAY BY NAME r_n32.n32_sueldo
        --#AFTER DISPLAY  
                --#CONTINUE DISPLAY  
END DISPLAY

END FUNCTION



FUNCTION control_consulta3(pos)
DEFINE pos	 	SMALLINT
DEFINE i, j, col, mes	SMALLINT
DEFINE dia, flag, p 	SMALLINT
DEFINE fecha_ini	LIKE rolt032.n32_fecha_ini
DEFINE fecha_fin	LIKE rolt032.n32_fecha_fin

IF preparar_query3() THEN
	RETURN
END IF
LET p = pos
IF rm_detalle[pos].n30_cod_trab <> rm_n32.n32_cod_trab THEN
	LET p = 0
END IF
IF num_args() <> 3 AND arg_val(6) <> 'T' THEN
	DISPLAY BY NAME rm_detalle[1].n30_nombres
END IF
CALL mostrar_totales2()
LET int_flag = 0
CALL set_count(vm_num_elmt)
DISPLAY ARRAY rm_det_tot2 TO rm_det_tot2.*
       	ON KEY(INTERRUPT)   
		LET int_flag = 1
		EXIT DISPLAY  
	ON KEY(F5)
		IF num_args() = 3 THEN
			LET int_flag = 0
			EXIT DISPLAY
		END IF
	ON KEY(F6)
		IF rm_n32.n32_cod_trab IS NOT NULL THEN
			IF rm_n32.n32_cod_trab = rm_detalle[pos].n30_cod_trab
			THEN
				CALL mostrar_empleado(
						rm_detalle[pos].n30_cod_trab)
				LET int_flag = 0
			END IF
		END IF
	ON KEY(F8)
		IF rm_n32.n32_cod_trab IS NOT NULL THEN
			IF rm_n32.n32_cod_trab = rm_detalle[pos].n30_cod_trab
			THEN
				CALL control_otros_valores(pos)
				LET int_flag = 0
			END IF
		END IF
	ON KEY(F9)
		LET flag = 1
		IF rm_n32.n32_cod_trab IS NULL OR rm_n32.n32_cod_depto IS NULL
		THEN
			LET flag = 0
		END IF
		CALL muestra_totales_rub(p, flag, rm_n32.n32_fecha_ini,
					rm_n32.n32_fecha_fin)
		LET int_flag = 0
	ON KEY(F10)
		LET i = arr_curr()
		CALL retorna_num_mes(rm_det_tot2[i].nom_mes) RETURNING mes
		LET dia = 1
		IF vm_codliq_ini IS NOT NULL AND i = 1 THEN
			IF vm_codliq_ini = "Q2" THEN
				LET dia = 16
			END IF
		END IF
		LET fecha_ini = MDY(mes, dia, rm_det_tot2[i].n32_ano_proceso)
		LET fecha_fin = MDY(MONTH(fecha_ini), 01, YEAR(fecha_ini))
				+ 1 UNITS MONTH - 1 UNITS DAY
		IF vm_codliq_fin IS NOT NULL AND i = vm_num_elmt THEN
			IF vm_codliq_fin = "Q1" THEN
				LET fecha_fin = MDY(MONTH(fecha_ini), 15,
							YEAR(fecha_ini))
			END IF
		END IF
		LET flag = 2
		IF rm_n32.n32_cod_trab IS NULL OR rm_n32.n32_cod_depto IS NULL
		THEN
			LET flag = 0
		END IF
		CALL muestra_totales_rub(p, flag, fecha_ini, fecha_fin)
		LET int_flag = 0
	ON KEY(F11)
		CALL control_imprimir_tot_gan_mes()
		LET int_flag = 0
	--#BEFORE DISPLAY 
		--#CALL dialog.keysetlabel('ACCEPT', '')   
		--#CALL dialog.keysetlabel("F1","") 
		--#CALL dialog.keysetlabel("CONTROL-W","") 
		--#IF num_args() = 3 THEN
			--#CALL dialog.keysetlabel("F5","Cabecera") 
		--#ELSE
			--#CALL dialog.keysetlabel("F5","") 
		--#END IF
		--#IF rm_n32.n32_cod_trab IS NOT NULL AND
		   --#(rm_n32.n32_cod_trab = rm_detalle[pos].n30_cod_trab)
		--#THEN
			--#CALL dialog.keysetlabel("F6","Datos Empleado") 
			--#CALL dialog.keysetlabel("F8","Otros Valores") 
		--#ELSE
			--#CALL dialog.keysetlabel("F6","") 
			--#CALL dialog.keysetlabel("F8","") 
		--#END IF
	--#BEFORE ROW 
		--#LET i = arr_curr()
		--#LET j = scr_line()
		--#CALL muestra_contadores_det_tot(i, vm_num_elmt)
        --#AFTER DISPLAY  
                --#CONTINUE DISPLAY  
END DISPLAY

END FUNCTION



FUNCTION preparar_query1()
DEFINE query		CHAR(1200)
DEFINE expr_estado	VARCHAR(100)
DEFINE expr_depto	VARCHAR(100)
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE nombre		LIKE gent035.g35_nombre

LET expr_estado = '   AND n30_estado    = "', rm_n30.n30_estado, '"'
IF rm_n30.n30_estado = 'T' THEN
	LET expr_estado = '   AND n30_estado IN ("A", "J", "I")'
END IF
LET expr_depto = NULL
IF rm_n30.n30_cod_depto IS NOT NULL THEN
	LET expr_depto = '   AND n30_cod_depto  = ', rm_n30.n30_cod_depto
END IF
LET query = 'SELECT rolt030.*, g35_nombre ',
		' FROM rolt030, gent035 ',
		' WHERE n30_compania   = ', vg_codcia,
		'   AND n30_mon_sueldo = "', rm_n30.n30_mon_sueldo, '"',
		expr_estado CLIPPED,
		expr_depto CLIPPED,
		'   AND n30_compania   = g35_compania ',
		'   AND n30_cod_cargo  = g35_cod_cargo ',
		' ORDER BY n30_nombres '
PREPARE det FROM query	
DECLARE q_det CURSOR FOR det
LET vm_num_det = 1
FOREACH q_det INTO r_n30.*, nombre
	LET rm_detalle[vm_num_det].n30_cod_trab   = r_n30.n30_cod_trab
	LET rm_detalle[vm_num_det].n30_nombres    = r_n30.n30_nombres
	LET rm_detalle[vm_num_det].g35_nombre     = nombre
	LET rm_detalle[vm_num_det].n30_sueldo_mes = r_n30.n30_sueldo_mes
	IF r_n30.n30_estado = 'J' THEN
	       LET rm_detalle[vm_num_det].n30_sueldo_mes = r_n30.n30_val_jub_pat
	END IF
	LET rm_detalle[vm_num_det].n30_estado     = r_n30.n30_estado
	INSERT INTO temp_detalle
		VALUES(r_n30.n30_cod_depto, rm_detalle[vm_num_det].*)
	LET vm_num_det = vm_num_det + 1
        IF vm_num_det > vm_max_det THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_det = vm_num_det - 1
IF vm_num_det = 0 THEN
	LET int_flag = 0
	CALL fl_mensaje_consulta_sin_registros()
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION preparar_query2()
DEFINE query		CHAR(1200)
DEFINE r_n32		RECORD LIKE rolt032.*

CALL armar_fechas()
LET query = 'SELECT * FROM rolt032 ',
		' WHERE n32_compania   = ',  vg_codcia,
		'   AND n32_fecha_ini >= "', rm_n32.n32_fecha_ini, '"',
		'   AND n32_fecha_fin <= "', rm_n32.n32_fecha_fin, '"',
		'   AND n32_cod_trab   = ',  rm_n32.n32_cod_trab,
		'   AND n32_estado    <> "E" ',
		' ORDER BY n32_fecha_ini '
PREPARE det2 FROM query	
DECLARE q_det2 CURSOR FOR det2
LET vm_num_elmt = 1
FOREACH q_det2 INTO r_n32.*
	IF vm_codliq_ini IS NOT NULL THEN
		IF r_n32.n32_cod_liqrol <  vm_codliq_ini AND
		   r_n32.n32_fecha_ini  <= rm_n32.n32_fecha_ini
		THEN
			CONTINUE FOREACH
		END IF
	END IF
	IF vm_codliq_fin IS NOT NULL THEN
		IF r_n32.n32_cod_liqrol >  vm_codliq_fin AND
		   r_n32.n32_fecha_fin  >= rm_n32.n32_fecha_fin
		THEN
			CONTINUE FOREACH
		END IF
	END IF
	LET rm_det_tot[vm_num_elmt].n32_cod_liqrol = r_n32.n32_cod_liqrol
	LET rm_det_tot[vm_num_elmt].n32_fecha_ini  = r_n32.n32_fecha_ini
	LET rm_det_tot[vm_num_elmt].n32_fecha_fin  = r_n32.n32_fecha_fin
	LET rm_det_tot[vm_num_elmt].n32_tot_gan    = r_n32.n32_tot_gan
	LET rm_det_tot[vm_num_elmt].total_ing      = r_n32.n32_tot_ing
	LET rm_det_tot[vm_num_elmt].total_egr      = r_n32.n32_tot_egr
	LET rm_det_tot[vm_num_elmt].total_net      = r_n32.n32_tot_neto
	LET vm_num_elmt = vm_num_elmt + 1
        IF vm_num_elmt > vm_max_elmt THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_elmt = vm_num_elmt - 1
IF vm_num_elmt = 0 THEN
	LET int_flag = 0
	CALL fl_mensaje_consulta_sin_registros()
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION preparar_query3()
DEFINE r_det		RECORD
				n32_ano_proceso	LIKE rolt032.n32_ano_proceso,
				n32_mes_proceso	LIKE rolt032.n32_mes_proceso,
				n32_sueldo	LIKE rolt032.n32_sueldo,
				n32_tot_gan	LIKE rolt032.n32_tot_gan,
				total_ing	DECIMAL(14,2),
				total_egr	DECIMAL(14,2),
				total_net	DECIMAL(14,2)
			END RECORD
DEFINE query		CHAR(2000)
DEFINE expr_fec_i	VARCHAR(100)
DEFINE expr_fec_f	VARCHAR(100)
DEFINE expr_trab	VARCHAR(100)
DEFINE expr_dpto	VARCHAR(100)

CALL armar_fechas()
LET expr_fec_i = '   AND a.n32_fecha_ini  >= "', rm_n32.n32_fecha_ini,  '"'
LET expr_fec_f = '   AND a.n32_fecha_fin  <= "', rm_n32.n32_fecha_fin,  '"'
IF vm_codliq_ini IS NOT NULL THEN
	IF vm_codliq_ini = "Q1" THEN
		LET expr_fec_i = '   AND a.n32_fecha_ini  >= MDY(',
			MONTH(rm_n32.n32_fecha_ini), ', 01, ',
			YEAR(rm_n32.n32_fecha_ini), ')'
	END IF
	IF vm_codliq_ini = "Q2" THEN
		LET expr_fec_i = '   AND a.n32_fecha_ini  >= MDY(',
			MONTH(rm_n32.n32_fecha_ini), ', 16, ',
			YEAR(rm_n32.n32_fecha_ini), ')'
	END IF
END IF
IF vm_codliq_fin IS NOT NULL THEN
	IF vm_codliq_fin = "Q1" THEN
		LET expr_fec_f = '   AND a.n32_fecha_fin  <= MDY(',
			MONTH(rm_n32.n32_fecha_fin), ', 15, ',
			YEAR(rm_n32.n32_fecha_fin), ')'
	END IF
	IF vm_codliq_fin = "Q2" THEN
		LET expr_fec_f = '   AND a.n32_fecha_fin  <= MDY(',
			MONTH(rm_n32.n32_fecha_fin), ', 01, ',
			YEAR(rm_n32.n32_fecha_fin),
			') + 1 UNITS MONTH - 1 UNITS DAY'
	END IF
END IF
LET expr_trab = NULL
IF rm_n32.n32_cod_trab IS NOT NULL THEN
	LET expr_trab = '   AND a.n32_cod_trab    = ', rm_n32.n32_cod_trab
END IF
LET expr_dpto = NULL
IF rm_n32.n32_cod_depto IS NOT NULL THEN
	LET expr_dpto = '   AND a.n32_cod_depto   = ', rm_n32.n32_cod_depto
END IF
SELECT * FROM rolt033
	WHERE n33_compania    = vg_codcia
	  AND n33_cod_liqrol IN ("Q1", "Q2")
	  AND n33_fecha_ini  >= rm_n32.n32_fecha_ini
	  AND n33_fecha_fin  <= rm_n32.n32_fecha_fin
	  AND n33_det_tot     = "DI"
	  AND n33_cant_valor  = "V"
	  AND n33_valor       > 0
	INTO TEMP tmp_n33
LET query = 'SELECT a.n32_ano_proceso anio, a.n32_mes_proceso mes, ',
		'a.n32_cod_trab, ',
		'CASE WHEN NVL(SUM((SELECT SUM(n33_valor) ',
			'FROM tmp_n33 ',
			'WHERE n33_compania   = a.n32_compania ',
			'  AND n33_fecha_ini  = a.n32_fecha_ini ',
			'  AND n33_fecha_fin  = a.n32_fecha_fin ',
			'  AND n33_cod_trab   = a.n32_cod_trab ',
			'  AND n33_cod_rubro  IN ',
				'(SELECT n06_cod_rubro ',
				'FROM rolt006 ',
				'WHERE n06_flag_ident IN ("VT", "VV", "OV", ',
						'"VE", "SX")))), 0) >= ',
			'NVL(SUM(a.n32_sueldo / ',
			'(SELECT COUNT(*) ',
				'FROM rolt032 b ',
				'WHERE b.n32_compania    = a.n32_compania ',
				'  AND b.n32_ano_proceso = a.n32_ano_proceso ',
				'  AND b.n32_mes_proceso = a.n32_mes_proceso ',
				'  AND b.n32_cod_trab    = a.n32_cod_trab)),0)',
		' THEN ',
			'NVL(SUM(a.n32_sueldo / ',
			'(SELECT COUNT(*) ',
				'FROM rolt032 b ',
				'WHERE b.n32_compania    = a.n32_compania ',
				'  AND b.n32_ano_proceso = a.n32_ano_proceso ',
				'  AND b.n32_mes_proceso = a.n32_mes_proceso ',
				'  AND b.n32_cod_trab    = a.n32_cod_trab)), ',
			'0)',
		' ELSE ',
			'NVL(SUM((SELECT SUM(n33_valor) ',
				'FROM tmp_n33 ',
				'WHERE n33_compania   = a.n32_compania ',
				'  AND n33_fecha_ini  = a.n32_fecha_ini ',
				'  AND n33_fecha_fin  = a.n32_fecha_fin ',
				'  AND n33_cod_trab   = a.n32_cod_trab ',
				'  AND n33_cod_rubro  IN ',
					'(SELECT n06_cod_rubro ',
					'FROM rolt006 ',
					'WHERE n06_flag_ident IN ("VT", "VV", ',
						'"OV", "VE", "SX")))), 0) ',
		' END AS sueldo, ',
		'NVL(SUM(', retorna_expr_tg(1) CLIPPED, '), 0) AS tot_gan, ',
		'NVL(SUM(a.n32_tot_ing), 0) tot_ing, ',
		'NVL(SUM(a.n32_tot_egr), 0) tot_egr, ',
		'NVL(SUM(a.n32_tot_neto), 0) tot_net ',
		' FROM rolt032 a ',
		' WHERE a.n32_compania    = ',  vg_codcia,
		expr_fec_i CLIPPED,
		expr_fec_f CLIPPED,
		expr_trab CLIPPED,
		expr_dpto CLIPPED,
		'   AND a.n32_estado     <> "E" ',
		' GROUP BY 1, 2, 3 ',
		' INTO TEMP t1 '
PREPARE exec_n32 FROM query
EXECUTE exec_n32
DROP TABLE tmp_n33
LET query = 'SELECT anio, mes, SUM(sueldo), SUM(tot_gan), SUM(tot_ing), ',
			'SUM(tot_egr), SUM(tot_net) ',
		'FROM t1 ',
		'GROUP BY 1, 2 ',
		'ORDER BY 1, 2 '
PREPARE det3 FROM query	
DECLARE q_det3 CURSOR FOR det3
LET vm_num_elmt = 1
FOREACH q_det3 INTO r_det.*
	LET rm_det_tot2[vm_num_elmt].n32_ano_proceso = r_det.n32_ano_proceso
	CALL retorna_mes(r_det.n32_mes_proceso)
		RETURNING rm_det_tot2[vm_num_elmt].nom_mes
	LET rm_det_tot2[vm_num_elmt].nom_mes     =
		UPSHIFT(rm_det_tot2[vm_num_elmt].nom_mes)
	LET rm_det_tot2[vm_num_elmt].n32_sueldo  = r_det.n32_sueldo
	LET rm_det_tot2[vm_num_elmt].n32_tot_gan = r_det.n32_tot_gan
	LET rm_det_tot2[vm_num_elmt].total_ing   = r_det.total_ing
	LET rm_det_tot2[vm_num_elmt].total_egr   = r_det.total_egr
	LET rm_det_tot2[vm_num_elmt].total_net   = r_det.total_net
	LET vm_num_elmt = vm_num_elmt + 1
        IF vm_num_elmt > vm_max_elmt THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_elmt = vm_num_elmt - 1
DROP TABLE t1
IF vm_num_elmt = 0 THEN
	LET int_flag = 0
	CALL fl_mensaje_consulta_sin_registros()
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION retorna_expr_tg(flag)
DEFINE flag		SMALLINT
DEFINE expr_tot_gan	CHAR(1000)
DEFINE a		CHAR(2)

LET a = NULL
IF flag THEN
	LET a = 'a.'
END IF
LET expr_tot_gan = a, 'n32_tot_gan'
IF ver_tot_gan = 'S' THEN
	LET expr_tot_gan = '(SELECT SUM(n33_valor) ',
			'FROM tmp_n33 ',
			'WHERE n33_compania     = ', a, 'n32_compania ',
	  		'  AND n33_cod_liqrol   = ', a, 'n32_cod_liqrol ',
	  		'  AND n33_fecha_ini    = ', a, 'n32_fecha_ini ',
	  		'  AND n33_fecha_fin    = ', a, 'n32_fecha_fin ',
	  		'  AND n33_cod_trab     = ', a, 'n32_cod_trab ',
	  		'  AND n33_cod_rubro   IN ',
				'(SELECT n08_rubro_base ',
				'  FROM rolt008 ',
				'  WHERE n08_cod_rubro = ',
				'  (SELECT n06_cod_rubro ',
					'  FROM rolt006 ',
					'  WHERE n06_flag_ident = "AP")) ',
	  		'  AND n33_valor        > 0 ',
			'  AND n33_det_tot      = "DI") '
END IF
RETURN expr_tot_gan CLIPPED

END FUNCTION



FUNCTION armar_fechas()
DEFINE mes_fin		LIKE rolt032.n32_mes_proceso
DEFINE anio		LIKE rolt032.n32_ano_proceso

LET rm_n32.n32_fecha_ini = MDY(vm_mes_ini, 01, vm_anio_ini)
LET anio                 = vm_anio_fin
IF vm_mes_fin = 12 THEN
	LET mes_fin = 1
	LET anio    = anio + 1
ELSE
	LET mes_fin = vm_mes_fin + 1
END IF
LET rm_n32.n32_fecha_fin = MDY(mes_fin, 01, anio) - 1 UNITS DAY

END FUNCTION



FUNCTION cargar_det_tmp()
DEFINE query		VARCHAR(250)

LET query = 'SELECT n30_cod_trab, n30_nombres, g35_nombre, n30_sueldo_mes,',
			' n30_estado ',
		' FROM temp_detalle ',
		' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1], ', ',
			      vm_columna_2, ' ', rm_orden[vm_columna_2]
PREPARE tmp FROM query	
DECLARE q_tmp CURSOR FOR tmp
LET vm_num_det = 1
FOREACH q_tmp INTO rm_detalle[vm_num_det].*
	LET vm_num_det = vm_num_det + 1
        IF vm_num_det > vm_max_det THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_det = vm_num_det - 1

END FUNCTION



FUNCTION mostrar_totales_sueldo()
DEFINE i		SMALLINT

LET total_sueldo = 0
FOR i = 1 TO vm_num_det
	LET total_sueldo = total_sueldo + rm_detalle[i].n30_sueldo_mes
END FOR
DISPLAY BY NAME total_sueldo

END FUNCTION



FUNCTION mostrar_totales()
DEFINE i		SMALLINT

LET total_tot_gan = 0
LET total_ing_gen = 0
LET total_egr_gen = 0
LET total_net_gen = 0
FOR i = 1 TO vm_num_elmt
	LET total_tot_gan = total_tot_gan + rm_det_tot[i].n32_tot_gan
	LET total_ing_gen = total_ing_gen + rm_det_tot[i].total_ing
	LET total_egr_gen = total_egr_gen + rm_det_tot[i].total_egr
	LET total_net_gen = total_net_gen + rm_det_tot[i].total_net
END FOR
DISPLAY BY NAME total_tot_gan, total_ing_gen, total_egr_gen, total_net_gen

END FUNCTION



FUNCTION mostrar_totales2()
DEFINE i		SMALLINT

LET total_sueldo  = 0
LET total_tot_gan = 0
LET total_ing_gen = 0
LET total_egr_gen = 0
LET total_net_gen = 0
FOR i = 1 TO vm_num_elmt
	LET total_sueldo  = total_sueldo  + rm_det_tot2[i].n32_sueldo
	LET total_tot_gan = total_tot_gan + rm_det_tot2[i].n32_tot_gan
	LET total_ing_gen = total_ing_gen + rm_det_tot2[i].total_ing
	LET total_egr_gen = total_egr_gen + rm_det_tot2[i].total_egr
	LET total_net_gen = total_net_gen + rm_det_tot2[i].total_net
END FOR
DISPLAY BY NAME total_tot_gan, total_ing_gen, total_egr_gen, total_net_gen,
		total_sueldo

END FUNCTION



FUNCTION muestra_contadores_detalle(i, j)
DEFINE i, j		SMALLINT

DISPLAY i TO vm_num_det
DISPLAY j TO vm_max_det

END FUNCTION



FUNCTION muestra_contadores_det_tot(i, j)
DEFINE i, j		SMALLINT

DISPLAY i TO i_cor
DISPLAY j TO max_cor

END FUNCTION



FUNCTION muestra_estado(i)
DEFINE i		SMALLINT

IF rm_detalle[i].n30_estado = 'A' THEN
	DISPLAY 'ACTIVO' TO tit_estado
END IF
IF rm_detalle[i].n30_estado = 'I' THEN
	DISPLAY 'INACTIVO' TO tit_estado
END IF
IF rm_detalle[i].n30_estado = 'J' THEN
	DISPLAY 'JUBILADO' TO tit_estado
END IF

END FUNCTION



FUNCTION mostrar_botones_detalle1()

--#DISPLAY "Cod."		TO tit_col1
--#DISPLAY "Empleado"		TO tit_col2
--#DISPLAY "Cargo"		TO tit_col3
--#DISPLAY "Sueldo"		TO tit_col4
--#DISPLAY "E"			TO tit_col5

END FUNCTION



FUNCTION mostrar_botones_detalle2()

--#DISPLAY "LQ"			TO tit_col1
--#DISPLAY "Fecha Ini."		TO tit_col2
--#DISPLAY "Fecha Fin."		TO tit_col3
--#DISPLAY "Total Ganado"	TO tit_col4
--#DISPLAY "Tot. Ingreso"	TO tit_col5
--#DISPLAY "Total Egreso"	TO tit_col6
--#DISPLAY "Total Neto"		TO tit_col7

END FUNCTION



FUNCTION mostrar_botones_detalle4()

--#DISPLAY "Anio"		TO tit_col1
--#DISPLAY "Meses"		TO tit_col2
--#DISPLAY "Sueldo Mes"		TO tit_col3
--#DISPLAY "Total Ganado"	TO tit_col4
--#DISPLAY "Tot. Ingreso"	TO tit_col5
--#DISPLAY "Total Egreso"	TO tit_col6
--#DISPLAY "Total Neto"		TO tit_col7

END FUNCTION



FUNCTION retorna_mes(mes)
DEFINE mes		SMALLINT

RETURN fl_justifica_titulo('I', fl_retorna_nombre_mes(mes), 10)

END FUNCTION 



FUNCTION mostrar_fechas()

CALL fl_retorna_rango_fechas_proceso(vg_codcia, rm_n32.n32_cod_liqrol,
				rm_n32.n32_ano_proceso, rm_n32.n32_mes_proceso)
	RETURNING rm_n32.n32_fecha_ini, rm_n32.n32_fecha_fin
DISPLAY BY NAME rm_n32.n32_fecha_ini, rm_n32.n32_fecha_fin

END FUNCTION 
 


FUNCTION mostrar_empleado(cod_trab)
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE param		VARCHAR(60)

LET param = ' ', cod_trab
CALL ejecuta_comando('NOMINA', vg_modulo, 'rolp108 ', param)

END FUNCTION


 
FUNCTION ver_liquidacion(i, flag)
DEFINE i		SMALLINT
DEFINE flag		CHAR(1)
DEFINE param		VARCHAR(60)
DEFINE prog		VARCHAR(10)
DEFINE r_n32		RECORD LIKE rolt032.*

IF i > 0 THEN
	IF flag <> 'X' THEN
		CALL fl_lee_liquidacion_roles(vg_codcia,
					rm_det_tot[i].n32_cod_liqrol,
					rm_det_tot[i].n32_fecha_ini,
					rm_det_tot[i].n32_fecha_fin,
					rm_n32.n32_cod_trab)
			RETURNING r_n32.*
	ELSE
		CALL fl_lee_liquidacion_roles(vg_codcia,
					rm_totrub[i].n32_cod_liqrol,
					rm_totrub[i].n33_fecha_ini,
					rm_totrub[i].n33_fecha_fin,
					rm_n32.n32_cod_trab)
			RETURNING r_n32.*
	END IF
END IF
LET prog = 'rolp303 '
CASE flag
	WHEN 'T'
		LET param = ' "', rm_n32.n32_cod_liqrol, '" ',
				'"', rm_n32.n32_fecha_ini, '" ',
				'"', rm_n32.n32_fecha_fin, '" "', vm_agrupado,
				'" ', rm_n30.n30_cod_depto
		IF rm_n30.n30_cod_depto IS NULL THEN
			LET param = param CLIPPED, ' "', vm_consulta, '"'
		END IF
	WHEN 'L'
		LET param = ' "', rm_det_tot[i].n32_cod_liqrol, '" ',
				'"', rm_det_tot[i].n32_fecha_ini, '" ',
				'"', rm_det_tot[i].n32_fecha_fin, '" "N" ',
				r_n32.n32_cod_depto, ' ', r_n32.n32_cod_trab
	WHEN 'X'
		LET param = ' "', rm_totrub[i].n32_cod_liqrol, '" ',
				'"', rm_totrub[i].n33_fecha_ini, '" ',
				'"', rm_totrub[i].n33_fecha_fin, '" "N" ',
				r_n32.n32_cod_depto, ' ', r_n32.n32_cod_trab
	WHEN 'I'
		LET prog  = 'rolp405 '
		LET param = ' ', YEAR(rm_det_tot[i].n32_fecha_ini), ' ',
				MONTH(rm_det_tot[i].n32_fecha_ini), ' "',
				rm_det_tot[i].n32_cod_liqrol, '"', ' "N" ',
				r_n32.n32_cod_depto, ' ', r_n32.n32_cod_trab
		IF rm_n30.n30_estado = 'J' THEN
			LET prog  = 'rolp404 '
			LET param = ' ', YEAR(rm_det_tot[i].n32_fecha_ini), ' ',
					MONTH(rm_det_tot[i].n32_fecha_ini)
		END IF
END CASE
CALL ejecuta_comando('NOMINA', vg_modulo, prog, param)

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



FUNCTION borrar_detalle(flag)
DEFINE flag, i		SMALLINT

CLEAR total_tot_gan, total_ing_gen, total_egr_gen, total_net_gen, i_cor, max_cor
CASE flag
	WHEN 1
		FOR i = 1 TO fgl_scr_size('rm_det_tot')
			CLEAR rm_det_tot[i].*
		END FOR
		CLEAR n32_sueldo
	WHEN 2
		FOR i = 1 TO fgl_scr_size('rm_det_tot2')
			CLEAR rm_det_tot2[i].*
		END FOR
		CLEAR total_sueldo
END CASE

END FUNCTION



FUNCTION muestra_estado_par()
DEFINE estado		LIKE rolt045.n45_estado

LET estado = rm_n45.n45_estado
DISPLAY BY NAME rm_n45.n45_estado
CASE estado
	WHEN 'A'
		DISPLAY 'ACTIVO'        TO tit_estado
	WHEN 'P'
		DISPLAY 'PROCESADO'     TO tit_estado
	WHEN 'T'
		DISPLAY 'TRANSFERIDO'   TO tit_estado
	WHEN 'R'
		DISPLAY 'REDISTRIBUIDO' TO tit_estado
	WHEN 'E'
		DISPLAY 'ELIMINADO'     TO tit_estado
	WHEN 'V'
		DISPLAY 'VIGENTES'      TO tit_estado
	WHEN 'X'
		DISPLAY 'T O D O S'     TO tit_estado
	OTHERWISE
		CLEAR n45_estado, tit_estado
END CASE

END FUNCTION



FUNCTION control_otros_valores(i)
DEFINE i		SMALLINT
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE j		SMALLINT
DEFINE dias		INTEGER
DEFINE aux_t		CHAR(1)
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE r_n30		RECORD LIKE rolt030.*

CALL fl_lee_trabajador_roles(vg_codcia, rm_detalle[i].n30_cod_trab)
	RETURNING r_n30.*
LET dias = TODAY - r_n30.n30_fecha_ing
IF dias < 365 THEN
	CALL fl_mostrar_mensaje('El empleado tiene menos de un año en la empresa.', 'info')
END IF
OPEN WINDOW w_tipo AT 07, 31 WITH FORM "../forms/rolf302_6" 
	ATTRIBUTE(BORDER, COMMENT LINE LAST, FORM LINE FIRST)
LET aux_t    = vm_tipo_otro
LET int_flag = 0
INPUT BY NAME vm_tipo_otro
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag     = 1
		LET vm_tipo_otro = aux_t
		EXIT INPUT
END INPUT
CLOSE WINDOW w_tipo
IF int_flag THEN
	RETURN
END IF
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 22
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_rol5 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MENU LINE lin_menu,
		  MESSAGE LINE 0, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rolf302_5 FROM '../forms/rolf302_5'
ELSE
	OPEN FORM f_rolf302_5 FROM '../forms/rolf302_5c'
END IF
DISPLAY FORM f_rolf302_5
CALL setear_botones_valores()
CALL borrar_detalle_valores()
CALL fl_lee_departamento(vg_codcia, r_n30.n30_cod_depto) RETURNING r_g34.*
DISPLAY BY NAME rm_detalle[i].n30_cod_trab, rm_detalle[i].n30_nombres,
		r_n30.n30_cod_depto, r_g34.g34_nombre
FOR j = 1 TO 10
	LET rm_orden[j] = '' 
END FOR
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET rm_orden[1]  = 'DESC'
IF NOT preparar_querys(i) THEN
	CALL fl_mensaje_consulta_sin_registros()
	CLOSE WINDOW w_rol5
	RETURN
END IF
MENU 'OPCIONES'
	BEFORE MENU
		IF vm_num_tot > 0 THEN
			SHOW OPTION 'Resumen'
		ELSE
			HIDE OPTION 'Resumen'
		END IF
		IF vm_num_fon > 0 THEN
			SHOW OPTION 'Fondo Reserva'
		ELSE
			HIDE OPTION 'Fondo Reserva'
		END IF
		IF vm_num_dec > 0 THEN
			SHOW OPTION 'Decimos/Utilidad'
		ELSE
			HIDE OPTION 'Decimos/Utilidad'
		END IF
		IF vm_num_vac > 0 THEN
			SHOW OPTION 'Vacaciones'
		ELSE
			HIDE OPTION 'Vacaciones'
		END IF
	COMMAND KEY('E') 'Datos Empleado'
		CALL mostrar_empleado(r_n30.n30_cod_trab)
	COMMAND KEY('D') 'Decimos/Utilidad'
		CALL control_decimos(i)
	COMMAND KEY('V') 'Vacaciones'
		CALL control_vacaciones(i)
	COMMAND KEY('F') 'Fondo Reserva'
		CALL control_fondo_reserva(i)
	COMMAND KEY('R') 'Resumen'
		CALL control_resumen(i)
	COMMAND KEY('S') 'Salir' 'Regresar a la pantalla anterior.'
		EXIT MENU
END MENU
DROP TABLE tmp_tot
DROP TABLE tmp_fon
DROP TABLE tmp_dec
DROP TABLE tmp_vac
CLOSE WINDOW w_rol5
RETURN

END FUNCTION



FUNCTION borrar_detalle_valores()
DEFINE i		SMALLINT

LET vm_num_tot = 0
LET vm_num_fon = 0
LET vm_num_dec = 0
LET vm_num_vac = 0
INITIALIZE rm_totales.* TO NULL
FOR i = 1 TO fgl_scr_size('rm_dettot')
	CLEAR rm_dettot[i].*
END FOR
FOR i = 1 TO fgl_scr_size('rm_detfon')
	CLEAR rm_detfon[i].*
END FOR
FOR i = 1 TO fgl_scr_size('rm_detdec')
	CLEAR rm_detdec[i].*
END FOR
FOR i = 1 TO fgl_scr_size('rm_detvac')
	CLEAR rm_detvac[i].*
END FOR
CLEAR total01, total02, total03, total04, total05, total06, total07, total08,
	total09, total10, total11, num_row1, max_row1, num_row2, max_row2,
	num_row3, max_row3, num_row4, max_row4

END FUNCTION



FUNCTION setear_botones_valores()

DISPLAY "CP"		TO tit_col1
DISPLAY "Proceso"	TO tit_col2
DISPLAY "Subtotal"	TO tit_col3

DISPLAY "Periodo"	TO tit_col4
DISPLAY "Total Ganado"	TO tit_col5
DISPLAY "Valor Neto"	TO tit_col6

DISPLAY "Años"		TO tit_col7
DISPLAY "CP"		TO tit_col8
DISPLAY "Descripcion"	TO tit_col9
DISPLAY "Total Ganado"	TO tit_col10
DISPLAY "Valor Bruto"	TO tit_col11
DISPLAY "Valor Descto"	TO tit_col12
DISPLAY "Valor Neto"	TO tit_col13

DISPLAY "Años"		TO tit_col14
DISPLAY "DV."		TO tit_col15
DISPLAY "DA."		TO tit_col16
DISPLAY "TD."		TO tit_col17
DISPLAY "DG."		TO tit_col18
DISPLAY "DP."		TO tit_col19
DISPLAY "Total Ganado"	TO tit_col20
DISPLAY "Valor Bruto"	TO tit_col21
DISPLAY "Valor Descto"	TO tit_col22
DISPLAY "Valor Neto"	TO tit_col23

END FUNCTION



FUNCTION preparar_querys(i)
DEFINE i		SMALLINT

LET vm_max_tot = 20
LET vm_max_fon = 50
LET vm_max_dec = 100
LET vm_max_vac = 50
CALL preparar_query_fon(i)
CALL preparar_query_dec(i)
CALL preparar_query_vac(i)
CALL preparar_query_tot(i)
IF vm_num_fon = 0 AND vm_num_dec = 0 AND vm_num_vac = 0 THEN
	DROP TABLE tmp_tot
	DROP TABLE tmp_fon
	DROP TABLE tmp_dec
	DROP TABLE tmp_vac
	RETURN 0
ELSE
	RETURN 1
END IF

END FUNCTION



FUNCTION preparar_query_tot(i)
DEFINE i		SMALLINT
DEFINE query		CHAR(1800)

LET query = 'SELECT cod_fon cod_tot, n03_nombre nom_tot, ',
			'NVL(SUM(fon_neto), 0) t_val ',
		' FROM tmp_fon, rolt003 ',
		' WHERE cod_fon = n03_proceso ',
		' GROUP BY 1, 2 ',
		' UNION ',
		' SELECT cod_dec cod_tot, n03_nombre nom_tot, ',
			'NVL(SUM(dec_brut), 0) t_val ',
		' FROM tmp_dec, rolt003 ',
		' WHERE cod_dec = n03_proceso ',
		' GROUP BY 1, 2 ',
		' UNION ',
		' SELECT cod_vac cod_tot, n03_nombre nom_tot, ',
			'NVL(SUM(val_brut), 0) t_val ',
		' FROM tmp_vac, rolt003 ',
		' WHERE cod_vac = n03_proceso ',
		' GROUP BY 1, 2 ',
		' INTO TEMP tmp_tot '
PREPARE exec_tmp_t FROM query
EXECUTE exec_tmp_t
CALL cargar_detalle_tot()
IF vm_num_tot > 0 THEN
	CALL mostrar_detalle_tot()
END IF

END FUNCTION



FUNCTION cargar_detalle_tot()
DEFINE query		VARCHAR(200)

LET query = 'SELECT cod_tot, nom_tot, t_val ',
		' FROM tmp_tot ',
		' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1], ', ',
			      vm_columna_2, ' ', rm_orden[vm_columna_2]
PREPARE c_tmp_tot FROM query	
DECLARE q_tot CURSOR FOR c_tmp_tot
LET vm_num_tot = 1
FOREACH q_tot INTO rm_dettot[vm_num_tot].*
	LET vm_num_tot = vm_num_tot + 1
	IF vm_num_tot > vm_max_tot THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_tot = vm_num_tot - 1

END FUNCTION



FUNCTION mostrar_detalle_tot()
DEFINE i, lim		SMALLINT

FOR i = 1 TO fgl_scr_size('rm_dettot')
	CLEAR rm_dettot[i].*
END FOR
CALL calcula_total_tot()
LET lim = vm_num_tot
IF lim > fgl_scr_size('rm_dettot') THEN
	LET lim = fgl_scr_size('rm_dettot')
END IF
FOR i = 1 TO lim
	DISPLAY rm_dettot[i].* TO rm_dettot[i].*
END FOR
CALL muestra_contadores_tot(0, vm_num_tot)

END FUNCTION



FUNCTION preparar_query_fon(i)
DEFINE i		SMALLINT
DEFINE query		CHAR(5000)

CASE vm_tipo_otro
	WHEN 'A'
		LET query = query_fon2(i) CLIPPED
	WHEN 'P'
		LET query = query_fon1(i) CLIPPED
	WHEN 'T'
		LET query = query_fon1(i) CLIPPED,
				' UNION ',
				query_fon2(i) CLIPPED
END CASE
LET query = query CLIPPED, ' INTO TEMP tmp_fon '
PREPARE exec_tmp_f FROM query
EXECUTE exec_tmp_f
CALL cargar_detalle_fon()
IF vm_num_fon > 0 THEN
	CALL mostrar_detalle_fon()
END IF

END FUNCTION



FUNCTION query_fon1(i)
DEFINE i		SMALLINT
DEFINE query		CHAR(400)

LET query = 'SELECT EXTEND(n38_fecha_fin, YEAR TO MONTH) fec_fon, ',
		'"FR" cod_fon, n38_ganado_per fon_gan, ',
		'n38_valor_fondo fon_neto ',
		' FROM rolt038 ',
		' WHERE n38_compania = ', vg_codcia,
		'   AND n38_cod_trab = ', rm_detalle[i].n30_cod_trab
RETURN query CLIPPED

END FUNCTION



FUNCTION query_fon2(i)
DEFINE i		SMALLINT
DEFINE query		CHAR(5000)

LET query = ' SELECT EXTEND(CASE WHEN n32_fecha_fin <= ',
			'DATE((SELECT MDY(n03_mes_fin, n03_dia_fin, ',
				'YEAR(', subquery_fon(i) CLIPPED, ') + 1) ',
				' FROM rolt003 ',
				' WHERE n03_proceso = "FR"))',
			' THEN DATE(', subquery_fon(i) CLIPPED, ') + 1 ',
			' ELSE DATE(', subquery_fon(i) CLIPPED, ') + 2 ',
			' END, YEAR TO MONTH) fec_fon,',
		' "FR" cod_fon, NVL(SUM(n32_tot_gan), 0) fon_gan, ',
		' NVL(SUM(CASE WHEN DATE(CASE WHEN n32_fecha_fin <= ',
			'DATE((SELECT MDY(n03_mes_fin, n03_dia_fin, ',
				'YEAR(', subquery_fon(i) CLIPPED, ') + 1) ',
				' FROM rolt003 ',
				' WHERE n03_proceso = "FR"))',
			' THEN DATE(', subquery_fon(i) CLIPPED, ') + 1 ',
			' ELSE DATE(', subquery_fon(i) CLIPPED, ') + 2 ',
			' END) <= MDY(07, 31, 2009) ',
			' THEN n32_tot_gan / 12 ',
			' ELSE ',
			' CASE WHEN (SELECT n03_frecuencia FROM rolt003 ',
					'WHERE n03_proceso = "FR") = "A" ',
				' THEN n32_tot_gan / 12 ',
			     ' WHEN (SELECT n03_frecuencia FROM rolt003 ',
					'WHERE n03_proceso = "FR") = "M" ',
				' THEN n32_tot_gan * ',
					'(SELECT n07_factor ',
					'FROM rolt007 ',
					'WHERE n07_cod_rubro = ',
						'(SELECT n06_cod_rubro ',
						'FROM rolt006 ',
						'WHERE n06_flag_ident = "FM"))',
					' / 100 ',
			' END ',
		' END), 0) fon_neto ',
		' FROM rolt032 ',
		' WHERE n32_compania    = ', vg_codcia,
		'   AND n32_cod_liqrol IN ("Q1", "Q2") ',
		'   AND n32_fecha_ini  >= ', subquery_fon(i) CLIPPED,
		'   AND n32_cod_trab    = ', rm_detalle[i].n30_cod_trab,
		' GROUP BY 1 '
RETURN query CLIPPED

END FUNCTION



FUNCTION subquery_fon(i)
DEFINE i		SMALLINT
DEFINE query		CHAR(400)

LET query = 'NVL((SELECT MAX(n38_fecha_fin) ',
		' FROM rolt038 ',
		' WHERE n38_compania = n32_compania ',
		'   AND n38_cod_trab = n32_cod_trab),',
		' DATE((SELECT MDY(MONTH(n30_fecha_ing), ',
			'CASE WHEN DAY(n30_fecha_ing) > 15 ',
			'THEN 16 ELSE 1 END, YEAR(n30_fecha_ing) + 1) ',
			' FROM rolt030 ',
			' WHERE n30_compania = ', vg_codcia,
			'   AND n30_cod_trab = ', rm_detalle[i].n30_cod_trab,
			')))'
RETURN query CLIPPED

END FUNCTION



FUNCTION cargar_detalle_fon()
DEFINE query		VARCHAR(200)

LET query = 'SELECT fec_fon, fon_gan, fon_neto ',
		' FROM tmp_fon ',
		' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1], ', ',
			      vm_columna_2, ' ', rm_orden[vm_columna_2]
PREPARE c_tmp_fon FROM query	
DECLARE q_fon CURSOR FOR c_tmp_fon
LET vm_num_fon = 1
FOREACH q_fon INTO rm_detfon[vm_num_fon].*
	LET vm_num_fon = vm_num_fon + 1
	IF vm_num_fon > vm_max_fon THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_fon = vm_num_fon - 1

END FUNCTION



FUNCTION mostrar_detalle_fon()
DEFINE i, lim		SMALLINT

FOR i = 1 TO fgl_scr_size('rm_detfon')
	CLEAR rm_detfon[i].*
END FOR
CALL calcula_total_fon()
LET lim = vm_num_fon
IF lim > fgl_scr_size('rm_detfon') THEN
	LET lim = fgl_scr_size('rm_detfon')
END IF
FOR i = 1 TO lim
	DISPLAY rm_detfon[i].* TO rm_detfon[i].*
END FOR
CALL muestra_contadores_fon(0, vm_num_fon)

END FUNCTION



FUNCTION preparar_query_dec(i)
DEFINE i		SMALLINT
DEFINE query		CHAR(13500)

CASE vm_tipo_otro
	WHEN 'A'
		LET query = query_dec2(i) CLIPPED
	WHEN 'P'
		LET query = query_dec1(i) CLIPPED
	WHEN 'T'
		LET query = query_dec1(i) CLIPPED,
				' UNION ',
				query_dec2(i) CLIPPED
END CASE
LET query = query CLIPPED, ' INTO TEMP tmp_dec '
PREPARE exec_tmp_d FROM query
EXECUTE exec_tmp_d
CALL cargar_detalle_dec()
IF vm_num_dec > 0 THEN
	CALL mostrar_detalle_dec()
END IF

END FUNCTION



FUNCTION query_dec1(i)
DEFINE i		SMALLINT
DEFINE query		CHAR(2000)

LET query = 'SELECT n36_ano_proceso anio_dec, n36_proceso cod_dec, ',
		'n03_nombre_abr nom_dec, n36_ganado_real dec_gan, ',
		'n36_valor_bruto dec_brut, n36_descuentos dec_desc, ',
		'n36_valor_neto dec_neto ',
		' FROM rolt036, rolt003 ',
		' WHERE n36_compania = ', vg_codcia,
		'   AND n36_proceso  IN ("DT", "DC") ',
		'   AND n36_cod_trab = ', rm_detalle[i].n30_cod_trab,
		'   AND n03_proceso  = n36_proceso ',
		' UNION ',
		' SELECT n42_ano anio_dec, "UT" cod_dec,',
			' (SELECT n03_nombre_abr FROM rolt003 ',
				' WHERE n03_proceso = "UT") nom_dec,',
			' (n42_val_trabaj + n42_val_cargas) dec_gan,',
			' (n42_val_trabaj + n42_val_cargas) dec_brut,',
			' n42_descuentos dec_desc,',
			' (n42_val_trabaj + n42_val_cargas - n42_descuentos)',
			' dec_neto ',
			' FROM rolt042, rolt041 ',
			' WHERE n42_compania = ', vg_codcia,
			'   AND n42_cod_trab = ', rm_detalle[i].n30_cod_trab,
			'   AND n41_compania = n42_compania ',
			'   AND n41_ano      = n42_ano ',
			'   AND n41_estado   = "P" '
RETURN query CLIPPED

END FUNCTION



FUNCTION query_dec2(i)
DEFINE i		SMALLINT
DEFINE query		CHAR(10000)

LET query = ' SELECT YEAR(', subquery_dec1(i, 'YEAR','"DT"','"DT"', '') CLIPPED,
			') anio_dec,',
			' "DT" cod_dec, (SELECT n03_nombre_abr FROM rolt003 ',
					'WHERE n03_proceso = "DT") nom_dec,',
			' NVL(SUM(n32_tot_gan), 0) dec_gan,',
			' (NVL(SUM(n32_tot_gan), 0) / 12) dec_brut, ',
			subquery_desc_d(i,'"DT"','"DT"') CLIPPED, ' dec_desc,',
			' (NVL(SUM(n32_tot_gan), 0) / 12) - ',
			subquery_desc_d(i,'"DT"','"DT"') CLIPPED, ' dec_neto ',
			' FROM rolt032 ',
			' WHERE n32_compania    = ', vg_codcia,
			'   AND n32_cod_liqrol IN ("Q1", "Q2") ',
			'   AND n32_fecha_ini  >= ',
				subquery_dec1(i, 'DAY', '"DT"', '"DT"',
						'- 1') CLIPPED,
			'   AND n32_cod_trab  = ', rm_detalle[i].n30_cod_trab,
			' GROUP BY 1, 2, 3, 6 ',
		' UNION ',
		' SELECT YEAR(', subquery_dec1(i, 'YEAR', 'n03_proceso',
					'"DC"', '+ 1') CLIPPED, ') anio_dec,',
			' n03_proceso cod_dec, n03_nombre_abr nom_dec, ',
			'(n03_valor / ', rm_n90.n90_dias_anio, ') * (DATE(',
				subquery_dec2(i) CLIPPED, ') - ',
				'DATE(', subquery_dec1(i, 'DAY', 'n03_proceso',
					'"DC"', '') CLIPPED, ') + 1) dec_gan, ',
			'(n03_valor / ', rm_n90.n90_dias_anio, ') * (DATE(',
				subquery_dec2(i) CLIPPED, ') - ',
				'DATE(', subquery_dec1(i, 'DAY', 'n03_proceso',
				'"DC"', '') CLIPPED, ') + 1) dec_brut, ',
			subquery_desc_d(i,'n03_proceso','"DC"') CLIPPED,
			' dec_desc,',
			'(n03_valor / ', rm_n90.n90_dias_anio, ') * (DATE(',
				subquery_dec2(i) CLIPPED, ') - ',
				'DATE(', subquery_dec1(i, 'DAY', 'n03_proceso',
					'"DC"', '') CLIPPED, ') + 1) - ',
			subquery_desc_d(i,'n03_proceso','"DC"') CLIPPED,
			' dec_neto ',
			' FROM rolt003 ',
			' WHERE n03_proceso = "DC" '
RETURN query CLIPPED

END FUNCTION



FUNCTION subquery_dec1(i, expr, expr2, expr3, varia)
DEFINE i		SMALLINT
DEFINE expr		CHAR(6)
DEFINE expr2		CHAR(15)
DEFINE expr3		CHAR(5)
DEFINE varia		CHAR(3)
DEFINE query		CHAR(500)
DEFINE u		VARCHAR(1)

LET u = '1'
IF expr = 'DAY' THEN
	LET u = '2'
END IF
LET query = 'NVL((SELECT CASE WHEN EXTEND(MAX(n36_fecha_fin), MONTH TO DAY)',
			' = "02-29"',
			' THEN MAX(n36_fecha_fin) - 1 UNITS DAY + ',u,' UNITS ',
				expr CLIPPED,
			' ELSE MAX(n36_fecha_fin) + 1 UNITS ', expr CLIPPED,
			' END ',
		' FROM rolt036 ',
		' WHERE n36_compania = ', vg_codcia,
		'   AND n36_proceso  = ', expr2 CLIPPED,
		'   AND n36_cod_trab = ', rm_detalle[i].n30_cod_trab, '),',
		' DATE((SELECT MDY(n03_mes_ini, n03_dia_ini, ',
			'YEAR(TODAY) ', varia CLIPPED, ') ',
			' FROM rolt003 ',
			' WHERE n03_proceso = ', expr3 CLIPPED, ')))'
RETURN query CLIPPED

END FUNCTION



FUNCTION subquery_dec2(i)
DEFINE i		SMALLINT
DEFINE query		CHAR(200)

LET query = '(SELECT MAX(n32_fecha_fin) ',
		' FROM rolt032 ',
		' WHERE n32_compania    = ', vg_codcia,
		'   AND n32_cod_liqrol IN ("Q1", "Q2") ',
		'   AND n32_cod_trab    = ', rm_detalle[i].n30_cod_trab, ')'
RETURN query CLIPPED

END FUNCTION



FUNCTION subquery_desc_d(i, expr2, expr3)
DEFINE i		SMALLINT
DEFINE expr2		CHAR(15)
DEFINE expr3		CHAR(5)
DEFINE varia		CHAR(3)
DEFINE query		CHAR(1400)

LET varia = '+ 1'
IF expr3 = 'DT' THEN
	LET varia = '- 1'
END IF
LET query = '((SELECT NVL(SUM(n46_saldo), 0) ',
		' FROM rolt045, rolt046 ',
		' WHERE n45_compania    = ', vg_codcia,
		'   AND n45_cod_trab    = ', rm_detalle[i].n30_cod_trab,
		'   AND n45_estado     IN ("R", "A") ',
		'   AND n46_compania    = n45_compania ',
		'   AND n46_num_prest   = n45_num_prest ',
		'   AND n46_cod_liqrol  = ', expr3 CLIPPED,
		'   AND n46_fecha_ini  >= ',
			subquery_dec1(i, 'DAY', expr2, expr3, varia) CLIPPED,
		'   AND n46_fecha_fin  <= ',
			subquery_dec1(i, 'YEAR', expr2, expr3, varia) CLIPPED,
		'   AND n46_saldo       > 0) + ',
		'NVL((SELECT SUM(n10_valor) ',
			' FROM rolt010 ',
			' WHERE n10_compania   = ', vg_codcia,
			'   AND n10_cod_liqrol = ', expr3 CLIPPED,
			'   AND n10_cod_trab   = ', rm_detalle[i].n30_cod_trab,
			'), 0))'
RETURN query CLIPPED

END FUNCTION



FUNCTION cargar_detalle_dec()
DEFINE query		VARCHAR(200)

LET query = 'SELECT anio_dec, cod_dec, nom_dec, dec_gan, dec_brut, dec_desc, ',
		'dec_neto ',
		' FROM tmp_dec ',
		' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1], ', ',
			      vm_columna_2, ' ', rm_orden[vm_columna_2]
PREPARE c_tmp_dec FROM query	
DECLARE q_dec CURSOR FOR c_tmp_dec
LET vm_num_dec = 1
FOREACH q_dec INTO rm_detdec[vm_num_dec].*
	LET vm_num_dec = vm_num_dec + 1
	IF vm_num_dec > vm_max_dec THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_dec = vm_num_dec - 1

END FUNCTION



FUNCTION mostrar_detalle_dec()
DEFINE i, lim		SMALLINT

FOR i = 1 TO fgl_scr_size('rm_detdec')
	CLEAR rm_detdec[i].*
END FOR
CALL calcula_total_dec()
LET lim = vm_num_dec
IF lim > fgl_scr_size('rm_detdec') THEN
	LET lim = fgl_scr_size('rm_detdec')
END IF
FOR i = 1 TO lim
	DISPLAY rm_detdec[i].* TO rm_detdec[i].*
END FOR
CALL muestra_contadores_dec(0, vm_num_dec)

END FUNCTION



FUNCTION preparar_query_vac(i)
DEFINE i		SMALLINT
DEFINE query		CHAR(12000)

LET query = 'SELECT n30_compania, n30_cod_trab, n30_cod_depto, n30_mon_sueldo,',
		' n30_bco_empresa, n30_cta_empresa, n30_cta_trabaj, ',
		' CASE WHEN EXTEND(n30_fecha_ing, MONTH TO DAY) = "02-29"',
		' THEN MDY(MONTH(n30_fecha_ing), 28, YEAR(n30_fecha_ing))',
		' ELSE n30_fecha_ing',
		' END n30_fecha_ing, n30_cod_seguro ',
		' FROM rolt030 ',
		' WHERE n30_compania  = ', vg_codcia,
		'   AND n30_tipo_trab = "N" ',
		' INTO TEMP tmp_n30 '
PREPARE exec_n30 FROM query
EXECUTE exec_n30
CASE vm_tipo_otro
	WHEN 'A'
		LET query = query_vac2(i) CLIPPED
	WHEN 'P'
		LET query = query_vac1(i) CLIPPED
	WHEN 'T'
		LET query = query_vac1(i) CLIPPED,
				' UNION ',
				query_vac2(i) CLIPPED
END CASE
LET query = query CLIPPED, ' INTO TEMP t1 '
PREPARE exec_t1 FROM query
EXECUTE exec_t1
LET query = 'SELECT anio_vac, d_v, d_a, tot_dias, d_g, d_p, tot_gan,',
		' val_brut + ',
		' CASE WHEN anio_vac = YEAR(', subquery_vac(i) CLIPPED, ') + 1',
			' THEN (val_brut / d_v) * d_a ',
			' ELSE 0.00 ',
			' END val_brut, ',
		' val_desc + ',
		' CASE WHEN anio_vac = YEAR(', subquery_vac(i) CLIPPED, ') + 1',
			' THEN ((val_brut / d_v) * d_a) * ',
				'(SELECT n13_porc_trab',
				' FROM tmp_n30, rolt013 ',
				' WHERE n30_compania = ', vg_codcia,
				'   AND n30_cod_trab = ',
					rm_detalle[i].n30_cod_trab,
				'   AND n13_cod_seguro = n30_cod_seguro) / 100',
			' ELSE 0.00 ',
			' END + ',
		' CASE WHEN anio_vac = YEAR(', subquery_vac(i) CLIPPED, ') + 1',
			' THEN ', subquery_desc_v(i) CLIPPED,
			' ELSE 0.00 ',
			' END val_desc, ',
		' vac_net + ',
		' CASE WHEN anio_vac = YEAR(', subquery_vac(i) CLIPPED, ') + 1',
			' THEN ((val_brut / d_v) * d_a) - ',
				'(((val_brut / d_v) * d_a) * ',
				'(SELECT n13_porc_trab',
				' FROM tmp_n30, rolt013 ',
				' WHERE n30_compania = ', vg_codcia,
				'   AND n30_cod_trab = ',
					rm_detalle[i].n30_cod_trab,
				'  AND n13_cod_seguro = n30_cod_seguro) / 100)',
			' ELSE 0.00 ',
			' END - ',
		' CASE WHEN anio_vac = YEAR(', subquery_vac(i) CLIPPED, ') + 1',
			' THEN ', subquery_desc_v(i) CLIPPED,
			' ELSE 0.00 ',
			' END vac_net, cod_vac ',
		' FROM t1 ',
		' INTO TEMP tmp_vac '
PREPARE exec_tmp FROM query
EXECUTE exec_tmp
DROP TABLE t1
DROP TABLE tmp_n30
CALL cargar_detalle_vac()
IF vm_num_vac > 0 THEN
	CALL mostrar_detalle_vac()
END IF

END FUNCTION



FUNCTION query_vac1(i)
DEFINE i		SMALLINT
DEFINE query		CHAR(1000)

LET query = 'SELECT n39_ano_proceso anio_vac, n39_dias_vac d_v, ',
		'n39_dias_adi d_a, (n39_dias_vac + n39_dias_adi) tot_dias, ',
		'n39_dias_goza d_g, (n39_dias_vac + n39_dias_adi) - ',
		'NVL(n39_dias_goza, 0) d_p, n39_tot_ganado tot_gan, ',
		'(n39_valor_vaca + n39_valor_adic + n39_otros_ing) val_brut, ',
		'(n39_descto_iess + n39_otros_egr) val_desc, n39_neto vac_net,',
		' n39_proceso cod_vac ',
		' FROM rolt039 ',
		' WHERE n39_compania  = ', vg_codcia,
		'   AND n39_proceso  IN ("VA", "VP") ',
		'   AND n39_cod_trab  = ', rm_detalle[i].n30_cod_trab
RETURN query CLIPPED

END FUNCTION



FUNCTION query_vac2(i)
DEFINE i		SMALLINT
DEFINE expr_adi		CHAR(3000)
DEFINE query		CHAR(8000)

LET expr_adi = ' CASE WHEN (MDY(MONTH(n30_fecha_ing), ',
			'DAY(n30_fecha_ing), YEAR(', subquery_vac(i) CLIPPED,
						') + 1)) >= ',
			'(n30_fecha_ing + (n00_ano_adi_vac',
			' - 1) UNITS YEAR - 1 UNITS DAY)',
		' THEN ',
		'CASE WHEN (n00_dias_vacac + ((YEAR(MDY(MONTH(',
			'n30_fecha_ing), DAY(n30_fecha_ing), YEAR(',
			subquery_vac(i) CLIPPED, ') + 1)) - ',
			'YEAR(n30_fecha_ing + ',
			'(n00_ano_adi_vac - 1) UNITS YEAR - ',
			'1 UNITS DAY)) * n00_dias_adi_va)) > ',
			'n00_max_vacac ',
			'THEN n00_max_vacac - n00_dias_vacac ',
			'ELSE ((YEAR(MDY(MONTH(n30_fecha_ing), ',
				'DAY(n30_fecha_ing), YEAR(',
				subquery_vac(i) CLIPPED,') + 1)) -',
					'YEAR(n30_fecha_ing + (n00_ano_adi_vac',
					' - 1) UNITS YEAR - 1 UNITS DAY)) *',
					' n00_dias_adi_va)',
			' END',
		' ELSE 0 ',
		' END '
LET query = ' SELECT YEAR(', subquery_vac(i) CLIPPED, ') + 1 anio_vac,',
			' n00_dias_vacac d_v,',
			expr_adi CLIPPED, ' d_a,',
			' n00_dias_vacac +',
			expr_adi CLIPPED, ' tot_dias, 0 d_g, 0 d_p,',
			' NVL(SUM(n32_tot_gan), 0) tot_gan,',
			' (NVL(SUM(n32_tot_gan), 0) / 24) val_brut, ',
			' (NVL(SUM(n32_tot_gan * n13_porc_trab / 100),0) / 24)',
			' val_desc, ',
			' (NVL(SUM(n32_tot_gan), 0) / 24) -',
			' (NVL(SUM(n32_tot_gan * n13_porc_trab / 100),0) / 24)',
			' vac_net, "VA" cod_vac ',
			' FROM rolt032, tmp_n30, rolt013, rolt000 ',
			' WHERE n32_compania    = ', vg_codcia,
			'   AND n32_cod_liqrol IN ("Q1", "Q2") ',
			'   AND n32_fecha_ini  >= ',
				subquery_vac(i) CLIPPED,
			'   AND n32_cod_trab    = ', rm_detalle[i].n30_cod_trab,
			'   AND n30_compania    = n32_compania ',
			'   AND n30_cod_trab    = n32_cod_trab ',
			'   AND n13_cod_seguro  = n30_cod_seguro ',
			'   AND n00_serial      = n30_compania ',
			' GROUP BY 1, 2, 3, 4, 5, 6, 11 '
RETURN query CLIPPED

END FUNCTION



FUNCTION subquery_vac(i)
DEFINE i		SMALLINT
DEFINE query		CHAR(400)

LET query = 'NVL((SELECT MAX(n39_perfin_real) ',
		' FROM rolt039 ',
		' WHERE n39_compania  = ', vg_codcia,
		'   AND n39_proceso  IN ("VA", "VP") ',
		'   AND n39_cod_trab  = ', rm_detalle[i].n30_cod_trab, '),',
		' DATE((SELECT MDY(MONTH(a.n30_fecha_ing), ',
			'CASE WHEN DAY(a.n30_fecha_ing) > 15 ',
			'THEN 16 ELSE 1 END, YEAR(a.n30_fecha_ing)) ',
			' FROM tmp_n30 a',
			' WHERE a.n30_compania = ', vg_codcia,
			'   AND a.n30_cod_trab = ', rm_detalle[i].n30_cod_trab,
			')))'
RETURN query CLIPPED

END FUNCTION



FUNCTION subquery_desc_v(i)
DEFINE i		SMALLINT
DEFINE query		CHAR(1800)

LET query = '((SELECT NVL(SUM(n46_saldo), 0) ',
		' FROM rolt045, rolt046 ',
		' WHERE n45_compania    = ', vg_codcia,
		'   AND n45_cod_trab    = ', rm_detalle[i].n30_cod_trab,
		'   AND n45_estado     IN ("R", "A") ',
		'   AND n46_compania    = n45_compania ',
		'   AND n46_num_prest   = n45_num_prest ',
		'   AND n46_cod_liqrol IN ("VA", "VP") ',
		'   AND n46_fecha_ini  >= ', subquery_vac(i) CLIPPED,
						' + 1 UNITS DAY',
		'   AND n46_fecha_fin  <= ', subquery_vac(i) CLIPPED,
						' + 1 UNITS YEAR',
				{-- ARREGLAR POR ANIO BISIESTO
						' + CASE WHEN EXTEND(DATE(',
						subquery_vac(i) CLIPPED, '),',
						' MONTH TO DAY) = "02-29"',
						' THEN 365 UNITS DAY ',
						' ELSE 1 UNITS YEAR ',
						' END ',
				--}
		'   AND n46_saldo       > 0) + ',
		'NVL((SELECT SUM(n10_valor) ',
			' FROM rolt010 ',
			' WHERE n10_compania    = ', vg_codcia,
			'   AND n10_cod_liqrol IN ("VA", "VP") ',
			'   AND n10_cod_trab    = ', rm_detalle[i].n30_cod_trab,
			'), 0))'
RETURN query CLIPPED

END FUNCTION



FUNCTION cargar_detalle_vac()
DEFINE query		VARCHAR(200)

LET query = 'SELECT anio_vac, d_v, d_a, tot_dias, d_g, d_p, tot_gan, val_brut,',
		' val_desc, vac_net ',
		' FROM tmp_vac ',
		' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1], ', ',
			      vm_columna_2, ' ', rm_orden[vm_columna_2]
PREPARE tmp_d FROM query	
DECLARE q_vac CURSOR FOR tmp_d
LET vm_num_vac = 1
FOREACH q_vac INTO rm_detvac[vm_num_vac].*
	LET vm_num_vac = vm_num_vac + 1
	IF vm_num_vac > vm_max_vac THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_vac = vm_num_vac - 1

END FUNCTION



FUNCTION mostrar_detalle_vac()
DEFINE i, lim		SMALLINT

FOR i = 1 TO fgl_scr_size('rm_detvac')
	CLEAR rm_detvac[i].*
END FOR
CALL calcula_total_vac()
LET lim = vm_num_vac
IF lim > fgl_scr_size('rm_detvac') THEN
	LET lim = fgl_scr_size('rm_detvac')
END IF
FOR i = 1 TO lim
	DISPLAY rm_detvac[i].* TO rm_detvac[i].*
END FOR
CALL muestra_contadores_vac(0, vm_num_vac)

END FUNCTION



FUNCTION control_resumen(i)
DEFINE i		SMALLINT

WHILE TRUE
	CALL cargar_detalle_tot()
	CALL ubicarse_detalle_tot(i)
	IF int_flag THEN
		EXIT WHILE
	END IF
END WHILE
CALL mostrar_detalle_tot()

END FUNCTION



FUNCTION control_fondo_reserva(i)
DEFINE i		SMALLINT

WHILE TRUE
	CALL cargar_detalle_fon()
	CALL ubicarse_detalle_fon(i)
	IF int_flag THEN
		EXIT WHILE
	END IF
END WHILE
CALL mostrar_detalle_fon()

END FUNCTION



FUNCTION control_decimos(i)
DEFINE i		SMALLINT

WHILE TRUE
	CALL cargar_detalle_dec()
	CALL ubicarse_detalle_dec(i)
	IF int_flag THEN
		EXIT WHILE
	END IF
END WHILE
CALL mostrar_detalle_dec()

END FUNCTION



FUNCTION control_vacaciones(i)
DEFINE i		SMALLINT

WHILE TRUE
	CALL cargar_detalle_vac()
	CALL ubicarse_detalle_vac(i)
	IF int_flag THEN
		EXIT WHILE
	END IF
END WHILE
CALL mostrar_detalle_vac()

END FUNCTION



FUNCTION ubicarse_detalle_tot(l)
DEFINE l		SMALLINT
DEFINE i, j, col	SMALLINT

CALL calcula_total_tot()
LET int_flag = 0
CALL set_count(vm_num_tot)
DISPLAY ARRAY rm_dettot TO rm_dettot.*
       	ON KEY(INTERRUPT)   
		LET int_flag = 1
       	        EXIT DISPLAY  
	ON KEY(F5)
		LET i = arr_curr()
		IF rm_dettot[i].tot_cod <> 'UT' THEN
			CALL ver_tot_gan_liq(rm_dettot[i].tot_cod, 0, 0, l)
			LET int_flag = 0
		END IF
	ON KEY(F15)
		LET col = 1
		EXIT DISPLAY
	ON KEY(F16)
		LET col = 2
		EXIT DISPLAY
	ON KEY(F17)
		LET col = 3
		EXIT DISPLAY
	--#BEFORE DISPLAY 
		--#CALL dialog.keysetlabel('ACCEPT', '')   
		--#CALL dialog.keysetlabel("F1","") 
		--#CALL dialog.keysetlabel("CONTROL-W","") 
		--#CALL dialog.keysetlabel('RETURN', '')   
	--#BEFORE ROW 
		--#LET i = arr_curr()	
		--#LET j = scr_line()
		--#CALL muestra_contadores_tot(i, vm_num_tot)
		--#IF rm_dettot[i].tot_cod <> 'UT' THEN
			--#CALL dialog.keysetlabel("F5","Detalle Tot. Gan.") 
		--#ELSE
			--#CALL dialog.keysetlabel("F5","") 
		--#END IF
        --#AFTER DISPLAY  
                --#CONTINUE DISPLAY  
END DISPLAY
IF int_flag = 1 THEN
	RETURN
END IF
IF col <> vm_columna_1 THEN
	LET vm_columna_2           = vm_columna_1 
	LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
	LET vm_columna_1           = col 
END IF
IF rm_orden[vm_columna_1] = 'ASC' THEN
	LET rm_orden[vm_columna_1] = 'DESC'
ELSE
	LET rm_orden[vm_columna_1] = 'ASC'
END IF

END FUNCTION



FUNCTION calcula_total_tot()
DEFINE i		SMALLINT

LET rm_totales.total01 = 0
FOR i = 1 TO vm_num_tot
	LET rm_totales.total01 = rm_totales.total01 + rm_dettot[i].tot_val
END FOR
DISPLAY BY NAME rm_totales.*

END FUNCTION



FUNCTION muestra_contadores_tot(num_row1, max_row1)
DEFINE num_row1, max_row1	SMALLINT

DISPLAY BY NAME num_row1, max_row1

END FUNCTION



FUNCTION ubicarse_detalle_fon(l)
DEFINE l		SMALLINT
DEFINE i, j, col	SMALLINT

CALL calcula_total_fon()
LET int_flag = 0
CALL set_count(vm_num_fon)
DISPLAY ARRAY rm_detfon TO rm_detfon.*
       	ON KEY(INTERRUPT)   
		LET int_flag = 1
       	        EXIT DISPLAY  
	ON KEY(F5)
		LET i = arr_curr()
		CALL ver_tot_gan_liq('FR', YEAR(rm_detfon[i].fon_fecha),
					MONTH(rm_detfon[i].fon_fecha), l)
		LET int_flag = 0
	ON KEY(F18)
		LET col = 1
		EXIT DISPLAY
	ON KEY(F19)
		LET col = 2
		EXIT DISPLAY
	ON KEY(F20)
		LET col = 3
		EXIT DISPLAY
	--#BEFORE DISPLAY 
		--#CALL dialog.keysetlabel('ACCEPT', '')   
		--#CALL dialog.keysetlabel("F1","") 
		--#CALL dialog.keysetlabel("F5","Detalle Tot. Gan.") 
		--#CALL dialog.keysetlabel("CONTROL-W","") 
		--#CALL dialog.keysetlabel('RETURN', '')   
	--#BEFORE ROW 
		--#LET i = arr_curr()	
		--#LET j = scr_line()
		--#CALL muestra_contadores_fon(i, vm_num_fon)
        --#AFTER DISPLAY  
                --#CONTINUE DISPLAY  
END DISPLAY
IF int_flag = 1 THEN
	RETURN
END IF
IF col <> vm_columna_1 THEN
	LET vm_columna_2           = vm_columna_1 
	LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
	LET vm_columna_1           = col 
END IF
IF rm_orden[vm_columna_1] = 'ASC' THEN
	LET rm_orden[vm_columna_1] = 'DESC'
ELSE
	LET rm_orden[vm_columna_1] = 'ASC'
END IF

END FUNCTION



FUNCTION calcula_total_fon()
DEFINE i		SMALLINT

LET rm_totales.total02 = 0
LET rm_totales.total03 = 0
FOR i = 1 TO vm_num_fon
	LET rm_totales.total02 = rm_totales.total02 + rm_detfon[i].fon_gana
	LET rm_totales.total03 = rm_totales.total03 + rm_detfon[i].fon_neto
END FOR
DISPLAY BY NAME rm_totales.*

END FUNCTION



FUNCTION muestra_contadores_fon(num_row2, max_row2)
DEFINE num_row2, max_row2	SMALLINT

DISPLAY BY NAME num_row2, max_row2

END FUNCTION



FUNCTION ubicarse_detalle_dec(l)
DEFINE l		SMALLINT
DEFINE i, j, col	SMALLINT

CALL calcula_total_dec()
LET int_flag = 0
CALL set_count(vm_num_dec)
DISPLAY ARRAY rm_detdec TO rm_detdec.*
       	ON KEY(INTERRUPT)   
		LET int_flag = 1
       	        EXIT DISPLAY  
	ON KEY(F5)
		LET i = arr_curr()
		IF rm_detdec[i].dec_cod <> 'UT' THEN
			CALL ver_tot_gan_liq(rm_detdec[i].dec_cod,
						rm_detdec[i].dec_anio, 0, l)
			LET int_flag = 0
		END IF
	ON KEY(F21)
		LET col = 1
		EXIT DISPLAY
	ON KEY(F22)
		LET col = 2
		EXIT DISPLAY
	ON KEY(F23)
		LET col = 3
		EXIT DISPLAY
	ON KEY(F24)
		LET col = 4
		EXIT DISPLAY
	ON KEY(F25)
		LET col = 5
		EXIT DISPLAY
	ON KEY(F26)
		LET col = 6
		EXIT DISPLAY
	ON KEY(F27)
		LET col = 7
		EXIT DISPLAY
	--#BEFORE DISPLAY 
		--#CALL dialog.keysetlabel('ACCEPT', '')   
		--#CALL dialog.keysetlabel("F1","") 
		--#CALL dialog.keysetlabel("CONTROL-W","") 
		--#CALL dialog.keysetlabel('RETURN', '')   
	--#BEFORE ROW 
		--#LET i = arr_curr()	
		--#LET j = scr_line()
		--#CALL muestra_contadores_dec(i, vm_num_dec)
		--#IF rm_detdec[i].dec_cod <> 'UT' THEN
			--#CALL dialog.keysetlabel("F5","Detalle Tot. Gan.") 
		--#ELSE
			--#CALL dialog.keysetlabel("F5","") 
		--#END IF
        --#AFTER DISPLAY  
                --#CONTINUE DISPLAY  
END DISPLAY
IF int_flag = 1 THEN
	RETURN
END IF
IF col <> vm_columna_1 THEN
	LET vm_columna_2           = vm_columna_1 
	LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
	LET vm_columna_1           = col 
END IF
IF rm_orden[vm_columna_1] = 'ASC' THEN
	LET rm_orden[vm_columna_1] = 'DESC'
ELSE
	LET rm_orden[vm_columna_1] = 'ASC'
END IF

END FUNCTION



FUNCTION calcula_total_dec()
DEFINE i		SMALLINT

LET rm_totales.total04 = 0
LET rm_totales.total05 = 0
LET rm_totales.total06 = 0
LET rm_totales.total07 = 0
FOR i = 1 TO vm_num_dec
	LET rm_totales.total04 = rm_totales.total04 + rm_detdec[i].dec_gana
	LET rm_totales.total05 = rm_totales.total05 + rm_detdec[i].dec_brut
	LET rm_totales.total06 = rm_totales.total06 + rm_detdec[i].dec_desc
	LET rm_totales.total07 = rm_totales.total07 + rm_detdec[i].dec_neto
END FOR
DISPLAY BY NAME rm_totales.*

END FUNCTION



FUNCTION muestra_contadores_dec(num_row3, max_row3)
DEFINE num_row3, max_row3	SMALLINT

DISPLAY BY NAME num_row3, max_row3

END FUNCTION



FUNCTION ubicarse_detalle_vac(l)
DEFINE l		SMALLINT
DEFINE i, j, col	SMALLINT
DEFINE cod_v		LIKE rolt003.n03_proceso
DEFINE r_n39		RECORD LIKE rolt039.*

CALL calcula_total_vac()
LET int_flag = 0
CALL set_count(vm_num_vac)
DISPLAY ARRAY rm_detvac TO rm_detvac.*
       	ON KEY(INTERRUPT)   
		LET int_flag = 1
       	        EXIT DISPLAY  
	ON KEY(F5)
		LET i = arr_curr()
		CALL ver_comprobante_vacaciones(i, l, 'C')
		LET int_flag = 0
	ON KEY(F6)
		LET i = arr_curr()
		CALL ver_contabilizacion(i, l)
		LET int_flag = 0
	ON KEY(F7)
		LET i = arr_curr()
		CALL ver_comprobante_vacaciones(i, l, 'G')
		LET int_flag = 0
	ON KEY(F8)
		LET i = arr_curr()
		LET cod_v = 'VA'
		IF rm_detvac[i].vac_dgoz = 0 OR rm_detvac[i].vac_desc = 0 THEN
			CALL registro_vacaciones(i, l) RETURNING r_n39.*
			IF r_n39.n39_compania IS NOT NULL THEN
				LET cod_v = r_n39.n39_proceso
			END IF
		END IF
		CALL ver_tot_gan_liq(cod_v, rm_detvac[i].vac_anio, 0, l)
		LET int_flag = 0
	ON KEY(F28)
		LET col = 1
		EXIT DISPLAY
	ON KEY(F29)
		LET col = 2
		EXIT DISPLAY
	ON KEY(F30)
		LET col = 3
		EXIT DISPLAY
	ON KEY(F31)
		LET col = 4
		EXIT DISPLAY
	ON KEY(F32)
		LET col = 5
		EXIT DISPLAY
	ON KEY(F33)
		LET col = 6
		EXIT DISPLAY
	ON KEY(F34)
		LET col = 7
		EXIT DISPLAY
	ON KEY(F35)
		LET col = 8
		EXIT DISPLAY
	ON KEY(F36)
		LET col = 9
		EXIT DISPLAY
	ON KEY(F37)
		LET col = 10
		EXIT DISPLAY
	--#BEFORE DISPLAY 
		--#CALL dialog.keysetlabel('ACCEPT', '')   
		--#CALL dialog.keysetlabel("F1","") 
		--#CALL dialog.keysetlabel("F8","Detalle Tot. Gan.") 
		--#CALL dialog.keysetlabel("CONTROL-W","") 
		--#CALL dialog.keysetlabel('RETURN', '')   
		--#CALL dialog.keysetlabel("F31","") 
		--#CALL dialog.keysetlabel("F32","") 
		--#CALL dialog.keysetlabel("F33","") 
		--#CALL dialog.keysetlabel("F34","") 
		--#CALL dialog.keysetlabel("F35","") 
		--#CALL dialog.keysetlabel("F36","") 
	--#BEFORE ROW 
		--#LET i = arr_curr()	
		--#LET j = scr_line()
		--#CALL muestra_contadores_vac(i, vm_num_vac)
        --#AFTER DISPLAY  
                --#CONTINUE DISPLAY  
END DISPLAY
IF int_flag = 1 THEN
	RETURN
END IF
IF col <> vm_columna_1 THEN
	LET vm_columna_2           = vm_columna_1 
	LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
	LET vm_columna_1           = col 
END IF
IF rm_orden[vm_columna_1] = 'ASC' THEN
	LET rm_orden[vm_columna_1] = 'DESC'
ELSE
	LET rm_orden[vm_columna_1] = 'ASC'
END IF

END FUNCTION



FUNCTION calcula_total_vac()
DEFINE i		SMALLINT

LET rm_totales.total08 = 0
LET rm_totales.total09 = 0
LET rm_totales.total10 = 0
LET rm_totales.total11 = 0
FOR i = 1 TO vm_num_vac
	LET rm_totales.total08 = rm_totales.total08 + rm_detvac[i].vac_gana
	LET rm_totales.total09 = rm_totales.total09 + rm_detvac[i].vac_brut
	LET rm_totales.total10 = rm_totales.total10 + rm_detvac[i].vac_desc
	LET rm_totales.total11 = rm_totales.total11 + rm_detvac[i].vac_neto
END FOR
DISPLAY BY NAME rm_totales.*

END FUNCTION



FUNCTION muestra_contadores_vac(num_row4, max_row4)
DEFINE num_row4, max_row4	SMALLINT

DISPLAY BY NAME num_row4, max_row4

END FUNCTION


 
FUNCTION registro_vacaciones(i, j)
DEFINE i, j		SMALLINT
DEFINE r_n39		RECORD LIKE rolt039.*
DEFINE cod_v		LIKE rolt003.n03_proceso

{
LET cod_v = 'VA'
IF rm_detvac[i].vac_dgoz = 0 AND rm_detvac[i].vac_desc = 0 THEN
	LET cod_v = 'VP'
END IF
}
INITIALIZE r_n39.* TO NULL
DECLARE q_n39 CURSOR FOR
	SELECT * FROM rolt039
		WHERE n39_compania    = vg_codcia
		  AND n39_proceso     IN ('VA', 'VP')
		  AND n39_cod_trab    = rm_detalle[j].n30_cod_trab
		  AND n39_ano_proceso = rm_detvac[i].vac_anio
		ORDER BY n39_periodo_fin DESC
OPEN q_n39
FETCH q_n39 INTO r_n39.*
CLOSE q_n39
FREE q_n39
RETURN r_n39.*

END FUNCTION


 
FUNCTION ver_comprobante_vacaciones(i, j, flag)
DEFINE i, j		SMALLINT
DEFINE flag		CHAR(1)
DEFINE param		VARCHAR(60)
DEFINE r_n39		RECORD LIKE rolt039.*

CALL registro_vacaciones(i, j) RETURNING r_n39.*
IF r_n39.n39_compania IS NULL THEN
	RETURN
END IF
LET param = ' "', r_n39.n39_estado, '" "', r_n39.n39_proceso, '" ',
		rm_detalle[j].n30_cod_trab
IF flag <> 'L' THEN
	LET param = param CLIPPED, ' "', r_n39.n39_periodo_ini, '" "',
			r_n39.n39_periodo_fin, '"'
	IF flag = 'G' THEN
		LET param = param CLIPPED, ' "G"'
	END IF
END IF
CALL ejecuta_comando('NOMINA', vg_modulo, 'rolp252 ', param)

END FUNCTION



FUNCTION ver_contabilizacion(i, j)
DEFINE i, j		SMALLINT
DEFINE r_n39		RECORD LIKE rolt039.*
DEFINE r_n57		RECORD LIKE rolt057.*
DEFINE param		VARCHAR(60)

CALL registro_vacaciones(i, j) RETURNING r_n39.*
IF r_n39.n39_compania IS NULL THEN
	RETURN
END IF
INITIALIZE r_n57.* TO NULL
SELECT * INTO r_n57.*
	FROM rolt057
	WHERE n57_compania    = vg_codcia
	  AND n57_proceso     = r_n39.n39_proceso
	  AND n57_cod_trab    = r_n39.n39_cod_trab
	  AND n57_periodo_ini =	r_n39.n39_periodo_ini
	  AND n57_periodo_fin =	r_n39.n39_periodo_fin
IF r_n57.n57_compania IS NULL THEN
	RETURN
END IF
LET param = ' "', r_n57.n57_tipo_comp, '" ', r_n57.n57_num_comp
CALL ejecuta_comando('CONTABILIDAD', 'CB', 'ctbp201 ', param)

END FUNCTION



FUNCTION ver_tot_gan_liq(cod_liqrol, anio, mes, l)
DEFINE cod_liqrol	LIKE rolt003.n03_proceso
DEFINE anio		LIKE rolt032.n32_ano_proceso
DEFINE mes		LIKE rolt032.n32_mes_proceso
DEFINE l		SMALLINT
DEFINE fec_aux		LIKE rolt032.n32_fecha_ini
DEFINE fec_ini		LIKE rolt032.n32_fecha_ini
DEFINE fec_fin		LIKE rolt032.n32_fecha_fin

IF anio <> 0 THEN
	CALL retorna_fecha_proc(cod_liqrol, anio, mes,
				rm_detalle[l].n30_cod_trab)
		RETURNING fec_ini, fec_fin
ELSE
	IF cod_liqrol[1, 1] = 'D' THEN
		SELECT MIN(anio_dec) INTO anio
			FROM tmp_dec
			WHERE cod_dec = cod_liqrol
	END IF
	CASE cod_liqrol
		WHEN 'VA' SELECT MIN(anio_vac) INTO anio FROM tmp_vac
		WHEN 'VP' SELECT MIN(anio_vac) INTO anio FROM tmp_vac
		WHEN 'FR' SELECT YEAR(MIN(fec_fon)), MONTH(MIN(fec_fon))
				INTO anio, mes
				FROM tmp_fon
	END CASE
	CALL retorna_fecha_proc(cod_liqrol, anio, mes,
				rm_detalle[l].n30_cod_trab)
		RETURNING fec_ini, fec_fin
	LET fec_aux = fec_ini
	IF cod_liqrol[1, 1] = 'D' THEN
		SELECT MAX(anio_dec) INTO anio
			FROM tmp_dec
			WHERE cod_dec = cod_liqrol
	END IF
	CASE cod_liqrol
		WHEN 'VA' SELECT MAX(anio_vac) INTO anio FROM tmp_vac
		WHEN 'VP' SELECT MAX(anio_vac) INTO anio FROM tmp_vac
		WHEN 'FR' SELECT YEAR(MAX(fec_fon)), MONTH(MAX(fec_fon))
				INTO anio, mes
				FROM tmp_fon
	END CASE
	CALL retorna_fecha_proc(cod_liqrol, anio, mes,
				rm_detalle[l].n30_cod_trab)
		RETURNING fec_ini, fec_fin
	LET fec_ini = fec_aux
END IF
IF cod_liqrol = 'DC' AND YEAR(fec_fin) = 2008 THEN
	LET fec_ini = fec_ini - 1 UNITS MONTH
	LET fec_fin = fec_ini + 1 UNITS YEAR - 1 UNITS DAY
END IF
CALL fl_valor_ganado_liquidacion(vg_codcia, cod_liqrol,
				rm_detalle[l].n30_cod_trab, fec_ini, fec_fin)

END FUNCTION



FUNCTION retorna_fecha_proc(cod_liqrol, anio, mes, cod_trab)
DEFINE cod_liqrol	LIKE rolt003.n03_proceso
DEFINE anio		LIKE rolt032.n32_ano_proceso
DEFINE mes		LIKE rolt032.n32_mes_proceso
DEFINE cod_trab		LIKE rolt032.n32_cod_trab
DEFINE fecha_ini	LIKE rolt032.n32_fecha_ini
DEFINE fecha_fin	LIKE rolt032.n32_fecha_fin
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE obtener_fec, dia	SMALLINT
DEFINE fecha		DATE

IF cod_liqrol[1, 1] = 'D' THEN
	CALL fl_retorna_rango_fechas_proceso(vg_codcia, cod_liqrol, anio - 1,12)
		RETURNING fecha_ini, fecha_fin
	LET obtener_fec = 0
	CASE cod_liqrol
		WHEN 'DC'
			IF anio < YEAR(TODAY) THEN
				LET obtener_fec = 1
			END IF
		WHEN 'DT'
			IF anio > YEAR(TODAY) THEN
				LET obtener_fec = 1
			END IF
	END CASE
	IF obtener_fec THEN
		LET fecha = NULL
		SELECT MAX(n36_fecha_fin) + 1 UNITS DAY
			INTO fecha
			FROM rolt036
			WHERE n36_compania   = vg_codcia
			  AND n36_proceso    = cod_liqrol
			  AND n36_fecha_fin <= fecha_fin
			  AND n36_estado     = 'P'
		IF fecha IS NOT NULL THEN
			LET fecha_ini = fecha
			LET fecha_fin = fecha_ini + 1 UNITS YEAR - 1 UNITS DAY
		END IF
		IF fecha IS NULL THEN
			SELECT MIN(n36_fecha_fin)
				INTO fecha
				FROM rolt036
				WHERE n36_compania = vg_codcia
				  AND n36_proceso  = cod_liqrol
				  AND n36_estado   = 'P'
			IF fecha IS NOT NULL THEN
				LET fecha_fin = fecha
				LET fecha_ini = fecha_fin - 1 UNITS YEAR
						+ 1 UNITS DAY
			END IF
		END IF
	END IF
	IF anio_bisiesto(YEAR(fecha_fin)) AND
	   EXTEND(fecha_fin, MONTH TO DAY) = '02-28'
	THEN
		LET fecha_fin = fecha_fin + 1 UNITS DAY
	END IF
END IF
IF cod_liqrol = 'VA' OR cod_liqrol = 'VP' THEN
	CALL fl_lee_trabajador_roles(vg_codcia, cod_trab) RETURNING r_n30.*
	LET dia = DAY(r_n30.n30_fecha_ing)
	IF dia > 1 AND dia < 16 THEN
		LET dia = 1
	END IF
	IF dia > 16 THEN
		LET dia = 16
	END IF
	LET fecha_ini = MDY(MONTH(r_n30.n30_fecha_ing), dia, anio - 1)
	LET fecha_fin = fecha_ini + 1 UNITS YEAR - 1 UNITS DAY
END IF
IF cod_liqrol = 'FR' THEN
	LET fecha_ini = NULL
	LET fecha_fin = NULL
	SELECT n38_fecha_ini, n38_fecha_fin
		INTO fecha_ini, fecha_fin
		FROM rolt038
		WHERE n38_compania         = vg_codcia
		  AND YEAR(n38_fecha_fin)  = anio
		  AND MONTH(n38_fecha_fin) = mes
		  AND n38_cod_trab         = cod_trab
		  AND n38_estado           = 'P'
	IF fecha_ini IS NULL THEN
		CALL fl_lee_proceso_roles(cod_liqrol) RETURNING r_n03.*
		CASE r_n03.n03_frecuencia
			WHEN 'A' LET fecha_ini = MDY(r_n03.n03_mes_ini,
						r_n03.n03_dia_ini, (anio - 1))
				 LET fecha_fin = MDY(r_n03.n03_mes_fin,
						r_n03.n03_dia_fin, anio)
			WHEN 'M' LET fecha_ini = MDY(mes,r_n03.n03_dia_ini,anio)
				 LET fecha_fin = MDY(mes,r_n03.n03_dia_fin,anio)
				 IF fecha_fin IS NULL THEN
					LET fecha_fin = fecha_ini
							+ 1 UNITS MONTH
							- 1 UNITS DAY
				 END IF
		END CASE
		IF anio > (YEAR(TODAY) + 1) THEN
			LET fecha = NULL
			SELECT MAX(n38_fecha_fin) + 1 UNITS DAY
				INTO fecha
				FROM rolt038
				WHERE n38_compania   = vg_codcia
				  AND n38_fecha_fin <= fecha_fin
				  AND n38_estado     = 'P'
			IF fecha IS NOT NULL THEN
				LET fecha_ini = fecha
				CASE r_n03.n03_frecuencia
					WHEN 'A' LET fecha_fin = fecha_ini
								+ 1 UNITS YEAR
								- 1 UNITS DAY
					WHEN 'M' LET fecha_fin = fecha_ini
								+ 1 UNITS MONTH
								- 1 UNITS DAY
				END CASE
			END IF
		END IF
	END IF
END IF
RETURN fecha_ini, fecha_fin

END FUNCTION 



FUNCTION anio_bisiesto(anio)
DEFINE anio		SMALLINT
DEFINE query		VARCHAR(200)
DEFINE valor		DECIMAL(12,2)

LET query = 'SELECT MOD(', anio, ', 4) val_mod FROM dual INTO TEMP tmp_mod '
PREPARE exec_mod FROM query
EXECUTE exec_mod
SELECT * INTO valor FROM tmp_mod
DROP TABLE tmp_mod
IF valor = 0 THEN
	RETURN 1
ELSE
	RETURN 0
END IF

END FUNCTION



FUNCTION muestra_totales_rub(pos, flag, fecha_ini, fecha_fin)
DEFINE pos, flag	SMALLINT
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE r_n33		RECORD LIKE rolt033.*
DEFINE fecha_ini	LIKE rolt032.n32_fecha_ini
DEFINE fecha_fin	LIKE rolt032.n32_fecha_fin
DEFINE i, j, max_row	SMALLINT
DEFINE tot_rub_ing	SMALLINT
DEFINE tot_rub_des	SMALLINT
DEFINE tot_trab		SMALLINT
DEFINE tot_hp 		DECIMAL(14,2) 
DEFINE tot_val 		DECIMAL(14,2) 
DEFINE total_ing	DECIMAL(14,2) 
DEFINE total_egr	DECIMAL(14,2) 
DEFINE total_net	DECIMAL(14,2) 
DEFINE total_gan	DECIMAL(14,2) 
DEFINE query		CHAR(1500)
DEFINE expr_where	CHAR(500)
DEFINE expr_where2	CHAR(500)
DEFINE expr_tablas	VARCHAR(50)
DEFINE expr_fec_i	VARCHAR(100)
DEFINE expr_fec_f	VARCHAR(100)

LET max_row    = 100
LET expr_fec_i = '   AND n32_fecha_ini  >= "', fecha_ini,  '"'
LET expr_fec_f = '   AND n32_fecha_fin  <= "', fecha_fin,  '"'
IF vm_codliq_ini IS NOT NULL AND flag <> 2 THEN
	IF vm_codliq_ini = "Q1" THEN
		LET expr_fec_i = '   AND n32_fecha_ini  >= MDY(',
			MONTH(fecha_ini), ', 01, ',
			YEAR(fecha_ini), ')'
	END IF
	IF vm_codliq_ini = "Q2" THEN
		LET expr_fec_i = '   AND n32_fecha_ini  >= MDY(',
			MONTH(fecha_ini), ', 16, ',
			YEAR(fecha_ini), ')'
	END IF
END IF
IF vm_codliq_fin IS NOT NULL AND flag <> 2 THEN
	IF vm_codliq_fin = "Q1" THEN
		LET expr_fec_f = '   AND n32_fecha_fin  <= MDY(',
			MONTH(fecha_fin), ', 15, ',
			YEAR(fecha_fin), ')'
	END IF
	IF vm_codliq_fin = "Q2" THEN
		LET expr_fec_f = '   AND n32_fecha_fin  <= MDY(',
			MONTH(fecha_fin), ', 01, ',
			YEAR(fecha_fin),
			') + 1 UNITS MONTH - 1 UNITS DAY'
	END IF
END IF
LET expr_where = ' WHERE n32_compania    = ', vg_codcia,
		 '   AND n32_cod_liqrol IN ("Q1", "Q2") ',
			expr_fec_i CLIPPED,
			expr_fec_f CLIPPED,
		 '   AND n32_estado     <> "E" '
IF flag <> 0 THEN
	IF pos > 0 THEN
		LET expr_where = expr_where CLIPPED,
		 '   AND n32_cod_trab    = ', rm_detalle[pos].n30_cod_trab
	ELSE
		LET expr_where = expr_where CLIPPED,
		 	'   AND n32_cod_trab    = ', rm_n32.n32_cod_trab
	END IF
ELSE
	IF rm_n32.n32_cod_trab IS NOT NULL THEN
		LET expr_where = expr_where CLIPPED,
		 	'   AND n32_cod_trab    = ', rm_n32.n32_cod_trab
	END IF
	IF rm_n32.n32_cod_depto IS NOT NULL THEN
		LET expr_where = expr_where CLIPPED,
		 	'   AND n32_cod_depto   = ', rm_n32.n32_cod_depto
	END IF
END IF
SELECT * FROM rolt033
	WHERE n33_compania    = vg_codcia
	  AND n33_cod_liqrol IN ("Q1", "Q2")
	  AND n33_fecha_ini  >= fecha_ini
	  AND n33_fecha_fin  <= fecha_fin
	  AND n33_cant_valor  = "V"
	INTO TEMP tmp_n33
LET query = 'SELECT COUNT(*) ',
		' FROM rolt032 ',
		expr_where CLIPPED
PREPARE scont FROM query	
DECLARE q_scont CURSOR FOR scont
OPEN q_scont
FETCH q_scont INTO tot_trab
CLOSE q_scont
FREE q_scont
LET query = 'SELECT SUM(n32_tot_ing), SUM(n32_tot_egr), SUM(n32_tot_neto), ',
		' SUM(', retorna_expr_tg(0) CLIPPED, ') ',
		' FROM rolt032 ',
		expr_where CLIPPED
PREPARE sfin FROM query	
DECLARE q_sfin CURSOR FOR sfin
OPEN q_sfin
FETCH q_sfin INTO total_ing, total_egr, total_net, total_gan
CLOSE q_sfin
FREE q_sfin
LET expr_tablas = ' FROM tmp_n33, rolt006 '
LET expr_fec_i = '   AND n33_fecha_ini  >= "', fecha_ini,  '"'
LET expr_fec_f = '   AND n33_fecha_fin  <= "', fecha_fin,  '"'
IF vm_codliq_ini IS NOT NULL THEN
	IF vm_codliq_ini = "Q1" THEN
		LET expr_fec_i = '   AND n33_fecha_ini  >= MDY(',
			MONTH(fecha_fin), ', 01, ',
			YEAR(fecha_fin), ')'
	END IF
	IF vm_codliq_ini = "Q2" THEN
		LET expr_fec_i = '   AND n33_fecha_ini  >= MDY(',
			MONTH(fecha_fin), ', 16, ',
			YEAR(fecha_fin), ')'
	END IF
END IF
IF vm_codliq_fin IS NOT NULL THEN
	IF vm_codliq_fin = "Q1" THEN
		LET expr_fec_f = '   AND n33_fecha_fin  <= MDY(',
			MONTH(fecha_fin), ', 15, ',
			YEAR(fecha_fin), ')'
	END IF
	IF vm_codliq_fin = "Q2" THEN
		LET expr_fec_f = '   AND n33_fecha_fin  <= MDY(',
			MONTH(fecha_fin), ', 01, ',
			YEAR(fecha_fin),
			') + 1 UNITS MONTH - 1 UNITS DAY'
	END IF
END IF
LET expr_where2 = ' WHERE n33_compania   = ', vg_codcia,
		  '   AND n33_cod_liqrol IN ("Q1", "Q2") ',
			expr_fec_i CLIPPED,
			expr_fec_f CLIPPED
LET expr_tablas = ' FROM rolt032, tmp_n33, rolt006 '
LET expr_where2 = expr_where CLIPPED,
		  '   AND n32_compania   = n33_compania ',
		  '   AND n32_cod_liqrol = n33_cod_liqrol ',
		  '   AND n32_fecha_ini  = n33_fecha_ini ',
		  '   AND n32_fecha_fin  = n33_fecha_fin ',
		  '   AND n32_cod_trab   = n33_cod_trab '
LET query = 'SELECT n06_imprime_0, n06_orden, n33_det_tot, n33_cod_rubro, ',
		' SUM(n33_horas_porc), SUM(n33_valor) ',
		expr_tablas CLIPPED,
		expr_where2 CLIPPED,
		'   AND n33_cant_valor = "V" ',
		'   AND n33_det_tot   IN ("DI","DE") ',
		'   AND n06_cod_rubro  = n33_cod_rubro ',
		' GROUP BY 1,2,3,4 ',
		' ORDER BY n06_orden'
PREPARE tot2 FROM query	
DECLARE q_tot2 CURSOR FOR tot2
LET tot_rub_ing = 1
LET tot_rub_des = 1
FOREACH q_tot2 INTO r_n33.n33_imprime_0, r_n33.n33_orden, r_n33.n33_det_tot,
		   r_n33.n33_cod_rubro, tot_hp, tot_val
	IF tot_val = 0 AND r_n33.n33_imprime_0 = 'N' THEN
		IF tot_hp IS NULL OR tot_hp = 0 THEN
			CONTINUE FOREACH
		END IF
	END IF
	CALL fl_lee_rubro_roles(r_n33.n33_cod_rubro) RETURNING r_n06.*
	IF r_n33.n33_det_tot = 'DI' THEN
		LET rm_toting[tot_rub_ing].codrub_h = r_n33.n33_cod_rubro
		LET rm_toting[tot_rub_ing].nomrub_h = r_n06.n06_nombre_abr
		LET rm_toting[tot_rub_ing].valaux_h = tot_hp
		LET rm_toting[tot_rub_ing].valrub_h = tot_val
		LET tot_rub_ing                     = tot_rub_ing + 1
	END IF
	IF r_n33.n33_det_tot = 'DE' THEN
		LET rm_totdes[tot_rub_des].codrub_d = r_n33.n33_cod_rubro
		LET rm_totdes[tot_rub_des].nomrub_d = r_n06.n06_nombre_abr
		LET rm_totdes[tot_rub_des].valrub_d = tot_val
		LET tot_rub_des                     = tot_rub_des + 1
	END IF
	IF tot_rub_ing > max_row OR tot_rub_des > max_row THEN
		EXIT FOREACH
	END IF
END FOREACH
DROP TABLE tmp_n33
LET tot_rub_ing = tot_rub_ing - 1
LET tot_rub_des = tot_rub_des - 1
IF tot_rub_ing + tot_rub_des = 0 THEN
	RETURN
END IF
OPEN WINDOW w_rolf302_7 AT 03, 02 WITH FORM '../forms/rolf302_7'
	ATTRIBUTE(BORDER, FORM LINE FIRST, COMMENT LINE LAST)
CALL mostrar_botones_detalle3()
IF flag <> 2 THEN
	IF vm_codliq_ini IS NOT NULL THEN
		IF vm_codliq_ini = "Q2" THEN
			LET fecha_ini = MDY(MONTH(fecha_ini), 16,
						YEAR(fecha_ini))
		END IF
	END IF
	IF vm_codliq_fin IS NOT NULL THEN
		IF vm_codliq_fin = "Q1" THEN
			LET fecha_fin = MDY(MONTH(fecha_fin), 15,
						YEAR(fecha_fin))
		END IF
	END IF
END IF
CALL datos_defaults3(pos, flag, fecha_ini, fecha_fin)
LET i = tot_rub_des
IF i > fgl_scr_size('rm_totdes') THEN
	LET i = fgl_scr_size('rm_totdes')
END IF
IF i > 0 THEN
	FOR j = 1 TO i
		DISPLAY rm_totdes[j].* TO rm_totdes[j].*
	END FOR
END IF
DISPLAY BY NAME total_ing, total_egr, total_net, total_gan, tot_trab
CALL muestra_contadores_tot2(1, tot_rub_ing, 0, tot_rub_des)
WHILE TRUE
	LET int_flag = 0
	CALL set_count(tot_rub_ing)
	DISPLAY ARRAY rm_toting TO rm_toting.*
       		ON KEY(INTERRUPT)   
			LET int_flag = 1
       	        	EXIT DISPLAY  
		ON KEY(F5)
			IF tot_rub_des > 0 THEN
				LET int_flag = 0
				EXIT DISPLAY
			END IF
		ON KEY(F6)
			LET i = arr_curr()
			IF rm_n32.n32_cod_trab IS NOT NULL THEN
				CALL ver_detalle_rubro_tot(pos,
						rm_toting[i].codrub_h,
						flag, fecha_ini, fecha_fin)
			ELSE
				CALL ver_detalle_rubro_tot2(pos,
						rm_toting[i].codrub_h,
						fecha_ini, fecha_fin)
			END IF
			LET int_flag = 0
		ON KEY(F7)
			CALL imprimir_rubros('C', fecha_ini, fecha_fin, 'I')
			LET int_flag = 0
		ON KEY(F8)
			IF rm_n32.n32_cod_trab IS NULL AND
			   rm_n32.n32_cod_depto IS NULL
			THEN
				CALL imprimir_rubros('L', fecha_ini, fecha_fin,
							'I')
				LET int_flag = 0
			END IF
		ON KEY(F9)
			CALL imprimir_rubros('C', fecha_ini, fecha_fin, 'T')
			LET int_flag = 0
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#CALL muestra_contadores_tot2(i, tot_rub_ing, 0,
							--#tot_rub_des)
		--#BEFORE DISPLAY 
			--#CALL dialog.keysetlabel("ACCEPT", "") 
			--#CALL dialog.keysetlabel("F5", "Descuentos") 
			--#CALL dialog.keysetlabel("F6", "Detalle") 
			--#CALL dialog.keysetlabel("F7", "Imprimir Rec. Tot.") 
			--#IF rm_n32.n32_cod_trab IS NULL AND
			--#   rm_n32.n32_cod_depto IS NULL
			--#THEN
				--#CALL dialog.keysetlabel("F8", "Imprimir Rubros") 
			--#ELSE
				--#CALL dialog.keysetlabel("F8", "")
			--#END IF
			--#CALL dialog.keysetlabel("F9", "Imprimir Totales") 
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	CALL set_count(tot_rub_des)
	DISPLAY ARRAY rm_totdes TO rm_totdes.*
       		ON KEY(INTERRUPT)   
			LET int_flag = 1
       	        	EXIT DISPLAY  
		ON KEY(F5)
			IF tot_rub_des > 0 THEN
				LET int_flag = 0
				EXIT DISPLAY
			END IF
		ON KEY(F6)
			LET i = arr_curr()
			IF rm_n32.n32_cod_trab IS NOT NULL THEN
				CALL ver_detalle_rubro_tot(pos,
						rm_totdes[i].codrub_d,
						flag, fecha_ini, fecha_fin)
			ELSE
				CALL ver_detalle_rubro_tot2(pos,
						rm_totdes[i].codrub_d,
						fecha_ini, fecha_fin)
			END IF
			LET int_flag = 0
		ON KEY(F7)
			CALL imprimir_rubros('C', fecha_ini, fecha_fin, 'D')
			LET int_flag = 0
		ON KEY(F8)
			IF rm_n32.n32_cod_trab IS NULL AND
			   rm_n32.n32_cod_depto IS NULL
			THEN
				CALL imprimir_rubros('L', fecha_ini, fecha_fin,
							'D')
				LET int_flag = 0
			END IF
		ON KEY(F9)
			CALL imprimir_rubros('C', fecha_ini, fecha_fin, 'T')
			LET int_flag = 0
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#CALL muestra_contadores_tot2(0, tot_rub_ing, i,
							--#tot_rub_des)
		--#BEFORE DISPLAY 
			--#CALL dialog.keysetlabel("ACCEPT", "") 
			--#CALL dialog.keysetlabel("F5", "Ingresos") 
			--#CALL dialog.keysetlabel("F6", "Detalle") 
			--#CALL dialog.keysetlabel("F7", "Imprimir Rec. Tot.") 
			--#IF rm_n32.n32_cod_trab IS NULL AND
			--#   rm_n32.n32_cod_depto IS NULL
			--#THEN
				--#CALL dialog.keysetlabel("F8", "Imprimir Rubros") 
			--#ELSE
				--#CALL dialog.keysetlabel("F8", "")
			--#END IF
			--#CALL dialog.keysetlabel("F9", "Imprimir Totales") 
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
END WHILE
CLOSE WINDOW w_rolf302_7

END FUNCTION



FUNCTION muestra_contadores_tot2(ini_h, fin_h, ini_d, fin_d)
DEFINE ini_h, fin_h	SMALLINT
DEFINE ini_d, fin_d	SMALLINT

DISPLAY BY NAME ini_h, fin_h, ini_d, fin_d

END FUNCTION



FUNCTION ver_detalle_rubro_tot(pos, codrub, flag, fecha_ini, fecha_fin)
DEFINE pos		SMALLINT
DEFINE codrub		LIKE rolt033.n33_cod_rubro
DEFINE flag		SMALLINT
DEFINE fecha_ini	LIKE rolt033.n33_fecha_ini
DEFINE fecha_fin	LIKE rolt033.n33_fecha_fin
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE query		CHAR(1200)
DEFINE expr_val		VARCHAR(100)
DEFINE tot_hor, total	DECIMAL(14,2)
DEFINE num_row, max_row	SMALLINT
DEFINE cambio, flag2	SMALLINT

LET max_row = 500
OPEN WINDOW w_rolf302_8 AT 03,12
	WITH FORM '../../NOMINA/forms/rolf302_8'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 0, BORDER)
--#DISPLAY "LQ"		TO tit_col1
--#DISPLAY "Fecha Ini."	TO tit_col2
--#DISPLAY "Fecha Fin."	TO tit_col3
--#DISPLAY "D/H"	TO tit_col4
--#DISPLAY "Valor"	TO tit_col5
LET flag2 = 2
IF flag THEN
	LET flag2 = 1
END IF
CALL datos_defaults3(pos, flag2, fecha_ini, fecha_fin)
CALL fl_lee_rubro_roles(codrub) RETURNING r_n06.*
DISPLAY BY NAME r_n06.n06_cod_rubro, r_n06.n06_nombre
LET expr_val = NULL
IF r_n06.n06_det_tot <> 'DI' THEN
	LET expr_val = '   AND n33_valor       > 0 '
END IF
LET query = 'SELECT n33_cod_liqrol, n33_fecha_ini, n33_fecha_fin, ',
			'n33_horas_porc, n33_valor ',
		' FROM rolt033 ',
		' WHERE n33_compania    = ', vg_codcia,
		'   AND n33_cod_liqrol IN ("Q1", "Q2") ',
		'   AND n33_fecha_ini  >= "', fecha_ini, '"',
		'   AND n33_fecha_fin  <= "', fecha_fin, '"'
LET cambio = 0
IF flag THEN
	IF pos > 0 THEN
		LET query = query CLIPPED,
		'   AND n33_cod_trab    = ', rm_detalle[pos].n30_cod_trab
	ELSE
		LET query = query CLIPPED,
			'   AND n33_cod_trab    = ', rm_n32.n32_cod_trab
	END IF
ELSE
	IF rm_n32.n32_cod_trab IS NULL THEN
		LET rm_n32.n32_cod_trab = rm_totrub2[pos].n32_cod_trab
		LET cambio              = 1
	END IF
	LET query = query CLIPPED,
			'   AND n33_cod_trab    = ', rm_n32.n32_cod_trab
END IF
LET query = query CLIPPED,
		'   AND n33_cod_rubro   = ', codrub,
		expr_val CLIPPED,
		' ORDER BY n33_fecha_fin '
PREPARE det_tr FROM query	
DECLARE q_det_tr CURSOR FOR det_tr
LET num_row = 1
LET tot_hor = 0
LET total   = 0
FOREACH q_det_tr INTO rm_totrub[num_row].*
	IF vm_codliq_ini IS NOT NULL AND flag <> 2 THEN
		IF rm_totrub[num_row].n32_cod_liqrol <  vm_codliq_ini AND
		   rm_totrub[num_row].n33_fecha_ini  <= fecha_ini
		THEN
			CONTINUE FOREACH
		END IF
	END IF
	IF vm_codliq_fin IS NOT NULL AND flag <> 2 THEN
		IF rm_totrub[num_row].n32_cod_liqrol >  vm_codliq_fin AND
		   rm_totrub[num_row].n33_fecha_fin  >= fecha_fin
		THEN
			CONTINUE FOREACH
		END IF
	END IF
	IF rm_totrub[num_row].n33_horas_porc = 0 THEN
		LET rm_totrub[num_row].n33_horas_porc = NULL
	END IF
	IF rm_totrub[num_row].n33_horas_porc IS NULL AND
	   rm_totrub[num_row].n33_valor = 0
	THEN
		CONTINUE FOREACH
	END IF
	LET total   = total + rm_totrub[num_row].n33_valor
	IF rm_totrub[num_row].n33_horas_porc IS NOT NULL THEN
		LET tot_hor = tot_hor + rm_totrub[num_row].n33_horas_porc
	END IF
	LET num_row = num_row + 1
	IF num_row > max_row THEN
		EXIT FOREACH
	END IF
END FOREACH
LET num_row = num_row - 1
IF num_row = 0 THEN
	IF cambio THEN
		LET rm_n32.n32_cod_trab = NULL
	END IF
	CALL fl_mensaje_consulta_sin_registros()
	CLOSE WINDOW w_rolf302_8
	RETURN
END IF
IF tot_hor = 0 THEN
	LET tot_hor = NULL
END IF
DISPLAY BY NAME tot_hor, total
LET max_row  = num_row
LET int_flag = 0
CALL set_count(max_row)
DISPLAY ARRAY rm_totrub TO rm_totrub.*
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT DISPLAY
	ON KEY(F5)
		IF flag THEN
			IF pos > 0 THEN
				CALL mostrar_empleado(
						rm_detalle[pos].n30_cod_trab)
			ELSE
				CALL mostrar_empleado(rm_n32.n32_cod_trab)
			END IF
		ELSE
			CALL mostrar_empleado(rm_n32.n32_cod_trab)
		END IF
		LET int_flag = 0
	ON KEY(F6)
		LET num_row = arr_curr()	
		CALL ver_liquidacion(num_row, 'X')
		LET int_flag = 0
	--#BEFORE DISPLAY 
		--#CALL dialog.keysetlabel('ACCEPT', '')   
		--#CALL dialog.keysetlabel('RETURN', '')   
		--#CALL dialog.keysetlabel("F1","") 
		--#CALL dialog.keysetlabel("CONTROL-W","") 
	--#BEFORE ROW
		--#LET num_row = arr_curr()
		--#DISPLAY BY NAME num_row, max_row
        --#AFTER DISPLAY
                --#CONTINUE DISPLAY
END DISPLAY
IF cambio THEN
	LET rm_n32.n32_cod_trab = NULL
END IF
CLOSE WINDOW w_rolf302_8
RETURN

END FUNCTION



FUNCTION ver_detalle_rubro_tot2(pos, codrub, fecha_ini, fecha_fin)
DEFINE pos		SMALLINT
DEFINE codrub		LIKE rolt033.n33_cod_rubro
DEFINE fecha_ini	LIKE rolt033.n33_fecha_ini
DEFINE fecha_fin	LIKE rolt033.n33_fecha_fin
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE cod_liqrol	LIKE rolt033.n33_cod_liqrol
DEFINE query		CHAR(1200)
DEFINE expr_depto	VARCHAR(100)
DEFINE expr_val		VARCHAR(100)
DEFINE expr_fec_i	VARCHAR(100)
DEFINE expr_fec_f	VARCHAR(100)
DEFINE tot_hor, total	DECIMAL(14,2)
DEFINE num_row, max_row	SMALLINT

LET max_row = 500
OPEN WINDOW w_rolf303_6 AT 04,08
	WITH FORM '../../NOMINA/forms/rolf303_6'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 0, BORDER)
--#DISPLAY "DP"		TO tit_col1
--#DISPLAY "Cod."	TO tit_col2
--#DISPLAY "Empleado"	TO tit_col3
--#DISPLAY "D/H"	TO tit_col4
--#DISPLAY "Valor"	TO tit_col5
CALL muestra_tituto_det(fecha_ini, fecha_fin)
CALL fl_lee_rubro_roles(codrub) RETURNING r_n06.*
DISPLAY BY NAME r_n06.n06_cod_rubro, r_n06.n06_nombre
LET expr_val = NULL
IF r_n06.n06_det_tot <> 'DI' THEN
	LET expr_val = '   AND n33_valor       > 0 '
END IF
LET expr_depto = NULL
IF rm_n32.n32_cod_depto IS NOT NULL THEN
	LET expr_depto = '   AND n30_cod_depto   = ', rm_n32.n32_cod_depto
END IF
LET expr_fec_i = '   AND n33_fecha_ini  >= "', fecha_ini, '"'
LET expr_fec_f = '   AND n33_fecha_fin  <= "', fecha_fin, '"'
IF vm_codliq_ini IS NOT NULL THEN
	IF vm_codliq_ini = "Q1" THEN
		LET expr_fec_i = '   AND n33_fecha_ini  >= MDY(',
			MONTH(fecha_ini), ', 01, ',
			YEAR(fecha_ini), ')'
	END IF
	IF vm_codliq_ini = "Q2" THEN
		LET expr_fec_i = '   AND n33_fecha_ini  >= MDY(',
			MONTH(fecha_ini), ', 16, ',
			YEAR(fecha_ini), ')'
	END IF
END IF
IF vm_codliq_fin IS NOT NULL THEN
	IF vm_codliq_fin = "Q1" THEN
		LET expr_fec_f = '   AND n33_fecha_fin  <= MDY(',
			MONTH(fecha_fin), ', 15, ',
			YEAR(fecha_fin), ')'
	END IF
	IF vm_codliq_fin = "Q2" THEN
		LET expr_fec_f = '   AND n33_fecha_fin  <= MDY(',
			MONTH(fecha_fin), ', 01, ',
			YEAR(fecha_fin),
			') + 1 UNITS MONTH - 1 UNITS DAY'
	END IF
END IF
LET query = 'SELECT n30_cod_depto, n30_cod_trab, n30_nombres,',
			' SUM(n33_horas_porc), SUM(n33_valor) ',
		' FROM rolt030, rolt033 ',
		' WHERE n33_compania    = ', vg_codcia,
		'   AND n33_cod_liqrol IN ("Q1", "Q2") ',
		expr_fec_i CLIPPED,
		expr_fec_f CLIPPED,
		'   AND n33_cod_trab    = n30_cod_trab ',
		'   AND n33_cod_rubro   = ', codrub,
		expr_depto CLIPPED,
		expr_val CLIPPED,
		' GROUP BY 1, 2, 3 ',
		' ORDER BY n30_nombres '
PREPARE det_tr2 FROM query	
DECLARE q_det_tr2 CURSOR FOR det_tr2
LET num_row = 1
LET tot_hor = 0
LET total   = 0
FOREACH q_det_tr2 INTO rm_totrub2[num_row].*
	IF rm_totrub2[num_row].n33_horas_porc = 0 THEN
		LET rm_totrub2[num_row].n33_horas_porc = NULL
	END IF
	IF rm_totrub2[num_row].n33_horas_porc IS NULL AND
	   rm_totrub2[num_row].n33_valor = 0
	THEN
		CONTINUE FOREACH
	END IF
	LET total   = total + rm_totrub2[num_row].n33_valor
	IF rm_totrub2[num_row].n33_horas_porc IS NOT NULL THEN
		LET tot_hor = tot_hor + rm_totrub2[num_row].n33_horas_porc
	END IF
	LET num_row = num_row + 1
	IF num_row > max_row THEN
		EXIT FOREACH
	END IF
END FOREACH
LET num_row = num_row - 1
IF num_row = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	CLOSE WINDOW w_rolf303_6
	RETURN
END IF
IF tot_hor = 0 THEN
	LET tot_hor = NULL
END IF
DISPLAY BY NAME tot_hor, total
LET max_row  = num_row
LET int_flag = 0
CALL set_count(max_row)
DISPLAY ARRAY rm_totrub2 TO rm_totrub.*
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT DISPLAY
	ON KEY(F5)
		LET num_row = arr_curr()
		CALL ver_detalle_rubro_tot(num_row, codrub, 0,
						fecha_ini, fecha_fin)
		LET int_flag = 0
	--#BEFORE DISPLAY 
		--#CALL dialog.keysetlabel('ACCEPT', '')   
		--#CALL dialog.keysetlabel('RETURN', '')   
		--#CALL dialog.keysetlabel("F1","") 
		--#CALL dialog.keysetlabel("CONTROL-W","") 
		--#CALL dialog.keysetlabel("F5","Detalle") 
	--#BEFORE ROW
		--#LET num_row = arr_curr()
		--#DISPLAY BY NAME num_row, max_row
		--#IF rm_n32.n32_cod_depto IS NULL THEN
			--#CALL fl_lee_departamento(vg_codcia,
					--#rm_totrub2[num_row].cod_depto)
				--#RETURNING r_g34.*
			--#DISPLAY rm_totrub2[num_row].cod_depto
				--#TO n32_cod_depto
			--#DISPLAY BY NAME r_g34.g34_nombre
		--#END IF
        --#AFTER DISPLAY
                --#CONTINUE DISPLAY
END DISPLAY
CLOSE WINDOW w_rolf303_6
RETURN

END FUNCTION



FUNCTION muestra_tituto_det(fecha_ini, fecha_fin)
DEFINE fecha_ini	LIKE rolt033.n33_fecha_ini
DEFINE fecha_fin	LIKE rolt033.n33_fecha_fin
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE r_n03		RECORD LIKE rolt003.*

DISPLAY fecha_ini TO n32_fecha_ini
DISPLAY fecha_fin TO n32_fecha_fin
DISPLAY BY NAME rm_n32.n32_cod_liqrol, rm_n32.n32_cod_depto
CALL fl_lee_proceso_roles(rm_n32.n32_cod_liqrol) RETURNING r_n03.*
CALL fl_lee_departamento(vg_codcia, rm_n32.n32_cod_depto) RETURNING r_g34.*
IF r_n03.n03_nombre IS NOT NULL THEN
	DISPLAY BY NAME r_n03.n03_nombre
ELSE
	DISPLAY '** TODAS LAS LIQUIDACIONES **' TO n03_nombre
END IF
DISPLAY BY NAME r_g34.g34_nombre

END FUNCTION



FUNCTION mostrar_botones_detalle3()

--#DISPLAY "Cod."		TO tit_col1
--#DISPLAY "Descripción"	TO tit_col2
--#DISPLAY "D/H"		TO tit_col3
--#DISPLAY "Valor"		TO tit_col4
--#DISPLAY "Cod."		TO tit_col5
--#DISPLAY "Descripción"	TO tit_col6
--#DISPLAY "Valor"		TO tit_col7

END FUNCTION



FUNCTION datos_defaults3(pos, flag, fecha_ini, fecha_fin)
DEFINE pos, flag	SMALLINT
DEFINE fecha_ini	LIKE rolt033.n33_fecha_ini
DEFINE fecha_fin	LIKE rolt033.n33_fecha_fin
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE r_g35		RECORD LIKE gent035.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE n32_fecha_ini	LIKE rolt032.n32_fecha_ini
DEFINE cod_trab		LIKE rolt030.n30_cod_trab

LET n32_fecha_ini = fecha_ini
IF n32_fecha_ini < retorna_fec_min_trab(pos) THEN
	CALL retorna_fec_min_trab(pos) RETURNING n32_fecha_ini
END IF
CASE flag
	WHEN 0
		CALL fl_lee_trabajador_roles(vg_codcia, rm_n32.n32_cod_trab)
			RETURNING r_n30.*
		IF rm_n32.n32_cod_trab IS NULL THEN
			LET r_n30.n30_nombres = '** TODOS LOS EMPLEADOS **'
		END IF
		CALL fl_lee_departamento(vg_codcia, rm_n32.n32_cod_depto)
			RETURNING r_g34.*
		LET r_n30.n30_cod_depto = rm_n32.n32_cod_depto
		IF num_args() <> 3 THEN
			CASE arg_val(6)
				WHEN 'T' LET cod_trab = arg_val(7)
				WHEN 'D' LET r_n30.n30_cod_depto = arg_val(7)
			END CASE
		END IF
	WHEN 1
		CALL fl_lee_trabajador_roles(vg_codcia, retorna_cod_trab(pos))
			RETURNING r_n30.*
	WHEN 2
		LET cod_trab = rm_n32.n32_cod_trab
		IF cod_trab IS NULL THEN
			LET cod_trab = rm_totrub2[pos].n32_cod_trab
		END IF
		IF num_args() <> 3 THEN
			CASE arg_val(6)
				WHEN 'T' LET cod_trab = arg_val(7)
				WHEN 'D' LET r_n30.n30_cod_depto = arg_val(7)
			END CASE
		END IF
		CALL fl_lee_trabajador_roles(vg_codcia, cod_trab)
			RETURNING r_n30.*
END CASE
IF flag <> 0 THEN
	CALL fl_lee_departamento(vg_codcia, r_n30.n30_cod_depto)
		RETURNING r_g34.*
END IF
CALL fl_lee_cargo(vg_codcia, r_n30.n30_cod_cargo) RETURNING r_g35.*
DISPLAY BY NAME r_n30.n30_cod_trab, r_n30.n30_nombres, r_n30.n30_cod_depto,
		r_g34.g34_nombre, n32_fecha_ini, r_g35.g35_nombre,
		r_n30.n30_cod_cargo
DISPLAY fecha_fin TO n32_fecha_fin

END FUNCTION



FUNCTION retorna_fec_min_trab(i)
DEFINE i		SMALLINT
DEFINE fec_min		LIKE rolt032.n32_fecha_ini
DEFINE cod_trab		LIKE rolt032.n32_cod_trab

CALL retorna_cod_trab(i) RETURNING cod_trab
SELECT NVL(MIN(n32_fecha_ini), TODAY)
	INTO fec_min
	FROM rolt032
	WHERE n32_compania    = vg_codcia
	  AND n32_cod_liqrol IN ("Q1", "Q2")
	  AND n32_estado     <> 'E'
	  AND n32_cod_trab    = cod_trab
RETURN fec_min

END FUNCTION



FUNCTION retorna_fec_max_trab(i)
DEFINE i		SMALLINT
DEFINE fec_max		LIKE rolt032.n32_fecha_fin
DEFINE cod_trab		LIKE rolt032.n32_cod_trab

CALL retorna_cod_trab(i) RETURNING cod_trab
SELECT NVL(MAX(n32_fecha_fin), TODAY)
	INTO fec_max
	FROM rolt032
	WHERE n32_compania    = vg_codcia
	  AND n32_cod_liqrol IN ("Q1", "Q2")
	  AND n32_estado     <> 'E'
	  AND n32_cod_trab    = cod_trab
RETURN fec_max

END FUNCTION



FUNCTION retorna_num_mes(mes)
DEFINE mes		VARCHAR(10)
DEFINE num_m		SMALLINT

LET mes = UPSHIFT(mes)
CASE mes
	WHEN 'ENERO'      LET num_m = 1
	WHEN 'FEBRERO'    LET num_m = 2
	WHEN 'MARZO'      LET num_m = 3
	WHEN 'ABRIL'      LET num_m = 4
	WHEN 'MAYO'       LET num_m = 5
	WHEN 'JUNIO'      LET num_m = 6
	WHEN 'JULIO'      LET num_m = 7
	WHEN 'AGOSTO'     LET num_m = 8
	WHEN 'SEPTIEMBRE' LET num_m = 9
	WHEN 'OCTUBRE'    LET num_m = 10
	WHEN 'NOVIEMBRE'  LET num_m = 11
	WHEN 'DICIEMBRE'  LET num_m = 12
END CASE
RETURN num_m

END FUNCTION



FUNCTION retorna_cod_trab(pos)
DEFINE pos		SMALLINT
DEFINE cod_trab		LIKE rolt032.n32_cod_trab

LET cod_trab = rm_n32.n32_cod_trab
IF pos > 0 THEN
	LET cod_trab = rm_detalle[pos].n30_cod_trab
END IF
RETURN cod_trab

END FUNCTION



FUNCTION imprimir_rubros(tipo_imp, fecha_ini, fecha_fin, tipo_rub)
DEFINE tipo_imp		CHAR(1)
DEFINE fecha_ini	LIKE rolt032.n32_fecha_ini
DEFINE fecha_fin	LIKE rolt032.n32_fecha_fin
DEFINE tipo_rub		CHAR(1)
DEFINE prog		VARCHAR(10)
DEFINE param		VARCHAR(60)

CASE tipo_imp
	WHEN 'L'
		LET prog  = 'rolp416 '
		LET param = ' "XX" "', fecha_ini, '" "', fecha_fin, '" ',
				tipo_rub
	WHEN 'C'
		LET prog  = 'rolp405 '
		LET param = ' "', fecha_ini, '" "', fecha_fin, '" "XX" '
		IF tipo_rub <> 'T' THEN
			LET param = param CLIPPED, ' "N" '
		ELSE
			LET param = param CLIPPED, ' ', tipo_rub
		END IF
		IF rm_n32.n32_cod_depto IS NOT NULL THEN
			LET param = param CLIPPED, ' ', rm_n32.n32_cod_depto
		ELSE
			LET param = param CLIPPED, ' 0 '
		END IF
		IF rm_n32.n32_cod_trab IS NOT NULL THEN
			LET param = param CLIPPED, ' ', rm_n32.n32_cod_trab
		END IF
END CASE
CALL ejecuta_comando('NOMINA', vg_modulo, prog, param)

END FUNCTION



FUNCTION control_imprimir_tot_gan_quin()
DEFINE comando		VARCHAR(100)
DEFINE i		SMALLINT

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
START REPORT report_tot_gan_quin TO PIPE comando
FOR i = 1 TO vm_num_elmt
	OUTPUT TO REPORT report_tot_gan_quin(i)
END FOR
FINISH REPORT report_tot_gan_quin

END FUNCTION



REPORT report_tot_gan_quin(i)
DEFINE i		SMALLINT
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE usuario		VARCHAR(19,15)
DEFINE modulo		VARCHAR(40)
DEFINE escape		SMALLINT
DEFINE act_comp		SMALLINT
DEFINE desact_comp	SMALLINT
DEFINE act_12cpi	SMALLINT
DEFINE act_neg, des_neg	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	96
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresión
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_neg	= 71		# Activar negrita.
	LET des_neg	= 72		# Desactivar negrita.
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo      = "MODULO: ", r_g50.g50_nombre[1, 19] CLIPPED
	LET usuario     = "USUARIO: ", vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_lee_compania(vg_codcia) RETURNING r_g01.*
	print ASCII escape;
	print ASCII act_neg;
	print ASCII escape;
	print ASCII act_12cpi;
	PRINT COLUMN 005, r_g01.g01_razonsocial,
  	      COLUMN 090, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 032, "LISTADO TOTAL GANADO POR QUINCENAS",
	      COLUMN 090, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	CALL fl_lee_trabajador_roles(vg_codcia, rm_n32.n32_cod_trab)
		RETURNING r_n30.*
	CALL fl_lee_departamento(vg_codcia, rm_n32.n32_cod_depto)
		RETURNING r_g34.*
	PRINT COLUMN 013, "** EMPLEADO      : ",
		rm_n32.n32_cod_trab USING "<<<&&&", ' ',
		r_n30.n30_nombres CLIPPED
	PRINT COLUMN 013, "** DEPTO. ACTUAL : ",
		rm_n32.n32_cod_depto USING "<<&&", ' ', 
		r_g34.g34_nombre CLIPPED
	PRINT COLUMN 013, "** PERIODO INIC. : ", vm_anio_ini USING "&&&&",
		' - ', vm_mes_ini USING "&&", ' ',
		UPSHIFT(retorna_mes(vm_mes_ini));
	IF vm_codliq_ini IS NOT NULL THEN
   		CALL fl_lee_proceso_roles(vm_codliq_ini) RETURNING r_n03.*
        	PRINT COLUMN 054, "LIQ. INIC.: ",
			fl_justifica_titulo('I', vm_codliq_ini
				|| ' ' || r_n03.n03_nombre[1, 28] CLIPPED, 31)
	ELSE
		PRINT ' '
	END IF
	PRINT COLUMN 013, "** PERIODO FIN.  : ", vm_anio_fin USING "&&&&",
		' - ', vm_mes_fin USING "&&", ' ',
		UPSHIFT(retorna_mes(vm_mes_fin));
	IF vm_codliq_fin IS NOT NULL THEN
   		CALL fl_lee_proceso_roles(vm_codliq_fin) RETURNING r_n03.*
        	PRINT COLUMN 054, "LIQ. FIN. : ",
			fl_justifica_titulo('I', vm_codliq_fin
				|| ' ' || r_n03.n03_nombre[1, 28] CLIPPED, 31)
	ELSE
		PRINT ' '
	END IF
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
 		1 SPACES, TIME,
	      COLUMN 078, usuario
	PRINT "------------------------------------------------------------------------------------------------"
	PRINT COLUMN 001, "LQ",
	      COLUMN 007, "DESCRIPCION",
	      COLUMN 027, "FECHA INI.",
	      COLUMN 039, "FECHA FIN.",
	      COLUMN 051, "TOTAL GAN.",
	      COLUMN 063, "TOTAL ING.",
	      COLUMN 075, "TOTAL EGR.",
	      COLUMN 087, "TOTAL NETO"
	PRINT "------------------------------------------------------------------------------------------------";
	print ASCII escape;
	print ASCII des_neg

ON EVERY ROW
	NEED 3 LINES
   	CALL fl_lee_proceso_roles(rm_det_tot[i].n32_cod_liqrol)
		RETURNING r_n03.*
	PRINT COLUMN 001, rm_det_tot[i].n32_cod_liqrol,
	      COLUMN 005, r_n03.n03_nombre_abr		CLIPPED,
	      COLUMN 027, rm_det_tot[i].n32_fecha_ini	USING "dd-mm-yyyy",
	      COLUMN 039, rm_det_tot[i].n32_fecha_fin	USING "dd-mm-yyyy",
	      COLUMN 051, rm_det_tot[i].n32_tot_gan	USING "###,##&.##",
	      COLUMN 063, rm_det_tot[i].total_ing	USING "###,##&.##",
	      COLUMN 075, rm_det_tot[i].total_egr	USING "###,##&.##",
	      COLUMN 087, rm_det_tot[i].total_net	USING "###,##&.##"
	
ON LAST ROW
	NEED 2 LINES
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 053, "----------",
	      COLUMN 065, "----------",
	      COLUMN 077, "----------",
	      COLUMN 089, "----------"
	PRINT COLUMN 001, "TOT. LIQ. ", vm_num_elmt USING "<<<&",
	      COLUMN 038, "TOTALES ==>  ",
	      COLUMN 051, SUM(rm_det_tot[i].n32_tot_gan) USING "###,##&.##",
	      COLUMN 063, SUM(rm_det_tot[i].total_ing)	USING "###,##&.##",
	      COLUMN 075, SUM(rm_det_tot[i].total_egr)	USING "###,##&.##",
	      COLUMN 087, SUM(rm_det_tot[i].total_net)	USING "###,##&.##";
	print ASCII escape;
	print ASCII des_neg;
	print ASCII escape;
	print ASCII desact_comp

END REPORT



FUNCTION control_imprimir_tot_gan_mes()
DEFINE comando		VARCHAR(100)
DEFINE i		SMALLINT

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
START REPORT report_tot_gan_mes TO PIPE comando
FOR i = 1 TO vm_num_elmt
	OUTPUT TO REPORT report_tot_gan_mes(i)
END FOR
FINISH REPORT report_tot_gan_mes

END FUNCTION



REPORT report_tot_gan_mes(i)
DEFINE i		SMALLINT
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE usuario		VARCHAR(19,15)
DEFINE modulo		VARCHAR(40)
DEFINE escape		SMALLINT
DEFINE act_comp		SMALLINT
DEFINE desact_comp	SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_neg, des_neg	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	80
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresión
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_neg	= 71		# Activar negrita.
	LET des_neg	= 72		# Desactivar negrita.
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo      = "MODULO: ", r_g50.g50_nombre[1, 12] CLIPPED
	LET usuario     = "USUARIO: ", vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_lee_compania(vg_codcia) RETURNING r_g01.*
	print ASCII escape;
	print ASCII act_neg;
	print ASCII escape;
	print ASCII act_10cpi;
	PRINT COLUMN 005, r_g01.g01_razonsocial,
  	      COLUMN 074, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 024, "TOTAL GANADO POR MES DE EMPLEADOS",
	      COLUMN 074, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	CALL fl_lee_trabajador_roles(vg_codcia, rm_n32.n32_cod_trab)
		RETURNING r_n30.*
	CALL fl_lee_departamento(vg_codcia, rm_n32.n32_cod_depto)
		RETURNING r_g34.*
	IF rm_n32.n32_cod_trab IS NOT NULL THEN
		PRINT COLUMN 006, "** EMPLEADO     : ",
			rm_n32.n32_cod_trab USING "<<<&&&", ' ',
			r_n30.n30_nombres CLIPPED
	ELSE
		PRINT COLUMN 006, "** EMPLEADO     : ** TODOS LOS EMPLEADOS **"
	END IF
	IF rm_n32.n32_cod_depto IS NOT NULL THEN
		PRINT COLUMN 006, "** DEPTO. ACTUAL: ",
			rm_n32.n32_cod_depto USING "<<&&", ' ', 
			r_g34.g34_nombre CLIPPED
	END IF
	PRINT COLUMN 006, "** PERIODO INIC.: ", vm_anio_ini USING "&&&&",
		' - ', vm_mes_ini USING "&&", ' ',
		UPSHIFT(retorna_mes(vm_mes_ini));
	IF vm_codliq_ini IS NOT NULL THEN
   		CALL fl_lee_proceso_roles(vm_codliq_ini) RETURNING r_n03.*
        	PRINT COLUMN 047, "LIQ. INIC.: ",
			fl_justifica_titulo('I', vm_codliq_ini
				|| ' ' || r_n03.n03_nombre[1, 19] CLIPPED, 22)
	ELSE
		PRINT ' '
	END IF
	PRINT COLUMN 006, "** PERIODO FIN. : ", vm_anio_fin USING "&&&&",
		' - ', vm_mes_fin USING "&&", ' ',
		UPSHIFT(retorna_mes(vm_mes_fin));
	IF vm_codliq_fin IS NOT NULL THEN
   		CALL fl_lee_proceso_roles(vm_codliq_fin) RETURNING r_n03.*
        	PRINT COLUMN 047, "LIQ. FIN. : ",
			fl_justifica_titulo('I', vm_codliq_fin
				|| ' ' || r_n03.n03_nombre[1, 19] CLIPPED, 22)
	ELSE
		PRINT ' '
	END IF
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
 		1 SPACES, TIME,
	      COLUMN 062, usuario
	PRINT "--------------------------------------------------------------------------------"
	PRINT COLUMN 001, "ANIO",
	      COLUMN 009, "MESES",
	      COLUMN 023, "SUELDO MES",
	      COLUMN 035, "TOTAL GAN.",
	      COLUMN 047, "TOTAL ING.",
	      COLUMN 059, "TOTAL EGR.",
	      COLUMN 071, "TOTAL NETO"
	PRINT "--------------------------------------------------------------------------------";
	print ASCII escape;
	print ASCII des_neg

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 001, rm_det_tot2[i].n32_ano_proceso USING "&&&&",
	      COLUMN 007, rm_det_tot2[i].nom_mes	CLIPPED,
	      COLUMN 023, rm_det_tot2[i].n32_sueldo	USING "###,##&.##",
	      COLUMN 035, rm_det_tot2[i].n32_tot_gan	USING "###,##&.##",
	      COLUMN 047, rm_det_tot2[i].total_ing	USING "###,##&.##",
	      COLUMN 059, rm_det_tot2[i].total_egr	USING "###,##&.##",
	      COLUMN 071, rm_det_tot2[i].total_net	USING "###,##&.##"
	
ON LAST ROW
	NEED 2 LINES
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 025, "----------",
	      COLUMN 037, "----------",
	      COLUMN 049, "----------",
	      COLUMN 061, "----------",
	      COLUMN 073, "----------"
	PRINT COLUMN 001, vm_num_elmt USING "<<&", " MESES",
	      COLUMN 012, "TOTALES==> ",
	      COLUMN 023, SUM(rm_det_tot2[i].n32_sueldo) USING "###,##&.##",
	      COLUMN 035, SUM(rm_det_tot2[i].n32_tot_gan) USING "###,##&.##",
	      COLUMN 047, SUM(rm_det_tot2[i].total_ing)	USING "###,##&.##",
	      COLUMN 059, SUM(rm_det_tot2[i].total_egr)	USING "###,##&.##",
	      COLUMN 071, SUM(rm_det_tot2[i].total_net)	USING "###,##&.##";
	print ASCII escape;
	print ASCII des_neg

END REPORT
