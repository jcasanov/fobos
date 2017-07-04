insert into srit023
	(s23_compania, s23_tipo_orden, s23_sustento_tri)
	select 1, c01_tipo_orden,
		case when c01_modulo = 'RE' then '06'
		     when c01_modulo = 'AF' then '03'
		     else '01'
		end
		from ordt001
		where c01_tipo_orden not in
				(select unique s23_tipo_orden
					from srit023
					where s23_tipo_orden = c01_tipo_orden)
		  and c01_estado      = 'A';
