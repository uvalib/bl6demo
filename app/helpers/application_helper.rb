# app/helpers/application_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'
require 'config/_common'

# Common helper methods.
#
module ApplicationHelper

  include UVA::Constants
  include UVA::Networks

  # Displayed only if a method is set up to avoid returning *nil*.
  NO_LINK_DISPLAY = 'None available'.html_safe.freeze

  RETURN_NIL = {
    doi_link: false,
    url_link: true,
  }

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Produce a click-able URL link.
  #
  # If only one argument is given, it is interpreted as the URL and the "label"
  # becomes the text of the URL.
  #
  # @param [String]      label
  # @param [String, nil] url
  # @param [Hash, nil]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def outlink(label, url = nil, opt = nil)
    url ||= label
    html_opt = { target: '_blank' }
    html_opt.merge!(opt) if opt.is_a?(Hash)
    link_to(label, url, html_opt)
  end

  # ===========================================================================
  # :section: Blacklight configuration "helper_methods"
  # ===========================================================================

  public

  # url_link
  #
  # @param [Hash]      value        Supplied by Blacklight::FieldPresenter.
  # @param [Hash, nil] opt          Supplied internally to join multiple items.
  #
  # @option value [Hash]   :html_options        See below.
  # @option value [Hash]   :separator_options   See below.
  # @option value [String] :separator
  #
  # @option opt   [String] :separator
  #
  # @return [Array<ActiveSupport::SafeBuffer>]
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                                 If no URLs were present.
  #
  # Options separating multiple:
  # @see ActionView::Helper::OutputSafetyHelper#to_sentence
  #
  def url_link(value, opt = nil)
    values, opt = extract_config_value(value, opt)
    separator = opt.delete(:separator) || ' '
    result =
      Array.wrap(values).map { |url|
        parts = url.to_s.split('|', -3)
        next if (url = parts.first).blank?
        label = (parts.last.presence if parts.size > 1) || url
        outlink(label, url, opt)
      }.compact.join(separator).html_safe.presence
    result || (NO_LINK_DISPLAY unless RETURN_NIL[__method__])
  end

  # doi_link
  #
  # @param [Hash]      value        Supplied by Blacklight::FieldPresenter.
  # @param [Hash, nil] opt          Supplied internally to join multiple items.
  #
  # @option value [Hash]   :html_options        See below.
  # @option value [Hash]   :separator_options   See below.
  # @option value [String] :separator
  #
  # @option opt   [String] :separator
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                                 If no URLs were present.
  #
  def doi_link(value, opt = nil)
    value, opt = extract_config_value(value, opt)
    separator = opt.delete(:separator)
    result =
      Array.wrap(value).map { |url|
        next if url.blank?
        label = url.sub(%r{^https?://.*doi\.org/}, '')
        outlink(label, url, opt)
      }.compact.join(separator).html_safe.presence
    result || (NO_LINK_DISPLAY unless RETURN_NIL[__method__])
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # extract_config_options
  #
  # @param [Hash]      value
  # @param [Hash, nil] opt
  #
  # @option value [Hash]   :html_options        See below.
  # @option value [Hash]   :separator_options   See below.
  # @option value [String] :separator
  #
  # @option opt   [String] :separator
  #
  # @return [Array<(String, Hash)>]
  # @return [Array<(Array<String>, Hash)>]
  #
  # Options separating multiple:
  # @see ActionView::Helper::OutputSafetyHelper#to_sentence
  #
  def extract_config_value(value, opt = nil)
    opt ||= {}
    case value
      when Hash, Blacklight::Configuration::Field
        opt   = extract_config_options(value[:config], opt)
        value = value[:value]
      when Array # NOTE: 0% coverage for this case
        opt   = opt.merge(separator: HTML_NEW_LINE) unless opt.key?(:separator)
    end
    return value, opt
  end

  # extract_config_options
  #
  # @param [Hash]      config
  # @param [Hash, nil] opt
  #
  # @option config [Hash]   :html_options        See below.
  # @option config [Hash]   :separator_options   See below.
  # @option config [String] :separator
  #
  # @option opt    [String] :separator
  #
  # @return [Hash]
  #
  # Options separating multiple:
  # @see ActionView::Helper::OutputSafetyHelper#to_sentence
  #
  def extract_config_options(config, opt = nil)
    opt ||= {}
    if config.present?
      opt = opt.merge(config[:html_options] || {})
      if config.key?(:separator) # NOTE: 0% coverage for this case
        opt.merge!(separator: config[:separator])
      elsif config[:separator_options].present?
        opt.merge!(separator: config[:separator_options].first.last)
      end
    end
    opt
  end

end

__loading_end(__FILE__)
