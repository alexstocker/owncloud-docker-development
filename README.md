## Owncloud Docker Development Environment for custom web apps

Simple owncloud docker environment. Ready to test and develop custom apps for owncloud.
Created and tested for use with Ubuntu 26.04. But should work on any system supporting composer and docker.

* Owncloud Classic 11 - [1.1-devel](https://github.com/alexstocker/owncloud-docker-development/tree/1.1-devel) and [main](https://github.com/alexstocker/owncloud-docker-development/tree/main)
* Owncloud Classic 10 - [1.0-devel](https://github.com/alexstocker/owncloud-docker-development/tree/1.0-devel)

Currently in Progress and testing with Owncloud Classic 11 (PHP 8.x compatible) and Owncloud 10.13.4 (PHP 7.4 compatible).

* **INPROGRESS** [SensorLogger](https://marketplace.owncloud.com/apps/sensorlogger/) for Owncloud Classic 11 (PHP 8.x compatible)
* PENDING [3D File Viewer](https://marketplace.owncloud.com/apps/files_3dviewer/) for Owncloud Classic 11 (PHP 8.x compatible)
* PENDING [Domain Manager](https://github.com/alexstocker/domain-manager-for-owncloud/tree/0.1-devel) for Owncloud Classic 11 (PHP 8.x compatible)

Others [Compatibility Checks](docs/owncloud-11-apps-compatibility.md)
* **COMPLETE** [Contacts](https://github.com/owncloud/contacts) for Owncloud Classic 11 (PHP 8.x compatible)
* **COMPLETE** [Calendar](https://github.com/owncloud/calendar/) for Owncloud Classic 11 (PHP 8.x compatible)
* **COMPLETE** [Passman](https://github.com/nextcloud/passman) for Owncloud Classic 11 (PHP 8.x compatible)
* **COMPLETE** [Tasks](https://github.com/owncloud/tasks) for Owncloud Classic 11 (PHP 8.x compatible)
* **COMPLETE** [Rainloop](https://www.rainloop.net/) for Owncloud Classic 11 (PHP 8.x compatible)
* PENDING **Activity** for Owncloud Classic 11
* PENDING **Bookmarks** for Owncloud Classic 11
* PENDING **PDF Viewer** for Owncloud Classic 11
* PENDING **Text Editor** for Owncloud Classic 11
* PENDING **Video Player** for Owncloud Classic 11

* but with some tweaks suitable for others too.

### Requirements
* composer (and PHP installed on your machine)
   * https://wiki.ubuntuusers.de/Composer/
   * https://getcomposer.org/download/ 
* docker-compose
   * sudo apt-get install docker-compose

### Install
1. your@machine:$ `git clone https://github.com/alexstocker/owncloud-docker-development.git`
2. your@machine:$ `cd owncloud-docker-development`
3. your@machine:...owncloud-docker-development$ `composer install --prefer-source` (--ignore-platform-reqs may be required if your local php version is not outdated ;-) 
4. your@machine:...owncloud-docker-development$ `composer docker-up`
5. your@machine:...owncloud-docker-development$ `sudo chown -Rf [USER]:[GROUP] vendor/` (adjust [USER] and [GROUP] to fit your needs)
6. open browser goto http://localhost:8080/ (have a look at .env for username and password) and login

### Usage

#### Get docker containers up and running
your@machine:...owncloud-docker-development$ `composer docker-up`

#### Stop docker containers
your@machine:...owncloud-docker-development$ `composer docker-stop`

#### Start docker containers
your@machine:...owncloud-docker-development$ `composer docker-start`,

#### Remove and wipe out docker containers
your@machine:...owncloud-docker-development$ `composer docker-wipeout`

#### Enable Custom Apps
your@machine:...owncloud-docker-development$ `composer enable-apps`

#### Install and Enable xdebug
your@machine:...owncloud-docker-development$ `composer install-xdebug`

#### SensorLogger API integration tests

The SensorLogger API integration suite exercises device registration, data-type lookup, and extended log storage against the ownCloud database. Run it from the development checkout with:

```sh
docker exec -u www-data -w /var/www/owncloud/apps-external/sensorlogger \
  owncloud_server env OWNCLOUD_ROOT=/var/www/owncloud \
  vendor/bin/phpunit -c phpunit.integration.xml
```

The suite creates unique test records inside a database transaction and rolls them back, so it does not require an ownCloud app password or leave test data behind. For unit tests and coverage, see the [SensorLogger development guide](https://github.com/alexstocker/sensorlogger#development-and-unit-tests).

#### SensorLogger API demo scripts

The `sensorlogger/scripts/` directory contains interactive-use examples for registering a demo device, listing its data types, and sending simulated basic or extended readings. These scripts send real requests to ownCloud and store sensor data. The development `.env` is created from `.env.default`. Add or update these entries in `.env` (existing `.env` files are not overwritten when defaults change):

```sh
SENSORLOGGER_URL=http://localhost:8080
SENSORLOGGER_USERNAME=admin
SENSORLOGGER_APP_PASSWORD=your-ownCloud-app-password
SENSORLOGGER_DEVICE_ID=
```

Use an app password created in ownCloud's Security settings, not `ADMIN_PASSWORD`. Then run:

```sh
php sensorlogger/scripts/sensorlogger-demo.php register
php sensorlogger/scripts/sensorlogger-demo.php types
php sensorlogger/scripts/sensorlogger-demo.php extended
php sensorlogger/scripts/sensorlogger-demo.php basic
```

The script reads `SENSORLOGGER_*` values from `.env`; after registration, save the printed device ID as `SENSORLOGGER_DEVICE_ID` there before using the `types` or `extended` commands. Shell environment values override `.env` if you prefer not to edit it. The basic command can run without registering a device first. To send readings continuously, use `sensorlogger/scripts/sensorlogger-demo.sh basic [interval-seconds]` or `sensorlogger/scripts/sensorlogger-demo.sh extended [interval-seconds]`; stop the loop with Ctrl-C. The extended loop requires a registered device ID. Both scripts default to `http://localhost:8080` and require PHP's cURL extension.

#### Additions for 3D File Viewer

* ... `comming soon`
