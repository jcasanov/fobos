{*
 * Titulo               : repp229.4gl -- CIERRE MENSUAL DE REPUESTOS
 * Elaboración          : 30-abr-2002
 * Autor                : GVA
 * Formato de Ejecución : fglrun repp229 base modulo compañia localidad
 *}
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_anio		VARCHAR(4)
DEFINE vm_mes		VARCHAR(2)
DEFINE rm_r00		RECORD LIKE rept000.*


MAIN

CALL startlog('../logs/repp229.error')

IF num_args() <> 4 THEN
     EXIT PROGRAM
END IF

LET vg_base		= arg_val(1)
LET vg_modulo	= arg_val(2)
LET vg_codcia	= arg_val(3)
LET vg_codloc	= arg_val(4)

LET vg_proceso	= 'repp229'

CALL fl_activar_base_datos(vg_base)

CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE resp 		VARCHAR(6)

CALL fl_nivel_isolation()

CALL fl_lee_compania_repuestos(vg_codcia) RETURNING rm_r00.*
IF rm_r00.r00_compania IS NULL THEN
	EXIT PROGRAM
END IF

IF rm_r00.r00_anopro IS NULL THEN 
	LET vm_anio = YEAR(TODAY)
	LET vm_mes  = MONTH(TODAY)
ELSE
	LET vm_anio = rm_r00.r00_anopro
	LET vm_mes  = rm_r00.r00_mespro
END IF

CALL control_cerrar_mes()

END FUNCTION



FUNCTION validar_mes(anho, mes)

DEFINE mes,anho		SMALLINT

DEFINE dia, mes2, anho2	SMALLINT
DEFINE fecha		DATE

IF anho < YEAR(TODAY) THEN
	RETURN 1
ELSE
	IF mes < MONTH(TODAY) THEN
		RETURN 1
	END IF
END IF

IF mes = 12 THEN
	LET mes2  = 1
	LET anho2 = anho + 1
ELSE
	LET mes2  = mes + 1
	LET anho2 = anho
END IF

LET fecha = mdy(mes2, 1, anho2)
LET fecha = fecha - 1

IF TODAY < fecha THEN
	RETURN 0
END IF

RETURN 1

END FUNCTION



FUNCTION control_cerrar_mes()
DEFINE expr_sql 	VARCHAR(500)

BEGIN WORK

INITIALIZE rm_r00.* TO NULL

SET LOCK MODE TO WAIT 5
WHENEVER ERROR CONTINUE
DECLARE q_rept000 CURSOR FOR
	SELECT * FROM rept000 WHERE r00_compania = vg_codcia
	FOR UPDATE
OPEN  q_rept000
FETCH q_rept000 INTO rm_r00.*
IF STATUS < 0 THEN
	WHENEVER ERROR STOP
	SET LOCK MODE TO NOT WAIT
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	RETURN
END IF
WHENEVER ERROR STOP
SET LOCK MODE TO NOT WAIT

DELETE FROM rept031 WHERE r31_compania = vg_codcia
		      AND r31_ano      = vm_anio
		      AND r31_mes      = vm_mes

LET expr_sql = 'INSERT INTO rept031 ',
		'SELECT r11_compania,', vm_anio, ',', vm_mes,
		', r11_bodega, r11_item, r11_stock_act,',
		'r10_costo_mb, r10_costo_ma, r10_precio_mb,',
		'r10_precio_ma',
		' FROM rept011, rept010 ',
		'WHERE r11_compania  =',vg_codcia,
		'  AND r11_stock_act > 0',
		'  AND r10_compania  = r11_compania',
		'  AND r10_codigo    = r11_item'

PREPARE sentencia FROM expr_sql
EXECUTE sentencia

IF status < 0 THEN
	ROLLBACK WORK
	RETURN 0
END IF

LET expr_sql = 'UPDATE STATISTICS'
PREPARE updstats FROM expr_sql
EXECUTE updstats

IF vm_mes = 12 THEN
	LET vm_mes  = 1
	LET vm_anio = vm_anio + 1
ELSE
	LET vm_mes  = vm_mes + 1
END IF

CALL calcular_datos_estadisticos()

UPDATE rept000 SET r00_mespro = vm_mes, r00_anopro = vm_anio 
	WHERE CURRENT OF q_rept000 

COMMIT WORK
RETURN 1

END FUNCTION



FUNCTION calcular_datos_estadisticos()
DEFINE r_r106			RECORD LIKE rept106.*
DEFINE r_r10			RECORD LIKE rept010.*

DEFINE num_items_anio	INTEGER
DEFINE lead_time		LIKE rept105.r105_valor
DEFINE item				LIKE rept010.r10_codigo

DEFINE costo			LIKE rept020.r20_costo
DEFINE costo_anio		LIKE rept020.r20_costo
DEFINE prom_costo_anio	LIKE rept020.r20_costo
DEFINE fecing			LIKE rept020.r20_fecing

DEFINE A, F, X, Y		DECIMAL(15,5)

--#	MESSAGE 'Borrando datos anteriores...'

	DELETE FROM rept106 
	 WHERE r106_compania  = vg_codcia
	   AND r106_localidad = vg_codloc
	   AND r106_anio      = vm_anio
	   AND r106_mes       = vm_mes

--#	MESSAGE 'Cargando datos para calcular estadisticas...'

	INITIALIZE r_r106.* TO NULL
	LET r_r106.r106_compania  = vg_codcia
	LET r_r106.r106_localidad = vg_codloc
	LET r_r106.r106_anio      = vm_anio
	LET r_r106.r106_mes	      = vm_mes

	SELECT * FROM rept020, rept100
	 WHERE r20_compania   = vg_codcia
	   AND r20_localidad  = vg_codloc
	   AND r20_cod_tran IN ('FA', 'DF', 'AF')
	   AND r20_fecing BETWEEN EXTEND(MDY(vm_mes, 1, vm_anio), YEAR TO SECOND)
		                  AND EXTEND((MDY(vm_mes, 1, vm_anio)+ 1 UNITS MONTH), YEAR TO SECOND) - 1 UNITS SECOND
	   AND r100_compania  = r20_compania
	   AND r100_localidad = r20_localidad
	   AND r100_cod_tran  = r20_cod_tran
	   AND r100_num_tran  = r20_num_tran
	   AND r100_item      = r20_item
	  INTO TEMP te_items

	UPDATE te_items SET r100_cantidad = r100_cantidad * (-1) 
	 WHERE r20_cod_tran IN ('DF', 'AF')

	-- Solo los items que alguna vez han tenido movimiento son interesantes
	-- para consideracion
	DECLARE q_items CURSOR FOR 
		SELECT r31_item, NVL(SUM(r100_cantidad), 0), NVL(SUM(r20_precio*r100_cantidad), 0),
						 NVL(SUM(r20_costo*r100_cantidad), 0)
		  FROM rept002, rept031, OUTER te_items 
	 	 WHERE r02_compania = vg_codcia 
		   AND r02_localidad = vg_codloc 
		   AND r31_compania  = r02_compania
		   AND r31_ano = vm_anio
		   AND r31_mes = vm_mes
		   AND r31_bodega  = r02_codigo 
		   AND r20_compania  = r31_compania
		   AND r20_localidad = r02_localidad
		   AND r20_cod_tran IN ('FA', 'DF', 'AF')
		   AND r20_item      = r31_item
		   AND r100_bodega   = r31_bodega
		 GROUP BY r31_item

	FOREACH q_items INTO r_r106.r106_item, r_r106.r106_unid_vtas, r_r106.r106_valor_vtas,
						 r_r106.r106_costo_vtas

		IF r_r106.r106_item IS NULL THEN
			CONTINUE FOREACH
		END IF

		LET r_r106.r106_pto_reorden = 0
		LET r_r106.r106_eoq         = 0
		LET r_r106.r106_stock_min   = 0
		LET r_r106.r106_stock_seg   = 0
		LET r_r106.r106_ult_cpp     = 0
		LET r_r106.r106_rota_und    = 0
		LET r_r106.r106_rota_finan  = 0

		LET lead_time = 0
		LET num_items_anio = 0
		LET costo_anio = 0
		LET prom_costo_anio = 0

		-- Necesito saber el lead time vigente actualmente
		SELECT NVL(r105_valor, r104_valor_default) INTO lead_time 
		  FROM rept104, OUTER rept105	
		 WHERE r104_compania  = vg_codcia
		   AND r104_codigo    = 'LT'
		   AND r105_compania  = r104_compania
		   AND r105_parametro = r104_codigo
		   AND r105_item      = r_r106.r106_item
		   AND r105_fecha_fin IS NULL

		IF lead_time IS NULL THEN
			LET lead_time = 0
		END IF

		-- Necesito saber el num. de items vendidos en los ult. 12 meses
		SELECT SUM(r106_unid_vtas), SUM(r106_costo_vtas), SUM(r106_ult_cpp) 
		  INTO num_items_anio, costo_anio, prom_costo_anio
		  FROM rept106
		 WHERE r106_compania  = vg_codcia
		   AND r106_localidad = vg_codloc
		   AND MDY(r106_mes, 1, r106_anio) BETWEEN MDY(vm_mes, 1, vm_anio) - 11 UNITS MONTH
				    						   AND MDY(vm_mes, 1, vm_anio) 
		   AND r106_item = r_r106.r106_item

		IF num_items_anio IS NULL THEN
			LET num_items_anio = 0
		END IF
		LET num_items_anio = num_items_anio + r_r106.r106_unid_vtas 

		IF costo_anio IS NULL THEN
			LET costo_anio = 0
		END IF
		LET costo_anio = costo_anio + r_r106.r106_costo_vtas 

		IF prom_costo_anio IS NULL THEN
			LET prom_costo_anio = 0
		END IF

		INITIALIZE costo TO NULL
		LET fecing = (EXTEND(MDY(vm_mes, 1, vm_anio), YEAR TO SECOND) + 1 UNITS MONTH) - 1 UNITS SECOND
		DECLARE q_ult CURSOR FOR
			SELECT r20_costo, r20_fecing FROM rept020
			 WHERE r20_compania = vg_codcia
			   AND r20_localidad = vg_codloc
			   AND r20_cod_tran IN ('CL', 'IM', 'AC', 'IC', 'IX')
			   AND r20_item  = r_r106.r106_item
			   AND r20_fecing <= fecing
			ORDER BY r20_fecing DESC 
		OPEN q_ult 
		FETCH q_ult INTO costo, fecing
		CLOSE q_ult
		FREE q_ult
		IF costo IS NULL THEN
			LET costo = 0
		END IF
		LET prom_costo_anio = (prom_costo_anio + costo) / 12

		{*
		 * Calculo del Punto de Reorden; si el lead time es igual a 0 no calcule nada
		 *
	     * A = 360 / lead time
		 * F = num_items_anio / A  
		 * X = F * lead time
		 * Y = 360 / X
		 * PR = num_items_anio / Y 
		 *}
		IF lead_time > 0 AND num_items_anio > 0 THEN
			LET A = 360 / lead_time
			LET F = num_items_anio / A 
			LET X = F * lead_time
			LET Y = 360 / X
			LET r_r106.r106_pto_reorden = num_items_anio / Y 
		END IF
		
		{*
		 * Calculo del EOQ y stock minimo y de seguridad; si el lead time es igual a 0 no 
		 * calcule nada
		 *
		 * EOQ = (num_items_anio * lead time) / 360
		 * stock_seguridad = EOQ * 1.5 
		 * stock_minimo    = EOQ + stock_seguridad 
		 *}
		IF lead_time > 0 AND num_items_anio > 0 THEN
			LET r_r106.r106_eoq = (num_items_anio * lead_time) / 360 
			LET r_r106.r106_stock_seg   = r_r106.r106_eoq * 1.5
			LET r_r106.r106_stock_min   = r_r106.r106_eoq + r_r106.r106_stock_seg
		END IF

		{*
		 * Se obtiene el ultimo CPP
		 *}
		LET r_r106.r106_ult_cpp = costo

		{*
	 	 * Rotacion financiera
		 *}
		IF costo_anio > 0 AND prom_costo_anio > 0 THEN
			LET	r_r106.r106_rota_finan = costo_anio / prom_costo_anio
		END IF

		{*
	 	 * Rotacion items
		 *}
		IF num_items_anio > 0 THEN
			LET r_r106.r106_rota_und = num_items_anio / 360
		END IF

		INSERT INTO rept106 VALUES (r_r106.*)
	END FOREACH
	FREE q_items

	DROP TABLE te_items
END FUNCTION

