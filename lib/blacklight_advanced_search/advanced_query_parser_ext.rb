# lib/blacklight_advanced_search/advanced_query_parser_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'
require 'blacklight_advanced_search/advanced_query_parser'

module BlacklightAdvancedSearch

  # Can extract query elements from rails #params query params, and then parse
  # them and convert them into a solr query with #to_solr
  #
  # #keyword_queries and #filters, which just return extracted elements of query
  # params, may also be useful in display etc.
  #
  # @see BlacklightAdvancedSearch::QueryParser
  #
  class QueryParserExt < BlacklightAdvancedSearch::QueryParser

=begin # NOTE: using base version
    include ParsingNestingParser # only one strategy currently supported. if BlacklightAdvancedSearch.config[:solr_type] == "parsing_nesting"
    include FilterParser
=end

    # =========================================================================
    # :section: BlacklightAdvancedSearch::QueryParser overrides
    # =========================================================================

    public

=begin # NOTE: using base version
    attr_reader :config, :params
=end

    # Initialize a self instance
    #
    # @param [ActionController::Parameters] params
    # @param [Blacklight::Configuration]    config
    #
    # This method overrides:
    # @see BlacklightAdvancedSearch::QueryParser#initialize
    #
    def initialize(params, config)
      @params = Blacklight::SearchStateExt.new(params, config).to_h
      @config = config
    end

=begin # NOTE: using base version
    # to_solr
    #
    # @return [Hash]
    #
    # This method overrides:
    # @see BlacklightAdvancedSearch::QueryParser#to_solr
    #
    def to_solr
      @to_solr ||= {
        q:  process_query(params, config),
        fq: generate_solr_fq
      }
    end
=end

=begin # NOTE: using base version
    # Returns "AND" or "OR", how #keyword_queries will be combined.
    #
    # @return [String]
    #
    # This method overrides:
    # @see BlacklightAdvancedSearch::QueryParser#keyword_op
    #
    def keyword_op
      @params['op'] || 'AND'
    end
=end

    # Extracts advanced-type keyword query elements from query params,
    # returns as a hash of field => query.
    #
    # @return [Hash]
    #
    # @see self#keyword_op
    #
    # This method overrides:
    # @see BlacklightAdvancedSearch::QueryParser#keyword_queries
    #
    def keyword_queries
      @keyword_queries ||=
        if @params[:search_field] == config.advanced_search[:url_key]
          config.search_fields.map { |key, _field_def|
            key = key.to_sym
            [key, @params[key]] if @params[key]
          }.compact.to_h
        else
          {}
        end
    end

    # Extracts advanced-type filters from query params,
    # returned as a hash of field => [array of values]
    #
    # @return [Hash]
    #
    # This method overrides:
    # @see BlacklightAdvancedSearch::QueryParser#filters
    #
    def filters
      @filters ||= @params[:f_inclusive]&.deep_dup || {}
    end

=begin # NOTE: using base version
    # filters_include_value?
    #
    # @param [String, Symbol] field
    # @param [String]         value
    #
    # This method overrides:
    # @see BlacklightAdvancedSearch::QueryParser#filters_include_value?
    #
    def filters_include_value?(field, value)
      filters[field.to_s].try { |array| array.include?(value) }
    end
=end

=begin # NOTE: using base version
    # empty?
    #
    # This method overrides:
    # @see BlacklightAdvancedSearch::QueryParser#empty?
    #
    def empty?
      filters.empty? && keyword_queries.empty?
    end
=end

  end

end

__loading_end(__FILE__)
