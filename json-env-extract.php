#!/usr/bin/env /app/bin/php
<?php

$var = $argv[1];
$path_str = $argv[2];

$arr = json_decode(getenv($var),true);
$path = explode('.',$path_str);
$result = $arr;

foreach($path as $key) {
    if(isset($result[$key])) {
        $result = $result[$key];
    } else {
        fwrite(STDERR,"Failed locating subkey $key\n");
        exit(1);
    }
}

echo $result;
