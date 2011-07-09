require 'fog/core/model'

module Fog
  module Compute
    class OpenStack_1_1

      class Extension < Fog::Model

        identity :alias

        attribute :name
        attribute :namespace
        attribute :description
        attribute :updated, :type => :time
        attribute :links, :type => :array
      end

    end
  end
end
