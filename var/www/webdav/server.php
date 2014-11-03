<?php

// Require autoloader.
require_once "vendor/autoload.php";

// Additional requires.
require_once "/usr/share/php/openmediavault/rpc.inc";
require_once "auth.php";
require_once "config.php";

$rootDirectory = new \Sabre\DAV\FS\Directory($publicDir);

$server = new \Sabre\DAV\Server($rootDirectory);

// Auth.
$authBackend = new \OMV\WebDav\Auth();
$authPlugin = new \Sabre\DAV\Auth\Plugin($authBackend, "OpenMediaVault WebDAV");

// Locks.
$lockBackend = new \Sabre\DAV\Locks\Backend\File("/tmp/sabre_locks");
$lockPlugin = new \Sabre\DAV\Locks\Plugin($lockBackend);

// Set base URI.
$server->setBaseUri("/webdav/");

// Add plugins.
$server->addPlugin($lockPlugin);
$server->addPlugin($authPlugin);
$server->addPlugin(new \Sabre\DAV\Browser\Plugin());

// Run server.
$server->exec();
