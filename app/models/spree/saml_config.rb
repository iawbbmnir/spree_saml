class Spree::SamlConfig < ActiveRecord::Base
  attr_accessible :assertion_consumer_service_url, :assertion_consumer_service_binding, :single_logout_service_url, :single_logout_service_binding, :idp_metadata, :idp_metadata_ttl, :name_identifier_format, :issuer, :authn_context, :idp_cert, :idp_cert_fingerprint, :idp_sso_target_url, :host, :is_active

  def self.active_providers
    return Spree::SamlConfig.where(:is_active => true)
  end
end

