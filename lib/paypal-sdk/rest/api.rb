module PayPal
  module SDK
    module REST
      class API < Core::API::REST
        def initialize(environment = nil, options = {})
          super('', environment, options)
        end

        class << self
          def user_agent
            @user_agent ||= "PayPalSDK/rest-sdk-ruby #{VERSION} (#{sdk_library_details})"
          end
        end

      end
    end
  end
end

