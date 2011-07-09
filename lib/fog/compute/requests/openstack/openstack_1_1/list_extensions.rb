module Fog
  module Compute
    class OpenStack_1_1
      class Real

        # List all extensions
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'alias'<~String> - Id of the extension
        #     * 'name'<~String> - Name of the extension
        #     * 'namespace'<~String> - Request namespace
        #     * 'description'<~String> - Human description
        #     * 'links'<~Array> - hashes of type and href
        def list_extensions
          request(
            :expects  => [200, 203],
            :method   => 'GET',
            :path     => 'extensions.json'
          )
        end

      end

      class Mock

        def list_extensions
          response = Excon::Response.new
          response.status = 200
          response.body = {
            'extensions' => [
              {'alias' => 'OS-TEST',
               'name' => 'test extension',
               'description' => 'simple extension',
               'namespace' => 'http://openstack.org/extensions/os-test',
               'links' => [
                 {'rel' => 'describedby',
                  'type' => 'application/pdf',
                  'href' => 'http://wiki.openstack.org/extensions/os-test/download.pdf'}]}
            ]
          }
          response
        end

      end
    end
  end
end
