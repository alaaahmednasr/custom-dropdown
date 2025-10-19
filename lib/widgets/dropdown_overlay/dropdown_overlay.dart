part of '../../custom_dropdown.dart';

const _defaultOverlayIconUp = Icon(
  Icons.keyboard_arrow_up_rounded,
  size: 20,
);

const _defaultHeaderPadding = EdgeInsets.all(16.0);
const _overlayOuterPadding =
EdgeInsetsDirectional.only(bottom: 12, start: 12, end: 12);
const _defaultOverlayShadowOffset = Offset(0, 6);
const _defaultListItemPadding =
EdgeInsets.symmetric(vertical: 12, horizontal: 16);

class _DropdownOverlay<T> extends StatefulWidget {
  final List<T> items;
  final ScrollController? itemsScrollCtrl;
  final SingleSelectController<T?> selectedItemNotifier;
  final MultiSelectController<T> selectedItemsNotifier;
  final Function(T) onItemSelect;
  final Size size;
  final LayerLink layerLink;
  final VoidCallback hideOverlay;
  final String hintText, searchHintText, noResultFoundText;
  final bool excludeSelected, hideSelectedFieldWhenOpen, canCloseOutsideBounds;
  final _SearchType? searchType;
  final Future<List<T>> Function(String)? futureRequest;
  final Duration? futureRequestDelay;
  final int maxLines;
  final double? overlayHeight;
  final TextStyle? hintStyle, headerStyle, noResultFoundStyle, listItemStyle;
  final EdgeInsets? headerPadding, listItemPadding, itemsListPadding;
  final Widget? searchRequestLoadingIndicator;
  final _ListItemBuilder<T>? listItemBuilder;
  final _HeaderBuilder<T>? headerBuilder;
  final _HeaderListBuilder<T>? headerListBuilder;
  final _HintBuilder? hintBuilder;
  final _NoResultFoundBuilder? noResultFoundBuilder;
  final CustomDropdownDecoration? decoration;
  final _DropdownType dropdownType;
  final List<T> Function(String query, List<T> items)? customSearchFn;

  const _DropdownOverlay({
    Key? key,
    required this.items,
    required this.itemsScrollCtrl,
    required this.size,
    required this.layerLink,
    required this.hideOverlay,
    required this.hintText,
    required this.searchHintText,
    required this.selectedItemNotifier,
    required this.selectedItemsNotifier,
    required this.excludeSelected,
    required this.onItemSelect,
    required this.noResultFoundText,
    required this.canCloseOutsideBounds,
    required this.maxLines,
    required this.overlayHeight,
    required this.dropdownType,
    required this.decoration,
    required this.hintStyle,
    required this.headerStyle,
    required this.listItemStyle,
    required this.noResultFoundStyle,
    required this.hideSelectedFieldWhenOpen,
    required this.searchRequestLoadingIndicator,
    required this.headerPadding,
    required this.itemsListPadding,
    required this.listItemPadding,
    required this.headerBuilder,
    required this.hintBuilder,
    required this.searchType,
    required this.futureRequest,
    required this.futureRequestDelay,
    required this.listItemBuilder,
    required this.headerListBuilder,
    required this.noResultFoundBuilder,
    required this.customSearchFn,
  });

  @override
  _DropdownOverlayState<T> createState() => _DropdownOverlayState<T>();
}

class _DropdownOverlayState<T> extends State<_DropdownOverlay<T>> {
  bool displayOverly = true, displayOverlayBottom = true;
  bool isSearchRequestLoading = false;
  bool? mayFoundSearchRequestResult;
  late List<T> items;
  late T? selectedItem;
  late List<T> selectedItems;
  late ScrollController scrollController;
  final key1 = GlobalKey(), key2 = GlobalKey();

  @override
  void initState() {
    super.initState();
    scrollController = widget.itemsScrollCtrl ?? ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final render1 = key1.currentContext?.findRenderObject() as RenderBox?;
      final render2 = key2.currentContext?.findRenderObject() as RenderBox?;
      if (render1 != null && render2 != null) {
        final screenHeight = MediaQuery.of(context).size.height;
        double y = render1.localToGlobal(Offset.zero).dy;
        if (screenHeight - y < render2.size.height) {
          displayOverlayBottom = false;
          setState(() {});
        }
      }
    });

    selectedItem = widget.selectedItemNotifier.value;
    selectedItems = widget.selectedItemsNotifier.value;

    widget.selectedItemNotifier.addListener(singleSelectListener);
    widget.selectedItemsNotifier.addListener(multiSelectListener);

    if (widget.excludeSelected &&
        widget.items.length > 1 &&
        selectedItem != null) {
      T value = selectedItem as T;
      items = widget.items.where((item) => item != value).toList();
    } else {
      items = widget.items;
    }
  }

  @override
  void dispose() {
    widget.selectedItemNotifier.removeListener(singleSelectListener);
    widget.selectedItemsNotifier.removeListener(multiSelectListener);
    if (widget.itemsScrollCtrl == null) scrollController.dispose();
    super.dispose();
  }

  void singleSelectListener() {
    if (mounted) {
      selectedItem = widget.selectedItemNotifier.value;
    }
  }

  void multiSelectListener() {
    if (mounted) {
      selectedItems = widget.selectedItemsNotifier.value;
    }
  }

  void onItemSelect(T value) {
    widget.onItemSelect(value);
    if (widget.dropdownType == _DropdownType.singleSelect) {
      setState(() => displayOverly = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final decoration = widget.decoration;
    final onSearch = widget.searchType != null;
    final overlayOffset = const Offset(-12, 0);
    final listPadding =
    onSearch ? const EdgeInsets.only(top: 8) : EdgeInsets.zero;

    final list = items.isNotEmpty
        ? _ItemsList<T>(
      scrollController: scrollController,
      listItemBuilder: widget.listItemBuilder ?? defaultListItemBuilder,
      excludeSelected: items.length > 1 ? widget.excludeSelected : false,
      selectedItem: selectedItem,
      selectedItems: selectedItems,
      items: items,
      itemsListPadding: widget.itemsListPadding ?? listPadding,
      listItemPadding: widget.listItemPadding ?? _defaultListItemPadding,
      onItemSelect: onItemSelect,
      decoration: decoration?.listItemDecoration,
      dropdownType: widget.dropdownType,
    )
        : (mayFoundSearchRequestResult != null &&
        !mayFoundSearchRequestResult!) ||
        widget.searchType == _SearchType.onListData
        ? noResultFoundBuilder(context)
        : const SizedBox(height: 12);

    final child = Stack(
      children: [
        /// ✨ تعديل هنا لجعل الـ dropdown يتحرك عند فتح الكيبورد
        Positioned(
          width: widget.size.width + 24,
          top: displayOverlayBottom
              ? null
              : (MediaQuery.of(context).viewInsets.bottom * -1),
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: CompositedTransformFollower(
              link: widget.layerLink,
              followerAnchor: displayOverlayBottom
                  ? Alignment.topLeft
                  : Alignment.bottomLeft,
              showWhenUnlinked: false,
              offset: overlayOffset,
              child: Container(
                key: key1,
                margin: _overlayOuterPadding,
                decoration: BoxDecoration(
                  color: decoration?.expandedFillColor ??
                      CustomDropdownDecoration._defaultFillColor,
                  border: decoration?.expandedBorder,
                  borderRadius: decoration?.expandedBorderRadius ??
                      _defaultBorderRadius,
                  boxShadow: decoration?.expandedShadow ??
                      [
                        BoxShadow(
                          blurRadius: 24.0,
                          color: Colors.black.withOpacity(.08),
                          offset: _defaultOverlayShadowOffset,
                        ),
                      ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: _AnimatedSection(
                    animationDismissed: widget.hideOverlay,
                    expand: displayOverly,
                    axisAlignment: displayOverlayBottom ? 1.0 : -1.0,
                    child: SizedBox(
                      key: key2,
                      height: items.length > 4
                          ? widget.overlayHeight ?? (onSearch ? 270 : 225)
                          : null,
                      child: ClipRRect(
                        borderRadius: decoration?.expandedBorderRadius ??
                            _defaultBorderRadius,
                        child: NotificationListener<
                            OverscrollIndicatorNotification>(
                          onNotification: (notification) {
                            notification.disallowIndicator();
                            return true;
                          },
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              scrollbarTheme:
                              decoration?.overlayScrollbarDecoration ??
                                  ScrollbarThemeData(
                                    thumbVisibility:
                                    MaterialStateProperty.all(true),
                                    thickness:
                                    MaterialStateProperty.all(5),
                                    radius: const Radius.circular(4),
                                    thumbColor: MaterialStateProperty.all(
                                      Colors.grey[300],
                                    ),
                                  ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!widget.hideSelectedFieldWhenOpen)
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      setState(() => displayOverly = false);
                                    },
                                    child: Padding(
                                      padding: widget.headerPadding ??
                                          _defaultHeaderPadding,
                                      child: Row(
                                        children: [
                                          if (widget.decoration?.prefixIcon !=
                                              null) ...[
                                            widget.decoration!.prefixIcon!,
                                            const SizedBox(width: 12),
                                          ],
                                          Expanded(
                                            child:
                                            selectedItem != null
                                                ? defaultHeaderBuilder(
                                              context,
                                              item: selectedItem,
                                            )
                                                : defaultHintBuilder(
                                              context,
                                              widget.hintText,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          decoration?.expandedSuffixIcon ??
                                              _defaultOverlayIconUp,
                                        ],
                                      ),
                                    ),
                                  ),
                                if (isSearchRequestLoading)
                                  widget.searchRequestLoadingIndicator ??
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 20.0,
                                        ),
                                        child: Center(
                                          child: SizedBox(
                                            width: 25,
                                            height: 25,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 3,
                                            ),
                                          ),
                                        ),
                                      )
                                else
                                  items.length > 4
                                      ? Expanded(child: list)
                                      : list,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );

    if (widget.canCloseOutsideBounds) {
      return Stack(
        children: [
          GestureDetector(
            onTap: () => setState(() => displayOverly = false),
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              color: Colors.transparent,
            ),
          ),
          child,
        ],
      );
    }

    return child;
  }

  Widget noResultFoundBuilder(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Text(
          widget.noResultFoundText,
          style: widget.noResultFoundStyle ?? const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget defaultListItemBuilder(
      BuildContext context,
      T result,
      bool isSelected,
      VoidCallback onItemSelect,
      ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            result.toString(),
            maxLines: widget.maxLines,
            overflow: TextOverflow.ellipsis,
            style: widget.listItemStyle ?? const TextStyle(fontSize: 16),
          ),
        ),
        if (widget.dropdownType == _DropdownType.multipleSelect)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 12.0),
            child: Checkbox(
              onChanged: (_) => onItemSelect(),
              value: isSelected,
            ),
          ),
      ],
    );
  }

  Widget defaultHeaderBuilder(BuildContext context,
      {T? item, List<T>? items}) {
    return Text(
      items != null ? items.join(', ') : item.toString(),
      maxLines: widget.maxLines,
      overflow: TextOverflow.ellipsis,
      style: widget.headerStyle ??
          const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    );
  }

  Widget defaultHintBuilder(BuildContext context, String hint) {
    return Text(
      hint,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: widget.hintStyle ??
          const TextStyle(fontSize: 16, color: Color(0xFFA7A7A7)),
    );
  }
}
