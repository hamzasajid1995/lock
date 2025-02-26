{{ config(materialized='table', post_hook=['ANALYZE TABLE {{ this }}'], sort=['CUSTOMER_ID'], update_frequency='daily') }}

WITH
  crm_customers AS (
    SELECT *
    FROM {{ source('DBML DataSource', 'CRM_CUSTOMERS') }}
  ),
  bil_invoices AS (
    SELECT *
    FROM {{ source('DBML DataSource', 'BIL_INVOICES') }}
  ),
  bil_invoice_items AS (
    SELECT *
    FROM {{ source('DBML DataSource', 'BIL_INVOICE_ITEMS') }}
  ),
  bil_payments AS (
    SELECT *
    FROM {{ source('DBML DataSource', 'BIL_PAYMENTS') }}
  ),
  crm_accounts AS (
    SELECT *
    FROM {{ source('DBML DataSource', 'CRM_ACCOUNTS') }}
  ),
  crm_contacts AS (
    SELECT *
    FROM {{ source('DBML DataSource', 'CRM_CONTACTS') }}
  ),
  crm_opportunities AS (
    SELECT *
    FROM {{ source('DBML DataSource', 'CRM_OPPORTUNITIES') }}
  ),
  mkt_campaign_targets AS (
    SELECT *
    FROM {{ source('DBML DataSource', 'MKT_CAMPAIGN_TARGETS') }}
  ),
  mkt_campaigns AS (
    SELECT *
    FROM {{ source('DBML DataSource', 'MKT_CAMPAIGNS') }}
  ),
  prv_service_assignments AS (
    SELECT *
    FROM {{ source('DBML DataSource', 'PRV_SERVICE_ASSIGNMENTS') }}
  ),
  prv_services AS (
    SELECT *
    FROM {{ source('DBML DataSource', 'PRV_SERVICES') }}
  ),
  nwk_equipment AS (
    SELECT *
    FROM {{ source('DBML DataSource', 'NWK_EQUIPMENT') }}
  ),
  nwk_usage AS (
    SELECT *
    FROM {{ source('DBML DataSource', 'NWK_USAGE') }}
  ),
  nwk_outages AS (
    SELECT *
    FROM {{ source('DBML DataSource', 'NWK_OUTAGES') }}
  ),
  sup_tickets AS (
    SELECT *
    FROM {{ source('DBML DataSource', 'SUP_TICKETS') }}
  ),
  sup_ticket_notes AS (
    SELECT *
    FROM {{ source('DBML DataSource', 'SUP_TICKET_NOTES') }}
  )

SELECT
  crm_customers.CUSTOMER_ID,
  crm_customers.FIRST_NAME,
  crm_customers.MIDDLE_NAME,
  crm_customers.LAST_NAME,
  crm_customers.EMAIL,
  crm_customers.PHONE,
  crm_customers.ADDRESS_LINE1,
  crm_customers.ADDRESS_LINE2,
  crm_customers.CITY,
  crm_customers.STATE,
  crm_customers.ZIP_CODE,
  crm_customers.COUNTRY,
  crm_customers.CUSTOMER_SEGMENT,
  crm_customers.CUSTOMER_TIER,
  crm_customers.START_DATE,
  crm_customers.STATUS,
  COUNT(DISTINCT bil_invoices.INVOICE_ID) AS Total_Invoices,
  SUM(bil_invoices.TOTAL_AMOUNT) AS Total_Invoice_Amount,
  SUM(bil_invoices.TAX_AMOUNT) AS Total_Tax_Amount,
  SUM(bil_invoices.DISCOUNT_AMOUNT) AS Total_Discount_Amount,
  SUM(bil_payments.AMOUNT) AS Total_Payments,
  COUNT(DISTINCT crm_accounts.ACCOUNT_ID) AS Total_Accounts,
  MAX(crm_accounts.ACCOUNT_BALANCE) AS Account_Balance,
  COUNT(DISTINCT crm_opportunities.OPPORTUNITY_ID) AS Total_Opportunities,
  SUM(crm_opportunities.AMOUNT) AS Opportunity_Amount,
  COUNT(DISTINCT crm_contacts.CONTACT_ID) AS Total_Contacts,
  COUNT(DISTINCT mkt_campaigns.CAMPAIGN_ID) AS Total_Campaigns,
  COUNT(DISTINCT mkt_campaign_targets.TARGET_ID) AS Total_Campaign_Targets,
  COUNT(DISTINCT prv_services.SERVICE_ID) AS Total_Services,
  COUNT(DISTINCT nwk_equipment.EQUIPMENT_ID) AS Total_Equipment,
  SUM(nwk_usage.DATA_CONSUMED) AS Total_Usage_Data,
  COUNT(DISTINCT sup_tickets.TICKET_ID) AS Total_Tickets,
  COUNT(DISTINCT sup_ticket_notes.NOTE_ID) AS Total_Ticket_Notes,
  SUM(bil_invoices.TOTAL_AMOUNT) AS total_sales,
  SUM(bil_payments.AMOUNT) AS total_payments,
  AVG(bil_invoices.TOTAL_AMOUNT) AS average_invoice_value,
  CASE WHEN COUNT(DISTINCT sup_tickets.TICKET_ID) = 0 THEN 0
       ELSE COUNT(DISTINCT CASE WHEN sup_tickets.STATUS = 'resolved' THEN sup_tickets.TICKET_ID END) / COUNT(DISTINCT sup_tickets.TICKET_ID)
  END AS ticket_resolution_rate
FROM crm_customers
LEFT JOIN bil_invoices ON crm_customers.CUSTOMER_ID = bil_invoices.CUSTOMER_ID
LEFT JOIN bil_invoice_items ON bil_invoices.INVOICE_ID = bil_invoice_items.INVOICE_ID
LEFT JOIN bil_payments ON bil_invoices.INVOICE_ID = bil_payments.INVOICE_ID
LEFT JOIN crm_accounts ON crm_customers.CUSTOMER_ID = crm_accounts.CUSTOMER_ID
LEFT JOIN crm_contacts ON crm_customers.CUSTOMER_ID = crm_contacts.CUSTOMER_ID
LEFT JOIN crm_opportunities ON crm_accounts.ACCOUNT_ID = crm_opportunities.ACCOUNT_ID
LEFT JOIN mkt_campaign_targets ON crm_customers.CUSTOMER_ID = mkt_campaign_targets.CUSTOMER_ID
LEFT JOIN mkt_campaigns ON mkt_campaign_targets.CAMPAIGN_ID = mkt_campaigns.CAMPAIGN_ID
LEFT JOIN prv_service_assignments ON crm_customers.CUSTOMER_ID = prv_service_assignments.CUSTOMER_ID
LEFT JOIN prv_services ON prv_service_assignments.SERVICE_ID = prv_services.SERVICE_ID
LEFT JOIN nwk_equipment ON prv_service_assignments.ASSIGNMENT_ID = nwk_equipment.ASSIGNMENT_ID
LEFT JOIN nwk_usage ON prv_service_assignments.ASSIGNMENT_ID = nwk_usage.ASSIGNMENT_ID
LEFT JOIN nwk_outages ON prv_service_assignments.ASSIGNMENT_ID = nwk_outages.ASSIGNMENT_ID
LEFT JOIN sup_tickets ON crm_customers.CUSTOMER_ID = sup_tickets.CUSTOMER_ID
LEFT JOIN sup_ticket_notes ON sup_tickets.TICKET_ID = sup_ticket_notes.TICKET_ID
GROUP BY
  crm_customers.CUSTOMER_ID,
  crm_customers.FIRST_NAME,
  crm_customers.MIDDLE_NAME,
  crm_customers.LAST_NAME,
  crm_customers.EMAIL,
  crm_customers.PHONE,
  crm_customers.ADDRESS_LINE1,
  crm_customers.ADDRESS_LINE2,
  crm_customers.CITY,
  crm_customers.STATE,
  crm_customers.ZIP_CODE,
  crm_customers.COUNTRY,
  crm_customers.CUSTOMER_SEGMENT,
  crm_customers.CUSTOMER_TIER,
  crm_customers.START_DATE,
  crm_customers.STATUS;
