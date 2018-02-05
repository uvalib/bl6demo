# app/models/blacklight/suggest_search_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

module Blacklight

  # Blacklight::SuggestSearchExt
  #
  # Derived from:
  # @see Blacklight::SuggestSearch
  #
  class SuggestSearchExt < Blacklight::SuggestSearch

    # =========================================================================
    # :section: Blacklight::SuggestSearch overrides
    # =========================================================================

    public

=begin # NOTE: using base version
    attr_reader :request_params, :repository
=end

    # Initialize a self instance.
    #
    # @param [Hash]                           params
    # @param [Blacklight::AbstractRepository] repository
    #
    # This method overrides:
    # @see Blacklight::SuggestSearch#initialize
    #
    def initialize(params, repository)
      super
      sf = params[:search_field].to_s.presence
      sf = nil if sf && %w(advanced all_fields).include?(sf)
      @request_params[:search_field] = sf if sf
    end

=begin # NOTE: using base version
    # For now, only use the q parameter to create a response.
    #
    # @return [Blacklight::Suggest::Response]
    #
    def suggestions
      Blacklight::Suggest::Response.new(suggest_results, request_params, suggest_handler_path)
    end
=end

    # Query the suggest handler.
    #
    # @return [RSolr::HashWithResponse, nil]
    #
    # This method overrides:
    # @see Blacklight::SuggestSearch#suggest_results
    #
    def suggest_results
      repository.auto_suggest(suggest_handler_path, request_params)
    end

=begin # NOTE: using base version
    # suggest_handler_path
    #
    # @return [String]
    #
    def suggest_handler_path
      repository.blacklight_config.autocomplete_path
    end
=end

  end

end

__loading_end(__FILE__)
