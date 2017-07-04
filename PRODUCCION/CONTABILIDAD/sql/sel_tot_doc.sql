select count(*) tot_fact_gm, z01_tipo_doc_id tipo_gm
	from acero_gm:rept019, acero_gm:cxct001
	where r19_compania                      = 1
	  and r19_localidad                     = 1
	  and r19_cod_tran                      = 'FA'
	  and extend(r19_fecing, year to month) = '2006-02'
	  and z01_codcli                        = r19_codcli
	group by 2
	into temp t1;
select count(*) tot_fact_gc, z01_tipo_doc_id tipo_gc
	from acero_gc:rept019, acero_gc:cxct001
	where r19_compania                      = 1
	  and r19_localidad                     = 2
	  and r19_cod_tran                      = 'FA'
	  and extend(r19_fecing, year to month) = '2006-02'
	  and z01_codcli                        = r19_codcli
	group by 2
	into temp t2;
select tot_fact_gm + tot_fact_gc total_fact
	from t1, t2
	where tipo_gm = 'R'
	  and tipo_gc = 'R';
select tot_fact_gm + tot_fact_gc total_nv
	from t1, t2
	where tipo_gm = 'C'
	  and tipo_gc = 'C';
drop table t1;
drop table t2;
select count(*) tot_nc_gm
	from acero_gm:cxct021
	where z21_compania                      = 1
	  and z21_localidad                     = 1
	  and z21_tipo_doc                      = 'NC'
	  and extend(z21_fecing, year to month) = '2006-02'
	into temp t1;
select count(*) tot_nc_gc
	from acero_gc:cxct021
	where z21_compania                      = 1
	  and z21_localidad                     = 2
	  and z21_tipo_doc                      = 'NC'
	  and extend(z21_fecing, year to month) = '2006-02'
	into temp t2;
select tot_nc_gm + tot_nc_gm total_nc from t1, t2;
drop table t1;
drop table t2;
select count(*) tot_nd_gm
	from acero_gm:cxct020
	where z20_compania                      = 1
	  and z20_localidad                     = 1
	  and z20_tipo_doc                      = 'ND'
	  and extend(z20_fecing, year to month) = '2006-02'
	into temp t1;
select count(*) tot_nd_gc
	from acero_gc:cxct020
	where z20_compania                      = 1
	  and z20_localidad                     = 2
	  and z20_tipo_doc                      = 'ND'
	  and extend(z20_fecing, year to month) = '2006-02'
	into temp t2;
select tot_nd_gm + tot_nd_gm total_nd from t1, t2;
drop table t1;
drop table t2;
select count(*) total_ret, p28_tipo_ret tipo_ret, c02_porcentaje porc
	from acero_gm:cxpt028, acero_gm:cxpt027, acero_gm:ordt002
	where p28_compania                      = 1
	  and p28_localidad                     = 1
	  and p27_compania                      = p28_compania
	  and p27_localidad                     = p28_localidad
	  and p27_num_ret                       = p28_num_ret
	  and extend(p27_fecing, year to month) = '2006-02'
	  and c02_compania                      = p28_compania
	  and c02_tipo_ret                      = p28_tipo_ret
	  and c02_porcentaje                    = p28_porcentaje
	group by 2, 3
	into temp t1;
select total_ret total_ret_f, porc from t1 where tipo_ret = 'F';
select total_ret total_ret_i, porc from t1 where tipo_ret = 'I';
drop table t1;
