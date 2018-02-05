# lib/ext/ebsco-eds/ext.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Support for actively redefining objects defined in the EBSCO EDS gem.

__loading_begin(__FILE__)

require File.join(Rails.root, 'app/models/blacklight/eds')

# Load files from this subdirectory.
_LIB_EXT_EBSCO_EDS_LOADS ||=
  begin
    dir = File.dirname(__FILE__)
    Dir["#{dir}/**.rb"].each do |path|
      require(path) unless path == __FILE__
    end
  end

__loading_end(__FILE__)
