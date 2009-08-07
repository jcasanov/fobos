SELECT p01_nomprov, p20_fecha_emi, p28_num_ret,
                 p28_num_doc, p20_fecha_emi, p28_tipo_ret, p27_moneda,
                 p28_valor_base, p28_porcentaje, p28_valor_ret
                 FROM cxpt027, cxpt028, cxpt020, cxpt001
                 WHERE p27_compania =   1
                 AND p27_localidad =   1
                 AND p27_moneda =   'DO'
                 AND p28_compania = p27_compania
                 AND p28_localidad = p27_localidad
                 AND p28_num_ret = p27_num_ret
                 AND p28_codprov = p27_codprov
                 AND p20_compania = p28_compania
                 AND p20_localidad = p28_localidad
                 AND p20_codprov = p28_codprov
                 AND p20_tipo_doc = p28_tipo_doc
                 AND p20_num_doc = p28_num_doc
                 AND p20_fecha_emi BETWEEN '11-15-2003' AND  '11-20-2003'
                  AND p20_cod_depto = 3
                 ORDER BY 2
