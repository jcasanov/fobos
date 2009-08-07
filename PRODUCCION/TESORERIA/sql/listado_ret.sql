SELECT p01_nomprov[1,20], p01_tipo_doc, p01_num_doc, 
       p28_porcentaje porc, SUM(p28_valor_base) valor_base, 
       SUM(p28_valor_ret) valor_ret, COUNT(*) num_ret 
  FROM cxpt027, cxpt028, cxpt001
 WHERE p27_compania  = 1 
   AND p27_localidad = 1 
   AND p27_estado    = "A"
   AND p27_moneda = "DO"
   AND DATE(p27_fecing) BETWEEN mdy(01, 1, 2005) AND mdy(01, 31, 2005)
   AND p28_compania = p27_compania
   AND p28_localidad = p27_localidad
   AND p28_num_ret = p27_num_ret
   AND p28_codprov = p27_codprov
   AND p28_tipo_ret = "F"
   AND p01_codprov = p27_codprov
 GROUP BY p01_nomprov, p01_tipo_doc, p01_num_doc, p28_tipo_ret, p28_porcentaje
