SELECT cxct022.ROWID, z22_tipo_trn, z22_num_trn, z22_fecing
	FROM cxct023, cxct022
	WHERE z23_tipo_doc  = 'FA'
	  AND z23_num_doc   = '48544'
	  AND z22_compania  = z23_compania
	  AND z22_localidad = z23_localidad
	  AND z22_codcli    = z23_codcli
	  AND z22_tipo_trn  = z23_tipo_trn
	  AND z22_num_trn   = z23_num_trn
	ORDER BY 1;
SELECT a.ROWID num_id, a.z22_compania cia, a.z22_localidad loc,
        a.z22_codcli codcli, a.z22_tipo_trn tip_tr, a.z22_num_trn num_tr,
        a.z22_fecing fecing
        FROM cxct023 b, cxct022 a
        WHERE b.z23_compania  = 1
          AND b.z23_localidad = 1
          AND b.z23_codcli    = 7186
          AND EXISTS
                (SELECT 1 FROM cxct025
                        WHERE z25_compania   = b.z23_compania
                          AND z25_localidad  = b.z23_localidad
                          --AND z25_numero_sol = 0
                          AND z25_codcli     = b.z23_codcli
                          AND z25_tipo_doc   = b.z23_tipo_doc
                          AND z25_num_doc    = b.z23_num_doc
                          AND z25_dividendo  = b.z23_div_doc)
          AND a.z22_compania  = b.z23_compania
          AND a.z22_localidad = b.z23_localidad
          AND a.z22_codcli    = b.z23_codcli
          AND a.z22_tipo_trn  = b.z23_tipo_trn
          AND a.z22_num_trn   = b.z23_num_trn
          AND a.ROWID        >=
                (SELECT MAX(c.ROWID)
                FROM cxct023 d, cxct022 c
                WHERE d.z23_compania  = a.z22_compania
                  AND d.z23_localidad = a.z22_localidad
                  AND d.z23_codcli    = a.z22_codcli
                  AND d.z23_tipo_trn  = a.z22_tipo_trn
                  AND d.z23_num_trn   = a.z22_num_trn
                  AND EXISTS
                        (SELECT 1 FROM cxct025
                                WHERE z25_compania   = d.z23_compania
                                  AND z25_localidad  = d.z23_localidad
                                  --AND z25_numero_sol = 0
                                  AND z25_codcli     = d.z23_codcli
                                  AND z25_tipo_doc   = d.z23_tipo_doc
                                  AND z25_num_doc    = d.z23_num_doc
                                  AND z25_dividendo  = d.z23_div_doc)
                  AND c.z22_compania  = d.z23_compania
                  AND c.z22_localidad = d.z23_localidad
		  AND c.z22_codcli    = d.z23_codcli
                  AND c.z22_tipo_trn  = 'AJ'
                  AND c.z22_num_trn   = 10556)
	INTO TEMP t1;
SELECT a.num_id n_id, a.tip_tr t_tr, a.num_tr n_tr, a.fecing fec
        FROM t1 a
        WHERE a.num_id = (SELECT MIN(b.num_id) FROM t1 b)
        INTO TEMP t2;
SELECT * FROM t1;
SELECT * FROM t1
        WHERE fecing >= (SELECT fec FROM t2)
          --AND num_id NOT IN (SELECT n_id FROM t2)
        INTO TEMP t3;
DROP TABLE t1;
SELECT * FROM t2;
DROP TABLE t2;
SELECT * FROM t3
        ORDER BY 1;
DROP TABLE t3;
