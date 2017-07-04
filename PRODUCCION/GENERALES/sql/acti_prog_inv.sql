begin work;

	update gent054
		set g54_estado = 'A'
		where (g54_proceso like 'repp2%'
		   or  g54_proceso in ('repp666, repp667'))
		  and  g54_proceso <> 'repp220';

	update gent054
		set g54_estado = 'A'
		where g54_proceso like 'talp2%';

commit work;
