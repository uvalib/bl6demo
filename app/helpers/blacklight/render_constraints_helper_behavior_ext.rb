# app/helpers/blacklight/render_constraints_helper_behavior_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Blacklight::RenderConstraintsHelperBehaviorExt
#
# @see Blacklight::RenderConstraintsHelperBehavior
#
# Some methods are overridden by:
# @see BlacklightAdvancedSearch::RenderConstraintsOverrideExt
#
module Blacklight::RenderConstraintsHelperBehaviorExt

  include Blacklight::RenderConstraintsHelperBehavior
  include LensHelper

  # ===========================================================================
  # :section: Blacklight::RenderConstraintsHelperBehavior overrides
  # ===========================================================================

  public

=begin # NOTE: using base version
  # Indicate whether the query has any constraints defined (a query, facet,
  # etc).
  #
  # @param [Hash] p                   Query parameters.
  #
  # This method overrides:
  # @see Blacklight::RenderConstraintsHelperBehavior#query_has_constraints
  #
  def query_has_constraints?(p = nil)
    p ||= params
    %i(q f).any? { |field| p[field].present? }
  end
=end

=begin # NOTE: using base version
  # Render the actual constraints, not including header or footer info.
  #
  # @param [Hash] p                   Query parameters.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::RenderConstraintsHelperBehavior#render_constraints
  #
  def render_constraints(p = nil)
    p ||= params
    render_constraints_query(p) + render_constraints_filters(p)
  end
=end

=begin # NOTE: using base version
  # Render the query constraints.
  #
  # @param [ActionController::Parameters] p  Query parameters.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::RenderConstraintsHelperBehavior#render_constraints_query
  #
  def render_constraints_query(p = nil)
    p ||= params

    # So simple don't need a view template, we can just do it here.
    return ''.html_safe if p[:q].blank?

    render_constraint_element(
      constraint_query_label(p),
      p[:q],
      classes: %w(query),
      remove:  remove_constraint_url(p)
    )
  end
=end

=begin # NOTE: using base version
  # Provide a URL for removing a particular constraint. This can be overridden
  # in the case that you want parameters other than the defaults to be removed
  # (e.g. :search_field).
  #
  # @param [ActionController::Parameters] p  Query parameters.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::RenderConstraintsHelperBehavior#remove_constraint_url
  #
  def remove_constraint_url(p = nil)
    p ||= params
    scope = p.delete(:route_set) || self

    unless p.is_a?(ActionController::Parameters)
      p = ActionController::Parameters.new(p)
    end

    options = p.merge(q: nil, action: 'index')
    options.permit!
    scope.url_for(options)
  end
=end

  # Render the facet constraints.
  #
  # @param [Hash] localized_params    Default: `params`.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::RenderConstraintsHelperBehavior#render_constraints_filters
  #
  def render_constraints_filters(localized_params = nil)
    localized_params ||= params.to_unsafe_h
    facets = localized_params[:f]
    facets = facets.to_unsafe_h if facets.respond_to?(:to_unsafe_h)
    facets ||= {}
    ss = nil
    facets.map { |facet, values|
      ss ||= controller.search_state_class
      path = ss.new(localized_params, blacklight_config, controller)
      render_filter_element(facet, values, path)
    }.join("\n").html_safe
  end

  # Render a single facet's constraint.
  #
  # @param [String]                     facet   Field.
  # @param [Array<String>]              values  Selected facet values.
  # @param [Blacklight::SearchStateExt] path    Query parameters.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::RenderConstraintsHelperBehavior#render_filter_element
  #
  def render_filter_element(facet, values, path)
    facet_config = facet_configuration_for_field(facet)
    facet_key    = facet_config.key
    facet_label  = facet_field_label(facet_key)
    Array(values).map { |value|
      next unless value.present?
      render_constraint_element(
        facet_label,
        facet_display_value(facet, value),
        remove:  search_action_path(path.remove_facet_params(facet, value)),
        classes: %W(filter filter-#{facet.parameterize})
      )
    }.compact.join("\n").html_safe
  end

  # Render a label/value constraint on the screen.
  #
  # Can be called by plugins and such to get application-defined rendering.
  #
  # Can be over-ridden locally to render differently if desired, although in
  # most cases you can just change CSS instead.
  #
  # Can pass in nil label if desired.
  #
  # @param [String] label
  # @param [String] value
  # @param [Hash]   options
  #
  # @option options [String]        :remove   URL to execute for a 'remove' action
  # @option options [Array<String>] :classes  CSS classes to add
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  # This method overrides:
  # @see Blacklight::RenderConstraintsHelperBehavior#render_constraint_element
  #
  def render_constraint_element(label, value, options = nil)
    options ||= {}
    locals = { label: label, value: value, options: options }
    render_template('constraints_element', locals)
  end

end

__loading_end(__FILE__)
