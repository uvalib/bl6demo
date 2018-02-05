# app/models/blacklight/eds/utility.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative('../eds')

module Blacklight::Eds::Utility # TODO: delete?

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

=begin # NOTE: moved to ArticlesHelper
  EBSCO_LINK_TARGETS = %w(pdf ebook-pdf ebook-epub html cataloglink).freeze

  # Alter the order of the types listed below, putting the most desired links
  # first.
  BEST_FULLTEXT_TYPES = %w(
    cataloglink
    pdf
    ebook-pdf
    ebook-epub
    smartlinks
    customlink-fulltext
    customlink-other
  ).freeze

  # Patterns that start a new line in the text display.
  EBSCO_BREAK_BEFORE = Regexp.new(%w(•).join('|'))

  # Translation of XML element tags to equivalent HTML element tags.
  EBSCO_XML_TO_HTML = {
    '<anid>'   => '<anid style="display: none">',
    '<title '  => '<div ',
    '</title>' => '</div>',
    '<bold>'   => '<b>',
    '</bold>'  => '</b>',
    '<emph>'   => '<i>',
    '</emph>'  => '</i>',
  }.freeze

  # For matching any of the XML element tag strings.
  EBSCO_XML_KEYS = Regexp.new(EBSCO_XML_TO_HTML.keys.join('|'))

  # Displayed only if a method is set up to avoid returning *nil*.
  EBSCO_NO_LINK = 'None available'.html_safe.freeze
=end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

=begin # NOTE: moved to ArticlesHelper
  # Massage text.
  #
  # @param [String]  s
  # @param [Boolean] multiline
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def eds_text(s, multiline = false)
    CGI.unescapeHTML(s || '').tap { |result|
      result.gsub!(EBSCO_BREAK_BEFORE) { |s| '<br/>' + s } if multiline
      result.gsub!(EBSCO_XML_KEYS, EBSCO_XML_TO_HTML)
    }.strip.html_safe
  end
=end

  # ===========================================================================
  # :section: BlacklightMarcHelper replacements
  # ===========================================================================

=begin # NOTE: moved to ArticlesHelper
  # refworks_eds_document_path
  #
  # @return [String]
  #
  # Compare with:
  # @see BlacklightMarcHelper#refworks_solr_document_path
  #
  def refworks_eds_document_path(*args)
    opt = { only_path: false }
    opt.merge!(args.pop)  if args.last.is_a?(Hash)
    opt[:id] = args.first if args.first.present?
    opt[:format] = :refworks_marc_txt
    refworks_export_url(url: url_for(opt))
  end
=end

=begin # NOTE: moved to ArticlesHelper
  # refworks_bookmarks_path
  #
  # @return [String]
  #
  # @see BlacklightMarcHelper#refworks_solr_document_path
  #
  # NOTE: 0% coverage for this method
  #
  def refworks_bookmarks_path(*args)
    refworks_eds_document_path(*args)
  end
=end

end

__loading_end(__FILE__)
