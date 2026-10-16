# Sprint 1.4 — ER Diagram Analysis (Before SQL)

This section answers the ten analytical-planning prompts from the supplied project brief. These are logical plans, not SQL queries.

1. **Customer profile and segment**
   - Tables/columns: `customers.customer_id`, `first_name`, `last_name`, `segment`, `gender`, `date_of_birth`, `city`, `state`, `annual_income`, `credit_score`, `kyc_status`, `is_active`, `customer_since`.
   - Relationship: `customers.customer_id` is the parent key for `accounts.customer_id` and `loans.customer_id`.
   - Logical flow: profile the customer table, compare counts and distributions by segment/demographics/location, then connect account and loan activity only if product engagement is needed.

2. **Customers with multiple accounts**
   - Tables/columns: `customers.customer_id`, customer names; `accounts.account_id`, `accounts.customer_id`, `accounts.status`, `accounts.account_type`.
   - Relationship: one customer may have many accounts, joined on `customer_id`.
   - Logical flow: count accounts per customer, filter counts greater than one, then compare active/closed account mix.

3. **Accounts by branch**
   - Tables/columns: `branches.branch_id`, `branch_name`, `city`, `state`, `region`; `accounts.branch_id`, `account_id`, `account_type`, `current_balance`, `status`.
   - Relationship: `branches.branch_id = accounts.branch_id`.
   - Logical flow: aggregate account counts and balances by branch, then compare regions and account types. Use a left join if branches with zero accounts must remain visible.

4. **How customers use accounts through transactions**
   - Tables/columns: `customers.customer_id`; `accounts.account_id`, `customer_id`; `transactions.account_id`, `transaction_date`, `transaction_type`, `amount`, `channel`, `status`.
   - Relationship: customer → accounts → transactions.
   - Logical flow: connect transactions to accounts and customers, separate completed from pending/failed rows, then aggregate by customer, segment, account type and period.

5. **Most common transaction types and channels**
   - Tables/columns: `transactions.transaction_type`, `channel`, `status`, `amount`, `transaction_date`.
   - Relationship: transaction facts can be analyzed alone; join `accounts` only to add account or customer context.
   - Logical flow: count rows by type/channel/status, compare completed amounts, and use a consistent date grain for trend analysis.

6. **Customers with loans and loan types**
   - Tables/columns: `customers.customer_id`, customer profile fields; `loans.loan_id`, `customer_id`, `loan_type`, `principal_amount`, `loan_status`, `purpose`, `outstanding_balance`.
   - Relationship: `customers.customer_id = loans.customer_id`.
   - Logical flow: identify loan-holding customers, summarize loan types/statuses and compare exposure by customer segment.

7. **Whether loan customers pay on time**
   - Tables/columns: `loans.loan_id`, `customer_id`, `loan_type`, `loan_status`; `loan_payments.loan_id`, `payment_date`, `scheduled_amount`, `paid_amount`, `days_late`, `penalty`, `status`, `payment_method`.
   - Relationship: one loan can have many payment records, joined by `loan_id`.
   - Logical flow: compare payment status with days late, amounts paid versus scheduled, penalties and repeat late/missed payment counts. Interpret status labels using the provided data definitions.

8. **Loan performance across branches**
   - Tables/columns: `branches.branch_id`, `branch_name`, `region`; `loans.branch_id`, `loan_id`, `principal_amount`, `outstanding_balance`, `loan_status`; optionally `loan_payments` for repayment outcomes.
   - Relationship: branch → loans → loan payments.
   - Logical flow: compare loan count and exposure by branch; then join payment records to compare late/missed payment rates. Aggregate at the intended grain to avoid double-counting loan balances after joining multiple payments.

9. **Customers, accounts and linked cards**
   - Tables/columns: `customers.customer_id`; `accounts.account_id`, `customer_id`; `cards.account_id`, `card_type`, `is_active`, `expiry_date`, `credit_limit`, `outstanding_balance`, `reward_points`, `network`.
   - Relationship: customer → accounts → cards.
   - Logical flow: identify cards per customer/account, compare card type and activation/expiry, and aggregate card balances carefully when customers have multiple accounts.

10. **How customers use multiple banking products**
    - Tables/columns: customer profile; accounts and account balances/status; cards and activation/balances/rewards; loans and loan status/exposure; transactions and payment history where required.
    - Relationship: customer → accounts → transactions/cards; customer → loans → loan_payments. Loans connect directly to customers and branches in the supplied data model.
    - Logical flow: create a customer-level product summary with distinct account, card and loan counts; compare single-product versus multi-product customers and avoid join fan-out by using pre-aggregations or distinct counts.

## Relationship summary
- `branches` 1-to-many `accounts`
- `customers` 1-to-many `accounts`
- `customers` 1-to-many `loans`
- `branches` 1-to-many `loans`
- `accounts` 1-to-many `transactions`
- `accounts` 1-to-many `cards`
- `loans` 1-to-many `loan_payments`

**Important:** The project brief requires the latest `transaction_date` to be used as “today” for time-based analysis. The supplied data's latest transaction date is **2025-02-22**.
