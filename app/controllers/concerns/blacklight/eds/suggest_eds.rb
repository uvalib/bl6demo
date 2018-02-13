# app/controllers/concerns/blacklight/eds/suggest_eds.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/eds'

module Blacklight::Eds

  # An extension of Blacklight::SuggestExt for controllers that work with
  # articles (EdsDocument).
  #
  # @see Blacklight::SuggestExt
  # @see Blacklight::Suggest
  #
  module SuggestEds

    extend ActiveSupport::Concern

    include Blacklight::SuggestExt

    # Code to be added to the controller class including this module.
    included do |base|
      __included(base, 'Blacklight::Eds::SuggestEds')
      include EdsConcern
      include Blacklight::SuggestExt
    end

    # =========================================================================
    # :section: Blacklight::Suggest replacements
    # =========================================================================

    public

=begin # NOTE: using base version
    # == GET /articles/suggest
    # Get search results from EBSCO EDS.
    #
    # This method overrides:
    # @see Blacklight::SuggestExt#index
    #
    def index
      respond_to do |format|
        format.json { render json: suggestions_service.suggestions }
      end
    end
=end

    # =========================================================================
    # :section: Blacklight::Suggest replacements
    # =========================================================================

    protected

    # suggestions_service
    #
    # @return [Blacklight::Eds::Suggest::ResponseEds]
    #
    # This method overrides:
    # @see Blacklight::SuggestExt#suggestions_service
    #
    def suggestions_service
      req_params = params.merge(session.to_hash)
      Blacklight::Eds::SuggestSearchEds.new(req_params, repository).suggestions
    end

  end

end

__loading_end(__FILE__)
