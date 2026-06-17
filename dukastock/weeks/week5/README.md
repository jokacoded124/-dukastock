\# Week 5 — Networking: Connectivity \& Error Handling



This folder contains copies of the code and documentation produced during Week 5 of the DukaStock project, kept here for easy reference and grading alongside the main `lib/` source tree.



\## What was built



\- \*\*connectivity\_service.dart\*\* — wraps the `connectivity\_plus` package, exposing a real-time online/offline stream (`onStatusChange`) and a one-off check (`isOnline`) used before network-dependent actions.

\- \*\*offline\_banner.dart\*\* — a reusable widget that automatically shows a red "No internet connection" bar at the top of any screen when connectivity drops, and hides itself when connection is restored.

\- \*\*dashboard\_screen.dart\*\* — updated to include the `OfflineBanner` so connectivity status is visible immediately after login.

\- \*\*add\_product\_screen.dart\*\* — updated to check connectivity before attempting a Firestore write, and to handle `FirebaseException` separately from generic errors so the user gets a clear, specific message instead of a raw exception or a silent failure.



\## Testing



All of the above was tested on a real Redmi Note 14 device by toggling Airplane Mode:

\- The offline banner correctly appears on the Dashboard when connection is lost, and disappears automatically when restored.

\- Attempting to save a product while offline shows "No internet connection. Please reconnect and try again." instead of crashing or hanging.



Screenshots of both tests are included in the project logbook (`BIT4107\_DukaStock\_Complete\_Logbook\_Eugene\_Ndungu.docx`, Week 5 section).



\## Files in this folder



\- `connectivity\_service.dart`

\- `offline\_banner.dart`

\- `dashboard\_screen.dart`

\- `add\_product\_screen.dart`

\- `BIT4107\_DukaStock\_Complete\_Logbook\_Eugene\_Ndungu.docx` — full project logbook, including the Week 5 entry with code excerpts, screenshots, and reflection.



The live, working versions of these files remain in their normal locations under `lib/services/`, `lib/widgets/`, and `lib/screens/` — this folder is a documentation snapshot, not the build source.



\## Branch



This work lives on the `week5-networking` branch.

