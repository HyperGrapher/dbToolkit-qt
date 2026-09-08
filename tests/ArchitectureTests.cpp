#include "core/StaleResultGate.h"
#include "core/CachedSnapshotStore.h"
#include "models/ConnectionListModel.h"
#include "models/TableListModel.h"

#include <catch2/catch_test_macros.hpp>

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
