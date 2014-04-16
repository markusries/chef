#
# Author:: Vasiliy Tolstov (<v.tolstov@selfip.ru>)
# Copyright:: Copyright (c) 2014 Opscode, Inc.
# License:: Apache License, Version 2.0
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

require 'chef/provider/package'
require 'chef/mixin/command'
require 'chef/resource/package'
require 'chef/mixin/shell_out'

class Chef
  class Provider
    class Package
      class Paludis < Chef::Provider::Package

        include Chef::Mixin::ShellOut

        def load_current_resource
          @current_resource = Chef::Resource::Package.new(@new_resource.name)
          @current_resource.package_name(@new_resource.package_name)

          @current_resource.version(nil)

          Chef::Log.debug("Checking package status for #{package}")
          installed = false

          shell_out!("cave -L warning print-ids -m \"#{package}\" -f \"%c/%p %v %r\n\"").stdout.each_line do |line|
            case line
            when /(.*)\s+(.*)\s+(.*)\sinstalled/
              installed = true
              @current_resource.version($2)
            else
              @candidate_version = $2
              @current_resource.version(nil)
            end
          end

          @current_resource
        end

        def install_package(name, version)
          pkg = "=#{name}-#{version}"
          shell_out!("cave -L warning resolve -x#{expand_options(@new_resource.options)} \"#{pkg}\"")
        end

        def upgrade_package(name, version)
          install_package(name, version)
        end

        def remove_package(name, version)
          if(version)
            pkg = "=#{@new_resource.package_name}-#{version}"
          else
            pkg = "#{@new_resource.package_name}"
          end

          shell_out!("cave -L warning uninstall -x#{expand_options(@new_resource.options)} \"#{pkg}\"")
        end

        def purge_package(name, version)
          remove_package(name, version)
        end

      end
    end
  end
end


