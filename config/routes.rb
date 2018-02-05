# config/routes.rb
#
# frozen_string_literal: true
# warn_indent:           true

Rails.application.routes.draw do

  # This defines routes from the Blacklight gem config/routes.rb:
  #
  #   get    'search_history'
  #   delete 'search_history/clear'
  #   delete 'saved_searches/clear'
  #   get    'saved_searches'
  #   put    'saved_searches/save/:id'
  #   delete 'saved_searches/forget/:id'
  #   post   'saved_searches/forget/:id'
  #   post   '/catalog/:id/track'
  #   resources :suggest, only: :index, defaults: { format: 'json' }
  #
  mount Blacklight::Engine => '/'

  # This defines routes from the BlacklightAdvancedSearch gem config/routes.rb:
  #
  #   get 'advanced'
  #
  mount BlacklightAdvancedSearch::Engine => '/'

  # ===========================================================================
  # :section: Routing concern definitions.
  # ===========================================================================

  # When added to a resource this concern adds routes as defined in:
  # @see Blacklight::Routes::Searchable#call
  concern :searchable, Blacklight::Routes::Searchable.new

  # When added to a resource this concern adds routes as defined in:
  # @see Blacklight::Routes::Exportable#call
  concern :exportable, Blacklight::Routes::Exportable.new

  # ===========================================================================
  # :section: Catalog lens routes.
  # ===========================================================================

  get 'catalog/home',       to: redirect('/catalog')
  get 'catalog/index',      to: redirect('/catalog?q=*'), as: 'catalog_all'
  get 'catalog/show',       to: 'catalog#show',           as: 'show_solr_document'
  get 'catalog/advanced',   to: 'catalog_advanced#index', as: 'catalog_advanced_search'
  get 'catalog/opensearch', to: 'catalog#opensearch'

  resources 'suggest', only: [:index], as: 'catalog_suggest', path: 'catalog/suggest', defaults: { format: 'json' }

  resources 'solr_documents', only: [:show], path: 'catalog', controller: 'catalog' do
    concerns :exportable
  end

  # This adds routes as defined in:
  # @see Blacklight::Marc::Routes::RouteSets#catalog
  Blacklight::Marc.add_routes(self)

  resource 'catalog', only: [:index], as: 'catalog', path: 'catalog', controller: 'catalog' do
    concerns :searchable
  end

  get 'catalog/:id/endnote', to: 'catalog#endnote', as: 'catalog_endnote', defaults: { format: 'endnote' }

  # ===========================================================================
  # :section: Articles lens routes
  # ===========================================================================

  get 'articles/home',       to: redirect('/articles')
  get 'articles/index',      to: redirect('/articles?q=*'), as: 'articles_all'
  get 'articles/show',       to: 'articles#show',           as: 'show_eds_document'
  get 'articles/advanced',   to: 'articles_advanced#index', as: 'articles_advanced_search'
  get 'articles/opensearch', to: 'articles#opensearch'

  resources 'articles_suggest', only: [:index], as: 'articles_suggest', path: 'articles/suggest', defaults: { format: 'json' }

  resources 'eds_documents', only: [:show], path: 'articles', controller: 'articles' do
    concerns :exportable
  end

  resource 'articles', only: [:index], as: 'articles', path: 'articles', controller: 'articles' do
    concerns :searchable
    member do # TODO: needed?
      get ':type/fulltext', action: 'fulltext', as: 'fulltext_link'
    end
  end

  # NOTE: Supersedes Blacklight::Marc for articles
  get 'articles/:id/librarian_view', to: 'articles#librarian_view', as: 'librarian_view_eds_document'
  get 'articles/:id/endnote',        to: 'articles#endnote',        as: 'articles_endnote', defaults: { format: 'endnote' }

  # ===========================================================================
  # :section: Bookmarks
  # ===========================================================================

  resources 'bookmarks' do
    collection do
      delete 'clear'
    end
    concerns :exportable
  end

  # ===========================================================================
  # :section: User account
  # ===========================================================================

  devise_for :users, path: 'account', path_names: {
    sign_in:  'login',
    sign_out: 'logout',
    edit:     'status' # TODO: probably there isn't an "edit"...
  }

  resource 'account', only: [:index], as: 'account', path: 'account', controller: 'account' do
    get 'signed_out'
  end

  # ===========================================================================
  # :section: Home page
  # ===========================================================================

  root to: 'catalog#index'

end
