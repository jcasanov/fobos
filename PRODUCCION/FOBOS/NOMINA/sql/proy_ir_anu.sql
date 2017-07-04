{--
create temp table temp_ir
	(
		anio		smallint,
		indice		smallint,
		base_ini	decimal(14,2),
		base_max	decimal(14,2),
		base_fra	decimal(12,2),
		porc		decimal(5,2)
	);

insert into temp_ir values (2007, 1, 0.00, 7850.00, 0.00, 0.00);
insert into temp_ir values (2007, 2, 7850.01, 15360.00, 0.00, 5.00);
insert into temp_ir values (2007, 3, 15360.01, 30720.00, 393.00, 10.00);
insert into temp_ir values (2007, 4, 30720.01, 46080.00, 1536.00, 15.00);
insert into temp_ir values (2007, 5, 46080.01, 61440.00, 4608.00, 20.00);
insert into temp_ir values (2007, 6, 61440.01, 800000.00, 9216.00, 25.00);
--}

create procedure fecha_tope(anio smallint, mes smallint) returning date;

	define fecha	date;

	let fecha = mdy(mes, day(mdy(mes, 01, anio) + 1 units month
			- 1 units day), anio);

	return fecha;

end procedure;

create procedure fec_act() returning date;

	define fecha	date;

	let fecha = fecha_tope(2008, 12);

	return fecha;

end procedure;

CREATE PROCEDURE dia_mes (fecha DATE) RETURNING INT;
	DEFINE dia		INT;

	IF MONTH(fecha) = 2 AND DAY(fecha) > 28 THEN
		IF MOD(YEAR(TODAY), 4) = 0 THEN
			--RETURN 29;
			return 28;
		ELSE
			RETURN 28;
		END IF;
	END IF;

	LET dia = DAY(fecha);

	RETURN dia;

END PROCEDURE;

select n32_cod_trab codo, round(sum(n33_valor), 2) val_ot
	from rolt032, rolt033
	where n32_compania   in (1, 2)
	  and n32_cod_liqrol in ("Q1", "Q2")
	  --and n32_fecha_ini  >= mdy(month(fec_act()), 01, year(fec_act()))
	  and n32_fecha_ini  >= mdy(01, 01, year(fec_act()))
	  and n32_fecha_fin  <= fec_act()
	  and n33_compania    = n32_compania
	  and n33_cod_liqrol  = n32_cod_liqrol
	  and n33_fecha_ini   = n32_fecha_ini
	  and n33_fecha_fin   = n32_fecha_fin
	  and n33_cod_trab    = n32_cod_trab
	  and n33_cod_rubro  <> 18
	  and n33_valor       > 0
	  and n33_det_tot     = "DI"
	  and n33_cant_valor  = "V"
	  and not exists (select 1 from rolt008, rolt006
			 where n08_rubro_base = n33_cod_rubro
			   and n06_cod_rubro  = n08_cod_rubro
			   and n06_flag_ident = "AP")
	group by 1
	into temp tmp_ot;

select n32_compania cia, lpad(n32_cod_trab, 3, 0) cod,
	trim(n30_nombres) empleado,
	nvl(round(sum(n32_tot_gan / month(fec_act()) * 12), 2), 0) tot_gan,
	--nvl(round((select val_ot * 12 from tmp_ot
	nvl(round((select val_ot from tmp_ot
		where codo = n32_cod_trab), 2), 0) otros,
	round(nvl((select n10_valor * 12
			from rolt010
			where n10_compania   = n32_compania
			  and n10_cod_liqrol = 'ME'
			  and n10_cod_trab   = n32_cod_trab
			  and n10_cod_trab   in(116, 117, 131)), 0), 2) bonif,
	n30_cod_seguro cod_seguro, n30_tipo_trab tipo,
	n00_dias_vacac +
	(CASE WHEN (MDY(MONTH(n30_fecha_ing), dia_mes(n30_fecha_ing),
		year(fec_act())))
		>= (n30_fecha_ing + (n00_ano_adi_vac - 1) UNITS YEAR
			- 1 UNITS DAY)
		THEN CASE WHEN (n00_dias_vacac +
			((YEAR(MDY(MONTH(n30_fecha_ing),dia_mes(n30_fecha_ing),
			year(fec_act()))) - YEAR(n30_fecha_ing
			 + (n00_ano_adi_vac
			- 1) UNITS YEAR - 1 UNITS DAY)) * n00_dias_adi_va)) >
			n00_max_vacac
			THEN n00_max_vacac - n00_dias_vacac
			ELSE ((YEAR(MDY(MONTH(n30_fecha_ing),
				dia_mes(n30_fecha_ing),
				year(fec_act()))) - YEAR(n30_fecha_ing +
				(n00_ano_adi_vac - 1) UNITS YEAR
				- 1 UNITS DAY)) * n00_dias_adi_va)
			END
		ELSE 0
		END) d_vac
	from rolt032, rolt030, rolt000
	where n32_compania   in (1, 2)
	  and n32_cod_liqrol in ("Q1", "Q2")
	  and n32_fecha_ini  >= mdy(01, 01, year(fec_act()))
	  and n32_fecha_fin  <= fec_act()
	  and n30_compania    = n32_compania
	  and n30_cod_trab    = n32_cod_trab
	  and n00_serial      = n30_compania
	group by 1, 2, 3, 5, 6, 7, 8, 9
	into temp t1;

drop table tmp_ot;
drop procedure dia_mes;

select cia, cod, empleado, tot_gan, nvl(round(tot_gan * n13_porc_trab / 100,2),
	0) val_ap, nvl(round(tot_gan - (tot_gan * n13_porc_trab / 100), 2),
	0) val_nom, otros, bonif, tipo, d_vac
	from t1, rolt013
	where n13_cod_seguro = cod_seguro
	into temp tmp_emp;

drop table t1;

select cod codv, nvl(n39_valor_vaca + n39_valor_adic, 0) val_vac,
	nvl(n39_descto_iess, 0) ap_vac, nvl((n39_valor_vaca + n39_valor_adic)
	- n39_descto_iess, 0) vac_net, n39_tipo tip_v
	from rolt039, tmp_emp
	where n39_compania     = cia
	  and n39_proceso     in ("VA", "VP")
	  and n39_ano_proceso  = year(fec_act())
	  and n39_mes_proceso <= month(fec_act())
	  and n39_cod_trab     = cod
	  and n39_estado       = "P"
	into temp tmp_vac;

select cod codd, n36_proceso c_dec, nvl(n36_valor_bruto, 0) val_dec
	from rolt036, tmp_emp
	where n36_compania     = cia
	  and n36_proceso     in ("DC", "DT")
	  and n36_ano_proceso  = year(fec_act())
	  and n36_mes_proceso <= month(fec_act())
	  and n36_cod_trab     = cod
	  and n36_estado       = "P"
	into temp tmp_dec;

select cod codu, n42_val_trabaj + n42_val_cargas val_ut
	 from rolt041, rolt042, tmp_emp
	 where n41_compania      = cia
	   and n41_ano           = year(mdy(month(fec_act()), 01,
						year(fec_act()))) - 1
	   and n41_estado        = "P"
	   and n42_compania      = n41_compania
	   and n42_ano           = n41_ano
	   and n42_cod_trab      = cod
	into temp tmp_ut;

select extend(fec_act(), year to month) periodo, cod, empleado, tot_gan, val_ap,
	val_nom, otros,
	round(case when nvl((select val_vac from tmp_vac
				where codv = cod), 0) = 0
			then case when tipo = "N" then (tot_gan / 360) * d_vac
				else 0.00 end
			else (select val_vac from tmp_vac
				where codv = cod)
		end, 2) val_vac,
	round(nvl(case when ((nvl((select ap_vac from tmp_vac
				where codv = cod), 0) = 0) and
			(nvl((select tip_v from tmp_vac
				where codv = cod), "G") = "G"))
			then case when tipo = "N"
				then ((tot_gan / 360) * d_vac) * 9.35 / 100
				else 0.00 end
			else (select ap_vac from tmp_vac where codv = cod)
		end, 0), 2) ap_vac,
	round(case when nvl((select vac_net from tmp_vac
				where codv = cod), 0) = 0
			then case when tipo = "N"
				then ((tot_gan / 360) * d_vac) -
					(((tot_gan / 360) * d_vac) *
					9.35 / 100)
				else 0.00 end
			else (select vac_net from tmp_vac where codv = cod)
		end, 2) vac_net,
	round(case when nvl((select val_dec from tmp_dec
				where codd = cod and c_dec = "DT"), 0) = 0
			then case when tipo = "N" then tot_gan / 12
				else 0.00 end
			else (select val_dec from tmp_dec
				where codd = cod and c_dec = "DT")
		end, 2) val_dt,
	nvl(case when month(fec_act()) >= 3
			then round((select val_dec from tmp_dec
					where codd  = cod
					  and c_dec = "DC"), 2)
			else case when tipo = "N" then
				nvl(round((select (n00_salario_min / 12) *
					(9 + month(fec_act()) - 1)
					from rolt000
					where n00_serial = cia), 2), 0)
				else 0.00
				end
		end, 0) val_dc,
	nvl(case when month(fec_act()) >= 4
			then round((select val_ut from tmp_ut
					where codu = cod), 2)
			else 0.00
		end, 0) val_ut,
	bonif
	from tmp_emp
	into temp t1;

drop table tmp_emp;
drop table tmp_vac;
drop table tmp_dec;
drop table tmp_ut;
drop procedure fec_act;
drop procedure fecha_tope;

unload to "proyeccion_ir_dic2008.unl"
	select cod, empleado, tot_gan, val_ap, val_nom, otros, val_vac,ap_vac,
		vac_net, val_dt, val_dc, val_ut, bonif
	from t1
	order by 2;

select count(*) tot_emp from t1;
select periodo, cod, empleado, tot_gan, val_ap, val_nom, otros, val_vac,ap_vac,
	vac_net, val_dt, val_dc, val_ut, bonif, nvl(round(val_nom + otros +
	vac_net + val_dt + val_dc + val_ut + bonif, 2), 0) total_calc
	from t1
	order by 3;
drop table t1;

{--
select anio, indice, (base_ini / 12) base_ini, (base_max / 12) base_max,
	(base_fra / 12) base_fra, porc
	from temp_ir
	into temp tmp_ir;
drop table temp_ir;
--drop table tmp_ir;
--}
