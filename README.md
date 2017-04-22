This project is no longer maintained!

---

A fork of https://github.com/Varying-Vagrant-Vagrants/VVV with some significant changes.

## Purpose
- Meant to run as a single instance running multiple projects
- Focus on hooking into existing (WP) projects in any location of the local machine
- Balance out the "vagrant up / provision" processes for optimal machine (re)boot/update workflow
- Simplify project (host, symlink, nginx, database) management

## Applied features
- Load box & project config from single setup.yaml file (and overwrite defaults with setup-custom.yaml). Hosts, synched folders and virtual hosts are automatically generated using these settings.
- Automatically create & import databases for .sql dumps that don't exist during vagrant up & also overwrite the existing databases during provision
- Removed WordPress installs, updates, databases & hosts (start with only vvv.dev for the dashboard)
- Enabled SSL certificate for all .dev domains
- Stripped vagrant version pre-1.3 code
- Removed installation of subversion (svn), vim, colordiff
- Skip checking if the ubuntu box is up to date to speed up boot time
- Reduced the need to run the (slow) provisioning process. Provisioning is now only needed to install/update the box software. Simply run vagrant reload to apply new projects.

## Todo
- Remove existing symlinks before adding them?
- Generate a project's guest path if it's not set (makes setup.yaml's project "guestpath" param optional)
- Make provision.sh:tools_install() lighter
- Add a script to generate a new WP install with customizable defaults (trigger from setup.yaml?)
- Optionally add a WP admin user to new database imports (trigger from setup.yaml?)
- Expand the vvv.dev dashboard

## How to add a project
1. Put your existing .sql in **./database/backups** or copy & rename ./database/new.sql-sample to start with an empty database
2. Copy & rename ./setup-custom.yaml-sample to **./setup-custom.yaml** and add your project details
3. Add the domain to your **local hosts file**, pointing to 192.168.50.4 (or use the hostsupdater plugin to do this automatically)
4. Run **vagrant up** or vagrant reload

## References
- vagrant up
- vagrant suspend
- vagrant halt
- vagrant provision
- vagrant ssh
- vagrant status
- vagrant global-status
- vagrant box update
- Visit vvv.dev for the vvv dashboard
- Connect to mysql externally via 192.168.50.4:external/external
- Connect to imported databases with localhost:admin/admin
