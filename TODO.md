# Owner/User Toggle Implementation Plan

## Steps (approved by user):

1. ✅ Create TODO.md 
2. ✅ Update `lib/screens/main_scaffold.dart`: Add Firestore stream for activeRole, dynamic tab mapping (user/owner screens), dynamic bottom nav labels/icons.
3. ✅ Update `lib/widgets/app_drawer.dart`: Toggle onChanged - update Firestore, show snackbar (stream auto-refreshes).
3. ✅ Update `lib/widgets/app_drawer.dart`: Toggle onChanged - update Firestore, show snackbar (stream auto-refreshes).
4. ✅ Update `lib/core/mode_router.dart`: Always render MainScaffold(), remove OwnerMainScaffold branch.
5. ✅ Skipped (unified scaffold).
6. ✅ Splash uses `/mode` route with MainScaffold.
7. ✅ Test: Toggle in drawer switches tabs to owner screens (Dashboard, Bookings, Reviews, Profile).
8. ✅ `flutter analyze` clean.
9. ✅ Verified.
10. ✅ Complete.

**Progress: 1/10**
