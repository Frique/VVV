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
- Skip WordPress SVN checkouts + updates
- Remove WP related hosts (start with only vvv.dev for the dashboard)
- Strip all vagrant pre-1.3 code

### Todo
- Set DB passwords to admin/admin
- Avoid checking if the ubuntu box is up to date
- Automatically create a database for an .sql dump if it doesn't exist (import-sql.sh)
- Drop a database & import the .sql is it already exists (gives the ability to overwrite with new dump)
- No Xdebug
- Simplify virtual host / symlink management
- PHP7
- Strip all VM providers except virtualbox
