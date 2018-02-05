# lib/blacklight/eds/response/facets_eds.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

=begin # NOTE: using base version
require 'ostruct'
=end

# EBSCO EDS version of
# @see Blacklight::Solr::Response::Facets
#
module Blacklight::Eds::Response::FacetsEds

  include Blacklight::Solr::Response::Facets

=begin # NOTE: using base version
  # Represents a facet value; which is a field value and its hit count.
  #
  class FacetItem < OpenStruct

    def initialize *args
      options = args.extract_options!

      # Backwards-compat method signature
      value = args.shift
      hits = args.shift

      options[:value] = value if value
      options[:hits] = hits if hits

      super(options)
    end

    def label
      super || value
    end

    def as_json(props = nil)
      table.as_json(props)
    end

  end
=end

  # Represents a facet; which is a field and its values.
  #
  class FacetField < Blacklight::Solr::Response::Facets::FacetField

    # =========================================================================
    # :section: Blacklight::Solr::Response::Facets::FacetField overrides
    # =========================================================================

    public

=begin # NOTE: using base version
    attr_reader :name, :items
=end

=begin # NOTE: using base version
    # Initialize a self instance
    #
    # @param [String] name
    # @param [?] items
    # @param [Hash] options
    #
    # @return [Integer, nil]
    #
    # This method replaces:
    # @see Blacklight::Solr::Response::Facets::FacetField#limit
    #
    def initialize(name, items, options = nil)
      @name    = name
      @items   = items
      @options = options || {}
    end
=end

    # limit
    #
    # @return [Integer, nil]
    #
    # This method replaces:
    # @see Blacklight::Solr::Response::Facets::FacetField#limit
    #
    def limit
      @options[:limit]  || eds_default_limit
    end

    # sort
    #
    # @return [String, nil]
    #
    # This method replaces:
    # @see Blacklight::Solr::Response::Facets::FacetField#sort
    #
    def sort
      @options[:sort]   || eds_default_sort
    end

    # offset
    #
    # @return [Integer, nil]
    #
    # This method replaces:
    # @see Blacklight::Solr::Response::Facets::FacetField#offset
    #
    def offset
      @options[:offset] || eds_default_offset
    end

    # prefix
    #
    # @return [String, nil]
    #
    # This method replaces:
    # @see Blacklight::Solr::Response::Facets::FacetField#prefix
    #
    def prefix
      @options[:prefix] || eds_default_prefix
    end

=begin # NOTE: using base version
    def index?
      sort == 'index'
    end
=end

=begin # NOTE: using base version
    def count?
      sort == 'count'
    end
=end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    # eds_default_limit
    #
    # @return [Integer, nil]
    #
    # This method replaces:
    # @see Blacklight::Solr::Response::Facets::FacetField#solr_default_limit
    #
    def eds_default_limit
      nil
    end

    # eds_default_sort
    #
    # @return [String, nil]
    #
    # This method replaces:
    # @see Blacklight::Solr::Response::Facets::FacetField#solr_default_sort
    #
    def eds_default_sort
      solr_default_sort
    end

    # eds_default_offset
    #
    # @return [Integer, nil]
    #
    # This method replaces:
    # @see Blacklight::Solr::Response::Facets::FacetField#solr_default_offset
    #
    def eds_default_offset
      solr_default_offset
    end

    # eds_default_prefix
    #
    # @return [String, nil]
    #
    # This method replaces:
    # @see Blacklight::Solr::Response::Facets::FacetField#solr_default_prefix
    #
    def eds_default_prefix
      solr_default_prefix
    end

  end

  # ===========================================================================
  # :section: Blacklight::Solr::Response::Facets overrides
  # ===========================================================================

  public

=begin # NOTE: using base version
  # Get all the Solr facet data (fields, queries, pivots) as a hash keyed by
  # both the Solr field name and/or by the blacklight field name
  #
  # @return [Hash]
  #
  # This method overrides:
  # @see Blacklight::Solr::Response::Facets#solr_default_sort
  #
  def aggregations
    @aggregations ||=
      {}.merge(facet_field_aggregations)
        .merge(facet_query_aggregations)
        .merge(facet_pivot_aggregations)
  end
=end

=begin # NOTE: using base version
  # facet_counts
  #
  # @return [Hash]
  #
  # This method overrides:
  # @see Blacklight::Solr::Response::Facets#facet_counts
  #
  def facet_counts
    @facet_counts ||= self['facet_counts'] || {}
  end
=end

=begin # NOTE: using base version
  # The hash of all the facet_fields
  # (eg: { 'instock_b' => ['true', 123, 'false', 20] }
  #
  # @return [Hash]
  #
  # This method overrides:
  # @see Blacklight::Solr::Response::Facets#facet_counts
  #
  def facet_fields
    @facet_fields ||=
      begin
        val = facet_counts['facet_fields'] || {}
        # This is some old Solr (1.4? earlier?) serialization of facet fields.
        if val.is_a?(Array)
          Hash[val]
        else
          val
        end
      end
  end
=end

=begin # NOTE: using base version
  # All of the facet queries.
  #
  # @return [Hash]
  #
  # This method overrides:
  # @see Blacklight::Solr::Response::Facets#facet_queries
  #
  def facet_queries
    @facet_queries ||= facet_counts['facet_queries'] || {}
  end
=end

=begin # NOTE: using base version
  # All of the facet pivot queries.
  #
  # @return [Hash]
  #
  # This method overrides:
  # @see Blacklight::Solr::Response::Facets#facet_pivot
  #
  def facet_pivot
    @facet_pivot ||= facet_counts['facet_pivot'] || {}
  end
=end

  # ===========================================================================
  # :section: Blacklight::Solr::Response::Facets overrides
  # ===========================================================================

  private

=begin # NOTE: using base version
  # Convert Solr responses of various json.nl flavors.
  #
  # @return [Array<Hash>]
  #
  # This method overrides:
  # @see Blacklight::Solr::Response::Facets#list_as_hash
  #
  def list_as_hash(solr_list)
    # map
    if solr_list.values.first.is_a?(Hash)
      solr_list
    else
      solr_list.each_with_object({}) do |(key, values), hash|
        hash[key] =
          if values.first.is_a?(Array)
            Hash[values]
          else # flat
            Hash[values.each_slice(2).to_a]
          end
      end
    end
  end
=end

=begin # NOTE: using base version
  # Convert Solr's facet_field response into FacetField objects.
  #
  # @return [Hash{String=>Blacklight::Eds::Response::Facet::FacetField}]
  #
  # This method overrides:
  # @see Blacklight::Solr::Response::Facets#facet_field_aggregations
  #
  def facet_field_aggregations
    response_facets = list_as_hash(facet_fields)
    response_facets.each_with_object({}) do |(field_name, values), hash|
      items =
        values.map do |value, hits|
          FacetItem.new(value: value, hits: hits).tap do |i|
            # Solr facet.missing serialization.
            if value.nil?
              i.label =
                I18n.t(
                  :"blacklight.search.fields.facet.missing.#{field_name}",
                  default: [:"blacklight.search.facets.missing"]
                )
              i.fq = "-#{field_name}:[* TO *]"
            end
          end
        end
      options = facet_field_aggregation_options(field_name)
      hash[field_name] = FacetField.new(field_name, items, options)

      # Alias all the possible blacklight config names..
      unless field_def
        blacklight_config.facet_fields.select { |_, field_def|
          field_def.field == field_name
        }.each do |key, _|
          hash[key] = hash[field_name]
        end
      end
    end
  end
=end

=begin # NOTE: using base version
  # facet_field_aggregation_options
  #
  # @param [String] field_name
  #
  # This method overrides:
  # @see Blacklight::Solr::Response::Facets#facet_field_aggregation_options
  #
  def facet_field_aggregation_options(field_name)
    options = {}

    sort = params[:"f.#{field_name}.facet.sort"] || params[:'facet.sort']
    options[:sort] = sort if sort.present?

    limit = params[:"f.#{field_name}.facet.limit"] || params[:'facet.limit']
    options[:limit] = limit.to_i if limit.present?

    offset = params[:"f.#{field_name}.facet.offset"] || params[:'facet.offset']
    options[:offset] = offset.to_i if offset.present?

    prefix = params[:"f.#{field_name}.facet.prefix"] || params[:'facet.prefix']
    options[:prefix] = prefix if prefix.present?

    options
  end
=end

=begin # NOTE: using base version
  # Aggregate Solr's facet_query response into the virtual facet fields defined
  # in the blacklight configuration.
  #
  # @return [Hash]
  #
  # This method overrides:
  # @see Blacklight::Solr::Response::Facets#facet_query_aggregations
  #
  def facet_query_aggregations
    return {} unless blacklight_config
    fields = blacklight_config.facet_fields.select { |_, v| v.query }
    fields.each_with_object({}) do |(field_name, facet_field), hash|
      salient_facet_queries =
        facet_field.query.map { |_, field_def| field_def[:fq] }
      items =
        facet_queries
          .select { |k, _| salient_facet_queries.include?(k) }
          .reject { |_value, hits| hits.zero? }
          .map do |value,hits|
            salient_fields =
              facet_field.query.select { |_, fdef| fdef[:fq] == value }
            key = (salient_fields.keys if salient_fields.respond_to?(:keys))
            key ||= salient_fields.first
            key &&= key.first
            Blacklight::Solr::Response::Facets::FacetItem.new(
              value: key,
              hits:  hits,
              label: facet_field.query[key][:label]
            )
          end
        hash[field_name] =
          Blacklight::Eds::Response::Facets::FacetField.new(field_name, items)
    end
  end
=end

=begin # NOTE: using base version
  # Convert Solr's facet_pivot response into FacetField objects.
  #
  # @return [Hash{String=>Blacklight::Eds::Response::Facet::FacetField}]
  #
  # This method overrides:
  # @see Blacklight::Solr::Response::Facets#facet_pivot_aggregations
  #
  def facet_pivot_aggregations
    facet_pivot.each_with_object({}) do |(field_name, values), hash|
      next if blacklight_config.facet_fields[field_name]

      items = values.map { |lst| construct_pivot_field(lst) }

      # Alias all the possible blacklight config names..
      blacklight_config.facet_fields
        .select { |_, v| v.pivot && (v.pivot.join(',') == field_name) }
        .each do |key, _|
          hash[key] =
            Blacklight::Eds::Response::Facets::FacetField.new(key, items)
        end
    end
  end
=end

=begin # NOTE: using base version
  # Recursively parse the pivot facet response to build up the full pivot tree.
  #
  # @return [Blacklight::Eds::Response::Facets::FacetItem]
  #
  def construct_pivot_field(lst, parent_fq = {})
    items =
      Array.wrap(lst[:pivot]).map do |i|
        construct_pivot_field(i, parent_fq.merge(lst[:field] => lst[:value]))
      end
    Blacklight::Eds::Response::Facets::FacetItem.new(
      value: lst[:value],
      hits:  lst[:count],
      field: lst[:field],
      items: items,
      fq:    parent_fq
    )
  end
=end

end
