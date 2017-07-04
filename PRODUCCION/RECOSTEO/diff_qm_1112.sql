select b12_tipo_comp tc, b12_num_comp num, b13_secuencia sec, b13_cuenta cta,
	b13_valor_base val_12
	from acero_qm@acgyede:ctbt012, acero_qm@acgyede:ctbt013
	where b12_compania     = 1
	  and b12_estado      <> 'E'
	  and b12_fec_proceso between mdy(01, 01, 2009)
				  and mdy(11, 01, 2009)
	  and b13_compania     = b12_compania
	  and b13_tipo_comp    = b12_tipo_comp
	  and b13_num_comp     = b12_num_comp
	  and b13_cuenta      matches '114*'
	into temp tmp_s12;

select b12_tipo_comp tc1, b12_num_comp num1, b13_secuencia sec1,
	b13_cuenta cta1, b13_valor_base val_11
	from acero_qm@acuiopr:ctbt012, acero_qm@acuiopr:ctbt013
	where b12_compania     = 1
	  and b12_estado      <> 'E'
	  and b12_fec_proceso between mdy(01, 01, 2009)
				  and mdy(11, 01, 2009)
	  and b13_compania     = b12_compania
	  and b13_tipo_comp    = b12_tipo_comp
	  and b13_num_comp     = b12_num_comp
	  and b13_cuenta      matches '114*'
	into temp tmp_s11;

select count(*) tot_s11 from tmp_s11;
select count(*) tot_s12 from tmp_s12;

select tmp_s12.*, val_11
	from tmp_s11, tmp_s12
	where tc      = tc1
	  and num     = num1
	  and cta     = cta1
	  and sec     = sec1
	  and val_12 <> val_11
	into temp t1;

drop table tmp_s11;
drop table tmp_s12;

select round(sum(val_11), 2) val_11, round(sum(val_12), 2) val_12
	from t1;

select count(*) tot_t1 from t1;

select * from t1 order by 3, 1, 2;

drop table t1;
