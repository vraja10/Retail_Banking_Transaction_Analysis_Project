-- Sprint 3: Basic analysis | Run after CSV import
USE retail_banking;

-- 11. Total customers
SELECT COUNT(*) AS total_customers FROM customers;
-- 12. Total accounts
SELECT COUNT(*) AS total_accounts FROM accounts;
-- 13. Account types
SELECT DISTINCT account_type FROM accounts ORDER BY account_type;
-- 14. Active customers
SELECT COUNT(*) AS active_customers FROM customers WHERE is_active = 'Yes';
-- 15. Transaction types
SELECT DISTINCT transaction_type FROM transactions ORDER BY transaction_type;
-- 16. Total amount of completed transactions (exclude pending/failed)
SELECT ROUND(SUM(amount), 2) AS completed_transaction_amount
FROM transactions WHERE status = 'Completed';
-- 17. Loan types
SELECT DISTINCT loan_type FROM loans ORDER BY loan_type;
-- 18. Total loans
SELECT COUNT(*) AS total_loans FROM loans;
-- 19. Card types
SELECT DISTINCT card_type FROM cards ORDER BY card_type;
-- 20. Total outstanding loan balance
SELECT ROUND(SUM(outstanding_balance), 2) AS total_outstanding_loan_balance FROM loans;

-- Import verification: row counts expected from the supplied data
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL SELECT 'accounts', COUNT(*) FROM accounts
UNION ALL SELECT 'branches', COUNT(*) FROM branches
UNION ALL SELECT 'loans', COUNT(*) FROM loans
UNION ALL SELECT 'loan_payments', COUNT(*) FROM loan_payments
UNION ALL SELECT 'cards', COUNT(*) FROM cards
UNION ALL SELECT 'transactions', COUNT(*) FROM transactions;
