# @license   http://www.gnu.org/licenses/gpl.html GPL Version 3
# @author    OpenMediaVault Plugin Developers <plugins@omv-extras.org>
# @copyright Copyright (c) 2019-2022 OpenMediaVault Plugin Developers
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

{% set config = salt['omv_conf.get']('conf.service.webdav') %}
{% set confFile = '/etc/nginx/openmediavault-webgui.d/openmediavault-webdav.conf' %}
{% set pamFile = '/etc/pam.d/openmediavault-webdav' %}
{% set allowFile = '/etc/openmediavault-webdev.group.allow' %}

{% if config.enable | to_bool %}

{% set sfpath = salt['omv_conf.get_sharedfolder_path'](config.sharedfolderref) %}

configure_sftp_root_dir:
  file.directory:
    - name: "{{ sfpath }}/webdav"
    - user: www-data
    - group: "{{ config.grpname }}"
    - mode: 770

configure_webdav:
  file.managed:
    - name: "{{ confFile }}"
    - contents: |
        location /webdav {
            root {{ sfpath }};
            dav_methods PUT DELETE MKCOL COPY MOVE;
            dav_ext_methods PROPFIND OPTIONS;
            dav_access  user:rw group:rw;
            create_full_put_path on;
            client_body_temp_path /srv/client_temp;
            {% if config.auth | to_bool -%}
            auth_pam "PAM Authentication";
            auth_pam_service_name "openmediavault-webdav";
            {% endif -%}
            autoindex on;
        }
    - user: root
    - group: root
    - mode: 644

{% if config.auth | to_bool %}

configure_webdav_pam:
  file.managed:
    - name: "{{ pamFile }}"
    - contents: |
        auth required pam_listfile.so onerr=fail item=group sense=allow file={{ allowFile }}
        @include common-auth
    - user: root
    - group: root
    - mode: 644

configure_pam_allow:
  file.managed:
    - name: "{{ allowFile }}"
    - contents: |
        {{ config.grpname }}
    - user: root
    - group: root
    - mode: 644

{% else %}

remove_webdav_auth_files:
  file.absent:
    - names:
      - "{{ pamFile }}"
      - "{{ allowFile }}"

{% endif %}

{% else %}

remove_webdav_conf_files:
  file.absent:
    - names:
      - "{{ confFile }}"
      - "{{ pamFile }}"
      - "{{ allowFile }}"

{% endif %}

reload_nginx_service:
  service.running:
    - name: nginx
    - enable: True
    - reload: True
