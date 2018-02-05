# lib/blacklight_advanced_search/catalog_helper_override_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# BlacklightAdvancedSearch::CatalogHelperOverrideExt
#
# @see BlacklightAdvancedSearch::CatalogHelperOverride
#
module BlacklightAdvancedSearch::CatalogHelperOverrideExt

  unless ONLY_FOR_DOCUMENTATION
    include Blacklight::FacetsHelperBehaviorExt
    include BlacklightAdvancedSearch::CatalogHelperOverride
  end

  include LensHelper

  # =========================================================================
  # :section: BlacklightAdvancedSearch::CatalogHelperOverride replacements
  #           of dynamic Blacklight::FacetsHelperBehavior overrides
  # =========================================================================

  public

  # Special display for facet limits that include advanced search inclusive-or
  # limits.
  #
  # @param [Blacklight::Solr::Response::Facets::FacetField] display_facet
  #
  # @return [String]
  #
  # This method overrides:
  # @see BlacklightAdvancedSearch::CatalogHelperOverride#facet_partial_name
  #
  # During operation this method overrides:
  # @see Blacklight::FacetsHelperBehaviorExt#facet_partial_name
  #
  def facet_partial_name(display_facet = nil)
    if advanced_query&.filters&.keys&.include?(display_facet.name)
      'blacklight_advanced_search/facet_limit'
    else
      super
    end
  end

  # =========================================================================
  # :section: BlacklightAdvancedSearch::CatalogHelperOverride replacements
  # =========================================================================

  public

  # Special display for facet limits that include advanced search inclusive-or
  # limits.
  #
  # @param [String, Symbol] field
  # @param [String]         value
  # @param [Hash, nil]      my_params   Default: `params`.
  #
  # @return [String]
  #
  # This method overrides:
  # @see BlacklightAdvancedSearch::CatalogHelperOverride#remove_advanced_facet_param
  #
  def remove_advanced_facet_param(field, value, my_params = nil)
    my_params ||= params
    result = Blacklight::SearchStateExt.new(my_params, blacklight_config).to_h
    if result&.fetch(:f_inclusive, nil)&.fetch(field, nil)&.include?(value)
      result[:f_inclusive] = result[:f_inclusive].dup
      result[:f_inclusive][field] = result[:f_inclusive][field].dup
      result[:f_inclusive][field].delete(value)
      result[:f_inclusive].delete(field) if result[:f_inclusive][field].empty?
      result.delete(:f_inclusive) if result[:f_inclusive].empty?
    end
    result.except(:id, :counter, :page, :commit)
  end

end

__loading_end(__FILE__)
