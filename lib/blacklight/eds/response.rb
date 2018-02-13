# lib/blacklight/eds/response.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/eds'

# Blacklight::Eds::Response
#
# Derived from:
# @see Blacklight::Solr::Response
#
class Blacklight::Eds::Response < Blacklight::Solr::Response

=begin # NOTE: using base version
  extend Deprecation
=end

=begin # NOTE: using base version
  # Using required_dependency to work around Rails autoloading
  # problems when developing blacklight. Without this, any change
  # to this class breaks other classes in this namespace
  require_dependency 'blacklight/solr/response/pagination_methods'
  require_dependency 'blacklight/solr/response/response'
  require_dependency 'blacklight/solr/response/spelling'
  require_dependency 'blacklight/solr/response/facets'
  require_dependency 'blacklight/solr/response/more_like_this'
  require_dependency 'blacklight/solr/response/group_response'
  require_dependency 'blacklight/solr/response/group'
=end

=begin # NOTE: using base version
  include PaginationMethods
  include Spelling
  include Facets
  include Response
  include MoreLikeThis
=end

  require_dependency 'blacklight/eds/response/facets_eds'
  include FacetsEds

  # ===========================================================================
  # :section: Blacklight::Solr::Response overrides
  # ===========================================================================

  public

=begin # NOTE: using base version
  attr_reader :request_params
  attr_accessor :document_model, :blacklight_config
=end

=begin # NOTE: using base version
  # Initialize a self instance.
  #
  # @param [String] data
  # @param [Hash]   request_params
  # @param [Hash]   options
  #
  # @return [Hash]
  #
  # This method overrides:
  # @see Blacklight::Solr::Response#initialize
  #
  def initialize(data, request_params, options = {})
    super(force_to_utf8(ActiveSupport::HashWithIndifferentAccess.new(data)))
    @request_params =
      ActiveSupport::HashWithIndifferentAccess.new(request_params)
    self.document_model =
      options[:solr_document_model] || options[:document_model] || SolrDocument
    self.blacklight_config = options[:blacklight_config]
  end
=end

=begin # NOTE: using base version
  # header
  #
  # @return [Hash]
  #
  # This method overrides:
  # @see Blacklight::Solr::Response#header
  #
  def header
    self['responseHeader'] || {}
  end
=end

=begin # NOTE: using base version
  # params
  #
  # @return [Hash]
  #
  # This method overrides:
  # @see Blacklight::Solr::Response#params
  #
  def params
    header['params'] || request_params
  end
=end

=begin # NOTE: using base version
  # start
  #
  # @return [Integer]
  #
  # This method overrides:
  # @see Blacklight::Solr::Response#start
  #
  def start
    params[:start].to_i
  end
=end

=begin # NOTE: using base version
  # rows
  #
  # @return [Integer]
  #
  # This method overrides:
  # @see Blacklight::Solr::Response#rows
  #
  def rows
    params[:rows].to_i
  end
=end

=begin # NOTE: using base version
  # sort
  #
  # @return [String, nil]
  #
  # This method overrides:
  # @see Blacklight::Solr::Response#sort
  #
  def sort
    params[:sort]
  end
=end

=begin # NOTE: using base version
  # documents
  #
  # @return [Array<EdsDocument>]
  #
  # This method overrides:
  # @see Blacklight::Solr::Response#documents
  #
  def documents
    @documents ||=
      (response['docs'] || []).map{ |doc| document_model.new(doc, self) }
  end
  alias_method :docs, :documents
=end

=begin # NOTE: using base version
  # Grouped responses can either be grouped by:
  #   - field, where this key is the field name, and there will be a list
  #        of documents grouped by field value, or:
  #   - function, where the key is the function, and the documents will be
  #        further grouped by function value, or:
  #   - query, where the key is the query, and the matching documents will be
  #        in the doclist on THIS object
  #
  # @return [Array<GroupResponse, Group>]
  #
  # This method overrides:
  # @see Blacklight::Solr::Response#grouped
  #
  def grouped
    @groups ||=
      self['grouped'].map do |field, group|
        if group['groups']                      # Field or function.
          GroupResponse.new(field, group, self)
        else                                    # Query.
          Group.new(field, group, self)
        end
      end
  end
=end

=begin # NOTE: using base version
  # group
  #
  # @param [String] key
  #
  # @return [Array<String>]
  #
  # This method overrides:
  # @see Blacklight::Solr::Response#group
  #
  def group(key)
    grouped.find { |x| x.key == key }
  end
=end

=begin # NOTE: using base version
  # grouped?
  #
  # This method overrides:
  # @see Blacklight::Solr::Response#grouped?
  #
  def grouped?
    self.key?('grouped')
  end
=end

=begin # NOTE: using base version
  # export_formats
  #
  # @return [Array<String>]
  #
  # This method overrides:
  # @see Blacklight::Solr::Response#export_formats
  #
  def export_formats
    documents.map { |doc| doc.export_formats.keys }.flatten.uniq
  end
=end

  # ===========================================================================
  # :section: Blacklight::Solr::Response overrides
  # ===========================================================================

  private

  # force_to_utf8
  #
  # @param [Hash, Array, String] value
  #
  # @return [Hash, Array, String]     Potentially modified value.
  #
  # This method overrides:
  # @see Blacklight::Solr::Response#force_to_utf8
  #
  # NOTE: the original function doesn't appear to handled the String case right
  #
  def force_to_utf8(value)
    case value
      when Hash
        value.each { |k, v| value[k] = force_to_utf8(v) }
      when Array
        value.each { |v| force_to_utf8(v) }
      when String
        unless value.encoding == Encoding::UTF_8
          Blacklight.logger.warn {
            'Found a non utf-8 value in Blacklight::Solr::Response.' \
            "\"#{value}\" Encoding is #{value.encoding}"
          }
=begin
          value.dup.force_encoding('UTF-8')
=end
          value.force_encoding('UTF-8')
        end
    end
    value
  end

end

__loading_end(__FILE__)
