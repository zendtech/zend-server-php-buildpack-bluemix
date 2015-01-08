# Overview

Welcome to the Zend Server PHP buildpack! This buildpack allows you to deploy your PHP apps on Cloud Foundry using Zend Server 7.0.
Zend Server's integration with Cloud Foundry allows you to quickly get your PHP applications up and running on a highly available PHP production environment which includes, amongst other features, a highly reliable PHP stack, application monitoring, troubleshooting, and the new and innovative new technology - Z-Ray. 
Z-Ray gives developers unprecedented visibility into their code by tracking and displaying in a toolbar live and detailed info on how the various elements constructing their page are performing.

# Buildpack Components

* Zend Server 7.0 Enterprise edition
* Zend Server 7.0 configuration files
* PHP 5.4
* Apache web server

# Concepts

* .zpk - a .zpk or a Zend Application Package is basically a compressed file containing all your application data for the purpose of deployment on Zend Server, and can also be used to deploy libraries. For more information on .zpks, please visit the Zend Server Online Help at: http://files.zend.com/help/Zend-Server/zend-server.htm#application_package.htm
 

# Usage
1. Download and install Cloud Foundry's 'cf v6' CLI. For installation instructions, see http://docs.run.pivotal.io/devguide/installcf/install-go-cli.html.
2. Create a new folder on your workstation, and access it.
3. If you have an application package (.zpk) ready for deployment, place it anywhere in your application. If not, create a new 'index.php' file in the root folder of your application, and paste the following code:

 ```
<?php
echo "Hello world!";
?>
```
7. Enter the following command:
`cf push <application name> -m 512M -b https://github.com/zendtech/zend-server-php-buildpack-bluemix.git` 
Your application is deployed using the Zend Server buildpack. This may take a few minutes.
Note: If you are using Composer to manage library dependencies, make sure the 'composer.json' file is located in the root folder of your application. Your dependecies will be installed together with your application.
7. Once successfully initialized and deployed, a success message with the URL at which your application is available at is displayed.
8. To access the application, enter the supplied URL in your Web browser. Deployed .zpks can be accessed at: `http://<application URL>/<.zpk name>`
9. To access Zend Server, add 'ZendServer' to the supplied URL. For example:`http://<application URL>/ZendServer` The Zend Server Login page is displayed.
10. Log in using the following credentials: Username - admin, Password - enter the following command in your CLI to retrieve an initial password: `cf files <application name> /app/zend-password` 
11. To change the Zend Server UI password, or in case you misplace your password, enter the following command:
`cf set-env <application name> ZS_ADMIN_PASSWORD <new password>`. After this you may have to redeploy your application using `cf push` command.
12. To use Z-Ray, enable it first. Go to the Configurations | Z-Ray page in the Zend Server UI, and select Enabled. Once enabled, simply open your app in a browser.

## Automatically Importing PHP Configurations
The Zend Server buildpack can optionally import PHP configurations from backup files. This allows you to easily deploy applications which require a change of directives.
It also allows you to retain changes you made using the Zend Server GUI. To do so, follow these instructions:

1. In your application's code (on your workstation) create a folder named `.zend_config`.
2. Browse to: `http://<application URL>/ZendServer/ImportExport/`.
3. Click on the "Export Configuration" button.
4. Move the saved file to the .zend_config folder in your app.
5. Change directory into your app source code directory: `cd <app_source_directory_on_your_workstation>`
6. Enter the following command to apply the changes: `cf push` 

``` Tip: you can reuse these backup files for other applications that might require similar settings. ```

# Known Issues
* Zend Server Code Tracing may not work properly in this version.
* Several issues might be encountered if you do not bind MySQL providing service to the app (mysql/MariaDB):
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
* Local installation instructions for cloud providers: [localinstallation.md](localinstallation.md)
* Cloud foundry environment variables that affect the buildpack: [environment.md](environment.md)

# User Feedback

Think we’ve missed something? Let us know at: http://www.zend.com/en/support-center
