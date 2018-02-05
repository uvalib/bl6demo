# app/models/concerns/blacklight/document_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

require 'models/concerns/blacklight/document' unless ONLY_FOR_DOCUMENTATION

# Blacklight::DocumentExt
#
# @see Blacklight::Document
#
module Blacklight::DocumentExt

  extend ActiveSupport::Concern

  include Blacklight::Document
  include Blacklight::Document::ExportExt

=begin # NOTE: using base version
  extend Deprecation
  self.deprecation_horizon = 'blacklight 7.0'
=end

=begin # NOTE: using base version
  autoload :ActiveModelShim, 'blacklight/document/active_model_shim'
  autoload :SchemaOrg, 'blacklight/document/schema_org'
  autoload :CacheKey, 'blacklight/document/cache_key'
  autoload :DublinCore, 'blacklight/document/dublin_core'
  autoload :Email, 'blacklight/document/email'
  autoload :SemanticFields, 'blacklight/document/semantic_fields'
  autoload :Sms, 'blacklight/document/sms'
  autoload :Extensions, 'blacklight/document/extensions'
  autoload :Export, 'blacklight/document/export'
=end

=begin # NOTE: using base version
  extend ActiveSupport::Concern
  include Blacklight::Document::SchemaOrg
  include Blacklight::Document::SemanticFields
  include Blacklight::Document::CacheKey
  include Blacklight::Document::Export
=end

=begin # NOTE: using base version
  included do
    extend ActiveModel::Naming
    include Blacklight::Document::Extensions
    include GlobalID::Identification
  end
=end

  # ===========================================================================
  # :section: Blacklight::Document overrides
  # ===========================================================================

  public

=begin # NOTE: using base version
  attr_reader :response, :_source
  alias_method :solr_response, :response
  delegate :[], :key?, :keys, :to_h, to: :_source
=end

=begin # NOTE: using base version
=end
  # Initialize a self instance
  #
  # @param [Hash, nil]                    source_doc
  # @param [RSolr::HashWithResponse, nil] response
  #
  # This method overrides:
  # @see Blacklight::Document#initialize
  #
  def initialize(source_doc = {}, response = nil)

    # Invoke Blacklight::Document initializer.
    source_doc ||= {}
    super(source_doc, response)

    # We will always support these export formats (unlike basic Blacklight
    # which only supports them for MARC-based metadata).
    will_export_as(:openurl_ctx_kev,   'application/x-openurl-ctx-kev')
    will_export_as(:refworks_marc_txt, 'text/plain')
    will_export_as(:endnote,           'application/x-endnote-refer')
    will_export_as(:ris,               'application/x-research-info-systems')

  end

=begin # NOTE: using base version
  # the wrapper method to the @_source object.
  # If a method is missing, it gets sent to @_source
  # with all of the original params and block
  #
  # @param [Symbol] m
  # @param [Array]  args
  #
  # This method overrides:
  # @see Blacklight::Document#method_missing
  #
  def method_missing(m, *args, &b)
    if (m == :to_hash) || !_source_responds_to?(m)
      super
    else
      Deprecation.warn(
        Blacklight::Document,
        "Blacklight::Document##{m} is deprecated; use obj.to_h.#{m} instead."
      )
      _source.send(m, *args, &b)
    end
  end
=end

=begin # NOTE: using base version
  # respond_to_missing?
  #
  # @param [Symbol] m
  # @param [Array]  args
  #
  # This method overrides:
  # @see Blacklight::Document#respond_to_missing?
  #
  def respond_to_missing?(m, *args)
    if %i(empty? to_hash).include?(m) || !_source_responds_to?(m, *args)
      super
    else
      true
    end
  end
=end

=begin # NOTE: using base version
  # Helper method to check if value/multi-values exist for a given key.
  #
  # The value can be a string, or a RegExp
  # Multiple "values" can be given; only one needs to match.
  #
  # @param [String, Symbol] key
  # @param [Array]          expected_values
  #
  # @example
  #   doc.has?(:location_facet)
  #   doc.has?(:location_facet, 'Clemons')
  #   doc.has?(:id, 'h009', /^u/i)
  #
  # This method overrides:
  # @see Blacklight::Document#has?
  #
  def has?(key, *expected_values)
    if !key?(key)
      false
    elsif expected_values.empty?
      self[key].present?
    else
      actual_values = Array.wrap(self[key])
      Array.wrap(expected_values).any? do |expected|
        if expected.is_a?(Regexp)
          actual_values.any? { |actual| actual =~ expected }
        else
          actual_values.any? { |actual| actual == expected }
        end
      end
    end
  end
  alias has_field? has?
  alias has_key? key?
=end

  # Get an index field value contained in the document.
  #
  # @param [String, Symbol] key
  # @param [Array]          default
  #
  # @yield [Blacklight::DocumentExt] self
  #
  # @return [Array<String>, String]
  # @return [default.first]
  #
  # This method overrides:
  # @see Blacklight::Document#fetch
  #
  def fetch(key, *default)
    result =
      if key?(key)
        self[key]
      elsif block_given? # NOTE: 0% coverage for this case
        yield(self)
      end
    unless result
      raise KeyError, "key not found \"#{key}\"" if default.empty?
      result = default.first
    end
    result
  end

=begin # NOTE: using base version
  # Get the first field value for the given key.
  #
  # @param [String, Symbol] key
  #
  # @return [String, nil]
  #
  # This method overrides:
  # @see Blacklight::Document#first
  #
  def first(key)
    Array.wrap(self[key]).first
  end
=end

=begin # NOTE: using base version
  # to_partial_path
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::Document#to_partial_path
  #
  def to_partial_path
    'catalog/document'
  end
=end

=begin # NOTE: using base version
  # has_highlight_field?
  #
  # @param [String, Symbol] key
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::Document#has_highlight_field?
  #
  def has_highlight_field?(key)
    false
  end
=end

=begin # NOTE: using base version
  # highlight_field
  #
  # @param [String, Symbol] key
  #
  # @return [String, nil]
  #
  # This method overrides:
  # @see Blacklight::Document#highlight_field
  #
  def highlight_field(key)
    nil
  end
=end

=begin # NOTE: using base version
  # Implementations that support More-Like-This should override this method
  # to return an array of documents that are like this one.
  #
  # @return [Array<Blacklight::DocumentExt>]
  #
  # This method overrides:
  # @see Blacklight::Document#more_like_this
  #
  def more_like_this
    []
  end
=end

  # ===========================================================================
  # :section: Blacklight::Document overrides
  # ===========================================================================

  public

  module ClassMethods

=begin # NOTE: using base version
    attr_writer :unique_key
=end

=begin # NOTE: using base version
    def unique_key
      @unique_key ||= 'id'
    end
=end

  end

  # ===========================================================================
  # :section: Blacklight::Document overrides
  # ===========================================================================

  private

=begin # NOTE: using base version
  # _source_responds_to?
  #
  # @param [Array] args
  #
  # This method overrides:
  # @see Blacklight::Document#_source_responds_to?
  #
  def _source_responds_to?(*args)
    _source && (self != _source) && _source.respond_to?(*args)
  end
=end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether this document is shadowed (that is, not viewable and
  # not discoverable).
  #
  # By default, this method returns *false*; derived classes should override as
  # required.
  #
  def hidden?(*)
  end

  # Indicate whether this document can be discovered by user search.
  #
  # Such records, even if not independently discoverable can be linked to and
  # accessed directly.  This is useful in the case of records that are
  # 'part of' a discoverable collection.
  #
  # By default, this method returns *true*; derived classes should override as
  # required.
  #
  # NOTE: 0% coverage for this method
  #
  def discoverable?(*)
    true
  end

end

__loading_end(__FILE__)
