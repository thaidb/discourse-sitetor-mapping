import { Input } from "@ember/component";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import DButton from "discourse/components/d-button";
import { i18n } from "discourse-i18n";
import BdsMultiSelect from "discourse/plugins/discourse-sitetor-mapping/discourse/components/bds-multi-select";

// 25000000 → "25 tr" ; 5500000000 → "5,5 tỷ"
function formatGia(vnd) {
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
    <h1><a href="/mapping" class="bds-home-link">{{i18n "sitetor_mapping.title"}}</a></h1>

    <div class="bds-filters">
      <div class="bds-filter-row">
        <div class="bds-filter-group bds-filter-q">
          <Input
            @value={{@controller.fQ}}
            placeholder={{i18n "sitetor_mapping.tu_khoa"}}
            {{on "keydown" @controller.onQKeydown}}
          />
        </div>

        <div class="bds-filter-group">
          <label>{{i18n "sitetor_mapping.loai_tin"}}</label>
          <select {{on "change" (fn @controller.updateField "fCategoryId")}}>
            <option value="" selected={{eq @controller.fCategoryId ""}}>
              {{i18n "sitetor_mapping.tat_ca"}}
            </option>
            {{#each @controller.categoryOptions as |c|}}
              <option value={{c.id}} selected={{eq @controller.fCategoryId c.id}}>{{c.name}}</option>
            {{/each}}
          </select>
        </div>

        <BdsMultiSelect
          @label={{i18n "sitetor_mapping.loai_san_pham"}}
          @options={{@controller.facets.loai}}
          @selected={{@controller.sLoai}}
          @onChange={{fn @controller.setSelection "sLoai"}}
        />
        <BdsMultiSelect
          @label={{i18n "sitetor_mapping.tinh_thanh"}}
          @options={{@controller.facets.tinh}}
          @selected={{@controller.sTinh}}
          @onChange={{fn @controller.setSelection "sTinh"}}
        />
        <BdsMultiSelect
          @label={{i18n "sitetor_mapping.quan_huyen"}}
          @options={{@controller.facets.quan}}
          @selected={{@controller.sQuan}}
          @onChange={{fn @controller.setSelection "sQuan"}}
          @searchable={{true}}
        />
        <BdsMultiSelect
          @label={{i18n "sitetor_mapping.phuong_xa"}}
          @options={{@controller.facets.phuong}}
          @selected={{@controller.sPhuong}}
          @onChange={{fn @controller.setSelection "sPhuong"}}
          @searchable={{true}}
        />
        <BdsMultiSelect
          @label={{i18n "sitetor_mapping.duong_pho"}}
          @options={{@controller.facets.duong}}
          @selected={{@controller.sDuong}}
          @onChange={{fn @controller.setSelection "sDuong"}}
          @searchable={{true}}
        />
        <BdsMultiSelect
          @label={{i18n "sitetor_mapping.vi_tri"}}
          @options={{@controller.facets.vi_tri}}
          @selected={{@controller.sViTri}}
          @onChange={{fn @controller.setSelection "sViTri"}}
        />
        <BdsMultiSelect
          @label={{i18n "sitetor_mapping.huong"}}
          @options={{@controller.facets.huong}}
          @selected={{@controller.sHuong}}
          @onChange={{fn @controller.setSelection "sHuong"}}
        />
      </div>

      <div class="bds-filter-row">
        <div class="bds-filter-group">
          <label>{{i18n "sitetor_mapping.ngan_sach"}}</label>
          <Input @value={{@controller.fGiaMin}} @type="number" placeholder={{i18n "sitetor_mapping.tu"}} />
          <span>–</span>
          <Input @value={{@controller.fGiaMax}} @type="number" placeholder={{i18n "sitetor_mapping.den"}} />
          <select {{on "change" (fn @controller.updateField "fGiaUnit")}}>
            <option value="trieu" selected={{eq @controller.fGiaUnit "trieu"}}>{{i18n "sitetor_mapping.trieu"}}</option>
            <option value="ty" selected={{eq @controller.fGiaUnit "ty"}}>{{i18n "sitetor_mapping.ty"}}</option>
            <option value="usd" selected={{eq @controller.fGiaUnit "usd"}}>USD</option>
          </select>
        </div>

        <div class="bds-filter-group">
          <label>{{i18n "sitetor_mapping.mat_tien"}} (m)</label>
          <Input @value={{@controller.fMtMin}} @type="number" placeholder="min" />
          <span>–</span>
          <Input @value={{@controller.fMtMax}} @type="number" placeholder="max" />
        </div>

        <div class="bds-filter-group">
          <label>{{i18n "sitetor_mapping.dien_tich"}} (m²)</label>
          <Input @value={{@controller.fDtMin}} @type="number" placeholder="min" />
          <span>–</span>
          <Input @value={{@controller.fDtMax}} @type="number" placeholder="max" />
        </div>

        <div class="bds-filter-group">
          <label>{{i18n "sitetor_mapping.sap_xep"}}</label>
          <select {{on "change" (fn @controller.updateField "fSort")}}>
            <option value="new" selected={{eq @controller.fSort "new"}}>{{i18n "sitetor_mapping.moi_nhat"}}</option>
            <option value="price_asc" selected={{eq @controller.fSort "price_asc"}}>{{i18n "sitetor_mapping.gia_tang"}}</option>
            <option value="price_desc" selected={{eq @controller.fSort "price_desc"}}>{{i18n "sitetor_mapping.gia_giam"}}</option>
            <option value="area_desc" selected={{eq @controller.fSort "area_desc"}}>{{i18n "sitetor_mapping.dt_lon"}}</option>
          </select>
        </div>

        <DButton
          @action={{@controller.applyFilter}}
          @icon="magnifying-glass"
          @label="sitetor_mapping.loc"
          class="btn-primary"
        />
        <DButton @action={{@controller.resetFilter}} @label="sitetor_mapping.xoa_loc" />
      </div>
    </div>

    <p class="bds-total">
      {{i18n "sitetor_mapping.tong" count=@controller.total}}
      · {{i18n "sitetor_mapping.trang_x_tren_y" page=@controller.currentPage total=@controller.totalPages}}
    </p>

    <div class="bds-table-wrap">
      <table class="bds-table">
        <thead>
          <tr>
            <th>ID</th>
            <th>{{i18n "sitetor_mapping.loai_tin"}}</th>
            <th>{{i18n "sitetor_mapping.nhu_cau"}}</th>
            <th>{{i18n "sitetor_mapping.loai_san_pham"}}</th>
            <th>{{i18n "sitetor_mapping.quan_huyen"}}</th>
            <th>{{i18n "sitetor_mapping.duong_pho"}}</th>
            <th>{{i18n "sitetor_mapping.ngan_sach"}}</th>
            <th>{{i18n "sitetor_mapping.dien_tich"}}</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          {{#each @controller.topics as |t|}}
            <tr>
              <td class="bds-num">
                <a href="/t/{{t.slug}}/{{t.id}}" title={{t.title}}>{{t.id}}</a>
              </td>
              <td>{{@controller.categoryName t.category_id}}</td>
              <td class="bds-title">
                <a href="/t/{{t.slug}}/{{t.id}}">{{t.title}}</a>
              </td>
              <td>{{orDash t.loai}}</td>
              <td>{{orDash t.quan}}</td>
              <td>{{orDash t.duong}}</td>
              <td class="bds-num">{{formatGia t.gia}}</td>
              <td class="bds-num">{{orDash t.dien_tich}}</td>
              <td>
                <DButton
                  @action={{fn @controller.openGioiThieu t}}
                  @label="sitetor_mapping.gioi_thieu_ngay"
                  class="btn-primary btn-small bds-gioi-thieu-btn"
                />
              </td>
            </tr>
          {{else}}
            <tr><td colspan="9">{{i18n "sitetor_mapping.khong_co"}}</td></tr>
          {{/each}}
        </tbody>
      </table>
    </div>

    {{! phân trang nhảy bước: 1,2,3,4,5 ... 10,15,20 ... 100,200 ... n }}
    <div class="bds-paging">
      <DButton
        @action={{@controller.prevPage}}
        @disabled={{unless @controller.hasPrev true}}
        @label="sitetor_mapping.truoc"
      />
      <span class="bds-page-list">
        {{#each @controller.pageList as |p|}}
          {{#if p.current}}
            <span class="bds-page bds-page-current">{{p.num}}</span>
          {{else}}
            <button
              type="button"
              class="bds-page"
              {{on "click" (fn @controller.goPage p.num)}}
            >{{p.num}}</button>
          {{/if}}
        {{/each}}
      </span>
      <DButton
        @action={{@controller.nextPage}}
        @disabled={{unless @controller.hasNext true}}
        @label="sitetor_mapping.sau"
      />
    </div>
  </div>
</template>
