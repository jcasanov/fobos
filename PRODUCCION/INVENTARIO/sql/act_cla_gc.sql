set isolation to dirty read;

select r72_compania cia, r72_linea lin, r72_sub_linea slin, r72_cod_grupo gru,
	r72_cod_clase cla, r72_desc_clase descrip
	from acero_gm@idsgye01:rept072
	where r72_compania = 1
	into temp tmp_cla;

begin work;

	update rept072
		set r72_desc_clase = (select descrip
					from tmp_cla
					where cia  = r72_compania
					  and lin  = r72_linea
					  and slin = r72_sub_linea
					  and gru  = r72_cod_grupo
					  and cla  = r72_cod_clase)
		where r72_compania = 1
		  and not exists
			(select 1 from tmp_cla
				where cia     = r72_compania
				  and lin     = r72_linea
				  and slin    = r72_sub_linea
				  and gru     = r72_cod_grupo
				  and cla     = r72_cod_clase
				  and descrip = r72_desc_clase);

commit work;
--rollback work;

drop table tmp_cla;
