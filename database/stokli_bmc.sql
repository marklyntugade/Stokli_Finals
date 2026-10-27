CREATE DATABASE IF NOT EXISTS stokli_bmc
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE stokli_bmc;

SET NAMES utf8mb4;
CREATE TABLE IF NOT EXISTS api_schema_migrations (
  version SMALLINT UNSIGNED NOT NULL,
  applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (version)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS users (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  account_id VARCHAR(64) NOT NULL,
  full_name VARCHAR(120) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('student', 'admin') NOT NULL DEFAULT 'student',
  email VARCHAR(254) NULL,
  program_section VARCHAR(80) NULL,
  contact_number VARCHAR(32) NULL,
  account_status ENUM('active', 'suspended') NOT NULL DEFAULT 'active',
  profile_photo VARCHAR(80) NULL,
  profile_version INT UNSIGNED NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_account_id (account_id),
  UNIQUE KEY uq_users_email (email),
  KEY idx_users_role (role)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS equipment (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  equipment_code VARCHAR(32) NOT NULL,
  name VARCHAR(120) NOT NULL,
  brand VARCHAR(80) NOT NULL DEFAULT 'Stokli',
  model VARCHAR(120) NULL,
  category VARCHAR(60) NOT NULL,
  serial_number VARCHAR(120) NULL,
  program VARCHAR(100) NOT NULL DEFAULT 'IT Laboratory',
  location VARCHAR(120) NULL,
  description TEXT NULL,
  total_stock INT UNSIGNED NOT NULL DEFAULT 0,
  item_condition ENUM('Good', 'Fair', 'Damaged') NOT NULL DEFAULT 'Good',
  inventory_status VARCHAR(32) NOT NULL DEFAULT 'active',
  image_asset VARCHAR(120) NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_equipment_code (equipment_code),
  KEY idx_equipment_category (category),
  KEY idx_equipment_name (name),
  KEY idx_equipment_brand (brand),
  KEY idx_equipment_serial (serial_number),
  KEY idx_equipment_inventory_status (inventory_status),
  KEY idx_equipment_active (is_active)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS borrowing_requests (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  request_code VARCHAR(32) NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  equipment_id BIGINT UNSIGNED NOT NULL,
  status ENUM('pending', 'approved', 'rejected', 'cancelled') NOT NULL DEFAULT 'pending',
  request_note VARCHAR(500) NULL,
  reviewed_by BIGINT UNSIGNED NULL,
  requested_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  reviewed_at TIMESTAMP NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_request_code (request_code),
  KEY idx_requests_user_status (user_id, status),
  KEY idx_requests_status (status),
  CONSTRAINT fk_requests_user FOREIGN KEY (user_id) REFERENCES users (id),
  CONSTRAINT fk_requests_equipment FOREIGN KEY (equipment_id) REFERENCES equipment (id),
  CONSTRAINT fk_requests_reviewer FOREIGN KEY (reviewed_by) REFERENCES users (id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS borrowing_transactions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  transaction_code VARCHAR(32) NOT NULL,
  request_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  equipment_id BIGINT UNSIGNED NOT NULL,
  borrowed_at DATETIME NOT NULL,
  due_at DATETIME NOT NULL,
  returned_at DATETIME NULL,
  status ENUM('active', 'return_pending', 'returned', 'missing') NOT NULL DEFAULT 'active',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_transaction_code (transaction_code),
  UNIQUE KEY uq_transaction_request (request_id),
  KEY idx_transactions_user_status (user_id, status),
  KEY idx_transactions_equipment_status (equipment_id, status),
  KEY idx_transactions_due_status (due_at, status),
  CONSTRAINT fk_transactions_request FOREIGN KEY (request_id) REFERENCES borrowing_requests (id),
  CONSTRAINT fk_transactions_user FOREIGN KEY (user_id) REFERENCES users (id),
  CONSTRAINT fk_transactions_equipment FOREIGN KEY (equipment_id) REFERENCES equipment (id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS return_reports (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  transaction_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  reported_condition ENUM('Good', 'Damaged', 'Missing') NOT NULL,
  photo_data MEDIUMBLOB NULL,
  status ENUM('pending', 'accepted', 'rejected') NOT NULL DEFAULT 'pending',
  reviewed_by BIGINT UNSIGNED NULL,
  reported_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  reviewed_at TIMESTAMP NULL,
  PRIMARY KEY (id),
  KEY idx_return_transaction (transaction_id),
  KEY idx_return_status (status),
  CONSTRAINT fk_returns_transaction FOREIGN KEY (transaction_id) REFERENCES borrowing_transactions (id),
  CONSTRAINT fk_returns_user FOREIGN KEY (user_id) REFERENCES users (id),
  CONSTRAINT fk_returns_reviewer FOREIGN KEY (reviewed_by) REFERENCES users (id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS inventory_exceptions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  equipment_id BIGINT UNSIGNED NOT NULL,
  transaction_id BIGINT UNSIGNED NULL,
  reported_by BIGINT UNSIGNED NOT NULL,
  exception_type ENUM('missing', 'damaged') NOT NULL,
  quantity SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  notes VARCHAR(500) NULL,
  status ENUM('open', 'resolved') NOT NULL DEFAULT 'open',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  resolved_at TIMESTAMP NULL,
  PRIMARY KEY (id),
  KEY idx_exceptions_status (status),
  KEY idx_exceptions_equipment_status (equipment_id, status),
  CONSTRAINT fk_exceptions_equipment FOREIGN KEY (equipment_id) REFERENCES equipment (id),
  CONSTRAINT fk_exceptions_transaction FOREIGN KEY (transaction_id) REFERENCES borrowing_transactions (id),
  CONSTRAINT fk_exceptions_reporter FOREIGN KEY (reported_by) REFERENCES users (id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS penalties (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  transaction_id BIGINT UNSIGNED NULL,
  amount DECIMAL(10,2) NOT NULL,
  amount_paid DECIMAL(10,2) NOT NULL DEFAULT 0,
  reason VARCHAR(250) NOT NULL,
  status ENUM('unpaid', 'paid', 'waived') NOT NULL DEFAULT 'unpaid',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  settled_at DATETIME NULL,
  PRIMARY KEY (id),
  KEY idx_penalties_user_status (user_id, status),
  CONSTRAINT fk_penalties_user FOREIGN KEY (user_id) REFERENCES users (id),
  CONSTRAINT fk_penalties_transaction FOREIGN KEY (transaction_id) REFERENCES borrowing_transactions (id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS payments (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  payment_code VARCHAR(32) NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  method ENUM('GCash', 'Maya', 'Cash') NOT NULL,
  status ENUM('pending', 'verified', 'rejected') NOT NULL DEFAULT 'pending',
  reference_note VARCHAR(160) NULL,
  reviewed_by BIGINT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  reviewed_at DATETIME NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_payment_code (payment_code),
  KEY idx_payments_user_status (user_id, status),
  CONSTRAINT fk_payments_user FOREIGN KEY (user_id) REFERENCES users (id),
  CONSTRAINT fk_payments_reviewer FOREIGN KEY (reviewed_by) REFERENCES users (id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS auth_sessions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  token_hash CHAR(64) NOT NULL,
  expires_at DATETIME NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_session_token_hash (token_hash),
  KEY idx_sessions_expiry (expires_at),
  CONSTRAINT fk_sessions_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS system_logs (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  actor_id BIGINT UNSIGNED NULL,
  action VARCHAR(80) NOT NULL,
  entity_type VARCHAR(60) NULL,
  entity_id BIGINT UNSIGNED NULL,
  details VARCHAR(500) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_logs_created_at (created_at),
  KEY idx_logs_actor (actor_id),
  CONSTRAINT fk_logs_actor FOREIGN KEY (actor_id) REFERENCES users (id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS api_idempotency (
  user_id BIGINT UNSIGNED NOT NULL,
  operation_id CHAR(32) NOT NULL,
  action VARCHAR(80) NOT NULL,
  payload_hash CHAR(64) NOT NULL,
  response_status SMALLINT UNSIGNED NOT NULL,
  response_json MEDIUMTEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, operation_id),
  CONSTRAINT fk_idempotency_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB;

INSERT IGNORE INTO equipment (id, equipment_code, name, brand, category, program, total_stock, item_condition, image_asset) VALUES
(1, 'STK-001', 'Display Port', 'Stokli', 'Cables', 'IT Laboratory', 5, 'Good', 'display-port.jpg'),
(2, 'STK-002', 'RGB Keyboard', 'Stokli', 'Peripherals', 'IT Laboratory', 3, 'Good', 'rgb-keyboard.jpg'),
(3, 'STK-003', 'RGB Mouse', 'Stokli', 'Peripherals', 'IT Laboratory', 5, 'Good', 'rgb-mouse.jpg'),
(4, 'STK-004', 'RGB Speaker Bluetooth', 'Stokli', 'Audio', 'IT Laboratory', 2, 'Good', 'rgb-speaker-bluetooth.jpg'),
(5, 'STK-005', 'RGB Speaker Desktop', 'Stokli', 'Audio', 'IT Laboratory', 4, 'Good', 'rgb-speaker-desktop.jpg'),
(6, 'STK-006', 'Screw Driver Set', 'Stokli', 'Tools', 'IT Laboratory', 3, 'Good', 'screw-driver-set.jpg'),
(7, 'STK-007', 'Thermal Paste', 'Stokli', 'Tools', 'IT Laboratory', 5, 'Good', 'thermal-paste.jpg'),
(8, 'STK-008', 'VGA Port', 'Stokli', 'Cables', 'IT Laboratory', 4, 'Good', 'vga-port.jpg');
