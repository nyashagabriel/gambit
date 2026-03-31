// lib/core/strings.dart — GAMBIT TSL

class AppStrings {
  AppStrings._();

  // ── Brand & General ────────────────────────────────────────────────────────
  static const String appName = "GAMBIT TSL";
  static const String appTagline = "TRANSPORT · LOGISTICS · SYSTEM";
  static const String cancel = "Cancel";
  static const String save = "Save";
  static const String update = "Update";
  static const String delete = "Delete";
  static const String confirm = "Confirm";
  static const String back = "Back";
  static const String errorGeneric = "An unexpected error occurred. Please try again.";
  static const String loading = "Loading...";

  // ── Auth & Profile ─────────────────────────────────────────────────────────
  static const String signInAs = "SIGN IN AS";
  static const String usernameLabel = "USERNAME";
  static const String passwordLabel = "PASSWORD";
  static const String loginButton = "SIGN IN";
  static const String forgotPassword = "Forgot password?";
  static const String setRecoveryEmail = "Set recovery email →";
  static const String logout = "Log Out";
  static const String defaultPasswordNote = "⚡ Admin must change this password on first login.";

  // ── Status Labels ──────────────────────────────────────────────────────────
  static const String statusActive = "ACTIVE";
  static const String statusMaintenance = "MAINT.";
  static const String statusIdle = "IDLE";
  static const String statusBanned = "BANNED";
  static const String statusWarned = "WARNED";
  static const String statusPending = "PENDING";
  static const String statusCompleted = "DONE";
  static const String statusUnpaid = "UNPAID";
  static const String statusPaid = "PAID";
  static const String statusOnTrip = "ON TRIP";
  static const String statusAvailable = "AVAILABLE";
  static const String statusOffDuty = "OFF DUTY";
  static const String statusValid = "VALID";
  static const String statusExpiring = "EXPIRING";
  static const String statusExpired = "EXPIRED";

  // ── Role 1: Super Admin (Platform Control) ─────────────────────────────────
  static const String superDashTitle = "Platform Control";
  static const String superDashSub = "Gambit TSL · Super Admin";
  static const String registerCompany = "Register Company";
  static const String companyNameLabel = "COMPANY NAME";
  static const String adminUsernameLabel = "ADMIN USERNAME";
  static const String recoveryEmailLabel = "RECOVERY EMAIL (OPTIONAL)";

  // ── Role 2: Company Admin (Modules) ────────────────────────────────────────
  static const String moduleFleet = "Fleet";
  static const String moduleTrips = "Trips";
  static const String moduleDrivers = "Drivers";
  static const String moduleDocuments = "Documents";
  static const String moduleInventory = "Inventory";
  static const String moduleInvoices = "Invoices";
  static const String moduleFueling = "Fueling";
  static const String moduleSettings = "Settings";

  // ── Fleet Registry ─────────────────────────────────────────────────────────
  static const String fleetTitle = "Fleet Registry";
  static const String registerVehicle = "Register Vehicle";
  static const String regNumberLabel = "REG NUMBER";
  static const String vehicleTypeLabel = "VEHICLE TYPE";
  static const String modelLabel = "MODEL";
  static const String yearLabel = "YEAR";
  static const String engineNumberLabel = "ENGINE NUMBER";
  static const String chassisNumberLabel = "CHASSIS NUMBER";
  static const List<String> vehicleTypes = ["Freightliner", "HOWO", "IVECO", "VOLVO", "SHACMAN", "DAF", "MAN"];

  // ── Trip Booking ───────────────────────────────────────────────────────────
  static const String tripsTitle = "Trip Booking";
  static const String bookTrip = "Book New Trip";
  static const String originLabel = "FROM (ORIGIN)";
  static const String destinationLabel = "TO (DESTINATION)";
  static const String driverSelectLabel = "DRIVER";
  static const String cargoTypeLabel = "CARGO TYPE";
  static const String tonnageLabel = "TONNAGE (MT)";
  static const String rateLabel = "RATE (\$/MT)";
  static const String driverChecklistTitle = "DRIVER CHECKLIST";
  static const List<String> tripChecklist = [
    "Loading instruction",
    "Route risk assessment",
    "POD number",
    "ODO Reading",
    "Weighbridge site"
  ];

  // ── Inventory Management ───────────────────────────────────────────────────
  static const String inventoryTitle = "Inventory";
  static const String addInventoryItem = "Add Inventory Item";
  static const String itemNameLabel = "ITEM NAME";
  static const String qtyLabel = "QTY";
  static const String unitLabel = "UNIT";
  static const String categoryLabel = "CATEGORY";
  static const String unitRateLabel = "UNIT RATE (\$)";
  static const String vendorLabel = "VENDOR";
  static const List<String> inventoryUnits = ["Pcs", "Litres", "Sets", "Kg", "Metres"];
  static const List<String> inventoryCategories = ["Spares", "Lubricants", "Tyres", "Consumables", "Tools"];

  // ── Drivers ────────────────────────────────────────────────────────────────
  static const String driversTitle = "Drivers";
  static const String registerDriver = "Register Driver";
  static const String firstNameLabel = "FIRST NAME";
  static const String surnameLabel = "SURNAME";
  static const String idNumberLabel = "ID NUMBER";
  static const String licenseNumberLabel = "LICENSE NUMBER";
  static const String phoneLabel = "PHONE";
  static const String genderLabel = "GENDER";

  // ── Documents & Compliance ─────────────────────────────────────────────────
  static const String documentsTitle = "Documents";
  static const String documentsSub = "Compliance & permits";
  static const String uploadDocument = "Upload Document";

  // ── Invoices & Billing ─────────────────────────────────────────────────────
  static const String invoicesTitle = "Invoices";
  static const String invoicesSub = "Billing & payments";
  static const String markPaid = "Mark Paid";

  // ── Fueling ────────────────────────────────────────────────────────────────
  static const String fuelingTitle = "Fueling Stations";
  static const String fuelingSub = "Fuel accounts & orders";
  static const String addStation = "Add Station";
  static const String orderFuel = "Order";

  // ── Role 3: Staff (Operations) ─────────────────────────────────────────────
  static const String staffDashTitle = "Operations";
  static const String activeTripBanner = "ACTIVE TRIP";
  static const String updatePod = "Update POD";
  static const String updateOdo = "ODO";
  static const String requestInventory = "Request Inventory";
  static const String submitDocuments = "Submit Documents";
}
