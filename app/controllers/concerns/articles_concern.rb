# app/controllers/concerns/articles_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'config/articles'

# ArticlesConcern
#
module ArticlesConcern

  extend ActiveSupport::Concern

  # Code to be added to the controller class including this module.
  included do |base|

    __included(base, 'ArticlesConcern')

    include EdsConcern
    include LensConcern

    if base == ArticlesController
      self.blacklight_config = Config::Articles.new.blacklight_config
    else
      copy_blacklight_config_from(ArticlesController)
    end

    # @see Blacklight::DefaultComponentConfiguration
    # @see Blacklight::Marc::Catalog

    #add_results_document_tool(:bookmark, partial: 'bookmark_control', if: :render_bookmarks_control?)

    #add_results_collection_tool(:sort_widget)
    #add_results_collection_tool(:per_page_widget)
    #add_results_collection_tool(:view_type_group)

    #add_show_tools_partial(:bookmark, partial: 'bookmark_control', if: :render_bookmarks_control?)
    #add_show_tools_partial(:email, callback: :email_action, validator: :validate_email_params)
    #add_show_tools_partial(:sms, if: :render_sms_action?, callback: :sms_action, validator: :validate_sms_params)
    #add_show_tools_partial(:citation)

    #add_nav_action(:bookmark, partial: 'blacklight/nav/bookmark', if: :render_bookmarks_control?)
    #add_nav_action(:saved_searches, partial: 'blacklight/nav/saved_searches', if: :render_saved_searches?)
    #add_nav_action(:search_history, partial: 'blacklight/nav/search_history')

=begin # NOTE: moved to ExportConcern
    add_show_tools_partial(:librarian_view, if: :render_librarian_view_control?, define_method: false)
    add_show_tools_partial(:refworks,       if: :render_refworks_action?,                              modal: false)
    add_show_tools_partial(:endnote,        if: :render_endnote_action?,         define_method: false, modal: false, path: :articles_endnote_path)
=end

  end

end

__loading_end(__FILE__)
