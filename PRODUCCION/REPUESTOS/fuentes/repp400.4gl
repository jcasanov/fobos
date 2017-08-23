-----------------------------------------------------------------------------
-- Titulo           : repp400.4gl - Listado detalle facturas/devoluciones
-- Elaboracion      : 27-dic-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp400 base módulo compañía
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
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
CALL startlog('../logs/repp400.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN   -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'repp400'
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

CALL fl_nivel_isolation()
LET vm_tipo_fact = 'FA'
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 13
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_mas AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST - 1, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rep FROM "../forms/repf400_1"
ELSE
	OPEN FORM f_rep FROM "../forms/repf400_1c"
END IF
DISPLAY FORM f_rep
CALL borrar_cabecera()
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE i,col		SMALLINT
DEFINE query		CHAR(1000)
DEFINE r_rep		RECORD LIKE rept019.*
DEFINE r_gen		RECORD LIKE gent021.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE valor_iva	DECIMAL(11,2)
DEFINE total_bru	DECIMAL(12,2)
DEFINE total_des	DECIMAL(11,2)
DEFINE total_iva	DECIMAL(11,2)
DEFINE total_fle	DECIMAL(11,2)
DEFINE total_net	DECIMAL(12,2)
DEFINE comando		VARCHAR(100)
DEFINE expr_tipo	VARCHAR(50)

LET vm_fecha_ini = vg_fecha
LET vm_fecha_fin = vg_fecha
LET rm_rep.r19_moneda = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_rep.r19_moneda) RETURNING r_mon.*
IF r_mon.g13_moneda IS NULL THEN
	CALL fl_mostrar_mensaje('No existe moneda base.','stop')
    EXIT PROGRAM
END IF
LET rm_rep.r19_cont_cred = 'T'
IF vg_gui = 0 THEN
	CALL muestra_contcred(rm_rep.r19_cont_cred)
END IF
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
	LET expr_tipo = NULL
	IF rm_rep.r19_cont_cred <> 'T' THEN
		LET expr_tipo = '  AND r19_cont_cred = "',
				rm_rep.r19_cont_cred, '"'
	END IF
	LET total_bru = 0
	LET total_des = 0
	LET total_iva = 0
	LET total_fle = 0
	LET total_net = 0
	LET query = 'SELECT *, r19_tot_neto - (r19_tot_bruto - r19_tot_dscto) ',
			' - r19_flete ',
			'FROM rept019 ',
			'WHERE r19_compania  = ', vg_codcia,
			'  AND r19_localidad = ', vg_codloc,
			'  AND (r19_cod_tran = "', vm_tipo_fact, '"',
			'   OR r19_cod_tran   IN ("DF","AF")) ',
			expr_tipo CLIPPED,
			'  AND r19_moneda    = "', rm_rep.r19_moneda, '"',
			'  AND DATE(r19_fecing) BETWEEN "', vm_fecha_ini,
			'" AND "', vm_fecha_fin, '"',
			' ORDER BY 37, 3, 4'
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
		IF r_rep.r19_cod_tran = 'DF' OR r_rep.r19_cod_tran = 'AF' THEN
			LET r_rep.r19_tot_bruto = r_rep.r19_tot_bruto * (-1)
			LET r_rep.r19_tot_dscto = r_rep.r19_tot_dscto * (-1)
			LET valor_iva           = valor_iva * (-1)
			LET r_rep.r19_flete     = r_rep.r19_flete * (-1)
			LET r_rep.r19_tot_neto  = r_rep.r19_tot_neto * (-1)
		END IF
		LET total_bru = total_bru + r_rep.r19_tot_bruto
		LET total_des = total_des + r_rep.r19_tot_dscto
		LET total_iva = total_iva + valor_iva
		LET total_fle = total_fle + r_rep.r19_flete
		LET total_net = total_net + r_rep.r19_tot_neto
		OUTPUT TO REPORT rep_costos(r_rep.*, valor_iva, total_bru,
					total_des, total_iva, total_fle,
					total_net)
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
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
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
			CALL fl_ayuda_vendedores(vg_codcia, 'A', 'F')
				RETURNING rm_r01.r01_codigo, 
					  rm_r01.r01_nombres
			IF rm_r01.r01_codigo IS NOT NULL THEN
			    	LET rm_rep.r19_vendedor = rm_r01.r01_codigo
			    	DISPLAY BY NAME rm_rep.r19_vendedor
			    	DISPLAY rm_r01.r01_nombres TO n_vendedor
			END IF
		END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD vm_fecha_ini
		LET fecha_ini = vm_fecha_ini
	BEFORE FIELD vm_fecha_fin
		LET fecha_fin = vm_fecha_fin
	AFTER FIELD r19_moneda
               	IF rm_rep.r19_moneda IS NOT NULL THEN
                       	CALL fl_lee_moneda(rm_rep.r19_moneda)
                               	RETURNING r_mon.*
                       	IF r_mon.g13_moneda IS NULL THEN
							CALL fl_mostrar_mensaje('Moneda no existe.','exclamation')
                            NEXT FIELD r19_moneda
                       	END IF
                       	IF rm_rep.r19_moneda <> rg_gen.g00_moneda_base AND rm_rep.r19_moneda <> rg_gen.g00_moneda_alt THEN
							CALL fl_mostrar_mensaje('La moneda solo puede ser moneda base o alterna.','exclamation')
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
			IF vm_fecha_ini > vg_fecha THEN
				CALL fl_mostrar_mensaje('La fecha de inicio no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD vm_fecha_ini
			END IF
		ELSE
			LET vm_fecha_ini = fecha_ini
			DISPLAY BY NAME vm_fecha_ini
		END IF
	AFTER FIELD vm_fecha_fin 
		IF vm_fecha_fin IS NOT NULL THEN
			IF vm_fecha_fin > vg_fecha THEN
				CALL fl_mostrar_mensaje('La fecha de término no puede ser mayor a la de hoy.','exclamation')
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
				CALL fl_mostrar_mensaje('Vendedor no existe.','exclamation')
				NEXT FIELD r19_vendedor
			END IF 
			DISPLAY rm_r01.r01_nombres TO n_vendedor
		ELSE
			CLEAR n_vendedor
		END IF
	AFTER FIELD r19_cont_cred
		IF vg_gui = 0 THEN
			IF rm_rep.r19_cont_cred IS NOT NULL THEN
				CALL muestra_contcred(rm_rep.r19_cont_cred)
			ELSE
				CLEAR tit_cont_cred
			END IF
		END IF
	AFTER INPUT
		IF vm_fecha_ini > vm_fecha_fin THEN
			CALL fl_mostrar_mensaje('Fecha inicial debe ser menor a fecha final.','exclamation')
			NEXT FIELD vm_fecha_ini
		END IF
END INPUT

END FUNCTION



REPORT rep_costos(r_rep, valor_iva, total_bru, total_des, total_iva, total_fle,
		total_net)
DEFINE r_rep		RECORD LIKE rept019.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r38		RECORD LIKE rept038.*
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE valor_iva	DECIMAL(11,2)
DEFINE total_bru	DECIMAL(12,2)
DEFINE total_des	DECIMAL(11,2)
DEFINE total_iva	DECIMAL(11,2)
DEFINE total_fle	DECIMAL(11,2)
DEFINE total_net	DECIMAL(12,2)
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i,long		SMALLINT
DEFINE fecha		DATE
DEFINE factura		VARCHAR(15)
DEFINE tipo		CHAR(1)
DEFINE escape		SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_12cpi	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	132
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	IF rm_rep.r19_vendedor IS NULL THEN
		LET rm_r01.r01_nombres = 'T O D O S'
	END IF
	--print 'E'; --print '&l26A';	-- Indica que voy a trabajar con hojas A4
	--print '&k4S'	                -- Letra (12 cpi)
	LET modulo  = "MODULO: INVENTARIO"
	LET long    = LENGTH(modulo)
	LET usuario = 'USUARIO: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('I', 'LISTADO DETALLE DE FACTURACION', 80)
		RETURNING titulo
	LET tipo   = rm_rep.r19_cont_cred
	IF tipo = 'T' THEN
		LET tipo = NULL
	END IF
	SKIP 2 LINES
	print ASCII escape;
	print ASCII act_comp;
	print ASCII escape;
	print ASCII act_12cpi
	PRINT COLUMN 01,  rm_cia.g01_razonsocial,
  	      COLUMN 136, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 01,  modulo CLIPPED,
	      COLUMN 52,  titulo CLIPPED,
	      COLUMN 140, UPSHIFT(vg_proceso)
	PRINT COLUMN 48,  "** MONEDA        : ", rm_rep.r19_moneda,
						" ", vm_moneda_des
	PRINT COLUMN 48,  "** VENDEDOR      : ", rm_r01.r01_nombres
	PRINT COLUMN 48,  "** FECHA INICIAL : ", vm_fecha_ini USING "dd-mm-yyyy"
	PRINT COLUMN 48,  "** FECHA FINAL   : ", vm_fecha_fin USING "dd-mm-yyyy"
	PRINT COLUMN 48,  "** TIPO          : ";
	IF rm_rep.r19_cont_cred = 'R' THEN
		PRINT tipo, ' CREDITO'
	ELSE
		IF rm_rep.r19_cont_cred = 'C' THEN
			PRINT tipo, ' CONTADO'
		ELSE
			--#IF rm_rep.r19_cont_cred = 'T' THEN
				PRINT 'T O D O S'
			--#END IF
		END IF
	END IF
	PRINT COLUMN 01, "FECHA IMPRESION: ", vg_fecha USING "dd-mm-yyyy",
		1 SPACES, TIME,
	      COLUMN 128, usuario
	SKIP 1 LINES
	--print '&k2S'	                -- Letra condensada (16 cpi)
	PRINT "--------------------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 01,  "FECHA",
	      COLUMN 12,  "TP",
	      COLUMN 15,  "FACTURA INTERNA",
	      COLUMN 31,  "FACTURA SRI",
	      COLUMN 48,  "CLIENTE",
	      COLUMN 76,  "   VALOR BRUTO",
	      COLUMN 91,  " VALOR DSCTO.",
	      COLUMN 105, "    VALOR IVA",
	      COLUMN 119, "  VALOR FLETE",
	      COLUMN 133, "    VALOR NETO"
	PRINT "--------------------------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 3 LINES
	LET fecha   = DATE(r_rep.r19_fecing)
	LET factura = r_rep.r19_num_tran
	INITIALIZE r_r19.*, r_r38.* TO NULL
	CALL fl_lee_cabecera_transaccion_rep(vg_codcia, vg_codloc,
		  			r_rep.r19_cod_tran, r_rep.r19_num_tran)
		RETURNING r_r19.*
	LET cod_tran = r_rep.r19_cod_tran
	LET num_tran = r_rep.r19_num_tran
	IF r_r19.r19_tipo_dev = 'FA' THEN
		LET cod_tran = r_r19.r19_tipo_dev
		LET num_tran = r_r19.r19_num_dev
	END IF
	SELECT * INTO r_r38.* FROM rept038
		WHERE r38_compania    = vg_codcia
		  AND r38_localidad   = vg_codloc
		  AND r38_tipo_doc    IN ("FA", "NV")
		  AND r38_tipo_fuente = 'PR'
		  AND r38_cod_tran    = cod_tran
		  AND r38_num_tran    = num_tran
	IF STATUS = NOTFOUND THEN
		SELECT * INTO r_r38.* FROM rept038
			WHERE r38_compania    = vg_codcia
			  AND r38_localidad   = vg_codloc
			  AND r38_tipo_doc    IN ("FA", "NV")
			  AND r38_tipo_fuente = 'OT'
			  AND r38_cod_tran    = cod_tran
			  AND r38_num_tran    = num_tran
	END IF
	PRINT COLUMN 01,  fecha USING "dd-mm-yyyy",
	      COLUMN 12,  r_rep.r19_cod_tran,
	      COLUMN 15,  factura,
	      COLUMN 31,  r_r38.r38_num_sri,
	      COLUMN 48,  r_rep.r19_nomcli[1,27],
	      COLUMN 76,  r_rep.r19_tot_bruto USING "---,---,--&.##",
	      COLUMN 91,  r_rep.r19_tot_dscto USING "--,---,--&.##",
	      COLUMN 105, valor_iva           USING "--,---,--&.##",
	      COLUMN 119, r_rep.r19_flete     USING "--,---,--&.##",
	      COLUMN 133, r_rep.r19_tot_neto  USING "---,---,--&.##"
	
ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 76,  "--------------",
	      COLUMN 91,  "-------------",
	      COLUMN 105, "-------------",
	      COLUMN 119, "-------------",
	      COLUMN 133, "--------------"
	PRINT COLUMN 63, "TOTALES ==>  ",
	      COLUMN 76,  total_bru USING "---,---,--&.##",
	      COLUMN 91,  total_des USING "--,---,--&.##",
	      COLUMN 105, total_iva USING "--,---,--&.##",
	      COLUMN 119, total_fle USING "--,---,--&.##",
	      COLUMN 133, total_net USING "---,---,--&.##";
	print ASCII escape;
	print ASCII desact_comp;
	print ASCII escape;
	print ASCII act_10cpi

END REPORT



FUNCTION borrar_cabecera()

CLEAR r19_moneda, tit_moneda, vm_fecha_ini, vm_fecha_fin
INITIALIZE rm_rep.*, vm_fecha_ini, vm_fecha_fin TO NULL

END FUNCTION



FUNCTION llamar_visor_teclas()
DEFINE a		CHAR(1)

IF vg_gui = 0 THEN
	CALL fl_visor_teclas_caracter() RETURNING int_flag 
	LET a = fgl_getkey()
	CLOSE WINDOW w_tf
	LET int_flag = 0
END IF

END FUNCTION



FUNCTION muestra_contcred(contcred)
DEFINE contcred		CHAR(1)

CASE contcred
	WHEN 'C'
		DISPLAY 'CONTADO' TO tit_cont_cred
	WHEN 'R'
		DISPLAY 'CREDITO' TO tit_cont_cred
	WHEN 'T'
		DISPLAY 'TODOS' TO tit_cont_cred
	OTHERWISE
		CLEAR r19_cont_cred, tit_cont_cred
END CASE

END FUNCTION
