import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'Offline Account',
      'dashboard': 'Dashboard',
      'settings': 'Settings',
      'accounts': 'Accounts',
      'categories': 'Categories',
      'charts': 'Charts',
      'invoice': 'Invoice',
      'exportCsv': 'Export CSV',
      'importCsv': 'Import CSV',
      'privacyPolicy': 'Privacy Policy',
      'deleteAccount': 'Delete Account',
      'theme': 'Theme',
      'darkTheme': 'Dark Theme',
      'language': 'Language',
      'fontSize': 'Font Size',
      'previewTextSize': 'Preview Text Size',
      'english': 'English',
      'persian': 'Persian (فارسی)',
      'createAccount': 'Create Account',
      'username': 'Username',
      'password': 'Password',
      'confirmPassword': 'Confirm Password',
      'login': 'Login',
      'logout': 'Logout',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'income': 'Income',
      'expense': 'Expense',
      'date': 'Date',
      'amount': 'Amount',
      'note': 'Note',
      'description': 'Description',
      'search': 'Search',
      'filter': 'Filter',
      'generateInvoice': 'Generate Invoice (PDF)',
      'account': 'Account',
      'allAccounts': 'All Accounts',
      'transactionType': 'Transaction Type',
      'all': 'All',
      'dateRange': 'Date Range',
      'startDate': 'Start Date',
      'endDate': 'End Date',
      'generatePdf': 'Generate PDF',
      'sortByDate': 'Sort by Date',
      'sortByAmount': 'Sort by Amount',
      'incomeFirst': 'Income First',
      'expenseFirst': 'Expense First',
      'privacyPolicyContent':
          'This app works offline.\n\nYour data is stored locally on your device.\nTransactions, bank cards, and categories are encrypted at rest.\n\nYou can export your data anytime as CSV.',
      'deleteAccountConfirm': 'Delete account?',
      'deleteAccountWarning':
          'This deletes the local account and all transactions on this device.',
      'enterUsername': 'Enter a username',
      'usernameTooShort': 'Username too short (min 3 chars)',
      'enterPassword': 'Enter a password',
      'passwordTooShort': 'Password too short',
      'passwordTooWeak':
          'Password too weak. Must contain:\n• At least 8 characters\n• One uppercase letter\n• One lowercase letter\n• One number',
      'passwordsDoNotMatch': 'Passwords do not match',
      'loginTitle': 'Welcome back',
      'loginSubtitle': 'Enter your credentials to access your data',
      'invalidCredentials': 'Invalid username or password',
      'recentTransactions': 'Recent Transactions',
      'noTransactions': 'No transactions yet',
      'totalBalance': 'Total Balance',
      'totalIncome': 'Total Income',
      'totalExpense': 'Total Expense',
      'anyDate': 'Any Date',
      'clear': 'Clear',
      'ok': 'OK',
      'importedTransactions': 'Imported transactions',
      'add': 'Add',
      'transactionDetails': 'Transaction Details',
      'currencySymbol': '\$',
      'title': 'Title',
      'category': 'Category',
      'relatedPerson': 'Related Person',
      'created': 'Created',
      'cardNumberFormatted': 'Card Number',
      'balanceWithSeparator': 'Balance',
      'time': 'Time',
      'today': 'Today',
      'yesterday': 'Yesterday',
      'invoiceGeneratedSuccessfully': 'Invoice generated successfully',
      'addTransaction': 'Add transaction',
      'editTransaction': 'Edit transaction',
      'card': 'Card',
      'selectCard': 'Select Card',
      'amountHint': '1,234.50',
      'enterAmount': 'Enter amount',
      'enterTitle': 'Enter title',
      'selectCategory': 'Select Category',
      'selectDate': 'Select Date',
      'affectsBalance': 'This transaction affects the balance on',
      'noteOptional': 'Note (optional)',
      'relatedPersonOptional': 'Related person (optional)',
      'amountMustBeGreater': 'Amount must be greater than 0',
      'couldNotSave': 'Could not save: ',
      'enterValidAmount': 'Enter a valid amount',
      'addCategory': 'Add category',
      'editCategory': 'Edit category',
      'enterCategoryName': 'Enter category name',
      'passwordOptional': 'Password Optional',
      'enablePassword': 'Enable password protection',
      'skipPassword': 'Skip password (less secure)',
      'incomeVsExpenses': 'Income vs Expenses',
      'lastDays': 'Last',
      'days': 'days',
      'current': 'Current',
      'noData': 'No data',
      'expenses': 'Expenses',
      'addCard': 'Add card',
      'editCard': 'Edit card',
      'cardBankName': 'Card / Bank name',
      'enterCardName': 'Enter card name',
      'cardNumber': 'Card number (optional)',
      'initialBalance': 'Initial balance',
      'bankCards': 'Bank cards',
      'deleteCard': 'Delete card?',
      'deleteCardWarning': 'Transactions in this card will be deleted.',
      'invoiceTitle': 'Invoice',
      'quickEdit': 'Quick Edit Balance',
      'editBalance': 'Edit Balance',
      'swipeActions': 'Swipe Actions',
      'swipeActionsEnabled': 'Enable Swipe Actions',
      'swipeLeft': 'Swipe Left to Delete',
      'swipeRight': 'Swipe Right to Edit',
    },
    'fa': {
      'appTitle': 'حساب آفلاین',
      'dashboard': 'داشبورد',
      'settings': 'تنظیمات',
      'accounts': 'حساب‌ها',
      'categories': 'دسته‌بندی‌ها',
      'charts': 'نمودارها',
      'invoice': 'فاکتور',
      'exportCsv': 'خروجی اکسل (CSV)',
      'importCsv': 'ورودی اکسل (CSV)',
      'privacyPolicy': 'سیاست محرمانگی',
      'deleteAccount': 'حذف حساب کاربری',
      'theme': 'پوسته',
      'darkTheme': 'حالت شب',
      'language': 'زبان',
      'fontSize': 'اندازه قلم',
      'previewTextSize': 'پیش‌نمایش اندازه متن',
      'english': 'English',
      'persian': 'Persian (فارسی)',
      'createAccount': 'ایجاد حساب',
      'username': 'نام کاربری',
      'password': 'رمز عبور',
      'confirmPassword': 'تکرار رمز عبور',
      'login': 'ورود',
      'logout': 'خروج',
      'save': 'ذخیره',
      'cancel': 'لغو',
      'delete': 'حذف',
      'edit': 'ویرایش',
      'income': 'درآمد',
      'expense': 'هزینه',
      'date': 'تاریخ',
      'amount': 'مبلغ',
      'note': 'یادداشت',
      'description': 'توضیحات',
      'search': 'جستجو',
      'filter': 'فیلتر',
      'generateInvoice': 'صدور فاکتور (PDF)',
      'account': 'حساب',
      'allAccounts': 'همه حساب‌ها',
      'transactionType': 'نوع تراکنش',
      'all': 'همه',
      'dateRange': 'بازه زمانی',
      'startDate': 'از تاریخ',
      'endDate': 'تا تاریخ',
      'generatePdf': 'ایجاد فایل PDF',
      'sortByDate': 'مرتب‌سازی بر اساس تاریخ',
      'sortByAmount': 'مرتب‌سازی بر اساس مبلغ',
      'incomeFirst': 'ابتدا درآمدها',
      'expenseFirst': 'ابتدا هزینه‌ها',
      'privacyPolicyContent':
          'این برنامه به صورت کاملاً آفلاین کار می‌کند.\n\nاطلاعات شما به صورت محلی روی دستگاه ذخیره می‌شود.\nتراکنش‌ها، کارت‌های بانکی و دسته‌بندی‌ها به صورت رمزنگاری شده نگهداری می‌شوند.\n\nشما می‌توانید هر زمان که بخواهید از اطلاعات خود خروجی CSV بگیرید.',
      'deleteAccountConfirm': 'حذف حساب کاربری؟',
      'deleteAccountWarning':
          'این عملیات حساب کاربری محلی و تمام تراکنش‌های روی این دستگاه را حذف می‌کند.',
      'enterUsername': 'نام کاربری را وارد کنید',
      'usernameTooShort': 'نام کاربری خیلی کوتاه است (حداقل ۳ حرف)',
      'enterPassword': 'رمز عبور را وارد کنید',
      'passwordTooShort': 'رمز عبور خیلی کوتاه است',
      'passwordTooWeak':
          'رمز عبور ضعیف است. باید شامل:\n• حداقل ۸ کاراکتر\n• یک حرف بزرگ\n• یک حرف کوچک\n• یک عدد باشد',
      'passwordsDoNotMatch': 'رمز عبورها مطابقت ندارند',
      'loginTitle': 'خوش آمدید',
      'loginSubtitle': 'برای دسترسی به اطلاعات وارد شوید',
      'invalidCredentials': 'نام کاربری یا رمز عبور اشتباه است',
      'recentTransactions': 'تراکنش‌های اخیر',
      'noTransactions': 'هنوز تراکنشی ثبت نشده است',
      'totalBalance': 'موجودی کل',
      'totalIncome': 'مجموع درآمد',
      'totalExpense': 'مجموع هزینه',
      'anyDate': 'هر تاریخی',
      'clear': 'پاک کردن',
      'ok': 'تایید',
      'importedTransactions': 'تراکنش وارد شد',
      'add': 'افزودن',
      'transactionDetails': 'جزئیات تراکنش',
      'currencySymbol': 'ریال',
      'title': 'عنوان',
      'category': 'دسته‌بندی',
      'relatedPerson': 'طرف حساب',
      'created': 'ایجاد شده',
      'cardNumberFormatted': 'شماره کارت',
      'balanceWithSeparator': 'موجودی',
      'time': 'زمان',
      'today': 'امروز',
      'yesterday': 'دیروز',
      'invoiceGeneratedSuccessfully': 'فاکتور با موفقیت ایجاد شد',
      'addTransaction': 'افزودن تراکنش',
      'editTransaction': 'ویرایش تراکنش',
      'card': 'کارت',
      'selectCard': 'انتخاب کارت',
      'amountHint': '1,234.50',
      'enterAmount': 'مبلغ را وارد کنید',
      'enterTitle': 'عنوان را وارد کنید',
      'selectCategory': 'انتخاب دسته‌بندی',
      'selectDate': 'انتخاب تاریخ',
      'affectsBalance': 'این تراکنش موجودی را در تاریخ',
      'noteOptional': 'یادداشت (اختیاری)',
      'relatedPersonOptional': 'طرف حساب (اختیاری)',
      'amountMustBeGreater': 'مبلغ باید بیشتر از صفر باشد',
      'couldNotSave': 'نتوانست ذخیره شود: ',
      'enterValidAmount': 'مبلغ معتبری را وارد کنید',
      'addCategory': 'افزودن دسته‌بندی',
      'editCategory': 'ویرایش دسته‌بندی',
      'enterCategoryName': 'نام دسته‌بندی را وارد کنید',
      'passwordOptional': 'رمز عبور اختیاری',
      'enablePassword': 'فعال کردن محافظت با رمز عبور',
      'skipPassword': 'بدون رمز عبور (امن‌تر نیست)',
      'incomeVsExpenses': 'درآمد در مقابل هزینه',
      'lastDays': 'آخرین',
      'days': 'روز',
      'current': 'موجودی فعلی',
      'noData': 'داده‌ای موجود نیست',
      'expenses': 'هزینه‌ها',
      'addCard': 'افزودن کارت',
      'editCard': 'ویرایش کارت',
      'cardBankName': 'نام کارت / بانک',
      'enterCardName': 'نام کارت را وارد کنید',
      'cardNumber': 'شماره کارت (اختیاری)',
      'initialBalance': 'موجودی اولیه',
      'bankCards': 'کارت‌های بانکی',
      'deleteCard': 'حذف کارت؟',
      'deleteCardWarning': 'تراکنش‌های این کارت حذف خواهند شد.',
      'invoiceTitle': 'صورت‌حساب',
      'quickEdit': 'ویرایش سریع موجودی',
      'editBalance': 'ویرایش موجودی',
      'swipeActions': 'کشش‌های جانبی',
      'swipeActionsEnabled': 'فعال کردن کشش‌های جانبی',
      'swipeLeft': 'کشش چپ برای حذف',
      'swipeRight': 'کشش راست برای ویرایش',
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Getters for common strings
  String get appTitle => get('appTitle');
  String get dashboard => get('dashboard');
  String get settings => get('settings');
  String get accounts => get('accounts');
  String get categories => get('categories');
  String get charts => get('charts');
  String get invoice => get('invoice');
  String get exportCsv => get('exportCsv');
  String get importCsv => get('importCsv');
  String get privacyPolicy => get('privacyPolicy');
  String get deleteAccount => get('deleteAccount');
  String get theme => get('theme');
  String get darkTheme => get('darkTheme');
  String get language => get('language');
  String get fontSize => get('fontSize');
  String get previewTextSize => get('previewTextSize');
  String get english => get('english');
  String get persian => get('persian');
  String get createAccount => get('createAccount');
  String get username => get('username');
  String get password => get('password');
  String get confirmPassword => get('confirmPassword');
  String get login => get('login');
  String get logout => get('logout');
  String get save => get('save');
  String get cancel => get('cancel');
  String get delete => get('delete');
  String get edit => get('edit');
  String get income => get('income');
  String get expense => get('expense');
  String get date => get('date');
  String get amount => get('amount');
  String get note => get('note');
  String get description => get('description');
  String get search => get('search');
  String get filter => get('filter');
  String get generateInvoice => get('generateInvoice');
  String get account => get('account');
  String get allAccounts => get('allAccounts');
  String get transactionType => get('transactionType');
  String get all => get('all');
  String get dateRange => get('dateRange');
  String get startDate => get('startDate');
  String get endDate => get('endDate');
  String get generatePdf => get('generatePdf');
  String get sortByDate => get('sortByDate');
  String get sortByAmount => get('sortByAmount');
  String get incomeFirst => get('incomeFirst');
  String get expenseFirst => get('expenseFirst');
  String get privacyPolicyContent => get('privacyPolicyContent');
  String get deleteAccountConfirm => get('deleteAccountConfirm');
  String get deleteAccountWarning => get('deleteAccountWarning');
  String get enterUsername => get('enterUsername');
  String get usernameTooShort => get('usernameTooShort');
  String get enterPassword => get('enterPassword');
  String get passwordTooShort => get('passwordTooShort');
  String get passwordTooWeak => get('passwordTooWeak');
  String get passwordsDoNotMatch => get('passwordsDoNotMatch');
  String get loginTitle => get('loginTitle');
  String get loginSubtitle => get('loginSubtitle');
  String get invalidCredentials => get('invalidCredentials');
  String get recentTransactions => get('recentTransactions');
  String get noTransactions => get('noTransactions');
  String get totalBalance => get('totalBalance');
  String get totalIncome => get('totalIncome');
  String get totalExpense => get('totalExpense');
  String get anyDate => get('anyDate');
  String get clear => get('clear');
  String get ok => get('ok');
  String get importedTransactions => get('importedTransactions');
  String get add => get('add');
  String get transactionDetails => get('transactionDetails');
  String get currencySymbol => get('currencySymbol');
  String get title => get('title');
  String get category => get('category');
  String get relatedPerson => get('relatedPerson');
  String get created => get('created');
  String get cardNumberFormatted => get('cardNumberFormatted');
  String get balanceWithSeparator => get('balanceWithSeparator');
  String get time => get('time');
  String get today => get('today');
  String get yesterday => get('yesterday');
  String get invoiceGeneratedSuccessfully => get('invoiceGeneratedSuccessfully');
  String get addTransaction => get('addTransaction');
  String get editTransaction => get('editTransaction');
  String get card => get('card');
  String get selectCard => get('selectCard');
  String get amountHint => get('amountHint');
  String get enterAmount => get('enterAmount');
  String get enterTitle => get('enterTitle');
  String get selectCategory => get('selectCategory');
  String get selectDate => get('selectDate');
  String get affectsBalance => get('affectsBalance');
  String get noteOptional => get('noteOptional');
  String get relatedPersonOptional => get('relatedPersonOptional');
  String get amountMustBeGreater => get('amountMustBeGreater');
  String get couldNotSave => get('couldNotSave');
  String get enterValidAmount => get('enterValidAmount');
  String get addCategory => get('addCategory');
  String get editCategory => get('editCategory');
  String get enterCategoryName => get('enterCategoryName');
  String get passwordOptional => get('passwordOptional');
  String get enablePassword => get('enablePassword');
  String get skipPassword => get('skipPassword');
  String get incomeVsExpenses => get('incomeVsExpenses');
  String get lastDays => get('lastDays');
  String get days => get('days');
  String get current => get('current');
  String get noData => get('noData');
  String get addCard => get('addCard');
  String get editCard => get('editCard');
  String get cardBankName => get('cardBankName');
  String get enterCardName => get('enterCardName');
  String get cardNumber => get('cardNumber');
  String get initialBalance => get('initialBalance');
  String get bankCards => get('bankCards');
  String get deleteCard => get('deleteCard');
  String get deleteCardWarning => get('deleteCardWarning');
  String get invoiceTitle => get('invoiceTitle');
  String get quickEdit => get('quickEdit');
  String get editBalance => get('editBalance');
  String get swipeActions => get('swipeActions');
  String get swipeActionsEnabled => get('swipeActionsEnabled');
  String get swipeLeft => get('swipeLeft');
  String get swipeRight => get('swipeRight');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'fa'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
