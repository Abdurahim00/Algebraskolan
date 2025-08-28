const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
// For this script to work, you need to either:
// 1. Set GOOGLE_APPLICATION_CREDENTIALS environment variable to your service account key file
// 2. Or replace this with admin.initializeApp({ credential: admin.credential.cert(serviceAccount) })
//    where serviceAccount is your service account key JSON

try {
    admin.initializeApp({
        projectId: 'algebra-82c5d'
    });
} catch (error) {
    console.error('❌ Failed to initialize Firebase Admin SDK');
    console.error('Make sure you have proper authentication set up.');
    console.error('You can download a service account key from Firebase Console > Project Settings > Service Accounts');
    process.exit(1);
}

const db = admin.firestore();

async function progressClasses() {
    try {
        console.log('Starting class progression...');
        
        // Step 1: Get all students with classNumber 9 and delete them
        console.log('Fetching students in class 9...');
        const class9Query = await db.collection('users')
            .where('classNumber', '==', 9)
            .where('role', '==', 'student')
            .get();
        
        console.log(`Found ${class9Query.size} students in class 9 to delete`);
        
        // Delete students in class 9
        const deletePromises = [];
        class9Query.forEach(doc => {
            console.log(`Deleting student: ${doc.data().displayName} (${doc.id})`);
            deletePromises.push(doc.ref.delete());
        });
        
        await Promise.all(deletePromises);
        console.log(`✅ Successfully deleted ${class9Query.size} graduating students from class 9`);
        
        // Step 2: Get all remaining students (classes 1-8) and increment their class numbers
        console.log('\nFetching remaining students to promote...');
        const studentsQuery = await db.collection('users')
            .where('role', '==', 'student')
            .get();
        
        const batch = db.batch();
        let updateCount = 0;
        
        studentsQuery.forEach(doc => {
            const studentData = doc.data();
            const currentClass = studentData.classNumber;
            
            // Only update if classNumber is between 1-8
            if (currentClass >= 1 && currentClass <= 8) {
                console.log(`Promoting ${studentData.displayName} from class ${currentClass} to class ${currentClass + 1}`);
                batch.update(doc.ref, { classNumber: currentClass + 1 });
                updateCount++;
            }
        });
        
        await batch.commit();
        console.log(`✅ Successfully promoted ${updateCount} students to the next grade`);
        
        console.log('\n🎉 Class progression completed successfully!');
        console.log(`Summary:`);
        console.log(`- Deleted ${class9Query.size} graduating students (former class 9)`);
        console.log(`- Promoted ${updateCount} students to next grade`);
        
        return {
            success: true,
            deletedStudents: class9Query.size,
            updatedStudents: updateCount,
            message: `Successfully progressed classes: Deleted ${class9Query.size} graduating students, promoted ${updateCount} students to next grade`
        };
        
    } catch (error) {
        console.error('❌ Error during class progression:', error);
        throw error;
    }
}

// Run the script
progressClasses()
    .then(result => {
        console.log('\n✅ Script completed successfully:', result);
        process.exit(0);
    })
    .catch(error => {
        console.error('\n❌ Script failed:', error);
        process.exit(1);
    });