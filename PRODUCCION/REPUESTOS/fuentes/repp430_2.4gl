------------------------------------------------------------------------------
-- Titulo           : repp430.4gl - Listado de Transacciones Repuestos
-- Elaboracion      : 09-ago-2002
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp430 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE vm_nuevoprog     VARCHAR(400)
DEFINE rm_rep		RECORD LIKE rept019.*
DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE vm_moneda_des	LIKE gent013.g13_nombre
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE vm_total_fob_im	DECIMAL(12,2)

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
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
LET vg_proceso = 'repp430'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)

CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
OPEN WINDOW w_mas AT 3,2 WITH 08 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_rep FROM "../forms/repf430_1"
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
DEFINE total_cos	DECIMAL(12,2)
DEFINE flag		VARCHAR(1)
DEFINE comando		VARCHAR(100)

LET vm_fecha_ini = TODAY
LET vm_fecha_fin = TODAY
LET rm_rep.r19_moneda = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_rep.r19_moneda) RETURNING r_mon.*
IF r_mon.g13_moneda IS NULL THEN
       	CALL fgl_winmessage(vg_producto,'No existe moneda base.','stop')
        EXIT PROGRAM
END IF
DISPLAY r_mon.g13_nombre TO tit_moneda
LET vm_moneda_des = r_mon.g13_nombre
WHILE TRUE
	CALL fl_lee_cod_transaccion(rm_rep.r19_cod_tran) RETURNING r_gen.*
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
	LET total_cos = 0
	LET vm_total_fob_im = 0
	LET query = 'SELECT *, r19_tot_neto - (r19_tot_bruto - r19_tot_dscto) ',
			'FROM rept019 ',
			'WHERE r19_compania  = ', vg_codcia,
			'  AND r19_localidad = ', vg_codloc,
			'  AND r19_cod_tran  = "', rm_rep.r19_cod_tran, '"',
			'  AND r19_moneda    = "', rm_rep.r19_moneda, '"',
			'  AND DATE(r19_fecing) BETWEEN "', vm_fecha_ini,
			'" AND "', vm_fecha_fin, '"',
			' ORDER BY r19_fecing, r19_num_tran'
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
	IF rm_rep.r19_cod_tran = 'FA' OR rm_rep.r19_cod_tran = 'DF'
	  OR rm_rep.r19_cod_tran = 'AF'
	  OR rm_rep.r19_cod_tran = 'RQ' OR rm_rep.r19_cod_tran = 'DR'
	  OR rm_rep.r19_cod_tran = 'CL' OR rm_rep.r19_cod_tran = 'DC'
	THEN
		START REPORT rep_fact_dev TO PIPE comando
	END IF
	IF rm_rep.r19_cod_tran = 'TR' THEN
		START REPORT rep_transferencia TO PIPE comando
	END IF
	IF rm_rep.r19_cod_tran = 'AC' OR rm_rep.r19_cod_tran = 'A+'
	  OR rm_rep.r19_cod_tran = 'A-' THEN
		START REPORT rep_ajustes TO PIPE comando
	END IF
	IF rm_rep.r19_cod_tran = 'IM' THEN
		START REPORT rep_importaciones TO PIPE comando
	END IF
	FOREACH q_deto INTO r_rep.*, valor_iva
		IF r_rep.r19_cod_tran = r_gen.g21_codigo_dev THEN
			LET r_rep.r19_tot_bruto = r_rep.r19_tot_bruto * (-1)
			LET r_rep.r19_tot_dscto = r_rep.r19_tot_dscto * (-1)
			LET valor_iva           = valor_iva * (-1)
			LET r_rep.r19_tot_neto  = r_rep.r19_tot_neto * (-1)
		END IF
		LET total_bru = total_bru + r_rep.r19_tot_bruto
		LET total_des = total_des + r_rep.r19_tot_dscto
		LET total_iva = total_iva + valor_iva
		LET total_net = total_net + r_rep.r19_tot_neto
		LET total_cos = total_cos + r_rep.r19_tot_costo
		IF rm_rep.r19_cod_tran = 'FA' OR rm_rep.r19_cod_tran = 'DF'
		  OR rm_rep.r19_cod_tran = 'AF'
		  OR rm_rep.r19_cod_tran = 'RQ' OR rm_rep.r19_cod_tran = 'DR'
		THEN
			LET flag = 'F'
			OUTPUT TO REPORT rep_fact_dev(r_rep.*, valor_iva,
					total_bru, total_des, total_iva,
					total_net, total_cos, flag)
		END IF
		IF rm_rep.r19_cod_tran = 'CL' OR rm_rep.r19_cod_tran = 'DC'
		THEN
			IF r_rep.r19_oc_interna IS NULL THEN
				CONTINUE FOREACH
			END IF
			LET flag = 'D'
			OUTPUT TO REPORT rep_fact_dev(r_rep.*, valor_iva,
					total_bru, total_des, total_iva,
					total_net, 0, flag)
		END IF
		IF rm_rep.r19_cod_tran = 'TR' THEN
			OUTPUT TO REPORT rep_transferencia (r_rep.*, total_cos)
		END IF
		IF rm_rep.r19_cod_tran = 'AC' OR rm_rep.r19_cod_tran = 'A+'
	  	  OR rm_rep.r19_cod_tran = 'A-' THEN
			OUTPUT TO REPORT rep_ajustes (r_rep.*, total_cos)
		END IF
		IF rm_rep.r19_cod_tran = 'IM' THEN
			OUTPUT TO REPORT rep_importaciones (r_rep.*, total_cos)
		END IF
	END FOREACH
	IF rm_rep.r19_cod_tran = 'FA' OR rm_rep.r19_cod_tran = 'DF'
	  OR rm_rep.r19_cod_tran = 'AF'
	  OR rm_rep.r19_cod_tran = 'RQ' OR rm_rep.r19_cod_tran = 'DR'
	  OR rm_rep.r19_cod_tran = 'CL' OR rm_rep.r19_cod_tran = 'DC'
	THEN
		FINISH REPORT rep_fact_dev
	END IF
	IF rm_rep.r19_cod_tran = 'TR' THEN
		FINISH REPORT rep_transferencia
	END IF
	IF rm_rep.r19_cod_tran = 'AC' OR rm_rep.r19_cod_tran = 'A+'
  	  OR rm_rep.r19_cod_tran = 'A-' THEN
		FINISH REPORT rep_ajustes
	END IF
	IF rm_rep.r19_cod_tran = 'IM' THEN
		FINISH REPORT rep_importaciones
	END IF
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_tra		RECORD LIKE gent021.*
DEFINE mone_aux         LIKE gent013.g13_moneda
DEFINE nomm_aux         LIKE gent013.g13_nombre
DEFINE deci_aux         LIKE gent013.g13_decimales
DEFINE cod_tran      	LIKE gent021.g21_cod_tran
DEFINE nombre      	LIKE gent021.g21_nombre
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE

INITIALIZE mone_aux, cod_tran TO NULL
LET int_flag = 0
INPUT BY NAME rm_rep.r19_moneda, rm_rep.r19_cod_tran, vm_fecha_ini, vm_fecha_fin
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
		IF INFIELD(r19_cod_tran) THEN
			CALL fl_ayuda_tipo_tran('N')
				RETURNING cod_tran, nombre
			IF cod_tran IS NOT NULL THEN
			    	LET rm_rep.r19_cod_tran = cod_tran
			    	DISPLAY BY NAME rm_rep.r19_cod_tran
			    	DISPLAY nombre TO tit_tipo 
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
	AFTER FIELD r19_cod_tran
		IF rm_rep.r19_cod_tran IS NOT NULL THEN
			CALL fl_lee_cod_transaccion(rm_rep.r19_cod_tran)
				RETURNING r_tra.*
			IF r_tra.g21_cod_tran IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Tipo de Transacción no existe.','exclamation')
				NEXT FIELD r19_cod_tran
			END IF 
			DISPLAY r_tra.g21_nombre TO tit_tipo
		ELSE
			CLEAR tit_tipo
		END IF		 
	AFTER INPUT
		IF vm_fecha_ini > vm_fecha_fin THEN
			CALL fgl_winmessage(vg_producto,'Fecha inicial debe ser menor a fecha final.','exclamation')
			NEXT FIELD vm_fecha_ini
		END IF
END INPUT

END FUNCTION



REPORT rep_fact_dev (r_rep, valor_iva, total_bru, total_des, total_iva,
			total_net, total_cos, flag)
DEFINE r_rep		RECORD LIKE rept019.*
DEFINE r_gen		RECORD LIKE gent021.*
DEFINE valor_iva	DECIMAL(11,2)
DEFINE total_bru	DECIMAL(12,2)
DEFINE total_des	DECIMAL(11,2)
DEFINE total_iva	DECIMAL(11,2)
DEFINE total_net	DECIMAL(12,2)
DEFINE total_cos	DECIMAL(12,2)
DEFINE flag		VARCHAR(1)
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i,long		SMALLINT
DEFINE fecha		DATE
DEFINE factura		VARCHAR(10)
DEFINE origen		VARCHAR(10)

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	90
	BOTTOM MARGIN	4
	PAGE LENGTH	66
FORMAT

PAGE HEADER
	print ascii 27, ascii 64;
	print ascii 27, ascii 77;
	print ascii 27, ascii 15;
	LET modulo  = "Módulo: Repuestos"
	LET long    = LENGTH(modulo)
	LET usuario = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('I', 'LISTADO DETALLE DE TRANSACCIONES', 80)
		RETURNING titulo
	CALL fl_lee_cod_transaccion(rm_rep.r19_cod_tran) RETURNING r_gen.*
	{FOR i = 1 TO long
		LET titulo[i,i] = modulo[i,i]
	END FOR}
--	LET titulo = modulo, titulo 
	PRINT COLUMN 1, rm_cia.g01_razonsocial,
  	      COLUMN 122, "Página: ", PAGENO USING "&&&"
	PRINT COLUMN 1, modulo CLIPPED,
	      COLUMN 51, titulo CLIPPED,
	      COLUMN 126, UPSHIFT(vg_proceso) 
	PRINT COLUMN 47, "** Moneda        : ", rm_rep.r19_moneda,
						" ", vm_moneda_des
	PRINT COLUMN 47, "** Tipo Transac. : ", rm_rep.r19_cod_tran, " ",
						r_gen.g21_nombre
	PRINT COLUMN 47, "** Fecha Inicial : ", vm_fecha_ini USING "dd-mm-yyyy"
	PRINT COLUMN 47, "** Fecha Final   : ", vm_fecha_fin USING "dd-mm-yyyy"
	PRINT COLUMN 01, "Fecha  : ", TODAY USING "dd-mm-yyyy", 1 SPACES, TIME,
	      COLUMN 114, usuario
	SKIP 1 LINES
	PRINT COLUMN 1,   "Fecha",
	      COLUMN 12,  "TP",
	      COLUMN 15,  "Tran.",
	      COLUMN 21,  "Factura.",
	      COLUMN 31,  "Cliente",
	      COLUMN 58,  "Valor Bruto",
	      COLUMN 72,  "Valor Dscto.",
	      COLUMN 90,  "Valor IVA",
	      COLUMN 106, "Valor Neto";
	IF flag = 'F' THEN
	      PRINT COLUMN 122, "Valor Costo"
	ELSE
	      PRINT COLUMN 122, "No. O.Comp."
	END IF
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	--OJO
	NEED 2 LINES
	LET fecha   = DATE(r_rep.r19_fecing)
	LET factura = r_rep.r19_num_tran
	CALL fl_justifica_titulo('I', factura, 15) RETURNING factura
	PRINT COLUMN 1,   fecha USING "dd-mm-yyyy",
	      COLUMN 12,  r_rep.r19_cod_tran,
	      COLUMN 15,  factura,
	      COLUMN 21,  r_rep.r19_num_dev USING "<<<<<<<<",
	      COLUMN 31,  r_rep.r19_nomcli[1,21],
	      COLUMN 53,  r_rep.r19_tot_bruto USING "-,---,---,--&.##",
	      COLUMN 70,  r_rep.r19_tot_dscto USING "---,---,--&.##",
	      COLUMN 85,  valor_iva           USING "---,---,--&.##",
	      COLUMN 100, r_rep.r19_tot_neto  USING "-,---,---,--&.##";
	IF flag = 'F' THEN
	      PRINT COLUMN 117, r_rep.r19_tot_costo USING "-,---,---,--&.##"
	ELSE
	      PRINT COLUMN 117, r_rep.r19_oc_interna
	END IF
	
ON LAST ROW
	PRINT COLUMN 53,  "----------------",
	      COLUMN 70,  "--------------",
	      COLUMN 85,  "--------------",
	      COLUMN 100, "----------------";
	IF flag = 'F' THEN
	      PRINT COLUMN 117, "----------------"
	ELSE
	      PRINT COLUMN 117, " "
	END IF
	PRINT COLUMN 40, "TOTALES ==>  ", total_bru USING "-,---,---,--&.##",
	      COLUMN 70,  total_des USING "---,---,--&.##",
	      COLUMN 85,  total_iva USING "---,---,--&.##",
	      COLUMN 100, total_net USING "-,---,---,--&.##";
	IF flag = 'F' THEN
	      PRINT COLUMN 117, total_cos USING "-,---,---,--&.##"
	ELSE
	      PRINT COLUMN 117, " "
	END IF

END REPORT



REPORT rep_transferencia (r_rep, total_cos)
DEFINE r_rep		RECORD LIKE rept019.*
DEFINE total_cos	DECIMAL(12,2)
DEFINE r_gen		RECORD LIKE gent021.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i,long		SMALLINT
DEFINE fecha		DATE
DEFINE factura		VARCHAR(15)
DEFINE origen		VARCHAR(30)
DEFINE destino		VARCHAR(30)

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	90
	BOTTOM MARGIN	4
	PAGE LENGTH	66
FORMAT

PAGE HEADER
	print ascii 27, ascii 15;
	LET modulo  = "Módulo: Repuestos"
	LET long    = LENGTH(modulo)
	LET usuario = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('I', 'LISTADO DETALLE DE TRANSACCIONES', 80)
		RETURNING titulo
	CALL fl_lee_cod_transaccion(rm_rep.r19_cod_tran) RETURNING r_gen.*
	{FOR i = 1 TO long
		LET titulo[i,i] = modulo[i,i]
	END FOR}
--	LET titulo = modulo, titulo 
	PRINT COLUMN 1, rm_cia.g01_razonsocial,
  	      COLUMN 103, "Página: ", PAGENO USING "&&&"
	PRINT COLUMN 1, modulo CLIPPED,
	      COLUMN 41, titulo CLIPPED,
	      COLUMN 107, UPSHIFT(vg_proceso)
	PRINT COLUMN 38, "** Moneda        : ", rm_rep.r19_moneda,
						" ", vm_moneda_des
	PRINT COLUMN 38, "** Tipo Transac. : ", rm_rep.r19_cod_tran, " ",
						r_gen.g21_nombre
	PRINT COLUMN 38, "** Fecha Inicial : ", vm_fecha_ini USING "dd-mm-yyyy"
	PRINT COLUMN 38, "** Fecha Final   : ", vm_fecha_fin USING "dd-mm-yyyy"
	PRINT COLUMN 01, "Fecha  : ", TODAY USING "dd-mm-yyyy", 1 SPACES, TIME,
	      COLUMN 95, usuario
	SKIP 1 LINES
	PRINT COLUMN 1,   "Fecha",
	      COLUMN 13,  "TP",
	      COLUMN 17,  "No. Tran.",
	      COLUMN 34,  "Origen",
	      COLUMN 66,  "Destino",
	      COLUMN 103, "Valor Costo"
	PRINT "-----------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 2 LINES
	LET fecha   = DATE(r_rep.r19_fecing)
	LET factura = r_rep.r19_num_tran
	CALL fl_justifica_titulo('I', factura, 15) RETURNING factura
	CALL fl_lee_bodega_rep (vg_codcia, r_rep.r19_bodega_ori)
		RETURNING r_r02.*
	LET origen = r_r02.r02_nombre
	CALL fl_lee_bodega_rep (vg_codcia, r_rep.r19_bodega_dest)
		RETURNING r_r02.*
	LET destino = r_r02.r02_nombre
	CALL fl_justifica_titulo('I', origen, 30) RETURNING origen
	CALL fl_justifica_titulo('I', destino, 30) RETURNING destino
	PRINT COLUMN 1,   fecha USING "dd-mm-yyyy",
	      COLUMN 13,  r_rep.r19_cod_tran,
	      COLUMN 17,  factura,
	      COLUMN 34,  origen,
	      COLUMN 66,  destino,
	      COLUMN 98,  r_rep.r19_tot_costo USING "-,---,---,--&.##"
	
ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 98,  "----------------"
	PRINT COLUMN 87, "TOTAL ==>  ", total_cos USING "-,---,---,--&.##"

END REPORT



REPORT rep_ajustes (r_rep, total_cos)
DEFINE r_rep		RECORD LIKE rept019.*
DEFINE total_cos	DECIMAL(12,2)
DEFINE r_gen		RECORD LIKE gent021.*
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i,long		SMALLINT
DEFINE fecha		DATE
DEFINE factura		VARCHAR(15)
DEFINE referen		VARCHAR(40)

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	90
	BOTTOM MARGIN	4
	PAGE LENGTH	66
FORMAT

PAGE HEADER
	print ascii 27, ascii 64;
	print ascii 27, ascii 77;
	print ascii 27, ascii 15;
	LET modulo  = "Módulo: Repuestos"
	LET long    = LENGTH(modulo)
	LET usuario = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('I', 'LISTADO DETALLE DE TRANSACCIONES', 80)
		RETURNING titulo
	CALL fl_lee_cod_transaccion(rm_rep.r19_cod_tran) RETURNING r_gen.*
	{FOR i = 1 TO long
		LET titulo[i,i] = modulo[i,i]
	END FOR}
--	LET titulo = modulo, titulo 
	PRINT COLUMN 1, rm_cia.g01_razonsocial,
  	      COLUMN 81, "Página: ", PAGENO USING "&&&"
	PRINT COLUMN 1, modulo CLIPPED,
	      COLUMN 30, titulo CLIPPED,
	      COLUMN 85, UPSHIFT(vg_proceso)
	PRINT COLUMN 27, "** Moneda        : ", rm_rep.r19_moneda,
						" ", vm_moneda_des
	PRINT COLUMN 27, "** Tipo Transac. : ", rm_rep.r19_cod_tran, " ",
						r_gen.g21_nombre
	PRINT COLUMN 27, "** Fecha Inicial : ", vm_fecha_ini USING "dd-mm-yyyy"
	PRINT COLUMN 27, "** Fecha Final   : ", vm_fecha_fin USING "dd-mm-yyyy"
	PRINT COLUMN 01, "Fecha  : ", TODAY USING "dd-mm-yyyy", 1 SPACES, TIME,
	      COLUMN 73, usuario
	SKIP 1 LINES
	PRINT COLUMN 1,   "Fecha",
	      COLUMN 13,  "TP",
	      COLUMN 17,  "No. Tran.",
	      COLUMN 34,  "Referencia",
	      COLUMN 80,  "Valor Ajuste"
	PRINT "-------------------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 2 LINES
	LET fecha   = DATE(r_rep.r19_fecing)
	LET factura = r_rep.r19_num_tran
	LET referen = r_rep.r19_referencia
	CALL fl_justifica_titulo('I', factura, 15) RETURNING factura
	CALL fl_justifica_titulo('I', referen, 40) RETURNING referen
	PRINT COLUMN 1,   fecha USING "dd-mm-yyyy",
	      COLUMN 13,  r_rep.r19_cod_tran,
	      COLUMN 17,  factura,
	      COLUMN 34,  referen,
	      COLUMN 76,  r_rep.r19_tot_costo USING "-,---,---,--&.##"
	
ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 76,  "----------------"
	PRINT COLUMN 65, "TOTAL ==>  ", total_cos USING "-,---,---,--&.##"

END REPORT



REPORT rep_importaciones (r_rep, total_cos)
DEFINE r_rep		RECORD LIKE rept019.*
DEFINE total_cos	DECIMAL(12,2)
DEFINE r_gen		RECORD LIKE gent021.*
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i,long		SMALLINT
DEFINE fecha		DATE
DEFINE factura		VARCHAR(15)
DEFINE liquid		VARCHAR(11)
DEFINE total_fob	DECIMAL(12,2)
DEFINE pedido		LIKE rept029.r29_pedido

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	90
	BOTTOM MARGIN	4
	PAGE LENGTH	66
FORMAT

PAGE HEADER
	print ascii 27, ascii 64;
	print ascii 27, ascii 77;
	print ascii 27, ascii 15
	LET modulo  = "Módulo: Repuestos"
	LET long    = LENGTH(modulo)
	LET usuario = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('I', 'LISTADO DETALLE DE TRANSACCIONES', 80)
		RETURNING titulo
	CALL fl_lee_cod_transaccion(rm_rep.r19_cod_tran) RETURNING r_gen.*
	{FOR i = 1 TO long
		LET titulo[i,i] = modulo[i,i]
	END FOR}
--	LET titulo = modulo, titulo 
	PRINT COLUMN 1, rm_cia.g01_razonsocial,
  	      COLUMN 82, "Página: ", PAGENO USING "&&&"
	PRINT COLUMN 1, modulo CLIPPED,
	      COLUMN 31, titulo CLIPPED,
	      COLUMN 86, UPSHIFT(vg_proceso)
	PRINT COLUMN 27, "** Moneda        : ", rm_rep.r19_moneda,
						" ", vm_moneda_des
	PRINT COLUMN 27, "** Tipo Transac. : ", rm_rep.r19_cod_tran, " ",
						r_gen.g21_nombre
	PRINT COLUMN 27, "** Fecha Inicial : ", vm_fecha_ini USING "dd-mm-yyyy"
	PRINT COLUMN 27, "** Fecha Final   : ", vm_fecha_fin USING "dd-mm-yyyy"
	PRINT COLUMN 01, "Fecha  : ", TODAY USING "dd-mm-yyyy", 1 SPACES, TIME,
	      COLUMN 74, usuario
	SKIP 1 LINES
	PRINT COLUMN 1,   "Fecha",
	      COLUMN 13,  "TP",
	      COLUMN 17,  "No. Tran.",
	      COLUMN 34,  "No. Liq.",
	      COLUMN 47,  "No. Ped.",
	      COLUMN 66,  "Total FOB",
	      COLUMN 82,  "Total Costo"
	PRINT "--------------------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 2 LINES
	SELECT SUM (r20_cant_ven * r20_fob) INTO total_fob
		FROM rept019, rept020
		WHERE r19_compania  = r_rep.r19_compania
		  AND r19_localidad = r_rep.r19_localidad
		  AND r19_cod_tran  = r_rep.r19_cod_tran 
		  AND r19_num_tran  = r_rep.r19_num_tran 
		  AND r19_compania  = r20_compania
		  AND r19_localidad = r20_localidad
		  AND r19_cod_tran  = r20_cod_tran 
		  AND r19_num_tran  = r20_num_tran 
	DECLARE q_deto2 CURSOR FOR
			SELECT r29_pedido
				FROM rept029
				WHERE r29_compania  = r_rep.r19_compania
				  AND r29_localidad = r_rep.r19_localidad
				  AND r29_numliq    = r_rep.r19_numliq
	OPEN q_deto2
	FETCH q_deto2 INTO pedido
	CLOSE q_deto2
	LET vm_total_fob_im = vm_total_fob_im + total_fob
	LET fecha   = DATE(r_rep.r19_fecing)
	LET factura = r_rep.r19_num_tran
	LET liquid  = r_rep.r19_numliq
	CALL fl_justifica_titulo('I', factura, 15) RETURNING factura
	CALL fl_justifica_titulo('I', liquid, 11) RETURNING liquid
	CALL fl_justifica_titulo('I', pedido, 10) RETURNING pedido
	PRINT COLUMN 1,   fecha USING "dd-mm-yyyy",
	      COLUMN 13,  r_rep.r19_cod_tran,
	      COLUMN 17,  factura,
	      COLUMN 34,  liquid,
	      COLUMN 47,  pedido,
	      COLUMN 59,  total_fob USING "-,---,---,--&.##",
	      COLUMN 77,  r_rep.r19_tot_costo USING "-,---,---,--&.##"
	
ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 59,  "----------------",
	      COLUMN 77,  "----------------"
	PRINT COLUMN 48, "TOTAL ==>  ",vm_total_fob_im USING "-,---,---,--&.##",
	      COLUMN 77, total_cos USING "-,---,---,--&.##"

END REPORT



FUNCTION borrar_cabecera()

CLEAR r19_moneda, tit_moneda, tit_tipo, vm_fecha_ini, vm_fecha_fin
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
