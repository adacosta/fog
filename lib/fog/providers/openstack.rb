require 'fog/core'

module Fog
  module OpenStack

    extend Fog::Provider

    service(:compute, 'compute/openstack')

    # This uses the traditional rackspace-styled token authentication.
    # It can talk to rackspace cloud services or a keystone endpoint.
    # In this authentication model you hit a single endpoint for authentication
    # across multiple services, and get the service catalog back in http
    # headers. You also get back an authentication token that will be used
    # to validate your requests to other components (nova, swift, etc).
    # 
    # Returns the response from Fog::Connection#request
    class Authenticate_1_0
      def self.authenticate uri, options
        connection = Fog::Connection.new(uri.to_s)
        path = uri.path
        path = (path.nil? or path.empty? or path == '/') ? '/v1.0' : path
        response = connection.request({
          :expects  => [200, 204],
          :headers  => {
            'X-Auth-Key'  => options[:openstack_auth_key],
            'X-Auth-User' => options[:openstack_auth_user]
          },
          :host     => uri.host,
          :method   => 'GET',
          :path     => path
        })
      end
    end

    def self.versions
      {
        '1.0' => Authenticate_1_0
      }
    end

    # Pick the version of the authentication api to use based on url,
    # default to 1.0.
    #
    # Required key = openstack_auth_url
    # Also requires version-specific authentication information
    # v1.0:
    #   * openstack_api_user
    #   * openstack_api_key
    #
    def self.authenticate(options)
      openstack_auth_url = options[:openstack_auth_url]
      url = openstack_auth_url.match(/^https?:/) ? \
                openstack_auth_url : 'https://' + openstack_auth_url
      uri = URI.parse(url)
      version = (uri.path.to_s.match(/v(\d+.\d+)/) || [nil, '1.0'])[1]
      unless mechanism = versions[version]
        raise "Unable to find authentication handler version #{version}"
      end
      mechanism.authenticate(uri, options)
    end

  end
end
