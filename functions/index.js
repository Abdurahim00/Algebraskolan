const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

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
