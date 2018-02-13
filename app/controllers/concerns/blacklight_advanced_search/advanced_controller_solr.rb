# app/controllers/concerns/blacklight_advanced_search/advanced_controller_solr.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Need to sub-class CatalogController so we get all other plugins behavior
# for our own "inside a search context" lookup of facets.
#
# Used in place of:
# @see BlacklightAdvancedSearch::AdvancedController
#
class BlacklightAdvancedSearch::AdvancedControllerSolr < CatalogController

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Ensure that 'advanced' is searched first for templates.
  #
  # @return [Array<String>]
  #
  # This method overrides:
  # @see ActionView::ViewPaths::ClassMethods#local_prefixes
  #
  def self.local_prefixes
    super.unshift('advanced').uniq
  end

  # ===========================================================================
  # :section: BlacklightAdvancedSearch::AdvancedController replacements
  # ===========================================================================

  public

  # == GET /catalog/advanced
  #
  # TODO: Do a clean search to get total facet values THEN render to check boxes
  #
  # This method overrides:
  # @see Blacklight::CatalogExt#index
  #
  # Compare with:
  # @see BlacklightAdvancedSearch::AdvancedController#index
  #
  def index
    @response = get_advanced_search_facets unless request.method == :post
  end

  # ===========================================================================
  # :section: BlacklightAdvancedSearch::AdvancedController replacements
  # ===========================================================================

  protected

=begin # NOTE: moved to CatalogExt
  # Override to use the engine routes
  #
  # @param [Hash] options
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::CatalogExt#search_action_url
  #
  # Compare with:
  # @see BlacklightAdvancedSearch::AdvancedController#search_action_url
  #
  def search_action_url(options = nil)
    opt = { controller: current_lens_key, action: 'index' }
    opt.reverse_merge!(options) if options.is_a?(Hash)
    url_for(opt)
  end
=end

  # get_advanced_search_facets
  #
  # We want to find the facets available for the current search, but:
  # * IGNORING current query (add in :facets_for_advanced_search_form filter)
  # * IGNORING current advanced search facets (remove :add_advanced_search_to_solr filter)
  #
  # @return [Blacklight::Solr::Response]
  #
  # Compare with:
  # @see BlacklightAdvancedSearch::AdvancedController#get_advanced_search_facets
  #
  def get_advanced_search_facets
    response, _ =
      search_results(params) do |search_builder|
        search_builder
          .except(:add_advanced_search_to_solr)
          .append(:facets_for_advanced_search_form)
      end
    response
  end

end

__loading_end(__FILE__)
