# app/controllers/concerns/blacklight/search_helper_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Replacement for Blacklight::SearchHelper
#
# @see Blacklight::SearchHelper
#
module Blacklight::SearchHelperExt

  extend ActiveSupport::Concern

  include Blacklight::SearchHelper
  include LensHelper

  # Code to be added to the controller class including this module.
  included do |base|
    __included(base, 'Blacklight::SearchHelperExt')
    include LensConcern
  end

  # ===========================================================================
  # :section: Blacklight::SearchHelper overrides
  # ===========================================================================

  public

=begin # NOTE: using base version
  # search_results
  #
  # @param [Hash] user_params
  #
  # @yield [search_builder]           Optional block yields configured
  #                                     SearchBuilder, caller can modify or
  #                                     create new SearchBuilder to be used.
  #                                     Block should return SearchBuilder to be
  #                                     used.
  #
  # @return [Array<(Blacklight::Solr::Response, Array<Blacklight::Document>)>]
  #
  # This method overrides:
  # @see Blacklight::SearchHelper#search_results
  #
  def search_results(user_params)
    user_params ||= {}
    page = user_params[:page]
    rows = user_params[:per_page] || user_params[:rows]

    query = search_builder.with(user_params)
    query.page = page if page
    query.rows = rows if rows
    query = yield(query) if block_given?

    response = repository.search(query)
    if response.grouped? && grouped_key_for_results
      return response.group(grouped_key_for_results), []
    elsif response.grouped? && response.grouped.length == 1
      return response.grouped.first, []
    else
      return response, response.documents
    end
  end
=end

=begin # NOTE: using base version
  # Retrieve a document, given the doc id.
  #
  # @param [String, Array<String>] id
  # @param [Hash]                  solr_params
  #
  # @return [Array<(Blacklight::Solr::Response, Blacklight::Document)>]
  # @return [Array<(Blacklight::Solr::Response, Array<Blacklight::Document>)>]
  #
  # This method overrides:
  # @see Blacklight::SearchHelper#fetch
  #
  def fetch(id = nil, solr_params = nil)
    if id.is_a?(Array)
      fetch_many(id, search_state.to_h, solr_params)
    else
      fetch_one(id, solr_params)
    end
  end
=end

=begin # NOTE: using base version
  # Get the search service response when retrieving only a single facet field.
  #
  # @param [String, Symbol] facet_field
  # @param [Hash]           req_params
  # @param [Hash]           solr_params
  #
  # @return [Blacklight::Solr::Response]
  #
  # This method overrides:
  # @see Blacklight::SearchHelper#get_facet_field_response
  #
  def get_facet_field_response(facet_field, req_params = nil, solr_params = nil)
    query =
      search_builder
        .with(req_params || params)
        .facet(facet_field)
        .merge(solr_params || {})
    repository.search(query)
  end
=end

=begin # NOTE: using base version
  # Get the previous and next document from a search result.
  #
  # @param [Integer] index
  # @param [Hash]    req_params
  # @param [Hash]    solr_params
  #
  # @return [Array<(Blacklight::Solr::Response, Array<Blacklight::Document>)>]
  #
  # This method overrides:
  # @see Blacklight::SearchHelper#get_previous_and_next_documents_for_search
  #
  def get_previous_and_next_documents_for_search(index, req_params, solr_params = nil)
    pagination_params = previous_and_next_document_params(index)
    start = pagination_params.delete(:start)
    rows  = pagination_params.delete(:rows)
    query =
      search_builder
        .with(req_params)
        .start(start)
        .rows(rows)
        .merge(solr_params || {})
        .merge(pagination_params)
    response = repository.search(query)
    docs     = response.documents
    prev_doc = (docs.first if index > 0)
    next_doc = (docs.last  if (index + 1) < response.total)
    return response, [prev_doc, next_doc]
  end
=end

=begin # NOTE: using base version
  # A Solr query method.
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
  # @param [Hash] solr_params
  #
  # @return [Array<(String, Array)>]
  #
  # This method overrides:
  # @see Blacklight::SearchHelper#get_opensearch_response
  #
  def get_opensearch_response(field = nil, req_params = nil, solr_params = nil)
    field ||= blacklight_config.view_config(:opensearch).title_field
    query =
      search_builder
        .with(req_params || params)
        .merge(solr_opensearch_params(field))
        .merge(solr_params || {})
    resp = repository.search(query)
    q    = resp.params[:q].to_s
    docs = resp.documents.flat_map { |doc| doc[field] }.compact.uniq
    return q, docs
  end
=end

=begin # NOTE: using base version
  # The key to use to retrieve the grouped field to display.
  #
  # @return [?]
  #
  # This method overrides:
  # @see Blacklight::SearchHelper#grouped_key_for_results
  #
  def grouped_key_for_results
    blacklight_config.index.group
  end
=end

=begin # NOTE: using base version
  delegate :repository_class, to: :blacklight_config
=end

=begin # NOTE: using base version
  # repository
  #
  # @param [Blacklight::Configuration, nil] config  Default: `blacklight_config`.
  #
  # @return [Blacklight::AbstractRepository]
  #
  # This method overrides:
  # @see Blacklight::SearchHelper#repository
  #
  def repository(config = nil)
    config ||= blacklight_config
    config.repository_class.new(config)
  end
=end

  # ===========================================================================
  # :section: Blacklight::SearchHelper overrides
  # ===========================================================================

  private

  # Retrieve a set of documents by id.
  #
  # @param [Array] ids
  # @param [Hash]  user_params
  # @param [Hash]  solr_params
  #
  # @return [Array<(Blacklight::Solr::Response, Array<Blacklight::Document>)>]
  #
  # This method overrides:
  # @see Blacklight::SearchHelper#fetch_many
  #
  # Compare with (for articles search):
  # @see Blacklight::Eds::SearchService#fetch_many
  #
  def fetch_many(ids, user_params = nil, solr_params = nil)

    # Get each item from its appropriate repository one-at-a-time rather than
    # as a batch (search) request.  This is for two reasons:
    # 1. Ensure that each failed item is indicated with a *nil* value.
    # 2. To better support cache management.
    response_hash = {}
    response_docs = {}
    Array.wrap(ids).each do |id|
      next if response_hash[id] && response_docs[id]
      response, document = fetch_one(id, solr_params)
      response &&= response['response']
      response &&= response['doc'] || response['docs']
      response_hash[id] = Array.wrap(response).first || document&.to_h
      response_docs[id] = document
    end

    # Manufacture a response from the sets of document hash values.
    response_params = Blacklight::Parameters.sanitize(user_params)
    response = Blacklight::Solr::Response.new({}, response_params)
    response['response'] ||= {}
    response['response']['docs'] = response_hash.values
    return response, response_docs.values

  end

  # Retrieve a single document by id.
  #
  # @param [String] id
  # @param [Hash]   solr_params
  #
  # @return [Array<(Blacklight::Solr::Response, Blacklight::Document)>]
  #
  # This method overrides:
  # @see Blacklight::SearchHelper#fetch_one
  #
  # Compare with (for articles search):
  # @see Blacklight::Eds::SearchService#fetch_one
  #
  def fetch_one(id, solr_params = nil)
    solr_params ||= {}
    response = repository.find(id, solr_params)
    [response, response.documents.first]
  end

end

__loading_end(__FILE__)
