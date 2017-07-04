---------------------------------------------
SELECT
	r11_compania	compania,
	r11_bodega	bodega,
	r11_item	item,
	r11_stock_act	stock_act,
	r11_stock_ant	stock_ant
FROM
	rept011
WHERE
	r11_compania = 99
INTO TEMP t1;

LOAD FROM "stock.unl" INSERT INTO t1;

-------------------------------------------
SELECT count(*) todos from t1;

SELECT
        compania,
        bodega,
        item,
        r11_stock_act,
        r11_stock_ant,
        stock_act,
        stock_ant
FROM
        rept011,
        t1
WHERE
            r11_compania        = compania
        AND r11_bodega          = bodega
        AND r11_item            = item
        AND r11_stock_act      <> stock_act
INTO TEMP tmp_stock;

SELECT count(*) distintos from tmp_stock;


BEGIN WORK;
UPDATE rept011
	SET 	r11_stock_act = (SELECT stock_act FROM tmp_stock
				 WHERE
					    r11_compania = compania
					AND r11_bodega	 = bodega
					AND r11_item	 = item
				),
		r11_stock_ant = (SELECT stock_ant FROM tmp_stock
				 WHERE
					    r11_compania = compania
					AND r11_bodega	 = bodega
					AND r11_item	 = item
				)
WHERE
	EXISTS(	SELECT * FROM tmp_stock
		WHERE
			    r11_compania	= compania
			AND r11_bodega		= bodega
			AND r11_item		= item
	);
COMMIT WORK;

DROP TABLE tmp_stock;

-----------------------------------------------
-- INSERTA REGISTROS EN LA REPT011 (NO EXISTEN)
-----------------------------------------------

SELECT
        compania,
        bodega,
        item,
        r11_stock_act,
        r11_stock_ant,
        stock_act,
        stock_ant
FROM
        outer  rept011,
        tmp_stock
WHERE
            r11_compania        = compania
        AND r11_bodega          = bodega
        AND r11_item            = item

INTO TEMP t1;
SELECT count(*) noexisten FROM t1 WHERE r11_stock_act IS  NULL;

DROP TABLE t1;


