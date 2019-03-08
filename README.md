# foreman\_expire\_hosts

# Context

Foreman makes host creation extremely simple for a sysadmin or a user. However this simplicity leads to wasteful usage of compute resources. The foreman_expire_hosts plugin allows to specify an expiry date for the host. The host will be shutdown first and then automatically deleted after a grace period.

This plugin adds an expired on (date) field to the host form (Additional Information tab). If we create a host with expiry date, then that host will be stopped on the day after the given date and then deleted. If a host has no expiration date set then that host will live forever (until it is deleted manually).

This plugin will send two warning notifications before host expiry (see Settings). It also sends notifications when the host is stopped on its expiry date and when the host is deleted after the grace period (configured in settings).

## Compatibility

| Foreman Version | Plugin Version |
| --------------- | -------------- |
| >= 1.11         | ~> 2.0         |
| >= 1.13         | ~> 2.1         |
| >= 1.15         | ~> 3.0         |
| >= 1.16         | ~> 4.0         |
| >= 1.17         | ~> 5.0         |
| >= 1.18         | ~> 6.0         |

# Screenshots
![Expiry date field in host form](https://raw.githubusercontent.com/ingenico-group/screenshots/master/foreman_host_expiry/expiry-date-field-in-host-form.png)

![Expiry date field in host show page](https://raw.githubusercontent.com/ingenico-group/screenshots/master/foreman_host_expiry/expiry-date-in-host-show-page.png)

![Plugin Settings](https://raw.githubusercontent.com/ingenico-group/screenshots/master/foreman_host_expiry/settings.png)


# Installation
See [Plugins install instructions](https://theforeman.org/plugins/) for how to install Foreman plugins.
TLDR: You need to install the package `tfm-rubygem-foreman_expire_hosts` on RPM-based systems or use foreman-installer.

This plugin has not been packeged for Debian, yet.

# Post installation

This plugin needs additional column in hosts table. Please run migration with below command

```yaml
VERSION=20150427101516 foreman-rake db:migrate:up
```

If you have not installed this plugin through os packages, add below line to crontab to take appropriate action on expiring/expired hosts and notify user about those hosts. This cronjob will run at 07:45 AM.


```
# /etc/cron.d/foreman_expire_hosts
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

RAILS_ENV=production
FOREMAN_HOME=/usr/share/foreman

# Send out notifications about expired hosts
45 7 * * *      foreman    /usr/sbin/foreman-rake expired_hosts:deliver_notifications >>/var/log/foreman/expired_hosts.log 2>&1
```

# Pre remove

If we want to remove this feature and remove the expired_on column from hosts table, please run below rake task and either remove this gem from the Gemfile or uninstall the os package.

```yaml
VERSION=20150427101516 foreman-rake db:migrate:down
```

# Configuration

This plugin will add configurations to settings table and are editable from settings page

![Plugin Settings](https://raw.githubusercontent.com/ingenico-group/screenshots/master/foreman_host_expiry/settings.png)

NOTE: After installing this plugin, please update administrator email in Foreman Web UI (More -> Settings -> General) with valid email. This can be used to send notifications when the plugin failed to deliver notifications to its owner.


# Foreman API to add expiry date to host

Existing foreman host create/edit API can be used to add/update host's expiry date. For example

Create host with expiry date

```ruby
# POST /api/hosts
{
  "host": {
    "name": "testhost11",
    "environment_id": "334344675",
    "domain_id": "22495316",
    "ip": "10.0.0.20",
    "mac": "52:53:00:1e:85:93",
    "ptable_id": "980190962",
    "medium_id": "980190962",
    "architecture_id": "501905019",
    "operatingsystem_id": "1073012828",
    "puppet_proxy_id": "980190962",
    "compute_resource_id": "980190962",
    "root_pass": "xybxa6JUkz63w",
    "location_id": "255093256",
    "organization_id": "447626438",
    "expired_on": "30/12/2014"  # dd/mm/yyyy format
  }
}
```

curl command example

```sh
curl -u admin:changeme 'https://your-foreman-url.com/api/hosts' -d 'host[name]=testhost11&host[expired_on]=30/12/2014&......' -X POST

```

Update host expiry date

```ruby
# POST /api/hosts/testhost11
{
  "host": {
    "expired_on": "30/12/2014"  # dd/mm/yyyy format
  }
}
```

curl command example

```sh
curl -u admin:changeme 'https://your-foreman-url.com/api/hosts/testhost11' -d 'host[expired_on]=30/12/2014' -X PUT
```

# Copyright

Copyright (c) 2016 The Foreman developers

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
