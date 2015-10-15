<?php

/**
* Copyright (C) 2013-2015 OpenMediaVault Plugin Developers
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

require_once("openmediavault/config.inc");
require_once("openmediavault/error.inc");
require_once("openmediavault/notify.inc");
require_once("openmediavault/object.inc");
require_once("openmediavault/rpcservice.inc");
require_once("openmediavault/util.inc");

class OMVRpcServiceWebDav extends OMVRpcServiceAbstract
{
    private function getXpath()
    {
        return sprintf("/config/services/webdav");
    }

    private function getEventMessagePath()
    {
        return sprintf("org.openmediavault.services.webdav");
    }

    public function getName()
    {
        return "WebDAV";
    }

    public function initialize()
    {
        $this->registerMethod("getSettings");
        $this->registerMethod("setSettings");
    }

    public function getSettings($params, $context)
    {
        global $xmlConfig;

        // Validate the RPC caller context.
        $this->validateMethodContext($context, array(
            "role" => OMV_ROLE_ADMINISTRATOR
        ));

        // Get the configuration object.
        $object = $xmlConfig->get($this->getXpath());

        if (is_null($object)) {
            throw new OMVException(
                OMVErrorMsg::E_CONFIG_GET_OBJECT_FAILED,
                $this->getXpath()
            );
        }

        // Modify the result object.
        $object["enable"] = boolval($object["enable"]);

        return $object;
    }

    public function setSettings($params, $context)
    {
        global $xmlConfig;

        // Validate the RPC caller context.
        $this->validateMethodContext($context, array(
            "role" => OMV_ROLE_ADMINISTRATOR
        ));

        // Validate the parameters of the RPC service method.
        $this->validateMethodParams(
            $params,
            '{
                "type": "object",
                "properties": {
                    "enable": { "type": "boolean" },
                    "sharedfolderref": { "type": "string" }
                }
            }'
        );

        // Get the existing configuration object.
        $oldObject = $xmlConfig->get($this->getXpath());

        if (is_null($oldObject)) {
            throw new OMVException(
                OMVErrorMsg::E_CONFIG_GET_OBJECT_FAILED,
                $this->getXpath()
            );
        }

        // Update the configuration object.
        $object = array(
            "enable" => array_boolval($params, "enable"),
            "sharedfolderref" => $params["sharedfolderref"]
        );

        if (false === $xmlConfig->replace($this->getXpath(), $object)) {
            throw new OMVException(OMVErrorMsg::E_CONFIG_SET_OBJECT_FAILED);
        }

        // Notify configuration changes.
        $dispatcher = &OMVNotifyDispatcher::getInstance();
        $dispatcher->notify(
            OMV_NOTIFY_MODIFY,
            $this->getEventMessagePath(),
            $object
        );

        // Return the configuration object.
        return $object;
    }
}

// Register the RPC service.
$rpcServiceMgr = &OMVRpcServiceMgr::getInstance();
$rpcServiceMgr->registerService(new OMVRpcServiceWebDav());
