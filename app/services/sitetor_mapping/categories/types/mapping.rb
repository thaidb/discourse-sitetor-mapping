# frozen_string_literal: true

# Category type "Mapping" trong wizard tạo category (/new-category/setup):
# tạo category kiểu này → ID tự thêm vào sitetor_mapping_categories (trang
# /mapping) và sitetor_filter_demand_categories (để plugin filter parse dữ liệu).
module SitetorMapping
  module Categories
    module Types
      class Mapping < ::Categories::Types::Base
        type_id :sitetor_mapping

        class << self
          def enable_plugin
            SiteSetting.sitetor_mapping_enabled = true
          end

          def plugin_enabled?
            SiteSetting.sitetor_mapping_enabled
          end

          def category_matches?(category)
            setting_ids.include?(category.id)
          end

          def find_matches
            Category.where(id: setting_ids)
          end

          def configure_category(category, guardian:, configuration_values: {})
            configure_custom_fields(category, guardian:, configuration_values:)
            update_settings(setting_ids | [category.id], category, guardian, add: true)
          end

          def unconfigure_category(category, guardian:)
            update_settings(setting_ids - [category.id], category, guardian, add: false)
          end

          def configuration_schema
            {
              general_category_settings: {
                name: {
                  default: I18n.t("category_types.sitetor_mapping.name"),
                  type: :string,
                },
                style_type: {
                  default: "emoji",
                  type: :string,
                },
                emoji: {
                  default: "handshake",
                  type: :string,
                },
              },
              site_settings: {
              },
              category_custom_fields: {
              },
              site_texts: {
              },
            }
          end

          def icon
            "handshake"
          end

          private

          def setting_ids
            SiteSetting.sitetor_mapping_categories.split("|").map(&:to_i).reject(&:zero?)
          end

          def update_settings(ids, category, guardian, add:)
            user = guardian&.user || Discourse.system_user
            SiteSetting.set_and_log("sitetor_mapping_categories", ids.uniq.join("|"), user)

            # đồng bộ sang plugin filter (nếu có cài) để dữ liệu được parse
            if SiteSetting.respond_to?(:sitetor_filter_demand_categories)
              demand = SiteSetting.sitetor_filter_demand_categories.split("|").map(&:to_i)
              demand = add ? (demand | [category.id]) : (demand - [category.id])
              SiteSetting.set_and_log("sitetor_filter_demand_categories", demand.uniq.join("|"), user)
            end
          end
        end
      end
    end
  end
end
