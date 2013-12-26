location ${alias} {
	root /app/www;
	try_files $uri $uri/ ${alias}/index.php?$args;
	include fastcgi.conf;	
}
