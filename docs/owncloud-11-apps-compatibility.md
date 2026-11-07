# OwnCloud 11 Apps Compatibility

| App Name       |                                                                                                         PHP 8.3                                                                                                          | can be enabled | works somewhat | OC 11 compatibility | Repository                                                                        | Branch                                                                       |
|----------------|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------:|:--------------:|:--------------:|:-------------------:|-----------------------------------------------------------------------------------|------------------------------------------------------------------------------|
| contacts       |                                                                                                           `🟡`                                                                                                           |      `🟢`      |      `🟢`      |        `⚪`         | [alexstocker/owncloud-contacts](https://github.com/alexstocker/owncloud-contacts) | [1.6-devel](https://github.com/alexstocker/owncloud-contacts/tree/1.6-devel) |
| calendar       | [![PHP 8.3](https://img.shields.io/github/actions/workflow/status/alexstocker/owncloud-calendar/main.yml?branch=2.1-devel&label=PHP%208.3)](https://github.com/alexstocker/owncloud-calendar/actions/workflows/main.yml) |      `🟢`      |      `🟢`      |        `🟢`         | [alexstocker/owncloud-calendar](https://github.com/alexstocker/owncloud-calendar) | [2.1-devel](https://github.com/alexstocker/owncloud-calendar/tree/2.1-devel) |
| passman        |                                                                                                           `🟡`                                                                                                           |      `🟢`      |      `🟢`      |        `⚪`         |
| tasks          |                                                                                                           `🟢`                                                                                                           |      `🟢`      |      `🟢`      |        `⚪`         |
| sensorlogger   |                                                                                                           `⚪`                                                                                                           |      `🟢`      |      `⚪`      |        `⚪`         |
| files_3dviewer |                                                                                                           `⚪`                                                                                                           |      `🟢`      |      `⚪`      |        `⚪`         |
| domain_manager |                                                                                                           `⚪`                                                                                                           |      `🟢`      |      `⚪`      |        `⚪`         |
| rainloop       |                                                                                                           `🟡`                                                                                                           |      `🟢`      |      `🟢`      |        `⚪`         |

## Rainloop
* Sources from https://github.com/RainLoop/rainloop-webmail/releases/tag/v1.17.0 required
* `🟡` logout from owncloud with activated rainloop app causes internal server error (500)
  * Solution/**Workaround**
    * `include_once OC_App::getAppPath('rainloop').'/lib/RainLoopHelper.php';` to fix ownCloud 11 failed to autoload RainLoop’s legacy OC_RainLoop_Helper class when invoking its logout hook.
* **FIXED** `🔴` ERR on PHP 8.3 compatibility. MUST to be fixed.
* `🟡` WARN on PHP 8.3 compatibility. SHOULD be fixed.

### Hints
```bash
docker compose run --no-deps --rm node yarn install --frozen-lockfile
make rl-build
```

## Calendar
* `🔴` `npm install` fails on "jquery-timepicker": "fgelinas/timepicker#883bb2cd94". 
  * Solution/**Workaround**
    * `nvm install 18` (will install node 18.20.8)
    * `nvm use 18.20.8`
    * `yarn install --frozen-lockfile`
* `🟡` WARN on PHP 8.3 compatibility. SHOULD be fixed.

## Tasks
* **FIXED**`🟡` Set `<owncloud max-version="11"/>` in `info.xml` is required to enable the app in owncloud 11.

## Passman
* `🟡` WARN on PHP 8.3 compatibility. SHOULD be fixed.