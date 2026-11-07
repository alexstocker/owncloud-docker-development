## Owncloud Docker Development Environment for custom apps

### 1.1.0 (UNRELEASED)
* [NOREF] Fix PHP 8.3 ERR on Rainloop and raised OC version of tasks
* [NOREF] Start PHP 8.3 compatibility verification
* [NOREF] Workaround for Rainloop logout hook exception
* [NOREF] Workaround for Calendar frontend assets build_
* [NOREF] ADDED rainloop for PHP 8 compatibility verification
* [NOREF] ADDED tasks for PHP 8 compatibility verification
* [NOREF] ADDED passman for PHP 8 compatibility verification
* [NOREF] ADDED Calendar for PHP 8 compatibility verification
* [NOREF] ADDED Contacts for PHP 8 compatibility verification
* [NOREF] UPDATE to Owncloud 11

### 1.0.1 (UNRELEASED)
* [NOREF] IMPROVED xdebug install script
* [NOREF] FIXED Missing entrypoint on docker exec to get set env vars
* [NOREF] ADDED Domain Manager for owncloud support
* [NOREF] ADDED builer and _signing volumes for app signing purpose
* [NOREF] ADDED `composer enable-apps`
* [NOREF] UPDATED to Owncloud 10.13.4
* Modified README. Enhanced composer script
* Updated to Owncloud 10.8
* Replace owncloud shipped overwrite.config.php by overwrite.config.php.dist on docker composer-up