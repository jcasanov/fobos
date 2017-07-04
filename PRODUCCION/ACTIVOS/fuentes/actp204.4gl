--------------------------------------------------------------------------------
-- Titulo           : actp204.4gl - Cierre Mensual (Generacion Depreciacion)
-- Elaboracion      : 12-jun-2003
-- Autor            : YEC
-- Formato Ejecucion: fglrun actp204 base módulo compañía
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_programa	VARCHAR(12)
DEFINE rm_a00		RECORD LIKE actt000.*
DEFINE rm_b00		RECORD LIKE ctbt000.*
DEFINE rm_b12		RECORD LIKE ctbt012.*
DEFINE vm_mes_ini	LIKE actt000.a00_mespro
DEFINE vm_mes_fin	LIKE actt000.a00_mespro
DEFINE vm_tran_ini	INTEGER
DEFINE vm_tran_fin	INTEGER
DEFINE vm_cod_tran	LIKE actt012.a12_codigo_tran



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/actp204.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parametros correcto
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'actp204'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vm_programa || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE mes		LIKE actt000.a00_mespro
DEFINE mensaje		VARCHAR(200)
DEFINE deprecio		SMALLINT

CALL fl_nivel_isolation()
LET vm_cod_tran = 'DP'
OPEN WINDOW w_actf204_1 AT 3,2 WITH 15 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_actf204_1 FROM "../forms/actf204_1"
DISPLAY FORM f_actf204_1
CALL confirma_cierre(2)
CREATE TEMP TABLE te_depre
	(te_grupo		SMALLINT,
	 te_codigo_bien		INTEGER,
	 te_cuenta		CHAR(12),
	 te_valor		DECIMAL(14,2))
LET vm_mes_ini = rm_a00.a00_mespro
LET vm_mes_fin = 12
IF rm_a00.a00_anopro >= YEAR(TODAY) THEN
	IF TODAY =
	  (MDY(MONTH(TODAY), 01, YEAR(TODAY)) + 1 UNITS MONTH - 1 UNITS DAY)
	THEN
		LET vm_mes_fin = MONTH(TODAY)
	ELSE
		LET vm_mes_fin = MONTH(TODAY) - 1
	END IF
	IF MONTH(TODAY) < rm_a00.a00_mespro THEN
		LET vm_mes_fin = vm_mes_fin + 1
		IF vm_mes_fin > 12 THEN
			LET vm_mes_fin = 12
		END IF
	END IF
END IF
CALL lee_parametros()
IF int_flag THEN
	CLOSE WINDOW w_actf204_1
	DROP TABLE te_depre
	EXIT PROGRAM
END IF
CALL confirma_cierre(1)
LET deprecio = 0
FOR mes = vm_mes_ini TO vm_mes_fin
	CALL confirma_cierre(2)
	INITIALIZE vm_tran_ini, vm_tran_fin, rm_b12.* TO NULL
	IF MDY(rm_a00.a00_mespro, 1, rm_a00.a00_anopro) + 1 UNITS MONTH
	   - 1 UNITS DAY > TODAY
	THEN
		CALL fl_mostrar_mensaje('Aún no corresponde generar depreciaciónde este mes.', 'exclamation')
		EXIT FOR
	END IF
	CALL control_depreciacion()
	LET mensaje = 'MES ', mes USING "&&", ' ', fl_justifica_titulo('I',
			fl_retorna_nombre_mes(mes), 11) CLIPPED, '  AñO ',
			rm_a00.a00_anopro USING "&&&&",
			'  DEPRECIADO CORRECTAMENTE.'
	MESSAGE mensaje CLIPPED
	SLEEP 2
	LET deprecio = 1
END FOR
IF deprecio THEN
	CALL fl_mostrar_mensaje('Proceso de Depreciación Terminado Ok.', 'info')
END IF
CLOSE WINDOW w_actf204_1
DROP TABLE te_depre
EXIT PROGRAM

END FUNCTION



FUNCTION lee_parametros()
DEFINE mes_ini		SMALLINT
DEFINE mes_fin		SMALLINT
DEFINE tit_mes_ini	VARCHAR(11)
DEFINE tit_mes_fin	VARCHAR(11)

CALL fl_retorna_nombre_mes(vm_mes_ini) RETURNING tit_mes_ini
CALL fl_justifica_titulo('I', tit_mes_ini, 11) RETURNING tit_mes_ini
DISPLAY BY NAME tit_mes_ini
CALL fl_retorna_nombre_mes(vm_mes_fin) RETURNING tit_mes_fin
CALL fl_justifica_titulo('I', tit_mes_fin, 11) RETURNING tit_mes_fin
DISPLAY BY NAME tit_mes_fin
LET int_flag = 0
INPUT BY NAME vm_mes_ini, vm_mes_fin
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
	BEFORE FIELD vm_mes_ini
		LET mes_ini = vm_mes_ini
	BEFORE FIELD vm_mes_fin
		LET mes_fin = vm_mes_fin
	AFTER FIELD vm_mes_ini
		IF vm_mes_ini IS NOT NULL THEN
			IF vm_mes_ini > MONTH(TODAY) AND
			   rm_a00.a00_anopro >= YEAR(TODAY)
			THEN
				CALL fl_mostrar_mensaje('Mes Inicial no puede ser mayor al mes del año en que estamos.', 'exclamation')
				NEXT FIELD vm_mes_ini
			END IF
		ELSE
			LET vm_mes_ini = mes_ini
			DISPLAY BY NAME vm_mes_ini
		END IF
		CALL fl_retorna_nombre_mes(vm_mes_ini) RETURNING tit_mes_ini
		CALL fl_justifica_titulo('I', tit_mes_ini, 11)
			RETURNING tit_mes_ini
		DISPLAY BY NAME tit_mes_ini
	AFTER FIELD vm_mes_fin
		IF vm_mes_fin IS NOT NULL THEN
			IF vm_mes_fin > MONTH(TODAY) AND
			   rm_a00.a00_anopro >= YEAR(TODAY)
			THEN
				CALL fl_mostrar_mensaje('Mes Final no puede ser mayor al mes del año en que estamos.', 'exclamation')
				NEXT FIELD vm_mes_fin
			END IF
		ELSE
			LET vm_mes_fin = mes_fin
			DISPLAY BY NAME vm_mes_fin
		END IF
		CALL fl_retorna_nombre_mes(vm_mes_fin) RETURNING tit_mes_fin
		CALL fl_justifica_titulo('I', tit_mes_fin, 11)
			RETURNING tit_mes_fin
		DISPLAY BY NAME tit_mes_fin
	AFTER INPUT
		IF vm_mes_ini > vm_mes_fin THEN
			CALL fl_mostrar_mensaje('El Mes Final debe ser mayor o igual al Mes Inicial.', 'exclamation')
			NEXT FIELD vm_mes_fin
		END IF
END INPUT

END FUNCTION



FUNCTION confirma_cierre(flag)
DEFINE flag		SMALLINT
DEFINE resp 		VARCHAR(6)
DEFINE cuantos		INTEGER
DEFINE mensaje		VARCHAR(200)
DEFINE fecha		DATE

CALL fl_lee_compania_contabilidad(vg_codcia) RETURNING rm_b00.*
CALL fl_lee_compania_activos(vg_codcia) RETURNING rm_a00.*
IF rm_a00.a00_anopro < YEAR(rm_b00.b00_fecha_cm) OR
	(rm_a00.a00_anopro = YEAR(rm_b00.b00_fecha_cm) AND 
	 rm_a00.a00_mespro <= MONTH(rm_b00.b00_fecha_cm)) THEN
	CALL fl_mostrar_mensaje('Mes a cerrar ya esta cerrado en Contabilidad. Reapertúrelo para que pueda generar la depreciación.', 'stop')
	EXIT PROGRAM
END IF
LET fecha = MDY(rm_a00.a00_mespro, 01, rm_a00.a00_anopro)
IF (EXTEND(TODAY, YEAR TO MONTH) = EXTEND(fecha, YEAR TO MONTH)) THEN
	CALL fl_mostrar_mensaje('Aún no corresponde generar depreciación, hagalo a fin de mes.', 'stop')
	EXIT PROGRAM
END IF
DISPLAY BY NAME rm_a00.a00_anopro
IF flag = 2 THEN
	RETURN
END IF
SELECT COUNT(*) INTO cuantos
	FROM actt010
	WHERE a10_compania = vg_codcia
	  AND a10_estado   = 'D'
IF cuantos > 0 THEN
	{--
	CALL fl_mostrar_mensaje('No puede realizar el CIERRE MENSUAL mientras existan ACTIVOS FIJOS sin dar de baja.', 'stop')
	EXIT PROGRAM
	--}
	LET mensaje = 'Existen un total de ', cuantos USING "<<<<#&",
			' ACTIVOS FIJOS sin DAR DE BAJA en el modulo.'
	CALL fl_mostrar_mensaje(mensaje, 'info')
END IF
CALL fl_hacer_pregunta('Esta seguro que desea realizar el cierre del mes.','No')
	RETURNING resp
IF resp <> 'Yes' THEN
	CLOSE WINDOW w_actf204_1
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION control_depreciacion()

BEGIN WORK
CALL actualiza_actt000()
CALL genera_depreciacion()
--
CALL genera_contabilizacion()
UPDATE actt012 SET a12_tipcomp_gen = rm_b12.b12_tipo_comp,
                   a12_numcomp_gen = rm_b12.b12_num_comp
	WHERE a12_compania    = vg_codcia   AND 
	      a12_codigo_tran = vm_cod_tran AND
	      a12_numero_tran BETWEEN vm_tran_ini AND vm_tran_fin	  
--
COMMIT WORK
--
IF rm_b12.b12_tipo_comp IS NOT NULL THEN
	CALL fl_mayoriza_comprobante(vg_codcia, rm_b12.b12_tipo_comp, 
			rm_b12.b12_num_comp, 'M')
END IF
--
DELETE FROM te_depre WHERE 1 = 1

END FUNCTION



FUNCTION actualiza_actt000()
DEFINE r		RECORD LIKE actt000.*

LET r.* = rm_a00.*
IF r.a00_mespro = 12 THEN
	LET r.a00_mespro = 1
	LET r.a00_anopro = r.a00_anopro + 1
ELSE
	LET r.a00_mespro = r.a00_mespro + 1
END IF
UPDATE actt000 SET a00_mespro = r.a00_mespro,
		   a00_anopro = r.a00_anopro
	WHERE a00_compania = r.a00_compania 

END FUNCTION



FUNCTION genera_depreciacion()
DEFINE i, j		SMALLINT
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE r_a01		RECORD LIKE actt001.*
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE r_a11		RECORD LIKE actt011.*
DEFINE r_a12		RECORD LIKE actt012.*
DEFINE r_a13		RECORD LIKE actt013.*
DEFINE r_a14		RECORD LIKE actt014.*
DEFINE r_a13_ant	RECORD LIKE actt013.*
DEFINE r_a14_ant	RECORD LIKE actt014.*
DEFINE val_dep, tot_dep	DECIMAL(14,2)
DEFINE dif             	DECIMAL(14,2)
DEFINE dias		INTEGER
DEFINE fin_mes		DATE
DEFINE fin_deprec	DATE
DEFINE mes, anio	SMALLINT
                                             
DECLARE q_ab CURSOR FOR
	SELECT * FROM actt010
		WHERE a10_estado     IN ('S', 'R')
		  AND a10_valor_mb   > a10_tot_dep_mb
		  AND a10_val_dep_mb > 0
		ORDER BY a10_grupo_act, a10_tipo_act, a10_codigo_bien
LET int_flag = 0
LET fin_mes  = MDY(rm_a00.a00_mespro, 1, rm_a00.a00_anopro) +
 		    1 UNITS MONTH - 1 UNITS DAY
FOREACH q_ab INTO r_a10.*
	IF retorna_fecha_dep() < r_a10.a10_fecha_comp THEN
		CONTINUE FOREACH
	END IF
	LET fin_deprec = r_a10.a10_fecha_comp + r_a10.a10_anos_util UNITS YEAR
	LET dias = fin_mes - r_a10.a10_fecha_comp
	IF YEAR(r_a10.a10_fecha_comp) = rm_a00.a00_anopro AND 
	   MONTH(r_a10.a10_fecha_comp) = rm_a00.a00_mespro THEN
		LET r_a10.a10_val_dep_mb = (r_a10.a10_val_dep_mb * dias) /
					    DAY(fin_mes)
	END IF
	IF YEAR(fin_deprec)  = rm_a00.a00_anopro AND 
	   MONTH(fin_deprec) = rm_a00.a00_mespro THEN
		LET r_a10.a10_val_dep_mb = r_a10.a10_valor_mb
						- r_a10.a10_tot_dep_mb
	END IF
	IF r_a10.a10_val_dep_mb > r_a10.a10_valor_mb - r_a10.a10_tot_dep_mb THEN
		LET r_a10.a10_val_dep_mb = r_a10.a10_valor_mb
						- r_a10.a10_tot_dep_mb
	END IF
	CALL fl_lee_grupo_activo(r_a10.a10_compania, r_a10.a10_grupo_act)
		RETURNING r_a01.*
	IF r_a01.a01_depreciable = 'N' THEN
		CONTINUE FOREACH
	END IF
if r_a10.a10_locali_ori = 1 and r_a10.a10_codigo_bien = 313 and
  (extend(fin_mes, year to month) = '2012-04' or
   extend(fin_mes, year to month) = '2012-05' or
   extend(fin_mes, year to month) = '2012-06' or
   extend(fin_mes, year to month) = '2012-07')
then
	continue foreach
end if
if r_a10.a10_locali_ori = 3 and r_a10.a10_codigo_bien >= 430 and
   r_a10.a10_codigo_bien <= 433 and
  (extend(fin_mes, year to month) = '2012-06' or
   extend(fin_mes, year to month) = '2012-07')
then
	continue foreach
end if
if r_a10.a10_codigo_bien = 412 and extend(fin_mes, year to month) = '2011-01'
then
	let r_a10.a10_val_dep_mb = 57.7
end if
if r_a10.a10_locali_ori = 1 and r_a10.a10_codigo_bien = 313 and
   extend(fin_mes, year to month) = '2012-08'
then
	let r_a10.a10_val_dep_mb = 74.3
end if
if r_a10.a10_locali_ori = 3 and r_a10.a10_codigo_bien = 430 and
   extend(fin_mes, year to month) = '2012-08'
then
	let r_a10.a10_val_dep_mb = 34.16
end if
if r_a10.a10_locali_ori = 3 and r_a10.a10_codigo_bien = 431 and
   extend(fin_mes, year to month) = '2012-08'
then
	let r_a10.a10_val_dep_mb = 34.16
end if
if r_a10.a10_locali_ori = 3 and r_a10.a10_codigo_bien = 432 and
   extend(fin_mes, year to month) = '2012-08'
then
	let r_a10.a10_val_dep_mb = 56.86
end if
if r_a10.a10_locali_ori = 3 and r_a10.a10_codigo_bien = 433 and
   extend(fin_mes, year to month) = '2012-08'
then
	let r_a10.a10_val_dep_mb = 56.86
end if
	DECLARE q_dpto CURSOR FOR
		SELECT * FROM actt011
			WHERE a11_compania    = r_a10.a10_compania
			  AND a11_codigo_bien = r_a10.a10_codigo_bien
	LET j = 0
	FOREACH q_dpto INTO r_a11.*
		LET j = j + 1
	END FOREACH
	LET i = 0
	LET tot_dep = 0
	FOREACH q_dpto INTO r_a11.*
		CALL lee_departamento(r_a10.a10_compania, r_a11.a11_cod_depto)
			RETURNING r_g34.*
		LET i = i + 1	
		LET val_dep = r_a10.a10_val_dep_mb * r_a11.a11_porcentaje / 100
		LET tot_dep = tot_dep + val_dep 
		IF i = j THEN
			LET dif     = r_a10.a10_val_dep_mb - tot_dep
			LET tot_dep = tot_dep - val_dep
			LET val_dep = val_dep + dif
			LET tot_dep = tot_dep + val_dep
		END IF
		CALL inserta_tabla_temporal(r_a10.a10_grupo_act, 
				            r_a10.a10_codigo_bien,
				            r_g34.g34_aux_deprec,
				            val_dep, 'D')
		CALL inserta_tabla_temporal(r_a10.a10_grupo_act,
						r_a10.a10_codigo_bien,
						r_a01.a01_aux_dep_act,
						val_dep, 'H') 
	END FOREACH
	IF i = 0 THEN
		CALL lee_departamento(r_a10.a10_compania, r_a10.a10_cod_depto)
                	RETURNING r_g34.*
		CALL inserta_tabla_temporal(r_a10.a10_grupo_act,
						r_a10.a10_codigo_bien,
						r_g34.g34_aux_deprec,
						r_a10.a10_val_dep_mb, 'D')
		CALL inserta_tabla_temporal(r_a10.a10_grupo_act,
						r_a10.a10_codigo_bien,
						r_a01.a01_aux_dep_act,
						r_a10.a10_val_dep_mb, 'H')
	END IF          			    
	LET r_a10.a10_tot_dep_mb = r_a10.a10_tot_dep_mb + r_a10.a10_val_dep_mb
	IF r_a10.a10_valor_mb = r_a10.a10_tot_dep_mb THEN
		LET r_a10.a10_estado = 'D'
	END IF
	UPDATE actt010 SET a10_tot_dep_mb = r_a10.a10_tot_dep_mb,
			   a10_estado     = r_a10.a10_estado
		WHERE a10_compania    = r_a10.a10_compania
		  AND a10_codigo_bien = r_a10.a10_codigo_bien 
	INITIALIZE r_a12.*, r_a14.* TO NULL
	LET r_a12.a12_compania	  = vg_codcia
	LET r_a12.a12_codigo_tran = vm_cod_tran
	LET r_a12.a12_numero_tran = fl_retorna_num_tran_activo(vg_codcia, 
							r_a12.a12_codigo_tran)
	IF r_a12.a12_numero_tran <= 0 THEN
		ROLLBACK WORK
		EXIT PROGRAM
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
	LET r_a12.a12_usuario	  = vg_usuario
	LET r_a12.a12_fecing	  = MDY(rm_a00.a00_mespro, 1, rm_a00.a00_anopro)
					+ 1 UNITS MONTH - 1 UNITS DAY
	INSERT INTO actt012 VALUES (r_a12.*)
	LET r_a14.a14_compania     = r_a12.a12_compania
	LET r_a14.a14_codigo_bien  = r_a10.a10_codigo_bien
	LET r_a14.a14_anio         = rm_a00.a00_anopro
	LET r_a14.a14_mes          = rm_a00.a00_mespro
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
	LET anio                   = rm_a00.a00_anopro
	LET mes                    = rm_a00.a00_mespro - 1
	IF mes = 0 THEN
		LET anio           = rm_a00.a00_anopro - 1
		LET mes            = 12
	END IF
	CALL fl_lee_depreciacion_mensual_activo(vg_codcia,r_a10.a10_codigo_bien,
						anio, mes)
		RETURNING r_a14_ant.*
	IF r_a14_ant.a14_compania IS NULL THEN
		LET r_a14_ant.a14_dep_acum_act = 0
	END IF
	LET r_a14.a14_dep_acum_act = r_a14.a14_val_dep_mb
					+ r_a14_ant.a14_dep_acum_act
	IF YEAR(r_a10.a10_fecha_comp) < rm_a00.a00_anopro
	   AND r_a10.a10_estado <> 'D' THEN
		LET r_a14.a14_dep_acum_act = r_a14.a14_val_dep_mb *
						rm_a00.a00_mespro
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
	IF int_flag = 0 THEN
		LET vm_tran_ini = r_a12.a12_numero_tran
		LET int_flag = 1
	END IF
	LET vm_tran_fin = r_a12.a12_numero_tran
	IF rm_a00.a00_mespro <> 12 THEN
		IF r_a10.a10_estado <> 'D' THEN
			CONTINUE FOREACH
		END IF
	END IF
	INITIALIZE r_a13_ant.*, r_a13.* TO NULL
	SELECT * INTO r_a13_ant.* FROM actt013
		WHERE a13_compania    = vg_codcia
		  AND a13_codigo_bien = r_a10.a10_codigo_bien
		  AND a13_ano         = rm_a00.a00_anopro - 1
	LET r_a13.a13_compania     = r_a10.a10_compania
	LET r_a13.a13_codigo_bien  = r_a10.a10_codigo_bien
	LET r_a13.a13_ano          = rm_a00.a00_anopro
	IF r_a13_ant.a13_compania IS NULL THEN
		LET r_a13.a13_val_dep_acum = r_a10.a10_tot_dep_mb
	ELSE
		LET r_a13.a13_val_dep_acum = r_a13_ant.a13_val_dep_acum
						+ r_a14.a14_dep_acum_act
						--+ r_a10.a10_tot_dep_mb
	END IF
	INSERT INTO actt013 VALUES(r_a13.*)
END FOREACH
FREE q_ab

END FUNCTION



FUNCTION inserta_tabla_temporal(grupo_act, cod_bien, cuenta, valor, tipo_mov)  
DEFINE grupo_act	LIKE actt010.a10_grupo_act
DEFINE cod_bien		LIKE actt010.a10_codigo_bien
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE valor		DECIMAL(14,2)
DEFINE tipo_mov		CHAR(1)

IF tipo_mov = 'H' THEN
	LET valor = valor * -1
END IF
SELECT * FROM te_depre WHERE te_grupo = grupo_act AND te_cuenta = cuenta
IF status = NOTFOUND THEN
	INSERT INTO te_depre VALUES (grupo_act, cod_bien, cuenta, valor)
ELSE
	UPDATE te_depre SET te_valor = te_valor + valor
		WHERE te_grupo = grupo_act AND te_cuenta = cuenta
END IF

END FUNCTION



FUNCTION genera_contabilizacion()
DEFINE tot_reg, i	SMALLINT
DEFINE r_b13		RECORD LIKE ctbt013.*
DEFINE grupo		LIKE actt010.a10_grupo_act
DEFINE cuenta		LIKE ctbt013.b13_cuenta
DEFINE valor		DECIMAL(14,2)

SELECT COUNT(*) INTO tot_reg FROM te_depre
IF tot_reg = 0 THEN
	RETURN
END IF
INITIALIZE rm_b12.* TO NULL
LET rm_b12.b12_compania 		= vg_codcia
LET rm_b12.b12_tipo_comp		= 'DC'
LET rm_b12.b12_num_comp 		= fl_numera_comprobante_contable(vg_codcia, 
			             rm_b12.b12_tipo_comp, rm_a00.a00_anopro, 
				     rm_a00.a00_mespro)
LET rm_b12.b12_estado		= 'A'
LET rm_b12.b12_subtipo 		=  61
LET rm_b12.b12_glosa		= 'DEPRECIACION ACTIVOS: ',
				   rm_a00.a00_mespro USING '&&', '/',
				   rm_a00.a00_anopro USING '&&&&'
LET rm_b12.b12_origen 		= 'A'
LET rm_b12.b12_moneda 		= rm_b00.b00_moneda_base
LET rm_b12.b12_paridad		= 1
LET rm_b12.b12_fec_proceso	= MDY(rm_a00.a00_mespro, 1, rm_a00.a00_anopro) +
				  1 UNITS MONTH - 1 UNITS DAY
LET rm_b12.b12_modulo 		= 'AF'
LET rm_b12.b12_usuario		= vg_usuario
LET rm_b12.b12_fecing 		= CURRENT
INSERT INTO ctbt012 VALUES (rm_b12.*)
DECLARE qu_sopla CURSOR FOR
	SELECT te_grupo, te_cuenta, te_valor
		FROM te_depre
        	ORDER BY 1, 3 DESC, 2
LET i = 0
FOREACH qu_sopla INTO grupo, cuenta, valor
	INITIALIZE r_b13.* TO NULL
	LET i = i + 1
    	LET r_b13.b13_compania 		= rm_b12.b12_compania
    	LET r_b13.b13_tipo_comp 	= rm_b12.b12_tipo_comp
    	LET r_b13.b13_num_comp 		= rm_b12.b12_num_comp
    	LET r_b13.b13_secuencia		= i
    	LET r_b13.b13_cuenta 		= cuenta
    	LET r_b13.b13_glosa 		= rm_b12.b12_glosa 
    	LET r_b13.b13_valor_base 	= valor
    	LET r_b13.b13_valor_aux 	= 0
    	LET r_b13.b13_fec_proceso 	= rm_b12.b12_fec_proceso
	INSERT INTO ctbt013 VALUES (r_b13.*)
END FOREACH

END FUNCTION



FUNCTION lee_departamento(codcia, cod_depto) 
DEFINE codcia		LIKE gent034.g34_compania
DEFINE cod_depto	LIKE gent034.g34_cod_depto
DEFINE r_g34		RECORD LIKE gent034.* 
 
CALL fl_lee_departamento(codcia, cod_depto) RETURNING r_g34.*     
IF r_g34.g34_aux_deprec IS NULL THEN                            
	CALL fl_mostrar_mensaje('Departamento: '||              
		r_g34.g34_cod_depto ||                          
		' no tiene asignado auxiliar contable'||        
		' de depreciación.', 'stop')                    
	EXIT PROGRAM                                            
END IF
RETURN r_g34.*

END FUNCTION



FUNCTION retorna_num_tran_activo(codcia, codigo_tran) 
DEFINE codcia 		LIKE actt005.a05_compania
DEFINE codigo_tran	LIKE actt005.a05_codigo_tran
DEFINE numero		LIKE actt005.a05_numero

DECLARE up_tact CURSOR FOR SELECT a05_numero FROM actt005
	WHERE a05_compania    = codcia AND
	      a05_codigo_tran = codigo_tran
	FOR UPDATE
OPEN up_tact
FETCH up_tact INTO numero
IF status = NOTFOUND THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No existe control secuencia en actt005',
				'exclamation')
	EXIT PROGRAM
END IF
LET numero = numero + 1
UPDATE actt005 SET a05_numero = numero + 1
	WHERE CURRENT OF up_tact
RETURN numero

END FUNCTION



FUNCTION retorna_fecha_dep()
DEFINE mes, ano		SMALLINT
DEFINE fecha_dep	DATE

LET mes = rm_a00.a00_mespro + 1
LET ano = rm_a00.a00_anopro
IF rm_a00.a00_mespro = 12 THEN
	LET mes = 1
	LET ano = ano + 1
END IF
LET fecha_dep = MDY(mes, 01, ano) - 1 UNITS DAY
RETURN fecha_dep

END FUNCTION
