"""Exploratory analysis for Retail Banking Transaction Analysis.
Run from project root: python python/eda_analysis.py
"""
from pathlib import Path
import pandas as pd
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data" / "raw"
OUT = ROOT / "visuals"
OUT.mkdir(exist_ok=True)

def load(name):
    return pd.read_csv(DATA / f"{name}.csv")

customers, accounts, transactions = load("customers"), load("accounts"), load("transactions")
loans, payments, cards = load("loans"), load("loan_payments"), load("cards")
branches = load("branches")

# Parse dates for reliable time analysis.
for df, cols in [(transactions, ["transaction_date"]), (payments, ["payment_date"]),
                 (cards, ["issue_date", "expiry_date"]), (loans, ["disbursement_date", "maturity_date"]),
                 (accounts, ["open_date", "close_date"]), (customers, ["date_of_birth", "customer_since"])]:
    for col in cols:
        df[col] = pd.to_datetime(df[col], errors="coerce")

print("DATASET OVERVIEW")
for name, df in [("customers", customers), ("accounts", accounts), ("branches", branches),
                 ("loans", loans), ("loan_payments", payments), ("cards", cards),
                 ("transactions", transactions)]:
    print(f"{name:16s} rows={len(df):5d} columns={len(df.columns):2d} duplicates={df.duplicated().sum():3d} missing_cells={df.isna().sum().sum():3d}")

print("\\nKEY KPIs")
print(f"Customers: {len(customers):,}; active: {(customers.is_active == 'Yes').sum():,}")
print(f"Accounts: {len(accounts):,}; active accounts: {(accounts.status == 'Active').sum():,}")
print(f"Transactions: {len(transactions):,}; completed: {(transactions.status == 'Completed').sum():,} ({(transactions.status == 'Completed').mean():.1%})")
print(f"Completed transaction amount: ${transactions.loc[transactions.status == 'Completed', 'amount'].sum():,.2f}")
print(f"Loans: {len(loans):,}; defaulted/in arrears: {loans.loan_status.isin(['Defaulted','In Arrears']).sum():,}")
print(f"Loan outstanding balance: ${loans.outstanding_balance.sum():,.2f}")
print(f"Payments late or missed: {payments.status.isin(['Late','Missed']).sum():,} / {len(payments):,} ({payments.status.isin(['Late','Missed']).mean():.1%})")
print(f"Cards active: {(cards.is_active == 'Yes').sum():,} / {len(cards):,}")
print(f"Latest transaction date (project clock): {transactions.transaction_date.max().date()}")

# Referential integrity checks
checks = [
    ("accounts.customer_id -> customers", accounts.customer_id.isin(customers.customer_id).all()),
    ("accounts.branch_id -> branches", accounts.branch_id.isin(branches.branch_id).all()),
    ("transactions.account_id -> accounts", transactions.account_id.isin(accounts.account_id).all()),
    ("cards.account_id -> accounts", cards.account_id.isin(accounts.account_id).all()),
    ("loans.customer_id -> customers", loans.customer_id.isin(customers.customer_id).all()),
    ("loans.branch_id -> branches", loans.branch_id.isin(branches.branch_id).all()),
    ("loan_payments.loan_id -> loans", payments.loan_id.isin(loans.loan_id).all()),
]
print("\\nREFERENTIAL INTEGRITY")
for label, passed in checks:
    print(f"{'PASS' if passed else 'FAIL'} | {label}")

# Charts
charts = [
    (transactions.status.value_counts(), "Transaction Status Distribution", "Status", "Transactions", "transaction_status.png"),
    (customers.segment.value_counts(), "Customer Distribution by Segment", "Segment", "Customers", "customer_segments.png"),
    (loans.loan_status.value_counts(), "Loan Portfolio by Status", "Loan status", "Loans", "loan_status.png"),
    (cards.is_active.value_counts(), "Card Activation Status", "Active?", "Cards", "card_activation.png"),
]
for series, title, xlabel, ylabel, filename in charts:
    ax = series.plot(kind="bar", figsize=(8, 4.5), title=title)
    ax.set_xlabel(xlabel); ax.set_ylabel(ylabel)
    plt.xticks(rotation=25, ha="right")
    plt.tight_layout(); plt.savefig(OUT / filename, dpi=160); plt.close()

monthly = (transactions[transactions.status == "Completed"].set_index("transaction_date")
           .resample("MS").agg(transaction_count=("transaction_id", "count"), amount=("amount", "sum")).reset_index())
fig, ax = plt.subplots(figsize=(10, 4.5))
ax.plot(monthly.transaction_date, monthly.transaction_count)
ax.set(title="Monthly Completed Transaction Volume", xlabel="Month", ylabel="Completed transactions")
fig.tight_layout(); fig.savefig(OUT / "monthly_completed_transactions.png", dpi=160); plt.close(fig)

# Save a clean monthly output for optional BI import.
monthly.to_csv(OUT / "monthly_completed_transactions.csv", index=False)
print("\\nSaved charts and monthly aggregate to visuals/.")
