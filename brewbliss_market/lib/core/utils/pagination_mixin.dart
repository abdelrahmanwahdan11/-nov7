mixin PaginationMixin {
  static const int defaultPageSize = 12;

  int startForPage(int page, {int pageSize = defaultPageSize}) {
    return page * pageSize;
  }

  int endForPage(int page, int totalLength, {int pageSize = defaultPageSize}) {
    final end = (page + 1) * pageSize;
    return end > totalLength ? totalLength : end;
  }

  bool isEnd(int page, int totalLength, {int pageSize = defaultPageSize}) {
    return startForPage(page, pageSize: pageSize) >= totalLength;
  }

  List<T> sliceForPage<T>(List<T> source, int page, {int pageSize = defaultPageSize}) {
    if (source.isEmpty || isEnd(page, source.length, pageSize: pageSize)) {
      return <T>[];
    }
    final start = startForPage(page, pageSize: pageSize);
    final end = endForPage(page, source.length, pageSize: pageSize);
    return source.sublist(start, end);
  }
}
