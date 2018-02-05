# app/controllers/concerns/blacklight/controller_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Filters added to this controller apply to all controllers in the
# hosting application as this module is mixed-in to the application controller
# in the hosting app on installation.
#
# @see Blacklight::Controller
#
module Blacklight::ControllerExt

  extend ActiveSupport::Concern
=begin # NOTE: using base version
  extend Deprecation
=end

  include Blacklight::Controller

=begin # NOTE: using base version
  self.deprecation_horizon = 'blacklight 7.x'
=end

  # Code to be added to the controller class including this module.
  included do |base|

    __included(base, 'Blacklight::ControllerExt')

    include LensConcern

=begin # NOTE: using base version
    include Blacklight::SearchFields
    helper Blacklight::SearchFields
=end
=begin # NOTE: using base version
    include ActiveSupport::Callbacks
=end

=begin # NOTE: using base version
    # now in application.rb file under config.filter_parameters
    # filter_parameter_logging :password, :password_confirmation
    helper_method :current_user_session, :current_user, :current_or_guest_user
=end
=begin # NOTE: using base version
    after_action :discard_flash_if_xhr
=end

=begin # NOTE: using base version
    # handle basic authorization exception with #access_denied
    rescue_from Blacklight::Exceptions::AccessDenied, :with => :access_denied
=end

=begin # NOTE: using base version
    # extra head content
    helper_method :has_user_authentication_provider?
    helper_method :blacklight_config, :blacklight_configuration_context
    helper_method :search_action_url, :search_action_path, :search_facet_url, :search_facet_path
    helper_method :search_state
=end

=begin # NOTE: using base version
    # Specify which class to use for the search state. You can subclass SearchState if you
    # want to override any of the methods (e.g. SearchState#url_for_document)
    class_attribute :search_state_class
=end
    self.search_state_class = Blacklight::SearchStateExt

=begin # NOTE: using base version
    # This callback runs when a user first logs in
    define_callbacks :logging_in_user
    set_callback :logging_in_user, :before, :transfer_guest_user_actions_to_current_user
=end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  module ClassMethods

    # _prefixes
    #
    # @return [Array<String>]
    #
    # This method overrides:
    # @see ActionView::ViewPaths::ClassMethods#_prefixes
    #
    def _prefixes # :nodoc:
      @_prefixes ||=
        begin
          return local_prefixes if superclass.abstract?
          (local_prefixes +
            [Blacklight::Lens.default_key.to_s] +
            superclass._prefixes).uniq
        end
    end

  end

  # ===========================================================================
  # :section: Blacklight::Controller overrides
  # ===========================================================================

  public

=begin # NOTE: using base version
  # default_catalog_controller
  #
  # @return [ApplicationController]
  #
  # This method overrides:
  # @see Blacklight::Controller#default_catalog_controller
  #
  def default_catalog_controller
    CatalogController
  end
=end

=begin # NOTE: overriding base version (see #blacklight_config below)
  delegate :blacklight_config, to: :default_catalog_controller
=end

  # Undo the delegation of :blacklight_config to :default_catalog_controller
  # that is performed by Blacklight::Controller.
  #
  # This uses the same signature as the one generated by #delegate.
  #
  # NOTE: 0% coverage for this method
  #
  def blacklight_config(*args, &block)
    blacklight_config_for(args.first)
  end

  # ===========================================================================
  # :section: Blacklight::Controller overrides
  # ===========================================================================

  protected

=begin # NOTE: using base version
  # Context in which to evaluate Blacklight configuration conditionals.
  #
  # @return [Blacklight::Configuration::Context]
  #
  # This method overrides:
  # @see Blacklight::Controller#blacklight_configuration_context
  #
  def blacklight_configuration_context(*) # Ignoring lens arg.
    @blacklight_configuration_context ||=
      Blacklight::Configuration::Context.new(self)
  end
=end

=begin # NOTE: using base version
  # Indicate whether to render the bookmarks control.
  #
  # (Needs to be available globally, as it is used in the navbar.)
  #
  # This method overrides:
  # @see Blacklight::Controller#render_bookmarks_control?
  #
  def render_bookmarks_control?
    current_or_guest_user.present?
  end
=end

=begin # NOTE: using base version
  # Indicate whether to render the saved searches link.
  #
  # (Needs to be available globally, as it is used in the navbar.)
  #
  # This method overrides:
  # @see Blacklight::Controller#render_saved_searches?
  #
  def render_saved_searches?
    current_user.present?
  end
=end

  # A memo-ized instance of the parameter state.
  #
  # @return [Blacklight::SearchStateExt]
  #
  # This method overrides:
  # @see Blacklight::Controller#search_state
  #
  def search_state
    @search_state ||=
      if (ssa = search_state_class.instance_method(:initialize).arity) == -3
        search_state_class.new(params, blacklight_config, self)
      elsif ssa != -2
        ss = search_state_class.new
        methods = ss.methods - ss.class.ancestors[1..-1].flat_map(&:methods).uniq
        raise "search_state_class arity #{ssa} [#{search_state_class}]; methods #{methods}"
      else
        Deprecation.warn(search_state_class,
          "The constructor for #{search_state_class} now requires a third " \
          'argument. Invoking it with 2 arguments is deprecated and will be ' \
          'removed in Blacklight 7.'
        )
        search_state_class.new(params, blacklight_config)
      end
  end

=begin # NOTE: using base version
  # Default route to the search action (used e.g. in global partials).
  #
  # Override this method in a controller or in your ApplicationController to
  # introduce custom logic for choosing which action the search form should use
  #
  # @param [Hash] options
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::Controller#search_action_url
  #
  def search_action_url(options = {})
    # Rails 4.2 deprecated url helpers accepting string keys for
    # 'controller' or 'action'.
    search_catalog_url(options.except(:controller, :action))
  end
=end

=begin # NOTE: using base version
  # search_action_path
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::Controller#search_action_path
  #
  def search_action_path(*args)
    opt =
      if args.last.is_a?(Hash)
        args[-1] = args.last.dup
      else
        args.push({}) && args[-1]
      end
    opt[:only_path] = true
    search_action_url(*args)
  end
=end

  # search_facet_url
  #
  # @param [Hash] options
  #
  # @return [String]
  #
  # @deprecated Use self#search_facet_path
  #
  # This method overrides:
  # @see Blacklight::Controller#search_facet_url
  #
  # NOTE: 0% coverage for this method
  #
  def search_facet_url(options = nil)
    opt = { only_path: false }
    opt.merge!(options) if options.present?
    search_facet_path(opt)
  end
  deprecate(search_facet_url: 'Use search_facet_path instead.')

  # This overrides the Blacklight method only to silence deprecation warnings.
  #
  # @param [Hash] options
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::Controller#search_facet_path
  #
  def search_facet_path(options = nil)
    opt = search_state.to_h.merge(only_path: true)
    opt.merge!(options) if options.present?
    opt.merge!(controller: current_lens_key, action: 'facet')
    opt.except!(:page)
    url_for(opt)
  end

=begin # NOTE: using base version
  # Returns a list of searches from the ids in the user's history.
  #
  # @return [Array<Search>]
  #
  # This method overrides:
  # @see Blacklight::Controller#searches_from_history
  #
  def searches_from_history
    hids = session[:history]
    if hids.blank?
      Search.none
    else
      Search.where(id: hids).order('updated_at desc')
    end
  end
=end

=begin # NOTE: using base version
  # Should be provided by authentication provider
  # def current_user
  # end
  # def current_or_guest_user
  # end

  # Here's a stub implementation we'll add if it isn't provided for us
  def current_or_guest_user
    if defined?(super)
      super
    elsif has_user_authentication_provider?
      current_user
    end
  end
  alias blacklight_current_or_guest_user current_or_guest_user
=end

=begin # NOTE: using base version
  # We discard flash messages generated by the xhr requests to avoid
  # confusing UX.
  #
  # This method overrides:
  # @see Blacklight::Controller#discard_flash_if_xhr
  #
  def discard_flash_if_xhr
    flash.discard if request.xhr?
  end
=end

=begin # NOTE: using base version
  # has_user_authentication_provider?
  #
  # This method overrides:
  # @see Blacklight::Controller#has_user_authentication_provider?
  #
  def has_user_authentication_provider?
    respond_to?(:current_user)
  end
=end

=begin # NOTE: using base version
  # require_user_authentication_provider
  #
  # @raise [ActionController::RoutingError]
  #
  # @return [void]
  #
  # This method overrides:
  # @see Blacklight::Controller#require_user_authentication_provider
  #
  def require_user_authentication_provider
    return if has_user_authentication_provider?
    raise ActionController::RoutingError, 'Not Found'
  end
=end

=begin # NOTE: using base version
  # When a user logs in, transfer any saved searches or bookmarks to the
  # current_user.
  #
  # @return [void]
  #
  # This method overrides:
  # @see Blacklight::Controller#transfer_guest_user_actions_to_current_user
  #
  def transfer_guest_user_actions_to_current_user
    return unless respond_to?(:current_user) && current_user
    return unless respond_to?(:guest_user)   && guest_user
    current_user_searches  = current_user.searches.pluck(:query_params)
    current_user_bookmarks = current_user.bookmarks.pluck(:document_id)

    searches =
      guest_user.searches.reject do |s|
        current_user_searches.include?(s.query_params)
      end
    searches.each do |s|
      current_user.searches << s
      s.save!
    end

    bookmarks =
      guest_user.bookmarks.reject do |b|
        current_user_bookmarks.include?(b.document_id)
      end
    bookmarks.each do |b|
      current_user.bookmarks << b
      b.save!
    end

    # Let guest_user know we've moved some bookmarks from under it.
    guest_user.reload if guest_user.persisted?
  end
=end

=begin # NOTE: using base version
  # To handle failed authorization attempts, redirect the user to the login
  # form and persist the current request URI as a parameter.
  #
  def access_denied
    # Send the user home if the access was previously denied by the same
    # request to avoid sending the user back to the login page
    #   (e.g. protected page -> logout -> returned to protected page -> home)
    if request&.referer&.end_with?(request.fullpath)
      redirect_to root_url
      flash.discard
    elsif !has_user_authentication_provider?
      redirect_to root_url
    else
      redirect_to new_user_session_url(referer: request.fullpath)
    end
  end
=end

end

__loading_end(__FILE__)
