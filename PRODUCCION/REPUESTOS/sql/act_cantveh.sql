set isolation to dirty read;
begin work;
        update rept010
                set r10_cantveh     = 1,
                    r10_usu_cosrepo = 'HSALZAR',
                    r10_fec_cosrepo = current
                where r10_compania = 1
                  and r10_estado   = 'A'
                  and r10_marca    = 'INTACO'
                  and r10_cantveh  = 0;
commit work;
