# 🏫 Class Progression Script

This script automates the yearly class progression process by:
- ❌ **Deleting all students in class 9** (graduating students)
- ⬆️ **Promoting all other students** to the next grade (class number + 1)

## 🚨 IMPORTANT WARNING

**This action is IRREVERSIBLE!** Make sure you have a backup of your Firebase database before running this script.

## 📋 Available Options

### Option 1: Web Interface (Recommended)
The easiest way to run the script:

1. Open `class_progression.html` in a web browser
2. Click "Preview Changes" to see what will happen
3. If everything looks correct, click "Execute Class Progression"

### Option 2: Node.js Script
For command-line execution:

1. Install dependencies:
   ```bash
   npm install firebase-admin
   ```

2. Set up authentication (choose one):
   - **Option A:** Download service account key from Firebase Console and set environment variable:
     ```bash
     set GOOGLE_APPLICATION_CREDENTIALS=path\to\your\serviceAccountKey.json
     ```
   - **Option B:** Edit the script to include your service account key directly

3. Run the script:
   ```bash
   node class_progression_script.js
   ```

### Option 3: Firebase Cloud Function
If you have Firebase CLI installed:

1. Deploy the function:
   ```bash
   firebase deploy --only functions
   ```

2. Call the function from your Firebase console or using the Firebase CLI:
   ```bash
   firebase functions:call progressClasses
   ```

## 📊 What the Script Does

### Before Running:
- Class 1 students → Class 2
- Class 2 students → Class 3
- Class 3 students → Class 4
- Class 4 students → Class 5
- Class 5 students → Class 6
- Class 6 students → Class 7
- Class 7 students → Class 8
- Class 8 students → Class 9
- Class 9 students → **DELETED** (graduated)

### Data Structure
The script operates on the `users` collection in Firestore, looking for documents with:
- `role`: "student"
- `classNumber`: Integer from 1-9

## 🔍 Testing
Always use the "Preview Changes" feature first to see exactly which students will be affected before executing the actual progression.

## 🆘 Need Help?
If you encounter any issues:
1. Check the browser console for error messages
2. Verify your Firebase project permissions
3. Ensure you're connected to the internet
4. Make sure the Firebase project `algebra-82c5d` is accessible