set isolation to dirty read;
select b12_compania cia, b12_tipo_comp tc, b12_num_comp num, b12_glosa glosa,
        b12_fec_proceso fec_pro, b12_fecing fecha, b12_estado est,
	b12_compania || b12_tipo_comp || b12_num_comp
        from ctbt012
        where b12_compania     = 1
          and b12_tipo_comp    = 'DC'
          and b12_subtipo      = 3
          and b12_origen       = 'A'
          and b12_estado      <> 'E'
          and year(b12_fecing) = 2013
        into temp t1;
select * from cxct040 into temp t2;
select count(*) tot_t1 from  t1;
select count(*) tot_t2 from  t2;
select t1.*, z40_tipo_comp tc2, z40_localidad loc, z40_codcli cli,
	z40_tipo_doc tip_d, z40_num_doc num_doc
	from t1, outer t2
	where z40_compania  = cia
          and z40_tipo_comp = tc
          and z40_num_comp  = num
	into temp t3;
drop table t1;
drop table t2;
select unique cia, tc, num, loc, cli, tip_d, num_doc, j14_cod_tran cod_t,
	j14_num_tran num_t, to_char(j14_fec_emi_fact, "%d-%m-%Y") fec_fac,
	to_char(j14_fecha_emi, "%d-%m-%Y") fec_ret,
	to_char(fec_pro, "%d-%m-%Y") fec_pro, to_char(fecha, "%d-%m-%Y") fecha
	from t3, cajt010, cajt014
	where j10_compania     = cia
	  and j10_localidad    = loc
	  and j10_tipo_fuente  = 'SC'
	  and j10_tipo_destino = tip_d
	  and j10_num_destino  = num_doc
	  and j10_codcli       = cli
	  and j14_compania     = j10_compania
	  and j14_localidad    = j10_localidad
	  and j14_tipo_fuente  = j10_tipo_fuente
	  and j14_num_fuente   = j10_num_fuente
	  and j14_fecha_emi    < fec_pro
	into temp t4;
drop table t3;
select * from t4
	order by 5 desc;
drop table t4;
