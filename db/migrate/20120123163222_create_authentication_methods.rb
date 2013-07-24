class CreateAuthenticationMethods < ActiveRecord::Migration
  def change
    create_table :spree_authentication_methods do |t|
      t.string :environment
      t.string :provider
      t.string :api_key
      t.string :api_secret
      t.boolean :active

      t.timestamps
     end

    create_table :spree_authentication_saml do |t|
	t.string :issuer
	t.string :assertion_consumer_service_url
	t.string :idp_sso_target_url
	t.string :idp_cert
	t.string :idp_cert_fingerprint
	t.string :name_identifier_format

    end
  end
end
