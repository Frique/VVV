A fork of https://github.com/Varying-Vagrant-Vagrants/VVV for personal use.

### Purpose
- Focus on hooking into existing (WP) projects
- Speed up the "vagrant up" process by stripping bloat from the provisioning
- Simplify host + symlink creation
- Expand DB import/export functionality
- Anything that makes it ideal as a single box with many projects
- Keep list of changes here
- Keep repo up to date with VVV

### Applied features
- Switch to trusty32 for lighter performance
- Skip WordPress installs, updates & databases
- Remove WP related hosts (start with only vvv.dev for the dashboard)
- Strip vagrant version pre-1.3 code
- Enable SSL certificate for all .dev domains
- Automatically create a database for an .sql dump if it doesn't exist (user: admin/admin)
- Skip installation of subversion (svn), vim, colordiff

### Todo
- Avoid checking if the ubuntu box is up to date
- Drop & reimport a database if it already exists (adds the ability to overwrite with newer version)
- No Xdebug?
- Simplify virtual host / symlink management
- PHP7
- Strip all VM providers except virtualbox
- Skip apt-get update?
