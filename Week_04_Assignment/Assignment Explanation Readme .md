# Week 4 Assignment — Azure Cloud Fundamentals and Data Pipeline Implementation using ADF
## Objective

The goal of this assignment was to understand core Azure cloud concepts and implement a complete, working data pipeline using Azure Storage Account and Azure Data Factory (ADF). 
The pipeline was designed to intelligently filter and copy only specific CSV files (those starting with the name "superstore") from a source Blob container to a destination container using Get Metadata, ForEach, If Condition, and Copy Data activities.

---

## Architecture Overview

```
Azure Portal
└── resource-group-celebal                   (Resource Group — East US)
    └── celebal                              (Storage Account)
        ├── superstore-dataset               (Source Container — CSV files)
        └── destination-superstore-dataset   (Destination Container — copied files)

Azure Data Factory: data-factory-week-04
└── Pipeline: Get_Metadata
    ├── Linked Service: linked_service_superstore  (Azure Blob Storage)
    ├── Datasets:
    │   ├── mata_data_source      (points to source container)
    │   ├── source_dataset        (source CSV files)
    │   └── Destination_dataset   (destination container)
    └── Pipeline Flow:
        Get Metadata → ForEach → If Condition (File_Name_Check) → Copy Data
```

---

## Task 1 — Explore Azure Portal and Create Resource Group

### What is a Resource Group?

A Resource Group is a logical container in Azure that holds all related resources for a project. Think of it like a project folder everything inside belongs to the same project. When you delete a Resource Group, all resources inside it get deleted automatically.

In production environments, teams create separate Resource Groups for each environment:
- `rg-project-dev` → development
- `rg-project-staging` → testing
- `rg-project-prod` → production

This ensures no accidental mixing of environments.

### What was done

- Opened Azure Portal (`portal.azure.com`) and explored the home dashboard
- Navigated to **Resource Manager → Resource Groups**
- Created a new Resource Group named **`resource-group-celebal`**
- Selected region: **East US** (chosen for low latency and availability of required services)
- The Resource Group was created under **Azure Subscription 1**

### What I learned

The Azure Portal is the central control panel for all Azure services. The hierarchy in Azure is:

```
Azure Account
└── Subscription (billing boundary)
    └── Resource Group (logical container)
        └── Resources (Storage, ADF, SQL DB, etc.)
```

Every resource in Azure must belong to a Resource Group. Organizing resources this way makes it easy to manage, monitor costs, and control access at a group level.

**Screenshot reference:** Resource Groups page showing `resource-group-celebal` under Azure Subscription 1, East US region.
<img width="1840" height="923" alt="Screenshot 2026-06-20 025342" src="https://github.com/user-attachments/assets/8547a4c8-d650-4824-b08a-d446f85b7e13" />

---

## Task 2 — Storage Setup

### What is a Storage Account?

An Azure Storage Account is a cloud storage service that can hold different types of data — files, blobs (unstructured data), tables, and queues. In Data Engineering, Storage Accounts are primarily used to store raw data files (CSV, JSON, Parquet) that act as the source or destination of pipelines.

### What is a Blob Container?

A Blob Container is like a folder inside a Storage Account. It holds Blob files any type of file (CSV, JSON, images, etc.). Each container has its own access level (Private, Blob, Container).

### What was done

1. Created a Storage Account named **`celebal`** inside `resource-group-celebal`, region East US
2. Inside the `celebal` storage account, created **3 containers**:
   - **`$logs`** — auto-created by Azure for diagnostic logging
   - **`superstore-dataset`** — source container where the original CSV file(s) were uploaded
   - **`destination-superstore-dataset`** — destination container, initially empty, receives files after pipeline runs

3. Uploaded the **Superstore CSV dataset** into the `superstore-dataset` container

### Why two containers?

Separating source and destination is a best practice in Data Engineering:
- **Source** = raw, original data — should not be modified
- **Destination** = processed/copied data — output of the pipeline

This ensures the original data is always preserved, and if the pipeline runs again, it won't corrupt the source.

Azure Storage uses a **flat namespace** by default (Blob Storage). For big data analytics with hierarchical folder structures and fine-grained security, **ADLS Gen2** (Azure Data Lake Storage Gen2) is used which is built on top of Blob Storage with Hierarchical Namespace enabled. For this assignment, standard Blob Storage was sufficient.

**Screenshot reference:** `celebal | Containers` page showing all 3 containers — `$logs`, `destination-superstore-dataset`, and `superstore-dataset`.
<img width="1896" height="899" alt="Screenshot 2026-06-21 215510" src="https://github.com/user-attachments/assets/50e26d15-2653-4a56-8f40-a43920087426" />


---

## Task 3 — ADF Basics

### What is Azure Data Factory?

Azure Data Factory (ADF) is Microsoft Azure's managed cloud ETL/ELT service. It allows you to create data pipelines that move and transform data between different sources and destinations without managing any server or infrastructure. ADF is a PaaS (Platform as a Service) Azure handles all the compute, scaling, and maintenance.

ADF has 3 main sections in its UI:
- **Author** — where you build pipelines, datasets, linked services
- **Monitor** — where you track pipeline runs, activity status, errors
- **Manage** — where you configure connections (Linked Services), triggers, integration runtimes

### Step 3a — Created Linked Service

A Linked Service is ADF's connection definition it tells ADF how to connect to an external data store. Think of it like a connection string with credentials.

**Created:** `linked_service_superstore`  
**Type:** Azure Blob Storage  
**Connected to:** `celebal` storage account

This single Linked Service is reused by all 3 datasets because all data (source and destination) lives in the same storage account.

**Related count = 3** means this Linked Service is used by 3 datasets — which is correct (mata_data_source, source_dataset, Destination_dataset).

### Step 3b — Created Datasets

A Dataset is a pointer to specific data within a Linked Service. It tells ADF exactly which container, which file/folder, and what format the data is in.

3 Datasets were created:

| Dataset Name | Purpose | Points To |
|---|---|---|
| `mata_data_source` | Used by Get Metadata activity — scans the container | `superstore-dataset` container (folder level) |
| `source_dataset` | Source for Copy Data activity — reads CSV files | `superstore-dataset` container (file level, CSV format) |
| `Destination_dataset` | Destination for Copy Data — writes output | `destination-superstore-dataset` container |

**Why 3 datasets instead of 2?**  
Get Metadata needs to scan the entire container (folder) to get a list of all files. A separate dataset (`mata_data_source`) pointing to the container level was created for this purpose. The `source_dataset` points to individual files and is used inside the ForEach loop for the actual copy operation.

### Step 3c — Get Metadata Activity

Get Metadata is an ADF activity that retrieves information about a file or folder — such as:
- `childItems` → list of all files inside a container/folder
- `exists` → whether a file/folder exists
- `size` → file size in bytes
- `lastModified` → last modified timestamp

In this pipeline, Get Metadata was configured to retrieve the **`childItems`** of the `superstore-dataset` container returning a list of all files present in the container.

**Output of Get Metadata:**
<img width="1851" height="882" alt="Screenshot 2026-06-20 232056" src="https://github.com/user-attachments/assets/291201c7-7b14-4264-8434-6afe0c10e2bf" />

This output is then passed to the ForEach activity.

**Screenshot reference:** Linked Services page showing `linked_service_superstore` of type Azure Blob Storage with 3 related items. Datasets panel showing all 3 datasets.
<img width="1842" height="874" alt="Screenshot 2026-06-21 215546" src="https://github.com/user-attachments/assets/59368918-6800-431c-9271-3923b7bfe732" />
<img width="368" height="162" alt="Screenshot 2026-06-21 215613" src="https://github.com/user-attachments/assets/c5ec0960-fd8e-4ae2-9cba-d1b7289c0ac1" />

---

## Task 4 — Pipeline Development

### Pipeline Name: `Get_Metadata`

The pipeline implements a smart file filtering logic instead of blindly copying all files, it first checks each file's name and copies only those that start with "superstore".

### Pipeline Flow

```
[Get Metadata] ──→ [ForEach: For_Each_Dataset] ──→ [If Condition: File_Name_Check] ──→ [Copy Data]
```

### Activity 1 — Get Metadata

- **Purpose:** Scan the `superstore-dataset` container and get a list of all files
- **Dataset used:** `mata_data_source`
- **Field list:** `childItems` (returns array of all file names)
- **Output:** Array of file objects passed to ForEach

### Activity 2 — ForEach: `For_Each_Dataset`

- **Purpose:** Loop over every file returned by Get Metadata
- **Items:** `@activity('Get Metadata').output.childItems`
- **Mode:** Sequential (processes one file at a time)
- **Inside ForEach:** Contains the If Condition activity

**Why ForEach?**  
Without ForEach, the pipeline can only process one hardcoded file. ForEach makes the pipeline dynamic it automatically handles any number of files without changing the pipeline design. If 5 files are added to the container tomorrow, the pipeline will process all 5 automatically.

### Activity 3 — If Condition: `File_Name_Check`

This is the **core business logic** of the pipeline.

- **Purpose:** Check if the current file's name starts with "superstore"
- **Condition expression:**
```
@startsWith(item().name, 'superstore')
```
- **If TRUE:** Proceed to Copy Data activity
- **If FALSE:** Skip the file (do nothing)

**Why this logic?**  
The source container may contain multiple CSV files of different types. The requirement was to copy only "superstore" files. Using an If Condition inside ForEach, we can filter at the file level this is a pattern-based selective copy approach used in real production pipelines.

### Activity 4 — Copy Data

- **Purpose:** Copy the current file from source to destination
- **Source dataset:** `source_dataset` (pointing to `superstore-dataset` container)
- **Sink dataset:** `Destination_dataset` (pointing to `destination-superstore-dataset` container)
- **File reference:** `@item().name` (dynamic — current file in the loop)

**Screenshot reference:** Pipeline canvas showing Get Metadata → ForEach with For_Each_Dataset and File_Name_Check activities connected to Copy Data.
<img width="1853" height="928" alt="Screenshot 2026-06-21 000247" src="https://github.com/user-attachments/assets/37aeeef5-d672-406d-9196-a66df7511a6b" />


---

## Task 5 — Pipeline Execution

### How the pipeline was run

The pipeline was first tested using **Debug** mode in ADF — Debug runs the pipeline immediately without needing a trigger, using the current published configuration. This is ideal for testing during development.

After successful debug, a **Schedule Trigger** named `Trigger_for_copy` was created and published to run the pipeline automatically.

### Trigger Details

| Property | Value |
|---|---|
| Trigger Name | `Trigger_for_copy` |
| Type | Schedule |


**Overall Pipeline Status: Succeeded**

### Execution flow explanation
1. **Get Metadata :** Scanned `superstore-dataset` container — retrieved list of all files
2. **For_Each_Dataset :** Started looping over each file in the list
3. **File_Name_Check — 1st run (<1s):** Checked a file — name did NOT start with "superstore" → condition FALSE → skipped instantly (less than 1 second = no copy happened)
4. **File_Name_Check — 2nd run (20s):** Checked next file — name DID start with "superstore" → condition TRUE → triggered Copy Data
5. **Copy data :** Successfully copied the superstore CSV file to `destination-superstore-dataset` container


**Key observation:** The two File_Name_Check runs confirm that the container had at least 2 files one non-superstore file (skipped instantly) and one superstore file (copied successfully). The filtering logic worked exactly as designed.

**Screenshot reference:** ADF Monitor Output tab showing all 5 activities with Succeeded status, run times, and durations. Pipeline canvas showing the full design.
<img width="1857" height="927" alt="Screenshot 2026-06-21 002137" src="https://github.com/user-attachments/assets/353f0d94-9517-4b2d-87f2-b6bcf1395a10" />


---

## Task 6 — IAM Roles

### What is IAM in Azure?

IAM (Identity and Access Management) is Azure's system for controlling who can access what resources and what actions they can perform. Azure uses RBAC (Role-Based Access Control) you assign roles to users, groups, or service principals.

### Key roles in Azure

| Role | What it can do |
|---|---|
| **Owner** | Full control — read, write, delete, manage access |
| **Contributor** | Read + write + delete resources, but CANNOT manage access |
| **Reader** | Read-only  can view resources but cannot make changes |
| **Role Based Access Control Administrator** | Can manage role assignments for others |
| **Storage Blob Data Reader** | Can only read blob data (not manage the storage account) |
| **Storage Blob Data Contributor** | Can read + write + delete blobs |

### Role assignments configured(Contributor with manage access)

On `resource-group-celebal`, the following roles were assigned to **Swadesh Singh**:

| Role | Scope | Purpose |
|---|---|---|
| **Owner (x2)** | Subscription (Inherited) | Full control inherited from subscription level |
| **Reader** | This resource (Resource Group) | Read-only view at resource group level |
| **Role Based Access Control Administrator** | This resource (Resource Group) | Ability to assign roles to others |


### Why does ADF need access to Storage?

ADF runs as a service principal (service identity) in Azure. For ADF to read from and write to Blob Storage, it must be granted the appropriate role on the storage account:
In this assignment, the Linked Service (`linked_service_superstore`) uses the storage account key for authentication which gives full access. In production, Managed Identity is preferred over account keys, as it eliminates the need to store credentials and follows the principle of least privilege.

### Principle of Least Privilege

A core security concept: give only the minimum permissions required for the task. 

- If ADF only needs to read from source → give `Storage Blob Data Reader`, not `Contributor`
- If a junior team member only needs to view pipelines → give `Reader`, not `Owner`

**Screenshot reference:** `resource-group-celebal | Access control (IAM)` page showing 4 role assignments — Owner (x2), Reader, and Role Based Access Control Administrator all assigned to Swadesh Singh.
<img width="1632" height="927" alt="qraJwzQsHN" src="https://github.com/user-attachments/assets/9e6a03c7-853e-4bf3-be6e-8ba22fd5d71f" />


---

## Mini Project — Complete Pipeline: CSV → Blob → ADF

### Problem Statement

Build a complete, intelligent pipeline that reads CSV files from Azure Blob Storage, validates each file by name, and copies only the relevant files to a destination container using Azure Data Factory.

### Solution Design

The mini project directly extends the tasks above into a complete end-to-end working solution.

**Source:** `superstore-dataset` container (in `celebal` storage account) — contains more than one CSV files  
**Destination:** `destination-superstore-dataset` container — receives only files whose names start with "superstore"  
**Tool:** Azure Data Factory (`data-factory-week-04`)

### Complete Pipeline Architecture

```
SOURCE                    ADF PIPELINE (Get_Metadata)                    DESTINATION
──────                    ─────────────────────────────                  ───────────
celebal storage           Step 1: Get Metadata                           celebal storage
superstore-dataset   →    Scans container, gets file list    
  - movies.csv   
  - superstore.csv        Step 2: ForEach                     
                          Loops over each file in list
                          
                          Step 3: If Condition (File_Name_Check)
                          @startsWith(item().name, 'superstore')
                          
                          TRUE  → Step 4: Copy Data                →    destination-superstore-dataset
                          FALSE → Skip (do nothing)                        - movies.csv (skipped)
                                                                           - superstore_jan.csv (Copyed)
                                                                          
```

The pipeline ran end-to-end successfully in approximately 73 seconds, with all 5 activities showing Succeeded status in the ADF Monitor.


### Why this design is better than a simple Copy All

A naive pipeline would simply copy ALL files from source to destination. This design is better because:

1. **Selective copy** — only relevant files are processed, saving time and compute cost
2. **Dynamic** — ForEach handles any number of files without pipeline changes
3. **Scalable** — if 100 new files are added, the pipeline handles all automatically
4. **Maintainable** — the filter condition (`startsWith`) can be easily changed to match different naming patterns
5. **Production-ready pattern** — Get Metadata + ForEach + If Condition is a standard ADF design pattern used in real enterprise pipelines

---
