# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'
custom_setup_file = "./setup-custom.yaml"
setup_file = "./setup.yaml"
vagrant_dir = File.expand_path(File.dirname(__FILE__))

Vagrant.configure("2") do |config|

  # Load the setup file
  setup = YAML::load(File.read(setup_file))

  # Merge with custom setup file
  if File.exist? custom_setup_file
    setup_custom = YAML::load(File.read(custom_setup_file))
    setup.merge!(setup_custom)
  end

  # A little feedback on the loaded setup data
  config.vm.post_up_message = "VVV-Lite box configured according to the (custom) setup files: #{setup['box']} using #{setup['cpus']} CPUs and #{setup['memory'].to_i / 1024}GB RAM."

  # Skip box update check to speed up boot time
  if setup['skip_box_update']
	config.vm.box_check_update = false
  end

  # Store the current version of Vagrant for use in conditionals when dealing with possible backward compatible issues.
  vagrant_version = Vagrant::VERSION.sub(/^v/, '')

  # Store the current vagrant command (up/halt/reload/provision)
  command = ARGV[0]

  # Configurations from 1.0.x can be placed in Vagrant 1.1.x specs like the following.
  config.vm.provider :virtualbox do |v|
    v.customize ["modifyvm", :id, "--memory", setup['memory']]
    v.customize ["modifyvm", :id, "--cpus", setup['cpus']]
    v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    v.customize ["modifyvm", :id, "--natdnsproxy1", "on"]

    # Set the box name in VirtualBox to match the working directory.
    vvv_pwd = Dir.pwd
    v.name = File.basename(vvv_pwd)
  end

  # Configuration options for the Parallels provider.
  config.vm.provider :parallels do |v|
    v.update_guest_tools = true
    v.optimize_power_consumption = false
    v.memory = setup['memory']
    v.cpus = setup['cpus']
  end

  # Configuration options for the VMware Fusion provider.
  config.vm.provider :vmware_fusion do |v|
    v.vmx["memsize"] = setup['memory']
    v.vmx["numvcpus"] = setup['cpus']
  end

  # Configuration options for Hyper-V provider.
  config.vm.provider :hyperv do |v, override|
    v.memory = setup['memory']
    v.cpus = setup['cpus']
  end

  # SSH Agent Forwarding
  #
  # Enable agent forwarding on vagrant ssh commands. This allows you to use ssh keys
  # on your host machine inside the guest. See the manual for `ssh-add`.
  config.ssh.forward_agent = true

  # Load the OS box
  #
  # Once this box is downloaded to your host computer, it is cached for future use under the specified box name.
  config.vm.box = setup['box']
  config.vm.hostname = "vvv-lite"

  # Local Machine Hosts
  #
  # If the Vagrant plugin hostsupdater (https://github.com/cogitatio/vagrant-hostsupdater) is installed, the following will automatically configure your local machine's hosts file to be aware of the domains specified below.
  # Watch the provisioning script as you may need to enter a password for Vagrant to access your hosts file.
  # Hosts are taken from the setup(-custom).yaml file's addition_hosts and projects[]['host'] config.
  if defined?(VagrantPlugins::HostsUpdater)
	hosts = []

	# Add project hosts to the hosts array
    setup["projects"].each do |project|
      hosts.push project["host"]
    end

	# Add additional hosts
	setup["additional_hosts"].each do |host|
      hosts.push host
    end

	# Strip duplicates
	hosts.flatten.uniq

    # Pass the found host names to the hostsupdater plugin so it can perform magic.
	puts "Adding following hosts to the local hostfile: #{hosts}"
    config.hostsupdater.aliases = hosts
    config.hostsupdater.remove_on_suspend = true
  end

  # Private Network (default)
  #
  # A private network is created by default. This is the IP address through which your
  # host machine will communicate to the guest. In this default configuration, the virtual
  # machine will have an IP address of 192.168.50.4 and a virtual network adapter will be
  # created on your host machine with the IP of 192.168.50.1 as a gateway.
  #
  # Access to the guest machine is only available to your local host. To provide access to
  # other devices, a public network should be configured or port forwarding enabled.
  #
  # Note: If your existing network is using the 192.168.50.x subnet, this default IP address
  # should be changed. If more than one VM is running through VirtualBox, including other
  # Vagrant machines, different subnets should be used for each.
  #
  config.vm.network :private_network, id: "vvv_primary", ip: setup['ip']

  config.vm.provider :hyperv do |v, override|
    override.vm.network :private_network, id: "vvv_primary", ip: nil
  end

  # Public Network (disabled)
  #
  # Using a public network rather than the default private network configuration will allow
  # access to the guest machine from other devices on the network. By default, enabling this
  # line will cause the guest machine to use DHCP to determine its IP address. You will also
  # be prompted to choose a network interface to bridge with during `vagrant up`.
  #
  # Please see VVV and Vagrant documentation for additional details.
  #
  # config.vm.network :public_network

  # Port Forwarding (disabled)
  #
  # This network configuration works alongside any other network configuration in Vagrantfile
  # and forwards any requests to port 8080 on the local host machine to port 80 in the guest.
  #
  # Port forwarding is a first step to allowing access to outside networks, though additional
  # configuration will likely be necessary on our host machine or router so that outside
  # requests will be forwarded from 80 -> 8080 -> 80.
  #
  # Please see VVV and Vagrant documentation for additional details.
  #
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Drive mapping
  #
  # The following config.vm.synced_folder settings will map directories in your Vagrant
  # virtual machine to directories on your local machine. Once these are mapped, any
  # changes made to the files in these directories will affect both the local and virtual
  # machine versions. Think of it as two different ways to access the same file. When the
  # virtual machine is destroyed with `vagrant destroy`, your files will remain in your local
  # environment.

  # /srv/database/
  #
  # If a database directory exists in the same directory as your Vagrantfile,
  # a mapped directory inside the VM will be created that contains these files.
  # This directory is used to maintain default database scripts as well as backed
  # up mysql dumps (SQL files) that are to be imported automatically on vagrant up
  config.vm.synced_folder "database/", "/srv/database"

  # If the mysql_upgrade_info file from a previous persistent database mapping is detected,
  # we'll continue to map that directory as /var/lib/mysql inside the virtual machine. Once
  # this file is changed or removed, this mapping will no longer occur. A db_backup command
  # is now available inside the virtual machine to backup all databases for future use. This
  # command is automatically issued on halt, suspend, and destroy if the vagrant-triggers
  # plugin is installed.
  if File.exists?(File.join(vagrant_dir,'database/data/mysql_upgrade_info')) then
	config.vm.synced_folder "database/data/", "/var/lib/mysql", :mount_options => [ "dmode=777", "fmode=777" ]

    # The Parallels Provider does not understand "dmode"/"fmode" in the "mount_options" as
    # those are specific to Virtualbox. The folder is therefore overridden with one that
    # uses corresponding Parallels mount options.
    config.vm.provider :parallels do |v, override|
      override.vm.synced_folder "database/data/", "/var/lib/mysql", :mount_options => []
    end
  end

  # /srv/config/
  #
  # If a server-conf directory exists in the same directory as your Vagrantfile,
  # a mapped directory inside the VM will be created that contains these files.
  # This directory is currently used to maintain various config files for php and
  # nginx as well as any pre-existing database files.
  config.vm.synced_folder "config/", "/srv/config"

  # /srv/log/
  #
  # If a log directory exists in the same directory as your Vagrantfile, a mapped
  # directory inside the VM will be created for some generated log files.
  config.vm.synced_folder "log/", "/srv/log", :owner => "www-data"

  # /srv/www/
  #
  # If a www directory exists in the same directory as your Vagrantfile, a mapped directory
  # inside the VM will be created that acts as the default location for nginx sites. Put all
  # of your project files here that you want to access through the web server
  config.vm.synced_folder "www/", "/srv/www/", :owner => "www-data", :mount_options => [ "dmode=775", "fmode=774" ]

  config.vm.provision "fix-no-tty", type: "shell" do |s|
    s.privileged = false
    s.inline = "sudo sed -i '/tty/!s/mesg n/tty -s \\&\\& mesg n/' /root/.profile"
  end

  # The Parallels Provider does not understand "dmode"/"fmode" in the "mount_options" as
  # those are specific to Virtualbox. The folder is therefore overridden with one that
  # uses corresponding Parallels mount options.
  config.vm.provider :parallels do |v, override|
    override.vm.synced_folder "www/", "/srv/www/", :owner => "www-data", :mount_options => []
  end

  # The Hyper-V Provider does not understand "dmode"/"fmode" in the "mount_options" as
  # those are specific to Virtualbox. Furthermore, the normal shared folders need to be
  # replaced with SMB shares. Here we switch all the shared folders to us SMB and then
  # override the www folder with options that make it Hyper-V compatible.
  config.vm.provider :hyperv do |v, override|
    override.vm.synced_folder "www/", "/srv/www/", :owner => "www-data", :mount_options => ["dir_mode=0775","file_mode=0774","forceuid","noperm","nobrl","mfsymlinks"]
    # Change all the folder to use SMB instead of Virtual Box shares
    override.vm.synced_folders.each do |id, options|
      if ! options[:type]
        options[:type] = "smb"
      end
    end
  end

  # Synced project folders
  #
  # First add specified synced folders from the additional_synced_folders option in the setup file
  setup["additional_synced_folders"].each do |paths|
	config.vm.synced_folder paths["localpath"], paths["guestpath"], :owner => "www-data"
  end
  #
  # Reads the project array from the setup file (setup-custom.yaml) and creates the required synced folders for each
  setup["projects"].each do |project|
	if project["localpath"] then
	  config.vm.synced_folder project["localpath"], project["guestpath"], :owner => "www-data"
	end
  end

  # Customfile - POSSIBLY UNSTABLE
  #
  # Use this to insert your own (and possibly rewrite) Vagrant config lines. Helpful
  # for mapping additional drives. If a file 'Customfile' exists in the same directory
  # as this Vagrantfile, it will be evaluated as ruby inline as it loads.
  #
  # Note that if you find yourself using a Customfile for anything crazy or specifying
  # different provisioning, then you may want to consider a new Vagrantfile entirely.
  if File.exists?(File.join(vagrant_dir,'Customfile')) then
    eval(IO.read(File.join(vagrant_dir,'Customfile')), binding)
  end

  # Provisioning
  #
  # Process one or more provisioning scripts depending on the existence of custom files.
  #
  # provison-pre.sh acts as a pre-hook to our default provisioning script. Anything that
  # should run before the shell commands laid out in provision.sh (or your provision-custom.sh
  # file) should go in this script. If it does not exist, no extra provisioning will run.
  if File.exists?(File.join(vagrant_dir,'provision','provision-pre.sh')) then
    config.vm.provision :shell, :path => File.join( "provision", "provision-pre.sh" )
  end

  # provision.sh or provision-custom.sh
  #
  # By default, Vagrantfile is set to use the provision.sh bash script located in the
  # provision directory. If it is detected that a provision-custom.sh script has been
  # created, that is run as a replacement. This is an opportunity to replace the entirety
  # of the provisioning provided by default.
  if File.exists?(File.join(vagrant_dir,'provision','provision-custom.sh')) then
    config.vm.provision :shell, :path => File.join( "provision", "provision-custom.sh" )
  else
    config.vm.provision :shell, :path => File.join( "provision", "provision.sh" )
  end

  # provision-post.sh acts as a post-hook to the default provisioning. Anything that should
  # run after the shell commands laid out in provision.sh or provision-custom.sh should be
  # put into this file. This provides a good opportunity to install additional packages
  # without having to replace the entire default provisioning script.
  if File.exists?(File.join(vagrant_dir,'provision','provision-post.sh')) then
    config.vm.provision :shell, :path => File.join( "provision", "provision-post.sh" )
  end

  # Generate VVV-Lite project vhost configs derived from setup(-custom).yaml
  project_vhosts = ''
  setup["projects"].each do |project|
    if project["guestpath"] then
      project_vhosts << "server{\n"
      project_vhosts << "\tlisten\t\t80;\n"
      project_vhosts << "\tlisten\t\t443 ssl;\n"
      project_vhosts << "\tserver_name\t" + project["host"] + ";\n"
	  project_vhosts << "\troot\t\t'" + project["guestpath"] + "';\n"
	  project_vhosts << "\tinclude\t\t/etc/nginx/nginx-wp-common.conf;\n"
	  project_vhosts << "}\n"
    end
  end
  if project_vhosts then
    file = '/etc/nginx/custom-sites/vvv-auto-vvv-lite-projects-$(md5sum <<< "vvv-lite-projects" | cut -c1-32).conf'
	script = 'echo "Generating project vhost configs derived from setup(-custom).yaml" & '
    script << 'touch ' + file + ' & echo "' + project_vhosts + '" >> ' + file
    config.vm.provision "shell", inline: script
  end

  # Always start MySQL on boot, even when not running the full provisioner
  # (run: "always" support added in 1.6.0)
  if vagrant_version >= "1.6.0"
    config.vm.provision :shell, inline: "sudo service mysql restart", run: "always"
    config.vm.provision :shell, inline: "sudo service nginx restart", run: "always"
  end

  # Vagrant Triggers
  #
  # If the vagrant-triggers plugin is installed, we can run various scripts on Vagrant
  # state changes like `vagrant up`, `vagrant halt`, `vagrant suspend`, and `vagrant destroy`
  #
  # These scripts are run on the host machine, so we use `vagrant ssh` to tunnel back
  # into the VM and execute things. By default, each of these scripts calls db_backup
  # to create backups of all current databases. This can be overridden with custom
  # scripting. See the individual files in config/homebin/ for details.
  if defined? VagrantPlugins::Triggers
    config.trigger.after :up, :stdout => true do
      run "vagrant ssh -c 'vagrant_up'"
    end
    config.trigger.before :reload, :stdout => true do
      run "vagrant ssh -c 'vagrant_reload_before'"
    end
    config.trigger.after :reload, :stdout => true do
      run "vagrant ssh -c 'vagrant_reload_after'"
    end
    config.trigger.before :halt, :stdout => true do
      run "vagrant ssh -c 'vagrant_halt'"
    end
    config.trigger.before :suspend, :stdout => true do
      run "vagrant ssh -c 'vagrant_suspend'"
    end
    config.trigger.before :destroy, :stdout => true do
      run "vagrant ssh -c 'vagrant_destroy'"
    end
  end
end
