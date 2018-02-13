# app/models/concerns/blacklight/document/export_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'
require 'blacklight/document/export'

# Extensions to Blacklight::Document::Export.
#
# The document class that includes this module should override these methods
# according to its abilities.
#
# (For example, SolrDocument overrides these when [conditinally] including
# Blacklight::Solr::Document::Marc.)
#
# @see Blacklight::Document::Export
# @see Blacklight::Solr::Document::MarcExport
#
module Blacklight::Document::ExportExt

  include Blacklight::Document::Export
  include BlacklightMarcHelper
  include ExportHelper

  include Blacklight::Solr::Document::Marc unless ONLY_FOR_DOCUMENTATION

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

=begin # NOTE: moved to ExportHelper
  REFWORKS_URL = 'https://www.refworks.com/express/expressimport.asp'
=end

  # ===========================================================================
  # :section: BlacklightMarcHelper overrides
  # ===========================================================================

  public

=begin # NOTE: moved to ExportHelper
  # refworks_export_url
  #
  # @param [Hash] url_params
  #
  # @options url_params [String] :url       Required path to document.
  # @options url_params [String] :vendor    Default: `application_name`.
  # @options url_params [String] :filter    Default: 'RefWorks Tagged Format'
  #
  # @return [String]
  #
  # This method overrides:
  # @see BlacklightMarcHelper#refworks_export_url
  #
  def refworks_export_url(url_params = nil)
    opt = { vendor: application_name, filter: 'RefWorks Tagged Format' }
    case url_params
      when Hash   then opt.merge!(url_params)
      when String then opt[:url] = url_params
    end
    url_params =
      opt.map { |key, value|
        value = CGI.escape(value || '')
        %Q(#{key}=#{value})
      }.join('&')
    "#{REFWORKS_URL}?#{url_params}"
  end
=end

=begin # NOTE: moved to ExportHelper
  # refworks_solr_document_path
  #
  # @param [Hash] options
  #
  # @options url_params [String] :id        Required: Document ID.
  #
  # @return [String, nil]
  #
  # This method overrides:
  # @see BlacklightMarcHelper#refworks_solr_document_path
  #
  def refworks_solr_document_path(options = nil)
    refworks_document_path(options)
  end
=end

=begin # NOTE: moved to ExportHelper
  # For exporting a single document in EndNote format.
  #
  # @param [Hash] options
  #
  # @options url_params [String] :id        Required: Document ID.
  #
  # @return [String, nil]
  #
  # This method overrides:
  # @see BlacklightMarcHelper#single_endnote_catalog_path
  #
  def single_endnote_catalog_path(options = nil)
    endnote_document_path(options)
  end
=end

=begin # NOTE: using base version
  # Combines a set of document references into one RefWorks export string.
  #
  # @param [Blacklight::Document, Array<Blacklight::Document>] documents
  #
  # @return [String]
  #
  # This method overrides:
  # @see BlacklightMarcHelper#render_refworks_texts
  #
  def render_refworks_texts(documents)
    documents.map { |doc|
      doc.export_as(:refworks_marc_txt) if doc.exports_as?(:refworks_marc_txt)
    }.compact.join("\n")
  end
=end

=begin # NOTE: using base version
  # Combines a set of document references into one EndNote export string.
  #
  # @param [Blacklight::Document, Array<Blacklight::Document>] documents
  #
  # @return [String]
  #
  # This method overrides:
  # @see BlacklightMarcHelper#render_endnote_texts
  #
  def render_endnote_texts(documents)
    documents.map { |doc|
      doc.export_as(:endnote) if doc.exports_as?(:endnote)
    }.compact.join("\n")
  end
=end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

=begin # NOTE: moved to ExportHelper
  # refworks_document_path
  #
  # @param [Hash] options
  #
  # @options url_params [String] :id        Required: Document ID.
  #
  # @return [String, nil]
  #
  def refworks_document_path(*args)
    opt = { action: 'show', format: :refworks_marc_txt, only_path: false }
    opt.merge!(args.pop) if args.last.is_a?(Hash)
    opt[:id] = args.first if args.first.present?
    opt[:controller] ||= current_lens_key
    url = (url_for(opt) if opt[:id].present?)
    refworks_export_url(url) if url
  end
=end

=begin # NOTE: moved to ExportHelper
  # For exporting a single document in EndNote format.
  #
  # @param [Hash] options
  #
  # @options url_params [String] :id        Required: Document ID.
  #
  # @return [String, nil]
  #
  def endnote_document_path(*args)
    opt = { action: 'show', format: :endnote, only_path: true }
    opt.merge!(args.pop) if args.last.is_a?(Hash)
    opt[:id] = args.first if args.first.present?
    opt[:controller] ||= current_lens_key
    url_for(opt) if opt[:id].present?
  end
=end

=begin # NOTE: moved to ExportHelper
  # For exporting a single document in Zotero RIS format.
  #
  # @param [Hash] options
  #
  # @options url_params [String] :id        Required: Document ID.
  #
  # @return [String, nil]
  #
  def ris_document_path(*args)
    opt = { action: 'show', format: :ris, only_path: true }
    opt.merge!(args.pop) if args.last.is_a?(Hash)
    opt[:id] = args.first if args.first.is_a?(String)
    opt[:controller] ||= current_lens_key
    url_for(opt) if opt[:id].present?
  end
=end

=begin # NOTE: moved to ExportHelper
  # Combines a set of document references into one Zotero RIS export string.
  #
  # @param [Blacklight::Document, Array<Blacklight::Document>] documents
  #
  # @return [String]
  #
  # @see BlacklightMarcHelper#render_refworks_texts
  # @see BlacklightMarcHelper#render_endnote_texts
  #
  def render_ris_texts(documents)
    documents.map { |doc|
      doc.export_as(:ris) if doc.exports_as?(:ris)
    }.compact.join("\n")
  end
=end

  # ===========================================================================
  # :section: Blacklight::Solr::Document::Marc default implementations
  # ===========================================================================

  public

  # to_marc
  #
  # @return [nil]
  #
  # Compare with:
  # @see Blacklight::Solr::Document::Marc#to_marc
  #
  def to_marc
    nil
  end

  # ===========================================================================
  # :section: Blacklight::Solr::Document::MarcExport default implementations
  # ===========================================================================

  public

  # Export in MARC format.
  #
  # @return [String]
  # @return [nil]
  #
  # Compare with:
  # @see Blacklight::Solr::Document::MarcExport#export_as_marc
  #
  # NOTE: 0% coverage for this method
  #
  def export_as_marc
    if to_marc
      not_implemented('MARC')
    else
      invalid_for_non_marc(__method__) # TODO: ???
    end
  end

  # Export in MARCXML format.
  #
  # @return [String]
  # @return [nil]
  #
  # Compare with:
  # @see Blacklight::Solr::Document::MarcExport#export_as_marcxml
  #
  # NOTE: 0% coverage for this method
  #
  def export_as_marcxml
    if to_marc
      not_implemented('MARCXML')
    else
      invalid_for_non_marc(__method__) # TODO: ???
    end
  end

  # Export in XML format.
  #
  # @return [String]
  # @return [nil]
  #
  # Compare with:
  # @see Blacklight::Solr::Document::MarcExport#export_as_xml
  #
  # NOTE: 0% coverage for this method
  #
  def export_as_xml
    not_implemented('XML')
  end

  # Emit an APA (American Psychological Association) bibliographic citation.
  #
  # @return [String]
  # @return [nil]
  #
  # Compare with:
  # @see Blacklight::Solr::Document::MarcExport#export_as_apa_citation_txt
  #
  def export_as_apa_citation_txt
    not_implemented('APA citation')
  end

  # Emit an MLA (Modern Language Association) bibliographic citation.
  #
  # @return [String]
  # @return [nil]
  #
  # Compare with:
  # @see Blacklight::Solr::Document::MarcExport#export_as_mla_citation_txt
  #
  def export_as_mla_citation_txt
    not_implemented('MLA citation')
  end

  # Emit an CMOS (Chicago Manual of Style) bibliographic citation.
  #
  # @return [String]
  # @return [nil]
  #
  # Compare with:
  # @see Blacklight::Solr::Document::MarcExport#export_as_chicago_citation_txt
  #
  def export_as_chicago_citation_txt
    not_implemented('CMOS citation')
  end

  # Export as an OpenURL KEV (key-encoded value) query string.
  #
  # @param [String] format
  #
  # @return [String]
  # @return [nil]
  #
  # Compare with:
  # @see Blacklight::Solr::Document::MarcExport#export_as_openurl_ctx_kev
  #
  def export_as_openurl_ctx_kev(format = nil)
    not_implemented('OpenURL')
  end

  # Export to RefWorks.
  #
  # @return [String]
  # @return [nil]
  #
  # Compare with:
  # @see Blacklight::Solr::Document::MarcExport#export_as_refworks_marc_txt
  #
  # NOTE: 0% coverage for this method
  #
  def export_as_refworks_marc_txt
    not_implemented('RefWorks')
  end

  # Export to EndNote.
  #
  # @return [String]
  # @return [nil]
  #
  # Compare with:
  # @see Blacklight::Solr::Document::MarcExport#export_as_endnote
  #
  def export_as_endnote
    not_implemented('EndNote')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Export to Zotero RIS.
  #
  # @return [String]
  # @return [nil]
  #
  # NOTE: 0% coverage for this method
  #
  def export_as_ris
    not_implemented('Zotero RIS')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  PROD_EXPORT_NOT_AVAILABLE =
    'Export as %s not available for non-MARC metadata' \
    ' - Blacklight does not support it'.html_safe.freeze
  DEV_EXPORT_NOT_AVAILABLE = PROD_EXPORT_NOT_AVAILABLE

  # Result to return from the base method implementation.
  #
  # To cause `NotImplementedError` to be raised instead, make this value *nil*.
  #
  EXPORT_NOT_AVAILABLE =
    case Rails.env
      when 'production'  then PROD_EXPORT_NOT_AVAILABLE
      when 'development' then DEV_EXPORT_NOT_AVAILABLE
      else                    NotImplementedError
    end

  # not_implemented
  #
  # @param [Array] *args
  #
  # @return [String]
  # @return [nil]
  #
  # @raise [NotImplementedError]      As defined by self#EXPORT_NOT_AVAILABLE.
  #
  def not_implemented(*args)
    result = EXPORT_NOT_AVAILABLE
    raise result   if result.is_a?(Exception)
    result %= args if result.is_a?(String) && args.present?
    result
  end

  # invalid_for_non_marc
  #
  # @param [Symbol, nil] method
  #
  # @raise [NotImplementedError]
  #
  # NOTE: 0% coverage for this method
  #
  def invalid_for_non_marc(method = nil)
    report = +'ERROR: '
    report << "#{method.inspect} " if method
    report << 'SHOULD NEVER BE INVOKED FOR NON-MARC'
    raise NotImplementedError, report
  end

end

__loading_end(__FILE__)
