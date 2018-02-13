# app/controllers/concerns/eds_concern.rb
#
# encoding:              utf-8
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/eds'

# Common concerns of controllers that work with articles (EdsDocument).
#
module EdsConcern

  extend ActiveSupport::Concern

  include Blacklight::Eds::BaseEds

  # Code to be added to the controller class including this module.
  included do |base|

    __included(base, 'EdsConcern')

    include RescueConcern
    include LensConcern

    # =========================================================================
    # :section: Helpers
    # =========================================================================

    helper_method :default_catalog_controller if defined?(helper_method)

    # =========================================================================
    # :section: Controller exception handling
    # =========================================================================

    # Connection errors cause a return to the home page.
    rescue_from *[
      EBSCO::EDS::ConnectionFailed,
      EBSCO::EDS::ServiceUnavailable,
    ], with: :handle_connect_error

    # Handle EBSCO EDS communication failures.
    rescue_from EBSCO::EDS::Error, with: :handle_ebsco_eds_error

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The default controller for searches.
  #
  # @return [Class]
  #
  def default_catalog_controller
    ArticlesController
  end

  # ===========================================================================
  # :section: Exception handlers
  # ===========================================================================

  protected

  # Handle EBSCO EDS communication failures (EBSCO::EDS::Error).
  #
  # @param [Exception] exception
  #
  # @see http://edswiki.ebscohost.com/API_Reference_Guide:_Error_Codes
  # @see http://edswiki.ebscohost.com/API_Reference_Guide:_Authentication_Error_Codes
  # @see https://help.ebsco.com/interfaces/EBSCOhost/EBSCOhost_FAQs/error_message_when_log_in_to_EBSCOhost
  #
  # NOTE: 0% coverage for this method
  #
  def handle_ebsco_eds_error(exception)

    # Extract EBSCO fault information.
    fault = (exception.fault    if exception.respond_to?(:fault))
    fault = (fault[:error_body] if fault.is_a?(Hash)) || {}

    # Get error values.
    details = fault['AdditionalDetail'] || fault['DetailedErrorDescription']
    code    = fault['ErrorCode']        || fault['ErrorNumber']
    message = fault['Reason']           || fault['ErrorDescription']
    unless message
      message = exception.message.presence
      message = message ? message.demodulize : 'unknown error'
    end
    if details.present?
      message = message.chomp('.') << +' (' << details.chomp('.') << ')'
    end
    message = I18n.t('blacklight.search.errors.ebsco_eds', error: message)

    # Act based on the type of error.
    case code.to_i
      when 101, 102, 103, 104, 105, 113, 130, 131, 132, 133, 134, 135,
        1100, 1103
        # TODO: Determine whether this is correct for all of these error codes
        logger.debug("[ignore] #{exception.class}: #{exception.message}")
        flash[:notice] = 'Please sign on to complete this article search.'
        redirect_to articles_home_path
      when 106
        # EBSCO::EDS::BadRequest
        # "Unknown error encountered"
        logger.warn("#{exception.class}: #{exception.message}")
        flash[:notice] = "Article search provider reports: #{message}"
        redirect_to articles_home_path
      when 107
        logger.error("#{exception.class}: #{exception.message}")
        flash[:notice] =
          'Your IP address has been blocked from making article searches. ' \
          'Please contact a librarian.'
        redirect_to articles_home_path
      when 109
        # EBSCO::EDS::BadRequest
        # "Session Token Invalid"
        logger.debug("[ignore] #{exception.class}: #{exception.message}")
      when 114
        # EBSCO::EDS::BadRequest
        # "Retrieval Request AN must contain a valid value."
        logger.warn("#{exception.class}: #{exception.message}")
        flash.now[:notice] = message
      when 1102
        logger.debug("[ignore] #{exception.class}: #{exception.message}")
        flash[:notice] = message
        redirect_to articles_home_path
      else
        logger.error("#{exception.class}: #{exception.message}")
        flash[:notice] = message
        redirect_to articles_home_path
    end
  end

end

__loading_end(__FILE__)
