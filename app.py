from pathlib import Path
import pandas as pd
import streamlit as st
import plotly.express as px

ROOT = Path(__file__).resolve().parent
DATA = ROOT / "data" / "raw"

@st.cache_data
def read(name):
    return pd.read_csv(DATA / f"{name}.csv")

customers, accounts = read("customers"), read("accounts")
transactions, loans = read("transactions"), read("loans")
payments, cards = read("loan_payments"), read("cards")
transactions["transaction_date"] = pd.to_datetime(transactions["transaction_date"])
payments["payment_date"] = pd.to_datetime(payments["payment_date"])
cards["expiry_date"] = pd.to_datetime(cards["expiry_date"])
as_of_date = transactions["transaction_date"].max().date()

st.set_page_config(page_title="Retail Banking Analytics", page_icon="🏦", layout="wide")
st.title("Retail Banking Transaction Analysis")
st.caption(f"Portfolio dashboard")

st.sidebar.header("Filters")
status_options = sorted(transactions["status"].dropna().unique().tolist())
selected_status = st.sidebar.multiselect("Transaction status", status_options, default=status_options)
type_options = sorted(transactions["transaction_type"].dropna().unique().tolist())
selected_types = st.sidebar.multiselect("Transaction type", type_options, default=type_options)
filtered = transactions[transactions["status"].isin(selected_status) & transactions["transaction_type"].isin(selected_types)]

completed = transactions[transactions.status == "Completed"]
late_missed = payments.status.isin(["Late", "Missed"]).sum()
risk_loans = loans.loan_status.isin(["Defaulted", "In Arrears"]).sum()
cols = st.columns(5)
cols[0].metric("Customers", f"{len(customers):,}")
cols[1].metric("Accounts", f"{len(accounts):,}")
cols[2].metric("Completed transaction value", f"${completed.amount.sum():,.0f}")
cols[3].metric("Loans in arrears/default", f"{risk_loans:,} / {len(loans):,}")
cols[4].metric("Late/missed payment rows", f"{late_missed:,} / {len(payments):,}")

left, right = st.columns(2)
with left:
    status_df = filtered.status.value_counts().rename_axis("status").reset_index(name="transactions")
    st.plotly_chart(px.bar(status_df, x="status", y="transactions", title="Transaction status distribution"), use_container_width=True)
with right:
    segment_df = customers.segment.value_counts().rename_axis("segment").reset_index(name="customers")
    st.plotly_chart(px.bar(segment_df, x="segment", y="customers", title="Customers by segment"), use_container_width=True)

left, right = st.columns(2)
with left:
    monthly = (completed.set_index("transaction_date").resample("MS").agg(transaction_count=("transaction_id","count"), amount=("amount","sum")).reset_index())
    st.plotly_chart(px.line(monthly, x="transaction_date", y="transaction_count", title="Monthly completed transaction volume"), use_container_width=True)
with right:
    loan_df = loans.groupby("loan_status", as_index=False).agg(loan_count=("loan_id","count"), outstanding_balance=("outstanding_balance","sum"))
    st.plotly_chart(px.bar(loan_df, x="loan_status", y="outstanding_balance", title="Outstanding loan balance by status"), use_container_width=True)

left, right = st.columns(2)
with left:
    card_df = cards.is_active.value_counts().rename_axis("is_active").reset_index(name="cards")
    st.plotly_chart(px.pie(card_df, names="is_active", values="cards", title="Card activation mix"), use_container_width=True)
with right:
    pay_df = payments.status.value_counts().rename_axis("status").reset_index(name="payment_rows")
    st.plotly_chart(px.bar(pay_df, x="status", y="payment_rows", title="Loan payment status"), use_container_width=True)

st.subheader("Filtered transactions")
st.caption("Transaction amount includes all statuses in this table; the completed-value KPI excludes pending and failed transactions.")
st.dataframe(filtered.sort_values("transaction_date", ascending=False), use_container_width=True, hide_index=True)
st.download_button("Download filtered transactions CSV", filtered.to_csv(index=False).encode("utf-8"), "filtered_transactions.csv", "text/csv")

st.markdown("### Interpretation notes")
st.markdown("""
- Treat the dataset as a training portfolio dataset; validate definitions before making real-world decisions.
- Transaction amounts are not net cash flow because transaction type signs are not supplied consistently. Avoid summing all statuses as successful volume.
- The project brief says to use the latest `transaction_date` as the reference date for time-based analysis.
- A high late/missed payment count is a portfolio risk signal, not proof of individual borrower default.
""")
