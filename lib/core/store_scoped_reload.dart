import 'business_store.dart';
import 'community_messages_store.dart';
import 'faq_store.dart';
import 'manager_store.dart';
import 'reviews_store.dart';

/// Reloads slug-scoped local stores after the linked business changes.
Future<void> reloadStoreScopedData() async {
  final slug = ManagerStore.instance.linkedBusinessSlug;
  await Future.wait([
    BusinessStore.instance.loadForCurrentStore(slug),
    ReviewsStore.instance.loadForCurrentStore(slug),
    FaqStore.instance.loadForCurrentStore(slug),
    CommunityMessagesStore.instance.loadForCurrentStore(slug),
  ]);
}
