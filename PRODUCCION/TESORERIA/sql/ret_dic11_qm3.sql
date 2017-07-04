select p20_codprov as codprov, p01_num_doc as cedruc, p01_nomprov as proveedor,
	p28_tipo_ret as tret, p28_porcentaje as porc,
        nvl(sum(p28_valor_base), 0) as val_base,
        nvl(sum(p28_valor_ret), 0) as valor_ret
        from cxpt020, cxpt028, cxpt027, cxpt001
        where p20_compania         = 1
          and p20_localidad        = 3
	  and p20_tipo_doc         = 'FA'
	  and extend(p20_fecing, year to month) = '2011-12'
	  and p28_compania         = p20_compania
	  and p28_localidad        = p20_localidad
	  and p28_codprov          = p20_codprov
	  and p28_tipo_doc         = p20_tipo_doc
	  and p28_num_doc          = p20_num_doc
	  and p28_dividendo        = p28_dividendo
	  and p27_compania         = p28_compania
	  and p27_localidad        = p28_localidad
	  and p27_num_ret          = p28_num_ret
	  and p27_estado           = 'A'
	  and p01_codprov          = p27_codprov
	group by 1, 2, 3, 4, 5
	into temp t1;
select * from t1;
select tret, porc, round(sum(val_base), 2) val_base,
	round(sum(valor_ret), 2) val_ret
	from t1
	group by 1, 2
	order by 1, 2;
drop table t1;
