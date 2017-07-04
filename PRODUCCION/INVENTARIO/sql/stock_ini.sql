DROP FUNCTION ff_obt_sto_ini;
CREATE FUNCTION ff_obt_sto_ini(codcia INT, bod_par CHAR(2),
				item VARCHAR(15,6), fecha DATE)
	RETURNING DECIMAL;
DEFINE fecing		LIKE rept020.r20_fecing;
DEFINE max_fecha	LIKE rept020.r20_fecing;
DEFINE bodega		CHAR(2);
DEFINE fec_ini		DATETIME YEAR TO SECOND;
DEFINE stock_inicial	DECIMAL(8,2);
DEFINE r19_bod_ori	CHAR(2);
DEFINE r19_bod_dest	CHAR(2);
DEFINE r20_bodeg	CHAR(2);
DEFINE r20_cantven	DECIMAL(8,2);
DEFINE r20_stockant	DECIMAL(8,2);
DEFINE r20_stockbd	DECIMAL(8,2);
DEFINE g21_tip		CHAR(1);
DEFINE cuantos		INTEGER;

LET fec_ini       = EXTEND(fecha, YEAR TO SECOND);
LET stock_inicial = 0;
SELECT r20_bodega bode, r20_cant_ven cant, r20_stock_ant sto_ant,
	r20_stock_bd sto_bd, r19_bodega_ori bod_ori, r19_bodega_dest bod_des,
	g21_tipo tipo_t, r20_fecing
	FROM rept020, rept019, gent021
	WHERE r20_compania   = codcia
	  AND r20_item       = item
	  AND r20_fecing    <= fec_ini
	  AND r20_compania   = r19_compania
	  AND r20_localidad  = r19_localidad
	  AND r20_cod_tran   = r19_cod_tran
	  AND r20_num_tran   = r19_num_tran
	  AND r20_cod_tran   = g21_cod_tran
	ORDER BY r20_fecing DESC
	INTO TEMP t1;
SELECT COUNT(*) INTO cuantos FROM t1;
IF cuantos > 0 THEN
	SELECT MAX(a.r20_fecing) INTO max_fecha FROM t1 a;
	SELECT t1.*
		INTO r20_bodeg, r20_cantven, r20_stockant, r20_stockbd,
			r19_bod_ori, r19_bod_dest, g21_tip, fecing
		FROM t1
		WHERE r20_fecing = max_fecha;
	LET bodega = bod_par;
	IF g21_tip = 'T' THEN
		IF bod_par = r19_bod_ori THEN
			LET bodega = r19_bod_ori;
		END IF;
		IF bod_par = r19_bod_dest THEN
			LET bodega = r19_bod_dest;
		END IF;
	ELSE
		IF g21_tip <> 'C' THEN
			LET bodega = r20_bodeg;
		END IF;
	END IF;
	IF g21_tip <> 'T' THEN
		IF g21_tip = 'E' THEN
			LET r20_cantven = r20_cantven * (-1);
		END IF;
		LET stock_inicial = r20_stockant + r20_cantven;
	ELSE
		IF bodega = r19_bod_ori THEN
			LET stock_inicial = r20_stockant - r20_cantven;
		END IF;
		IF bodega = r19_bod_dest THEN
			LET stock_inicial = r20_stockbd + r20_cantven;
		END IF;
	END IF;
END IF;
DROP TABLE t1;
RETURN stock_inicial;

END FUNCTION;
