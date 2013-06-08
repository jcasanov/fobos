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
				n48_cod_liqrol	LIKE rolt048.n48_cod_liqrol,
				n48_fecha_ini	LIKE rolt048.n48_fecha_ini,
				n48_fecha_fin	LIKE rolt048.n48_fecha_fin
			END RECORD
DEFINE rm_n00		RECORD LIKE rolt000.*  
DEFINE rm_loc		RECORD LIKE gent002.*
DEFINE rm_n01		RECORD LIKE rolt001.*  
DEFINE rm_n48		RECORD LIKE rolt048.*  
DEFINE rm_par		RECORD 
				n48_estado	LIKE rolt048.n48_estado,
				n48_proceso	LIKE rolt048.n48_proceso,
				n03_nombre	LIKE rolt003.n03_nombre,
				n48_cod_liqrol	LIKE rolt048.n48_cod_liqrol,
				tit_nombre	LIKE rolt003.n03_nombre,
				n48_fecha_ini	LIKE rolt048.n48_fecha_ini,
				n48_fecha_fin	LIKE rolt048.n48_fecha_fin
			END RECORD
DEFINE rm_pat		ARRAY[300] OF RECORD
				n48_cod_trab	LIKE rolt048.n48_cod_trab,
				n30_num_doc_id	LIKE rolt030.n30_num_doc_id,
				n30_nombres	LIKE rolt030.n30_nombres,
				n30_fec_jub	LIKE rolt030.n30_fec_jub,
				n48_num_dias	LIKE rolt048.n48_num_dias,
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
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE i		SMALLINT
DEFINE salir 		INTEGER
DEFINE resp 		VARCHAR(6)

CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rm_loc.*
IF rm_loc.g02_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe localidad.','stop')
	EXIT PROGRAM
END IF
-- AQUI SE DEFINEN VALORES DE VARIABLES GLOBALES
LET vm_proceso = 'JU'
CALL fl_lee_proceso_roles(vm_proceso) RETURNING r_n03.*
IF r_n03.n03_proceso IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configurado el proceso JUBILADOS en la tabla rolt003.', 'stop')
	EXIT PROGRAM
END IF
LET rm_par.n48_proceso = vm_proceso
LET rm_par.n03_nombre  = r_n03.n03_nombre
LET vm_max_rows        = 200
LET vm_maxelm          = 300
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
		HIDE OPTION 'Archivo Banco'
		HIDE OPTION 'Recibos de Pago'
		HIDE OPTION 'Detalle/Pago'
		HIDE OPTION 'Contab. Transf.'
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
			SHOW OPTION 'Archivo Banco'
			SHOW OPTION 'Recibos de Pago'
			IF vm_filas_pant < vm_numelm THEN
				SHOW OPTION 'Contab. Transf.'
				SHOW OPTION 'Detalle/Pago'
			ELSE
				HIDE OPTION 'Contab. Transf.'
				HIDE OPTION 'Detalle/Pago'
			END IF
			IF vm_num_rows > 1 THEN
				SHOW OPTION 'Avanzar'
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
			SHOW OPTION 'Archivo Banco'
			SHOW OPTION 'Recibos de Pago'
			IF vm_filas_pant < vm_numelm THEN
				SHOW OPTION 'Contab. Transf.'
				SHOW OPTION 'Detalle/Pago'
			ELSE
				HIDE OPTION 'Contab. Transf.'
				HIDE OPTION 'Detalle/Pago'
			END IF
			IF vm_num_rows > 1 THEN
				SHOW OPTION 'Avanzar'
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
			SHOW OPTION 'Archivo Banco'
			SHOW OPTION 'Recibos de Pago'
			IF vm_filas_pant < vm_numelm THEN
				SHOW OPTION 'Contab. Transf.'
				SHOW OPTION 'Detalle/Pago'
			ELSE
				HIDE OPTION 'Contab. Transf.'
				HIDE OPTION 'Detalle/Pago'
			END IF
		END IF
	COMMAND KEY('T') 'Contab. Transf.' 'Contabiliza Transferencia al Banco.'
		CALL control_contabilizacion(0)
	COMMAND KEY('D') 'Detalle/Pago' 'Se ubica en el datalle y genera pago.'
		CALL control_detalle()
	COMMAND KEY('I') 'Imprimir' 'Imprime Lista de Jubilados'
		CALL control_imprimir()
	COMMAND KEY('X') 'Archivo Banco' 'Genera archivo para credito bancario.'
		CALL generar_archivo()
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
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n48, r_n48_2	RECORD LIKE rolt048.*
DEFINE r_g14		RECORD LIKE gent014.*
DEFINE dias_ini, i	SMALLINT
DEFINE ult_dia		SMALLINT
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE
DEFINE fecha1, fecha2	DATE
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
IF rm_par.n48_cod_liqrol IS NULL THEN
	LET rm_par.n48_estado     = 'A'
	CALL muestra_estado()
	LET rm_par.n48_cod_liqrol = 'ME'
END IF
CALL fl_lee_compania_roles(vg_codcia) RETURNING rm_n01.*
CALL lee_datos()
IF int_flag THEN
	CALL mostrar_salir()
	RETURN 0
END IF
INITIALIZE r_n48.* TO NULL
DECLARE q_ultjub CURSOR FOR
	SELECT * FROM rolt048 
		WHERE n48_compania    = vg_codcia
		  AND n48_cod_liqrol  = rm_par.n48_cod_liqrol
		  AND n48_estado     <> 'E' 
		  AND n48_tipo_comp  IS NULL
		ORDER BY n48_fecing DESC
OPEN q_ultjub
FETCH q_ultjub INTO r_n48.* 
IF r_n48.n48_estado = 'P' THEN
	IF r_n48.n48_ano_proceso = rm_n01.n01_ano_proceso AND 
	   r_n48.n48_mes_proceso = rm_n01.n01_mes_proceso
	THEN
		CALL fl_mostrar_mensaje('La jubilación del presente mes ya fue procesada.', 'exclamation')
		CALL mostrar_salir()
		RETURN 0
	END IF
END IF
CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
IF resp <> 'Yes' THEN
	CALL mostrar_salir()
	RETURN 0
END IF
BEGIN WORK
DELETE FROM rolt048
	WHERE n48_compania    = vg_codcia
	  AND n48_cod_liqrol  = rm_par.n48_cod_liqrol
	  AND n48_estado      = 'A'
	  AND n48_tipo_comp  IS NULL
LET i = 0
LET fecha_ini = rm_par.n48_fecha_ini
LET fecha_fin = rm_par.n48_fecha_fin
CALL fl_lee_proceso_roles(rm_par.n48_cod_liqrol) RETURNING r_n03.*
LET fecha1 = EXTEND(MDY(rm_n01.n01_mes_proceso, 01, rm_n01.n01_ano_proceso),
			YEAR TO MONTH)
IF r_n03.n03_proceso = 'ME' THEN
	LET fecha2 = NULL
	SELECT MAX(EXTEND(MDY(n48_mes_proceso, 01, n48_ano_proceso),
			YEAR TO MONTH))
		INTO fecha2
	        FROM rolt048
        	WHERE n48_compania    = vg_codcia
	          AND n48_proceso     = vm_proceso
	          AND n48_cod_liqrol  = r_n03.n03_proceso
		  AND n48_estado     <> 'P'
	IF fecha2 IS NOT NULL THEN
		IF fecha1 > fecha2 THEN
			LET fecha1 = fecha2
		END IF
	END IF
END IF
FOREACH q_pt INTO r_n30.*
	CALL lee_reg_jub2(rm_par.n48_cod_liqrol, YEAR(fecha1), MONTH(fecha1),
				r_n30.n30_cod_trab)
		RETURNING r_n48_2.*
	IF r_n48_2.n48_compania IS NOT NULL THEN
		CONTINUE FOREACH
	END IF
	LET i = i + 1
	INITIALIZE r_n48.* TO NULL
	LET r_n48.n48_compania	  = vg_codcia
	LET r_n48.n48_proceso     = vm_proceso
	LET r_n48.n48_cod_liqrol  = rm_par.n48_cod_liqrol
	LET r_n48.n48_fecha_ini   = fecha_ini
	LET r_n48.n48_fecha_fin   = fecha_fin
	LET r_n48.n48_cod_trab    = r_n30.n30_cod_trab
	LET r_n48.n48_estado      = 'A'
	LET r_n48.n48_ano_proceso = YEAR(fecha1)
	LET r_n48.n48_mes_proceso = MONTH(fecha1)
	IF r_n48.n48_cod_liqrol = 'ME' THEN
		IF r_n48.n48_mes_proceso <> MONTH(r_n48.n48_fecha_fin) THEN
			LET r_n48.n48_mes_proceso = MONTH(r_n48.n48_fecha_fin)
		END IF
	END IF
	LET r_n48.n48_moneda      = r_n30.n30_mon_sueldo
	LET r_n48.n48_paridad     = 1
	IF r_n48.n48_moneda <> rg_gen.g00_moneda_base THEN
		CALL fl_lee_factor_moneda(r_n48.n48_moneda,
						rg_gen.g00_moneda_base)
				RETURNING r_g14.*
		IF r_g14.g14_serial IS NULL THEN
			CALL fl_mostrar_mensaje('No hay paridad cambiaria para la moneda: ' || r_n48.n48_moneda,'exclamation')
			RETURN
		END IF
		LET r_n48.n48_paridad = r_g14.g14_tasa
	END IF
	LET r_n48.n48_num_dias    = rm_n00.n00_dias_mes
	IF rm_par.n48_cod_liqrol = 'ME' THEN
		LET r_n48.n48_tot_gan     = r_n30.n30_val_jub_pat
		LET r_n48.n48_val_jub_pat = r_n30.n30_val_jub_pat
		IF EXTEND(r_n30.n30_fec_jub, YEAR TO MONTH) =
		   EXTEND(fecha_fin, YEAR TO MONTH)
		THEN
			LET dias_ini = (fecha_fin - r_n30.n30_fec_jub) + 1
			IF dias_ini > rm_n00.n00_dias_mes THEN
				LET dias_ini = rm_n00.n00_dias_mes
			END IF
			IF dias_ini = 0 THEN
				LET dias_ini = 1
			END IF
			LET r_n48.n48_num_dias    = dias_ini
			LET r_n48.n48_val_jub_pat = (r_n30.n30_val_jub_pat /
						rm_n00.n00_dias_mes) * dias_ini
		END IF
	END IF
	IF rm_par.n48_cod_liqrol[1, 1] = 'D' THEN
		LET r_n48.n48_num_dias    = retorna_num_meses(r_n30.n30_fec_jub,
								fecha_fin)
						* rm_n00.n00_dias_mes
		LET r_n48.n48_tot_gan     = r_n03.n03_valor
		IF DAY(r_n30.n30_fec_jub) > rm_n00.n00_dias_mes THEN
			LET dias_ini = rm_n00.n00_dias_mes
		ELSE
		IF DAY(r_n30.n30_fec_jub) > 1 AND r_n30.n30_fec_jub > fecha_ini
		THEN
			LET ult_dia = DAY(MDY(MONTH(r_n30.n30_fec_jub), 01,
					YEAR(r_n30.n30_fec_jub))
					+ 1 UNITS MONTH - 1 UNITS DAY)
			IF (ult_dia > rm_n00.n00_dias_mes) OR
			   (MONTH(r_n30.n30_fec_jub) = 2)
			THEN
				LET ult_dia = rm_n00.n00_dias_mes
			END IF
			LET dias_ini = ult_dia - DAY(r_n30.n30_fec_jub) + 1
		END IF
		END IF
		IF r_n48.n48_num_dias < (rm_n00.n00_dias_mes * 12) THEN
			LET r_n48.n48_num_dias = r_n48.n48_num_dias + dias_ini
		END IF
		IF r_n03.n03_proceso = 'DT' THEN
			SELECT NVL(SUM(n48_val_jub_pat), 0)
				INTO r_n48.n48_tot_gan
				FROM rolt048
				WHERE n48_compania    = vg_codcia
				  AND n48_proceso     = vm_proceso
				  AND n48_cod_liqrol  = 'ME'
				  AND n48_fecha_ini  >= r_n48.n48_fecha_ini
				  AND n48_fecha_fin  <= r_n48.n48_fecha_fin
				  AND n48_cod_trab    = r_n48.n48_cod_trab
			LET r_n48.n48_val_jub_pat = r_n48.n48_tot_gan / 12
		END IF
		IF r_n03.n03_proceso = 'DC' THEN
			LET r_n48.n48_tot_gan     = r_n03.n03_valor
			LET r_n48.n48_val_jub_pat = (r_n48.n48_tot_gan / 12
							/ rm_n00.n00_dias_mes)
							* r_n48.n48_num_dias
		END IF
	END IF
	LET r_n48.n48_tipo_pago   = r_n30.n30_tipo_pago
	IF r_n30.n30_tipo_pago <> 'E' THEN
		LET r_n48.n48_bco_empresa = r_n30.n30_bco_empresa
		LET r_n48.n48_cta_empresa = r_n30.n30_cta_empresa
		IF r_n30.n30_tipo_pago = 'T' THEN
			LET r_n48.n48_cta_trabaj = r_n30.n30_cta_trabaj
			IF vg_codloc = 1 THEN
				--LET r_n48.n48_cta_trabaj = NULL
			END IF
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
	LET r_n48.n48_usuario     = vg_usuario
	LET r_n48.n48_fecing      = CURRENT
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



FUNCTION lee_datos()
DEFINE r_par		RECORD 
				n48_estado	LIKE rolt048.n48_estado,
				n48_proceso	LIKE rolt048.n48_proceso,
				n03_nombre	LIKE rolt003.n03_nombre,
				n48_cod_liqrol	LIKE rolt048.n48_cod_liqrol,
				tit_nombre	LIKE rolt003.n03_nombre,
				n48_fecha_ini	LIKE rolt048.n48_fecha_ini,
				n48_fecha_fin	LIKE rolt048.n48_fecha_fin
			END RECORD
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n05		RECORD LIKE rolt005.*
DEFINE cod_liq		LIKE rolt003.n03_proceso
DEFINE nombre		LIKE rolt003.n03_nombre
DEFINE fec_pro		DATE
DEFINE mensaje		VARCHAR(200)
DEFINE resp		CHAR(6)

LET r_par.* = rm_par.*
LET int_flag = 0
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_par.*) THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				EXIT INPUT
			END IF
		ELSE
			EXIT INPUT
		END IF
	ON KEY(F2)
		IF INFIELD(n48_cod_liqrol) THEN
			CALL fl_ayuda_procesos_roles()
				RETURNING r_n03.n03_proceso, r_n03.n03_nombre
			IF r_n03.n03_proceso IS NOT NULL THEN
				LET rm_par.n48_cod_liqrol = r_n03.n03_proceso
				LET rm_par.tit_nombre     = r_n03.n03_nombre
				CALL retorna_fechas_proceso()
					RETURNING rm_par.n48_fecha_ini,
						  rm_par.n48_fecha_fin
				DISPLAY BY NAME rm_par.*
			END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		IF rm_par.n48_cod_liqrol IS NOT NULL THEN
			CALL fl_lee_proceso_roles(rm_par.n48_cod_liqrol)
				RETURNING r_n03.*
			LET rm_par.tit_nombre = r_n03.n03_nombre
			DISPLAY BY NAME rm_par.tit_nombre
		END IF
	BEFORE FIELD n48_cod_liqrol
		LET cod_liq = rm_par.n48_cod_liqrol
		LET nombre  = rm_par.tit_nombre
	AFTER FIELD n48_cod_liqrol
		IF rm_par.n48_cod_liqrol IS NOT NULL THEN
   			CALL fl_lee_proceso_roles(rm_par.n48_cod_liqrol)
				RETURNING r_n03.*
			IF r_n03.n03_proceso IS NULL THEN
				CALL fl_mostrar_mensaje('No existe el código de liquidación en la Compañía.', 'exclamation')
				NEXT FIELD n48_cod_liqrol
			END IF
			SELECT * FROM rolt028
				WHERE n28_compania   = vg_codcia
				  AND n28_proceso    = vm_proceso
				  AND n28_cod_liqrol = rm_par.n48_cod_liqrol
			IF STATUS = NOTFOUND THEN
				CALL fl_mostrar_mensaje('Este código de rol no pertenece al proceso de JUBILADOS.', 'exclamation')
				NEXT FIELD n48_cod_liqrol
			END IF
			LET rm_par.n48_cod_liqrol = r_n03.n03_proceso
			LET rm_par.tit_nombre     = r_n03.n03_nombre
			CALL retorna_fechas_proceso()
				RETURNING rm_par.n48_fecha_ini,
					  rm_par.n48_fecha_fin
			DISPLAY BY NAME rm_par.*
			LET fec_pro = MDY(r_n03.n03_mes_ini, r_n03.n03_dia_ini,
						rm_n01.n01_ano_proceso)
			IF fec_pro > MDY(rm_n01.n01_mes_proceso, DAY(TODAY),
						rm_n01.n01_ano_proceso)
			THEN
				CALL fl_mostrar_mensaje('Este proceso debe realizarse despues del ' || r_n03.n03_dia_ini || ' de ' || fl_justifica_titulo('I', fl_retorna_nombre_mes( r_n03.n03_mes_ini), 12) CLIPPED || ' del ' || rm_n01.n01_ano_proceso || '.', 'exclamation')
				NEXT FIELD n48_cod_liqrol
			END IF
			SELECT * INTO r_n05.*
				FROM rolt005
				WHERE n05_compania = vg_codcia
				  AND n05_proceso  = r_n03.n03_proceso
			IF r_n05.n05_activo = 'N' AND
			   r_n05.n05_fecfin_act = rm_par.n48_fecha_fin
			THEN
				LET mensaje = 'El ',
					DOWNSHIFT(r_n03.n03_nombre_abr) CLIPPED,
					' del periodo: ', 
				       rm_par.n48_fecha_ini USING 'dd-mm-yyyy',
				' - ', rm_par.n48_fecha_fin USING 'dd-mm-yyyy',
		                     ' ya fue procesado.'
				CALL fl_mostrar_mensaje(mensaje, 'exclamation')
				NEXT FIELD n48_cod_liqrol
			END IF
		ELSE
			LET rm_par.n48_cod_liqrol = cod_liq
			LET rm_par.tit_nombre     = nombre
			DISPLAY BY NAME rm_par.n48_cod_liqrol, rm_par.tit_nombre
		END IF
END INPUT
IF int_flag THEN
	LET rm_par.* = r_par.*
	DISPLAY BY NAME rm_par.*
END IF

END FUNCTION



FUNCTION retorna_fechas_proceso()
DEFINE anio		SMALLINT
DEFINE fecha1, fecha2	DATE
DEFINE cuantos		INTEGER

LET anio = rm_n01.n01_ano_proceso
IF rm_par.n48_cod_liqrol[1, 1] = 'D' THEN
	LET anio = rm_n01.n01_ano_proceso - 1
END IF
CALL fl_retorna_rango_fechas_proceso(vg_codcia, rm_par.n48_cod_liqrol,
			anio, rm_n01.n01_mes_proceso)
	RETURNING fecha1, fecha2
IF rm_par.n48_cod_liqrol <> 'ME' THEN
	RETURN fecha1, fecha2
END IF
LET fecha2 = fecha1 - 1 UNITS DAY
LET fecha1 = fecha1 - 1 UNITS MONTH
SELECT COUNT(*)
	INTO cuantos
	FROM rolt048 
	WHERE n48_compania   = vg_codcia
	  AND n48_proceso    = vm_proceso
	  AND n48_cod_liqrol = rm_par.n48_cod_liqrol
	  AND n48_fecha_ini  = fecha1
	  AND n48_fecha_fin  = fecha2
	  AND n48_estado     = 'A'
IF cuantos > 0 THEN
	RETURN fecha1, fecha2
END IF
SELECT COUNT(*)
	INTO cuantos
	FROM rolt048 
	WHERE n48_compania   = vg_codcia
	  AND n48_proceso    = vm_proceso
	  AND n48_cod_liqrol = rm_par.n48_cod_liqrol
	  AND n48_fecha_ini  = fecha1
	  AND n48_fecha_fin  = fecha2
	  AND n48_estado     = 'P'
IF cuantos > 0 THEN
	LET fecha1 = fecha1 + 1 UNITS MONTH
	LET fecha2 = fecha1 + 1 UNITS MONTH - 1 UNITS DAY
END IF
RETURN fecha1, fecha2

END FUNCTION



FUNCTION retorna_num_meses(fecha1, fecha2)
DEFINE fecha1, fecha2	DATE
DEFINE num_mes		SMALLINT

SQL
	SELECT (($fecha2 - $fecha1) + 1) / $rm_n00.n00_dias_mes
		INTO $num_mes
		FROM dual
END SQL
IF num_mes > 12 THEN
	LET num_mes = 12
END IF
RETURN num_mes

END FUNCTION



FUNCTION mostrar_botones()

DISPLAY 'Código'		TO tit_col1
DISPLAY 'Cédula'		TO tit_col2
DISPLAY 'Nombre Jubilado' 	TO tit_col3
DISPLAY 'Fec. Jub.' 		TO tit_col4
DISPLAY 'Días'			TO tit_col5
DISPLAY 'Valor' 		TO tit_col6

END FUNCTION



FUNCTION control_consulta(estado)
DEFINE estado		CHAR(1)
DEFINE query		CHAR(800)
DEFINE expr_sql		CHAR(400)
DEFINE num_reg		INTEGER
DEFINE foo_anho		INTEGER
DEFINE r_n03		RECORD LIKE rolt003.*

INITIALIZE rm_par.n48_estado, rm_par.n48_cod_liqrol, rm_par.tit_nombre,
		rm_par.n48_fecha_ini, rm_par.n48_fecha_fin TO NULL
CLEAR FORM
CALL mostrar_botones()
IF estado IS NULL THEN
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON n48_estado, n48_cod_liqrol, n48_fecha_ini,
					n48_fecha_fin 
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT CONSTRUCT
		ON KEY(F2)
			IF INFIELD(n48_cod_liqrol) THEN
				CALL fl_ayuda_procesos_roles()
					RETURNING r_n03.n03_proceso,
							r_n03.n03_nombre
				IF r_n03.n03_proceso IS NOT NULL THEN
					LET rm_par.n48_cod_liqrol =
							r_n03.n03_proceso
					LET rm_par.tit_nombre     =
							r_n03.n03_nombre
					DISPLAY BY NAME rm_par.n48_cod_liqrol,
							rm_par.tit_nombre
				END IF
			END IF
			LET int_flag = 0
	END CONSTRUCT
	IF int_flag THEN
		CALL mostrar_salir()
		RETURN
	END IF
ELSE
	LET expr_sql = ' n48_estado = "', estado, '" '
END IF
LET query = 'SELECT n48_cod_liqrol, n48_fecha_ini, n48_fecha_fin ',
		' FROM rolt048 ',
		' WHERE n48_compania   = ', vg_codcia,
		'   AND n48_proceso    = "', vm_proceso, '"',
		'   AND ', expr_sql CLIPPED,
		' GROUP BY 1, 2, 3 ',
		' ORDER BY 3 DESC, 1 ASC'
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
	INITIALIZE rm_par.n48_estado, rm_par.n48_cod_liqrol, rm_par.tit_nombre,
			rm_par.n48_fecha_ini, rm_par.n48_fecha_fin TO NULL
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

IF vm_num_rows <= 0 THEN
	RETURN
END IF
INITIALIZE rm_par.* TO NULL
SELECT UNIQUE n48_estado, n48_proceso,
		(SELECT a.n03_nombre
			FROM rolt003 a
			WHERE a.n03_proceso = n48_proceso),
		n48_cod_liqrol, n03_nombre, n48_fecha_ini, n48_fecha_fin 
	INTO rm_par.*
	FROM rolt048, rolt003
	WHERE n48_compania   = vg_codcia
	  AND n48_cod_liqrol = vm_r_rows[num_registro].n48_cod_liqrol	
	  AND n48_fecha_ini  = vm_r_rows[num_registro].n48_fecha_ini	
	  AND n48_fecha_fin  = vm_r_rows[num_registro].n48_fecha_fin	
	  AND n03_proceso    = n48_cod_liqrol
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro con índice: ' || vm_row_current,'exclamation')
	RETURN
END IF
CALL muestra_estado()
DISPLAY BY NAME	rm_par.*
CALL muestra_detalle()

END FUNCTION



FUNCTION muestra_estado()

CASE rm_par.n48_estado  
	WHEN 'A' DISPLAY 'ACTIVO'    TO tit_estado
	WHEN 'P' DISPLAY 'PROCESADO' TO tit_estado
END CASE

END FUNCTION



FUNCTION control_detalle()

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL ubicarse_en_detalle(0)

END FUNCTION



FUNCTION muestra_detalle()

CALL carga_trabajadores()
CALL ubicarse_en_detalle(1)
	
END FUNCTION



FUNCTION ubicarse_en_detalle(flag)
DEFINE flag		SMALLINT
DEFINE num_row		SMALLINT
DEFINE tot_valor	LIKE rolt036.n36_ganado_per

LET int_flag = 0
CALL set_count(vm_numelm)
DISPLAY ARRAY rm_pat TO rm_pat.*
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT DISPLAY
	ON KEY(F5)
		LET num_row = arr_curr()
		CALL mostrar_empleado(num_row)
		LET int_flag = 0
	ON KEY(F6)
		LET num_row = arr_curr()
		CALL control_contabilizacion(num_row)
		LET int_flag = 0
	ON KEY(F7)
		LET num_row = arr_curr()
		CALL control_forma_pago(num_row)
		LET int_flag = 0
	ON KEY(F8)
		IF rm_par.n48_estado = 'A' THEN
			LET num_row = arr_curr()
			CALL control_eliminacion_pago(num_row)
			LET int_flag = 0
		END IF
	BEFORE DISPLAY
		CALL dialog.keysetlabel('ACCEPT', '')   
		IF rm_par.n48_estado = 'A' THEN
			CALL dialog.keysetlabel("F8", "Eliminación Pago")
		ELSE
			CALL dialog.keysetlabel("F8", "")
		END IF
		CALL calcula_totales() RETURNING tot_valor
		IF flag THEN
			DISPLAY BY NAME tot_valor
        	        LET vm_filas_pant = fgl_scr_size('rm_pat')
			LET int_flag = 0
			EXIT DISPLAY
		END IF
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



FUNCTION carga_trabajadores()

DECLARE q_trab CURSOR FOR 
	SELECT n48_cod_trab, n30_num_doc_id, n30_nombres, n30_fec_jub,
		n48_num_dias, n48_val_jub_pat, n48_tipo_comp, n48_num_comp
        	FROM rolt048, rolt030   
           	WHERE n48_compania   = vg_codcia
		  AND n48_cod_liqrol = rm_par.n48_cod_liqrol
		  AND n48_fecha_ini  = rm_par.n48_fecha_ini
		  AND n48_fecha_fin  = rm_par.n48_fecha_fin
		  AND n48_compania   = n30_compania
		  AND n48_cod_trab   = n30_cod_trab
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



FUNCTION muestra_contadores(row_cur, max_cur)
DEFINE row_cur, max_cur	SMALLINT

DISPLAY BY NAME row_cur, max_cur

END FUNCTION



FUNCTION mostrar_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION mostrar_salir()

IF vm_row_current > 0 THEN
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL mostrar_registro(vm_row_current)
ELSE
	CLEAR FORM
	INITIALIZE rm_par.n48_estado, rm_par.n48_cod_liqrol, rm_par.tit_nombre,
			rm_par.n48_fecha_ini, rm_par.n48_fecha_fin TO NULL
	CALL mostrar_botones()
END IF

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



FUNCTION mostrar_empleado(i)
DEFINE i		SMALLINT
DEFINE param		VARCHAR(60)

LET param = ' ', rm_pat[i].n48_cod_trab
CALL fl_ejecuta_comando('NOMINA', vg_modulo, 'rolp108 ', param, 0)

END FUNCTION



FUNCTION control_imprimir()
DEFINE param		VARCHAR(60)

LET param = ' "', rm_par.n48_cod_liqrol, '" "', rm_par.n48_fecha_ini, '" "',
		rm_par.n48_fecha_fin, '"'
CALL fl_ejecuta_comando('NOMINA', vg_modulo, 'rolp419 ', param, 0)

END FUNCTION



FUNCTION control_recibos()
DEFINE param		VARCHAR(60)

LET param = ' "', rm_par.n48_cod_liqrol, '" "', rm_par.n48_fecha_ini, '" "',
		rm_par.n48_fecha_fin, '"'
CALL fl_ejecuta_comando('NOMINA', vg_modulo, 'rolp404 ', param, 0)

END FUNCTION



FUNCTION control_cerrar_reabrir(estado)
DEFINE estado		LIKE rolt048.n48_estado
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
        		WHERE n48_compania   = $vg_codcia
			  AND n48_proceso    = $rm_par.n48_proceso
			  AND n48_cod_liqrol = $rm_par.n48_cod_liqrol
	END SQL
	IF rm_par.n48_cod_liqrol <> "ME" AND YEAR(fecha) = YEAR(TODAY) THEN
		LET fecha = fecha - 1 UNITS DAY
	END IF
	LET fecha2 = vm_r_rows[vm_row_current].n48_fecha_fin
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
        WHERE n48_compania   = vg_codcia
	  AND n48_cod_liqrol = vm_r_rows[vm_row_current].n48_cod_liqrol
	  AND n48_fecha_ini  = vm_r_rows[vm_row_current].n48_fecha_ini
	  AND n48_fecha_fin  = vm_r_rows[vm_row_current].n48_fecha_fin
COMMIT WORK
CALL mostrar_registro(vm_row_current)	
CALL muestra_contadores(vm_row_current, vm_num_rows)
LET mensaje = 'El rol ha sido '
CASE estado
	WHEN 'A' LET mensaje = mensaje CLIPPED, ' ACTIVADO.'
	WHEN 'P' LET mensaje = mensaje CLIPPED, ' PROCESADO.'
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
			--LET rm_n48.n48_cta_trabaj = NULL
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
			IF rm_n48.n48_bco_empresa IS NOT NULL OR
			   rm_n48.n48_cta_empresa IS NOT NULL
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
	WHERE n48_compania   = vg_codcia
	  AND n48_cod_liqrol = rm_n48.n48_cod_liqrol
	  AND n48_fecha_ini  = rm_n48.n48_fecha_ini
	  AND n48_fecha_fin  = rm_n48.n48_fecha_fin
	  AND n48_cod_trab   = rm_n48.n48_cod_trab
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
IF r_cta.b10_nivel <> vm_nivel THEN
	CALL fl_mostrar_mensaje('Nivel de cuenta debe ser solo del último.', 'exclamation')
	RETURN 0
END IF
RETURN 1

END FUNCTION




FUNCTION control_contabilizacion(num_registro)
DEFINE num_registro	INTEGER
DEFINE r_n48		RECORD LIKE rolt048.*
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE tipo_pago	LIKE rolt048.n48_tipo_pago
DEFINE fec_fin		LIKE rolt048.n48_fecha_fin
DEFINE tip_comp		LIKE rolt048.n48_tipo_comp
DEFINE num_comp		LIKE rolt048.n48_num_comp
DEFINE nombre		LIKE rolt030.n30_nombres
DEFINE cont		INTEGER
DEFINE num_r		SMALLINT
DEFINE query		CHAR(1200)
DEFINE mensaje		VARCHAR(250)
DEFINE resp		CHAR(6)

IF num_registro > 0 THEN
	CALL lee_reg_jub(num_registro) RETURNING rm_n48.*
	IF rm_n48.n48_tipo_comp IS NOT NULL THEN
		CALL ver_contabilizacion(rm_n48.n48_tipo_comp,
						rm_n48.n48_num_comp)
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
ELSE	
	IF rm_par.n48_estado <> 'P' THEN
		CALL fl_mostrar_mensaje('El rol de pago de los JUBILADOS debe estar PROCESADO, para contabilizar la transferencia al banco.', 'exclamation')
		RETURN
	END IF
	SQL
		SELECT NVL(MAX(n48_fecha_fin), TODAY)
			INTO $fec_fin
			FROM rolt048
			WHERE n48_compania   = $vg_codcia
			  AND n48_proceso    = $rm_par.n48_proceso
			  AND n48_cod_liqrol = $rm_par.n48_cod_liqrol
	END SQL
	IF rm_par.n48_fecha_fin < fec_fin THEN
		CALL fl_mostrar_mensaje('El rol de pago de los JUBILADOS debe ser el último PROCESADO, para contabilizar la transferencia al banco.', 'exclamation')
		RETURN
	END IF
	INITIALIZE tip_comp, num_comp TO NULL
	DECLARE q_v_c CURSOR FOR
		SELECT n48_tipo_comp, n48_num_comp, COUNT(*)
			FROM rolt048
			WHERE n48_compania   = vg_codcia
			  AND n48_proceso    = rm_par.n48_proceso
			  AND n48_cod_liqrol = rm_par.n48_cod_liqrol
			  AND n48_fecha_ini  = rm_par.n48_fecha_ini
			  AND n48_fecha_fin  = rm_par.n48_fecha_fin
			  AND n48_tipo_pago  = "T"
		GROUP BY 1, 2
	OPEN q_v_c
	FETCH q_v_c INTO tip_comp, num_comp, cont
	CLOSE q_v_c
	FREE q_v_c
	IF tip_comp IS NOT NULL THEN
		CALL ver_contabilizacion(tip_comp, num_comp)
		RETURN
	END IF
	IF cont = 0 THEN
		CALL fl_mostrar_mensaje('No existe ningún registro de jubilado para ser transferido.', 'exclamation')
		RETURN
	END IF
	LET int_flag = 0
	CALL fl_hacer_pregunta('Desea generar Contabilización por Transferencia al Banco de este rol de pago ?', 'No')
		RETURNING resp
	IF resp <> 'Yes' THEN
		RETURN
	END IF
END IF
IF num_registro > 0 THEN
	LET query = 'SELECT rolt048.*, "" n30_nombres ',
			'FROM rolt048 ',
			'WHERE n48_compania   = ', vg_codcia,
			'  AND n48_cod_liqrol = "',
				vm_r_rows[vm_row_current].n48_cod_liqrol, '"',
			'  AND n48_fecha_ini  = DATE("',
				vm_r_rows[vm_row_current].n48_fecha_ini, '")',
			'  AND n48_fecha_fin  = DATE("',
				vm_r_rows[vm_row_current].n48_fecha_fin, '")',
			'  AND n48_cod_trab   = ',
				rm_pat[num_registro].n48_cod_trab
ELSE
	LET query = 'SELECT rolt048.*, n30_nombres ',
			'FROM rolt048, rolt030 ',
			'WHERE n48_compania   = ', vg_codcia,
			'  AND n48_cod_liqrol = "', rm_par.n48_cod_liqrol, '"',
			'  AND n48_fecha_ini  = DATE("', rm_par.n48_fecha_ini,
							'")',
			'  AND n48_fecha_fin  = DATE("', rm_par.n48_fecha_fin,
							'")',
			'  AND n48_tipo_pago  = "T"',
			'  AND n48_compania   = n30_compania ',
			'  AND n48_cod_trab   = n30_cod_trab ',
			' ORDER BY n30_nombres '
END IF
LET r_n48.* = rm_n48.*
BEGIN WORK
	WHENEVER ERROR CONTINUE
	PREPARE cons_cont FROM query
	DECLARE q_cont CURSOR WITH HOLD FOR cons_cont
		--FOR UPDATE
	OPEN q_cont
	FETCH q_cont INTO rm_n48.*, nombre
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
	IF num_registro > 0 THEN
		UPDATE rolt048
			SET n48_tipo_pago   = rm_n48.n48_tipo_pago,
			    n48_bco_empresa = rm_n48.n48_bco_empresa,
			    n48_cta_empresa = rm_n48.n48_cta_empresa,
			    n48_cta_trabaj  = rm_n48.n48_cta_trabaj
			--WHERE CURRENT OF q_cont
			WHERE n48_compania   = vg_codcia
			  AND n48_proceso    = rm_n48.n48_proceso
			  AND n48_cod_liqrol = rm_n48.n48_cod_liqrol
			  AND n48_fecha_ini  = rm_n48.n48_fecha_ini
			  AND n48_fecha_fin  = rm_n48.n48_fecha_fin
			  AND n48_cod_trab   = rm_n48.n48_cod_trab
		IF STATUS < 0 THEN
			ROLLBACK WORK
			WHENEVER ERROR STOP
			CALL fl_mostrar_mensaje('Ha ocurrido un error interno de la base de datos al intentar actualizar el registro. Consulte con el Administrador.', 'exclamation')
			RETURN
		END IF
	END IF
	WHENEVER ERROR STOP
	CALL generar_contabilizacion(nombre, num_registro)
		RETURNING r_b12.*, num_r
	IF r_b12.b12_compania IS NULL THEN
		ROLLBACK WORK
		WHENEVER ERROR STOP
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
IF num_registro > 0 THEN
	CALL lee_reg_jub(num_registro) RETURNING rm_n48.*
	LET mensaje = 'Contabilización del Jubilado Generada Ok.'
ELSE
	LET rm_n48.* = r_n48.*
	LET mensaje = 'Se contabilizaron por Transf. a Cta. ',
			num_r USING "<<<<&", ' Jubilados Ok.'
END IF
CALL fl_mostrar_mensaje(mensaje, 'info')

END FUNCTION



FUNCTION generar_contabilizacion(nombre, num_registro)
DEFINE nombre		LIKE rolt030.n30_nombres
DEFINE num_registro	INTEGER
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_g14		RECORD LIKE gent014.*
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n48		RECORD LIKE rolt048.*
DEFINE r_n56		RECORD LIKE rolt056.*
DEFINE glosa		LIKE ctbt012.b12_glosa
DEFINE fecha		LIKE ctbt012.b12_fec_proceso
DEFINE num_che		LIKE ctbt012.b12_num_cheque
DEFINE sec		LIKE ctbt013.b13_secuencia
DEFINE valor_pago	DECIMAL(14,2)
DEFINE valor_cuad	DECIMAL(14,2)
DEFINE query		CHAR(1000)
DEFINE expr_sql		VARCHAR(200)
DEFINE expr_sql2	CHAR(500)
DEFINE num_r		SMALLINT

LET num_r = 0
INITIALIZE r_b12.* TO NULL
LET r_b12.b12_compania 	  = vg_codcia
CASE rm_n48.n48_tipo_pago
	WHEN 'E' LET r_b12.b12_tipo_comp = "DC"
	WHEN 'C' LET r_b12.b12_tipo_comp = "EG"
	WHEN 'T' LET r_b12.b12_tipo_comp = "DN"
END CASE
LET r_b12.b12_fec_proceso = rm_par.n48_fecha_fin
IF TODAY < r_b12.b12_fec_proceso OR rm_n48.n48_cod_liqrol <> "ME" THEN
	LET r_b12.b12_fec_proceso = TODAY
END IF
IF NOT validacion_contable(r_b12.b12_fec_proceso) THEN
	INITIALIZE r_b12.* TO NULL
	RETURN r_b12.*, num_r
END IF
LET r_b12.b12_estado 	  = 'A'
CALL fl_lee_proceso_roles(rm_n48.n48_cod_liqrol) RETURNING r_n03.*
IF nombre IS NULL THEN
	CALL fl_lee_trabajador_roles(vg_codcia, rm_n48.n48_cod_trab)
		RETURNING r_n30.*
	LET nombre = r_n30.n30_nombres
END IF
IF rm_n48.n48_tipo_pago <> 'T' THEN
	LET r_b12.b12_glosa = nombre[1, 25] CLIPPED
ELSE
	LET r_b12.b12_glosa = 'TRANSF. A CTA. BANCO'
END IF
LET r_b12.b12_glosa       = r_b12.b12_glosa CLIPPED, ', PAGO DE JUBILACION (',
				r_n03.n03_nombre_abr CLIPPED, ')'
IF rm_n48.n48_tipo_pago = 'C' THEN
	LET r_b12.b12_benef_che = nombre CLIPPED
	CALL lee_cheque(r_b12.*) RETURNING num_che, fecha, glosa
	IF int_flag THEN
		CALL fl_mostrar_mensaje('No se generara el cheque de pago para este jubilado.', 'exclamation')
		INITIALIZE r_b12.* TO NULL
		RETURN r_b12.*, num_r
	END IF
	LET r_b12.b12_num_cheque = num_che
	LET r_b12.b12_glosa      = glosa CLIPPED
	IF r_b12.b12_fec_proceso <> fecha THEN
		LET r_b12.b12_fec_proceso = fecha
	END IF
END IF
LET r_b12.b12_num_comp    = fl_numera_comprobante_contable(vg_codcia,
						r_b12.b12_tipo_comp,
						YEAR(r_b12.b12_fec_proceso),
						MONTH(r_b12.b12_fec_proceso))
IF r_b12.b12_num_comp <= 0 THEN
	INITIALIZE r_b12.* TO NULL
	RETURN r_b12.*, num_r
END IF
LET r_b12.b12_glosa  = r_b12.b12_glosa CLIPPED, ' JUB. ',
			rm_n48.n48_ano_proceso USING "&&&&", '-',
			rm_n48.n48_mes_proceso USING "&&"
LET r_b12.b12_origen = 'A'
CALL fl_lee_moneda(rg_gen.g00_moneda_base) RETURNING r_g13.*
IF r_g13.g13_moneda  = rg_gen.g00_moneda_base THEN
	LET r_g14.g14_tasa = 1
ELSE
	CALL fl_lee_factor_moneda(r_g13.g13_moneda, rg_gen.g00_moneda_base)
		RETURNING r_g14.*
	IF r_g14.g14_serial IS NULL THEN
		CALL fl_mostrar_mensaje('La paridad para esta moneda no existe.', 'stop')
		INITIALIZE r_b12.* TO NULL
		RETURN r_b12.*, num_r
	END IF
END IF
LET r_b12.b12_moneda      = r_g13.g13_moneda
LET r_b12.b12_paridad     = r_g14.g14_tasa
LET r_b12.b12_modulo      = vg_modulo
LET r_b12.b12_usuario     = vg_usuario
LET r_b12.b12_fecing      = CURRENT
INSERT INTO ctbt012 VALUES (r_b12.*) 
LET sec        = 1
LET valor_pago = 0
FOREACH q_cont INTO rm_n48.*, r_n30.n30_nombres
	INITIALIZE r_n56.* TO NULL
	CALL fl_lee_trabajador_roles(vg_codcia, rm_n48.n48_cod_trab)
		RETURNING r_n30.*
	SELECT * INTO r_n56.*
		FROM rolt056
		WHERE n56_compania  = vg_codcia
		  AND n56_proceso   = vm_proceso
		  AND n56_cod_depto = r_n30.n30_cod_depto
		  AND n56_cod_trab  = rm_n48.n48_cod_trab
		  AND n56_estado    = "A"
	IF r_n56.n56_compania IS NULL THEN
		CALL fl_lee_proceso_roles(rm_par.n48_proceso) RETURNING r_n03.*
		CALL fl_mostrar_mensaje('No existen auxiliares contable para este trabajador en el proceso de ' || r_n03.n03_nombre CLIPPED || '.', 'stop')
		INITIALIZE r_b12.* TO NULL
		EXIT FOREACH
	END IF
	CALL generar_detalle_contable(r_b12.*, r_n56.n56_aux_val_vac,
				rm_n48.n48_val_jub_pat, 'D', sec, 0, 'S',
				r_n30.n30_nombres)
	LET sec        = sec + 1
	LET valor_pago = valor_pago + rm_n48.n48_val_jub_pat
END FOREACH
IF r_b12.b12_compania IS NULL THEN
	RETURN r_b12.*, num_r
END IF
CALL generar_detalle_contable(r_b12.*, r_n56.n56_aux_banco, valor_pago,
				'H', sec, 1, 'S', r_n30.n30_nombres)
SELECT NVL(SUM(b13_valor_base), 0)
	INTO valor_cuad
	FROM ctbt013
	WHERE b13_compania  = vg_codcia
	  AND b13_tipo_comp = r_b12.b12_tipo_comp
	  AND b13_num_comp  = r_b12.b12_num_comp
IF valor_cuad <> 0 THEN
	CALL fl_mostrar_mensaje('Se ha generado un error en la contabilizacion. POR FAVOR LLAME AL ADMINISTRADOR.', 'stop')
	INITIALIZE r_b12.* TO NULL
	RETURN r_b12.*, num_r
END IF
IF num_registro > 0 THEN
	LET expr_sql = '   AND n48_cod_trab   = ', rm_n48.n48_cod_trab
ELSE
	LET expr_sql = '   AND n48_tipo_pago  = "T"',
			'   AND n48_tipo_comp  IS NULL '
END IF
LET expr_sql2 = ' WHERE n48_compania   = ', vg_codcia,
		'   AND n48_cod_liqrol = "', rm_n48.n48_cod_liqrol, '"',
		'   AND n48_fecha_ini  = "', rm_n48.n48_fecha_ini, '"',
		'   AND n48_fecha_fin  = "', rm_n48.n48_fecha_fin, '"'
LET query = 'UPDATE rolt048 ',
		'SET n48_tipo_comp = "', r_b12.b12_tipo_comp, '",',
		   ' n48_num_comp  = "', r_b12.b12_num_comp, '"',
		expr_sql2 CLIPPED,
		expr_sql CLIPPED
PREPARE exec_up FROM query
EXECUTE exec_up
IF num_registro = 0 THEN
	LET expr_sql = '   AND n48_tipo_pago  = "T"',
			'   AND n48_tipo_comp  IS NOT NULL '
END IF
LET query = 'SELECT COUNT(*) num_reg',
		' FROM rolt048 ',
		expr_sql2 CLIPPED,
		expr_sql CLIPPED,
		' INTO TEMP t1 '
PREPARE exec_t1_2 FROM query
EXECUTE exec_t1_2
SELECT * INTO num_r FROM t1
DROP TABLE t1
RETURN r_b12.*, num_r

END FUNCTION



FUNCTION validacion_contable(fecha)
DEFINE fecha		DATE
DEFINE resp 		VARCHAR(6)

IF YEAR(fecha) < YEAR(rm_b00.b00_fecha_cm) OR
  (YEAR(fecha) = YEAR(rm_b00.b00_fecha_cm) AND
   MONTH(fecha) <= MONTH(rm_b00.b00_fecha_cm))
THEN
	CALL fl_mostrar_mensaje('El Mes en Contabilidad esta cerrado. Reapertúrelo para que se pueda generar la contabilización de Jubilados.', 'stop')
	RETURN 0
END IF
IF fecha_bloqueada(vg_codcia, MONTH(fecha), YEAR(fecha)) THEN
	CALL fl_mostrar_mensaje('No puede generar contabilización de Jubilados de un mes bloqueado en CONTABILIDAD.', 'stop')
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
DEFINE fecha		LIKE ctbt012.b12_fec_proceso
DEFINE mensaje		VARCHAR(200)

OPEN WINDOW w_rolf208_3 AT 09, 12 WITH FORM "../forms/rolf208_3" 
	ATTRIBUTE(BORDER, COMMENT LINE LAST, FORM LINE FIRST)
LET int_flag = 0
INPUT BY NAME r_b12.b12_num_cheque, r_b12.b12_fec_proceso, r_b12.b12_glosa
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD b12_fec_proceso
		LET fecha = r_b12.b12_fec_proceso
	BEFORE FIELD b12_glosa
		LET glosa = r_b12.b12_glosa
	AFTER FIELD b12_num_cheque
		IF r_b12.b12_num_cheque IS NULL THEN
			NEXT FIELD b12_num_cheque
		END IF
	AFTER FIELD b12_fec_proceso
		IF r_b12.b12_fec_proceso IS NULL THEN
			LET r_b12.b12_fec_proceso = fecha
			DISPLAY BY NAME r_b12.b12_fec_proceso
		END IF
		IF r_b12.b12_fec_proceso > TODAY THEN
			CALL fl_mostrar_mensaje('La fecha de pago no puede ser mayor que la fecha de hoy.', 'exclamation')
			NEXT FIELD b12_fec_proceso
		END IF
		IF r_b12.b12_fec_proceso <
		   MDY(MONTH(rm_par.n48_fecha_fin), 01,
			YEAR(rm_par.n48_fecha_fin))
		THEN
			LET mensaje = 'La fecha de pago no puede ser menor ',
					' que la fecha: ',
		   			DATE(MDY(MONTH(rm_par.n48_fecha_fin),
						01, YEAR(rm_par.n48_fecha_fin)))
					USING "dd-mm-yyyy", '.'
			CALL fl_mostrar_mensaje(mensaje, 'exclamation')
			NEXT FIELD b12_fec_proceso
		END IF
	AFTER FIELD b12_glosa
		IF r_b12.b12_glosa IS NULL THEN
			LET r_b12.b12_glosa = glosa
			DISPLAY BY NAME r_b12.b12_glosa
		END IF
	AFTER INPUT
		IF r_b12.b12_num_cheque IS NULL THEN
			NEXT FIELD b12_num_cheque
		END IF
END INPUT
CLOSE WINDOW w_rolf208_3
RETURN r_b12.b12_num_cheque, r_b12.b12_fec_proceso, r_b12.b12_glosa

END FUNCTION



FUNCTION generar_detalle_contable(r_b12, cuenta, valor, tipo, sec, flag_bco,
					flag, nombre)
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE valor		LIKE ctbt013.b13_valor_base
DEFINE tipo		CHAR(1)
DEFINE sec		LIKE ctbt013.b13_secuencia
DEFINE flag_bco		SMALLINT
DEFINE flag		CHAR(1)
DEFINE nombre		LIKE rolt030.n30_nombres
DEFINE mes		VARCHAR(10)
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
LET mes                   = UPSHIFT(fl_justifica_titulo('I',
			fl_retorna_nombre_mes(MONTH(r_b12.b12_fec_proceso)),10))
CASE rm_n48.n48_tipo_pago
	WHEN 'E' LET r_b13.b13_glosa = 'LIQ.PAG.JUB. '
	WHEN 'C' LET r_b13.b13_glosa = 'LIQ.CHE.JUB. '
	WHEN 'T' LET r_b13.b13_glosa = 'LIQ.TRA.JUB. '
END CASE
IF rm_n48.n48_tipo_pago <> "T" THEN
	LET r_b13.b13_glosa = r_b13.b13_glosa CLIPPED, ' ',
				rm_n48.n48_cod_trab USING "<<<&&", ' '
ELSE
	LET r_b13.b13_glosa = r_b13.b13_glosa CLIPPED, ' ',nombre[1, 30] CLIPPED
END IF
LET r_b13.b13_glosa       = r_b13.b13_glosa CLIPPED, ' (',
				rm_n48.n48_cod_liqrol CLIPPED, '). EN ',
				mes[1, 3], '/',
				YEAR(rm_n48.n48_fecing) USING "&&&&"
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



FUNCTION control_eliminacion_pago(num_registro)
DEFINE num_registro	INTEGER
DEFINE resp		CHAR(6)
DEFINE resul		SMALLINT

CALL lee_reg_jub(num_registro) RETURNING rm_n48.*
IF rm_n48.n48_tipo_comp IS NULL THEN
	CALL fl_mostrar_mensaje('No existe comprobante de pago contable.', 'exclamation')
	RETURN
END IF
LET int_flag = 0
CALL fl_hacer_pregunta('Esta seguro de ELIMINAR el pago de este jubilado ?',
			'No')
	RETURNING resp
IF resp <> 'Yes' THEN
	RETURN
END IF
CALL fl_mayoriza_comprobante(rm_n48.n48_compania, rm_n48.n48_tipo_comp,
				rm_n48.n48_num_comp, 'D')
SET LOCK MODE TO WAIT 5
LET resul = 1
BEGIN WORK
	WHENEVER ERROR CONTINUE
	UPDATE ctbt012
		SET b12_estado     = 'E',
		    b12_fec_modifi = CURRENT 
		WHERE b12_compania  = rm_n48.n48_compania
		  AND b12_tipo_comp = rm_n48.n48_tipo_comp
		  AND b12_num_comp  = rm_n48.n48_num_comp
	IF STATUS <> 0 THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('Ha ocurrido un error al intentar cambiar el estado del diario contable. Por favor llame al ADMINISTRADOR.', 'exclamation')
		WHENEVER ERROR STOP
		LET resul = 0
	END IF
	IF resul THEN
		WHENEVER ERROR CONTINUE
		UPDATE rolt048
			SET n48_tipo_comp = NULL,
			    n48_num_comp  = NULL
			WHERE n48_compania   = vg_codcia
			  AND n48_cod_liqrol = rm_n48.n48_cod_liqrol
			  AND n48_fecha_ini  = rm_n48.n48_fecha_ini
			  AND n48_fecha_fin  = rm_n48.n48_fecha_fin
			  AND n48_cod_trab   = rm_n48.n48_cod_trab
		IF STATUS <> 0 THEN
			ROLLBACK WORK
			CALL fl_mostrar_mensaje('Ha ocurrido un error al intentar devincular el diario contable de este jubilado. Por favor llame al ADMINISTRADOR.', 'exclamation')
			WHENEVER ERROR STOP
			LET resul = 0
		END IF
	END IF
	IF NOT resul THEN
		CALL fl_mayoriza_comprobante(rm_n48.n48_compania,
						rm_n48.n48_tipo_comp,
						rm_n48.n48_num_comp, 'M')
		SET LOCK MODE TO WAIT 5
		CALL fl_mostrar_mensaje('No se pudo Eliminar este pago.', 'exclamation')
		RETURN
	END IF
	WHENEVER ERROR STOP
COMMIT WORK
CALL fl_mostrar_mensaje('Este pago ha sido ELIMINADO OK.', 'info')

END FUNCTION



FUNCTION lee_reg_jub(num_registro)
DEFINE num_registro	INTEGER

INITIALIZE rm_n48.* TO NULL
SELECT * INTO rm_n48.*
	FROM rolt048 
	WHERE n48_compania   = vg_codcia
	  AND n48_cod_liqrol = vm_r_rows[vm_row_current].n48_cod_liqrol
	  AND n48_fecha_ini  = vm_r_rows[vm_row_current].n48_fecha_ini
	  AND n48_fecha_fin  = vm_r_rows[vm_row_current].n48_fecha_fin
	  AND n48_cod_trab   = rm_pat[num_registro].n48_cod_trab
RETURN rm_n48.*

END FUNCTION



FUNCTION lee_reg_jub2(cod_liqrol, anio, mes, cod_trab)
DEFINE cod_liqrol	LIKE rolt048.n48_cod_liqrol
DEFINE anio		LIKE rolt048.n48_ano_proceso
DEFINE mes		LIKE rolt048.n48_mes_proceso
DEFINE cod_trab		LIKE rolt048.n48_cod_trab
DEFINE r_n48		RECORD LIKE rolt048.*

INITIALIZE r_n48.* TO NULL
SELECT * INTO r_n48.*
	FROM rolt048 
	WHERE n48_compania    = vg_codcia
	  AND n48_cod_liqrol  = cod_liqrol
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



FUNCTION generar_archivo()
DEFINE query 		CHAR(6000)
DEFINE archivo		VARCHAR(100)
DEFINE mensaje		VARCHAR(200)
DEFINE nom_mes		VARCHAR(10)
DEFINE r_g31		RECORD LIKE gent031.*

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
			' 0 AS secu, "" AS comp_p, n48_cod_trab AS cod_emp,',
			' g13_simbolo AS mone,',
			' TRUNC(n48_val_jub_pat * 100, 0) AS neto_rec,',
			' "CTA" AS for_pag, "0040" AS cod_ban,',
			' CASE WHEN n30_tipo_cta_tra = "A"',
				' THEN "AHO"',
				' ELSE "CTE"',
			' END AS tipo_c, n48_cta_trabaj AS cuenta_empl,',
			' n30_tipo_doc_id AS tipo_id,n30_num_doc_id AS cedula,',
			' n30_nombres AS empleados, n30_domicilio AS direc,',
			' g31_nombre AS ciudad_emp, n30_telef_domic AS fono,',
			' "" AS loc_cob, n03_nombre AS refer1,',
			' CASE',
				' WHEN n48_mes_proceso = 01 THEN "ENERO"',
				' WHEN n48_mes_proceso = 02 THEN "FEBRERO"',
				' WHEN n48_mes_proceso = 03 THEN "MARZO"',
				' WHEN n48_mes_proceso = 04 THEN "ABRIL"',
				' WHEN n48_mes_proceso = 05 THEN "MAYO"',
				' WHEN n48_mes_proceso = 06 THEN "JUNIO"',
				' WHEN n48_mes_proceso = 07 THEN "JULIO"',
				' WHEN n48_mes_proceso = 08 THEN "AGOSTO"',
				' WHEN n48_mes_proceso = 09 THEN "SEPTIEMBRE"',
				' WHEN n48_mes_proceso = 10 THEN "OCTUBRE"',
				' WHEN n48_mes_proceso = 11 THEN "NOVIEMBRE"',
				' WHEN n48_mes_proceso = 12 THEN "DICIEMBRE"',
			' END || "-" || LPAD(n48_ano_proceso, 4, 0) AS refer2',
		' FROM rolt048, rolt030, gent009, gent013, gent031, rolt003 ',
		' WHERE n48_compania     = ', vg_codcia,
		'   AND n48_proceso      = "', rm_par.n48_proceso, '"',
		'   AND n48_cod_liqrol   = "', rm_par.n48_cod_liqrol, '"',
		'   AND n48_fecha_ini    = "', rm_par.n48_fecha_ini, '"',
		'   AND n48_fecha_fin    = "', rm_par.n48_fecha_fin, '"',
		'   AND n48_estado      <> "E"',
		'   AND n48_tipo_pago    = "T"',
		'   AND n48_val_jub_pat  > 0 ',
  		'   AND n30_compania     = n48_compania ',
		'   AND n30_cod_trab     = n48_cod_trab ',
		'   AND g09_compania     = n48_compania ',
		'   AND g09_banco        = n48_bco_empresa ',
		'   AND n03_proceso      = n48_proceso ',
		'   AND g13_moneda       = n48_moneda ',
		'   AND g31_ciudad       = n30_ciudad_nac ',
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
		' "JUBILADO" referencia, referencia_adic',
		' FROM tmp_rol_ban ',
		' INTO TEMP t1 '
PREPARE exec_t1 FROM query
EXECUTE exec_t1
DROP TABLE tmp_rol_ban
UNLOAD TO "../../../tmp/rol_pag.txt" DELIMITER "	"
	SELECT * FROM t1
		ORDER BY secuencia
LET nom_mes = UPSHIFT(fl_justifica_titulo('I',
			fl_retorna_nombre_mes(MONTH(rm_par.n48_fecha_fin)), 11))
LET archivo = "ACRE_", rm_loc.g02_nombre[1, 3] CLIPPED, "_", vm_proceso,
		nom_mes[1, 3] CLIPPED, YEAR(rm_par.n48_fecha_fin) USING "####",
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
