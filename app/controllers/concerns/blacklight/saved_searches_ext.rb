# app/controllers/concerns/blacklight/saved_searches_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

module Blacklight

  # Replacement for Blacklight::SavedSearches
  #
  # @see Blacklight::SavedSearches
  #
  # == Implementation Notes
  # This does not include Blacklight::SavedSearches to avoid executing its
  # `included` block -- which means that it has to completely recreate the
  # module.
  #
  module SavedSearchesExt

    extend ActiveSupport::Concern

    include Blacklight::SavedSearches unless ONLY_FOR_DOCUMENTATION

    include Blacklight::ConfigurableExt

    # Code to be added to the controller class including this module.
    included do |base|

      __included(base, 'Blacklight::SavedSearchesExt')

      include RescueConcern

      # =======================================================================
      # :section: Controller filter actions
      # =======================================================================

      before_action :require_user_authentication_provider
      before_action :verify_user

    end

    # =========================================================================
    # :section: Blacklight::SavedSearches replacements
    # =========================================================================

    public

    # == GET /saved_searches
    #
    # This method replaces:
    # @see Blacklight::SavedSearches#index
    #
    def index
      @searches = current_user.searches
    end

    # == PUT /saved_searches/save/:id
    #
    # This method replaces:
    # @see Blacklight::SavedSearches#save
    #
    def save
      current_user.searches << searches_from_history.find(params[:id])
      if current_user.save
        go_back notice: I18n.t('blacklight.saved_searches.add.success')
      else # NOTE: 0% coverage for this case
        go_back error:  I18n.t('blacklight.saved_searches.add.failure')
      end
    end

    # == DELETE /saved_searches/forget/:id
    # == POST   /saved_searches/forget/:id
    # Only dereferences the user rather than removing the item in case it is in
    # the session[:history].
    #
    # This method replaces:
    # @see Blacklight::SavedSearches#forget
    #
    def forget
      search = current_user.searches.find(params[:id])
      if search.present?
        search.user_id = nil
        search.save
        go_back notice: I18n.t('blacklight.saved_searches.remove.success')
      else # NOTE: 0% coverage for this case
        go_back error:  I18n.t('blacklight.saved_searches.remove.failure')
      end
    end

    # == DELETE /saved_searches/clear
    # Only dereferences the user rather than removing the items in case they
    # are in the session[:history].
    #
    # This method replaces:
    # @see Blacklight::SavedSearches#clear
    #
    def clear
      if current_user.searches.update_all('user_id = NULL')
        flash[:notice] = I18n.t('blacklight.saved_searches.clear.success')
      else # NOTE: 0% coverage for this case
        flash[:error]  = I18n.t('blacklight.saved_searches.clear.failure')
      end
      redirect_to blacklight.saved_searches_url
    end

    # =========================================================================
    # :section: Blacklight::SavedSearches replacements
    # =========================================================================

    protected

    # Called before each action to ensure that saved search operations are
    # limited to logged in users.
    #
    # @raise [Blacklight::Exceptions::AccessDenied]  If session is anonymous.
    #
    # This method replaces:
    # @see Blacklight::SavedSearches#verify_user
    #
    def verify_user
      return if current_user
      flash[:notice] = I18n.t('blacklight.saved_searches.need_login')
      raise Blacklight::Exceptions::AccessDenied
    end

  end

end

__loading_end(__FILE__)
