# app/presenters/blacklight/show_presenter_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

module Blacklight

  # Blacklight::ShowPresenterExt
  #
  # Subclass of:
  # @see Blacklight::ShowPresenter
  #
  class ShowPresenterExt < Blacklight::ShowPresenter

    include Blacklight::PresenterBehaviors

=begin # NOTE: using base version
    extend Deprecation
    self.deprecation_horizon = 'Blacklight version 7.0.0'
=end

    # =========================================================================
    # :section: Blacklight::ShowPresenter overrides
    # =========================================================================

    public

=begin # NOTE: using base version
    attr_reader :document, :configuration, :view_context
=end

=begin # NOTE: using base version
    # Initialize a self instance.
    #
    # @param [Blacklight::Document]           doc
    # @param [ActionView::Base]               view_context
    # @param [Blacklight::Configuration, nil] configuration
    #
    # This method overrides:
    # @see Blacklight::ShowPresenter#initialize
    #
    def initialize(doc, view_context, configuration = nil)
      @document      = doc
      @view_context  = view_context
      @configuration = configuration || @view_context.blacklight_config
    end
=end

=begin # NOTE: using base version
    # Create <link rel="alternate"> links from a documents dynamically
    # provided export formats. Returns empty string if no links available.
    #
    # @param [Hash, nil] options
    #
    # @option options [Boolean]       :unique   Ensures only one link is output
    #                                             for every content type, e.g.
    #                                             as required by Atom.
    #
    # @option options [Array<String>] :exclude  Array of format shortnames to
    #                                             not include in the output.
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    # @deprecated moved to ShowPresenter#link_rel_alternates
    #
    # This method overrides:
    # @see Blacklight::ShowPresenter#link_rel_alternates
    #
    def link_rel_alternates(options = nil)
      options ||= {}
      LinkAlternatePresenter.new(view_context, document, options).render
    end
=end

    # Get the document's "title" to display in the <title> element.
    # (By default, use the #document_heading.)
    #
    # @param [Hash, nil] options
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    # @see self#document_heading
    #
    # This method overrides:
    # @see Blacklight::ShowPresenter#html_title
    #
    # NOTE: 0% coverage for this method
    #
    def html_title(options = nil)
      fields = Array.wrap(view_config.html_title)
      if fields.present?
        f = fields.find { |field| document.has?(field) }
        f ||= configuration.default_title_field
        field_value(f)
      else
        opt = { line_separator: '<br/>'.html_safe }
        opt.merge!(options) if options.is_a?(Hash)
        heading(opt)
      end
    end

=begin # NOTE: using base version
    # document_show_html_title
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    # @deprecated
    #
    # This method overrides:
    # @see Blacklight::ShowPresenter#document_show_html_title
    #
    def document_show_html_title
      html_title
    end
    deprecate document_show_html_title: 'use #html_title'
=end

    # Get the value of the document's "title_field" and "subtitle_field", or a
    # placeholder value (if empty).
    #
    # @param [Hash, nil] options
    #
    # @option options [Boolean] :format         Set as *false* for plain text
    #                                             instead of HTML.
    #
    # @option options [Boolean] :show_title     Set as *false* to only show the
    #                                             subtitle.
    #
    # @option options [Boolean] :show_subtitle  Set as *false* to only show the
    #                                             main title.
    #
    # @option options [Boolean] :show_linked_title  Set as *false* to avoid
    #                                             showing the original-language
    #                                             title.
    #
    # @option options [String]  :title_sep      String shown between title and
    #                                             subtitle.  Set as *nil* to
    #                                             have no separator.
    #
    # @option options [String]  :author_sep     String shown between authors.
    #                                             Set as *nil* to have no
    #                                             separator.
    #
    # @option options [String]  :line_break     String shown between title and
    #                                             subtitle.  Set as *nil* to
    #                                             have no break.
    #
    # @return [ActiveSupport::SafeBuffer]   If *format* is *true*.
    # @return [String]                      If *format* is not *true*.
    #
    # This method overrides:
    # @see Blacklight::ShowPresenter#heading
    #
    # For search results (index page), compare with:
    # @see Blacklight::IndexPresenterExt#label
    # TODO: share logic
    #
    def heading(options = nil)
      opt = {
        format:              true,
        title_sep:           ': ',
        title_tag:           DEF_TITLE_TAG,
        title_class:         nil,
        show_title:          true,
        show_subtitle:       true,
        show_linked_title:   true,
        author_sep:          ', ',
        author_tag:          DEF_AUTHOR_TAG,
        author_class:        nil,
        show_authors:        true,
        show_linked_authors: true,
        line_break:          '<br/>'.html_safe,
      }
      opt.merge!(options) if options.is_a?(Hash)
      format         = opt.delete(:format).presence
      title_sep      = opt.delete(:title_sep).presence
      title_tag      = opt.delete(:title_tag).presence
      title_class    = opt.delete(:title_class).presence
      title          = opt.delete(:show_title).presence
      subtitle       = opt.delete(:show_subtitle).presence
      linked_title   = opt.delete(:show_linked_title).presence
      author_sep     = opt.delete(:author_sep).presence
      author_tag     = opt.delete(:author_tag).presence
      author_class   = opt.delete(:author_class).presence
      authors        = opt.delete(:show_authors).presence
      linked_authors = opt.delete(:show_linked_authors).presence
      line_break     = opt.delete(:line_break).presence
      line_break     = "\n" if line_break && !format

      default_field = configuration.default_title_field
      title        &&= value_for(view_config.title_field, default_field)
      subtitle     &&= value_for(view_config.subtitle_field)
      linked_title &&= value_for(view_config.alt_title_field)

      title_lines = []
      title_lines << linked_title
      title_lines << [title, subtitle].reject(&:blank?).join(title_sep)

      authors        &&= value_for(view_config.author_field)
      linked_authors &&= value_for(view_config.alt_author_field)

      author_lines = []
      author_lines << Array.wrap(linked_authors).join(author_sep)
      author_lines << Array.wrap(authors).join(author_sep)

      if format
        title_result =
          title_lines.map { |line|
            ERB::Util.h(line) if line.present?
          }.compact.join(line_break).html_safe
        if title_tag || title_class
          case title_tag
            when nil  then title_tag = :div # NOTE: 0% coverage for this case
            when true then title_tag = DEF_TITLE_TAG # NOTE: 0% coverage for this case
          end
          title_opt = {}
          title_opt[:class] = title_class if title_class
          title_opt[:itemprop] = 'name'
          title_result = content_tag(title_tag, title_result, title_opt)
        end
        author_result =
          author_lines.map { |line|
            ERB::Util.h(line) if line.present?
          }.compact.join(line_break).html_safe
        if author_tag || author_class
          case author_tag
            when nil  then author_tag = :div # NOTE: 0% coverage for this case
            when true then author_tag = DEF_TITLE_TAG # NOTE: 0% coverage for this case
          end
          author_opt = {}
          author_opt[:class] = author_class if author_class
          author_result = content_tag(author_tag, author_result, author_opt)
        end
        title_result + author_result
      else
        (title_lines + author_lines).reject(&:blank?).join(line_break)
      end

    end

=begin # NOTE: using base version
    # document_heading
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    # @deprecated
    #
    # This method overrides:
    # @see Blacklight::ShowPresenter#document_heading
    #
    def document_heading
      heading
    end
    deprecate document_heading: 'replaced by #heading'
=end

=begin # NOTE: using base version
    # Render the show field value for a document.
    #
    # Allow an extension point where information in the document may drive the
    # value of the field.
    #
    # @param [String, Symbol] field
    # @param [Hash, nil]      options
    #
    # @option options [String] :value
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    # This method overrides:
    # @see Blacklight::ShowPresenter#field_value
    #
    def field_value(field, options = nil)
      field_values(field_config(field), options)
    end
=end

=begin # NOTE: using base version
    # render_document_show_field_value
    #
    # @param [Array] args
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    # @deprecated
    #
    # This method overrides:
    # @see Blacklight::ShowPresenter#render_document_show_field_value
    #
    def render_document_show_field_value(*args)
      field_value(*args)
    end
    deprecate render_document_show_field_value: 'replaced by #field_value'
=end

=begin # NOTE: using base version
    # get_field_values
    #
    # @param [Blacklight::Configuration::Field] field_def
    # @param [Hash, nil]                        options
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    # @deprecated
    #
    # This method overrides:
    # @see Blacklight::ShowPresenter#get_field_values
    #
    def get_field_values(field_def, options = nil)
      field_values(field_def, options)
    end
    deprecate get_field_values: 'replaced by #field_value'
=end

=begin # NOTE: using base version
    # render_field_values
    #
    # @param [String, Array<String>]                 values
    # @param [Blacklight::Configuration::Field, nil] field_def
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    # @deprecated
    #
    # This method overrides:
    # @see Blacklight::ShowPresenter#render_field_values
    #
    def render_field_values(values, field_def = nil)
      render_values(values, field_def)
    end
    deprecate render_field_values: 'replaced by #field_value'
=end

=begin # NOTE: using base version
    # render_values
    #
    # @param [String, Array<String>]                 values
    # @param [Blacklight::Configuration::Field, nil] field_def
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    # @deprecated
    #
    # This method overrides:
    # @see Blacklight::ShowPresenter#render_values
    #
    def render_values(values, field_def = nil)
      field_def ||= Configuration::NullField.new
      field_values(field_def, value: Array.wrap(values))
    end
    deprecate render_values: 'replaced by #field_value'
=end

    # =========================================================================
    # :section: Blacklight::ShowPresenter overrides
    # =========================================================================

    private

=begin # NOTE: using base version
    # Get the value for a document's field, and prepare to render it.
    # - highlight_field
    # - accessor
    # - solr field
    #
    # Rendering:
    #   - helper_method
    #   - link_to_search
    #
    # @param [Blacklight::Configuration::Field] field_def
    # @param [Hash, nil]                        options
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    # This method overrides:
    # @see Blacklight::ShowPresenter#field_values
    #
    def field_values(field_def, options = nil)
      options ||= {}
      FieldPresenter.new(view_context, document, field_def, options).render
    end
=end

=begin # NOTE: using base version
    # view_config
    #
    # @return [Blacklight::Configuration::ViewConfig]
    #
    # This method overrides:
    # @see Blacklight::ShowPresenter#view_config
    #
    def view_config
      configuration.view_config(:show)
    end
=end

=begin # NOTE: using base version
    # field_config
    #
    # @param [String, Symbol] field
    #
    # @return [Blacklight::Configuration::Field]
    #
    # This method overrides:
    # @see Blacklight::ShowPresenter#field_config
    #
    def field_config(field)
      configuration.show_fields
        .fetch(field) { Configuration::NullField.new(field) }
    end
=end

  end

end

__loading_end(__FILE__)
