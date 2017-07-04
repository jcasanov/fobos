--------------------------------------------------------------------------------
-- Titulo           : talp412.4gl - Reporte de Orden de Trabajo
-- Elaboracion      : 04-Jul-2003
-- Autor            : NPC
-- Formato Ejecucion: fglrun talp412 base modulo compañia localidad orden
-- Ultima Correccion: 
-- Motivo Correccion:
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_orden		LIKE talt023.t23_orden      
DEFINE rm_t23		RECORD LIKE talt023.*
DEFINE rm_t00		RECORD LIKE talt000.*
DEFINE rm_z01		RECORD LIKE cxct001.*
DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE rm_loc		RECORD LIKE gent002.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp412.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 5 THEN     -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vm_orden   = arg_val(5)
LET vg_proceso = 'talp412'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
INITIALIZE rm_t23.* TO NULL
CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc, vm_orden)
	RETURNING rm_t23.*
IF rm_t23.t23_compania IS NULL THEN	
	CALL fl_mostrar_mensaje('No existe Orden de Trabajo.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_cliente_general(rm_t23.t23_cod_cliente) RETURNING rm_z01.*
{--
IF rm_z01.z01_codcli IS NULL THEN	
	CALL fl_mostrar_mensaje('No existe codigo de Cliente.','stop')
	EXIT PROGRAM
END IF
--}
CALL fl_lee_configuracion_taller(vg_codcia) RETURNING rm_t00.*
IF rm_t00.t00_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe compañia de configuracion de taller.','stop')
	EXIT PROGRAM
END IF
CALL control_main_reporte()

END FUNCTION



FUNCTION control_main_reporte()
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
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rm_loc.*
IF rm_loc.g02_localidad IS NULL THEN
	CALL fl_mostrar_mensaje('No existe localidad.','stop')
	EXIT PROGRAM
END IF
START REPORT report_ot TO PIPE comando
OUTPUT TO REPORT report_ot()
FINISH REPORT report_ot

END FUNCTION



REPORT report_ot()
DEFINE r_r00		RECORD LIKE rept000.*
DEFINE r_t20		RECORD LIKE talt020.*
DEFINE r_t24		RECORD LIKE talt024.*
DEFINE num_lin		INTEGER
DEFINE documento	VARCHAR(60)
DEFINE usuario		VARCHAR(10,5)
DEFINE titulo		VARCHAR(80)
DEFINE long		SMALLINT
DEFINE subtotal		DECIMAL(14,2)
DEFINE impuesto		DECIMAL(14,2)
DEFINE valor_pag	DECIMAL(14,2)
DEFINE label_letras	VARCHAR(130)
DEFINE orden		VARCHAR(10)
DEFINE estado		VARCHAR(15)
DEFINE escape		SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	132
	BOTTOM MARGIN	3
	PAGE LENGTH	44

FORMAT

PAGE HEADER
	--print 'E';
	--print '&l26A';	-- Indica que voy a trabajar con hojas A4
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET subtotal    = rm_t23.t23_tot_bruto
	LET impuesto    = rm_t23.t23_val_impto
	LET valor_pag   = rm_t23.t23_tot_neto
	CALL fl_justifica_titulo('I', vg_usuario, 10) RETURNING usuario
--	print '&k2S' 		-- Letra condensada
	CALL fl_lee_presupuesto_taller(rm_t23.t23_compania,rm_t23.t23_localidad,
					rm_t23.t23_numpre)
		RETURNING r_t20.*
	LET orden  = rm_t23.t23_orden
	LET estado = muestra_estado()
	SKIP 2 LINES
	print ASCII escape;
	print ASCII act_comp
	IF rm_t23.t23_cod_cliente IS NOT NULL THEN
		PRINT COLUMN 01,  "CLIENTE (", rm_t23.t23_cod_cliente
						USING "&&&&&", ") : ",
						rm_z01.z01_nomcli[1,48] CLIPPED,
		      COLUMN 69,  "No. ORDEN TRABAJO: ", orden
		PRINT COLUMN 01,  "CEDULA/RUC      : ", rm_z01.z01_num_doc_id,
		      COLUMN 69,  "ESTADO ORDEN TRA.: ", rm_t23.t23_estado, " ",
							estado
		PRINT COLUMN 01,  "DIRECCION       : ", rm_z01.z01_direccion1,
		      COLUMN 69,  "FECHA ORDEN TRAB.: ", DATE(rm_t23.t23_fecing)
			 			USING "dd-mm-yyyy"
	ELSE
		PRINT COLUMN 01,  "CLIENTE         : ",
						rm_t23.t23_nom_cliente[1,48],
		      COLUMN 69,  "No. ORDEN TRABAJO: ", orden
		PRINT COLUMN 69,  "ESTADO ORDEN TRA.: ", rm_t23.t23_estado, " ",
							estado
		PRINT COLUMN 69,  "FECHA ORDEN TRAB.: ", DATE(rm_t23.t23_fecing)
			 			USING "dd-mm-yyyy"
	END IF
	PRINT COLUMN 01,  "TELEFONO        : ", rm_t23.t23_tel_cliente,
	      COLUMN 69,  "No. PRESUPUESTO  : ", rm_t23.t23_numpre
						USING "<<<<<<<<"
	PRINT COLUMN 01,  "DESCRIPCION OT  : ", rm_t23.t23_descripcion[1,46],
	      COLUMN 69,  "FECHA PRESUPUESTO: ", DATE(r_t20.t20_fecing)
						USING "dd-mm-yyyy"
	PRINT COLUMN 19,  rm_t23.t23_descripcion[47,92],
	      COLUMN 69,  "ALMACEN          : ", rm_loc.g02_nombre
	PRINT COLUMN 19,  rm_t23.t23_descripcion[93,120],
	      COLUMN 69,  "RUC              : ", rm_loc.g02_numruc
	PRINT COLUMN 01,  "OBSER. PRESUP.  : ", r_t20.t20_observaciones,
	      COLUMN 69,  "DIRECCION        : ", rm_loc.g02_direccion
	PRINT COLUMN 69,  "TELEFONO         : ", rm_loc.g02_telefono1, " ",
						 rm_loc.g02_telefono2
	PRINT COLUMN 01,  "FECHA IMPRESION : ", DATE(TODAY) USING 'dd-mm-yyyy',
		1 SPACES, TIME,
	      COLUMN 69,  "FAX              : ", rm_loc.g02_fax1, " ",
						 rm_loc.g02_fax2
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 11,  "DESCRIPCION",
	      COLUMN 121, "VALOR TOTAL"
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"
	SKIP 1 LINES

ON EVERY ROW
	NEED 1 LINES
	PRINT COLUMN 07,  "ESTA ORDEN DE TRABAJO ESTA SUJETA A VARIACION"
	{--
	SKIP 1 LINES
	PRINT COLUMN 11,  "SUBTOTAL DE PROFORMAS ",
				rm_cia.g01_razonsocial CLIPPED,
	      COLUMN 118, total_proformas		USING '###,###,##&.##'
	--}
	SKIP 1 LINES
	PRINT COLUMN 11,  "TOTAL SERVICIOS ", rm_cia.g01_razonsocial CLIPPED
	      --COLUMN 118, rm_t23.t23_total_mo		USING '###,###,##&.##'
	SELECT COUNT(*) INTO num_lin FROM talt024
		WHERE t24_compania  = vg_codcia
		  AND t24_localidad = vg_codloc
		  AND t24_orden     = rm_t23.t23_orden
	CALL fl_lee_compania_repuestos(vg_codcia) RETURNING r_r00.*
	IF num_lin <= ((r_r00.r00_numlin_fact * 2) - 5) THEN
		DECLARE q_talt024 CURSOR FOR
			SELECT * FROM talt024
				WHERE t24_compania  = vg_codcia
				  AND t24_localidad = vg_codloc
				  AND t24_orden     = rm_t23.t23_orden
				ORDER BY t24_secuencia
		FOREACH q_talt024 INTO r_t24.*
			PRINT COLUMN 13, "- - ", r_t24.t24_descripcion,
	      		      COLUMN 118, r_t24.t24_valor_tarea
						USING '###,###,##&.##'
		END FOREACH
	END IF
	SKIP 1 LINES
	PRINT COLUMN 11,  "TOTAL DE MATERIALES VARIOS Y OTROS (SIN IMPUESTOS)",
	      COLUMN 118, rm_t23.t23_val_otros1 + rm_t23.t23_val_otros2
			USING '###,###,##&.##'
	SKIP 1 LINES
	PRINT COLUMN 11,  "TOTAL DE MANO DE OBRA Y MATERIALES EXTERNOS",
	      COLUMN 118, rm_t23.t23_val_mo_ext + rm_t23.t23_val_mo_cti
			USING '###,###,##&.##'
	
PAGE TRAILER
	--NEED 4 LINES
	LET label_letras = fl_retorna_letras(rm_t23.t23_moneda, valor_pag)
	SKIP 2 LINES
	PRINT COLUMN 02,  "SOMOS CONTRIBUYENTES ESPECIALES D.G.R. # 39",
	      COLUMN 102, "SUBTOTAL",
	      COLUMN 118, subtotal		USING "###,###,##&.##"
	PRINT COLUMN 02,  "PRECIOS SUJETOS A CAMBIO SIN PREVIO AVISO",
	      COLUMN 60,  "-------------------------",
	      COLUMN 100, "DESCUENTOS",
      	      COLUMN 118, rm_t23.t23_tot_dscto	USING "###,###,##&.##"
	PRINT COLUMN 60,  "       ACEPTACION        ",
	      COLUMN 95,  "I. V. A. (", rg_gen.g00_porc_impto USING "#&", ") %",
	      COLUMN 118, impuesto		USING "###,###,##&.##"
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 02,  "SON: ", label_letras[1,87],
	      COLUMN 97,  "VALOR A PAGAR",
	      COLUMN 116, valor_pag		USING "#,###,###,##&.##"
	PRINT "------------------------------------------------------------------------------------------------------------------------------------";
	print ASCII escape;
	print ASCII desact_comp 

END REPORT



FUNCTION muestra_estado()

IF rm_t23.t23_estado = 'A' THEN
	RETURN 'ACTIVA'
END IF
IF rm_t23.t23_estado = 'C' THEN
	RETURN 'CERRADA'
END IF
IF rm_t23.t23_estado = 'F' THEN
	RETURN 'FACTURADA'
END IF
IF rm_t23.t23_estado = 'E' THEN
	RETURN 'ELIMINADA'
END IF
IF rm_t23.t23_estado = 'D' THEN
	RETURN 'DEVUELTA'
END IF

END FUNCTION
