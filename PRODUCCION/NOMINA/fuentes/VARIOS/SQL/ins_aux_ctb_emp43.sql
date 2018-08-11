select b10_cuenta cuenta, trim(replace(b10_descripcion,
	(select trim(n30_nombres)
		from rolt030
		where n30_compania = b10_compania
		  and n30_cod_trab = 204), " ")) nomcta
	from ctbt010
	where b10_compania    = 1
	  and b10_descripcion matches '*BAYONA*'
	into temp t1;
select cuenta, trim(replace(nomcta, "BAYONA MENOSCAL RUTH ELIZABETH","")) nomcta
	from t1
	into temp t2;
drop table t1;
select cuenta, trim(replace(nomcta, "BAYONA MENOSCAL RUTH ELIZA", "")) nomcta
	from t2
	into temp t1;
drop table t2;
select cuenta, trim(replace(nomcta, "BAYONA MENOSCAL RUTH ELIZ", "")) nomcta
	from t1
	into temp t2;
drop table t1;
select cuenta, trim(replace(nomcta, "BAYONA MENOSCAL RUTH", "")) nomcta
	from t2
	into temp t1;
drop table t2;
select cuenta, trim(replace(nomcta, "BAYONA MENOSCAL", "")) nomcta
	from t1
	into temp tmp_cta;
drop table t1;
select unique n56_compania cia, n56_proceso pro, n56_cod_depto dep,
	n56_aux_val_vac aux1, n56_aux_val_adi aux2, n56_aux_otr_ing aux3,
	n56_aux_iess aux4, n56_aux_otr_egr aux5, n56_aux_banco aux6
	from rolt056
	where n56_compania = 1
	  and n56_cod_trab = 204
	  --and n56_estado   = "A"
	into temp t2;
select a.b10_compania cia, cuenta[1, 8] || '115' cta,
	trim(nomcta) || ' ' || trim(n30_nombres) nombre, '' nom,
	a.b10_estado, a.b10_tipo_cta, a.b10_tipo_mov,
	a.b10_nivel, '' ttt, a.b10_saldo_ma, 'E1GINVIT' usua, current fecing
	from tmp_cta, ctbt010 a, rolt030
	where b10_compania = 1
	  and b10_cuenta   = cuenta
	  and n30_compania = b10_compania
	  and n30_cod_trab = 212
	into temp t3;
begin work;
	insert into ctbt010
		(b10_compania, b10_cuenta, b10_descripcion, b10_descri_alt,
		 b10_estado, b10_tipo_cta, b10_tipo_mov, b10_nivel,
		 b10_cod_ccosto, b10_saldo_ma, b10_usuario, b10_fecing)
		select * from t3;
	drop table t3;
	insert into rolt056
		(n56_compania, n56_proceso, n56_cod_depto, n56_cod_trab,
		 n56_estado, n56_aux_val_vac, n56_aux_val_adi, n56_aux_otr_ing,
		 n56_aux_iess, n56_aux_otr_egr, n56_aux_banco, n56_usuario,
		 n56_fecing)
		select cia, pro, n30_cod_depto, n30_cod_trab, 'A',
			case when pro[1, 1] = 'D' or
				  pro[1, 1] = 'F' or
				  pro       = 'UT' or
				  pro       = 'VP'
				then aux1
				else aux1[1, 8] || '115'
			end,
			case when pro <> 'VP' and
				  pro <> 'UV'
				then aux2[1, 8] || '115'
				else aux2
			end,
			aux3, aux4, aux5, aux6, 'E1GINVIT', current
			from t2, rolt030
			where n30_compania = cia
			  and n30_cod_trab = 212;
	insert into rolt052
		(n52_compania, n52_cod_rubro, n52_cod_trab, n52_aux_cont)
		select n52_compania, n52_cod_rubro, 212,
			n52_aux_cont[1, 8] || '115'
			from rolt052
			where n52_compania = 1
			  and n52_cod_trab = 204;
--rollback work;
commit work;
drop table t2;
