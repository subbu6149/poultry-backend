-- ============================================================
-- FARM MANAGER DATABASE SCHEMA
-- MySQL 8.0+
-- ============================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- Drop existing database and create fresh
DROP DATABASE IF EXISTS farm_manager;
CREATE DATABASE farm_manager CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE farm_manager;

-- ============================================================
-- 1. AUTHENTICATION & AUTHORIZATION
-- ============================================================

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    role_id INT,
    is_active BOOLEAN DEFAULT TRUE,
    last_login DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by INT,
    updated_by INT,
    INDEX idx_username (username),
    INDEX idx_role (role_id)
) ENGINE=InnoDB;

CREATE TABLE roles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    is_system BOOLEAN DEFAULT FALSE COMMENT 'System roles cannot be deleted',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE permissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    module VARCHAR(50) NOT NULL COMMENT 'e.g., DASHBOARD, FARMS, BATCHES, FEED, EGGS, HEALTH, ACCOUNTS',
    action VARCHAR(50) NOT NULL COMMENT 'e.g., VIEW, CREATE, EDIT, DELETE, EXPORT',
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_module_action (module, action)
) ENGINE=InnoDB;

CREATE TABLE role_permissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    role_id INT NOT NULL,
    permission_id INT NOT NULL,
    granted BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_role_permission (role_id, permission_id),
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- 2. MASTER DATA
-- ============================================================

CREATE TABLE companies (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    legal_name VARCHAR(200),
    gstin VARCHAR(15),
    pan VARCHAR(10),
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    pincode VARCHAR(10),
    phone VARCHAR(20),
    email VARCHAR(100),
    logo_url VARCHAR(500),
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE states (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    code VARCHAR(10),
    gst_state_code VARCHAR(2),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE places (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    state_id INT,
    district VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (state_id) REFERENCES states(id)
) ENGINE=InnoDB;

CREATE TABLE units (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    short_name VARCHAR(10),
    unit_type VARCHAR(20) COMMENT 'WEIGHT, VOLUME, LENGTH, COUNT',
    base_unit_id INT,
    conversion_factor DECIMAL(18,6) DEFAULT 1.0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (base_unit_id) REFERENCES units(id)
) ENGINE=InnoDB;

CREATE TABLE item_categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    parent_id INT,
    category_type VARCHAR(30) COMMENT 'FEED_RM, FEED_FINISHED, EGG, MEDICINE, ASSET, CONSUMABLE',
    hsn_code VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_id) REFERENCES item_categories(id)
) ENGINE=InnoDB;

CREATE TABLE items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    category_id INT,
    stock_category VARCHAR(20) COMMENT 'FEED_RM, FEED_FINISHED, EGG, MEDICINE, ASSET, OTHER',
    base_unit_id INT,
    hsn_code VARCHAR(20),
    gst_rate_id INT,
    opening_stock DECIMAL(18,4) DEFAULT 0,
    current_stock DECIMAL(18,4) DEFAULT 0,
    reorder_level DECIMAL(18,4),
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES item_categories(id),
    FOREIGN KEY (base_unit_id) REFERENCES units(id),
    INDEX idx_stock_category (stock_category),
    INDEX idx_code (code)
) ENGINE=InnoDB;

CREATE TABLE party_types (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL COMMENT 'SUPPLIER, CUSTOMER, TRANSPORTER, BOTH_SUP_CUS',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE parties (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) UNIQUE,
    name VARCHAR(200) NOT NULL,
    party_type_id INT,
    gstin VARCHAR(15),
    pan VARCHAR(10),
    contact_person VARCHAR(100),
    phone VARCHAR(20),
    email VARCHAR(100),
    address TEXT,
    city VARCHAR(100),
    state_id INT,
    pincode VARCHAR(10),
    opening_balance DECIMAL(18,2) DEFAULT 0,
    balance_type ENUM('DR', 'CR') DEFAULT 'DR',
    current_balance DECIMAL(18,2) DEFAULT 0,
    credit_limit DECIMAL(18,2),
    credit_days INT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (party_type_id) REFERENCES party_types(id),
    FOREIGN KEY (state_id) REFERENCES states(id),
    INDEX idx_party_type (party_type_id)
) ENGINE=InnoDB;

-- ============================================================
-- 3. FARM STRUCTURE
-- ============================================================

CREATE TABLE sites (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    site_type VARCHAR(30) COMMENT 'FARM, FEED_PLANT, GUDAM, HATCHERY',
    address TEXT,
    place_id INT,
    state_id INT,
    pincode VARCHAR(10),
    contact_person VARCHAR(100),
    phone VARCHAR(20),
    capacity_birds INT,
    area_sqft DECIMAL(10,2),
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (place_id) REFERENCES places(id),
    FOREIGN KEY (state_id) REFERENCES states(id),
    INDEX idx_site_type (site_type)
) ENGINE=InnoDB;

CREATE TABLE sheds (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    site_id INT NOT NULL,
    capacity_birds INT,
    length_ft DECIMAL(10,2),
    width_ft DECIMAL(10,2),
    height_ft DECIMAL(10,2),
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (site_id) REFERENCES sites(id) ON DELETE CASCADE,
    INDEX idx_site (site_id)
) ENGINE=InnoDB;

CREATE TABLE gudams (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    site_id INT,
    gudam_type VARCHAR(30) COMMENT 'FEED_RM, FEED_FINISHED, EGG, MEDICINE, GENERAL',
    address TEXT,
    place_id INT,
    capacity_mt DECIMAL(10,2),
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (site_id) REFERENCES sites(id),
    FOREIGN KEY (place_id) REFERENCES places(id)
) ENGINE=InnoDB;

-- ============================================================
-- 4. BREED & STANDARDS
-- ============================================================

CREATE TABLE breeds (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    breed_type VARCHAR(30) COMMENT 'LAYER, BROILER, PARENT',
    origin VARCHAR(100),
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE bird_standards (
    id INT AUTO_INCREMENT PRIMARY KEY,
    breed_id INT NOT NULL,
    age_week INT NOT NULL,
    cumulative_feed_g DECIMAL(10,2),
    weekly_feed_g DECIMAL(10,2),
    body_weight_g DECIMAL(10,2),
    cumulative_mortality_pct DECIMAL(5,2),
    weekly_mortality_pct DECIMAL(5,2),
    hen_housed_production_pct DECIMAL(5,2),
    hen_day_production_pct DECIMAL(5,2),
    cumulative_eggs_per_bird DECIMAL(10,2),
    avg_egg_weight_g DECIMAL(10,2),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (breed_id) REFERENCES breeds(id) ON DELETE CASCADE,
    UNIQUE KEY unique_breed_week (breed_id, age_week)
) ENGINE=InnoDB;

-- ============================================================
-- 5. BATCHES & PRODUCTION
-- ============================================================

CREATE TABLE batches (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    breed_id INT NOT NULL,
    bird_standard_id INT,
    site_id INT NOT NULL,
    current_shed_id INT,
    placement_date DATE NOT NULL,
    opening_birds INT NOT NULL,
    current_birds INT,
    source VARCHAR(100) COMMENT 'Hatchery or supplier name',
    parent_batch_id INT COMMENT 'For parent stock lineage',
    status ENUM('ACTIVE', 'CLOSED') DEFAULT 'ACTIVE',
    closed_date DATE,
    remarks TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by INT,
    FOREIGN KEY (breed_id) REFERENCES breeds(id),
    FOREIGN KEY (bird_standard_id) REFERENCES bird_standards(id),
    FOREIGN KEY (site_id) REFERENCES sites(id),
    FOREIGN KEY (current_shed_id) REFERENCES sheds(id),
    FOREIGN KEY (parent_batch_id) REFERENCES batches(id),
    FOREIGN KEY (created_by) REFERENCES users(id),
    INDEX idx_status (status),
    INDEX idx_site (site_id)
) ENGINE=InnoDB;

CREATE TABLE batch_shed_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    batch_id INT NOT NULL,
    shed_id INT NOT NULL,
    site_id INT NOT NULL,
    from_date DATE NOT NULL,
    to_date DATE,
    bird_count INT,
    remarks TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (batch_id) REFERENCES batches(id) ON DELETE CASCADE,
    FOREIGN KEY (shed_id) REFERENCES sheds(id),
    FOREIGN KEY (site_id) REFERENCES sites(id),
    INDEX idx_batch (batch_id),
    INDEX idx_dates (from_date, to_date)
) ENGINE=InnoDB;

CREATE TABLE bird_movements (
    id INT AUTO_INCREMENT PRIMARY KEY,
    batch_id INT NOT NULL,
    site_id INT NOT NULL,
    shed_id INT,
    movement_date DATE NOT NULL,
    movement_type ENUM('PLACEMENT', 'MORTALITY', 'CULL', 'TRANSFER_OUT', 'TRANSFER_IN', 'SALE') NOT NULL,
    quantity INT NOT NULL,
    reason VARCHAR(200),
    remarks TEXT,
    link_type VARCHAR(30) COMMENT 'TRANSFER, SALE, etc',
    link_id INT COMMENT 'ID of related transfer or sale record',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by INT,
    FOREIGN KEY (batch_id) REFERENCES batches(id),
    FOREIGN KEY (site_id) REFERENCES sites(id),
    FOREIGN KEY (shed_id) REFERENCES sheds(id),
    FOREIGN KEY (created_by) REFERENCES users(id),
    INDEX idx_batch_date (batch_id, movement_date),
    INDEX idx_type (movement_type)
) ENGINE=InnoDB;

CREATE TABLE bird_transfers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    transfer_no VARCHAR(50) UNIQUE,
    transfer_date DATE NOT NULL,
    from_batch_id INT NOT NULL,
    from_shed_id INT NOT NULL,
    from_site_id INT NOT NULL,
    to_batch_id INT NOT NULL,
    to_shed_id INT NOT NULL,
    to_site_id INT NOT NULL,
    quantity INT NOT NULL,
    reason VARCHAR(200),
    status ENUM('PENDING', 'COMPLETED', 'CANCELLED') DEFAULT 'PENDING',
    remarks TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by INT,
    FOREIGN KEY (from_batch_id) REFERENCES batches(id),
    FOREIGN KEY (to_batch_id) REFERENCES batches(id),
    FOREIGN KEY (from_shed_id) REFERENCES sheds(id),
    FOREIGN KEY (to_shed_id) REFERENCES sheds(id),
    FOREIGN KEY (from_site_id) REFERENCES sites(id),
    FOREIGN KEY (to_site_id) REFERENCES sites(id),
    FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE daily_production (
    id INT AUTO_INCREMENT PRIMARY KEY,
    batch_id INT NOT NULL,
    shed_id INT NOT NULL,
    site_id INT NOT NULL,
    entry_date DATE NOT NULL,
    live_birds_snapshot INT NOT NULL,
    total_eggs INT DEFAULT 0 COMMENT 'Computed from lines',
    production_pct DECIMAL(5,2) COMMENT 'total_eggs / live_birds * 100',
    status ENUM('DRAFT', 'CONFIRMED') DEFAULT 'DRAFT',
    remarks TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by INT,
    UNIQUE KEY unique_batch_date (batch_id, entry_date),
    FOREIGN KEY (batch_id) REFERENCES batches(id),
    FOREIGN KEY (shed_id) REFERENCES sheds(id),
    FOREIGN KEY (site_id) REFERENCES sites(id),
    FOREIGN KEY (created_by) REFERENCES users(id),
    INDEX idx_entry_date (entry_date)
) ENGINE=InnoDB;

CREATE TABLE daily_production_lines (
    id INT AUTO_INCREMENT PRIMARY KEY,
    daily_production_id INT NOT NULL,
    egg_item_id INT NOT NULL COMMENT 'Links to items table for egg grades',
    good_qty INT DEFAULT 0,
    damage_qty INT DEFAULT 0,
    double_yolk_qty INT DEFAULT 0,
    total_qty INT AS (good_qty + damage_qty + double_yolk_qty) STORED,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (daily_production_id) REFERENCES daily_production(id) ON DELETE CASCADE,
    FOREIGN KEY (egg_item_id) REFERENCES items(id),
    INDEX idx_production (daily_production_id)
) ENGINE=InnoDB;

CREATE TABLE daily_percent_entries (
    id INT AUTO_INCREMENT PRIMARY KEY,
    batch_id INT NOT NULL,
    entry_date DATE NOT NULL,
    metric_key VARCHAR(50) NOT NULL COMMENT 'FEED_INTAKE, WATER_INTAKE, MORTALITY, etc',
    value_pct DECIMAL(5,2),
    value_absolute DECIMAL(18,4) COMMENT 'Optional absolute value',
    remarks TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by INT,
    UNIQUE KEY unique_batch_date_metric (batch_id, entry_date, metric_key),
    FOREIGN KEY (batch_id) REFERENCES batches(id),
    FOREIGN KEY (created_by) REFERENCES users(id),
    INDEX idx_metric (metric_key)
) ENGINE=InnoDB;

CREATE TABLE body_weights (
    id INT AUTO_INCREMENT PRIMARY KEY,
    batch_id INT NOT NULL,
    shed_id INT NOT NULL,
    measure_date DATE NOT NULL,
    sample_count INT NOT NULL,
    avg_weight_g DECIMAL(10,2) NOT NULL,
    remarks TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by INT,
    FOREIGN KEY (batch_id) REFERENCES batches(id),
    FOREIGN KEY (shed_id) REFERENCES sheds(id),
    FOREIGN KEY (created_by) REFERENCES users(id),
    INDEX idx_batch_date (batch_id, measure_date)
) ENGINE=InnoDB;

CREATE TABLE batch_schedules (
    id INT AUTO_INCREMENT PRIMARY KEY,
    batch_id INT NOT NULL,
    site_id INT NOT NULL,
    shed_id INT,
    category ENUM('FARM', 'HEALTH') NOT NULL,
    activity_type VARCHAR(100) NOT NULL,
    due_date DATE NOT NULL,
    completed_date DATE,
    assigned_to_user_id INT,
    assigned_to_name VARCHAR(100),
    status ENUM('PENDING', 'DONE', 'CANCELLED') DEFAULT 'PENDING',
    source_module VARCHAR(50) COMMENT 'HEALTH_EVENT, MANUAL',
    source_id INT,
    remarks TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (batch_id) REFERENCES batches(id),
    FOREIGN KEY (site_id) REFERENCES sites(id),
    FOREIGN KEY (shed_id) REFERENCES sheds(id),
    FOREIGN KEY (assigned_to_user_id) REFERENCES users(id),
    INDEX idx_status (status),
    INDEX idx_due_date (due_date)
) ENGINE=InnoDB;

-- ============================================================
-- 6. FEED MANAGEMENT
-- ============================================================

CREATE TABLE feed_formulations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    feed_type VARCHAR(50) COMMENT 'STARTER, GROWER, LAYER, BROILER',
    batch_size_kg DECIMAL(18,4) DEFAULT 1000,
    status ENUM('DRAFT', 'APPROVED', 'ARCHIVED') DEFAULT 'DRAFT',
    cost_per_kg DECIMAL(18,4) COMMENT 'Computed from ingredients',
    remarks TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by INT,
    approved_by INT,
    approved_date DATETIME,
    FOREIGN KEY (created_by) REFERENCES users(id),
    FOREIGN KEY (approved_by) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE feed_formulation_lines (
    id INT AUTO_INCREMENT PRIMARY KEY,
    formulation_id INT NOT NULL,
    item_id INT NOT NULL COMMENT 'Raw material',
    percentage DECIMAL(5,2) NOT NULL,
    quantity_kg DECIMAL(18,4) COMMENT 'Computed: batch_size * percentage',
    cost_per_kg DECIMAL(18,4),
    line_cost DECIMAL(18,4),
    sort_order INT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (formulation_id) REFERENCES feed_formulations(id) ON DELETE CASCADE,
    FOREIGN KEY (item_id) REFERENCES items(id),
    INDEX idx_formulation (formulation_id)
) ENGINE=InnoDB;

CREATE TABLE feed_productions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    production_no VARCHAR(50) UNIQUE,
    production_date DATE NOT NULL,
    site_id INT NOT NULL COMMENT 'Feed plant',
    formulation_id INT NOT NULL,
    planned_qty_kg DECIMAL(18,4) NOT NULL,
    actual_qty_kg DECIMAL(18,4),
    output_item_id INT COMMENT 'Finished feed item',
    output_gudam_id INT,
    status ENUM('PLANNED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED') DEFAULT 'PLANNED',
    remarks TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by INT,
    FOREIGN KEY (site_id) REFERENCES sites(id),
    FOREIGN KEY (formulation_id) REFERENCES feed_formulations(id),
    FOREIGN KEY (output_item_id) REFERENCES items(id),
    FOREIGN KEY (output_gudam_id) REFERENCES gudams(id),
    FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE feed_production_lines (
    id INT AUTO_INCREMENT PRIMARY KEY,
    production_id INT NOT NULL,
    item_id INT NOT NULL,
    planned_qty_kg DECIMAL(18,4) NOT NULL,
    actual_qty_kg DECIMAL(18,4),
    source_gudam_id INT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (production_id) REFERENCES feed_productions(id) ON DELETE CASCADE,
    FOREIGN KEY (item_id) REFERENCES items(id),
    FOREIGN KEY (source_gudam_id) REFERENCES gudams(id)
) ENGINE=InnoDB;

CREATE TABLE feed_usages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usage_date DATE NOT NULL,
    site_id INT NOT NULL,
    shed_id INT,
    batch_id INT,
    gudam_id INT,
    item_id INT NOT NULL,
    entered_qty DECIMAL(18,4) NOT NULL,
    unit_id INT NOT NULL,
    qty_base DECIMAL(18,4) COMMENT 'Converted to base unit (KG)',
    status ENUM('DRAFT', 'CONFIRMED') DEFAULT 'DRAFT',
    stock_ledger_id INT COMMENT 'Link to stock ledger',
    remarks TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by INT,
    FOREIGN KEY (site_id) REFERENCES sites(id),
    FOREIGN KEY (shed_id) REFERENCES sheds(id),
    FOREIGN KEY (batch_id) REFERENCES batches(id),
    FOREIGN KEY (gudam_id) REFERENCES gudams(id),
    FOREIGN KEY (item_id) REFERENCES items(id),
    FOREIGN KEY (unit_id) REFERENCES units(id),
    FOREIGN KEY (created_by) REFERENCES users(id),
    INDEX idx_batch_date (batch_id, usage_date)
) ENGINE=InnoDB;

-- ============================================================
-- 7. INVENTORY & STOCK
-- ============================================================

CREATE TABLE stock_ledger (
    id INT AUTO_INCREMENT PRIMARY KEY,
    transaction_date DATE NOT NULL,
    item_id INT NOT NULL,
    gudam_id INT,
    site_id INT,
    stock_category VARCHAR(30) COMMENT 'FEED_RM, FEED_FINISHED, EGG, MEDICINE, OTHER',
    transaction_type VARCHAR(30) COMMENT 'RECEIPT, ISSUE, TRANSFER_IN, TRANSFER_OUT, ADJUSTMENT, PRODUCTION',
    quantity DECIMAL(18,4) NOT NULL COMMENT 'Positive for IN, Negative for OUT',
    unit_id INT NOT NULL,
    rate DECIMAL(18,4),
    amount DECIMAL(18,2),
    balance_qty DECIMAL(18,4) COMMENT 'Running balance',
    source_type VARCHAR(50) COMMENT 'MATERIAL_RECEIPT, FEED_USAGE, EGG_PRODUCTION, STOCK_TRANSFER',
    source_id INT,
    reference_no VARCHAR(100),
    remarks TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by INT,
    FOREIGN KEY (item_id) REFERENCES items(id),
    FOREIGN KEY (gudam_id) REFERENCES gudams(id),
    FOREIGN KEY (site_id) REFERENCES sites(id),
    FOREIGN KEY (unit_id) REFERENCES units(id),
    FOREIGN KEY (created_by) REFERENCES users(id),
    INDEX idx_item_date (item_id, transaction_date),
    INDEX idx_gudam (gudam_id),
    INDEX idx_source (source_type, source_id)
) ENGINE=InnoDB;

CREATE TABLE material_receipts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    receipt_no VARCHAR(50) UNIQUE,
    receipt_date DATE NOT NULL,
    party_id INT NOT NULL,
    gudam_id INT NOT NULL,
    site_id INT,
    stock_category VARCHAR(30),
    invoice_id INT COMMENT 'Links to purchase invoice',
    party_invoice_no VARCHAR(100),
    party_invoice_date DATE,
    vehicle_no VARCHAR(50),
    lr_no VARCHAR(100),
    lr_date DATE,
    gross_weight DECIMAL(18,4),
    tare_weight DECIMAL(18,4),
    net_weight DECIMAL(18,4),
    status ENUM('DRAFT', 'CONFIRMED') DEFAULT 'DRAFT',
    remarks TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by INT,
    FOREIGN KEY (party_id) REFERENCES parties(id),
    FOREIGN KEY (gudam_id) REFERENCES gudams(id),
    FOREIGN KEY (site_id) REFERENCES sites(id),
    FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE material_receipt_lines (
    id INT AUTO_INCREMENT PRIMARY KEY,
    receipt_id INT NOT NULL,
    item_id INT NOT NULL,
    quantity DECIMAL(18,4) NOT NULL,
    unit_id INT NOT NULL,
    rate DECIMAL(18,4),
    amount DECIMAL(18,2),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (receipt_id) REFERENCES material_receipts(id) ON DELETE CASCADE,
    FOREIGN KEY (item_id) REFERENCES items(id),
    FOREIGN KEY (unit_id) REFERENCES units(id)
) ENGINE=InnoDB;

CREATE TABLE stock_transfers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    transfer_no VARCHAR(50) UNIQUE,
    transfer_date DATE NOT NULL,
    from_gudam_id INT NOT NULL,
    to_gudam_id INT NOT NULL,
    from_site_id INT,
    to_site_id INT,
    stock_category VARCHAR(30),
    vehicle_no VARCHAR(50),
    status ENUM('PENDING', 'IN_TRANSIT', 'RECEIVED', 'CANCELLED') DEFAULT 'PENDING',
    remarks TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by INT,
    FOREIGN KEY (from_gudam_id) REFERENCES gudams(id),
    FOREIGN KEY (to_gudam_id) REFERENCES gudams(id),
    FOREIGN KEY (from_site_id) REFERENCES sites(id),
    FOREIGN KEY (to_site_id) REFERENCES sites(id),
    FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE stock_transfer_lines (
    id INT AUTO_INCREMENT PRIMARY KEY,
    transfer_id INT NOT NULL,
    item_id INT NOT NULL,
    quantity DECIMAL(18,4) NOT NULL,
    unit_id INT NOT NULL,
    received_quantity DECIMAL(18,4),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (transfer_id) REFERENCES stock_transfers(id) ON DELETE CASCADE,
    FOREIGN KEY (item_id) REFERENCES items(id),
    FOREIGN KEY (unit_id) REFERENCES units(id)
) ENGINE=InnoDB;

CREATE TABLE stock_adjustments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    adjustment_no VARCHAR(50) UNIQUE,
    adjustment_date DATE NOT NULL,
    gudam_id INT NOT NULL,
    site_id INT,
    stock_category VARCHAR(30),
    adjustment_type ENUM('PHYSICAL_VERIFICATION', 'DAMAGE', 'EXPIRY', 'OTHER') NOT NULL,
    reason TEXT,
    status ENUM('DRAFT', 'CONFIRMED') DEFAULT 'DRAFT',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by INT,
    approved_by INT,
    FOREIGN KEY (gudam_id) REFERENCES gudams(id),
    FOREIGN KEY (site_id) REFERENCES sites(id),
    FOREIGN KEY (created_by) REFERENCES users(id),
    FOREIGN KEY (approved_by) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE stock_adjustment_lines (
    id INT AUTO_INCREMENT PRIMARY KEY,
    adjustment_id INT NOT NULL,
    item_id INT NOT NULL,
    book_qty DECIMAL(18,4),
    physical_qty DECIMAL(18,4),
    difference_qty DECIMAL(18,4),
    unit_id INT NOT NULL,
    remarks TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (adjustment_id) REFERENCES stock_adjustments(id) ON DELETE CASCADE,
    FOREIGN KEY (item_id) REFERENCES items(id),
    FOREIGN KEY (unit_id) REFERENCES units(id)
) ENGINE=InnoDB;

-- ============================================================
-- 8. EGG MANAGEMENT
-- ============================================================

CREATE TABLE egg_rates (
    id INT AUTO_INCREMENT PRIMARY KEY,
    rate_date DATE NOT NULL,
    rate_type VARCHAR(30) NOT NULL COMMENT 'DAILY, NECC, PLACE, TRADER, PULP_TRAY, PLASTIC_TRAY, DAMAGE, DOUBLE',
    place_id INT,
    party_id INT,
    egg_item_id INT,
    rate DECIMAL(18,4) NOT NULL,
    rate_unit VARCHAR(20) COMMENT 'PER_EGG, PER_100, PER_TRAY',
    source VARCHAR(20) DEFAULT 'MANUAL' COMMENT 'MANUAL, NECC',
    fetched_at DATETIME,
    remarks TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by INT,
    FOREIGN KEY (place_id) REFERENCES places(id),
    FOREIGN KEY (party_id) REFERENCES parties(id),
    FOREIGN KEY (egg_item_id) REFERENCES items(id),
    FOREIGN KEY (created_by) REFERENCES users(id),
    INDEX idx_rate_date (rate_date),
    INDEX idx_rate_type (rate_type)
) ENGINE=InnoDB;

CREATE TABLE egg_sales (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sale_no VARCHAR(50) UNIQUE,
    sale_date DATE NOT NULL,
    site_id INT NOT NULL,
    gudam_id INT,
    party_id INT NOT NULL,
    place_id INT,
    rate_type VARCHAR(30),
    sales_invoice_id INT,
    vehicle_no VARCHAR(50),
    status ENUM('DRAFT', 'CONFIRMED', 'INVOICED') DEFAULT 'DRAFT',
    remarks TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by INT,
    FOREIGN KEY (site_id) REFERENCES sites(id),
    FOREIGN KEY (gudam_id) REFERENCES gudams(id),
    FOREIGN KEY (party_id) REFERENCES parties(id),
    FOREIGN KEY (place_id) REFERENCES places(id),
    FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE egg_sale_lines (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sale_id INT NOT NULL,
    egg_item_id INT NOT NULL,
    qty_eggs INT NOT NULL,
    trays DECIMAL(10,2),
    rate DECIMAL(18,4) NOT NULL,
    rate_unit VARCHAR(20),
    amount DECIMAL(18,2),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sale_id) REFERENCES egg_sales(id) ON DELETE CASCADE,
    FOREIGN KEY (egg_item_id) REFERENCES items(id)
) ENGINE=InnoDB;

CREATE TABLE egg_weights (
    id INT AUTO_INCREMENT PRIMARY KEY,
    site_id INT NOT NULL,
    shed_id INT,
    batch_id INT,
    egg_item_id INT NOT NULL,
    measure_date DATE NOT NULL,
    sample_qty INT NOT NULL,
    avg_weight_g DECIMAL(10,2) NOT NULL,
    remarks TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by INT,
    FOREIGN KEY (site_id) REFERENCES sites(id),
    FOREIGN KEY (shed_id) REFERENCES sheds(id),
    FOREIGN KEY (batch_id) REFERENCES batches(id),
    FOREIGN KEY (egg_item_id) REFERENCES items(id),
    FOREIGN KEY (created_by) REFERENCES users(id),
    INDEX idx_batch_date (batch_id, measure_date)
) ENGINE=InnoDB;

-- ============================================================
-- 9. HEALTH MANAGEMENT
-- ============================================================

CREATE TABLE health_event_types (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    kind ENUM('VACCINATION', 'TREATMENT', 'DISEASE', 'OTHER') NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE schedule_templates (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    breed_id INT,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (breed_id) REFERENCES breeds(id)
) ENGINE=InnoDB;

CREATE TABLE schedule_template_lines (
    id INT AUTO_INCREMENT PRIMARY KEY,
    template_id INT NOT NULL,
    event_type_id INT NOT NULL,
    age_day INT NOT NULL,
    product_name VARCHAR(200),
    dose VARCHAR(100),
    unit VARCHAR(50),
    route VARCHAR(100) COMMENT 'Oral, Injection, Drinking water, etc',
    remarks TEXT,
    sort_order INT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (template_id) REFERENCES schedule_templates(id) ON DELETE CASCADE,
    FOREIGN KEY (event_type_id) REFERENCES health_event_types(id)
) ENGINE=InnoDB;

CREATE TABLE health_events (
    id INT AUTO_INCREMENT PRIMARY KEY,
    batch_id INT NOT NULL,
    site_id INT NOT NULL,
    shed_id INT,
    event_type_id INT NOT NULL,
    scheduled_date DATE,
    completed_date DATE,
    product_name VARCHAR(200),
    item_id INT COMMENT 'Link to medicine/vaccine item',
    dose VARCHAR(100),
    unit VARCHAR(50),
    route VARCHAR(100),
    administered_by VARCHAR(100),
    symptoms TEXT,
    diagnosis TEXT,
    treatment TEXT,
    outcome TEXT,
    status ENUM('SCHEDULED', 'DONE', 'CANCELLED') DEFAULT 'SCHEDULED',
    remarks TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by INT,
    FOREIGN KEY (batch_id) REFERENCES batches(id),
    FOREIGN KEY (site_id) REFERENCES sites(id),
    FOREIGN KEY (shed_id) REFERENCES sheds(id),
    FOREIGN KEY (event_type_id) REFERENCES health_event_types(id),
    FOREIGN KEY (item_id) REFERENCES items(id),
    FOREIGN KEY (created_by) REFERENCES users(id),
    INDEX idx_batch (batch_id),
    INDEX idx_status (status),
    INDEX idx_scheduled_date (scheduled_date)
) ENGINE=InnoDB;

CREATE TABLE lab_reports (
    id INT AUTO_INCREMENT PRIMARY KEY,
    batch_id INT,
    site_id INT,
    shed_id INT,
    lab_name VARCHAR(200),
    sample_date DATE,
    report_date DATE,
    test_type VARCHAR(100),
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by INT,
    FOREIGN KEY (batch_id) REFERENCES batches(id),
    FOREIGN KEY (site_id) REFERENCES sites(id),
    FOREIGN KEY (shed_id) REFERENCES sheds(id),
    FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB;

-- ============================================================
-- 10. ACCOUNTS & GST
-- ============================================================

CREATE TABLE gst_rates (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    cgst_pct DECIMAL(5,2) DEFAULT 0,
    sgst_pct DECIMAL(5,2) DEFAULT 0,
    igst_pct DECIMAL(5,2) DEFAULT 0,
    effective_from DATE,
    effective_to DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE invoices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    invoice_no VARCHAR(50) UNIQUE NOT NULL,
    invoice_type ENUM('SALE', 'PURCHASE') NOT NULL,
    invoice_date DATE NOT NULL,
    party_id INT NOT NULL,
    site_id INT,
    place_of_supply_state_id INT,
    tax_mode ENUM('INTRA', 'INTER', 'NONE') DEFAULT 'INTRA',
    subtotal DECIMAL(18,2) DEFAULT 0,
    discount_total DECIMAL(18,2) DEFAULT 0,
    taxable_total DECIMAL(18,2) DEFAULT 0,
    cgst_total DECIMAL(18,2) DEFAULT 0,
    sgst_total DECIMAL(18,2) DEFAULT 0,
    igst_total DECIMAL(18,2) DEFAULT 0,
    round_off DECIMAL(18,2) DEFAULT 0,
    grand_total DECIMAL(18,2) DEFAULT 0,
    due_date DATE,
    status ENUM('DRAFT', 'CONFIRMED', 'PAID', 'CANCELLED') DEFAULT 'DRAFT',
    source_type VARCHAR(50) COMMENT 'EGG_SALE, GUDAM_SALE, MATERIAL_RECEIPT',
    source_id INT,
    party_invoice_no VARCHAR(100) COMMENT 'For purchases',
    party_invoice_date DATE,
    remarks TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by INT,
    FOREIGN KEY (party_id) REFERENCES parties(id),
    FOREIGN KEY (site_id) REFERENCES sites(id),
    FOREIGN KEY (place_of_supply_state_id) REFERENCES states(id),
    FOREIGN KEY (created_by) REFERENCES users(id),
    INDEX idx_invoice_type (invoice_type),
    INDEX idx_invoice_date (invoice_date),
    INDEX idx_party (party_id)
) ENGINE=InnoDB;

CREATE TABLE invoice_lines (
    id INT AUTO_INCREMENT PRIMARY KEY,
    invoice_id INT NOT NULL,
    item_id INT,
    description TEXT,
    hsn_code VARCHAR(20),
    quantity DECIMAL(18,4),
    unit_id INT,
    rate DECIMAL(18,4),
    amount DECIMAL(18,2),
    discount DECIMAL(18,2) DEFAULT 0,
    taxable_value DECIMAL(18,2),
    gst_rate_id INT,
    cgst_pct DECIMAL(5,2),
    sgst_pct DECIMAL(5,2),
    igst_pct DECIMAL(5,2),
    cgst_amt DECIMAL(18,2),
    sgst_amt DECIMAL(18,2),
    igst_amt DECIMAL(18,2),
    line_total DECIMAL(18,2),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE,
    FOREIGN KEY (item_id) REFERENCES items(id),
    FOREIGN KEY (unit_id) REFERENCES units(id),
    FOREIGN KEY (gst_rate_id) REFERENCES gst_rates(id)
) ENGINE=InnoDB;

CREATE TABLE payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    voucher_no VARCHAR(50) UNIQUE NOT NULL,
    voucher_type ENUM('RECEIPT', 'PAYMENT') NOT NULL,
    party_id INT NOT NULL,
    site_id INT,
    pay_date DATE NOT NULL,
    mode VARCHAR(30) COMMENT 'CASH, CHEQUE, BANK_TRANSFER, UPI',
    reference VARCHAR(100) COMMENT 'Cheque no, Transaction ID',
    amount DECIMAL(18,2) NOT NULL,
    unallocated_amount DECIMAL(18,2),
    remarks TEXT,
    status ENUM('DRAFT', 'CONFIRMED', 'CANCELLED') DEFAULT 'DRAFT',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by INT,
    FOREIGN KEY (party_id) REFERENCES parties(id),
    FOREIGN KEY (site_id) REFERENCES sites(id),
    FOREIGN KEY (created_by) REFERENCES users(id),
    INDEX idx_voucher_type (voucher_type),
    INDEX idx_pay_date (pay_date)
) ENGINE=InnoDB;

CREATE TABLE payment_allocations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    payment_id INT NOT NULL,
    invoice_id INT NOT NULL,
    amount DECIMAL(18,2) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (payment_id) REFERENCES payments(id) ON DELETE CASCADE,
    FOREIGN KEY (invoice_id) REFERENCES invoices(id)
) ENGINE=InnoDB;

CREATE TABLE party_ledger (
    id INT AUTO_INCREMENT PRIMARY KEY,
    party_id INT NOT NULL,
    transaction_date DATE NOT NULL,
    voucher_type VARCHAR(30) COMMENT 'INVOICE, PAYMENT, OPENING',
    voucher_no VARCHAR(50),
    source_type VARCHAR(50),
    source_id INT,
    debit DECIMAL(18,2) DEFAULT 0,
    credit DECIMAL(18,2) DEFAULT 0,
    balance DECIMAL(18,2),
    remarks TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (party_id) REFERENCES parties(id),
    INDEX idx_party_date (party_id, transaction_date),
    INDEX idx_source (source_type, source_id)
) ENGINE=InnoDB;

CREATE TABLE expense_categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    parent_id INT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_id) REFERENCES expense_categories(id)
) ENGINE=InnoDB;

CREATE TABLE expenses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    expense_no VARCHAR(50) UNIQUE,
    site_id INT,
    expense_date DATE NOT NULL,
    category_id INT NOT NULL,
    vehicle_id INT,
    plant_asset_id INT,
    party_id INT,
    amount DECIMAL(18,2) NOT NULL,
    payment_mode VARCHAR(30),
    narration TEXT,
    status ENUM('DRAFT', 'CONFIRMED') DEFAULT 'DRAFT',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by INT,
    FOREIGN KEY (site_id) REFERENCES sites(id),
    FOREIGN KEY (category_id) REFERENCES expense_categories(id),
    FOREIGN KEY (party_id) REFERENCES parties(id),
    FOREIGN KEY (created_by) REFERENCES users(id),
    INDEX idx_expense_date (expense_date)
) ENGINE=InnoDB;

-- ============================================================
-- 11. VEHICLES & ASSETS
-- ============================================================

CREATE TABLE vehicles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    vehicle_no VARCHAR(50) UNIQUE NOT NULL,
    vehicle_type VARCHAR(50) COMMENT 'TRUCK, TEMPO, CAR, etc',
    owner VARCHAR(100) COMMENT 'OWN, LEASED, HIRED',
    capacity_kg DECIMAL(10,2),
    insurance_expiry DATE,
    fitness_expiry DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE plant_assets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    asset_code VARCHAR(50) UNIQUE,
    name VARCHAR(200) NOT NULL,
    asset_type VARCHAR(50) COMMENT 'MACHINERY, EQUIPMENT, GENERATOR',
    site_id INT,
    purchase_date DATE,
    purchase_value DECIMAL(18,2),
    current_value DECIMAL(18,2),
    warranty_expiry DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (site_id) REFERENCES sites(id)
) ENGINE=InnoDB;

-- ============================================================
-- 12. COMPLAINTS & SUPPORT
-- ============================================================

CREATE TABLE complaint_categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE complaints (
    id INT AUTO_INCREMENT PRIMARY KEY,
    complaint_no VARCHAR(50) UNIQUE,
    category_id INT,
    site_id INT,
    batch_id INT,
    subject VARCHAR(500) NOT NULL,
    description TEXT,
    priority ENUM('LOW', 'MEDIUM', 'HIGH', 'URGENT') DEFAULT 'MEDIUM',
    status ENUM('OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED', 'CANCELLED') DEFAULT 'OPEN',
    reported_by INT,
    assigned_to INT,
    resolved_date DATETIME,
    resolution_notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES complaint_categories(id),
    FOREIGN KEY (site_id) REFERENCES sites(id),
    FOREIGN KEY (batch_id) REFERENCES batches(id),
    FOREIGN KEY (reported_by) REFERENCES users(id),
    FOREIGN KEY (assigned_to) REFERENCES users(id),
    INDEX idx_status (status),
    INDEX idx_priority (priority)
) ENGINE=InnoDB;

-- ============================================================
-- 13. ATTACHMENTS & AUDIT
-- ============================================================

CREATE TABLE attachments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    entity_type VARCHAR(50) NOT NULL COMMENT 'BATCH, HEALTH_EVENT, LAB_REPORT, COMPLAINT',
    entity_id INT NOT NULL,
    file_name VARCHAR(500) NOT NULL,
    file_path VARCHAR(1000) NOT NULL,
    file_size BIGINT,
    mime_type VARCHAR(100),
    uploaded_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    uploaded_by INT,
    FOREIGN KEY (uploaded_by) REFERENCES users(id),
    INDEX idx_entity (entity_type, entity_id)
) ENGINE=InnoDB;

CREATE TABLE audit_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    action VARCHAR(50) NOT NULL COMMENT 'CREATE, UPDATE, DELETE, LOGIN, LOGOUT',
    entity_type VARCHAR(50),
    entity_id INT,
    old_values JSON,
    new_values JSON,
    ip_address VARCHAR(50),
    user_agent TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    INDEX idx_user_date (user_id, created_at),
    INDEX idx_entity (entity_type, entity_id),
    INDEX idx_action (action)
) ENGINE=InnoDB;

-- ============================================================
-- SEED DATA
-- ============================================================

-- Insert default roles
INSERT INTO roles (name, description, is_system) VALUES
('Super Admin', 'Full system access', TRUE),
('Admin', 'Administrative access', TRUE),
('Manager', 'Farm and operations management', TRUE),
('Operator', 'Daily data entry and viewing', TRUE),
('Viewer', 'Read-only access to reports', TRUE);

-- Insert default permissions (modules and actions)
INSERT INTO permissions (module, action, description) VALUES
('DASHBOARD', 'VIEW', 'View dashboard'),
('USERS', 'VIEW', 'View users'),
('USERS', 'CREATE', 'Create users'),
('USERS', 'EDIT', 'Edit users'),
('USERS', 'DELETE', 'Delete users'),
('ROLES', 'VIEW', 'View roles'),
('ROLES', 'CREATE', 'Create roles'),
('ROLES', 'EDIT', 'Edit roles'),
('ROLES', 'DELETE', 'Delete roles'),
('FARMS', 'VIEW', 'View farms and sheds'),
('FARMS', 'CREATE', 'Create farms and sheds'),
('FARMS', 'EDIT', 'Edit farms and sheds'),
('FARMS', 'DELETE', 'Delete farms and sheds'),
('BATCHES', 'VIEW', 'View batches'),
('BATCHES', 'CREATE', 'Create batches'),
('BATCHES', 'EDIT', 'Edit batches'),
('BATCHES', 'DELETE', 'Delete batches'),
('PRODUCTION', 'VIEW', 'View production data'),
('PRODUCTION', 'CREATE', 'Enter production data'),
('PRODUCTION', 'EDIT', 'Edit production data'),
('PRODUCTION', 'DELETE', 'Delete production data'),
('FEED', 'VIEW', 'View feed data'),
('FEED', 'CREATE', 'Create feed formulations'),
('FEED', 'EDIT', 'Edit feed data'),
('FEED', 'DELETE', 'Delete feed data'),
('INVENTORY', 'VIEW', 'View inventory'),
('INVENTORY', 'CREATE', 'Create stock entries'),
('INVENTORY', 'EDIT', 'Edit inventory'),
('INVENTORY', 'DELETE', 'Delete inventory'),
('EGGS', 'VIEW', 'View egg data'),
('EGGS', 'CREATE', 'Create egg entries'),
('EGGS', 'EDIT', 'Edit egg data'),
('EGGS', 'DELETE', 'Delete egg data'),
('HEALTH', 'VIEW', 'View health records'),
('HEALTH', 'CREATE', 'Create health events'),
('HEALTH', 'EDIT', 'Edit health records'),
('HEALTH', 'DELETE', 'Delete health records'),
('ACCOUNTS', 'VIEW', 'View accounts'),
('ACCOUNTS', 'CREATE', 'Create transactions'),
('ACCOUNTS', 'EDIT', 'Edit accounts'),
('ACCOUNTS', 'DELETE', 'Delete transactions'),
('REPORTS', 'VIEW', 'View reports'),
('REPORTS', 'EXPORT', 'Export reports'),
('COMPLAINTS', 'VIEW', 'View complaints'),
('COMPLAINTS', 'CREATE', 'Create complaints'),
('COMPLAINTS', 'EDIT', 'Edit complaints'),
('COMPLAINTS', 'DELETE', 'Delete complaints');

-- Assign all permissions to Super Admin
INSERT INTO role_permissions (role_id, permission_id, granted)
SELECT 1, id, TRUE FROM permissions;

-- Create default admin user (password: admin123)
INSERT INTO users (username, password_hash, full_name, role_id, is_active, created_by)
VALUES ('admin', '$2a$10$rZ8PqYqEWGHvQQzBfPqIJeQ2qVWZkXQhFoYvHGYjxYKZQqr3N7hOe', 'System Administrator', 1, TRUE, 1);

-- Insert some default units
INSERT INTO units (name, short_name, unit_type, base_unit_id, conversion_factor) VALUES
('Kilogram', 'KG', 'WEIGHT', NULL, 1.0),
('Gram', 'G', 'WEIGHT', 1, 0.001),
('Quintal', 'Q', 'WEIGHT', 1, 100.0),
('Metric Ton', 'MT', 'WEIGHT', 1, 1000.0),
('Liter', 'L', 'VOLUME', NULL, 1.0),
('Milliliter', 'ML', 'VOLUME', 5, 0.001),
('Piece', 'PC', 'COUNT', NULL, 1.0),
('Box', 'BOX', 'COUNT', NULL, 1.0),
('Bag', 'BAG', 'COUNT', NULL, 1.0),
('Tray', 'TRAY', 'COUNT', NULL, 1.0);

-- Insert Indian states
INSERT INTO states (name, code, gst_state_code) VALUES
('Andhra Pradesh', 'AP', '37'),
('Telangana', 'TS', '36'),
('Karnataka', 'KA', '29'),
('Tamil Nadu', 'TN', '33'),
('Kerala', 'KL', '32'),
('Maharashtra', 'MH', '27'),
('Gujarat', 'GJ', '24');

-- Insert default GST rates
INSERT INTO gst_rates (name, cgst_pct, sgst_pct, igst_pct, effective_from) VALUES
('GST 0%', 0.00, 0.00, 0.00, '2017-07-01'),
('GST 5%', 2.50, 2.50, 5.00, '2017-07-01'),
('GST 12%', 6.00, 6.00, 12.00, '2017-07-01'),
('GST 18%', 9.00, 9.00, 18.00, '2017-07-01'),
('GST 28%', 14.00, 14.00, 28.00, '2017-07-01');

-- Insert party types
INSERT INTO party_types (name) VALUES
('SUPPLIER'),
('CUSTOMER'),
('TRANSPORTER'),
('BOTH_SUP_CUS');

-- Insert default item categories
INSERT INTO item_categories (name, category_type) VALUES
('Feed Raw Materials', 'FEED_RM'),
('Finished Feed', 'FEED_FINISHED'),
('Eggs', 'EGG'),
('Medicines & Vaccines', 'MEDICINE'),
('Assets', 'ASSET'),
('Consumables', 'CONSUMABLE');

-- Insert sample health event types
INSERT INTO health_event_types (name, kind) VALUES
('Marek Disease Vaccination', 'VACCINATION'),
('Newcastle Disease (ND)', 'VACCINATION'),
('Infectious Bronchitis (IB)', 'VACCINATION'),
('Ranikhet Disease', 'VACCINATION'),
('Deworming', 'TREATMENT'),
('Coccidiosis Treatment', 'TREATMENT'),
('General Illness', 'DISEASE');

-- Insert expense categories
INSERT INTO expense_categories (name) VALUES
('Fuel'),
('Electricity'),
('Maintenance'),
('Labor'),
('Transport'),
('Miscellaneous');

-- Insert complaint categories
INSERT INTO complaint_categories (name) VALUES
('Equipment Failure'),
('Bird Health Issue'),
('Feed Quality'),
('Power Outage'),
('Water Supply'),
('Other');

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- END OF SCHEMA
-- ============================================================
