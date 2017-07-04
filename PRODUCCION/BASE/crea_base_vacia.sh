dbaccess $1 borra.sql
dbaccess acero_gm crea_base_vac.sql
dbaccess $1 base_vacia.sql

sleep 4

ontape -s -U $1
