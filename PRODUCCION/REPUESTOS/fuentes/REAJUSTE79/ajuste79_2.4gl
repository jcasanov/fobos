DATABASE aceros



GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'


DEFINE rm_r00		RECORD LIKE rept000.*	-- CONFIGURACION DE LA
DEFINE rm_r01		RECORD LIKE rept001.*
DEFINE rm_r11	 	RECORD LIKE rept011.*	-- EXIST. ITEMS
DEFINE rm_r19		RECORD LIKE rept019.*	-- CABECERA
DEFINE rm_r20	 	RECORD LIKE rept020.*	-- DETALLE
DEFINE rm_aj_exist	ARRAY[1000] OF RECORD
				r20_cant_ven	LIKE rept020.r20_cant_ven,
				r20_stock_ant	LIKE rept020.r20_stock_ant,
				r20_item	LIKE rept020.r20_item,
				r10_costo_mb	LIKE rept010.r10_costo_mb,
				total		LIKE rept019.r19_tot_costo
			END RECORD
DEFINE vm_num_detalles	SMALLINT	-- NUMERO DE ELEMENTOS DEL DETALLE
DEFINE vm_total    	DECIMAL(12,2)
DEFINE linea		VARCHAR(5)
DEFINE vm_ajuste_mas	LIKE gent021.g21_cod_tran
DEFINE vm_ajuste_menos	LIKE gent021.g21_cod_tran
DEFINE vm_bod_sstock	LIKE rept002.r02_codigo

DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE vm_fecha_desde	DATE
DEFINE vm_fecha_hasta	DATE
DEFINE vm_bodega	LIKE rept019.r19_bodega_ori
DEFINE vm_stock_inicial	DECIMAL(8,2)
DEFINE vm_tot_ing	DECIMAL(8,2)
DEFINE vm_tot_egr	DECIMAL(8,2)
DEFINE r_detalle	ARRAY [1000] OF RECORD
				r20_cod_tran	LIKE rept019.r19_cod_tran,
				r20_num_tran	LIKE rept019.r19_num_tran,
				fecha		DATE,
				cliente		LIKE cxct001.z01_nomcli,
				cant_ing	DECIMAL(8,2),
				cant_egr	DECIMAL(8,2),
				saldo		DECIMAL(8,2)
			END RECORD



MAIN
	
CALL startlog('ajuste79.err')
IF num_args() <> 2 THEN
	DISPLAY 'Parametros Incorrectos. Son: BASE y LOCALIDAD.'
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = "RE"
LET vg_codcia   = 1
LET vg_codloc   = arg_val(2)
CALL fl_activar_base_datos(vg_base)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
INITIALIZE rm_r01.* TO NULL
SELECT * INTO rm_r01.* FROM rept001
	WHERE r01_compania   = vg_codcia
	  AND r01_estado     = 'A'
	  AND r01_user_owner = 'FOBOS'
IF rm_r01.r01_compania IS NULL THEN
	DISPLAY 'El Usuario FOBOS no tiene creado Código de Vendedor.'
	EXIT PROGRAM
END IF
LET vm_ajuste_mas   = 'A+'
LET vm_ajuste_menos = 'A-'
INITIALIZE vm_bod_sstock TO NULL                                      
SELECT r02_codigo INTO vm_bod_sstock FROM rept002                               
		WHERE r02_compania  = vg_codcia                                 
		  --AND r02_localidad = vg_codloc
		  AND r02_localidad = 2		-- LA DEL CENTRO
		  AND r02_estado    = "A"                                      
		  AND r02_tipo      = "S"                                       
		  AND r02_area      = "R"                                       
IF vm_bod_sstock IS NULL THEN
	DISPLAY 'No existe una Bodega sin Stock.'
	EXIT PROGRAM
END IF
LET vm_max_det = 1000
CALL obtener_items()
CALL obtener_saldo_real_item()
INITIALIZE linea TO NULL
BEGIN WORK
	CALL ejecuta_proceso(1)
	CALL ejecuta_proceso(2)
COMMIT WORK
CALL fl_mensaje_registro_ingresado()
DROP TABLE tmp_sinstock

END FUNCTION



FUNCTION ejecuta_proceso(i)
DEFINE i		SMALLINT

DECLARE q_tipo_aj CURSOR FOR
	SELECT UNIQUE r03_codigo FROM tmp_sinstock, rept003
		WHERE flag_tipo_aj = i
		  AND r03_compania = r11_compania
		  AND r03_codigo   = divis
		ORDER BY r03_codigo
FOREACH q_tipo_aj INTO linea
	CALL control_ingreso(i)
END FOREACH

END FUNCTION



FUNCTION obtener_items()
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r35		RECORD LIKE rept035.*
DEFINE division		LIKE rept010.r10_linea
DEFINE saldo		LIKE rept011.r11_stock_act
DEFINE cuantos, i, j, l	INTEGER

SELECT rept011.*, r10_linea divis, 1 flag_tipo_aj
	FROM rept011, rept010
	WHERE r11_compania   = vg_codcia
	  AND r11_bodega     = vm_bod_sstock
	  AND r11_stock_act <> 0
	  AND r10_compania   = r11_compania
	  AND r10_codigo     = r11_item
	INTO TEMP tmp_sinstock
SELECT COUNT(*) INTO cuantos FROM tmp_sinstock
IF cuantos = 0 THEN
	DISPLAY 'No existen items con stock distinto a cero en la bodega sin stock del Centro.'
	EXIT PROGRAM
END IF
DECLARE q_caca1 CURSOR FOR SELECT * FROM tmp_sinstock
LET i = 0
LET l = 0
FOREACH q_caca1 INTO r_r11.*, division, j
	DECLARE q_caca2 CURSOR FOR SELECT rept035.*
		FROM rept035, rept034, rept019
		WHERE r35_compania                 = r_r11.r11_compania
		  AND r35_localidad                = vg_codloc
		  AND r35_bodega                   = r_r11.r11_bodega
		  AND r35_item                     = r_r11.r11_item
		  AND r35_cant_des - r35_cant_ent <> 0
		  AND r34_compania                 = r35_compania
		  AND r34_localidad                = r35_localidad
		  AND r34_bodega                   = r35_bodega
		  AND r34_num_ord_des              = r35_num_ord_des
		  AND r34_estado                  IN ("A", "P")
		  AND r19_compania                 = r34_compania
		  AND r19_localidad                = r34_localidad
		  AND r19_cod_tran                 = r34_cod_tran
		  AND r19_num_tran                 = r34_num_tran
		  AND r19_tipo_dev IS NULL
	OPEN q_caca2
	FETCH q_caca2 INTO r_r35.*
	IF STATUS = NOTFOUND THEN
		UPDATE tmp_sinstock SET r11_stock_ant = r11_stock_act,
					r11_stock_act = 0
			WHERE r11_compania = r_r11.r11_compania
			  AND r11_bodega   = r_r11.r11_bodega
			  AND r11_item     = r_r11.r11_item
		DISPLAY 'Actualizando Stock Item: ', r_r11.r11_item CLIPPED,
			' con Stock igual a 0  OK.'
		LET l = l + 1
		CLOSE q_caca2
		FREE q_caca2
		CONTINUE FOREACH
	END IF
	LET saldo = 0
	FOREACH q_caca2 INTO r_r35.*
		LET saldo = saldo + (r_r35.r35_cant_des - r_r35.r35_cant_ent)
	END FOREACH
	LET saldo = saldo * (-1)
	UPDATE tmp_sinstock SET r11_stock_ant = r11_stock_act,
				r11_stock_act = saldo
		WHERE r11_compania = r_r35.r35_compania
		  AND r11_bodega   = r_r35.r35_bodega
		  AND r11_item     = r_r35.r35_item
	DISPLAY 'Actualizando Stock Pendiente Item: ', r_r35.r35_item CLIPPED,
		' con Saldo: ', saldo USING "--,--&.##", '  OK.'
	LET i = i + 1
END FOREACH
DISPLAY 'Actualizo ', l USING "#,##&",
	' Items con Stock = 0 en la Tabla Temporal Sin Stock. OK'
DISPLAY 'Actualizo ', i USING "#,##&",
	' Items con Stock <> 0 en la Tabla Temporal Sin Stock. OK'

END FUNCTION



FUNCTION control_ingreso(flag_aj)
DEFINE flag_aj, i, j 	SMALLINT
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE division		LIKE rept010.r10_linea

INITIALIZE rm_r19.* TO NULL
INITIALIZE rm_r20.* TO NULL
DECLARE q_items CURSOR FOR
	SELECT * FROM tmp_sinstock
		WHERE flag_tipo_aj = flag_aj
		  AND divis        = linea
LET vm_num_detalles = 1
FOREACH q_items INTO r_r11.*, division, j
	LET rm_aj_exist[vm_num_detalles].r20_cant_ven  = r_r11.r11_stock_ant
	LET rm_aj_exist[vm_num_detalles].r20_stock_ant = r_r11.r11_stock_act
	LET rm_aj_exist[vm_num_detalles].r20_item      = r_r11.r11_item
	CALL fl_lee_item(vg_codcia, rm_aj_exist[vm_num_detalles].r20_item)
		RETURNING r_r10.*
	LET rm_aj_exist[vm_num_detalles].r10_costo_mb  = r_r10.r10_costo_mb
	LET vm_num_detalles                            = vm_num_detalles + 1
	IF vm_num_detalles > vm_max_det THEN
		DISPLAY 'ERROR: El tamaño del Arreglo excede el límite.'
		EXIT PROGRAM
	END IF
END FOREACH
LET vm_num_detalles       = vm_num_detalles - 1
CALL calcular_total()
LET rm_r19.r19_compania   = vg_codcia
LET rm_r19.r19_localidad  = vg_codloc
CASE flag_aj
	WHEN 1
		LET rm_r19.r19_cod_tran   = vm_ajuste_mas
	WHEN 2
		LET rm_r19.r19_cod_tran   = vm_ajuste_menos
END CASE
--LET rm_r19.r19_referencia = 'AJUSTE PARA CUADRAR BODEGA 79 CENTRO.'
LET rm_r19.r19_referencia = 'AJUSTE QUE REGULARIZA SALDO REAL BOD.79'
LET rm_r19.r19_vendedor   = rm_r01.r01_codigo
LET rm_r19.r19_bodega_ori = vm_bod_sstock
LET rm_r19.r19_cont_cred  = 'C'
LET rm_r19.r19_nomcli     = ' '
LET rm_r19.r19_dircli     = ' '
LET rm_r19.r19_cedruc     = ' '
LET rm_r19.r19_descuento  = 0.0
LET rm_r19.r19_porc_impto = 0.0
LET rm_r19.r19_precision  = 2
LET rm_r19.r19_paridad    = 1
LET rm_r19.r19_tot_bruto  = 0.0
LET rm_r19.r19_tot_dscto  = 0.0
LET rm_r19.r19_flete      = 0.0
LET rm_r19.r19_tot_costo  = vm_total 
LET rm_r19.r19_tot_neto   = vm_total 
CALL control_ingreso_cabecera()
CALL control_ingreso_detalle()
CALL control_actualizacion_existencia()

END FUNCTION



FUNCTION control_ingreso_cabecera()
DEFINE i 		SMALLINT
DEFINE num_tran         LIKE rept019.r19_num_tran

CALL fl_lee_compania_repuestos(vg_codcia) RETURNING rm_r00.*
CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, vg_modulo, 'AA',
					rm_r19.r19_cod_tran)
	RETURNING num_tran
CASE num_tran 
	WHEN 0
		CALL fl_mostrar_mensaje('No existe control de secuencia para esta transacción, no se puede asignar un número de transacción a la operación.','stop')
		ROLLBACK WORK	
		EXIT PROGRAM
	WHEN -1
		SET LOCK MODE TO WAIT
		WHILE num_tran = -1
			IF num_tran <> -1 THEN
				EXIT WHILE
			END IF
			CALL fl_actualiza_control_secuencias(vg_codcia,
							vg_codloc, vg_modulo,
							rm_r00.r00_bodega_fact,
							rm_r19.r19_cod_tran)
				RETURNING num_tran
		END WHILE
		SET LOCK MODE TO NOT WAIT
END CASE
LET rm_r19.r19_num_tran    = num_tran
LET rm_r19.r19_moneda      = "DO"
LET rm_r19.r19_bodega_dest = rm_r19.r19_bodega_ori
LET rm_r19.r19_fecing      = CURRENT
LET rm_r19.r19_usuario     = "FOBOS"
INSERT INTO rept019 VALUES (rm_r19.*)

END FUNCTION



FUNCTION control_ingreso_detalle()
DEFINE j 		SMALLINT
DEFINE rart		RECORD LIKE rept010.*

LET rm_r20.r20_compania   = vg_codcia
LET rm_r20.r20_localidad  = vg_codloc
LET rm_r20.r20_cod_tran   = rm_r19.r19_cod_tran
LET rm_r20.r20_num_tran   = rm_r19.r19_num_tran
LET rm_r20.r20_linea      = linea
LET rm_r20.r20_stock_bd   = 0
LET rm_r20.r20_cant_ent   = 0 
LET rm_r20.r20_cant_dev   = 0
LET rm_r20.r20_descuento  = 0.0
LET rm_r20.r20_val_descto = 0.0
LET rm_r20.r20_val_impto  = 0.0
LET rm_r20.r20_fob        = 0.0
LET rm_r20.r20_ubicacion  = ' '
FOR j = 1 TO vm_num_detalles
	CALL fl_lee_item(vg_codcia, rm_aj_exist[j].r20_item)
		RETURNING rart.*
	LET rm_r20.r20_cant_ped   = rm_aj_exist[j].r20_stock_ant 
	LET rm_r20.r20_cant_ven   = rm_aj_exist[j].r20_stock_ant 
	LET rm_r20.r20_stock_ant  = rm_aj_exist[j].r20_cant_ven
	LET rm_r20.r20_bodega     = rm_r19.r19_bodega_ori
	LET rm_r20.r20_item       = rm_aj_exist[j].r20_item 
	LET rm_r20.r20_orden      = j
	LET rm_r20.r20_linea      = rart.r10_linea
	LET rm_r20.r20_rotacion   = rart.r10_rotacion 
	LET rm_r20.r20_precio     = rart.r10_precio_mb
	LET rm_r20.r20_costo      = rart.r10_costo_mb
	LET rm_r20.r20_costant_mb = rart.r10_costult_mb
	LET rm_r20.r20_costnue_mb = rart.r10_costo_mb
	LET rm_r20.r20_costant_ma = rart.r10_costult_ma
	LET rm_r20.r20_costnue_ma = rart.r10_costo_ma
	LET rm_r20.r20_fecing     = CURRENT
	INSERT INTO rept020 VALUES(rm_r20.*)
END FOR 

END FUNCTION




FUNCTION control_actualizacion_existencia()
DEFINE j		SMALLINT
DEFINE mensaje		VARCHAR(200)

FOR j = 1 TO vm_num_detalles
	CASE rm_r19.r19_cod_tran
		WHEN vm_ajuste_mas
			IF rm_aj_exist[j].r20_stock_ant <= 0 THEN
				DELETE FROM rept011
					WHERE r11_compania = vg_codcia
					AND   r11_bodega = rm_r19.r19_bodega_ori
					AND   r11_item = rm_aj_exist[j].r20_item
				INSERT INTO rept011
			 		(r11_compania, r11_bodega, r11_item, 
					 r11_ubicacion, r11_stock_ant, 
					 r11_stock_act, r11_ing_dia,
					 r11_egr_dia)
					VALUES(vg_codcia, rm_r19.r19_bodega_ori,
					       rm_aj_exist[j].r20_item, 'SN', 
					       0, rm_aj_exist[j].r20_cant_ven, 
					       rm_aj_exist[j].r20_cant_ven,0) 
			ELSE	 
				UPDATE rept011 
					SET r11_stock_ant = r11_stock_act,
					    r11_stock_act =
						rm_aj_exist[j].r20_cant_ven,
					    r11_ing_dia   =
						rm_aj_exist[j].r20_cant_ven
					WHERE r11_compania = vg_codcia
					  AND r11_bodega   =
							rm_r19.r19_bodega_ori
					  AND r11_item     =
							rm_aj_exist[j].r20_item 
			END IF
		WHEN vm_ajuste_menos
			{--
			CALL fl_lee_stock_rep(vg_codcia, rm_r19.r19_bodega_ori,
     					      rm_aj_exist[j].r20_item)
				RETURNING rm_r11.*
			IF rm_r11.r11_stock_act < rm_aj_exist[j].r20_cant_ven
			THEN
				LET mensaje = 'Ha ocurrido una disminución en el stoctk del item ', rm_r20.r20_item CLIPPED, ' Stock Actual ', rm_r11.r11_stock_act USING "#,##&.##", ' Cant. Ajustar ', rm_aj_exist[j].r20_cant_ven USING "#,##&.##", '. No se puede realizar la transacción.'
				CALL fl_mostrar_mensaje(mensaje, 'exclamation')
				ROLLBACK WORK
				EXIT PROGRAM
			END IF
			--}
			UPDATE rept011 
				SET r11_stock_act = rm_aj_exist[j].r20_cant_ven,
				    r11_egr_dia   = rm_aj_exist[j].r20_cant_ven
				WHERE r11_compania = vg_codcia
				  AND r11_bodega   = rm_r19.r19_bodega_ori
				  AND r11_item     = rm_aj_exist[j].r20_item
	END CASE
	WHENEVER ERROR STOP
	IF status < 0 THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('Registro está siendo modificado por otro usuario, desea intentarlo nuevamente','stop')
		EXIT PROGRAM
	END IF
END FOR

END FUNCTION



FUNCTION calcular_total()
DEFINE k 	SMALLINT

LET vm_total = 0
FOR k = 1 TO vm_num_detalles
	LET rm_aj_exist[k].total = rm_aj_exist[k].r10_costo_mb *						   rm_aj_exist[k].r20_cant_ven
	LET vm_total             = vm_total + rm_aj_exist[k].total
END FOR

END FUNCTION



FUNCTION obtener_saldo_real_item()
DEFINE i, j, l	 	SMALLINT
DEFINE query         	CHAR(600)
DEFINE fec_ini		LIKE rept020.r20_fecing
DEFINE bodega		LIKE rept019.r19_bodega_ori
DEFINE division		LIKE rept003.r03_codigo
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE r_g21		RECORD LIKE gent021.*
DEFINE valor, valor2	DECIMAL(10,2)

INITIALIZE vm_bodega, vm_fecha_desde, vm_fecha_hasta TO NULL
LET vm_fecha_desde   = MDY(01, 01, 2003)
LET vm_fecha_hasta   = TODAY
LET vm_stock_inicial = NULL
LET vm_bodega        = vm_bod_sstock
DECLARE q_caca3 CURSOR FOR SELECT * FROM tmp_sinstock
FOR i = 1 TO vm_max_det
	INITIALIZE r_detalle[i].* TO NULL
END FOR
LET l = 0
FOREACH q_caca3 INTO r_r11.*, division, j
	LET vm_num_det = 0
	CALL control_consulta(r_r11.r11_item)
	IF vm_num_det = 0 THEN
		LET fec_ini = EXTEND(vm_fecha_desde, YEAR TO SECOND)
		LET query = 'SELECT rept020.*, rept019.*, gent021.* ' ,
				' FROM rept020, rept019, gent021 ',
				' WHERE r20_compania  = ',vg_codcia,
				'   AND r20_localidad = ',vg_codloc,
				'   AND r20_item      = "',r_r11.r11_item,'"',
				'   AND r20_fecing   <= "',fec_ini,'"',
				'   AND r20_compania  = r19_compania ',
				'   AND r20_localidad = r19_localidad ',
				'   AND r20_cod_tran  = r19_cod_tran ',
				'   AND r20_num_tran  = r19_num_tran ',
				'   AND r20_cod_tran  = g21_cod_tran ',
				' ORDER BY r20_fecing DESC'
		PREPARE cons_stock FROM query
		DECLARE q_sto CURSOR FOR cons_stock
		LET vm_stock_inicial = 0
		OPEN q_sto
		FETCH q_sto INTO r_r20.*, r_r19.*, r_g21.*
		IF STATUS <> NOTFOUND THEN
			LET bodega = vm_bodega
			CASE
				WHEN(r_g21.g21_tipo = 'I')
					LET bodega = r_r20.r20_bodega
				WHEN(r_g21.g21_tipo = 'E')
					LET bodega = r_r20.r20_bodega
				WHEN(r_g21.g21_tipo = 'T')
					IF vm_bodega = r_r19.r19_bodega_ori THEN
						LET bodega =r_r19.r19_bodega_ori
					END IF
					IF vm_bodega= r_r19.r19_bodega_dest THEN
						LET bodega=r_r19.r19_bodega_dest
					END IF
			END CASE
			IF r_g21.g21_tipo <> 'T' THEN
				IF r_g21.g21_tipo = 'E' THEN
					LET r_r20.r20_cant_ven =
						r_r20.r20_cant_ven * (-1)
				END IF
				LET vm_stock_inicial = r_r20.r20_stock_ant
							+ r_r20.r20_cant_ven
			ELSE
				IF bodega = r_r19.r19_bodega_ori THEN
					LET vm_stock_inicial=r_r20.r20_stock_ant
							- r_r20.r20_cant_ven
				END IF
				IF bodega = r_r19.r19_bodega_dest THEN
					LET vm_stock_inicial =r_r20.r20_stock_bd
							+ r_r20.r20_cant_ven
				END IF
			END IF
		END IF
		EXIT PROGRAM
	END IF
	IF r_detalle[vm_num_det].saldo IS NULL THEN
		CONTINUE FOREACH
	END IF
	LET valor = r_r11.r11_stock_act - r_detalle[vm_num_det].saldo
	IF r_r11.r11_stock_act = 0 THEN
		LET valor = r_detalle[vm_num_det].saldo
	END IF
	LET valor  = valor * (-1)
	LET valor2 = valor
	IF valor2 < 0 THEN
		LET valor2 = valor2 * (-1)
	END IF
	LET valor2 = valor2 + r_detalle[vm_num_det].saldo
	IF valor > 0 THEN
		LET j = 1
	END IF
	IF valor < 0 THEN
		LET j = 2
	END IF
	UPDATE tmp_sinstock SET r11_stock_ant = valor2,
				r11_stock_act = valor,
				flag_tipo_aj  = j
		WHERE r11_compania   = r_r11.r11_compania
		  AND r11_bodega     = r_r11.r11_bodega
		  AND r11_item       = r_r11.r11_item
	DISPLAY 'Act. Stock Item: ', r_r11.r11_item CLIPPED,
		' con Stock Trans. con ', valor USING "--,--&.##", ' y kardex ',
		r_detalle[vm_num_det].saldo USING "--,--&.##", ' j = ',
		j USING "&"
	LET l = l + 1
	FOR i = 1 TO vm_num_det
		INITIALIZE r_detalle[i].* TO NULL
	END FOR
END FOREACH
DISPLAY 'Cuadro ', l USING "##&", ' Itmes OK.'
SELECT COUNT(*) INTO l FROM tmp_sinstock WHERE r11_stock_act = 0
DISPLAY 'Items con Stock = 0, hay ', l USING "##&", ' OK.'
DELETE FROM tmp_sinstock WHERE r11_stock_act = 0

END FUNCTION



FUNCTION control_consulta(item)
DEFINE item		LIKE rept010.r10_codigo
DEFINE query         	CHAR(600)
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_g21		RECORD LIKE gent021.*
DEFINE i		SMALLINT
DEFINE saldo		DECIMAL (8,2)
DEFINE bodega		LIKE rept019.r19_bodega_ori
DEFINE fec_ini		LIKE rept020.r20_fecing
DEFINE fec_fin		LIKE rept020.r20_fecing

LET fec_ini = EXTEND(vm_fecha_desde, YEAR TO SECOND)
LET fec_fin = EXTEND(vm_fecha_hasta, YEAR TO SECOND) + 23 UNITS HOUR +
	      59 UNITS MINUTE + 59 UNITS SECOND  
LET query = 'SELECT rept020.*, rept019.*, gent021.* ' ,
		' FROM rept020, rept019, gent021 ',
		' WHERE r20_compania  = ',vg_codcia,
		'   AND r20_localidad = ',vg_codloc,
		'   AND r20_item      = "',item,'"',
		'   AND r20_fecing ',
		'BETWEEN "',fec_ini,'" AND "',fec_fin,'"',
		'   AND r20_compania  = r19_compania ',
		'   AND r20_localidad = r19_localidad ',
		'   AND r20_cod_tran  = r19_cod_tran ',
		'   AND r20_num_tran  = r19_num_tran ',
		'   AND r20_cod_tran  = g21_cod_tran ',
		' ORDER BY r20_fecing '
PREPARE consulta FROM query
DECLARE q_consulta CURSOR FOR consulta
LET i = 1
LET vm_tot_ing = 0
LET vm_tot_egr = 0
LET saldo      = 0
FOREACH q_consulta INTO r_r20.*, r_r19.*, r_g21.*
	LET bodega = "**"
	CASE
		WHEN(r_g21.g21_tipo = 'I')
			LET bodega = r_r20.r20_bodega
		WHEN(r_g21.g21_tipo = 'E')
			LET bodega = r_r20.r20_bodega
		WHEN(r_g21.g21_tipo = 'T')
			IF vm_bodega = r_r19.r19_bodega_ori THEN
				LET bodega = r_r19.r19_bodega_ori
			END IF
			IF vm_bodega = r_r19.r19_bodega_dest THEN
				LET bodega = r_r19.r19_bodega_dest
			END IF
	END CASE
	IF vm_bodega <> bodega THEN
		CONTINUE FOREACH
	END IF
	IF i = 1 THEN
		IF r_g21.g21_tipo <> 'T' THEN
			LET vm_stock_inicial = r_r20.r20_stock_ant
		ELSE
			IF bodega = r_r19.r19_bodega_ori THEN
				LET vm_stock_inicial = r_r20.r20_stock_ant
			END IF
			IF bodega = r_r19.r19_bodega_dest THEN
				LET vm_stock_inicial = r_r20.r20_stock_bd
			END IF
		END IF
		LET saldo = vm_stock_inicial
	END IF
	LET r_detalle[i].r20_cod_tran = r_r20.r20_cod_tran
	LET r_detalle[i].r20_num_tran = r_r20.r20_num_tran
	LET r_detalle[i].fecha        = DATE(r_r20.r20_fecing)
	LET r_detalle[i].cliente      = r_r19.r19_nomcli
	IF r_r19.r19_nomcli IS NULL OR r_r19.r19_nomcli = ' ' THEN
		LET r_detalle[i].cliente = r_r19.r19_referencia
	END IF
	CASE
		WHEN(r_g21.g21_tipo = 'I')
			LET r_detalle[i].cant_egr = 0
			LET r_detalle[i].cant_ing = r_r20.r20_cant_ven

			LET r_detalle[i].saldo    = r_r20.r20_cant_ven + 
						    saldo
			LET vm_tot_ing            = vm_tot_ing + 
						    r_r20.r20_cant_ven
		WHEN(r_g21.g21_tipo = 'E')
			LET r_detalle[i].cant_egr = r_r20.r20_cant_ven
			LET r_detalle[i].cant_ing = 0
			LET r_detalle[i].saldo    = saldo  -
						    r_r20.r20_cant_ven  
			LET vm_tot_egr            = vm_tot_egr + 
						    r_r20.r20_cant_ven
		WHEN(r_g21.g21_tipo = 'C')
			LET r_detalle[i].cant_egr = 0
			LET r_detalle[i].cant_ing = 0

			LET r_detalle[i].saldo    = saldo
		WHEN(r_g21.g21_tipo = 'T')
			IF vm_bodega = r_r19.r19_bodega_ori THEN
				LET r_detalle[i].cant_egr = r_r20.r20_cant_ven
				LET r_detalle[i].cant_ing = 0
				LET r_detalle[i].saldo    = saldo - 
							    r_r20.r20_cant_ven 
				LET vm_tot_egr            = vm_tot_egr + 
							    r_r20.r20_cant_ven
			END IF
			IF vm_bodega = r_r19.r19_bodega_dest THEN
				LET r_detalle[i].cant_egr = 0
				LET r_detalle[i].cant_ing = r_r20.r20_cant_ven
				LET r_detalle[i].saldo    = r_r20.r20_cant_ven+ 
							    saldo
				LET vm_tot_ing            = vm_tot_ing + 
							    r_r20.r20_cant_ven
			END IF
	END CASE
	LET saldo = r_detalle[i].saldo
	LET i = i + 1
	IF i > vm_max_det THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_det = i - 1

END FUNCTION
