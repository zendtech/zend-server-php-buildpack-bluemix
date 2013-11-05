<?php

/**
 * Zend Server GUI password change script - compatible with ZS6 and above
 * 
 * The script changes the password of the admin user, with the value passed to the script.
 * The script should be executed by the root/administrator from the command line. 
 * The script expects a single mandatory argument which is the new value of the admin passowrd
 */


ini_set('error_reporting', E_ALL & ~E_STRICT);

define('ZEND_INSTALL_DIR', get_cfg_var('zend.install_dir'));
define("GUI_SQLITE_FILENAME", 'gui.db');
define("ADMIN_NAME", 'admin');
define("ADMIN_ROLE", 'administrator');

if (! ZEND_INSTALL_DIR) {
	terminateScript("could not determine the Zend Install Directory - this problem might be caused by one of the following reasons:
	- php-cli binary executed is not the Zend Server PHP binary 
	- user running the script does not have permissions to read zend ini files");
}

try {	
	$newPassword = getNewPassword($argv);
	$iniDbdata = getConnectionDirectives();
	$dbh = getConnection($iniDbdata);
	$dbh->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
	$dbh->setAttribute(PDO::ATTR_EMULATE_PREPARES, false);
	$db = $dbh->getAttribute(PDO::ATTR_DRIVER_NAME);
	validateBootstrap($dbh);

	$statement = getReplaceStatement($newPassword);
	$pdoStatement = $dbh->prepare($statement);	
	if ($pdoStatement->execute(array(':NAME'=>ADMIN_NAME, ':PASSWORD'=>$newPassword, ':ROLE'=>ADMIN_ROLE)) === false) {
		terminateScript("SQL query [$statement] against the {$db} DB failed to execute!");
	}
	
	setSimpleAuth();

	exit("GUI password was replaced successfully" . PHP_EOL);
}
catch(Exception $e) {
	terminateScript("the script failed to execute with the following message: " . $e->getMessage());
}


// functions from here
function setSimpleAuth() {
	$guiIniPath = getGuiIniPath();
	$iniData = parse_ini_file($guiIniPath, true, INI_SCANNER_RAW);
	if (!isset($iniData['authentication']['zend_gui.simple'])) {
		terminateScript("Could not find directive 'zend_gui.simple' under the 'authentication' section - authentication method will be left as");
	}

	$value = trim($iniData['authentication']['zend_gui.simple']);
	if ($value === 'true' || $value === '1') {
		return true;
	}
	
	echo("will change authentication method to simple" . PHP_EOL);
	$iniData['authentication']['zend_gui.simple'] = '1';
	return writeIniFile($guiIniPath, $iniData);
}

function writeIniFile($guiIniPath, $iniData) {
	$dataStr = '';
	foreach($iniData as $section=>$sectionData) {
		$dataStr .= PHP_EOL . "[{$section}]" . PHP_EOL;
		foreach ($sectionData as $key=>$value) {
			if (preg_match('/[= ]/', $value)) { // parse_ini_file() strips ", even when using the INI_SCANNER_RAW option
				$value = '"' . trim($value) . '"';
			}
			
			$dataStr .= trim($key) . ' = ' . trim($value) . PHP_EOL;
		}
	}
	
	return file_put_contents($guiIniPath, trim($dataStr), LOCK_EX);
}

function getGuiIniPath() {
	$guiIniPath = ZEND_INSTALL_DIR . DIRECTORY_SEPARATOR . 'gui' . DIRECTORY_SEPARATOR . 'config' . DIRECTORY_SEPARATOR . 'zs_ui.ini';
	if (!is_writable($guiIniPath)) {
		terminateScript("GUI ini file is not writable at '{$guiIniPath}'- authentication method will be left as");
	}

	return $guiIniPath;
}

function getNewPassword($argv) {
	if (!isset($argv[1])) {
		terminateScript("the script expects the first argument to be the new password value");
	}
	
	$newPassword = trim($argv[1]);
	if (!preg_match('/^[^\x00-\x1f\s]*$/', $newPassword)) { //No control characters nor whitespace
		terminateScript("new password value should neither contain whitespaces and control characters");
	}
	
	return hash('sha256', $newPassword);
}


function getConnectionDirectives() {
	$zendDbInifile = ZEND_INSTALL_DIR . DIRECTORY_SEPARATOR . 'etc' . DIRECTORY_SEPARATOR . 'zend_database.ini';
	$iniDbdata = parse_ini_file($zendDbInifile);
	if (!isset($iniDbdata['zend.database.type'])) $iniDbdata = current($iniDbdata);// crude, but in windows, all directives are under [Zend.zend_database] section
	return $iniDbdata;
}

function getConnection() {
	global $iniDbdata;
	if (! isMysql()) return new PDO('sqlite:'.getSqliteDbPath());

	$hostname = $iniDbdata['zend.database.host_name'];
	$dbname = $iniDbdata['zend.database.name'];
	$username = $iniDbdata['zend.database.user'];
	$password = $iniDbdata['zend.database.password'];

	return new PDO("mysql:host=$hostname;dbname=$dbname", $username, $password);
}

function isMysql() {
	global $iniDbdata;
	return strtolower($iniDbdata['zend.database.type']) === 'mysql';
}

function getSqliteDbPath() {
	isWin() ? $data_dir = 'data' : $data_dir = 'var';

	$guiSqlitePath = ZEND_INSTALL_DIR . DIRECTORY_SEPARATOR .$data_dir . DIRECTORY_SEPARATOR . 'db' . DIRECTORY_SEPARATOR . GUI_SQLITE_FILENAME;
	if (!is_writable($guiSqlitePath)) {
		terminateScript("GUI sqlite db file is not writable at '{$guiSqlitePath}'");
	}
	
	return $guiSqlitePath;
}

function isWin() {
	return (stripos(PHP_OS, "win") === 0);
}

/**
 * 
 * @param PDO $dbh
 */
function validateBootstrap($dbh) {
	$usersCount = $dbh->query('SELECT count(NAME) FROM GUI_USERS')->fetch();
	if (!isset($usersCount[0]) || $usersCount[0] <= 0) {
		terminateScript("It seems that bootstrap was not peformed yet - this script should be executed against a bootstrapped ZS environment", 2);
	}
}

function getReplaceStatement($newPassword) {
	return "REPLACE INTO GUI_USERS (NAME, PASSWORD, ROLE) VALUES (:NAME, :PASSWORD, :ROLE)";
}

function terminateScript($message, $code = 1) {
	fprintf(STDERR, $message . PHP_EOL);
	exit((int) $code);
}