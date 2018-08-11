DATABASE aceros



GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'



DEFINE rm_r20		RECORD LIKE rept020.*
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

CALL startlog('reproc79.err')
IF num_args() <> 2 THEN
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto. Son: BASE y LOCALIDAD.','stop')
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
DEFINE i	 	SMALLINT
DEFINE query         	CHAR(600)
DEFINE fec_ini		LIKE rept020.r20_fecing
DEFINE bodega		LIKE rept019.r19_bodega_ori
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE r_g21		RECORD LIKE gent021.*

CALL fl_nivel_isolation()
LET vm_max_det = 1000
LET vm_num_det = 0
INITIALIZE rm_r20.*, vm_bodega, vm_fecha_desde, vm_fecha_hasta TO NULL
LET vm_fecha_desde   = MDY(01, 01, 2003)
LET vm_fecha_hasta   = TODAY
LET vm_stock_inicial = NULL
LET rm_r20.r20_item  = '490'
LET vm_bodega        = '79'
--WHILE TRUE
	FOR i = 1 TO vm_num_det
		INITIALIZE r_detalle[i].* TO NULL
	END FOR
	CALL control_consulta()
	IF vm_num_det = 0 THEN
		LET fec_ini = EXTEND(vm_fecha_desde, YEAR TO SECOND)
		LET query = 'SELECT rept020.*, rept019.*, gent021.* ' ,
				' FROM rept020, rept019, gent021 ',
				' WHERE r20_compania  = ',vg_codcia,
				'   AND r20_localidad = ',vg_codloc,
				'   AND r20_item      = "',rm_r20.r20_item,'"',
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
--END WHILE

END FUNCTION



FUNCTION control_consulta()
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
		'   AND r20_item      = "',rm_r20.r20_item,'"',
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
		DISPLAY vm_stock_inicial		-- OJO NPC
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
