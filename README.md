# discourse-sitetor-mapping (Sitetor Mapping Filter)

Trang **`/mapping`** — bộ lọc **NHU CẦU mua/thuê BĐS** (nửa **Cầu** của thị trường,
đối xứng với `/listing` là nửa **Cung**) cho lms.sitetor.com.

> Tư duy thiết kế: mỗi category giống một group Zalo, nhưng có topic + workflow.
> Mỗi mục đích có một plugin gắn **bộ lọc chuyên dụng** lên nhóm category đó:
> `/listing` lọc tin Bán/Cho thuê, `/mapping` lọc tin Cần mua/Cần thuê.

## Tính năng

- Lọc nhu cầu trong category **Cần mua (3698)** + **Cần thuê (3344)**: từ khóa,
  loại tin, loại sản phẩm, tỉnh/quận/phường/đường (multi-select cascade),
  vị trí, hướng, **ngân sách từ–đến (triệu/tỷ/USD)**, diện tích, mặt tiền, sắp xếp.
- Bảng kết quả: ID, Loại tin, Nhu cầu, Loại SP, Quận/Huyện, Đường, Ngân sách, DT
  + nút **"Giới thiệu ngay"** từng dòng.
- **Giới thiệu ngay**: chủ listing chọn 1 tin trong tài khoản (Bán/Cho thuê) →
  tự tạo reply gắn link listing (onebox) vào topic nhu cầu — kết nối Cung ↔ Cầu.
- Phân trang nhảy bước `1,2,3,4,5…10,15,20…100,200…n`; link sidebar "Nhu cầu mua/thuê".

## Phụ thuộc

**Yêu cầu cài kèm [discourse-sitetor-filter](https://github.com/thaidb/discourse-sitetor-filter)** —
plugin đó parse & backfill custom fields (`bds_gia`, `bds_quan`, `bds_duong`…) mà
plugin này đọc. Sau khi cài cả hai, chạy lại `rake sitetor_filter:backfill` để
quét luôn 2 category nhu cầu.

## Cài đặt

Thêm vào `app.yml` (cạnh dòng clone sitetor-filter):

```yaml
          - git clone https://github.com/thaidb/discourse-sitetor-filter.git
          - git clone https://github.com/thaidb/discourse-sitetor-mapping.git
```

```bash
cd /var/discourse && ./launcher rebuild app
./launcher enter app && rake sitetor_filter:backfill && exit
```

Mở `https://lms.sitetor.com/mapping`.

## Ghi chú

- `/launch` (discourse-docs) vẫn hoạt động bình thường — plugin này không đụng
  vào docs, chỉ thêm trang `/mapping` riêng với filter chuyên dụng.
- Đơn vị ngân sách USD quy đổi theo setting `sitetor_mapping_usd_rate`.
