# Firestore Indexes Required for Fritids Feature

This document lists all the Firestore composite indexes required for the Fritids Pass Registration feature.

## Collection: `fritidsPassRegistrations`

### Index 1: Query registrations by date and filters
**Fields:**
1. `date` (Ascending)
2. `group` (Ascending)
3. `passType` (Ascending)
4. `isReverted` (Ascending)
5. `timestamp` (Descending)

**Usage:** Used in history view to filter registrations by date range, group, and pass type while sorting by timestamp.

### Index 2: Query by student
**Fields:**
1. `studentId` (Ascending)
2. `date` (Ascending)
3. `isReverted` (Ascending)

**Usage:** Used to get a student's registration history.

### Index 3: Check for duplicates
**Fields:**
1. `studentId` (Ascending)
2. `group` (Ascending)
3. `passType` (Ascending)
4. `date` (Ascending)
5. `isReverted` (Ascending)

**Usage:** Used to check if a student has already registered for a specific pass on a specific date.

### Index 4: Get registrations by staff (for undo functionality)
**Fields:**
1. `staffId` (Ascending)
2. `isReverted` (Ascending)
3. `timestamp` (Descending)

**Usage:** Used to find the last registration made by a staff member for potential reverting.

## How to Create Indexes

### Option 1: Via Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to Firestore Database > Indexes
4. Click "Create Index"
5. Select collection: `fritidsPassRegistrations`
6. Add fields as specified above
7. Click "Create Index"

### Option 2: Via Error Links
When you run a query that requires an index, Firestore will throw an error with a direct link to create the index. Click the link and Firebase will automatically configure the correct index.

### Option 3: Via firestore.indexes.json
Add the following to your `firestore.indexes.json` file:

```json
{
  "indexes": [
    {
      "collectionGroup": "fritidsPassRegistrations",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "date", "order": "ASCENDING" },
        { "fieldPath": "group", "order": "ASCENDING" },
        { "fieldPath": "passType", "order": "ASCENDING" },
        { "fieldPath": "isReverted", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "fritidsPassRegistrations",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "studentId", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "ASCENDING" },
        { "fieldPath": "isReverted", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "fritidsPassRegistrations",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "studentId", "order": "ASCENDING" },
        { "fieldPath": "group", "order": "ASCENDING" },
        { "fieldPath": "passType", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "ASCENDING" },
        { "fieldPath": "isReverted", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "fritidsPassRegistrations",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "staffId", "order": "ASCENDING" },
        { "fieldPath": "isReverted", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    }
  ]
}
```

Then deploy with:
```bash
firebase deploy --only firestore:indexes
```

## Note
Indexes can take several minutes to build after creation. The Firebase Console will show the status of each index (Building/Enabled).
