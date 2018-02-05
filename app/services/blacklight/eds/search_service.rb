# app/services/blacklight/eds/search_service.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/eds'

module Blacklight::Eds

  # Blacklight::Eds::SearchService
  #
  # Returns search results from EBSCO Discovery Service.
  #
  # @see Blacklight::Eds::SearchHelperEds
  #
  class SearchService

    include Blacklight::RequestBuilders

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # blacklight_config
    #
    # @return [Blacklight::Configuration]
    #
    # == Usage Notes
    # This is required by Blacklight::RequestBuilders
    #
    attr_reader :blacklight_config

    # initialize
    #
    # @param [Blacklight::Configuration] bl_config
    # @param [Hash]                      user_params
    # @param [Hash]                      eds_params
    #
    # @option eds_params [ActionDispatch::Request::Session] :session
    # @option eds_params [Boolean]                          :guest
    #
    def initialize(bl_config, user_params = nil, eds_params = nil)
      @blacklight_config = bl_config
      @user_params = user_params || {}
      @eds_params  = eds_params  || {}
      $stderr.puts("!!! SearchService blacklight_config #{bl_config.index_fields}") # TODO: debugging - remove
      repository_class =
        @blacklight_config.repository_class || Blacklight::Eds::Repository
      $stderr.puts("!!! SearchService repository_class #{repository_class}") # TODO: debugging - remove
      @repository = repository_class.new(@blacklight_config)
    end

    # =========================================================================
    # :section: Blacklight::SearchHelper replacements
    # =========================================================================

    public

    # Get results from the search service.
    #
    # @yield [search_builder]         Optional block yields configured
    #                                   SearchBuilder, caller can modify or
    #                                   create new SearchBuilder to be used.
    #                                   Block should return SearchBuilder to be
    #                                   used.
    #
    # @return [Array<(Blacklight::Solr::Response, Array<EdsDocument>)>]
    #
    # Compare with:
    # @see Blacklight::SearchHelper#search_results
    #
    def search_results
      page = @user_params[:page]
      rows = @user_params[:per_page] || @user_params[:rows]

      query = search_builder.with(@user_params)
      query.page = page if page
      query.rows = rows if rows
      query = yield(query) if block_given?

      response = @repository.search(query, @eds_params)
      if response.grouped? && grouped_key_for_results # NOTE: 0% coverage for this case
        return response.group(grouped_key_for_results), []
      elsif response.grouped? && response.grouped.length == 1 # NOTE: 0% coverage for this case
        return response.grouped.first, []
      else
        return response, response.documents
      end
    end

    # Retrieve a document, given the doc id.
    #
    # @param [String, Array<String>] id
    # @param [Hash]                  eds_params
    #
    # @return [Array<(Blacklight::Solr::Response, EdsDocument)>]
    # @return [Array<(Blacklight::Solr::Response, Array<EdsDocument>)>]
    #
    # Compare with:
    # @see Blacklight::SearchHelper#fetch
    #
    # NOTE: 0% coverage for this method
    #
    def fetch(id = nil, eds_params = nil)
      if id.is_a?(Array)
        fetch_many(id, nil, eds_params)
      else
        fetch_one(id, eds_params)
      end
    end

    # Get the search service response when retrieving only a single facet field.
    #
    # @param [String, Symbol] facet_field
    # @param [Hash]           req_params
    # @param [Hash]           eds_params
    #
    # @return [Blacklight::Solr::Response]
    #
    # Compare with:
    # @see Blacklight::SearchHelper#get_facet_field_response
    #
    # NOTE: 0% coverage for this method
    #
    def get_facet_field_response(facet_field, req_params = nil, eds_params = nil)
      query =
        search_builder
          .with(@user_params)
          .facet(facet_field)
          .merge(req_params || {})
      @repository.search(query, @eds_params.merge(eds_params || {}))
    end

    # Get the previous and next document from a search result.
    #
    # @param [Integer] index
    # @param [Hash]    req_params
    # @param [Hash]    user_params
    #
    # @return [Array<(Blacklight::Solr::Response, Array<EdsDocument>)>]
    #
    # Compare with:
    # @see Blacklight::SearchHelper#get_previous_and_next_documents_for_search
    #
    def get_previous_and_next_documents_for_search(index, req_params, user_params = nil)
      pagination_params = previous_and_next_document_params(index)
      start = pagination_params.delete(:start)
      rows  = pagination_params.delete(:rows)
      query =
        search_builder
          .with(req_params)
          .start(start)
          .rows(rows)
          .merge(user_params || {})
          .merge(pagination_params)
      # Add an EDS current page index for next-previous search.
      next_index = index + 1
      eds_params = @eds_params.merge('previous-next-index': next_index)
      response = @repository.search(query, eds_params)
      docs     = response.documents
      prev_doc = (docs.first if index > 0)
      next_doc = (docs.last  if next_index < response.total)
      return response, [prev_doc, next_doc]
    end

    # A solr query method.
    #
    # Does a standard search but returns a simplified object.
    #
    # An array is returned, the first item is the query string, the second item
    # is an other array. This second array contains all of the field values for
    # each of the documents...
    # where the field is the "field" argument passed in.
    #
    # @param [?]    field
    # @param [Hash] req_params
    # @param [Hash] eds_params
    #
    # @return [Array<(String, Array)>]
    #
    # Compare with:
    # @see Blacklight::SearchHelper#get_opensearch_response
    #
    # NOTE: 0% coverage for this method
    #
    def get_opensearch_response(field = nil, req_params = nil, eds_params = nil)
      field ||= @blacklight_config.view_config(:opensearch).title_field
      query =
        search_builder
          .with(@user_params)
          .merge(solr_opensearch_params(field))
          .merge(req_params || {})
      resp = @repository.search(query, @eds_params.merge(eds_params || {}))
      q    = resp.params[:q].to_s
      docs = resp.documents.flat_map { |doc| doc[field] }.compact.uniq
      return q, docs
    end

    # The key to use to retrieve the grouped field to display.
    #
    # @return [?]
    #
    # Compare with:
    # @see Blacklight::SearchHelper#grouped_key_for_results
    #
    # NOTE: 0% coverage for this method
    #
    def grouped_key_for_results
      @blacklight_config.index.group
    end

    # repository
    #
    # @return [Blacklight::Eds::Repository]
    #
    # Compare with:
    # @see Blacklight::SearchHelper#repository
    #
    # NOTE: 0% coverage for this method
    #
    def repository
      @repository
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # fetch_fulltext
    #
    # @param [String] id
    # @param [String] type
    # @param [Hash]   req_params
    #
    # @return [String]
    #
    # NOTE: 0% coverage for this method
    #
    def fetch_fulltext(id, type, req_params)
      @repository.fulltext_url(id, type, req_params, @eds_params)
    end

    # =========================================================================
    # :section: Blacklight::SearchHelper replacements
    # =========================================================================

    public

    # Retrieve a set of documents by id.
    #
    # @param [Array] ids
    # @param [Hash]  req_params
    # @param [Hash]  eds_params
    #
    # @return [Array<(Blacklight::Solr::Response, Array<EdsDocument>)>]
    #
    # Compare with:
    # @see Blacklight::SearchHelper#fetch_many
    #
    def fetch_many(ids, req_params = nil, eds_params = nil)
      query =
        search_builder
          .with(@user_params)
          .where(@blacklight_config.document_model.unique_key => ids)
          .merge(fl: '*')
          .merge(req_params  || {})
      eds_params = @eds_params.merge(eds_params || {})
      response   = @repository.search(query, eds_params)
      return response, response.documents
    end

    # fetch_one
    #
    # @param [?]    id
    # @param [Hash] eds_params
    #
    # @return [Array<(Blacklight::Solr::Response, EdsDocument)>]
    #
    # Compare with:
    # @see Blacklight::SearchHelper#fetch_one
    #
    def fetch_one(id, eds_params = nil)
      eds_params = @eds_params.merge(eds_params || {})
      $stderr.puts ">>> #{__method__}: config #{@blacklight_config.class}" # TODO: debugging - remove
      $stderr.puts ">>> #{__method__}: repository #{@repository.class}" # TODO: debugging - remove
      response   = @repository.find(id, nil, eds_params)
      return response, response.documents.first
    end
  end

end

__loading_end(__FILE__)
