
select p01_nomprov, p28_valor_base, p28_tipo_doc, p28_num_doc,
	           p28_valor_fact, p28_tipo_ret, p28_porcentaje, 
	           p28_valor_ret, date(p27_fecing)
            from cxpt027, cxpt028, cxpt001 
            where p27_compania  = 1 
	      and p27_localidad = 1
              and p27_estado <> "E" 
              and p28_compania  = p27_compania
              and p28_localidad = p27_localidad
              and p28_num_ret   = p27_num_ret
              and p01_codprov   = p28_codprov
	    order by 8, 1, 5, 6 
