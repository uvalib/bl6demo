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

  # When invoked from a resource, this concern adds routes as defined in:
  # @see Blacklight::Routes::Searchable#call
  concern :searchable, Blacklight::Routes::Searchable.new

  # When invoked from a resource, this concern adds routes as defined in:
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

  # Route for /catalog/suggest.
  resources 'suggest', only: [:index], as: 'catalog_suggest', path: 'catalog/suggest', defaults: { format: 'json' }

  # Routes for /catalog/email, /catalog/sms, and /catalog/citation.
  resources 'solr_documents', only: [:show], path: 'catalog', controller: 'catalog' do
    concerns :exportable
  end

  # This adds routes as defined in:
  # @see Blacklight::Marc::Routes::RouteSets#catalog
  #
  #   get 'catalog/:id/librarian_view'
  #   get 'catalog/endnote'
  #
  Blacklight::Marc.add_routes(self)

  # Routes for /catalog, /catalog/:id/track, /catalog/opensearch, and
  # /catalog/facet/:id.
  resource 'catalog', only: [:index], as: 'catalog', path: 'catalog', controller: 'catalog' do
    concerns :searchable
  end

=begin
  get 'catalog/:id/endnote', to: 'catalog#endnote', as: 'catalog_endnote', defaults: { format: 'endnote' }
=end

  # ===========================================================================
  # :section: Video lens routes.
  # ===========================================================================

  get 'video/home',       to: redirect('/video')
  get 'video/index',      to: redirect('/video?q=*'), as: 'video_all'
  get 'video/show',       to: 'video#show' #,           as: 'show_solr_document'
  get 'video/advanced',   to: 'video_advanced#index', as: 'video_advanced_search'
  get 'video/opensearch', to: 'video#opensearch'

  # Route for /video/suggest.
  resources 'video_suggest', only: [:index], as: 'video_suggest', path: 'video/suggest', defaults: { format: 'json' }

  # Routes for /video/email, /video/sms, and /video/citation.
  resources 'solr_documents', only: [:show], path: 'video', controller: 'video' do
    concerns :exportable
  end

  # Video lens variants of Blacklight::Marc::Routes.
  get 'video/:id/librarian_view', to: 'video#librarian_view'
  get 'video/endnote',            to: 'video#endnote', defaults: { format: 'endnote' }

  # Routes for /video, /video/:id/track, /video/opensearch, and
  # /video/facet/:id.
  resource 'video', only: [:index], as: 'video', path: 'video', controller: 'video' do
    concerns :searchable
  end

=begin
  get 'video/:id/endnote', to: 'video#endnote', as: 'video_endnote', defaults: { format: 'endnote' }
=end

  # ===========================================================================
  # :section: Music lens routes.
  # ===========================================================================

  get 'music/home',       to: redirect('/music')
  get 'music/index',      to: redirect('/music?q=*'), as: 'music_all'
  get 'music/show',       to: 'music#show' #,           as: 'show_solr_document'
  get 'music/advanced',   to: 'music_advanced#index', as: 'music_advanced_search'
  get 'music/opensearch', to: 'music#opensearch'

  # Route for /music/suggest.
  resources 'music_suggest', only: [:index], as: 'music_suggest', path: 'music/suggest', defaults: { format: 'json' }

  # Routes for /music/email, /music/sms, and /music/citation.
  resources 'solr_documents', only: [:show], path: 'music', controller: 'music' do
    concerns :exportable
  end

  # Music lens variants of Blacklight::Marc::Routes.
  get 'music/:id/librarian_view', to: 'music#librarian_view'
  get 'music/endnote',            to: 'music#endnote', defaults: { format: 'endnote' }

  # Routes for /music, /music/:id/track, /music/opensearch, and
  # /music/facet/:id.
  resource 'music', only: [:index], as: 'music', path: 'music', controller: 'music' do
    concerns :searchable
  end

=begin
  get 'music/:id/endnote', to: 'music#endnote', as: 'music_endnote', defaults: { format: 'endnote' }
=end

  # ===========================================================================
  # :section: Articles lens routes
  # ===========================================================================

  get 'articles/home',       to: redirect('/articles')
  get 'articles/index',      to: redirect('/articles?q=*'), as: 'articles_all'
  get 'articles/show',       to: 'articles#show',           as: 'show_eds_document'
  get 'articles/advanced',   to: 'articles_advanced#index', as: 'articles_advanced_search'
  get 'articles/opensearch', to: 'articles#opensearch'

  # Route for /articles/suggest.
  resources 'articles_suggest', only: [:index], as: 'articles_suggest', path: 'articles/suggest', defaults: { format: 'json' }

  # Routes for /articles/email, /articles/sms, and /articles/citation.
  resources 'eds_documents', only: [:show], path: 'articles', controller: 'articles' do
    concerns :exportable
  end

  # Articles lens variants of Blacklight::Marc::Routes.
  get 'articles/:id/librarian_view', to: 'articles#librarian_view', as: 'librarian_view_eds_document'
  get 'articles/endnote',            to: 'articles#endnote',        as: 'endnote_eds_document'

  # Routes for /articles, /articles/:id/track, /articles/opensearch, and
  # /articles/facet/:id.
  resource 'articles', only: [:index], as: 'articles', path: 'articles', controller: 'articles' do
    concerns :searchable
    member do # TODO: needed?
      get ':type/fulltext', action: 'fulltext', as: 'fulltext_link'
    end
  end

=begin
  get 'articles/:id/endnote', to: 'articles#endnote', as: 'articles_endnote', defaults: { format: 'endnote' }
=end

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
