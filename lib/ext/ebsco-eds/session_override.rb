# lib/ext/ebsco-eds/session_override.rb

__loading_begin(__FILE__)

require_relative 'eds_override'

# =============================================================================
# :section: Inject methods into EBSCO::EDS::Session
# =============================================================================

override EBSCO::EDS::Session do

  # ===========================================================================
  # :section: Replacement methods
  # ===========================================================================

  public

  # Performs a search.
  #
  # @param [Hash]    options
  # @param [Boolean] add_actions      Default: *false*.
  # @param [Boolean] increment_page   Default: *true*.
  #
  # @return [EBSCO::EDS::Results]
  #
  # == Options
  # * :query            - The search terms. (REQUIRED)
  #                       Format: {booleanOperator},{fieldCode}:{term}.
  #                       Example: SU:Hiking
  #
  # * :mode             - Search mode to be used.
  #                       Either: 'all' (default), 'any', 'bool', 'smart'
  #
  # * :results_per_page - The number of records retrieved with the search
  #                       results (between 1-100, default is 20).
  #
  # * :page             - Starting page number for the result set returned from
  #                       a search (if results per page = 10, and page number =
  #                       3 , this implies: I am expecting 10 records starting
  #                       at page 3).
  #
  # * :sort             - The sort order for the search results.
  #                       Either: 'relevance' (default), 'oldest', 'newest'
  #
  # * :highlight        - Specifies whether or not the search term is
  #                       highlighted using <highlight /> tags.
  #                       Either 'true' or 'false'.
  #
  # * :include_facets   - Specifies whether or not the search term is
  #                       highlighted using <highlight /> tags.
  #                       Either 'true' (default) or 'false'.
  #
  # * :facet_filters    - Facets to apply to the search. Facets are used to
  #                       refine previous search results.
  #                       Format: \{filterID},{facetID}:{value}[,{facetID}:{value}]*
  #                       Example: 1,SubjectEDS:food,SubjectEDS:fiction
  #
  # * :view             - Specifies the amount of data to return with the
  #                       response. Either:
  #                         'title': title only;
  #                         'brief' (default): Title + Source, Subjects;
  #                         'detailed': Brief + full abstract
  #
  # * :actions          - Actions to take on the existing query specification.
  #                       Example: addfacetfilter(SubjectGeographic:massachusetts)
  #
  # * :limiters         - Criteria to limit the search results by.
  #                       Example: LA99:English,French,German
  #
  # * :expanders        - Expanders that can be applied to the search.
  #                       Either: 'thesaurus', 'fulltext', 'relatedsubjects'
  #
  # * :publication_id   - Publication to search within.
  #
  # * :related_content  - Comma separated list of related content types to
  #                       return with the search results. Either:
  #                         'rs' (Research Starters)
  #                         'emp' (Exact Publication Match)
  #
  # * :auto_suggest     - Specifies whether or not to return search suggestions
  #                       along with the search results.
  #                       Either 'true' or 'false' (default).
  #
  # == Examples
  #
  #   results = session.search({
  #     query:            'abraham lincoln',
  #     results_per_page: 5,
  #     related_content:  ['rs','emp']
  #   })
  #
  #   results = session.search({
  #     query:            'volcano',
  #     results_per_page: 1,
  #     publication_id:   'eric',
  #     include_facets:   false
  #   })
  #
  # This method replaces:
  # @see EBSCO::EDS::Session#search
  #
  def search(options = {}, add_actions = false, increment_page = true)

    options = options.deep_stringify_keys
    @search_results = nil

    # Only perform a search when there are query terms since certain EDS
    # profiles will throw errors when given empty queries.
    if (options.keys & %w(query q)).present?

      # Create/recreate the search options if nil or not passing actions.
      @search_options = nil unless add_actions
      @search_options ||= EBSCO::EDS::Options.new(options, @info)

      # Get search results.
      @search_results = get_results(@search_options, options)
      @current_page   = @search_results.page_number if increment_page
      $stderr.puts "||| EBSCO #{__method__}: @search_options = #{@search_options.pretty_inspect}"    # TODO: debugging - remove
      $stderr.puts "||| EBSCO #{__method__}: response = #{@search_results.results.pretty_inspect}"   # TODO: debugging - remove
=begin
=end
      $stderr.puts "||| EBSCO #{__method__}: @config = #{@config}"                                   # TODO: debugging - remove
=begin
      $stderr.puts "||| EBSCO #{__method__}: @info.available_limiters = #{@info.available_limiters}" # TODO: debugging - remove
=end
      $stderr.puts "||| EBSCO #{__method__}: options = #{options}"                                   # TODO: debugging - remove

      # Create temporary facet results if needed.
      # TODO: should this also be considering 'f_inclusive' facets?
      facets = options['f']
      if facets.present?
        # Create temporary format facet results if needed.
        target_facet = 'eds_publication_type_facet'
        if facets.key?(target_facet)
          tmp_options = options.except('f')
          tmp_options['f'] = options['f'].except(target_facet)
          tmp_search_options = EBSCO::EDS::Options.new(tmp_options, @info)
          tmp_search_options.Comment = 'temp source type facets'
          @search_results.temp_format_facet_results =
            get_results(tmp_search_options, tmp_options)
        end
        # Create temporary content provider facet results if needed.
        target_facet = 'eds_content_provider_facet'
        if facets.key?(target_facet)
          tmp_options = options.except('f')
          tmp_options['f'] = options['f'].except(target_facet)
          tmp_search_options = EBSCO::EDS::Options.new(tmp_options, @info)
          tmp_search_options.Comment = 'temp content provider facet'
          @search_results.temp_content_provider_facet_results =
            get_results(tmp_search_options, tmp_options)
        end
      end

    elsif @search_options.present? #options.blank? && @search_options.present?

      # Use existing/updated SearchOptions.
      @search_results = get_results(@search_options, options)
      @current_page   = @search_results.page_number if increment_page

    else

      @search_results = EBSCO::EDS::Results.new(empty_results, @config)

    end

    @search_results
  end

  # Display @search_options if debugging (@debug is *true*).
  #
  # @param [Symbol]              method
  # @param [String]              path
  # @param [EBSCO::EDS::Options] payload
  #
  # This method replaces:
  # @see EBSCO::EDS::Session#do_request
  #
  def do_request(method, path:, payload: nil, attempt: 0)
    if @debug
      puts 'EDS REQUEST ' \
            "method #{method.inspect}, " \
            "path #{path.inspect}, " \
            "payload #{payload.pretty_inspect}"
    end
    super # Call the original method.
  end

  # ===========================================================================
  # :section: Added methods
  # ===========================================================================

  public

  # Create a new method in order to query the session for the value of @guest.
  #
  # @return [Boolean]
  #
  def guest
    @guest
  end

  # ===========================================================================
  # :section: Added methods
  # ===========================================================================

  private

  # Perform an API request an encapsulate the results.
  #
  # @param [Hash]      payload
  # @param [Hash, nil] options
  #
  # @return [EBSCO::EDS::Results]
  #
  def get_results(payload, options = {})
    resp = do_request(:post, path: '/edsapi/rest/Search', payload: payload)
    EBSCO::EDS::Results.new(resp, @config, @info.available_limiters, options)
  end

end

__loading_end(__FILE__)
