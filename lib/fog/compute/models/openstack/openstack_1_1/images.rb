require 'fog/core/collection'
require 'fog/compute/models/openstack/openstack_1_1/image'

module Fog
  module Compute
    class OpenStack_1_1

      class Images < Fog::Collection

        model Fog::Compute::OpenStack_1_1::Image

        attribute :server

        def all
          data = connection.list_images_detail.body['images']
          load(data)
          if server
            self.replace(self.select {|image| image.server_id == server.id})
          end
        end

        def get(image_id)
          data = connection.get_image_details(image_id).body['image']
          new(data)
        rescue Fog::Compute::OpenStack::NotFound
          nil
        end

      end

    end
  end
end
