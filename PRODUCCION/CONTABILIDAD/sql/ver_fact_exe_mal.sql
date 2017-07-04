set isolation to dirty read;

select z01_codcli codcli
	from cxct001
	where z01_paga_impto = 'N'
	into temp tmp_cli;

select r19_cod_tran tp, r19_num_tran num, r19_tot_neto tot_n,
	r40_tipo_comp tc, r40_num_comp num_c,
	extend(r19_fecing, year to month) fecha
        from rept019, rept040
        where r19_compania     = 1
          and r19_localidad    = 1
          and r19_cod_tran     in ('FA', 'NV', 'DF', 'AF')
	  and r19_codcli       in (select codcli from tmp_cli)
	  and r19_porc_impto   = 0
          and date(r19_fecing) between mdy(01, 01, 2008)
                                   and today
          and r40_compania     = r19_compania
          and r40_localidad    = r19_localidad
          and r40_cod_tran     = r19_cod_tran
          and r40_num_tran     = r19_num_tran
union
	select "FA" tp, t23_num_factura num, t23_tot_neto tot_n,
		t50_tipo_comp tc, t50_num_comp num_c,
		extend(t23_fec_factura, year to month) fecha
		from talt023, talt050
	        where t23_compania     = 1
	          and t23_localidad    = 1
	          and t23_estado       = 'F'
		  and t23_cod_cliente  in (select codcli from tmp_cli)
		  and t23_val_impto    = 0
	          and date(t23_fec_factura) between mdy(01, 01, 2008)
						and today
	          and t50_compania     = t23_compania
	          and t50_localidad    = t23_localidad
	          and t50_orden        = t23_orden
	          and t50_factura      = t23_num_factura
union
	select "FA" tp, t23_num_factura num, t23_tot_neto tot_n,
		t50_tipo_comp tc, t50_num_comp num_c,
		extend(t23_fec_factura, year to month) fecha
		from talt023, talt050, ctbt012
	        where t23_compania     = 1
	          and t23_localidad    = 1
	          and t23_estado       = 'D'
		  and t23_cod_cliente  in (select codcli from tmp_cli)
		  and t23_val_impto    = 0
	          and date(t23_fec_factura) between mdy(01, 01, 2008)
						and today
	          and t50_compania     = t23_compania
	          and t50_localidad    = t23_localidad
	          and t50_orden        = t23_orden
	          and t50_factura      = t23_num_factura
	          and b12_compania     = t50_compania
	          and b12_tipo_comp    = t50_tipo_comp
	          and b12_num_comp     = t50_num_comp
		  and b12_subtipo      = 41
union
	select "DF" tp, t23_num_factura num, t23_tot_neto tot_n,
		t50_tipo_comp tc, t50_num_comp num_c,
		extend(t28_fec_anula, year to month) fecha
		from talt023, talt028, talt050, ctbt012
	        where t23_compania     = 1
	          and t23_localidad    = 1
	          and t23_estado       = 'D'
		  and t23_cod_cliente  in (select codcli from tmp_cli)
		  and t23_val_impto    = 0
	          and date(t23_fec_factura) between mdy(01, 01, 2008)
						and today
	          and t28_compania     = t23_compania
	          and t28_localidad    = t23_localidad
	          and t28_factura      = t23_num_factura
	          and t50_compania     = t28_compania
	          and t50_localidad    = t28_localidad
	          and t50_orden        = t28_ot_ant
	          and t50_factura      = t28_factura
	          and b12_compania     = t50_compania
	          and b12_tipo_comp    = t50_tipo_comp
	          and b12_num_comp     = t50_num_comp
		  and b12_subtipo      = 10
        into temp t1;

select count(*) tot_t1 from t1;

select unique t1.*, b13_cuenta cuenta, b12_estado est
	from t1, ctbt012, ctbt013
	where b12_compania   = 1
	  and b12_tipo_comp  = tc
	  and b12_num_comp   = num_c
	  and b12_estado    <> 'E'
          and b13_compania   = b12_compania
          and b13_tipo_comp  = b12_tipo_comp
          and b13_num_comp   = b12_num_comp
	  and b13_cuenta    in ('41010101001', '41010101003', '21040201001',
				'41010102003', '41010102005', '41010102004',
				'41010102006', '41010102007')
	into temp t2;

drop table t1;

drop table tmp_cli;

select count(*) tot_t2 from t2;

select * from t2 order by fecha;

drop table t2;
