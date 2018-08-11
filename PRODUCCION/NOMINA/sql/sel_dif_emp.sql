output to "difempl.sql" without headings
select 'select distinct ' from systables
	where tabname = 'rolt030'
union all
	select 'a.' || trim(colname) || ', b.' || trim(colname) || ','
		from syscolumns
		where tabid in (select tabid from systables
				where tabname = 'rolt030')
		  and colname not in ('n30_domicilio', 'n30_telef_domic')
union all
	select '  from rolt030 a, aceros:rolt030 b ' ||
        	' where b.n30_compania = 1 ' ||
	        '   and b.n30_estado   = "A" ' ||
                '   and a.n30_compania = b.n30_compania ' ||
                '   and a.n30_cod_trab = b.n30_cod_trab ' ||
                ' order by b.n30_nombres'
		from systables
		where tabname = 'rolt030'
