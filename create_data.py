import csv
import random
from faker import Faker
from datetime import datetime, timedelta

fake = Faker('vi_VN')
random.seed(42)  # Để kết quả lặp lại (nếu muốn)

NUM_KHUVUC = 5
NUM_CHINHANH = 15
NUM_BOPHAN = 5
NUM_NHANVIEN = 300
NUM_LICHSULAMVIEC = 500
NUM_KHACHHANG = 100000
NUM_THETHANHVIEN = 40000
NUM_LICHSUTRUYCAP = 60000
NUM_MUCTHUCDON = 10
NUM_MONAN = 100
NUM_BAN_PER_BRANCH = 20
NUM_DATBAN = 55000
NUM_ORDERS = 150000
NUM_ORDER_ITEMS = 2000000
NUM_HOADON = NUM_ORDERS
NUM_DANHGIA = 27000

start_date_2023 = datetime(2023,1,1)
end_date_2023 = datetime(2023,12,31)
days_2023 = (end_date_2023 - start_date_2023).days + 1

########################################
# 1. KHUVUC
########################################
khuvucs = []
area_names = ["Hà Nội", "TP.HCM", "Đà Nẵng", "Hải Phòng", "Cần Thơ"]
for i in range(NUM_KHUVUC):
    TenKhuVuc = area_names[i % len(area_names)]
    khuvucs.append([i+1, TenKhuVuc])

with open('data/KHUVUC.csv','w',newline='',encoding='utf-8') as f:
    w = csv.writer(f)
    w.writerow(["MaKhuVuc","TenKhuVuc"])
    w.writerows(khuvucs)

########################################
# 2. CHINHANH
########################################
chinhanhs = []
for i in range(NUM_CHINHANH):
    MaKhuVuc = random.randint(1, NUM_KHUVUC)
    QuanLyChiNhanh = random.randint(1,NUM_NHANVIEN)  # Giả định nhân viên 1-300
    TenChiNhanh = f"SushiX {area_names[(MaKhuVuc-1)%len(area_names)]} {i+1}"
    DiaChi = fake.address().replace('\n',' ')
    ThoiGianMoCua = "09:00:00"
    ThoiGianDongCua = "22:00:00"
    SoDienThoai = fake.phone_number()
    CoBaiDoXeMay = random.randint(0,1)
    CoBaiDoOto = random.randint(0,1)
    chinhanhs.append([i+1, MaKhuVuc, QuanLyChiNhanh, TenChiNhanh, DiaChi, ThoiGianMoCua, ThoiGianDongCua, SoDienThoai, CoBaiDoXeMay, CoBaiDoOto])

with open('data/CHINHANH.csv','w',newline='',encoding='utf-8') as f:
    w = csv.writer(f)
    w.writerow(["MaChiNhanh","MaKhuVuc","QuanLyChiNhanh","TenChiNhanh","DiaChi","ThoiGianMoCua","ThoiGianDongCua","SoDienThoaiChiNhanh","CoBaiDoXeMay","CoBaiDoOto"])
    w.writerows(chinhanhs)

########################################
# 3. BOPHAN
########################################
bophan_names = ["Bếp", "Lễ tân", "Phục vụ bàn", "Thu ngân", "Quản lý"]
bophans = []
for i in range(NUM_BOPHAN):
    TenBoPhan = bophan_names[i % len(bophan_names)]
    # Giả sử lương mỗi bộ phận cố định:
    Luong = random.randint(5000000,15000000)
    bophans.append([i+1, TenBoPhan, Luong])

with open('data/BOPHAN.csv','w',newline='',encoding='utf-8') as f:
    w = csv.writer(f)
    w.writerow(["MaBoPhan","TenBoPhan","Luong"])
    w.writerows(bophans)

########################################
# 4. NHANVIEN
########################################
nhanviens = []
for i in range(NUM_NHANVIEN):
    HoTen = fake.name()
    NgaySinh = fake.date_of_birth(minimum_age=18, maximum_age=50).strftime("%Y-%m-%d")
    GioiTinh = random.choice(['Nam','Nữ','Khác'])
    MaBoPhan = random.randint(1,NUM_BOPHAN)
    MaChiNhanh = random.randint(1,NUM_CHINHANH)
    nhanviens.append([i+1, HoTen, NgaySinh, GioiTinh, MaBoPhan, MaChiNhanh])

with open('data/NHANVIEN.csv','w',newline='',encoding='utf-8') as f:
    w = csv.writer(f)
    w.writerow(["MaNhanVien","HoTen","NgaySinh","GioiTinh","MaBoPhan","MaChiNhanh"])
    w.writerows(nhanviens)

########################################
# 5. LICHSULAMVIEC
########################################
lichsulamviecs = []
for i in range(NUM_LICHSULAMVIEC):
    MaNhanVien = random.randint(1, NUM_NHANVIEN)
    MaChiNhanh = random.randint(1, NUM_CHINHANH)
    start_day_offset = random.randint(0, days_2023-30)
    NgayBatDau = start_date_2023 + timedelta(days=start_day_offset)
    # 50% chưa kết thúc
    if random.random()<0.5:
        NgayKetThuc = ""
    else:
        end_day_offset = start_day_offset + random.randint(1,30)
        if end_day_offset >= days_2023:
            NgayKetThuc = ""
        else:
            NgayKetThuc = (start_date_2023 + timedelta(days=end_day_offset)).strftime("%Y-%m-%d")

    lichsulamviecs.append([MaNhanVien, MaChiNhanh, NgayBatDau.strftime("%Y-%m-%d"), NgayKetThuc])

with open('data/LICHSULAMVIEC.csv','w',newline='',encoding='utf-8') as f:
    w = csv.writer(f)
    w.writerow(["MaNhanVien","MaChiNhanh","NgayBatDau","NgayKetThuc"])
    w.writerows(lichsulamviecs)

########################################
# 6. KHACHHANG
########################################
customers = []
genders = ['Nam','Nữ','Khác']
unique_cccd = set()
for i in range(NUM_KHACHHANG):
    HoTen = fake.name()
    SoDienThoai = fake.phone_number()
    Email = fake.email()
    # Đảm bảo CCCD unique:
    cccd = None
    while True:
        cccd_candidate = str(random.randint(10**11,10**12-1))
        if cccd_candidate not in unique_cccd:
            cccd = cccd_candidate
            unique_cccd.add(cccd)
            break
    GioiTinh = random.choice(genders)
    KhachOnline = random.randint(0,1)
    customers.append([i+1, HoTen, SoDienThoai, Email, cccd, GioiTinh, KhachOnline])

with open('data/KHACHHANG.csv','w',newline='',encoding='utf-8') as f:
    w = csv.writer(f)
    w.writerow(["MaKhachHang","HoTen","SoDienThoai","Email","SoCCCD","GioiTinh","KhachOnline"])
    w.writerows(customers)

########################################
# 7. THETHANHVIEN (40,000)
########################################
thethanhviens = []
for i in range(NUM_THETHANHVIEN):
    MaKhachHang = random.randint(1, NUM_KHACHHANG)
    NgayLap = (start_date_2023 + timedelta(days=random.randint(0,days_2023-1))).strftime("%Y-%m-%d")
    # Khi mới lập: Member
    LoaiThe = "Member"
    TinhTrangThe = "Active"
    DiemTichLuy = 0
    thethanhviens.append([i+1, MaKhachHang, NgayLap, LoaiThe, TinhTrangThe, DiemTichLuy])

with open('data/THETHANHVIEN.csv','w',newline='',encoding='utf-8') as f:
    w = csv.writer(f)
    w.writerow(["MaSoThe","MaKhachHang","NgayLap","LoaiThe","TinhTrangThe","DiemTichLuy"])
    w.writerows(thethanhviens)

########################################
# 8. LICHSUTRUYCAP (60,000)
########################################
# Ghi nhận truy cập của khách hàng
lichsutruycaps = []
for i in range(NUM_LICHSUTRUYCAP):
    MaKhachHang = random.randint(1, NUM_KHACHHANG)
    # ThoiDiemTruyCap random trong năm
    random_day = start_date_2023 + timedelta(days=random.randint(0,days_2023-1), 
                                             hours=random.randint(0,23),
                                             minutes=random.randint(0,59))
    ThoiGianTruyCap = random.randint(0,3600) # giây
    lichsutruycaps.append([MaKhachHang, random_day.strftime("%Y-%m-%d %H:%M:%S"), ThoiGianTruyCap])

with open('data/LICHSUTRUYCAP.csv','w',newline='',encoding='utf-8') as f:
    w = csv.writer(f)
    w.writerow(["MaKhachHang","ThoiDiemTruyCap","ThoiGianTruyCap"])
    w.writerows(lichsutruycaps)

########################################
# 9. MUCTHUCDON (10 mục)
########################################
muc_names = ["Khai vị","Sashimi","Nigiri","Tempura","Udon","Hotpot","Lunch set","Thức uống","Món chay","Tráng miệng"]
mucthucdons = []
for i in range(NUM_MUCTHUCDON):
    mucthucdons.append([i+1, muc_names[i]])

with open('data/MUCTHUCDON.csv','w',newline='',encoding='utf-8') as f:
    w = csv.writer(f)
    w.writerow(["MaMucThucDon","TenMucThucDon"])
    w.writerows(mucthucdons)

########################################
# 11. CHINHANH_MON
########################################
# Mỗi chi nhánh với mỗi món: CoPhucVu random
chinhanh_mons = []
for cn in range(1, NUM_CHINHANH+1):
    for mon in range(1, NUM_MONAN+1):
        CoPhucVu = random.randint(0,1)
        chinhanh_mons.append([cn, mon, CoPhucVu])

with open('data/CHINHANH_MON.csv','w',newline='',encoding='utf-8') as f:
    w = csv.writer(f)
    w.writerow(["MaChiNhanh","MaMon","CoPhucVu"])
    w.writerows(chinhanh_mons)

########################################
# 12. BAN
########################################
bans = []
for cn in range(1, NUM_CHINHANH+1):
    for sttban in range(1, NUM_BAN_PER_BRANCH+1):
        TrangThai = random.choice(["Trống","Đã đặt","Đang phục vụ"])
        bans.append([cn, sttban, TrangThai])

with open('data/BAN.csv','w',newline='',encoding='utf-8') as f:
    w = csv.writer(f)
    w.writerow(["MaChiNhanh","STTBan","TrangThai"])
    w.writerows(bans)

########################################
# 13. DATBAN (55,000)
########################################
datbans = []
for i in range(NUM_DATBAN):
    MaKhachHang = random.randint(1, NUM_KHACHHANG)
    MaChiNhanh = random.randint(1, NUM_CHINHANH)
    STTBan = random.randint(1, NUM_BAN_PER_BRANCH)
    day_offset = random.randint(0, days_2023-1)
    NgayDat = (start_date_2023 + timedelta(days=day_offset)).strftime("%Y-%m-%d")
    GioDen = (start_date_2023 + timedelta(days=day_offset, hours=random.randint(10,21), minutes=random.randint(0,59))).strftime("%Y-%m-%d %H:%M:%S")
    SoLuongKhach = random.randint(2,10)
    GhiChu = "Ghi chú..."
    datbans.append([i+1, MaKhachHang, MaChiNhanh, STTBan, NgayDat, GioDen, SoLuongKhach, GhiChu])

with open('data/DATBAN.csv','w',newline='',encoding='utf-8') as f:
    w = csv.writer(f)
    w.writerow(["MaDatBan","MaKhachHang","MaChiNhanh","STTBan","NgayDat","GioDen","SoLuongKhach","GhiChu"])
    w.writerows(datbans)

########################################
# 14. THONGTINPHIEUDATMON (Orders) - 150,000
########################################
orders = []
for i in range(NUM_ORDERS):
    NgayLap_dt = start_date_2023 + timedelta(days=random.randint(0,days_2023-1), hours=random.randint(10,21), minutes=random.randint(0,59))
    NgayLap = NgayLap_dt.strftime("%Y-%m-%d %H:%M:%S")
    MaChiNhanh = random.randint(1, NUM_CHINHANH)
    STTBan = random.randint(1,NUM_BAN_PER_BRANCH)
    MaNV = random.randint(1, NUM_NHANVIEN)
    # ~40% có khách hàng
    if random.random()<0.4:
        MaKH = random.randint(1, NUM_KHACHHANG)
    else:
        MaKH = ""
    orders.append([i+1, NgayLap, MaChiNhanh, STTBan, MaNV, MaKH])

with open('data/THONGTINPHIEUDATMON.csv','w',newline='',encoding='utf-8') as f:
    w = csv.writer(f)
    w.writerow(["MaPhieu","NgayLap","MaChiNhanh","STTBan","MaNV","MaKH"])
    w.writerows(orders)

########################################
# 15. CHITIETPHIEUDATMON (2,000,000 items)
########################################
# Mỗi đơn ~ 10-15 món
order_items = []
current_count = 0
for i in range(1, NUM_ORDERS+1):
    item_count = random.randint(10,15)
    for stt in range(1, item_count+1):
        if current_count >= NUM_ORDER_ITEMS:
            break
        MaMon = random.randint(1, NUM_MONAN)
        SoLuong = random.randint(1,5)
        order_items.append([i, stt, MaMon, SoLuong])
        current_count += 1
    if current_count >= NUM_ORDER_ITEMS:
        break

with open('data/CHITIETPHIEUDATMON.csv','w',newline='',encoding='utf-8') as f:
    w = csv.writer(f)
    w.writerow(["MaPhieu","STT","MaMon","SoLuong"])
    w.writerows(order_items)

########################################
# 16. HOADON (150,000)
########################################
# Tính tổng tiền và tiền giảm giá:
# Để tính tổng tiền, thông thường ta phải join MONAN. Ở đây, đơn giản: 
# Giả sử tính sau: GiaTien = random (chỉ minh họa)
hoadons = []
for i in range(1, NUM_HOADON+1):
    # Giả lập tổng tiền từ 500k - 2tr
    TongTien = random.randint(500000,2000000)
    # Giảm giá 10% nếu có MaKH từ orders
    MaPhieu = i
    # Tìm order:
    # (Ở đây để đơn giản, ta chỉ check xem có MaKH không)
    # Từ THONGTINPHIEUDATMON: MaKH ở cột thứ 5 (index 5)
    MaKH_str = orders[i-1][5]
    if MaKH_str != "":
        TienGiamGia = TongTien * 0.1
    else:
        TienGiamGia = 0
    NgayLap = orders[i-1][1]
    hoadons.append([i, NgayLap, TongTien, TienGiamGia, MaPhieu])

with open('data/HOADON.csv','w',newline='',encoding='utf-8') as f:
    w = csv.writer(f)
    w.writerow(["MaHoaDon","NgayLap","TongTien","TienGiamGia","MaPhieu"])
    w.writerows(hoadons)

########################################
# 17. DANHGIA (27,000 feedback)
########################################
# Chọn ngẫu nhiên 27,000 hóa đơn để đánh giá
danhgias = []
selected_invoices = random.sample(range(1, NUM_HOADON+1), NUM_DANHGIA)
positive_comments = ["Ngon, sẽ quay lại!", "Rất hài lòng!", "Dịch vụ tuyệt vời!", "Không gian đẹp!", "Giá cả hợp lý!"]
negative_comments = ["Không ngon!", "Dịch vụ kém!", "Không gian chật chội!", "Giá quá đắt!", "Không hài lòng!"]

for inv in selected_invoices:
    DiemPhucVu = random.randint(0, 10)
    DiemViTri = random.randint(0, 10)
    DiemChatLuongMonAn = random.randint(0, 10)
    DiemGiaCa = random.randint(0, 10)
    DiemKhongGian = random.randint(0, 10)
    
    avg_score = (DiemPhucVu + DiemViTri + DiemChatLuongMonAn + DiemGiaCa + DiemKhongGian) / 5
    if avg_score >= 6:
        BinhLuan = random.choice(positive_comments)
    else:
        BinhLuan = random.choice(negative_comments)
    
    danhgias.append([inv, DiemPhucVu, DiemViTri, DiemChatLuongMonAn, DiemGiaCa, DiemKhongGian, BinhLuan])

with open('data/DANHGIA.csv','w',newline='',encoding='utf-8') as f:
    w = csv.writer(f)
    w.writerow(["MaHoaDon","DiemPhucVu","DiemViTri","DiemChatLuongMonAn","DiemGiaCa","DiemKhongGian","BinhLuan"])
    w.writerows(danhgias)


print("Tạo dữ liệu giả thành công!")
