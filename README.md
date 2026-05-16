# mobile-operator-project-sql
Mobile operator database analysis using Oracle SQL
 ## Overview
This project focuses on analyzing telecommunication subscriber data using SQL. The main goal is to extract meaningful insights about customer demographics, call behavior, payment patterns, service usage, SMS activity, and complaint resolution performance.

## Project Objectives
- Analyze subscriber demographics by age and gender
- Examine payment behavior and transaction history
- Track call and SMS activity patterns
- Evaluate service and tariff plan performance
- Analyze complaint resolution efficiency
- Identify high-value and low-activity subscribers
- Generate business insights for customer retention and revenue optimization

## Dataset Structure
- subscribers – Stores subscriber personal information such as name, surname, gender, and birth date
- address – Contains subscriber address details
- address_type – Defines different types of addresses.
- technical_data – Stores technical information related to subscribers or system usage
- payments – Records all payment transactions made by subscribers
- payment_method_type – Defines different payment methods.
- services – Lists available telecom services
- tariff_information – Contains tariff plans and pricing details
- calls – Stores call records including duration, type, and participants
- call_type – Defines different types of calls
- sms_information – Contains SMS records sent by subscribers
- sms_types – Defines categories of SMS messages
- complaints_and_support_requests – Stores customer complaints and support tickets
- complain_type – Defines types of complaints submitted by subscribers

## Technologies Used
- SQL (Oracle)
- Window Functions
- CTE (Common Table Expressions)
- JOIN Operations
- Aggregate Functions
- Pivot Tables

## Key Insights
- Most subscribers are in the 31-50 age group and male users dominate
- Payment behavior is stable among subscribers
- Service B generates the highest subscriber activity and revenue
- Users with high call activity can be considered VIP customers
- Total duration of domestic calls is longer than international calls
- Higher service usage is associated with higher charges
- Complaint resolution is efficient, averaging 2 days
- SMS activity is generally low, while a few subscribers are highly active
- The 31–50 age group, especially in the Economy Plan, shows higher average payments, making this segment potentially more profitable for the company.
- Subscribers whose payments exceed the tariff average can be considered premium customers and targeted with loyalty-focused strategies.

The project helps identify high-value, passive, and complaint-prone customer segments for better business decisions
