import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../database/deliverable_repository.dart';
import '../models/deliverable_submission.dart';

/// Service coordinating real-time encrypted deliverable sync and FCM push notifications via Firebase.
class FirebaseSyncService {
  final FirebaseFirestore? _injectedFirestore;
  final FirebaseMessaging? _injectedMessaging;
  final DeliverableRepository? deliverableRepository;

  final Map<String, StreamSubscription> _contractSubscriptions = {};
  StreamSubscription? _userNotificationsSubscription;
  String? _registeredFcmToken;

  FirebaseSyncService({
    FirebaseFirestore? firestore,
    FirebaseMessaging? messaging,
    this.deliverableRepository,
  })  : _injectedFirestore = firestore,
        _injectedMessaging = messaging;

  FirebaseFirestore? get firestore {
    if (_injectedFirestore != null) return _injectedFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('[FirebaseSyncService] Firestore not initialized: $e');
      return null;
    }
  }

  FirebaseMessaging? get messaging {
    if (_injectedMessaging != null) return _injectedMessaging;
    try {
      return FirebaseMessaging.instance;
    } catch (e) {
      debugPrint('[FirebaseSyncService] Messaging not initialized: $e');
      return null;
    }
  }

  /// Cached active FCM token for this device.
  String? get fcmToken => _registeredFcmToken;

  /// Initialize FCM push notifications, request permissions, and register token.
  Future<String?> initializeFcm({
    String? walletAddress,
    void Function(RemoteMessage message)? onForegroundMessage,
  }) async {
    final msg = messaging;
    if (msg == null) return null;

    try {
      final settings = await msg.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

      // Enable foreground heads-up notifications
      await msg.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      final token = await msg.getToken();
      _registeredFcmToken = token;
      debugPrint('[FCM] Target Token for this device: $token');

      if (token != null && walletAddress != null) {
        await saveDeviceToken(walletAddress, token);
      }

      // Listen for token refreshes
      msg.onTokenRefresh.listen((newToken) async {
        _registeredFcmToken = newToken;
        if (walletAddress != null) {
          await saveDeviceToken(walletAddress, newToken);
        }
      });

      // Foreground message listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM Foreground] Received: ${message.notification?.title} - ${message.notification?.body}');
        if (onForegroundMessage != null) {
          onForegroundMessage(message);
        }
      });

      // Background notification tap listener
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[FCM OpenedApp] User tapped notification: ${message.data}');
      });

      return token;
    } catch (e) {
      debugPrint('[FCM] Failed to initialize FCM: $e');
      return null;
    }
  }

  /// Associate device FCM token with a user's Solana wallet address in Firestore.
  Future<void> saveDeviceToken(String walletAddress, String token) async {
    final fs = firestore;
    if (fs == null) return;

    try {
      await fs.collection('users').doc(walletAddress).set({
        'fcmToken': token,
        'walletAddress': walletAddress,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('[FCM] Token saved for wallet $walletAddress');
    } catch (e) {
      debugPrint('[FCM] Error saving token to Firestore: $e');
    }
  }

  /// Register/publish user's X25519 public key to /users/{walletAddress} in Firestore.
  /// This enables employers and workers to encrypt keys for each other (zero-knowledge envelopes).
  Future<void> registerUserPublicKey(String walletAddress, String publicKey) async {
    final fs = firestore;
    if (fs == null) return;

    try {
      await fs.collection('users').doc(walletAddress).set({
        'x25519PublicKey': publicKey,
        'walletAddress': walletAddress,
        'keyUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('[Firestore] Registered X25519 public key for wallet $walletAddress');
    } catch (e) {
      debugPrint('[Firestore] Error registering X25519 public key: $e');
    }
  }

  /// Retrieve another user's (e.g. employer's) X25519 public key from Firestore.
  Future<String?> getUserPublicKey(String walletAddress) async {
    final fs = firestore;
    if (fs == null) return null;

    try {
      final doc = await fs.collection('users').doc(walletAddress).get();
      if (doc.exists) {
        final data = doc.data();
        final pubKey = data?['x25519PublicKey'] as String?;
        if (pubKey != null && pubKey.isNotEmpty) {
          debugPrint('[Firestore] Retrieved X25519 public key for $walletAddress');
          return pubKey;
        }
      }
      debugPrint('[Firestore] No X25519 public key found for $walletAddress');
      return null;
    } catch (e) {
      debugPrint('[Firestore] Error fetching X25519 public key for $walletAddress: $e');
      return null;
    }
  }

  /// Subscribe device to real-time events for a specific contract.
  Future<void> subscribeToContract(String contractId) async {
    final msg = messaging;
    if (msg != null) {
      try {
        await msg.subscribeToTopic('contract_$contractId');
        debugPrint('[FCM] Subscribed to topic: contract_$contractId');
      } catch (e) {
        debugPrint('[FCM] Topic subscription error: $e');
      }
    }

    // Start real-time Firestore synchronization for this contract
    listenToContractDeliverables(contractId);
  }

  /// Unsubscribe device from a contract's push topic.
  Future<void> unsubscribeFromContract(String contractId) async {
    final msg = messaging;
    if (msg != null) {
      try {
        await msg.unsubscribeFromTopic('contract_$contractId');
        debugPrint('[FCM] Unsubscribed from topic: contract_$contractId');
      } catch (e) {
        debugPrint('[FCM] Topic unsubscription error: $e');
      }
    }
    stopListeningToContract(contractId);
  }

  /// Publish an encrypted deliverable submission to Firestore for the employer to sync.
  Future<void> publishDeliverableSubmission(
    DeliverableSubmission submission, {
    String? employerAddress,
  }) async {
    final fs = firestore;
    if (fs == null) return;

    try {
      final docId = submission.id?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString();

      await fs
          .collection('contracts')
          .doc(submission.contractId)
          .collection('deliverables')
          .doc(docId)
          .set({
        'contractId': submission.contractId,
        'submitterAddress': submission.submitterAddress,
        'encryptedPayload': submission.encryptedPayload,
        'iv': submission.iv,
        'authTag': submission.authTag,
        'plaintextHash': submission.plaintextHash,
        'completionNote': submission.completionNote,
        'arweaveTxId': submission.arweaveTxId,
        'wrappedKey': submission.wrappedKey,
        'status': submission.status.name,
        'submittedAt': submission.submittedAt.toIso8601String(),
        'syncedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[Firestore] Published deliverable for contract #${submission.contractId}');

      // Post notification to employer's inbox
      if (employerAddress != null) {
        await fs.collection('users').doc(employerAddress).collection('notifications').add({
          'type': 'deliverable_submitted',
          'contractId': submission.contractId,
          'title': 'Deliverables Ready for Review',
          'body': 'Worker submitted deliverables for Contract #${submission.contractId}. Tap to inspect.',
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });
        debugPrint('[Firestore] Posted notification for employer $employerAddress');
      }
    } catch (e) {
      debugPrint('[Firestore] Error publishing deliverable: $e');
    }
  }

  /// Update deliverable status in Firestore (e.g. reviewed or revisionRequested).
  Future<void> updateDeliverableStatus(
    String contractId,
    DeliverableStatus status, {
    int? submissionId,
    String? workerAddress,
  }) async {
    final fs = firestore;
    if (fs == null) return;

    try {
      final collection = fs
          .collection('contracts')
          .doc(contractId)
          .collection('deliverables');

      if (submissionId != null) {
        await collection.doc(submissionId.toString()).update({
          'status': status.name,
          'statusUpdatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final snapshot = await collection.get();
        for (final doc in snapshot.docs) {
          await doc.reference.update({
            'status': status.name,
            'statusUpdatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      debugPrint('[Firestore] Updated deliverable status to ${status.name}');

      // Notify worker of the employer's decision
      if (workerAddress != null) {
        final isReviewed = status == DeliverableStatus.reviewed;
        await fs.collection('users').doc(workerAddress).collection('notifications').add({
          'type': isReviewed ? 'payment_released' : 'revision_requested',
          'contractId': contractId,
          'title': isReviewed ? 'Payment Released!' : 'Revision Requested',
          'body': isReviewed
              ? 'Employer approved work and released escrow funds for Contract #$contractId!'
              : 'Employer requested changes for Contract #$contractId.',
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });
        debugPrint('[Firestore] Posted status notification for worker $workerAddress');
      }
    } catch (e) {
      debugPrint('[Firestore] Error updating deliverable status: $e');
    }
  }

  /// Listen for real-time deliverable submissions for a contract and hydrate into local Drift DB.
  void listenToContractDeliverables(String contractId) {
    if (_contractSubscriptions.containsKey(contractId)) return;

    final fs = firestore;
    if (fs == null) return;

    final sub = fs
        .collection('contracts')
        .doc(contractId)
        .collection('deliverables')
        .snapshots()
        .listen((snapshot) async {
      for (final doc in snapshot.docs) {
        final data = doc.data();
        try {
          if (deliverableRepository != null) {
            await deliverableRepository!.saveReceivedSubmission(
              contractId: data['contractId'] as String? ?? contractId,
              submitterAddress: data['submitterAddress'] as String? ?? 'unknown',
              encryptedPayload: data['encryptedPayload'] as String,
              iv: data['iv'] as String,
              plaintextHash: data['plaintextHash'] as String,
              authTag: data['authTag'] as String? ?? '',
              arweaveTxId: data['arweaveTxId'] as String?,
              completionNote: data['completionNote'] as String?,
              wrappedKey: data['wrappedKey'] as String?,
            );
          }
        } catch (e) {
          debugPrint('[Firestore] Error saving synced deliverable into Drift: $e');
        }
      }
    }, onError: (error) {
      debugPrint('[Firestore] Deliverable stream error for contract #$contractId: $error');
    });

    _contractSubscriptions[contractId] = sub;
  }

  /// Stop listening to real-time events for a specific contract.
  void stopListeningToContract(String contractId) {
    _contractSubscriptions[contractId]?.cancel();
    _contractSubscriptions.remove(contractId);
  }

  /// Listen to real-time notification events in user's inbox.
  void listenToUserNotifications(
    String walletAddress,
    void Function(Map<String, dynamic> notification) onNotification,
  ) {
    _userNotificationsSubscription?.cancel();
    final fs = firestore;
    if (fs == null) return;

    _userNotificationsSubscription = fs
        .collection('users')
        .doc(walletAddress)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      for (final doc in snapshot.docChanges) {
        if (doc.type == DocumentChangeType.added) {
          final data = doc.doc.data();
          if (data != null) {
            onNotification({'id': doc.doc.id, ...data});
          }
        }
      }
    });
  }

  /// Dispose all active subscriptions.
  void dispose() {
    for (final sub in _contractSubscriptions.values) {
      sub.cancel();
    }
    _contractSubscriptions.clear();
    _userNotificationsSubscription?.cancel();
  }
}
