# app/helpers/blacklight/layout_helper_behavior_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

module Blacklight

  # A module for useful methods used in layout configuration.
  #
  # This module overrides:
  # @see Blacklight::LayoutHelperBehavior
  #
  module LayoutHelperBehaviorExt

    include Blacklight::LayoutHelperBehavior

    META_TAG_SEPARATOR = "\n  "

    EXTERNAL_FONTS = %w(
      //fonts.googleapis.com/css?family=Cardo:400,700
      //maxcdn.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css
    ).freeze

    DEFAULT_JQUERY =
      '//ajax.googleapis.com/ajax/libs/jquery/3.2.1/jquery.min.js' && \
        nil # TODO: jQuery version in use is 1.12.4

    EXTERNAL_SCRIPTS = %W(
      //use.typekit.com/dcu6kro.js
    ).reject(&:blank?).freeze
    #EXTERNAL_SCRIPTS = %W(
    #  //use.typekit.com/dcu6kro.js
    #  #{Piwik.script} # TODO: Piwik
    #).reject(&:blank?).freeze

    # This script is being added as part of a UVA effort to analyze and improve
    # accessibility.
    #
    # @see https://levelaccess.com
    #
    ACCESS_ANALYTICS = %q(
      <script type="text/javascript">
        var access_analytics={
        base_url:"https://analytics.ssbbartgroup.com/api/",
        instance_id:"AA-58bdcc11cee35"};(function(a,b,c){
        var d=a.createElement(b);a=a.getElementsByTagName(b)[0];
        d.src=c.base_url+"access.js?o="+c.instance_id+"&v=2";
        a.parentNode.insertBefore(d,a)})(document,"script",access_analytics);
      </script>
    ).squish.freeze && nil # TODO: ACCESS_ANALYTICS

    # =========================================================================
    # :section: Blacklight::UrlHelperBehavior overrides
    # =========================================================================

    public

=begin # NOTE: using base version
    # Classes added to a document's show content div.
    #
    # @return [String]
    #
    # This method overrides:
    # @see Blacklight::LayoutHelperBehavior#show_content_classes
    #
    def show_content_classes
      "#{main_content_classes} show-document"
    end
=end

=begin # NOTE: using base version
    # Classes added to a document's sidebar div.
    #
    # @return [String]
    #
    # This method overrides:
    # @see Blacklight::LayoutHelperBehavior#show_sidebar_classes
    #
    def show_sidebar_classes
      sidebar_classes
    end
=end

=begin # NOTE: using base version
    # Classes used for sizing the main content of a Blacklight page.
    #
    # @return [String]
    #
    # This method overrides:
    # @see Blacklight::LayoutHelperBehavior#main_content_classes
    #
    def main_content_classes
      'col-md-9 col-sm-8'
    end
=end

=begin # NOTE: using base version
    # Classes used for sizing the sidebar content of a Blacklight page.
    #
    # @return [String]
    #
    # This method overrides:
    # @see Blacklight::LayoutHelperBehavior#sidebar_classes
    #
    def sidebar_classes
      'col-md-3 col-sm-4'
    end
=end

=begin # NOTE: using base version
    # Class used for specifying main layout container classes. Can be
    # overridden to return 'container-fluid' for Bootstrap full-width layout.
    #
    # @return [String]
    #
    # This method overrides:
    # @see Blacklight::LayoutHelperBehavior#container_classes
    #
    def container_classes
      'container'
    end
=end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # external_stylesheets
    #
    # @param [Array<String>] args     Added script URL's or literal tags.
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    # TODO: needs work
    #
    def external_stylesheets(*args)
      tags, paths = args.partition { |arg| arg.include?('<link') }
      paths = (EXTERNAL_FONTS + paths).reject(&:blank?)
      tags  = tags.reject(&:blank?).uniq.join(META_TAG_SEPARATOR).html_safe
      stylesheet_link_tag(*paths) + tags
    end

    # external_scripts
    #
    # @param [Array<String>] args     Added script URL's or literal tags.
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    # TODO: needs work
    #
    def external_scripts(*args)
      tags, paths = args.partition { |arg| arg.include?('<script') }
      paths = (EXTERNAL_SCRIPTS + [DEFAULT_JQUERY] + paths).reject(&:blank?)
      tags << ACCESS_ANALYTICS
      tags  = tags.reject(&:blank?).uniq.join(META_TAG_SEPARATOR).html_safe
      javascript_include_tag(*paths) + tags
    end

  end

end

__loading_end(__FILE__)
