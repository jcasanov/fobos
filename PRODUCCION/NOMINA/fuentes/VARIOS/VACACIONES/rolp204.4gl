--------------------------------------------------------------------------------
-- Titulo           : rolp204.4gl - Cierre liquidacion de roles
-- Elaboracion      : 07-Ago-2003
-- Autor            : YEC
-- Formato Ejecucion: fglrun rolp204 base modulo compania [cod_trab] [flag]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_n00		RECORD LIKE rolt000.*  
DEFINE rm_n01		RECORD LIKE rolt001.*  
DEFINE rm_n05		RECORD LIKE rolt005.*  
DEFINE rm_par RECORD 
	n32_cod_liqrol		LIKE rolt032.n32_cod_liqrol,
	n_liqrol		LIKE rolt003.n03_nombre,
	n32_fecha_ini		LIKE rolt032.n32_fecha_ini,
	n32_fecha_fin		LIKE rolt032.n32_fecha_fin,
	n32_ano_proceso		LIKE rolt032.n32_ano_proceso,
	n32_mes_proceso		LIKE rolt032.n32_mes_proceso,
	n_mes			VARCHAR(12)
END RECORD
DEFINE vm_num_liq	SMALLINT
DEFINE vm_cod_trab	INTEGER



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp204.err')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 5 THEN -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso  = 'rolp204'
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

CALL fl_nivel_isolation()
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_201 AT 3,2 WITH 13 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_204 FROM '../forms/rolf204_1'
DISPLAY FORM f_204
CALL control_cierre_liquidacion_roles()

END FUNCTION



FUNCTION control_cierre_liquidacion_roles()
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE mensaje		VARCHAR(250)
DEFINE num		SMALLINT
DEFINE resp		CHAR(10)

DEFINE estado		LIKE rolt032.n32_estado
DEFINE query		VARCHAR(500)

CALL fl_lee_parametro_general_roles()  RETURNING rm_n00.*
IF rm_n00.n00_serial IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'No existe configuración general para este módulo.',
		'stop')
	EXIT PROGRAM
END IF
INITIALIZE rm_par.* TO NULL
CALL fl_lee_compania_roles(vg_codcia) RETURNING rm_n01.*
IF rm_n01.n01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'No existe configuración para esta compañía.',
		'stop')
	EXIT PROGRAM
END IF
IF rm_n01.n01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto,
		'Compañía no está activa.', 'stop')
	EXIT PROGRAM
END IF
LET rm_par.n32_ano_proceso = rm_n01.n01_ano_proceso
LET rm_par.n32_mes_proceso = rm_n01.n01_mes_proceso
LET rm_par.n_mes           = 
	fl_justifica_titulo('I', 
		fl_retorna_nombre_mes(rm_par.n32_mes_proceso), 12)
INITIALIZE rm_n05.* TO NULL
SELECT * INTO rm_n05.* FROM rolt005
	WHERE n05_compania = vg_codcia
	  AND n05_activo   = 'S'
IF rm_n05.n05_compania IS NULL THEN
        CALL fl_mostrar_mensaje('No existe una liquidación activa.', 'stop')
	EXIT PROGRAM
END IF

LET estado = 'A'
INITIALIZE vm_cod_trab TO NULL
IF num_args() = 5 AND arg_val(5) = 'F' THEN
	LET vm_cod_trab = arg_val(4)
	LET estado = 'F'
END IF

LET query = 'SELECT * FROM rolt032 WHERE n32_compania = ', vg_codcia
IF estado = 'F' THEN
	LET query = query, ' AND n32_cod_trab = ', vm_cod_trab
END IF
LET query = query, ' AND n32_estado = "', estado, '"',
			' ORDER BY n32_fecha_ini DESC '

INITIALIZE r_n32.* TO NULL
PREPARE ultliq FROM query
DECLARE q_ultliq CURSOR FOR ultliq
		      
OPEN q_ultliq 
FETCH q_ultliq INTO r_n32.*
IF r_n32.n32_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No hay liquidaciones de roles generadas en rolt032.', 'stop')
	EXIT PROGRAM
END IF
LET rm_par.n32_cod_liqrol = r_n32.n32_cod_liqrol
LET rm_par.n32_fecha_ini  = r_n32.n32_fecha_ini
LET rm_par.n32_fecha_fin  = r_n32.n32_fecha_fin
IF r_n32.n32_cod_liqrol <> rm_n05.n05_proceso THEN
	IF estado <> 'F' AND rm_n05.n05_proceso <> 'AF' THEN
		LET mensaje = 'Inconsistencia entre liquidacion de roles activa en ',
			      'rolt032 y rolt005.'
		CALL fl_mostrar_mensaje(mensaje, 'stop')
	        EXIT PROGRAM                                           
	END IF
END IF
CALL fl_lee_proceso_roles(rm_par.n32_cod_liqrol) RETURNING r_n03.*
LET rm_par.n_liqrol = r_n03.n03_nombre
DISPLAY BY NAME rm_par.*
CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
IF resp <> 'Yes' THEN
	EXIT PROGRAM
END IF
BEGIN WORK
	CALL cerrar_nomina()
COMMIT WORK
LET mensaje = 'Proceso Terminado Ok.'
IF num_args() <> 5 THEN
	CALL fl_mostrar_mensaje(mensaje, 'info')
END IF

END FUNCTION



FUNCTION cerrar_nomina()
DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE r_n33		RECORD LIKE rolt033.*
DEFINE r_n13		RECORD LIKE rolt013.*
DEFINE r_n45		RECORD LIKE rolt045.*
DEFINE r_n64		RECORD LIKE rolt064.*
DEFINE fecha_ini	LIKE rolt038.n38_fecha_ini
DEFINE fecha_fin	LIKE rolt038.n38_fecha_fin
DEFINE tot_valor	DECIMAL(12,2)
DEFINE tot_egr		DECIMAL(12,2)
DEFINE tot_ing		DECIMAL(12,2)
DEFINE mensaje		VARCHAR(200)
DEFINE query		VARCHAR(500)

DEFINE fact_aporte_trab	DECIMAL(5,2)
DEFINE aporte_patr	LIKE rolt080.n80_sac_patr

DEFINE r_n30 		RECORD LIKE rolt030.*
DEFINE r_n80_cur	RECORD LIKE rolt080.*
DEFINE r_n80_old	RECORD LIKE rolt080.*
DEFINE r_n80_new	RECORD LIKE rolt080.*

UPDATE rolt032 SET n32_estado = 'C' WHERE n32_estado = 'A'

INITIALIZE r_n32.n32_estado TO NULL
SELECT n32_estado INTO r_n32.n32_estado FROM rolt032
	WHERE n32_compania   = vg_codcia 
	  AND n32_cod_liqrol = rm_par.n32_cod_liqrol
          AND n32_fecha_ini  = rm_par.n32_fecha_ini 
          AND n32_fecha_fin  = rm_par.n32_fecha_fin
          AND n32_estado     = 'C'
	GROUP BY n32_estado

IF vm_cod_trab IS NULL AND r_n32.n32_estado IS NOT NULL THEN
	LET rm_n05.n05_activo     = 'N'
	LET rm_n05.n05_fecini_act = NULL
	LET rm_n05.n05_fecfin_act = NULL
	LET rm_n05.n05_fec_ultcie = rm_n05.n05_fec_cierre
	LET rm_n05.n05_fec_cierre = TODAY
	UPDATE rolt005 SET * = rm_n05.*
		WHERE n05_compania = rm_n05.n05_compania AND 
		      n05_proceso  = rm_n05.n05_proceso
END IF
DECLARE q_prest CURSOR FOR 
	SELECT * FROM rolt033
		WHERE n33_compania   = rm_n05.n05_compania   AND 
                      n33_cod_liqrol = rm_par.n32_cod_liqrol AND 
                      n33_fecha_ini  = rm_par.n32_fecha_ini  AND 
                      n33_fecha_fin  = rm_par.n32_fecha_fin  AND 
                      n33_num_prest  IS NOT NULL
FOREACH q_prest INTO r_n33.*
	IF vm_cod_trab IS NOT NULL THEN
		IF vm_cod_trab <> r_n33.n33_cod_trab THEN
			CONTINUE FOREACH
		END IF
	END IF
	CALL fl_lee_liquidacion_roles(rm_n05.n05_compania, 
			rm_par.n32_cod_liqrol, rm_par.n32_fecha_ini, 
		        rm_par.n32_fecha_fin,  r_n33.n33_cod_trab)
		RETURNING r_n32.*
	IF vm_cod_trab IS NULL AND r_n32.n32_estado = 'F' THEN
		CONTINUE FOREACH
	END IF
	CALL fl_lee_cab_prestamo_roles(rm_n05.n05_compania, r_n33.n33_num_prest)
		RETURNING r_n45.*
	IF r_n45.n45_compania IS NULL THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No existe préstamo: ' || 
					 r_n33.n33_num_prest, 'stop')
		EXIT PROGRAM
	END IF
	IF r_n45.n45_estado = 'P' THEN
		CONTINUE FOREACH
	END IF
	IF (r_n45.n45_descontado + r_n33.n33_valor) >=
	   (r_n45.n45_val_prest + r_n45.n45_valor_int + r_n45.n45_sal_prest_ant)
	THEN
		LET r_n45.n45_estado = 'P' 
	END IF
	UPDATE rolt045 SET n45_descontado = n45_descontado + r_n33.n33_valor,
			   n45_estado     = r_n45.n45_estado
		WHERE n45_compania  = r_n33.n33_compania AND 
		      n45_num_prest = r_n33.n33_num_prest
	UPDATE rolt058
		SET n58_div_act    = n58_div_act + 1,
		    n58_saldo_dist = n58_saldo_dist - r_n33.n33_valor
		WHERE n58_compania  = r_n33.n33_compania
		  AND n58_num_prest = r_n33.n33_num_prest
		  AND n58_proceso   = r_n33.n33_cod_liqrol
	UPDATE rolt046 SET n46_saldo = n46_saldo - r_n33.n33_valor
		WHERE n46_compania   = r_n33.n33_compania AND 
		      n46_num_prest  = r_n33.n33_num_prest AND
		      n46_cod_liqrol = r_n33.n33_cod_liqrol AND 
		      n46_fecha_ini  = r_n32.n32_fecha_ini AND 
		      n46_fecha_fin  = r_n32.n32_fecha_fin
END FOREACH
FREE q_prest

DECLARE q_prest_club CURSOR FOR 
	SELECT * FROM rolt033
		WHERE n33_compania   = rm_n05.n05_compania   AND 
                      n33_cod_liqrol = rm_par.n32_cod_liqrol AND 
                      n33_fecha_ini  = rm_par.n32_fecha_ini  AND 
                      n33_fecha_fin  = rm_par.n32_fecha_fin  AND 
                      n33_prest_club  IS NOT NULL
FOREACH q_prest_club INTO r_n33.*
	IF vm_cod_trab IS NOT NULL THEN
		IF vm_cod_trab <> r_n33.n33_cod_trab THEN
			CONTINUE FOREACH
		END IF
	END IF
	CALL fl_lee_liquidacion_roles(rm_n05.n05_compania, 
			rm_par.n32_cod_liqrol, rm_par.n32_fecha_ini, 
		        rm_par.n32_fecha_fin,  r_n33.n33_cod_trab)
		RETURNING r_n32.*
	IF vm_cod_trab IS NULL AND r_n32.n32_estado = 'F' THEN
		CONTINUE FOREACH
	END IF
	CALL fl_lee_cab_prestamo_club(rm_n05.n05_compania, r_n33.n33_prest_club)
		RETURNING r_n64.*
	IF r_n64.n64_compania IS NULL THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No existe préstamo: ' || 
					 r_n33.n33_prest_club, 'stop')
		EXIT PROGRAM
	END IF
	IF r_n64.n64_descontado + r_n33.n33_valor >= r_n64.n64_val_prest + r_n64.n64_val_interes THEN
		LET r_n64.n64_estado = 'P' 
	END IF
	UPDATE rolt064 SET n64_descontado = n64_descontado + r_n33.n33_valor,
			   n64_estado     = r_n64.n64_estado
		WHERE n64_compania  = r_n33.n33_compania AND 
		      n64_num_prest = r_n33.n33_prest_club
	UPDATE rolt065 SET n65_saldo = n65_saldo - r_n33.n33_valor
		WHERE n65_compania   = r_n33.n33_compania AND 
		      n65_num_prest  = r_n33.n33_prest_club AND
		      n65_cod_liqrol = r_n33.n33_cod_liqrol AND 
		      n65_fecha_ini  = r_n32.n32_fecha_ini AND 
		      n65_fecha_fin  = r_n32.n32_fecha_fin
END FOREACH
FREE q_prest

IF vm_cod_trab IS NULL THEN
	UPDATE rolt063 SET n63_estado = 'P' 
		WHERE n63_compania   = vg_codcia
		  AND n63_cod_liqrol = rm_par.n32_cod_liqrol
		  AND n63_fecha_ini  = rm_par.n32_fecha_ini
		  AND n63_fecha_fin  = rm_par.n32_fecha_fin
END IF

-- Acumulacion de valores para el fondo de cesantia
-- Codigo Especifico para Acero Comercial

LET fact_aporte_trab = factor_aporte_trab()

IF vm_cod_trab IS NULL THEN
	LET query = 'SELECT * FROM rolt030 WHERE n30_compania = ', vg_codcia
ELSE
	LET query = 'SELECT * FROM rolt030 WHERE n30_compania = ', vg_codcia,
					  '  AND n30_cod_trab = ', vm_cod_trab
END IF
PREPARE cons_cesan FROM query
DECLARE q_cesan CURSOR FOR cons_cesan 
	
FOREACH q_cesan INTO r_n30.*
	INITIALIZE r_n80_cur.* TO NULL
	INITIALIZE r_n80_old.* TO NULL
	INITIALIZE r_n80_new.* TO NULL
	SELECT * INTO r_n80_cur.* FROM rolt080
		WHERE n80_compania = vg_codcia
		  AND n80_ano      = YEAR(rm_par.n32_fecha_ini)
		  AND n80_mes      = MONTH(rm_par.n32_fecha_ini)
		  AND n80_cod_trab = r_n30.n30_cod_trab

	IF r_n80_cur.n80_compania IS NULL THEN
		DECLARE q_ult_cesan CURSOR FOR 
			SELECT * FROM rolt080
				WHERE n80_compania = vg_codcia
			  	  AND n80_cod_trab = r_n30.n30_cod_trab
				ORDER BY 1 ASC, 2 DESC, 3 DESC

		OPEN  q_ult_cesan
		FETCH q_ult_cesan INTO r_n80_old.*
		CLOSE q_ult_cesan
		FREE  q_ult_cesan

		IF r_n80_old.n80_compania IS NULL THEN
			IF r_n30.n30_estado = 'A' THEN
				CALL inicia_registro(r_n30.*) 
					RETURNING r_n80_new.*
			ELSE
				CONTINUE FOREACH
			END IF
		ELSE
			IF ((r_n80_old.n80_sac_trab + r_n80_old.n80_sac_patr +
		     	     r_n80_old.n80_sac_int  + r_n80_old.n80_sac_dscto) =
		           r_n80_old.n80_val_retiro * -1) AND 
			   r_n30.n30_estado <> 'A'
			THEN
				CONTINUE FOREACH
			END IF
			CALL seguir_acumulando(r_n80_old.*, r_n30.*) 
				RETURNING r_n80_new.*
		END IF
		INSERT INTO rolt080 VALUES (r_n80_new.*)
	ELSE
		LET r_n80_new.* = r_n80_cur.*
	END IF
	CALL fl_lee_liquidacion_roles(rm_n05.n05_compania, 
			rm_par.n32_cod_liqrol, rm_par.n32_fecha_ini, 
		        rm_par.n32_fecha_fin,  r_n30.n30_cod_trab)
		RETURNING r_n32.*
	INITIALIZE r_n33.* TO NULL
	SELECT * INTO r_n33.* FROM rolt033
		WHERE n33_compania   = vg_codcia
		  AND n33_cod_liqrol = rm_par.n32_cod_liqrol
		  AND n33_fecha_ini  = rm_par.n32_fecha_ini
		  AND n33_fecha_fin  = rm_par.n32_fecha_fin
		  AND n33_cod_trab   = r_n30.n30_cod_trab
		  AND n33_cod_rubro  = (SELECT n06_cod_rubro FROM rolt006
						WHERE n06_estado     = 'A'
						  AND n06_det_tot    = 'DE'
						  AND n06_flag_ident = 'FC') 

	IF r_n33.n33_compania IS NULL THEN
		CONTINUE FOREACH
	END IF
	
	LET aporte_patr = (r_n33.n33_valor * (rm_n01.n01_porc_aporte / 100)) /
			   fact_aporte_trab

	LET query = "UPDATE rolt080 SET ",
		" n80_", DOWNSHIFT(rm_par.n32_cod_liqrol), "_trab = ",
					r_n33.n33_valor, ", ",
		" n80_", DOWNSHIFT(rm_par.n32_cod_liqrol), "_patr = ",
					aporte_patr, ", ",
		" n80_sac_trab = n80_sac_trab + ", r_n33.n33_valor, ", ", 
		" n80_sac_patr = n80_sac_patr + ", aporte_patr,  
		" WHERE n80_compania = ", vg_codcia,
		"   AND n80_ano = ", YEAR(rm_par.n32_fecha_ini),
		"   AND n80_mes = ", MONTH(rm_par.n32_fecha_ini),
		"   AND n80_cod_trab = ", r_n30.n30_cod_trab

	PREPARE stmnt FROM query
	EXECUTE stmnt
END FOREACH
FREE q_cesan
--CALL genera_vacaciones_proxima_quincena()
CALL cerrar_dias_vacaciones_gozadas()
LET fecha_fin = MDY(MONTH(rm_par.n32_fecha_ini), 01, YEAR(rm_par.n32_fecha_ini))
			- 1 UNITS DAY
LET fecha_ini = MDY(MONTH(fecha_fin), 01, YEAR(fecha_fin))
UPDATE rolt038
	SET n38_estado = 'P' 
	WHERE n38_compania  = vg_codcia 
	  AND n38_fecha_ini = fecha_ini
	  AND n38_fecha_fin = fecha_fin
	  AND n38_pago_iess = "N"

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



FUNCTION inicia_registro(r_n30)
DEFINE r_n30			RECORD LIKE rolt030.*
DEFINE r_n80			RECORD LIKE rolt080.*

INITIALIZE r_n80.* TO NULL

LET r_n80.n80_compania   = vg_codcia
LET r_n80.n80_ano        = YEAR(rm_par.n32_fecha_ini) 
LET r_n80.n80_mes        = MONTH(rm_par.n32_fecha_ini) 
LET r_n80.n80_cod_trab   = r_n30.n30_cod_trab      
LET r_n80.n80_moneda     = r_n30.n30_mon_sueldo     
LET r_n80.n80_paridad    = calcula_paridad(r_n30.n30_mon_sueldo,
			 	           rg_gen.g00_moneda_base)   
LET r_n80.n80_san_trab   = 0    
LET r_n80.n80_san_patr   = 0
LET r_n80.n80_san_int    = 0
LET r_n80.n80_san_dscto  = 0     
LET r_n80.n80_q1_trab    = 0   
LET r_n80.n80_q2_trab    = 0  
LET r_n80.n80_q1_patr    = 0 
LET r_n80.n80_q2_patr    = 0
LET r_n80.n80_val_int    = 0      
LET r_n80.n80_val_dscto  = 0    
LET r_n80.n80_sac_trab   = 0    
LET r_n80.n80_sac_patr   = 0    
LET r_n80.n80_sac_int    = 0    
LET r_n80.n80_sac_dscto  = 0    
LET r_n80.n80_val_retiro = 0    

RETURN r_n80.*

END FUNCTION



FUNCTION seguir_acumulando(r_n80_old, r_n30)
DEFINE r_n30    		RECORD LIKE rolt030.*
DEFINE r_n80_old		RECORD LIKE rolt080.*
DEFINE r_n80_new		RECORD LIKE rolt080.*

DEFINE paridad			LIKE rolt080.n80_paridad

INITIALIZE r_n80_new.* TO NULL

LET paridad = calcula_paridad(r_n30.n30_mon_sueldo, rg_gen.g00_moneda_base)

LET r_n80_new.n80_compania   = r_n80_old.n80_compania
LET r_n80_new.n80_ano        = YEAR(rm_par.n32_fecha_ini) 
LET r_n80_new.n80_mes        = MONTH(rm_par.n32_fecha_ini) 
LET r_n80_new.n80_cod_trab   = r_n80_old.n80_cod_trab      
LET r_n80_new.n80_moneda     = r_n80_old.n80_moneda     
LET r_n80_new.n80_paridad    = calcula_paridad(r_n30.n30_mon_sueldo,
			 	               rg_gen.g00_moneda_base)   
LET r_n80_new.n80_san_trab   = r_n80_old.n80_sac_trab
LET r_n80_new.n80_san_patr   = r_n80_old.n80_sac_patr
LET r_n80_new.n80_san_int    = r_n80_old.n80_sac_int
LET r_n80_new.n80_san_dscto  = r_n80_old.n80_sac_dscto
LET r_n80_new.n80_q1_trab    = 0   
LET r_n80_new.n80_q2_trab    = 0  
LET r_n80_new.n80_q1_patr    = 0 
LET r_n80_new.n80_q2_patr    = 0
LET r_n80_new.n80_val_int    = 0      
LET r_n80_new.n80_val_dscto  = 0    
LET r_n80_new.n80_sac_trab   = r_n80_old.n80_sac_trab
LET r_n80_new.n80_sac_patr   = r_n80_old.n80_sac_patr
LET r_n80_new.n80_sac_int    = r_n80_old.n80_sac_int
LET r_n80_new.n80_sac_dscto  = r_n80_old.n80_sac_dscto
LET r_n80_new.n80_val_retiro = r_n80_old.n80_val_retiro

RETURN r_n80_new.*

END FUNCTION



FUNCTION factor_aporte_trab()
DEFINE r_n07		RECORD LIKE rolt007.*

INITIALIZE r_n07.* TO NULL
SELECT rolt007.* INTO r_n07.* FROM rolt006, rolt007
	WHERE n06_flag_ident = 'FC'
	  AND n06_det_tot    = 'DE'
	  AND n06_estado     = 'A'
	  AND n07_cod_rubro  = n06_cod_rubro

RETURN r_n07.n07_factor

END FUNCTION



FUNCTION genera_vacaciones_proxima_quincena()
DEFINE query		CHAR(6000)
DEFINE mensaje		VARCHAR(200)
DEFINE cuantos		INTEGER
DEFINE fecha_ult	LIKE rolt032.n32_fecha_fin

CALL fecha_ultima_quincena() RETURNING fecha_ult
LET query = 'SELECT n30_compania, n30_cod_trab, n30_cod_depto, n30_mon_sueldo,',
		' n30_tipo_pago, n30_bco_empresa, n30_cta_empresa, ',
		' n30_cta_trabaj, ',
		' CASE WHEN EXTEND(n30_fecha_ing, MONTH TO DAY) = "02-29"',
		' THEN MDY(MONTH(n30_fecha_ing), 28, YEAR(n30_fecha_ing))',
		' ELSE n30_fecha_ing',
		' END n30_fecha_ing ',
		' FROM rolt030 ',
		' WHERE n30_compania  = ', vg_codcia,
		'   AND n30_estado    = "A" ',
		'   AND n30_tipo_trab = "N" ',
		' INTO TEMP tmp_n30 '
PREPARE exec_n30 FROM query
EXECUTE exec_n30
LET query = 'SELECT a.n32_compania cia, "VA" proc, a.n32_cod_trab cod_trab, ',
		'MDY(MONTH(n30_fecha_ing), DAY(n30_fecha_ing),YEAR(TODAY) - 1)',
		' per_ini, MDY(MONTH(n30_fecha_ing), DAY(n30_fecha_ing), ',
		'YEAR(TODAY)) - 1 UNITS DAY per_fin, ',
		'MDY(MONTH(n30_fecha_ing), DAY(n30_fecha_ing),YEAR(TODAY) - 1)',
		' - 1 UNITS YEAR fec_ini_re, ((((MDY(MONTH(n30_fecha_ing),',
		' DAY(n30_fecha_ing), YEAR(TODAY)) - 1 UNITS DAY) - 1 ',
		'UNITS YEAR) + 1 UNITS YEAR) - 1 UNITS DAY) fec_fin_re, ',
		'"G" tipo, "A" est, n30_cod_depto dp, YEAR((((a.n32_fecha_ini',
		' - 1 UNITS YEAR) + 1 UNITS YEAR) - 1 UNITS DAY)) ano_pro, ',
		'MONTH((((a.n32_fecha_ini - 1 UNITS YEAR) + 1 UNITS YEAR)',
		' - 1 UNITS DAY)) mes_pro, ',
		'n30_fecha_ing fec_ing, n00_dias_vacac d_v,',
		' CASE WHEN (MDY(MONTH(n30_fecha_ing), DAY(n30_fecha_ing),',
			' YEAR(TODAY))) >= (n30_fecha_ing + (n00_ano_adi_vac',
			' - 1) UNITS YEAR - 1 UNITS DAY)',
			' THEN ',
			'CASE WHEN (n00_dias_vacac + ((YEAR(MDY(MONTH(',
				'n30_fecha_ing), DAY(n30_fecha_ing), ',
				'YEAR(TODAY))) - YEAR(n30_fecha_ing + ',
				'(n00_ano_adi_vac - 1) UNITS YEAR - ',
				'1 UNITS DAY)) * n00_dias_adi_va)) > ',
				'n00_max_vacac',
				' THEN n00_max_vacac - n00_dias_vacac ',
				'ELSE ((YEAR(MDY(MONTH(n30_fecha_ing), ',
					'DAY(n30_fecha_ing), YEAR(TODAY))) -',
					'YEAR(n30_fecha_ing + (n00_ano_adi_vac',
					' - 1) UNITS YEAR - 1 UNITS DAY)) *',
					' n00_dias_adi_va)',
				' END',
			' ELSE 0 ',
		' END d_a,',
		' 0 d_g, "" fec_ini_v, "" fec_fin_v, n30_mon_sueldo mo, 1 par,',
		' n30_tipo_pago pago, n30_bco_empresa bco,n30_cta_empresa cta,',
		' n30_cta_trabaj cta_t, "S" goza, "',
		UPSHIFT(vg_usuario) CLIPPED,'" usua, EXTEND(CURRENT, YEAR TO',
		' SECOND) fec_i ',
		' FROM rolt032 a, tmp_n30, rolt000 ',
		' WHERE a.n32_compania   = ', vg_codcia,
		'   AND a.n32_cod_liqrol IN ("Q1", "Q2") ',
		'   AND a.n32_estado     = "C"',
		'   AND a.n32_fecha_fin  = (SELECT MAX(b.n32_fecha_fin)',
						' FROM rolt032 b ',
					' WHERE b.n32_compania =a.n32_compania',
		  			'   AND b.n32_estado   = "C") ',
		'   AND n30_compania     = a.n32_compania ',
		'   AND n30_cod_trab     = a.n32_cod_trab ',
		'   AND MDY(MONTH(n30_fecha_ing), ',
			'(CASE WHEN DAY(n30_fecha_ing) >= 1 ',
				'AND DAY(n30_fecha_ing) <= 15 ',
			'THEN 1 ELSE 16 END), ',
			'a.n32_ano_proceso) - 1 UNITS DAY <= EXTEND(DATE("',
						fecha_ult, '"), YEAR TO DAY) ',
		'   AND NOT EXISTS(SELECT * FROM rolt039 ',
			' WHERE n39_compania     = a.n32_compania ',
			'   AND n39_proceso      IN ("VA", "VP") ',
			'   AND n39_cod_trab     = a.n32_cod_trab ',
			'  AND n39_periodo_ini >= MDY(MONTH(n30_fecha_ing), ',
				'DAY(n30_fecha_ing), a.n32_ano_proceso - 1)',
			'  AND n39_periodo_fin <= MDY(MONTH(n30_fecha_ing), ',
			'DAY(n30_fecha_ing), a.n32_ano_proceso) - 1 UNITS DAY)',
		'   AND n00_serial       = n30_compania ',
		' INTO TEMP t1 '
PREPARE exec_t1 FROM query
EXECUTE exec_t1
DROP TABLE tmp_n30
SELECT COUNT(*) INTO cuantos FROM t1
IF cuantos = 0 THEN
	DROP TABLE t1
	RETURN
END IF
LET query = 'SELECT cia, proc, cod_trab, per_ini, per_fin, ',
		'CASE WHEN (DAY(per_ini) >= 1 AND DAY(per_ini) < 16) THEN ',
			'MDY(MONTH(per_ini), 01, YEAR(per_ini)) ',
		'     WHEN DAY(per_ini) >= 16 THEN ',
			'MDY(MONTH(per_ini), 16, YEAR(per_ini)) ',
		'END fec_ini_re, ',
		'CASE WHEN (NOT (MOD(YEAR(per_fin), 4) = 0) AND ',
		'MONTH(per_fin) > 2) OR (EXTEND(per_fin, MONTH TO DAY) = ',
			'EXTEND(per_fin, MONTH TO DAY)) ',
		'THEN ',
			'CASE WHEN (DAY(per_ini) >= 1 AND DAY(per_ini) < 16) ',
				'THEN MDY(MONTH(per_fin), 01, YEAR(per_fin)) ',
			'     WHEN DAY(per_ini) >= 16 THEN ',
				'MDY(MONTH(per_fin), 16, YEAR(per_fin)) ',
			'END - 1 UNITS DAY ',
		'ELSE ',
			'CASE WHEN (DAY(per_ini) >= 1 AND DAY(per_ini) < 16) ',
				'THEN MDY(MONTH(per_fin), 01, YEAR(per_fin)) ',
			'     WHEN DAY(per_ini) >= 16 THEN ',
				'MDY(MONTH(per_fin), 16, YEAR(per_fin)) ',
			'END + (SELECT n90_dias_anio FROM rolt090 ',
				'WHERE n90_compania = cia) UNITS DAY ',
		'END fec_fin_re, ',
		'tipo, est, dp, ano_pro, mes_pro, fec_ing, d_v, d_a, d_g, ',
		'fec_ini_v, fec_fin_v, mo, par, NVL(SUM(n32_tot_gan), 0) ',
		'tot_gan,(NVL(SUM(n32_tot_gan),0) / (360 / d_v)) val_vac, ',
		'(((NVL(SUM(n32_tot_gan),0) / (360 / d_v)) / d_v) * d_a) ',
		'val_adi, 0.00 ot_i, 0.00 iess, 0.00 ot_e, 0.00 neto, pago, ',
		'bco, cta, cta_t, goza, usua, fec_i, n13_porc_trab porc',
		' FROM t1, rolt032, rolt030, rolt013',
		' WHERE n32_compania     = cia ',
		'   AND n32_cod_liqrol  IN ("Q1", "Q2") ',
		'   AND n32_fecha_ini   >= MDY(MONTH(n30_fecha_ing), ',
				'(CASE WHEN DAY(n30_fecha_ing) >= 1 ',
					'AND DAY(n30_fecha_ing) <= 15 ',
				'THEN 1 ELSE 16 END), YEAR(DATE("', fecha_ult,
								'")) - 1) ',
		'   AND n32_fecha_fin   <= MDY(MONTH(n30_fecha_ing), ',
				'(CASE WHEN DAY(n30_fecha_ing) >= 1 ',
					'AND DAY(n30_fecha_ing) <= 15 ',
				'THEN 1 ELSE 16 END), YEAR(DATE("', fecha_ult,
							'"))) - 1 UNITS DAY ',
		'   AND n32_cod_trab     = cod_trab ',
		'   AND n32_ano_proceso >= ',
				'(SELECT n90_anio_ini_vac FROM rolt090 ',
					'WHERE n90_compania = n30_compania) ',
		'   AND n32_estado      = "C" ',
		'   AND n30_compania    = n32_compania ',
		'   AND n30_cod_trab    = n32_cod_trab ',
		'   AND n13_cod_seguro  = n30_cod_seguro ',
		' GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, ',
			'16, 17, 18, 19, 20, 24, 25, 26, 27, 28, 29, 30, 31, ',
			'32, 33, 34, 35 ',
		' INTO TEMP t2 '
PREPARE exec_t2 FROM query
EXECUTE exec_t2
DROP TABLE t1
INSERT INTO rolt039
	SELECT cia, proc, cod_trab, per_ini, per_fin, fec_ini_re, fec_fin_re,
		tipo, est, dp, ano_pro, mes_pro, fec_ing, d_v, d_a, d_g,
		fec_ini_v, fec_fin_v, mo, par, tot_gan, round(val_vac, 2)
		val_vac, round(val_adi, 2) val_adi, ot_i, round((((val_vac +
		val_adi) * porc) / 100), 2) iess, ot_e, round((round(val_vac, 2)
		+ round(val_adi, 2) + ot_i - round((((val_vac + val_adi) * porc)
		/ 100), 2) - ot_e), 2) neto, pago, bco, cta, cta_t, goza, usua,
		fec_i
	FROM t2
LET mensaje = 'Se generaron ', cuantos USING "<<<<&", ' liquidaciones de',
		' vacaciones, con estado "En Proceso" de liquidación Ok.'
CALL fl_mostrar_mensaje(mensaje, 'info')
DROP TABLE t2

END FUNCTION



FUNCTION cerrar_dias_vacaciones_gozadas()

UPDATE rolt039
	SET n39_dias_goza = n39_dias_goza +
				(SELECT NVL(SUM(n47_dias_goza), 0)
				FROM rolt047
				WHERE n47_compania    = n39_compania
				  AND n47_proceso     = n39_proceso
				  AND n47_cod_trab    = n39_cod_trab
				  AND n47_periodo_ini = n39_periodo_ini
				  AND n47_periodo_fin = n39_periodo_fin
				  AND n47_cod_liqrol  = rm_par.n32_cod_liqrol
				  AND n47_fecha_ini   = rm_par.n32_fecha_ini
				  AND n47_fecha_fin   = rm_par.n32_fecha_fin
				  AND n47_estado      = "A")
	WHERE n39_compania = vg_codcia
	  AND n39_proceso  = "VA"
	  AND n39_estado   = "P"
	  AND EXISTS       (SELECT n47_compania, n47_proceso, n47_cod_trab,
					n47_periodo_ini, n47_periodo_fin
				FROM rolt047
				WHERE n47_compania    = n39_compania
				  AND n47_proceso     = n39_proceso
				  AND n47_cod_trab    = n39_cod_trab
				  AND n47_periodo_ini = n39_periodo_ini
				  AND n47_periodo_fin = n39_periodo_fin
				  AND n47_cod_liqrol  = rm_par.n32_cod_liqrol
				  AND n47_fecha_ini   = rm_par.n32_fecha_ini
				  AND n47_fecha_fin   = rm_par.n32_fecha_fin
				  AND n47_estado      = "A")
UPDATE rolt047
	SET n47_estado = "G"
	WHERE n47_compania   = vg_codcia
	  AND n47_cod_liqrol = rm_par.n32_cod_liqrol
	  AND n47_fecha_ini  = rm_par.n32_fecha_ini
	  AND n47_fecha_fin  = rm_par.n32_fecha_fin
	  AND n47_estado     = "A"

END FUNCTION



FUNCTION fecha_ultima_quincena()
DEFINE fecha_ult	LIKE rolt032.n32_fecha_fin

SELECT NVL(MAX(n32_fecha_fin), TODAY) INTO fecha_ult
	FROM rolt032
	WHERE n32_compania    = vg_codcia
	  AND n32_cod_liqrol IN("Q1", "Q2")
	  AND n32_estado     <> 'E'
RETURN fecha_ult

END FUNCTION
