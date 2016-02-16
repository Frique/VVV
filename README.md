A fork of https://github.com/Varying-Vagrant-Vagrants/VVV for personal use.

### Purpose
- Meant to run as a single instance running unlimited projects
- Focus on hooking into existing (WP) projects in any location of the local machine
- Speed up the "vagrant up / provision" process by stripping bloat from the provisioning
- Simplify host + symlink creation
- Expand DB import/export functionality
- Keep list of changes here
- Keep repo up to date with VVV
- Separate vagrant up & provision actions for optimal machine (re)boot workflow

### Applied features
- Switched to trusty32 for lighter performance
- Removed WordPress installs, updates, databases & hosts (start with only vvv.dev for the dashboard)
- Stripped vagrant version pre-1.3 code
- Enabled SSL certificate for all .dev domains
- Automatically create a database for an .sql dump if it doesn't exist during provision
- Removed installation of subversion (svn), vim, colordiff
- Added ./Customfile-sample and ./www/vvv-nginx.conf-sample
- Import new .sql databases from ./database/backups during vagrant up

### Todo
- Drop & reimport a database if it already exists (adds the ability to overwrite with newer version)
- Automate/simplify project / virtual host / symlink / database management (Create custom setup file to manage everything in 1 place?)
- Avoid checking if the ubuntu box is up to date
- No Xdebug?
- PHP7
- Strip all VM providers except virtualbox
- Skip apt-get update?
- Make provision.sh:tools_install() lighter
- Add empty database .sql sample for new projects
- Optionally add a WP admin user to new database imports
- Load box & project setup from single setup.yaml file
- Append setup-custom.yaml to setup.yaml (overwrite defaults)

### Adding a project
1. Existing DB: Put your .sql in **./database/backups**
1. New DB: //todo Copy & rename ./database/empty.sql to start with an empty database
2. Rename ./www/vvv-nginx.conf-sample to **./www/vvv-nginx.conf** and add your project's vhost config
3. Rename ./Customfile-sample to **./Customfile** and add a symlink to your local project folder
4. Add the domain to your **local hosts file**, pointing to 192.168.50.4
5. Run "vagrant provision"

### Other references
- vagrant up
- vagrant suspend
- vagrant halt
- vagrant provision
- vagrant status
- vagrant global-status
- vagrant box update
- Visit vvv.dev for the vvv dashboard
- Connect to mysql externally via 192.168.50.4:external/external
- Connect to imported databases with admin/admin
