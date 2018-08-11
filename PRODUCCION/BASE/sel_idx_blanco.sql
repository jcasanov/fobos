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

select i.idxname, t.tabname
	from sysindexes i, systables t
	where t.tabid         > 99
	  and t.tabtype       = 'T'
	  and t.tabid         = i.tabid
	  and i.idxname[1, 1] = ' '
	order by 2;
