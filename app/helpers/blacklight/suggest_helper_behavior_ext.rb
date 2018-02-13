# app/helpers/blacklight/suggest_helper_behavior_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

module Blacklight

  # Blacklight::SuggestHelperBehaviorExt
  #
  # @see Blacklight::SuggestHelperBehavior
  #
  module SuggestHelperBehaviorExt

    include Blacklight::SuggestHelperBehavior
    include Blacklight::ConfigurationHelperBehaviorExt
    include LensHelper

    # =========================================================================
    # :section: Blacklight::SuggestHelperBehavior overrides
    # =========================================================================

    public

=begin # NOTE: using base version
    # Indicate whether auto-complete is enabled in the UI.
    #
    def autocomplete_enabled?
      blacklight_config.autocomplete_enabled.present? &&
        blacklight_config.autocomplete_path.present?
    end
=end

  end

end

__loading_end(__FILE__)
