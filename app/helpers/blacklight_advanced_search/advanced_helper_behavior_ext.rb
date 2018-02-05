# app/helpers/blacklight_advanced_search/advanced_search_helper_behavior_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

module BlacklightAdvancedSearch

  # BlacklightAdvancedSearch::AdvancedHelperBehaviorExt
  #
  # @see BlacklightAdvancedSearch::AdvancedHelperBehavior
  #
  module AdvancedHelperBehaviorExt

    include BlacklightAdvancedSearch::AdvancedHelperBehavior
    include LensHelper

    # =========================================================================
    # :section: BlacklightAdvancedSearch::AdvancedHelperBehavior overrides
    # =========================================================================

    public

=begin # NOTE: using base version
=end
    # Fill in default from existing search, if present.
    # -- if you are using same search fields for basic
    # search and advanced, will even fill in properly if existing
    # search used basic search on same field present in advanced.
    #
    # @param [String] key
    #
    # @return [String, nil]
    #
    # This method overrides:
    # @see BlacklightAdvancedSearch::AdvancedHelperBehavior#label_tag_default_for
    #
    def label_tag_default_for(key)
      params[key].presence || (params[:q] if params[:search_field] == key)
    end

=begin # NOTE: using base version
=end
    # Indicate whether the facet value in advanced facet search results.
    #
    # @param [String, Symbol] field
    # @param [String]         value
    #
    # This method overrides:
    # @see BlacklightAdvancedSearch::AdvancedHelperBehavior#facet_value_checked?
    #
    def facet_value_checked?(field, value)
      BlacklightAdvancedSearch::QueryParserExt.new(params, blacklight_config)
        .filters_include_value?(field, value)
    end

    # select_menu_for_field_operator
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    # This method overrides:
    # @see BlacklightAdvancedSearch::AdvancedHelperBehavior#select_menu_for_field_operator
    #
    def select_menu_for_field_operator
      options = {
        t('blacklight_advanced_search.op.AND.menu_label') => 'AND',
        t('blacklight_advanced_search.op.OR.menu_label')  => 'OR'
      }.sort
      options = options_for_select(options, params[:op])
      select_tag(:op, options, class: 'input-small')
    end

=begin # NOTE: using base version
=end
    # Current params without fields that will be over-written by adv. search,
    # or other fields we don't want.
    #
    # @return [Hash]
    #
    # This method overrides:
    # @see BlacklightAdvancedSearch::AdvancedHelperBehavior#advanced_search_context
    #
    def advanced_search_context
      search_fields = search_fields_for_advanced_search
      skip = search_fields.map { |_key, field_def| field_def[:key] }
      skip += %i(q search_field f_inclusive op index sort page)
      search_state.params_for_search.except(*skip)
    end

=begin # NOTE: using base version
=end
    # search_fields_for_advanced_search
    #
    # @return [Hash]
    #
    # This method overrides:
    # @see BlacklightAdvancedSearch::AdvancedHelperBehavior#search_fields_for_advanced_search
    #
    def search_fields_for_advanced_search
      @search_fields_for_advanced_search ||=
        blacklight_config.search_fields.select do |_k, v|
          (inc = v.include_in_advanced_search) || inc.nil?
        end
    end

=begin # NOTE: using base version
=end
    # facet_field_names_for_advanced_search
    #
    # @return [Array<String>]
    #
    # This method overrides:
    # @see BlacklightAdvancedSearch::AdvancedHelperBehavior#facet_field_names_for_advanced_search
    #
    def facet_field_names_for_advanced_search
      @facet_field_names_for_advanced_search ||=
        blacklight_config.facet_fields.select { |_k, v|
          (inc = v.include_in_advanced_search) || inc.nil?
        }.values.map(&:field)
    end

=begin # NOTE: using base version
=end
    # Use configured facet partial name for facet or fallback on
    # 'catalog/facet_limit'.
    #
    # @param [String] display_facet
    #
    # This method overrides:
    # @see BlacklightAdvancedSearch::AdvancedHelperBehavior#advanced_search_facet_partial_name
    #
    def advanced_search_facet_partial_name(display_facet)
      facet_configuration_for_field(display_facet.name).try(:partial) ||
        'catalog/facet_limit' # TODO: ???
    end

  end

end

__loading_end(__FILE__)
