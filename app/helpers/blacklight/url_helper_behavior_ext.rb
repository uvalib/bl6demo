# app/helpers/blacklight/url_helper_behavior_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Blacklight::UrlHelperBehaviorExt
#
# @see Blacklight::UrlHelperBehavior
#
module Blacklight::UrlHelperBehaviorExt

  include Blacklight::UrlHelperBehavior

  include LensHelper

  # ===========================================================================
  # :section: Blacklight::UrlHelperBehavior overrides
  # ===========================================================================

  public

=begin # NOTE: using base version
  # Extension point for downstream applications to provide more interesting
  # routing to documents.
  #
  # @param [Blacklight::Document] doc
  # @param [Hash]                 options
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::UrlHelperBehavior#url_for_document
  #
  def url_for_document(doc, options = nil)
    options ||= {}
    search_state.url_for_document(doc, options)
  end
=end

=begin # NOTE: using base version
  # link_to_document(doc, 'VIEW', :counter => 3)
  # Use the catalog_path RESTful route to create a link to the show page for a
  # specific item.
  #
  # catalog_path accepts a hash.
  #
  # The Solr query params are stored in the session, so we only need the
  # *counter* param here.
  #
  # We also need to know if we are viewing to document as part of search
  # results.
  #
  # @param [Blacklight::Document] doc
  # @param [Symbol, String]       field_or_opts
  # @param [Hash]                 opts
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::UrlHelperBehavior#link_to_document
  #
  def link_to_document(doc, field_or_opts = nil, opts = nil)
    if field_or_opts.is_a?(Hash)
      field = nil
      opts  = field_or_opts
    else
      field = field_or_opts
    end
    field ||= document_show_link_field(doc)
    opts  ||= {}

    label = index_presenter(doc).label(field, opts)
    url   = url_for_document(doc)
    opts  = document_link_params(doc, opts)
    link_to(label, url, opts)
  end
=end

=begin # NOTE: using base version
  # document_link_params
  #
  # @param [Blacklight::Document] doc
  # @param [Hash]                 opts
  #
  # @return [Hash]
  #
  # This method overrides:
  # @see Blacklight::UrlHelperBehavior#document_link_params
  #
  def document_link_params(doc, opts = nil)
    opts ||= {}
    counter = opts[:counter]
    opts = opts.except(:label, :counter)
    session_tracking_params(doc, counter).deep_merge(opts)
  end
  protected :document_link_params
=end

  # Link to the previous document in the current search context.
  #
  # @param [Blacklight::Document] doc
  # @param [Hash, nil]            options
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::UrlHelperBehavior#link_to_previous_document
  #
  def link_to_previous_document(doc, options = nil)
    label = t('views.pagination.previous').html_safe
    opt   = { class: 'previous' }
    opt.merge!(options) if options.is_a?(Hash)
    if (url = url_for_document(doc))
      count = search_session['counter'].to_i - 1
      opt.merge!(session_tracking_params(doc, count))
      opt[:rel] = 'prev'
      link_to(label, url, opt)
    else
      opt[:class] += ' disabled'
      opt[:title] = 'Already at the beginning of the list.' # TODO: I18n
      content_tag(:span, label, opt)
    end
  end

  # Link to the next document in the current search context.
  #
  # @param [Blacklight::Document] doc
  # @param [Hash, nil]            options
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::UrlHelperBehavior#link_to_next_document
  #
  def link_to_next_document(doc, options = nil)
    label = t('views.pagination.next').html_safe
    opt   = { class: 'next' }
    opt.merge!(options) if options.is_a?(Hash)
    if (url = url_for_document(doc))
      count = search_session['counter'].to_i + 1
      opt.merge!(session_tracking_params(doc, count))
      opt[:rel] = 'next'
      link_to(label, url, opt)
    else # NOTE: 0% coverage for this case
      opt[:class] += ' disabled'
      opt[:title] = 'Already at the end of the list.' # TODO: I18n
      content_tag(:span, label, opt)
    end
  end

=begin # NOTE: using base version
  # Attributes for a link that gives a URL we can use to track clicks for the
  # current search session.
  #
  # @param [Blacklight::Document] document
  # @param [Integer]              counter
  #
  # @return [Hash]
  #
  # @example session_tracking_params(SolrDocument.new(id: 123), 7)
  #   => { data: { :'tracker-href' =>
  #                '/catalog/123/track?counter=7&search_id=999' } }
  #
  # This method overrides:
  # @see Blacklight::UrlHelperBehavior#session_tracking_params
  #
  def session_tracking_params(document, counter)
    path =
      session_tracking_path(
        document,
        per_page:  params.fetch(:per_page, search_session['per_page']),
        counter:   counter,
        search_id: current_search_session.try(:id)
      )
    result = {}
    result[:data] = { 'context-href': path } if path.present?
    result
  end
  protected :session_tracking_params
=end

=begin # NOTE: using base version
  # Get the URL for tracking search sessions across pages using polymorphic
  # routing.
  #
  # @param [Blacklight::Document] document
  # @param [Hash]                 params
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::UrlHelperBehavior#session_tracking_path
  #
  def session_tracking_path(document, params = nil)
    return if document.nil?
    opt = { id: document }
    opt.reverse_merge!(params) if params.present?
    if respond_to?(:controller_tracking_method)
      send(controller_tracking_method, opt)
    else
      blacklight.track_search_context_path(opt)
    end
  end
=end

  # controller_tracking_method
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::UrlHelperBehavior#controller_tracking_method
  #
  def controller_tracking_method
    "track_#{current_lens.key}_path"
  end

  # ===========================================================================
  # :section: Blacklight::UrlHelperBehavior overrides
  # link based helpers ->
  # ===========================================================================

  public

=begin # NOTE: using base version
  # Create link to query (e.g. spelling suggestion).
  #
  # @param [String] query
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::UrlHelperBehavior#link_to_query
  #
  def link_to_query(query)
    opt  = search_state.to_h.except(:page, :action).merge(q: query)
    path = search_action_path(opt)
    link_to(query, path)
  end
=end

=begin # NOTE: using base version
  # Get the path to the search action with any parameters (e.g. view type)
  # that should be persisted across search sessions.
  #
  # @param [Hash] query_params
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::UrlHelperBehavior#start_over_path
  #
  def start_over_path(query_params = nil)
    query_params ||= params
    view_type = document_index_view_type(query_params)
    opt = {}
    opt[:view] = view_type unless view_type == default_document_index_view_type
    search_action_path(opt)
  end
=end

=begin # NOTE: using base version
  # Create a link back to the index screen, keeping the user's facet, query and
  # paging choices intact by using session.
  #
  # @param [Hash] opts
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @example
  #   link_back_to_catalog(label: 'Back to Search')
  #   link_back_to_catalog(label: 'Back to Search', route_set: my_engine)
  #
  # This method overrides:
  # @see Blacklight::UrlHelperBehavior#link_back_to_catalog
  #
  def link_back_to_catalog(opts = nil)
    opts ||= {}
    scope = opts.delete(:route_set) || self
    query_params = current_search_session.try(:query_params)
    query_params = search_state.reset(query_params).to_hash

    if (counter = search_session['counter'])
      spp = search_session['per_page']
      per_page = (spp || default_per_page).to_i
      query_params[:per_page] = per_page unless spp.to_i == default_per_page
      query_params[:page]     = ((counter.to_i - 1)/ per_page) + 1
    end

    link_url =
      if query_params.empty?
        search_action_path(only_path: true)
      else
        scope.url_for(query_params)
      end

    label = opts.delete(:label)
    label ||= (t('blacklight.back_to_bookmarks') if link_url =~ /bookmarks/)
    label ||= t('blacklight.back_to_search')

    link_to(label, link_url, opts)
  end
=end

=begin # NOTE: using base version
  # Search History and Saved Searches display.
  #
  # @param [Hash]      params
  # @param [Hash, nil] options
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::UrlHelperBehavior#link_to_previous_search
  #
  def link_to_previous_search(params, options = nil)
    opt = { class: 'search-link' }
    opt.merge!(options) if options.is_a?(Hash)
    link_to(render_search_to_s(params), search_action_path(params), opt)
  end
=end

=begin # NOTE: using base version
  # Get URL parameters to a search within a grouped result set.
  #
  # @param [Blacklight::Solr::Response::Group] group
  #
  # @return [Hash]
  #
  # This method overrides:
  # @see Blacklight::UrlHelperBehavior#add_group_facet_params_and_redirect
  #
  def add_group_facet_params_and_redirect(group)
    search_state.add_facet_params_and_redirect(group.field, group.key)
  end
=end

=begin # NOTE: using base version
  # A URL to RefWorks export, with an embedded callback URL to this app.
  #
  # The callback URL is to bookmarks#export, which delivers a list of the
  # user's bookmarks in 'refworks marc txt' format -- we tell RefWorks to
  # expect that format.
  #
  # @param [String] format
  # @parma [Hash]   params
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::UrlHelperBehavior#bookmarks_export_url
  #
  def bookmarks_export_url(format, params = nil)
    opt = {
      format:            format,
      encrypted_user_id: encrypt_user_id(current_or_guest_user.id)
    }
    opt.reverse_merge!(params) if params.present?
    bookmarks_url(opt)
  end
=end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # To be used in place of #opensearch_catalog_url.
  #
  # @param [Hash, nil] options
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # == Implementation Notes
  # Because this is being called from the layout and not from an action
  # template, #url_for is actually ActionView::RoutingUrlFor#url_for rather
  # than ActionDispatch::Routing::UrlFor#url_for.
  #
  # This variant was causing a crash when trying to sign in because the current
  # controller ("/devise/sessions") was resulting in the requested path for
  # `{ controller: 'catalog', action: 'opensearch' }` to be interpreted as
  # `{ controller: '/devise/catalog', action: 'opensearch' }`.
  #
  # Prefixing the controller name with '/' avoids that interpretation.
  #
  def opensearch_url(options = nil)
    opt = search_state.to_h.merge(only_path: false)
    opt.merge!(options) if options.present?
    opt.merge!(controller: "/#{current_lens_key}", action: 'opensearch')
    url_for(opt)
  end

end

__loading_end(__FILE__)
