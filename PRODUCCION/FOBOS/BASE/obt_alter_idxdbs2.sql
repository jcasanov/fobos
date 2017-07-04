select count(i.idxname) tot_idx_all
	from sysindexes i, systables t
	where t.tabid   > 99
	  and t.tabtype = 'T'
	  and t.tabid   = i.tabid;

select count(i.idxname) tot_idx_blan
	from sysindexes i, systables t
	where t.tabid         > 99
	  and t.tabtype       = 'T'
	  and t.tabid         = i.tabid
	  and i.idxname[1, 1] = ' ';

select count(i.idxname) tot_idx_alt
	from sysindexes i, systables t
	where t.tabid          > 99
	  and t.tabtype        = 'T'
	  and t.tabid          = i.tabid
	  and i.idxname[1, 1] <> ' ';

output to "alter_idxdbs.sql" without headings
	select 'alter fragment on index ' || i.idxname || ' init in idxdbs;'
		from sysindexes i, systables t
		where t.tabid          > 99
		  and t.tabtype        = 'T'
		  and t.tabid          = i.tabid
		  and i.idxname[1, 1] <> ' ';
