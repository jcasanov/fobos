select p21_localidad localidad, p21_codprov codprov, p21_tipo_doc tipo_doc,
	p21_num_doc num_doc, p21_fecha_emi fec_emi,
	nvl(case when p21_fecha_emi > mdy(12, 31, 2002) then
		p21_valor +
		(select sum(p23_valor_cap + p23_valor_int)
		from cxpt023, cxpt022
		where p23_compania   = p21_compania
		  and p23_localidad  = p21_localidad
		  and p23_codprov    = p21_codprov
		  and p23_tipo_favor = p21_tipo_doc
		  and p23_doc_favor  = p21_num_doc
		  and p22_compania   = p23_compania
		  and p22_localidad  = p23_localidad
		  and p22_codprov    = p23_codprov
		  and p22_tipo_trn   = p23_tipo_trn
		  and p22_num_trn    = p23_num_trn
		  and p22_fecing     between extend(p21_fecha_emi,
								year to second)
					 and current)
					 --and "2005-12-31 23:59:59")
		else
		nvl((select sum(p23_valor_cap + p23_valor_int)
			from cxpt023
			where p23_compania   = p21_compania
			  and p23_localidad  = p21_localidad
			  and p23_codprov    = p21_codprov
			  and p23_tipo_favor = p21_tipo_doc
			  and p23_doc_favor  = p21_num_doc), 0) +
		p21_saldo -
		(select sum(p23_valor_cap + p23_valor_int)
		from cxpt023, cxpt022
		where p23_compania   = p21_compania
		  and p23_localidad  = p21_localidad
		  and p23_codprov    = p21_codprov
		  and p23_tipo_favor = p21_tipo_doc
		  and p23_doc_favor  = p21_num_doc
		  and p22_compania   = p23_compania
		  and p22_localidad  = p23_localidad
		  and p22_codprov    = p23_codprov
		  and p22_tipo_trn   = p23_tipo_trn
		  and p22_num_trn    = p23_num_trn
		  and p22_fecing     between extend(p21_fecha_emi,
								year to second)
					 and current)
					 --and "2005-12-31 23:59:59")
		end,
		case when p21_fecha_emi <= mdy(12, 31, 2002)
						-- fecha migracion TESORERIA
			then p21_saldo -
				nvl((select sum(p23_valor_cap + p23_valor_int)
					from cxpt023
					where p23_compania   = p21_compania
					  and p23_localidad  = p21_localidad
					  and p23_codprov    = p21_codprov
					  and p23_tipo_favor = p21_tipo_doc
					  and p23_doc_favor  = p21_num_doc), 0)
			else p21_valor
		end) saldo_fav
	from cxpt021
	where p21_compania  in (1, 2)
	  and p21_moneda     = "DO"
	  and p21_fecha_emi <= today
	into temp temp_fav;
select codprov prov_fav, nvl(sum(saldo_fav) * (-1), 0) valor_fav
	from temp_fav
	group by 1
	into temp t1;
drop table temp_fav;
select p20_codprov codprov, p01_nomprov proveedor, p20_saldo_cap saldo_fav
	from cxpt020, cxpt001
	where p20_compania = 99
	  and p01_codprov  = p20_codprov
	into temp t2;
insert into t2
	select prov_fav, trim(p01_nomprov), valor_fav
	from t1, cxpt001
	where p01_codprov = prov_fav;
drop table t1;
select codprov, proveedor, nvl(sum(saldo_fav), 0) saldo_fav
	from t2
	group by 1, 2
	into temp t3;
drop table t2;
delete from t3 where saldo_fav = 0;
select count(*) total_prov from t3;
select nvl(round(sum(saldo_fav), 2), 0) total_fav from t3;
select codprov, proveedor[1, 40] proveedor, saldo_fav from t3 order by 2;
drop table t3;
