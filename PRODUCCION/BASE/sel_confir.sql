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
	from sysindexes i, systables t, sysfragments f
	where t.tabid          > 99
	  and t.tabtype        = 'T'
	  and t.tabid          = i.tabid
	  and i.idxname[1, 1] <> ' '
	  and f.fragtype       = 'I'
	  and f.tabid          = i.tabid
	  and f.indexname      = i.idxname
	  and f.dbspace        = 'idxdbs';
	  --and f.dbspace       <> 'idxdbs';
