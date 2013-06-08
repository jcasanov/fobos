DATABASE aceros



GLOBALS '../../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'


DEFINE rm_r00		RECORD LIKE rept000.*	-- CONFIGURACION DE LA
DEFINE rm_r01		RECORD LIKE rept001.*
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
	
CALL startlog('ajuste99.err')
IF num_args() <> 2 THEN
	DISPLAY 'Parametros Incorrectos. Son: BASE y LOCALIDAD.'
	EXIT PROGRAM
END IF
LET vg_base   = arg_val(1)
LET vg_modulo = "RE"
LET vg_codcia = 1
LET vg_codloc = arg_val(2)
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
		  AND r02_localidad = vg_codloc
		  AND r02_estado    = "A"                                      
		  AND r02_tipo      = "S"                                       
		  AND r02_area      = "R"                                       
IF vm_bod_sstock IS NULL THEN
	DISPLAY 'No existe una Bodega sin Stock.'
	EXIT PROGRAM
END IF
LET vm_max_det = 1000
CALL obtener_items()
call muestra_tmp(1)
CALL obtener_items_ajustar()
call muestra_tmp(2)
INITIALIZE linea TO NULL
BEGIN WORK
	CALL ejecuta_proceso(1)
	CALL ejecuta_proceso(2)
COMMIT WORK
DROP TABLE tmp_sinstock
DISPLAY 'Proceso Terminado OK.'

END FUNCTION



function muestra_tmp(flag)
define flag		smallint
define r_r11		record like rept011.*
define i, j		smallint

declare q_caca cursor for
	select r11_item, r11_stock_act, r11_stock_ant, flag_tipo_aj
		from tmp_sinstock
		order by 2 desc
display 'Comienzo ...'
let i = 0
foreach q_caca into r_r11.r11_item, r_r11.r11_stock_act, r_r11.r11_stock_ant, j
	display r_r11.r11_item using "######", '  ',
		r_r11.r11_stock_act using "---,--&.##", '  ',
		r_r11.r11_stock_ant using "---,--&.##", '   Tipo AJ = ',
		j using "&"
	let i = i + 1
end foreach
display 'Total de Items: ', i using "##,##&"
display '...'
display ''
if flag = 2 then
	exit program
end if

end function



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
		  AND r19_tipo_dev                IS NULL
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

INITIALIZE rm_r19.*, rm_r20.* TO NULL
DECLARE q_items CURSOR FOR
	SELECT * FROM tmp_sinstock
		WHERE flag_tipo_aj = flag_aj
		  AND divis        = linea
LET vm_num_detalles = 1
FOREACH q_items INTO r_r11.*, division, j
	LET rm_aj_exist[vm_num_detalles].r20_cant_ven  = r_r11.r11_stock_ant -
							 r_r11.r11_stock_act
	IF rm_aj_exist[vm_num_detalles].r20_cant_ven < 0 THEN
		LET rm_aj_exist[vm_num_detalles].r20_cant_ven =
			rm_aj_exist[vm_num_detalles].r20_cant_ven * (-1)
	END IF
	LET rm_aj_exist[vm_num_detalles].r20_stock_ant = r_r11.r11_stock_ant
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
LET rm_r19.r19_referencia = 'AJ. PARA CUADRAR DESFASE BD-79 CENTRO.'
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
	LET rm_r20.r20_cant_ped   = rm_aj_exist[j].r20_cant_ven 
	LET rm_r20.r20_cant_ven   = rm_aj_exist[j].r20_cant_ven 
	LET rm_r20.r20_stock_ant  = rm_aj_exist[j].r20_stock_ant
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
DEFINE r_r11		RECORD LIKE rept011.*

FOR j = 1 TO vm_num_detalles
	SELECT r11_stock_act, r11_stock_ant
		INTO r_r11.r11_stock_act, r_r11.r11_stock_ant
		FROM tmp_sinstock
		WHERE r11_compania = vg_codcia
		  AND r11_bodega   = vm_bod_sstock
		  AND r11_item     = rm_aj_exist[j].r20_item
	CASE rm_r19.r19_cod_tran
		WHEN vm_ajuste_mas
			UPDATE rept011 
				SET r11_stock_ant = r_r11.r11_stock_ant,
				    r11_stock_act = r_r11.r11_stock_act,
				    r11_ing_dia   = rm_aj_exist[j].r20_cant_ven
				WHERE r11_compania = vg_codcia
				  AND r11_bodega   = rm_r19.r19_bodega_ori
				  AND r11_item     = rm_aj_exist[j].r20_item 
		WHEN vm_ajuste_menos
			UPDATE rept011 
				SET r11_stock_ant = r_r11.r11_stock_ant,
				    r11_stock_act = r_r11.r11_stock_act,
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



FUNCTION obtener_items_ajustar()
DEFINE j	 	SMALLINT
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE stock_act	LIKE rept011.r11_stock_act
DEFINE stock_ant	LIKE rept011.r11_stock_ant

DELETE FROM tmp_sinstock WHERE r11_stock_act = r11_stock_ant
DECLARE q_caca3 CURSOR FOR
	SELECT r11_item, r11_stock_act, r11_stock_ant FROM tmp_sinstock
FOREACH q_caca3 INTO r_r11.r11_item, r_r11.r11_stock_act, r_r11.r11_stock_ant
	LET stock_ant = r_r11.r11_stock_ant * (-1)
	LET stock_act = r_r11.r11_stock_act * (-1)
	IF stock_act > stock_ant THEN
		LET j = 2
	ELSE
		LET j = 1
	END IF
	UPDATE tmp_sinstock SET flag_tipo_aj = j
		WHERE r11_compania = vg_codcia
		  AND r11_bodega   = vm_bod_sstock
		  AND r11_item     = r_r11.r11_item
END FOREACH

END FUNCTION
