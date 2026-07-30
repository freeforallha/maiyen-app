part of '../all_home_page.dart';

extension _AllHomeAlarmTimePart on _AllHomeState {
  Future<String?> _inputSelectedHomesAlarmTime(String title, String initial) async {
    final parts = initial.split(":");

    String hourText = parts.isNotEmpty ? parts[0].padLeft(2, "0") : "23";
    String minuteText = parts.length > 1 ? parts[1].padLeft(2, "0") : "00";

    const suggestions = [
      ["23", "00"],
      ["00", "00"],
      ["01", "00"],
      ["04", "00"],
      ["05", "00"],
      ["06", "00"],
    ];

    bool isValidTime(String value) {
      return RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').hasMatch(value.trim());
    }

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void submit() {
              final h = hourText.trim().padLeft(2, "0");
              final m = minuteText.trim().padLeft(2, "0");
              final value = "$h:$m";

              if (!isValidTime(value)) {
                showTopToast(
                  dialogContext,
                  _strings.t("Giờ không hợp lệ"),
                  color: Colors.red,
                  icon: Icons.schedule_rounded,
                );
                return;
              }

              Navigator.of(dialogContext).pop(value);
            }

            Widget suggestionChip(List<String> s) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: SizedBox(
                    width: double.infinity,
                    child: ActionChip(
                      label: Center(child: Text("${s[0]}:${s[1]}")),
                      onPressed: () {
                        setDialogState(() {
                          hourText = s[0];
                          minuteText = s[1];
                        });
                      },
                    ),
                  ),
                ),
              );
            }

            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: ValueKey("all_home_alarm_hour_$hourText"),
                          initialValue: hourText,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          maxLength: 2,
                          decoration: InputDecoration(
                            labelText: _strings.t("Giờ"),
                            counterText: "",
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            hourText = value.trim();
                          },
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          ":",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          key: ValueKey("all_home_alarm_minute_$minuteText"),
                          initialValue: minuteText,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          maxLength: 2,
                          decoration: InputDecoration(
                            labelText: _strings.t("Phút"),
                            counterText: "",
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            minuteText = value.trim();
                          },
                          onFieldSubmitted: (_) => submit(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Column(
                    children: [
                      Row(
                        children: suggestions
                            .take(3)
                            .map(suggestionChip)
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: suggestions
                            .skip(3)
                            .map(suggestionChip)
                            .toList(),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(_strings.t("Huỷ")),
                ),
                ElevatedButton(
                  onPressed: submit,
                  child: Text(_strings.t("OK")),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _selectedHomesAlarmRepeatLabel(int minutes) {
    if (minutes <= 0) {
      return _strings.t("Không lặp lại");
    }

    return _strings.minuteText(minutes);
  }
}
