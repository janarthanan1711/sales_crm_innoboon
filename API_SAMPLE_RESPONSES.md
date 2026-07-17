# API Sample Responses Documentation

This document contains all API sample responses used by the SalesHub app. Use these as contracts with your backend API.

---

## 1. LEADS API

### Get All Leads
**Endpoint:** `GET /api/leads`

**Query Parameters:**
- `search` (optional): string - Search leads by company name, contact name, or email
- `status` (optional): 'New' | 'Contacted' | 'Qualified' | 'Unqualified'
- `tier` (optional): 'Bronze' | 'Silver' | 'Gold' | 'Diamond' | 'Strategic'
- `owner` (optional): string - Sales owner name
- `source` (optional): string - Lead source
- `page` (optional): number - Default: 1
- `pageSize` (optional): number - Default: 25

**Response:**
```json
{
  "data": [
    {
      "id": "lead_001",
      "companyName": "Nexbridge Tech",
      "contactName": "Karthick Selvam",
      "email": "karthick@nexbridge.io",
      "phone": "+91 98765 43210",
      "source": "LinkedIn",
      "status": "Contacted",
      "tier": null,
      "owner": "Sarah Jenkins",
      "website": "nexbridge.io",
      "industry": "IT Services",
      "notes": "Interested in cloud migration services",
      "createdAt": "2024-08-15T00:00:00Z",
      "lastContactedAt": "2024-09-10T00:00:00Z"
    },
    {
      "id": "lead_002",
      "companyName": "Cloudverge Solutions",
      "contactName": "Vishnu Priya",
      "email": "vishnu@cloudverge.com",
      "phone": "+91 87654 32109",
      "source": "Referral",
      "status": "New",
      "tier": null,
      "owner": "M. Chen",
      "website": "cloudverge.com",
      "industry": "SaaS",
      "notes": "Referred by Nexbridge Tech CEO",
      "createdAt": "2024-09-01T00:00:00Z",
      "lastContactedAt": null
    }
  ],
  "pagination": {
    "page": 1,
    "pageSize": 25,
    "total": 12
  }
}
```

### Get Lead By ID
**Endpoint:** `GET /api/leads/{leadId}`

**Response:**
```json
{
  "data": {
    "id": "lead_001",
    "companyName": "Nexbridge Tech",
    "contactName": "Karthick Selvam",
    "email": "karthick@nexbridge.io",
    "phone": "+91 98765 43210",
    "source": "LinkedIn",
    "status": "Contacted",
    "tier": null,
    "owner": "Sarah Jenkins",
    "website": "nexbridge.io",
    "industry": "IT Services",
    "notes": "Interested in cloud migration services",
    "createdAt": "2024-08-15T00:00:00Z",
    "lastContactedAt": "2024-09-10T00:00:00Z"
  }
}
```

### Create Lead
**Endpoint:** `POST /api/leads`

**Request Body:**
```json
{
  "companyName": "New Company Ltd",
  "contactName": "John Doe",
  "email": "john@newcompany.com",
  "phone": "+91 98765 00000",
  "source": "LinkedIn",
  "status": "New",
  "owner": "Sarah Jenkins",
  "website": "newcompany.com",
  "industry": "Technology",
  "notes": "Interested in partnership"
}
```

**Response:**
```json
{
  "data": {
    "id": "lead_new_uuid",
    "companyName": "New Company Ltd",
    "contactName": "John Doe",
    "email": "john@newcompany.com",
    "phone": "+91 98765 00000",
    "source": "LinkedIn",
    "status": "New",
    "tier": null,
    "owner": "Sarah Jenkins",
    "website": "newcompany.com",
    "industry": "Technology",
    "notes": "Interested in partnership",
    "createdAt": "2024-09-20T10:30:00Z",
    "lastContactedAt": null
  }
}
```

### Update Lead
**Endpoint:** `PUT /api/leads/{leadId}`

**Request Body:**
```json
{
  "id": "lead_001",
  "companyName": "Nexbridge Tech",
  "contactName": "Karthick Selvam",
  "email": "karthick@nexbridge.io",
  "phone": "+91 98765 43210",
  "source": "LinkedIn",
  "status": "Contacted",
  "owner": "Sarah Jenkins",
  "website": "nexbridge.io",
  "industry": "IT Services",
  "notes": "Updated notes",
  "createdAt": "2024-08-15T00:00:00Z",
  "lastContactedAt": "2024-09-15T00:00:00Z"
}
```

**Response:** Same as Get Lead By ID

### Convert Lead to Account
**Endpoint:** `POST /api/leads/{leadId}/convert`

**Request Body (Optional - Conversion Form Data):**
```json
{
  "domain": "nexbridge.io",
  "industry": "IT Services",
  "tier": "Strategic",
  "primaryOwner": "Sarah Jenkins",
  "description": "Enterprise IT services provider"
}
```

**Response:**
```json
{
  "data": {
    "accountId": "acc_nexbridge_tech",
    "message": "Lead successfully converted to account"
  }
}
```

### Check Duplicate Lead
**Endpoint:** `POST /api/leads/check-duplicate`

**Request Body:**
```json
{
  "email": "karthick@nexbridge.io"
}
```

**Response:**
```json
{
  "data": {
    "isDuplicate": true
  }
}
```

---

## 2. ACCOUNTS API

### Get All Accounts
**Endpoint:** `GET /api/accounts`

**Query Parameters:**
- `search` (optional): string - Search by company name or domain
- `industry` (optional): string - Filter by industry
- `tier` (optional): 'Bronze' | 'Silver' | 'Gold' | 'Diamond' | 'Strategic'
- `owner` (optional): string - Primary owner name

**Response:**
```json
{
  "data": [
    {
      "id": "acc_nexbridge",
      "companyName": "Nexbridge Tech",
      "domain": "nexbridge.io",
      "industry": "IT Services",
      "tier": "Strategic",
      "primaryOwner": "Sarah Jenkins",
      "description": "Enterprise IT services provider specializing in cloud migration and digital transformation.",
      "activeDealsCount": 3,
      "contacts": [
        {
          "id": "con_001",
          "name": "Karthick Selvam",
          "role": "CTO",
          "email": "karthick@nexbridge.io",
          "phone": "+91 98765 43210",
          "isDecisionMaker": true,
          "accountId": "acc_nexbridge"
        },
        {
          "id": "con_002",
          "name": "Priya Rajan",
          "role": "VP Engineering",
          "email": "priya@nexbridge.io",
          "phone": null,
          "isDecisionMaker": false,
          "accountId": "acc_nexbridge"
        }
      ],
      "createdAt": "2024-01-15T00:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "pageSize": 25,
    "total": 3
  }
}
```

### Get Account By ID
**Endpoint:** `GET /api/accounts/{accountId}`

**Response:**
```json
{
  "data": {
    "id": "acc_nexbridge",
    "companyName": "Nexbridge Tech",
    "domain": "nexbridge.io",
    "industry": "IT Services",
    "tier": "Strategic",
    "primaryOwner": "Sarah Jenkins",
    "description": "Enterprise IT services provider specializing in cloud migration and digital transformation.",
    "activeDealsCount": 3,
    "contacts": [
      {
        "id": "con_001",
        "name": "Karthick Selvam",
        "role": "CTO",
        "email": "karthick@nexbridge.io",
        "phone": "+91 98765 43210",
        "isDecisionMaker": true,
        "accountId": "acc_nexbridge"
      }
    ],
    "createdAt": "2024-01-15T00:00:00Z"
  }
}
```

### Create Account
**Endpoint:** `POST /api/accounts`

**Request Body:**
```json
{
  "companyName": "Tech Innovators Inc",
  "domain": "techinnovators.com",
  "industry": "Software Development",
  "tier": "Gold",
  "primaryOwner": "M. Chen",
  "description": "Leading software development firm",
  "contacts": []
}
```

**Response:**
```json
{
  "data": {
    "id": "acc_tech_innovators",
    "companyName": "Tech Innovators Inc",
    "domain": "techinnovators.com",
    "industry": "Software Development",
    "tier": "Gold",
    "primaryOwner": "M. Chen",
    "description": "Leading software development firm",
    "activeDealsCount": 0,
    "contacts": [],
    "createdAt": "2024-09-20T10:30:00Z"
  }
}
```

### Update Account
**Endpoint:** `PUT /api/accounts/{accountId}`

**Request Body:** Same structure as Create Account but with ID

**Response:** Same as Get Account By ID

### Add Contact to Account
**Endpoint:** `POST /api/accounts/{accountId}/contacts`

**Request Body:**
```json
{
  "name": "Anjali Singh",
  "role": "Product Manager",
  "email": "anjali@nexbridge.io",
  "phone": "+91 87654 32100",
  "isDecisionMaker": false
}
```

**Response:**
```json
{
  "data": {
    "id": "con_new_uuid",
    "name": "Anjali Singh",
    "role": "Product Manager",
    "email": "anjali@nexbridge.io",
    "phone": "+91 87654 32100",
    "isDecisionMaker": false,
    "accountId": "acc_nexbridge"
  }
}
```

---

## 3. DEALS API

### Get All Deals
**Endpoint:** `GET /api/deals`

**Query Parameters:**
- `owner` (optional): string - Deal owner
- `tier` (optional): 'Bronze' | 'Silver' | 'Gold' | 'Diamond' | 'Strategic'
- `stage` (optional): 'Prospecting' | 'Qualified to Buy' | 'Evaluation' | 'Proposals' | 'Negotiation' | 'Closed Won' | 'Closed Lost'

**Response:**
```json
{
  "data": [
    {
      "id": "deal_001",
      "name": "Q3 Enterprise Expansion",
      "accountId": "acc_nexbridge",
      "accountName": "Nexbridge Tech",
      "contactId": "con_001",
      "contactName": "Karthick Selvam",
      "value": 4500000,
      "currency": "INR",
      "stage": "Proposals",
      "expectedCloseDate": "2024-09-15T00:00:00Z",
      "owner": "Sarah Jenkins",
      "tier": "Strategic",
      "description": "Expanding their cloud infrastructure to support 10k new concurrent users.",
      "stakeholders": [
        {
          "id": "st_1",
          "name": "Karthick Selvam",
          "role": "CTO",
          "email": "karthick@nexbridge.io",
          "dealId": "deal_001",
          "isPrimary": true
        }
      ],
      "createdAt": "2024-07-01T00:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "pageSize": 25,
    "total": 3
  }
}
```

### Get Deal By ID
**Endpoint:** `GET /api/deals/{dealId}`

**Response:**
```json
{
  "data": {
    "id": "deal_001",
    "name": "Q3 Enterprise Expansion",
    "accountId": "acc_nexbridge",
    "accountName": "Nexbridge Tech",
    "contactId": "con_001",
    "contactName": "Karthick Selvam",
    "value": 4500000,
    "currency": "INR",
    "stage": "Proposals",
    "expectedCloseDate": "2024-09-15T00:00:00Z",
    "owner": "Sarah Jenkins",
    "tier": "Strategic",
    "description": "Expanding their cloud infrastructure to support 10k new concurrent users.",
    "stakeholders": [
      {
        "id": "st_1",
        "name": "Karthick Selvam",
        "role": "CTO",
        "email": "karthick@nexbridge.io",
        "dealId": "deal_001",
        "isPrimary": true
      }
    ],
    "createdAt": "2024-07-01T00:00:00Z"
  }
}
```

### Create Deal
**Endpoint:** `POST /api/deals`

**Request Body:**
```json
{
  "name": "New Cloud Project",
  "accountId": "acc_nexbridge",
  "accountName": "Nexbridge Tech",
  "contactId": "con_001",
  "contactName": "Karthick Selvam",
  "value": 2500000,
  "currency": "INR",
  "stage": "Prospecting",
  "expectedCloseDate": "2024-12-31T00:00:00Z",
  "owner": "Sarah Jenkins",
  "tier": "Strategic",
  "description": "New cloud infrastructure project",
  "stakeholders": []
}
```

**Response:**
```json
{
  "data": {
    "id": "deal_new_uuid",
    "name": "New Cloud Project",
    "accountId": "acc_nexbridge",
    "accountName": "Nexbridge Tech",
    "contactId": "con_001",
    "contactName": "Karthick Selvam",
    "value": 2500000,
    "currency": "INR",
    "stage": "Prospecting",
    "expectedCloseDate": "2024-12-31T00:00:00Z",
    "owner": "Sarah Jenkins",
    "tier": "Strategic",
    "description": "New cloud infrastructure project",
    "stakeholders": [],
    "createdAt": "2024-09-20T10:30:00Z"
  }
}
```

### Update Deal
**Endpoint:** `PUT /api/deals/{dealId}`

**Request Body:** Same as Create Deal with ID

**Response:** Same as Get Deal By ID

### Update Deal Stage
**Endpoint:** `PATCH /api/deals/{dealId}/stage`

**Request Body:**
```json
{
  "stage": "Evaluation"
}
```

**Response:**
```json
{
  "data": {
    "id": "deal_001",
    "name": "Q3 Enterprise Expansion",
    "accountId": "acc_nexbridge",
    "accountName": "Nexbridge Tech",
    "stage": "Evaluation",
    "updatedAt": "2024-09-20T10:30:00Z"
  }
}
```

### Add Stakeholder to Deal
**Endpoint:** `POST /api/deals/{dealId}/stakeholders`

**Request Body:**
```json
{
  "name": "Priya Rajan",
  "role": "VP Engineering",
  "email": "priya@nexbridge.io",
  "isPrimary": false
}
```

**Response:**
```json
{
  "data": {
    "id": "st_new_uuid",
    "name": "Priya Rajan",
    "role": "VP Engineering",
    "email": "priya@nexbridge.io",
    "dealId": "deal_001",
    "isPrimary": false
  }
}
```

---

## 4. ACTIVITY LOG API

### Get Activities for Entity
**Endpoint:** `GET /api/activities?entityType={entityType}&entityId={entityId}`

**Query Parameters:**
- `entityType`: 'Deal' | 'Account' | 'Lead'
- `entityId`: string - ID of the entity

**Response:**
```json
{
  "data": [
    {
      "id": "act_1",
      "type": "Meeting",
      "title": "Discovery Call",
      "description": "Discussed cloud migration strategy and timeline expectations.",
      "entityType": "Deal",
      "entityId": "deal_001",
      "performedBy": "Sarah Jenkins",
      "performedAt": "2024-09-18T10:00:00Z"
    },
    {
      "id": "act_2",
      "type": "Email",
      "title": "Sent Proposal Draft",
      "description": "Emailed the V1 architecture proposal for review.",
      "entityType": "Deal",
      "entityId": "deal_001",
      "performedBy": "Sarah Jenkins",
      "performedAt": "2024-09-20T15:00:00Z"
    },
    {
      "id": "act_3",
      "type": "Stage Change",
      "title": "Stage changed to Proposals",
      "entityType": "Deal",
      "entityId": "deal_001",
      "performedBy": "System",
      "performedAt": "2024-09-20T15:05:00Z"
    }
  ]
}
```

### Log Activity
**Endpoint:** `POST /api/activities`

**Request Body:**
```json
{
  "type": "Meeting",
  "title": "Quarterly Business Review",
  "description": "Discussed Q4 roadmap and budget allocation",
  "entityType": "Account",
  "entityId": "acc_nexbridge",
  "performedBy": "Sarah Jenkins"
}
```

**Response:**
```json
{
  "data": {
    "id": "act_new_uuid",
    "type": "Meeting",
    "title": "Quarterly Business Review",
    "description": "Discussed Q4 roadmap and budget allocation",
    "entityType": "Account",
    "entityId": "acc_nexbridge",
    "performedBy": "Sarah Jenkins",
    "performedAt": "2024-09-20T10:30:00Z"
  }
}
```

---

## 5. CHECKLIST API

### Get Checklist for Deal
**Endpoint:** `GET /api/checklists/deals/{dealId}`

**Response:**
```json
{
  "data": [
    {
      "stageName": "Discovery Phase",
      "stageOrder": 1,
      "items": [
        {
          "id": "chk_1",
          "dealId": "deal_001",
          "stageName": "Discovery Phase",
          "stageOrder": 1,
          "itemText": "Identify Key Stakeholders",
          "isCompleted": true,
          "owningTeam": "Sales",
          "completedAt": "2024-09-15T00:00:00Z",
          "completedBy": "Sarah Jenkins",
          "notes": null,
          "isConditional": false
        },
        {
          "id": "chk_2",
          "dealId": "deal_001",
          "stageName": "Discovery Phase",
          "stageOrder": 1,
          "itemText": "Define Budget Constraints",
          "isCompleted": true,
          "owningTeam": "Sales",
          "completedAt": "2024-09-16T00:00:00Z",
          "completedBy": "Sarah Jenkins",
          "notes": null,
          "isConditional": false
        },
        {
          "id": "chk_3",
          "dealId": "deal_001",
          "stageName": "Discovery Phase",
          "stageOrder": 1,
          "itemText": "Technical Requirements Document",
          "isCompleted": false,
          "owningTeam": "Pre-Sales",
          "completedAt": null,
          "completedBy": null,
          "notes": "Waiting for client IT team to send architecture diagrams.",
          "isConditional": false
        }
      ]
    },
    {
      "stageName": "Solution Design",
      "stageOrder": 2,
      "items": [
        {
          "id": "chk_4",
          "dealId": "deal_001",
          "stageName": "Solution Design",
          "stageOrder": 2,
          "itemText": "Architecture Review",
          "isCompleted": false,
          "owningTeam": "Pre-Sales",
          "completedAt": null,
          "completedBy": null,
          "notes": null,
          "isConditional": false
        },
        {
          "id": "chk_5",
          "dealId": "deal_001",
          "stageName": "Solution Design",
          "stageOrder": 2,
          "itemText": "Security Compliance Check",
          "isCompleted": false,
          "owningTeam": "InfoSec",
          "completedAt": null,
          "completedBy": null,
          "notes": null,
          "isConditional": true,
          "conditionDescription": "Only if deal involves cloud migration"
        }
      ]
    }
  ]
}
```

### Toggle Checklist Item Status
**Endpoint:** `PATCH /api/checklists/items/{itemId}/status`

**Request Body:**
```json
{
  "isCompleted": true
}
```

**Response:**
```json
{
  "data": {
    "id": "chk_1",
    "dealId": "deal_001",
    "itemText": "Identify Key Stakeholders",
    "isCompleted": true,
    "completedAt": "2024-09-20T10:30:00Z",
    "completedBy": "Current User"
  }
}
```

### Update Checklist Item Notes
**Endpoint:** `PATCH /api/checklists/items/{itemId}/notes`

**Request Body:**
```json
{
  "notes": "Received architecture diagrams from client. Reviewing with team."
}
```

**Response:**
```json
{
  "data": {
    "id": "chk_3",
    "dealId": "deal_001",
    "itemText": "Technical Requirements Document",
    "notes": "Received architecture diagrams from client. Reviewing with team.",
    "updatedAt": "2024-09-20T10:30:00Z"
  }
}
```

---

## 6. NOTIFICATIONS API

### Get All Notifications
**Endpoint:** `GET /api/notifications`

**Response:**
```json
{
  "data": [
    {
      "id": "notif_1",
      "type": "Lead Assigned",
      "title": "New Lead Assigned",
      "message": "Alex Johnson has been assigned to you.",
      "entityId": "lead_002",
      "entityType": "Lead",
      "isRead": false,
      "createdAt": "2024-09-20T10:25:00Z"
    },
    {
      "id": "notif_2",
      "type": "Deal Stage Changed",
      "title": "Deal Stage Updated",
      "message": "Q3 Enterprise Expansion moved to Proposals.",
      "entityId": "deal_001",
      "entityType": "Deal",
      "isRead": false,
      "createdAt": "2024-09-20T09:00:00Z"
    },
    {
      "id": "notif_3",
      "type": "Mention",
      "title": "You were mentioned",
      "message": "M. Chen mentioned you in a note on Cloudverge Solutions.",
      "entityId": "acc_cloudverge",
      "entityType": "Account",
      "isRead": true,
      "createdAt": "2024-09-19T14:30:00Z"
    }
  ]
}
```

### Get Unread Count
**Endpoint:** `GET /api/notifications/unread-count`

**Response:**
```json
{
  "data": {
    "unreadCount": 2
  }
}
```

### Mark Notification as Read
**Endpoint:** `PATCH /api/notifications/{notificationId}/read`

**Response:**
```json
{
  "data": {
    "id": "notif_1",
    "isRead": true,
    "updatedAt": "2024-09-20T10:30:00Z"
  }
}
```

### Mark All Notifications as Read
**Endpoint:** `PATCH /api/notifications/read-all`

**Response:**
```json
{
  "data": {
    "message": "All notifications marked as read",
    "updatedCount": 2
  }
}
```

---

## 7. ANALYTICS API

### Get Sales Metrics
**Endpoint:** `GET /api/analytics/sales-metrics?period=Monthly`

**Query Parameters:**
- `period` (optional): 'Monthly' | 'Quarterly' | 'Yearly' - Default: 'Monthly'

**Response:**
```json
{
  "data": {
    "revenueHistory": [
      {
        "date": "2024-04-01T00:00:00Z",
        "amount": 500000.0
      },
      {
        "date": "2024-05-01T00:00:00Z",
        "amount": 800000.0
      },
      {
        "date": "2024-06-01T00:00:00Z",
        "amount": 750000.0
      },
      {
        "date": "2024-07-01T00:00:00Z",
        "amount": 1100000.0
      },
      {
        "date": "2024-08-01T00:00:00Z",
        "amount": 1250000.0
      },
      {
        "date": "2024-09-01T00:00:00Z",
        "amount": 1450000.0
      }
    ],
    "targetHistory": [
      {
        "date": "2024-04-01T00:00:00Z",
        "amount": 600000.0
      },
      {
        "date": "2024-05-01T00:00:00Z",
        "amount": 780000.0
      },
      {
        "date": "2024-06-01T00:00:00Z",
        "amount": 960000.0
      },
      {
        "date": "2024-07-01T00:00:00Z",
        "amount": 1140000.0
      },
      {
        "date": "2024-08-01T00:00:00Z",
        "amount": 1320000.0
      },
      {
        "date": "2024-09-01T00:00:00Z",
        "amount": 1500000.0
      }
    ],
    "overallWinRate": 0.68,
    "funnel": [
      {
        "stageName": "Leads",
        "count": 450,
        "value": 0
      },
      {
        "stageName": "Qualified",
        "count": 180,
        "value": 45000000
      },
      {
        "stageName": "Proposals",
        "count": 85,
        "value": 21000000
      },
      {
        "stageName": "Closed Won",
        "count": 58,
        "value": 12500000
      }
    ],
    "leaderboard": [
      {
        "repName": "Sarah Jenkins",
        "dealsClosed": 24,
        "revenueGenerated": 6200000,
        "winRate": 0.75
      },
      {
        "repName": "M. Chen",
        "dealsClosed": 18,
        "revenueGenerated": 4100000,
        "winRate": 0.62
      },
      {
        "repName": "P. Kumar",
        "dealsClosed": 16,
        "revenueGenerated": 2200000,
        "winRate": 0.58
      }
    ]
  }
}
```

---

## Error Response Format

All endpoints follow this error response format:

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable error message",
    "details": {}
  }
}
```

**Common Error Codes:**
- `VALIDATION_ERROR` - Request validation failed
- `NOT_FOUND` - Resource not found
- `UNAUTHORIZED` - Authentication required
- `FORBIDDEN` - Access denied
- `CONFLICT` - Resource conflict (e.g., duplicate email)
- `SERVER_ERROR` - Internal server error

**Example Error Response:**
```json
{
  "error": {
    "code": "NOT_FOUND",
    "message": "Lead with ID 'lead_999' not found",
    "details": {
      "resourceType": "Lead",
      "resourceId": "lead_999"
    }
  }
}
```

---

## Enum Values

### Lead Status
- `New` – newly created lead, not yet contacted
- `Contacted` – initial contact made
- `Junk` – invalid or spam lead
- `Closed` – no longer pursuing
- `Contact in Future` – follow up scheduled

### Account/Lead Tier
- `Bronze`
- `Silver`
- `Gold`
- `Diamond`
- `Strategic`
- `Not Applicable` – for unclassified accounts/leads

### Deal Stage
- `Prospecting`
- `Qualified to Buy`
- `Evaluation`
- `Proposals`
- `Negotiation`
- `Closed Won`
- `Closed Lost`

### Activity Type
- `Meeting`
- `Email`
- `Call`
- `Stage Change`
- `Note`
- `Document Upload`

### Notification Type
- `Lead Assigned`
- `Deal Stage Changed`
- `Deal Created`
- `Contact Added`
- `Mention`
- `Task Assigned`
- `Task Completed`

---

## Pagination

All list endpoints support pagination with the following parameters:

**Query Parameters:**
- `page` (optional): number - Page number, starts at 1. Default: 1
- `pageSize` (optional): number - Items per page. Default: 25, Max: 100

**Pagination Response:**
```json
{
  "data": [],
  "pagination": {
    "page": 1,
    "pageSize": 25,
    "total": 100,
    "totalPages": 4
  }
}
```

---

## Date Format

All dates use ISO 8601 format: `YYYY-MM-DDTHH:mm:ssZ` (UTC timezone)

---

## Authentication

Include authentication token in request headers:
```
Authorization: Bearer {token}
```

---

## Rate Limiting

- Rate limit: 1000 requests per hour per user
- Response headers include:
  - `X-RateLimit-Limit`: Total limit
  - `X-RateLimit-Remaining`: Requests remaining
  - `X-RateLimit-Reset`: Unix timestamp when limit resets
