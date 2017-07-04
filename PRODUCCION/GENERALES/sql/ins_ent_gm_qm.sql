begin work;

insert into gent011
        select b.* from acero_qm@idsuio01:gent011 b
                where b.g11_tiporeg not in
                        (select a.g11_tiporeg from gent011 a
                                where a.g11_tiporeg = b.g11_tiporeg);

insert into gent012
        select b.g12_tiporeg, b.g12_subtipo, b.g12_nombre, "FOBOS",
                b.g12_fecing
                from acero_qm@idsuio01:gent012 b
                where (b.g12_tiporeg || b.g12_subtipo) not in
                        (select unique a.g12_tiporeg || a.g12_subtipo
                                from gent012 a);

--rollback work;
commit work;
