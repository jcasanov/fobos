DATABASE diteca

DEFINE vg_codcia	INTEGER
DEFINE vg_codloc	SMALLINT
DEFINE vm_anio		SMALLINT	
DEFINE vm_mes		SMALLINT	


MAIN

LET vg_codcia	= arg_val(1)
LET vg_codloc	= arg_val(2)

CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE resp 		VARCHAR(6)
DEFINE fecha		DATE

LET fecha = MDY(9, 1, 2008)

WHILE TRUE
	LET vm_anio = YEAR(fecha)
	LET vm_mes  = MONTH(fecha)


	DISPLAY 'procesando: ', fecha USING 'yyyy-mm-dd'
	CALL calcular_datos_estadisticos()

	LET fecha = fecha + 1 UNITS MONTH
	IF YEAR(fecha) = 2010 AND MONTH(fecha) = 2 THEN
		EXIT WHILE
	END IF
END WHILE

END FUNCTION




FUNCTION calcular_datos_estadisticos()
DEFINE r_r106			RECORD LIKE rept106.*
DEFINE r_r10			RECORD LIKE rept010.*

DEFINE ult_anio			INTEGER
DEFINE ult_mes			INTEGER

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

	SELECT * FROM rept020
	 WHERE r20_compania   = vg_codcia
	   AND r20_localidad  = vg_codloc
	   AND r20_cod_tran IN ('FA', 'DF', 'AF')
	   AND r20_fecing BETWEEN EXTEND(MDY(vm_mes, 1, vm_anio), YEAR TO SECOND)
		                  AND EXTEND((MDY(vm_mes, 1, vm_anio)+ 1 UNITS MONTH), YEAR TO SECOND) - 1 UNITS SECOND
	  INTO TEMP te_items

	UPDATE te_items SET r20_cant_ven = r20_cant_ven * (-1) 
	 WHERE r20_cod_tran IN ('DF', 'AF')

	-- Solo los items que alguna vez han tenido movimiento son interesantes
	-- para consideracion
	DECLARE q_ult106 CURSOR FOR
	SELECT r106_anio, r106_mes FROM rept106
	 GROUP BY 1, 2 ORDER BY 1 DESC, 2 DESC

	INITIALIZE ult_anio, ult_mes TO NULL
	OPEN  q_ult106
	FETCH q_ult106 INTO ult_anio, ult_mes
	CLOSE q_ult106
	FREE  q_ult106

	IF ult_anio IS NULL THEN
		LET ult_anio = 2001
		LET ult_mes  = 1
	END IF

	SELECT r106_item, NVL(SUM(r20_cant_ven), 0) as unid, 
                      NVL(SUM(r20_precio*r20_cant_ven), 0) as precio,
		              NVL(SUM(r20_costo*r20_cant_ven), 0) as costo
	  FROM rept106, OUTER te_items 
	 WHERE r106_compania  = vg_codcia 
	   AND r106_localidad = vg_codloc 
	   AND r106_anio      = ult_anio
	   AND r106_mes       = ult_mes
	   AND r20_compania  = r106_compania
	   AND r20_localidad = r106_localidad
	   AND r20_cod_tran IN ('FA', 'DF', 'AF')
	   AND r20_item      = r106_item
	 GROUP BY r106_item
	  INTO TEMP items_a_procesar

	INSERT INTO items_a_procesar
	SELECT r20_item, NVL(SUM(r20_cant_ven), 0) as unid, 
                     NVL(SUM(r20_precio*r20_cant_ven), 0) as precio,
		             NVL(SUM(r20_costo*r20_cant_ven), 0) as costo
	  FROM te_items 
	 WHERE r20_item NOT IN (SELECT r106_item FROM rept106
							 WHERE r106_compania  = vg_codcia
							   AND r106_localidad = vg_codloc
							   AND r106_anio      = ult_anio
							   AND r106_mes       = ult_mes)
	 GROUP BY r20_item

	DECLARE q_items CURSOR FOR 
		SELECT * FROM items_a_procesar

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
{
			LET A = 360 / lead_time
			LET F = num_items_anio / A 
			LET X = F * lead_time
			LET Y = 360 / X
}
			LET r_r106.r106_pto_reorden = (360*360) / (num_items_anio*lead_time*lead_time) 
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
	DROP TABLE items_a_procesar
END FUNCTION
