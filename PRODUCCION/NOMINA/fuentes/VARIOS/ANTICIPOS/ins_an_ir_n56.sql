begin work;

insert into rolt056
	(n56_compania, n56_proceso, n56_cod_depto,n56_cod_trab,n56_aux_val_vac,
	 n56_aux_banco, n56_usuario, n56_fecing)
	select n30_compania, case when b10_cuenta[1, 1] = '1'
					then 'AN'
					else 'IR'
				end,
		n30_cod_depto, n30_cod_trab, b10_cuenta,
		case when b10_cuenta[1, 1] = '1'
			then '11020101003'
			else '11020101002'
		end,
		'FOBOS', current
		from rolt030, ctbt010
		where n30_compania = 1
		  and n30_estado   = 'A'
		  and b10_compania = n30_compania
		  and (b10_cuenta  matches '11210103*'
		   or  b10_cuenta  matches '21040102*')
		  and b10_estado   = 'A'
		  and b10_nivel    = 6
		  and substr(b10_descripcion,11,length(trim(b10_descripcion)))
			= substr(n30_nombres,1,length(substr(b10_descripcion,
					11,length(trim(b10_descripcion)))));

commit work;
