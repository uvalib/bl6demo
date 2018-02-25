# app/helpers/articles_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/eds'

# Methods to support the display of EdsDocument items.
#
# == Usage Notes
# For each method *options* will be a Hash with the following contents:
#
#   {
#     document: EdsDocument.instance,
#     field:    String,                               # name of matched field (e.g. 'eds_all_links')
#     config:   Blacklight::Configuration::ShowField, # instance for matched field
#     value:    Array                                 # Array<Hash>
#   }
#
module ArticlesHelper

  include Blacklight::BlacklightHelperBehaviorExt

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  EDS_LINK_LABEL  = 'Find @ UVA'
  EDS_PLINK_LABEL =
    'Online via <b>EBSCO Discovery Service</b>'.html_safe.freeze

  FULL_TEXT_ANCHOR = 'full-text'

  RETURN_NIL = {
    eds_publication_type_label: true,
    eds_links:      false,
    best_fulltext:  false,
  }

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

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # eds_publication_type_label
  #
  # @param [Hash] options             Supplied by Blacklight::FieldPresenter.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                                 If no URLs were present.
  #
  # @see CatalogHelper#format_facet_label
  #
  def eds_publication_type_label(options = nil)
    values, opt = extract_config_value(options)
    separator = opt.delete(:separator) || "&nbsp;\n"
    result =
      Array.wrap(values).map { |v|
        content_tag(:span, v, class: 'label label-default') if v.present?
      }.compact.join(separator).html_safe.presence
    result || (EBSCO_NO_LINK unless RETURN_NIL[__method__])
  end

  # eds_index_publication_info
  #
  # The `options[:value]` will be :eds_composed_title but if it's blank, show
  # the :eds_publication_date instead.
  #
  # @param [Hash] options             Supplied by Blacklight::FieldPresenter.
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  # TODO: This never gets triggered if :eds_composed_title is missing...
  # Maybe dealing with fields in this way needs to be handled through
  # IndexPresenter.
  #
  def eds_index_publication_info(options = nil)
    values, opt = extract_config_value(options)
    separator = opt.delete(:separator) || "<br/>\n"
    unless values.present? # NOTE: 0% coverage for this case
      doc = (options[:document] if options.respond_to?(:[]))
      values = (doc[:eds_publication_date] if doc.is_a?(Blacklight::Document))
    end
    Array.wrap(values).join(separator).html_safe.presence
  end

  # best_fulltext
  #
  # @param [Hash] options
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # NOTE: 0% coverage for this method
  #
  def best_fulltext(options = nil)
    values, opt = extract_config_value(options)
    values = (values.first.presence if values.is_a?(Hash))
    array_of_hashes = (values['Links'] if values.is_a?(Hash))
    result =
      if array_of_hashes.present? # NOTE: 0% coverage for this case -- need to investigate
        controller = 'articles' # TODO: generalize
        separator  = opt.delete(:separator)
        guest = current_or_guest_user.guest
        id    = values['id'].to_s.tr('.', '_')
        BEST_FULLTEXT_TYPES.map { |type|
          hash = array_of_hashes.find { |hash| hash['type'] == type }
          url  = hash && hash['url']
          next unless url.present?
          # Use the new fulltext route and controller to avoid time-bombed PDF
          # links.
          pdf = %w(pdf ebook-pdf).include?(type)
          url = "/#{controller}/#{id}/#{type}/fulltext" if pdf
          # Replace 'URL' label for catalog links.
          label = (type == 'cataloglink') ? 'Catalog Link' : hash['label']
          label = 'Full Text' if label.blank?
          if guest
            # Sign in and redirect if guest; return with full-text link if not.
            url    = "/users/sign_in?redirect=#{u(url)}"
            label += ', login to view'
            link_to(label, url)
          else
            outlink(label, url)
          end
        }.compact.join(separator).html_safe.presence
      end
    result || (EBSCO_NO_LINK unless RETURN_NIL[__method__])
  end

  # html_fulltext
  #
  # @param [Hash] options
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_fulltext(options = nil)
    values, opt = extract_config_value(options)
    separator = opt.delete(:separator) || "<br/>\n"
    text = Array.wrap(values).join(separator)
    anchor   = content_tag(:div, '', id: FULL_TEXT_ANCHOR, class: 'anchor')
    scroller = content_tag(:div, eds_text(text, true), class: 'scroller')
    anchor + scroller
  end

  # html_fulltext
  #
  # @param [Hash] options
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def fulltext_link(options = nil)
    doc = options.is_a?(Hash) ? options[:document] : options
    return unless doc.is_a?(Blacklight::Document)
    opt = {
      controller: Blacklight::Lens.key_for_doc(doc),
      action:     'show',
      id:         doc.id,
      anchor:     FULL_TEXT_ANCHOR
    }
    link_to('View', url_for(opt)) # TODO: I18n
  end

  # ebsco_eds_plink
  #
  # Multiple links are wrapped in "<ul class='list-unstyled'></ul>", although,
  # under normal circumstances, there should only be one :eds_plink value.
  #
  # @param [String, Array<String>, Hash] options  Link value(s).
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                                 If no URLs were present.
  #
  def ebsco_eds_plink(options = nil)
    values, _ = extract_config_value(options)
    url = Array.wrap(values).first
    outlink(EDS_PLINK_LABEL, url) if url.present?
  end

  # eds_links
  #
  # Multiple links are wrapped in "<ul class='list-unstyled'></ul>".
  #
  # @param [String, Array<String>, Hash] options  Link value(s).
  #
  # @option options [String] :value
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                                 If no URLs were present.
  #
  # NOTE: 0% coverage for this method
  #
  def eds_links(options = nil)
    all_eds_links(options, %w(pdf ebook-pdf ebook-epub html cataloglink))
  end

  # all_eds_links
  #
  # Multiple links are wrapped in "<ul class='list-unstyled'></ul>".
  #
  # @param [String, Array<String>, Hash] options  Link value(s).
  # @param [Array]  types                         Default: all types.
  # @param [String] separator                     Default: '<br/>'.
  #
  # @option options [String] :value
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                                 If no URLs were present.
  #
  def all_eds_links(options = nil, types = nil, separator = '<br/>')
    values =
      case options
        when Hash  then options[:value]
        when Array then options.map { |value| { url: value } } # NOTE: 0% coverage for this case
        else            { url: options.to_s } # NOTE: 0% coverage for this case
      end
    types = types.presence
    links =
      Array.wrap(values).map { |hash|
        next if hash.blank? || (types && !types.include?(hash['type']))
        make_eds_link(hash)
      }.compact
    if links.blank? # NOTE: 0% coverage for this case
      EBSCO_NO_LINK unless RETURN_NIL[__method__]
    elsif links.size == 1
      links.first
    else
      content_tag(:ul, links.join(separator).html_safe, class: 'list-unstyled')
    end
  end

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

  # ===========================================================================
  # :section: BlacklightMarcHelper replacements
  # ===========================================================================

=begin # NOTE: may not be useful
  # refworks_eds_document_path
  #
  # @return [String]
  #
  # Compare with:
  # @see ExportHelper#refworks_solr_document_path
  #
  def refworks_eds_document_path(*args)
    opt = { action: 'show', format: :refworks_marc_txt, only_path: false }
    opt.merge!(args.pop) if args.last.is_a?(Hash)
    opt[:id] = args.first if args.first.is_a?(String)
    opt[:controller] = :articles
    url = (url_for(opt) if opt[:id].present?)
    refworks_export_url(url) if url
  end
=end

=begin # NOTE: may not be useful
  # refworks_bookmarks_path
  #
  # @return [String]
  #
  # @see ArticlesHelper#refworks_solr_document_path
  #
  # NOTE: 0% coverage for this method
  #
  def refworks_bookmarks_path(*args)
    refworks_eds_document_path(*args)
  end
=end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # make_eds_link
  #
  # @param [Array] *args
  #
  # @option args.last [String]  'label'
  # @option args.last [String]  'url'
  # @option args.last [String]  'icon'
  # @option args.last [String]  'type'      Ignored.
  # @option args.last [String]  'expires'   Ignored.
  # @option args.last [Boolean] :guest
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                           If no URL was provided.
  #
  def make_eds_link(*args)
    opt   = args.extract_options!.except('type', 'expires')
    label = opt.delete('label').presence
    url   = opt.delete('url').presence
    icon  = opt.delete('icon').presence
    guest = opt.delete('guest')
    guest = opt.delete(:guest) || guest
    guest = current_or_guest_user.guest if guest.nil?
    opt.delete('type')
    opt.delete('expires')
    label = args.shift || label
    url   = args.shift || url
    icon  = args.shift || icon
    if guest || (url == 'detail')
      label = 'Access is available, login to view'
      url   = '/users/sign_in'
      link_to(label, url, opt)
    elsif url.present?
      label = image_tag(icon) if icon.to_s.match(/^http/)
      label ||= EDS_LINK_LABEL || 'Link'
      outlink(label, url, opt)
    end
  end

end

__loading_end(__FILE__)
