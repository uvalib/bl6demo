# app/controllers/concerns/config/_solr.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '_constants'
require 'blacklight/solr/repository_ext'

class Config::Solr

  include Config::Constants

  # === Common field values ===
  # Certain "index" and "show" configuration fields have the same values based
  # on the relevant fields defined by the search service.
  SOLR_FIELD = {
    display_type_field: :format_facet,  # TODO: Could remove to avoid partial lookups by display type if "_default" is the only appropriate partial.
    title_field:        :title_display,
    subtitle_field:     :subtitle_display,
    alt_title_field:    :linked_title_display,
    author_field:       %i(
                          responsibility_statement_display
                          author_display
                          author_facet
                        ),
    alt_author_field:   %i(
                          linked_responsibility_statement_display
                          linked_author_display
                          linked_author_facet
                        ),
    thumbnail_field:    %i(thumbnail_url_display),
  }

  # === Sort field values ===
  #
  BY_YEAR        = :year_multisort_i
  BY_RECEIPT     = :date_received_facet
  BY_TITLE       = :title_sort_facet
  BY_AUTHOR      = :author_sort_facet
  BY_CALL_NUMBER = :call_number_sort_facet
  BY_RELEVANCE   = :score

  BY_RECEIVED_DATE   = "#{BY_RECEIPT} desc"
  BY_NEWEST          = "#{BY_YEAR} desc, #{BY_RECEIPT} desc"
  BY_OLDEST          = "#{BY_YEAR} asc, #{BY_RECEIPT} asc"
  IN_TITLE_ORDER     = "#{BY_TITLE} asc, #{BY_AUTHOR} asc"
  IN_AUTHOR_ORDER    = "#{BY_AUTHOR} asc, #{BY_TITLE} asc"
  IN_SHELF_ORDER     = "#{BY_CALL_NUMBER} asc"
  IN_REV_SHELF_ORDER = "#{BY_CALL_NUMBER} desc"
  BY_RELEVANCY       = "#{BY_RELEVANCE} desc, #{BY_NEWEST}"

  # ===========================================================================
  # :section:
  # ===========================================================================

  # The Blacklight configuration for lenses using Solr search.
  #
  # @return [Blacklight::Configuration]
  #
  # @see Blacklight::Configuration#default_values
  #
  def self.instance
    unless Blacklight.connection_config[:url].include?('lib.virginia.edu')
      alert = name <<
        'This configuration will not work without changing ' \
        'config/blacklight.yml'
      Rails.logger.error(alert)
      $stderr.puts('ERROR: ' + alert)
    end
    @instance ||= Blacklight::Configuration.new do |config|

      # === Search request configuration ===

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

      # === Single document request configuration ===

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

      # === Response models ===

      # Class for sending and receiving requests from a search index.
      config.repository_class = Blacklight::Solr::RepositoryExt

      # Class for converting Blacklight's URL parameters into request
      # parameters for the search index via repository_class.
      config.search_builder_class = ::SearchBuilder

      # Model that maps search index responses to Blacklight responses.
      config.response_model = Blacklight::Solr::Response

      # The model to use for each response document.
      config.document_model = SolrDocument

      # Class for paginating long lists of facet fields.
      config.facet_paginator_class = Blacklight::Solr::FacetPaginator

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
      config.index.document_presenter_class = Blacklight::IndexPresenterExt
      config.index.display_type_field = SOLR_FIELD[:display_type_field]
      config.index.title_field        = SOLR_FIELD[:title_field]
      config.index.subtitle_field     = SOLR_FIELD[:subtitle_field]
      config.index.alt_title_field    = SOLR_FIELD[:alt_title_field]
      config.index.author_field       = SOLR_FIELD[:author_field]
      config.index.alt_author_field   = SOLR_FIELD[:alt_author_field]
      config.index.thumbnail_field    = SOLR_FIELD[:thumbnail_field].last

      # === Configuration for document/show views ===
      #
      # @see Blacklight::Configuration::ViewConfig::Show
      #
      config.show.document_presenter_class = Blacklight::ShowPresenterExt
      config.show.display_type_field  = SOLR_FIELD[:display_type_field]
      config.show.title_field         = SOLR_FIELD[:title_field]
      config.show.subtitle_field      = SOLR_FIELD[:subtitle_field]
      config.show.alt_title_field     = SOLR_FIELD[:alt_title_field]
      config.show.author_field        = SOLR_FIELD[:author_field]
      config.show.alt_author_field    = SOLR_FIELD[:alt_author_field]
      config.show.thumbnail_field     = SOLR_FIELD[:thumbnail_field]
      config.show.route               = { controller: :catalog }
      config.show.partials            = [:show_header, :thumbnail, :show]

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
      # Setting a limit will trigger Blacklight's 'more' facet values link.
      #
      # * If left unset, then all facet values returned by Solr will be
      #     displayed.
      #
      # * If set to an integer, then "f.somefield.facet.limit" will be added to
      #     Solr request, with actual Solr request being +1 your configured
      #     limit -- you configure the number of items you actually want
      #     _displayed_ in a page.
      #
      # * If set to *true*, then no additional parameters will be sent to Solr,
      #     but any 'sniffed' request limit parameters will be used for paging,
      #     with paging at requested limit -1. Can sniff from facet.limit or
      #     f.specific_field.facet.limit Solr request params. This *true*
      #     config can be used if you set limits in :default_solr_params, or as
      #     defaults on the Solr side in the request handler itself. Request
      #     handler defaults sniffing requires Solr requests to be made with
      #     "echoParams=all", for app code to actually have it echo'd back to
      #     see it.
      #
      # :show may be set to *false* if you don't want the facet to be drawn in
      # the facet bar.
      #
      # Set :index_range to *true* if you want the facet pagination view to
      # have facet prefix-based navigation (useful when user clicks "more" on a
      # large facet and wants to navigate alphabetically across a large set of
      # results).
      #
      # :index_range can be an array or range of prefixes that will be used to
      # create the navigation (Note: It is case sensitive when searching
      # values).
      #
      # @see Blacklight::Configuration::Files::ClassMethods#define_field_access
      #
      config.add_facet_field :library_facet,            label: 'Library'
      config.add_facet_field :format_facet,             label: 'Format'
      config.add_facet_field :author_facet,             label: 'Author'
      config.add_facet_field :subject_facet,            label: 'Subject'
      config.add_facet_field :series_title_facet,       label: 'Series'
      config.add_facet_field :digital_collection_facet, label: 'Digital Collection'
      config.add_facet_field :call_number_broad_facet,  label: 'Call Number Range'
      config.add_facet_field :language_facet,           label: 'Language'
      config.add_facet_field :region_facet,             label: 'Geographic Location'
      config.add_facet_field :published_date_facet,     label: 'Publication Era'
      config.add_facet_field :category_facet,           label: 'Category'
      config.add_facet_field :group_facet,              label: 'Group'
      config.add_facet_field :signature_facet,          label: 'Signature'
      config.add_facet_field :use_facet,                label: 'Permissions'
      config.add_facet_field :license_class_facet,      label: 'License'
      config.add_facet_field :source_facet,             label: 'Source'
      config.add_facet_field :location2_facet,          label: 'Shelf Location'
      config.add_facet_field :year_multisort_i,         label: 'Year'
      config.add_facet_field :collection_facet,         label: 'Coin Collection'

=begin
    config.add_facet_field :example_pivot_field, label: 'Pivot Field', pivot: %w(format_facet language_facet)

    now = Time.zone.now.year
    config.add_facet_field :example_query_facet_field, label: 'Publish Date', query: {
      years_5:  { label: 'within 5 Years',  fq: "published_date_facet:[#{now-5}  TO *]" },
      years_10: { label: 'within 10 Years', fq: "published_date_facet:[#{now-10} TO *]" },
      years_25: { label: 'within 25 Years', fq: "published_date_facet:[#{now-25} TO *]" }
    }
=end

      # NOTE: The following fields need to have their values capitalized
      # (that is, the data needs to be capitalized when acquired) so that you
      # don't need to have an index_range that includes both upper- and lower-
      # case letters in order to access the entire gamut of values:
      #
      #                             !"#$%&'()*+,-./ 0123456789 :;<=>?@ A-Z [\]^_` a-z {|}~
      #                             --------------- ---------- ------- --- ------ --- ----
      # alternate_form_title_facet  YYYY_YYY_YY_YYY YYYYYYYYYY Y_Y__YY YYY YY___Y YYY ____
      # author_facet                _YYYYYYYYYYYYYY YYYYYYYYYY Y_YYYYY YYY YYY__Y YYY ____
      # genre_facet                 _______Y_____Y_ YYYY___Y_Y _______ YYY Y_____ YYY ____
      # journal_title_facet         _______________ YYYYYYYYYY _______ ___ ______ YYY ____
      # location_facet              _______________ __YY______ _______ YYY ______ ___ ____
      # location2_facet             _______________ ___Y______ _______ YYY ______ ___ ____
      # region_facet                _Y____YY_Y__YY_ YYYYYYYYYY __YY___ YYY ______ YYY ____
      # series_title_facet          YYYYYYYYYYYYYY_ YYYYYYYYYY Y_YY_YY YYY YY__YY YYY YY__
      # subject_facet               YYYY_YYY_YYYYY_ YYYYYYYYYY Y_Y_YY_ YYY Y_____ YYY ____
      # topic_form_genre_facet      YY_Y__YY_YYYYY_ YYYYYYYYYY __Y__YY YYY Y_____ YYY ____
      # uniform_title_facet         YYY___YY_Y__YYY YYYYYYYYYY ___Y_YY YYY Y_____ YYY ____
      #
      # (The starting letter of values for other facets checked were within the
      # range 'A'..'Z'.)
      #
      config.facet_fields.each_pair do |key, field_def|

        case key.to_sym
          when :library_facet            then -1 # Show all libraries.
          when :author_facet             then 10
          when :series_title_facet       then 15
          when :digital_collection_facet then 10
          when :call_number_broad_facet  then 15
          else                                20
        end.tap { |limit| field_def.limit = limit if limit }

        case key.to_sym
          when :library_facet            then 'index'
          when :call_number_broad_facet  then 'index'
          else                                'count'
        end.tap { |sort| field_def.sort = sort if sort }

        case key.to_sym
          when :alternate_form_title_facet  then "\x20".."\x7E"
          when :author_facet                then "\x20".."\x7E"
          when :genre_facet                 then "\x20".."\x7E"
          when :journal_title_facet         then "\x20".."\x7E"
          when :location_facet              then "\x20".."\x7E"
          when :location2_facet             then "\x20".."\x7E"
          when :region_facet                then "\x20".."\x7E"
          when :series_title_facet          then "\x20".."\x7E"
          when :subject_facet               then "\x20".."\x7E"
          when :topic_form_genre_facet      then "\x20".."\x7E"
          when :uniform_title_facet         then "\x20".."\x7E"
          when :call_number_broad_facet     then nil
          when :year_multisort_i            then 0..9
          else                              'A'..'Z'
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
      # NOTE: IndexPresenterExt#label displays :title_display, :subtitle_display,
      # and :linked_title_display so they do not need to be included here.
      #
      #config.add_index_field :title_display,           label: 'Title'
      #config.add_index_field :subtitle_display,        label: 'Subtitle'
      #config.add_index_field :linked_title_display,    label: 'Title'
      config.add_index_field :linked_author_display,    label: 'Author'
      config.add_index_field :author_display,           label: 'Author'
      config.add_index_field :format_facet,             label: 'Format',            helper_method: :format_facet_label
      config.add_index_field :language_facet,           label: 'Language'
      config.add_index_field :year_display,             label: 'Date'
      config.add_index_field :published_date_display,   label: 'Published'
      config.add_index_field :digital_collection_facet, label: 'Digital Collection'
      config.add_index_field :library_facet,            label: 'Library'
      config.add_index_field :location_facet,           label: 'Location'
      config.add_index_field :call_number_display,      label: 'Call number'
      config.add_index_field :url_display,              label: 'Access Online',     helper_method: :url_link

      # === Item details (show page) metadata fields ===
      # Solr fields to be displayed in the show (single result) view.
      # (The ordering of the field names is the order of display.)
      #
      # @see Blacklight::Configuration::Files::ClassMethods#define_field_access
      #
      # NOTE: ShowPresenterExt#heading shows :title_display, :subtitle_display,
      # :linked_title_display, :responsibility_statement_display, and
      # :linked_responsibility_statement_display so they do not need to be
      # included here.
      #
      #config.add_show_field :title_display,                    label: 'Title'
      #config.add_show_field :subtitle_display,                 label: 'Subtitle'
      #config.add_show_field :linked_title_display,             label: 'Title'
      #config.add_show_field :responsibility_statement_display, label: 'By'
      config.add_show_field :format_facet,                      label: 'Format',                    helper_method: :format_facet_label
      config.add_show_field :medium_display,                    label: '[medium_display]'
      config.add_show_field :part_display,                      label: 'Part'
      config.add_show_field :journal_title_facet,               label: 'Journal'
      config.add_show_field :uniform_title_facet,               label: 'Uniform Title'
      config.add_show_field :alternate_form_title_facet,        label: 'Other Title(s)'
      config.add_show_field :series_title_facet,                label: 'Series'
      #config.add_show_field :collection_title_display,         label: 'Digital Collection' # NOTE: seems to be the same as :digital_collection_facet
      config.add_show_field :digital_collection_facet,          label: 'Digital Collection'
      config.add_show_field :degree_display,                    label: 'Degree'
      config.add_show_field :recording_type_facet,              label: 'Recording Type'
      config.add_show_field :music_composition_form_facet,      label: 'Composition Form'
      config.add_show_field :music_catagory_facet,              label: 'Music Category'
      config.add_show_field :mus_display,                       label: '[mus_display]'
      config.add_show_field :video_genre_facet,                 label: 'Film Genre'
      config.add_show_field :genre_facet,                       label: 'Genre'
      #config.add_show_field :date_coverage_display,            label: 'Date' # NOTE: seems to be the same as :published_date_display
      config.add_show_field :published_date_display,            label: 'Date'
      config.add_show_field :language_facet,                    label: 'Language'
      config.add_show_field :langauge_facet,                    label: 'Language'
      config.add_show_field :media_resource_id_display,         label: 'Type'
      config.add_show_field :published_display,                 label: 'Published'
      #config.add_show_field :cre_display,                      label: 'Creators' # NOTE: seems to be the same as :author_facet
      config.add_show_field :author_facet,                      label: 'Creators'
      config.add_show_field :release_date_facet,                label: 'Release Date'
      config.add_show_field :duration_display,                  label: 'Duration'
      config.add_show_field :video_run_time_display,            label: 'Running Time'
      config.add_show_field :video_rating_facet,                label: 'Rating'
      config.add_show_field :video_director_facet,              label: 'Director'
      config.add_show_field :accession_display,                 label: 'Accession Number'
      config.add_show_field :denomination_display,              label: 'Denomination'
      config.add_show_field :collection_facet,                  label: 'Collection'
      config.add_show_field :abstract_display,                  label: 'Abstract'
      config.add_show_field :description_note_display,          label: 'Description Note'
      config.add_show_field :title_added_entry_display,         label: 'Contents'
      config.add_show_field :toc_display,                       label: 'Table of Contents'
      config.add_show_field :note_display,                      label: 'Note'
      config.add_show_field :subject_facet,                     label: 'Subject'
      config.add_show_field :topic_form_genre_facet,            label: 'Topic Form Genre'
      config.add_show_field :subject_era_facet,                 label: 'Subject Era'
      config.add_show_field :region_facet,                      label: 'Geographic Region'
      config.add_show_field :media_description_display,         label: 'Media Description'
      config.add_show_field :media_retrieval_id_facet,          label: 'Media Retrieval ID'
      config.add_show_field :isbn_display,                      label: 'ISBN'
      config.add_show_field :issn_display,                      label: 'ISSN'
      config.add_show_field :oclc_display,                      label: 'OCLC'
      config.add_show_field :upc_display,                       label: 'UPC'
      config.add_show_field :url_display,                       label: 'Access Online',               helper_method: :url_link
      config.add_show_field :library_facet,                     label: 'Library'
      config.add_show_field :location_facet,                    label: 'Location'
      config.add_show_field :location2_facet,                   label: '[location2_facet]'
      config.add_show_field :unit_display,                      label: 'Unit'
      config.add_show_field :url_supp_display,                  label: 'Other Resources',             helper_method: :url_link
      config.add_show_field :call_number_display,               label: 'Call Number'
      config.add_show_field :call_number_orig_display,          label: '[call_number_orig]'
      config.add_show_field :call_number_facet,                 label: '[call_number_facet]'
      config.add_show_field :call_number_sort_facet,            label: '[call_number_sort_facet]'
      config.add_show_field :lc_call_number_display,            label: '[lc_call_number_display]'
      config.add_show_field :shelfkey,                          label: '[shelfkey]'
      config.add_show_field :reverse_shelfkey,                  label: '[reverse_shelfkey]'
      config.add_show_field :use_facet,                         label: 'Permissions'
      config.add_show_field :license_class_facet,               label: 'License'
      config.add_show_field :terms_of_use_display,              label: 'Terms of Use'
      config.add_show_field :summary_holdings_display,          label: '[summary_holdings]'
      config.add_show_field :published_date_facet,              label: '[published_date_facet]'
      config.add_show_field :shadowed_location_facet,           label: '[shadowed_location]'
      config.add_show_field :alternate_id_facet,                label: '[alternate_id_facet]'
      config.add_show_field :doc_type_facet,                    label: '[doc_type_facet]'
      config.add_show_field :content_model_facet,               label: '[content_model]'
      config.add_show_field :content_type_facet,                label: '[content_type]'
      config.add_show_field :feature_facet,                     label: '[feature_facet]'
      config.add_show_field :individual_call_number_display,    label: '[individual_call_number]'
      config.add_show_field :iiif_presentation_metadata_display,label: '[iiif_presentation_metadata]'
      config.add_show_field :rights_wrapper_display,            label: '[rights_wrapper_display]'
      config.add_show_field :rights_wrapper_url_display,        label: '[rights_wrapper_url]',        helper_method: :url_link
      config.add_show_field :rs_uri_display,                    label: '[rs_uri]',                    helper_method: :url_link
      config.add_show_field :pdf_url_display,                   label: '[pdf_url]',                   helper_method: :url_link
      config.add_show_field :avalon_url_display,                label: '[avalon_url]'
      config.add_show_field :part_pid_display,                  label: '[part_pid]'
      config.add_show_field :part_label_display,                label: '[part_label]'
      config.add_show_field :part_duration_display,             label: '[part_duration]'
      config.add_show_field :issued_date_display,               label: '[issued_date]'
      config.add_show_field :created_date_display,              label: '[created_date]'
      config.add_show_field :breadcrumbs_display,               label: '[breadcrumbs_display]'
      config.add_show_field :hierarchy_level_display,           label: '[hierarchy_level]'
      config.add_show_field :hierarchy_display,                 label: '[hierarchy_display]'
      config.add_show_field :full_hierarchy_display,            label: '[full_hierarchy]'
      config.add_show_field :pbcore_display,                    label: '[pbcore_display]'
      config.add_show_field :scope_content_display,             label: '[scope_content]'
      config.add_show_field :repository_address_display,        label: '[repository_address]'
      config.add_show_field :datafile_name_display,             label: '[datafile_name]'
      config.add_show_field :admin_meta_file_display,           label: '[admin_meta]'
      config.add_show_field :desc_meta_file_display,            label: '[desc_meta]'
      config.add_show_field :raw_ead_display,                   label: '[raw_ead_display]'
      config.add_show_field :source_facet,                      label: '[source_facet]'
      config.add_show_field :barcode_facet,                     label: '[barcode_facet]'
      config.add_show_field :fund_code_facet,                   label: '[fund_code_facet]'
      config.add_show_field :date_first_indexed_facet,          label: '[date_first_indexed]'
      config.add_show_field :timestamp,                         label: '[timestamp]'
      config.add_show_field :date_indexed_facet,                label: '[date_indexed_facet]'
      config.add_show_field :id,                                label: '[id]'
      config.add_show_field :score,                             label: '[score]'
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
      # Search fields will inherit the :qt Solr request handler from
      # config[:default_solr_parameters], OR can specify a different one with a
      # :qt key/value. Below examples inherit, except for subject that
      # specifies the same :qt as default for our own internal testing
      # purposes.
      #
      # The :key is what will be used to identify this BL search field
      # internally, as well as in URLs -- so changing it after deployment may
      # break bookmarked URLs.  A display label will be automatically
      # calculated from the :key, or can be specified manually to be different.
      #
      # This one uses all the defaults set by the Solr request handler. Which
      # Solr request handler? The one set in
      # config[:default_solr_parameters][:qt], since we aren't specifying it
      # otherwise.
      #
      # Now we see how to over-ride Solr request handler defaults, in this case
      # for a BL "search field", which is really a dismax aggregate of Solr
      # search fields.
      #
      # :solr_parameters are sent to Solr as ordinary URL query params.
      #
      # :solr_local_parameters are sent using Solr LocalParams syntax, e.g:
      # "{! qf=$qf_title }". This is necessary to use Solr parameter
      # de-referencing like $qf_title.
      # @see http://wiki.apache.org/solr/LocalParams
      #
      # @see Blacklight::Configuration::Files::ClassMethods#define_field_access
      #
      # NOTE: "All Fields" is intentionally placed last.

      # "Title" search selection.
      config.add_search_field(:title) do |field|
        #field.solr_parameters = { 'spellcheck.dictionary': 'title' } # TODO: ?
        field.solr_local_parameters = { qf: '$qf_title', pf: '$pf_title' }
      end

      # "Author" search selection.
      config.add_search_field(:author) do |field|
        #field.solr_parameters = { 'spellcheck.dictionary': 'author' } # TODO: ?
        field.solr_local_parameters = { qf: '$qf_author', pf: '$pf_author' }
      end

      # "Subject" search selection.
      config.add_search_field(:subject) do |field|
        #field.solr_parameters = { 'spellcheck.dictionary': 'subject' } # TODO: ?
        field.solr_local_parameters = { qf: '$qf_subject', pf: '$pf_subject' }
      end

      # "Journal Title" search selection.
      config.add_search_field(:journal) do |field|
        field.label = 'Journal Title'
        field.solr_local_parameters =
          { qf: '$qf_journal_title', pf: '$pf_journal_title' }
      end

      # "Keywords" search selection. # TODO: testing?
      config.add_search_field(:keyword) do |field|
        field.label = 'Keywords'
        field.solr_local_parameters = { qf: '$qf_keyword', pf: '$pf_keyword' }
      end

      # "Call Number" search selection. # TODO: testing?
      config.add_search_field(:call_number) do |field|
        field.label = 'Call Number'
        field.solr_local_parameters =
          { qf: '$qf_call_number', pf: '$pf_call_number' }
      end

      # "Publisher" search selection. # TODO: testing?
      config.add_search_field(:published) do |field|
        field.label = 'Publisher Name/Place'
        field.solr_local_parameters =
          { qf: '$qf_published', pf: '$pf_published' }
      end

      # "Publisher" search selection. # TODO: testing?
      config.add_search_field(:publication_date) do |field|
        field.label = 'Year Published'
        field.range = 'true'
        field.solr_field = 'year_multisort_i'
      end

      # "ISSN" search selection. # TODO: testing?
      config.add_search_field(:issn) do |field|
        field.label = 'ISSN'
        field.solr_local_parameters = { qf: '$qf_issn', pf: '$pf_issn' }
=begin
      field.include_in_advanced_search = false
=end
      end

      # "ISBN" search selection. # TODO: testing?
      config.add_search_field(:isbn) do |field|
        field.label = 'ISBN'
        field.solr_local_parameters = { qf: '$qf_isbn', pf: '$pf_isbn' }
=begin
      field.include_in_advanced_search = false
=end
      end

      # "All Fields" search selection is intentionally placed last so that the
      # user will be encouraged to arrive at a more appropriate search type
      # before falling-back on a generic keyword search.  It is indicated as
      # "default" only to ensure that other search types are properly labeled
      # in search constraints and history.
      config.add_search_field :all_fields, label: 'All Fields', default: true

      # === Sort fields ===
      #
      # "Sort results by" select (pulldown)
      #
      # @see Blacklight::Configuration::Files::ClassMethods#define_field_access
      #
      config.add_sort_field BY_RELEVANCY,       label: 'Relevancy'
      config.add_sort_field BY_RECEIVED_DATE,   label: 'Date Received'
      config.add_sort_field BY_NEWEST,          label: 'Date Published (newest)'
      config.add_sort_field BY_OLDEST,          label: 'Date Published (oldest)'
      config.add_sort_field IN_TITLE_ORDER,     label: 'Title'
      config.add_sort_field IN_AUTHOR_ORDER,    label: 'Author'
      config.add_sort_field IN_SHELF_ORDER,     label: 'Call Number'
      config.add_sort_field IN_REV_SHELF_ORDER, label: 'Call Number (reverse)'

      # === Blacklight behavior configuration ===

      # If there are more than this many search results, no "did you mean"
      # suggestion is offered.
      config.spell_max = 10 # NOTE: was 5

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
      config.default_more_limit = 15 # config.default_facet_limit # NOTE: was 20

      # Configuration for suggester.
      config.autocomplete_enabled = true
      config.autocomplete_path    = 'suggest'

      # === Blacklight Advanced Search ===

      config.advanced_search ||= Blacklight::OpenStructWithHashAccess.new
      #config.advanced_search.qt                  ||= 'search'
      config.advanced_search.url_key              ||= 'advanced'
      config.advanced_search.query_parser         ||= 'dismax'
      config.advanced_search.form_solr_parameters ||= {}
=begin
    config.advanced_search = Blacklight::OpenStructWithHashAccess.new(
      qt:           'search',
      url_key:      'advanced',
      query_parser: 'dismax',
      form_solr_parameters: {
        'facet.field': %w(
          format
          pub_date
          subject_topic_facet
          language_facet
          lc_alpha_facet
          subject_geo_facet
          subject_era_facet
        ),
        'facet.limit': -1,     # return all facet values
        'facet.sort':  'index' # sort by byte order of values
      }
    )
=end

    end
  end

end

__loading_end(__FILE__)
