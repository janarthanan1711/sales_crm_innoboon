# Sales CRM App – Development Sync Meeting Minutes
**Date:** July 15, 2026  
**Status:** In Progress

---

## 1. Meeting Objective
To align the development team on lead, account, and deal workflow requirements, access control, bulk upload approach, and demo timeline for the upcoming week.

---

## 2. Lead Management Requirements

### Definition & Purpose
- A **Lead** is unqualified prospect data collected from web sources or contact form submissions
- Leads represent initial business interest without verification

### Mandatory Lead Fields
- Contact Name
- Company Name
- LinkedIn URL
- Email
- Phone Number

### Lead Status Field
**Tracks contact attempts with values:**
- `New` – newly created lead, not yet contacted
- `Contacted` – initial contact made
- `Junk` – invalid or spam lead
- `Closed` – no longer pursuing
- `Contact in Future` – follow up scheduled

### Lead Tier Classification
- **Tier field must remain EMPTY on leads**
- Tier is only assigned after conversion to Account
- No tier tracking at lead stage

### Lead Owner Assignment
- **Defaults to EMPTY** if not explicitly assigned during creation
- Can be reassigned to a different team member after creation
- Lead Owner automatically becomes Account Owner upon conversion (unless manually changed)

### Form Design Constraints
- **NO Amount field** on lead creation form
- Amount belongs exclusively to Accounts and Deals
- All fields except Name, Company, and Email should be optional
- No mandatory fields – users can save with minimal information

---

## 3. Lead-to-Account Conversion Process

### Conversion Trigger
- A Lead converts to an Account **only when** a qualified business requirement or genuine conversation is established
- Conversion is an explicit user action, not automatic

### Conversion Workflow
1. User initiates conversion from Lead detail page
2. Conversion form appears requesting Account details:
   - Company Name (pre-filled from lead)
   - Domain/Website
   - Industry
   - Primary Owner (defaults to Lead Owner)
   - Tier classification (NEW dropdown with "Not Applicable" option)
   - Description/Notes (optional)

### Post-Conversion Actions
- **Creates:** New Account record with provided details
- **Creates:** New Contact record (from lead contact details)
- **Removes:** Lead is deleted from the system
- **Assigns:** Lead Owner becomes Account Owner (configurable during conversion)
- **Navigation:** Redirects to new Account detail page upon successful conversion

### Account Tier Options (including new requirement)
- Bronze
- Silver
- Gold
- Diamond
- Strategic
- **Not Applicable** (NEW – for unclassified accounts)

---

## 4. Account and Deal Management

### Account Definition & Ownership
- An **Account** represents a verified company with an established business relationship
- One or more contacts associated with an account
- **Only the Account Owner can modify** account details and associated information

### Account Information
- Company Name
- Domain/Website
- Industry
- Tier Classification
- Primary Owner
- Description
- Active Deals Count
- Associated Contacts

### Deal Management
- An Account can have **multiple Deals** for different opportunities
- Each deal represents a distinct sales opportunity

### Deal Creation Requirements
- Deal Name (required)
- Owner (required)
- Associated Contact (required)
- Expected Closing Date (required)
- Deal Value (optional)
- Description/Notes (optional)

### Deal Status Values
- `Open` – actively being pursued
- `Closed` – no longer pursuing
- `Won` – closed successfully
- `Lost` – deal was lost to competitor

---

## 5. Access Control and Permissions

### Role-Based Permissions

#### Delivery Executives
- ✅ View leads
- ✅ View deals
- ✅ View accounts (read-only)
- ❌ Cannot create accounts
- ❌ Cannot perform lead-to-account conversion
- ❌ Cannot create deals
- ❌ Cannot modify any records

#### Sales Representatives
- ✅ Create leads
- ✅ Create accounts
- ✅ Perform lead-to-account conversion
- ✅ Create deals
- ✅ Modify own records
- ✅ View all records in system

#### Sales Managers
- ✅ All Sales Representative permissions
- ✅ View team member records
- ✅ Reassign leads and deals
- ✅ Generate reports

#### Admins
- ✅ Full system access
- ✅ User management
- ✅ Bulk upload management
- ✅ Configuration and settings

### Lead Owner Reassignment
- Lead Owner can be reassigned to a different team member after creation
- Reassignment updates access control immediately
- Audit trail records ownership changes

### Future Enhancement
- **Next iteration:** Role-based access control will auto-assign new leads to the logged-in user
- Requires authentication system integration

---

## 6. Data Collection and Bulk Upload

### Lead Generation Targets
- **Monthly target:** ~400 leads from various sources
- Quarterly target: ~1,200 leads

### Lead Source Tracking
**Lead Source field tracks origin:**
- `Advertisement` – paid advertising campaigns
- `Cold Call` – direct outreach
- `Referral` – customer referrals
- `Contact Form` – website form submissions
- `LinkedIn` – LinkedIn connections/outreach
- `Conference` – trade shows and events
- `Partner` – partner referrals
- `Other` – miscellaneous sources

### Bulk Upload Process
- Bulk upload requires **consistent field headers** matching the manual lead creation form
- Supported file formats: CSV, XLSX
- Field validation before import
- Duplicate email checking to prevent duplicates
- Import status tracking and error reporting
- Bulk upload audit trail

### Contact Form Integration
- Contact form submissions **automatically populate lead fields** in the CRM system
- Auto-assign form submissions to default lead owner (configurable)
- Auto-set Lead Status to "New" for form submissions
- Auto-set Lead Source to "Contact Form"

---

## 7. UI and Form Design

### Lead Creation Form
**Fields:**
- Contact Name (optional)
- Company Name (optional)
- Email (optional)
- Phone (optional)
- LinkedIn URL (optional)
- Lead Source (dropdown)
- Lead Status (defaults to "New")
- Lead Owner (dropdown of team members, defaults to empty)
- Notes (optional textarea)

**Constraints:**
- ❌ NO Amount field
- ❌ NO Tier field
- ✅ All fields optional
- ✅ Can save with minimal information

### Lead Owner Dropdown
- Displays all active team members
- Searchable
- Option to leave blank
- Shows current assignment

### Lead Detail Page
- Display all lead information
- Action buttons:
  - Edit Lead
  - Convert to Account
  - Reassign Owner
  - Log Activity
  - Add Notes

### Convert to Account Form
- Pre-fills Company Name from lead
- Requests: Domain, Industry, Tier (with "Not Applicable" option)
- Confirms Account Owner (defaults to Lead Owner, editable)
- Optional: Description/Notes
- Submit button converts and redirects

### Account Edit Form
- Allow updating all account fields including:
  - Company Name
  - Domain/Website
  - Industry
  - Tier Classification (can be changed to/from "Not Applicable")
  - Primary Owner
  - Description
- Save and Cancel buttons

### Account Detail Page
- Display Account Information
- Contacts section (add, edit, remove)
- Associated Deals section
- Activity timeline
- Action buttons: Edit Account, Add Contact, Create Deal

---

## 8. Current Implementation Status

### ✅ Completed
- Basic lead CRUD operations
- Basic account CRUD operations
- Basic deal CRUD operations
- Activity logging
- Checklist management
- Notification system
- Analytics dashboard
- Lead-to-Account conversion (MVP)

### 🔄 In Progress / Requires Updates
- [ ] Lead Status field - update values (add "Contact in Future", remove others as needed)
- [ ] Remove Tier field from Lead entity
- [ ] Add "Not Applicable" option to Tier enum
- [ ] Update Lead creation form - remove Amount field
- [ ] Enhance Lead-to-Account conversion form - add Account tier selection
- [ ] Implement role-based access control (phase 1)
- [ ] Bulk lead upload feature
- [ ] Contact form auto-integration
- [ ] Lead Owner reassignment feature

### ⏳ Planned / Future Iterations
- [ ] Auto-assign leads to logged-in user based on role
- [ ] Advanced role-based access control (Delivery Executives)
- [ ] Lead scoring and qualification automation
- [ ] Deal pipeline analytics
- [ ] Custom field support
- [ ] Lead and deal templates

---

## 9. Development Priorities

### Phase 1 (This Week)
1. Update Lead Status enum (New, Contacted, Junk, Closed, Contact in Future)
2. Remove Tier from Lead entity
3. Update Lead creation form UI
4. Enhance conversion form with Account tier selection
5. Add "Not Applicable" to Tier options
6. Fix conversion bug (ensure account is created before redirecting)

### Phase 2 (Next Week)
1. Implement role-based access control
2. Add Lead Owner reassignment feature
3. Implement basic access control for Delivery Executives
4. Update API endpoints with permission checks

### Phase 3 (Following Week)
1. Bulk upload feature (CSV/XLSX)
2. Contact form auto-integration
3. Duplicate email checking for bulk upload

---

## 10. API & Backend Requirements

### Lead Status Values (Updated)
```json
{
  "leadStatus": ["New", "Contacted", "Junk", "Closed", "Contact in Future"]
}
```

### Tier Options (Updated)
```json
{
  "tiers": ["Bronze", "Silver", "Gold", "Diamond", "Strategic", "Not Applicable"]
}
```

### Lead Source Values
```json
{
  "leadSources": ["Advertisement", "Cold Call", "Referral", "Contact Form", "LinkedIn", "Conference", "Partner", "Other"]
}
```

### New API Endpoints Needed
- `POST /api/leads/{leadId}/reassign-owner` – reassign lead owner
- `POST /api/leads/bulk-upload` – bulk upload leads
- `GET /api/leads/check-duplicate?email={email}` – check duplicate emails
- `PATCH /api/accounts/{accountId}/tier` – update account tier

---

## 11. Demo Timeline
- **Demo Date:** End of this week (Friday, July 19, 2026)
- **Demo Focus:** Lead creation, Lead-to-Account conversion, Account detail view
- **Test Data:** Use mock data for demonstration

---

## 12. Notes & Action Items

### Action Items
- [ ] Backend team: Update Lead Status and Tier enums
- [ ] Backend team: Add "Not Applicable" to Tier
- [ ] Frontend team: Update Lead entity model
- [ ] Frontend team: Update Lead creation form
- [ ] Frontend team: Enhance conversion form
- [ ] QA team: Test lead conversion workflow
- [ ] QA team: Verify account creation after conversion

### Blockers
- None identified

### Risks
- Lead generation target (400/month) may require dedicated data team
- Bulk upload implementation complexity – may require backend support

### Questions for Next Meeting
- Authentication system integration timeline?
- Contact form endpoint ready for integration?
- Bulk upload file size limits?

---

**Meeting Conducted By:** Development Team Lead  
**Next Sync:** July 18, 2026 (3 PM)  
**Document Version:** 1.0  
**Last Updated:** July 15, 2026
