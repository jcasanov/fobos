-----------------------------------------------------------------------------
-- Titulo           : cxcp414.4gl - Listado detalle facturas varios modulos
-- Elaboracion      : 29-sep-2007
-- Autor            : JCM
-- Formato Ejecucion: fglrun cxcp414 base módulo compañía
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_nuevoprog     VARCHAR(400)
DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE vm_tipo_fact	CHAR(2)
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE rm_r01		RECORD LIKE rept001.*

DEFINE rm_output	RECORD
	cod_tran		CHAR(2),
	factura			DECIMAL(15,0),
	fecha			DATE,
	cliente			VARCHAR(40),
	ced_ruc			VARCHAR(13),
	base12			DECIMAL(11,2),
	base0			DECIMAL(11,2),
	dscto			DECIMAL(11,2),
	subtotal		DECIMAL(11,2),
	iva				DECIMAL(11,2),
	total			DECIMAL(11,2),
	vendedor		VARCHAR(40),
	tipo_vta		VARCHAR(5)
END RECORD



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxcp414.err')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN   -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'cxcp414'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)

CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_tipo_fact = 'FA'
OPEN WINDOW w_mas AT 3,2 WITH 13 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_rep FROM "../forms/cxcf414_1"
DISPLAY FORM f_rep
CALL borrar_cabecera()
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE i,col		SMALLINT
DEFINE query		VARCHAR(1000)
DEFINE r_rep		RECORD LIKE rept019.*
DEFINE r_gen		RECORD LIKE gent021.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE valor_iva	DECIMAL(11,2)
DEFINE total_bru	DECIMAL(12,2)
DEFINE total_des	DECIMAL(11,2)
DEFINE total_iva	DECIMAL(11,2)
DEFINE total_net	DECIMAL(12,2)
DEFINE comando		VARCHAR(100)
DEFINE expr_tipo	VARCHAR(50)

LET vm_fecha_ini = TODAY
LET vm_fecha_fin = TODAY
WHILE TRUE
	CALL fl_lee_cod_transaccion(vm_tipo_fact) RETURNING r_gen.*
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		CONTINUE WHILE
	END IF
	CALL fl_lee_compania(vg_codcia) RETURNING rm_cia.*
	LET total_bru = 0
	LET total_des = 0
	LET total_iva = 0
	LET total_net = 0

	LET query = 'SELECT r19_cod_tran, r19_num_tran, DATE(r19_fecing), ',
                'NVL(z01_nomcli, r19_nomcli), NVL(z01_num_doc_id, r19_cedruc), ',
				' CASE WHEN ROUND(r19_tot_neto - (r19_tot_bruto - r19_tot_dscto), 2) > 0.00 THEN ROUND(r19_tot_bruto, 2) ELSE 0 END, ',
       			' CASE WHEN ROUND(r19_tot_neto - (r19_tot_bruto - r19_tot_dscto), 2) = 0.00 THEN ROUND(r19_tot_bruto, 2) ELSE 0 END, ',
       			' r19_tot_dscto, r19_tot_bruto - r19_tot_dscto, ',
				' r19_tot_neto - (r19_tot_bruto - r19_tot_dscto), ',
				' r19_tot_neto, r01_nombres, "RE" ',
			'FROM rept019, OUTER cxct001, rept001 ',
			'WHERE r19_compania  = ', vg_codcia,
			'  AND r19_localidad = ', vg_codloc,
			'  AND r19_cod_tran IN ("FA", "AF", "DF") ',
			'  AND DATE(r19_fecing) BETWEEN "', vm_fecha_ini, '" AND "', vm_fecha_fin, '"',
			'  AND z01_codcli = r19_codcli ',
			'  AND r01_compania = r19_compania ',
			'  AND r01_codigo = r19_vendedor ',
			' UNION ALL ',
			'SELECT "FA",t23_num_factura, DATE(t23_fec_factura), z01_nomcli, ',
				' z01_num_doc_id, ',
				' CASE WHEN ROUND(t23_tot_neto - (t23_tot_bruto - t23_tot_dscto), 2) > 0.00 THEN ROUND(t23_tot_bruto, 2) ELSE 0 END, ',
       			' CASE WHEN ROUND(t23_tot_neto - (t23_tot_bruto - t23_tot_dscto), 2) = 0.00 THEN ROUND(t23_tot_bruto, 2) ELSE 0 END, ',
       			' t23_tot_dscto, t23_tot_bruto - t23_tot_dscto, ',
				' t23_tot_neto - (t23_tot_bruto - t23_tot_dscto), ',
				' t23_tot_neto, t03_nombres, "TA" ',
			'FROM talt023, cxct001, talt003 ',
			'WHERE t23_compania  = ', vg_codcia,
			'  AND t23_localidad = ', vg_codloc,
			'  AND t23_num_factura IS NOT NULL ',
			'  AND DATE(t23_fecing) BETWEEN "', vm_fecha_ini, '" AND "', vm_fecha_fin, '"',
			'  AND z01_codcli = t23_cod_cliente ',
			'  AND t03_compania = t23_compania ',
			'  AND t03_mecanico = t23_cod_asesor ',
			' ORDER BY 1'
display query
	PREPARE deto FROM query
	DECLARE q_deto CURSOR FOR deto
	OPEN q_deto
	FETCH q_deto
	IF STATUS = NOTFOUND THEN
		CLOSE q_deto
		CALL fl_mensaje_consulta_sin_registros()
		CONTINUE WHILE
	END IF
	CLOSE q_deto
	START REPORT rep_costos TO PIPE comando
	FOREACH q_deto INTO rm_output.*
		IF rm_output.cod_tran = r_gen.g21_codigo_dev OR 
           rm_output.cod_tran = "AF" 
        THEN
			LET rm_output.base12   = rm_output.base12   * (-1)
			LET rm_output.base0    = rm_output.base0    * (-1)
			LET rm_output.dscto    = rm_output.dscto    * (-1)
			LET rm_output.subtotal = rm_output.subtotal * (-1)
			LET rm_output.iva      = rm_output.iva      * (-1)
			LET rm_output.total    = rm_output.total    * (-1)
		END IF
--		LET total_bru = total_bru + r_rep.r19_tot_bruto
--		LET total_des = total_des + r_rep.r19_tot_dscto
--		LET total_iva = total_iva + valor_iva
--		LET total_net = total_net + r_rep.r19_tot_neto
		OUTPUT TO REPORT rep_costos(rm_output.*)
	END FOREACH
	FINISH REPORT rep_costos
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE mone_aux         LIKE gent013.g13_moneda
DEFINE nomm_aux         LIKE gent013.g13_nombre
DEFINE deci_aux         LIKE gent013.g13_decimales
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE

INITIALIZE mone_aux TO NULL
LET int_flag = 0
INPUT BY NAME vm_fecha_ini, vm_fecha_fin
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
	ON KEY(F2)
	BEFORE FIELD vm_fecha_ini
		LET fecha_ini = vm_fecha_ini
	BEFORE FIELD vm_fecha_fin
		LET fecha_fin = vm_fecha_fin
	AFTER FIELD vm_fecha_ini 
		IF vm_fecha_ini IS NOT NULL THEN
			IF vm_fecha_ini > TODAY THEN
				CALL fgl_winmessage(vg_producto,'La fecha de inicio no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD vm_fecha_ini
			END IF
		ELSE
			LET vm_fecha_ini = fecha_ini
			DISPLAY BY NAME vm_fecha_ini
		END IF
	AFTER FIELD vm_fecha_fin 
		IF vm_fecha_fin IS NOT NULL THEN
			IF vm_fecha_fin > TODAY THEN
				CALL fgl_winmessage(vg_producto,'La fecha de término no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD vm_fecha_fin
			END IF
		ELSE
			LET vm_fecha_fin = fecha_fin
			DISPLAY BY NAME vm_fecha_fin
		END IF
	AFTER INPUT
		IF vm_fecha_ini > vm_fecha_fin THEN
			CALL fgl_winmessage(vg_producto,'Fecha inicial debe ser menor a fecha final.','exclamation')
			NEXT FIELD vm_fecha_ini
		END IF
END INPUT

END FUNCTION



REPORT rep_costos(cod_tran, factura, fecha, cliente, ced_ruc, base12, base0, 
                  dscto, subtotal, iva, total, vendedor, tipo_vta)
DEFINE r_rep		RECORD LIKE rept019.*
DEFINE valor_iva	DECIMAL(11,2)
DEFINE total_bru	DECIMAL(12,2)
DEFINE total_des	DECIMAL(11,2)
DEFINE total_iva	DECIMAL(11,2)
DEFINE total_net	DECIMAL(12,2)
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i,long		SMALLINT
DEFINE tipo		CHAR(1)

-- Var. program
DEFINE cod_tran			CHAR(2)
DEFINE factura			DECIMAL(15,0)
DEFINE fecha			DATE
DEFINE cliente			VARCHAR(40)
DEFINE ced_ruc			VARCHAR(13)
DEFINE base12			DECIMAL(11,2)
DEFINE base0			DECIMAL(11,2)
DEFINE dscto			DECIMAL(11,2)
DEFINE subtotal			DECIMAL(11,2)
DEFINE iva				DECIMAL(11,2)
DEFINE total			DECIMAL(11,2)
DEFINE vendedor			VARCHAR(40)
DEFINE tipo_vta			VARCHAR(5)


OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	2
	RIGHT MARGIN	90
	BOTTOM MARGIN	4
	PAGE LENGTH	66
FORMAT
PAGE HEADER
	print 'E'; 
	print '&l26A';	-- Indica que voy a trabajar con hojas A4
	print '&l1O';		-- Modo landscape
	print '&k4S'	    -- Letra (12 cpi)

	LET modulo  = "Módulo: Cobranzas"
	LET long    = LENGTH(modulo)
	LET usuario = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('I', 'LISTADO DETALLE DE FACTURACION PARA EL SRI', 80)
		RETURNING titulo
	{FOR i = 1 TO long
		LET titulo[i,i] = modulo[i,i]
	END FOR}
--	LET titulo = modulo, titulo 
	PRINT COLUMN 1, rm_cia.g01_razonsocial,
  	      COLUMN 120, "Página: ", PAGENO USING "&&&"
	PRINT COLUMN 1, modulo CLIPPED,
	      COLUMN 52, titulo CLIPPED,
	      COLUMN 124, "CXCP414" 
	PRINT COLUMN 48, "** Fecha Inicial : ", vm_fecha_ini USING "dd-mm-yyyy"
	PRINT COLUMN 48, "** Fecha Final   : ", vm_fecha_fin USING "dd-mm-yyyy"

	PRINT COLUMN 01, "Fecha  : ", TODAY USING "dd-mm-yyyy", 1 SPACES, TIME,
	      COLUMN 112, usuario
	SKIP 1 LINES

	print '&k2S'	                -- Letra condensada (16 cpi)
	PRINT COLUMN 1,   "Tipo",
	      COLUMN 7,   "No. Fact.",
		  COLUMN 15,  "Fecha",
	      COLUMN 27,  "Cliente",
	      COLUMN 69,  "Ced/Ruc",
		  COLUMN 84,  fl_justifica_titulo("D", "Base 12", 14),
		  COLUMN 100, fl_justifica_titulo("D", "Base 0", 12),
	      COLUMN 114, fl_justifica_titulo("D", "Valor Dscto.", 12),
	      COLUMN 128, fl_justifica_titulo("D", "Subtotal", 14),
	      COLUMN 144, fl_justifica_titulo("D", "Valor IVA", 12),
	      COLUMN 158, fl_justifica_titulo("D", "Valor Neto", 14),
		  COLUMN 174, "Vendedor",
		  COLUMN 216, "Tipo Vta"
	PRINT "-----------------------------------------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 2 LINES

	PRINT COLUMN 1,   cod_tran,
	      COLUMN 7,   fl_justifica_titulo('I', factura, 6),
		  COLUMN 15,  fecha USING "dd-mm-yyyy",
	      COLUMN 27,  cliente,
	      COLUMN 69,  ced_ruc,
		  COLUMN 84,  base12   USING "---,---,--&.##",
		  COLUMN 100, base0    USING "-,---,--&.##",
		  COLUMN 114, dscto    USING "-,---,--&.##",
		  COLUMN 128, subtotal USING "---,---,--&.##",
		  COLUMN 144, iva      USING "-,---,--&.##",
		  COLUMN 158, total    USING "---,---,--&.##",
		  COLUMN 174, vendedor,
		  COLUMN 216, tipo_vta
	
ON LAST ROW
	PRINT COLUMN 84,  "--------------",
	      COLUMN 100, "------------",
	      COLUMN 114, "------------",
	      COLUMN 128, "--------------",
	      COLUMN 144, "------------",
	      COLUMN 158, "--------------"

	PRINT COLUMN 65, "TOTALES ==>  ", 
		  COLUMN 84,  SUM(base12)   USING "---,---,--&.##",
		  COLUMN 100, SUM(base0)    USING "-,---,--&.##",
		  COLUMN 114, SUM(dscto)    USING "-,---,--&.##",
		  COLUMN 128, SUM(subtotal) USING "---,---,--&.##",
		  COLUMN 144, SUM(iva)      USING "-,---,--&.##",
		  COLUMN 158, SUM(total)    USING "---,---,--&.##"

END REPORT



FUNCTION borrar_cabecera()

CLEAR vm_fecha_ini, vm_fecha_fin
INITIALIZE vm_fecha_ini, vm_fecha_fin TO NULL
LET vm_fecha_fin = CURRENT

END FUNCTION



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
	LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc, 'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
