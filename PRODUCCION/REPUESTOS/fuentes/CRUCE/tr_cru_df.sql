SELECT a.*
                FROM rept088 a
                WHERE a.r88_compania     = 1
                  AND a.r88_localidad    = 3
                  AND a.r88_cod_fact_nue = 'FA'
                  AND a.r88_num_fact_nue = 167381
                  AND NOT EXISTS
                        (SELECT 1 FROM rept088 b
                                WHERE b.r88_compania     = a.r88_compania
                                  AND b.r88_localidad    = a.r88_localidad
                                  AND b.r88_cod_fact_nue = a.r88_cod_fact
                                  AND b.r88_num_fact_nue = a.r88_num_fact);

SELECT r20_item item FROM rept020 WHERE r20_compania = 999 INTO TEMP t1;

INSERT INTO t1
                SELECT r20_item
                        FROM rept020
                        WHERE r20_compania  = 1
                          AND r20_localidad = 3
                          AND r20_cod_tran  = 'FA'
                          AND r20_num_tran  = 167381
                          AND r20_bodega    =
                                (SELECT r02_codigo
                                        FROM rept002
                                        WHERE r02_compania   = r20_compania
                                          AND r02_localidad  = r20_localidad
                                          AND r02_estado     = 'A'
                                          AND r02_tipo       = 'S'
                                          AND r02_area       = 'R'
                                          AND r02_tipo_ident = 'V'
                                          AND r02_factura    = 'S');

select * from t1;

SELECT UNIQUE b.*
	FROM rept019 c, rept041 b
	WHERE c.r19_compania    = 1
	  AND c.r19_localidad   = 3
	  AND c.r19_cod_tran    = "TR"
	  AND c.r19_tipo_dev    = "FA"
	  AND c.r19_num_dev     = 167381
	  AND b.r41_compania    = c.r19_compania
	  AND b.r41_localidad   = c.r19_localidad
	  AND b.r41_cod_tr      = c.r19_cod_tran
	  AND b.r41_num_tr      = c.r19_num_tran
	  AND  EXISTS
		(SELECT 1 FROM rept019 a, rept041 d
			WHERE a.r19_compania    = b.r41_compania
			  AND a.r19_localidad   = b.r41_localidad
			  AND a.r19_cod_tran   IN ("TR")
			  AND a.r19_tipo_dev    = c.r19_tipo_dev
			  AND a.r19_num_dev     = c.r19_num_dev
			  AND a.r19_bodega_ori  = c.r19_bodega_dest
			  AND d.r41_compania    = a.r19_compania
			  AND d.r41_localidad   = a.r19_localidad
			  AND d.r41_cod_tr      = a.r19_cod_tran
	  AND d.r41_num_tr      = a.r19_num_tran)
	  AND EXISTS
		(SELECT 1 FROM rept020
			WHERE r20_compania   = b.r41_compania
			  AND r20_localidad  = b.r41_localidad
			  AND r20_cod_tran   = b.r41_cod_tr
			  AND r20_num_tran   = b.r41_num_tr
			  AND r20_item      IN
				(SELECT item FROM t1
					WHERE item = r20_item));

drop table t1;
