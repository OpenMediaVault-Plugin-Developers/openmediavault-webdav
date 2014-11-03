<?php

namespace OMV\WebDav;

use OMVRpc;
use Sabre\DAV\Auth\Backend\AbstractBasic;

class Auth extends AbstractBasic
{
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

        }

        return false;
    }
}
