# app/helpers/blacklight/search_history_constraints_behavior_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Blacklight::SearchHistoryConstraintsHelperBehaviorExt
#
# @see Blacklight::SearchHistoryConstraintsHelperBehavior
#
module Blacklight::SearchHistoryConstraintsHelperBehaviorExt

  include Blacklight::SearchHistoryConstraintsHelperBehavior
  include LensHelper

  # ===========================================================================
  # :section: Blacklight::SearchHistoryConstraintsHelperBehavior overrides
  # ===========================================================================

  public

=begin # NOTE: using base version
  # Simpler textual version of constraints, used on Search History page.
  # Theoretically can may be DRY'd up with results page render_constraints,
  # maybe even using the very same HTML with different CSS?
  # But too tricky for now, too many changes to existing CSS. TODO.
  #
  # @param [Hash] params
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::SearchHistoryConstraintsHelperBehavior#render_search_to_s
  #
  def render_search_to_s(params)
    render_search_to_s_q(params) + render_search_to_s_filters(params)
  end
=end

  # Render the search query constraint.
  #
  # @param [Hash] params
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::SearchHistoryConstraintsHelperBehavior#render_search_to_s_q
  #
  def render_search_to_s_q(params)
    query = params[:q]
    return ''.html_safe unless query.present?
    search = params[:search_field].to_s.presence
    if search
      skipped = [default_search_field.key.to_s]
      skipped << blacklight_config.advanced_search.url_key.to_s
      search  = nil if skipped.map(&:to_s).include?(search)
    end
    label = (search && label_for_search_field(search)) || ''
    value = render_filter_value(query)
    render_search_to_s_element(label, value)
  end

  # Render the search facet constraints.
  #
  # @param [Hash] params
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::SearchHistoryConstraintsHelperBehavior#render_search_to_s_filters
  #
  def render_search_to_s_filters(params)
    separator =
      content_tag(:span, " #{t('blacklight.and')} ", class: 'filterSeparator')
    facets = params[:f] || {}
    facets.map { |field, values|
      label = facet_field_label(field)
      value =
        values.map { |value|
          render_filter_value(value, field)
        }.join(separator).html_safe
      render_search_to_s_element(label, value)
    }.join("\n").html_safe
  end

=begin # NOTE: using base version
  # render_search_to_s_element
  #
  # @param [Symbol, String]        key
  # @param [String, Array<String>] value      Multiple values joined with "and"
  # @param [Hash, nil]             _options
  #
  # @option options [Boolean] :escape_value   To pass in pre-prerended HTML
  #                                             for value.
  #                                           NOTE: never implemented; not used
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::SearchHistoryConstraintsHelperBehavior#render_search_to_s_element
  #
  def render_search_to_s_element(key, value, _options = nil)
    display = render_filter_name(key)
    display << content_tag(:span, value, class: 'filterValues')
    content_tag(:span, display, class: 'constraint')
  end
=end

=begin # NOTE: using base version
  # Render the name of the facet.
  #
  # @param [Symbol, String] name
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::SearchHistoryConstraintsHelperBehavior#render_filter_name
  #
  def render_filter_name(name)
    return ''.html_safe unless name.present?
    display = t('blacklight.search.filters.label', label: name)
    content_tag(:span, display, class: 'filterName')
  end
=end

=begin # NOTE: using base version
  # Render the value of the facet.
  #
  # @param [String, Array<String>] value
  # @param [Symbol, String, nil]   key
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::SearchHistoryConstraintsHelperBehavior#render_filter_value
  #
  def render_filter_value(value, key = nil)
    display = key ? facet_display_value(key, value) : value
    content_tag(:span, h(display), class: 'filterValue')
  end
=end

end

__loading_end(__FILE__)
