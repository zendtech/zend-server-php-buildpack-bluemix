<?php
shell_exec("touch /app/restarted");
$pid = file_get_contents( "/app/nginx/logs/nginx.pid" );
shell_exec("kill -1 $pid");
?>
