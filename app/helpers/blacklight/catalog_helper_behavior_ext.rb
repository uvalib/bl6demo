# app/helpers/blacklight/catalog_helper_behavior_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Blacklight::CatalogHelperBehaviorExt
#
# @see Blacklight::CatalogHelperBehavior
#
# Some methods are overridden by:
# @see BlacklightAdvancedSearch::CatalogHelperOverrideExt
#
module Blacklight::CatalogHelperBehaviorExt

  include Blacklight::CatalogHelperBehavior
  include LensHelper

  # ===========================================================================
  # :section: Blacklight::CatalogHelperBehavior overrides
  # ===========================================================================

  public

=begin # NOTE: using base version
  # rss_feed_link_tag
  #
  # @param [Hash] options
  #
  # @option options :route_set the route scope to use when constructing the link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::CatalogHelperBehavior#rss_feed_link_tag
  #
  def rss_feed_link_tag(options = nil)
    url = feed_link_url('rss', options)
    opt = { title: t('blacklight.search.rss_feed') }
    auto_discovery_link_tag(:rss, url, opt)
  end
=end

=begin # NOTE: using base version
  # atom_feed_link_tag
  #
  # @param [Hash] options
  #
  # @option options :route_set the route scope to use when constructing the link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::CatalogHelperBehavior#atom_feed_link_tag
  #
  def atom_feed_link_tag(options = nil)
    url = feed_link_url('atom', options)
    opt = { title: t('blacklight.search.atom_feed') }
    auto_discovery_link_tag(:atom, url, opt)
  end
=end

=begin # NOTE: using base version
  # json_api_link_tag
  #
  # @param [Hash] options
  #
  # @option options :route_set the route scope to use when constructing the link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::CatalogHelperBehavior#json_api_link_tag
  #
  def json_api_link_tag(options = nil)
    url = feed_link_url('json', options)
    opt = { type: 'application/json' }
    auto_discovery_link_tag(:json, url, opt)
  end
=end

=begin # NOTE: using base version
  # Override the Kaminari page_entries_info helper with our own,
  # Blacklight-aware implementation.
  #
  # Displays the "showing X through Y of N" message.
  #
  # @param [RSolr::Resource] collection (or other Kaminari-compatible objects)
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::CatalogHelperBehavior#page_entries_info
  #
  def page_entries_info(collection, options = nil)

    return unless show_pagination?(collection)

    options ||= {}
    entry_name =
      if options[:entry_name]
        options[:entry_name]
      elsif collection.respond_to?(:model)  # DataMapper
        collection.model.model_name.human.downcase
      elsif collection.respond_to?(:model_name) && collection.model_name # AR, Blacklight::PaginationMethods
        collection.model_name.human.downcase
      else
        t('blacklight.entry_name.default')
      end
    total = collection.total_count
    entry_name = entry_name.pluralize unless total == 1

    # Grouped response objects need special handling.
    end_num =
      if collection.respond_to?(:groups) && render_grouped_response?(collection)
        collection.groups.length
      else
        collection.limit_value
      end
    offset  = collection.offset_value + end_num
    end_num = [offset, total].min

    t_key =
      case total
        when 0 then 'no_items_found'
        when 1 then 'single_item_found'
        else        'pages'
      end
    t_key = "blacklight.search.pagination_info.#{t_key}"
    t_opt = { entry_name: entry_name }
    t_opt.merge!(
      current_page: collection.current_page,
      num_pages:    total,
      start_num:    number_with_delimiter(collection.offset_value + 1),
      end_num:      number_with_delimiter(end_num),
      total_num:    number_with_delimiter(total),
      count:        total,
    ) if total > 1
    t(t_key, t_opt)

  end
=end

=begin # NOTE: using base version
  # Get the offset counter for a document
  #
  # @param [Integer] idx document index
  # @param [Integer] offset additional offset to increment the counter by
  #
  # @return [Integer]
  #
  # This method overrides:
  # @see Blacklight::CatalogHelperBehavior#document_counter_with_offset
  #
  def document_counter_with_offset(idx, offset = nil)
    offset ||= @response.start if @response
    idx + 1 + offset.to_i unless render_grouped_response?
  end
=end

=begin # NOTE: using base version
  # Like #page_entries_info above, but for an individual
  # item show page. Displays "showing X of Y items" message.
  #
  # @return [String]
  #
  # @see self#page_entries_info
  #
  # This method overrides:
  # @see Blacklight::CatalogHelperBehavior#item_page_entry_info
  #
  def item_page_entry_info
    t(
      'blacklight.search.entry_pagination_info.other',
      current: number_with_delimiter(search_session['counter']),
      total:   number_with_delimiter(search_session['total']),
      count:   search_session['total'].to_i
    ).html_safe
  end
=end

=begin # NOTE: using base version
  # Look up search field user-displayable label
  # based on params[:qt] and blacklight_configuration.
  #
  # @param [ActionController::Parameters] params
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::CatalogHelperBehavior#search_field_label
  #
  def search_field_label(params)
    h(label_for_search_field(params[:search_field]))
  end
=end

  # Look up the current sort field, or provide the default if none is set.
  #
  # @return [Blacklight::Configuration::SortField]
  #
  # This method overrides:
  # @see Blacklight::CatalogHelperBehavior#current_sort_field
  #
  def current_sort_field
    entry = nil
    sort_fields = blacklight_config.sort_fields
    [@response&.sort, params[:sort]].find { |sort|
      next if sort.blank?
      entry = sort_fields.find { |k, f| (k == sort) || (f.sort == sort) }
    }
    entry ||= sort_fields.first
    entry.last
  end

=begin # NOTE: using base version
  # Look up the current per page value, or the default if none if set.
  #
  # @return [Integer]
  #
  # This method overrides:
  # @see Blacklight::CatalogHelperBehavior#current_per_page
  #
  def current_per_page
    rows = @response&.rows || 0
    (rows unless rows.zero?) || params.fetch(:per_page, default_per_page).to_i
  end
=end

  # Get the classes to add to a document's div.
  #
  # @param [Blacklight::Document, nil] doc
  #
  # @return [String, nil]
  #
  # This method overrides:
  # @see Blacklight::CatalogHelperBehavior#render_document_class
  #
  def render_document_class(doc = nil)
    doc ||= @document
    config = doc && blacklight_config(doc)
    field  = config&.view_config(document_index_view_type)&.display_type_field
    types  = field && Array.wrap(doc[field])
    return unless types.present?
    types.map { |type|
      type = type.parameterize if type.respond_to?(:parameterize)
      "#{document_class_prefix}#{type}"
    }.join(' ')
  end

=begin # NOTE: using base version
  # document_class_prefix
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::CatalogHelperBehavior#document_class_prefix
  #
  def document_class_prefix
    'blacklight-'
  end
=end

  # Render the sidebar partial for a document.
  #
  # @param [Blacklight::Document, nil] _doc    Unused.
  # @param [Hash, nil]                 locals
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  # This method overrides:
  # @see Blacklight::CatalogHelperBehavior#render_document_sidebar_partial
  #
  def render_document_sidebar_partial(_doc = nil, locals = nil)
    render_template('show_sidebar', locals)
  end

  # Render the main content partial for a document.
  #
  # @param [Blacklight::Document, nil] _doc    Unused.
  # @param [Hash, nil]                 locals
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  # This method overrides:
  # @see Blacklight::CatalogHelperBehavior#render_document_main_content_partial
  #
  def render_document_main_content_partial(_doc = nil, locals = nil)
    render_template('show_main_content', locals)
  end

=begin # NOTE: using base version
  # Should we display the sort and per page widget?
  #
  # @param [Blacklight::Solr::Response] response
  #
  # This method overrides:
  # @see Blacklight::CatalogHelperBehavior#show_sort_and_per_page?
  #
  def show_sort_and_per_page?(response = nil)
    (response || @response).present?
  end
=end

=begin # NOTE: using base version
  # Should we display the pagination controls?
  #
  # @param [Blacklight::Solr::Response] response
  #
  # This method overrides:
  # @see Blacklight::CatalogHelperBehavior#show_pagination?
  #
  def show_pagination?(response = nil)
    (response || @response).limit_value > 0
  end
=end

=begin # NOTE: using base version
  # If no search parameters have been given, we should auto-focus the user's
  # cursor into the search box.
  #
  # This method overrides:
  # @see Blacklight::CatalogHelperBehavior#should_autofocus_on_search_box?
  #
  def should_autofocus_on_search_box?
    controller.is_a?(Blacklight::Catalog) &&
      (action_name == 'index') &&
      !has_search_parameters?
  end
=end

  # Does the document have a thumbnail to render?
  #
  # @param [Blacklight::Document, nil] doc
  #
  # This method overrides:
  # @see Blacklight::CatalogHelperBehavior#has_thumbnail?
  #
  def has_thumbnail?(doc = nil)
    doc ||= @document
    bl_config   = blacklight_config(doc)
    view_type   = document_index_view_type # TODO: lens?
    view_config = bl_config.view_config(view_type)
    view_config.thumbnail_method.present? ||
      Array.wrap(view_config.thumbnail_field).any? { |field| doc.has?(field) }
  end

  # Render the thumbnail, if available, for a document and link it to the
  # document record.
  #
  # @param [Blacklight::Document] doc         Default: @document.
  # @param [Hash]                 image_opt   For `image_tag`.
  # @param [Hash, FalseClass]     url_opt     For #link_to_document.
  #
  # @options url_opt [Boolean] :suppress_link
  #
  # @return [ActiveSupport::SafeBuffer, String, nil]
  #
  # This method overrides:
  # @see Blacklight::CatalogHelperBehavior#render_thumbnail_tag
  #
  def render_thumbnail_tag(doc = nil, image_opt = nil, url_opt = nil)
    doc ||= @document
    return unless doc.is_a?(Blacklight::Document)
    if url_opt.is_a?(FalseClass) # NOTE: 0% coverage for this case
      Deprecation.warn(self,
        'passing false as the second argument to render_thumbnail_tag is ' \
        'deprecated. Use suppress_link: true instead. This behavior will ' \
        'be removed in Blacklight 7'
      )
      url_opt = { suppress_link: true }
    end
    view_config = blacklight_config(doc).view_config(document_index_view_type)
    value =
      if view_config.thumbnail_method # NOTE: 0% coverage for this case
        send(view_config.thumbnail_method, doc, image_opt)
      elsif (url = thumbnail_url(doc))
        image_tag(url, image_opt)
      end
    if url_opt[:suppress_link] # NOTE: 0% coverage for this case
      value
    elsif value
      link_to_document(doc, value, url_opt)
    end
  end

  # Get the URL to a document's thumbnail image.
  #
  # @param [Blacklight::Document, nil] doc    Default: @document.
  #
  # @return [String, nil]
  #
  # This method overrides:
  # @see Blacklight::CatalogHelperBehavior#thumbnail_url
  #
  def thumbnail_url(doc = nil)
    doc ||= @document
    return unless doc.is_a?(Blacklight::Document)
    bl_config   = blacklight_config(doc)
    view_type   = document_index_view_type # TODO: lens?
    view_config = bl_config.view_config(view_type)
    field = Array.wrap(view_config.thumbnail_field).find { |f| doc.has?(f) }
    Array.wrap(doc[field]).first if field
  end

=begin # NOTE: using base version
  # Render the view type icon for the results view picker.
  #
  # @param [String] view
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::CatalogHelperBehavior#render_view_type_group_icon
  #
  def render_view_type_group_icon(view)
    icon_class = blacklight_config.view[view].icon_class
    icon_class ||= default_view_type_group_icon_classes(view)
    content_tag(:span, '', class: "glyphicon #{icon_class}")
  end
=end

=begin # NOTE: using base version
  # Get the default view type classes for a view in the results view picker
  #
  # @param [String] view
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::CatalogHelperBehavior#default_view_type_group_icon_classes
  #
  def default_view_type_group_icon_classes(view)
    view = view.to_s.parameterize
    "glyphicon-#{view} view-icon-#{view}"
  end
=end

  # current_bookmarks
  #
  # @param [Blacklight::Solr::Response, nil] resp   Default: @response.
  #
  # @return [Array<Bookmark>]
  #
  # This method overrides:
  # @see Blacklight::CatalogHelperBehavior#current_bookmarks
  #
  def current_bookmarks(resp = nil)
    @current_bookmarks ||=
      (resp ||= (@response if defined?(@response))) &&
      current_or_guest_user.bookmarks_for_documents(resp.documents).to_a
  end

  # Check if the document is in the user's bookmarks.
  #
  # @param [Blacklight::Document, nil]       doc    Default: @document.
  # @param [Blacklight::Solr::Response, nil] resp   Default: @response.
  #
  # This method overrides:
  # @see Blacklight::CatalogHelperBehavior#bookmarked?
  #
  def bookmarked?(doc = nil, resp = nil)
    doc ||= @document
    return unless doc.is_a?(Blacklight::Document)
    current_bookmarks(resp).any? do |record|
      (record.document_id == doc.id) && (record.document_type == doc.class)
    end
  end

=begin # NOTE: using base version
  # render_search_to_page_title_filter
  #
  # @param [?] facet
  # @param [?] values
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::CatalogHelperBehavior#render_search_to_page_title_filter
  #
  def render_search_to_page_title_filter(facet, values)
    facet_config = facet_configuration_for_field(facet)
    filter_label = facet_field_label(facet_config.key)
    filter_value =
      if values.size < 3
        values.map { |value| facet_display_value(facet, value) }.to_sentence
      else
        t('blacklight.search.page_title.many_constraint_values', values: values.size)
      end
    t('blacklight.search.page_title.constraint', label: filter_label, value: filter_value)
  end
=end

=begin # NOTE: using base version
  # render_search_to_page_title
  #
  # @param [ActionController::Parameters] params
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::CatalogHelperBehavior#render_search_to_page_title
  #
  def render_search_to_page_title(params)

    q  = params[:q]
    f  = params[:f]
    sf = params[:search_field]

    constraints = []
    if q.present?
      label =
        unless sf == default_search_field.key)
          label_for_search_field(sf)
        end
      constraints <<
        if label.present?
          t('blacklight.search.page_title.constraint', label: label, value: q)
        else
          q
        end
    end
    if f.present?
      constraints +=
        f.to_unsafe_h.map { |k, v| render_search_to_page_title_filter(k, v) }
    end
    constraints.join(' / ')

  end
=end

  # ===========================================================================
  # :section: Blacklight::CatalogHelperBehavior overrides
  # ===========================================================================

  private

=begin # NOTE: using base version
  # feed_link_url
  #
  # @param [String] format
  # @param [Hash]   options
  #
  # @option options :route_set the route scope to use when constructing the link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::CatalogHelperBehavior#feed_link_url
  #
  def feed_link_url(format, options = nil)
    url_opt = search_state.to_h.merge(format: format)
    scope   = (options[:route_set] if options.present?) || self
    scope.url_for(url_opt)
  end
=end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # rss_button
  #
  # @param [Hash, nil] options
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def rss_button(options = nil)
    opt = { class: 'rss-link', title: 'RSS' }
    opt.merge!(options) if options.is_a?(Hash)
    label = opt.delete(:label) || ''
    label = content_tag(:div, label, class: 'fa fa-rss')
    url =
      opt.delete(:url) ||
      url_for(search_state.params_for_search(format: 'rss').except(:page))
    $stderr.puts(">>> #{__method__}: #{url.inspect}")
    outlink(label, url, opt)
  end

  # atom_button
  #
  # @param [Hash, nil] options
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # NOTE: 0% coverage for this method
  #
  def atom_button(options = nil)
    opt = { class: 'atom-link', title: 'Atom' }
    opt.merge!(options) if options.is_a?(Hash)
    label = opt.delete(:label) || ''
    label = content_tag(:div, label, class: 'fa fa-rss')
    url =
      opt.delete(:url) ||
      url_for(search_state.params_for_search(format: 'atom').except(:page))
    $stderr.puts(">>> #{__method__}: #{url.inspect}")
    outlink(label, url, opt)
  end

  # print_view_button
  #
  # @param [Hash, nil] options
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def print_view_button(options = nil)
    opt = { class: 'print-view-link', title: 'Print view' }
    opt.merge!(options) if options.is_a?(Hash)
    label = opt.delete(:label) || ''
    label = content_tag(:div, label, class: 'glyphicon glyphicon-print')
    url   = opt.delete(:url)
    url ||= url_for(search_state.params_for_search(view: 'print'))
    $stderr.puts(">>> #{__method__}: #{url.inspect}")
    outlink(label, url, opt)
  end

end

__loading_end(__FILE__)
