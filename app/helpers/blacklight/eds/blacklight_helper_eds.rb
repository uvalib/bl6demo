# app/helpers/blacklight/eds/blacklight_helper_eds.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/eds'

module Blacklight::Eds

  # Blacklight::Eds::BlacklightHelperEds
  #
  # Used in place of:
  # @see Blacklight::BlacklightHelper
  #
  # @see Blacklight::BlacklightHelperBehaviorExt
  # @see Blacklight::BlacklightHelperBehavior
  #
  module BlacklightHelperEds # TODO: delete and replace invocations with "include Blacklight::BlacklightHelper"
    include Blacklight::BlacklightHelperBehaviorExt
  end

end

__loading_end(__FILE__)
