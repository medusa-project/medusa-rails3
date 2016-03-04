class ApplicationController < ActionController::Base
  protect_from_forgery
  helper_method :current_user, :medusa_user?, :public_path, :public_view_on?

  protected

  def set_current_user(user)
    @current_user = user
    session[:current_user_id] = user.id
  end

  def unset_current_user
    @current_user = nil
    session[:current_user_id] = nil
  end

  def current_user
    @current_user || User.find_by(id: session[:current_user_id])
  end

  def current_user_uid
    current_user.uid
  end

  def medusa_user?
    logged_in? and self.class.is_ad_user?(current_user)
  end

  def require_medusa_user
    unless medusa_user?
      redirect_non_medusa_user
    end
  end

  def require_medusa_user_or_basic_auth
    unless medusa_user? or basic_auth?
      redirect_non_medusa_user
    end
  end

  def redirect_non_medusa_user
    if current_user
      redirect_to unauthorized_net_id_url(net_id: current_user.net_id)
    else
      redirect_non_logged_in_user
    end
  end

  def redirect_non_logged_in_user
    session[:login_return_uri] = request.env['REQUEST_URI']
    redirect_to(login_path)
  end

  def logged_in?
    current_user.present?
  end

  def require_logged_in
    redirect_non_logged_in_user unless logged_in?
  end

  def require_logged_in_or_basic_auth
    redirect_non_logged_in_user unless logged_in? or basic_auth?
  end

  def basic_auth?
    ActionController::HttpAuthentication::Basic.decode_credentials(request) == MedusaCollectionRegistry::Application.medusa_config['basic_auth']
  rescue
    false
  end

  rescue_from CanCan::AccessDenied do
    redirect_to unauthorized_path
  end

  def record_event(eventable, key, user = current_user)
    eventable.events.create(actor_email: user.email, key: key, date: Date.today)
  end

  def self.is_member_of?(group, user, domain = nil)
    domain ||= 'uofi'
    self.internal_is_member_of?(group, user.net_id, domain)
  end

  #We define this differently for production and development/test for convenience
  if Rails.env.production?
    def self.internal_is_member_of?(group, net_id, domain)
      LdapQuery.new.is_member_of?(group, net_id)
    end
  else
    #To make development/test easier
    #any net_id that matches admin is member of the ad_admin and ad_users
    #any net_id that matches user is a member only of ad_users
    #any net_id that matched manager is a member of ad_users and the managers group
    #any net_id that matches outsider or visitor is a member of no AD groups, but is logged in
    #otherwise member iff the part of the net_id preceding '@' (recall Omniauth dev mode uses email as uid)
    #includes the group when both are downcased and any spaces in the group converted to '-'
    def self.internal_is_member_of?(group, net_id, domain=nil)
      return false if group.blank?
      return true if net_id.match(/admin/) and (group == admin_ad_group or group == user_ad_group)
      return true if net_id.match(/manager/) and (group == user_ad_group or group.match(/manager/))
      return true if net_id.match(/user/) and group == user_ad_group
      return false if net_id.match(/user/) or net_id.match(/outsider/) or net_id.match(/visitor/)
      return net_id.split('@').first.downcase.match(group.downcase.gsub(' ', '-'))
    end
  end

  def self.is_ad_user?(user)
    user and self.is_member_of?(user_ad_group, user, 'uofi')
  end

  def self.is_ad_admin?(user)
    user and self.is_member_of?(admin_ad_group, user, 'uofi')
  end

  def self.user_ad_group
    MedusaCollectionRegistry::Application.medusa_config['medusa_users_group']
  end

  def self.admin_ad_group
    MedusaCollectionRegistry::Application.medusa_config['medusa_admins_group']
  end

  def public_path(object)
    class_name = object.class.to_s.underscore
    self.send("public_#{class_name}_path", object)
  end

  def public_view_on?
    MedusaCollectionRegistry::Application.medusa_config['public_view_on']
  end

  def public_view_enabled?
    redirect_to(unauthorized_path) unless public_view_on?
  end

  def reset_ldap_cache(user)
    user ||= current_user
    LdapQuery.reset_cache(user.net_id) if user.present?
  end

end
