begin work;

select "ALTER TABLE " || tabname || " LOCK MODE(ROW); " expresion
	from systables
	where tabid   > 99
	  and tabtype = 'T'
	into temp t1;

unload to "lmrfobos.sql" select * from t1;

drop table t1;

commit work;
