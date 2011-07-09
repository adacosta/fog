module Fog
  module Compute
    class OpenStackExtensions
      class Real

        # List flavors (including cores)
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'id'<~Integer> - primary key
        #     * 'name'<~String> - reference name like 'm1.large'
        #     * 'ram'<~String> - megabytes of ram
        #     * 'disk'<~String> - gigabytes of disk space
        #     * 'vcpus'<~String> - number of virutal cores
        def extras_list_flavors
          request(
            :expects  => [200, 203],
            :method   => 'GET',
            :path     => "extras/flavors.json"
          )
        end

      end
    end
  end
end
