select z20_compania, z20_localidad, z20_codcli, z20_tipo_doc, z20_num_doc,
	z20_dividendo, z20_saldo_cap, z20_saldo_int, z20_fecha_emi,
	z20_fecha_vcto,
	nvl((select z23_valor_cap + z23_valor_int + z23_saldo_cap +
			z23_saldo_int
		from cxct023, cxct022
		where z23_compania  = z20_compania
		  and z23_localidad = z20_localidad
		  and z23_codcli    = z20_codcli
		  and z23_tipo_doc  = z20_tipo_doc
		  and z23_num_doc   = z20_num_doc
		  and z23_div_doc   = z20_dividendo
		  and z22_compania  = z23_compania
		  and z22_localidad = z23_localidad
		  and z22_codcli    = z23_codcli
		  and z22_tipo_trn  = z23_tipo_trn
		  and z22_num_trn   = z23_num_trn
		  and z22_fecing    = (select max(z22_fecing)
					from cxct023, cxct022
					where z23_compania  = z20_compania
					  and z23_localidad = z20_localidad
					  and z23_codcli    = z20_codcli
					  and z23_tipo_doc  = z20_tipo_doc
					  and z23_num_doc   = z20_num_doc
					  and z23_div_doc   = z20_dividendo
					  and z22_compania  = z23_compania
					  and z22_localidad = z23_localidad
					  and z22_codcli    = z23_codcli
					  and z22_tipo_trn  = z23_tipo_trn
					  and z22_num_trn   = z23_num_trn)),
		case when z20_fecha_emi <=
				(select z60_fecha_carga
					from cxct060
					where z60_compania  = z20_compania
					  and z60_localidad = z20_localidad)
						-- fecha migración COBRANZAS
			then z20_saldo_cap + z20_saldo_int
			else z20_valor_cap + z20_valor_int
		end) saldo_doc
	from cxct020
	where z20_compania  in (1, 2)
	  and z20_moneda     = "DO"
	  and z20_fecha_emi <= today
	into temp temp_doc;
select z20_codcli cli_trn, nvl(sum(saldo_doc), 0) valor_trn
	from temp_doc
	group by 1
	into temp t1;
select z20_codcli cli_doc, nvl(sum(z20_saldo_cap + z20_saldo_int), 0) valor_doc
	from temp_doc
	group by 1
	into temp t2;
select count(cli_trn) tot_cli_trn from t1;
select count(cli_doc) tot_cli_doc from t2;
select cli_doc, valor_doc, valor_trn
	from t1, t2
	where cli_trn    = cli_doc
	  and valor_trn <> valor_doc
	into temp t3;
select cli_doc, cli_trn
	from t2, outer t1
	where cli_doc = cli_trn
	into temp t4;
delete from t4 where cli_trn is not null;
drop table t1;
drop table t2;
select count(*) total_cli from t3;
select * from t3 order by 1;
select z20_compania, z20_localidad, z20_codcli, z20_tipo_doc, z20_num_doc,
	z20_dividendo, z20_saldo_cap, z20_saldo_int, z20_fecha_emi,
	z20_fecha_vcto, z22_tipo_trn, z22_num_trn, saldo_doc, z22_fecing
	from temp_doc, cxct023, cxct022
	where z20_codcli    in (select cli_doc from t3)
	  and saldo_doc     <> z20_saldo_cap + z20_saldo_int
	  and z23_compania   = z20_compania
	  and z23_localidad  = z20_localidad
	  and z23_codcli     = z20_codcli
	  and z23_tipo_doc   = z20_tipo_doc
	  and z23_num_doc    = z20_num_doc
	  and z23_div_doc    = z20_dividendo
	  and z22_compania   = z23_compania
	  and z22_localidad  = z23_localidad
	  and z22_codcli     = z23_codcli
	  and z22_tipo_trn   = z23_tipo_trn
	  and z22_num_trn    = z23_num_trn
	  and z22_fecing     = (select max(z22_fecing)
				from cxct023, cxct022
				where z23_compania  = z20_compania
				  and z23_localidad = z20_localidad
				  and z23_codcli    = z20_codcli
				  and z23_tipo_doc  = z20_tipo_doc
				  and z23_num_doc   = z20_num_doc
				  and z23_div_doc   = z20_dividendo
				  and z22_compania  = z23_compania
				  and z22_localidad = z23_localidad
				  and z22_codcli    = z23_codcli
				  and z22_tipo_trn  = z23_tipo_trn
				  and z22_num_trn   = z23_num_trn)
	order by z20_fecha_emi, z22_fecing;
drop table temp_doc;
drop table t3;
select unique z20_codcli
	from cxct020
	where z20_compania                  in (1, 2)
	  and z20_codcli                    in (select cli_doc from t4)
	  and z20_saldo_cap + z20_saldo_int  > 0
	  and year(z20_fecing)               < 
				(select date(z60_fecha_carga)
					from cxct060
					where z60_compania  = z20_compania
					  and z60_localidad = z20_localidad)
	into temp t5;
drop table t4;
select count(*) cli_no_estan_z23 from t5;
select * from t5 order by 1;
drop table t5;
