# app/controllers/concerns/blacklight/search_context_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

module Blacklight::SearchContextExt

  extend ActiveSupport::Concern

  include Blacklight::SearchContext

  # Code to be added to the controller class including this module.
  included do |base|

    __included(base, 'Blacklight::SearchContextExt')

    include LensConcern

=begin # NOTE: using base version
    if base.respond_to?(:helper_method)
      helper_method :current_search_session, :search_session
    end
=end

  end

  # ===========================================================================
  # :section: Blacklight::SearchContext overrides
  # ===========================================================================

  public

  module ClassMethods

=begin # NOTE: using base version
    # Save the submitted search parameters in the search session.
    #
    # @param [Hash] opts
    #
    # @return [void]
    #
    def record_search_parameters(opts = nil)
      opts ||= { only: :index }
      before_action :set_current_search_session, opts
    end
=end

  end

  # ===========================================================================
  # :section: Blacklight::SearchContext overrides
  # ===========================================================================

  protected

=begin # NOTE: using base version
  # Sets up the `session[:search]` hash if it doesn't already exist.
  #
  # @return [Hash]
  #
  # This method overrides:
  # @see Blacklight::SearchContext#search_session
  #
  def search_session
    session[:search] ||= {}
    # Need to call the getter again. The value is mutated
    # https://github.com/rails/rails/issues/23884
    session[:search]
  end
=end

=begin # NOTE: using base version
  # The current search session.
  #
  # @return [Search, nil]
  #
  # This method overrides:
  # @see Blacklight::SearchContext#current_search_session
  #
  def current_search_session
    @current_search_session ||= find_search_session
  end
=end

=begin # NOTE: using base version
  # Persist the current search session id to the user's session.
  #
  # @return [?]
  # @return [nil]
  #
  # This method overrides:
  # @see Blacklight::SearchContext#set_current_search_session
  #
  def set_current_search_session
    search_session['id'] = current_search_session.id if current_search_session
  end
=end

  # find_search_session
  #
  # @return [Search, nil]
  #
  # This method overrides:
  # @see Blacklight::SearchContext#find_search_session
  #
  def find_search_session
    if agent_is_crawler?
      nil
    elsif (context = params[:search_context]).present? # NOTE: 0% coverage for this case
      find_or_initialize_search_session_from_params(JSON.parse(context))
    elsif (sid = params[:search_id]).present? # NOTE: 0% coverage for this case
      # TODO: check the search id signature.
      searches_from_history.find(sid)
    elsif start_new_search_session?
      find_or_initialize_search_session_from_params(search_state.to_h)
    elsif (sid = search_session['id']).present?
      searches_from_history.find(sid)
    end
  rescue => e # ActiveRecord::RecordNotFound => e
    unless e.is_a?(ActiveRecord::RecordNotFound)
      logger.error("#{__method__}: UNEXPECTED #{e.class}: #{e.message}")
    end
    nil
  end

=begin # NOTE: using base version
  # If the current action should start a new search session, this should be
  # set to true.
  #
  # This method overrides:
  # @see Blacklight::SearchContext#start_new_search_session?
  #
  def start_new_search_session?
    false
  end
=end

=begin # NOTE: using base version
  # Indicate whether the current request is coming from an anonymous bot or
  # search crawler.
  #
  # This method overrides:
  # @see Blacklight::SearchContext#agent_is_crawler?
  #
  def agent_is_crawler?
    blacklight_config.crawler_detector&.call(request) if current_user.blank?
  end
=end

=begin # NOTE: using base version
  # find_or_initialize_search_session_from_params
  #
  # @param [Hash] qp                  Copy of `params`.
  #
  # @return [Search, nil]
  #
  # This method overrides:
  # @see Blacklight::SearchContext#find_or_initialize_search_session_from_params
  #
  def find_or_initialize_search_session_from_params(qp)
    qp =
      qp.reject do |k, v|
        blacklisted_search_session_params.include?(k.to_sym) || v.blank?
      end
    return if qp.except(:controller, :action).blank?

    # Find a saved search or create one and add it to the search history.
    searches_from_history.find { |s| s.query_params == qp } ||
      Search.create(query_params: qp).tap { |s| add_to_search_history(s) }
  end
=end

=begin # NOTE: using base version
  # Add a search to the in-session search history list.
  #
  # @param [Hash] search
  #
  # @return [void]
  #
  # This method overrides:
  # @see Blacklight::SearchContext#add_to_search_history
  #
  def add_to_search_history(search)
    h = session[:history] || []
    h.unshift(search.id)
    session[:history] = h.slice(0, blacklight_config.search_history_window)
  end
=end

=begin # NOTE: using base version
  # A list of query parameters that should not be persisted for a search.
  #
  # @return [Array<Symbol>]
  #
  # This method overrides:
  # @see Blacklight::SearchContext#blacklisted_search_session_params
  #
  def blacklisted_search_session_params
    %i(commit counter total search_id page per_page)
  end
=end

  # Used in the show action for single view pagination to set up
  # @previous_document and @next_document.
  #
  # @return [void]
  #
  # This method overrides:
  # @see Blacklight::SearchContext#setup_next_and_previous_documents
  #
  def setup_next_and_previous_documents
    counter = search_session['counter']
    search  = current_search_session
    $stderr.puts(">>> #{__method__}: counter #{counter}")                                            # TODO: debugging - remove
    $stderr.puts(">>> #{__method__}: search  #{search.inspect}")                                     # TODO: debugging - remove
    return unless counter && search
    index          = counter.to_i - 1
    query          = search.query_params.with_indifferent_access
    $stderr.puts(">>> #{__method__}: index   #{index}")                                              # TODO: debugging - remove
    $stderr.puts(">>> #{__method__}: query   #{query.inspect}")                                      # TODO: debugging - remove
    response, docs = get_previous_and_next_documents_for_search(index, query)
    search_session['total']  = response.total
    @search_context_response = response
    @previous_document       = docs.first
    @next_document           = docs.last
    $stderr.puts(">>> #{__method__}: response.total = #{response.total}, docs.size = #{docs.size}")  # TODO: debugging - remove
    $stderr.puts(">>> #{__method__}: previous_document #{@previous_document&.id || '-'}")            # TODO: debugging - remove
    $stderr.puts(">>> #{__method__}: next_document     #{@next_document&.id || '-'}")                # TODO: debugging - remove
  rescue Blacklight::Exceptions::InvalidRequest => e
    logger.warn "#{__method__}: #{e}"
  end

end

__loading_end(__FILE__)
