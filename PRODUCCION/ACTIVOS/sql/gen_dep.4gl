DATABASE aceros


DEFINE vg_codcia	LIKE actt010.a10_compania
DEFINE vg_activo	LIKE actt010.a10_codigo_bien
DEFINE vm_cod_tran1	LIKE actt012.a12_codigo_tran
DEFINE ano_ini, mes_ini	SMALLINT
DEFINE ano_fin, mes_fin	SMALLINT



MAIN

IF num_args() <> 7 THEN
        DISPLAY 'Número de parametros incorrecto.'
	DISPLAY '  SON BASE COMPAÑÍA EL BIEN AÑO_INI MES_INI AÑO_FIN MES_FIN.'
        EXIT PROGRAM
END IF
CALL activar_base_datos(arg_val(1))
LET vg_codcia = arg_val(2)
LET vg_activo = arg_val(3)
LET ano_ini   = arg_val(4)
LET mes_ini   = arg_val(5)
LET ano_fin   = arg_val(6)
LET mes_fin   = arg_val(7)
CALL funcion_master()  

END MAIN



FUNCTION activar_base_datos(base)
DEFINE base		CHAR(20)
DEFINE r_cia		RECORD LIKE gent001.*
DEFINE r_loc		RECORD LIKE gent002.*

CLOSE DATABASE 
WHENEVER ERROR CONTINUE
DATABASE base
IF STATUS < 0 THEN
	DISPLAY 'No se pudo abrir base de datos: ', base CLIPPED
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
SELECT * FROM gent051 WHERE g51_basedatos = base
IF STATUS = NOTFOUND THEN
	DISPLAY 'No se pudo abrir base de datos: ', base CLIPPED
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION funcion_master()

LET vm_cod_tran1 = 'DP'
BEGIN WORK
	IF NOT control_depreciacion() THEN
		WHENEVER ERROR STOP
		ROLLBACK WORK
		RETURN
	END IF
COMMIT WORK
DISPLAY 'Activo Fijo DEPRECIADO Ok.'

END FUNCTION



FUNCTION bloqueo_bien(activo)
DEFINE activo		LIKE actt010.a10_codigo_bien
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE resul		SMALLINT

LET resul = 0
SET LOCK MODE TO WAIT 3
WHENEVER ERROR CONTINUE
WHILE TRUE
	DECLARE q_ab CURSOR FOR
		SELECT * FROM actt010
			WHERE a10_compania    = vg_codcia
			  AND a10_codigo_bien = activo
			FOR UPDATE
	OPEN q_ab
	FETCH q_ab INTO r_a10.*
	IF STATUS = 0 THEN
		LET resul = 1
		EXIT WHILE
	END IF
	IF STATUS < 0 THEN
		IF muestra_mensaje_error_continuar_act(activo, '10',
						'actualizar', 'actualización')
		THEN
			CLOSE q_ab
			FREE q_ab
			CONTINUE WHILE
		END IF
	END IF
	IF STATUS = NOTFOUND THEN
		IF muestra_mensaje_error_continuar_act(activo, '10',
						'encontrar', 'búsqueda')
		THEN
			CLOSE q_ab
			FREE q_ab
			CONTINUE WHILE
		END IF
	END IF
	EXIT WHILE
END WHILE
SET LOCK MODE TO NOT WAIT
WHENEVER ERROR STOP
RETURN resul, r_a10.*

END FUNCTION



FUNCTION control_depreciacion()
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE num_tran		LIKE actt012.a12_numero_tran
DEFINE fin_mes, fecha	DATE
DEFINE resul		SMALLINT
DEFINE mensaje		VARCHAR(200)
DEFINE valor		DECIMAL(14,2)

CALL bloqueo_bien(vg_activo) RETURNING resul, r_a10.*
IF NOT resul THEN
	RETURN 0
END IF
LET fin_mes = MDY(mes_ini, 01, ano_ini) + 1 UNITS MONTH - 1 UNITS DAY
IF fin_mes > TODAY THEN
	RETURN 1
END IF
LET resul  = 0
FOREACH q_ab INTO r_a10.*
	WHILE TRUE
		CALL generar_depreciacion(fin_mes, r_a10.*)
			RETURNING resul, num_tran, valor
		LET mensaje = 'Depreciación Generada: ', num_tran USING "<<<&&",
				' Periodo: ', YEAR(fin_mes) USING "&&&&", '/',
				MONTH(fin_mes) USING "&&", ' ',
				valor USING "--,---,--&.##"
		DISPLAY mensaje CLIPPED
		IF NOT resul THEN
			EXIT WHILE
		END IF
		LET fecha  = MDY(MONTH(fin_mes), 01, YEAR(fin_mes))
				+ 1 UNITS MONTH
		CALL retorna_fecha_dep(fecha) RETURNING fin_mes
		IF fin_mes > (MDY(mes_fin, 01, ano_fin) + 1 UNITS MONTH) THEN
			EXIT WHILE
		END IF
	END WHILE
END FOREACH
RETURN resul

END FUNCTION



FUNCTION generar_depreciacion(fin_mes, r_a10)
DEFINE fin_mes		DATE
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE r_a01		RECORD LIKE actt001.*
DEFINE r_a11		RECORD LIKE actt011.*
DEFINE r_a12		RECORD LIKE actt012.*
DEFINE r_a13		RECORD LIKE actt013.*
DEFINE r_a14		RECORD LIKE actt014.*
DEFINE r_a13_ant	RECORD LIKE actt013.*
DEFINE r_a14_ant	RECORD LIKE actt014.*
DEFINE val_dep, tot_dep	DECIMAL(14,2)
DEFINE dif             	DECIMAL(14,2)
DEFINE dias		INTEGER
DEFINE fin_deprec	DATE
DEFINE mes, anio	SMALLINT
DEFINE i, j		SMALLINT

INITIALIZE r_a10.* TO NULL
SELECT * INTO r_a10.*
	FROM actt010
	WHERE a10_compania    = vg_codcia
	  AND a10_codigo_bien = vg_activo
LET fin_deprec = r_a10.a10_fecha_comp + r_a10.a10_anos_util UNITS YEAR
LET dias       = fin_mes - r_a10.a10_fecha_comp
IF YEAR(r_a10.a10_fecha_comp)  = YEAR(fin_mes) AND
   MONTH(r_a10.a10_fecha_comp) = MONTH(fin_mes)
THEN
	LET r_a10.a10_val_dep_mb = (r_a10.a10_val_dep_mb * dias) / DAY(fin_mes)
END IF
IF YEAR(fin_deprec) = YEAR(fin_mes) AND MONTH(fin_deprec) = MONTH(fin_mes) THEN
	LET r_a10.a10_val_dep_mb = r_a10.a10_valor_mb - r_a10.a10_tot_dep_mb
END IF
IF r_a10.a10_val_dep_mb > r_a10.a10_valor_mb - r_a10.a10_tot_dep_mb THEN
	LET r_a10.a10_val_dep_mb = r_a10.a10_valor_mb - r_a10.a10_tot_dep_mb
END IF
INITIALIZE r_a01.* TO NULL
SELECT * INTO r_a01.*
	FROM actt001
	WHERE a01_compania  = r_a01.a01_compania
	  AND a01_grupo_act = r_a01.a01_grupo_act
DECLARE q_dpto CURSOR FOR
	SELECT * FROM actt011
		WHERE a11_compania    = r_a10.a10_compania
		  AND a11_codigo_bien = r_a10.a10_codigo_bien
LET j = 0
FOREACH q_dpto INTO r_a11.*
	LET j = j + 1
END FOREACH
LET i       = 0
LET tot_dep = 0
FOREACH q_dpto INTO r_a11.*
	INITIALIZE r_g34.* TO NULL
	SELECT * INTO r_g34.*
		FROM gent034
		WHERE g34_compania  = r_a10.a10_compania
		  AND g34_cod_depto = r_a11.a11_cod_depto
	LET i       = i + 1	
	LET val_dep = r_a10.a10_val_dep_mb * r_a11.a11_porcentaje / 100
	LET tot_dep = tot_dep + val_dep 
	IF i = j THEN
		LET dif     = r_a10.a10_val_dep_mb - tot_dep
		LET tot_dep = tot_dep - val_dep
		LET val_dep = val_dep + dif
		LET tot_dep = tot_dep + val_dep
	END IF
END FOREACH
IF i = 0 THEN
	INITIALIZE r_g34.* TO NULL
	SELECT * INTO r_g34.*
		FROM gent034
		WHERE g34_compania  = r_a10.a10_compania
		  AND g34_cod_depto = r_a10.a10_cod_depto
END IF          			    
LET r_a10.a10_tot_dep_mb = r_a10.a10_tot_dep_mb + r_a10.a10_val_dep_mb
IF r_a10.a10_valor_mb = r_a10.a10_tot_dep_mb THEN
	LET r_a10.a10_estado = 'D'
END IF
UPDATE actt010
	SET a10_tot_dep_mb = r_a10.a10_tot_dep_mb,
	    a10_estado     = r_a10.a10_estado
	WHERE CURRENT OF q_ab
INITIALIZE r_a12.*, r_a14.* TO NULL
LET r_a12.a12_compania	  = vg_codcia
LET r_a12.a12_codigo_tran = vm_cod_tran1
LET r_a12.a12_numero_tran = retorna_num_tran_activo(vg_codcia,
							r_a12.a12_codigo_tran)
IF r_a12.a12_numero_tran <= 0 THEN
	RETURN 0, 0, 0
END IF
LET r_a12.a12_codigo_bien = r_a10.a10_codigo_bien
LET r_a12.a12_referencia  = 'DEPRECIACION MENSUAL'
LET r_a12.a12_locali_ori  = r_a10.a10_localidad
LET r_a12.a12_depto_ori	  = r_a10.a10_cod_depto
LET r_a12.a12_porc_deprec = r_a10.a10_porc_deprec
LET r_a12.a12_valor_mb	  = r_a10.a10_val_dep_mb * (-1)
LET r_a12.a12_valor_ma	  = 0
LET r_a12.a12_tipcomp_gen = NULL
LET r_a12.a12_numcomp_gen = NULL
LET r_a12.a12_usuario	  = 'FOBOS'
LET r_a12.a12_fecing	  = MDY(MONTH(fin_mes), 1, YEAR(fin_mes))
				+ 1 UNITS MONTH - 1 UNITS DAY
INSERT INTO actt012 VALUES (r_a12.*)
LET r_a14.a14_compania     = r_a12.a12_compania
LET r_a14.a14_codigo_bien  = r_a10.a10_codigo_bien
LET r_a14.a14_anio         = YEAR(fin_mes)
LET r_a14.a14_mes          = MONTH(fin_mes)
LET r_a14.a14_referencia   = 'GENERADA ', r_a12.a12_referencia CLIPPED
LET r_a14.a14_grupo_act    = r_a10.a10_grupo_act
LET r_a14.a14_tipo_act     = r_a10.a10_tipo_act
LET r_a14.a14_anos_util    = r_a10.a10_anos_util
LET r_a14.a14_porc_deprec  = r_a10.a10_porc_deprec
LET r_a14.a14_locali_ori   = r_a10.a10_locali_ori
LET r_a14.a14_localidad	   = r_a10.a10_localidad
LET r_a14.a14_cod_depto	   = r_a10.a10_cod_depto
LET r_a14.a14_moneda	   = r_a10.a10_moneda
LET r_a14.a14_paridad	   = r_a10.a10_paridad
LET r_a14.a14_valor	   = r_a10.a10_valor
LET r_a14.a14_valor_mb	   = r_a10.a10_valor_mb
LET r_a14.a14_fecha_baja   = r_a10.a10_fecha_baja
LET r_a14.a14_val_dep_mb   = r_a10.a10_val_dep_mb
LET r_a14.a14_val_dep_ma   = 0
LET anio = YEAR(fin_mes)
LET mes  = MONTH(fin_mes) - 1
IF mes = 0 THEN
	LET anio = YEAR(fin_mes) - 1
	LET mes  = 12
END IF
INITIALIZE r_a14_ant.* TO NULL
SELECT * INTO r_a14_ant.*
	FROM actt014
	WHERE a14_compania    = vg_codcia
	  AND a14_codigo_bien = r_a10.a10_codigo_bien
	  AND a14_anio        = anio
	  AND a14_mes         = mes
IF r_a14_ant.a14_compania IS NULL THEN
	LET r_a14_ant.a14_dep_acum_act = 0
END IF
LET r_a14.a14_dep_acum_act = r_a14.a14_val_dep_mb + r_a14_ant.a14_dep_acum_act
IF YEAR(r_a10.a10_fecha_comp) < YEAR(fin_mes) AND r_a10.a10_estado <> 'D'
THEN
	LET r_a14.a14_dep_acum_act = r_a14.a14_val_dep_mb * MONTH(fin_mes)
END IF
LET r_a14.a14_tot_dep_mb   = r_a10.a10_tot_dep_mb
LET r_a14.a14_tot_dep_ma   = 0
LET r_a14.a14_tot_reexpr   = r_a10.a10_tot_reexpr
LET r_a14.a14_tot_dep_ree  = r_a10.a10_tot_dep_ree
LET r_a14.a14_tipo_comp	   = NULL
LET r_a14.a14_num_comp	   = NULL
LET r_a14.a14_usuario	   = r_a12.a12_usuario
LET r_a14.a14_fecing	   = r_a12.a12_fecing
INSERT INTO actt014 VALUES (r_a14.*)
IF MONTH(fin_mes) <> 12 THEN
	IF r_a10.a10_estado <> 'D' THEN
		RETURN 1, r_a12.a12_numero_tran, r_a12.a12_valor_mb
	END IF
END IF
INITIALIZE r_a13_ant.*, r_a13.* TO NULL
SELECT * INTO r_a13_ant.*
	FROM actt013
	WHERE a13_compania    = vg_codcia
	  AND a13_codigo_bien = r_a10.a10_codigo_bien
	  AND a13_ano         = YEAR(fin_mes) - 1
LET r_a13.a13_compania    = r_a10.a10_compania
LET r_a13.a13_codigo_bien = r_a10.a10_codigo_bien
LET r_a13.a13_ano         = YEAR(fin_mes)
IF r_a13_ant.a13_compania IS NULL THEN
	LET r_a13.a13_val_dep_acum = r_a10.a10_tot_dep_mb
ELSE
	LET r_a13.a13_val_dep_acum = r_a13_ant.a13_val_dep_acum
					+ r_a14.a14_dep_acum_act
END IF
INSERT INTO actt013 VALUES(r_a13.*)
RETURN 1, r_a12.a12_numero_tran, r_a12.a12_valor_mb

END FUNCTION



FUNCTION retorna_fecha_dep(fecha)
DEFINE fecha		DATE
DEFINE mes, ano		SMALLINT
DEFINE fecha_dep	DATE

LET mes = MONTH(fecha) + 1
LET ano = YEAR(fecha)
IF MONTH(fecha) = 12 THEN
	LET mes = 1
	LET ano = ano + 1
END IF
LET fecha_dep = MDY(mes, 01, ano) - 1 UNITS DAY
RETURN fecha_dep

END FUNCTION



FUNCTION muestra_mensaje_error_continuar_act(activo, prefi, palabra, palabra2)
DEFINE activo		LIKE actt010.a10_codigo_bien
DEFINE prefi		CHAR(2)
DEFINE palabra		VARCHAR(15)
DEFINE palabra2		VARCHAR(15)
DEFINE query		CHAR(1000)
DEFINE varusu		VARCHAR(100)
DEFINE usuario		LIKE gent005.g05_usuario

LET query = 'SELECT UNIQUE s.username ',
		' FROM sysmaster:syslocks l, sysmaster:syssessions s ',
		' WHERE type    = "U" ',
		'   AND sid     <> DBINFO("sessionid") ',
		'   AND owner   = sid ',
		'   AND tabname = "actt0', prefi, '"',
		'   AND rowidlk IN ',
			' (SELECT ROWID FROM actt0', prefi,
				' WHERE a', prefi, '_compania    = ', vg_codcia,
				'   AND a', prefi, '_codigo_bien = ', activo,')'
PREPARE cons_blo FROM query
DECLARE q_blo CURSOR FOR cons_blo
LET varusu = NULL
FOREACH q_blo INTO usuario
	IF varusu IS NULL THEN
		LET varusu = UPSHIFT(usuario) CLIPPED
	ELSE
		LET varusu = varusu CLIPPED, ' ', UPSHIFT(usuario) CLIPPED
	END IF
END FOREACH
RETURN mensaje_error(activo, palabra, palabra2, varusu)

END FUNCTION



FUNCTION mensaje_error(activo, palabra, palabra2, varusu)
DEFINE activo		LIKE actt010.a10_codigo_bien
DEFINE palabra		VARCHAR(15)
DEFINE palabra2		VARCHAR(15)
DEFINE varusu		VARCHAR(100)
DEFINE resp		CHAR(6)
DEFINE mensaje		VARCHAR(255)

LET mensaje = 'No se ha podido ', palabra CLIPPED, ' el registro del ',
		'código de Activo Fijo ', activo USING "<<<<<<&",
		'. LLAME AL ADMINISTRADOR.'
DISPLAY mensaje CLIPPED
RETURN 0

END FUNCTION



FUNCTION retorna_num_tran_activo(codcia, codigo_tran) 
DEFINE codcia 		LIKE actt005.a05_compania
DEFINE codigo_tran	LIKE actt005.a05_codigo_tran
DEFINE numero		LIKE actt005.a05_numero
DEFINE mensaje		VARCHAR(60)

WHENEVER ERROR CONTINUE
SET LOCK MODE TO WAIT 5
DECLARE up_tact CURSOR FOR
	SELECT a05_numero FROM actt005
		WHERE a05_compania    = codcia
		  AND a05_codigo_tran = codigo_tran
	FOR UPDATE
OPEN up_tact
FETCH up_tact INTO numero
IF STATUS = NOTFOUND THEN
	LET mensaje = 'No existe control secuencia en actt005: ',
		       codcia USING '<&', ' transacción: ', codigo_tran
	DISPLAY mensaje CLIPPED
	LET numero = 0
ELSE
	IF STATUS < 0 THEN
		DISPLAY 'Secuencia está bloqueada por otro proceso.'
		LET numero = -1
	ELSE
		LET numero = numero + 1
		UPDATE actt005 SET a05_numero = numero
			WHERE CURRENT OF up_tact
		IF STATUS < 0 THEN
			DISPLAY 'No se actualizó control secuencia.'
			LET numero = -1
		END IF
	END IF
END IF
WHENEVER ERROR STOP
SET LOCK MODE TO NOT WAIT
RETURN numero

END FUNCTION
