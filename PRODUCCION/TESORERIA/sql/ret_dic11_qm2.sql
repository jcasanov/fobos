select p28_tipo_ret as tret,
	p28_porcentaje as porc,
        nvl(sum(p28_valor_base), 0) as val_base,
        nvl(sum(p28_valor_ret), 0) as valor_ret
        from cxpt027, cxpt028
        where p27_compania         = 1
          and p27_localidad        = 3
	  and p27_estado           = 'A'
	  and extend(p27_fecing, year to month) = '2011-12'
	  and p28_compania         = p27_compania
	  and p28_localidad        = p27_localidad
	  and p28_num_ret          = p27_num_ret
	group by 1, 2
	order by 1, 2;
select b12_origen orig, b13_cuenta cta, b10_descripcion nomcta,
	nvl(sum(b13_valor_base), 0) saldo
	from ctbt012, ctbt013, ctbt010
	where b12_compania  = 1
	  and b12_estado    = 'M'
	  and extend(b12_fec_proceso, year to month) = '2011-12'
	  and b13_compania  = b12_compania
	  and b13_tipo_comp = b12_tipo_comp
	  and b13_num_comp  = b12_num_comp
	  and b13_cuenta[1,8] = '21040301'
	  and b10_compania  = b13_compania
	  and b10_cuenta    = b13_cuenta
	group by 1, 2, 3
	order by 1, 2, 3;
