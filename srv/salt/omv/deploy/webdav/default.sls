# @license   http://www.gnu.org/licenses/gpl.html GPL Version 3
# @author    OpenMediaVault Plugin Developers <plugins@omv-extras.org>
# @copyright Copyright (c) 2019-2025 openmediavault plugin developers
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

# The configuration was based on:
# https://nworm.icu/post/nginx-webdav-dolphin-deken/
# https://www.robpeck.com/2020/06/making-webdav-actually-work-on-nginx/
# https://wiki.archlinux.org/title/WebDAV
# https://www.robpeck.com/2020/06/making-webdav-actually-work-on-nginx/

# if the request method is MKCOL or is to a directory, add / at the end of the URL if it was missing
# if the request method is COPY or MOVE a directory, also add / at the end of the Destination header if it was missing

{% set config = salt['omv_conf.get']('conf.service.webdav') %}
{% set confFile = '/etc/nginx/openmediavault-webgui.d/openmediavault-webdav.conf' %}
{% set lockFile = '/etc/nginx/conf.d/openmediavault-lockzone.conf' %}
{% set pamFile = '/etc/pam.d/openmediavault-webdav' %}
{% set allowFile = '/etc/openmediavault-webdev.group.allow' %}

{% if config.enable | to_bool and config.sharedfolderref != '' %}

{% set sfpath = salt['omv_conf.get_sharedfolder_path'](config.sharedfolderref) %}

configure_webdav:
  file.managed:
    - name: "{{ confFile }}"
    - contents: |
        location ^~ /webdav {
            alias {{ sfpath }};
            dav_methods PUT DELETE MKCOL COPY MOVE;
            dav_ext_methods PROPFIND OPTIONS LOCK UNLOCK;
            dav_ext_lock zone=foo;
            dav_access  user:rw group:rw;
            create_full_put_path on;
            client_body_temp_path /srv/client_temp;
            {% if config.auth | to_bool -%}
            auth_pam "PAM Authentication";
            auth_pam_service_name "openmediavault-webdav";
            {% endif -%}
            autoindex on;
            error_page 404 /_404;
            if ($request_method = MKCOL) {
                rewrite ^(.*[^/])$ $1/;
            }
            set $destination $http_destination;
            set $parse "";
            if ($request_method = MOVE) {
                set $parse "${parse}M";
            }
            if ($request_method = COPY) {
                set $parse "${parse}M";
            }
            if (-d $request_filename) {
                rewrite ^(.*[^/])$ $1/;
                set $parse "${parse}D";
            }
            if ($destination ~ ^(https?://.+)$) {
                set $ob $1;
                set $parse "${parse}R${ob}";
            }
            if ($parse ~ ^MDR(.*[^/])$) {
                set $mvpath $1;
                set $destination "${mvpath}/";
                more_set_input_headers "Destination: $destination";
            }
            {{ config.extraoptions | indent(12) }}
        }
    - user: root
    - group: root
    - mode: 644

configure_lockzone_conf:
  file.managed:
    - name: "{{ lockFile }}"
    - contents: |
        dav_ext_lock_zone zone=foo:10m;
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
      - "{{ lockFile }}"
      - "{{ pamFile }}"
      - "{{ allowFile }}"

{% endif %}

reload_nginx_service:
  service.running:
    - name: nginx
    - enable: True
    - reload: True
    - watch:
{% if config.enable | to_bool and config.sharedfolderref != '' %}
      - file: configure_webdav
      - file: configure_lockzone_conf
{% if config.auth | to_bool %}
      - file: configure_webdav_pam
      - file: configure_pam_allow
{% else %}
      - file: remove_webdav_auth_files
{% endif %}
{% else %}
      - file: remove_webdav_conf_files
{% endif %}
