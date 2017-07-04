create temp table tmp_per
	(
		periodo		date
	);

create procedure carga_per();

	define anio	smallint;
	define mes	smallint;
	define lim_mes	smallint;
	define per_mes	date;

	for anio = 2003 to year(today)

		let lim_mes = 12;
		if (anio = year(today)) and (lim_mes > month(today)) then
			let lim_mes = month(today);
		end if;

		for mes = 1 to lim_mes
			let per_mes = mdy(mes, 01, anio) + 1 units month -
					1 units day;

			if per_mes > today then
				let per_mes = today;
			end if;

			insert into tmp_per values (per_mes);
		end for;

	end for;

end procedure;

execute procedure carga_per();
drop procedure carga_per;

--insert into tmp_per values (today);

select periodo, z20_localidad, z20_codcli, z20_tipo_doc, z20_num_doc,
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
					where z23_compania   = z20_compania
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
		  			  and date(z22_fecing) <= periodo)),
		case when z20_fecha_emi <=
				(select z60_fecha_carga
					from cxct060
					where z60_compania  = z20_compania
					  and z60_localidad = z20_localidad)
			then z20_saldo_cap + z20_saldo_int -
				nvl((select sum(z23_valor_cap + z23_valor_int)
					from cxct023
					where z23_compania  = z20_compania
					  and z23_localidad = z20_localidad
					  and z23_codcli    = z20_codcli
					  and z23_tipo_doc  = z20_tipo_doc
					  and z23_num_doc   = z20_num_doc
					  and z23_div_doc   = z20_dividendo), 0)
			else z20_valor_cap + z20_valor_int
		end) saldo_doc
	from tmp_per, cxct020
	where z20_compania  in (1, 2)
	  and z20_moneda     = "DO"
	  and z20_fecha_emi <= periodo
	into temp temp_doc;

drop table tmp_per;

select periodo, z20_codcli cli_trn, nvl(round(sum(saldo_doc), 2), 0) valor_trn
	from temp_doc
	group by 1, 2
	into temp tmp_sal_per;

drop table temp_doc;

select count(*) tot_cli_trn from tmp_sal_per;

select periodo, nvl(round(sum(valor_trn), 2), 0) valor_per
	from tmp_sal_per
	group by 1
	order by 1;

--select * from tmp_sal_per order by 1, 2;

drop table tmp_sal_per;
