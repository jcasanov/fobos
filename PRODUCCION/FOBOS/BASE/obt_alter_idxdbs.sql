select count(idxname) tot_idx
	from sysindexes
	where idxname matches " [1234567890]*";

output to "rename_index.sql" without headings
	select 'rename index ' || idxname || ' to ix_' || trim(idxname) || ';'
		from sysindexes
		where idxname matches " [1234567890]*";

output to "alter_idxdbs.sql" without headings
	select 'alter fragment on index ' || i.idxname || ' init in idxdbs;'
		from sysindexes i, systables t
		where t.tabid   > 99
		  and t.tabtype = 'T'
		  and t.tabid   = i.tabid;
