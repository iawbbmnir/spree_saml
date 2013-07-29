module SpreeSocial
  class Engine < Rails::Engine
    engine_name 'spree_social'

    config.autoload_paths += %W(#{config.root}/lib)

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), "../../app/**/*_decorator*.rb")) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    config.to_prepare &method(:activate).to_proc
  end

  def self.init_saml
    config = Spree::SamlConfig.where(:is_active => true).first

    if !config.nil?
      provider = "saml"
      assertion_consumer_service_url = config.assertion_consumer_service_url
      issuer = config.issuer
      idp_sso_target_url = config.idp_sso_target_url
      idp_cert = config.idp_cert.gsub(/\\n/, 10.chr)
      name_identifier_format = config.name_identifier_format
      self.setup_saml_config(provider, assertion_consumer_service_url, issuer, idp_sso_target_url, idp_cert, name_identifier_format)
    end 
 end

  def self.setup_saml_config(provider, acsu, i, istu, ic, nif)
    Devise.setup do |config|
      config.omniauth :saml,
		:assertion_consumer_service_url => acsu,
		:issuer => i,
		:idp_sso_target_url => istu,
		:idp_cert => ic,
		:name_identifier_format => nif
    end
  end
end

module OmniAuth
  module Strategies
  end
end
