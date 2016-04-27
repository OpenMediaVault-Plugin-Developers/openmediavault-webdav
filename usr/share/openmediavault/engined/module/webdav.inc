<?php

/**
 * Copyright (C) 2013-2015 OpenMediaVault Plugin Developers.
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

namespace OMV\Engined\Module;

use OMV\Engine\Module\Manager as ModuleManager;
use OMV\Engine\Module\ServiceAbstract;
use OMV\Engine\Notify\Dispatcher;
use OMV\Engine\Notify\IListener;
use OMV\System\Process;

class WebDav extends ServiceAbstract implements
    IListener
{
    /** @var string */
    private $eventMessagePath = 'org.openmediavault.conf.service.webdav';

    /** @var string */
    private $sharedFolderEventMessagePath = 'org.openmediavault.conf.system.sharedfolder';

    /**
     * Get the module name.
     *
     * @return string
     */
    public function getName()
    {
        return 'webdav';
    }

    /**
     * Create and update the configuration.
     *
     * @return void
     *
     * @throws OMVException
     */
    public function applyConfig()
    {
        $cmd = new Process('omv-mkconf', $this->getName());
        $cmd->setRedirect2to1();
        $cmd->execute();
    }

    /**
     * Bind listeners.
     *
     * @param Dispatcher $dispatcher
     *
     * @return void
     */
    public function bindListeners(Dispatcher $dispatcher)
    {
        $moduleManager = ModuleManager::getInstance();

        $dispatcher->addListener(
            OMV_NOTIFY_MODIFY,
            $this->eventMessagePath,
            [$this, 'setDirty']
        );

        $dispatcher->addListener(
            OMV_NOTIFY_MODIFY,
            $this->eventMessagePath,
            [$moduleManager->getModule('php5fpm'), 'setDirty']
        );

        $dispatcher->addListener(
            OMV_NOTIFY_MODIFY,
            $this->eventMessagePath,
            [$moduleManager->getModule('webserver'), 'setDirty']
        );

        $dispatcher->addListener(
            OMV_NOTIFY_MODIFY,
            $this->sharedFolderEventMessagePath,
            [$this, 'setDirty']
        );
    }
}
