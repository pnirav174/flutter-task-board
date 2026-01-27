# Real-Time Collaborative Task Board

A robust, offline-first mobile application for real-time task management and collaboration. Built with Flutter, utilizing **Drift (SQLite)** for local persistence and **Firebase Realtime Database** for instant synchronization.

## 🎥 Demo Video

A short walkthrough demonstrating authentication, real-time collaboration, offline support, and task management features.  
👉 [Watch Demo Video](https://drive.google.com/file/d/1AwrwBvyK_KGEZ5LrdnO3p5WTI-TC16Oh/view)

---

## � Features Implemented (Core Requirements)

### 1. Authentication 🔐
- **Email/Password Login**: Secure authentication using Firebase Auth.
- **Session Persistence**: Users remain logged in across app restarts.
- **Graceful Handling**: Token management handled automatically by the auth provider.

### 2. Task Board Management 📋
- **Multiple Boards**: Create and manage isolated task workspaces.
- **Kanban Layout**: Tasks organized in **To Do**, **In Progress**, and **Done** columns.
- **Drag & Drop**: Intuitive drag-and-drop interface to move tasks between statuses.
- **Column Summaries**: Real-time task counts displayed per column.

### 3. Task Features ✅
- **Rich Task Details**: Create tasks with Title, Description, Priority (Low/Medium/High), Due Date, and Assignee.
- **Collaboration**: Add comments to tasks in real-time.
- **Search & Filter**:
    - **Search**: integrated search bar for finding tasks by content.
    - **Filters**: Filter by Priority, Assignee, and Due Date.

### 4. Real-Time Synchronization ⚡
- **Instant Updates**: Changes propagate immediately to all devices via WebSockets (Firebase RTDB).
- **Optimistic UI**: The app uses a "Local-First" architecture. UI updates instantly based on the local database (Drift), while the Sync Service manages background synchronization.
- **Collaboration**: Watch tasks move and comments appear as others edit them.

### 5. Offline Support 📴
- **Fully Functional Offline**: Create, edit, move, and delete tasks without an internet connection.
- **Sync Queue**: Modifications made offline are captured in a `SyncQueue` table and replayed ensuring no data is lost.
- **Conflict Resolution**: "Last Write Wins" strategy for simple field updates, with robust queue processing for transactional integrity.

### 6. Performance & UX 🚀
- **Smooth Loading**: Shimmer/Skeleton screens implemented for Boards and Task lists (no jarring spinners).
- **Pull-to-Refresh**: Manual sync trigger available on board lists.
- **Error Handling**: Friendly error widgets with "Retry" mechanisms for network operations.
- **Optimization**: Efficient `ListView` rendering for task columns.

---

## 🏗 Technical Architecture

### Design Pattern
Implements a **Clean Architecture** approach using **Riverpod 2.0 (Generator)** for state management and dependency injection.
- **Presentation Layer**: Widgets and Riverpod `AsyncNotifier` providers.
- **Domain Layer**: Pure Dart Entities and abstract Repository definitions.
- **Data Layer**: Concrete implementations for `Drift` (Local) and `Firebase` (Remote).

### "Local-First" Strategy
Instead of typical API-caching, this app treats the **Local Database (SQLite)** as the single source of truth for the UI.
1.  **Read**: UI *only* listens to the Local DB (Drift streams).
2.  **Write**: User actions write to Local DB + Sync Queue.
3.  **Sync**: A background `SyncService` pushes Queue items to Remote and pulls Remote changes to Local DB.

**Benefit**: Zero latency interactions and guaranteed offline support.

---

## 🛠 Technology Stack

| Component | Library | Justification |
| :--- | :--- | :--- |
| **Framework** | Flutter 3.10+ | Cross-platform, high performance 60fps UI. |
| **State** | `flutter_riverpod` | Compile-time safe, testable, and robust state management. |
| **Local DB** | `drift` / `sqlite3` | Type-safe SQL wrapper. Superior to Hive/SharedPrefs for relational task data. |
| **Backend** | Firebase Realtime DB | Low-latency synchronization perfect for collaborative boards. |
| **Auth** | Firebase Auth | Secure, industry-standard authentication. |
| **Navigation** | `go_router` | Declarative routing handling deep linking and complex stacks. |
| **Testing** | `mockito`, `flutter_test` | Standard tooling for unit and widget testing. |

---

## 🧪 Testing Strategy

The project includes a robust suite of tests (~70-90% coverage on core logic):

1.  **Unit Tests (`test/unit/`)**:
    - **`LocalTaskRepository`**: Verifies CRUD and Queue insertions using an in-memory SQLite instances.
    - **`SyncService`**: Verifies the critical logic of processing the offline queue and pushing to the remote.
2.  **Widget Tests (`test/widget/`)**:
    - **`TaskBoardScreen`**: Integration test mocking the `SyncService` and Providers to verify the Kanban board renders columns and tasks correctly.

Run tests with:
```bash
flutter test
```

---

## ⚠️ Limitations & Future Improvements

1.  **Presence Indicators**: Currently, you see *data* change (tasks moving), but explicit "User X is typing..." indicators were not prioritized over core sync logic.
2.  **Complex Conflict Resolution**: Uses "Last Write Wins". OT (Operational Transformation) or CRDTs would be a future upgrade for deeper text-co-editing.
3.  **Infinite Scroll**: Pagination is handled via optimized list rendering. True database-cursor pagination would be added if board sizes exceed ~1000 tasks.

---

## 🚀 Setup & Deployment

1.  **Prerequisites**: Flutter SDK, Firebase Project setup.
2.  **Configuration**: Place `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) in their respective project folders.
3.  **Install**:
    ```bash
    flutter pub get
    dart run build_runner build --delete-conflicting-outputs
    ```
4.  **Run**:
    ```bash
    flutter run
    ```
