# Overview

Welcome to the Zend Server PHP buildpack! This buildpack allows you to deploy your PHP apps on Cloud Foundry using Zend Server 6.2. 
Zend Server's integration with Cloud Foundry allows you to quickly get your PHP applications up and running on a highly available PHP production environment which includes, amongst other features, a highly reliable PHP stack, application monitoring, troubleshooting, and more.

# Buildpack Components

* Zend Server 6.2 Free edition
* Zend Server 6.2 configuration files
* PHP 5.4
* Nginx web server
 

# Usage
1. Download and install Cloud Foundry's 'cf' CLI.
2. Create a new folder on your workstation, and access it
3. In the new folder, create an empty file called `zend_server_php_app`. 
4. If you have additional application files and resources you would like to deploy, copy them to the new folder.
5. Create a new 'index.php' file, and paste the following code (if you already have an 'index.php' file, skip to the next step):
```
<?php
echo "Hello world!;
?>
```
6. Enter the following command:
`cf push --buildpack=https://github.com/zendtech/zend-server-php-buildpack.git` 
7. Name your application.
8. Select the number of instances you would like to use for your application.
9. Allocate memory for you application (at least 512M).
10. Enter a sub-domain for your application.
11. Enter a domain for your application.
12. To save the configuration, enter 'y'. Your configurations area saved in a 'manifest.yml' file, and your application is deployed using the Zend Server buildpack. This may take a few minutes.
13. Once successfully initialized and deployed, a success message with the URL at which your application is available at is displayed.
14. To access the application, enter the supplied URL in your Web browser.
15. To access Zend Server, enter add 'ZendServer' to the supplied URL. For example:`http://<application URL>/ZendServer` The Zend Server Login page is displayed.
16. To access the Zend Server UI, enter the following credentials: Username - admin, Password - changeme.
17. To change the Zend Server UI password, or in case you misplace your password, enter the following command:
`cf set-env <application name> ZS_ADMIN_PASSWORD <new password>`

# Known Issues
* Zend Server Code Tracing may not work properly in this version.
* Several issues might be encountered if you do not bind MySQL providing service to the app (mysql/MaraiaDB):
 * You can change settings using the Zend Server UI and apply them - but they will not survive application pushes and restarts, nor will they be propagated to new application instances.
 * Application packages deployed using Zend Server's deployment mechanism (.zpk packages) will not be propagated to new app instances.
 * Zend Server will not operate in cluster mode.
* Application generated data is not persistent (this is a limitation of Cloud Foundry) unless saved to a third party storage provider (like S3). 
* MySQL is not used automatically - If you require MySQL then you will have to setup your own server and configure your app to use it.
* If the application does not contain an 'index.php' file you will most likely encounter a "403 permission denied error".

# Additional Resources
The following resources will help you understand Cloud Foundry concepts and workflows:
* For more info on getting started with Cloud Foundry: http://docs.cloudfoundry.com/docs/dotcom/getting-started.html
* How to add a service in Cloud Foundry: http://docs.cloudfoundry.com/docs/dotcom/adding-a-service.html
* How to design apps for the cloud: http://docs.cloudfoundry.com/docs/using/app-arch/index.html
* Cloud Foundry documentation: http://docs.cloudfoundry.com/
* Read more about Zend Server Free Edition: http://www.zend.com/en/products/server/free-edition
* Zend Server edition comparison: http://www.zend.com/en/products/server/editions.
* Local installation instructions for cloud providers: (localinstallation.md)
* Cloud foundry environment variables that affect the buildpack: (environment.md)

