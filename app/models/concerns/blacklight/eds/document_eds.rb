# app/models/concerns/blacklight/eds/document_eds.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/eds'

# Blacklight::Eds::DocumentEds
#
# @see Blacklight::Solr::DocumentExt
# @see Blacklight::Document
#
module Blacklight::Eds::DocumentEds

  extend ActiveSupport::Concern

  include Blacklight::DocumentExt
  include Blacklight::Solr::Document

  unless ONLY_FOR_DOCUMENTATION
    include Blacklight::Document::Email
    include Blacklight::Document::Sms
    include Blacklight::Document::DublinCore
    include Blacklight::Solr::Document::Marc
  end

  # ===========================================================================
  # :section: Blacklight::DocumentExt overrides
  # ===========================================================================

  public

=begin # NOTE: using base version
  # Initialize a new self instance.
  #
  # @param [Hash, nil]                    source_doc
  # @param [RSolr::HashWithResponse, nil] response
  #
  # This method overrides:
  # @see Blacklight::DocumentExt#initialize
  #
  def initialize(source_doc = nil, response = nil)

    # Invoke Blacklight::Document initializer.
    source_doc ||= {}
    super(source_doc, response)

    # Register export formats
    will_export_as(:xml)
xbegin
    will_export_as(:marc,              'application/marc')
    will_export_as(:marcxml,           'application/marcxml+xml')
xend
    will_export_as(:openurl_ctx_kev,   'application/x-openurl-ctx-kev')
    will_export_as(:refworks_marc_txt, 'text/plain')
    will_export_as(:endnote,           'application/x-endnote-refer')
    will_export_as(:ris,               'application/x-research-info-systems')

  end
=end

  # ===========================================================================
  # :section: Blacklight::Document::ActiveModelShim overrides
  # ===========================================================================

  public

  # Unique ID for the document.
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::Document::ActiveModelShim#id
  #
  def id
    super.to_s.tr('.', '_')
  end

  # to_partial_path
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::Document::ActiveModelShim#to_partial_path
  #
  # NOTE: This means that there really has to be an 'articles/document' even if it's a duplicate of 'catalog/document'
  #
  # NOTE: 0% coverage for this method
  #
  def to_partial_path
    'articles/document'
  end

  # ===========================================================================
  # :section: Blacklight::Solr::Document::MarcExport replacements
  # ===========================================================================

  public

=begin # NOTE: using base version
  # Export in MARC format.
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::Document::ExportExt#export_as_marc
  #
  # Compare with:
  # @see Blacklight::Solr::Document::MarcExport#export_as_marc
  #
  def export_as_marc
    invalid_for_non_marc(__method__)
  end
=end

=begin # NOTE: using base version
  # Export in MARCXML format.
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::Document::ExportExt#export_as_marcxml
  #
  # Compare with:
  # @see Blacklight::Solr::Document::MarcExport#export_as_marcxml
  #
  def export_as_marcxml
    invalid_for_non_marc(__method__)
  end
=end

  # Export in XML format.
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::Document::ExportExt#export_as_xml
  #
  # Compare with:
  # @see Blacklight::Solr::Document::MarcExport#export_as_xml
  #
  def export_as_xml
    super # TODO: XML export for non-MARC
  end

  # Emit an APA (American Psychological Association) bibliographic citation
  # from the :citation_apa field.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::Document::ExportExt#export_as_apa_citation_txt
  #
  # Compare with:
  # @see Blacklight::Solr::Document::MarcExport#export_as_apa_citation_txt
  #
  def export_as_apa_citation_txt
    (self[:citation_apa].presence || super).html_safe
  end

  # Emit an MLA (Modern Language Association) bibliographic citation from the
  # :citation_mla field.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::Document::ExportExt#export_as_mla_citation_txt
  #
  # Compare with:
  # @see Blacklight::Solr::Document::MarcExport#export_as_mla_citation_txt
  #
  def export_as_mla_citation_txt
    (self[:citation_mla].presence || super).html_safe
  end

  # Emit an CMOS (Chicago Manual of Style) bibliographic citation from the
  # :citation_chicago field.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::Document::ExportExt#export_as_chicago_citation_txt
  #
  # Compare with:
  # @see Blacklight::Solr::Document::MarcExport#export_as_chicago_citation_txt
  #
  def export_as_chicago_citation_txt
    (self[:citation_chicago].presence || super).html_safe
  end

  # Exports as an OpenURL KEV (key-encoded value) query string.
  #
  # @param [String] format
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::Document::ExportExt#export_as_openurl_ctx_kev
  #
  # Compare with:
  # @see Blacklight::Solr::Document::MarcExport#export_as_openurl_ctx_kev
  #
  def export_as_openurl_ctx_kev(format = nil)
    super # TODO - OpenURL for non-MARC
  end

  # Export to RefWorks.
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::Document::ExportExt#export_as_refworks_marc_txt
  #
  # Compare with:
  # @see Blacklight::Solr::Document::MarcExport#export_as_refworks_marc_txt
  #
  def export_as_refworks_marc_txt
    super # TODO - RefWorks for non-MARC
  end

  # Export to EndNote.
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::Document::ExportExt#export_as_endnote
  #
  # Compare with:
  # @see Blacklight::Solr::Document::MarcExport#export_as_endnote
  #
  def export_as_endnote
    super # TODO - EndNote for non-MARC
  end

  # Export to Zotero RIS.
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::Document::ExportExt#export_as_ris
  #
  def export_as_ris
    super # TODO - Zotero RIS for non-MARC
  end

end

__loading_end(__FILE__)
