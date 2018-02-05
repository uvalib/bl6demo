# app/helpers/blacklight/render_partials_helper_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Blacklight::RenderPartialsHelperExt
#
# @see Blacklight::RenderPartialsHelper
#
module Blacklight::RenderPartialsHelperExt

  include Blacklight::RenderPartialsHelper
  include LensHelper

  # ===========================================================================
  # :section: Blacklight::RenderPartialsHelper overrides
  # ===========================================================================

  public

=begin # NOTE: using base version
  # Render the document index view
  #
  # @param [Array<Blacklight::Document>] docs    List of documents to render.
  # @param [Hash]                        locals  To pass to the render call.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::RenderPartialsHelper#render_document_index
  #
  def render_document_index(docs = nil, locals = nil)
    docs   ||= @document_list
    locals ||= {}
    render_document_index_with_view(document_index_view_type, docs, locals)
  end
=end

  # Render the document index for a grouped response.
  #
  # @param [Hash, nil] locals
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  # This method overrides:
  # @see Blacklight::RenderPartialsHelper#render_grouped_document_index
  #
  # NOTE: 0% coverage for this method
  #
  def render_grouped_document_index(locals = nil)
    render_template('group_default', locals)
  end

=begin # NOTE: using base version
  # Return the list of partials for a given Solr document.
  #
  # @param [Blacklight::Document] doc
  # @param [Array<String>]        partials  List of partials to render.
  # @param [Hash]                 locals    To pass to the render call.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::RenderPartialsHelper#render_document_partials
  #
  def render_document_partials(doc, partials = nil, locals = nil)
    partials ||= []
    locals   ||= {}
    partials.map { |action_name|
      render_document_partial(doc, action_name, locals)
    }.join("\n").html_safe
  end
=end

=begin # NOTE: using base version
  # Given a doc and a base name for a partial, this method will attempt to
  # render an appropriate partial based on the document format and view type.
  #
  # If a partial that matches the document format is not found, render a
  # default partial for the base name.
  #
  # @param [Blacklight::Document] doc
  # @param [String]               base_name  Base name for the partial.
  # @param [Hash]                 locals     To pass to the render call.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see self#document_partial_path_templates
  #
  # This method overrides:
  # @see Blacklight::RenderPartialsHelper#render_document_partial
  #
  def render_document_partial(doc, base_name, locals = nil)
    locals ||= {}
    format   = document_partial_name(doc, base_name)
    type     = document_index_view_type
    view_key = ['show', type, base_name, format].join('_')
    template =
      cached_view(view_key) do
        find_document_show_template_with_view(type, base_name, format, locals)
      end
    if template
      template.render(self, locals.merge(document: doc))
    else
      ''.html_safe
    end
  end
=end

=begin # NOTE: using base version
  # Render the document index for the given view type with the list of
  # documents.
  #
  # This method will interpolate the list of templates with the current view,
  # and gracefully handles missing templates.
  #
  # @param [String]              view       Type.
  # @param [Array<SolrDocument>] documents  List of documents to render.
  # @param [Hash]                locals     To pass to the render call.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see self#document_index_path_templates
  #
  # This method overrides:
  # @see Blacklight::RenderPartialsHelper#render_document_index_with_view
  #
  def render_document_index_with_view(view, documents, locals = nil)
    locals ||= {}
    view_key = ['index', view].join('_')
    template =
      cached_view(view_key) do
        find_document_index_template_with_view(view, locals)
      end
    if template
      template.render(self, locals.merge(documents: documents))
    else
      ''.html_safe
    end
  end
=end

  # A list of document partial templates to attempt to render.
  #
  # @return [Array<String>]
  #
  # This method overrides:
  # @see Blacklight::RenderPartialsHelper#document_index_path_templates
  #
  def document_index_path_templates
    @document_index_path_templates ||=
      document_path_templates('document', %w(%{index_view_type} list))
    #
    # === In ArticlesController view:
    #
    # view_subdirs = ['articles', nil, 'catalog']
    #
    #   articles/document_%{index_view_type}
    #   articles/document_list
    #   document_%{index_view_type}
    #   document_list
    #   catalog/document_%{index_view_type}
    #   catalog/document_list
    #
    # === In CatalogController view:
    #
    # view_subdirs = [nil, 'catalog']
    #
    #   document_%{index_view_type}
    #   document_list
    #   catalog/document_%{index_view_type}
    #   catalog/document_list
    #
    # === In BookmarksController view:
    #
    # view_subdirs = [nil, 'catalog']
    #
    #   document_%{index_view_type}
    #   document_list
    #   catalog/document_%{index_view_type}
    #   catalog/document_list
    #
  end

  # ===========================================================================
  # :section: Blacklight::RenderPartialsHelper overrides
  # ===========================================================================

  protected

=begin # NOTE: using base version
  # Return a partial name for rendering a document
  # this method can be overridden in order to transform the value
  #   (e.g. 'PdfBook' => 'pdf_book')
  #
  # @param [Blacklight::Document] document
  # @param [String, Array]        display_type A value suggestive of a partial.
  #
  # @return [String]                  The name of the partial to render.
  #
  # @example
  #  type_field_to_partial_name(['a book-article'])
  #  => 'a_book_article'
  #
  # This method overrides:
  # @see Blacklight::RenderPartialsHelper#type_field_to_partial_name
  #
  if Rails.version >= '5.0.0'
    def type_field_to_partial_name(document, display_type)
      # Using "_" as separator to more closely follow the views file naming
      # conventions.  Parameterize uses '-' as the default separator which
      # throws errors.
      underscore = '_'
      Array(display_type)
        .join(' ')
        .tr('-', underscore)
        .parameterize(separator: underscore)
    end
  else
    def type_field_to_partial_name(document, display_type)
      # Using "_" as separator to more closely follow the views file naming
      # conventions.  Parameterize uses '-' as the default separator which
      # throws errors.
      underscore = '_'
      Array(display_type)
        .join(' ')
        .tr('-', underscore)
        .parameterize(underscore)
    end
  end
=end

  # Return a normalized partial name for rendering a single document.
  #
  # @param [Blacklight::Document] doc
  # @param [Symbol]               base_name   Base name for the partial.
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::RenderPartialsHelper#document_partial_name
  #
  def document_partial_name(doc, base_name = nil)
    view = blacklight_config(doc).view_config(:show)
    key  = base_name && view[:"#{base_name}_display_type_field"].presence
    type = (key && doc[key]) || doc[view.display_type_field] || 'default'
    type_field_to_partial_name(doc, type)
  end

  # A list of document partial templates to try to render for a document
  #
  # The partial names will be interpolated with the following variables:
  #   - action_name: (e.g. index, show)
  #   - index_view_type: (the current view type, e.g. list, gallery)
  #   - format: the document's format (e.g. book)
  #
  # @return [Array<String>]
  #
  # This method overrides:
  # @see Blacklight::RenderPartialsHelper#document_partial_path_templates
  #
  def document_partial_path_templates
    @partial_path_templates ||=
      document_path_templates('%{action_name}', %w(%{format} default))
    #
    # === In ArticlesController view:
    #
    # view_subdirs = ['articles', nil, 'catalog']
    #
    #   articles/%{action_name}_%{format}
    #   articles/%{action_name}_default
    #   %{action_name}_%{format}
    #   %{action_name}_default
    #   catalog/%{action_name}_%{format}
    #   catalog/%{action_name}_default
    #
    # === In CatalogController view:
    #
    # view_subdirs = [nil, 'catalog']
    #
    #   %{action_name}_%{format}
    #   %{action_name}_default
    #   catalog/%{action_name}_%{format}
    #   catalog/%{action_name}_default
    #
    # === In BookmarksController view:
    #
    # view_subdirs = [nil, 'catalog']
    #
    #   %{action_name}_%{format}
    #   %{action_name}_default
    #   catalog/%{action_name}_%{format}
    #   catalog/%{action_name}_default
    #
  end

  # ===========================================================================
  # :section: Blacklight::RenderPartialsHelper overrides
  # ===========================================================================

  private

=begin # NOTE: using base version
  # find_document_show_template_with_view
  #
  # @param [String] type       View type.
  # @param [String] base_name
  # @param [String] format
  # @param [Hash]   locals
  #
  # @return [String, nil]
  #
  # This method overrides:
  # @see Blacklight::RenderPartialsHelper#find_document_show_template_with_view
  #
  def find_document_show_template_with_view(type, base_name, format, locals)
    values   = { action_name: base_name, index_view_type: type }
    prefixes = lookup_context.prefixes + ['']
    keys     = locals.keys + [:document]
    document_partial_path_templates.find do |str|
      partial = str % values.merge(format: format)
      logger.debug { "Looking for document partial #{partial}" }
      template = lookup_context.find_all(partial, prefixes, true, keys, {})
      template &&= template.first
      return template if template
    end
  end
=end

=begin # NOTE: using base version
  # find_document_index_template_with_view
  #
  # @param [String] type       View type.
  # @param [String] base_name
  # @param [String] format
  # @param [Hash]   locals
  #
  # @return [String, nil]
  #
  # This method overrides:
  # @see Blacklight::RenderPartialsHelper#find_document_index_template_with_view
  #
  def find_document_index_template_with_view(type, locals)
    values   = { index_view_type: type }
    prefixes = lookup_context.prefixes + ['']
    keys     = locals.keys + [:document]
    document_index_path_templates.find do |str|
      partial = str % values
      logger.debug { "Looking for document index partial #{partial}" }
      template = lookup_context.find_all(partial, prefixes, true, keys, {})
      template &&= template.first
      return template if template
    end
  end
=end

=begin # NOTE: using base version
  # cached_view
  #
  # @param [String] key fetches or writes data to a cache, using the given key.
  # @yield The block to evaluate (and cache) if there is a cache miss.
  #
  # This method overrides:
  # @see Blacklight::RenderPartialsHelper#cached_view
  #
  def cached_view(key)
    @view_cache ||= {}
    if @view_cache.key?(key)
      @view_cache[key]
    else
      @view_cache[key] = yield
    end
  end
=end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # document_path_templates
  #
  # @param [String]        base
  # @param [Array<String>] suffixes   One or more strings or arrays of strings
  #
  # @return [Array<String>]
  #
  def document_path_templates(base, *suffixes)
    suffixes.flatten!
    suffixes = [nil] if suffixes.empty?
    view_subdirs.flat_map do |view_subdir|
      view_subdir &&= "#{view_subdir}/"
      suffixes.map do |suffix|
        suffix &&= "_#{suffix}"
        "#{view_subdir}#{base}#{suffix}"
      end
    end
  end

end

__loading_end(__FILE__)
