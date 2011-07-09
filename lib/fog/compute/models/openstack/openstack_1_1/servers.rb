require 'fog/core/collection'
require 'fog/compute/models/openstack/openstack_1_1/server'

module Fog
  module Compute
    class OpenStack_1_1

      class Servers < Fog::Collection

        model Fog::Compute::OpenStack_1_1::Server

        def all
          data = connection.list_servers_detail.body['servers']
          load(data)
        end

        def bootstrap(new_attributes = {})
          server = create(new_attributes)
          server.wait_for { ready? }
          server.setup(:password => server.password)
          server
        end

        def get(server_id)
          if server = connection.get_server_details(server_id).body['server']
            new(server)
          end
        rescue Fog::Compute::OpenStack::NotFound
          nil
        end

      end

    end
  end
end
