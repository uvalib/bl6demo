# lib/ext/ebsco-eds/options_override.rb

__loading_begin(__FILE__)

require_relative 'eds_override'

# =============================================================================
# :section: Inject methods into EBSCO::EDS::Record
# =============================================================================

override EBSCO::EDS::Record do

  require 'i18n'

  # The RELAXED config:
  # @see https://github.com/rgrove/sanitize/blob/master/lib/sanitize/config/relaxed.rb
  SANITIZE_BASE_CONFIG = Sanitize::Config::RELAXED

  # Additional HTML elements that are not removed during sanitization.
  SANITIZE_PERMITTED_ELEMENTS =
    SANITIZE_BASE_CONFIG[:elements] + %w(relatesto searchlink)

  # Additional HTML attributes that are not removed during sanitization.
  SANITIZE_PERMITTED_ATTRIBUTES =
    SANITIZE_BASE_CONFIG[:attributes].merge('searchlink' => %w(fieldcode term))

  # General sanitization configuration.
  # @see self#html_decode_and_sanitize
  SANITIZE_CONFIG =
    Sanitize::Config.merge(
      SANITIZE_BASE_CONFIG,
      elements:   SANITIZE_PERMITTED_ELEMENTS,
      attributes: SANITIZE_PERMITTED_ATTRIBUTES
    ).freeze

  # Default replacements of XML node names with related HTML element names.
  FULL_TEXT_DEFAULT_TRANSFORM = {
    title:    'h1',
    sbt:      'h2',
    jsection: 'h3',
    et:       'h3',
  }.with_indifferent_access.freeze

  # Replace received XML node names with related HTML element names from
  # 'ebsco_eds.html_fulltext' or #FULL_TEXT_DEFAULT_TRANSFORM.
  # @see config/locale/ebsco_eds.yml
  SANITIZE_TRANSFORMER =
    lambda do |env|
      node = env[:node]
      html_element =
        I18n.t(
          "ebsco_eds.html_fulltext.#{node.name}",
          default: FULL_TEXT_DEFAULT_TRANSFORM[node.name]
        )
      node.name = html_element if html_element
    end

  # Sanitization configuration for full-text content.
  # @see self#html_fulltext
  SANITIZE_FULLTEXT_CONFIG =
    SANITIZE_CONFIG.merge(
      remove_contents: true,
      transformers:    [SANITIZE_TRANSFORMER]
    ).freeze

  # @see self#bib_publication_date
  PUB_DATE_KEYS = %w(Y M D).freeze

  # ===========================================================================
  # MISC HELPERS
  # ===========================================================================

=begin # NOTE: using base version
  # Options hash containing accession number and database ID.
  # This can be passed to the retrieve method.
  #
  # @return [Hash]
  #
  def retrieve_options
    { 'an' => @eds_accession_number, 'dbid' => @eds_database_id }
  end
=end

  # The title.
  #
  # @param [String, nil] fallback     Displayed for items without a title.
  #
  # @return [String]                  Fallback: 'ebsco_eds.message.title'
  #
  # The default fallback title is taken from 'ebsco_eds.message.title':
  # @see config/locales/ebsco_eds.yml
  #
  def title(fallback = nil)
    bib_title || get_item_data(name: 'Title') || fallback ||
      I18n.t('ebsco_eds.message.title', default: 'Please login to view')
  end

  # The source title (e.g.: 'Salem Press Encyclopedia')
  #
  # @return [String, nil]
  #
  def source_title
    result = bib_source_title || get_item_data(name: 'TitleSource')
    result unless result == title # Suppress if it's identical to title.
  end

=begin # NOTE: using base version
  # Link to the thumbnail-size cover image.
  #
  # @return [String, nil]
  #
  def cover_thumb_url
    images('thumb')&.first&.fetch(:src, nil)
  end
=end

=begin # NOTE: using base version
  # Link to the medium-size cover image.
  #
  # @return [String, nil]
  #
  def cover_medium_url
    images('medium')&.first&.fetch(:src, nil)
  end
=end

=begin # NOTE: using base version
  # Indicate whether full-text is available for the item.
  #
  # @return [Boolean]
  #
  def html_fulltext_available
    @record.dig('FullText', 'Text', 'Availability') == '1'
  end
=end

  # The full text of the item embedded in the record.
  #
  # @param [Sanitize::Config, nil] sanitize_config  If @decode_sanitize_html is
  #                                                 *true* (Default:
  #                                                 #SANITIZE_FULLTEXT_CONFIG)
  #
  # @return [String, nil]
  #
  # @see self#SANITIZE_FULLTEXT_CONFIG
  #
  def html_fulltext(sanitize_config = nil)
    return unless html_fulltext_available
    value = @record.dig('FullText', 'Text', 'Value')
    if @decode_sanitize_html
      sanitize_config ||= SANITIZE_FULLTEXT_CONFIG
      value = html_decode_and_sanitize(value, sanitize_config)
    end
    value
  end

=begin # NOTE: using base version
  # Zero or more links to cover images for the item.
  #
  # @return [Array<Hash>]
  #
  def images(size_requested = 'all')
    Array.wrap(@record['ImageInfo']).map { |image|
      if (size_requested == 'all') || (size_requested == image['Size'])
        { size: image['Size'], src: image['Target'] }
      end
    }.compact
  end
=end

=begin # NOTE: using base version
  # Related ISBNs.
  #
  # @return [Array<String>, nil]
  #
  def item_related_isbns
    isbns = get_item_data(label: 'Related ISBNs')
    isbns&.split(' ')&.map{ |item| item.sub(/\.$/, '') }
  end
=end

  # ===========================================================================
  # LINK HELPERS
  # ===========================================================================

=begin # NOTE: using base version
  # A list of all available links.
  #
  # @return [Array<Hash>]
  #
  def all_links
    fulltext_links + non_fulltext_links
  end
=end

=begin # NOTE: using base version
  # The first fulltext link.
  #
  # @return [Hash]
  #
  def fulltext_link(type = 'first')
    links = fulltext_links
    links.find { |link| link[:type] == type } || links.first || {}
  end
=end

  # All available fulltext links.
  #
  # @return [Array<Hash>]
  #
  # Default link labels and icons in 'ebsco_eds.fulltext_links':
  # @see config/locales/ebsco_eds.yml
  #
  def fulltext_links

    result = []

    items        = Array.wrap(@record['Items'])
    ebsco_links  = Array.wrap(@record.dig('FullText', 'Links'))
    custom_links = Array.wrap(@record.dig('FullText', 'CustomLinks'))

    result +=
      ebsco_links.map { |link|
        next unless link['Type'] == 'pdflink'
        @eds_pdf_fulltext_available = true
        make_link(__method__, 'pdf', true, link['Url'])
      }.compact

    result +=
      ebsco_links.map { |link|
        next unless link['Type'] == (type = 'ebook-pdf')
        @eds_ebook_pdf_fulltext_available = true
        make_link(__method__, type, true, link['Url'])
      }.compact

    result +=
      ebsco_links.map { |link|
        next unless link['Type'] == (type = 'ebook-epub')
        @eds_ebook_epub_fulltext_available = true
        make_link(__method__, type, true, link['Url'])
      }.compact

    result +=
      items.map { |item|
        next unless item['Group'] == 'URL'
        data  = item['Data']
        label = item['Label']
        link_term = 'linkTerm=&quot;'
        if data.include?(link_term)
          url_start = data.index(link_term) + 15
          link_url  = data[url_start..-1]
          url_end   = link_url.index('&quot;') - 1
          link_url  = link_url[0..url_end]
          unless (link_label = label)
            label_start = data.index('link&gt;') + 8
            link_label  = data[label_start..-1].strip
          end
        else
          link_url   = data
          link_label = label
        end
        make_link(__method__, 'cataloglink', false, link_url, link_label)
      }.compact

    result +=
      ebsco_links.map { |link|
        next unless link['Type'] == 'other'
        @eds_pdf_fulltext_available = true
        make_link(__method__, 'smartlinks', false, link['Url'])
      }.compact

    result +=
      custom_links.map { |link|
        make_link(__method__, 'customlink-fulltext', false, link)
      }.compact

    result << make_link(__method__, 'html', false) if html_fulltext_available

    result

  end

  # All available non-fulltext links.
  #
  # @return [Array<Hash>]
  #
  def non_fulltext_links
    Array.wrap(@record['CustomLinks']).map { |link|
      make_link(__method__, 'customlink-other', false, link)
    }.compact
  end

  # make_link
  #
  # @param [Array] args
  #   arg[0]  I18n scope  [Symbol, String]
  #   arg[1]  Type        [String]
  #   arg[2]  Expires     [Boolean]
  #   arg[3]  URL         [String, Array<String,String,String>, Hash]
  #   arg[4]  Label       (if URL is a String)
  #   arg[5]  Icon        (if URL is a String)
  #
  # @return [Hash]
  #
  def make_link(*args)
    i18n_scope, type, expires, lnk, label, icon = args
    case lnk
      when Hash  then url, label, icon = lnk['Url'], lnk['Text'], lnk['Icon']
      when Array then url, label, icon = lnk
      else            url = lnk
    end
    unless i18n_scope.to_s.include?('.')
      i18n_scope = 'ebsco_eds' + (i18n_scope ? ".#{i18n_scope}" : '')
      i18n_scope += '.' + type.to_s.underscore
    end
    url     ||= 'detail'
    label   ||= I18n.t('label', scope: i18n_scope, default: url)
    icon    ||= I18n.t('icon',  scope: i18n_scope)
    expires ||= false
    { url: url, label: label, icon: icon, type: type, expires: expires }
  end

  # ===========================================================================
  # BIB ENTITY
  # ===========================================================================

=begin # NOTE: using base version
  # bib_title
  #
  # @return [String, nil]
  #
  def bib_title
    titles = @bib_entity&.fetch('Titles', nil)&.presence
    titles&.find { |item| item['Type'] == 'main' }&.fetch('TitleFull', nil)
  end
=end

=begin # NOTE: using base version
  # bib_authors
  #
  # @return [String, nil]
  #
  # @see self#bib_authors_list
  #
  def bib_authors
    bib_authors_list&.join('; ')
  end
=end

=begin # NOTE: using base version
  # bib_authors_list
  #
  # @return [Array<String>, nil]
  #
  def bib_authors_list
    @bib_relationships&.deep_find('NameFull')
  end
=end

=begin # NOTE: using base version
  # bib_subjects
  #
  # @return [Array<String>, nil]
  #
  def bib_subjects
    @bib_entity&.deep_find('SubjectFull')
  end
=end

=begin # NOTE: using base version
  # bib_languages
  #
  # @return [Array<String>, nil]
  #
  def bib_languages
    langs = @bib_entity&.fetch('Languages', nil)&.presence
    langs&.map { |lang| lang['Text'].presence }&.compact
  end
=end

=begin # NOTE: using base version
  # bib_page_count
  #
  # @return [String, nil]
  #
  def bib_page_count
    @bib_entity&.deep_find('PageCount')&.first
  end
=end

=begin # NOTE: using base version
  # bib_page_start
  #
  # @return [String, nil]
  #
  def bib_page_start
    @bib_entity&.deep_find('StartPage')&.first
  end
=end

=begin # NOTE: using base version
  # bib_doi
  #
  # @return [String, nil]
  #
  def bib_doi
    ids = @bib_entity&.fetch('Identifiers', nil)&.presence
    ids&.find { |item| item['Type'] == 'doi' }&.fetch('Value', nil)
  end
=end

  # ===========================================================================
  # BIB - IS PART OF (journal, book)
  # ===========================================================================

=begin # NOTE: using base version
  # bib_source_title
  #
  # @return [String, nil]
  #
  def bib_source_title
    titles = @bib_part&.dig('BibEntity', 'Titles')&.presence
    titles&.find { |item| item['Type'] == 'main' }&.fetch('TitleFull', nil)
  end
=end

  # bib_issn_print
  #
  # @return [String, nil]
  #
  def bib_issn_print
    get_bib_identifier_values('issn-print').first
  end

  # bib_issn_electronic
  #
  # @return [String, nil]
  #
  # NOTE: 0% coverage for this method
  #
  def bib_issn_electronic
    get_bib_identifier_values('issn-electronic').first
  end

  # bib_issns
  #
  # @return [Array<String>]
  #
  def bib_issns
    get_bib_identifier_values('issn', except: 'locals')
  end

  # bib_isbn_print
  #
  # @return [String, nil]
  #
  def bib_isbn_print
    get_bib_identifier_values('isbn-print').first
  end

  # bib_isbn_electronic
  #
  # @return [String, nil]
  #
  def bib_isbn_electronic
    get_bib_identifier_values('isbn-electronic').first
  end

  # bib_issns
  #
  # @return [Array<String>]
  #
  def bib_isbns
    get_bib_identifier_values('isbn', except: 'locals')
  end

  # get_bib_identifier_values
  #
  # @param [String]    only           E.g.: 'isbn', 'issn'
  # @param [Hash, nil] opt
  #
  # @option opt [String] :except
  #
  # @return [Array<String>]
  #
  def get_bib_identifier_values(only, opt = nil)
    only   = only&.to_s
    except = (opt[:except].presence if opt.is_a?(Hash))
    get_bib_identifiers.map { |id|
      type = id['Type'].to_s
      next if only   && !only.include?(type)
      next if except && type.include?(except)
      id['Value']
    }.compact
  end

  # get_bib_identifiers
  #
  # @return [Array<Hash>]
  #
  def get_bib_identifiers
    @bib_identifiers ||= Array.wrap(@bib_part&.dig('BibEntity', 'Identifiers'))
  end

  # bib_publication_date
  #
  # @param [String, nil] format       Sprintf format used to render the date.
  #
  # @return [String, nil]
  #
  # @see self#PUB_DATE_KEYS
  #
  # Default format taken from 'ebsco_eds.bib_publication_date.format':
  # @see config/locales/ebsco_eds.yml
  #
  def bib_publication_date(format = nil)
    date = get_bib_pub_date
    return if PUB_DATE_KEYS.any? { |k| date[k].blank? }
    format ||=
      I18n.t('ebsco_eds.bib_publication_date.format', default: '%d-%d-%d')
    format % date.slice(*PUB_DATE_KEYS).values.map(&:to_i)
  end

  # bib_publication_year
  #
  # @return [String, nil]
  #
  def bib_publication_year
    get_bib_pub_date['Y'].presence
  end

  # bib_publication_month
  #
  # @return [String, nil]
  #
  # NOTE: 0% coverage for this method
  #
  def bib_publication_month
    get_bib_pub_date['M'].presence
  end

  # get_bib_pub_date
  #
  # @return [Hash]                    Empty if no dates were found.
  #
  def get_bib_pub_date
    @bib_pub_date ||=
      begin
        dates = @bib_part&.dig('BibEntity', 'Dates')&.presence
        dates&.find { |item| item['Type'] == 'published' } || {}
      end
  end

=begin # NOTE: using base version
  # bib_volume
  #
  # @return [String, nil]
  #
  def bib_volume
    num = @bib_part&.dig('BibEntity', 'Numbering')&.presence
    num&.find { |item| item['Type'] == 'volume' }&.fetch('Value', nil)
  end
=end

=begin # NOTE: using base version
  # bib_issue
  #
  # @return [String, nil]
  #
  def bib_issue
    num = @bib_part&.dig('BibEntity', 'Numbering')&.presence
    num&.find { |item| item['Type'] == 'issue' }&.fetch('Value', nil)
  end
=end

=begin # NOTE: using base version

  TO_ATTR_HASH_SKIP =
    %i(@record @items @bib_entity @bib_part @bib_relationships)

  # to_attr_hash
  #
  # @return [Hash]
  #
  def to_attr_hash
    full_text = {
      'id'    => @eds_database_id + '__' + @eds_accession_number,
      'links' => all_links
    }
    instance_variables.map { |var|
      next if TO_ATTR_HASH_SKIP.include?(var)
      [var.to_s.sub(/^@/, ''), instance_variable_get(var)]
    }.compact.to_h.merge('eds_full_text_link' => full_text)
  end
=end

=begin # NOTE: using base version
  # to_solr
  #
  # @return [Hash]
  #
  def to_solr
    {
      'responseHeader' => {
        'status' => 0
      },
      'response' => {
        'numFound' => 1,
        'start'    => 0,
        'docs'     => [to_attr_hash]
      }
    }
  end
=end

  # ===========================================================================
  # ITEM DATA HELPERS
  # ===========================================================================

=begin # NOTE: using base version
  # get_item_data
  #
  # @param [Hash] options
  #
  # @return [String, nil]
  #
  def get_item_data(options)
    return unless @items.present?
    name  = options[:name]
    label = options[:label]
    group = options[:group]
    if name && label && group
      @items.each do |item|
        if item.slice('Name', 'Label', 'Group').values == [name, label, group]
          return sanitize_data(item)
        end
      end
    elsif name && label
      @items.each do |item|
        if item.slice('Name', 'Label').values == [name, label]
          return sanitize_data(item)
        end
      end
    elsif name && group
      @items.each do |item|
        if item.slice('Name', 'Group').values == [name, group]
          return sanitize_data(item)
        end
      end
    elsif label && group
      @items.each do |item|
        if item.slice('Label', 'Group').values == [label, group]
          return sanitize_data(item)
        end
      end
    elsif label
      @items.each do |item|
        if item['Label'] == label
          return sanitize_data(item)
        end
      end
    elsif name
      @items.each do |item|
        if item['Name'] == name
          return sanitize_data(item)
        end
      end
    end
    nil
  end
=end

=begin # NOTE: using base version
  # Decode & sanitize HTML tags found in item data; apply any special
  # transformations.
  #
  # @param [Hash] item
  #
  # @return [String, nil]
  #
  def sanitize_data(item)
    return unless (data = item['Data']).present?

    # Group-specific transformations.
    if (group = item['Group']) && (group == 'Su')
      # Translate searchLink field codes to DE?
      if @all_subjects_search_links
        data = data.gsub(/(searchLink fieldCode=&quot;)([A-Z]+)/, '\1DE')
      end
    end

    # Decode-sanitize?
    @decode_sanitize_html ? html_decode_and_sanitize(data) : data
  end
=end

  # Decode any HTML elements and then run it through sanitize to preserve
  # entities (e.g.: ampersand) and strip out elements/attributes that aren't
  # explicitly whitelisted.
  #
  # @param [String]                data
  # @param [Sanitize::Config, nil] sanitize_config  Default: #SANITIZE_CONFIG
  #
  # @return [String]
  #
  # @see self#SANITIZE_CONFIG
  #
  def html_decode_and_sanitize(data, sanitize_config = nil)
    data = CGI.unescapeHTML(data.to_s)
    sanitize_config ||= SANITIZE_CONFIG
    Sanitize.fragment(data, sanitize_config)
  end

=begin # NOTE: using base version
  # Dynamically add item metadata as 'eds_extra_ItemNameOrLabel'.
  #
  # @param [Hash] item
  #
  def add_extra_item_accessors(item)
    name  = item['Name']
    label = item['Label']
    value = item['Data']
    key   = (name || label).gsub(/\s+/, '_')
    # NumberOther isn't always unique, concatenate the label.
    if (key == 'NumberOther') || (key == 'Number_Other')
      key = 'number_other_' + label.gsub(/\s+/, '_')
    end
    key = "eds_extras_#{key}"
    unless value.nil?
      class_eval { attr_accessor key }
      instance_variable_set "@#{key}", CGI.unescapeHTML(value)
    end
  end
=end

end
