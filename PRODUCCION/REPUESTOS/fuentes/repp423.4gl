{*
 * Titulo           : repp423.4gl - Listado de Transacciones Repuestos
 * Elaboracion      : 14-ene-2008
 * Autor            : JCM
 * Formato Ejecucion: fglrun repp423 base módulo compañía localidad
 *}
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_rep		RECORD LIKE rept019.*
DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE vm_moneda_des	LIKE gent013.g13_nombre
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE vm_linea		LIKE rept010.r10_linea



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp423.error')
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
LET vg_proceso = 'repp423'
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
OPEN FORM f_rep FROM "../forms/repf423_1"
DISPLAY FORM f_rep
CALL borrar_cabecera()
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE i,col		SMALLINT
DEFINE query		VARCHAR(1000)
DEFINE expr_linea	VARCHAR(150)
DEFINE r_rep		RECORD LIKE rept019.*
DEFINE r_r20		RECORD LIKE rept020.*
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

INITIALIZE vm_linea TO NULL
LET vm_fecha_ini = TODAY
LET vm_fecha_fin = TODAY
LET rm_rep.r19_cod_tran = 'FA'
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
	LET expr_linea = ''
	IF vm_linea IS NOT NULL THEN
		LET expr_linea = ' AND r20_linea = "', vm_linea CLIPPED, '" '
	END IF
	LET query = 'SELECT * ',
			'FROM rept019, rept020 ',
			'WHERE r19_compania  = ', vg_codcia,
			'  AND r19_localidad = ', vg_codloc,
			'  AND r19_cod_tran  IN ("FA", "DF", "AF") ',
			'  AND r19_moneda    = "', rm_rep.r19_moneda, '"',
			'  AND DATE(r19_fecing) BETWEEN "', vm_fecha_ini,
			'" AND "', vm_fecha_fin, '"',
			'  AND r20_compania  = r19_compania ',
			'  AND r20_localidad = r19_localidad ',
			'  AND r20_cod_tran  = r19_cod_tran ',
			'  AND r20_num_tran  = r19_num_tran ',
			expr_linea CLIPPED,
			' ORDER BY r20_compania, r20_localidad, r20_cod_tran, ',
			'          r20_num_tran, r20_item '
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

	LET int_flag = 0
	START REPORT rep_fact_dev TO PIPE comando
	FOREACH q_deto INTO r_rep.*, r_r20.*
		OUTPUT TO REPORT rep_fact_dev(r_rep.*, r_r20.*)
		IF int_flag THEN
			EXIT FOREACH
		END IF
	END FOREACH
	FINISH REPORT rep_fact_dev
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_tra		RECORD LIKE gent021.*
DEFINE r_r03		RECORD LIKE rept003.*
DEFINE mone_aux         LIKE gent013.g13_moneda
DEFINE nomm_aux         LIKE gent013.g13_nombre
DEFINE deci_aux         LIKE gent013.g13_decimales
DEFINE nombre      	LIKE gent021.g21_nombre
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE

INITIALIZE mone_aux TO NULL
LET int_flag = 0
INPUT BY NAME rm_rep.r19_moneda, vm_linea, vm_fecha_ini, vm_fecha_fin
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
		IF INFIELD(vm_linea) THEN
                     	CALL fl_ayuda_lineas_rep(vg_codcia)
				RETURNING r_r03.r03_codigo, r_r03.r03_nombre
       		      	LET int_flag = 0
                       	IF r_r03.r03_codigo IS NOT NULL THEN
                             	LET vm_linea = r_r03.r03_codigo
                               	DISPLAY BY NAME vm_linea
                               	DISPLAY r_r03.r03_nombre TO tit_linea
                        END IF
                END IF
		LET int_flag = 0
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
	AFTER FIELD vm_linea
               	IF vm_linea IS NOT NULL THEN
                       	CALL fl_lee_linea_rep(vg_codcia, vm_linea)
                     		RETURNING r_r03.*
                        IF r_r03.r03_compania IS NULL THEN
                               	CALL fgl_winmessage(vg_producto,'Línea no existe.','exclamation')
                               	NEXT FIELD vm_linea
                        END IF
			DISPLAY r_r03.r03_nombre TO tit_linea
		ELSE
			CLEAR tit_linea
                END IF
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



REPORT rep_fact_dev (r_rep, r_r20) 
DEFINE r_rep		RECORD LIKE rept019.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE r_gen		RECORD LIKE gent021.*
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i,long		SMALLINT
DEFINE fecha		DATE
DEFINE factura		VARCHAR(10)
DEFINE r_r10		RECORD LIKE rept010.*

DEFINE signo		INTEGER
DEFINE precio		LIKE rept020.r20_precio

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	90
	BOTTOM MARGIN	4
	PAGE LENGTH	66
FORMAT

PAGE HEADER
	--print 'E'; --print '&l26A';	-- Indica que voy a trabajar con hojas A4
	print '&k4S'	                -- Letra (12 cpi)
	print ascii 27, ascii 64;
	print ascii 27, ascii 77 
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
  	      COLUMN 158, "Página: ", PAGENO USING "&&&"
	PRINT COLUMN 1, modulo CLIPPED,
	      COLUMN 51, titulo CLIPPED,
	      COLUMN 162, UPSHIFT(vg_proceso) 
	PRINT COLUMN 47, "** Moneda        : ", rm_rep.r19_moneda,
						" ", vm_moneda_des
	IF vm_linea IS NOT NULL THEN
		PRINT COLUMN 47, "** Linea         : ", vm_linea
	ELSE
		PRINT COLUMN 47, "** Linea         : T O D A S "
	END IF
	PRINT COLUMN 47, "** Fecha Inicial : ", vm_fecha_ini USING "dd-mm-yyyy"
	PRINT COLUMN 47, "** Fecha Final   : ", vm_fecha_fin USING "dd-mm-yyyy"
	PRINT COLUMN 01, "Fecha  : ", TODAY USING "dd-mm-yyyy", 1 SPACES, TIME,
	      COLUMN 154, usuario
	SKIP 1 LINES
	print '&k2S'	                -- Letra condensada (16 cpi)
	PRINT COLUMN 1,   fl_justifica_titulo("D", "Cod.", 5), 
	      COLUMN 7,   "Cliente",
	      COLUMN 49,  "Item",
	      COLUMN 66,  "Descripcion.",
	      COLUMN 88,  "Fecha",
		  COLUMN 100, "TP",
	      COLUMN 104, "Numero",
	      COLUMN 112, "Cant. Ven.",
	      COLUMN 124, fl_justifica_titulo("D", "PVP Total", 14),
	      COLUMN 142, fl_justifica_titulo("D", "Costo", 14),
	      COLUMN 158, fl_justifica_titulo("D", "Costo Total", 14)
	PRINT "-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 2 LINES
	LET fecha   = DATE(r_rep.r19_fecing)
	LET factura = r_rep.r19_num_tran
	CALL fl_justifica_titulo('I', factura, 15) RETURNING factura
	CALL fl_lee_item(vg_codcia, r_r20.r20_item) RETURNING r_r10.*

	IF r_r20.r20_cod_tran = 'FA' THEN
		LET signo = 1
	ELSE
		LET signo = (-1)
	END IF 

	LET precio = r_r20.r20_precio - (r_r20.r20_val_descto / r_r20.r20_cant_ven) 
	LET precio = precio * (1 - r_rep.r19_descuento / 100) 

	PRINT COLUMN 1,   r_rep.r19_codcli USING "#####",
	      COLUMN 7,   r_rep.r19_nomcli[1,40],
	      COLUMN 49,  r_r20.r20_item,
	      COLUMN 66,  r_r10.r10_nombre[1,21],
	      COLUMN 88,  fecha USING "dd-mm-yyyy",
		  COLUMN 100, r_r20.r20_cod_tran CLIPPED,
	      COLUMN 104, r_rep.r19_num_tran USING "#####&",
	      COLUMN 112, r_r20.r20_cant_ven * signo USING "--,---,--&",
	      COLUMN 124, precio * r_r20.r20_cant_ven * signo   
						USING "---,---,--&.&&",
	      COLUMN 142, r_r20.r20_costo * signo USING "---,---,--&.&&",
	      COLUMN 158, r_r20.r20_costo * r_r20.r20_cant_ven * signo 
		  				USING "---,---,--&.&&"
END REPORT



FUNCTION borrar_cabecera()

CLEAR r19_moneda, tit_moneda, vm_linea, tit_linea, vm_fecha_ini, vm_fecha_fin
INITIALIZE rm_rep.*, vm_linea, vm_fecha_ini, vm_fecha_fin TO NULL

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
