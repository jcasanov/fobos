SELECT z20_areaneg, z06_zona_cobro, z20_codcli,    z01_nomcli,  z20_tipo_doc,
       z20_num_doc, z20_dividendo,  z20_fecha_emi, z20_fecha_vcto,
       (z20_fecha_vcto - TODAY) antiguedad,
       (z20_saldo_cap + z20_saldo_int) saldo
FROM cxct020, cxct006, cxct002, cxct001
WHERE z20_compania =           1    AND z20_localidad =      1
  AND z20_moneda = "DO"             AND (z20_saldo_cap + z20_saldo_int) > 0
  AND z01_codcli = z20_codcli       AND z02_compania = z20_compania
  AND z02_localidad = z20_localidad AND z02_codcli = z20_codcli
  AND z06_zona_cobro = z02_zona_cobro
ORDER BY 1 ASC, 4 ASC, 9 ASC
