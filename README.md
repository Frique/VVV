A fork of https://github.com/Varying-Vagrant-Vagrants/VVV for personal use.

## Purpose
- Meant to run as a single instance running unlimited projects
- Focus on hooking into existing (WP) projects in any location of the local machine
- Speed up the "vagrant up / provision" process by stripping bloat from the provisioning
- Separate "vagrant up / provision" actions for optimal machine (re)boot workflow
- Simplify host + symlink creation
- Expand DB import/export functionality
- Keep list of changes here
- Keep repo up to date with VVV

## Applied features
- Load box & project setup from single setup.yaml file
- Overwrite default setup with setup-custom.yaml
- Removed WordPress installs, updates, databases & hosts (start with only vvv.dev for the dashboard)
- Stripped vagrant version pre-1.3 code
- Enabled SSL certificate for all .dev domains
- Automatically create & import databases for .sql dumps that don't exist during vagrant up & provision
- Removed installation of subversion (svn), vim, colordiff
- Added ./www/vvv-nginx.conf-sample

## Todo
- Apply project setup to nginx server setup
- Drop & reimport a database if it already exists (adds the ability to overwrite with newer version)
- Add empty database .sql sample for new projects
- Reenable some of the update checks during provisioning when vital tasks are moved to vagrant up
- Avoid checking if the ubuntu box is up to date
- No Xdebug?
- PHP7
- Skip apt-get update?
- Make provision.sh:tools_install() lighter
- Write a script to generate a new WP install with customizable defaults
- Optionally add a WP admin user to new database imports

## How to add a project
1. Put your existing .sql in **./database/backups** or copy & rename ./database/new.sql-sample to start with an empty database
2. Rename ./setup-custom.yaml-sample to **./setup-custom.yaml** and add your project details
3. Rename ./www/vvv-nginx.conf-sample to **./www/vvv-nginx.conf** and add your project's vhost config
4. Add the domain to your **local hosts file**, pointing to 192.168.50.4
5. Run vagrant provision / vagrant reload --provision

## Other references
- vagrant up
- vagrant suspend
- vagrant halt
- vagrant provision
- vagrant status
- vagrant global-status
- vagrant box update
- Visit vvv.dev for the vvv dashboard
- Connect to mysql externally via 192.168.50.4:external/external
- Connect to imported databases with localhost:admin/admin
