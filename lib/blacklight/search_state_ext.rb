# lib/blacklight/search_state_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight'

module Blacklight

  # Overrides Blacklight::SearchState for lens-sensitivity.
  #
  # @see Blacklight::SearchState
  #
  class SearchStateExt < Blacklight::SearchState

    include LensHelper

    # =========================================================================
    # :section: Blacklight::SearchState replacements
    # =========================================================================

    public

=begin # NOTE: using base version
    # Must be called "blacklight_config" because Blacklight::Facet expects it.
    #
    # @return [Blacklight::Configuration]
    #
    # This method overrides:
    # @see Blacklight::SearchState#blacklight_config
    #
    attr_reader :blacklight_config
=end

=begin # NOTE: using base version
    # params
    #
    # @return [ActiveSupport::HashWithIndifferentAccess]
    #
    # This method overrides:
    # @see Blacklight::SearchState#params
    #
    attr_reader :params
=end

=begin # NOTE: using base version
    # This method is never accessed in this class, but may be used by
    # subclasses that need to access the url_helpers.
    #
    # @return [ActionController]
    #
    # This method overrides:
    # @see Blacklight::SearchState#controller
    #
    attr_reader :controller
=end

=begin # NOTE: using base version
    delegate :facet_configuration_for_field, to: :blacklight_config
=end

=begin # NOTE: using base version
    # Initialize a self instance.
    #
    # @param [ActionController::Parameters] params
    # @param [Blacklight::Configuration]    blacklight_config
    # @param [ApplicationController]        controller
    #
    # This method overrides:
    # @see Blacklight::SearchState#initialize
    #
    def initialize(params, blacklight_config, controller = nil)
      @params =
        if params.respond_to?(:to_unsafe_h)
          # This is the typical (not-ActionView::TestCase) code path.
          # In Rails 5 to_unsafe_h returns a HashWithIndifferentAccess, in
          # Rails 4 it returns Hash.
          p = params.to_unsafe_h
          p = p.with_indifferent_access if p.instance_of?(Hash)
          p
        elsif params.is_a?(Hash)
          # This is an ActionView::TestCase workaround for Rails 4.2.
          params.dup.with_indifferent_access
        else
          (params || {}).to_h.with_indifferent_access
        end
      @blacklight_config = blacklight_config
      @controller        = controller
    end
=end

    # TODO: This would avoid needing to do SearchStateExt.new.to_hash to extract search parameter values
    delegate :[], :key?, :keys, to: :to_hash

=begin # NOTE: using base version
    # to_hash
    #
    # @return [ActiveSupport::HashWithIndifferentAccess]
    #
    # This method overrides:
    # @see Blacklight::SearchState#to_hash
    #
    def to_hash
      @params
    end
    alias to_h to_hash
=end

=begin # NOTE: using base version
    # reset
    #
    # @param [ActionController::Parameters, Hash, nil] params
    #
    # @return [Blacklight::SearchState]
    #
    # This method overrides:
    # @see Blacklight::SearchState#reset
    #
    def reset(params = nil)
      params ||= ActionController::Parameters.new
      self.class.new(params, blacklight_config, controller)
    end
=end

    # Extension point for downstream applications to provide more interesting
    # routing to documents.
    #
    # @param [Blacklight::Document] doc
    # @param [Hash, nil]            options
    #
    # @return [String, Blacklight::Document, nil]
    #
    # This method overrides:
    # @see Blacklight::SearchState#url_for_document
    #
    def url_for_document(doc, options = nil)
      valid = doc.is_a?(Blacklight::Document)
      valid ||=
        doc.respond_to?(:to_model) && doc.to_model.is_a?(Blacklight::Document)
      if !valid
        doc
      elsif (route = blacklight_config.show.route).is_a?(String) # NOTE: 0% coverage for this case
        url_for([route, id: doc])
      else
        path = { controller: current_lens_key, action: 'show', id: doc }
        path.merge!(route)   if route.is_a?(Hash)
        path.merge!(options) if options.is_a?(Hash)
        path[:controller] = nil if path[:controller] == :current
        path[:controller] ||= params[:controller]
        path
      end
    end

=begin # NOTE: using base version
    # Adds the value and/or field to params[:f].
    #
    # Does NOT remove request keys and otherwise ensure that the hash
    # is suitable for a redirect.
    #
    # @param [?] field
    # @param [?] item
    #
    # @return [ActionController::Parameters]
    #
    # @see self#add_facet_params_and_redirect
    #
    # This method overrides:
    # @see Blacklight::SearchState#add_facet_params
    #
    def add_facet_params(field, item)
      reset_search_params.tap do |p|
        add_facet_param(p, field, item)
        fq = (item.fq if item.respond_to?(:fq))
        Array(fq).each { |f, v| add_facet_param(p, f, v) } if fq
      end
    end
=end

=begin # NOTE: using base version
    # Used in catalog/facet action, facets.rb view, for a click on a facet
    # value. Add on the facet params to existing search constraints. Remove any
    # paginator-specific request params, or other request params that should be
    # removed for a 'fresh' display.
    #
    # Change the action to 'index' to send them back to catalog/index with
    # their new facet choice.
    #
    # @param [?] field
    # @param [?] item
    #
    # @return [ActionController::Parameters]
    #
    # This method overrides:
    # @see Blacklight::SearchState#add_facet_params_and_redirect
    #
    def add_facet_params_and_redirect(field, item)
      add_facet_params(field, item).tap do |new_params|
        # Delete any request params from facet-specific action, needed to
        # redirect to index action properly.
        request_keys = blacklight_config.facet_paginator_class.request_keys
        new_params.extract!(*request_keys.values)
      end
    end
=end

=begin # NOTE: using base version
    # Copies the current params (or whatever is passed in as the 3rd arg);
    # removes the field value from params[:f];
    # removes the field if there are no more values in params[:f][field];
    # removes additional params (:page, :id, etc..).
    #
    # @param [?] field
    # @param [?] item
    #
    # @return [ActionController::Parameters]
    #
    # This method overrides:
    # @see Blacklight::SearchState#remove_facet_params
    #
    def remove_facet_params(field, item)

      field = item.field if item.respond_to?(:field)

      facet_config = facet_configuration_for_field(field)
      url_field    = facet_config.key

      reset_search_params.tap do |p|
        # Need to dup the facet values too, if the values aren't dup'd, then
        # the values from the session will get remove in the show view...
        p[:f] &&= p[:f].dup
        p[:f] ||= {}
        p[:f][url_field] &&= p[:f][url_field].dup
        p[:f][url_field] ||= []
        collection = p[:f][url_field]

        # Collection should be an array, because we link to "?f[key][]=value",
        # however, Facebook (and maybe some other PHP tools) transform those
        # parameters into "?f[key][0]=value", which Rails interprets as a Hash.
        collection = collection.values if collection.is_a?(Hash)

        value = facet_value_for_facet_item(item)
        p[:f][url_field] = collection - [value]
        p[:f].delete(url_field) if p[:f][url_field].blank?
        p.delete(:f) if p[:f].blank?
      end
    end
=end

=begin # NOTE: using base version
    # Merge the source params with the params_to_merge hash.
    #
    # @param [Hash] params_to_merge to merge into above
    #
    # @yield [params] The merged parameters hash before being sanitized
    #
    # @return [ActionController::Parameters]  The current search parameters
    #                                           after being sanitized by
    #                                           Blacklight::Parameters#sanitize
    #
    # This method overrides:
    # @see Blacklight::SearchState#params_for_search
    #
    def params_for_search(params_to_merge = nil, &block)
      result = params.merge(reset(params_to_merge))

      yield result if block_given?

      if result[:page]
        if result.slice(:per_page, :sort) != params.slice(:per_page, :sort)
          result[:page] = 1
        end
      end

      Parameters.sanitize(result)
    end
=end

    # =========================================================================
    # :section: Blacklight::SearchState replacements
    # =========================================================================

    private

=begin # NOTE: using base version
    # Reset any search parameters that store search context and need to be
    # reset (e.g. when constraints change).
    #
    # @return [ActionController::Parameters]
    #
    # This method overrides:
    # @see Blacklight::SearchState#reset_search_params
    #
    def reset_search_params
      Parameters.sanitize(params).except(:page, :counter)
    end
=end

=begin # NOTE: using base version
    # facet_value_for_facet_item
    #
    # @param [?] item
    #
    # @return [?]
    #
    # TODO: this code is duplicated in Blacklight::FacetsHelperBehavior
    #
    # This method overrides:
    # @see Blacklight::SearchState#facet_value_for_facet_item
    #
    def facet_value_for_facet_item(item)
      item.respond_to?(:value) ? item.value : item
    end
=end

=begin # NOTE: using base version
    # add_facet_param
    #
    # @param [ActionController::Parameters, Hash] p
    # @param [?] field
    # @param [?] item
    #
    # @return [void]
    #
    # This method overrides:
    # @see Blacklight::SearchState#add_facet_param
    #
    def add_facet_param(p, field, item)

      field = item.field if item.respond_to?(:field)

      facet_config = facet_configuration_for_field(field)
      url_field    = facet_config.key

      p[:f] &&= p[:f].dup
      p[:f] ||= {}
      p[:f][url_field] =
        if p[:f][url_field] && !facet_config.single
          p[:f][url_field].dup
        end
      p[:f][url_field] ||= []
      p[:f][url_field] << facet_value_for_facet_item(item)
    end
=end

  end

end

__loading_end(__FILE__)
