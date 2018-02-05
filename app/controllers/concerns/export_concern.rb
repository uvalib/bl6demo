# app/controllers/concerns/export_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Rolls-up logic associated with bibliographic citation exports and also
# "librarian view".
#
# @see Blacklight::Marc::Catalog
#
module ExportConcern

  extend ActiveSupport::Concern

  include Blacklight::Catalog       unless ONLY_FOR_DOCUMENTATION
  include Blacklight::Marc::Catalog unless ONLY_FOR_DOCUMENTATION

  include ExportHelper

  # Code to be added to the controller class including this module.
  included do |base|

    __included(base, 'ExportConcern')

    include RescueConcern
    include LensConcern

    add_show_tools_partial(
      :librarian_view,
      if:             :render_librarian_view_control?,
      define_method:  false
    )

    add_show_tools_partial(
      :refworks,
      if:             :render_refworks_action?,
      define_method:  false,
      modal:          false,
      path:           :single_refworks_path,
      url_opts:       { target: '_blank' }
    )

    add_show_tools_partial(
      :endnote,
      if:             :render_endnote_action?,
      define_method:  false,
      modal:          false,
      path:           :single_endnote_path
    )

=begin # TODO: Zotero RIS
    add_show_tools_partial(
      :ris,
      if:             :render_ris_action?,
      modal:          false,
      define_method:  false,
      path:           :single_ris_path
    )
=end

    if respond_to?(:helper_method)
      helper_method :single_refworks_path
      helper_method :single_endnote_path
=begin # TODO: Zotero RIS
      helper_method :single_ris_path
=end
    end

  end

  # ===========================================================================
  # :section: Blacklight::Marc::Catalog replacements
  # ===========================================================================

  public

  # == GET /:controller/:id/librarian_view
  # == GET /:controller/librarian_view?id=:id
  #
  # Compare with:
  # @see Blacklight::Marc::Catalog#librarian_view
  #
  def librarian_view
    @response, @document = fetch(params[:id])
    respond_to do |format|
      format.html { render layout: false }
      format.js   { render layout: false }
    end
  end

  # == GET /:controller/:id/endnote
  # == GET /:controller/endnote?id=:id
  #
  # Compare with:
  # @see Blacklight::Marc::Catalog#endnote
  #
  # NOTE: 0% coverage for this method
  #
  def endnote
    @response, @documents = fetch(Array(params[:id]))
    respond_to do |format|
      format.endnote { render layout: false }
    end
  end

=begin # TODO: testing... may not need
  # == GET /:controller/:id/refworks
  # == GET /:controller/refworks?id=:id
  #
  def refworks
    @response, @documents = fetch(Array(params[:id]))
    respond_to do |format|
      format.refworks_marc_txt { render layout: false }
    end
  end
=end

  # ===========================================================================
  # :section: Blacklight::Catalog overrides
  # ===========================================================================

  protected

  # Render additional response formats for the index action, as provided by the
  # blacklight configuration
  #
  # @param [Hash] format
  #
  # @return [void]
  #
  # @raise [ActionController::RoutingError]
  #
  # @note Make sure your format has a well known mime-type or is registered in
  # config/initializers/mime_types.rb
  #
  # @example
  #   config.index.respond_to.txt = Proc.new { render plain: 'A list of docs' }
  #
  # Compare with:
  # @see Blacklight::Catalog#additional_response_formats
  #
  def additional_response_formats(format)
    blacklight_config.index.respond_to.each do |key, config|
      format.send(key) do
        case config
          when false  then raise ActionController::RoutingError, 'Not Found'
          when Hash   then render config
          when Proc   then instance_exec(&config)
          when Symbol then send config
          when String then send config
          else             render({})
        end
      end
    end
  end

=begin # NOTE: using base version
  # Render additional export formats for the show action, as provided by the
  # document extension framework.
  #
  # @param [Blacklight::Document] document
  # @param [?]                    format
  #
  # Compare with:
  # @see Blacklight::Catalog#additional_export_formats
  #
  def additional_export_formats(document, format)
    document.export_formats.each_key do |format_name|
      format.send(format_name.to_sym) do
        render body: document.export_as(format_name), layout: false
      end
    end
  end
=end

=begin # NOTE: using base version
  # Try to render a response from the document export formats available.
  #
  # @param [?] format
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @raise [ActionController::UnknownFormat]
  #
  # Compare with:
  # @see Blacklight::Catalog#document_export_formats
  #
  def document_export_formats(format) # TODO: needed?
    format.any do
      format_name = params[:format]&.to_sym
      if @response.export_formats.include?(format_name)
        render_document_export_format(format_name)
      else
        raise ActionController::UnknownFormat, format_name
      end
    end
  end
=end

  # Render the document export formats for a response.
  #
  # First, try to render an appropriate template (e.g. index.endnote.erb)
  # If that fails, just concatenate the document export responses with a
  # newline.
  #
  # @param [Symbol, String] fmt_name
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # Compare with:
  # @see Blacklight::Catalog#render_document_export_format
  #
  # NOTE: 0% coverage for this method
  #
  def render_document_export_format(fmt_name)
    render
  rescue => e # ActionView::MissingTemplate => e
    unless e.is_a?(ActionView::MissingTemplate)
      logger.error("#{__method__}: UNEXPECTED #{e.class}: #{e.message}")
    end
    docs    = @response&.documents || []
    exports = docs.map { |x| x.export_as(fmt_name) if x.exports_as?(fmt_name) }
    render plain: exports.compact.join("\n"), layout: false
  end

  # ===========================================================================
  # :section: Blacklight::Marc::Catalog replacements
  # ===========================================================================

  protected

  # render_librarian_view_control?
  #
  # @param [?]    _config             Ignored.
  # @param [Hash] opt
  #
  # @options opt [String, Array<String>] :document
  #
  # Compare with:
  # @see Blacklight::Marc::Catalog#render_librarian_view_control?
  #
  def render_librarian_view_control?(_config = nil, opt = nil)
    if_any?(opt) { |doc| doc.to_marc.present? }
  end

  # render_refworks_action?
  #
  # @param [?]    _config             Ignored.
  # @param [Hash] opt
  #
  # @options opt [String, Array<String>] :document
  #
  # Compare with:
  # @see Blacklight::Marc::Catalog#render_refworks_action?
  #
  def render_refworks_action?(_config = nil, opt = nil)
    if_any?(opt) { |doc| doc.exports_as?(:refworks_marc_txt) }
  end

  # render_endnote_action?
  #
  # @param [?]    _config             Ignored.
  # @param [Hash] opt
  #
  # @options opt [String, Array<String>] :document
  #
  # Compare with:
  # @see Blacklight::Marc::Catalog#render_endnote_action?
  #
  def render_endnote_action?(_config = nil, opt = nil)
    if_any?(opt) { |doc| doc.exports_as?(:endnote) }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # render_ris_action?
  #
  # @param [?]    _config             Ignored.
  # @param [Hash] opt
  #
  # @options opt [String, Array<String>] :document
  #
  def render_ris_action?(_config = nil, opt = nil)
    if_any?(opt) { |doc| doc.exports_as?(:ris) }
  end

  # For exporting a single document to RefWorks.
  #
  # @param [Array] args
  #
  #   args[-2] Document identifier
  #   args[-1] Options
  #
  # @return [String]
  #
  def single_refworks_path(*args)
    refworks_document_path(*args)
  end

  # For exporting a single document to EndNote.
  #
  # @param [Array] args
  #
  #   args[-2] Document identifier
  #   args[-1] Options
  #
  # @return [String]
  #
  def single_endnote_path(*args)
    endnote_document_path(*args)
  end

  # For exporting a single document to Zotero RIS.
  #
  # @param [Array] args
  #
  #   args[-2] Document identifier
  #   args[-1] Options
  #
  # @return [String]
  #
  def single_ris_path(*args)
    ris_document_path(*args)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # For the given documents (either one or more documents directly or one or
  # more documents in a hash at key :document), indicate whether any meet the
  # criteria supplied via the block.
  #
  # @param [Hash, Blacklight::Document, Array<Blacklight::Document] docs
  #
  # @options docs [Blacklight::Document, Array<Blacklight::Document>] :document
  #
  # @yield [Blacklight::Document]
  #
  def if_any?(docs)
    docs = docs[:document] if docs.is_a?(Hash)
    docs ||= @document || @documents
    docs = Array.wrap(docs)
    docs.any? { |doc| yield(doc) if doc.is_a?(Blacklight::Document) }
  end

end

__loading_end(__FILE__)
