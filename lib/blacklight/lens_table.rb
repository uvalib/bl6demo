# lib/blacklight/lens_table.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

module Blacklight

  # Blacklight::LensTable
  #
  class LensTable

    include Blacklight::LensConfig
    include Blacklight::LensMapper

    TABLE_METHODS = %i(
      keys
      size
      length
      empty?
      blank?
      present?
      key?
      has_key?
    ).freeze

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Initialize a self instance.
    #
    def initialize
      @hash = LENS_KEYS.map { |k| [k, nil] }.to_h.with_indifferent_access
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    delegate *TABLE_METHODS, to: :@hash

    # Retrieve lens by key.
    #
    # @param [String, Symbol] key
    #
    # @return [Blacklight::Lens, nil]
    #
    def [](key)
      key = key_for(key, false)
      @hash[key] if key
    end

    # Set lens by key.
    #
    # @param [String, Symbol]   key
    # @param [Blacklight::Lens] entry
    #
    # @return [Blacklight::Lens, nil]
    #
    def []=(key, entry)
      key = key_for(key) unless valid_key?(key)
      @hash[key] = entry if key
    end

  end

end

__loading_end(__FILE__)
