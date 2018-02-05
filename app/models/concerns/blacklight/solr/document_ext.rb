# app/models/concerns/blacklight/eds/suggest/response_eds.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

require 'blacklight/solr/document' #unless ONLY_FOR_DOCUMENTATION

# Blacklight::Solr::DocumentExt
#
# @see Blacklight::Solr::Document
#
module Blacklight::Solr::DocumentExt

  extend ActiveSupport::Concern

  include Blacklight::DocumentExt
  include Blacklight::Solr::Document

=begin # NOTE: using base version
  include Blacklight::Document
  include Blacklight::Document::ActiveModelShim
  include Blacklight::Solr::Document::MoreLikeThis
=end

=begin # NOTE: using base version
  autoload :MoreLikeThis, 'blacklight/solr/document/more_like_this'
=end

  # ===========================================================================
  # :section: Blacklight::Solr::Document overrides
  # ===========================================================================

  public

=begin # NOTE: using base version
  # has_highlight_field?
  #
  # @param [String, Symbol] key
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::Solr::Document#has_highlight_field?
  #
  def has_highlight_field?(key)
    response['highlighting']&.fetch(self.id, nil)&.key?(key.to_s)
  end
=end

=begin # NOTE: using base version
  # highlight_field
  #
  # @param [String, Symbol] key
  #
  # @return [Array<ActiveSupport::SafeBuffer>, nil]
  #
  # This method overrides:
  # @see Blacklight::Solr::Document#highlight_field
  #
  def highlight_field(key)
    hl = response['highlighting']&.fetch(self.id, nil)&.fetch(key.to_s, nil)
    Array.wrap(hl).map(&:html_safe) if hl
  end
=end

  # ===========================================================================
  # :section: Blacklight::DocumentExt overrides
  # ===========================================================================

  public

  # Indicate whether this document is shadowed (that is, not viewable and
  # not discoverable).
  #
  # This method overrides:
  # @see Blacklight::DocumentExt#hidden?
  #
  # NOTE: 0% coverage for this method
  #
  def hidden?
    has?(:shadowed_location_facet, 'HIDDEN')
  end

  # Indicate whether this document can be discovered by user search.
  #
  # Such records, even if not independently discoverable can be linked to and
  # accessed directly.  This is useful in the case of records that are
  # 'part of' a discoverable collection.
  #
  # This method overrides:
  # @see Blacklight::DocumentExt#discoverable?
  #
  # NOTE: 0% coverage for this method
  #
  def discoverable?
    !has?(:shadowed_location_facet, 'UNDISCOVERABLE')
  end

end

__loading_end(__FILE__)
