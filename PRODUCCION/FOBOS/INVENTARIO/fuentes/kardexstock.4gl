DATABASE aceros


DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE fec_i, fec_f	LIKE rept020.r20_fecing
DEFINE base		CHAR(20)

DEFINE vm_bodega	LIKE rept019.r19_bodega_ori
DEFINE vm_stock_inicial	LIKE rept011.r11_stock_act
DEFINE vm_tot_ing	LIKE rept011.r11_stock_act
DEFINE vm_tot_egr	LIKE rept011.r11_stock_act
DEFINE r_detalle	ARRAY[4000] OF RECORD
				r20_cod_tran	LIKE rept019.r19_cod_tran,
				r20_num_tran	LIKE rept019.r19_num_tran,
				fecha		DATE,
				cliente		LIKE cxct001.z01_nomcli,
				cant_ing	LIKE rept011.r11_stock_act,
				cant_egr	LIKE rept011.r11_stock_act,
				saldo		LIKE rept011.r11_stock_act
			END RECORD
DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT



MAIN

	IF num_args() <> 1 THEN
		DISPLAY 'Error de Parametros. Falta la Localidad.'
		EXIT PROGRAM
	END IF
	LET codcia = 1
	LET codloc = arg_val(1)
	CASE codloc
		WHEN 1
			LET base = 'acero_gm'
		WHEN 2
			LET base = 'acero_gc'
		WHEN 3
			LET base = 'acero_qm'
		WHEN 4
			LET base = 'acero_qs'
	END CASE
	CALL activar_base()
	CALL validar_parametros()
	LET fec_i = EXTEND(MDY(04, 27, 2005), YEAR TO SECOND)
	LET fec_f = EXTEND(MDY(05, 05, 2005), YEAR TO SECOND) + 23 UNITS HOUR +
			59 UNITS MINUTE + 59 UNITS SECOND  
	LET vm_max_det = 4000
	CALL ejecuta_proceso()

END MAIN



FUNCTION activar_base()
DEFINE r_g51		RECORD LIKE gent051.*

CLOSE DATABASE
WHENEVER ERROR CONTINUE
DATABASE base
IF STATUS < 0 THEN
	DISPLAY 'No se pudo abrir base de datos: ', base
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
INITIALIZE r_g51.* TO NULL
SELECT * INTO r_g51.* FROM gent051
	WHERE g51_basedatos = base
IF r_g51.g51_basedatos IS NULL THEN
	DISPLAY 'No existe base de datos: ', base
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION validar_parametros()
DEFINE r_g02		RECORD LIKE gent002.*

INITIALIZE r_g02.* TO NULL
SELECT * INTO r_g02.* FROM gent002
	WHERE g02_compania  = codcia
	  AND g02_localidad = codloc
IF r_g02.g02_compania IS NULL THEN
	DISPLAY 'No existe la Localidad ', codloc USING '<<&', '.'
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION ejecuta_proceso()
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE i		SMALLINT

DISPLAY 'Ejecutando Chequeo por favor espere ...'
DECLARE q_ajust CURSOR FOR
	SELECT * FROM rept020
		WHERE r20_compania  = codcia
		  AND r20_localidad = codloc
		  AND r20_cod_tran  IN ('A+', 'A-')
		  AND r20_fecing    BETWEEN fec_i AND fec_f
		ORDER BY r20_num_tran, r20_orden
LET i = 0
FOREACH q_ajust INTO r_r20.*
	INITIALIZE r_r11.* TO NULL
	SELECT * INTO r_r11.* FROM rept011
		WHERE r11_compania = r_r20.r20_compania
		  AND r11_bodega   = r_r20.r20_bodega
		  AND r11_item     = r_r20.r20_item
	LET vm_bodega = r_r20.r20_bodega
	CALL control_consulta_detalle(r_r20.r20_item)
	IF r_detalle[vm_num_det].saldo = r_r11.r11_stock_act THEN
		CONTINUE FOREACH
	END IF
	DISPLAY 'EL Item ', r_r11.r11_item CLIPPED, ' en bodega ',
		r_r20.r20_bodega CLIPPED, ' con stock act. ',
		r_r11.r11_stock_act USING "##,##&.##", ' saldo fin. kardex ',
		r_detalle[vm_num_det].saldo USING "##,##&.##"
	LET i = i + 1
END FOREACH
DISPLAY 'Total Item con descuadre ', i USING "<<<<&"
DISPLAY 'Chequeo Terminado OK.'

END FUNCTION



FUNCTION control_consulta_detalle(item)
DEFINE item		LIKE rept010.r10_codigo
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_g21		RECORD LIKE gent021.*
DEFINE bodega		LIKE rept019.r19_bodega_ori
DEFINE query         	CHAR(1200)
DEFINE saldo		DECIMAL (8,2)
DEFINE i		SMALLINT

LET query = 'SELECT rept020.*, rept019.*, gent021.* ' ,
		' FROM rept020, rept019, gent021 ',
		' WHERE r20_compania  = ', codcia,
		'   AND r20_localidad = ', codloc,
		'   AND r20_item      = "', item, '"',
		'   AND r20_fecing    BETWEEN "', fec_i, '"',
					' AND "', fec_f, '"',
		'   AND r20_compania  = r19_compania ',
		'   AND r20_localidad = r19_localidad ',
		'   AND r20_cod_tran  = r19_cod_tran ',
		'   AND r20_num_tran  = r19_num_tran ',
		'   AND r20_cod_tran  = g21_cod_tran ',
		' ORDER BY r20_fecing '
PREPARE consulta FROM query
DECLARE q_consulta CURSOR FOR consulta
LET i          = 1
LET vm_tot_ing = 0
LET vm_tot_egr = 0
LET saldo      = 0
FOREACH q_consulta INTO r_r20.*, r_r19.*, r_g21.*
	LET bodega = "**"
	IF r_g21.g21_tipo = 'T' THEN
		IF vm_bodega = r_r19.r19_bodega_ori THEN
			LET bodega = r_r19.r19_bodega_ori
		END IF
		IF vm_bodega = r_r19.r19_bodega_dest THEN
			LET bodega = r_r19.r19_bodega_dest
		END IF
	ELSE
		IF r_g21.g21_tipo <> 'C' THEN
			LET bodega = r_r20.r20_bodega
		END IF
	END IF
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
			LET r_detalle[i].saldo    = r_r20.r20_cant_ven + saldo
			LET vm_tot_ing            = vm_tot_ing +
							r_r20.r20_cant_ven
		WHEN(r_g21.g21_tipo = 'E')
			LET r_detalle[i].cant_egr = r_r20.r20_cant_ven
			LET r_detalle[i].cant_ing = 0
			LET r_detalle[i].saldo    = saldo - r_r20.r20_cant_ven
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
				LET r_detalle[i].saldo    = r_r20.r20_cant_ven +
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
