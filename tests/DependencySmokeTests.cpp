#include <array>
#include <memory>

#include <catch2/catch_test_macros.hpp>
#include <sodium.h>
#include <sqlite3.h>

TEST_CASE("SQLite runtime opens an isolated in-memory database", "[dependencies]")
{
    sqlite3* database = nullptr;
    const int result = sqlite3_open(":memory:", &database);
    const std::unique_ptr<sqlite3, decltype(&sqlite3_close)> connection(database, sqlite3_close);

    REQUIRE(result == SQLITE_OK);
    REQUIRE(sqlite3_exec(connection.get(), "CREATE TABLE smoke (id INTEGER PRIMARY KEY)",
                        nullptr, nullptr, nullptr) == SQLITE_OK);
}

TEST_CASE("Sodium runtime authenticates ciphertext and rejects tampering", "[dependencies]")
{
    REQUIRE(sodium_init() >= 0);
    std::array<unsigned char, crypto_secretbox_KEYBYTES> key{};
    std::array<unsigned char, crypto_secretbox_NONCEBYTES> nonce{};
    constexpr std::array<unsigned char, 4> message{1, 2, 3, 4};
    std::array<unsigned char, message.size() + crypto_secretbox_MACBYTES> ciphertext{};
    std::array<unsigned char, message.size()> plaintext{};
    crypto_secretbox_keygen(key.data());
    randombytes_buf(nonce.data(), nonce.size());

    REQUIRE(crypto_secretbox_easy(ciphertext.data(), message.data(), message.size(),
                                 nonce.data(), key.data()) == 0);
    REQUIRE(crypto_secretbox_open_easy(plaintext.data(), ciphertext.data(), ciphertext.size(),
                                      nonce.data(), key.data()) == 0);
    REQUIRE(plaintext == message);
    ciphertext.front() ^= 1;
    REQUIRE(crypto_secretbox_open_easy(plaintext.data(), ciphertext.data(), ciphertext.size(),
                                      nonce.data(), key.data()) == -1);
    sodium_memzero(key.data(), key.size());
}
