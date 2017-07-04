SELECT r19_bodega_dest bod, r20_item item,
	NVL(SUM(r20_cant_ven), 0) * (-1) cant_tr
	FROM rept019, rept020
	WHERE r19_compania    = 1
	  AND r19_localidad   = 1
	  AND r19_cod_tran    = "TR"
	  AND r19_bodega_ori  = "99"
	  --AND r19_bodega_dest = "64"
	  AND r19_tipo_dev    = "FA"
	  AND r19_num_dev     = 45946
	  AND r20_compania    = r19_compania
	  AND r20_localidad   = r19_localidad
	  AND r20_cod_tran    = r19_cod_tran
	  AND r20_num_tran    = r19_num_tran
	  --AND r20_item        = "1906"
	group by 1, 2
UNION
SELECT r19_bodega_ori bod, r20_item item,
	NVL(SUM(r20_cant_ven), 0) cant_tr
	FROM rept019, rept020
	WHERE r19_compania    = 1
	  AND r19_localidad   = 1
	  AND r19_cod_tran    = "TR"
	  --AND r19_bodega_ori  = "64"
	  AND r19_bodega_dest = "99"
	  AND r19_tipo_dev    = "FA"
	  AND r19_num_dev     = 45946
	  AND r20_compania    = r19_compania
	  AND r20_localidad   = r19_localidad
	  AND r20_cod_tran    = r19_cod_tran
	  AND r20_num_tran    = r19_num_tran
	  --AND r20_item        = "1906"
	group by 1, 2
UNION
SELECT r36_bodega_real bod, r37_item item,
	NVL(SUM(r37_cant_ent), 0) * (-1) cant_tr
	FROM rept036, rept037
	WHERE r36_compania    = 1
	  AND r36_localidad   = 1
	  AND r36_bodega      = "99"
	  --AND r36_num_entrega <> 7831
	  AND r36_num_ord_des = 6370
	--  AND r36_bodega_real = "64"
	  AND r36_estado      = "A"
	  AND r37_compania    = r36_compania
	  AND r37_localidad   = r36_localidad
	  AND r37_bodega      = r36_bodega
	  AND r37_num_entrega = r36_num_entrega
	  --AND r37_item        = "1906"
	group by 1, 2
	INTO TEMP t1;
select * from t1;
drop table t1;
