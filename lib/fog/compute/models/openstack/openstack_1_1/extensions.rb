require 'fog/core/collection'
require 'fog/compute/models/openstack/openstack_1_1/extension'

module Fog
  module Compute
    class OpenStack_1_1

      class Extensions < Fog::Collection

        model Fog::Compute::OpenStack_1_1::Extension

        def all
          data = connection.list_extensions.body['extensions']
          load(data)
        end

        def get(ext_alias)
          data = connection.get_extension_details(ext_alias).body['extension']
          new(data)
        rescue Fog::Compute::OpenStack::NotFound
          nil
        end

      end

    end
  end
end
