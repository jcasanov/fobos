SELECT z20_areaneg, z02_zona_cobro, z20_codcli, z01_nomcli,
        z20_tipo_doc, z20_num_doc, z20_dividendo, z20_fecha_emi, 
       z20_fecha_vcto, (z20_fecha_vcto - DATE("08/19/2011")) antiguedad,
     NVL((SELECT a.z23_valor_cap + a.z23_valor_int +
 a.z23_saldo_cap + a.z23_saldo_int
    FROM cxct023 a, cxct022 b
             WHERE a.z23_compania  = z20_compania
                AND a.z23_localidad = z20_localidad
                AND a.z23_codcli    = z20_codcli
                AND a.z23_tipo_doc  = z20_tipo_doc
                AND a.z23_num_doc   = z20_num_doc
 AND a.z23_div_doc   = z20_dividendo
                AND b.z22_compania  = a.z23_compania
       AND b.z22_localidad = a.z23_localidad
                AND b.z22_codcli    = a.z23_codcli
             AND b.z22_tipo_trn  = a.z23_tipo_trn
                AND b.z22_num_trn   = a.z23_num_trn
                AND b.z22_fecing    = (SELECT MAX(d.z22_fecing)
   FROM cxct023 c, cxct022 d
 WHERE c.z23_compania   = z20_compania
    AND c.z23_localidad  = z20_localidad
    AND c.z23_codcli   = z20_codcli
    AND c.z23_tipo_doc   = z20_tipo_doc
    AND c.z23_num_doc    = z20_num_doc
    AND c.z23_div_doc    = z20_dividendo
    AND d.z22_compania   = c.z23_compania
    AND d.z22_localidad  = c.z23_localidad
    AND d.z22_codcli     = c.z23_codcli
    AND d.z22_tipo_trn   = c.z23_tipo_trn
    AND d.z22_num_trn    = c.z23_num_trn
    AND d.z22_fecing    <= "2011-08-19 23:59:59")),
           z20_saldo_cap + z20_saldo_int -
 NVL((SELECT SUM(e.z23_valor_cap + e.z23_valor_int)
    FROM cxct023 e
  WHERE e.z23_compania  = z20_compania
     AND e.z23_localidad = z20_localidad
     AND e.z23_codcli    = z20_codcli
     AND e.z23_tipo_doc  = z20_tipo_doc
     AND e.z23_num_doc   = z20_num_doc
     AND e.z23_div_doc   = z20_dividendo), 0)) saldo
  FROM cxct020, cxct001, OUTER cxct002
  WHERE z20_compania =           1
   AND z20_localidad =      1
   AND z20_moneda = "DO"
   AND z20_fecha_emi <= "08/19/2011"
    AND z01_codcli = z20_codcli
    AND z02_compania = z20_compania
    AND z02_localidad = z20_localidad
    AND z02_codcli = z20_codcli
 --INTO TEMP temp_cartera;
