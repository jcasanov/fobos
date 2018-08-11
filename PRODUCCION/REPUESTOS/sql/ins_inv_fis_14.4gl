DATABASE aceros


DEFINE base_ori		CHAR(20)
DEFINE serv_ori		CHAR(20)
DEFINE vg_codcia	LIKE gent001.g01_compania
DEFINE vg_codloc	LIKE gent002.g02_localidad



MAIN

	IF num_args() <> 4 THEN
		DISPLAY 'Parametros Incorrectos. SON: BASE SERVIDOR COMPANIA',
			' LOCALIDAD.'
		EXIT PROGRAM
	END IF
	LET base_ori    = arg_val(1)
	LET serv_ori    = arg_val(2)
	LET vg_codcia   = arg_val(3)
	LET vg_codloc   = arg_val(4)
	CALL ejecuta_proceso()

END MAIN



FUNCTION activar_base(b, s)
DEFINE b, s		CHAR(20)
DEFINE base, base1	CHAR(20)
DEFINE r_g51		RECORD LIKE gent051.*

LET base  = b
LET base1 = base CLIPPED, '@', s
CLOSE DATABASE
WHENEVER ERROR CONTINUE
DATABASE base1
IF STATUS < 0 THEN
	DISPLAY 'No se pudo abrir base de datos: ', base1
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
INITIALIZE r_g51.* TO NULL
SELECT * INTO r_g51.* FROM gent051 WHERE g51_basedatos = base
IF r_g51.g51_basedatos IS NULL THEN
	DISPLAY 'No existe base de datos: ', base
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION ejecuta_proceso()
DEFINE r_r89		RECORD LIKE rept089.*
DEFINE r_reg		RECORD
				bodega		LIKE rept089.r89_bodega,
				item		LIKE rept089.r89_item,
				vendib		LIKE rept089.r89_bueno,
				novend		LIKE rept089.r89_incompleto
			END RECORD
DEFINE insertado	INTEGER
DEFINE actualizado	INTEGER
DEFINE mensaje		VARCHAR(250)

CALL activar_base(base_ori, serv_ori)
SET ISOLATION TO DIRTY READ
SELECT r89_bodega AS bod,
	r89_item AS item,
	r89_bueno AS vendib,
	r89_incompleto AS novend
	FROM rept089
	WHERE r89_compania = 999
	INTO TEMP t1
DISPLAY "Cargando el archivo..."
LOAD FROM "inv_fis_2014.unl" DELIMITER ","
	INSERT INTO t1
BEGIN WORK
WHENEVER ERROR CONTINUE
SET LOCK MODE TO WAIT 3
DECLARE q_t1 CURSOR WITH HOLD FOR
	SELECT * FROM t1
LET insertado   = 0
LET actualizado = 0
FOREACH q_t1 INTO r_reg.*
	SELECT * FROM rept089
		WHERE r89_compania  = vg_codcia
		  AND r89_localidad = vg_codloc
		  AND r89_bodega    = r_reg.bodega
		  AND r89_item      = r_reg.item
		  AND r89_anio      = 2014
		  AND r89_mes       = 12
	IF STATUS = NOTFOUND THEN
		INITIALIZE r_r89.* TO NULL
		LET r_r89.r89_compania   = vg_codcia
		LET r_r89.r89_localidad  = vg_codloc
		LET r_r89.r89_bodega     = r_reg.bodega
		LET r_r89.r89_item       = r_reg.item
		LET r_r89.r89_usuario    = "FOBOS"
		LET r_r89.r89_anio       = 2014
		LET r_r89.r89_mes        = 12
		SELECT NVL(MAX(r89_secuencia), 0) + 1
			INTO r_r89.r89_secuencia
			FROM rept089
			WHERE r89_compania  = r_r89.r89_compania
			  AND r89_localidad = r_r89.r89_localidad
			  AND r89_usuario   = r_r89.r89_usuario
			  AND r89_anio      = r_r89.r89_anio
			  AND r89_mes       = r_r89.r89_mes
		SELECT r11_stock_act, r11_fec_corte
			INTO r_r89.r89_stock_act, r_r89.r89_fec_corte
			FROM resp_exis
			WHERE r11_compania = vg_codcia
			  AND r11_bodega   = r_reg.bodega
			  AND r11_item     = r_reg.item
		LET r_r89.r89_bueno      = r_reg.vendib
		LET r_r89.r89_incompleto = r_reg.novend
		LET r_r89.r89_mal_est    = 0.00
		LET r_r89.r89_suma       = r_r89.r89_bueno
						+ r_r89.r89_incompleto
						+ r_r89.r89_mal_est
		LET r_r89.r89_fecha      = TODAY
		LET r_r89.r89_fecing     = CURRENT
		WHENEVER ERROR CONTINUE
		INSERT INTO rept089 VALUES (r_r89.*)
		WHENEVER ERROR STOP
		DISPLAY '  Insertando el item: ', r_reg.item CLIPPED,
			' bodega: ', r_reg.bodega CLIPPED, '  OK.'
		LET insertado = insertado + 1
	ELSE
		LET r_r89.r89_bueno      = r_reg.vendib
		LET r_r89.r89_incompleto = r_reg.novend
		LET r_r89.r89_mal_est    = 0.00
		LET r_r89.r89_suma       = r_r89.r89_bueno
						+ r_r89.r89_incompleto
						+ r_r89.r89_mal_est
		LET r_r89.r89_usu_modifi = "FOBOS"
		LET r_r89.r89_fec_modifi = CURRENT
		WHENEVER ERROR CONTINUE
		UPDATE rept089
			SET r89_bueno      = r_r89.r89_bueno,
			    r89_incompleto = r_r89.r89_incompleto,
			    r89_mal_est    = r_r89.r89_mal_est,
			    r89_suma       = r_r89.r89_suma,
			    r89_usu_modifi = r_r89.r89_usu_modifi,
			    r89_fec_modifi = r_r89.r89_fec_modifi
			WHERE r89_compania = vg_codcia
			  AND r89_localidad= vg_codloc
			  AND r89_bodega   = r_reg.bodega
			  AND r89_item     = r_reg.item
			  AND r89_anio     = 2014
			  AND r89_mes      = 12
		IF STATUS <> 0 THEN
			LET mensaje  =  'Ha ocurrido un error al ',
					'intentar actualizar los datos',
					' del ítem ',
				r_reg.item CLIPPED,
					', Vuelva a intentar para ',
					'tratar de completar la ',
					'actualización.'
			ROLLBACK WORK
			WHENEVER ERROR STOP
			DROP TABLE t1
			EXIT PROGRAM
		END IF
		DISPLAY '  Actualizando el item: ', r_reg.item CLIPPED,
			' bodega: ', r_reg.bodega CLIPPED, '  OK.'
		LET actualizado = actualizado + 1
	END IF
END FOREACH
SET LOCK MODE TO NOT WAIT
WHENEVER ERROR STOP
COMMIT WORK
DISPLAY ' '
DISPLAY 'Se insertaron un total de ', insertado USING "<<<<<&"
DISPLAY 'Se actualizaron un total de ', actualizado USING "<<<<<&"
DISPLAY ' '
DISPLAY 'Carga de items terminada  OK. '
DROP TABLE t1

END FUNCTION
