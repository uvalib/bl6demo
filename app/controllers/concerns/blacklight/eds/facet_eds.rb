# app/controllers/concerns/blacklight/eds/facet_eds.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/eds'

module Blacklight

  # EBSCO facets
  #
  # @see Blacklight::FacetExt
  # @see Blacklight::Facet
  #
  module FacetEds # TODO: Remove if not needed

    include Blacklight::FacetExt

=begin # NOTE: using base version
    delegate :facet_configuration_for_field, to: :blacklight_config
=end

=begin # NOTE: using base version
    # facet_paginator
    #
    # @param [?] field_config
    # @param [?] response_data
    #
    # @return [Blacklight::Solr::FacetPaginator]
    #
    # This method overrides:
    # @see Blacklight::FacetExt#facet_paginator
    #
    def facet_paginator(field_config, response_data)
      blacklight_config.facet_paginator_class.new(
        response_data.items,
        sort:   response_data.sort,
        offset: response_data.offset,
        prefix: response_data.prefix,
        limit:  facet_limit_for(field_config.key)
      )
      .tap { |res| $stderr.puts ">>> #{__method__}: #{res.pretty_inspect}"}
    end
=end

=begin # NOTE: using base version
    # facets_from_request
    #
    # @param [Array<Blacklight::Configuration::FacetField>, nil] fields
    #
    # @return [Array<Blacklight::Configuration::FacetField>]
    #
    # This method overrides:
    # @see Blacklight::FacetExt#facets_from_request
    #
    def facets_from_request(fields = nil)
      fields ||= facet_field_names
      fields.map { |field| facet_by_field_name(field) }.compact
    end
=end

=begin # NOTE: using base version
    # facet_field_names
    #
    # @return [Array<String>]
    #
    # This method overrides:
    # @see Blacklight::FacetExt#facet_field_names
    #
    def facet_field_names
      blacklight_config.facet_fields.values.map(&:field)
    end
=end

=begin # NOTE: using base version
    # Get a FacetField object from the @response.
    #
    # @param [String, Symbol, Blacklight::Configuration::FacetField] arg
    #
    # @return [Blacklight::Solr::Response::Facets::FacetField, nil]
    #
    # This method overrides:
    # @see Blacklight::FacetExt#facet_by_field_name
    #
    def facet_by_field_name(arg)
      case arg
        when String, Symbol
          facet_field = facet_configuration_for_field(arg)
          @response&.aggregations&.fetch(facet_field.field, nil)

        when Blacklight::Configuration::FacetField
          @response&.aggregations&.fetch(arg.field, nil)

        else
          arg # Is this really a useful case?
      end
    end
=end

  end

end

__loading_end(__FILE__)
