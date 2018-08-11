insert into gent007
        (g07_user, g07_impresora, g07_default, g07_usuario, g07_fecing)
        select a.g07_user, 'LPJEFES', 'N', 'FOBOS', current
                from gent007 a, gent005
                where a.g07_impresora = 'LPVENTAXP'
                  and g05_usuario     = a.g07_user
                  and g05_estado      = 'A';
