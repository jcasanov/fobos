--------------------------------------------------------------------------------
-- Titulo              : srip206.4gl -- Generar Anexo Transaccional SRI
-- Elaboración         : 22-Dic-2017
-- Autor               : NPC
-- Formato de Ejecución: fglrun srip206 Base Modulo Compañía Localidad
--							año mes
-- Ultima Correción    : 
-- Motivo Corrección   : 
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_s00				RECORD LIKE srit000.*
DEFINE rm_par				RECORD
								anio_fin	SMALLINT,
								mes_fin		SMALLINT
							END RECORD
DEFINE vm_fecha_emi_vta		LIKE srit021.s21_fecha_emi_vta



MAIN

DEFER QUIT
DEFER INTERRUPT
LET vg_proceso = arg_val(0)
CALL startlog('../logs/' || vg_proceso CLIPPED || '.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 6 THEN
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')
     	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()
                                                                                
END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
INITIALIZE rm_par.* TO NULL
CALL fl_lee_configuracion_sri(vg_codcia) RETURNING rm_s00.*
IF rm_s00.s00_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configurada la compania de SRI.', 'stop')
	EXIT PROGRAM
END IF
LET rm_par.anio_fin = arg_val(5)
LET rm_par.mes_fin  = arg_val(6)
CALL control_generar_anexos()

END FUNCTION



FUNCTION control_generar_anexos()
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE codestablec	LIKE gent037.g37_pref_sucurs
DEFINE query		CHAR(800)
DEFINE registro		CHAR(4000)
DEFINE total_venta	DECIMAL(12,2)

LET vm_fecha_emi_vta = MDY(rm_par.mes_fin, 01, rm_par.anio_fin) + 1 UNITS MONTH
						- 1 UNITS DAY
CALL fl_lee_compania(vg_codcia) RETURNING r_g01.*
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING r_g02.*
DISPLAY '<?xml version="1.0" encoding="UTF-8"?>'
DISPLAY '<iva xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
DISPLAY '<TipoIDInformante>R</TipoIDInformante>'
DISPLAY '<IdInformante>', r_g02.g02_numruc CLIPPED, '</IdInformante>'
DISPLAY '<razonSocial>', r_g01.g01_razonsocial CLIPPED, '</razonSocial>'
DISPLAY '<Anio>', rm_par.anio_fin USING "&&&&", '</Anio>'
DISPLAY '<Mes>', rm_par.mes_fin USING "&&", '</Mes>'
LET query = 'SELECT NVL(SUM((s21_bas_imp_gr_iva + s21_base_imp_tar_0) * ',
				'CASE WHEN s21_tipo_comp = "04" ',
					'THEN -1 ',
					'ELSE 1 ',
				'END), 0) AS total_venta ',
		'FROM srit021 ',
		' WHERE s21_compania  = ', vg_codcia,
		'   AND s21_localidad = ', vg_codloc,
		'   AND s21_anio      = ', rm_par.anio_fin,
		'   AND s21_mes       = ', rm_par.mes_fin,
		' INTO TEMP tmp_vta '
PREPARE exec_tmp_vta FROM query
EXECUTE exec_tmp_vta
SELECT * INTO total_venta FROM tmp_vta
DROP TABLE tmp_vta
LET codestablec = NULL
SELECT g37_pref_sucurs
		INTO codestablec
		FROM gent037 b
		WHERE b.g37_compania  = vg_codcia
		  AND b.g37_localidad = vg_codloc
		  AND b.g37_tipo_doc  = "FA"
		  AND b.g37_secuencia =
			(SELECT MAX(a.g37_secuencia)
				FROM gent037 a
				WHERE a.g37_compania  = b.g37_compania
				  AND a.g37_localidad = b.g37_localidad
				  AND a.g37_tipo_doc  = b.g37_tipo_doc)
DISPLAY '<numEstabRuc>', codestablec, '</numEstabRuc>'
DISPLAY '<totalVentas>', total_venta USING "<<<<<<<<<<<&.&&", '</totalVentas>'
DISPLAY '<codigoOperativo>IVA</codigoOperativo>'
DISPLAY '<compras>'
CALL control_generar_anexo_compras()
DISPLAY '</compras>'
DISPLAY '<ventas>'
CALL control_generar_anexo_ventas(1)
CALL control_generar_anexo_ventas(2)
DISPLAY '</ventas>'
DISPLAY '<ventasEstablecimiento>'
DISPLAY '<ventaEst>'
DISPLAY '<codEstab>', codestablec, '</codEstab>'
DISPLAY '<ventasEstab>', total_venta USING "<<<<<<<<<<<&.&&", '</ventasEstab>'
DISPLAY '<ivaComp>0.00</ivaComp>'
DISPLAY '</ventaEst>'
DISPLAY '</ventasEstablecimiento>'
DISPLAY '<exportaciones>'
DISPLAY '</exportaciones>'
DISPLAY '<recap>'
DISPLAY '</recap>'
DISPLAY '<fideicomisos>'
DISPLAY '</fideicomisos>'
DISPLAY '<anulados>'
CALL control_generar_anexo_anulados()
DISPLAY '</anulados>'
DISPLAY '<rendFinancieros>'
DISPLAY '</rendFinancieros>'
DISPLAY '</iva>'
CALL fl_mostrar_mensaje('Anexo Transaccional Generado OK.', 'info')

END FUNCTION



FUNCTION control_generar_anexo_compras()
DEFINE fecha		DATE
DEFINE comando		VARCHAR(250)

LET comando = 'cd ..', vg_separador, '..', vg_separador, 'SRI', vg_separador,
				'fuentes', vg_separador, '; umask 0002; fglrun srip203 ',
				vg_base, ' "', vg_modulo, '" ', vg_codcia, ' ', vg_codloc, ' ',
				YEAR(vm_fecha_emi_vta), ' ', MONTH(vm_fecha_emi_vta), ' 1'
RUN comando

END FUNCTION



FUNCTION control_generar_anexo_ventas(flag)
DEFINE flag			SMALLINT
DEFINE fecha		DATE
DEFINE comando		VARCHAR(250)
DEFINE archivo		VARCHAR(30)
DEFINE param		VARCHAR(25)

CASE flag
	WHEN 1
		LET archivo = NULL
	WHEN 2
		LET param   = ' "U"'
		LET archivo = param CLIPPED
END CASE
LET fecha   = MDY(MONTH(vm_fecha_emi_vta), 01, YEAR(vm_fecha_emi_vta))
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'SRI', vg_separador,
				'fuentes', vg_separador, '; umask 0002; fglrun srip200 ',
				vg_base, ' "', vg_modulo, '" ', vg_codcia, ' ', vg_codloc, ' "',
				fecha, '" "', vm_fecha_emi_vta, '" ', archivo CLIPPED
RUN comando

END FUNCTION



FUNCTION control_generar_anexo_anulados()
DEFINE fecha		DATE
DEFINE comando		VARCHAR(250)

LET fecha   = MDY(MONTH(vm_fecha_emi_vta), 01, YEAR(vm_fecha_emi_vta))
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'SRI', vg_separador,
				'fuentes', vg_separador, '; umask 0002; fglrun srip202 ',
				vg_base, ' "', vg_modulo, '" ', vg_codcia, ' ', vg_codloc, ' "',
				fecha, '" "', vm_fecha_emi_vta, '" '
RUN comando

END FUNCTION
