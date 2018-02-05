# lib/blacklight/search_builder_behavior.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module Blacklight

  # Extensions to Blacklight SearchBuilder applicable to all types of searches.
  #
  # This module extends:
  # @see Blacklight::Solr::SearchBuilderBehavior
  #
  module SearchBuilderBehavior

    extend ActiveSupport::Concern

    include Blacklight::Solr::SearchBuilderBehavior
    include LensHelper

=begin # NOTE: using base version
    included do
      self.default_processor_chain = %i(
        default_solr_parameters
        add_query_to_solr
        add_facet_fq_to_solr
        add_facetting_to_solr
        add_solr_fields_to_query
        add_paging_to_solr
        add_sorting_to_solr
        add_group_config_to_solr
        add_facet_paging_to_solr
      )
    end
=end

    # Code to be added to the controller class including this module.
    included do |base|
      __included(base, 'Blacklight::SearchBuilderBehavior')
    end

    # =========================================================================
    # :section: Blacklight::Solr::SearchBuilderBehavior overrides
    # =========================================================================

    public

=begin # NOTE: using base version
    # Start with general defaults from Blacklight config. Need to use custom
    # merge to dup values, to avoid later mutating the original by mistake.
    #
    # @param [Hash] solr_params
    #
    # @return [Hash]
    #
    # This method overrides:
    # @Blacklight::Solr::SearchBuilderBehavior#default_solr_parameters
    #
    def default_solr_parameters(solr_params)
      default_params = blacklight_config.default_solr_params.presence
      default_params &&= default_params.deep_dup
      default_params ||= {}
      solr_params.reverse_merge!(default_params)
    end
=end

=begin # NOTE: using base version
    # Take the user-entered query, and put it in the solr params,
    # including config's "search field" params for current search field.
    # also include setting spellcheck.q.
    #
    # @param [Hash] solr_params
    #
    # @return [void]
    #
    # This method overrides:
    # @Blacklight::Solr::SearchBuilderBehavior#add_query_to_solr
    #
    def add_query_to_solr(solr_params)

      # Merge in search field configured values, if present, overriding
      # general defaults.
      #
      # Legacy behavior of user param :qt is passed through, but overridden by
      # the actual search field config if present. We might want to remove this
      # legacy behavior at some point. It does not seem to be currently rspec'd.
      #
      qt = search_field&.qt.presence || blacklight_params[:qt].presence
      solr_params[:qt] = qt if qt
      solr_parameters = search_field&.solr_parameters.presence
      solr_params.merge!(solr_parameters) if solr_parameters

      # Create Solr 'q' including the user-entered q, prefixed by any Solr
      # LocalParams in config, using Solr LocalParams syntax.
      # @see http://wiki.apache.org/solr/LocalParams
      #
      solr_local_parameters = search_field&.solr_local_parameters.presence
      q =
        if solr_local_parameters
          local_params =
            solr_local_parameters.map { |key, val|
              +"#{key}=" << solr_param_quote(val, quote: %q('))
            }.join(' ')
          "{!#{local_params}}#{blacklight_params[:q]}"
        elsif q.is_a?(Hash)
          solr_params[:spellcheck] = 'false'
          terms =
            if blacklight_params[:q].values.any?(&:blank?)
              'NOT *:*' # If any field params are empty, exclude *all* results.
            else
              blacklight_params[:q].map { |field, values|
                values = Array.wrap(values).map { |v| solr_param_quote(v) }
                values = values.join(' OR ')
                "#{field}:(#{values})"
              }.join(' AND ')
            end
          "{!lucene}#{terms}"
        end

      if q
        # Set Solr spellcheck.q to be original user-entered query, without our
        # local params, otherwise it'll try and spellcheck the local params!
        solr_params['spellcheck.q'] ||= q if solr_local_parameters
        solr_params[:q] = q
      end
    end
=end

=begin # NOTE: using base version
    # Add any existing facet limits (present in the HTTP query as :f) to Solr
    # as the appropriate :fq query.
    #
    # @param [Hash] solr_params
    #
    # @return [void]
    #
    # This method overrides:
    # @Blacklight::Solr::SearchBuilderBehavior#add_facet_fq_to_solr
    #
    def add_facet_fq_to_solr(solr_params)
      # Convert a String value into an Array.
      solr_params[:fq] = [solr_params[:fq]] if solr_params[:fq].is_a?(String)

      # Map :f to :fq.
      f_request_params = blacklight_params[:f] || {}
      f_request_params.each_pair do |facet_field, values|
        Array.wrap(values).each do |value|
          next unless value.present?
          fq_value = facet_value_to_fq_string(facet_field, value)
          solr_params.append_filter_query(fq_value) if fq_value
        end
      end
    end
=end

=begin # NOTE: using base version
    # Add in appropriate Solr facet directives, including taking account of our
    # facet paging/'more'.  This is not about Solr 'fq', this is about Solr
    # 'facet.*' params.
    #
    # @param [Hash] solr_params
    #
    # @return [void]
    #
    # This method overrides:
    # @Blacklight::Solr::SearchBuilderBehavior#add_facetting_to_solr
    #
    def add_facetting_to_solr(solr_params)
      facet_fields_to_include_in_request.each do |field_name, facet|
        solr_params[:facet] ||= true

        if facet.pivot
          value = with_ex_local_param(facet.ex, facet.pivot.join(','))
          solr_params.append_facet_pivot(value)
        elsif facet.query
          value =
            facet.query.map { |_, v| with_ex_local_param(facet.ex, v[:fq]) }
          solr_params.append_facet_query(value)
        else
          value = with_ex_local_param(facet.ex, facet.field)
          solr_params.append_facet_fields(value)
        end

        if facet.sort
          solr_params[:"f.#{facet.field}.facet.sort"] = facet.sort
        end

        (facet.solr_params || {}).each do |k, v|
          solr_params[:"f.#{facet.field}.#{k}"] = v
        end

        limit = facet_limit_with_pagination(field_name)
        solr_params[:"f.#{facet.field}.facet.limit"] = limit if limit
      end
    end
=end

=begin # NOTE: using base version
    # add_solr_fields_to_query
    #
    # @param [Hash] solr_params
    #
    # @return [void]
    #
    # This method overrides:
    # @Blacklight::Solr::SearchBuilderBehavior#add_solr_fields_to_query
    #
    def add_solr_fields_to_query(solr_params)

      blacklight_config.show_fields.each do |key, field_def|
        if should_add_field_to_request?(key, field_def)
          params = field_def.solr_params || {}
          params.each { |k, v| solr_params[:"f.#{field_def.field}.#{k}"] = v }
        end
      end

      blacklight_config.index_fields.each do |key, field_def|
        if field_def.highlight
          solr_params[:hl] = true
          solr_params.append_highlight_field(field_def.field)
        end
        if should_add_field_to_request?(key, field_def)
          params = field_def.solr_params || {}
          params.each { |k, v| solr_params[:"f.#{field_def.field}.#{k}"] = v }
        end
      end

    end
=end

=begin # NOTE: using base version
    # Transmit Blacklight paging parameters to Solr, changing app-level 'page'
    # and 'per_page' to Solr 'rows' and 'start'.
    #
    # @param [Hash] solr_params
    #
    # @return [void]
    #
    # This method overrides:
    # @Blacklight::Solr::SearchBuilderBehavior#add_paging_to_solr
    #
    def add_paging_to_solr(solr_params)
      rows(solr_params[:rows] || 10) if rows.nil?
      solr_params[:rows]  = rows
      solr_params[:start] = start unless start.zero?
    end
=end

=begin # NOTE: using base version
    # Transmit Blacklight sort parameters to Solr.
    #
    # @param [Hash] solr_params
    #
    # @return [void]
    #
    # This method overrides:
    # @Blacklight::Solr::SearchBuilderBehavior#add_sorting_to_solr
    #
    def add_sorting_to_solr(solr_params)
      solr_params[:sort] = sort if sort.present?
    end
=end

=begin # NOTE: using base version
    # Remove the group parameter if we've faceted on the group field (e.g. for
    # the full results for a group).
    #
    # @param [Hash] solr_params
    #
    # @return [void]
    #
    # This method overrides:
    # @Blacklight::Solr::SearchBuilderBehavior#add_group_config_to_solr
    #
    def add_group_config_to_solr(solr_params)
      if blacklight_params&.fetch(:f, nil)&.fetch(grouped_key_for_results, nil)
        solr_params[:group] = false
      end
    end
=end

=begin # NOTE: using base version
    # add_facet_paging_to_solr
    #
    # @param [Hash] solr_params
    #
    # @return [void]
    #
    # This method overrides:
    # @Blacklight::Solr::SearchBuilderBehavior#add_facet_paging_to_solr
    #
    def add_facet_paging_to_solr(solr_params)
      return unless facet.present?

      facet_config = blacklight_config.facet_fields[facet]

      # Now override with our specific things for fetching facet values.
      facet_ex = (facet_config.ex if facet_config.respond_to?(:ex))
      solr_params[:'facet.field'] =
        with_ex_local_param(facet_ex, facet_config.field)

      limit =
        if scope.respond_to?(:facet_list_limit)
          Deprecation.warn(
            self,
            'The use of facet_list_limit is deprecated and will be removed ' \
            "in 7.0. Consider using the 'more_limit' option in the field " \
            "configuration or 'default_more_limit' instead."
          )
          scope.facet_list_limit.to_s.to_i
        elsif solr_params['facet.limit']
          solr_params['facet.limit'].to_i
        else
          facet_config.fetch(:more_limit, blacklight_config.default_more_limit)
        end

      # Need to set as 'f.facet_field.facet.*' to make sure we override any
      # field-specific default in the Solr request handler.
      solr_params[:"f.#{facet_config.field}.facet.limit"]  = limit + 1
      page   = blacklight_params.fetch(request_keys[:page], 1).to_i
      offset = (page - 1) * limit
      solr_params[:"f.#{facet_config.field}.facet.offset"] = offset
      if (sort = blacklight_params[request_keys[:sort]])
        solr_params[:"f.#{facet_config.field}.facet.sort"] = sort
      end
      if (prefix = blacklight_params[request_keys[:prefix]])
        solr_params[:"f.#{facet_config.field}.facet.prefix"] = prefix
      end
      solr_params[:rows] = 0
    end
=end

=begin # NOTE: using base version
    # with_ex_local_param
    #
    # @param [String, nil] ex
    # @param [Object]      value
    #
    # @return [Object]
    #
    # This method overrides:
    # @Blacklight::Solr::SearchBuilderBehavior#with_ex_local_param
    #
    def with_ex_local_param(ex, value)
      ex ? "{!ex=#{ex}}#{value}" : value
    end
=end

=begin # NOTE: using base version
    # Look up facet limit for given facet_field. Will look at config, and
    # if config is 'true' will look up from Solr @response if available. If
    # no limit is available, return nil.
    #
    # Used from #add_facetting_to_solr to supply f.fieldname.facet.limit values
    # in Solr request (no @response available), and used in display (with
    # @response available) to create a facet paginator with the right limit.
    #
    # @param [String, Symbol] facet_field
    #
    # @param [Integer, nil]
    #
    # This method overrides:
    # @Blacklight::Solr::SearchBuilderBehavior#facet_limit_for
    #
    def facet_limit_for(facet_field)
      limit = blacklight_config.facet_fields[facet_field]&.limit
      limit = blacklight_config.default_facet_limit if limit.is_a?(TrueClass)
      limit
    end
=end

=begin # NOTE: using base version
    # Support facet paging and 'more' links, by sending a facet.limit one more
    # than what we want to page at, according to configured facet limits.
    #
    # @param [String, Symbol] facet_field
    #
    # @param [Integer, nil]
    #
    # This method overrides:
    # @Blacklight::Solr::SearchBuilderBehavior#facet_limit_with_pagination
    #
    def facet_limit_with_pagination(facet_field)
      limit = facet_limit_for(facet_field)
      limit += 1 if limit.to_i > 0
      limit
    end
=end

    # A helper method used for generating Solr LocalParams, put quotes around
    # the term unless it's a simple word. Escape internal quotes if needed.
    #
    # @param [String]    value
    # @param [Hash, nil] options
    #
    # @return [String]
    #
    # This method overrides:
    # @Blacklight::Solr::SearchBuilderBehavior#solr_param_quote
    #
    def solr_param_quote(value, options = nil)
      value = value.to_s.squish
      quote = options&.fetch(:quote, nil) || %q(")
      if value =~ /^[a-z0-9$_\-\^]+$/i
        value
      else
        # Strip outer balanced quotes.
        %w( " ' ).each do |c|
          value = value[1..-2] if value.start_with?(c) && value.end_with?(c)
        end
        # Yes, we need crazy escaping here, to deal with regexp esc too!
        value.gsub!(/['"]/, (%q(\\\\) + '\0'))
        "#{quote}#{value}#{quote}"
      end
    end

    # =========================================================================
    # :section: Blacklight::Solr::SearchBuilderBehavior overrides
    # =========================================================================

    private

=begin # NOTE: using base version
    # Convert a facet/value pair into a Solr :fq parameter.
    #
    # @param [String, Symbol] facet_field
    # @param [String]         value
    #
    # @param [String]
    #
    # This method overrides:
    # @Blacklight::Solr::SearchBuilderBehavior#facet_value_to_fq_string
    #
    def facet_value_to_fq_string(facet_field, value)
      facet_config = blacklight_config.facet_fields[facet_field]
      query = facet_config&.query
      if query
        # Exclude all documents if the specified facet key was not found.
        query[value] ? query[value][:fq] : '-*:*'
      else
        solr_field   = (facet_config.field if facet_config) || facet_field
        local_params = ("tag=#{facet_config.tag}" if facet_config&.tag)
        if value.is_a?(Range)
          prefix = nil
          value  = "#{solr_field}:[#{value.first} TO #{value.last}]"
        else
          prefix = "term f=#{solr_field}"
          value  = convert_to_term_value(value)
        end
        prefix = [prefix, local_params].compact.join(' ').presence
        prefix ? "{!#{prefix}}#{value}" : value
      end
    end
=end

=begin # NOTE: using base version
    # convert_to_term_value
    #
    # @param [String] value
    #
    # @return [String]
    #
    # This method overrides:
    # @Blacklight::Solr::SearchBuilderBehavior#convert_to_term_value
    #
    def convert_to_term_value(value)
      if [Date, Time, DateTime].include?(value.class)
        time = value.is_a?(Date) ? value.to_time(:local) : value.utc
        time.strftime('%Y-%m-%dT%H:%M:%SZ')
      else
        value.to_s
      end
    end
=end

=begin # NOTE: using base version
    # The key to use to retrieve the grouped field to display.
    #
    # @return [Symbol]
    #
    # This method overrides:
    # @Blacklight::Solr::SearchBuilderBehavior#grouped_key_for_results
    #
    def grouped_key_for_results
      blacklight_config.index.group
    end
=end

=begin # NOTE: using base version
    # facet_fields_to_include_in_request
    #
    # @return [Array<Blacklight::Configuration::Field>]
    #
    # This method overrides:
    # @Blacklight::Solr::SearchBuilderBehavior#facet_fields_to_include_in_request
    #
    def facet_fields_to_include_in_request
      blacklight_config.facet_fields.select do |_, field_def|
        in_request = field_def.include_in_request
        in_request.nil? || in_request ||
          blacklight_config.add_facet_fields_to_solr_request
      end
    end
=end

=begin # NOTE: using base version
    # request_keys
    #
    # @return [Hash{Symbol=>String}]
    #
    # This method overrides:
    # @Blacklight::Solr::SearchBuilderBehavior#request_keys
    #
    def request_keys
      blacklight_config.facet_paginator_class.request_keys
    end
=end

  end

end

__loading_end(__FILE__)
