# lib/blacklight_advanced_search/controller_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

require 'blacklight_advanced_search/parsing_nesting_parser'

# This module gets included into CatalogController, or another SearchHelper
# includer, to add advanced search behavior.
#
# @see BlacklightAdvancedSearch::Controller
#
module BlacklightAdvancedSearch::ControllerExt

  extend ActiveSupport::Concern

  include BlacklightAdvancedSearch::Controller unless ONLY_FOR_DOCUMENTATION

  # Code to be added to the controller class including this module.
  included do |base|

    __included(base, 'BlacklightAdvancedSearch::ControllerExt')

    # =========================================================================
    # :section: Helpers
    # =========================================================================

    # Display advanced search constraints properly.
    helper BlacklightAdvancedSearch::RenderConstraintsOverrideExt
    helper BlacklightAdvancedSearch::CatalogHelperOverrideExt

    helper_method :is_advanced_search?, :advanced_query

  end

  # ===========================================================================
  # :section: BlacklightAdvancedSearch::Controller replacements
  # ===========================================================================

  public

  # is_advanced_search?
  #
  # @param [ActionController::Parameters, Hash, nil] req_params  Def: `params`.
  #
  # This method replaces:
  # @see BlacklightAdvancedSearch::Controller#is_advanced_search?
  #
  def is_advanced_search?(req_params = nil)
    p = req_params || params
    p[:f_inclusive].present? ||
      (p[:search_field] == blacklight_config.advanced_search[:url_key])
  end

  # advanced_query
  #
  # @param [ActionController::Parameters, Hash, nil] req_params  Def: `params`.
  #
  # @return [BlacklightAdvancedSearch::QueryParserExt, nil]
  #
  # This method replaces:
  # @see BlacklightAdvancedSearch::Controller#advanced_query
  #
  def advanced_query(req_params = nil)
    req_params ||= params
    return unless is_advanced_search?(req_params)
    BlacklightAdvancedSearch::QueryParserExt.new(req_params, blacklight_config)
  end

end

__loading_end(__FILE__)
