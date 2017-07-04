select --p27_num_ret as num_ret,
        --p28_secuencia as sec,
        p28_codprov as codprov,
        p01_num_doc as cedruc,
        p01_nomprov as proveedor,
	{--
        p28_tipo_doc as td,
        p28_num_doc as num_d,
        p28_dividendo as divi,
        p28_valor_fact as val_fac,
	--}
        p28_tipo_ret as tret,
        p28_porcentaje as porc,
        --p28_codigo_sri as codsri,
	--b13_cuenta[1 ,8] as cuenta,
        nvl(sum(p28_valor_base), 0) as val_base,
        nvl(sum(p28_valor_ret), 0) as valor_ret,
	nvl(sum(b13_valor_base), 0) as val_ctb
	--p27_fecing as fecing
        from cxpt027, cxpt028, cxpt001, ctbt012, ctbt013
        where p27_compania         = 1
          and p27_localidad        = 3
	  and p27_estado           = 'A'
	  and extend(p27_fecing, year to month) = '2011-12'
	  and p28_compania         = p27_compania
	  and p28_localidad        = p27_localidad
	  and p28_num_ret          = p27_num_ret
	  and p28_tipo_ret         = 'F'
	  and p01_codprov          = p28_codprov
	  and b12_compania         = p27_compania
	  and b12_tipo_comp        = p27_tip_contable
	  and b12_num_comp         = p27_num_contable
	  and b12_estado           = 'M'
	  and b13_compania         = b12_compania
	  and b13_tipo_comp        = b12_tipo_comp
	  and b13_num_comp         = b12_num_comp
	  --and b13_cuenta[1, 8]     = '21040301'
	  and b13_cuenta           = '21040301001'
	group by 1, 2, 3, 4, 5
	--having sum(b13_valor_base) <> sum(p28_valor_ret * (-1))
	into temp t1;
select sum(valor_ret) v_ret, sum(val_ctb) v_ctb
	from t1;
drop table t1;

{
union
select --p27_num_ret as num_ret,
        --p28_secuencia as sec,
        p28_codprov as codprov,
        p01_num_doc as cedruc,
        p01_nomprov as proveedor,
	--
        p28_tipo_doc as td,
        p28_num_doc as num_d,
        p28_dividendo as divi,
        p28_valor_fact as val_fac,
	--
        p28_tipo_ret as tret,
        p28_porcentaje as porc,
        --p28_codigo_sri as codsri,
	b13_cuenta[1 ,8] as cuenta,
        nvl(sum(p28_valor_base), 0) as val_base,
        nvl(sum(p28_valor_ret), 0) as valor_ret,
	nvl(sum(b13_valor_base), 0) as val_ctb
	--p27_fecing as fecing
        from cxpt027, cxpt028, cxpt001, ctbt012, ctbt013
        where p27_compania         = 1
          and p27_localidad        = 3
	  and p27_estado           = 'A'
	  and extend(p27_fecing, year to month) = '2011-12'
	  and p28_compania         = p27_compania
	  and p28_localidad        = p27_localidad
	  and p28_num_ret          = p27_num_ret
	  and p28_tipo_ret         = 'I'
	  and p01_codprov          = p28_codprov
	  and b12_compania         = p27_compania
	  and b12_tipo_comp        = p27_tip_contable
	  and b12_num_comp         = p27_num_contable
	  and b12_estado           = 'M'
	  and b13_compania         = b12_compania
	  and b13_tipo_comp        = b12_tipo_comp
	  and b13_num_comp         = b12_num_comp
	  --and b13_cuenta[1, 8]     = '21040201'
	  and b13_cuenta           = '21040301001'
	group by 1, 2, 3, 4, 5
	having sum(b13_valor_base) <> sum(p28_valor_ret * (-1))
}
	--order by 1;
