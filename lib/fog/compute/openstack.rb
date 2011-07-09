module Fog
  module Compute

    # This class supports a mutli-versioned interface for openstack services.
    #
    # Since keystone builds a service catalog through http headers, you can 
    # specify which service you actually want to use with the
    # openstack_compute_url_header option (Default X-Server-Management-Url),
    # this lets you swith to a 1.0 compatability service if you desire, or use
    # a demo cloud, if keystone is perhaps offering a x-nova-preview or
    # somesuch.
    #
    # Authentication is set via openstack_auth_(url|user|key) options.  If
    # you only pass in a hostname for the url, it will be treated a v1.0 over
    # https.  If you pass in a url that doesn't have a path,
    # eg. http://cloudprovider.com, it will use v1.0 auth as well.
    #
    # You can share authentication tokens and endpoints as well, to keep from
    # having to hit the authentication service across multiple threads,
    # or to use an unpublished compute service, by specifying
    # openstack_auth_token and openstack_compute_service_url
    #
    # You can also specify a particular version to interface with the endpiont
    # with via the openstack_compute_api_version
    class OpenStack < Fog::Service

      recognizes :openstack_auth_url, :openstack_auth_user, :openstack_auth_key
      recognizes :openstack_compute_url_header, :openstack_compute_service_url
      recognizes :openstack_auth_token

      class Real
        def initialize(options={})
          require 'json'
          [:openstack_auth_key, :openstack_auth_user, :openstack_auth_url,
           :openstack_auth_token, :openstack_compute_service_url,
           :openstack_compute_url_header].each do |k|
            instance_variable_set("@#{k}", options[k])
          end
          @openstack_must_reauthenticate = !(@openstack_auth_token and \
                                             @openstack_compute_service_url)
          authenticate
          # after authenticate, auth token, service url, and version are set
          uri = URI.parse(@openstack_compute_service_url)
          @connection = Fog::Connection.new(
                            "#{uri.scheme}://#{uri.host}:#{uri.port}",
                            options[:persistent])
        end

        def versioned_service
          unless rv = versions[@openstack_compute_api_version]
            raise "Got unexpected api version #{rv}"
          end
          unless version_backends[rv]
            rv.setup_requirements
            if Fog.mocking?
              rv::Mock.send(:include, rv::Collections)
              version_backends[rv] = rv::Mock.new
            else
              rv::Real.send(:include, rv::Collections)
              version_backends[rv] = rv::Real.new(:requestor => self)
            end
          end
          version_backends[rv]
        end

        def extension_service
          unless @extension_service
            rv = OpenStackExtensions
            rv.setup_requirements
            if Fog.mocking?
              rv::Mock.send(:include, rv::Collections)
              inst = rv::Mock.new
            else
              rv::Real.send(:include, rv::Collections)
              inst = rv::Real.new(:requestor => self)
            end
          end
          inst
        end

        def versions
          {
            '1.0' => OpenStack_1_0,
            '1.1' => OpenStack_1_1
          }
        end

        def version_backends
          @version_backends ||= {}
        end

        def reload
          @connection.reset
        end

        def request(params)
          uri = URI.parse(@openstack_compute_service_url)
          begin
            response = @connection.request(params.merge!({
              :headers  => {
                'Content-Type' => 'application/json',
                'X-Auth-Token' => @openstack_auth_token
              }.merge!(params[:headers] || {}),
              :host     => uri.host,
              :path     => "#{uri.path}/#{params[:path]}",
              :query    => ('ignore_awful_caching' << Time.now.to_i.to_s)
            }))
          rescue Excon::Errors::Unauthorized => error
            if JSON.parse(response.body)['unauthorized']['message'] == 'Invalid authentication token.  Please renew.'
              @openstack_must_reauthenticate = true
              authenticate
              retry
            else
              raise error
            end
          rescue Excon::Errors::HTTPStatusError => error
            raise case error
            when Excon::Errors::NotFound
              Fog::Compute::OpenStack::NotFound.slurp(error)
            else
              error
            end
          end
          unless response.body.empty?
            response.body = JSON.parse(response.body)
          end
          response
        end

        private

        def method_missing name, *args
          if versioned_service.respond_to?(name)
            versioned_service.send(name, *args)
          elsif versioned_service.service.supports_extensions? \
          and extension_service.respond_to?(name)
            extension_service.send(name, *args)
          else
            super
          end
        end

        def authenticate
          if @openstack_must_reauthenticate
            @openstack_must_reauthenticate = false
            options = [:key, :url, :user].inject({}) do |opts, key|
                        name = "openstack_auth_#{key}".to_sym
                        opts.merge(name => instance_variable_get("@#{name}"))
                      end
            response = Fog::OpenStack.authenticate(options)
            @openstack_auth_token = response.headers['X-Auth-Token']
            # always take user-supplied endpoint over published endpoint
            unless @openstack_compute_service_url
              header_key = @openstack_compute_url_header || \
                           'X-Server-Management-Url'
              @openstack_compute_service_url = response.headers[header_key]
            end
          end
          uri = URI.parse(@openstack_compute_service_url)
          expected_version = uri.path.split('/').reject(&:empty?).last.\
                                 match(/(\d+\.\d+)/)[1]
          unless @openstack_compute_api_version
            @openstack_compute_api_version = expected_version
          end
          if @openstack_compute_api_version != expected_version
            # fix the url
            parts = uri.split('/')
            parts[parts.length - 1] = "v#{@openstack_compute_api_version}"
            uri.path = parts.join('/')
            @openstack_compute_service_url = uri.to_s
          end
        end
      end # real
    end # openstack

    class OpenStack_1_0 < Fog::Service
      model_path 'fog/compute/models/openstack/openstack_1_0'
      model       :flavor
      collection  :flavors
      model       :image
      collection  :images
      model       :server
      collection  :servers

      request_path 'fog/compute/requests/openstack/openstack_1_0'
      request :confirm_resized_server
      request :create_image
      request :create_server
      request :delete_image
      request :delete_server
      request :get_flavor_details
      request :get_image_details
      request :get_server_details
      request :list_addresses
      request :list_private_addresses
      request :list_public_addresses
      request :list_flavors
      request :list_flavors_detail
      request :list_images
      request :list_images_detail
      request :list_servers
      request :list_servers_detail
      request :reboot_server
      request :revert_resized_server
      request :resize_server
      request :server_action
      request :update_server

      def self.supports_extensions? ; false ; end

      class Mock ; end
      class Real
        def initialize options={}
          @requestor = options[:requestor]
        end

        def request params
          @requestor.request params
        end

      end
    end # 1.0

    class OpenStack_1_1 < Fog::Service
      model_path 'fog/compute/models/openstack/openstack_1_1'
      model       :flavor
      collection  :flavors
      model       :image
      collection  :images
      model       :server
      collection  :servers
      model       :extension
      collection  :extensions

      request_path 'fog/compute/requests/openstack/openstack_1_1'
      request :confirm_resized_server
      request :create_image
      request :create_server
      request :delete_image
      request :delete_server
      request :get_flavor_details
      request :get_image_details
      request :get_server_details
      request :list_addresses
      request :list_private_addresses
      request :list_public_addresses
      request :list_flavors
      request :list_flavors_detail
      request :list_images
      request :list_images_detail
      request :list_servers
      request :list_servers_detail
      request :reboot_server
      request :revert_resized_server
      request :resize_server
      request :server_action
      request :update_server
      request :list_extensions

      # move these to core/service.rb?

      def self.extension_path pth
        @extension_path = pth
        @supports_extensions = true
      end
      extension_path 'fog/compute/extensions/openstack'

      def self.supports_extensions?
        @supports_extensions
      end

      def self.load_extension name
        begin
          require "#{@extension_path}/#{name.downcase.gsub('-', '_')}"
        rescue LoadError
          # simply not supported, don't error out
          nil
        end
      end

      class Mock ; end
      class Real
        def initialize options={}
          @requestor = options[:requestor]
          load_extensions
        end

        def request params
          @requestor.request params
        end

        private

        def load_extensions
          list_extensions.body['extensions'].each do |ext|
            service.load_extension(ext['alias'])
          end
        end
      end
    end # 1.1

    # This is a version independent service that handles extensions.
    class OpenStackExtensions < Fog::Service
      class Mock ; end
      class Real
        def initialize options={}
          @requestor = options[:requestor]
        end

        def request params
          @requestor.request params
        end
      end
    end

  end # compute
end # fog
