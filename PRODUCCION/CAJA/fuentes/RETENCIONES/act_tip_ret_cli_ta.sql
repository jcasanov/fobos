select unique t23_compania cia, t23_cod_cliente codcli
	from talt023
	where t23_cod_cliente is not null
	into temp t1;

begin work;

	update cxct008
		set z08_defecto = 'S'
		where exists (select 1 from t1
				where z08_compania = cia
				  and z08_codcli   = codcli)
		  and z08_tipo_ret   = 'F'
		  and z08_porcentaje = 2.00;

commit work;

drop table t1;
