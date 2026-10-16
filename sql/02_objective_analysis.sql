-- Sprint 4: Objective-based analysis | MySQL 8.0+
USE retail_banking;

-- A. Customer profile and segmentation
-- A1. Customer count and share by segment
SELECT segment, COUNT(*) AS customers,
       ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM customers), 2) AS pct_customers
FROM customers GROUP BY segment ORDER BY customers DESC;
-- A2. Demographic distribution
SELECT gender, COUNT(*) AS customers FROM customers GROUP BY gender ORDER BY customers DESC;
-- A3. Income and credit-score profile by segment
SELECT segment, COUNT(*) AS customers,
       ROUND(AVG(annual_income),2) AS avg_annual_income,
       ROUND(AVG(credit_score),1) AS avg_credit_score
FROM customers GROUP BY segment ORDER BY avg_annual_income DESC;
-- A4. KYC status and active status
SELECT kyc_status, is_active, COUNT(*) AS customers
FROM customers GROUP BY kyc_status, is_active ORDER BY kyc_status, is_active;
-- A5. Customer tenure using latest transaction date as project 'today'
WITH project_clock AS (SELECT MAX(transaction_date) AS as_of_date FROM transactions)
SELECT c.segment,
       ROUND(AVG(TIMESTAMPDIFF(MONTH,c.customer_since,p.as_of_date))/12,2) AS avg_tenure_years
FROM customers c CROSS JOIN project_clock p
GROUP BY c.segment ORDER BY avg_tenure_years DESC;
-- A6. Customers with multiple accounts
SELECT c.customer_id, CONCAT(c.first_name,' ',c.last_name) AS customer_name,
       COUNT(a.account_id) AS account_count
FROM customers c JOIN accounts a ON a.customer_id=c.customer_id
GROUP BY c.customer_id, customer_name HAVING COUNT(a.account_id)>1
ORDER BY account_count DESC;

-- B. Account usage and branch activity
-- B1. Account count, balances, and average balance by type/status
SELECT account_type, status, COUNT(*) AS accounts,
       ROUND(SUM(current_balance),2) AS total_balance,
       ROUND(AVG(current_balance),2) AS avg_balance
FROM accounts GROUP BY account_type,status ORDER BY account_type,status;
-- B2. Branch activity and customer/account balances
SELECT b.branch_id,b.branch_name,b.city,b.state,
       COUNT(a.account_id) AS account_count,
       ROUND(SUM(a.current_balance),2) AS total_account_balance,
       ROUND(AVG(a.current_balance),2) AS avg_account_balance
FROM branches b LEFT JOIN accounts a ON a.branch_id=b.branch_id
GROUP BY b.branch_id,b.branch_name,b.city,b.state
ORDER BY total_account_balance DESC;
-- B3. Account interest rate by type
SELECT account_type, ROUND(AVG(interest_rate),3) AS avg_interest_rate,
       MIN(interest_rate) AS min_rate, MAX(interest_rate) AS max_rate
FROM accounts GROUP BY account_type ORDER BY avg_interest_rate DESC;
-- B4. Account usage based on completed transactions only
SELECT a.account_type, COUNT(t.transaction_id) AS completed_transactions,
       ROUND(SUM(t.amount),2) AS completed_amount
FROM accounts a LEFT JOIN transactions t
  ON t.account_id=a.account_id AND t.status='Completed'
GROUP BY a.account_type ORDER BY completed_amount DESC;
-- B5. Branch-level loan exposure
SELECT b.branch_id,b.branch_name,b.region,COUNT(l.loan_id) AS loan_count,
       ROUND(SUM(l.principal_amount),2) AS principal_total,
       ROUND(SUM(l.outstanding_balance),2) AS outstanding_total
FROM branches b LEFT JOIN loans l ON l.branch_id=b.branch_id
GROUP BY b.branch_id,b.branch_name,b.region
ORDER BY outstanding_total DESC;

-- C. Transaction patterns
-- C1. Status distribution; don't treat all transaction rows as successful
SELECT status,COUNT(*) AS transaction_count,
       ROUND(100*COUNT(*)/(SELECT COUNT(*) FROM transactions),2) AS pct_transactions
FROM transactions GROUP BY status ORDER BY transaction_count DESC;
-- C2. Type and channel mix for completed transactions
SELECT transaction_type,channel,COUNT(*) AS txn_count,
       ROUND(SUM(amount),2) AS amount_total,
       ROUND(AVG(amount),2) AS avg_amount
FROM transactions WHERE status='Completed'
GROUP BY transaction_type,channel ORDER BY amount_total DESC;
-- C3. Monthly completed transaction trend
SELECT DATE_FORMAT(transaction_date,'%Y-%m') AS month,
       COUNT(*) AS completed_txn_count, ROUND(SUM(amount),2) AS completed_amount
FROM transactions WHERE status='Completed'
GROUP BY DATE_FORMAT(transaction_date,'%Y-%m') ORDER BY month;
-- C4. Description patterns
SELECT description,COUNT(*) AS txn_count,ROUND(SUM(amount),2) AS amount_total
FROM transactions WHERE status='Completed'
GROUP BY description ORDER BY txn_count DESC;
-- C5. Largest completed transactions (review as outlier candidates, not errors by default)
SELECT transaction_id,account_id,transaction_date,transaction_type,channel,amount
FROM transactions WHERE status='Completed'
ORDER BY amount DESC LIMIT 20;
-- C6. Completed transaction value by customer segment
SELECT c.segment,COUNT(t.transaction_id) AS txn_count,
       ROUND(SUM(t.amount),2) AS completed_amount
FROM transactions t JOIN accounts a ON a.account_id=t.account_id
JOIN customers c ON c.customer_id=a.customer_id
WHERE t.status='Completed'
GROUP BY c.segment ORDER BY completed_amount DESC;

-- D. Loan performance and repayment behaviour
-- D1. Portfolio by loan status
SELECT loan_status,COUNT(*) AS loan_count,
       ROUND(SUM(principal_amount),2) AS principal_total,
       ROUND(SUM(outstanding_balance),2) AS outstanding_total
FROM loans GROUP BY loan_status ORDER BY outstanding_total DESC;
-- D2. Loan type performance
SELECT loan_type,COUNT(*) AS loan_count,
       ROUND(AVG(interest_rate),2) AS avg_interest_rate,
       ROUND(SUM(outstanding_balance),2) AS outstanding_total
FROM loans GROUP BY loan_type ORDER BY outstanding_total DESC;
-- D3. Payment status and late-payment rate
SELECT status,COUNT(*) AS payment_count,
       ROUND(AVG(days_late),2) AS avg_days_late,
       ROUND(SUM(penalty),2) AS penalty_total,
       ROUND(SUM(paid_amount),2) AS amount_paid
FROM loan_payments GROUP BY status ORDER BY payment_count DESC;
-- D4. Loans with repeated late/missed payments
SELECT l.loan_id,l.customer_id,l.loan_type,l.loan_status,
       SUM(CASE WHEN p.status IN ('Late','Missed') THEN 1 ELSE 0 END) AS late_or_missed_count,
       ROUND(SUM(p.penalty),2) AS penalties
FROM loans l JOIN loan_payments p ON p.loan_id=l.loan_id
GROUP BY l.loan_id,l.customer_id,l.loan_type,l.loan_status
HAVING late_or_missed_count>=2
ORDER BY late_or_missed_count DESC,penalties DESC;
-- D5. Repayment behaviour by branch
SELECT b.branch_name,b.region,COUNT(DISTINCT l.loan_id) AS loans,
       SUM(CASE WHEN p.status IN ('Late','Missed') THEN 1 ELSE 0 END) AS late_or_missed_payments,
       COUNT(p.payment_id) AS scheduled_payment_rows,
       ROUND(100*SUM(CASE WHEN p.status IN ('Late','Missed') THEN 1 ELSE 0 END)
         / NULLIF(COUNT(p.payment_id),0),2) AS late_or_missed_pct,
       ROUND(SUM(p.penalty),2) AS penalty_total
FROM branches b JOIN loans l ON l.branch_id=b.branch_id
JOIN loan_payments p ON p.loan_id=l.loan_id
GROUP BY b.branch_id,b.branch_name,b.region
ORDER BY late_or_missed_pct DESC;
-- D6. Payment method mix
SELECT payment_method,COUNT(*) AS payment_count,
       ROUND(SUM(paid_amount),2) AS paid_total,
       ROUND(AVG(days_late),2) AS avg_days_late
FROM loan_payments GROUP BY payment_method ORDER BY payment_count DESC;

-- E. Card usage and product engagement
-- E1. Card type and active status
SELECT card_type,is_active,COUNT(*) AS cards,
       ROUND(AVG(credit_limit),2) AS avg_credit_limit,
       ROUND(SUM(outstanding_balance),2) AS outstanding_total,
       ROUND(AVG(reward_points),0) AS avg_reward_points
FROM cards GROUP BY card_type,is_active ORDER BY card_type,is_active;
-- E2. Cards expired as of latest transaction date (project clock)
WITH project_clock AS (SELECT MAX(transaction_date) AS as_of_date FROM transactions)
SELECT COUNT(*) AS expired_cards
FROM cards CROSS JOIN project_clock
WHERE expiry_date < project_clock.as_of_date;
-- E3. Customers with multiple product categories (accounts, cards, loans)
WITH product_counts AS (
 SELECT c.customer_id,
        COUNT(DISTINCT a.account_id) AS account_count,
        COUNT(DISTINCT cd.card_id) AS card_count,
        COUNT(DISTINCT l.loan_id) AS loan_count
 FROM customers c
 LEFT JOIN accounts a ON a.customer_id=c.customer_id
 LEFT JOIN cards cd ON cd.account_id=a.account_id
 LEFT JOIN loans l ON l.customer_id=c.customer_id
 GROUP BY c.customer_id
)
SELECT *,
       (CASE WHEN account_count>0 THEN 1 ELSE 0 END
       + CASE WHEN card_count>0 THEN 1 ELSE 0 END
       + CASE WHEN loan_count>0 THEN 1 ELSE 0 END) AS product_categories
FROM product_counts
WHERE (CASE WHEN account_count>0 THEN 1 ELSE 0 END
       + CASE WHEN card_count>0 THEN 1 ELSE 0 END
       + CASE WHEN loan_count>0 THEN 1 ELSE 0 END)>=2
ORDER BY product_categories DESC,account_count DESC;
-- E4. Card network mix
SELECT network,card_type,COUNT(*) AS card_count,
       ROUND(SUM(outstanding_balance),2) AS outstanding_total
FROM cards GROUP BY network,card_type ORDER BY card_count DESC;
-- E5. Card balances and utilization; utilization is meaningful primarily for credit cards
SELECT card_type,COUNT(*) AS cards,
       ROUND(AVG(CASE WHEN credit_limit>0 THEN outstanding_balance/credit_limit END)*100,2)
         AS avg_utilization_pct
FROM cards GROUP BY card_type;
