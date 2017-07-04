SELECT a01_compania cia_gru, a01_grupo_act grupo, a01_nombre nom_gru,
        a01_aux_activo[1, 8] cta_gru
        FROM actt001
        WHERE a01_compania = 1
UNION
SELECT a01_compania cia_gru, a01_grupo_act grupo, a01_nombre nom_gru,
        a01_aux_dep_act[1, 8] cta_gru
        FROM actt001
        WHERE a01_compania = 1
        INTO TEMP tmp_gru;
SELECT grupo, nom_gru, 0.00 saldo_ini,
      SUM(CASE WHEN a12_valor_mb >= 0 THEN a12_valor_mb ELSE 0 END) valor_ing,
      SUM(CASE WHEN a12_valor_mb <= 0 THEN a12_valor_mb ELSE 0 END) valor_egr
FROM tmp_gru, actt010, outer actt012
WHERE a10_compania      = cia_gru
  AND a10_grupo_act     = grupo
  AND a10_estado       <> "B"
  AND a12_compania      = a10_compania
  AND a12_codigo_bien   = a10_codigo_bien
  AND DATE(a12_fecing) BETWEEN "01/01/2010" AND "12/31/2010"
GROUP BY 1, 2, 3
INTO TEMP t1;
  SELECT grupo, nom_gru, NVL(SUM(a12_valor_mb), 0) saldo_ini, 0.00 valor_ing,
 0.00 valor_egr
 FROM tmp_gru, actt010, actt012
  WHERE grupo            <> 1
    AND a10_compania      = cia_gru
    AND a10_grupo_act     = grupo
    AND a10_estado       <> "B"
    AND a12_compania      = a10_compania
    AND a12_codigo_bien   = a10_codigo_bien
    AND DATE(a12_fecing)  < "01/01/2010"
 GROUP BY 1, 2, 4, 5
UNION
  SELECT grupo, nom_gru, NVL(SUM(a12_valor_mb), 0) saldo_ini, 0.00 valor_ing,
 0.00 valor_egr
 FROM tmp_gru, actt010, actt012
  WHERE grupo             = 1
    AND a10_compania      = cia_gru
    AND a10_grupo_act     = grupo
    AND a10_estado       <> "B"
    AND a12_compania      = a10_compania
    AND a12_codigo_bien   = a10_codigo_bien
    AND DATE(a12_fecing)  < "01/01/2010"
    AND a12_valor_mb      > 0
 GROUP BY 1, 2, 4, 5
UNION
  SELECT grupo, nom_gru, NVL(SUM(a12_valor_mb), 0) saldo_ini, 0.00 valor_ing,
 0.00 valor_egr
 FROM tmp_gru, actt010, actt012
  WHERE grupo             = 1
    AND a10_compania      = cia_gru
    AND a10_grupo_act     = grupo
    AND a10_estado       <> "B"
    AND a12_compania      = a10_compania
    AND a12_codigo_bien   = a10_codigo_bien
    AND YEAR(a12_fecing)  = 2009
    AND a12_valor_mb      < 0
 GROUP BY 1, 2, 4, 5
  INTO TEMP t2;
select * from t2 where grupo = 1;
SELECT grupo, nom_gru, NVL(SUM(saldo_ini), 0) saldo_ini,
        NVL(SUM(valor_ing), 0) valor_ing, NVL(SUM(valor_egr), 0) valor_egr
        FROM t2
        GROUP BY 1, 2
        INTO TEMP t3;
DROP TABLE t2;
select * from t3 where grupo = 1;
drop table tmp_gru;
SELECT t1.grupo, t1.nom_gru, NVL((t1.saldo_ini + t3.saldo_ini), 0) saldo_ini,
        NVL((t1.valor_ing + t3.valor_ing), 0) valor_ing,
        NVL((t1.valor_egr + t3.valor_egr), 0) valor_egr,
        NVL((t1.saldo_ini + t3.saldo_ini + t1.valor_ing + t3.valor_ing +
                t1.valor_egr + t3.valor_egr), 0) saldo_fin
        FROM t1, t3
        WHERE t1.grupo = t3.grupo
        INTO TEMP tmp_mov;
drop table t1;
drop table t3;
select * from tmp_mov order by grupo;
drop table tmp_mov;
