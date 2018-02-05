# app/helpers/blacklight/component_helper_behavior_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

module Blacklight

  # Blacklight::ComponentHelperBehaviorExt
  #
  # @see Blacklight::ComponentHelperBehavior
  #
  module ComponentHelperBehaviorExt

    include Blacklight::ComponentHelperBehavior
    include LensHelper

    # =========================================================================
    # :section: Blacklight::ComponentHelperBehavior overrides
    # =========================================================================

    public

=begin # NOTE: using base version
    # document_action_label
    #
    # @param [String, Symbol] action
    # @param [Hash]           opts
    #
    # @return [String]
    #
    # This method overrides:
    # @see Blacklight::ComponentHelperBehavior#document_action_label
    #
    def document_action_label(action, opts = nil)
      default = (opts.label if opts.is_a?(Hash)) || action.to_s.humanize
      t("blacklight.tools.#{action}", default: default)
    end
=end

=begin # NOTE: using base version
=end
    # document_action_path
    #
    # @param [?]         action_opts
    # @param [Hash, nil] url_opts
    #
    # @return [String]
    #
    # This method overrides:
    # @see Blacklight::ComponentHelperBehavior#document_action_path
    #
    def document_action_path(action_opts, url_opts = nil)
      url_opts ||= {}
      if action_opts.path
        self.send(action_opts.path, url_opts)
      elsif (id = url_opts[:id]).class.respond_to?(:model_name)
        url_for([action_opts.key, id])
      else # NOTE: 0% coverage for this case
        controller = default_lens_controller.controller_name
        url_helper = "#{action_opts.key}_#{controller}_path"
        self.send(url_helper, url_opts)
      end
    end

=begin # NOTE: using base version
    # Render "document actions" area for navigation header
    # (normally renders "Saved Searches", "History", "Bookmarks")
    #
    # @param [Hash] opt
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    # This method overrides:
    # @see Blacklight::ComponentHelperBehavior#document_action_path
    #
    def render_nav_actions(opt = nil, &block)
      opt ||= {}
      render_filtered_partials(blacklight_config.navbar.partials, opt, &block)
    end
=end

    # Render "document actions" area for search results view.
    # (Normally renders next to title in the list view.)
    #
    # @param [Blacklight::Document, nil] doc      Default: @document.
    # @param [Hash, nil]                 options
    #
    # @option options [String] :wrapping_class
    #
    # @return [ActiveSupport::SafeBuffer, nil]
    #
    # This method overrides:
    # @see Blacklight::ComponentHelperBehavior#render_index_doc_actions
    #
    def render_index_doc_actions(doc = nil, options = nil)
      doc ||= @document
      return unless doc.is_a?(Blacklight::Document)
      opt = { document: doc, wrapping_class: 'index-document-functions' }
      opt.merge!(options) if options.present?
      wrapper   = opt.delete(:wrapping_class)
      view_type = document_index_view_type # TODO: lens?
      view_cfg  = blacklight_config(doc).view_config(view_type)
      partials  = view_cfg.document_actions
      rendered  = render_filtered_partials(partials, opt)
      content_tag(:div, rendered, class: wrapper) unless rendered.blank?
    end

    # Render "collection actions" area for search results view
    # (normally renders next to pagination at the top of the result set)
    #
    # @param [Hash] options
    #
    # @option options [String] :wrapping_class
    #
    # @return [ActiveSupport::SafeBuffer, nil]
    #
    # This method overrides:
    # @see Blacklight::ComponentHelperBehavior#render_results_collection_tools
    #
    def render_results_collection_tools(options = nil)
      opt = { wrapping_class: 'search-widgets pull-right' }
      opt.merge!(options) if options.present?
      wrapper   = opt.delete(:wrapping_class)
      view_type = document_index_view_type # TODO: lens?
      view_cfg  = blacklight_config.view_config(view_type)
      partials  = view_cfg.collection_actions
      rendered  = render_filtered_partials(partials, opt)
      content_tag(:div, rendered, class: wrapper) unless rendered.blank?
    end

    # render_filters_partials
    #
    # @param [Blacklight::NestedOpenStructWithHashAccess] partials
    # @param [Hash]                                       options
    #
    # @yield [config, ActiveSupport::SafeBuffer]
    #
    # @return [ActiveSupport::SafeBuffer, nil]
    #
    # This method overrides:
    # @see Blacklight::ComponentHelperBehavior#render_filtered_partials
    #
    def render_filtered_partials(partials, options = nil)
      opt = {}
      opt.merge!(options) if options.is_a?(Hash)
      content = []
      filter_partials(partials, opt).each do |key, config|
        config.key ||= key
        partial  = config.partial || key.to_s
        locals   = opt.merge(document_action_config: config)
        rendered = render(partial, locals)
        next unless rendered
        if block_given?
          yield config, rendered
        else
          content << rendered
        end
      end
      safe_join(content, "\n") unless block_given?
    end

    # Render "document actions" for the item detail 'show' view.
    # (This normally renders next to title.)
    #
    # By default includes 'Bookmarks'
    #
    # @param [Blacklight::Document, nil] doc      Default: @document.
    # @param [Hash, nil]                 options
    #
    # @return [ActiveSupport::SafeBuffer, nil]
    #
    # This method overrides:
    # @see Blacklight::ComponentHelperBehavior#render_show_doc_actions
    #
    def render_show_doc_actions(doc = nil, options = nil, &block)
      doc ||= @document
      return unless doc.is_a?(Blacklight::Document)
      opt = { document: doc }
      opt.merge!(options) if options.present?
      partials = blacklight_config(doc).show.document_actions
      render_filtered_partials(partials, opt, &block)
    end

    # show_doc_actions?
    #
    # @param [Blacklight::Document, nil] doc      Default: @document.
    # @param [Hash]                      options
    #
    # This method overrides:
    # @see Blacklight::ComponentHelperBehavior#show_doc_actions?
    #
    def show_doc_actions?(doc = nil, options = nil)
      doc ||= @document
      return unless doc.is_a?(Blacklight::Document)
      opt = { document: doc }
      opt.merge!(options) if options.present?
      partials = blacklight_config(doc).show.document_actions
      filter_partials(partials, opt).any?
    end

    # =========================================================================
    # :section: Blacklight::ComponentHelperBehavior overrides
    # =========================================================================

    private

=begin # NOTE: using base version
=end
    # filter_partials
    #
    # @param [Blacklight::NestedOpenStructWithHashAccess] partials
    # @param [Hash]                                       options
    #
    # @return [Hash]
    #
    # This method overrides:
    # @see Blacklight::ComponentHelperBehavior#filter_partials
    #
    def filter_partials(partials, options)
      context = blacklight_configuration_context
      partials.select do |_, config|
        context.evaluate_if_unless_configuration(config, options)
      end
    end

  end

end

__loading_end(__FILE__)
