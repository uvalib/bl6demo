# lib/blacklight/lens_config.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

module Blacklight

  # Blacklight::LensConfig
  #
  module LensConfig

    # All (known) lens keys.
    LENS_KEYS = [
      #:all,        # TODO: Combined results controller?
      :articles,
      #:music,      # TODO: Music controller
      #:video,      # TODO: Video controller
      :catalog,
    ].freeze

    # Explicitly state the key for the default lens.
    DEFAULT_LENS_KEY = :catalog

    # Sanity check.
    abort unless LENS_KEYS.include?(DEFAULT_LENS_KEY)

  end

end

__loading_end(__FILE__)
