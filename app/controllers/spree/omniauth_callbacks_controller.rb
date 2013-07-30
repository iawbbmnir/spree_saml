class Spree::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include Spree::Core::ControllerHelpers::Common
  include Spree::Core::ControllerHelpers::Order
  include Spree::Core::ControllerHelpers::Auth

  def self.provide_callback_for_saml
     def saml
          if request.env["omniauth.error"].present?
            flash[:error] = t("devise.omniauth_callbacks.failure", :kind => auth_hash['provider'], :reason => t(:user_was_not_valid))
            redirect_back_or_default(root_url)
            return
          end

          authentication = Spree::UserAuthentication.find_by_provider_and_uid(auth_hash['provider'], auth_hash['info']['name'])

	  if !authentication.nil?
	    user_address = Spree::User.where(:id => authentication.user_id)

            address_id = store_address(authentication.user_id,
  			auth_hash['extra']['raw_info']['first_name'], 
			auth_hash['extra']['raw_info']['last_name'], 
			auth_hash['extra']['raw_info']['telephone'], 
			auth_hash['extra']['raw_info']['address'])

            if !address_id.nil?
              change_id = "id = " + authentication.user_id.to_s
 	      update_ship_id = "ship_address_id = " + address_id.to_s
              update_bill_id = "bill_address_id = " + address_id.to_s	  
              Spree::User.update_all([update_ship_id], change_id)
	      Spree::User.update_all([update_bill_id], change_id)
            else
              #Address provided from SAML Assertion is invalid (eg. No city, No zipcode)
            end 
          end

	  auth_hash['uid'] = auth_hash['info']['name']

          if authentication.present?
            flash[:notice] = "Signed in successfully"
            sign_in_and_redirect :spree_user, authentication.user
          elsif spree_current_user
            spree_current_user.apply_omniauth(auth_hash)
            spree_current_user.save!
            flash[:notice] = "Authentication successful."
            redirect_back_or_default(account_url)
          else

            random_pw = (0...8).map{(65+rand(26)).chr}.join
            #puts "RandomPW: " + random_pw

            user = Spree::User.find_by_email(auth_hash['info']['email']) || (Spree::User.new email: auth_hash['info']['email'], password: random_pw)
            user.apply_omniauth(auth_hash)

            if user.save
              flash[:notice] = "Signed in successfully."
              sign_in_and_redirect :spree_user, user
            else
              session[:omniauth] = auth_hash
              flash[:notice] = Spree.t(:one_more_step, :kind => auth_hash['provider'].capitalize)
              redirect_to new_spree_user_registration_url               
            end
          end

          if current_order
            user = spree_current_user || authentication.user
            current_order.associate_user!(user)
            session[:guest_token] = nil
          end
        end
  end

  provide_callback_for_saml

  def failure
    set_flash_message :alert, :failure, :kind => failed_strategy.name.to_s.humanize, :reason => failure_message
    redirect_to spree.login_path
  end

  def passthru
    render :file => "#{Rails.root}/public/404", :formats => [:html], :status => 404, :layout => false
  end

  def auth_hash
    request.env["omniauth.auth"]
  end

  def store_address(user_auth_id, raw_firstname, raw_lastname, raw_telephone, raw_address)
    address = raw_address.split /,\s*/
 
    sai = "ship_address_id"
    checked_user = Spree::User.find(user_auth_id)    

    if checked_user.read_attribute(sai) == nil
       new_address = Spree::Address.new firstname: raw_firstname, lastname: raw_lastname, address1: address[0], address2: nil, city: address[1], zipcode: address[4], phone: raw_telephone, state_name: address[2], alternative_phone: nil, company: nil, state_id: 48, country_id: 49
       new_address.save
       return new_address.id      
    end

    old_address = Spree::Address.find(checked_user.read_attribute(sai))

    if raw_firstname == old_address.read_attribute("firstname") && raw_lastname == old_address.read_attribute("lastname") &&
       address[0] == old_address.read_attribute("address1") && address[1] == old_address.read_attribute("city") &&
       address[4] == old_address.read_attribute("zipcode")
       return old_address.read_attribute("id")
    end

    new_address = Spree::Address.new firstname: raw_firstname, lastname: raw_lastname, address1: address[0], address2: nil, city: address[1], zipcode: address[4], phone: raw_telephone, state_name: address[2], alternative_phone: nil, company: nil, state_id: 48, country_id: 49
    new_address.save
    return new_address.id
  end
end
