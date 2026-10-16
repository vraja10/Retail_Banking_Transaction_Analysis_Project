-- Retail Banking Transaction Analysis | MySQL 8.0+
-- Run this script first. Import CSVs after the tables are created.
CREATE DATABASE IF NOT EXISTS retail_banking;
USE retail_banking;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS loan_payments;
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS cards;
DROP TABLE IF EXISTS loans;
DROP TABLE IF EXISTS accounts;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS branches;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE branches (
    branch_id VARCHAR(10) PRIMARY KEY,
    branch_name VARCHAR(100) NOT NULL,
    city VARCHAR(80) NOT NULL,
    state VARCHAR(40) NOT NULL,
    region VARCHAR(40) NOT NULL,
    opening_date DATE,
    employee_count INT NOT NULL DEFAULT 0,
    CHECK (employee_count >= 0)
) ENGINE=InnoDB;

CREATE TABLE customers (
    customer_id VARCHAR(10) PRIMARY KEY,
    first_name VARCHAR(80) NOT NULL,
    last_name VARCHAR(80) NOT NULL,
    date_of_birth DATE,
    gender VARCHAR(20),
    city VARCHAR(80),
    state VARCHAR(40),
    customer_since DATE,
    kyc_status VARCHAR(20) NOT NULL,
    segment VARCHAR(30) NOT NULL,
    annual_income DECIMAL(14,2),
    credit_score INT,
    is_active VARCHAR(3) NOT NULL DEFAULT 'Yes',
    CHECK (annual_income IS NULL OR annual_income >= 0),
    CHECK (credit_score IS NULL OR credit_score BETWEEN 300 AND 900),
    CHECK (is_active IN ('Yes','No'))
) ENGINE=InnoDB;

CREATE TABLE accounts (
    account_id VARCHAR(12) PRIMARY KEY,
    customer_id VARCHAR(10) NOT NULL,
    branch_id VARCHAR(10) NOT NULL,
    account_type VARCHAR(40) NOT NULL,
    open_date DATE NOT NULL,
    close_date DATE NULL,
    current_balance DECIMAL(16,2) NOT NULL DEFAULT 0,
    interest_rate DECIMAL(6,3) NOT NULL DEFAULT 0,
    overdraft_limit DECIMAL(16,2) NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL,
    CONSTRAINT fk_accounts_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fk_accounts_branch FOREIGN KEY (branch_id) REFERENCES branches(branch_id),
    CHECK (current_balance >= 0),
    CHECK (interest_rate >= 0),
    CHECK (overdraft_limit >= 0),
    INDEX idx_accounts_customer (customer_id),
    INDEX idx_accounts_branch (branch_id),
    INDEX idx_accounts_status (status)
) ENGINE=InnoDB;

CREATE TABLE loans (
    loan_id VARCHAR(10) PRIMARY KEY,
    customer_id VARCHAR(10) NOT NULL,
    branch_id VARCHAR(10) NOT NULL,
    loan_type VARCHAR(40) NOT NULL,
    principal_amount DECIMAL(16,2) NOT NULL,
    interest_rate DECIMAL(6,3) NOT NULL,
    tenure_months INT NOT NULL,
    disbursement_date DATE NOT NULL,
    maturity_date DATE NOT NULL,
    emi_amount DECIMAL(14,2) NOT NULL,
    outstanding_balance DECIMAL(16,2) NOT NULL DEFAULT 0,
    loan_status VARCHAR(30) NOT NULL,
    purpose VARCHAR(80),
    CONSTRAINT fk_loans_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fk_loans_branch FOREIGN KEY (branch_id) REFERENCES branches(branch_id),
    CHECK (principal_amount >= 0),
    CHECK (interest_rate >= 0),
    CHECK (tenure_months > 0),
    CHECK (emi_amount >= 0),
    CHECK (outstanding_balance >= 0),
    INDEX idx_loans_customer (customer_id),
    INDEX idx_loans_branch (branch_id),
    INDEX idx_loans_status (loan_status)
) ENGINE=InnoDB;

CREATE TABLE cards (
    card_id VARCHAR(12) PRIMARY KEY,
    account_id VARCHAR(12) NOT NULL,
    card_type VARCHAR(20) NOT NULL,
    issue_date DATE NOT NULL,
    expiry_date DATE NOT NULL,
    credit_limit DECIMAL(16,2) NOT NULL DEFAULT 0,
    outstanding_balance DECIMAL(16,2) NOT NULL DEFAULT 0,
    reward_points INT NOT NULL DEFAULT 0,
    is_active VARCHAR(3) NOT NULL DEFAULT 'No',
    network VARCHAR(30),
    CONSTRAINT fk_cards_account FOREIGN KEY (account_id) REFERENCES accounts(account_id),
    CHECK (credit_limit >= 0),
    CHECK (outstanding_balance >= 0),
    CHECK (reward_points >= 0),
    CHECK (is_active IN ('Yes','No')),
    INDEX idx_cards_account (account_id),
    INDEX idx_cards_active (is_active)
) ENGINE=InnoDB;

CREATE TABLE transactions (
    transaction_id VARCHAR(15) PRIMARY KEY,
    account_id VARCHAR(12) NOT NULL,
    transaction_date DATE NOT NULL,
    transaction_time TIME,
    transaction_type VARCHAR(30) NOT NULL,
    amount DECIMAL(16,2) NOT NULL,
    channel VARCHAR(30) NOT NULL,
    description VARCHAR(100),
    balance_after DECIMAL(16,2),
    status VARCHAR(20) NOT NULL,
    CONSTRAINT fk_transactions_account FOREIGN KEY (account_id) REFERENCES accounts(account_id),
    CHECK (amount >= 0),
    INDEX idx_transactions_account (account_id),
    INDEX idx_transactions_date (transaction_date),
    INDEX idx_transactions_status (status),
    INDEX idx_transactions_type_channel (transaction_type, channel)
) ENGINE=InnoDB;

CREATE TABLE loan_payments (
    payment_id VARCHAR(15) PRIMARY KEY,
    loan_id VARCHAR(10) NOT NULL,
    payment_date DATE NOT NULL,
    scheduled_amount DECIMAL(14,2) NOT NULL,
    paid_amount DECIMAL(14,2) NOT NULL DEFAULT 0,
    principal_paid DECIMAL(14,2) NOT NULL DEFAULT 0,
    interest_paid DECIMAL(14,2) NOT NULL DEFAULT 0,
    penalty DECIMAL(14,2) NOT NULL DEFAULT 0,
    days_late INT NOT NULL DEFAULT 0,
    payment_method VARCHAR(30),
    status VARCHAR(20) NOT NULL,
    CONSTRAINT fk_payments_loan FOREIGN KEY (loan_id) REFERENCES loans(loan_id),
    CHECK (scheduled_amount >= 0),
    CHECK (paid_amount >= 0),
    CHECK (penalty >= 0),
    CHECK (days_late >= 0),
    INDEX idx_payments_loan (loan_id),
    INDEX idx_payments_date (payment_date),
    INDEX idx_payments_status (status)
) ENGINE=InnoDB;
