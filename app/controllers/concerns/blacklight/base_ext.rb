# app/controllers/concerns/blacklight/base_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# An extension to Blacklight::Base.
#
# Compare with:
# @see Blacklight::Base
#
module Blacklight::BaseExt

  extend ActiveSupport::Concern

  include Blacklight::Base

  include Blacklight::ConfigurableExt
  include Blacklight::SearchHelperExt
  include Blacklight::SearchContextExt

  # Code to be added to the controller class including this module.
  included do |base|
    __included(base, 'Blacklight::BaseExt')
    include RescueConcern
    include LensConcern
=begin # NOTE: using base method
    # When Blacklight::Exceptions::InvalidRequest is raised, the
    # rsolr_request_error method is executed.
    # The index action will more than likely throw this one.
    # Example, when the standard query parser is used, and a user submits a
    # "bad" query.
    rescue_from Blacklight::Exceptions::InvalidRequest, with: :handle_request_error if respond_to?(:rescue_from)
=end
  end

end

__loading_end(__FILE__)
