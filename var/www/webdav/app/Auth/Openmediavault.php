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

namespace OMVWebDAV\Auth;

use OMVRpc;
use Sabre\DAV\Auth\Backend\AbstractBasic;

/**
 * HTTP Basic authentication backend that integrates with OpenMediaVault.
 */
class Openmediavault extends AbstractBasic
{
    /**
     * Validates a username and password.
     *
     * @param string $username
     * @param string $password
     * @return bool
     */
    public function validateUserPass($username, $password)
    {
        try {
            $result = OMVRpc::exec(
                "UserMgmt",
                "authUser",
                array(
                    "username" => $username,
                    "password" => $password
                ),
                array(
                    "username" => "admin",
                    "role" => OMV_ROLE_ADMINISTRATOR
                ),
                OMV_RPC_MODE_REMOTE
            );

            if ($result["authenticated"]) {
                return true;
            }
        } catch (Exception $e) {
            // Do nothing.
        }

        return false;
    }
}
