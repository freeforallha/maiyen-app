part of '../all_home_page.dart';

extension _AllHomeLayoutPart on _AllHomeState {
  Widget _buildAllHomePage(BuildContext context) {
    final grouped = groupedHomes();

    return Scaffold(
      backgroundColor: MaiYenColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leadingWidth: 54,

        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            tooltip: _strings.t("Quay lại"),
            onPressed: () {
              Navigator.maybePop(context);
            },
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            style:
                IconButton.styleFrom(
                  foregroundColor: MaiYenColors.textPrimary,
                  backgroundColor: Colors.transparent,
                  shape: const CircleBorder(),
                ).copyWith(
                  overlayColor: WidgetStatePropertyAll(
                    MaiYenColors.primary.withValues(alpha: 0.10),
                  ),
                ),
          ),
        ),

        title: isSearching
            ? TextField(
                controller: searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: _strings.t("Tìm nhà..."),
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) {
                  setState(() {
                    search = value.toLowerCase().trim();
                  });
                },
              )
            : Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: showAllHomeSummarySheet,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 4,
                    ),
                    child: const MaiYenWordmark(
                      suffix: 'Home',
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      leafSize: 24,
                    ),
                  ),
                ),
              ),

        actions: [
          IconButton(
            tooltip: isSearching
                ? _strings.t("Đóng tìm kiếm")
                : _strings.t("Tìm nhà"),
            icon: Icon(
              isSearching ? Icons.close_rounded : Icons.search_rounded,
              size: 23,
            ),
            style:
                IconButton.styleFrom(
                  foregroundColor: MaiYenColors.textPrimary,
                  backgroundColor: Colors.transparent,
                  shape: const CircleBorder(),
                ).copyWith(
                  overlayColor: WidgetStatePropertyAll(
                    MaiYenColors.primary.withValues(alpha: 0.10),
                  ),
                ),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;

                if (!isSearching) {
                  search = "";
                  searchController.clear();
                }
              });
            },
          ),

          if (selectedHomes.isNotEmpty)
            IconButton(
              tooltip: _strings.t("Bỏ chọn"),
              icon: const Icon(Icons.deselect_rounded, size: 22),
              style:
                  IconButton.styleFrom(
                    foregroundColor: MaiYenColors.danger,
                    backgroundColor: Colors.transparent,
                    shape: const CircleBorder(),
                  ).copyWith(
                    overlayColor: WidgetStatePropertyAll(
                      MaiYenColors.danger.withValues(alpha: 0.10),
                    ),
                  ),
              onPressed: () {
                setState(() {
                  selectedHomes.clear();
                });
              },
            ),

          const SizedBox(width: 6),
        ],
      ),

      body: Stack(
        children: [
          Container(
            color: MaiYenColors.background,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                12,
                6,
                12,
                selectedHomes.isEmpty ? 16 : 370,
              ),
              children: grouped.entries.map((entry) {
                final groupKey = entry.key;
                final ids = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildSectionTitle(groupKey, ids),
                    const SizedBox(height: 6),
                  ],
                );
              }).toList(),
            ),
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            left: 12,
            right: 12,
            bottom: selectedHomes.isEmpty ? -360 : 12,
            child: SafeArea(
              top: false,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: selectedHomes.isEmpty ? 0 : 1,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.schedule_rounded,
                            color: Colors.blueAccent,
                          ),
                        ),
                        title: Text(
                          _strings.t("Đặt nhắc nhở / báo động nhà đã chọn"),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(selectedHomeCountText()),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: setSelectedHomesAlarm,
                      ),

                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.share_rounded,
                            color: Colors.green,
                          ),
                        ),
                        title: Text(
                          _strings.t("Chia sẻ nhà đã chọn"),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(selectedHomeCountText()),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _shareSelectedHomes,
                      ),

                      const Divider(height: 8),

                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.people_alt_rounded,
                            color: Colors.orange,
                          ),
                        ),
                        title: Text(
                          _strings.t("Mở danh sách chia sẻ nhà"),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(selectedHomeCountText()),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _manageSelectedHomeShares,
                      ),

                      const Divider(height: 8),

                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.delete_rounded,
                            color: Colors.red,
                          ),
                        ),
                        title: Text(
                          _strings.t("Xoá các nhà đã chọn?"),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                        subtitle: Text(selectedHomeCountText()),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: confirmDeleteSelected,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
