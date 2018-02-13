# app/controllers/concerns/blacklight/eds/catalog_eds.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/eds'

# An extension of Blacklight::CatalogExt for controllers that work with
# articles (EdsDocument).
#
# @see Blacklight::CatalogExt
# @see Blacklight::Catalog
#
module Blacklight::Eds::CatalogEds

  extend ActiveSupport::Concern

  include Blacklight::CatalogExt
  include Blacklight::Eds::BaseEds
=begin # NOTE: using base version
  include Blacklight::DefaultComponentConfiguration
  include Blacklight::FacetExt
=end

  # Code to be added to the controller class including this module.
  included do |base|

    __included(base, 'Blacklight::Eds::CatalogEds')

    include EdsConcern
    include LensConcern

    # =========================================================================
    # :section: Helpers
    # =========================================================================

=begin # NOTE: using base version
    helper_method :sms_mappings, :has_search_parameters?
=end

=begin # NOTE: using base version
    helper Blacklight::FacetExt
=end

    # =========================================================================
    # :section: Controller filter actions
    # =========================================================================

=begin # NOTE: using base version
    record_search_parameters
=end

    # =========================================================================
    # :section:
    # =========================================================================

    public

=begin # NOTE: using base version
    # Initialize controller instance and set the Blacklight configuration from
    # the class.
    #
    def initialize
      super
      @blacklight_config ||= blacklight_config_for(self)
    end
=end

  end

  # ===========================================================================
  # :section: Blacklight::Catalog overrides
  # ===========================================================================

  public

  # == GET /articles
  # Get search results from the EBSCO EDS search service.
  #
  # @see EdsConcern#get_eds_results
  #
  # This method overrides:
  # @see Blacklight::CatalogExt#index
  #
  def index
    @response, @document_list = search_results(params)
    @document_list =
      ActiveSupport::Deprecation::DeprecatedObjectProxy.new(
        @document_list,
        'The @document_list instance variable is deprecated; ' \
        'use @response.documents instead.'
      )
    respond_to do |format|
      format.html { store_preferred_view }
      format.rss  { render layout: false }
      format.atom { render layout: false }
      format.json { @presenter = json_presenter(@response) }
      additional_response_formats(format)
      document_export_formats(format)
    end
  end

  # == GET /articles/:id
  # Get a single document from the EBSCO EDS search service.
  #
  # To add responses for formats other than HTML or JSON:
  # @see Blacklight::Document::Export
  #
  # This method overrides:
  # @see Blacklight::CatalogExt#show
  #
  def show
    @response, @document = fetch(params[:id])
    @response =
      ActiveSupport::Deprecation::DeprecatedObjectProxy.new(
        @response,
        'The @response instance variable is deprecated; ' \
        'use @document.response instead.'
      )
    respond_to do |format|
      format.html { setup_next_and_previous_documents }
      format.json { render json: { response: { document: @document } } }
      additional_export_formats(@document, format)
    end
  end

=begin # NOTE: using base version
  # == POST /articles/:id/track
  # Updates the search counter (allows the show view to paginate).
  #
  # This method overrides:
  # @see Blacklight::CatalogExt#track
  #
  def track
    search_session['counter']  = params[:counter]
    search_session['id']       = params[:search_id]
    search_session['per_page'] = params[:per_page]
    url                        = params[:redirect]
    path =
      if url && (url.start_with?('/') || (url =~ URI.regexp))
        uri = URI.parse(url)
        uri.query ? "#{uri.path}?#{uri.query}" : uri.path
      else
        blacklight_config.document_model.new(id: params[:id])
      end
    redirect_to path, status: 303
  end
=end

  # == GET /articles/facet/:id
  # Displays values and pagination links for a single facet field.
  #
  # @raise [ActionController::RoutingError]
  #
  # This method overrides:
  # @see Blacklight::CatalogExt#facet
  #
  def facet
    @facet = blacklight_config.facet_fields[params[:id]]
    raise ActionController::RoutingError, 'Not Found' unless @facet
    @response      = get_facet_field_response(@facet.key)
    @display_facet = @response.aggregations[@facet.field]
    @pagination    = facet_paginator(@facet, @display_facet)
    respond_to do |format|
      format.html do
        # Draw the partial for the "more" facet modal window:
        return render layout: false if request.xhr?
        # Otherwise draw the facet selector for users who have javascript
        # disabled.
      end
      format.json
      # Draw the partial for the "more" facet modal window:
      format.js { render layout: false }
    end
  end

=begin # NOTE: using base version
=end
  # == GET /articles/opensearch
  # Method to serve up XML OpenSearch description and JSON autocomplete
  # response.
  #
  # This method overrides:
  # @see Blacklight::CatalogExt#opensearch
  #
  # NOTE: 0% coverage for this method
  #
  def opensearch
    respond_to do |format|
      format.xml  { render layout: false }
      format.json { render json:   get_opensearch_response }
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /articles/:id/fulltext
  #
  # NOTE: 0% coverage for this method
  #
  def fulltext
    fulltext_url = fetch_fulltext(params[:id], params[:type])
    redirect_to fulltext_url, status: 303 if fulltext_url
  end

  # ===========================================================================
  # :section: Blacklight::Catalog overrides
  # ===========================================================================

  protected

=begin # NOTE: using base version
  # Used by the method generated by #add_show_tools_partial to acquire the
  # items to be handled by the tool.
  #
  # This method overrides:
  # @see Blacklight::CatalogExt#action_documents
  #
  def action_documents
    fetch(Array.wrap(params[:id]))
  end
=end

=begin # NOTE: using base version
  # Used by the method generated by #add_show_tools_partial as the path to
  # redirect to after a POST to the tool route.
  #
  # This method overrides:
  # @see Blacklight::CatalogExt#action_success_redirect_path
  #
  def action_success_redirect_path
    path = blacklight_config.document_model.new(id: params[:id])
    search_state.url_for_document(path)
  end
=end

=begin # NOTE: using base version
  # Indicate whether any search parameters have been set.
  #
  # This method overrides:
  # @see Blacklight::CatalogExt#has_search_parameters?
  #
  def has_search_parameters?
    %i(q search_field f f_inclusive).any? { |field| params[field].present? }
  end
=end

  # ===========================================================================
  # :section: Blacklight::Catalog overrides
  # non-routable methods ->
  # ===========================================================================

  protected

=begin # NOTE: using base version
  # If the params specify a view, then store it in the session. If the params
  # do not specify the view, set the view parameter to the value stored in the
  # session. This enables a user with a session to do subsequent searches and
  # have them default to the last used view.
  #
  # @return [?]
  # @return [nil]
  #
  # This method overrides:
  # @see Blacklight::CatalogExt#store_preferred_view
  #
  def store_preferred_view
    session[:preferred_view] = params[:view] if params[:view]
  end
=end

=begin # NOTE: using base version
  # Render additional response formats for the index action, as provided by the
  # blacklight configuration
  #
  # @param [Hash] format
  #
  # @note Make sure your format has a well known mime-type or is registered in
  # config/initializers/mime_types.rb
  #
  # @example
  #   config.index.respond_to.txt = Proc.new { render plain: 'A list of docs' }
  #
  # This method overrides:
  # @see Blacklight::CatalogExt#additional_response_formats
  #
  def additional_response_formats(format)
    blacklight_config.index.respond_to.each do |key, config|
      format.send(key) do
        case config
          when false  then raise ActionController::RoutingError, 'Not Found'
          when Hash   then render config
          when Proc   then instance_exec(&config)
          when Symbol then send config
          when String then send config
          else             render({})
        end
      end
    end
  end
=end

=begin # NOTE: using base version
  # Render additional export formats for the show action, as provided by the
  # document extension framework.
  #
  # @param [Blacklight::Document] document
  # @param [?]                    format
  #
  # This method overrides:
  # @see Blacklight::CatalogExt#additional_export_formats
  #
  def additional_export_formats(document, format)
    document.export_formats.each_key do |format_name|
      format.send(format_name.to_sym) do
        render body: document.export_as(format_name), layout: false
      end
    end
  end
=end

=begin # NOTE: using base version
  # Try to render a response from the document export formats available.
  #
  # @param [?] format
  #
  # This method overrides:
  # @see Blacklight::CatalogExt#document_export_formats
  #
  def document_export_formats(format)
    format.any do
      format_name = params.fetch(:format, '').to_sym
      if @response.export_formats.include?(format_name)
        render_document_export_format(format_name)
      else
        raise ActionController::UnknownFormat
      end
    end
  end
=end

=begin # NOTE: using base version
  # Render the document export formats for a response.
  #
  # First, try to render an appropriate template (e.g. index.endnote.erb)
  # If that fails, just concatenate the document export responses with a
  # newline.
  #
  # @param [Symbol, String] fmt_name
  #
  # This method overrides:
  # @see Blacklight::CatalogExt#render_document_export_format
  #
  def render_document_export_format(fmt_name)
    render
  rescue => e
  #rescue ActionView::MissingTemplate => e
    docs    = @response.documents
    exports = docs.map { |x| x.export_as(fmt_name) if x.exports_as?(fmt_name) }
    render plain: exports.compact.join("\n"), layout: false
  end
=end

=begin # NOTE: using base version
  # Overrides the Blacklight::Controller provided #search_action_url.
  #
  # By default, any search action from a Blacklight::Catalog controller should
  # use the current controller when constructing the route.
  #
  # @param [Hash] options
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::CatalogExt#search_action_url
  #
  def search_action_url(options = nil)
    opt = { controller: current_lens_key, action: 'index' }
    opt.reverse_merge!(options) if options.is_a?(Hash)
    url_for(opt)
  end
=end

=begin # NOTE: using base version
  # Email Action (this will render the appropriate view on GET requests and
  # process the form and send the email on POST requests)
  #
  # @param [Array<EdsDocument>] documents
  #
  # This method overrides:
  # @see Blacklight::CatalogExt#email_action
  #
  def email_action(documents)
    details = params.slice(:to, :message)
    mail = RecordMailer.email_record(documents, details, url_options)
    mail.respond_to?(:deliver_now) ? mail.deliver_now : mail.deliver
  end
=end

=begin # NOTE: using base version
  # SMS action (this will render the appropriate view on GET requests and
  # process the form and send the email on POST requests)
  #
  # @param [Array<EdsDocument>] documents
  #
  # This method overrides:
  # @see Blacklight::CatalogExt#sms_action
  #
  def sms_action(documents)
    ph_number = params[:to].to_s.gsub(/[^\d]/, '')
    carrier   = params[:carrier]
    details   = { to: "#{ph_number}@#{carrier}" }
    mail = RecordMailer.sms_record(documents, details, url_options)
    mail.respond_to?(:deliver_now) ? mail.deliver_now : mail.deliver
  end
=end

=begin # NOTE: using base version
  # validate_sms_params
  #
  # @return [Boolean]
  #
  # This method overrides:
  # @see Blacklight::CatalogExt#validate_sms_params
  #
  def validate_sms_params
    error = []
    ph_number = params[:to]
    if ph_number.blank?
      error << I18n.t('blacklight.sms.errors.to.blank')
    elsif ph_number.gsub(/[^\d]/, '').length != 10
      error << I18n.t('blacklight.sms.errors.to.invalid', to: ph_number)
    end
    carrier = params[:carrier]
    if carrier.blank?
      error << I18n.t('blacklight.sms.errors.carrier.blank')
    elsif !sms_mappings.values.include?(carrier)
      error << I18n.t('blacklight.sms.errors.carrier.invalid')
    end
    flash[:error] = error.join("<br/>\n").html_safe if error.present?
    flash[:error].blank?
  end
=end

=begin # NOTE: using base version
  # sms_mappings
  #
  # @return [?]
  #
  # This method overrides:
  # @see Blacklight::CatalogExt#sms_mappings
  #
  def sms_mappings
    Blacklight::Engine.config.sms_mappings
  end
=end

=begin # NOTE: using base version
  # validate_email_params
  #
  # @return [Boolean]
  #
  # This method overrides:
  # @see Blacklight::CatalogExt#validate_email_params
  #
  def validate_email_params
    error = []
    addr = params[:to]
    if addr.blank?
      error << I18n.t('blacklight.email.errors.to.blank')
    elsif !addr.match(Blacklight::Engine.config.email_regexp)
      error << I18n.t('blacklight.email.errors.to.invalid', to: addr)
    end
    flash[:error] = error.join("<br/>\n").html_safe if error.present?
    flash[:error].blank?
  end
=end

=begin # NOTE: using base version
  # When a request for /catalog/BAD_SOLR_ID is made, this method is executed.
  #
  # Just returns a 404 response, but you can override locally in your own
  # CatalogController to do something else -- older BL displayed a
  # Catalog#index page with a flash message and a 404 status.
  #
  # @param [Exception] exception
  #
  # This method overrides:
  # @see Blacklight::CatalogExt#invalid_document_id_error
  #
  def invalid_document_id_error(exception)
    error_status = 404
    error_html   = "#{Rails.root}/public/#{error_status}.html"
    raise exception unless Pathname.new(error_html).exist?
    error_info = {
      'status' => error_status.to_s,
      'error'  => "#{exception.class}: #{exception.message}"
    }
    respond_to do |format|
      format.xml  { render xml:  error_info, status: error_status }
      format.json { render json: error_info, status: error_status }
      # Default to HTML response, even for other non-HTML formats we don't
      # necessarily know about, seems to be consistent with what Rails4 does
      # by default with uncaught ActiveRecord::RecordNotFound in production.
      format.any do
        # Use standard, possibly locally overridden, 404.html file. Even for
        # possibly non-HTML formats, this is consistent with what Rails does
        # on raising an ActiveRecord::RecordNotFound. Rails.root IS needed for
        # it to work under testing, without worrying about CWD.
        render file:         error_html,
               content_type: 'text/html',
               layout:       false,
               status:       error_status
      end
    end
  end
=end

=begin # NOTE: using base version
  # start_new_search_session?
  #
  # This method overrides:
  # @see Blacklight::CatalogExt#start_new_search_session?
  #
  def start_new_search_session?
    action_name == 'index'
  end
=end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

=begin # NOTE: using base version
  # json_presenter
  #
  # @param [Blacklight::Solr::Response]  response
  # @param [Array<Blacklight::Document>] documents
  #
  # @return [Blacklight::JsonPresenter]
  #
  # This method overrides:
  # @see Blacklight::CatalogExt#json_presenter
  #
  def json_presenter(response = nil, documents = nil)
    response  ||= @response
    documents ||= response.documents
    Blacklight::JsonPresenter.new(
      response,
      documents,
      facets_from_request,
      blacklight_config
    )
  end
=end

end

__loading_end(__FILE__)
