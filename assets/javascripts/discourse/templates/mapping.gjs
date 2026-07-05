import { Input } from "@ember/component";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import DButton from "discourse/components/d-button";
import { i18n } from "discourse-i18n";
import MultiSelect from "discourse/plugins/discourse-sitetor-mapping/discourse/components/multi-select";

// 25000000 → "25 tr" ; 5500000000 → "5,5 tỷ"
function formatPrice(vnd) {
  if (!vnd) {
    return "—";
  }
  const n = Number(vnd);
  if (n >= 1e9) {
    return `${(n / 1e9).toLocaleString("vi-VN", { maximumFractionDigits: 2 })} tỷ`;
  }
  return `${(n / 1e6).toLocaleString("vi-VN", { maximumFractionDigits: 1 })} tr`;
}

function orDash(v) {
  return v ?? "—";
}

function eq(a, b) {
  return a === b;
}

export default <template>
  <div class="sitetor-mapping">
    {{! tiêu đề là link reset về /mapping gốc }}
    <h1><a href="/mapping" class="mapping-home-link">{{i18n "sitetor_mapping.title"}}</a></h1>

    {{! layout 2 cột: sidebar filter dọc bên trái (kiểu /launch) + kết quả bên phải }}
    <div class="mapping-layout">
      <aside class="mapping-sidebar">
        <div class="mapping-filter-group mapping-filter-q">
          <Input
            @value={{@controller.fQ}}
            placeholder={{i18n "sitetor_mapping.search_hint"}}
            {{on "keydown" @controller.onQKeydown}}
          />
        </div>

        <div class="mapping-filter-group">
          <label>{{i18n "sitetor_mapping.category"}}</label>
          <select {{on "change" (fn @controller.updateField "fCategoryId")}}>
            <option value="" selected={{eq @controller.fCategoryId ""}}>
              {{i18n "sitetor_mapping.all"}}
            </option>
            {{#each @controller.categoryOptions as |c|}}
              <option value={{c.id}} selected={{eq @controller.fCategoryId c.id}}>{{c.name}}</option>
            {{/each}}
          </select>
        </div>

        <MultiSelect
          @label={{i18n "sitetor_mapping.product_type"}}
          @options={{@controller.facets.type}}
          @selected={{@controller.sTypes}}
          @onChange={{fn @controller.setSelection "sTypes"}}
        />
        <MultiSelect
          @label={{i18n "sitetor_mapping.province"}}
          @options={{@controller.facets.province}}
          @selected={{@controller.sProvinces}}
          @onChange={{fn @controller.setSelection "sProvinces"}}
        />
        <MultiSelect
          @label={{i18n "sitetor_mapping.district"}}
          @options={{@controller.facets.district}}
          @selected={{@controller.sDistricts}}
          @onChange={{fn @controller.setSelection "sDistricts"}}
          @searchable={{true}}
        />
        <MultiSelect
          @label={{i18n "sitetor_mapping.ward"}}
          @options={{@controller.facets.ward}}
          @selected={{@controller.sWards}}
          @onChange={{fn @controller.setSelection "sWards"}}
          @searchable={{true}}
        />
        <MultiSelect
          @label={{i18n "sitetor_mapping.street"}}
          @options={{@controller.facets.street}}
          @selected={{@controller.sStreets}}
          @onChange={{fn @controller.setSelection "sStreets"}}
          @searchable={{true}}
        />
        <MultiSelect
          @label={{i18n "sitetor_mapping.position"}}
          @options={{@controller.facets.position}}
          @selected={{@controller.sPositions}}
          @onChange={{fn @controller.setSelection "sPositions"}}
        />
        <MultiSelect
          @label={{i18n "sitetor_mapping.direction"}}
          @options={{@controller.facets.direction}}
          @selected={{@controller.sDirections}}
          @onChange={{fn @controller.setSelection "sDirections"}}
        />

        <div class="mapping-filter-group">
          <label>{{i18n "sitetor_mapping.budget"}}</label>
          <div class="mapping-range">
            <Input @value={{@controller.fPriceMin}} @type="number" placeholder={{i18n "sitetor_mapping.from"}} />
            <span>–</span>
            <Input @value={{@controller.fPriceMax}} @type="number" placeholder={{i18n "sitetor_mapping.to"}} />
          </div>
          <select {{on "change" (fn @controller.updateField "fPriceUnit")}}>
            <option value="million" selected={{eq @controller.fPriceUnit "million"}}>{{i18n "sitetor_mapping.million"}}</option>
            <option value="billion" selected={{eq @controller.fPriceUnit "billion"}}>{{i18n "sitetor_mapping.billion"}}</option>
            <option value="usd" selected={{eq @controller.fPriceUnit "usd"}}>USD</option>
          </select>
        </div>

        <div class="mapping-filter-group">
          <label>{{i18n "sitetor_mapping.frontage"}} (m)</label>
          <div class="mapping-range">
            <Input @value={{@controller.fFrontageMin}} @type="number" placeholder="min" />
            <span>–</span>
            <Input @value={{@controller.fFrontageMax}} @type="number" placeholder="max" />
          </div>
        </div>

        <div class="mapping-filter-group">
          <label>{{i18n "sitetor_mapping.area"}} (m²)</label>
          <div class="mapping-range">
            <Input @value={{@controller.fAreaMin}} @type="number" placeholder="min" />
            <span>–</span>
            <Input @value={{@controller.fAreaMax}} @type="number" placeholder="max" />
          </div>
        </div>

        <div class="mapping-filter-group">
          <label>{{i18n "sitetor_mapping.sort_by"}}</label>
          <select {{on "change" (fn @controller.updateField "fSort")}}>
            <option value="new" selected={{eq @controller.fSort "new"}}>{{i18n "sitetor_mapping.newest"}}</option>
            <option value="price_asc" selected={{eq @controller.fSort "price_asc"}}>{{i18n "sitetor_mapping.price_asc"}}</option>
            <option value="price_desc" selected={{eq @controller.fSort "price_desc"}}>{{i18n "sitetor_mapping.price_desc"}}</option>
            <option value="area_desc" selected={{eq @controller.fSort "area_desc"}}>{{i18n "sitetor_mapping.area_desc"}}</option>
          </select>
        </div>

        <div class="mapping-actions">
          <DButton
            @action={{@controller.applyFilter}}
            @icon="magnifying-glass"
            @label="sitetor_mapping.apply_filter"
            class="btn-primary"
          />
          <DButton @action={{@controller.resetFilter}} @label="sitetor_mapping.reset_filter" />
        </div>
      </aside>

      <div class="mapping-content">
        <p class="mapping-total">
          {{i18n "sitetor_mapping.total_found" count=@controller.total}}
          · {{i18n "sitetor_mapping.page_of" page=@controller.currentPage total=@controller.totalPages}}
        </p>

        <div class="mapping-table-wrap">
          <table class="mapping-table">
            <thead>
              <tr>
                <th>ID</th>
                <th>{{i18n "sitetor_mapping.category"}}</th>
                <th>{{i18n "sitetor_mapping.demand"}}</th>
                <th>{{i18n "sitetor_mapping.product_type"}}</th>
                <th>{{i18n "sitetor_mapping.district"}}</th>
                <th>{{i18n "sitetor_mapping.street"}}</th>
                <th>{{i18n "sitetor_mapping.budget"}}</th>
                <th>{{i18n "sitetor_mapping.area"}}</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {{#each @controller.topics as |t|}}
                <tr>
                  <td class="mapping-num">
                    <a href="/t/{{t.slug}}/{{t.id}}" title={{t.title}}>{{t.id}}</a>
                  </td>
                  <td>{{@controller.categoryName t.category_id}}</td>
                  <td class="mapping-title">
                    <a href="/t/{{t.slug}}/{{t.id}}">{{t.title}}</a>
                  </td>
                  <td>{{orDash t.type}}</td>
                  <td>{{orDash t.district}}</td>
                  <td>{{orDash t.street}}</td>
                  <td class="mapping-num">{{formatPrice t.price}}</td>
                  <td class="mapping-num">{{orDash t.area}}</td>
                  <td>
                    <DButton
                      @action={{fn @controller.openRecommend t}}
                      @label="sitetor_mapping.recommend_now"
                      class="btn-primary btn-small mapping-recommend-btn"
                    />
                  </td>
                </tr>
              {{else}}
                <tr><td colspan="9">{{i18n "sitetor_mapping.no_results"}}</td></tr>
              {{/each}}
            </tbody>
          </table>
        </div>

        {{! phân trang nhảy bước: 1,2,3,4,5 ... 10,15,20 ... 100,200 ... n }}
        <div class="mapping-paging">
          <DButton
            @action={{@controller.prevPage}}
            @disabled={{unless @controller.hasPrev true}}
            @label="sitetor_mapping.prev"
          />
          <span class="mapping-page-list">
            {{#each @controller.pageList as |p|}}
              {{#if p.current}}
                <span class="mapping-page mapping-page-current">{{p.num}}</span>
              {{else}}
                <button
                  type="button"
                  class="mapping-page"
                  {{on "click" (fn @controller.goPage p.num)}}
                >{{p.num}}</button>
              {{/if}}
            {{/each}}
          </span>
          <DButton
            @action={{@controller.nextPage}}
            @disabled={{unless @controller.hasNext true}}
            @label="sitetor_mapping.next"
          />
          <span class="mapping-goto">
            {{i18n "sitetor_mapping.go_to_page"}}
            <Input
              @value={{@controller.fGotoPage}}
              @type="number"
              min="1"
              {{on "input" @controller.updateGotoPage}}
            />
            <DButton @action={{@controller.gotoPage}} @label="sitetor_mapping.go" class="btn-small" />
          </span>
        </div>
      </div>
    </div>
  </div>
</template>
