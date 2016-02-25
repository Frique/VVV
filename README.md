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
- Load box & project config from single setup.yaml file (and overwrite defaults with setup-custom.yaml). Hosts, synched folders and virtual hosts are automatically generated using these settings.
- Removed WordPress installs, updates, databases & hosts (start with only vvv.dev for the dashboard)
- Automatically create & import databases for .sql dumps that don't exist during vagrant up & provision
- Only import new databases on vagrant up, also overwrite existing on provision
- Enabled SSL certificate for all .dev domains
- Stripped vagrant version pre-1.3 code
- Removed installation of subversion (svn), vim, colordiff
- Moved vvv-hosts config to "additional_hosts" array in setup.yaml
- Skip checking if the ubuntu box is up to date to speed up boot time

## Todo
- Reenable some of the update checks during provisioning when vital tasks are moved to vagrant up
- Remove existing symlinks before adding them?
- Generate a project's guest path if it's not set (makes setup.yaml's project "guestpath" param optional)
- No Xdebug?
- PHP7
- Make provision.sh:tools_install() lighter
- Add a script to generate a new WP install with customizable defaults (trigger from setup.yaml?)
- Optionally add a WP admin user to new database imports (trigger from setup.yaml?)

## How to add a project
1. Put your existing .sql in **./database/backups** or copy & rename ./database/new.sql-sample to start with an empty database
2. Rename ./setup-custom.yaml-sample to **./setup-custom.yaml** and add your project details
3. Add the domain to your **local hosts file**, pointing to 192.168.50.4
4. Run vagrant provision / vagrant reload --provision

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
