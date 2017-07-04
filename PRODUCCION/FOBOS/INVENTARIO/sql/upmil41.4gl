DATABASE aceros



DEFINE base1, base2	CHAR(20)
DEFINE codcia1, codcia2	LIKE gent001.g01_compania
DEFINE division		LIKE rept003.r03_codigo
DEFINE linea		LIKE rept070.r70_sub_linea
DEFINE marca		LIKE rept073.r73_marca



MAIN

	IF num_args() <> 7 THEN
		DISPLAY 'Parametros Incorrectos. BASE_ORIGEN BASE_DESTINO ',
			'COMPAÑIA_ORIGEN COMPAÑIA_DESTINO DIVISION LINEA MARCA'
		EXIT PROGRAM
	END IF
	LET base1    = arg_val(1)
	LET base2    = arg_val(2)
	LET codcia1  = arg_val(3)
	LET codcia2  = arg_val(4)
	LET division = arg_val(5)
	LET linea    = arg_val(6)
	LET marca    = arg_val(7)
	CALL ejecuta_proceso()
	DISPLAY 'Actualización Terminada OK.'

END MAIN



FUNCTION ejecuta_proceso()
DEFINE r_ite		RECORD LIKE rept010.*
DEFINE i		INTEGER

DATABASE base1
SET ISOLATION TO DIRTY READ
DISPLAY 'Descargando ítems de la división ', division CLIPPED, ' línea ', linea,
	'. Por favor espere ...'
UNLOAD TO "item.unl"
	SELECT * FROM rept010
		WHERE r10_compania  = codcia1
		  AND r10_linea     = division
		  AND r10_sub_linea = linea
		  AND r10_marca     = marca
CLOSE DATABASE
WHENEVER ERROR CONTINUE
DATABASE base2
WHENEVER ERROR STOP
SET ISOLATION TO DIRTY READ
DISPLAY ' '
DISPLAY 'Subiendo la información ...'
SELECT * FROM rept010
	WHERE r10_compania = 77
	INTO TEMP tmp_r10
LOAD FROM "item.unl" INSERT INTO tmp_r10
DISPLAY ' '
DISPLAY 'Actualizando Items. Por favor espere ...'
DECLARE q_r10 CURSOR FOR SELECT * FROM tmp_r10
LET i = 0
FOREACH q_r10 INTO r_ite.*
	UPDATE rept010
		SET r10_nombre      = r_ite.r10_nombre,
		    r10_linea       = r_ite.r10_linea,
		    r10_sub_linea   = r_ite.r10_sub_linea,
		    r10_cod_grupo   = r_ite.r10_cod_grupo,
		    r10_cod_clase   = r_ite.r10_cod_clase,
		    r10_estado      = r_ite.r10_estado,
		    r10_tipo        = r_ite.r10_tipo,
		    r10_peso        = r_ite.r10_peso,
		    r10_uni_med     = r_ite.r10_uni_med,
		    r10_cantpaq     = r_ite.r10_cantpaq,
		    r10_cantveh     = r_ite.r10_cantveh,
		    r10_partida     = r_ite.r10_partida,
		    r10_modelo      = r_ite.r10_modelo,
		    r10_cod_pedido  = r_ite.r10_cod_pedido,
		    r10_cod_comerc  = r_ite.r10_cod_comerc,
		    r10_cod_util    = r_ite.r10_cod_util,
		    r10_rotacion    = r_ite.r10_rotacion,
		    r10_paga_impto  = r_ite.r10_paga_impto,
		    r10_comentarios = r_ite.r10_comentarios,
		    r10_filtro      = r_ite.r10_filtro,
		    r10_electrico   = r_ite.r10_electrico,
		    r10_color       = r_ite.r10_color,
		    r10_stock_max   = r_ite.r10_stock_max,
		    r10_stock_min   = r_ite.r10_stock_min,
		    r10_vol_cuft    = r_ite.r10_vol_cuft,
		    r10_dias_mant   = r_ite.r10_dias_mant,
		    r10_dias_inv    = r_ite.r10_dias_inv,
		    r10_sec_item    = r_ite.r10_sec_item
		WHERE r10_compania IN (codcia1, codcia2)
		  AND r10_codigo   = r_ite.r10_codigo
	DISPLAY 'Actualizando el Item ', r_ite.r10_codigo CLIPPED, '.'
	LET i = i + 1
END FOREACH
DISPLAY 'Se actualizaron un total de ', i USING "<<<<<&", ' Items. Ok'
DISPLAY ' '

END FUNCTION
