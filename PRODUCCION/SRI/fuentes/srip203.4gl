--------------------------------------------------------------------------------
-- Titulo              : srip203.4gl -- Mantenimiento anexo de compras
-- Elaboraci�n         : 02-Jun-2007
-- Autor               : NPC
-- Formato de Ejecuci�n: fglrun srip203 Base Modulo Compa��a Localidad
--			[anio] [mes] [orden]
-- Ultima Correci�n    : 
-- Motivo Correcci�n   : 
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE num_ret_ant	LIKE cxpt028.p28_num_ret
DEFINE anio, mes	SMALLINT
DEFINE orden		SMALLINT
DEFINE num_row		SMALLINT
DEFINE max_row		SMALLINT
DEFINE long_dig		SMALLINT



MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/srip203.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 7 AND num_args() <> 8 THEN
	CALL fl_mostrar_mensaje('N�mero de parametros incorrecto.','stop')
     	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'srip203'
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
LET anio     = arg_val(5)
LET mes      = arg_val(6)
LET orden    = arg_val(7)
LET long_dig = 8 + 9		-- PONER UNA TABLA DE CONFIGURACION
CALL ejecuta_proceso()

END FUNCTION



FUNCTION ejecuta_proceso()
DEFINE r_doc		RECORD
				num_ret		CHAR(12),
				modulo		CHAR(2),
				sustento	LIKE srit023.s23_sustento_sri,
				idtipo		CHAR(2),
				idprov		LIKE cxpt001.p01_num_doc,
				tc		CHAR(1),
				estableci	CHAR(3),
				pemision	CHAR(3),
				--secuencia	CHAR(10),
				secuencia	LIKE cxpt020.p20_num_doc,
				aut		LIKE ordt013.c13_num_aut,
				fecha_reg	CHAR(10),
				fecha_emi	CHAR(10),
				fecha_cad	CHAR(10),
				base_sin	VARCHAR(15),
				base_con	VARCHAR(15),
				base_ice	VARCHAR(15),
				porc_iva	VARCHAR(1),
				porc_ice	VARCHAR(5,2),
				monto_iva	VARCHAR(18),
				monto_ice	VARCHAR(18),
				bienesBase	VARCHAR(40),
				bienesPorc	VARCHAR(40),
				bienesValor	VARCHAR(40),
				serviciosBase	VARCHAR(40),
				serviciosPorc	VARCHAR(40),
				serviciosValor	VARCHAR(40),
				nom_mes		CHAR(3),
				anio_reg	SMALLINT,
				usuario		LIKE ordt010.c10_usuario
			END RECORD
DEFINE r_adi		RECORD
				proveedor	LIKE cxpt020.p20_codprov,
				nomprov		LIKE cxpt001.p01_nomprov,
				tipo		LIKE cxpt020.p20_tipo_doc,
				numero		LIKE cxpt020.p20_num_doc
				--divid		LIKE cxpt020.p20_dividendo
			END RECORD
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE fecha		DATETIME YEAR TO MONTH
DEFINE registro		CHAR(10100)
DEFINE query		CHAR(21000)

LET fecha = EXTEND(MDY(mes, 01, anio), YEAR TO MONTH)
LET query = 'SELECT NVL((SELECT UNIQUE p28_num_ret ',
			'FROM cxpt028, cxpt027 ',
			'WHERE p27_estado    = "A" ',
			'  AND p27_compania  = p28_compania ',
			'  AND p27_localidad = p28_localidad ',
			'  AND p27_num_ret   = p28_num_ret ',
			'  AND p28_compania  = p20_compania ',
			'  AND p28_localidad = p20_localidad ',
			'  AND p28_tipo_doc  = p20_tipo_doc ',
			'  AND p28_num_doc   = p20_num_doc ',
			'  AND p28_codprov   = p20_codprov ',
			'  AND p28_dividendo = p20_dividendo), "NR") sec, ',
		'"CO" modulo, c10_cod_sust_sri sustento, ',
		'(SELECT s18_sec_tran ',
			'FROM srit018 ',
			'WHERE s18_compania  = c10_compania ',
			'  AND s18_tipo_tran = 1 ',
			'  AND s18_cod_ident = p01_tipo_doc) idtipo, ',
		'p01_num_doc idprov, ',
		'(SELECT s19_tipo_comp ',
			'FROM srit018, srit019 ',
			'WHERE s18_compania  = c10_compania ',
			'  AND s18_tipo_tran = 1 ',
			'  AND s18_cod_ident = p01_tipo_doc ',
			'  AND s19_cod_ident = s18_cod_ident ',
			'  AND s19_tipo_doc  = "FA" ',
			'  AND s19_sec_tran  = s18_sec_tran) tc, ',
		'c10_factura[1,3] establecimiento, ',
		'c10_factura[5,7] pemision, ',
		'CASE WHEN p20_codprov IN (477, 1057) ',
			'THEN c10_factura[11,', long_dig, '] ',
			'ELSE c10_factura[9,', long_dig, '] ',
		'END secuencia, ',
		'c13_num_aut aut, ',
		'TO_CHAR(c13_fecha_recep, "%d/%m/%Y") fecha_reg, ', 
		'TO_CHAR(c13_fecha_recep, "%d/%m/%Y") fecha_emi, ',
		'TO_CHAR(TODAY,"%m/%Y") fecha_cad, ',
		'CASE WHEN c10_tot_impto = 0 ',
			'THEN c10_tot_compra ',
			'ELSE c10_flete ',
		'END base_sin, ',
		'CASE WHEN c10_tot_impto > 0 ',
			'THEN (c10_tot_compra - c10_tot_impto - c10_flete) ',
			'ELSE 0 ',
		'END base_con, ',
		'0 base_ice, ',
		'NVL((SELECT UNIQUE ',
				'CASE WHEN s08_codigo = 0 ',
					'THEN 2 ',
					'ELSE s08_codigo ',
				'END s08_codigo ',
			'FROM srit008 ',
			'WHERE s08_compania   = c10_compania ',
			'  AND s08_porcentaje = c10_porc_impto), 2) iva, ',
		'"0" ice, c10_tot_impto monto_iva, "0.00" monto_ice, ',
		'NVL((SELECT p28_valor_base ',
			'FROM cxpt028, cxpt027, ordt002 ',
			'WHERE p27_estado      = "A" ',
			'  AND p28_tipo_ret    = "I" ',
			'  AND c02_tipo_fuente = "B" ',
			'  AND p27_compania    = p28_compania ',
			'  AND p27_localidad   = p28_localidad ',
			'  AND p27_num_ret     = p28_num_ret ',
			'  AND p28_compania    = p20_compania ',
			'  AND p28_localidad   = p20_localidad ',
			'  AND p28_tipo_doc    = p20_tipo_doc ',
			'  AND p28_num_doc     = p20_num_doc ',
			'  AND p28_codprov     = p20_codprov ',
			'  AND p28_dividendo   = p20_dividendo ',
			'  AND c02_compania    = p28_compania ',
			'  AND c02_tipo_ret    = p28_tipo_ret ',
			'  AND c02_porcentaje  = p28_porcentaje), ',
			'NVL((SELECT UNIQUE 0 ',
				'FROM cxpt028, cxpt027 ',
				'WHERE p27_estado    = "A" ',
				'  AND p28_tipo_ret  = "I" ',
				'  AND p27_compania  = p28_compania ',
				'  AND p27_localidad = p28_localidad ',
				'  AND p27_num_ret   = p28_num_ret ',
				'  AND p28_compania  = p20_compania ',
				'  AND p28_localidad = p20_localidad ',
				'  AND p28_tipo_doc  = p20_tipo_doc ',
				'  AND p28_num_doc   = p20_num_doc ',
				'  AND p28_codprov   = p20_codprov ',
				'  AND p28_dividendo = p20_dividendo), ',
			'CASE WHEN c01_bien_serv IN ("B","T") ',
				'THEN c10_tot_impto ',	
				'ELSE 0.00 ',
			'END)) bienesBase, ',
			'NVL((SELECT s09_codigo ',
				'FROM cxpt028, cxpt027, ordt002, srit009 ',
				'WHERE p27_estado      = "A" ',
				'  AND p28_tipo_ret    = "I" ',
				'  AND c02_tipo_fuente = "B" ',
				'  AND p27_compania    = p28_compania ',
				'  AND p27_localidad   = p28_localidad ',
				'  AND p27_num_ret     = p28_num_ret ',
				'  AND p28_compania    = p20_compania ',
				'  AND p28_localidad   = p20_localidad ',
				'  AND p28_tipo_doc    = p20_tipo_doc ',
				'  AND p28_num_doc     = p20_num_doc ',
				'  AND p28_codprov     = p20_codprov ',
				'  AND p28_dividendo   = p20_dividendo ',
				'  AND c02_compania    = p28_compania ',
				'  AND c02_tipo_ret    = p28_tipo_ret ',
				'  AND c02_porcentaje  = p28_porcentaje ',
				'  AND s09_compania    = c02_compania ',
				'  AND s09_tipo_porc   = c02_tipo_fuente ',
				'  AND REPLACE(s09_descripcion, "/", "") = ',
				'c02_porcentaje), 0) bienesPorcentaje, ',
			'NVL((SELECT p28_valor_ret ',
				'FROM cxpt028, cxpt027, ordt002 ',
				'WHERE p27_estado      = "A" ',
				'  AND p28_tipo_ret    = "I" ',
				'  AND c02_tipo_fuente = "B" ',
				'  AND p27_compania    = p28_compania ',
				'  AND p27_localidad   = p28_localidad ',
				'  AND p27_num_ret     = p28_num_ret ',
				'  AND p28_compania    = p20_compania ',
				'  AND p28_localidad   = p20_localidad ',
				'  AND p28_tipo_doc    = p20_tipo_doc ',
				'  AND p28_num_doc     = p20_num_doc ',
				'  AND p28_codprov     = p20_codprov ',
				'  AND p28_dividendo   = p20_dividendo ',
				'  AND c02_compania    = p28_compania ',
				'  AND c02_tipo_ret    = p28_tipo_ret ',
				'  AND c02_porcentaje  = p28_porcentaje), ',
		'0) bienesValor, ',
		'NVL((SELECT p28_valor_base ',
			'FROM cxpt028, cxpt027, ordt002 ',
			'WHERE p27_estado      = "A" ',
                        '  AND p28_tipo_ret    = "I" ',
                        '  AND c02_tipo_fuente IN ("S","T") ',
                        '  AND p27_compania    = p28_compania ',
                        '  AND p27_localidad   = p28_localidad ',
                        '  AND p27_num_ret     = p28_num_ret ',
                        '  AND p28_compania    = p20_compania ',
                        '  AND p28_localidad   = p20_localidad ',
                        '  AND p28_tipo_doc    = p20_tipo_doc ',
                        '  AND p28_num_doc     = p20_num_doc ',
                        '  AND p28_codprov     = p20_codprov ',
                        '  AND p28_dividendo   = p20_dividendo ',
                        '  AND c02_compania    = p28_compania ',
                        '  AND c02_tipo_ret    = p28_tipo_ret ',
                        '  AND c02_porcentaje  = p28_porcentaje), ',
                        'NVL((SELECT UNIQUE 0 ',
				'FROM cxpt028, cxpt027 ',
				'WHERE p27_estado    = "A" ',
				'  AND p28_tipo_ret  = "I" ',
				'  AND p27_compania  = p28_compania ',
				'  AND p27_localidad = p28_localidad ',
				'  AND p27_num_ret   = p28_num_ret ',
				'  AND p28_compania  = p20_compania ',
				'  AND p28_localidad = p20_localidad ',
				'  AND p28_tipo_doc  = p20_tipo_doc ',
				'  AND p28_num_doc   = p20_num_doc ',
				'  AND p28_codprov   = p20_codprov ',
				'  AND p28_dividendo = p20_dividendo), ',
			'CASE WHEN c01_bien_serv = "S" ',
				'THEN c10_tot_impto ',
				'ELSE 0.00 ',
			'END)) serviciosBase, ',
		'NVL((SELECT s09_codigo ',
			'FROM cxpt028, cxpt027, ordt002, srit009 ',
			'WHERE p27_estado      = "A" ',
			'  AND p28_tipo_ret    = "I" ',
                        '  AND c02_tipo_fuente IN ("S","T") ',
                        '  AND p27_compania    = p28_compania ',
                        '  AND p27_localidad   = p28_localidad ',
                        '  AND p27_num_ret     = p28_num_ret ',
                        '  AND p28_compania    = p20_compania ',
                        '  AND p28_localidad   = p20_localidad ',
                        '  AND p28_tipo_doc    = p20_tipo_doc ',
                        '  AND p28_num_doc     = p20_num_doc ',
                        '  AND p28_codprov     = p20_codprov ',
                        '  AND p28_dividendo   = p20_dividendo ',
                        '  AND c02_compania    = p28_compania ',
                        '  AND c02_tipo_ret    = p28_tipo_ret ',
                        '  AND c02_porcentaje  = p28_porcentaje ',
                        '  AND s09_compania    = c02_compania ',
                        '  AND s09_tipo_porc   = c02_tipo_fuente ',
                        '  AND REPLACE(s09_descripcion,"/","") = ',
				'c02_porcentaje), 0) serviciosPorc, ',
			'NVL((SELECT p28_valor_ret ',
				'FROM cxpt028, cxpt027, ordt002 ',
				'WHERE p27_estado      = "A" ',
				'  AND p28_tipo_ret    = "I" ',
				'  AND c02_tipo_fuente IN ("S","T") ',
	                        '  AND p27_compania    = p28_compania ',
        	                '  AND p27_localidad   = p28_localidad ',
                	        '  AND p27_num_ret     = p28_num_ret ',
	                        '  AND p28_compania    = p20_compania ',
        	                '  AND p28_localidad   = p20_localidad ',
                	        '  AND p28_tipo_doc    = p20_tipo_doc ',
                        	'  AND p28_num_doc     = p20_num_doc ',
	                        '  AND p28_codprov     = p20_codprov ',
        	                '  AND p28_dividendo   = p20_dividendo ',
	                        '  AND c02_compania    = p28_compania ',
	                        '  AND c02_tipo_ret    = p28_tipo_ret ',
	                        '  AND c02_porcentaje  = p28_porcentaje), ',
			'0) serviciosValor, ',
		'CASE    WHEN MONTH(c10_fecing) = 01 THEN "ENE" ',
			'WHEN MONTH(c10_fecing) = 02 THEN "FEB" ',
			'WHEN MONTH(c10_fecing) = 03 THEN "MAR" ',
			'WHEN MONTH(c10_fecing) = 04 THEN "ABR" ',
			'WHEN MONTH(c10_fecing) = 05 THEN "MAY" ',
			'WHEN MONTH(c10_fecing) = 06 THEN "JUN" ',
			'WHEN MONTH(c10_fecing) = 07 THEN "JUL" ',
			'WHEN MONTH(c10_fecing) = 08 THEN "AGO" ',
			'WHEN MONTH(c10_fecing) = 09 THEN "SEP" ',
			'WHEN MONTH(c10_fecing) = 10 THEN "OCT" ',
			'WHEN MONTH(c10_fecing) = 11 THEN "NOV" ',
			'WHEN MONTH(c10_fecing) = 12 THEN "DIC" ',
		'END mes, ',
		'YEAR(c10_fecing) anio, c10_usuario usuario, p20_codprov, ',
		'REPLACE(REPLACE(REPLACE(p01_nomprov, "&", "&amp;"), ',
				' "�","&#209;"), "�","&#241;") nomprov, ',
		'p20_tipo_doc, p20_num_doc, p20_dividendo ',
	'FROM ordt010, cxpt001, ordt001, ordt013, cxpt020 ',
	'WHERE c10_compania   = ', vg_codcia,
	'  AND c10_estado     = "C" ',
	'  AND c13_estado     = "A" ',
	'  AND c10_tipo_orden = c01_tipo_orden ',
	'  AND c10_compania   = c13_compania ',
	'  AND c10_localidad  = c13_localidad ',
	'  AND c10_numero_oc  = c13_numero_oc ',
	--'  and c10_factura    = "001-001-0202903"',
	'  AND c10_compania   = p20_compania ',
	'  AND c10_localidad  = p20_localidad ',
	'  AND c10_numero_oc  = p20_numero_oc ',
	'  AND c10_factura    = p20_num_doc ',		-- Agregado por NPC
	'  AND EXTEND(c13_fecha_recep, YEAR TO MONTH) = "', fecha, '"',
	'  AND p01_codprov    = c10_codprov ',
	' UNION ',
	' SELECT NVL((SELECT UNIQUE p28_num_ret ',
			'FROM cxpt028, cxpt027 ',
			'WHERE p27_estado    = "A" ',
			'  AND p27_compania  = p28_compania ',
			'  AND p27_localidad = p28_localidad ',
			'  AND p27_num_ret   = p28_num_ret ',
			'  AND p28_compania  = p20_compania ',
			'  AND p28_localidad = p20_localidad ',
			'  AND p28_tipo_doc  = p20_tipo_doc ',
			'  AND p28_num_doc   = p20_num_doc ',
			'  AND p28_codprov   = p20_codprov ',
			'  AND p28_dividendo = p20_dividendo), "NR") sec, ',
		'"TE" modulo, "01" sustento, ',
		'(SELECT s18_sec_tran ',
			'FROM srit018 ',
			'WHERE s18_compania  = p20_compania ',
			'  AND s18_tipo_tran = 1 ',
			'  AND s18_cod_ident = p01_tipo_doc) idtipo, ',
		'p01_num_doc idprov, ',
		'(SELECT s19_tipo_comp ',
			'FROM srit018, srit019 ',
			'WHERE s18_compania  = p20_compania ',
			'  AND s18_tipo_tran = 1 ',
			'  AND s18_cod_ident = p01_tipo_doc ',
			'  AND s19_cod_ident = s18_cod_ident ',
			'  AND s19_tipo_doc  = "FA" ',
			'  AND s19_sec_tran  = s18_sec_tran) tc, ',
		'p20_num_doc[1,3] establecimiento, p20_num_doc[5,7] pemision, ',
		'CASE WHEN p20_codprov IN (477, 1057) ',
			'THEN p20_num_doc[11,', long_dig, '] ',
			'ELSE p20_num_doc[9,', long_dig, '] ',
		'END secuencia, ',
		'"1109999999" aut, ',
		'TO_CHAR(p20_fecha_emi, "%d/%m/%Y") fecha_reg, ',
		'TO_CHAR(p20_fecha_emi, "%d/%m/%Y") fecha_emi,',
		'TO_CHAR(TODAY,"%m/%Y") fecha_cad, ',
		{--
		'CASE WHEN p20_valor_impto = 0 THEN p20_valor_fact ELSE 0 END ',
		'base_sin, CASE WHEN p20_valor_impto > 0 THEN ',
		'(p20_valor_fact - p20_valor_impto) ELSE 0 END base_con, ',
		--}
		'0 base_sin, p20_valor_fact base_con, 0 base_ice, ',
		'NVL((SELECT UNIQUE CASE WHEN s08_codigo = 0 ',
						'THEN 2 ',
						'ELSE s08_codigo ',
					'END s08_codigo ',
			'FROM srit008 ',
			'WHERE s08_compania   = p20_compania ',
			'  AND s08_porcentaje = p20_porc_impto), 2) iva, ',
		'"0" ice, p20_valor_impto monto_iva, ',
		'"0.00" monto_ice, ',
		'NVL((SELECT p28_valor_base ',
			'FROM cxpt028, cxpt027, ordt002 ',
			'WHERE p27_estado      = "A" ',
			'  AND p28_tipo_ret    = "I" ',
			'  AND c02_tipo_fuente = "B" ',
			'  AND p27_compania    = p28_compania ',
			'  AND p27_localidad   = p28_localidad ',
			'  AND p27_num_ret     = p28_num_ret ',
			'  AND p28_compania    = p20_compania ',
			'  AND p28_localidad   = p20_localidad ',
			'  AND p28_tipo_doc    = p20_tipo_doc ',
			'  AND p28_num_doc     = p20_num_doc ',
			'  AND p28_codprov     = p20_codprov ',
			'  AND p28_dividendo   = p20_dividendo ',
			'  AND c02_compania    = p28_compania ',
			'  AND c02_tipo_ret    = p28_tipo_ret ',
			'  AND c02_porcentaje  = p28_porcentaje), ',
		'0) bienesBase, ',
                'NVL((SELECT s09_codigo ',
                        ' FROM cxpt028, cxpt027, ordt002, srit009 ',
                        ' WHERE p27_estado      = "A" ',
                        '   AND p28_tipo_ret    = "I" ',
                        '   AND c02_tipo_fuente = "B" ',
                        '   AND p27_compania    = p28_compania ',
                        '   AND p27_localidad   = p28_localidad ',
                        '   AND p27_num_ret     = p28_num_ret ',
                        '   AND p28_compania    = p20_compania ',
                        '   AND p28_localidad   = p20_localidad ',
                        '   AND p28_tipo_doc    = p20_tipo_doc ',
                        '   AND p28_num_doc     = p20_num_doc ',
                        '   AND p28_codprov     = p20_codprov ',
                        '   AND p28_dividendo   = p20_dividendo ',
                        '   AND c02_compania    = p28_compania ',
                        '   AND c02_tipo_ret    = p28_tipo_ret ',
                        '   AND c02_porcentaje  = p28_porcentaje ',
			'   AND s09_compania    = c02_compania ', 
			'   AND s09_tipo_porc   = c02_tipo_fuente ', 
			'   AND REPLACE(s09_descripcion,"/","") = ',
				'c02_porcentaje), 0) bienesPorcentaje, ',
			'NVL((SELECT p28_valor_ret ',
				'FROM cxpt028, cxpt027, ordt002 ',
	                        'WHERE p27_estado      = "A" ',
        	                '  AND p28_tipo_ret    = "I" ',
                	        '  AND c02_tipo_fuente = "B" ',
				'  AND p27_compania    = p28_compania ',
                	        '  AND p27_localidad   = p28_localidad ',
                        	'  AND p27_num_ret     = p28_num_ret ',
	                        '  AND p28_compania    = p20_compania ',
        	                '  AND p28_localidad   = p20_localidad ',
                	        '  AND p28_tipo_doc    = p20_tipo_doc ',
                        	'  AND p28_num_doc     = p20_num_doc ',
	                        '  AND p28_codprov     = p20_codprov ',
        	                '  AND p28_dividendo   = p20_dividendo ',
                	        '  AND c02_compania    = p28_compania ',
	                        '  AND c02_tipo_ret    = p28_tipo_ret ',
        	                '  AND c02_porcentaje  = p28_porcentaje), ',
			'0) bienesValor, ',
			'NVL((SELECT p28_valor_base ',
				'FROM cxpt028, cxpt027, ordt002 ',
	                        'WHERE p27_estado      = "A" ',
        	                '  AND p28_tipo_ret    = "I" ',
                	        '  AND c02_tipo_fuente IN ("S","T") ',
                        	'  AND p27_compania    = p28_compania ',
	                        '  AND p27_localidad   = p28_localidad ',
        	                '  AND p27_num_ret     = p28_num_ret ',
                	        '  AND p28_compania    = p20_compania ',
                        	'  AND p28_localidad   = p20_localidad ',
	                        '  AND p28_tipo_doc    = p20_tipo_doc ',
        	                '  AND p28_num_doc     = p20_num_doc ',
                	        '  AND p28_codprov     = p20_codprov ',
                        	'  AND p28_dividendo   = p20_dividendo ',
	                        '  AND c02_compania    = p28_compania ',
        	                '  AND c02_tipo_ret    = p28_tipo_ret ',
                	        '  AND c02_porcentaje  = p28_porcentaje), ',
			'0) serviciosBase, ',
			'NVL((SELECT s09_codigo ',
				'FROM cxpt028, cxpt027, ordt002, srit009 ',
	                        'WHERE p27_estado      = "A" ',
        	                '  AND p28_tipo_ret    = "I" ',
                	        '  AND c02_tipo_fuente = "S" ',
                        	'  AND p27_compania    = p28_compania ',
	                        '  AND p27_localidad   = p28_localidad ',
        	                '  AND p27_num_ret     = p28_num_ret ',
                	        '  AND p28_compania    = p20_compania ',
                        	'  AND p28_localidad   = p20_localidad ',
	                        '  AND p28_tipo_doc    = p20_tipo_doc ',
        	                '  AND p28_num_doc     = p20_num_doc ',
                	        '  AND p28_codprov     = p20_codprov ',
                        	'  AND p28_dividendo   = p20_dividendo ',
	                        '  AND c02_compania    = p28_compania ',
        	                '  AND c02_tipo_ret    = p28_tipo_ret ',
                	        '  AND c02_porcentaje  = p28_porcentaje ',
	                        '  AND s09_compania    = c02_compania ',
        	                '  AND s09_tipo_porc   = c02_tipo_fuente ',
                	        '  AND REPLACE(s09_descripcion,"/","") = ',
					'c02_porcentaje), 0) serviciosPorc, ',
		'NVL((SELECT p28_valor_ret ',
			'FROM cxpt028, cxpt027, ordt002 ',
                        'WHERE p27_estado      = "A" ',
                        '  AND p28_tipo_ret    = "I" ',
                        '  AND c02_tipo_fuente = "S" ',
                        '  AND p27_compania    = p28_compania ',
                        '  AND p27_localidad   = p28_localidad ',
                        '  AND p27_num_ret     = p28_num_ret ',
                        '  AND p28_compania    = p20_compania ',
                        '  AND p28_localidad   = p20_localidad ',
                        '  AND p28_tipo_doc    = p20_tipo_doc ',
                        '  AND p28_num_doc     = p20_num_doc ',
                        '  AND p28_codprov     = p20_codprov ',
                        '  AND p28_dividendo   = p20_dividendo ',
                        '  AND c02_compania    = p28_compania ',
                        '  AND c02_tipo_ret    = p28_tipo_ret ',
                        '  AND c02_porcentaje  = p28_porcentaje), ',
			'0) serviciosValor,',
		'CASE    WHEN MONTH(p20_fecha_emi) = 01 THEN "ENE" ',
			'WHEN MONTH(p20_fecha_emi) = 02 THEN "FEB" ',
			'WHEN MONTH(p20_fecha_emi) = 03 THEN "MAR" ',
			'WHEN MONTH(p20_fecha_emi) = 04 THEN "ABR" ',
			'WHEN MONTH(p20_fecha_emi) = 05 THEN "MAY" ',
			'WHEN MONTH(p20_fecha_emi) = 06 THEN "JUN" ',
			'WHEN MONTH(p20_fecha_emi) = 07 THEN "JUL" ',
			'WHEN MONTH(p20_fecha_emi) = 08 THEN "AGO" ',
			'WHEN MONTH(p20_fecha_emi) = 09 THEN "SEP" ',
			'WHEN MONTH(p20_fecha_emi) = 10 THEN "OCT" ',
			'WHEN MONTH(p20_fecha_emi) = 11 THEN "NOV" ',
			'WHEN MONTH(p20_fecha_emi) = 12 THEN "DIC" ',
		'END mes, YEAR(p20_fecha_emi) anio, p20_usuario usuario, ',
		'p20_codprov, ',
		'REPLACE(REPLACE(REPLACE(p01_nomprov, "&", "&amp;"),',
				' "�","&#209;"), "�","&#241;") nomprov, ',
		'p20_tipo_doc, p20_num_doc, p20_dividendo ',
		'FROM cxpt020, cxpt001 ',
		'WHERE p20_codprov   = p01_codprov ',
		'  AND p20_tipo_doc  = "FA" ',
		'  AND p20_compania  = ', vg_codcia,
		--'  and p20_num_doc   = "001-001-0202903"',
		'  AND p20_numero_oc IS NULL ',
		'  AND EXTEND(p20_fecha_emi, YEAR TO MONTH) = "', fecha, '"',
	'INTO TEMP t1 '
PREPARE exec_t1 FROM query
EXECUTE exec_t1
SELECT p20_codprov codp, p20_tipo_doc tp, p20_num_doc num_d, COUNT(*) tot_reg
	FROM t1
	WHERE sec = 'NR'
	GROUP BY 1, 2, 3
	HAVING COUNT(*) > 1
	INTO TEMP t2
SELECT UNIQUE codp, tp, num_d, sec sec_rt
	FROM t1, t2
	WHERE p20_codprov   = codp
	  AND p20_tipo_doc  = tp
	  AND p20_num_doc   = num_d
	  AND sec          <> 'NR'
	INTO TEMP t3
DROP TABLE t2
LET query = 'SELECT UNIQUE NVL((SELECT sec_rt ',
				'FROM t3 ',
				'WHERE codp  = p20_codprov ',
				'  AND tp    = p20_tipo_doc ',
				'  AND num_d = p20_num_doc), sec) sec, ',
			'modulo, sustento, idtipo, idprov, tc, ',
			'establecimiento, pemision, secuencia, aut, ',
			'fecha_reg, fecha_emi, fecha_cad, base_sin, ',
			'base_con, base_ice, iva, ice, monto_iva, monto_ice, ',
			'bienesBase, bienesPorcentaje, bienesValor, ',
			'serviciosBase, serviciosPorc, serviciosValor, ',
			'mes, anio, usuario, p20_codprov, nomprov, ',
			'p20_tipo_doc, p20_num_doc ',
		'FROM t1 ',
		'ORDER BY ', orden CLIPPED
INITIALIZE r_g01.*, r_g02.* TO NULL
SELECT g02_numruc, g01_razonsocial, g02_direccion, g02_telefono1, g02_fax1,
	g02_correo, g01_cedrepl
	INTO r_g02.g02_numruc, r_g01.g01_razonsocial, r_g02.g02_direccion,
		r_g02.g02_telefono1, r_g02.g02_fax1, r_g02.g02_correo,
		r_g01.g01_cedrepl
	FROM gent001, gent002
	WHERE g01_compania  = vg_codcia
	  AND g02_compania  = g01_compania
	  AND g02_localidad = vg_codloc
DISPLAY '<?xml version="1.0" encoding="UTF-8" ?>'
DISPLAY '<iva xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
DISPLAY '<numeroRuc>', r_g02.g02_numruc CLIPPED, '</numeroRuc>'
DISPLAY '<razonSocial>', r_g01.g01_razonsocial CLIPPED, '</razonSocial>'
DISPLAY '<direccionMatriz>', r_g02.g02_direccion CLIPPED, '</direccionMatriz>'
DISPLAY '<telefono>', r_g02.g02_telefono1 CLIPPED, '</telefono>'
DISPLAY '<fax>', r_g02.g02_fax1 CLIPPED, '</fax>'
DISPLAY '<email>', r_g02.g02_correo CLIPPED, '</email>'
DISPLAY '<tpIdRepre>C</tpIdRepre>'
DISPLAY '<idRepre>', r_g01.g01_cedrepl CLIPPED, '</idRepre>'
DISPLAY '<rucContador>1700401100001</rucContador>'
DISPLAY '<anio>', anio USING "&&&&", '</anio>'
DISPLAY '<mes>', mes USING "&&", '</mes>'
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET registro    = '<compras>'
LET num_ret_ant = NULL
FOREACH q_cons INTO r_doc.*, r_adi.*
	LET registro = registro CLIPPED, '<detalleCompras>'
	IF num_args() = 8 THEN
		LET registro = registro CLIPPED,
			'<codProv>', r_adi.proveedor USING "<<<<<<&",
			'</codProv>',
			'<nomProv>', r_adi.nomprov CLIPPED, '</nomProv>'
	END IF
	LET registro = registro CLIPPED,
			'<codSustento>', r_doc.sustento, '</codSustento>',
			'<devIva>N</devIva>',
			'<tpIdProv>', r_doc.idtipo CLIPPED, '</tpIdProv>',
			'<idProv>', r_doc.idprov[1,13] CLIPPED, '</idProv>',
			'<tipoComprobante>', r_doc.tc, '</tipoComprobante>'
			IF vg_codcia = 1 THEN
				LET registro = registro CLIPPED,
				'<fechaRegistro>', r_doc.fecha_reg CLIPPED,
				'</fechaRegistro>'
			ELSE
				LET registro = registro CLIPPED,
				'<fechaRegistro>', '01/', mes USING "&&", '/',
							anio USING "&&&&",
				'</fechaRegistro>'
			END IF
			LET registro = registro CLIPPED,
			'<establecimiento>', r_doc.estableci,
			'</establecimiento>',
			'<puntoEmision>', r_doc.pemision, '</puntoEmision>',
			'<secuencial>', r_doc.secuencia CLIPPED,'</secuencial>'
			IF vg_codcia = 1 THEN
				LET registro = registro CLIPPED,
				'<fechaEmision>', r_doc.fecha_emi CLIPPED,
				'</fechaEmision>'
			ELSE
				LET registro = registro CLIPPED,
				'<fechaEmision>', '01/', mes USING "&&", '/',
							anio USING "&&&&",
				'</fechaEmision>'
			END IF
			LET registro = registro CLIPPED,
			'<autorizacion>', r_doc.aut, '</autorizacion>'
			IF vg_codcia = 1 THEN
				LET registro = registro CLIPPED,
				'<fechaCaducidad>', r_doc.fecha_cad CLIPPED,
				'</fechaCaducidad>'
			ELSE
				LET registro = registro CLIPPED,
				'<fechaCaducidad>', mes USING "&&", '/',
							anio USING "&&&&",
				'</fechaCaducidad>'
			END IF
			LET registro = registro CLIPPED,
			'<baseImponible>', r_doc.base_sin CLIPPED, '</baseImponible>',
			'<baseImpGrav>', r_doc.base_con CLIPPED, '</baseImpGrav>',
			'<porcentajeIva>', r_doc.porc_iva, '</porcentajeIva>',
			'<montoIva>', r_doc.monto_iva CLIPPED, '</montoIva>',
			'<baseImpIce>', r_doc.base_ice CLIPPED, '</baseImpIce>',
			'<porcentajeIce>', r_doc.porc_ice, '</porcentajeIce>',
			'<montoIce>', r_doc.monto_ice CLIPPED, '</montoIce>',
			'<montoIvaBienes>',r_doc.bienesBase CLIPPED,'</montoIvaBienes>',
			'<porRetBienes>',r_doc.bienesPorc CLIPPED, '</porRetBienes>',
			'<valorRetBienes>', r_doc.bienesValor CLIPPED,
			'</valorRetBienes>',
			'<montoIvaServicios>', r_doc.serviciosBase CLIPPED,
			'</montoIvaServicios>',
			'<porRetServicios>', r_doc.serviciosPorc CLIPPED,
			'</porRetServicios>',
			'<valorRetServicios>', r_doc.serviciosValor CLIPPED,
			'</valorRetServicios>',
			'<air>', at_air(r_adi.*) CLIPPED, '</air>',
-- ESTE PEDACITO SOLO SI HAY RETENCIONES
			datos_ret(r_adi.*, 'F') CLIPPED,
			datos_ret(r_adi.*, 'I') CLIPPED,
-- CUANDO NO HAY RETENCION USAR DESDE AQUI
			'<docModificado>0</docModificado>',
			'<fechaEmiModificado>00/00/0000</fechaEmiModificado>',
			'<estabModificado>000</estabModificado>',
			'<ptoEmiModificado>000</ptoEmiModificado>',
			'<secModificado>0000000</secModificado>',
			'<autModificado>0000000000</autModificado>',
			'<montoTituloOneroso>0.00</montoTituloOneroso>',
			'<montoTituloGratuito>0.00</montoTituloGratuito>',
			'</detalleCompras>'
	DISPLAY registro CLIPPED
	LET registro = ' '
	LET num_ret_ant = NULL
END FOREACH
DISPLAY '</compras>'
DISPLAY '<ventas>'
DISPLAY '</ventas>'
DISPLAY '<importaciones>'
DISPLAY '</importaciones>'
DISPLAY '<exportaciones>'
DISPLAY '</exportaciones>'
DISPLAY '<recap>'
DISPLAY '</recap>'
DISPLAY '<fideicomisos>'
DISPLAY '</fideicomisos>'
DISPLAY '<anulados>'
DISPLAY '</anulados>'
DISPLAY '<rendFinancieros>'
DISPLAY '</rendFinancieros>'
DISPLAY '</iva>'
DROP TABLE t1
DROP TABLE t3

END FUNCTION



FUNCTION at_air(proveedor, nomprov, tipo, numero)
DEFINE proveedor	LIKE cxpt020.p20_codprov
DEFINE nomprov		LIKE cxpt001.p01_nomprov
DEFINE tipo		LIKE cxpt020.p20_tipo_doc
DEFINE numero		LIKE cxpt020.p20_num_doc
--DEFINE divid		LIKE cxpt020.p20_dividendo
DEFINE tempo		CHAR(160)
DEFINE salida		CHAR(1500)
DEFINE query		CHAR(2000)

LET tempo  = NULL
LET salida = ' '
LET query  = 'SELECT "<detalleAir><codRetAir>" || TRIM(NVL(p28_codigo_sri, "307"))',
			' || "</codRetAir> " || "<baseImpAir>" || ',
			'p28_valor_base || "</baseImpAir> " ',
			'|| "<porcentajeAir>" || p28_porcentaje || ',
			'"</porcentajeAir>" ||  "<valRetAir>" || p28_valor_ret',
			' || "</valRetAir></detalleAir>" ',
			' FROM cxpt027, cxpt028, cxpt020, ordt002 ',
			' WHERE p27_compania   = ', vg_codcia,
			'   AND p27_localidad  = ', vg_codloc,
			'   AND p27_estado     = "A" ',
			'   AND p28_compania   = p27_compania ',
			'   AND p28_localidad  = p27_localidad ',
			'   AND p28_num_ret    = p27_num_ret ',
			'   AND	p28_tipo_ret   = "F" ',
			'   AND p28_tipo_doc   = "', tipo, '"',
			'   AND p28_num_doc    = "', numero, '"',
			'   AND p28_codprov    = ', proveedor,
			'   AND p20_compania   = p28_compania ',
			'   AND p20_localidad  = p28_localidad ',
			'   AND p20_tipo_doc   = p28_tipo_doc ',
			'   AND p20_num_doc    = p28_num_doc ',
			'   AND p20_codprov    = p28_codprov ',
			'   AND p20_dividendo  = p28_dividendo ',
			'   AND c02_compania   = p28_compania ',
			'   AND c02_tipo_ret   = p28_tipo_ret ',
			'   AND c02_porcentaje = p28_porcentaje	'
PREPARE cons_air FROM query
DECLARE q_cons_air CURSOR FOR cons_air
FOREACH q_cons_air INTO tempo
	LET salida = salida CLIPPED, tempo CLIPPED
END FOREACH
RETURN salida

END FUNCTION



FUNCTION query_datos_ret(proveedor, tipo, numero, tip_ret, opc, flag)
DEFINE proveedor	LIKE cxpt020.p20_codprov
DEFINE tipo		LIKE cxpt020.p20_tipo_doc
DEFINE numero		LIKE cxpt020.p20_num_doc
--DEFINE divid		LIKE cxpt020.p20_dividendo
DEFINE tip_ret		CHAR(1)
DEFINE opc, flag	SMALLINT
DEFINE salida		CHAR(50)
DEFINE campos		CHAR(800)
DEFINE query		CHAR(1000)
DEFINE num_ret		LIKE cxpt028.p28_num_ret

CASE opc
	WHEN 1
		LET campos = 'NVL((SELECT UNIQUE g37_pref_sucurs ',
				'FROM 	gent037, cxpt032 ',
				'WHERE ',
				'p32_compania	= p27_compania AND  ',
				'p32_localidad 	= p27_localidad AND ',
				'p32_num_ret 	= p27_num_ret AND   ',
	
				'g37_compania 	= p32_compania  AND ',
				'g37_localidad 	= p32_localidad AND ',
				'g37_tipo_doc 	= p32_tipo_doc AND  ',
				'g37_secuencia 	= p32_secuencia),0) '
	WHEN 2
		LET campos = 'NVL((SELECT UNIQUE g37_pref_pto_vta ',
				'FROM 	gent037, cxpt032 ',
				'WHERE ',
				'p32_compania	= p27_compania AND  ',
				'p32_localidad 	= p27_localidad AND ',
				'p32_num_ret 	= p27_num_ret AND   ',
	
				'g37_compania 	= p32_compania  AND ',
				'g37_localidad 	= p32_localidad AND ',
				'g37_tipo_doc 	= p32_tipo_doc AND  ',
				'g37_secuencia 	= p32_secuencia),0) '
	WHEN 3
		LET campos = 'TO_CHAR(p27_fecing, "%d/%m/%Y") '

	WHEN 4 
		LET campos = 'NVL((SELECT UNIQUE g37_autorizacion ',
				'FROM 	gent037, cxpt032 ',
				'WHERE ',
				'p32_compania	= p27_compania AND  ',
				'p32_localidad 	= p27_localidad AND ',
				'p32_num_ret 	= p27_num_ret AND   ',
	
				'g37_compania 	= p32_compania  AND ',
				'g37_localidad 	= p32_localidad AND ',
				'g37_tipo_doc 	= p32_tipo_doc AND  ',
				'g37_secuencia 	= p32_secuencia),0) '
	WHEN 5 
		LET campos = 'NVL((SELECT UNIQUE p29_num_sri[9,', long_dig,'] ',
				'FROM 	cxpt029 ',
				'WHERE ',
				'p29_compania	= p27_compania AND  ',
				'p29_localidad 	= p27_localidad AND ',
				'p29_num_ret 	= p27_num_ret ),0)  '
		{--
		IF vg_codcia = 2 THEN
			LET campos ='"01/', mes USING "&&", '/',
					anio USING "&&&&", '" p27_fecing'
		END IF
		--}
END CASE
LET salida = NULL
LET query  = 'SELECT UNIQUE p27_num_ret, ', campos CLIPPED,
		' FROM cxpt028, cxpt027 ',
		' WHERE p27_estado      = "A" ',
		'   AND p28_tipo_ret    = "', tip_ret, '" ',
		'   AND p27_compania    = p28_compania ',
		'   AND p27_localidad   = p28_localidad ',
		'   AND p27_num_ret     = p28_num_ret ',
		'   AND p28_compania    = ', vg_codcia,
		'   AND p28_localidad   = ', vg_codloc,
		'   AND p28_codprov     = ', proveedor,
		'   AND p28_tipo_doc    = "', tipo, '" ',
		'   AND p28_num_doc     = "', numero, '" ',
		--'   AND p28_dividendo   = ', divid
		'   AND p28_dividendo   = 1 '
PREPARE cons_ret FROM query
DECLARE q_ret CURSOR FOR cons_ret
OPEN q_ret
FETCH q_ret INTO num_ret, salida
IF num_ret_ant IS NOT NULL THEN
	IF num_ret_ant = num_ret AND flag = 1 THEN
		LET salida = NULL
	END IF
END IF
LET num_ret_ant = num_ret
CLOSE q_ret
FREE q_ret
RETURN salida

END FUNCTION



FUNCTION datos_ret(proveedor, nomprov, tipo, numero, tip_ret)
DEFINE proveedor	LIKE cxpt020.p20_codprov
DEFINE nomprov		LIKE cxpt001.p01_nomprov
DEFINE tipo		LIKE cxpt020.p20_tipo_doc
DEFINE numero		LIKE cxpt020.p20_num_doc
--DEFINE divid		LIKE cxpt020.p20_dividendo
DEFINE tip_ret		CHAR(1)
DEFINE posi		CHAR(1)
DEFINE salida		CHAR(800)

LET salida = NULL
--IF query_datos_ret(proveedor, tipo, numero, divid, tip_ret, 1, 1) IS NULL THEN
IF query_datos_ret(proveedor, tipo, numero, tip_ret, 1, 1) IS NULL THEN
	RETURN salida
END IF
CASE tip_ret
	WHEN 'F' LET posi = '1'
	WHEN 'I' LET posi = '2'
END CASE
LET salida = '<estabRetencion', posi, '>',
			--query_datos_ret(proveedor, tipo, numero, divid,
			query_datos_ret(proveedor, tipo, numero,
					tip_ret, 1, 0) CLIPPED
			USING "&&&",
		'</estabRetencion', posi, '>',
		'<ptoEmiRetencion', posi, '>',
			--query_datos_ret(proveedor, tipo, numero, divid,
			query_datos_ret(proveedor, tipo, numero,
					tip_ret, 2, 0) CLIPPED
			USING "&&&",
		'</ptoEmiRetencion', posi, '>',
		'<secRetencion', posi, '>',
			--query_datos_ret(proveedor, tipo, numero, divid,
			query_datos_ret(proveedor, tipo, numero,
                                        tip_ret, 5, 0) CLIPPED
			USING "&&&&&&&",
		'</secRetencion', posi, '>',
		'<autRetencion', posi, '>',
			--query_datos_ret(proveedor, tipo, numero, divid,
			query_datos_ret(proveedor, tipo, numero,
                                        tip_ret, 4, 0) CLIPPED
			USING "&&&&&&&&&&",
		'</autRetencion', posi, '>',
		'<fechaEmiRet', posi, '>',
			--query_datos_ret(proveedor, tipo, numero, divid,
			query_datos_ret(proveedor, tipo, numero,
					tip_ret, 3, 0) CLIPPED,
		'</fechaEmiRet', posi, '>'
RETURN salida

END FUNCTION
