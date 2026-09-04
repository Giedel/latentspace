# 📊 Database Seeder - Data Structure & Relationships

Visual representation of the seeded data and their relationships.

## 🗂️ Table Relationships

```
┌─────────────────────────────────────┐
│     core_ai_actions (6 records)     │
│  ┌───────────────────────────────┐  │
│  │ action_id (PK)                │  │
│  │ raw_user_input                │  │
│  │ inferred_domain               │  │
│  │ execution_strategy            │  │
│  │ json_payload                  │  │
│  │ status                        │  │
│  │ created_at                    │  │
│  └───────────────────────────────┘  │
└──────────┬──────────┬────────────────┘
           │          │
           │          │
    ┌──────┴──┐   ┌──┴─────────┐
    │         │   │            │
    ▼         ▼   ▼            ▼
┌─────────┐ ┌──────────┐ ┌──────────────────┐
│ Finance │ │  Tasks   │ │  Dependencies    │
│ Ledger  │ │          │ │                  │
│ (6)     │ │  (6)     │ │      (5)         │
└─────────┘ └──────────┘ └──────────────────┘

┌────────────────────────────────┐
│   user_context_memory (6)      │
│   (Independent table)          │
└────────────────────────────────┘
```

## 📋 Core AI Actions Breakdown

```
┌─────────────┬──────────┬─────────────┬───────────┐
│   Domain    │ Strategy │   Status    │  Count    │
├─────────────┼──────────┼─────────────┼───────────┤
│  FINANCE    │  SINGLE  │  COMPLETED  │    2      │
│  TO-DO      │  SINGLE  │  PENDING    │    1      │
│  PLANNING   │  MULTI   │ IN_PROGRESS │    1      │
│  REMINDER   │  SINGLE  │  APPROVED   │    1      │
│  NOTE       │  SINGLE  │  COMPLETED  │    1      │
└─────────────┴──────────┴─────────────┴───────────┘
```

## 💰 Finance Ledger Data Flow

```
Action #1                     Action #2
    │                             │
    ├─> Finance Record #1         ├─> Finance Record #2
    │   Type: EXPENSE             │   Type: INCOME
    │   Amount: ₱2,500            │   Amount: ₱45,000
    │   Category: Groceries       │   Category: Salary
    └──────────────────           └──────────────────

Additional Finance Actions (4 more created automatically)
    │
    ├─> EXPENSE: Gas ₱850
    ├─> EXPENSE: Clothing ₱1,500
    ├─> INCOME: Freelance ₱5,000
    └─> EXPENSE: Utilities ₱3,200

Financial Summary:
┌──────────────────────────────────┐
│  Income:    ₱50,000              │
│  Expenses:  ₱7,550               │
│  ────────────────────            │
│  Net:       +₱42,450             │
└──────────────────────────────────┘
```

## ✅ Admin Tasks Structure

```
┌──────────────────────────────────────────────┐
│              Admin Tasks (6)                  │
├──────────────────────────────────────────────┤
│                                              │
│  [PENDING] Team Meeting                      │
│  └─ Due: Tomorrow                            │
│  └─ Recurring: No                            │
│                                              │
│  [PENDING] Submit quarterly report           │
│  └─ Due: +7 days                             │
│  └─ Recurring: No                            │
│                                              │
│  [PENDING] Weekly team sync                  │
│  └─ Due: +3 days                             │
│  └─ Recurring: Yes ↻                         │
│                                              │
│  [PENDING] Code review for PR #234           │
│  └─ Due: +2 days                             │
│  └─ Recurring: No                            │
│                                              │
│  [COMPLETED] ✓ Update documentation          │
│  └─ Due: +5 days                             │
│  └─ Recurring: No                            │
│                                              │
│  [PENDING] Backup database                   │
│  └─ Due: +30 days                            │
│  └─ Recurring: Yes ↻                         │
└──────────────────────────────────────────────┘
```

## 🧠 Context Memory Types

```
┌────────────────────────────────────────────┐
│         Context Memory (6 entries)         │
├────────────────────────────────────────────┤
│                                            │
│  [user_preference]                         │
│  ├─ default_currency: PHP                  │
│  ├─ notification_settings: {...}           │
│  └─ ui_theme: dark mode                    │
│                                            │
│  [user_context]                            │
│  ├─ work_location: Manila                  │
│  └─ favorite_categories: {...}             │
│                                            │
│  [system_state]                            │
│  └─ last_sync: 30 minutes ago              │
└────────────────────────────────────────────┘
```

## 🔗 Action Dependencies (DAG)

```
         Action A
           │
     ┌─────┼─────┐
     │           │
     ▼           ▼
Action B    Action D
     │      (non-blocking)
     ▼
Action C ────────┐
     │           │
     ▼           ▼
         Action E
```

**Execution Flow:**
1. Action A executes first
2. Action B and D can start (B blocks, D doesn't)
3. After B completes, Action C starts
4. Action E waits for both C and D
5. Full workflow completes

## 📊 Data Distribution

```
Database Record Count by Table:
┌───────────────────────┬────────┐
│  Table                │ Count  │
├───────────────────────┼────────┤
│  core_ai_actions      │   6+   │ ← +4 auto-created for finance
│  finance_ledger       │   6    │
│  admin_tasks          │   6    │
│  context_memory       │   6    │
│  action_dependencies  │   5    │
├───────────────────────┼────────┤
│  TOTAL RECORDS        │  29+   │
└───────────────────────┴────────┘

+ = Additional records created automatically
```

## 🎯 Domain Distribution

```
Core AI Actions by Domain:

  FINANCE  ███████ 33%
  TO-DO    ███████ 33%
  PLANNING ███     16%
  REMINDER ███     8%
  NOTE     ███     8%
```

## 🔄 Status Distribution

```
Core AI Actions by Status:

  COMPLETED    ████ 50%
  PENDING      ███  25%
  IN_PROGRESS  ██   12.5%
  APPROVED     ██   12.5%
```

## 💳 Transaction Categories

```
Finance Transactions by Category:

Expenses (4):
  Food & Dining      ₱2,500  ███████████
  Transportation     ₱850    ████
  Shopping          ₱1,500   ███████
  Utilities         ₱3,200   ██████████████

Income (2):
  Salary           ₱45,000  ██████████████████████████
  Freelance         ₱5,000  ███
```

## 🗓️ Task Timeline

```
Timeline (Next 30 Days):

NOW ────────────────────────────────────> +30 days
 │      │       │       │       │           │
 │   +1 day  +2d    +3d    +7d          +30d
 │      │       │       │       │           │
 │   Meeting Review Sync Report      Backup
 │             │       │       │           │
 │             PR      Weekly  Quarterly  Monthly
 │            #234     Sync   Report     Backup
 │
Documentation ✓
(Completed)
```

## 🔐 Foreign Key Relationships

```
Referential Integrity:

1. domain_finance_ledger.action_id 
   → core_ai_actions.action_id

2. domain_admin_tasks.action_id 
   → core_ai_actions.action_id

3. action_dependencies.parent_action_id 
   → core_ai_actions.action_id

4. action_dependencies.child_action_id 
   → core_ai_actions.action_id

5. user_context_memory 
   → No foreign keys (independent)

CASCADE DELETE: 
If core_ai_action deleted → related records auto-deleted
```

## 📝 Sample Data Examples

### Example 1: Complete Finance Flow

```
User Input: "Add expense for groceries ₱2,500"
     │
     ▼
Core AI Action Created:
  - action_id: "abc-123..."
  - domain: FINANCE
  - status: COMPLETED
     │
     ▼
Finance Ledger Entry:
  - action_id: "abc-123..." (FK)
  - type: EXPENSE
  - amount: 250000 cents
  - category: Food & Dining
```

### Example 2: Complete Task Flow

```
User Input: "Schedule meeting with team tomorrow"
     │
     ▼
Core AI Action Created:
  - action_id: "def-456..."
  - domain: TO-DO
  - status: PENDING
     │
     ▼
Admin Task Entry:
  - action_id: "def-456..." (FK)
  - title: Team Meeting
  - due_date: Tomorrow
  - recurring: No
```

## 🎨 Data Characteristics

```
✓ Realistic timestamps (spread over time)
✓ Valid UUIDs for all IDs
✓ Proper foreign key relationships
✓ Valid JSON in json_payload
✓ Enforced CHECK constraints
✓ Mixed statuses and types
✓ Philippine context (PHP currency)
✓ Real-world scenarios
```

---

This structure ensures:
1. **Data Integrity**: All relationships valid
2. **Realism**: Data represents actual use cases
3. **Variety**: Mixed statuses, types, domains
4. **Completeness**: All tables populated
5. **Testability**: Good coverage for testing features
