Spree::UserRegistrationsController.class_eval do

  after_filter :clear_omniauth, :only => :create

  private

  def build_resource(*args)
    super

    if @user.nil?
	@user = @spree_user
    end

    if session[:omniauth]
      if session[:omniauth]['provider'] == 'saml'
          session[:omniauth]['uid'] = session[:omniauth]['info']['name']
      end
      @user.apply_omniauth(session[:omniauth])
    end
    @user
  end

  def clear_omniauth
    session[:omniauth] = nil unless @user.new_record?
  end
end
