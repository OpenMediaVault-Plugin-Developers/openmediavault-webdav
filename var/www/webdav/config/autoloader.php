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

require_once "Symfony/Component/ClassLoader/ClassLoader.php";
require_once "Symfony/Component/ClassLoader/MapClassLoader.php";

use Symfony\Component\ClassLoader\ClassLoader;
use Symfony\Component\ClassLoader\MapClassLoader;

$loader = new ClassLoader();

$loader->setUseIncludePath(true);

$loader->register();

$mapLoader = new MapClassLoader([
    "OMVRpc" => "/usr/share/php/openmediavault/rpc.inc",
    // Normally we would add OMVWebDAV to the ClassLoader but we're only PSR-4
    // compliant and not PSR-0.
    "OMVWebDAV\\Auth\\Openmediavault" => __DIR__."/../app/Auth/Openmediavault.php",
]);

$mapLoader->register();
