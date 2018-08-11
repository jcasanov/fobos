begin work;

select  idxname
  from sysindexes i, systables t
 where t.tabid   > 99
   and t.owner  = 'fobos'
   and t.tabtype = 'T'
   and t.tabid   = i.tabid
   and i.idxname[1,1] = ' '
  into temp tmp_idx;

update sysconstraints set idxname = 'fobos_' || idxname[2,18]
 where idxname in (select idxname from tmp_idx);

update sysobjstate set name = 'fobos_' || name[2,18]
 where name in (select idxname from tmp_idx)
   and objtype = 'I';

update sysindexes set idxname = 'fobos_' || idxname[2,18]
 where idxname in (select idxname from tmp_idx);

commit work;

output to "alter_idxdbs.sql" without headings
select "alter fragment on index fobos_" || idxname[2,18] || " init in idxdbs;"
  from tmp_idx;
