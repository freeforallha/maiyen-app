const Map<String, String> filStrings = {
  "Không tìm thấy người dùng": "Hindi natagpuan ang user",
  "Không đọc được số điện thoại": "Hindi mabasa ang numero ng telepono",
  "Tin nhắn quá dài": "Masyadong mahaba ang mensahe",
  "Không gửi được tin nhắn": "Hindi maipadala ang mensahe",
  "Bạn không có quyền sửa lịch chung của nhà":
      "Wala kang pahintulot na baguhin ang ibinahaging iskedyul ng bahay",
  "Nhà của bạn": "Ang iyong bahay",
  "Tải tin cũ hơn": "Mag-load ng mas lumang mga mensahe",
  "Nhà chưa đặt tên": "Bahay na walang pangalan",
  "Nhà": "Bahay",
  "Chưa có thông tin": "Wala pang impormasyon",
  "Chưa cập nhật": "Hindi pa na-update",
  "Chủ nhà": "May-ari",
  "Nhà được chia sẻ": "Ibinahaging bahay",
  "Địa chỉ": "Address",
  "An ninh ra/vào": "Seguridad sa pasukan",
  "Nguy hiểm khẩn cấp": "Mga agarang panganib",
  "Điều khiển & hạ tầng": "Kontrol at imprastraktura",
  "Môi trường": "Kapaligiran",
  "Toàn bộ thiết bị SafeHome": "Lahat ng aparato ng SafeHome",
  "Cửa ra/vào": "Pinto sa pasukan",
  "Cửa": "Pinto",
  "Cửa sổ": "Bintana",
  "Cổng": "Tarangkahan",
  "Khóa thông minh": "Smart lock",
  "Chuyển động": "Galaw",
  "Hiện diện": "Presensya",
  "Rung/chấn động": "Panginginig",
  "Kính vỡ": "Pagkabasag ng salamin",
  "Báo khói": "Alarm sa usok",
  "Báo nhiệt": "Alarm sa init",
  "Khí CO": "Carbon monoxide",
  "Báo gas": "Alarm sa gas",
  "Báo ngập/rò nước": "Alarm sa tagas ng tubig",
  "Nút SOS": "Pindutan ng SOS",
  "Nhiệt độ/Độ ẩm": "Temperatura/Halumigmig",
  "Bụi mịn PM2.5": "Pinong alikabok na PM2.5",
  "CO₂": "CO₂",
  "Chất lượng không khí": "Kalidad ng hangin",
  "Ổ điện thông minh": "Smart plug",
  "Còi báo động": "Sirena",
  "Van thông minh": "Smart valve",
  "Camera": "Camera",
  "Chuông cửa": "Kampanilya ng pinto",
  "Bàn phím an ninh": "Keypad ng seguridad",
  "Bộ mở rộng sóng": "Repeater",
  "Hub trung tâm": "Pangunahing Hub",
  "Đo điện năng": "Monitor ng konsumo ng kuryente",
  "Nguồn dự phòng UPS": "Backup na kuryente mula sa UPS",
  "Thiết bị đang Offline": "Nakadiskonekta ang aparato",
  "Thiết bị đang Online": "Nakakonekta ang aparato",
  "lâu không phản hồi": "Matagal nang hindi tumutugon",
  "Kết nối cần kiểm tra": "Kailangang suriin ang koneksyon",
  "Vừa xong": "Ngayon lang",
  "Bị tháo": "Natukoy ang pakikialam",
  "Có khói": "Natukoy ang usok",
  "Bình thường": "Normal",
  "Bảo vệ": "Proteksyon",
  "Chế độ Bảo vệ": "Mode ng Proteksyon",
  "Tự động Bảo vệ khi rời nhà": "Awtomatikong Proteksyon kapag wala sa bahay",
  "Đã kích hoạt": "Na-activate",
  "Sẵn sàng": "Handa",
  "Đang đóng": "Sarado",
  "Đang mở": "Bukas",
  "Rò rỉ gas": "Natukoy ang tagas ng gas",
  "Phát hiện ngập nước": "Natukoy ang tagas ng tubig",
  "Phát hiện chuyển động": "Natukoy ang galaw",
  "Không có chuyển động": "Walang natukoy na galaw",
  "Phát hiện hiện diện": "Natukoy ang presensya",
  "Không phát hiện hiện diện": "Walang natukoy na presensya",
  "Phát hiện rung/chấn động": "Natukoy ang panginginig",
  "Không có rung bất thường": "Walang kakaibang panginginig",
  "Phát hiện kính vỡ": "Natukoy ang pagkabasag ng salamin",
  "Không có cảnh báo kính vỡ": "Walang alerto sa pagkabasag ng salamin",
  "Nhiệt độ nguy hiểm": "Natukoy ang mapanganib na init",
  "Phát hiện khí CO": "Natukoy ang carbon monoxide",
  "Không phát hiện khí CO": "Walang natukoy na carbon monoxide",
  "Khóa đang mở": "Naka-unlock",
  "Khóa đang đóng": "Naka-lock",
  "Đang bật": "Naka-on",
  "Đang tắt": "Naka-off",
  "Đang theo dõi điện năng": "Sinusubaybayan ang konsumo ng kuryente",
  "Đang dùng nguồn dự phòng": "Gumagamit ng backup na kuryente",
  "Nguồn điện bình thường": "Normal ang pangunahing kuryente",
  "Còi đang bật": "Aktibo ang sirena",
  "Còi sẵn sàng": "Handa ang sirena",
  "Van đang mở": "Bukas ang balbula",
  "Van đã đóng": "Sarado ang balbula",
  "Đang hoạt động": "Gumagana",
  "Đang theo dõi": "Sinusubaybayan",
  "Chưa nhận diện": "Hindi nakikilalang aparato",
  "Chưa có cập nhật": "Wala pang update",
  "Chưa có thiết bị, hãy nhấn nút + để thêm để bắt đầu duy trì an ninh":
      "Wala pang aparato. I-tap ang + para magdagdag at simulang protektahan ang iyong bahay.",
  "CHƯA AN TOÀN": "HINDI LIGTAS",
  "ĐÃ AN TOÀN": "LIGTAS",
  "Nhà đang có dấu hiệu cần kiểm tra, bạn nên xem lại các trạng thái bên dưới.":
      "Kailangang suriin ang iyong bahay. Tingnan ang mga status sa ibaba.",
  "Nhà đang hoạt động ổn định, bạn có thể yên tâm.":
      "Normal ang pagpapatakbo ng iyong bahay.",
  "Không có dấu hiệu khói hoặc SOS bất thường.":
      "Walang natukoy na usok o anumang SOS alert.",
  "Chưa có nhiều hoạt động mới để phân tích sâu hơn.":
      "Hindi pa sapat ang datos ng kamakailang aktibidad para sa mas malalim na pagsusuri.",
  "Hub kết nối bình thường": "Nakakonekta ang Hub",
  "Cài đặt cảnh báo cho nhà hiện tại":
      "Mga setting ng alerto para sa bahay na ito",
  "Nhận cảnh báo Alarm": "Tumanggap ng mga alerto ng Alarm",
  "Đang bật cho tài khoản này": "Naka-enable para sa account na ito",
  "Đang tắt cho tài khoản này": "Naka-disable para sa account na ito",
  "Hẹn giờ Reminder": "Iskedyul ng Reminder",
  "Nhắc kiểm tra nhà theo thời gian":
      "Magtakda ng mga Reminder para suriin ang bahay",
  "Hẹn giờ Alarm": "Iskedyul ng Alarm",
  "Chưa thiết lập": "Hindi pa nakatakda",
  "Chưa thiết lập thời gian": "Walang nakatakdang iskedyul",
  "Tổng hợp trạng thái nhà": "Buod ng status ng bahay",
  "Cần xử lý ngay": "Kailangang aksyunan",
  "Đánh giá tự động": "Awtomatikong pagtatasa",
  "Tự động đánh giá": "Awtomatikong pagtatasa",
  "Tổng quan hôm nay": "Pangkalahatang-ideya ngayong araw",
  "Chưa có dữ liệu tổng quan": "Wala pang datos para sa pangkalahatang-ideya",
  "Chưa có dữ liệu trạng thái": "Wala pang datos ng status",
  "Chưa đủ dữ liệu để đánh giá": "Hindi sapat ang datos para sa pagtatasa",
  "Chưa có dữ liệu để đánh giá": "Hindi sapat ang datos para sa pagtatasa",
  "Bấm vào để xem chi tiết": "I-tap para tingnan ang mga detalye",
  "Nhấn để xem chi tiết...": "I-tap para tingnan ang mga detalye...",
  "Tạm dừng": "Naka-pause",
  "Tắt": "Naka-off",
  "Chi tiết": "Mga detalye",
  "Tổng hợp trạng thái": "Buod ng status",
  "Không an toàn": "Hindi ligtas",
  "Cần chú ý": "Kailangang bigyang-pansin",
  "An toàn": "Ligtas",
  "Không có": "Wala",
  "Đổi tên nhóm": "Palitan ang pangalan ng grupo",
  "Huỷ": "Kanselahin",
  "Lưu": "I-save",
  "Thêm": "Idagdag",
  "Xoá": "Tanggalin",
  "Đổi tên": "Palitan ang pangalan",
  "Nhà của tôi": "Mga bahay ko",
  "Bỏ chọn toàn bộ nhóm": "Alisin sa pagkakapili ang buong grupo",
  "Chọn toàn bộ nhóm": "Piliin ang buong grupo",
  "Bỏ chọn": "Alisin sa pagkakapili",
  "Quay lại": "Bumalik",
  "Tìm kiếm": "Maghanap",
  "Đóng tìm kiếm": "Isara ang paghahanap",
  "Giờ": "Oras",
  "Phút": "Minuto",
  "Đặt Home Reminder": "Itakda ang Reminder ng bahay",
  "Đặt Home Alarm": "Itakda ang Alarm ng bahay",
  "Xác nhận thay đổi": "Kumpirmahin ang mga pagbabago",
  "Tiếp tục": "Magpatuloy",
  "Giờ Reminder": "Oras ng Reminder",
  "Giờ bắt đầu Alarm": "Oras ng pagsisimula ng Alarm",
  "Giờ kết thúc Alarm": "Oras ng pagtatapos ng Alarm",
  "Không có nhà nào đủ điều kiện để cài": "Walang nakitang kwalipikadong bahay",
  "Cài đặt hoàn tất": "Kumpleto na ang pag-setup",
  "Xác nhận rời nhà": "Kumpirmahin ang pag-alis sa bahay",
  "Xác nhận xoá nhà": "Kumpirmahin ang pagtanggal ng bahay",
  "Nhập mật khẩu": "Ilagay ang password",
  "Mật khẩu tài khoản": "Password ng account",
  "Rời khỏi nhà": "Umalis sa bahay",
  "Xoá nhà": "Tanggalin ang bahay",
  "Sai mật khẩu": "Maling password",
  "Đã rời khỏi home": "Umalis na sa bahay",
  "Đã cập nhật": "Na-update",
  "Tìm home...": "Maghanap ng mga bahay...",
  "Đặt vị trí nhà và bật bảo vệ tự động":
      "Itakda ang lokasyon ng bahay at i-enable ang awtomatikong proteksyon",
  "Chuyển quyền chủ nhà hoặc xoá nhà":
      "Ilipat ang pagmamay-ari o tanggalin ang bahay",
  "Đặt Reminder / Alarm nhà đã chọn":
      "Itakda ang Reminder / Alarm para sa mga napiling bahay",
  "Chia sẻ nhà đã chọn": "Ibahagi ang mga napiling bahay",
  "Mở danh sách chia sẻ nhà": "Buksan ang listahan ng pagbabahagi ng bahay",
  "Xoá các nhà đã chọn?": "Tanggalin ang mga napiling bahay?",
  "Các nhà đã chọn sẽ bị xoá vĩnh viễn.":
      "Permanenteng tatanggalin ang mga napiling bahay.",
  "Hoặc quét QR để xin gia nhập các nhà đã chọn":
      "O mag-scan ng QR para humiling ng access sa mga napiling bahay",
  "Email người nhận": "Email ng tatanggap",
  "Chia sẻ": "Ibahagi",
  "Email chưa đăng ký": "Hindi nakarehistro ang email",
  "Chia sẻ hoàn tất": "Kumpleto na ang pagbabahagi",
  "Mở List chia sẻ nhà": "Buksan ang listahan ng pagbabahagi ng bahay",
  "Không có nhà nào bạn có quyền quản lý":
      "Wala kang pamamahala sa alinman sa mga napiling bahay",
  "Chưa share cho ai": "Hindi pa ibinabahagi kaninuman",
  "Tìm nhà": "Maghanap ng mga bahay",
  "Xoá các nhà đã chọn ?": "Tanggalin ang mga napiling bahay?",
  "Thông báo Home": "Mga notification ng bahay",
  "Thông báo nhà": "Mga notification ng bahay",
  "Vai trò thành viên đã thay đổi": "Nabago ang tungkulin ng miyembro",
  "Xoá tất cả thông báo?": "Burahin ang lahat ng notification?",
  "Toàn bộ thông báo nhà sẽ bị xoá.":
      "Buburahin ang lahat ng notification ng bahay.",
  "Chưa có thông báo nào": "Wala pang notification",
  "Chưa có thông báo": "Wala pang notification",
  "Vuốt lên để tải thêm": "Mag-swipe pataas para mag-load pa",
  "Không có thiết bị": "Walang aparato",
  "Chỉ chủ nhà mới được xoá nhà":
      "May-ari lang ang maaaring magtanggal ng bahay na ito",
  "Chỉ chủ nhà mới được chuyển quyền":
      "May-ari lang ang maaaring maglipat ng pagmamay-ari",
  "Lưu ý khi bật Alarm": "Paalala tungkol sa Alarm",
  "Alarm đã được bật": "Naka-enable ang Alarm",
  "Đã hiểu": "Nauunawaan ko",
  "Lưu ý tạm tắt Alarm": "Paalala sa pag-pause ng Alarm",
  "Đã bật Alarm": "Naka-enable ang Alarm",
  "Đã tắt Alarm": "Naka-disable ang Alarm",
  "Tắt Alarm": "I-off ang Alarm",
  "Cả ngày": "Buong araw",
  "Bạn không có quyền thực hiện thao tác này.":
      "Wala kang pahintulot na gawin ito.",
  "Không thể hoàn tất thao tác. Vui lòng thử lại.":
      "Hindi makumpleto ang aksyon. Pakisubukang muli.",
  "QR gia nhập nhiều nhà không hợp lệ":
      "Di-wastong QR code para sa pagsali sa maraming bahay",
  "Bạn đang là chủ các nhà này": "Ikaw ang may-ari ng mga bahay na ito",
  "Một người dùng": "Isang user",
  "Yêu cầu gia nhập nhà": "Kahilingan na sumali sa bahay",
  "Đã gửi yêu cầu gia nhập nhà": "Naipadala na ang kahilingan na sumali",
  "QR gia nhập không hợp lệ": "Di-wastong QR code para sumali",
  "Bạn đang là chủ nhà này": "Ikaw na ang may-ari ng bahay na ito",
  "QR này không phải mã xin gia nhập nhà":
      "Ang QR code na ito ay hindi code para sumali sa bahay",
  "Bạn không có quyền thêm thiết bị":
      "Wala kang pahintulot na magdagdag ng mga aparato",
  "Đã mở chế độ thêm thiết bị": "Naka-enable ang pagpapares ng aparato",
  "Rời khỏi Home này?": "Umalis sa bahay na ito?",
  "Nhà này và toàn bộ thiết bị bên trong sẽ bị xoá vĩnh viễn.":
      "Permanenteng tatanggalin ang bahay na ito at lahat ng aparatong naroon.",
  "Đã xoá nhà": "Natanggal na ang bahay",
  "QR của nhà này": "QR code ng bahay na ito",
  "Người khác quét mã này để gửi yêu cầu gia nhập nhà.":
      "Maaaring i-scan ng iba ang code na ito para humiling ng access sa bahay.",
  "Chia sẻ nhà": "Ibahagi ang bahay",
  "Quét QR để xin gia nhập nhà": "Mag-scan ng QR para sumali sa bahay",
  "Quét QR xin gia nhập nhà": "Mag-scan ng QR para sumali sa bahay",
  "Đưa mã QR chia sẻ nhà vào khung hình":
      "Ilagay sa loob ng frame ang QR code para sa pagbabahagi ng bahay",
  "Mã QR này do chủ nhà chia sẻ":
      "Ibinahagi ng may-ari ng bahay ang QR code na ito",
  "Nhập mã mời": "Ilagay ang code ng imbitasyon",
  "Gửi yêu cầu gia nhập": "Ipadala ang kahilingan na sumali",
  "QR này không phải mã thiết bị":
      "Ang QR code na ito ay hindi code ng aparato",
  "Xin gia nhập nhà": "Humiling na sumali sa bahay",
  "Quét mã QR chia sẻ nhà": "Mag-scan ng QR code para sa pagbabahagi ng bahay",
  "Mời thành viên bằng mã QR": "Mag-imbita ng miyembro gamit ang QR code",
  "Không thể share cho chính bạn":
      "Hindi mo maaaring ibahagi ang bahay sa sarili mo",
  "Lời mời chia sẻ nhà": "Imbitasyon sa pagbabahagi ng bahay",
  "Đã share home": "Naibahagi na ang bahay",
  "Chuyển quyền chủ nhà": "Ilipat ang pagmamay-ari",
  "Không thể chuyển quyền cho chính bạn":
      "Hindi mo maaaring ilipat ang pagmamay-ari sa iyong sarili",
  "Không tìm thấy user": "Hindi natagpuan ang user",
  "Không tìm thấy tài khoản": "Hindi natagpuan ang account",
  "Xác nhận chuyển quyền": "Kumpirmahin ang paglilipat ng pagmamay-ari",
  "Chuyển": "Ilipat",
  "Xác nhận mật khẩu": "Kumpirmahin ang password",
  "Yêu cầu chuyển quyền chủ nhà": "Kahilingan sa paglilipat ng pagmamay-ari",
  "Đã gửi yêu cầu chuyển quyền": "Naipadala na ang kahilingan sa paglilipat",
  "Đã gửi yêu cầu chuyển quyền chủ nhà":
      "Naipadala na ang kahilingan sa paglilipat ng pagmamay-ari",
  "Bạn không có quyền xoá thiết bị":
      "Wala kang pahintulot na magtanggal ng mga aparato",
  "Xóa Device?": "Tanggalin ang aparatong ito?",
  "Đã gửi yêu cầu xoá thiết bị":
      "Naipadala na ang kahilingan sa pagtanggal ng aparato",
  "Đang xoá thiết bị": "Tinatanggal ang aparato",
  "Đăng xuất?": "Mag-log out?",
  "Thêm nhà": "Magdagdag ng bahay",
  "Thêm nhà mới": "Magdagdag ng bagong bahay",
  "Tạo nhà mới": "Gumawa ng bagong bahay",
  "Tạo một ngôi nhà mới của bạn": "Gumawa ng bagong bahay para sa iyo",
  "Quét mã QR được chủ nhà chia sẻ":
      "I-scan ang QR code na ibinahagi ng may-ari ng bahay",
  "Tên nhà": "Pangalan ng bahay",
  "Số điện thoại": "Numero ng telepono",
  "Nam": "Lalaki",
  "Nữ": "Babae",
  "Ngày": "Araw",
  "Tháng": "Buwan",
  "Năm": "Taon",
  "Thông tin cá nhân": "Personal na impormasyon",
  "Thiết lập tài khoản": "I-setup ang account",
  "Vui lòng nhập đủ thông tin":
      "Pakilagay ang lahat ng kinakailangang impormasyon",
  "Không thể lưu thông tin": "Hindi mai-save ang impormasyon",
  "Đã lưu thông tin": "Na-save ang impormasyon",
  "Lỗi lưu profile": "Hindi mai-save ang profile",
  "Thêm số điện thoại để dùng cho các trường hợp khẩn cấp":
      "Magdagdag ng numero ng telepono para sa mga emergency",
  "Hoàn tất": "Tapos na",
  "Đã tạo nhà mới": "Nagawa na ang bahay",
  "Về muộn": "Gabi nang uuwi",
  "Ra ngoài": "Lalabas",
  "Khác": "Iba pa",
  "⏸️ Tạm tắt Alarm hôm nay": "⏸️ I-pause ang Alarm ngayong araw",
  "Chọn giờ bắt đầu tạm tắt": "Piliin ang oras ng pagsisimula ng pag-pause",
  "Từ": "Mula",
  "Từ giờ": "Mula",
  "Chọn giờ kết thúc tạm tắt": "Piliin ang oras ng pagtatapos ng pag-pause",
  "Đến": "Hanggang",
  "Đến giờ": "Hanggang",
  "Xoá lịch tạm tắt": "Tanggalin ang iskedyul ng pag-pause",
  "Xóa lịch tạm tắt": "Tanggalin ang iskedyul ng pag-pause",
  "Giới tính": "Kasarian",
  "SĐT": "Telepono",
  "Ngày sinh": "Petsa ng kapanganakan",
  "Yêu cầu & lời mời": "Mga kahilingan at imbitasyon",
  "Xem lời mời chia sẻ và xin gia nhập":
      "Tingnan ang mga imbitasyon sa pagbabahagi at kahilingang sumali",
  "Cài đặt bảo mật": "Mga setting ng seguridad",
  "Quyền báo động toàn màn hình": "Pahintulot para sa full-screen na Alarm",
  "Báo động toàn màn hình": "Full-screen na Alarm",
  "Đã được cấp quyền": "Naibigay ang pahintulot",
  "Chưa được cấp quyền": "Hindi pa naibibigay ang pahintulot",
  "Mở cài đặt hệ thống": "Buksan ang mga setting ng system",
  "Đăng xuất": "Mag-log out",
  "Thoát tài khoản khỏi thiết bị này": "Mag-sign out sa aparatong ito",
  "Không có yêu cầu hoặc lời mời nào": "Walang kahilingan o imbitasyon",
  "Xoá tài khoản": "Tanggalin ang account",
  "Hành động này sẽ xoá toàn bộ dữ liệu:": "Buburahin nito ang lahat ng datos:",
  "Nhà và thiết bị": "Mga bahay at aparato",
  "Chia sẻ và quyền truy cập": "Pagbabahagi at access",
  "Toàn bộ dữ liệu liên quan": "Lahat ng kaugnay na datos",
  "Mật khẩu xác nhận": "Password sa pagkumpirma",
  "Đã xoá tài khoản": "Natanggal na ang account",
  "Xoá thất bại": "Hindi natanggal",
  "Lỗi xoá tài khoản": "Hindi matanggal ang account",
  "Tình trạng": "Status",
  "Tháo/Lắp": "Pakikialam",
  "Pin": "Baterya",
  "Tín hiệu": "Signal",
  "Chưa liên kết": "Hindi pa naka-link",
  "Liên lạc cuối": "Huling pakikipag-ugnayan",
  "Event cuối": "Huling event",
  "Sự kiện cuối": "Huling kaganapan",
  "Lần kích hoạt cuối": "Huling pag-trigger",
  "Thiết bị không còn tồn tại": "Wala na ang aparato",
  "Mất kết nối": "Nakadiskonekta",
  "Online": "Online",
  "Offline": "Offline",
  "Loại thiết bị": "Uri ng aparato",
  "Nhiệt độ": "Temperatura",
  "Độ ẩm": "Halumigmig",
  "Công suất": "Power",
  "Điện áp": "Boltahe",
  "Dòng điện": "Daloy ng kuryente",
  "Điện năng": "Enerhiya",
  "Cường độ rung": "Lakas ng panginginig",
  "Góc nghiêng": "Anggulo ng pagkakatagilid",
  "Độ mở van": "Pagkabukas ng balbula",
  "Nguồn dự phòng": "Reserbang kuryente",
  "Ngập/rò nước": "Tagas ng tubig",
  "Phát hiện khói": "Natukoy ang usok",
  "Quản lý phòng": "Pamamahala ng kuwarto",
  "Bạn không có quyền quản lý phòng":
      "Wala kang pahintulot na pamahalaan ang mga kuwarto",
  "Đổi tên phòng": "Palitan ang pangalan ng kuwarto",
  "Tên phòng": "Pangalan ng kuwarto",
  "Xoá phòng": "Tanggalin ang kuwarto",
  "Thiết bị trong phòng này sẽ được chuyển về Chưa phân phòng.":
      "Ililipat sa seksyong Hindi nakatalaga ang mga aparato sa kuwartong ito.",
  "Thêm phòng": "Magdagdag ng kuwarto",
  "Ví dụ: Phòng khách": "Halimbawa: Sala",
  "Phòng khách": "Sala",
  "Tên phòng đã tồn tại": "May kuwarto nang may ganitong pangalan",
  "Chưa phân phòng": "Hindi nakatalaga",
  "Phòng mặc định": "Default na kuwarto",
  "Phát hiện bất thường": "Natukoy ang hindi pangkaraniwang aktibidad",
  "Phát hiện cạy phá": "Natukoy ang pakikialam",
  "Tamper detected": "Natukoy ang pakikialam",
  "Tamper cleared": "Natapos na ang alerto sa pakikialam",
  "Door opened": "Bukas ang pinto",
  "Door closed": "Sarado ang pinto",
  "Motion detected": "Natukoy ang galaw",
  "Battery low": "Mahina ang baterya",
  "Device offline": "Offline ang aparato",
  "Device online": "Online ang aparato",
  "Alarm triggered": "Na-trigger ang Alarm",
  "Alarm cleared": "Natapos na ang Alarm",
  "Cửa mở": "Bukas ang pinto",
  "Cửa đóng": "Sarado ang pinto",
  "Chưa đặt vị trí nhà": "Hindi pa nakatakda ang lokasyon ng bahay",
  "Đặt vị trí nhà tại đây": "Itakda rito ang lokasyon ng bahay",
  "Hãy đặt vị trí nhà trước khi bật tự động Bảo vệ":
      "Itakda muna ang lokasyon ng bahay bago i-on ang Awtomatikong Proteksyon",
  "Bán kính bảo vệ mặc định: 150 m": "Default na radius ng proteksyon: 150 m",
  "Mỗi thành viên sẽ cần cấp quyền vị trí Luôn cho phép để trạng thái rời/đến nhà hoạt động khi app chạy nền.":
      "Kailangang itakda ng bawat miyembro ang pahintulot sa lokasyon sa Palaging Payagan upang gumana ang status ng pag-alis/pagdating sa bahay habang tumatakbo ang app sa background.",
  "Lưu cài đặt": "I-save ang mga setting",
  "Đã đặt vị trí nhà": "Nakatakda na ang lokasyon ng bahay",
  "Đang lấy vị trí...": "Kinukuha ang lokasyon...",
  "Đang lưu...": "Sine-save...",
  "Đổi tên hiển thị": "Palitan ang pangalang ipinapakita",
  "Cập nhật thông tin nhà": "I-update ang impormasyon ng bahay",
  "Nhập địa chỉ của nhà": "Ilagay ang address ng bahay",
  "Lưu thay đổi": "I-save ang mga pagbabago",
  "Tên này chỉ hiển thị riêng trên tài khoản của bạn.":
      "Sa account mo lang ipinapakita ang pangalang ito.",
  "Tên và địa chỉ sẽ được cập nhật cho toàn bộ thành viên trong nhà.":
      "Maa-update ang pangalan at address para sa lahat ng miyembro ng bahay.",
  "Một thành viên": "Isang miyembro",
  "Đã cập nhật thông tin nhà": "Na-update ang impormasyon ng bahay",
  "Thay tên": "Palitan ang pangalan",
  "Đã đổi tên thiết bị": "Napalitan ang pangalan ng aparato",
  "Chưa chọn nhà để kiểm tra": "Pumili ng bahay na susuriin",
  "Hãy thực hiện kiểm tra bằng tài khoản Owner":
      "Gawin ang pagsusuring ito gamit ang account ng may-ari",
  "Không đọc được dữ liệu nhà": "Hindi mabasa ang datos ng bahay",
  "Nhà cần có ít nhất một thiết bị để test":
      "Kailangang may kahit isang aparato ang bahay para sa pagsusuri",
  "Đóng": "Isara",
  "Đã thiết lập": "Nakatakda",
  "Quét QR": "Mag-scan ng QR",
  "Quét QR để thêm thiết bị": "Mag-scan ng QR para magdagdag ng aparato",
  "Nhập HUB ID thủ công": "Manu-manong ilagay ang HUB ID",
  "Bạn không có quyền sắp xếp phòng":
      "Wala kang pahintulot na baguhin ang ayos ng mga kuwarto",
  "Cảnh báo khói": "Alerto sa usok",
  "Cập nhật thiết bị": "Pag-update ng aparato",
  "Cửa đang mở": "Bukas ang pinto",
  "Cửa đã đóng": "Sarado ang pinto",
  "Firebase Rules: CÓ LỖI": "Firebase Rules: MAY NAKITANG PROBLEMA",
  "Firebase Rules: ĐẠT": "Firebase Rules: PASADO",
  "Giờ không hợp lệ": "Di-wastong oras",
  "Khôi phục mật khẩu": "I-reset ang password",
  "Nhập email của bạn": "Ilagay ang iyong email",
  "Gửi": "Ipadala",
  "Đã gửi email khôi phục":
      "Naipadala na ang email para sa pag-reset ng password",
  "Không gửi được email": "Hindi maipadala ang email",
  "Vui lòng nhập email và mật khẩu": "Ilagay ang iyong email at password",
  "Mật khẩu xác nhận không khớp": "Hindi magkatugma ang mga password",
  "Không thể tạo tài khoản": "Hindi magawa ang account",
  "Sai tài khoản": "Maling account",
  "Email đã tồn tại": "May account nang gumagamit ng email na ito",
  "Mật khẩu quá yếu": "Masyadong mahina ang password",
  "Sai email hoặc mật khẩu": "Maling email o password",
  "Lỗi đăng nhập": "Error sa pag-sign in",
  "Email": "Email",
  "Mật khẩu": "Password",
  "Ghi nhớ tài khoản": "Tandaan ang account",
  "Đăng nhập": "Mag-log in",
  "Đăng ký mới": "Gumawa ng account",
  "Quên mật khẩu?": "Nakalimutan ang password?",
  "Chưa có tài khoản? Đăng ký": "Wala ka pang account? Mag-sign up",
  "Đã có tài khoản? Đăng nhập": "May account ka na? Mag-log in",
  "Tính năng đang được phát triển": "Ginagawa pa ang feature na ito",
  "Thông báo": "Mga notification",
  "Chat trong nhà": "Chat sa bahay",
  "Tìm kiếm tin nhắn": "Maghanap ng mga mensahe",
  "Xem thành viên": "Tingnan ang mga miyembro",
  "Tìm nội dung hoặc tên người gửi":
      "Maghanap ng nilalaman o pangalan ng nagpadala",
  "Xoá từ khoá": "I-clear ang keyword",
  "Không có kết quả": "Walang resulta",
  "Tìm ngôn ngữ": "Maghanap ng wika",
  "Kết quả trước": "Nakaraang resulta",
  "Kết quả tiếp theo": "Susunod na resulta",
  "Chưa có tin nhắn": "Wala pang mensahe",
  "Không tìm thấy thành viên phù hợp": "Walang natagpuang katugmang miyembro",
  "Nhắc đến trong tin nhắn": "Banggitin sa mensahe",
  "Huỷ trả lời": "Kanselahin ang tugon",
  "Nhắn gì đó...": "Mag-type ng mensahe...",
  "Gọi điện": "Tumawag",
  "Alarm thiết bị": "Alarm ng aparato",
  "Chế độ áp dụng": "Mode na ilalapat",
  "Theo nhà": "Iskedyul ng bahay",
  "Riêng tôi": "Para sa akin lang",
  "Dùng lịch chung do Chủ nhà hoặc Quản trị viên thiết lập":
      "Gamitin ang ibinahaging iskedyul na itinakda ng may-ari o admin",
  "Dùng lịch riêng chỉ áp dụng cho tài khoản của bạn":
      "Gumamit ng personal na iskedyul na para lang sa iyong account",
  "Thiết lập nhanh Alarm": "Mabilisang pag-setup ng Alarm",
  "Thiết lập nhanh toàn bộ thiết bị": "Mabilisang itakda ang lahat ng aparato",
  "Áp dụng cho toàn bộ thiết bị": "Ilapat sa lahat ng aparato",
  "Bắt đầu": "Magsimula",
  "Kết thúc": "Magtapos",
  "Thời gian lặp lại": "Agwat ng pag-uulit",
  "Không lặp lại": "Huwag ulitin",
  "Quét QR HUB": "I-scan ang QR ng HUB",
  "Đưa mã QR vào giữa khung": "Ilagay ang QR code sa loob ng frame",
  "Đang áp dụng...": "Inilalapat...",
  "Hôm nay đã ghi nhận cảnh báo SOS":
      "May naitalang alerto ng SOS ngayong araw",
  "Hôm nay đã ghi nhận cảnh báo khói":
      "May naitalang alerto sa usok ngayong araw",
  "Khói đã an toàn": "Wala nang usok",
  "Không tìm thấy nhà của thông báo này":
      "Hindi natagpuan ang bahay para sa notification na ito",
  "Không tìm thấy thiết bị trong nhà này":
      "Hindi natagpuan ang aparato sa bahay na ito",
  "Một chủ nhà": "Isang may-ari ng bahay",
  "Ngôi nhà đang hoạt động ổn định": "Normal ang pagpapatakbo ng bahay",
  "Nhiệt độ cao": "Mataas na temperatura",
  "OK": "OK",
  "Pin yếu": "Mahina ang baterya",
  "SOS đã kết thúc": "Natapos na ang SOS",
  "SOS được kích hoạt": "Na-activate ang SOS",
  "Tamper bình thường": "Natapos na ang alerto sa pakikialam",
  "Thiết bị bị tháo": "Natukoy ang pakikialam",
  "Thiết bị mới": "Bagong aparato",
  "Thiết bị offline": "Offline ang aparato",
  "Thiết bị online": "Online ang aparato",
  "Báo động kích hoạt": "Na-trigger ang Alarm",
  "Báo động đã tắt": "Natapos na ang Alarm",
  "Tạm tắt Alarm hôm nay": "I-pause ang Alarm ngayong araw",
  "Độ ẩm cao": "Mataas na halumigmig",
  "Thử lại": "Subukan muli",
  "Không thể tải dữ liệu tài khoản": "Hindi ma-load ang datos ng account",
  "Không": "Hindi",
  "Đã chia sẻ nhà thành công.": "Matagumpay na naibahagi ang mga bahay.",
  "Tìm nhà...": "Maghanap ng mga bahay...",
  "Đã rời khỏi nhà": "Umalis na sa bahay",
  "Bạn sẽ rời khỏi các nhà được chia sẻ.": "Aalis ka sa mga ibinahaging bahay.",
  "Các nhà của bạn sẽ bị xoá.\n": "Tatanggalin ang mga bahay mo.\n",
  "Thao tác này sẽ thay đổi lịch Home Alarm của toàn bộ thiết bị an ninh trong các nhà đã chọn.\n\n":
      "Babaguhin nito ang mga iskedyul ng Alarm ng bahay para sa lahat ng aparatong panseguridad sa mga napiling bahay.\n\n",
  "Thao tác này sẽ thêm Home Reminder cho các nhà đã chọn.\n\n":
      "Magdaragdag ito ng Reminder ng bahay sa mga napiling bahay.\n\n",
  "Xác nhận thay đổi Alarm": "Kumpirmahin ang mga pagbabago sa Alarm",
  "Xác nhận thay đổi Reminder": "Kumpirmahin ang mga pagbabago sa Reminder",
  "Lặp lại khi sự cố vẫn còn": "Ulitin habang nagpapatuloy ang problema",
  "Thời gian lặp lại Alarm": "Oras ng pag-uulit ng Alarm",
  "VD: Mr Chung": "Hal. G. Chung",
  "🏡 Chưa có nhà nào": "🏡 Wala pang bahay",
  "Vẫn chuyển về Bình thường": "Lumipat pa rin sa Normal",
  "Tự động Bảo vệ khi rời nhà vẫn đang bật. Nếu mọi thành viên vẫn ở ngoài, hệ thống có thể tự bật lại Bảo vệ sau vài phút.":
      "Naka-on pa rin ang Awtomatikong Proteksyon kapag wala sa bahay. Kung nasa labas pa rin ang lahat ng miyembro, maaaring awtomatikong i-on muli ng system ang Mode ng Proteksyon pagkalipas ng ilang minuto.",
  "Chuyển về Bình thường?": "Lumipat sa Normal?",
  "Khi bật, các thiết bị an ninh sẽ được giám sát ngay.\n\n":
      "Agad na susubaybayan ang mga aparatong panseguridad.\n\n",
  "Bật Bảo vệ thủ công?": "Manu-manong i-on ang Mode ng Proteksyon?",
  "Hành động này sẽ thay đổi thời gian báo động của một số thiết bị ":
      "Babaguhin ng aksyong ito ang oras ng Alarm para sa ilang aparato ngayong araw...",
  "Hành động này sẽ tắt toàn bộ báo động của nhà ":
      "I-o-off ng aksyong ito ang lahat ng Alarm para sa ",
  "Tắt toàn bộ Alarm?": "I-off ang lahat ng Alarm?",
  "Không xoá được lịch tạm tắt Alarm":
      "Hindi matanggal ang iskedyul ng pag-pause ng Alarm",
  "Không lưu được tạm tắt Alarm": "Hindi mai-save ang pag-pause ng Alarm",
  "Không gửi được yêu cầu xoá": "Hindi maipadala ang kahilingan sa pagtanggal",
  "Không lưu được cài đặt": "Hindi mai-save ang setting",
  "Không lấy được vị trí hiện tại": "Hindi makuha ang kasalukuyang lokasyon",
  "Không thể xác nhận tài khoản hiện tại":
      "Hindi ma-verify ang kasalukuyang account",
  "Mật khẩu không đúng": "Maling password",
  "Không thể xác nhận mật khẩu": "Hindi ma-verify ang password",
  "Chỉ Chủ nhà hoặc Quản trị viên mới có quyền thay đổi lặp báo động":
      "May-ari o Admin lang ang maaaring magbago ng setting ng pag-uulit ng Alarm",
  "Không lưu được thời gian lặp báo động":
      "Hindi mai-save ang oras ng pag-uulit ng Alarm",
  "Chỉ Chủ nhà hoặc Quản trị viên mới có quyền thay đổi Mode Bảo vệ":
      "May-ari o Admin lang ang maaaring magbago ng Mode ng Proteksyon",
  "Không thể thay đổi chế độ nhà": "Hindi mabago ang mode ng bahay",
  "Đã bật Bảo vệ nhưng chưa gửi được thông báo":
      "Naka-on ang Mode ng Proteksyon, pero hindi naipadala ang notification",
  "Đã bật Mode Bảo vệ thủ công":
      "Naka-enable ang manu-manong Mode ng Proteksyon",
  "Đã chuyển nhà về Bình thường": "Naibalik sa Normal ang bahay",
  "60 phút": "60 minuto",
  "30 phút": "30 minuto",
  "15 phút": "15 minuto",
  "Bạn đang xem lịch của chủ nhà. Chọn Riêng tôi để tự đặt lịch Alarm.":
      "Tinitingnan mo ang iskedyul ng may-ari. Piliin ang Para sa akin lang para magtakda ng sarili mong iskedyul ng Alarm.",
  "Chọn giờ kết thúc Alarm": "Piliin ang oras ng pagtatapos ng Alarm",
  "Chọn giờ bắt đầu Alarm": "Piliin ang oras ng pagsisimula ng Alarm",
  "Bạn không có quyền sửa lịch Alarm của nhà":
      "Wala kang pahintulot na baguhin ang iskedyul ng Alarm ng bahay na ito",
  "Không thể áp dụng Alarm cho toàn bộ thiết bị":
      "Hindi mailapat ang Alarm sa lahat ng aparato",
  "Nhà chưa có thiết bị an ninh để áp dụng":
      "Walang aparatong panseguridad sa bahay na ito na maaaring lagyan ng Alarm",
  "Bạn không có quyền sửa lịch Theo nhà. Hãy chọn Riêng tôi.":
      "Wala kang pahintulot na baguhin ang iskedyul ng bahay. Piliin ang Para sa akin lang.",
  "Không thể lưu chế độ Alarm": "Hindi mai-save ang mode ng Alarm",
  "Thêm Reminder": "Magdagdag ng Reminder",
  "Reminder sẽ nhắc bạn kiểm tra trạng thái an toàn của ngôi nhà vào giờ đã chọn.":
      "Paalalahanan ka ng Reminder na tingnan ang status ng seguridad ng iyong bahay sa napiling oras.",
  "Thêm khung giờ Alarm": "Magdagdag ng saklaw ng oras ng Alarm",
  "Đang sử dụng Reminder riêng của bạn":
      "Ginagamit ang sarili mong mga setting ng Reminder",
  "Đang sử dụng Reminder của chủ nhà":
      "Ginagamit ang mga setting ng Reminder ng may-ari",
  "Sửa giờ Reminder": "Baguhin ang oras ng Reminder",
  "Sửa giờ kết thúc Alarm": "Baguhin ang oras ng pagtatapos ng Alarm",
  "Sửa giờ bắt đầu Alarm": "Baguhin ang oras ng pagsisimula ng Alarm",
  "Xoá Reminder": "Tanggalin ang Reminder",
  "Mỗi 1 giờ": "Bawat 1 oras",
  "Mỗi 30 phút": "Bawat 30 minuto",
  "Mỗi 15 phút": "Bawat 15 minuto",
  "Không báo lại": "Huwag ulitin ang alerto",
  "Báo lại khi vẫn chưa an toàn": "Ulitin ang alerto habang hindi pa ligtas",
  "Báo lại mỗi 1 giờ": "Ulitin ang alerto bawat oras",
  "Báo lại mỗi 30 phút": "Ulitin ang alerto bawat 30 minuto",
  "Báo lại mỗi 15 phút": "Ulitin ang alerto bawat 15 minuto",
  "Quản lý nhà": "Pamamahala ng bahay",
  "Xoá thành viên": "Alisin ang miyembro",
  "Đã xoá thành viên": "Naalis ang miyembro",
  "Đồng ý": "OK",
  "Bạn chắc chắn muốn rời khỏi nhà này?":
      "Sigurado ka bang gusto mong umalis sa bahay na ito?",
  "Xoá thành viên?": "Alisin ang miyembro?",
  "Rời khỏi nhà?": "Umalis sa bahay na ito?",
  "Chỉ chủ nhà mới được thay đổi vai trò":
      "May-ari lang ang maaaring magbago ng mga tungkulin",
  "Bạn không có quyền xoá thành viên này":
      "Wala kang pahintulot na alisin ang miyembrong ito",
  "Bạn": "Ikaw",
  "Không có email": "Walang email",
  "Chưa có số điện thoại": "Walang numero ng telepono",
  "Không mở được ứng dụng gọi điện": "Hindi mabuksan ang app sa pagtawag",
  "Thành viên chưa cập nhật số điện thoại":
      "Hindi pa nagdagdag ng numero ng telepono ang miyembrong ito",
  "Bảo vệ thủ công đang bật - chỉ tắt khi chuyển về Bình thường":
      "Naka-on ang manu-manong Mode ng Proteksyon—lumipat sa Normal para i-off ito",
  "Thời gian lặp": "Agwat ng pag-uulit",
  "Chọn 0 để chỉ báo một lần. Cài đặt này dùng cho cả Bảo vệ thủ công và Tự động Bảo vệ khi rời nhà.":
      "Piliin ang 0 para isang beses lang mag-alerto. Nalalapat ang setting na ito sa manu-manong Mode ng Proteksyon at Awtomatikong Proteksyon kapag wala sa bahay.",
  "Lặp báo động khi sự cố vẫn còn":
      "Ulitin ang Alarm habang nagpapatuloy ang problema",
  "Đang được sử dụng": "Kasalukuyang aktibo",
  "Chuyển về sử dụng thông thường": "Bumalik sa normal na paggamit",
  "Chế độ nhà": "Mode ng bahay",
  "Thiết bị SOS chưa ghi nhận cảnh báo.":
      "Wala pang naitalang alerto mula sa aparatong SOS.",
  "Cảm biến khói chưa ghi nhận bất thường.":
      "Wala pang natukoy na problema ang sensor ng usok.",
  "Bạn hoặc thành viên đã chủ động bật Bảo vệ.":
      "Manu-manong in-on mo o ng isang miyembro ang Mode ng Proteksyon.",
  "SafeHome tự bật Bảo vệ vì bạn đã rời khỏi nhà.":
      "Awtomatikong in-on ng SafeHome ang Mode ng Proteksyon dahil umalis ka sa bahay.",
  "Nhà đang ở chế độ dùng bình thường.":
      "Kasalukuyang nasa Normal mode ang bahay na ito.",
  "Bảo vệ thủ công đang bật": "Naka-on ang manu-manong Mode ng Proteksyon",
  "Bảo vệ tự động đang bật": "Naka-on ang awtomatikong Mode ng Proteksyon",
  "Bảo vệ đang tắt": "Naka-off ang Mode ng Proteksyon",
  "Bạn đã mở app gần đây để kiểm tra trạng thái.":
      "Binuksan mo kamakailan ang app para tingnan ang status.",
  "Bạn nên mở app định kỳ để kiểm tra quyền, lịch và cảnh báo chưa đọc.":
      "Buksan nang regular ang app para tingnan ang mga pahintulot, iskedyul, at hindi pa nababasang alerto.",
  "Sau vài lần sử dụng, SafeHome sẽ đánh giá thói quen kiểm tra app tốt hơn.":
      "Pagkatapos ng ilang paggamit, mas mahusay nang masusuri ng SafeHome ang nakasanayan mong pagtingin sa app.",
  "Tần suất vào app ổn": "Maayos ang dalas ng pagtingin sa app",
  "Đã lâu chưa vào app kiểm tra":
      "Matagal mo nang hindi binubuksan ang app para tingnan ang status",
  "Đang ghi nhận tần suất vào app": "Itinatala ang dalas ng pagbukas sa app",
  "Cần kiểm tra quyền vị trí luôn luôn và điều kiện chạy nền.":
      "Suriin ang pahintulot sa lokasyon na Palaging Payagan at ang mga kondisyon sa background.",
  "Thiết bị đủ điều kiện để Auto rời khỏi nhà hoạt động.":
      "Natutugunan ng aparatong ito ang mga kinakailangan para sa Awtomatikong Proteksyon kapag wala sa bahay.",
  "Bạn có thể bật khi muốn tự động chuyển Bảo vệ lúc rời nhà.":
      "I-enable ito kung gusto mong awtomatikong i-on ang Mode ng Proteksyon kapag umalis ka.",
  "Auto rời khỏi nhà chưa ổn":
      "Hindi pa handa ang Awtomatikong Proteksyon kapag wala sa bahay",
  "Auto rời khỏi nhà đã sẵn sàng":
      "Handa na ang Awtomatikong Proteksyon kapag wala sa bahay",
  "Auto rời khỏi nhà chưa bật":
      "Hindi naka-enable ang Awtomatikong Proteksyon kapag wala sa bahay",
  "Nên thêm báo khói, SOS hoặc thiết bị khẩn cấp phù hợp với nhà.":
      "Magdagdag ng sensor ng usok, SOS, o aparatong pang-emergency na angkop sa iyong bahay.",
  "Chưa có thiết bị khẩn cấp": "Wala pang aparatong pang-emergency",
  "Đã có thiết bị khẩn cấp": "May mga aparatong pang-emergency na",
  "Nên đặt lịch Alarm cho thời gian ngủ hoặc vắng nhà.":
      "Magtakda ng iskedyul ng Alarm para sa oras ng pagtulog o kapag wala ka sa bahay.",
  "Nhà đã có lịch Alarm hoặc lịch cảnh báo theo thiết bị.":
      "May iskedyul ng Alarm o alerto kada aparato ang bahay na ito.",
  "Chưa set lịch Alarm": "Hindi pa nakatakda ang iskedyul ng Alarm",
  "Đã set lịch Alarm": "Nakatakda na ang iskedyul ng Alarm",
  "Nên có ít nhất một Reminder để không quên kiểm tra nhà.":
      "Magtakda ng kahit isang Reminder para hindi mo makalimutang tingnan ang iyong bahay.",
  "App sẽ nhắc bạn kiểm tra nhà theo lịch đã đặt.":
      "Paalalahanan ka ng app na tingnan ang bahay ayon sa itinakdang iskedyul.",
  "Chưa setup Reminder": "Hindi pa naka-setup ang Reminder",
  "Đã setup Reminder": "Naka-setup na ang Reminder",
  "Hãy mở lại app hoặc đăng nhập lại nếu thiết bị không nhận cảnh báo.":
      "Buksan muli ang app o mag-sign in ulit kung hindi nakakatanggap ng mga alerto ang aparatong ito.",
  "Thiết bị chưa đăng ký nhận cảnh báo":
      "Hindi nakarehistro ang aparatong ito para sa mga alerto",
  "Thiết bị nhận cảnh báo bình thường":
      "Nakakatanggap nang maayos ng mga alerto ang aparatong ito",
  "iOS quản lý chạy nền chặt hơn Android; hãy giữ thông báo và vị trí luôn luôn nếu dùng Auto rời khỏi nhà.":
      "Mas mahigpit ang iOS sa paggamit sa background kaysa Android; panatilihing naka-on ang mga notification at Palaging Payagan ang lokasyon kung gumagamit ng Awtomatikong Proteksyon kapag wala sa bahay.",
  "Cơ chế iOS": "Pagpapatakbo ng iOS",
  "Hãy kiểm tra quyền chạy nền và tự khởi động để cảnh báo không bị trễ.":
      "Suriin ang pahintulot sa background at awtomatikong pagsisimula para hindi maantala ang mga alerto.",
  "Thiết bị đã xác nhận các điều kiện chạy nền quan trọng.":
      "Nakumpirma ng aparato ang mahahalagang kondisyon sa background.",
  "Cần kiểm tra chạy nền / tự khởi động":
      "Suriin ang paggamit sa background / awtomatikong pagsisimula",
  "Chạy nền ổn định": "Maayos ang pagpapatakbo sa background",
  "Một số máy Android có thể trì hoãn cảnh báo nếu tối ưu pin còn bật.":
      "Maaaring maantala ng ilang Android phone ang mga alerto habang naka-on ang pag-optimize ng baterya.",
  "Điện thoại ít có khả năng trì hoãn cảnh báo SafeHome.":
      "Mas maliit ang posibilidad na maantala ng telepono ang mga alerto ng SafeHome.",
  "Chưa tắt tối ưu pin": "Naka-enable pa rin ang pag-optimize ng baterya",
  "Tối ưu pin không chặn app":
      "Hindi hinaharangan ng pag-optimize ng baterya ang app",
  "Auto rời khỏi nhà cần quyền vị trí luôn luôn để chạy ổn định.":
      "Kailangan ng pahintulot sa lokasyon na Palaging Payagan upang gumana nang maaasahan ang Awtomatikong Proteksyon kapag wala sa bahay.",
  "Cần cấp quyền vị trí để Auto rời khỏi nhà hoạt động.":
      "Kailangan ang pahintulot sa lokasyon para sa Awtomatikong Proteksyon kapag wala sa bahay.",
  "Dịch vụ vị trí đang tắt nên Auto rời khỏi nhà không ổn định.":
      "Naka-off ang serbisyo ng lokasyon, kaya maaaring hindi gumana nang maaasahan ang Awtomatikong Proteksyon kapag wala sa bahay.",
  "Chỉ cần quyền này khi dùng Auto rời khỏi nhà.":
      "Kailangan lang ito kapag ginagamit ang Awtomatikong Proteksyon kapag wala sa bahay.",
  "Chưa cấp vị trí luôn luôn":
      "Hindi pinapayagan ang lokasyon sa lahat ng oras",
  "Đã cấp vị trí luôn luôn": "Pinapayagan ang lokasyon sa lahat ng oras",
  "iOS không mở toàn màn hình như Android; app dùng notification và âm thanh hệ thống.":
      "Hindi nagbubukas ng full-screen ang iOS tulad ng Android; gumagamit ang app ng mga notification at tunog ng system.",
  "Android dùng cảnh báo toàn màn hình; nếu máy chặn, hãy cấp quyền trong cài đặt.":
      "Gumagamit ang Android ng mga full-screen na alerto; payagan ito sa mga setting kung hinaharangan ng telepono.",
  "Cảnh báo trên iOS": "Mga alerto sa iOS",
  "Cảnh báo toàn màn hình": "Mga full-screen na alerto",
  "Cảnh báo có thể không hiển thị nếu thông báo bị tắt.":
      "Maaaring hindi lumabas ang mga alerto kung naka-disable ang mga notification.",
  "Điện thoại có thể nhận thông báo SafeHome.":
      "Makakatanggap ang teleponong ito ng mga notification ng SafeHome.",
  "Chưa bật thông báo": "Hindi naka-enable ang mga notification",
  "Đã bật thông báo": "Naka-enable ang mga notification",
  "Hệ thống: Sẵn sàng": "System: Handa",
  "Hệ thống: Có thể bỏ lỡ cảnh báo":
      "System: Maaaring hindi matanggap ang ilang alerto",
  "Cách bạn đang dùng app": "Paano mo ginagamit ang app",
  "Thiết bị của bạn": "Ang iyong aparato",
  "Kiểm tra điện thoại và cách bạn đang dùng app.":
      "Sinusuri ang iyong telepono at kung paano mo ginagamit ang app.",
  "Hệ thống SafeHome": "System ng SafeHome",
  "Hệ thống: Đang kiểm tra...": "System: Sinusuri...",
  "Tên": "Pangalan",
  "Bạn không có quyền thay đổi vị trí nhà":
      "Wala kang pahintulot na baguhin ang lokasyon ng bahay",
  "Hãy bật GPS để đặt vị trí nhà":
      "I-on ang GPS para itakda ang lokasyon ng bahay",
  "Bạn chưa cấp quyền vị trí": "Hindi pa naibibigay ang pahintulot sa lokasyon",
  "Hãy cấp quyền vị trí trong Cài đặt ứng dụng":
      "Ibigay ang pahintulot sa lokasyon sa mga setting ng app",
  "Đã bật tự động Bảo vệ khi mọi người rời nhà":
      "Naka-enable ang Awtomatikong Proteksyon kapag umalis ang lahat sa bahay",
  "Đã tắt tự động Bảo vệ khi mọi người rời nhà":
      "Naka-disable ang Awtomatikong Proteksyon kapag umalis ang lahat sa bahay",
  "Không thể thay đổi trạng thái Alarm": "Hindi mabago ang status ng Alarm",
  "Đã tắt toàn bộ Alarm của nhà": "Na-off na ang lahat ng Alarm ng bahay",
  "QR này không phải mã xin gia nhập Home":
      "Ang QR code na ito ay hindi code para sumali sa bahay",
  "Thêm Home": "Magdagdag ng bahay",
  "Mở cài đặt": "Buksan ang mga setting",
  "Để sau": "Mamaya",
  "SafeHome cần quyền vị trí \"Luôn cho phép\" để nhận biết khi bạn rời hoặc trở về nhà, kể cả khi ứng dụng đang chạy nền.":
      "Kailangan ng SafeHome ang pahintulot sa lokasyon na \"Palaging Payagan\" upang matukoy kung umalis ka o bumalik sa bahay, kahit tumatakbo ang app sa background.",
  "SafeHome hiện chỉ được truy cập vị trí khi bạn đang sử dụng ứng dụng.\n\nHãy chọn quyền Vị trí và chuyển sang \"Luôn cho phép\" để tính năng tự động Bảo vệ khi rời nhà hoạt động khi ứng dụng đang chạy nền.":
      "Kasalukuyang maa-access lang ng SafeHome ang lokasyon habang ginagamit mo ang app.\n\nBuksan ang setting ng pahintulot sa Lokasyon at piliin ang \"Palaging Payagan\" upang patuloy na gumana sa background ang awtomatikong proteksyon kapag wala sa bahay.",
  "Cho phép vị trí luôn luôn": "Palaging payagan ang access sa lokasyon",
  "Các nhà của bạn sẽ bị xoá.\nCác nhà được chia sẻ sẽ được rời khỏi.":
      "Tatanggalin ang mga bahay mo.\nAalis ka sa mga ibinahaging bahay.",
  "Thao tác này sẽ thay đổi lịch Home Alarm của toàn bộ thiết bị an ninh trong các nhà đã chọn.\n\nNhững thành viên đang sử dụng Alarm 'Theo nhà' sẽ bị ảnh hưởng.\nAlarm cá nhân ở chế độ 'Riêng tôi' sẽ không bị thay đổi.":
      "Babaguhin nito ang mga iskedyul ng Alarm ng bahay para sa lahat ng aparatong panseguridad sa mga napiling bahay.\n\nMaaapektuhan ang mga miyembrong gumagamit ng mga setting ng Alarm ng bahay.\nHindi mababago ang mga personal na setting ng Alarm.",
  "Thao tác này sẽ thêm Home Reminder cho các nhà đã chọn.\n\nNhững thành viên đang sử dụng Reminder 'Theo nhà' sẽ bị ảnh hưởng.\nReminder cá nhân ở chế độ 'Riêng tôi' sẽ không bị thay đổi.":
      "Magdaragdag ito ng Reminder ng bahay sa mga napiling bahay.\n\nMaaapektuhan ang mga miyembrong gumagamit ng mga setting ng Reminder ng bahay.\nHindi mababago ang mga personal na setting ng Reminder.",
  "Khi bật, các thiết bị an ninh sẽ được giám sát ngay.\n\nTự động Bảo vệ khi rời nhà sẽ tạm dừng. Chế độ này không tự tắt khi có người về nhà và chỉ được tắt khi một thành viên có quyền chủ động chuyển về Bình thường.":
      "Agad na susubaybayan ang mga aparatong panseguridad.\n\nIpo-pause ang Awtomatikong Proteksyon kapag wala sa bahay. Hindi awtomatikong nag-o-off ang mode na ito kapag may umuwi at maaari lang itong ibalik sa Normal ng miyembrong may pahintulot.",
  "Hành động này sẽ thay đổi thời gian báo động của một số thiết bị trong hôm nay...":
      "Babaguhin ng aksyong ito ang oras ng Alarm para sa ilang aparato ngayong araw...",
  "Hành động này sẽ tắt toàn bộ báo động của nhà dưới mọi hình thức. Bạn sẽ không còn nhận được cảnh báo khi có nguy hiểm trên điện thoại nữa.":
      "I-o-off ng aksyong ito ang lahat ng Alarm para sa bahay na ito. Hindi ka na makakatanggap ng mga alerto sa panganib sa teleponong ito.",
  "Alarm đang sử dụng chế độ Theo nhà.\n\nBạn sẽ nhận cảnh báo theo lịch Alarm chung do Chủ nhà hoặc Quản trị viên thiết lập.":
      "Ginagamit ng Alarm ang mga setting ng bahay.\n\nMakakatanggap ka ng mga alerto ayon sa ibinahaging iskedyul na itinakda ng may-ari o administrator.",
  "Alarm đang sử dụng chế độ Riêng tôi.\n\nBạn sẽ nhận cảnh báo theo lịch Alarm riêng đã thiết lập cho tài khoản này.":
      "Ginagamit ng Alarm ang mga setting na Para sa akin lang.\n\nMakakatanggap ka ng mga alerto ayon sa personal na iskedyul ng Alarm para sa account na ito.",
  "Không thể đăng nhập bằng Google": "Hindi makapag-sign in gamit ang Google",
  "Không đặt được mật khẩu": "Hindi maitakda ang password",
  "Chấp nhận": "Tanggapin",
  "Cho phép": "Payagan",
  "Không thể chấp nhận lời mời. Vui lòng thử lại.":
      "Hindi matanggap ang imbitasyon. Pakisubukang muli.",
  "Không thể chấp nhận lời xin vào nhà. Vui lòng thử lại.":
      "Hindi matanggap ang kahilingan na sumali. Pakisubukang muli.",
  "Từ chối": "Tanggihan",
  "Lời mời từ chủ nhà": "Imbitasyon mula sa may-ari",
  "Nhận quyền chủ nhà": "Tanggapin ang pagmamay-ari ng bahay",
  "Một người dùng SafeHome": "Isang user ng SafeHome",
  "Lời mời gia nhập": "Imbitasyon na sumali",
  "Lời xin vào nhà": "Kahilingan na sumali sa bahay",
  "Nhập HUB ID": "Ilagay ang HUB ID",
  "VD: HUB_001": "Halimbawa: HUB_001",
  "Pair": "Ipares",
  "Mật khẩu tối thiểu 6 ký tự":
      "Dapat may hindi bababa sa 6 na character ang password",
  "Mật khẩu nhập lại không khớp": "Hindi magkatugma ang mga password",
  "Tạo mật khẩu": "Gumawa ng password",
  "Mật khẩu mới": "Bagong password",
  "Nhập lại mật khẩu": "Ilagay muli ang password",
  "Xác nhận tắt cảnh báo": "Kumpirmahin ang paghinto ng Alarm",
  "HỦY": "KANSELAHIN",
  "XÁC NHẬN": "KUMPIRMAHIN",
  "CẦN KIỂM TRA": "KAILANGANG SURIIN",
  "KIỂM TRA NHÀ": "SURIIN ANG BAHAY",
  "ĐÓNG NHẮC NHỞ": "ISARA ANG REMINDER",
  "SafeHome Security Alert": "Alerto sa Seguridad ng SafeHome",
  "Hãy chọn quyền vị trí Luôn cho phép trong Cài đặt ứng dụng":
      "Piliin ang pahintulot sa lokasyon na Palaging Payagan sa mga setting ng app",
  "Tài khoản Google cần tạo thêm mật khẩu để dùng các chức năng bảo mật.":
      "Kailangan ng karagdagang password ang iyong Google account para magamit ang mga feature ng seguridad.",
  "Alarm": "Alarm",
  "Bạn không có quyền thực hiện thao tác này。":
      "Wala kang pahintulot na gawin ang aksyong ito.",
  "Cài đặt": "Mga setting",
  "Cập nhật": "I-update",
  "Chọn ngôn ngữ": "Pumili ng wika",
  "Chưa có dữ liệu thiết bị để đánh giá":
      "Walang datos ng aparato para sa pagtatasa",
  "Chuyển quyền sở hữu cho thành viên khác":
      "Ilipat ang pagmamay-ari sa ibang miyembro",
  "Có": "Oo",
  "Cửa đã đóng an toàn": "Ligtas na nakasara ang pinto",
  "Đã xảy ra lỗi. Vui lòng thử lại.": "Nagkaroon ng error. Pakisubukang muli.",
  "Đang kiểm tra kết nối Hub": "Sinusuri ang koneksyon ng Hub",
  "Đang mở khi nhà ở chế độ Bảo vệ":
      "Bukas habang nasa Mode ng Proteksyon ang bahay",
  "Đang mở trong giờ Alarm": "Bukas sa oras ng Alarm",
  "Đang tải...": "Naglo-load...",
  "Hồ sơ, yêu cầu và lời mời tham gia":
      "Profile, mga kahilingan, at imbitasyon",
  "Hub chưa gửi trạng thái": "Wala pang status mula sa Hub",
  "Hub mất kết nối": "Nakadiskonekta ang Hub",
  "Hub tín hiệu bình thường": "Nakakonekta ang Hub",
  "Khóa đang mở khi nhà ở chế độ Bảo vệ":
      "Naka-unlock habang nasa Mode ng Proteksyon ang bahay",
  "Khóa đang mở trong giờ Alarm": "Naka-unlock sa oras ng Alarm",
  "Không có thông báo": "Walang notification",
  "Khu vực nguy hiểm": "Mapanganib na lugar",
  "Kiểm tra thiết bị trong nhà này": "Suriin ang mga aparato sa bahay na ito",
  "Mất điện lưới": "Nawala ang pangunahing suplay ng kuryente",
  "Mời người khác tham gia nhà này":
      "Mag-imbita ng isang tao na sumali sa bahay na ito",
  "Môi trường hiện tại": "Kasalukuyang kapaligiran",
  "MQTT mất kết nối": "Nakadiskonekta ang MQTT",
  "Ngôn ngữ": "Wika",
  "Nhà đã chia sẻ": "Ibinahaging bahay",
  "Nhà đang hoạt động bình thường": "Normal ang pagpapatakbo ng bahay",
  "Nhập email": "Ilagay ang email",
  "Phòng": "Kuwarto",
  "Quản trị viên": "Administrator",
  "Reminder": "Reminder",
  "SafeHome": "SafeHome",
  "Sóng yếu": "Mahina ang signal",
  "SOS": "SOS",
  "Tài khoản & hệ thống": "Account at system",
  "Tài khoản cá nhân": "Personal na account",
  "Tạo tài khoản": "Gumawa ng account",
  "Thành viên": "Miyembro",
  "Thành viên trong nhà": "Mga miyembro ng bahay",
  "Thành viên đang ở trong nhà": "Mga miyembrong kasalukuyang nasa bahay",
  "Thành viên đang ở ngoài": "Mga miyembrong kasalukuyang nasa labas",
  "Thành viên chưa xác định vị trí":
      "Mga miyembrong hindi matukoy ang lokasyon",
  "Thay đổi ngôn ngữ hiển thị": "Palitan ang wikang ipinapakita",
  "Thêm, đổi tên và sắp xếp phòng":
      "Magdagdag, magpalit ng pangalan, at mag-ayos ng mga kuwarto",
  "Thiết bị đang được giám sát": "Sinusubaybayan ang aparato",
  "Tiếng Anh": "Ingles",
  "Tiếng Hàn": "Koreano",
  "Tiếng Nhật": "Hapon",
  "Tiếng Trung": "Tsino",
  "Tiếng Việt": "Biyetnames",
  "Toàn bộ thiết bị": "Lahat ng aparato",
  "Vai trò": "Tungkulin",
  "Về nhà": "Nasa bahay",
  "Xem và quản lý quyền thành viên":
      "Tingnan at pamahalaan ang mga tungkulin ng miyembro",
  "Xóa": "Tanggalin",
  "Xóa nhà": "Tanggalin ang bahay",
  "Xoá toàn bộ dữ liệu và thiết bị": "Tanggalin ang lahat ng datos at aparato",
  "TẮT CẢNH BÁO": "I-OFF ANG ALERTO",
  "Đã tạo nhà": "Nagawa na ang bahay",

  "Mode Bảo vệ thủ công đã bật":
      "Naka-enable ang manu-manong Mode ng Proteksyon",
  "Báo động không lặp lại.": "Hindi uulit ang Alarm.",
  "Báo động lặp sau \$securityModeRepeatMinutes phút nếu sự cố vẫn còn.":
      "Uulit ang Alarm pagkalipas ng \$securityModeRepeatMinutes minuto kung magpapatuloy ang problema.",
  "\$actorName đã bật Mode Bảo vệ thủ công cho \"\$homeName\". Chế độ này chỉ tắt khi một thành viên có quyền chủ động chuyển về Bình thường. \$repeatMessage":
      "Manu-manong in-on ni \$actorName ang Mode ng Proteksyon para sa \"\$homeName\". Mananatiling naka-on ang mode na ito hanggang ibalik ito sa Normal ng miyembrong may pahintulot. \$repeatMessage",
  "Bạn đã bật Alarm cho nhà \"\$homeName\".":
      "In-enable mo ang Alarm para sa bahay na \"\$homeName\".",
  "Bạn đã tắt toàn bộ Alarm của nhà \"\$homeName\".":
      "In-off mo ang lahat ng Alarm ng bahay na \"\$homeName\".",
  "Thành viên mới": "Bagong miyembro",
  "Thành viên rời nhà": "Umalis ang miyembro sa bahay",
  "\$displayMemberName đã rời khỏi nhà \"\$homeName\".":
      "Umalis si \$displayMemberName sa bahay na \"\$homeName\".",
  "\$actorName đã đổi vai trò của \$memberName từ \$oldRoleName thành \$newRoleName trong nhà \"\$homeName\".":
      "Pinalitan ni \$actorName ang tungkulin ni \$memberName mula \$oldRoleName patungong \$newRoleName sa bahay na \"\$homeName\".",
  "Còn \$count tin nhắn chưa đọc": "May \$count hindi pa nababasang mensahe",
  "Hãy an tâm nghỉ ngơi.": "Makapagpahinga ka nang panatag.",
  "Có thiết bị chưa an toàn.": "May mga aparatong hindi ligtas.",
  "SafeHome đang cập nhật vị trí": "Ina-update ng SafeHome ang lokasyon",
  "Đang theo dõi để tự động bật Chế độ Bảo vệ.":
      "Sinusubaybayan upang awtomatikong i-on ang Mode ng Proteksyon.",
  "Dùng vị trí để tự động bật Chế độ Bảo vệ khi mọi người rời nhà.":
      "Ginagamit ang lokasyon upang awtomatikong i-on ang Mode ng Proteksyon kapag umalis ang lahat sa bahay.",
  "CẢNH BÁO SOS": "ALERTO NG SOS",
  "CẢNH BÁO KHÓI / CHÁY": "ALERTO SA USOK / SUNOG",
  "CẢNH BÁO NGẬP NƯỚC": "ALERTO SA BAHA",
  "CẢNH BÁO RÒ KHÍ": "ALERTO SA TAGAS NG GAS",
  "CẢNH BÁO CỬA": "ALERTO SA PINTO",
  "CẢNH BÁO AN NINH": "ALERTO SA SEGURIDAD",
  "Không thể xác nhận với SafeHome. Hãy kiểm tra kết nối và thử lại.":
      "Hindi makumpirma ng SafeHome. Suriin ang koneksyon at subukang muli.",
  "Chỉ tắt cảnh báo khi bạn đã kiểm tra tình trạng trong nhà.\n\nBạn chắc chắn muốn tắt cảnh báo?":
      "I-off lamang ang alerto pagkatapos suriin ang kalagayan ng bahay.\n\nSigurado ka bang gusto mong i-off ang alerto?",
  "🚨 SafeHome phát hiện cảnh báo": "🚨 May natukoy na alerto ang SafeHome",
  "Mở SafeHome để kiểm tra ngay.":
      "Buksan ang SafeHome upang suriin ito ngayon.",
  "\$count tin nhắn mới": "\$count bagong mensahe",
  "Tin nhắn HomeChat": "Mensahe sa HomeChat",
  "\$senderName đã gửi một tin nhắn": "Nagpadala ng mensahe si \$senderName",
  "Bạn có tin nhắn mới": "May bago kang mensahe",
  "Mode Bảo vệ sẽ chỉ báo động một lần":
      "Isang beses lang mag-aalerto ang Mode ng Proteksyon",
  "Mode Bảo vệ sẽ lặp báo động sau \$minutes phút":
      "Uulit ang alerto ng Mode ng Proteksyon pagkalipas ng \$minutes minuto",
  "Đã gửi yêu cầu gia nhập \$count nhà":
      "Naipadala ang mga kahilingang sumali sa \$count bahay",
  "\$requesterName đang xin gia nhập nhà \"\$homeName\".":
      "Humiling si \$requesterName na sumali sa bahay na \"\$homeName\".",
  "Bạn đã xoá nhà \"\$homeName\".": "Tinanggal mo ang bahay na \"\$homeName\".",
  "Bạn đã gửi yêu cầu chuyển quyền chủ nhà \"\$homeName\" cho \$email.":
      "Nagpadala ka kay \$email ng kahilingan na ilipat ang pagmamay-ari ng bahay na \"\$homeName\".",
  "\$actorName muốn chuyển quyền chủ nhà \"\$homeName\" cho bạn.":
      "Gustong ilipat ni \$actorName sa iyo ang pagmamay-ari ng bahay na \"\$homeName\".",
  "\$actorName đã mời bạn tham gia nhà \"\$homeName\".":
      "Inimbitahan ka ni \$actorName na sumali sa bahay na \"\$homeName\".",
  "SafeHome đang xoá thiết bị \"\$deviceName\" khỏi nhà \"\$homeName\".":
      "Tinatanggal ng SafeHome ang \"\$deviceName\" mula sa bahay na \"\$homeName\".",
  "Thiết bị \"\$deviceName\" đã xuất hiện trong \"\$homeName\".":
      "Naidagdag ang aparatong \"\$deviceName\" sa bahay na \"\$homeName\".",
  "Bạn đã tạo nhà \"\$name\".": "Nagawa mo na ang bahay na \"\$name\".",
  "\$actorName đã cập nhật tên nhà thành \"\$newName\" và thay đổi địa chỉ.":
      "Pinalitan ni \$actorName ng \"\$newName\" ang pangalan ng bahay at binago rin ang address nito.",
  "\$actorName đã đổi tên nhà thành \"\$newName\".":
      "Pinalitan ni \$actorName ng \"\$newName\" ang pangalan ng bahay.",
  "\$actorName đã cập nhật địa chỉ của nhà \"\$newName\".":
      "In-update ni \$actorName ang address ng bahay na \"\$newName\".",
  "\$actorName đã đổi tên thiết bị \"\$oldDeviceName\" thành \"\$newName\" trong nhà \"\$homeName\".":
      "Pinalitan ni \$actorName ng \"\$newName\" ang pangalan ng aparatong \"\$oldDeviceName\" sa bahay na \"\$homeName\".",
  "Đang ghép nối: \$seconds giây": "Ipinapares: \$seconds segundo",
  "Chế độ thêm thiết bị đã được mở trong nhà \"\$homeName\" trong \$seconds giây.":
      "Naka-enable ang pagpapares ng aparato sa bahay na \"\$homeName\" sa loob ng \$seconds segundo.",
  "Khoảng thời gian phải nằm trong khung Alarm (\$start → \$end)":
      "Dapat nasa loob ng iskedyul ng Alarm ang panahon ng pag-pause (\$start → \$end)",
  "\$passCount/\$total bài test đạt\n\n":
      "\$passCount/\$total pagsusuri ang pumasa\n\n",
  "\$name chưa cập nhật số điện thoại trong hồ sơ.":
      "Hindi pa nagdagdag si \$name ng numero ng telepono sa profile.",
  "Tin nhắn mới trong \$homeName": "Bagong mensahe sa \$homeName",
  "\$current/\$total kết quả": "Resulta \$current/\$total",
  "Đang trả lời \$name": "Tumutugon kay \$name",
  "\"\$name\" phát hiện khói trong \"\$homeName\".":
      "Natukoy ng \"\$name\" ang usok sa bahay na \"\$homeName\".",
  "\"\$name\" đã trở lại trạng thái bình thường.":
      "Bumalik na sa normal ang \"\$name\".",
  "\"\$name\" vừa kích hoạt SOS trong \"\$homeName\".":
      "Na-trigger ng \"\$name\" ang SOS sa bahay na \"\$homeName\".",
  "\"\$name\" đã hết trạng thái SOS.": "Wala na sa SOS status ang \"\$name\".",
  "\"\$name\" báo bị tháo/cạy trong \"\$homeName\".":
      "Natukoy ng \"\$name\" ang pakikialam sa bahay na \"\$homeName\".",
  "\"\$name\" đã hết cảnh báo tháo/cạy.":
      "Natapos na ang alerto sa pakikialam para sa \"\$name\".",
  "\"\$name\" đã đóng trong \"\$homeName\".":
      "Nagsara ang \"\$name\" sa bahay na \"\$homeName\".",
  "\"\$name\" đang mở trong \"\$homeName\".":
      "Bukas ang \"\$name\" sa bahay na \"\$homeName\".",
  "\"\$name\" trong \"\$homeName\" đang yếu pin.":
      "Mahina ang baterya ng \"\$name\" sa bahay na \"\$homeName\".",
  "\"\$name\" trong \"\$homeName\" đã mất kết nối.":
      "Nag-offline ang \"\$name\" sa bahay na \"\$homeName\".",
  "\"\$name\" trong \"\$homeName\" đã kết nối trở lại.":
      "Online na muli ang \"\$name\" sa bahay na \"\$homeName\".",
  "\"\$name\" ghi nhận nhiệt độ cao trong \"\$homeName\".":
      "Nagtala ang \"\$name\" ng mataas na temperatura sa bahay na \"\$homeName\".",
  "\"\$name\" ghi nhận độ ẩm cao trong \"\$homeName\".":
      "Nagtala ang \"\$name\" ng mataas na halumigmig sa bahay na \"\$homeName\".",
  "Có nút SOS vừa được kích hoạt": "May na-activate na pindutan ng SOS",
  "Có dấu hiệu khói hoặc cháy": "May natukoy na usok o sunog",
  "Có dấu hiệu ngập nước": "May natukoy na pagbaha",
  "Có dấu hiệu rò khí": "May natukoy na tagas ng gas",
  "Có cửa đang mở hoặc thiết bị bị tháo":
      "May bukas na pinto o may aparatong pinakialaman",
  "Có thiết bị đang cảnh báo": "May aparatong nag-aalerto",
  "Nếu chưa có ai xác nhận, SafeHome sẽ chuyển sang gọi điện khẩn cấp.":
      "Kung walang magkumpirma, magsasagawa ang SafeHome ng emergency call.",
  "Báo lại lúc \$time nếu vấn đề chưa được xử lý.":
      "Mag-aalerto muli sa \$time kung hindi pa nalulutas ang problema.",
  "Sẽ báo lại theo lịch Alarm đã cài nếu vấn đề chưa được xử lý.":
      "Mag-aalerto muli ayon sa iskedyul ng Alarm kung hindi pa nalulutas ang problema.",
  "\"\$deviceName\" đã đóng trong \"\$resolvedHomeName\".":
      "Nagsara ang \"\$deviceName\" sa bahay na \"\$resolvedHomeName\".",
  "\"\$deviceName\" đang mở trong \"\$resolvedHomeName\".":
      "Bukas ang \"\$deviceName\" sa bahay na \"\$resolvedHomeName\".",
  "\$count nhà đã chọn": "\$count bahay ang napili",
  "🚨 \$count nhà không an toàn\$suffix":
      "🚨 \$count bahay ang hindi ligtas\$suffix",
  "⚠️ \$count nhà cần chú ý\$suffix":
      "⚠️ \$count bahay ang kailangang bigyang-pansin\$suffix",
  "✅ \$count nhà an toàn": "✅ \$count ligtas na bahay",
  "\$count nhà đang được theo dõi": "\$count bahay ang sinusubaybayan",
  "\$minutes phút": "\$minutes minuto",
  "Đã cài Reminder cho \$updatedHomes nhà.":
      "Naitakda ang Reminder para sa \$updatedHomes bahay.",
  "Đã cài Alarm cho \$updatedDevices thiết bị trong \$updatedHomes nhà.\n":
      "Naitakda ang Alarm para sa \$updatedDevices aparato sa \$updatedHomes bahay.\n",
  "Đã chia sẻ các nhà bạn có quyền.\n\n\$skipped nhà bị bỏ qua vì bạn không có quyền chia sẻ.":
      "Naibahagi ang mga bahay na pinamamahalaan mo.\n\nNilaktawan ang \$skipped bahay dahil wala kang pahintulot na ibahagi ang mga ito.",
  "Đã áp dụng Alarm cho \$count thiết bị an ninh":
      "Inilapat ang Alarm sa \$count aparatong panseguridad",
  "Áp dụng cùng một lịch cho \$count thiết bị an ninh":
      "Ilapat ang parehong iskedyul sa \$count aparatong panseguridad",
  "\$count phút trước": "\$count minuto ang nakalipas",
  "\$count giờ trước": "\$count oras ang nakalipas",
  "\${count}h trước": "\${count} oras ang nakalipas",
  "\${hours}h\$minutes' trước":
      "\${hours} oras at \${minutes} minuto ang nakalipas",
  "\$count ngày trước": "\$count araw ang nakalipas",
  "\$count tháng trước": "\$count buwan ang nakalipas",
  "Bạn chắc chắn muốn xoá \$name khỏi nhà này?":
      "Sigurado ka bang gusto mong alisin si \$name sa bahay na ito?",
  "\$targetEmail\nXin gia nhập \"\$homeName\"":
      "\$targetEmail\nHumihiling na sumali sa \"\$homeName\"",
  "Xin gia nhập \"\$homeName\"": "Humihiling na sumali sa \"\$homeName\"",
  "Bạn được mời nhận quyền nhà \"\$homeName\"":
      "Inimbitahan kang tanggapin ang pagmamay-ari ng bahay na \"\$homeName\"",
  "\$ownerEmail\nMời bạn gia nhập \"\$homeName\"":
      "\$ownerEmail\nIniimbitahan kang sumali sa \"\$homeName\"",
  "Mời bạn gia nhập \"\$homeName\"":
      "Iniimbitahan kang sumali sa \"\$homeName\"",
  "Cần kiểm tra: \$joined": "Kailangang bigyang-pansin: \$joined",
  "Cập nhật \$value": "In-update ang \$value",
  "Hãy thêm thiết bị SafeHome đầu tiên để bắt đầu theo dõi nhà.":
      "Idagdag ang una mong aparatong SafeHome upang simulang subaybayan ang bahay na ito.",
  "Kiểm tra cảnh báo khẩn cấp trước, sau đó liên hệ thành viên trong nhà nếu cần.":
      "Suriin muna ang mga alertong pang-emergency, pagkatapos ay kontakin ang mga miyembro ng bahay kung kailangan.",
  "Không có thành viên nào ở nhà nhưng cửa hoặc khóa đang mở, hãy kiểm tra ngay.":
      "Walang miyembro sa bahay ngunit may bukas na pinto o lock. Suriin ito ngayon.",
  "Kiểm tra cửa hoặc khóa đang mở trước khi giữ nhà ở chế độ Bảo vệ.":
      "Suriin ang bukas na pinto o lock bago panatilihin ang bahay na ito sa Mode ng Proteksyon.",
  "Có thể vẫn có người ở nhà; nếu đúng, nên chuyển về Bình thường.":
      "Maaaring may tao pa sa bahay. Kung gayon, ibalik ang bahay sa Normal.",
  "Có thành viên chưa xác định vị trí, hãy nhắc họ mở app hoặc kiểm tra quyền vị trí.":
      "Hindi matukoy ang lokasyon ng ilang miyembro. Hilingin sa kanila na buksan ang app o suriin ang pahintulot sa lokasyon.",
  "Có thiết bị mất kết nối, hãy kiểm tra pin, nguồn hoặc vị trí đặt thiết bị.":
      "May aparatong nadiskonekta. Tingnan ang baterya, kuryente, o puwesto nito.",
  "Có thiết bị pin yếu, nên thay pin sớm để tránh mất cảnh báo.":
      "May aparatong mahina ang baterya. Palitan ito agad upang hindi mapalampas ang mga alerto.",
  "Bạn chưa đặt Reminder, nên tạo lịch nhắc kiểm tra nhà định kỳ.":
      "Hindi pa nakatakda ang Reminder. Gumawa ng iskedyul upang regular na suriin ang iyong bahay.",
  "Bạn chưa đặt lịch Alarm, nên bật bảo vệ theo khung giờ thường vắng nhà.":
      "Hindi pa nakatakda ang iskedyul ng Alarm. I-enable ang proteksyon sa mga oras na karaniwan kang wala.",
  "Không có việc cần xử lý ngay, bạn chỉ cần tiếp tục theo dõi trạng thái nhà.":
      "Walang kailangang aksyunan agad. Patuloy lang na subaybayan ang bahay na ito.",
  "Lặp sau \$minutes phút": "Ulitin pagkalipas ng \$minutes minuto",
  "Đang dùng • \$repeatText": "Aktibo • \$repeatText",
  "Giám sát an ninh • \$repeatText": "Pagsubaybay sa seguridad • \$repeatText",
  "Gia đình: \$mode": "Mode ng bahay: \$mode",
  "Gợi ý xử lý": "Mga mungkahing aksyon",
  "Phát hiện \$count vấn đề cần xử lý":
      "May natukoy na \$count problemang kailangang aksyunan",
  "Hôm nay các cửa đã được sử dụng \$count lần":
      "Ginamit ang mga pinto nang \$count beses ngayong araw",
  "Đã ghi nhận \$count hoạt động gần đây":
      "Naitala ang \$count kamakailang aktibidad",
  "Hệ thống: Cần kiểm tra \$issueCount mục":
      "System: May \$issueCount item na kailangang suriin",
  "FCM token đã sẵn sàng trên điện thoại này.":
      "Handa na ang FCM token sa teleponong ito.",
  "FCM token đã sẵn sàng, nhưng Auto rời khỏi nhà còn thiếu điều kiện.":
      "Handa na ang FCM token, ngunit may kulang pang kinakailangan para sa Awtomatikong Proteksyon kapag wala sa bahay.",
  "Hiện có \$emergencyTotal thiết bị khẩn cấp. Khuyến nghị tối thiểu: báo khói và SOS.":
      "May \$emergencyTotal aparatong pang-emergency. Inirerekomendang minimum: sensor ng usok at SOS.",
  "Bạn chắc chắn muốn chuyển quyền chủ nhà cho:\n\$targetEmail?":
      "Ilipat ang pagmamay-ari ng bahay kay:\n\$targetEmail?",
  "\$count cửa đã đóng an toàn": "\$count pintong ligtas na nakasara",
  "\$count cửa và khóa đã an toàn": "Ligtas na ang \$count pinto at lock",
  "\$count thiết bị đang được theo dõi": "\$count aparato ang sinusubaybayan",
  "Cập nhật \$timeText": "Na-update \$timeText",
  "Dữ liệu gần nhất cập nhật \$count phút trước":
      "Huling na-update ang datos \$count minuto ang nakalipas",
  "Dữ liệu gần nhất cập nhật \$count giờ trước":
      "Huling na-update ang datos \$count oras ang nakalipas",
  "Thành viên trong nhà: \$count": "Mga miyembrong nasa bahay: \$count",
  "Thành viên bên ngoài: \$count": "Mga miyembrong nasa labas: \$count",
  "Chưa xác định vị trí: \$count": "Hindi matukoy ang lokasyon: \$count",
  "Môi trường hiện tại: \$environment":
      "Kasalukuyang kapaligiran: \$environment",
  "\$name: Đang mở khi nhà ở chế độ Bảo vệ":
      "\$name: Bukas habang nasa Mode ng Proteksyon ang bahay",
  "An tâm hơn trong từng ngôi nhà": "Panatag sa bawat bahay",
  "Báo động SafeHome": "Alarm ng SafeHome",
  "Có cảnh báo an ninh cần kiểm tra ngay.":
      "May alerto sa seguridad na kailangang suriin agad.",
  "Có cảnh báo cần kiểm tra": "May alertong kailangang suriin",
  "Tự đóng sau \$time": "Awtomatikong magsasara sa loob ng \$time",
  "Ngày trong tuần": "Mga araw ng linggo",
  "Hoặc": "O",
  "Giờ bắt đầu và kết thúc không được trùng nhau":
      "Hindi maaaring magkapareho ang oras ng pagsisimula at pagtatapos",
  "Giờ kết thúc phải sau thời điểm hiện tại":
      "Dapat mas huli sa kasalukuyang oras ang oras ng pagtatapos",
  "Khoảng tạm tắt không hợp lệ": "Di-wastong saklaw ng pag-pause ng Alarm",
  "Khoảng tạm tắt không trùng với lịch Alarm nào đang bật":
      "Hindi nag-o-overlap ang saklaw ng pag-pause sa anumang aktibong iskedyul ng Alarm",
};
