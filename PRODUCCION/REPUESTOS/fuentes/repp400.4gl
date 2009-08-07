{*
 * Titulo           : repp400.4gl - Listado detalle facturas/devoluciones
 * Elaboracion      : 27-dic-2001
 * Autor            : NPC
 * Formato Ejecucion: fglrun repp400 base módulo compañía
 *}
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_rep		RECORD LIKE rept019.*
DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE vm_moneda_des	LIKE gent013.g13_nombre
DEFINE vm_tipo_fact	CHAR(2)
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE rm_r01		RECORD LIKE rept001.*

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp400.error')
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
LET vg_proceso = 'repp400'
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
OPEN FORM f_rep FROM "../forms/repf400_1"
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
DEFINE expr_vend	VARCHAR(50)

LET vm_fecha_ini = TODAY
LET vm_fecha_fin = TODAY
LET rm_rep.r19_moneda = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_rep.r19_moneda) RETURNING r_mon.*
IF r_mon.g13_moneda IS NULL THEN
       	CALL fgl_winmessage(vg_producto,'No existe moneda base.','stop')
        EXIT PROGRAM
END IF
LET rm_rep.r19_cont_cred = 'T'
DISPLAY r_mon.g13_nombre TO tit_moneda
LET vm_moneda_des = r_mon.g13_nombre
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
	LET expr_tipo = ' '
	IF rm_rep.r19_cont_cred <> 'T' THEN
		LET expr_tipo = '  AND r19_cont_cred = "', rm_rep.r19_cont_cred, '"'
	END IF
	LET expr_vend = ' '
	IF rm_rep.r19_vendedor IS NOT NULL THEN
		LET expr_vend = '  AND r19_vendedor = ', rm_rep.r19_vendedor
	END IF
	LET total_bru = 0
	LET total_des = 0
	LET total_iva = 0
	LET total_net = 0
	LET query = 'SELECT *, r19_tot_neto - (r19_tot_bruto - r19_tot_dscto) ',
			'FROM rept019 ',
			'WHERE r19_compania  = ', vg_codcia,
			'  AND r19_localidad = ', vg_codloc,
			'  AND r19_cod_tran IN ("FA", "AF", "DF") ',
			expr_tipo CLIPPED,
			expr_vend CLIPPED,
			'  AND r19_moneda    = "', rm_rep.r19_moneda, '"',
			'  AND DATE(r19_fecing) BETWEEN "', vm_fecha_ini,
			'" AND "', vm_fecha_fin, '"',
			' ORDER BY 36, 4'

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
	FOREACH q_deto INTO r_rep.*, valor_iva
		IF rm_rep.r19_vendedor IS NOT NULL AND
			rm_rep.r19_vendedor <> r_rep.r19_vendedor THEN
			CONTINUE FOREACH
		END IF
		IF r_rep.r19_cod_tran = r_gen.g21_codigo_dev 
                OR r_rep.r19_cod_tran = "AF" THEN
			LET r_rep.r19_tot_bruto = r_rep.r19_tot_bruto * (-1)
			LET r_rep.r19_tot_dscto = r_rep.r19_tot_dscto * (-1)
			LET valor_iva           = valor_iva * (-1)
			LET r_rep.r19_tot_neto  = r_rep.r19_tot_neto * (-1)
		END IF
		LET total_bru = total_bru + r_rep.r19_tot_bruto
		LET total_des = total_des + r_rep.r19_tot_dscto
		LET total_iva = total_iva + valor_iva
		LET total_net = total_net + r_rep.r19_tot_neto
		OUTPUT TO REPORT rep_costos(r_rep.*, valor_iva, total_bru,
					total_des, total_iva, total_net)
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
INPUT BY NAME rm_rep.r19_moneda, rm_rep.r19_vendedor, vm_fecha_ini,
	vm_fecha_fin, rm_rep.r19_cont_cred
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
	ON KEY(F2)
		IF INFIELD(r19_moneda) THEN
               		CALL fl_ayuda_monedas()
                       		RETURNING mone_aux, nomm_aux, deci_aux
       		      	LET int_flag = 0
                      	IF mone_aux IS NOT NULL THEN
                              	LET rm_rep.r19_moneda = mone_aux
                               	DISPLAY BY NAME rm_rep.r19_moneda
                               	DISPLAY nomm_aux TO tit_moneda
                       	END IF
                END IF
		IF INFIELD(r19_vendedor) THEN
			CALL fl_ayuda_vendedores(vg_codcia)
				RETURNING rm_r01.r01_codigo, 
					  rm_r01.r01_nombres
			IF rm_r01.r01_codigo IS NOT NULL THEN
			    	LET rm_rep.r19_vendedor = rm_r01.r01_codigo
			    	DISPLAY BY NAME rm_rep.r19_vendedor
			    	DISPLAY rm_r01.r01_nombres TO n_vendedor
			END IF
		END IF
	BEFORE FIELD vm_fecha_ini
		LET fecha_ini = vm_fecha_ini
	BEFORE FIELD vm_fecha_fin
		LET fecha_fin = vm_fecha_fin
	AFTER FIELD r19_moneda
               	IF rm_rep.r19_moneda IS NOT NULL THEN
                       	CALL fl_lee_moneda(rm_rep.r19_moneda)
                               	RETURNING r_mon.*
                       	IF r_mon.g13_moneda IS NULL THEN
                               	CALL fgl_winmessage(vg_producto,'Moneda no existe.','exclamation')
                               	NEXT FIELD r19_moneda
                       	END IF
                       	IF rm_rep.r19_moneda <> rg_gen.g00_moneda_base
                       	AND rm_rep.r19_moneda <> rg_gen.g00_moneda_alt THEN
                               	CALL fgl_winmessage(vg_producto,'La moneda solo puede ser moneda base o alterna.','exclamation')
                               	NEXT FIELD r19_moneda
			END IF
               	ELSE
                       	LET rm_rep.r19_moneda = rg_gen.g00_moneda_base
                       	CALL fl_lee_moneda(rm_rep.r19_moneda)
				RETURNING r_mon.*
                       	DISPLAY BY NAME rm_rep.r19_moneda
               	END IF
               	DISPLAY r_mon.g13_nombre TO tit_moneda
		LET vm_moneda_des = r_mon.g13_nombre
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
	AFTER FIELD r19_vendedor
		IF rm_rep.r19_vendedor IS NOT NULL THEN
			CALL fl_lee_vendedor_rep(vg_codcia, rm_rep.r19_vendedor)
				RETURNING rm_r01.*
			IF rm_r01.r01_codigo IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Vendedor no existe.','exclamation')
				NEXT FIELD r19_vendedor
			END IF 
			DISPLAY rm_r01.r01_nombres TO n_vendedor
		ELSE
			CLEAR n_vendedor
		END IF		 
	AFTER INPUT
		IF vm_fecha_ini > vm_fecha_fin THEN
			CALL fgl_winmessage(vg_producto,'Fecha inicial debe ser menor a fecha final.','exclamation')
			NEXT FIELD vm_fecha_ini
		END IF
END INPUT

END FUNCTION



REPORT rep_costos(r_rep, valor_iva, total_bru, total_des, total_iva, total_net)
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
DEFINE fecha		DATE
DEFINE factura		VARCHAR(15)
DEFINE tipo		CHAR(1)

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	2
	RIGHT MARGIN	90
	BOTTOM MARGIN	4
	PAGE LENGTH	66
FORMAT
PAGE HEADER
	IF rm_rep.r19_vendedor IS NULL THEN
		LET rm_r01.r01_nombres = 'T O D O S'
	END IF
	print 'E'; print '&l26A';	-- Indica que voy a trabajar con hojas A4
	print '&k4S'	                -- Letra (12 cpi)
	LET modulo  = "Módulo: Repuestos"
	LET long    = LENGTH(modulo)
	LET usuario = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('I', 'LISTADO DETALLE DE FACTURACION', 80)
		RETURNING titulo
	{FOR i = 1 TO long
		LET titulo[i,i] = modulo[i,i]
	END FOR}
--	LET titulo = modulo, titulo 
	LET tipo   = rm_rep.r19_cont_cred
	IF tipo = 'T' THEN
		LET tipo = NULL
	END IF
	PRINT COLUMN 1, rm_cia.g01_razonsocial,
  	      COLUMN 120, "Página: ", PAGENO USING "&&&"
	PRINT COLUMN 1, modulo CLIPPED,
	      COLUMN 52, titulo CLIPPED,
	      COLUMN 124, "REPP400" 
	PRINT COLUMN 48, "** Moneda        : ", rm_rep.r19_moneda,
						" ", vm_moneda_des
	PRINT COLUMN 48, "** Vendedor      : ", rm_r01.r01_nombres
	PRINT COLUMN 48, "** Fecha Inicial : ", vm_fecha_ini USING "dd-mm-yyyy"
	PRINT COLUMN 48, "** Fecha Final   : ", vm_fecha_fin USING "dd-mm-yyyy"
	PRINT COLUMN 48, "** Tipo          : ";
	IF rm_rep.r19_cont_cred = 'R' THEN
		PRINT tipo, ' Crédito'
	END IF
	IF rm_rep.r19_cont_cred = 'C' THEN
		PRINT tipo, ' Contado'
	END IF
	IF rm_rep.r19_cont_cred = 'T' THEN
		PRINT 'T O D O S'
	END IF
	PRINT COLUMN 01, "Fecha  : ", TODAY USING "dd-mm-yyyy", 1 SPACES, TIME,
	      COLUMN 112, usuario
	SKIP 1 LINES
	print '&k2S'	                -- Letra condensada (16 cpi)
	PRINT COLUMN 1,   "Fecha",
	      COLUMN 13,  "TP",
	      COLUMN 17,  "No. Fact.",
	      COLUMN 34,  "Cliente",
	      COLUMN 66,  "Valor Bruto",
	      COLUMN 81,  "Valor Dscto.",
	      COLUMN 100, "Valor IVA",
	      COLUMN 117, "Valor Neto"
	PRINT "----------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 2 LINES
	LET fecha   = DATE(r_rep.r19_fecing)
	LET factura = r_rep.r19_num_tran
	CALL fl_justifica_titulo('I', factura, 15) RETURNING factura
	PRINT COLUMN 1,   fecha USING "dd-mm-yyyy",
	      COLUMN 13,  r_rep.r19_cod_tran,
	      COLUMN 17,  factura,
	      COLUMN 34,  r_rep.r19_nomcli[1,25],
	      COLUMN 61,  r_rep.r19_tot_bruto USING "-,---,---,--&.##",
	      COLUMN 79,  r_rep.r19_tot_dscto USING "---,---,--&.##",
	      COLUMN 95,  valor_iva           USING "---,---,--&.##",
	      COLUMN 111, r_rep.r19_tot_neto  USING "-,---,---,--&.##"
	
ON LAST ROW
	PRINT COLUMN 65,  "----------------",
	      COLUMN 83,  "--------------",
	      COLUMN 99,  "--------------",
	      COLUMN 115, "----------------"
	PRINT COLUMN 48, "TOTALES ==>  ", total_bru USING "-,---,---,--&.##",
	      COLUMN 79,  total_des USING "---,---,--&.##",
	      COLUMN 95,  total_iva USING "---,---,--&.##",
	      COLUMN 111, total_net USING "-,---,---,--&.##"

END REPORT



FUNCTION borrar_cabecera()

CLEAR r19_moneda, tit_moneda, vm_fecha_ini, vm_fecha_fin
INITIALIZE rm_rep.*, vm_fecha_ini, vm_fecha_fin TO NULL

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
