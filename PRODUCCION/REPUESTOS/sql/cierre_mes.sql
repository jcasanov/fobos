BEGIN WORK;

INSERT INTO rept031
SELECT r11_compania,
       (SELECT YEAR(current - 10 UNITS DAY) FROM dual),
       (SELECT MONTH(current - 10 UNITS DAY) FROM dual),
       r11_bodega, r11_item, r11_stock_act,
       r10_costo_mb, r10_costo_ma, r10_precio_mb,
       r10_precio_ma
  FROM rept011, rept010
 WHERE r11_compania  = 1
   AND r11_stock_act > 0
   AND r10_compania  = r11_compania
   AND r10_codigo    = r11_item;

UPDATE rept000 SET r00_anopro = (SELECT YEAR(current) FROM dual),
                   r00_mespro = (SELECT MONTH(current) FROM dual)
 WHERE r00_compania = 1;

COMMIT WORK;
