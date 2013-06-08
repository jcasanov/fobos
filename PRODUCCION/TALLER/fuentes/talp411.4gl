--------------------------------------------------------------------------------
-- Titulo           : talp411.4gl - Comprobante de Presupuesto
-- Elaboracion      : 06-Mar-2003
-- Autor            : NPC
-- Formato Ejecucion: fglrun talp411 base modulo compañia localidad presupuesto
-- Ultima Correccion: 
-- Motivo Correccion:
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_presupuesto	LIKE talt020.t20_numpre      
DEFINE rm_t20		RECORD LIKE talt020.*
DEFINE rm_t00		RECORD LIKE talt000.*
DEFINE rm_z01		RECORD LIKE cxct001.*
DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE rm_loc		RECORD LIKE gent002.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp411.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 5 AND num_args() <> 6 THEN	-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base        = arg_val(1)
LET vg_modulo      = arg_val(2)
LET vg_codcia      = arg_val(3)
LET vg_codloc      = arg_val(4)
LET vm_presupuesto = arg_val(5)
LET vg_proceso     = 'talp411'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
INITIALIZE rm_t20.* TO NULL
CALL fl_lee_presupuesto_taller(vg_codcia, vg_codloc, vm_presupuesto)
	RETURNING rm_t20.*
IF rm_t20.t20_compania IS NULL THEN	
	CALL fl_mostrar_mensaje('No existe Presupuesto.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_cliente_general(rm_t20.t20_cod_cliente) RETURNING rm_z01.*
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
DEFINE archivo		VARCHAR(100)

IF num_args() <> 6 THEN
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		RETURN
	END IF
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
CASE num_args()
	WHEN 5
		START REPORT report_presupuesto TO PIPE comando
	WHEN 6
		LET archivo = 'presup_', rm_t20.t20_numpre USING "<<<<<<<&",
				'.wri'
		START REPORT report_presupuesto TO FILE archivo
END CASE
OUTPUT TO REPORT report_presupuesto()
FINISH REPORT report_presupuesto
IF num_args() = 6 THEN
	LET comando = 'mv ', archivo CLIPPED, ' /acero/fobos/tmp'
	RUN comando
END IF

END FUNCTION



REPORT report_presupuesto()
DEFINE r_r00		RECORD LIKE rept000.*
DEFINE r_t21		RECORD LIKE talt021.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE num_lin		INTEGER
DEFINE documento	VARCHAR(60)
DEFINE usuario		VARCHAR(10,5)
DEFINE titulo		VARCHAR(80)
DEFINE long		SMALLINT
DEFINE total_bruto	DECIMAL(14,2)
DEFINE subtotal		DECIMAL(14,2)
DEFINE impuesto		DECIMAL(14,2)
DEFINE valor_pag	DECIMAL(14,2)
DEFINE label_letras	VARCHAR(130)
DEFINE numpre		VARCHAR(10)
DEFINE estado		VARCHAR(8)
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
	LET total_bruto = rm_t20.t20_total_mo + rm_t20.t20_total_rp +
				rm_t20.t20_mano_ext
	LET subtotal    = total_bruto - rm_t20.t20_vde_mo_tal
	LET impuesto    = rm_t20.t20_total_impto
	LET valor_pag   = rm_t20.t20_total_neto
	CALL fl_justifica_titulo('I', vg_usuario, 10) RETURNING usuario
--	print '&k2S' 		-- Letra condensada
	SELECT * INTO r_t23.* FROM talt023
		WHERE t23_compania  = vg_codcia
		  AND t23_localidad = vg_codloc
		  AND t23_numpre    = rm_t20.t20_numpre
		  AND t23_estado <> 'D'
	LET numpre = rm_t20.t20_numpre
	LET estado = muestra_estado()
	--SKIP 2 LINES
	print ASCII escape;
	print ASCII act_comp
	IF rm_t20.t20_cod_cliente IS NOT NULL THEN
		PRINT COLUMN 01,  "CLIENTE (", rm_t20.t20_cod_cliente
						USING "&&&&&", ") : ",
						rm_z01.z01_nomcli[1,48] CLIPPED,
		      COLUMN 69,  "No. PRESUPUESTO  : ", numpre
		PRINT COLUMN 01,  "CEDULA/RUC      : ", rm_z01.z01_num_doc_id,
		      COLUMN 69,  "ESTADO PRESUP.   : ", rm_t20.t20_estado, " ",
							estado
	ELSE
		PRINT COLUMN 01,  "CLIENTE         : ",
						rm_t20.t20_nom_cliente[1,48],
		      COLUMN 69,  "No. PRESUPUESTO  : ", numpre
		PRINT COLUMN 69,  "ESTADO PRESUP.   : ", rm_t20.t20_estado, " ",
							estado
	END IF
	PRINT COLUMN 01,  "DIRECCION       : ", rm_t20.t20_dir_cliente,
	      COLUMN 69,  "FECHA PRESUPUESTO: ", DATE(rm_t20.t20_fecing) 
			 			USING "dd-mm-yyyy"
	PRINT COLUMN 01,  "TELEFONO        : ", rm_t20.t20_tel_cliente,
	      COLUMN 69,  "No. ORDEN TRABAJO: ", r_t23.t23_orden
						USING "&&&&&&&"
	PRINT COLUMN 01,  "MOTIVO PRESUP.  : ", rm_t20.t20_motivo[1,46],
	      COLUMN 69,  "USUARIO QUE APR. : ", rm_t20.t20_user_aprob
	PRINT COLUMN 19,  rm_t20.t20_motivo[47,92],
	      COLUMN 69,  "FECHA APROBACION : ", DATE(rm_t20.t20_fecha_aprob)
						USING "dd-mm-yyyy"
	PRINT COLUMN 19,  rm_t20.t20_motivo[93,120],
	      COLUMN 69,  "ALMACEN          : ", rm_loc.g02_nombre
	PRINT COLUMN 01,  "OBSERVACIONES   : ", rm_t20.t20_observaciones,
	      COLUMN 69,  "RUC              : ", rm_loc.g02_numruc
	PRINT COLUMN 69,  "DIRECCION        : ", rm_loc.g02_direccion
	PRINT COLUMN 69,  "TELEFONO         : ", rm_loc.g02_telefono1, " ",
						 rm_loc.g02_telefono2
	PRINT COLUMN 01,  "FECHA IMPRESION : ", DATE(TODAY) USING 'dd-mm-yyyy',
		1 SPACES, TIME,
	      COLUMN 69,  "FAX              : ", rm_loc.g02_fax1, " ",
						 rm_loc.g02_fax2
	--SKIP 1 LINES
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 11,  "DESCRIPCION",
	      COLUMN 121, "VALOR TOTAL"
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"
	--SKIP 1 LINES

ON EVERY ROW
	NEED 1 LINES
	PRINT COLUMN 07,  "ESTE PRESUPUESTO ESTA SUJETO A VARIACION"
	SKIP 1 LINES
	PRINT COLUMN 11,  "SUBTOTAL DE PROFORMAS ",
				rm_cia.g01_razonsocial CLIPPED,
	      COLUMN 118, rm_t20.t20_total_rp		USING '###,###,##&.##'
	SKIP 1 LINES
	PRINT COLUMN 11,  "TOTAL SERVICIOS ", rm_cia.g01_razonsocial CLIPPED
	      --COLUMN 118, rm_t20.t20_total_mo		USING '###,###,##&.##'
	SELECT COUNT(*) INTO num_lin FROM talt021
		WHERE t21_compania  = vg_codcia
		  AND t21_localidad = vg_codloc
		  AND t21_numpre    = rm_t20.t20_numpre
	CALL fl_lee_compania_repuestos(vg_codcia) RETURNING r_r00.*
	IF num_lin <= ((r_r00.r00_numlin_fact * 2) - 5) THEN
		DECLARE q_talt021 CURSOR FOR
			SELECT * FROM talt021
				WHERE t21_compania  = vg_codcia
				  AND t21_localidad = vg_codloc
				  AND t21_numpre    = rm_t20.t20_numpre
				ORDER BY t21_secuencia
		FOREACH q_talt021 INTO r_t21.*
			PRINT COLUMN 13, "- - ", r_t21.t21_descripcion,
	      		      COLUMN 118, r_t21.t21_valor USING '###,###,##&.##'
		END FOREACH
	END IF
	SKIP 1 LINES
	PRINT COLUMN 11,  "TOTAL DE MATERIALES Y MANO DE OBRA EXTERNOS",
	      COLUMN 118, rm_t20.t20_mano_ext		USING '###,###,##&.##'
	
PAGE TRAILER
	--NEED 4 LINES
	LET label_letras = fl_retorna_letras(rm_t20.t20_moneda, valor_pag)
	IF impuesto = 0 THEN
		LET rg_gen.g00_porc_impto = 0
	END IF
	SKIP 1 LINES
	PRINT COLUMN 099, "TOTAL BRUTO",
	      COLUMN 118, total_bruto		USING "###,###,##&.##"
	PRINT COLUMN 02,  "SOMOS CONTRIBUYENTES ESPECIALES S.R.I. # 39",
	      COLUMN 92,  "DESC. M.O. INTERNA",
	      COLUMN 119, rm_t20.t20_vde_mo_tal		USING "##,###,##&.##"
	PRINT COLUMN 02,  "PRECIOS SUJETOS A CAMBIO SIN PREVIO AVISO",
	      COLUMN 60,  "-------------------------",
	      COLUMN 102, "SUBTOTAL",
	      COLUMN 118, subtotal		USING "###,###,##&.##"
	--SKIP 1 LINES
	PRINT COLUMN 60,  "       ACEPTACION        ",
	      COLUMN 95,  "I. V. A. (", rg_gen.g00_porc_impto USING "#&", ") %",
	      COLUMN 118, impuesto		USING "###,###,##&.##"
	PRINT COLUMN 02,  "MATERIALES SUJETOS A CAMBIOS SEGUN INSTALACION",
	      COLUMN 93,  "MATERIALES VARIOS",
      	      COLUMN 118, rm_t20.t20_otros_mat	USING "###,###,##&.##"
	PRINT COLUMN 81,  "GASTOS DE DIETAS Y TRANSPORTE",
	      COLUMN 118, rm_t20.t20_gastos	USING "###,###,##&.##"
	--PRINT COLUMN 116, "----------------"
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 02,  "SON: ", label_letras[1,87],
	      COLUMN 97,  "VALOR A PAGAR",
	      COLUMN 116, valor_pag		USING "#,###,###,##&.##"
	PRINT "------------------------------------------------------------------------------------------------------------------------------------";
	print ASCII escape;
	print ASCII desact_comp 

END REPORT



FUNCTION muestra_estado()

IF rm_t20.t20_estado = 'A' THEN
	RETURN 'ACTIVO'
ELSE
	RETURN 'APROBADO'
END IF

END FUNCTION
