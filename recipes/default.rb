#
# Cookbook Name:: chef-handler-jenkins
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe 'chef_handler'

cookbook_file 'jenkins_handler.rb' do
  path ::File.join(node['chef_handler']['handler_path'], 'jenkins_handler.rb')
  owner 'root'
  group 'root'
  mode 0755
  action :create
end

chef_handler 'Chef::Handler::Jenkins' do
  source ::File.join(node['chef_handler']['handler_path'], 'jenkins_handler.rb')
  arguments :url => node['chef-handler-jenkins']['jenkins_url'],
            :dryrun => node['chef-handler-jenkins']['dryrun']
  action :enable
end
