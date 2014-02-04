# Overview

The Zend Server version used by the buildpack can optionally be upgraded to "Enterprise Edition". Support for this edition is still experimental and requires an attached mysql database service.

# Usage
1. Create a folder on your workstation, and "cd" into it.
2. Create an empty file called "zend_server_php_app". If you do not do this, you will have to manually specify which buildpack to use for the app. 
3. Make sure your app contains an "index.php" file.
4. Issue the `cf push --buildpack=https://github.com/zendtech/zend-server-php-buildpack.git` command. Allocate at least 512M of RAM for your app. 
5. When prompted, save your manifest.
6. Bind a MySQL service (mysql/MariaDB/user-provided) to the app - this will cause Zend Server to operate in cluster mode (experimental). Operating in cluster mode enables: scaling, persistence of settings changed using the Zend Server UI and persistence of apps deployed using Zend Server's deployment mechanism. 
If you bind more than one database service to an app, specify which service Zend Server should use by setting the 'ZS_ DB' env variable to the correct service: `cf set-env <app_name> ZS_DB <db-service-name>`. Otherwise, Zend Server will use the first database available.
7. When prompted, save the manifest.
8. Issue the comand below to change the Zend Server UI password (this can be performed in the future in case you forget your password):
`cf set-env <app_name> ZS_ADMIN_PASSWORD <password>`
9. The previous steps should generate a YAML file named "manifest.yml" (see example below). Optional - add and push the generated manifest in future applications to facilitate smoother future pushes. 

 ```
 ---
 env:
    ZS_ACCEPT_EULA: 'TRUE'
    ZS_ADMIN_PASSWORD: '<password_for_Zend_Server_GUI_console>'
 applications:
 - name: <app_name>
    instances: 1
    memory: <at least 512M >
    host: <app_name>
    domain: <your_cloud_domain>
    path: .
 ```

10. Wait for the app to start.
11. Once the app starts, you can access the Zend Server UI at http://url-to-your-app/ZendServer (e.g. http://dave2.vcap.me/ZendServer) using username 'admin' and the password you defined in step 7. If you forgot to perform step 7, then the password is 'changeme'. 
12. If you chose to save the manifest in the previous steps, then you can issue the `cf push` command to udpate your application code in the future.

# Using an External Database Service
It is possible to bind an external database to the Zend Server app as a "user-provided" service. Doing so will enable persistence, session clustering, and more. 
To bind an external database:

1. Run `cf create-service`.
2. As a service type select "user-provided".
3. Enter a friendly name for the service.
4. Enter service paramaters. The required parameters are `hostname, port, password, name`, where 'name' is the database Zend Server will use for its internal functions.
5. Enter the paramaters of your external database provider in order.
6. Bind the service to your app `cf bind-service [service-name] [app-name]`.
7. The service will be auto-detected upon push. Zend Server will create the schema and enable clustering features.

# Known issues
* cleardb is not yet supported by this buildpack - you will get a "1203 == ER_TOO_MANY_USER_CONNECTIONS" error.
