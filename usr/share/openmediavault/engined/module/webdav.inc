<?php

/**
 * Copyright (C) 2009-2013 Volker Theile <volker.theile@openmediavault.org>
 * Copyright (C) 2013-2025 openmediavault plugin developers
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

class OMVModuleWebdav extends \OMV\Engine\Module\ServiceAbstract
    implements \OMV\Engine\Notify\IListener, \OMV\Engine\Module\IServiceStatus
{
    public function getName()
    {
        return "webdav";
    }

    public function getStatus()
    {
        $db = \OMV\Config\Database::getInstance();
        $object = $db->get("conf.service.webdav");
        return array(
            "name" => $this->getName(),
            "title" => gettext("WebDAV"),
            "enabled" => $object->get("enable"),
            "running" => $object->get("enable")
        );
    }

    public function bindListeners(\OMV\Engine\Notify\Dispatcher $dispatcher)
    {
        $moduleMngr = \OMV\Engine\Module\Manager::getInstance();
        $dispatcher->addListener(
            OMV_NOTIFY_MODIFY,
            "org.openmediavault.conf.service.webdav",
            [$moduleMngr->getModule("webserver"), "setDirty"]);
        $dispatcher->addListener(
            OMV_NOTIFY_MODIFY,
            "org.openmediavault.conf.service.webdav",
            [ $this, "setDirty" ]
        );
        $dispatcher->addListener(
            OMV_NOTIFY_MODIFY,
            "org.openmediavault.conf.system.sharedfolder",
            [ $this, "setDirty" ]
        );
        $dispatcher->addListener(
            OMV_NOTIFY_MODIFY,
            "org.openmediavault.conf.system.sharedfolder.privilege",
            [ $this, "setDirty" ]
        );
    }
}
