set isolation to dirty read;
select j10_compania cia, j10_localidad loc, j10_tipo_destino tp,
	j10_num_destino num,
	case when j10_valor = 0
		then 'R'
		else 'C'
	end cr,
	j10_fecing fecha, j11_codigo_pago cp, j11_cod_bco_tarj cod_t,
	(select unique g10_codcobr
		from acero_qs@idsuio02:gent010
		where g10_compania = j11_compania
		  and g10_tarjeta  = j11_cod_bco_tarj
		  and g10_cod_tarj = j11_codigo_pago
		  and g10_estado   = 'A') cli_tj
	from acero_qs@idsuio02:cajt010, acero_qs@idsuio02:cajt011
	where j10_compania    = (select g01_compania
				from acero_qs@idsuio02:gent001
				where g01_principal = 'S')
	  and j10_localidad   = (select g02_localidad
				from acero_qs@idsuio02:gent002
				where g02_compania = j10_compania
				  and g02_matriz   = 'S')
	  and j11_compania    = j10_compania
	  and j11_localidad   = j10_localidad
	  and j11_tipo_fuente = j10_tipo_fuente
	  and j11_num_fuente  = j10_num_fuente
	  and j11_codigo_pago in
		(select g10_cod_tarj
			from acero_qs@idsuio02:gent010
			where g10_compania = j11_compania
			  and g10_tarjeta  = j11_cod_bco_tarj
			  and g10_estado   = 'A')
	into temp t1;
select cia, loc, tp, num, cr, fecha, cp, cod_t, cli_tj, z02_aux_clte_mb cta
	from t1, acero_qm@idsuio01:cxct002, acero_qm@idsuio01:cxct001
	where z02_compania  = cia
	  and z02_localidad = loc
	  and z02_codcli    = cli_tj
	  and z01_codcli    = z02_codcli
	  and z01_estado    = 'A'
	into temp t2;
drop table t1;
select t2.*, r40_tipo_comp tp_d, r40_num_comp num_t
	from t2, acero_qm@idsuio01:rept040
	where r40_compania  = cia
	  and r40_localidad = loc
	  and r40_cod_tran  = tp
	  and r40_num_tran  = num
	into temp t3;
drop table t2;
select t3.*, b13_secuencia sec, b13_cuenta cta_d
	from t3, acero_qm@idsuio01:ctbt012, acero_qm@idsuio01:ctbt013
	where b12_compania   = cia
	  and b12_tipo_comp  = tp_d
	  and b12_num_comp   = num_t
	  and b12_subtipo    = 52
	  and b12_estado    <> 'E'
	  and b13_compania   = b12_compania
	  and b13_tipo_comp  = b12_tipo_comp
	  and b13_num_comp   = b12_num_comp
	  and b13_cuenta     = '11210101001'
	into temp t4;
drop table t3;
select count(*) tot_reg from t4;
select * from t4;
{--
begin work;
	update acero_qm@idsuio01:ctbt013
		set b13_cuenta = (select cta
					from t4
					where cia   = b13_compania
					  and tp_d  = b13_tipo_comp
					  and num_t = b13_num_comp
					  and sec   = b13_secuencia)
		where exists
			(select 1 from t4
				where cia   = b13_compania
				  and tp_d  = b13_tipo_comp
				  and num_t = b13_num_comp
				  and sec   = b13_secuencia
				  and cta_d = b13_cuenta);
rollback work;
--}
drop table t4;
