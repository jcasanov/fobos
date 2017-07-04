{
DROP TABLE tmp_bod;
DROP TABLE tmp_pro;
DROP TABLE tmp_sto1;
DROP TABLE tmp_sto2;
DROP TABLE tmp_ite;
}
SELECT r02_codigo bode, r02_tipo tipo
        FROM rept002
        WHERE r02_compania   = 1
          AND r02_localidad  = 1
          AND r02_estado     = 'A'
          AND r02_factura    = 'S'
          AND r02_area       = 'R'
          AND r02_tipo_ident IN ('V', 'X')
INTO TEMP tmp_bod;
SELECT r22_bodega bod, r22_item item, r22_cantidad cant
        FROM rept022
        WHERE r22_compania  = 1
          AND r22_localidad = 1
          AND r22_numprof   = 164474
        INTO TEMP tmp_pro;
SELECT COUNT(*) cuantos
        FROM tmp_pro
        WHERE bod = (SELECT bode FROM tmp_bod WHERE tipo = 'S');
SELECT bode FROM tmp_bod WHERE tipo <> 'S';
SELECT UNIQUE item FROM tmp_pro;
SELECT r11_bodega bod_sto1, r11_item ite_sto1, r11_stock_act stock1
        FROM rept011
        WHERE r11_compania   = 1
          AND r11_bodega    IN (SELECT bode FROM tmp_bod WHERE tipo <> 'S')
          AND r11_item      IN (SELECT UNIQUE item FROM tmp_pro)
          AND r11_stock_act <> 0
        INTO TEMP tmp_sto1;
select * from tmp_sto1;
SELECT ite_sto1 ite_sto2, NVL(SUM(stock1), 0) stock2
        FROM tmp_sto1
        GROUP BY 1
        INTO TEMP t1;
select * from t1;
SELECT ite_sto2, (stock2 -
        NVL((SELECT SUM(cant)
                FROM tmp_pro
                WHERE item = ite_sto2
                  AND bod  IN (SELECT bode
                                FROM tmp_bod
                                WHERE tipo <> 'S')), 0)) stock2
        FROM t1
        INTO TEMP tmp_sto2;
DROP TABLE t1;
select * from tmp_sto2;
SELECT bod_sto1, item, cant, stock1
        FROM tmp_pro, tmp_sto2, tmp_sto1
        WHERE item      = ite_sto2
          AND ((cant   <> stock2
          AND   stock2  > 0)
           OR   stock2 <> 0)
          AND bod       = (SELECT bode FROM tmp_bod WHERE tipo = 'S')
          AND ite_sto1  = ite_sto2
        INTO TEMP tmp_ite;
DROP TABLE tmp_bod;
DROP TABLE tmp_pro;
DROP TABLE tmp_sto1;
DROP TABLE tmp_sto2;
SELECT COUNT(*) cuantos FROM tmp_ite;
drop table tmp_ite;
