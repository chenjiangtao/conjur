require 'uri'
require 'json'

module Authentication
  module AuthnOidc
    module AuthenticateIdToken

      Log = LogMessages::Authentication::AuthnOidc
      Err = Errors::Authentication::AuthnOidc
      # Possible Errors Raised:
      # ProviderDiscoveryTimeout, ProviderDiscoveryFailed, ProviderFetchCertificateFailed

      FetchProviderCertificate = CommandClass.new(
        dependencies: {
          logger: Rails.logger
        },
        inputs: %i(provider_uri)
      ) do

        def call
          @logger.debug(Log::OIDCProviderUri.new(@provider_uri).to_s)

          # provider discovery might throw exception. Let it propagate upward
          discover_provider
          fetch_certs
        end

        private

        def discover_provider
          @discovered_provider = OpenIDConnect::Discovery::Provider::Config.discover!(@provider_uri)

          @logger.debug(Log::OIDCProviderDiscoverySuccess.new.to_s)
        rescue HTTPClient::ConnectTimeoutError => e
          raise_error(Err::ProviderDiscoveryTimeout, e)
        rescue => e
          raise_error(Err::ProviderDiscoveryFailed, e)
        end

        def fetch_certs
          jwks = @discovered_provider.jwks
          @logger.debug(Log::FetchProviderCertsSuccess.new.to_s)
          jwks
        rescue => e
          raise_error(Err::ProviderFetchCertificateFailed, e)
        end

        def raise_error(error_class, original_error)
          raise error_class.new(@provider_uri, original_error.inspect)
        end
      end
    end
  end
end