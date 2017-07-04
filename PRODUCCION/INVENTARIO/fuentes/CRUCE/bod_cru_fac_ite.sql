SELECT r19_bodega_ori bod_ori, r20_item item_c,
        NVL(SUM(r20_cant_ven -
                NVL((SELECT SUM(r35_cant_ent)
                        FROM rept035
                        WHERE r35_compania    = r19_compania
                          AND r35_localidad   = r19_localidad
                          AND r35_bodega      = r19_bodega_dest
                          AND r35_num_ord_des = 6223
                          AND r35_item        = r20_item), 0)), 0) cant_c
        FROM rept019, rept020
        WHERE r19_compania    = 1
          AND r19_localidad   = 1
          AND r19_cod_tran    = 'TR'
          AND r19_bodega_dest = '99'
          AND r19_tipo_dev    = 'FA'
          AND r19_num_dev     = 45167
          AND EXISTS (SELECT 1 FROM rept041
                        WHERE r41_compania  = r19_compania
                          AND r41_localidad = r19_localidad
                          AND r41_cod_tran  NOT IN ('DF', 'AF', 'DC')
                          AND r41_cod_tr    = r19_cod_tran
                          AND r41_num_tr    = r19_num_tran)
          AND r20_compania    = r19_compania
          AND r20_localidad   = r19_localidad
          AND r20_cod_tran    = r19_cod_tran
          AND r20_num_tran    = r19_num_tran
        GROUP BY 1, 2
