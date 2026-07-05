# frozen_string_literal: true

# name: discourse-sitetor-mapping
# about: Sitetor Mapping Filter — trang /mapping lọc NHU CẦU mua/thuê BĐS (nửa Cầu của thị trường, đối xứng /listing) + nút Giới thiệu ngay
# version: 0.2.0
# authors: Sitetor
# url: https://lms.sitetor.com

enabled_site_setting :sitetor_mapping_enabled

register_asset "stylesheets/sitetor-mapping.scss"

module ::SitetorMapping
  PLUGIN_NAME = "discourse-sitetor-mapping"

  # đọc chung custom fields do discourse-sitetor-listing parse/backfill
  FIELD_PRICE = "listing_price"
  FIELD_FRONTAGE = "listing_frontage"
  FIELD_AREA = "listing_area"
  FIELD_TYPE = "listing_type"
  FIELD_POSITION = "listing_position"
  FIELD_DIRECTION = "listing_direction"
  FIELD_STREET_NUMBER = "listing_street_number"
  FIELD_STREET = "listing_street"
  FIELD_WARD = "listing_ward"
  FIELD_DISTRICT = "listing_district"
  FIELD_PROVINCE = "listing_province"

  MULTI_FILTERS = {
    "type" => FIELD_TYPE,
    "position" => FIELD_POSITION,
    "direction" => FIELD_DIRECTION,
    "street" => FIELD_STREET,
    "ward" => FIELD_WARD,
    "district" => FIELD_DISTRICT,
    "province" => FIELD_PROVINCE,
  }.freeze
end

after_initialize do
  module ::SitetorMapping
    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace SitetorMapping
    end

    # Mở rộng danh sách category gồm cả sub + sub-sub (hỗ trợ gộp về
    # 1 category cha Mapping với cây con Cần mua/Cần thuê bên trong)
    def self.with_descendants(ids)
      children = Category.where(parent_category_id: ids).pluck(:id)
      grandchildren = Category.where(parent_category_id: children).pluck(:id)
      (ids + children + grandchildren).uniq
    end
  end

  # Category type "Mapping" trong wizard /new-category/setup
  if respond_to?(:register_category_type)
    require_relative "app/services/sitetor_mapping/categories/types/mapping"
    reloadable_patch { register_category_type(SitetorMapping::Categories::Types::Mapping) }
  end

  require_relative "app/controllers/sitetor_mapping/page_controller"
  require_relative "app/controllers/sitetor_mapping/filter_controller"

  SitetorMapping::Engine.routes.draw do
    get "/" => "page#index"
    get "/filter" => "filter#index"
    get "/facets" => "filter#facets"
  end

  Discourse::Application.routes.append { mount ::SitetorMapping::Engine, at: "/mapping" }
end
