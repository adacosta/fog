require 'fog/core/collection'
require 'fog/compute/models/openstack/openstack_1_1/flavor'

module Fog
  module Compute
    class OpenStack_1_1

      class Flavors < Fog::Collection

        model Fog::Compute::OpenStack_1_1::Flavor

        def all
          data = connection.list_flavors_detail.body['flavors']
          load(data)
        end

        def get(flavor_id)
          data = connection.get_flavor_details(flavor_id).body['flavor']
          new(data)
        rescue Fog::Compute::OpenStack::NotFound
          nil
        end

      end

    end
  end
end
