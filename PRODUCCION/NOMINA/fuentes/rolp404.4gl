--------------------------------------------------------------------------------
-- Titulo           : rolp404.4gl - Impresión recibos de pagos de jubilados
-- Elaboracion      : 04-Sep-2003
-- Autor            : JCM
-- Formato Ejecucion: fglrun rolp404 base módulo compañía
--					cod_liqrol fec_ini fec_fin
-- Ultima Correccion: 
-- Motivo Correccion:
--------------------------------------------------------------------------------

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE rm_loc		RECORD LIKE gent002.*
DEFINE fin_arch		INTEGER
DEFINE num_liq, tot_liq	INTEGER
DEFINE tot_sueldo	DECIMAL(14,2)
DEFINE tot_descontar	DECIMAL(14,2)
DEFINE vm_cod_lq	LIKE rolt048.n48_cod_liqrol
DEFINE vm_fec_ini	LIKE rolt048.n48_fecha_ini
DEFINE vm_fec_fin	LIKE rolt048.n48_fecha_fin
DEFINE vm_lineas_impr	SMALLINT



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp404.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 6 THEN
	-- Validar # parametros correcto
	CALL fl_mostrar_mensaje('Numero de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vm_cod_lq  = arg_val(4)
LET vm_fec_ini = arg_val(5)
LET vm_fec_fin = arg_val(6)
LET vg_proceso = 'rolp404'
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
DEFINE comando		CHAR(100)

CALL fl_nivel_isolation()
CALL fl_lee_compania(vg_codcia) RETURNING rm_cia.*
IF rm_cia.g01_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe compañía.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rm_loc.*
IF rm_loc.g02_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe localidad.','stop')
	EXIT PROGRAM
END IF
IF rm_loc.g02_localidad = 1 THEN
        LET vm_lineas_impr = 33
END IF
IF rm_loc.g02_localidad = 3 THEN
        LET vm_lineas_impr = 44
END IF

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF

CALL control_reporte(comando)

END FUNCTION



FUNCTION control_reporte(comando)
DEFINE comando		CHAR(100)
DEFINE r_jub		RECORD
				anio		LIKE rolt048.n48_ano_proceso,
				mes		LIKE rolt048.n48_mes_proceso,
				cod_trab	LIKE rolt048.n48_cod_trab,
				nom_trab	LIKE rolt030.n30_nombres,
				estado		LIKE rolt048.n48_estado,
				valor		LIKE rolt048.n48_val_jub_pat,
				moneda		LIKE rolt048.n48_moneda,
				tipo_pago	LIKE rolt048.n48_tipo_pago,
				bco_empresa	LIKE rolt048.n48_bco_empresa,
				cta_empresa	LIKE rolt048.n48_cta_empresa,
				cta_trabaj	LIKE rolt048.n48_cta_trabaj
			END RECORD
DEFINE flag 		INTEGER

DECLARE q_jub CURSOR FOR
	SELECT n48_ano_proceso, n48_mes_proceso, n48_cod_trab, n30_nombres,
		n48_estado, n48_val_jub_pat, n48_moneda, n48_tipo_pago,
		n48_bco_empresa, n48_cta_empresa, n48_cta_trabaj 
	FROM rolt048, rolt030 
	WHERE n48_compania   = vg_codcia
	  AND n48_cod_liqrol = vm_cod_lq
	  AND n48_fecha_ini  = vm_fec_ini
	  AND n48_fecha_fin  = vm_fec_fin
	  AND n30_compania   = n48_compania 
	  AND n30_cod_trab   = n48_cod_trab 
	ORDER BY n30_nombres 

LET flag = 0
START REPORT reporte_liq_jubilados TO PIPE comando
--START REPORT reporte_liq_jubilados TO FILE "jubila.txt"
	LET tot_liq       = 0
	LET num_liq       = 0
	LET tot_sueldo    = 0
	LET tot_descontar = 0
	FOREACH q_jub INTO r_jub.*
		LET flag = 1
		OUTPUT TO REPORT reporte_liq_jubilados(r_jub.*)
	END FOREACH
FINISH REPORT reporte_liq_jubilados
IF flag = 0 THEN
	CALL fl_mensaje_consulta_sin_registros() 
END IF

END FUNCTION



REPORT reporte_liq_jubilados(r_jub)
DEFINE r_jub		RECORD
				anio		LIKE rolt048.n48_ano_proceso,
				mes		LIKE rolt048.n48_mes_proceso,
				cod_trab	LIKE rolt048.n48_cod_trab,
				nom_trab	LIKE rolt030.n30_nombres,
				estado		LIKE rolt048.n48_estado,
				valor		LIKE rolt048.n48_val_jub_pat,
				moneda		LIKE rolt048.n48_moneda,
				tipo_pago	LIKE rolt048.n48_tipo_pago,
				bco_empresa	LIKE rolt048.n48_bco_empresa,
				cta_empresa	LIKE rolt048.n48_cta_empresa,
				cta_trabaj	LIKE rolt048.n48_cta_trabaj
			END RECORD
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE suel_t		VARCHAR(15)
DEFINE nom_est		VARCHAR(10)
DEFINE mensaje		VARCHAR(80)
DEFINE titulo		VARCHAR(80)
DEFINE forma_pago	VARCHAR(31)
DEFINE nom_depto	VARCHAR(36)
DEFINE encont		SMALLINT
DEFINE lineas, postit	SMALLINT
DEFINE escape, act_des	SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT
DEFINE act_neg, des_neg	SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_12cpi	SMALLINT

OUTPUT
	TOP MARGIN	0
	LEFT MARGIN	0
	RIGHT MARGIN	96
	BOTTOM MARGIN	2
	PAGE LENGTH	vm_lineas_impr

FORMAT

PAGE HEADER
	--print 'E';
	--print '&l26A';	-- Indica que voy a trabajar con hojas A4
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_neg	= 71		# Activar negrita.
	LET des_neg	= 72		# Desactivar negrita.
	LET act_des	= 0
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.

	print ASCII escape;
	print ASCII act_neg;
	print ASCII escape;
	print ASCII desact_comp;
	print ASCII escape;
	print ASCII act_10cpi

ON EVERY ROW
	NEED 30 LINES
	LET tot_liq = tot_liq + 1
	CALL fl_lee_trabajador_roles(vg_codcia, r_jub.cod_trab) 
		RETURNING r_n30.*
	CALL fl_lee_moneda(r_jub.moneda) RETURNING r_g13.*
	CALL retorna_estado(r_jub.estado) RETURNING nom_est
	CALL retorna_forma_pago(r_jub.tipo_pago, r_jub.cta_trabaj) 
		RETURNING forma_pago
	LET suel_t     = r_jub.valor USING "--,---,--&.##"
	--print '&k2S' 		-- Letra condensada
	--print ASCII escape;
	--print ASCII act_comp
	SKIP 6 LINES
	LET tot_sueldo = tot_sueldo + r_jub.valor
	CALL fl_lee_proceso_roles(vm_cod_lq) RETURNING r_n03.*
	LET titulo     = "RECIBO PAGO JUBILADOS (",r_n03.n03_nombre_abr CLIPPED,
				")"
	CALL fl_justifica_titulo('C', titulo, 80) RETURNING titulo
	PRINT COLUMN 001, rm_cia.g01_razonsocial
	PRINT COLUMN 001, titulo
	SKIP 1 LINES
	PRINT COLUMN 001, "NOMBRE(", r_jub.cod_trab USING "&&&&", "): ",
			  r_jub.nom_trab[1,36],
	      COLUMN 050, "LIQUIDACION: ", fl_retorna_nombre_mes(r_jub.mes),
					   " / ", r_jub.anio USING '&&&&' 
	PRINT COLUMN 001, "FORMA PAGO  : ", forma_pago,
	      COLUMN 055, "ESTADO LIQ.: ", nom_est
	SKIP 1 LINES
	PRINT COLUMN 001, "INGRESOS    : ",
	      COLUMN 062, DATE(TODAY) USING 'dd-mm-yyyy', 1 SPACES, TIME
	PRINT "--------------------------------------------------------------------------------";
	SKIP 1 LINES
	print ASCII escape;
	print ASCII des_neg
	PRINT COLUMN 001, "Valor Jubilacion: ",
	      COLUMN 033, suel_t
	print ASCII escape;
	print ASCII act_neg
	SKIP 1 LINES
	PRINT COLUMN 001, "TOTAL A RECIBIR   : ",
	      COLUMN 028, r_g13.g13_simbolo CLIPPED,
	      COLUMN 033, suel_t
	SKIP 4 LINES
	PRINT COLUMN 001, "RECIBI CONFORME: _________________________"

ON LAST ROW
	NEED 30 LINES
	LET suel_t = tot_sueldo USING "--,---,--&.##"
	SKIP 6 LINES
	PRINT COLUMN 001, rm_cia.g01_razonsocial
	PRINT COLUMN 032, "RECIBO DE PAGO JUBILADOS - TOTALES"
	SKIP 1 LINES
	PRINT COLUMN 001, "TOTALES     : No. de Liquidaciones ", 
		          tot_liq USING "###",
	      COLUMN 050, "LIQUIDACION: ", fl_retorna_nombre_mes(r_jub.mes),
					   " / ", r_jub.anio USING '&&&&' 
	SKIP 2 LINES
	PRINT COLUMN 001, "INGRESOS    : ",
	      COLUMN 062, DATE(TODAY) USING 'dd-mm-yyyy', 1 SPACES, TIME
	PRINT "--------------------------------------------------------------------------------";

	SKIP 1 LINES
	print ASCII escape;
	print ASCII des_neg
	PRINT COLUMN 001, "Total - Valor Jubilacion: ",
	      COLUMN 033, suel_t
	print ASCII escape;
	print ASCII act_neg
	SKIP 1 LINES
	PRINT COLUMN 001, "TOTAL A RECIBIR   : ",
	      COLUMN 028, r_g13.g13_simbolo CLIPPED,
	      COLUMN 033, suel_t
	SKIP 2 LINES

	PRINT COLUMN 033, "============="
	CALL sacar_totales('T') RETURNING r_jub.valor
	IF r_jub.valor > 0 THEN
		PRINT COLUMN 001, "TOTAL DE DEPOSITO A CUENTA",
		      COLUMN 033, r_jub.valor	USING "--,---,--&.##"
	END IF
	CALL sacar_totales('E') RETURNING r_jub.valor
	IF r_jub.valor > 0 THEN
		PRINT COLUMN 001, "TOTAL EN EFECTIVO",
		      COLUMN 033, r_jub.valor	USING "--,---,--&.##"
	END IF
	CALL sacar_totales('C') RETURNING r_jub.valor
	IF r_jub.valor > 0 THEN
		PRINT COLUMN 001, "TOTAL EN CHEQUE",
		      COLUMN 033, r_jub.valor	USING "--,---,--&.##"
	END IF
	print ASCII escape;
	print ASCII des_neg;
	print ASCII escape;
	print ASCII act_10cpi
END REPORT



FUNCTION sacar_totales(tipo)
DEFINE tipo		CHAR(1)
DEFINE tot_valor	DECIMAL(14,2)

SELECT NVL(SUM(n48_val_jub_pat), 0)
	INTO tot_valor
	FROM rolt048 
	WHERE n48_compania    =  vg_codcia
	  AND n48_cod_liqrol  = vm_cod_lq
	  AND n48_fecha_ini   = vm_fec_ini
	  AND n48_fecha_fin   = vm_fec_fin
 	  AND n48_estado     <> "E"
          AND n48_tipo_pago   = tipo
RETURN tot_valor

END FUNCTION



FUNCTION retorna_estado(estado)
DEFINE estado		LIKE rolt032.n32_estado

CASE estado
	WHEN 'A'
		RETURN "EN PROCESO"
	WHEN 'P'
		RETURN "CERRADO"
	WHEN 'E'
		RETURN "ELIMINADO"
END CASE

END FUNCTION



FUNCTION retorna_forma_pago(tipo_pago, cta_trabaj)
DEFINE tipo_pago	LIKE rolt030.n30_tipo_pago
DEFINE cta_trabaj	LIKE rolt030.n30_cta_trabaj
DEFINE forma_pago	VARCHAR(31)

CASE tipo_pago
	WHEN 'E'
		LET forma_pago = 'EFECTIVO'
	WHEN 'C'
		LET forma_pago = 'CHEQUE'
	WHEN 'T'
		LET forma_pago = 'DEPOSITO A CTA. ', cta_trabaj CLIPPED
END CASE
RETURN forma_pago

END FUNCTION
