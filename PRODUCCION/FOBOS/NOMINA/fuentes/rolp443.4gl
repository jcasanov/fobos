--------------------------------------------------------------------------------
-- Titulo           : rolp443.4gl - Impresión recibos de devolucion de 
--				    fondo cesantia
-- Elaboracion      : 27-nov-2003
-- Autor            : JCM
-- Formato Ejecucion: fglrun rolp443 base módulo compañía cod_trab secuencia
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
DEFINE vm_cod_trab   	INTEGER
DEFINE vm_secuencia	INTEGER
DEFINE vm_ano, vm_mes	SMALLINT
DEFINE vm_lineas_impr	SMALLINT



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 5 THEN
	-- Validar # parametros correcto
	CALL fl_mostrar_mensaje('Numero de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base      = arg_val(1)
LET vg_modulo    = arg_val(2)
LET vg_codcia    = arg_val(3)
LET vm_cod_trab  = arg_val(4)
LET vm_secuencia = arg_val(5)
LET vg_proceso  = 'rolp443'
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
DEFINE r_cesan		RECORD
	cod_trab		LIKE rolt082.n82_cod_trab,
	nom_trab		LIKE rolt030.n30_nombres,
	valor			LIKE rolt082.n82_valor,
	moneda			LIKE gent013.g13_moneda,
	banco			LIKE rolt082.n82_banco,
	numero_cta    		LIKE rolt082.n82_numero_cta,
	num_cheque    		LIKE rolt082.n82_num_cheque
END RECORD
DEFINE flag 		INTEGER

DECLARE q_cesan CURSOR FOR
	SELECT n82_cod_trab, n30_nombres, n82_valor,  
	       n82_moneda,   n82_banco,   n82_numero_cta, 
               n82_num_cheque, YEAR(n82_fecha), MONTH(n82_fecha)
	FROM rolt082, rolt030 
	WHERE n82_compania     = vg_codcia
	  AND n82_cod_trab     = vm_cod_trab
	  AND n82_secuencia    = vm_secuencia
	  AND n30_compania     = n82_compania 
	  AND n30_cod_trab     = n82_cod_trab 

LET flag = 0
START REPORT reporte_liq_cesan TO PIPE comando
--START REPORT reporte_liq_cesan TO FILE "jubila.txt"
	LET tot_liq       = 0
	LET num_liq       = 0
	LET tot_sueldo    = 0
	LET tot_descontar = 0
	FOREACH q_cesan INTO r_cesan.*, vm_ano, vm_mes
		LET flag = 1
		OUTPUT TO REPORT reporte_liq_cesan(r_cesan.*)
	END FOREACH
FINISH REPORT reporte_liq_cesan
IF flag = 0 THEN
	CALL fl_mensaje_consulta_sin_registros() 
END IF

END FUNCTION



REPORT reporte_liq_cesan(r_cesan)
DEFINE r_cesan		RECORD
	cod_trab		LIKE rolt082.n82_cod_trab,
	nom_trab		LIKE rolt030.n30_nombres,
	valor			LIKE rolt082.n82_valor,
	moneda			LIKE gent013.g13_moneda,
	banco			LIKE rolt082.n82_banco,
	numero_cta		LIKE rolt082.n82_numero_cta,
	num_cheque		LIKE rolt082.n82_num_cheque
END RECORD
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
	CALL fl_lee_trabajador_roles(vg_codcia, r_cesan.cod_trab) 
		RETURNING r_n30.*
	CALL fl_lee_moneda(r_cesan.moneda) RETURNING r_g13.*
	LET suel_t     = r_cesan.valor USING "--,---,--&.##"
	--print '&k2S' 		-- Letra condensada
	--print ASCII escape;
	--print ASCII act_comp
	SKIP 6 LINES
	LET tot_sueldo = tot_sueldo + r_cesan.valor
	PRINT COLUMN 001, rm_cia.g01_razonsocial
	PRINT COLUMN 022, "RECIBO DEVOLUCION FONDO CESANTIA"
	SKIP 1 LINES
	PRINT COLUMN 001, "NOMBRE(", r_cesan.cod_trab USING "&&&&", "): ",
			  r_cesan.nom_trab[1,36],
	      COLUMN 050, "LIQUIDACION: ", fl_retorna_nombre_mes(vm_mes),
						   " / ", vm_ano USING '&&&&'
	SKIP 1 LINES
	PRINT COLUMN 001, "INGRESOS    : ",
	      COLUMN 062, DATE(TODAY) USING 'dd-mm-yyyy', 1 SPACES, TIME
	PRINT "--------------------------------------------------------------------------------";
	SKIP 1 LINES
	print ASCII escape;
	print ASCII des_neg
	PRINT COLUMN 001, "Valor Devuelto: ",
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
	PRINT COLUMN 032, "RECIBO DEV. FONDO CESANTIA - TOTALES"
	SKIP 1 LINES
	PRINT COLUMN 001, "TOTALES     : No. de Liquidaciones ", 
		          tot_liq USING "###",
	      COLUMN 050, "LIQUIDACION: ", fl_retorna_nombre_mes(vm_mes),
						   " / ", vm_ano USING '&&&&' 
	SKIP 2 LINES
	PRINT COLUMN 001, "INGRESOS    : ",
	      COLUMN 062, DATE(TODAY) USING 'dd-mm-yyyy', 1 SPACES, TIME
	PRINT "--------------------------------------------------------------------------------";

	SKIP 1 LINES
	print ASCII escape;
	print ASCII des_neg
	PRINT COLUMN 001, "Total - Valor Devuelto: ",
	      COLUMN 033, suel_t
	print ASCII escape;
	print ASCII act_neg
	SKIP 1 LINES
	PRINT COLUMN 001, "TOTAL A RECIBIR   : ",
	      COLUMN 028, r_g13.g13_simbolo CLIPPED,
	      COLUMN 033, suel_t
	SKIP 2 LINES

	PRINT COLUMN 033, "============="
	CALL sacar_totales() RETURNING r_cesan.valor
	IF r_cesan.valor > 0 THEN
		PRINT COLUMN 001, "TOTAL EN CHEQUE",
		      COLUMN 033, r_cesan.valor	USING "--,---,--&.##"
	END IF
	print ASCII escape;
	print ASCII des_neg;
	print ASCII escape;
	print ASCII act_10cpi
END REPORT



FUNCTION sacar_totales()
DEFINE tot_valor	DECIMAL(14,2)

SELECT NVL(SUM(n82_valor), 0) INTO tot_valor FROM rolt082 
	WHERE n82_compania     = vg_codcia
	  AND YEAR(n82_fecha)  = vm_ano
	  AND MONTH(n82_fecha) = vm_mes

RETURN tot_valor

END FUNCTION
