# app/controllers/concerns/blacklight/search_history_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

module Blacklight

  # Replacement for Blacklight::SearchHistory
  #
  # @see Blacklight::SearchHistory
  #
  # == Implementation Notes
  # This does not include Blacklight::SearchHistory to avoid executing its
  # `included` block -- which means that it has to completely recreate the
  # module.
  #
  module SearchHistoryExt

    extend ActiveSupport::Concern

    include Blacklight::SearchHistory unless ONLY_FOR_DOCUMENTATION

    include Blacklight::ConfigurableExt

    # Code to be added to the controller class including this module.
    included do |base|
      __included(base, 'Blacklight::SearchHistoryExt')
      include RescueConcern
      include LensConcern
    end

    # =========================================================================
    # :section: Blacklight::SearchHistory replacements
    # =========================================================================

    public

    # == GET /search_history
    #
    # This method replaces:
    # @see Blacklight::SearchHistory#index
    #
    def index
      @searches = searches_from_history
    end

    # == DELETE /search_history/clear
    #
    # TODO: we may want to remove unsaved (those without user_id) items from
    # the database when removed from history
    #
    # This method replaces:
    # @see Blacklight::SearchHistory#clear
    #
    def clear
      if session[:history].clear
        flash[:notice] = I18n.t('blacklight.search_history.clear.success')
      else # NOTE: 0% coverage for this case
        flash[:error]  = I18n.t('blacklight.search_history.clear.failure')
      end
      go_back(fallback: blacklight.search_history_path)
    end

  end

end

__loading_end(__FILE__)
