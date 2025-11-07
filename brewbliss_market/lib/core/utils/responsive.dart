int responsiveCrossAxisCount(double width) {
  if (width >= 1200) return 4;
  if (width >= 900) return 3;
  if (width >= 600) return 2;
  return 1;
}

double responsiveChildAspectRatio(int crossAxisCount) {
  return crossAxisCount == 1 ? 1.05 : 0.72;
}
