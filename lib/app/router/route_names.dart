/// Centralised route name constants for every screen across all features.
///
/// Feature agents map these names to builders inside their own
/// `<feature>_routes.dart`. Never hard-code a route string elsewhere.
class RouteNames {
  const RouteNames._();

  // Shell / root.
  static const splash = '/';
  static const shell = '/shell';

  // Auth & onboarding (WS5).
  static const onboarding = '/onboarding';
  static const signIn = '/auth/sign-in';
  static const signUp = '/auth/sign-up';
  static const roleSelection = '/auth/role';
  static const verification = '/auth/verification';
  static const forgotPassword = '/auth/forgot-password';
  static const resetPassword = '/auth/reset-password';

  // Discovery & catalogue (WS1).
  static const home = '/home';
  static const catalog = '/catalog';
  static const categories = '/categories';
  static const categoryListings = '/categories/listings';
  static const search = '/search';
  static const flashSales = '/flash-sales';

  // Product and reviews (WS2).
  static const productDetail = '/product';
  static const reviews = '/reviews';
  static const writeReview = '/reviews/write';

  // Cart, checkout, payment (WS3).
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const payment = '/payment';
  static const paymentMethods = '/payment/methods';
  static const orderConfirmation = '/checkout/confirmation';
  static const orderConversation = '/messages/order';

  // Orders, wishlist, addresses (WS4).
  static const orders = '/orders';
  static const orderDetail = '/orders/detail';
  static const orderTracking = '/orders/tracking';
  static const wishlist = '/wishlist';
  static const addresses = '/addresses';
  static const addAddress = '/addresses/add';

  // Profile, settings, support, notifications (WS6).
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const changePassword = '/profile/change-password';
  static const settings = '/settings';
  static const notifications = '/notifications';
  static const support = '/support';
  static const faq = '/support/faq';
  static const legal = '/support/legal';
  static const contact = '/support/contact';
  static const partnerApplication = '/support/partner-application';
  static const admin = '/admin';

  // Seller space (WS7).
  static const sellerHub = '/seller';
  static const sellerHome = '/seller/home';
  static const createShop = '/seller/create-shop';
  static const editShop = '/seller/edit-shop';
  static const addProduct = '/seller/add-product';
  static const editProduct = '/seller/edit-product';
  static const sellerOrders = '/seller/orders';
  static const sellerOrderDetail = '/seller/orders/detail';
  static const sellerAnalytics = '/seller/analytics';
  static const sellerCoupons = '/seller/coupons';
  static const createCoupon = '/seller/coupons/create';
  static const sellerKyc = '/seller/kyc';
  static const aiListingGenerator = '/seller/ai-listing';

  // Partner aliases kept alongside legacy seller routes.
  static const partnerHub = '/partner';
  static const partnerHome = '/partner/home';
  static const partnerCreateProfile = '/partner/create-profile';
  static const partnerEditProfile = '/partner/edit-profile';
  static const partnerAddProduct = '/partner/products/add';
  static const partnerEditProduct = '/partner/products/edit';

  // Delivery & assistant (WS8).
  static const driverHome = '/driver/home';
  static const driverRegister = '/driver/register';
  static const driverDeliveries = '/driver/deliveries';
  static const deliveryDetail = '/driver/deliveries/detail';
  static const driverEarnings = '/driver/earnings';
  static const assistant = '/assistant';
}
