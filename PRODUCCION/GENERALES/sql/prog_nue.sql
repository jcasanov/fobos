begin work;
	insert into gent054
		select * from acero_gm@idsgye01:gent054
			where date(g54_fecing) = today;
	insert into gent057
		select * from acero_gm@idsgye01:gent057
			where date(g57_fecing) = today
			  and g57_user         = 'FOBOS'
			  and exists
			(select 1 from acero_gm@idsgye01:gent054
				where g54_modulo  = g57_modulo
				  and g54_proceso = g57_proceso);
commit work;
