<?php

/**
 * Copyright (C) 2013-2017 OpenMediaVault Plugin Developers.
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

namespace OMV\Engined\Rpc;

use OMV\Config\Database;
use OMV\Rpc\ServiceAbstract;

class WebDav extends ServiceAbstract
{
    /** @var Database */
    private $database;

    /** @var string */
    private $dataModelPath = 'conf.service.webdav';

    public function __construct(Database $database = null)
    {
        $this->database = $database ?: Database::getInstance();
    }

    /**
     * Get the name of the RPC service.
     *
     * @return string
     */
    public function getName()
    {
        return 'WebDAV';
    }

    /**
     * Initialize the RPC service.
     *
     * @return void
     */
    public function initialize()
    {
        $this->registerMethod('getSettings');
        $this->registerMethod('setSettings');
    }

    /**
     * Get the settings of the service.
     *
     * @param array $params  The method parameters.
     * @param array $context The context of the caller.
     *
     * @return array
     */
    public function getSettings($params, $context)
    {
        $this->validateMethodContext($context, ['role' => OMV_ROLE_ADMINISTRATOR]);

        $object = $this->database->get($this->dataModelPath);

        return $object->getAssoc();
    }

    /**
     * Set the settings of the service.
     *
     * @param array $params  The method parameters.
     * @param array $context The context of the caller.
     *
     * @return array
     */
    public function setSettings($params, $context)
    {
        $this->validateMethodContext($context, ['role' => OMV_ROLE_ADMINISTRATOR]);
        $this->validateMethodParams($params, 'rpc.webdav.setsettings');

        $object = $this->database->get($this->dataModelPath);
        $object->setAssoc($params);

        $this->database->set($object);

        return $object->getAssoc();
    }
}
