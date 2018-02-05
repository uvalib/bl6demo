# lib/blacklight_advanced_search/advanced_search_builder_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

require 'parslet'
require 'parsing_nesting/tree'

module BlacklightAdvancedSearch

  # BlacklightAdvancedSearch::AdvancedSearchBuilderExt
  #
  # @see BlacklightAdvancedSearch::AdvancedSearchBuilder
  #
  module AdvancedSearchBuilderExt # TODO: Remove if not needed

    include BlacklightAdvancedSearch::AdvancedSearchBuilder
    include LensHelper

    # =========================================================================
    # :section:
    # =========================================================================

    public

    SB_ADV_SEARCH_FILTERS = %i(
      add_advanced_parse_q_to_solr
      add_advanced_search_to_solr
    )

    # =========================================================================
    # :section: BlacklightAdvancedSearch::AdvancedSearchBuilder overrides
    # =========================================================================

    public

=begin # NOTE: using base version
    # is_advanced_search?
    #
    # This method overrides:
    # @see BlacklightAdvancedSearch::AdvancedSearchBuilder#is_advanced_search?
    #
    def is_advanced_search?
      p = blacklight_params
      a = blacklight_config.advanced_search
      p[:f_inclusive] || (a && (p[:search_field] == a[:url_key]))
    end
=end

=begin # NOTE: using base version
    # This method should get added into the processor chain in a position AFTER
    # normal query handling (:add_query_to_solr), so it'll overwrite that if
    # and only if it's an advanced search.
    #
    # Adds a 'q' and 'fq's based on advanced search form input.
    #
    # @param [Hash] solr_parameters
    #
    # @return [void]
    #
    # This method overrides:
    # @see BlacklightAdvancedSearch::AdvancedSearchBuilder#add_advanced_search_to_solr
    #
    def add_advanced_search_to_solr(solr_parameters)
      # If we've got the hint that we're doing an 'advanced' search, then map
      # that to Solr #q, overriding whatever some other logic may have set,
      # yeah.  The hint right now is :search_field request param is set to a
      # magic key. OR of :f_inclusive is set for advanced params, we need
      # processing too.
      return unless is_advanced_search?
      # Set this as a controller instance variable, not sure if some
      # views/helpers depend on it. Better to leave it as a local variable
      # if not, more investigation later.
      advanced_query =
        BlacklightAdvancedSearch::QueryParserExt.new(
          blacklight_params,
          blacklight_config
        )
      BlacklightAdvancedSearch.deep_merge!(
        solr_parameters,
        advanced_query.to_solr
      )
      # Force :qt if set, fine if it's nil, we'll use whatever
      # CatalogController ordinarily uses.
      if advanced_query.keyword_queries.present?
        solr_parameters[:qt]      = blacklight_config.advanced_search[:qt]
        solr_parameters[:defType] = 'lucene'
      end
    end
=end

=begin # NOTE: using base version
    # Different versions of Parslet raise different exception classes,
    # need to figure out which one exists to rescue
    PARSLET_FAILED_EXCEPTIONS =
      if defined?(Parslet::UnconsumedInput)
       [Parslet::UnconsumedInput].freeze
      else
       [Parslet::ParseFailed].freeze
      end
=end

=begin # NOTE: using base version
    # This method can be included in the SearchBuilder to have us parse an
    # ordinary entered :q for AND/OR/NOT and produce appropriate Solr query.
    #
    # Note: For syntactically invalid input, we'll just skip the adv parse and
    # send it straight to Solr same as if advanced_parse_q were not being used.
    #
    # @param [Hash] solr_parameters
    #
    # @return [void]
    #
    # This method overrides:
    # @see BlacklightAdvancedSearch::AdvancedSearchBuilder#add_advanced_parse_q_to_solr
    #
    def add_advanced_parse_q_to_solr(solr_parameters)
      q = blacklight_params[:q]
      return unless q.present? && q.respond_to?(:to_str)

      sf = blacklight_params[:search_field]
      field_def = blacklight_config.search_fields[sf] || default_search_field

      # If the individual field has advanced_parse_q suppressed, punt.
      return if field_def[:advanced_parse].is_a?(FalseClass)

      solr_direct_params = field_def[:solr_parameters] || {}
      solr_local_params  = field_def[:solr_local_parameters] || {}

      # See if we can parse it, if we can't, we're going to give up and just
      # allow basic search, perhaps with a warning.
      begin
        adv_search_params =
          ParsingNesting::Tree.parse(
            q,
            blacklight_config.advanced_search[:query_parser]
          ).to_single_query_params(solr_local_params)
        BlacklightAdvancedSearch.deep_merge!(solr_parameters, solr_direct_params)
        BlacklightAdvancedSearch.deep_merge!(solr_parameters, adv_search_params)
      rescue *PARSLET_FAILED_EXCEPTIONS => e
        # Do nothing, don't merge our input in, keep basic search optional.
        # TODO, display error message in flash here, but hard to display a good one.
        return
      end
    end
=end

=begin # NOTE: using base version
    # A Solr param filter that is NOT included by default in the chain, but is
    # appended by AdvancedController#index, to do a search for facets
    # _ignoring_ the current query, we want the facets as if the current query
    # weren't there.
    #
    # Also adds any Solr params set in
    # blacklight_config.advanced_search[:form_solr_parameters]
    #
    # @param [Hash] solr_p
    #
    # @return [void]
    #
    # This method overrides:
    # @see BlacklightAdvancedSearch::AdvancedSearchBuilder#facets_for_advanced_search_form
    #
    def facets_for_advanced_search_form(solr_p)
      # Ensure empty query is all records, to fetch available facets on entire
      # corpus.
      solr_p['q'] = '{!lucene}*:*'

      # We only care about facets, we don't need any rows.
      solr_p['rows'] = '0'

      # Anything set in config as a literal
      fsp = blacklight_config.advanced_search[:form_solr_parameters]
      solr_p.merge!(fsp) if fsp
    end
=end

  end

end

__loading_end(__FILE__)
