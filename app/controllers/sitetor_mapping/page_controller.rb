# frozen_string_literal: true

module SitetorMapping
  # Full page load /mapping: render app shell rỗng để Ember boot,
  # route "mapping" phía client đảm nhận phần còn lại.
  class PageController < ::ApplicationController
    requires_plugin SitetorMapping::PLUGIN_NAME
    skip_before_action :check_xhr

    def index
      render "default/empty"
    end
  end
end
