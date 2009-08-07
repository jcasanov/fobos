SELECT r10_codigo, r10_nombre,
       CASE NVL(r105_valor, r104_valor_default)
			WHEN 0 THEN "E"
			WHEN 1 THEN "A"
			WHEN 2 THEN "B"
			WHEN 3 THEN "C"
			ELSE NULL
	   END
  FROM rept010, rept104, rept105
 WHERE r10_compania  =           1
   AND r10_linea = "ADM"
   AND  1=1
   AND r104_compania  = r10_compania
   AND r104_codigo    = "ABC"
-- AND NVL(r105_valor, r104_valor_default) IN (1,0)
   AND r105_compania  = r104_compania
   AND r105_parametro = r104_codigo
   AND r105_item      = r10_codigo
   AND r105_fecha_fin IS NULL
