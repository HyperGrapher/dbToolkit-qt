pragma ComponentBehavior: Bound
pragma Singleton
import QtQuick

QtObject {
    // Fictional display fixtures only. No connection details are persisted or used.
    readonly property var services: [
        {
            name: "PostgreSQL",
            version: "17.6",
            port: "5432",
            running: true,
            color: "#82aaff",
            databases: 5
        },
        {
            name: "MySQL",
            version: "8.4",
            port: "3306",
            running: true,
            color: "#e4bb78",
            databases: 3
        },
        {
            name: "MariaDB",
            version: "11.4",
            port: "3307",
            running: false,
            color: "#ba9cf1",
            databases: 2
        }
    ]
    readonly property var databases: [
        {
            name: "atlas_dev",
            description: "The next thing you're building.",
            size: "124.8 MB",
            tables: 12,
            owner: "atlas_app",
            managed: true,
            color: "#82aaff",
            letter: "A",
            note: "Local development environment for Atlas. Seed data is safe to reset.",
            updated: "2 minutes ago"
        },
        {
            name: "storefront",
            description: "Commerce, without the complexity.",
            size: "86.2 MB",
            tables: 18,
            owner: "storefront_app",
            managed: true,
            color: "#70d6ab",
            letter: "S",
            note: "Product catalog and checkout development.",
            updated: "18 minutes ago"
        },
        {
            name: "analytics_local",
            description: "A place for the bigger picture.",
            size: "256.4 MB",
            tables: 8,
            owner: "analytics_app",
            managed: true,
            color: "#ba9cf1",
            letter: "a",
            note: "Anonymized events for local reporting.",
            updated: "1 hour ago"
        },
        {
            name: "playground",
            description: "Room to try something new.",
            size: "8.1 MB",
            tables: 4,
            owner: "postgres",
            managed: false,
            color: "#e4bb78",
            letter: "P",
            note: "Experiments and quick prototypes.",
            updated: "Yesterday"
        },
        {
            name: "postgres",
            description: "Default maintenance database",
            size: "7.4 MB",
            tables: 0,
            owner: "postgres",
            managed: false,
            color: "#929dad",
            letter: "p",
            note: "Server maintenance database.",
            updated: "Yesterday"
        }
    ]
    readonly property var tableNames: ["users", "projects", "workspaces", "memberships", "invitations", "sessions", "activity_log", "notifications", "preferences", "api_keys", "attachments", "migrations"]
    readonly property var rows: [
        {
            id: "1",
            name: "Alex Morgan",
            email: "alex@example.test",
            role: "admin",
            status: "active",
            created: "2026-09-08 09:41"
        },
        {
            id: "2",
            name: "Jamie Chen",
            email: "jamie@example.test",
            role: "member",
            status: "active",
            created: "2026-09-08 09:46"
        },
        {
            id: "3",
            name: "Sam Rivera",
            email: "sam@example.test",
            role: "member",
            status: "active",
            created: "2026-09-07 14:22"
        },
        {
            id: "4",
            name: "Taylor Brooks",
            email: "taylor@example.test",
            role: "member",
            status: "invited",
            created: "2026-09-07 11:08"
        },
        {
            id: "5",
            name: "Jordan Lee",
            email: "jordan@example.test",
            role: "editor",
            status: "active",
            created: "2026-09-06 16:35"
        },
        {
            id: "6",
            name: "Casey Wilson",
            email: "casey@example.test",
            role: "member",
            status: "active",
            created: "2026-09-06 10:12"
        },
        {
            id: "7",
            name: "Riley Parker",
            email: "riley@example.test",
            role: "member",
            status: "inactive",
            created: "2026-09-05 15:54"
        },
        {
            id: "8",
            name: "Drew Ellis",
            email: "drew@example.test",
            role: "editor",
            status: "active",
            created: "2026-09-05 09:18"
        },
        {
            id: "9",
            name: "Avery Stone",
            email: "avery@example.test",
            role: "member",
            status: "active",
            created: "2026-09-04 13:02"
        },
        {
            id: "10",
            name: "Quinn James",
            email: "quinn@example.test",
            role: "member",
            status: "invited",
            created: "2026-09-04 08:37"
        }
    ]
}
