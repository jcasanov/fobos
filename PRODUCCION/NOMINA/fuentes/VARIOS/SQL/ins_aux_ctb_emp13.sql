select b10_cuenta cuenta, trim(replace(b10_descripcion,
	(select trim(n30_nombres)
		from rolt030
		where n30_compania = b10_compania
		  and n30_cod_trab = 165), " ")) nomcta
	from ctbt010
	where b10_compania    = 1
	  and b10_estado      = 'A'
	  and b10_descripcion matches '*RAMIREZ M*'
	into temp t1;
select cuenta, trim(replace(nomcta, "RAMIREZ MORAN RODDY OMAR","")) nomcta
	from t1
	into temp t2;
drop table t1;
select cuenta, trim(replace(nomcta, "RAMIREZ MORAN RODDY O", "")) nomcta
	from t2
	into temp t1;
drop table t2;
select cuenta, trim(replace(nomcta, "RAMIREZ MORAN RO", "")) nomcta
	from t1
	into temp tmp_cta;
drop table t1;
--select * from tmp_cta order by 1;
select unique n56_compania cia, n56_proceso pro, n56_cod_depto dep,
	n56_aux_val_vac aux1, n56_aux_val_adi aux2, n56_aux_otr_ing aux3,
	n56_aux_iess aux4, n56_aux_otr_egr aux5, n56_aux_banco aux6
	from rolt056
	where n56_compania = 1
	  --and n56_estado   = 'A'
	  and n56_cod_trab = 165
	into temp t2;
--select * from t2;
select a.b10_compania cia, cuenta[1, 8] || '083' cta,
	trim(nomcta) || ' ' || trim(n30_nombres) nombre, '' nom,
	a.b10_estado, a.b10_tipo_cta, a.b10_tipo_mov,
	a.b10_nivel, '' ttt, a.b10_saldo_ma, 'PATRMOLI' usua, current fecing
	from tmp_cta, ctbt010 a, rolt030
	where b10_compania = 1
	  and b10_cuenta   = cuenta
	  and n30_compania = b10_compania
	  and n30_cod_trab = 178
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
				else aux1[1, 8] || '083'
			end,
			case when pro <> 'VP' and
				  pro <> 'UV'
				then aux2[1, 8] || '083'
				else aux2
			end,
			aux3, aux4, aux5, aux6, 'PATRMOLI', current
			from t2, rolt030
			where n30_compania = cia
			  and n30_cod_trab = 178;
	insert into rolt052
		(n52_compania, n52_cod_rubro, n52_cod_trab, n52_aux_cont)
		select n52_compania, n52_cod_rubro, 178,
			n52_aux_cont[1, 8] || '083'
			from rolt052
			where n52_compania = 1
			  and n52_cod_trab = 165;
--rollback work;
commit work;
drop table t2;
