This is a Chef report handler that allows [Jenkins](http://jenkins-ci.org/) to track
when files are deployed where.

# Usage
There are two ways to configure Chef Handler.

## Via solo.rb or client.rb
Install `chef-handler-jenkins` gem upfront first:

    $ gem install chef-handler-jenkins

Then configure Chef to use it with the following lines. For chef-solo, you can put that in your [/etc/chef/solo.rb](http://docs.opscode.com/config_rb_solo.html) (or your local override). For chef-client, you can put that in your [/etc/chef/client.rb](http://docs.opscode.com/config_rb_client.html).

    require 'chef/handler/jenkins'
    report_handlers << Chef::Handler::Jenkins.new(:url => 'http://myserver.acme.com/jenkins')
 
This approach is best suited if you own the operation environment and want to do the deployment integration without modifying recipes.

## Via recipes
Use [chef_handler cookbook](http://community.opscode.com/cookbooks/chef_handler) and activate this handler via your recipe:

    chef_gem 'chef-handler-jenkins'
    
    chef_handler 'Chef::Handler::Jenkins' do
      source 'chef/handler/jenkins'
      arguments :url => 'http://myserver.acme.com/jenkins'
      action :enable
    end
