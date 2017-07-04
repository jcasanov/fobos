define err_flag		integer

main
call fgl_init4js()
CALL WinExec("Project1.exe 30000") RETURNING err_flag
end main
