---------------------------------------------
SET LOCK MODE TO WAIT;
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

-----------------------------------------------
-- ACTUALIZA REGISTROS EN LA REPT011 (DISTINTOS)
-----------------------------------------------

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
SET LOCK MODE TO WAIT;
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
        t1
WHERE
            r11_compania        = compania
        AND r11_bodega          = bodega
        AND r11_item            = item
GROUP BY 1,2,3,4,5,6,7
HAVING 
	r11_stock_act IS NULL
INTO TEMP tmp_stock;
SELECT count(*) noexisten FROM tmp_stock ;

DROP TABLE t1;

SELECT trim(item), trim(bodega), r11_stock_act, stock_act FROM tmp_stock;

BEGIN WORK;
INSERT INTO rept011 
	SELECT  compania, bodega, item, "SN", "", 
		stock_ant, stock_act,0,0,
		"","","","","",""
	FROM
		tmp_stock;
	
COMMIT WORK;

DROP TABLE tmp_stock;



