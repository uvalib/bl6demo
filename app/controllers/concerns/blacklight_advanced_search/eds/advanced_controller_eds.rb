# app/controllers/concerns/blacklight_advanced_search/eds/advanced_controller_eds.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/eds'

module BlacklightAdvancedSearch
  module Eds
  end
end

# Need to sub-class ArticlesController so we get all other plugins behavior
# for our own "inside a search context" lookup of facets.
#
# Used in place of:
# @see BlacklightAdvancedSearch::AdvancedController
#
class BlacklightAdvancedSearch::Eds::AdvancedControllerEds < ArticlesController

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

  # == GET /articles/advanced
  #
  # This method overrides:
  # @see Blacklight::Eds::CatalogEds#index
  #
  # Compare with:
  # @see BlacklightAdvancedSearch::AdvancedControllerSolr#index
  #
  # TODO: Do a clean search to get total facet values THEN render to check boxes
  #
  def index
    $stderr.puts '}}}}}}}}}}}}}}}}}}}}}}}} articles advanced index' # TODO: debugging - remove
    @response = get_advanced_search_facets unless request.method == :post
  end

  # ===========================================================================
  # :section: BlacklightAdvancedSearch::AdvancedController replacements
  # ===========================================================================

  protected

=begin # NOTE: using base version
  # Override to use the engine routes
  #
  # @param [Hash] options
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::Eds::CatalogEds#search_action_url
  #
  # Compare with:
  # @see BlacklightAdvancedSearch::AdvancedControllerSolr#search_action_url
  #
  def search_action_url(options = nil)
    opt = { controller: current_lens_key, action: 'index' }
    opt.reverse_merge!(options) if options.is_a?(Hash)
    url_for(opt)
  end
=end

  # get_advanced_search_facets
  #
  # @return [Blacklight::Solr::Response]
  #
  # Compare with:
  # @see BlacklightAdvancedSearch::AdvancedControllerSolr#get_advanced_search_facets
  #
  # TODO: Should there be EDS-specific versions of :add_advanced_search_to_solr and/or :facets_for_advanced_search_form?
  #
  def get_advanced_search_facets
    # We want to find the facets available for the current search, but:
    # * IGNORING current query (add in facets_for_advanced_search_form filter)
    # * IGNORING current advanced search facets (remove add_advanced_search_to_solr filter)
    response, _ =
      search_results do |search_builder|
        search_builder
          .except(:add_advanced_search_to_solr)
          .append(:facets_for_advanced_search_form)
      end
    response
  end

end

__loading_end(__FILE__)
