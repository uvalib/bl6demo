# app/models/concerns/blacklight/eds/suggest/response_eds.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'sanitize'
require 'blacklight/eds'

module Blacklight::Eds
  module Suggest

    # Blacklight::Eds::Suggest::ResponseEds
    #
    # @see Blacklight::Suggest::Response
    #
    class ResponseEds < Blacklight::Suggest::Response

      # TODO: share with Blacklight::Eds::SuggestSearchEds
      SUGGEST_FIELDS = {
        title:       %i(eds_title eds_other_titles),
        author:      %i(eds_authors),
        journal:     %i(eds_source_title eds_series),
        subject:     %i(eds_subjects),
        keyword:     %i(eds_author_supplied_keywords),
        isbn:        %i(eds_isbns),
        issn:        %i(eds_issns),
        call_number: nil,
        published:   %i(eds_publisher),
      }.stringify_keys.freeze

      # =======================================================================
      # :section: Blacklight::Suggest::Response overrides
      # =======================================================================

      public

=begin # NOTE: using base version
      attr_reader :response, :request_params, :suggest_path
=end

=begin # NOTE: using base version
      # Initialize a new self instance.
      #
      # @param [RSolr::HashWithResponse] response
      # @param [Hash]                    request_params
      # @param [String]                  suggest_path
      #
      # This method overrides:
      # @see Blacklight::Suggest::Response#initialize
      #
      def initialize(response, request_params, suggest_path)
        @response       = response
        @request_params = request_params
        @suggest_path   = suggest_path
      end
=end

      # Extracts suggested terms from the suggester response.
      #
      # @return [Array<Hash{String=>String}>]
      #
      # This method overrides:
      # @see Blacklight::Suggest::Response#suggestions
      #
      # TODO: there is probably a better way to handle this through the EDS API
      #
      def suggestions
=begin
        $stderr.puts ">>> #{__method__}: response #{response.pretty_inspect}"                  # TODO: debugging - remove
=end
        $stderr.puts ">>> #{__method__}: request_params #{request_params.pretty_inspect}"      # TODO: debugging - remove
        $stderr.puts ">>> #{__method__}: suggest_path #{suggest_path.pretty_inspect}"          # TODO: debugging - remove
        query =
          request_params[:q].to_s.squish.downcase
            .sub(/^[^a-z0-9_]+/, '').sub(/[^a-z0-9_]+$/, '')
            .split(' ')
        $stderr.puts ">>> #{__method__}: query #{query.inspect}"                               # TODO: debugging - remove
        docs = response.dig('response', 'docs') || []
        $stderr.puts ">>> #{__method__}: docs #{docs.size}"                                    # TODO: debugging - remove

        search = request_params[:search_field].to_s
        fields = SUGGEST_FIELDS[search] || SUGGEST_FIELDS.values.flatten
        docs
          .map { |doc|
            # To prepare for sorting by descending order of usefulness, transform
            # each *doc* into an array with these elements:
            # [0] all_score - terms with all matches to the top
            # [1] any_score - terms with most matches to the top
            # [2] score     - tie-breaker sort by descending relevancy
            # [3..-1]       - fields with terms
            terms =
              doc.slice(*fields).values.flatten.map { |term|
                Sanitize.fragment(term).downcase if term.is_a?(String)
              }.compact
            any = query.count { |qt| terms.any? { |term| term.include?(qt) } }
            next if any.zero?
            all = query.count { |qt| terms.all? { |term| term.include?(qt) } }
            terms.unshift(-doc[:eds_relevancy_score].to_f)
            terms.unshift(query.size - any)
            terms.unshift(query.size - all)
          }
          .compact
          .tap { |result| $stderr.puts ">>> #{__method__}: raw terms #{result.inspect}" }      # TODO: debugging - remove
          .sort
          .map { |terms| terms.shift(3); terms } # Remove non-search-terms.
          .flatten
          .uniq
          .select { |term| query.any? { |qt| term.include?(qt) } }
          .tap { |result| $stderr.puts ">>> #{__method__}: matching terms #{result.inspect}" } # TODO: debugging - remove
          .sort_by { |t| query.size - query.count { |qt| t.include?(qt) } }
          .map { |term| { 'term' => term, 'weight' => 1, 'payload' => '' } }
          .tap { |result| $stderr.puts ">>> #{__method__}: results #{result.inspect}" }        # TODO: debugging - remove
      end

    end

  end
end

__loading_end(__FILE__)
