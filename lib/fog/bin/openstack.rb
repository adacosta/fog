class OpenStack < Fog::Bin
  class << self

    def class_for(key)
      case key
      when :compute
        Fog::Compute::Rackspace
      else 
        raise ArgumentError, "Unrecognized service: #{key}"
      end
    end

    def [](service)
      @@connections ||= Hash.new do |hash, key|
        hash[key] = case key
        when :compute
          Formatador.display_line("[yellow][WARN] OpenStack[:compute] is deprecated, use Compute[:openstack] instead[/]")
          Fog::Compute.new(:provider => 'OpenStack')
        else
          raise ArgumentError, "Unrecognized service: #{key.inspect}"
        end
      end
      @@connections[service]
    end

    def services
      Fog::OpenStack.services
    end

  end
end
