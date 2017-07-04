select rolt008.*,
        (select n06_flag_ident
                from rolt006
                where n06_cod_rubro = n08_rubro_base) ident
        from rolt008
        where n08_cod_rubro = (select n06_cod_rubro
                                from rolt006
                                where n06_flag_ident = "AP")
