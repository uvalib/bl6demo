# app/controllers/concerns/blacklight/facet_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

module Blacklight

  # These are methods that are used at both the view helper and controller layers
  # They are only dependent on `blacklight_config` and `@response`
  #
  # @see Blacklight::Facet
  #
  module FacetExt # TODO: Not sure if any of these overrides are needed -- if LensHelper isn't needed here then FacetExt probably isn't needed at all

    include Blacklight::Facet
    include LensHelper

=begin # NOTE: using base version
    delegate :facet_configuration_for_field, to: :blacklight_config
=end

=begin # NOTE: using base version
=end
    # facet_paginator
    #
    # @param [Blacklight::Configuration::FacetField] field_config
    # @param [?] response_data
    #
    # @return [Blacklight::Solr::FacetPaginator]
    #
    # This method overrides:
    # @see Blacklight::Facet#facet_paginator
    #
    def facet_paginator(field_config, response_data)
      blacklight_config.facet_paginator_class.new(
        response_data.items,
        sort:   response_data.sort,
        offset: response_data.offset,
        prefix: response_data.prefix,
        limit:  facet_limit_for(field_config.key)
      )
=begin # TODO: debugging - remove
      .tap { |res| $stderr.puts ">>> #{__method__}: #{res.pretty_inspect}" } # TODO: debugging - remove
=end
    end

=begin # NOTE: using base version
    # facets_from_request
    #
    # @param [Array<Blacklight::Configuration::FacetField>, nil] fields
    #
    # @return [Array<Blacklight::Configuration::FacetField>]
    #
    # This method overrides:
    # @see Blacklight::Facet#facets_from_request
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
    # @see Blacklight::Facet#facet_field_names
    #
    def facet_field_names
      blacklight_config.facet_fields.values.map(&:field)
    end
=end

=begin # NOTE: using base version
=end
    # Get a FacetField object from the @response.
    #
    # @param [String, Symbol, Blacklight::Configuration::FacetField] arg
    #
    # @return [Blacklight::Solr::Response::Facets::FacetField, nil]
    #
    # This method overrides:
    # @see Blacklight::Facet#facet_by_field_name
    #
    def facet_by_field_name(arg)
      case arg
        when String, Symbol
          facet_field = facet_configuration_for_field(arg)
          @response&.aggregations&.fetch(facet_field.field, nil)

        when Blacklight::Configuration::FacetField # NOTE: 0% coverage for this case
          @response&.aggregations&.fetch(arg.field, nil)

        else # NOTE: 0% coverage for this case
          arg # Is this really a useful case?
      end
    end

  end

end

__loading_end(__FILE__)
