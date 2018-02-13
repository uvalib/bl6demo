# lib/blacklight/lens_mapper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'
require 'config/_base'

module Blacklight

  # Blacklight::LensMapper
  #
  module LensMapper

    include Blacklight::LensConfig

    # default_key
    #
    # @return [Symbol]
    #
    def default_key
      DEFAULT_LENS_KEY
    end

    # default_key
    #
    # @param [Symbol] key
    #
    # @return [Symbol]
    #
    def valid_key?(key)
      LENS_KEYS.include?(key.to_sym) if key.present?
    end

    %i(key? has_key?).each { |x| alias_method x, :valid_key? }

    # Translate an entity to a lens key.
    #
    # @param [String, Symbol, Class, Config::Base, Blacklight::Controller] name
    #
    # @return [Symbol]
    #
    def key_for(name)
      case name
        when nil                    then default_key
        when Array                  then key_for(name.first) # NOTE: 0% coverage for this case
        when Config::Base           then name.key # NOTE: 0% coverage for this case
        when Blacklight::Lens       then name.key # NOTE: 0% coverage for this case
        when Blacklight::Document   then key_for_doc(name)
        when Blacklight::Controller then key_for_name(name.class)
        else                             key_for_name(name)
      end
    end

    # Given a generic lens key based on the nature of the provided document.
    #
    # @param [Blacklight::Document, String] doc
    #
    # @return [Symbol]
    #
    def key_for_doc(doc)
      articles = doc.is_a?(EdsDocument)
      articles ||= (doc.respond_to?(:id) ? doc.id : doc).to_s.include?('__')
      articles ? :articles : :catalog
    end

    # Translate a named item to a lens key.
    #
    # @param [String, Symbol, Class, Config::Base, Blacklight::Controller] name
    #
    # @return [Symbol]
    #
    def key_for_name(name)
      result =
        name.to_s.underscore.strip
          .sub(%r{^.*/([^/]+)$}, '\1') # NOTE: "devise/catalog" -> "catalog"
          .sub(/^config(::|_)*/, '')
          .sub(/(::|_)*controller$/, '')
          .sub(/(::|_)*advanced$/, '')
          .sub(/^article$/, '\0s') # NOTE: Silently correct to 'articles'.
          .to_sym
      valid_key?(result) ? result : key_for_doc(result)
    end

  end

end

__loading_end(__FILE__)
