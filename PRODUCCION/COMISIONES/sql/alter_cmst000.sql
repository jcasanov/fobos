alter table cmst000 add c00_fecini_dev date;
alter table cmst000 add c00_fecfin_dev date;
update cmst000 set c00_feini_dev = mdy(1, 31, 2009),
				   c00_fecfin_dev = mdy(1, 1, 2001);
alter table cmst000 modify c00_fecini_dev date not null;
alter table cmst000 modify c00_fecfin_dev date not null;
				   
