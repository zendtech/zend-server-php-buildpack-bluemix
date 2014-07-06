# Zend Server Buildpack Environment variables

## Debug and development

1. **ZEND\_DEVELOPMENT** - if set to 1, then patches are downloaded from
   repos-source.zend.com to prevent hitting CDN cache. This is useful while
   developing patch.
2. **ZEND\_CF\_DEBUG** - after finishing start up print some debug information.
3. **ZEND\_LOG\_VERBOSITY** - if set, then log verbosity of ZS daemons is set to it's
   value. Additionally enables debug mode in ZS UI.
4. **ZEND\_CLEAR\_CACHE** - if set, in compile stage cache is cleared before
   downloading tarballs. This is useful mainly for debug purposes.

## Zend Server customization

1. **ZEND\_DOCUMENT\_ROOT** - can be used to customize document root relative to root
   of application uploaded.
2. **ZS\_ADMIN\_PASSWORD** - if set, then Zend Server admin password is initialy set
   to it's value.
3. **ZS\_DB** - if set, indicates name of database that should be used for Zend
   Server. At bootstrap service with such database name will be searched and
   it's parameters used.
4. **ZEND\_WEB\_SERVER** - allows choosing between nginx and apache. By default
   apache is used. If this variable is set to "nginx", then nginx is used instead.

## License related
1. **ZEND\_LICENSE\_ORDER** - override Zend Server license order
2. **ZEND\_LICENSE\_KEY** - override Zend Server license key
