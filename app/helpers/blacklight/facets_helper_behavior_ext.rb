# app/helpers/blacklight/facets_helper_behavior_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Blacklight::FacetsHelperBehaviorExt
#
# @see Blacklight::FacetsHelperBehavior
#
module Blacklight::FacetsHelperBehaviorExt

  include LensHelper
  include Blacklight::FacetsHelperBehavior
  include Blacklight::FacetExt

  # ===========================================================================
  # :section: Blacklight::FacetsHelperBehavior overrides
  # ===========================================================================

  public

=begin # NOTE: using base version
  # Indicate whether any of the given fields have values.
  #
  # @param [Array<String>, nil] fields     Default: `facet_field_names`.
  # @param [Hash, nil]          _options   Ignored.
  #
  # This method overrides:
  # @see Blacklight::FacetsHelperBehavior#has_facet_values?
  #
  def has_facet_values?(fields = nil, _options = nil)
    fields ||= facet_field_names
    facets_from_request(fields).any? { |facet| should_render_facet?(facet) }
  end
=end

=begin # NOTE: using base version
  # Render a collection of facet fields.
  #
  # @param [Array<String>, nil] fields     Default: `facet_field_names`.
  # @param [Hash, nil]          options
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #render_facet_limit
  #
  # This method overrides:
  # @see Blacklight::FacetsHelperBehavior#render_facet_partials
  #
  def render_facet_partials(fields = nil, options = nil)
    fields  ||= facet_field_names
    options ||= {}
    facets_from_request(fields).map { |display_facet|
      render_facet_limit(display_facet, options)
    }.compact.join("\n").html_safe
  end
=end

=begin # NOTE: using base version
  # Renders a single section for facet limit with a specified Solr field used
  # for faceting. Can be over-ridden for custom display on a per-facet basis.
  #
  # @param [Blacklight::Solr::Response::Facets::FacetField] display_facet
  # @param [Hash, nil]                                      options
  #
  # @option options [String] :partial Partial to render.
  # @option options [String] :layout  Partial layout to render.
  # @option options [Hash]   :locals  Locals to pass to the partial.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::FacetsHelperBehavior#render_facet_limit
  #
  def render_facet_limit(display_facet, options = nil)
    return unless should_render_facet?(display_facet)
    options = options ? options.dup : {}
    options[:partial] ||= facet_partial_name(display_facet)
    options[:layout]  ||= 'facet_layout'
    locals = options[:locals] ||= {}
    name   = display_facet.name
    locals[:field_name]    ||= name
    locals[:solr_field]    ||= name # deprecated
    locals[:facet_field]   ||= facet_configuration_for_field(name)
    locals[:display_facet] ||= display_facet
    render(options)
  end
=end

=begin # NOTE: using base version
  # Renders the list of values.
  #
  # Removes any elements where render_facet_item returns a nil value. This
  # enables an application to filter undesirable facet items so they don't
  # appear in the UI.
  #
  # @param [Blacklight::Solr::FacetPaginator]               paginator
  # @param [Blacklight::Solr::Response::Facets::FacetField] facet_field
  # @param [String, Symbol, nil]                            wrapping_element
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::FacetsHelperBehavior#render_facet_limit_list
  #
  def render_facet_limit_list(paginator, facet_field, wrapping_element = nil)
    wrapping_element ||= :li
    items = paginator.items.map { |item| render_facet_item(facet_field, item) }
    items.compact!
    items.map! { |item| content_tag(wrapping_element, item) }
    safe_join(items)
  end
=end

=begin # NOTE: using base version
  # Renders a single facet item.
  #
  # @param [Blacklight::Solr::Response::Facets::FacetField] facet_field
  # @param [Blacklight::Solr::Response::Facets::FacetItem]  item
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::FacetsHelperBehavior#render_facet_item
  #
  def render_facet_item(facet_field, item)
    if facet_in_params?(facet_field, item.value)
      render_selected_facet_value(facet_field, item)
    else
      render_facet_value(facet_field, item)
    end
  end
=end

=begin # NOTE: using base version
  # Indicate whether Blacklight should render the display_facet or not
  # (if the facet configuration 'show' value is *true* or missing).
  #
  # By default, only render facets with items.
  #
  # @param [Blacklight::Solr::Response::Facets::FacetField] display_facet
  #
  # This method overrides:
  # @see Blacklight::FacetsHelperBehavior#should_render_facet?
  #
  def should_render_facet?(display_facet)
    return unless display_facet&.items.present?
    cfg = facet_configuration_for_field(display_facet.name)
    should_render_field?(cfg, display_facet)
  end
=end

=begin # NOTE: using base version
  # Indicate whether a facet should be rendered as collapsed or not.
  #   - if the facet is 'active', don't collapse
  #   - if the facet is configured to collapse (the default), collapse
  #   - if the facet is configured not to collapse, don't collapse
  #
  # @param [Blacklight::Solr::Response::Facets::FacetField] facet_field
  #
  # This method overrides:
  # @see Blacklight::FacetsHelperBehavior#should_collapse_facet?
  #
  def should_collapse_facet?(facet_field)
    facet_field.collapse unless facet_field_in_params?(facet_field.key)
  end
=end

=begin # NOTE: using base version
  # The name of the partial to use to render a facet field.
  #
  # Uses the value of the "partial" field if set in the facet configuration;
  # otherwise uses "facet_pivot"; if this facet is a pivot facet, defaults to
  # "facet_limit".
  #
  # @param [Blacklight::Solr::Response::Facets::FacetField, nil] display_facet
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::FacetsHelperBehavior#facet_partial_name
  #
  def facet_partial_name(display_facet = nil)
    cfg = facet_configuration_for_field(display_facet.name)
    cfg[:partial] || (cfg.pivot ? 'facet_pivot' : 'facet_limit')
  end
=end

=begin # NOTE: using base version
  # Standard display of a facet value in a list.
  #
  # Used in both _facets sidebar partial and catalog/facet expanded list.
  # Will output facet value name as a link to add that to your restrictions,
  # with count in parens.
  #
  # @param [Blacklight::Solr::Response::Facets::FacetField] facet_field
  # @param [Blacklight::Solr::Response::Facets::FacetItem]  item
  # @param [Hash, nil]                                      options
  #
  # @option options [Boolean] :suppress_link  Display the facet value, but
  #                                             don't link to it.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::FacetsHelperBehavior#render_facet_value
  #
  def render_facet_value(facet_field, item, options = nil)
    suppress_link = options && options[:suppress_link]
    path   = path_for_facet(facet_field, item)
    label  = facet_display_value(facet_field, item)
    link   = link_to_unless(suppress_link, label, path, class: 'facet_select')
    result = content_tag(:span, link, class: 'facet-label')
    result << render_facet_count(item.hits)
  end
=end

=begin # NOTE: using base version
  # Where the facet value should link to.
  #
  # @param [Blacklight::Solr::Response::Facets::FacetField] facet_field
  # @param [Blacklight::Solr::Response::Facets::FacetItem]  item
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::FacetsHelperBehavior#path_for_facet
  #
  def path_for_facet(facet_field, item)
    cfg = facet_configuration_for_field(facet_field)
    url = cfg&.url_method
    if url
      send(url, facet_field, item)
    else
      path_opt = search_state.add_facet_params_and_redirect(facet_field, item)
      search_action_path(path_opt)
    end
  end
=end

=begin # NOTE: using base version
  # Standard display of a SELECTED facet value (e.g. without a link and with a
  # remove button).
  #
  # @param [Blacklight::Solr::Response::Facets::FacetField] facet_field
  # @param [Blacklight::Solr::Response::Facets::FacetItem]  item
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see self#render_facet_value
  #
  # This method overrides:
  # @see Blacklight::FacetsHelperBehavior#render_selected_facet_value
  #
  def render_selected_facet_value(facet_field, item)
    path_opt = search_state.remove_facet_params(facet_field, item)
    path     = search_action_path(path_opt)
    label    = facet_display_value(facet_field, item)
    result =
      content_tag(:span, class: 'facet-label') do
        content_tag(:span, label, class: 'selected') +
        # Remove link.
        link_to(path, class: 'remove') do
          content_tag(:span, '', class: 'glyphicon glyphicon-remove') +
          content_tag(:span, '[remove]', class: 'sr-only')
        end
      end
    result << render_facet_count(item.hits, classes: %w(selected))
  end
=end

=begin # NOTE: using base version
  # Renders a count value for facet limits. Can be over-ridden locally
  # to change style. And can be called by plugins to get consistent display.
  #
  # @param [Integer]   count          Number of facet results.
  # @param [Hash, nil] options
  #
  # @option options [Array<String>]   An array of classes to add to count span.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::FacetsHelperBehavior#render_facet_count
  #
  def render_facet_count(count, options = nil)
    count   = number_with_delimiter(count)
    label   = t('blacklight.search.facets.count', number: count)
    classes = Array.wrap(options && options[:classes]) << 'facet-count'
    content_tag(:span, label, class: classes)
  end
=end

=begin # NOTE: using base version
  # Indicate whether there are any facet restrictions for a field in the query
  # parameters.
  #
  # @param [Blacklight::Solr::Response::Facets::FacetField] field
  #
  # This method overrides:
  # @see Blacklight::FacetsHelperBehavior#facet_field_in_params?
  #
  def facet_field_in_params?(field)
    facet_params(field).present?
  end
=end

=begin # NOTE: using base version
  # Indicate whether the query parameters have the given facet field with the
  # given value.
  #
  # @param [Blacklight::Solr::Response::Facets::FacetField] field
  # @param [Blacklight::Solr::Response::Facets::FacetItem]  item
  #
  # This method overrides:
  # @see Blacklight::FacetsHelperBehavior#facet_in_params?
  #
  def facet_in_params?(field, item)
    value = facet_value_for_facet_item(item)
    f = facet_params(field) || []
    f.include?(value)
  end
=end

=begin # NOTE: using base version
  # Get the values of the facet set in the blacklight query string.
  #
  # @param [Blacklight::Solr::Response::Facets::FacetField] field
  #
  # This method overrides:
  # @see Blacklight::FacetsHelperBehavior#facet_params
  #
  def facet_params(field)
    return unless params[:f].present?
    cfg = facet_configuration_for_field(field)
    params[:f][cfg.key]
  end
=end

=begin # NOTE: using base version
  # Get the displayable version of a facet's value.
  #
  # @param [Blacklight::Solr::Response::Facets::FacetField] field
  # @param [Blacklight::Solr::Response::Facets::FacetItem]  item
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::FacetsHelperBehavior#facet_display_value
  #
  def facet_display_value(field, item)
    cfg = facet_configuration_for_field(field)

    value =
      if item.respond_to?(:label)
        item.label
      else
        facet_value_for_facet_item(item)
      end

    if cfg.helper_method
      send(cfg.helper_method, value)
    elsif cfg.query && cfg.query[value]
      cfg.query[value][:label]
    elsif cfg.date
      opt = {}
      opt = cfg.date unless cfg.date.is_a?(TrueClass)
      localize(value.to_datetime, opt)
    else
      value
    end
  end
=end

=begin # NOTE: using base version
  # facet_field_id
  #
  # @param [Blacklight::Solr::Response::Facets::FacetField] facet_field
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::FacetsHelperBehavior#facet_field_id
  #
  def facet_field_id(facet_field)
    "facet-#{facet_field.key.parameterize}"
  end
=end

  # ===========================================================================
  # :section: Blacklight::FacetsHelperBehavior overrides
  # ===========================================================================

  private

=begin # NOTE: using base version
  # facet_value_for_facet_item
  #
  # @param [Blacklight::Solr::Response::Facets::FacetItem] item
  #
  # @return [?]
  #
  # This method overrides:
  # @see Blacklight::FacetsHelperBehavior#facet_value_for_facet_item
  #
  def facet_value_for_facet_item(item)
    item.respond_to?(:value) ? item.value : item
  end
=end

end

__loading_end(__FILE__)
