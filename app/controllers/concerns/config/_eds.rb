# app/controllers/concerns/config/_eds.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '_constants'
require_relative 'catalog'
require 'blacklight/eds'

module Config::Eds

  include Config::Constants

  # === Common field values ===
  # Certain "index" and "show" configuration fields have the same values based
  # on the relevant fields defined by the search service.
  EDS_FIELD = {
    display_type_field: :eds_publication_type,  # TODO: Could remove to avoid partial lookups by display type if "_default" is the only appropriate partial.
    title_field:        :eds_title,
    subtitle_field:     :eds_other_titles,      # TODO: ???
    alt_title_field:    nil,                    # TODO: ???
    author_field:       :eds_authors,
    alt_author_field:   nil,                    # TODO: ???
    thumbnail_field:    %i(eds_cover_medium_url eds_cover_thumb_url),
  }

  # ===========================================================================
  # :section:
  # ===========================================================================

  # The Blacklight configuration for lenses using EBSCO EDS search.
  #
  # This derives from the configuration for the Catalog lens.
  #
  # @return [Blacklight::Configuration]
  #
  # @see Config::Catalog#CATALOG_CONFIG
  # @see Blacklight::Configuration#default_values
  #
  def self.instance
    @instance ||= Config::Catalog.new.deep_copy.tap do |config|

      # === Search request configuration ===

=begin
      # HTTP method to use when making requests to Solr; valid values are
      # :get and :post.
      #config.http_method = :get

      # Solr path which will be added to Solr base URL before the other Solr
      # params.
      #config.solr_path = 'select'

      # Default parameters to send to Solr for all search-like requests.
      # @see Blacklight::SearchBuilder#processed_parameters
      config.default_solr_params = {
        qt:   'search',
        rows: 10,
        #'facet.sort': 'index' # Sort by byte order rather than by count.
      }
=end

      # === Single document request configuration ===

=begin
      # The Solr request handler to use when requesting only a single document.
      #config.document_solr_request_handler = 'document'

      # The path to send single document requests to Solr (if different than
      # 'config.solr_path').
      #config.document_solr_path = nil

      # Primary key for indexed documents.
      #config.document_unique_id_param = :id

      # Default parameters to send on single-document requests to Solr. These
      # settings are the Blacklight defaults (see SearchHelper#solr_doc_params)
      # or parameters included in the Blacklight-jetty document requestHandler.
      #config.default_document_solr_params = {
      #  qt: 'document',
      #  ## These are hard-coded in the blacklight 'document' requestHandler
      #  # fl: '*',
      #  # rows: 1,
      #  # q: '{!term f=id v=$id}'
      #}

      # Base Solr parameters for pagination of single documents.
      # @see Blacklight::RequestBuilders#previous_and_next_document_params
      #config.document_pagination_params = {}
=end

      # === Response models ===

      # Class for sending and receiving requests from a search index.
      config.repository_class = Blacklight::Eds::Repository

      # Class for converting Blacklight's URL parameters into request
      # parameters for the search index via repository_class.
      config.search_builder_class = ::SearchBuilderEds

      # Model that maps search index responses to Blacklight responses.
      config.response_model = Blacklight::Eds::Response

      # The model to use for each response document.
      config.document_model = EdsDocument

      # Class for paginating long lists of facet fields.
      #config.facet_paginator_class = Blacklight::Solr::FacetPaginator

      # Repository connection configuration.
      # NOTE: For the standard catalog this is based on blacklight.yml;
      # for alternate lenses this might allow for an alternate Solr to be
      # accessed by providing an alternate blacklight.yml.
      #config.connection_config = ...

      # === Configuration for navbar ===
      #
      # @see Blacklight::Configuration#add_nav_action
      #
      #config.navbar = OpenStructWithHashAccess.new(partials: {})

      # === Configuration for search results/index views ===
      #
      # @see Blacklight::Configuration::ViewConfig::Index
      #
      #config.index.document_presenter_class = Blacklight::IndexPresenterExt
      config.index.display_type_field = EDS_FIELD[:display_type_field]
      config.index.title_field        = EDS_FIELD[:title_field]
      config.index.subtitle_field     = EDS_FIELD[:subtitle_field]
      config.index.alt_title_field    = EDS_FIELD[:alt_title_field]
      config.index.author_field       = EDS_FIELD[:author_field]
      config.index.alt_author_field   = EDS_FIELD[:alt_author_field]
      config.index.thumbnail_field    = EDS_FIELD[:thumbnail_field].last

      # === Configuration for document/show views ===
      #
      # @see Blacklight::Configuration::ViewConfig::Show
      #
      #config.show.document_presenter_class = Blacklight::ShowPresenterExt
      config.show.display_type_field  = EDS_FIELD[:display_type_field]
      config.show.title_field         = EDS_FIELD[:title_field]
      config.show.subtitle_field      = EDS_FIELD[:subtitle_field]
      config.show.alt_title_field     = EDS_FIELD[:alt_title_field]
      config.show.author_field        = EDS_FIELD[:author_field]
      config.show.alt_author_field    = EDS_FIELD[:alt_author_field]
      config.show.thumbnail_field     = EDS_FIELD[:thumbnail_field]
      config.show.route               = { controller: :articles }
      #config.show.partials            = [:show_header, :thumbnail, :show]

      # === Configurations for specific types of index views ===
      #
      # @see Blacklight::Configuration#view_config
      #
      #config.view =
      #  Blacklight::NestedOpenStructWithHashAccess.new(
      #    Blacklight::Configuration::ViewConfig,
      #    'list',
      #    atom: { if: false, partials: [:document] },
      #    rss:  { if: false, partials: [:document] },
      #  )

      # === Facet fields ===
      # Solr fields that will be treated as facets by the application.
      # (The ordering of the field names is the order of display.)
      #
      # @see Blacklight::Configuration::Files::ClassMethods#define_field_access
      #
      # Begin by clearing the fields that were set by Config::Catalog.
      #
      config.facet_fields.clear
      config.add_facet_field :eds_search_limiters_facet,        label: 'Search Limiters'
      config.add_facet_field :eds_library_location_facet,       label: 'Library Location'
      config.add_facet_field :eds_library_collection_facet,     label: 'Library Collection'
      config.add_facet_field :eds_author_university_facet,      label: 'Author University'
      config.add_facet_field :eds_publication_type_facet,       label: 'Format'
      config.add_facet_field :eds_publication_year_facet,       label: 'Publication Year' #,    single: true
      config.add_facet_field :eds_publication_year_range_facet, label: 'Date Range',          single: true # TODO: testing
      config.add_facet_field :eds_category_facet,               label: 'Category'
      config.add_facet_field :eds_subject_topic_facet,          label: 'Topic'
      config.add_facet_field :eds_language_facet,               label: 'Language'
      config.add_facet_field :eds_journal_facet,                label: 'Journal'
      config.add_facet_field :eds_subjects_geographic_facet,    label: 'Geography'
      config.add_facet_field :eds_publisher_facet,              label: 'Publisher'
      config.add_facet_field :eds_content_provider_facet,       label: 'Content Provider'
      #
      # End by supplying options that apply to multiple field configurations.
      #
      config.facet_fields.each_pair do |key, field_def|

        key = key.to_sym

        case key
          when :eds_search_limiters_facet then -1
          else                                 20
        end.tap { |limit| field_def.limit = limit if limit }

        case key
          when :eds_search_limiters_facet then 'index'
          else                                 'count'
        end.tap { |sort| field_def.sort = sort if sort }

        case key
          when :eds_search_limiters_facet then 'A'..'Z'
          #else                                 'A'..'Z'
          else                                 "\x20".."\x7E"
        end.tap { |range| field_def.index_range = range if range }

      end

      # Have BL send all facet field names to Solr, which has been the default
      # previously. Simply remove these lines if you'd rather use Solr request
      # handler defaults, or have no facets.
      config.add_facet_fields_to_solr_request!

      # === Index (results page) metadata fields ===
      # Solr fields to be displayed in the index (search results) view.
      # (The ordering of the field names is the order of the display.)
      #
      # @see Blacklight::Configuration::Files::ClassMethods#define_field_access
      #
      # NOTE: 'Title' (:eds_title) is displayed by IndexPresenterExt#label.
      # NOTE: 'Published in' (:eds_composed_title), if present, eliminates the
      # need for separate :eds_source_title, :eds_publication_info, and
      # :eds_publication_date entries.
      #
      # Begin by clearing the fields that were set by Config::Catalog.
      #
      config.index_fields.clear
      #config.add_index_field :eds_title,                   label: 'Title'
      config.add_index_field :eds_publication_type,         label: 'Format',            helper_method: :eds_publication_type_label
      config.add_index_field :eds_authors,                  label: 'Author'
      config.add_index_field :eds_composed_title,           label: 'Published in',      helper_method: :eds_index_publication_info
      config.add_index_field :eds_languages,                label: 'Language'
      config.add_index_field :eds_html_fulltext_available,  label: 'Full text on page', helper_method: :fulltext_link
      #config.add_index_field :id,                          label: 'ID'
      config.add_index_field :eds_relevancy_score,          label: '[eds_relevancy_score]'

      # === Item details (show page) metadata fields ===
      # Solr fields to be displayed in the show (single result) view.
      # (The ordering of the field names is the order of display.)
      #
      # @see Blacklight::Configuration::Files::ClassMethods#define_field_access
      #
      # NOTE: ShowPresenterExt#heading displays :eds_title and :eds_authors so
      # they do not need to be included here.
      #
      # Begin by clearing the fields that were set by Config::Catalog.
      #
      config.show_fields.clear
      #config.add_show_field :eds_title,                        label: 'Title'
      #config.add_show_field :eds_authors,                      label: 'Author'
      config.add_show_field :eds_publication_type,              label: 'Format',          helper_method: :eds_publication_type_label
      config.add_show_field :eds_document_type,                 label: 'Document Type'
      config.add_show_field :eds_publication_status,            label: 'Status'
      config.add_show_field :eds_other_titles,                  label: 'Other Titles'
      config.add_show_field :eds_composed_title,                label: 'Published in'
      config.add_show_field :eds_languages,                     label: 'Language'
      config.add_show_field :eds_source_title,                  label: 'Journal'
      config.add_show_field :eds_series,                        label: 'Series'
      config.add_show_field :eds_publication_year,              label: 'Year'
      config.add_show_field :eds_volume,                        label: 'Volume'
      config.add_show_field :eds_issue,                         label: 'Issue'
      config.add_show_field :eds_page_count,                    label: 'Page Count'
      config.add_show_field :eds_start_page,                    label: 'Start Page'
      config.add_show_field :eds_publication_info,              label: 'Published'
      config.add_show_field :eds_publisher,                     label: 'Publisher'
      config.add_show_field :eds_publication_date,              label: 'Publication Date'
      config.add_show_field :eds_document_doi,                  label: 'DOI',             helper_method: :doi_link
      config.add_show_field :eds_document_oclc,                 label: 'OCLC'
      config.add_show_field :eds_issns,                         label: 'ISSN'
      config.add_show_field :eds_issbs,                         label: 'ISBN'
      config.add_show_field :eds_all_links,                     label: 'Availability',    helper_method: :all_eds_links
      config.add_show_field :eds_plink,                         label: 'EBSCO Record',    helper_method: :ebsco_eds_plink
      #config.add_show_field :eds_fulltext_links,                label: 'Fulltext',        helper_method: :best_fulltext # NOTE: not working right
      config.add_show_field :eds_abstract,                      label: 'Abstract'
      config.add_show_field :eds_notes,                         label: 'Notes'
      config.add_show_field :eds_physical_description,          label: 'Description'
      config.add_show_field :eds_html_fulltext,                 label: 'Full Text',       helper_method: :html_fulltext
      config.add_show_field :eds_publication_type_id,           label: '[eds_publication_type_id]'
      config.add_show_field :eds_access_level,                  label: '[eds_access_level]'
      config.add_show_field :eds_authors_composed,              label: '[eds_authors_composed]'
      config.add_show_field :eds_author_affiliations,           label: '[eds_author_affiliations]'
      config.add_show_field :eds_issn_print,                    label: '[eds_issn_print]'
      config.add_show_field :eds_isbn_print,                    label: '[eds_isbn_print]'
      config.add_show_field :eds_isbn_electronic,               label: '[eds_isbn_electronic]'
      config.add_show_field :eds_isbns_related,                 label: '[eds_isbns_related]'
      config.add_show_field :eds_subjects,                      label: '[eds_subjects]'
      config.add_show_field :eds_subjects_geographic,           label: '[eds_subjects_geographic]'
      config.add_show_field :eds_subjects_person,               label: '[eds_subjects_person]'
      config.add_show_field :eds_subjects_company,              label: '[eds_subjects_company]'
      config.add_show_field :eds_subjects_bisac,                label: '[eds_subjects_bisac]'
      config.add_show_field :eds_subjects_mesh,                 label: '[eds_subjects_mesh]'
      config.add_show_field :eds_subjects_genre,                label: '[eds_subjects_genre]'
      config.add_show_field :eds_author_supplied_keywords,      label: '[eds_author_supplied_keywords]'
      config.add_show_field :eds_subset,                        label: '[eds_subset]'
      config.add_show_field :eds_code_naics,                    label: '[eds_code_naics]'
      config.add_show_field :eds_fulltext_word_count,           label: '[eds_fulltext_word_count]'
      config.add_show_field :eds_covers,                        label: '[eds_covers]'
      config.add_show_field :eds_cover_thumb_url,               label: '[eds_cover_thumb_url]', helper_method: :url_link
      config.add_show_field :eds_cover_medium_url,              label: '[eds_cover_medium_url]', helper_method: :url_link
      config.add_show_field :eds_images,                        label: '[eds_images]'
      config.add_show_field :eds_pdf_fulltext_available,        label: '[eds_pdf_fulltext_available]'
      config.add_show_field :eds_ebook_pdf_fulltext_available,  label: '[eds_ebook_pdf_fulltext_available]'
      config.add_show_field :eds_ebook_epub_fulltext_available, label: '[eds_ebook_epub_fulltext_available]'
      config.add_show_field :eds_abstract_supplied_copyright,   label: '[eds_abstract_supplied_copyright]'
      config.add_show_field :eds_descriptors,                   label: '[eds_descriptors]'
      config.add_show_field :eds_publication_id,                label: '[eds_publication_id]'
      config.add_show_field :eds_publication_is_searchable,     label: '[eds_publication_is_searchable]'
      config.add_show_field :eds_publication_scope_note,        label: '[eds_publication_scope_note]'
      config.add_show_field :all_subjects_search_links,         label: '[all_subjects_search_links]'
      #config.add_show_field :eds_result_id,                    label: '[eds_result_id]' # NOTE: Only meaningful in search results
      config.add_show_field :eds_database_id,                   label: '[eds_database_id]'
      config.add_show_field :eds_accession_number,              label: '[eds_accession_number]'
      config.add_show_field :eds_database_name,                 label: '[eds_database_name]'
      config.add_show_field :id,                                label: '[id]'
      config.add_show_field :eds_relevancy_score,               label: '[eds_relevancy_score]'
      #
      # End by supplying options that apply to multiple field configurations.
      #
      config.show_fields.each_pair do |_, field_def|
        field_def[:separator_options] = HTML_LINES
      end

      # === Search fields ===
      # "Fielded" search configuration. Used by pulldown among other places.
      # For supported keys in hash, see rdoc for Blacklight::SearchFields.
      #
      # @see Blacklight::Configuration::Files::ClassMethods#define_field_access
      #
      # NOTE: "All Fields" is intentionally placed last.
      #
      # Begin by clearing the fields that were set by Config::Catalog.
      #
      config.search_fields.clear
      config.add_search_field :title,      label: 'Title'                 # 'TI'
      config.add_search_field :author,     label: 'Author'                # 'AU'
      config.add_search_field :subject,    label: 'Subject'               # 'SU'
      config.add_search_field :text,       label: 'Text'                  # 'TX' # TODO: testing - remove?
      config.add_search_field :abstract,   label: 'Abstract'              # 'AB' # TODO: testing - remove?
      config.add_search_field :source,     label: 'Source'                # 'SO' # TODO: testing - remove?
      config.add_search_field :issn,       label: 'ISSN'                  # 'IS' # TODO: testing - remove?
      config.add_search_field :isbn,       label: 'ISBN'                  # 'IB' # TODO: testing - remove?
      #config.add_search_field :descriptor,      label: 'Descriptor'      # 'DE' # TODO: testing - remove?
      #config.add_search_field :series,          label: 'Series'          # 'SE' # TODO: testing - remove?
      #config.add_search_field :subject_heading, label: 'Subject Heading' # 'SH' # TODO: testing - remove?
      #config.add_search_field :keywords,        label: 'Keywords'        # 'KW' # TODO: testing - remove?
      config.add_search_field :all_fields, label: 'All Fields', default: true

      # === Sort fields ===
      #
      # "Sort results by" select (pulldown)
      #
      # @see Blacklight::Configuration::Files::ClassMethods#define_field_access
      #
      # Begin by clearing the fields that were set by Config::Catalog.
      #
      config.sort_fields.clear
      config.add_sort_field :relevance, sort: 'relevance', label: 'Relevance'
      config.add_sort_field :newest,    sort: 'newest',    label: 'Date'
      config.add_sort_field :oldest,    sort: 'oldest',    label: 'Date (oldest first)'

      # === Blacklight behavior configuration ===

      # Force spell checking in all cases, no max results required.
      config.spell_max = 9999999999

      # Maximum number of results to show per page.
      #config.max_per_page: 100

      # Items to show per page, each number in the array represent another
      # option to choose from.
      #config.per_page = [10, 20, 50, 100]

      # Default :per_page selection
      #config.default_per_page = nil

      # How many searches to save in session history.
      #config.search_history_window = 100

      # The default number of items to show in a facet value menu when the
      # facet field does not specify a :limit.
      #config.default_facet_limit = 10

      # The facets with more than this number of values get a "more>>" link.
      # This the number of items per page in the facet modal dialog.
      #config.default_more_limit = 15 # config.default_facet_limit # NOTE: was 20

      # Configuration for suggester.
      #config.autocomplete_enabled = true
      #config.autocomplete_path    = 'suggest'

      # === Blacklight Advanced Search ===

      #config.advanced_search ||= Blacklight::OpenStructWithHashAccess.new
      ##config.advanced_search.qt                  ||= 'advanced'
      #config.advanced_search.url_key              ||= 'advanced'
      #config.advanced_search.query_parser         ||= 'dismax'
      #config.advanced_search.form_solr_parameters ||= {}
=begin
      config.advanced_search.form_solr_parameters[:'facet.field'] = %i(
        eds_search_limiters_facet
        eds_publication_type_facet
        eds_publication_year_facet
        eds_category_facet
        eds_subject_topic_facet
        eds_language_facet
        eds_journal_facet
        eds_subjects_geographic_facet
        eds_publisher_facet
        eds_content_provider_facet
      )
=end

    end
  end

end

__loading_end(__FILE__)
