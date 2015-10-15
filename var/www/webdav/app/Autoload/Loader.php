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

namespace OMVWebDAV\Autoload;

class Loader
{
    private $classMaps = [];
    private $namespaces = [];

    /**
     * Add a class mapping to the file containing the class.
     *
     * @param string $class The classname with full namespace.
     * @param string $path The filepath to the file containing the class.
     * @return void
     */
    public function addClassMap($class, $path)
    {
        $this->classMaps[$class] = $path;
    }

    /**
     * Add a namespace mapping to a specific directory.
     *
     * @param string $prefix Namepspace prefix with trailing \\.
     * @param string $path The directory which classes will be mapped to.
     * @return void
     */
    public function addNamespace($prefix, $path)
    {
        $this->namespaces[$prefix] = $path;
    }

    /**
     * Load a class based on its classname and namespace.
     *
     * @param string $class The classname.
     * @return bool|null
     */
    public function loadClass($class)
    {
        // Try to find it in the classmap first.
        if (isset($this->classMaps[$class])) {
            $file = $this->classMaps[$class];

            if (is_file($file)) {
                includeFile($file);

                return true;
            }
        }

        // Move on to namespaces.
        foreach ($this->namespaces as $prefix => $dir) {
            if (0 === strpos($class, $prefix)) {
                $extension = ".php";
                $prefixLength = strlen($prefix);

                $remainingClasspath = strtr(
                    substr($class . $extension, $prefixLength),
                    "\\",
                    DIRECTORY_SEPARATOR
                );

                $file = $dir . DIRECTORY_SEPARATOR . $remainingClasspath;

                if (is_file($file)) {
                    includeFile($file);

                    return true;
                }
            }
        }
    }

    /**
     * Register the autoloader.
     *
     * @return void
     */
    public function register()
    {
        spl_autoload_register(array($this, "loadClass"));
    }
}

function includeFile($file)
{
    include_once $file;
}
