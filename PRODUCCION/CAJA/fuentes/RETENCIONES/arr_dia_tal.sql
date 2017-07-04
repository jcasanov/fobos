select j14_compania cia, j14_localidad loc, j14_tipo_fuente tf,
	j14_num_fuente num_f, j14_secuencia sec, j14_codigo_pago cp,
	j14_num_ret_sri num_ret_s, j14_sec_ret sec_r,
	case when j14_tipo_fuente = 'SC'
		then 'R'
		else j14_cont_cred
	end cont_cred, j14_tipo_ret tr, j14_porc_ret porc,
	extend(j14_fecha_emi, year to day) fec, j14_valor_ret val_ret
	from cajt014
	where j14_compania        in (1, 2)
	  and j14_tipo_fue         = 'OT'
	  and year(j14_fecha_emi)  = 2009
	--  and j14_fecha_emi   >= mdy(01, 01, 2009)
	into temp t1;
select t1.*, j91_aux_cont aux_c
	from t1, cajt091
	where j91_compania    = cia
	  and j91_codigo_pago = cp
	  and j91_cont_cred   = cont_cred
	  and j91_tipo_ret    = tr
	  and j91_porcentaje  = porc
	into temp tmp_j14;
drop table t1;
select count(*) from tmp_j14;
select cia, loc, tf, num_f, sec, cp, num_ret_s, sec_r,
	case when j10_valor = 0
		then 'R'
		else cont_cred
	end cont_cred, tr, porc, aux_c, j10_tipo_destino td,
	j10_num_destino num_d, j10_codcli codcli, fec, val_ret
	from tmp_j14, cajt010
	where j10_compania    = cia
	  and j10_localidad   = loc
	  and j10_tipo_fuente = tf
	  and j10_num_fuente  = num_f
	into temp t1;
drop table tmp_j14;
select t1.*, z40_tipo_comp tp, z40_num_comp num_c
	from t1, cxct040
	where tf            = 'SC'
	  and z40_compania  = cia
	  and z40_localidad = loc
	  and z40_codcli    = codcli
	  and z40_tipo_doc  = td
	  and z40_num_doc   = num_d
	union
	select t1.*, t50_tipo_comp tp, t50_num_comp num_c
		from t1, talt050
		where tf            <> 'SC'
		  and t50_compania  = cia
		  and t50_localidad = loc
		  and t50_orden     = num_f
		  and t50_factura   = num_d
	into temp tmp_ret;
drop table t1;
select count(*) from tmp_ret;
select tmp_ret.*, b13_secuencia secuen, b13_cuenta cta
	from tmp_ret, ctbt013
	where b13_compania    = cia
	  and b13_tipo_comp   = tp
	  and b13_num_comp    = num_c
	  and b13_cuenta     <> aux_c
	  and b13_valor_base  = val_ret
	into temp tmp_cta;
drop table tmp_ret;
select count(*) tot_rt from tmp_cta;
select tf, num_f, cont_cred cr, count(*) tot
	from tmp_cta
	group by 1, 2, 3
	into temp caca;
update caca set tot = 1 where tot > 1;
select tf, cr, count(*) tot
	from caca
	group by 1, 2;
drop table caca;
select trim(tf) tf, lpad(num_f, 6, 0) num_f, porc, aux_c,
	lpad(num_d, 6, 0) num_d, cta cta_act, fec, cont_cred cr
	from tmp_cta
	order by fec, num_d;
begin work;
	update ctbt013
		set b13_cuenta = (select aux_c
					from tmp_cta
					where cia     = b13_compania
					  and tp      = b13_tipo_comp
					  and num_c   = b13_num_comp
					  and secuen  = b13_secuencia
					  and cta     = b13_cuenta
					  and val_ret = b13_valor_base)
		where exists (select 1 from tmp_cta
				where cia     = b13_compania
				  and tp      = b13_tipo_comp
				  and num_c   = b13_num_comp
				  and secuen  = b13_secuencia
				  and cta     = b13_cuenta
				  and val_ret = b13_valor_base);
	update cajt014
		set j14_cont_cred = (select cont_cred
					from tmp_cta
					where cia       = j14_compania
					  and loc       = j14_localidad
					  and tf        = j14_tipo_fuente
					  and num_f     = j14_num_fuente
					  and sec       = j14_secuencia
					  and cp        = j14_codigo_pago
					  and num_ret_s = j14_num_ret_sri
					  and sec_r     = j14_sec_ret)
		where exists (select * from tmp_cta
				where cia       = j14_compania
				  and loc       = j14_localidad
				  and tf        = j14_tipo_fuente
				  and num_f     = j14_num_fuente
				  and sec       = j14_secuencia
				  and cp        = j14_codigo_pago
				  and num_ret_s = j14_num_ret_sri
				  and sec_r     = j14_sec_ret
				  and cont_cred <> j14_cont_cred);
	update cajt014
		set j14_tipo_comp = (select tp
					from tmp_cta
					where cia       = j14_compania
					  and loc       = j14_localidad
					  and tf        = j14_tipo_fuente
					  and num_f     = j14_num_fuente
					  and sec       = j14_secuencia
					  and cp        = j14_codigo_pago
					  and num_ret_s = j14_num_ret_sri
					  and sec_r     = j14_sec_ret),
		    j14_num_comp  = (select num_c
					from tmp_cta
					where cia       = j14_compania
					  and loc       = j14_localidad
					  and tf        = j14_tipo_fuente
					  and num_f     = j14_num_fuente
					  and sec       = j14_secuencia
					  and cp        = j14_codigo_pago
					  and num_ret_s = j14_num_ret_sri
					  and sec_r     = j14_sec_ret)
		where exists (select * from tmp_cta
				where cia       = j14_compania
				  and loc       = j14_localidad
				  and tf        = j14_tipo_fuente
				  and num_f     = j14_num_fuente
				  and sec       = j14_secuencia
				  and cp        = j14_codigo_pago
				  and num_ret_s = j14_num_ret_sri
				  and sec_r     = j14_sec_ret)
		  and j14_tipo_comp is null;
commit work;
--rollback work;
drop table tmp_cta;
