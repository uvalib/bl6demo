# app/controllers/concerns/rescue_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

module RescueConcern

  extend ActiveSupport::Concern

  # Code to be added to the controller class including this module.
  included do |base|

    __included(base, 'RescueConcern')

    # =========================================================================
    # :section: Controller exception handling
    # =========================================================================

    public

    rescue_from *[
      Errno::ECONNABORTED,
      Errno::ECONNREFUSED,
      Errno::ECONNRESET,
      Errno::EHOSTDOWN,
      Errno::EHOSTUNREACH,
      Errno::ENETDOWN,
      Errno::ENETRESET,
      Errno::ENETUNREACH,
      Faraday::ConnectionFailed,
    ], with: :handle_connect_error

    # The index action will more than likely throw this one.
    # Example: when the standard query parser is used, and a user submits a
    # "bad" query.
    rescue_from *[
      Blacklight::Exceptions::InvalidRequest
    ], with: :handle_request_error

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Redirect back.
  #
  # @param [Array] *args
  # - [String, Hash] msg
  # - [String]       fallback_path
  #
  def go_back(*args)
    opt = args.last.is_a?(Hash) ? args.pop.dup : {}
    msg = args.shift
    opt[:error] = msg if msg
    fallback_path = opt.delete(:fallback)
    fallback_path = opt.delete(:fallback_location) || fallback_path
    fallback_path = args.shift || fallback_path || root_path
    if respond_to?(:redirect_back)
      redirect_back opt.reverse_merge(fallback_location: fallback_path)
    else # Deprecated in Rails 5.0
      redirect_to :back, opt
    end
  end

  # ===========================================================================
  # :section: Exception handlers
  # ===========================================================================

  protected

  # This method is executed when there is a problem communicating with an
  # external service.
  #
  # @param [Exception]           exception
  # @param [String, Symbol, nil] i18n
  #
  # == Implementation Notes
  # Because the lens home pages send a request in order to fill the facet
  # selections, if a request fails due to failure to connect to a service then
  # there are only two safe choices:
  #
  #   1. Redirect to the lens main page
  #   2. Redirect to the home page
  #
  # The problem with either is that the landing page has to be able to avoid
  # attempting to fill facet selections by making a request to the failing
  # service.  Otherwise the page won't display so the user will never see the
  # flash message about the service failure.
  #
  # NOTE: 0% coverage for this method
  #
  def handle_connect_error(exception, i18n = nil)
    i18n ||= 'blacklight.search.errors.connect.general'
    flash_notice = I18n.t(i18n, error: exception.class)
    if flash[:notice] == flash_notice
      logger.error { "#{__method__} is looping" }
      raise exception
    else
      logger.error(exception)
      redirect_to root_path, notice: flash_notice
    end
  end

  # This method is executed when Blacklight::Exceptions::InvalidRequest has
  # been raised.
  #
  # @param [Exception]           exception
  # @param [String, Symbol, nil] i18n
  #
  # This method overrides:
  # @see Blacklight::Base#handle_request_error
  #
  # NOTE: 0% coverage for this method
  #
  def handle_request_error(exception, i18n = nil)
=begin
    # Rails own code will catch and give the usual Rails error page with stack
    # trace.
    raise exception if Rails.env.development? || Rails.env.test?
=end
    # If there are errors coming from the index page, we want to trap those
    # sensibly.
    i18n ||= 'blacklight.search.errors.request_error'
    flash_notice = I18n.t(i18n)
    if flash[:notice] == flash_notice
      logger.error { "#{__method__} is looping" }
      raise exception
    else
      logger.error(exception)
      redirect_to search_action_path, notice: flash_notice
    end
  end

end

__loading_end(__FILE__)
