------------------------------------------------------------------------------
-- Titulo           : rolp205.4gl - Reapertura liquidacion de roles
-- Elaboracion      : 07-Ago-2003
-- Autor            : YEC
-- Formato Ejecucion: fglrun rolp205 base modulo compania
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_n00		RECORD LIKE rolt000.*  
DEFINE rm_n05		RECORD LIKE rolt005.*  
DEFINE rm_n01		RECORD LIKE rolt001.*  
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


MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp205.err')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso  = 'rolp205'
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
OPEN FORM f_205 FROM '../forms/rolf205_1'
DISPLAY FORM f_205
CALL control_reapertura_liquidacion_roles()

END FUNCTION



FUNCTION control_reapertura_liquidacion_roles()
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE mensaje		VARCHAR(250)
DEFINE num		SMALLINT
DEFINE resp		CHAR(10)

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
IF status <> NOTFOUND THEN
	LET mensaje = 'Esta activo el proceso de roles: ',
		       rm_n05.n05_proceso
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
INITIALIZE r_n32.* TO NULL
DECLARE q_ultliq CURSOR FOR
	SELECT * FROM rolt032
		WHERE n32_compania = vg_codcia  AND 
		      n32_estado   = 'C'
		ORDER BY n32_fecha_ini DESC
OPEN q_ultliq 
FETCH q_ultliq INTO r_n32.*
IF r_n32.n32_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No hay liquidaciones cerradas en rolt032.', 'stop')
	EXIT PROGRAM
END IF
LET rm_par.n32_cod_liqrol = r_n32.n32_cod_liqrol
LET rm_par.n32_fecha_ini  = r_n32.n32_fecha_ini
LET rm_par.n32_fecha_fin  = r_n32.n32_fecha_fin
IF r_n32.n32_mes_proceso <> rm_n01.n01_mes_proceso AND
   r_n32.n32_ano_proceso <> rm_n01.n01_ano_proceso THEN
	LET mensaje = 'Ya no es posible reprocesar nómina, mes de proceso ',
		      'no correponde.'
	CALL fl_mostrar_mensaje(mensaje, 'stop')                                
        EXIT PROGRAM                                           
END IF
CALL fl_lee_proceso_roles(rm_par.n32_cod_liqrol) RETURNING r_n03.*
LET rm_par.n_liqrol = r_n03.n03_nombre
DISPLAY BY NAME rm_par.*
CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
IF resp <> 'Yes' THEN
	EXIT PROGRAM
END IF
BEGIN WORK
	CALL reprocesar_nomina()
COMMIT WORK
IF vg_codloc <> 3 THEN
	CALL eliminar_diario_contable()
END IF
LET mensaje = 'Proceso terminado Ok.'
CALL fl_mostrar_mensaje(mensaje, 'info')

END FUNCTION



FUNCTION reprocesar_nomina()
DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE r_n33		RECORD LIKE rolt033.*
DEFINE r_n13		RECORD LIKE rolt013.*
DEFINE r_n45		RECORD LIKE rolt045.*
DEFINE fecha_ini	LIKE rolt038.n38_fecha_ini
DEFINE fecha_fin	LIKE rolt038.n38_fecha_fin
DEFINE tot_valor	DECIMAL(12,2)
DEFINE tot_egr		DECIMAL(12,2)
DEFINE tot_ing		DECIMAL(12,2)
DEFINE mensaje		VARCHAR(200)
DEFINE query		VARCHAR(500)

UPDATE rolt032 SET n32_estado = 'A' 
	WHERE n32_estado = 'C' AND
              n32_compania   = vg_codcia AND
              n32_cod_liqrol = rm_par.n32_cod_liqrol AND 
              n32_fecha_ini  = rm_par.n32_fecha_ini AND 
              n32_fecha_fin  = rm_par.n32_fecha_fin
UPDATE rolt005 SET n05_activo = 'S',
		   n05_fecini_act = rm_par.n32_fecha_ini,
		   n05_fecfin_act = rm_par.n32_fecha_fin
	WHERE n05_compania = rm_n01.n01_compania AND 
	      n05_proceso  = rm_par.n32_cod_liqrol
DECLARE q_prest CURSOR FOR 
	SELECT * FROM rolt033
		WHERE n33_compania   = rm_n01.n01_compania   AND 
                      n33_cod_liqrol = rm_par.n32_cod_liqrol AND 
                      n33_fecha_ini  = rm_par.n32_fecha_ini  AND 
                      n33_fecha_fin  = rm_par.n32_fecha_fin  AND 
                      n33_num_prest  IS NOT NULL
FOREACH q_prest INTO r_n33.*
	CALL fl_lee_liquidacion_roles(rm_n01.n01_compania, 
			rm_par.n32_cod_liqrol, rm_par.n32_fecha_ini, 
		        rm_par.n32_fecha_fin,  r_n33.n33_cod_trab)
		RETURNING r_n32.*
	UPDATE rolt045 SET n45_descontado = n45_descontado - r_n33.n33_valor
		WHERE n45_compania  = r_n33.n33_compania AND 
		      n45_num_prest = r_n33.n33_num_prest
	UPDATE rolt058
		SET n58_div_act    = n58_div_act - 1,
		    n58_saldo_dist = n58_saldo_dist + r_n33.n33_valor
		WHERE n58_compania  = r_n33.n33_compania
		  AND n58_num_prest = r_n33.n33_num_prest
		  AND n58_proceso   = r_n33.n33_cod_liqrol
	UPDATE rolt046 SET n46_saldo = n46_saldo + r_n33.n33_valor
		WHERE n46_compania   = r_n33.n33_compania AND 
		      n46_num_prest  = r_n33.n33_num_prest AND
		      n46_cod_liqrol = r_n33.n33_cod_liqrol AND 
		      n46_fecha_ini  = r_n32.n32_fecha_ini   AND 
		      n46_fecha_fin  = r_n32.n32_fecha_fin  
	CALL fl_lee_cab_prestamo_roles(vg_codcia, r_n33.n33_num_prest)
		RETURNING r_n45.*
	LET r_n45.n45_estado = 'A'
	IF r_n45.n45_prest_tran IS NOT NULL THEN
		LET r_n45.n45_estado = 'R'
	END IF
	UPDATE rolt045 SET n45_estado = r_n45.n45_estado
		WHERE n45_compania  = r_n33.n33_compania AND 
		      n45_num_prest = r_n33.n33_num_prest
END FOREACH
FREE q_prest

DECLARE q_prest_club CURSOR FOR 
	SELECT * FROM rolt033
		WHERE n33_compania   = rm_n01.n01_compania   AND 
                      n33_cod_liqrol = rm_par.n32_cod_liqrol AND 
                      n33_fecha_ini  = rm_par.n32_fecha_ini  AND 
                      n33_fecha_fin  = rm_par.n32_fecha_fin  AND 
                      n33_prest_club IS NOT NULL
FOREACH q_prest_club INTO r_n33.*
	CALL fl_lee_liquidacion_roles(rm_n01.n01_compania, 
			rm_par.n32_cod_liqrol, rm_par.n32_fecha_ini, 
		        rm_par.n32_fecha_fin,  r_n33.n33_cod_trab)
		RETURNING r_n32.*
	UPDATE rolt064 SET n64_descontado = n64_descontado - r_n33.n33_valor
		WHERE n64_compania  = r_n33.n33_compania AND 
		      n64_num_prest = r_n33.n33_prest_club
	UPDATE rolt065 SET n65_saldo = n65_saldo + r_n33.n33_valor
		WHERE n65_compania   = r_n33.n33_compania AND 
		      n65_num_prest  = r_n33.n33_prest_club AND
		      n65_cod_liqrol = r_n33.n33_cod_liqrol AND 
		      n65_fecha_ini  = r_n32.n32_fecha_ini   AND 
		      n65_fecha_fin  = r_n32.n32_fecha_fin  
END FOREACH
FREE q_prest_club

UPDATE rolt063 SET n63_estado = 'A' 
	WHERE n63_compania   = vg_codcia
	  AND n63_cod_liqrol = rm_par.n32_cod_liqrol
	  AND n63_fecha_ini  = rm_par.n32_fecha_ini
	  AND n63_fecha_fin  = rm_par.n32_fecha_fin

LET query = "UPDATE rolt080 SET ",
	" n80_sac_trab = n80_sac_trab - n80_", DOWNSHIFT(rm_par.n32_cod_liqrol), "_trab, ", 
	" n80_sac_patr = n80_sac_patr - n80_", DOWNSHIFT(rm_par.n32_cod_liqrol), "_patr, ", 
	" n80_", DOWNSHIFT(rm_par.n32_cod_liqrol), "_trab = 0, ",
	" n80_", DOWNSHIFT(rm_par.n32_cod_liqrol), "_patr = 0 ",
	" WHERE n80_compania = ", vg_codcia,
	"   AND n80_ano = ", YEAR(rm_par.n32_fecha_ini),
	"   AND n80_mes = ", MONTH(rm_par.n32_fecha_ini)
PREPARE stmnt FROM query
EXECUTE stmnt

DELETE FROM rolt080 WHERE n80_compania   = vg_codcia
	              AND n80_ano        = YEAR(rm_par.n32_fecha_ini)
	              AND n80_mes        = MONTH(rm_par.n32_fecha_ini)
		      AND n80_q1_trab    = 0
		      AND n80_q2_trab    = 0
		      AND n80_q1_patr    = 0
		      AND n80_q2_trab    = 0
		      AND n80_val_int    = 0
		      AND n80_val_dscto  = 0
		      AND n80_sac_trab   = n80_san_trab
		      AND n80_sac_patr   = n80_san_patr
		      AND n80_sac_int    = n80_san_int
		      AND n80_sac_dscto  = n80_san_dscto
		      AND n80_val_retiro = 0

CALL reabrir_dias_vacaciones_gozadas()

UPDATE rolt026
	SET n26_estado = 'G'
	WHERE n26_compania  = vg_codcia
	  AND n26_ano_carga = YEAR(rm_par.n32_fecha_ini)
	  AND n26_mes_carga = MONTH(rm_par.n32_fecha_ini)

LET fecha_fin = MDY(MONTH(rm_par.n32_fecha_ini), 01, YEAR(rm_par.n32_fecha_ini))
			- 1 UNITS DAY
LET fecha_ini = MDY(MONTH(fecha_fin), 01, YEAR(fecha_fin))
UPDATE rolt038
	SET n38_estado = 'A' 
	WHERE n38_compania  = vg_codcia 
	  AND n38_fecha_ini = fecha_ini
	  AND n38_fecha_fin = fecha_fin
	  AND n38_pago_iess = "N"

END FUNCTION



FUNCTION eliminar_diario_contable()
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE r_n53		RECORD LIKE rolt053.*
DEFINE resp		CHAR(6)

INITIALIZE r_n53.* TO NULL
SELECT * INTO r_n53.*
	FROM rolt053
	WHERE n53_compania   = vg_codcia
	  AND n53_cod_liqrol = rm_par.n32_cod_liqrol
	  AND n53_fecha_ini  = rm_par.n32_fecha_ini
	  AND n53_fecha_fin  = rm_par.n32_fecha_fin

CALL fl_lee_comprobante_contable(r_n53.n53_compania, r_n53.n53_tipo_comp,
					r_n53.n53_num_comp)
	RETURNING r_b12.*
IF r_b12.b12_compania IS NULL THEN
	RETURN
END IF
IF r_b12.b12_estado = 'E' THEN
	RETURN
END IF

CALL fl_hacer_pregunta('Desea eliminar el diario contable automatico de esta nómina ?', 'No')
	RETURNING resp
IF resp <> 'Yes' THEN
	RETURN
END IF

CALL fl_mayoriza_comprobante(r_b12.b12_compania, r_b12.b12_tipo_comp,
				r_b12.b12_num_comp, 'D')

BEGIN WORK
SET LOCK MODE TO WAIT 5
WHENEVER ERROR CONTINUE
UPDATE ctbt012 SET b12_estado     = 'E',
		   b12_fec_modifi = CURRENT 
	WHERE b12_compania  = r_b12.b12_compania
	  AND b12_tipo_comp = r_b12.b12_tipo_comp
	  AND b12_num_comp  = r_b12.b12_num_comp
IF STATUS < 0 THEN
	ROLLBACK WORK
	WHENEVER ERROR STOP
	CALL fl_mostrar_mensaje('No se puede eliminar el diario contable de la nómina. LLAME AL ADMINISTRADOR.', 'stop')
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP

DELETE FROM rolt053
	WHERE n53_compania   = r_n53.n53_compania
	  AND n53_cod_liqrol = r_n53.n53_cod_liqrol
	  AND n53_fecha_ini  = r_n53.n53_fecha_ini
	  AND n53_fecha_fin  = r_n53.n53_fecha_fin
	  AND n53_tipo_comp  = r_n53.n53_tipo_comp
	  AND n53_num_comp   = r_n53.n53_num_comp

COMMIT WORK

END FUNCTION



FUNCTION reabrir_dias_vacaciones_gozadas()

UPDATE rolt039
	SET n39_dias_goza = n39_dias_goza -
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
				  AND n47_estado      = "G")
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
				  AND n47_estado      = "G")
UPDATE rolt047
	SET n47_estado = "A"
	WHERE n47_compania   = vg_codcia
	  AND n47_cod_liqrol = rm_par.n32_cod_liqrol
	  AND n47_fecha_ini  = rm_par.n32_fecha_ini
	  AND n47_fecha_fin  = rm_par.n32_fecha_fin
	  AND n47_estado     = "G"

END FUNCTION
