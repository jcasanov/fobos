SELECT UNIQUE b.*  FROM rept019 c, rept041 b
  WHERE c.r19_compania    =           1
   AND c.r19_localidad   =      1
   AND c.r19_cod_tran    = "TR"
   AND c.r19_tipo_dev    = "FA"
   AND c.r19_num_dev     =             44829
   AND b.r41_compania    = c.r19_compania
    AND b.r41_localidad   = c.r19_localidad
   AND b.r41_cod_tr      = c.r19_cod_tran
    AND b.r41_num_tr      = c.r19_num_tran
   AND NOT EXISTS  (SELECT 1 FROM rept019 a, rept041 d
	  WHERE a.r19_compania    = b.r41_compania
	    AND a.r19_localidad   = b.r41_localidad
	    AND a.r19_cod_tran    IN ("TR")
	    AND a.r19_tipo_dev    = c.r19_tipo_dev
	    AND a.r19_num_dev     = c.r19_num_dev
	    AND a.r19_bodega_ori  = c.r19_bodega_dest
	    AND a.r19_bodega_dest = c.r19_bodega_ori
	    AND d.r41_compania    = a.r19_compania
	    AND d.r41_localidad   = a.r19_localidad
	    AND d.r41_cod_tr      = a.r19_cod_tran
	    AND d.r41_num_tr      = a.r19_num_tran)
    AND EXISTS (SELECT 1 FROM rept020
		  WHERE r20_compania  = b.r41_compania
		    AND r20_localidad = b.r41_localidad
		    AND r20_cod_tran  = b.r41_cod_tr
		    AND r20_num_tran  = b.r41_num_tr
		    AND r20_item      IN ('49158'))
