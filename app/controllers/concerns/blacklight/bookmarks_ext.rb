# app/controllers/concerns/blacklight/bookmarks_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# A replacement for Blacklight::Bookmarks.
#
# Note that while this is mostly restful routing, the #update and #destroy
# actions take :id as the document ID and NOT the ID of the actual Bookmark
# action.
#
# Compare with:
# @see Blacklight::Bookmarks
#
# == Implementation Notes
# This does not include Blacklight::Bookmarks to avoid executing its `included`
# block -- which means that it has to completely recreate the module.
#
module Blacklight::BookmarksExt

  extend ActiveSupport::Concern

  # TODO: If this is going to copy config from Catalog anyway then this module
  # *could* just extend Blacklight::Bookmarks although most methods are
  # overridden...
  include Blacklight::Bookmarks unless ONLY_FOR_DOCUMENTATION

  include Blacklight::BaseExt
  include Blacklight::DefaultComponentConfiguration
  include Blacklight::FacetExt

  # Code to be added to the controller class including this module.
  included do |base|

    __included(base, 'Blacklight::BookmarksExt')

    include Blacklight::SearchHelperExt
    include Blacklight::TokenBasedUser

    include RescueConcern
    include ExportConcern
    include MailConcern
    include SearchConcern
    include LensConcern

    # =========================================================================
    # :section: Controller Blacklight configuration
    # =========================================================================

    copy_blacklight_config_from(CatalogController)

    # NOTE: This is needed so that Solr gets :data rather than :params argument.
    blacklight_config.http_method =
      Blacklight::Engine.config.bookmarks_http_method

    # TODO: Why is this not getting included?
    blacklight_config.add_results_collection_tool(:clear_bookmarks_widget)

    # NOTE: This wouldn't be necessary if the Blacklight configuration wasn't being copied.
    %i(bookmark sms).each do |k|
      entry = blacklight_config.show.document_actions[k]
      entry.if = false if entry
    end

    # =========================================================================
    # :section: Controller filter actions
    # =========================================================================

    before_action :verify_user

  end

  # ===========================================================================
  # :section: Blacklight::Bookmarks replacements
  # ===========================================================================

  public

  # == GET /bookmarks
  # Get documents associated with bookmarks.
  #
  # This method replaces:
  # @see Blacklight::Bookmarks#index
  #
  def index
    @response, @document_list = fetch(bookmark_ids)
    respond_to do |format|
      format.html { }
      format.rss  { render layout: false }
      format.atom { render layout: false }
      format.json { @presenter = json_presenter(@response, @document_list) }
      additional_response_formats(format)
=begin # TODO: implement for bookmarks
      document_export_formats(format)
=end
    end
  end

  # == PUT   /bookmarks/:id[?type=XXX]
  # == PATCH /bookmarks/:id[?type=XXX]
  #
  # Where XXX is one of 'SolrDocument' or 'EdsDocument'.
  #
  # This method replaces:
  # @see Blacklight::Bookmarks#update
  #
  def update
    create
  end

  # == POST /bookmarks[?type=XXX]
  #
  # For adding a single bookmark, suggest use PUT/#update to
  # /bookmarks/$docuemnt_id instead.
  #
  # But this method, accessed via POST to /bookmarks, can be used for
  # creating multiple bookmarks at once, by posting with keys
  # such as bookmarks[n][document_id], bookmarks[n][title].
  # It can also be used for creating a single bookmark by including keys
  # bookmark[title] and bookmark[document_id], but in that case #update
  # is simpler.
  #
  # This method replaces:
  # @see Blacklight::Bookmarks#create
  #
  def create
    bookmarks = params[:bookmarks]
    bookmarks ||= [bookmark_criteria(params[:id], params[:type])]
    count = bookmarks.size

    current_or_guest_user.save! unless current_or_guest_user.persisted?
    table   = current_or_guest_user.bookmarks
    success = bookmarks.all? { |b| table.where(b).exists? || table.create(b) }

    if request.xhr?
      if success
        render json: { bookmarks: { count: count } }
      else # NOTE: 0% coverage for this case
        head 500
      end
    else # NOTE: 0% coverage for this case
      if success
        go_back notice: t('blacklight.bookmarks.add.success', count: count)
      else
        go_back error:  t('blacklight.bookmarks.add.failure', count: count)
      end
    end
  end

  # == DELETE /bookmarks/:id
  #
  # Beware, :id is the Solr document_id, not the actual Bookmark id.
  # idempotent, as DELETE is supposed to be.
  #
  # This method replaces:
  # @see Blacklight::Bookmarks#destroy
  #
  def destroy
    table    = current_or_guest_user.bookmarks
    bookmark = bookmark_criteria(params[:id], params[:type])
    target   = table.find_by(bookmark)
    success  = target&.delete && target.destroyed?

    if request.xhr?
      if success
=begin
        count = current_or_guest_user.bookmarks.count
        render json: { bookmarks: { count: count } }
=end
        render json: { bookmarks: { count: table.count } }
      else # NOTE: 0% coverage for this case
        head 500
      end
    else # NOTE: 0% coverage for this case
      if success
        go_back notice: t('blacklight.bookmarks.remove.success')
      else
        go_back error:  t('blacklight.bookmarks.remove.failure')
      end
    end
  end

  # == DELETE /bookmarks/clear
  #
  # This method replaces:
  # @see Blacklight::Bookmarks#clear
  #
  def clear
    table = current_or_guest_user.bookmarks
    if table.clear
      flash[:notice] = t('blacklight.bookmarks.clear.success')
    else # NOTE: 0% coverage for this case
      flash[:error]  = t('blacklight.bookmarks.clear.failure')
    end
    redirect_to action: 'index'
  end

  # ===========================================================================
  # :section: Blacklight::Bookmarks replacements
  # ===========================================================================

  protected

  # Used by the method generated by #add_show_tools_partial to acquire the
  # items to be handled by the tool.
  #
  # @return [Blacklight::Solr::Response, Array<Blacklight::Document>]
  #
  # This method replaces:
  # @see Blacklight::Bookmarks#action_documents
  #
  # NOTE: 0% coverage for this method
  #
  def action_documents
    fetch(bookmark_ids)
  end

  # Used by the method generated by #add_show_tools_partial as the path to
  # redirect to after a POST to the tool route.
  #
  # This method replaces:
  # @see Blacklight::Bookmarks#action_success_redirect_path
  #
  # NOTE: 0% coverage for this method
  #
  def action_success_redirect_path
    bookmarks_path
  end

  # Blacklight uses #search_action_url to figure out the right URL for
  # the global search box.
  #
  # @param [Hash] options
  #
  # @return [String]
  #
  # This method replaces:
  # @see Blacklight::Bookmarks#search_action_url
  #
  # TODO: In this case the search should be for combined results.
  #
  def search_action_url(options = {})
    search_catalog_url(options.except(:controller, :action))
  end

  # No bookmarks action causes a new search.
  #
  # This method replaces:
  # @see Blacklight::Bookmarks#start_new_search_session?
  #
  # NOTE: 0% coverage for this method
  #
  def start_new_search_session?
    false
  end

  # ===========================================================================
  # :section: Filter actions - Blacklight::Bookmarks replacements
  # ===========================================================================

  protected

  # Called before each action to ensure that bookmark operations are limited to
  # logged in users.
  #
  # @raise [Blacklight::Exceptions::AccessDenied]  If the session is anonymous.
  #
  # This method replaces:
  # @see Blacklight::Bookmarks#verify_user
  #
  def verify_user
    return if current_or_guest_user
    return if (action == 'index') && token_or_current_or_guest_user
    flash[:notice] = t('blacklight.bookmarks.need_login')
    raise Blacklight::Exceptions::AccessDenied
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # The list of document IDs of the currently-bookmarked items.
  #
  # @param [?] table
  #
  # @return [Array<String>]
  #
  def bookmark_ids(table = nil)
    table ||= token_or_current_or_guest_user&.bookmarks || []
    table.map { |b| b.document_id.to_s }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # A hash which specifies a bookmark for lookup in the 'bookmarks' table.
  #
  # @param [String]        id         ID of bookmarked document
  # @param [String, Class] type       Type of bookmarked document
  #
  # @return [Hash]
  #
  def bookmark_criteria(id, type = nil)
    { document_id: id.to_s, document_type: document_type(id, type) }
  end

end

__loading_end(__FILE__)
