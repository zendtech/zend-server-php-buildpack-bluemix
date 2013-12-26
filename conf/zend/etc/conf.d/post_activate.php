<?php
$pid = file_get_contents( "/app/nginx/logs/nginx.pid" );
posix_kill( $pid, 1);
?>
