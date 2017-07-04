select n53_cod_liqrol rol, b13_cuenta[1, 8] cuenta,
	b10_descripcion[1, 30] nombre,
	nvl(sum(case when b13_valor_base > 0
		then b13_valor_base
		else 0.00
	end), 0) valor_db,
	nvl(sum(case when b13_valor_base <= 0
		then b13_valor_base
		else 0.00
	end), 0) valor_cr
	from rolt053, ctbt012, ctbt013, ctbt010
	where n53_compania           = 1
	  and ((n53_cod_liqrol       <> 'UT'
	  and  year(n53_fecha_fin)   = 2008)
	   or (n53_cod_liqrol        = 'UT'
	  and  year(n53_fecha_fin)   = 2007))
	  and b12_compania           = n53_compania
	  and b12_tipo_comp          = n53_tipo_comp
	  and b12_num_comp           = n53_num_comp
	  and b12_estado            <> 'E'
	  and year(b12_fec_proceso)  = 2008
	  and b13_compania           = b12_compania
	  and b13_tipo_comp          = b12_tipo_comp
	  and b13_num_comp           = b12_num_comp
	  and b10_compania           = b13_compania
	  and b10_cuenta             = b13_cuenta[1, 8]
	group by 1, 2, 3
	union
	select n57_proceso rol, b13_cuenta[1, 8] cuenta,
		b10_descripcion[1, 30] nombre,
		nvl(sum(case when b13_valor_base > 0
			then b13_valor_base
			else 0.00
		end), 0) valor_db,
		nvl(sum(case when b13_valor_base <= 0
			then b13_valor_base
			else 0.00
		end), 0) valor_cr
		from rolt057, ctbt012, ctbt013, ctbt010
		where n57_compania           = 1
		  and n57_proceso           in ('VA', 'VP')
		  and year(n57_periodo_fin)  = 2008
		  and b12_compania           = n57_compania
		  and b12_tipo_comp          = n57_tipo_comp
		  and b12_num_comp           = n57_num_comp
		  and b12_estado            <> 'E'
		  and year(b12_fec_proceso)  = 2008
		  and b13_compania           = b12_compania
		  and b13_tipo_comp          = b12_tipo_comp
		  and b13_num_comp           = b12_num_comp
		  and b10_compania           = b13_compania
		  and b10_cuenta             = b13_cuenta[1, 8]
		group by 1, 2, 3
	union
	select 'GD' rol, b13_cuenta[1, 8] cuenta,
		b10_descripcion[1, 30] nombre,
		nvl(sum(case when b13_valor_base > 0
			then b13_valor_base
			else 0.00
		end), 0) valor_db,
		nvl(sum(case when b13_valor_base <= 0
			then b13_valor_base
			else 0.00
		end), 0) valor_cr
		from ctbt012, ctbt013, ctbt010
		where b12_compania           = 1
		  and b12_tipo_comp         <> 'DN'
		  and b12_estado            <> 'E'
		  and year(b12_fec_proceso)  = 2008
		  and b13_compania           = b12_compania
		  and b13_tipo_comp          = b12_tipo_comp
		  and b13_num_comp           = b12_num_comp
		  and b13_cuenta[1, 8]      matches '510307*'
		  and b10_compania           = b13_compania
		  and b10_cuenta             = b13_cuenta[1, 8]
		group by 1, 2, 3
	into temp t1;
select cuenta, nombre, round(sum(valor_db), 2) valor_db,
	round(sum(valor_cr), 2) valor_cr
	from t1
	group by 1, 2
	order by 1 desc, 3 desc, 4 asc;
select round(sum(valor_db), 2) total_db, round(sum(valor_cr), 2) total_cr
	from t1;
select rol, round(sum(valor_db), 2) valor_db, round(sum(valor_cr), 2) valor_cr
	from t1
	group by 1
	order by 2 desc, 3 asc;
drop table t1;
