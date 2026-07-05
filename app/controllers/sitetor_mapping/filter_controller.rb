# frozen_string_literal: true

module SitetorMapping
  class FilterController < ::ApplicationController
    requires_plugin SitetorMapping::PLUGIN_NAME

    SORTS = {
      "new" => "topics.bumped_at DESC",
      "price_asc" => :price_asc,
      "price_desc" => :price_desc,
      "area_desc" => :area_desc,
    }.freeze

    # GET /mapping/filter.json — lọc topic NHU CẦU (Cần mua/Cần thuê).
    # Params: q | price_min, price_max (VND — ngân sách) | frontage_min, frontage_max | area_min, area_max
    #         | type,district,ward,street,position,direction,province (CSV) | category_id | sort | page
    def index
      page = params[:page].to_i
      per = SiteSetting.sitetor_mapping_page_size

      topics = Topic
        .visible
        .listable_topics
        .where(category_id: allowed_category_ids)

      if params[:q].present?
        topics = topics.where("topics.title ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[:q])}%")
      end

      topics = apply_range(topics, SitetorMapping::FIELD_PRICE, :price_min, :price_max)
      topics = apply_range(topics, SitetorMapping::FIELD_FRONTAGE, :frontage_min, :frontage_max)
      topics = apply_range(topics, SitetorMapping::FIELD_AREA, :area_min, :area_max)
      topics = apply_multi_filters(topics)

      total = topics.count
      topics = apply_sort(topics).offset(page * per).limit(per)

      render json: {
        total: total,
        page: page,
        per_page: per,
        topics: topics.map { |t| serialize_topic(t) },
      }
    end

    # GET /mapping/facets.json — options + count cho dropdown multi-select
    def facets
      base = Topic.visible.listable_topics.where(category_id: allowed_category_ids)

      district_filter = csv_param(:district)
      cascade = {}
      if district_filter.any?
        cascade_scope = filter_by_field(base, SitetorMapping::FIELD_DISTRICT, district_filter)
        cascade = {
          ward: facet_counts(cascade_scope, SitetorMapping::FIELD_WARD),
          street: facet_counts(cascade_scope, SitetorMapping::FIELD_STREET),
        }
      end

      render json: {
        type: facet_counts(base, SitetorMapping::FIELD_TYPE),
        position: facet_counts(base, SitetorMapping::FIELD_POSITION),
        direction: facet_counts(base, SitetorMapping::FIELD_DIRECTION),
        province: facet_counts(base, SitetorMapping::FIELD_PROVINCE),
        district: facet_counts(base, SitetorMapping::FIELD_DISTRICT),
        ward: cascade[:ward] || [],
        street: cascade[:street] || [],
      }
    end

    private

    def allowed_category_ids
      ids = SiteSetting.sitetor_mapping_categories.split("|").map(&:to_i)
      if params[:category_id].present? && ids.include?(params[:category_id].to_i)
        ids = [params[:category_id].to_i]
      end
      SitetorMapping.with_descendants(ids)
    end

    def csv_param(key)
      params[key].to_s.split(",").map(&:strip).reject(&:blank?)
    end

    def filter_by_field(scope, field, values)
      scope.joins(<<~SQL).where("mf_#{field}.value IN (?)", values)
        INNER JOIN topic_custom_fields mf_#{field}
          ON mf_#{field}.topic_id = topics.id
          AND mf_#{field}.name = '#{field}'
      SQL
    end

    def apply_multi_filters(scope)
      SitetorMapping::MULTI_FILTERS.each do |param, field|
        values = csv_param(param)
        scope = filter_by_field(scope, field, values) if values.any?
      end
      scope
    end

    def facet_counts(scope, field)
      TopicCustomField
        .where(name: field, topic_id: scope.select(:id))
        .group(:value)
        .order(Arel.sql("COUNT(*) DESC"))
        .limit(500)
        .count
        .map { |value, count| { value: value, count: count } }
    end

    def apply_range(scope, field, min_key, max_key)
      min = params[min_key]
      max = params[max_key]
      return scope if min.blank? && max.blank?

      scope = scope.joins(<<~SQL)
        INNER JOIN topic_custom_fields tcf_#{field}
          ON tcf_#{field}.topic_id = topics.id
          AND tcf_#{field}.name = '#{field}'
          AND tcf_#{field}.value ~ '^\\d+(\\.\\d+)?$'
      SQL
      scope = scope.where("CAST(tcf_#{field}.value AS numeric) >= ?", min.to_f) if min.present?
      scope = scope.where("CAST(tcf_#{field}.value AS numeric) <= ?", max.to_f) if max.present?
      scope
    end

    def apply_sort(scope)
      case SORTS[params[:sort].to_s]
      when :price_asc
        sort_by_field(scope, SitetorMapping::FIELD_PRICE, "ASC")
      when :price_desc
        sort_by_field(scope, SitetorMapping::FIELD_PRICE, "DESC")
      when :area_desc
        sort_by_field(scope, SitetorMapping::FIELD_AREA, "DESC")
      else
        scope.order(bumped_at: :desc)
      end
    end

    def sort_by_field(scope, field, dir)
      scope
        .joins(<<~SQL)
          LEFT JOIN topic_custom_fields sort_#{field}
            ON sort_#{field}.topic_id = topics.id
            AND sort_#{field}.name = '#{field}'
            AND sort_#{field}.value ~ '^\\d+(\\.\\d+)?$'
        SQL
        .order(Arel.sql("CAST(sort_#{field}.value AS numeric) #{dir} NULLS LAST, topics.bumped_at DESC"))
    end

    def serialize_topic(t)
      cf = t.custom_fields
      {
        id: t.id,
        title: t.title,
        slug: t.slug,
        category_id: t.category_id,
        created_at: t.created_at,
        bumped_at: t.bumped_at,
        tags: t.tags.pluck(:name),
        price: cf[SitetorMapping::FIELD_PRICE]&.to_i,
        frontage: cf[SitetorMapping::FIELD_FRONTAGE]&.to_f,
        area: cf[SitetorMapping::FIELD_AREA]&.to_f,
        type: cf[SitetorMapping::FIELD_TYPE],
        position: cf[SitetorMapping::FIELD_POSITION],
        direction: cf[SitetorMapping::FIELD_DIRECTION],
        street: cf[SitetorMapping::FIELD_STREET],
        ward: cf[SitetorMapping::FIELD_WARD],
        district: cf[SitetorMapping::FIELD_DISTRICT],
        province: cf[SitetorMapping::FIELD_PROVINCE],
      }
    end
  end
end
