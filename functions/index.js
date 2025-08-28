const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Cloud Function to handle class progression (increase class numbers and remove class 9)
exports.progressClasses = functions.https.onCall(async (data, context) => {
    try {
        console.log('Starting class progression...');
        
        const db = admin.firestore();
        
        // Step 1: Get all students with classNumber 9 and delete them
        console.log('Deleting students in class 9...');
        const class9Query = await db.collection('users')
            .where('classNumber', '==', 9)
            .where('role', '==', 'student')
            .get();
        
        const deletePromises = [];
        class9Query.forEach(doc => {
            deletePromises.push(doc.ref.delete());
        });
        
        await Promise.all(deletePromises);
        console.log(`Deleted ${class9Query.size} students from class 9`);
        
        // Step 2: Get all remaining students (classes 1-8) and increment their class numbers
        console.log('Incrementing class numbers for remaining students...');
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
                batch.update(doc.ref, { classNumber: currentClass + 1 });
                updateCount++;
            }
        });
        
        await batch.commit();
        console.log(`Updated class numbers for ${updateCount} students`);
        
        return {
            success: true,
            deletedStudents: class9Query.size,
            updatedStudents: updateCount,
            message: `Successfully progressed classes: Deleted ${class9Query.size} graduating students, promoted ${updateCount} students to next grade`
        };
        
    } catch (error) {
        console.error('Error during class progression:', error);
        throw new functions.https.HttpsError('internal', 'Class progression failed', error);
    }
});

exports.setUserRole = functions.firestore
    .document('users/{userId}')
    .onCreate(async (snap, context) => {
        const userData = snap.data();
        const teacherEmails = [
            'adam@algebraskolan.se',
            'abdullah@algebraskolan.se',
            'ahmed@algebraskolan.se',
            'airoll@algebraskolan.se',
            'admin@algebraskolan.se',
            'amani@algebraskolan.se',
            'amina@algebraskolan.se',
            'anas.s@algebraskolan.se',
            'anneli@algebraskolan.se',
            'kurator@algebraskolan.se',
            'avin@algebraskolan.se',
            'bouran@algebraskolan.se',
            'christine@algebraskolan.se',
            'dima@algebraskolan.se',
            'gulzada@algebraskolan.se',
            'hala@algebraskolan.se',
            'hayal@algebraskolan.se',
            'rektor@algebraskolan.se',
            'john@algebraskolan.se',
            'lina.a@algebraskolan.se',
            'lina@algebraskolan.se',
            'magdalena@algebraskolan.se',
            'mahmood.alosh@algebraskolan.se',
            'mahmoud@algebraskolan.se',
            'memnuna@algebraskolan.se',
            'moaminat@algebraskolan.se',
            'nadia@algebraskolan.se',
            'nancy@algebraskolan.se',
            'skolskoterska@algebraskolan.se',
            'naser@algebraskolan.se',
            'niyan@algebraskolan.se',
            'specialpedagog@algebraskolan.se',
            'petter@algebraskolan.se',
            'rana@algebraskolan.se',
            'safa@algebraskolan.se',
            'sahr@algebraskolan.se',
            'sainab@algebraskolan.se',
            'sofia@algebraskolan.se',
            'surra@algebraskolan.se',
            'yamila@algebraskolan.se',
            'syv@algebraskolan.se',
            // Add more teacher emails as needed
        ];

        if (teacherEmails.includes(userData.email.toLowerCase())) {
            try {
                await snap.ref.update({ role: 'teacher' });
                console.log(`Role 'teacher' assigned to user with email: ${userData.email}`);
            } catch (error) {
                console.error('Error updating user role:', error);
            }
        } else {
            console.log(`User with email: ${userData.email} is not a teacher.`);
        }
    });
