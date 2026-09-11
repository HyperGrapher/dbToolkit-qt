#include "core/StaleResultGate.h"
#include "core/CachedSnapshotStore.h"
#include "models/ConnectionListModel.h"
#include "models/RowTableModel.h"
#include "models/TableListModel.h"
#include "core/ProtectedConnections.h"
#include <QStandardPaths>
#include <QFile>

#include <catch2/catch_test_macros.hpp>

TEST_CASE("Windows protected connections survive reload without plaintext credentials", "[storage]")
{
#ifdef Q_OS_WIN
    QStandardPaths::setTestModeEnabled(true);
    dbtoolkit::StoredConnection entry;
    entry.profile.displayName = "Storage regression";
    entry.profile.host = "127.0.0.1";
    entry.profile.port = 5432;
    entry.credentials.administratorPassword = "test-only-secret-123";
    const auto saved = dbtoolkit::ProtectedConnections::save(entry);
    REQUIRE(saved.isSuccess());
    const auto loaded = dbtoolkit::ProtectedConnections::load();
    bool found = false;
    for (const auto &candidate : loaded) {
        if (candidate.profile.id == entry.profile.id) {
            found = candidate.credentials.administratorPassword == entry.credentials.administratorPassword;
        }
    }
    QFile file(QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation) +
               "/connections/" + entry.profile.id.toString(QUuid::WithoutBraces) + ".protected");
    const bool opened = file.open(QIODevice::ReadOnly);
    const auto bytes = file.readAll();
    file.close();
    REQUIRE(dbtoolkit::ProtectedConnections::remove(entry.profile.id));
    REQUIRE(found);
    REQUIRE(opened);
    REQUIRE_FALSE(bytes.contains("test-only-secret-123"));
    QStandardPaths::setTestModeEnabled(false);
#endif
}

TEST_CASE("A stale-result gate rejects work from an obsolete selection", "[architecture]")
{
    dbtoolkit::StaleResultGate gate;
    const quint64 firstRequest = gate.beginWork();
    const quint64 secondRequest = gate.beginWork();
    REQUIRE_FALSE(gate.isCurrent(firstRequest));
    REQUIRE(gate.isCurrent(secondRequest));
    gate.invalidate();
    REQUIRE_FALSE(gate.isCurrent(secondRequest));
}

TEST_CASE("Cached snapshots are isolated by connection", "[architecture]")
{
    dbtoolkit::CachedSnapshotStore store;
    const QUuid connectionId = QUuid::createUuid();
    dbtoolkit::CachedDatabaseSnapshot snapshot;
    snapshot.connectionId = connectionId;
    snapshot.serverVersion = "PostgreSQL 18";

    store.replace(snapshot);

    REQUIRE(store.snapshotFor(connectionId).serverVersion == "PostgreSQL 18");
    REQUIRE(store.snapshotFor(QUuid::createUuid()).serverVersion.isEmpty());
}

TEST_CASE("Updating a connection profile keeps one model row", "[architecture]")
{
    dbtoolkit::ConnectionListModel model;
    dbtoolkit::ConnectionProfile profile;
    profile.displayName = "Local PostgreSQL";
    const QUuid profileId = profile.id;
    model.upsertProfile(profile);

    profile.displayName = "Project PostgreSQL";
    model.upsertProfile(profile);

    REQUIRE(model.rowCount() == 1);
    REQUIRE(model.data(model.index(0), dbtoolkit::ConnectionListModel::DisplayNameRole).toString() ==
            "Project PostgreSQL");
    REQUIRE(model.removeProfile(profileId));
    REQUIRE(model.rowCount() == 0);
}

TEST_CASE("Table model exposes schema-qualified identities", "[architecture]")
{
    dbtoolkit::TableListModel model;
    dbtoolkit::TableSummary publicUsers;
    publicUsers.schemaName = "public";
    publicUsers.tableName = "users";
    dbtoolkit::TableSummary auditUsers;
    auditUsers.schemaName = "audit";
    auditUsers.tableName = "users";

    model.replaceTables({publicUsers, auditUsers});

    REQUIRE(model.rowCount() == 2);
    REQUIRE(model.data(model.index(0), dbtoolkit::TableListModel::QualifiedNameRole).toString() ==
            "public.users");
    REQUIRE(model.data(model.index(1), dbtoolkit::TableListModel::QualifiedNameRole).toString() ==
            "audit.users");
    model.clear();
    REQUIRE(model.rowCount() == 0);
}

TEST_CASE("Row table model preserves null, empty, and binary values", "[architecture]")
{
    dbtoolkit::TablePage page;
    page.metadata.columns = {{.name = "optional"}, {.name = "label"}, {.name = "payload"}};
    page.rows = {{{.kind = dbtoolkit::CellValueKind::Null, .displayText = "NULL", .fullText = "NULL"},
                  {.kind = dbtoolkit::CellValueKind::Text,
                   .displayText = "Empty string",
                   .fullText = {}},
                  {.kind = dbtoolkit::CellValueKind::Binary,
                   .displayText = "Binary · 3 bytes",
                   .fullText = "Binary · 3 bytes"}}};

    dbtoolkit::RowTableModel model;
    model.replacePage(page);

    REQUIRE(model.rowCount() == 1);
    REQUIRE(model.columnCount() == 3);
    REQUIRE(model.roleNames().value(Qt::DisplayRole) == "display");
    REQUIRE(model.headerData(2, Qt::Horizontal).toString() == "payload");
    REQUIRE(model.data(model.index(0, 0), dbtoolkit::RowTableModel::ValueKindRole).toInt() == 1);
    REQUIRE(model.data(model.index(0, 1), dbtoolkit::RowTableModel::DisplayTextRole).toString() ==
            "Empty string");
    REQUIRE(model.data(model.index(0, 2), dbtoolkit::RowTableModel::ValueKindRole).toInt() == 2);
}
