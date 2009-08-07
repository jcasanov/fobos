{*
 * Titulo           : cmsp200.4gl - Generacion de liquidacion para pago
 *									de comisiones
 * Elaboracion      : 04-jun-2009
 * Autor            : JCM
 * Formato Ejecucion: fglrun cmsp200 base módulo compañía 
 *}
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_c00		RECORD LIKE cmst000.*

DEFINE rm_par			RECORD
	anio			LIKE cmst010.c10_anio,
	mes				LIKE cmst010.c10_mes,
	fecini_fact		LIKE cmst010.c10_fecini_fact,
	fecfin_fact		LIKE cmst010.c10_fecini_fact
END RECORD
	


MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cmsp200.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'cmsp200'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL validar_parametros()
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
OPEN WINDOW cmsw200_1 AT 3,2 WITH 12 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM cmsf200_1 FROM "../forms/cmsf200_1"
DISPLAY FORM cmsf200_1

CALL fl_lee_compania_comisiones(vg_codcia) RETURNING rm_c00.*
IF rm_c00.c00_compania IS NULL THEN
        CALL fgl_winmessage(vg_producto,
                'No existe configuración para esta compañía.',
                'exclamation')
        EXIT PROGRAM
END IF
                                                                                
MENU 'OPCIONES'
        COMMAND KEY('G') 'Generar'       'Generar liquidacion mensual'
                CALL control_generar()
        COMMAND KEY('S') 'Salir'        'Salir del programa.'
                EXIT MENU
END MENU

END FUNCTION



FUNCTION control_generar()
DEFINE salir		INTEGER
DEFINE finmes_ant	DATE

LET finmes_ant = MDY(MONTH(TODAY), 1, YEAR(TODAY)) - 1 UNITS DAY
INITIALIZE rm_par.* TO NULL
LET rm_par.anio = YEAR(finmes_ant)
LET rm_par.mes  = MONTH(finmes_ant)

LET rm_par.fecini_fact = rm_c00.c00_fecini_fact
LET rm_par.fecfin_fact = finmes_ant 

CALL leer_datos()
IF INT_FLAG THEN
	LET INT_FLAG = 0
	RETURN
END IF

CALL proceso_generar_liquidacion()

END FUNCTION



FUNCTION leer_datos()
DEFINE resp		CHAR(6)
DEFINE tit_mes		VARCHAR(12)

LET INT_FLAG = 0
INPUT BY NAME rm_par.* WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(anio, mes, fecini_fact, fecfin_fact) 
		THEN
			LET INT_FLAG = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET INT_FLAG = 1
				RETURN
			END IF
		END IF
	AFTER INPUT
		IF rm_par.fecini_fact > rm_par.fecfin_fact THEN
			CALL fgl_winmessage(vg_producto, 'La fecha inicial no puede ser mayor a la fecha final.', 'exclamation')
			CONTINUE INPUT
		END IF
END INPUT
		
CALL fl_retorna_nombre_mes(rm_par.mes) RETURNING tit_mes
DISPLAY BY NAME tit_mes

END FUNCTION



FUNCTION proceso_generar_liquidacion()
DEFINE resp			CHAR(6)

DEFINE fecini_pago	DATETIME YEAR TO SECOND
DEFINE fecfin_pago	DATETIME YEAR TO SECOND
DEFINE fecini_fact	DATETIME YEAR TO SECOND
DEFINE fecfin_fact	DATETIME YEAR TO SECOND

DEFINE query		VARCHAR(2500)

DEFINE r_r00		RECORD LIKE rept000.*
DEFINE r_c10		RECORD LIKE cmst010.*

LET fecini_pago = EXTEND(MDY(rm_par.mes, 1, rm_par.anio), YEAR TO SECOND)
LET fecfin_pago = (fecini_pago + 1 UNITS MONTH) - 1 UNITS SECOND

LET fecini_fact = EXTEND(rm_par.fecini_fact, YEAR TO SECOND)
LET fecfin_fact = EXTEND(rm_par.fecfin_fact, YEAR TO SECOND) 
			    + 1 UNITS DAY - 1 UNITS SECOND

CALL fl_lee_compania_repuestos(vg_codcia) RETURNING r_r00.*

BEGIN WORK

DECLARE q_c10 CURSOR FOR
SELECT * 
  FROM cmst010
 WHERE c10_compania = vg_codcia
   AND c10_anio     = rm_par.anio
   AND c10_mes      = rm_par.mes 
FOR UPDATE

INITIALIZE r_c10.* TO NULL
WHENEVER ERROR CONTINUE
OPEN  q_c10
FETCH q_c10 INTO r_c10.*
IF STATUS < 0 THEN
	WHENEVER ERROR STOP
	CALL fgl_winmessage(vg_producto, 'Registro bloqueado por otro usuario.', 'stop')
	ROLLBACK WORK
	RETURN
END IF
WHENEVER ERROR STOP
CLOSE q_c10
FREE  q_c10

IF r_c10.c10_compania IS NOT NULL THEN
	CASE r_c10.c10_estado 
		WHEN 'A'
			CALL fgl_winquestion(vg_producto,
						'Ya se ha generado una liquidación para este mes.' ||
						'¿Desea reemplazarla?', 'No', 'Yes|No', 
						'question', 1)
				RETURNING resp
			IF resp = 'Yes' THEN
				DELETE FROM cmst012 WHERE c12_compania = vg_codcia
									  AND c12_anio     = rm_par.anio	
									  AND c12_mes      = rm_par.mes 	
				DELETE FROM cmst011 WHERE c11_compania = vg_codcia
									  AND c11_anio     = rm_par.anio	
									  AND c11_mes      = rm_par.mes 	
				DELETE FROM cmst010 WHERE c10_compania = vg_codcia
									  AND c10_anio     = rm_par.anio	
									  AND c10_mes      = rm_par.mes 	
			ELSE  -- No
				RETURN
			END IF
		WHEN 'P'
			ROLLBACK WORK
			CALL fgl_winmessage(vg_producto, 'Ya existe una liquidación cerrada para este mes.', 'stop')
			RETURN
		OTHERWISE
			ROLLBACK WORK
			CALL fgl_winmessage(vg_producto, 'Estado desconocido.', 'stop')
			RETURN
	END CASE
END IF 

{*
 * Si todo esta bien empieza el proceso que basicamente consiste en sacar
 * respaldo de algunos datos y un par de calculos.
 *}

-- 1) creamos la cabecera de la liquidación
INITIALIZE r_c10.* TO NULL
LET r_c10.c10_compania    = vg_codcia
LET r_c10.c10_anio        = rm_par.anio
LET r_c10.c10_mes         = rm_par.mes 
LET r_c10.c10_estado      = 'A'
LET r_c10.c10_fecini_fact = rm_par.fecini_fact
LET r_c10.c10_fecfin_fact = rm_par.fecfin_fact
INSERT INTO cmst010 VALUES (r_c10.*)

-- 2) grabamos un respaldo de los pago del mes (tanto PG como PA aplicados)

-- 2.1) Las facturas al contado no pasaban por cobranzas pero sí se deben 
--      considerar para las comisiones. La forma de identificar tales facturas
--      es 1) porque r19_cont_cred esta en C y 2) tienen registros en la cajt011
--      Esto ya no es cierto porque las facturas de contado ahora sí pasan por 
--      cobranzas pero aun es seguro por 2).
LET query = 'INSERT INTO cmst011 ',
			'SELECT r19_compania, ', rm_par.anio, ', ', rm_par.mes, ', ',
			'       r19_localidad, ',
			'		NVL(r19_codcli, ', r_r00.r00_cliente_final, '), ',
			'		j10_tipo_fuente, ',
			'       j10_num_fuente, 1, r19_nomcli, j10_areaneg, r19_cod_tran, ',
			'       "" || r19_num_tran, 1, r19_vendedor, ',
			'       (SELECT r03_grupo_linea FROM rept003 ',
			'		  WHERE r03_compania = r19_compania ',
			' 			AND r03_codigo   = (SELECT MIN(r20_linea) ', 
											' FROM rept020 ',
											'WHERE r20_compania  = r19_compania',
											'  AND r20_localidad = r19_localidad',
											'  AND r20_cod_tran  = r19_cod_tran ',
											'  AND r20_num_tran  = r19_num_tran)), ',
			'       c01_localidad, c01_categoria, ',
			'		DATE(r19_fecing), DATE(j10_fecha_pro), ',
			'       r19_tot_neto, SUM(j11_valor), ',
			'		r19_tot_neto - SUM(j11_valor) ',
			'  FROM cajt010, rept019, cajt011, OUTER cmst001 ',
			' WHERE j10_compania     = ', vg_codcia,
			'   AND j10_tipo_fuente  = "PR" ',
			'   AND j10_tipo_destino = "FA" ',
			'   AND j10_estado       = "P"  ',
			'   AND j10_fecha_pro BETWEEN "', fecini_pago, '"',
									' AND "', fecfin_pago, '"', 
			'   AND r19_compania     = j10_compania ',
			'   AND r19_localidad    = j10_localidad ',
			'   AND r19_cod_tran     = j10_tipo_destino ',
			'   AND r19_num_tran     = j10_num_destino ',
			'   AND r19_fecing BETWEEN "', fecini_fact, '"',
								 ' AND "', fecfin_fact, '"', 
			'   AND r19_cont_cred    = "C" ',
 			'   AND NOT EXISTS (SELECT 1 FROM rept019 dev ',
 								'WHERE dev.r19_compania = rept019.r19_compania', 
 								'  AND dev.r19_localidad = rept019.r19_localidad', 
 								'  AND dev.r19_tipo_dev = rept019.r19_cod_tran', 
 								'  AND dev.r19_num_dev = rept019.r19_num_tran', 
 								'  AND dev.r19_fecing BETWEEN "', fecini_pago, '"',
 														' AND "', fecfin_pago, '")', 
			'   AND j11_compania     = j10_compania ',
			'   AND j11_localidad    = j10_localidad ',
			'   AND j11_tipo_fuente  = j10_tipo_fuente ',
			'   AND j11_num_fuente   = j10_num_fuente ',
			'   AND c01_compania     = r19_compania ',
			'   AND c01_codcli       = r19_codcli ',
			' GROUP BY 1, 4, 5, 6, 7, 9, 10, 11, 12, 14, 15, 16, 17, 18, 19, 20'

PREPARE stmt1 FROM query
EXECUTE stmt1

-- 2.2) Los pagos de facturas a credito, y ahora tanbien pago de facturas 
--      al contado 
LET query = 'INSERT INTO cmst011 ',
			'SELECT z23_compania, ', rm_par.anio, ', ', rm_par.mes, ', ',
			'       z23_localidad, z23_codcli, z23_tipo_trn, z23_num_trn, ',
			'		z23_orden, r19_nomcli, z23_areaneg, z23_tipo_doc, ',
			'		z23_num_doc, ',
			'		z23_div_doc, r19_vendedor, z20_linea, ',
			'       c01_localidad, c01_categoria, ',
			'		z20_fecha_emi, DATE(z22_fecing), ',
			'       z20_valor_cap, z23_valor_cap * (-1), ',
			'		z23_saldo_cap + z23_valor_cap ',
			'  FROM cxct022, cxct023, rept019, cxct020, OUTER cmst001 ',
			' WHERE z22_compania  = ', vg_codcia,
			'   AND z22_tipo_trn  = "PG" ',
			'   AND z22_fecing BETWEEN "', fecini_pago, '"',
								 ' AND "', fecfin_pago, '"', 
			'   AND z23_compania  = z22_compania',
			'   AND z23_localidad = z22_localidad',
			'   AND z23_codcli    = z22_codcli',
			'   AND z23_tipo_trn  = z22_tipo_trn',
			'   AND z23_num_trn   = z22_num_trn',
			'   AND r19_compania  = z23_compania',
			'   AND r19_localidad = z23_localidad',
			'   AND r19_cod_tran  = z23_tipo_doc',
			'   AND r19_num_tran || ""  = z23_num_doc',
			'	AND	NVL(r19_codcli,', r_r00.r00_cliente_final,')=z23_codcli',
 			'   AND NOT EXISTS (SELECT 1 FROM rept019 dev ',
 								'WHERE dev.r19_compania = rept019.r19_compania', 
 								'  AND dev.r19_localidad = rept019.r19_localidad', 
 								'  AND dev.r19_tipo_dev = rept019.r19_cod_tran', 
 								'  AND dev.r19_num_dev = rept019.r19_num_tran', 
 								'  AND dev.r19_fecing BETWEEN "', fecini_pago, '"',
 														' AND "', fecfin_pago, '")', 
			'   AND c01_compania = z23_compania ',
			'   AND c01_codcli   = z23_codcli ',
			'   AND z20_compania  = z23_compania',
			'   AND z20_localidad = z23_localidad',
			'   AND z20_codcli    = z23_codcli',
			'   AND z20_tipo_doc  = z23_tipo_doc',
			'   AND z20_num_doc   = z23_num_doc',
			'   AND z20_dividendo = z23_div_doc',
			'   AND EXTEND(z20_fecha_emi, YEAR TO SECOND) ',
							' BETWEEN "', fecini_fact, '" ',
								' AND "', fecfin_fact, '" ' 

PREPARE stmt2 FROM query	
EXECUTE stmt2

-- 2.3) Los pagos anticipados aplicados 
LET query = 'INSERT INTO cmst011 ',
			'SELECT z23_compania, ', rm_par.anio, ', ', rm_par.mes, ', ',
			'       z23_localidad, z23_codcli, z23_tipo_trn, z23_num_trn, ',
			'		z23_orden, r19_nomcli, z23_areaneg, z23_tipo_doc, ',
			'		z23_num_doc, ',
			'		z23_div_doc, r19_vendedor, z20_linea, ',
			'       c01_localidad, c01_categoria, ',
			'		z20_fecha_emi, DATE(z22_fecing), ',
			'       z20_valor_cap, z23_valor_cap * (-1), ',
			'		z23_saldo_cap + z23_valor_cap ',
			'  FROM cxct022, cxct023, rept019, cxct020, OUTER cmst001 ',
			' WHERE z22_compania  = ', vg_codcia,
			'   AND z22_tipo_trn  = "AJ" ',
			'   AND z22_fecing BETWEEN "', fecini_pago, '"',
								 ' AND "', fecfin_pago, '"', 
			'   AND z23_compania  = z22_compania',
			'   AND z23_localidad = z22_localidad',
			'   AND z23_codcli    = z22_codcli',
			'   AND z23_tipo_trn  = z22_tipo_trn',
			'   AND z23_num_trn   = z22_num_trn',
  			'   AND z23_tipo_favor = "PA" ',
			'   AND r19_compania  = z23_compania',
			'   AND r19_localidad = z23_localidad',
			'   AND r19_cod_tran  = z23_tipo_doc',
			'   AND r19_num_tran || ""  = z23_num_doc',
			'	AND	NVL(r19_codcli,', r_r00.r00_cliente_final,')=z23_codcli',
			'   AND r19_tipo_dev is null',
 			'   AND NOT EXISTS (SELECT 1 FROM rept019 dev ',
 								'WHERE dev.r19_compania = rept019.r19_compania', 
 								'  AND dev.r19_localidad = rept019.r19_localidad', 
 								'  AND dev.r19_tipo_dev = rept019.r19_cod_tran', 
 								'  AND dev.r19_num_dev = rept019.r19_num_tran', 
 								'  AND dev.r19_fecing BETWEEN "', fecini_pago, '"',
 														' AND "', fecfin_pago, '")', 
			'   AND c01_compania = z23_compania ',
			'   AND c01_codcli   = z23_codcli ',
			'   AND z20_compania  = z23_compania',
			'   AND z20_localidad = z23_localidad',
			'   AND z20_codcli    = z23_codcli',
			'   AND z20_tipo_doc  = z23_tipo_doc',
			'   AND z20_num_doc   = z23_num_doc',
			'   AND z20_dividendo = z23_div_doc',
			'   AND EXTEND(z20_fecha_emi, YEAR TO SECOND) ',
							' BETWEEN "', fecini_fact, '" ',
								' AND "', fecfin_fact, '" ' 

PREPARE stmt3 FROM query	
EXECUTE stmt3

-- Los clientes a los que no se les a asignado una localidad usan la 
-- localidad en la que se realizo la venta
UPDATE cmst011 SET c11_loca_comi = c11_localidad, 
				   c11_categoria = (SELECT c04_codigo FROM cmst004
				   					 WHERE c04_compania = c11_compania
									   AND c04_predet   = 'S')		
 WHERE c11_anio      = rm_par.anio
   AND c11_mes       = rm_par.mes
   AND c11_compania  = vg_codcia
   AND c11_loca_comi IS NULL
   AND c11_categoria IS NULL
   
-- 3.1) grabamos un respaldo de la tabla de clientes x comisionistas 
--      (cmst003 -> cmst012)
LET query = 'INSERT INTO cmst012 ',
			'SELECT c03_compania, ', rm_par.anio, ', ', rm_par.mes, ', ',
		    '       c03_codcli, c03_codcomi, c01_categoria,  ', 
		    '       c05_linea, c05_porcentaje ',
			'  FROM cmst003, cmst005, cmst001 ', 
			' WHERE c03_compania = ', vg_codcia,
 			'   AND c01_compania = c03_compania ',
			'   AND c01_codcli   = c03_codcli   ',
			'   AND c05_compania = c03_compania ',
			'   AND c05_codcomi  = c03_codcomi  ',
  			'   AND c05_categoria = c01_categoria '

PREPARE stmt4 FROM query			
EXECUTE stmt4

-- 3.2) Para todos aquellos clientes que no han sido asignados a un comisionista
--      usamos el que corresponda al que hizo la venta  

-- Los clientes que no estan en la cmst003 (no se les a asignado ningun 
-- comisionista) son categoria baja aunque la cmst001 diga otra cosa
UPDATE cmst011 SET c11_categoria = (SELECT c04_codigo FROM cmst004
				   					 WHERE c04_compania = c11_compania
									   AND c04_predet   = 'S')		
 WHERE c11_anio      = rm_par.anio
   AND c11_mes       = rm_par.mes
   AND c11_compania  = vg_codcia
   AND c11_codcli NOT IN (SELECT c03_codcli FROM cmst003
   						   WHERE c03_compania = vg_codcia)	

LET query = 'INSERT INTO cmst012 ',
			'SELECT c11_compania, ', rm_par.anio, ', ', rm_par.mes, ', ',
			'		c11_codcli, c06_codcomi, c11_categoria, ',  
			'		c11_linea, c05_porcentaje ',
			'  FROM cmst011, cmst006, cmst005 ', 
			' WHERE c11_anio      = ', rm_par.anio,
			'   AND c11_mes       = ', rm_par.mes,
			'   AND c11_compania  = ', vg_codcia,
   			'	AND NOT EXISTS (SELECT 1 FROM cmst003 ',
								'WHERE c03_compania = c11_compania ',
								'  AND c03_codcli   = c11_codcli) ',
			'   AND c06_compania  = c11_compania ',
			'   AND c06_modulo     = "RE" ',
			'   AND c06_vendedor   = c11_vendedor ', 	
			'   AND c05_compania  = c06_compania ',
			'   AND c05_codcomi   = c06_codcomi  ',
  			'   AND c05_categoria = c11_categoria ',
  			'   AND c05_linea     = c11_linea ',
			' GROUP BY c11_compania, c11_codcli, c06_codcomi, c11_categoria, ',
			'		   c11_linea, c05_porcentaje '

PREPARE stmt5 FROM query			
EXECUTE stmt5

-- 4) Tambien se debe sacar un respaldo de las devoluciones realizadas en este
--    mes de facturas emitidas antes de c00_fecfin_dev
LET query = 'INSERT INTO cmst011 ',
            'SELECT dev.r19_compania, ', rm_par.anio, ', ', rm_par.mes, ', ',
            '       dev.r19_localidad, dev.r19_codcli, dev.r19_cod_tran, ',
			'		dev.r19_num_tran, 1, fact.r19_nomcli, 1, ',
			'		dev.r19_cod_tran, ',
			'		dev.r19_num_tran, 1, ',
            '       fact.r19_vendedor, ',
			'       (SELECT r03_grupo_linea FROM rept003 ',
			'		  WHERE r03_compania = dev.r19_compania ',
			' 			AND r03_codigo   = (SELECT MIN(r20_linea) ', 
											' FROM rept020 ',
											'WHERE r20_compania  = fact.r19_compania',
											'  AND r20_localidad = fact.r19_localidad',
											'  AND r20_cod_tran  = fact.r19_cod_tran ',
											'  AND r20_num_tran  = fact.r19_num_tran)), ',
			'       c01_localidad, c01_categoria, ',
            '       DATE(dev.r19_fecing), DATE(dev.r19_fecing), ',
            '       dev.r19_tot_neto, dev.r19_tot_neto, ',
            '       0 ',
			'  FROM rept019 dev, rept019 fact, OUTER cmst001 ',
			' WHERE dev.r19_compania = ', vg_codcia,
			'   AND dev.r19_cod_tran IN ("DF", "AF") ',
			'   AND dev.r19_fecing BETWEEN "', fecini_pago, '"',
									 ' AND "', fecfin_pago, '"', 
			'	AND c01_compania	   = dev.r19_compania ',
			'	AND c01_codcli  	   = dev.r19_codcli   ',
			'   AND fact.r19_compania  = dev.r19_compania ',
			'   AND fact.r19_localidad = dev.r19_localidad ',
			'   AND fact.r19_cod_tran  = dev.r19_tipo_dev ',
			'   AND fact.r19_num_tran  = dev.r19_num_dev ',
			'   AND DATE(fact.r19_fecing) <= "', rm_c00.c00_fecfin_dev, '"'

PREPARE stmt6 FROM query			
EXECUTE stmt6

COMMIT WORK
CALL fgl_winmessage(vg_producto, 'Proceso realizado Ok.', 'exclamation')

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
