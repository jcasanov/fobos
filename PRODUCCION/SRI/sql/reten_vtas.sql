create temp table t2
	(
		codcli		integer,
		c_ruc		char(15),
		valor_r		decimal(14,2)
	);
create temp table tmp_fal
	(
		codcli_f	integer,
		c_ruc_f		char(15),
		valor_f		decimal(14,2)
	);
load from "reten_sri.txt" insert into t2;
load from "reten_sri_fal.txt" insert into tmp_fal;
select codcli, c_ruc, round(sum(valor_r), 2) valor_r
	from t2
	group by 1, 2
	into temp t4;
drop table t2;
select codcli_f, c_ruc_f, round(sum(valor_f), 2) valor_f
	from tmp_fal
	group by 1, 2
	into temp t6;
drop table tmp_fal;
select * from t4 into temp t2;
select round(sum(valor_r), 2) total_ret_sri from t2;
select count(*) tot_cli_sri from t2;
select round(sum(valor_f), 2) total_ret_sri_fal from t6;
select count(*) tot_cli_sri_fal from t6;
drop table t6;
select b12_tipo_comp tp, b12_num_comp num, b12_fec_proceso, b12_glosa,
	b13_codcli, z01_nomcli, z01_num_doc_id cedruc, b13_cuenta,
	round(b13_valor_base, 2) valor_ret
	from ctbt012, ctbt013, ctbt042, cxct001
	where b12_compania    = 1
	  and b12_estado      = 'M'
	  and b12_fec_proceso between mdy(12,01,2006) and mdy(12,28,2006)
	  and b13_compania    = b12_compania
	  and b13_tipo_comp   = b12_tipo_comp
	  and b13_num_comp    = b12_num_comp
	  and b13_cuenta      in ("11300201003","11300201002", b42_retencion)
	  and b42_compania    = b13_compania
	  and b42_localidad   = 1
	  and z01_codcli      = b13_codcli
	into temp t1;
select b13_cuenta, round(sum(valor_ret), 2) total_ret_cta from t1 group by 1;
select b13_codcli, z01_nomcli, round(sum(valor_ret), 2) total_ret_fil
	from t1
	group by 1, 2
	into temp caca;
select * from caca, t4
	where codcli   = b13_codcli
	  and valor_r <> total_ret_fil
	  and total_ret_fil > 0
	into temp t5;
select round(sum(total_ret_fil), 2) dif_b13, round(sum(valor_r), 2) dif_ane,
	round(sum(total_ret_fil) - sum(valor_r), 2) diferencia
	from t5;
select * from t5 order by 3 desc;
select round(sum(total_ret_fil), 2) total_ret_fil from caca;
drop table caca;
drop table t4;
drop table t5;
select round(sum(valor_ret), 2) total_ret from t1;
select b13_cuenta, count(*) tot_cli from t1 group by 1;
select b13_codcli, count(*) tot_cli_fil
	from t1
	group by 1
	into temp caca;
select round(sum(tot_cli_fil), 2) tot_cli_fil from caca;
drop table caca;
select count(*) tot_cli from t1;
unload to "reten_vtas.txt" select * from t1 order by valor_ret desc;
--select * from t1 order by valor_ret desc;
select * from t1, outer t2 where b13_codcli = codcli into temp t3;
drop table t1;
drop table t2;
delete from t3 where codcli is not null;
select count(*) tot_cli_t3 from t3;
unload to "reten_vtas_sri.txt" select * from t3 order by valor_ret desc;
drop table t3;
