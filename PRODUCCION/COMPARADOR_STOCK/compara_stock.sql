----------------------------------------
SELECT
        r11_compania    compania,
        r11_bodega      bodega,
        r11_item        item,
        r11_stock_act   stock_act,
        r11_stock_ant   stock_ant
FROM
        rept011
WHERE
        r11_compania = 99
INTO TEMP tmp_stock;

LOAD FROM "stock.unl" INSERT INTO tmp_stock;

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
	tmp_stock
WHERE
	    r11_compania        = compania
        AND r11_bodega          = bodega
        AND r11_item            = item
	AND (r11_stock_act	<> stock_act
--	OR  r11_stock_ant	<> stock_ant
	)
INTO TEMP t1;

SELECT "distintos: " || round(count(*),0) total_dist FROM t1; 

SELECT trim(item), bodega, r11_stock_act, stock_act FROM t1;
DROP TABLE t1;

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
SELECT trim(item), bodega, r11_stock_act, stock_act FROM t1 WHERE r11_stock_act IS  NULL;
DROP TABLE t1;

