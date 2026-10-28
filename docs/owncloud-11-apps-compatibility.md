# OwnCloud 11 Apps Compatibility

| App Name       | Compatible with OwnCloud 11 | can be enabled | works somewhat | works fully |
|----------------|-----------------------------|:--------------:|----------------|-------------|
| contacts       |                             |      `🟢`      | `🟢`           |             |
| calendar       |                             |      `🟢`      | `🔴`           |             |
| passman        |                             |      `🟢`      | `🟢`           |             |
| tasks          |                             |      `🟢`     | `🟡`            |             |
| sensorlogger   |                             |      `🟢`      | `⚪`           |             |
| files_3dviewer |                             |      `🟢`      | `⚪`           |             |
| domain_manager |                             |      `🟢`      | `⚪`           |             |
| rainloop       |                             |      `🟢`       | `🟡`           |             |

## Rainloop
* Sources from https://github.com/RainLoop/rainloop-webmail/releases/tag/v1.17.0 required
* `🟡` logout from owncloud with activated rainloop app causes internal server error (500)

## Calendar
* `🔴` `npm install` fails on "jquery-timepicker": "fgelinas/timepicker#883bb2cd94". Currently no solution.

## Tasks
* `🟡` Set `<owncloud max-version="11"/>` in `info.xml` is required to enable the app in owncloud 11.