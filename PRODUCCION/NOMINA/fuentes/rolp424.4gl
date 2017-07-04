--------------------------------------------------------------------------------
-- Titulo           : rolp424.4gl - LISTADO CONTROL LIQUIDACION DECIMO TERCERO
-- Elaboracion      : 8-Abr-2008
-- Autor            : NPC
-- Formato Ejecucion: fglrun rolp424 BD MODULO COMPANIA ANIO
-- Ultima Correccion:
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE vm_anio		LIKE rolt041.n41_ano
DEFINE vm_proceso	LIKE rolt042.n42_proceso
DEFINE vm_fecha_ini	LIKE rolt042.n42_fecha_ini
DEFINE vm_fecha_fin	LIKE rolt042.n42_fecha_fin
DEFINE rm_n42		RECORD LIKE rolt042.*



MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp424.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN     -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vm_anio    = arg_val(4)
LET vg_proceso = 'rolp424'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE r_n41		RECORD LIKE rolt041.*
DEFINE cuantas		INTEGER

CALL fl_nivel_isolation()
LET vm_proceso = 'UT'
DECLARE q_est CURSOR FOR
	SELECT * FROM rolt041
		WHERE n41_compania = vg_codcia
		  AND n41_proceso  = vm_proceso
		  AND n41_ano      = vm_anio
OPEN q_est
FETCH q_est INTO r_n41.*
CLOSE q_est
FREE q_est
IF r_n41.n41_estado IS NULL THEN
	CALL fl_mostrar_mensaje('Liquidación no existe.', 'stop')
	EXIT PROGRAM
END IF
LET vm_fecha_ini = r_n41.n41_fecha_ini
LET vm_fecha_fin = r_n41.n41_fecha_fin
SELECT COUNT(*) INTO cuantas
	FROM rolt042
	WHERE n42_compania  = vg_codcia
	  AND n42_proceso   = vm_proceso
	  AND n42_fecha_ini = vm_fecha_ini
	  AND n42_fecha_fin = vm_fecha_fin
IF cuantas = 0 THEN	
	CALL fl_mostrar_mensaje('No existe liquidaci¢n de decimos para el periodo: ' || vm_fecha_ini USING "dd-mm-yyyy" || ' - ' || vm_fecha_fin USING "dd-mm-yyyy" || '.', 'stop')
	EXIT PROGRAM
END IF
CALL control_main_reporte()

END FUNCTION



FUNCTION control_main_reporte()
DEFINE r_rol		RECORD
				cod_trab	LIKE rolt042.n42_cod_trab,
				nom_trab	LIKE rolt030.n30_nombres,
				dias_trab	LIKE rolt042.n42_dias_trab,
				ganado		LIKE rolt042.n42_val_trabaj,
				cargas		LIKE rolt042.n42_num_cargas,
				valor_bruto	LIKE rolt042.n42_val_cargas,
				descuentos	LIKE rolt042.n42_descuentos,
				anticipos	LIKE rolt042.n42_descuentos,
				valor_neto	DECIMAL(12,2)
			END RECORD
DEFINE comando		VARCHAR(100)

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rm_cia.*
IF rm_cia.g01_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe compañía.','stop')
	EXIT PROGRAM
END IF
DECLARE q_utilidades CURSOR FOR
	SELECT n42_cod_trab, n30_nombres, n42_dias_trab, n42_val_trabaj,
		n42_num_cargas, n42_val_cargas, n42_descuentos,
		NVL((SELECT SUM(n49_valor)
			FROM rolt049, rolt006
			WHERE n49_compania    = n42_compania
			  AND n49_proceso     = n42_proceso
			  AND n49_fecha_ini   = n42_fecha_ini
			  AND n49_fecha_fin   = n42_fecha_fin
			  AND n49_cod_trab    = n42_cod_trab
			  AND n49_cod_rubro   = n06_cod_rubro
			  AND (n49_num_prest  IS NOT NULL
			   OR  n06_flag_ident =
				(SELECT UNIQUE n06_flag_ident
					FROM rolt018
					WHERE n18_cod_rubro =
							n06_cod_rubro))), 0)
		AS anticipos,
		(n42_val_trabaj + n42_val_cargas -
		NVL((SELECT SUM(n49_valor)
			FROM rolt049, rolt006
			WHERE n49_compania    = n42_compania
			  AND n49_proceso     = n42_proceso
			  AND n49_fecha_ini   = n42_fecha_ini
			  AND n49_fecha_fin   = n42_fecha_fin
			  AND n49_cod_trab    = n42_cod_trab
			  AND n49_cod_rubro   = n06_cod_rubro), 0))
		AS n42_valor_neto
		FROM rolt042, rolt030
		WHERE n42_compania  = vg_codcia          
		  AND n42_proceso   = vm_proceso         
		  AND n42_fecha_ini = vm_fecha_ini
		  AND n42_fecha_fin = vm_fecha_fin
		  AND n30_compania  = n42_compania
		  AND n30_cod_trab  = n42_cod_trab
		ORDER BY n30_nombres ASC
--START REPORT report_utilidades TO FILE "listado.npc"
START REPORT report_utilidades TO PIPE comando
FOREACH q_utilidades INTO r_rol.*
	IF r_rol.anticipos IS NULL THEN
		LET r_rol.anticipos = 0
	END IF
	OUTPUT TO REPORT report_utilidades(r_rol.*)
END FOREACH
FINISH REPORT report_utilidades

END FUNCTION



REPORT report_utilidades(r_rol)
DEFINE r_rol		RECORD
				cod_trab	LIKE rolt042.n42_cod_trab,
				nom_trab	LIKE rolt030.n30_nombres,
				dias_trab	LIKE rolt042.n42_dias_trab,
				ganado		LIKE rolt042.n42_val_trabaj,
				cargas		LIKE rolt042.n42_num_cargas,
				valor_bruto	LIKE rolt042.n42_val_cargas,
				descuentos	LIKE rolt042.n42_descuentos,
				anticipos	LIKE rolt042.n42_descuentos,
				valor_neto	DECIMAL(12,2)
			END RECORD
DEFINE usuario          VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i, long          SMALLINT
DEFINE fecha            DATE
DEFINE est		LIKE rolt041.n41_estado
DEFINE estado		VARCHAR(30)
DEFINE escape, act_des  SMALLINT
DEFINE act_comp, db_c   SMALLINT
DEFINE desact_comp, db  SMALLINT
DEFINE act_neg, des_neg SMALLINT
DEFINE act_10cpi        SMALLINT
DEFINE act_12cpi        SMALLINT

OUTPUT
	TOP MARGIN	0
	LEFT MARGIN	0
	RIGHT MARGIN	132 
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
        LET escape      = 27            # Iniciar sec. impresi¢n
        LET act_comp    = 15            # Activar Comprimido.
        LET desact_comp = 18            # Cancelar Comprimido.
        LET act_neg     = 71            # Activar negrita.
        LET des_neg     = 72            # Desactivar negrita.
        LET act_des     = 0
        LET act_10cpi   = 80            # Comprimido 10 CPI.
        LET act_12cpi   = 77            # Comprimido 12 CPI.
        LET modulo  = "MODULO: NOMINA"
        LET long    = LENGTH(modulo)
        LET usuario = 'USUARIO: ', vg_usuario
        CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
        CALL fl_justifica_titulo('C', 'LISTADO UTILIDADES TRABAJADORES', 33)
                RETURNING titulo
        print ASCII escape;
        print ASCII act_comp
        PRINT COLUMN 1, rm_cia.g01_razonsocial,
              COLUMN 121, "PAGINA: ", PAGENO USING "&&&"
        PRINT COLUMN 1, modulo CLIPPED,
              COLUMN 50, titulo CLIPPED,
              COLUMN 125, UPSHIFT(vg_proceso)
        SKIP 1 LINES
	DECLARE q_est2 CURSOR FOR
		SELECT n41_estado
			FROM rolt041
			WHERE n41_compania  = vg_codcia          
			  AND n41_proceso   = vm_proceso         
			  AND n41_fecha_ini = vm_fecha_ini
			  AND n41_fecha_fin = vm_fecha_fin
			GROUP BY 1
      	OPEN q_est2
	FETCH q_est2 INTO est
	CASE est 
		WHEN 'A'
			LET estado = 'EN PROCESO'
		WHEN 'P'
			LET estado = 'PROCESADO'
	END CASE
	CLOSE q_est2
	FREE  q_est2
        PRINT COLUMN 25, "** PERIODO: ", vm_fecha_ini USING "dd-mm-yyyy", 
                         " - ", vm_fecha_fin USING "dd-mm-yyyy",
	      COLUMN 70, "** ESTADO: ", estado
        SKIP 1 LINES
        PRINT COLUMN 01, "Fecha de Impresión: ", TODAY USING "dd-mm-yyyy",
                         1 SPACES, TIME,
              COLUMN 117, fl_justifica_titulo('D', usuario, 15)
        SKIP 1 LINES
	PRINT COLUMN 002, "COD.",
	      COLUMN 008, "NOMBRES",
	      COLUMN 050, " DIAS",
	      COLUMN 056, fl_justifica_titulo('D', "VALOR TRABAJ.", 14),
	      COLUMN 071, "NCA",
	      COLUMN 075, fl_justifica_titulo('D', "VALOR CARGAS", 14),
	      COLUMN 090, fl_justifica_titulo('D', "ANTICIPOS", 14),
	      COLUMN 105, fl_justifica_titulo('D', "OTROS DSCTOS.", 13),
	      COLUMN 119, fl_justifica_titulo('D', "A RECIBIR", 14)
        PRINT COLUMN 002, '-----------------------------------------------------------------------------------------------------------------------------------'

ON EVERY ROW
	NEED 2 LINES
	PRINT COLUMN 002, r_rol.cod_trab USING '##&&',
	      COLUMN 008, r_rol.nom_trab CLIPPED,
	      COLUMN 050, r_rol.dias_trab USING "###&&",
	      COLUMN 056, r_rol.ganado USING '###,###,##&.##',
	      COLUMN 071, r_rol.cargas USING "#&&",
	      COLUMN 075, r_rol.valor_bruto USING '###,###,##&.##',
	      COLUMN 090, r_rol.anticipos USING '###,###,##&.##',
	      COLUMN 105, r_rol.descuentos - r_rol.anticipos 
				USING '##,###,##&.##',
	      COLUMN 119, r_rol.valor_neto USING '###,###,##&.##'

ON LAST ROW 
	PRINT COLUMN 050, '-----',
	      COLUMN 056, '--------------',  
	      COLUMN 071, '---',  
	      COLUMN 075, '--------------',  
	      COLUMN 090, '--------------',  
	      COLUMN 105, '-------------',  
	      COLUMN 119, '--------------'  
	PRINT COLUMN 043, 'TOTAL: ',
	      COLUMN 050, SUM(r_rol.dias_trab) USING '###&&',
	      COLUMN 056, SUM(r_rol.ganado) USING '###,###,##&.##',
	      COLUMN 071, SUM(r_rol.cargas) USING '#&&',
	      COLUMN 075, SUM(r_rol.valor_bruto) USING '###,###,##&.##',
	      COLUMN 090, SUM(r_rol.anticipos) USING '###,###,##&.##',
	      COLUMN 105, SUM(r_rol.descuentos - r_rol.anticipos) 
				USING '##,###,##&.##',
	      COLUMN 119, SUM(r_rol.valor_neto) USING '###,###,##&.##'

END REPORT
