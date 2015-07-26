<?php

/**
 * Copyright (C) 2015 OpenMediaVault Plugin Developers
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

// Require autoloader.
require_once __DIR__."/../config/autoloader.php";

// Load config.
require_once __DIR__."/../config/config.php";

// Create a new server with a public directory.
$rootDirectory = new \Sabre\DAV\FS\Directory($publicDir);
$server = new \Sabre\DAV\Server($rootDirectory);

// Set up authentication.
$authBackend = new \OMVWebDAV\Auth\Openmediavault();
$authPlugin = new \Sabre\DAV\Auth\Plugin($authBackend, "OpenMediaVault WebDAV");

// Set up WebDAV locks.
$lockBackend = new \Sabre\DAV\Locks\Backend\File(
    tempnam(sys_get_temp_dir(), "webdav")
);
$lockPlugin = new \Sabre\DAV\Locks\Plugin($lockBackend);

// Set base URI.
$server->setBaseUri("/webdav/");

// Add plugins.
$server->addPlugin($lockPlugin);
$server->addPlugin($authPlugin);
$server->addPlugin(new \Sabre\DAV\Browser\Plugin());

return $server;
