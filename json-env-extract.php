#!/usr/bin/env /app/bin/php
<?php

$var = $argv[1];

$arr = json_decode(getenv($var),true);
$path = array_slice($argv,2);
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
