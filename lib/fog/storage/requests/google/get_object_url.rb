module Fog
  module Storage
    class Google
      class Real

        # Get an expiring object url from Google Storage
        #
        # ==== Parameters
        # * bucket_name<~String> - Name of bucket containing object
        # * object_name<~String> - Name of object to get expiring url for
        # * expires<~Time> - An expiry time for this url
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~String> - url for object
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AmazonS3/latest/dev/S3_QSAuth.html

        def get_object_url(bucket_name, object_name, expires)
          Formatador.display_line("[yellow][WARN] Fog::Storage::Google => ##{get_object_url} is deprecated, use ##{get_object_https_url} instead[/] [light_black](#{caller.first})[/]")
          get_object_https_url(bucket_name, object_name, expires)
        end

      end

      class Mock # :nodoc:all

        def get_object_url(bucket_name, object_name, expires)
          Formatador.display_line("[yellow][WARN] Fog::Storage::Google => ##{get_object_url} is deprecated, use ##{get_object_https_url} instead[/] [light_black](#{caller.first})[/]")
          get_object_https_url(bucket_name, object_name, expires)
        end

      end
    end
  end
end
