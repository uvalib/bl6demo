# lib/ext/ebsco-eds/retrieval_criteria_override.rb

__loading_begin(__FILE__)

require_relative 'eds_override'

# =============================================================================
# :section: Inject methods into EBSCO::EDS::RetrievalCriteria
# =============================================================================

override EBSCO::EDS::RetrievalCriteria do

  # ===========================================================================
  # :section: New methods
  # ===========================================================================

  public

  # The starting row, which may be given in place of a page.
  #
  # @return [Integer, nil]
  #
  attr_accessor :Offset

  # ===========================================================================
  # :section: Replacement methods
  # ===========================================================================

  public

  # Override initializer to handle facet pagination.
  #
  # @param [Hash]             options
  # @param [EBSCO::EDS::Info] info
  #
  # This method replaces:
  # @see EBSCO::EDS::RetrievalCriteria#initialize
  #
  # == Usage Notes
  # The caller is expected to have deep-stringified all *options* keys.
  #
  # TODO: This override may no longer be necessary...
  #
  def initialize(options, info)

    options.each do |key, value|

      case key

        # =====================================================================
        # View
        # =====================================================================

        when 'view'
          value = value.to_s.downcase
          @View = (value if info.available_result_list_views.include?(value))

        # =====================================================================
        # Results per page
        # =====================================================================

        when 'rows', 'per_page', 'results_per_page'
          @ResultsPerPage = [value.to_i, info.max_results_per_page].min

        # =====================================================================
        # Row offset
        # =====================================================================

        when 'start' # Solr starts at row 0.
          @Offset = value.to_i + 1

        # =====================================================================
        # Page number
        # =====================================================================

        when 'page', 'page_number'
          @PageNumber = value.to_i

        # =====================================================================
        # Highlight
        # =====================================================================

        when 'highlight'
          @Highlight = value.to_s

        when 'hl' # Solr/Blacklight version
          # API bug: if set to 'n' you won't get research starter abstracts!
          @Highlight = (value == 'on') ? 'y' : 'y'

        # =====================================================================
        # Anything else
        # =====================================================================

        else
          Rails.logger.debug {
            "EDS RetrievalCriteria: ignoring param #{key} = #{value.inspect}"
          }

      end

    end

    # Resolve page versus offset.
    @PageNumber ||= (@Offset / @ResultsPerPage) + 1 if @Offset

    # Apply defaults where values where not explicitly given.
    @View           ||= info.default_result_list_view
    @ResultsPerPage ||= info.default_results_per_page
    @PageNumber     ||= 1

  end

end

__loading_end(__FILE__)
