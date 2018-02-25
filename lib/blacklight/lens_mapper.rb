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

    # Used to determine whether to interpret a name as one that includes a
    # Blacklight Lens name within it (as opposed to a name which is more likely
    # a document ID).
    #
    # @see self#key_for_name
    #
    KEY_PATH_HINT =
      Regexp.new((%w(/ ::) + LENS_KEYS.map(&:to_s)).join('|'), true)


    # Used to determine whether to interpret a name as one that as a document
    # ID by eliminating strings with invalid characters.
    #
    # @see self#key_for_name
    #
    DOC_ID_HINT = /^[^<>#]+$/

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # default_key
    #
    # @return [Symbol]
    #
    def default_key
      DEFAULT_LENS_KEY
    end

    # valid_key?
    #
    # @param [Symbol] key
    #
    def valid_key?(key)
      key.respond_to?(:to_sym) && LENS_KEYS.include?(key.to_sym)
    end

=begin
    %i(key? has_key?).each { |x| alias_method x, :valid_key? }
=end

    # Translate an entity to a lens key.
    #
    # @param [String, Symbol, Class, Config::Base, Blacklight::Controller] name
    # @param [Boolean, Symbol] default    Default value: *true*.
    #
    # @return [Symbol]
    # @return [default] If *name* is invalid and *default* is not a Boolean.
    # @return [nil]     If *name* is invalid and *default* is *false*.
    #
    def key_for(name, default = true)
      if name
        case name
          when Array                  then key_for(name.first, default) # NOTE: 0% coverage for this case
          when Config::Base           then name.key # NOTE: 0% coverage for this case
          when Blacklight::Lens       then name.key # NOTE: 0% coverage for this case
          when Blacklight::Document   then key_for_doc(name, default)
          when Blacklight::Controller then key_for_name(name.class, default)
          else                             key_for_name(name, default)
        end
      elsif default.is_a?(TrueClass)
        default_key
      elsif !default.is_a?(FalseClass) # NOTE: 0% coverage for this case
        default
      end
    end

    # Given a generic lens key based on the nature of the provided document.
    #
    # @param [Blacklight::Document, String] doc
    # @param [Boolean, Symbol] default    Default value: *true*.
    #
    # @return [Symbol]
    # @return [default] If *doc* is invalid and *default* is not a Boolean.
    # @return [nil]     If *doc* is invalid and *default* is *false*.
    #
    # === Implementation Notes
    # The method assumes that :articles is the only lens that handles items of
    # type EdsDocument.
    #
    def key_for_doc(doc, default = true)
=begin # TODO: If Blacklight::Document responded to :lens_key
      if doc.respond_to?(:lens_key)
        doc.lens_key
      elsif doc.to_s.include?('__')
        Config::Articles.key
      elsif doc.is_a?(String)
        Config::Catalog.key
      elsif default.is_a?(TrueClass)
        default_key
      elsif !default.is_a?(FalseClass)
        default
      end
=end
      case doc
        when EdsDocument
          Config::Articles.key
        when SolrDocument
          Config::Catalog.key
        when Blacklight::Document, String, Symbol
          if (doc.respond_to?(:id) ? doc.id : doc).to_s.include?('__')
            Config::Articles.key
          else
            Config::Catalog.key
          end
        else
          case default
            when false then nil
            when true  then default_key
            else            default
          end
      end
    end

    # Translate a named item to a lens key.
    #
    # If the name is derived from the current controller then the method will
    # attempt to strip off name variations to find the core name (for example,
    # 'video_advanced' will result in 'video'; 'articles_suggest' will result
    # in 'articles', etc).
    #
    # @param [String, Symbol, Class, Config::Base, Blacklight::Controller] name
    # @param [Boolean, Symbol] default    Default value: *true*.
    #
    # @return [Symbol]
    # @return [default] If *doc* is invalid and *default* is not a Boolean.
    # @return [nil]     If *doc* is invalid and *default* is *false*.
    #
    def key_for_name(name, default = true)
      name = name.to_s.strip
      result =
        case name
          when KEY_PATH_HINT
            name.underscore
              .sub(%r{^.*/([^/]+)$}, '\1') # "devise/catalog" -> "catalog"
              .sub(/^config/, '')          # "config_video" -> "_video"
              .sub(/^[:_]*/, '')           # "_catalog" -> "catalog"
              .sub(/^([^:_]+).*$/, '\1')   # "music_suggest_controller" -> "music"
              .sub(/^article$/, '\0s')     # "article" -> "articles"
              .to_sym
          when DOC_ID_HINT
            key_for_doc(name, false)
        end
      if valid_key?(result)
        result
      elsif default.is_a?(TrueClass)
        default_key
      elsif !default.is_a?(FalseClass)
        default
      end
    end

  end

end

__loading_end(__FILE__)
