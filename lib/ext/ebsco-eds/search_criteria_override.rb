# lib/ext/ebsco-eds/search_criteria_override.rb

__loading_begin(__FILE__)

require_relative 'eds_override'

# =============================================================================
# :section: Inject methods into EBSCO::EDS::SearchCriteria
# =============================================================================

override EBSCO::EDS::SearchCriteria do

  # ===========================================================================
  # :section: Replacement methods
  # ===========================================================================

  public

  # Override initializer to handle translating facets and for :f_inclusive
  # facets.
  #
  # @param [Hash]             options
  # @param [EBSCO::EDS::Info] info
  #
  # This method replaces:
  # @see EBSCO::EDS::SearchCriteria#initialize
  #
  # == Usage Notes
  # The caller is expected to have deep-stringified all *options* keys.
  #
  # Although this accommodates both "inclusive-or" and "exclusive-or" facets,
  # not all combinations will work as expected.  However, this does not appear
  # to be a limitation of the EBSCO EDS gem; the server does not seem to handle
  # these combinations properly.
  #
  # For example:
  #
  #   ?...&f_inclusive[
  #
  def initialize(options, info)

    @Queries      = []
    @FacetFilters = []
    @Limiters     = []

    filter_id = 0

    # Blacklight year range slider input.
    #
    # 'range' => { 'pub_year_tisim' => { 'begin' => '1970', 'end' => '1980'} }
    #
    if (year = options.dig('range', 'pub_year_tisim')).present? # NOTE: 0% coverage for this case
      start_year = year['begin'].presence
      end_year   = year['end'].presence
      range = (start_year || end_year) && "#{start_year}-01/#{end_year}-01"
      @Limiters << { Id: 'DT1', Values: [range] } if range.present?
    end

    # Analyze Blacklight Advanced Search field, if present.
    # NOTE: the "search_field=advanced" case is not handled directly;
    # instead, individual search field queries are handled in the "else" clause
    # of the case statement below.
    search_field = options.delete('search_field').to_s
    field_code =
      EBSCO::EDS::SOLR_SEARCH_TO_EBSCO_FIELD_CODE[search_field] ||
      (search_field if search_field =~ /[A-Z]{2}/)

    # Blacklight Advanced Search logical operator.
    logical_op = options.delete('op').to_s.upcase
    logical_op = nil unless %w(AND OR).include?(logical_op)

    # Process all other parameters.
    #
    options.each do |key, value|

      case key

        # =====================================================================
        # Query
        # =====================================================================

        when 'q', 'query'
          value = value.to_s
          value = '*' if value.blank?
          query = { Term: value }
          query[:FieldCode]       = field_code unless field_code.nil?
          query[:BooleanOperator] = logical_op unless logical_op.nil?
          @Queries << query

        # =====================================================================
        # Mode
        # =====================================================================

        when 'mode' # NOTE: 0% coverage for this case
          available = info.available_search_mode_types
          value     = value.to_s.downcase
          @SearchMode = (value if available.include?(value))

        # =====================================================================
        # Sort
        # =====================================================================

        when 'sort'
          value = value.to_s.downcase
          @Sort = (value if info.available_sorts(value).present?)
          @Sort ||=
            case value
              when 'newest', 'pub_date_sort desc' then 'date'
              when 'oldest', 'pub_date_sort asc'  then 'date2'
              when 'score desc'                   then 'relevance'
            end

        # =====================================================================
        # Publication ID
        # =====================================================================

        when 'publication_id' # NOTE: 0% coverage for this case
          @PublicationId = value.to_s

        # =====================================================================
        # Auto suggest & correct
        # =====================================================================

        when 'auto_suggest' # NOTE: 0% coverage for this case
          @AutoSuggest = value ? 'y' : 'n'

        when 'auto_correct' # NOTE: 0% coverage for this case
          @AutoCorrect = value ? 'y' : 'n'

        # =====================================================================
        # Expanders
        # =====================================================================

        when 'expanders' # NOTE: 0% coverage for this case
          available = info.available_expander_ids
          expanders =
            Array.wrap(value)
              .map    { |item| item.to_s.downcase }
              .select { |item| available.include?(item) }
          if expanders.present?
            @Expanders ||= []
            @Expanders += expanders
          end

        # =====================================================================
        # Related content
        # =====================================================================

        when 'related_content' # NOTE: 0% coverage for this case
          available = info.available_related_content_types
          related_content =
            Array.wrap(value)
              .map    { |item| item.to_s.downcase }
              .select { |item| available.include?(item) }
          if related_content.present?
            @RelatedContent ||= []
            @RelatedContent += related_content
          end

        # =====================================================================
        # Facets
        # =====================================================================

        when 'include_facets' # NOTE: 0% coverage for this case
          @IncludeFacets = value ? 'y' : 'n'

        when 'facet_filters' # NOTE: 0% coverage for this case
          @FacetFilters += Array.wrap(value).reject(&:blank?)

        # =====================================================================
        # Solr filter query (Blacklight Advanced Search)
        #
        # ==== Examples:
        # '{!term f=eds_publication_facet}New York Times'
        # '{!term f=eds_publication_year_facet tag=eds_publication_year_facet_single}2013'
        # 'eds_content_provider_facet:("ERIC" OR  "JSTOR Journals")'
        # =====================================================================

        when 'fq'
          @FacetFilters +=
            Array.wrap(value).flat_map { |filter_query|
              $stderr.puts ">>>>>>>>>>> filter_query #{filter_query.inspect}"
              facet_type = facet_name = facet_values = nil
              case filter_query
                when /^{!terms? (f[^=]*)=([^}]+)}(.+)$/
                  facet_type, facet_name, facet_values = $1, $2, $3
                  facet_type   = facet_type.to_s.presence
                  facet_name   = facet_name.to_s.sub(/ +tag=.*$/, '').presence
                  facet_values = facet_values.to_s.split(',').presence
                when /^([^:]+):\((.*)\)$/
                  facet_name, facet_values = $1, $2
                  facet_name   = facet_name.to_s.presence
                  if (array = facet_values.to_s.split(/ +OR +/)).size > 1
                    facet_type   = 'f_inclusive'
                    facet_values = array
                  elsif (array = facet_values.to_s.split(/ +AND +/)).size > 1
                    facet_type   = 'f'
                    facet_values = array
                  else
                    facet_values = []
                  end
                  facet_values.map! { |v| v.sub(/^\\?"+(.*)\\?"+$/, '\1') }
                  $stderr.puts ">>>>>>>>>>> values #{facet_values.inspect}"
              end
              next unless facet_type && facet_name && facet_values.present?
              ef = EBSCO::EDS::SOLR_FACET_TO_EBSCO_FACET[facet_name]
              case facet_type
                when 'f_inclusive'
                  filter_id += 1
                  facet_filter(filter_id, ef, facet_values)
                when 'f'
                  facet_values.map { |facet_value|
                    filter_id += 1
                    facet_filter(filter_id, ef, facet_value)
                  }
              end
            }.compact

        # =====================================================================
        # Solr "inclusive-or" facets for Blacklight Advanced Search
        # =====================================================================

        when 'f_inclusive'
          @FacetFilters +=
            EBSCO::EDS::SOLR_FACET_TO_EBSCO_FACET.map { |sf, ef|
              facet_values = Array.wrap(value[sf]).reject(&:blank?)
              next unless facet_values.present?
              filter_id += 1
              facet_filter(filter_id, ef, facet_values)
            }.compact

        # =====================================================================
        # Solr "exclusive-or" facets and limiters
        # =====================================================================

        when 'f'
          @FacetFilters +=
            EBSCO::EDS::SOLR_FACET_TO_EBSCO_FACET.flat_map { |sf, ef|
              facet_values = Array.wrap(value[sf]).reject(&:blank?)
              facet_values.map { |facet_value|
                filter_id += 1
                facet_filter(filter_id, ef, facet_value)
              }
            }

          # Only handle 'select' limiters (ones with values of 'y' or 'n').
          values = Array.wrap(value['eds_search_limiters_facet'])
          @Limiters +=
            info.available_limiters.map { |limiter|
              next unless limiter['Type'] == 'select'
              id = limiter['Id']
              if values.include?(id) || values.include?(limiter['Label'])
                { Id: id, Values: ['y'] }
              end
            }.compact

          # Date limiters.
          yy = Date.today.year
          mm = Date.today.month
          @Limiters +=
            Array.wrap(value['eds_publication_year_range_facet']).map { |item| # NOTE: 0% coverage for this case
              range =
                case item.to_s.capitalize
                  when 'This year'     then "#{yy}-01/#{yy}-#{mm}"
                  when 'Last 3 years'  then "#{yy-3}-#{mm}/#{yy}-#{mm}"
                  when 'Last 10 years' then "#{yy-10}-#{mm}/#{yy}-#{mm}"
                  when 'Last 50 years' then "#{yy-50}-#{mm}/#{yy}-#{mm}"
                  when 'More than 50 years ago' then "0000-01/#{yy-50}-12"
                end
              { Id: 'DT1', Values: [range] } if range.present?
            }.compact

        # =====================================================================
        # Limiters
        # =====================================================================

        when 'limiters' # NOTE: 0% coverage for this case
          available = info.available_limiter_ids
          @Limiters +=
            Array.wrap(value).map { |item|
              parts = item.to_s.split(':', 2)
              l_key = parts.shift.upcase
              next unless available.include?(l_key)
              # If multi-value, add the values if they're available.
              # Do nothing if none of the values are available.
              # TODO: make case insensitive?
              limiter = parts.join(':')
              if info.available_limiters(l_key)['Type'] == 'multiselectvalue'
                l_avail = info.available_limiter_values(l_key)
                limiter = limiter.split(',').select { |v| l_avail.include?(v) }
              end
              limiter = Array.wrap(limiter).compact
              { Id: l_key, Values: limiter } if limiter.present?
            }.compact

        # =====================================================================
        # Blacklight Advanced Search query
        # =====================================================================

        else
          fc = EBSCO::EDS::SOLR_SEARCH_TO_EBSCO_FIELD_CODE[key]
          if fc.present? && value.present?
            query = { FieldCode: fc, Term: value.to_s }
            query[:BooleanOperator] = logical_op unless logical_op.nil?
            @Queries << query
          else
            Rails.logger.debug {
              "EDS SearchCriteria: ignoring param #{key} = #{value.inspect}"
            }
          end

      end

    end

    # Remove null search if it is not needed because other search terms were
    # introduced.
    Queries << { Term: '*', BooleanOperator: logical_op } unless logical_op.nil?
    non_null = @Queries.reject { |q| q[:Term] == '*' }
    @Queries = non_null unless non_null.empty?

    # Because there is some inconsistent usage of Symbol versus String for hash
    # keys, ensure that all hashes generated here can accomodate that.
    normalize!(@Queries)
    normalize!(@FacetFilters)
    normalize!(@Limiters)

    # Defaults.
    @AutoCorrect    ||= info.default_auto_correct
    @AutoSuggest    ||= info.default_auto_suggest
    @Expanders      ||= info.default_expander_ids
    @RelatedContent ||= info.default_related_content_types
    @SearchMode     ||= info.default_search_mode
    @IncludeFacets  ||= 'y'
    @Sort           ||= 'relevance'

  end

  # ===========================================================================
  # :section: Added methods
  # ===========================================================================

  private

  # Create an entry for @FacetFilters.
  #
  # @param [Integer]               filter_id
  # @param [String]                ebsco_facet
  # @param [String, Array<String>] values
  #
  # @return [Hash]
  #
  def facet_filter(filter_id, ebsco_facet, values)
    values = Array.wrap(values)
    values = values.map { |value| { Id: ebsco_facet, Value: value } }
    { FilterId: filter_id, FacetValues: values }
  end

  # Convert hashes to ActiveSupport::HashWithIndifferentAccess.
  #
  # @param [Array<Hash>] array        Array of hashes to modify.
  #
  # @return [Array<ActiveSupport::HashWithIndifferentAccess>]
  #
  def normalize!(array)
    array.map! do |entry|
      entry.is_a?(Hash) ? entry.with_indifferent_access : entry
    end
  end

end

__loading_end(__FILE__)
