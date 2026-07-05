# frozen_string_literal: true

# name: discourse-sitetor-mapping
# about: Sitetor Mapping Filter — trang /mapping lọc NHU CẦU mua/thuê BĐS (nửa Cầu của thị trường, đối xứng /listing) + nút Giới thiệu ngay
# version: 0.1.0
# authors: Sitetor
# url: https://lms.sitetor.com

enabled_site_setting :sitetor_mapping_enabled

register_asset "stylesheets/sitetor-mapping.scss"

module ::SitetorMapping
  PLUGIN_NAME = "discourse-sitetor-mapping"

  # đọc chung custom fields do discourse-sitetor-filter parse/backfill
  FIELD_GIA = "bds_gia"
  FIELD_MAT_TIEN = "bds_mat_tien"
  FIELD_DIEN_TICH = "bds_dien_tich"
  FIELD_LOAI = "bds_loai"
  FIELD_VI_TRI = "bds_vi_tri"
  FIELD_HUONG = "bds_huong"
  FIELD_SO_NHA = "bds_so_nha"
  FIELD_DUONG = "bds_duong"
  FIELD_PHUONG = "bds_phuong"
  FIELD_QUAN = "bds_quan"
  FIELD_TINH = "bds_tinh"

  MULTI_FILTERS = {
    "loai" => FIELD_LOAI,
    "vi_tri" => FIELD_VI_TRI,
    "huong" => FIELD_HUONG,
    "duong" => FIELD_DUONG,
    "phuong" => FIELD_PHUONG,
    "quan" => FIELD_QUAN,
    "tinh" => FIELD_TINH,
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
