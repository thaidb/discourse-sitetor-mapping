# frozen_string_literal: true

module SitetorMapping
  class FilterController < ::ApplicationController
    requires_plugin SitetorMapping::PLUGIN_NAME

    SORTS = {
      "new" => "topics.bumped_at DESC",
      "price_asc" => :gia_asc,
      "price_desc" => :gia_desc,
      "area_desc" => :dt_desc,
    }.freeze

    # GET /mapping/filter.json — lọc topic NHU CẦU (Cần mua/Cần thuê).
    # Params: q | gia_min, gia_max (VND — ngân sách) | mt_min, mt_max | dt_min, dt_max
    #         | loai,quan,phuong,duong,vi_tri,huong,tinh (CSV) | category_id | sort | page
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

      topics = apply_range(topics, SitetorMapping::FIELD_GIA, :gia_min, :gia_max)
      topics = apply_range(topics, SitetorMapping::FIELD_MAT_TIEN, :mt_min, :mt_max)
      topics = apply_range(topics, SitetorMapping::FIELD_DIEN_TICH, :dt_min, :dt_max)
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

      quan_filter = csv_param(:quan)
      cascade = {}
      if quan_filter.any?
        cascade_scope = filter_by_field(base, SitetorMapping::FIELD_QUAN, quan_filter)
        cascade = {
          phuong: facet_counts(cascade_scope, SitetorMapping::FIELD_PHUONG),
          duong: facet_counts(cascade_scope, SitetorMapping::FIELD_DUONG),
        }
      end

      render json: {
        loai: facet_counts(base, SitetorMapping::FIELD_LOAI),
        vi_tri: facet_counts(base, SitetorMapping::FIELD_VI_TRI),
        huong: facet_counts(base, SitetorMapping::FIELD_HUONG),
        tinh: facet_counts(base, SitetorMapping::FIELD_TINH),
        quan: facet_counts(base, SitetorMapping::FIELD_QUAN),
        phuong: cascade[:phuong] || [],
        duong: cascade[:duong] || [],
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
      when :gia_asc
        sort_by_field(scope, SitetorMapping::FIELD_GIA, "ASC")
      when :gia_desc
        sort_by_field(scope, SitetorMapping::FIELD_GIA, "DESC")
      when :dt_desc
        sort_by_field(scope, SitetorMapping::FIELD_DIEN_TICH, "DESC")
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
        gia: cf[SitetorMapping::FIELD_GIA]&.to_i,
        mat_tien: cf[SitetorMapping::FIELD_MAT_TIEN]&.to_f,
        dien_tich: cf[SitetorMapping::FIELD_DIEN_TICH]&.to_f,
        loai: cf[SitetorMapping::FIELD_LOAI],
        vi_tri: cf[SitetorMapping::FIELD_VI_TRI],
        huong: cf[SitetorMapping::FIELD_HUONG],
        duong: cf[SitetorMapping::FIELD_DUONG],
        phuong: cf[SitetorMapping::FIELD_PHUONG],
        quan: cf[SitetorMapping::FIELD_QUAN],
        tinh: cf[SitetorMapping::FIELD_TINH],
      }
    end
  end
end
