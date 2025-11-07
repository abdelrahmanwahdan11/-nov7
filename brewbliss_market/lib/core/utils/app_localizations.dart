import 'package:flutter/widgets.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('ar')];

  static const _localizedValues = {
    'en': {
      'appName': 'BrewBliss Market',
      'forYou': 'for you',
      'newCollection': 'new collection',
      'specialOffers': 'special offers',
      'placeOrder': 'place order',
      'compare': 'Compare',
      'addToFav': 'Add to favorites',
      'addToMyItems': 'Add to My Items',
      'aiInfo': 'AI info (coming soon)',
      'addToCart': 'Add to cart',
      'negotiate': 'Negotiate',
      'cart': 'Cart',
      'experiments': 'Experiments',
      'reduceMotion': 'Reduce motion',
      'cancel': 'Cancel',
      'view': 'View',
      'search': 'Search items...',
      'catalog': 'Catalog',
      'myItems': 'My Items',
      'settings': 'Settings',
      'offers': 'Offers',
      'sell': 'Sell',
      'keepOffers': 'Keep, accept offers',
      'guest': 'Continue as guest',
      'signIn': 'Sign in',
      'signUp': 'Create account',
      'forgot': 'Forgot password?',
      'emailPhone': 'Email or phone',
      'password': 'Password',
      'name': 'Name',
      'confirmPassword': 'Confirm password',
      'passwordStrength': 'Password strength',
      'continueLabel': 'Continue',
      'skip': 'Skip',
      'next': 'Next',
      'getStarted': 'Get started',
      'language': 'Language',
      'darkMode': 'Dark Mode',
      'primaryColor': 'Primary color',
      'tutorialReplay': 'Replay tutorial',
      'clearStorage': 'Clear local data',
      'searchAnything': 'Search anything',
      'rotateModel': 'Rotate the 3D model',
      'tapCards': 'Tap cards to open overlay',
      'compareHere': 'Compare items here',
      'addItem': 'Add your item',
      'pullToRefresh': 'Pull to refresh',
      'emptyState': 'No items yet. Add your first collectible.',
      'offersTitle': 'Offers',
      'accept': 'Accept',
      'decline': 'Decline',
      'makeOffer': 'Make an offer',
      'price': 'Price',
      'category': 'Category',
      'condition': 'Condition',
      'description': 'Description',
      'allowOffers': 'Allow offers',
      'model3d': '3D model URL',
      'images': 'Image URLs',
      'save': 'Save',
      'saveSearch': 'Save this search',
      'savedSearches': 'Saved searches updated',
      'addedToFavorites': 'Added to favorites',
      'removedFromFavorites': 'Removed from favorites',
      'addedToCompare': 'Added to compare',
      'removedFromCompare': 'Removed from compare',
      'offersBadge': 'offers',
      'removeFromCompare': 'Remove',
    },
    'ar': {
      'appName': 'سوق بريو بليس',
      'forYou': 'لك',
      'newCollection': 'مجموعة جديدة',
      'specialOffers': 'عروض خاصة',
      'placeOrder': 'اطلب الآن',
      'compare': 'مقارنة',
      'addToFav': 'أضف للمفضلة',
      'addToMyItems': 'أضف لمقتنياتي',
      'aiInfo': 'معلومات بالذكاء الاصطناعي (لاحقًا)',
      'addToCart': 'أضف إلى السلة',
      'negotiate': 'تفاوض',
      'cart': 'السلة',
      'experiments': 'التجارب',
      'reduceMotion': 'تقليل الحركة',
      'cancel': 'إلغاء',
      'view': 'العرض',
      'search': 'ابحث في العناصر...',
      'catalog': 'الكتالوج',
      'myItems': 'مقتنياتي',
      'settings': 'الإعدادات',
      'offers': 'العروض',
      'sell': 'للبيع',
      'keepOffers': 'موجود لدي وقابل للعروض',
      'guest': 'الدخول كضيف',
      'signIn': 'تسجيل الدخول',
      'signUp': 'إنشاء حساب',
      'forgot': 'نسيت كلمة المرور؟',
      'emailPhone': 'البريد أو الهاتف',
      'password': 'كلمة المرور',
      'name': 'الاسم',
      'confirmPassword': 'تأكيد كلمة المرور',
      'passwordStrength': 'قوة كلمة المرور',
      'continueLabel': 'متابعة',
      'skip': 'تخطي',
      'next': 'التالي',
      'getStarted': 'ابدأ',
      'language': 'اللغة',
      'darkMode': 'الوضع الداكن',
      'primaryColor': 'اللون الأساسي',
      'tutorialReplay': 'إعادة العرض التوجيهي',
      'clearStorage': 'مسح البيانات المحلية',
      'searchAnything': 'ابحث عن أي عنصر',
      'rotateModel': 'حرّك النموذج ثلاثي الأبعاد',
      'tapCards': 'اضغط لفتح العرض العائم',
      'compareHere': 'قارن العناصر هنا',
      'addItem': 'أضف عنصرًا جديدًا',
      'pullToRefresh': 'اسحب للتحديث',
      'emptyState': 'لا توجد عناصر بعد. أضف مقتنيتك الأولى.',
      'offersTitle': 'العروض',
      'accept': 'قبول',
      'decline': 'رفض',
      'makeOffer': 'قدّم عرضًا',
      'price': 'السعر',
      'category': 'الفئة',
      'condition': 'الحالة',
      'description': 'الوصف',
      'allowOffers': 'السماح بالعروض',
      'model3d': 'رابط نموذج ثلاثي الأبعاد',
      'images': 'روابط الصور',
      'save': 'حفظ',
      'saveSearch': 'حفظ هذا البحث',
      'savedSearches': 'تم تحديث عمليات البحث المحفوظة',
      'addedToFavorites': 'أضيف إلى المفضلة',
      'removedFromFavorites': 'أزيل من المفضلة',
      'addedToCompare': 'أضيف إلى المقارنة',
      'removedFromCompare': 'أزيل من المقارنة',
      'offersBadge': 'عروض',
      'removeFromCompare': 'إزالة',
    },
  };

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(Localizations.localeOf(context));
  }

  String get languageCode => locale.languageCode;

  String translate(String key) {
    return _localizedValues[languageCode]?[key] ??
        _localizedValues['en']![key] ??
        key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales
          .map((e) => e.languageCode)
          .contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
