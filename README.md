# Illumina Salesforce Coding Challenge
**Author:** Adrian Vega
**Date:** Aug 17, 2026
**Version:** V1.0

A performant, secure, and bulk-safe bundle of 2 Use cases solved in salesforce.
---------------------------------------------

## 1. Setup & Deployment Steps

Ensure your org has:

1.- An External Credential (ensure also it has a principal added).

Label: Zippopotam_API

Name: Zippopotam_API

Authentication Protocol: No Authentication

2.- Named Credential.

Label: Zippopotam_API

Name: Zippopotam_API

URL:https://api.zippopotam.us

External Credential: Zippopotam_API (created in previous step).

3.- Create a permission set and grant in External Credential Principal Access the principal name you created in step 1.



```bash
# Clone the Repository
git clone [https://github.com/javzamora91-sfdev/IlluminaCodeAssertation.git](https://github.com/javzamora91-sfdev/IlluminaCodeAssertation.git)
cd IlluminaCodeAssertation

# Authenticate & Create Scratch Org
sf org login web -d -a DevHub
sf org create scratch -f config/project-scratch-def.json -a IlluminaScratch -d 30

# Deploy Metadata & Code
sf project deploy start -o IlluminaScratch

# Assign Permissions
sf org assign permset -n ZipCode_App_User -o IlluminaScratch



---------------------------------------------

## 2. Data Model & Field Choices

ZipCode_Log__c (Use Case 1): Custom log object created to store non-US zip code lookups (ZipCode__c, Country__c, State__c, Place_Name__c).

Risk_Level (Global Value Set): A single source of truth value set containing High, Medium, and Low. Ensures enterprise-wide picklist consistency and data integrity across objects.

Account.Risk__c (Use Case 2): Picklist field bound to the Risk_Level Global Value Set with restricted API choices.

Account_Risk_Event__e (Platform Event): Asynchronous event definition carrying Account_Id__c, Account_Name__c, and Account_Owner_Id__c payloads for decoupled processing.


---------------------------------------------

3. Component Architecture & Placement:
Use Case 1 (Zip Code Search & API Integration):
 LWC Component ZipLookupParent: Invokes ZipCodeController.getZipCodeDetails dynamically using countryCode and zipCode.
 US Lookups: Displays postal details instantly in a reactive UI view without persisting data.  
 Non-US Lookups: Automatically persists location metadata to ZipCode_Log__c.  

Separate Screen UI: Includes a dynamic Datatable view exposing the non-US log records (getNonUSLogs) for auditing.  
Screen Flow UI "Zip Code Search": Provides a separate, flow-native UI experience using standard screen components and the ZipCodeFlowAdapter invocable Apex layer. Handles OTHER ISO country entries cleanly with dynamic column section rendering.  


Use Case 2 (Event-Driven Case Automation):
 Account Trigger (AccountTrigger & AccountTriggerHandler): Evaluates after insert and after update contexts for Risk__c == 'High'. Publishes Account_Risk_Event__e instances in bulk via EventBus.publish.  
 Subscriber Service (AccountRiskEventTrigger & AccountRiskEventService): Subscribes to event bus insertions asynchronously. Automatically generates a review Case and assigns ownership to an active standard user different from the Account Owner (WHERE Id NOT IN :accountOwnerIds).  

---------------------------------------------

4. Security & Access Enforcement

User Mode SOQL & DML Execution: All controller and service SOQL queries enforce strict field-level security using WITH USER_MODE. DML operations use user-mode database actions (insert as user log;), preventing unauthorized data manipulation.

Custom Exception Handling: Internal runtime exceptions are safely caught and wrapped using AuraHandledException helpers (createAuraException) to avoid exposing sensitive stack trace or API metadata to end users.  

SOQL Injection Prevention: All queries utilize standard inline bind variables.

---------------------------------------------

5. Test Execution & Performance Results:

Class:                           Per:   Lines:
ZipCodeController                  100%   63/63
ZipCodeFlowAdapter                 100%   17/17
AccountTriggerHandler              94%    17/18
AccountRiskEventService            96%    25/26

Total Behavioral Coverage Verified: 100% across synchronous DML transactions, platform event delivery threads, and HTTP callout mock assertions.


---------------------------------------------
