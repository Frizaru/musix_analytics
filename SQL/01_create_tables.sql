CREATE DATABASE IF NOT EXISTS musix_analytics
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE musix_analytics;

DROP TABLE IF EXISTS listens;
DROP TABLE IF EXISTS tracks;
DROP TABLE IF EXISTS albums;
DROP TABLE IF EXISTS artists;
DROP TABLE IF EXISTS users;

-- ПОЛЬЗОВАТЕЛИ
CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL,
    country VARCHAR(30) NOT NULL,
    subscription_type VARCHAR(20) NOT NULL,
    registration_date DATE NOT NULL,
    CONSTRAINT chk_users_subscription_type
        CHECK (subscription_type IN ('free', 'premium', 'family'))
);

-- ИСПОЛНИТЕЛИ
CREATE TABLE artists (
    artist_id INT PRIMARY KEY AUTO_INCREMENT,
    artist_name VARCHAR(50) NOT NULL,
    country VARCHAR(30) NOT NULL
);

-- АЛЬБОМЫ
CREATE TABLE albums (
    album_id INT PRIMARY KEY AUTO_INCREMENT,
    artist_id INT NOT NULL,
    album_name VARCHAR(50) NOT NULL,
    tracks_amount INT NOT NULL,
    release_date DATE NOT NULL,
    CONSTRAINT chk_albums_tracks_amount CHECK (tracks_amount > 0),
    CONSTRAINT uq_albums_album_artist UNIQUE (album_id, artist_id),
    CONSTRAINT fk_albums_artist
        FOREIGN KEY (artist_id) REFERENCES artists(artist_id)
);

-- ТРЕКИ
CREATE TABLE tracks (
    track_id INT PRIMARY KEY AUTO_INCREMENT,
    artist_id INT NOT NULL,
    album_id INT NOT NULL,
    track_name VARCHAR(100) NOT NULL,
    duration INT NOT NULL,
    genre VARCHAR(50) NOT NULL,
    release_date DATE NOT NULL,
    CONSTRAINT chk_tracks_duration CHECK (duration > 0),
    CONSTRAINT uq_tracks_track_artist_album
        UNIQUE (track_id, artist_id, album_id),
    CONSTRAINT fk_tracks_artist
        FOREIGN KEY (artist_id) REFERENCES artists(artist_id),
    CONSTRAINT fk_tracks_album_artist
        FOREIGN KEY (album_id, artist_id)
        REFERENCES albums(album_id, artist_id)
);

-- ПРОСЛУШИВАНИЯ
CREATE TABLE listens (
    listen_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    artist_id INT NOT NULL,
    track_id INT NOT NULL,
    album_id INT NOT NULL,
    listen_date DATETIME NOT NULL,
    CONSTRAINT fk_listens_user
        FOREIGN KEY (user_id) REFERENCES users(user_id),
    CONSTRAINT fk_listens_track_artist_album
        FOREIGN KEY (track_id, artist_id, album_id)
        REFERENCES tracks(track_id, artist_id, album_id)
);
