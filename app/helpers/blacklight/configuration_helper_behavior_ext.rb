# app/helpers/blacklight/configuration_helper_behavior_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Blacklight::ConfigurationHelperBehaviorExt
#
# @see Blacklight::ConfigurationHelperBehavior
#
module Blacklight::ConfigurationHelperBehaviorExt

  include LensHelper
  include Blacklight::ConfigurationHelperBehavior

  # ===========================================================================
  # :section: Blacklight::ConfigurationHelperBehavior overrides
  # ===========================================================================

  public

  # Index fields to display for a type of document.
  #
  # @param [Object, nil] lens         Default: `current_lens`.
  #
  # @return [Array<Blacklight::Configuration::Field>]
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#index_fields
  #
  def index_fields(lens = nil)
    blacklight_config(lens).index_fields
  end

  # Used in the document_list partial (search view) for building a select
  # element.
  #
  # @param [Object, nil] lens         Default: `current_lens`.
  #
  # @return [Array<Array<(String,Symbol)>>]
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#sort_fields
  #
  def sort_fields(lens = nil)
    active_sort_fields(lens).keys.map do |key|
      [sort_field_label(key), key.to_sym]
    end
  end
  deprecation_deprecate :sort_fields

  # active_sort_fields
  #
  # @param [Object, nil] lens         Default: `current_lens`.
  #
  # @return [Array<Blacklight::Configuration::SortField>]
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#active_sort_fields
  #
  def active_sort_fields(lens = nil)
    blacklight_config(lens).sort_fields.select do |_, field_def|
      should_render_field?(field_def)
    end
  end

  # Used in the search form partial for building a select tag.
  #
  # @param [Object, nil] lens         Default: `current_lens`.
  #
  # @return [Array<Array<(String, Symbol)>>]
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#search_fields
  #
  def search_fields(lens = nil)
    search_field_options_for_select(lens)
  end

  # Returns suitable argument to options_for_select method, to create an HTML
  # <select> based on #search_field_list.
  #
  # Skips search_fields marked with :include_in_simple_select => *false*
  #
  # @param [Object, nil] lens         Default: `current_lens`.
  #
  # @return [Array<Array<(String, Symbol)>>]
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#search_field_options_for_select
  #
  def search_field_options_for_select(lens = nil)
    blacklight_config(lens).search_fields.map { |_, field_def|
      key = field_def.key
      [label_for_search_field(key), key] if should_render_field?(field_def)
    }.compact
  end

  # Used in the catalog/_show/_default partial.
  #
  # @param [Object, nil] lens         Default: `current_lens`.
  #
  # @return [Array<Blacklight::Configuration::Field>]
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#document_show_fields
  #
  def document_show_fields(lens = nil)
    blacklight_config(lens).show_fields
  end

=begin # NOTE: using base version
  # Return a label for the currently selected search field.
  #
  # If no "search_field" or the default (e.g. "all_fields") is selected, then
  # return *nil*.  Otherwise grab the label of the selected search field.
  #
  # @param [Hash] localized_params query parameters
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#constraint_query_label
  #
  def constraint_query_label(localized_params = nil)
    localized_params ||= params
    field = localized_params[:search_field]
    label_for_search_field(field) unless default_search_field?(field)
  end
=end

=begin # NOTE: using base version
  # Indicate whether search form using the default search field ("all_fields"
  # by default).
  #
  # @param [String] field             The currently selected search_field.
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#default_search_field?
  #
  def default_search_field?(field)
    field.blank? || (field == default_search_field&.fetch(:key, nil))
  end
=end

  # Look up the label for the index field.
  #
  # @param [Object]         lens      Default: `current_lens` if *nil*.
  # @param [String, Symbol] field
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#index_field_label
  #
  def index_field_label(lens, field)
    return '' unless field.present?
    lens      = lens_key_for(lens)
    field_def = index_fields(lens)[field]
    field_label(
      :"blacklight.#{lens}.search.fields.index.#{field}",
      :"blacklight.#{lens}.search.fields.#{field}",
      :"blacklight.search.fields.index.#{field}",
      :"blacklight.search.fields.#{field}",
      field_def&.label,
      field.to_s.humanize
    )
  end

  # Look up the label for the show field
  #
  # @param [Object]         lens      Default: `current_lens` if *nil*.
  # @param [String, Symbol] field
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#document_show_field_label
  #
  def document_show_field_label(lens, field)
    return '' unless field.present?
    lens      = lens_key_for(lens)
    field_def = document_show_fields(lens)[field]
    field_label(
      :"blacklight.#{lens}.search.fields.show.#{field}",
      :"blacklight.#{lens}.search.fields.#{field}",
      :"blacklight.search.fields.show.#{field}",
      :"blacklight.search.fields.#{field}",
      field_def&.label,
      field.to_s.humanize
    )
  end

  # Look up the label for the facet field.
  #
  # @param [String, Symbol] field
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#facet_field_label
  #
  def facet_field_label(field)
    return '' unless field.present?
    lens      = current_lens.key
    field_def = blacklight_config(lens).facet_fields[field]
    field_label(
      :"blacklight.#{lens}.search.fields.facet.#{field}",
      :"blacklight.#{lens}.search.fields.#{field}",
      :"blacklight.search.fields.facet.#{field}",
      :"blacklight.search.fields.#{field}",
      field_def&.label,
      field.to_s.humanize
    )
  end

  # Look up the label for the view.
  #
  # @param [String, Symbol] view
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#view_label
  #
  # NOTE: 0% coverage for this method
  #
  def view_label(view)
    return '' unless view.present?
    lens        = current_lens.key
    view_config = blacklight_config(lens).view[view]
    field_label(
      :"blacklight.#{lens}.search.view_title.#{view}",
      :"blacklight.#{lens}.search.view.#{view}",
      :"blacklight.search.view_title.#{view}",
      :"blacklight.search.view.#{view}",
      view_config&.label,
      view_config&.title,
      view.to_s.humanize
    )
  end

  # Shortcut for commonly needed operation, look up display label for the key
  # specified. Returns "Keyword" if a label can't be found.
  #
  # @param [String, Symbol] key
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#label_for_search_field
  #
  def label_for_search_field(key)
    return '' unless key.present?
    lens      = current_lens.key
    field_def = blacklight_config(lens).search_fields[key]
    key       = field_def&.key || key
    field_label(
      :"blacklight.#{lens}.search.fields.search.#{key}",
      :"blacklight.#{lens}.search.fields.#{key}",
      :"blacklight.search.fields.search.#{key}",
      :"blacklight.search.fields.#{key}",
      field_def&.label,
      key.to_s.humanize
    )
  end

  # Look up the label for the sort field.
  #
  # @param [String, Symbol] key
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#sort_field_label
  #
  def sort_field_label(key)
    return '' unless key.present?
    lens      = current_lens.key
    field_def = blacklight_config(lens).sort_fields[key]
    field_label(
      :"blacklight.#{lens}.search.fields.sort.#{key}",
      :"blacklight.search.fields.sort.#{key}",
      field_def&.label,
      key.to_s.humanize
    )
  end

=begin # NOTE: using base version
  # Look up the label for a Solr field.
  #
  # @overload label
  #   @param [Symbol] an i18n key
  #
  # @overload label, i18n_key, another_i18n_key, and_another_i18n_key
  #   @param [String] default label to display if the i18n look up fails
  #   @param [Symbol] i18n keys to attempt to look up
  #     before falling  back to the label
  #   @param [Symbol] any number of additional keys
  #   @param [Symbol] ...
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#field_label
  #
  def field_label(*i18n_keys)
    i18n_keys.compact!
    first = i18n_keys.shift
    t(first, default: i18n_keys)
  end
=end

  # document_index_views
  #
  # @param [Object, nil] lens         Default: `current_lens`.
  #
  # @return [Array<Blacklight::Configuration::ViewConfig>]
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#document_index_views
  #
  def document_index_views(lens = nil)
    blacklight_config(lens).view.select do |_, field_def|
      should_render_field?(field_def)
    end
  end

  # Filter #document_index_views to just views that should display in the view
  # type control.
  #
  # @param [Object, nil] lens         Default: `current_lens`.
  #
  # @return [Hash]
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#document_index_view_controls
  #
  # NOTE: 0% coverage for this method
  #
  def document_index_view_controls(lens = nil)
    context = blacklight_configuration_context
    document_index_views(lens).select do |_, field_def|
      control = field_def.display_control
      control.nil? || context.evaluate_configuration_conditional(control)
    end
  end

  # Get the default index view type.
  #
  # @param [Object, nil] lens         Default: `current_lens`.
  #
  # @return [Symbol]
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#default_document_index_view_type
  #
  def default_document_index_view_type(lens = nil)
    views   = document_index_views(lens)
    default = views.select { |_, field_def| field_def.default }.keys.first
    default || views.keys.first
  end

  # Indicate whether there are alternative views configured.
  #
  # @param [Object, nil] lens         Default: `current_lens`.
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#has_alternative_views?
  #
  def has_alternative_views?(lens = nil)
    document_index_views(lens).keys.size > 1
  end

  # Maximum number of results for spell-checking.
  #
  # @param [Object, nil] lens         Default: `current_lens`.
  #
  # @return [Integer]
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#spell_check_max
  #
  def spell_check_max(lens = nil)
    blacklight_config(lens).spell_max
  end

  # Used in the document list partial (search view) for creating a link to the
  # document show action.
  #
  # @param [Blacklight::Document] doc
  # @param [Hash, nil]            options
  #
  # @option options [Boolean] :show_title     Set as *false* to only show the
  #                                             subtitle.
  # @option options [Boolean] :show_subtitle  Set as *false* to only show the
  #                                             main title.
  # @option options [String]  :separator      String shown between title and
  #                                             subtitle.  Set as *nil* to
  #                                             have no separator.
  #
  # @return [Symbol, String]
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#document_show_link_field
  #
  def document_show_link_field(doc = nil, options = nil)
    config = blacklight_config(doc)
    type   = document_index_view_type # TODO: lens?
    fields = config.view_config(type).title_field
    fields = Array.wrap(fields)
    if doc.is_a?(Blacklight::Document)
      fields.find { |f| doc.has?(f) }&.to_sym || doc.id
    else # NOTE: 0% coverage for this case
      fields.first&.to_sym
    end
  end

  # Default sort field.
  #
  # @param [Object, nil] lens         Default: `current_lens`.
  #
  # @return [Blacklight::Configuration::SortField]
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#default_sort_field
  #
  def default_sort_field(lens = nil)
    fields = active_sort_fields(lens)
    field  = fields.find { |_, field_def| field_def.default } || fields.first
    field&.last
  end

  # The default value for search results per page.
  #
  # @param [Object, nil] lens         Default: `current_lens`.
  #
  # @return [Integer]
  #
  # @see Blacklight::Configuration#default_per_page
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#default_per_page
  #
  def default_per_page(lens = nil)
    blacklight_config(lens).default_per_page
  end

  # The available options for results per page, in the style of
  # #options_for_select.
  #
  # @param [Object, nil] lens         Default: `current_lens`.
  #
  # @return [Array<Array<(ActiveSupport::SafeBuffer, Integer)>>]
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#per_page_options_for_select
  #
  def per_page_options_for_select(lens = nil)
    blacklight_config(lens).per_page.map do |per_page|
      label = t('blacklight.search.per_page.label', count: per_page).html_safe
      [label, per_page]
    end
  end

=begin # NOTE: using base version
  # Indicate whether to render a field by evaluating :if and :unless conditions
  #
  # @param [Blacklight::Configuration::Field] field_def
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#should_render_field?
  #
  def should_render_field?(field_def, *args)
    blacklight_configuration_context
      .evaluate_if_unless_configuration(field_def, *args)
  end
=end

end

__loading_end(__FILE__)
