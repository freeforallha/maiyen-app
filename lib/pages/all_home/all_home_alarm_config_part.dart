part of '../all_home_page.dart';

extension _AllHomeAlarmConfigPart on _AllHomeState {
  Future<Map<String, dynamic>?> _inputSelectedHomesAlarmConfig() async {
    var start = "23:00";
    var end = "06:00";
    var repeatMinutes = 30;
    final selectedDays = <int>{1, 2, 3, 4, 5, 6, 7};

    final dayItems = [
      (
        value: 1,
        label: _strings.choose(
          vi: "Thứ 2",
          my: "တနင်္လာနေ့",
          fil: "Lunes",
          km: "ថ្ងៃចន្ទ",
          en: "Monday",
          zh: "星期一",
          ko: "월요일",
          ja: "月曜日",
          de: "Montag",
          ru: "Понедельник",
          fr: "Lundi",
          es: "Lunes",
          id: "Senin",
          th: "วันจันทร์",
          ms: "Isnin",
          lo: "ວັນຈັນ",
          ta: "திங்கட்கிழமை",
          pt: "segunda-feira",
          tet: "Segunda-feira",
        ),
      ),
      (
        value: 2,
        label: _strings.choose(
          vi: "Thứ 3",
          my: "အင်္ဂါနေ့",
          fil: "Martes",
          km: "ថ្ងៃអង្គារ",
          en: "Tuesday",
          zh: "星期二",
          ko: "화요일",
          ja: "火曜日",
          de: "Dienstag",
          ru: "Вторник",
          fr: "Mardi",
          es: "Martes",
          id: "Selasa",
          th: "วันอังคาร",
          ms: "Selasa",
          lo: "ວັນອັງຄານ",
          ta: "செவ்வாய்க்கிழமை",
          pt: "terça-feira",
          tet: "Tersa-feira",
        ),
      ),
      (
        value: 3,
        label: _strings.choose(
          vi: "Thứ 4",
          my: "ဗုဒ္ဓဟူးနေ့",
          fil: "Miyerkules",
          km: "ថ្ងៃពុធ",
          en: "Wednesday",
          zh: "星期三",
          ko: "수요일",
          ja: "水曜日",
          de: "Mittwoch",
          ru: "Среда",
          fr: "Mercredi",
          es: "Miércoles",
          id: "Rabu",
          th: "วันพุธ",
          ms: "Rabu",
          lo: "ວັນພຸດ",
          ta: "புதன்கிழமை",
          pt: "quarta-feira",
          tet: "Kuarta-feira",
        ),
      ),
      (
        value: 4,
        label: _strings.choose(
          vi: "Thứ 5",
          my: "ကြာသပတေးနေ့",
          fil: "Huwebes",
          km: "ថ្ងៃព្រហស្បតិ៍",
          en: "Thursday",
          zh: "星期四",
          ko: "목요일",
          ja: "木曜日",
          de: "Donnerstag",
          ru: "Четверг",
          fr: "Jeudi",
          es: "Jueves",
          id: "Kamis",
          th: "วันพฤหัสบดี",
          ms: "Khamis",
          lo: "ວັນພະຫັດ",
          ta: "வியாழக்கிழமை",
          pt: "quinta-feira",
          tet: "Kinta-feira",
        ),
      ),
      (
        value: 5,
        label: _strings.choose(
          vi: "Thứ 6",
          my: "သောကြာနေ့",
          fil: "Biyernes",
          km: "ថ្ងៃសុក្រ",
          en: "Friday",
          zh: "星期五",
          ko: "금요일",
          ja: "金曜日",
          de: "Freitag",
          ru: "Пятница",
          fr: "Vendredi",
          es: "Viernes",
          id: "Jumat",
          th: "วันศุกร์",
          ms: "Jumaat",
          lo: "ວັນສຸກ",
          ta: "வெள்ளிக்கிழமை",
          pt: "sexta-feira",
          tet: "Sesta-feira",
        ),
      ),
      (
        value: 6,
        label: _strings.choose(
          vi: "Thứ 7",
          my: "စနေနေ့",
          fil: "Sabado",
          km: "ថ្ងៃសៅរ៍",
          en: "Saturday",
          zh: "星期六",
          ko: "토요일",
          ja: "土曜日",
          de: "Samstag",
          ru: "Суббота",
          fr: "Samedi",
          es: "Sábado",
          id: "Sabtu",
          th: "วันเสาร์",
          ms: "Sabtu",
          lo: "ວັນເສົາ",
          ta: "சனிக்கிழமை",
          pt: "sábado",
          tet: "Sábadu",
        ),
      ),
      (
        value: 7,
        label: _strings.choose(
          vi: "Chủ nhật",
          my: "တနင်္ဂနွေနေ့",
          fil: "Linggo",
          km: "ថ្ងៃអាទិត្យ",
          en: "Sunday",
          zh: "星期日",
          ko: "일요일",
          ja: "日曜日",
          de: "Sonntag",
          ru: "Воскресенье",
          fr: "Dimanche",
          es: "Domingo",
          id: "Minggu",
          th: "วันอาทิตย์",
          ms: "Ahad",
          lo: "ວັນອາທິດ",
          ta: "ஞாயிற்றுக்கிழமை",
          pt: "domingo",
          tet: "Domingu",
        ),
      ),
    ];

    return MaiYenNavigation.showModalSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (innerContext, setSheetState) {
            Future<void> chooseTime(bool isStart) async {
              final picked = await _inputSelectedHomesAlarmTime(
                isStart
                    ? _strings.t("Giờ bắt đầu báo động")
                    : _strings.t("Giờ kết thúc báo động"),
                isStart ? start : end,
              );

              if (picked == null || !sheetContext.mounted) {
                return;
              }

              setSheetState(() {
                if (isStart) {
                  start = picked;
                } else {
                  end = picked;
                }
              });
            }

            void toggleDay(int day) {
              setSheetState(() {
                if (selectedDays.contains(day)) {
                  // Giữ tối thiểu một ngày để lịch Alarm luôn hợp lệ.
                  if (selectedDays.length > 1) {
                    selectedDays.remove(day);
                  }
                } else {
                  selectedDays.add(day);
                }
              });
            }

            Widget timeButton({
              required String label,
              required String value,
              required VoidCallback onTap,
            }) {
              return Expanded(
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: MaiYenColors.border),
                    ),
                    child: Column(
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            color: MaiYenColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          value,
                          style: const TextStyle(
                            color: MaiYenColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            Widget dayButton(int value, String label) {
              final selected = selectedDays.contains(value);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    onTap: () => toggleDay(value),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      height: 42,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? MaiYenColors.primary.withValues(alpha: 0.12)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? MaiYenColors.primary.withValues(alpha: 0.55)
                              : MaiYenColors.border,
                          width: selected ? 1.3 : 1,
                        ),
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            label,
                            maxLines: 1,
                            style: TextStyle(
                              color: selected
                                  ? MaiYenColors.primary
                                  : MaiYenColors.textPrimary,
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            return SafeArea(
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(innerContext).viewInsets.bottom,
                ),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(innerContext).size.height * 0.92,
                  ),
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 44,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: MaiYenColors.border,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: MaiYenColors.primary.withValues(
                                  alpha: 0.10,
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.security_rounded,
                                color: MaiYenColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _strings.t("Đặt báo động cho nhà"),
                                    style: const TextStyle(
                                      color: MaiYenColors.textPrimary,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    selectedHomeCountText(),
                                    style: const TextStyle(
                                      color: MaiYenColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            timeButton(
                              label: _strings.t("Bắt đầu"),
                              value: start,
                              onTap: () => chooseTime(true),
                            ),
                            const SizedBox(width: 10),
                            timeButton(
                              label: _strings.t("Kết thúc"),
                              value: end,
                              onTap: () => chooseTime(false),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: MaiYenColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: MaiYenColors.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _strings.t("Thời gian lặp lại"),
                                  style: const TextStyle(
                                    color: MaiYenColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: repeatMinutes,
                                    isExpanded: true,
                                    alignment: Alignment.centerRight,
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: MaiYenColors.textSecondary,
                                    ),
                                    items: [
                                      DropdownMenuItem(
                                        value: 0,
                                        child: Text(
                                          _strings.t("Không lặp lại"),
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 15,
                                        child: Text(_strings.t("15 phút")),
                                      ),
                                      DropdownMenuItem(
                                        value: 30,
                                        child: Text(_strings.t("30 phút")),
                                      ),
                                      DropdownMenuItem(
                                        value: 60,
                                        child: Text(_strings.t("60 phút")),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      if (value == null) {
                                        return;
                                      }

                                      setSheetState(() {
                                        repeatMinutes = value;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(11, 10, 11, 12),
                          decoration: BoxDecoration(
                            color: MaiYenColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: MaiYenColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 3),
                                child: Text(
                                  _strings.t("Ngày trong tuần"),
                                  style: const TextStyle(
                                    color: MaiYenColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 9),
                              Row(
                                children: [
                                  dayButton(
                                    dayItems[0].value,
                                    dayItems[0].label,
                                  ),
                                  dayButton(
                                    dayItems[1].value,
                                    dayItems[1].label,
                                  ),
                                  dayButton(
                                    dayItems[2].value,
                                    dayItems[2].label,
                                  ),
                                  dayButton(
                                    dayItems[3].value,
                                    dayItems[3].label,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  dayButton(
                                    dayItems[4].value,
                                    dayItems[4].label,
                                  ),
                                  dayButton(
                                    dayItems[5].value,
                                    dayItems[5].label,
                                  ),
                                  dayButton(
                                    dayItems[6].value,
                                    dayItems[6].label,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: MaiYenColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              final days = selectedDays.toList()..sort();

                              Navigator.pop(sheetContext, {
                                "start": start,
                                "end": end,
                                "repeatMinutes": repeatMinutes,
                                "days": days,
                              });
                            },
                            icon: const Icon(Icons.done_all_rounded),
                            label: Text(_strings.t("Xác nhận")),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
