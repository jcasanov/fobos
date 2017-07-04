select j10_codigo_caja caja, j10_tipo_fuente fu, j10_tip_contable tp,
	j10_num_contable num, b13_cuenta cta, b10_descripcion nom
	from cajt010, ctbt012, ctbt013, ctbt010
	where j10_estado     = 'P'
	  and b12_compania   = j10_compania
	  and b12_tipo_comp  = j10_tip_contable
	  and b12_num_comp   = j10_num_contable
	  and b12_estado    <> 'E'
	  and b12_origen     = 'A'
	  and b13_compania   = b12_compania
	  and b13_tipo_comp  = b12_tipo_comp
	  and b13_num_comp   = b12_num_comp
	  and b13_cuenta    <> '11010101005'
	  and b10_compania   = b13_compania
	  and b10_cuenta     = b13_cuenta
	into temp t1;
select count(*) tot_reg from t1;
select caja, fu, cta, nom[1,25], count(*) tot_cta from t1 group by 1, 2, 3, 4;
drop table t1;
select b13_compania cia, b13_tipo_comp tp, b13_num_comp num, b13_cuenta cta,
	b10_descripcion nom
	from ctbt012, ctbt013, ctbt010
	where b12_compania   = 2
	  and b12_estado    <> 'E'
	  and b12_origen     = 'A'
	  and b13_compania   = b12_compania
	  and b13_tipo_comp  = b12_tipo_comp
	  and b13_num_comp   = b12_num_comp
	  and b13_cuenta    in ('11010101005', '11010101007')
	  and b10_compania   = b13_compania
	  and b10_cuenta     = b13_cuenta
	into temp t1;
select t1.* from t1
	where exists (select * from rept040
				where r40_compania  = cia
				  and r40_tipo_comp = tp
				  and r40_num_comp  = num)
	union
	select t1.* from t1
		where exists (select * from cajt010
				where j10_compania     = cia
				  and j10_tip_contable = tp
				  and j10_num_contable = num)
	into temp t2;
select t1.* from t1
	where not exists (select t2.* from t2
				where t2.cia = t1.cia
				  and t2.tp  = t1.tp
				  and t2.num = t1.num)
	into temp t3;
select count(*) tot_t1 from t1;
drop table t1;
select count(*) tot_t2 from t2;
drop table t2;
select count(*) tot_t3 from t3;
select cta, count(*) tot_dia from t3 group by 1 order by 2;
--select * from t3;
drop table t3;
