# app/controllers/concerns/search_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Determine by context whether searches for IDs and/or search terms should go
# to a single or multiple derivatives of Blacklight::AbstractRepository.
#
# @see Blacklight::SearchHelperExt
# @see Blacklight::SearchHelper
#
module SearchConcern

  extend ActiveSupport::Concern

  include Blacklight::Catalog unless ONLY_FOR_DOCUMENTATION

  include Blacklight::SearchHelperExt

  # Code to be added to the controller class including this module.
  included do |base|
    __included(base, 'SearchConcern')
    include RescueConcern
    include LensConcern
  end

  # ===========================================================================
  # :section: Blacklight::SearchHelper overrides
  # ===========================================================================

  protected

  # Indicate whether the document ID is one that was supplied by EDS.
  #
  # @param [String] id
  #
  def eds_doc?(id)
    Blacklight::Lens.key_for_doc(id) == :articles
  end

  # document_type
  #
  # @param [String]        id         ID of bookmarked document
  # @param [String, Class] type       Type of bookmarked document
  #
  # @return [String]
  #
  def document_type(id, type = nil)
    type = type.class if type.is_a?(Blacklight::Document)
    type ||= (EdsDocument if type.is_a?(String) && type.match(/^eds/i))
    type ||= eds_doc?(id) ? EdsDocument : SolrDocument
    type.to_s
  end

  # Get an item using the appropriate mechanism.
  #
  # @param [String, Array<String>] ids  One or more document IDs.
  # @param [Hash]                  *    Ignored.
  #
  # @return [Array<(Blacklight::Solr::Response, Blacklight::Document)>]
  #
  # This method overrides:
  # @see Blacklight::SearchHelper#fetch
  #
  def fetch(ids, *)
    ids.is_a?(Array) ? fetch_many(ids) : fetch_one(ids)
  end

  # ===========================================================================
  # :section: Blacklight::SearchHelper overrides
  # ===========================================================================

  private

  # Get many items from the appropriate repositor(ies).
  #
  # @param [Array<String>] ids
  # @param [Hash]          *          Ignored.
  #
  # @return [Blacklight::Solr::Response, Array<Blacklight::Document>]
  #
  # This method overrides:
  # @see Blacklight::SearchHelperExt#fetch_many
  #
  def fetch_many(ids, *)

    # Get each item from its appropriate repository one-at-a-time rather than
    # as a batch (search) request.  This is for two reasons:
    # 1. Ensure that each failed item is indicated with a *nil* value.
    # 2. To better support cache management.
    response_hash = {}
    response_docs = {}
    Array.wrap(ids).each do |id|
      next if response_hash[id] && response_docs[id]
      response, document = fetch_one(id)
      response &&= response['response']
      response &&= response['doc'] || response['docs']
      response_hash[id] = Array.wrap(response).first || document&.to_h
      response_docs[id] = document
    end

    # Manufacture a response from the sets of document hash values.
    response_params = Blacklight::Parameters.sanitize(params.to_unsafe_hash)
    response = Blacklight::Solr::Response.new({}, response_params)
    response['response'] ||= {}
    response['response']['docs'] = response_hash.values
    return response, response_docs.values

  end

  # Get an item using the appropriate mechanism.
  #
  # @param [String] id
  # @param [Hash]   *                 Ignored.
  #
  # @return [Array<(Blacklight::Solr::Response, Blacklight::Document)>]
  #
  # This method overrides:
  # @see Blacklight::SearchHelperExt#fetch_one
  #
  def fetch_one(id, *)
    $stderr.puts("........... looking for #{id.inspect}") # TODO: debugging - remove
    $stderr.flush # TODO: debugging - remove
    controller_instance = lens_for(id).instance(@response, request)
    controller_instance.instance_exec(id) { |id| fetch(id) }
  end

end

__loading_end(__FILE__)
