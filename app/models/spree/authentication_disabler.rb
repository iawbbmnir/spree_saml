class Spree::AuthenticationDisabler
  def self.login_disabled
    return false
  end

  def self.active_saml
    config = Spree::SamlConfig.where(:is_active => true).first
    if config.nil?
      return false
    else
      return true
    end
  end
end

